// Apollo Linux — Calamares Desktop Choice Module
// apollo-calamares/modules/apollo-desktop-choice/DesktopChoice.qml
//
// Custom QML page shown in Calamares before partitioning.
// Reads hardware recommendation from GlobalStorage (apollo-detect output)
// and lets user confirm / override the desktop mode.

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.kde.calamares 1.0 as Calamares

Item {
    id: root
    anchors.fill: parent

    // ── Read hardware detection from GlobalStorage ─────────────────────────────
    property string detectedGpu:     Calamares.GlobalStorage.value("apollo_gpu_model") ?? "Unknown GPU"
    property string detectedDriver:  Calamares.GlobalStorage.value("apollo_gpu_driver") ?? "unknown"
    property bool   waylandOk:       Calamares.GlobalStorage.value("apollo_gpu_wayland") === "true"
    property string ramMB:           Calamares.GlobalStorage.value("apollo_ram_mb") ?? "0"
    property string defaultDesktop:  Calamares.GlobalStorage.value("apollo_desktop_default") ?? "apollo-desktop"
    property bool   desktopLocked:   Calamares.GlobalStorage.value("apollo_desktop_locked") === "true"
    property string lockReason:      Calamares.GlobalStorage.value("apollo_desktop_reason") ?? ""

    property string chosenDesktop: defaultDesktop

    // Write final choice back to storage
    function isComplete() { return true }
    function onLeave() {
        Calamares.GlobalStorage.insert("apollo_desktop_chosen", root.chosenDesktop)
    }

    // ── Colors ────────────────────────────────────────────────────────────────
    readonly property string bg:      "#0f1117"
    readonly property string surface: "#1a1d27"
    readonly property string overlay: "#252836"
    readonly property string border_: "#2e3248"
    readonly property string accent:  "#6C8EFF"
    readonly property string accent2: "#A78BFA"
    readonly property string text:    "#E8EAF0"
    readonly property string muted:   "#8890A4"
    readonly property string green:   "#4ADE80"
    readonly property string yellow:  "#FBBF24"
    readonly property string red:     "#F87171"

    // ── Background ────────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: root.bg
    }

    // ── Layout ────────────────────────────────────────────────────────────────
    ColumnLayout {
        anchors { fill: parent; margins: 32 }
        spacing: 20

        // Header
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 6

            Text {
                text: "Choose Your Desktop"
                font { family: "FiraCode Nerd Font"; pixelSize: 22; bold: true }
                color: root.text
                Layout.alignment: Qt.AlignHCenter
            }
            Text {
                text: "Based on your hardware, we recommend:"
                font { family: "FiraCode Nerd Font"; pixelSize: 12 }
                color: root.muted
                Layout.alignment: Qt.AlignHCenter
            }
        }

        // Hardware info card
        Rectangle {
            Layout.fillWidth: true
            height: hwCol.implicitHeight + 20
            color: root.surface
            radius: 10
            border.color: root.border_
            border.width: 1

            Column {
                id: hwCol
                anchors { fill: parent; margins: 14 }
                spacing: 6

                Row {
                    spacing: 10
                    Text { text: ""; font.family: "FiraCode Nerd Font"; font.pixelSize: 13; color: root.accent; width: 22 }
                    Text { text: "GPU:"; font.family: "FiraCode Nerd Font"; font.pixelSize: 11; color: root.muted; width: 60 }
                    Text { text: root.detectedGpu; font.family: "FiraCode Nerd Font"; font.pixelSize: 11; color: root.text; elide: Text.ElideRight }
                }
                Row {
                    spacing: 10
                    Text { text: "󰻠"; font.family: "FiraCode Nerd Font"; font.pixelSize: 13; color: root.accent; width: 22 }
                    Text { text: "Driver:"; font.family: "FiraCode Nerd Font"; font.pixelSize: 11; color: root.muted; width: 60 }
                    Text { text: root.detectedDriver; font.family: "FiraCode Nerd Font"; font.pixelSize: 11; color: root.text }
                }
                Row {
                    spacing: 10
                    Text { text: ""; font.family: "FiraCode Nerd Font"; font.pixelSize: 13; color: root.accent; width: 22 }
                    Text { text: "Wayland:"; font.family: "FiraCode Nerd Font"; font.pixelSize: 11; color: root.muted; width: 60 }
                    Text {
                        text: root.waylandOk ? "✓ Supported" : "✗ Not supported (X11 only)"
                        font.family: "FiraCode Nerd Font"; font.pixelSize: 11
                        color: root.waylandOk ? root.green : root.yellow
                    }
                }
                Row {
                    spacing: 10
                    Text { text: ""; font.family: "FiraCode Nerd Font"; font.pixelSize: 13; color: root.accent; width: 22 }
                    Text { text: "RAM:"; font.family: "FiraCode Nerd Font"; font.pixelSize: 11; color: root.muted; width: 60 }
                    Text { text: (Math.round(parseInt(root.ramMB) / 1024)) + " GB"; font.family: "FiraCode Nerd Font"; font.pixelSize: 11; color: root.text }
                }
            }
        }

        // Desktop choice cards
        Row {
            Layout.fillWidth: true
            spacing: 16

            // ── Apollo Desktop Card ────────────────────────────────────────
            Rectangle {
                width: (parent.width - 16) / 2
                height: apolloCardCol.implicitHeight + 28
                color: root.chosenDesktop === "apollo-desktop" ? Qt.alpha(root.accent, 0.12) : root.surface
                radius: 12
                border.color: root.chosenDesktop === "apollo-desktop" ? root.accent : Qt.alpha(root.border_, 0.6)
                border.width: root.chosenDesktop === "apollo-desktop" ? 2 : 1
                Behavior on color { ColorAnimation { duration: 200 } }
                Behavior on border.color { ColorAnimation { duration: 200 } }

                Column {
                    id: apolloCardCol
                    anchors { fill: parent; margins: 16 }
                    spacing: 10

                    Row {
                        spacing: 10
                        Text { text: "󰣆"; font.family: "FiraCode Nerd Font"; font.pixelSize: 28; color: root.accent }
                        Column {
                            Text { text: "Apollo Desktop"; font { family: "FiraCode Nerd Font"; pixelSize: 14; bold: true }; color: root.text }
                            Text { text: "Openbox · X11"; font.family: "FiraCode Nerd Font"; font.pixelSize: 10; color: root.muted }
                        }
                    }

                    Column {
                        spacing: 4
                        width: parent.width
                        Repeater {
                            model: ["✓ Works on all GPUs", "✓ NVIDIA legacy support",
                                    "✓ Minimal RAM usage (~350MB)", "✓ Maximum compatibility"]
                            Text {
                                required property string modelData
                                text: modelData
                                font.family: "FiraCode Nerd Font"; font.pixelSize: 10; color: root.muted
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width; height: 28; radius: 6
                        color: root.chosenDesktop === "apollo-desktop" ? root.accent : root.overlay
                        Text {
                            anchors.centerIn: parent
                            text: root.chosenDesktop === "apollo-desktop" ? "✓ Selected" : "Select"
                            font { family: "FiraCode Nerd Font"; pixelSize: 11; bold: true }
                            color: root.chosenDesktop === "apollo-desktop" ? "white" : root.text
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (!root.desktopLocked || root.defaultDesktop === "apollo-desktop")
                                root.chosenDesktop = "apollo-desktop"
                        }
                    }
                }
            }

            // ── Hyprland Card ──────────────────────────────────────────────
            Rectangle {
                width: (parent.width - 16) / 2
                height: hyprCardCol.implicitHeight + 28
                color: root.chosenDesktop === "hyprland"
                    ? Qt.alpha(root.accent2, 0.12) : root.surface
                radius: 12
                opacity: root.desktopLocked && root.defaultDesktop !== "hyprland" ? 0.45 : 1.0
                border.color: root.chosenDesktop === "hyprland" ? root.accent2 : Qt.alpha(root.border_, 0.6)
                border.width: root.chosenDesktop === "hyprland" ? 2 : 1
                Behavior on color { ColorAnimation { duration: 200 } }

                Column {
                    id: hyprCardCol
                    anchors { fill: parent; margins: 16 }
                    spacing: 10

                    Row {
                        spacing: 10
                        Text { text: "󰟀"; font.family: "FiraCode Nerd Font"; font.pixelSize: 28; color: root.accent2 }
                        Column {
                            Text { text: "Hyprland"; font { family: "FiraCode Nerd Font"; pixelSize: 14; bold: true }; color: root.text }
                            Text { text: "Wayland · Modern"; font.family: "FiraCode Nerd Font"; font.pixelSize: 10; color: root.muted }
                        }
                    }

                    Column {
                        spacing: 4
                        width: parent.width
                        Repeater {
                            model: ["✓ Smooth animations & blur", "✓ Native Wayland apps",
                                    "✓ Touchpad gestures", "⚠ Requires AMD/Intel/modern NVIDIA"]
                            Text {
                                required property string modelData
                                text: modelData
                                font.family: "FiraCode Nerd Font"; font.pixelSize: 10
                                color: modelData.startsWith("⚠") ? root.yellow : root.muted
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width; height: 28; radius: 6
                        color: root.desktopLocked && root.defaultDesktop !== "hyprland"
                            ? root.overlay
                            : root.chosenDesktop === "hyprland" ? root.accent2 : root.overlay
                        Text {
                            anchors.centerIn: parent
                            text: root.desktopLocked && root.defaultDesktop !== "hyprland"
                                ? "Not compatible" : root.chosenDesktop === "hyprland" ? "✓ Selected" : "Select"
                            font { family: "FiraCode Nerd Font"; pixelSize: 11; bold: true }
                            color: root.chosenDesktop === "hyprland" ? "white" : root.text
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: root.desktopLocked && root.defaultDesktop !== "hyprland"
                                ? Qt.ForbiddenCursor : Qt.PointingHandCursor
                            onClicked: {
                                if (!root.desktopLocked || root.defaultDesktop === "hyprland")
                                    root.chosenDesktop = "hyprland"
                            }
                        }
                    }
                }
            }
        }

        // Lock reason warning
        Rectangle {
            Layout.fillWidth: true
            height: lockText.implicitHeight + 18
            color: Qt.alpha(root.yellow, 0.1)
            radius: 8
            border.color: Qt.alpha(root.yellow, 0.3)
            border.width: 1
            visible: root.desktopLocked

            Text {
                id: lockText
                anchors { fill: parent; margins: 10 }
                text: "󰀦  " + root.lockReason
                font.family: "FiraCode Nerd Font"; font.pixelSize: 10
                color: root.yellow
                wrapMode: Text.WordWrap
            }
        }

        Item { Layout.fillHeight: true }
    }
}
