// Apollo Shell — Window List Widget (Task buttons)
// apollo-shell/widgets/WindowList/WindowList.qml
//
// Shows running windows as clickable task buttons in the taskbar.
// Uses EWMH _NET_CLIENT_LIST for X11 compatibility.

import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    property int    maxButtonWidth: 180
    property bool   showIcons: true
    property bool   showLabels: true
    property bool   groupSimilar: false
    property var    theme: ({})

    property string fontFamily: theme.font ?? "FiraCode Nerd Font"
    property int    fontSize: theme.fontSize ?? 10
    property string textColor: theme.text ?? "#E8EAF0"
    property string mutedColor: theme.textMuted ?? "#8890A4"
    property string accentColor: theme.accent ?? "#6C8EFF"
    property string surfaceColor: theme.surface ?? "#1a1d27"
    property string overlayColor: theme.overlay ?? "#252836"
    property string borderColor: theme.border ?? "#2e3248"
    property int    radius: theme.radius ?? 8

    // Window list from EWMH
    property var windows: []
    property int activeWindow: -1

    implicitWidth: parent ? parent.width : 400
    implicitHeight: parent ? parent.height : 44

    // Poll window list every 500ms via xdotool/wmctrl
    Timer {
        interval: 500; running: true; repeat: true
        onTriggered: windowPoller.running = true
    }

    Process {
        id: windowPoller
        // wmctrl -l gives: WindowID Desktop PID Hostname Title
        command: ["bash", "-c",
            "wmctrl -l 2>/dev/null | grep -v '^0x.*-1 ' || true; " +
            "echo '---ACTIVE---'; " +
            "xdotool getactivewindow 2>/dev/null || echo 0"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const output = text.trim()
                const parts = output.split("---ACTIVE---")
                const winLines = (parts[0] || "").trim().split('\n').filter(l => l.trim())
                const activeHex = (parts[1] || "0").trim()
                root.activeWindow = parseInt(activeHex, 16) || -1

                root.windows = winLines.map(line => {
                    const m = line.match(/^(0x[0-9a-f]+)\s+(\d+)\s+\S+\s+\S+\s+(.*)$/i)
                    if (!m) return null
                    return {
                        id: parseInt(m[1], 16),
                        idHex: m[1],
                        desktop: parseInt(m[2]),
                        title: m[3].substring(0, 60)
                    }
                }).filter(w => w !== null)
            }
        }
    }

    // Activate/raise window via wmctrl
    function activateWindow(idHex) {
        activateProc.command = ["wmctrl", "-ia", idHex]
        activateProc.running = true
    }
    Process { id: activateProc; running: false }

    // Close window
    function closeWindow(idHex) {
        closeProc.command = ["wmctrl", "-ic", idHex]
        closeProc.running = true
    }
    Process { id: closeProc; running: false }

    // ── Task buttons ──────────────────────────────────────────────
    Row {
        id: taskRow
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
        spacing: 3

        Repeater {
            model: root.windows
            delegate: Item {
                required property var modelData
                property bool isActive: modelData.id === root.activeWindow

                width: Math.min(root.maxButtonWidth,
                    Math.max(120, root.parent.width / Math.max(root.windows.length, 1) - 4))
                height: root.height

                Rectangle {
                    anchors { fill: parent; topMargin: 6; bottomMargin: 6 }
                    color: isActive
                        ? Qt.alpha(root.accentColor, 0.15)
                        : taskMouse.containsMouse
                          ? root.overlayColor
                          : "transparent"
                    radius: root.radius - 2
                    border.color: isActive ? Qt.alpha(root.accentColor, 0.4) : "transparent"
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 100 } }

                    // Active window indicator dot
                    Rectangle {
                        anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter; bottomMargin: -2 }
                        width: isActive ? 18 : 6; height: 3; radius: 2
                        color: root.accentColor
                        visible: isActive
                        Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                    }

                    RowLayout {
                        anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                        spacing: 5

                        // Window icon placeholder (would use _NET_WM_ICON in full impl)
                        Rectangle {
                            width: 16; height: 16; radius: 3
                            color: Qt.alpha(root.accentColor, 0.3)
                            visible: root.showIcons
                            Layout.alignment: Qt.AlignVCenter

                            Text {
                                anchors.centerIn: parent
                                text: modelData.title.charAt(0).toUpperCase()
                                font.family: root.fontFamily
                                font.pixelSize: 9
                                font.bold: true
                                color: root.accentColor
                            }
                        }

                        // Window title
                        Text {
                            text: modelData.title
                            font.family: root.fontFamily
                            font.pixelSize: root.fontSize
                            font.bold: isActive
                            color: isActive ? root.textColor : root.mutedColor
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            visible: root.showLabels
                            Behavior on color { ColorAnimation { duration: 100 } }
                        }
                    }
                }

                MouseArea {
                    id: taskMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor

                    onClicked: (mouse) => {
                        if (mouse.button === Qt.MiddleButton) {
                            root.closeWindow(modelData.idHex)
                        } else if (mouse.button === Qt.LeftButton) {
                            root.activateWindow(modelData.idHex)
                        } else {
                            taskContextMenu.popup()
                        }
                    }

                    ToolTip {
                        visible: parent.containsMouse && modelData.title.length > 30
                        delay: 600
                        text: modelData.title
                    }
                }

                Menu {
                    id: taskContextMenu
                    MenuItem { text: "Bring to Front"; onTriggered: root.activateWindow(modelData.idHex) }
                    MenuItem { text: "Close"; onTriggered: root.closeWindow(modelData.idHex) }
                }
            }
        }
    }
}
