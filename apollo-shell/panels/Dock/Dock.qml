// Apollo Shell — Dock Panel
// apollo-shell/panels/Dock/Dock.qml
//
// Optional macOS-style dock. Disabled by default.
// Enable via apollo-shell.json: "dock": { "enabled": true }
// Supports: pinned apps, running window indicators, auto-hide.

import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

PanelWindow {
    id: dock

    property var pCfg: ShellRoot.cfg.panels?.dock ?? {}
    property var theme: ShellRoot.cfg.theme ?? {}
    property var pinnedApps: pCfg.apps ?? []

    property string fontFamily: theme.font ?? "FiraCode Nerd Font"
    property int    iconSize: pCfg.iconSize ?? 48
    property int    dockHeight: iconSize + 24
    property int    gapFromEdge: pCfg.offset ?? 8
    property bool   autoHide: pCfg.autohide ?? true
    property bool   isHidden: autoHide

    // Expose toggle for IPC
    function toggle() { isHidden = !isHidden }

    anchors {
        bottom: true
        left:   false
        right:  false
    }
    height: isHidden ? 4 : dockHeight + gapFromEdge
    implicitWidth: dockRow.implicitWidth + 24

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.exclusiveZone: isHidden ? 0 : dockHeight + gapFromEdge
    WlrLayershell.anchors: WlrAnchors.Bottom

    color: "transparent"

    Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    Behavior on WlrLayershell.exclusiveZone { NumberAnimation { duration: 220 } }

    // Auto-hide trigger via mouse proximity
    HoverHandler {
        id: dockHover
        target: dock
        onHoveredChanged: {
            if (dock.autoHide) dock.isHidden = !hovered
        }
    }

    // ── Dock background ─────────────────────────────────────────
    Rectangle {
        id: dockBg
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: dock.gapFromEdge
        }
        width: dockRow.implicitWidth + 24
        height: dock.dockHeight
        color: theme.surface ?? "#1a1d27"
        opacity: pCfg.opacity ?? 0.90
        radius: (theme.radius ?? 10) + 4
        border.color: theme.border ?? "#2e3248"
        border.width: 1
        visible: !dock.isHidden

        // Subtle shadow illusion via inner glow
        layer.enabled: true

        Row {
            id: dockRow
            anchors.centerIn: parent
            spacing: 8
            padding: 4

            Repeater {
                model: dock.pinnedApps
                delegate: DockItem {
                    required property var modelData
                    appName: modelData.name ?? ""
                    appExec: modelData.exec ?? ""
                    appIcon: modelData.icon ?? ""
                    iconSize: dock.iconSize
                    theme: dock.theme
                }
            }
        }
    }
}

// ── DockItem component ────────────────────────────────────────────────────────
component DockItem : Item {
    property string appName: ""
    property string appExec: ""
    property string appIcon: ""
    property int    iconSize: 48
    property var    theme: ({})

    property string accentColor: theme.accent ?? "#6C8EFF"
    property string fontFamily: theme.font ?? "FiraCode Nerd Font"

    property bool hovered: false
    property bool running: false  // TODO: check via wmctrl

    width: iconSize + 8
    height: iconSize + 16

    Column {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 2

        // Icon with bounce animation on hover
        Item {
            width: iconSize + 8
            height: iconSize + 8
            anchors.horizontalCenter: parent.horizontalCenter

            Rectangle {
                anchors.centerIn: parent
                width: iconSize + (dockItemHover.containsMouse ? 8 : 0)
                height: width
                radius: width * 0.22
                color: Qt.alpha(parent.parent.parent.accentColor, 0.2)
                visible: !iconImg.visible
                Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }

                Text {
                    anchors.centerIn: parent
                    text: appName.charAt(0)
                    font.family: fontFamily
                    font.pixelSize: parent.width * 0.45
                    font.bold: true
                    color: accentColor
                }
            }

            Image {
                id: iconImg
                source: appIcon.startsWith("/") ? ("file://" + appIcon) :
                        ("image://xdg-icon/" + appIcon)
                width:  iconSize + (dockItemHover.containsMouse ? 8 : 0)
                height: width
                anchors.centerIn: parent
                visible: status === Image.Ready
                smooth: true
                fillMode: Image.PreserveAspectFit
                Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
            }

            // Y offset / bounce
            transform: Translate {
                y: dockItemHover.containsMouse ? -6 : 0
                Behavior on y { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
            }
        }

        // Running indicator dot
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 4; height: 4; radius: 2
            color: accentColor
            opacity: running ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }
    }

    // Tooltip
    ToolTip {
        visible: dockItemHover.containsMouse && appName !== ""
        delay: 300
        text: appName
    }

    MouseArea {
        id: dockItemHover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            Process {
                command: appExec.split(" ")
                running: true
            }
        }
    }
}
