// Apollo Shell — Media Player Plugin
// apollo-shell/plugins/media-player/MediaPlayer.qml
//
// MPRIS2 mini media player for the taskbar/sidebar.
// Works with any MPRIS2-capable player (Spotify, VLC, mpv, etc.)

import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    property var theme: ({})
    property string fontFamily: theme.font ?? "FiraCode Nerd Font"
    property int    fontSize: theme.fontSize ?? 11
    property string accentColor: theme.accent ?? "#6C8EFF"
    property string textColor: theme.text ?? "#E8EAF0"
    property string mutedColor: theme.textMuted ?? "#8890A4"
    property string surfaceColor: theme.surface ?? "#1a1d27"
    property string overlayColor: theme.overlay ?? "#252836"
    property int    radius: theme.radius ?? 10

    property int maxTitleLength: 30

    implicitWidth: 260
    implicitHeight: 72

    // ── MPRIS2 ───────────────────────────────────────────────────
    MprisController { id: mpris }

    property var player: mpris.players.length > 0 ? mpris.players[0] : null
    property bool isPlaying: player?.playbackStatus === MprisPlaybackStatus.Playing ?? false
    property string title:  player?.metadata?.title ?? "Nothing playing"
    property string artist: player?.metadata?.artist ?? ""
    property string album:  player?.metadata?.album ?? ""

    function truncate(str, max) {
        return str.length > max ? str.substring(0, max - 1) + "…" : str
    }

    // ── UI ────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: root.overlayColor
        radius: root.radius
        border.color: root.accentColor
        border.width: 1
        opacity: player ? 1.0 : 0.4

        ColumnLayout {
            anchors { fill: parent; margins: 10 }
            spacing: 6

            // Track info
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                // Album art placeholder
                Rectangle {
                    width: 40; height: 40; radius: 6
                    color: Qt.alpha(root.accentColor, 0.2)
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        anchors.centerIn: parent
                        text: "󰝚"
                        font.family: root.fontFamily
                        font.pixelSize: 20
                        color: root.accentColor
                    }
                }

                Column {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: root.truncate(root.title, root.maxTitleLength)
                        font.family: root.fontFamily
                        font.pixelSize: root.fontSize
                        font.bold: true
                        color: root.textColor
                        elide: Text.ElideRight
                        width: parent.width
                    }
                    Text {
                        text: root.artist !== "" ? root.artist : (root.player?.identity ?? "—")
                        font.family: root.fontFamily
                        font.pixelSize: root.fontSize - 2
                        color: root.mutedColor
                        elide: Text.ElideRight
                        width: parent.width
                    }
                }
            }

            // Controls
            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                spacing: 4

                Repeater {
                    model: [
                        { icon: "󰒮", action: "prev",  tip: "Previous" },
                        { icon: root.isPlaying ? "󰏤" : "󰐊", action: "play", tip: root.isPlaying ? "Pause" : "Play" },
                        { icon: "󰒭", action: "next",  tip: "Next" }
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        width: 32; height: 32; radius: 8
                        color: ctrlMouse.containsMouse ? Qt.alpha(root.accentColor, 0.2) : "transparent"
                        Behavior on color { ColorAnimation { duration: 100 } }

                        Text {
                            anchors.centerIn: parent
                            text: modelData.icon
                            font.family: root.fontFamily
                            font.pixelSize: root.fontSize + 4
                            color: modelData.action === "play" ? root.accentColor : root.mutedColor
                        }

                        MouseArea {
                            id: ctrlMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (!root.player) return
                                if (modelData.action === "play") root.player.playPause()
                                else if (modelData.action === "next") root.player.next()
                                else if (modelData.action === "prev") root.player.previous()
                            }
                            ToolTip { visible: parent.containsMouse; delay: 400; text: modelData.tip }
                        }
                    }
                }
            }
        }
    }

    // Show placeholder when no player
    Text {
        anchors.centerIn: parent
        text: "No media playing"
        font.family: root.fontFamily
        font.pixelSize: root.fontSize - 1
        color: root.mutedColor
        visible: !root.player
    }
}
