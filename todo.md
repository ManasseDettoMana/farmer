# TODO — Isometric Idle Farm Builder

Tracking implementation of the plan
(`~/.claude/plans/i-want-to-create-jolly-sifakis.md`). Status: a full first pass is in place and
runs clean (verified headless + screenshot). Remaining work is interactive playtesting and polish.

## Milestone 1 — Foundation (grid + camera) ✅
- [x] Project settings: main scene, 1280×720 window, `canvas_items` stretch, Nearest texture filter
- [x] `autoload/IsoUtils.gd` — TILE_W/H constants, `grid_to_world` / `world_to_grid`
- [x] `autoload/Catalog.gd` — land + structure definitions (id, name, cost, income, visual, spawns)
- [x] `autoload/GameState.gd` — points, points/sec, owned_cells (seed 4×4), structures, signals
- [x] `scenes/world/LandTile.gd` — diamond drawn via `_draw()` (grass top + brown sides)
- [x] `scenes/world/IsoWorld.gd` — GroundLayer + y-sorted EntityLayer, builds the 4×4
- [x] `scenes/Main.tscn/.gd` — background, Camera2D pan + clamp, mounts IsoWorld + HUD
- [x] Verified: 4×4 diamond renders with corners up/down/left/right (screenshot)
- [ ] Manual: confirm pan (left-drag) + zoom (wheel) feel right; camera never rotates

## Milestone 2 — Economy + HUD ✅
- [x] GameState tick: `points += points_per_second * delta`; `recompute_income()`
- [x] Click bonus on owned land (+ floating "+N" label); UI/panels consume their own clicks
- [x] `scenes/ui/HUD.gd` — top points bar (points + points/sec)
- [x] Save/load `user://save.json` (points, owned_cells, structures); autosave + load on start
- [ ] Manual: confirm points rise, clicks add, state persists across relaunch

## Milestone 3 — Market + structure placement ✅
- [x] `scenes/world/Structure.gd` — real sprite OR placeholder card; cell/type/ghost mode
- [x] Market list built into `HUD.gd` (name/cost/income, affordability-gated)
- [x] `scenes/placement/PlacementController.gd` — ghost, snap, green/red tint, ✓/✗ buttons
- [x] Wired dashboard "Build" → market → placement; occupancy + income recompute on confirm
- [ ] Manual: buy field → place → income up; cannot overlap; ✗ cancels with no charge

## Milestone 4 — NPCs ✅
- [x] `util/SpriteSheet.gd` — build SpriteFrames from strips/grids via AtlasTexture
- [x] `scenes/world/Villager.gd` — idle/walk, flip by x, wander owned cells
- [x] `scenes/world/Animal.gd` — directional rows, wander (default row→dir map)
- [x] Spawn starter farmer; house spawns villager, stable spawns animal
- [ ] Manual: confirm NPCs walk + y-sort correctly; **tune Animal `DIR_ROWS`** if facing is wrong

## Milestone 5 — Land expansion ✅
- [x] Reuse PlacementController for a 4×4 land-block ghost (all cells un-owned + adjacent)
- [x] "Expand Land" dashboard action; cost scales with blocks owned (shows "$400" next)
- [ ] Manual: grid grows adjacent; cost scales; new tiles usable/clickable

## Milestone 6 — Move tool + trees + polish
- [x] "Move" tool: tap structure → re-enter ghost flow (no cost) → ✓ commit / ✗ revert
- [x] Plantable real trees (random of 16 variants) via the `tree` catalog entry
- [x] "Fish" action (placeholder reward + floating text)
- [ ] Minimap (top-right) drawing owned cells — **not yet built**
- [ ] Replace emoji dashboard icons with proper labeled icons/art when available

## Notes / follow-ups
- Costs & incomes are placeholder values — balance after a playtest.
- Animal sprite-sheet row→direction order is a sensible default; tweak `Animal.DIR_ROWS` in-editor.
- Real building/icon/ground art can replace placeholders by swapping the `sprite`/`color` fields only.
- River is a placeholder card today; the "Fish" reward is global (not yet tied to standing near a river).
