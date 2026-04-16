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

import "../../widgets/WindowList"
import "../../widgets/SystemTray"
import "../../widgets/VolumeControl"
import "../../widgets/NetworkStatus"
import "../../widgets/BatteryIndicator"
import "../../widgets/Clock"
import "../../widgets/AppMenu"

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

            // ── LEFT: Start Button (Apollo Logo) ──────────────────
            //
            // Uses logo.png from /usr/share/apollo/logo.png
            // Configurable via apollo-shell.json: panels.taskbar.startButton
            Rectangle {
                id: startBtn
                property var sbCfg: pCfg.startButton ?? {}
                property int  sz:   sbCfg.size ?? 32
                property bool hov:  false
                property string logoPath: sbCfg.logoPath ?? "/usr/share/apollo/logo.png"

                width:  sz + 12
                height: sz + 8
                radius: theme.radius ?? 10
                color:  hov ? (theme.overlay ?? "#252836") : "transparent"
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: 2

                Behavior on color { ColorAnimation { duration: 100 } }

                // Scale effect on hover
                scale: hov ? 1.08 : 1.0
                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutBack } }

                // Logo image with accent-color tint via ColorOverlay
                Image {
                    id: logoImg
                    anchors.centerIn: parent
                    width:  parent.sz
                    height: parent.sz
                    source: "file://" + parent.logoPath
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    antialiasing: true
                    visible: status === Image.Ready

                    // Colorize the black arrow to accent color
                    layer.enabled: true
                    layer.effect: ColorOverlay {
                        id: colorOverlay
                        color: startBtn.hov
                            ? Qt.lighter(theme.accent ?? "#6C8EFF", 1.2)
                            : (theme.accent ?? "#6C8EFF")
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }

                // Nerd Font fallback
                Text {
                    anchors.centerIn: parent
                    text: "󰀻"
                    font.family: theme.font ?? "FiraCode Nerd Font"
                    font.pixelSize: 20
                    color: startBtn.hov
                        ? Qt.lighter(theme.accent ?? "#6C8EFF", 1.2)
                        : (theme.accent ?? "#6C8EFF")
                    visible: !logoImg.visible
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                // Tooltip
                ToolTip {
                    visible: startBtnMa.containsMouse
                    delay: 400
                    text: "App Menu   (Super+A)"
                }

                MouseArea {
                    id: startBtnMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: startBtn.hov = true
                    onExited:  startBtn.hov = false
                    onClicked: appMenuPopup.visible = !appMenuPopup.visible
                }
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
