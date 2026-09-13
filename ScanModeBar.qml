import QtQuick
import qs.Commons
import qs.Ui

// Connected Off/Confirm/Trust chips: one outer border, 1px dividers, no gaps.
// Same pattern as local.control LlmModeBar.
BorderSurface {
  id: root

  property var options: []
  property string value: ""
  property color foreground: Color.foreground
  property color accent: Color.accent
  property string fontFamily: Style.font.family
  property real fontSize: Style.font.caption

  signal changed(string value)

  function optionValue(o) {
    return (o && typeof o === "object") ? String(o.value) : String(o)
  }

  function optionLabel(o) {
    return (o && typeof o === "object" && o.label !== undefined) ? String(o.label) : String(o)
  }

  function optionTooltip(o) {
    if (o && typeof o === "object" && o.tooltip !== undefined) return String(o.tooltip)
    return ""
  }

  radius: Style.cornerRadius
  color: "transparent"
  clip: true
  borderSpec: Border.controlSpec("normal", root.foreground, root.accent)
  implicitWidth: row.implicitWidth + borderLeft + borderRight
  implicitHeight: Math.max(Style.spacing.controlHeight, row.implicitHeight + borderTop + borderBottom)

  readonly property color dividerColor: Border.color(borderSpec)

  Row {
    id: row
    x: root.borderLeft
    y: root.borderTop
    spacing: 0

    Repeater {
      model: root.options

      delegate: Item {
        id: seg
        required property var modelData
        required property int index
        readonly property bool isLast: index >= root.options.length - 1
        readonly property bool selected: root.optionValue(modelData) === root.value
        implicitWidth: chip.implicitWidth + (isLast ? 0 : 1)
        implicitHeight: chip.implicitHeight
        width: implicitWidth
        height: implicitHeight

        BorderSurface {
          id: chip
          anchors.left: parent.left
          anchors.top: parent.top
          anchors.bottom: parent.bottom
          radius: 0
          borderSpec: Border.none()
          color: chipMouse.pressed ? Style.pressedFillFor(root.foreground, root.accent)
            : (chipMouse.containsMouse || selected)
              ? (selected ? Style.selectedFillFor(root.foreground, root.accent) : Style.hoverFillFor(root.foreground, root.accent))
              : "transparent"
          implicitWidth: chipLabel.implicitWidth + Style.space(16)
          implicitHeight: Math.max(Style.spacing.controlHeight - root.borderTop - root.borderBottom, chipLabel.implicitHeight + Style.space(8))

          Text {
            id: chipLabel
            anchors.centerIn: parent
            text: root.optionLabel(seg.modelData)
            color: seg.selected ? Style.selectedStateColor(root.foreground, root.accent) : root.foreground
            font.family: root.fontFamily
            font.pixelSize: root.fontSize
            font.bold: seg.selected
          }

          MouseArea {
            id: chipMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.changed(root.optionValue(seg.modelData))
          }

          PanelToolTip {
            visible: chipMouse.containsMouse && root.optionTooltip(seg.modelData) !== ""
            text: root.optionTooltip(seg.modelData)
            fontFamily: root.fontFamily
          }
        }

        Rectangle {
          visible: !seg.isLast
          width: 1
          anchors.top: parent.top
          anchors.bottom: parent.bottom
          anchors.right: parent.right
          color: root.dividerColor
        }
      }
    }
  }
}
