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
// shows its age and stops offering the action row. `swatch`, present, is a
// colour the icon box shows AS the icon instead of a fallback glyph — the card
// does not know or ask why.
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
    // Each entry is its own `surface` body with a slight shadow, so neighbours
    // never read as one run of text. False is the boxless row for a host that
    // draws its own container: the list cursor is then a tick, and the host
    // separates rows with `showDivider`.
    property bool bodied: true
    // The bodied card's corner radius.
    property real bodyRadius: Style.radiusBody
    // Hover expands a popup, which nothing scrolls. Inside a scrolled list
    // hover expansion steals the wheel under the pointer, so a list sets
    // false: the leading column then asks for expansion by click
    // (`expandRequested`), the rest of the card stays the card's action,
    // and an expanded body shows in full instead of scrolling inside itself.
    property bool expandOnHover: true
    // False when a heading above the card already names the app.
    property bool showAppName: true
    // The host says this entry has not been seen (a dot beside the app name)
    // and whether a plain click on the body should report `activated` when
    // there is no primary action to run.
    property bool unread: false
    property bool activatable: false
    // A list with its own cursor marks this card current: the accent tick
    // on a boxless card, the selected tint on a bodied one.
    property bool selected: false
    // Which of this entry's (at most 3) actions carries keyboard focus, or
    // -1 for none. A list owns one cursor for many cards and passes it down.
    property int actionFocusIndex: -1
    // The host's own expansion (the list's open row), separate from the
    // drag state below so a drag never replaces the host's binding.
    property bool hostExpanded: false
    // Toggled by a vertical drag past the threshold; additive to hover. Card
    // state only: a host asks for expansion through `hostExpanded`.
    property bool _dragExpanded: false
    property bool swipeDismissPending: false
    property double currentTimeMs: Date.now()
    // Defaults from the entry shape; a consumer whose entry does not carry a
    // swatch of its own (or which decides one under a rule the card cannot
    // see — an app name, say) overrides it directly.
    property var swatch: root.entry.swatch

    readonly property bool verticalDrag: drag.active && Math.abs(drag.translation.y) > Math.abs(drag.translation.x)
    readonly property bool dragActive: drag.active
    // The pointer is anywhere over the card. It is read on the card itself:
    // a handler on a layer stacked above another steals the hover from the one
    // below, and the leading column and the dismiss button both sit above.
    readonly property bool hovered: root.enabled && root.inputEnabled && cardHover.hovered
    readonly property bool primaryPressed: root.pressZone === "body" && (root.primaryActionAvailable || root.activatable)
    readonly property bool expansionAnimating: expansionAnimation.running
    readonly property bool expanded: root.expansionFrozen ? root.frozenExpanded
        : root.alwaysExpanded || (root.expandOnHover && root.hovered) || root.hostExpanded || root._dragExpanded || (root.entry.paused ?? false)
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
    Accessible.name: (root.unread ? "Unread. " : "") + (root.primaryActionAvailable
        ? `${root.primaryActionLabel}: ${root.entry.summary}`
        : `${root.entry.appName}: ${root.entry.summary}`)
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
    // A missing or undecodable file never claims the slot; the glyph stays.
    readonly property bool showsImage: !root.hasSwatch && iconImage.status === Image.Ready
    readonly property bool urgencyBadged: (root.hasSwatch || root.showsImage)
        && (root.entry.urgency === "critical" || root.entry.urgency === "low")
    // Urgency is carried by the glyph's shape first (triangle, bell, info) and
    // by its colour second: critical danger, low textMuted, normal plain text.
    // The moon belongs to do-not-disturb alone.
    readonly property string iconName: root.entry.urgency === "critical" ? "alert-triangle"
        : root.entry.urgency === "low" ? "info"
        : "bell"
    readonly property color glyphColor: root.entry.urgency === "critical" ? Style.danger
        : root.entry.urgency === "low" ? Style.textMuted
        : Style.text

    Timer {
        interval: Motion.clockRefresh
        repeat: true
        running: root.hasStamp
        onTriggered: root.currentTimeMs = Date.now()
    }

    // The preview shows two lines; its ceiling in pixels is
    // `notificationPreviewHeight`.
    readonly property int previewLines: 2

    // One format for every entry, live or archived: a list that mixed a clock
    // time with "5m ago" read as two columns of different widths. The wall
    // clock is the timestamp's accessible description.
    readonly property var stampMs: root.archived ? root.entry.archivedAt : root.entry.createdAt
    readonly property bool hasStamp: root.stampMs !== undefined && root.stampMs !== null

    function timestampText(): string {
        if (!root.hasStamp)
            return "";
        const seconds = Math.max(0, (root.currentTimeMs - root.stampMs) / 1000);
        if (seconds < 60)
            return "just now";
        if (seconds < 3600)
            return `${Math.floor(seconds / 60)}m ago`;
        if (seconds < 86400)
            return `${Math.floor(seconds / 3600)}h ago`;
        return `${Math.floor(seconds / 86400)}d ago`;
    }

    implicitWidth: Style.notificationWidth
    // The shadow falls into the host's gap between cards: the card's height
    // is its body's, so the gap a host sets is the gap a person sees.
    implicitHeight: root.expansionFrozen ? root.frozenHeight : root.restHeight
    readonly property bool hasBody: String(root.entry.body ?? "").length > 0
    readonly property bool hasDetails: root.hasBody
        || (root.showActions && !root.archived && root.actionList().length > 0)
    // One padding on all four sides; the glyph column is the headline's
    // height, and the text starts one gap past it.
    readonly property real pad: Style.space3
    readonly property real textColumn: Style.notificationTextColumn
    // A body line sits on the 4px rhythm, and the expanded viewport is a whole
    // number of lines so its last line is never cut through the middle.
    readonly property real bodyLine: Style.rhythm(Style.textSm * Style.lineBody)
    readonly property real bodyViewportHeight: Math.round(Style.notificationBodyViewportHeight / root.bodyLine) * root.bodyLine
    // A preview is as tall as its real lines; the token is the ceiling.
    readonly property real previewHeight: Math.min(Style.notificationPreviewHeight,
        root.pad + Style.iconLg + Style.space1 + bodyPreview.implicitHeight + root.pad)
    readonly property real restHeight: root.expanded && root.hasDetails
            ? root.pad + Style.iconLg + Style.space1 + details.implicitHeight + root.pad
        : root.hasBody ? root.previewHeight
        : Style.notificationCollapsedHeight
    readonly property bool leadHovered: leadHover.hovered
    readonly property bool dismissHovered: dismissHover.hovered && dismissButton.visible
    // The dismiss button takes the timestamp's place, so a card never changes
    // width under the pointer. Keyboard focus reveals it too.
    readonly property bool dismissShown: root.enabled && root.inputEnabled && (root.hovered || root.activeFocus)

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

    // The words under the headline, shared by the preview and the full body.
    component BodyText: Prose {
        role: "body"
        textFormat: Text.StyledText
        color: root.enabled ? Style.textMuted : Style.disabled(Style.textMuted)
        lineHeight: root.bodyLine
        lineHeightMode: Text.FixedHeight
        // The card's description carries the body once.
        Accessible.ignored: true
    }

    Surface {
        id: body
        anchors.fill: parent
        visible: root.bodied
        radius: root.bodyRadius
        base: Style.surface
        // A popup row answers hover by opening as well; the lift is the
        // colour half of it, so a row with nothing more to show still says
        // the pointer is on it.
        hovered: root.hovered
        pressed: root.primaryPressed
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

    // The content clips to the card (the height animates) while the body and
    // its shadow stay outside the clip, so the shadow keeps its full reach.
    Item {
        id: content
        anchors.fill: parent
        clip: true

        // The list cursor: a card in a list that keeps its own cursor shows
        // it here, thick and accent. Urgency has no tick (the glyph carries it),
        // and a bodied card shows selection on its body instead.
        SelectionMark {
            id: tick
            anchors.left: parent.left
            anchors.leftMargin: Style.space1
            anchors.verticalCenter: lead.verticalCenter
            shown: root.selected && !root.bodied
            strong: true
            markColor: root.enabled ? Style.accent : Style.disabled(Style.accent)
        }

        // The app's own icon when it sent one, the swatch when the consumer
        // decided this entry carries one, else the urgency glyph — all three
        // occupy the same box so the headline never reflows on arrival.
        Item {
            id: lead
            x: root.pad
            y: root.pad
            width: Style.iconLg
            height: Style.iconLg

            Rectangle {
                anchors.fill: parent
                visible: root.hasSwatch && !root.leadHovered
                radius: Style.radiusSm
                color: root.swatch ?? "transparent"
                border.width: Style.stroke(Style.indicatorWidth, root)
                border.color: Style.textMuted
            }

            Image {
                id: iconImage
                anchors.fill: parent
                visible: !root.leadHovered && root.showsImage
                source: root.iconSource
                sourceSize: Qt.size(width * 2, height * 2)
                asynchronous: true
                fillMode: Image.PreserveAspectFit
            }

            // The urgency glyph, or the chevron that says the leading column
            // opens the card while the pointer is on it.
            SvgIcon {
                anchors.centerIn: parent
                visible: root.leadHovered || (!root.hasSwatch && !root.showsImage)
                name: root.leadHovered ? (root.expanded ? "chevron-up" : "chevron-down") : root.iconName
                size: root.leadHovered ? Style.iconSm : Style.iconLg
                color: root.leadHovered ? Style.text
                    : root.enabled ? root.glyphColor : Style.disabled(root.glyphColor)
            }

            // An image or swatch carries no urgency, so a critical or low
            // entry keeps its glyph as a badge on the slot's corner, on a disc
            // of the card's own colour so it stands clear of what is under it.
            Loader {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.rightMargin: -Style.space1
                anchors.bottomMargin: -Style.space1
                active: root.urgencyBadged && !root.leadHovered
                sourceComponent: Rectangle {
                    width: Style.iconSm
                    height: width
                    radius: Style.radiusPill
                    color: root.bodied ? body.color : Style.band

                    SvgIcon {
                        anchors.centerIn: parent
                        name: root.iconName
                        size: Style.iconXs
                        color: root.enabled ? root.glyphColor : Style.disabled(root.glyphColor)
                    }
                }
            }
        }

        RowLayout {
            id: headline
            anchors.left: parent.left
            anchors.leftMargin: root.textColumn
            anchors.right: parent.right
            anchors.rightMargin: root.pad
            y: root.pad
            height: Style.iconLg
            spacing: Style.space2

            // A NAME, not a value — the technical face is reserved for numbers
            // and machine text.
            Prose {
                id: appNameLabel
                visible: root.showAppName
                Layout.fillHeight: true
                verticalAlignment: Text.AlignVCenter
                role: "supporting"
                text: root.entry.appName
                Layout.maximumWidth: (Style.notificationWidth - root.textColumn - root.pad) / 3
                color: root.enabled ? Style.textMuted : Style.disabled(Style.textMuted)
            }
            Rectangle {
                visible: root.unread
                width: Style.badgeDot
                height: width
                radius: Style.radiusPill
                color: Style.accent
                Accessible.ignored: true
            }
            Prose {
                Layout.fillWidth: true
                Layout.fillHeight: true
                verticalAlignment: Text.AlignVCenter
                role: "title"
                text: root.entry.summary
                // A bodied card answers a press with its body; a boxless one has only its title.
                color: !root.enabled ? Style.disabled(Style.text)
                    : root.primaryPressed && !root.bodied ? Style.accent : Style.text
            }

            // The age, which the dismiss button replaces while the pointer is on
            // the card; both take the one slot.
            Item {
                Layout.fillHeight: true
                Layout.preferredWidth: Math.ceil(Math.max(stamp.implicitWidth, Style.iconLg))

                Prose {
                    id: stamp
                    anchors.right: parent.right
                    // The slot's full height, centred inside it: a 14 px line centred
                    // by its own box would start on a quarter pixel. Whole pixels wide,
                    // so a right-aligned reading starts on the pixel grid.
                    height: parent.height
                    verticalAlignment: Text.AlignVCenter
                    width: Math.ceil(implicitWidth)
                    role: "metadata"
                    technical: true
                    text: root.timestampText()
                    opacity: root.dismissShown ? 0 : 1
                    Accessible.description: root.hasStamp
                        ? Qt.formatDateTime(new Date(root.stampMs), "ddd d MMM hh:mm") : ""
                    color: root.enabled ? Style.textMuted : Style.disabled(Style.textMuted)

                    Behavior on opacity {
                        NumberAnimation { duration: Motion.micro; easing.type: Motion.standardEasing }
                    }
                }

                // The same `dismiss()` as the swipe, the middle click and a
                // host's Delete key; a disc one step above the card says it is
                // pressable and the glyph is what it does.
                Item {
                    id: dismissButton
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: Style.iconLg
                    height: Style.iconLg
                    opacity: root.dismissShown ? 1 : 0
                    // Pressable the moment it is asked for, not once the fade has begun.
                    visible: root.dismissShown || opacity > 0

                    Accessible.role: Accessible.Button
                    Accessible.name: "Dismiss"
                    Accessible.onPressAction: root.dismiss()

                    Behavior on opacity {
                        NumberAnimation { duration: Motion.micro; easing.type: Motion.standardEasing }
                    }

                    Surface {
                        anchors.fill: parent
                        radius: Style.radiusPill
                        base: Style.overlay
                        hovered: root.dismissHovered
                        pressed: root.pressZone === "dismiss"
                        opacity: root.dismissHovered ? 1 : 0

                        Behavior on opacity {
                            NumberAnimation { duration: Motion.micro; easing.type: Motion.standardEasing }
                        }
                    }

                    SvgIcon {
                        anchors.centerIn: parent
                        name: "x"
                        size: Style.iconSm
                        color: root.dismissHovered ? Style.text : Style.textMuted
                    }

                    HoverHandler {
                        id: dismissHover
                        cursorShape: Qt.PointingHandCursor
                    }
                }
            }
        }

        BodyText {
            id: bodyPreview
            anchors.left: headline.left
            anchors.right: headline.right
            anchors.top: headline.bottom
            anchors.topMargin: Style.space1
            height: Math.min(implicitHeight, Style.notificationPreviewHeight - root.pad * 2 - headline.height - Style.space1)
            // Preview and full body start on the same line and cross-fade on
            // the card's own height token, so opening reveals lines rather
            // than swapping one text for another.
            opacity: root.expanded && root.hasDetails ? 0 : 1
            visible: opacity > 0 && root.hasBody
            Behavior on opacity {
                NumberAnimation { duration: Motion.fast; easing.type: Motion.emphasizedEasing }
            }
            text: root.entry.body ?? ""
            maximumLineCount: root.previewLines
            clip: true
        }

        ColumnLayout {
            id: details
            anchors.left: headline.left
            anchors.right: headline.right
            anchors.top: headline.bottom
            anchors.topMargin: Style.space1
            spacing: Style.space1
            opacity: root.expanded ? 1 : 0
            // Visible the moment it is asked for: an invisible layout reports
            // no height, and the card sizes itself from this one.
            visible: (root.expanded || opacity > 0) && root.hasDetails
            Behavior on opacity {
                NumberAnimation { duration: Motion.fast; easing.type: Motion.emphasizedEasing }
            }

            Item {
                id: bodyViewportHost
                Layout.fillWidth: true
                visible: root.hasBody
                implicitHeight: root.expandOnHover
                    ? Math.min(bodyText.implicitHeight, root.bodyViewportHeight)
                    : bodyText.implicitHeight

                Flickable {
                    id: bodyViewport
                    anchors.fill: parent
                    clip: true
                    // The wheel scrolls it (below); a press on the body stays the
                    // card's own, so a swipe or a tap that starts on the text works.
                    interactive: false
                    boundsBehavior: Flickable.StopAtBounds
                    contentWidth: width
                    contentHeight: bodyText.implicitHeight
                    flickableDirection: Flickable.VerticalFlick

                    BodyText {
                        id: bodyText
                        width: bodyViewport.width
                        text: root.entry.body ?? ""
                    }
                }

                // A popup body that is longer than its viewport says so.
                ScrollCue {
                    view: bodyViewport
                    fadeColor: root.bodied ? body.color : Style.band
                    indicator: false
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

                    Prose {
                        id: actionLabel
                        required property var modelData
                        required property int index
                        readonly property bool available: root.enabled && root.inputEnabled
                            && !(modelData.disabled ?? false)
                        readonly property bool focusedAction: root.actionFocusIndex === index
                        enabled: available
                        // Addressable by a consumer or a test without exposing a
                        // repeater handle from the card's own public interface.
                        objectName: "notificationAction" + index
                        text: modelData.label ?? String(modelData)
                        color: !available ? Style.disabled(focusedAction ? Style.text : Style.accent)
                            : focusedAction || actionHit.containsMouse ? Style.text : Style.accent
                        Accessible.role: Accessible.Button
                        Accessible.name: text
                        Accessible.onPressAction: root.activateAction(String(modelData.id))
                        font.weight: focusedAction ? Style.weightBold : Style.weightMedium
                        font.underline: focusedAction

                        MouseArea {
                            id: actionHit
                            anchors.fill: parent
                            // Lifts a 12px label to a 24px-tall hit target.
                            anchors.margins: -Style.notificationActionHitMargin
                            hoverEnabled: true
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
        }
    }

    // Hover pauses expiry AND expands (one gesture, reported once); the
    // consumer decides what "paused" does. The layer only paints the keyboard
    // ring and answers to the card's own state: a layer with handlers of its own,
    // stacked above the content, would take the hover from the dismiss button
    // and the action labels under it. The card is the focus holder (Tab stop).
    // `growth` goes unused because this card's own response IS its height
    // opening; growing it too would answer the same hover twice.
    StateLayer {
        id: layer
        host: root
        anchors.fill: parent
        interactive: root.enabled && root.inputEnabled
        focused: root.activeFocus
        focusRadius: root.bodied ? root.bodyRadius : 0
    }

    HoverHandler {
        id: cardHover
        cursorShape: root.primaryActionAvailable || root.activatable ? Qt.PointingHandCursor : Qt.ArrowCursor
    }

    // Which part of the card a point of it falls on: the leading column that
    // opens it when hover does not, the dismiss button, or the body.
    function zoneAt(point: point): string {
        if (leadZone.visible && point.x < leadZone.width)
            return "lead";
        if (dismissButton.visible && dismissButton.contains(dismissButton.mapFromItem(root, point)))
            return "dismiss";
        return "body";
    }

    // ONE tap, routed by where it lands: a click on the leading column must not
    // also be the card's action (it marked an unread entry read while the person
    // was only opening it to read), nor a click on the dismiss button. The press
    // zone is read from where the press began.
    readonly property string pressZone: bodyTap.pressed ? root.zoneAt(bodyTap.point.pressPosition) : ""
    TapHandler {
        id: bodyTap
        enabled: root.enabled && root.inputEnabled
        onTapped: eventPoint => {
            const zone = root.zoneAt(eventPoint.position);
            if (zone === "lead")
                root.expandRequested();
            else if (zone === "dismiss")
                root.dismiss();
            else if (root.primaryActionAvailable)
                root.activatePrimary();
            else if (root.activatable)
                root.activated(root.entry);
        }
    }

    // The leading column's own hover (the chevron and the hand) is read from
    // an item that sits there and answers nothing else.
    Item {
        id: leadZone
        width: lead.x + lead.width + Style.space3
        height: root.height
        visible: !root.expandOnHover

        HoverHandler {
            id: leadHover
            enabled: root.enabled && root.inputEnabled
            cursorShape: Qt.PointingHandCursor
        }
    }

    activeFocusOnTab: root.primaryActionAvailable && root.enabled && root.inputEnabled

    Keys.onPressed: event => {
        if (!root.enabled || !root.inputEnabled)
            return;
        if (event.key === Qt.Key_Delete || event.key === Qt.Key_Backspace || event.key === Qt.Key_Escape) {
            event.accepted = true;
            root.dismiss();
            return;
        }
        if (event.key !== Qt.Key_Return && event.key !== Qt.Key_Enter && event.key !== Qt.Key_Space)
            return;
        if (!root.primaryActionAvailable)
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
    // threshold fraction of the card's own width — works on any urgency. The
    // card follows the pointer one to one while it is held and eases home
    // only once it is let go.
    property real _swipeOffset: 0
    // Set before the offset moves, in this order, so the ease runs on release
    // and never during the drag.
    property bool _swipeHeld: false
    transform: Translate {
        x: root._swipeOffset

        Behavior on x {
            enabled: !root._swipeHeld
            NumberAnimation { duration: Motion.fast; easing.type: Motion.standardEasing }
        }
    }

    DragHandler {
        id: drag
        enabled: root.draggable && root.inputEnabled
        target: null
        xAxis.enabled: true
        yAxis.enabled: root.verticalDragEnabled
        // Remember a completed horizontal swipe while the grab is active, so
        // dismissal does not depend only on the handler's terminal translation.
        onTranslationChanged: {
            if (!active)
                return;
            const horizontal = Math.abs(translation.x) >= Math.abs(translation.y);
            root._swipeOffset = horizontal ? translation.x : 0;
            root.swipeDismissPending = horizontal && Math.abs(translation.x) > root.width * Style.notificationDismissFraction;
        }
        onActiveChanged: {
            root._swipeHeld = active;
            if (active) {
                root.swipeDismissPending = false;
                return;
            }
            root._swipeOffset = 0;
            if (!root.inputEnabled) {
                root.swipeDismissPending = false;
                return;
            }
            if (Math.abs(translation.y) > Math.abs(translation.x)) {
                if (Math.abs(translation.y) > Style.notificationExpandDragPx)
                    root._dragExpanded = translation.y > 0;
            } else if (root.swipeDismissPending
                    || Math.abs(translation.x) > root.width * Style.notificationDismissFraction) {
                root.dismiss();
            }
            root.swipeDismissPending = false;
        }
    }
}
