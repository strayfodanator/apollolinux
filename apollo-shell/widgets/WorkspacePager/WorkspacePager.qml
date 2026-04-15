// Apollo Shell — Workspace Pager Widget
// apollo-shell/widgets/WorkspacePager/WorkspacePager.qml
//
// Shows virtual desktops as dots, numbers, or named buttons.
// Integrates with Openbox via _NET_* EWMH properties.

import Quickshell
import Quickshell.Services.Hyprland   // also works for EWMH on X11
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    property string style: "dots"        // "dots" | "numbers" | "names"
    property int    dotSize: 8
    property int    maxWorkspaces: 9
    property string activeColor: "#6C8EFF"
    property string inactiveColor: "#8890A4"
    property string occupiedColor: "#E8EAF0"
    property string hoverColor: "#A78BFA"
    property int    spacing: 6
    property var    theme: ({})

    // Desktop info via EWMH (works on X11 with Openbox)
    property int currentDesktop: 0
    property int totalDesktops: 9
    property var occupiedDesktops: []

    implicitWidth: pagerRow.implicitWidth + 8
    implicitHeight: parent ? parent.height : 28

    // Read EWMH via xprop polling (X11 fallback)
    Timer {
        interval: 300; running: true; repeat: true
        onTriggered: {
            ewmhProc.running = true
        }
    }

    Process {
        id: ewmhProc
        command: ["bash", "-c",
            "echo CURRENT:$(xprop -root _NET_CURRENT_DESKTOP | awk '{print $3}'); " +
            "echo TOTAL:$(xprop -root _NET_NUMBER_OF_DESKTOPS | awk '{print $3}')"]
        running: false
        stdout: SplitParser {
            onRead: (line) => {
                if (line.startsWith("CURRENT:")) {
                    root.currentDesktop = parseInt(line.split(":")[1]) || 0
                } else if (line.startsWith("TOTAL:")) {
                    root.totalDesktops = Math.min(parseInt(line.split(":")[1]) || 9, root.maxWorkspaces)
                }
            }
        }
    }

    Row {
        id: pagerRow
        anchors.centerIn: parent
        spacing: root.spacing

        Repeater {
            model: root.totalDesktops
            delegate: Item {
                property bool isActive: index === root.currentDesktop
                property bool isOccupied: root.occupiedDesktops.indexOf(index) !== -1

                width:  root.style === "dots" ? dotRect.width : wsLabel.implicitWidth + 12
                height: parent ? parent.height : 28

                // Dot style
                Rectangle {
                    id: dotRect
                    visible: root.style === "dots"
                    width:  isActive ? root.dotSize * 1.8 : root.dotSize
                    height: root.dotSize
                    radius: root.dotSize / 2
                    anchors.centerIn: parent
                    color: isActive ? root.activeColor : isOccupied ? root.occupiedColor : root.inactiveColor
                    opacity: isActive ? 1.0 : 0.7
                    Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                // Number / Name style
                Rectangle {
                    visible: root.style !== "dots"
                    anchors { fill: parent; topMargin: 4; bottomMargin: 4 }
                    color: isActive ? Qt.alpha(root.activeColor, 0.2) : wsHover.containsMouse ? Qt.alpha(root.hoverColor, 0.1) : "transparent"
                    radius: 4
                    border.color: isActive ? root.activeColor : "transparent"
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 120 } }

                    Text {
                        id: wsLabel
                        anchors.centerIn: parent
                        text: root.style === "numbers" ? (index + 1) : ["Home","Browser","Code","Files","Media","Chat","Games","Work","Other"][index] ?? (index+1)
                        font.family: theme.font ?? "FiraCode Nerd Font"
                        font.pixelSize: (theme.fontSize ?? 11) - 1
                        color: isActive ? root.activeColor : root.inactiveColor
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }
                }

                MouseArea {
                    id: wsHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        // Switch desktop via wmctrl (X11/Openbox)
                        switchProc.command = ["wmctrl", "-s", index.toString()]
                        switchProc.running = true
                    }
                    onWheel: (wheel) => {
                        const dir = wheel.angleDelta.y > 0 ? -1 : 1
                        const target = Math.max(0, Math.min(root.totalDesktops - 1, root.currentDesktop + dir))
                        switchProc.command = ["wmctrl", "-s", target.toString()]
                        switchProc.running = true
                    }
                }
            }
        }
    }

    Process {
        id: switchProc
        running: false
    }
}
