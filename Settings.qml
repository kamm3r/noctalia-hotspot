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
  property bool showPassword: false
  property int saveIndicator: 0

  function saveWithIndicator() {
    pluginApi.saveSettings()
    saveIndicator = 1
    saveIndicatorTimer.restart()
  }

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

    RowLayout {
      Layout.fillWidth: true

      TextField {
        id: passwordField
        Layout.fillWidth: true
        text: settings.password || ""
        placeholderText: "Enter password"
        echoMode: root.showPassword ? TextInput.Normal : TextInput.Password
      }

      NIconButton {
        icon: root.showPassword ? "eye-off" : "eye"
        tooltipText: root.showPassword ? "Hide password" : "Show password"
        baseSize: Style.baseWidgetSize * 0.75
        onClicked: {
          root.showPassword = !root.showPassword
        }
      }
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

    RowLayout {
      Layout.fillWidth: true
      Layout.topMargin: Style.marginS

      NText {
        text: saveIndicator === 1 ? "Settings saved" : ""
        color: Color.mPrimary
        pointSize: Style.fontSizeXS
        font.italic: true
        Layout.fillWidth: true
      }
    }

    Timer {
      id: saveIndicatorTimer
      interval: 2000
      onTriggered: {
        saveIndicator = 0
      }
    }

    Component.onCompleted: {
      if (pluginApi) {
        ssidField.text = pluginApi.pluginSettings.ssid || "NoctaliaHotspot"
        passwordField.text = pluginApi.pluginSettings.password || ""
        autoStartSwitch.checked = pluginApi.pluginSettings.autoStart === true
        notifSwitch.checked = pluginApi.pluginSettings.showNotifications !== false
      }

      ssidField.textChanged.connect(function() {
        if (pluginApi) {
          pluginApi.pluginSettings.ssid = ssidField.text
          root.saveWithIndicator()
        }
      })
      passwordField.textChanged.connect(function() {
        if (pluginApi) {
          pluginApi.pluginSettings.password = passwordField.text
          root.saveWithIndicator()
        }
      })
      autoStartSwitch.checkedChanged.connect(function() {
        if (pluginApi) {
          pluginApi.pluginSettings.autoStart = autoStartSwitch.checked
          root.saveWithIndicator()
        }
      })
      notifSwitch.checkedChanged.connect(function() {
        if (pluginApi) {
          pluginApi.pluginSettings.showNotifications = notifSwitch.checked
          root.saveWithIndicator()
        }
      })
    }
  }
}
