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
  property bool showSavedIndicator: false

  function saveSettings() {
    pluginApi.pluginSettings.ssid = root.editSsid
    pluginApi.pluginSettings.password = root.editPassword
    pluginApi.pluginSettings.autoStart = root.editAutoStart
    pluginApi.pluginSettings.showNotifications = root.editShowNotifications
    pluginApi.saveSettings()

    root.showSavedIndicator = true
    savedIndicatorTimer.restart()
  }

  Timer {
    id: savedIndicatorTimer
    interval: 2000
    onTriggered: root.showSavedIndicator = false
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

  NToggle {
    label: "Auto-start on boot"
    checked: root.editAutoStart
    onToggled: root.editAutoStart = checked
  }

  NToggle {
    label: "Show notifications"
    checked: root.editShowNotifications
    onToggled: root.editShowNotifications = checked
  }

  NButton {
    text: "Apply"
    Layout.fillWidth: true
    onClicked: saveSettings()
  }

  NText {
    visible: root.showSavedIndicator
    text: "Settings saved"
    color: Color.mPrimary
    pointSize: Style.fontSizeXS
    font.italic: true
  }
}
