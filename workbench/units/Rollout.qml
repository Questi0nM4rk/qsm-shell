import QtQuick
import QtQuick.Layouts

import qs.QsmShell.Components
import qs.QsmShell.Style

Rectangle {
    id: root

    property string variant: ""
    property var eventRecorder: null
    property bool revealed: true
    property bool hoverOpen: false
    property bool suppressed: false
    property bool fullscreen: false
    property bool detached: false
    property string edge: "top"
    property string layerMode: "plain"
    property bool detailsOpen: true
    property bool quiet: false
    property bool alarmsAudible: true
    property bool controlsEnabled: true
    property string contentMode: "normal"
    property string extent: "compact"
    property string motionTier: "small"
    readonly property bool horizontal: root.edge === "left" || root.edge === "right"
    readonly property bool nested: root.layerMode !== "plain"
    readonly property bool openIntent: root.revealed || (root.hoverOpen && rollout.wantsOpen)
    readonly property var activeRollout: rollout

    color: Style.band
    implicitWidth: Style.controlWidth * 2 + Style.space6 * 2
    implicitHeight: Style.controlWidth + Style.space6 * 2

    ScenePointer {
        id: scenePointer
    }

    ShellBorder {
        id: border
        anchors.fill: parent
        fullscreen: root.fullscreen
        pointer: scenePointer
        leftEdge: Style.frameThickness + Style.space6
    }

    Item {
        id: band
        width: root.horizontal ? (root.edge === "left" ? border.leftEdge : border.edge) : Style.controlHeight
        height: root.horizontal ? Style.controlHeight : border.edge
        x: root.edge === "right" ? root.width - width : root.edge === "left" ? 0 : (root.width - width) / 2
        y: root.edge === "bottom" ? root.height - height : root.edge === "top" ? 0 : (root.height - height) / 2
    }

    Rollout {
        id: rollout
        host: border
        rolloutId: "sound"
        edges: [root.edge]
        anchorItem: band
        tier: root.motionTier
        // Host intent only; the source is held for its child through childRollout.
        shouldBeActive: root.openIntent
        suppressed: root.suppressed
        fullscreenDetached: root.detached
        triggerAreas: [rollout.anchorRect]
        childRollout: childPanel
        padding: Style.space4
        bodyWidth: root.extent === "wide" ? Style.controlWidth : Style.controlWidth - Style.space6 * 2
        bodyHeight: Style.controlHeight * 3 + Style.space6 * 2

        ColumnLayout {
            anchors.fill: parent
            spacing: Style.space3
            visible: root.contentMode !== "empty"
            Prose {
                Layout.fillWidth: true
                role: "heading"
                text: "Notification sounds"
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: Style.space3
                Prose {
                    Layout.fillWidth: true
                    role: "label"
                    text: root.contentMode === "long"
                        ? "Mute notification sounds while concentrating on the current task"
                        : "Quiet mode"
                }
                Switch {
                    id: quietToggle
                    text: "Quiet mode"
                    Accessible.name: text
                    checked: root.quiet
                    enabled: root.controlsEnabled
                    onToggleRequested: next => {
                        root.quiet = next
                        root.eventRecorder?.("intent", "quiet-changed", { checked: next })
                    }
                }
            }
            Prose {
                Layout.fillWidth: true
                role: "supporting"
                text: root.quiet ? "Notification sounds muted" : "Notification sounds enabled"
            }
            Capsule {
                id: detailsButton
                visible: root.nested
                variant: "ghost"
                size: "sm"
                label: root.detailsOpen ? "Hide alarm settings" : "Alarm settings"
                enabled: root.controlsEnabled
                onClicked: {
                    root.detailsOpen = !root.detailsOpen
                    root.eventRecorder?.("intent", "details-changed", { open: root.detailsOpen })
                }
            }
            Item { Layout.fillHeight: true }
        }
        Prose {
            anchors.fill: parent
            visible: root.contentMode === "empty"
            verticalAlignment: Text.AlignVCenter
            role: "body"
            text: "No sound preferences available"
        }
    }

    Rollout {
        id: childPanel
        host: border
        rolloutId: "alarms"
        edges: [root.edge]
        parentRollout: rollout
        tier: root.motionTier
        shouldBeActive: root.nested && root.detailsOpen && root.contentMode !== "empty"
            && root.openIntent
            && rollout.revealProgress >= 1
        suppressed: root.suppressed
        fullscreenDetached: root.detached
        // These extents already follow the parent's size morph.
        animateBodySize: false
        padding: Style.space4
        bodyWidth: root.horizontal ? Style.controlWidth - Style.space6 * 2
            : root.layerMode === "full-span-child" ? rollout.bodyWidth : rollout.bodyWidth - Style.space6
        bodyHeight: !root.horizontal ? Style.controlHeight * 3 + padding * 2
            : root.layerMode === "full-span-child" ? rollout.bodyHeight : rollout.bodyHeight - Style.space6

        ColumnLayout {
            anchors.fill: parent
            spacing: Style.space3
            Prose { Layout.fillWidth: true; role: "heading"; text: "Alarms" }
            RowLayout {
                Layout.fillWidth: true
                spacing: Style.space3
                Prose { Layout.fillWidth: true; role: "label"; text: "Keep alarms audible" }
                Switch {
                    id: alarmsToggle
                    text: "Keep alarms audible"
                    Accessible.name: text
                    checked: root.alarmsAudible
                    enabled: root.controlsEnabled
                    onToggleRequested: next => {
                        root.alarmsAudible = next
                        root.eventRecorder?.("intent", "alarms-changed", { checked: next })
                    }
                }
            }
            Prose {
                Layout.fillWidth: true
                role: "supporting"
                text: root.alarmsAudible ? "Alarms can still sound in quiet mode" : "Alarms follow quiet mode"
            }
            Item { Layout.fillHeight: true }
        }
    }

    readonly property var controls: [
        { label: "mode", options: [
            { label: "shown", set: { revealed: true, hoverOpen: false, suppressed: false } },
            { label: "hidden", set: { revealed: false, hoverOpen: false, suppressed: false } },
            { label: "hover-open", set: { revealed: false, hoverOpen: true, suppressed: false } },
            { label: "suppressed", set: { revealed: true, suppressed: true } }
        ] },
        { label: "edge", options: [
            { label: "left", set: { edge: "left" } },
            { label: "right", set: { edge: "right" } },
            { label: "top", set: { edge: "top" } },
            { label: "bottom", set: { edge: "bottom" } }
        ] },
        { label: "layer", options: [
            { label: "plain", set: { layerMode: "plain" } },
            { label: "short-child", set: { layerMode: "short-child", detailsOpen: true } },
            { label: "full-span-child", set: { layerMode: "full-span-child", detailsOpen: true } }
        ] },
        { label: "width", options: [
            { label: "compact", set: { extent: "compact" } },
            { label: "wide", set: { extent: "wide" } }
        ] },
        { label: "content", options: [
            { label: "normal", set: { contentMode: "normal" } },
            { label: "long", set: { contentMode: "long" } },
            { label: "empty", set: { contentMode: "empty" } }
        ] },
        { label: "actions", options: [
            { label: "enabled", set: { controlsEnabled: true } },
            { label: "disabled", set: { controlsEnabled: false } }
        ] },
        { label: "tier", options: [
            { label: "small", set: { motionTier: "small" } },
            { label: "large", set: { motionTier: "large" } }
        ] },
        { label: "form", options: [
            { label: "attached", set: { detached: false } },
            { label: "detached", set: { detached: true } }
        ] },
        { label: "state", options: [
            { label: "windowed", set: { fullscreen: false } },
            { label: "fullscreen", set: { fullscreen: true } }
        ] }
    ]

    function invokeControl(control: Item, action: var): bool {
        if (!control.visible || !control.enabled)
            return false
        action()
        return true
    }

    readonly property var actionHandlers: ({
        "toggle-quiet": () => root.invokeControl(quietToggle, () => quietToggle.flip()),
        "toggle-alarms": () => root.invokeControl(alarmsToggle, () => alarmsToggle.flip()),
        "toggle-details": () => root.invokeControl(detailsButton, () => detailsButton.activate())
    })

    readonly property var integration: ({
        events: ["quiet-changed", "alarms-changed", "details-changed"],
        actions: Object.keys(root.actionHandlers),
        idle: () => [rollout, childPanel].every(item =>
            !item.animating && !(item.keepOpen && !item.hovered)),
        observables: {
            "hit-active": () => root.activeRollout.hitActive,
            capsules: () => border.fullscreenCapsuleEntries.length,
            "attached-left": () => rollout.attached("left"),
            "attached-right": () => rollout.attached("right"),
            "attached-top": () => rollout.attached("top"),
            "attached-bottom": () => rollout.attached("bottom"),
            nested: () => root.nested && childPanel.parentRollout === rollout,
            "exact-seam": () => childPanel.flushToParent,
            "parent-child-linked": () => rollout.childRollout === childPanel,
            quiet: () => root.quiet,
            "alarms-audible": () => root.alarmsAudible,
            "details-open": () => root.detailsOpen,
            "reveal-progress": () => rollout.revealProgress,
            "settled-body": () => rollout.settledBodyRect,
            "viewport-rect": () => rollout.viewportRect,
            "bulge-count": () => border.bulgeEntries.length,
            "region-count": () => Object.keys(border.rolloutRegions).length,
            "registration-ready": () => root.activeRollout.rolloutId in border.bulgeRegions
                && root.activeRollout.rolloutId in border.rolloutRegions
        },
        runAction: name => Object.prototype.hasOwnProperty.call(root.actionHandlers, name)
            ? root.actionHandlers[name]() : false
    })
}
