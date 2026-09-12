import QtQuick
import Quickshell
import Quickshell.Io
import "Model.js" as Model

// Plugin `service` singleton. Dual-monitor pills share this list and
// the periodic git check; a Process on the widget would be one fetch
// per screen.
Item {
  id: root
  width: 0
  height: 0
  visible: false

  property var settings: ({})
  property var shell: null
  property var manifest: null
  property var pluginRegistry: null
  property var barWidgetRegistry: null
  property string omarchyPath: ""

  property var plugins: []
  property double checkedAt: 0
  property bool loaded: false
  property bool listing: false
  property bool checking: false
  property string busyId: ""
  property string busyKind: ""
  property string lastError: ""
  property string defaultAgent: ""
  property bool hasDefaultAgent: false
  property var scanPref: null

  readonly property int checkMs: Model.configuredCheckMs(settings)
  readonly property int updateCount: Model.updateCount(plugins)
  readonly property int pluginCount: Model.thirdPartyCount(plugins)
  readonly property int firstPartyCount: Model.filterByFirstParty(plugins, true).length
  // listing is a background refresh — do not freeze the panel on it.
  readonly property bool busy: checking || busyId !== ""
  readonly property bool securityScanOn: hasDefaultAgent && (scanPref !== null
    ? scanPref === true
    : Model.configuredSecurityScan(settings))

  onSettingsChanged: {
    if (root.scanPref === null) return
    if (Model.configuredSecurityScan(root.settings) === root.scanPref)
      root.scanPref = null
  }

  readonly property string script:
    Qt.resolvedUrl("bin/plugin-mgr").toString().replace(/^file:\/\//, "")

  function argv() {
    var a = []
    for (var i = 0; i < arguments.length; i++) a.push(String(arguments[i]))
    return [root.script].concat(a)
  }

  function applyPayload(text, stderrText) {
    var raw = String(text || "").trim()
    if (!raw) return false
    var data
    try {
      data = JSON.parse(raw)
    } catch (e) {
      var err = String(stderrText || "").trim()
      if (err)
        root.lastError = Model.clipError(err)
      return false
    }
    if (data && data.hasDefaultAgent !== undefined)
      root.hasDefaultAgent = data.hasDefaultAgent === true
    if (data && data.defaultAgent !== undefined)
      root.defaultAgent = String(data.defaultAgent || "")
    if (data && Array.isArray(data.plugins)) {
      root.plugins = data.plugins
      root.checkedAt = Number(data.checkedAt || 0)
      root.loaded = true
      root.lastError = data.error ? Model.clipError(data.error) : ""
      return !data.error
    }
    if (data && data.error) {
      root.lastError = Model.clipError(data.error)
      return false
    }
    if (data && data.ok === true) {
      root.lastError = ""
      return true
    }
    return false
  }

  function load() {
    if (listProc.running) return
    root.listAttempts += 1
    root.listing = true
    listProc.command = root.argv("list")
    listProc.running = true
  }

  function check(id) {
    if (checkProc.running) return
    root.checking = true
    root.lastError = ""
    if (id)
      checkProc.command = root.argv("check", id)
    else
      checkProc.command = root.argv("check")
    checkProc.running = true
  }

  function enablePlugin(id) {
    runAction("enable", id)
  }

  function disablePlugin(id) {
    runAction("disable", id)
  }

  function updatePlugin(id) {
    if (!id || actionProc.running || scanPrepProc.running) return
    if (root.securityScanOn)
      prepareScan(id)
    else
      runAction("update", id)
  }

  function prepareScan(id) {
    if (!id || scanPrepProc.running || actionProc.running || statusProc.running) return
    root.busyId = id
    root.busyKind = "scan"
    root.lastError = ""
    if (Model.debugForceUpdateButtons())
      scanPrepProc.command = root.argv("prepare-scan", id, "--force")
    else
      scanPrepProc.command = root.argv("prepare-scan", id)
    scanPrepProc.running = true
  }

  function pollScan() {
    if (root.busyKind !== "scan" || root.busyId === "" || statusProc.running) return
    statusProc.command = root.argv("scan-status", root.busyId)
    statusProc.running = true
  }

  function finishScan(data) {
    var state = data && data.state ? String(data.state) : ""
    if (state === "waiting") return
    if (state === "clear") {
      scanTimer.stop()
      runAction("update", root.busyId)
      return
    }
    scanTimer.stop()
    if (state === "block")
      root.lastError = Model.clipError(data.summary || "security scan blocked the update")
    else if (state === "idle")
      root.lastError = ""
    var id = root.busyId
    root.busyId = ""
    root.busyKind = ""
    if (id && !cancelProc.running) {
      cancelProc.command = root.argv("cancel-scan", id)
      cancelProc.running = true
    }
  }

  function cancelScan() {
    if (root.busyKind !== "scan") return
    scanTimer.stop()
    var id = root.busyId
    root.busyId = ""
    root.busyKind = ""
    root.lastError = ""
    if (id && !cancelProc.running) {
      cancelProc.command = root.argv("cancel-scan", id)
      cancelProc.running = true
    }
  }

  function setSecurityScan(on) {
    if (!root.hasDefaultAgent) return
    root.scanPref = on === true
    if (setProc.running) return
    setProc.command = ["omarchy", "bar", "set", "io.github.bonesgit.omarchy-plugin-mgr", "securityScan", on ? "true" : "false", "--json"]
    setProc.running = true
  }

  function removePlugin(id) {
    runAction("remove", id)
  }

  function openRepo(id) {
    if (!id || openProc.running) return
    openProc.command = root.argv("open", id)
    openProc.running = true
  }

  function runAction(kind, id) {
    if (!id || actionProc.running || scanPrepProc.running) return
    root.busyId = id
    root.busyKind = kind
    root.lastError = ""
    actionProc.command = root.argv(kind, id)
    actionProc.running = true
  }

  function refreshNow() {
    load()
  }

  function scheduleDue(fromCheck) {
    if (!root.loaded || checkProc.running) return
    var wait = Model.msUntilDue(root.checkedAt, root.checkMs)
    if (fromCheck && wait <= 0) wait = root.checkMs
    if (wait <= 0) {
      root.check()
      return
    }
    dueTimer.interval = Math.max(1000, Math.round(wait))
    dueTimer.restart()
  }

  onCheckMsChanged: if (root.loaded) root.scheduleDue()

  Process {
    id: listProc
    stdout: StdioCollector {
      onStreamFinished: {
        root.listing = false
        root.applyPayload(text, listErr.text)
        root.scheduleDue()
      }
    }
    stderr: StdioCollector { id: listErr }
    onExited: function(code) {
      root.listing = false
    }
  }

  Process {
    id: checkProc
    stdout: StdioCollector {
      onStreamFinished: {
        root.checking = false
        root.applyPayload(text, checkErr.text)
        root.scheduleDue(true)
      }
    }
    stderr: StdioCollector { id: checkErr }
    onExited: function(code) {
      root.checking = false
    }
  }

  Process {
    id: actionProc
    stdout: StdioCollector {
      onStreamFinished: {
        if (!root.applyPayload(text, actionErr.text) && root.lastError === "")
          root.lastError = Model.clipError(actionErr.text || "action failed")
        root.busyId = ""
        root.busyKind = ""
      }
    }
    stderr: StdioCollector { id: actionErr }
    onExited: function(code) {
      root.busyId = ""
      root.busyKind = ""
      if (code !== 0 && root.lastError === "")
        root.lastError = Model.clipError(actionErr.text || "action failed")
    }
  }

  Process {
    id: openProc
    stdout: StdioCollector {}
    stderr: StdioCollector { id: openErr }
    onExited: function(code) {
      if (code !== 0)
        root.lastError = Model.clipError(openErr.text || "open failed")
    }
  }

  Process {
    id: scanPrepProc
    stdout: StdioCollector {
      onStreamFinished: {
        var raw = String(text || "").trim()
        var data = null
        try { data = JSON.parse(raw) } catch (e) { data = null }
        if (data && data.hasDefaultAgent !== undefined)
          root.hasDefaultAgent = data.hasDefaultAgent === true
        if (!data || data.ok !== true) {
          if (!root.applyPayload(raw, scanPrepErr.text) && root.lastError === "")
            root.lastError = Model.clipError(scanPrepErr.text || "scan failed")
          root.busyId = ""
          root.busyKind = ""
          return
        }
        scanTimer.restart()
        root.pollScan()
      }
    }
    stderr: StdioCollector { id: scanPrepErr }
    onExited: function(code) {
      if (code !== 0 && root.busyKind === "scan") {
        if (root.lastError === "")
          root.lastError = Model.clipError(scanPrepErr.text || "scan failed")
        root.busyId = ""
        root.busyKind = ""
        scanTimer.stop()
      }
    }
  }

  Process {
    id: statusProc
    stdout: StdioCollector {
      onStreamFinished: {
        var raw = String(text || "").trim()
        var data = null
        try { data = JSON.parse(raw) } catch (e) { data = null }
        if (root.busyKind !== "scan") return
        if (!data || data.ok !== true) return
        root.finishScan(data)
      }
    }
    stderr: StdioCollector {}
  }

  Process {
    id: cancelProc
    stdout: StdioCollector {}
    stderr: StdioCollector {}
  }

  Process {
    id: setProc
    stdout: StdioCollector {}
    stderr: StdioCollector { id: setErr }
    onExited: function(code) {
      if (code !== 0)
        root.lastError = Model.clipError(setErr.text || "could not save scan setting")
    }
  }

  Timer {
    id: scanTimer
    interval: 1000
    running: false
    repeat: true
    onTriggered: root.pollScan()
  }

  Component.onCompleted: root.load()

  Timer {
    id: listRetry
    interval: 400
    running: root.firstPartyCount === 0 && root.listAttempts < 20
    repeat: true
    onTriggered: if (!listProc.running) root.load()
  }

  property int listAttempts: 0

  Timer {
    id: dueTimer
    interval: 86400000
    running: false
    repeat: false
    onTriggered: root.scheduleDue()
  }

  IpcHandler {
    target: "io.github.bonesgit.omarchy-plugin-mgr.service"

    function reload(): string {
      root.load()
      return "reloading"
    }

    function check(): string {
      root.check()
      return "checking"
    }

    function state(): string {
      return JSON.stringify({
        plugins: root.pluginCount,
        updates: root.updateCount,
        checking: root.checking,
        loaded: root.loaded,
        lastError: root.lastError
      })
    }
  }
}
