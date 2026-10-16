import QtQuick

import qs.QsmShell.Components
import qs.QsmShell.Style

Rectangle {
    id: root

    property string variant: ""
    property var eventRecorder: null
    property bool revealed: true
    property bool suppressed: false
    property bool fullscreen: false
    property bool detached: false
    property var entryFilter: null
    property bool registerHitRect: true

    color: Style.band
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
        bodyHeight: body.childrenRect.height + padding * 2

        Card {
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
        actions: ["add-capsule", "remove-capsule"],
        idle: () => !(rollout.offsetScale > 0 && rollout.offsetScale < 1),
        observables: {
            bulges: () => border.bulgeEntries.length,
            "hit-regions": () => border.maskRects.length,
            capsules: () => border.fullscreenCapsuleEntries.length,
            revealed: () => root.revealed,
            suppressed: () => root.suppressed
        },
        runAction: name => {
            if (name === "add-capsule") {
                border.registerFullscreenCapsule("capsule",
                    Qt.rect(0, 0, Style.controlWidth, Style.controlHeight),
                    Style.radiusPill);
                return true;
            }
            if (name === "remove-capsule") {
                border.unregisterFullscreenCapsule("capsule");
                return true;
            }
            return false;
        }
    })
}
