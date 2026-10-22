import QtQuick
import QtQuick.Layouts

import qs.QsmShell.Components
import qs.QsmShell.Style

FocusScope {
    id: root

    property string variant: ""
    property var eventRecorder: null
    property bool selected: true
    property bool disabled: false
    property bool interactive: true
    property bool header: false
    property bool separator: false
    property string size: variant === "lg-selected" ? "lg" : "md"
    property bool recede: true
    property int activations: 0
    property int hoverEnters: 0
    property int secondaryActivations: 0
    property bool longContent: false

    activeFocusOnTab: true
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
            if (!event.isAutoRepeat) {
                root.activateRow()
            }
            event.accepted = true
        }
    }

    readonly property bool device: variant === "reading-selected"

    implicitWidth: Style.controlWidth
    implicitHeight: Style.size("Control", "lg")

    property Component readingComponent: Component {
        Prose { role: "reading"; text: "87%" }
    }

    ListRow {
        id: row
        focused: root.activeFocus

        width: root.width
        size: root.size
        selected: root.selected
        disabled: root.disabled
        interactive: root.interactive
        header: root.header
        separator: root.separator
        recede: root.recede
        icon: root.variant === "lg-selected" ? "search" : root.device ? "monitor" : "wifi"
        primary: root.longContent
            ? "A deliberately long row title that remains contained and elides without changing the row size"
            : root.variant === "lg-selected" ? "Screenshot 2026-09-30"
            : root.device ? "DP-1 · 2560×1440 @ 60 Hz" : "Living room lamp"
        supporting: root.longContent
            ? "A long supporting description demonstrating contained text beside the trailing secondary action"
            : root.variant === "lg-selected" ? "~/Pictures"
            : root.device ? "" : "Quiet Luminous · 62%"

        onActivated: {
            root.activations++
            root.forceActiveFocus()
            root.eventRecorder?.("intent", "activated", {})
        }
        onHoveredEntered: {
            root.hoverEnters++
            root.eventRecorder?.("intent", "hovered-entered", {})
        }

        ControlLabel {
            id: secondary
            text: root.longContent ? "Open details" : "Details"
            icon: "chevron-right"
            clickable: true
            onClicked: {
                root.secondaryActivations++
                root.eventRecorder?.("intent", "secondary-activated", {})
            }
        }

        Loader {
            visible: root.device
            sourceComponent: root.device ? root.readingComponent : null
        }
    }

    readonly property var controls: [
        { label: "selection", options: [
            { label: "selected", set: { selected: true } },
            { label: "unselected", set: { selected: false } }
        ] },
        { label: "state", options: [
            { label: "enabled", set: { disabled: false } },
            { label: "disabled", set: { disabled: true } }
        ] },
        { label: "target", options: [
            { label: "interactive", set: { interactive: true } },
            { label: "report-only", set: { interactive: false } }
        ] },
        { label: "structure", options: [
            { label: "row", set: { header: false, separator: false } },
            { label: "header", set: { header: true, separator: false } },
            { label: "separator", set: { header: false, separator: true } }
        ] },
        { label: "size", options: [
            { label: "sm", set: { size: "sm" } },
            { label: "md", set: { size: "md" } },
            { label: "lg", set: { size: "lg" } }
        ] },
        { label: "recede", options: [
            { label: "on", set: { recede: true } },
            { label: "off", set: { recede: false } }
        ] },
        { label: "content", options: [
            { label: "normal", set: { longContent: false } },
            { label: "long", set: { longContent: true } }
        ] }
    ]

    readonly property var actionHandlers: ({
        activate: () => root.activateRow(),
        "secondary-activate": () => {
            if (!row.selectable)
                return false
            return secondary.activate()
        }
    })

    readonly property var integration: ({
        events: ["activated", "hovered-entered", "secondary-activated"],
        actions: Object.keys(root.actionHandlers),
        targets: ({
            row: () => row,
            browse: () => root
        }),
        observables: {
            selectable: () => row.selectable,
            selected: () => row.selected,
            size: () => row.size,
            hovered: () => row.hovered,
            pressed: () => row.pressed,
            focused: () => row.focused,
            activations: () => root.activations,
            "hover-enters": () => root.hoverEnters,
            "secondary-activations": () => root.secondaryActivations
        },
        runAction: name => Object.prototype.hasOwnProperty.call(root.actionHandlers, name)
            ? root.actionHandlers[name]() : false,
        keys: {
            "Enter": () => { root.forceActiveFocus(); root.activateRow(); return true },
            "Return": () => { root.forceActiveFocus(); root.activateRow(); return true }
        }
    })

    function activateRow(): bool {
        if (!row.selectable)
            return false
        row.activate()
        return true
    }

}
