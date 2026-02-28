import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null
  property var settings: pluginApi?.pluginSettings ?? {}

  property string editSsid: settings.ssid ?? "NoctaliaHotspot"
  property string editPassword: settings.password ?? ""
  property bool showPassword: false

  spacing: Style.marginL

  NTextInput {
    Layout.fillWidth: true
    label: "Network Name (SSID)"
    description: "Name of your WiFi hotspot"
    text: root.editSsid
    onTextChanged: {
      root.editSsid = text
      pluginApi.pluginSettings.ssid = text
      pluginApi.saveSettings()
    }
  }

  NText {
    text: "Password"
    color: Color.mOnSurfaceVariant
    pointSize: Style.fontSizeXS
  }

  RowLayout {
    Layout.fillWidth: true
    spacing: 8

    Control {
      Layout.fillWidth: true
      Layout.minimumWidth: 80 * Style.uiScaleRatio
      implicitHeight: Style.baseWidgetSize * 1.1 * Style.uiScaleRatio

      focusPolicy: Qt.StrongFocus
      hoverEnabled: true

      property bool isFocused: passwordInput.activeFocus

      background: Rectangle {
        radius: Style.iRadiusM
        color: Color.mSurface
        border.color: passwordInput.activeFocus ? Color.mSecondary : Color.mOutline
        border.width: Style.borderS
      }

      contentItem: TextField {
        id: passwordInput
        anchors.fill: parent
        anchors.leftMargin: Style.marginM
        anchors.rightMargin: Style.marginM
        verticalAlignment: TextInput.AlignVCenter
        text: root.editPassword
        placeholderText: "Enter password"
        echoMode: root.showPassword ? TextInput.Normal : TextInput.Password
        placeholderTextColor: Qt.alpha(Color.mOnSurfaceVariant, 0.6)
        color: Color.mOnSurface
        background: null
        selectByMouse: true
        topPadding: 0
        bottomPadding: 0
        leftPadding: 0
        rightPadding: 0

        onTextChanged: {
          root.editPassword = text
          pluginApi.pluginSettings.password = text
          pluginApi.saveSettings()
        }
      }
    }

    NIconButton {
      icon: root.showPassword ? "eye-off" : "eye"
      onClicked: root.showPassword = !root.showPassword
    }
  }
}
