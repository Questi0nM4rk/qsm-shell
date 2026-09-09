import QtQuick

import qs.QsmShell.Components
import qs.QsmShell.Style

Item {
    id: root

    width: 320
    height: 240
    visible: false

    property int activatedIndex: -1

    QtObject {
        id: backend
        property bool reducedMotion: false
        property color accent: "#c5a5e9"
        property color secondary: "#e1b7e1"
        property color success: "#91d6c2"
        property color outline: "#4e3f62"
        property color background: "#1c0e27"
        property color surface: "#21142b"
        property color surfaceHover: "#382a48"
        property color surfaceRaised: "#2d1f3a"
        property color text: "#f6f1f9"
        property color textMuted: "#b6a8c2"
        property color danger: "#ff8b94"
        property string fontFamily: "Test Sans"
        property string technicalFontFamily: "Test Mono"
        property real surfaceOpacity: 0.9
        property real opacityDisabled: 0.23
        property int sliderThumbSize: 19
        property int sliderTrackThickness: 7
        property int iconLg: 26
        property int controlHeight: 53
        property int controlHeightSm: 29
        property int textDisplay: 37
        property color warning: "#abcdef"
    }

    Component.onCompleted: {
        Style.backend = backend;
        runTimer.start();
    }

    Timer {
        id: runTimer
        interval: Motion.micro + 20
        onTriggered: root.run()
    }

    function require(condition, message) {
        if (condition)
            return true;

        console.error(`SMOKE_FAIL: ${message}`);
        Qt.exit(1);
        return false;
    }

    function run() {
        if (!require(compactCapsule.implicitHeight === backend.controlHeightSm,
                "Capsule did not consume backend compact height"))
            return;
        if (!require(capsule.implicitHeight === backend.controlHeight,
                "Capsule did not consume backend height"))
            return;
        // The md thumb derives from the icon scale, so that is the token the
        // consumer's backend has to reach.
        if (!require(level.thumbSize === backend.iconLg,
                "Slider did not derive its md thumb from the backend icon scale"))
            return;
        if (!require(disabledButton.opacity === backend.opacityDisabled,
                "IconButton did not consume backend disabled opacity"))
            return;
        if (!require(Style.technicalFontFamily === backend.technicalFontFamily,
                "Style did not consume backend technical font"))
            return;
        // A role resolves to a token AND the token resolves through the
        // backend -- the two halves of "the consumer can retheme the type
        // scale", which a component typing its own pixelSize breaks silently.
        if (!require(bigReading.font.pixelSize === backend.textDisplay,
                "Prose display role did not resolve the backend display size"))
            return;
        if (!require(bigReading.font.family === backend.technicalFontFamily,
                "Prose reading role did not use the technical face"))
            return;
        if (!require(String(Style.warning) === String(backend.warning),
                "Style did not consume backend warning"))
            return;

        menu.step(1);
        if (!require(menu.currentIndex === 1, "Menu did not skip its header"))
            return;
        if (!require(first.width === menu.width, "Menu did not size its vertical rows"))
            return;

        menu.step(1);
        if (!require(menu.currentIndex === 3, "Menu did not skip its disabled row"))
            return;
        if (!require(second.selected, "Menu did not apply selection to its real row"))
            return;

        menu.activateCurrent();
        if (!require(activatedIndex === 3, "Menu did not emit its selected index"))
            return;

        menu.step(1);
        if (!require(menu.currentIndex === 1, "Menu did not wrap to the first selectable row"))
            return;

        console.log("SMOKE_OK");
        Qt.exit(0);
    }

    Prose {
        id: bigReading
        role: "display"
        text: "72%"
        // A role sets the face; a call site may still need the other one. The
        // reading face is what a value that changes gets, whatever its size.
        font.family: Style.technicalFontFamily
    }

    Capsule {
        id: compactCapsule
        size: "sm"
        icon: "check"
        label: "Compact"
    }

    Capsule {
        id: capsule
        icon: "check"
        label: "Default"
    }

    Slider {
        id: level
        width: 100
        value: 0.5
    }

    IconButton {
        id: disabledButton
        icon: "check"
        enabled: false
    }

    Menu {
        id: menu

        width: parent.width
        height: parent.height

        onActivated: index => root.activatedIndex = index

        ListRow {
            header: true
            primary: "Section"
        }

        ListRow {
            id: first
            primary: "First"
        }

        ListRow {
            disabled: true
            primary: "Disabled"
        }

        ListRow {
            id: second
            primary: "Second"
        }
    }

}
