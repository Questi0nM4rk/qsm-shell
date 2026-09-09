import QtQuick
import QtTest

import qs.QsmShell.Components
import qs.QsmShell.Style
import "../../previews/units" as PreviewUnits

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

    property int downs: 0
    property int accepts: 0
    property int escapes: 0
    property int claims: 0
    property int composedAccepts: 0
    property bool claimDown: false
    property string lastSeenKey: ""

    TextField {
        id: field
        width: 300
        placeholder: "Search"

        onKeyPressed: event => {
            probe.lastSeenKey = String(event.key);
            if (probe.claimDown && event.key === Qt.Key_Down)
                event.accepted = true;
        }
        onMoveDown: probe.downs++
        onAccepted: probe.accepts++
        onEscaped: probe.escapes++
        onSelectionClaimed: probe.claims++
    }

    PreviewUnits.TextField {
        id: composedField
        y: 60
        width: 300
        variant: "text-filled"
        onAccepted: probe.composedAccepts++
    }

    function init() {
        probe.downs = 0;
        probe.accepts = 0;
        probe.escapes = 0;
        probe.claims = 0;
        probe.composedAccepts = 0;
        probe.claimDown = false;
        probe.lastSeenKey = "";
        field.text = "";
        field.enabled = true;
        field.inputType = "text";
        field.forceActiveFocus();
        composedField.purposeOverride = "text";
        composedField.readOnly = false;
        composedField.text = "Plain text";
    }

    function test_unclaimed_keys_fall_through_to_the_field() {
        keyClick(Qt.Key_Down);
        compare(probe.downs, 1, "an unclaimed Down did not reach moveDown");
        probe.claims = 0;
        keyClick(Qt.Key_Return);
        compare(probe.accepts, 1, "Return did not accept");
        compare(probe.claims, 1, "Return did not claim keyboard selection");
        keyClick(Qt.Key_Escape);
        compare(probe.escapes, 1, "Escape did not escape");
    }

    // The half that matters: accepting in the hook must STOP the field, not
    // merely run beside it. If both fire, a launcher taking Down for its list
    // would move the list twice.
    function test_a_claimed_key_never_reaches_the_field() {
        probe.claimDown = true;
        keyClick(Qt.Key_Down);
        compare(probe.downs, 0, "a claimed Down still reached moveDown");
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

    function test_search_action_keeps_the_glyph_sized_pointer_target() {
        composedField.purposeOverride = "search";
        wait(0);
        const searchAction = findChild(composedField, "textFieldSearchAction");
        verify(searchAction !== null, "the search field had no submit action");
        mouseClick(searchAction, 1, searchAction.height / 2);
        compare(probe.composedAccepts, 1,
            "the search action lost the edge of its glyph-sized pointer target");
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
        // The caret glides to a new position rather than jumping, so its
        // geometry can only be read once the move has settled.
        wait(Motion.press * 2);
        const caret = findChild(composedField, "textFieldCaret");
        const trailing = findChild(composedField, "textFieldTrailingAction");
        verify(caret !== null, "the caret overlay is not reachable");
        verify(trailing !== null, "a long value lost its trailing action");
        verify(caret.visible, "the caret hid while the field is focused");

        const caretRight = caret.mapToItem(composedField, caret.width, 0).x;
        const buttonLeft = trailing.mapToItem(composedField, 0, 0).x;
        const gap = buttonLeft - caretRight;
        // One row-spacing step, and nothing else: flush is too tight, floating
        // is too far, and the owner's live ruler settled on the spacing step.
        verify(gap >= Style.space2 - 2,
            "caret right (" + caretRight + ") is more than a step from button left (" + buttonLeft + ")");
        verify(gap <= Style.space2 + 2,
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
        compare(names, ["Accept", "Clear", "Reveal"], "action list changed shape");

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
    }

    // The ring is a KEYBOARD mark. A pointer already says where it is, so a
    // click focuses the input without painting one; arriving down the Tab
    // chain is the case that needs telling.
    function test_focus_ring_follows_keyboard_focus_only() {
        mouseClick(field, 150, 20);
        compare(field.focused, true, "click did not focus the input");
        compare(field.keyboardFocused, false, "a click painted the keyboard focus ring");

        // Clicking the PADDING is the other pointer route -- it reaches the
        // input through the frame's own tap handler, and must not ring either.
        probe.forceActiveFocus();
        mouseClick(field, 4, 20);
        compare(field.focused, true, "a click on the padding did not focus the input");
        compare(field.keyboardFocused, false, "a click on the padding painted the ring");

        // Setting `focus` on the FRAME cannot take focus off the input inside
        // it, so the probe takes it instead and Tab walks back in.
        probe.forceActiveFocus();
        verify(!field.focused, "the field kept focus before the Tab route");
        keyClick(Qt.Key_Tab);
        tryCompare(field, "keyboardFocused", true, 500);
    }

    // The mark that says "focus did not arrive by key" is cleared when focus
    // LEAVES the input, so a press that never focuses the input at all must
    // not leave one behind: pressing the trailing action on an unfocused
    // field would otherwise swallow the ring on the next Tab into it.
    function test_a_press_that_does_not_focus_leaves_no_stale_mark() {
        probe.forceActiveFocus();
        const clear = findChild(composedField, "textFieldTrailingAction");
        verify(clear !== null, "a filled field had no trailing action");
        mouseClick(clear, clear.width / 2, clear.height / 2);
        // Measured: the rejected press reaches BOTH the action and the frame's
        // tap handler, so clearing a field also leaves a caret in it -- and
        // that focus is what later clears the mark.
        compare(composedField.focused, true,
            "a press on a slot action did not reach the frame's tap handler");
        field.forceActiveFocus();
        keyClick(Qt.Key_Tab);
        tryCompare(composedField, "keyboardFocused", true, 500);
    }
}
