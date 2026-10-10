import QtQuick
import QtTest

TestCase {
    id: testCase
    name: "MockScreen"
    width: 800
    height: 600
    visible: true
    when: windowShown

    QtObject {
        id: environment
        property bool fullscreen: false
        property rect screenRect: Qt.rect(120, 80, 800, 600)
        property string source: "simulated"
    }

    property var fixtureComponent: null
    property var fixture: null
    property var content: null
    property int activations: 0

    function initTestCase() {
        fixtureComponent = Qt.createComponent(Qt.resolvedUrl("../../workbench/fixtures/MockScreen.qml"))
        compare(fixtureComponent.status, Component.Ready, fixtureComponent.errorString())
    }

    function cleanup() {
        if (fixture)
            fixture.destroy()
        fixture = null
        content = null
        activations = 0
    }

    function createFixture(context) {
        fixture = fixtureComponent.createObject(testCase, {
            x: 120,
            y: 80,
            width: 800,
            height: 600,
            previewEnvironment: context,
            preferredWidth: 180,
            preferredHeight: 64,
            edge: "bottom",
            alignment: "center",
            inset: 24
        })
        verify(fixture)
    }

    function test_fullscreenKeepsOverlayInstanceAndInput() {
        createFixture(environment)
        content = Qt.createQmlObject('import QtQuick; MouseArea { anchors.fill: parent; onClicked: testCase.activations++ }',
                                     fixture.overlayBody)
        verify(content)
        const overlay = fixture.overlayBody
        const originalContent = content
        const app = fixture.children[0]
        verify(app)
        compare(fixture.environmentSupported, true)
        compare(fixture.bodyRect.x + fixture.bodyRect.width / 2, 520)
        compare(fixture.bodyRect.y + fixture.bodyRect.height, 656)

        environment.fullscreen = true

        compare(fixture.fullscreen, true)
        compare(fixture.overlayBody, overlay)
        compare(fixture.overlayBody.children[0], originalContent)
        compare(app.width, environment.screenRect.width)
        compare(app.height, environment.screenRect.height)
        mouseClick(fixture.overlayBody, fixture.overlayBody.width / 2, fixture.overlayBody.height / 2)
        compare(activations, 1)
    }

    function test_placementClampsBodyAcrossEdgesAndEmptyInsets() {
        createFixture(environment)
        fixture.edge = "left"
        fixture.alignment = "end"
        fixture.preferredWidth = 900
        fixture.preferredHeight = 700

        compare(fixture.constrained, true)
        compare(fixture.bodyRect.x, 144)
        compare(fixture.bodyRect.y, 104)
        compare(fixture.bodyRect.width, 752)
        compare(fixture.bodyRect.height, 552)
        compare(fixture.overlayBody.width, fixture.bodyRect.width)
        compare(fixture.overlayBody.height, fixture.bodyRect.height)

        fixture.edge = "right"
        fixture.alignment = "start"
        compare(fixture.bodyRect.x + fixture.bodyRect.width, 896)
        compare(fixture.bodyRect.y, 104)

        fixture.edge = "top"
        fixture.alignment = "end"
        compare(fixture.bodyRect.x + fixture.bodyRect.width, 896)
        compare(fixture.bodyRect.y, 104)

        fixture.edge = "bottom"
        fixture.alignment = "start"
        compare(fixture.bodyRect.x, 144)
        compare(fixture.bodyRect.y + fixture.bodyRect.height, 656)

        fixture.inset = 400
        compare(fixture.emptyPlacement, true)
        compare(fixture.overlayBody.visible, false)
        compare(fixture.overlayBody.enabled, false)
        compare(fixture.bodyRect.width, 0)
        compare(fixture.bodyRect.height, 0)
    }

    function test_standaloneUsesItsOwnDesktopBoundsWithoutFullscreenSupport() {
        createFixture(null)
        compare(fixture.environmentSupported, false)
        compare(fixture.fullscreen, false)
        compare(fixture.screenRect.x, fixture.x)
        compare(fixture.screenRect.y, fixture.y)
        compare(fixture.screenRect.width, fixture.width)
        compare(fixture.screenRect.height, fixture.height)
    }
}
