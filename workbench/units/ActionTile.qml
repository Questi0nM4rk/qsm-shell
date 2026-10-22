import QtQuick
import QtQuick.Layouts

import qs.QsmShell.Components
import qs.QsmShell.Style

// The task: choose what happens to the session. The set plays the host a
// session surface plays: it owns which tile is selected (the pointer moves it),
// arms the destructive ones through the library's ArmedAction and runs the
// choice. The tiles only report.
Item {
    id: root

    property string variant: ""
    property var eventRecorder: null
    property string size: "md"
    property bool longLabels: false
    property int selectedIndex: -1
    property int firedCount: 0
    property string firedRole: ""

    readonly property var session: [
        { icon: "lock", label: "Lock", role: "lock", destructive: false },
        { icon: "moon", label: "Hibernate", role: "hibernate", destructive: false },
        { icon: "log-out", label: "Log out", confirmLabel: "Log out?", role: "logout", destructive: true },
        { icon: "rotate-cw", label: "Restart", confirmLabel: "Restart?", role: "reboot", destructive: true },
        { icon: "power", label: "Shut down", confirmLabel: "Shut down?", role: "shutdown", destructive: true }
    ]
    readonly property string _longWord: " and close everything"

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: Style.space2

        Repeater {
            id: tiles
            model: root.session

            ActionTile {
                id: tile
                required property var modelData
                required property int index

                readonly property ArmedAction arm: ArmedAction {
                    destructive: tile.modelData.destructive
                    onFired: {
                        root.firedCount++
                        root.firedRole = tile.modelData.role
                        root.eventRecorder?.("intent", "fired", { role: tile.modelData.role })
                    }
                }

                icon: modelData.icon
                label: root.longLabels ? modelData.label + root._longWord : modelData.label
                confirmLabel: modelData.confirmLabel ?? ""
                size: root.size
                growthCap: Motion.hoverGrowthWithin(row.spacing)
                danger: modelData.role === "shutdown"
                // The group that ends the session starts a full step after the
                // group that keeps it.
                Layout.leftMargin: index > 0 && modelData.destructive && !root.session[index - 1].destructive
                    ? Style.space4 - Style.space2 : 0
                selected: root.selectedIndex === index
                armed: arm.armed
                onSelectedChanged: if (!selected) arm.disarm()
                onEntered: root.selectedIndex = index
                onExited: arm.disarm()
                onActivated: {
                    root.selectedIndex = index
                    root.eventRecorder?.("intent", "activated", { role: modelData.role, armed: arm.armed })
                    arm.trigger()
                }
            }
        }
    }

    function _tile(index: int): var {
        return tiles.itemAt(index)
    }

    readonly property var controls: [
        { label: "size", options: [
            { label: "xs", set: { size: "xs" } },
            { label: "sm", set: { size: "sm" } },
            { label: "md", set: { size: "md" } },
            { label: "lg", set: { size: "lg" } }
        ] },
        { label: "labels", options: [
            { label: "short", set: { longLabels: false } },
            { label: "long", set: { longLabels: true } }
        ] },
        { label: "selection", options: [
            { label: "none", set: { selectedIndex: -1 } },
            { label: "first", set: { selectedIndex: 0 } },
            { label: "last", set: { selectedIndex: 4 } }
        ] },
        { label: "state", options: [
            { label: "enabled", set: { enabled: true } },
            { label: "disabled", set: { enabled: false } }
        ] }
    ]
    readonly property var integration: ({
        events: ["activated", "fired"],
        actions: ["activate"],
        targets: ({
            lock: () => root._tile(0),
            logout: () => root._tile(2),
            shutdown: () => root._tile(4)
        }),
        observables: {
            enabled: () => root.enabled,
            size: () => root.size,
            "selected-index": () => root.selectedIndex,
            "armed-role": () => {
                for (let i = 0; i < root.session.length; i++)
                    if (root._tile(i)?.armed)
                        return root.session[i].role
                return ""
            },
            "fired-role": () => root.firedRole,
            "fired-count": () => root.firedCount,
            "shutdown-label": () => root._tile(4)?.shownLabel ?? "",
            "tile-width": () => root._tile(0)?.width ?? 0,
            "tile-height": () => root._tile(0)?.height ?? 0,
            "lock-name": () => root._tile(0)?.Accessible.name ?? "",
            "shutdown-selected": () => root._tile(4)?.Accessible.selected ?? false
        },
        runAction: name => {
            if (name !== "activate")
                return false
            root._tile(4).activate()
            return true
        }
    })
}
