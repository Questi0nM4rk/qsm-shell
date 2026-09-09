import QtQuick
import QtQuick.Templates as T

import qs.QsmShell.Style

// THE text input. One line, every state, two slots.
//
// It replaced `SearchField`, which was this component plus a magnifier plus
// four booleans naming which keys the launcher wanted to steal. A search box
// is a text box with an icon in its leading slot; it is not a second kind of
// text box, and the moment a second surface needed a plain one the library
// would have grown a third.
//
// It stands on `T.Control` with a `TextInput` in a clipped `contentItem`, the
// shape Qt's own `T.SpinBox` uses. A `T.TextField` root cannot host slots: it
// scrolls its glyphs UNDER its own padding rather than clipping them at the
// padding edge (measured -- with `leftPadding: 60` and a value twice the box
// wide, the first glyph sits at x = -206), and the padding is exactly where a
// leading magnifier or a trailing reveal has to live.
//
// ── keys ─────────────────────────────────────────────────────────────────
// A text input sits in the middle of a keyboard argument it cannot settle:
// Up and Down might move a cursor or move a selection in the list below;
// Left might move a caret or leave a drilled-in view; Tab might indent or
// move on. Only the surface knows.
//
// So there is ONE hook. `keyPressed` fires before anything else happens, with
// the real event; a consumer that sets `event.accepted = true` has taken the
// key and the field does nothing further with it. Everything the field does
// NOT hear back about, it handles itself: Return accepts, Escape escapes, Up
// and Down are reported as `moveUp` / `moveDown` for the list that usually
// sits under a field like this.
//
// That is one mechanism instead of four flags, and it covers the fifth key
// the flags did not anticipate.
T.Control {
    id: root

    property string placeholder: ""
    property alias text: input.text
    // sm | md | lg
    property string size: "md"
    // text | password | number. A search box is still `text` with a
    // magnifier in its leading slot -- search is not an input type.
    property string inputType: "text"
    // Non-empty paints the failure. The message itself belongs to `Field`.
    property bool failed: false
    property alias readOnly: input.readOnly
    // A password stays a password -- including its input-method hints -- while
    // its host decides whether a trailing reveal action shows the text.
    property bool passwordVisible: false

    // ── slots ───────────────────────────────────────────────────────────
    property alias leading: leadingSlot.data
    property alias trailing: trailingSlot.data
    property int leadingCursorShape: Qt.IBeamCursor
    property int trailingCursorShape: Qt.PointingHandCursor

    // ── the one key hook ────────────────────────────────────────────────
    // Fires first, with the live event. Accept it to take the key.
    signal keyPressed(var event)

    signal accepted
    signal escaped
    signal edited(string text)
    signal moveUp
    signal moveDown
    // A hover-enter is not allowed to claim a selection while someone is
    // typing; the consumer owns that rule and the field only reports that
    // the text changed under the keyboard.
    signal selectionClaimed

    // The input's own validity, surfaced so a HOST decides what "not a
    // number yet" means. `acceptableInput` being false never paints `failed`
    // on its own; the host reads it and owns the error copy.
    readonly property bool acceptableInput: input.acceptableInput

    // Host-overridable validator. The binding defaults to the built-in
    // `number` validator (any double, no hardcoded range); assigning your own
    // validator replaces the binding. `text` and `password` validate nothing.
    // `var` because Qt Quick registers no `Validator` type -- only the
    // concrete `DoubleValidator` / `IntValidator` /
    // `RegularExpressionValidator`.
    property var validator: inputType === "number" ? numericValidator : null

    // Host-overridable input-method hints; the default derives from the
    // input type, so a `number` field asks for a formatted-numbers pad and a
    // `password` field hides text and suppresses prediction.
    property int inputMethodHints: inputType === "number"
        ? Qt.ImhFormattedNumbersOnly
        : inputType === "password"
            ? Qt.ImhHiddenText | Qt.ImhSensitiveData | Qt.ImhNoPredictiveText
            : 0

    readonly property bool _sm: size === "sm"
    readonly property bool _lg: size === "lg"
    readonly property bool _password: inputType === "password"
    readonly property int fieldTextSize: _sm ? Style.textSm : _lg ? Style.textLg : Style.textMd
    readonly property bool focused: input.activeFocus

    // ── actions: the one route for pointer, keyboard and menus ──────────
    // The one semantic accept entry point: Return/Enter, the Accept action and
    // a consumer accepting programmatically all call it. Emits `accepted` only
    // when the current text is acceptable, and reports whether it did.
    function accept(): bool {
        if (!root.enabled || !input.acceptableInput)
            return false;
        root.accepted();
        return true;
    }
    function clear(): void { input.clear(); root.edited(input.text); }
    function toggleReveal(): void { root.passwordVisible = !root.passwordVisible; }
    function selectAll(): void { input.selectAll(); }

    // What a consumer's action menu renders for this field. Shortcuts are
    // never set here: which key means what is the surface's call.
    readonly property list<T.Action> actions: [
        T.Action { text: "Accept"; enabled: root.enabled && input.acceptableInput; onTriggered: root.accept() },
        T.Action { text: "Clear"; enabled: root.enabled && !input.readOnly && input.length > 0; onTriggered: root.clear() },
        T.Action {
            text: "Reveal"
            enabled: root.enabled && root._password
            checkable: true
            checked: root.passwordVisible
            onTriggered: root.toggleReveal()
        },
        T.Action {
            text: "Select all"
            enabled: root.enabled && input.length > 0
            onTriggered: root.selectAll()
        }
    ]

    // The built-in `number` validator. Any double: the Qt defaults are an
    // unbounded range, so nothing is hardcoded here -- a host that wants a
    // range or an integer supplies its own validator through `validator`.
    DoubleValidator {
        id: numericValidator
        notation: DoubleValidator.StandardNotation
    }

    // How wide the field wants to be when nothing tells it. A text box's
    // preferred width is a CONSTANT, never its content: the first version fed
    // the input's own implicit width into this sum, so typing stretched the
    // box across the screen instead of scrolling inside itself.
    property real naturalWidth: Style.notificationWidth

    implicitWidth: Math.max(naturalWidth, leftPadding + rightPadding)
    implicitHeight: _sm ? Style.controlHeightSm : _lg ? Style.controlHeightLg : Style.controlHeight

    // Padding is where the slots sit, and the template owns the arithmetic
    // from here: the contentItem gets exactly what is left over.
    leftPadding: Style.space3 + (leadingSlot.hasContent ? leadingSlot.implicitWidth + Style.space2 : 0)
    rightPadding: Style.space3 + (trailingSlot.hasContent ? trailingSlot.implicitWidth + Style.space2 : 0)

    hoverEnabled: true
    // Focus lands on the INPUT, never on the frame: the frame forwards it
    // below, so a caller reaching for the public `forceActiveFocus()` gets a
    // caret rather than a control that swallowed the keyboard.
    focusPolicy: Qt.NoFocus
    opacity: enabled ? 1 : Style.opacityDisabled

    background: Rectangle {
        objectName: "textFieldSurface"
        radius: Style.radiusMd
        // Hover and press are answered by the SURFACE, not by growth. Every
        // other control in the library grows, and a text box must not: the
        // caret and the text have to stay where the eye put them, and a field
        // that jumps under the pointer is a field you cannot aim a click into.
        // A read-only field REPORTS; it is not a target, and lifting under the
        // pointer told a person it was one. They clicked, got no caret, typed,
        // and the keystrokes vanished. `StateLayer` already stops answering
        // while read-only, so the surface has to agree with it. Focus still
        // lifts: a read-only value is selectable and copyable.
        color: root.focused || (root.hovered && !input.readOnly)
            ? Style.surfaceHover
            : Style.surface
        // The one border in the library, and it means one thing: this field
        // FAILED. Invisible otherwise. It used to double as the focus edge,
        // which drew one state twice -- `StateLayer` owns the focus ring, so a
        // focused-and-failed field would have painted a danger border under an
        // accent ring and said "failed" in a channel already spoken for.
        // Pointer focus is the surface lift plus the caret; keyboard focus is
        // the ring.
        border.width: root.failed ? 1 : 0
        border.color: Style.danger

        Behavior on color {
            ColorAnimation { duration: Motion.micro; easing.type: Motion.standardEasing }
        }
        Behavior on border.color {
            ColorAnimation { duration: Motion.micro; easing.type: Motion.standardEasing }
        }
    }

    // Does this slot hold anything? Counting children answered the wrong
    // question, because a `Loader` never gives its footprint back: measured,
    // a Loader that unloads still reports implicit 24x24 with `item` null, so
    // a trailing action that switched itself off went on reserving an
    // action's width beside an empty value -- and an empty slot takes no
    // space. A child that loads its content counts once it HAS it; any other
    // child counts by being there.
    //
    // Geometry is deliberately NOT read here. Asking a child for its `width`
    // or even its `visible` puts a per-child read inside the binding that
    // sizes their own parent, and Qt then reports a binding loop on the
    // slot's `implicitWidth` (measured: appears as soon as `visible` is read,
    // gone when it is not). The Loader's `item` is the one honest signal that
    // does not go through layout.
    //
    // `slot` is untyped on purpose: `children` is a list of `Item`, and
    // neither `sourceComponent` nor `item` is a member of `Item`.
    function _slotHasContent(slot): bool {
        for (let i = 0; i < slot.children.length; i++) {
            const child = slot.children[i];
            if (child.sourceComponent === undefined)
                return true;
            if (child.item !== null)
                return true;
        }
        return false;
    }

    // The slots live in the padding, outside the clipped content, so a glyph
    // is never scrolled over by the text.
    Item {
        id: leadingSlot
        readonly property bool hasContent: root._slotHasContent(leadingSlot)
        x: Style.space3
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: hasContent ? childrenRect.width : 0
        implicitHeight: hasContent ? childrenRect.height : 0
        width: implicitWidth
        height: implicitHeight
    }

    Item {
        id: trailingSlot
        readonly property bool hasContent: root._slotHasContent(trailingSlot)
        anchors.right: parent.right
        anchors.rightMargin: Style.space3
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: hasContent ? childrenRect.width : 0
        implicitHeight: hasContent ? childrenRect.height : 0
        width: implicitWidth
        height: implicitHeight
    }

    contentItem: Item {
        // Long text scrolls INSIDE the box; it never stretches it. Without the
        // clip, overflowing glyphs painted past the field's rounded edge.
        clip: true

        Prose {
            id: placeholder
            anchors.fill: parent
            visible: input.length === 0
            role: "label"
            muted: true
            font.pixelSize: root.fieldTextSize
            verticalAlignment: Text.AlignVCenter
            text: root.placeholder
        }

        TextInput {
            id: input
            objectName: "textFieldInput"
            anchors.fill: parent
            enabled: root.enabled
            // A keyboard-first surface travels by Tab. The input is the
            // focusable thing here, so the tab stop lives on it -- it is
            // skipped automatically while disabled.
            activeFocusOnTab: true
            color: Style.text
            selectionColor: Style.accent
            selectedTextColor: Style.background
            verticalAlignment: TextInput.AlignVCenter
            font.family: Style.fontFamily
            font.pixelSize: root.fieldTextSize
            // The validator and the method hints travel together with the
            // input type. `validator` is host-overridable but defaults to the
            // built-in number validator; the hints ask the platform keyboard
            // for the right pad.
            validator: root.validator
            inputMethodHints: root.inputMethodHints
            // The password is ALWAYS masked, including the character being
            // typed. Echo-on-edit was tried first because hiding the very
            // first keystroke read as a dead field, but it revealed the WHOLE
            // password while the field was being edited -- and since the dots
            // turned into letters under the caret, it read as if typing wiped
            // the text. A password that stops being a password exactly while a
            // person works on it is not one.
            echoMode: root._password && !root.passwordVisible
                ? TextInput.Password
                : TextInput.Normal
            // The right inset is what keeps the caret legible at the end of a
            // long value: without it the insertion point pins flush against
            // the clip edge and the bar loses half of itself off-screen.
            rightPadding: Style.spaceTight
            // The library draws its own caret (see `caret` below). The stock
            // one is a 1px line that hides during fast typing and loses itself
            // against the scroll edge; nothing here controls that, so it
            // renders nothing and the overlay takes over.
            cursorDelegate: Item {}

            // The one place in the frame that sees a press on the TEXT: the
            // input accepts that press itself, so no ancestor handler hears
            // it. Focus arrives on the press here and nowhere else, so this is
            // the only point the pointer route marks. A handler is delivered
            // before its own item and this one only takes a PASSIVE grab, so
            // the press still reaches the input and drag-selection survives.
            TapHandler {
                onPressedChanged: if (pressed) root._focusOffTheKeyChain = true
            }

            onTextEdited: {
                root.selectionClaimed();
                root.edited(text);
            }

            // Losing focus forgets how the last focus arrived, so the next
            // arrival is judged on its own route.
            onActiveFocusChanged: if (!input.activeFocus) root._focusOffTheKeyChain = false

            // ONE dispatcher, and the reason is measured rather than
            // stylistic: `Keys.onPressed` and the per-key handlers
            // (`Keys.onDownPressed` and friends) hang off the SAME
            // attached object, and accepting the event in the generic one
            // does not stop the specific one from running. The first
            // version of this component had both, and a consumer that
            // claimed Down got its own handler AND `moveDown` — a
            // launcher list that moved two rows per keystroke.
            // `tests/units/tst_TextField.qml` is that bug, kept.
            //
            // So the hook fires, and if it did not take the key this
            // decides what the key means. No ordering to depend on.
            Keys.onPressed: event => {
                root.keyPressed(event);
                if (event.accepted)
                    return;

                switch (event.key) {
                case Qt.Key_Up:
                    root.selectionClaimed();
                    root.moveUp();
                    event.accepted = true;
                    break;
                case Qt.Key_Down:
                    root.selectionClaimed();
                    root.moveDown();
                    event.accepted = true;
                    break;
                case Qt.Key_Return:
                case Qt.Key_Enter:
                    root.selectionClaimed();
                    root.accept();
                    event.accepted = true;
                    break;
                case Qt.Key_Escape:
                    root.escaped();
                    event.accepted = true;
                    break;
                default:
                    // Everything else is typing, and typing belongs to the
                    // input. Leaving it unaccepted is what lets the caret,
                    // selection and clipboard keys keep working.
                    break;
                }
            }
        }

        // The insertion point, drawn by the field itself. Qt's caret blinks
        // away during fast typing and, at the scroll edge of a long value,
        // sits flush against the trailing action where a 1px line is hard to
        // read. `cursorRectangle` always reports where the caret really is, so
        // an accent bar at that spot survives long text and a held key -- the
        // two cases the stock caret loses.
        //
        // Moving it shows it solid for one half-cycle, so the mark a person is
        // steering never blinks out from under them mid-move. The blink period
        // is the platform's; a platform that turns blinking off reports zero
        // and the timer stays down.
        Rectangle {
            id: caret
            objectName: "textFieldCaret"
            property bool holdSolid: false
            readonly property int halfPeriod: Application.styleHints.cursorFlashTime / 2
            x: input.x + input.cursorRectangle.x
            y: input.y + input.cursorRectangle.y
            width: Style.spaceTight
            height: input.cursorRectangle.height
            color: Style.accent
            radius: Style.radiusXs
            visible: input.activeFocus && !input.readOnly

            onVisibleChanged: opacity = 1

            Connections {
                target: input
                function onCursorPositionChanged(): void {
                    caret.opacity = 1;
                    caret.holdSolid = true;
                    holdTimer.restart();
                }
            }

            Timer {
                id: holdTimer
                interval: caret.halfPeriod
                onTriggered: caret.holdSolid = false
            }

            Timer {
                running: caret.visible && !caret.holdSolid
                    && caret.halfPeriod > 0 && !Style.reducedMotion
                repeat: true
                interval: caret.halfPeriod
                onTriggered: caret.opacity = caret.opacity === 1 ? 0 : 1
            }

            Behavior on x {
                NumberAnimation { duration: Motion.press; easing.type: Motion.standardEasing }
            }
        }
    }

    // The five states, owned in one place. Host mode: hovered, pressed and the
    // enabled cascade come from the control itself, so there is one source of
    // every state. `target: null` because nothing here scales.
    StateLayer {
        id: layer
        objectName: "textFieldLayer"
        anchors.fill: parent
        target: null
        host: root
        // `enabled` alone. A read-only field is still a tab stop -- its value
        // can be selected and copied -- and the layer owns the ring, so
        // gating the layer on editability took the ring off the one route
        // that has nothing else to say where it is. The no-lift-while-
        // read-only rule lives in the background binding, where the pointer
        // states are answered.
        interactive: root.enabled
        focused: root.keyboardFocused
        focusRadius: Style.radiusMd
        focusColor: root.failed ? Style.danger : Style.accent
    }

    // The ring is a KEYBOARD mark: a pointer already says where it is, and a
    // ring under the hand that put it there is noise. Qt will not tell us how
    // focus arrived -- `Item` has no `focusReason` in QML, and a `T.Control`
    // records reasons only for its OWN focus events, never for a descendant's
    // -- so the routes that are not the key chain mark themselves. Each marks
    // at the point where it HANDS focus over, never merely where a press
    // landed: a press that ends in a drag or a long press hands over nothing,
    // and a mark left behind by one would have swallowed the ring on the next
    // Tab in. What is left unmarked is Tab and Backtab. Programmatic focus --
    // `forceActiveFocus()` on the frame, `focus: true`, a shortcut that ends
    // in either -- arrives through `onActiveFocusChanged` below and is marked
    // as pointer-like: the caller already knows where it sent the caret.
    //
    // Not named `visualFocus`: `T.Control` already has one (always false here,
    // `focusPolicy` is `NoFocus`) and a shadow would be a duplicate property.
    property bool _focusOffTheKeyChain: false
    readonly property bool keyboardFocused: input.activeFocus && !_focusOffTheKeyChain

    // `forceActiveFocus()` on the frame means "put the caret in this field".
    // A plain T.Control keeps that focus for itself, so the frame hands it on.
    onActiveFocusChanged: {
        if (!root.activeFocus)
            return;
        root._focusOffTheKeyChain = true;
        input.forceActiveFocus();
    }

    TapHandler {
        // Tapping the padding focuses the input; slot actions sit above and
        // take their own taps first. A tap on the text never reaches here --
        // the input accepts that press itself -- which is why a `TapHandler`
        // inside `input` marks that route instead.
        onTapped: {
            root._focusOffTheKeyChain = true;
            input.forceActiveFocus(Qt.MouseFocusReason);
        }
    }

    // The cursor describes the region under it, not the outer component: a
    // clickable glyph that still shows a text cursor denies its own action.
    //
    // A HoverHandler, not a filling MouseArea. The MouseArea this replaced was
    // the frontmost item in the frame with `hoverEnabled`, so it consumed hover
    // from the slot actions underneath and their `StateLayer`s never grew --
    // press and click survived, and the one state that says "this is a target"
    // went missing. A hover reader belongs on the ANCESTOR of the surfaces,
    // where it coexists with theirs instead of stacking on top of them.
    HoverHandler {
        id: cursorReader
        cursorShape: {
            const point = cursorReader.point.position;
            if (leadingSlot.contains(leadingSlot.mapFromItem(root, point)))
                return root.leadingCursorShape;
            return trailingSlot.contains(trailingSlot.mapFromItem(root, point))
                ? root.trailingCursorShape
                : Qt.IBeamCursor;
        }
    }
}
