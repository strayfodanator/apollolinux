// Apollo Shell — Sidebar Panel
// apollo-shell/panels/Sidebar/Sidebar.qml
//
// Collapsible right-side panel with plugin slots.
// Default plugins: weather, calendar, media-player, notes, cpu-graph.
// Toggle via: Super+S or apollo-shell-action toggle-sidebar

import Quickshell
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

PanelWindow {
    id: sidebar

    property var pCfg: ShellRoot.cfg.panels?.sidebar ?? {}
    property var theme: ShellRoot.cfg.theme ?? {}

    property int sidebarWidth: pCfg.width ?? 280
    property bool visible_: false

    // IPC: called from ShellRoot
    function toggle() {
        visible_ = !visible_
        slideAnim.restart()
    }

    anchors {
        top:    true
        bottom: true
        right:  true
    }
    width: sidebarWidth
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: 0  // Sidebar overlays, doesn't push content

    color: "transparent"

    // Slide animation
    property real slideX: visible_ ? 0 : sidebarWidth
    Behavior on slideX { NumberAnimation { id: slideAnim; duration: 280; easing.type: Easing.OutCubic } }

    // Dimming overlay (click to close)
    Rectangle {
        anchors { top: parent.top; bottom: parent.bottom; right: parent.left }
        width: visible_ ? 9999 : 0
        color: "#000000"
        opacity: visible_ ? 0.3 : 0.0
        Behavior on opacity { NumberAnimation { duration: 280 } }
        MouseArea {
            anchors.fill: parent
            onClicked: sidebar.toggle()
        }
    }

    // ── Sidebar body ─────────────────────────────────────────────
    Rectangle {
        anchors { top: parent.top; bottom: parent.bottom; right: parent.right }
        width: sidebar.sidebarWidth
        color: theme.surface ?? "#1a1d27"
        opacity: pCfg.opacity ?? 0.92
        border.color: theme.border ?? "#2e3248"
        border.width: 1
        transform: Translate { x: sidebar.slideX }

        ScrollView {
            anchors { fill: parent; topMargin: 8; bottomMargin: 8 }
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ScrollBar.vertical.policy: ScrollBar.AsNeeded
            clip: true

            Column {
                width: sidebar.sidebarWidth
                spacing: 12
                padding: 12

                // ── Header ────────────────────────────────────────
                RowLayout {
                    width: parent.width - 24

                    Text {
                        text: "Apollo"
                        font.family: theme.font ?? "FiraCode Nerd Font"
                        font.pixelSize: (theme.fontSize ?? 11) + 4
                        font.bold: true
                        color: theme.accent ?? "#6C8EFF"
                    }
                    Item { Layout.fillWidth: true }

                    // Close button
                    Rectangle {
                        width: 24; height: 24; radius: 12
                        color: closeHover.containsMouse ? Qt.alpha(theme.error ?? "#F87171", 0.2) : "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: "󰅙"
                            font.family: theme.font ?? "FiraCode Nerd Font"
                            font.pixelSize: 14
                            color: closeHover.containsMouse ? (theme.error ?? "#F87171") : (theme.textMuted ?? "#8890A4")
                            Behavior on color { ColorAnimation { duration: 100 } }
                        }
                        MouseArea {
                            id: closeHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: sidebar.toggle()
                        }
                        Behavior on color { ColorAnimation { duration: 100 } }
                    }
                }

                Rectangle {
                    width: parent.width - 24
                    height: 1
                    color: theme.border ?? "#2e3248"
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                // ── Plugin slots ──────────────────────────────────
                // Weather plugin
                Loader {
                    width: parent.width - 24
                    anchors.horizontalCenter: parent.horizontalCenter
                    active: ShellRoot.cfg.plugins?.weather?.enabled ?? true
                    source: "../../plugins/weather/Weather.qml"
                    onLoaded: item.theme = sidebar.theme
                }

                SidebarDivider {}

                // Media Player plugin
                Loader {
                    width: parent.width - 24
                    anchors.horizontalCenter: parent.horizontalCenter
                    active: ShellRoot.cfg.plugins?.["media-player"]?.enabled ?? true
                    source: "../../plugins/media-player/MediaPlayer.qml"
                    onLoaded: item.theme = sidebar.theme
                }

                SidebarDivider {}

                // CPU Graph plugin
                Loader {
                    width: parent.width - 24
                    anchors.horizontalCenter: parent.horizontalCenter
                    active: ShellRoot.cfg.plugins?.["cpu-graph"]?.enabled ?? false
                    source: "../../plugins/cpu-graph/CpuGraph.qml"
                    onLoaded: item.theme = sidebar.theme
                }

                SidebarDivider {}

                // Notes plugin
                Loader {
                    width: parent.width - 24
                    anchors.horizontalCenter: parent.horizontalCenter
                    active: ShellRoot.cfg.plugins?.notes?.enabled ?? true
                    source: "../../plugins/notes/Notes.qml"
                    onLoaded: item.theme = sidebar.theme
                }

                // Bottom padding
                Item { height: 16 }
            }
        }
    }
}

// Thin separator between plugin cards
component SidebarDivider : Rectangle {
    width: parent.width - 48
    height: 1
    color: ShellRoot.cfg.theme?.border ?? "#2e3248"
    opacity: 0.5
    anchors.horizontalCenter: parent.horizontalCenter
}
