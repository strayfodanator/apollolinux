// Apollo Shell — Clock Widget
// apollo-shell/widgets/Clock/ClockWidget.qml
//
// Displays time and optionally date. Supports hover to toggle date.
// Uses Qt.formatDateTime for locale-aware formatting.

import QtQuick
import QtQuick.Controls

Item {
    id: root

    property string format: "HH:mm"
    property string dateFormat: "ddd, DD MMM"
    property bool   showDate: false
    property bool   showDateOnHover: false
    property string style: "digital"   // "digital" | "minimal"
    property var    theme: ({})

    property string fontFamily: theme.font ?? "FiraCode Nerd Font"
    property int    fontSize: theme.fontSize ?? 11
    property string textColor: theme.text ?? "#E8EAF0"
    property string mutedColor: theme.textMuted ?? "#8890A4"
    property string accentColor: theme.accent ?? "#6C8EFF"

    implicitWidth: col.implicitWidth + 8
    implicitHeight: parent ? parent.height : 36

    // Update every second
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            timeText.text = Qt.formatDateTime(new Date(), root.format)
            dateText.text = Qt.formatDateTime(new Date(), root.dateFormat)
        }
    }

    Component.onCompleted: {
        timeText.text = Qt.formatDateTime(new Date(), root.format)
        dateText.text = Qt.formatDateTime(new Date(), root.dateFormat)
    }

    Column {
        id: col
        anchors.centerIn: parent
        spacing: 1

        Text {
            id: timeText
            font.family: root.fontFamily
            font.pixelSize: root.fontSize
            font.weight: Font.Medium
            color: root.textColor
            horizontalAlignment: Text.AlignHCenter
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            id: dateText
            font.family: root.fontFamily
            font.pixelSize: root.fontSize - 2
            color: root.mutedColor
            horizontalAlignment: Text.AlignHCenter
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.showDate || (root.showDateOnHover && hoverArea.containsMouse)
            opacity: visible ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: root.showDateOnHover
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            // Click to open calendar popup (if plugin enabled)
            if (typeof calendarPopup !== "undefined")
                calendarPopup.visible = !calendarPopup.visible
        }
    }

    ToolTip {
        visible: hoverArea.containsMouse && !dateText.visible
        text: Qt.formatDateTime(new Date(), root.dateFormat)
        delay: 600
    }
}
