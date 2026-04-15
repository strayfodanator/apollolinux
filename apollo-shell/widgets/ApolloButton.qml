// Apollo Shell — Reusable Button Component
// apollo-shell/widgets/ApolloButton.qml

import QtQuick
import QtQuick.Controls

Item {
    id: root

    property string icon: ""
    property string label: ""
    property string font: "FiraCode Nerd Font"
    property int    fontSize: 12
    property string accentColor: "#6C8EFF"
    property string bgColor: "#1a1d27"
    property string hoverColor: "#252836"
    property string textColor: "#E8EAF0"
    property int    radius: 8
    property var    theme: ({})

    signal clicked()
    signal rightClicked()

    implicitWidth: row.implicitWidth + 16
    implicitHeight: parent ? parent.height : 36

    Rectangle {
        id: bg
        anchors { fill: parent; margins: 4 }
        color: mouseArea.containsPress ? Qt.darker(hoverColor, 1.1)
             : mouseArea.containsMouse ? hoverColor
             : "transparent"
        radius: root.radius

        Behavior on color { ColorAnimation { duration: 100 } }

        Row {
            id: row
            anchors.centerIn: parent
            spacing: 5

            // Nerd Font glyph icon
            Text {
                text: root.icon
                font.family: root.font
                font.pixelSize: root.fontSize + 2
                color: mouseArea.containsMouse ? root.accentColor : root.textColor
                visible: root.icon !== ""
                verticalAlignment: Text.AlignVCenter
                Behavior on color { ColorAnimation { duration: 100 } }
            }

            Text {
                text: root.label
                font.family: root.font
                font.pixelSize: root.fontSize
                color: mouseArea.containsMouse ? root.accentColor : root.textColor
                visible: root.label !== ""
                verticalAlignment: Text.AlignVCenter
                Behavior on color { ColorAnimation { duration: 100 } }
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) root.rightClicked()
            else root.clicked()
        }
        cursorShape: Qt.PointingHandCursor
    }
}
