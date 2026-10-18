pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import QtQuick.Templates as T

import qs.QsmShell.Style

// ONE notification entry, rendered and made interactive. The card owns
// everything about how a notification LOOKS and RESPONDS; it owns no service,
// no scene, and no policy about when a notification is shown at all.
//
// `entry` is a plain data object shaped like:
//   { notificationId, appName, summary, body, urgency, actions: [{id, label}],
//     imagePath, createdAt, paused, isTransient, archivedAt, swatch }
// Every field is optional except where the card cannot degrade without it
// (`appName`, `summary`). `urgency` is "low" | "normal" | "critical". `body`
// is StyledText — the consumer is the one that sanitizes it before handing it
// here. `archivedAt` present means the entry is a closed record: the card
// shows its wall-clock time instead of a relative one and stops offering the
// action row. `swatch`, present, is a colour the icon box shows AS the icon
// instead of a fallback glyph — the card does not know or ask why.
//
// The card never mutates `entry` and never calls into anything outside
// itself: hover is reported through `hovered`, an action press through
// `actionTriggered`, a dismiss gesture through `dismissed`. What any of that
// should DO — pause an expiry timer, invoke a D-Bus action, register the
// card's rect with a fullscreen capsule — is the consumer's call, made from
// the outside.
Item {
    id: root

    required property var entry
    // Held open regardless of hover/drag — a fixed reference card, or the
    // notification centre's currently-toggled row.
    property bool alwaysExpanded: false
    property bool draggable: false
    // A retiring stack row keeps its current expansion but cannot receive input.
    property bool inputEnabled: true
    property bool expansionFrozen: false
    property bool frozenExpanded: false
    property real frozenHeight: 0
    // Vertical drag-to-expand is opt-in: a delegate inside a Flickable list
    // must not let a vertical drag double as the list's own scroll gesture.
    property bool verticalDragEnabled: false
    property bool showActions: true
    // Set by a host only when this exact live record currently offers the
    // protocol's default action. The card owns the activation affordance only.
    property bool primaryActionEnabled: false
    property bool showDivider: false
    // A list of cards opts in to bodied cards: each entry is its own
    // `surface` body with a slight shadow, so neighbours never read as one
    // run of text. The default stays boxless for the popup stack.
    property bool bodied: false
    // The bodied card's corner radius. The menu keeps the large radius; the
    // popup stack asks for the medium one (spec 04).
    property real bodyRadius: Style.radiusLg
    // Hover expands a popup, which nothing scrolls. Inside a scrolled list
    // hover expansion steals the wheel under the pointer, so a list sets
    // false: the leading column then asks for expansion by click
    // (`expandRequested`), the rest of the card stays the card's action,
    // and an expanded body shows in full instead of scrolling inside itself.
    property bool expandOnHover: true
    // The host says this entry has not been seen (a 6px accent dot by the
    // app name) and whether a plain click on the body should report
    // `activated` when there is no primary action to run.
    property bool unread: false
    property bool activatable: false
    // A list with its own cursor marks this card current: the accent tick
    // on a boxless card, the selected tint on a bodied one.
    property bool selected: false
    // Which of this entry's (at most 3) actions carries keyboard focus, or
    // -1 for none. A list owns one cursor for many cards and passes it down.
    property int actionFocusIndex: -1
    // Toggled by a vertical drag past the threshold; additive to hover.
    property bool dragExpanded: false
    property bool swipeDismissPending: false
    property double currentTimeMs: Date.now()
    // Defaults from the entry shape; a consumer whose entry does not carry a
    // swatch of its own (or which decides one under a rule the card cannot
    // see — an app name, say) overrides it directly.
    property var swatch: root.entry.swatch

    readonly property bool verticalDrag: drag.active && Math.abs(drag.translation.y) > Math.abs(drag.translation.x)
    readonly property bool dragActive: drag.active
    readonly property bool hovered: layer.hovered
    readonly property bool primaryPressed: layer.pressed
    readonly property bool expansionAnimating: expansionAnimation.running
    readonly property bool expanded: root.expansionFrozen ? root.frozenExpanded
        : root.alwaysExpanded || (root.expandOnHover && root.hovered) || root.dragExpanded || (root.entry.paused ?? false)
    readonly property bool archived: root.entry.archivedAt !== undefined && root.entry.archivedAt !== null
    readonly property bool hasSwatch: root.swatch !== undefined && root.swatch !== null
    readonly property bool primaryActionAvailable: root.primaryActionEnabled
        && !root.showActions && !root.archived
        && root.defaultAction() !== null
    readonly property string primaryActionLabel: {
        const action = root.defaultAction();
        const label = String(action?.label ?? "").trim();
        return label.length > 0 ? label : `Open ${root.entry.appName}`;
    }

    signal dismissed
    // The leading column was clicked; the host owns which card is open.
    signal expandRequested
    signal actionTriggered(string actionId)
    signal primaryTriggered(var entry)
    signal activated(var entry)
    readonly property list<T.Action> actions: [dismissAction, primaryAction, firstAction, secondAction, thirdAction]
        .filter(action => action.text.length > 0)

    Accessible.role: root.primaryActionAvailable ? Accessible.Button : Accessible.StaticText
    Accessible.name: root.primaryActionAvailable
        ? `${root.primaryActionLabel}: ${root.entry.summary}`
        : `${root.entry.appName}: ${root.entry.summary}`
    Accessible.description: String(root.entry.body ?? "")
    Accessible.onPressAction: root.activatePrimary()

    T.Action {
        id: dismissAction
        text: "Dismiss"
        enabled: root.enabled && root.visible && root.inputEnabled
        onTriggered: root.dismiss()
    }

    T.Action {
        id: primaryAction
        text: root.primaryActionAvailable ? root.primaryActionLabel : ""
        enabled: root.enabled && root.visible && root.inputEnabled && root.primaryActionAvailable
        onTriggered: root.activatePrimary()
    }

    component EntryAction: T.Action {
        required property int index
        readonly property var entryAction: root.entry.actions?.[index] ?? null
        text: entryAction ? String(entryAction.label ?? entryAction.id ?? "") : ""
        enabled: !!entryAction && root.enabled && root.visible && root.inputEnabled && root.expanded
            && root.showActions && !root.archived && !(entryAction.disabled ?? false)
        onTriggered: root.activateAction(String(entryAction.id))
    }

    EntryAction { id: firstAction; index: 0 }
    EntryAction { id: secondAction; index: 1 }
    EntryAction { id: thirdAction; index: 2 }

    function dismiss(): void {
        if (root.enabled && root.visible && root.inputEnabled)
            root.dismissed()
    }

    function freezePresentation(): void {
        if (root.expansionFrozen)
            return;
        const paintedHeight = root.height;
        const paintedProgress = root.entranceProgress;
        root.frozenExpanded = root.expanded;
        root.frozenHeight = paintedHeight;
        root.expansionFrozen = true;
        // Behavior owns its animation; a disabled write replaces its target.
        root.entranceProgress = paintedProgress;
    }

    function releasePresentation(): void {
        root.entranceProgress = 1;
        root.expansionFrozen = false;
    }

    function activateAction(actionId: string): void {
        const actions = root.actionList();
        if (!root.enabled || !root.visible || !root.inputEnabled || !root.expanded || !root.showActions || root.archived || !actionId)
            return;
        const action = actions.find(item => String(item.id) === actionId);
        if (!action || action.disabled)
            return;
        root.actionTriggered(actionId);
    }

    function activatePrimary(): bool {
        if (!root.enabled || !root.visible || !root.inputEnabled || !root.primaryActionAvailable)
            return false;
        root.primaryTriggered(root.entry);
        return true;
    }

    // A record's actions may arrive as a QVariantList reference, which indexes
    // like an array but has no Array methods; copy it before .find or .some.
    function actionsOf(record: var): var {
        const source = record?.actions;
        const result = [];
        for (let index = 0; source && index < source.length; index++)
            result.push(source[index]);
        return result;
    }

    function actionList(): var {
        return root.actionsOf(root.entry).slice(0, 3);
    }

    function defaultAction(): var {
        return root.actionsOf(root.entry).find(item => String(item.id) === "default"
            && !(item.disabled ?? false)) ?? null;
    }

    readonly property string iconSource: root.entry.imagePath ?? ""
    readonly property string iconName: root.entry.urgency === "critical" ? "alert-triangle"
        : root.entry.urgency === "low" ? "moon"
        : "bell"
    // Urgency is carried by the glyph's colour alone (spec 04, owner
    // 2026-10-16): critical danger, normal info, low textMuted.
    readonly property color glyphColor: root.entry.urgency === "critical" ? Style.danger
        : root.entry.urgency === "low" ? Style.textMuted
        : Style.info

    Timer {
        interval: 60 * 1000
        repeat: true
        running: !root.archived && root.entry.createdAt !== undefined && root.entry.createdAt !== null
        onTriggered: root.currentTimeMs = Date.now()
    }

    // Named rather than inlined in the label's binding so it is one call
    // away from a test, the same reasoning `Style.childRadius` is a function.
    function timestampText(): string {
        if (root.archived)
            return Qt.formatDateTime(new Date(root.entry.archivedAt), "hh:mm");
        if (root.entry.createdAt === undefined || root.entry.createdAt === null)
            return "";
        const seconds = Math.max(0, (root.currentTimeMs - root.entry.createdAt) / 1000);
        if (seconds < 60)
            return "just now";
        if (seconds < 3600)
            return `${Math.floor(seconds / 60)}m ago`;
        return `${Math.floor(seconds / 3600)}h ago`;
    }

    implicitWidth: Style.notificationWidth
    implicitHeight: root.expansionFrozen ? root.frozenHeight
        : root.restHeight + (root.bodied ? root.shadowRoom : 0)
    readonly property real restHeight: root.expanded ? headline.height + details.implicitHeight + Style.space2
        : String(root.entry.body ?? "").length > 0 ? Style.notificationPreviewHeight
        : Style.notificationCollapsedHeight
    // The card clips (its height animates), so a bodied card keeps room
    // under its body for the shadow to fall into.
    readonly property real shadowRoom: Style.space1
    readonly property bool leadHovered: leadLayer.hovered

    clip: true

    // A fixed reference instance (a preview, a list row re-entering from a
    // filter change) can skip the settle; a fresh arrival gets it.
    property bool animateEntrance: true
    property real entranceProgress: root.animateEntrance ? 0 : 1
    // A small settle rather than a real button press — the same idiom every
    // control's own `pressScale` uses, named as its own property rather than
    // a literal in the scale expression below (same law, `pressScale` etc.).
    property real entranceScale: Motion.microPopScale
    opacity: root.entranceProgress
    scale: root.entranceScale + root.entranceProgress * (1 - root.entranceScale)
    Behavior on entranceProgress {
        enabled: !root.expansionFrozen
        NumberAnimation { id: entranceAnimation; duration: Motion.microPop; easing.type: Motion.emphasizedEasing }
    }
    Component.onCompleted: {
        if (root.animateEntrance)
            Qt.callLater(() => root.entranceProgress = 1);
    }

    Behavior on implicitHeight {
        enabled: !root.expansionFrozen
        NumberAnimation {
            id: expansionAnimation
            duration: Motion.fast
            easing.type: Motion.emphasizedEasing
        }
    }

    Surface {
        id: body
        anchors.fill: parent
        anchors.bottomMargin: root.bodied ? root.shadowRoom : 0
        visible: root.bodied
        radius: root.bodyRadius
        base: Style.surface
        selected: root.selected
        enabled: root.enabled
        layer.enabled: root.bodied && !Style.reducedEffects
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Style.shadow
            shadowOpacity: Style.cardShadowOpacity
            shadowBlur: Style.cardShadowBlur
            shadowVerticalOffset: Style.cardShadowOffset
            blurMax: Style.cardShadowExtent
        }
    }

    // The list cursor: a card in a list that keeps its own cursor shows
    // it here, thick and accent. Urgency has no tick (the glyph carries it),
    // and a bodied card shows selection on its body instead.
    SelectionMark {
        id: tick
        anchors.left: parent.left
        anchors.leftMargin: Style.space2
        anchors.verticalCenter: headline.verticalCenter
        shown: root.selected && !root.bodied
        strong: true
        markColor: root.enabled ? Style.accent : Style.disabled(Style.accent)
    }

    RowLayout {
        id: headline
        anchors.left: tick.right
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: Style.space2
        anchors.rightMargin: Style.space3
        height: Style.notificationCollapsedHeight
        spacing: Style.space2

        // The app's own icon when it sent one, the swatch when the consumer
        // decided this entry carries one, else the urgency glyph — all three
        // occupy the same box so the headline never reflows on arrival.
        Item {
            implicitWidth: Style.iconSm
            implicitHeight: Style.iconSm

            SvgIcon {
                anchors.fill: parent
                visible: root.leadHovered
                name: root.expanded ? "chevron-up" : "chevron-down"
                size: Style.iconSm
                color: Style.text
            }

            Rectangle {
                anchors.fill: parent
                visible: root.hasSwatch && !root.leadHovered
                radius: Style.radiusSm
                color: root.swatch ?? "transparent"
                border.width: 1
                border.color: Style.textMuted
            }

            Image {
                anchors.fill: parent
                visible: !root.leadHovered && !root.hasSwatch && root.iconSource.length > 0
                source: root.iconSource
                asynchronous: true
                fillMode: Image.PreserveAspectFit
            }

            SvgIcon {
                anchors.fill: parent
                visible: !root.leadHovered && !root.hasSwatch && root.iconSource.length === 0
                name: root.iconName
                size: Style.iconSm
                color: root.enabled ? root.glyphColor : Style.disabled(root.glyphColor)
            }
        }

        // A NAME, not a value — the technical face is reserved for numbers
        // and machine text.
        Prose {
            id: appNameLabel
            role: "metadata"
            text: root.entry.appName
            Layout.maximumWidth: (Style.notificationWidth - Style.iconSm - Style.space3 * 3) / 3
            color: root.enabled ? Style.textMuted : Style.disabled(Style.textMuted)
        }
        Rectangle {
            visible: root.unread
            width: Style.space1 + Style.spaceTight
            height: width
            radius: width / 2
            color: Style.accent
            Accessible.name: "unread"
        }
        Prose {
            Layout.fillWidth: true
            role: "title"
            text: root.entry.summary
            visible: !root.expanded
            color: !root.enabled ? Style.disabled(Style.text)
                : root.primaryPressed && root.primaryActionAvailable ? Style.accent : Style.text
        }
        Prose {
            role: "metadata"
            technical: true
            text: root.timestampText()
            visible: text.length > 0
            color: root.enabled ? Style.textMuted : Style.disabled(Style.textMuted)
        }
    }

    Text {
        id: bodyPreview
        anchors.left: headline.left
        anchors.leftMargin: Style.iconSm + Style.space2
        anchors.right: headline.right
        anchors.top: headline.bottom
        anchors.topMargin: Style.space1
        height: Math.max(0, Style.notificationPreviewHeight - headline.height - Style.space1)
        visible: !root.expanded && String(root.entry.body ?? "").length > 0
        text: root.entry.body ?? ""
        textFormat: Text.StyledText
        color: root.enabled ? Style.textMuted : Style.disabled(Style.textMuted)
        font.family: Style.fontFamily
        font.pixelSize: Style.textSm
        lineHeight: Style.rhythm(Style.textSm * Style.lineBody)
        lineHeightMode: Text.FixedHeight
        wrapMode: Text.WordWrap
        maximumLineCount: 2
        elide: Text.ElideRight
        clip: true
        Accessible.role: Accessible.StaticText
    }

    ColumnLayout {
        id: details
        anchors.left: headline.left
        anchors.leftMargin: Style.iconSm + Style.space2
        anchors.right: parent.right
        anchors.top: headline.bottom
        anchors.rightMargin: Style.space3
        spacing: Style.space1
        visible: root.expanded

        Item {
            id: bodyViewportHost
            Layout.fillWidth: true
            implicitHeight: root.expandOnHover
                ? Math.min(expandedContent.implicitHeight, Style.notificationBodyViewportHeight)
                : expandedContent.implicitHeight
            height: implicitHeight

            Flickable {
                id: bodyViewport
                anchors.fill: parent
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                contentWidth: width
                contentHeight: expandedContent.implicitHeight
                flickableDirection: Flickable.VerticalFlick

                Column {
                    id: expandedContent
                    width: bodyViewport.width
                    spacing: Style.space1

                    Text {
                        width: parent.width
                        text: root.entry.summary
                        color: !root.enabled ? Style.disabled(Style.text)
                            : root.primaryPressed && root.primaryActionAvailable ? Style.accent : Style.text
                        font.family: Style.fontFamily
                        font.pixelSize: Style.textMd
                        font.weight: Style.weightMedium
                        lineHeight: Style.rhythm(Style.textMd * Style.lineBody)
                        lineHeightMode: Text.FixedHeight
                        wrapMode: Text.WordWrap
                        Accessible.role: Accessible.StaticText
                    }

                    Text {
                        id: bodyText
                        width: parent.width
                        visible: text.length > 0
                        text: root.entry.body ?? ""
                        // Ingress sanitizes to the supported b/i/u/br subset.
                        textFormat: Text.StyledText
                        color: root.enabled ? Style.textMuted : Style.disabled(Style.textMuted)
                        font.family: Style.fontFamily
                        font.pixelSize: Style.textSm
                        lineHeight: Style.rhythm(Style.textSm * Style.lineBody)
                        lineHeightMode: Text.FixedHeight
                        wrapMode: Text.WordWrap
                        Accessible.role: Accessible.StaticText
                    }
                }
            }

            MouseArea {
                anchors.fill: bodyViewport
                enabled: root.expandOnHover
                acceptedButtons: Qt.NoButton
                onWheel: event => {
                    const next = Math.max(0, Math.min(bodyViewport.contentHeight - bodyViewport.height,
                        bodyViewport.contentY - event.angleDelta.y));
                    if (next !== bodyViewport.contentY) {
                        bodyViewport.contentY = next;
                        event.accepted = true;
                    } else {
                        event.accepted = false;
                    }
                }
            }
        }

        RowLayout {
            visible: root.showActions && !root.archived && root.actionList().length > 0
            spacing: Style.space3

            Repeater {
                model: root.actionList()

                Text {
                    required property var modelData
                    required property int index
                    readonly property bool available: root.enabled && root.inputEnabled
                        && !(modelData.disabled ?? false)
                    enabled: available
                    // Addressable by a consumer or a test without exposing a
                    // repeater handle from the card's own public interface.
                    objectName: "notificationAction" + index
                    text: modelData.label ?? String(modelData)
                    color: root.enabled && !(modelData.disabled ?? false)
                        ? (root.actionFocusIndex === index ? Style.text : Style.accent)
                        : Style.disabled(root.actionFocusIndex === index ? Style.text : Style.accent)
                    Accessible.role: Accessible.Button
                    Accessible.name: text
                    Accessible.onPressAction: root.activateAction(String(modelData.id))
                    font.family: Style.fontFamily
                    font.pixelSize: Style.textSm
                    font.weight: root.actionFocusIndex === index ? Style.weightBold : Style.weightMedium
                    font.underline: root.actionFocusIndex === index

                    MouseArea {
                        anchors.fill: parent
                        // Lifts a 14px label to a 24px-tall hit target.
                        anchors.margins: -Style.notificationActionHitMargin
                        cursorShape: parent.available ? Qt.PointingHandCursor : Qt.ArrowCursor
                        enabled: parent.available
                        onClicked: root.activateAction(String(parent.modelData.id))
                    }
                }
            }
        }

    }

    Divider {
        visible: root.showDivider
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        inset: Style.notificationDividerInset
        strength: 0.25
    }

    // Hover pauses expiry AND expands (one gesture, reported once); the
    // consumer decides what "paused" does. `target: null` because this
    // card's own response IS its height opening — scaling it too would
    // answer the same hover twice.
    StateLayer {
        id: layer
        anchors.fill: parent
        interactive: root.enabled && root.inputEnabled
        clickable: root.primaryActionAvailable || root.activatable
        target: null
        onClicked: {
            if (root.primaryActionAvailable)
                root.activatePrimary();
            else if (root.activatable)
                root.activated(root.entry);
        }
    }

    // The leading column (cursor and glyph) opens and closes the card when
    // hover does not; above the body layer, so the rest stays the action.
    StateLayer {
        id: leadLayer
        x: 0
        y: 0
        width: headline.x + Style.iconSm + Style.space2
        height: root.height - (root.bodied ? root.shadowRoom : 0)
        visible: !root.expandOnHover
        interactive: root.enabled && root.inputEnabled
        clickable: true
        target: null
        onClicked: root.expandRequested()
    }

    activeFocusOnTab: root.primaryActionAvailable && root.enabled && root.inputEnabled

    Keys.onPressed: event => {
        if (event.key !== Qt.Key_Return && event.key !== Qt.Key_Enter && event.key !== Qt.Key_Space)
            return;
        if (!root.primaryActionAvailable || !root.enabled || !root.inputEnabled)
            return;
        event.accepted = true;
        if (!event.isAutoRepeat)
            root.activatePrimary();
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: root.inputEnabled ? Qt.MiddleButton : Qt.NoButton
        onClicked: root.dismiss()
    }

    // Swipe-dismiss: horizontal, both directions, spring-back under the
    // threshold fraction of the card's own width — works on any urgency.
    transform: Translate {
        x: drag.active && !root.verticalDrag ? drag.translation.x : 0

        Behavior on x {
            NumberAnimation { duration: Motion.fast; easing.type: Motion.standardEasing }
        }
    }

    DragHandler {
        id: drag
        enabled: root.draggable && root.inputEnabled
        target: null
        xAxis.enabled: true
        yAxis.enabled: root.verticalDragEnabled && !root.expanded
        // Remember a completed horizontal swipe while the grab is active, so
        // dismissal does not depend only on the handler's terminal translation.
        onTranslationChanged: {
            if (active)
                root.swipeDismissPending = Math.abs(translation.x) > root.width * Style.notificationDismissFraction
                    && Math.abs(translation.x) >= Math.abs(translation.y);
        }
        onActiveChanged: {
            if (active) {
                root.swipeDismissPending = false;
                return;
            }
            if (!root.inputEnabled) {
                root.swipeDismissPending = false;
                return;
            }
            if (Math.abs(translation.y) > Math.abs(translation.x)) {
                if (Math.abs(translation.y) > Style.notificationExpandDragPx)
                    root.dragExpanded = translation.y > 0;
            } else if (root.swipeDismissPending
                    || Math.abs(translation.x) > root.width * Style.notificationDismissFraction) {
                root.dismiss();
            }
            root.swipeDismissPending = false;
        }
    }
}
