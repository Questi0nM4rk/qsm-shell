import QtQuick

import qs.QsmShell.Components
import qs.QsmShell.Style

Rectangle {
    id: root

    property string variant: ""
    property var eventRecorder: null
    property var inputDriver: null
    property int windowSize: 2
    property int geometryUpdates: 0
    property int nextId: 3
    property bool pendingArrivalDuringRetreat: false
    property int retreatArrivals: 0
    property int primaryCallbackCount: 0
    property var primaryCallbackIds: []
    property string callbackEvidence: ""
    // Newest-first, matching the host publication contract.
    property var all: [
        { notificationId: "b", appName: "Files", summary: "Transfer started",
            body: "Copying the project archive to backup storage.", urgency: "normal", createdAt: Date.now(),
            actions: [{ id: "details", label: "Details" },
                { id: "default", label: "Open transfer" }] },
        { notificationId: "a", appName: "Files", summary: "Backup storage connected",
            body: "The backup destination is ready.", urgency: "low", createdAt: Date.now(),
            actions: [{ id: "settings", label: "Settings" }] }
    ]

    readonly property var windowed: root.all.slice(0, root.windowSize)
    readonly property var rolloutHost: border
    property var replacementRow: null
    property bool replacementKeptRow: false

    color: Style.band
    implicitWidth: Style.notificationWidth + Style.rolloutPadding * 2 + Style.space6 * 2
    implicitHeight: Style.controlWidth + Style.space6 * 2

    ScenePointer { id: scenePointer }
    ShellBorder {
        id: border
        anchors.fill: parent
        pointer: scenePointer
    }

    Item {
        id: band
        x: (root.width - width) / 2
        width: Style.notificationWidth + Style.rolloutPadding * 2
        height: border.edge
    }

    function card(id): var {
        return stack.targetForNotification(id);
    }

    function arrive(): void {
        const id = String.fromCharCode(96 + root.nextId++);
        root.all = [{ notificationId: id, appName: "Shell", summary: "Transfer complete",
            body: "The same transfer reports its latest result.", urgency: "normal",
            createdAt: Date.now(), actions: [{ id: "open", label: "Open" }] }].concat(root.all);
        root.eventRecorder?.("scenario", "arrival", { id });
    }

    function arriveCritical(): void {
        const id = String.fromCharCode(96 + root.nextId++);
        root.all = [{ notificationId: id, appName: "Power", summary: "Battery critically low",
            body: "Plug in within five minutes or the session will hibernate.", urgency: "critical",
            createdAt: Date.now() }].concat(root.all);
        root.eventRecorder?.("scenario", "arrival", { id });
    }

    function arriveLong(): void {
        const id = String.fromCharCode(96 + root.nextId++);
        root.all = [{ notificationId: id, appName: "Mail", summary: "Weekly report",
            body: "The quarterly numbers are in and the summary is attached. Revenue is up on the previous period and the three open risks from the last review are closed; the remaining items need a decision from you before the end of the week. Please read section four first.",
            urgency: "normal", createdAt: Date.now(), actions: [{ id: "default", label: "Open message" }] }].concat(root.all);
        root.eventRecorder?.("scenario", "arrival", { id });
    }

    function arriveColour(): void {
        const id = String.fromCharCode(96 + root.nextId++);
        root.all = [{ notificationId: id, appName: "Colour picker", summary: "#c78fe0",
            body: "Copied to the clipboard.", urgency: "normal", createdAt: Date.now() }].concat(root.all);
        root.eventRecorder?.("scenario", "arrival", { id });
    }

    function replaceNewest(): void {
        if (root.all.length === 0)
            return;
        const current = root.all[0];
        root.replacementRow = root.card(current.notificationId);
        root.all = [{ notificationId: current.notificationId, appName: current.appName,
            summary: "Transfer complete", body: "Updated result for the same transfer.",
            urgency: current.urgency, createdAt: current.createdAt,
             actions: [{ id: "open", label: "Open", disabled: false }] }].concat(root.all.slice(1));
        root.replacementKeptRow = root.card(current.notificationId) === root.replacementRow;
        root.eventRecorder?.("scenario", "same-id-replacement", { id: current.notificationId });
    }

    function expireNewest(): void {
        if (root.all.length > 0)
            root.all = root.all.slice(1);
    }

    function clearAll(): void {
        root.all = [];
    }

    function setNewestDefault(available: bool): void {
        if (root.all.length === 0)
            return;
        const current = root.all[0];
        const actions = [{ id: "details", label: "Details" }];
        if (available)
            actions.push({ id: "default", label: "Open transfer" });
        root.all = [Object.assign({}, current, { actions })].concat(root.all.slice(1));
    }

    function arriveDuringRetreat(): void {
        root.pendingArrivalDuringRetreat = true;
        root.clearAll();
    }

    Rollout {
        id: rollout
        anchorItem: band
        host: root.rolloutHost
        rolloutId: "notification-stack-fixture"
        edges: ["top"]
        shouldBeActive: root.all.length > 0
        tier: "small"
        // The cards stand one rollout padding inside the body, which is what
        // makes `Style.radiusBody` concentric with the rollout's corners.
        padding: Style.rolloutPadding
        bodyWidth: stack.implicitWidth + padding * 2
        bodyHeight: stack.implicitHeight + padding * 2
        // Row heights already animate; the containing aperture follows directly.
        animateBodySize: false

        NotificationStack {
            id: stack
            width: implicitWidth
            height: implicitHeight
            stack: root.windowed
            isAlive: id => root.all.some(entry => entry.notificationId === id)
            // A colour-picker announcement's summary IS the picked colour.
            swatchFor: entry => entry.appName === "Colour picker" && /^#[0-9a-fA-F]{6}$/.test(entry.summary)
                ? entry.summary : undefined
            retainWhenEmpty: rollout.visible
            inputEnabled: rollout.shouldBeActive

            onDismissRequested: entry => {
                root.all = root.all.filter(item => item.notificationId !== entry.notificationId);
                root.eventRecorder?.("intent", "dismiss-requested", { id: entry.notificationId });
            }
            onPrimaryActionRequested: entry => {
                // This unit answers the intent with fixture evidence only.
                root.primaryCallbackCount++;
                root.primaryCallbackIds = [entry.notificationId].concat(root.primaryCallbackIds);
                root.callbackEvidence = `Fixture callback · ${entry.notificationId} · default`;
                root.eventRecorder?.("component", "primary-triggered", { id: entry.notificationId });
                root.eventRecorder?.("client", "action-invoked", {
                    id: entry.notificationId, action: "default", outcome: "fixture-callback-only"
                });
            }
            onHoverChanged: (entry, hovered) => root.eventRecorder?.("intent", "hover-changed",
                { id: entry.notificationId, hovered })
            onGeometryChanged: {
                root.geometryUpdates++;
                root.eventRecorder?.("intent", "geometry-changed",
                    { updates: root.geometryUpdates });
            }
        }
    }

    Connections {
        target: rollout
        function onOffsetScaleChanged() {
            if (root.pendingArrivalDuringRetreat && rollout.offsetScale > 0) {
                root.pendingArrivalDuringRetreat = false;
                root.retreatArrivals++;
                root.arrive();
            }
        }
    }

    readonly property var controls: [
        { label: "arrival", options: [
            { label: "arrive", call: "arrive" },
            { label: "arrive-critical", call: "arriveCritical" },
            { label: "arrive-colour", call: "arriveColour" },
            { label: "arrive-long", call: "arriveLong" },
            { label: "same-id-update", call: "replaceNewest" },
            { label: "expire-newest", call: "expireNewest" },
            { label: "clear", call: "clearAll" },
            { label: "arrive-during-retreat", call: "arriveDuringRetreat" }
        ] },
        { label: "window", options: [
            { label: "one", set: { windowSize: 1 } },
            { label: "two", set: { windowSize: 2 } },
            { label: "three", set: { windowSize: 3 } }
        ] },
        { label: "primary-action", options: [
            { label: "default-provided", call: "setDefaultProvided" },
            { label: "no-default", call: "setNoDefault" }
        ] }
    ]

    readonly property var integration: ({
        events: ["dismiss-requested", "hover-changed", "geometry-changed", "primary-triggered", "action-invoked"],
        actions: ["activate-newest-primary", "focus-newest"],
        targets: {
            scene: () => root,
            newest: () => root.all.length ? root.card(root.all[0].notificationId) : null,
            oldest: () => stack.displayStack.length ? root.card(stack.displayStack[0].notificationId) : null
        },
        idle: () => stack.evicting.length === 0 && !stack.rowHeightsAnimating
            && (rollout.revealProgress === 0 || rollout.revealProgress === 1),
        observables: {
            count: () => stack.displayStack.length,
            rendered: () => stack.cardGeometry().length,
            evicting: () => stack.evicting.length,
            ids: () => stack.displayStack.map(entry => entry.notificationId).join(","),
            phases: () => stack.cardGeometry().map(row => row.phase).join(","),
            eligible: () => stack.cardGeometry().map(row => row.eligible ? "1" : "0").join(","),
            "geometry-updates": () => root.geometryUpdates,
            "rollout-visible": () => rollout.visible,
            "retreat-arrivals": () => root.retreatArrivals,
            "replacement-kept-row": () => root.replacementKeptRow,
            "primary-callback-count": () => root.primaryCallbackCount,
            "primary-callback-ids": () => root.primaryCallbackIds.join(","),
            "callback-evidence": () => root.callbackEvidence,
            "newest-expanded": () => root.all.length > 0 && root.card(root.all[0].notificationId)?.expanded === true,
            "newest-hovered": () => root.all.length > 0 && root.card(root.all[0].notificationId)?.hovered === true,
            "newest-focused": () => root.all.length > 0 && root.card(root.all[0].notificationId)?.activeFocus === true,
            "newest-drag-active": () => root.all.length > 0 && root.card(root.all[0].notificationId)?.dragActive === true,
            "source-count": () => root.all.length,
            "reveal-progress": () => rollout.revealProgress,
            retracting: () => rollout.visible && rollout.offsetScale > 0
        },
        runAction: name => {
            if (root.all.length === 0)
                return false;
            const card = root.card(root.all[0].notificationId);
            // The host grants the newest row keyboard focus, as a focus-capable popup host does.
            if (name === "focus-newest") {
                card?.forceActiveFocus();
                return !!card && card.activeFocus;
            }
            return name === "activate-newest-primary" && !!card && card.activatePrimary();
        }
    })

    function setDefaultProvided(): void { root.setNewestDefault(true); }
    function setNoDefault(): void { root.setNewestDefault(false); }

    function applyControl(groupIndex: int, optionIndex: int): bool {
        const group = root.controls[groupIndex];
        const option = group?.options[optionIndex];
        if (!option)
            return false;
        if (option.call === "setDefaultProvided")
            root.setNewestDefault(true);
        else if (option.call === "setNoDefault")
            root.setNewestDefault(false);
        else
            return false;
        return true;
    }
}
