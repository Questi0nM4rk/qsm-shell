import QtQuick
import QtQuick.Layouts

import qs.QsmShell.Components
import qs.QsmShell.Style

// One exclusive choice. The unit is the host: it owns which option is
// selected, answers every selectionRequested, and clears the others.
Item {
    id: root

    property string variant: ""
    property var eventRecorder: null
    property int selectedIndex: variant === "off" ? -1 : 0
    property string size: "md"
    property string labelLength: "short"
    property bool secondAvailable: true

    readonly property var labels: [
        labelLength === "long"
            ? "Match the window size, and keep matching it whenever the window is resized, tiled or moved to another monitor"
            : "Match window size",
        "Fit to width",
        "Original size"
    ]

    implicitWidth: group.implicitWidth
    implicitHeight: group.implicitHeight

    ColumnLayout {
        id: group
        anchors.centerIn: parent
        spacing: Style.space2

        Repeater {
            id: radios
            model: root.labels.length

            Radio {
                id: option
                required property int index
                Layout.preferredWidth: Style.controlWidth
                size: root.size
                checked: root.selectedIndex === option.index
                enabled: option.index !== 1 || root.secondAvailable
                onSelectionRequested: {
                    root.selectedIndex = option.index
                    root.eventRecorder?.("intent", "selection-requested", { index: option.index })
                }

                Prose {
                    role: "label"
                    font.pixelSize: option.labelSize
                    width: parent.width
                    elide: Text.ElideRight
                    text: root.labels[option.index]
                    color: option.enabled ? Style.text : Style.disabled(Style.text)
                }
            }
        }
    }

    function _radio(index: int): var {
        return radios.itemAt(index)
    }

    // The index of the first radio for which `test` holds, else -1.
    function _which(test: var): int {
        for (let i = 0; i < radios.count; i++) {
            if (test(radios.itemAt(i)))
                return i
        }
        return -1
    }

    readonly property var controls: [
        { label: "selected", options: [
            { label: "none", set: { selectedIndex: -1 } },
            { label: "first", set: { selectedIndex: 0 } },
            { label: "second", set: { selectedIndex: 1 } },
            { label: "third", set: { selectedIndex: 2 } }
        ] },
        { label: "size", options: [
            { label: "sm", set: { size: "sm" } },
            { label: "md", set: { size: "md" } },
            { label: "lg", set: { size: "lg" } }
        ] },
        { label: "label", options: [
            { label: "short", set: { labelLength: "short" } },
            { label: "long", set: { labelLength: "long" } }
        ] },
        { label: "second-option", options: [
            { label: "available", set: { secondAvailable: true } },
            { label: "unavailable", set: { secondAvailable: false } }
        ] },
        { label: "state", options: [
            { label: "enabled", set: { enabled: true } },
            { label: "disabled", set: { enabled: false } }
        ] }
    ]
    readonly property var integration: ({
        events: ["selection-requested"],
        actions: ["select-first", "select-second", "select-third"],
        targets: ({
            first: () => root._radio(0),
            second: () => root._radio(1),
            third: () => root._radio(2),
            scene: () => root
        }),
        observables: {
            selected: () => root.selectedIndex,
            hovered: () => root._which(r => r.hovered),
            pressed: () => root._which(r => r.pressed),
            "keyboard-focus": () => root._which(r => r.visualFocus),
            "target-height": () => root._radio(0).height,
            "accessible-checked": () => root._which(r => r.Accessible.checked)
        },
        runAction: name => {
            const index = ["select-first", "select-second", "select-third"].indexOf(name)
            if (index < 0)
                return false
            root._radio(index).select()
            return true
        }
    })
}
