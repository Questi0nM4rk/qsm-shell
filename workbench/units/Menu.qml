pragma ComponentBehavior: Bound

import QtQuick

import qs.QsmShell.Components
import qs.QsmShell.Style

Item {
    id: root

    property string variant: ""
    property var eventRecorder: null
    property bool modelled: false
    property int currentIndex: 1
    property int activatedIndex: -1
    property int activations: 0
    property string modelSelection: ""

    readonly property var modelRows: ["Bold", "Italic", "Underline"]

    implicitWidth: Style.controlWidth
    implicitHeight: Style.controlWidth / 2

    Menu {
        id: menu

        anchors.fill: parent
        model: root.modelled ? root.modelRows : null
        delegate: rowDelegate
        currentIndex: root.currentIndex

        onActivated: index => {
            root.activatedIndex = index
            root.activations++
            root.eventRecorder?.("intent", "activated", { index })
        }

        ListRow {
            id: headerRow
            header: true
            interactive: false
            primary: "Clipboard"
        }

        ListRow {
            id: cutRow
            icon: "copy"
            primary: "Cut"
            onActivated: root.eventRecorder?.("intent", "row-activated", { id: "cut" })
        }

        ListRow {
            id: archiveRow
            icon: "download"
            primary: "Archive"
            disabled: true
        }

        ListRow {
            id: quitRow
            icon: "power"
            primary: "Quit"
            danger: true
            onActivated: root.eventRecorder?.("intent", "row-activated", { id: "quit" })
        }

    }

    Component {
        id: rowDelegate

        ListRow {
            required property string modelData
            primary: modelData
            onSelectedChanged: root.modelSelection = selected ? modelData : ""
        }
    }

    readonly property var controls: [
        { label: "rows", options: [
            { label: "static", set: { modelled: false } },
            { label: "modelled", set: { modelled: true } }
        ] },
        { label: "selection", options: [
            { label: "cut", set: { currentIndex: 1 } },
            { label: "quit", set: { currentIndex: 3 } },
            { label: "none", set: { currentIndex: -1 } }
        ] }
    ]

    readonly property var integration: ({
        events: ["activated", "row-activated"],
        actions: ["step-next", "step-previous", "activate-current"],
        observables: {
            "current-index": () => menu.currentIndex,
            "selected-cut": () => cutRow.selected,
            "selected-quit": () => quitRow.selected,
            "model-selected": () => root.modelSelection,
            "activated-index": () => root.activatedIndex,
            activations: () => root.activations
        },
        runAction: name => {
            if (name === "step-next") { menu.step(1); return true }
            if (name === "step-previous") { menu.step(-1); return true }
            if (name === "activate-current") { menu.activateCurrent(); return true }
            return false
        },
        keys: {
            "Enter": () => { menu.activateCurrent(); return true }
        }
    })
}
