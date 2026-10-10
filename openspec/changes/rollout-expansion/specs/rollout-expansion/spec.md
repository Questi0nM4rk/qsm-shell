## ADDED Requirements

### Requirement: Expansion belongs to one registered source silhouette
The existing Rollout type SHALL expand a frame band or a parent Rollout registered
in the same rendering host. It SHALL supply geometry to the existing ShellBorder
union renderer and SHALL NOT paint a full-body backdrop or create another shader
or registry. An arbitrary QML parent Item SHALL NOT be treated as a silhouette
source merely because it contains the Rollout.

#### Scenario: Expand the frame
- **WHEN** a left or right frame-attached Rollout opens
- **THEN** its growing contour and source frame are rendered as one silhouette
- **AND** its wrapper supplies no travelling-background or counter-translation fix

#### Scenario: Expand a parent Rollout
- **WHEN** a child declares a parent Rollout in the same host
- **THEN** its source is that parent's settled full-body edge in host coordinates
- **AND** it can extend beyond the parent's clipping aperture without being clipped by it

### Requirement: Full-size content stays fixed relative to reveal origin
Rollout SHALL require caller-supplied bodyWidth and bodyHeight, expose its full-size
content slot as readonly contentItem, and keep that content's size and source-relative
position independent of reveal progress. The aperture SHALL grow on the axis named
by edges[0] with progress clamped to zero through one. Additional edge contacts
SHALL NOT add another reveal axis. Preferred body size SHALL NOT be inferred from
moving or clipped childrenRect.

#### Scenario: Open and close on any frame side
- **WHEN** an attached Rollout reveals or retracts with unchanged requested body size
- **THEN** full-size content stays at its settled source-relative position
- **AND** only the clip/paint aperture changes along the declared reveal axis

#### Scenario: Content supplies a new preferred size
- **WHEN** the host explicitly changes a body dimension while open
- **THEN** content and contour follow the same size-animation owner
- **AND** that resize is distinct from scaling content during reveal

### Requirement: Normal placement derives from the source container
Frame-attached Rollout SHALL resolve default source depth from the host's leftEdge
or edge as appropriate, with Style.frameThickness fallback for injected registry
hosts that expose no band geometry. Explicit edgeInset overrides SHALL remain
available. Anchor centring and optional nudge SHALL affect only the free axis.
Nested origin placement SHALL use settled parent extents rather than the parent's
animated viewport extent.

#### Scenario: Asymmetric frame
- **WHEN** a host has a wider left band than its other bands
- **THEN** a normally configured left Rollout starts at that band's inner face
- **AND** the caller need not duplicate a desktop-specific band constant

#### Scenario: Parent reveals while child exists
- **WHEN** the parent's reveal progress changes without a source placement or requested size change
- **THEN** the child's origin does not drift with the parent's aperture width or height

### Requirement: Aperture contour and identity deformation are the attached standard
An attached Rollout SHALL register its aperture as silhouetteRect, square its
source-side corners and clamp free radii against current aperture half extents.
Content and shader deformation SHALL be identity; reveal SHALL NOT introduce goo,
independent content scaling, opacity fade, origin-wall movement or parking travel.
The final public API SHALL NOT require a borderExtrusion style toggle.

#### Scenario: Barely revealed contour
- **WHEN** the expansion has less depth than its normal corner radius
- **THEN** free radii remain bounded by the current aperture dimensions
- **AND** content remains full-size rather than squashed into that small aperture

#### Scenario: Existing deformation state
- **WHEN** a converted Rollout has stale deformation state from an earlier travelling mode
- **THEN** that state cannot deform the attached expansion's paint or content

### Requirement: Shader composition preserves source and neighbour edges
ShellBorder and its shader SHALL retain non-origin edge joins, capped frame welds,
parent/child corner coverage, exact full-span seams and seam overlap. Blend and
outness SHALL remain separate facts. A child SHALL NOT extend paint through an
unrelated source or invent a stroke line at an internal full-span seam.

#### Scenario: Full-span nested child
- **WHEN** a child expands across the parent's full free-axis span
- **THEN** the shared seam is an exact continuous union without a gap, bulge or lit internal line
- **AND** zero seam blend does not hide an otherwise emerged child

#### Scenario: Short nested child
- **WHEN** a shorter child expands from the middle of the parent edge
- **THEN** exposed parent boundaries remain visible above and below the child
- **AND** the T-junction retains the appropriate joined contour

