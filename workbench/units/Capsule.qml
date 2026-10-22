import QtQuick

import qs.QsmShell.Components
import qs.QsmShell.Style

Rectangle {
    id: root

    property string variant: ""
    property var eventRecorder: null
    property bool active: variant === "active"
    property string size: "sm"
    property string emphasis: "secondary"
    // label | reading | long | glyph: the same wireless toggle, composed whole.
    property string content: variant === "active" ? "reading" : "label"
    // band | card: the ground the capsule rests on. A body the colour of its
    // ground is no body, so on a surface card the capsule takes the overlay rung.
    property string ground: "band"
    // natural | narrow | wide: the width the host gives it.
    property string span: "natural"

    // The ground a capsule is judged on: a ghost paints nothing at rest.
    color: Style.band
    implicitWidth: Style.controlWidth
    implicitHeight: Style.controlWidth

    Rectangle {
        anchors.centerIn: parent
        visible: root.ground === "card"
        width: pill.width + Style.space4 * 2
        height: pill.height + Style.space4 * 2
        radius: Style.radiusBody
        color: Style.surface
    }

    Capsule {
        id: pill
        anchors.centerIn: parent
        icon: "power"
        label: root.content === "glyph" ? "" : root.content === "long" ? "Wireless off · click to enable" : "Wireless"
        detail: root.content === "reading" ? "2 paired" : ""
        accessibleName: "Wireless"
        checkable: true
        size: root.size
        variant: root.emphasis
        base: root.ground === "card" ? Style.overlay : Style.surface
        active: root.active
        width: root.span === "narrow" ? Style.controlWidth / 4
            : root.span === "wide" ? Style.controlWidth / 2 : implicitWidth
        onClicked: {
            root.active = !root.active
            root.eventRecorder?.("intent", "clicked", { active: root.active })
        }
    }

    readonly property var controls: [
        { label: "state", options: [
            { label: "enabled", set: { enabled: true } },
            { label: "disabled", set: { enabled: false } }
        ] },
        { label: "active", options: [
            { label: "on", set: { active: true } },
            { label: "off", set: { active: false } }
        ] },
        { label: "size", options: [
            { label: "xs", set: { size: "xs" } },
            { label: "sm", set: { size: "sm" } },
            { label: "md", set: { size: "md" } },
            { label: "lg", set: { size: "lg" } }
        ] },
        { label: "variant", options: [
            { label: "ghost", set: { emphasis: "ghost" } },
            { label: "secondary", set: { emphasis: "secondary" } },
            { label: "primary", set: { emphasis: "primary" } },
            { label: "destructive", set: { emphasis: "destructive" } }
        ] },
        { label: "content", options: [
            { label: "label", set: { content: "label" } },
            { label: "reading", set: { content: "reading" } },
            { label: "long", set: { content: "long" } },
            { label: "glyph-only", set: { content: "glyph" } }
        ] },
        { label: "width", options: [
            { label: "natural", set: { span: "natural" } },
            { label: "narrow", set: { span: "narrow" } },
            { label: "wide", set: { span: "wide" } }
        ] },
        { label: "ground", options: [
            { label: "band", set: { ground: "band" } },
            { label: "card", set: { ground: "card" } }
        ] }
    ]
    readonly property var integration: ({
        events: ["clicked"],
        actions: ["activate"],
        targets: ({ capsule: () => pill, scene: () => root }),
        observables: {
            active: () => root.active,
            hovered: () => pill.hovered,
            pressed: () => pill.pressed,
            focused: () => pill.visualFocus,
            raised: () => Qt.colorEqual(pill.base, Style.overlay),
            width: () => pill.width,
            height: () => pill.height
        },
        runAction: name => {
            if (name !== "activate")
                return false
            pill.activate()
            return true
        }
    })
}
