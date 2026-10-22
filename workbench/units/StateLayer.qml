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
    property int clicks: 0

    implicitWidth: Style.controlWidth / 2
    implicitHeight: Style.size("Control", "lg")

    // The host: it owns the pointer target, the keys and the focus. The layer
    // fills it at rest size, so the hit zone never grows with the body.
    Item {
        id: sample
        anchors.centerIn: parent
        width: root.implicitWidth
        height: root.implicitHeight
        enabled: root.variant !== "disabled"
        activeFocusOnTab: enabled
        Accessible.role: Accessible.Button
        Accessible.name: "State layer sample"
        Accessible.onPressAction: stateLayer.activate()
        Keys.onSpacePressed: stateLayer.activate()
        Keys.onReturnPressed: stateLayer.activate()
        Keys.onEnterPressed: stateLayer.activate()

        // The layer reports `growth`; the body takes it on every side.
        Surface {
            id: body
            x: -stateLayer.growth
            y: -stateLayer.growth
            width: sample.width + 2 * stateLayer.growth
            height: sample.height + 2 * stateLayer.growth
            radius: Style.radiusMd
            hovered: stateLayer.hovered
            pressed: stateLayer.pressed
        }

        StateLayer {
            id: stateLayer
            anchors.fill: parent
            interactive: sample.enabled
            bodyGrows: true
            clickable: root.variant !== "trigger"
            focusRadius: Style.radiusMd
            onClicked: {
                sample.forceActiveFocus(Qt.MouseFocusReason)
                root.clicks++
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
        targets: ({ host: () => sample }),
        observables: {
            interactive: () => stateLayer.interactive,
            clickable: () => stateLayer.clickable,
            clicks: () => root.clicks,
            hovered: () => stateLayer.hovered,
            pressed: () => stateLayer.pressed,
            "ring-shown": () => stateLayer.ringShown,
            // The hover or press ease has finished: growth is its final size.
            settled: () => stateLayer.response === (stateLayer.pressed ? stateLayer.pressScale
                : stateLayer.hovered ? stateLayer.hoverScale : 1),
            // How far the ring's gap from the (grown) body is off the gap plus
            // stroke it promises; 0 at rest, hovered and pressed.
            "ring-gap-error": () => {
                const ring = stateLayer.children.find(child => child.color !== undefined && child.color.a === 0)
                if (!ring)
                    return -1
                const promised = 2 * Style.stroke(Style.indicatorWidth, sample)
                return Math.round((body.x - ring.mapToItem(sample, 0, 0).x - promised) * 1000) / 1000
            }
        },
        runAction: name => {
            if (name !== "click")
                return false;
            return stateLayer.activate();
        }
    })
}
