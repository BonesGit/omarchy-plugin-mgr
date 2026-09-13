import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model

BarWidget {
  id: root
  // moduleName is injected by the bar. Binding it here makes the
  // property read-only and injectProps() throws before settings land.

  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false
  readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing === true : false

  property var store: null

  readonly property int pluginCount: store ? store.pluginCount : 0
  readonly property int updateCount: store ? store.updateCount : 0
  readonly property bool checking: store ? store.checking : false
  readonly property string lastError: store ? store.lastError : ""
  readonly property color statusColor: {
    if (!store || !store.loaded) return Color.muted
    if (store.lastError !== "") return themeYellow
    if (store.updateCount > 0) return Color.accent
    return themeGreen
  }
  readonly property real openPanelIndicatorWidth: root.vertical ? 0 : contentRow.implicitWidth
  readonly property real openPanelIndicatorHeight: Math.max(Style.space(10), Math.round(Style.bar.iconSlot * 0.55))
  readonly property string tooltip: Model.pillTooltip(pluginCount, updateCount, checking, lastError)

  property color themeGreen: "#3ecf6a"
  property color themeYellow: "#e0b44b"

  function bindService() {
    if (store) return
    if (!bar || !bar.shell || typeof bar.shell.serviceFor !== "function") return
    var s = bar.shell.serviceFor("io.github.bonesgit.omarchy-plugin-mgr")
    if (!s) return
    store = s
    s.settings = root.settings
    injectPanel()
  }

  function open() {
    if (panelLoader.item) panelLoader.item.open()
  }
  function close() {
    if (panelLoader.item) panelLoader.item.close()
  }
  function toggle() {
    if (panelLoader.item) panelLoader.item.toggle()
  }
  function closeForPopoutSwitch() {
    if (panelLoader.item) panelLoader.item.closeForPopoutSwitch()
  }
  function refresh() {
    if (store) store.check()
  }

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    if ("bar" in target) target.bar = root.bar
    if ("settings" in target) target.settings = root.settings
    if ("anchorItem" in target) target.anchorItem = button
    if ("hostWidget" in target) target.hostWidget = root
    if ("service" in target) target.service = store
    if ("statusColor" in target) target.statusColor = root.statusColor
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onBarChanged: {
    bindService()
    injectPanel()
  }
  onSettingsChanged: {
    if (store) store.settings = root.settings
    else bindService()
    injectPanel()
  }
  onStatusColorChanged: if (panelLoader.item && "statusColor" in panelLoader.item) panelLoader.item.statusColor = statusColor
  onStoreChanged: injectPanel()

  Timer {
    interval: 200
    running: root.store === null
    repeat: true
    triggeredOnStart: true
    onTriggered: root.bindService()
  }

  IpcHandler {
    target: "io.github.bonesgit.omarchy-plugin-mgr"
    function open(): void { root.open() }
    function close(): void { root.close() }
    function show(): void { root.open() }
    function hide(): void { root.close() }
    function toggle(): void { root.toggle() }
    function refresh(): void { root.refresh() }
  }

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: ""
    labelVisible: false
    hasVisualContent: true
    tooltipText: root.tooltip
    fixedWidth: root.vertical ? -1 : Style.bar.iconSlot
    fixedHeight: root.vertical ? Style.bar.iconSlot : -1

    onPressed: function(buttonCode) {
      if (buttonCode === Qt.RightButton || buttonCode === Qt.MiddleButton) root.refresh()
      else root.toggle()
    }

    Item {
      id: contentRow
      visible: !root.vertical
      anchors.centerIn: parent
      width: Style.bar.iconSlot
      height: Style.bar.iconSlot
      implicitWidth: width
      implicitHeight: height

      OpticalGlyph {
        anchors.fill: parent
        text: "󰐱"
        fontFamily: button.fontFamily
        fontSize: Style.bar.iconFont
        color: button.active && button.useActiveColor ? button.activeColor : button.foreground
      }

      Text {
        visible: root.updateCount > 0
        text: String(root.updateCount)
        color: button.foreground
        font.family: button.fontFamily
        font.pixelSize: Math.max(8, Math.round(Style.bar.iconFont * 0.5))
        font.bold: true
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: Style.space(1)
        anchors.bottomMargin: Style.space(1)
      }
    }

    Item {
      visible: root.vertical
      anchors.centerIn: parent
      width: Style.bar.iconSlot
      height: Style.bar.iconSlot

      OpticalGlyph {
        anchors.fill: parent
        text: "󰐱"
        fontFamily: button.fontFamily
        fontSize: Style.bar.iconFont
        color: button.active && button.useActiveColor ? button.activeColor : button.foreground
      }

      Text {
        visible: root.updateCount > 0
        text: String(root.updateCount)
        color: button.foreground
        font.family: button.fontFamily
        font.pixelSize: Math.max(8, Math.round(Style.bar.iconFont * 0.5))
        font.bold: true
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: Style.space(1)
        anchors.bottomMargin: Style.space(1)
      }
    }
  }
}