### Requirement: The host owns intent and consequences
Rollout SHALL retain host-owned shouldBeActive and suppressed inputs, report
triggered, hovered, keepOpen, wantsOpen and animating, and own the common area
containment and grace mechanism. It SHALL NOT mutate host state, manage dismissal,
invent keyboard focus policy or take a screen-reader role from its content.
Pointer, keyboard and programmatic content routes SHALL keep their native action
semantics without synthetic events from reveal state changes.

#### Scenario: Leave the open area
- **WHEN** the pointer leaves every trigger and hover area and no descendant holds the source
- **THEN** Rollout reports its common grace verdict to the host
- **AND** the host decides whether and what to close without reimplementing containment

#### Scenario: Keyboard-retained content
- **WHEN** a surface retains a password prompt or modal keyboard interaction
- **THEN** that retention remains host policy
- **AND** a generic Rollout does not infer permanent retention from a focused child

### Requirement: Input never follows hidden or retired paint
Rollout's registered input SHALL be only the exposed viewport near settled reveal
and SHALL be withdrawn on semantic close or suppression. Hidden full-body content,
weld continuation and edge-snapped paint SHALL NOT enlarge that input region.
Wrappers SHALL disable retired content actions immediately while retaining their
visuals. registerHitRect false SHALL preserve a modal host's separate catch policy.

#### Scenario: Close while still visibly expanded
- **WHEN** host intent changes to closed while the contour is still painted
- **THEN** the Rollout's own input registration is withdrawn
- **AND** outgoing visuals and dimensions survive until the transition is hidden

#### Scenario: Paint joins another band
- **WHEN** registration extends the contour to a nearby non-origin frame side
- **THEN** that paint-only extension does not become additional clickable application space

### Requirement: Hidden slot removal is neutral
At zero reveal depth, outness SHALL be zero and content/shader deformation SHALL
be identity before slot removal. The slot SHALL preserve the incoming fill/rim
distance fields, existing edge gate, stroke depth and lighting gradient. Removal
SHALL NOT introduce another motion, relighting, recovery timer or border sink.

#### Scenario: Retract beside a persistent handle
- **WHEN** the aperture reaches zero and its slot is removed
- **THEN** the source border and persistent handle retain the same contour and lighting
- **AND** the removed slot contributes no fill, rim, stroke gate or input

### Requirement: Progress and content sizing have distinct animation ownership
Rollout SHALL retain the shared small/large reveal and retract tokens, retarget
reversals from current progress without overshoot and respect reducedMotion.
animateBodySize SHALL enable a single target-size morph or allow already animated
child extents to pass through directly. Existing notification row motion SHALL NOT
receive a second expansion-owned entrance, scale or size animation.

#### Scenario: Reverse before settling
- **WHEN** the host reverses open intent during reveal or retract
- **THEN** the same progress value continues from its current state without jumping
- **AND** the source-relative full-size content position remains unchanged

#### Scenario: Animated notification extent
- **WHEN** row eviction or expansion already animates the stack's actual height
- **THEN** its Rollout uses those extents without an additional body-height lag
- **AND** last-content retention and immediate input withdrawal remain intact

#### Scenario: Suppress or reset
- **WHEN** the surface is suppressed or its host resets the example
- **THEN** pending animation/grace is cancelled without a later completion or control activation

### Requirement: Detached presentation and source migration remain explicit
Attached expansion SHALL NOT paint or require a frame on a fullscreen-detached
presentation. Existing capsule behaviour SHALL remain governed by its separate
contract. Coordinated source migration SHALL account for intended attached callers
before removing the obsolete travelling API and attached-only physics. Detached
compatibility SHALL NOT provide an attached style selector. A source-reviewed case
SHALL NOT be labelled runtime-verified or accepted; live review stays one item at a time.

#### Scenario: Enter fullscreen
- **WHEN** the consumer switches to its permitted fullscreen capsule presentation
- **THEN** the attached expansion does not invent a frame source
- **AND** the consumer's existing content, service lifetime and fullscreen input policy remain separate

#### Scenario: Adopt attached consumers together
- **WHEN** the owner authorizes full attached source migration
- **THEN** intended callers' geometry-selection workarounds and duplicate size ownership are removed
- **AND** content retention, detached presentation and unrelated desktop work are preserved
