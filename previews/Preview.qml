pragma ComponentBehavior: Bound
import QtQuick
// Namespaced: an unqualified import shadows qs.QsmShell.Components' own
// TextField and Menu, which several scenarios below use unqualified.
import QtQuick.Controls as Controls
import QtQuick.Layouts
import qs.QsmShell.Components
import qs.QsmShell.Style
import "inspect.js" as Inspect

Rectangle {
    id: root
    property string component: "capsule"
    property string variant: "resting"
    // PascalCase basename under previews/units/. Empty means not migrated
    // yet -- the inline children below keep working unchanged.
    property string unit: ""
    // Sibling scenario keys of this scene's group (same `unit`, or the same
    // `component` for a legacy scene not yet migrated), in scenarios.json
    // order. Empty means no scene switcher -- CapturePreview never sets this,
    // so a capture always renders exactly the one scene it was asked for.
    property var scenes: []
    property int viewportWidth: 1600
    property int viewportHeight: 900
    property var screenContext: ({ id: "preview-1", width: viewportWidth, height: viewportHeight, scale: 1, focused: true, safeInsets: Qt.rect(16, 16, 16, 16) })
    property string theme: "deep-night"
    property var backend: null
    // Buttons for a unit's declared `controls` only ever exist on the live
    // path -- a capture is a picture of the component and must not grow them.
    property bool interactive: false
    // The Timer's load-time dump only fires under `interactive` on the live
    // path; the capture host sets this instead so the same dump fires there.
    property bool captureDump: false
    width: viewportWidth
    height: viewportHeight
    color: "#1c0e27"
    // Theme fixtures: one backend object per named theme. A caller-supplied
    // `backend` always wins over the theme map. `deep-night`'s object is the
    // CONSUMER-shaped one, loaded from theme.json rather than declared here,
    // so the preview windows and unit tests run under the same shape a real
    // desktop's bootstrap would install (extra `sizes` presets included).
    property var _deepNightBackend: ({})
    function _loadTheme(): void {
        const request = new XMLHttpRequest();
        request.open("GET", Qt.resolvedUrl("theme.json"), false);
        request.send();
        if (request.responseText.length === 0) {
            console.warn("Preview: could not read previews/theme.json -- run through "
                + "scripts/preview-qml.mjs or scripts/capture-qml.mjs, which set "
                + "QML_XHR_ALLOW_FILE_READ");
            return;
        }
        root._deepNightBackend = JSON.parse(request.responseText);
    }
    property var _themeFixtures: ({ "deep-night": root._deepNightBackend })
    property var activeBackend: backend !== null && backend !== undefined ? backend : (_themeFixtures[theme] || null)
    // Install the active backend on the Style singleton so every component
    // resolves tokens from the scenario theme.
    Component.onCompleted: {
        root._loadTheme();
        Style.backend = root.activeBackend;
        if (root.interactive || root.captureDump)
            settleDump.start();
    }
    onActiveBackendChanged: Style.backend = root.activeBackend
    // A loaded unit's type is only known at runtime, so `controls` cannot be
    // typed on `Loader.item` -- read it through an untyped parameter instead
    // of a direct `.controls` access qmllint cannot resolve.
    function unitControls(item) {
        return (item && Array.isArray(item.controls)) ? item.controls : [];
    }
    // The audit skills need geometry, not a screenshot. One JSON line on
    // stderr per dump; scripts/preview-qml.mjs turns the last one into a
    // file. Dumped on load, after every control-strip click and on F12.
    function inspect(visibleOnly: bool): var {
        return {
            "scene": `${root.component}/${root.variant}`,
            "width": root.width,
            "height": root.height,
            "tree": Inspect.describe(root, visibleOnly)
        };
    }

    function dumpTree(): void {
        console.info("QSM_INSPECT " + JSON.stringify(root.inspect(true)));
    }

    Shortcut {
        sequence: "F12"
        onActivated: root.dumpTree()
    }

    // A dump has to describe a SETTLED scene, and one frame after load is not
    // that: a unit gets its `variant` from `onLoaded`, after it completed, so
    // the host's write starts a Behavior and the frame after load lands in the
    // middle of it. Both slider scenarios reported a thumb a third of the way
    // to where it belonged this way. `Motion.fast` is the library's ceiling
    // for a control changing shape, and `Qt.callLater` adds the pass after its
    // last frame; every dump goes through here, so a strip click reads the
    // state it just asked for rather than the transition into it.
    Timer {
        id: settleDump
        interval: Motion.fast
        onTriggered: Qt.callLater(root.dumpTree)
    }
    // A unit's `controls` reach every property-only state that isn't
    // reachable by hovering, pressing or focusing the live window --
    // `disabled`, `selected`, `indeterminate`, and the like. One more group,
    // "scene", switches the whole scenario when `root.scenes` is non-empty;
    // it sets properties on the PREVIEW HOST, never on the loaded unit.
    // The whole strip-plus-scene column sits in a Flickable so a pane too
    // short for both scrolls, strip first.
    Flickable {
        id: flick
        anchors.fill: parent
        clip: true
        contentWidth: width
        contentHeight: contentColumn.implicitHeight
        // Only claim the vertical drag once there is somewhere to scroll --
        // unconditionally interactive steals the vertical Slider scenario's
        // own drag.
        interactive: contentHeight > height
        boundsBehavior: Flickable.StopAtBounds
        Controls.ScrollBar.vertical: Controls.ScrollBar {}

        ColumnLayout {
            id: contentColumn
            width: flick.width
            spacing: Style.space4

            ColumnLayout {
                id: controlStrip
                spacing: Style.space2
                // Off the window edge: buttons flush with the pane border
                // read as part of the compositor chrome, not the scene.
                Layout.leftMargin: Style.space6 + Style.space4
                Layout.topMargin: Style.space6 + Style.space4
                Layout.rightMargin: Style.space6 + Style.space4

                // Bumped on every apply() so `isSelected`'s dynamic
                // `item[key]` reads pick up a dependency even where the
                // meta-object system would not otherwise notice a
                // bracket-notation read.
                property int revision: 0

                readonly property var groups: {
                    const list = [];
                    if (root.scenes.length > 0)
                        list.push({
                            label: "scene",
                            target: "root",
                            options: root.scenes.map(scene => ({ label: scene.key, set: { component: scene.component, variant: scene.variant } }))
                        });
                    for (const group of root.unitControls(unitLoader.item))
                        list.push({ label: group.label, target: "unit", options: group.options });
                    return list;
                }
                visible: root.interactive && controlStrip.groups.length > 0

                function targetItem(target) {
                    return target === "root" ? root : unitLoader.item;
                }

                // Colour value types never compare `===` even when
                // identical -- each property read returns a fresh wrapper.
                // Qt.colorEqual compares the underlying colour instead.
                function sameValue(a, b) {
                    if (a === b)
                        return true;
                    return typeof a === "object" && a !== null && typeof b === "object" && b !== null && Qt.colorEqual(a, b);
                }

                function isSelected(target, option) {
                    void controlStrip.revision;
                    if (option.set === undefined)
                        return false;
                    const item = controlStrip.targetItem(target);
                    if (!item)
                        return false;
                    for (const key in option.set) {
                        if (!controlStrip.sameValue(item[key], option.set[key]))
                            return false;
                    }
                    return true;
                }

                function apply(target, option) {
                    const item = controlStrip.targetItem(target);
                    if (option.call !== undefined)
                        item[option.call]();
                    else
                        for (const key in option.set)
                            item[key] = option.set[key];
                    controlStrip.revision++;
                    settleDump.restart();
                }

                Repeater {
                    model: controlStrip.groups
                    RowLayout {
                        id: groupRow
                        required property var modelData
                        spacing: Style.space2
                        Prose { role: "metadata"; text: groupRow.modelData.label }
                        Repeater {
                            model: groupRow.modelData.options
                            Capsule {
                                id: optionButton
                                required property var modelData
                                size: "sm"
                                label: optionButton.modelData.label
                                active: controlStrip.isSelected(groupRow.modelData.target, optionButton.modelData)
                                onClicked: controlStrip.apply(groupRow.modelData.target, optionButton.modelData)
                            }
                        }
                    }
                }
            }

            Item {
                id: sceneArea
                Layout.fillWidth: true
                // Centred in whatever is LEFT once the strip has taken the
                // top of the visible pane -- same rule as before the strip
                // could grow a "scene" row: a short window put the two on
                // top of each other and the header read through the buttons.
                Layout.preferredHeight: Math.max(sceneColumn.implicitHeight, flick.height - (controlStrip.visible ? controlStrip.height + contentColumn.spacing : 0))

                ColumnLayout {
                    id: sceneColumn
                    anchors.centerIn: parent
                    spacing: Style.space4
        Prose { role: "section"; text: `${root.component} / ${root.variant}` }
        Loader {
            id: unitLoader
            active: root.unit !== ""
            visible: active
            source: root.unit === "" ? "" : "units/" + root.unit + ".qml"
            onLoaded: item.variant = Qt.binding(() => root.variant)
        }
        Card {
            visible: root.component === "card"
            Layout.preferredWidth: 260
            Layout.preferredHeight: 90
            surfaceColor: root.variant === "hover" || root.variant === "pressed" ? Style.surfaceRaised : Style.surface
            surfaceOpacity: root.variant === "disabled" ? Style.opacityDisabled : Style.surfaceOpacity
            scale: root.variant === "pressed" ? 0.97 : 1
        }
        SvgIcon {
            visible: root.component === "svg-icon"
            name: "sparkle"
            size: 44
            color: root.variant === "hover" ? Style.accent : root.variant === "pressed" ? Style.secondary : root.variant === "selected" ? Style.success : Style.text
            opacity: root.variant === "disabled" ? Style.opacityDisabled : 1
        }
        Prose {
            visible: root.component === "prose"
            role: root.variant
            text: `Prose / ${root.variant}`
        }
        // The four roles that sit next to each other on the scale. They are
        // captured TOGETHER because the only question worth asking about a
        // supporting role is whether it is tellable from its neighbours.
        ColumnLayout {
            visible: root.component === "prose-ladder"
            spacing: Style.space3
            Repeater {
                model: ["title", "body", "supporting", "metadata"]
                ColumnLayout {
                    required property string modelData
                    spacing: 0
                    Prose { role: "section"; text: modelData }
                    Prose { role: parent.modelData; text: "The rail keeps its width while a popout is open" }
                }
            }
        }
        Capsule { visible: root.component === "capsule"; icon: "bell"; label: "Notifications"; detail: root.variant === "active" ? "2" : ""; active: root.variant === "active" }
        MonthCalendar { visible: root.component === "calendar"; Layout.preferredWidth: 300; shown: new Date(2026, 7, 1); today: new Date(2026, 7, 28) }
        // The same component, named and failing -- the state a text box spends
        // most of its life in once a person is actually using it.
        Field {
            visible: root.component === "field"
            Layout.preferredWidth: 400
            label: "Network name"
            hint: "The SSID as the router broadcasts it"
            error: root.variant === "error" ? "No network by that name is in range" : ""

            TextField { width: parent.width; failed: root.variant === "error"; placeholder: "qsm-lab" }
        }
        IconButton { visible: root.component === "icon-button"; icon: "sparkle"; color: Style.accent }
        NotificationCard {
            visible: root.component === "notification"
            Layout.preferredWidth: 380
            selected: root.variant === "selected"
            alwaysExpanded: root.variant === "expanded"
            animateEntrance: false
            entry: ({
                notificationId: 1,
                appName: "qsm-test",
                summary: "Reference shell updated",
                body: "A deterministic notification fixture for the component library.",
                urgency: "normal",
                createdAt: Date.now()
            })
        }
        NotificationStack {
            visible: root.component === "notification-stack"
            Layout.preferredWidth: 380
            stack: [
                {
                    notificationId: 3,
                    appName: "qsm-test",
                    summary: "Battery critical",
                    body: "Plug in now — 2% remaining.",
                    urgency: "critical",
                    createdAt: Date.now()
                },
                {
                    notificationId: 2,
                    appName: "qsm-mail",
                    summary: "New message from Ada",
                    body: "Reference shell updated in the notification stack.",
                    urgency: "normal",
                    createdAt: Date.now()
                },
                {
                    notificationId: 1,
                    appName: "qsm-focus",
                    summary: "Do not disturb ended",
                    body: "Notifications are visible again.",
                    urgency: "low",
                    createdAt: Date.now()
                }
            ]
            isAlive: id => [1, 2, 3].includes(id)
        }
        ActionTile { visible: root.component === "action-tile"; icon: "power"; label: "Power off"; selected: root.variant === "selected"; armed: root.variant === "armed" }
        Menu {
            visible: root.component === "menu"
            Layout.preferredWidth: 320
            Layout.preferredHeight: 240
            currentIndex: root.variant === "selected" ? 1 : 0
            ListRow { icon: "sparkle"; primary: "Pick a colour" }
            ListRow { icon: "copy"; primary: "Copy" }
            ListRow { header: true; primary: "Danger zone" }
            ListRow { icon: "trash-2"; primary: "Clear"; danger: true }
            ListRow { separator: true }
            ListRow { icon: "log-out"; primary: "Sign out" }
        }
        Segmented {
            visible: root.component === "segmented"
            Layout.preferredWidth: 500
            options: ["Overview", { label: "Media", badge: "2" }, { label: "Performance", disabled: true }]
            currentIndex: root.variant === "second" ? 1 : 0
        }
        StatRing {
            visible: root.component === "stat-ring"
            value: .72
            icon: "cpu"
            reading: "72%"
            label: "CPU"
            // The open form: the gap is where the label sits without meeting
            // the arc.
            startAngle: root.variant === "open" ? -225 : -90
            sweepAngle: root.variant === "open" ? 270 : 360
        }
        EmptyState { visible: root.component === "empty-state"; Layout.preferredWidth: 260; icon: "bell"; title: "Nothing here"; detail: "A deterministic empty fixture." }
        KeyValueRow { visible: root.component === "key-value"; Layout.preferredWidth: 280; icon: "battery"; label: "Battery"; value: "68%"; valueColor: Style.accent }
        Meter { visible: root.component === "meter"; Layout.preferredWidth: 300; value: root.variant === "low" ? .08 : .72; low: .15 }
        Skeleton { visible: root.component === "skeleton"; Layout.preferredWidth: 300; shape: "line"; role: "title" }
        Callout {
            visible: root.component === "callout"
            Layout.preferredWidth: 380
            tone: root.variant
            title: "Could not reach the network"
            body: "The adapter is up but no route answered. Check that the access point is in range."

            Capsule { size: "sm"; variant: "ghost"; icon: "rotate-cw"; label: "Retry" }
        }
        Checkbox { visible: root.component === "checkbox"; label: "Include hidden"; checked: root.variant === "on"; indeterminate: root.variant === "some" }
        Stat { visible: root.component === "stat"; value: "72"; unit: "%"; label: "CPU"; trend: "up"; good: "down" }
        Sparkline { visible: root.component === "sparkline"; Layout.preferredWidth: 200; Layout.preferredHeight: 48; values: [4, 7, 3, 9, 6, 11, 8]; area: root.variant === "area" }
        ColorSwatch { visible: root.component === "swatch"; sample: root.variant === "pale" ? "#f6f1f9" : "#c5a5e9"; reading: root.variant === "pale" ? "#F6F1F9" : "#C5A5E9"; size: 72 }
        Kbd { visible: root.component === "kbd"; combo: "SUPER + SHIFT + Q" }
        Avatar { visible: root.component === "avatar"; name: "Ada Lovelace"; size: 64; status: root.variant === "online" ? "success" : "" }
        Marquee { visible: root.component === "marquee"; Layout.preferredWidth: 200; role: "title"; mode: "always"; text: "A now-playing title far longer than two hundred pixels" }
        Section {
            visible: root.component === "section"
            Layout.preferredWidth: 380
            title: "Devices"

            action: IconButton { icon: "rotate-cw"; size: Style.iconSm; padding: Style.space1; color: Style.textMuted }

            ListRow { size: "sm"; recede: false; icon: "headphones"; primary: "WH-1000XM4"; selected: true }
            ListRow { size: "sm"; recede: false; icon: "mouse"; primary: "MX Master 3" }
        }
        Disclosure {
            visible: root.component === "disclosure"
            Layout.preferredWidth: 380
            title: "Advanced"
            badge: "3"
            expanded: root.variant === "expanded"

            KeyValueRow { Layout.fillWidth: true; label: "MTU"; value: "1500" }
        }
        ScrollArea {
            visible: root.component === "scroll"
            Layout.preferredWidth: 300
            Layout.preferredHeight: 200
            fadeColor: Style.background

            Column {
                width: 300
                spacing: Style.space1
                Repeater {
                    model: 12
                    ListRow { required property int index; width: 300; size: "sm"; recede: false; icon: "workspace"; primary: `Row ${index + 1}` }
                }
            }
        }
                }
            }
        }
    }

    // ShellBorder + Rollout: order-of-work step 2 (docs/design-2026-09-06-
    // shell-border) — one host, one dynamically anchored rollout, reviewed
    // live before anything else is added. Full-viewport, unlike every other
    // scenario above: the band geometry only reads as a band at real size.
    Item {
        id: shellBorderStage
        anchors.fill: parent
        visible: root.component === "shell-border"

        ShellBorder {
            id: borderHost
            anchors.fill: parent
        }

        Rollout {
            host: borderHost
            rolloutId: "preview-rollout"
            edges: ["top"]
            shouldBeActive: root.variant === "shown"

            Rectangle {
                width: 320
                height: 140
                color: "transparent"
                Prose {
                    anchors.centerIn: parent
                    role: "section"
                    text: "ShellBorder preview"
                }
            }
        }
    }
}
