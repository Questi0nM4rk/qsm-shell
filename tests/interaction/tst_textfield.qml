import QtQuick
import QtTest

import qs.QsmShell.Components

// The contract that replaced four boolean flags: `keyPressed` fires first with
// the live event, and a consumer that accepts it has TAKEN the key — the field
// does nothing further with it. Everything not taken falls through to the
// field's own handling.
//
// This is the whole reason `SearchField` could be deleted, so it is the piece
// of the library most worth a regression check.
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
    }

    function init() {
        probe.downs = 0;
        probe.accepts = 0;
        probe.escapes = 0;
        probe.claimDown = false;
        probe.lastSeenKey = "";
        field.setText("");
        field.focusField();
    }

    function test_unclaimed_keys_fall_through_to_the_field() {
        keyClick(Qt.Key_Down);
        compare(probe.downs, 1, "an unclaimed Down did not reach moveDown");
        keyClick(Qt.Key_Return);
        compare(probe.accepts, 1, "Return did not accept");
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

    // A masked field must still show that characters are ARRIVING — a field
    // that shows nothing at all cannot be told from one that is not receiving
    // the keystrokes.
    function test_masked_still_accepts_text() {
        field.masked = true;
        keyClick(Qt.Key_B);
        compare(field.text, "b", "a masked field dropped the character");
        field.masked = false;
    }
}
