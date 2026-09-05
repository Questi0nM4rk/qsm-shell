import QtQuick
import QtQuick.Layouts
import qs.QsmShell.Components
import qs.QsmShell.Style

Rectangle {
    id: root
    property string component: "capsule"
    property string variant: "resting"
    property int viewportWidth: 1600
    property int viewportHeight: 900
    property var screenContext: ({ id: "preview-1", width: viewportWidth, height: viewportHeight, scale: 1, focused: true, safeInsets: Qt.rect(16, 16, 16, 16) })
    property string theme: "deep-night"
    property var backend: null
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
    ColumnLayout {
        anchors.centerIn: parent
        spacing: Style.space4
        Prose { role: "section"; text: `${root.component} / ${root.variant}` }
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
        Capsule { visible: root.component === "capsule"; icon: "bell"; label: "Notifications"; detail: root.variant === "active" ? "2" : ""; active: root.variant === "active" }
        Slider { visible: root.component === "level"; Layout.preferredWidth: 260; value: root.variant === "high" ? .82 : .42; wheelStep: .05 }
        PopoutRow { visible: root.component === "popout-row"; Layout.preferredWidth: 260; icon: "wifi"; label: "qsm-lab"; value: "Connected"; active: root.variant === "active"; actionIcon: "trash-2" }
        MonthCalendar { visible: root.component === "calendar"; Layout.preferredWidth: 300; shown: new Date(2026, 7, 1); today: new Date(2026, 7, 28) }
        SearchField { visible: root.component === "search"; Layout.preferredWidth: 400; placeholder: "Search components" }
        ResultRow { visible: root.component === "result"; Layout.preferredWidth: 500; item: root.variant === "header" ? { kind: "header", label: "Tools" } : { kind: "action", label: "Pick a colour", sub: "Open colour picker", icon: "sparkle" }; selected: root.variant !== "idle" }
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
        NotificationCard { visible: root.component === "notification"; Layout.preferredWidth: 380; selected: root.variant === "selected"; expanded: root.variant === "expanded"; title: "Reference shell updated"; body: "A deterministic notification fixture for the component library."; source: "qsm-test"; icon: "bell"; accent: Style.accent }
        SessionButton { visible: root.component === "session-button"; icon: "power"; label: "Power off"; selected: root.variant === "selected"; armed: root.variant === "armed" }
        MenuRowItem {
            visible: root.component === "menu-row-item"
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
            MenuRowItem { icon: "sparkle"; primary: "Pick a colour" }
            MenuRowItem { icon: "copy"; primary: "Copy" }
            MenuRowItem { header: true; primary: "Danger zone" }
            MenuRowItem { icon: "trash-2"; primary: "Clear"; danger: true }
            MenuRowItem { separator: true }
            MenuRowItem { icon: "log-out"; primary: "Sign out" }
        }
        TabStrip { visible: root.component === "tabs"; Layout.preferredWidth: 500; labels: ["Overview", "Media", "Performance"]; currentIndex: root.variant === "second" ? 1 : 0 }
        StatRing { visible: root.component === "stat-ring"; value: .72; label: "CPU"; reading: "72%" }
        Divider { visible: root.component === "divider"; Layout.preferredWidth: 400; inset: 20 }
        EmptyState { visible: root.component === "empty-state"; Layout.preferredWidth: 260; icon: "bell"; title: "Nothing here"; detail: "A deterministic empty fixture." }
        KeyValueRow { visible: root.component === "key-value"; Layout.preferredWidth: 280; icon: "battery"; label: "Battery"; value: "68%"; valueColor: Style.accent }
        AppIcon { visible: root.component === "app-icon"; Layout.preferredWidth: 48; Layout.preferredHeight: 48; sourceUrl: root.variant === "resolved" ? Qt.resolvedUrl("../qml/QsmShell/assets/icons/sparkle.svg") : "" }
    }
}
