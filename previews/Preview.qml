pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.QsmShell.Components
import qs.QsmShell.Style

Rectangle {
    id: root
    property string component: "capsule"
    property string variant: "resting"
    // PascalCase basename under previews/units/. Empty means not migrated
    // yet -- the inline children below keep working unchanged.
    property string unit: ""
    property int viewportWidth: 1600
    property int viewportHeight: 900
    property var screenContext: ({ id: "preview-1", width: viewportWidth, height: viewportHeight, scale: 1, focused: true, safeInsets: Qt.rect(16, 16, 16, 16) })
    property string theme: "deep-night"
    property var backend: null
    // Buttons for a unit's declared `controls` only ever exist on the live
    // path -- a capture is a picture of the component and must not grow them.
    property bool interactive: false
    width: viewportWidth
    height: viewportHeight
    color: "#1c0e27"
    // Theme fixtures: one backend object per named theme. A caller-supplied
    // `backend` always wins over the theme map.
    StyleBackend { id: deepNightBackend }
    property var _themeFixtures: ({ "deep-night": deepNightBackend })
    property var activeBackend: backend !== null && backend !== undefined ? backend : (_themeFixtures[theme] || null)
    // Install the active backend on the Style singleton so every component
    // resolves tokens from the scenario theme.
    Component.onCompleted: Style.backend = root.activeBackend
    onActiveBackendChanged: Style.backend = root.activeBackend
    // A loaded unit's type is only known at runtime, so `controls` cannot be
    // typed on `Loader.item` -- read it through an untyped parameter instead
    // of a direct `.controls` access qmllint cannot resolve.
    function unitControls(item) {
        return (item && Array.isArray(item.controls)) ? item.controls : [];
    }
    ColumnLayout {
        anchors.centerIn: parent
        spacing: Style.space4
        // A unit's `controls` reach every property-only state that isn't
        // reachable by hovering, pressing or focusing the live window --
        // `disabled`, `selected`, `indeterminate`, and the like.
        ColumnLayout {
            id: controlStrip
            spacing: Style.space2
            visible: root.interactive && root.unitControls(unitLoader.item).length > 0

            // group label -> applied option label, so the matching button can
            // show `active` for whatever was clicked last.
            property var applied: ({})

            function apply(groupLabel, option, optionLabel) {
                if (option.call !== undefined) {
                    unitLoader.item[option.call]();
                } else {
                    for (const key in option.set)
                        unitLoader.item[key] = option.set[key];
                }
                const next = Object.assign({}, controlStrip.applied);
                next[groupLabel] = optionLabel;
                controlStrip.applied = next;
            }

            Repeater {
                model: controlStrip.visible ? root.unitControls(unitLoader.item) : []
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
                            active: controlStrip.applied[groupRow.modelData.label] === optionButton.modelData.label
                            onClicked: controlStrip.apply(groupRow.modelData.label, optionButton.modelData, optionButton.modelData.label)
                        }
                    }
                }
            }
        }
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
        Item {
            visible: root.component === "state-layer"
            Layout.preferredWidth: 260
            Layout.preferredHeight: 76
            Rectangle {
                id: layerTarget
                anchors.fill: parent
                radius: Style.radiusLg
                color: Style.surfaceRaised
                opacity: root.variant === "disabled" ? Style.opacityDisabled : 1
            }
            Text {
                anchors.centerIn: parent
                text: `StateLayer / ${root.variant}`
                color: Style.textMuted
                font.pixelSize: Style.textXs
            }
            StateLayer {
                anchors.fill: parent
                target: layerTarget
                interactive: root.variant !== "disabled"
            }
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
        Slider { visible: root.component === "level"; Layout.preferredWidth: 260; value: root.variant === "high" ? .82 : .42; wheelStep: .05 }
        // A row in a list you READ: no recession, a reading and a tertiary
        // action in the trailing slot.
        ListRow {
            visible: root.component === "device-row"
            Layout.preferredWidth: 260
            size: "sm"
            recede: false
            icon: "wifi"
            primary: "qsm-lab"
            selected: root.variant === "active"

            Prose { role: "reading"; font.pixelSize: Style.textXs; muted: true; text: "Connected" }
            IconButton { icon: "trash-2"; size: Style.iconSm; padding: Style.space1; color: Style.textMuted }
        }
        MonthCalendar { visible: root.component === "calendar"; Layout.preferredWidth: 300; shown: new Date(2026, 7, 1); today: new Date(2026, 7, 28) }
        // A search box is a text box with a magnifier in its leading slot.
        TextField {
            visible: root.component === "search"
            Layout.preferredWidth: 400
            size: "lg"
            placeholder: "Search components"

            leading: SvgIcon { name: "search"; size: Style.iconMd; color: Style.textMuted }
        }
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
        // A row in a list you PICK from: large, and everything not current
        // recedes hard.
        ListRow {
            visible: root.component === "result-row"
            Layout.preferredWidth: 500
            size: "lg"
            header: root.variant === "header"
            icon: "sparkle"
            primary: root.variant === "header" ? "Tools" : "Pick a colour"
            supporting: "Open colour picker"
            selected: root.variant !== "idle"
        }
        IconButton { visible: root.component === "icon-button"; icon: "sparkle"; color: Style.accent }
        Slider {
            visible: root.component === "osd-slider"
            orientation: Qt.Vertical
            Layout.preferredHeight: 180
            thickness: 40
            thumbSize: 32
            raised: true
            trackColor: Qt.darker(Style.surface, 1.35)
            value: root.variant === "high" ? .82 : .42
            thumbContent: Text {
                anchors.centerIn: parent
                text: Math.round((root.variant === "high" ? .82 : .42) * 100)
                color: Style.background
                font.family: Style.fontFamily
                font.pixelSize: Style.textSm
                font.weight: Style.weightBold
            }
            after: IconButton { icon: "volume"; size: Style.iconMd; padding: Style.space2 }
        }
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
        ListRow {
            visible: root.component === "list-row"
            Layout.preferredWidth: 320
            icon: "sparkle"
            primary: "Pick a colour"
            supporting: "Open colour picker"
            selected: root.variant === "selected"
            danger: root.variant === "danger"
            header: root.variant === "header"
            separator: root.variant === "separator"
            disabled: root.variant === "disabled"
        }
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
        Switch { visible: root.component === "switch"; checked: root.variant === "on" }
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
