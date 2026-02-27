import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.Commons
import qs.Widgets
import "Services"

Item {
  id: root

  property var pluginApi: null

  property var cfg: pluginApi?.pluginSettings || ({})
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  property string editSsid: cfg.ssid ?? defaults.ssid ?? "NoctaliaHotspot"
  property string editPassword: cfg.password ?? defaults.password ?? ""
  property bool editAutoStart: cfg.autoStart ?? defaults.autoStart ?? false
  property bool editShowNotifications: cfg.showNotifications ?? defaults.showNotifications ?? true
  property bool showPassword: false
  property bool showSavedIndicator: false
  property bool hasChanges: false

  function saveSettings() {
    pluginApi.pluginSettings.ssid = root.editSsid
    pluginApi.pluginSettings.password = root.editPassword
    pluginApi.pluginSettings.autoStart = root.editAutoStart
    pluginApi.pluginSettings.showNotifications = root.editShowNotifications
    pluginApi.saveSettings()

    root.showSavedIndicator = true
    root.hasChanges = false
    savedIndicatorTimer.restart()
  }

  function checkChanges() {
    const cfgVals = cfg || {}
    const defVals = defaults || {}
    const currentSsid = cfgVals.ssid ?? defVals.ssid ?? "NoctaliaHotspot"
    const currentPassword = cfgVals.password ?? defVals.password ?? ""
    const currentAutoStart = cfgVals.autoStart ?? defVals.autoStart ?? false
    const currentNotifications = cfgVals.showNotifications ?? defVals.showNotifications ?? true

    root.hasChanges = editSsid !== currentSsid ||
                      editPassword !== currentPassword ||
                      editAutoStart !== currentAutoStart ||
                      editShowNotifications !== currentNotifications
  }

  Timer {
    id: savedIndicatorTimer
    interval: 2000
    onTriggered: root.showSavedIndicator = false
  }

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: Style.marginL
    spacing: Style.marginM

    RowLayout {
      NIcon {
        icon: "wifi"
        color: Color.mPrimary
        pointSize: Style.fontSizeXXL
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 2

        NText {
          text: "Hotspot Settings"
          color: Color.mOnSurface
          pointSize: Style.fontSizeL
          font.weight: Font.Bold
        }

        NText {
          text: "Configure your WiFi hotspot"
          color: Color.mOnSurfaceVariant
          pointSize: Style.fontSizeXS
        }
      }
    }

    NBox {
      Layout.fillWidth: true
      color: HotspotService.isActive ? Color.mPrimaryContainer : Color.mSurfaceVariant
      radius: Style.radiusM

      RowLayout {
        anchors.fill: parent
        anchors.margins: Style.marginM
        spacing: Style.marginM

        NIcon {
          icon: HotspotService.isActive ? "wifi" : "wifi-off"
          color: HotspotService.isActive ? Color.mOnPrimaryContainer : Color.mOnSurfaceVariant
          pointSize: Style.fontSizeXL
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: 2

          NText {
            text: HotspotService.isActive ? "Hotspot is running" : "Hotspot is stopped"
            color: HotspotService.isActive ? Color.mOnPrimaryContainer : Color.mOnSurfaceVariant
            pointSize: Style.fontSizeS
            font.weight: Font.Medium
          }

          NText {
            text: HotspotService.isActive
              ? "Network: " + (HotspotService.currentSsid || editSsid)
              : "Toggle in panel to start"
            color: HotspotService.isActive ? Color.mOnPrimaryContainer : Color.mOnSurfaceVariant
            pointSize: Style.fontSizeXS
          }
        }

        NBusyIndicator {
          visible: HotspotService.isLoading
          size: 16
          color: HotspotService.isActive ? Color.mOnPrimaryContainer : Color.mOnSurfaceVariant
        }
      }
    }

    NDivider {}

    NText {
      text: "Network Configuration"
      color: Color.mOnSurfaceVariant
      pointSize: Style.fontSizeXS
      font.weight: Font.Medium
    }

    NBox {
      Layout.fillWidth: true
      color: Color.mSurface
      radius: Style.radiusM

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: Style.marginM
        spacing: Style.marginM

        NTextInput {
          Layout.fillWidth: true
          label: "Network Name (SSID)"
          description: "Name of the wireless network"
          text: root.editSsid
          onTextChanged: {
            root.editSsid = text
            root.checkChanges()
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: Style.marginXS

          NText {
            text: "Password"
            color: Color.mOnSurfaceVariant
            pointSize: Style.fontSizeXS
          }

          RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginS

            TextField {
              Layout.fillWidth: true
              text: root.editPassword
              placeholderText: "Enter password (optional)"
              echoMode: root.showPassword ? TextInput.Normal : TextInput.Password
              onTextChanged: {
                root.editPassword = text
                root.checkChanges()
              }

              background: Rectangle {
                color: Color.mSurfaceVariant
                radius: Style.radiusS
              }
            }

            NIconButton {
              icon: root.showPassword ? "eye-off" : "eye"
              tooltipText: root.showPassword ? "Hide password" : "Show password"
              onClicked: root.showPassword = !root.showPassword
            }
          }

          NText {
            text: "Leave empty for open network"
            color: Color.mOnSurfaceVariant
            pointSize: Style.fontSizeXXS
            font.italic: true
          }
        }
      }
    }

    NText {
      text: "Behavior"
      color: Color.mOnSurfaceVariant
      pointSize: Style.fontSizeXS
      font.weight: Font.Medium
    }

    NBox {
      Layout.fillWidth: true
      color: Color.mSurface
      radius: Style.radiusM

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: Style.marginM
        spacing: Style.marginM

        NToggle {
          label: "Auto-start on boot"
          description: "Automatically enable hotspot when system starts"
          checked: root.editAutoStart
          onToggled: {
            root.editAutoStart = checked
            root.checkChanges()
          }
        }

        NToggle {
          label: "Show notifications"
          description: "Display notifications for connect/disconnect events"
          checked: root.editShowNotifications
          onToggled: {
            root.editShowNotifications = checked
            root.checkChanges()
          }
        }
      }
    }

    Item {
      Layout.fillWidth: true
      Layout.minimumHeight: Style.marginS
    }

    NButton {
      text: root.hasChanges ? "Apply Changes" : "Apply"
      Layout.fillWidth: true
      enabled: root.hasChanges || editSsid.length > 0
      onClicked: saveSettings()
    }

    NText {
      visible: root.showSavedIndicator
      text: "Settings saved successfully"
      color: Color.mPrimary
      pointSize: Style.fontSizeXS
      font.italic: true
      horizontalAlignment: Text.AlignHCenter
      Layout.fillWidth: true
    }
  }
}
