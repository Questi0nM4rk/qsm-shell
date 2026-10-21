import QtQuick

import qs.QsmShell.Style

// THE text. One axis carries almost everything: what ROLE this text plays.
// The FACE is the one thing a role does not decide, and `technical` is it.
//
// WHY it exists: a hand-typed `font.pixelSize` is always the same three-line
// incantation — family, size, weight — and often a fourth line that disagrees
// with its neighbours. That is not a scale, it is a scale plus a hundred
// chances to leave it. A role names the DECISION ("this is a section
// heading") instead of restating its three consequences, so the decision can
// be changed in one place and cannot be half-applied.
//
// The roles are the type scale's semantic layer, and there are eight because
// that is how many kinds of text a shell actually has:
//
//   hero      a number read from across the room. A clock, nothing else.
//   display   a big reading — a temperature, a ring's value.
//   heading   the title of a surface.
//   title     the title of a thing inside a surface: a card, a row.
//   body      prose that wraps. The only role that gets a body line height.
//   label     the name of a control or a field. The default.
//   metadata  the fine print: a timestamp, a source, a count.
//   supporting  metadata's job one step up the scale: the line that explains
//             the thing above it and is meant to be READ, not skimmed past.
//             Same shape as metadata, at body size.
//   reading   a VALUE, in the technical face — a percentage, an address, a
//             key combination. Tabular by intent: numbers that change must not
//             move the text around them.
//   section   the small capitalised rule over a group of rows.
//
// `lineHeight` belongs to wrapping text ONLY. On a single line it grows the
// line box and the glyphs stop sitting in the middle of it, which is why the
// tight roles below leave it at 1 rather than at some ratio that looks
// harmless in isolation.
Text {
    id: root

    // hero | display | heading | title | body | label | supporting | metadata | reading | section
    property string role: "label"

    // Muted is a ROLE modifier, not a colour choice: it says "this text is
    // supporting" once, instead of asking every call site to remember which
    // grey. A call site that needs a specific colour still sets `color`.
    property bool muted: false

    // The mono face, as a SECOND axis rather than a consequence of the role.
    //
    // A clock is a hero AND technical, a temperature is a display AND
    // technical, a percentage under an icon is metadata AND technical. None of
    // those is a "reading" — they are their own roles, at their own sizes,
    // that happen to be made of digits. Tied to one role, each would have to
    // abandon Prose and hand-type family, size and weight to get the face.
    //
    // It still DEFAULTS from the role, so a reading needs to say nothing.
    property bool technical: role === "reading"

    readonly property bool _wraps: role === "body"
    readonly property var _roles: ["hero", "display", "heading", "title", "body",
        "label", "supporting", "metadata", "reading", "section"]

    // A misspelt role still renders as label, so it says so once per role
    // value instead of passing for a deliberate label.
    function _checkRole(): void {
        if (_roles.indexOf(role) < 0)
            console.warn(`Prose: unknown role "${role}" -- rendering as "label"`);
    }
    Component.onCompleted: _checkRole()
    onRoleChanged: _checkRole()

    color: muted || role === "supporting" || role === "metadata" || role === "section" ? Style.textMuted : Style.text

    font.family: technical ? Style.technicalFontFamily : Style.fontFamily
    font.pixelSize: {
        switch (role) {
        case "hero": return Style.textHero;
        case "display": return Style.textDisplay;
        case "heading": return Style.textXl;
        case "title": return Style.textMd;
        case "body": return Style.textSm;
        case "supporting": return Style.textSm;
        case "metadata": return Style.textXs;
        case "reading": return Style.textSm;
        case "section": return Style.textXs;
        default: return Style.textSm;
        }
    }
    font.weight: {
        switch (role) {
        case "hero":
        case "display":
        case "heading":
        case "title":
        case "reading":
        case "section": return Style.weightBold;
        case "body":
        case "supporting":
        case "metadata": return Style.weightRegular;
        default: return Style.weightMedium;
        }
    }
    // ONLY the wrapping role gets a line height. Everything else is a single
    // line, where a ratio above 1 grows the line box and the glyphs stop
    // sitting in the middle of it — the library's own law, broken here for
    // three roles because a big number "looked like it wanted air". It does
    // not: at 44px the default leading already opens a gap the eye reads as
    // two separate things.
    lineHeight: _wraps ? Style.lineBody : 1
    // The section rule is the one role whose shape is not just size and
    // weight: it is small, spaced out, and capitalised, and those three
    // together are what make it read as a rule rather than as a short label.
    font.letterSpacing: role === "section" ? Style.trackingWide : 0
    font.capitalization: role === "section" ? Font.AllUppercase : Font.MixedCase

    // Numbers that change must not shift the text beside them, which is the
    // whole reason the face exists as its own axis: it is a TABULAR decision,
    // and it applies at every size a number is written at.
    font.kerning: !technical

    wrapMode: _wraps ? Text.WordWrap : Text.NoWrap
    textFormat: Text.PlainText
    // Text that cannot fit says so with an ellipsis rather than by running out
    // of its container. A wrapping body only meets its limit through
    // maximumLineCount or an explicit height; Qt elides it then and never
    // otherwise, so ElideRight is safe for an unbounded body too.
    elide: Text.ElideRight
}
