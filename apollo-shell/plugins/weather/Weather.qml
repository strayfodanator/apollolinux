// Apollo Shell — Weather Plugin
// apollo-shell/plugins/weather/Weather.qml
//
// Shows current weather for detected or configured location.
// Uses Open-Meteo API (free, no API key required).

import Quickshell
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

    implicitWidth: col.implicitWidth + 16
    implicitHeight: col.implicitHeight + 16

    // ── State ────────────────────────────────────────────────────
    property string weatherIcon: "󰖙"
    property string temperature: "--°C"
    property string condition: "Loading..."
    property string humidity: "--%"
    property string windSpeed: "--"
    property string location: "Detecting..."

    property bool loading: true
    property bool error: false

    // ── WMO weather code → Nerd Font icon mapping ─────────────────
    function wmoIcon(code) {
        if (code === 0) return "󰖙"          // Clear sky
        if (code <= 2) return "󰖕"          // Partly cloudy
        if (code === 3) return "󰖐"         // Overcast
        if (code <= 49) return "󰖑"         // Fog/Mist
        if (code <= 55) return "󰖦"         // Drizzle
        if (code <= 65) return "󰖖"         // Rain
        if (code <= 75) return "󰖘"         // Snow
        if (code <= 77) return "󰖘"         // Snow grains
        if (code <= 82) return "󰖖"         // Rain showers
        if (code <= 86) return "󰖘"         // Snow showers
        if (code <= 99) return "󰖓"         // Thunderstorm
        return "󰖙"
    }

    function wmoCondition(code) {
        if (code === 0) return "Clear"
        if (code <= 2) return "Partly Cloudy"
        if (code === 3) return "Overcast"
        if (code <= 49) return "Foggy"
        if (code <= 55) return "Drizzle"
        if (code <= 65) return "Rain"
        if (code <= 75) return "Snow"
        if (code <= 82) return "Showers"
        if (code <= 86) return "Snow Showers"
        if (code <= 99) return "Thunderstorm"
        return "Unknown"
    }

    // ── Location detection via ipinfo.io → then Open-Meteo ────────
    Timer {
        interval: 1800000  // Update every 30 minutes
        running: true; repeat: true
        onTriggered: fetchWeather()
    }
    Component.onCompleted: fetchWeather()

    function fetchWeather() {
        root.loading = true
        geoProc.running = true
    }

    // Step 1: Get lat/lon from IP
    Process {
        id: geoProc
        command: ["curl", "-sf", "--max-time", "5",
                  "https://ipinfo.io/json"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text)
                    const loc = data.loc.split(",")
                    root.location = data.city ?? "Unknown"
                    weatherProc.command = [
                        "curl", "-sf", "--max-time", "8",
                        `https://api.open-meteo.com/v1/forecast?latitude=${loc[0]}&longitude=${loc[1]}&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m&wind_speed_unit=kmh&temperature_unit=celsius`
                    ]
                    weatherProc.running = true
                } catch(e) {
                    root.error = true
                    root.loading = false
                    root.condition = "Location error"
                }
            }
        }
    }

    // Step 2: Fetch weather data
    Process {
        id: weatherProc
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text)
                    const curr = data.current
                    root.temperature = Math.round(curr.temperature_2m) + "°C"
                    root.humidity = curr.relative_humidity_2m + "%"
                    root.windSpeed = Math.round(curr.wind_speed_10m) + " km/h"
                    root.weatherIcon = root.wmoIcon(curr.weather_code)
                    root.condition = root.wmoCondition(curr.weather_code)
                    root.loading = false
                    root.error = false
                } catch(e) {
                    root.error = true
                    root.loading = false
                    root.condition = "Weather unavailable"
                }
            }
        }
    }

    // ── UI ────────────────────────────────────────────────────────
    Column {
        id: col
        anchors.centerIn: parent
        spacing: 8

        // Main weather display
        Row {
            spacing: 12
            anchors.horizontalCenter: parent.horizontalCenter

            Text {
                text: root.loading ? "󰔟" : root.weatherIcon
                font.family: root.fontFamily
                font.pixelSize: root.fontSize + 20
                color: root.error ? root.mutedColor : root.accentColor
                verticalAlignment: Text.AlignVCenter
            }

            Column {
                spacing: 2
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    text: root.temperature
                    font.family: root.fontFamily
                    font.pixelSize: root.fontSize + 12
                    font.bold: true
                    color: root.textColor
                }

                Text {
                    text: root.condition
                    font.family: root.fontFamily
                    font.pixelSize: root.fontSize - 1
                    color: root.mutedColor
                }

                Text {
                    text: root.location
                    font.family: root.fontFamily
                    font.pixelSize: root.fontSize - 2
                    color: root.mutedColor
                    opacity: 0.7
                }
            }
        }

        // Details row
        Row {
            spacing: 16
            anchors.horizontalCenter: parent.horizontalCenter
            visible: !root.loading && !root.error

            Row {
                spacing: 4
                Text { text: "󰖝"; font.family: root.fontFamily; font.pixelSize: root.fontSize; color: root.mutedColor }
                Text { text: root.humidity; font.family: root.fontFamily; font.pixelSize: root.fontSize - 1; color: root.mutedColor }
            }
            Row {
                spacing: 4
                Text { text: ""; font.family: root.fontFamily; font.pixelSize: root.fontSize; color: root.mutedColor }
                Text { text: root.windSpeed; font.family: root.fontFamily; font.pixelSize: root.fontSize - 1; color: root.mutedColor }
            }
        }
    }
}
