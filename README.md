# µKanban

A minimalist kanban plugin for Godot, loosely inspired by [Nullboard](https://github.com/apankrat/nullboard).

---

## Features

- Lives in its own editor tab alongside 2D, 3D, and Script
- Multiple columns with left/right reordering
- Multi-line cards with keyboard-driven editing
- Drag cards between columns and reorder within them
- Board state saved automatically to `res://.kanban` in your project

---

## Installation

### Via Asset Library _(recommended)_
1. In the Godot editor, open **AssetLib**
2. Search for **µKanban**
3. Click **Download** and then **Install**
4. Enable the plugin under **Project > Project Settings > Plugins**

### Manual
1. Download or clone this repository
2. Copy the `addons/ukanban/` folder into your project's `addons/` folder
3. Enable the plugin under **Project > Project Settings > Plugins**

---

## Usage

Once enabled, the **µKanban** tab appears in the top editor bar. Your board is saved automatically, no manual save needed.

The `.kanban` file can be committed alongside your project, keeping your board in sync with your codebase and shared with your team through version control.

### Cards

| Key | Action |
|---|---|
| `Click` | Enter edit mode |
| `Escape` | Cancel (removes card if new) |
| `Shift+Enter` | Confirm edit |
| `Ctrl+Enter` | Add card below |
| `Shift+Ctrl+Enter` | Add card above |
| `Tab` | Focus next card |
| `Shift+Tab` | Focus previous card |
| `Hold + Drag` | Reorder card |
| `Alt+Click` | Start drag immediately |

### Columns

| Key | Action |
|---|---|
| `Click header` | Rename column |
| `Escape` | Cancel (removes column if new) |
| `Enter` | Confirm rename |

### Menu

Hover over any card or column header to reveal the action menu.

| Button | Action |
|---|---|
| `+` | Add card to column |
| `×` | Delete card or column |
| `‹ / ›` | Move column left or right |

> Delete is disabled when only one column remains.

---

## License

MIT — see [LICENSE](LICENSE).
