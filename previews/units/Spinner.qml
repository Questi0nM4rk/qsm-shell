import qs.QsmShell.Components
import qs.QsmShell.Style

Spinner {
    property string variant: ""

    size: Style.iconLg

    // Whether it turns is the only thing about a spinner that a still image
    // cannot show -- the reason this strip exists at all.
    readonly property var controls: [
        { label: "motion", options: [
            { label: "running", set: { running: true } },
            { label: "stopped", set: { running: false } }
        ]}
    ]
}
