--============================================================================
-- ASTRAL UI — QUICK REFERENCE EXAMPLE
--============================================================================

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/inCythe/Astral/refs/heads/main/Astral.lua"))()

--============================================================================
-- WINDOW
--============================================================================
-- Library:CreateWindow(Info) -> Window
--   Title, Icon, Footer      Header text/icon and footer text
--   Size, Center             UDim2 size, whether to center on screen
--   Resizable                Lets the user drag-resize the window
--   ToggleKeybind             Enum.KeyCode that shows/hides the window
--   NotifySide                "Left" | "Right" — which side notifications slide in from
--   DPIScale                  1-10 UI scale, 5 = 100% (see the Display section below)
--   SidebarWidth, EnableSidebarResize, SidebarCompacted
--   SingleInstance            Destroys any previous Astral window before creating this one
--============================================================================
local Window = Library:CreateWindow({
    Title            = "Astral UI — Reference",
    Icon             = "AstralIcon",
    Footer           = "Quick Reference v2.0",
    Size             = UDim2.fromOffset(940, 620),
    Center           = true,
    Resizable        = true,
    ToggleKeybind    = Enum.KeyCode.RightControl,
    NotifySide       = "Right",
    DPIScale         = 5,
    TitleSize        = 15,
    SidebarWidth     = 210,
    EnableSidebarResize = true,
    SidebarCompacted = false,
    SingleInstance   = true,

    -- AutoShow = false is required for SaveManager:Init(Window) (see the
    -- bottom of this script) to actually prevent the "flash of default
    -- values" -- if the window shows itself immediately, it's already
    -- visible before the script even reaches the SaveManager:Init line,
    -- so every Toggle/Slider/etc. below briefly renders its Default before
    -- snapping to the saved config value. Window:Toggle(true) is called
    -- manually once loading is fully done, further down.
    AutoShow         = false,
})

--============================================================================
-- TAB SECTIONS  (Window:AddTabSection)
--   Name, Open   Sidebar group header text, and whether it starts expanded
--============================================================================
local ElementsSection = Window:AddTabSection({ Name = "Elements",  Open = true })
local LayoutSection   = Window:AddTabSection({ Name = "Layout",    Open = true })
local AdvancedSection = Window:AddTabSection({ Name = "Advanced",  Open = false })
local SettingsSection = Window:AddTabSection({ Name = "Settings",  Open = false })

--============================================================================
-- TABS  (TabSection:AddTab)
--   Name, Icon, Description   Sidebar label, Lucide icon, and the one-line
--                              blurb shown at the top of the window when the
--                              tab is active.
--============================================================================
local FormTab      = ElementsSection:AddTab({ Name = "Form Controls", Icon = "sliders-horizontal", Description = "Toggles, sliders, dropdowns, inputs" })
local DisplayTab    = ElementsSection:AddTab({ Name = "Display",       Icon = "type",               Description = "Labels, rich text, progress bars, media" })
local ActionsTab    = ElementsSection:AddTab({ Name = "Actions",       Icon = "mouse-pointer-2",     Description = "Buttons, key pickers, color pickers" })

local LayoutsTab    = LayoutSection:AddTab({ Name = "Sections",       Icon = "columns-2",  Description = "Full-width vs. two-column layout" })
local NestedTab     = LayoutSection:AddTab({ Name = "Nested & Groups",Icon = "git-branch", Description = "Sub-sections, section groups, conditionals" })

local DialogsTab    = AdvancedSection:AddTab({ Name = "Dialogs",   Icon = "message-square",      Description = "Modal popups and confirmations" })
local OverlaysTab   = AdvancedSection:AddTab({ Name = "Overlays",  Icon = "picture-in-picture-2", Description = "Draggable overlays, context menus, and the overlay manager" })

local SettingsTab   = SettingsSection:AddTab({ Name = "Settings", Icon = "settings", Description = "UI scale, theme, and saved configs" })

--============================================================================
-- FORM CONTROLS TAB — Toggle, Checkbox, Slider, Dropdown, Input
--============================================================================
-- Section:AddToggle(Idx, Info) -> Toggle
--   Text, Default, Callback, Changed (alias of Callback), Risky, Disabled,
--   Visible, Tooltip, DisabledTooltip
-- Methods: SetValue, SetText, SetDisabled, SetVisible, OnChanged
-- Addons (attach after creation): Toggle:AddKeyPicker / Toggle:AddColorPicker
local ToggleSection = FormTab:AddLeftSection("Toggle — every method")

local BasicToggle = ToggleSection:AddToggle("BasicToggle", {
    Text = "Basic Toggle",
    Default = false,
    Callback = function(Value)
        Library:Notify({ Title = "Toggle", Description = Value and "ON" or "OFF", Time = 1.5 })
    end,
})
-- OnChanged: attach an ADDITIONAL listener alongside Callback (both fire)
BasicToggle:OnChanged(function(Value)
    print("[OnChanged] BasicToggle ->", Value)
end)

-- Risky = true, combined with a Tooltip
ToggleSection:AddToggle("RiskyToggle", {
    Text = "Risky Toggle",
    Default = false,
    Risky = true,
    Tooltip = "Risky = true colors the label red",
})

-- Disabled = true at creation, with a DisabledTooltip explaining why
ToggleSection:AddToggle("DisabledToggle", {
    Text = "Disabled Toggle",
    Default = true,
    Disabled = true,
    DisabledTooltip = "Enabled via SetDisabled(false) by the button below",
})

ToggleSection:AddButton({
    Text = "SetValue (Basic Toggle)",
    Func = function()
        BasicToggle:SetValue(not BasicToggle.Value)
    end,
})
ToggleSection:AddButton({
    Text = "SetText (Basic Toggle)",
    Func = function()
        BasicToggle:SetText(BasicToggle.Value and "Now ON" or "Now OFF")
    end,
})
ToggleSection:AddButton({
    Text = "SetDisabled (Disabled Toggle)",
    Func = function()
        local T = Library.Toggles.DisabledToggle
        T:SetDisabled(not T.Disabled)
    end,
})
ToggleSection:AddButton({
    Text = "SetVisible (Basic Toggle)",
    Func = function()
        BasicToggle:SetVisible(not BasicToggle.Visible)
    end,
})

-- Section:AddCheckbox(Idx, Info) -> identical Info/API to AddToggle,
-- just rendered as a square checkbox instead of a pill switch.
-- Library:SetForceCheckbox(true) makes every AddToggle-created toggle
-- render as a checkbox -- including ones already on screen, updated live.
-- (Plain `Library.ForceCheckbox = true` assignment does NOT do this -- it's
-- only read once at AddToggle-call-time, so it silently no-ops on anything
-- already created. Always go through SetForceCheckbox.)
local CheckboxSection = FormTab:AddRightSection("Checkbox variant")

CheckboxSection:AddCheckbox("BasicCheckbox", {
    Text = "Checkbox Style",
    Default = false,
    Callback = function(Value) print("Checkbox:", Value) end,
})
CheckboxSection:AddCheckbox("RiskyCheckbox", {
    Text = "Risky Checkbox",
    Default = false,
    Risky = true,
})
CheckboxSection:AddToggle("ForceCheckboxGlobal", {
    Text = "Force ALL toggles to render as checkboxes",
    Default = false,
    Tooltip = "Calls Library:SetForceCheckbox -- live-updates every AddToggle toggle immediately",
    Callback = function(Value)
        Library:SetForceCheckbox(Value)
    end,
})

-- Section:AddSlider(Idx, Info) -> Slider
--   Text, Default, Min, Max, Rounding, Prefix, Suffix
--   Compact, HideMax, Editable, EditableStyle ("Pencil" | "ValueBox")
--   FormatDisplayValue(Slider, Value) -> string
-- Methods: SetValue, SetMin, SetMax, SetText, SetPrefix, SetSuffix,
--          SetDisabled, SetVisible, OnChanged
local SliderSection = FormTab:AddLeftSection("Slider — every method")

local SpeedSlider = SliderSection:AddSlider("SpeedSlider", {
    Text = "Speed",
    Default = 16,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Suffix = " studs/s",
})
SpeedSlider:OnChanged(function(Value)
    print("[OnChanged] SpeedSlider ->", Value)
end)

