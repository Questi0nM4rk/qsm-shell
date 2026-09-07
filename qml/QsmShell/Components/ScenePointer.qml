import QtQuick

// Declare this directly inside the item that is the ANCESTOR of the surfaces
// a keep-open test cares about -- never as a sibling stacked with them.
//
//     Item {
//         id: scene
//         ScenePointer { id: pointer }
//         // every surface below, at any depth, keeps its own hover ...
//     }
//
// A `HoverHandler` on a sibling item is shadowed rather than shared: only the
// one nearest the pointer along the stack is notified. Placed BELOW an
// interactive surface it never sees the pointer at all; placed ABOVE one it
// steals hover from everything underneath instead of reporting alongside it.
// On the ancestor there is no stacking to shadow, so this handler and every
// handler on a descendant are told about the pointer independently.
HoverHandler {
    id: root

    // The pointer's point, in the coordinates of the item this is declared
    // on. Holds its last real value once the pointer has left -- a
    // `PointerHandler` has nothing to reset it to -- so read it through
    // `inside` or `contains()`, never on its own.
    readonly property point position: point.position

    // Whether the pointer is actually over this scene right now.
    readonly property bool inside: root.hovered

    // The call a keep-open test actually wants: true when the pointer is
    // inside `rect` (in this item's coordinates) AND still `inside` the
    // scene. Without this every caller re-derives
    // `inside && rect.contains(position)` by hand, and the next one forgets
    // the `inside` half and keeps something open for a ghost position.
    function contains(rect) {
        return root.inside
            && root.position.x >= rect.x && root.position.x <= rect.x + rect.width
            && root.position.y >= rect.y && root.position.y <= rect.y + rect.height;
    }
}
