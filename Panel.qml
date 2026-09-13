import QtQuick
import QtQuick.Controls
import qs.Commons
import qs.Ui
import "Model.js" as Model

Panel {
  id: root
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  property var service: null
  property color statusColor: Color.muted
  property double now: Date.now()

  readonly property var barIdentity: hostWidget || root
  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color dim: Qt.darker(foreground, 1.4)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  property string partyTab: "third"
  property string pluginQuery: ""
  readonly property var plugins: service && service.plugins ? service.plugins : []
  readonly property var visiblePlugins: Model.filterPlugins(plugins, partyTab === "first", pluginQuery)
  readonly property bool loaded: service ? service.loaded : false
  readonly property bool listing: service ? service.listing : false
  readonly property bool checking: service ? service.checking : false
  readonly property bool busy: service ? service.busy : false
  readonly property string busyId: service ? service.busyId : ""
  readonly property string busyKind: service ? service.busyKind : ""
  readonly property string lastError: service ? service.lastError : ""
  readonly property bool hasDefaultAgent: service ? service.hasDefaultAgent === true : false
  readonly property bool securityScanOn: service ? service.securityScanOn === true : false
  readonly property string scanMode: service ? service.scanMode : "off"
  readonly property var scanModeOptions: {
    var needAgent = "Pick a default agent to enable security scans."
    return [
      { value: "off", label: "Off", tooltip: "Update without a scan." },
      { value: "confirm", label: "Confirm", tooltip: root.hasDefaultAgent ? "Scan, then click the thumbs-up to install." : needAgent },
      { value: "trust", label: "Trust", tooltip: root.hasDefaultAgent ? "Scan, then update on CLEAR with no extra click." : needAgent }
    ]
  }
  readonly property int updateCount: service ? service.updateCount : 0
  readonly property double checkedAt: service ? service.checkedAt : 0
  readonly property string metaText: {
    if (busyKind === "scan") return "scanning with default agent"
    if (busyKind === "confirm") return "scan clear — confirm update"
    if (checking) return "checking remotes"
    if (listing && !loaded) return "reading plugins"
    if (updateCount === 1) return "1 update"
    if (updateCount > 1) return updateCount + " updates"
    return "checked " + Model.relativeTime(checkedAt, now)
  }

  function open() {
    root.controller.show()
  }

  function close() {
    root.controller.hide()
  }

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.barIdentity, direction)
    return false
  }

  onOpenedChanged: {
    if (opened) {
      now = Date.now()
      if (service && service.firstPartyCount === 0) service.load()
      Qt.callLater(function() { if (keyCatcher) keyCatcher.forceActiveFocus() })
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(480))
    contentHeight: panel.fittedContentHeight(content.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      blocked: searchField.activeFocus
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onTextKey: function(t) {
        if (t === "r" || t === "R") {
          if (root.service) root.service.check()
        }
      }

      Column {
        id: content
        width: parent.width
        spacing: Style.space(12)
        clip: true

        Item {
          width: parent.width
          implicitHeight: Math.max(heroLabels.implicitHeight, headerActions.implicitHeight)

          Column {
            id: heroLabels
            anchors.left: parent.left
            anchors.right: headerActions.left
            anchors.rightMargin: Style.space(12)
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(2)

            Text {
              width: parent.width
              text: "Plugins"
              textFormat: Text.PlainText
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.title
              font.bold: true
              elide: Text.ElideRight
            }

            Text {
              width: parent.width
              text: root.metaText.toUpperCase()
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              font.letterSpacing: 1.2
              elide: Text.ElideRight
            }
          }

          Row {
            id: headerActions
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(4)

            Button {
              text: root.checking ? "Checking" : "Check"
              tooltipText: "Fetch git remotes for every third-party plugin  ( r )"
              foreground: root.foreground
              fontFamily: root.fontFamily
              fontSize: Style.font.caption
              bordered: true
              enabled: !root.checking && !root.busy
              onClicked: if (root.service) root.service.check()
            }
          }
        }

        Item {
          width: parent.width
          implicitHeight: Math.max(Style.spacing.controlHeight, searchField.implicitHeight)
          height: implicitHeight

          ButtonGroup {
            id: partyTabs
            anchors.left: parent.left
            anchors.right: searchBox.left
            anchors.rightMargin: Style.space(8)
            anchors.verticalCenter: parent.verticalCenter
            focusable: false
            foreground: root.foreground
            background: "transparent"
            accent: Color.accent
            fontFamily: root.fontFamily
            fontSize: Style.font.caption
            value: root.partyTab
            options: [
              { value: "third", label: "Third Party" },
              { value: "first", label: "First Party" }
            ]
            onChanged: function(v) { root.partyTab = v }
          }

          Item {
            id: searchBox
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: Style.space(176)
            implicitHeight: searchField.implicitHeight
            height: implicitHeight

            TextField {
              id: searchField
              anchors.fill: parent
              placeholderText: "Filter"
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              foreground: root.foreground
              horizontalPadding: Style.spacing.controlGap
              verticalPadding: Style.spacing.controlPaddingY
              rightPadding: horizontalPadding + (clearBtn.visible ? clearBtn.width : 0)
              text: root.pluginQuery
              onTextChanged: if (text !== root.pluginQuery) root.pluginQuery = text
              Keys.onEscapePressed: function(event) {
                if (text !== "") {
                  text = ""
                  event.accepted = true
                } else {
                  keyCatcher.forceActiveFocus()
                  event.accepted = true
                }
              }
            }

            PanelActionButton {
              id: clearBtn
              visible: searchField.text !== ""
              anchors.right: parent.right
              anchors.rightMargin: Style.space(2)
              anchors.verticalCenter: parent.verticalCenter
              z: 2
              iconText: "󰅙"
              tooltipText: "Clear filter"
              foreground: root.dim
              hoverColor: root.foreground
              fontFamily: root.fontFamily
              fontSize: Style.font.caption
              onClicked: {
                searchField.text = ""
                searchField.forceActiveFocus()
              }
            }
          }
        }

        PanelSeparator { width: parent.width }

        Text {
          width: parent.width
          visible: root.visiblePlugins.length === 0
          horizontalAlignment: Text.AlignHCenter
          topPadding: Style.space(22)
          bottomPadding: Style.space(22)
          text: !root.loaded ? "Reading plugins\u2026" : (String(root.pluginQuery).trim() !== "" ? "No matching plugins" : (root.partyTab === "first" ? "No first-party plugins" : "No third-party plugins"))
          wrapMode: Text.WordWrap
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          color: root.foreground
          opacity: 0.55
        }

        Flickable {
          id: pluginScroll
          width: parent.width
          visible: root.visiblePlugins.length > 0
          implicitHeight: Math.min(pluginList.implicitHeight, Style.space(480))
          height: implicitHeight
          contentWidth: width
          contentHeight: pluginList.implicitHeight
          clip: true
          boundsBehavior: Flickable.StopAtBounds
          interactive: contentHeight > height

          Column {
            id: pluginList
            width: pluginScroll.width
            spacing: Style.space(6)

          Repeater {
            model: root.visiblePlugins
            delegate: BorderSurface {
              id: card
              width: parent.width
              radius: Style.cornerRadius
              property bool _hot: cardHover.hovered
              property bool _on: modelData.enabled === true
              property bool _rowBusy: root.busyId === modelData.id
              property bool _scanning: root.busyKind === "scan" && root.busyId === modelData.id
              property bool _confirm: root.busyKind === "confirm" && root.busyId === modelData.id
              property bool _armed: false
              color: Style.controlFill(false, _hot, root.foreground, Color.accent)
              borderSpec: card._armed
                ? Border.flat(Color.urgent, Math.max(1, Style.hoverBorderWidth))
                : (card._confirm
                  ? Border.flat(Color.accent, Math.max(1, Style.hoverBorderWidth))
                  : (card._scanning
                    ? Border.flat(Color.accent, Math.max(1, Style.hoverBorderWidth))
                    : (modelData.updateAvailable
                      ? Border.flat(Color.accent, Math.max(1, Style.hoverBorderWidth))
                      : (_on
                        ? Border.controlSpec(_hot ? "hover-cursor" : "selected", root.foreground, Color.accent)
                        : Border.controlSpec(_hot ? "hover-cursor" : "normal", root.foreground, Color.accent)))))
              implicitHeight: row.implicitHeight + Style.space(10)
              opacity: (_rowBusy && !card._scanning && !card._confirm && !card._armed) ? 0.55 : 1

              Behavior on color { ColorAnimation { duration: 100 } }
              Behavior on opacity { NumberAnimation { duration: 100 } }

              function arm() {
                if (modelData.firstParty === true || root.busy) return
                card._armed = true
                disarm.restart()
              }

              function confirmRemove() {
                if (!card._armed || root.busy) return
                if (modelData.firstParty === true) return
                card._armed = false
                disarm.stop()
                if (root.service) root.service.removePlugin(modelData.id)
              }

              MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.RightButton
                onClicked: card.arm()
              }

              HoverHandler { id: cardHover }

              Timer {
                id: disarm
                interval: 4000
                onTriggered: card._armed = false
              }

              Item {
                id: row
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: card.borderLeft + Style.spacing.rowPaddingX
                anchors.rightMargin: card.borderRight + Style.spacing.rowPaddingX
                implicitHeight: Math.max(titleCol.implicitHeight, actions.implicitHeight)

                Column {
                  id: titleCol
                  anchors.left: parent.left
                  anchors.right: actions.left
                  anchors.rightMargin: Style.space(10)
                  anchors.verticalCenter: parent.verticalCenter
                  spacing: Style.space(1)

                  Text {
                    width: parent.width
                    text: modelData.name
                    color: root.foreground
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.body
                    font.bold: true
                    elide: Text.ElideRight
                  }

                  Item {
                    width: parent.width
                    implicitHeight: Math.max(verText.implicitHeight, gitText.implicitHeight)

                    Text {
                      id: gitText
                      anchors.right: parent.right
                      anchors.verticalCenter: parent.verticalCenter
                      text: Model.gitLine(modelData)
                      color: modelData.updateAvailable ? Color.accent : root.dim
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.caption
                      visible: text !== ""
                    }

                    Text {
                      id: verText
                      anchors.left: parent.left
                      anchors.right: gitText.visible ? gitText.left : parent.right
                      anchors.rightMargin: gitText.visible ? Style.space(8) : 0
                      anchors.verticalCenter: parent.verticalCenter
                      text: Model.versionLine(modelData)
                      color: root.dim
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.caption
                      elide: Text.ElideRight
                    }
                  }

                  Text {
                    width: parent.width
                    text: modelData.id
                    color: Color.muted
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    opacity: 0.85
                    elide: Text.ElideMiddle
                  }
                }

                Row {
                  id: actions
                  anchors.right: parent.right
                  anchors.verticalCenter: parent.verticalCenter
                  spacing: Style.space(2)

                  PanelActionButton {
                    anchors.verticalCenter: parent.verticalCenter
                    opacity: modelData.git === true ? 1 : 0
                    iconText: card._confirm ? "󰔓" : (card._scanning ? "󰅖" : "󰚰")
                    tooltipText: card._confirm ? "Security scan clear. Click to install the update."
                      : (card._scanning ? "Cancel security scan"
                      : (modelData.git !== true ? ""
                        : (Model.debugForceUpdateButtons() && !modelData.updateAvailable
                          ? "Debug: force update/scan"
                          : (!modelData.updateAvailable ? "No upstream commits"
                            : (root.securityScanOn
                              ? "Scan with default agent, then update if clear"
                              : "Update from origin")))))
                    foreground: card._confirm ? Color.accent
                      : (card._scanning ? Color.urgent
                      : ((modelData.updateAvailable || Model.debugForceUpdateButtons()) ? Color.accent : root.dim))
                    fontFamily: root.fontFamily
                    enabled: card._confirm || card._scanning || (modelData.git === true && !root.busy && (modelData.updateAvailable === true || Model.debugForceUpdateButtons()))
                    onClicked: {
                      if (card._confirm) {
                        if (root.service) root.service.confirmScanUpdate()
                        return
                      }
                      if (card._scanning) {
                        if (root.service) root.service.cancelScan()
                        return
                      }
                      if (root.service) root.service.updatePlugin(modelData.id)
                    }
                  }

                  PanelActionButton {
                    anchors.verticalCenter: parent.verticalCenter
                    opacity: modelData.repo && modelData.repo !== "" ? 1 : 0
                    iconText: "󰖟"
                    tooltipText: modelData.repo && modelData.repo !== "" ? "Open " + modelData.repo : ""
                    foreground: root.foreground
                    fontFamily: root.fontFamily
                    enabled: !!(modelData.repo && modelData.repo !== "") && !root.busy
                    onClicked: if (root.service) root.service.openRepo(modelData.id)
                  }

                  ToggleSwitch {
                    id: enableSwitch
                    anchors.verticalCenter: parent.verticalCenter
                    checked: modelData.enabled === true
                    foreground: root.foreground
                    accent: Color.accent
                    enabled: !root.busy
                    onToggled: {
                      if (!root.service) return
                      if (checked === (modelData.enabled === true)) return
                      if (checked) root.service.enablePlugin(modelData.id)
                      else root.service.disablePlugin(modelData.id)
                    }

                    PanelToolTip {
                      visible: enableSwitch.containsMouse
                      text: modelData.enabled ? "Disable plugin" : "Enable plugin"
                      fontFamily: root.fontFamily
                    }
                  }
                }
              }

              Button {
                visible: card._armed && !card._scanning && !card._confirm
                anchors.centerIn: parent
                z: 2
                text: "Remove"
                tooltipText: "Remove this plugin"
                foreground: Color.urgent
                accent: Color.urgent
                fontFamily: root.fontFamily
                fontSize: Style.font.caption
                enabled: !root.busy
                onClicked: card.confirmRemove()
              }
            }
          }
          }
        }

        Text {
          visible: root.lastError !== ""
          width: parent.width
          text: root.lastError
          color: Color.urgent
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          wrapMode: Text.WordWrap
        }

        Item {
          width: parent.width
          implicitHeight: scanRow.implicitHeight
          height: implicitHeight

          Row {
            id: scanRow
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(8)

            Text {
              text: "Security scan"
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              anchors.verticalCenter: parent.verticalCenter
            }

            ScanModeBar {
              id: scanModeBar
              anchors.verticalCenter: parent.verticalCenter
              options: root.scanModeOptions
              value: root.scanMode
              foreground: root.foreground
              accent: Color.accent
              fontFamily: root.fontFamily
              fontSize: Style.font.caption
              opacity: root.hasDefaultAgent ? 1 : 0.45
              onChanged: function(v) {
                if (root.busy) return
                if (!root.service) return
                if (v !== "off" && !root.hasDefaultAgent) return
                root.service.setScanMode(v)
              }
            }
          }
        }
      }
    }
  }

  Timer {
    interval: 30000
    running: root.opened
    repeat: true
    triggeredOnStart: true
    onTriggered: root.now = Date.now()
  }
}
