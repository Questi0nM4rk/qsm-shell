import QtQuick
import QtQuick.Layouts
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
Rectangle {
    id: root

    property string variant: ""
    property var eventRecorder: null

    implicitWidth: 160
    implicitHeight: 64
    radius: Style.radiusMd
    color: Style.surface

    StateLayer {
        anchors.fill: parent
        interactive: root.variant !== "disabled"
        // A rollout trigger takes part in hover and not in press. The unit
        // reaches it through a control because a pointer cannot produce it.
        clickable: root.variant !== "trigger"
        onClicked: root.eventRecorder?.("intent", "clicked", {})
        onHoveredEntered: root.eventRecorder?.("intent", "hovered", {})
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
            interactive: () => root.variant !== "disabled",
            clickable: () => root.variant !== "trigger"
        },
        runAction: name => {
            if (name !== "click")
                return false;
            root.eventRecorder?.("intent", "clicked", {});
            return true;
        }
    })
}
