import QtQuick
import QtTest

import qs.QsmShell.Components

// The cue's one promise: it never claims there is more when the content
// fits, and each fade is visible only while there is content past its own
// edge. Every case drives a real Flickable to a real boundary and reads what
// the cue paints -- which children are visible and which edge they sit on --
// never exact pixels, never the source, never an internal id.
TestCase {
    id: probe

    name: "ScrollCue"
    width: 640
    height: 480
    visible: true
    when: windowShown

    // Content that fits: nothing to report, so nothing may paint.
    Item {
        id: fitStage
        x: 20; y: 20; width: 200; height: 100

        Flickable {
            id: fitView
            anchors.fill: parent
            clip: true
            contentWidth: width
            contentHeight: 40
            boundsBehavior: Flickable.StopAtBounds
            Item { width: 200; height: 40 }
        }

        ScrollCue { id: fitCue; view: fitView }
    }

    // Content that overflows vertically: the top and bottom fades take turns.
    Item {
        id: tallStage
        x: 240; y: 20; width: 200; height: 100

        Flickable {
            id: tallView
            anchors.fill: parent
            clip: true
            flickableDirection: Flickable.VerticalFlick
            contentWidth: width
            contentHeight: 400
            boundsBehavior: Flickable.StopAtBounds
            Item { width: 200; height: 400 }
        }

        ScrollCue { id: tallCue; view: tallView }
    }

    // Content that overflows horizontally: the fades move to the sides.
    Item {
        id: wideStage
        x: 20; y: 140; width: 200; height: 100

        Flickable {
            id: wideView
            anchors.fill: parent
            clip: true
            flickableDirection: Flickable.HorizontalFlick
            contentWidth: 400
            contentHeight: height
            boundsBehavior: Flickable.StopAtBounds
            Item { width: 400; height: 100 }
        }

        ScrollCue { id: wideCue; view: wideView; orientation: Qt.Horizontal }
    }

    function test_content_that_fits_paints_nothing() {
        verify(!fitCue.overflows, "a cue on content that fits claimed there was more");
        compare(fitCue.startFade, 0, "a cue on content that fits painted a start fade");
        compare(fitCue.endFade, 0, "a cue on content that fits painted an end fade");
        verify(!fitCue.enabled, "the cue was left able to take a pointer event meant for the content");
    }

    function test_each_fade_shows_only_while_content_remains_past_its_edge() {
        verify(tallCue.overflows, "a cue on overflowing content said it fit");

        tallView.contentY = 0;
        compare(tallCue.startFade, 0, "at the top there is a fade although nothing is hidden above");
        verify(tallCue.endFade > 0, "at the top there is no fade for the content below");

        tallView.contentY = tallView.contentHeight - tallView.height;
        verify(tallCue.startFade > 0, "at the bottom there is no fade for the content above");
        compare(tallCue.endFade, 0, "at the bottom there is a fade although nothing is hidden below");
    }

    // A fade never reaches deeper than the content hidden past its edge, nor
    // than a sixth of the viewport however deep it is asked to go.
    function test_a_fade_is_bounded_by_the_hidden_content_and_the_viewport() {
        tallCue.fadeDepth = 1000;
        tallView.contentY = 5;
        compare(tallCue.startFade, 5, "the fade is deeper than the 5 px hidden above it");
        tallView.contentY = 150;
        compare(tallCue.startFade, tallView.height / 6, "the fade is deeper than a sixth of the viewport");
        compare(tallCue.endFade, tallView.height / 6, "the end fade is deeper than a sixth of the viewport");
    }

    function test_horizontal_fades_sit_on_the_left_and_right_edges() {
        verify(wideCue.overflows, "a horizontal cue on overflowing content said it fit");

        wideView.contentX = 0;
        compare(wideCue.startFade, 0, "at the left there is a fade although nothing is hidden before it");
        compare(wideCue.endFade, Math.min(wideCue.fadeDepth, wideView.width / 6),
            "at the left the end fade is not one fade depth wide");

        wideView.contentX = wideView.contentWidth - wideView.width;
        verify(wideCue.startFade > 0, "at the right there is no fade for the content before it");
        compare(wideCue.endFade, 0, "at the right there is a fade although nothing is hidden past it");
    }
}
