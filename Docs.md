# Astral UI Library — Full API Reference

> A feature-rich Roblox exploit UI library with a dark, modern aesthetic. Supports both PC and mobile, themes, keybinds, notifications, dialogs, loading screens, and a full suite of interactive elements.

---

## Table of Contents

1. [Setup & Loading](#1-setup--loading)
2. [Library Object](#2-library-object)
3. [Creating a Window](#3-creating-a-window)
4. [Window API](#4-window-api)
5. [Tabs & Tab Sections](#5-tabs--tab-sections)
6. [Sections & Section Groups](#6-sections--section-groups)
7. [Elements](#7-elements)
   - [Divider](#71-divider)
   - [Label](#72-label)
   - [Button](#73-button)
   - [Toggle / Checkbox](#74-toggle--checkbox)
   - [Input](#75-input)
   - [Slider](#76-slider)
   - [Dropdown](#77-dropdown)
   - [Viewport](#78-viewport)
   - [Image](#79-image)
   - [Video](#710-video)
   - [UIPassthrough](#711-uipassthrough)
8. [Addons (on Labels & Toggles)](#8-addons)
   - [KeyPicker](#81-keypicker)
   - [ColorPicker](#82-colorpicker)
9. [Conditional Groups & Sections](#9-conditional-groups--sections)
10. [Notifications](#10-notifications)
11. [Key Tab](#11-key-tab)
12. [Draggable Overlays](#12-draggable-overlays)
13. [Theme / Scheme](#13-theme--scheme)
14. [Global Registries](#14-global-registries)
15. [Unloading](#15-unloading)
16. [Addons](#16-addons)
   - [SaveManager](#161-savemanager)
   - [ThemeManager](#162-thememanager)
17. [Dialogs](#17-dialogs)
18. [Loading Screens](#18-loading-screens)
19. [Advanced Utilities](#19-advanced-utilities)
   - [Tooltips](#191-tooltips)
   - [Context Menus](#192-context-menus)

---

## 1. Setup & Loading

The library is loaded via `loadstring` or by requiring the module directly:

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/inCythe/Astral/refs/heads/main/Astral.lua"))()
```

Once loaded, `Library` is also stored in `getgenv().Library` for global access. On re-execution, any existing Astral ScreenGui is automatically destroyed or cleanly unloaded before the new instance is created.

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
| `Library.ForceCheckbox` | boolean | false | Force all toggles to render as checkboxes instead of switches |
| `Library.IsMobile` | boolean | auto | Whether the local device is mobile |
| `Library.NotifyOnError` | boolean | false | Show a notification when a callback errors |
| `Library.DPIScale` | number | 1 | Current DPI scale factor |
| `Library.ShowToggleFrameInKeybinds` | boolean | true | Show the toggle checkbox in the keybind list |
| `Library.HighlightSearchResults` | boolean | true | Wrap the matching substring of search results in a colored highlight |
| `Library.Scheme` | table | — | The active color scheme (see [Theme](#13-theme--scheme)) |
| `Library.Toggles` | table | — | All registered toggles, keyed by their `Idx` |
| `Library.Options` | table | — | All registered options (inputs, sliders, dropdowns, etc.) keyed by `Idx` |
| `Library.Labels` | table | — | All registered labels |
| `Library.Buttons` | table | — | All registered buttons |
| `Library.ImageManager` | table | — | Custom asset/image management system |

### Utility Methods

```lua
-- Set DPI scaling (100 = default)
Library:SetDPIScale(DPIScale: number)

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

-- Get a custom icon supporting asset IDs, rbxassetid URLs, and Lucide names
Library:GetCustomIcon(IconName: string): Icon?

-- Set an external Lucide icon module
Library:SetIconModule(module: IconModule)

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

-- Validate a table against a template (fills in missing keys)
Library:Validate(Table: table, Template: table): table
```

---

## 3. Creating a Window

```lua
local Window = Library:CreateWindow({
    Title        = "My Script",            -- Window title (string)
    Footer       = "v1.0.0",              -- Footer text shown at the bottom
    Icon         = nil,                   -- Lucide icon name, rbxassetid, or asset URL
    IconSize     = UDim2.fromOffset(30, 30),
    Size         = UDim2.fromOffset(720, 600),
    Position     = UDim2.fromOffset(6, 6),
    Center       = true,                  -- Center window on screen
    AutoShow     = true,                  -- Show window immediately on create
    Resizable    = true,                  -- Allow window to be resized by dragging the corner
    CornerRadius = 6,                     -- Corner radius (0–20)
    Font         = Enum.Font.GothamMedium,

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

    -- Sidebar resize (experimental)
    EnableSidebarResize = false,

    -- Mobile
    ShowMobileButtons = true,
    MobileButtonsSide = "Left",           -- "Left" or "Right"

    -- Mouse unlock
    UnlockMouseWhileOpen = true,

    -- Discord button (shown at the bottom of the sidebar, set DiscordLink to enable it)
    DiscordLink = nil,                    -- e.g. "https://discord.gg/yourinvite"
    DiscordAction = "open",               -- "open" (tries Discord RPC, falls back to clipboard) or "clipboard"

    -- Instance management
    SingleInstance = true,                -- Destroy any existing window with same Title on create
})
```

All fields are optional and fall back to sensible defaults. The window starts hidden; toggle it with the `ToggleKeybind` (default `RightControl`).

The window has **Minimize** (`−`) and **Close** (`×`) buttons in the top-right. Minimize hides the window. Close hides and then calls `Library:Unload()`.

---

## 4. Window API

Methods on the `Window` object returned from `Library:CreateWindow`.

```lua
Window:ChangeTitle(title: string)
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

### Key Tab

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

## 6. Sections & Section Groups

### AddSection

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

Sections are laid out top-to-bottom in the order they're added. Omitting `Side` (or any value other than `1`/`2`) creates a full-width, one-column section instead of placing it in the left/right two-column row. The first time a left or right section is added, a single two-column row is created at that point in the layout; every subsequent left/right section is appended into that same row (left column top-to-bottom, then right column top-to-bottom), while full-width sections added before or after it keep their own creation order above/below the row.

The global searchbar/overlay (see [Window API](#4-window-api)) lists matching sections and elements in this same visual order — full-width sections in creation order, then the entire left column top-to-bottom, then the entire right column top-to-bottom — rather than an arbitrary order, so results always read top-to-bottom, left-to-right just like the tab itself.

### AddSectionGroup (Tabbed Section Box)

A section box with multiple sub-tabs at the top, sharing the same panel area.

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

---

## 7. Elements

All elements are added to a `Section` (or SectionGroup page). Every element that stores a value takes an `Idx` string as its first argument — this key is used to register the element in `Library.Options` or `Library.Toggles`.

### 7.1 Divider

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

### 7.2 Label

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

### 7.3 Button

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

### 7.4 Toggle / Checkbox

A boolean toggle rendered as a pill switch or as a checkbox (if `Library.ForceCheckbox = true` or `AddCheckbox` is called directly).

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

### 7.5 Input

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

### 7.6 Slider

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

### 7.7 Dropdown

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
Dropdown:SetValues(Values: table)     -- Replace the entire value list
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

Registered in `Library.Options[Idx]`.

---

### 7.8 Viewport

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

### 7.9 Image

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

### 7.10 Video

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

### 7.11 UIPassthrough

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

Registered in `Library.Options[Idx]`.

---

## 8. Addons

Addons attach to **Label** or **Toggle** elements and appear inline to the right of the element label. Call these on the element object _after_ creating it.

### 8.1 KeyPicker

A bindable key button. Supports Always, Toggle, Hold, and Press modes.

```lua
Toggle:AddKeyPicker("myKey", {
    Text    = "KeyPicker",          -- Label used in the keybind list
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
KeyPicker:SetValue({ Key, Mode, Modifiers })
KeyPicker:GetState(): boolean
KeyPicker:SetText(Text: string)
KeyPicker:OnChanged(Func)
KeyPicker:OnClick(Func)
```

Left-click the key button to enter picking mode (shows `...`). Press the desired key or combo. Right-click to open the mode selector menu. The keybind also appears in the floating **Keybinds** panel.

Registered in `Library.Options[Idx]`.

---

### 8.2 ColorPicker

An HSV color picker popup with optional alpha (transparency) support.

```lua
Toggle:AddColorPicker("myColor", {
    Default      = Color3.new(1, 1, 1),
    Transparency = nil,    -- If a number (0–1) is provided, shows an alpha slider
    Title        = nil,    -- Optional title shown inside the picker popup
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

Registered in `Library.Options[Idx]`.

---

## 9. Conditional Groups & Sections

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

**Notification Methods:**

```lua
Notif:ChangeTitle(Text: string)
Notif:ChangeDescription(Text: string)
Notif:ChangeStep(NewStep: number)    -- Advances the step progress bar
Notif:Destroy()                      -- Manually dismiss
```

Notifications slide in from the configured side and slide back out when dismissed. The timer bar drains over the `Time` duration.

---

## 11. Key Tab

See [Tabs & Tab Sections — Key Tab](#key-tab) above.

---

## 12. Draggable Overlays

Floating panels that exist outside the main window. Useful for persistent mini-displays.

### Draggable Label

```lua
local LabelOverlay = Library:AddDraggableLabel("My Label")

LabelOverlay:SetText("New Text")
LabelOverlay:SetVisible(true)
```

### Draggable Button

```lua
local BtnOverlay = Library:AddDraggableButton("Click Me", function(self)
    -- self is the BtnOverlay table
end)

BtnOverlay:SetText("New Label")
```

### Draggable Menu

A titled floating panel with a container for custom children.

```lua
local Holder, Container = Library:AddDraggableMenu("Menu Title")
-- Parent your custom UI into Container
```

---

## 13. Theme / Scheme

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

## 14. Global Registries

| Table | Contents |
|---|---|
| `Library.Toggles` | All toggles, keyed by `Idx` |
| `Library.Options` | All inputs, sliders, dropdowns, viewports, images, videos, passthroughs, keypickers, colorpickers — keyed by `Idx` |
| `Library.Labels` | All labels (array-indexed or keyed by `Idx`) |
| `Library.Buttons` | All buttons keyed by `Idx` (when provided) |
| `Library.Tabs` | All tabs keyed by name |
| `Library.Notifications` | All active notification objects |

Access any registered element globally:

```lua
Library.Toggles["myToggle"]:SetValue(true)
Library.Options["mySlider"]:SetValue(75)
Library.Options["myDropdown"]:SetValue("Option B")
```

---

## 15. Unloading

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

## 16. Addons

Astral includes optional addon modules that extend functionality for configuration management and theming.

### 16.1 SaveManager

SaveManager provides automatic configuration persistence, allowing users to save, load, and manage UI settings across sessions.

#### Setup

```lua
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/inCythe/Astral/refs/heads/main/addons/SaveManager.lua"))()

-- Link to the library
SaveManager:SetLibrary(Library)

-- Optional: Set custom folder (default: "AstralSettings")
SaveManager:SetFolder("MyScriptSettings")

-- Optional: Set subfolder for organization
SaveManager:SetSubFolder("profiles")

-- Optional: Ignore theme-related settings from saves
SaveManager:IgnoreThemeSettings()

-- Optional: Set loading order for dependency management
SaveManager:SetLoadingOrder(true, { "Toggle", "Slider", "Dropdown", "Input", "ColorPicker", "KeyPicker" })
```

#### Key Properties

| Property | Type | Default | Description |
|---|---|---|---|
| `SaveManager.Folder` | string | `"AstralSettings"` | Root folder for settings |
| `SaveManager.SubFolder` | string | `""` | Subfolder for organization |
| `SaveManager.Library` | Library | `nil` | Reference to the Astral library |
| `SaveManager.UseLoadingOrder` | boolean | `false` | Enable custom loading order |
| `SaveManager.LoadingOrder` | table | `{}` | Custom loading order table |
| `SaveManager.Ignore` | table | `{}` | Indexes to ignore during save/load |

#### Core Methods

```lua
-- Save current configuration
SaveManager:Save(name: string): (success: boolean, error: string?)

-- Load a saved configuration
SaveManager:Load(name: string): (success: boolean, error: string?)

-- Delete a saved configuration
SaveManager:Delete(name: string): (success: boolean, error: string?)

-- Refresh the list of available configurations
SaveManager:RefreshConfigList(): { string }

-- Set indexes to ignore during save/load
SaveManager:SetIgnoreIndexes(list: { string })

-- Ignore theme-related settings automatically
SaveManager:IgnoreThemeSettings()
```

#### Autoload Methods

```lua
-- Get the current autoload configuration name
SaveManager:GetAutoloadConfig(): string

-- Load the autoload configuration automatically
SaveManager:LoadAutoloadConfig()

-- Set a configuration to autoload on script start
SaveManager:SaveAutoloadConfig(name: string): (success: boolean, error: string?)

-- Clear the autoload configuration
SaveManager:DeleteAutoLoadConfig(): (success: boolean, error: string?)
```

#### GUI Integration

```lua
-- Automatically build a configuration section in a tab
SaveManager:BuildConfigSection(tab: Tab)
```

This creates a full UI section with:
- Input field for config names
- Buttons to create, load, overwrite, and delete configs
- Dropdown to select from existing configs
- Autoload management (set/reset autoload)
- Automatic config list refreshing

#### Supported Element Types

SaveManager automatically handles the following element types:
- **Toggle**: Saves boolean state
- **Slider**: Saves numeric value
- **Dropdown**: Saves selected value (supports multi-select)
- **ColorPicker**: Saves color hex and transparency
- **KeyPicker**: Saves key, mode, and modifiers
- **Input**: Saves text content

#### Example Usage

```lua
-- Basic setup
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/inCythe/Astral/refs/heads/main/addons/SaveManager.lua"))()
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()

-- Add configuration UI to a tab
local Tab = Window:AddTab({ Name = "Settings" })
SaveManager:BuildConfigSection(Tab)

-- Manual save/load
SaveManager:Save("MyConfig")
SaveManager:Load("MyConfig")

-- Autoload setup
SaveManager:SaveAutoloadConfig("MyConfig")
SaveManager:LoadAutoloadConfig() -- Call on script start
```

---

### 16.2 ThemeManager

ThemeManager provides comprehensive theme management with 18 built-in themes and support for custom theme creation, saving, and loading.

#### Setup

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

#### Built-in Themes

ThemeManager includes 18 pre-configured themes:

| Theme Name | Style |
|---|---|
| **Default** | Standard dark blue accent |
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

#### Key Properties

| Property | Type | Default | Description |
|---|---|---|---|
| `ThemeManager.Folder` | string | `"AstralSettings"` | Root folder for themes |
| `ThemeManager.Library` | Library | `nil` | Reference to the Astral library |
| `ThemeManager.AppliedToTab` | boolean | `false` | Whether theme manager is applied to a tab |
| `ThemeManager.BuiltInThemes` | table | — | Table of built-in themes |
| `ThemeManager.DefaultTheme` | string | `"Default"` | Default theme name |

#### Core Methods

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

#### GUI Integration

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

#### Theme Fields

Themes control the following color fields:
- **FontColor**: Text color
- **MainColor**: Primary UI element color
- **AccentColor**: Interactive element accent color
- **BackgroundColor**: Background color
- **OutlineColor**: Border/outline color
- **FontFace**: Font family

#### Example Usage

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

#### Integration with SaveManager

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

## 17. Dialogs

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
Dialog:Dismiss()                                       -- Close and destroy the dialog
Dialog:AddFooterButton(ButtonIdx, ButtonInfo)           -- Add or replace a footer button
Dialog:RemoveFooterButton(ButtonIdx)
Dialog:SetButtonDisabled(ButtonIdx, Disabled: boolean)
Dialog:SetButtonOrder(ButtonIdx, Order: number)
```

Registered in `Library.Dialogues[Idx]`. `Library.ActiveDialog` points to the most recently opened dialog while it's visible.

---

## 18. Loading Screens

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

## 19. Advanced Utilities

Lower-level building blocks used internally by the library, exposed for advanced/custom UI work.

### 19.1 Tooltips

Manually attach a hover tooltip to any `GuiObject`. (Most elements already expose this via their `Tooltip`/`DisabledTooltip` fields — use `AddTooltip` directly only when building custom UI.)

```lua
local Tooltip = Library:AddTooltip("Shown normally", "Shown while disabled", SomeGuiObject)

Tooltip.Disabled = true   -- Switch to showing the disabled text
Tooltip:Destroy()         -- Disconnect and remove the tooltip
```

### 19.2 Context Menus

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
```

Only one context menu can be open at a time globally — opening a new one closes whichever was previously open.