# Studio Preview

The live UI is mirrored into a Roblox Studio place so changes can be seen in the
viewport without ever starting a play session (no client, no server).

## What is in the place

`ReplicatedStorage/AstralPreview`

| Instance | Purpose |
| --- | --- |
| `Astral/Parts/Part_01..04` | The full `Astral.lua` source, split into string modules. |
| `Astral/LucideSource` | `LucideIcons.lua` returned as a string (the library expects source text, not a table). |
| `Addons/SaveManager` | `addons/SaveManager.lua` (real module source). |
| `Addons/ThemeManager` | `addons/ThemeManager.lua` (real module source). |
| `ExampleSource` | `Example.lua` with the three `game:HttpGet` imports replaced by injected arguments. |
| `Runner` | Loads everything, stubs executor-only APIs, runs the example. |

Run the preview from the Studio command bar (or via the MCP):

```lua
local report = require(game.ReplicatedStorage.AstralPreview.Runner)()
```

The window is parented to `CoreGui` (the same place the library uses in an
executor), so it renders over the viewport in **Edit** mode and can be clicked
and dragged with the normal tools.

## Why the source is chunked

Roblox rejects `Script.Source` strings of 200,000 characters or more, and
`Astral.lua` is ~580 KB. The file is split into byte-aligned chunks, each stored
as `return [====[ ... ]====]`, and the `Runner` concatenates them before
`loadstring`. Keep the split away from multi-byte UTF-8 boundaries.

## Preview limitations

- `HttpService` is disabled in the experience, so PNG assets (header logo,
  check marks) cannot be downloaded. Lucide icons work because `Runner` serves
  the local `LucideIcons.lua` through a stubbed `http_request`.
- `readfile` / `writefile` are stubbed, so config saving and autoload are no-ops.
- Everything else -- layout, themes, search overlay, highlighting, pooling --
  is the real library code.

## Refreshing after an edit

1. Edit `Astral.lua` (and `Example.lua` / addons if needed) in the repo.
2. Re-split and re-push the parts, then run the `Runner` again.

`Runner` itself only needs re-creating if its harness code changes; it always
re-reads the parts, addons and example source at call time.
