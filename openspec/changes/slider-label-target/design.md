## Context

Slider already owns one ControlLabel for the host's text/icon and optional action.
Desktop OSD uses that action as mute and needs its native target in its story.

## Goals / Non-Goals

Goal: expose the existing item through readonly property Item labelItem.
Non-goals: any new controls, layout, hitbox, state, action or desktop policy.

## Decisions

Reference the existing ControlLabel by its QML id, not a tree search or duplicate
item. The property exists even when the label is empty/noninteractive; the label's
existing visibility and enabled state govern whether it is an input target.
All existing settings, sizes, five states, focus, accessibility and overflow stay
as described in docs/components/Slider.md. No pixel or token changes.

## Risks / Trade-offs

Exposing the object permits external use of it; callers must treat it as a native
target, not replace library-owned content or handlers. Runtime review remains
unrequested; source implementation is not owner acceptance.
