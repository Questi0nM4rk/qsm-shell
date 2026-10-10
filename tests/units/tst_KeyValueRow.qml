import QtQuick
import QtTest

import qs.QsmShell.Components

TestCase {
    name: "KeyValueRow"
    width: 480
    height: 160
    visible: true
    when: windowShown

    Item {
        id: host
        width: 400
        height: 40

        property string glyph: ""

        KeyValueRow {
            id: row
            anchors.fill: parent
            label: "Battery"
            value: "87%"
            icon: host.glyph
        }
    }

    function test_icon_slot_tracks_late_changes_without_overlap() {
        const glyph = findChild(row, "keyValueGlyph");
        const label = findChild(row, "keyValueLabel");
        const reading = findChild(row, "keyValueReading");
        verify(!glyph.visible);
        compare(label.x, row.x);

        host.glyph = "battery-full";
        verify(waitForRendering(row));
        verify(glyph.visible);
        verify(glyph.x + glyph.width <= label.x);
        verify(label.x + label.width <= reading.x);

        host.glyph = "";
        verify(waitForRendering(row));
        verify(!glyph.visible);
        compare(label.x, row.x);
        verify(label.x + label.width <= reading.x);
    }
}
