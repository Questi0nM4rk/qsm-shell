import QtQuick
import QtTest

import qs.QsmShell.Components
import qs.QsmShell.Style

// `keyPressed` fires first with the live event, and a consumer that accepts it
// has TAKEN the key -- the field does nothing further with it. Everything not
// taken falls through to the field's own handling.
TestCase {
    id: probe

    name: "TextField"
    width: 400
    height: 120
    visible: true
    when: windowShown

    property int accepts: 0
    property int escapes: 0
    property int claims: 0
    property int composedAccepts: 0
    property bool claimReturn: false
    property string lastSeenKey: ""

    component PreviewTextField: TextField {
        id: previewField
        property string purposeOverride: "text"
        property bool showLeading: true
        readonly property bool passwordExample: purposeOverride === "password"
        readonly property bool numberExample: purposeOverride === "number"
        readonly property int _slotIconSize: Style.glyphBeside(previewField.fieldHeight)
        inputType: passwordExample ? "password" : numberExample ? "number" : "text"
        failed: numberExample && text.length > 0 && !acceptableInput
        leadingSlotInset: purposeOverride === "search" ? 0 : previewField._inset
        leadingCursorShape: purposeOverride === "search" ? Qt.PointingHandCursor : Qt.IBeamCursor
        trailingCursorShape: readOnly && !passwordExample ? Qt.ArrowCursor : Qt.PointingHandCursor
        leading: Loader { active: previewField.showLeading; sourceComponent: previewField.purposeOverride === "search" ? searchAction : purposeGlyph }
        trailing: Loader { active: previewField.text.length > 0; sourceComponent: IconButton { objectName: "textFieldTrailingAction"; enabled: previewField.passwordExample || !previewField.readOnly; icon: previewField.passwordExample ? previewField.passwordVisible ? "eye-off" : "eye" : "x"; size: "sm"; padding: 0; color: Style.textMuted; onClicked: previewField.passwordExample ? previewField.toggleReveal() : previewField.clear() } }
        Component { id: searchAction; IconButton { objectName: "textFieldSearchAction"; icon: "search"; size: "sm"; padding: 0; leftPadding: previewField._inset; height: previewField.fieldHeight; color: Style.textMuted; onClicked: previewField.accept() } }
        Component { id: purposeGlyph; SvgIcon { objectName: "textFieldPurposeGlyph"; name: previewField.passwordExample ? "key" : previewField.numberExample ? "hash" : "type"; size: previewField._slotIconSize; color: previewField.enabled ? Style.textMuted : Style.disabled(Style.textMuted) } }
    }

    TextField {
        id: field
        width: 300
        placeholder: "Search"

        onKeyPressed: event => {
            probe.lastSeenKey = String(event.key);
            if (probe.claimReturn && event.key === Qt.Key_Return)
                event.accepted = true;
        }
        onAccepted: probe.accepts++
        onEscaped: probe.escapes++
        onSelectionClaimed: probe.claims++
    }

    PreviewTextField {
        id: composedField
        y: 60
        width: 300
        onAccepted: probe.composedAccepts++
    }

    function init() {
        probe.accepts = 0;
        probe.escapes = 0;
        probe.claims = 0;
        probe.composedAccepts = 0;
        probe.claimReturn = false;
        probe.lastSeenKey = "";
        field.text = "";
        field.enabled = true;
        field.readOnly = false;
        field.inputType = "text";
        field.forceActiveFocus();
        composedField.readOnly = false;
        composedField.text = "Plain text";
    }

    function test_unclaimed_keys_fall_through_to_the_field() {
        keyClick(Qt.Key_Return);
        compare(probe.accepts, 1, "Return did not accept");
        compare(probe.claims, 1, "Return did not claim keyboard selection");
        keyClick(Qt.Key_Escape);
        compare(probe.escapes, 1, "Escape did not escape");
    }

    // The half that matters: accepting in the hook must STOP the field, not
    // merely run beside it. If both fire, a surface taking Return for itself
    // would also submit the field.
    function test_a_claimed_key_never_reaches_the_field() {
        probe.claimReturn = true;
        keyClick(Qt.Key_Return);
        compare(probe.accepts, 0, "a claimed Return still accepted the field");
        verify(probe.lastSeenKey.length > 0, "the hook never saw the event");
    }

    function test_typing_lands() {
        keyClick(Qt.Key_A);
        compare(field.text, "a", "the typed character did not land");
    }

    // A password field must still show that characters are ARRIVING — a
    // field whose text is hidden can otherwise be mistaken for a dead one.
    function test_password_input_type_still_accepts_text() {
        field.inputType = "password";
        keyClick(Qt.Key_B);
        compare(field.text, "b", "a password field dropped the character");
    }

    // A number field gates both typing and accepting. The validator rejects a
    // letter keystroke outright, lets a digit land, and an invalid
    // programmatic value reports false acceptableInput with accept() refusing
    // to emit — while a valid value through the same method emits.
    function test_number_input_type_rejects_letters_and_gates_accept() {
        field.inputType = "number";

        keyClick(Qt.Key_A);
        compare(field.text, "", "a number field accepted a letter keystroke");

        keyClick(Qt.Key_4);
        compare(field.text, "4", "a number field dropped a digit keystroke");
        verify(field.acceptableInput, "a valid number read as unacceptable");

        field.text = "abc";
        compare(field.acceptableInput, false, "an invalid programmatic value read as acceptable");
        probe.accepts = 0;
        compare(field.accept(), false, "accept() reported success on an invalid value");
        compare(probe.accepts, 0, "accept() emitted accepted on an invalid value");

        field.text = "42";
        probe.accepts = 0;
        probe.claims = 0;
        compare(field.accept(), true, "accept() refused a valid value");
        compare(probe.accepts, 1, "accept() failed to emit accepted on a valid value");
        compare(probe.claims, 0, "programmatic accept() pretended to be keyboard input");

        field.enabled = false;
        probe.accepts = 0;
        compare(field.accept(), false, "accept() accepted a disabled field");
        compare(probe.accepts, 0, "a disabled accept() emitted accepted");
    }

    // The existing tests prove the field works once focused, but not that
    // focus can be REACHED. A pointer click routes through the StateLayer
    // and Tab follows the platform's focus chain — two independent routes
    // a keyboard-first person depends on.
    function test_focus_is_reachable_by_pointer_and_tab() {
        probe.forceActiveFocus();
        verify(!field.focused, "field was not unfocused before pointer test");

        mouseClick(field, field.width / 2, field.height / 2);
        verify(field.focused, "pointer click did not give focus to the field");

        // Tab away, then back
        keyClick(Qt.Key_Tab);
        probe.forceActiveFocus();
        verify(!field.focused, "field was not unfocused before Tab test");

        keyClick(Qt.Key_Tab);
        verify(field.focused, "Tab did not reach the text field");
    }

    function test_read_only_clear_action_cannot_mutate_text() {
        composedField.readOnly = true;
        wait(0);
        const readOnlyClearAction = findChild(composedField, "textFieldTrailingAction");
        verify(readOnlyClearAction !== null, "a read-only filled field lost its clear action");
        verify(!readOnlyClearAction.enabled, "a read-only field left its mutating clear action enabled");
        mouseClick(readOnlyClearAction,
            readOnlyClearAction.width / 2, readOnlyClearAction.height / 2);
        compare(composedField.text, "Plain text", "the read-only clear action changed the text");

        composedField.readOnly = false;
        wait(0);
        const clearAction = findChild(composedField, "textFieldTrailingAction");
        verify(clearAction !== null, "an editable filled field had no clear action");
        mouseClick(clearAction, clearAction.width / 2, clearAction.height / 2);
        compare(composedField.text, "", "the editable clear action did not clear the text");
    }

    function test_search_action_owns_the_leading_inset() {
        composedField.purposeOverride = "search";
        composedField.size = "md";
        wait(0);
        const searchAction = findChild(composedField, "textFieldSearchAction");
        verify(searchAction !== null, "the search field had no submit action");
        const actionOrigin = searchAction.mapToItem(composedField, 0, 0);
        compare(actionOrigin.x, 0, "the search action did not begin at the field's left edge");
        compare(searchAction.height, composedField.height,
            "the search action did not own the field's full leading edge");
        verify(searchAction.width >= Style.iconLg,
            "the search action remained smaller than the pointer target floor");
        mouseClick(searchAction, 1, searchAction.height / 2);
        compare(probe.composedAccepts, 1,
            "the search action did not answer at the field's left edge");
    }

    // A slot action is a control in its own right, and it has to answer the
    // pointer like one. An overlay spanning the frame used to consume hover
    // from the slots, so the actions never grew under the pointer while their
    // press and their click still worked -- the one state that went missing was
    // the one that says "this is a target".
    function test_slot_actions_answer_hover_under_the_pointer() {
        const trailing = findChild(composedField, "textFieldTrailingAction");
        verify(trailing !== null, "an editable filled field had no trailing action");
        // `IconButton` grows its GLYPH and reports no hover of its own, so the
        // state is read off the layer that owns it.
        let layer = null;
        for (let i = 0; i < trailing.children.length; i++) {
            if (trailing.children[i].hoverScale !== undefined)
                layer = trailing.children[i];
        }
        verify(layer !== null, "the trailing action has no StateLayer to answer hover");

        mouseMove(trailing, trailing.width / 2, trailing.height / 2);
        compare(composedField.hovered, true, "the pointer never arrived on the field");
        tryCompare(layer, "hovered", true, 500);
    }

    // "An empty slot takes no space." A `Loader` keeps its last item's
    // implicit size after `active: false` -- measured: implicit 24x24 with
    // `item` null -- so a field that had a trailing action and then lost its
    // text went on reserving a whole action's width next to an empty value.
    function test_an_empty_trailing_slot_takes_no_space() {
        // The bare inset, at this field's own scale -- never the base
        // Style.space3, which is only the md reading.
        const restInset = Style.rhythm(Style.space3 * composedField.sizeScale);

        composedField.text = "Plain text";
        wait(0);
        verify(composedField.rightPadding > restInset,
            "a filled field reserved no room for its trailing action");

        composedField.text = "";
        wait(0);
        compare(composedField.rightPadding, restInset,
            "an emptied field kept its inactive trailing action's footprint");
    }

    // The leading glyph is the host's content, so switching it off must give
    // the padding it reserved back to the text, not leave a hole.
    function test_a_field_without_a_leading_glyph_gives_the_space_back() {
        const restInset = Style.rhythm(Style.space3 * composedField.sizeScale);

        composedField.showLeading = true;
        wait(0);
        verify(composedField.leftPadding > restInset,
            "a field with a leading glyph reserved no room for it");

        composedField.showLeading = false;
        tryCompare(composedField, "leftPadding", restInset);

        composedField.showLeading = true;
    }

    // One scale per instance: a leading and a trailing glyph at two
    // different sizes read as two different fields.
    function test_leading_and_trailing_slot_glyphs_share_one_size() {
        composedField.purposeOverride = "text";
        composedField.showLeading = true;
        composedField.text = "Plain text";
        wait(0);

        const leading = findChild(composedField, "textFieldPurposeGlyph");
        const trailing = findChild(composedField, "textFieldTrailingAction");
        verify(leading !== null, "the filled text field had no leading glyph");
        verify(trailing !== null, "the filled text field had no trailing action");

        const expected = Style.glyphBeside(composedField.fieldHeight);
        compare(trailing._glyph, expected, "the trailing slot glyph is not the field's glyph");
        compare(leading.size, expected, "the leading slot glyph does not match the trailing one");
    }

    // "Unavailable and not-a-target are different states": a read-only field
    // reports, it is not a target. Its two state owners used to disagree --
    // the layer stopped answering while the background lifted anyway, so a
    // person got the editable-field answer, clicked, and got no caret.
    function test_a_read_only_field_does_not_lift_under_the_pointer() {
        probe.forceActiveFocus();
        verify(!field.focused, "the field kept focus before the hover test");
        const surface = findChild(field, "textFieldSurface");
        verify(surface !== null, "the field surface is not reachable");

        field.readOnly = true;
        mouseMove(field, field.width / 2, field.height / 2);
        compare(field.hovered, true, "the pointer never arrived on the read-only field");
        // The surface animates, so the reading is only worth taking once the
        // curve has settled -- polled from the first frame, a lift that is
        // still leaving the rest colour reads as no lift at all.
        wait(Motion.micro * 3);
        compare(surface.color, Style.surface,
            "a read-only field lifted under the pointer");

        field.readOnly = false;
        mouseMove(field, field.width / 2 + 1, field.height / 2);
        compare(field.hovered, true, "the pointer never arrived on the editable field");
        wait(Motion.micro * 3);
        compare(surface.color, Style.lift(Style.surface, 0.4),
            "an editable field did not lift under the pointer");
    }

    // `failed` is the HOST's verdict, and the unit plays the host: a number
    // purpose reads `acceptableInput` and paints the failure itself. Return on
    // an unacceptable value was otherwise a silent no-op with a frame identical
    // to a valid field's.
    function test_the_number_host_paints_an_unacceptable_value_as_failed() {
        composedField.purposeOverride = "number";
        composedField.text = "12a";
        compare(composedField.acceptableInput, false, "the number validator accepted letters");
        compare(composedField.failed, true, "an unacceptable number was not reported as failed");

        composedField.text = "12";
        compare(composedField.failed, false, "a valid number was reported as failed");

        composedField.text = "";
        compare(composedField.failed, false, "an empty number field was reported as failed");
    }

    // Echo-on-edit showed the WHOLE password in cleartext the moment the field
    // was focused for typing -- and because the dots switch to letters under
    // the caret, it also read as "typing wiped the field". A password must
    // stay masked while it is being typed into, and the text it is holding
    // must survive the keystroke.
    function test_password_always_masks_and_preserves_text() {
        field.inputType = "password";
        field.text = "secret";
        const input = findChild(field, "textFieldInput");
        verify(input !== null, "the input is not reachable for echo-mode asserts");
        input.cursorPosition = input.length;

        compare(input.echoMode, TextInput.Password, "a sitting password was not masked");
        keyClick(Qt.Key_X);
        compare(field.text, "secretx", "typing cleared the sitting password text");
        compare(input.echoMode, TextInput.Password, "typing switched the password to cleartext");

        field.passwordVisible = true;
        compare(input.echoMode, TextInput.Normal, "a revealed password did not become editable text");
        keyClick(Qt.Key_Y);
        compare(field.text, "secretxy", "typing into a revealed password cleared the text");

        field.passwordVisible = false;
        compare(input.echoMode, TextInput.Password, "re-masking restored another echo mode");
        keyClick(Qt.Key_Z);
        compare(field.text, "secretxyz", "typing a re-masked password cleared the text");
        compare(input.echoMode, TextInput.Password, "typing a re-masked password was not masked");
    }

    // A text box's preferred width is a constant. Products scroll a single
    // line inside a fixed box; they never let the typed text stretch the box.
    function test_field_never_grows_with_typed_content() {
        const before = field.implicitWidth;
        let longText = "qsm-lab";
        for (let i = 0; i < 300; i++)
            longText += "x";
        field.text = longText;
        compare(field.implicitWidth, before,
            "typing a long value stretched the field's implicit width");
    }

    // The custom caret must stay visibly LEFT of the trailing action at the
    // end of a long value. Pinned to the scroll edge it reads as "under the
    // button", and hard against the clip edge it reads as vanished -- so the
    // scroll-end caret lands exactly the row-spacing step off the action, with
    // its bar fully on-screen. The owner's live ruler chose that distance.
    function test_caret_clears_the_trailing_action() {
        composedField.readOnly = false;
        composedField.text = "abcdefghijklmnopqrstuvwxyz0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";
        composedField.forceActiveFocus();
        wait(0);
        const input = findChild(composedField, "textFieldInput");
        input.cursorPosition = input.length;
        const caret = findChild(composedField, "textFieldCaret");
        const trailing = findChild(composedField, "textFieldTrailingAction");
        verify(caret !== null, "the caret overlay is not reachable");
        verify(trailing !== null, "a long value lost its trailing action");
        // The caret glides to a new position rather than jumping, so its
        // geometry can only be read once the move has settled.
        tryVerify(() => Math.abs(caret.x - (input.x + input.cursorRectangle.x)) < 0.5,
            500, "the caret did not settle after the cursor moved to the end");
        verify(caret.visible, "the caret hid while the field is focused");

        const caretRight = caret.mapToItem(composedField, caret.width, 0).x;
        const buttonLeft = trailing.mapToItem(composedField, 0, 0).x;
        const gap = buttonLeft - caretRight;
        // One row-spacing step at this field's own scale, and nothing else:
        // flush is too tight, floating is too far, and the owner's live
        // ruler settled on the spacing step -- never the base Style.space2,
        // which is only the md reading.
        const step = Style.rhythm(Style.space2 * composedField.sizeScale);
        verify(gap >= step - 2,
            "caret right (" + caretRight + ") is more than a step from button left (" + buttonLeft + ")");
        verify(gap <= step + 2,
            "caret right (" + caretRight + ") floats more than a spacing step from the button");

        const middle = input.parent;
        verify(caret.x + caret.width <= middle.width + 0.5,
            "caret right edge overflows the text column clip");
    }

    // The action list is the API a consumer's action menu renders. Each entry
    // must be the same route the keyboard takes: Return and the Accept action
    // both go through accept(), Clear empties through clear().
    function test_actions_are_the_same_route_as_the_keys() {
        field.text = "42";
        const names = [];
        for (let i = 0; i < field.actions.length; i++)
            names.push(field.actions[i].text);
        compare(names, ["Accept", "Clear", "Reveal", "Select all"], "action list changed shape");

        field.actions[0].trigger();
        compare(probe.accepts, 1, "Accept action did not go through accept()");
        keyClick(Qt.Key_Return);
        compare(probe.accepts, 2, "Return and the Accept action are not one route");

        field.actions[1].trigger();
        compare(field.text, "", "Clear action did not clear");

        compare(field.actions[2].enabled, false, "Reveal is enabled on a text field");
        field.inputType = "password";
        compare(field.actions[2].enabled, true, "Reveal is disabled on a password field");
        field.actions[2].trigger();
        compare(field.passwordVisible, true, "Reveal did not toggle passwordVisible");
        field.inputType = "text";
        field.passwordVisible = false;
        // A checkable action's `trigger()` writes `checked` itself, so the
        // menu's tick has to keep following the field rather than the last
        // trigger.
        compare(field.actions[2].checked, false, "Action.trigger() severed the checked binding");

        // Select all is a menu route onto the same function the keyboard uses.
        field.text = "42";
        const input = findChild(field, "textFieldInput");
        verify(input !== null, "the input is not reachable for the select-all assert");
        field.actions[3].trigger();
        compare(input.selectedText, field.text,
            "the Select all action did not select the whole value");
    }

    // Every route into the field focuses the input: the text, the padding and
    // the Tab chain. The padding reaches it through the frame's own tap
    // handler, which is the route that broke once.
    function test_every_route_focuses_the_input() {
        mouseClick(field, 150, 20);
        compare(field.focused, true, "click on the text did not focus the input");

        probe.forceActiveFocus();
        mouseClick(field, 4, 20);
        compare(field.focused, true, "a click on the padding did not focus the input");

        // Setting `focus` on the FRAME cannot take focus off the input inside
        // it, so the probe takes it instead and Tab walks back in.
        probe.forceActiveFocus();
        verify(!field.focused, "the field kept focus before the Tab route");
        keyClick(Qt.Key_Tab);
        tryCompare(field, "focused", true, 500);
    }

    // A read-only field is still a tab stop: the value it reports can be
    // selected and copied, so the keyboard has to be able to land on it and
    // be told where it is. The layer used to stop answering while read-only
    // and took the ring with it.
    function test_a_read_only_field_still_rings_on_the_tab_route() {
        field.readOnly = true;
        probe.forceActiveFocus();
        verify(!field.focused, "the field held focus before the Tab route");

        keyClick(Qt.Key_Tab);
        tryCompare(field, "focused", true, 500);

        const layer = findChild(field, "textFieldLayer");
        verify(layer !== null, "the field's StateLayer is not reachable");
        let ring = null;
        for (let i = 0; i < layer.children.length; i++) {
            if (layer.children[i].border !== undefined)
                ring = layer.children[i];
        }
        verify(ring !== null, "the StateLayer has no focus ring to read");
        verify(ring.visible, "a read-only field on the Tab route painted no focus ring");
    }

    // Disabled dims by COLOUR, never by opacity on a composite: `opacity` on
    // the frame applies to each child separately, so a translucent surface
    // shows whatever sits behind the field through its own text. Every layer
    // blends toward the background instead and stays opaque.
    function test_disabled_dims_by_colour_and_leaves_the_frame_opaque() {
        const surface = findChild(field, "textFieldSurface");
        const input = findChild(field, "textFieldInput");
        verify(surface !== null && input !== null, "a painted part of the field lost its objectName");

        field.enabled = false;
        compare(field.opacity, 1,
            "a disabled field dimmed itself with `opacity`, so its surface is translucent "
            + "and whatever sits behind it reads through the text");
        tryCompare(surface, "color", Style.disabled(Style.surface), 500,
            "a disabled surface is not its rest colour blended toward the background");
        compare(input.color, Style.disabled(Style.text),
            "disabled text is not its rest colour blended toward the background");
        compare(surface.color.a, 1, "the dimmed surface is translucent rather than dimmed");

        // A literal, and the one place one is right: comparing against
        // `Style.disabled` alone passes even if the blend is wrong, as long
        // as both sides are wrong the same way. Deep-night's surface is
        // #2d2036, its background #1c0e27 and `opacityDisabled` 0.35, so
        // retuning any of them moves this number and the message says which.
        compare(String(Style.disabled(Style.surface)), "#30273a",
            "the disabled blend of Style.surface is not the measured deep-night value -- either "
            + "the arithmetic changed or the theme's surface / background / opacityDisabled did");
    }
}
