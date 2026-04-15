// Apollo Shell — App Menu Popup
// apollo-shell/widgets/AppMenu/AppMenuPopup.qml
//
// Full-screen app launcher grid shown when the "Apps" button is clicked.
// Reads applications from XDG .desktop files via Process.
// Shows: categories sidebar + app grid with search.

import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
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
    property int    rad: theme.radius ?? 10

    width: 680
    height: 460
    color: root.bgColor
    radius: root.rad + 4
    border.color: root.borderColor
    border.width: 1

    // ── App data ──────────────────────────────────────────────────
    property var allApps: []
    property var filteredApps: []
    property string searchQuery: ""
    property string activeCategory: "All"

    // Load .desktop files on open
    Component.onCompleted: loadApps()

    function loadApps() {
        appLoader.running = true
    }

    Process {
        id: appLoader
        // List apps from XDG dirs with their categories
        command: ["bash", "-c", `
            find /usr/share/applications ~/.local/share/applications -name "*.desktop" 2>/dev/null |
            while read f; do
                name=$(grep -m1 '^Name=' "$f" | cut -d= -f2-)
                exec=$(grep -m1 '^Exec=' "$f" | cut -d= -f2- | sed 's/ %[uUfFdDnNickvm]//g')
                icon=$(grep -m1 '^Icon=' "$f" | cut -d= -f2-)
                cat=$(grep -m1 '^Categories=' "$f" | cut -d= -f2-)
                nodisplay=$(grep -m1 '^NoDisplay=' "$f" | cut -d= -f2-)
                [[ "$nodisplay" == "true" ]] && continue
                [[ -z "$name" || -z "$exec" ]] && continue
                echo "$name|$exec|$icon|$cat"
            done | sort -u
        `]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split('\n').filter(l => l.trim())
                root.allApps = lines.map(line => {
                    const p = line.split('|')
                    return {
                        name:     p[0] ?? "",
                        exec:     p[1] ?? "",
                        icon:     p[2] ?? "",
                        category: (p[3] ?? "").split(';')[0] || "Other"
                    }
                })
                root.filterApps()
            }
        }
    }

    function filterApps() {
        const q = root.searchQuery.toLowerCase()
        filteredApps = root.allApps.filter(app => {
            const matchSearch = !q || app.name.toLowerCase().includes(q)
            const matchCat = root.activeCategory === "All" ||
                             app.category.includes(root.activeCategory)
            return matchSearch && matchCat
        })
    }

    onSearchQueryChanged: filterApps()
    onActiveCategoryChanged: filterApps()

    // ── Categories ────────────────────────────────────────────────
    readonly property var categories: [
        { name: "All",        icon: "󰀻" },
        { name: "AudioVideo", icon: "" },
        { name: "Development",icon: "󰨞" },
        { name: "Game",       icon: "󰊗" },
        { name: "Graphics",   icon: "󰏘" },
        { name: "Network",    icon: "" },
        { name: "Office",     icon: "󰏢" },
        { name: "System",     icon: "󱙌" },
        { name: "Utility",    icon: "󰒓" },
    ]

    // ── Layout ────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        // ── Search bar ────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 40
            color: root.overlayColor
            radius: 20
            border.color: searchField.activeFocus ? root.accentColor : root.borderColor
            border.width: 1
            Behavior on border.color { ColorAnimation { duration: 150 } }

            RowLayout {
                anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
                spacing: 8

                Text {
                    text: "󰍉"
                    font.family: root.fontFamily
                    font.pixelSize: root.fontSize + 2
                    color: root.mutedColor
                }
                TextField {
                    id: searchField
                    Layout.fillWidth: true
                    placeholderText: "Search applications..."
                    placeholderTextColor: root.mutedColor
                    color: root.textColor
                    font.family: root.fontFamily
                    font.pixelSize: root.fontSize
                    background: Item {}
                    onTextChanged: root.searchQuery = text
                    Keys.onEscapePressed: root.visible = false
                }
                Text {
                    text: "󰅙"
                    font.family: root.fontFamily
                    font.pixelSize: root.fontSize + 2
                    color: root.mutedColor
                    visible: searchField.text !== ""
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: searchField.clear()
                    }
                }
            }
        }

        // ── Body: categories + app grid ───────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10

            // Category sidebar (slim)
            Column {
                spacing: 2
                Layout.preferredWidth: 110
                Layout.fillHeight: true

                Repeater {
                    model: root.categories
                    delegate: Rectangle {
                        required property var modelData
                        property bool active: root.activeCategory === modelData.name
                        width: 108; height: 32
                        radius: 7
                        color: active ? Qt.alpha(root.accentColor, 0.2)
                             : catHov.containsMouse ? root.overlayColor
                             : "transparent"
                        Behavior on color { ColorAnimation { duration: 80 } }

                        RowLayout {
                            anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                            spacing: 6
                            Text {
                                text: modelData.icon
                                font.family: root.fontFamily; font.pixelSize: root.fontSize
                                color: active ? root.accentColor : root.mutedColor
                            }
                            Text {
                                text: modelData.name === "AudioVideo" ? "Media" : modelData.name
                                font.family: root.fontFamily; font.pixelSize: root.fontSize - 1
                                color: active ? root.accentColor : root.textColor
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                        }
                        MouseArea {
                            id: catHov; anchors.fill: parent
                            hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: root.activeCategory = modelData.name
                        }
                    }
                }
            }

            // Vertical divider
            Rectangle {
                width: 1; Layout.fillHeight: true
                color: root.borderColor; opacity: 0.5
            }

            // App grid
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                clip: true

                GridLayout {
                    width: parent.width
                    columns: Math.floor(parent.width / 116)
                    rowSpacing: 4
                    columnSpacing: 4

                    Repeater {
                        model: root.filteredApps
                        delegate: Rectangle {
                            required property var modelData
                            width: 112; height: 88
                            radius: root.rad
                            color: appHov.containsMouse ? root.overlayColor : "transparent"
                            Behavior on color { ColorAnimation { duration: 80 } }

                            Column {
                                anchors.centerIn: parent
                                spacing: 6

                                // Icon
                                Rectangle {
                                    width: 40; height: 40; radius: 10
                                    color: Qt.alpha(root.accentColor, 0.2)
                                    anchors.horizontalCenter: parent.horizontalCenter

                                    Image {
                                        id: appIcon
                                        anchors.fill: parent
                                        anchors.margins: 4
                                        source: modelData.icon.startsWith("/") ? ("file://" + modelData.icon) :
                                                (`image://xdg-icon/${modelData.icon}`)
                                        fillMode: Image.PreserveAspectFit
                                        smooth: true
                                        visible: status === Image.Ready
                                    }
                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.name.charAt(0).toUpperCase()
                                        font.family: root.fontFamily
                                        font.pixelSize: 18; font.bold: true
                                        color: root.accentColor
                                        visible: !appIcon.visible
                                    }
                                }

                                Text {
                                    text: modelData.name
                                    font.family: root.fontFamily
                                    font.pixelSize: root.fontSize - 1
                                    color: root.textColor
                                    horizontalAlignment: Text.AlignHCenter
                                    width: 108
                                    elide: Text.ElideRight
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                            }

                            MouseArea {
                                id: appHov; anchors.fill: parent
                                hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Process {
                                        command: modelData.exec.split(" ")
                                        running: true
                                    }
                                    root.visible = false
                                }
                                ToolTip { visible: parent.containsMouse; delay: 600
                                    text: modelData.name }
                            }
                        }
                    }
                }
            }
        }
    }

    // Close on click outside
    Keys.onEscapePressed: root.visible = false

    // Focus search when shown
    onVisibleChanged: if (visible) searchField.forceActiveFocus()
}
