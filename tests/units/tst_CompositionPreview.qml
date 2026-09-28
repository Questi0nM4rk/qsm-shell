import QtQuick
import QtTest

// Bounded contract checks for workbench/CompositionPreview.qml: exact
// viewport construction of layouts, all seven input leaves, and both
// containers, honest initial properties, independent per-node
// control/action routing with nodeId event records, safe named links with
// route records, truthful rebuild, and truthful failure for unknown types.
// Offscreen; no pixels, no visual constants.
TestCase {
    id: probe

    name: "CompositionPreview"
    width: 800
    height: 600
    visible: true
    when: windowShown

    SignalSpy { id: eventSpy; signalName: "eventRecorded" }

    function makePreview(doc) {
        const component = Qt.createComponent("../../workbench/CompositionPreview.qml");
        verify(component.status === Component.Ready,
            "CompositionPreview did not compile: " + component.errorString());
        const preview = component.createObject(probe, { composition: doc });
        verify(preview !== null, "could not construct CompositionPreview");
        eventSpy.target = preview;
        eventSpy.clear();
        return preview;
    }

    // The shipped workbench examples live in the sibling qsm-workbench
    // checkout, the same layout the Node composition tests assume. What
    // matters here is that every shipped document constructs in the real
    // runtime, not the file mechanics.
    function loadExample(name) {
        const request = new XMLHttpRequest();
        request.open("GET", Qt.resolvedUrl("../../../qsm-workbench/compositions/examples/"
            + name + ".json"), false);
        request.send();
        verify(request.responseText.length > 0, "could not read shipped example " + name);
        return JSON.parse(request.responseText);
    }

    function routeRecords() {
        const out = [];
        for (let i = 0; i < eventSpy.count; i++) {
            const record = eventSpy.signalArguments[i][0];
            if (record.kind === "route")
                out.push(record);
        }
        return out;
    }

    function matrixDoc() {
        return {
            version: 1, key: "probe-matrix", viewport: [640, 480],
            root: {
                id: "col", type: "column", props: { spacing: "sm", padding: "sm" },
                children: [
                    { id: "first", type: "text-field",
                        props: { size: "sm", state: "default", label: "First", text: "" } },
                    { id: "second", type: "text-field",
                        props: { size: "md", state: "filled", label: "Second", text: "Ada" } },
                    { id: "agree", type: "checkbox", props: { checked: true, label: "Agree" } },
                    { id: "row", type: "row", props: { spacing: "xs", padding: "none" },
                        children: [
                            { id: "power", type: "switch", props: { checked: true, label: "Power" } },
                            { id: "output", type: "radio", props: { checked: false, label: "Output" } }
                        ] },
                    { id: "pile", type: "stack", props: { spacing: "none", padding: "none" },
                        children: [
                            { id: "level", type: "slider",
                                props: { value: 70, orientation: "horizontal", label: "Level" } },
                            { id: "mode", type: "segmented", props: { selected: 1, label: "Mode" } },
                            { id: "count", type: "spin-box", props: { value: 7, label: "Count" } }
                        ] }
                ]
            }
        };
    }

    function controlIndex(preview, nodeId, label) {
        const groups = preview.controls;
        for (let i = 0; i < groups.length; i++) {
            if (groups[i].nodeId === nodeId && groups[i].label === label)
                return i;
        }
        return -1;
    }

    function optionIndex(preview, group, label) {
        const options = preview.controls[group].options;
        for (let i = 0; i < options.length; i++) {
            if (options[i].label === label)
                return i;
        }
        return -1;
    }

    function actionIndex(preview, nodeId, label) {
        const list = preview.actions;
        for (let i = 0; i < list.length; i++) {
            if (list[i].nodeId === nodeId && list[i].label === label)
                return i;
        }
        return -1;
    }

    function treeNames(tree, out) {
        if (tree.name !== undefined)
            out.push(tree.name);
        const kids = tree.children || [];
        for (let i = 0; i < kids.length; i++)
            treeNames(kids[i], out);
    }

    function test_constructs_all_layouts_and_leaves_at_exact_viewport() {
        const preview = makePreview(matrixDoc());
        tryCompare(preview, "storyStatus", "ready", 8000);
        compare(preview.width, 640, "preview did not take the document viewport width");
        compare(preview.height, 480, "preview did not take the document viewport height");
        compare(preview.storyKey, "probe-matrix", "storyKey did not follow the document key");
        compare(preview.storyError, "", "ready document reported an error");

        const registry = preview._registry;
        for (const id of ["col", "first", "second", "agree", "row", "power", "output", "pile", "level", "mode", "count"])
            verify(registry[id] !== undefined, "node was not registered: " + id);

        compare(registry["second"].item.text, "Ada", "text-field text was not mapped honestly");
        compare(registry["second"].item.size, "md", "text-field size was not mapped honestly");
        compare(registry["agree"].item.checked, true, "checkbox initial state was not mapped honestly");
        compare(registry["power"].item.checked, true, "switch initial state was not mapped honestly");
        compare(registry["output"].item.checked, false, "radio initial state was not mapped honestly");
        compare(registry["level"].item.compositionValue, 0.7, "slider value was not mapped honestly");
        compare(registry["mode"].item.currentIndex, 1, "segmented selection was not mapped honestly");
        compare(registry["count"].item.value, 7, "spin-box value was not mapped honestly");
        preview.destroy();
    }

    function test_control_routes_to_exactly_one_instance_with_node_id() {
        const preview = makePreview(matrixDoc());
        tryCompare(preview, "storyStatus", "ready", 8000);

        const group = controlIndex(preview, "second", "size");
        verify(group >= 0, "second text-field has no flattened size group");
        const option = optionIndex(preview, group, "lg");
        verify(option >= 0, "size group has no lg option");
        verify(preview.applyControl(group, option), "applyControl rejected a valid index");

        compare(preview._registry["second"].item.size, "lg", "control did not reach its own node");
        compare(preview._registry["first"].item.size, "sm", "control leaked into a sibling node");
        compare(eventSpy.count, 1, "control did not record exactly one event");
        compare(eventSpy.signalArguments[0][0].nodeId, "second", "event record missed its nodeId");
        compare(eventSpy.signalArguments[0][0].kind, "control", "event record missed its kind");
        verify(!preview.applyControl(-1, 0), "negative group index was accepted");
        verify(!preview.applyControl(9999, 0), "out-of-range group index was accepted");
        preview.destroy();
    }

    function test_action_routes_to_exactly_one_instance_with_node_id() {
        const preview = makePreview(matrixDoc());
        tryCompare(preview, "storyStatus", "ready", 8000);

        const index = actionIndex(preview, "agree", "Toggle");
        verify(index >= 0, "agree checkbox has no flattened Toggle action");
        verify(preview.triggerAction(index), "triggerAction rejected a valid index");
        compare(preview._registry["agree"].item.checked, false, "action did not flip its own node");
        // Two records: the unit's own toggle intent plus the action
        // invocation, mirroring Preview.qml. Both carry the node ID.
        compare(eventSpy.count, 2, "action did not record intent plus invocation");
        compare(eventSpy.signalArguments[0][0].nodeId, "agree", "intent record missed its nodeId");
        compare(eventSpy.signalArguments[0][0].kind, "intent", "first record is not the unit intent");
        compare(eventSpy.signalArguments[1][0].nodeId, "agree", "action record missed its nodeId");
        compare(eventSpy.signalArguments[1][0].kind, "action", "second record is not the action");
        verify(!preview.triggerAction(9999), "out-of-range action index was accepted");
        preview.destroy();
    }

    function test_inspection_carries_node_identity() {
        const preview = makePreview(matrixDoc());
        tryCompare(preview, "storyStatus", "ready", 8000);
        const names = [];
        treeNames(preview.inspect(true).tree, names);
        for (const id of ["first", "second", "agree", "power", "level", "mode", "count"])
            verify(names.indexOf(id) >= 0, "inspection missed node identity: " + id);
        preview.destroy();
    }

    function test_reset_clears_events_and_rebuilds_current_only() {
        const preview = makePreview(matrixDoc());
        tryCompare(preview, "storyStatus", "ready", 8000);

        const group = controlIndex(preview, "second", "size");
        preview.applyControl(group, optionIndex(preview, group, "lg"));
        compare(eventSpy.count, 1, "setup control did not record");

        preview.resetGeneration++;
        tryCompare(preview, "storyStatus", "ready", 8000);
        compare(preview._eventSequence, 0, "reset did not clear the event sequence");
        compare(preview._registry["second"].item.size, "md", "reset did not rebuild initial state");
        preview.destroy();
    }

    function test_unsupported_container_fails_truthfully_then_recovers() {
        const bad = {
            version: 1, key: "probe-bad", viewport: [640, 480],
            root: { id: "form", type: "column", props: { spacing: "sm", padding: "none" },
                children: [
                    { id: "mystery", type: "dialog", props: {} }
                ] }
        };
        const preview = makePreview(bad);
        tryCompare(preview, "storyStatus", "failed", 8000);
        verify(preview.storyError.indexOf("mystery") >= 0, "failure did not name the node ID");
        verify(preview.storyError.indexOf("dialog") >= 0, "failure did not name the node type");

        preview.composition = matrixDoc();
        tryCompare(preview, "storyStatus", "ready", 8000);
        compare(preview.storyError, "", "recovered document still reports the old failure");
        compare(preview.storyKey, "probe-matrix", "recovered document is not current");
        preview.destroy();
    }

    function test_shipped_examples_construct_ready() {
        const expected = {
            "text-field-matrix": ["matrix", "row-sm", "sm-default", "lg-disabled"],
            "menu-form": ["form", "account-menu", "name-field", "newsletter-opt"],
            "shell-border-rollout": ["demo", "trigger", "panel", "confirm-step"]
        };
        for (const name in expected) {
            const preview = makePreview(loadExample(name));
            tryCompare(preview, "storyStatus", "ready", 8000);
            const registry = preview._registry;
            for (const id of expected[name])
                verify(registry[id] !== undefined, name + ": node was not registered: " + id);
            compare(preview.storyError, "", name + ": ready document reported an error");
            if (name === "text-field-matrix")
                verify(preview.contentExtentWidth > preview.width,
                    "matrix overflow was not exposed to the workbench scroller");
            preview.destroy();
        }
    }

    function test_menu_hosts_children_in_document_order() {
        const preview = makePreview(loadExample("menu-form"));
        tryCompare(preview, "storyStatus", "ready", 8000);

        const menu = preview._registry["account-menu"].item;
        verify(menu.menuOpen, "menu did not take its initial open state");
        const host = menu.containerHost;
        verify(host, "menu exposes no hosted Menu");
        verify(typeof host.step === "function" && typeof host.activateCurrent === "function",
            "menu host is not the real qsm-shell Menu");
        verify(host.visible, "open menu host is not visible");
        // Non-ListRow children are honest layout content: the real Menu
        // registry picks up no keyboard rows for them.
        compare(host._rows.length, 0, "non-ListRow children became fake keyboard rows");

        // Flattened controls follow document order across the menu.
        const groups = preview.controls;
        let firstField = -1, firstOpt = -1;
        for (let i = 0; i < groups.length; i++) {
            if (firstField < 0 && groups[i].nodeId === "name-field")
                firstField = i;
            if (firstOpt < 0 && groups[i].nodeId === "newsletter-opt")
                firstOpt = i;
        }
        verify(firstField >= 0 && firstOpt >= 0, "menu children expose no controls");
        verify(firstField < firstOpt, "menu children are out of document order");

        // Declared container actions are flattened and useful.
        const labels = preview.actions
            .filter(entry => entry.nodeId === "account-menu")
            .map(entry => entry.label);
        for (const label of ["Open", "Close", "Toggle"])
            verify(labels.indexOf(label) >= 0, "menu is missing flattened action: " + label);
        preview.destroy();
    }

    function test_link_accepted_closes_menu() {
        const preview = makePreview(loadExample("menu-form"));
        tryCompare(preview, "storyStatus", "ready", 8000);

        const field = preview._registry["name-field"].item;
        compare(field.text, "Ada", "menu-form fixture lost its initial text");
        verify(field.accept(), "TextField.accept did not fire on fixture text");
        verify(!preview._registry["account-menu"].item.menuOpen,
            "accepted -> close link did not close the menu");

        const routes = routeRecords();
        verify(routes.length > 0, "no route event was recorded");
        const hop = routes[0];
        compare(hop.nodeId, "name-field", "route record missed its source node");
        compare(hop.targetNodeId, "account-menu", "route record missed its target node");
        compare(hop.payload.from.event, "accepted", "route record missed its source event");
        compare(hop.payload.to.action, "close", "route record missed its target action");
        preview.destroy();
    }

    function test_link_routes_rollout_and_registers_with_shell_border() {
        const preview = makePreview(loadExample("shell-border-rollout"));
        tryCompare(preview, "storyStatus", "ready", 8000);

        const panel = preview._registry["panel"].item;
        verify(!panel.rolloutOpen, "rollout did not take its initial closed state");
        const border = panel.hostBorder;
        verify(border, "rollout exposes no ShellBorder host");
        compare(border.bulgeEntries.length, 0, "closed rollout registered with its border");

        const trigger = preview._registry["trigger"].item;
        trigger.text = "open sesame";
        verify(trigger.accept(), "trigger accept did not fire");
        verify(panel.rolloutOpen, "accepted -> open link did not open the rollout");
        tryVerify(() => border.bulgeEntries.length > 0, 3000,
            "open rollout registered no bulge with the real ShellBorder");

        const routes = routeRecords();
        verify(routes.length > 0, "no route event was recorded for the rollout");
        compare(routes[0].nodeId, "trigger", "rollout route missed its source node");
        compare(routes[0].targetNodeId, "panel", "rollout route missed its target node");

        preview._registry["confirm-step"].item.flip();
        verify(!panel.rolloutOpen, "toggled -> close link did not close the rollout");
        preview.destroy();
    }

    function test_parity_every_type_constructs_and_named_actions_run() {
        const preview = makePreview({
            version: 1, key: "probe-parity", viewport: [960, 640],
            root: { id: "col", type: "column", props: { spacing: "sm", padding: "none" },
                children: [
                    { id: "field", type: "text-field",
                        props: { size: "md", state: "default", label: "Field", text: "Ada" } },
                    { id: "box", type: "checkbox", props: { checked: false, label: "Box" } },
                    { id: "sw", type: "switch", props: { checked: false, label: "Sw" } },
                    { id: "rad", type: "radio", props: { checked: false, label: "Rad" } },
                    { id: "sli", type: "slider",
                        props: { value: 30, orientation: "horizontal", label: "Sli" } },
                    { id: "seg", type: "segmented", props: { selected: 0, label: "Seg" } },
                    { id: "spin", type: "spin-box", props: { value: 7, label: "Spin" } },
                    { id: "menu", type: "menu", props: { title: "M", open: false },
                        children: [
                            { id: "menu-field", type: "text-field", props: { label: "In", text: "" } }
                        ] },
                    { id: "panel", type: "shell-border-rollout", props: { side: "right", open: false },
                        children: [
                            { id: "panel-box", type: "checkbox", props: { checked: false, label: "P" } }
                        ] }
                ] },
            links: [
                { from: { node: "seg", event: "changed" }, to: { node: "panel", action: "open" } }
            ]
        });
        tryCompare(preview, "storyStatus", "ready", 8000);

        // A real component intent canonicalized to its descriptor event
        // routes exactly like a direct one.
        preview._registry["seg"].item.select(1);
        verify(preview._registry["panel"].item.rolloutOpen,
            "segmented selected -> changed -> open link did not open the rollout");

        const invocations = [
            ["field", "clear"], ["field", "focus"],
            ["box", "toggle"], ["box", "check"], ["box", "uncheck"],
            ["sw", "toggle"], ["rad", "select"],
            ["sli", "reset"], ["seg", "reset"],
            ["spin", "increment"], ["spin", "decrement"], ["spin", "reset"],
            ["menu", "open"], ["menu", "close"], ["menu", "toggle"],
            ["panel", "open"], ["panel", "close"], ["panel", "toggle"]
        ];
        for (const [nodeId, action] of invocations)
            verify(preview.invokeNodeAction(nodeId, action),
                "declared action not implemented: " + nodeId + "." + action);

        compare(preview._registry["field"].item.text, "", "text-field clear did not run");
        compare(preview._registry["box"].item.checked, false, "checkbox uncheck did not run");
        compare(preview._registry["rad"].item.checked, true, "radio select did not run");
        compare(preview._registry["sli"].item.compositionValue, 0.3, "slider reset did not restore");
        compare(preview._registry["seg"].item.currentIndex, 0, "segmented reset did not restore");
        verify(preview._registry["menu"].item.menuOpen, "menu toggle did not end open");
        verify(preview._registry["panel"].item.rolloutOpen, "rollout toggle did not end open");

        verify(!preview.invokeNodeAction("field", "launch"), "undeclared action was accepted");
        verify(!preview.invokeNodeAction("col", "open"), "layout accepted a named action");
        verify(!preview.invokeNodeAction("ghost", "open"), "unknown node accepted a named action");
        preview.destroy();
    }
}
