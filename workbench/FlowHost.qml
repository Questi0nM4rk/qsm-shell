import QtQuick

// Offscreen semantic flow host (workbench bead 1q6.3). Preview-owned: loads
// the real Preview (solo story) or CompositionPreview (composition document)
// at its exact logical viewport and executes an already-validated flow
    // document against the common flow* bridge. Sequential state machine only:
// truthful loading wait, full preflight before the first mutation, then
// reset/emit/control/action/write/key/expect/expectEvent/awaitIdle in order.
// Queued progression (Qt.callLater plus small bounded polling where loading
    // requires it), never document sleeps. Capture fails clearly
    // as not implemented in this bead; nothing is approximated. Exactly one
// machine-readable QSM_FLOW_RESULT record is printed, then the process exits.
Item {
    id: host

    // Data injected by the workbench flow runner through JSON serialization
    // only (no document-derived source, imports, or commands). Exactly one
    // of storyConfig / compositionDoc is set, matching flowData.target.
    property var flowData: null // __FLOW_DATA__
    property var storyConfig: null // __STORY_CONFIG__
    property var compositionDoc: null // __COMPOSITION_DOC__
    property var captureArtifacts: null // __CAPTURE_ARTIFACTS__
    property bool verbose: false // __VERBOSE__
    // Focused contract tests set testMode to observe flowResult/flowFinished
    // instead of quitting the process.
    property bool testMode: false
    property var flowResult: null
    signal flowFinished(var result)

    readonly property bool isSolo: host.flowData !== null && host.flowData !== undefined
        && host.flowData.target !== undefined && host.flowData.target !== null
        && host.flowData.target.story !== undefined
    readonly property var activePreview: host.isSolo ? soloHost : compHost
    readonly property var logicalViewport: host.isSolo
        ? (host.storyConfig ? host.storyConfig.viewport : null)
        : (host.compositionDoc ? host.compositionDoc.viewport : null)
    readonly property string flowTheme: host.flowData && host.flowData.theme !== undefined
        ? String(host.flowData.theme) : "deep-night"
    readonly property real renderScale: host.flowData && host.flowData.scale !== undefined
        ? Number(host.flowData.scale) : 1
    readonly property int logicalWidth: host.asArray(host.logicalViewport).length === 2
        ? Number(host.asArray(host.logicalViewport)[0]) || 800 : 800
    readonly property int logicalHeight: host.asArray(host.logicalViewport).length === 2
        ? Number(host.asArray(host.logicalViewport)[1]) || 600 : 600
    readonly property real physicalWidthRaw: host.logicalWidth * host.renderScale
    readonly property real physicalHeightRaw: host.logicalHeight * host.renderScale
    readonly property int physicalWidth: Math.round(host.physicalWidthRaw)
    readonly property int physicalHeight: Math.round(host.physicalHeightRaw)

    width: host.physicalWidth
    height: host.physicalHeight

    property var eventLog: []
    property var stepResults: []
    property int stepIndex: 0
    property string phase: "boot"
    property int pollCount: 0
    // Small bounded polling only where loading requires it: 50ms x 200.
    property int pollInterval: 50
    property int maxPolls: 200
    property var waitingStep: null

    function asArray(v): var {
        if (v === null || v === undefined)
            return [];
        if (Array.isArray(v))
            return v;
        if (typeof v.length === "number") {
            const out = [];
            for (let i = 0; i < v.length; i++)
                out.push(v[i]);
            return out;
        }
        return [];
    }

    // Exact semantic equality over bounded JSON values, not string display.
    // Length-indexed so QVariantList sequences compare like real arrays.
    function jsonEqual(a, b): bool {
        if (a === b)
            return true;
        if (typeof a !== typeof b)
            return false;
        if (a === null || b === null)
            return false;
        if (typeof a !== "object")
            return false;
        const aIsList = Array.isArray(a) || typeof a.length === "number";
        const bIsList = Array.isArray(b) || typeof b.length === "number";
        if (aIsList || bIsList) {
            if (!aIsList || !bIsList || a.length !== b.length)
                return false;
            for (let i = 0; i < a.length; i++) {
                if (!host.jsonEqual(a[i], b[i]))
                    return false;
            }
            return true;
        }
        const aKeys = Object.keys(a);
        const bKeys = Object.keys(b);
        if (aKeys.length !== bKeys.length)
            return false;
        for (let i = 0; i < aKeys.length; i++) {
            if (!Object.prototype.hasOwnProperty.call(b, aKeys[i]))
                return false;
            if (!host.jsonEqual(a[aKeys[i]], b[aKeys[i]]))
                return false;
        }
        return true;
    }

    function safeJson(value): string {
        try {
            return JSON.stringify(value);
        } catch (e) {
            return "<unserializable: " + e + ">";
        }
    }

    // expectEvent matching over the recorded host events. Ordinary steps
    // match by event name, origin, and source node. Route steps match the
    // source event/node and optional target node through the route payload.
    function eventMatches(record, step): bool {
        if (!record || typeof record !== "object")
            return false;
        const origin = step.origin !== undefined ? String(step.origin) : "component";
        if (origin === "route") {
            if (record.origin !== "route" && record.kind !== "route")
                return false;
            const payload = record.payload;
            const from = payload ? payload.from : null;
            if (!from)
                return false;
            if (String(from.event) !== String(step.event))
                return false;
            if (!host.isSolo && String(from.node) !== String(step.node))
                return false;
            if (step.targetNode !== undefined) {
                const to = payload ? payload.to : null;
                if (!to || String(to.node) !== String(step.targetNode))
                    return false;
            }
            return true;
        }
        if (String(record.origin) !== origin)
            return false;
        if (String(record.name) !== String(step.event))
            return false;
        if (!host.isSolo && String(record.nodeId) !== String(step.node))
            return false;
        return true;
    }

    function findEvent(step): var {
        const log = host.asArray(host.eventLog);
        for (let i = 0; i < log.length; i++) {
            if (host.eventMatches(log[i], step))
                return log[i];
        }
        return null;
    }

    function describeStep(step): string {
        if (!step || typeof step !== "object")
            return "<missing>";
        let label = String(step.type ?? "<missing>");
        if (step.node !== undefined)
            label += " " + String(step.node);
        if (step.name !== undefined)
            label += " " + String(step.name);
        else if (step.event !== undefined)
            label += " " + String(step.event);
        else if (step.observable !== undefined)
            label += " " + String(step.observable);
        return label;
    }

    function begin(): void {
        if (host.phase !== "boot")
            return;
        if (!host.flowData || typeof host.flowData !== "object") {
            host.finish(false, "no flow data: the runner must serialize flowData", [], null);
            return;
        }
        if (host.isSolo && (!host.storyConfig || typeof host.storyConfig !== "object")) {
            host.finish(false, "no story configuration for story target", [], null);
            return;
        }
        if (!host.isSolo && (!host.compositionDoc || typeof host.compositionDoc !== "object")) {
            host.finish(false, "no composition document for composition target", [], null);
            return;
        }
        if (!isFinite(host.renderScale) || Math.abs(host.physicalWidthRaw - host.physicalWidth) > 0.000001
            || Math.abs(host.physicalHeightRaw - host.physicalHeight) > 0.000001) {
            host.finish(false, "flow scale/viewport does not produce integer physical dimensions: "
                + host.logicalWidth + "x" + host.logicalHeight + " at scale " + host.renderScale,
                [], null);
            return;
        }
        host.phase = "waiting-ready";
        host.pollCount = 0;
        poller.start();
    }

    function poll(): void {
        if (host.phase !== "waiting-ready" && host.phase !== "waiting-reset")
            return;
        const preview = host.activePreview;
        const status = preview ? String(preview.storyStatus) : "failed";
        if (status === "ready") {
            if (host.phase === "waiting-ready")
                host.preflight();
            else
                host.afterReset();
            return;
        }
        if (status === "failed") {
            const detail = preview && preview.storyError ? String(preview.storyError) : "target failed to load";
            host.finish(false, "target did not become ready: " + detail, [], null);
            return;
        }
        host.pollCount++;
        if (host.pollCount >= host.maxPolls) {
            host.finish(false, "target did not become ready within "
                + (host.pollInterval * host.maxPolls) + "ms (status: " + status + ")", [], null);
            return;
        }
        poller.start();
    }

    // Every supported step is preflighted before the first mutation.
    function preflight(): void {
        const steps = host.asArray(host.flowData.steps);
        const missing = host.activePreview.flowPreflight(steps);
        const list = host.asArray(missing);
        if (list.length > 0) {
            host.finish(false, "preflight found unavailable capabilities: " + list.join("; "),
                [], host.snapshotCapabilities());
            return;
        }
        host.phase = "running";
        host.stepIndex = 0;
        host.stepResults = [];
        Qt.callLater(function() { host.runNext(); });
    }

    function snapshotCapabilities(): var {
        if (host.isSolo)
            return soloHost.flowCapabilities();
        const seen = {};
        const out = {};
        const steps = host.asArray(host.flowData ? host.flowData.steps : null);
        for (let i = 0; i < steps.length; i++) {
            const node = steps[i] ? steps[i].node : undefined;
            if (node === undefined || seen[String(node)])
                continue;
            seen[String(node)] = true;
            out[String(node)] = compHost.flowCapabilities(String(node));
        }
        return out;
    }

    function runNext(): void {
        if (host.phase !== "running")
            return;
        const steps = host.asArray(host.flowData.steps);
        if (host.stepIndex >= steps.length) {
            host.finish(true, null, null, null);
            return;
        }
        const step = steps[host.stepIndex];
        const type = step ? String(step.type ?? "") : "";
        if (type === "awaitCheckpoint") {
            host.startStepWait(step, "checkpoint");
            return;
        }
        if (type === "awaitIdle") {
            host.startStepWait(step, "idle");
            return;
        }
        if (type === "capture") {
            host.captureStep(step);
            return;
        }
        if (type === "reset") {
            // Reset rides the existing generation/rebuild route and waits
            // for the current tree to become ready again.
            host.phase = "waiting-reset";
            host.activePreview.resetGeneration++;
            Qt.callLater(function() {
                host.pollCount = 0;
                poller.start();
            });
            return;
        }
        const result = host.execute(step);
        host.stepResults.push(Object.assign({ index: host.stepIndex, type: type }, result));
        console.log("QSM_FLOW_STEP " + host.stepIndex + " " + host.describeStep(step)
            + " " + (result.ok ? "ok" : "FAIL"));
        if (!result.ok) {
            host.finish(false, "step " + host.stepIndex + " (" + type + ") failed: "
                + (result.error || "unknown failure"), null, null);
            return;
        }
        host.stepIndex++;
        Qt.callLater(function() { host.runNext(); });
    }

    function startStepWait(step, kind: string): void {
        if (host.verbose)
            console.log("QSM_FLOW_VERBOSE startStepWait " + kind + " step " + host.stepIndex + " " + host.describeStep(step));
        host.phase = "waiting-" + kind;
        host.waitingStep = step;
        host.pollCount = 0;
        stepPoller.start();
    }

    function pollStepWait(): void {
        if (host.phase !== "waiting-checkpoint" && host.phase !== "waiting-idle")
            return;
        const kind = host.phase === "waiting-checkpoint" ? "checkpoint" : "idle";
        const ready = kind === "checkpoint"
            ? host.activePreview.flowCheckpointReached(host.waitingStep)
            : host.activePreview.flowIdle(host.waitingStep);
        if (ready) {
            host.phase = "running";
            host.stepResults.push({ index: host.stepIndex, type: String(host.waitingStep.type ?? ""), ok: true });
            console.log("QSM_FLOW_STEP " + host.stepIndex + " " + host.describeStep(host.waitingStep) + " ok");
            host.stepIndex++;
            Qt.callLater(function() { host.runNext(); });
            return;
        }
        host.pollCount++;
        if (host.pollCount >= host.maxPolls) {
            host.phase = "running";
            host.stepResults.push({ index: host.stepIndex, type: String(host.waitingStep.type ?? ""), ok: false,
                error: kind + " wait timed out" });
            host.finish(false, "step " + host.stepIndex + " (" + String(host.waitingStep.type ?? "")
                + ") failed: " + kind + " wait timed out", null, null);
            return;
        }
        stepPoller.start();
    }

    function afterReset(): void {
        host.phase = "running";
        const steps = host.asArray(host.flowData.steps);
        const step = steps[host.stepIndex];
        host.stepResults.push({ index: host.stepIndex, type: "reset", ok: true });
        console.log("QSM_FLOW_STEP " + host.stepIndex + " reset ok");
        host.stepIndex++;
        Qt.callLater(function() { host.runNext(); });
    }

    function execute(step): var {
        const type = step ? String(step.type ?? "") : "";
        const payload = step && step.payload !== undefined && step.payload !== null ? step.payload : {};
        if (host.isSolo)
            return host.executeSolo(soloHost, type, step, payload);
        return host.executeOnNode(compHost, type, step, payload);
    }

    function capturePathForStep(index: int): string {
        if (!host.captureArtifacts || typeof host.captureArtifacts !== "object")
            return "";
        const value = host.captureArtifacts[String(index)];
        return value !== undefined && value !== null ? String(value) : "";
    }

    function targetObject(): string {
        if (host.isSolo)
            return "story:" + String(host.flowData.target.story ?? "");
        return "composition:" + String(host.flowData.target.composition ?? "");
    }

    function captureMetadata(index: int): var {
        const parts = String(Qt.version).split(".");
        return {
            flowKey: host.flowData ? String(host.flowData.key ?? "") : "",
            stepIndex: index,
            target: host.targetObject(),
            logicalWidth: host.logicalWidth,
            logicalHeight: host.logicalHeight,
            renderScale: host.renderScale,
            physicalWidth: host.physicalWidth,
            physicalHeight: host.physicalHeight,
            theme: host.flowTheme,
            qtMajor: Number(parts[0]) || 0,
            qtMinor: Number(parts[1]) || 0,
            renderer: "opengl"
        };
    }

    function captureStep(step): void {
        if (host.verbose)
            console.log("QSM_FLOW_VERBOSE captureStep " + host.stepIndex + " " + host.describeStep(step));
        const path = host.capturePathForStep(host.stepIndex);
        if (path === "") {
            host.stepResults.push({ index: host.stepIndex, type: "capture", ok: false,
                error: "runner did not provide a private capture artifact path" });
            host.finish(false, "step " + host.stepIndex + " (capture) failed: runner did not provide a private capture artifact path", null, null);
            return;
        }
        host.phase = "capturing";
        const index = host.stepIndex;
        Qt.callLater(function() {
            Qt.callLater(function() {
                host.grabToImage(function(result) {
                    const metadata = host.captureMetadata(index);
                    if (!result.saveToFile(path)) {
                        host.phase = "running";
                        host.stepResults.push({ index: index, type: "capture", ok: false,
                            error: "could not save capture to runner artifact", actualPath: path, metadata: metadata });
                        host.finish(false, "step " + index + " (capture) failed: could not save capture to runner artifact", null, null);
                        return;
                    }
                    host.phase = "running";
                    host.stepResults.push({ index: index, type: "capture", ok: true,
                        actualPath: path, metadata: metadata, baseline: String(step.baseline ?? "") });
                    console.log("QSM_FLOW_STEP " + index + " " + host.describeStep(step) + " ok");
                    host.stepIndex++;
                    Qt.callLater(function() { host.runNext(); });
                }, Qt.size(host.physicalWidth, host.physicalHeight));
            });
        });
    }

    function executeSolo(preview, type, step, payload): var {
        if (host.verbose)
            console.log("QSM_FLOW_VERBOSE executeSolo step " + host.stepIndex + " type=" + type + " " + host.describeStep(step));
        switch (type) {
        case "emit": {
            const record = preview.flowEmit(String(step.event ?? ""), payload);
            if (record === null || record === undefined)
                return { ok: false, error: "unavailable event '" + String(step.event ?? "") + "'" };
            return { ok: true };
        }
        case "action":
            if (!preview.flowInvokeAction(String(step.name ?? "")))
                return { ok: false, error: "unavailable action '" + String(step.name ?? "") + "'" };
            return { ok: true };
        case "control":
            if (!preview.flowApplyControl(String(step.group ?? ""), String(step.option ?? "")))
                return { ok: false, error: "unavailable control '" + String(step.group ?? "")
                    + "' option '" + String(step.option ?? "") + "'" };
            return { ok: true };
        case "write":
            if (!preview.flowWrite(String(step.text ?? "")))
                return { ok: false, error: "text driver rejected the write" };
            return { ok: true };
        case "key":
            if (!preview.flowPressKey(String(step.key ?? "")))
                return { ok: false, error: "unavailable key '" + String(step.key ?? "") + "'" };
            return { ok: true };
        case "expect": {
            const read = preview.flowRead(String(step.observable ?? ""));
            if (!read || read.ok !== true)
                return { ok: false, error: read && read.error ? String(read.error) : "unavailable observable" };
            if (!host.jsonEqual(read.value, step.equals)) {
                return { ok: false, error: "expected " + host.safeJson(step.equals)
                    + " but observed " + host.safeJson(read.value),
                expected: step.equals, actual: read.value };
            }
            return { ok: true, actual: read.value };
        }
        case "expectEvent": {
            const found = host.findEvent(step);
            if (!found) {
                return { ok: false, error: "no recorded event '" + String(step.event ?? "")
                    + "' with origin '" + (step.origin !== undefined ? String(step.origin) : "component")
                    + "' among " + host.asArray(host.eventLog).length + " records" };
            }
            return { ok: true, matched: found.sequence };
        }
        case "armCheckpoint": {
            const armed = preview.flowArmCheckpoint(step);
            if (!armed || armed.ok !== true)
                return { ok: false, error: armed && armed.error ? String(armed.error) : "checkpoint arm failed" };
            return { ok: true };
        }
        case "continueCheckpoint": {
            const continued = preview.flowContinueCheckpoint(step);
            if (!continued || continued.ok !== true)
                return { ok: false, error: continued && continued.error ? String(continued.error) : "checkpoint continue failed" };
            return { ok: true };
        }
        case "awaitIdle":
            if (String(preview.storyStatus) !== "ready")
                return { ok: false, error: "host is not idle (status: " + String(preview.storyStatus) + ")" };
            return { ok: true };
        default:
            return { ok: false, error: type + " is not implemented in this bead" };
        }
    }

    function executeOnNode(preview, type, step, payload): var {
        if (host.verbose)
            console.log("QSM_FLOW_VERBOSE executeOnNode step " + host.stepIndex + " type=" + type + " " + host.describeStep(step));
        const node = String(step.node ?? "");
        switch (type) {
        case "emit": {
            const record = preview.flowEmit(node, String(step.event ?? ""), payload);
            if (record === null || record === undefined)
                return { ok: false, error: "node '" + node + "' declares no event '"
                    + String(step.event ?? "") + "'" };
            return { ok: true };
        }
        case "action":
            if (!preview.flowInvokeAction(node, String(step.name ?? "")))
                return { ok: false, error: "node '" + node + "' declares no action '"
                    + String(step.name ?? "") + "'" };
            return { ok: true };
        case "control":
            if (!preview.flowApplyControl(node, String(step.group ?? ""), String(step.option ?? "")))
                return { ok: false, error: "node '" + node + "' has no control '"
                    + String(step.group ?? "") + "' option '" + String(step.option ?? "") + "'" };
            return { ok: true };
        case "write":
            if (!preview.flowWrite(node, String(step.text ?? "")))
                return { ok: false, error: "node '" + node + "' rejected the write" };
            return { ok: true };
        case "key":
            if (!preview.flowPressKey(node, String(step.key ?? "")))
                return { ok: false, error: "node '" + node + "' supports no key '"
                    + String(step.key ?? "") + "'" };
            return { ok: true };
        case "expect": {
            const read = preview.flowRead(node, String(step.observable ?? ""));
            if (!read || read.ok !== true)
                return { ok: false, error: read && read.error ? String(read.error) : "unavailable observable" };
            if (!host.jsonEqual(read.value, step.equals)) {
                return { ok: false, error: "expected " + host.safeJson(step.equals)
                    + " but observed " + host.safeJson(read.value),
                expected: step.equals, actual: read.value };
            }
            return { ok: true, actual: read.value };
        }
        case "expectEvent": {
            const found = host.findEvent(step);
            if (!found) {
                return { ok: false, error: "no recorded event '" + String(step.event ?? "")
                    + "' from node '" + node + "' with origin '"
                    + (step.origin !== undefined ? String(step.origin) : "component")
                    + "' among " + host.asArray(host.eventLog).length + " records" };
            }
            return { ok: true, matched: found.sequence };
        }
        case "armCheckpoint": {
            const armed = preview.flowArmCheckpoint(step);
            if (!armed || armed.ok !== true)
                return { ok: false, error: armed && armed.error ? String(armed.error) : "checkpoint arm failed" };
            return { ok: true };
        }
        case "continueCheckpoint": {
            const continued = preview.flowContinueCheckpoint(step);
            if (!continued || continued.ok !== true)
                return { ok: false, error: continued && continued.error ? String(continued.error) : "checkpoint continue failed" };
            return { ok: true };
        }
        case "awaitIdle":
            if (String(preview.storyStatus) !== "ready")
                return { ok: false, error: "host is not idle (status: " + String(preview.storyStatus) + ")" };
            return { ok: true };
        default:
            return { ok: false, error: type + " is not implemented in this bead" };
        }
    }

    function finish(ok, error, extraSteps, capabilities): void {
        if (host.phase === "done")
            return;
        host.phase = "done";
        const steps = extraSteps !== null && extraSteps !== undefined ? extraSteps : host.stepResults;
        const viewport = host.asArray(host.logicalViewport);
        let events = [];
        try {
            events = JSON.parse(JSON.stringify(host.eventLog));
        } catch (e) {
            events = [{ sequence: 0, kind: "note",
                name: "event evidence was not JSON-safe: " + e }];
        }
        const result = {
            status: ok ? "pass" : "fail",
            key: host.flowData ? String(host.flowData.key ?? "") : "",
            target: host.isSolo
                ? { story: host.flowData && host.flowData.target ? String(host.flowData.target.story ?? "") : "" }
                : { composition: host.flowData && host.flowData.target
                    ? String(host.flowData.target.composition ?? "") : "" },
            steps: steps,
            events: events,
            error: error !== null && error !== undefined ? String(error) : null,
            viewport: { width: host.logicalWidth, height: host.logicalHeight },
            scale: host.renderScale,
            physical: { width: host.physicalWidth, height: host.physicalHeight },
            theme: host.flowTheme,
            capabilities: capabilities !== null && capabilities !== undefined ? capabilities : undefined,
            artifacts: {}
        };
        host.flowResult = result;
        console.log("QSM_FLOW_RESULT " + JSON.stringify(result));
        host.flowFinished(result);
        if (!host.testMode)
            Qt.exit(ok ? 0 : 1);
    }

    Timer {
        id: poller
        interval: host.pollInterval
        repeat: false
        onTriggered: host.poll()
    }
    Timer {
        id: stepPoller
        interval: host.pollInterval
        repeat: false
        onTriggered: host.pollStepWait()
    }

    IntegrationController { id: checkpointController }

    Connections {
        target: soloHost
        function onEventRecorded(record) { host.eventLog.push(record); }
    }

    Connections {
        target: compHost
        function onEventRecorded(record) { host.eventLog.push(record); }
    }

    StoryHost {
        id: soloHost
        width: host.logicalWidth
        height: host.logicalHeight
        scale: host.renderScale
        transformOrigin: Item.TopLeft
        visible: host.isSolo
        component: host.isSolo && host.storyConfig ? String(host.storyConfig.component ?? "") : ""
        variant: host.isSolo && host.storyConfig ? String(host.storyConfig.variant ?? "") : ""
        storyKey: host.flowData ? String(host.flowData.key ?? "") : ""
        viewportWidth: host.logicalWidth
        viewportHeight: host.logicalHeight
        theme: host.flowTheme
        integrationController: checkpointController
    }

    CompositionPreview {
        id: compHost
        width: host.logicalWidth
        height: host.logicalHeight
        scale: host.renderScale
        transformOrigin: Item.TopLeft
        visible: !host.isSolo
        composition: !host.isSolo ? host.compositionDoc : null
        theme: host.flowTheme
        integrationController: checkpointController
    }

    Component.onCompleted: Qt.callLater(function() { host.begin(); });
}
