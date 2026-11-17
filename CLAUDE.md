# CLAUDE.md

Instructions for Claude when working in this project. Claude reads this file at the start of every session.

## Project

- **Desolatum** — a Godot 4.7 game written in GDScript (Mobile renderer).
- Main folders: `autoload/` (singletons), `characters/`, `components/`, `levels/`, `managers/`, `resources/`, `states/`, `systems/`, `ui/`, `utils/`.
- Music and music-style sound effects are generated as LMMS projects by Python scripts in `music/`. Before making or changing any, read `music/MUSIC_STYLE.md`.

## Rules

### Code changes

- **Report every change.** After changing code, list each file you touched and what changed in it, in plain words. Include small changes such as renames, removed code, or moved functions, and scene/resource (.tscn/.tres) edits.
- **Ask before making implementation choices.** When there's more than one reasonable way to do something, stop and describe the options with a short pro/con for each and your recommendation, then wait for my answer. This includes:
  - adding new classes, autoloads, signals, or files
  - changing how existing systems work together, or the structure of a scene
  - removing or renaming things other code or scenes depend on
  - anything that changes how the game plays or feels (numbers, behavior, controls, UI)
  - adding addons or other dependencies
- Small, obvious fixes that follow directly from a card's description (e.g. a null check, a typo) don't need approval first, but still list them in the report.
- If something in a card turns out to be wrong or bigger than described, tell me before continuing.

### Trello tracking

Every feature and bug fix we work on must have a card on the **Desolatum** Trello board: https://trello.com/b/s8t32EAr/desolatum
(board ID `6431f41258e32fe5e5bc865a`). The `Art` list is for art tasks and is not part of this flow.

Lists, in order:

| List | What goes there |
|------|-----------------|
| `Ideas` | Undecided features and suggestions. Anything *you* (Claude) propose goes here, never straight into Todo. |
| `Bugs` | Things that are broken. |
| `Todo` | Features I've committed to building. |
| `Doing` | What we're working on right now. |
| `Testing` | Code is finished and waiting for me to try it in Godot. |
| `Done` | I've confirmed it works in the game. |

Keep cards in sync with the work, without being asked:

- **Before starting** work, find its card. If there is none, create one with a short description: in **Bugs** for a fix, in **Todo** for a feature.
- **When work begins**, move the card from **Todo** or **Bugs** to **Doing**. Only move an **Ideas** card when I say we're doing it.
- **When the code is finished**, move the card to **Testing** and tell me what to check in the game.
- **Only move a card to Done after I confirm** it works in Godot. If I report a problem, move it back to **Doing**.
- **If you notice a bug** while working on something else, create a card in **Bugs** and tell me, instead of silently fixing it.

### Focus: three cards at a time

- **Work on one card at a time.** Every code change must belong to the single card we're currently working on. Say which card that is when you start. Finish it (move it to Testing) before writing code for another card. If you spot something outside the current card, make a card for it instead of fixing it.
- **Doing holds at most 3 cards.** That's our current focus: the one we're working on plus up to two that come next. Don't add a fourth until one of them moves to Testing.
- **Suggest what's next** whenever a slot in Doing opens up, or when I ask. Pick from **Bugs** and **Todo**, and give one line per card saying why it should go next. Prefer, in order:
  1. crashes and bugs that affect gameplay
  2. cards that other cards depend on (e.g. seeding before tests)
  3. small cards that finish off work we just did
  4. a mix of cleanup and new gameplay features, so the game keeps moving forward, not only the code
- **Ask me before moving** the suggested cards into Doing.
- When one card depends on another, note it in the card's description (e.g. "After: Seed the whole run").
- **Every time you create or update a card**, make sure it has all relevant labels. Use the board's existing labels:
  - `Code` (orange): the feature involves writing or changing code/scripts.
  - `Design`: gameplay/system design, balancing, level or UI design decisions.
  - `Art` (blue): sprites, textures, animations, particles or other visual assets.
  - `Priority` (red): only when I say the feature is a priority.
  
  A card can have several labels. If none of these fit, suggest a new label and ask me before creating it.
- Tell me in chat whenever you create or move a card, and which labels you added.
- If Trello can't be reached, say so and keep working, then update the card once it's reachable again.

- Use static typing in all GDScript (`var speed: float = 10.0`).
- Don't edit .tscn files by hand; tell me what to change in the editor instead.
- Don't commit or push unless I ask.
- Keep changes small and explain what you changed.
