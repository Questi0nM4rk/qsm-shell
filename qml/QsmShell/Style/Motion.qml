pragma Singleton

import QtQuick

import qs.QsmShell.Style

// THE motion vocabulary. Two questions only: how long, and along which curve.
//
// Duration is named by the ROLE of the change, never by a number, so a call
// site says what it is doing rather than how many milliseconds it wants.
// Nothing a person is waiting on runs longer than `fast`; anything above that
// is a surface arriving or leaving, which is a different kind of event.
//
// Curves come in three, and the split is not decoration. A thing arriving
// should land — decelerate into place, so the eye catches it at the end. A
// thing leaving should get out of the way — accelerate away, because nobody
// watches an exit. A thing MOVING between two places it already occupies is
// neither, so it eases at both ends.
//
// Reduced motion shortens every duration rather than removing the animation:
// a change with no transition at all reads as a glitch, not as calm.
QtObject {
    // press — the acknowledgement under a finger. Anything slower feels late.
    readonly property int press: Style.reducedMotion ? 40 : Tokens.motionPress
    // micro — hover, toggle, a colour or opacity settling.
    readonly property int micro: Style.reducedMotion ? 60 : Tokens.motionMicro
    // microPop — a small surface arriving with a scale settle (a card's
    // entrance). Distinct from `micro`: it carries its own tuned duration
    // rather than reusing the hover/toggle number, so retuning one does not
    // silently retune the other.
    readonly property int microPop: Style.reducedMotion ? 60 : Tokens.motionMicroPop
    // microPopDuration — the same settle, named for a host whose content
    // slot rides it directly (Rollout's `settleContent`). One fact, two
    // names during the transition: retuning `microPop` retunes this too.
    readonly property int microPopDuration: microPop
    // microPopScale — the one settle scale every micro-pop entrance shares
    // (0.97: barely a press, just enough to read as arriving rather than
    // appearing). Unlike the duration it does not shorten under reduced
    // motion; reduced motion asks for less TIME, not a smaller shape.
    readonly property real microPopScale: Tokens.motionMicroPopScale
    // Capsules span a label and optional reading, so their hover response is
    // quieter than an icon target's default growth.
    readonly property real capsuleHoverScale: Tokens.motionCapsuleHoverScale
    // fast — a control changing shape, a row disclosing. The ceiling for
    // anything the pointer or the keyboard is waiting on.
    readonly property int fast: Style.reducedMotion ? 80 : Tokens.motionFast
    // medium — a popout or a menu arriving.
    readonly property int medium: Style.reducedMotion ? 100 : Tokens.motionMedium
    // large — a whole surface rolling out or retracting.
    readonly property int large: Style.reducedMotion ? 120 : Tokens.motionLarge

    // ── the rollout tier ────────────────────────────────────────────────
    // A rollout is not a surface arriving on top of another one: it is the
    // border BULGING, one continuous silhouette deforming. That is a different
    // event from `large`, it is slower on purpose, and it carries its own
    // curves -- which is why it gets its own names rather than reusing the
    // surface tier at a different number.
    //
    // Two tiers, and the split is size: a whole panel unrolling reads wrong at
    // the speed a popout should take, and a popout at panel speed reads as a
    // hesitation.
    readonly property int revealLarge: Style.reducedMotion ? 120 : Tokens.motionRevealLarge
    readonly property int revealSmall: Style.reducedMotion ? 120 : Tokens.motionRevealSmall
    // morphGlide -- one entry MORPHING into the next while both stay on
    // screen. Same number as revealSmall today and deliberately its own token:
    // a glide and a reveal are different events and must be retunable apart.
    readonly property int morphGlide: Style.reducedMotion ? 120 : Tokens.motionMorphGlide

    // The reveal curves are bezier control points, not durations, so they are
    // constants rather than theme tokens: a theme changes how long the border
    // takes, never what shape the deformation has.
    //
    // NO overshoot in either. A spring was tried and cut: overshoot made every
    // reveal read as a popup landing on top of the shell rather than as the
    // border itself moving. Where organic feel is wanted, the goo deformation
    // supplies it -- the curve stays honest.
    //
    // Reveal is a strong decelerate: fast out of the border, soft landing.
    readonly property var revealCurve: [0.05, 0.7, 0.1, 1.0, 1.0, 1.0]
    // Retract is a gentle accelerate-decelerate. It is NOT an exit curve: the
    // border does not leave, it returns to rest, and an exit curve there reads
    // as the surface being yanked away.
    readonly property var retractCurve: [0.3, 0.0, 0.2, 1.0, 1.0, 1.0]

    // ── loops ───────────────────────────────────────────────────────────
    // Everything above names a ONE-SHOT change: how long a thing takes to
    // arrive or to leave. A loop is a different quantity — it has a period,
    // not a duration — and reduced motion must LENGTHEN it rather than
    // shorten it. Shortening a duration calms a transition; shortening a
    // period makes a spinner whirr, which is the opposite of the request.
    //
    // spin — one full turn of an indeterminate indicator.
    readonly property int spin: Style.reducedMotion ? Tokens.motionSpin * 2 : Tokens.motionSpin
    // pulse — one breath of a placeholder or a waiting surface.
    readonly property int pulse: Style.reducedMotion ? Tokens.motionPulse * 2 : Tokens.motionPulse

    // hoverGrace — how long a rollout stays reported `keepOpen` after the
    // pointer leaves its hover area (Rollout.hoverAreas). Neither a duration
    // nor a period: it is an interaction TIMEOUT, not a visual transition, so
    // it does not shorten under Style.reducedMotion the way a duration does —
    // reduced motion asks for calmer animation, not a different dead-zone.
    readonly property int hoverGrace: Tokens.motionHoverGrace

    // Enter: decelerate in, so the arrival is where the eye lands.
    readonly property int standardEasing: Easing.OutCubic
    // Enter, with more authority — a surface rather than a control.
    readonly property int emphasizedEasing: Easing.OutQuart
    // Exit: accelerate away. Using an enter curve on an exit is why a
    // disappearing thing can feel like it hesitated.
    readonly property int exitEasing: Easing.InCubic
    // Move or resize between two states that both already exist: eased at
    // both ends, because neither end is an arrival.
    readonly property int moveEasing: Easing.InOutCubic
}
