# Movement System Architecture

## Node Responsibilities
- `MovementManager` (`Core/movement_manager.gd`)
  - Orchestrates physics tick order.
  - Builds a `MovementState`.
  - Queues and applies requested mode changes (`request_mode_change`) inside physics tick.
  - Validates extension/mode setup at startup.
  - Calls extension update hooks.
  - Resolves final movement and rotation outputs.
- `MovementModeManager` (`Core/movement_mode_manager.gd`)
  - Owns active movement mode (`walking`, `climbing`, `flying`, etc.).
  - Applies mode setting overrides from child `MovementMode` nodes.
  - Evaluates mode transition rules from the active mode node.
  - Supports per-transition cooldowns and global mode-switch lock duration.
- `MovementMode` (`Core/movement_mode.gd`)
  - Per-mode configuration node.
  - Declares speed/gravity overrides.
  - Declares extension enable/disable lists.
  - Can apply extension parameter overrides via child override entries.
  - Declares transition rules for that mode.
- `MovementExtension` (`Core/movement_extension.gd`)
  - Feature module (`Locomotion`, `Jump`, `Flight`, `Climb`, etc.).
  - Reads `MovementState`.
  - Updates internal state in `update_extension_state`.
  - Returns movement or rotation contributions.
  - Standard lifecycle signals:
    - `extension_entered`
    - `extension_exited`
    - `extension_active_changed`
  - Use `request_active_state(...)` instead of writing `is_active` directly.

## Frame Data Flow
1. `InputManager` captures actions in `_input` and emits move axis in `_physics_process`.
2. `MovementManager` receives input and enters `_physics_process`.
3. `MovementManager` creates `MovementState`.
4. Active extensions run `update_extension_state`.
5. `MovementModeManager` evaluates transitions and applies mode changes.
6. `MovementManager` blends extension outputs by blend mode.
7. Final velocity + rotation are applied to `CharacterBody3D`.

## Input Ownership
- Input should enter through `Scripts/input_manager.gd`.
- Extensions should avoid direct `Input.*` polling.
- Wire `InputManager` signals to extension handlers in `character.tscn`.
- `InputManager` validates configured Input Map actions on startup.

## Shared Mode Names
- Use `Core/movement_mode_names.gd` constants instead of hard-coded mode strings:
  - `MovementModeNames.WALKING`
  - `MovementModeNames.CLIMBING`
  - `MovementModeNames.FLYING`

## Where New Features Go
- New movement mechanic: create a new `MovementExtension`.
- New high-level traversal state: add a new `MovementMode` child under `ModeManager`.
- New transition logic: add `MovementModeTransitionRule` resources to the mode node.
- New mode-wide numeric override: use `MovementMode` values or `MovementStateSettingOverride`.

## Per-Mode Extension Overrides
- Preferred: add override nodes as direct children of each mode node.
- For each override node:
  - set `target_extension_path` (example: `Locomotion`, `Jump`, `Flight`)
  - path resolution checks override-node relative path first, then `MovementManager`-relative path
  - optional activation control:
    - `override_extension_active_state`
    - `extension_should_be_active`
  - enable only the `override_*` values you want to apply
- Current typed override nodes:
  - `LocomotionExtensionOverride`
  - `RotationExtensionOverride`
  - `JumpExtensionOverride`
  - `SprintExtensionOverride`
  - `CrouchExtensionOverride`
  - `ImpulseExtensionOverride`
  - `FlightExtensionOverride`
  - `ClimbExtensionOverride`
  - `GravityExtensionOverride`
- Extension settings are reset to defaults on mode switch, then active mode overrides are applied.
- Mode precedence:
  - mode `enabled_extensions` / `disabled_extensions` are applied first
  - extension override node activation (`override_extension_active_state`) is applied after and wins

## Debugging
- `MovementDebugOverlay` (`Debug/movement_debug_overlay.gd`) shows:
  - current mode
  - grounded state
  - move input
  - velocity
  - active extensions
- Toggle with action: `movement_debug_toggle` (if configured in Input Map).
