# Astral — Web Preview

A browser port of the Astral window, so the UI can be inspected without Roblox,
Studio, an executor, or a play session. Open `web/index.html` directly (works
from `file://`) or serve the folder:

```
python -m http.server 8322 --bind 127.0.0.1 --directory web
```

Then open <http://127.0.0.1:8322/index.html>.

## How it works

The approach follows the same idea as the Obsidian playground in
[`mspaint-cc/docs.mspaint.cc`](https://github.com/mspaint-cc/docs.mspaint.cc/tree/main/src/components/demo/playground),
which renders Roblox library UI on the web:

1. **Describe the UI as data** — `window-spec.js` holds the window, tab sections,
   tabs, sections and elements. It uses the library's own property names
   (`Text`, `Default`, `Min`, `Max`, `Rounding`, `Values`, `Multi`, `Side`, …).
2. **Render that data once** — `astral.js` walks the spec and builds DOM nodes.
   There is no per-widget hand-written markup, so a new element type is added in
   one place.
3. **Style with design tokens** — `astral.css` keeps the library colours and
   metrics as CSS variables. `Library:GetBetterColor` is implemented in the
   runtime, so shades (window background, content panel, footer strip) are
   computed from `BackgroundColor` exactly like `Astral.lua`.
4. **Icons stay authentic** — `icons.js` is generated from Lucide, which is what
   the Roblox library uses. Regenerate it with `python web/build-icons.py`.

Roblox draws a layout tree with offsets; the browser does the same with plain
pixels. Every value below is copied from `Astral.lua`, not estimated:

| Part | Size |
| --- | --- |
| Window | `940 × 620`, corner radius `6` |
| Title bar | `48 px`, divider at `48` |
| Sidebar | `SidebarWidth` (210 in the spec), top `49`, height `-70` |
| Content panel | left `sidebar + 1`, top `49`, height `-70`, `6 px` side padding |
| Footer strip | `20 px`, line at `-20` |
| Tab button | `36 px`, icon `18`, label `26` from the left, padding `4` |
| Section | header `34`, body padding `10`, gap `10`, corner `6` |
| Toggle / checkbox | row `24`, switch `32×18`, checkbox `16×16` |
| Button | `21` |
| Label | `18` (`DoesWrap` grows it) |
| Input | `39` (`14` label + gap + `21` box) |
| Slider | `33`, or `42` with the value-box variant; bar `15` |
| Dropdown | `41` (label `18` + gap `2` + display `21`) |
| Search overlay | `300 × 400`, rows `26` |

## Scaling

This is the part worth keeping honest: the phone view is **not** a separate
layout. `astral.js` computes one uniform scale and applies it with a single
CSS transform, mirroring `Library:CalculateAutoBaseScale` / `SetDPIScale`:

```
margin  = 5% of the viewport per side (min 12 px)
fit     = min((vw - 2·marginX) / 940, (vh - 2·marginY) / 620)
scale   = clamp(fit, 0.25, 1)
```

In automatic mode the rendered window is capped at `fit`, so a phone gets the
desktop window at, for example, 62% instead of a squashed, re-proportioned
window with truncated titles. Dragging **UI Scale** switches to manual
(`AutoDPIScale = false`), and **Return to automatic sizing** restores it — the
same flow as the Display section of `Example.lua`.

The toolbar's readout reports the logical result (`940×620` at `100%`), while
the device frame may be zoomed to fit the browser window. Choose a device with
the toolbar pills or a deep link:

```
index.html#device=932x430
index.html#device=430x932&tab=Settings
```

## What is interactive

- Tabs, sidebar section folding, and section folding.
- Toggles and checkboxes, including the "force checkbox" demo.
- Sliders: drag the bar, or type into the value box (`Editable`).
- Dropdowns: single, multi-select, searchable; panels flip above when near the
  bottom edge.
- Text inputs with the 2 px accent focus ring.
- Key pickers: click the box, then press a key.
- Colour pickers: click a swatch.
- The search box filters every element in every tab; <kbd>↑</kbd>/<kbd>↓</kbd>
  move, <kbd>Enter</kbd> jumps to the element, unfolds its section and flashes
  the highlight ring.
- Custom scrollbars: 4 px accent thumb, 2 px track, auto-hide after 1.6 s.

## Adding something

```js
// window-spec.js
{
    Type: "Slider",
    Text: "Field of view",
    Default: 70, Min: 50, Max: 120, Rounding: 0, Suffix: "°"
}
```

Supported `Type` values: `Toggle`, `Checkbox`, `Slider`, `Dropdown`, `Input`,
`Button`, `Label`, `Divider`, `KeyPicker`, `ColorPicker`.

Add a new widget type by writing one `buildX(record)` function in `astral.js`
and returning a node — it is registered by `Type` in `buildElement`. Elements
opt into search automatically from `Text`.

## Limits

- No Roblox APIs: no notifications, dialogs, context menus, drag/resize,
  animations, or real asset images (`rbxassetid://` would need a Roblox CDN).
- Fonts are a local stack; Roblox uses GothamMedium.
- This is a visual/interaction reference, not a runtime: `Callback` bodies are
  not executed, and the demo buttons only drive the local widgets.
