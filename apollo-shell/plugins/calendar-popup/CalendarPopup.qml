// Apollo Shell — Calendar Popup Plugin
// apollo-shell/plugins/calendar-popup/CalendarPopup.qml
//
// Compact monthly calendar showing current date.
// Integrates with the clock widget on click.

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Basic

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

    property bool startOnMonday: true

    implicitWidth: 240
    implicitHeight: calCol.implicitHeight + 20

    // ── Date state ────────────────────────────────────────────────
    property var today: new Date()
    property int viewYear:  today.getFullYear()
    property int viewMonth: today.getMonth()   // 0-based

    property string monthName: Qt.locale().monthName(viewMonth, Locale.LongFormat)
    property var    monthDays: daysInMonth(viewYear, viewMonth)

    function daysInMonth(y, m) {
        return new Date(y, m + 1, 0).getDate()
    }
    function firstDayOfMonth(y, m) {
        let d = new Date(y, m, 1).getDay()  // 0=Sun
        if (startOnMonday) d = (d + 6) % 7 // convert to Mon-based
        return d
    }
    function prevMonth() {
        if (viewMonth === 0) { viewMonth = 11; viewYear-- }
        else viewMonth--
    }
    function nextMonth() {
        if (viewMonth === 11) { viewMonth = 0; viewYear++ }
        else viewMonth++
    }
    function isToday(day) {
        return day === today.getDate()
            && viewMonth === today.getMonth()
            && viewYear  === today.getFullYear()
    }

    Column {
        id: calCol
        anchors.centerIn: parent
        spacing: 8
        width: parent.width - 20

        // ── Header row (← Month Year →) ──────────────────────────
        RowLayout {
            width: parent.width

            Rectangle {
                width: 24; height: 24; radius: 12
                color: prevHov.containsMouse ? Qt.alpha(root.accentColor, 0.2) : "transparent"
                Text {
                    anchors.centerIn: parent
                    text: ""; font.family: root.fontFamily
                    font.pixelSize: root.fontSize; color: root.mutedColor
                }
                MouseArea { id: prevHov; anchors.fill: parent; hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor; onClicked: root.prevMonth() }
            }

            Text {
                text: root.monthName + "  " + root.viewYear
                font.family: root.fontFamily; font.pixelSize: root.fontSize
                font.bold: true; color: root.textColor
                Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter
            }

            Rectangle {
                width: 24; height: 24; radius: 12
                color: nextHov.containsMouse ? Qt.alpha(root.accentColor, 0.2) : "transparent"
                Text {
                    anchors.centerIn: parent
                    text: ""; font.family: root.fontFamily
                    font.pixelSize: root.fontSize; color: root.mutedColor
                }
                MouseArea { id: nextHov; anchors.fill: parent; hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor; onClicked: root.nextMonth() }
            }
        }

        // ── Day-of-week headers ───────────────────────────────────
        Row {
            width: parent.width
            spacing: 0
            Repeater {
                model: root.startOnMonday
                    ? ["Mo","Tu","We","Th","Fr","Sa","Su"]
                    : ["Su","Mo","Tu","We","Th","Fr","Sa"]
                delegate: Text {
                    required property string modelData
                    width: parent.width / 7
                    text: modelData
                    font.family: root.fontFamily; font.pixelSize: root.fontSize - 2
                    color: (modelData === "Sa" || modelData === "Su") ? root.accentColor : root.mutedColor
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        // Thin separator
        Rectangle { width: parent.width; height: 1; color: root.borderColor; opacity: 0.6 }

        // ── Calendar grid ─────────────────────────────────────────
        Grid {
            id: calGrid
            width: parent.width
            columns: 7
            spacing: 0

            property int firstDay: root.firstDayOfMonth(root.viewYear, root.viewMonth)
            property int totalDays: root.daysInMonth(root.viewYear, root.viewMonth)

            // Leading empty cells
            Repeater {
                model: calGrid.firstDay
                delegate: Item { width: calGrid.width / 7; height: 28 }
            }

            // Day cells
            Repeater {
                model: calGrid.totalDays
                delegate: Item {
                    required property int index
                    property int day: index + 1
                    property bool today_: root.isToday(day)
                    property bool weekend: {
                        let col = (calGrid.firstDay + index) % 7
                        return root.startOnMonday ? col >= 5 : (col === 0 || col === 6)
                    }

                    width: calGrid.width / 7
                    height: 28

                    Rectangle {
                        anchors.centerIn: parent
                        width: 26; height: 26; radius: 13
                        color: today_ ? root.accentColor
                             : dayHov.containsMouse ? Qt.alpha(root.accentColor, 0.15)
                             : "transparent"
                        Behavior on color { ColorAnimation { duration: 80 } }

                        Text {
                            anchors.centerIn: parent
                            text: day.toString()
                            font.family: root.fontFamily
                            font.pixelSize: root.fontSize - 1
                            font.bold: today_
                            color: today_ ? "white"
                                 : weekend ? root.accentColor
                                 : root.textColor
                        }

                        MouseArea {
                            id: dayHov; anchors.fill: parent
                            hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        }
                    }
                }
            }
        }

        // ── Today button ─────────────────────────────────────────
        Rectangle {
            width: 70; height: 22; radius: 11
            color: Qt.alpha(root.accentColor, 0.15)
            border.color: Qt.alpha(root.accentColor, 0.4)
            border.width: 1
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.viewMonth !== root.today.getMonth()
                  || root.viewYear  !== root.today.getFullYear()

            Text {
                anchors.centerIn: parent
                text: "Today"
                font.family: root.fontFamily; font.pixelSize: root.fontSize - 2
                color: root.accentColor
            }
            MouseArea {
                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.today = new Date()
                    root.viewMonth = root.today.getMonth()
                    root.viewYear  = root.today.getFullYear()
                }
            }
        }
    }
}
