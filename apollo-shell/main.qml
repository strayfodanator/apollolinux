// Apollo Shell — Main Entry Point
// apollo-shell/main.qml
//
// QuickShell root. Loads config from apollo-shell.json and
// instantiates all enabled panels.

pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Controls

ShellRoot {
    id: root

    // ── Config loader ─────────────────────────────────────────────
    property var cfg: ({})

    FileView {
        id: configFile
        // configFile path injected via -override flag at launch
        path: Qt.resolvedUrl(
            typeof configFilePath !== "undefined"
                ? configFilePath
                : (StandardPaths.writableLocation(StandardPaths.HomeLocation)
                   + "/.config/apollo-shell/apollo-shell.json")
        )
        onTextChanged: {
            try {
                root.cfg = JSON.parse(configFile.text)
                console.log("[Apollo Shell] Config loaded:", Object.keys(root.cfg))
            } catch(e) {
                console.error("[Apollo Shell] Config parse error:", e)
                root.cfg = {}
            }
        }
    }

    // ── Panels: instantiated after config is loaded ────────────────
    Loader {
        id: taskbarLoader
        active: root.cfg.panels?.taskbar?.enabled ?? true
        source: "./panels/Taskbar/Taskbar.qml"
        onStatusChanged: {
            if (status === Loader.Error)
                console.error("[Apollo Shell] Taskbar load error:", sourceComponent)
        }
    }

    Loader {
        id: topbarLoader
        active: root.cfg.panels?.topbar?.enabled ?? true
        source: "./panels/TopBar/TopBar.qml"
    }

    Loader {
        id: dockLoader
        active: root.cfg.panels?.dock?.enabled ?? false
        source: "./panels/Dock/Dock.qml"
    }

    Loader {
        id: sidebarLoader
        active: root.cfg.panels?.sidebar?.enabled ?? false
        source: "./panels/Sidebar/Sidebar.qml"
    }

    // ── IPC: allow external commands (apollo-shell-action toggle-*) ─
    IpcHandler {
        target: "apollo-shell"
        function execute(message) {
            const parts = message.split(" ")
            const action = parts[0]
            const arg = parts[1] || ""
            console.log("[Apollo Shell] IPC:", action, arg)
            switch(action) {
                case "toggle-sidebar":
                    sidebarLoader.item?.toggle()
                    break
                case "toggle-app-menu":
                    taskbarLoader.item?.toggleAppMenu()
                    break
                case "reload":
                    configFile.reload()
                    break
                case "toggle-dock":
                    dockLoader.active = !dockLoader.active
                    break
            }
        }
    }
}
