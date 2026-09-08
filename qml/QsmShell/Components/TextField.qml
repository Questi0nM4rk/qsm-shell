import QtQuick
import QtQuick.Layouts

import qs.QsmShell.Style

// THE text input. One line, every state, two slots.
//
// It replaced `SearchField`, which was this component plus a magnifier plus
// four booleans naming which keys the launcher wanted to steal. A search box
// is a text box with an icon in its leading slot; it is not a second kind of
// text box, and the moment a second surface needed a plain one the library
// would have grown a third.
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
Rectangle {
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
    property bool readOnly: false
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

    function focusField(): void { input.forceActiveFocus(); }
    function setText(value: string): void { input.text = value; }
    function selectAll(): void { input.selectAll(); }
    // The one semantic accept entry point: Return/Enter, and a consumer that
    // wants to accept programmatically, both call it. Emits `accepted` only
    // when the current text is acceptable and reports whether it did.
    function accept(): bool {
        if (!root.enabled || !input.acceptableInput)
            return false;
        root.accepted();
        return true;
    }

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
    // box across the screen instead of scrolling inside itself. The slots may
    // demand more than the default; the characters typed into the middle never
    // do. A consumer gives the field an explicit width or lets the layout
    // decide; the field reports one fixed resting size either way.
    property real naturalWidth: Style.notificationWidth

    implicitHeight: _sm ? Style.controlHeightSm : _lg ? Style.controlHeightLg : Style.controlHeight
    implicitWidth: Math.max(naturalWidth,
        leadingSlot.implicitWidth + trailingSlot.implicitWidth
            + Style.space3 * 4)
    radius: Style.radiusMd
    opacity: enabled ? 1 : Style.opacityDisabled

    // Hover and press are answered by the SURFACE, not by growth. Every other
    // control in the library grows, and a text box must not: the caret and the
    // text have to stay where the eye put them, and a field that jumps under
    // the pointer is a field you cannot aim a click into. So the layer owns
    // the states — the five exist and are defined — and the response is a
    // lift in the ground rather than a change in size.
    color: layer.hovered || root.focused ? Style.surfaceHover : Style.surface

    Behavior on color {
        ColorAnimation { duration: Motion.micro; easing.type: Motion.standardEasing }
    }

    // The one border in the library, and it earns it: a text box is the only
    // control whose EDGE is the affordance — it says "your typing goes inside
    // this". It stays invisible at rest (the shell paints no boxes), appears
    // on focus, and turns on failure.
    border.width: root.failed || root.focused ? 1 : 0
    border.color: root.failed ? Style.danger : Style.accent

    Behavior on border.color {
        ColorAnimation { duration: Motion.micro; easing.type: Motion.standardEasing }
    }

    RowLayout {
        id: row
        anchors.fill: parent
        anchors.leftMargin: Style.space3
        anchors.rightMargin: Style.space3
        // One step less than the box margin: a spacing step is the air the
        // scroll-end caret keeps from the trailing action, and the owner's
        // live ruler read the full step as too much room. Both sides shrink
        // together, so the leading-to-text rhythm stays equal to the
        // text-to-action rhythm.
        spacing: Style.space2

        Item {
            id: leadingSlot
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: children.length > 0 ? childrenRect.width : 0
            implicitHeight: children.length > 0 ? childrenRect.height : 0
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            // Long text scrolls INSIDE the box; it never stretches it. Without
            // the clip, overflowing glyphs painted past the field's rounded
            // edge.
            clip: true

            Prose {
                id: placeholder
                anchors.fill: parent
                visible: input.text.length === 0
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
                readOnly: root.readOnly
                // A keyboard-first surface travels by Tab. The input is the
                // focusable thing here (the root Rectangle is not a focus
                // scope), so the tab stop lives on it -- it is skipped
                // automatically while disabled.
                activeFocusOnTab: true
                color: Style.text
                selectionColor: Style.accent
                selectedTextColor: Style.background
                verticalAlignment: TextInput.AlignVCenter
                font.family: Style.fontFamily
                font.pixelSize: root.fieldTextSize
                // The validator and the method hints travel together with the
                // input type. `validator` is host-overridable but defaults to
                // the built-in number validator; the hints ask the platform
                // keyboard for the right pad.
                validator: root.validator
                inputMethodHints: root.inputMethodHints
                // The password is ALWAYS masked, including the character being
                // typed. Echo-on-edit was tried first because hiding the very
                // first keystroke read as a dead field, but it revealed the
                // WHOLE password while the field was being edited -- and since
                // the dots turned into letters under the caret, it read as if
                // typing wiped the text. A password that stops being a password
                // exactly while a person works on it is not one.
                echoMode: root._password && !root.passwordVisible
                    ? TextInput.Password
                    : TextInput.Normal
                // The right inset is what keeps the caret legible at the end
                // of a long value: without it the insertion point pins flush
                // against the trailing action (and the row spacing alone reads
                // as no air at all). The live ruler came back with one spacing
                // step on the button -- the caret should land where the text
                // would if the box were endless, not a third of the box back.
                // So the inset is only as deep as needed to keep the full 2px
                // bar on-screen past the clip: the scroll-end caret shows all
                // of itself exactly one row-spacing step from the action.
                rightPadding: Style.spaceTight
                clip: true
                // The library draws its own caret (see `caret` below). The
                // stock one is a 1px line that hides during fast typing and
                // loses itself against the scroll edge; nothing here controls
                // that, so it renders nothing and the overlay takes over.
                cursorDelegate: Item {}

                onTextEdited: {
                    root.selectionClaimed();
                    root.edited(text);
                }

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

            // The insertion point, drawn by the field itself. Qt's caret
            // blinks away during fast typing and, at the scroll edge of a
            // long value, sits flush against the trailing action where a 1px
            // line is hard to read. `cursorRectangle` always reports where
            // the caret really is, so an accent bar at that spot survives
            // long text and a held key -- the two cases the stock caret loses.
            Rectangle {
                id: caret
                objectName: "textFieldCaret"
                x: input.x + input.cursorRectangle.x
                y: input.y + input.cursorRectangle.y
                width: 2
                height: input.cursorRectangle.height
                color: Style.accent
                radius: 1
                visible: input.activeFocus
            }
        }

        Item {
            id: trailingSlot
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: children.length > 0 ? childrenRect.width : 0
            implicitHeight: children.length > 0 ? childrenRect.height : 0
        }
    }

    // Clicking anywhere in the box puts the caret in it. Without this the
    // person has to hit the text itself, which on an empty field is a
    // zero-width target sitting behind a placeholder.
    //
    // `target: null` because nothing here scales, and the I-beam rather than
    // the pointing hand because this is a place to type, not a thing to press.
    StateLayer {
        id: layer
        anchors.fill: parent
        target: null
        interactive: root.enabled && !root.readOnly
        focused: root.focused
        focusRadius: root.radius
        focusColor: root.failed ? Style.danger : Style.accent
        onClicked: input.forceActiveFocus()
    }

    MouseArea {
        id: cursorArea
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        hoverEnabled: true
        cursorShape: {
            const leadingPoint = leadingSlot.mapFromItem(cursorArea, mouseX, mouseY);
            const point = trailingSlot.mapFromItem(cursorArea, mouseX, mouseY);
            if (leadingSlot.contains(leadingPoint))
                return root.leadingCursorShape;
            return trailingSlot.contains(point)
                ? root.trailingCursorShape
                : Qt.IBeamCursor;
        }
    }
}
