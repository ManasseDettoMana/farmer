# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

An **isometric idle + click farm game** built in **Godot 4.6 (2D)**. The player starts with a 4×4
isometric land block, earns points over time (idle) and by clicking owned land (click bonus), and
spends points to place income-generating structures and buy more 4×4 land blocks. NPCs (a farmer and
animals) wander autonomously. Visual reference: `assets/inspo.jpeg`.

Despite the project's 3D/Jolt settings, this is a **2D game** — use Godot 2D nodes and `Area2D` for
click/hit detection. The active task plan lives at
`C:\Users\eleon\.claude\plans\i-want-to-create-jolly-sifakis.md`; progress is tracked in `todo.md`.

### Core design decisions (locked)
- **Economy**: idle income (points/sec from structures) **plus** a click bonus on owned land.
- **Land**: start 4×4; expand by buying another full **4×4 block** placed adjacent.
- **Buildings**: each occupies **one tile**.
- **No combat** — peaceful farm.
- **Camera**: pans, **never rotates**. View is 2:1 isometric (tile corners point up/down/left/right).
- **Placement**: Clash-of-Clans style — buy → ghost at first free cell → drag/snap → **green ✓ / red ✗**.

## Architecture

GDScript only (no C#/Mono). Planned layout (see the plan file for detail):
- `autoload/` — `IsoUtils.gd` (tile constants `TILE_W=128`/`TILE_H=64` + grid↔world math),
  `Catalog.gd` (structure/land definitions), `GameState.gd` (points, points/sec, owned cells, placed
  structures, tick, save/load to `user://save.json`, signals).
- `scenes/Main.tscn` — root: background, `Camera2D` (pan + clamp), `IsoWorld`, `HUD` CanvasLayer.
- `scenes/world/` — `IsoWorld` (non-sorted **GroundLayer** of `LandTile`s drawn first + a
  `y_sort_enabled` **EntityLayer** for structures + NPCs), `LandTile` (diamond via `_draw()`),
  `Structure`, `Villager`, `Animal`.
- `scenes/ui/` — `HUD` (top points bar, bottom-center action dashboard, minimap), `MarketPanel`.
- `scenes/placement/PlacementController.gd` — one ghost flow reused for structures **and** land blocks.
- `util/SpriteSheet.gd` — builds `SpriteFrames` at runtime from strip/grid sheets via `AtlasTexture`.

**Depth**: ground tiles live in a non-y-sorted layer drawn first; structures/NPCs in a
`y_sort_enabled` layer set their `position.y` at their "feet" so sorting is correct.

## Engine configuration

`project.godot` pins choices that affect how code and tools must behave:
- **Godot 4.6**, **Forward Plus** renderer.
- Rendering device driver on Windows is **D3D12** (`rendering_device/driver.windows="d3d12"`), not Vulkan.
- 3D physics engine is **Jolt Physics** (`3d/physics_engine="Jolt Physics"`).

Edit `project.godot` through the Godot editor UI when possible rather than by hand — its parameters are not
all obvious and the editor keeps related metadata in sync.

## Working with the project

- Open/edit in the **Godot 4.6 editor** (GUI-driven; there is no npm/build script to run).
- Run from CLI (if the Godot binary is on PATH): `godot --path .` to launch, or `godot --path . --headless`
  for a headless run. The main scene is set via `[application] run/main_scene` in `project.godot`.
- The `.godot/` directory is generated cache/import data and is **git-ignored** — never edit or commit it.
  It will be recreated by the editor.

## Assets (real sprites vs. placeholders)

Real art exists for these; everything else is a **colorful placeholder** (procedurally-drawn iso tiles
or labeled placeholder cards), to be swapped for real art later without logic changes:
- **Villagers** `assets/craftpix-781111-free-villagers-...` — side-view, **48×48** frames; horizontal
  strips: `*_idle.png` (4f), `*_walk.png` (6f), `*_attack.png` (4f). Flip horizontally for direction.
- **Animals** `assets/craftpix-net-291971-...farm...sprites/PNG/With_shadow/*.png` — top-down,
  multi-directional grids (e.g. Sheep 32×32, Bull 64×64). Row→direction order must be tuned in-editor.
- **Trees** `assets/green_pine_tree_with_grass_at*/.../rotations/unknown.png` — 16 pine variants, 48×48.
- **Background** `assets/bg-sky.jpg` 720×480.
- **No art** for: ground tiles, house, mill, stable, field, river, well, and all UI icons → placeholders.

## Conventions

- Files use UTF-8 and **LF line endings** (`.editorconfig` + `.gitattributes` `eol=lf`); preserve this when
  writing files on Windows.
- Pixel art: keep **Nearest** texture filtering (no smoothing) so sprites stay crisp.
- Asset source files live under `assets/`. Godot generates a `.import` sidecar for each imported asset;
  commit the source and its `.import` file, not the `.godot/imported/` output.
