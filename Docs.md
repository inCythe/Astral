# Astral UI Library — Full API Reference

## Table of Contents

**Getting Started**
1. [Setup & Loading](#1-setup--loading)
   - [Example Script](#example-script)
2. [Library Object](#2-library-object)
3. [Creating a Window](#3-creating-a-window)
4. [Window API](#4-window-api)
   - [Toggle Bubble](#toggle-bubble)

**Structure**
5. [Tabs & Tab Sections](#5-tabs--tab-sections)
6. [Sections & Section Groups](#6-sections--section-groups)
   - [AddSection](#61-addsection)
   - [Layout & Alternation](#62-layout--alternation)
   - [AddSectionGroup](#63-addsectiongroup-tabbed-section-box)
   - [AddSubSection](#64-addsubsection-nested-sections)
7. [Conditional Groups & Sections](#7-conditional-groups--sections)

**Elements**
8. [Elements](#8-elements)
   - [Divider](#81-divider)
   - [Label](#82-label)
   - [Button](#83-button)
   - [Toggle / Checkbox](#84-toggle--checkbox)
   - [Input](#85-input)
   - [Slider](#86-slider)
   - [ProgressBar](#87-progressbar)
   - [Dropdown](#88-dropdown)
   - [Viewport](#89-viewport)
   - [Image](#810-image)
   - [Video](#811-video)
   - [UIPassthrough](#812-uipassthrough)
9. [Addons (on Labels & Toggles)](#9-addons-on-labels--toggles)
   - [KeyPicker](#91-keypicker)
   - [ColorPicker](#92-colorpicker)

**Surfaces**
10. [Notifications](#10-notifications)
11. [Key Tab](#11-key-tab)
12. [Draggable Overlays](#12-draggable-overlays)
    - [Draggable Label](#121-draggable-label)
    - [Draggable Button](#122-draggable-button)
    - [Draggable Toggle](#123-draggable-toggle)
    - [Draggable Progress](#124-draggable-progress)
    - [Draggable Menu](#125-draggable-menu)
    - [Overlay Manager](#126-overlay-manager)
13. [Dialogs](#13-dialogs)
14. [Loading Screens](#14-loading-screens)

**Theming & State**
15. [Theme / Scheme](#15-theme--scheme)
16. [Global Registries](#16-global-registries)
17. [Unloading](#17-unloading)

**Addon Modules**
18. [SaveManager](#18-savemanager)
19. [ThemeManager](#19-thememanager)

**Advanced**
20. [Advanced Utilities](#20-advanced-utilities)
    - [Tooltips](#201-tooltips)
    - [Context Menus](#202-context-menus)
21. [Icon Reference](#21-icon-reference)

---

## 1. Setup & Loading

The library is loaded via `loadstring` or by requiring the module directly:

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/inCythe/Astral/refs/heads/main/Astral.lua"))()
```

Once loaded, `Library` is also stored in `getgenv().Library` for global access. On re-execution, any existing Astral ScreenGui is automatically destroyed or cleanly unloaded before the new instance is created.

**Important:** Elements are stored in the Library object, not as global variables:
- `Library.Toggles` - All toggle/checkbox elements
- `Library.Buttons` - All button elements
- `Library.Options` - All input, slider, dropdown, and other option elements
- `Library.Labels` - All label elements

For example, to access a toggle:
```lua
Library.Toggles.MyToggle:SetState(true)
```

### Example Script

A comprehensive example demonstrating all UI features, rich text formatting, and advanced functionality is available at `Example.lua` in the repository:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/inCythe/Astral/refs/heads/main/Example.lua"))()
```

The example includes:
- All element types with various configurations
- Rich text formatting throughout the UI
- Addons (SaveManager, ThemeManager) integration
- Advanced features: conditional groups, keybinds, color pickers
- Dialogs, notifications, loading screens
- New dropdown methods: `SetSelectedValue`, `DeselectValue`, `ClearSelectedValues`
- Auto-deselect behavior when values are removed from dropdowns

---

## 2. Library Object

The root `Library` table contains global state and utility methods.

### Key Properties

| Property | Type | Default | Description |
|---|---|---|---|
| `Library.Toggled` | boolean | false | Whether the main window is visible |
| `Library.ToggleKeybind` | KeyCode | `RightControl` | Keybind to show/hide the window |
| `Library.NotifySide` | string | `"Right"` | Side for notifications (`"Left"` or `"Right"`) |
| `Library.ShowCustomCursor` | boolean | false | Show the library's crosshair custom cursor |
| `Library.ForceCheckbox` | boolean | false | Read-only reflection of the last value passed to `Library:SetForceCheckbox`. Do not assign this directly -- it will not update existing toggles. Use `Library:SetForceCheckbox(true/false)` instead, which also flips every already-created `AddToggle` toggle live (toggles made with `AddCheckbox` directly are unaffected either way). |
| `Library.IsMobile` | boolean | auto | Whether the local device is mobile |
| `Library.NotifyOnError` | boolean | false | Show a notification when a callback errors |
| `Library.DPIScale` | number | 1 | Current global scale factor set via `Library:SetDPIScale` (percentage / 100 -- separate from the per-window `DPIScale` option, see below) |
| `Library.AutoDPIScale` | boolean | true | Whether the UI scale is currently being computed automatically from screen size. Starts `true` unless a window was created with an explicit `DPIScale` option, and is set to `false` the moment anything calls `Library:SetDPIScale` directly (e.g. a manual UI Scale slider) so that choice sticks rather than getting overwritten on the next resize. Set it back to `true` (and call `Library:SetDPIScale(Library:CalculateAutoDPIScale())` once) to return to automatic sizing. |
| `Library.ShowToggleFrameInKeybinds` | boolean | true | Show the toggle checkbox in the keybind list |
| `Library.HighlightSearchResults` | boolean | true | Wrap the matching substring of search results in a colored highlight |
| `Library.WaitForIconsOnLoad` | boolean | true | Wait for icons to load before creating windows/loading screens |
| `Library.Scheme` | table | — | The active color scheme (see [Theme](#15-theme--scheme)) |
| `Library.Toggles` | table | — | All registered toggles, keyed by their `Idx` |
| `Library.Options` | table | — | All registered options (inputs, sliders, dropdowns, etc.) keyed by `Idx` |
| `Library.Labels` | table | — | All registered labels |
| `Library.Buttons` | table | — | All registered buttons |
| `Library.ImageManager` | table | — | Custom asset/image management system |
| `Library.KeybindFrame` | Frame | — | Floating keybinds panel (draggable menu) |
| `Library.KeybindContainer` | Frame | — | Container for keybind entries |
| `Library.KeybindToggles` | table | — | All keybind toggle entries in the panel |

### Utility Methods

```lua
-- Set global DPI scaling (100 = default). Affects tooltips, notifications,
-- dialogs, and other elements tracked in Library.Scales.
-- Note: the per-window DPIScale option (see CreateWindow below) does the
-- same job using a 1-10 range and is applied automatically when the window
-- is created -- you generally won't need to call this directly unless you
-- want to change scaling again afterwards.
Library:SetDPIScale(DPIScale: number)

-- Compute the DPIScale value (1-10, same units as SetDPIScale) that best
-- fits the current screen/viewport size, using the short side of
-- workspace.CurrentCamera.ViewportSize as the primary signal (with a small
-- correction for very wide/tall aspect ratios like split screen or a
-- sideways tablet). This is what CreateWindow uses automatically when no
-- explicit DPIScale option is passed, and what the live auto-resize
-- listener re-calls on every viewport change while Library.AutoDPIScale
-- is true.
--
-- Optionally pass a Rounding digit count (matching a slider's own
-- Rounding option) to get a value pre-rounded for display -- e.g. if you
-- show this in a slider with Rounding = 1, call
-- Library:CalculateAutoDPIScale(1) for its Default so the initial display
-- matches what dragging the slider would produce. Leave it out (as the
-- internal callers above do) to get the full-precision float, which keeps
-- the actual applied UIScale smooth instead of stepped.
local DPIValue = Library:CalculateAutoDPIScale()
local RoundedForSlider = Library:CalculateAutoDPIScale(1) -- e.g. 3.7
```

**Automatic mobile/screen-size scaling:** unless a window is created with an explicit `DPIScale` option, Astral now computes an appropriate scale from the actual screen size on load via `Library:CalculateAutoDPIScale()`, and keeps recalculating it live whenever `workspace.CurrentCamera.ViewportSize` changes (window resize, device rotation, split screen, a new camera being set) -- so a small phone screen gets a genuinely smaller `UIScale`, rather than the window frame just being pixel-clamped into a cramped box while its contents stay at 100%. This live behavior only runs while `Library.AutoDPIScale` is `true`; the moment `Library:SetDPIScale` is called directly (e.g. from a manual "UI Scale" slider, or because a saved config restores one), `Library.AutoDPIScale` flips to `false` so the manual/saved value isn't fought on the next resize. See the Display section in `Example.lua` for a slider + "Reset to Automatic Scaling" button pairing that demonstrates this handoff.

-- Fire a safe pcall-wrapped callback (errors are caught and optionally notified)
Library:SafeCallback(Func, ...args)

-- Get text pixel bounds
local X, Y = Library:GetTextBounds(Text, Font, Size, Width?)

-- Check if mouse position is inside a frame
local result = Library:MouseIsOverFrame(Frame: GuiObject, Mouse: Vector2): boolean

-- Color helpers
Library:GetLighterColor(Color: Color3): Color3
Library:GetDarkerColor(Color: Color3): Color3
Library:GetBetterColor(Color: Color3, Amount: number): Color3

-- Get a key name string from a KeyCode
Library:GetKeyString(KeyCode: Enum.KeyCode): string

-- Register an RBXScriptConnection to be auto-disconnected on Unload
Library:GiveSignal(Connection: RBXScriptConnection)

-- Register a callback to be called on Unload
Library:OnUnload(Callback: () -> ())

-- Update all themed colors using the registry
Library:UpdateColorsUsingRegistry()

-- Update all conditional groups
Library:UpdateConditionalGroups()

-- Add/remove instances from the color registry (for theme syncing)
Library:AddToRegistry(Instance, Properties: { [string]: string | () -> any })
Library:RemoveFromRegistry(Instance)

-- Get an icon from the Lucide icon set by name
Library:GetIcon(IconName: string): Icon?

-- Get a custom icon supporting named built-in/custom assets (e.g. "AstralIcon"), asset IDs, rbxassetid URLs, and Lucide names
Library:GetCustomIcon(IconName: string): Icon?

-- Set an external Lucide icon module
Library:SetIconModule(module: IconModule)

-- Wait for icons to finish loading (with optional timeout in seconds, default 10)
Library:WaitForIcons(Timeout: number?): boolean

-- Check if icons are loaded without waiting
Library:AreIconsLoaded(): boolean

-- Re-apply icons to any instances that were waiting on icons still loading
-- (rarely needed manually -- called automatically once icons finish loading)
Library:RefreshIcons()

-- Change/reset the custom cursor icon
Library:ChangeCursorIcon(ImageId: string)
Library:ResetCursorIcon()
Library:ChangeCursorIconSize(Size: UDim2)

-- Set the global font
Library:SetFont(FontFace: Font | Enum.Font)

-- Set notification side
Library:SetNotifySide(Side: "Left" | "Right")

-- Toggle whether matching text in search results is highlighted (re-renders the active search immediately)
Library:SetHighlightSearchResults(Enabled: boolean)

-- Force all toggles created via AddToggle to render as checkboxes instead
-- of pill switches, and live-update every AddToggle toggle already on
-- screen to match. (Toggles created directly via AddCheckbox always stay
-- checkboxes regardless of this.) Setting Library.ForceCheckbox = true
-- directly does NOT do this -- it only affects toggles created afterward.
Library:SetForceCheckbox(Enabled: boolean)

-- Validate a table against a template (fills in missing keys)
Library:Validate(Table: table, Template: table): table
```

> **Note on `GetCustomIcon`:** it resolves, in order: (1) a *named* asset registered in the CustomImageManager — this covers the built-ins (`"AstralIcon"`, `"DiscordIcon"`, `"LoadingIcon"`, `"CheckIcon"`, `"TransparencyTexture"`, `"SaturationMap"`) plus anything added via `CustomImageManager.AddAsset`; (2) a raw `rbxasset://` / `rbxthumb://` / asset-URL string; (3) a Lucide icon name via `GetIcon`. Always pass the **name** (e.g. `"AstralIcon"`) — passing an already-resolved URL will also work (it matches step 2), but the name is what you should use in your own code.

> **Icon Loading:** The library automatically loads Lucide icons from the remote source on startup and caches them locally in `Astral/cache/LucideIcons.lua`. This significantly speeds up subsequent loads and prevents network-related icon loading failures. By default, `Library:CreateWindow()` and `Library:CreateLoading()` will wait up to 10 seconds for icons to load before proceeding to ensure all icons are available. You can disable this behavior by setting `Library.WaitForIconsOnLoad = false` before creating windows/loading screens, or manually wait with `Library:WaitForIcons()`.

---

## 3. Creating a Window

```lua
local Window = Library:CreateWindow({
    Title        = "My Script",            -- Window title (string)
    Footer       = "v1.0.0",              -- Footer text shown at the bottom
    Icon         = nil,                   -- Lucide icon name, rbxassetid, or asset URL (gracefully handles invalid icons)
    IconSize     = UDim2.fromOffset(30, 30),
    Size         = UDim2.fromOffset(720, 600),
    Position     = UDim2.fromOffset(6, 6),
    Center       = true,                  -- Center window on screen
    AutoShow     = true,                  -- Show window immediately on create
    Resizable    = true,                  -- Allow window to be resized by dragging the corner
    CornerRadius = 6,                     -- Corner radius (0–20)
    Font         = Enum.Font.GothamMedium,
    TitleSize    = 20,                    -- Title font size (number, default: 20)

    -- DPI / UI scale, 1-10 (5 = 100% / normal size). Applied to the window
    -- itself plus every other scaled UI surface (notifications, tooltips,
    -- dialogs, keybinds panel, draggable menus, the mobile bubble) so
    -- scaling is consistent across the whole UI, not just the window.
    --
    -- Leave this out (or pass nil) and Astral picks a scale automatically
    -- based on the player's actual screen/viewport size instead -- smaller
    -- on a small phone, full size on desktop -- and keeps it updated live
    -- as the viewport changes (rotation, resize, split screen). Passing an
    -- explicit number here (like the 5 below) opts out of that and locks
    -- the window to a fixed scale, exactly like before.
    DPIScale     = 5,

    -- Toggle behavior
    ToggleKeybind = Enum.KeyCode.RightControl,

    -- Searchbar
    SearchbarSize = UDim2.fromScale(1, 1),
    DisableSearch = false,                -- Hide the searchbar entirely
    HighlightSearchResults = true,        -- Wrap matching text in a colored <font> highlight while searching

    -- Notifications
    NotifySide = "Right",                 -- "Left" or "Right"

    -- Cursor
    ShowCustomCursor = false,

    -- Background image (optional)
    BackgroundImage = nil,                -- Roblox asset ID string

    -- Sidebar compacting
    SidebarCompacted = false,             -- Start with sidebar collapsed to icons
    CompactSidebarTooltips = true,        -- Show tab name tooltips when sidebar is compacted

    -- Sidebar sizing / resize
    SidebarWidth = nil,                   -- Initial sidebar width in pixels. nil = auto (22% of window width)
    EnableSidebarResize = true,           -- Let the user drag the divider to resize the sidebar (default: on)

    -- Floating draggable toggle bubble (chat-head style, magnets to screen edges)
    Bubble = nil,                          -- nil = auto (shown only on mobile). true/false forces it on any platform.
    BubbleSide = "Right",                  -- Starting side, and the side it magnets back to. "Left" or "Right".
    BubbleIcon = "menu",                   -- Lucide icon name or custom asset id. nil falls back to the window title's first letter.
    BubbleIconColor = nil,                 -- Color3. nil uses Scheme.AccentColor.
    BubbleColor = nil,                     -- Color3. nil uses Scheme.MainColor.
    BubbleSize = UDim2.fromOffset(50, 50),
    BubbleCornerRadius = 25,               -- Half of BubbleSize for a full circle; lower for rounded-square bubbles.
    BubblePadding = 12,                    -- Inset between the bubble edge and its icon/letter.

    -- Mobile
    -- (mobile support -- IsMobile detection, touch-friendly sizing, the Bubble
    -- toggle above -- is automatic; there is no separate mobile-buttons option)

    -- Mouse unlock
    UnlockMouseWhileOpen = true,

    -- Discord button (shown at the bottom of the sidebar, set DiscordLink to enable it)
    DiscordLink = nil,                    -- e.g. "https://discord.gg/yourinvite"
    DiscordAction = "open",               -- "open" (tries Discord RPC, falls back to clipboard) or "clipboard"

    -- Instance management
    SingleInstance = true,                -- Destroy any existing window with same Title on create

    -- Icon Loading
    WaitForIconsOnLoad = nil,              -- Override global Library.WaitForIconsOnLoad for this window (nil = use global setting)
})
```

All fields are optional and fall back to sensible defaults. The window starts hidden; toggle it with the `ToggleKeybind` (default `RightControl`).

The window has **Minimize** (`−`) and **Close** (`×`) buttons in the top-right. Minimize hides the window. Close hides and then calls `Library:Unload()`.

---

## 4. Window API

Methods on the `Window` object returned from `Library:CreateWindow`.

```lua
Window:ChangeTitle(title: string)
Window:SetTitleSize(size: number)           -- Set title font size (default: 20)
Window:SetFooter(footer: string)
Window:SetCornerRadius(Radius: number)      -- 0–20

-- Sidebar width control
Window:GetSidebarWidth(): number
Window:SetSidebarWidth(Width: number)
Window:IsSidebarCompacted(): boolean
Window:SetCompact(State: boolean)

-- Tab info bar (shown next to searchbar when a tab with a Description is active)
Window:ShowTabInfo(Name: string, Description: string)
Window:HideTabInfo()

-- Background image (only available if BackgroundImage was set at creation)
Window:SetBackgroundImage(Image: string)
```

### Toggle Bubble

A floating, draggable "chat-head" style button that shows/hides the window and magnets to the nearest screen edge when dragged. By default it only appears on mobile (`Bubble = nil`), but it can be forced on or off for any platform:

```lua
local Window = Library:CreateWindow({
    -- ...
    Bubble           = true,                     -- force it on (nil = auto/mobile-only, false = never)
    BubbleSide       = "Right",                   -- "Left" or "Right" -- starting side and the side it snaps back to
    BubbleIcon       = "menu",                    -- Lucide icon name / asset id; nil falls back to the window title's first letter
    BubbleIconColor  = nil,                       -- Color3, defaults to Scheme.AccentColor
    BubbleColor      = nil,                       -- Color3, defaults to Scheme.MainColor
    BubbleSize       = UDim2.fromOffset(50, 50),
    BubbleCornerRadius = 25,                      -- half of BubbleSize for a circle
    BubblePadding    = 12,
})
```

Tapping the bubble toggles the window; dragging it releases and animates a snap to whichever edge (left/right) it's closest to. There's no separate return value/handle for the bubble — it's fully configured through the `CreateWindow` options above.

---

## 5. Tabs & Tab Sections

### Adding a Tab

```lua
local Tab = Window:AddTab({
    Name        = "Main",         -- Tab name shown in sidebar
    Icon        = "home",         -- Optional Lucide icon name, asset ID, or URL
    Description = "Main tab",     -- Optional description shown in the top info bar
})

-- Shorthand (name only, no icon):
local Tab = Window:AddTab("Main")

-- With icon:
local Tab = Window:AddTab("Main", "home")
```

Tabs appear in the left sidebar. The first added tab is shown automatically. Only one tab is active at a time.

### Tab Methods

```lua
Tab:Show()                        -- Switch to this tab
Tab:Hide()                        -- Deactivate this tab
Tab:SetVisible(Visible: boolean)  -- Show/hide the tab button in the sidebar
```

### Collapsible Tab Sections

Tab sections group tab buttons in the sidebar under a collapsible header.

```lua
local Section = Window:AddTabSection({
    Name = "Combat",              -- Section header text
    Icon = "swords",              -- Optional icon
    Open = true,                  -- Start expanded (default: true)
})

local Tab = Section:AddTab({
    Name = "Aimbot",
    Icon = "crosshair",
})
```

Clicking the section header toggles the group open/closed. When the sidebar is compact, the header label is hidden and the chevron is centered.

> The special **Key Tab** variant is covered separately in [§11](#11-key-tab).

---

## 6. Sections & Section Groups

A **tab** is filled with **sections** — boxed panels that hold elements. Sections can span the full width of the tab, or sit side-by-side in a two-column layout, and you can freely alternate between the two down the page.

### 6.1 AddSection

Adds a boxed section panel to a tab.

```lua
local Section = Tab:AddSection({
    Name     = "Settings",   -- Section header text
    Side     = 1,            -- 1 = left column, 2 = right column, omitted/nil = full-width (one column)
    IconName = "settings",   -- Optional icon shown next to the header
})

-- Convenience wrappers:
local LeftSection  = Tab:AddLeftSection("Settings")
local RightSection = Tab:AddRightSection("Settings", "settings")  -- icon optional
```

- Omitting `Side` (or passing anything other than `1`/`2`) creates a **full-width** section.
- `Side = 1` places the section in the **left column**, `Side = 2` in the **right column** of a two-column row.

### 6.2 Layout & Alternation

Sections render in **exactly the order you call `AddSection`/`AddLeftSection`/`AddRightSection`/`AddSectionGroup`**, top to bottom. Full-width and two-column sections can be freely interleaved:

```lua
Tab:AddSection("Overview")               -- full-width, row 1

Tab:AddLeftSection("Combat")             -- \
Tab:AddRightSection("Visuals")           -- / two-column row, row 2

Tab:AddSection("Misc")                   -- full-width, row 3

Tab:AddLeftSection("Player")             -- \
Tab:AddRightSection("World")             -- / two-column row, row 4
```

This produces exactly what it reads as: **section → two-column → section → two-column**, in call order, with no manual row/index bookkeeping required. Every consecutive pair of `Side = 1` / `Side = 2` calls shares one row; a call with no `Side` (or a switch back to full-width) always starts a fresh row.

Within a two-column row, left sections (`Side = 1`) stack top-to-bottom in the left column, and right sections (`Side = 2`) stack top-to-bottom in the right column, independent of each other.

The global searchbar/overlay (see [Window API](#4-window-api)) lists matching sections and elements in this same visual order, so results always read top-to-bottom, left-to-right just like the tab itself.

### 6.3 AddSectionGroup (Section Group)

A section box with multiple sub-tabs at the top, sharing the same panel area. It participates in the same layout ordering and `Side` rules as `AddSection` above.

```lua
local Group = Tab:AddSectionGroup({
    Name = "MyGroup",   -- Optional key for Tab.SectionGroups lookup
    Side = 1,           -- 1 = left, 2 = right
})

-- Shorthand:
local Group = Tab:AddLeftSectionGroup("MyGroup")
local Group = Tab:AddRightSectionGroup("MyGroup")

-- Add pages to the group
local Page = Group:AddTab("Page One", "icon-name")
local Page2 = Group:AddTab("Page Two")

-- Page is a section-like object supporting all element methods
Page:AddToggle("myToggle", { Text = "Enable", Default = false })
```

The first page added is shown by default. Clicking a tab button at the top of the box switches the active page.

### 6.4 AddSubSection (Nested Sections)

Creates a nested section inside an existing section, allowing for hierarchical organization of elements. Subsections support the same alternation between full-width and two-column layouts as regular sections.

```lua
local SubSection = Section:AddSubSection({
    Name = "Advanced Settings",   -- Sub-section header text
    IconName = "settings",         -- Optional icon shown next to the header
    DefaultOpen = true,           -- Start expanded (default: true)
    Side = nil,                   -- Optional: nil for full-width, 1 for left column, 2 for right column
})

-- Shorthand:
local SubSection = Section:AddSubSection("Advanced Settings", "settings")

-- Add elements to the sub-section just like a regular section
SubSection:AddToggle("myToggle", { Text = "Enable Feature", Default = false })
SubSection:AddSlider("mySlider", { Text = "Value", Min = 0, Max = 100, Default = 50 })

-- Two-column subsections
Section:AddSubSection({ Name = "Left Column", Side = 1 })
Section:AddSubSection({ Name = "Right Column", Side = 2 })

-- Full-width subsection (alternation works)
Section:AddSubSection("Full Width Settings")
```

Sub-sections use a slightly smaller header and a subtly different background to indicate nesting. They support all the same element methods as regular sections. Clicking the header toggles the sub-section open/closed, and the parent section automatically resizes to accommodate.

**Layout Alternation:** Subsections automatically alternate between full-width and two-column layouts when you use the `Side` parameter, just like regular sections:
- Full-width subsection → Two-column subsections → Full-width subsection → Two-column subsections

---

## 7. Conditional Groups & Sections

Show/hide a group of elements or an entire section based on the state of other elements.

### ConditionalGroup

Inline group inside an existing section. Shown/hidden without affecting the section box.

```lua
local Group = Section:AddConditionalGroup()

-- Add elements to the group just like a section:
Group:AddToggle("innerToggle", { Text = "Sub Option" })
Group:AddSlider("innerSlider", { Text = "Value", Min = 0, Max = 10 })

-- Set which elements control visibility:
Group:SetupDependencies({
    { Toggles["myToggle"], true },          -- visible when myToggle = true
    { Options["myDropdown"], "Option A" },  -- AND dropdown = "Option A"
})
```

### ConditionalSection

A separate styled section box that appears/disappears, anchored to the parent section's column.

```lua
local CondSection = Section:AddConditionalSection()

CondSection:AddLabel("Only visible when condition is met")

CondSection:SetupDependencies({
    { Toggles["someToggle"], true },
})
```

### Dependency format

Each dependency entry is `{ Element, ExpectedValue }`:
- For `Toggle` elements: `ExpectedValue` is a `boolean`
- For `Dropdown` elements (single): `ExpectedValue` is the selected value
- For `Dropdown` elements (multi): `ExpectedValue` is a value that must be present in the selection

All listed dependencies must be satisfied simultaneously for the group/section to become visible.

---

## 8. Elements

All elements are added to a `Section` (or SectionGroup page). Every element that stores a value takes an `Idx` string as its first argument — this key is used to register the element in `Library.Options` or `Library.Toggles`.

### 8.1 Divider

A horizontal rule optionally labelled, used to visually separate groups of elements.

```lua
Section:AddDivider()

-- With a text label
Section:AddDivider("Section Label")

-- With a table (full control)
Section:AddDivider({
    Text         = "Label",   -- string or nil
    Margin       = 0,         -- top and bottom margin (px)
    MarginTop    = 0,
    MarginBottom = 0,
})
```

Returns a `Divider` object:

```lua
Divider.Holder    -- the root Frame
Divider.Text      -- string or nil
```

---

### 8.2 Label

A text label. Supports addons (KeyPicker, ColorPicker) on non-wrapping labels.

```lua
local Label = Section:AddLabel("My Label")

-- With options:
local Label = Section:AddLabel({
    Text      = "My Label",
    DoesWrap  = false,        -- Enable text wrapping (disables addons)
    Size      = 14,           -- Font size
    Visible   = true,
})

-- With an Idx for registry:
local Label = Section:AddLabel("myLabel", { Text = "Hello" })
```

**Methods:**

```lua
Label:SetText(Text: string)
Label:SetVisible(Visible: boolean)

-- Addon methods (non-wrapping labels only):
Label:AddKeyPicker(Idx, Info)
Label:AddColorPicker(Idx, Info)
```

Registered labels are stored in `Library.Labels`.

---

### 8.3 Button

A clickable button. Supports an optional secondary sub-button next to it.

```lua
local Button = Section:AddButton({
    Text         = "Do Thing",
    Func         = function() end,  -- Called on click
    DoubleClick  = false,           -- Require a second click within 0.5s to confirm
    Risky        = false,           -- Colors text red as a visual warning
    Disabled     = false,
    Visible      = true,
    Tooltip      = nil,             -- string shown on hover
    DisabledTooltip = nil,
    Idx          = nil,             -- optional key for Library.Buttons
})

-- Shorthand:
Section:AddButton("Label", function() end)
```

**Methods:**

```lua
Button:SetText(Text: string)
Button:SetDisabled(Disabled: boolean)
Button:SetVisible(Visible: boolean)
```

**Sub-button:** Call `:AddButton(...)` on a button object to attach a second button displayed inline to its right.

```lua
local Sub = Button:AddButton({
    Text = "Sub",
    Func = function() end,
})
```

Buttons are stored in `Library.Buttons` when an `Idx` is provided.

---

### 8.4 Toggle / Checkbox

A boolean toggle rendered as a pill switch or as a checkbox (if `Library:SetForceCheckbox(true)` was called, or `AddCheckbox` is called directly).

```lua
local Toggle = Section:AddToggle("myToggle", {
    Text     = "Enable Feature",
    Default  = false,
    Callback = function(Value) end,
    Changed  = function(Value) end,  -- alias for Callback
    Risky    = false,                -- Red label text
    Disabled = false,
    Visible  = true,
    Tooltip  = nil,
    DisabledTooltip = nil,
})

-- Force checkbox style:
local Toggle = Section:AddCheckbox("myToggle", { ... })
```

**Methods:**

```lua
Toggle:SetValue(Value: boolean)
Toggle:SetText(Text: string)
Toggle:SetDisabled(Disabled: boolean)
Toggle:SetVisible(Visible: boolean)
Toggle:OnChanged(Func: (Value: boolean) -> ())
```

**Addon methods:**

```lua
Toggle:AddKeyPicker(Idx, Info)
Toggle:AddColorPicker(Idx, Info)
```

Registered in `Library.Toggles[Idx]`.

---

### 8.5 Input

A text input field with an optional label above it.

```lua
local Input = Section:AddInput("myInput", {
    Text             = "Player Name",    -- Label above the box
    Default          = "",
    Placeholder      = "",
    Finished         = false,            -- Fire callback only on Enter (true) vs every keystroke (false)
    Numeric          = false,            -- Only allow numeric input
    ClearTextOnFocus = true,
    ClearTextOnBlur  = false,
    AllowEmpty       = true,             -- If false, resets to EmptyReset on empty submit
    EmptyReset       = "---",           -- Value used when AllowEmpty is false and input is blank
    Callback         = function(Value) end,
    Changed          = function(Value) end,
    VerifyValue      = nil,              -- function(Value) -> boolean, return false to reject
    Disabled         = false,
    Visible          = true,
    Tooltip          = nil,
    DisabledTooltip  = nil,
})
```

> If `VerifyValue` is provided, `Finished` is forced to `true` automatically.

**Methods:**

```lua
Input:SetValue(Text: string)
Input:SetText(Text: string)        -- Changes the label (not the box content)
Input:SetDisabled(Disabled: boolean)
Input:SetVisible(Visible: boolean)
Input:OnChanged(Func: (Value: string) -> ())
```

Registered in `Library.Options[Idx]`.

---

### 8.6 Slider

A horizontal drag slider with an optional editable value field.

```lua
local Slider = Section:AddSlider("mySlider", {
    Text     = "Speed",
    Default  = 50,
    Min      = 0,
    Max      = 100,
    Rounding = 0,          -- Decimal places (0 = integer)
    Prefix   = "",
    Suffix   = "",
    Compact  = false,      -- Inline label + bar in a single row (no separate label row)
    HideMax  = false,      -- Show only current value, not "value/max"
    Editable = false,      -- Show an edit control to type a value directly
    EditableStyle = "Pencil",  -- "Pencil" (icon button reveals overlay box) or "ValueBox" (always-visible box)
    Callback = function(Value) end,
    Changed  = function(Value) end,
    Disabled = false,
    Visible  = true,
    Tooltip  = nil,
    DisabledTooltip = nil,
    FormatDisplayValue = nil,  -- function(Slider, Value) -> string, custom display text
})
```

**Methods:**

```lua
Slider:SetValue(Value: number)
Slider:SetMin(Value: number)
Slider:SetMax(Value: number)
Slider:SetText(Text: string)
Slider:SetPrefix(Prefix: string)
Slider:SetSuffix(Suffix: string)
Slider:SetDisabled(Disabled: boolean)
Slider:SetVisible(Visible: boolean)
Slider:OnChanged(Func: (Value: number) -> ())
```

Registered in `Library.Options[Idx]`.

---

### 8.7 ProgressBar

A read-only progress bar that displays a value visually as a filled bar. Unlike sliders, progress bars cannot be dragged or edited by the user — the value can only be changed programmatically via `:SetValue()`.

```lua
local ProgressBar = Section:AddProgressBar("myProgressBar", {
    Text     = "Loading",
    Value    = 50,
    Min      = 0,
    Max      = 100,
    Rounding = 0,          -- Decimal places (0 = integer)
    Prefix   = "",
    Suffix   = "%",
    Compact  = false,      -- Inline label + bar in a single row (no separate label row)
    HideMax  = false,      -- Show only current value, not "value/max"
    Callback = function(Value) end,
    Changed  = function(Value) end,
    Disabled = false,
    Visible  = true,
})
```

**Methods:**

```lua
ProgressBar:SetValue(Value: number)
ProgressBar:SetMin(Value: number)
ProgressBar:SetMax(Value: number)
ProgressBar:SetText(Text: string)
ProgressBar:SetPrefix(Prefix: string)
ProgressBar:SetSuffix(Suffix: string)
ProgressBar:SetDisabled(Disabled: boolean)
ProgressBar:SetVisible(Visible: boolean)
ProgressBar:OnChanged(Func: (Value: number) -> ())
```

Registered in `Library.Options[Idx]`.

---

### 8.8 Dropdown

A single or multi-select dropdown list.

```lua
local Dropdown = Section:AddDropdown("myDropdown", {
    Text   = "Select Mode",       -- Optional label above the box (omit for no label)
    Values = { "A", "B", "C" },
    DisabledValues = {},           -- Values shown but not selectable
    ValueImages    = {},           -- { [Value] = "icon-name or asset-id" }
    Default        = nil,          -- Pre-selected value (string) or list (table) for Multi
    Multi          = false,        -- Allow multiple selections
    AllowNull      = false,        -- Allow deselecting the last item
    Searchable     = false,        -- Show a search box inside the dropdown list
    MaxVisibleDropdownItems = 8,   -- Max visible rows before scrolling
    FormatDisplayValue = nil,      -- function(Value) -> string, format the display text
    FormatListValue    = nil,      -- function(Value) -> string, format each list item

    -- Special types (auto-populate Values)
    SpecialType        = nil,      -- "Player" or "Team"
    ExcludeLocalPlayer = false,    -- Used with SpecialType = "Player"
    EnablePlayerImages = false,    -- Show avatar thumbnails for Player type

    Callback  = function(Value) end,
    Changed   = function(Value) end,
    Disabled  = false,
    Visible   = true,
    Tooltip   = nil,
    DisabledTooltip = nil,
})
```

**Methods:**

```lua
Dropdown:SetValue(Value)              -- string (single) or table (multi)
Dropdown:SetSelectedValue(Value)      -- Set a specific value as selected (without replacing others in multi)
Dropdown:DeselectValue(Value)         -- Deselect a specific value
Dropdown:ClearSelectedValues()        -- Clear all selected values
Dropdown:SetValues(Values: table)     -- Replace the entire value list (auto-deselects removed values)
Dropdown:AddValues(Values: table | string)
Dropdown:SetDisabledValues(Values: table)
Dropdown:AddDisabledValues(Values: table | string)
Dropdown:SetValueImages(Images: table)
Dropdown:AddValueImages(Images: table)
Dropdown:SetText(Text: string?)       -- nil hides the label
Dropdown:SetDisabled(Disabled: boolean)
Dropdown:SetVisible(Visible: boolean)
Dropdown:OnChanged(Func: (Value) -> ())
Dropdown:GetActiveValues(): table | number
```

For `Multi = true`, `Dropdown.Value` is a dictionary `{ [Value] = true }`. For single, it is the raw selected value or `nil`.

`SetValues` automatically deselects any values that are no longer in the updated list. For single-select dropdowns without `AllowNull`, it will select the first available value if the current selection is removed.

Registered in `Library.Options[Idx]`.

---

### 8.9 Viewport

Embeds a 3D ViewportFrame displaying a BasePart or Model.

```lua
local Viewport = Section:AddViewport("myViewport", {
    Object      = someModel,      -- BasePart or Model instance (required)
    Camera      = nil,            -- Custom Camera instance (auto-created if nil)
    Clone       = true,           -- Clone the object before parenting
    AutoFocus   = true,           -- Auto-position camera to fit the object
    Interactive = false,          -- Enable mouse/touch orbit + zoom
    Height      = 200,
    Visible     = true,
})
```

**Methods:**

```lua
Viewport:SetObject(Object: Instance, Clone: boolean?)
Viewport:SetCamera(Camera: Camera)
Viewport:SetInteractive(Interactive: boolean)
Viewport:SetHeight(Height: number)
Viewport:SetVisible(Visible: boolean)
Viewport:Focus()                  -- Re-run AutoFocus camera positioning
```

Registered in `Library.Options[Idx]`.

---

### 8.10 Image

Embeds a static image using any supported icon format.

```lua
local Image = Section:AddImage("myImage", {
    Image               = "rbxassetid://123456",  -- Asset ID, URL, or Lucide icon name (required)
    Color               = Color3.new(1, 1, 1),
    Transparency        = 0,
    BackgroundTransparency = 0,
    RectOffset          = Vector2.zero,
    RectSize            = Vector2.zero,
    ScaleType           = Enum.ScaleType.Fit,
    Height              = 200,
    Visible             = true,
})
```

**Methods:**

```lua
Image:SetImage(NewImage: string)
Image:SetColor(Color: Color3)
Image:SetTransparency(Transparency: number)
Image:SetRectOffset(RectOffset: Vector2)
Image:SetRectSize(RectSize: Vector2)
Image:SetScaleType(ScaleType: Enum.ScaleType)
Image:SetHeight(Height: number)
Image:SetVisible(Visible: boolean)
```

Registered in `Library.Options[Idx]`.

---

### 8.11 Video

Embeds a `VideoFrame` for playing Roblox video assets.

```lua
local Video = Section:AddVideo("myVideo", {
    Video   = "rbxassetid://123456",
    Looped  = false,
    Playing = false,
    Volume  = 1,
    Height  = 200,
    Visible = true,
})
```

**Methods:**

```lua
Video:SetVideo(NewVideo: string)
Video:SetLooped(Looped: boolean)
Video:SetVolume(Volume: number)
Video:SetPlaying(Playing: boolean)
Video:Play()
Video:Pause()
Video:SetHeight(Height: number)
Video:SetVisible(Visible: boolean)
```

Registered in `Library.Options[Idx]`.

---

### 8.12 UIPassthrough

Embeds an arbitrary `GuiBase2d` instance directly inside a section at a fixed height.

```lua
local Pass = Section:AddUIPassthrough("myPass", {
    Instance = someFrame,   -- GuiBase2d (required)
    Height   = 24,
    Visible  = true,
})
```

**Methods:**

```lua
Pass:SetInstance(Instance: GuiBase2d)
Pass:SetHeight(Height: number)
Pass:SetVisible(Visible: boolean)
```

**Sizing:** if the `Instance` you pass in is still at Roblox's own default size (i.e. you never set `.Size` on it yourself), it's automatically stretched to fill the passthrough's `Height`. If you did set a `.Size`, it's left untouched — useful for a fixed-width element anchored to one side instead of filling the row. The passthrough's own holder always clips its contents, so oversized content can't bleed into whatever sits below it in the section.

**ZIndex:** any `GuiObject` you (or your own code, later) parent into the passthrough is automatically bumped to match its holder's `ZIndex` if it's lower. Since the whole UI uses `ZIndexBehavior.Global`, a plain `Instance.new(...)` with no explicit `ZIndex` defaults to `1` and loses against nearly everything else in the library — without this, custom content could be correctly parented and positioned yet render invisibly underneath other UI. This applies automatically, including to whatever you pass to `SetInstance` later — no manual `ZIndex` bookkeeping needed on your end.

Registered in `Library.Options[Idx]`.

---

## 9. Addons (on Labels & Toggles)

Addons attach to **Label** or **Toggle** elements and appear inline to the right of the element label. Call these on the element object _after_ creating it.

### 9.1 KeyPicker

A bindable key button. Supports Always, Toggle, Hold, and Press modes.

```lua
Toggle:AddKeyPicker("myKey", {
    Text    = "KeyPicker",          -- Label shown in the keybind list. Give each KeyPicker a distinct, descriptive Text -- the panel row is literally "[Key] Text (Mode)", so leaving this as a generic placeholder (e.g. "Key") on multiple pickers makes every row look identical.
    Default = "None",               -- Default key name (e.g. "F", "MB1", "None")
    DefaultModifiers = {},          -- e.g. { "LCtrl" }

    Mode  = "Toggle",               -- "Always" | "Toggle" | "Hold" | "Press"
    Modes = { "Always", "Toggle", "Hold" },  -- Modes shown in right-click menu

    SyncToggleState = false,        -- Sync Toggle.Value with KeyPicker.Toggled

    -- Key whitelist/blacklist
    Blacklisted          = {},
    BlacklistedModifiers = {},
    Whitelisted          = {},
    WhitelistedModifiers = {},

    Callback        = function(State: boolean) end,
    ChangedCallback = function(KeyCode, Modifiers) end,
    Changed         = function(KeyCode, Modifiers) end,
    Clicked         = function(State: boolean) end,
})
```

**Supported special key names:** `"MB1"`, `"MB2"`, `"MB3"`

**Supported modifier names:** `"LAlt"`, `"RAlt"`, `"LCtrl"`, `"RCtrl"`, `"LShift"`, `"RShift"`, `"Tab"`, `"CapsLock"`

**Methods:**

```lua
KeyPicker:SetValue({ Key = "F", Mode = "Toggle", Modifiers = { "LShift" } })
-- Positional form also accepted: KeyPicker:SetValue({ Key, Mode, Modifiers })
-- Mode/Modifiers are optional in the dict form and default to the picker's current values.
KeyPicker:GetState(): boolean
KeyPicker:SetText(Text: string)
KeyPicker:OnChanged(Func)
KeyPicker:OnClick(Func)
```

Left-click the key button to enter picking mode (shows `...`). Press the desired key or combo. Right-click to open the mode selector menu. The keybind also appears in the floating **Keybinds** panel.

**Keybinds Panel:** The floating Keybinds panel displays all registered keybinds. It can be toggled via the window's keybind or programmatically through `Library.KeybindFrame.Visible`. Each row is rendered as `[Key] Text (Mode)`, where `Text` is the KeyPicker's own `Text` field -- **not** the element's `Idx`. Each entry shows:
- Current key binding
- The KeyPicker's `Text` label
- Mode (Toggle, Hold, Press, Always)
- Toggle checkbox (if enabled via `Library.ShowToggleFrameInKeybinds`)

Because the row's label comes from `Text`, distinct KeyPickers that all share the same `Text` (e.g. every picker left as `Text = "Key"`) will show up as identical-looking rows in the panel, differing only by their key/mode. Give each KeyPicker a unique, descriptive `Text` to keep the panel readable.

Registered in `Library.Options[Idx]`.

---

### 9.2 ColorPicker

An HSV color picker panel with optional alpha (transparency) support.

```lua
Toggle:AddColorPicker("myColor", {
    Default      = Color3.new(1, 1, 1),
    Transparency = nil,    -- If a number (0–1) is provided, shows an alpha slider
    Title        = nil,    -- Optional title shown inside the picker panel
    Callback     = function(Color: Color3) end,
    Changed      = function(Color: Color3) end,
})
```

**Methods:**

```lua
ColorPicker:SetValue(HSV: {number, number, number} | Color3, Transparency?: number)
ColorPicker:SetValueRGB(Color: Color3, Transparency?: number)
ColorPicker:OnChanged(Func: (Color: Color3) -> ())
```

Left-click the color swatch to open the picker. Right-click for a context menu with **Copy color**, **Paste color**, **Copy Hex**, and **Copy RGB** options (clipboard options require `setclipboard`).

The picker contains:
- A 200×200 saturation/value map
- A hue strip
- An optional alpha strip (if `Transparency` is set)
- Hex and RGB text inputs

**Layout:** the picker renders inline, as its own row directly beneath whichever Label or Toggle it's attached to — it does not float above other content. Opening it inserts this row into the owning section and closes automatically on an outside click, exactly like every other addon/popup in the library. It behaves identically whether attached to a Label or a Toggle.

Registered in `Library.Options[Idx]`.

---
## 10. Notifications

```lua
local Notif = Library:Notify({
    Title       = "Success",           -- Optional title line
    Description = "Action completed",  -- Main message text
    Time        = 5,                   -- Duration in seconds; or a Roblox Instance (destroyed to dismiss)
    Icon        = nil,                 -- Small icon next to the title (Lucide / asset ID)
    BigIcon     = nil,                 -- Large icon to the left of all text
    IconColor   = nil,                 -- Color3 for the icon; defaults to AccentColor (BigIcon) or FontColor
    SoundId     = nil,                 -- number or rbxassetid string, played on appear
    Steps       = nil,                 -- number of steps for a progress bar (use ChangeStep to advance)
    Persist     = false,               -- Never auto-dismiss (no timer bar shown)
})

-- Shorthand (description + optional time):
Library:Notify("Something happened", 3)
```

**Methods:**

```lua
Notif:ChangeTitle(Text: string)
Notif:ChangeDescription(Text: string)
Notif:ChangeStep(NewStep: number)    -- Advances the step progress bar
Notif:Destroy()                      -- Manually dismiss
```

Notifications slide in from the configured side and slide back out when dismissed. The timer bar drains over the `Time` duration.

---

## 11. Key Tab

A special tab variant intended for key-gated content (e.g., a whitelist key entry screen).

```lua
local KeyTab = Window:AddKeyTab({
    Name = "Key",
    Icon = "key",           -- Defaults to the key icon if omitted
})

-- Add a key input box
KeyTab:AddKeyBox(function(Key)
    -- Key is the string the user entered
    if Key == "my-secret-key" then
        -- grant access
    end
end)

-- Add a label
KeyTab:AddLabel("Enter your key below")

-- Add a link button
KeyTab:AddLinkBox("Get Key", "https://example.com")
```

Key tabs use a centered, single-column scrolling layout. The searchbar is disabled while a key tab is active.

---

## 12. Draggable Overlays

Floating panels that exist outside the main window. Useful for persistent mini-displays. Every overlay created through the methods below — draggable labels, buttons, toggles, progress bars, menus, and context menus — is automatically registered in a central registry (`Library.Overlays`) the moment it's created. See **12.6 Overlay Manager** for the bulk toggle/remove API that works across all of them.

### 12.1 Draggable Label

```lua
local LabelOverlay = Library:AddDraggableLabel("My Label")

LabelOverlay:SetText("New Text")
LabelOverlay:SetVisible(true)
```

### 12.2 Draggable Button

```lua
local BtnOverlay = Library:AddDraggableButton("Click Me", function(self)
    -- self is the BtnOverlay table
end)

BtnOverlay:SetText("New Label")
```

### 12.3 Draggable Toggle

A floating on/off switch, useful for things like a persistent "Auto Farm" or "ESP" toggle that lives outside the main window.

```lua
local ToggleOverlay = Library:AddDraggableToggle("Auto Farm", false, function(Value)
    print("Auto Farm:", Value)
end)

ToggleOverlay:SetValue(true)
print(ToggleOverlay.Value)
```

**Signature:** `Library:AddDraggableToggle(Text: string, Default: boolean?, Callback: (Value: boolean) -> ())`

### 12.4 Draggable Progress

A floating progress/status bar. Handy for showing farm progress, a loading state, or any running total without needing the main window open.

```lua
local ProgressOverlay = Library:AddDraggableProgress("Loading...", 0, 100)

ProgressOverlay:SetValue(50)     -- clamps to [0, Max]
ProgressOverlay:SetText("Halfway there")
```

**Signature:** `Library:AddDraggableProgress(Text: string, Default: number?, Max: number?)`

### 12.5 Draggable Menu

A titled floating panel with a title bar (minimize + close buttons, styled to match the main window's own controls) and a container that supports the full set of normal element methods.

```lua
local Holder, RawContainer, Container = Library:AddDraggableMenu("Menu Title")

-- Container behaves like a normal Section -- use the same Add* methods
-- you'd use anywhere else in the library:
Container:AddButton({ Text = "Click Me", Func = function() end })
Container:AddToggle("myToggle", { Text = "Some Setting", Default = false })
Container:AddSlider("mySlider", { Text = "Some Value", Default = 25, Min = 0, Max = 100 })

-- You can also still parent your own raw Instances via AddUIPassthrough,
-- same as any Section:
Container:AddUIPassthrough("myCustom", { Instance = someFrame, Height = 30 })
```

**Return values:**
- `Holder` — the whole floating panel (title bar + body), the Instance you'd pass to `Library:MakeDraggable` or destroy directly.
- `RawContainer` — the raw content `Frame` Instance. Rarely needed directly; kept for advanced use.
- `Container` — the element-friendly wrapper. Use this one. Supports `AddButton`, `AddToggle`, `AddSlider`, `AddInput`, `AddDropdown`, `AddLabel`, `AddKeyPicker`/`AddColorPicker` addons, `AddUIPassthrough`, `AddDivider`, etc. — the same methods a normal `Section` has. Nested-Tab-only features (`AddViewport`'s scroll-lock, `AddConditionalSection`, nested `AddSubSection`) aren't available here, since a draggable menu has no owning Tab.

**Title bar:** every draggable menu has a minimize (`-`) button that collapses the body (hides `Container`, keeps its state and the panel's position — re-expanding restores exactly where it was left) and a close (`×`) button that destroys the whole panel outright. Both match the main window's own minimize/close button styling.

```lua
Container:SetCollapsed(true)      -- collapse (same as clicking minimize)
Container:ToggleCollapsed()       -- flip collapsed state
Container:Remove()                -- destroy the whole menu (same as clicking close)
```

**Sizing:** the panel's width is fixed at creation (auto-widened only if the title text needs more room) and its height grows automatically with content, capped at a maximum height so it can never grow to fill the screen.

### 12.6 Overlay Manager

Every overlay created via `AddDraggableLabel`, `AddDraggableButton`, `AddDraggableToggle`, `AddDraggableProgress`, `AddDraggableMenu`, or `AddContextMenu` is automatically added to `Library.Overlays`, keyed by a numeric `Id`. No manual bookkeeping is required — this lets you build a "toggle UI elements" panel, a cleanup routine, or a settings option that hides/shows/removes overlays in bulk without tracking references yourself.

Every overlay table carries three extra fields once registered:

| Field | Meaning |
|---|---|
| `Overlay.Id` | Unique numeric id, assigned in creation order |
| `Overlay.OverlayType` | `"DraggableLabel"`, `"DraggableButton"`, `"DraggableToggle"`, `"DraggableProgress"`, `"DraggableMenu"`, or `"ContextMenu"` |
| `Overlay.OverlayName` | The label/title text passed at creation, or an auto-generated fallback |

And every overlay table supports these methods, regardless of type:

```lua
Overlay:SetVisible(true)   -- show / hide without destroying
Overlay:IsVisible()        -- -> boolean
Overlay:Remove()           -- destroy and unregister
```

**Library-level methods** (operate across every registered overlay, or a filtered subset):

```lua
Library:GetOverlays()                     -- -> array of ALL overlay tables, in creation order
Library:GetOverlays("DraggableToggle")    -- -> array filtered to just that type
Library:GetOverlay(Id)                    -- -> single overlay table, or nil

Library:SetOverlayVisible(Id, true)       -- show/hide a specific overlay by Id
Library:ToggleOverlay(Id)                 -- flip a specific overlay's visibility
Library:RemoveOverlay(Id)                 -- destroy + unregister a specific overlay

Library:SetAllOverlaysVisible(false)                    -- hide every overlay
Library:SetAllOverlaysVisible(true, "DraggableLabel")   -- show only labels

Library:RemoveAllOverlays()                    -- destroy + unregister every overlay
Library:RemoveAllOverlays("ContextMenu")       -- destroy + unregister only context menus
```

Example: build a simple management list from scratch, without keeping your own references around from the moment each overlay was created:

```lua
for _, Overlay in Library:GetOverlays() do
    print(("#%d  %s  (%s)  visible=%s"):format(
        Overlay.Id, Overlay.OverlayName, Overlay.OverlayType, tostring(Overlay:IsVisible())
    ))
end
```

---

## 13. Dialogs

A modal popup dialog with a title, description, optional element content, and footer action buttons. Only one dialog overlay is shown at a time per call; dialogs darken the background and block interaction with the window behind them.

```lua
local Dialog = Window:AddDialog("confirmDelete", {
    Title               = "Delete Config?",
    Description          = "This action cannot be undone.",
    Icon                = "trash-2",            -- Optional Lucide icon name / asset ID
    TitleColor          = nil,                  -- Optional Color3 override for icon + title
    DescriptionColor    = nil,                  -- Optional Color3 override for description text
    AutoDismiss         = true,                 -- Dismiss automatically when a footer button is clicked
    OutsideClickDismiss = true,                 -- Clicking the dark overlay dismisses the dialog
    ButtonsAlignment    = "Right",              -- Footer buttons alignment: "Left" | "Center" | "Right"
    FooterButtons = {
        Cancel = { Title = "Cancel", Variant = "Secondary", Order = 1, Callback = function(Dialog) end },
        Confirm = {
            Title    = "Delete",
            Variant  = "Destructive",            -- "Primary" | "Secondary" | "Destructive" | "Ghost"
            Order    = 2,
            WaitTime = 0,                         -- Seconds the button stays disabled with a fill animation (e.g. "hold to confirm" delays)
            Callback = function(Dialog) end,
        },
    },
})
```

Dialogs support the same element methods as a `Section` (`AddLabel`, `AddInput`, `AddToggle`, `AddSlider`, `AddDropdown`, etc.) — added elements appear in the body, above the footer buttons:

```lua
Dialog:AddInput("dialogInput", { Text = "Config Name", Placeholder = "MyConfig" })
```

**Methods:**

```lua
Dialog:SetTitle(Title: string)
Dialog:SetDescription(Description: string)
Dialog:SetButtonsAlignment(Alignment: string)          -- Alignment: "Left" | "Center" | "Right"
Dialog:Dismiss()                                       -- Close and destroy the dialog
Dialog:AddFooterButton(ButtonIdx, ButtonInfo)           -- Add or replace a footer button
Dialog:RemoveFooterButton(ButtonIdx)
Dialog:SetButtonDisabled(ButtonIdx, Disabled: boolean)
Dialog:SetButtonOrder(ButtonIdx, Order: number)
```

Registered in `Library.Dialogues[Idx]`. `Library.ActiveDialog` points to the most recently opened dialog while it's visible.

---

## 14. Loading Screens

A separate standalone window (its own `ScreenGui`) shown before/instead of the main UI — useful for a key-system or "initializing" splash screen. Only one loading screen can exist at a time.

```lua
local Loading = Library:CreateLoading({
    Title    = "Astral",
    Icon     = "AstralIcon",              -- Lucide icon name, asset ID, or built-in asset name
    IconSize = UDim2.fromOffset(30, 30),

    LoadingIcon          = "LoadingIcon", -- Spinner icon
    LoadingIconColor     = nil,
    LoadingIconTweenTime = 1,             -- Spin duration in seconds (0 disables spinning)

    CurrentStep = 0,
    TotalSteps  = 10,

    ShowSidebar      = false,             -- Show a side panel next to the main content
    AutoResizeHeight = false,             -- Automatically grow window height to fit content

    WindowWidth  = 450,
    WindowHeight = 275,
    ContentWidth = 450,
    SidebarWidth = 250,
})
```

Creating a loading screen automatically hides the main window (`Library:Toggle(false)`) while it's active, and automatically re-shows the main window once the loading screen is destroyed.

**Methods:**

```lua
-- Content
Loading:SetMessage(Text: string)
Loading:SetDescription(Text: string)
Loading:SetLoadingIcon(Icon: string)
Loading:SetLoadingIconTweenTime(TweenTime: number)
Loading:SetLoadingIconColor(Color: Color3)

-- Progress
Loading:SetCurrentStep(Step: number)
Loading:SetTotalSteps(Steps: number)

-- Sizing
Loading:SetWindowHeight(Height: number)
Loading:SetWindowWidth(Width: number)
Loading:SetContentWidth(Width: number)
Loading:SetSidebarWidth(Width: number)

-- Sidebar page
Loading:ShowSidebarPage(Bool: boolean)

-- Error page (swaps the body for a centered error message + buttons)
Loading:ShowErrorPage(Enabled: boolean)
Loading:SetErrorMessage(Text: string)
Loading:SetErrorButtons({
    Retry = { Title = "Retry", Variant = "Primary", Callback = function(Loading) end },
})

-- Cleanup
Loading:Destroy()       -- Also available as Loading:Continue() (alias)
```

`Library.ActiveLoading` references the active loading screen object; `Library:CreateLoading` returns the existing instance with a warning if one is already active rather than creating a second one.

---

## 15. Theme / Scheme

The active color scheme is stored in `Library.Scheme`. All colors are applied reactively via the registry system.

### Default Scheme

| Key | Default | Description |
|---|---|---|
| `BackgroundColor` | `RGB(13, 13, 16)` | Outermost window background |
| `MainColor` | `RGB(21, 21, 25)` | Panel and control background |
| `AccentColor` | `RGB(66, 135, 245)` | Active state color (sliders, toggles on) |
| `OutlineColor` | `RGB(36, 36, 42)` | Border/stroke color |
| `FontColor` | `RGB(255, 255, 255)` | Default text color |
| `Font` | `GothamMedium` | UI font |
| `RedColor` | `RGB(255, 64, 64)` | Risky element text |
| `DestructiveColor` | `RGB(225, 60, 60)` | Destructive action accent |
| `DarkColor` | `RGB(0, 0, 0)` | Shadow stroke color |
| `WhiteColor` | `RGB(255, 255, 255)` | Cursor and light highlight color |

### Updating Colors

Directly mutate `Library.Scheme` then call:

```lua
Library.Scheme.AccentColor = Color3.fromRGB(255, 100, 50)
Library:UpdateColorsUsingRegistry()
```

Or use the font setter:

```lua
Library:SetFont(Enum.Font.Code)
Library:SetFont(Font.fromEnum(Enum.Font.Code))
```

---

## 16. Global Registries

| Table | Contents |
|---|---|
| `Library.Toggles` | All toggles, keyed by `Idx` |
| `Library.Options` | All inputs, sliders, dropdowns, viewports, images, videos, passthroughs, keypickers, colorpickers — keyed by `Idx` |
| `Library.Labels` | All labels (array-indexed or keyed by `Idx`) |
| `Library.Buttons` | All buttons keyed by `Idx` (when provided) |
| `Library.Tabs` | All tabs keyed by name |
| `Library.Notifications` | All active notification objects |
| `Library.Overlays` | All draggable labels/buttons/toggles/progress bars/menus and context menus, keyed by numeric `Id` — see [12.6 Overlay Manager](#126-overlay-manager) |

Access any registered element globally:

```lua
Library.Toggles["myToggle"]:SetValue(true)
Library.Options["mySlider"]:SetValue(75)
Library.Options["myDropdown"]:SetValue("Option B")
Library.Overlays[1]:SetVisible(false)
```

---

## 17. Unloading

```lua
Library:Unload()
```

Disconnects all signals registered via `Library:GiveSignal`, fires all `Library:OnUnload` callbacks, destroys tooltips, destroys the ScreenGui, and sets `getgenv().Library = nil`.

The `Library.Unloaded` flag is set to `true` immediately; all internal callbacks check this flag and return early if set.

```lua
Library:OnUnload(function()
    -- cleanup code
end)
```

---

## 18. SaveManager

SaveManager provides automatic configuration persistence: it always keeps an autosave watcher running in the background, so there's no separate "enable autosave" step or debounce configuration — once you call `BuildConfigSection`, saving and loading are fully hands-off.

### Setup

```lua
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/inCythe/Astral/refs/heads/main/addons/SaveManager.lua"))()

-- Link to the library
SaveManager:SetLibrary(Library)

-- Optional: Set custom folder (default: "AstralSettings")
SaveManager:SetFolder("MyScriptSettings")

-- Optional: Set subfolder for organization
SaveManager:SetSubFolder("profiles")

-- Optional: Ignore theme-related settings from saves (use when ThemeManager is also present)
SaveManager:IgnoreThemeSettings()
```

### Key Properties

| Property | Type | Default | Description |
|---|---|---|---|
| `SaveManager.Folder` | string | `"AstralSettings"` | Root folder for settings |
| `SaveManager.SubFolder` | string | `""` | Subfolder for organization |
| `SaveManager.Library` | Library | `nil` | Reference to the Astral library |
| `SaveManager.Ignore` | table | `{}` | Indexes to ignore during save/load |
| `SaveManager.CurrentConfig` | string? | `nil` | Name of the config currently loaded/active |

### Core Methods

```lua
-- Save current configuration
SaveManager:Save(name: string): (success: boolean, error: string?)

-- Load a saved configuration (applies values onto whatever elements
-- currently exist in Library.Toggles / Library.Options)
SaveManager:Load(name: string): (success: boolean, error: string?)

-- Delete a saved configuration
SaveManager:Delete(name: string): (success: boolean, error: string?)

-- Refresh the list of available configurations
SaveManager:RefreshConfigList(): { string }

-- Set indexes to ignore during save/load
SaveManager:SetIgnoreIndexes(list: { string })

-- Ignore theme-related settings automatically
SaveManager:IgnoreThemeSettings()

-- Reset every registered Toggle/Option back to its library-defined default
SaveManager:ResetToDefaults()

-- If the player's own per-user config doesn't exist yet, create it from
-- current values; otherwise load it. Either way it becomes CurrentConfig.
-- Called automatically by BuildConfigSection.
SaveManager:EnsureStartupConfig(): (name: string)

-- Start the always-on autosave watcher (polls every 0.5s for changes).
-- Called automatically by BuildConfigSection -- you don't need to call
-- this yourself under normal use.
SaveManager:StartAutoSaveWatcher()
```

### GUI Integration

```lua
-- Automatically build a configuration section in a tab
SaveManager:BuildConfigSection(tab: Tab)
```

This creates a full UI section with:
- A dropdown listing every saved config, auto-selecting the currently active one
- An input + button to create a new config (starts from default values, not whatever's currently loaded)
- A button to delete the current config — always resets every registered Toggle/Option back to its library-defined default (via `ResetToDefaults`) afterward and saves that as the player's default config, so deleting a config always leaves you in a clean, default state rather than switching to another saved config or keeping stale in-memory values
- An always-on autosave watcher — any change to a registered Toggle/Option is detected within ~0.5s and written to the active config automatically, with no separate enable step
- Automatic config list refreshing, so the dropdown stays current without a manual refresh button

`EnsureStartupConfig` runs as part of `BuildConfigSection`, so the player's own config (or a fresh default one) is loaded as soon as the config section itself is built.

### Avoiding the "flash of default values" on startup

`SaveManager:Load()` can only set a value on a Toggle/Slider/etc. that **already exists** — it looks elements up by name in `Library.Toggles`/`Library.Options`, which only get populated as your own `AddToggle`/`AddSlider`/etc. calls run. That means `Load()` can only ever run *after* every element in your whole UI has already been created — and by then, each one has already rendered once with its `Default` value. If the window is visible during that gap, the player sees the default value snap to the saved one a moment later.

To avoid that entirely, keep the window hidden until after the config has loaded, using `SaveManager:Init`:

```lua
-- 1. Create the window WITHOUT showing it yet
local Window = Library:CreateWindow({ Name = "My UI", AutoShow = false })

-- 2. Build every tab, section, and element for your ENTIRE UI here
local MainTab = Window:AddTab({ Name = "Main" })
-- ... AddToggle, AddSlider, etc. ...

local SettingsTab = Window:AddTab({ Name = "Settings" })
SaveManager:SetLibrary(Window)
SaveManager:BuildConfigSection(SettingsTab)  -- adds the config UI, does not show the window

-- 3. Load the config, THEN reveal the window -- no flash
SaveManager:Init(Window)
```

`SaveManager:Init(Window)` re-runs `Load` against every element that now exists in the whole UI (not just the ones that existed when `BuildConfigSection` ran) and then calls `Window:Toggle(true)`. `AutoShow = false` at `CreateWindow` is required — if the window auto-shows itself, it's already visible before your script reaches the `Init` call.

If you're also using a loading screen (`Library:CreateLoading`), note that `Window:Toggle(true)` is silently ignored while that loading screen is still active — call `Init` after the loading screen finishes, or let the loading screen's own hand-off reveal the window instead.

### Supported Element Types

SaveManager automatically handles the following element types:
- **Toggle**: Saves boolean state
- **Slider**: Saves numeric value
- **ProgressBar**: Saves numeric value
- **Dropdown**: Saves selected value
- **ColorPicker**: Saves color hex and transparency
- **KeyPicker**: Saves key, mode, and modifiers
- **Input**: Saves text content

### Example Usage

```lua
-- Basic setup
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/inCythe/Astral/refs/heads/main/addons/SaveManager.lua"))()
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()

-- Add configuration UI to a tab
local Tab = Window:AddTab({ Name = "Settings" })
SaveManager:BuildConfigSection(Tab)

-- Manual save/load, if you need it outside the built-in GUI
SaveManager:Save("MyConfig")
SaveManager:Load("MyConfig")
```

**Autosave behavior:**
- A background watcher polls every ~0.5 seconds and compares a fingerprint of every registered Toggle/Option's value against its last known state
- On any change, it saves to whichever config is currently active (`SaveManager.CurrentConfig`) — there's no separate enable/target step
- Saving is skipped entirely while a `Load()` is in progress, so applying saved values back onto the UI never gets mistaken for a user edit and re-saved

---

## 19. ThemeManager

ThemeManager provides comprehensive theme management with 18 built-in themes and support for custom theme creation, saving, and loading.

### Setup

```lua
local ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/inCythe/Astral/refs/heads/main/addons/ThemeManager.lua"))()

-- Link to the library
ThemeManager:SetLibrary(Library)

-- Optional: Set custom folder (default: "AstralSettings")
ThemeManager:SetFolder("MyScriptSettings")

-- Optional: Set default theme before applying to tab
ThemeManager:SetDefaultTheme({
    FontColor = Color3.fromHex("ffffff"),
    MainColor = Color3.fromHex("191919"),
    AccentColor = Color3.fromHex("4287f5"),
    BackgroundColor = Color3.fromHex("0f0f0f"),
    OutlineColor = Color3.fromHex("282828"),
    FontFace = Enum.Font.Code
})
```

### Built-in Themes

ThemeManager includes 18 pre-configured themes:

| Theme Name | Style |
|---|---|
| **Default** | Matches Astral's built-in scheme exactly (same colors the library ships with before any theme is applied) |
| **BBot** | Purple accent |
| **Fatality** | Pink/purple accent |
| **Jester** | Red accent |
| **Mint** | Green accent |
| **Tokyo Night** | Purple/night theme |
| **Ubuntu** | Orange accent |
| **Quartz** | Blue/cyan theme |
| **Nord** | Nordic color scheme |
| **Dracula** | Dracula theme |
| **Monokai** | Monokai theme |
| **Gruvbox** | Gruvbox theme |
| **Solarized** | Solarized theme |
| **Catppuccin** | Catppuccin theme |
| **One Dark** | One Dark theme |
| **Cyberpunk** | Cyberpunk neon |
| **Oceanic Next** | Oceanic blue |
| **Material** | Material design |

### Key Properties

| Property | Type | Default | Description |
|---|---|---|---|
| `ThemeManager.Folder` | string | `"AstralSettings"` | Root folder for themes |
| `ThemeManager.Library` | Library | `nil` | Reference to the Astral library |
| `ThemeManager.AppliedToTab` | boolean | `false` | Whether theme manager is applied to a tab |
| `ThemeManager.BuiltInThemes` | table | — | Table of built-in themes |
| `ThemeManager.DefaultTheme` | string | `"Default"` | Default theme name |

### Core Methods

```lua
-- Apply a theme (built-in or custom)
ThemeManager:ApplyTheme(themeName: string)

-- Update theme from current option values
ThemeManager:ThemeUpdate()

-- Get custom theme data from file
ThemeManager:GetCustomTheme(fileName: string): table?

-- Load the default theme on startup
ThemeManager:LoadDefault()

-- Save current theme as default
ThemeManager:SaveDefault(themeName: string)

-- Set a custom default theme (before applying to tab)
ThemeManager:SetDefaultTheme(theme: table)

-- Save current settings as a custom theme
ThemeManager:SaveCustomTheme(fileName: string)

-- Delete a custom theme
ThemeManager:Delete(themeName: string): (success: boolean, error: string?)

-- Reload and list custom themes
ThemeManager:ReloadCustomThemes(): { string }
```

### GUI Integration

```lua
-- Apply theme manager to a tab (creates full UI)
ThemeManager:ApplyToTab(tab: Tab)

-- Or create groupbox manually and apply
local groupbox = ThemeManager:CreateGroupBox(tab)
ThemeManager:ApplyToGroupbox(groupbox)

-- Or create theme manager UI in existing groupbox
ThemeManager:CreateThemeManager(groupbox: Section)
```

The GUI includes:
- Color pickers for all theme colors (Background, Main, Accent, Outline, Font)
- Font face dropdown
- Built-in theme dropdown with instant preview
- Custom theme creation (name input + save button)
- Custom theme management (load, overwrite, delete, refresh)
- Default theme management (set/reset default)
- Automatic theme update on color change

### Theme Fields

Themes control the following color fields:
- **FontColor**: Text color
- **MainColor**: Primary UI element color
- **AccentColor**: Interactive element accent color
- **BackgroundColor**: Background color
- **OutlineColor**: Border/outline color
- **FontFace**: Font family

### Example Usage

```lua
-- Basic setup
local ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/inCythe/Astral/refs/heads/main/addons/ThemeManager.lua"))()
ThemeManager:SetLibrary(Library)

-- Add theme manager to a tab
local Tab = Window:AddTab({ Name = "Settings" })
ThemeManager:ApplyToTab(Tab)

-- Manual theme application
ThemeManager:ApplyTheme("Dracula")

-- Custom theme creation
ThemeManager:SaveCustomTheme("MyCustomTheme")

-- Set custom default theme
ThemeManager:SetDefaultTheme({
    FontColor = Color3.fromHex("ffffff"),
    MainColor = Color3.fromHex("1a1a2e"),
    AccentColor = Color3.fromHex("ff6b6b"),
    BackgroundColor = Color3.fromHex("0f0f1a"),
    OutlineColor = Color3.fromHex("2a2a3e"),
    FontFace = Enum.Font.Gotham
})
```

### Integration with SaveManager

ThemeManager works seamlessly with SaveManager:

```lua
-- Set up both managers
SaveManager:SetLibrary(Library)
ThemeManager:SetLibrary(Library)

-- Ignore theme settings in configs
SaveManager:IgnoreThemeSettings()

-- Theme settings will be managed separately by ThemeManager
-- Other settings will be saved/loaded by SaveManager
```

---

## 20. Advanced Utilities

Lower-level building blocks used internally by the library, exposed for advanced/custom UI work.

### 20.1 Tooltips

Manually attach a hover tooltip to any `GuiObject`. (Most elements already expose this via their `Tooltip`/`DisabledTooltip` fields — use `AddTooltip` directly only when building custom UI.)

```lua
local Tooltip = Library:AddTooltip("Shown normally", "Shown while disabled", SomeGuiObject)

Tooltip.Disabled = true   -- Switch to showing the disabled text
Tooltip:Destroy()         -- Disconnect and remove the tooltip
```

### 20.2 Context Menus

A low-level positioned popup/menu primitive (used internally for dropdowns, color pickers, and right-click menus). Useful when building fully custom elements.

```lua
local Menu = Library:AddContextMenu(
    HolderInstance,                 -- GuiObject the menu is anchored to
    UDim2.fromOffset(200, 100),     -- Size (UDim2 or a function returning one)
    { 0, 30 },                      -- Offset from the holder's position ({x, y} or a function returning one)
    nil,                            -- List mode: nil (plain Frame), 1 (auto-size ScrollingFrame), 2 (scrollable list)
    function(Active) end,           -- Optional callback fired on open/close
    false                           -- IgnoreCornerRadius
)

Menu:Open()
Menu:Close()
Menu:Toggle()
Menu:SetSize(UDim2.fromOffset(220, 120))
Menu:Remove()   -- destroy and unregister from the overlay manager
```

Only one context menu can be open at a time globally — opening a new one closes whichever was previously open. Like every other floating overlay, each context menu is registered in `Library.Overlays` on creation — see [12.6 Overlay Manager](#126-overlay-manager) for bulk toggle/remove access (`OverlayType` is `"ContextMenu"`).

---

## 21. Icon Reference

Any `IconName` / `Icon` field across the library (tabs, sections, buttons, dialogs, notifications, etc.) accepts one of:

- A **Lucide icon name** from the list below, e.g. `"settings"`, `"crosshair"`, `"trash-2"`
- A **`rbxassetid://...`** string
- A raw **asset ID** number/string
- A full **asset URL**

Invalid or unrecognized names are handled gracefully (no icon is shown) rather than erroring.

Use `Library:GetIcon(IconName)` to look up an icon directly, or `Library:GetCustomIcon(IconName)` to also resolve named built-in/custom assets (e.g. `"AstralIcon"`), asset IDs, and URLs. `Library:SetIconModule(module)` swaps in an external/custom Lucide module if you need a newer icon set.