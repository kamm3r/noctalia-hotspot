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
    readonly property real contentPreferredHeight: isActive 
        ? 200 * Style.uiScaleRatio * Settings.data.ui.fontDefaultScale 
        : 100 * Style.uiScaleRatio * Settings.data.ui.fontDefaultScale

    anchors.fill: parent

    Component.onCompleted: {
        HotspotService.detectInterfaces();
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Style.marginL
        spacing: Style.marginS

        RowLayout {
            NIcon {
                icon: isActive ? "access-point" : "access-point-off"
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

            NToggle {
                Layout.fillWidth: false
                checked: isActive
                enabled: !isLoading
                onToggled: {
                    if (checked) {
                        HotspotService.startHotspot(savedSsid, savedPassword);
                    } else {
                        HotspotService.stopHotspot();
                    }
                }
            }

            NIconButton {
                icon: "settings"
                tooltipText: "Settings"
                onClicked: {
                    if (pluginApi) {
                        BarService.openPluginSettings(pluginApi.panelOpenScreen, pluginApi.manifest);
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

        NBox {
            visible: isActive
            Layout.fillWidth: true
            Layout.preferredHeight: 80 * Style.uiScaleRatio
            color: Color.mSurfaceVariant
            radius: Style.radiusM

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Style.marginM
                spacing: Style.marginXS

                RowLayout {
                    Layout.fillWidth: true

                    NText {
                        text: "Connected Devices"
                        pointSize: Style.fontSizeS
                        font.weight: Font.Medium
                        color: Color.mOnSurfaceVariant
                        Layout.fillWidth: true
                    }

                    NIconButton {
                        icon: "refresh"
                        tooltipText: "Refresh"
                        baseSize: Style.baseWidgetSize * 0.7
                        enabled: !isLoading
                        onClicked: HotspotService.refreshDevices()
                    }
                }

                Item {
                    visible: connectedDevices.length === 0
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    NText {
                        text: "No devices"
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
                            pointSize: 14
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
                            baseSize: 10
                            tooltipText: "Disconnect"

                            onClicked: {
                                const dev = connectedDevices[index];
                                if (dev)
                                    HotspotService.disconnectDevice(dev.mac);
                            }
                        }
                    }
                }
            }
        }
    }
}