SliderSection:AddButton({
    Text = "SetMin (10)",
    Func = function()
        SpeedSlider:SetMin(10)
    end,
})
SliderSection:AddButton({
    Text = "SetMax (200)",
    Func = function()
        SpeedSlider:SetMax(200)
    end,
})
SliderSection:AddButton({
    Text = "SetValue (120)",
    Func = function()
        SpeedSlider:SetValue(120)
    end,
})
SliderSection:AddButton({
    Text = "SetPrefix (~)",
    Func = function()
        SpeedSlider:SetPrefix("~")
    end,
})
SliderSection:AddButton({
    Text = "SetSuffix (pts)",
    Func = function()
        SpeedSlider:SetSuffix(" pts")
    end,
})
SliderSection:AddButton({
    Text = "SetText (Rescaled Slider)",
    Func = function()
        SpeedSlider:SetText("Rescaled Slider")
    end,
})
SliderSection:AddButton({
    Text = "SetDisabled toggle",
    Func = function()
        SpeedSlider:SetDisabled(not SpeedSlider.Disabled)
    end,
})

-- Combination: Editable + EditableStyle "Pencil" (icon reveals a value box)
SliderSection:AddSlider("PencilSlider", {
    Text = "Editable (Pencil style)",
    Default = 50,
    Min = 0,
    Max = 100,
    Editable = true,
    EditableStyle = "Pencil",
})

-- Combination: Editable + EditableStyle "ValueBox" (always-visible box)
SliderSection:AddSlider("ValueBoxSlider", {
    Text = "Editable (ValueBox style)",
    Default = 25,
    Min = 0,
    Max = 100,
    Editable = true,
    EditableStyle = "ValueBox",
})

-- Combination: Compact + HideMax (single-row, value-only display)
SliderSection:AddSlider("CompactSlider", {
    Text = "Compact Slider",
    Default = 40,
    Min = 0,
    Max = 100,
    Compact = true,
    HideMax = true,
})

-- Combination: Rounding for decimals + FormatDisplayValue custom text
SliderSection:AddSlider("DecimalSlider", {
    Text = "Decimal Slider (2 places)",
    Default = 0.5,
    Min = 0,
    Max = 1,
    Rounding = 2,
})
SliderSection:AddSlider("CustomFormatSlider", {
    Text = "Custom Format",
    Default = 50,
    Min = 0,
    Max = 100,
    FormatDisplayValue = function(Slider, Value)
        return string.format("Lvl %d / %d", Value, Slider.Max)
    end,
})

-- Section:AddDropdown(Idx, Info) -> Dropdown
--   Text, Values, DisabledValues, ValueImages, Default, Multi, AllowNull,
--   Searchable, MaxVisibleDropdownItems, FormatDisplayValue, FormatListValue,
--   SpecialType ("Player"|"Team"), ExcludeLocalPlayer, EnablePlayerImages
-- Methods: SetValue, SetSelectedValue, DeselectValue, ClearSelectedValues,
--          SetValues, AddValues, SetDisabledValues, AddDisabledValues,
--          SetValueImages, AddValueImages, SetText, SetDisabled, SetVisible,
--          OnChanged, GetActiveValues
local DropdownSection = FormTab:AddRightSection("Dropdown — single-select")

-- Basic single-select
local ModeDropdown = DropdownSection:AddDropdown("ModeDropdown", {
    Text = "Select Mode",
    Values = { "Option A", "Option B", "Option C" },
    Default = "Option A",
    Callback = function(Value) print("[Callback] ModeDropdown ->", Value) end,
})
ModeDropdown:OnChanged(function(Value)
    print("[OnChanged] ModeDropdown ->", Value)
end)

-- Combination: AllowNull (can deselect the last item) + DisabledValues
DropdownSection:AddDropdown("NullableDropdown", {
    Text = "Nullable + Disabled Value",
    Values = { "Enabled", "Disabled Choice" },
    Default = nil,
    AllowNull = true,
    DisabledValues = { "Disabled Choice" },
})

-- Combination: Searchable single-select (filter box, no All/Clear buttons)
DropdownSection:AddDropdown("SearchableSingle", {
    Text = "Search a Country",
    Values = { "United States", "United Kingdom", "Canada", "Australia", "Germany", "France", "Japan" },
    Default = "United States",
    Searchable = true,
})

DropdownSection:AddButton({
    Text = "SetValue (Option B)",
    Func = function()
        ModeDropdown:SetValue("Option B")
    end,
})
DropdownSection:AddButton({
    Text = "SetText (Renamed Dropdown)",
    Func = function()
        ModeDropdown:SetText("Renamed Dropdown")
    end,
})
DropdownSection:AddButton({
    Text = "SetDisabled(false)",
    Func = function()
        ModeDropdown:SetDisabled(false)
    end,
})
DropdownSection:AddButton({
    Text = "AddValues -> Option D, E",
    Func = function()
        ModeDropdown:AddValues({ "Option D", "Option E" })
    end,
})
DropdownSection:AddButton({
    Text = "SetValues -> replace list",
    Func = function()
        ModeDropdown:SetValues({ "Fresh A", "Fresh B", "Fresh C" })
    end,
})
DropdownSection:AddButton({
    Text = "AddDisabledValues -> Fresh B",
    Func = function()
        ModeDropdown:AddDisabledValues({ "Fresh B" })
    end,
})

-- Combination: Multi + Searchable (adds All/Clear buttons for bulk-select)
-- + MaxVisibleDropdownItems to cap the list height before it scrolls
local RolesDropdown = FormTab:AddLeftSection("Dropdown — multi-select"):AddDropdown("RolesDropdown", {
    Text = "Search & Select Roles",
    Values = { "Admin", "Moderator", "Editor", "Viewer", "Contributor", "Reviewer", "Support", "Analyst" },
    Default = { "Admin", "Analyst" },
    Multi = true,
    Searchable = true,
    MaxVisibleDropdownItems = 6,
    Callback = function(Value) print("[Callback] RolesDropdown ->", Value) end,
})

