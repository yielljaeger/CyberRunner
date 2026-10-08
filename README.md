# ⚡ CyberRunner 3D

A fast-paced 3D cyberpunk infinite runner game built with **Godot Engine 4.6**. Sprint down high-speed neon highways flanked by towering skyscrapers, flying speeders, and holographic billboards while dodging laser hurdles, collecting data cores, and triggering nitrous boosts.

---

## 🎮 Gameplay Features

- **Responsive Lane Movement**: Snappy 3-lane switching with smooth horizontal interpolation.
- **Nitrous Boost Mechanic (`[W]`)**: Accelerate your runner to hyper-speeds with particle thrusters and peripheral radial warp speed lines (optimized for crystal-clear screen visibility).
- **Procedural Cyberpunk Environment**:
  - Endless highway chunks dynamically spawning overhead tech arches, holographic city billboards, street lamps, and flying traffic speeders.
  - Balanced starlight key lighting and 4K deep space nebula skybox.
- **Dynamic Obstacle System**:
  - **Low Hurdle**: Amber plasma hurdle requiring a clean jump (`[SPACE]`).
  - **High Laser Gate**: Crimson energy gate requiring an under-slide (`[S]`).
  - **Solid Reinforced Barrier**: High-security barrier requiring a lane switch.
  - *Guaranteed Path*: Every obstacle checkpoint always guarantees at least one safe, open path.
- **Power-Ups & Economy**:
  - **Data Cores (◆)**: Collectible crystals with an ascending pitch streak combo bonus.
  - **Cyber Shield (🛡️)**: Translucent energy bubble that absorbs 1 collision impact and grants recovery invulnerability.
  - **Overdrive (⚡)**: 6 seconds of hyper-speed invulnerability and obstacle demolition (+500 pts smash bonus).
  - **Flux Magnet (🧲)**: 8-second magnetic field pulling all nearby data cores directly into your runner.
- **Difficulty Scaling ("Every 10k")**:
  - **Tier 0 (0 – 9,999 m)**: 1.0x score multiplier, baseline runner speed.
  - **Tier 1 (10,000 – 19,999 m) [Hyper-Surge]**: 2.0x score multiplier, +3.5 m/s speed boost, multi-lane obstacle combos.
  - **Tier 2 (20,000 – 29,999 m) [Overclock]**: 3.0x score multiplier, +7.0 m/s speed boost, double hazard rows per chunk.
  - **Tier 3+ (30,000+ m) [Overdrive]**: Continuous speed and multiplier ramping every 10,000 meters.
- **Cyberpunk Audio & Music**:
  - Looping BGM: *"Endless Cyber Runner"* by Eric Matyas (CC-BY 4.0 via OpenGameArt).
  - Dynamic crash slowdown effect (pitch drop on game over).
  - 11 curated CC0 sound effects for jumping, sliding friction, boost thrusters, data cores, and demolitions.
- **Futuristic HUD**:
  - Real-time Speed & Nitrous Gauge, Score, Distance, Tier Badge, and Salvaged Cores.
  - Active Power-Up countdown badges (`[🛡️ SHIELD]`, `[⚡ OVERDRIVE]`, `[🧲 MAGNET]`).
  - Animated milestone level-up announcements.
  - Comprehensive Game Over breakdown.

---

## 🕹️ Controls

| Key | Action |
| :--- | :--- |
| **`A` / `D`** or **`←` / `→`** | Switch Lanes (Left / Right) |
| **`W`** or **`↑`** | Nitrous Boost (Accelerate) |
| **`SPACE`** | Jump (Leap over Low Hurdles) |
| **`S`** or **`↓`** | Slide / Crouch Dive (Pass under Laser Gates / Fast Fall) |
| **`R`** or **`SPACE`** | Re-initialize / Restart after Crash |

---

## 🚀 Running the Project

1. Clone the repository:
   ```bash
   git clone https://github.com/yielljaeger/CyberRunner.git
   ```
2. Open **Godot 4.6+**.
3. Import the `project.godot` file and press **F5** (or click **Run Project**).

---

## 📜 Credits & License
- Code: MIT License
- 3D Models: Kenney Space & City Kit (CC0 Public Domain)
- Audio SFX: KenneyNL Starter Kits (CC0 Public Domain)
- Music: *"Endless Cyber Runner"* by Eric Matyas ([soundimage.org](https://soundimage.org) / OpenGameArt)
