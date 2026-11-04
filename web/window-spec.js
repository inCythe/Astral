// ============================================================================
// Astral web preview — window specification
// ============================================================================
//
// This file is the browser-side equivalent of Example.lua: the same window, the
// same tab sections, tabs, sections and elements, described as plain data
// instead of Lua calls. astral.js renders it; nothing here touches the DOM.
//
// Keys intentionally mirror the Lua API (Name / Text / Default / Min / Max /
// Rounding / Prefix / Suffix / Values / Multi / Searchable / Risky / Disabled)
// so a change in Example.lua can be copied across with the same vocabulary.
//
// Section `Side` follows the Lua convention:
//   1    -> left column of a two-column row
//   2    -> right column of a two-column row
//   nil  -> full width (no column splitting)
// Consecutive Side sections are grouped into one row, exactly like
// `Tab:AddSection` / `AddLeftSection` / `AddRightSection`.
// ============================================================================

window.ASTRAL_SPEC = {
    // Library:CreateWindow({...})
    Title: "Astral UI — Reference",
    Footer: "Quick Reference",
    Size: { X: 940, Y: 620 },
    TitleSize: 15,
    SidebarWidth: 210,
    CornerRadius: 6,
    SearchPlaceholder: "Search",

    // Default Library.Scheme (dark). GetBetterColor / outlines are derived
    // from these at runtime, the same way the library derives them.
    Theme: {
        BackgroundColor: [13, 13, 16],
        MainColor: [21, 21, 25],
        AccentColor: [66, 135, 245],
        OutlineColor: [36, 36, 42],
        FontColor: [255, 255, 255],
        RedColor: [255, 64, 64],
        DarkColor: [0, 0, 0],
    },

    TabSections: [
        {
            Name: "Elements",
            Open: true,
            Tabs: [
                {
                    Name: "Form Controls",
                    Icon: "sliders-horizontal",
                    Description: "Toggles, sliders, dropdowns, inputs",
                    Sections: [
                        {
                            Name: "Toggle — every method",
                            IconName: "toggle-left",
                            Side: 1,
                            Elements: [
                                { Type: "Toggle", Id: "BasicToggle", Text: "Basic Toggle", Default: false },
                                {
                                    Type: "Toggle",
                                    Text: "Risky Toggle",
                                    Default: false,
                                    Risky: true,
                                    Tooltip: "Risky = true colors the label red",
                                },
                                {
                                    Type: "Toggle",
                                    Text: "Disabled Toggle",
                                    Default: true,
                                    Disabled: true,
                                    Tooltip: "Disabled = true at creation",
                                },
                                { Type: "Button", Text: "SetValue (Basic Toggle)" },
                                { Type: "Button", Text: "SetText (Basic Toggle)" },
                                { Type: "Button", Text: "SetDisabled (Disabled Toggle)" },
                            ],
                        },
                        {
                            Name: "Checkbox variant",
                            IconName: "square-check",
                            Side: 2,
                            Elements: [
                                { Type: "Checkbox", Text: "Checkbox Style", Default: false },
                                { Type: "Checkbox", Text: "Risky Checkbox", Default: false, Risky: true },
                                {
                                    Type: "Toggle",
                                    Text: "Force ALL toggles to render as checkboxes",
                                    Default: false,
                                    Tooltip: "Library:SetForceCheckbox — live-updates every toggle",
                                },
                            ],
                        },
                        {
                            Name: "Slider — every method",
                            IconName: "sliders-horizontal",
                            Side: 1,
                            Elements: [
                                {
                                    Type: "Slider",
                                    Text: "Speed",
                                    Default: 16,
                                    Min: 0,
                                    Max: 100,
                                    Rounding: 0,
                                    Suffix: " studs/s",
                                },
                                {
                                    Type: "Slider",
                                    Text: "Editable (Value box)",
                                    Default: 50,
                                    Min: 0,
                                    Max: 100,
                                    Editable: true,
                                    EditableStyle: "ValueBox",
                                },
                                { Type: "Slider", Text: "Compact", Default: 35, Min: 0, Max: 100, Compact: true },
                                { Type: "Button", Text: "SetMin (10)" },
                                { Type: "Button", Text: "SetMax (200)" },
                            ],
                        },
                        {
                            Name: "Dropdown — every method",
                            IconName: "list-checks",
                            Side: 2,
                            Elements: [
                                {
                                    Type: "Dropdown",
                                    Text: "Weapon",
                                    Default: "Sword",
                                    Values: ["Sword", "Bow", "Staff", "Dagger", "None"],
                                },
                                {
                                    Type: "Dropdown",
                                    Text: "Multi select",
                                    Multi: true,
                                    Default: { "Speed": true, "Jump": true },
                                    Values: ["Speed", "Jump", "Fly", "Noclip", "Infinite Jump"],
                                },
                                {
                                    Type: "Dropdown",
                                    Text: "Searchable",
                                    Searchable: true,
                                    Default: "Ambush",
                                    Values: [
                                        "Ambush", "Rush", "Eyes", "Halt", "Screech", "Figure",
                                        "Seek", "Glitch", "Hide", "Timothy", "Jack", "Window",
                                    ],
                                },
                            ],
                        },
                        {
                            Name: "Input — every method",
                            IconName: "text",
                            Side: 1,
                            Elements: [
                                { Type: "Input", Text: "Username", Placeholder: "Type a name…" },
                                { Type: "Input", Text: "Numeric", Placeholder: "0" },
                            ],
                        },
                        {
                            Name: "Key picker & color",
                            IconName: "keyboard",
                            Side: 2,
                            Elements: [
                                { Type: "KeyPicker", Text: "Toggle menu", Default: "RightControl" },
                                { Type: "KeyPicker", Text: "Aim assist", Default: "E" },
                                { Type: "KeyPicker", Text: "Panic", Default: "" },
                                { Type: "ColorPicker", Text: "Accent swatch", Default: "#4287f5" },
                                { Type: "ColorPicker", Text: "Risky swatch", Default: "#ff4040" },
                            ],
                        },
                    ],
                },
                {
                    Name: "Display",
                    Icon: "type",
                    Description: "Labels, rich text, progress bars, media",
                    Sections: [
                        {
                            Name: "Labels",
                            IconName: "text",
                            Side: 1,
                            Elements: [
                                { Type: "Label", Text: "Plain label — 14 px, single line" },
                                {
                                    Type: "Label",
                                    Text: "Wrapped label. DoesWrap = true lets the text flow onto as many lines as it needs, and the section grows to fit it.",
                                    DoesWrap: true,
                                },
                                {
                                    Type: "Label",
                                    Text: 'Rich text: <b>bold</b>, <i>italic</i>, and <font color="#4287f5">accent</font> inline.',
                                    RichText: true,
                                },
                            ],
                        },
                        {
                            Name: "Dividers",
                            IconName: "minus",
                            Side: 2,
                            Elements: [
                                { Type: "Label", Text: "Above the divider" },
                                { Type: "Divider" },
                                { Type: "Label", Text: "Below the divider" },
                                { Type: "Divider", Text: "Section break" },
                                { Type: "Label", Text: "Text inside the divider is optional." },
                            ],
                        },
                    ],
                },
                {
                    Name: "Actions",
                    Icon: "mouse-pointer-2",
                    Description: "Buttons, key pickers, color pickers",
                    Sections: [
                        {
                            Name: "Buttons",
                            IconName: "mouse-pointer-click",
                            Side: 1,
                            Elements: [
                                { Type: "Button", Text: "Primary action" },
                                { Type: "Button", Text: "Risky action", Risky: true },
                                { Type: "Button", Text: "Disabled action", Disabled: true },
                                { Type: "Button", Text: "Launch", Icon: "zap" },
                                { Type: "Button", Text: "Copy config", Icon: "copy" },
                            ],
                        },
                        {
                            Name: "Colors",
                            IconName: "palette",
                            Side: 2,
                            Elements: [
                                { Type: "ColorPicker", Text: "Accent", Default: "#4287f5" },
                                { Type: "ColorPicker", Text: "Background", Default: "#0d0d10" },
                                { Type: "ColorPicker", Text: "Risky", Default: "#ff4040" },
                                { Type: "Label", Text: "Click a swatch to pick a colour." },
                            ],
                        },
                    ],
                },
            ],
        },
        {
            Name: "Layout",
            Open: true,
            Tabs: [
                {
                    Name: "Sections",
                    Icon: "columns-2",
                    Description: "Full-width vs. two-column layout",
                    Sections: [
                        {
                            Name: "Full width section",
                            IconName: "columns-2",
                            Elements: [
                                { Type: "Label", Text: "A section with no Side spans the full content width." },
                                { Type: "Toggle", Text: "Full-width toggle", Default: true },
                            ],
                        },
                        {
                            Name: "Left column",
                            IconName: "columns-2",
                            Side: 1,
                            Elements: [
                                { Type: "Label", Text: "Side = 1" },
                                { Type: "Toggle", Text: "Left toggle", Default: true },
                                { Type: "Slider", Text: "Left slider", Default: 40, Min: 0, Max: 100 },
                            ],
                        },
                        {
                            Name: "Right column",
                            IconName: "columns-2",
                            Side: 2,
                            Elements: [
                                { Type: "Label", Text: "Side = 2" },
                                { Type: "Toggle", Text: "Right toggle", Default: false },
                                { Type: "Slider", Text: "Right slider", Default: 70, Min: 0, Max: 100 },
                            ],
                        },
                    ],
                },
                {
                    Name: "Nested & Groups",
                    Icon: "git-branch",
                    Description: "Sub-sections, section groups, conditionals",
                    Sections: [
                        {
                            Name: "Sub-Sections",
                            IconName: "git-branch",
                            Side: 1,
                            Elements: [
                                { Type: "Label", Text: "Sub-sections nest inside a parent section." },
                                { Type: "Toggle", Text: "Nested toggle", Default: true },
                                { Type: "Input", Text: "Nested input", Placeholder: "value" },
                            ],
                        },
                        {
                            Name: "Conditional group",
                            IconName: "git-branch",
                            Side: 2,
                            Elements: [
                                { Type: "Label", Text: "Elements appear and disappear with a condition." },
                                { Type: "Dropdown", Text: "Mode", Default: "Off", Values: ["Off", "On", "Auto"] },
                                { Type: "Button", Text: "Toggle visibility", Icon: "eye" },
                            ],
                        },
                    ],
                },
            ],
        },
        {
            Name: "Advanced",
            Open: false,
            Tabs: [
                {
                    Name: "Dialogs",
                    Icon: "message-square",
                    Description: "Modal popups and confirmations",
                    Sections: [
                        {
                            Name: "Modal dialog",
                            IconName: "message-square",
                            Elements: [
                                { Type: "Label", Text: "Library:AddDialog — modal popups, confirmations, prompts." },
                                { Type: "Button", Text: "Open dialog" },
                            ],
                        },
                    ],
                },
                {
                    Name: "Overlays",
                    Icon: "picture-in-picture-2",
                    Description: "Draggable overlays, context menus, and the overlay manager",
                    Sections: [
                        {
                            Name: "Overlay manager",
                            IconName: "layers",
                            Elements: [
                                { Type: "Label", Text: "Draggable overlays and right-click context menus." },
                                { Type: "Button", Text: "Spawn overlay", Icon: "plus" },
                            ],
                        },
                    ],
                },
            ],
        },
        {
            Name: "Settings",
            Open: false,
            Tabs: [
                {
                    Name: "Settings",
                    Icon: "settings",
                    Description: "UI scale, theme, and saved configs",
                    Sections: [
                        {
                            Name: "Display",
                            IconName: "sliders-horizontal",
                            Side: 1,
                            Elements: [
                                {
                                    Type: "Slider",
                                    Id: "UIScale",
                                    Text: "UI Scale",
                                    Default: 5,
                                    Min: 1,
                                    Max: 10,
                                    Rounding: 1,
                                    Editable: true,
                                    EditableStyle: "ValueBox",
                                },
                                { Type: "Toggle", Id: "AutoScale", Text: "Automatic sizing", Default: true },
                                { Type: "Button", Id: "ResetScale", Text: "Return to automatic sizing", Icon: "rotate-ccw" },
                            ],
                        },
                        {
                            Name: "Theme",
                            IconName: "palette",
                            Side: 2,
                            Elements: [
                                { Type: "Dropdown", Text: "Theme", Default: "Dark", Values: ["Dark", "Light", "Midnight", "Rose"] },
                                { Type: "ColorPicker", Text: "Accent color", Default: "#4287f5" },
                                { Type: "Toggle", Text: "Rounded dropdowns", Default: false },
                            ],
                        },
                        {
                            Name: "Configs",
                            IconName: "save",
                            Side: 1,
                            Elements: [
                                { Type: "Input", Text: "Config name", Placeholder: "my-config" },
                                { Type: "Button", Text: "Save config", Icon: "save" },
                                { Type: "Button", Text: "Load config", Icon: "copy" },
                                { Type: "Button", Text: "Delete config", Icon: "trash-2", Risky: true },
                            ],
                        },
                        {
                            Name: "About",
                            IconName: "circle-dot",
                            Side: 2,
                            Elements: [
                                { Type: "Label", Text: "Astral web preview — no Roblox, no Studio." },
                                { Type: "Divider" },
                                { Type: "Label", Text: "Rendered from web/window-spec.js." },
                                { Type: "Label", Text: "Metrics taken from Astral.lua." },
                            ],
                        },
                    ],
                },
            ],
        },
    ],
};
