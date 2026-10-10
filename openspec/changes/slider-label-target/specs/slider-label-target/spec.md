## ADDED Requirements

### Requirement: Slider exposes its existing label item
Slider SHALL provide readonly Item `labelItem` referencing its actual ControlLabel.
The reference SHALL preserve item identity during value/state/label changes and
SHALL NOT introduce a separate action route or modify its geometry or appearance.

#### Scenario: Consumer targets a clickable label
- **WHEN** a consumer obtains labelItem on a Slider with labelClickable enabled
- **THEN** it obtains the same real label whose existing activation emits labelClicked

#### Scenario: Label is passive or empty
- **WHEN** labelClickable is false or label content is empty
- **THEN** labelItem remains the same reference, with its existing passive/visibility
  behavior rather than an invented clickable fallback
