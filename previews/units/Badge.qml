import qs.QsmShell.Components

Badge {
    property string variant: ""

    tone: variant
    text: "3"

    readonly property var controls: [
        { label: "tone", options: [
            { label: "neutral", set: { tone: "neutral" } },
            { label: "accent",  set: { tone: "accent" } },
            { label: "success", set: { tone: "success" } },
            { label: "warning", set: { tone: "warning" } },
            { label: "danger",  set: { tone: "danger" } },
            { label: "info",    set: { tone: "info" } }
        ]},
        { label: "weight", options: [
            { label: "tinted", set: { filled: false } },
            { label: "filled", set: { filled: true } }
        ]}
    ]
}
