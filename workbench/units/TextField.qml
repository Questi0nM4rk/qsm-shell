pragma ComponentBehavior: Bound

import QtQuick

import qs.QsmShell.Components
import qs.QsmShell.Style

Item {
    id: root

    property string variant: ""
    property var eventRecorder: null
    property string purpose: variant.startsWith("search-") ? "search"
        : variant.startsWith("password-") ? "password"
        : variant.startsWith("number-") ? "number" : "text"
    property string text: purpose === "search" ? "volume"
        : purpose === "password" ? "hunter2" : purpose === "number" ? "42" : "Ada Lovelace"
    property bool failed: false
    property bool readOnly: false
    property string size: "md"
    property int acceptedCount: 0
    property int escapedCount: 0
    // Slot content is the host's: its glyph follows the field's box, and an
    // action's own box is one preset below the field's so its glyph is the same.
    readonly property int slotGlyph: Style.glyphBeside(field.fieldHeight)
    readonly property string actionSize: ({ xs: "xs", sm: "xs", md: "sm", lg: "md" })[root.size] ?? "sm"

    implicitWidth: Style.controlWidth
    implicitHeight: Style.size("Control", "lg")

    TextField {
        id: field
        anchors.centerIn: parent
        text: root.text
        inputType: root.purpose === "password" ? "password"
            : root.purpose === "number" ? "number" : "text"
        failed: root.failed
        readOnly: root.readOnly
        size: root.size
        placeholder: root.purpose === "search" ? "Search" : "Value"

        leading: Loader {
            active: root.purpose === "search"
            sourceComponent: Component { SvgIcon { name: "search"; size: root.slotGlyph } }
        }
        trailing: Loader {
            active: root.purpose === "password" || root.purpose === "number"
            sourceComponent: root.purpose === "password" ? revealAction : unitSuffix
        }

        onAccepted: {
            root.acceptedCount++
            root.eventRecorder?.("intent", "accepted", { text: field.text })
        }
        onEdited: text => {
            root.text = text
            root.eventRecorder?.("intent", "edited", { text })
        }
        onEscaped: {
            root.escapedCount++
            root.eventRecorder?.("intent", "escaped", {})
        }
        onSelectionClaimed: root.eventRecorder?.("intent", "selection-claimed", {})
        onKeyPressed: event => {
            root.eventRecorder?.("intent", "key-pressed", { key: event.key })
            if (event.key === Qt.Key_Up || event.key === Qt.Key_Down)
                event.accepted = true
        }
    }

    Component {
        id: revealAction
        IconButton {
            size: root.actionSize
            icon: field.passwordVisible ? "eye" : "eye-off"
            accessibleName: "Reveal password"
            onClicked: field.toggleReveal()
        }
    }

    Component {
        id: unitSuffix
        Prose {
            role: "metadata"
            text: "%"
        }
    }

    readonly property var controls: [
        { label: "purpose", options: [
            { label: "text", set: { purpose: "text", text: "Ada Lovelace" } },
            { label: "search", set: { purpose: "search", text: "volume" } },
            { label: "password", set: { purpose: "password", text: "hunter2" } },
            { label: "number", set: { purpose: "number", text: "42" } }
        ] },
        { label: "state", options: [
            { label: "enabled", set: { enabled: true } },
            { label: "disabled", set: { enabled: false } }
        ] },
        { label: "validity", options: [
            { label: "valid", set: { failed: false } },
            { label: "failed", set: { failed: true } }
        ] },
        { label: "mode", options: [
            { label: "editable", set: { readOnly: false } },
            { label: "read-only", set: { readOnly: true } }
        ] },
        { label: "size", options: [
            { label: "sm", set: { size: "sm" } },
            { label: "md", set: { size: "md" } },
            { label: "lg", set: { size: "lg" } }
        ] }
    ]

    readonly property var integration: ({
        events: ["accepted", "edited", "escaped", "selection-claimed", "key-pressed"],
        actions: ["accept", "clear", "reveal", "select-all"],
        keys: {
            "Enter": () => { field.accept(); return true }
        },
        textDriver: text => {
            field.text = String(text);
            return true;
        },
        observables: {
            text: () => field.text,
            "input-type": () => field.inputType,
            purpose: () => root.purpose,
            "leading-glyph": () => root.purpose === "search" ? "search" : "",
            "trailing-action": () => root.purpose === "password" ? "reveal"
                : root.purpose === "number" ? "unit" : "",
            revealed: () => field.passwordVisible,
            "acceptable-input": () => field.acceptableInput,
            "read-only": () => field.readOnly,
            failed: () => field.failed,
            size: () => field.size,
            accepted: () => root.acceptedCount,
            escaped: () => root.escapedCount,
            "can-accept": () => field.actions[0].enabled,
            "can-clear": () => field.actions[1].enabled
        },
        runAction: name => {
            if (name === "accept")
                field.accept();
            else if (name === "clear")
                field.clear();
            else if (name === "reveal")
                field.toggleReveal();
            else if (name === "select-all")
                field.selectAll();
            else
                return false;
            return true;
        }
    })
}
