import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets
import qs.Services.UI
import qs.Services.System
import "./Services"

Item {
  id: root

  property var pluginApi: null
  property ShellScreen screen
  property string widgetId: ""
  property string section: ""

  readonly property string screenName: screen?.name ?? ""
  readonly property string barPosition: Settings.getBarPositionForScreen(screenName)
  readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screenName)
  readonly property real barFontSize: Style.getBarFontSizeForScreen(screenName)

  readonly property var settings: pluginApi?.pluginSettings ?? {}
  readonly property string ssid: settings.ssid ?? "NoctaliaHotspot"

  readonly property bool isActive: HotspotService.isActive
  readonly property int connectedCount: HotspotService.connectedDevices?.length ?? 0
  readonly property bool isLoading: HotspotService.isLoading

  scale: 1.0

  implicitWidth: capsuleHeight
  implicitHeight: capsuleHeight

  Rectangle {
    id: visualCapsule
    width: capsuleHeight
    height: capsuleHeight
    x: Style.pixelAlignCenter(parent.width, width)
    y: Style.pixelAlignCenter(parent.height, height)

    radius: Style.radiusL
    color: {
      if (isLoading) return Color.mPrimary + "40"
      if (mouseArea.containsMouse) return Color.mSurfaceVariant
      if (isActive) return Color.mPrimary
      return Style.capsuleColor
    }
    border.color: isActive ? Color.mPrimary : Style.capsuleBorderColor
    border.width: Style.capsuleBorderWidth

    NIcon {
      icon: isActive ? "wifi" : "wifi-off"
      color: isActive ? Color.mOnPrimary : (mouseArea.containsMouse ? Color.mOnSurface : Color.mOnSurfaceVariant)
      pointSize: Style.toOdd(capsuleHeight * 0.48)
      anchors.centerIn: parent
    }
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    onPressed: {
      root.scale = 0.97
    }
    onReleased: {
      root.scale = 1.0
    }

    onEntered: {
      let msg
      if (isLoading) {
        msg = "Hotspot - Working..."
      } else if (isActive) {
        msg = connectedCount > 0 
          ? ssid + " - " + connectedCount + " device(s)" 
          : ssid + " (active)"
      } else {
        msg = "Hotspot - Click to configure"
      }
      TooltipService.show(root, msg, BarService.getTooltipDirection())
    }

    onExited: {
      TooltipService.hide()
    }

    onClicked: {
      pluginApi?.openPanel(root.screen, root)
    }
  }

  Behavior on scale {
    NumberAnimation {
      duration: 150
      easing.type: Easing.OutCubic
    }
  }
}
