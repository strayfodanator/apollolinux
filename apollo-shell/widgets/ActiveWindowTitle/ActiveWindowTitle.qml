// Apollo Shell — Active Window Title Widget
// apollo-shell/widgets/ActiveWindowTitle/ActiveWindowTitle.qml
//
// Shows the title of the currently focused window in the top bar.

import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root

    property int    maxLength: 60
    property bool   showIcon: true
    property int    iconSize: 16
    property string color: "#E8EAF0"
    property string mutedColor: "#8890A4"
    property string fontFamily: "FiraCode Nerd Font"
    property int    fontSize: 10
    property var    theme: ({})

    property string windowTitle: ""
    property string windowClass: ""

    implicitWidth: row.implicitWidth + 8
    implicitHeight: parent ? parent.height : 28

    Timer {
        interval: 400; running: true; repeat: true
        onTriggered: titleProc.running = true
    }

    Process {
        id: titleProc
        command: ["bash", "-c",
            "xdotool getactivewindow getwindowname 2>/dev/null || echo 'Apollo Desktop'; " +
            "echo '---CLASS---'; " +
            "xdotool getactivewindow getwindowclassname 2>/dev/null || echo ''"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("---CLASS---")
                root.windowTitle = (lines[0] || "").trim().substring(0, root.maxLength)
                root.windowClass = (lines[1] || "").trim()
            }
        }
    }

    Row {
        id: row
        anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: 4 }
        spacing: 6

        // App icon placeholder (initial letter)
        Rectangle {
            width: root.iconSize; height: root.iconSize; radius: 3
            color: Qt.alpha(root.theme.accent ?? "#6C8EFF", 0.25)
            visible: root.showIcon && root.windowTitle !== ""
            anchors.verticalCenter: parent.verticalCenter

            Text {
                anchors.centerIn: parent
                text: root.windowTitle.charAt(0).toUpperCase()
                font.family: root.fontFamily
                font.pixelSize: root.iconSize * 0.55
                font.bold: true
                color: root.theme.accent ?? "#6C8EFF"
            }
        }

        Text {
            text: root.windowTitle || "Apollo Desktop"
            font.family: root.fontFamily
            font.pixelSize: root.fontSize
            color: root.windowTitle ? root.color : root.mutedColor
            elide: Text.ElideRight
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
