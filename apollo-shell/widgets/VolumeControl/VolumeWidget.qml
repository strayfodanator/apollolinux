// Apollo Shell — Volume Control Widget
// apollo-shell/widgets/VolumeControl/VolumeWidget.qml
//
// Shows current volume with Nerd Font icon.
// Scroll to change volume. Click to open mini slider popup.
// Uses PipeWire via Quickshell.Services.Pipewire.

import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    property var theme: ({})
    property string fontFamily: theme.font ?? "FiraCode Nerd Font"
    property int    fontSize: theme.fontSize ?? 12
    property string textColor: theme.text ?? "#E8EAF0"
    property string accentColor: theme.accent ?? "#6C8EFF"
    property string mutedColor: theme.textMuted ?? "#8890A4"
    property string surfaceColor: theme.surface ?? "#1a1d27"
    property string overlayColor: theme.overlay ?? "#252836"
    property int    radius: theme.radius ?? 10

    implicitWidth: row.implicitWidth + 16
    implicitHeight: parent ? parent.height : 36

    // ── PipeWire sink ─────────────────────────────────────────────
    PwNodeLinkage { id: audio }

    property var  sink:   audio.defaultSink
    property real volume: sink ? Math.round(sink.volume * 100) : 0
    property bool muted:  sink ? sink.muted : false

    // ── Volume icon selection ─────────────────────────────────────
    function volIcon(): string {
        if (muted || volume === 0) return "󰝟"
        if (volume < 30) return "󰕿"
        if (volume < 70) return "󰖀"
        return "󰕾"
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 4

        Text {
            id: volIcon
            text: root.volIcon()
            font.family: root.fontFamily
            font.pixelSize: root.fontSize + 2
            color: root.muted ? root.mutedColor : root.accentColor
            verticalAlignment: Text.AlignVCenter
        }

        Text {
            text: root.muted ? "  " : root.volume + "%"
            font.family: root.fontFamily
            font.pixelSize: root.fontSize - 1
            color: root.muted ? root.mutedColor : root.textColor
            verticalAlignment: Text.AlignVCenter
        }
    }

    // ── Mouse interactions ────────────────────────────────────────
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor

        onClicked: (mouse) => {
            if (mouse.button === Qt.MiddleButton) {
                if (root.sink) root.sink.muted = !root.sink.muted
            } else {
                sliderPopup.visible = !sliderPopup.visible
            }
        }

        onWheel: (wheel) => {
            if (!root.sink) return
            const delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05
            root.sink.volume = Math.max(0, Math.min(1.5, root.sink.volume + delta))
        }
    }

    // ── Volume Slider Popup ───────────────────────────────────────
    Rectangle {
        id: sliderPopup
        visible: false
        width: 160
        height: 44
        x: -(width / 2) + (root.width / 2)
        y: -(height + 8)
        color: root.overlayColor
        radius: root.radius
        border.color: "#2e3248"
        border.width: 1

        // Shadow effect (approximated)
        layer.enabled: true
        layer.effect: null  // real shadow via picom

        RowLayout {
            anchors { fill: parent; margins: 10 }
            spacing: 8

            Text {
                text: root.volIcon()
                font.family: root.fontFamily
                font.pixelSize: root.fontSize + 2
                color: root.accentColor
            }

            Slider {
                id: volSlider
                Layout.fillWidth: true
                from: 0; to: 150; stepSize: 1
                value: root.volume

                background: Rectangle {
                    x: volSlider.leftPadding
                    y: volSlider.topPadding + volSlider.availableHeight / 2 - height / 2
                    width: volSlider.availableWidth
                    height: 4
                    radius: 2
                    color: "#2e3248"
                    Rectangle {
                        width: volSlider.visualPosition * parent.width
                        height: parent.height
                        color: root.accentColor
                        radius: 2
                    }
                }
                handle: Rectangle {
                    x: volSlider.leftPadding + volSlider.visualPosition * (volSlider.availableWidth - width)
                    y: volSlider.topPadding + volSlider.availableHeight / 2 - height / 2
                    width: 14; height: 14; radius: 7
                    color: "white"
                    border.color: root.accentColor
                    border.width: 2
                }
                onMoved: { if (root.sink) root.sink.volume = value / 100 }
            }
        }
    }

    // Close popup when clicking elsewhere
    Connections {
        target: sliderPopup.visible ? Qt.application : null
        function onActiveWindowChanged() { sliderPopup.visible = false }
    }
}
