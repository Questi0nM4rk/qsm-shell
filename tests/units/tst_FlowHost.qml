import QtQuick
import QtTest

// Focused FlowHost contracts (workbench bead 1q6.3): the preview-owned host
// runs an already-validated flow against the real Preview bridge in test
// mode (no process exit), proving sequential execution, exact semantic
// equality, preflight-before-mutation, and clear deferred-step failure.
// Composition routing is proved through the Node runner's end-to-end flow;
// this case stays solo and fast. Offscreen; no pixels, no visual constants.
TestCase {
    id: probe

    name: "FlowHost"
    width: 800
    height: 600
    visible: true
    when: windowShown

    function storyConfig() {
        return { component: "text-input", variant: "text-filled", viewport: [800, 500] };
    }

    function makeHost(key, steps) {
        const component = Qt.createComponent("../../workbench/FlowHost.qml");
        verify(component.status === Component.Ready,
            "FlowHost did not compile: " + component.errorString());
        const host = component.createObject(probe, {
            flowData: { version: 1, key: key, target: { story: "text-input" }, steps: steps },
            storyConfig: probe.storyConfig(),
            compositionDoc: null,
            testMode: true
        });
        verify(host !== null, "could not construct FlowHost");
        return host;
    }

    function rolloutDoc() {
        return {
            version: 1, key: "probe-rollout", viewport: [960, 600],
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
                { from: { node: "trigger", event: "accepted" }, to: { node: "panel", action: "open" } }
            ]
        };
    }

    function makeCompositionHost(key, steps, maxPolls) {
        const component = Qt.createComponent("../../workbench/FlowHost.qml");
        verify(component.status === Component.Ready,
            "FlowHost did not compile: " + component.errorString());
        const host = component.createObject(probe, {
            flowData: { version: 1, key: key, target: { composition: "probe-rollout.json" }, steps: steps },
            storyConfig: null,
            compositionDoc: probe.rolloutDoc(),
            testMode: true,
            maxPolls: maxPolls || 200
        });
        verify(host !== null, "could not construct composition FlowHost");
        return host;
    }

    function makeCaptureCompositionHost(key, steps, artifacts) {
        const component = Qt.createComponent("../../workbench/FlowHost.qml");
        verify(component.status === Component.Ready,
            "FlowHost did not compile: " + component.errorString());
        const host = component.createObject(probe, {
            flowData: { version: 1, key: key, target: { composition: "probe-rollout.json" }, scale: 1.25, steps: steps },
            storyConfig: null,
            compositionDoc: probe.rolloutDoc(),
            captureArtifacts: artifacts,
            testMode: true
        });
        verify(host !== null, "could not construct capture FlowHost");
        return host;
    }

    function waitResult(host) {
        tryVerify(function() { return host.flowResult !== null; }, 10000,
            "flow did not finish: " + host.phase);
        return host.flowResult;
    }

    function test_solo_clear_write_accept_passes() {
        const host = makeHost("probe-clear-accept", [
            { type: "reset" },
            { type: "action", name: "clear" },
            { type: "write", text: "Ada Lovelace" },
            { type: "key", key: "Enter" },
            { type: "expect", observable: "text", equals: "Ada Lovelace" },
            { type: "expectEvent", event: "accepted", origin: "component" },
            { type: "awaitIdle" }
        ]);
        const result = waitResult(host);
        compare(result.status, "pass", "solo flow failed: " + result.error);
        compare(result.key, "probe-clear-accept", "result missed its flow key");
        compare(result.target, { story: "text-input" }, "result missed its target");
        compare(result.steps.length, 7, "result missed step evidence");
        verify(result.events.length > 0, "result missed host event evidence");
        compare(result.viewport, { width: 800, height: 500 }, "result missed its viewport");
        compare(result.physical, { width: 800, height: 500 }, "result missed physical dimensions");
        compare(result.artifacts, {}, "result invented artifacts");
        host.destroy();
    }

    function test_expect_failure_reports_expected_and_actual() {
        const host = makeHost("probe-mismatch", [
            { type: "reset" },
            { type: "write", text: "Ada Lovelace" },
            { type: "expect", observable: "text", equals: "Grace Hopper" }
        ]);
        const result = waitResult(host);
        compare(result.status, "fail", "mismatched expect passed");
        compare(result.steps.length, 3, "failure cut step evidence short");
        compare(result.steps[2].ok, false, "failing step read as ok");
        compare(result.steps[2].expected, "Grace Hopper", "failure missed its expected value");
        compare(result.steps[2].actual, "Ada Lovelace", "failure missed its actual value");
        host.destroy();
    }

    function test_preflight_runs_before_any_mutation() {
        const host = makeHost("probe-preflight", [
            { type: "action", name: "launch" },
            { type: "write", text: "mutating write" },
            { type: "expect", observable: "text", equals: "mutating write" }
        ]);
        const result = waitResult(host);
        compare(result.status, "fail", "unsupported action passed preflight");
        verify(String(result.error).indexOf("unavailable action 'launch'") >= 0,
            "preflight missed the capability: " + result.error);
        compare(result.steps.length, 0, "preflight mutated before failing");
        verify(result.capabilities !== undefined, "preflight failure missed capability evidence");
        host.destroy();
    }

    function test_capture_step_requires_runner_artifact_path() {
        const host = makeHost("probe-deferred", [
            { type: "reset" },
            { type: "capture", reason: "capture remains deferred", baseline: "tests/integration/baselines/x.png" },
            { type: "expect", observable: "text", equals: "Plain text" }
        ]);
        const result = waitResult(host);
        compare(result.status, "fail", "capture without runner artifact passed");
        verify(String(result.error).indexOf("runner did not provide") >= 0,
            "capture failure was not clear: " + result.error);
        compare(result.steps.length, 2, "capture failure missed prior step evidence");
        host.destroy();
    }

    function test_scaled_paused_captures_are_stable_and_do_not_continue_checkpoint() {
        const firstPath = "/tmp/qsm-flowhost-capture-first.png";
        const secondPath = "/tmp/qsm-flowhost-capture-second.png";
        const host = makeCaptureCompositionHost("probe-scaled-capture", [
            { type: "reset" },
            { type: "armCheckpoint", name: "rollout.shell-revealed" },
            { type: "emit", node: "trigger", event: "accepted" },
            { type: "awaitCheckpoint", name: "rollout.shell-revealed" },
            { type: "expect", node: "panel", observable: "contentScale", equals: 0.97 },
            { type: "capture", baseline: "tests/integration/baselines/shell-border-rollout.png", reason: "first stable paused frame" },
            { type: "capture", baseline: "tests/integration/baselines/shell-border-rollout.png", reason: "second stable paused frame" },
            { type: "expect", node: "panel", observable: "contentScale", equals: 0.97 },
            { type: "continueCheckpoint", name: "rollout.shell-revealed" },
            { type: "awaitIdle", node: "panel" }
        ], ({ "5": firstPath, "6": secondPath }));
        const result = waitResult(host);
        compare(result.status, "pass", "scaled capture flow failed: " + result.error);
        compare(result.viewport, { width: 960, height: 600 }, "logical viewport changed");
        compare(result.scale, 1.25, "scale was not reported");
        compare(result.physical, { width: 1200, height: 750 }, "physical dimensions were not exact");
        compare(result.steps[5].metadata.physicalWidth, 1200, "first capture metadata missed width");
        compare(result.steps[5].metadata.physicalHeight, 750, "first capture metadata missed height");
        compare(result.steps[5].metadata.target, "composition:probe-rollout.json", "target metadata changed");
        compare(result.steps[6].metadata.stepIndex, 6, "second capture metadata missed step index");
        compare(result.steps[7].actual, 0.97, "capture advanced the paused animation");
        host.destroy();
    }

    function test_checkpoint_flow_pauses_continues_and_idles() {
        const host = makeCompositionHost("probe-checkpoint", [
            { type: "reset" },
            { type: "armCheckpoint", name: "rollout.shell-revealed" },
            { type: "emit", node: "trigger", event: "accepted" },
            { type: "awaitCheckpoint", name: "rollout.shell-revealed" },
            { type: "expect", node: "panel", observable: "open", equals: true },
            { type: "expect", node: "panel", observable: "contentScale", equals: 0.97 },
            { type: "continueCheckpoint", name: "rollout.shell-revealed" },
            { type: "awaitIdle", node: "panel" },
            { type: "expectEvent", node: "trigger", event: "accepted", origin: "route", targetNode: "panel" }
        ]);
        const result = waitResult(host);
        compare(result.status, "pass", "checkpoint flow failed: " + result.error);
        compare(result.steps.length, 9, "checkpoint flow missed step evidence");
        host.destroy();
    }

    function test_await_checkpoint_times_out_within_bound() {
        const host = makeCompositionHost("probe-checkpoint-timeout", [
            { type: "reset" },
            { type: "awaitCheckpoint", name: "rollout.shell-revealed" }
        ], 2);
        const result = waitResult(host);
        compare(result.status, "fail", "unreached checkpoint wait passed");
        verify(String(result.error).indexOf("checkpoint wait timed out") >= 0,
            "timeout failure was not clear: " + result.error);
        host.destroy();
    }

    function test_preflight_rejects_undeclared_checkpoint_before_mutation() {
        const host = makeCompositionHost("probe-bad-checkpoint", [
            { type: "armCheckpoint", name: "rollout.unknown" },
            { type: "emit", node: "trigger", event: "accepted" }
        ]);
        const result = waitResult(host);
        compare(result.status, "fail", "undeclared checkpoint passed preflight");
        verify(String(result.error).indexOf("undeclared checkpoint 'rollout.unknown'") >= 0,
            "preflight did not name the undeclared checkpoint: " + result.error);
        compare(result.steps.length, 0, "preflight mutated before checkpoint rejection");
        host.destroy();
    }
}
