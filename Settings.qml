import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.Commons
import qs.Widgets
import qs.Services.UI
import "Services"

Item {
  id: root

  property var pluginApi: null
  property var settings: pluginApi ? pluginApi.pluginSettings : ({})

  implicitWidth: 320
  implicitHeight: column.implicitHeight + Style.marginL * 2

  ColumnLayout {
    id: column
    anchors.fill: parent
    anchors.margins: Style.marginL
    spacing: Style.marginM

    NText {
      text: "Hotspot Settings"
      color: Color.mOnSurface
      pointSize: Style.fontSizeL
      font.weight: Font.Bold
      Layout.fillWidth: true
    }

    NText {
      text: "Configure your WiFi hotspot"
      color: Color.mOnSurfaceVariant
      pointSize: Style.fontSizeS
      Layout.fillWidth: true
    }

    NDivider {}

    NText {
      text: "Network Name (SSID)"
      color: Color.mOnSurface
      pointSize: Style.fontSizeS
      Layout.fillWidth: true
    }

    TextField {
      id: ssidField
      Layout.fillWidth: true
      text: settings.ssid || "NoctaliaHotspot"
      placeholderText: "Enter network name"
    }

    NText {
      text: "Password (min 8 characters)"
      color: Color.mOnSurface
      pointSize: Style.fontSizeS
      Layout.fillWidth: true
    }

    TextField {
      id: passwordField
      Layout.fillWidth: true
      text: settings.password || ""
      placeholderText: "Enter password"
      echoMode: TextInput.Password
    }

    NText {
      visible: HotspotService.isActive
      text: "Hotspot is currently running"
      color: Color.mPrimary
      pointSize: Style.fontSizeS
      font.italic: true
      Layout.fillWidth: true
    }

    NDivider {}

    RowLayout {
      Layout.fillWidth: true

      NText {
        text: "Auto-start on boot"
        color: Color.mOnSurface
        pointSize: Style.fontSizeS
        Layout.fillWidth: true
      }

      Switch {
        id: autoStartSwitch
        checked: settings.autoStart === true
      }
    }

    RowLayout {
      Layout.fillWidth: true

      NText {
        text: "Show notifications"
        color: Color.mOnSurface
        pointSize: Style.fontSizeS
        Layout.fillWidth: true
      }

      Switch {
        id: notifSwitch
        checked: settings.showNotifications !== false
      }
    }

    Component.onCompleted: {
      ssidField.textChanged.connect(function() {
        if (pluginApi) {
          pluginApi.pluginSettings.ssid = ssidField.text
          pluginApi.saveSettings()
        }
      })
      passwordField.textChanged.connect(function() {
        if (pluginApi) {
          pluginApi.pluginSettings.password = passwordField.text
          pluginApi.saveSettings()
        }
      })
      autoStartSwitch.checkedChanged.connect(function() {
        if (pluginApi) {
          pluginApi.pluginSettings.autoStart = autoStartSwitch.checked
          pluginApi.saveSettings()
        }
      })
      notifSwitch.checkedChanged.connect(function() {
        if (pluginApi) {
          pluginApi.pluginSettings.showNotifications = notifSwitch.checked
          pluginApi.saveSettings()
        }
      })
    }
  }
}
