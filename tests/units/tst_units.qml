import QtQuick
import QtTest

// Every unit named in scenarios.json, constructed once, with every option of
// every declared control applied. Assigning a property or calling a method
// that a QML type does not have raises a catchable error at the point of the
// call -- qmllint cannot see inside a `set` object's keys, so this walk is
// the only thing that would ever notice a typo'd or stale control
// declaration.
TestCase {
    id: probe

    name: "Units"
    width: 400
    height: 400
    visible: true
    when: windowShown

    // The loaded unit's type is only known at runtime, so `controls` cannot
    // be typed on the generic object `createObject` returns -- read it
    // through an untyped parameter instead of a direct `.controls` access.
    function controlsOf(item) {
        return Array.isArray(item.controls) ? item.controls : [];
    }

    function unitNames() {
        const request = new XMLHttpRequest();
        request.open("GET", Qt.resolvedUrl("../../previews/scenarios.json"), false);
        request.send();
        // Qt refuses local-file GET unless QML_XHR_ALLOW_FILE_READ is set, and
        // the refusal arrives as an empty body rather than an error, which
        // then surfaces as an unreadable JSON parse failure.
        verify(request.responseText.length > 0,
               "could not read previews/scenarios.json -- run through scripts/run-unit.mjs "
               + "or scripts/validate-library, which set QML_XHR_ALLOW_FILE_READ");
        const scenarios = JSON.parse(request.responseText);
        const seen = {};
        const names = [];
        for (const key in scenarios) {
            const unit = scenarios[key].unit;
            if (unit && !seen[unit]) {
                seen[unit] = true;
                names.push(unit);
            }
        }
        return names;
    }

    function test_every_unit_constructs_and_walks_its_controls() {
        const names = unitNames();
        verify(names.length > 0, "scenarios.json named no units");

        for (let i = 0; i < names.length; i++) {
            const name = names[i];
            const component = Qt.createComponent(Qt.resolvedUrl("../../previews/units/" + name + ".qml"), Component.PreferSynchronous);
            compare(component.status, Component.Ready, name + ": " + component.errorString());

            const item = component.createObject(probe);
            verify(item !== null, name + ": " + component.errorString());

            const groups = controlsOf(item);
            try {
                for (let g = 0; g < groups.length; g++) {
                    const options = groups[g].options;
                    for (let o = 0; o < options.length; o++) {
                        const option = options[o];
                        if (option.call !== undefined) {
                            item[option.call]();
                        } else {
                            for (const key in option.set)
                                item[key] = option.set[key];
                        }
                    }
                }
            } catch (e) {
                fail(name + ": " + e);
            }

            verify(item !== null, name + ": did not survive its own controls");
            item.destroy();
        }
    }
}
