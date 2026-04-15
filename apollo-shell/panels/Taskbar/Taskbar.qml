// Apollo Shell — Taskbar (Bottom Panel)
// apollo-shell/panels/Taskbar/Taskbar.qml
//
// The main bottom panel. Contains:
//   Left:   App Menu button, Window List (task buttons)
//   Right:  System Tray, Volume, Network, Battery, Clock

import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import Quickshell.Services.Pipewire
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

PanelWindow {
    id: taskbar

    // ── Read config from ShellRoot ────────────────────────────────
    property var pCfg: ShellRoot.cfg.panels?.taskbar ?? {}
    property var theme: ShellRoot.cfg.theme ?? {}

    // ── Geometry ─────────────────────────────────────────────────
    anchors {
        bottom: true
        left:   true
        right:  true
    }
    height: pCfg.height ?? 44
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.exclusiveZone: height

    // ── Allow app menou toggle from IPC ───────────────────────────
    function toggleAppMenu() {
        appMenuPopup.visible = !appMenuPopup.visible
    }

    // ── Background ────────────────────────────────────────────────
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        color: theme.surface ?? "#1a1d27"
        opacity: pCfg.opacity ?? 0.92

        // Top border
        Rectangle {
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: 1
            color: theme.border ?? "#2e3248"
            visible: pCfg.border ?? true
        }

        // ── Main layout ───────────────────────────────────────────
        RowLayout {
            anchors {
                fill: parent
                leftMargin: 8
                rightMargin: 8
            }
            spacing: 4

            // ── LEFT: App Menu button ─────────────────────────────
            ApolloButton {
                id: appMenuBtn
                icon: "󰀻"
                label: "Apps"
                font: theme.font ?? "FiraCode Nerd Font"
                fontSize: (theme.fontSize ?? 11) + 1
                accentColor: theme.accent ?? "#6C8EFF"
                bgColor: theme.surface ?? "#1a1d27"
                hoverColor: theme.overlay ?? "#252836"
                radius: theme.radius ?? 10
                onClicked: appMenuPopup.visible = !appMenuPopup.visible
                Layout.preferredWidth: 80
                Layout.fillHeight: true
            }

            // Separator
            Rectangle {
                width: 1; height: parent.height * 0.6
                color: theme.border ?? "#2e3248"
                Layout.alignment: Qt.AlignVCenter
            }

            // ── LEFT: Window List (task buttons) ─────────────────
            WindowList {
                id: windowList
                Layout.fillWidth: true
                Layout.fillHeight: true
                maxButtonWidth: 180
                showIcons: true
                showLabels: true
                theme: taskbar.theme
            }

            // ── RIGHT: Widgets ────────────────────────────────────
            // System Tray
            SysTrayWidget {
                iconSize: 18
                spacing: 4
                theme: taskbar.theme
                Layout.alignment: Qt.AlignVCenter
            }

            Rectangle { width: 1; height: parent.height * 0.5; color: theme.border ?? "#2e3248"; Layout.alignment: Qt.AlignVCenter }

            // Volume
            VolumeWidget {
                theme: taskbar.theme
                Layout.alignment: Qt.AlignVCenter
            }

            // Network
            NetworkWidget {
                theme: taskbar.theme
                Layout.alignment: Qt.AlignVCenter
            }

            // Battery (only shown if battery exists)
            BatteryWidget {
                theme: taskbar.theme
                Layout.alignment: Qt.AlignVCenter
                visible: hasBattery
            }

            Rectangle { width: 1; height: parent.height * 0.5; color: theme.border ?? "#2e3248"; Layout.alignment: Qt.AlignVCenter }

            // Clock
            ClockWidget {
                format: "HH:mm"
                showDateOnHover: true
                dateFormat: "ddd DD MMM"
                theme: taskbar.theme
                Layout.alignment: Qt.AlignVCenter
                Layout.rightMargin: 4
            }
        }
    }

    // ── App Menu Popup ────────────────────────────────────────────
    AppMenuPopup {
        id: appMenuPopup
        visible: false
        x: 0
        y: -height - 4
        theme: taskbar.theme
    }
}
