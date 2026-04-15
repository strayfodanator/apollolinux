// Apollo Shell — CPU Graph Plugin
// apollo-shell/plugins/cpu-graph/CpuGraph.qml
//
// Real-time CPU usage graph + per-core bars.
// Reads from /proc/stat. Zero external dependencies.

import Quickshell.Io
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    property var theme: ({})
    property string fontFamily: theme.font ?? "FiraCode Nerd Font"
    property int    fontSize: theme.fontSize ?? 10
    property string accentColor: theme.accent ?? "#6C8EFF"
    property string accentAlt: theme.accent2 ?? "#A78BFA"
    property string textColor: theme.text ?? "#E8EAF0"
    property string mutedColor: theme.textMuted ?? "#8890A4"
    property string bgColor: theme.surface ?? "#1a1d27"
    property int    radius: theme.radius ?? 10

    property int historyLength: 60
    property int updateInterval: 1000

    implicitWidth: 260
    implicitHeight: 120

    // ── CPU reading ───────────────────────────────────────────────
    property var cpuHistory: []
    property real currentCpu: 0
    property var coreUsages: []
    property var _prevStats: []
    property int coreCount: 0

    function parseStat(text) {
        const lines = text.split('\n').filter(l => l.startsWith('cpu'))
        const result = []
        lines.forEach(line => {
            const p = line.split(/\s+/).filter(x => x !== '')
            const vals = p.slice(1).map(Number)
            const total = vals.reduce((a, b) => a + b, 0)
            const idle = vals[3] + (vals[4] ?? 0)
            result.push({ total, idle, name: p[0] })
        })
        return result
    }

    function computeUsage(prev, curr) {
        const dtotal = curr.total - prev.total
        const didle  = curr.idle  - prev.idle
        if (dtotal === 0) return 0
        return Math.max(0, Math.min(100, ((dtotal - didle) / dtotal) * 100))
    }

    Timer {
        interval: root.updateInterval; running: true; repeat: true
        onTriggered: statFile.reload()
    }

    FileView {
        id: statFile
        path: "/proc/stat"
        onTextChanged: {
            const stats = root.parseStat(text)
            if (root._prevStats.length === stats.length) {
                root.currentCpu = root.computeUsage(root._prevStats[0], stats[0])
                const cores = []
                for (let i = 1; i < stats.length; i++) {
                    cores.push(root.computeUsage(root._prevStats[i], stats[i]))
                }
                root.coreUsages = cores
                root.coreCount = cores.length
                root.cpuHistory = [...root.cpuHistory.slice(-(root.historyLength - 1)), root.currentCpu]
            }
            root._prevStats = stats
        }
    }

    // ── UI ────────────────────────────────────────────────────────
    Column {
        anchors { fill: parent; margins: 10 }
        spacing: 8

        // Header
        RowLayout {
            width: parent.width
            Text {
                text: "󰻠 CPU"
                font.family: root.fontFamily; font.pixelSize: root.fontSize; font.bold: true
                color: root.accentColor
            }
            Item { Layout.fillWidth: true }
            Text {
                text: Math.round(root.currentCpu) + "%"
                font.family: root.fontFamily; font.pixelSize: root.fontSize
                color: root.currentCpu > 80 ? "#F87171" : root.currentCpu > 50 ? "#FBBF24" : root.textColor
            }
        }

        // History graph
        Canvas {
            id: graph
            width: parent.width; height: 50
            onPaint: {
                const ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)

                // Background
                ctx.fillStyle = "#0f1117"
                ctx.roundRect(0, 0, width, height, 6)
                ctx.fill()

                // Grid lines
                ctx.strokeStyle = "#252836"
                ctx.lineWidth = 0.5
                for (let i = 0; i <= 4; i++) {
                    const y = height - (i / 4) * height
                    ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(width, y); ctx.stroke()
                }

                // CPU usage graph
                if (root.cpuHistory.length < 2) return
                ctx.beginPath()
                const step = width / (root.historyLength - 1)
                root.cpuHistory.forEach((val, i) => {
                    const x = i * step
                    const y = height - (val / 100) * height
                    i === 0 ? ctx.moveTo(x, y) : ctx.lineTo(x, y)
                })

                // Gradient fill
                const grad = ctx.createLinearGradient(0, 0, 0, height)
                grad.addColorStop(0, "rgba(108,142,255,0.4)")
                grad.addColorStop(1, "rgba(108,142,255,0.02)")
                ctx.strokeStyle = "#6C8EFF"
                ctx.lineWidth = 1.5
                ctx.stroke()
                ctx.lineTo(width, height); ctx.lineTo(0, height); ctx.closePath()
                ctx.fillStyle = grad; ctx.fill()
            }

            Connections {
                target: root
                function onCpuHistoryChanged() { graph.requestPaint() }
            }
        }

        // Per-core bars (up to 8)
        Row {
            width: parent.width
            spacing: 3

            Repeater {
                model: Math.min(root.coreCount, 8)
                delegate: Column {
                    required property int index
                    property real usage: root.coreUsages[index] ?? 0
                    width: (parent.width - 3 * (Math.min(root.coreCount, 8) - 1)) / Math.min(root.coreCount, 8)
                    spacing: 2

                    Rectangle {
                        width: parent.width; height: 8; radius: 2; color: "#252836"
                        Rectangle {
                            width: parent.width * (usage / 100); height: parent.height; radius: 2
                            color: usage > 80 ? "#F87171" : usage > 50 ? "#FBBF24" : root.accentColor
                            Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutQuad } }
                            Behavior on color { ColorAnimation { duration: 300 } }
                        }
                    }
                    Text {
                        text: "C" + index; font.family: root.fontFamily; font.pixelSize: 7
                        color: root.mutedColor; anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }
        }
    }
}
