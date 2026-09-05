import QtQuick

import qs.QsmShell.Style

// THE text. One type, one axis: what ROLE this text plays.
//
// WHY it exists, measured: `font.pixelSize` was typed by hand 104 times in the
// one consuming shell and 40-odd more inside this library, always as the same
// three-line incantation — family, size, weight — and often a fourth line that
// disagreed with its neighbours. That is not a scale, it is a scale plus a
// hundred chances to leave it. A role names the DECISION ("this is a section
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
//   metadata  supporting text: a timestamp, a source, a subtitle.
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

    // hero | display | heading | title | body | label | metadata | reading | section
    property string role: "label"

    // Muted is a ROLE modifier, not a colour choice: it says "this text is
    // supporting" once, instead of asking every call site to remember which
    // grey. A call site that needs a specific colour still sets `color`.
    property bool muted: false

    readonly property bool _wraps: role === "body"
    readonly property bool _technical: role === "reading"

    color: muted || role === "metadata" || role === "section" ? Style.textMuted : Style.text

    font.family: _technical ? Style.technicalFontFamily : Style.fontFamily
    font.pixelSize: {
        switch (role) {
        case "hero": return Style.textHero;
        case "display": return Style.textDisplay;
        case "heading": return Style.textXl;
        case "title": return Style.textMd;
        case "body": return Style.textSm;
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
        case "metadata": return Style.weightRegular;
        default: return Style.weightMedium;
        }
    }
    // A big number is set tight — at 44px the default leading opens a gap the
    // eye reads as two separate things.
    lineHeight: _wraps ? Style.lineBody
        : role === "hero" || role === "display" || role === "heading" ? Style.lineHeading
        : 1
    // The section rule is the one role whose shape is not just size and
    // weight: it is small, spaced out, and capitalised, and those three
    // together are what make it read as a rule rather than as a short label.
    font.letterSpacing: role === "section" ? 1.4 : 0
    font.capitalization: role === "section" ? Font.AllUppercase : Font.MixedCase

    // Numbers that change must not shift the text beside them. This is why a
    // reading is a role and not just "body in the mono face".
    font.kerning: !_technical

    wrapMode: _wraps ? Text.WordWrap : Text.NoWrap
    textFormat: Text.PlainText
    // Text that cannot fit says so with an ellipsis rather than by running out
    // of its container. Wrapping text has somewhere to go and is left alone.
    elide: _wraps ? Text.ElideNone : Text.ElideRight
}
