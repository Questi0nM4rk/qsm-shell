import QtQuick
import qs.QsmShell.Components
import qs.QsmShell.Style

// One unit, one file, named by `workbench/stories.json`. The harness resolves
// it from the catalog and drives it through `controls` and `integration`, so
// nothing in the harness knows this type exists.
//
// It is a FRONTEND: it answers every signal the type hands upward (here
// `clicked` and `hoveredEntered`) and it reaches the property-only states a
// pointer cannot, through declared controls. It decides nothing about the
// component's behaviour — five states, clickable vs interactive and the focus
// ring all belong to `StateLayer`.
Item {
    id: root

    property string variant: ""
    property var eventRecorder: null

    implicitWidth: Style.controlWidth / 2
    implicitHeight: Style.controlHeightLg

    Rectangle {
        id: body
        anchors.centerIn: parent
        width: root.implicitWidth
        height: root.implicitHeight
        enabled: root.variant !== "disabled"
        activeFocusOnTab: enabled
        radius: Style.radiusMd
        color: enabled ? Style.surface : Style.disabled(Style.surface)
        Accessible.role: Accessible.Button
        Accessible.name: "State layer sample"
        Accessible.onPressAction: layer.activate()
        Keys.onSpacePressed: layer.activate()
        Keys.onReturnPressed: layer.activate()

        StateLayer {
            id: layer
            x: -Style.spaceTight
            y: -Style.spaceTight
            width: body.width + Style.spaceTight * 2
            height: body.height + Style.spaceTight * 2
            interactive: body.enabled
            clickable: root.variant !== "trigger"
            focusRadius: body.radius + Style.spaceTight
            onClicked: {
                body.forceActiveFocus(Qt.MouseFocusReason)
                root.eventRecorder?.("intent", "clicked", {})
            }
            onHoveredEntered: root.eventRecorder?.("intent", "hovered", {})
        }
    }

    readonly property var controls: [
        { label: "purpose", options: [
            { label: "action", set: { variant: "action" } },
            { label: "trigger", set: { variant: "trigger" } },
            { label: "disabled", set: { variant: "disabled" } }
        ] }
    ]
    readonly property var integration: ({
        events: ["clicked", "hovered"],
        actions: ["click"],
        observables: {
            interactive: () => layer.interactive,
            clickable: () => layer.clickable
        },
        runAction: name => {
            if (name !== "click")
                return false;
            return layer.activate();
        }
    })
}
