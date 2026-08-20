local cloneref = (cloneref or clonereference or function(instance: any)
    return instance
end)
local CoreGui: CoreGui = cloneref(game:GetService("CoreGui"))
local Players: Players = cloneref(game:GetService("Players"))
local RunService: RunService = cloneref(game:GetService("RunService"))
local SoundService: SoundService = cloneref(game:GetService("SoundService"))
local UserInputService: UserInputService = cloneref(game:GetService("UserInputService"))
local TextService: TextService = cloneref(game:GetService("TextService"))
local Teams: Teams = cloneref(game:GetService("Teams"))
local TweenService: TweenService = cloneref(game:GetService("TweenService"))

local getgenv = getgenv or function()
    return shared
end
local setclipboard = setclipboard or nil
local protectgui = protectgui or function() end
local gethui = gethui or function()
    return CoreGui
end

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    LocalPlayer = Players.PlayerAdded:Wait()
end
local Mouse = LocalPlayer and cloneref(LocalPlayer:GetMouse()) or { Hit = CFrame.new(), Target = nil }

local Labels = {}
local Buttons = {}
local Toggles = {}
local Options = {}
local Tooltips = {}

local BaseURL = "https://raw.githubusercontent.com/inCythe/Astral/refs/heads/main/"
local CustomImageManager = {}
local CustomImageManagerAssets = {
    TransparencyTexture = {
        RobloxId = 139119720835185,
        Path = "Astral/assets/TransparencyTexture.png",
        URL = BaseURL .. "assets/TransparencyTexture.png",

        Id = nil,
        BuiltIn = true,
    },

    SaturationMap = {
        RobloxId = 105123850473267,
        Path = "Astral/assets/SaturationMap.png",
        URL = BaseURL .. "assets/SaturationMap.png",

        Id = nil,
        BuiltIn = true,
    },

    LoadingIcon = {
        RobloxId = 134481797305372,
        Path = "Astral/assets/LoadingIcon.png",
        URL = BaseURL .. "assets/LoadingIcon.png",

        Id = nil,
        BuiltIn = true,
    },

    CheckIcon = {
        RobloxId = 121540767860106,
        Path = "Astral/assets/CheckIcon.png",
        URL = BaseURL .. "assets/CheckIcon.png",

        Id = nil,
        BuiltIn = true,
    },

    AstralIcon = {
        RobloxId = 80158178764553,
        Path = "Astral/assets/AstralIcon.png",
        URL = BaseURL .. "assets/AstralIcon.png",

        Id = nil,
        BuiltIn = true,
    },

    DiscordIcon = {
        RobloxId = 79452348456435,
        Path = "Astral/assets/DiscordIcon.png",
        URL = BaseURL .. "assets/DiscordIcon.png",

        Id = nil,
        BuiltIn = true,
    },
}
do
    local function RecursiveCreatePath(Path: string, IsFile: boolean?)
        if not isfolder or not makefolder then
            return
        end

        local Segments = Path:split("/")
        local TraversedPath = ""

        if IsFile then
            table.remove(Segments, #Segments)
        end

        for _, Segment in Segments do
            if not isfolder(TraversedPath .. Segment) then
                makefolder(TraversedPath .. Segment)
            end

            TraversedPath = TraversedPath .. Segment .. "/"
        end

        return TraversedPath
    end

    function CustomImageManager.AddAsset(
        AssetName: string,
        RobloxAssetId: number,
        URL: string,
        ForceRedownload: boolean?
    )
        if CustomImageManagerAssets[AssetName] ~= nil then
            error(string.format("Asset %q already exists", AssetName))
        end

        assert(typeof(RobloxAssetId) == "number", "RobloxAssetId must be a number")

        CustomImageManagerAssets[AssetName] = {
            RobloxId = RobloxAssetId,
            Path = string.format("Astral/custom_assets/%s", AssetName),
            URL = URL,

            Id = nil,
        }

        CustomImageManager.DownloadAsset(AssetName, ForceRedownload)
    end

    function CustomImageManager.IsBuiltIn(AssetName: string)
        local AssetData = CustomImageManagerAssets[AssetName]
        return AssetData ~= nil and AssetData.BuiltIn == true
    end

    function CustomImageManager.GetAsset(AssetName: string)
        if not CustomImageManagerAssets[AssetName] then
            return nil
        end

        local AssetData = CustomImageManagerAssets[AssetName]
        if AssetData.Id then
            return AssetData.Id
        end

        local AssetID = string.format("rbxassetid://%s", AssetData.RobloxId)

        if getcustomasset then

            if isfile and not isfile(AssetData.Path) then
                local Ok = CustomImageManager.DownloadAsset(AssetName)

                if not Ok or not isfile(AssetData.Path) then
                    return AssetID
                end
            end

            local Success, NewID = pcall(getcustomasset, AssetData.Path)

            if Success and NewID and NewID ~= "" then
                AssetID = NewID

                AssetData.Id = AssetID
            end

        end

        return AssetID
    end

    function CustomImageManager.DownloadAsset(AssetName: string, ForceRedownload: boolean?)
        if not getcustomasset or not writefile or not isfile then
            return false, "missing functions"
        end

        local AssetData = CustomImageManagerAssets[AssetName]

        RecursiveCreatePath(AssetData.Path, true)

        if ForceRedownload ~= true and isfile(AssetData.Path) then

            local ExistingOk = false
            pcall(function()
                local Content = readfile(AssetData.Path)

                local Sig = Content:sub(1, 4)
                ExistingOk = (Sig:sub(1,1) == "\x89" and Sig:sub(2,4) == "PNG")
                    or (Sig:sub(1,2) == "\xFF\xD8")
                    or (Sig:sub(1,4) == "RIFF")
                    or (Sig:sub(1,3) == "GIF")
            end)
            if ExistingOk then
                return true, nil
            end

            pcall(delfile, AssetData.Path)
            AssetData.Id = nil
        end

        AssetData.Id = nil

        local Content = nil
        local DownloadSuccess, DownloadError = pcall(function()
            Content = game:HttpGet(AssetData.URL)
        end)

        if not DownloadSuccess or not Content or Content == "" then
            return false, DownloadError or "empty response"
        end

        local Sig = Content:sub(1, 4)
        local IsValidImage = (Sig:sub(1,1) == "\x89" and Sig:sub(2,4) == "PNG")
            or (Sig:sub(1,2) == "\xFF\xD8")
            or (Sig:sub(1,4) == "RIFF")
            or (Sig:sub(1,3) == "GIF")

        if not IsValidImage then
            return false, "downloaded content is not a valid image (URL may be invalid)"
        end

        local WriteSuccess, WriteError = pcall(function()
            writefile(AssetData.Path, Content)
        end)

        if WriteSuccess and not isfile(AssetData.Path) then
            return false, "writefile completed but file was not found on disk"
        end

        return WriteSuccess, WriteError
    end

    for AssetName, _ in CustomImageManagerAssets do
        CustomImageManager.DownloadAsset(AssetName)
    end
end

local Library = {
    LocalPlayer = LocalPlayer,
    DevicePlatform = nil,
    IsMobile = false,
    IsRobloxFocused = true,

    ScreenGui = nil,
    Bubble = nil,

    SearchText = "",
    Searching = false,
    LastSearchTab = nil,

    ActiveTab = nil,
    Tabs = {},
    TabButtons = {},
    ConditionalGroups = {},

    ActiveTabChangedCallbacks = {},

    KeybindFrame = nil,
    KeybindContainer = nil,
    KeybindToggles = {},

    Notifications = {},
    Dialogues = {},
    ActiveLoading = nil,
    ActiveDialog = nil,

    Overlays = {},
    OverlaysOrder = {},
    OverlayIdCounter = 0,

    Corners = {},

    OverlayZIndex = 1500,

    ToggleKeybind = Enum.KeyCode.RightControl,
    TweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    NotifyTweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),

    Toggled = false,
    Unloaded = false,

    Labels = Labels,
    Buttons = Buttons,
    Toggles = Toggles,
    Options = Options,

    TabSectionHeaders = {},

    NotifySide = "Right",
    ShowCustomCursor = false,
    ForceCheckbox = false,
    ShowToggleFrameInKeybinds = true,
    NotifyOnError = false,
    WaitForIconsOnLoad = true,

    CantDragForced = false,

    Signals = {},
    UnloadSignals = {},

    OriginalMinSize = Vector2.new(480, 360),
    MinSize = Vector2.new(480, 360),
    DPIScale = 1,
    CornerRadius = 6,
    CornerRadiusDropdown = false,

    IsLightTheme = false,
    Scheme = {
        BackgroundColor = Color3.fromRGB(13, 13, 16),
        MainColor = Color3.fromRGB(21, 21, 25),
        AccentColor = Color3.fromRGB(66, 135, 245),
        OutlineColor = Color3.fromRGB(36, 36, 42),
        FontColor = Color3.new(1, 1, 1),
        Font = Font.fromEnum(Enum.Font.GothamMedium),

        RedColor = Color3.fromRGB(255, 64, 64),
        DestructiveColor = Color3.fromRGB(225, 60, 60),
        DarkColor = Color3.new(0, 0, 0),
        WhiteColor = Color3.new(1, 1, 1),
    },

    Registry = {},
	Scales = {},
	ScalesOffset = {},
	DPIScaleCallbacks = {},
	AutoDPIScale = true,

    ImageManager = CustomImageManager,
    ShowCursorBinding = string.sub(tostring({}), 10),
}

if RunService:IsStudio() then
    if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
        Library.IsMobile = true
        Library.OriginalMinSize = Vector2.new(480, 240)
    else
        Library.IsMobile = false
        Library.OriginalMinSize = Vector2.new(480, 360)
    end
else
    pcall(function()
        Library.DevicePlatform = UserInputService:GetPlatform()
    end)
    Library.IsMobile = (Library.DevicePlatform == Enum.Platform.Android or Library.DevicePlatform == Enum.Platform.IOS)
    Library.OriginalMinSize = Library.IsMobile and Vector2.new(480, 240) or Vector2.new(480, 360)
end

local Templates = {

    Frame = {
        BorderSizePixel = 0,
    },
    ImageLabel = {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    },
    ImageButton = {
        AutoButtonColor = false,
        BorderSizePixel = 0,
    },
    ScrollingFrame = {
        BorderSizePixel = 0,
    },
    TextLabel = {
        BorderSizePixel = 0,
        FontFace = "Font",
        RichText = true,
        TextColor3 = "FontColor",
    },
    TextButton = {
        AutoButtonColor = false,
        BorderSizePixel = 0,
        FontFace = "Font",
        RichText = true,
        TextColor3 = "FontColor",
    },
    TextBox = {
        BorderSizePixel = 0,
        FontFace = "Font",
        PlaceholderColor3 = function()
            local H, S, V = Library.Scheme.FontColor:ToHSV()
            return Color3.fromHSV(H, S, V / 2)
        end,
        Text = "",
        TextColor3 = "FontColor",
    },
    UIListLayout = {
        SortOrder = Enum.SortOrder.LayoutOrder,
    },
    UIStroke = {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    },

    Window = {
        Title = "No Title",
        Footer = "No Footer",
        Position = UDim2.fromOffset(6, 6),
        Size = UDim2.fromOffset(720, 600),
        IconSize = UDim2.fromOffset(30, 30),
        AutoShow = false,
        Center = true,
        Resizable = true,
        SearchbarSize = UDim2.fromScale(1, 1),
        CornerRadius = 6,
        NotifySide = "Right",
        ShowCustomCursor = false,
        Font = Enum.Font.GothamMedium,
        TitleSize = 20,
        ToggleKeybind = Enum.KeyCode.RightControl,

        Bubble = nil,
        BubbleSide = "Right",
        BubbleIcon = "menu",
        BubbleIconColor = nil,
        BubbleColor = nil,
        BubbleSize = UDim2.fromOffset(50, 50),
        BubbleCornerRadius = 25,
        BubblePadding = 12,
        BubbleMargin = 8,

        UnlockMouseWhileOpen = true,

        DPIScale = 5,

        EnableSidebarResize = true,
        SidebarWidth = nil,
        SidebarCompacted = false,
        CompactSidebarTooltips = true,

        DiscordLink = nil,
        DiscordAction = "open",

        SingleInstance = true,

        WaitForIconsOnLoad = nil,
    },
    Dialog = {
        Title = "Dialog",
        Description = "Description",
        AutoDismiss = true,
        OutsideClickDismiss = true,
        ButtonsAlignment = "Right",
        FooterButtons = {}
    },
    Loading = {
        Title = "Astral",
        Icon = "AstralIcon",
        IconSize = UDim2.fromOffset(30, 30),

        LoadingIcon = "LoadingIcon",
        LoadingIconColor = nil,
        LoadingIconTweenTime = 1,

        CurrentStep = 0,
        TotalSteps = 10,

        ShowSidebar = false,
        AutoResizeHeight = false,

        WindowWidth = 450,
        WindowHeight = 275,

        ContentWidth = 450,
        SidebarWidth = 250,

        DPIScale = nil,
    },
    Toggle = {
        Text = "Toggle",
        Default = false,

        Callback = function() end,
        Changed = function() end,

        Risky = false,
        Disabled = false,
        Visible = true,
    },
    Input = {
        Text = "Input",
        Default = "",
        Finished = false,
        Numeric = false,
        ClearTextOnFocus = true,
        ClearTextOnBlur = false,
        Placeholder = "",
        AllowEmpty = true,
        EmptyReset = "---",

        Callback = function() end,
        Changed = function() end,
        VerifyValue = nil,

        Disabled = false,
        Visible = true,
    },
    Slider = {
        Text = "Slider",
        Default = 0,
        Min = 0,
        Max = 100,
        Rounding = 0,

        Prefix = "",
        Suffix = "",
        Editable = false,
        EditableStyle = "Pencil",

        Callback = function() end,
        Changed = function() end,

        Disabled = false,
        Visible = true,
    },
    ProgressBar = {
        Text = "Progress",
        Value = 0,
        Min = 0,
        Max = 100,
        Rounding = 0,

        Prefix = "",
        Suffix = "",
        Compact = false,
        HideMax = false,

        Callback = function() end,
        Changed = function() end,

        Disabled = false,
        Visible = true,
    },
    Dropdown = {
        Values = {},
        DisabledValues = {},
        ValueImages = {},

        Multi = false,
        MaxVisibleDropdownItems = 8,

        Callback = function() end,
        Changed = function() end,

        Disabled = false,
        Visible = true,
    },
    Viewport = {
        Object = nil,
        Camera = nil,
        Clone = true,
        AutoFocus = true,
        Interactive = false,
        Height = 200,
        Visible = true,
    },
    Image = {
        Image = "",
        Transparency = 0,
        BackgroundTransparency = 0,
        Color = Color3.new(1, 1, 1),
        RectOffset = Vector2.zero,
        RectSize = Vector2.zero,
        ScaleType = Enum.ScaleType.Fit,
        Height = 200,
        Visible = true,
    },
    Video = {
        Video = "",
        Looped = false,
        Playing = false,
        Volume = 1,
        Height = 200,
        Visible = true,
    },
    UIPassthrough = {
        Instance = nil,
        Height = 24,
        Visible = true,
    },

    KeyPicker = {
        Text = "KeyPicker",

        Default = "None",
        DefaultModifiers = {},

        Blacklisted = {},
        BlacklistedModifiers = {},
        Whitelisted = {},
        WhitelistedModifiers = {},

        Mode = "Toggle",
        Modes = { "Always", "Toggle", "Hold" },
        SyncToggleState = false,

        Callback = function() end,
        ChangedCallback = function() end,
        Changed = function() end,
        Clicked = function() end,
    },
    ColorPicker = {
        Default = Color3.new(1, 1, 1),

        Callback = function() end,
        Changed = function() end,
    },
}

local Places = {
    Bottom = { 0, 1 },
    Right = { 1, 0 },
}
local Sizes = {
    Left = { 0.5, 1 },
    Right = { 0.5, 1 },
}

local SchemeReplaceAlias = {
    RedColor = "Red",
    WhiteColor = "White",
    DarkColor = "Dark"
}

local SchemeAlias = {
    Red = "RedColor",
    White = "WhiteColor",
    Dark = "DarkColor"
}

local function GetSchemeValue(Index)
    if not Index then
        return nil
    end

    local ReplaceAliasIndex = SchemeReplaceAlias[Index]
    if ReplaceAliasIndex and Library.Scheme[ReplaceAliasIndex] ~= nil then
        Library.Scheme[Index] = Library.Scheme[ReplaceAliasIndex]
        Library.Scheme[ReplaceAliasIndex] = nil

        return Library.Scheme[Index]
    end

    local AliasIndex = SchemeAlias[Index]
    if AliasIndex and Library.Scheme[AliasIndex] ~= nil then
        warn(string.format("Scheme Value %q is deprecated, please use %q instead.", Index, AliasIndex))
        return Library.Scheme[AliasIndex]
    end

    return Library.Scheme[Index]
end

local function WaitForEvent(Event, Timeout, Condition)
    local Bindable = Instance.new("BindableEvent")
    local Connection = Event:Once(function(...)
        if not Condition or typeof(Condition) == "function" and Condition(...) then
            Bindable:Fire(true)
        else
            Bindable:Fire(false)
        end
    end)
    task.delay(Timeout, function()
        if Connection and Connection.Connected then
            Connection:Disconnect()
        end
        Bindable:Fire(false)
    end)

    local Result = Bindable.Event:Wait()
    Bindable:Destroy()

    return Result
end

local function IsMouseInput(Input: InputObject, IncludeM2: boolean?)
    return Input.UserInputType == Enum.UserInputType.MouseButton1
        or (IncludeM2 == true and Input.UserInputType == Enum.UserInputType.MouseButton2)
        or Input.UserInputType == Enum.UserInputType.Touch
end
local function IsClickInput(Input: InputObject, IncludeM2: boolean?)
    return IsMouseInput(Input, IncludeM2)
        and Input.UserInputState == Enum.UserInputState.Begin
        and Library.IsRobloxFocused
end
local function IsHoverInput(Input: InputObject)
    return (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch)
        and Input.UserInputState == Enum.UserInputState.Change
end
local function IsDragInput(Input: InputObject, IncludeM2: boolean?)
    return IsMouseInput(Input, IncludeM2)
        and (Input.UserInputState == Enum.UserInputState.Begin or Input.UserInputState == Enum.UserInputState.Change)
        and Library.IsRobloxFocused
end

local function GetTableSize(Table: { [any]: any })
    local Size = 0

    for _, _ in Table do
        Size += 1
    end

    return Size
end
local function StopTween(Tween: TweenBase)
    if not (Tween and Tween.PlaybackState == Enum.PlaybackState.Playing) then
        return
    end

    Tween:Cancel()
end
local function Trim(Text: string)
    return Text:match("^%s*(.-)%s*$")
end
local function Round(Value, Rounding)
    assert(Rounding >= 0, "Invalid rounding number.")

    if Rounding == 0 then

        return math.floor(Value + 0.5)
    end

    return tonumber(string.format("%." .. Rounding .. "f", Value))
end

local function GetPlayers(ExcludeLocalPlayer: boolean?)
    local PlayerList = Players:GetPlayers()

    if ExcludeLocalPlayer then
        local Idx = table.find(PlayerList, LocalPlayer)
        if Idx then
            table.remove(PlayerList, Idx)
        end
    end

    table.sort(PlayerList, function(Player1, Player2)
        return Player1.Name:lower() < Player2.Name:lower()
    end)

    return PlayerList
end
local function GetTeams()
    local TeamList = Teams:GetTeams()

    table.sort(TeamList, function(Team1, Team2)
        return Team1.Name:lower() < Team2.Name:lower()
    end)

    return TeamList
end

function Library:UpdateConditionalGroups()
    for _, ConditionalGroup in Library.ConditionalGroups do
        ConditionalGroup:Update(true)
    end

    if Library.Searching then
        Library:UpdateSearch(Library.SearchText)
    end
end

function Library:SetForceCheckbox(Value: boolean)
    Library.ForceCheckbox = Value

    for _, Toggle in Toggles do

        if typeof(Toggle) == "table" and Toggle.SetVariant and not Toggle.ExplicitCheckbox then
            Toggle:SetVariant(Value and "Checkbox" or "Switch")
        end
    end
end

local function CheckConditionalGroup(Box, Search)
    local VisibleElements = 0

    for _, ElementInfo in Box.Elements do
        if ElementInfo.Type == "Divider" then
            ElementInfo.Holder.Visible = false
            continue
        elseif ElementInfo.SubButton then

            local Visible = false

            if ElementInfo.Text:lower():match(Search) and ElementInfo.Visible then
                Visible = true
            else
                ElementInfo.Base.Visible = false
            end
            if ElementInfo.SubButton.Text:lower():match(Search) and ElementInfo.SubButton.Visible then
                Visible = true
            else
                ElementInfo.SubButton.Base.Visible = false
            end
            ElementInfo.Holder.Visible = Visible
            if Visible then
                VisibleElements += 1
            end

            continue
        end

        if ElementInfo.Text and ElementInfo.Text:lower():match(Search) and ElementInfo.Visible then
            ElementInfo.Holder.Visible = true
            VisibleElements += 1
        else
            ElementInfo.Holder.Visible = false
        end
    end

    for _, ConditionalGroup in Box.ConditionalGroups do
        if not ConditionalGroup.Visible then
            continue
        end

        VisibleElements += CheckConditionalGroup(ConditionalGroup, Search)
    end

    if Box.Resize then
        Box:Resize()
    end

    Box.Holder.Visible = VisibleElements > 0
    return VisibleElements
end
local function RestoreConditionalGroup(Box)
    for _, ElementInfo in Box.Elements do
        ElementInfo.Holder.Visible = typeof(ElementInfo.Visible) == "boolean" and ElementInfo.Visible or true

        if ElementInfo.SubButton then
            ElementInfo.Base.Visible = ElementInfo.Visible
            ElementInfo.SubButton.Base.Visible = ElementInfo.SubButton.Visible
        end
    end

    Box:Resize()
    Box.Holder.Visible = true

    for _, ConditionalGroup in Box.ConditionalGroups do
        if not ConditionalGroup.Visible then
            continue
        end

        RestoreConditionalGroup(ConditionalGroup)
    end

    if Box.SubSections then
        for _, SubSection in Box.SubSections do
            RestoreConditionalGroup(SubSection)
        end
    end
end

local function FilterBox(Box, Search)
    local VisibleElements = 0

    for _, ElementInfo in Box.Elements do
        if ElementInfo.Type == "Divider" then
            ElementInfo.Holder.Visible = false
            continue
        elseif ElementInfo.SubButton then

            local Visible = false

            if ElementInfo.Text:lower():match(Search) and ElementInfo.Visible then
                Visible = true
            else
                ElementInfo.Base.Visible = false
            end
            if ElementInfo.SubButton.Text:lower():match(Search) and ElementInfo.SubButton.Visible then
                Visible = true
            else
                ElementInfo.SubButton.Base.Visible = false
            end
            ElementInfo.Holder.Visible = Visible
            if Visible then
                VisibleElements += 1
            end

            continue
        end

        if ElementInfo.Text and ElementInfo.Text:lower():match(Search) and ElementInfo.Visible then
            ElementInfo.Holder.Visible = true
            VisibleElements += 1
        else
            ElementInfo.Holder.Visible = false
        end
    end

    if Box.ConditionalGroups then
        for _, ConditionalGroup in Box.ConditionalGroups do
            if not ConditionalGroup.Visible then
                continue
            end

            VisibleElements += CheckConditionalGroup(ConditionalGroup, Search)
        end
    end

    if Box.SubSections then
        for _, SubSection in Box.SubSections do
            local SubVisible = FilterBox(SubSection, Search)
            VisibleElements += SubVisible

            if SubVisible > 0 then
                SubSection:Resize()
            end
            SubSection.Holder.Visible = SubVisible > 0
        end
    end

    return VisibleElements
end

local function ApplySearchToTab(Tab, Search)
    if not Tab then
        return
    end

    local HasVisible = false

    for _, Section in Tab.Sections do
        local VisibleElements = FilterBox(Section, Search)

        if VisibleElements > 0 then
            Section:Resize()
            HasVisible = true
        end
        Section.BoxHolder.Visible = VisibleElements > 0
    end

    for _, SectionGroup in Tab.SectionGroups do
        local VisibleTabs = 0
        local VisibleElements = {}

        for _, SubTab in SectionGroup.Tabs do
            VisibleElements[SubTab] = FilterBox(SubTab, Search)
        end

        for SubTab, Visible in VisibleElements do
            SubTab.ButtonHolder.Visible = Visible > 0
            if Visible > 0 then
                VisibleTabs += 1
                HasVisible = true

                if SectionGroup.ActiveTab == SubTab then
                    SubTab:Resize()
                elseif SectionGroup.ActiveTab and VisibleElements[SectionGroup.ActiveTab] == 0 then
                    SubTab:Show()
                end
            end
        end

        SectionGroup.BoxHolder.Visible = VisibleTabs > 0
    end

    return HasVisible
end

local function RestoreBox(Box)
    for _, ElementInfo in Box.Elements do
        ElementInfo.Holder.Visible = typeof(ElementInfo.Visible) == "boolean" and ElementInfo.Visible or true

        if ElementInfo.SubButton then
            ElementInfo.Base.Visible = ElementInfo.Visible
            ElementInfo.SubButton.Base.Visible = ElementInfo.SubButton.Visible
        end
    end

    if Box.ConditionalGroups then
        for _, ConditionalGroup in Box.ConditionalGroups do
            if not ConditionalGroup.Visible then
                continue
            end

            RestoreConditionalGroup(ConditionalGroup)
        end
    end

    if Box.SubSections then
        for _, SubSection in Box.SubSections do
            RestoreConditionalGroup(SubSection)
            SubSection.Holder.Visible = true
        end
    end
end

local function ResetTab(Tab)
    if not Tab then
        return
    end

    for _, Section in Tab.Sections do
        RestoreBox(Section)

        Section:Resize()
        Section.BoxHolder.Visible = true
    end

    for _, SectionGroup in Tab.SectionGroups do
        for _, SubTab in SectionGroup.Tabs do
            RestoreBox(SubTab)

            SubTab.ButtonHolder.Visible = true
        end

        if SectionGroup.ActiveTab then
            SectionGroup.ActiveTab:Resize()
        end
        SectionGroup.BoxHolder.Visible = true
    end
end

function Library:UpdateSearch(SearchText)
    Library.SearchText = SearchText

    local TabsToReset = {}

    if Library.LastSearchTab and typeof(Library.LastSearchTab) == "table" then
        table.insert(TabsToReset, Library.LastSearchTab)
    end

    for _, Tab in TabsToReset do
        ResetTab(Tab)
    end

    local Search = SearchText:lower()
    if Trim(Search) == "" then
        Library.Searching = false
        Library.LastSearchTab = nil
        return
    end
    if Library.ActiveTab and Library.ActiveTab.IsKeyTab then
        Library.Searching = false
        Library.LastSearchTab = nil
        return
    end

    Library.Searching = true

    if Library.ActiveTab then
        ApplySearchToTab(Library.ActiveTab, Search)
    end

    Library.LastSearchTab = Library.ActiveTab
end

function Library:AddToRegistry(Inst, Properties)

    local Existing = Library.Registry[Inst]
    if Existing then
        for Key, Value in Properties do
            Existing[Key] = Value
        end
    else
        Library.Registry[Inst] = Properties
    end
end

function Library:RemoveFromRegistry(Inst)
    Library.Registry[Inst] = nil
end

function Library:UpdateColorsUsingRegistry()
    for Inst, Properties in Library.Registry do
        for Property, Index in Properties do
            local SchemeValue = GetSchemeValue(Index)

            if SchemeValue or typeof(Index) == "function" then
                Inst[Property] = SchemeValue or Index()
            end
        end
    end
end

function Library:CalculateAutoBaseScale(): number
    local Camera = workspace.CurrentCamera
    local ViewportSize: Vector2 = (Camera and Camera.ViewportSize) or Vector2.new(1280, 720)
    if RunService:IsStudio() and ViewportSize.X <= 5 and ViewportSize.Y <= 5 then
        return 1
    end

    local WinWidth = (Library.MainFrame and Library.MainFrame.Size.X.Offset) or 720
    local WinHeight = (Library.MainFrame and Library.MainFrame.Size.Y.Offset) or 600

    local MarginX = 36
    local MarginY = 36
    local AvailableX = math.max(100, ViewportSize.X - MarginX)
    local AvailableY = math.max(100, ViewportSize.Y - MarginY)

    local ScaleX = AvailableX / WinWidth
    local ScaleY = AvailableY / WinHeight
    local FitScale = math.min(ScaleX, ScaleY)

    return math.clamp(FitScale, 0.25, 1)
end

function Library:CalculateAutoDPIScale(Rounding: number?): number
    local Value = 5
    if Rounding ~= nil then
        local Multiplier = 10 ^ math.max(math.floor(Rounding), 0)
        Value = math.floor(Value * Multiplier + 0.5) / Multiplier
    end
    return Value
end

function Library:SetDPIScale(DPIScale: number)
    DPIScale = math.clamp(tonumber(DPIScale) or 5, 1, 10)
    Library.UIScaleValue = DPIScale

    -- Always recalculate BaseScale from the current viewport
    Library.BaseScale = Library:CalculateAutoBaseScale()

    local Multiplier = DPIScale / 5
    local ScaleFactor = Library.BaseScale * Multiplier

    Library.DPIValue = DPIScale
    Library.DPIScale = ScaleFactor

    -- IMPORTANT:
    -- MinSize NEVER changes with DPI. The logical UI dimensions remain
    -- constant; only UIScale changes to make them fit the viewport.
    Library.MinSize = Library.OriginalMinSize

	for _, UIScale in Library.Scales do
        UIScale.Scale = ScaleFactor - (tonumber(Library.ScalesOffset[UIScale]) or 0)
    end

    if Library.MainFrame and Library.CenterMainWindow and not Library.MainWindowWasMoved then
        local MainScaleFactor = (Library.MainWindowScale and Library.MainWindowScale.Scale) or ScaleFactor
        local ScaledWidth = Library.MainFrame.Size.X.Offset * MainScaleFactor
        local ScaledHeight = Library.MainFrame.Size.Y.Offset * MainScaleFactor
        Library.MainFrame.Position = UDim2.new(0.5, -ScaledWidth / 2, 0.5, -ScaledHeight / 2)
    end

    for _, Option in Options do
        if Option.Type == "Dropdown" then
            Option:RecalculateListSize()
        end
    end

    for _, Notification in Library.Notifications do
        Notification:Resize()
    end

    for _, Callback in Library.DPIScaleCallbacks do
        Library:SafeCallback(Callback, ScaleFactor)
    end
end

function Library:GiveDPIScaleCallback(Callback: (ScaleFactor: number) -> ())
    table.insert(Library.DPIScaleCallbacks, Callback)
    return Callback
end

function Library:GiveActiveTabChangedCallback(Callback: (Tab: any) -> ())
    table.insert(Library.ActiveTabChangedCallbacks, Callback)
    return Callback
end

function Library:FireActiveTabChanged(Tab)
    for _, Callback in Library.ActiveTabChangedCallbacks do
        Library:SafeCallback(Callback, Tab)
    end
end

function Library:GiveSignal(Connection: RBXScriptConnection)
    if Connection and typeof(Connection) == "RBXScriptConnection" then
        table.insert(Library.Signals, Connection)
    end

    return Connection
end

function IsValidCustomIcon(Icon: string)
    return typeof(Icon) == "string" and (Icon:match("rbxasset") or Icon:match("roblox%.com/asset/%?id=") or Icon:match("rbxthumb://type="))
end

type Icon = {
    Url: string,
    Id: number,
    IconName: string,
    ImageRectOffset: Vector2,
    ImageRectSize: Vector2,
}

type IconModule = {
    Icons: { string },
    GetAsset: (Name: string) -> Icon?,
}

local LUCIDE_SOURCE_URL = "https://raw.githubusercontent.com/inCythe/Astral/refs/heads/main/LucideIcons.lua"
local LUCIDE_CACHE_PATH = "Astral/cache/LucideIcons.lua"

local IconsLoaded = false
local Icons = {} :: { [string]: string }

local function HttpGetAny(Url: string): (boolean, string?)
    local Methods = {}

    if game and typeof(game.HttpGet) == "function" then
        table.insert(Methods, function()
            return game:HttpGet(Url)
        end)
    end

    if typeof(http_request) == "function" then
        table.insert(Methods, function()
            local Response = http_request({ Url = Url, Method = "GET" })
            return Response and Response.Body
        end)
    end

    if typeof(request) == "function" then
        table.insert(Methods, function()
            local Response = request({ Url = Url, Method = "GET" })
            return Response and Response.Body
        end)
    end

    if syn and typeof(syn.request) == "function" then
        table.insert(Methods, function()
            local Response = syn.request({ Url = Url, Method = "GET" })
            return Response and Response.Body
        end)
    end

    if typeof(fluxus_request) == "function" then
        table.insert(Methods, function()
            local Response = fluxus_request({ Url = Url, Method = "GET" })
            return Response and Response.Body
        end)
    end

    for _, Method in Methods do
        local Success, Result = pcall(Method)
        if Success and typeof(Result) == "string" and #Result > 0 then
            return true, Result
        end
    end

    return false, nil
end

local function LoadIconsFromCache(): boolean
    if not isfile or not readfile then
        return false
    end

    if not isfile(LUCIDE_CACHE_PATH) then
        return false
    end

    local Success, Content = pcall(readfile, LUCIDE_CACHE_PATH)
    if not Success or not Content or Content == "" then
        return false
    end

    if not Content:find("return {") or not Content:find("rbxassetid://") then
        return false
    end

    local CompileSuccess, Compiled = pcall(loadstring, Content)
    if not CompileSuccess or typeof(Compiled) ~= "function" then
        return false
    end

    local RunSuccess, Module = pcall(Compiled)
    if not RunSuccess or typeof(Module) ~= "table" then
        return false
    end

    Icons = Module :: { [string]: string }
    return true
end

local function SaveIconsToCache(Content: string): boolean
    if not writefile or not isfolder or not makefolder then
        return false
    end

    local CacheDir = LUCIDE_CACHE_PATH:sub(1, LUCIDE_CACHE_PATH:find("/[^/]*$") - 1)
    if not isfolder(CacheDir) then
        pcall(makefolder, CacheDir)
    end

    local Success, Error = pcall(writefile, LUCIDE_CACHE_PATH, Content)
    if not Success then
        return false
    end

    return true
end

local function FetchIconsWithRetry(): (boolean, { [string]: string }?)

    if LoadIconsFromCache() then
        return true, Icons
    end

    local Success, Result = HttpGetAny(LUCIDE_SOURCE_URL)
    if not Success or not Result or Result == "" then
        return false, nil
    end

    local CompileSuccess, Compiled = pcall(loadstring, Result)
    if not CompileSuccess or typeof(Compiled) ~= "function" then
        return false, nil
    end

    local RunSuccess, Module = pcall(Compiled)
    if not RunSuccess or typeof(Module) ~= "table" then
        return false, nil
    end

    pcall(SaveIconsToCache, Result)

    Icons = Module :: { [string]: string }
    return true, Icons
end

local FetchIcons = false
task.spawn(function()
    local Success, Result = FetchIconsWithRetry()
    if Success and Result then
        FetchIcons = true
        Icons = Result
    end
    IconsLoaded = true
end)

function Library:GetIcon(IconName: string)
    if not FetchIcons then
        return
    end

    local Url = Icons[IconName]
    if typeof(Url) ~= "string" or Url == "" then
        return
    end

    return {
        Url = Url,
        IconName = IconName,
        ImageRectOffset = Vector2.zero,
        ImageRectSize = Vector2.zero,
    }
end

function Library:WaitForIcons(Timeout: number?): boolean
    Timeout = Timeout or 10

    local StartTime = tick()

    while not IconsLoaded do
        if tick() - StartTime > Timeout then
            warn("[Astral] Icon loading timed out after " .. Timeout .. " seconds")
            return false
        end
        task.wait(0.1)
    end

    return FetchIcons
end

function Library:AreIconsLoaded(): boolean
    return IconsLoaded and FetchIcons
end

local PendingIconInstances = {} :: { [Instance]: string }

function Library:RegisterIconInstance(Instance: Instance, IconName: string)
    if Library:AreIconsLoaded() then
        local Icon = Library:GetIcon(IconName)
        if Icon then
            (Instance :: any).Image = Icon.Url
            ;(Instance :: any).ImageRectOffset = Icon.ImageRectOffset
            ;(Instance :: any).ImageRectSize = Icon.ImageRectSize
        end
        return
    end

    PendingIconInstances[Instance] = IconName

    Instance.Destroying:Connect(function()
        PendingIconInstances[Instance] = nil
    end)
end

function Library:RefreshIcons()
    for Instance, IconName in pairs(PendingIconInstances) do
        if Instance and Instance.Parent then
            local Icon = Library:GetIcon(IconName)
            if Icon then
                (Instance :: any).Image = Icon.Url
                ;(Instance :: any).ImageRectOffset = Icon.ImageRectOffset
                ;(Instance :: any).ImageRectSize = Icon.ImageRectSize
            end
        end
    end
    table.clear(PendingIconInstances)
end

function Library:GetCustomIcon(IconName: string): any
    if not IconName then
        return nil
    end

    if typeof(IconName) == "table" and IconName.Url then
        return IconName
    end

    if tonumber(IconName) then
        IconName = string.format("rbxassetid://%s", tostring(IconName))
    end

    if CustomImageManagerAssets[IconName] ~= nil then
        local ResolvedUrl = CustomImageManager.GetAsset(IconName)
        if ResolvedUrl then
            return {
                Url = ResolvedUrl,
                ImageRectOffset = Vector2.zero,
                ImageRectSize = Vector2.zero,
                Custom = true,
                IsBuiltIn = CustomImageManager.IsBuiltIn(IconName),
            }
        end
    end

    local CustomIcon = IsValidCustomIcon(IconName)
    if CustomIcon then
        return {
            Url = IconName,
            ImageRectOffset = Vector2.zero,
            ImageRectSize = Vector2.zero,
            Custom = true,
        }
    end

    local LucideIcon = Library:GetIcon(IconName)
    if LucideIcon then
        return LucideIcon
    end

    return nil
end

function Library:Validate(Table: { [string]: any }, Template: { [string]: any }): { [string]: any }
    if typeof(Table) ~= "table" then
        return Template
    end

    for k, v in Template do
        if typeof(k) == "number" then
            continue
        end

        if typeof(v) == "table" then
            Table[k] = Library:Validate(Table[k], v)
        elseif Table[k] == nil then
            Table[k] = v
        end
    end

    return Table
end

local function FillInstance(Table: { [string]: any }, Inst: GuiObject)
    local ThemeProperties = Library.Registry[Inst] or {}

    for key, value in Table do
        if key ~= "Text" then
            local SchemeValue = GetSchemeValue(value)

            if SchemeValue or typeof(value) == "function" then
                ThemeProperties[key] = value
                value = SchemeValue or value()
            else
                ThemeProperties[key] = nil
            end
        end

        Inst[key] = value
    end

    if GetTableSize(ThemeProperties) > 0 then
        Library.Registry[Inst] = ThemeProperties
    end
end

local function New(ClassName: string, Properties: { [string]: any }): any
    local inst = Instance.new(ClassName)

    if Templates[ClassName] then
        FillInstance(Templates[ClassName], inst)
    end
    FillInstance(Properties, inst)

    if Properties["Parent"] and not Properties["ZIndex"] then
        pcall(function()
            inst.ZIndex = Properties.Parent.ZIndex
        end)
    end

    return inst
end

function Library:NewTrackedScale(Parent: Instance, Offset: number?)
    local ScaleFactor = Library.DPIScale or 1
    local Scale = New("UIScale", {
        Scale = ScaleFactor - (Offset or 0),
        Parent = Parent,
    })
    table.insert(Library.Scales, Scale)
    if Offset then
        Library.ScalesOffset[Scale] = Offset
    end
    return Scale
end

local function SafeParentUI(UI: Instance, Parent: Instance | () -> Instance)
    local success, _error = pcall(function()
        if not Parent then
            Parent = CoreGui
        end

        local DestinationParent
        if typeof(Parent) == "function" then
            DestinationParent = Parent()
        else
            DestinationParent = Parent
        end

        UI.Parent = DestinationParent
    end)

    if not (success and UI.Parent) then
        UI.Parent = Library.LocalPlayer:WaitForChild("PlayerGui", math.huge)
    end
end

local function ParentUI(UI: Instance, SkipHiddenUI: boolean?)
    if SkipHiddenUI then
        SafeParentUI(UI, CoreGui)
        return
    end

    pcall(protectgui, UI)
    SafeParentUI(UI, gethui)
end

do
    local GuiParent = gethui()
    local ExistingGui = GuiParent:FindFirstChild("Astral")
    if ExistingGui then

        if getgenv().Library and typeof(getgenv().Library.Unload) == "function" and not getgenv().Library.Unloaded then
            pcall(getgenv().Library.Unload, getgenv().Library)
        else

            pcall(function() ExistingGui:Destroy() end)
        end
    end
end

local ScreenGui = New("ScreenGui", {
    Name = "Astral",
    DisplayOrder = 998,
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Global,
})
ParentUI(ScreenGui)
Library.ScreenGui = ScreenGui

ScreenGui.DescendantRemoving:Connect(function(Inst)
    Library:RemoveFromRegistry(Inst)
end)

local ModalElement = New("TextButton", {
    BackgroundTransparency = 1,
    Modal = false,
    Size = UDim2.fromScale(0, 0),
    AnchorPoint = Vector2.zero,
    Text = "",
    ZIndex = -999,
    Parent = ScreenGui,
})

local Cursor, CursorCustomImage
do
    Cursor = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = "WhiteColor",
        Size = UDim2.fromOffset(9, 1),
        Visible = false,
        ZIndex = 11000,
        Parent = ScreenGui,
    })
    New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = "DarkColor",
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, 2, 1, 2),
        ZIndex = 10999,
        Parent = Cursor,
    })

    local CursorV = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = "WhiteColor",
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(1, 9),
        ZIndex = 11000,
        Parent = Cursor,
    })
    New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = "DarkColor",
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, 2, 1, 2),
        ZIndex = 10999,
        Parent = CursorV,
    })

    CursorCustomImage = New("ImageLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(20, 20),
        ZIndex = 11000,
        Visible = false,
        Parent = Cursor
    })
end

local NotificationArea
local NotificationList
do
    NotificationArea = New("Frame", {
        AnchorPoint = Vector2.new(1, 0),
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -6, 0, 6),
        Size = UDim2.new(0, 300, 1, -6),
        Parent = ScreenGui,
    })
    table.insert(
        Library.Scales,
        New("UIScale", {
            Parent = NotificationArea,
        })
    )

    NotificationList = New("UIListLayout", {
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        Padding = UDim.new(0, 8),
        Parent = NotificationArea,
    })
end

function Library:ResetCursorIcon()
    CursorCustomImage.Visible = false
    CursorCustomImage.Size = UDim2.fromOffset(20, 20)
end

function Library:ChangeCursorIcon(ImageId: string)
    if not ImageId or ImageId == "" then
        Library:ResetCursorIcon()
        return
    end

    local Icon = Library:GetCustomIcon(ImageId)
    assert(Icon, "Image must be a valid Roblox asset or a valid URL or a valid lucide icon.")

    CursorCustomImage.Visible = true
    CursorCustomImage.Image = Icon.Url
    CursorCustomImage.ImageRectOffset = Icon.ImageRectOffset
    CursorCustomImage.ImageRectSize = Icon.ImageRectSize
end

function Library:ChangeCursorIconSize(Size: UDim2)
    assert(typeof(Size) == "UDim2", "UDim2 expected.")
    CursorCustomImage.Size = Size
end

function Library:GetBetterColor(Color: Color3, Add: number): Color3
    Add = Add * (Library.IsLightTheme and -4 or 2)
    return Color3.fromRGB(
        math.clamp(Color.R * 255 + Add, 0, 255),
        math.clamp(Color.G * 255 + Add, 0, 255),
        math.clamp(Color.B * 255 + Add, 0, 255)
    )
end

function Library:GetLighterColor(Color: Color3): Color3
    local H, S, V = Color:ToHSV()
    return Color3.fromHSV(H, math.max(0, S - 0.1), math.min(1, V + 0.1))
end

function Library:GetDarkerColor(Color: Color3): Color3
    local H, S, V = Color:ToHSV()
    return Color3.fromHSV(H, S, V / 2)
end

function Library:GetAccentShade(_Step: number): Color3
    return (Library.Scheme and Library.Scheme.AccentColor) or Color3.fromRGB(90, 160, 255)
end

function Library:GetKeyString(KeyCode: Enum.KeyCode)
    if KeyCode.EnumType == Enum.KeyCode and KeyCode.Value > 33 and KeyCode.Value < 127 then
        return string.char(KeyCode.Value)
    end

    return KeyCode.Name
end

function Library:GetTextBounds(Text: string, Font: Font, Size: number, Width: number?): (number, number)
    local Params = Instance.new("GetTextBoundsParams")
    Params.Text = Text
    Params.RichText = true
    Params.Font = Font
    Params.Size = Size
    Params.Width = Width or workspace.CurrentCamera.ViewportSize.X - 32

    local Bounds = TextService:GetTextBoundsAsync(Params)
    return Bounds.X, Bounds.Y
end

function Library:MouseIsOverFrame(Frame: GuiObject, Mouse: Vector2): boolean
    local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize
    return Mouse.X >= AbsPos.X
        and Mouse.X <= AbsPos.X + AbsSize.X
        and Mouse.Y >= AbsPos.Y
        and Mouse.Y <= AbsPos.Y + AbsSize.Y
end

function Library:SafeCallback(Func: (...any) -> ...any, ...: any)
    if not (Func and typeof(Func) == "function") then
        return
    end

    local Result = table.pack(xpcall(Func, function(Error)
        task.defer(error, debug.traceback(Error, 2))
        if Library.NotifyOnError then
            Library:Notify(Error)
        end

        return Error
    end, ...))

    if not Result[1] then
        return nil
    end

    return table.unpack(Result, 2, Result.n)
end

function Library:MakeDraggable(UI: GuiObject, DragFrame: GuiObject, IgnoreToggled: boolean?, IsMainWindow: boolean?)
    local StartPos
    local FramePos
    local Dragging = false
    local Changed

    local function GetOwningScreenGui(): ScreenGui?
        return UI:FindFirstAncestorOfClass("ScreenGui")
    end

    DragFrame.InputBegan:Connect(function(Input: InputObject)
        if not IsClickInput(Input) or IsMainWindow and Library.CantDragForced then
            return
        end

        StartPos = Input.Position
        FramePos = UI.Position
        Dragging = true

        if IsMainWindow then
            Library.MainWindowWasMoved = true
        end

        Changed = Input.Changed:Connect(function()
            if Input.UserInputState ~= Enum.UserInputState.End then
                return
            end

            Dragging = false
            if Changed and Changed.Connected then
                Changed:Disconnect()
                Changed = nil
            end
        end)
    end)
    Library:GiveSignal(UserInputService.InputChanged:Connect(function(Input: InputObject)
        local OwningScreenGui = GetOwningScreenGui()

        if
            (not IgnoreToggled and not Library.Toggled)
            or (IsMainWindow and Library.CantDragForced)
            or not (OwningScreenGui and OwningScreenGui.Parent)
        then
            Dragging = false
            if Changed and Changed.Connected then
                Changed:Disconnect()
                Changed = nil
            end

            return
        end

        if Dragging and IsHoverInput(Input) then
            local Delta = Input.Position - StartPos
            UI.Position =
                UDim2.new(FramePos.X.Scale, FramePos.X.Offset + Delta.X, FramePos.Y.Scale, FramePos.Y.Offset + Delta.Y)
        end
    end))
end

function Library:MakeResizable(UI: GuiObject, DragFrame: GuiObject, Callback: () -> ()?)
    local StartPos
    local FrameSize
    local Dragging = false
    local Changed

    DragFrame.InputBegan:Connect(function(Input: InputObject)
        if not IsClickInput(Input) then
            return
        end

        StartPos = Input.Position
        FrameSize = UI.Size
        Dragging = true

        Changed = Input.Changed:Connect(function()
            if Input.UserInputState ~= Enum.UserInputState.End then
                return
            end

            Dragging = false
            if Changed and Changed.Connected then
                Changed:Disconnect()
                Changed = nil
            end
        end)
    end)

    Library:GiveSignal(UserInputService.InputChanged:Connect(function(Input: InputObject)
        if not UI.Visible or not (ScreenGui and ScreenGui.Parent) then
            Dragging = false
            if Changed and Changed.Connected then
                Changed:Disconnect()
                Changed = nil
            end

            return
        end

        if Dragging and IsHoverInput(Input) then
            local Delta = Input.Position - StartPos
            UI.Size = UDim2.new(
                FrameSize.X.Scale,
                math.clamp(FrameSize.X.Offset + Delta.X, Library.MinSize.X, math.huge),
                FrameSize.Y.Scale,
                math.clamp(FrameSize.Y.Offset + Delta.Y, Library.MinSize.Y, math.huge)
            )
            if Callback then
                Library:SafeCallback(Callback)
            end
        end
    end))
end

function Library:MakeCover(Holder: GuiObject, Place: string)
    local Pos = Places[Place] or { 0, 0 }
    local Size = Sizes[Place] or { 1, 0.5 }

    local Cover = New("Frame", {
        AnchorPoint = Vector2.new(Pos[1], Pos[2]),
        BackgroundColor3 = Holder.BackgroundColor3,
        Position = UDim2.fromScale(Pos[1], Pos[2]),
        Size = UDim2.fromScale(Size[1], Size[2]),
        Parent = Holder,
    })

    return Cover
end

function Library:MakeLine(Frame: GuiObject, Info)
    local Line = New("Frame", {
        AnchorPoint = Info.AnchorPoint or Vector2.zero,
        BackgroundColor3 = "OutlineColor",
        Position = Info.Position,
        Size = Info.Size,
        ZIndex = Info.ZIndex or Frame.ZIndex,
        Parent = Frame,
    })

    return Line
end

function Library:AddOutline(Frame: GuiObject)
    local OutlineStroke = New("UIStroke", {
        Color = "OutlineColor",
        Thickness = 1,
        Transparency = 0.2,
        ZIndex = 2,
        Parent = Frame,
    })
    local ShadowStroke = New("UIStroke", {
        Color = "DarkColor",
        Thickness = 1,
        Transparency = 0.5,
        ZIndex = 1,
        Parent = Frame,
    })
    return OutlineStroke, ShadowStroke
end

function Library:AddBlank(Frame: GuiObject, Size: UDim2)
    return New("Frame", {
        BackgroundTransparency = 1,
        Size = Size or UDim2.fromScale(0, 0),
        Parent = Frame,
    })
end

function Library:MakeOutline(Frame: GuiObject, Corner: number?, ZIndex: number?)
    warn("Astral:MakeOutline is deprecated, please use Astral:AddOutline instead.")
    local Holder = New("Frame", {
        BackgroundColor3 = "DarkColor",
        Position = UDim2.fromOffset(-2, -2),
        Size = UDim2.new(1, 4, 1, 4),
        ZIndex = ZIndex,
        Parent = Frame,
    })

    local Outline = New("Frame", {
        BackgroundColor3 = "OutlineColor",
        Position = UDim2.fromOffset(1, 1),
        Size = UDim2.new(1, -2, 1, -2),
        ZIndex = ZIndex,
        Parent = Holder,
    })

    if Corner and Corner > 0 then
        New("UICorner", {
            CornerRadius = UDim.new(0, Corner + 1),
            Parent = Holder,
        })
        New("UICorner", {
            CornerRadius = UDim.new(0, Corner),
            Parent = Outline,
        })
    end

    return Holder, Outline
end

function Library:RegisterOverlay(OverlayType: string, Name: string?, Table: { [any]: any })
    Library.OverlayIdCounter = Library.OverlayIdCounter + 1
    local Id = Library.OverlayIdCounter

    Table.Id = Id
    Table.OverlayType = OverlayType
    Table.OverlayName = Name or (OverlayType .. " #" .. Id)

    if not Table.SetVisible then
        function Table:SetVisible(Visible: boolean)
            local Root = Table.Holder or Table.Label or Table.Button or Table.Menu
            if Root then
                Root.Visible = Visible
            end
        end
    end

    if not Table.IsVisible then
        function Table:IsVisible(): boolean
            local Root = Table.Holder or Table.Label or Table.Button or Table.Menu
            return Root and Root.Visible or false
        end
    end

    if not Table.Remove then
        function Table:Remove()
            local Root = Table.Holder or Table.Label or Table.Button or Table.Menu
            if Root then
                Root:Destroy()
            end
        end
    end

    local BaseRemove = Table.Remove
    function Table:Remove()
        Library.Overlays[Id] = nil
        for Index, Entry in Library.OverlaysOrder do
            if Entry == Table then
                table.remove(Library.OverlaysOrder, Index)
                break
            end
        end
        BaseRemove(Table)
    end

    Library.Overlays[Id] = Table
    table.insert(Library.OverlaysOrder, Table)

    return Table
end

function Library:GetOverlay(Id: number)
    return Library.Overlays[Id]
end

function Library:GetOverlays(OverlayType: string?)
    if not OverlayType then
        return Library.OverlaysOrder
    end

    local Filtered = {}
    for _, Overlay in Library.OverlaysOrder do
        if Overlay.OverlayType == OverlayType then
            table.insert(Filtered, Overlay)
        end
    end
    return Filtered
end

function Library:SetOverlayVisible(Id: number, Visible: boolean)
    local Overlay = Library.Overlays[Id]
    if Overlay then
        Overlay:SetVisible(Visible)
    end
    return Overlay
end

function Library:ToggleOverlay(Id: number)
    local Overlay = Library.Overlays[Id]
    if Overlay then
        Overlay:SetVisible(not Overlay:IsVisible())
    end
    return Overlay
end

function Library:RemoveOverlay(Id: number)
    local Overlay = Library.Overlays[Id]
    if Overlay then
        Overlay:Remove()
    end
end

function Library:SetAllOverlaysVisible(Visible: boolean, OverlayType: string?)
    for _, Overlay in Library:GetOverlays(OverlayType) do
        Overlay:SetVisible(Visible)
    end
end

function Library:RemoveAllOverlays(OverlayType: string?)
    for _, Overlay in Library:GetOverlays(OverlayType) do
        Overlay:Remove()
    end
end

function Library:AddDraggableLabel(Text: string)
    local Table = {}

    local OwningScreenGui = ScreenGui

    local Label = New("TextLabel", {
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundColor3 = "BackgroundColor",
        Size = UDim2.fromOffset(0, 0),
        Position = UDim2.fromOffset(6, 6),
        Text = Text,
        TextSize = 15,
        ZIndex = Library.OverlayZIndex,
        Parent = OwningScreenGui,
    })
    table.insert(
        Library.Corners,
        New("UICorner", {
            CornerRadius = UDim.new(0, Library.CornerRadius),
            Parent = Label,
        })
    )
    New("UIPadding", {
        PaddingBottom = UDim.new(0, 6),
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
        PaddingTop = UDim.new(0, 6),
        Parent = Label,
    })
    Library:NewTrackedScale(Label)
    Library:AddOutline(Label)

    Library:MakeDraggable(Label, Label, true)

    Table.Label = Label

    function Table:SetText(Text: string)
        Label.Text = Text
    end

    function Table:SetVisible(Visible: boolean)
        Label.Visible = Visible
    end

    function Table:IsVisible(): boolean
        return Label.Visible
    end

    function Table:Remove()
        Label:Destroy()
    end

    Library:RegisterOverlay("DraggableLabel", Text, Table)

    return Table
end

function Library:AddDraggableButton(Text: string, Func, ExcludeScaling: boolean?)
    local Table = {}

    local OwningScreenGui = ScreenGui

    local Button = New("TextButton", {
        BackgroundColor3 = "BackgroundColor",
        Position = UDim2.fromOffset(6, 6),
        TextSize = 16,
        ZIndex = Library.OverlayZIndex,
        Parent = OwningScreenGui,
    })
    table.insert(
        Library.Corners,
        New("UICorner", {
            CornerRadius = UDim.new(0, Library.CornerRadius),
            Parent = Button,
        })
    )
    if not ExcludeScaling then
        Library:NewTrackedScale(Button)
    end
    Library:AddOutline(Button)

    Button.MouseButton1Click:Connect(function()
        Library:SafeCallback(Func, Table)
    end)
    Library:MakeDraggable(Button, Button, true)

    Table.Button = Button

    function Table:SetText(Text: string)
        local X, Y = Library:GetTextBounds(Text, Library.Scheme.Font, 16)

        Button.Text = Text
        Button.Size = UDim2.fromOffset(X * 2, Y * 2)
    end
    Table:SetText(Text)

    function Table:SetVisible(Visible: boolean)
        Button.Visible = Visible
    end

    function Table:IsVisible(): boolean
        return Button.Visible
    end

    function Table:Remove()
        Button:Destroy()
    end

    Library:RegisterOverlay("DraggableButton", Text, Table)

    return Table
end

function Library:AddDraggableToggle(Text: string, Default: boolean?, Callback)
    local Table = {}
    local OwningScreenGui = ScreenGui

    local Holder = New("Frame", {
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundColor3 = "BackgroundColor",
        Position = UDim2.fromOffset(6, 6),
        Size = UDim2.fromOffset(0, 0),
        ZIndex = Library.OverlayZIndex,
        Parent = OwningScreenGui,
    })
    table.insert(
        Library.Corners,
        New("UICorner", {
            CornerRadius = UDim.new(0, Library.CornerRadius),
            Parent = Holder,
        })
    )
    New("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 8),
        Parent = Holder,
    })
    New("UIPadding", {
        PaddingBottom = UDim.new(0, 6),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
        PaddingTop = UDim.new(0, 6),
        Parent = Holder,
    })
    Library:NewTrackedScale(Holder)
    Library:AddOutline(Holder)

    local Label = New("TextLabel", {
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundTransparency = 1,
        Text = Text,
        TextSize = 15,
        ZIndex = Library.OverlayZIndex,
        Parent = Holder,
    })

    local Switch = New("TextButton", {
        BackgroundColor3 = "MainColor",
        Size = UDim2.fromOffset(34, 18),
        Text = "",
        ZIndex = Library.OverlayZIndex,
        Parent = Holder,
    })
    table.insert(Library.Corners, New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Switch }))
    Library:AddOutline(Switch)

    local Dot = New("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = "FontColor",
        Position = UDim2.new(0, 2, 0.5, 0),
        Size = UDim2.fromOffset(14, 14),
        ZIndex = Library.OverlayZIndex + 1,
        Parent = Switch,
    })
    table.insert(Library.Corners, New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Dot }))

    Table.Value = Default == true

    local function Refresh()
        TweenService:Create(Dot, Library.TweenInfo, {
            Position = Table.Value and UDim2.new(1, -16, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
        }):Play()
        TweenService:Create(Switch, Library.TweenInfo, {
            BackgroundColor3 = Table.Value and Library.Scheme.AccentColor or Library.Scheme.MainColor,
        }):Play()
    end

    function Table:SetValue(Value: boolean)
        Table.Value = Value == true
        Refresh()
        Library:SafeCallback(Callback, Table.Value)
    end

    Switch.MouseButton1Click:Connect(function()
        Table:SetValue(not Table.Value)
    end)

    Library:MakeDraggable(Holder, Holder, true)
    Refresh()

    Table.Holder = Holder

    function Table:SetText(NewText: string)
        Label.Text = NewText
    end

    Library:RegisterOverlay("DraggableToggle", Text, Table)

    return Table
end

function Library:AddDraggableProgress(Text: string, Default: number?, Max: number?)
    local Table = {}
    local OwningScreenGui = ScreenGui

    local Holder = New("Frame", {
        BackgroundColor3 = "BackgroundColor",
        Position = UDim2.fromOffset(6, 6),
        Size = UDim2.fromOffset(180, 44),
        ZIndex = Library.OverlayZIndex,
        Parent = OwningScreenGui,
    })
    table.insert(
        Library.Corners,
        New("UICorner", {
            CornerRadius = UDim.new(0, Library.CornerRadius),
            Parent = Holder,
        })
    )
    Library:NewTrackedScale(Holder)
    Library:AddOutline(Holder)
    New("UIPadding", {
        PaddingBottom = UDim.new(0, 6),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
        PaddingTop = UDim.new(0, 6),
        Parent = Holder,
    })

    local Label = New("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 16),
        Text = Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = Library.OverlayZIndex,
        Parent = Holder,
    })

    local Track = New("Frame", {
        BackgroundColor3 = "MainColor",
        Position = UDim2.new(0, 0, 1, -10),
        Size = UDim2.new(1, 0, 0, 10),
        ZIndex = Library.OverlayZIndex,
        Parent = Holder,
    })
    table.insert(Library.Corners, New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Track }))
    Library:AddOutline(Track)

    local Fill = New("Frame", {
        BackgroundColor3 = "AccentColor",
        Size = UDim2.fromScale(0, 1),
        ZIndex = Library.OverlayZIndex + 1,
        Parent = Track,
    })
    table.insert(Library.Corners, New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Fill }))

    Table.Value = Default or 0
    Table.Max = Max or 100

    function Table:SetValue(Value: number)
        Table.Value = math.clamp(Value, 0, Table.Max)
        TweenService:Create(Fill, Library.TweenInfo, {
            Size = UDim2.fromScale(Table.Value / Table.Max, 1),
        }):Play()
    end
    Table:SetValue(Table.Value)

    function Table:SetText(NewText: string)
        Label.Text = NewText
    end

    Library:MakeDraggable(Holder, Holder, true)

    Table.Holder = Holder

    Library:RegisterOverlay("DraggableProgress", Text, Table)

    return Table
end

local BaseSection = {}

function Library:AddDraggableMenu(Name: string)

    local OwningScreenGui = ScreenGui

    local MenuWidth = 220
    local BaseZIndex = Library.OverlayZIndex

    local ControlsWidth = 62
    local TitleTextWidth = select(1, Library:GetTextBounds(Name, Library.Scheme.Font, 15))
    local ResolvedWidth = math.max(MenuWidth, math.ceil(TitleTextWidth) + 12 + ControlsWidth)

    local MaxWidth = 480

    local Holder = New("Frame", {
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = "BackgroundColor",
        Position = UDim2.fromOffset(6, 6),
        Size = UDim2.fromOffset(ResolvedWidth, 0),
        ZIndex = BaseZIndex,
        Parent = OwningScreenGui,
    })
    local SizeConstraint = New("UISizeConstraint", {

        MaxSize = Vector2.new(MaxWidth, 800),
        MinSize = Vector2.new(ResolvedWidth, 0),
        Parent = Holder,
    })
    table.insert(
        Library.Corners,
        New("UICorner", {
            CornerRadius = UDim.new(0, Library.CornerRadius),
            Parent = Holder,
        })
    )
    Library:NewTrackedScale(Holder)
    Library:AddOutline(Holder)

    New("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = Holder,
    })

    local LabelHolder = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 34),
        LayoutOrder = 1,
        ZIndex = BaseZIndex,
        Parent = Holder,
    })

    local Label = New("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Text = Name,
        TextSize = 15,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = BaseZIndex,
        Parent = LabelHolder,
    })
    New("UIPadding", {
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, ControlsWidth),
        Parent = Label,
    })

    local ControlsHolder = New("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -8, 0.5, 0),
        Size = UDim2.fromOffset(46, 20),
        ZIndex = BaseZIndex,
        Parent = LabelHolder,
    })
    New("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 6),
        Parent = ControlsHolder,
    })

    local function MakeTitleBarButton(IconName: string)
        local Btn = New("TextButton", {
            BackgroundColor3 = "MainColor",
            Size = UDim2.fromOffset(20, 20),
            Text = "",
            ZIndex = BaseZIndex,
            Parent = ControlsHolder,
        })
        table.insert(Library.Corners, New("UICorner", { CornerRadius = UDim.new(0, 5), Parent = Btn }))
        Library:AddOutline(Btn)
        local Icon = New("ImageLabel", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            ImageColor3 = "FontColor",
            ImageTransparency = 0.35,
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(11, 11),
            ZIndex = BaseZIndex,
            Parent = Btn,
        })

        Library:RegisterIconInstance(Icon, IconName)
        return Btn
    end

    local MinimizeBtn = MakeTitleBarButton("minus")
    MinimizeBtn.MouseEnter:Connect(function()
        TweenService:Create(MinimizeBtn, Library.TweenInfo, { BackgroundColor3 = Library:GetBetterColor(Library.Scheme.MainColor, 12) }):Play()
    end)
    MinimizeBtn.MouseLeave:Connect(function()
        TweenService:Create(MinimizeBtn, Library.TweenInfo, { BackgroundColor3 = Library.Scheme.MainColor }):Play()
    end)

    local CloseBtn = MakeTitleBarButton("x")
    CloseBtn.MouseEnter:Connect(function()
        TweenService:Create(CloseBtn, Library.TweenInfo, { BackgroundColor3 = Color3.fromRGB(200, 50, 50) }):Play()
    end)
    CloseBtn.MouseLeave:Connect(function()
        TweenService:Create(CloseBtn, Library.TweenInfo, { BackgroundColor3 = Library.Scheme.MainColor }):Play()
    end)

    local Separator = Library:MakeLine(LabelHolder, {
        Position = UDim2.fromOffset(0, 33),
        Size = UDim2.new(1, 0, 0, 1),
    })

    local Container = New("Frame", {
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        LayoutOrder = 2,
        ZIndex = BaseZIndex,
        Parent = Holder,
    })
    New("UIListLayout", {
        Padding = UDim.new(0, 7),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = Container,
    })
    local ContainerPadding = New("UIPadding", {
        PaddingBottom = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
        PaddingTop = UDim.new(0, 8),
        Parent = Container,
    })

    -- Measures the widest direct child of Container (each child is expected
    -- to be AutomaticSize.X, so AbsoluteSize.X reflects its natural width)
    -- and grows/shrinks Holder to fit it, clamped between the title-derived
    -- ResolvedWidth and MaxWidth.
    --
    -- IMPORTANT: Holder has a UIScale on it (see NewTrackedScale below), so
    -- Child.AbsoluteSize is already in SCREEN space (post-UIScale). Holder.Size
    -- is logical/BASE space (pre-UIScale). We must divide by the current scale
    -- factor before writing the measured width back into Holder.Size, or the
    -- UIScale will be applied to it a second time.
    local ResizeQueued = false
    local function RecalculateWidth()
        local ScaleFactor = math.max(Library.DPIScale or 1, 0.001)

        local WidestChildWidth = 0
        for _, Child in ipairs(Container:GetChildren()) do
            if Child:IsA("GuiObject") and Child.Visible then
                local LogicalWidth = Child.AbsoluteSize.X / ScaleFactor
                WidestChildWidth = math.max(WidestChildWidth, LogicalWidth)
            end
        end

        local ContentWidth = WidestChildWidth
            + ContainerPadding.PaddingLeft.Offset
            + ContainerPadding.PaddingRight.Offset

        local TargetWidth = math.clamp(math.max(ResolvedWidth, ContentWidth), ResolvedWidth, MaxWidth)

        SizeConstraint.MinSize = Vector2.new(TargetWidth, 0)
        Holder.Size = UDim2.fromOffset(TargetWidth, 0)
    end

    local function QueueResize()
        if ResizeQueued then
            return
        end
        ResizeQueued = true
        task.defer(function()
            ResizeQueued = false
            RecalculateWidth()
        end)
    end

    Container.ChildAdded:Connect(function(Child)
        QueueResize()
        if Child:IsA("GuiObject") then
            Child:GetPropertyChangedSignal("AbsoluteSize"):Connect(QueueResize)
            Child:GetPropertyChangedSignal("Visible"):Connect(QueueResize)
        end
    end)
    Container.ChildRemoved:Connect(QueueResize)

    Container.ZIndex = BaseZIndex + 100

    local MenuCollapsed = false
    local function SetMenuCollapsed(Collapsed: boolean)
        MenuCollapsed = Collapsed
        Container.Visible = not MenuCollapsed

        Separator.Visible = not MenuCollapsed
    end
    MinimizeBtn.MouseButton1Click:Connect(function()
        SetMenuCollapsed(not MenuCollapsed)
    end)
    CloseBtn.MouseButton1Click:Connect(function()
        Holder:Destroy()
    end)

    Library:MakeDraggable(Holder, LabelHolder, true)

    local ContainerObj = {
        Holder = Holder,
        Container = Container,
        Elements = {},
        ConditionalGroups = {},
    }
    function ContainerObj:Resize()
        RecalculateWidth()
    end

    function ContainerObj:SetCollapsed(Collapsed: boolean)
        SetMenuCollapsed(Collapsed)
    end
    function ContainerObj:ToggleCollapsed()
        SetMenuCollapsed(not MenuCollapsed)
    end
    function ContainerObj:Remove()
        Holder:Destroy()
    end
    function ContainerObj:SetVisible(Visible: boolean)
        Holder.Visible = Visible
    end
    function ContainerObj:IsVisible(): boolean
        return Holder.Visible
    end
    setmetatable(ContainerObj, BaseSection)

    Library:RegisterOverlay("DraggableMenu", Name, ContainerObj)

    return Holder, Container, ContainerObj
end

local CurrentMenu
function Library:AddContextMenu(
    Holder: GuiObject,
    Size: UDim2 | () -> (),
    Offset: { [number]: number } | () -> {},
    List: number?,
    ActiveCallback: (Active: boolean) -> ()?,
    IgnoreCornerRadius: boolean?
)
    local Menu

    local ParentGui = Holder:FindFirstAncestorOfClass("ScreenGui")
    if not ParentGui or (ParentGui ~= ScreenGui and not (Library.ActiveLoading and ParentGui == Library.ActiveLoading.ScreenGui)) then
        ParentGui = (Library.ActiveLoading and Library.ActiveLoading.ScreenGui) or ScreenGui
    end

    if List then
        Menu = New("ScrollingFrame", {
            AutomaticCanvasSize = List == 2 and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
            AutomaticSize = List == 1 and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
            BackgroundColor3 = "BackgroundColor",
            BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
            CanvasSize = UDim2.fromOffset(0, 0),
            ScrollBarImageColor3 = "OutlineColor",
            ScrollBarThickness = List == 2 and 2 or 0,
            Size = typeof(Size) == "function" and Size() or Size,
            TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
            Visible = false,
            ZIndex = Library.OverlayZIndex,
            Parent = ParentGui,
        })
    else
        Menu = New("Frame", {
            BackgroundColor3 = "BackgroundColor",
            Size = typeof(Size) == "function" and Size() or Size,
            Visible = false,
            ZIndex = Library.OverlayZIndex,
            Parent = ParentGui,
        })
    end
    Library:NewTrackedScale(Menu)

    New("UIStroke", {
        Color = "OutlineColor",
        Parent = Menu,
    })

    if IgnoreCornerRadius ~= true then
        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                Parent = Menu,
            })
        )
    end

    local Table = {
        Active = false,
        Holder = Holder,
        Menu = Menu,
        List = nil,
        Signal = nil,

        Size = Size,
    }

    if List then
        Table.List = New("UIListLayout", {
            Parent = Menu,
        })
    end

    function Table:Open()
        if CurrentMenu == Table then
            return
        elseif CurrentMenu then
            CurrentMenu:Close()
        end

        CurrentMenu = Table
        Table.Active = true

        if typeof(Offset) == "function" then
            Menu.Position = UDim2.fromOffset(
                math.floor(Holder.AbsolutePosition.X + Offset()[1]),
                math.floor(Holder.AbsolutePosition.Y + Offset()[2])
            )
        else
            Menu.Position = UDim2.fromOffset(
                math.floor(Holder.AbsolutePosition.X + Offset[1]),
                math.floor(Holder.AbsolutePosition.Y + Offset[2])
            )
        end
        Menu.Size = typeof(Table.Size) == "function" and Table.Size() or Table.Size
        if typeof(ActiveCallback) == "function" then
            Library:SafeCallback(ActiveCallback, true)
        end

        Menu.Visible = true

        Table.Signal = Holder:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
            if typeof(Offset) == "function" then
                Menu.Position = UDim2.fromOffset(
                    math.floor(Holder.AbsolutePosition.X + Offset()[1]),
                    math.floor(Holder.AbsolutePosition.Y + Offset()[2])
                )
            else
                Menu.Position = UDim2.fromOffset(
                    math.floor(Holder.AbsolutePosition.X + Offset[1]),
                    math.floor(Holder.AbsolutePosition.Y + Offset[2])
                )
            end
        end)
    end

    function Table:Close()
        if CurrentMenu ~= Table then
            return
        end
        Menu.Visible = false

        if Table.Signal then
            Table.Signal:Disconnect()
            Table.Signal = nil
        end
        Table.Active = false
        CurrentMenu = nil
        if typeof(ActiveCallback) == "function" then
            Library:SafeCallback(ActiveCallback, false)
        end
    end

    function Table:Toggle()
        if Table.Active then
            Table:Close()
        else
            Table:Open()
        end
    end

    function Table:SetSize(Size)
        Table.Size = Size
        Menu.Size = typeof(Size) == "function" and Size() or Size
    end

    function Table:SetVisible(Visible: boolean)
        if Visible then
            Table:Open()
        else
            Table:Close()
        end
    end

    function Table:IsVisible(): boolean
        return Table.Active
    end

    function Table:Remove()
        if CurrentMenu == Table then
            Table:Close()
        end
        Menu:Destroy()
    end

    Library:RegisterOverlay("ContextMenu", nil, Table)

    return Table
end

Library:GiveSignal(UserInputService.InputBegan:Connect(function(Input: InputObject)
    if Library.Unloaded then
        return
    end

    if IsClickInput(Input, true) then
        local Location = Input.Position

        if
            CurrentMenu
            and not (
                Library:MouseIsOverFrame(CurrentMenu.Menu, Location)
                or Library:MouseIsOverFrame(CurrentMenu.Holder, Location)
            )
        then
            CurrentMenu:Close()
        end
    end
end))

local TooltipLabel = New("TextLabel", {
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundColor3 = "BackgroundColor",
    TextSize = 14,
    TextWrapped = true,
    Visible = false,
    ZIndex = 20,
    Parent = ScreenGui,
})
New("UIPadding", {
    PaddingBottom = UDim.new(0, 2),
    PaddingLeft = UDim.new(0, 4),
    PaddingRight = UDim.new(0, 4),
    PaddingTop = UDim.new(0, 2),
    Parent = TooltipLabel,
})
table.insert(
    Library.Scales,
    New("UIScale", {
        Parent = TooltipLabel,
    })
)
New("UIStroke", {
    Color = "OutlineColor",
    Parent = TooltipLabel,
})
table.insert(
    Library.Corners,
    New("UICorner", {
        CornerRadius = UDim.new(0, Library.CornerRadius / 2),
        Parent = TooltipLabel,
    })
)
TooltipLabel:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
    if Library.Unloaded then
        return
    end

    local X, _ = Library:GetTextBounds(
        TooltipLabel.Text,
        TooltipLabel.FontFace,
        TooltipLabel.TextSize,
        (workspace.CurrentCamera.ViewportSize.X - TooltipLabel.AbsolutePosition.X - 8) / Library.DPIScale
    )

    TooltipLabel.Size = UDim2.fromOffset(X + 8)
end)

local CurrentHoverInstance
function Library:AddTooltip(InfoStr: string, DisabledInfoStr: string, HoverInstance: GuiObject)
    local TooltipTable = {
        Disabled = false,
        Hovering = false,
        Signals = {},
    }

    local function DoHover()
        if
            CurrentHoverInstance == HoverInstance
            or Library.ActiveDialog
            or (CurrentMenu and Library:MouseIsOverFrame(CurrentMenu.Menu, Mouse))
            or (TooltipTable.Disabled and typeof(DisabledInfoStr) ~= "string")
            or (not TooltipTable.Disabled and typeof(InfoStr) ~= "string")
        then
            return
        end
        CurrentHoverInstance = HoverInstance

        local ParentGui = HoverInstance:FindFirstAncestorOfClass("ScreenGui")
        if ParentGui ~= ScreenGui and (Library.ActiveLoading and ParentGui ~= Library.ActiveLoading.ScreenGui) then
            ParentGui = ScreenGui
        end
        TooltipLabel.Parent = ParentGui

        TooltipLabel.Text = TooltipTable.Disabled and DisabledInfoStr or InfoStr
        TooltipLabel.Visible = true

        while
            (Library.Toggled or Library.ActiveLoading)
            and not Library.ActiveDialog
            and Library:MouseIsOverFrame(HoverInstance, Mouse)
            and not (CurrentMenu and Library:MouseIsOverFrame(CurrentMenu.Menu, Mouse))
        do
            TooltipLabel.Position = UDim2.fromOffset(
                Mouse.X + (Library.ShowCustomCursor and 8 or 14),
                Mouse.Y + (Library.ShowCustomCursor and 8 or 12)
            )

            RunService.RenderStepped:Wait()
        end

        TooltipLabel.Visible = false
        CurrentHoverInstance = nil
    end

    local function GiveSignal(Connection: RBXScriptConnection | RBXScriptSignal)
        local ConnectionType = typeof(Connection)
        if Connection and (ConnectionType == "RBXScriptConnection" or ConnectionType == "RBXScriptSignal") then
            table.insert(TooltipTable.Signals, Connection)
        end

        return Connection
    end

    GiveSignal(HoverInstance.MouseEnter:Connect(DoHover))
    GiveSignal(HoverInstance.MouseMoved:Connect(DoHover))
    GiveSignal(HoverInstance.MouseLeave:Connect(function()
        if CurrentHoverInstance ~= HoverInstance then
            return
        end

        TooltipLabel.Visible = false
        CurrentHoverInstance = nil
    end))

    function TooltipTable:Destroy()
        for Index = #TooltipTable.Signals, 1, -1 do
            local Connection = table.remove(TooltipTable.Signals, Index)
            if Connection and Connection.Connected then
                Connection:Disconnect()
            end
        end

        if CurrentHoverInstance == HoverInstance then
            if TooltipLabel then
                TooltipLabel.Visible = false
            end

            CurrentHoverInstance = nil
        end
    end

    table.insert(Tooltips, TooltipTable)
    return TooltipTable
end

function Library:OnUnload(Callback)
    table.insert(Library.UnloadSignals, Callback)
end

function Library:Unload()
    for Index = #Library.Signals, 1, -1 do
        local Connection = table.remove(Library.Signals, Index)
        if Connection and Connection.Connected then
            Connection:Disconnect()
        end
    end

    Library.AutoDPIScaleConnection = nil

    for _, Callback in Library.UnloadSignals do
        Library:SafeCallback(Callback)
    end

    for _, Tooltip in Tooltips do
        Library:SafeCallback(Tooltip.Destroy, Tooltip)
    end

    Library.Unloaded = true

    if Library.ActiveLoading then
        Library.ActiveLoading:Destroy()
    end

    if ScreenGui then
        ScreenGui:Destroy()
    end

    getgenv().Library = nil
end

local CheckIcon = Library:GetIcon("check")
local ArrowIcon = Library:GetIcon("chevron-up")
local ResizeIcon = Library:GetIcon("move-diagonal-2")
local KeyIcon = Library:GetIcon("key")
local MoveIcon = Library:GetIcon("move")
local EditIcon = Library:GetIcon("pencil")

if not Library:AreIconsLoaded() then
    task.spawn(function()
        Library:WaitForIcons()

        CheckIcon = Library:GetIcon("check")
        ArrowIcon = Library:GetIcon("chevron-up")
        ResizeIcon = Library:GetIcon("move-diagonal-2")
        KeyIcon = Library:GetIcon("key")
        MoveIcon = Library:GetIcon("move")
        EditIcon = Library:GetIcon("pencil")

        if Library.RefreshIcons then
            Library:RefreshIcons()
        end
    end)
end

function Library:SetIconModule(module: IconModule)
    FetchIcons = true
    Icons = module

    CheckIcon = Library:GetIcon("check")
    ArrowIcon = Library:GetIcon("chevron-up")
    ResizeIcon = Library:GetIcon("move-diagonal-2")
    KeyIcon = Library:GetIcon("key")
    MoveIcon = Library:GetIcon("move")
    EditIcon = Library:GetIcon("pencil")
end

local BaseAddons = {}
do
    local Funcs = {}

    function Funcs:AddKeyPicker(Idx, Info)
        Info = Library:Validate(Info, Templates.KeyPicker)

        local ParentObj = self
        local ToggleLabel = ParentObj.TextLabel

        local KeyPicker = {
            Text = Info.Text,
            Value = Info.Default,
            Modifiers = Info.DefaultModifiers,
            DisplayValue = Info.Default,

            Blacklisted = Info.Blacklisted,
            BlacklistedModifiers = Info.BlacklistedModifiers,
            Whitelisted = Info.Whitelisted,
            WhitelistedModifiers = Info.WhitelistedModifiers,

            Toggled = false,
            Mode = Info.Mode,
            SyncToggleState = Info.SyncToggleState,

            Callback = Info.Callback,
            ChangedCallback = Info.ChangedCallback,
            Changed = Info.Changed,
            Clicked = Info.Clicked,

            Type = "KeyPicker",
        }

        if KeyPicker.Mode == "Press" then
            assert(ParentObj.Type == "Label", "KeyPicker with the mode 'Press' can be only applied on Labels.")

            KeyPicker.SyncToggleState = false
            Info.Modes = { "Press" }
            Info.Mode = "Press"
        end

        if KeyPicker.SyncToggleState then
            Info.Modes = { "Toggle", "Hold" }

            if not table.find(Info.Modes, Info.Mode) then
                Info.Mode = "Toggle"
            end
        end

        local Picking = false

        local SpecialKeys = {
            ["MB1"] = Enum.UserInputType.MouseButton1,
            ["MB2"] = Enum.UserInputType.MouseButton2,
            ["MB3"] = Enum.UserInputType.MouseButton3,
        }

        local SpecialKeysInput = {
            [Enum.UserInputType.MouseButton1] = "MB1",
            [Enum.UserInputType.MouseButton2] = "MB2",
            [Enum.UserInputType.MouseButton3] = "MB3",
        }

        local Modifiers = {
            ["LAlt"] = Enum.KeyCode.LeftAlt,
            ["RAlt"] = Enum.KeyCode.RightAlt,

            ["LCtrl"] = Enum.KeyCode.LeftControl,
            ["RCtrl"] = Enum.KeyCode.RightControl,

            ["LShift"] = Enum.KeyCode.LeftShift,
            ["RShift"] = Enum.KeyCode.RightShift,

            ["Tab"] = Enum.KeyCode.Tab,
            ["CapsLock"] = Enum.KeyCode.CapsLock,
        }

        local ModifiersInput = {
            [Enum.KeyCode.LeftAlt] = "LAlt",
            [Enum.KeyCode.RightAlt] = "RAlt",

            [Enum.KeyCode.LeftControl] = "LCtrl",
            [Enum.KeyCode.RightControl] = "RCtrl",

            [Enum.KeyCode.LeftShift] = "LShift",
            [Enum.KeyCode.RightShift] = "RShift",

            [Enum.KeyCode.Tab] = "Tab",
            [Enum.KeyCode.CapsLock] = "CapsLock",
        }

        local IsModifierInput = function(Input)
            return Input.UserInputType == Enum.UserInputType.Keyboard and ModifiersInput[Input.KeyCode] ~= nil
        end

        local GetActiveModifiers = function()
            local ActiveModifiers = {}

            for Name, Input in Modifiers do
                if table.find(ActiveModifiers, Name) then
                    continue
                end
                if not UserInputService:IsKeyDown(Input) then
                    continue
                end

                table.insert(ActiveModifiers, Name)
            end

            return ActiveModifiers
        end

        local AreModifiersHeld = function(Required)
            if not (typeof(Required) == "table" and GetTableSize(Required) > 0) then
                return true
            end

            local ActiveModifiers = GetActiveModifiers()
            local Holding = true

            for _, Name in Required do
                if table.find(ActiveModifiers, Name) then
                    continue
                end

                Holding = false
                break
            end

            return Holding
        end

        local IsInputDown = function(Input)
            if not Input then
                return false
            end

            if SpecialKeysInput[Input.UserInputType] ~= nil then
                return UserInputService:IsMouseButtonPressed(Input.UserInputType)
                    and not UserInputService:GetFocusedTextBox()
            elseif Input.UserInputType == Enum.UserInputType.Keyboard then
                return UserInputService:IsKeyDown(Input.KeyCode) and not UserInputService:GetFocusedTextBox()
            else
                return false
            end
        end

        local ConvertToInputModifiers = function(CurrentModifiers)
            local InputModifiers = {}

            for _, name in CurrentModifiers do
                table.insert(InputModifiers, Modifiers[name])
            end

            return InputModifiers
        end

        local VerifyModifiers = function(CurrentModifiers)
            if typeof(CurrentModifiers) ~= "table" then
                return {}
            end

            local ValidModifiers = {}

            for _, name in CurrentModifiers do
                if not Modifiers[name] then
                    continue
                end

                table.insert(ValidModifiers, name)
            end

            return ValidModifiers
        end

        KeyPicker.Modifiers = VerifyModifiers(KeyPicker.Modifiers)

        local PickerGapTrim = -1
        local Picker = New("TextButton", {
            AnchorPoint = Vector2.new(1, 0.5),
            BackgroundColor3 = "MainColor",
            Position = UDim2.new(1, -PickerGapTrim, 0.5, 0),
            Size = UDim2.fromOffset(18, 18),
            Text = KeyPicker.Value,
            TextSize = 14,
            Parent = ToggleLabel,
        })

        New("UIStroke", {
            Color = "OutlineColor",
            Parent = Picker,
        })

        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                Parent = Picker,
            })
        )

        local KeybindsToggle = { Normal = KeyPicker.Mode ~= "Toggle" }
        do
            local Holder = New("TextButton", {
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundTransparency = 1,
                Size = UDim2.new(0, 0, 0, 16),
                Text = "",
                Visible = not Info.NoUI,
                Parent = Library.KeybindContainer,
            })

            local Label = New("TextLabel", {
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(0, 1),
                Text = "",
                TextSize = 14,
                TextTransparency = 0.5,
                Parent = Holder,
            })

            local Checkbox = New("Frame", {
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundColor3 = "MainColor",
                Position = UDim2.fromScale(0, 0.5),
                Size = UDim2.fromOffset(14, 14),
                SizeConstraint = Enum.SizeConstraint.RelativeYY,
                Parent = Holder,
            })
            table.insert(
                Library.Corners,
                New("UICorner", {
                    CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                    Parent = Checkbox,
                })
            )
            New("UIStroke", {
                Color = "OutlineColor",
                Parent = Checkbox,
            })

            local CheckImage = New("ImageLabel", {
                Image = CheckIcon and CheckIcon.Url or "",
                ImageColor3 = "FontColor",
                ImageRectOffset = CheckIcon and CheckIcon.ImageRectOffset or Vector2.zero,
                ImageRectSize = CheckIcon and CheckIcon.ImageRectSize or Vector2.zero,
                ImageTransparency = 1,
                Position = UDim2.fromOffset(2, 2),
                Size = UDim2.new(1, -4, 1, -4),
                Parent = Checkbox,
            })
            Library:RegisterIconInstance(CheckImage, "check")

            function KeybindsToggle:Display(State)
                Label.TextTransparency = State and 0 or 0.5
                CheckImage.ImageTransparency = State and 0 or 1
            end

            function KeybindsToggle:SetText(Text)
                Label.Text = Text
            end

            function KeybindsToggle:SetVisibility(Visibility)
                Holder.Visible = Visibility
            end

            function KeybindsToggle:SetNormal(Normal)
                KeybindsToggle.Normal = Normal

                Holder.Active = not Normal
                Label.Position = Normal and UDim2.fromOffset(0, 0) or UDim2.fromOffset(22, 0)
                Checkbox.Visible = not Normal
            end

            KeyPicker.DoClick = function(...) end
            Holder.MouseButton1Click:Connect(function()
                if KeybindsToggle.Normal then
                    return
                end

                KeyPicker.Toggled = not KeyPicker.Toggled
                KeyPicker:DoClick()
            end)

            KeybindsToggle.Holder = Holder
            KeybindsToggle.Label = Label
            KeybindsToggle.Checkbox = Checkbox
            KeybindsToggle.Loaded = true
            table.insert(Library.KeybindToggles, KeybindsToggle)
        end

        local MenuTable = Library:AddContextMenu(Picker, UDim2.fromOffset(62, 0), function()
            return { Picker.AbsoluteSize.X + 1.5, 0.5 }
        end, 1, nil, true)
        KeyPicker.Menu = MenuTable

        local ModeButtons = {}
        for _, Mode in Info.Modes do
            local ModeButton = {}

            local Button = New("TextButton", {
                BackgroundColor3 = "MainColor",
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 21),
                Text = Mode,
                TextSize = 14,
                TextTransparency = 0.5,
                Parent = MenuTable.Menu,
            })

            function ModeButton:Select()
                for _, Button in ModeButtons do
                    Button:Deselect()
                end

                KeyPicker.Mode = Mode

                Button.BackgroundTransparency = 0
                Button.TextTransparency = 0

                MenuTable:Close()
            end

            function ModeButton:Deselect()
                KeyPicker.Mode = nil

                Button.BackgroundTransparency = 1
                Button.TextTransparency = 0.5
            end

            Button.MouseButton1Click:Connect(function()
                ModeButton:Select()
            end)

            if KeyPicker.Mode == Mode then
                ModeButton:Select()
            end

            ModeButtons[Mode] = ModeButton
        end

        function KeyPicker:Display(PickerText)
            if Library.Unloaded then
                return
            end

            local X, Y = Library:GetTextBounds(
                PickerText or KeyPicker.DisplayValue,
                Picker.FontFace,
                Picker.TextSize,
                ToggleLabel.AbsoluteSize.X
            )
            Picker.Text = PickerText or KeyPicker.DisplayValue
            Picker.Size = UDim2.fromOffset((X + 9), (Y + 4))
        end

        function KeyPicker:Update()
            KeyPicker:Display()

            if Info.NoUI then
                return
            end

            if KeyPicker.Mode == "Toggle" and ParentObj.Type == "Toggle" and ParentObj.Disabled then
                KeybindsToggle:SetVisibility(false)
                return
            end

            local State = KeyPicker:GetState()
            local ShowToggle = Library.ShowToggleFrameInKeybinds and KeyPicker.Mode == "Toggle"

            if KeyPicker.SyncToggleState and ParentObj.Value ~= State then
                ParentObj:SetValue(State)
            end

            if KeybindsToggle.Loaded then
                if ShowToggle then
                    KeybindsToggle:SetNormal(false)
                else
                    KeybindsToggle:SetNormal(true)
                end

                KeybindsToggle:SetText(("[%s] %s (%s)"):format(KeyPicker.DisplayValue, KeyPicker.Text, KeyPicker.Mode))
                KeybindsToggle:SetVisibility(true)
                KeybindsToggle:Display(State)
            end
        end

        function KeyPicker:GetState()
            if KeyPicker.Mode == "Always" then
                return true
            elseif KeyPicker.Mode == "Hold" then
                local Key = KeyPicker.Value
                if Key == "None" then
                    return false
                end

                if not AreModifiersHeld(KeyPicker.Modifiers) then
                    return false
                end

                if SpecialKeys[Key] ~= nil then
                    return UserInputService:IsMouseButtonPressed(SpecialKeys[Key])
                        and not UserInputService:GetFocusedTextBox()
                else
                    return UserInputService:IsKeyDown(Enum.KeyCode[Key]) and not UserInputService:GetFocusedTextBox()
                end
            else
                return KeyPicker.Toggled
            end
        end

        function KeyPicker:OnChanged(Func)
            KeyPicker.Changed = Func
        end

        function KeyPicker:OnClick(Func)
            KeyPicker.Clicked = Func
        end

        function KeyPicker:DoClick()
            if KeyPicker.Mode == "Press" then
                if KeyPicker.Toggled and Info.WaitForCallback == true then
                    return
                end

                KeyPicker.Toggled = true
            end

            Library:SafeCallback(KeyPicker.Callback, KeyPicker.Toggled)
            Library:SafeCallback(KeyPicker.Clicked, KeyPicker.Toggled)

            if KeyPicker.Mode == "Press" then
                KeyPicker.Toggled = false
            end
        end

        function KeyPicker:SetValue(Data)

            local Key = Data.Key ~= nil and Data.Key or Data[1]
            local Mode = Data.Mode ~= nil and Data.Mode or Data[2]
            local Modifiers = Data.Modifiers ~= nil and Data.Modifiers or Data[3]

            Mode = Mode or KeyPicker.Mode

            local IsKeyValid, KeyCode = pcall(function()
                if Key == "None" then
                    Key = nil
                    return nil
                end

                if SpecialKeys[Key] == nil then
                    return Enum.KeyCode[Key]
                end

                return SpecialKeys[Key]
            end)

            if Key == nil then
                KeyPicker.Value = "None"
            elseif IsKeyValid then
                KeyPicker.Value = Key
            else
                KeyPicker.Value = "Unknown"
            end

            KeyPicker.Modifiers =
                VerifyModifiers(if typeof(Modifiers) == "table" then Modifiers else KeyPicker.Modifiers)
            KeyPicker.DisplayValue = if GetTableSize(KeyPicker.Modifiers) > 0
                then (table.concat(KeyPicker.Modifiers, " + ") .. " + " .. KeyPicker.Value)
                else KeyPicker.Value

            if ModeButtons[Mode] then
                ModeButtons[Mode]:Select()
            end

            local NewModifiers = ConvertToInputModifiers(KeyPicker.Modifiers)
            Library:SafeCallback(KeyPicker.ChangedCallback, KeyCode, NewModifiers)
            Library:SafeCallback(KeyPicker.Changed, KeyCode, NewModifiers)

            KeyPicker:Update()
        end

        function KeyPicker:SetText(Text)
            KeybindsToggle:SetText(Text)
            KeyPicker:Update()
        end

        Picker.MouseButton1Click:Connect(function()
            if Picking then
                return
            end

            Picking = true

            Picker.Text = "..."
            Picker.Size = UDim2.fromOffset(29, 18)

            local Input
            local ActiveModifiers = {}

            local GetInput = nil; GetInput = function()
                Input = UserInputService.InputBegan:Wait()
                if UserInputService:GetFocusedTextBox() ~= nil then
                    return true
                end

                if Input.KeyCode == Enum.KeyCode.Escape then
                    return false
                end

                local IsMod = IsModifierInput(Input)
                local KeyName
                if SpecialKeysInput[Input.UserInputType] ~= nil then
                    KeyName = SpecialKeysInput[Input.UserInputType]
                elseif Input.UserInputType == Enum.UserInputType.Keyboard then
                    if IsMod then
                        KeyName = ModifiersInput[Input.KeyCode]
                    else
                        KeyName = Input.KeyCode.Name
                    end
                end

                if KeyName then
                    if IsMod then
                        if KeyPicker.WhitelistedModifiers and #KeyPicker.WhitelistedModifiers > 0 and not table.find(KeyPicker.WhitelistedModifiers, KeyName) then
                            return GetInput()
                        end

                        if KeyPicker.BlacklistedModifiers and table.find(KeyPicker.BlacklistedModifiers, KeyName) then
                            return GetInput()
                        end
                    else
                        if KeyPicker.Whitelisted and #KeyPicker.Whitelisted > 0 and not table.find(KeyPicker.Whitelisted, KeyName) then
                            return GetInput()
                        end

                        if KeyPicker.Blacklisted and table.find(KeyPicker.Blacklisted, KeyName) then
                            return GetInput()
                        end
                    end
                end

                return false
            end

            repeat
                task.wait()

                Picker.Text = "..."
                Picker.Size = UDim2.fromOffset(29, 18)

                if GetInput() then
                    Picking = false
                    KeyPicker:Update()
                    return
                end

                if Input.KeyCode == Enum.KeyCode.Escape then
                    break
                end

                if IsModifierInput(Input) then
                    local StopLoop = false

                    repeat
                        task.wait()
                        if UserInputService:IsKeyDown(Input.KeyCode) then
                            task.wait(0.075)

                            if UserInputService:IsKeyDown(Input.KeyCode) then

                                if not table.find(ActiveModifiers, ModifiersInput[Input.KeyCode]) then
                                    ActiveModifiers[#ActiveModifiers + 1] = ModifiersInput[Input.KeyCode]
                                    KeyPicker:Display(table.concat(ActiveModifiers, " + ") .. " + ...")
                                end

                                if GetInput() then
                                    StopLoop = true
                                    break
                                end

                                if Input.KeyCode == Enum.KeyCode.Escape then
                                    break
                                end

                                if not IsModifierInput(Input) then
                                    break
                                end
                            else
                                if not table.find(ActiveModifiers, ModifiersInput[Input.KeyCode]) then
                                    break
                                end
                            end
                        end
                    until false

                    if StopLoop then
                        Picking = false
                        KeyPicker:Update()
                        return
                    end
                end

                break
            until false

            local Key = "Unknown"
            if SpecialKeysInput[Input.UserInputType] ~= nil then
                Key = SpecialKeysInput[Input.UserInputType]
            elseif Input.UserInputType == Enum.UserInputType.Keyboard then
                Key = Input.KeyCode == Enum.KeyCode.Escape and "None" or Input.KeyCode.Name
            end

            ActiveModifiers = if Input.KeyCode == Enum.KeyCode.Escape or Key == "Unknown" then {} else ActiveModifiers

            KeyPicker.Toggled = false
            KeyPicker:SetValue({ Key, KeyPicker.Mode, ActiveModifiers })

            repeat
                task.wait()
            until not IsInputDown(Input) or UserInputService:GetFocusedTextBox()
            Picking = false
        end)
        Picker.MouseButton2Click:Connect(MenuTable.Toggle)

        Library:GiveSignal(UserInputService.InputBegan:Connect(function(Input: InputObject)
            if Library.Unloaded then
                return
            end

            if
                KeyPicker.Mode == "Always"
                or KeyPicker.Value == "Unknown"
                or KeyPicker.Value == "None"
                or Picking
                or UserInputService:GetFocusedTextBox()
            then
                return
            end

            local Key = KeyPicker.Value
            local HoldingModifiers = AreModifiersHeld(KeyPicker.Modifiers)
            local HoldingKey = false

            if
                Key
                and HoldingModifiers == true
                and (
                    SpecialKeysInput[Input.UserInputType] == Key
                    or (Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode.Name == Key)
                )
            then
                HoldingKey = true
            end

            if KeyPicker.Mode == "Toggle" then
                if HoldingKey then
                    KeyPicker.Toggled = not KeyPicker.Toggled
                    KeyPicker:DoClick()
                end
            elseif KeyPicker.Mode == "Press" then
                if HoldingKey then
                    KeyPicker:DoClick()
                end
            end

            KeyPicker:Update()
        end))

        Library:GiveSignal(UserInputService.InputEnded:Connect(function()
            if Library.Unloaded then
                return
            end

            if
                KeyPicker.Value == "Unknown"
                or KeyPicker.Value == "None"
                or Picking
                or UserInputService:GetFocusedTextBox()
            then
                return
            end

            KeyPicker:Update()
        end))

        KeyPicker:Update()

        KeyPicker.Holder = Picker

        if ParentObj.Addons then
            table.insert(ParentObj.Addons, KeyPicker)
        end

        KeyPicker.Default = KeyPicker.Value
        KeyPicker.DefaultModifiers = table.clone(KeyPicker.Modifiers or {})

        Options[Idx] = KeyPicker

        return KeyPicker
    end

    local HueSequenceTable = {}
    for Hue = 0, 1, 0.1 do
        table.insert(HueSequenceTable, ColorSequenceKeypoint.new(Hue, Color3.fromHSV(Hue, 1, 1)))
    end
    function Funcs:AddColorPicker(Idx, Info)
        Info = Library:Validate(Info, Templates.ColorPicker)

        local ParentObj = self
        local ToggleLabel = ParentObj.TextLabel

        local ColorPicker = {
            Value = Info.Default,

            Transparency = Info.Transparency or 0,
            Title = Info.Title,

            Callback = Info.Callback,
            Changed = Info.Changed,

            Type = "ColorPicker",
        }
        ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = ColorPicker.Value:ToHSV()

        local SwatchGapTrim = -1
        local Holder = New("TextButton", {
            AnchorPoint = Vector2.new(1, 0.5),
            BackgroundColor3 = ColorPicker.Value,
            ClipsDescendants = true,
            Position = UDim2.new(1, -SwatchGapTrim, 0.5, 0),
            Size = UDim2.fromOffset(18, 18),
            Text = "",
            Parent = ToggleLabel,
        })

        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                Parent = Holder,
            })
        )

        local HolderBackground = New("Frame", {
            BackgroundColor3 = Color3.new(1, 1, 1),
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.fromScale(1, 1),
            Parent = Holder,
        })

        local HolderColor = New("Frame", {
            BackgroundColor3 = ColorPicker.Value,
            BackgroundTransparency = ColorPicker.Transparency,
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.fromScale(1, 1),
            Parent = HolderBackground,
        })

        local HolderStroke = New("UIStroke", {
            Color = Library:GetDarkerColor(ColorPicker.Value),
            Thickness = 1,
            Parent = Holder,
        })

        local SectionContainer = ParentObj.Container

        local ColorPanelOpen = false

        local InlinePanel = New("Frame", {
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = "BackgroundColor",
            Size = UDim2.new(1, 0, 0, 0),
            Visible = false,
            Parent = SectionContainer,
        })

        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                Parent = InlinePanel,
            })
        )
        Library:AddOutline(InlinePanel)
        New("UIListLayout", {
            Padding = UDim.new(0, 6),
            Parent = InlinePanel,
        })
        New("UIPadding", {
            PaddingTop = UDim.new(0, 8),
            PaddingBottom = UDim.new(0, 8),
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
            Parent = InlinePanel,
        })

        local function ResizeOwner()
            if ParentObj.Section then
                ParentObj.Section:Resize()
            elseif type(ParentObj.Resize) == "function" then
                ParentObj:Resize()
            end
        end

        local function OpenColorPanel()
            if ColorPanelOpen then return end
            ColorPanelOpen = true
            InlinePanel.Visible = true
            ResizeOwner()
        end
        local function CloseColorPanel()
            if not ColorPanelOpen then return end
            ColorPanelOpen = false
            InlinePanel.Visible = false
            ResizeOwner()
        end

        local OutsideClickConn
        local function StartWatchingOutsideClicks()
            if OutsideClickConn then return end
            OutsideClickConn = UserInputService.InputBegan:Connect(function(Input, GameProcessed)
                if GameProcessed then return end
                if Input.UserInputType ~= Enum.UserInputType.MouseButton1
                    and Input.UserInputType ~= Enum.UserInputType.Touch then
                    return
                end
                if not ColorPanelOpen then return end

                local MousePos = UserInputService:GetMouseLocation()
                local PanelPos, PanelSize = InlinePanel.AbsolutePosition, InlinePanel.AbsoluteSize
                local WithinPanel = MousePos.X >= PanelPos.X and MousePos.X <= PanelPos.X + PanelSize.X
                    and MousePos.Y >= PanelPos.Y and MousePos.Y <= PanelPos.Y + PanelSize.Y

                local HolderPos, HolderSize = Holder.AbsolutePosition, Holder.AbsoluteSize
                local WithinSwatch = MousePos.X >= HolderPos.X and MousePos.X <= HolderPos.X + HolderSize.X
                    and MousePos.Y >= HolderPos.Y and MousePos.Y <= HolderPos.Y + HolderSize.Y

                if not WithinPanel and not WithinSwatch then
                    CloseColorPanel()
                end
            end)
        end
        StartWatchingOutsideClicks()

        local ColorMenu = {}
        function ColorMenu:Toggle()
            if ColorPanelOpen then CloseColorPanel() else OpenColorPanel() end
        end
        function ColorMenu:Close() CloseColorPanel() end
        function ColorMenu:Open() OpenColorPanel() end
        ColorPicker.ColorMenu = ColorMenu

        local HasTitle = typeof(ColorPicker.Title) == "string"
        if HasTitle then
            New("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 14),
                Text = ColorPicker.Title,
                TextColor3 = "FontColor",
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = InlinePanel,
            })
        end

        local ColorHolder = New("Frame", {
            BackgroundColor3 = "BackgroundColor",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 200),
            Parent = InlinePanel,
        })
        local ColorHolderList = New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalFlex = Enum.UIFlexAlignment.Fill,
            Padding = UDim.new(0, 6),
            Parent = ColorHolder,
        })

        local SatVipMap = New("ImageButton", {
            BackgroundColor3 = ColorPicker.Value,
            Image = CustomImageManager.GetAsset("SaturationMap"),
            Size = UDim2.new(1, 0, 1, 0),
            Parent = ColorHolder,
        })
        New("UIFlexItem", {
            FlexMode = Enum.UIFlexMode.Fill,
            Parent = SatVipMap,
        })

        do
            local InitialImage = SatVipMap.Image
            if InitialImage:sub(1, 13) == "rbxassetid://" then
                task.spawn(function()
                    for _ = 1, 60 do
                        task.wait(0.5)
                        if not SatVipMap or not SatVipMap.Parent then break end
                        local ResolvedId = CustomImageManager.GetAsset("SaturationMap")
                        if ResolvedId and ResolvedId:sub(1, 13) ~= "rbxassetid://" then
                            SatVipMap.Image = ResolvedId
                            break
                        end
                    end
                end)
            end
        end

        local SatVibCursor = New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = "WhiteColor",
            Size = UDim2.fromOffset(6, 6),
            Parent = SatVipMap,
        })
        New("UICorner", {
            CornerRadius = UDim.new(1, 0),
            Parent = SatVibCursor,
        })
        New("UIStroke", {
            Color = "DarkColor",
            Parent = SatVibCursor,
        })

        local HueSelector = New("TextButton", {
            Size = UDim2.fromOffset(16, 200),
            Text = "",
            Parent = ColorHolder,
        })
        New("UIGradient", {
            Color = ColorSequence.new(HueSequenceTable),
            Rotation = 90,
            Parent = HueSelector,
        })

        local HueCursor = New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = "WhiteColor",
            BorderColor3 = "DarkColor",
            BorderSizePixel = 1,
            Position = UDim2.fromScale(0.5, ColorPicker.Hue),
            Size = UDim2.new(1, 2, 0, 1),
            Parent = HueSelector,
        })

        local TransparencySelector, TransparencyColor, TransparencyCursor
        if Info.Transparency then
            TransparencySelector = New("ImageButton", {
                BackgroundColor3 = Color3.new(1, 1, 1),
                Image = "",
                Size = UDim2.fromOffset(16, 200),
                Parent = ColorHolder,
            })

            TransparencyColor = New("Frame", {
                BackgroundColor3 = ColorPicker.Value,
                Size = UDim2.fromScale(1, 1),
                Parent = TransparencySelector,
            })
            New("UIGradient", {
                Rotation = 90,
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(1, 1),
                }),
                Parent = TransparencyColor,
            })

            TransparencyCursor = New("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = "WhiteColor",
                BorderColor3 = "DarkColor",
                BorderSizePixel = 1,
                Position = UDim2.fromScale(0.5, ColorPicker.Transparency),
                Size = UDim2.new(1, 2, 0, 1),
                Parent = TransparencySelector,
            })
        end

        local InfoHolder = New("Frame", {
            BackgroundColor3 = "BackgroundColor",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 20),
            Parent = InlinePanel,
        })
        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalFlex = Enum.UIFlexAlignment.Fill,
            Padding = UDim.new(0, 8),
            Parent = InfoHolder,
        })

        local HueBox = New("TextBox", {
            BackgroundColor3 = "BackgroundColor",
            ClearTextOnFocus = false,
            Size = UDim2.fromScale(1, 1),
            Text = "#??????",
            TextColor3 = "FontColor",
            TextSize = 14,
            Parent = InfoHolder,
        })

        New("UIStroke", {
            Color = "OutlineColor",
            Parent = HueBox,
        })

        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                Parent = HueBox,
            })
        )

        local RgbBox = New("TextBox", {
            BackgroundColor3 = "BackgroundColor",
            ClearTextOnFocus = false,
            Size = UDim2.fromScale(1, 1),
            Text = "?, ?, ?",
            TextColor3 = "FontColor",
            TextSize = 14,
            Parent = InfoHolder,
        })

        New("UIStroke", {
            Color = "OutlineColor",
            Parent = RgbBox,
        })

        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                Parent = RgbBox,
            })
        )

        local ContextMenu = Library:AddContextMenu(Holder, UDim2.fromOffset(93, 0), function()
            return { Holder.AbsoluteSize.X + 1.5, 0.5 }
        end, 1)
        ColorPicker.ContextMenu = ContextMenu
        ContextMenu.List.Padding = UDim.new(0, 6)
        do
            local function CreateButton(Text, Func)
                local Button = New("TextButton", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 21),
                    Text = Text,
                    TextSize = 14,
                    Parent = ContextMenu.Menu,
                })

                Button.MouseButton1Click:Connect(function()
                    Library:SafeCallback(Func)
                    ContextMenu:Close()
                end)
            end

            CreateButton("Copy color", function()
                Library.CopiedColor = { ColorPicker.Value, ColorPicker.Transparency }
            end)

            ColorPicker.SetValueRGB = function(...) end
            CreateButton("Paste color", function()
                ColorPicker:SetValueRGB(Library.CopiedColor[1], Library.CopiedColor[2])
            end)

            if setclipboard then
                CreateButton("Copy Hex", function()
                    setclipboard(tostring(ColorPicker.Value:ToHex()))
                end)

                CreateButton("Copy RGB", function()
                    setclipboard(table.concat({
                        math.floor(ColorPicker.Value.R * 255),
                        math.floor(ColorPicker.Value.G * 255),
                        math.floor(ColorPicker.Value.B * 255),
                    }, ", "))
                end)
            end
        end

        function ColorPicker:SetHSVFromRGB(Color)
            ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = Color:ToHSV()
        end

        function ColorPicker:Display()
            if Library.Unloaded then
                return
            end

            ColorPicker.Value = Color3.fromHSV(ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib)

            Holder.BackgroundColor3 = ColorPicker.Value
            HolderStroke.Color = Library:GetDarkerColor(ColorPicker.Value)
            HolderColor.BackgroundColor3 = ColorPicker.Value
            HolderColor.BackgroundTransparency = ColorPicker.Transparency

            SatVipMap.BackgroundColor3 = Color3.fromHSV(ColorPicker.Hue, 1, 1)
            if TransparencyColor then
                TransparencyColor.BackgroundColor3 = ColorPicker.Value
            end

            SatVibCursor.Position = UDim2.fromScale(ColorPicker.Sat, 1 - ColorPicker.Vib)
            HueCursor.Position = UDim2.fromScale(0.5, ColorPicker.Hue)
            if TransparencyCursor then
                TransparencyCursor.Position = UDim2.fromScale(0.5, ColorPicker.Transparency)
            end

            HueBox.Text = "#" .. ColorPicker.Value:ToHex()
            RgbBox.Text = table.concat({
                math.floor(ColorPicker.Value.R * 255),
                math.floor(ColorPicker.Value.G * 255),
                math.floor(ColorPicker.Value.B * 255),
            }, ", ")
        end

        function ColorPicker:Update()
            ColorPicker:Display()

            Library:SafeCallback(ColorPicker.Callback, ColorPicker.Value)
            Library:SafeCallback(ColorPicker.Changed, ColorPicker.Value)
        end

        function ColorPicker:OnChanged(Func)
            ColorPicker.Changed = Func
        end

        function ColorPicker:SetValue(HSV, Transparency)
            if typeof(HSV) == "Color3" then
                ColorPicker:SetValueRGB(HSV, Transparency)
                return
            end

            local Color = Color3.fromHSV(HSV[1], HSV[2], HSV[3])
            ColorPicker.Transparency = Info.Transparency and Transparency or 0
            ColorPicker:SetHSVFromRGB(Color)
            ColorPicker:Update()
        end

        function ColorPicker:SetValueRGB(Color, Transparency)
            ColorPicker.Transparency = Info.Transparency and Transparency or 0
            ColorPicker:SetHSVFromRGB(Color)
            ColorPicker:Update()
        end

        Holder.MouseButton1Click:Connect(function() ColorMenu:Toggle() end)
        Holder.MouseButton2Click:Connect(ContextMenu.Toggle)

        SatVipMap.InputBegan:Connect(function(Input: InputObject)
            while IsDragInput(Input) do
                local MinX = SatVipMap.AbsolutePosition.X
                local MaxX = MinX + SatVipMap.AbsoluteSize.X
                local LocationX = math.clamp(Mouse.X, MinX, MaxX)

                local MinY = SatVipMap.AbsolutePosition.Y
                local MaxY = MinY + SatVipMap.AbsoluteSize.Y
                local LocationY = math.clamp(Mouse.Y, MinY, MaxY)

                local OldSat = ColorPicker.Sat
                local OldVib = ColorPicker.Vib
                ColorPicker.Sat = (LocationX - MinX) / (MaxX - MinX)
                ColorPicker.Vib = 1 - ((LocationY - MinY) / (MaxY - MinY))

                if ColorPicker.Sat ~= OldSat or ColorPicker.Vib ~= OldVib then
                    ColorPicker:Update()
                end

                RunService.RenderStepped:Wait()
            end
        end)
        HueSelector.InputBegan:Connect(function(Input: InputObject)
            while IsDragInput(Input) do
                local Min = HueSelector.AbsolutePosition.Y
                local Max = Min + HueSelector.AbsoluteSize.Y
                local Location = math.clamp(Mouse.Y, Min, Max)

                local OldHue = ColorPicker.Hue
                ColorPicker.Hue = (Location - Min) / (Max - Min)

                if ColorPicker.Hue ~= OldHue then
                    ColorPicker:Update()
                end

                RunService.RenderStepped:Wait()
            end
        end)
        if TransparencySelector then
            TransparencySelector.InputBegan:Connect(function(Input: InputObject)
                while IsDragInput(Input) do
                    local Min = TransparencySelector.AbsolutePosition.Y
                    local Max = TransparencySelector.AbsolutePosition.Y + TransparencySelector.AbsoluteSize.Y
                    local Location = math.clamp(Mouse.Y, Min, Max)

                    local OldTransparency = ColorPicker.Transparency
                    ColorPicker.Transparency = (Location - Min) / (Max - Min)

                    if ColorPicker.Transparency ~= OldTransparency then
                        ColorPicker:Update()
                    end

                    RunService.RenderStepped:Wait()
                end
            end)
        end

        HueBox.FocusLost:Connect(function(Enter)
            if not Enter then
                return
            end

            local Success, Color = pcall(Color3.fromHex, HueBox.Text)
            if Success and typeof(Color) == "Color3" then
                ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = Color:ToHSV()
            end

            ColorPicker:Update()
        end)
        RgbBox.FocusLost:Connect(function(Enter)
            if not Enter then
                return
            end

            local R, G, B = RgbBox.Text:match("(%d+),%s*(%d+),%s*(%d+)")
            if R and G and B then
                ColorPicker:SetHSVFromRGB(Color3.fromRGB(R, G, B))
            end

            ColorPicker:Update()
        end)

        ColorPicker:Display()

        ColorPicker.Holder = Holder

        if ParentObj.Addons then
            table.insert(ParentObj.Addons, ColorPicker)
        end

        ColorPicker.Default = ColorPicker.Value

        Options[Idx] = ColorPicker

        return ColorPicker
    end

    BaseAddons.__index = Funcs
    BaseAddons.__namecall = function(_, Key, ...)
        return Funcs[Key](...)
    end
end

do
    local Funcs = {}

    function Funcs:AddDivider(...)
        local Params = select(1, ...)
        local Text
        local MarginTop = 0
        local MarginBottom = 0

        if typeof(Params) == "table" then
            Text = Params.Text
            MarginTop = Params.MarginTop or Params.Margin or 0
            MarginBottom = Params.MarginBottom or Params.Margin or 0
        elseif typeof(Params) == "string" then
            Text = Params
        end

        local ExtraTop = 6

        local Section = self
        local Container = Section.Container

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 14 + MarginTop + MarginBottom),
            Parent = Container,
        })

        local InnerHolder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Parent = Holder,
        })

        New("UIPadding", {
            PaddingTop = UDim.new(0, MarginTop + ExtraTop),
            PaddingBottom = UDim.new(0, MarginBottom),
            Parent = Holder,
        })

        if Text then
            local TextLabel = New("TextLabel", {
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 0),
                Text = Text,
                TextSize = 14,
                TextTransparency = 0.5,
                TextXAlignment = Enum.TextXAlignment.Center,
                Parent = InnerHolder,
            })

            local X, _ = Library:GetTextBounds(Text, TextLabel.FontFace, TextLabel.TextSize, TextLabel.AbsoluteSize.X)
            local SizeX = X // 2 + 10

            New("Frame", {
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundColor3 = "MainColor",
                BorderColor3 = "OutlineColor",
                BorderSizePixel = 1,
                Position = UDim2.fromScale(0, 0.5),
                Size = UDim2.new(0.5, -SizeX, 0, 2),
                Parent = InnerHolder,
            })
            New("Frame", {
                AnchorPoint = Vector2.new(1, 0.5),
                BackgroundColor3 = "MainColor",
                BorderColor3 = "OutlineColor",
                BorderSizePixel = 1,
                Position = UDim2.fromScale(1, 0.5),
                Size = UDim2.new(0.5, -SizeX, 0, 2),
                Parent = InnerHolder,
            })
        else
            New("Frame", {
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundColor3 = "MainColor",
                BorderColor3 = "OutlineColor",
                BorderSizePixel = 1,
                Position = UDim2.fromScale(0, 0.5),
                Size = UDim2.new(1, 0, 0, 2),
                Parent = InnerHolder,
            })
        end

        Section:Resize()

        local Divider = {
            Holder = Holder,
            Text = Text,
            MarginTop = MarginTop,
            MarginBottom = MarginBottom,
            Type = "Divider",
        }

        table.insert(Section.Elements, Divider)
        return Divider
    end

    function Funcs:AddLabel(...)
        local Data = {}
        local Addons = {}

        local First = select(1, ...)
        local Second = select(2, ...)

        if typeof(First) == "table" or typeof(Second) == "table" then
            local Params = typeof(First) == "table" and First or Second

            Data.Text = Params.Text or ""
            Data.DoesWrap = Params.DoesWrap or false
            Data.Size = Params.Size or 14
            Data.Visible = Params.Visible or true
            Data.Idx = typeof(Second) == "table" and First or nil
        else
            Data.Text = First or ""
            Data.DoesWrap = Second or false
            Data.Size = 14
            Data.Visible = true
            Data.Idx = select(3, ...) or nil
        end

        local Section = self
        local Container = Section.Container

        local Label = {
            Text = Data.Text,
            DoesWrap = Data.DoesWrap,

            Addons = Addons,

            Visible = Data.Visible,
            Type = "Label",
        }

        local TextLabel = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 18),
            Text = Label.Text,
            TextSize = Data.Size,
            TextTruncate = Enum.TextTruncate.AtEnd,
            TextWrapped = Label.DoesWrap,
            TextXAlignment = Section.IsKeyTab and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left,
            Parent = Container,
        })

        function Label:SetVisible(Visible: boolean)
            Label.Visible = Visible

            TextLabel.Visible = Label.Visible
            Section:Resize()
        end

        function Label:SetText(Text: string)
            task.spawn(function()
                Label.Text = Text
                TextLabel.Text = Text

                if Label.DoesWrap then
                    local _, Y =
                        Library:GetTextBounds(Label.Text, TextLabel.FontFace, TextLabel.TextSize, TextLabel.AbsoluteSize.X)
                    TextLabel.Size = UDim2.new(1, 0, 0, Y + 4)
                end

                Section:Resize()
            end)
        end

        if Label.DoesWrap then
            task.spawn(function()
                local _, Y =
                    Library:GetTextBounds(Label.Text, TextLabel.FontFace, TextLabel.TextSize, TextLabel.AbsoluteSize.X)
                TextLabel.Size = UDim2.new(1, 0, 0, Y + 4)

                local Last = TextLabel.AbsoluteSize
                TextLabel:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
                    if TextLabel.AbsoluteSize == Last then
                        return
                    end

                    local _, Y =
                        Library:GetTextBounds(Label.Text, TextLabel.FontFace, TextLabel.TextSize, TextLabel.AbsoluteSize.X)
                    TextLabel.Size = UDim2.new(1, 0, 0, Y + 4)

                    Last = TextLabel.AbsoluteSize
                    Section:Resize()
                end)
            end)
        else
            New("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Right,
                Padding = UDim.new(0, 6),
                Parent = TextLabel,
            })
        end

        Section:Resize()

        Label.TextLabel = TextLabel
        Label.Container = Container
        if not Data.DoesWrap then
            setmetatable(Label, BaseAddons)
        end

        Label.Holder = TextLabel
        Label.Section = Section
        table.insert(Section.Elements, Label)

        if Data.Idx then
            Labels[Data.Idx] = Label
        else
            table.insert(Labels, Label)
        end

        return Label
    end

    function Funcs:AddButton(...)
        local function GetInfo(...)
            local Info = {}

            local First = select(1, ...)
            local Second = select(2, ...)

            if typeof(First) == "table" or typeof(Second) == "table" then
                local Params = typeof(First) == "table" and First or Second

                Info.Text = Params.Text or ""
                Info.Func = Params.Func or Params.Callback or function() end
                Info.DoubleClick = Params.DoubleClick

                Info.Tooltip = Params.Tooltip
                Info.DisabledTooltip = Params.DisabledTooltip

                Info.Risky = Params.Risky or false
                Info.Disabled = Params.Disabled or false
                Info.Visible = Params.Visible or true
                Info.Idx = typeof(Second) == "table" and First or nil
            else
                Info.Text = First or ""
                Info.Func = Second or function() end
                Info.DoubleClick = false

                Info.Tooltip = nil
                Info.DisabledTooltip = nil

                Info.Risky = false
                Info.Disabled = false
                Info.Visible = true
                Info.Idx = select(3, ...) or nil
            end

            return Info
        end
        local Info = GetInfo(...)

        local Section = self
        local Container = Section.Container

        local Button = {
            Text = Info.Text,
            Func = Info.Func,
            DoubleClick = Info.DoubleClick,

            Tooltip = Info.Tooltip,
            DisabledTooltip = Info.DisabledTooltip,
            TooltipTable = nil,

            Risky = Info.Risky,
            Disabled = Info.Disabled,
            Visible = Info.Visible,

            Tween = nil,
            Type = "Button",
        }

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 21),
            Parent = Container,
        })

        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalFlex = Enum.UIFlexAlignment.Fill,
            Padding = UDim.new(0, 9),
            Parent = Holder,
        })

        local function CreateButton(Button)
            local Base = New("TextButton", {
                Active = not Button.Disabled,
                BackgroundColor3 = Button.Disabled and "BackgroundColor" or "MainColor",
                Size = UDim2.fromScale(1, 1),
                Text = Button.Text,
                TextSize = 14,
                TextTransparency = 0.4,
                TextTruncate = Enum.TextTruncate.AtEnd,
                Visible = Button.Visible,
                Parent = Holder,
            })

            local Stroke = New("UIStroke", {
                Color = "OutlineColor",
                Transparency = Button.Disabled and 0.5 or 0,
                Parent = Base,
            })

            table.insert(
                Library.Corners,
                New("UICorner", {
                    CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                    Parent = Base,
                })
            )

            return Base, Stroke
        end

        local function InitEvents(Button)
            Button.Base.MouseEnter:Connect(function()
                if Button.Disabled then
                    return
                end

                Button.Tween = TweenService:Create(Button.Base, Library.TweenInfo, {
                    TextTransparency = 0,
                })
                Button.Tween:Play()
            end)
            Button.Base.MouseLeave:Connect(function()
                if Button.Disabled then
                    return
                end

                Button.Tween = TweenService:Create(Button.Base, Library.TweenInfo, {
                    TextTransparency = 0.4,
                })
                Button.Tween:Play()
            end)

            Button.Base.MouseButton1Click:Connect(function()
                if Button.Disabled or Button.Locked then
                    return
                end

                if Button.DoubleClick then
                    Button.Locked = true

                    Button.Base.Text = "Are you sure?"
                    Button.Base.TextColor3 = Library.Scheme.AccentColor
                    Library.Registry[Button.Base].TextColor3 = "AccentColor"

                    local Clicked = WaitForEvent(Button.Base.MouseButton1Click, 1.5)

                    Button.Base.Text = Button.Text
                    Button.Base.TextColor3 = Button.Risky and Library.Scheme.RedColor or Library.Scheme.FontColor
                    Library.Registry[Button.Base].TextColor3 = Button.Risky and "RedColor" or "FontColor"

                    if Clicked then
                        Library:SafeCallback(Button.Func)
                    end

                    RunService.RenderStepped:Wait()
                    Button.Locked = false
                    return
                end

                Library:SafeCallback(Button.Func)
            end)
        end

        Button.Base, Button.Stroke = CreateButton(Button)
        InitEvents(Button)

        function Button:AddButton(...)
            local Info = GetInfo(...)

            local SubButton = {
                Text = Info.Text,
                Func = Info.Func,
                DoubleClick = Info.DoubleClick,

                Tooltip = Info.Tooltip,
                DisabledTooltip = Info.DisabledTooltip,
                TooltipTable = nil,

                Risky = Info.Risky,
                Disabled = Info.Disabled,
                Visible = Info.Visible,

                Tween = nil,
                Type = "SubButton",
            }

            Button.SubButton = SubButton
            SubButton.Base, SubButton.Stroke = CreateButton(SubButton)

            SubButton.Holder = SubButton.Base
            InitEvents(SubButton)

            function SubButton:UpdateColors()
                if Library.Unloaded then
                    return
                end

                StopTween(SubButton.Tween)

                SubButton.Base.BackgroundColor3 = SubButton.Disabled and Library.Scheme.BackgroundColor
                    or Library.Scheme.MainColor
                SubButton.Base.TextTransparency = SubButton.Disabled and 0.8 or 0.4
                SubButton.Stroke.Transparency = SubButton.Disabled and 0.5 or 0

                Library.Registry[SubButton.Base].BackgroundColor3 = SubButton.Disabled and "BackgroundColor"
                    or "MainColor"
            end

            function SubButton:SetDisabled(Disabled: boolean)
                SubButton.Disabled = Disabled

                if SubButton.TooltipTable then
                    SubButton.TooltipTable.Disabled = SubButton.Disabled
                end

                SubButton.Base.Active = not SubButton.Disabled
                SubButton:UpdateColors()
            end

            function SubButton:SetVisible(Visible: boolean)
                SubButton.Visible = Visible

                SubButton.Base.Visible = SubButton.Visible
                Section:Resize()
            end

            function SubButton:SetText(Text: string)
                SubButton.Text = Text
                SubButton.Base.Text = Text
            end

            if typeof(SubButton.Tooltip) == "string" or typeof(SubButton.DisabledTooltip) == "string" then
                SubButton.TooltipTable =
                    Library:AddTooltip(SubButton.Tooltip, SubButton.DisabledTooltip, SubButton.Base)
                SubButton.TooltipTable.Disabled = SubButton.Disabled
            end

            if SubButton.Risky then
                SubButton.Base.TextColor3 = Library.Scheme.RedColor
                Library.Registry[SubButton.Base].TextColor3 = "RedColor"
            end

            SubButton:UpdateColors()

            if Info.Idx then
                Buttons[Info.Idx] = SubButton
            else
                table.insert(Buttons, SubButton)
            end

            return SubButton
        end

        function Button:UpdateColors()
            if Library.Unloaded then
                return
            end

            StopTween(Button.Tween)

            Button.Base.BackgroundColor3 = Button.Disabled and Library.Scheme.BackgroundColor
                or Library.Scheme.MainColor
            Button.Base.TextTransparency = Button.Disabled and 0.8 or 0.4
            Button.Stroke.Transparency = Button.Disabled and 0.5 or 0

            Library.Registry[Button.Base].BackgroundColor3 = Button.Disabled and "BackgroundColor" or "MainColor"
        end

        function Button:SetDisabled(Disabled: boolean)
            Button.Disabled = Disabled

            if Button.TooltipTable then
                Button.TooltipTable.Disabled = Button.Disabled
            end

            Button.Base.Active = not Button.Disabled
            Button:UpdateColors()
        end

        function Button:SetVisible(Visible: boolean)
            Button.Visible = Visible

            Holder.Visible = Button.Visible
            Section:Resize()
        end

        function Button:SetText(Text: string)
            Button.Text = Text
            Button.Base.Text = Text
        end

        if typeof(Button.Tooltip) == "string" or typeof(Button.DisabledTooltip) == "string" then
            Button.TooltipTable = Library:AddTooltip(Button.Tooltip, Button.DisabledTooltip, Button.Base)
            Button.TooltipTable.Disabled = Button.Disabled
        end

        if Button.Risky then
            Button.Base.TextColor3 = Library.Scheme.RedColor
            Library.Registry[Button.Base].TextColor3 = "RedColor"
        end

        Button:UpdateColors()
        Section:Resize()

        Button.Holder = Holder
        table.insert(Section.Elements, Button)

        if Info.Idx then
            Buttons[Info.Idx] = Button
        else
            table.insert(Buttons, Button)
        end

        return Button
    end

    local function BuildSwitchVisual(Button: GuiObject)
        local Switch = New("Frame", {
            AnchorPoint = Vector2.new(1, 0),
            BackgroundColor3 = "MainColor",
            Position = UDim2.fromScale(1, 0),
            Size = UDim2.fromOffset(32, 18),
            Parent = Button,
        })
        New("UICorner", {
            CornerRadius = UDim.new(1, 0),
            Parent = Switch,
        })
        New("UIPadding", {
            PaddingBottom = UDim.new(0, 2),
            PaddingLeft = UDim.new(0, 2),
            PaddingRight = UDim.new(0, 2),
            PaddingTop = UDim.new(0, 2),
            Parent = Switch,
        })
        local SwitchStroke = New("UIStroke", {
            Color = "OutlineColor",
            Parent = Switch,
        })

        local Ball = New("Frame", {
            BackgroundColor3 = "FontColor",
            Size = UDim2.fromScale(1, 1),
            SizeConstraint = Enum.SizeConstraint.RelativeYY,
            Parent = Switch,
        })
        New("UICorner", {
            CornerRadius = UDim.new(1, 0),
            Parent = Ball,
        })

        local function Display(Toggle)
            if Library.Unloaded then
                return
            end

            local Offset = Toggle.Value and 1 or 0

            Switch.BackgroundTransparency = Toggle.Disabled and 0.75 or 0
            SwitchStroke.Transparency = Toggle.Disabled and 0.75 or 0

            Switch.BackgroundColor3 = Toggle.Value and Library.Scheme.AccentColor or Library.Scheme.MainColor
            SwitchStroke.Color = Toggle.Value and Library.Scheme.AccentColor or Library.Scheme.OutlineColor

            if Library.Registry[Switch] then
                Library.Registry[Switch].BackgroundColor3 = Toggle.Value and "AccentColor" or "MainColor"
            end
            if Library.Registry[SwitchStroke] then
                Library.Registry[SwitchStroke].Color = Toggle.Value and "AccentColor" or "OutlineColor"
            end

            if Toggle.Disabled then
                Toggle.TextLabel.TextTransparency = 0.8
                Ball.AnchorPoint = Vector2.new(Offset, 0)
                Ball.Position = UDim2.fromScale(Offset, 0)

                Ball.BackgroundColor3 = Library:GetDarkerColor(Library.Scheme.FontColor)
                if Library.Registry[Ball] then
                    Library.Registry[Ball].BackgroundColor3 = function()
                        return Library:GetDarkerColor(Library.Scheme.FontColor)
                    end
                end

                return
            end

            TweenService:Create(Toggle.TextLabel, Library.TweenInfo, {
                TextTransparency = Toggle.Value and 0 or 0.4,
            }):Play()
            TweenService:Create(Ball, Library.TweenInfo, {
                AnchorPoint = Vector2.new(Offset, 0),
                Position = UDim2.fromScale(Offset, 0),
            }):Play()

            Ball.BackgroundColor3 = Library.Scheme.FontColor
            if Library.Registry[Ball] then
                Library.Registry[Ball].BackgroundColor3 = "FontColor"
            end
        end

        return Switch, Display
    end

    local function BuildCheckboxVisual(Button: GuiObject)
        local Checkbox = New("Frame", {
            BackgroundColor3 = "MainColor",
            Size = UDim2.fromScale(1, 1),
            SizeConstraint = Enum.SizeConstraint.RelativeYY,
            Parent = Button,
        })
        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                Parent = Checkbox,
            })
        )

        local CheckboxStroke = New("UIStroke", {
            Color = "OutlineColor",
            Parent = Checkbox,
        })

        local CheckImage = New("ImageLabel", {
            Image = CheckIcon and CheckIcon.Url or "",
            ImageColor3 = "FontColor",
            ImageRectOffset = CheckIcon and CheckIcon.ImageRectOffset or Vector2.zero,
            ImageRectSize = CheckIcon and CheckIcon.ImageRectSize or Vector2.zero,
            ImageTransparency = 1,
            Position = UDim2.fromOffset(2, 2),
            Size = UDim2.new(1, -4, 1, -4),
            Parent = Checkbox,
        })
        Library:RegisterIconInstance(CheckImage, "check")

        local function Display(Toggle)
            if Library.Unloaded then
                return
            end

            CheckboxStroke.Transparency = Toggle.Disabled and 0.5 or 0

            if Toggle.Disabled then
                Toggle.TextLabel.TextTransparency = 0.8
                CheckImage.ImageTransparency = Toggle.Value and 0.8 or 1

                Checkbox.BackgroundColor3 = Library.Scheme.BackgroundColor
                Library.Registry[Checkbox].BackgroundColor3 = "BackgroundColor"

                return
            end

            TweenService:Create(Toggle.TextLabel, Library.TweenInfo, {
                TextTransparency = Toggle.Value and 0 or 0.4,
            }):Play()
            TweenService:Create(CheckImage, Library.TweenInfo, {
                ImageTransparency = Toggle.Value and 0 or 1,
            }):Play()

            Checkbox.BackgroundColor3 = Library.Scheme.MainColor
            Library.Registry[Checkbox].BackgroundColor3 = "MainColor"
        end

        return Checkbox, Display
    end

    local function ConstructToggle(Section, Container, Info, InitialVariant: string, ExplicitCheckbox: boolean?)
        local Toggle = {
            Text = Info.Text,
            Value = Info.Default,

            Tooltip = Info.Tooltip,
            DisabledTooltip = Info.DisabledTooltip,
            TooltipTable = nil,

            Callback = Info.Callback,
            Changed = Info.Changed,

            Risky = Info.Risky,
            Disabled = Info.Disabled,
            Visible = Info.Visible,
            Addons = {},

            Variant = InitialVariant,

            ExplicitCheckbox = ExplicitCheckbox or false,
            Type = "Toggle",
        }

        local Button = New("TextButton", {
            Active = not Toggle.Disabled,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 18),
            Text = "",
            Visible = Toggle.Visible,
            Parent = Container,
        })

        local Label = New("TextLabel", {
            BackgroundTransparency = 1,
            Text = Toggle.Text,
            TextSize = 14,
            TextTransparency = 0.4,
            TextTruncate = Enum.TextTruncate.AtEnd,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = Button,
        })

        Toggle.TextLabel = Label

        local Visual: GuiObject
        local DisplayImpl: (Toggle: any) -> ()

        local function ApplyVariantLayout()
            if Toggle.Variant == "Checkbox" then
                Label.Position = UDim2.fromOffset(26, 0)
                Label.Size = UDim2.new(1, -26, 1, 0)
            else
                Label.Position = UDim2.fromOffset(0, 0)
                Label.Size = UDim2.new(1, -40, 1, 0)
            end
        end

        function Toggle:SetVariant(Variant: string)
            assert(Variant == "Switch" or Variant == "Checkbox", "Variant must be 'Switch' or 'Checkbox'.")

            if Toggle.Variant == Variant and Visual then
                return
            end

            Toggle.Variant = Variant

            if Visual then
                Visual:Destroy()
                Visual = nil
            end

            ApplyVariantLayout()

            if Variant == "Checkbox" then
                Visual, DisplayImpl = BuildCheckboxVisual(Button)
            else
                Visual, DisplayImpl = BuildSwitchVisual(Button)
            end

            Toggle:Display()
        end

        function Toggle:UpdateColors()
            Toggle:Display()
        end

        function Toggle:Display()
            if DisplayImpl then
                DisplayImpl(Toggle)
            end
        end

        function Toggle:OnChanged(Func)
            Toggle.Changed = Func
        end

        function Toggle:SetValue(Value)
            if Toggle.Disabled then
                return
            end

            Toggle.Value = Value
            Toggle:Display()

            for _, Addon in Toggle.Addons do
                if Addon.Type == "KeyPicker" and Addon.SyncToggleState then
                    Addon.Toggled = Toggle.Value
                    Addon:Update()
                end
            end

            Library:UpdateConditionalGroups()
            Library:SafeCallback(Toggle.Callback, Toggle.Value)
            Library:SafeCallback(Toggle.Changed, Toggle.Value)
        end

        function Toggle:SetDisabled(Disabled: boolean)
            Toggle.Disabled = Disabled

            if Toggle.TooltipTable then
                Toggle.TooltipTable.Disabled = Toggle.Disabled
            end

            for _, Addon in Toggle.Addons do
                if Addon.Type == "KeyPicker" and Addon.SyncToggleState then
                    Addon:Update()
                end
            end

            Button.Active = not Toggle.Disabled
            Toggle:Display()
        end

        function Toggle:SetVisible(Visible: boolean)
            Toggle.Visible = Visible

            Button.Visible = Toggle.Visible
            Section:Resize()
        end

        function Toggle:SetText(Text: string)
            Toggle.Text = Text
            Label.Text = Text
        end

        Button.MouseButton1Click:Connect(function()
            if Toggle.Disabled then
                return
            end

            Toggle:SetValue(not Toggle.Value)
        end)

        if typeof(Toggle.Tooltip) == "string" or typeof(Toggle.DisabledTooltip) == "string" then
            Toggle.TooltipTable = Library:AddTooltip(Toggle.Tooltip, Toggle.DisabledTooltip, Button)
            Toggle.TooltipTable.Disabled = Toggle.Disabled
        end

        if Toggle.Risky then
            Label.TextColor3 = Library.Scheme.RedColor
            Library.Registry[Label].TextColor3 = "RedColor"
        end

        ApplyVariantLayout()
        if InitialVariant == "Checkbox" then
            Visual, DisplayImpl = BuildCheckboxVisual(Button)
        else
            Visual, DisplayImpl = BuildSwitchVisual(Button)
        end

        Toggle:Display()
        Section:Resize()

        Toggle.Container = Container
        setmetatable(Toggle, BaseAddons)

        Toggle.Holder = Button
        Toggle.Section = Section
        table.insert(Section.Elements, Toggle)

        Toggle.Default = Toggle.Value

        return Toggle
    end

    function Funcs:AddCheckbox(Idx, Info)
        Info = Library:Validate(Info, Templates.Toggle)

        local Section = self
        local Container = Section.Container

        local Toggle = ConstructToggle(Section, Container, Info, "Checkbox", true)
        Toggles[Idx] = Toggle

        return Toggle
    end

    function Funcs:AddToggle(Idx, Info)
        Info = Library:Validate(Info, Templates.Toggle)

        local Section = self
        local Container = Section.Container

        local Toggle = ConstructToggle(Section, Container, Info, Library.ForceCheckbox and "Checkbox" or "Switch")
        Toggles[Idx] = Toggle

        return Toggle
    end

    function Funcs:AddInput(Idx, Info)
        if typeof(Info) == "table" and (typeof(Info.VerifyValue) == "function" and Info.Finished ~= true) then
            Info.Finished = true
        end

        Info = Library:Validate(Info, Templates.Input)

        local Section = self
        local Container = Section.Container

        local Input = {
            Text = Info.Text,
            Value = Info.Default,

            Finished = Info.Finished,
            Numeric = Info.Numeric,
            ClearTextOnFocus = Info.ClearTextOnFocus,
            ClearTextOnBlur = Info.ClearTextOnBlur,
            Placeholder = Info.Placeholder,
            AllowEmpty = Info.AllowEmpty,
            EmptyReset = Info.EmptyReset,

            Tooltip = Info.Tooltip,
            DisabledTooltip = Info.DisabledTooltip,
            TooltipTable = nil,

            Callback = Info.Callback,
            Changed = Info.Changed,
            VerifyValue = Info.VerifyValue,

            Disabled = Info.Disabled,
            Visible = Info.Visible,

            Type = "Input",
        }

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 39),
            Visible = Input.Visible,
            Parent = Container,
        })

        local Label = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 14),
            Text = Input.Text,
            TextSize = 14,
            TextTruncate = Enum.TextTruncate.AtEnd,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = Holder,
        })

        local Box = New("TextBox", {
            AnchorPoint = Vector2.new(0, 1),
            BackgroundColor3 = "MainColor",
            ClearTextOnFocus = not Input.Disabled and Input.ClearTextOnFocus,
            PlaceholderText = Input.Placeholder,
            Position = UDim2.fromScale(0, 1),
            Size = UDim2.new(1, 0, 0, 21),
            Text = Input.Value,
            TextEditable = not Input.Disabled,
            TextScaled = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = Holder,
        })

        New("UIPadding", {
            PaddingBottom = UDim.new(0, 4),
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
            PaddingTop = UDim.new(0, 4),
            Parent = Box,
        })

        New("UIStroke", {
            Color = "OutlineColor",
            Parent = Box,
        })

        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                Parent = Box,
            })
        )

        function Input:UpdateColors()
            if Library.Unloaded then
                return
            end

            Label.TextTransparency = Input.Disabled and 0.8 or 0
            Box.TextTransparency = Input.Disabled and 0.8 or 0
        end

        function Input:OnChanged(Func)
            Input.Changed = Func
        end

        function Input:SetValue(Text)
            if not Input.AllowEmpty and Trim(Text) == "" then
                Text = Input.EmptyReset
            end

            if Info.MaxLength and #Text > Info.MaxLength then
                Text = Text:sub(1, Info.MaxLength)
            end

            if Input.Numeric then
                if #tostring(Text) > 0 and not tonumber(Text) then
                    Text = Input.Value
                end
            end

            if typeof(Info.VerifyValue) == "function" and (Text ~= Input.EmptyReset and Info.VerifyValue(Text) ~= true) then
                Text = Input.EmptyReset
            end

            Input.Value = Text
            Box.Text = Text

            if not Input.Disabled then
                Library:SafeCallback(Input.Callback, Input.Value)
                Library:SafeCallback(Input.Changed, Input.Value)
            end
        end

        function Input:SetDisabled(Disabled: boolean)
            Input.Disabled = Disabled

            if Input.TooltipTable then
                Input.TooltipTable.Disabled = Input.Disabled
            end

            Box.ClearTextOnFocus = not Input.Disabled and Input.ClearTextOnFocus
            Box.TextEditable = not Input.Disabled
            Input:UpdateColors()
        end

        function Input:SetVisible(Visible: boolean)
            Input.Visible = Visible

            Holder.Visible = Input.Visible
            Section:Resize()
        end

        function Input:SetText(Text: string)
            Input.Text = Text
            Label.Text = Text
        end

        if Input.Finished then
            Box.FocusLost:Connect(function(Enter)
                if not Enter then
                    if Input.ClearTextOnBlur then
                        Box.Text = Input.Value
                    end

                    return
                end

                Input:SetValue(Box.Text)
            end)
        else
            Box:GetPropertyChangedSignal("Text"):Connect(function()
                if Box.Text == Input.Value then return end

                Input:SetValue(Box.Text)
            end)
        end

        if typeof(Input.Tooltip) == "string" or typeof(Input.DisabledTooltip) == "string" then
            Input.TooltipTable = Library:AddTooltip(Input.Tooltip, Input.DisabledTooltip, Box)
            Input.TooltipTable.Disabled = Input.Disabled
        end

        Section:Resize()

        Input.Holder = Holder
        table.insert(Section.Elements, Input)

        Input.Default = Input.Value
        if typeof(Info.VerifyValue) == "function" and (Input.Default ~= Input.EmptyReset and Info.VerifyValue(Input.Default) ~= true) then
            Input:SetValue(Input.EmptyReset)
            Input.Default = Input.EmptyReset
        end

        Options[Idx] = Input

        return Input
    end

    function Funcs:AddSlider(Idx, Info)
        Info = Library:Validate(Info, Templates.Slider)

        local Section = self
        local Container = Section.Container

        local Slider = {
            Text = Info.Text,
            Value = Info.Default,

            Min = Info.Min,
            Max = Info.Max,

            Prefix = Info.Prefix,
            Suffix = Info.Suffix,
            Compact = Info.Compact,
            Rounding = Info.Rounding,
            HideMax = Info.HideMax,
            Editable = Info.Editable,
            EditableStyle = Info.EditableStyle or "Pencil",

            Tooltip = Info.Tooltip,
            DisabledTooltip = Info.DisabledTooltip,
            TooltipTable = nil,

            Callback = Info.Callback,
            Changed = Info.Changed,

            Disabled = Info.Disabled,
            Visible = Info.Visible,

            Type = "Slider",
        }

        local IsValueBoxStyle = Slider.Editable and Slider.EditableStyle == "ValueBox"

        local ValueBoxHeight = 21
        local TopRowHeight = IsValueBoxStyle and math.max(14, ValueBoxHeight) or 14
        local VerticalGap = IsValueBoxStyle and 6 or 4

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, Info.Compact and 15 or (TopRowHeight + VerticalGap + 15)),
            Visible = Slider.Visible,
            Parent = Container,
        })

        local SliderLabel
        local InlineValueBox
        if not Info.Compact then

            local ValueBoxWidth = 56
            local ValueBoxGap = 8

            local LabelWidth = (Slider.Editable and Slider.EditableStyle == "ValueBox")
                and UDim2.new(1, -(ValueBoxWidth + ValueBoxGap), 0, TopRowHeight)
                or  UDim2.new(1, 0, 0, 14)

            SliderLabel = New("TextLabel", {
                BackgroundTransparency = 1,
                Size = LabelWidth,
                Text = Slider.Text,
                TextSize = 14,
                TextTruncate = Enum.TextTruncate.AtEnd,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Center,
                Parent = Holder,
            })

            if Slider.Editable and Slider.EditableStyle == "ValueBox" then
                InlineValueBox = New("TextBox", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    BackgroundColor3 = "MainColor",
                    ClearTextOnFocus = true,

                    Position = UDim2.new(1, 0, 0, TopRowHeight / 2),
                    Size = UDim2.fromOffset(ValueBoxWidth, ValueBoxHeight),
                    Text = tostring(Slider.Value),
                    TextSize = 12,
                    TextEditable = not Slider.Disabled,
                    Parent = Holder,
                })
                New("UIStroke", {
                    Color = "OutlineColor",
                    Parent = InlineValueBox,
                })
                table.insert(
                    Library.Corners,
                    New("UICorner", {
                        CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                        Parent = InlineValueBox,
                    })
                )
                Library:AddToRegistry(InlineValueBox, { BackgroundColor3 = "MainColor" })
            end
        end

        local Bar = New("TextButton", {
            Active = not Slider.Disabled,
            AnchorPoint = Vector2.new(0, 1),
            BackgroundColor3 = "MainColor",
            Position = UDim2.fromScale(0, 1),
            Size = UDim2.new(1, 0, 0, 15),
            Text = "",
            Parent = Holder,
        })

        New("UIStroke", {
            Color = "OutlineColor",
            Parent = Bar,
        })

        local DisplayLabel = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Text = "",
            TextSize = 14,
            ZIndex = Bar.ZIndex + 1,
            Parent = Bar,
        })
        New("UIStroke", {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
            Color = "DarkColor",
            LineJoinMode = Enum.LineJoinMode.Miter,
            Parent = DisplayLabel,
        })

        local Fill = New("Frame", {
            BackgroundColor3 = "AccentColor",
            Size = UDim2.fromScale(0.5, 1),
            ZIndex = Bar.ZIndex,
            Parent = Bar,
        })

        local EditButton, ValueBox
        if Slider.Editable and Slider.EditableStyle ~= "ValueBox" then

            EditButton = New("ImageButton", {
                AnchorPoint = Vector2.new(1, 0.5),
                BackgroundTransparency = 1,
                Image = EditIcon and EditIcon.Url or "",
                ImageColor3 = "FontColor",
                ImageRectOffset = EditIcon and EditIcon.ImageRectOffset or Vector2.zero,
                ImageRectSize = EditIcon and EditIcon.ImageRectSize or Vector2.zero,
                ImageTransparency = 0.4,
                Position = UDim2.new(1, -4, 0.5, 0),
                Size = UDim2.fromOffset(12, 12),
                Parent = Bar,
            })
            Library:AddToRegistry(EditButton, { ImageColor3 = "FontColor" })
            Library:RegisterIconInstance(EditButton, "pencil")

            ValueBox = New("TextBox", {
                BackgroundColor3 = "MainColor",
                ClearTextOnFocus = true,
                Size = UDim2.fromScale(1, 1),
                Text = "",
                TextSize = 14,
                TextEditable = not Slider.Disabled,
                Visible = false,
                Parent = Bar,
            })
            New("UIStroke", {
                Color = "AccentColor",
                Parent = ValueBox,
            })
            table.insert(
                Library.Corners,
                New("UICorner", {
                    CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                    Parent = ValueBox,
                })
            )
        end

        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                Parent = Bar,
            })
        )

        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                Parent = Fill,
            })
        )

        function Slider:UpdateColors()
            if Library.Unloaded then
                return
            end

            if SliderLabel then
                SliderLabel.TextTransparency = Slider.Disabled and 0.8 or 0
            end
            DisplayLabel.TextTransparency = Slider.Disabled and 0.8 or 0

            if EditButton then
                EditButton.ImageTransparency = Slider.Disabled and 0.8 or 0.4
            end

            if InlineValueBox then
                InlineValueBox.TextTransparency = Slider.Disabled and 0.8 or 0
                Library.Registry[InlineValueBox].BackgroundColor3 = "MainColor"
            end

            Fill.BackgroundColor3 = Slider.Disabled and Library.Scheme.OutlineColor or Library.Scheme.AccentColor
            Library.Registry[Fill].BackgroundColor3 = Slider.Disabled and "OutlineColor" or "AccentColor"
        end

        function Slider:Display()
            if Library.Unloaded then
                return
            end

            local CustomDisplayText = nil
            if Info.FormatDisplayValue then
                CustomDisplayText = Info.FormatDisplayValue(Slider, Slider.Value)
            end

            if CustomDisplayText then
                DisplayLabel.Text = tostring(CustomDisplayText)
            else
                if Info.Compact then
                    DisplayLabel.Text =
                        string.format("%s: %s%s%s", Slider.Text, Slider.Prefix, Slider.Value, Slider.Suffix)
                elseif Info.HideMax then
                    DisplayLabel.Text = string.format("%s%s%s", Slider.Prefix, Slider.Value, Slider.Suffix)
                else
                    DisplayLabel.Text = string.format(
                        "%s%s/%s%s",
                        Slider.Prefix,
                        Slider.Value,
                        Slider.Max,
                        Slider.Suffix
                    )
                end
            end

            local X = (Slider.Value - Slider.Min) / (Slider.Max - Slider.Min)
            Fill.Size = UDim2.fromScale(X, 1)

            if InlineValueBox and not InlineValueBox:IsFocused() then
                InlineValueBox.Text = tostring(Slider.Value)
            end
        end

        function Slider:OnChanged(Func)
            Slider.Changed = Func
        end

        function Slider:SetMax(Value)
            assert(Value > Slider.Min, "Max value cannot be less than the current min value.")

            Slider:SetValue(math.clamp(Slider.Value, Slider.Min, Value))
            Slider.Max = Value
            Slider:Display()
        end

        function Slider:SetMin(Value)
            assert(Value < Slider.Max, "Min value cannot be greater than the current max value.")

            Slider:SetValue(math.clamp(Slider.Value, Value, Slider.Max))
            Slider.Min = Value
            Slider:Display()
        end

        function Slider:SetValue(Str)
            if Slider.Disabled then
                return
            end

            local Num = tonumber(Str)
            if not Num or Num == Slider.Value then
                return
            end

            Num = math.clamp(Num, Slider.Min, Slider.Max)

            Slider.Value = Num
            Slider:Display()

            Library:SafeCallback(Slider.Callback, Slider.Value)
            Library:SafeCallback(Slider.Changed, Slider.Value)
        end

        function Slider:SetDisabled(Disabled: boolean)
            Slider.Disabled = Disabled

            if Slider.TooltipTable then
                Slider.TooltipTable.Disabled = Slider.Disabled
            end

            Bar.Active = not Slider.Disabled
            if EditButton then
                EditButton.Active = not Slider.Disabled
            end
            if ValueBox then
                ValueBox.TextEditable = not Slider.Disabled
            end
            if InlineValueBox then
                InlineValueBox.TextEditable = not Slider.Disabled
            end
            Slider:UpdateColors()
        end

        function Slider:SetVisible(Visible: boolean)
            Slider.Visible = Visible

            Holder.Visible = Slider.Visible
            Section:Resize()
        end

        function Slider:SetText(Text: string)
            Slider.Text = Text
            if SliderLabel then
                SliderLabel.Text = Text
                return
            end
            Slider:Display()
        end

        function Slider:SetPrefix(Prefix: string)
            Slider.Prefix = Prefix
            Slider:Display()
        end

        function Slider:SetSuffix(Suffix: string)
            Slider.Suffix = Suffix
            Slider:Display()
        end

        Bar.InputBegan:Connect(function(Input: InputObject)
            if not IsClickInput(Input) or Slider.Disabled then
                return
            end

            if Library.ActiveTab then
                for _, Side in Library.ActiveTab.Sides do
                    Side.ScrollingEnabled = false
                end
            end

            if Library.ActiveLoading and Library.ActiveLoading.Sidebar then
                Library.ActiveLoading.Sidebar.Container.ScrollingEnabled = false
            end

            local StartMouseX = Mouse.X
            local StartBarX = Bar.AbsolutePosition.X
            local StartBarWidth = math.max(Bar.AbsoluteSize.X, 1)
            local StartScale = math.clamp((StartMouseX - StartBarX) / StartBarWidth, 0, 1)

            while IsDragInput(Input) do

                local CurrentBarX = Bar.AbsolutePosition.X
                local CurrentBarWidth = math.max(Bar.AbsoluteSize.X, 1)
                if CurrentBarX ~= StartBarX or CurrentBarWidth ~= StartBarWidth then
                    StartScale = math.clamp((Slider.Value - Slider.Min) / math.max(Slider.Max - Slider.Min, 1e-6), 0, 1)
                    StartBarX = CurrentBarX
                    StartBarWidth = CurrentBarWidth
                    StartMouseX = Mouse.X
                end

                local DeltaX = Mouse.X - StartMouseX
                local Scale = math.clamp(StartScale + (DeltaX / StartBarWidth), 0, 1)

                local OldValue = Slider.Value
                local NewValue = Round(Slider.Min + ((Slider.Max - Slider.Min) * Scale), Slider.Rounding)

                if NewValue ~= OldValue then
                    Slider.Value = NewValue
                    Slider:Display()
                    Library:SafeCallback(Slider.Callback, Slider.Value)
                    Library:SafeCallback(Slider.Changed, Slider.Value)
                end

                RunService.RenderStepped:Wait()
            end

            if Library.ActiveTab then
                for _, Side in Library.ActiveTab.Sides do
                    Side.ScrollingEnabled = true
                end
            end

            if Library.ActiveLoading and Library.ActiveLoading.Sidebar then
                Library.ActiveLoading.Sidebar.Container.ScrollingEnabled = true
            end
        end)

        if EditButton and ValueBox then
            local function EnterEditMode()
                if Slider.Disabled then
                    return
                end

                DisplayLabel.Visible = false
                EditButton.Visible = false
                ValueBox.Text = tostring(Slider.Value)
                ValueBox.Visible = true
                ValueBox:CaptureFocus()
            end

            local function ExitEditMode(Commit: boolean)
                if Commit then
                    Slider:SetValue(ValueBox.Text)
                end

                ValueBox.Visible = false
                DisplayLabel.Visible = true
                EditButton.Visible = true
            end

            EditButton.MouseButton1Click:Connect(EnterEditMode)

            ValueBox.FocusLost:Connect(function(Enter)
                ExitEditMode(Enter)
            end)
        end

        if InlineValueBox then
            InlineValueBox.FocusLost:Connect(function(Enter)
                if Enter then
                    Slider:SetValue(InlineValueBox.Text)
                end

                InlineValueBox.Text = tostring(Slider.Value)
            end)
        end

        if typeof(Slider.Tooltip) == "string" or typeof(Slider.DisabledTooltip) == "string" then
            Slider.TooltipTable = Library:AddTooltip(Slider.Tooltip, Slider.DisabledTooltip, Bar)
            Slider.TooltipTable.Disabled = Slider.Disabled
        end

        Slider:UpdateColors()
        Slider:Display()
        Section:Resize()

        Slider.Holder = Holder
        table.insert(Section.Elements, Slider)

        Slider.Default = Slider.Value

        Options[Idx] = Slider

        return Slider
    end

    function Funcs:AddProgressBar(Idx, Info)
        Info = Library:Validate(Info, Templates.ProgressBar)

        local Section = self
        local Container = Section.Container

        local ProgressBar = {
            Text = Info.Text,
            Value = Info.Value,

            Min = Info.Min,
            Max = Info.Max,

            Prefix = Info.Prefix,
            Suffix = Info.Suffix,
            Compact = Info.Compact,
            Rounding = Info.Rounding,
            HideMax = Info.HideMax,

            Callback = Info.Callback,
            Changed = Info.Changed,

            Disabled = Info.Disabled,
            Visible = Info.Visible,

            Type = "ProgressBar",
        }

        local VerticalGap = 6
        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, Info.Compact and 15 or (14 + VerticalGap + 15)),
            Visible = ProgressBar.Visible,
            Parent = Container,
        })

        local ProgressBarLabel
        if not Info.Compact then
            ProgressBarLabel = New("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 14),
                Text = ProgressBar.Text,
                TextSize = 14,
                TextTruncate = Enum.TextTruncate.AtEnd,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = Holder,
            })
        end

        local Bar = New("Frame", {
            Active = false,
            AnchorPoint = Vector2.new(0, 1),
            BackgroundColor3 = "MainColor",
            Position = UDim2.fromScale(0, 1),
            Size = UDim2.new(1, 0, 0, 15),
            Parent = Holder,
        })

        New("UIStroke", {
            Color = "OutlineColor",
            Parent = Bar,
        })

        local DisplayLabel = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Text = "",
            TextSize = 14,
            ZIndex = Bar.ZIndex + 1,
            Parent = Bar,
        })
        New("UIStroke", {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
            Color = "DarkColor",
            LineJoinMode = Enum.LineJoinMode.Miter,
            Parent = DisplayLabel,
        })

        local Fill = New("Frame", {
            BackgroundColor3 = "AccentColor",
            Size = UDim2.fromScale(0, 1),
            ZIndex = Bar.ZIndex,
            Parent = Bar,
        })

        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                Parent = Bar,
            })
        )

        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                Parent = Fill,
            })
        )

        function ProgressBar:UpdateColors()
            if Library.Unloaded then
                return
            end

            if ProgressBarLabel then
                ProgressBarLabel.TextTransparency = ProgressBar.Disabled and 0.8 or 0
            end
            DisplayLabel.TextTransparency = ProgressBar.Disabled and 0.8 or 0

            Fill.BackgroundColor3 = ProgressBar.Disabled and Library.Scheme.OutlineColor or Library.Scheme.AccentColor
            Library.Registry[Fill].BackgroundColor3 = ProgressBar.Disabled and "OutlineColor" or "AccentColor"
        end

        function ProgressBar:Display()
            if Library.Unloaded then
                return
            end

            if Info.Compact then
                DisplayLabel.Text = string.format("%s: %s%s%s", ProgressBar.Text, ProgressBar.Prefix, ProgressBar.Value, ProgressBar.Suffix)
            elseif Info.HideMax then
                DisplayLabel.Text = string.format("%s%s%s", ProgressBar.Prefix, ProgressBar.Value, ProgressBar.Suffix)
            else
                DisplayLabel.Text = string.format(
                    "%s%s/%s%s",
                    ProgressBar.Prefix,
                    ProgressBar.Value,
                    ProgressBar.Max,
                    ProgressBar.Suffix
                )
            end

            local X = (ProgressBar.Value - ProgressBar.Min) / (ProgressBar.Max - ProgressBar.Min)
            Fill.Size = UDim2.fromScale(math.clamp(X, 0, 1), 1)
        end

        function ProgressBar:OnChanged(Func)
            ProgressBar.Changed = Func
        end

        function ProgressBar:SetMax(Value)
            assert(Value > ProgressBar.Min, "Max value cannot be less than the current min value.")

            ProgressBar:SetValue(math.clamp(ProgressBar.Value, ProgressBar.Min, Value))
            ProgressBar.Max = Value
            ProgressBar:Display()
        end

        function ProgressBar:SetMin(Value)
            assert(Value < ProgressBar.Max, "Min value cannot be greater than the current max value.")

            ProgressBar:SetValue(math.clamp(ProgressBar.Value, Value, ProgressBar.Max))
            ProgressBar.Min = Value
            ProgressBar:Display()
        end

        function ProgressBar:SetValue(Str)
            if ProgressBar.Disabled then
                return
            end

            local Num = tonumber(Str)
            if not Num or Num == ProgressBar.Value then
                return
            end

            Num = math.clamp(Num, ProgressBar.Min, ProgressBar.Max)

            ProgressBar.Value = Num
            ProgressBar:Display()

            Library:SafeCallback(ProgressBar.Callback, ProgressBar.Value)
            Library:SafeCallback(ProgressBar.Changed, ProgressBar.Value)
        end

        function ProgressBar:SetDisabled(Disabled: boolean)
            ProgressBar.Disabled = Disabled
            ProgressBar:UpdateColors()
        end

        function ProgressBar:SetVisible(Visible: boolean)
            ProgressBar.Visible = Visible

            Holder.Visible = ProgressBar.Visible
            Section:Resize()
        end

        function ProgressBar:SetText(Text: string)
            ProgressBar.Text = Text
            if ProgressBarLabel then
                ProgressBarLabel.Text = Text
                return
            end
            ProgressBar:Display()
        end

        function ProgressBar:SetPrefix(Prefix: string)
            ProgressBar.Prefix = Prefix
            ProgressBar:Display()
        end

        function ProgressBar:SetSuffix(Suffix: string)
            ProgressBar.Suffix = Suffix
            ProgressBar:Display()
        end

        ProgressBar:UpdateColors()
        ProgressBar:Display()
        Section:Resize()

        ProgressBar.Holder = Holder
        table.insert(Section.Elements, ProgressBar)

        ProgressBar.Default = ProgressBar.Value

        Options[Idx] = ProgressBar

        return ProgressBar
    end

    function Funcs:AddDropdown(Idx, Info)
        Info = Library:Validate(Info, Templates.Dropdown)

        local Section = self
        local Container = Section.Container

        if Info.SpecialType == "Player" then
            Info.Values = GetPlayers(Info.ExcludeLocalPlayer)
            Info.AllowNull = true
        elseif Info.SpecialType == "Team" then
            Info.Values = GetTeams()
            Info.AllowNull = true
        end

        local Dropdown = {
            Text = typeof(Info.Text) == "string" and Info.Text or nil,

            Value = Info.Multi and {} or nil,
            Values = Info.Values,
            DisabledValues = Info.DisabledValues,
            ValueImages = Info.ValueImages,

            Multi = Info.Multi,

            SpecialType = Info.SpecialType,
            ExcludeLocalPlayer = Info.ExcludeLocalPlayer,
            EnablePlayerImages = Info.EnablePlayerImages,

            Tooltip = Info.Tooltip,
            DisabledTooltip = Info.DisabledTooltip,
            TooltipTable = nil,

            Callback = Info.Callback,
            Changed = Info.Changed,

            Disabled = Info.Disabled,
            Visible = Info.Visible,

            Type = "Dropdown",
        }

        local LabelHeight = Dropdown.Text and 18 or 0

        local Holder = New("Frame", {
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            Visible = Dropdown.Visible,
            Parent = Container,
        })
        New("UIListLayout", {
            Padding = UDim.new(0, 2),
            Parent = Holder,
        })

        local Label = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, LabelHeight),
            Text = Dropdown.Text,
            TextSize = 14,
            TextTruncate = Enum.TextTruncate.AtEnd,
            TextXAlignment = Enum.TextXAlignment.Left,
            Visible = not not Info.Text,
            Parent = Holder,
        })

        local DisplayContainer = New("TextButton", {
            BackgroundColor3 = "MainColor",
            Size = UDim2.new(1, 0, 0, 21),
            Text = "",
            TextTransparency = 1,
            Parent = Holder,
        })

        New("UIPadding", {
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 4),
            Parent = DisplayContainer,
        })

        New("UIStroke", {
            Color = "OutlineColor",
            Parent = DisplayContainer,
        })

        if Library.CornerRadiusDropdown == true then
            table.insert(
                Library.Corners,
                New("UICorner", {
                    CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                    Parent = DisplayContainer,
                })
            )
        end

        local DisplayImage = New("ImageLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(-4, 3),
            Size = UDim2.fromOffset(16, 16),
            Image = "",
            ImageTransparency = 1,
            Parent = DisplayContainer,
        })

        local DisplayButton = New("TextButton", {
            Active = not Dropdown.Disabled,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -16, 0, 21),
            Text = "---",
            TextSize = 14,
            TextTruncate = Enum.TextTruncate.AtEnd,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = DisplayContainer,
        })

        local ArrowImage = New("ImageLabel", {
            AnchorPoint = Vector2.new(1, 0.5),
            Image = ArrowIcon and ArrowIcon.Url or "",
            ImageColor3 = "FontColor",
            ImageRectOffset = ArrowIcon and ArrowIcon.ImageRectOffset or Vector2.zero,
            ImageRectSize = ArrowIcon and ArrowIcon.ImageRectSize or Vector2.zero,
            ImageTransparency = 0.5,
            Position = UDim2.fromScale(1, 0.5),
            Size = UDim2.fromOffset(16, 16),
            Parent = DisplayContainer,
        })
        Library:RegisterIconInstance(ArrowImage, "chevron-up")

        local SearchBox
        local SearchBar
        local ActionBar
        local Buttons = {}
        if Info.Searchable then
            local RightBtnsWidth = Info.Multi and 88 or 0

            SearchBar = New("Frame", {
                BackgroundColor3 = "MainColor",
                Size = UDim2.new(1, 0, 0, 28),
                Visible = false,
                Parent = Holder,
            })
            New("UIStroke", { Color = "OutlineColor", Parent = SearchBar })
            if Library.CornerRadiusDropdown == true then
                table.insert(Library.Corners, New("UICorner", {
                    CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                    Parent = SearchBar,
                }))
            end

            New("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Left,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Padding = UDim.new(0, 0),
                Parent = SearchBar,
            })
            New("UIPadding", {
                PaddingLeft = UDim.new(0, 8),
                PaddingRight = UDim.new(0, 8),
                PaddingTop = UDim.new(0, 4),
                PaddingBottom = UDim.new(0, 4),
                Parent = SearchBar,
            })

            SearchBox = New("TextBox", {
                BackgroundTransparency = 1,
                PlaceholderText = "Search...",
                Size = UDim2.new(1, Info.Multi and -88 or 0, 1, 0),
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = SearchBar,
            })

            if Info.Multi then

                New("Frame", {
                    BackgroundColor3 = "OutlineColor",
                    BorderSizePixel = 0,
                    Size = UDim2.new(0, 1, 1, 0),
                    Parent = SearchBar,
                })

                local function MakeActionBtn(BtnText, Callback)
                    local Btn = New("TextButton", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(0, RightBtnsWidth / 2 - 1, 1, 0),
                        Text = BtnText,
                        TextSize = 12,
                        TextTransparency = 0.5,
                        Parent = SearchBar,
                    })
                    Btn.MouseEnter:Connect(function()
                        TweenService:Create(Btn, Library.TweenInfo, { TextTransparency = 0 }):Play()
                    end)
                    Btn.MouseLeave:Connect(function()
                        TweenService:Create(Btn, Library.TweenInfo, { TextTransparency = 0.5 }):Play()
                    end)
                    Btn.MouseButton1Click:Connect(Callback)
                    return Btn
                end

                MakeActionBtn("All", function()
                    for _, Value in Dropdown.Values do
                        if not table.find(Dropdown.DisabledValues, Value) then
                            Dropdown.Value[Value] = true
                        end
                    end
                    Dropdown:Display()
                    for _, Btn in Buttons do Btn:UpdateButton() end
                    Library:UpdateConditionalGroups()
                    Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
                    Library:SafeCallback(Dropdown.Changed, Dropdown.Value)
                end)

                MakeActionBtn("Clear", function()
                    table.clear(Dropdown.Value)
                    Dropdown:Display()
                    for _, Btn in Buttons do Btn:UpdateButton() end
                    Library:UpdateConditionalGroups()
                    Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
                    Library:SafeCallback(Dropdown.Changed, Dropdown.Value)
                end)
            end
        end

        local GetValueImage = function(Value)
            if not Value then
                return nil
            end

            local ValueImage = nil
            if Dropdown.SpecialType == "Player" and Dropdown.EnablePlayerImages == true then
                if typeof(Value) == "Instance" and Value:IsA("Player") then
                    ValueImage = { Url = string.format("rbxthumb://type=AvatarHeadShot&id=%s&w=48&h=48", tostring(Value.UserId)) }
                end
            else
                if Info.ValueImages and Info.ValueImages[Value] then
                    ValueImage = Library:GetCustomIcon(Info.ValueImages[Value])
                end
            end

            return ValueImage
        end

        local InlineList = New("ScrollingFrame", {
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = "MainColor",
            CanvasSize = UDim2.fromScale(0, 0),
            ScrollBarImageColor3 = "OutlineColor",
            ScrollBarThickness = 3,
            Size = UDim2.new(1, 0, 0, 0),
            Visible = false,
            Parent = Holder,
        })
        Library:AddToRegistry(InlineList, { ScrollBarImageColor3 = "OutlineColor" })
        New("UIStroke", { Color = "OutlineColor", Parent = InlineList })
        if Library.CornerRadiusDropdown == true then
            table.insert(Library.Corners, New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                Parent = InlineList,
            }))
        end
        local InlineListLayout = New("UIListLayout", { Parent = InlineList })

        local DropdownOpen = false

        local MenuTable = {
            Active = false,
            Menu = InlineList,
            List = InlineListLayout,
        }
        Dropdown.Menu = MenuTable

        local function SetDropdownOpen(Active)
            DropdownOpen = Active
            MenuTable.Active = Active
            InlineList.Visible = Active
            ArrowImage.ImageTransparency = Active and 0 or 0.5
            ArrowImage.Rotation = Active and 180 or 0
            if SearchBar then
                if SearchBox then SearchBox.Text = "" end
                SearchBar.Visible = Active
            end
            if ActionBar then
                ActionBar.Visible = Active
            end
            Section:Resize()
        end

        function MenuTable:Open()  SetDropdownOpen(true)  end
        function MenuTable:Close() SetDropdownOpen(false) end
        function MenuTable:Toggle()
            SetDropdownOpen(not DropdownOpen)
        end
        function MenuTable:SetSize(SizeFunc)

            local S = typeof(SizeFunc) == "function" and SizeFunc() or SizeFunc
            InlineList.Size = UDim2.new(1, 0, 0, S.Y.Offset)
        end

        function Dropdown:UpdateColors()
            if Library.Unloaded then
                return
            end

            Label.TextTransparency = Dropdown.Disabled and 0.8 or 0
            DisplayButton.TextTransparency = Dropdown.Disabled and 0.8 or 0
            DisplayImage.ImageTransparency = Dropdown.Disabled and 0.8 or 0
            ArrowImage.ImageTransparency = Dropdown.Disabled and 0.8 or MenuTable.Active and 0 or 0.5
        end

        function Dropdown:Display()
            if Library.Unloaded then
                return
            end

            local Str = ""
            local ValueImage = nil

            if Info.Multi then
                for _, Value in Dropdown.Values do
                    if Dropdown.Value[Value] then
                        if not ValueImage then
                            ValueImage = GetValueImage(Value)
                        end

                        Str = Str
                            .. (Info.FormatDisplayValue and tostring(Info.FormatDisplayValue(Value)) or tostring(Value))
                            .. ", "
                    end
                end

                Str = Str:sub(1, #Str - 2)
            else
                ValueImage = GetValueImage(Dropdown.Value)
                Str = Dropdown.Value and tostring(Dropdown.Value) or ""

                if Str ~= "" and Info.FormatDisplayValue then
                    Str = tostring(Info.FormatDisplayValue(Str))
                end
            end

            DisplayButton.Text = (Str == "" and "---" or Str)

            if ValueImage then
                DisplayImage.Image = ValueImage.Url
                DisplayImage.ImageRectOffset = ValueImage.ImageRectOffset or Vector2.zero
                DisplayImage.ImageRectSize = ValueImage.ImageRectSize or Vector2.zero
                DisplayImage.ImageTransparency = 0
            else
                DisplayImage.Image = ""
                DisplayImage.ImageTransparency = 1
            end

            DisplayButton.Size = ValueImage and UDim2.new(1, -24, 0, 21) or UDim2.new(1, -16, 0, 21)
            DisplayButton.Position = ValueImage and UDim2.fromOffset(14, 0) or UDim2.fromOffset(0, 0)
        end

        function Dropdown:OnChanged(Func)
            Dropdown.Changed = Func
        end

        function Dropdown:RecalculateListSize(Count)
            local Y = math.clamp((Count or GetTableSize(Dropdown.Values)) * 21, 0, Info.MaxVisibleDropdownItems * 21)
            InlineList.Size = UDim2.new(1, 0, 0, Y)
            Section:Resize()
        end

        function Dropdown:GetActiveValues()
            if Info.Multi then
                local Table = {}

                for Value, _ in Dropdown.Value do
                    table.insert(Table, Value)
                end

                return Table
            end

            return Dropdown.Value and 1 or 0
        end

        function Dropdown:BuildDropdownList()
            local Values = Dropdown.Values
            local DisabledValues = Dropdown.DisabledValues

            for Button, _ in Buttons do
                if Button and Button.Parent then
                    pcall(function()
                        Button.Parent:Destroy()
                    end)
                end
            end
            table.clear(Buttons)

            local Count = 0
            for _, Value in Values do
                local FormattedValue = tostring(Info.FormatListValue and Info.FormatListValue(Value) or Value)
                if SearchBox and not FormattedValue:lower():match(SearchBox.Text:lower()) then
                    continue
                end

                Count += 1

                local IsDisabled = table.find(DisabledValues, Value)
                local Table = {}
                local ValueImage = GetValueImage(Value)

                local Container = New("Frame", {
                    BackgroundColor3 = "AccentColor",
                    BackgroundTransparency = 1,
                    LayoutOrder = IsDisabled and 1 or 0,
                    Size = UDim2.new(1, 0, 0, 21),
                    Parent = MenuTable.Menu,
                })

                local ItemIndex = Count
                Library:AddToRegistry(Container, {
                    BackgroundColor3 = Info.Multi and function()
                        local Base = Library.Scheme.AccentColor
                        local H, S, V = Base:ToHSV()
                        if ItemIndex % 2 == 1 then
                            return Color3.fromHSV(H, S, math.min(1, V + 0.12))
                        else
                            return Color3.fromHSV(H, S, math.max(0, V - 0.10))
                        end
                    end or "AccentColor",
                })

                local Image = ValueImage and New("ImageLabel", {
                    BackgroundTransparency = 1,
                    Image = ValueImage.Url,
                    ImageRectOffset = ValueImage.ImageRectOffset,
                    ImageRectSize = ValueImage.ImageRectSize,
                    ImageTransparency = 0.5,
                    Size = UDim2.fromOffset(16, 16),
                    Position = UDim2.fromOffset(4, 3),
                    Parent = Container,
                })

                local Button = New("TextButton", {
                    BackgroundTransparency = 1,
                    Size = ValueImage and UDim2.new(1, -18, 0, 21) or UDim2.new(1, 0, 0, 21),
                    Position = ValueImage and UDim2.fromOffset(18, 0) or UDim2.fromOffset(0, 0),
                    Text = FormattedValue,
                    TextSize = 14,
                    TextTransparency = 0.5,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = Container,
                })
                New("UIPadding", {
                    PaddingLeft = UDim.new(0, 8),
                    PaddingRight = UDim.new(0, 8),
                    Parent = Button,
                })

                local Selected
                if Info.Multi then
                    Selected = Dropdown.Value[Value]
                else
                    Selected = Dropdown.Value == Value
                end

                function Table:UpdateButton()
                    if Info.Multi then
                        Selected = Dropdown.Value[Value]
                    else
                        Selected = Dropdown.Value == Value
                    end

                    if Info.Multi and Selected then
                        local Base = Library.Scheme.AccentColor
                        local H, S, V = Base:ToHSV()
                        Container.BackgroundColor3 = ItemIndex % 2 == 1
                            and Color3.fromHSV(H, S, math.min(1, V + 0.12))
                            or  Color3.fromHSV(H, S, math.max(0, V - 0.10))
                    elseif not Info.Multi then
                        Container.BackgroundColor3 = Library.Scheme.AccentColor
                    end
                    Container.BackgroundTransparency = IsDisabled and 1 or Selected and 0.75 or 1
                    Button.TextTransparency = IsDisabled and 0.8 or Selected and 0 or 0.4

                    if Image then
                        Image.ImageTransparency = IsDisabled and 0.8 or Selected and 0 or 0.4
                    end
                end

                if not IsDisabled then
                    Button.MouseEnter:Connect(function()
                        if not Selected then
                            TweenService:Create(Button, Library.TweenInfo, { TextTransparency = 0 }):Play()
                        end
                    end)
                    Button.MouseLeave:Connect(function()
                        if not Selected then
                            TweenService:Create(Button, Library.TweenInfo, { TextTransparency = 0.4 }):Play()
                        end
                    end)
                    Button.MouseButton1Click:Connect(function()
                        local Try = not Selected

                        if not (Dropdown:GetActiveValues() == 1 and not Try and not Info.AllowNull) then
                            Selected = Try
                            if Info.Multi then
                                Dropdown.Value[Value] = Selected and true or nil
                            else
                                Dropdown.Value = Selected and Value or nil
                            end

                            for _, OtherButton in Buttons do
                                OtherButton:UpdateButton()
                            end
                        end

                        Table:UpdateButton()
                        Dropdown:Display()

                        Library:UpdateConditionalGroups()
                        Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
                        Library:SafeCallback(Dropdown.Changed, Dropdown.Value)
                    end)
                end

                Table:UpdateButton()
                Dropdown:Display()

                Buttons[Button] = Table
            end

            Dropdown:RecalculateListSize(Count)
        end

        function Dropdown:SetValue(Value)
            if Info.Multi then
                local Table = {}

                for Val, Active in Value or {} do
                    if typeof(Active) ~= "boolean" then
                        Table[Active] = true
                    elseif Active and table.find(Dropdown.Values, Val) then
                        Table[Val] = true
                    end
                end

                Dropdown.Value = Table
            else
                if table.find(Dropdown.Values, Value) then
                    Dropdown.Value = Value
                elseif not Value then
                    Dropdown.Value = nil
                end
            end

            Dropdown:Display()
            for _, Button in Buttons do
                Button:UpdateButton()
            end

            if not Dropdown.Disabled then
                Library:UpdateConditionalGroups()
                Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
                Library:SafeCallback(Dropdown.Changed, Dropdown.Value)
            end
        end

        function Dropdown:SetSelectedValue(Value)
            if not table.find(Dropdown.Values, Value) then
                return
            end

            if Info.Multi then
                Dropdown.Value[Value] = true
            else
                Dropdown.Value = Value
            end

            Dropdown:Display()
            for _, Button in Buttons do
                Button:UpdateButton()
            end

            if not Dropdown.Disabled then
                Library:UpdateConditionalGroups()
                Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
                Library:SafeCallback(Dropdown.Changed, Dropdown.Value)
            end
        end

        function Dropdown:DeselectValue(Value)
            if Info.Multi then
                Dropdown.Value[Value] = nil
            else
                if Dropdown.Value == Value then
                    if Info.AllowNull then
                        Dropdown.Value = nil
                    else
                        return
                    end
                end
            end

            Dropdown:Display()
            for _, Button in Buttons do
                Button:UpdateButton()
            end

            if not Dropdown.Disabled then
                Library:UpdateConditionalGroups()
                Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
                Library:SafeCallback(Dropdown.Changed, Dropdown.Value)
            end
        end

        function Dropdown:ClearSelectedValues()
            if Info.Multi then
                table.clear(Dropdown.Value)
            else
                if Info.AllowNull then
                    Dropdown.Value = nil
                else
                    return
                end
            end

            Dropdown:Display()
            for _, Button in Buttons do
                Button:UpdateButton()
            end

            if not Dropdown.Disabled then
                Library:UpdateConditionalGroups()
                Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
                Library:SafeCallback(Dropdown.Changed, Dropdown.Value)
            end
        end

        function Dropdown:SetValues(Values)
            Dropdown.Values = Values

            if Info.Multi then
                for SelectedValue in pairs(Dropdown.Value) do
                    if not table.find(Dropdown.Values, SelectedValue) then
                        Dropdown.Value[SelectedValue] = nil
                    end
                end
            else
                if Dropdown.Value and not table.find(Dropdown.Values, Dropdown.Value) then
                    if Info.AllowNull then
                        Dropdown.Value = nil
                    else
                        Dropdown.Value = Dropdown.Values[1] or nil
                    end
                end
            end

            Dropdown:BuildDropdownList()
            Dropdown:Display()
            for _, Button in Buttons do
                Button:UpdateButton()
            end

            if not Dropdown.Disabled then
                Library:UpdateConditionalGroups()
                Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
                Library:SafeCallback(Dropdown.Changed, Dropdown.Value)
            end
        end

        function Dropdown:AddValues(Values)
            if typeof(Values) == "table" then
                for _, val in Values do
                    table.insert(Dropdown.Values, val)
                end
            elseif typeof(Values) == "string" then
                table.insert(Dropdown.Values, Values)
            else
                return
            end

            Dropdown:BuildDropdownList()
        end

        function Dropdown:SetDisabledValues(DisabledValues)
            Dropdown.DisabledValues = DisabledValues
            Dropdown:BuildDropdownList()
        end

        function Dropdown:AddDisabledValues(DisabledValues)
            if typeof(DisabledValues) == "table" then
                for _, val in DisabledValues do
                    table.insert(Dropdown.DisabledValues, val)
                end
            elseif typeof(DisabledValues) == "string" then
                table.insert(Dropdown.DisabledValues, DisabledValues)
            else
                return
            end

            Dropdown:BuildDropdownList()
        end

        function Dropdown:SetValueImages(ValueImages)
            if typeof(ValueImages) ~= "table" then
                return
            end

            Dropdown.ValueImages = ValueImages
            Dropdown:BuildDropdownList()
        end

        function Dropdown:AddValueImages(ValueImages)
            if typeof(ValueImages) ~= "table" then
                return
            end

            for key, val in ValueImages do
                Dropdown.ValueImages[key] = val
            end

            Dropdown:BuildDropdownList()
        end

        function Dropdown:SetDisabled(Disabled: boolean)
            Dropdown.Disabled = Disabled

            if Dropdown.TooltipTable then
                Dropdown.TooltipTable.Disabled = Dropdown.Disabled
            end

            MenuTable:Close()
            DisplayButton.Active = not Dropdown.Disabled
            Dropdown:UpdateColors()
        end

        function Dropdown:SetVisible(Visible: boolean)
            Dropdown.Visible = Visible

            Holder.Visible = Dropdown.Visible
            Section:Resize()
        end

        function Dropdown:SetText(Text: string)
            Dropdown.Text = Text
            Label.Size = UDim2.new(1, 0, 0, Text and 18 or 0)
            Label.Text = Text and Text or ""
            Label.Visible = not not Text
        end

        local ToggleDropdown = function()
            if Dropdown.Disabled then
                return
            end

            MenuTable:Toggle()
        end

        DisplayContainer.MouseButton1Click:Connect(ToggleDropdown)
        DisplayButton.MouseButton1Click:Connect(ToggleDropdown)

        if SearchBox then
            SearchBox:GetPropertyChangedSignal("Text"):Connect(Dropdown.BuildDropdownList)
        end

        local Defaults = {}
        if typeof(Info.Default) == "string" then
            local Index = table.find(Dropdown.Values, Info.Default)
            if Index then
                table.insert(Defaults, Index)
            end
        elseif typeof(Info.Default) == "table" then
            for _, Value in next, Info.Default do
                local Index = table.find(Dropdown.Values, Value)
                if Index then
                    table.insert(Defaults, Index)
                end
            end
        elseif Dropdown.Values[Info.Default] ~= nil then
            table.insert(Defaults, Info.Default)
        end

        if next(Defaults) then
            for i = 1, #Defaults do
                local Index = Defaults[i]
                if Info.Multi then
                    Dropdown.Value[Dropdown.Values[Index]] = true
                else
                    Dropdown.Value = Dropdown.Values[Index]
                end

                if not Info.Multi then
                    break
                end
            end
        end

        if typeof(Dropdown.Tooltip) == "string" or typeof(Dropdown.DisabledTooltip) == "string" then
            Dropdown.TooltipTable = Library:AddTooltip(Dropdown.Tooltip, Dropdown.DisabledTooltip, DisplayContainer)
            Dropdown.TooltipTable.Disabled = Dropdown.Disabled
        end

        Dropdown:UpdateColors()
        Dropdown:Display()
        Dropdown:BuildDropdownList()
        Section:Resize()

        Dropdown.Holder = Holder
        table.insert(Section.Elements, Dropdown)

        Dropdown.Default = Defaults
        Dropdown.DefaultValues = Dropdown.Values

        Options[Idx] = Dropdown

        return Dropdown
    end

    function Funcs:AddViewport(Idx, Info)
        Info = Library:Validate(Info, Templates.Viewport)

        local Section = self
        local Container = Section.Container

        local Dragging, Pinching = false, false
        local LastMousePos, LastPinchDist = nil, 0

        local ViewportObject = Info.Object
        if Info.Clone and typeof(Info.Object) == "Instance" then
            if Info.Object.Archivable then
                ViewportObject = ViewportObject:Clone()
            else
                Info.Object.Archivable = true
                ViewportObject = ViewportObject:Clone()
                Info.Object.Archivable = false
            end
        end

        local ViewportCamera = if not Info.Camera then Instance.new("Camera") else Info.Camera
        if not Info.Camera then
            ViewportCamera.Name = "ViewportCamera"
            ViewportCamera.Parent = ViewportFrame
        end

        local Viewport = {
            Object = ViewportObject,
            Camera = ViewportCamera,
            Interactive = Info.Interactive,
            AutoFocus = Info.AutoFocus,
            Visible = Info.Visible,
            Type = "Viewport",
        }

        assert(
            typeof(Viewport.Object) == "Instance" and (Viewport.Object:IsA("BasePart") or Viewport.Object:IsA("Model")),
            "Instance must be a BasePart or Model."
        )

        assert(
            typeof(Viewport.Camera) == "Instance" and Viewport.Camera:IsA("Camera"),
            "Camera must be a valid Camera instance."
        )

        local function GetModelSize(model)
            if model:IsA("BasePart") then
                return model.Size
            end

            return select(2, model:GetBoundingBox())
        end

        local function FocusCamera()
            local ModelSize = GetModelSize(Viewport.Object)
            local MaxExtent = math.max(ModelSize.X, ModelSize.Y, ModelSize.Z)
            local CameraDistance = MaxExtent * 1.5
            local ModelPosition = Viewport.Object:GetPivot().Position

            ViewportCamera.CFrame =
                CFrame.new(ModelPosition + Vector3.new(0, 0, CameraDistance), ModelPosition)
        end

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, Info.Height),
            Visible = Viewport.Visible,
            Parent = Container,
        })

        local Box = New("Frame", {
            AnchorPoint = Vector2.new(0, 1),
            BackgroundColor3 = "BackgroundColor",
            BorderColor3 = "OutlineColor",
            BorderSizePixel = 1,
            Position = UDim2.fromScale(0, 1),
            Size = UDim2.fromScale(1, 1),
            Parent = Holder,
        })

        New("UIPadding", {
            PaddingBottom = UDim.new(0, 4),
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
            PaddingTop = UDim.new(0, 4),
            Parent = Box,
        })

        local ViewportFrame = New("ViewportFrame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Parent = Box,
            CurrentCamera = ViewportCamera,
            Active = Viewport.Interactive,
        })

        ViewportFrame.MouseEnter:Connect(function()
            if not Viewport.Interactive then
                return
            end

            for _, Side in Section.Tab.Sides do
                Side.ScrollingEnabled = false
            end
        end)

        ViewportFrame.MouseLeave:Connect(function()
            if not Viewport.Interactive then
                return
            end

            for _, Side in Section.Tab.Sides do
                Side.ScrollingEnabled = true
            end
        end)

        ViewportFrame.InputBegan:Connect(function(input)
            if not Viewport.Interactive then
                return
            end

            if input.UserInputType == Enum.UserInputType.MouseButton2 then
                Dragging = true
                LastMousePos = input.Position
            elseif input.UserInputType == Enum.UserInputType.Touch and not Pinching then
                Dragging = true
                LastMousePos = input.Position
            end
        end)

        Library:GiveSignal(UserInputService.InputEnded:Connect(function(input)
            if Library.Unloaded then
                return
            end

            if not Viewport.Interactive then
                return
            end

            if input.UserInputType == Enum.UserInputType.MouseButton2 then
                Dragging = false
            elseif input.UserInputType == Enum.UserInputType.Touch then
                Dragging = false
            end
        end))

        Library:GiveSignal(UserInputService.InputChanged:Connect(function(input)
            if Library.Unloaded then
                return
            end

            if not Viewport.Interactive or not Dragging or Pinching then
                return
            end

            if
                input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch
            then
                local MouseDelta = input.Position - LastMousePos
                LastMousePos = input.Position

                local Position = Viewport.Object:GetPivot().Position
                local Camera = ViewportCamera

                local RotationY = CFrame.fromAxisAngle(Vector3.new(0, 1, 0), -MouseDelta.X * 0.01)
                Camera.CFrame = CFrame.new(Position) * RotationY * CFrame.new(-Position) * Camera.CFrame

                local RotationX = CFrame.fromAxisAngle(Camera.CFrame.RightVector, -MouseDelta.Y * 0.01)
                local PitchedCFrame = CFrame.new(Position) * RotationX * CFrame.new(-Position) * Camera.CFrame

                if PitchedCFrame.UpVector.Y > 0.1 then
                    Camera.CFrame = PitchedCFrame
                end
            end
        end))

        ViewportFrame.InputChanged:Connect(function(input)
            if not Viewport.Interactive then
                return
            end

            if input.UserInputType == Enum.UserInputType.MouseWheel then
                local ZoomAmount = input.Position.Z * 2
                ViewportCamera.CFrame += ViewportCamera.CFrame.LookVector * ZoomAmount
            end
        end)

        Library:GiveSignal(UserInputService.TouchPinch:Connect(function(touchPositions, scale, velocity, state)
            if Library.Unloaded then
                return
            end

            if not Viewport.Interactive or not Library:MouseIsOverFrame(ViewportFrame, touchPositions[1]) then
                return
            end

            if state == Enum.UserInputState.Begin then
                Pinching = true
                Dragging = false
                LastPinchDist = (touchPositions[1] - touchPositions[2]).Magnitude
            elseif state == Enum.UserInputState.Change then
                local currentDist = (touchPositions[1] - touchPositions[2]).Magnitude
                local delta = (currentDist - LastPinchDist) * 0.1
                LastPinchDist = currentDist
                ViewportCamera.CFrame += ViewportCamera.CFrame.LookVector * delta
            elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
                Pinching = false
            end
        end))

        pcall(function()
            Viewport.Object.Parent = ViewportFrame
        end)
        if Viewport.AutoFocus then
            FocusCamera()
        end

        function Viewport:SetObject(Object: Instance, Clone: boolean?)
            assert(Object, "Object cannot be nil.")

            if Clone then
                Object = Object:Clone()
            end

            if Viewport.Object and Viewport.Object ~= Object then
                pcall(function()
                    Viewport.Object:Destroy()
                end)
            end

            Viewport.Object = Object
            pcall(function()
                Viewport.Object.Parent = ViewportFrame
            end)

            Section:Resize()
        end

        function Viewport:SetHeight(Height: number)
            assert(Height > 0, "Height must be greater than 0.")

            Holder.Size = UDim2.new(1, 0, 0, Height)
            Section:Resize()
        end

        function Viewport:Focus()
            if not Viewport.Object then
                return
            end

            FocusCamera()
        end

        function Viewport:SetCamera(Camera: Instance)
            assert(
                Camera and typeof(Camera) == "Instance" and Camera:IsA("Camera"),
                "Camera must be a valid Camera instance."
            )

            ViewportCamera = Camera
            Viewport.Camera = Camera
            ViewportFrame.CurrentCamera = Camera
        end

        function Viewport:SetInteractive(Interactive: boolean)
            Viewport.Interactive = Interactive
            ViewportFrame.Active = Interactive
        end

        function Viewport:SetVisible(Visible: boolean)
            Viewport.Visible = Visible

            Holder.Visible = Viewport.Visible
            Section:Resize()
        end

        Section:Resize()

        Viewport.Holder = Holder
        table.insert(Section.Elements, Viewport)

        Options[Idx] = Viewport

        return Viewport
    end

    function Funcs:AddImage(Idx, Info)
        Info = Library:Validate(Info, Templates.Image)

        local Section = self
        local Container = Section.Container

        local Image = {
            Image = Info.Image,
            Color = Info.Color,
            RectOffset = Info.RectOffset,
            RectSize = Info.RectSize,
            Height = Info.Height,
            ScaleType = Info.ScaleType,
            Transparency = Info.Transparency,
            BackgroundTransparency = Info.BackgroundTransparency,

            Visible = Info.Visible,
            Type = "Image",
        }

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, Info.Height),
            Visible = Image.Visible,
            Parent = Container,
        })

        local Box = New("Frame", {
            AnchorPoint = Vector2.new(0, 1),
            BackgroundColor3 = "MainColor",
            BorderColor3 = "OutlineColor",
            BorderSizePixel = 1,
            BackgroundTransparency = Image.BackgroundTransparency,
            Position = UDim2.fromScale(0, 1),
            Size = UDim2.fromScale(1, 1),
            Parent = Holder,
        })

        New("UIPadding", {
            PaddingBottom = UDim.new(0, 4),
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
            PaddingTop = UDim.new(0, 4),
            Parent = Box,
        })

        local ImageProperties = {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Image = Image.Image,
            ImageTransparency = Image.Transparency,
            ImageColor3 = Image.Color,
            ImageRectOffset = Image.RectOffset,
            ImageRectSize = Image.RectSize,
            ScaleType = Image.ScaleType,
            Parent = Box,
        }

        local Icon = Library:GetCustomIcon(ImageProperties.Image)
        assert(Icon, "Image must be a valid Roblox asset or a valid URL or a valid lucide icon.")

        ImageProperties.Image = Icon.Url
        ImageProperties.ImageRectOffset = Icon.ImageRectOffset
        ImageProperties.ImageRectSize = Icon.ImageRectSize

        local ImageLabel = New("ImageLabel", ImageProperties)

        function Image:SetHeight(Height: number)
            assert(Height > 0, "Height must be greater than 0.")

            Image.Height = Height
            Holder.Size = UDim2.new(1, 0, 0, Height)
            Section:Resize()
        end

        function Image:SetImage(NewImage: string)
            assert(typeof(NewImage) == "string", "Image must be a string.")

            local Icon = Library:GetCustomIcon(NewImage)
            assert(Icon, "Image must be a valid Roblox asset or a valid URL or a valid lucide icon.")

            NewImage = Icon.Url
            Image.RectOffset = Icon.ImageRectOffset
            Image.RectSize = Icon.ImageRectSize

            ImageLabel.Image = NewImage
            Image.Image = NewImage
        end

        function Image:SetColor(Color: Color3)
            assert(typeof(Color) == "Color3", "Color must be a Color3 value.")

            ImageLabel.ImageColor3 = Color
            Image.Color = Color
        end

        function Image:SetRectOffset(RectOffset: Vector2)
            assert(typeof(RectOffset) == "Vector2", "RectOffset must be a Vector2 value.")

            ImageLabel.ImageRectOffset = RectOffset
            Image.RectOffset = RectOffset
        end

        function Image:SetRectSize(RectSize: Vector2)
            assert(typeof(RectSize) == "Vector2", "RectSize must be a Vector2 value.")

            ImageLabel.ImageRectSize = RectSize
            Image.RectSize = RectSize
        end

        function Image:SetScaleType(ScaleType: Enum.ScaleType)
            assert(
                typeof(ScaleType) == "EnumItem" and ScaleType:IsA("ScaleType"),
                "ScaleType must be a valid Enum.ScaleType."
            )

            ImageLabel.ScaleType = ScaleType
            Image.ScaleType = ScaleType
        end

        function Image:SetTransparency(Transparency: number)
            assert(typeof(Transparency) == "number", "Transparency must be a number between 0 and 1.")
            assert(Transparency >= 0 and Transparency <= 1, "Transparency must be between 0 and 1.")

            ImageLabel.ImageTransparency = Transparency
            Image.Transparency = Transparency
        end

        function Image:SetVisible(Visible: boolean)
            Image.Visible = Visible

            Holder.Visible = Image.Visible
            Section:Resize()
        end

        Section:Resize()

        Image.Holder = Holder
        table.insert(Section.Elements, Image)

        Options[Idx] = Image

        return Image
    end

    function Funcs:AddVideo(Idx, Info)
        Info = Library:Validate(Info, Templates.Video)

        local Section = self
        local Container = Section.Container

        local Video = {
            Video = Info.Video,
            Looped = Info.Looped,
            Playing = Info.Playing,
            Volume = Info.Volume,
            Height = Info.Height,
            Visible = Info.Visible,

            Type = "Video",
        }

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, Info.Height),
            Visible = Video.Visible,
            Parent = Container,
        })

        local Box = New("Frame", {
            AnchorPoint = Vector2.new(0, 1),
            BackgroundColor3 = "MainColor",
            BorderColor3 = "OutlineColor",
            BorderSizePixel = 1,
            Position = UDim2.fromScale(0, 1),
            Size = UDim2.fromScale(1, 1),
            Parent = Holder,
        })

        New("UIPadding", {
            PaddingBottom = UDim.new(0, 4),
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
            PaddingTop = UDim.new(0, 4),
            Parent = Box,
        })

        local VideoFrameInstance = New("VideoFrame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Video = Video.Video,
            Looped = Video.Looped,
            Volume = Video.Volume,
            Parent = Box,
        })

        VideoFrameInstance.Playing = Video.Playing

        function Video:SetHeight(Height: number)
            assert(Height > 0, "Height must be greater than 0.")

            Video.Height = Height
            Holder.Size = UDim2.new(1, 0, 0, Height)
            Section:Resize()
        end

        function Video:SetVideo(NewVideo: string)
            assert(typeof(NewVideo) == "string", "Video must be a string.")

            VideoFrameInstance.Video = NewVideo
            Video.Video = NewVideo
        end

        function Video:SetLooped(Looped: boolean)
            assert(typeof(Looped) == "boolean", "Looped must be a boolean.")

            VideoFrameInstance.Looped = Looped
            Video.Looped = Looped
        end

        function Video:SetVolume(Volume: number)
            assert(typeof(Volume) == "number", "Volume must be a number between 0 and 10.")

            VideoFrameInstance.Volume = Volume
            Video.Volume = Volume
        end

        function Video:SetPlaying(Playing: boolean)
            assert(typeof(Playing) == "boolean", "Playing must be a boolean.")

            VideoFrameInstance.Playing = Playing
            Video.Playing = Playing
        end

        function Video:Play()
            VideoFrameInstance.Playing = true
            Video.Playing = true
        end

        function Video:Pause()
            VideoFrameInstance.Playing = false
            Video.Playing = false
        end

        function Video:SetVisible(Visible: boolean)
            Video.Visible = Visible

            Holder.Visible = Video.Visible
            Section:Resize()
        end

        Section:Resize()

        Video.Holder = Holder
        Video.VideoFrame = VideoFrameInstance
        table.insert(Section.Elements, Video)

        Options[Idx] = Video

        return Video
    end

    function Funcs:AddUIPassthrough(Idx, Info)
        Info = Library:Validate(Info, Templates.UIPassthrough)

        local Section = self
        local Container = Section.Container

        assert(Info.Instance, "Instance must be provided.")
        assert(
            typeof(Info.Instance) == "Instance" and Info.Instance:IsA("GuiBase2d"),
            "Instance must inherit from GuiBase2d."
        )
        assert(typeof(Info.Height) == "number" and Info.Height > 0, "Height must be a number greater than 0.")

        local Passthrough = {
            Instance = Info.Instance,
            Height = Info.Height,
            Visible = Info.Visible,

            Type = "UIPassthrough",
        }

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            ClipsDescendants = true,
            Size = UDim2.new(1, 0, 0, Info.Height),
            Visible = Passthrough.Visible,

            Parent = Container,
        })

        pcall(function()
            local CurrentSize = Passthrough.Instance.Size
            if CurrentSize.X.Offset == 0 and CurrentSize.X.Scale == 0
                or CurrentSize.Y.Offset == 0 and CurrentSize.Y.Scale == 0 then
                Passthrough.Instance.Size = UDim2.new(1, 0, 1, 0)
                Passthrough.Instance.Position = UDim2.new(0, 0, 0, 0)
            end
        end)

        local PassthroughZIndex = Holder.ZIndex + 1
        Passthrough.Instance.ZIndex = PassthroughZIndex
        for _, Descendant in Passthrough.Instance:GetDescendants() do
            if Descendant:IsA("GuiObject") then
                Descendant.ZIndex = PassthroughZIndex
            end
        end

        pcall(function()
            Passthrough.Instance.Parent = Holder
        end)

        Section:Resize()

        function Passthrough:SetHeight(Height: number)
            assert(typeof(Height) == "number" and Height > 0, "Height must be a number greater than 0.")

            Passthrough.Height = Height
            Holder.Size = UDim2.new(1, 0, 0, Height)
            Section:Resize()
        end

        function Passthrough:SetInstance(NewInstance: Instance)
            assert(NewInstance, "Instance must be provided.")
            assert(
                typeof(NewInstance) == "Instance" and NewInstance:IsA("GuiBase2d"),
                "Instance must inherit from GuiBase2d."
            )

            if Passthrough.Instance then
                Passthrough.Instance.Parent = nil
            end

            Passthrough.Instance = NewInstance
            pcall(function()
                local CurrentSize = Passthrough.Instance.Size
                if CurrentSize.X.Offset == 0 and CurrentSize.X.Scale == 0
                    or CurrentSize.Y.Offset == 0 and CurrentSize.Y.Scale == 0 then
                    Passthrough.Instance.Size = UDim2.new(1, 0, 1, 0)
                    Passthrough.Instance.Position = UDim2.new(0, 0, 0, 0)
                end
            end)

            local PassthroughZIndex = Holder.ZIndex + 1
            Passthrough.Instance.ZIndex = PassthroughZIndex
            for _, Descendant in Passthrough.Instance:GetDescendants() do
                if Descendant:IsA("GuiObject") then
                    Descendant.ZIndex = PassthroughZIndex
                end
            end

            pcall(function()
                Passthrough.Instance.Parent = Holder
            end)
        end

        function Passthrough:SetVisible(Visible: boolean)
            Passthrough.Visible = Visible

            Holder.Visible = Passthrough.Visible
            Section:Resize()
        end

        Passthrough.Holder = Holder
        table.insert(Section.Elements, Passthrough)

        Options[Idx] = Passthrough

        return Passthrough
    end

    function Funcs:AddConditionalGroup()
        local Section = self
        local Container = Section.Container

        local ConditionalGroupContainer
        local ConditionalGroupList

        do
            ConditionalGroupContainer = New("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                Visible = false,
                Parent = Container,
            })

            ConditionalGroupList = New("UIListLayout", {
                Padding = UDim.new(0, 8),
                Parent = ConditionalGroupContainer,
            })
        end

        local ConditionalGroup = {
            Visible = false,
            Dependencies = {},

            Holder = ConditionalGroupContainer,
            Container = ConditionalGroupContainer,

            Elements = {},
            ConditionalGroups = {},
            SubSections = {},
        }

        function ConditionalGroup:Resize()
            ConditionalGroupContainer.Size = UDim2.new(1, 0, 0, ConditionalGroupList.AbsoluteContentSize.Y / Library.DPIScale)
            Section:Resize()
        end

        function ConditionalGroup:Update(CancelSearch)
            for _, Dependency in ConditionalGroup.Dependencies do
                local Element = Dependency[1]
                local Value = Dependency[2]

                if Element.Type == "Toggle" and Element.Value ~= Value then
                    ConditionalGroupContainer.Visible = false
                    ConditionalGroup.Visible = false
                    return
                elseif Element.Type == "Dropdown" then
                    if typeof(Element.Value) == "table" then
                        if not Element.Value[Value] then
                            ConditionalGroupContainer.Visible = false
                            ConditionalGroup.Visible = false
                            return
                        end
                    else
                        if Element.Value ~= Value then
                            ConditionalGroupContainer.Visible = false
                            ConditionalGroup.Visible = false
                            return
                        end
                    end
                end
            end

            ConditionalGroup.Visible = true
            ConditionalGroupContainer.Visible = true
            if not Library.Searching then
                task.defer(function()
                    ConditionalGroup:Resize()
                end)
            elseif not CancelSearch then
                Library:UpdateSearch(Library.SearchText)
            end
        end

        ConditionalGroupList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            if not ConditionalGroup.Visible then
                return
            end

            ConditionalGroup:Resize()
        end)

        function ConditionalGroup:SetupDependencies(Dependencies)
            for _, Dependency in Dependencies do
                assert(typeof(Dependency) == "table", "Dependency should be a table.")
                assert(Dependency[1] ~= nil, "Dependency is missing element.")
                assert(Dependency[2] ~= nil, "Dependency is missing expected value.")
            end

            ConditionalGroup.Dependencies = Dependencies
            ConditionalGroup:Update()
        end

        ConditionalGroupContainer:GetPropertyChangedSignal("Visible"):Connect(function()
            ConditionalGroup:Resize()
        end)

        setmetatable(ConditionalGroup, BaseSection)

        table.insert(Section.ConditionalGroups, ConditionalGroup)
        table.insert(Library.ConditionalGroups, ConditionalGroup)

        return ConditionalGroup
    end

    function Funcs:AddConditionalSection()
        local Section = self
        local Tab = Section.Tab
        local BoxHolder = Section.BoxHolder

        local ConditionalSectionContainer
        local ConditionalSectionList

        do
            ConditionalSectionContainer = New("Frame", {
                BackgroundColor3 = "BackgroundColor",
                Size = UDim2.fromScale(1, 0),
                Visible = false,
                Parent = BoxHolder,
            })
            table.insert(
                Library.Corners,
                New("UICorner", {
                    CornerRadius = UDim.new(0, Library.CornerRadius),
                    Parent = ConditionalSectionContainer,
                })
            )
            Library:AddOutline(ConditionalSectionContainer)

            ConditionalSectionList = New("UIListLayout", {
                Padding = UDim.new(0, 8),
                Parent = ConditionalSectionContainer,
            })
            New("UIPadding", {
                PaddingBottom = UDim.new(0, 10),
                PaddingLeft = UDim.new(0, 10),
                PaddingRight = UDim.new(0, 10),
                PaddingTop = UDim.new(0, 10),
                Parent = ConditionalSectionContainer,
            })
        end

        local ConditionalSection = {
            Visible = false,
            Dependencies = {},

            BoxHolder = BoxHolder,
            Holder = ConditionalSectionContainer,
            Container = ConditionalSectionContainer,

            Tab = Tab,
            Elements = {},
            ConditionalGroups = {},
            SubSections = {},
        }

        function ConditionalSection:Resize()
            ConditionalSectionContainer.Size = UDim2.new(1, 0, 0, (ConditionalSectionList.AbsoluteContentSize.Y / Library.DPIScale) + 24)
        end

        function ConditionalSection:Update(CancelSearch)
            for _, Dependency in ConditionalSection.Dependencies do
                local Element = Dependency[1]
                local Value = Dependency[2]

                if Element.Type == "Toggle" and Element.Value ~= Value then
                    ConditionalSectionContainer.Visible = false
                    ConditionalSection.Visible = false
                    return
                elseif Element.Type == "Dropdown" then
                    if typeof(Element.Value) == "table" then
                        if not Element.Value[Value] then
                            ConditionalSectionContainer.Visible = false
                            ConditionalSection.Visible = false
                            return
                        end
                    else
                        if Element.Value ~= Value then
                            ConditionalSectionContainer.Visible = false
                            ConditionalSection.Visible = false
                            return
                        end
                    end
                end
            end

            ConditionalSection.Visible = true
            if not Library.Searching then
                ConditionalSectionContainer.Visible = true
                ConditionalSection:Resize()
            elseif not CancelSearch then
                Library:UpdateSearch(Library.SearchText)
            end
        end

        function ConditionalSection:SetupDependencies(Dependencies)
            for _, Dependency in Dependencies do
                assert(typeof(Dependency) == "table", "Dependency should be a table.")
                assert(Dependency[1] ~= nil, "Dependency is missing element.")
                assert(Dependency[2] ~= nil, "Dependency is missing expected value.")
            end

            ConditionalSection.Dependencies = Dependencies
            ConditionalSection:Update()
        end

        setmetatable(ConditionalSection, BaseSection)

        table.insert(Tab.ConditionalSections, ConditionalSection)
        table.insert(Library.ConditionalGroups, ConditionalSection)

        return ConditionalSection
    end

    function Funcs:AddSubSection(NameOrInfo, IconName)
        local Section = self
        local Container = Section.Container

        local Info
        if typeof(NameOrInfo) == "table" then
            Info = NameOrInfo
        else
            Info = { Name = NameOrInfo, IconName = IconName }
        end

        if not Section.SubSectionLayout then
            Section.SubSectionLayout = {
                CurrentLayoutMode = nil,
                CurrentColumnsRow = nil,
                CurrentColumnLeft = nil,
                CurrentColumnRight = nil,
                NextOrder = 0,
            }
        end

        local SubSectionLayout = Section.SubSectionLayout

        local function GetSubSectionParent(Side)
            local RequestedMode = (Side == 1 or Side == 2) and "two-column" or nil

            local NeedNewRow = SubSectionLayout.CurrentLayoutMode ~= RequestedMode

            if NeedNewRow then
                SubSectionLayout.CurrentLayoutMode = RequestedMode

                if RequestedMode == "two-column" then

                    SubSectionLayout.CurrentColumnsRow = New("Frame", {
                        AutomaticSize = Enum.AutomaticSize.Y,
                        BackgroundTransparency = 1,
                        LayoutOrder = SubSectionLayout.NextOrder,
                        Size = UDim2.new(1, 0, 0, 0),
                        Parent = Container,
                    })

                    SubSectionLayout.CurrentColumnLeft = New("Frame", {
                        AutomaticSize = Enum.AutomaticSize.Y,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(0.5, -3, 0, 0),
                        Parent = SubSectionLayout.CurrentColumnsRow,
                    })
                    New("UIListLayout", {
                        Padding = UDim.new(0, 2),
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        Parent = SubSectionLayout.CurrentColumnLeft,
                    })

                    SubSectionLayout.CurrentColumnRight = New("Frame", {
                        AnchorPoint = Vector2.new(1, 0),
                        AutomaticSize = Enum.AutomaticSize.Y,
                        BackgroundTransparency = 1,
                        Position = UDim2.fromScale(1, 0),
                        Size = UDim2.new(0.5, -3, 0, 0),
                        Parent = SubSectionLayout.CurrentColumnsRow,
                    })
                    New("UIListLayout", {
                        Padding = UDim.new(0, 2),
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        Parent = SubSectionLayout.CurrentColumnRight,
                    })

                    SubSectionLayout.NextOrder = SubSectionLayout.NextOrder + 1
                else

                    SubSectionLayout.NextOrder = SubSectionLayout.NextOrder + 1
                end
            end

            if RequestedMode == "two-column" then
                return Side == 1 and SubSectionLayout.CurrentColumnLeft or SubSectionLayout.CurrentColumnRight
            else
                local Order = SubSectionLayout.NextOrder - 1
                return Container, Order
            end
        end

        local SubSectionParent, SubSectionOrder = GetSubSectionParent(Info.Side)

        local SubSectionHolder
        local SubSectionLabel
        local SubSectionContainer
        local SubSectionList
        local SubSectionSeparatorLine

        do
            SubSectionHolder = New("Frame", {
                BackgroundColor3 = "MainColor",
                BackgroundTransparency = 0.3,
                Size = UDim2.new(1, 0, 0, 0),
                LayoutOrder = SubSectionOrder or 0,
                Parent = SubSectionParent,
            })
            table.insert(
                Library.Corners,
                New("UICorner", {
                    CornerRadius = UDim.new(0, 4),
                    Parent = SubSectionHolder,
                })
            )
            Library:AddOutline(SubSectionHolder)

            SubSectionSeparatorLine = Library:MakeLine(SubSectionHolder, {
                Position = UDim2.fromOffset(0, 28),
                Size = UDim2.new(1, 0, 0, 1),
            })

            local BoxIcon = Library:GetCustomIcon(Info.IconName)
            if BoxIcon then
                New("ImageLabel", {
                    Image = BoxIcon.Url,
                    ImageColor3 = BoxIcon.Custom and "WhiteColor" or "AccentColor",
                    ImageRectOffset = BoxIcon.ImageRectOffset,
                    ImageRectSize = BoxIcon.ImageRectSize,
                    Position = UDim2.fromOffset(11, 4),
                    Size = UDim2.fromOffset(18, 18),
                    Parent = SubSectionHolder,
                })
            end

            local SubSectionHeaderBtn = New("TextButton", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(0, 0),
                Size = UDim2.new(1, 0, 0, 28),
                Text = "",
                Parent = SubSectionHolder,
            })

            SubSectionLabel = New("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(BoxIcon and 23 or 3, 0),
                Size = UDim2.new(1, -(BoxIcon and 23 or 3) - 24, 0, 28),
                Text = Info.Name,
                TextSize = 13,
                TextTruncate = Enum.TextTruncate.AtEnd,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = SubSectionHeaderBtn,
            })
            New("UIPadding", {
                PaddingLeft = UDim.new(0, 10),
                PaddingRight = UDim.new(0, 10),
                Parent = SubSectionLabel,
            })

            local SubSectionFoldOpen = Info.DefaultOpen ~= false
            local SectionChevronDown = Library:GetIcon("chevron-down")
            local SectionChevronRight = Library:GetIcon("chevron-right")
            local SubSectionArrow = New("ImageLabel", {
                AnchorPoint = Vector2.new(1, 0.5),
                BackgroundTransparency = 1,
                Position = UDim2.new(1, -8, 0.5, 0),
                Size = UDim2.fromOffset(10, 10),
                ImageColor3 = "FontColor",
                ImageTransparency = 0.5,
                ScaleType = Enum.ScaleType.Fit,
                Image = SubSectionFoldOpen
                    and (SectionChevronDown and SectionChevronDown.Url or "")
                    or (SectionChevronRight and SectionChevronRight.Url or ""),
                ImageRectOffset = SubSectionFoldOpen
                    and (SectionChevronDown and SectionChevronDown.ImageRectOffset or Vector2.zero)
                    or (SectionChevronRight and SectionChevronRight.ImageRectOffset or Vector2.zero),
                ImageRectSize = SubSectionFoldOpen
                    and (SectionChevronDown and SectionChevronDown.ImageRectSize or Vector2.zero)
                    or (SectionChevronRight and SectionChevronRight.ImageRectSize or Vector2.zero),
                Parent = SubSectionHeaderBtn,
            })
            Library:AddToRegistry(SubSectionArrow, { ImageColor3 = "FontColor" })

            SubSectionContainer = New("Frame", {
                BackgroundColor3 = "BackgroundColor",
                BackgroundTransparency = 0.5,
                Position = UDim2.fromOffset(0, 29),
                Size = UDim2.new(1, 0, 1, -29),
                Visible = SubSectionFoldOpen,
                Parent = SubSectionHolder,
            })
            SubSectionSeparatorLine.Visible = SubSectionFoldOpen

            SubSectionList = New("UIListLayout", {
                Padding = UDim.new(0, 8),
                Parent = SubSectionContainer,
            })
            New("UIPadding", {
                PaddingBottom = UDim.new(0, 10),
                PaddingLeft = UDim.new(0, 10),
                PaddingRight = UDim.new(0, 10),
                PaddingTop = UDim.new(0, 10),
                Parent = SubSectionContainer,
            })
        end

        local SubSection = {
            Holder = SubSectionHolder,

            HeaderHolder = SubSectionHeaderBtn,
            Container = SubSectionContainer,

            Tab = Section.Tab,
            ConditionalGroups = {},
            SubSections = {},
            Elements = {},

            Name = Info.Name,
            ParentSection = Section,
            Folded = not (Info.DefaultOpen ~= false),
            Side = Info.Side,
        }

        function SubSection:Resize()
            if SubSection.Folded then
                SubSectionHolder.Size = UDim2.new(1, 0, 0, 28)
            else
                SubSectionHolder.Size = UDim2.new(1, 0, 0, (SubSectionList.AbsoluteContentSize.Y / Library.DPIScale) + 48)
            end
            Section:Resize()
        end

        do
            local SectionChevronDown = Library:GetIcon("chevron-down")
            local SectionChevronRight = Library:GetIcon("chevron-right")
            local function SetSectionArrowIcon(Arrow, Open)
                local Icon = Open and SectionChevronDown or SectionChevronRight
                if Icon then
                    Arrow.Image = Icon.Url
                    Arrow.ImageRectOffset = Icon.ImageRectOffset
                    Arrow.ImageRectSize = Icon.ImageRectSize
                end
            end

            local HeaderBtn = SubSectionHolder:FindFirstChildWhichIsA("TextButton")
            local Arrow = HeaderBtn and HeaderBtn:FindFirstChildWhichIsA("ImageLabel")

            function SubSection:SetFolded(Folded)
                if SubSection.Folded == Folded then return end
                SubSection.Folded = Folded
                SubSectionContainer.Visible = not SubSection.Folded
                SubSectionSeparatorLine.Visible = not SubSection.Folded
                if Arrow then
                    SetSectionArrowIcon(Arrow, not SubSection.Folded)
                end
                SubSection:Resize()
            end

            if HeaderBtn then
                HeaderBtn.MouseButton1Click:Connect(function()
                    SubSection:SetFolded(not SubSection.Folded)
                end)
            end
        end

        setmetatable(SubSection, BaseSection)

        SubSection:Resize()

        if not Section.SubSections then
            Section.SubSections = {}
        end
        table.insert(Section.SubSections, SubSection)

        return SubSection
    end

    BaseSection.__index = Funcs
    BaseSection.__namecall = function(_, Key, ...)
        return Funcs[Key](...)
    end
end

function Library:SetFont(FontFace)
    if typeof(FontFace) == "EnumItem" then
        FontFace = Font.fromEnum(FontFace)
    end

    Library.Scheme.Font = FontFace
    Library:UpdateColorsUsingRegistry()
end

function Library:SetNotifySide(Side: string)
    Library.NotifySide = Side

    if Side:lower() == "left" then
        NotificationArea.AnchorPoint = Vector2.new(0, 0)
        NotificationArea.Position = UDim2.fromOffset(6, 6)
        NotificationList.HorizontalAlignment = Enum.HorizontalAlignment.Left
    else
        NotificationArea.AnchorPoint = Vector2.new(1, 0)
        NotificationArea.Position = UDim2.new(1, -6, 0, 6)
        NotificationList.HorizontalAlignment = Enum.HorizontalAlignment.Right
    end
end

function Library:Notify(...)
    local Data = {}
    local Info = select(1, ...)

    if typeof(Info) == "table" then
        Data.Title = tostring(Info.Title)
        Data.Description = tostring(Info.Description)
        Data.Time = Info.Time or 5
        Data.SoundId = Info.SoundId
        Data.Steps = Info.Steps
        Data.Persist = Info.Persist
        Data.Icon = Info.Icon
        Data.BigIcon = Info.BigIcon
        Data.IconColor = Info.IconColor
    else
        Data.Description = tostring(Info)
        Data.Time = select(2, ...) or 5
        Data.SoundId = select(3, ...)
    end
    Data.Destroyed = false

    local DeletedInstance = false
    local DeleteConnection = nil
    if typeof(Data.Time) == "Instance" then
        DeleteConnection = Data.Time.Destroying:Connect(function()
            DeletedInstance = true

            if DeleteConnection then
                pcall(function()
                    DeleteConnection:Disconnect()
                end)
                DeleteConnection = nil
            end
        end)
    end

    local FakeBackground = New("Frame", {
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 0),
        Visible = false,
        Parent = NotificationArea,
    })

    local Holder = New("Frame", {
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = "MainColor",
        Position = Library.NotifySide:lower() == "left" and UDim2.new(-1, -8, 0, -2) or UDim2.new(1, 8, 0, -2),
        Size = UDim2.fromScale(1, 1),
        ZIndex = 5,
        Parent = FakeBackground,
    })
    table.insert(
        Library.Corners,
        New("UICorner", {
            CornerRadius = UDim.new(0, Library.CornerRadius),
            Parent = Holder,
        })
    )
    New("UIListLayout", {
        Padding = UDim.new(0, 4),
        Parent = Holder,
    })
    New("UIPadding", {
        PaddingBottom = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
        PaddingTop = UDim.new(0, 8),
        Parent = Holder,
    })
    Library:AddOutline(Holder)

    local ContentContainer = New("Frame", {
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.XY,
        Size = UDim2.fromScale(1, 0),
        Parent = Holder,
    })

    if Data.BigIcon then
        New("UIListLayout", {
            Padding = UDim.new(0, 8),
            FillDirection = Enum.FillDirection.Horizontal,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Parent = ContentContainer,
        })
    end

    local BigIconLabel
    if Data.BigIcon then
        local ParsedIcon = Library:GetCustomIcon(Data.BigIcon)
        if ParsedIcon then
            BigIconLabel = New("ImageLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.fromOffset(24, 24),
                Image = ParsedIcon.Url,
                ImageColor3 = Data.IconColor or "AccentColor",
                ImageRectOffset = ParsedIcon.ImageRectOffset,
                ImageRectSize = ParsedIcon.ImageRectSize,
                Parent = ContentContainer,
            })
        end
    end

    local TextContainer = New("Frame", {
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.XY,
        Size = UDim2.fromScale(0, 0),
        Parent = ContentContainer,
    })
    New("UIListLayout", {
        Padding = UDim.new(0, 4),
        Parent = TextContainer,
    })

    local TitleContainer
    if Data.Title then
        TitleContainer = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(0, 0),
            Parent = TextContainer,
        })
    end

    local IconLabel
    if Data.Icon and TitleContainer then
        local ParsedIcon = Library:GetCustomIcon(Data.Icon)
        if ParsedIcon then
            IconLabel = New("ImageLabel", {
                BackgroundTransparency = 1,
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 0, 0.5, 1),
                Size = UDim2.fromOffset(15, 15),
                Image = ParsedIcon.Url,
                ImageColor3 = Data.IconColor or "FontColor",
                ImageRectOffset = ParsedIcon.ImageRectOffset,
                ImageRectSize = ParsedIcon.ImageRectSize,
                Parent = TitleContainer,
            })
        end
    end

    local Title
    local Desc
    local TitleX = 0
    local DescX = 0

    local TimerFill

    if Data.Title then
        Title = New("TextLabel", {
            AutomaticSize = Enum.AutomaticSize.None,
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, (Data.Icon and 21 or 0), 0.5, 0),
            Size = UDim2.fromScale(0, 0),
            Text = Data.Title,
            TextSize = 15,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
            TextWrapped = true,
            Parent = TitleContainer,
        })
    end

    if Data.Description then
        Desc = New("TextLabel", {
            AutomaticSize = Enum.AutomaticSize.None,
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(0, 0),
            Text = Data.Description,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            Parent = TextContainer,
        })
    end

    function Data:Resize()
        local ExtraWidth = BigIconLabel and 32 or 0
        local IconWidth = IconLabel and 21 or 0

        if Title then
            local X, Y =
                Library:GetTextBounds(Title.Text, Title.FontFace, Title.TextSize, (NotificationArea.AbsoluteSize.X / Library.DPIScale) - 24 - ExtraWidth - IconWidth)
            Title.Size = UDim2.fromOffset(X, Y)
            TitleX = X + IconWidth
            TitleContainer.Size = UDim2.fromOffset(TitleX, math.max(Y, IconLabel and 16 or 0))
        end

        if Desc then
            local X, Y =
                Library:GetTextBounds(Desc.Text, Desc.FontFace, Desc.TextSize, (NotificationArea.AbsoluteSize.X / Library.DPIScale) - 24 - ExtraWidth)
            Desc.Size = UDim2.fromOffset(X, Y)
            DescX = X
        end

        FakeBackground.Size = UDim2.fromOffset(math.max(TitleX, DescX) + 24 + ExtraWidth, 0)
    end

    function Data:ChangeTitle(Text)
        if Title then
            Data.Title = tostring(Text)
            Title.Text = Data.Title
            Data:Resize()
        end
    end

    function Data:ChangeDescription(Text)
        if Desc then
            Data.Description = tostring(Text)
            Desc.Text = Data.Description
            Data:Resize()
        end
    end

    function Data:ChangeStep(NewStep)
        if TimerFill and Data.Steps then
            NewStep = math.clamp(NewStep or 0, 0, Data.Steps)
            TimerFill.Size = UDim2.fromScale(NewStep / Data.Steps, 1)
        end
    end

    function Data:Destroy()
        Data.Destroyed = true

        if typeof(Data.Time) == "Instance" then
            pcall(Data.Time.Destroy, Data.Time)
        end

        if DeleteConnection and DeleteConnection.Connected then
            pcall(function()
                DeleteConnection:Disconnect()
            end)
        end

        TweenService
            :Create(Holder, Library.NotifyTweenInfo, {
                Position = Library.NotifySide:lower() == "left" and UDim2.new(-1, -8, 0, -2) or UDim2.new(1, 8, 0, -2),
            })
            :Play()

        task.delay(Library.NotifyTweenInfo.Time, function()
            Library.Notifications[FakeBackground] = nil
            FakeBackground:Destroy()
        end)
    end

    Data:Resize()

    local TimerHolder = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 7),
        Visible = (Data.Persist ~= true and typeof(Data.Time) ~= "Instance") or typeof(Data.Steps) == "number",
        Parent = Holder,
    })
    local TimerBar = New("Frame", {
        BackgroundColor3 = "BackgroundColor",
        BorderColor3 = "OutlineColor",
        BorderSizePixel = 1,
        Position = UDim2.fromOffset(0, 3),
        Size = UDim2.new(1, 0, 0, 2),
        Parent = TimerHolder,
    })
    TimerFill = New("Frame", {
        BackgroundColor3 = "AccentColor",
        Size = UDim2.fromScale(1, 1),
        Parent = TimerBar,
    })

    if typeof(Data.Time) == "Instance" then
        TimerFill.Size = UDim2.fromScale(0, 1)
    end
    if Data.SoundId then
        local SoundId = Data.SoundId
        if typeof(SoundId) == "number" then
            SoundId = string.format("rbxassetid://%d", SoundId)
        end

        pcall(function()
            local Sound = New("Sound", {
                SoundId = SoundId,
                Volume = 3,
                PlayOnRemove = true,
                Parent = SoundService,
            })
            Sound:Destroy()
        end)
    end

    Library.Notifications[FakeBackground] = Data

    FakeBackground.Visible = true
    TweenService:Create(Holder, Library.NotifyTweenInfo, {
        Position = UDim2.fromOffset(0, 0),
    }):Play()

    task.delay(Library.NotifyTweenInfo.Time, function()
        if Data.Persist then
            return
        elseif typeof(Data.Time) == "Instance" then
            repeat
                task.wait()
            until DeletedInstance or Data.Destroyed
        else
            TweenService
                :Create(TimerFill, TweenInfo.new(Data.Time, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {
                    Size = UDim2.fromScale(0, 1),
                })
                :Play()
            task.wait(Data.Time)
        end

        if not Data.Destroyed then
            Data:Destroy()
        end
    end)

    return Data
end

function Library:CreateWindow(WindowInfo)
    local ExplicitDPIScale = typeof(WindowInfo) == "table" and WindowInfo.DPIScale or nil
    WindowInfo = Library:Validate(WindowInfo, Templates.Window)

    local ShouldWait = WindowInfo.WaitForIconsOnLoad
    if ShouldWait == nil then
        ShouldWait = Library.WaitForIconsOnLoad
    end
    if ShouldWait ~= false then
        Library:WaitForIcons(10)
    end

    if WindowInfo.SingleInstance ~= false then
        local GuiParent = gethui()
        local GuiName = "Astral_" .. tostring(WindowInfo.Title)
        for _, Child in GuiParent:GetChildren() do
            if Child:IsA("ScreenGui") and Child.Name == GuiName then

                local Unloaded = false
                if getgenv and typeof(getgenv) == "function" then
                    local env = getgenv()
                    for _, v in env do
                        if type(v) == "table" and typeof(v.Unload) == "function"
                            and not v.Unloaded and v.ScreenGui == Child then
                            pcall(v.Unload, v)
                            Unloaded = true
                            break
                        end
                    end
                end
                if not Unloaded then
                    pcall(function() Child:Destroy() end)
                end
                break
            end
        end
    end
    local ViewportSize: Vector2 = workspace.CurrentCamera.ViewportSize
    if RunService:IsStudio() and ViewportSize.X <= 5 and ViewportSize.Y <= 5 then
        repeat
            ViewportSize = workspace.CurrentCamera.ViewportSize
            task.wait()
        until ViewportSize.X > 5 and ViewportSize.Y > 5
    end

    -- =========================================================
    -- BASE UI SIZE
    --
    -- WindowInfo.Size is NEVER modified here. The UI is always
    -- created using its original logical dimensions -- DPI/UIScale
    -- is what makes that UI fit the current viewport.
    -- =========================================================
    Library.MinSize = Library.OriginalMinSize

    local BaseWindowSize = Vector2.new(WindowInfo.Size.X.Offset, WindowInfo.Size.Y.Offset)
    Library.BaseWindowSize = BaseWindowSize

    if typeof(WindowInfo.Font) == "EnumItem" then
        WindowInfo.Font = Font.fromEnum(WindowInfo.Font)
    end
    WindowInfo.CornerRadius = math.min(WindowInfo.CornerRadius, 20)

    if WindowInfo.Compact ~= nil then
        WindowInfo.SidebarCompacted = WindowInfo.Compact
    end

    Library.CornerRadius = WindowInfo.CornerRadius
    Library:SetNotifySide(WindowInfo.NotifySide)

    if ScreenGui then
        ScreenGui.Name = "Astral_" .. tostring(WindowInfo.Title)
    end
    Library.ShowCustomCursor = WindowInfo.ShowCustomCursor
    Library.Scheme.Font = WindowInfo.Font
    Library.ToggleKeybind = WindowInfo.ToggleKeybind

    local IsDefaultSearchbarSize = WindowInfo.SearchbarSize == UDim2.fromScale(1, 1)
    local MainFrame
    local DividerLine
    local TitleHolder
    local WindowTitle
    local WindowIcon
    local RightWrapper
    local SearchBox
    local CurrentTabInfo
    local CurrentTabLabel
    local CurrentTabDescription
    local ResizeButton
    local Tabs
    local Container
    local Sidebar
    local BackgroundImage
    local BottomBackground
    local FooterLabel
    local DiscordBtn
    local DiscordBtnHeight
    local MainWindowScale

    local InitialLeftWidth = WindowInfo.SidebarWidth or math.ceil(WindowInfo.Size.X.Offset * 0.22)
    local IsCompact = WindowInfo.SidebarCompacted
    local CompactTooltips = WindowInfo.CompactSidebarTooltips ~= false
    local LastExpandedWidth = InitialLeftWidth

    do
        Library.KeybindFrame, Library.KeybindContainer = Library:AddDraggableMenu("Keybinds")
        Library.KeybindFrame.AnchorPoint = Vector2.new(0, 0.5)
        Library.KeybindFrame.Position = UDim2.new(0, 6, 0.5, 0)
        Library.KeybindFrame.Visible = false

        MainFrame = New("TextButton", {
            BackgroundColor3 = function()
                return Library:GetBetterColor(Library.Scheme.BackgroundColor, -1)
            end,
            Name = "Main",
            Text = "",
            Position = WindowInfo.Position,
            Size = WindowInfo.Size,
            Visible = false,
            Parent = ScreenGui,
        })
        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, WindowInfo.CornerRadius),
                Parent = MainFrame,
            })
        )
        table.insert(
            Library.Scales,
            New("UIScale", {
                Parent = MainFrame,
            })
        )
        MainWindowScale = MainFrame:FindFirstChildOfClass("UIScale")
        Library.MainFrame = MainFrame
        Library.MainWindowScale = MainWindowScale
        Library.CenterMainWindow = WindowInfo.Center and true or false

        do
            if ExplicitDPIScale ~= nil then
                Library.AutoDPIScale = false
                Library.BaseScale = 1
                Library:SetDPIScale(ExplicitDPIScale)
            else
                Library.AutoDPIScale = true
                Library.BaseScale = Library:CalculateAutoBaseScale()
                Library:SetDPIScale(5)
                -- Recalculate after Roblox has laid out the frame (deferred)
                task.defer(function()
                    if Library.AutoDPIScale then
                        Library.BaseScale = Library:CalculateAutoBaseScale()
                        Library:SetDPIScale(Library.UIScaleValue or 5)
                    end
                end)
            end
        end

        if not Library.AutoDPIScaleConnection then
            local Camera = workspace.CurrentCamera
            local function OnViewportChanged()
                if not Library.AutoDPIScale then
                    return
                end
                Library.BaseScale = Library:CalculateAutoBaseScale()
                Library:SetDPIScale(Library.UIScaleValue or 5)
            end

            local function BindCamera(Cam: Camera?)
                if Library.AutoDPIScaleConnection then
                    Library.AutoDPIScaleConnection:Disconnect()
                    Library.AutoDPIScaleConnection = nil
                end
                if Cam then
                    local Connection = Cam:GetPropertyChangedSignal("ViewportSize"):Connect(OnViewportChanged)
                    Library.AutoDPIScaleConnection = Connection
                    Library:GiveSignal(Connection)
                end
            end

            BindCamera(Camera)
            Library:GiveSignal(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
                BindCamera(workspace.CurrentCamera)
                OnViewportChanged()
            end))
        end
        Library:AddOutline(MainFrame)
        Library:MakeLine(MainFrame, {
            Position = UDim2.fromOffset(0, 48),
            Size = UDim2.new(1, 0, 0, 1),
        })

        DividerLine = New("Frame", {
            BackgroundColor3 = "OutlineColor",
            Position = UDim2.fromOffset(InitialLeftWidth, 0),
            Size = UDim2.new(0, 1, 1, -20),
            ZIndex = 3,
            Parent = MainFrame,
        })

        if WindowInfo.BackgroundImage then
            BackgroundImage = New("ImageLabel", {
                Image = WindowInfo.BackgroundImage,
                Position = UDim2.fromScale(0, 0),
                Size = UDim2.fromScale(1, 1),
                ScaleType = Enum.ScaleType.Stretch,
                ZIndex = 999,
                BackgroundTransparency = 1,
                ImageTransparency = 0.75,
                Parent = MainFrame,
            })

            table.insert(
                Library.Corners,
                New("UICorner", {
                    CornerRadius = UDim.new(0, WindowInfo.CornerRadius),
                    Parent = BackgroundImage,
                })
            )
        end

        local TopBar = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 48),
            Parent = MainFrame,
        })
        Library:MakeDraggable(MainFrame, TopBar, false, true)

        TitleHolder = New("Frame", {
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundTransparency = 1,
            ClipsDescendants = true,
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0, InitialLeftWidth / 2, 0, 0),
            Size = UDim2.new(0, 0, 1, 0),
            Parent = TopBar,
        })
        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 6),
            Parent = TitleHolder,
        })

        if WindowInfo.Icon then
            local Icon = Library:GetCustomIcon(WindowInfo.Icon)
            if Icon then
                WindowIcon = New("ImageLabel", {
                    Image = Icon.Url,
                    ImageColor3 = "AccentColor",
                    ImageRectOffset = Icon.ImageRectOffset,
                    ImageRectSize = Icon.ImageRectSize,
                    Size = WindowInfo.IconSize,
                    Parent = TitleHolder,
                })
                Library:AddToRegistry(WindowIcon, { ImageColor3 = "AccentColor" })
            else
                WindowIcon = New("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = WindowInfo.IconSize,
                    Text = WindowInfo.Title:sub(1, 1),
                    TextScaled = true,
                    Visible = false,
                    Parent = TitleHolder,
                })
            end
        else
            WindowIcon = New("TextLabel", {
                BackgroundTransparency = 1,
                Size = WindowInfo.IconSize,
                Text = WindowInfo.Title:sub(1, 1),
                TextScaled = true,
                Visible = false,
                Parent = TitleHolder,
            })
        end

        local MaxTitleAreaWidth = math.max(InitialLeftWidth - 24, 20)
        local X = Library:GetTextBounds(
            WindowInfo.Title,
            Library.Scheme.Font,
            WindowInfo.TitleSize or 20,
            MaxTitleAreaWidth - (WindowInfo.Icon and WindowInfo.IconSize.X.Offset + 6 or 0)
        )
        WindowTitle = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(0, X, 1, 0),
            Text = WindowInfo.Title,
            TextSize = WindowInfo.TitleSize or 20,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = TitleHolder,
        })

        RightWrapper = New("Frame", {
            AnchorPoint = Vector2.new(1, 0.5),
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -82, 0.5, 0),
            Size = UDim2.new(1, -InitialLeftWidth - 90 - 1, 1, -22),
            Parent = TopBar,
        })

        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 8),
            Parent = RightWrapper,
        })

        CurrentTabInfo = New("Frame", {
            AutomaticSize = Enum.AutomaticSize.Y,
            Size = UDim2.fromScale(WindowInfo.DisableSearch and 1 or 0.5, 0),
            Visible = false,
            BackgroundTransparency = 1,
            Parent = RightWrapper,
        })

        New("UIFlexItem", {
            FlexMode = Enum.UIFlexMode.Grow,
            Parent = CurrentTabInfo,
        })

        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            HorizontalAlignment = Enum.HorizontalAlignment.Left,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Parent = CurrentTabInfo,
        })

        New("UIPadding", {
            PaddingBottom = UDim.new(0, 8),
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
            PaddingTop = UDim.new(0, 8),
            Parent = CurrentTabInfo,
        })

        CurrentTabLabel = New("TextLabel", {
            BackgroundTransparency = 1,
            AutomaticSize = Enum.AutomaticSize.Y,
            Size = UDim2.new(1, 0, 0, 16),
            Text = "",
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = CurrentTabInfo,
        })

        CurrentTabDescription = New("TextLabel", {
            BackgroundTransparency = 1,
            AutomaticSize = Enum.AutomaticSize.Y,
            Size = UDim2.new(1, 0, 0, 0),
            Text = "",
            TextWrapped = true,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTransparency = 0.5,
            Parent = CurrentTabInfo,
        })

        SearchBox = New("TextBox", {
            BackgroundColor3 = "MainColor",
            PlaceholderText = "Search",
            Size = UDim2.fromScale(0.5, 1),
            TextSize = 13,
            TextScaled = false,
            Visible = not (WindowInfo.DisableSearch or false),
            Parent = RightWrapper,
        })
        New("UIFlexItem", {
            FlexMode = Enum.UIFlexMode.Shrink,
            Parent = SearchBox,
        })
        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, WindowInfo.CornerRadius),
                Parent = SearchBox,
            })
        )
        New("UIPadding", {
            PaddingBottom = UDim.new(0, 4),
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
            PaddingTop = UDim.new(0, 4),
            Parent = SearchBox,
        })
        New("UIStroke", {
            Color = "OutlineColor",
            Parent = SearchBox,
        })

        local SearchIcon = Library:GetIcon("search")
        if SearchIcon then
            New("ImageLabel", {
                Image = SearchIcon.Url,
                ImageColor3 = "FontColor",
                ImageRectOffset = SearchIcon.ImageRectOffset,
                ImageRectSize = SearchIcon.ImageRectSize,
                ImageTransparency = 0.5,
                Size = UDim2.fromScale(1, 1),
                SizeConstraint = Enum.SizeConstraint.RelativeYY,
                Parent = SearchBox,
            })
        end

        do
            local ControlsHolder = New("Frame", {
                AnchorPoint = Vector2.new(1, 0.5),
                BackgroundTransparency = 1,
                Position = UDim2.new(1, -10, 0.5, 0),
                Size = UDim2.fromOffset(60, 26),
                Parent = TopBar,
            })
            New("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Right,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Padding = UDim.new(0, 6),
                Parent = ControlsHolder,
            })

            local MinimizeIcon = Library:GetIcon("minus")
            local CloseIcon = Library:GetIcon("x")

            local MinBtn = New("TextButton", {
                BackgroundColor3 = "MainColor",
                Size = UDim2.fromOffset(26, 26),
                Text = "",
                Parent = ControlsHolder,
            })
            table.insert(Library.Corners, New("UICorner", { CornerRadius = UDim.new(0, 6), Parent = MinBtn }))
            Library:AddOutline(MinBtn)
            if MinimizeIcon then
                New("ImageLabel", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundTransparency = 1,
                    Image = MinimizeIcon.Url,
                    ImageColor3 = "FontColor",
                    ImageRectOffset = MinimizeIcon.ImageRectOffset,
                    ImageRectSize = MinimizeIcon.ImageRectSize,
                    ImageTransparency = 0.35,
                    Position = UDim2.fromScale(0.5, 0.5),
                    Size = UDim2.fromOffset(14, 14),
                    Parent = MinBtn,
                })
            end
            MinBtn.MouseEnter:Connect(function()
                TweenService:Create(MinBtn, Library.TweenInfo, { BackgroundColor3 = Library:GetBetterColor(Library.Scheme.MainColor, 12) }):Play()
            end)
            MinBtn.MouseLeave:Connect(function()
                TweenService:Create(MinBtn, Library.TweenInfo, { BackgroundColor3 = Library.Scheme.MainColor }):Play()
            end)
            MinBtn.MouseButton1Click:Connect(function()
                Library:Toggle(false)
            end)

            local CloseBtn = New("TextButton", {
                BackgroundColor3 = "MainColor",
                Size = UDim2.fromOffset(26, 26),
                Text = "",
                Parent = ControlsHolder,
            })
            table.insert(Library.Corners, New("UICorner", { CornerRadius = UDim.new(0, 6), Parent = CloseBtn }))
            Library:AddOutline(CloseBtn)
            if CloseIcon then
                New("ImageLabel", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundTransparency = 1,
                    Image = CloseIcon.Url,
                    ImageColor3 = "FontColor",
                    ImageRectOffset = CloseIcon.ImageRectOffset,
                    ImageRectSize = CloseIcon.ImageRectSize,
                    ImageTransparency = 0.35,
                    Position = UDim2.fromScale(0.5, 0.5),
                    Size = UDim2.fromOffset(14, 14),
                    Parent = CloseBtn,
                })
            end
            CloseBtn.MouseEnter:Connect(function()
                TweenService:Create(CloseBtn, Library.TweenInfo, { BackgroundColor3 = Color3.fromRGB(200, 50, 50) }):Play()
            end)
            CloseBtn.MouseLeave:Connect(function()
                TweenService:Create(CloseBtn, Library.TweenInfo, { BackgroundColor3 = Library.Scheme.MainColor }):Play()
            end)
            CloseBtn.MouseButton1Click:Connect(function()
                Library:Toggle(false)
                Library:Unload()
            end)
        end

        BottomBackground = New("Frame", {
            AnchorPoint = Vector2.new(0, 1),
            BackgroundColor3 = function()
                return Library:GetBetterColor(Library.Scheme.BackgroundColor, 4)
            end,
            Position = UDim2.fromScale(0, 1),
            Size = UDim2.new(1, 0, 0, 20 + WindowInfo.CornerRadius),
            Parent = MainFrame
        })
        Library:MakeLine(MainFrame, {
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.new(0, 0, 1, -20),
            Size = UDim2.new(1, 0, 0, 1),
        })

        local BottomBar = New("Frame", {
            AnchorPoint = Vector2.new(0, 1),
            BackgroundTransparency = 1,
            Position = UDim2.fromScale(0, 1),
            Size = UDim2.new(1, 0, 0, 20),
            Parent = MainFrame,
        })
        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, WindowInfo.CornerRadius),
                Parent = BottomBackground,
            })
        )

        FooterLabel = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Text = WindowInfo.Footer,
            TextSize = 14,
            TextTransparency = 0.5,
            Parent = BottomBar,
        })

        if WindowInfo.Resizable then
            ResizeButton = New("TextButton", {
                AnchorPoint = Vector2.new(1, 0),
                BackgroundTransparency = 1,
                Position = UDim2.new(1, -WindowInfo.CornerRadius / 4, 0, 0),
                Size = UDim2.fromScale(1, 1),
                SizeConstraint = Enum.SizeConstraint.RelativeYY,
                Text = "",
                Parent = BottomBar,
            })

            Library:MakeResizable(MainFrame, ResizeButton, function()
                for _, Tab in Library.Tabs do
                    Tab:Resize(true)
                end
            end)
        end

        local ResizeImage = New("ImageLabel", {
            Image = ResizeIcon and ResizeIcon.Url or "",
            ImageColor3 = "FontColor",
            ImageRectOffset = ResizeIcon and ResizeIcon.ImageRectOffset or Vector2.zero,
            ImageRectSize = ResizeIcon and ResizeIcon.ImageRectSize or Vector2.zero,
            ImageTransparency = 0.5,
            Position = UDim2.fromOffset(2, 2),
            Size = UDim2.new(1, -4, 1, -4),
            Parent = ResizeButton,
        })
        Library:RegisterIconInstance(ResizeImage, "move-diagonal-2")

        Sidebar = New("Frame", {
            BackgroundColor3 = "BackgroundColor",
            Position = UDim2.fromOffset(0, 49),
            Size = UDim2.new(0, InitialLeftWidth, 1, -70),
            Parent = MainFrame,
        })
        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = Sidebar,
        })

        DiscordBtnHeight = (WindowInfo.DiscordLink and typeof(WindowInfo.DiscordLink) == "string") and 36 or 0
        Tabs = New("ScrollingFrame", {
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = "BackgroundColor",
            CanvasSize = UDim2.fromScale(0, 0),
            LayoutOrder = 1,
            ScrollBarThickness = 0,
            Size = UDim2.new(1, 0, 1, -DiscordBtnHeight),
            Parent = Sidebar,
        })
        local TabsLayout = New("UIListLayout", {
            Padding = UDim.new(0, 2),
            Parent = Tabs,
        })
        New("UIPadding", {
            PaddingTop = UDim.new(0, 6),
            PaddingBottom = UDim.new(0, 6),
            PaddingLeft = UDim.new(0, 4),
            PaddingRight = UDim.new(0, 4),
            Parent = Tabs,
        })

        if DiscordBtnHeight > 0 then
            local HttpService = cloneref(game:GetService("HttpService"))
            local DiscordUrl = WindowInfo.DiscordLink
            local DiscordAction = WindowInfo.DiscordAction or "open"
            local DiscordInvite = DiscordUrl:match("discord%.gg/([^/%?]+)")
            local DiscordM = (syn and syn.request) or (http and http.request) or (rawget(_G, "http_request")) or (rawget(_G, "request"))

            local function DoDiscordAction()
                local Opened = false
                if DiscordAction == "open" and DiscordM and DiscordInvite then
                    pcall(function()
                        DiscordM({
                            Url = "http://127.0.0.1:6463/rpc?v=1",
                            Method = "POST",
                            Headers = {
                                ["Content-Type"] = "application/json",
                                ["Origin"] = "https://discord.com",
                            },
                            Body = HttpService:JSONEncode({
                                cmd = "INVITE_BROWSER",
                                nonce = HttpService:GenerateGUID(false),
                                args = { code = DiscordInvite },
                            }),
                        })
                        Opened = true
                    end)
                end
                if not Opened and setclipboard then
                    setclipboard(tostring(DiscordUrl))
                    Library:Notify({ Title = "Discord", Description = "Invite link copied to clipboard.", Icon = "copy", Time = 3 })
                end
            end

            New("Frame", {
                BackgroundColor3 = "OutlineColor",
                BorderSizePixel = 0,
                LayoutOrder = 2,
                Size = UDim2.new(1, 0, 0, 1),
                Parent = Sidebar,
            })

            DiscordBtn = New("TextButton", {
                BackgroundColor3 = "MainColor",
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                LayoutOrder = 3,
                Size = UDim2.new(1, 0, 0, DiscordBtnHeight - 1),
                Text = "",
                Parent = Sidebar,
            })

            New("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Padding = UDim.new(0, 8),
                Parent = DiscordBtn,
            })

            local DiscordImgLabel = New("ImageLabel", {
                BackgroundTransparency = 1,
                Image = CustomImageManager.GetAsset("DiscordIcon") or "",
                ImageColor3 = "AccentColor",
                ImageTransparency = 0.5,
                ScaleType = Enum.ScaleType.Fit,
                Size = UDim2.fromOffset(18, 18),
                Visible = not IsCompact,
                Parent = DiscordBtn,
            })

            local DiscordTextLabel = New("TextLabel", {
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundTransparency = 1,
                Size = UDim2.new(0, 0, 1, 0),
                Text = "Discord",
                TextSize = 16,
                TextTransparency = 0.5,
                TextTruncate = Enum.TextTruncate.AtEnd,
                TextXAlignment = Enum.TextXAlignment.Center,
                Visible = not IsCompact,
                Parent = DiscordBtn,
            })

            local DiscordCompactIcon = New("ImageLabel", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                Image = CustomImageManager.GetAsset("DiscordIcon") or "",
                ImageColor3 = "AccentColor",
                ImageTransparency = 0.5,
                ScaleType = Enum.ScaleType.Fit,
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(20, 20),
                Visible = IsCompact,
                Parent = DiscordBtn,
            })

            task.defer(function()
                DiscordTextLabel.Visible = not IsCompact
                DiscordImgLabel.Visible = not IsCompact
                DiscordCompactIcon.Visible = IsCompact

                local Resolved = CustomImageManager.GetAsset("DiscordIcon")
                if Resolved and DiscordImgLabel and DiscordImgLabel.Parent then
                    DiscordImgLabel.Image = Resolved
                end
                if Resolved and DiscordCompactIcon and DiscordCompactIcon.Parent then
                    DiscordCompactIcon.Image = Resolved
                end
            end)

            DiscordBtn.MouseButton1Click:Connect(DoDiscordAction)

            DiscordBtn.MouseEnter:Connect(function()
                TweenService:Create(DiscordBtn, Library.TweenInfo, {
                    BackgroundTransparency = 0.85,
                }):Play()
                TweenService:Create(DiscordImgLabel, Library.TweenInfo, {
                    ImageTransparency = 0,
                }):Play()
                TweenService:Create(DiscordTextLabel, Library.TweenInfo, {
                    TextTransparency = 0,
                }):Play()
                TweenService:Create(DiscordCompactIcon, Library.TweenInfo, {
                    ImageTransparency = 0,
                }):Play()
            end)
            DiscordBtn.MouseLeave:Connect(function()
                TweenService:Create(DiscordBtn, Library.TweenInfo, {
                    BackgroundTransparency = 1,
                }):Play()
                TweenService:Create(DiscordImgLabel, Library.TweenInfo, {
                    ImageTransparency = 0.5,
                }):Play()
                TweenService:Create(DiscordTextLabel, Library.TweenInfo, {
                    TextTransparency = 0.5,
                }):Play()
                TweenService:Create(DiscordCompactIcon, Library.TweenInfo, {
                    ImageTransparency = 0.5,
                }):Play()
            end)
            DiscordBtn.MouseButton1Down:Connect(function()
                TweenService:Create(DiscordBtn, Library.TweenInfo, {
                    BackgroundTransparency = 0.7,
                }):Play()
            end)
            DiscordBtn.MouseButton1Up:Connect(function()
                TweenService:Create(DiscordBtn, Library.TweenInfo, {
                    BackgroundTransparency = 0.85,
                }):Play()
            end)
        end

        Container = New("Frame", {
            AnchorPoint = Vector2.new(1, 0),
            BackgroundColor3 = function()
                return Library:GetBetterColor(Library.Scheme.BackgroundColor, 1)
            end,
            Name = "Container",
            Position = UDim2.new(1, 0, 0, 49),
            Size = UDim2.new(1, -InitialLeftWidth - 1, 1, -70),
            Parent = MainFrame,
        })
        New("UIPadding", {
            PaddingBottom = UDim.new(0, 0),
            PaddingLeft = UDim.new(0, 6),
            PaddingRight = UDim.new(0, 6),
            PaddingTop = UDim.new(0, 0),
            Parent = Container,
        })
    end

    local Window = {}

    function Window:ChangeTitle(title)
        assert(typeof(title) == "string", "Expected string for title got: " .. typeof(title))

        WindowTitle.Text = title
        WindowInfo.Title = title

        local MaxTitleAreaWidth = math.max(InitialLeftWidth - 24, 20)
        local X = Library:GetTextBounds(
            title,
            Library.Scheme.Font,
            WindowInfo.TitleSize or 20,
            MaxTitleAreaWidth - (WindowInfo.Icon and WindowInfo.IconSize.X.Offset + 6 or 0)
        )
        WindowTitle.Size = UDim2.new(0, X, 1, 0)
    end

    function Window:SetTitleSize(size)
        assert(typeof(size) == "number", "Expected number for size got: " .. typeof(size))

        WindowInfo.TitleSize = size
        WindowTitle.TextSize = size

        local MaxTitleAreaWidth = math.max(InitialLeftWidth - 24, 20)
        local X = Library:GetTextBounds(
            WindowInfo.Title,
            Library.Scheme.Font,
            size,
            MaxTitleAreaWidth - (WindowInfo.Icon and WindowInfo.IconSize.X.Offset + 6 or 0)
        )
        WindowTitle.Size = UDim2.new(0, X, 1, 0)
    end

    if WindowInfo.BackgroundImage then
        function Window:SetBackgroundImage(Image: string)
            assert(typeof(Image) == "string", "Expected string for Image got: " .. typeof(Image))

            BackgroundImage.Image = Image
            WindowInfo.BackgroundImage = Image
        end
    end

    function Window:SetFooter(footer: string)
        assert(typeof(footer) == "string", "Expected string for footer got: " .. typeof(footer))

        FooterLabel.Text = footer
        WindowInfo.Footer = footer
    end

    function Window:SetCornerRadius(Radius: number)
        assert(typeof(Radius) == "number", "Expected number for Radius got: " .. typeof(Radius))
        Radius = math.min(Radius, 20)

        for _, UICorner in Library.Corners do
            if UICorner.CornerRadius.Offset == Library.CornerRadius / 2 then
                UICorner.CornerRadius = UDim.new(0, Radius / 2)
            else
                UICorner.CornerRadius = UDim.new(0, Radius)
            end
        end

        Library.CornerRadius = Radius
        WindowInfo.CornerRadius = Radius

        ResizeButton.Position = UDim2.new(1, -Radius / 4, 0, 0)
        BottomBackground.Size = UDim2.new(1, 0, 0, 20 + Radius)

        for _, Tab in Library.Tabs do
            if Tab.IsKeyTab then
                continue
            end

            for _, SectionGroup in Tab.SectionGroups do
                SectionGroup:UpdateCorners()
            end
        end
    end

    local CompactWidth = 48

    local function ApplyCompact()
        IsCompact = Window:GetSidebarWidth() <= CompactWidth

        WindowTitle.Visible = not IsCompact
        if not WindowInfo.Icon then
            WindowIcon.Visible = IsCompact
        end

        for _, Button in Library.TabButtons do
            Button.Label.Visible = not IsCompact

            if IsCompact then

                Button.IconSlot.AnchorPoint = Vector2.new(0.5, 0.5)
                Button.IconSlot.Position = UDim2.fromScale(0.5, 0.5)
                Button.IconSlot.Size = UDim2.new(0, 20, 1, 0)
                Button.IconSlot.SizeConstraint = Enum.SizeConstraint.RelativeYY
                Button.Padding.PaddingLeft = UDim.new(0, 4)
            else

                Button.IconSlot.AnchorPoint = Vector2.new(0, 0.5)
                Button.IconSlot.Position = UDim2.new(0, 0, 0.5, 0)
                Button.IconSlot.Size = UDim2.new(0, 20, 1, 0)
                Button.IconSlot.SizeConstraint = Enum.SizeConstraint.RelativeYY
                Button.Padding.PaddingLeft = UDim.new(0, 20)
            end

            if Button.Icon then
                Button.FirstLetter.Visible = false
            else
                Button.FirstLetter.Visible = IsCompact
            end

            if Button.Tooltip then
                Button.Tooltip.Disabled = not IsCompact
            end
        end

        if DiscordBtn then
            local DiscordImgLabelObj = DiscordBtn:FindFirstChildWhichIsA("ImageLabel")
            local AllImgLabels = {}
            for _, Child in DiscordBtn:GetChildren() do
                if Child:IsA("ImageLabel") then
                    table.insert(AllImgLabels, Child)
                end
            end
            local AllTextLabels = {}
            for _, Child in DiscordBtn:GetChildren() do
                if Child:IsA("TextLabel") then
                    table.insert(AllTextLabels, Child)
                end
            end

            if AllTextLabels[1] then AllTextLabels[1].Visible = not IsCompact end
            if AllImgLabels[1] then AllImgLabels[1].Visible = not IsCompact end
            if AllImgLabels[2] then AllImgLabels[2].Visible = IsCompact end
        end

        for _, Header in Library.TabSectionHeaders do
            Header.Label.Visible = not IsCompact
            if IsCompact then
                Header.Arrow.AnchorPoint = Vector2.new(0.5, 0.5)
                Header.Arrow.Position = UDim2.new(0.5, 0, 0.5, 0)
            else
                Header.Arrow.AnchorPoint = Vector2.new(1, 0.5)
                Header.Arrow.Position = UDim2.new(1, -2, 0.5, 0)
            end

            if Header.IndentPaddings then
                for _, Pad in Header.IndentPaddings do
                    Pad.PaddingLeft = UDim.new(0, IsCompact and 0 or 6)
                end
            end

            if Header.Separator then
                Header.Separator.Visible = IsCompact and Header.GetHasFollower() and Header.GetIsOpen()
            end

            if Header.Tooltip then
                Header.Tooltip.Disabled = not IsCompact
            end
        end
    end

    function Window:IsSidebarCompacted()
        return IsCompact
    end

    function Window:SetCompact(State)
        Window:SetSidebarWidth(State and CompactWidth or LastExpandedWidth)
    end

    function Window:GetSidebarWidth()
        return Sidebar.Size.X.Offset
    end

    local SidebarGrabberRef = nil

    function Window:SetSidebarWidth(Width)
        Width = math.clamp(Width, CompactWidth, MainFrame.Size.X.Offset - 256 - 1)

        DividerLine.Position = UDim2.fromOffset(Width, 0)

        if SidebarGrabberRef and SidebarGrabberRef.Parent then
            SidebarGrabberRef.Position = UDim2.fromOffset(Width, 0)
        end

        TitleHolder.Position = UDim2.new(0, Width / 2, 0, 0)
        RightWrapper.Size = UDim2.new(1, -Width - 90 - 1, 1, -16)
        Sidebar.Size = UDim2.new(0, Width, 1, -70)
        Container.Size = UDim2.new(1, -Width - 1, 1, -70)

        local MaxTitleAreaWidth = math.max(Width - 24, 20)
        local TitleX = Library:GetTextBounds(
            WindowTitle.Text,
            WindowTitle.FontFace,
            WindowTitle.TextSize,
            MaxTitleAreaWidth - (WindowIcon and WindowIcon.Visible and (WindowIcon.Size.X.Offset + 6) or 0)
        )
        WindowTitle.Size = UDim2.new(0, TitleX, 1, 0)

        ApplyCompact()
        if not IsCompact then
            LastExpandedWidth = Width
        end
    end

    function Window:ShowTabInfo(Name, Description)
        CurrentTabLabel.Text = Name
        CurrentTabDescription.Text = Description

        CurrentTabInfo.Visible = true
    end
    function Window:HideTabInfo()
        CurrentTabInfo.Visible = false
    end

    local LastSectionSeparator = nil

    function Window:AddTabSection(Info)
        local SectionName = typeof(Info) == "table" and (Info.Name or "Section") or tostring(Info)
        local DefaultOpen = typeof(Info) == "table" and (Info.Open ~= false) or true
        local SectionIcon = typeof(Info) == "table" and Library:GetCustomIcon(Info.Icon) or nil

        local IsOpen = DefaultOpen

        if LastSectionSeparator then
            LastSectionSeparator.Show()
        end

        local GroupHolder = New("Frame", {
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            Parent = Tabs,
        })
        New("UIListLayout", {
            Padding = UDim.new(0, 1),
            Parent = GroupHolder,
        })

        local HeaderBtn = New("TextButton", {
            BackgroundColor3 = "MainColor",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 28),
            Text = "",
            Parent = GroupHolder,
        })
        table.insert(Library.Corners, New("UICorner", { CornerRadius = UDim.new(0, 6), Parent = HeaderBtn }))

        local HeaderContent = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Parent = HeaderBtn,
        })
        New("UIPadding", {
            PaddingLeft = UDim.new(0, 10),
            PaddingRight = UDim.new(0, 8),
            Parent = HeaderContent,
        })

        if SectionIcon then
            New("ImageLabel", {
                BackgroundTransparency = 1,
                Image = SectionIcon.Url,
                ImageColor3 = SectionIcon.Custom and "WhiteColor" or "AccentColor",
                ImageRectOffset = SectionIcon.ImageRectOffset,
                ImageRectSize = SectionIcon.ImageRectSize,
                ImageTransparency = 0.3,
                Position = UDim2.fromOffset(0, 0),
                AnchorPoint = Vector2.new(0, 0.5),
                Size = UDim2.fromOffset(14, 14),
                Position = UDim2.new(0, 10, 0.5, 0),
                Parent = HeaderContent,
            })
        end

        local HeaderLabel = New("TextLabel", {
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundTransparency = 1,
            Position = UDim2.new(0, SectionIcon and 24 or 0, 0.5, 0),
            Size = UDim2.new(1, -(SectionIcon and 40 or 16), 0, 14),
            Text = SectionName:upper(),
            TextSize = 10,
            TextTransparency = 0.4,
            TextTruncate = Enum.TextTruncate.AtEnd,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = HeaderContent,
        })

        local ChevronDownIcon = Library:GetIcon("chevron-down")
        local ChevronRightIcon = Library:GetIcon("chevron-right")
        local ArrowImg = New("ImageLabel", {
            AnchorPoint = Vector2.new(1, 0.5),
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -2, 0.5, 0),
            Size = UDim2.fromOffset(12, 12),
            ImageColor3 = "FontColor",
            ImageTransparency = 0.5,
            ScaleType = Enum.ScaleType.Fit,
            Image = IsOpen
                and (ChevronDownIcon and ChevronDownIcon.Url or "")
                or (ChevronRightIcon and ChevronRightIcon.Url or ""),
            ImageRectOffset = IsOpen
                and (ChevronDownIcon and ChevronDownIcon.ImageRectOffset or Vector2.zero)
                or (ChevronRightIcon and ChevronRightIcon.ImageRectOffset or Vector2.zero),
            ImageRectSize = IsOpen
                and (ChevronDownIcon and ChevronDownIcon.ImageRectSize or Vector2.zero)
                or (ChevronRightIcon and ChevronRightIcon.ImageRectSize or Vector2.zero),
            Parent = HeaderContent,
        })
        Library:AddToRegistry(ArrowImg, { ImageColor3 = "FontColor" })

        local function ApplySectionCompact(compact)
            HeaderLabel.Visible = not compact
            if compact then
                ArrowImg.AnchorPoint = Vector2.new(0.5, 0.5)
                ArrowImg.Position = UDim2.new(0.5, 0, 0.5, 0)
            else
                ArrowImg.AnchorPoint = Vector2.new(1, 0.5)
                ArrowImg.Position = UDim2.new(1, -2, 0.5, 0)
            end
        end

        ApplySectionCompact(IsCompact)

        local ChildrenHolder = New("Frame", {
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            Visible = IsOpen,
            Parent = GroupHolder,
        })
        New("UIListLayout", {
            Padding = UDim.new(0, 1),
            Parent = ChildrenHolder,
        })

        local function UpdateArrow()
            local Icon = IsOpen and ChevronDownIcon or ChevronRightIcon
            if Icon then
                ArrowImg.Image = Icon.Url
                ArrowImg.ImageRectOffset = Icon.ImageRectOffset
                ArrowImg.ImageRectSize = Icon.ImageRectSize
            end
        end

        local SectionSeparator = New("Frame", {
            BackgroundColor3 = "OutlineColor",
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 1),
            Visible = false,
            Parent = GroupHolder,
        })
        Library:AddToRegistry(SectionSeparator, { BackgroundColor3 = "OutlineColor" })

        local HasFollower = false

        LastSectionSeparator = {
            Show = function()
                HasFollower = true
                SectionSeparator.Visible = IsCompact and IsOpen
            end,
        }

        HeaderBtn.MouseButton1Click:Connect(function()
            IsOpen = not IsOpen
            ChildrenHolder.Visible = IsOpen
            UpdateArrow()
            if HasFollower then
                SectionSeparator.Visible = IsCompact and IsOpen
            end
        end)

        local IndentPaddings = {}
        local SectionTabButtonRefs = {}

        local SectionTooltip = CompactTooltips and Library:AddTooltip(SectionName, nil, HeaderBtn) or nil
        if SectionTooltip then
            SectionTooltip.Disabled = not IsCompact
        end

        table.insert(Library.TabSectionHeaders, {
            Label = HeaderLabel,
            Arrow = ArrowImg,
            IndentPaddings = IndentPaddings,
            SectionTabButtonRefs = SectionTabButtonRefs,
            Separator = SectionSeparator,
            Tooltip = SectionTooltip,
            GetHasFollower = function() return HasFollower end,
            GetIsOpen = function() return IsOpen end,
        })

        local SectionGroup = {}

        function SectionGroup:AddTab(...)
            local IndentFrame = New("Frame", {
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 0),
                Parent = ChildrenHolder,
            })
            local IndentPad = New("UIPadding", {
                PaddingLeft = UDim.new(0, IsCompact and 0 or 6),
                Parent = IndentFrame,
            })
            table.insert(IndentPaddings, IndentPad)
            New("UIListLayout", {
                Padding = UDim.new(0, 1),
                Parent = IndentFrame,
            })

            local PrevCount = #Library.TabButtons
            local Tab = Window:AddTab(..., IndentFrame)
            for i = PrevCount + 1, #Library.TabButtons do
                Library.TabButtons[i].InSection = true
                table.insert(SectionTabButtonRefs, Library.TabButtons[i])
            end

            return Tab
        end

        return SectionGroup
    end

    function Window:AddTab(InfoOrName, IconOrTabParent, Description, TabParent)
        local Name = nil
        local Icon = nil

        if select("#", InfoOrName) == 0 then

            Name = "Tab"
        elseif typeof(InfoOrName) == "table" then
            local Info = InfoOrName
            Name = Info.Name or "Tab"
            Icon = Info.Icon
            Description = Info.Description

            if typeof(IconOrTabParent) == "Instance" then
                TabParent = IconOrTabParent
            end
        else
            Name = InfoOrName
            if typeof(IconOrTabParent) == "Instance" then
                TabParent = IconOrTabParent
            else
                Icon = IconOrTabParent
            end
        end

        local TabButton: TextButton
        local TabLabel
        local TabIcon

        local TabContainer
        local TabScroll
        local ColumnsRow
        local ColumnLeft
        local ColumnRight
        local ColumnFull
        local GetSectionParent
        local NextOrder = 0

        Icon = Library:GetCustomIcon(Icon)
        do
            TabButton = New("TextButton", {
                BackgroundColor3 = "MainColor",
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 36),
                Text = "",
                Parent = TabParent or Tabs,
            })
            local ButtonPadding = New("UIPadding", {
                PaddingBottom = UDim.new(0, 4),
                PaddingLeft = UDim.new(0, IsCompact and 4 or 20),
                PaddingRight = UDim.new(0, 4),
                PaddingTop = UDim.new(0, 4),
                Parent = TabButton,
            })

            local IconSlot = New("Frame", {
                AnchorPoint = IsCompact and Vector2.new(0.5, 0.5) or Vector2.new(0, 0.5),
                BackgroundTransparency = 1,
                Position = IsCompact and UDim2.fromScale(0.5, 0.5) or UDim2.new(0, 0, 0.5, 0),
                Size = UDim2.new(0, 20, 1, 0),
                SizeConstraint = Enum.SizeConstraint.RelativeYY,
                Parent = TabButton,
            })

            if Icon then
                TabIcon = New("ImageLabel", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Image = Icon.Url,
                    ImageColor3 = Icon.Custom and "WhiteColor" or "AccentColor",
                    ImageRectOffset = Icon.ImageRectOffset,
                    ImageRectSize = Icon.ImageRectSize,
                    ImageTransparency = 0.5,
                    Position = UDim2.fromScale(0.5, 0.5),
                    ScaleType = Enum.ScaleType.Fit,
                    Size = UDim2.fromScale(1, 1),
                    SizeConstraint = Enum.SizeConstraint.RelativeYY,
                    Parent = IconSlot,
                })
            end

            local FirstLetterLabel = New("TextLabel", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromScale(1, 1),
                Text = Name:sub(1, 1):upper(),
                TextSize = 14,
                TextTransparency = 0.5,
                Visible = not Icon and IsCompact,
                Parent = IconSlot,
            })

            TabLabel = New("TextLabel", {
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 28, 0.5, 0),
                Size = UDim2.new(1, -28, 0, 18),
                Text = Name,
                TextSize = 14,
                TextTransparency = 0.5,
                TextTruncate = Enum.TextTruncate.AtEnd,
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Left,
                Visible = not IsCompact,
                Parent = TabButton,
            })

            local TabTooltip = CompactTooltips and Library:AddTooltip(Name, nil, TabButton) or nil
            if TabTooltip then TabTooltip.Disabled = not IsCompact end

            table.insert(Library.TabButtons, {
                Label = TabLabel,
                Padding = ButtonPadding,
                Icon = TabIcon,
                IconSlot = IconSlot,
                FirstLetter = FirstLetterLabel,
                Tooltip = TabTooltip,
            })

            TabContainer = New("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                Visible = false,
                Parent = Container,
            })

            TabScroll = New("ScrollingFrame", {
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                CanvasSize = UDim2.fromScale(0, 0),
                ScrollBarImageTransparency = 1,
                ScrollBarThickness = 0,
                Size = UDim2.fromScale(1, 1),
                Parent = TabContainer,
            })
            local TabScrollList = New("UIListLayout", {
                Padding = UDim.new(0, 2),
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = TabScroll,
            })
            New("UIPadding", {
                PaddingBottom = UDim.new(0, 8),
                PaddingLeft = UDim.new(0, 2),
                PaddingRight = UDim.new(0, 2),
                PaddingTop = UDim.new(0, 2),
                Parent = TabScroll,
            })
            do
                New("Frame", {
                    BackgroundTransparency = 1,
                    LayoutOrder = -1,
                    Parent = TabScroll,
                })
                New("Frame", {
                    BackgroundTransparency = 1,
                    LayoutOrder = 2147483646,
                    Parent = TabScroll,
                })
            end

            ColumnFull = TabScroll

            local CurrentLayoutMode = nil
            local CurrentColumnsRow = nil
            local CurrentColumnLeft = nil
            local CurrentColumnRight = nil

            GetSectionParent = function(Side)
                local RequestedMode = (Side == 1 or Side == 2) and "two-column" or nil

                local NeedNewRow = CurrentLayoutMode ~= RequestedMode

                if NeedNewRow then
                    CurrentLayoutMode = RequestedMode

                    if RequestedMode == "two-column" then

                        CurrentColumnsRow = New("Frame", {
                            AutomaticSize = Enum.AutomaticSize.Y,
                            BackgroundTransparency = 1,
                            LayoutOrder = NextOrder,
                            Size = UDim2.new(1, 0, 0, 0),
                            Parent = TabScroll,
                        })

                        CurrentColumnLeft = New("Frame", {
                            AutomaticSize = Enum.AutomaticSize.Y,
                            BackgroundTransparency = 1,
                            Size = UDim2.new(0.5, -3, 0, 0),
                            Parent = CurrentColumnsRow,
                        })
                        New("UIListLayout", {
                            Padding = UDim.new(0, 2),
                            SortOrder = Enum.SortOrder.LayoutOrder,
                            Parent = CurrentColumnLeft,
                        })

                        CurrentColumnRight = New("Frame", {
                            AnchorPoint = Vector2.new(1, 0),
                            AutomaticSize = Enum.AutomaticSize.Y,
                            BackgroundTransparency = 1,
                            Position = UDim2.fromScale(1, 0),
                            Size = UDim2.new(0.5, -3, 0, 0),
                            Parent = CurrentColumnsRow,
                        })
                        New("UIListLayout", {
                            Padding = UDim.new(0, 2),
                            SortOrder = Enum.SortOrder.LayoutOrder,
                            Parent = CurrentColumnRight,
                        })

                        NextOrder = NextOrder + 1
                    else

                        NextOrder = NextOrder + 1
                    end
                end

                if RequestedMode == "two-column" then
                    return Side == 1 and CurrentColumnLeft or CurrentColumnRight
                else
                    local Order = NextOrder - 1
                    return ColumnFull, Order
                end
            end
        end

        local WarningBoxHolder = New("Frame", {
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(0, 7),
            Size = UDim2.fromScale(1, 0),
            Visible = false,
            Parent = TabContainer,
        })

        local WarningBox
        local WarningBoxOutline
        local WarningBoxShadowOutline
        local WarningBoxScrollingFrame
        local WarningTitle
        local WarningStroke
        local WarningText
        do
            WarningBox = New("Frame", {
                BackgroundColor3 = "BackgroundColor",
                Position = UDim2.fromOffset(2, 0),
                Size = UDim2.new(1, -5, 0, 0),
                Parent = WarningBoxHolder,
            })
            table.insert(
                Library.Corners,
                New("UICorner", {
                    CornerRadius = UDim.new(0, WindowInfo.CornerRadius),
                    Parent = WarningBox,
                })
            )
            WarningBoxOutline, WarningBoxShadowOutline = Library:AddOutline(WarningBox)

            WarningBoxScrollingFrame = New("ScrollingFrame", {
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Size = UDim2.fromScale(1, 1),
                CanvasSize = UDim2.new(0, 0, 0, 0),
                ScrollBarThickness = 3,
                ScrollingDirection = Enum.ScrollingDirection.Y,
                Parent = WarningBox,
            })
            New("UIPadding", {
                PaddingBottom = UDim.new(0, 4),
                PaddingLeft = UDim.new(0, 6),
                PaddingRight = UDim.new(0, 6),
                PaddingTop = UDim.new(0, 4),
                Parent = WarningBoxScrollingFrame,
            })

            WarningTitle = New("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -4, 0, 14),
                Text = "",
                TextColor3 = Color3.fromRGB(255, 50, 50),
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = WarningBoxScrollingFrame,
            })

            WarningStroke = New("UIStroke", {
                ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
                Color = Color3.fromRGB(169, 0, 0),
                LineJoinMode = Enum.LineJoinMode.Miter,
                Parent = WarningTitle,
            })

            WarningText = New("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(0, 16),
                Size = UDim2.new(1, -4, 0, 0),
                Text = "",
                TextSize = 14,
                TextWrapped = true,
                Parent = WarningBoxScrollingFrame,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,
            })

            New("UIStroke", {
                ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
                Color = "DarkColor",
                LineJoinMode = Enum.LineJoinMode.Miter,
                Parent = WarningText,
            })
        end

        local Tab = {
            Sections = {},
            SectionCount = 0,
            SectionGroups = {},
            ConditionalSections = {},
            Description = Description,
            Sides = {
                TabScroll,
            },
            WarningBox = {
                IsNormal = false,
                LockSize = false,
                Visible = false,
                Title = "WARNING",
                Text = "",
            },
        }

        function Tab:UpdateWarningBox(Info)
            if typeof(Info.IsNormal) == "boolean" then
                Tab.WarningBox.IsNormal = Info.IsNormal
            end
            if typeof(Info.LockSize) == "boolean" then
                Tab.WarningBox.LockSize = Info.LockSize
            end
            if typeof(Info.Visible) == "boolean" then
                Tab.WarningBox.Visible = Info.Visible
            end
            if typeof(Info.Title) == "string" then
                Tab.WarningBox.Title = Info.Title
            end
            if typeof(Info.Text) == "string" then
                Tab.WarningBox.Text = Info.Text
            end

            WarningBoxHolder.Visible = Tab.WarningBox.Visible
            WarningTitle.Text = Tab.WarningBox.Title
            WarningText.Text = Tab.WarningBox.Text
            Tab:Resize(true)

            WarningBox.BackgroundColor3 = Tab.WarningBox.IsNormal == true and Library.Scheme.BackgroundColor
                or Color3.fromRGB(127, 0, 0)

            WarningBoxShadowOutline.Color = Tab.WarningBox.IsNormal == true and Library.Scheme.DarkColor
                or Color3.fromRGB(85, 0, 0)
            WarningBoxOutline.Color = Tab.WarningBox.IsNormal == true and Library.Scheme.OutlineColor
                or Color3.fromRGB(255, 50, 50)

            WarningTitle.TextColor3 = Tab.WarningBox.IsNormal == true and Library.Scheme.FontColor
                or Color3.fromRGB(255, 50, 50)
            WarningStroke.Color = Tab.WarningBox.IsNormal == true and Library.Scheme.OutlineColor
                or Color3.fromRGB(169, 0, 0)

            if not Library.Registry[WarningBox] then
                Library:AddToRegistry(WarningBox, {})
            end
            if not Library.Registry[WarningBoxShadowOutline] then
                Library:AddToRegistry(WarningBoxShadowOutline, {})
            end
            if not Library.Registry[WarningBoxOutline] then
                Library:AddToRegistry(WarningBoxOutline, {})
            end
            if not Library.Registry[WarningTitle] then
                Library:AddToRegistry(WarningTitle, {})
            end
            if not Library.Registry[WarningStroke] then
                Library:AddToRegistry(WarningStroke, {})
            end

            Library.Registry[WarningBox].BackgroundColor3 = function()
                return Tab.WarningBox.IsNormal == true and Library.Scheme.BackgroundColor or Color3.fromRGB(127, 0, 0)
            end

            Library.Registry[WarningBoxShadowOutline].Color = function()
                return Tab.WarningBox.IsNormal == true and Library.Scheme.DarkColor or Color3.fromRGB(85, 0, 0)
            end

            Library.Registry[WarningBoxOutline].Color = function()
                return Tab.WarningBox.IsNormal == true and Library.Scheme.OutlineColor or Color3.fromRGB(255, 50, 50)
            end

            Library.Registry[WarningTitle].TextColor3 = function()
                return Tab.WarningBox.IsNormal == true and Library.Scheme.FontColor or Color3.fromRGB(255, 50, 50)
            end

            Library.Registry[WarningStroke].Color = function()
                return Tab.WarningBox.IsNormal == true and Library.Scheme.OutlineColor or Color3.fromRGB(169, 0, 0)
            end
        end

        function Tab:RefreshSides()
            local Offset = WarningBoxHolder.Visible and WarningBox.Size.Y.Offset + 8 or 0
            for _, Side in Tab.Sides do
                Side.Position = UDim2.new(0, 0, 0, Offset)
                Side.Size = UDim2.new(1, 0, 1, -Offset)
            end
        end

        function Tab:Resize(ResizeWarningBox: boolean?)
            if ResizeWarningBox then
                local MaximumSize = math.floor(TabContainer.AbsoluteSize.Y / 3.25)
                local _, YText = Library:GetTextBounds(
                    WarningText.Text,
                    Library.Scheme.Font,
                    WarningText.TextSize,
                    WarningText.AbsoluteSize.X
                )

                local YBox = 24 + YText
                if Tab.WarningBox.LockSize == true and YBox >= MaximumSize then
                    WarningBoxScrollingFrame.CanvasSize = UDim2.fromOffset(0, YBox)
                    YBox = MaximumSize
                else
                    WarningBoxScrollingFrame.CanvasSize = UDim2.fromOffset(0, 0)
                end

                WarningText.Size = UDim2.new(1, -4, 0, YText)
                WarningBox.Size = UDim2.new(1, -5, 0, YBox + 4)
            end

            Tab:RefreshSides()
        end

        function Tab:AddSection(NameOrInfo, IconName)
            local Info
            if typeof(NameOrInfo) == "table" then
                Info = NameOrInfo
            else
                Info = { Name = NameOrInfo, IconName = IconName }
            end

            local SectionParent, SectionOrder = GetSectionParent(Info.Side)
            local BoxHolder = New("Frame", {
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                LayoutOrder = SectionOrder or 0,
                Size = UDim2.fromScale(1, 0),
                Parent = SectionParent,
            })
            New("UIListLayout", {
                Padding = UDim.new(0, 8),
                Parent = BoxHolder,
            })
            New("UIPadding", {
                PaddingBottom = UDim.new(0, 8),
                PaddingTop = UDim.new(0, 8),
                Parent = BoxHolder,
            })

            local SectionHolder
            local SectionLabel

            local SectionContainer
            local SectionList
            local SectionSeparatorLine

            do
                SectionHolder = New("Frame", {
                    BackgroundColor3 = "BackgroundColor",
                    Size = UDim2.fromScale(1, 0),
                    Parent = BoxHolder,
                })
                table.insert(
                    Library.Corners,
                    New("UICorner", {
                        CornerRadius = UDim.new(0, WindowInfo.CornerRadius),
                        Parent = SectionHolder,
                    })
                )
                Library:AddOutline(SectionHolder)

                SectionSeparatorLine = Library:MakeLine(SectionHolder, {
                    Position = UDim2.fromOffset(0, 34),
                    Size = UDim2.new(1, 0, 0, 1),
                })

                local BoxIcon = Library:GetCustomIcon(Info.IconName)
                if BoxIcon then
                    New("ImageLabel", {
                        Image = BoxIcon.Url,
                        ImageColor3 = BoxIcon.Custom and "WhiteColor" or "AccentColor",
                        ImageRectOffset = BoxIcon.ImageRectOffset,
                        ImageRectSize = BoxIcon.ImageRectSize,
                        Position = UDim2.fromOffset(6, 6),
                        Size = UDim2.fromOffset(22, 22),
                        Parent = SectionHolder,
                    })
                end

                local SectionHeaderBtn = New("TextButton", {
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(0, 0),
                    Size = UDim2.new(1, 0, 0, 34),
                    Text = "",
                    Parent = SectionHolder,
                })

                SectionLabel = New("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(BoxIcon and 24 or 0, 0),
                    Size = UDim2.new(1, -(BoxIcon and 24 or 0) - 28, 0, 34),
                    Text = Info.Name,
                    TextSize = 15,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = SectionHeaderBtn,
                })
                New("UIPadding", {
                    PaddingLeft = UDim.new(0, 12),
                    PaddingRight = UDim.new(0, 12),
                    Parent = SectionLabel,
                })

                local SectionFoldOpen = Info.DefaultOpen ~= false
                local SectionChevronDown = Library:GetIcon("chevron-down")
                local SectionChevronRight = Library:GetIcon("chevron-right")
                local SectionArrow = New("ImageLabel", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    BackgroundTransparency = 1,
                    Position = UDim2.new(1, -10, 0.5, 0),
                    Size = UDim2.fromOffset(12, 12),
                    ImageColor3 = "FontColor",
                    ImageTransparency = 0.5,
                    ScaleType = Enum.ScaleType.Fit,
                    Image = SectionFoldOpen
                        and (SectionChevronDown and SectionChevronDown.Url or "")
                        or (SectionChevronRight and SectionChevronRight.Url or ""),
                    ImageRectOffset = SectionFoldOpen
                        and (SectionChevronDown and SectionChevronDown.ImageRectOffset or Vector2.zero)
                        or (SectionChevronRight and SectionChevronRight.ImageRectOffset or Vector2.zero),
                    ImageRectSize = SectionFoldOpen
                        and (SectionChevronDown and SectionChevronDown.ImageRectSize or Vector2.zero)
                        or (SectionChevronRight and SectionChevronRight.ImageRectSize or Vector2.zero),
                    Parent = SectionHeaderBtn,
                })
                Library:AddToRegistry(SectionArrow, { ImageColor3 = "FontColor" })

                SectionContainer = New("Frame", {
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(0, 35),
                    Size = UDim2.new(1, 0, 1, -35),
                    Visible = SectionFoldOpen,
                    Parent = SectionHolder,
                })
                SectionSeparatorLine.Visible = SectionFoldOpen

                SectionList = New("UIListLayout", {
                    Padding = UDim.new(0, 10),
                    Parent = SectionContainer,
                })
                New("UIPadding", {
                    PaddingBottom = UDim.new(0, 10),
                    PaddingLeft = UDim.new(0, 10),
                    PaddingRight = UDim.new(0, 10),
                    PaddingTop = UDim.new(0, 10),
                    Parent = SectionContainer,
                })
            end

            Tab.SectionCount += 1

            local Section = {
                BoxHolder = BoxHolder,
                Holder = SectionHolder,
                Container = SectionContainer,

                Tab = Tab,
                ConditionalGroups = {},
                SubSections = {},
                Elements = {},

                Side = Info.Side or 1,
                Order = Tab.SectionCount,

                Folded = not (Info.DefaultOpen ~= false),

                SubSectionLayout = {
                    CurrentLayoutMode = nil,
                    CurrentColumnsRow = nil,
                    CurrentColumnLeft = nil,
                    CurrentColumnRight = nil,
                    NextOrder = 0,
                },
            }

            function Section:Resize()
                if Section.Folded then
                    SectionHolder.Size = UDim2.new(1, 0, 0, 34)
                else
                    SectionHolder.Size = UDim2.new(1, 0, 0, (SectionList.AbsoluteContentSize.Y / Library.DPIScale) + 54)
                end
            end

            do
                local SectionChevronDown = Library:GetIcon("chevron-down")
                local SectionChevronRight = Library:GetIcon("chevron-right")

                local function SetSectionArrowIcon(Arrow, Open)
                    local Icon = Open and SectionChevronDown or SectionChevronRight
                    if Icon then
                        Arrow.Image = Icon.Url
                        Arrow.ImageRectOffset = Icon.ImageRectOffset
                        Arrow.ImageRectSize = Icon.ImageRectSize
                    end
                end

                local HeaderBtn = SectionHolder:FindFirstChildWhichIsA("TextButton")
                local Arrow = HeaderBtn and HeaderBtn:FindFirstChildWhichIsA("ImageLabel")

                function Section:SetFolded(Folded)
                    if Section.Folded == Folded then return end
                    Section.Folded = Folded
                    SectionContainer.Visible = not Section.Folded
                    SectionSeparatorLine.Visible = not Section.Folded
                    if Arrow then
                        SetSectionArrowIcon(Arrow, not Section.Folded)
                    end
                    Section:Resize()
                end

                if HeaderBtn then
                    HeaderBtn.MouseButton1Click:Connect(function()
                        Section:SetFolded(not Section.Folded)
                    end)
                end
            end

            setmetatable(Section, BaseSection)

            Section:Resize()
            Tab.Sections[Info.Name] = Section

            return Section
        end

        function Tab:AddLeftSection(Name, IconName)
            return Tab:AddSection({ Side = 1, Name = Name, IconName = IconName })
        end

        function Tab:AddRightSection(Name, IconName)
            return Tab:AddSection({ Side = 2, Name = Name, IconName = IconName })
        end

        function Tab:AddSectionGroup(NameOrInfo)
            local Section = self
            local Container = Section.Container

            local Info
            if typeof(NameOrInfo) == "table" then
                Info = NameOrInfo
            else
                Info = { Name = NameOrInfo, IconName = IconName }
            end

            if not Section.SubSectionLayout then
                Section.SubSectionLayout = {
                    CurrentLayoutMode = nil,
                    CurrentColumnsRow = nil,
                    CurrentColumnLeft = nil,
                    CurrentColumnRight = nil,
                    NextOrder = 0,
                }
            end

            local SubSectionLayout = Section.SubSectionLayout

            local function GetSubSectionParent(Side)
                local RequestedMode = (Side == 1 or Side == 2) and "two-column" or nil

                local NeedNewRow = SubSectionLayout.CurrentLayoutMode ~= RequestedMode

                if NeedNewRow then
                    SubSectionLayout.CurrentLayoutMode = RequestedMode

                    if RequestedMode == "two-column" then

                        SubSectionLayout.CurrentColumnsRow = New("Frame", {
                            AutomaticSize = Enum.AutomaticSize.Y,
                            BackgroundTransparency = 1,
                            LayoutOrder = SubSectionLayout.NextOrder,
                            Size = UDim2.new(1, 0, 0, 0),
                            Parent = Container,
                        })

                        SubSectionLayout.CurrentColumnLeft = New("Frame", {
                            AutomaticSize = Enum.AutomaticSize.Y,
                            BackgroundTransparency = 1,
                            Size = UDim2.new(0.5, -3, 0, 0),
                            Parent = SubSectionLayout.CurrentColumnsRow,
                        })
                        New("UIListLayout", {
                            Padding = UDim.new(0, 2),
                            SortOrder = Enum.SortOrder.LayoutOrder,
                            Parent = SubSectionLayout.CurrentColumnLeft,
                        })

                        SubSectionLayout.CurrentColumnRight = New("Frame", {
                            AnchorPoint = Vector2.new(1, 0),
                            AutomaticSize = Enum.AutomaticSize.Y,
                            BackgroundTransparency = 1,
                            Position = UDim2.fromScale(1, 0),
                            Size = UDim2.new(0.5, -3, 0, 0),
                            Parent = SubSectionLayout.CurrentColumnsRow,
                        })
                        New("UIListLayout", {
                            Padding = UDim.new(0, 2),
                            SortOrder = Enum.SortOrder.LayoutOrder,
                            Parent = SubSectionLayout.CurrentColumnRight,
                        })

                        SubSectionLayout.NextOrder = SubSectionLayout.NextOrder + 1
                    else

                        SubSectionLayout.NextOrder = SubSectionLayout.NextOrder + 1
                    end
                end

                if RequestedMode == "two-column" then
                    return Side == 1 and SubSectionLayout.CurrentColumnLeft or SubSectionLayout.CurrentColumnRight
                else
                    local Order = SubSectionLayout.NextOrder - 1
                    return Container, Order
                end
            end

            local SubSectionParent, SubSectionOrder = GetSubSectionParent(Info.Side)

            local SubSectionHolder
            local SubSectionLabel
            local SubSectionContainer
            local SubSectionList
            local SubSectionSeparatorLine

            do
                SubSectionHolder = New("Frame", {
                    BackgroundColor3 = "MainColor",
                    BackgroundTransparency = 0.3,
                    Size = UDim2.new(1, 0, 0, 0),
                    LayoutOrder = SubSectionOrder or 0,
                    Parent = SubSectionParent,
                })
                table.insert(
                    Library.Corners,
                    New("UICorner", {
                        CornerRadius = UDim.new(0, WindowInfo.CornerRadius - 2),
                        Parent = SubSectionHolder,
                    })
                )
                Library:AddOutline(SubSectionHolder)

                SubSectionSeparatorLine = Library:MakeLine(SubSectionHolder, {
                    Position = UDim2.fromOffset(0, 28),
                    Size = UDim2.new(1, 0, 0, 1),
                })

                local BoxIcon = Library:GetCustomIcon(Info.IconName)
                if BoxIcon then
                    New("ImageLabel", {
                        Image = BoxIcon.Url,
                        ImageColor3 = BoxIcon.Custom and "WhiteColor" or "AccentColor",
                        ImageRectOffset = BoxIcon.ImageRectOffset,
                        ImageRectSize = BoxIcon.ImageRectSize,
                        Position = UDim2.fromOffset(11, 4),
                        Size = UDim2.fromOffset(18, 18),
                        Parent = SubSectionHolder,
                    })
                end

                local SubSectionHeaderBtn = New("TextButton", {
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(0, 0),
                    Size = UDim2.new(1, 0, 0, 28),
                    Text = "",
                    Parent = SubSectionHolder,
                })

                SubSectionLabel = New("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(BoxIcon and 23 or 3, 0),
                    Size = UDim2.new(1, -(BoxIcon and 23 or 3) - 24, 0, 28),
                    Text = Info.Name,
                    TextSize = 13,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = SubSectionHeaderBtn,
                })
                New("UIPadding", {
                    PaddingLeft = UDim.new(0, 10),
                    PaddingRight = UDim.new(0, 10),
                    Parent = SubSectionLabel,
                })

                local SubSectionFoldOpen = Info.DefaultOpen ~= false
                local SectionChevronDown = Library:GetIcon("chevron-down")
                local SectionChevronRight = Library:GetIcon("chevron-right")
                local SubSectionArrow = New("ImageLabel", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    BackgroundTransparency = 1,
                    Position = UDim2.new(1, -8, 0.5, 0),
                    Size = UDim2.fromOffset(10, 10),
                    ImageColor3 = "FontColor",
                    ImageTransparency = 0.5,
                    ScaleType = Enum.ScaleType.Fit,
                    Image = SubSectionFoldOpen
                        and (SectionChevronDown and SectionChevronDown.Url or "")
                        or (SectionChevronRight and SectionChevronRight.Url or ""),
                    ImageRectOffset = SubSectionFoldOpen
                        and (SectionChevronDown and SectionChevronDown.ImageRectOffset or Vector2.zero)
                        or (SectionChevronRight and SectionChevronRight.ImageRectOffset or Vector2.zero),
                    ImageRectSize = SubSectionFoldOpen
                        and (SectionChevronDown and SectionChevronDown.ImageRectSize or Vector2.zero)
                        or (SectionChevronRight and SectionChevronRight.ImageRectSize or Vector2.zero),
                    Parent = SubSectionHeaderBtn,
                })
                Library:AddToRegistry(SubSectionArrow, { ImageColor3 = "FontColor" })

                SubSectionContainer = New("Frame", {
                    BackgroundColor3 = "BackgroundColor",
                    BackgroundTransparency = 0.5,
                    Position = UDim2.fromOffset(0, 29),
                    Size = UDim2.new(1, 0, 1, -29),
                    Visible = SubSectionFoldOpen,
                    Parent = SubSectionHolder,
                })
                SubSectionSeparatorLine.Visible = SubSectionFoldOpen

                SubSectionList = New("UIListLayout", {
                    Padding = UDim.new(0, 8),
                    Parent = SubSectionContainer,
                })
                New("UIPadding", {
                    PaddingBottom = UDim.new(0, 12),
                    PaddingLeft = UDim.new(0, 8),
                    PaddingRight = UDim.new(0, 8),
                    PaddingTop = UDim.new(0, 8),
                    Parent = SubSectionContainer,
                })
            end

            local SubSection = {
                Holder = SubSectionHolder,

                HeaderHolder = SubSectionHeaderBtn,
                Container = SubSectionContainer,

                Tab = Section.Tab,
                ConditionalGroups = {},
                Elements = {},

                ParentSection = Section,
                Folded = not (Info.DefaultOpen ~= false),
                Side = Info.Side,
            }

            function SubSection:Resize()
                if SubSection.Folded then
                    SubSectionHolder.Size = UDim2.new(1, 0, 0, 28)
                else
                    SubSectionHolder.Size = UDim2.new(1, 0, 0, (SubSectionList.AbsoluteContentSize.Y / Library.DPIScale) + 48)
                end
                Section:Resize()
            end

            do
                local SectionChevronDown = Library:GetIcon("chevron-down")
                local SectionChevronRight = Library:GetIcon("chevron-right")
                local function SetSectionArrowIcon(Arrow, Open)
                    local Icon = Open and SectionChevronDown or SectionChevronRight
                    if Icon then
                        Arrow.Image = Icon.Url
                        Arrow.ImageRectOffset = Icon.ImageRectOffset
                        Arrow.ImageRectSize = Icon.ImageRectSize
                    end
                end

                local HeaderBtn = SubSectionHolder:FindFirstChildWhichIsA("TextButton")
                local Arrow = HeaderBtn and HeaderBtn:FindFirstChildWhichIsA("ImageLabel")

                function SubSection:SetFolded(Folded)
                    if SubSection.Folded == Folded then return end
                    SubSection.Folded = Folded
                    SubSectionContainer.Visible = not SubSection.Folded
                    SubSectionSeparatorLine.Visible = not SubSection.Folded
                    if Arrow then
                        SetSectionArrowIcon(Arrow, not SubSection.Folded)
                    end
                    SubSection:Resize()
                end

                if HeaderBtn then
                    HeaderBtn.MouseButton1Click:Connect(function()
                        SubSection:SetFolded(not SubSection.Folded)
                    end)
                end
            end

            setmetatable(SubSection, BaseSection)

            SubSection:Resize()

            return SubSection
        end

        function Tab:AddSectionGroup(NameOrInfo)
            local Info
            if typeof(NameOrInfo) == "table" then
                Info = NameOrInfo
            else
                Info = { Name = NameOrInfo }
            end

            local SectionParent, SectionOrder = GetSectionParent(Info.Side)
            local BoxHolder = New("Frame", {
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                LayoutOrder = SectionOrder or 0,
                Size = UDim2.fromScale(1, 0),
                Parent = SectionParent,
            })
            New("UIListLayout", {
                Padding = UDim.new(0, 6),
                Parent = BoxHolder,
            })
            New("UIPadding", {
                PaddingBottom = UDim.new(0, 4),
                PaddingTop = UDim.new(0, 4),
                Parent = BoxHolder,
            })

            local SectionGroupHolder
            local SectionGroupButtons

            do
                SectionGroupHolder = New("Frame", {
                    BackgroundColor3 = "BackgroundColor",
                    Size = UDim2.fromScale(1, 0),
                    Parent = BoxHolder,
                })
                table.insert(
                    Library.Corners,
                    New("UICorner", {
                        CornerRadius = UDim.new(0, WindowInfo.CornerRadius),
                        Parent = SectionGroupHolder,
                    })
                )
                Library:AddOutline(SectionGroupHolder)

                SectionGroupButtons = New("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 34),
                    Parent = SectionGroupHolder,
                })
                New("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalFlex = Enum.UIFlexAlignment.Fill,
                    Parent = SectionGroupButtons,
                })
            end

            local TotalButtons, TotalTabs = 0, 1
            local SectionGroup = {
                ActiveTab = nil,

                BoxHolder = BoxHolder,
                Holder = SectionGroupHolder,
                Tabs = {}
            }

            function SectionGroup:UpdateCorners()
                for _, Page in SectionGroup.Tabs do
                    Page:UpdateCorners()
                end
            end

            function SectionGroup:AddTab(Name, IconName)
                local TabIndex = TotalTabs

                TotalButtons = TotalButtons + 1
                TotalTabs = TotalTabs + 1

                local BoxIcon = Library:GetCustomIcon(IconName)

                local Button = New("TextButton", {
                    BackgroundColor3 = "MainColor",
                    BackgroundTransparency = 0,
                    Size = UDim2.fromOffset(0, 34),
                    Text = "",
                    Parent = SectionGroupButtons,
                })

                table.insert(
                    Library.Corners,
                    New("UICorner", {
                        CornerRadius = UDim.new(0, WindowInfo.CornerRadius),
                        Parent = Button,
                    })
                )

                local BottomCover = New("Frame", {
                    Name = "BottomCover",
                    BackgroundColor3 = "MainColor",
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 0, 1, -WindowInfo.CornerRadius),
                    Size = UDim2.new(1, 0, 0, WindowInfo.CornerRadius),
                    Parent = Button,
                })

                local LeftCover = New("Frame", {
                    Name = "LeftCover",
                    BackgroundColor3 = "MainColor",
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 0, 0, 0),
                    Size = UDim2.new(0, WindowInfo.CornerRadius, 1, 0),
                    Visible = false,
                    Parent = Button,
                })

                local RightCover = New("Frame", {
                    Name = "RightCover",
                    AnchorPoint = Vector2.new(1, 0),
                    BackgroundColor3 = "MainColor",
                    BorderSizePixel = 0,
                    Position = UDim2.new(1, 0, 0, 0),
                    Size = UDim2.new(0, WindowInfo.CornerRadius, 1, 0),
                    Visible = false,
                    Parent = Button,
                })

                local ButtonContent = New("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    AutomaticSize = Enum.AutomaticSize.X,
                    BackgroundTransparency = 1,
                    Position = UDim2.fromScale(0.5, 0.5),
                    Size = UDim2.fromOffset(0, 16),
                    Parent = Button,
                })
                New("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    Padding = UDim.new(0, 8),
                    Parent = ButtonContent,
                })

                local ButtonIcon
                if BoxIcon then
                    ButtonIcon = New("ImageLabel", {
                        Image = BoxIcon.Url,
                        ImageColor3 = BoxIcon.Custom and "WhiteColor" or "AccentColor",
                        ImageRectOffset = BoxIcon.ImageRectOffset,
                        ImageRectSize = BoxIcon.ImageRectSize,
                        ImageTransparency = 0.5,
                        Size = UDim2.fromOffset(16, 16),
                        Parent = ButtonContent,
                    })
                end

                local ButtonLabel = New("TextLabel", {
                    AutomaticSize = Enum.AutomaticSize.X,
                    BackgroundTransparency = 1,
                    Size = UDim2.fromOffset(0, 16),
                    Text = Name,
                    TextSize = 15,
                    TextTransparency = 0.5,
                    Parent = ButtonContent,
                })

                local Line = Library:MakeLine(Button, {
                    AnchorPoint = Vector2.new(0, 1),
                    Position = UDim2.new(0, 0, 1, 1),
                    Size = UDim2.new(1, 0, 0, 1),
                })

                local Container = New("Frame", {
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(0, 35),
                    Size = UDim2.new(1, 0, 1, -35),
                    Visible = false,
                    Parent = SectionGroupHolder,
                })
                local List = New("UIListLayout", {
                    Padding = UDim.new(0, 8),
                    Parent = Container,
                })
                New("UIPadding", {
                    PaddingBottom = UDim.new(0, 8),
                    PaddingLeft = UDim.new(0, 8),
                    PaddingRight = UDim.new(0, 8),
                    PaddingTop = UDim.new(0, 8),
                    Parent = Container,
                })

                local Page = {
                    ButtonHolder = Button,
                    Container = Container,

                    ButtonCovers = {
                        BottomCover = BottomCover,
                        LeftCover = LeftCover,
                        RightCover = RightCover
                    },

                    Tab = Tab,
                    Elements = {},
                    ConditionalGroups = {},
                    SubSections = {},

                    Order = TabIndex,
                }

                function Page:Show()
                    if SectionGroup.ActiveTab then
                        SectionGroup.ActiveTab:Hide()
                    end

                    Button.BackgroundTransparency = 1
                    BottomCover.BackgroundTransparency = 1
                    LeftCover.BackgroundTransparency = 1
                    RightCover.BackgroundTransparency = 1

                    ButtonLabel.TextTransparency = 0
                    if ButtonIcon then
                        ButtonIcon.ImageTransparency = 0
                    end
                    Line.Visible = false

                    Container.Visible = true

                    SectionGroup.ActiveTab = Page
                    Page:Resize()
                end

                function Page:Hide()
                    Button.BackgroundTransparency = 0
                    BottomCover.BackgroundTransparency = 0
                    LeftCover.BackgroundTransparency = 0
                    RightCover.BackgroundTransparency = 0

                    ButtonLabel.TextTransparency = 0.5
                    if ButtonIcon then
                        ButtonIcon.ImageTransparency = 0.5
                    end
                    Line.Visible = true
                    Container.Visible = false

                    SectionGroup.ActiveTab = nil
                end

                function Page:Resize()
                    if SectionGroup.ActiveTab ~= Page then
                        return
                    end

                    SectionGroupHolder.Size = UDim2.new(1, 0, 0, (List.AbsoluteContentSize.Y / Library.DPIScale) + 49)
                end

                function Page:UpdateCorners()
                    LeftCover.Visible = TabIndex ~= 1
                    RightCover.Visible = TabIndex ~= TotalButtons

                    BottomCover.Position = UDim2.new(0, 0, 1, -WindowInfo.CornerRadius)
                    BottomCover.Size = UDim2.new(1, 0, 0, WindowInfo.CornerRadius)

                    LeftCover.Size = UDim2.new(0, WindowInfo.CornerRadius, 1, 0)
                    RightCover.Size = UDim2.new(0, WindowInfo.CornerRadius, 1, 0)
                end

                if not SectionGroup.ActiveTab then
                    Page:Show()
                end

                Button.MouseButton1Click:Connect(Page.Show)

                setmetatable(Page, BaseSection)

                SectionGroup.Tabs[Name] = Page
                SectionGroup:UpdateCorners()

                return Page
            end

            if Info.Name then
                Tab.SectionGroups[Info.Name] = SectionGroup
            else
                table.insert(Tab.SectionGroups, SectionGroup)
            end

            return SectionGroup
        end

        function Tab:AddLeftSectionGroup(Name)
            return Tab:AddSectionGroup({ Side = 1, Name = Name })
        end

        function Tab:AddRightSectionGroup(Name)
            return Tab:AddSectionGroup({ Side = 2, Name = Name })
        end

        function Tab:Hover(Hovering)
            if Library.ActiveTab == Tab then
                return
            end

            TweenService:Create(TabLabel, Library.TweenInfo, {
                TextTransparency = Hovering and 0.25 or 0.5,
            }):Play()
            if TabIcon then
                TweenService:Create(TabIcon, Library.TweenInfo, {
                    ImageTransparency = Hovering and 0.25 or 0.5,
                }):Play()
            end
        end

        function Tab:Show()
            if Library.ActiveTab then
                Library.ActiveTab:Hide()
            end

            TweenService:Create(TabButton, Library.TweenInfo, {
                BackgroundTransparency = 1,
            }):Play()
            TweenService:Create(TabLabel, Library.TweenInfo, {
                TextTransparency = 0,
            }):Play()
            if TabIcon then
                TweenService:Create(TabIcon, Library.TweenInfo, {
                    ImageTransparency = 0,
                }):Play()
            end

            if Description then
                Window:ShowTabInfo(Name, Description)
            end

            TabContainer.Visible = true
            Tab:RefreshSides()

            Library.ActiveTab = Tab
            Library:FireActiveTabChanged(Tab)

            if Library.Searching then
                Library:UpdateSearch(Library.SearchText)
            end
        end

        function Tab:Hide()
            TweenService:Create(TabButton, Library.TweenInfo, {
                BackgroundTransparency = 1,
            }):Play()
            TweenService:Create(TabLabel, Library.TweenInfo, {
                TextTransparency = 0.5,
            }):Play()
            if TabIcon then
                TweenService:Create(TabIcon, Library.TweenInfo, {
                    ImageTransparency = 0.5,
                }):Play()
            end
            TabContainer.Visible = false

            Window:HideTabInfo()

            Library.ActiveTab = nil
        end

        function Tab:SetVisible(Visible: boolean)
            TabButton.Visible = Visible

            if not Visible and Library.ActiveTab == Tab then
                Tab:Hide()
            end
        end

        if not Library.ActiveTab then
            Tab:Show()
        end

        TabButton.MouseEnter:Connect(function()
            Tab:Hover(true)
        end)
        TabButton.MouseLeave:Connect(function()
            Tab:Hover(false)
        end)
        TabButton.MouseButton1Click:Connect(Tab.Show)

        Library.Tabs[Name] = Tab

        return Tab
    end

    function Window:AddKeyTab(...)
        local Name = nil
        local Icon = nil
        local Description = nil

        if select("#", ...) == 1 and typeof(...) == "table" then
            local Info = select(1, ...)
            Name = Info.Name or "Tab"
            Icon = Info.Icon
            Description = Info.Description
        else
            Name = select(1, ...) or "Tab"
            Icon = select(2, ...)
            Description = select(3, ...)
        end

        Icon = Icon or "key"

        local TabButton: TextButton
        local TabLabel
        local TabIcon

        local TabContainer

        Icon = if Icon == "key" then KeyIcon else Library:GetCustomIcon(Icon)
        do
            TabButton = New("TextButton", {
                BackgroundColor3 = "MainColor",
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 40),
                Text = "",
                Parent = Tabs,
            })
            local ButtonPadding = New("UIPadding", {
                PaddingBottom = UDim.new(0, 4),
                PaddingLeft = UDim.new(0, IsCompact and 4 or 20),
                PaddingRight = UDim.new(0, 4),
                PaddingTop = UDim.new(0, 4),
                Parent = TabButton,
            })

            local IconSlot = New("Frame", {
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 0, 0.5, 0),
                Size = UDim2.new(0, 20, 1, 0),
                SizeConstraint = Enum.SizeConstraint.RelativeYY,
                Parent = TabButton,
            })

            if Icon then
                TabIcon = New("ImageLabel", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Image = Icon.Url,
                    ImageColor3 = Icon.Custom and "WhiteColor" or "AccentColor",
                    ImageRectOffset = Icon.ImageRectOffset,
                    ImageRectSize = Icon.ImageRectSize,
                    ImageTransparency = 0.5,
                    Position = UDim2.fromScale(0.5, 0.5),
                    ScaleType = Enum.ScaleType.Fit,
                    Size = UDim2.fromScale(1, 1),
                    SizeConstraint = Enum.SizeConstraint.RelativeYY,
                    Parent = IconSlot,
                })
            end

            local FirstLetterLabel = New("TextLabel", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromScale(1, 1),
                Text = Name:sub(1, 1):upper(),
                TextSize = 14,
                TextTransparency = 0.5,
                Visible = not Icon and IsCompact,
                Parent = IconSlot,
            })

            TabLabel = New("TextLabel", {
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 28, 0.5, 0),
                Size = UDim2.new(1, -28, 0, 18),
                Text = Name,
                TextSize = 14,
                TextTransparency = 0.5,
                TextTruncate = Enum.TextTruncate.AtEnd,
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Left,
                Visible = not IsCompact,
                Parent = TabButton,
            })

            local TabTooltip = CompactTooltips and Library:AddTooltip(Name, nil, TabButton) or nil
            if TabTooltip then TabTooltip.Disabled = not IsCompact end

            table.insert(Library.TabButtons, {
                Label = TabLabel,
                Padding = ButtonPadding,
                Icon = TabIcon,
                IconSlot = IconSlot,
                FirstLetter = FirstLetterLabel,
                Tooltip = TabTooltip,
            })

            TabContainer = New("ScrollingFrame", {
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                CanvasSize = UDim2.fromScale(0, 0),
                ScrollBarImageColor3 = "OutlineColor",
                ScrollBarThickness = 3,
                Size = UDim2.fromScale(1, 1),
                Visible = false,
                Parent = Container,
            })
            Library:AddToRegistry(TabContainer, { ScrollBarImageColor3 = "OutlineColor" })
            New("UIListLayout", {
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                Padding = UDim.new(0, 8),
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Parent = TabContainer,
            })
            New("UIPadding", {
                PaddingLeft = UDim.new(0, 1),
                PaddingRight = UDim.new(0, 1),
                Parent = TabContainer,
            })
        end

        local Tab = {
            Elements = {},
            Description = Description,
            IsKeyTab = true,
        }

        function Tab:AddKeyBox(Callback)
            assert(typeof(Callback) == "function", "Callback must be a function")

            local Holder = New("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(0.75, 0, 0, 21),
                Parent = TabContainer,
            })

            local Box = New("TextBox", {
                BackgroundColor3 = "MainColor",
                PlaceholderText = "Key",
                Size = UDim2.new(1, -71, 1, 0),
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = Holder,
            })
            New("UIPadding", {
                PaddingLeft = UDim.new(0, 8),
                PaddingRight = UDim.new(0, 8),
                Parent = Box,
            })
            New("UIStroke", {
                Color = "OutlineColor",
                Parent = Box,
            })
            table.insert(
                Library.Corners,
                New("UICorner", {
                    CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                    Parent = Box,
                })
            )

            local Button = New("TextButton", {
                AnchorPoint = Vector2.new(1, 0),
                BackgroundColor3 = "MainColor",
                Position = UDim2.fromScale(1, 0),
                Size = UDim2.new(0, 63, 1, 0),
                Text = "Execute",
                TextSize = 14,
                Parent = Holder,
            })
            New("UIStroke", {
                Color = "OutlineColor",
                Parent = Button,
            })
            table.insert(
                Library.Corners,
                New("UICorner", {
                    CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                    Parent = Button,
                })
            )

            Button.InputBegan:Connect(function(Input)
                if not IsClickInput(Input) then
                    return
                end

                if not Library:MouseIsOverFrame(Button, Input.Position) then
                    return
                end

                Callback(Box.Text)
            end)
        end

        function Tab:RefreshSides() end
        function Tab:Resize() end
        function Tab:UpdateCorners() end

        function Tab:Hover(Hovering)
            if Library.ActiveTab == Tab then
                return
            end

            TweenService:Create(TabLabel, Library.TweenInfo, {
                TextTransparency = Hovering and 0.25 or 0.5,
            }):Play()
            if TabIcon then
                TweenService:Create(TabIcon, Library.TweenInfo, {
                    ImageTransparency = Hovering and 0.25 or 0.5,
                }):Play()
            end
        end

        function Tab:Show()
            if Library.ActiveTab then
                Library.ActiveTab:Hide()
            end

            TweenService:Create(TabButton, Library.TweenInfo, {
                BackgroundTransparency = 1,
            }):Play()
            TweenService:Create(TabLabel, Library.TweenInfo, {
                TextTransparency = 0,
            }):Play()
            if TabIcon then
                TweenService:Create(TabIcon, Library.TweenInfo, {
                    ImageTransparency = 0,
                }):Play()
            end
            TabContainer.Visible = true

            if Description then
                Window:ShowTabInfo(Name, Description)
            end

            Tab:RefreshSides()

            Library.ActiveTab = Tab
            Library:FireActiveTabChanged(Tab)

            if Library.Searching then
                Library:UpdateSearch(Library.SearchText)
            end
        end

        function Tab:Hide()
            TweenService:Create(TabButton, Library.TweenInfo, {
                BackgroundTransparency = 1,
            }):Play()
            TweenService:Create(TabLabel, Library.TweenInfo, {
                TextTransparency = 0.5,
            }):Play()
            if TabIcon then
                TweenService:Create(TabIcon, Library.TweenInfo, {
                    ImageTransparency = 0.5,
                }):Play()
            end
            TabContainer.Visible = false

            Window:HideTabInfo()

            Library.ActiveTab = nil
        end

        function Tab:SetVisible(Visible: boolean)
            TabButton.Visible = Visible

            if not Visible and Library.ActiveTab == Tab then
                Tab:Hide()
            end
        end

        if not Library.ActiveTab then
            Tab:Show()
        end

        TabButton.MouseEnter:Connect(function()
            Tab:Hover(true)
        end)
        TabButton.MouseLeave:Connect(function()
            Tab:Hover(false)
        end)
        TabButton.MouseButton1Click:Connect(Tab.Show)

        Tab.Container = TabContainer
        setmetatable(Tab, BaseSection)

        Library.Tabs[Name] = Tab

        return Tab
    end

    function Window:AddDialog(Idx, Info)
        Info = Library:Validate(Info, Templates.Dialog)

        local DialogFrame
        local DialogOverlay
        local DialogContainer
        local ButtonsHolder
        local FooterButtonsList = {}

        DialogOverlay = New("TextButton", {
            AutoButtonColor = false,
            BackgroundColor3 = "DarkColor",
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Text = "",
            Active = false,
            ZIndex = 13000,
            Visible = true,
            Parent = MainFrame,
        })
        TweenService:Create(DialogOverlay, Library.TweenInfo, {
            BackgroundTransparency = 0.5,
        }):Play()

        DialogFrame = New("TextButton", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = "BackgroundColor",
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(300, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Text = "",
            AutoButtonColor = false,
            ZIndex = 13001,
            Parent = DialogOverlay,
        })
        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, WindowInfo.CornerRadius),
                Parent = DialogFrame,
            })
        )
        Library:AddOutline(DialogFrame)

        local InnerContainer = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            ZIndex = 13002,
            Parent = DialogFrame,
        })
        local DialogScale = New("UIScale", {
            Scale = 0.95,
            Parent = DialogFrame,
        })
        TweenService:Create(DialogScale, Library.TweenInfo, {
            Scale = 1
        }):Play()
        local _InnerPadding = New("UIPadding", {
            PaddingBottom = UDim.new(0, 10),
            PaddingLeft = UDim.new(0, 12),
            PaddingRight = UDim.new(0, 12),
            PaddingTop = UDim.new(0, 10),
            Parent = InnerContainer,
        })
        local _InnerLayout = New("UIListLayout", {
            Padding = UDim.new(0, 4),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = InnerContainer,
        })

        local HeaderContainer = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = 1,
            ZIndex = 13002,
            Parent = InnerContainer,
        })
        New("UIListLayout", {
            Padding = UDim.new(0, 4),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = HeaderContainer,
        })
        New("UIPadding", {
            PaddingBottom = UDim.new(0, 4),
            Parent = HeaderContainer,
        })

        local TitleRow = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 20),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = 1,
            ZIndex = 13002,
            Parent = HeaderContainer,
        })
        New("UIListLayout", {
            Padding = UDim.new(0, 6),
            FillDirection = Enum.FillDirection.Horizontal,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = TitleRow,
        })

        if Info.Icon then
            local ParsedIcon = Library:GetCustomIcon(Info.Icon)
            if ParsedIcon then
                local IconImg = New("ImageLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.fromOffset(16, 16),
                    Image = ParsedIcon.Url,
                    ImageColor3 = "FontColor",
                    ImageRectOffset = ParsedIcon.ImageRectOffset,
                    ImageRectSize = ParsedIcon.ImageRectSize,
                    LayoutOrder = 1,
                    ZIndex = 13002,
                    Parent = TitleRow,
                })
                if Info.TitleColor then
                    IconImg.ImageColor3 = Info.TitleColor
                end
            end
        end

        local TitleLabel = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 18),
            AutomaticSize = Enum.AutomaticSize.Y,
            Text = Info.Title,
            TextSize = 18,
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = 2,
            ZIndex = 13002,
            Parent = TitleRow,
        })
        if Info.TitleColor then
            TitleLabel.TextColor3 = Info.TitleColor
        end

        local DescriptionLabel = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 14),
            AutomaticSize = Enum.AutomaticSize.Y,
            Text = Info.Description,
            TextSize = 14,
            TextTransparency = Info.DescriptionColor and 0 or 0.2,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            LayoutOrder = 2,
            ZIndex = 13002,
            Parent = HeaderContainer,
        })
        if Info.DescriptionColor then
            DescriptionLabel.TextColor3 = Info.DescriptionColor
        end

        DialogContainer = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = 4,
            ZIndex = 13002,
            Parent = InnerContainer,
        })
        local _DialogContainerLayout = New("UIListLayout", {
            Padding = UDim.new(0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = DialogContainer,
        })
        New("UIPadding", {
            PaddingTop = UDim.new(0, 4),
            PaddingBottom = UDim.new(0, 0),
            Parent = DialogContainer,
        })

        local _Sep2 = New("Frame", {
            BackgroundColor3 = "OutlineColor",
            BackgroundTransparency = 0,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 1),
            LayoutOrder = 5,
            ZIndex = 13002,
            Parent = InnerContainer,
        })

        local AlignMap = {
            Left = Enum.HorizontalAlignment.Left,
            Center = Enum.HorizontalAlignment.Center,
            Right = Enum.HorizontalAlignment.Right,
        }
        local ButtonsHorizontalAlignment = AlignMap[Info.ButtonsAlignment] or Enum.HorizontalAlignment.Right

        ButtonsHolder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = 6,
            ZIndex = 13002,
            Parent = InnerContainer,
        })
        local ButtonsLayout = New("UIListLayout", {
            Padding = UDim.new(0, 8),
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = ButtonsHorizontalAlignment,
            Wraps = true,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = ButtonsHolder,
        })
        New("UIPadding", {
            PaddingTop = UDim.new(0, 6),
            PaddingBottom = UDim.new(0, 0),
            Parent = ButtonsHolder,
        })

        local Dialog = {
            Elements = {},
            Container = DialogContainer,
        }

        function Dialog:Resize()
            local MaxWidth = MainFrame.AbsoluteSize.X * 0.75
            local MinWidth = 400

            local TotalButtonWidth = 0
            local ButtonCount = 0
            local HasButtons = false

            for _, BtnWrap in FooterButtonsList do
                HasButtons = true
                ButtonCount = ButtonCount + 1
                TotalButtonWidth = TotalButtonWidth + BtnWrap.Container.Size.X.Offset
            end

            local TargetWidth = MinWidth
            if HasButtons then
                local RequiredWidth = TotalButtonWidth + ((ButtonCount - 1) * 8) + 30
                TargetWidth = math.max(MinWidth, math.min(RequiredWidth, MaxWidth))
            end

            DialogFrame.Size = UDim2.fromOffset(TargetWidth, 0)

            local _DescX, DescY = Library:GetTextBounds(DescriptionLabel.Text, Library.Scheme.Font, 14, TargetWidth - 30)
            DescriptionLabel.Size = UDim2.new(1, 0, 0, DescY)

            local HasElements = false
            for _, v in DialogContainer:GetChildren() do
                if not v:IsA("UIListLayout") and not v:IsA("UIPadding") then
                    HasElements = true
                    break
                end
            end
            DialogContainer.Visible = HasElements

            ButtonsHolder.Visible = HasButtons
            _Sep2.Visible = HasButtons
        end

        DialogContainer.ChildAdded:Connect(function(Child)
            task.defer(function()
                if not Child:IsA("UIListLayout") and not Child:IsA("UIPadding") then
                    DialogContainer.Visible = true
                end
            end)
        end)

        function Dialog:SetTitle(Title)
            TitleLabel.Text = Title
            Dialog:Resize()
        end

        function Dialog:SetDescription(Description)
            DescriptionLabel.Text = Description
            Dialog:Resize()
        end

        function Dialog:SetButtonsAlignment(Alignment)
            if AlignMap[Alignment] then
                ButtonsLayout.HorizontalAlignment = AlignMap[Alignment]
            end
        end

        function Dialog:Dismiss()
            Library.ActiveDialog = nil
            local CloseTween = TweenService:Create(DialogScale, Library.TweenInfo, { Scale = 0.95 })
            TweenService:Create(DialogOverlay, Library.TweenInfo, { BackgroundTransparency = 1 }):Play()
            CloseTween:Play()

            task.delay(Library.TweenInfo.Time, function()
                DialogOverlay:Destroy()
            end)
            Library.Dialogues[Idx] = nil
        end

        DialogOverlay.MouseButton1Click:Connect(function()
            if Info.OutsideClickDismiss then
                Dialog:Dismiss()
            end
        end)

        function Dialog:RemoveFooterButton(ButtonIdx)
            if FooterButtonsList[ButtonIdx] then
                FooterButtonsList[ButtonIdx].Container:Destroy()
                FooterButtonsList[ButtonIdx] = nil
            end
        end

        function Dialog:SetButtonDisabled(ButtonIdx, Disabled)
            if FooterButtonsList[ButtonIdx] and type(FooterButtonsList[ButtonIdx].SetDisabled) == "function" then
                FooterButtonsList[ButtonIdx]:SetDisabled(Disabled)
            end
        end

        function Dialog:SetButtonOrder(ButtonIdx, Order)
            if FooterButtonsList[ButtonIdx] and FooterButtonsList[ButtonIdx].Container then
                FooterButtonsList[ButtonIdx].Container.LayoutOrder = Order
            end
        end

        function Dialog:AddFooterButton(ButtonIdx, ButtonInfo)
            Dialog:RemoveFooterButton(ButtonIdx)

            local WaitTime = ButtonInfo.WaitTime or 0

            local ButtonContainer = New("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.fromOffset(0, 26),
                LayoutOrder = ButtonInfo.Order or 0,
                ZIndex = 13002,
                Parent = ButtonsHolder,
            })

            local BtnColor = "MainColor"
            local BtnOutline = "OutlineColor"
            local Variant = ButtonInfo.Variant or "Primary"

            if Variant == "Primary" then
                BtnColor = "FontColor"
                BtnOutline = "FontColor"
            elseif Variant == "Secondary" then
                BtnColor = "MainColor"
                BtnOutline = "OutlineColor"
            elseif Variant == "Destructive" then
                BtnColor = "DestructiveColor"
                BtnOutline = "DestructiveColor"
            elseif Variant == "Ghost" then
                BtnColor = "BackgroundColor"
                BtnOutline = "BackgroundColor"
            end

            local TextBtn = New("TextButton", {
                BackgroundColor3 = BtnColor,
                BorderColor3 = BtnOutline,
                ClipsDescendants = true,
                Size = UDim2.fromOffset(0, 26),
                Text = "",
                AutoButtonColor = false,
                ZIndex = 13002,
                Parent = ButtonContainer,
            })
            Library:AddOutline(TextBtn)
            table.insert(
                Library.Corners,
                New("UICorner", {
                    CornerRadius = UDim.new(0, Library.CornerRadius),
                    Parent = TextBtn
                })
            )

            local TextColor = Library.Scheme.FontColor
            if Variant == "Primary" then
                TextColor = Library.Scheme.BackgroundColor
            elseif Variant == "Destructive" then
                TextColor = Color3.new(1, 1, 1)
            end

            local ActiveColor = typeof(BtnColor) == "Color3" and BtnColor or Library.Scheme[BtnColor]

            local ProgressBar
            if WaitTime > 0 then

                TextBtn.BackgroundColor3 = Library:GetDarkerColor(ActiveColor)

                ProgressBar = New("Frame", {
                    BackgroundColor3 = ActiveColor,
                    BorderSizePixel = 0,
                    Position = UDim2.fromScale(0, 0),
                    Size = UDim2.new(0, 0, 1, 0),
                    ZIndex = TextBtn.ZIndex,
                    Parent = TextBtn,
                })

                table.insert(
                    Library.Corners,
                    New("UICorner", {
                        CornerRadius = UDim.new(0, Library.CornerRadius),
                        Parent = ProgressBar,
                    })
                )
            end

            local BtnLabel = New("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                Text = ButtonInfo.Title or ButtonIdx,
                TextColor3 = TextColor,
                TextSize = 14,
                ZIndex = (ProgressBar and ProgressBar.ZIndex or TextBtn.ZIndex) + 1,
                Parent = TextBtn,
            })
            New("UIPadding", {
                PaddingLeft = UDim.new(0, 15),
                PaddingRight = UDim.new(0, 15),
                Parent = BtnLabel,
            })

            local LabelX, _ = Library:GetTextBounds(BtnLabel.Text, Library.Scheme.Font, 14, 250)
            ButtonContainer.Size = UDim2.fromOffset(LabelX + 30, 26)
            TextBtn.Size = UDim2.fromOffset(LabelX + 30, 26)

            local IsActive = WaitTime <= 0

            local ButtonWrap = {
                Container = ButtonContainer,
                SetDisabled = function(self, Disabled)
                    IsActive = not Disabled
                    if Disabled then
                        TweenService:Create(TextBtn, Library.TweenInfo, { BackgroundTransparency = 0.5 }):Play()
                        TweenService:Create(BtnLabel, Library.TweenInfo, { TextTransparency = 0.5 }):Play()
                    else
                        TweenService:Create(TextBtn, Library.TweenInfo, { BackgroundTransparency = 0 }):Play()
                        TweenService:Create(BtnLabel, Library.TweenInfo, { TextTransparency = 0 }):Play()
                    end
                end
            }

            local HoverColor = Variant == "Ghost" and Library.Scheme.MainColor or Library:GetBetterColor(ActiveColor, 10)

            TextBtn.MouseEnter:Connect(function()
                if not IsActive then return end
                TweenService:Create(TextBtn, Library.TweenInfo, {
                    BackgroundColor3 = HoverColor
                }):Play()
            end)
            TextBtn.MouseLeave:Connect(function()
                if not IsActive then return end
                TweenService:Create(TextBtn, Library.TweenInfo, {
                    BackgroundColor3 = ActiveColor
                }):Play()
            end)

            TextBtn.MouseButton1Click:Connect(function()
                if not IsActive then return end
                if ButtonInfo.Callback then
                    ButtonInfo.Callback(Dialog)
                end
                if Info.AutoDismiss then
                    Dialog:Dismiss()
                end
            end)

            if WaitTime > 0 then
                TweenService:Create(ProgressBar, TweenInfo.new(WaitTime, Enum.EasingStyle.Linear), {
                    Size = UDim2.new(1, 0, 1, 0)
                }):Play()

                task.delay(WaitTime, function()
                    ButtonWrap:SetDisabled(false)
                    if ProgressBar then

                        TextBtn.BackgroundColor3 = ActiveColor
                        TweenService:Create(ProgressBar, Library.TweenInfo, {
                            BackgroundTransparency = 1
                        }):Play()
                    end
                end)
            end

            FooterButtonsList[ButtonIdx] = ButtonWrap
        end

        for BIdx, BInfo in Info.FooterButtons do
            if type(BIdx) == "number" and BInfo.Id then BIdx = BInfo.Id end
            Dialog:AddFooterButton(BIdx, BInfo)
        end

        setmetatable(Dialog, BaseSection)
        Library.Dialogues[Idx] = Dialog

        Dialog:Resize()

        Library.ActiveDialog = Dialog
        return Dialog
    end

    function Window:Toggle(Value: boolean?)
        if Library.ActiveLoading then
            if Value == true then
                return
            end

            if not Library.Toggled then
                return
            end
        end

        if typeof(Value) == "boolean" then
            Library.Toggled = Value
        else
            Library.Toggled = not Library.Toggled
        end

        MainFrame.Visible = Library.Toggled

        if WindowInfo.UnlockMouseWhileOpen then
            ModalElement.Modal = Library.Toggled
        end

        if Library.Toggled and not Library.IsMobile then
            local OldMouseIconEnabled = UserInputService.MouseIconEnabled
            local ShowCursorBinding = Library.ShowCursorBinding

            pcall(function()
                RunService:UnbindFromRenderStep(ShowCursorBinding)
            end)
            RunService:BindToRenderStep(ShowCursorBinding, Enum.RenderPriority.Last.Value, function()
                UserInputService.MouseIconEnabled = not Library.ShowCustomCursor

                Cursor.Position = UDim2.fromOffset(Mouse.X, Mouse.Y)
                Cursor.Visible = Library.ShowCustomCursor

                if not (Library.Toggled and ScreenGui and ScreenGui.Parent) then
                    UserInputService.MouseIconEnabled = OldMouseIconEnabled
                    Cursor.Visible = false
                    RunService:UnbindFromRenderStep(ShowCursorBinding)
                end
            end)
        elseif not Library.Toggled then
            TooltipLabel.Visible = false

            for _, Option in Library.Options do
                if Option.Type == "ColorPicker" then
                    Option.ColorMenu:Close()
                    Option.ContextMenu:Close()
                elseif Option.Type == "Dropdown" or Option.Type == "KeyPicker" then
                    Option.Menu:Close()
                end
            end
        end
    end

    function Library:Toggle(Value: boolean?)
        return Window:Toggle(Value)
    end

    if WindowInfo.EnableSidebarResize then
        local MinWidth = 128
        local Threshold = (MinWidth + CompactWidth) * 0.5
        local StartPos, StartWidth
        local Dragging = false
        local Changed

        local SidebarGrabber = New("TextButton", {
            AnchorPoint = Vector2.new(0.5, 0),
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(Window:GetSidebarWidth(), 0),
            Size = UDim2.new(0, 8, 1, -21),
            Text = "",
            ZIndex = DividerLine.ZIndex + 1,
            Parent = MainFrame,
        })
        SidebarGrabberRef = SidebarGrabber
        SidebarGrabber.MouseEnter:Connect(function()
            TweenService:Create(DividerLine, Library.TweenInfo, {
                BackgroundColor3 = Library:GetLighterColor(Library.Scheme.OutlineColor),
            }):Play()
        end)
        SidebarGrabber.MouseLeave:Connect(function()
            if Dragging then
                return
            end
            TweenService:Create(DividerLine, Library.TweenInfo, {
                BackgroundColor3 = Library.Scheme.OutlineColor,
            }):Play()
        end)

        SidebarGrabber.InputBegan:Connect(function(Input: InputObject)
            if not IsClickInput(Input) then
                return
            end

            Library.CantDragForced = true

            StartPos = Input.Position
            StartWidth = Window:GetSidebarWidth()
            Dragging = true

            Changed = Input.Changed:Connect(function()
                if Input.UserInputState ~= Enum.UserInputState.End then
                    return
                end

                Library.CantDragForced = false
                TweenService:Create(DividerLine, Library.TweenInfo, {
                    BackgroundColor3 = Library.Scheme.OutlineColor,
                }):Play()

                Dragging = false
                if Changed and Changed.Connected then
                    Changed:Disconnect()
                    Changed = nil
                end
            end)
        end)

        Library:GiveSignal(UserInputService.InputChanged:Connect(function(Input: InputObject)
            if not Library.Toggled or not (ScreenGui and ScreenGui.Parent) then
                Dragging = false
                if Changed and Changed.Connected then
                    Changed:Disconnect()
                    Changed = nil
                end

                return
            end

            if Dragging and IsHoverInput(Input) then
                local Delta = Input.Position - StartPos
                local Width = StartWidth + Delta.X

                if Width > Threshold then
                    Window:SetSidebarWidth(math.max(Width, MinWidth))
                else
                    Window:SetSidebarWidth(CompactWidth)
                end
            end
        end))
    end
    if WindowInfo.SidebarCompacted then
        task.spawn(function()
            Window:SetSidebarWidth(CompactWidth)
        end)
    end
    if WindowInfo.AutoShow and not Library.ActiveLoading then
        task.spawn(Library.Toggle)
    end

    do

        local function CreateBubble()
            local BubbleSizeInfo = WindowInfo.BubbleSize
            local BaseWidth, BaseHeight = BubbleSizeInfo.X.Offset, BubbleSizeInfo.Y.Offset
            local BaseMargin = WindowInfo.BubbleMargin
            local Padding = WindowInfo.BubblePadding
            local StartSide = (WindowInfo.BubbleSide == "Left") and "Left" or "Right"

            -- Bubble carries its own UIScale (below), so Position/Size offsets
            -- here are logical/BASE space. Bubble.AbsolutePosition and
            -- ScreenGui.AbsoluteSize, used later for drag-snap clamping, are
            -- SCREEN space -- any math mixing the two must convert first.
            local Width, Height, Margin = BaseWidth, BaseHeight, BaseMargin

            local Bubble = New("TextButton", {
                AutoButtonColor = false,
                BackgroundColor3 = WindowInfo.BubbleColor or "MainColor",
                BorderSizePixel = 0,
                Text = "",
                Size = BubbleSizeInfo,
                Position = UDim2.new(
                    StartSide == "Right" and 1 or 0,
                    StartSide == "Right" and -(Margin + Width) or Margin,
                    0.5, -Height / 2
                ),
                ZIndex = 500,
                Parent = ScreenGui,
            })
            Library:AddToRegistry(Bubble, { BackgroundColor3 = WindowInfo.BubbleColor or "MainColor" })

            table.insert(
                Library.Corners,
                New("UICorner", {
                    CornerRadius = UDim.new(0, WindowInfo.BubbleCornerRadius),
                    Parent = Bubble,
                })
            )
            table.insert(Library.Scales, New("UIScale", { Parent = Bubble }))
            Library:AddOutline(Bubble)

            local IconSize = UDim2.fromOffset(
                math.max(Width - Padding * 2, 4),
                math.max(Height - Padding * 2, 4)
            )
            local CustomIcon = WindowInfo.BubbleIcon and Library:GetCustomIcon(WindowInfo.BubbleIcon)

            if CustomIcon then
                local BubbleIcon = New("ImageLabel", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundTransparency = 1,
                    Image = CustomIcon.Url,
                    ImageColor3 = WindowInfo.BubbleIconColor or "AccentColor",
                    ImageRectOffset = CustomIcon.ImageRectOffset,
                    ImageRectSize = CustomIcon.ImageRectSize,
                    Position = UDim2.fromScale(0.5, 0.5),
                    Size = IconSize,
                    ZIndex = 501,
                    Parent = Bubble,
                })
                Library:AddToRegistry(BubbleIcon, { ImageColor3 = WindowInfo.BubbleIconColor or "AccentColor" })
            else
                local BubbleLabel = New("TextLabel", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundTransparency = 1,
                    Position = UDim2.fromScale(0.5, 0.5),
                    Size = IconSize,
                    Text = WindowInfo.Title:sub(1, 1),
                    TextColor3 = WindowInfo.BubbleIconColor or "AccentColor",
                    TextScaled = true,
                    ZIndex = 501,
                    Parent = Bubble,
                })
                Library:AddToRegistry(BubbleLabel, { TextColor3 = WindowInfo.BubbleIconColor or "AccentColor" })
            end

            local SnapTweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

            local function SnapToSide(ToSide: string)
                local ScreenSize = ScreenGui.AbsoluteSize
                local ScaleFactor = math.max(Library.DPIScale or 1, 0.001)

                -- Bubble.AbsolutePosition/ScreenGui.AbsoluteSize are SCREEN
                -- space (post-UIScale). Margin/Height/Width and the TargetPos
                -- we tween to are logical/BASE space (pre-UIScale, since
                -- Bubble.Position is written as base-space offsets). Convert
                -- the measured Y back to base space before clamping/using it.
                local LogicalY = Bubble.AbsolutePosition.Y / ScaleFactor
                local LogicalScreenHeight = ScreenSize.Y / ScaleFactor

                local ClampedY =
                    math.clamp(LogicalY, Margin, math.max(Margin, LogicalScreenHeight - Height - Margin))

                local TargetPos
                if ToSide == "Right" then
                    TargetPos = UDim2.new(1, -(Margin + Width), 0, ClampedY)
                else
                    TargetPos = UDim2.new(0, Margin, 0, ClampedY)
                end

                TweenService:Create(Bubble, SnapTweenInfo, { Position = TargetPos }):Play()
            end

            local StartInputPos, StartPos
            local Dragging = false
            local Moved = false
            local Changed

            Bubble.InputBegan:Connect(function(Input: InputObject)
                if not IsClickInput(Input) then
                    return
                end

                StartInputPos = Input.Position
                StartPos = Bubble.Position
                Dragging = true
                Moved = false

                Changed = Input.Changed:Connect(function()
                    if Input.UserInputState ~= Enum.UserInputState.End then
                        return
                    end

                    Dragging = false
                    if Changed and Changed.Connected then
                        Changed:Disconnect()
                        Changed = nil
                    end

                    if Moved then
                        local ScreenSize = ScreenGui.AbsoluteSize
                        local CenterX = Bubble.AbsolutePosition.X + (Bubble.AbsoluteSize.X / 2)
                        SnapToSide(CenterX < (ScreenSize.X / 2) and "Left" or "Right")
                    else
                        Library:Toggle()
                    end
                end)
            end)

            Library:GiveSignal(UserInputService.InputChanged:Connect(function(Input: InputObject)
                if not (ScreenGui and ScreenGui.Parent) then
                    Dragging = false
                    if Changed and Changed.Connected then
                        Changed:Disconnect()
                        Changed = nil
                    end

                    return
                end

                if Dragging and IsHoverInput(Input) then
                    local Delta = Input.Position - StartInputPos

                    if not Moved and Delta.Magnitude > 5 then
                        Moved = true
                    end

                    Bubble.Position = UDim2.new(
                        StartPos.X.Scale, StartPos.X.Offset + Delta.X,
                        StartPos.Y.Scale, StartPos.Y.Offset + Delta.Y
                    )
                end
            end))

            Library.Bubble = Bubble
            return Bubble
        end

        function Library:ToggleBubble(Value: boolean?)
            if Value == nil then
                Value = not (Library.Bubble ~= nil and Library.Bubble.Visible)
            end

            if Value then
                if Library.Bubble then
                    Library.Bubble.Visible = true
                else
                    CreateBubble()
                end
            else
                if Library.Bubble then
                    Library.Bubble.Visible = false
                end
            end

            return Value
        end

        local BubbleEnabled = WindowInfo.Bubble
        if BubbleEnabled == nil then
            BubbleEnabled = Library.IsMobile
        end

        if BubbleEnabled then
            CreateBubble()
        end
    end

    do

        local SearchOverlay = New("Frame", {
            BackgroundColor3 = "MainColor",
            BorderSizePixel = 0,
            Size = UDim2.new(0, 300, 0, 400),
            Visible = false,
            ZIndex = 12000,
            Parent = ScreenGui,
        })
        Library:AddToRegistry(SearchOverlay, { BackgroundColor3 = "MainColor" })
        Library:NewTrackedScale(SearchOverlay)

        New("UICorner", {
            CornerRadius = UDim.new(0, WindowInfo.CornerRadius),
            Parent = SearchOverlay,
        })

        local OverlayStroke = New("UIStroke", {
            Color = "OutlineColor",
            Parent = SearchOverlay,
        })
        Library:AddToRegistry(OverlayStroke, { Color = "OutlineColor" })

        local ScrollFrame = New("ScrollingFrame", {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.fromScale(1, 1),
            CanvasSize = UDim2.fromScale(0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = "OutlineColor",
            ZIndex = 12001,
            Parent = SearchOverlay,
        })
        Library:AddToRegistry(ScrollFrame, { ScrollBarImageColor3 = "OutlineColor" })

        New("UICorner", {
            CornerRadius = UDim.new(0, WindowInfo.CornerRadius),
            Parent = ScrollFrame,
        })

        New("UIPadding", {
            PaddingTop    = UDim.new(0, 0),
            PaddingBottom = UDim.new(0, 6),
            PaddingLeft   = UDim.new(0, 6),
            PaddingRight  = UDim.new(0, 6),
            Parent = ScrollFrame,
        })

        New("UIListLayout", {
            Padding   = UDim.new(0, 0),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent    = ScrollFrame,
        })

        local CloseOverlay

        local function NavigateTo(Tab, Section, ElementInfo, TargetSubSection)
            if CloseOverlay then CloseOverlay() end
            SearchBox.Text = ""
            SearchBox:ReleaseFocus()

            if Tab and Tab.Show then
                Tab:Show()
            end

            if Section and Section.Show and not Section.BoxHolder then
                Section:Show()
            end

            task.spawn(function()
                task.wait()

                if Section and Section.SetFolded and Section.Folded then
                    Section:SetFolded(false)
                    task.wait()
                end

                local function UnfoldSubSections(Box)
                    if not Box or not Box.SubSections then return end
                    for _, SubSection in Box.SubSections do
                        if SubSection.SetFolded and SubSection.Folded then
                            SubSection:SetFolded(false)
                        end
                        UnfoldSubSections(SubSection)
                    end
                end
                if ElementInfo or TargetSubSection then
                    UnfoldSubSections(Section)
                    task.wait()
                end

                local ScrollTarget = (ElementInfo and ElementInfo.Holder)
                    or (TargetSubSection and (TargetSubSection.HeaderHolder or TargetSubSection.Holder))
                    or (Section and Section.BoxHolder)
                    or (Section and Section.Container)
                local IsPreciseTarget = (ElementInfo and ElementInfo.Holder) or (TargetSubSection and TargetSubSection.Holder)
                if ScrollTarget then
                    local Col = ScrollTarget.Parent

                    while Col and not Col:IsA("ScrollingFrame") do
                        Col = Col.Parent
                    end
                    if Col and Col:IsA("ScrollingFrame") then
                        local RelY = ScrollTarget.AbsolutePosition.Y - Col.AbsolutePosition.Y + Col.CanvasPosition.Y

                        local FullCenterOffset = Col.AbsoluteSize.Y / 2 - ScrollTarget.AbsoluteSize.Y / 2
                        local TargetOffset = IsPreciseTarget and math.min(FullCenterOffset, RelY) or 10
                        Col.CanvasPosition = Vector2.new(0, math.max(0, RelY - TargetOffset))
                    end
                end

                task.wait()
                task.wait()

                local function FlashTarget(TargetInst, ExpandX, ExpandY)
                    if not (TargetInst and TargetInst.Parent) then return end

                    local MainScaleFactor = math.max((Library.MainWindowScale and Library.MainWindowScale.Scale) or 1, 0.0001)

                    local AbsPos     = TargetInst.AbsolutePosition
                    local AbsSize    = TargetInst.AbsoluteSize
                    local MainAbsPos = MainFrame.AbsolutePosition
                    local RelX       = ((AbsPos.X - MainAbsPos.X) - ExpandX) / MainScaleFactor
                    local RelY       = ((AbsPos.Y - MainAbsPos.Y) - ExpandY) / MainScaleFactor
                    local SizeX      = (AbsSize.X + ExpandX * 2) / MainScaleFactor
                    local SizeY      = (AbsSize.Y + ExpandY * 2) / MainScaleFactor

                    local FlashOutline = New("Frame", {
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
                        Position = UDim2.fromOffset(RelX, RelY),
                        Size = UDim2.fromOffset(SizeX, SizeY),
                        ZIndex = 190,
                        Parent = MainFrame,
                    })
                    local FlashStroke = New("UIStroke", {
                        Color = Library.Scheme and Library.Scheme.AccentColor or Color3.fromRGB(100, 180, 255),
                        Thickness = 2,
                        Transparency = 0,
                        Parent = FlashOutline,
                    })
                    New("UICorner", {
                        CornerRadius = UDim.new(0, 4),
                        Parent = FlashOutline,
                    })

                    task.delay(0.8, function()
                        if FlashStroke and FlashStroke.Parent then
                            TweenService:Create(FlashStroke, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                                Transparency = 1,
                            }):Play()
                            task.delay(0.55, function()
                                if FlashOutline and FlashOutline.Parent then
                                    FlashOutline:Destroy()
                                end
                            end)
                        end
                    end)
                end

                if ElementInfo and ElementInfo.Holder and ElementInfo.Holder.Parent then
                    local IsButton   = ElementInfo.Type == "Button" or ElementInfo.Type == "SubButton"
                    local TargetInst = (IsButton and ElementInfo.Base) or ElementInfo.Holder

                    local ExpandX    = IsButton and 0 or 10
                    local ExpandY    = IsButton and 0 or 4
                    FlashTarget(TargetInst, ExpandX, ExpandY)
                elseif TargetSubSection and TargetSubSection.HeaderHolder and TargetSubSection.HeaderHolder.Parent then

                    FlashTarget(TargetSubSection.HeaderHolder, 0, 0)
                elseif TargetSubSection and TargetSubSection.Holder and TargetSubSection.Holder.Parent then
                    FlashTarget(TargetSubSection.Holder, 0, 0)
                elseif Section and Section.BoxHolder and Section.BoxHolder.Parent then
                    FlashTarget(Section.BoxHolder, 0, -8)
                elseif Section and Section.Container and Section.Container.Parent then
                    FlashTarget(Section.Container, 0, -8)
                end
            end)
        end

        local RowH   = 24
        local Indent = 16

        local function CollectElements(Box, Search, SectionMatches, Filtering, Out, Depth)
            Depth = Depth or 1

            for _, Info in Box.Elements do
                if Info.Type == "Divider" then continue end
                local EText = Info.Text
                if not EText or not Info.Visible then continue end

                if not Filtering or SectionMatches or EText:lower():match(Search) then
                    table.insert(Out, { Text = EText, Info = Info, ElType = Info.Type, Depth = Depth })
                end

                if Info.SubButton and Info.SubButton.Text and Info.SubButton.Visible then
                    local SubText = Info.SubButton.Text
                    if not Filtering or SectionMatches or SubText:lower():match(Search) then

                        table.insert(Out, { Text = SubText, Info = Info.SubButton, ElType = "SubButton", Depth = Depth })
                    end
                end
            end

            if Box.ConditionalGroups then
                for _, ConditionalGroup in Box.ConditionalGroups do
                    if not ConditionalGroup.Visible then
                        continue
                    end

                    CollectElements(ConditionalGroup, Search, SectionMatches, Filtering, Out, Depth)
                end
            end

            if Box.SubSections then

                for _, SubSection in Box.SubSections do
                    local SubMatches = SectionMatches or (Filtering and SubSection.Name and SubSection.Name:lower():match(Search))
                    local SubOut = {}
                    CollectElements(SubSection, Search, SubMatches, Filtering, SubOut, Depth + 1)

                    if SubMatches or #SubOut > 0 then
                        table.insert(Out, {
                            Text        = SubSection.Name or "SubSection",
                            IsSubSection = true,
                            SubSection  = SubSection,
                            Depth       = Depth,
                        })
                        for _, SubEntry in SubOut do
                            table.insert(Out, SubEntry)
                        end
                    end
                end
            end
        end

        local function MakeRow(Cfg, Order)
            local Depth = Cfg.Depth or 0
            local Z     = 12002

            local Btn = New("TextButton", {
                BackgroundColor3       = "MainColor",
                BackgroundTransparency = 1,
                BorderSizePixel        = 0,
                Size                   = UDim2.new(1, 0, 0, RowH),
                Text                   = "",
                LayoutOrder            = Order,
                ZIndex                 = Z,
                Parent                 = ScrollFrame,
            })
            Library:AddToRegistry(Btn, { BackgroundColor3 = "MainColor" })
            New("UICorner", { CornerRadius = UDim.new(0, 4), Parent = Btn })

            if Depth > 0 then
                for D = 1, Depth do
                    local LineX       = (D - 1) * Indent + 5
                    local IsDeepest   = (D == Depth)
                    local Terminating = IsDeepest and (Cfg.IsLast or false)

                    local VLine = New("Frame", {
                        BackgroundColor3 = "OutlineColor",
                        BorderSizePixel  = 0,
                        Position = UDim2.new(0, LineX, 0, 0),
                        Size     = UDim2.new(0, 1, 0, Terminating and RowH / 2 or RowH),
                        ZIndex   = Z + 1,
                        Parent   = Btn,
                    })
                    Library:AddToRegistry(VLine, { BackgroundColor3 = "OutlineColor" })

                    if IsDeepest then
                        local HLine = New("Frame", {
                            BackgroundColor3 = "OutlineColor",
                            BorderSizePixel  = 0,
                            Position = UDim2.new(0, LineX, 0, RowH / 2 - 1),
                            Size     = UDim2.new(0, Indent - 2, 0, 1),
                            ZIndex   = Z + 1,
                            Parent   = Btn,
                        })
                        Library:AddToRegistry(HLine, { BackgroundColor3 = "OutlineColor" })
                    end
                end
            end

            local TextX  = Depth * Indent + (Depth > 0 and 2 or 0)
            local BadgeW = 0

            local BadgeText, BadgeShadeStep
            local RowTextColorFn = nil

            if Cfg.IsTab then
                RowTextColorFn = function() return Library:GetAccentShade(1) end
            elseif Cfg.IsSection then
                RowTextColorFn = function() return Library:GetAccentShade(2) end
            elseif Cfg.IsSubSection then
                RowTextColorFn = function() return Library:GetAccentShade(1) end
            elseif Cfg.IsElement and Cfg.ElementType then
                local TypeLabels = {
                    Button = "BTN", Toggle = "TGL", Slider = "SLD",
                    Dropdown = "DROP", ColorPicker = "CLR", Input = "TXT",
                    Label = "LBL", KeyPicker = "KEY", SubButton = "SUB",
                    Checkbox = "CHK", ProgressBar = "PRG", Viewport = "VPT",
                    Image = "IMG", Video = "VID",
                }

                BadgeShadeStep = (Order % 2 == 0) and 2 or 1
                BadgeText = TypeLabels[Cfg.ElementType] or Cfg.ElementType:upper():sub(1, 4)
            end

            if BadgeText then
                BadgeW = 34

                local ShadeFn = function() return Library:GetAccentShade(BadgeShadeStep) end

                local Badge = New("Frame", {
                    BackgroundColor3       = ShadeFn,
                    BackgroundTransparency = 0,
                    BorderSizePixel        = 0,
                    Position = UDim2.new(1, -(BadgeW + 4), 0.5, -8),
                    Size     = UDim2.new(0, BadgeW, 0, 16),
                    ZIndex   = Z + 2,
                    Parent   = Btn,
                })
                New("UICorner", { CornerRadius = UDim.new(0, 3), Parent = Badge })
                New("TextLabel", {
                    BackgroundTransparency = 1,
                    Size           = UDim2.fromScale(1, 1),
                    Text           = BadgeText,
                    TextColor3     = Color3.new(1, 1, 1),
                    TextSize       = 9,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    Font           = Enum.Font.GothamBold,
                    ZIndex         = Z + 3,
                    Parent         = Badge,
                })
            end

            local LblFont
            if Cfg.IsTab then
                LblFont = Font.fromEnum(Enum.Font.GothamBold)
                LblFont = Font.new(LblFont.Family, Enum.FontWeight.Heavy, LblFont.Style)
            else
                LblFont = Font.fromEnum(Enum.Font.GothamMedium)
            end
            local LblTextSize = Cfg.IsTab and 13 or 12

            local Lbl = New("TextLabel", {
                BackgroundTransparency = 1,
                Position       = UDim2.new(0, TextX, 0, 0),
                Size           = UDim2.new(1, -(TextX + (BadgeW > 0 and BadgeW + 8 or 0)), 1, 0),
                Text           = Cfg.Text,
                TextColor3     = RowTextColorFn or "FontColor",
                TextSize       = LblTextSize,
                FontFace       = LblFont,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTransparency = Cfg.IsTab and 0 or (Cfg.IsElement and 0.35 or 0.1),
                TextTruncate   = Enum.TextTruncate.AtEnd,
                ZIndex         = Z + 1,
                Parent         = Btn,
            })

            Btn.MouseEnter:Connect(function()
                TweenService:Create(Btn, TweenInfo.new(0.08), { BackgroundTransparency = 0.82 }):Play()
            end)
            Btn.MouseLeave:Connect(function()
                TweenService:Create(Btn, TweenInfo.new(0.08), { BackgroundTransparency = 1 }):Play()
            end)

            if Cfg.OnActivate then
                Btn.MouseButton1Click:Connect(Cfg.OnActivate)
            end

            return Btn
        end

        local ActiveRows      = {}
        local BuildGeneration = 0

        local function ClearRows()
            for _, Row in ActiveRows do
                Row:Destroy()
            end
            table.clear(ActiveRows)
        end

        local function CloseOverlayImpl()
            SearchOverlay.Visible = false
            ClearRows()
        end
        CloseOverlay = CloseOverlayImpl

        local function RepositionOverlay()

            local ScaleFactor = math.max(Library.DPIScale or 1, 0.0001)

            local AbsPos  = SearchBox.AbsolutePosition
            local AbsSize = SearchBox.AbsoluteSize

            local Viewport   = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
            local MaxHeight  = math.max(Viewport.Y - (AbsPos.Y + AbsSize.Y + 4) - 12, 80)
            local WantHeight = math.min(400, MaxHeight)

            SearchOverlay.Size     = UDim2.fromOffset((AbsSize.X + 3) / ScaleFactor, WantHeight / ScaleFactor)
            SearchOverlay.Position = UDim2.fromOffset(AbsPos.X, AbsPos.Y + AbsSize.Y + 4)
        end

        Library:GiveDPIScaleCallback(function()
            if SearchOverlay.Visible then
                task.defer(RepositionOverlay)
            end
        end)

        local function RebuildOverlay(SearchText)
            BuildGeneration += 1
            local MyGen = BuildGeneration

            ClearRows()
            ScrollFrame.CanvasPosition = Vector2.zero

            local Search    = SearchText:lower():match("^%s*(.-)%s*$") or ""
            local Filtering = Search ~= ""

            local TabList  = {}
            local TabOrder = {}
            for I, BtnInfo in Library.TabButtons do
                if BtnInfo.Label then
                    local N = BtnInfo.Label.Text
                    if N and not TabOrder[N] then TabOrder[N] = I end
                end
            end
            for TabName, Tab in Library.Tabs do
                if typeof(Tab) == "table" and not Tab.IsKeyTab then
                    table.insert(TabList, { Name = TabName, Tab = Tab, Order = TabOrder[TabName] or 9999 })
                end
            end
            table.sort(TabList, function(A, B) return A.Order < B.Order end)

            if Library.ActiveTab then
                local ActiveEntry, RestEntries = nil, {}
                for _, TabEntry in TabList do
                    if TabEntry.Tab == Library.ActiveTab then
                        ActiveEntry = TabEntry
                    else
                        table.insert(RestEntries, TabEntry)
                    end
                end
                if ActiveEntry then
                    local Reordered = { ActiveEntry }
                    for _, TabEntry in RestEntries do
                        table.insert(Reordered, TabEntry)
                    end
                    TabList = Reordered
                end
            end

            local RowOrder = 0

            for _, TabEntry in TabList do
                if MyGen ~= BuildGeneration then return end

                local TabName    = TabEntry.Name
                local Tab        = TabEntry.Tab
                local TabMatches = {}

                local SortedSections = {}
                for SectionName, Section in Tab.Sections do
                    table.insert(SortedSections, { Name = SectionName, Section = Section })
                end

                table.sort(SortedSections, function(A, B)
                    return (A.Section.Order or 0) < (B.Section.Order or 0)
                end)

                for _, SectionEntry in SortedSections do
                    local SectionName = SectionEntry.Name
                    local Section     = SectionEntry.Section
                    local SectionMatches = not Filtering or SectionName:lower():match(Search)
                    local ElMatches = {}
                    CollectElements(Section, Search, SectionMatches, Filtering, ElMatches)
                    if SectionMatches or #ElMatches > 0 then
                        table.insert(TabMatches, { SectionName = SectionName, Section = Section, Elements = ElMatches, SectionMatch = SectionMatches })
                    end
                end

                if Tab.SectionGroups then
                    for _, SectionGroup in Tab.SectionGroups do

                        local SortedPages = {}
                        for PageName, Page in SectionGroup.Tabs do
                            table.insert(SortedPages, { Name = PageName, Page = Page })
                        end
                        table.sort(SortedPages, function(A, B)
                            return (A.Page.Order or 0) < (B.Page.Order or 0)
                        end)

                        for _, PageEntry in SortedPages do
                            local PageName = PageEntry.Name
                            local Page     = PageEntry.Page
                            local PageMatches = not Filtering or PageName:lower():match(Search)
                            local PageElMatches = {}
                            CollectElements(Page, Search, PageMatches, Filtering, PageElMatches)
                            if PageMatches or #PageElMatches > 0 then
                                table.insert(TabMatches, { SectionName = PageName, Section = Page, Elements = PageElMatches, SectionMatch = PageMatches })
                            end
                        end
                    end
                end

                if #TabMatches == 0 then continue end

                RowOrder += 1
                table.insert(ActiveRows, MakeRow({
                    Text       = TabName,
                    Depth      = 0,
                    IsTab      = true,
                    OnActivate = function() NavigateTo(Tab, nil, nil) end,
                }, RowOrder))

                for Si, SecEntry in TabMatches do
                    if MyGen ~= BuildGeneration then return end
                    local IsLastSec = Si == #TabMatches
                    local Section   = SecEntry.Section

                    RowOrder += 1
                    table.insert(ActiveRows, MakeRow({
                        Text         = SecEntry.SectionName,
                        Depth        = 1,
                        IsSection    = true,
                        SectionMatch = SecEntry.SectionMatch,
                        IsLast       = IsLastSec and #SecEntry.Elements == 0,
                        OnActivate   = function() NavigateTo(Tab, Section, nil) end,
                    }, RowOrder))

                    for Ei, ElEntry in SecEntry.Elements do
                        if MyGen ~= BuildGeneration then return end

                        local RowDepth = 1 + (ElEntry.Depth or 1)
                        local IsLastInGroup = Ei == #SecEntry.Elements

                        if ElEntry.IsSubSection then
                            local TargetSubSection = ElEntry.SubSection
                            RowOrder += 1
                            table.insert(ActiveRows, MakeRow({
                                Text         = ElEntry.Text,
                                Depth        = RowDepth,

                                IsSubSection = true,
                                SectionMatch = true,
                                IsLast       = IsLastInGroup,
                                OnActivate   = function() NavigateTo(Tab, Section, nil, TargetSubSection) end,
                            }, RowOrder))
                        else
                            local ElInfo = ElEntry.Info
                            RowOrder += 1
                            table.insert(ActiveRows, MakeRow({
                                Text        = ElEntry.Text,
                                Depth       = RowDepth,
                                IsElement   = true,
                                IsLast      = IsLastInGroup,
                                ElementType = ElEntry.ElType,
                                OnActivate  = function() NavigateTo(Tab, Section, ElInfo) end,
                            }, RowOrder))
                        end
                    end
                end
            end
        end

        local function OpenOverlay()
            RepositionOverlay()
            SearchOverlay.Visible = true
            task.spawn(RebuildOverlay, SearchBox.Text)
        end

        SearchBox.Focused:Connect(OpenOverlay)

        Library:GiveSignal(SearchBox:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
            if SearchOverlay.Visible then
                RepositionOverlay()
            end
        end))
        Library:GiveSignal(SearchBox:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
            if SearchOverlay.Visible then
                RepositionOverlay()
            end
        end))

        SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
            if SearchOverlay.Visible then
                task.spawn(RebuildOverlay, SearchBox.Text)
            end
        end)

        Library:GiveActiveTabChangedCallback(function()
            if SearchOverlay.Visible then
                task.spawn(RebuildOverlay, SearchBox.Text)
            end
        end)

        Library:GiveSignal(UserInputService.InputBegan:Connect(function(Input, _Processed)
            if not SearchOverlay.Visible then return end

            if Input.UserInputType == Enum.UserInputType.MouseButton1
                or Input.UserInputType == Enum.UserInputType.Touch then
                local MousePos = UserInputService:GetMouseLocation()
                local OvPos    = SearchOverlay.AbsolutePosition
                local OvSize   = SearchOverlay.AbsoluteSize
                local InOverlay = MousePos.X >= OvPos.X and MousePos.X <= OvPos.X + OvSize.X
                    and MousePos.Y >= OvPos.Y and MousePos.Y <= OvPos.Y + OvSize.Y
                local BxPos    = SearchBox.AbsolutePosition
                local BxSize   = SearchBox.AbsoluteSize
                local InBox    = MousePos.X >= BxPos.X and MousePos.X <= BxPos.X + BxSize.X
                    and MousePos.Y >= BxPos.Y and MousePos.Y <= BxPos.Y + BxSize.Y

                if InOverlay then

                elseif not InBox then
                    SearchBox:ReleaseFocus()
                    CloseOverlay()
                end
            end

            if Input.KeyCode == Enum.KeyCode.Escape then
                SearchBox.Text = ""
                SearchBox:ReleaseFocus()
                CloseOverlay()
            end
        end))
    end

    Library:GiveSignal(UserInputService.InputBegan:Connect(function(Input: InputObject)
        if Library.Unloaded then
            return
        end

        if UserInputService:GetFocusedTextBox() then
            return
        end

        if
            (
                typeof(Library.ToggleKeybind) == "table"
                and Library.ToggleKeybind.Type == "KeyPicker"
                and Input.KeyCode.Name == Library.ToggleKeybind.Value
            ) or Input.KeyCode == Library.ToggleKeybind
        then
            Library.Toggle()
        end
    end))

    Library:GiveSignal(UserInputService.WindowFocused:Connect(function()
        Library.IsRobloxFocused = true
    end))
    Library:GiveSignal(UserInputService.WindowFocusReleased:Connect(function()
        Library.IsRobloxFocused = false
    end))

    return Window
end

function Library:CreateLoading(LoadingInfo)
    if Library.ActiveLoading then
        warn("Loading GUI already exists, you cannot create multiple Loading GUIs.")
        return Library.ActiveLoading
    end

    LoadingInfo = Library:Validate(LoadingInfo, Templates.Loading)

    local ShouldWait = LoadingInfo.WaitForIconsOnLoad
    if ShouldWait == nil then
        ShouldWait = Library.WaitForIconsOnLoad
    end
    if ShouldWait ~= false then
        Library:WaitForIcons(10)
    end

    local Loading = {
        CurrentStep = LoadingInfo.CurrentStep,
        TotalSteps = LoadingInfo.TotalSteps,

        ShowSidebar = LoadingInfo.ShowSidebar,
        AutoResizeHeight = LoadingInfo.AutoResizeHeight,
        IsError = false,
        Destroyed = false,

        WindowWidth = LoadingInfo.WindowWidth,
        WindowHeight = LoadingInfo.WindowHeight,
        BaseWindowHeight = LoadingInfo.WindowHeight,
        WindowErrorHeight = LoadingInfo.WindowHeight,

        ContentWidth = LoadingInfo.ContentWidth,
        SidebarWidth = LoadingInfo.SidebarWidth,
    }

    local ScreenGui = New("ScreenGui", {
        Name = "AstralLoading",
        DisplayOrder = 999,
        ResetOnSpawn = false
    })
    ParentUI(ScreenGui)
    Loading.ScreenGui = ScreenGui

    ScreenGui.DescendantRemoving:Connect(function(Inst)
        Library:RemoveFromRegistry(Inst)
    end)

    local MainFrame = New("TextButton", {
        Name = "Main",
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = function()
            return Library:GetBetterColor(Library.Scheme.BackgroundColor, -1)
        end,
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(Loading.ShowSidebar and (Loading.ContentWidth + Loading.SidebarWidth) or Loading.WindowWidth, Loading.WindowHeight),
        ClipsDescendants = true,
        Text = "",
        AutoButtonColor = false,
        Parent = ScreenGui,
    })
    Library:AddOutline(MainFrame)
    table.insert(Library.Corners, New("UICorner", { CornerRadius = UDim.new(0, Library.CornerRadius), Parent = MainFrame }))

    local MobileOffset = Library.IsMobile and 0.2 or 0

    local InitialScale
    if LoadingInfo.DPIScale ~= nil then
        local DPIValue = math.clamp(tonumber(LoadingInfo.DPIScale) or 5, 1, 10)
        local ScaleFactor
        if DPIValue <= 5 then
            ScaleFactor = 0.40 + ((DPIValue - 1) / 4) * 0.60
        else
            ScaleFactor = 1.00 + ((DPIValue - 5) / 5) * 0.50
        end
        InitialScale = ScaleFactor - MobileOffset
    else
        InitialScale = (Library.IsMobile and 0.8 or 1)
    end

    local MainScale = New("UIScale", {
        Scale = InitialScale,
        Parent = MainFrame
    })
    table.insert(Library.Scales, MainScale)
    Library.ScalesOffset[MainScale] = MobileOffset

    local Container = New("Frame", {
        Name = "Content",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(0, Loading.ContentWidth, 1, 0),
        Parent = MainFrame,
    })

    local SideBar = New("Frame", {
        Name = "SideBar",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(Loading.ContentWidth, 0),
        Size = UDim2.new(0, Loading.ShowSidebar and Loading.SidebarWidth or 0, 1, 0),
        ClipsDescendants = true,
        Visible = Loading.ShowSidebar,
        Parent = MainFrame,
    })
    local SidebarCorner = New("UICorner", { CornerRadius = UDim.new(0, Library.CornerRadius), Parent = SideBar })
    table.insert(Library.Corners, SidebarCorner)

    Library:AddOutline(SideBar)

    local SidebarDivider = New("Frame", {
        BackgroundColor3 = "OutlineColor",
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(0, 1, 1, 0),
        Visible = Loading.ShowSidebar,
        Parent = SideBar,
    })

    local TopBar = New("Frame", {
        Name = "TopBar",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 48),
        ZIndex = 2,
        Parent = Container,
    })
    Library:MakeDraggable(MainFrame, TopBar, true, true)

    local TitleHolder = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Parent = TopBar,
    })
    New("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 6),
        Parent = TitleHolder,
    })
    New("UIPadding", {
        PaddingLeft = UDim.new(0, 12),
        Parent = TitleHolder,
    })

    if LoadingInfo.Icon then

        local IsBuiltInIcon = CustomImageManager.IsBuiltIn(LoadingInfo.Icon)
        local ResolvedIconId = IsBuiltInIcon and CustomImageManager.GetAsset(LoadingInfo.Icon) or LoadingInfo.Icon
        local Icon = Library:GetCustomIcon(ResolvedIconId)
        local _WindowIcon = New("ImageLabel", {
            Image = Icon.Url,
            ImageColor3 = IsBuiltInIcon and "AccentColor" or "WhiteColor",
            ImageRectOffset = Icon.ImageRectOffset,
            ImageRectSize = Icon.ImageRectSize,
            Size = LoadingInfo.IconSize,
            Parent = TitleHolder,
        })
        if IsBuiltInIcon then
            Library:AddToRegistry(_WindowIcon, { ImageColor3 = "AccentColor" })
        end
    else
        local _WindowIcon = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = LoadingInfo.IconSize,
            Text = LoadingInfo.Title:sub(1, 1),
            TextScaled = true,
            Visible = false,
            Parent = TitleHolder,
        })
    end

    local TitleX = Library:GetTextBounds(
        LoadingInfo.Title,
        Library.Scheme.Font,
        20,
        TitleHolder.AbsoluteSize.X - (LoadingInfo.Icon and (LoadingInfo.IconSize.X.Offset + 6) or 0) - 12
    )
    local _WindowTitle = New("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, TitleX, 1, 0),
        Text = LoadingInfo.Title,
        TextSize = 20,
        Parent = TitleHolder,
    })

    Library:MakeLine(Container, {
        Position = UDim2.fromOffset(0, 48),
        Size = UDim2.new(1, 0, 0, 1),
    })

    local InnerContent = New("Frame", {
        Name = "InnerContent",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 49),
        Size = UDim2.new(1, 0, 1, -49),
        Parent = Container,
    })

    New("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 12),
        Parent = InnerContent,
    })

    local IconHolder = New("Frame", {
        Name = "IconHolder",
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(64, 64),
        Parent = InnerContent,
    })

    local IsBuiltInLoadingIcon = CustomImageManager.IsBuiltIn(LoadingInfo.LoadingIcon)
    local ResolvedLoadingIconId = IsBuiltInLoadingIcon and CustomImageManager.GetAsset(LoadingInfo.LoadingIcon) or LoadingInfo.LoadingIcon
    local LoaderIcon = Library:GetCustomIcon(ResolvedLoadingIconId)
    local LoadingIcon = New("ImageLabel", {
        Name = "LoaderIcon",
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromScale(1, 1),
        Image = LoaderIcon.Url,
        ImageRectOffset = LoaderIcon.ImageRectOffset,
        ImageRectSize = LoaderIcon.ImageRectSize,
        ImageColor3 = LoadingInfo.LoadingIconColor or (IsBuiltInLoadingIcon and "AccentColor" or "WhiteColor"),
        Parent = IconHolder,
    })

    local RotationTween
    if LoadingInfo.LoadingIconTweenTime > 0 then
        RotationTween = TweenService:Create(
            LoadingIcon,
            TweenInfo.new(LoadingInfo.LoadingIconTweenTime, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1),
            { Rotation = 360 }
        )
        RotationTween:Play()
    end

    local MessageLabel = New("TextLabel", {
        BackgroundTransparency = 1,
        AutomaticSize = Loading.AutoResizeHeight and Enum.AutomaticSize.Y or Enum.AutomaticSize.XY,
        Size = Loading.AutoResizeHeight and UDim2.new(1, -60, 0, 0) or UDim2.fromOffset(0, 0),
        Text = "",
        TextSize = 18,
        TextWrapped = Loading.AutoResizeHeight,
        Parent = InnerContent,
    })

    local DescriptionLabel = New("TextLabel", {
        BackgroundTransparency = 1,
        AutomaticSize = Loading.AutoResizeHeight and Enum.AutomaticSize.Y or Enum.AutomaticSize.XY,
        Size = Loading.AutoResizeHeight and UDim2.new(1, -60, 0, 0) or UDim2.fromOffset(0, 0),
        Text = "",
        TextSize = 14,
        TextTransparency = 0.5,
        TextWrapped = Loading.AutoResizeHeight,
        Parent = InnerContent,
    })

    local SliderBar = New("Frame", {
        BackgroundColor3 = "MainColor",
        Size = UDim2.new(0.7, 0, 0, 15),
        Parent = InnerContent,
    })
    Library:AddOutline(SliderBar)
    table.insert(Library.Corners, New("UICorner", { CornerRadius = UDim.new(0, Library.CornerRadius / 2), Parent = SliderBar }))

    local SliderFill = New("Frame", {
        BackgroundColor3 = "AccentColor",
        BorderSizePixel = 0,
        Size = UDim2.fromScale(0, 1),
        Parent = SliderBar,
    })
    table.insert(Library.Corners, New("UICorner", { CornerRadius = UDim.new(0, Library.CornerRadius / 2), Parent = SliderFill }))

    local ProgressLabel = New("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Text = "",
        TextSize = 14,
        ZIndex = 2,
        Parent = SliderBar,
    })
    New("UIStroke", {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
        Color = "DarkColor",
        LineJoinMode = Enum.LineJoinMode.Miter,
        Parent = ProgressLabel,
    })

    local SidebarScrolling = New("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Size = UDim2.fromScale(1, 1),
        ScrollBarThickness = 0,
        Parent = SideBar,
    })
    local SidebarList = New("UIListLayout", {
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = SidebarScrolling,
    })
    New("UIPadding", {
        PaddingBottom = UDim.new(0, 12),
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
        PaddingTop = UDim.new(0, 12),
        Parent = SidebarScrolling,
    })

    local SidebarObject = {
        Elements = {},
        ConditionalGroups = {},
        SectionGroups = {},

        BoxHolder = SidebarScrolling,
        Container = SidebarScrolling,

        Resize = function(self)
            SidebarScrolling.CanvasSize = UDim2.fromOffset(0, SidebarList.AbsoluteContentSize.Y + 24)
        end,
        Tab = {
            Elements = {},
            ConditionalGroups = {},
            ConditionalSections = {},
            SectionGroups = {},
        },
    }

    SidebarList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        SidebarObject:Resize()
    end)

    setmetatable(SidebarObject, BaseSection)
    Loading.Sidebar = SidebarObject

    local ErrorFrame = New("Frame", {
        Name = "Error",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 49),
        Size = UDim2.new(1, 0, 1, -49),
        ClipsDescendants = true,
        Visible = false,
        Parent = Container,
    })

    local _ErrorTitle = New("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(15, 15),
        Size = UDim2.new(1, -30, 0, 18),
        Text = "Error",
        TextColor3 = "RedColor",
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = ErrorFrame,
    })

    local ErrorLabel = New("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(15, 39),
        Size = UDim2.new(1, -30, 1, -90),
        Text = "Error Message",
        TextSize = 14,
        TextTransparency = 0.2,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Parent = ErrorFrame,
    })

    local ErrorButtonsDivider = New("Frame", {
        BackgroundColor3 = "OutlineColor",
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 1, -48),
        Size = UDim2.new(1, -30, 0, 1),
        Visible = false,
        Parent = ErrorFrame,
    })

    local ErrorButtonsHolder = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 1),
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, 42),
        Visible = false,
        Parent = ErrorFrame,
    })
    New("UIListLayout", {
        Padding = UDim.new(0, 8),
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = ErrorButtonsHolder,
    })
    New("UIPadding", {
        PaddingTop = UDim.new(0, 5),
        PaddingBottom = UDim.new(0, 15),
        PaddingRight = UDim.new(0, 15),
        Parent = ErrorButtonsHolder,
    })

    function Loading:UpdateLayout()
        if Loading.IsError then
            Loading:RecalculateErrorHeight()
        end

        local ShowSidebar = Loading.ShowSidebar
        local FinalWidth = ShowSidebar and (Loading.ContentWidth + Loading.SidebarWidth) or Loading.WindowWidth
        local FinalHeight = Loading.IsError and Loading.WindowErrorHeight or Loading.WindowHeight

        if ShowSidebar then
            SideBar.Visible = true
            SidebarDivider.Visible = true
        end

        TweenService:Create(MainFrame, Library.TweenInfo, { Size = UDim2.fromOffset(FinalWidth, FinalHeight) }):Play()
        TweenService:Create(SideBar, Library.TweenInfo, { Position = UDim2.fromOffset(Loading.ContentWidth, 0), Size = UDim2.new(0, ShowSidebar and Loading.SidebarWidth or 0, 1, 0) }):Play()
        TweenService:Create(Container, Library.TweenInfo, { Size = UDim2.new(0, ShowSidebar and Loading.ContentWidth or Loading.WindowWidth, 1, 0) }):Play()

        if not ShowSidebar then
            task.delay(Library.TweenInfo.Time, function()
                if not Loading.ShowSidebar then
                    SideBar.Visible = false
                    SidebarDivider.Visible = false
                end
            end)
        end
    end

    function Loading:RecalculateLoadingHeight()
        if not Loading.AutoResizeHeight then
            return
        end

        local RequiredHeight =
              49
            + 48
            + InnerContent.UIListLayout.AbsoluteContentSize.Y

        Loading.WindowHeight = math.max(Loading.BaseWindowHeight, RequiredHeight)
    end

    function Loading:SetMessage(Text)
        MessageLabel.Text = Text

        if Loading.AutoResizeHeight then
            Loading:RecalculateLoadingHeight()
            Loading:UpdateLayout()
        end
    end

    function Loading:SetDescription(Text)
        DescriptionLabel.Text = Text

        if Loading.AutoResizeHeight then
            Loading:RecalculateLoadingHeight()
            Loading:UpdateLayout()
        end
    end

    function Loading:SetLoadingIcon(Icon)
        local IconData = Library:GetCustomIcon(Icon)
        LoadingIcon.Image = IconData.Url
        LoadingIcon.ImageRectOffset = IconData.ImageRectOffset
        LoadingIcon.ImageRectSize = IconData.ImageRectSize
    end

    function Loading:SetLoadingIconTweenTime(TweenTime)
        if RotationTween then
            RotationTween:Cancel()
            RotationTween:Destroy()
        end

        if TweenTime > 0 then
            RotationTween = TweenService:Create(
                LoadingIcon,
                TweenInfo.new(TweenTime, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1),
                { Rotation = 360 }
            )
            RotationTween:Play()
        else
            LoadingIcon.Rotation = 0
        end
    end

    function Loading:SetLoadingIconColor(Color)
        LoadingIcon.ImageColor3 = Color
    end

    function Loading:SetCurrentStep(Step)
        Loading.CurrentStep = math.clamp(Step, 0, Loading.TotalSteps)

        local Progress = Loading.CurrentStep / Loading.TotalSteps
        TweenService:Create(SliderFill, Library.TweenInfo, { Size = UDim2.fromScale(Progress, 1) }):Play()

        ProgressLabel.Text = string.format("%d/%d", Loading.CurrentStep, Loading.TotalSteps)
    end

    function Loading:SetTotalSteps(Steps)
        Loading.TotalSteps = Steps
        Loading:SetCurrentStep(Loading.CurrentStep)
    end

    function Loading:SetWindowHeight(Height)
        Loading.WindowHeight = Height
        Loading:UpdateLayout()
    end

    function Loading:SetWindowWidth(Width)
        Loading.WindowWidth = Width
        Loading:UpdateLayout()
    end

    function Loading:SetContentWidth(Width)
        Loading.ContentWidth = Width
        Loading:UpdateLayout()
    end

    function Loading:SetSidebarWidth(Width)
        Loading.SidebarWidth = Width
        Loading:UpdateLayout()
    end

    function Loading:ShowSidebarPage(Bool)
        Loading.ShowSidebar = Bool
        Loading:UpdateLayout()
    end

    function Loading:ShowErrorPage(Enabled)
        Loading.IsError = Enabled
        InnerContent.Visible = not Enabled
        ErrorFrame.Visible = Enabled

        if Loading.ShowSidebar then
            Loading:ShowSidebarPage(not Enabled)
        else
            Loading:UpdateLayout()
        end
    end

    function Loading:RecalculateErrorHeight()
        local TargetWidth = (Loading.ShowSidebar and Loading.ContentWidth or Loading.WindowWidth) - 30
        local _, ErrorY = Library:GetTextBounds(ErrorLabel.Text, Library.Scheme.Font, 14, TargetWidth)

        ErrorLabel.Size = UDim2.new(1, -30, 0, ErrorY)

        local HasButtons = ErrorButtonsHolder.Visible
        local RequiredHeight =
              49
            + 15
            + 18
            + 6
            + ErrorY
            + 15
            + (HasButtons and 48 or 0)

        Loading.WindowErrorHeight = RequiredHeight
    end

    function Loading:SetErrorMessage(Text)
        ErrorLabel.Text = Text
        Loading:UpdateLayout()
    end

    function Loading:SetErrorButtons(Buttons)
        assert(typeof(Buttons) == "table", "Buttons must be a table")

        for _, button in ErrorButtonsHolder:GetChildren() do
            if button:IsA("Frame") then
                button:Destroy()
            end
        end

        local HasButtons = GetTableSize(Buttons) > 0
        ErrorButtonsHolder.Visible = HasButtons
        ErrorButtonsDivider.Visible = HasButtons

        for Idx, ButtonInfo in Buttons do
            local ButtonContainer = New("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.fromOffset(0, 26),
                Parent = ErrorButtonsHolder,
            })

            local BtnColor = "MainColor"
            local BtnOutline = "OutlineColor"
            local Variant = ButtonInfo.Variant or "Primary"

            if Variant == "Primary" then
                BtnColor = "FontColor"
                BtnOutline = "FontColor"
            elseif Variant == "Secondary" then
                BtnColor = "MainColor"
                BtnOutline = "OutlineColor"
            elseif Variant == "Destructive" then
                BtnColor = "DestructiveColor"
                BtnOutline = "DestructiveColor"
            elseif Variant == "Ghost" then
                BtnColor = "BackgroundColor"
                BtnOutline = "BackgroundColor"
            end

            local TextBtn = New("TextButton", {
                BackgroundColor3 = BtnColor,
                BorderColor3 = BtnOutline,
                Size = UDim2.fromOffset(0, 26),
                Text = "",
                AutoButtonColor = false,
                Parent = ButtonContainer,
            })
            Library:AddOutline(TextBtn)
            table.insert(
                Library.Corners,
                New("UICorner", {
                    CornerRadius = UDim.new(0, Library.CornerRadius),
                    Parent = TextBtn
                })
            )

            New("UIPadding", {
                PaddingLeft = UDim.new(0, 15),
                PaddingRight = UDim.new(0, 15),
                Parent = TextBtn,
            })

            local TextColor = Library.Scheme.FontColor
            if Variant == "Primary" then
                TextColor = Library.Scheme.BackgroundColor
            elseif Variant == "Destructive" then
                TextColor = Color3.new(1, 1, 1)
            end

            local BtnLabel = New("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                Text = ButtonInfo.Title or Idx,
                TextColor3 = TextColor,
                TextSize = 14,
                Parent = TextBtn,
            })

            local LabelX, _ = Library:GetTextBounds(BtnLabel.Text, Library.Scheme.Font, 14, 250)
            ButtonContainer.Size = UDim2.fromOffset(LabelX + 30, 26)
            TextBtn.Size = UDim2.fromOffset(LabelX + 30, 26)

            local ActiveColor = typeof(BtnColor) == "Color3" and BtnColor or Library.Scheme[BtnColor]
            local HoverColor = Variant == "Ghost" and Library.Scheme.MainColor or Library:GetBetterColor(ActiveColor, 10)

            TextBtn.MouseEnter:Connect(function()
                TweenService:Create(TextBtn, Library.TweenInfo, {
                    BackgroundColor3 = HoverColor
                }):Play()
            end)
            TextBtn.MouseLeave:Connect(function()
                TweenService:Create(TextBtn, Library.TweenInfo, {
                    BackgroundColor3 = ActiveColor
                }):Play()
            end)

            TextBtn.MouseButton1Click:Connect(function()
                if ButtonInfo.Callback then
                    ButtonInfo.Callback(Loading)
                end
            end)
        end

        Loading:UpdateLayout()
    end

    function Loading:Destroy()
        if RotationTween then
            RotationTween:Cancel()
        end

        ScreenGui:Destroy()
        Loading.Destroyed = true
        Library.ActiveLoading = nil

        if Library.Toggle and Library.Toggled == false and Library.Unloaded ~= true then
            Library:Toggle(true)
        end
    end

    Loading.Continue = Loading.Destroy;

    if Library.Toggle and Library.Toggled and Library.Unloaded ~= true then
        Library:Toggle(false)
    end

    Loading:SetCurrentStep(Loading.CurrentStep)

    Library.ActiveLoading = Loading
    return Loading
end

local function OnPlayerChange()
    if Library.Unloaded then
        return
    end

    local PlayerList, ExcludedPlayerList = GetPlayers(), GetPlayers(true)
    for _, Dropdown in Options do
        if Dropdown.Type == "Dropdown" and Dropdown.SpecialType == "Player" then
            Dropdown:SetValues(Dropdown.ExcludeLocalPlayer and ExcludedPlayerList or PlayerList)
        end
    end
end

local function OnTeamChange()
    if Library.Unloaded then
        return
    end

    local TeamList = GetTeams()
    for _, Dropdown in Options do
        if Dropdown.Type == "Dropdown" and Dropdown.SpecialType == "Team" then
            Dropdown:SetValues(TeamList)
        end
    end
end

Library:GiveSignal(Players.PlayerAdded:Connect(OnPlayerChange))
Library:GiveSignal(Players.PlayerRemoving:Connect(OnPlayerChange))

Library:GiveSignal(Teams.ChildAdded:Connect(OnTeamChange))
Library:GiveSignal(Teams.ChildRemoved:Connect(OnTeamChange))

getgenv().Library = Library

return Library