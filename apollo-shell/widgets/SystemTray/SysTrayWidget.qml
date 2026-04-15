// Apollo Shell — System Tray Widget
// apollo-shell/widgets/SystemTray/SysTrayWidget.qml
//
// Renders system tray icons using Quickshell.Services.SystemTray.
// Compatible with StatusNotifierItem (SNI) standard.

import Quickshell.Services.SystemTray
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property int iconSize: 18
    property int spacing: 6
    property var theme: ({})

    implicitWidth: trayRow.implicitWidth + 4
    implicitHeight: parent ? parent.height : 44

    Row {
        id: trayRow
        anchors.centerIn: parent
        spacing: root.spacing

        Repeater {
            model: SystemTray.items
            delegate: Item {
                id: trayItem
                required property SystemTrayItem item

                width: root.iconSize + 4
                height: root.iconSize + 4

                Image {
                    anchors.centerIn: parent
                    source: trayItem.item.icon
                    width: root.iconSize
                    height: root.iconSize
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor

                    onClicked: (mouse) => {
                        if (mouse.button === Qt.LeftButton)
                            trayItem.item.activate(mouse.x, mouse.y)
                        else
                            trayItem.item.contextMenu(mouse.x, mouse.y)
                    }

                    onWheel: (wheel) => trayItem.item.scroll(0, wheel.angleDelta.y)

                    ToolTip {
                        visible: parent.containsMouse && trayItem.item.tooltip !== ""
                        delay: 600
                        text: trayItem.item.tooltip
                    }
                }
            }
        }
    }
}
