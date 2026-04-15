// Apollo Shell — Battery Indicator Widget
// apollo-shell/widgets/BatteryIndicator/BatteryWidget.qml
//
// Shows battery percentage + charging status via UPower.
// Turns red when critical, yellow when low.

import Quickshell.Services.UPower
import QtQuick
import QtQuick.Controls

Item {
    id: root

    property var theme: ({})
    property string fontFamily: theme.font ?? "FiraCode Nerd Font"
    property int    fontSize: theme.fontSize ?? 11
    property string textColor: theme.text ?? "#E8EAF0"
    property string mutedColor: theme.textMuted ?? "#8890A4"
    property string accentColor: theme.accent ?? "#6C8EFF"
    property string warningColor: theme.warning ?? "#FBBF24"
    property string errorColor:   theme.error ?? "#F87171"
    property string successColor: theme.success ?? "#4ADE80"

    property int criticalThreshold: 10
    property int lowThreshold: 20

    // Exposed so parent can hide if no battery
    property bool hasBattery: UPower.displayDevice?.isPresent ?? false

    implicitWidth: row.implicitWidth + 10
    implicitHeight: parent ? parent.height : 36

    property var bat: UPower.displayDevice

    property int    pct:      bat ? Math.round(bat.percentage) : 0
    property bool   charging: bat ? (bat.state === UPower.BatteryState.Charging || bat.state === UPower.BatteryState.FullyCharged) : false
    property bool   full:     bat ? bat.state === UPower.BatteryState.FullyCharged : false

    function batIcon(): string {
        if (charging) return "󰂄"
        if (full)     return "󰁹"
        if (pct >= 90) return "󰂀"
        if (pct >= 70) return "󰁾"
        if (pct >= 50) return "󰁼"
        if (pct >= 30) return "󰁺"
        if (pct >= 10) return "󰁹"
        return "󰂃"  // critical
    }

    function batColor(): string {
        if (charging || full) return root.successColor
        if (pct <= root.criticalThreshold) return root.errorColor
        if (pct <= root.lowThreshold) return root.warningColor
        return root.accentColor
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 4

        Text {
            text: root.batIcon()
            font.family: root.fontFamily
            font.pixelSize: root.fontSize + 2
            color: root.batColor()
            verticalAlignment: Text.AlignVCenter
            Behavior on color { ColorAnimation { duration: 300 } }
        }

        Text {
            text: root.pct + "%"
            font.family: root.fontFamily
            font.pixelSize: root.fontSize - 1
            color: root.batColor()
            verticalAlignment: Text.AlignVCenter
            Behavior on color { ColorAnimation { duration: 300 } }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        ToolTip {
            visible: parent.containsMouse
            delay: 400
            text: {
                let s = root.pct + "% — "
                if (root.full) return s + "Full"
                if (root.charging) {
                    const mins = root.bat?.timeToFull ?? 0
                    return s + "Charging" + (mins > 0 ? " (" + Math.round(mins/60) + "h remaining)" : "")
                }
                const mins = root.bat?.timeToEmpty ?? 0
                return s + "Discharging" + (mins > 0 ? " (" + Math.round(mins/60) + "h remaining)" : "")
            }
        }
    }

    // Low battery notification
    Timer {
        interval: 60000; running: true; repeat: true
        onTriggered: {
            if (!root.charging && root.pct <= root.criticalThreshold)
                Quickshell.exec(["notify-send", "-u", "critical", "-i", "battery-caution",
                                 "Battery Critical", root.pct + "% remaining. Please plug in your charger."])
        }
    }
}
