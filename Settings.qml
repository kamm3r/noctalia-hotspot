import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.Commons
import qs.Widgets
import "Services"

ColumnLayout {
  id: root

  property var pluginApi: null

  property var cfg: pluginApi?.pluginSettings || ({})
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  property string editSsid: cfg.ssid ?? defaults.ssid ?? "NoctaliaHotspot"
  property string editPassword: cfg.password ?? defaults.password ?? ""
  property bool editAutoStart: cfg.autoStart ?? defaults.autoStart ?? false
  property bool editShowNotifications: cfg.showNotifications ?? defaults.showNotifications ?? true
  property bool showPassword: false

  function saveSettings() {
    pluginApi.pluginSettings.ssid = root.editSsid
    pluginApi.pluginSettings.password = root.editPassword
    pluginApi.pluginSettings.autoStart = root.editAutoStart
    pluginApi.pluginSettings.showNotifications = root.editShowNotifications
    pluginApi.saveSettings()

    Logger.i("Hotspot", "Settings saved")
  }

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

  NTextInput {
    Layout.fillWidth: true
    label: "Network Name (SSID)"
    description: "Name of the wireless network"
    text: root.editSsid
    onTextChanged: root.editSsid = text
    onEditingFinished: saveSettings()
  }

  RowLayout {
    Layout.fillWidth: true
    spacing: Style.marginS

    TextField {
      Layout.fillWidth: true
      text: root.editPassword
      placeholderText: "Enter password"
      echoMode: root.showPassword ? TextInput.Normal : TextInput.Password
      onTextChanged: root.editPassword = text
      onEditingFinished: saveSettings()
    }

    NIconButton {
      icon: root.showPassword ? "eye-off" : "eye"
      tooltipText: root.showPassword ? "Hide password" : "Show password"
      onClicked: root.showPassword = !root.showPassword
    }
  }

  NText {
    text: "Password"
    color: Color.mOnSurfaceVariant
    pointSize: Style.fontSizeXS
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
      checked: root.editAutoStart
      onCheckedChanged: {
        root.editAutoStart = checked
        saveSettings()
      }
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
      checked: root.editShowNotifications
      onCheckedChanged: {
        root.editShowNotifications = checked
        saveSettings()
      }
    }
  }
}
