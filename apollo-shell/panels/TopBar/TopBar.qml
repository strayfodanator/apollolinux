// Apollo Shell — TopBar (Top Panel)
// apollo-shell/panels/TopBar/TopBar.qml
//
// Slim top panel. Contains:
//   Left:   Workspace Pager, Active Window Title
//   Right:  Notification Bell, Date+Time

import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

PanelWindow {
    id: topbar

    property var pCfg: ShellRoot.cfg.panels?.topbar ?? {}
    property var theme: ShellRoot.cfg.theme ?? {}

    anchors {
        top:   true
        left:  true
        right: true
    }
    height: pCfg.height ?? 28
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.exclusiveZone: height

    color: "transparent"

    Rectangle {
        anchors.fill: parent
        color: theme.surface ?? "#1a1d27"
        opacity: pCfg.opacity ?? 0.88

        // Bottom border
        Rectangle {
            anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
            height: 1
            color: theme.border ?? "#2e3248"
            visible: pCfg.border ?? true
        }

        RowLayout {
            anchors {
                fill: parent
                leftMargin: 10
                rightMargin: 10
            }
            spacing: 8

            // ── LEFT: Workspace Pager ─────────────────────────────
            WorkspacePager {
                id: pager
                style: "dots"         // "dots" | "numbers" | "names"
                dotSize: 8
                activeColor: theme.accent ?? "#6C8EFF"
                inactiveColor: theme.textMuted ?? "#8890A4"
                occupiedColor: theme.text ?? "#E8EAF0"
                spacing: 6
                theme: topbar.theme
                Layout.alignment: Qt.AlignVCenter
            }

            Rectangle { width: 1; height: parent.height * 0.6; color: theme.border ?? "#2e3248"; Layout.alignment: Qt.AlignVCenter }

            // ── CENTER: Active Window Title ────────────────────────
            ActiveWindowTitle {
                id: windowTitle
                maxLength: 60
                showIcon: true
                iconSize: 14
                color: theme.text ?? "#E8EAF0"
                mutedColor: theme.textMuted ?? "#8890A4"
                fontFamily: theme.font ?? "FiraCode Nerd Font"
                fontSize: (theme.fontSize ?? 11) - 1
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
            }

            // ── RIGHT: Notification Bell ───────────────────────────
            NotificationBell {
                id: notifBell
                iconActive: "󰂚"
                iconMuted: "󰂛"
                showCount: true
                accentColor: theme.accent ?? "#6C8EFF"
                theme: topbar.theme
                Layout.alignment: Qt.AlignVCenter
            }

            Rectangle { width: 1; height: parent.height * 0.6; color: theme.border ?? "#2e3248"; Layout.alignment: Qt.AlignVCenter }

            // ── RIGHT: Full Date+Time ─────────────────────────────
            ClockWidget {
                format: "HH:mm:ss"
                showDate: true
                dateFormat: "dddd, DD MMMM"
                style: "minimal"
                theme: topbar.theme
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }
}
