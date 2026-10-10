> Superseded delta; never promote its travelling geometry into durable specs. The new rollout-expansion delta carries forward its valid endpoint guarantees.

## ADDED Requirements

### Requirement: Retraction ends at the origin wall
Attached Rollout body travel SHALL end exactly at its border origin wall without
parking overtravel. Effective content/shader deformation SHALL reach identity at
zero outness. Zero-outness slots SHALL contribute no fill, rim, stroke gate or
frame join, leaving the original border unchanged without a later recovery step.

#### Scenario: Last frame of retract
- **WHEN** an attached Rollout reaches hidden progress
- **THEN** its free body edge is on the origin wall, deformation is identity, and
  its shader contribution is absent before registry removal

#### Scenario: Fully shown flush child
- **WHEN** a nested rollout has zero seam blend but nonzero outness
- **THEN** it keeps its exact parent seam and frame join, rather than being skipped

### Requirement: Full silhouette translates behind the origin wall
An attached Rollout SHALL register its actual full-size translated body for
painting and its clipped viewport for input. Reveal/retract SHALL NOT resize its
painted body's radii or default content scale. Content and shader deformation
SHALL use the same translated body centre. Existing curves and suppression remain.

#### Scenario: Retract a body
- **WHEN** an attached rollout closes
- **THEN** its body and content translate under the stationary border with fixed
  body dimensions/radii while only the exposed viewport decreases

#### Scenario: Reverse closing or attach at another edge
- **WHEN** close reverses or another declared edge/nested host is used
- **THEN** the same full-body translation rule applies without a second local motion

#### Scenario: Hidden body under the border
- **WHEN** part of the translated body is beneath the frame
- **THEN** painting may retain that hidden geometry but hit registration includes
  only the exposed viewport, not the hidden full-size body

#### Scenario: Register a retracting body at its origin
- **WHEN** the full-size body moves through its declared origin side beyond screen bounds
- **THEN** ShellBorder does not snap or truncate that side to the screen; the
  shader retains the full body and its translated pivot until absorbed
- **AND** automatic snapping remains available on non-origin contact sides

### Requirement: Closing preserves the existing border stroke and paint endpoint
A closing slot SHALL gate only its newly exposed stroke, not the existing
frame/parent boundary. Its fill and rim distance-field contributions SHALL
converge to the incoming union with outness, so removing a hidden slot does not
change the contour, interior stroke depth or lighting gradient of that union.

#### Scenario: Finish closing beside a persistent handle
- **WHEN** the attached body reaches its origin wall and its slot is removed
- **THEN** the fixed border and persistent handle do not extinguish then recover
  their stroke or undergo a separate lighting/geometry settle
