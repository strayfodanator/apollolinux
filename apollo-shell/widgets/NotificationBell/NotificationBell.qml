// Apollo Shell — Notification Bell Widget
// apollo-shell/widgets/NotificationBell/NotificationBell.qml
//
// Shows unread notification count from dunst.
// Click to toggle notification center (if notification center plugin is active).

import Quickshell
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Controls

Item {
    id: root

    property string iconActive: "󰂚"
    property string iconMuted: "󰂛"
    property bool   showCount: true
    property string accentColor: "#6C8EFF"
    property string textColor: "#E8EAF0"
    property string mutedColor: "#8890A4"
    property string fontFamily: "FiraCode Nerd Font"
    property int    fontSize: 12
    property var    theme: ({})

    property bool muted: false
    property int  unreadCount: 0

    implicitWidth: row.implicitWidth + 12
    implicitHeight: parent ? parent.height : 28

    // Track notifications from Quickshell's notification server
    NotificationServer {
        id: notifServer
        // When a new notification arrives, increment counter
        onNotification: (notif) => {
            if (!root.muted) root.unreadCount++
        }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 3

        Text {
            text: root.muted ? root.iconMuted : root.iconActive
            font.family: root.fontFamily
            font.pixelSize: root.fontSize + 2
            color: root.muted ? root.mutedColor
                 : root.unreadCount > 0 ? root.accentColor
                 : root.mutedColor
            verticalAlignment: Text.AlignVCenter
            Behavior on color { ColorAnimation { duration: 150 } }
        }

        // Count badge
        Rectangle {
            visible: root.showCount && root.unreadCount > 0 && !root.muted
            width: Math.max(16, countLabel.implicitWidth + 6)
            height: 16
            radius: 8
            color: root.accentColor
            anchors.verticalCenter: parent.verticalCenter

            Text {
                id: countLabel
                anchors.centerIn: parent
                text: root.unreadCount > 99 ? "99+" : root.unreadCount.toString()
                font.family: root.fontFamily
                font.pixelSize: root.fontSize - 3
                font.bold: true
                color: "white"
            }

            Behavior on visible {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200 }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor

        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                // Toggle DnD via dunst
                root.muted = !root.muted
                const cmd = root.muted ? ["dunstctl", "set-paused", "true"]
                                       : ["dunstctl", "set-paused", "false"]
                Qt.createQmlObject(
                    `import Quickshell.Io; Process { command: ${JSON.stringify(cmd)}; running: true }`,
                    root)
            } else {
                // Left click: clear count + show history  
                root.unreadCount = 0
                Qt.createQmlObject(
                    `import Quickshell.Io; Process { command: ["dunstctl", "history-pop"]; running: true }`,
                    root)
            }
        }

        ToolTip {
            visible: parent.containsMouse
            delay: 400
            text: root.muted ? "Notifications paused (right-click to resume)"
                : root.unreadCount > 0 ? root.unreadCount + " unread notification" + (root.unreadCount > 1 ? "s" : "")
                : "No new notifications"
        }
    }
}
