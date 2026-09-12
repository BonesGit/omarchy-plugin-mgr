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

  readonly property int checkMs: Model.configuredCheckMs(settings)
  readonly property int updateCount: Model.updateCount(plugins)
  readonly property int pluginCount: Model.thirdPartyCount(plugins)
  readonly property bool busy: listing || checking || busyId !== ""

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
    runAction("update", id)
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
    if (!id || actionProc.running) return
    root.busyId = id
    root.busyKind = kind
    root.lastError = ""
    actionProc.command = root.argv(kind, id)
    actionProc.running = true
  }

  function refreshNow() {
    load()
  }

  Process {
    id: listProc
    stdout: StdioCollector {
      onStreamFinished: {
        root.listing = false
        root.applyPayload(text, listErr.text)
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

  Timer {
    interval: 400
    running: true
    repeat: false
    onTriggered: root.load()
  }

  Timer {
    interval: 8000
    running: true
    repeat: false
    onTriggered: root.check()
  }

  Timer {
    interval: root.checkMs
    running: true
    repeat: true
    onTriggered: root.check()
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
