import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets
import qs.Modules.Bar.Extras
import qs.Services.UI
import qs.Services.System
import "./Services"

Item {
  id: root

  property var pluginApi: null

  readonly property bool isActive: HotspotService.isActive
  readonly property bool isLoading: HotspotService.isLoading
  readonly property string currentSsid: HotspotService.currentSsid || ""
  readonly property var connectedDevices: HotspotService.connectedDevices || []
  readonly property string lastError: HotspotService.lastError || ""
  readonly property string wifiInterface: HotspotService.wifiInterface || ""
  readonly property string internetInterface: HotspotService.internetInterface || ""

  readonly property var settings: pluginApi?.pluginSettings || ({})
  readonly property string savedSsid: settings.ssid || "NoctaliaHotspot"
  readonly property string savedPassword: settings.password || ""

  readonly property bool allowAttach: true
  readonly property real contentPreferredWidth: 380 * Style.uiScaleRatio
  readonly property real contentPreferredHeight: 420 * Style.uiScaleRatio * Settings.data.ui.fontDefaultScale

  anchors.fill: parent

  Component.onCompleted: {
    HotspotService.detectInterfaces()
  }

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: Style.marginL
    spacing: Style.marginM

    RowLayout {
      NIcon {
        icon: isActive ? "wifi" : "wifi-off"
        color: isActive ? Color.mPrimary : Color.mOnSurfaceVariant
        pointSize: Style.fontSizeXXL
      }

      NText {
        text: "Hotspot"
        pointSize: Style.fontSizeL
        font.weight: Font.Bold
        color: Color.mOnSurface
        Layout.fillWidth: true
      }

      NBusyIndicator {
        visible: isLoading
        size: 18
      }
    }

    NDivider {}

    NBox {
      Layout.fillWidth: true
      color: Color.mSurfaceVariant
      radius: Style.radiusM

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: Style.marginM
        spacing: Style.marginS

        RowLayout {
          NText { text: "WiFi"; pointSize: Style.fontSizeS; color: Color.mOnSurfaceVariant; Layout.fillWidth: true }
          NText { text: wifiInterface || "--"; pointSize: Style.fontSizeS; color: Color.mOnSurface }
        }

        RowLayout {
          NText { text: "Internet"; pointSize: Style.fontSizeS; color: Color.mOnSurfaceVariant; Layout.fillWidth: true }
          NText { text: internetInterface || "--"; pointSize: Style.fontSizeS; color: Color.mOnSurface }
        }

        RowLayout {
          NText { text: "Status"; pointSize: Style.fontSizeS; color: Color.mOnSurfaceVariant; Layout.fillWidth: true }
          NText { 
            text: isActive ? "Active" : (isLoading ? "Working..." : "Inactive")
            pointSize: Style.fontSizeS
            font.weight: Font.Medium
            color: isActive ? Color.mPrimary : (isLoading ? Color.mPrimary : Color.mOnSurfaceVariant)
          }
        }

        RowLayout {
          NText { text: "Network"; pointSize: Style.fontSizeS; color: Color.mOnSurfaceVariant; Layout.fillWidth: true }
          NText { text: currentSsid || "--"; pointSize: Style.fontSizeS; color: Color.mOnSurface }
        }

        RowLayout {
          NText { text: "Devices"; pointSize: Style.fontSizeS; color: Color.mOnSurfaceVariant; Layout.fillWidth: true }
          NText { 
            text: connectedDevices.length + " connected"
            pointSize: Style.fontSizeS
            color: connectedDevices.length > 0 ? Color.mPrimary : Color.mOnSurfaceVariant
          }
        }
      }
    }

    NText {
      visible: lastError !== ""
      text: lastError
      pointSize: Style.fontSizeS
      color: Color.mError
      wrapMode: Text.WordWrap
      Layout.fillWidth: true
    }

    NButton {
      text: isActive ? "Stop Hotspot" : "Start Hotspot"
      icon: isActive ? "wifi-off" : "wifi"
      backgroundColor: isActive ? Color.mError : Color.mPrimary
      textColor: isActive ? Color.mOnError : Color.mOnPrimary
      Layout.fillWidth: true
      enabled: !isLoading

      onClicked: {
        if (isActive) {
          HotspotService.stopHotspot()
        } else {
          HotspotService.startHotspot(savedSsid, savedPassword)
        }
      }
    }

    NButton {
      visible: isActive
      text: "Refresh Devices"
      icon: "refresh"
      Layout.fillWidth: true
      enabled: !isLoading

      onClicked: {
        HotspotService.refreshDevices()
      }
    }

    NDivider {}

    NBox {
      Layout.fillWidth: true
      Layout.fillHeight: true
      color: Color.mSurfaceVariant
      radius: Style.radiusM

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: Style.marginM
        spacing: Style.marginS

        NText {
          text: "Connected Devices"
          pointSize: Style.fontSizeS
          font.weight: Font.Medium
          color: Color.mOnSurfaceVariant
        }

        Item {
          visible: connectedDevices.length === 0
          Layout.fillWidth: true
          height: 20

          NText {
            text: isActive ? "No devices" : "Hotspot inactive"
            pointSize: Style.fontSizeS
            color: Color.mOnSurfaceVariant
            font.italic: true
            anchors.centerIn: parent
          }
        }

        Repeater {
          visible: connectedDevices.length > 0
          model: connectedDevices.length

          RowLayout {
            Layout.fillWidth: true

            NIcon {
              icon: "device-laptop"
              pointSize: 16
              color: Color.mOnSurfaceVariant
            }

            NText {
              text: connectedDevices[index]?.ssid || "Unknown"
              pointSize: Style.fontSizeS
              color: Color.mOnSurface
              Layout.fillWidth: true
              elide: Text.ElideRight
            }

            NIconButton {
              icon: "close"
              baseSize: 12
              tooltipText: "Disconnect"

              onClicked: {
                const dev = connectedDevices[index]
                if (dev) HotspotService.disconnectDevice(dev.mac)
              }
            }
          }
        }
      }
    }

    NButton {
      text: "Settings"
      icon: "settings"
      Layout.fillWidth: true

      onClicked: {
        if (pluginApi) {
          BarService.openPluginSettings(pluginApi.panelOpenScreen, pluginApi.manifest)
        }
      }
    }
  }
}
