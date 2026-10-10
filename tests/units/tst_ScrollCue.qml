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

    // What the cue paints, without naming any of its parts: the children
    // that are currently visible.
    function shown(cue) {
        const out = [];
        for (let i = 0; i < cue.children.length; i++) {
            if (cue.children[i].visible)
                out.push(cue.children[i]);
        }
        return out;
    }

    // The mark is the small child; the fades are the full-span strips. Told
    // apart by what they cover, not by which child they are.
    function isFullSpan(child, view, vertical) {
        return vertical
            ? Math.abs(child.width - view.width) < 0.5
            : Math.abs(child.height - view.height) < 0.5;
    }

    function test_content_that_fits_paints_nothing() {
        verify(!fitCue.overflows, "a cue on content that fits claimed there was more");
        compare(shown(fitCue).length, 0, "a cue on content that fits still painted");
        verify(!fitCue.enabled, "the cue was left able to take a pointer event meant for the content");
    }

    function test_each_fade_shows_only_while_content_remains_past_its_edge() {
        verify(tallCue.overflows, "a cue on overflowing content said it fit");

        tallView.contentY = 0;
        tryVerify(() => shown(tallCue).length === 2, 1000,
            "at the top the cue did not settle on exactly the mark plus one fade");
        let top = shown(tallCue);
        let topFades = top.filter(child => isFullSpan(child, tallView, true));
        compare(topFades.length, 1, "at the top there is not exactly one fade");
        verify(Math.abs((topFades[0].y + topFades[0].height) - tallView.height) < 0.5,
            "at the top the visible fade is not on the far edge");
        verify(topFades[0].y > 0.5,
            "at the top the near-edge fade is still visible although no content remains past it");

        tallView.contentY = tallView.contentHeight - tallView.height;
        tryVerify(() => {
            const now = shown(tallCue);
            if (now.length !== 2)
                return false;
            const fades = now.filter(child => isFullSpan(child, tallView, true));
            return fades.length === 1 && Math.abs(fades[0].y) < 0.5;
        }, 1000, "at the bottom the cue did not settle on the mark plus the near-edge fade");

        tallView.contentY = (tallView.contentHeight - tallView.height) / 2;
        tryVerify(() => shown(tallCue).length === 3, 1000,
            "in the middle both fades did not show");
        const mid = shown(tallCue).filter(child => isFullSpan(child, tallView, true));
        compare(mid.length, 2, "in the middle there is not one fade per edge");
    }

    function test_horizontal_fades_sit_on_the_left_and_right_edges() {
        verify(wideCue.overflows, "a horizontal cue on overflowing content said it fit");

        wideView.contentX = 0;
        tryVerify(() => shown(wideCue).length === 2, 1000,
            "at the left the horizontal cue did not settle on exactly the mark plus one fade");
        let left = shown(wideCue).filter(child => isFullSpan(child, wideView, false));
        compare(left.length, 1, "at the left there is not exactly one fade");
        compare(left[0].height, wideView.height, "a horizontal fade does not span the viewport height");
        compare(left[0].width, wideCue.fadeDepth, "a horizontal fade is not one fade depth wide");
        verify(Math.abs((left[0].x + left[0].width) - wideView.width) < 0.5,
            "at the left the visible fade is not on the far edge");

        wideView.contentX = wideView.contentWidth - wideView.width;
        tryVerify(() => {
            const now = shown(wideCue);
            if (now.length !== 2)
                return false;
            const fades = now.filter(child => isFullSpan(child, wideView, false));
            return fades.length === 1 && Math.abs(fades[0].x) < 0.5;
        }, 1000, "at the right the horizontal cue did not settle on the mark plus the near-edge fade");

        wideView.contentX = (wideView.contentWidth - wideView.width) / 2;
        tryVerify(() => shown(wideCue).length === 3, 1000,
            "in the middle both horizontal fades did not show");
    }
}
