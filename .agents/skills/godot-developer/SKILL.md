---
name: godot-developer
description: >-
  Expert Godot Engine 4.x game development skill. Use whenever creating, modifying,
  debugging, or testing Godot projects, GDScript code, 3D/2D gameplay mechanics,
  physics, materials, Label3D typography, camera controllers, procedural generation,
  audio managers, or running headless automated tests in Godot.
---

# Godot 4.x Game Developer Skill

This skill captures best practices, architectural patterns, and debugging runbooks for developing high-performance 2D and 3D games in Godot Engine 4.x (GDScript).

---

## 1. Automated Headless Testing & Verification

Always verify Godot code changes using headless execution without requiring GUI interaction:

### Running Test Scripts
Subclass `SceneTree` in lightweight standalone test scripts to verify logic, math, node structures, and gameplay systems:
```powershell
.\Godot_v4.6.2-stable_win64.exe --headless --script tests/test_feature.gd | Out-String
```

### Standalone Test Script Template
```gdscript
extends SceneTree

const ObstacleScript = preload("res://scripts/obstacle.gd")

func _init() -> void:
    print("--- RUNNING VERIFICATION TEST ---")
    var obj = ObstacleScript.create(...)
    root.add_child(obj)

    assert(obj != null, "Object should instantiate")
    assert(obj.collision_layer == 4, "Collision layer should be 4")

    # Clean up before quitting
    obj.free()
    print("[PASS] All assertions succeeded.")
    quit(0)
```

### Headless Scene Verification
Smoke-test full game scenes to catch runtime errors, missing nodes, and shader compilation failures:
```powershell
.\Godot_v4.6.2-stable_win64.exe --headless scenes/main.tscn
```

---

## 2. 3D Transforms, Basis Math & Rotation Traps

### The Euler Angle YXZ Hazard in Godot 4
Godot 4 evaluates `Node3D.rotation_degrees` using **`EULER_ORDER_YXZ`** by default.
- Setting `rotation_degrees = Vector3(90.0, 22.5, 0.0)` does **NOT** rotate an object 22.5° around its own face normal!
- Because $Y$ (yaw) is evaluated first in world space, the object swings like an open door ($15+\text{cm}$ forward on one side, backward on the other), burying planar labels and causing half-clipped text!

### Correct Solution: Compose Basis Directly
When orienting 3D geometry (such as octagons, cylinders, or signs facing oncoming gameplay along $+Z$):
```gdscript
# Orient cylinder axis along Z (+90° X), then spin 22.5° around normal (Z)
var oct_basis: Basis = Basis(Vector3.FORWARD, deg_to_rad(22.5)) * Basis(Vector3.RIGHT, deg_to_rad(90.0))
mesh_instance.transform.basis = oct_basis
```
**Golden Rule**: When you need all vertices of a face to lie on an exact flat plane parallel to the camera/runner, never use multi-axis Euler angles. Use `Basis` multiplication.

---

## 3. 3D Text & Typography (`Label3D`)

To prevent text clipping, z-fighting, or occlusion behind glowing shaders:

1. **Layer & Transparency Priorities**:
   ```gdscript
   label.render_priority = 10     # Render on top of transparent geometry
   label.sorting_offset = 2.0     # Camera sorting bias
   label.double_sided = false     # Prevent bleed-through from the back
   label.no_depth_test = false    # Keep true 3D occlusion while avoiding z-fighting
   ```
2. **Safe Depth Separation**:
   Position the `Label3D` floating slightly proud ($6\text{--}8\text{mm}$) in front of the supporting mesh:
   ```gdscript
   label.position = parent_pos + Vector3(0, 0, 0.032)
   ```
3. **Text Sizing & Bounds**:
   - In Godot `Label3D`, text height in meters is approximately `font_size * pixel_size` (e.g. $50 \times 0.005 = 0.25\text{m}$).
   - Set `outline_size = 8` to `12` with a dark outline color for high contrast against glowing cyberpunk backgrounds.
   - Avoid oversized outlines ($\ge 16\text{px}$) as font texture glyphs will bleed together.

---

## 4. Collision Shapes & Hitbox Clearances

In runner, platformer, and action games, design clearance thresholds deliberately:

- **Low Hurdles (Jump Clearances)**:
  - Hurdle height $\approx 0.45\text{m}$.
  - Player standing hitbox height $\approx 1.8\text{m}$, jump velocity reaches $Y \ge 2.2\text{m}$.
- **High Gates (Slide Clearances)**:
  - Gate collision clearance underneath is $0.88\text{m}$ (box spans $Y = 0.88\text{m}$ to $2.4\text{m}$).
  - Player crouch/slide hitbox height shrinks to $0.72\text{m}$—sliding passes underneath cleanly.
  - Player standing/jumping triggers upper-body collision.
- **Barrier Framing**:
  - Never place solid glowing laser fields intersecting directly through decorative meshes (like signs or text).
  - Split laser barriers into left and right wings with top/bottom rails, framing a clear central window.

---

## 5. Visual Effects & High-Speed Nitrous Shaders

- **Nitrous & Speed Boost Visuals**:
  - Keep full-screen post-processing and tunnel speed effects at $\le 50\%$ opacity so the player's view of obstacles is never blocked.
  - Pair speed boosts with a dynamic FOV ramp (e.g., $75^\circ \to 86^\circ$) and subtle kinetic camera shake ($0.015\text{m}$).
- **Neon Materials & Bloom**:
  - Use `BaseMaterial3D.SHADING_MODE_UNSHADED` with `emission_energy_multiplier` ($3.0\text{--}4.5$) for neon strips, tripwires, and billboards.

---

## 6. Procedural Generation & Difficulty Scaling

- **Tiered Spawning**:
  - Tier 0 ($0\text{--}10\text{km}$): 1 hazard per row, 2 wide-open lanes for relaxed pacing.
  - Tier 1 ($10\text{k}\text{--}20\text{km}$): 2 hazards per row, introducing jump vs slide decisions.
  - Tier 2+ ($20\text{km}+$): Complex multi-hazard patterns and faster ramp rates.
- **Fairness Golden Rule**:
  - Never generate an impossible row (never block all 3 lanes with impassable solid barriers). Always ensure at least one valid path.

---

## 7. Dynamic Audio Management

- Centralize audio in an `AudioManager` autoload or manager node.
- Modulate SFX playback using pitch randomization ($\pm 10\%$) to keep repetitive sounds (footsteps, boosts, pickups) fresh.
- Separate buses for `Master`, `Music`, and `SFX` for clean balance.
