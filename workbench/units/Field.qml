pragma ComponentBehavior: Bound

import QtQuick

import qs.QsmShell.Components
import qs.QsmShell.Style

Item {
    id: root

    property string variant: ""
    property var eventRecorder: null
    // The frame names any control: a text box (the default) or a switch.
    property string control: "text"
    property bool hintShown: true
    property string errorKind: variant === "error" ? "short" : ""
    property bool required: true
    property string size: "md"
    property string password: "hunter2"
    property bool toggled: true
    property int toggles: 0
    property int acceptedCount: 0

    // The words belong to what the frame names: a network password or a night
    // light setting.
    readonly property bool isText: root.control === "text"
    readonly property string hint: !root.hintShown ? ""
        : root.isText ? "Enter to connect, Escape to cancel." : "Follow the light around the room."
    readonly property string error: root.errorKind === "short"
        ? (root.isText ? "Wrong password. Check it and try again." : "Pick a profile the shell can read.")
        : root.errorKind === "long"
            ? "The network refused that password three times in a row. "
                + "Check the key printed on the router label, then wait a minute before you try again."
            : ""
    readonly property var controlItem: host.item
    // What a screen reader meets: the input of a text field, the switch itself.
    readonly property var accessibleItem: root.control === "text"
        ? Array.from(root.controlItem.contentItem.children).find(c => c.objectName === "textFieldInput") ?? null
        : root.controlItem

    implicitWidth: Style.controlWidth
    implicitHeight: Style.size("Control", "lg") + Style.space6 * 4

    function find(item, name: string): Item {
        for (const child of item.children) {
            if (child.objectName === name)
                return child;
            const found = root.find(child, name);
            if (found)
                return found;
        }
        return null;
    }

    Field {
        id: field

        width: Style.controlWidth
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: Style.space6 * 3
        label: root.control === "text" ? "Network password" : "Night light"
        hint: root.hint
        error: root.error
        required: root.required

        Loader {
            id: host
            width: root.control === "text" ? parent.width : implicitWidth
            sourceComponent: root.control === "text" ? textControl : switchControl
        }
    }

    Component {
        id: textControl
        TextField {
            size: root.size
            inputType: "password"
            placeholder: "Password"
            text: root.password
            failed: field.failed
            onEdited: text => root.password = text
            onAccepted: {
                root.acceptedCount++
                root.eventRecorder?.("intent", "accepted", { text: text })
            }
        }
    }

    Component {
        id: switchControl
        Switch {
            size: root.size
            checked: root.toggled
            onToggleRequested: checked => {
                root.toggled = checked
                root.toggles++
                root.eventRecorder?.("intent", "toggle-requested", { checked })
            }
        }
    }

    readonly property var controls: [
        { label: "control", options: [
            { label: "text", set: { control: "text" } },
            { label: "switch", set: { control: "switch" } }
        ] },
        { label: "validation", options: [
            { label: "ok", set: { errorKind: "" } },
            { label: "failed", set: { errorKind: "short" } },
            { label: "long", set: { errorKind: "long" } }
        ] },
        { label: "hint", options: [
            { label: "shown", set: { hintShown: true } },
            { label: "none", set: { hintShown: false } }
        ] },
        { label: "required", options: [
            { label: "yes", set: { required: true } },
            { label: "no", set: { required: false } }
        ] },
        { label: "size", options: [
            { label: "sm", set: { size: "sm" } },
            { label: "md", set: { size: "md" } },
            { label: "lg", set: { size: "lg" } }
        ] }
    ]

    readonly property var integration: ({
        events: ["toggle-requested", "accepted"],
        actions: ["toggle", "accept"],
        targets: ({
            control: () => root.controlItem,
            label: () => root.find(field, "controlLabel")
        }),
        observables: {
            failed: () => field.failed,
            "control-failed": () => root.control === "text" ? root.controlItem?.failed ?? false : false,
            toggled: () => root.toggled,
            password: () => root.password,
            "control-focused": () => root.control === "text" ? root.controlItem?.focused ?? false : root.controlItem?.activeFocus ?? false,
            "control-keyboard-focused": () => root.control === "text" ? root.controlItem?.keyboardFocused ?? false : false,
            "size-scale": () => field.sizeScale,
            toggles: () => root.toggles,
            accepted: () => root.acceptedCount,
            label: () => field.label,
            "accessibility-name": () => root.accessibleItem?.Accessible.name ?? "",
            "accessibility-description": () => root.accessibleItem?.Accessible.description ?? "",
            required: () => field.required,
            error: () => field.error,
            hint: () => field.hint,
            "message-truncated": () => root.find(field, "fieldMessage")?.truncated ?? false,
            "message-lines": () => root.find(field, "fieldMessage")?.lineCount ?? 0,
            size: () => root.size
        },
        runAction: name => {
            if (name === "toggle" && root.control === "switch") { root.controlItem.flip(); return true }
            if (name === "accept" && root.control === "text") return root.controlItem.accept()
            return false
        },
        keys: {
            "Enter": () => {
                if (root.control === "switch") { root.controlItem.flip(); return true }
                return root.controlItem.accept()
            }
        }
    })
}
