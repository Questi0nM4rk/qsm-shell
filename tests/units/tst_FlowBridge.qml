import QtQuick
import QtTest

// Focused flow-bridge contracts (workbench bead 1q6.2) for the shared
// Preview/CompositionPreview integration bridge: capability discovery,
// preflight without mutation, injected event routing with origins, named
// action/control/input execution, typed observable reads, reset, and
// unsupported-capability failure. Offscreen; no pixels, no visual
// constants, no animation checkpoints (bead .4).
TestCase {
    id: probe

    name: "FlowBridge"
    width: 800
    height: 600
    visible: true
    when: windowShown

    SignalSpy { id: eventSpy; signalName: "eventRecorded" }

    function makeSolo(componentKey, variant) {
        const component = Qt.createComponent("../../workbench/StoryHost.qml");
        verify(component.status === Component.Ready,
            "StoryHost did not compile: " + component.errorString());
        const preview = component.createObject(probe, {
            component: componentKey, variant: variant, storyKey: "probe-flow-solo"
        });
        verify(preview !== null, "could not construct StoryHost");
        eventSpy.target = preview;
        eventSpy.clear();
        return preview;
    }

    function makeComposition(doc) {
        const component = Qt.createComponent("../../workbench/CompositionPreview.qml");
        verify(component.status === Component.Ready,
            "CompositionPreview did not compile: " + component.errorString());
        const preview = component.createObject(probe, { composition: doc });
        verify(preview !== null, "could not construct CompositionPreview");
        eventSpy.target = preview;
        eventSpy.clear();
        return preview;
    }

    function rolloutDoc() {
        return {
            version: 1, key: "probe-flow", viewport: [960, 600],
            root: { id: "demo", type: "column", props: { spacing: "md", padding: "md" },
                children: [
                    { id: "trigger", type: "text-field",
                        props: { size: "md", state: "default", label: "Command", text: "" } },
                    { id: "panel", type: "shell-border-rollout",
                        props: { side: "right", open: false },
                        children: [
                            { id: "confirm-step", type: "checkbox",
                                props: { checked: false, label: "Confirm rollout" } }
                        ] }
                ] },
            links: [
                { from: { node: "trigger", event: "accepted" }, to: { node: "panel", action: "open" } },
                { from: { node: "confirm-step", event: "toggled" }, to: { node: "panel", action: "close" } }
            ]
        };
    }

    function records() {
        const out = [];
        for (let i = 0; i < eventSpy.count; i++)
            out.push(eventSpy.signalArguments[i][0]);
        return out;
    }

    function lastRecord() {
        return eventSpy.count > 0 ? eventSpy.signalArguments[eventSpy.count - 1][0] : null;
    }

    function test_solo_text_field_capabilities() {
        const preview = makeSolo("text-input", "text-filled");
        tryCompare(preview, "storyStatus", "ready", 8000);
        const caps = preview.flowCapabilities();
        compare(caps.events, ["accepted", "changed"], "solo TextField events changed shape");
        compare(caps.actions, ["clear", "focus"], "solo TextField actions changed shape");
        for (const name of ["text", "enabled", "focused", "failed", "readonly"])
            verify(caps.observables.indexOf(name) >= 0, "solo TextField is missing observable: " + name);
        compare(caps.keys, ["Enter", "Escape"], "solo TextField keys changed shape");
        verify(caps.textDriver, "solo TextField lost its text driver");
        compare(caps.checkpoints, [], "solo bridge invented checkpoints");
        preview.destroy();
    }

    function test_solo_checkbox_capabilities() {
        const preview = makeSolo("checkbox", "off");
        tryCompare(preview, "storyStatus", "ready", 8000);
        const caps = preview.flowCapabilities();
        compare(caps.events, ["toggled"], "solo Checkbox events changed shape");
        compare(caps.actions, ["toggle", "check", "uncheck"], "solo Checkbox actions changed shape");
        compare(caps.observables, ["checked", "enabled"], "solo Checkbox observables changed shape");
        verify(!caps.textDriver, "solo Checkbox invented a text driver");
        verify(preview.flowInvokeAction("check"), "solo check action did not run");
        compare(preview.flowRead("checked").value, true, "solo check did not apply");
        verify(preview.flowInvokeAction("uncheck"), "solo uncheck action did not run");
        compare(preview.flowRead("checked").value, false, "solo uncheck did not apply");
        preview.destroy();
    }

    function test_solo_preflight_lists_unavailable_without_mutating() {
        const preview = makeSolo("text-input", "text-filled");
        tryCompare(preview, "storyStatus", "ready", 8000);
        compare(preview.flowPreflight([
            { type: "reset" },
            { type: "action", name: "clear" },
            { type: "write", text: "Ada" },
            { type: "key", key: "Enter" },
            { type: "expect", observable: "text" },
            { type: "expectEvent", event: "accepted" }
        ]), [], "a fully supported solo flow did not preflight clean");
        const missing = preview.flowPreflight([
            { type: "action", name: "launch" },
            { type: "control", group: "nope", option: "x" },
            { type: "key", key: "Tab" },
            { type: "expect", observable: "opacity" }
        ]);
        compare(missing.length, 4, "preflight did not list every unavailable solo capability");
        compare(preview.flowRead("text").value, "Plain text", "preflight mutated the unit");
        compare(eventSpy.count, 0, "preflight recorded events");
        preview.destroy();
    }

    function test_solo_write_key_read_through_real_methods() {
        const preview = makeSolo("text-input", "text-filled");
        tryCompare(preview, "storyStatus", "ready", 8000);
        verify(preview.flowWrite("Ada Lovelace"), "solo write did not run");
        compare(preview.flowRead("text").value, "Ada Lovelace", "solo write did not land");
        eventSpy.clear();
        verify(preview.flowPressKey("Enter"), "solo Enter did not run");
        // Enter runs the real accept(): exactly one accepted intent with a
        // component origin, no duplicate synthetic component event.
        compare(eventSpy.count, 1, "Enter did not record exactly one event");
        const record = eventSpy.signalArguments[0][0];
        compare(record.kind, "intent", "Enter did not record the unit intent");
        compare(record.name, "accepted", "Enter recorded the wrong intent");
        compare(record.origin, "component", "ordinary unit intent missed its component origin");
        compare(preview.flowRead("text").value, "Ada Lovelace", "Enter clobbered the text");
        preview.destroy();
    }

    function test_solo_emit_action_control_reset_and_failures() {
        const preview = makeSolo("text-input", "text-filled");
        tryCompare(preview, "storyStatus", "ready", 8000);
        const injected = preview.flowEmit("accepted", { text: "Ada" });
        verify(injected !== null, "solo injection of a declared event failed");
        compare(injected.origin, "injected", "injected solo event missed its origin");
        compare(preview.flowRead("text").value, "Plain text", "solo injection mutated the unit");

        verify(preview.flowInvokeAction("clear"), "solo clear action did not run");
        compare(preview.flowRead("text").value, "", "solo clear did not run");
        const invoked = lastRecord();
        compare(invoked.kind, "action", "named action recorded the wrong kind");
        compare(invoked.origin, "component", "named action missed its component origin");

        // Canonical flow names map onto declared control labels: the strip
        // declares `readOnly`, the flow says `readonly`.
        verify(preview.flowApplyControl("readonly", "on"), "canonical control did not run");
        compare(preview.flowRead("readonly").value, true, "canonical control did not apply");
        verify(preview.flowApplyControl("readonly", "off"), "canonical control did not restore");

        verify(preview.flowEmit("bogus") === null, "undeclared solo event was injected");
        verify(!preview.flowInvokeAction("launch"), "undeclared solo action ran");
        verify(!preview.flowApplyControl("nope", "x"), "undeclared solo control ran");
        verify(!preview.flowWrite("x".repeat(201)), "over-bound solo write ran");
        verify(!preview.flowPressKey("Tab"), "undeclared solo key ran");
        const bad = preview.flowRead("opacity");
        verify(!bad.ok, "undeclared solo observable read as ok");

        preview.resetGeneration++;
        tryCompare(preview, "storyStatus", "ready", 8000);
        compare(preview._eventSequence, 0, "solo reset did not clear the event sequence");
        compare(preview.flowRead("text").value, "Plain text", "solo reset did not rebuild initial text");
        preview.destroy();
    }

    function test_composition_capabilities_layout_identity_only() {
        const preview = makeComposition(rolloutDoc());
        tryCompare(preview, "storyStatus", "ready", 8000);
        const trigger = preview.flowCapabilities("trigger");
        compare(trigger.type, "text-field", "trigger capability missed its type");
        compare(trigger.events, ["accepted", "changed"], "trigger events drifted from the descriptor");
        compare(trigger.actions, ["clear", "focus"], "trigger actions drifted from the descriptor");
        verify(trigger.textDriver, "trigger lost its text driver");
        compare(trigger.keys, ["Enter", "Escape"], "trigger keys changed shape");

        const panel = preview.flowCapabilities("panel");
        compare(panel.events, ["opened", "closed"], "panel events drifted from the descriptor");
        compare(panel.actions, ["open", "close", "toggle"], "panel actions drifted from the descriptor");
        compare(panel.observables, ["open", "side", "contentScale"], "panel observables changed shape");
        compare(panel.checkpoints, ["rollout.shell-revealed"], "panel checkpoints changed shape");

        const demo = preview.flowCapabilities("demo");
        compare(demo.type, "column", "layout capability missed its type");
        compare(demo.events, [], "layout invented events");
        compare(demo.actions, [], "layout invented actions");
        compare(demo.controls, [], "layout invented controls");
        compare(demo.observables, [], "layout invented observables");
        verify(!demo.textDriver, "layout invented a text driver");
        preview.destroy();
    }

    function test_composition_checkpoint_pauses_stays_stable_and_continues() {
        const preview = makeComposition(rolloutDoc());
        tryCompare(preview, "storyStatus", "ready", 8000);
        const panel = preview._registry["panel"].item;

        let armed = preview.flowArmCheckpoint({ name: "rollout.shell-revealed" });
        verify(armed.ok, "checkpoint arm failed: " + (armed.error || ""));
        verify(preview.flowInvokeAction("panel", "open"), "open action did not run");
        tryVerify(() => preview.flowCheckpointReached({ name: "rollout.shell-revealed" }), 3000,
            "armed rollout did not reach the checkpoint");
        compare(panel.rolloutOpen, true, "phase one did not open the rollout");
        verify(panel.containerHost.offsetScale <= 0.001, "rollout reveal did not complete before checkpoint");
        const heldScale = panel.rolloutPreviewContentScale;
        verify(heldScale < 1, "phase two content settle already ran while paused");
        wait(120);
        compare(panel.rolloutPreviewContentScale, heldScale,
            "paused checkpoint did not keep repeated observations stable");
        compare(preview.checkpointController.activeAnimation("rollout.shell-revealed"), panel.checkpointAnimation,
            "controller did not store the exact sequence instance");

        const continued = preview.flowContinueCheckpoint({ name: "rollout.shell-revealed" });
        verify(continued.ok, "checkpoint continue failed: " + (continued.error || ""));
        verify(panel.checkpointAnimation.running,
            "continue did not resume phase two on the same sequence instance");
        tryCompare(panel, "rolloutPreviewContentScale", 1, 3000);
        tryVerify(() => preview.flowIdle({ node: "panel" }), 3000, "rollout did not become idle after continue");
        verify(preview.checkpointController.activeAnimation("rollout.shell-revealed") === undefined,
            "controller retained the animation after continue");
        preview.destroy();
    }

    function test_composition_unarmed_open_does_not_pause() {
        const preview = makeComposition(rolloutDoc());
        tryCompare(preview, "storyStatus", "ready", 8000);
        const panel = preview._registry["panel"].item;

        verify(preview.flowInvokeAction("panel", "open"), "open action did not run");
        tryVerify(() => preview.flowIdle({ node: "panel" }), 3000, "unarmed rollout did not become idle");
        verify(!preview.flowCheckpointReached({ name: "rollout.shell-revealed" }),
            "unarmed rollout reached a checkpoint");
        compare(panel.rolloutPreviewContentScale, 1, "unarmed open altered preview content scale");
        preview.destroy();
    }

    function test_composition_preflight_lists_unavailable_without_mutating() {
        const preview = makeComposition(rolloutDoc());
        tryCompare(preview, "storyStatus", "ready", 8000);
        compare(preview.flowPreflight([
            { type: "reset" },
            { type: "emit", node: "trigger", event: "accepted" },
            { type: "action", node: "panel", name: "open" },
            { type: "control", node: "panel", group: "side", option: "left" },
            { type: "write", node: "trigger", text: "hi" },
            { type: "key", node: "trigger", key: "Enter" },
            { type: "expect", node: "panel", observable: "open" },
            { type: "expectEvent", node: "trigger", event: "accepted" }
        ]), [], "a fully supported composition flow did not preflight clean");
        const missing = preview.flowPreflight([
            { type: "emit", node: "demo", event: "opened" },
            { type: "action", node: "trigger", name: "launch" },
            { type: "expect", node: "panel", observable: "text" },
            { type: "write", node: "panel", text: "hi" },
            { type: "key", node: "panel", key: "Enter" },
            { type: "action", node: "ghost", name: "open" }
        ]);
        compare(missing.length, 6, "preflight did not list every unavailable node capability");
        verify(!preview._registry["panel"].item.rolloutOpen, "preflight mutated the rollout");
        compare(eventSpy.count, 0, "preflight recorded events");
        preview.destroy();
    }

    function test_composition_injected_event_routes_like_a_real_one() {
        const preview = makeComposition(rolloutDoc());
        tryCompare(preview, "storyStatus", "ready", 8000);
        eventSpy.clear();
        const injected = preview.flowEmit("trigger", "accepted", { text: "open sesame" });
        verify(injected !== null, "injection of a declared node event failed");
        compare(injected.origin, "injected", "injected node event missed its origin");
        compare(injected.nodeId, "trigger", "injected node event missed its node ID");
        verify(preview._registry["panel"].item.rolloutOpen,
            "injected accepted -> open link did not open the rollout");

        const all = records();
        const routes = all.filter(record => record.kind === "route");
        verify(routes.length > 0, "injected event recorded no route evidence");
        compare(routes[0].origin, "route", "route record missed its route origin");
        compare(routes[0].payload.from, { node: "trigger", event: "accepted" },
            "route record missed its source identity");
        compare(routes[0].payload.to, { node: "panel", action: "open" },
            "route record missed its target identity");

        // The same link through the real input path: write, then Enter,
        // which calls the real accept() and records a component origin.
        verify(preview.flowInvokeAction("panel", "close"), "setup close did not run");
        verify(preview.flowWrite("trigger", "open sesame"), "node write did not run");
        compare(preview.flowRead("trigger", "text").value, "open sesame", "node write did not land");
        eventSpy.clear();
        verify(preview.flowPressKey("trigger", "Enter"), "node Enter did not run");
        verify(preview._registry["panel"].item.rolloutOpen,
            "real accepted -> open link did not open the rollout");
        const intents = records().filter(record => record.kind === "intent" && record.name === "accepted");
        compare(intents.length, 1, "real Enter did not record exactly one accepted intent");
        compare(intents[0].origin, "component", "real intent missed its component origin");
        compare(preview.flowRead("panel", "open").value, true, "panel open observable misread");
        compare(preview.flowRead("panel", "side").value, "right", "panel side observable misread");
        preview.destroy();
    }

    function test_composition_action_control_reset_and_failures() {
        const preview = makeComposition(rolloutDoc());
        tryCompare(preview, "storyStatus", "ready", 8000);
        verify(preview.flowApplyControl("panel", "side", "left"), "panel side control did not run");
        compare(preview._registry["panel"].item.rolloutSide, "left", "panel side control leaked");
        compare(preview.flowRead("panel", "side").value, "left", "panel side observable misread");
        verify(preview.flowInvokeAction("panel", "open"), "panel open action did not run");
        compare(preview.flowRead("panel", "open").value, true, "panel open did not apply");
        verify(preview.flowInvokeAction("panel", "close"), "panel close action did not run");
        compare(preview.flowRead("panel", "open").value, false, "panel close did not apply");

        verify(preview.flowEmit("demo", "opened") === null, "layout accepted an injected event");
        verify(!preview.flowInvokeAction("demo", "open"), "layout accepted a named action");
        verify(!preview.flowApplyControl("demo", "open", "x"), "layout accepted a control");
        verify(!preview.flowWrite("confirm-step", "x"), "checkbox accepted a text write");
        verify(!preview.flowPressKey("confirm-step", "Enter"), "checkbox accepted a key press");
        verify(!preview.flowRead("panel", "text").ok, "panel read an undeclared observable");
        verify(!preview.flowRead("demo", "open").ok, "layout read an observable");

        preview.resetGeneration++;
        tryCompare(preview, "storyStatus", "ready", 8000);
        compare(preview._eventSequence, 0, "composition reset did not clear the event sequence");
        compare(preview._registry["panel"].item.rolloutSide, "right",
            "composition reset did not rebuild the initial side");
        verify(!preview._registry["panel"].item.rolloutOpen,
            "composition reset did not rebuild the closed rollout");
        preview.destroy();
    }
}
