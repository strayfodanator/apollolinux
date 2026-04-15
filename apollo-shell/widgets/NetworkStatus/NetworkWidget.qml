// Apollo Shell — Network Status Widget
// apollo-shell/widgets/NetworkStatus/NetworkWidget.qml
//
// Shows WiFi/Ethernet connectivity state and signal strength.
// Click opens nm-connection-editor.

import Quickshell.Services.NetworkManager
import QtQuick
import QtQuick.Controls

Item {
    id: root

    property var theme: ({})
    property string fontFamily: theme.font ?? "FiraCode Nerd Font"
    property int    fontSize: theme.fontSize ?? 12
    property string textColor: theme.text ?? "#E8EAF0"
    property string mutedColor: theme.textMuted ?? "#8890A4"
    property string accentColor: theme.accent ?? "#6C8EFF"
    property string errorColor: theme.error ?? "#F87171"
    property string successColor: theme.success ?? "#4ADE80"

    implicitWidth: row.implicitWidth + 12
    implicitHeight: parent ? parent.height : 36

    // ── NetworkManager state ──────────────────────────────────────
    NetworkManager { id: nm }

    property var activeConn: nm.primaryConnection
    property bool isWifi: activeConn?.type === "802-11-wireless"
    property bool isEth:  activeConn?.type === "802-3-ethernet"
    property bool connected: nm.connectivity !== NetworkManager.Connectivity.None
    property int  signalStrength: isWifi ? (activeConn?.wirelessDevice?.activeAccessPoint?.strength ?? 0) : 100

    function netIcon(): string {
        if (!connected) return "󰤭"
        if (isWifi) {
            if (signalStrength >= 75) return "󰤨"
            if (signalStrength >= 50) return "󰤥"
            if (signalStrength >= 25) return "󰤢"
            return "󰤟"
        }
        if (isEth) return "󰈀"
        return "󰛳"
    }

    function netColor(): string {
        if (!connected) return root.errorColor
        return root.accentColor
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 4

        Text {
            text: root.netIcon()
            font.family: root.fontFamily
            font.pixelSize: root.fontSize + 2
            color: root.netColor()
            verticalAlignment: Text.AlignVCenter
            Behavior on color { ColorAnimation { duration: 200 } }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Qt.openUrlExternally("nm-connection-editor")

        ToolTip {
            visible: parent.containsMouse
            delay: 400
            text: {
                if (!root.connected) return "Disconnected"
                if (root.isWifi)
                    return (root.activeConn?.id ?? "WiFi") + "  " + root.signalStrength + "%"
                if (root.isEth)
                    return "Ethernet: " + (root.activeConn?.id ?? "Connected")
                return "Connected"
            }
        }
    }
}
