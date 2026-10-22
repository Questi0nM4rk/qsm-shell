import QtQuick
import QtQuick.Layouts

import qs.QsmShell.Components
import qs.QsmShell.Style

// One exclusive choice of a real shell task: what closing the lid does. The
// unit is the host: it owns which option is chosen and answers `selected`.
Item {
    id: root

    property string variant: ""
    property var eventRecorder: null
    property int selectedIndex: variant === "none" ? -1 : 0
    property string size: "md"
    property bool hibernateAvailable: false
    property bool wrapNavigation: true

    implicitWidth: group.implicitWidth
    implicitHeight: group.implicitHeight

    RadioGroup {
        id: group
        anchors.centerIn: parent
        label: "When the lid closes"
        currentIndex: root.selectedIndex
        wrapNavigation: root.wrapNavigation
        onSelected: index => {
            root.selectedIndex = index
            root.eventRecorder?.("intent", "selected", { index })
        }

        Repeater {
            id: radios
            model: [
                { text: "Suspend", available: true },
                { text: "Hibernate, no swap space is set up", available: root.hibernateAvailable },
                { text: "Lock the screen", available: true },
                { text: "Keep running, so every download, call and sync carries on while the lid is closed and the laptop sits in a bag", available: true }
            ]

            Radio {
                id: option
                required property int index
                required property var modelData
                Layout.preferredWidth: Style.controlWidth
                size: root.size
                enabled: option.modelData.available

                Prose {
                    role: "label"
                    font.pixelSize: option.labelSize
                    width: parent.width
                    elide: Text.ElideRight
                    text: option.modelData.text
                    color: option.enabled ? Style.text : Style.disabled(Style.text)
                }
            }
        }
    }

    readonly property var controls: [
        { label: "selected", options: [
            { label: "none", set: { selectedIndex: -1 } },
            { label: "first", set: { selectedIndex: 0 } },
            { label: "third", set: { selectedIndex: 2 } },
            { label: "last", set: { selectedIndex: 3 } }
        ] },
        { label: "hibernate", options: [
            { label: "unavailable", set: { hibernateAvailable: false } },
            { label: "available", set: { hibernateAvailable: true } }
        ] },
        { label: "navigation", options: [
            { label: "wrapping", set: { wrapNavigation: true } },
            { label: "stopping", set: { wrapNavigation: false } }
        ] },
        { label: "size", options: [
            { label: "sm", set: { size: "sm" } },
            { label: "md", set: { size: "md" } },
            { label: "lg", set: { size: "lg" } }
        ] },
        { label: "state", options: [
            { label: "enabled", set: { enabled: true } },
            { label: "disabled", set: { enabled: false } }
        ] }
    ]

    function _radio(index: int): var {
        return radios.itemAt(index)
    }

    function _which(test: var): int {
        for (let i = 0; i < radios.count; i++) {
            if (test(radios.itemAt(i)))
                return i
        }
        return -1
    }

    readonly property var integration: ({
        events: ["selected"],
        actions: ["previous", "next", "first", "last"],
        targets: ({
            group: () => group,
            suspend: () => root._radio(0),
            hibernate: () => root._radio(1),
            lock: () => root._radio(2),
            keep: () => root._radio(3),
            scene: () => root
        }),
        observables: {
            selected: () => root.selectedIndex,
            "laid-out": () => root._radio(3) !== null && root._radio(3).y > 0,
            hovered: () => root._which(r => r.hovered),
            "keyboard-focus": () => root._which(r => r.visualFocus),
            "tab-stop": () => root._which(r => r.activeFocusOnTab),
            "accessible-checked": () => root._which(r => r.Accessible.checked),
            "group-name": () => group.Accessible.name,
            "group-description": () => group.Accessible.description
        },
        runAction: name => {
            if (name === "previous")
                return group.step(-1)
            if (name === "next")
                return group.step(1)
            if (name === "first")
                return group.first()
            if (name === "last")
                return group.last()
            return false
        }
    })
}
