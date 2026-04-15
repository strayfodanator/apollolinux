// Apollo Shell — Notes Plugin
// apollo-shell/plugins/notes/Notes.qml
//
// Quick notes widget. Markdown-light, auto-saved.
// Notes stored at ~/.local/share/apollo-notes/

import Quickshell.Io
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
    property string bgColor: theme.surface ?? "#1a1d27"
    property string overlayColor: theme.overlay ?? "#252836"
    property string borderColor: theme.border ?? "#2e3248"
    property int    radius: theme.radius ?? 10

    property string notesPath: StandardPaths.writableLocation(StandardPaths.HomeLocation)
                               + "/.local/share/apollo-notes/notes.md"

    implicitWidth: 260
    implicitHeight: 200

    property bool dirty: false

    // Auto-save every 5 seconds if dirty
    Timer {
        interval: 5000; running: true; repeat: true
        onTriggered: if (root.dirty) saveNote()
    }

    function saveNote() {
        Process {
            command: ["bash", "-c",
                `mkdir -p "$(dirname '${root.notesPath}')" && cat > '${root.notesPath}'`]
            stdin: noteArea.text + "\n"
            running: true
        }
        root.dirty = false
    }

    // Load on start
    FileView {
        id: notesFile
        path: root.notesPath
        onTextChanged: {
            if (noteArea.text === "" || !root.dirty) {
                noteArea.text = text
            }
        }
    }

    // ── UI ────────────────────────────────────────────────────────
    Column {
        anchors { fill: parent; margins: 8 }
        spacing: 6

        // Header
        RowLayout {
            width: parent.width
            Text {
                text: "󰒓 Notes"
                font.family: root.fontFamily; font.pixelSize: root.fontSize; font.bold: true
                color: root.accentColor
            }
            Item { Layout.fillWidth: true }
            Text {
                text: root.dirty ? "●" : "󰄬"
                font.family: root.fontFamily; font.pixelSize: root.fontSize
                color: root.dirty ? root.accentColor : root.mutedColor
                opacity: 0.8
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.saveNote()
                    visible: root.dirty
                }
                ToolTip { visible: parent.parent.containsMouse; delay: 400
                    text: root.dirty ? "Click to save" : "Saved" }
            }
        }

        // Text area
        ScrollView {
            width: parent.width
            height: parent.height - 30
            ScrollBar.vertical.policy: ScrollBar.AsNeeded
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            TextArea {
                id: noteArea
                width: parent.width
                wrapMode: TextEdit.Wrap
                font.family: root.fontFamily
                font.pixelSize: root.fontSize
                color: root.textColor
                selectionColor: Qt.alpha(root.accentColor, 0.35)
                selectedTextColor: root.textColor
                placeholderText: "Type your notes here...\nAuto-saved every 5 seconds."
                placeholderTextColor: root.mutedColor
                padding: 8
                background: Rectangle {
                    color: root.overlayColor
                    radius: root.radius - 2
                    border.color: noteArea.activeFocus ? root.accentColor : root.borderColor
                    border.width: 1
                    Behavior on border.color { ColorAnimation { duration: 150 } }
                }
                onTextChanged: root.dirty = true
            }
        }
    }
}