-- GetActiveValues, SetSelectedValue, DeselectValue, ClearSelectedValues
local MultiControls = FormTab:AddRightSection("Multi-select methods")
MultiControls:AddButton({
    Text = "GetActiveValues -> Notify",
    Func = function()
        local Active = RolesDropdown:GetActiveValues()
        local Names = {}
        for Key in pairs(Active) do table.insert(Names, Key) end
        Library:Notify({ Title = "Selected Roles", Description = #Names > 0 and table.concat(Names, ", ") or "(none)", Time = 2.5 })
    end,
})
MultiControls:AddButton({
    Text = "SetSelectedValue('Editor')",
    Func = function()
        RolesDropdown:SetSelectedValue("Editor")
    end,
})
MultiControls:AddButton({
    Text = "DeselectValue('Admin')",
    Func = function()
        RolesDropdown:DeselectValue("Admin")
    end,
})
MultiControls:AddButton({
    Text = "ClearSelectedValues()",
    Func = function()
        RolesDropdown:ClearSelectedValues()
    end,
})

-- Section:AddInput(Idx, Info) -> Input
--   Text (label above box), Default, Placeholder, Finished, Numeric,
--   ClearTextOnFocus, ClearTextOnBlur, AllowEmpty, EmptyReset,
--   Validate / VerifyValue (VerifyValue forces Finished = true)
-- Methods: SetValue, SetText, SetDisabled, SetVisible, OnChanged
local InputSection = FormTab:AddLeftSection("Input — every method")

local NameInput = InputSection:AddInput("NameInput", {
    Text = "Your Name",
    Placeholder = "Type here...",
    Default = "",
})
NameInput:OnChanged(function(Value)
    print("[OnChanged] NameInput ->", Value)
end)

InputSection:AddButton({
    Text = "SetValue (Astral)",
    Func = function()
        NameInput:SetValue("Astral")
    end,
})
InputSection:AddButton({
    Text = "SetText (Renamed Label)",
    Func = function()
        NameInput:SetText("Renamed Label")
    end,
})
InputSection:AddButton({
    Text = "SetDisabled(false)",
    Func = function()
        NameInput:SetDisabled(false)
    end,
})

-- Combination: Numeric + Finished (only fires on Enter, not every keystroke)
InputSection:AddInput("NumericInput", {
    Text = "Numeric Only (fires on Enter)",
    Placeholder = "123",
    Numeric = true,
    Finished = true,
    Callback = function(Value) print("[Callback] NumericInput ->", Value) end,
})

-- Combination: AllowEmpty = false + EmptyReset (falls back when cleared)
InputSection:AddInput("EmptyResetInput", {
    Text = "Falls Back When Empty",
    Placeholder = "Clear me and press Enter",
    Default = "DefaultValue",
    AllowEmpty = false,
    EmptyReset = "---",
})

-- Combination: Validate (reject bad text) — 3-20 alphanumeric chars
local ValidatedSection = FormTab:AddRightSection("Input — validation")
ValidatedSection:AddInput("ValidatedInput", {
    Text = "Username (3-20 chars)",
    Placeholder = "letters/numbers only",
    Default = "",
    Validate = function(Text)
        return #Text >= 3 and #Text <= 20 and Text:match("^%w+$")
    end,
})

-- Combination: Numeric + VerifyValue (auto-forces Finished = true)
ValidatedSection:AddInput("VerifiedInput", {
    Text = "Even Numbers Only",
    Placeholder = "Enter an even number",
    Default = "",
    Numeric = true,
    VerifyValue = function(Value)
        local Number = tonumber(Value)
        return Number ~= nil and Number % 2 == 0
    end,
})


--============================================================================
-- DISPLAY TAB — Divider, Label, rich text, ProgressBar, Image, Video, Viewport
--============================================================================
-- Section:AddDivider() / AddDivider("Text") / AddDivider({ Text, Margin, MarginTop, MarginBottom })
-- Returns Divider.Holder (root Frame) and Divider.Text
local DividerSection = DisplayTab:AddLeftSection("Divider")
DividerSection:AddLabel("Above the divider")
DividerSection:AddDivider("Labelled Divider")
DividerSection:AddLabel("Below the labelled divider")
DividerSection:AddDivider()
DividerSection:AddLabel("Below a plain (unlabelled) divider")
DividerSection:AddDivider({ Text = "Custom Margins", MarginTop = 8, MarginBottom = 8 })

-- Section:AddLabel(Text) or AddLabel({ Text, DoesWrap, Size, Visible })
-- Methods: SetText, SetVisible
-- Addons (non-wrapping labels only): Label:AddKeyPicker / Label:AddColorPicker
-- Rich text: <b>, <i>, <u>, <font color="rgb(r,g,b)">, <font face="...">
local LabelSection = DisplayTab:AddRightSection("Label — every method")

local CounterLabel = LabelSection:AddLabel("Counter: <font color=\"rgb(66,135,245)\">0</font>")
LabelSection:AddLabel({
    Text = "<b>Bold</b> · <i>Italic</i> · <u>Underline</u> · " ..
           "<font color=\"rgb(120,220,120)\">Colored</font> · " ..
           "<font face=\"RobotoMono\">Monospace</font>",
    DoesWrap = true,
    Size = 13,
})

local Count = 0
LabelSection:AddButton({
    Text = "SetText (increment counter)",
    Func = function()
        Count += 1
        CounterLabel:SetText(string.format("Counter: <font color=\"rgb(66,135,245)\">%d</font>", Count))
    end,
})
LabelSection:AddButton({
    Text = "SetVisible toggle",
    Func = function()
        CounterLabel:SetVisible(not CounterLabel.Visible)
    end,
})

-- Section:AddProgressBar(Idx, Info) -> ProgressBar (read-only; value only
-- changes via :SetValue -- cannot be dragged/edited by the user)
--   Text, Value, Min, Max, Rounding, Prefix, Suffix, Compact, HideMax
-- Methods: SetValue, SetMin, SetMax, SetText, SetPrefix, SetSuffix,
--          SetDisabled, SetVisible, OnChanged
local ProgressSection = DisplayTab:AddLeftSection("ProgressBar — every method")

local HealthBar = ProgressSection:AddProgressBar("HealthBar", {
    Text = "Health",
    Value = 100,
    Min = 0,
    Max = 100,
    Suffix = " HP",
})
HealthBar:OnChanged(function(Value)
    print("[OnChanged] HealthBar ->", Value)
end)

ProgressSection:AddButton({
    Text = "SetValue (-25 HP)",
    Func = function()
        HealthBar:SetValue(math.max(0, HealthBar.Value - 25))
    end,
})
ProgressSection:AddButton({
    Text = "SetMax (200)",
    Func = function()
        HealthBar:SetMax(200)
    end,
})
ProgressSection:AddButton({
    Text = "SetPrefix (Shielded:)",
    Func = function()
        HealthBar:SetPrefix("Shielded: ")
    end,
})
ProgressSection:AddButton({
    Text = "SetSuffix (HP)",
    Func = function()
        HealthBar:SetSuffix(" HP")
    end,
})
ProgressSection:AddButton({
    Text = "SetText (Health Rescaled)",
    Func = function()
        HealthBar:SetText("Health (Rescaled)")
    end,
})
ProgressSection:AddButton({
    Text = "SetDisabled toggle",
    Func = function()
        HealthBar:SetDisabled(not HealthBar.Disabled)
    end,
})

-- Combination: Compact + HideMax (single-row, value-only display)
ProgressSection:AddProgressBar("CompactBar", {
    Text = "Compact Progress",
    Value = 60,
    Min = 0,
    Max = 100,
    Compact = true,
    HideMax = true,
})

-- Section:AddImage(Idx, Info) -> Image
--   Image (asset id / url / Lucide icon name), Color, Transparency,
--   BackgroundTransparency, RectOffset, RectSize, ScaleType, Height
-- Methods: SetImage, SetColor, SetTransparency, SetRectOffset,
--          SetRectSize, SetScaleType, SetHeight, SetVisible
local ImageSection = DisplayTab:AddRightSection("Image — every method")

local DemoImage = ImageSection:AddImage("DemoImage", {
    Image = "sparkles",
    Height = 90,
    ScaleType = Enum.ScaleType.Fit,
})
ImageSection:AddButton({
    Text = "SetImage (star)",
    Func = function()
        DemoImage:SetImage("star")
        task.delay(1.5, function()
            DemoImage:SetImage("sparkles")
        end)
    end,
})
ImageSection:AddButton({
    Text = "SetColor (gold)",
    Func = function()
        DemoImage:SetColor(Color3.fromRGB(255, 200, 80))
        task.delay(1.5, function()
            DemoImage:SetColor(Color3.new(1, 1, 1))
        end)
    end,
})
ImageSection:AddButton({
    Text = "SetTransparency (0.15)",
    Func = function()
        DemoImage:SetTransparency(0.15)
        task.delay(1.5, function()
            DemoImage:SetTransparency(0)
        end)
    end,
})
ImageSection:AddButton({
    Text = "SetScaleType (Stretch)",
    Func = function()
        DemoImage:SetScaleType(Enum.ScaleType.Stretch)
        task.delay(1.5, function()
            DemoImage:SetScaleType(Enum.ScaleType.Fit)
        end)
    end,
})
ImageSection:AddButton({
    Text = "SetHeight (130)",
    Func = function()
        DemoImage:SetHeight(130)
        task.delay(1.5, function()
            DemoImage:SetHeight(90)
        end)
    end,
})
ImageSection:AddButton({
    Text = "SetVisible toggle",
    Func = function()
        DemoImage:SetVisible(not DemoImage.Visible)
    end,
})

-- Section:AddVideo(Idx, Info) -> Video (VideoFrame for Roblox video assets)
--   Video, Looped, Playing, Volume, Height, Visible
-- Methods: SetVideo, SetLooped, SetVolume, SetPlaying, Play, Pause, SetHeight, SetVisible
local VideoSection = DisplayTab:AddLeftSection("Video — every method")
VideoSection:AddLabel({
    Text = "Provide a real rbxassetid:// video asset to see playback; this demo just showcases the method calls.",
    DoesWrap = true,
})
local DemoVideo = VideoSection:AddVideo("DemoVideo", {
    Video = "rbxassetid://0",
    Looped = false,
    Playing = false,
    Volume = 0.5,
    Height = 100,
})
VideoSection:AddButton({
    Text = "Play() / Pause()",
    Func = function()
        if DemoVideo.Playing then
            DemoVideo:Pause()
        else
            DemoVideo:Play()
        end
    end,
})
VideoSection:AddButton({
    Text = "SetLooped(true)",
    Func = function()
        DemoVideo:SetLooped(true)
    end,
})
VideoSection:AddButton({
    Text = "SetVolume (1.0)",
    Func = function()
        DemoVideo:SetVolume(1)
    end,
})

-- Section:AddViewport(Idx, Info) -> Viewport (embeds a live 3D ViewportFrame)
--   Object (BasePart/Model), Camera, Clone, AutoFocus, Interactive, Height
-- Methods: SetObject, SetCamera, SetInteractive, SetHeight, SetVisible, Focus
local ViewportSection = DisplayTab:AddRightSection("3D Viewport — every method")

local DemoModel = Instance.new("Model")
local DemoPart = Instance.new("Part")
DemoPart.Size = Vector3.new(3, 3, 3)
DemoPart.Anchored = true
DemoPart.Color = Color3.fromRGB(66, 135, 245)
DemoPart.Parent = DemoModel

local DemoViewport = ViewportSection:AddViewport("DemoViewport", {
    Object = DemoModel,
    Height = 130,
    Interactive = true,
    AutoFocus = true,
})
ViewportSection:AddButton({
    Text = "SetObject (swap model) + Focus()",
    Func = function()
        local NewModel = Instance.new("Model")
        local NewPart = Instance.new("Part")
        NewPart.Shape = Enum.PartType.Ball
        NewPart.Size = Vector3.new(4, 4, 4)
        NewPart.Anchored = true
        NewPart.Color = Color3.fromRGB(245, 66, 135)
        NewPart.Parent = NewModel

        DemoViewport:SetObject(NewModel)
        DemoViewport:Focus()
    end,
})
ViewportSection:AddButton({
    Text = "SetInteractive toggle",
    Func = function()
        DemoViewport:SetInteractive(not DemoViewport.Interactive)
    end,
})
ViewportSection:AddButton({
    Text = "SetHeight(180)",
    Func = function()
        DemoViewport:SetHeight(180)
    end,
})

-- Section:AddUIPassthrough(Idx, Info) -> embeds any GuiBase2d you built
-- yourself directly inside a section, at a fixed height.
--   Instance (required), Height, Visible
-- Methods: SetInstance, SetHeight, SetVisible
local PassthroughSection = DisplayTab:AddLeftSection("UI Passthrough")
local CustomFrame = Instance.new("TextLabel")
CustomFrame.Size = UDim2.new(1, 0, 1, 0)
CustomFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 34)
CustomFrame.Text = "I'm a raw Instance()"
CustomFrame.TextColor3 = Color3.new(1, 1, 1)
CustomFrame.Font = Enum.Font.GothamMedium
CustomFrame.TextSize = 13
local Passthrough = PassthroughSection:AddUIPassthrough("CustomPass", {
    Instance = CustomFrame,
    Height = 36,
})
PassthroughSection:AddButton({
    Text = "SetHeight(60)",
    Func = function()
        Passthrough:SetHeight(60)
    end,
})
PassthroughSection:AddButton({
    Text = "SetVisible toggle",
    Func = function()
        Passthrough:SetVisible(not Passthrough.Visible)
    end,
})

--============================================================================
-- ACTIONS TAB — Button, sub-button, KeyPicker, ColorPicker
--============================================================================
-- Section:AddButton(Info) -> Button
--   Text, Func, DoubleClick, Risky, Disabled, Visible, Tooltip,
--   DisabledTooltip, Idx (optional, registers in Library.Buttons)
--   Shorthand: Section:AddButton("Label", function() end)
-- Methods: SetText, SetDisabled, SetVisible
-- Button:AddButton(Info) attaches a secondary sub-button to its right.
local ButtonSection = ActionsTab:AddLeftSection("Button — every method")

local MainButton = ButtonSection:AddButton({
    Text = "Click Me",
    Func = function()
        Library:Notify({ Title = "Clicked", Description = "Button fired.", Time = 2 })
    end,
})
-- Sub-button: a secondary action displayed inline to the right
MainButton:AddButton({
    Text = "Sub",
    Func = function()
        Library:Notify({ Title = "Sub-Button", Description = "Secondary action fired.", Time = 2 })
    end,
})

-- Shorthand form: AddButton("Label", function)
ButtonSection:AddButton("Shorthand Button", function()
    print("Shorthand button clicked")
end)

ButtonSection:AddButton({
    Text = "SetText (Renamed!)",
    Func = function()
        MainButton:SetText("Renamed!")
        task.delay(1, function()
            MainButton:SetText("Click Me")
        end)
    end,
})
ButtonSection:AddButton({
    Text = "SetDisabled toggle (Main Button)",
    Func = function()
        MainButton:SetDisabled(not MainButton.Disabled)
    end,
})
ButtonSection:AddButton({
    Text = "SetVisible toggle (Sub Button)",
    Func = function()
        local Sub = MainButton.SubButton
        if Sub then
            Sub:SetVisible(not Sub.Visible)
        end
    end,
})

-- Combination: DoubleClick + Risky (requires a confirming second click,
-- colored red as a visual warning for a destructive action)
ButtonSection:AddButton({
    Text = "Confirm to Delete",
    DoubleClick = true,
    Risky = true,
    Tooltip = "Click twice within 0.5s to confirm",
    Func = function()
        Library:Notify({ Title = "Deleted", Description = "Double-click confirmed.", Time = 2, Icon = "trash-2" })
    end,
})

-- Combination: Disabled + DisabledTooltip, re-enabled via SetDisabled
local DisabledDemo
DisabledDemo = ButtonSection:AddButton({
    Text = "Disable Myself",
    Tooltip = "Click to disable this button for 2 seconds",
    DisabledTooltip = "Currently disabled — wait a moment",
    Func = function()
        DisabledDemo:SetDisabled(true)
        DisabledDemo:SetText("Disabled...")
        task.delay(2, function()
            DisabledDemo:SetDisabled(false)
            DisabledDemo:SetText("Disable Myself")
        end)
    end,
})

-- KeyPicker attaches to a Toggle or Label:
--   Toggle:AddKeyPicker(Idx, Info) / Label:AddKeyPicker(Idx, Info)
--   Text, Default, DefaultModifiers, Mode ("Always"|"Toggle"|"Hold"|"Press"),
--   Modes, SyncToggleState, Blacklisted/Whitelisted (+Modifiers),
--   Callback(State), ChangedCallback(KeyCode, Modifiers), Clicked(State)
-- Methods: SetValue({Key,Mode,Modifiers}), GetState, SetText, OnChanged, OnClick
local KeySection = ActionsTab:AddRightSection("Key Picker — every mode")

local BoundToggle = KeySection:AddToggle("BoundToggle", {
    Text = "Keybound Toggle",
    Default = false,
})
-- SyncToggleState = true is required for Toggle/Hold modes to actually
-- flip the parent toggle's Value -- without it the key still fires
-- Callback but never calls Toggle:SetValue() under the hood.
local BoundKey = BoundToggle:AddKeyPicker("BoundToggleKey", {
    Text = "Toggle Keybind",
    Default = "F1",
    Mode = "Toggle",
    Modes = { "Toggle", "Hold", "Always" },
    SyncToggleState = true,
})
BoundKey:OnChanged(function(KeyCode, Modifiers)
    print("[OnChanged] BoundToggleKey ->", KeyCode, Modifiers)
end)

-- Mode = "Hold" on a mouse button, with SyncToggleState again
local HoldToggle = KeySection:AddToggle("HoldToggle", {
    Text = "Hold-to-Enable (MB2)",
    Default = false,
})
local HoldKey = HoldToggle:AddKeyPicker("HoldToggleKey", {
    Text = "Hold Keybind",
    Default = "MB2",
    Mode = "Hold",
    SyncToggleState = true,
})
HoldKey:OnChanged(function(KeyCode, Modifiers)
    print("[OnChanged] HoldToggleKey ->", KeyCode, Modifiers)
end)

-- Mode = "Press" with DefaultModifiers, attached to a Label (fires once
-- per press, doesn't hold a toggle state)
local PressLabel = KeySection:AddLabel("Modifier Combo (Ctrl+Shift, Press mode)")
PressLabel:AddKeyPicker("PressKey", {
    Text = "Ctrl+Shift Combo",
    Default = "F3",
    DefaultModifiers = { "LCtrl", "LShift" },
    Mode = "Press",
    Callback = function(State)
        print("[Callback] PressKey fired, state:", State)
    end,
})

KeySection:AddButton({
    Text = "GetState() -> Notify",
    Func = function()
        Library:Notify({ Title = "Toggle Keybind State", Description = tostring(BoundKey:GetState()), Time = 2 })
    end,
})
KeySection:AddButton({
    Text = "SetValue({Key='F5'})",
    Func = function()
        BoundKey:SetValue({ Key = "F5" })
    end,
})

-- ColorPicker attaches to a Toggle or Label:
--   Toggle:AddColorPicker(Idx, Info) / Label:AddColorPicker(Idx, Info)
--   Default (Color3), Transparency (0-1, adds an alpha slider), Title
-- Methods: SetValue(HSV table or Color3, Transparency?), SetValueRGB(Color3, Transparency?), OnChanged
local ColorSection = ActionsTab:AddLeftSection("Color Picker — every method")

-- NOTE: requires the Astral.lua fix where AddColorPicker/AddKeyPicker
-- return the picker object instead of `self` (the parent Label/Toggle).
-- Without that fix, AccentPicker below is actually ColorLabel, and
-- AccentPicker:OnChanged(...) throws "attempt to call missing method
-- 'OnChanged' of table".
local ColorLabel = ColorSection:AddLabel("Accent Color (no alpha)")
local AccentPicker = ColorLabel:AddColorPicker("AccentColor", {
    Default = Color3.fromRGB(66, 135, 245),
    Title = "Pick a Color",
})
AccentPicker:OnChanged(function(Color)
    print("[OnChanged] AccentColor ->", Color)
end)

-- Combination: attached to a Toggle instead of a Label, with Transparency
-- enabled (adds an alpha slider to the popup)
local GlowToggle = ColorSection:AddToggle("GlowToggle", {
    Text = "Glow Color (with alpha)",
    Default = true,
})
local GlowPicker = GlowToggle:AddColorPicker("GlowColor", {
    Default = Color3.fromRGB(120, 220, 120),
    Transparency = 0.25,
    Title = "Glow Color",
})

ColorSection:AddButton({
    Text = "SetValueRGB (set to red)",
    Func = function()
        AccentPicker:SetValueRGB(Color3.fromRGB(255, 80, 80))
    end,
})
ColorSection:AddButton({
    Text = "SetValue with HSV table",
    Func = function()
        AccentPicker:SetValue({ 0.6, 1, 1 }) -- {Hue, Sat, Vib}
    end,
})
ColorSection:AddButton({
    Text = "SetValueRGB + Transparency on Glow",
    Func = function()
        GlowPicker:SetValueRGB(Color3.fromRGB(255, 220, 80), 0.5)
    end,
})


--============================================================================
-- SECTIONS TAB — full-width vs. two-column layout
--
--   Tab:AddSection({ Side = 1|2|nil })     Side = 1 -> left column
--   Tab:AddLeftSection(Name, Icon)         Side = 2 -> right column
--   Tab:AddRightSection(Name, Icon)        Side omitted -> full-width row
--
-- Sections render in the exact order you call these, top to bottom. A
-- Side=1 and a Side=2 call sitting next to each other share one row; any
-- full-width call always starts a fresh row. Mix and match freely.
--============================================================================
LayoutsTab:AddSection({
    Name = "Full-Width Row",
    IconName = "maximize",
}):AddLabel({
    Text = "This section has no Side set, so it spans the whole tab width.",
    DoesWrap = true,
})

local Left = LayoutsTab:AddLeftSection("Left Column")
Left:AddToggle("LeftToggle", { Text = "Left-side Toggle", Default = true })

local Right = LayoutsTab:AddRightSection("Right Column")
Right:AddToggle("RightToggle", { Text = "Right-side Toggle", Default = false })

LayoutsTab:AddSection({
    Name = "Back to Full-Width",
    IconName = "maximize",
}):AddLabel("A plain AddSection call always starts a new full-width row, even after a two-column row.")

local LeftB = LayoutsTab:AddLeftSection("Left Again")
LeftB:AddSlider("LeftSlider", { Text = "Value", Default = 50, Min = 0, Max = 100 })

local RightB = LayoutsTab:AddRightSection("Right Again")
RightB:AddSlider("RightSlider", { Text = "Value", Default = 50, Min = 0, Max = 100 })

--============================================================================
-- NESTED & GROUPS TAB — AddSubSection, AddSectionGroup, ConditionalGroup
--============================================================================
-- Section:AddSubSection(Info | Name, Icon) -> nested section, same element
-- methods as a regular Section. DefaultOpen controls initial state; Side
-- lets sub-sections alternate full-width/two-column the same way top-
-- level sections do.
local Parent = NestedTab:AddSection("Sub-Sections")

local SubA = Parent:AddSubSection({ Name = "Nested (open)", IconName = "chevron-down", DefaultOpen = true })
SubA:AddToggle("SubToggleA", { Text = "Nested Toggle", Default = false })

local SubB = Parent:AddSubSection({ Name = "Nested (closed)", IconName = "chevron-right", DefaultOpen = false })
SubB:AddLabel("Click the header above to expand this.")

-- Tab:AddSectionGroup({ Side }) -> Group with Group:AddTab(Name, Icon) pages
-- IMPORTANT: this is called on the Tab itself (like AddSection), NOT on
-- a Section object -- a section box has no AddSectionGroup method.
-- Shorthand: Tab:AddLeftSectionGroup(Name) / Tab:AddRightSectionGroup(Name)
-- Each page behaves like a Section. The first page added is shown first;
-- clicking a tab at the top of the box switches pages.
local GroupBox = NestedTab:AddSectionGroup({ Name = "DemoGroup" })
local PageOne = GroupBox:AddTab("Page One", "list")
local PageTwo = GroupBox:AddTab("Page Two", "settings")
PageOne:AddLabel("Content for Page One.")
PageTwo:AddLabel("Content for Page Two.")

-- Section:AddConditionalGroup() -> shows/hides a block of elements based
-- on other elements' values via :SetupDependencies({ {Element, Value}, ... })
local CondParent = NestedTab:AddSection("Conditional Group")
local Driver = CondParent:AddToggle("ShowExtra", { Text = "Show Extra Options", Default = false })

local ExtraGroup = CondParent:AddConditionalGroup()
ExtraGroup:AddSlider("ExtraSlider", { Text = "Only visible when ShowExtra is ON", Default = 50, Min = 0, Max = 100 })
ExtraGroup:SetupDependencies({
    { Driver, true },
})

-- Sub-sections can also alternate into a two-column layout inside a
-- single parent section, the same way Tab:AddLeftSection/AddRightSection
-- do at the top level -- just pass Side = 1 (left) or Side = 2 (right)
-- in the Info table. Two consecutive Side sub-sections share a row;
-- a sub-section without Side goes back to full width on its own row.
local TwoColParent = NestedTab:AddSection("Two-Column Nested Sub-Sections")

local SubLeft = TwoColParent:AddSubSection({ Name = "Movement", IconName = "footprints", Side = 1 })
SubLeft:AddToggle("SubSpeedToggle", { Text = "Speed Boost", Default = false })
SubLeft:AddSlider("SubSpeedAmount", { Text = "Amount", Default = 20, Min = 0, Max = 100 })

local SubRight = TwoColParent:AddSubSection({ Name = "Combat", IconName = "swords", Side = 2 })
SubRight:AddToggle("SubAimToggle", { Text = "Aim Assist", Default = false })
SubRight:AddSlider("SubAimStrength", { Text = "Strength", Default = 50, Min = 0, Max = 100 })

-- Back to full width after a two-column row -- this alternation (full ->
-- two-column -> full -> two-column) is tracked automatically per parent
-- section, same as it is for top-level tabs.
local SubFull = TwoColParent:AddSubSection({ Name = "Notes", IconName = "sticky-note" })
SubFull:AddLabel({ Text = "Full-width sub-section after a two-column row.", DoesWrap = true })

-- SectionGroup pages (Tab:AddSectionGroup) can nest two-column
-- sub-sections too, since each page behaves exactly like a Section.
local NestedGroupBox = NestedTab:AddSectionGroup({ Name = "Group + Nested Columns" })
local GroupPage = NestedGroupBox:AddTab("Loadout", "package")
local GPLeft = GroupPage:AddSubSection({ Name = "Primary", Side = 1 })
GPLeft:AddDropdown("PrimaryWeapon", { Text = "Weapon", Values = { "Rifle", "SMG", "Shotgun" }, Default = "Rifle" })
local GPRight = GroupPage:AddSubSection({ Name = "Secondary", Side = 2 })
GPRight:AddDropdown("SecondaryWeapon", { Text = "Weapon", Values = { "Pistol", "Knife" }, Default = "Pistol" })

--============================================================================
-- DIALOGS TAB — Window:AddDialog
--============================================================================
-- Window:AddDialog(Idx, Info) -> Dialog. A modal popup with a title,
-- description, optional body elements (same AddXxx methods as a
-- Section), and footer buttons.
-- Methods: SetTitle, SetDescription, SetButtonsAlignment, Dismiss,
--          AddFooterButton, RemoveFooterButton, SetButtonDisabled, SetButtonOrder
local Section = DialogsTab:AddSection("Modal Dialog")

Section:AddButton({
    Text = "Open Confirm Dialog",
    Func = function()
        Window:AddDialog("ConfirmDialog", {
            Title = "Delete Config?",
            Description = "This action cannot be undone.",
            Icon = "trash-2",
            AutoDismiss = true,
            OutsideClickDismiss = true,
            FooterButtons = {
                Cancel = { Title = "Cancel", Variant = "Secondary", Order = 1 },
                Confirm = {
                    Title = "Delete",
                    Variant = "Destructive",
                    Order = 2,
                    Callback = function()
                        Library:Notify({ Title = "Deleted", Time = 2, Icon = "trash-2" })
                    end,
                },
            },
        })
    end,
})

Section:AddButton({
    Text = "Open Dialog with Body Elements",
    Func = function()
        local Dialog = Window:AddDialog("InputDialog", {
            Title = "Save Config",
            Description = "Give this config a name.",
            Icon = "save",
            FooterButtons = {
                Save = {
                    Title = "Save",
                    Variant = "Primary",
                    Order = 1,
                    Callback = function()
                        Library:Notify({ Title = "Saved", Time = 2 })
                    end,
                },
            },
        })
        Dialog:AddInput("ConfigName", { Text = "Config Name", Placeholder = "MyConfig" })
    end,
})

-- Buttons can start disabled and get re-enabled once some condition is
-- met (SetButtonDisabled), and WaitTime on a footer button shows a
-- countdown progress bar under it before it becomes clickable -- handy
-- for "hold on before you can confirm" style dialogs.
local Section2 = DialogsTab:AddSection("More Dialog Types")

Section2:AddButton({
    Text = "Open Validated-Input Dialog",
    Func = function()
        local Dialog = Window:AddDialog("ValidatedDialog", {
            Title = "Rename Config",
            Description = "Save is disabled until you type a name.",
            Icon = "pencil",
            AutoDismiss = false,
            FooterButtons = {
                Cancel = { Title = "Cancel", Variant = "Secondary", Order = 1, Callback = function(D) D:Dismiss() end },
                Save = {
                    Title = "Save",
                    Variant = "Primary",
                    Order = 2,
                    Callback = function(D)
                        Library:Notify({ Title = "Config Renamed", Time = 2 })
                        D:Dismiss()
                    end,
                },
            },
        })
        Dialog:SetButtonDisabled("Save", true)

        local NameInput = Dialog:AddInput("RenameInput", { Text = "New Name", Placeholder = "Type to enable Save..." })
        NameInput:OnChanged(function(Value)
            Dialog:SetButtonDisabled("Save", Value == "" or Value == nil)
        end)
    end,
})

Section2:AddButton({
    Text = "Open Timed-Confirm Dialog (WaitTime)",
    Func = function()
        Window:AddDialog("TimedDialog", {
            Title = "Reset All Settings?",
            Description = "The confirm button unlocks after a short delay so you can't misclick.",
            Icon = "alert-triangle",
            FooterButtons = {
                Cancel = { Title = "Cancel", Variant = "Secondary", Order = 1 },
                Confirm = {
                    Title = "Reset",
                    Variant = "Destructive",
                    Order = 2,
                    WaitTime = 3,
                    Callback = function()
                        Library:Notify({ Title = "Settings Reset", Time = 2, Icon = "rotate-ccw" })
                    end,
                },
            },
        })
    end,
})

Section2:AddButton({
    Text = "Open Info Dialog (no footer buttons)",
    Func = function()
        -- FooterButtons can be omitted entirely -- the divider/button row
        -- auto-hides and OutsideClickDismiss (default true) lets the user
        -- close it by clicking outside, like a plain toast-style modal.
        Window:AddDialog("InfoDialog", {
            Title = "Did You Know?",
            Description = "Click anywhere outside this dialog to close it -- no button needed.",
            Icon = "info",
        })
    end,
})

Section2:AddButton({
    Text = "Open Left-Aligned Buttons Dialog",
    Func = function()
        local Dialog = Window:AddDialog("AlignDialog", {
            Title = "Buttons Alignment",
            Description = "SetButtonsAlignment moves the footer row to Left/Center/Right.",
            ButtonsAlignment = "Left",
            FooterButtons = {
                Ok = { Title = "Got it", Variant = "Primary", Order = 1 },
            },
        })
        -- Alignment can also be changed after the fact:
        -- Dialog:SetButtonsAlignment("Center")
    end,
})

Section2:AddButton({
    Text = "Open Multi-Step Dialog",
    Func = function()
        local Dialog = Window:AddDialog("MultiStepDialog", {
            Title = "Step 1 of 2",
            Description = "Pick a name, then confirm on the next step.",
            Icon = "arrow-right",
            AutoDismiss = false,
            FooterButtons = {
                Cancel = { Title = "Cancel", Variant = "Secondary", Order = 1, Callback = function(D) D:Dismiss() end },
                Next = {
                    Title = "Next",
                    Variant = "Primary",
                    Order = 2,
                    Callback = function(D)
                        D:SetTitle("Step 2 of 2")
                        D:SetDescription("Confirm the change below.")
                        D:RemoveFooterButton("Next")
                        D:AddFooterButton("Confirm", {
                            Title = "Confirm",
                            Variant = "Primary",
                            Order = 2,
                            Callback = function(D2)
                                Library:Notify({ Title = "Multi-Step Dialog", Description = "Completed!", Time = 2 })
                                D2:Dismiss()
                            end,
                        })
                    end,
                },
            },
        })
    end,
})

Section2:AddButton({
    Text = "Open Loading-Style Dialog (WaitTime + Icon)",
    Func = function()
        Window:AddDialog("LoadingDialog", {
            Title = "Applying Changes",
            Description = "This closes itself once the wait finishes.",
            Icon = "loader",
            OutsideClickDismiss = false,
            FooterButtons = {
                Working = {
                    Title = "Please Wait...",
                    Variant = "Secondary",
                    Order = 1,
                    WaitTime = 2,
                    Callback = function(D)
                        Library:Notify({ Title = "Changes Applied", Time = 2, Icon = "circle-check" })
                        D:Dismiss()
                    end,
                },
            },
        })
    end,
})


--============================================================================
-- OVERLAYS TAB — Draggable overlays, the Context Menu primitive, and the
-- central Overlay Manager (toggle/remove overlays in bulk)
--============================================================================
-- Library:AddDraggableLabel(Text) / Library:AddDraggableButton(Text, Func)
-- Library:AddDraggableToggle(Text, Default, Callback)
-- Library:AddDraggableProgress(Text, Default, Max)
-- Floating panels that live outside the main window. Every one of these
-- (plus AddDraggableMenu and AddContextMenu below) is automatically added
-- to Library.Overlays -- see the "Overlay Manager" section further down
-- for the bulk toggle/remove API.
local OverlaySection = OverlaysTab:AddLeftSection("Draggable Overlays")

OverlaySection:AddButton({
    Text = "Spawn Draggable Label",
    Func = function()
        Library:AddDraggableLabel("Drag me around")
    end,
})
OverlaySection:AddButton({
    Text = "Spawn Draggable Button",
    Func = function()
        Library:AddDraggableButton("Click me", function()
            Library:Notify({ Title = "Draggable Button", Description = "Clicked!", Time = 2 })
        end)
    end,
})
OverlaySection:AddButton({
    Text = "Spawn Draggable Toggle",
    Func = function()
        Library:AddDraggableToggle("Auto Farm", false, function(Value)
            Library:Notify({ Title = "Draggable Toggle", Description = "Auto Farm: " .. tostring(Value), Time = 2 })
        end)
    end,
})
OverlaySection:AddButton({
    Text = "Spawn Draggable Progress",
    Func = function()
        local Progress = Library:AddDraggableProgress("Loading...", 0, 100)
        local Value = 0
        task.spawn(function()
            while Value < 100 and Progress:IsVisible() do
                Value += math.random(5, 15)
                Progress:SetValue(Value)
                task.wait(0.5)
            end
        end)
    end,
})

-- --------------------------------------------------------------
-- Overlay Manager: every draggable label/button/toggle/progress/
-- menu, and every context menu, is automatically registered in a
-- single central registry the moment it's created -- no manual
-- bookkeeping needed on your end. Use this to build a "Toggle UI
-- Elements" style panel, a cleanup routine, or a settings option
-- that hides/shows/removes overlays in bulk.
--
--   Library:GetOverlays(Type?)          -> array of overlay tables
--                                           (Type filters e.g. "DraggableLabel")
--   Library:GetOverlay(Id)              -> single overlay table, or nil
--   Overlay:SetVisible(bool) / :IsVisible() / :Remove()
--   Library:SetOverlayVisible(Id, bool) / :ToggleOverlay(Id) / :RemoveOverlay(Id)
--   Library:SetAllOverlaysVisible(bool, Type?)
--   Library:RemoveAllOverlays(Type?)
--
-- Every overlay table also carries .Id, .OverlayType, and .OverlayName
-- so you can build a list UI (like below) without tracking anything
-- yourself.
-- --------------------------------------------------------------
local ManagerSection = OverlaysTab:AddLeftSection("Overlay Manager")

ManagerSection:AddLabel({
    Text = "Spawn a few overlays above, then manage them here.",
    DoesWrap = true,
})

ManagerSection:AddButton({
    Text = "List Active Overlays",
    Func = function()
        local Overlays = Library:GetOverlays()
        if #Overlays == 0 then
            Library:Notify({ Title = "Overlay Manager", Description = "No overlays are currently active.", Time = 2 })
            return
        end

        local Lines = {}
        for _, Overlay in Overlays do
            table.insert(Lines, string.format("#%d  %s  (%s)", Overlay.Id, Overlay.OverlayName, Overlay.OverlayType))
        end

        Window:AddDialog("OverlayListDialog", {
            Title = string.format("Active Overlays (%d)", #Overlays),
            Description = table.concat(Lines, "\n"),
            Icon = "picture-in-picture-2",
            FooterButtons = {
                Ok = { Title = "Close", Variant = "Secondary", Order = 1 },
            },
        })
    end,
})

ManagerSection:AddButton({
    Text = "Hide All Overlays",
    Func = function()
        Library:SetAllOverlaysVisible(false)
        Library:Notify({ Title = "Overlay Manager", Description = "All overlays hidden.", Time = 2 })
    end,
})
ManagerSection:AddButton({
    Text = "Show All Overlays",
    Func = function()
        Library:SetAllOverlaysVisible(true)
        Library:Notify({ Title = "Overlay Manager", Description = "All overlays shown.", Time = 2 })
    end,
})
ManagerSection:AddButton({
    Text = "Remove Newest Overlay",
    Func = function()
        local Overlays = Library:GetOverlays()
        local Newest = Overlays[#Overlays]
        if not Newest then
            Library:Notify({ Title = "Overlay Manager", Description = "Nothing to remove.", Time = 2 })
            return
        end
        local Name = Newest.OverlayName
        Library:RemoveOverlay(Newest.Id)
        Library:Notify({ Title = "Overlay Manager", Description = "Removed " .. Name, Time = 2 })
    end,
})
ManagerSection:AddButton({
    Text = "Remove All Overlays",
    Risky = true,
    Func = function()
        Library:RemoveAllOverlays()
        Library:Notify({ Title = "Overlay Manager", Description = "All overlays removed.", Time = 2 })
    end,
})

-- --------------------------------------------------------------
-- Context Menu: the low-level positioned-popup primitive used
-- internally by dropdowns and color pickers. Anchor it to any
-- GuiObject and put whatever content you want inside Menu.Menu.
--
--   Library:AddContextMenu(Holder, Size, Offset, List, ActiveCallback, IgnoreCornerRadius)
--     Holder   GuiObject the menu is anchored to
--     Size     UDim2 (or a function returning one)
--     Offset   {x, y} pixel offset from Holder's position (or a function)
--     List     nil = plain Frame, 1 = auto-sizing list, 2 = scrollable list
--   Returns a Menu table: Menu:Open() / :Close() / :Toggle() / :SetSize(UDim2)
--   Only one context menu is open globally at a time.
-- --------------------------------------------------------------
local ContextSection = OverlaysTab:AddRightSection("Context Menu (Advanced)")

ContextSection:AddLabel({
    Text = "Right-click the box below to open a custom context menu.",
    DoesWrap = true,
})

local Anchor = Instance.new("TextButton")
Anchor.Size = UDim2.new(1, 0, 0, 36)
Anchor.BackgroundColor3 = Color3.fromRGB(30, 30, 34)
Anchor.Text = "Right-Click Me"
Anchor.TextColor3 = Color3.new(1, 1, 1)
Anchor.Font = Enum.Font.GothamMedium
Anchor.TextSize = 14
Anchor.AutoButtonColor = false
ContextSection:AddUIPassthrough("ContextAnchor", { Instance = Anchor, Height = 40 })

local RightClickMenu = Library:AddContextMenu(
    Anchor,
    UDim2.fromOffset(180, 90),
    { 0, 6 },
    nil,
    function(Active) end,
    false
)

local MenuLabel = Instance.new("TextLabel")
MenuLabel.BackgroundTransparency = 1
MenuLabel.Size = UDim2.fromScale(1, 1)
MenuLabel.Text = "Custom context menu\ncontent goes here"
MenuLabel.TextColor3 = Color3.new(1, 1, 1)
MenuLabel.TextSize = 13
MenuLabel.Font = Enum.Font.Gotham
MenuLabel.ZIndex = RightClickMenu.Menu.ZIndex -- match the menu's own ZIndex; needed for correct render order
MenuLabel.Parent = RightClickMenu.Menu

Anchor.InputBegan:Connect(function(Input)
    if Input.UserInputType == Enum.UserInputType.MouseButton2 then
        RightClickMenu:Toggle()
    end
end)

-- Toggle Bubble: floating chat-head style toggle that opens/closes the
-- window. Shown automatically on mobile, or force it on/off yourself:
--   CreateWindow-time: Bubble = true, BubbleSide, BubbleIcon, BubbleColor,
--                      BubbleIconColor, BubbleSize
--   Runtime:           Library:ToggleBubble() / (true) / (false)
local BubbleSection = OverlaysTab:AddLeftSection("Toggle Bubble")
BubbleSection:AddToggle("BubbleToggle", {
    Text = "Enable Floating Bubble",
    Default = false,
    Callback = function(Value)
        -- Guarded: Library:ToggleBubble only exists once CreateWindow has
        -- finished running (it's defined inside CreateWindow itself). If
        -- you ever see "attempt to call missing method 'ToggleBubble'",
        -- you're loading an older cached copy of Astral.lua that predates
        -- this method -- re-fetch/redeploy Astral.lua and it will resolve.
        if Library.ToggleBubble then
            Library:ToggleBubble(Value)
        else
            warn("Library:ToggleBubble is missing -- update Astral.lua")
        end
    end,
})

-- --------------------------------------------------------------
-- Draggable Menu: a full floating panel with its own title bar
-- (drag from the title to move it) and a content container you fill
-- with normal Add* element calls -- effectively a second, independent
-- mini-window that lives outside the main Window entirely.
--
--   Library:AddDraggableMenu(Name) -> Holder, RawContainer, Container
--     Holder        the whole panel (title bar + body), draggable by title
--     RawContainer  the raw content Frame Instance (rarely needed directly)
--     Container     element-friendly wrapper -- use THIS for AddButton/
--                   AddToggle/etc., same methods as any normal Section
-- --------------------------------------------------------------
local DraggableMenuSection = OverlaysTab:AddRightSection("Draggable Menu (Full Panel)")
DraggableMenuSection:AddButton({
    Text = "Spawn Draggable Menu",
    Func = function()
        local _MenuHolder, _RawContainer, MenuContainer = Library:AddDraggableMenu("Quick Actions")

        -- No need to build your own close button -- every draggable menu
        -- already has minimize (-) and close (x) buttons built into its
        -- title bar, styled to match the main window's own controls.
        MenuContainer:AddButton({
            Text = "Notify Me",
            Func = function()
                Library:Notify({ Title = "Hello from a draggable menu", Time = 2 })
            end,
        })
        MenuContainer:AddToggle("DragMenuToggle", { Text = "Some Setting", Default = false })
        MenuContainer:AddSlider("DragMenuSlider", { Text = "Some Value", Default = 25, Min = 0, Max = 100 })

        -- AddUIPassthrough still works normally inside a draggable menu
        -- for embedding your own raw Instances -- ZIndex is now handled
        -- automatically (see the note in Astral.lua's AddUIPassthrough),
        -- so this renders correctly above the menu's own background
        -- without needing any manual ZIndex bookkeeping.
        local CustomLabel = Instance.new("TextLabel")
        CustomLabel.BackgroundTransparency = 1
        CustomLabel.Text = "I'm a passthrough Instance, correctly layered"
        CustomLabel.TextColor3 = Color3.new(1, 1, 1)
        CustomLabel.TextWrapped = true
        CustomLabel.Font = Enum.Font.Gotham
        CustomLabel.TextSize = 12
        MenuContainer:AddUIPassthrough("DragMenuNote", { Instance = CustomLabel, Height = 30 })
    end,
})

-- --------------------------------------------------------------
-- Context Menu, List mode: pass List = 1 (auto-sizing) or List = 2
-- (fixed-size + scrollbar) as the 4th argument to get a UIListLayout
-- pre-built inside Menu.Menu, exactly like the dropdown/color-picker
-- popups use internally. Good for a right-click actions menu with a
-- variable number of rows.
-- --------------------------------------------------------------
local ListMenuSection = OverlaysTab:AddRightSection("Context Menu (List Mode)")
ListMenuSection:AddLabel({ Text = "Right-click below for a list-style menu.", DoesWrap = true })

local ListAnchor = Instance.new("TextButton")
ListAnchor.Size = UDim2.new(1, 0, 0, 36)
ListAnchor.BackgroundColor3 = Color3.fromRGB(30, 30, 34)
ListAnchor.Text = "Right-Click For Actions"
ListAnchor.TextColor3 = Color3.new(1, 1, 1)
ListAnchor.Font = Enum.Font.GothamMedium
ListAnchor.TextSize = 14
ListAnchor.AutoButtonColor = false
ListMenuSection:AddUIPassthrough("ListMenuAnchor", { Instance = ListAnchor, Height = 40 })

local ListMenu = Library:AddContextMenu(
    ListAnchor,
    UDim2.fromOffset(160, 0),
    { 0, 6 },
    1 -- List = 1: auto-sizing vertical list
)
ListMenu.ListLayout.Padding = UDim.new(0, 2)

local function AddListMenuRow(Text, Func)
    local Row = Instance.new("TextButton")
    Row.Size = UDim2.new(1, 0, 0, 24)
    Row.BackgroundTransparency = 1
    Row.Text = Text
    Row.TextColor3 = Color3.new(1, 1, 1)
    Row.TextSize = 13
    Row.Font = Enum.Font.Gotham
    Row.ZIndex = ListMenu.Menu.ZIndex
    Row.Parent = ListMenu.Menu
    Row.MouseButton1Click:Connect(function()
        Library:SafeCallback(Func)
        ListMenu:Close()
    end)
end
AddListMenuRow("Rename", function() Library:Notify({ Title = "Rename clicked", Time = 1.5 }) end)
AddListMenuRow("Duplicate", function() Library:Notify({ Title = "Duplicate clicked", Time = 1.5 }) end)
AddListMenuRow("Delete", function() Library:Notify({ Title = "Delete clicked", Time = 1.5 }) end)

ListAnchor.InputBegan:Connect(function(Input)
    if Input.UserInputType == Enum.UserInputType.MouseButton2 then
        ListMenu:Toggle()
    end
end)

--============================================================================
-- SETTINGS TAB — UI Scale, Theme Manager, Save Manager
--============================================================================
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/inCythe/Astral/refs/heads/main/addons/SaveManager.lua"))()
local ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/inCythe/Astral/refs/heads/main/addons/ThemeManager.lua"))()

SaveManager:SetLibrary(Library)
ThemeManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()

-- UI Scale lives above Theme/Config on purpose: it's the setting most
-- likely to need adjusting first (e.g. on a small or high-DPI screen)
-- before the rest of the settings tab is even comfortable to read.
--
-- Astral now auto-computes DPIScale from the actual screen/viewport size
-- on load, and keeps recalculating it live as the viewport changes
-- (window resize, device rotation, split screen) -- so on a small phone
-- the whole UI scales down to fit rather than just getting pixel-clamped
-- into a cramped box. Dragging this slider takes over as a manual
-- override (Library.AutoDPIScale becomes false) so your choice sticks
-- instead of being overwritten by the next auto-resize; there's a button
-- underneath to go back to automatic sizing at any time.
--
-- Library:SetDPIScale(Value: number 1-10) rescales the entire UI --
-- window, sidebar, dropdowns, notifications, overlays, and any active
-- loading screen -- everything registered in Library.Scales.
local DisplaySection = SettingsTab:AddSection({ Name = "Display", IconName = "sliders-horizontal" })
DisplaySection:AddSlider("UIScaleSlider", {
    Text = "UI Scale",
    Default = Library:CalculateAutoDPIScale(1),
    Min = 1,
    Max = 10,
    Rounding = 1,
    Callback = function(Value)
        Library.AutoDPIScale = false
        Library:SetDPIScale(Value)
    end,
})
DisplaySection:AddButton({
    Text = "Reset to Automatic Scaling",
    Func = function()
        Library.AutoDPIScale = true
        local AutoValue = Library:CalculateAutoDPIScale()
        Library:SetDPIScale(AutoValue)
        Library.Options.UIScaleSlider:SetValue(Library:CalculateAutoDPIScale(1))
        Library:Notify({ Title = "Display", Description = "UI Scale now follows your screen size automatically.", Time = 3 })
    end,
})

-- ThemeManager: color scheme presets + custom color editing.
ThemeManager:ApplyToTab(SettingsTab)

-- SaveManager: save/load/autoload named configs. BuildConfigSection now
-- loads the config and shows the window automatically once this script
-- finishes running (AutoShow = false above is what keeps the window hidden
-- until then) -- no separate SaveManager:Init(Window) call needed.
SaveManager:BuildConfigSection(SettingsTab)

-- Notify is safe to queue up before the window is shown -- it's stored and
-- gets displayed once the notification holder actually renders.
Library:Notify({
    Title = "Astral UI Loaded",
    Description = "Reference example ready — explore each tab.",
    Time = 4,
    Icon = "circle-check",
    IconColor = Color3.fromRGB(120, 220, 120),
})