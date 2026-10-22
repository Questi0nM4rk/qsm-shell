import QtQuick
import QtQuick.Layouts

import qs.QsmShell.Components
import qs.QsmShell.Style
import "../fixtures"

Item {
    id: root

    property string variant: ""
    property var eventRecorder: null
    property var previewEnvironment: null
    property bool shown: true
    property bool hoverStay: true
    property bool interactive: true
    property bool unavailable: false
    property bool elevated: true
    property int timeout: 0
    property int orientation: Qt.Horizontal
    property string size: "md"
    property string edge: "bottom"
    property string alignment: "center"
    property real inset: Style.space4
    property string length: "default"
    property string contentMode: "short"
    property int opened: 0
    property int expired: 0

    implicitWidth: Style.controlWidth
    implicitHeight: Style.size("Control", "md")

    readonly property real preferredLength: length === "short"
        ? Style.rhythm(Style.controlWidth / 2)
        : length === "long" ? Style.rhythm(Style.controlWidth * 1.5) : Style.controlWidth

    readonly property string titleText: "Workspace 10"
    readonly property string readingText: "10"
    readonly property string statusText: contentMode === "long"
        ? "A longer status detail stays inside the caller's capsule slot and never changes the capsule's preferred footprint."
        : "Details are ready to review."
    readonly property string singleLineText: titleText + " · " + statusText

    function present(): void {
        root.shown = true;
        capsule.restart();
    }

    function hide(): void {
        root.shown = false;
    }

    function clearPresentation(): void {
        capsule.reset();
        root.shown = false;
    }

    MockScreen {
        id: screen
        anchors.fill: parent
        previewEnvironment: root.previewEnvironment
        edge: root.edge
        alignment: root.alignment
        inset: root.inset
        preferredWidth: capsule.implicitWidth
        preferredHeight: capsule.implicitHeight

        DataCapsule {
            id: capsule
            objectName: "dataCapsule"
            shown: root.shown
            timeout: root.timeout
            hoverStay: root.hoverStay
            interactive: root.interactive
            enabled: !root.unavailable
            elevated: root.elevated
            actionLabel: "Open details"
            accessibleName: root.singleLineText
            orientation: root.orientation
            size: root.size
            preferredLength: root.preferredLength
            x: 0
            y: 0
            width: parent.width
            height: parent.height
            onActivated: {
                root.opened++;
                root.eventRecorder?.("intent", "activated", { opened: root.opened });
            }
            onTimeoutRequested: {
                root.expired++;
                root.shown = false;
                root.eventRecorder?.("intent", "timeout-requested", { expired: root.expired });
            }

            // Keep the same workspace task legible in either capsule shape.
            Item {
                id: composition
                objectName: "capsuleComposition"

                readonly property bool horizontal: root.orientation === Qt.Horizontal

                readonly property real slotWidth: Math.max(0, parent ? parent.width : 0)
                readonly property real slotHeight: Math.max(0, parent ? parent.height : 0)

                readonly property real gap: Style.rhythm(Style.space1)
                readonly property real glyphSpan: Style.iconNear(Style.iconMd * capsule.sizeScale)

                readonly property bool twoLine: slotHeight >= titleFontMetrics.height + gap + statusFontMetrics.height

                readonly property real naturalWidth: horizontal
                    ? (twoLine ? Math.max(titleSpan, statusSpan) : singleSpan)
                    : Math.max(glyphSpan, readingSpan)
                readonly property real naturalHeight: horizontal
                    ? (twoLine ? titleFontMetrics.height + gap + statusFontMetrics.height : singleFontMetrics.height)
                    : glyphSpan + gap + readingFontMetrics.height

                readonly property real titleSpan: titleMetrics.advanceWidth
                readonly property real statusSpan: statusMetrics.advanceWidth
                readonly property real readingSpan: readingMetrics.advanceWidth
                readonly property real singleSpan: singleMetrics.advanceWidth

                anchors.centerIn: parent
                width: Math.min(Math.ceil(naturalWidth), slotWidth)
                height: Math.min(naturalHeight, slotHeight)
                visible: root.contentMode !== "empty"

                ColumnLayout {
                    id: textStack
                    objectName: "capsuleTextStack"
                    anchors.centerIn: composition
                    width: composition.width
                    spacing: composition.gap
                    visible: composition.horizontal && composition.twoLine

                    Prose {
                        id: titleItem
                        objectName: "capsuleTitle"
                        role: "title"
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignHCenter
                        font.pixelSize: Style.textNear(Style.textMd * capsule.sizeScale)
                        color: capsule.enabled ? Style.text : Style.disabled(Style.text)
                        text: root.titleText
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Prose {
                        id: statusItem
                        objectName: "capsuleStatus"
                        role: "supporting"
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignHCenter
                        font.pixelSize: Style.textNear(Style.textSm * capsule.sizeScale)
                        color: capsule.enabled ? Style.textMuted : Style.disabled(Style.textMuted)
                        text: root.statusText
                        horizontalAlignment: Text.AlignHCenter
                    }
                }

                ColumnLayout {
                    id: singleStack
                    objectName: "capsuleSingleLine"
                    anchors.centerIn: composition
                    width: composition.width
                    visible: composition.horizontal && !composition.twoLine

                    Prose {
                        id: singleItem
                        objectName: "capsuleSingle"
                        role: "label"
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignHCenter
                        font.pixelSize: Style.textNear(Style.textMd * capsule.sizeScale)
                        color: capsule.enabled ? Style.text : Style.disabled(Style.text)
                        text: root.singleLineText
                        horizontalAlignment: Text.AlignHCenter
                    }
                }

                ColumnLayout {
                    id: columnStack
                    objectName: "capsuleColumn"
                    anchors.centerIn: composition
                    width: composition.width
                    spacing: composition.gap
                    visible: !composition.horizontal

                    SvgIcon {
                        id: glyphItem
                        objectName: "capsuleGlyph"
                        name: "workspace"
                        color: capsule.enabled ? Style.text : Style.disabled(Style.text)
                        size: composition.glyphSpan
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Prose {
                        id: readingItem
                        objectName: "capsuleReading"
                        role: "reading"
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignHCenter
                        font.pixelSize: Style.textNear(Style.textMd * capsule.sizeScale)
                        color: capsule.enabled ? Style.text : Style.disabled(Style.text)
                        text: root.readingText
                        horizontalAlignment: Text.AlignHCenter
                    }
                }

                FontMetrics {
                    id: titleFontMetrics
                    font: titleItem.font
                }

                TextMetrics {
                    id: titleMetrics
                    font: titleItem.font
                    text: root.titleText
                }

                FontMetrics {
                    id: statusFontMetrics
                    font: statusItem.font
                }

                TextMetrics {
                    id: statusMetrics
                    font: statusItem.font
                    text: root.statusText
                }

                FontMetrics {
                    id: readingFontMetrics
                    font: readingItem.font
                }

                TextMetrics {
                    id: readingMetrics
                    font: readingItem.font
                    text: root.readingText
                }

                FontMetrics {
                    id: singleFontMetrics
                    font: singleItem.font
                }

                TextMetrics {
                    id: singleMetrics
                    font: singleItem.font
                    text: root.singleLineText
                }
            }
        }
    }

    readonly property var controls: [
        { label: "edge", options: [
            { label: "left", set: { edge: "left" } },
            { label: "right", set: { edge: "right" } },
            { label: "top", set: { edge: "top" } },
            { label: "bottom", set: { edge: "bottom" } }
        ] },
        { label: "alignment", options: [
            { label: "start", set: { alignment: "start" } },
            { label: "center", set: { alignment: "center" } },
            { label: "end", set: { alignment: "end" } }
        ] },
        { label: "inset", options: [
            { label: "inset-small", set: { inset: Style.space2 } },
            { label: "inset-default", set: { inset: Style.space4 } },
            { label: "inset-large", set: { inset: Style.space6 } }
        ] },
        { label: "orientation", options: [
            { label: "horizontal", set: { orientation: Qt.Horizontal } },
            { label: "vertical", set: { orientation: Qt.Vertical } }
        ] },
        { label: "size", options: [
            { label: "sm", set: { size: "sm" } },
            { label: "md", set: { size: "md" } },
            { label: "lg", set: { size: "lg" } }
        ] },
        { label: "length", options: [
            { label: "short", set: { length: "short" } },
            { label: "default", set: { length: "default" } },
            { label: "long", set: { length: "long" } }
        ] },
        { label: "content", options: [
            { label: "short", set: { contentMode: "short" } },
            { label: "long", set: { contentMode: "long" } },
            { label: "empty", set: { contentMode: "empty" } }
        ] },
        { label: "presentation", options: [
            { label: "present", call: "present" },
            { label: "hide", call: "hide" }
        ] },
        { label: "lifetime", options: [
            { label: "persistent", set: { timeout: 0 } },
            { label: "timed", set: { timeout: 1000 } }
        ] },
        { label: "retention", options: [
            { label: "hover-stay", set: { hoverStay: true } },
            { label: "no-hover-stay", set: { hoverStay: false } }
        ] },
        { label: "elevation", options: [
            { label: "elevated", set: { elevated: true } },
            { label: "flat", set: { elevated: false } }
        ] },
        { label: "availability", options: [
            { label: "openable", set: { interactive: true, unavailable: false } },
            { label: "report-only", set: { interactive: false, unavailable: false } },
            { label: "disabled", set: { unavailable: true } }
        ] }
    ]

    readonly property var integration: ({
        events: ["activated", "timeout-requested"],
        actions: ["present", "hide", "activate", "restart", "reset"],
        targets: {
            "capsule": () => screen.emptyPlacement ? null : capsule,
            "scene": () => root
        },
        observables: {
            shown: () => root.shown,
            present: () => capsule.present,
            "keep-open": () => capsule.keepOpen,
            hovered: () => capsule.pointerHovered,
            focused: () => capsule.visualFocus,
            "accepts-input": () => capsule.acceptsInput,
            animating: () => capsule.animating,
            "can-activate": () => capsule.actions[0].enabled,
            "armed": () => capsule._armed,
            opened: () => root.opened,
            expired: () => root.expired,
            fullscreen: () => screen.fullscreen,
            "environment-supported": () => screen.environmentSupported,
            constrained: () => screen.constrained,
            "empty-placement": () => screen.emptyPlacement,
            edge: () => root.edge,
            alignment: () => root.alignment,
            "remaining-time": () => capsule.remainingTime()
        },
        runAction: name => {
            if (name === "present") { root.present(); return true; }
            if (name === "hide") { root.hide(); return true; }
            if (name === "activate") return capsule.activate();
            if (name === "restart") { capsule.restart(); return true; }
            if (name === "reset") { root.clearPresentation(); return true; }
            return false;
        }
    })
}
