import QtQuick
import QtTest

import qs.QsmShell.Components
import qs.QsmShell.Style

TestCase {
    id: probe

    name: "ColorSwatch"
    width: 400
    height: 260
    visible: true
    when: windowShown

    ColorSwatch {
        id: hosted
        x: 60
        y: 60
        size: 24
        sample: "#f6f1f9"
        reading: "#F6F1F9"
    }
    SignalSpy { id: hostedClicked; target: hosted; signalName: "clicked" }

    ColorSwatch {
        id: disabled
        x: 220
        y: 60
        size: 24
        sample: "#f6f1f9"
        reading: "#F6F1F9"
        enabled: false
    }
    SignalSpy { id: disabledClicked; target: disabled; signalName: "clicked" }

    ColorSwatch {
        id: clear
        x: 60
        y: 160
        size: 32
        sample: "#66c5a5e9"
        enabled: false
    }

    function init() {
        hostedClicked.clear()
        disabledClicked.clear()
    }

    // The face stays the caller's size while the layout footprint never drops
    // below the target floor, so palette siblings never share a hit zone.
    function test_face_stays_compact_while_target_meets_the_floor() {
        const face = findChild(hosted, "swatchFace")
        verify(face !== null, "the painted face did not construct")
        compare(face.width, 24, "a 24px sample did not paint 24px")
        compare(hosted.implicitWidth, Style.swatchTarget, "the target missed the floor")
        compare(hosted.implicitHeight, Style.swatchTarget, "the target missed the floor")
        const ring = findChild(hosted, "swatchRing")
        verify(ring !== null, "the selection ring did not construct")
        compare(ring.width, face.width, "the ring left the face for the target")
    }

    function test_pointer_keyboard_and_action_share_one_guarded_route() {
        mouseClick(hosted)
        hosted.forceActiveFocus()
        keyClick(Qt.Key_Space)
        keyClick(Qt.Key_Return)
        hosted.activate()

        compare(hostedClicked.count, 4, "swatch routes did not share clicked")
    }

    // No composite opacity: every layer stays opaque, and a translucent
    // sample keeps its alpha so the check still shows through it.
    function test_disabled_keeps_layers_opaque_and_silent() {
        compare(disabled.opacity, 1, "disabled dimmed the composite")
        const sample = findChild(clear, "swatchSample")
        verify(sample !== null, "the sample did not construct")
        verify(sample.color.a < 1, "disabled turned a translucent sample opaque")
        compare(clear.opacity, 1, "disabled dimmed the composite")

        mouseClick(disabled)
        disabled.forceActiveFocus()
        keyClick(Qt.Key_Space)
        keyClick(Qt.Key_Return)
        disabled.activate()

        compare(disabledClicked.count, 0, "disabled swatch fired clicked")
    }
}
