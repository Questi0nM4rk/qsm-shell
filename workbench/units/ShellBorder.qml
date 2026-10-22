import QtQuick

import qs.QsmShell.Components
import qs.QsmShell.Style

Item {
    id: root

    property string variant: ""
    property var eventRecorder: null
    property bool revealed: true
    property bool suppressed: false
    property bool fullscreen: false
    property bool detached: false
    property var entryFilter: null
    property bool registerHitRect: true

    implicitWidth: Style.controlWidth
    implicitHeight: Style.controlWidth

    ShellBorder {
        id: border
        anchors.fill: parent
        fullscreen: root.fullscreen
        entryFilter: root.entryFilter
    }

    Item {
        id: band
        width: Style.space4
        height: Style.frameThickness
        x: (root.width - width) / 2
    }

    Rollout {
        id: rollout
        host: border
        rolloutId: "rail"
        edges: ["top"]
        anchorItem: band
        shouldBeActive: root.revealed
        suppressed: root.suppressed
        fullscreenDetached: root.detached
        registerHitRect: root.registerHitRect
        padding: Style.space4
        bodyWidth: Style.controlWidth / 2 + padding * 2
        bodyHeight: card.height + padding * 2

        Card {
            id: card
            radius: Style.rolloutRadius - rollout.padding
            width: Style.controlWidth / 2
            height: body.implicitHeight + Style.space4 * 2

            Prose {
                id: body
                anchors.fill: parent
                anchors.margins: Style.space4
                role: "body"
                text: "Panel switched"
            }
        }
    }

    readonly property var controls: [
        { label: "mode", options: [
            { label: "shown", set: { revealed: true, suppressed: false } },
            { label: "hidden", set: { revealed: false, suppressed: false } },
            { label: "suppressed", set: { revealed: true, suppressed: true } }
        ] },
        { label: "state", options: [
            { label: "windowed", set: { fullscreen: false } },
            { label: "fullscreen", set: { fullscreen: true } }
        ] },
        { label: "form", options: [
            { label: "attached", set: { detached: false } },
            { label: "detached", set: { detached: true } }
        ] },
        { label: "hit", options: [
            { label: "registered", set: { registerHitRect: true } },
            { label: "withheld", set: { registerHitRect: false } }
        ] },
        { label: "policy", options: [
            { label: "all", set: { entryFilter: null } },
            { label: "filtered", set: { entryFilter: id => false } }
        ] }
    ]

    readonly property var integration: ({
        events: [],
        actions: ["add-capsule", "remove-capsule", "fill-slots", "clear-slots"],
        idle: () => !(rollout.offsetScale > 0 && rollout.offsetScale < 1),
        observables: {
            bulges: () => border.bulgeEntries.length,
            "painted-bulges": () => border.paintedBulges,
            "hit-regions": () => border.maskRects.length,
            capsules: () => border.fullscreenCapsuleEntries.length,
            revealed: () => root.revealed,
            suppressed: () => root.suppressed
        },
        runAction: name => {
            if (name === "add-capsule") {
                border.registerFullscreenCapsule("capsule",
                    Qt.rect(0, 0, Style.controlWidth, Style.size("Control", "md")),
                    Style.radiusPill);
                return true;
            }
            if (name === "remove-capsule") {
                border.unregisterFullscreenCapsule("capsule");
                return true;
            }
            if (name === "fill-slots") {
                for (let i = 0; i < border.maxBulgeSlots; i++)
                    border.registerBulge("slot-" + i, Qt.rect(8 + i * 12, 200, 8, 8),
                        Qt.vector4d(0, 0, 0, 0), 1, Qt.vector4d(1, 0, 0, 1), 1, 0, 0, true, 1);
                return true;
            }
            if (name === "clear-slots") {
                for (let i = 0; i < border.maxBulgeSlots; i++)
                    border.unregisterBulge("slot-" + i);
                return true;
            }
            return false;
        }
    })
}
