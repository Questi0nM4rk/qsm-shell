pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.QsmShell.Components
import qs.QsmShell.Style

// A select-all parent over three children. The unit is the host: it owns every
// `checked`, derives the parent's mixed state from the children and decides
// that clicking a mixed parent selects everything.
Item {
    id: root

    property string variant: ""
    property var eventRecorder: null
    property var picked: variant === "on" ? [true, true, true]
        : variant === "off" ? [false, false, false] : [true, true, false]
    property string size: "md"
    property string labelLength: "short"

    readonly property var labels: [
        labelLength === "long"
            ? "Documents, including every file whose name starts with a dot and everything inside folders that are themselves hidden from the listing"
            : "Documents",
        "Photos",
        "Music"
    ]
    readonly property var names: ["documents", "photos", "music"]
    readonly property int count: root.picked.filter(on => on).length

    implicitWidth: group.implicitWidth
    implicitHeight: group.implicitHeight

    function _set(index: int, on: bool): void {
        const next = root.picked.slice()
        next[index] = on
        root.picked = next
    }

    function _box(index: int): var {
        return items.itemAt(index)
    }

    // The name of the first box (the parent is "all") for which `test` holds, else "".
    function _which(test: var): string {
        if (test(all))
            return "all"
        for (let i = 0; i < items.count; i++) {
            if (test(items.itemAt(i)))
                return root.names[i]
        }
        return ""
    }

    ColumnLayout {
        id: group
        anchors.centerIn: parent
        spacing: Style.space2

        Checkbox {
            id: all
            Layout.preferredWidth: Style.controlWidth
            size: root.size
            checked: root.count === root.picked.length
            indeterminate: root.count > 0 && root.count < root.picked.length
            accessibleName: "Back up everything"
            // A mixed parent reports checked false, so its next state is all.
            onToggleRequested: next => {
                root.picked = root.picked.map(() => next)
                root.eventRecorder?.("intent", "toggle-requested", { item: "all", checked: next })
            }

            Prose {
                role: "label"
                font.pixelSize: all.labelSize
                width: parent.width
                elide: Text.ElideRight
                text: "Back up everything"
                color: all.enabled ? Style.text : Style.disabled(Style.text)
            }
        }

        ColumnLayout {
            Layout.leftMargin: Style.space5
            spacing: Style.space2

            Repeater {
                id: items
                model: root.labels.length

                Checkbox {
                    id: child
                    required property int index
                    Layout.preferredWidth: Style.controlWidth - Style.space5
                    size: root.size
                    checked: root.picked[child.index]
                    accessibleName: root.labels[child.index]
                    onToggleRequested: next => {
                        root._set(child.index, next)
                        root.eventRecorder?.("intent", "toggle-requested", { item: root.names[child.index], checked: next })
                    }

                    Prose {
                        role: "label"
                        font.pixelSize: child.labelSize
                        width: parent.width
                        elide: Text.ElideRight
                        text: root.labels[child.index]
                        color: child.enabled ? Style.text : Style.disabled(Style.text)
                    }
                }
            }
        }
    }

    readonly property var controls: [
        { label: "selection", options: [
            { label: "none", set: { picked: [false, false, false] } },
            { label: "some", set: { picked: [true, true, false] } },
            { label: "all", set: { picked: [true, true, true] } }
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
        { label: "state", options: [
            { label: "enabled", set: { enabled: true } },
            { label: "disabled", set: { enabled: false } }
        ] }
    ]
    readonly property var integration: ({
        events: ["toggle-requested"],
        actions: ["toggle-all", "toggle-first"],
        targets: ({
            all: () => all,
            documents: () => root._box(0),
            photos: () => root._box(1),
            scene: () => root
        }),
        observables: {
            "selected-count": () => root.count,
            "all-checked": () => all.checked,
            "all-mixed": () => all.indeterminate,
            "accessible-mixed": () => all.Accessible.checkStateMixed,
            "accessible-checked": () => all.Accessible.checked,
            hovered: () => root._which(box => box.hovered),
            pressed: () => root._which(box => box.pressed) !== "",
            "keyboard-focus": () => root._which(box => box.visualFocus),
            "target-height": () => all.height
        },
        runAction: name => {
            if (name === "toggle-all")
                all.flip()
            else if (name === "toggle-first")
                root._box(0).flip()
            else
                return false
            return true
        }
    })
}
