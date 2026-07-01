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

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local Mouse = cloneref(LocalPlayer:GetMouse())

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

    -- Returns true only for the hardcoded library assets (AstralIcon, LoadingIcon, etc.).
    -- User-added assets via AddAsset are NOT built-in and should not be tinted AccentColor.
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
            -- If the file is missing, attempt to download it now before calling
            -- getcustomasset so we don't silently use a bad/missing file.
            if isfile and not isfile(AssetData.Path) then
                local Ok = CustomImageManager.DownloadAsset(AssetName)
                -- If download still failed, return the Roblox ID fallback without
                -- caching, so the next call will retry the download.
                if not Ok or not isfile(AssetData.Path) then
                    return AssetID
                end
            end

            local Success, NewID = pcall(getcustomasset, AssetData.Path)

            if Success and NewID and NewID ~= "" then
                AssetID = NewID
                -- Only cache when getcustomasset actually succeeded with a real ID.
                AssetData.Id = AssetID
            end
            -- If getcustomasset failed we intentionally do NOT set AssetData.Id,
            -- so the next call to GetAsset will try again.
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
            -- Validate the existing file is not a blank or error-page artifact
            -- from a previous failed download. If it looks bad, delete and retry.
            local ExistingOk = false
            pcall(function()
                local Content = readfile(AssetData.Path)
                -- A valid image file starts with a known binary magic byte sequence.
                -- PNG: \x89PNG  |  JPEG: \xFF\xD8  |  WebP: RIFF...WEBP
                -- Any HTML/text error page will not match these.
                local Sig = Content:sub(1, 4)
                ExistingOk = (Sig:sub(1,1) == "\x89" and Sig:sub(2,4) == "PNG")  -- PNG
                    or (Sig:sub(1,2) == "\xFF\xD8")                               -- JPEG
                    or (Sig:sub(1,4) == "RIFF")                                   -- WebP/RIFF
                    or (Sig:sub(1,3) == "GIF")                                    -- GIF
            end)
            if ExistingOk then
                return true, nil
            end
            -- Bad cached file — delete it and re-download below.
            pcall(delfile, AssetData.Path)
            AssetData.Id = nil
        end

        -- Clear the cached Id so that GetAsset re-resolves via getcustomasset
        -- after a forced re-download rather than returning the stale cached value.
        AssetData.Id = nil

        local Content = nil
        local DownloadSuccess, DownloadError = pcall(function()
            Content = game:HttpGet(AssetData.URL)
        end)

        if not DownloadSuccess or not Content or Content == "" then
            return false, DownloadError or "empty response"
        end

        -- Reject obvious HTML/text error pages before writing to disk.
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

        -- Verify the file actually landed on disk; some executors silently no-op writefile.
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

    SearchText = "",
    Searching = false,
    LastSearchTab = nil,

    ActiveTab = nil,
    Tabs = {},
    TabButtons = {},
    ConditionalGroups = {},

    KeybindFrame = nil,
    KeybindContainer = nil,
    KeybindToggles = {},

    Notifications = {},
    Dialogues = {},
    ActiveLoading = nil,
    ActiveDialog = nil,

    Corners = {},

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

    CantDragForced = false,

    Signals = {},
    UnloadSignals = {},

    OriginalMinSize = Vector2.new(480, 360),
    MinSize = Vector2.new(480, 360),
    DPIScale = 1,
    CornerRadius = 6,
    CornerRadiusDropdown = false, -- Temporary

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
    --// UI \\-
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

    --// Library \\--
    Window = {
        Title = "No Title",
        Footer = "No Footer",
        Position = UDim2.fromOffset(6, 6),
        Size = UDim2.fromOffset(720, 600),
        IconSize = UDim2.fromOffset(30, 30),
        AutoShow = true,
        Center = true,
        Resizable = true,
        SearchbarSize = UDim2.fromScale(1, 1),
        CornerRadius = 6,
        NotifySide = "Right",
        ShowCustomCursor = false,
        Font = Enum.Font.GothamMedium,
        ToggleKeybind = Enum.KeyCode.RightControl,

        -- Floating draggable toggle bubble (chat-head style). Shows/hides the
        -- window on tap and magnets to the nearest screen edge when dragged.
        Bubble = nil,                        -- default: nil (auto -- shown only on mobile). true/false forces it on any platform.
        BubbleSide = "Right",                -- default: "Right" -- starting side, and the side it magnets back to. "Left" or "Right".
        BubbleIcon = "menu",                 -- default: "menu" -- Lucide icon name or custom asset id. nil falls back to the window title's first letter.
        BubbleIconColor = nil,               -- default: nil -- Color3. nil uses Scheme.AccentColor.
        BubbleColor = nil,                   -- default: nil -- Color3. nil uses Scheme.MainColor.
        BubbleSize = UDim2.fromOffset(50, 50),  -- default: UDim2.fromOffset(50, 50)
        BubbleCornerRadius = 25,             -- default: 25 -- half of BubbleSize for a full circle; lower for rounded-square bubbles.
        BubblePadding = 12,                  -- default: 12 -- inset between the bubble edge and its icon/letter.
        BubbleMargin = 8,                    -- default: 8 -- distance kept from the screen edges when snapped.

        UnlockMouseWhileOpen = true,

        EnableSidebarResize = false,
        SidebarCompacted = false,
        CompactSidebarTooltips = true,

        -- Discord button at the bottom of the sidebar.
        -- Set DiscordLink to a discord.gg URL to enable.
        -- DiscordAction = "open"      -> tries Discord local RPC, falls back to clipboard
        -- DiscordAction = "clipboard" -> copies directly to clipboard without attempting to open
        DiscordLink = nil,
        DiscordAction = "open",

        --// Instance Management \\--
        SingleInstance = true,
    },
    Dialog = {
        Title = "Dialog",
        Description = "Description",
        AutoDismiss = true,
        OutsideClickDismiss = true,
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
        EditableStyle = "Pencil", -- "Pencil" or "ValueBox"

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

    --// Addons \\-
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

--// Scheme Functions \\--
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

--// Basic Functions \\--
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
        Connection:Disconnect()
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
        return math.floor(Value)
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

local function CheckConditionalGroup(Box, Search)
    local VisibleElements = 0

    for _, ElementInfo in Box.Elements do
        if ElementInfo.Type == "Divider" then
            ElementInfo.Holder.Visible = false
            continue
        elseif ElementInfo.SubButton then
            --// Check if any of the Buttons Name matches with Search
            local Visible = false

            --// Check if Search matches Element's Name and if Element is Visible
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

        --// Check if Search matches Element's Name and if Element is Visible
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
end

local function ApplySearchToTab(Tab, Search)
    if not Tab then
        return
    end

    local HasVisible = false

    --// Loop through Sections to get Elements Info
    for _, Section in Tab.Sections do
        local VisibleElements = 0

        for _, ElementInfo in Section.Elements do
            if ElementInfo.Type == "Divider" then
                ElementInfo.Holder.Visible = false
                continue
            elseif ElementInfo.SubButton then
                --// Check if any of the Buttons Name matches with Search
                local Visible = false

                --// Check if Search matches Element's Name and if Element is Visible
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

            --// Check if Search matches Element's Name and if Element is Visible
            if ElementInfo.Text and ElementInfo.Text:lower():match(Search) and ElementInfo.Visible then
                ElementInfo.Holder.Visible = true
                VisibleElements += 1
            else
                ElementInfo.Holder.Visible = false
            end
        end

        for _, ConditionalGroup in Section.ConditionalGroups do
            if not ConditionalGroup.Visible then
                continue
            end

            VisibleElements += CheckConditionalGroup(ConditionalGroup, Search)
        end

        --// Update Section Size and Visibility if found any element
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
            VisibleElements[SubTab] = 0

            for _, ElementInfo in SubTab.Elements do
                if ElementInfo.Type == "Divider" then
                    ElementInfo.Holder.Visible = false
                    continue
                elseif ElementInfo.SubButton then
                    --// Check if any of the Buttons Name matches with Search
                    local Visible = false

                    --// Check if Search matches Element's Name and if Element is Visible
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
                        VisibleElements[SubTab] += 1
                    end

                    continue
                end

                --// Check if Search matches Element's Name and if Element is Visible
                if ElementInfo.Text and ElementInfo.Text:lower():match(Search) and ElementInfo.Visible then
                    ElementInfo.Holder.Visible = true
                    VisibleElements[SubTab] += 1
                else
                    ElementInfo.Holder.Visible = false
                end
            end

            for _, ConditionalGroup in SubTab.ConditionalGroups do
                if not ConditionalGroup.Visible then
                    continue
                end

                VisibleElements[SubTab] += CheckConditionalGroup(ConditionalGroup, Search)
            end
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

        --// Update SectionGroup Visibility if any visible
        SectionGroup.BoxHolder.Visible = VisibleTabs > 0
    end

    return HasVisible
end
local function ResetTab(Tab)
    if not Tab then
        return
    end

    for _, Section in Tab.Sections do
        for _, ElementInfo in Section.Elements do
            ElementInfo.Holder.Visible = typeof(ElementInfo.Visible) == "boolean" and ElementInfo.Visible or true

            if ElementInfo.SubButton then
                ElementInfo.Base.Visible = ElementInfo.Visible
                ElementInfo.SubButton.Base.Visible = ElementInfo.SubButton.Visible
            end
        end

        for _, ConditionalGroup in Section.ConditionalGroups do
            if not ConditionalGroup.Visible then
                continue
            end

            RestoreConditionalGroup(ConditionalGroup)
        end

        Section:Resize()
        Section.BoxHolder.Visible = true
    end

    for _, SectionGroup in Tab.SectionGroups do
        for _, SubTab in SectionGroup.Tabs do
            for _, ElementInfo in SubTab.Elements do
                ElementInfo.Holder.Visible = typeof(ElementInfo.Visible) == "boolean" and ElementInfo.Visible or true

                if ElementInfo.SubButton then
                    ElementInfo.Base.Visible = ElementInfo.Visible
                    ElementInfo.SubButton.Base.Visible = ElementInfo.SubButton.Visible
                end
            end

            for _, ConditionalGroup in SubTab.ConditionalGroups do
                if not ConditionalGroup.Visible then
                    continue
                end

                RestoreConditionalGroup(ConditionalGroup)
            end

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

function Library:AddToRegistry(Instance, Properties)
    Library.Registry[Instance] = Properties
end

function Library:RemoveFromRegistry(Instance)
    Library.Registry[Instance] = nil
end

function Library:UpdateColorsUsingRegistry()
    for Instance, Properties in Library.Registry do
        for Property, Index in Properties do
            local SchemeValue = GetSchemeValue(Index)

            if SchemeValue or typeof(Index) == "function" then
                Instance[Property] = SchemeValue or Index()
            end
        end
    end
end

function Library:SetDPIScale(DPIScale: number)
    Library.DPIScale = DPIScale / 100
    Library.MinSize = Library.OriginalMinSize * Library.DPIScale

	for _, UIScale in Library.Scales do
        UIScale.Scale = Library.DPIScale - (tonumber(Library.ScalesOffset[UIScale]) or 0)
    end

    for _, Option in Options do
        if Option.Type == "Dropdown" then
            Option:RecalculateListSize()
        end
    end

    for _, Notification in Library.Notifications do
        Notification:Resize()
    end
end

function Library:GiveSignal(Connection: RBXScriptConnection | RBXScriptSignal)
    local ConnectionType = typeof(Connection)
    if Connection and (ConnectionType == "RBXScriptConnection" or ConnectionType == "RBXScriptSignal") then
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

-- Mirrors for the Lucide icon-registry source module. Tried in order; the
-- first one that returns non-empty content wins. Add/re-order URLs here if
-- a mirror goes down.
local LUCIDE_SOURCE_MIRRORS = {
    "https://raw.githubusercontent.com/deividcomsono/lucide-roblox-direct/refs/heads/main/source.lua",
    "https://cdn.jsdelivr.net/gh/deividcomsono/lucide-roblox-direct@main/source.lua",
}

local LUCIDE_CACHE_FILE = "astral-lucide-source.lua"

-- Some executors expose different names for the HTTP function (or omit
-- game:HttpGet entirely). Try every method available in this environment
-- and fall through to the next one on failure instead of hard-erroring.
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

-- Some executors implement getcustomasset() but it silently returns an empty
-- string instead of a valid content id (no error thrown, so the module's own
-- broken-detection via pcall doesn't catch it). Worse, reassigning
-- getcustomasset = nil in this scope does NOT propagate into the loadstring'd
-- chunk on this executor (each loadstring gets its own fresh environment), so
-- we patch the fetched SOURCE TEXT directly: force both spritesheet entries to
-- always use the static rbxassetid:// fallback instead of calling
-- getcustomasset() at all. This is the only Url source confirmed to render.
--
-- IMPORTANT: this is done GENERICALLY (matching the surrounding code shape,
-- not a specific hardcoded asset id) because the upstream repo periodically
-- re-uploads the spritesheets, which changes the fallback rbxassetid on every
-- update. A patch pinned to an exact id silently stops matching (no error,
-- gsub just does nothing) the moment that happens, which is what was making
-- icons quietly stop loading.
local function PatchLucideSource(SourceCode: string): (string, number)
    return SourceCode:gsub(
        'if%s+getcustomasset%s+and%s+not%s+IS_GETCUSTOMASSET_BROKEN%s+then%s+getcustomasset%("lucide%-icons/%d%.png"%)%s+else%s+("rbxassetid://%d+")',
        "%1"
    )
end

local FetchIcons, Icons = pcall(function()
    local SourceCode, UsedCache = nil, false

    for _, Url in LUCIDE_SOURCE_MIRRORS do
        local Success, Result = HttpGetAny(Url)
        if Success then
            SourceCode = Result
            break
        end
    end

    -- Every mirror + every HTTP method failed (offline, firewalled, etc).
    -- Fall back to whatever we last managed to fetch successfully, if this
    -- executor supports persistent file IO.
    if not SourceCode and isfile and readfile then
        local Success, Cached = pcall(function()
            if isfile(LUCIDE_CACHE_FILE) then
                return readfile(LUCIDE_CACHE_FILE)
            end
            return nil
        end)
        if Success and typeof(Cached) == "string" and #Cached > 0 then
            SourceCode = Cached
            UsedCache = true
        end
    end

    if not SourceCode then
        return nil
    end

    local PatchedSource = PatchLucideSource(SourceCode)

    -- Cache the freshly-fetched (unpatched) source so a future session can
    -- still load icons even if every mirror is unreachable at that time.
    if not UsedCache and writefile then
        pcall(writefile, LUCIDE_CACHE_FILE, SourceCode)
    end

    local CompileSuccess, Compiled = pcall(loadstring, PatchedSource)
    if not CompileSuccess or typeof(Compiled) ~= "function" then
        return nil
    end

    local RunSuccess, Module = pcall(Compiled)
    if not RunSuccess then
        return nil
    end

    return Module :: IconModule
end)

if FetchIcons and not Icons then
    FetchIcons = false
end

function Library:GetIcon(IconName: string)
    if not FetchIcons then
        return
    end

    local Success, Icon = pcall(Icons.GetAsset, IconName)
    if not Success or not Icon then
        return
    end

    if typeof(Icon.Url) ~= "string" or Icon.Url == "" then
        return
    end

    return Icon
end

function Library:GetCustomIcon(IconName: string): any
    if not IconName then
        return nil
    end

    if tonumber(IconName) then
        IconName = string.format("rbxassetid://%s", tostring(IconName))
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

--// Creator Functions \\--
local function FillInstance(Table: { [string]: any }, Instance: GuiObject)
    local ThemeProperties = Library.Registry[Instance] or {}

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

        Instance[key] = value
    end

    if GetTableSize(ThemeProperties) > 0 then
        Library.Registry[Instance] = ThemeProperties
    end
end

local function New(ClassName: string, Properties: { [string]: any }): any
    local Instance = Instance.new(ClassName)

    if Templates[ClassName] then
        FillInstance(Templates[ClassName], Instance)
    end
    FillInstance(Properties, Instance)

    if Properties["Parent"] and not Properties["ZIndex"] then
        pcall(function()
            Instance.ZIndex = Properties.Parent.ZIndex
        end)
    end

    return Instance
end

--// Main Instances \\-
local function SafeParentUI(Instance: Instance, Parent: Instance | () -> Instance)
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

        Instance.Parent = DestinationParent
    end)

    if not (success and Instance.Parent) then
        Instance.Parent = Library.LocalPlayer:WaitForChild("PlayerGui", math.huge)
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

-- Legacy fallback: unload any old "Astral"-named ScreenGui from before per-title naming was introduced
do
    local GuiParent = gethui()
    local ExistingGui = GuiParent:FindFirstChild("Astral")
    if ExistingGui then
        -- If the previous Library instance is still alive in getgenv, unload it cleanly
        if getgenv().Library and typeof(getgenv().Library.Unload) == "function" and not getgenv().Library.Unloaded then
            pcall(getgenv().Library.Unload, getgenv().Library)
        else
            -- Fallback: just destroy the stale ScreenGui directly
            pcall(function() ExistingGui:Destroy() end)
        end
    end
end

local ScreenGui = New("ScreenGui", {
    Name = "Astral",
    DisplayOrder = 998,
    ResetOnSpawn = false,
})
ParentUI(ScreenGui)
Library.ScreenGui = ScreenGui

ScreenGui.DescendantRemoving:Connect(function(Instance)
    Library:RemoveFromRegistry(Instance)
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

--// Cursor
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

--// Notification
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

--// Lib Functions \\--
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
    DragFrame.InputBegan:Connect(function(Input: InputObject)
        if not IsClickInput(Input) or IsMainWindow and Library.CantDragForced then
            return
        end

        StartPos = Input.Position
        FramePos = UI.Position
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
        if
            (not IgnoreToggled and not Library.Toggled)
            or (IsMainWindow and Library.CantDragForced)
            or not (ScreenGui and ScreenGui.Parent)
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

--// Deprecated \\--
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

function Library:AddDraggableLabel(Text: string)
    local Table = {}

    local Label = New("TextLabel", {
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundColor3 = "BackgroundColor",
        Size = UDim2.fromOffset(0, 0),
        Position = UDim2.fromOffset(6, 6),
        Text = Text,
        TextSize = 15,
        ZIndex = 10,
        Parent = ScreenGui,
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
    table.insert(
        Library.Scales,
        New("UIScale", {
            Parent = Label,
        })
    )
    Library:AddOutline(Label)

    Library:MakeDraggable(Label, Label, true)

    Table.Label = Label

    function Table:SetText(Text: string)
        Label.Text = Text
    end

    function Table:SetVisible(Visible: boolean)
        Label.Visible = Visible
    end

    return Table
end

function Library:AddDraggableButton(Text: string, Func, ExcludeScaling: boolean?)
    local Table = {}

    local Button = New("TextButton", {
        BackgroundColor3 = "BackgroundColor",
        Position = UDim2.fromOffset(6, 6),
        TextSize = 16,
        ZIndex = 10,
        Parent = ScreenGui,
    })
    table.insert(
        Library.Corners, 
        New("UICorner", {
            CornerRadius = UDim.new(0, Library.CornerRadius),
            Parent = Button,
        })
    )
    if not ExcludeScaling then
        table.insert(
            Library.Scales,
            New("UIScale", {
                Parent = Button,
            })
        )
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

    return Table
end

function Library:AddDraggableMenu(Name: string)
    local Holder = New("Frame", {
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundColor3 = "BackgroundColor",
        Position = UDim2.fromOffset(6, 6),
        Size = UDim2.fromOffset(0, 0),
        ZIndex = 10,
        Parent = ScreenGui,
    })
    table.insert(
        Library.Corners,
        New("UICorner", {
            CornerRadius = UDim.new(0, Library.CornerRadius),
            Parent = Holder,
        })
    )
    table.insert(
        Library.Scales,
        New("UIScale", {
            Parent = Holder,
        })
    )
    Library:AddOutline(Holder)

    Library:MakeLine(Holder, {
        Position = UDim2.fromOffset(0, 34),
        Size = UDim2.new(1, 0, 0, 1),
    })

    local Label = New("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 34),
        Text = Name,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Holder,
    })
    New("UIPadding", {
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
        Parent = Label,
    })

    local Container = New("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 35),
        Size = UDim2.new(1, 0, 1, -35),
        Parent = Holder,
    })
    New("UIListLayout", {
        Padding = UDim.new(0, 7),
        Parent = Container,
    })
    New("UIPadding", {
        PaddingBottom = UDim.new(0, 7),
        PaddingLeft = UDim.new(0, 7),
        PaddingRight = UDim.new(0, 7),
        PaddingTop = UDim.new(0, 7),
        Parent = Container,
    })

    Library:MakeDraggable(Holder, Label, true)
    return Holder, Container
end


--// Context Menu \\--
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
    if ParentGui ~= ScreenGui and (Library.ActiveLoading and ParentGui ~= Library.ActiveLoading.ScreenGui) then
        ParentGui = ScreenGui
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
            ZIndex = 10,
            Parent = ParentGui,
        })
    else
        Menu = New("Frame", {
            BackgroundColor3 = "BackgroundColor",
            Size = typeof(Size) == "function" and Size() or Size,
            Visible = false,
            ZIndex = 10,
            Parent = ParentGui,
        })
    end
    table.insert(
        Library.Scales,
        New("UIScale", {
            Parent = Menu,
        })
    )

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

--// Tooltip \\--
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

    table.insert(Tooltips, TooltipLabel)
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

function Library:SetIconModule(module: IconModule)
    FetchIcons = true
    Icons = module

    -- Top ten fixes 🚀
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
            Value = Info.Default, -- Key
            Modifiers = Info.DefaultModifiers, -- Modifiers
            DisplayValue = Info.Default, -- Picker Text

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

        -- Special Keys
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

        -- Modifiers
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

        local Picker = New("TextButton", {
            BackgroundColor3 = "MainColor",
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
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 16),
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

            KeyPicker.DoClick = function(...) end --// make luau lsp shut up
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

                KeybindsToggle:SetText(("[%s] %s (%s)"):format(KeyPicker.DisplayValue, ParentObj.Text or KeyPicker.Text, KeyPicker.Mode))
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
            local Key, Mode, Modifiers = Data[1], Data[2], Data[3]

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

            -- Wait for an non modifier key --
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

                -- Wait for any input --
                Picker.Text = "..."
                Picker.Size = UDim2.fromOffset(29, 18)

                if GetInput() then
                    Picking = false
                    KeyPicker:Update()
                    return
                end

                -- Escape --
                if Input.KeyCode == Enum.KeyCode.Escape then
                    break
                end

                -- Handle modifier keys --
                if IsModifierInput(Input) then
                    local StopLoop = false

                    repeat
                        task.wait()
                        if UserInputService:IsKeyDown(Input.KeyCode) then
                            task.wait(0.075)

                            if UserInputService:IsKeyDown(Input.KeyCode) then
                                -- Add modifier to the key list --
                                if not table.find(ActiveModifiers, ModifiersInput[Input.KeyCode]) then
                                    ActiveModifiers[#ActiveModifiers + 1] = ModifiersInput[Input.KeyCode]
                                    KeyPicker:Display(table.concat(ActiveModifiers, " + ") .. " + ...")
                                end

                                -- Wait for another input --
                                if GetInput() then
                                    StopLoop = true
                                    break -- Invalid Input
                                end

                                -- Escape --
                                if Input.KeyCode == Enum.KeyCode.Escape then
                                    break
                                end

                                -- Stop loop if its a normal key --
                                if not IsModifierInput(Input) then
                                    break
                                end
                            else
                                if not table.find(ActiveModifiers, ModifiersInput[Input.KeyCode]) then
                                    break -- Modifier is meant to be used as a normal key --
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

                break -- Input found, end loop
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

            -- RunService.RenderStepped:Wait()
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

        if ParentObj.Addons then
            table.insert(ParentObj.Addons, KeyPicker)
        end

        KeyPicker.Default = KeyPicker.Value
        KeyPicker.DefaultModifiers = table.clone(KeyPicker.Modifiers or {})

        Options[Idx] = KeyPicker

        return self
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

        local Holder = New("TextButton", {
            BackgroundColor3 = ColorPicker.Value,
            Size = UDim2.fromOffset(18, 18),
            Text = "",
            Parent = ToggleLabel,
        })

        local HolderStroke = New("UIStroke", {
            Color = Library:GetDarkerColor(ColorPicker.Value),
            Parent = Holder,
        })

        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                Parent = Holder,
            })
        )

        local HolderTransparency = New("ImageLabel", {
            Image = CustomImageManager.GetAsset("TransparencyTexture"),
            ImageTransparency = (1 - ColorPicker.Transparency),
            ScaleType = Enum.ScaleType.Tile,
            Position = UDim2.new(0, -1, 0, -1),
            Size = UDim2.new(1, 2, 1, 2),
            TileSize = UDim2.fromOffset(9, 9),
            Parent = Holder,
        })

        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                Parent = HolderTransparency,
            })
        )

        --// Inline Color Panel \\--
        -- Inserted directly into the section container, below the parent element row.
        -- Toggled open/closed by clicking the swatch; section resizes automatically.
        local ColorPanelOpen = false

        -- Walk up to find the section that owns this addon's parent element
        local function FindOwnerSection()
            if ParentObj.Tab then
                for _, S in ParentObj.Tab.Sections do
                    return S
                end
            end
            return nil
        end

        local InlineParent = ParentObj.Container
        local InlinePanel = New("Frame", {
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = "MainColor",
            Size = UDim2.new(1, 0, 0, 0),
            Visible = false,
            Parent = InlineParent,
        })
        table.insert(Library.Corners, New("UICorner", {
            CornerRadius = UDim.new(0, Library.CornerRadius / 2),
            Parent = InlinePanel,
        }))
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

        -- Fake ColorMenu table so existing code (ColorMenu.Toggle / :Close) still works
        local ColorMenu = {
            Active = false,
            Menu = InlinePanel,
            List = New("UIListLayout", { Parent = Instance.new("Frame") }), -- unused dummy
        }
        ColorPicker.ColorMenu = ColorMenu

        local function ResizeOwner()
            local S = FindOwnerSection()
            if S then S:Resize() end
        end

        local function OpenColorPanel()
            ColorPanelOpen = true
            ColorMenu.Active = true
            InlinePanel.Visible = true
            ResizeOwner()
        end
        local function CloseColorPanel()
            ColorPanelOpen = false
            ColorMenu.Active = false
            InlinePanel.Visible = false
            ResizeOwner()
        end
        function ColorMenu:Toggle()
            if ColorPanelOpen then CloseColorPanel() else OpenColorPanel() end
        end
        function ColorMenu:Close() CloseColorPanel() end
        function ColorMenu:Open()  OpenColorPanel()  end

        if typeof(ColorPicker.Title) == "string" then
            New("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 14),
                Text = ColorPicker.Title,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = InlinePanel,
            })
        end

        local ColorHolder = New("Frame", {
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

        --// Sat Map
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

        -- If the SaturationMap asset was not yet resolved to a custom asset path
        -- (e.g. still downloading), poll in the background and update once ready.
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

        --// Hue
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

        --// Alpha
        local TransparencySelector, TransparencyColor, TransparencyCursor
        if Info.Transparency then
            TransparencySelector = New("ImageButton", {
                Image = CustomImageManager.GetAsset("TransparencyTexture"),
                ScaleType = Enum.ScaleType.Tile,
                Size = UDim2.fromOffset(16, 200),
                TileSize = UDim2.fromOffset(8, 8),
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
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 20),
            Parent = ColorMenu.Menu,
        })
        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalFlex = Enum.UIFlexAlignment.Fill,
            Padding = UDim.new(0, 8),
            Parent = InfoHolder,
        })

        local HueBox = New("TextBox", {
            BackgroundColor3 = "MainColor",
            ClearTextOnFocus = false,
            Size = UDim2.fromScale(1, 1),
            Text = "#??????",
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
            BackgroundColor3 = "MainColor",
            ClearTextOnFocus = false,
            Size = UDim2.fromScale(1, 1),
            Text = "?, ?, ?",
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

        --// Context Menu \\--
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

            ColorPicker.SetValueRGB = function(...) end --// make luau lsp shut up
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

        --// End \\--
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
            HolderTransparency.ImageTransparency = (1 - ColorPicker.Transparency)

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

        if ParentObj.Addons then
            table.insert(ParentObj.Addons, ColorPicker)
        end

        ColorPicker.Default = ColorPicker.Value

        Options[Idx] = ColorPicker

        return self
    end

    BaseAddons.__index = Funcs
    BaseAddons.__namecall = function(_, Key, ...)
        return Funcs[Key](...)
    end
end

local BaseSection = {}
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

        -- Add extra 6px above every divider so elements above it breathe
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
            Label.Text = Text
            TextLabel.Text = Text

            if Label.DoesWrap then
                local _, Y =
                    Library:GetTextBounds(Label.Text, TextLabel.FontFace, TextLabel.TextSize, TextLabel.AbsoluteSize.X)
                TextLabel.Size = UDim2.new(1, 0, 0, Y + 4)
            end

            Section:Resize()
        end

        if Label.DoesWrap then
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

                    local Clicked = WaitForEvent(Button.Base.MouseButton1Click, 0.5)

                    Button.Base.Text = Button.Text
                    Button.Base.TextColor3 = Button.Risky and Library.Scheme.RedColor or Library.Scheme.FontColor
                    Library.Registry[Button.Base].TextColor3 = Button.Risky and "RedColor" or "FontColor"

                    if Clicked then
                        Library:SafeCallback(Button.Func)
                    end

                    RunService.RenderStepped:Wait() --// Mouse Button fires without waiting (i hate roblox)
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

    function Funcs:AddCheckbox(Idx, Info)
        Info = Library:Validate(Info, Templates.Toggle)

        local Section = self
        local Container = Section.Container

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

            Variant = "Checkbox",
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
            Position = UDim2.fromOffset(26, 0),
            Size = UDim2.new(1, -26, 1, 0),
            Text = Toggle.Text,
            TextSize = 14,
            TextTransparency = 0.4,
            TextTruncate = Enum.TextTruncate.AtEnd,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = Button,
        })

        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            Padding = UDim.new(0, 6),
            Parent = Label,
        })

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

        function Toggle:UpdateColors()
            Toggle:Display()
        end

        function Toggle:Display()
            if Library.Unloaded then
                return
            end

            CheckboxStroke.Transparency = Toggle.Disabled and 0.5 or 0

            if Toggle.Disabled then
                Label.TextTransparency = 0.8
                CheckImage.ImageTransparency = Toggle.Value and 0.8 or 1

                Checkbox.BackgroundColor3 = Library.Scheme.BackgroundColor
                Library.Registry[Checkbox].BackgroundColor3 = "BackgroundColor"

                return
            end

            TweenService:Create(Label, Library.TweenInfo, {
                TextTransparency = Toggle.Value and 0 or 0.4,
            }):Play()
            TweenService:Create(CheckImage, Library.TweenInfo, {
                ImageTransparency = Toggle.Value and 0 or 1,
            }):Play()

            Checkbox.BackgroundColor3 = Library.Scheme.MainColor
            Library.Registry[Checkbox].BackgroundColor3 = "MainColor"
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

        Toggle:Display()
        Section:Resize()

        Toggle.TextLabel = Label
        Toggle.Container = Container
        setmetatable(Toggle, BaseAddons)

        Toggle.Holder = Button
        table.insert(Section.Elements, Toggle)

        Toggle.Default = Toggle.Value

        Toggles[Idx] = Toggle

        return Toggle
    end

    function Funcs:AddToggle(Idx, Info)
        if Library.ForceCheckbox then
            return Funcs.AddCheckbox(self, Idx, Info)
        end

        Info = Library:Validate(Info, Templates.Toggle)

        local Section = self
        local Container = Section.Container

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

            Variant = "Switch",
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
            Size = UDim2.new(1, -40, 1, 0),
            Text = Toggle.Text,
            TextSize = 14,
            TextTransparency = 0.4,
            TextTruncate = Enum.TextTruncate.AtEnd,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = Button,
        })

        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            Padding = UDim.new(0, 6),
            Parent = Label,
        })

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

        function Toggle:UpdateColors()
            Toggle:Display()
        end

        function Toggle:Display()
            if Library.Unloaded then
                return
            end

            local Offset = Toggle.Value and 1 or 0

            Switch.BackgroundTransparency = Toggle.Disabled and 0.75 or 0
            SwitchStroke.Transparency = Toggle.Disabled and 0.75 or 0

            Switch.BackgroundColor3 = Toggle.Value and Library.Scheme.AccentColor or Library.Scheme.MainColor
            SwitchStroke.Color = Toggle.Value and Library.Scheme.AccentColor or Library.Scheme.OutlineColor

            Library.Registry[Switch].BackgroundColor3 = Toggle.Value and "AccentColor" or "MainColor"
            Library.Registry[SwitchStroke].Color = Toggle.Value and "AccentColor" or "OutlineColor"

            if Toggle.Disabled then
                Label.TextTransparency = 0.8
                Ball.AnchorPoint = Vector2.new(Offset, 0)
                Ball.Position = UDim2.fromScale(Offset, 0)

                Ball.BackgroundColor3 = Library:GetDarkerColor(Library.Scheme.FontColor)
                Library.Registry[Ball].BackgroundColor3 = function()
                    return Library:GetDarkerColor(Library.Scheme.FontColor)
                end

                return
            end

            TweenService:Create(Label, Library.TweenInfo, {
                TextTransparency = Toggle.Value and 0 or 0.4,
            }):Play()
            TweenService:Create(Ball, Library.TweenInfo, {
                AnchorPoint = Vector2.new(Offset, 0),
                Position = UDim2.fromScale(Offset, 0),
            }):Play()

            Ball.BackgroundColor3 = Library.Scheme.FontColor
            Library.Registry[Ball].BackgroundColor3 = "FontColor"
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

        Toggle:Display()
        Section:Resize()

        Toggle.TextLabel = Label
        Toggle.Container = Container
        setmetatable(Toggle, BaseAddons)

        Toggle.Holder = Button
        table.insert(Section.Elements, Toggle)

        Toggle.Default = Toggle.Value

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
            PaddingBottom = UDim.new(0, 3),
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
        local VerticalGap = IsValueBoxStyle and 6 or 4

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, Info.Compact and 15 or (14 + VerticalGap + 15)),
            Visible = Slider.Visible,
            Parent = Container,
        })

        local SliderLabel
        local InlineValueBox -- only for EditableStyle = "ValueBox"
        if not Info.Compact then
            local LabelWidth = (Slider.Editable and Slider.EditableStyle == "ValueBox")
                and UDim2.new(1, -64, 0, 14)  -- 56px box + 8px gap
                or  UDim2.new(1, 0, 0, 14)

            SliderLabel = New("TextLabel", {
                BackgroundTransparency = 1,
                Size = LabelWidth,
                Text = Slider.Text,
                TextSize = 14,
                TextTruncate = Enum.TextTruncate.AtEnd,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = Holder,
            })

            -- ValueBox style: small always-visible input aligned with the label
            if Slider.Editable and Slider.EditableStyle == "ValueBox" then
                InlineValueBox = New("TextBox", {
                    AnchorPoint = Vector2.new(1, 0),
                    BackgroundColor3 = "MainColor",
                    ClearTextOnFocus = true,
                    Position = UDim2.fromScale(1, 0),
                    Size = UDim2.fromOffset(56, 14),
                    Text = tostring(Slider.Value),
                    TextSize = 12,
                    TextEditable = not Slider.Disabled,
                    ZIndex = 3,
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
            ZIndex = 2,
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
            Parent = Bar,
        })

        local EditButton, ValueBox
        if Slider.Editable and Slider.EditableStyle ~= "ValueBox" then
            -- Pencil style: icon on the right of the bar, click to reveal overlay textbox
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
                ZIndex = 3,
                Parent = Bar,
            })
            Library:AddToRegistry(EditButton, { ImageColor3 = "FontColor" })

            ValueBox = New("TextBox", {
                BackgroundColor3 = "MainColor",
                ClearTextOnFocus = true,
                Size = UDim2.fromScale(1, 1),
                Text = "",
                TextSize = 14,
                TextEditable = not Slider.Disabled,
                Visible = false,
                ZIndex = 4,
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
                        "%s%s%s/%s%s%s",
                        Slider.Prefix,
                        Slider.Value,
                        Slider.Suffix,
                        Slider.Prefix,
                        Slider.Max,
                        Slider.Suffix
                    )
                end
            end

            local X = (Slider.Value - Slider.Min) / (Slider.Max - Slider.Min)
            Fill.Size = UDim2.fromScale(X, 1)

            -- Keep the inline value box in sync (ValueBox style)
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

            while IsDragInput(Input) do
                local Location = Mouse.X
                local Scale = math.clamp((Location - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)

                local OldValue = Slider.Value
                Slider.Value = Round(Slider.Min + ((Slider.Max - Slider.Min) * Scale), Slider.Rounding)

                Slider:Display()
                if Slider.Value ~= OldValue then
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

        -- ValueBox style: commit on Enter, revert on blur
        if InlineValueBox then
            InlineValueBox.FocusLost:Connect(function(Enter)
                if Enter then
                    Slider:SetValue(InlineValueBox.Text)
                end
                -- Always resync to the real value (revert if not committed or clamped)
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
            ZIndex = 3,
            Parent = Holder,
        })

        local DisplayContainer = New("TextButton", {
            BackgroundColor3 = "MainColor",
            Size = UDim2.new(1, 0, 0, 21),
            Text = "",
            TextTransparency = 1,
            ZIndex = 2,
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
            ZIndex = 2,
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
            ZIndex = 2,
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

        local SearchBox
        local SearchBar  -- the container row above InlineList
        local ActionBar  -- unused, kept as nil so SetDropdownOpen guard still compiles
        local Buttons = {}  -- forward-declared so All/Clear callbacks capture the right table
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

            -- Use UIListLayout so the search input and action buttons are evenly spaced
            New("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Left,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Padding = UDim.new(0, 0),
                Parent = SearchBar,
            })
            New("UIPadding", {
                PaddingLeft = UDim.new(0, 8),
                PaddingRight = UDim.new(0, 4),
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
                -- Thin vertical divider separating search from buttons
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

                -- "All" then "Clear" laid out by UIListLayout
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

        -- Inline list panel (replaces the floating AddContextMenu overlay)
        local InlineList = New("ScrollingFrame", {
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = "MainColor",
            CanvasSize = UDim2.fromScale(0, 0),
            ScrollBarImageColor3 = "OutlineColor",
            ScrollBarThickness = 2,
            BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
            TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
            Size = UDim2.new(1, 0, 0, 0),
            Visible = false,
            Parent = Holder,
        })
        New("UIStroke", { Color = "OutlineColor", Parent = InlineList })
        if Library.CornerRadiusDropdown == true then
            table.insert(Library.Corners, New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                Parent = InlineList,
            }))
        end
        local InlineListLayout = New("UIListLayout", { Parent = InlineList })

        local DropdownOpen = false

        -- Fake MenuTable so existing code that references Dropdown.Menu still works
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
            -- Clamp visible height; canvas auto-grows
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
                Button.Parent:Destroy()
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
                -- No UICorner: selected highlight should be flat/square
                -- For multi-select use alternating light/dark accent tints
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
                    PaddingLeft = UDim.new(0, 7),
                    PaddingRight = UDim.new(0, 7),
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

        function Dropdown:SetValues(Values)
            Dropdown.Values = Values
            Dropdown:BuildDropdownList()
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

        local Viewport = {
            Object = ViewportObject,
            Camera = if not Info.Camera then Instance.new("Camera") else Info.Camera,
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
            local CameraDistance = MaxExtent * 2
            local ModelPosition = Viewport.Object:GetPivot().Position

            Viewport.Camera.CFrame =
                CFrame.new(ModelPosition + Vector3.new(0, MaxExtent / 2, CameraDistance), ModelPosition)
        end

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, Info.Height),
            Visible = Viewport.Visible,
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
            PaddingBottom = UDim.new(0, 3),
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
            PaddingTop = UDim.new(0, 4),
            Parent = Box,
        })

        local ViewportFrame = New("ViewportFrame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Parent = Box,
            CurrentCamera = Viewport.Camera,
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
                local Camera = Viewport.Camera

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
                Viewport.Camera.CFrame += Viewport.Camera.CFrame.LookVector * ZoomAmount
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
                Viewport.Camera.CFrame += Viewport.Camera.CFrame.LookVector * delta
            elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
                Pinching = false
            end
        end))

        Viewport.Object.Parent = ViewportFrame
        if Viewport.AutoFocus then
            FocusCamera()
        end

        function Viewport:SetObject(Object: Instance, Clone: boolean?)
            assert(Object, "Object cannot be nil.")

            if Clone then
                Object = Object:Clone()
            end

            if Viewport.Object then
                Viewport.Object:Destroy()
            end

            Viewport.Object = Object
            Viewport.Object.Parent = ViewportFrame

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
            PaddingBottom = UDim.new(0, 3),
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
            PaddingBottom = UDim.new(0, 3),
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
            Size = UDim2.new(1, 0, 0, Info.Height),
            Visible = Passthrough.Visible,
            Parent = Container,
        })

        Passthrough.Instance.Parent = Holder

        Section:Resize()

        function Passthrough:SetHeight(Height: number)
            assert(typeof(Height) == "number" and Height > 0, "Height must be a number greater than 0.")

            Passthrough.Height = Height
            Holder.Size = UDim2.new(1, 0, 0, Height)
            Section:Resize()
        end

        function Passthrough:SetInstance(Instance: Instance)
            assert(Instance, "Instance must be provided.")
            assert(
                typeof(Instance) == "Instance" and Instance:IsA("GuiBase2d"),
                "Instance must inherit from GuiBase2d."
            )

            if Passthrough.Instance then
                Passthrough.Instance.Parent = nil
            end

            Passthrough.Instance = Instance
            Passthrough.Instance.Parent = Holder
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
                PaddingBottom = UDim.new(0, 7),
                PaddingLeft = UDim.new(0, 7),
                PaddingRight = UDim.new(0, 7),
                PaddingTop = UDim.new(0, 7),
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
        }

        function ConditionalSection:Resize()
            ConditionalSectionContainer.Size = UDim2.new(1, 0, 0, (ConditionalSectionList.AbsoluteContentSize.Y / Library.DPIScale) + 18)
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

            DeleteConnection:Disconnect()
            DeleteConnection = nil
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

        if DeleteConnection then
            DeleteConnection:Disconnect()
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

        New("Sound", {
            SoundId = SoundId,
            Volume = 3,
            PlayOnRemove = true,
            Parent = SoundService,
        }):Destroy()
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
    WindowInfo = Library:Validate(WindowInfo, Templates.Window)

    -- SingleInstance: unload any existing UI with the same title before creating this one
    if WindowInfo.SingleInstance ~= false then
        local GuiParent = gethui()
        local GuiName = "Astral_" .. tostring(WindowInfo.Title)
        for _, Child in GuiParent:GetChildren() do
            if Child:IsA("ScreenGui") and Child.Name == GuiName then
                -- Try to cleanly unload via the stored Library reference in getgenv
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

    local MaxX = ViewportSize.X - 64
    local MaxY = ViewportSize.Y - 64

    Library.OriginalMinSize =
        Vector2.new(math.min(Library.OriginalMinSize.X, MaxX), math.min(Library.OriginalMinSize.Y, MaxY))
    Library.MinSize = Library.OriginalMinSize

    WindowInfo.Size = UDim2.fromOffset(
        math.clamp(WindowInfo.Size.X.Offset, Library.MinSize.X, MaxX),
        math.clamp(WindowInfo.Size.Y.Offset, Library.MinSize.Y, MaxY)
    )
    if typeof(WindowInfo.Font) == "EnumItem" then
        WindowInfo.Font = Font.fromEnum(WindowInfo.Font)
    end
    WindowInfo.CornerRadius = math.min(WindowInfo.CornerRadius, 20)

    -- Backwards compat: old "Compact" key
    if WindowInfo.Compact ~= nil then
        WindowInfo.SidebarCompacted = WindowInfo.Compact
    end

    Library.CornerRadius = WindowInfo.CornerRadius
    Library:SetNotifySide(WindowInfo.NotifySide)

    -- Rename the ScreenGui to a title-based name so SingleInstance can find it next run
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

    local InitialLeftWidth = math.ceil(WindowInfo.Size.X.Offset * 0.22)
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

        if WindowInfo.Center then
            MainFrame.Position = UDim2.new(0.5, -MainFrame.Size.X.Offset / 2, 0.5, -MainFrame.Size.Y.Offset / 2)
        end

        --// Top Bar \\-
        local TopBar = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 48),
            Parent = MainFrame,
        })
        Library:MakeDraggable(MainFrame, TopBar, false, true)

        --// Title
        TitleHolder = New("Frame", {
            BackgroundTransparency = 1,
            ClipsDescendants = true,
            Size = UDim2.new(0, InitialLeftWidth, 1, 0),
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

        local X = Library:GetTextBounds(
            WindowInfo.Title,
            Library.Scheme.Font,
            20,
            TitleHolder.AbsoluteSize.X - (WindowInfo.Icon and WindowInfo.IconSize.X.Offset + 6 or 0) - 12
        )
        WindowTitle = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(0, X, 1, 0),
            Text = WindowInfo.Title,
            TextSize = 20,
            Parent = TitleHolder,
        })

        --// Top Right Bar
        RightWrapper = New("Frame", {
            AnchorPoint = Vector2.new(1, 0.5),
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -82, 0.5, 0),
            Size = UDim2.new(1, -InitialLeftWidth - 90 - 1, 1, -22),
            Parent = TopBar,
        })

        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Left,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 8),
            Parent = RightWrapper,
        })

        CurrentTabInfo = New("Frame", {
            Size = UDim2.fromScale(WindowInfo.DisableSearch and 1 or 0.5, 1),
            Visible = false,
            BackgroundTransparency = 1,
            ClipsDescendants = true,
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
            Size = UDim2.new(1, 0, 0, 16),
            Text = "",
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = CurrentTabInfo,
        })

        CurrentTabDescription = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 14),
            Text = "",
            TextWrapped = true,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTransparency = 0.5,
            TextTruncate = Enum.TextTruncate.AtEnd,
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
            PaddingBottom = UDim.new(0, 2),
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
            PaddingTop = UDim.new(0, 2),
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

        -- Window controls: minimize + close
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

            -- Minimize button
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

            -- Close button
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

        --// Bottom Bar \\--
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

        --// Footer
        FooterLabel = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Text = WindowInfo.Footer,
            TextSize = 14,
            TextTransparency = 0.5,
            Parent = BottomBar,
        })

        --// Resize Button
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

        New("ImageLabel", {
            Image = ResizeIcon and ResizeIcon.Url or "",
            ImageColor3 = "FontColor",
            ImageRectOffset = ResizeIcon and ResizeIcon.ImageRectOffset or Vector2.zero,
            ImageRectSize = ResizeIcon and ResizeIcon.ImageRectSize or Vector2.zero,
            ImageTransparency = 0.5,
            Position = UDim2.fromOffset(2, 2),
            Size = UDim2.new(1, -4, 1, -4),
            Parent = ResizeButton,
        })

        --// Sidebar wrapper — holds Tabs scroll + optional Discord button \\--
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

        --// Tabs \\--
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

        --// Discord Sidebar Button \\--
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

            -- Top divider
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

            -- Icon + text centered horizontally
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

            -- Hover effect matching the tab button style
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

        --// Container \\--
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

    --// Window Table \\--
    local Window = {}

    function Window:ChangeTitle(title)
        assert(typeof(title) == "string", "Expected string for title got: " .. typeof(title))

        WindowTitle.Text = title
        WindowInfo.Title = title
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

        -- Topbar title: hide text, show icon initial instead
        WindowTitle.Visible = not IsCompact
        if not WindowInfo.Icon then
            WindowIcon.Visible = IsCompact
        end

        -- Tab buttons
        for _, Button in Library.TabButtons do
            Button.Label.Visible = not IsCompact

            if IsCompact then
                -- Center the icon slot in the button, ignore padding
                Button.IconSlot.AnchorPoint = Vector2.new(0.5, 0.5)
                Button.IconSlot.Position = UDim2.fromScale(0.5, 0.5)
                Button.IconSlot.Size = UDim2.new(0, 20, 1, 0)
                Button.IconSlot.SizeConstraint = Enum.SizeConstraint.RelativeYY
                Button.Padding.PaddingLeft = UDim.new(0, 4)
            else
                -- Left-anchored, fixed 20px wide slot with left breathing room
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

        -- Discord sidebar button compact state
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
            -- AllImgLabels[1] = inline icon (non-compact), AllImgLabels[2] = compact centered icon
            -- AllTextLabels[1] = "Discord" text label
            if AllTextLabels[1] then AllTextLabels[1].Visible = not IsCompact end
            if AllImgLabels[1] then AllImgLabels[1].Visible = not IsCompact end
            if AllImgLabels[2] then AllImgLabels[2].Visible = IsCompact end
        end

        -- TabSection headers: hide label text, keep only centered arrow when compact
        for _, Header in Library.TabSectionHeaders do
            Header.Label.Visible = not IsCompact
            if IsCompact then
                Header.Arrow.AnchorPoint = Vector2.new(0.5, 0.5)
                Header.Arrow.Position = UDim2.new(0.5, 0, 0.5, 0)
            else
                Header.Arrow.AnchorPoint = Vector2.new(1, 0.5)
                Header.Arrow.Position = UDim2.new(1, -2, 0.5, 0)
            end
            -- Remove indent padding on tabs inside this section when compact
            if Header.IndentPaddings then
                for _, Pad in Header.IndentPaddings do
                    Pad.PaddingLeft = UDim.new(0, IsCompact and 0 or 6)
                end
            end
            -- Separator only visible when compact, has a following section, and section is open
            if Header.Separator then
                Header.Separator.Visible = IsCompact and Header.GetHasFollower() and Header.GetIsOpen()
            end
            -- Tooltip only active when compact
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

    -- Holds a reference to the sidebar drag grabber once it is created so that
    -- SetSidebarWidth can keep it horizontally aligned with DividerLine.
    local SidebarGrabberRef = nil

    function Window:SetSidebarWidth(Width)
        Width = math.clamp(Width, CompactWidth, MainFrame.Size.X.Offset - 256 - 1)

        DividerLine.Position = UDim2.fromOffset(Width, 0)

        -- Keep the grabber centred on the divider line regardless of which
        -- code path changed the sidebar width.
        if SidebarGrabberRef and SidebarGrabberRef.Parent then
            SidebarGrabberRef.Position = UDim2.fromOffset(Width, 0)
        end

        TitleHolder.Size = UDim2.new(0, Width, 1, 0)
        RightWrapper.Size = UDim2.new(1, -Width - 90 - 1, 1, -16)
        Sidebar.Size = UDim2.new(0, Width, 1, -70)
        Container.Size = UDim2.new(1, -Width - 1, 1, -70)

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

    -- Tracks the last section separator so we can show it when a new section follows it
    local LastSectionSeparator = nil

    -- Collapsible tab section group in the sidebar
    function Window:AddTabSection(Info)
        local SectionName = typeof(Info) == "table" and (Info.Name or "Section") or tostring(Info)
        local DefaultOpen = typeof(Info) == "table" and (Info.Open ~= false) or true
        local SectionIcon = typeof(Info) == "table" and Library:GetCustomIcon(Info.Icon) or nil

        local IsOpen = DefaultOpen

        -- Show the previous section's separator now that this section follows it
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

        -- Section header button
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

        -- When compact, center the arrow since label is hidden
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

        -- Apply current compact state immediately
        ApplySectionCompact(IsCompact)

        -- Children container (holds the actual tab buttons)
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

        -- Separator at the bottom of this section's GroupHolder.
        -- Shown only when another section follows; hidden when this section collapses.
        local SectionSeparator = New("Frame", {
            BackgroundColor3 = "OutlineColor",
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 1),
            Visible = false,
            Parent = GroupHolder,
        })
        Library:AddToRegistry(SectionSeparator, { BackgroundColor3 = "OutlineColor" })

        local HasFollower = false  -- set to true when the next section is created

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

        local IndentPaddings = {}       -- UIPadding refs for indent frames
        local SectionTabButtonRefs = {} -- TabButton entries for buttons inside this section

        -- Tooltip for compact mode (shows section name when sidebar is collapsed)
        local SectionTooltip = CompactTooltips and Library:AddTooltip(SectionName, nil, HeaderBtn) or nil
        if SectionTooltip then
            SectionTooltip.Disabled = not IsCompact
        end

        -- Register for compact toggling (must happen after IndentPaddings/SectionTabButtonRefs are declared)
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

            -- Track which TabButtons belong to this section
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
            -- called with no args
            Name = "Tab"
        elseif typeof(InfoOrName) == "table" then
            local Info = InfoOrName
            Name = Info.Name or "Tab"
            Icon = Info.Icon
            Description = Info.Description
            -- If second arg is a Frame (TabParent override from SectionGroup:AddTab)
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

            -- Fixed-size icon slot, always centered vertically, left-anchored
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

            -- Fallback: first letter label when no icon, also inside IconSlot
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
                TextXAlignment = Enum.TextXAlignment.Left,
                Visible = not IsCompact,
                Parent = TabButton,
            })

            -- Tooltip for compact mode (shows tab name when sidebar is collapsed)
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

            --// Tab Container \\--
            TabContainer = New("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                Visible = false,
                Parent = Container,
            })

            -- Single scrolling container shared by full-width sections and the
            -- left/right two-column row. Everything is laid out top-to-bottom
            -- through one UIListLayout, sorted by LayoutOrder, so full-width
            -- sections and the two-column row push each other around in the
            -- order they were actually added instead of living in separate,
            -- visually-overlapping scroll regions.
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

            -- ColumnFull is just the shared scroll container itself: full-width
            -- sections (Tab:AddSection / Tab:AddSectionGroup with no Side) are
            -- parented straight into it.
            ColumnFull = TabScroll

            -- The two-column row is created lazily, the first time a Side = 1
            -- or Side = 2 section/group is requested, and is inserted into the
            -- shared list at whatever order it was first needed -- so anything
            -- added before it stays above, and anything added after stays below.
            GetSectionParent = function(Side)
                if Side ~= 1 and Side ~= 2 then
                    NextOrder = NextOrder + 1
                    return ColumnFull
                end

                if not ColumnsRow then
                    ColumnsRow = New("Frame", {
                        AutomaticSize = Enum.AutomaticSize.Y,
                        BackgroundTransparency = 1,
                        LayoutOrder = NextOrder,
                        Size = UDim2.new(1, 0, 0, 0),
                        Parent = TabScroll,
                    })

                    ColumnLeft = New("Frame", {
                        AutomaticSize = Enum.AutomaticSize.Y,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(0.5, -3, 0, 0),
                        Parent = ColumnsRow,
                    })
                    New("UIListLayout", {
                        Padding = UDim.new(0, 2),
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        Parent = ColumnLeft,
                    })

                    ColumnRight = New("Frame", {
                        AnchorPoint = Vector2.new(1, 0),
                        AutomaticSize = Enum.AutomaticSize.Y,
                        BackgroundTransparency = 1,
                        Position = UDim2.fromScale(1, 0),
                        Size = UDim2.new(0.5, -3, 0, 0),
                        Parent = ColumnsRow,
                    })
                    New("UIListLayout", {
                        Padding = UDim.new(0, 2),
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        Parent = ColumnRight,
                    })

                    NextOrder = NextOrder + 1
                end

                return Side == 1 and ColumnLeft or ColumnRight
            end
        end

        --// Warning Box \\--
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

        --// Tab Table \\--
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

            local BoxHolder = New("Frame", {
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 0),
                Parent = GetSectionParent(Info.Side),
            })
            New("UIListLayout", {
                Padding = UDim.new(0, 8),
                Parent = BoxHolder,
            })
            New("UIPadding", {
                PaddingBottom = UDim.new(0, 6),
                PaddingTop = UDim.new(0, 6),
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

                -- Foldable header button
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

                -- Fold arrow chevron
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
                    PaddingBottom = UDim.new(0, 16),
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
                Elements = {},

                Side = Info.Side or 1,
                Order = Tab.SectionCount,

                Folded = not (Info.DefaultOpen ~= false),
            }

            function Section:Resize()
                if Section.Folded then
                    SectionHolder.Size = UDim2.new(1, 0, 0, 34)
                else
                    SectionHolder.Size = UDim2.new(1, 0, 0, (SectionList.AbsoluteContentSize.Y / Library.DPIScale) + 55)
                end
            end

            -- Wire fold toggle on header click
            do
                local SectionChevronDown = Library:GetIcon("chevron-down")
                local SectionChevronRight = Library:GetIcon("chevron-right")
                -- Re-fetch the arrow reference through Section closure
                local function SetSectionArrowIcon(Arrow, Open)
                    local Icon = Open and SectionChevronDown or SectionChevronRight
                    if Icon then
                        Arrow.Image = Icon.Url
                        Arrow.ImageRectOffset = Icon.ImageRectOffset
                        Arrow.ImageRectSize = Icon.ImageRectSize
                    end
                end

                -- Find the header button we just created (last TextButton child of SectionHolder at index)
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
            local Info
            if typeof(NameOrInfo) == "table" then
                Info = NameOrInfo
            else
                Info = { Name = NameOrInfo }
            end

            local BoxHolder = New("Frame", {
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 0),
                Parent = GetSectionParent(Info.Side),
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
                    PaddingBottom = UDim.new(0, 7),
                    PaddingLeft = UDim.new(0, 7),
                    PaddingRight = UDim.new(0, 7),
                    PaddingTop = UDim.new(0, 7),
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

                --// Execution \\--
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
                BackgroundTransparency = 0,
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

        --// Execution \\--
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
                TextXAlignment = Enum.TextXAlignment.Left,
                Visible = not IsCompact,
                Parent = TabButton,
            })

            -- Tooltip for compact mode (shows tab name when sidebar is collapsed)
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

            --// Tab Container \\--
            TabContainer = New("ScrollingFrame", {
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                CanvasSize = UDim2.fromScale(0, 0),
                ScrollBarThickness = 0,
                Size = UDim2.fromScale(1, 1),
                Visible = false,
                Parent = Container,
            })
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

        --// Tab Table \\--
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
                BackgroundTransparency = 0,
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

        --// Execution \\--
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
            ZIndex = 9000,
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
            ZIndex = 9001,
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
            ZIndex = 9002,
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
            PaddingBottom = UDim.new(0, 15),
            PaddingLeft = UDim.new(0, 15),
            PaddingRight = UDim.new(0, 15),
            PaddingTop = UDim.new(0, 15),
            Parent = InnerContainer,
        })
        local _InnerLayout = New("UIListLayout", {
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = InnerContainer,
        })

        local HeaderContainer = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = 1,
            ZIndex = 9002,
            Parent = InnerContainer,
        })
        New("UIListLayout", {
            Padding = UDim.new(0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = HeaderContainer,
        })

        local TitleRow = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 20),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = 1,
            ZIndex = 9002,
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
                    ZIndex = 9002,
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
            ZIndex = 9002,
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
            ZIndex = 9002,
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
            ZIndex = 9002,
            Parent = InnerContainer,
        })
        local _DialogContainerLayout = New("UIListLayout", {
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = DialogContainer,
        })
        
        local _Sep2 = New("Frame", {
            BackgroundColor3 = "OutlineColor",
            BackgroundTransparency = 0,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 1),
            LayoutOrder = 5,
            ZIndex = 9002,
            Parent = InnerContainer,
        })

        ButtonsHolder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = 6,
            ZIndex = 9002,
            Parent = InnerContainer,
        })
        New("UIListLayout", {
            Padding = UDim.new(0, 8),
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            Wraps = true,
            SortOrder = Enum.SortOrder.LayoutOrder,
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

        function Dialog:SetTitle(Title)
            TitleLabel.Text = Title
            Dialog:Resize()
        end

        function Dialog:SetDescription(Description)
            DescriptionLabel.Text = Description
            Dialog:Resize()
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
                ZIndex = 9002,
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
                BackgroundTransparency = WaitTime > 0 and 0.5 or 0,
                Size = UDim2.fromOffset(0, 26),
                Text = "",
                AutoButtonColor = false,
                ZIndex = 9002,
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

            local _BtnPadding = New("UIPadding", {
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
                Text = ButtonInfo.Title or ButtonIdx,
                TextColor3 = TextColor,
                TextTransparency = WaitTime > 0 and 0.5 or 0,
                TextSize = 14,
                ZIndex = 9002,
                Parent = TextBtn,
            })
            
            local LabelX, _ = Library:GetTextBounds(BtnLabel.Text, Library.Scheme.Font, 14, 250)
            ButtonContainer.Size = UDim2.fromOffset(LabelX + 30, 26)
            TextBtn.Size = UDim2.fromOffset(LabelX + 30, 26)

            local ProgressBar
            if WaitTime > 0 then
                ProgressBar = New("Frame", {
                    BackgroundColor3 = "AccentColor",
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 0, 1, -2),
                    Size = UDim2.new(0, 0, 0, 2),
                    ZIndex = 2,
                    Parent = TextBtn,
                })
                table.insert(
                    Library.Corners,
                    New("UICorner", { 
                        CornerRadius = UDim.new(0, Library.CornerRadius), 
                        Parent = ProgressBar 
                    })
                )
            end

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

            local ActiveColor = typeof(BtnColor) == "Color3" and BtnColor or Library.Scheme[BtnColor]
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
                    Size = UDim2.new(1, 0, 0, 2)
                }):Play()
                
                task.delay(WaitTime, function()
                    ButtonWrap:SetDisabled(false)
                    if ProgressBar then
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
        Window:SetSidebarWidth(CompactWidth)
    end
    if WindowInfo.AutoShow and not Library.ActiveLoading then
        task.spawn(Library.Toggle)
    end

    --// Toggle Bubble \\--
    do
        local BubbleEnabled = WindowInfo.Bubble
        if BubbleEnabled == nil then
            BubbleEnabled = Library.IsMobile
        end

        if BubbleEnabled then
            local BubbleSizeInfo = WindowInfo.BubbleSize
            local Width, Height = BubbleSizeInfo.X.Offset, BubbleSizeInfo.Y.Offset
            local Margin = WindowInfo.BubbleMargin
            local Padding = WindowInfo.BubblePadding
            local StartSide = (WindowInfo.BubbleSide == "Left") and "Left" or "Right"

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
                local ClampedY =
                    math.clamp(Bubble.AbsolutePosition.Y, Margin, math.max(Margin, ScreenSize.Y - Height - Margin))

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
                        local CenterX = Bubble.AbsolutePosition.X + (Width / 2)
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
        end
    end

    --// Search Overlay System \\--
    do
        local SearchOverlay = New("Frame", {
            BackgroundColor3 = "MainColor",
            BorderSizePixel = 0,
            Size = UDim2.new(0, 300, 0, 400),
            Visible = false,
            ZIndex = 200,
            Parent = MainFrame,
        })
        Library:AddToRegistry(SearchOverlay, { BackgroundColor3 = "MainColor" })

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
            ZIndex = 201,
            Parent = SearchOverlay,
        })
        Library:AddToRegistry(ScrollFrame, { ScrollBarImageColor3 = "OutlineColor" })

        New("UICorner", {
            CornerRadius = UDim.new(0, WindowInfo.CornerRadius),
            Parent = ScrollFrame,
        })

        New("UIPadding", {
            PaddingTop    = UDim.new(0, 6),
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

        -- Forward-declared so NavigateTo (below) can call CloseOverlay before it is defined
        local CloseOverlay

        local function NavigateTo(Tab, Section, ElementInfo)
            if CloseOverlay then CloseOverlay() end
            SearchBox.Text = ""
            SearchBox:ReleaseFocus()

            if Tab and Tab.Show then
                Tab:Show()
            end

            task.spawn(function()
                task.wait()

                if Section and Section.SetFolded and Section.Folded then
                    Section:SetFolded(false)
                    task.wait()
                end

                if Section and Section.BoxHolder then
                    local Col = Section.BoxHolder.Parent
                    if Col and Col:IsA("ScrollingFrame") then
                        local RelY = Section.BoxHolder.AbsolutePosition.Y - Col.AbsolutePosition.Y + Col.CanvasPosition.Y
                        Col.CanvasPosition = Vector2.new(0, math.max(0, RelY - 10))
                    end
                end

                task.wait()
                task.wait()

                local function FlashTarget(TargetInst, ExpandX, ExpandY)
                    if not (TargetInst and TargetInst.Parent) then return end
                    local AbsPos     = TargetInst.AbsolutePosition
                    local AbsSize    = TargetInst.AbsoluteSize
                    local MainAbsPos = MainFrame.AbsolutePosition
                    local RelX       = (AbsPos.X - MainAbsPos.X) - ExpandX
                    local RelY       = (AbsPos.Y - MainAbsPos.Y) - ExpandY

                    local FlashOutline = New("Frame", {
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
                        Position = UDim2.fromOffset(RelX, RelY),
                        Size = UDim2.fromOffset(AbsSize.X + ExpandX * 2, AbsSize.Y + ExpandY * 2),
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
                    local IsButton   = ElementInfo.Type == "Button"
                    local TargetInst = (IsButton and ElementInfo.Base) or ElementInfo.Holder
                    local ExpandX    = IsButton and 0 or 10
                    local ExpandY    = IsButton and 0 or 4
                    FlashTarget(TargetInst, ExpandX, ExpandY)
                elseif Section and Section.BoxHolder and Section.BoxHolder.Parent then
                    FlashTarget(Section.BoxHolder, 0, -8)
                end
            end)
        end

        local RowH   = 24
        local Indent = 16

        local function MakeRow(Cfg, Order)
            local Depth = Cfg.Depth or 0
            local Z     = 202

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

            if Cfg.IsElement and Cfg.ElementType then
                local TypeLabels = {
                    Button = "BTN", Toggle = "TGL", Slider = "SLD",
                    Dropdown = "DROP", ColorPicker = "CLR", Textbox = "TXT",
                    Label = "LBL", KeyPicker = "KEY", SubButton = "SUB",
                }
                local BadgeText = TypeLabels[Cfg.ElementType] or Cfg.ElementType:upper():sub(1, 4)
                BadgeW = 34

                local Badge = New("Frame", {
                    BackgroundColor3       = "AccentColor",
                    BackgroundTransparency = 0.75,
                    BorderSizePixel        = 0,
                    Position = UDim2.new(1, -(BadgeW + 4), 0.5, -8),
                    Size     = UDim2.new(0, BadgeW, 0, 16),
                    ZIndex   = Z + 2,
                    Parent   = Btn,
                })
                Library:AddToRegistry(Badge, { BackgroundColor3 = "AccentColor" })
                New("UICorner", { CornerRadius = UDim.new(0, 3), Parent = Badge })
                New("TextLabel", {
                    BackgroundTransparency = 1,
                    Size           = UDim2.fromScale(1, 1),
                    Text           = BadgeText,
                    TextSize       = 9,
                    TextColor3     = Color3.fromRGB(255, 255, 255),
                    TextXAlignment = Enum.TextXAlignment.Center,
                    Font           = Enum.Font.GothamBold,
                    ZIndex         = Z + 3,
                    Parent         = Badge,
                })
            end

            local Lbl = New("TextLabel", {
                BackgroundTransparency = 1,
                Position       = UDim2.new(0, TextX, 0, 0),
                Size           = UDim2.new(1, -(TextX + (BadgeW > 0 and BadgeW + 8 or 0)), 1, 0),
                Text           = Cfg.Text,
                TextSize       = Cfg.IsTab and 13 or 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTransparency = Cfg.IsTab and 0 or (Cfg.IsElement and 0.35 or 0.1),
                TextTruncate   = Enum.TextTruncate.AtEnd,
                ZIndex         = Z + 1,
                Parent         = Btn,
            })
            if Cfg.IsTab then
                Library:AddToRegistry(Lbl, { TextColor3 = "AccentColor" })
            else
                Library:AddToRegistry(Lbl, { TextColor3 = "FontColor" })
            end

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
            local AbsPos  = SearchBox.AbsolutePosition
            local AbsSize = SearchBox.AbsoluteSize
            local MainAbs = MainFrame.AbsolutePosition
            SearchOverlay.Size     = UDim2.new(0, AbsSize.X + 3, 0, 400)
            SearchOverlay.Position = UDim2.fromOffset(
                AbsPos.X - MainAbs.X,
                AbsPos.Y - MainAbs.Y + AbsSize.Y + 4
            )
        end

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
                    local SideA, SideB = A.Section.Side or 1, B.Section.Side or 1
                    if SideA ~= SideB then
                        return SideA < SideB
                    end
                    return (A.Section.Order or 0) < (B.Section.Order or 0)
                end)

                for _, SectionEntry in SortedSections do
                    local SectionName = SectionEntry.Name
                    local Section     = SectionEntry.Section
                    local SectionMatches = not Filtering or SectionName:lower():match(Search)
                    local ElMatches = {}
                    for _, Info in Section.Elements do
                        if Info.Type == "Divider" then continue end
                        local EText = Info.Text
                        if not EText or not Info.Visible then continue end

                        if not Filtering or SectionMatches or EText:lower():match(Search) then
                            table.insert(ElMatches, { Text = EText, Info = Info, ElType = Info.Type })
                        end

                        if Info.SubButton and Info.SubButton.Text and Info.SubButton.Visible then
                            local SubText = Info.SubButton.Text
                            if not Filtering or SectionMatches or SubText:lower():match(Search) then
                                table.insert(ElMatches, { Text = SubText, Info = Info, ElType = "SubButton" })
                            end
                        end
                    end
                    if SectionMatches or #ElMatches > 0 then
                        table.insert(TabMatches, { SectionName = SectionName, Section = Section, Elements = ElMatches, SectionMatch = SectionMatches })
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
                        local ElInfo = ElEntry.Info

                        RowOrder += 1
                        table.insert(ActiveRows, MakeRow({
                            Text        = ElEntry.Text,
                            Depth       = 2,
                            IsElement   = true,
                            IsLast      = Ei == #SecEntry.Elements,
                            ElementType = ElEntry.ElType,
                            OnActivate  = function() NavigateTo(Tab, Section, ElInfo) end,
                        }, RowOrder))
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

        SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
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
                    -- overlay click: let the row's MouseButton1Click fire naturally
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

    --// ScreenGui \\--
    local ScreenGui = New("ScreenGui", {
        Name = "AstralLoading",
        DisplayOrder = 999,
        ResetOnSpawn = false
    })
    ParentUI(ScreenGui)
    Loading.ScreenGui = ScreenGui

    ScreenGui.DescendantRemoving:Connect(function(Instance)
        Library:RemoveFromRegistry(Instance)
    end)

    --// Main Frame \\--
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
    
	local MainScale = New("UIScale", {
		Scale = Library.IsMobile and 0.8 or 1,
		Parent = MainFrame
	})
	table.insert(Library.Scales, MainScale)
	Library.ScalesOffset[MainScale] = Library.IsMobile and 0.2 or 0

    --// Layout Containers \\--
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

    --// Top Bar \\--
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
        -- LoadingInfo.Icon may be an asset name ("AstralIcon") or a direct ID/URL string.
        -- Resolve through GetCustomIcon; use IsBuiltIn to decide accent tinting.
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

    --// Loading Content Elements \\--
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

    --// Progress Bar \\--
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

    --// Sidebar Object \\--
    local SidebarScrolling = New("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Size = UDim2.fromScale(1, 1),
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = "OutlineColor",
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

    --// Error Frame \\--
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

    --// Content Page \\--
    function Loading:RecalculateLoadingHeight()
        if not Loading.AutoResizeHeight then
            return
        end

        local RequiredHeight = 
              49 -- TopBar
            + 48 -- Padding
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

    --// Size \\--
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

    --// Sidebar \\--
    function Loading:ShowSidebarPage(Bool)
        Loading.ShowSidebar = Bool
        Loading:UpdateLayout()
    end

    --// Error Page \\--
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
              49                        -- TopBar
            + 15                        -- Padding Top
            + 18                        -- Title Height
            + 6                         -- Padding between Title and Label
            + ErrorY                    -- Label Height
            + 15                        -- Padding between Label and Buttons
            + (HasButtons and 48 or 0)  -- Buttons Area

        Loading.WindowErrorHeight = RequiredHeight -- math.max(Loading.WindowHeight, RequiredHeight)
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

    --// Destroy/Continue \\--
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


--[[
    ================================================================
    DEMO — Complete element showcase for the UI library
    Every element type, every combo, every variant.
    ================================================================
--]]

local _args = { ... }
if _args[1] == "Demo" then

local Window = Library:CreateWindow({
    Title = "Astral UI",
    Icon = Library.ImageManager.GetAsset("AstralIcon"),
    Footer = "Element Showcase — All Components",
    Size = UDim2.fromOffset(780, 580),
    Center = true,
    Resizable = true,
    ToggleKeybind = Enum.KeyCode.RightControl,
    NotifySide = "Right",
    EnableSidebarResize = true,
    SidebarCompacted = false,
    SingleInstance = true,
    DiscordLink = "https://discord.gg/",
    DiscordAction = "open",
    Bubble = true, -- force it on for this demo, even off mobile
    BubbleSide = "Right",
    BubbleIcon = Library.ImageManager.GetAsset("AstralIcon"),
})

-- ================================================================
-- ADDONS — SaveManager & ThemeManager
-- ================================================================
local SaveManager = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/inCythe/Astral/refs/heads/main/addons/SaveManager.lua"
))()
local ThemeManager = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/inCythe/Astral/refs/heads/main/addons/ThemeManager.lua"
))()

SaveManager:SetLibrary(Library)
ThemeManager:SetLibrary(Library)

-- Keep theme colours out of config saves so they are managed independently.
SaveManager:IgnoreThemeSettings()

-- ================================================================
-- TAB SECTIONS (collapsible sidebar groups)
-- ================================================================
local SecElements  = Window:AddTabSection({ Name = "Elements",   Open = true  })
local SecAddons    = Window:AddTabSection({ Name = "Addons",     Open = true  })
local SecLayout    = Window:AddTabSection({ Name = "Layout",     Open = true  })
local SecShowcase  = Window:AddTabSection({ Name = "Showcase",   Open = true  })
local SecDialogs   = Window:AddTabSection({ Name = "Dialogs",    Open = false })

-- ================================================================
-- TABS
-- ================================================================
local TabToggles   = SecElements:AddTab({ Name = "Toggles",   Icon = "toggle-right",   Description = "Toggle & Checkbox variants" })
local TabButtons   = SecElements:AddTab({ Name = "Buttons",   Icon = "mouse-pointer",  Description = "Button variants and combos" })
local TabInputs    = SecElements:AddTab({ Name = "Inputs",    Icon = "type",           Description = "Text inputs and sliders" })
local TabDropdowns = SecElements:AddTab({ Name = "Dropdowns", Icon = "chevron-down",   Description = "Dropdown variants incl. searchable" })
local TabLabels    = SecElements:AddTab({ Name = "Labels",    Icon = "align-left",     Description = "Labels, dividers, and wrapping text" })

local TabColors    = SecAddons:AddTab({ Name = "Colors",    Icon = "palette",        Description = "ColorPicker on toggles and labels" })
local TabKeys      = SecAddons:AddTab({ Name = "Keybinds",  Icon = "key",            Description = "KeyPicker modes: Toggle, Hold, Press, Always" })

local TabSections  = SecLayout:AddTab({ Name = "Sections",  Icon = "layout",         Description = "Full-width & left/right sections" })
local TabTabboxes  = SecLayout:AddTab({ Name = "Tabboxes",  Icon = "box",            Description = "SectionGroups (collapsible tabboxes)" })

local TabRichText  = SecShowcase:AddTab({ Name = "Rich Text",     Icon = "type",          Description = "Inline rich text formatting in labels, buttons and tooltips" })
local TabViewports = SecShowcase:AddTab({ Name = "Viewports",     Icon = "box",           Description = "3D viewport frames and image elements" })
local TabLoading   = SecShowcase:AddTab({ Name = "Loading",       Icon = "loader",        Description = "Standalone loading screen demo" })
local TabTruncate  = SecShowcase:AddTab({ Name = "Long Text",     Icon = "scissors",      Description = "Truncation behaviour for overflowing element text" })
local TabOverlays  = SecShowcase:AddTab({ Name = "Overlays",      Icon = "picture-in-picture-2", Description = "Floating draggable label/button/menu overlays + the Keybinds list" })

local TabDialogs   = SecDialogs:AddTab({ Name = "Dialogs",  Icon = "message-square", Description = "Dialog, overlay, and notification demos" })

local SecConfig    = Window:AddTabSection({ Name = "Config",     Open = true  })
local TabConfig    = SecConfig:AddTab({ Name = "Config",    Icon = "save",           Description = "Save, load, and manage named config profiles" })

-- ================================================================
-- TAB: TOGGLES
-- ================================================================
do
    local L = TabToggles:AddLeftSection("Standard Toggles", "toggle-right")
    local R = TabToggles:AddRightSection("Checkbox Style", "check-square")

    -- Basic on/off
    Toggles.T_Basic = L:AddToggle("T_Basic", {
        Text = "Basic Toggle",
        Default = false,
        Tooltip = "A simple on/off toggle with no extras",
    })

    -- Default ON
    Toggles.T_DefaultOn = L:AddToggle("T_DefaultOn", {
        Text = "Default ON",
        Default = true,
    })

    -- Risky (red text)
    Toggles.T_Risky = L:AddToggle("T_Risky", {
        Text = "Risky Toggle (red)",
        Default = false,
        Risky = true,
        Tooltip = "Dangerous actions show in red",
    })

    -- Disabled
    Toggles.T_Disabled = L:AddToggle("T_Disabled", {
        Text = "Disabled Toggle",
        Default = false,
        Disabled = true,
        DisabledTooltip = "This toggle is currently locked",
    })

    -- Callback demo
    Toggles.T_Callback = L:AddToggle("T_Callback", {
        Text = "Toggle with Callback",
        Default = false,
        Callback = function(Value)
            Library:Notify({
                Title = "Toggle Changed",
                Description = "Value is now: " .. tostring(Value),
                Time = 2,
            })
        end,
    })

    -- Visibility toggle (hides another)
    Toggles.T_ShowHide = L:AddToggle("T_ShowHide", {
        Text = "Show/Hide next toggle",
        Default = true,
        Callback = function(Value)
            if Toggles.T_Hidden then
                Toggles.T_Hidden:SetVisible(Value)
            end
        end,
    })
    Toggles.T_Hidden = L:AddToggle("T_Hidden", {
        Text = "← Hidden by above toggle",
        Default = false,
        Visible = true,
    })

    -- Right column: Checkbox style
    Toggles.CB_Basic = R:AddCheckbox("CB_Basic", {
        Text = "Basic Checkbox",
        Default = false,
    })
    Toggles.CB_On = R:AddCheckbox("CB_On", {
        Text = "Checked by Default",
        Default = true,
    })
    Toggles.CB_Risky = R:AddCheckbox("CB_Risky", {
        Text = "Risky Checkbox (red)",
        Default = false,
        Risky = true,
    })
    Toggles.CB_Disabled = R:AddCheckbox("CB_Disabled", {
        Text = "Disabled Checkbox",
        Default = false,
        Disabled = true,
    })
    Toggles.CB_Callback = R:AddCheckbox("CB_Callback", {
        Text = "Checkbox with Callback",
        Default = false,
        Callback = function(v)
            Library:Notify({ Title = "Checkbox", Description = "Checked: " .. tostring(v), Time = 2 })
        end,
    })
end

-- ================================================================
-- TAB: BUTTONS
-- ================================================================
do
    local L = TabButtons:AddLeftSection("Button Variants", "mouse-pointer")
    local R = TabButtons:AddRightSection("Sub-Buttons & Combos", "layers")

    -- Basic
    Buttons.B_Basic = L:AddButton({
        Text = "Basic Button",
        Func = function()
            Library:Notify({ Title = "Basic", Description = "Clicked!", Time = 2 })
        end,
    })

    -- Risky
    Buttons.B_Risky = L:AddButton({
        Text = "Risky Button",
        Risky = true,
        Func = function()
            Library:Notify({ Title = "Risky", Description = "Risky action triggered.", Time = 2 })
        end,
    })

    -- Double-click confirm
    Buttons.B_Double = L:AddButton({
        Text = "Double-Confirm Button",
        DoubleClick = true,
        Func = function()
            Library:Notify({ Title = "Confirmed", Description = "Double-click accepted.", Time = 2 })
        end,
    })

    -- Disabled
    Buttons.B_Disabled = L:AddButton({
        Text = "Disabled Button",
        Disabled = true,
        Func = function() end,
    })

    -- With tooltip
    Buttons.B_Tooltip = L:AddButton({
        Text = "Button with Tooltip",
        Tooltip = "Hover me to see this tooltip",
        Func = function()
            Library:Notify({ Title = "Tooltip Button", Description = "Fired!", Time = 2 })
        end,
    })

    -- Dynamic text change
    Buttons.B_Dynamic = L:AddButton({
        Text = "Click to Rename Me",
        Func = function()
            Buttons.B_Dynamic:SetText("Renamed!")
            Library:Notify({ Title = "Button", Description = "Text changed.", Time = 2 })
        end,
    })

    -- Right: Sub-buttons (two buttons side by side)
    local BtnPair1 = R:AddButton({
        Text = "Primary",
        Func = function()
            Library:Notify({ Title = "Primary", Description = "Primary clicked.", Time = 2 })
        end,
    })
    BtnPair1:AddButton({
        Text = "Secondary",
        Func = function()
            Library:Notify({ Title = "Secondary", Description = "Secondary clicked.", Time = 2 })
        end,
    })

    R:AddDivider({ Text = "More Sub-Buttons" })

    local BtnPair2 = R:AddButton({
        Text = "Save",
        Func = function()
            Library:Notify({ Title = "Save", Description = "Config saved.", Time = 2 })
        end,
    })
    BtnPair2:AddButton({
        Text = "Load",
        Func = function()
            Library:Notify({ Title = "Load", Description = "Config loaded.", Time = 2 })
        end,
    })

    local BtnPair3 = R:AddButton({
        Text = "Enable All",
        Func = function()
            Library:Notify({ Title = "All", Description = "All features enabled.", Time = 2 })
        end,
    })
    BtnPair3:AddButton({
        Text = "Disable All",
        Risky = true,
        Func = function()
            Library:Notify({ Title = "All", Description = "All features disabled.", Time = 2 })
        end,
    })

    R:AddDivider({ Text = "Risky Sub-Button" })

    local BtnPair4 = R:AddButton({
        Text = "Teleport to Marker",
        Func = function()
            Library:Notify({ Title = "TP", Description = "Teleporting...", Time = 2 })
        end,
    })
    BtnPair4:AddButton({
        Text = "Clear",
        Risky = true,
        Func = function()
            Library:Notify({ Title = "Cleared", Description = "Marker cleared.", Time = 2 })
        end,
    })
end

-- ================================================================
-- TAB: INPUTS & SLIDERS
-- ================================================================
do
    local L = TabInputs:AddLeftSection("Text Inputs", "type")
    local R = TabInputs:AddRightSection("Sliders", "sliders")

    -- Text input (any text)
    Options.I_Basic = L:AddInput("I_Basic", {
        Text = "Text Input",
        Default = "",
        Placeholder = "Type something...",
        AllowEmpty = true,
    })

    -- Numeric only
    Options.I_Numeric = L:AddInput("I_Numeric", {
        Text = "Numeric Input",
        Default = "0",
        Placeholder = "Numbers only",
        Numeric = true,
        AllowEmpty = false,
    })

    -- ClearOnFocus
    Options.I_ClearFocus = L:AddInput("I_ClearFocus", {
        Text = "Clears on Focus",
        Default = "Click to clear",
        ClearTextOnFocus = true,
        AllowEmpty = true,
    })

    -- Finished (fires only on Enter)
    Options.I_Finished = L:AddInput("I_Finished", {
        Text = "Fires on Enter Only",
        Default = "",
        Placeholder = "Press Enter...",
        Finished = true,
        AllowEmpty = true,
        Callback = function(v)
            Library:Notify({ Title = "Input", Description = "Submitted: " .. v, Time = 2 })
        end,
    })

    -- Disabled
    Options.I_Disabled = L:AddInput("I_Disabled", {
        Text = "Disabled Input",
        Default = "Cannot edit",
        Disabled = true,
        AllowEmpty = true,
    })

    -- Right: Sliders
    Options.S_Basic = R:AddSlider("S_Basic", {
        Text = "Basic Slider",
        Default = 50,
        Min = 0,
        Max = 100,
        Rounding = 0,
    })

    Options.S_Float = R:AddSlider("S_Float", {
        Text = "Float Slider",
        Default = 0.5,
        Min = 0.0,
        Max = 1.0,
        Rounding = 2,
    })

    Options.S_Suffix = R:AddSlider("S_Suffix", {
        Text = "Slider with Suffix",
        Default = 16,
        Min = 4,
        Max = 250,
        Rounding = 0,
        Suffix = " studs/s",
    })

    Options.S_Prefix = R:AddSlider("S_Prefix", {
        Text = "Slider with Prefix",
        Default = 1.0,
        Min = 0.1,
        Max = 5.0,
        Rounding = 1,
        Prefix = "x",
    })

    Options.S_Callback = R:AddSlider("S_Callback", {
        Text = "Slider with Callback",
        Default = 60,
        Min = 10,
        Max = 144,
        Rounding = 0,
        Suffix = " FPS",
        Callback = function(v)
            -- print("FPS cap:", v)
        end,
    })

    Options.S_Disabled = R:AddSlider("S_Disabled", {
        Text = "Disabled Slider",
        Default = 25,
        Min = 0,
        Max = 100,
        Rounding = 0,
        Disabled = true,
    })

    R:AddDivider({ Text = "Editable (click the pencil to type a value)" })

    Options.S_Editable = R:AddSlider("S_Editable", {
        Text = "Editable Slider (Pencil)",
        Default = 35,
        Min = 0,
        Max = 1000,
        Rounding = 0,
        Suffix = " HP",
        Editable = true,
        EditableStyle = "Pencil",
        Tooltip = "Drag the bar, or click the pencil icon to type an exact value.",
    })

    R:AddDivider({ Text = "Editable (value box on the right of label)" })

    Options.S_ValueBox = R:AddSlider("S_ValueBox", {
        Text = "Editable Slider (Value Box)",
        Default = 60,
        Min = 0,
        Max = 200,
        Rounding = 0,
        Suffix = " ms",
        Editable = true,
        EditableStyle = "ValueBox",
        Tooltip = "Drag the bar, or type directly in the small box next to the label.",
    })
end

-- ================================================================
-- TAB: DROPDOWNS (including searchable)
-- ================================================================
do
    local L = TabDropdowns:AddLeftSection("Standard Dropdowns", "chevron-down")
    local R = TabDropdowns:AddRightSection("Searchable & Multi-Select", "search")

    -- Basic single-select
    Options.D_Basic = L:AddDropdown("D_Basic", {
        Text = "Basic Dropdown",
        Default = "Option A",
        Values = { "Option A", "Option B", "Option C", "Option D", "Option E" },
    })

    -- Default by index
    Options.D_Index = L:AddDropdown("D_Index", {
        Text = "Default by Index",
        Default = 3,
        Values = { "Red", "Green", "Blue", "Yellow", "Purple" },
    })

    -- Callback
    Options.D_Callback = L:AddDropdown("D_Callback", {
        Text = "With Callback",
        Default = "Nearest",
        Values = { "Nearest", "Lowest HP", "Highest HP", "Random", "First Seen" },
        Callback = function(v)
            Library:Notify({ Title = "Dropdown", Description = "Selected: " .. tostring(v), Time = 2 })
        end,
    })

    -- Disabled
    Options.D_Disabled = L:AddDropdown("D_Disabled", {
        Text = "Disabled Dropdown",
        Default = "Locked",
        Values = { "Locked", "Also Locked" },
        Disabled = true,
    })

    -- Disabled values inside
    Options.D_DisabledVals = L:AddDropdown("D_DisabledVals", {
        Text = "Some Values Disabled",
        Default = "Normal",
        Values = { "Normal", "Locked Value", "Another", "Also Locked" },
        DisabledValues = { "Locked Value", "Also Locked" },
    })

    -- Right: Multi-select
    Options.D_Multi = R:AddDropdown("D_Multi", {
        Text = "Multi-Select",
        Default = { "Enemies", "Players" },
        Values = { "Enemies", "Players", "Bosses", "NPCs", "Chests", "All" },
        Multi = true,
    })

    R:AddDivider({ Text = "Searchable Dropdowns" })

    -- Searchable single
    Options.D_Search = R:AddDropdown("D_Search", {
        Text = "Searchable Single",
        Default = "Apple",
        Values = {
            "Apple", "Apricot", "Banana", "Blueberry", "Cherry",
            "Coconut", "Grape", "Kiwi", "Lemon", "Lime",
            "Mango", "Orange", "Papaya", "Peach", "Pear",
            "Pineapple", "Strawberry", "Watermelon",
        },
        Searchable = true,
    })

    -- Searchable multi-select
    Options.D_SearchMulti = R:AddDropdown("D_SearchMulti", {
        Text = "Searchable Multi-Select",
        Default = { "Sword", "Shield" },
        Values = {
            "Sword", "Shield", "Bow", "Staff", "Axe",
            "Dagger", "Spear", "Hammer", "Wand", "Tome",
            "Crossbow", "Scythe", "Whip", "Cannon", "Flail",
        },
        Multi = true,
        Searchable = true,
    })

    -- Searchable with many values (stress test)
    local BigList = {}
    for i = 1, 50 do table.insert(BigList, "Item " .. i) end
    Options.D_SearchBig = R:AddDropdown("D_SearchBig", {
        Text = "Searchable (50 items)",
        Default = "Item 1",
        Values = BigList,
        Searchable = true,
    })
end

-- ================================================================
-- TAB: LABELS & DIVIDERS
-- ================================================================
do
    local L = TabLabels:AddLeftSection("Label Variants", "type")
    local R = TabLabels:AddRightSection("Divider Variants", "minus")

    -- Static label
    L:AddLabel("Static label — default size")

    -- Custom size
    L:AddLabel({ Text = "Larger label (size 18)", Size = 18 })
    L:AddLabel({ Text = "Smaller label (size 11)", Size = 11 })

    -- Wrapping label
    L:AddLabel({ Text = "This is a wrapping label. It will expand to multiple lines if the text is too long to fit on a single line inside the section.", DoesWrap = true })

    -- Label with KeyPicker attached
    local LblKey = L:AddLabel("Label with KeyPicker →")
    LblKey:AddKeyPicker("LblKeyPick", {
        Default = "None",
        Mode = "Press",
        Text = "Key",
    })

    -- Label with ColorPicker attached
    local LblCol = L:AddLabel("Label with ColorPicker →")
    Options.LblColorPick = LblCol:AddColorPicker("LblColorPick", {
        Default = Color3.fromRGB(255, 100, 50),
    })

    -- Dynamic label
    local DynLabel = L:AddLabel("Dynamic Label — click button below")
    local counter = 0
    Buttons.B_UpdateLabel = L:AddButton({
        Text = "Update Label Text",
        Func = function()
            counter = counter + 1
            DynLabel:SetText("Updated " .. counter .. " time(s)")
        end,
    })

    -- Right: Divider variants
    R:AddLabel("No-text plain divider:")
    R:AddDivider()

    R:AddLabel("Divider with text:")
    R:AddDivider({ Text = "Section Title" })

    R:AddLabel("Divider with top/bottom margin:")
    R:AddDivider({ Text = "More Space", Margin = 6 })

    R:AddLabel("Divider with asymmetric margin:")
    R:AddDivider({ Text = "Asymmetric", MarginTop = 10, MarginBottom = 2 })

    R:AddLabel("Toggle below a divider:")
    R:AddDivider({ Text = "After This" })
    Toggles.T_AfterDivider = R:AddToggle("T_AfterDivider", {
        Text = "I am after a divider",
        Default = false,
    })
end

-- ================================================================
-- TAB: COLOR PICKERS
-- ================================================================
do
    local L = TabColors:AddLeftSection("Toggle + ColorPicker", "palette")
    local R = TabColors:AddRightSection("Label + ColorPicker", "droplets")

    -- ColorPicker on Toggle
    Toggles.C_ESP = L:AddToggle("C_ESP", {
        Text = "ESP Highlight",
        Default = true,
    })
    Options.C_ESPColor = Toggles.C_ESP:AddColorPicker("C_ESPColor", {
        Default = Color3.fromRGB(255, 80, 80),
    })

    Toggles.C_Trail = L:AddToggle("C_Trail", {
        Text = "Trail Effect",
        Default = false,
    })
    Options.C_TrailColor = Toggles.C_Trail:AddColorPicker("C_TrailColor", {
        Default = Color3.fromRGB(80, 180, 255),
    })

    Toggles.C_Glow = L:AddToggle("C_Glow", {
        Text = "Glow Outline",
        Default = true,
    })
    Options.C_GlowColor = Toggles.C_Glow:AddColorPicker("C_GlowColor", {
        Default = Color3.fromRGB(255, 220, 50),
    })

    Toggles.C_Chams = L:AddToggle("C_Chams", {
        Text = "Chams",
        Default = false,
        Risky = true,
    })
    Options.C_ChamsColor = Toggles.C_Chams:AddColorPicker("C_ChamsColor", {
        Default = Color3.fromRGB(200, 60, 255),
    })

    L:AddDivider({ Text = "Accent Override" })

    Toggles.C_Accent = L:AddToggle("C_Accent", {
        Text = "Custom Accent Color",
        Default = true,
    })
    Options.C_AccentColor = Toggles.C_Accent:AddColorPicker("C_AccentColor", {
        Default = Color3.fromRGB(66, 135, 245),
        Callback = function(Value)
            if Toggles.C_Accent.Value then
                Library.Scheme.AccentColor = Value
                Library:UpdateColorsUsingRegistry()
            end
        end,
    })

    -- Right: Label + ColorPicker combos
    local ColLabel1 = R:AddLabel("Enemy Color")
    Options.C_EnemyLabel = ColLabel1:AddColorPicker("C_EnemyLabel", {
        Default = Color3.fromRGB(255, 60, 60),
    })

    local ColLabel2 = R:AddLabel("Ally Color")
    Options.C_AllyLabel = ColLabel2:AddColorPicker("C_AllyLabel", {
        Default = Color3.fromRGB(60, 180, 255),
    })

    local ColLabel3 = R:AddLabel("Neutral Color")
    Options.C_NeutralLabel = ColLabel3:AddColorPicker("C_NeutralLabel", {
        Default = Color3.fromRGB(180, 180, 180),
    })

    local ColLabel4 = R:AddLabel("Boss Color")
    Options.C_BossLabel = ColLabel4:AddColorPicker("C_BossLabel", {
        Default = Color3.fromRGB(255, 160, 0),
    })

    R:AddDivider({ Text = "Multiple Pickers on One Toggle" })

    -- A single toggle with THREE ColorPickers attached — they line up on the right
    Toggles.C_Multi = R:AddToggle("C_Multi", {
        Text = "RGB Triple Color",
        Default = true,
    })
    Options.C_MultiRed = Toggles.C_Multi:AddColorPicker("C_MultiRed", {
        Default = Color3.fromRGB(255, 60, 60),
        Callback = function(v) end,
    })
    Options.C_MultiGreen = Toggles.C_Multi:AddColorPicker("C_MultiGreen", {
        Default = Color3.fromRGB(60, 200, 60),
        Callback = function(v) end,
    })
    Options.C_MultiBlue = Toggles.C_Multi:AddColorPicker("C_MultiBlue", {
        Default = Color3.fromRGB(60, 120, 255),
        Callback = function(v) end,
    })

    -- Another toggle with two pickers (primary + secondary)
    Toggles.C_Multi2 = R:AddToggle("C_Multi2", {
        Text = "Dual Color Feature",
        Default = false,
    })
    Options.C_Multi2Primary = Toggles.C_Multi2:AddColorPicker("C_Multi2Primary", {
        Default = Color3.fromRGB(255, 160, 0),
    })
    Options.C_Multi2Secondary = Toggles.C_Multi2:AddColorPicker("C_Multi2Secondary", {
        Default = Color3.fromRGB(100, 60, 200),
    })
end

-- ================================================================
-- TAB: KEYBINDS (KeyPicker)
-- ================================================================
do
    local L = TabKeys:AddLeftSection("Toggle & Hold Modes", "key")
    local R = TabKeys:AddRightSection("Press & Always Modes", "zap")

    -- Toggle mode (latches)
    Toggles.K_Toggle = L:AddToggle("K_Toggle", {
        Text = "Toggle Mode",
        Default = false,
    })
    Toggles.K_Toggle:AddKeyPicker("K_TogglePick", {
        Default = "None",
        Mode = "Toggle",
        Text = "Key",
        Modes = { "Toggle", "Hold" },
        SyncToggleState = true,
    })

    -- Hold mode (active while held)
    Toggles.K_Hold = L:AddToggle("K_Hold", {
        Text = "Hold Mode",
        Default = false,
    })
    Toggles.K_Hold:AddKeyPicker("K_HoldPick", {
        Default = "None",
        Mode = "Hold",
        Text = "Key",
        Modes = { "Toggle", "Hold" },
    })

    -- Risky toggle with key
    Toggles.K_Risky = L:AddToggle("K_Risky", {
        Text = "Risky Keybind Toggle",
        Default = false,
        Risky = true,
    })
    Toggles.K_Risky:AddKeyPicker("K_RiskyPick", {
        Default = "None",
        Mode = "Toggle",
        Text = "Key",
        Modes = { "Toggle", "Hold" },
        SyncToggleState = true,
    })

    -- Always-active (bypasses key)
    Toggles.K_Always = L:AddToggle("K_Always", {
        Text = "Always Active",
        Default = false,
    })
    Toggles.K_Always:AddKeyPicker("K_AlwaysPick", {
        Default = "None",
        Mode = "Always",
        Text = "Key",
        Modes = { "Always", "Toggle", "Hold" },
    })

    -- Right: Press mode (momentary fire)
    local PressLabel = R:AddLabel("Press key to fire →")
    PressLabel:AddKeyPicker("K_PressA", {
        Default = "None",
        Mode = "Press",
        Text = "Key",
    })

    local PressLabel2 = R:AddLabel("Another press binding →")
    PressLabel2:AddKeyPicker("K_PressB", {
        Default = "None",
        Mode = "Press",
        Text = "Key",
    })

    R:AddDivider({ Text = "Toggle + KeyPicker Combos" })

    -- Multiple keybinds
    Toggles.K_Combo1 = R:AddToggle("K_Combo1", {
        Text = "Feature A",
        Default = false,
    })
    Toggles.K_Combo1:AddKeyPicker("K_Combo1Pick", {
        Default = "None",
        Mode = "Toggle",
        Text = "Key",
        Modes = { "Toggle", "Hold", "Always" },
        SyncToggleState = true,
    })

    Toggles.K_Combo2 = R:AddToggle("K_Combo2", {
        Text = "Feature B",
        Default = false,
    })
    Toggles.K_Combo2:AddKeyPicker("K_Combo2Pick", {
        Default = "None",
        Mode = "Hold",
        Text = "Key",
        Modes = { "Toggle", "Hold", "Always" },
    })
end

-- ================================================================
-- TAB: SECTIONS (full-width + left/right layout demo)
-- ================================================================
do
    -- Plain AddSection (no Side) spans the full width of the tab.
    local Full = TabSections:AddSection("Full-Width Section", "rows")
    Toggles.Sec_Full1 = Full:AddToggle("Sec_Full1", { Text = "Toggle in the full-width section", Default = false })
    Options.Sec_Full2 = Full:AddSlider("Sec_Full2", { Text = "Slider in the full-width section", Default = 50, Min = 0, Max = 100, Rounding = 0 })

    -- AddLeftSection / AddRightSection split the tab into two columns.
    local LA = TabSections:AddLeftSection("Left Section A", "layers")
    local LB = TabSections:AddLeftSection("Left Section B", "list")
    local RA = TabSections:AddRightSection("Right Section A", "columns")
    local RB = TabSections:AddRightSection("Right Section B", "list")

    Toggles.Sec_LA1 = LA:AddToggle("Sec_LA1", { Text = "Toggle in Left A", Default = false })
    Toggles.Sec_LA2 = LA:AddToggle("Sec_LA2", { Text = "Another toggle", Default = true })
    Options.Sec_LA3 = LA:AddSlider("Sec_LA3", { Text = "Slider in Left A", Default = 40, Min = 0, Max = 100, Rounding = 0 })

    Options.Sec_LB1 = LB:AddDropdown("Sec_LB1", {
        Text = "Dropdown in Left B",
        Default = "Alpha",
        Values = { "Alpha", "Beta", "Gamma", "Delta" },
    })
    Buttons.Sec_LB2 = LB:AddButton({
        Text = "Button in Left B",
        Func = function()
            Library:Notify({ Title = "Left B", Description = "Button clicked.", Time = 2 })
        end,
    })

    Toggles.Sec_RA1 = RA:AddToggle("Sec_RA1", { Text = "Toggle in Right A", Default = false })
    Options.Sec_RA2 = RA:AddInput("Sec_RA2", {
        Text = "Input in Right A",
        Default = "",
        Placeholder = "Enter text...",
        AllowEmpty = true,
    })
    Options.Sec_RA3 = RA:AddSlider("Sec_RA3", { Text = "Slider in Right A", Default = 75, Min = 0, Max = 100, Rounding = 0 })

    Buttons.Sec_RB1 = RB:AddButton({
        Text = "Button in Right B",
        Func = function()
            Library:Notify({ Title = "Right B", Description = "Clicked.", Time = 2 })
        end,
    })
    Options.Sec_RB2 = RB:AddDropdown("Sec_RB2", {
        Text = "Multi in Right B",
        Default = { "X", "Z" },
        Values = { "X", "Y", "Z", "W" },
        Multi = true,
    })
end

-- ================================================================
-- TAB: TABBOXES / SECTION GROUPS (collapsible)
-- ================================================================
do
    local GroupLeft  = TabTabboxes:AddLeftSectionGroup("Preset Profiles")
    local GroupRight = TabTabboxes:AddRightSectionGroup("Weapon Configs")

    -- Left group: 3 sub-tabs
    local SubFarm  = GroupLeft:AddTab("Farming")
    local SubPvP   = GroupLeft:AddTab("PvP")
    local SubSafe  = GroupLeft:AddTab("Safe Mode")

    Toggles.GB_FarmAuto = SubFarm:AddToggle("GB_FarmAuto", { Text = "Auto Farm", Default = true })
    Options.GB_FarmRange = SubFarm:AddSlider("GB_FarmRange", { Text = "Farm Radius", Default = 50, Min = 5, Max = 200, Rounding = 0, Suffix = " studs" })
    Options.GB_FarmTarget = SubFarm:AddDropdown("GB_FarmTarget", { Text = "Target", Default = "All", Values = { "Enemies", "Bosses", "Chests", "All" } })
    Buttons.GB_FarmBtn = SubFarm:AddButton({ Text = "Start Farming", Func = function()
        Library:Notify({ Title = "Farm", Description = "Auto farm started.", Time = 2 })
    end })

    Toggles.GB_PvPAura = SubPvP:AddToggle("GB_PvPAura", { Text = "Auto Aura", Default = false, Risky = true })
    Options.GB_PvPRange = SubPvP:AddSlider("GB_PvPRange", { Text = "Aura Range", Default = 12, Min = 3, Max = 40, Rounding = 0, Suffix = " studs" })
    Toggles.GB_PvPParry = SubPvP:AddToggle("GB_PvPParry", { Text = "Auto Parry", Default = false })
    Options.GB_PvPTarget = SubPvP:AddDropdown("GB_PvPTarget", { Text = "Target Priority", Default = "Nearest", Values = { "Nearest", "Lowest HP", "Highest HP" } })

    Toggles.GB_SafeAntiKB = SubSafe:AddToggle("GB_SafeAntiKB", { Text = "Anti Knockback", Default = false })
    Toggles.GB_SafeAntiRag = SubSafe:AddToggle("GB_SafeAntiRag", { Text = "Anti Ragdoll", Default = false })
    Options.GB_SafeSpeed = SubSafe:AddSlider("GB_SafeSpeed", { Text = "Safe Walk Speed", Default = 16, Min = 8, Max = 30, Rounding = 0 })

    -- Right group: 3 sub-tabs
    local SubSword = GroupRight:AddTab("Sword")
    local SubGun   = GroupRight:AddTab("Gun")
    local SubMagic = GroupRight:AddTab("Magic")

    Toggles.GB_SwordParry = SubSword:AddToggle("GB_SwordParry", { Text = "Auto Parry", Default = true })
    Options.GB_SwordSwing = SubSword:AddSlider("GB_SwordSwing", { Text = "Swing Speed", Default = 0.3, Min = 0.05, Max = 2.0, Rounding = 2, Suffix = "s" })
    Toggles.GB_SwordLunge = SubSword:AddToggle("GB_SwordLunge", { Text = "Auto Lunge", Default = false })
    SubSword:AddDivider({ Text = "Color" })
    Toggles.GB_SwordTrail = SubSword:AddToggle("GB_SwordTrail", { Text = "Sword Trail", Default = true })
    Options.GB_SwordTrailColor = Toggles.GB_SwordTrail:AddColorPicker("GB_SwordTrailColor", { Default = Color3.fromRGB(255, 220, 50) })

    Toggles.GB_GunAim = SubGun:AddToggle("GB_GunAim", { Text = "Silent Aim", Default = false, Risky = true })
    Options.GB_GunFOV = SubGun:AddSlider("GB_GunFOV", { Text = "FOV", Default = 60, Min = 5, Max = 180, Rounding = 0, Suffix = "°" })
    Options.GB_GunTarget = SubGun:AddDropdown("GB_GunTarget", { Text = "Target Part", Default = "Head", Values = { "Head", "HumanoidRootPart", "Torso", "Nearest" } })

    Toggles.GB_MagicAuto = SubMagic:AddToggle("GB_MagicAuto", { Text = "Auto Cast", Default = false })
    Options.GB_MagicCooldown = SubMagic:AddSlider("GB_MagicCooldown", { Text = "Cast Cooldown", Default = 1.0, Min = 0.1, Max = 5.0, Rounding = 1, Suffix = "s" })
    Toggles.GB_MagicAOE = SubMagic:AddToggle("GB_MagicAOE", { Text = "AOE Mode", Default = false })
    Options.GB_MagicColor = SubMagic:AddDropdown("GB_MagicColor", { Text = "Effect Color", Default = "Purple", Values = { "Purple", "Blue", "Red", "Gold", "White" } })
end

-- ================================================================
-- TAB: RICH TEXT
-- ================================================================
do
    local L = TabRichText:AddLeftSection("Labels & Buttons", "type")
    local R = TabRichText:AddRightSection("Tooltips & Notifications", "message-circle")

    -- Every TextLabel/TextButton created by the library has RichText enabled
    -- by default, so Roblox rich text tags work anywhere normal Text would go.
    L:AddLabel({
        Text = '<b>Bold</b>, <i>italic</i>, and <u>underline</u> all work inline.',
    })
    L:AddLabel({
        Text = '<font color="#FF5C5C">Colored</font> and <font color="#5CC8FF" size="20">resized</font> spans.',
    })
    L:AddLabel({
        Text = 'Mix styles: <b><i><font color="#9B5CFF">bold italic purple</font></i></b> text.',
    })

    L:AddDivider({ Text = "Buttons" })

    Buttons.RT_Colored = L:AddButton({
        Text = '<font color="#5CFF8F">Green</font> Button Label',
        Func = function()
            Library:Notify({ Title = "Rich Text", Description = "Button text supports tags too.", Time = 3 })
        end,
    })
    Buttons.RT_Bold = L:AddButton({
        Text = "<b>Bold Button Text</b>",
        Func = function() end,
    })

    L:AddDivider({ Text = "Toggle / Slider Text" })

    Toggles.RT_Toggle = L:AddToggle("RT_Toggle", {
        Text = '<font color="#FFC95C">Highlighted</font> toggle label',
        Default = false,
    })
    Options.RT_Slider = L:AddSlider("RT_Slider", {
        Text = '<i>Italic</i> slider label',
        Default = 50,
        Min = 0,
        Max = 100,
        Rounding = 0,
    })

    -- Right column: tooltips & notifications
    R:AddLabel({ Text = "Hover the button below — tooltips render rich text too." })
    Buttons.RT_Tooltip = R:AddButton({
        Text = "Hover Me",
        Tooltip = '<b>Heads up:</b> tooltips use the same <font color="#5CC8FF">rich text</font> engine.',
        Func = function() end,
    })

    R:AddDivider({ Text = "Notifications" })

    Buttons.RT_Notify = R:AddButton({
        Text = "Rich Text Notification",
        Func = function()
            Library:Notify({
                Title = "Formatted Notification",
                Description = 'This notification has <b>bold</b>, <i>italic</i>, and <font color="#FF8F5C">colored</font> text.',
                Time = 5,
            })
        end,
    })
    Buttons.RT_NotifyIcon = R:AddButton({
        Text = "Rich Text + Icon",
        Func = function()
            Library:Notify({
                Title = "Success",
                Description = '<font color="#5CFF8F">Operation completed</font> without errors.',
                Icon = "check-circle",
                Time = 4,
            })
        end,
    })
end

-- ================================================================
-- TAB: VIEWPORTS & MEDIA
-- ================================================================
do
    local L = TabViewports:AddLeftSection("3D Viewport", "box")
    local R = TabViewports:AddRightSection("Images", "image")

    -- Build a small demo model so AddViewport has something to render.
    local DemoModel = Instance.new("Model")
    DemoModel.Name = "ViewportDemo"

    local Base = Instance.new("Part")
    Base.Name = "Base"
    Base.Size = Vector3.new(4, 1, 4)
    Base.Color = Color3.fromRGB(60, 60, 70)
    Base.Material = Enum.Material.SmoothPlastic
    Base.Anchored = true
    Base.CanCollide = false
    Base.Parent = DemoModel

    local Pillar = Instance.new("Part")
    Pillar.Name = "Pillar"
    Pillar.Size = Vector3.new(1, 3, 1)
    Pillar.CFrame = Base.CFrame * CFrame.new(0, 2, 0)
    Pillar.Color = Color3.fromRGB(90, 140, 255)
    Pillar.Material = Enum.Material.Neon
    Pillar.Anchored = true
    Pillar.CanCollide = false
    Pillar.Parent = DemoModel

    DemoModel.PrimaryPart = Base

    L:AddLabel({ Text = "Drag to orbit, scroll to zoom (Interactive = true)." })
    Options.VP_Demo = L:AddViewport("VP_Demo", {
        Object = DemoModel,
        Clone = true,
        AutoFocus = true,
        Interactive = true,
        Height = 220,
    })

    L:AddDivider({ Text = "Controls" })

    Buttons.VP_Refocus = L:AddButton({
        Text = "Re-focus Camera",
        Func = function()
            if Options.VP_Demo then
                Options.VP_Demo:Focus()
            end
        end,
    })
    Toggles.VP_Interactive = L:AddToggle("VP_Interactive", {
        Text = "Interactive (drag/zoom)",
        Default = true,
        Callback = function(Value)
            if Options.VP_Demo then
                Options.VP_Demo:SetInteractive(Value)
            end
        end,
    })

    -- Right column: image elements (uses bundled + lucide icons through AddImage)
    R:AddLabel({ Text = "AddImage accepts asset ids, URLs, or lucide icon names." })
    Options.IMG_Lucide = R:AddImage("IMG_Lucide", {
        Image = "image",
        Height = 90,
        ScaleType = Enum.ScaleType.Fit,
    })
    R:AddDivider({ Text = "Color tint" })
    Options.IMG_Tinted = R:AddImage("IMG_Tinted", {
        Image = "star",
        Color = Color3.fromRGB(255, 196, 60),
        Height = 90,
        ScaleType = Enum.ScaleType.Fit,
    })
end

-- ================================================================
-- TAB: LOADING SCREEN
-- ================================================================
do
    local L = TabLoading:AddLeftSection("Standalone Loading Screen", "loader")

    L:AddLabel({
        Text = "Opens a separate loading window (independent of the main UI), steps through progress, then closes itself.",
        DoesWrap = true,
    })

    Buttons.LS_Run = L:AddButton({
        Text = "Run Loading Screen Demo",
        Func = function()
            if Library.ActiveLoading then
                return
            end

            local Loading = Library:CreateLoading({
                Title = "Astral Demo",
                TotalSteps = 4,
                CurrentStep = 0,
                ShowSidebar = false,
                AutoResizeHeight = true,
            })

            Loading:SetMessage("Initializing...")
            Loading:SetDescription("Setting up the demo environment.")

            task.spawn(function()
                local Steps = {
                    { Message = "Loading assets...",      Description = "Fetching UI assets and icons." },
                    { Message = "Building interface...",  Description = "Constructing tabs and sections." },
                    { Message = "Applying theme...",       Description = "Resolving color scheme." },
                    { Message = "Finishing up...",         Description = "Almost there." },
                }

                for i, Step in Steps do
                    task.wait(0.8)
                    if Loading.Destroyed then
                        return
                    end
                    Loading:SetCurrentStep(i)
                    Loading:SetMessage(Step.Message)
                    Loading:SetDescription(Step.Description)
                end

                task.wait(0.6)
                if not Loading.Destroyed then
                    Loading:Destroy()
                    Library:Notify({ Title = "Loading", Description = "Loading screen demo finished.", Time = 3 })
                end
            end)
        end,
    })

    Buttons.LS_Error = L:AddButton({
        Text = "Run Loading Screen (Error State)",
        Func = function()
            if Library.ActiveLoading then
                return
            end

            local Loading = Library:CreateLoading({
                Title = "Astral Demo",
                TotalSteps = 3,
                CurrentStep = 0,
            })

            Loading:SetMessage("Connecting...")
            Loading:SetDescription("Reaching out to the server.")

            task.spawn(function()
                task.wait(1)
                if Loading.Destroyed then
                    return
                end
                Loading:SetCurrentStep(1)
                Loading:SetMessage("Verifying...")

                task.wait(1)
                if Loading.Destroyed then
                    return
                end

                Loading:ShowErrorPage(true)
                Loading:SetErrorMessage("Could not verify connection. This is a simulated failure for the demo.")
                Loading:SetErrorButtons({
                    {
                        Title = "Close",
                        Callback = function()
                            if not Loading.Destroyed then
                                Loading:Destroy()
                            end
                        end,
                    },
                })
            end)
        end,
    })
end

-- ================================================================
-- TAB: LONG TEXT / TRUNCATION
-- ================================================================
do
    local L = TabTruncate:AddLeftSection("Overflowing Text", "scissors")
    local R = TabTruncate:AddRightSection("Wrapped Text", "wrap-text")

    local LongTitle =
        "This Is An Extremely Long Toggle Label That Would Normally Overflow Past The Edge Of The Panel"
    local LongValue = "An Unreasonably Long Selected Dropdown Value For Testing Purposes"

    L:AddLabel({ Text = "All of these intentionally use very long strings to show truncation:" })

    Toggles.LT_Toggle = L:AddToggle("LT_Toggle", {
        Text = LongTitle,
        Default = false,
        Tooltip = LongTitle,
    })
    Options.LT_Slider = L:AddSlider("LT_Slider", {
        Text = LongTitle,
        Default = 10,
        Min = 0,
        Max = 100,
    })
    Buttons.LT_Button = L:AddButton({
        Text = LongTitle,
        Func = function() end,
    })
    Options.LT_Dropdown = L:AddDropdown("LT_Dropdown", {
        Text = LongTitle,
        Default = LongValue,
        Values = { LongValue, "Short", "Another Reasonably Long Value Here" },
    })

    L:AddDivider({ Text = "Section / Tab Names" })
    L:AddLabel({
        Text = "Tab and tabbox section names truncate the same way — see the sidebar entry for this tab if its name were longer than the panel.",
        DoesWrap = true,
    })

    -- Right column: text that wraps instead of truncating
    R:AddLabel({ Text = "Switch to DoesWrap = true and text grows downward instead of cutting off:" })
    R:AddLabel({
        Text = "This label has DoesWrap enabled, so this long sentence will wrap onto multiple lines rather than being truncated with an ellipsis, growing the section to fit.",
        DoesWrap = true,
    })
end

-- ================================================================
-- TAB: OVERLAYS (draggable screen widgets + Keybinds list)
-- ================================================================
do
    local L = TabOverlays:AddLeftSection("Floating Widgets", "picture-in-picture-2")
    local R = TabOverlays:AddRightSection("Keybinds Overlay", "key")

    L:AddLabel({
        Text = "These float on top of the whole screen (not inside the window) and can be dragged anywhere.",
        DoesWrap = true,
    })

    L:AddDivider({ Text = "Draggable Label" })

    local OverlayLabel
    Toggles.OV_Label = L:AddToggle("OV_Label", {
        Text = "Show Draggable Label",
        Default = false,
        Callback = function(Value)
            if Value then
                if not OverlayLabel then
                    OverlayLabel = Library:AddDraggableLabel("Drag me around!")
                end
                OverlayLabel:SetVisible(true)
            elseif OverlayLabel then
                OverlayLabel:SetVisible(false)
            end
        end,
    })

    L:AddDivider({ Text = "Draggable Button" })

    local OverlayButton
    Toggles.OV_Button = L:AddToggle("OV_Button", {
        Text = "Show Draggable Button",
        Default = false,
        Callback = function(Value)
            if Value then
                if not OverlayButton then
                    OverlayButton = Library:AddDraggableButton("Click Me", function()
                        Library:Notify({ Title = "Overlay", Description = "Draggable button clicked.", Time = 2 })
                    end)
                end
                OverlayButton.Button.Visible = true
            elseif OverlayButton then
                OverlayButton.Button.Visible = false
            end
        end,
    })

    L:AddDivider({ Text = "Draggable Menu" })

    local OverlayMenu, OverlayMenuContainer
    Toggles.OV_Menu = L:AddToggle("OV_Menu", {
        Text = "Show Draggable Menu",
        Default = false,
        Callback = function(Value)
            if Value then
                if not OverlayMenu then
                    OverlayMenu, OverlayMenuContainer = Library:AddDraggableMenu("Stats")
                    OverlayMenu.AnchorPoint = Vector2.new(1, 0)
                    OverlayMenu.Position = UDim2.new(1, -6, 0, 6)

                    for _, Row in { "FPS: 60", "Ping: 24ms", "Players: 12" } do
                        New("TextLabel", {
                            BackgroundTransparency = 1,
                            Size = UDim2.new(0, 200, 0, 16),
                            Text = Row,
                            TextSize = 14,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            Parent = OverlayMenuContainer,
                        })
                    end
                end
                OverlayMenu.Visible = true
            elseif OverlayMenu then
                OverlayMenu.Visible = false
            end
        end,
    })

    -- Right column: the library's built-in floating Keybinds list.
    -- Every AddKeyPicker automatically gets a row in here.
    R:AddLabel({
        Text = "Every KeyPicker you add (see the Keybinds tab) automatically gets a row in this floating list.",
        DoesWrap = true,
    })

    Toggles.OV_KeybindsFrame = R:AddToggle("OV_KeybindsFrame", {
        Text = "Show Keybinds Overlay",
        Default = false,
        Callback = function(Value)
            if Library.KeybindFrame then
                Library.KeybindFrame.Visible = Value
            end
        end,
    })
end

-- ================================================================
-- TAB: DIALOGS & NOTIFICATIONS
-- ================================================================
do
    local L = TabDialogs:AddLeftSection("Notifications", "bell")
    local R = TabDialogs:AddRightSection("Dialogs", "message-square")

    -- Basic notify
    Buttons.N_Basic = L:AddButton({
        Text = "Basic Notification",
        Func = function()
            Library:Notify({ Title = "Notification", Description = "This is a basic notification.", Time = 3 })
        end,
    })

    -- With icon
    Buttons.N_Icon = L:AddButton({
        Text = "Notification with Icon",
        Func = function()
            Library:Notify({ Title = "With Icon", Description = "This one has a star icon.", Icon = "star", Time = 3 })
        end,
    })

    -- Short duration
    Buttons.N_Short = L:AddButton({
        Text = "Short Notification (1s)",
        Func = function()
            Library:Notify({ Title = "Quick!", Description = "Gone in 1 second.", Time = 1 })
        end,
    })

    -- Long duration
    Buttons.N_Long = L:AddButton({
        Text = "Long Notification (8s)",
        Func = function()
            Library:Notify({ Title = "Long Notice", Description = "This stays for 8 seconds.", Time = 8 })
        end,
    })

    L:AddDivider({ Text = "Multiple at Once" })

    Buttons.N_Multi = L:AddButton({
        Text = "Fire 3 Notifications",
        Func = function()
            Library:Notify({ Title = "First",  Description = "Notification #1", Time = 4 })
            task.wait(0.1)
            Library:Notify({ Title = "Second", Description = "Notification #2", Icon = "check", Time = 4 })
            task.wait(0.1)
            Library:Notify({ Title = "Third",  Description = "Notification #3", Icon = "alert-triangle", Time = 4 })
        end,
    })

    -- Right: Dialogs
    Buttons.D_Basic = R:AddButton({
        Text = "Basic Dialog",
        Func = function()
            Window:AddDialog("BasicDialog", {
                Title = "Basic Dialog",
                Description = "This is a basic dialog with two buttons.",
                FooterButtons = {
                    { Title = "Cancel",  Variant = "Secondary",    Callback = function(d) d:Dismiss() end },
                    { Title = "OK",      Variant = "Primary",      Callback = function(d)
                        d:Dismiss()
                        Library:Notify({ Title = "Dialog", Description = "OK pressed.", Time = 2 })
                    end },
                },
            })
        end,
    })

    Buttons.D_Destructive = R:AddButton({
        Text = "Destructive Confirm Dialog",
        Risky = true,
        Func = function()
            Window:AddDialog("DestrDialog", {
                Title = "Confirm Reset",
                Description = "Are you sure you want to reset all settings? This cannot be undone.",
                FooterButtons = {
                    { Title = "Cancel", Variant = "Secondary",    Callback = function(d) d:Dismiss() end },
                    { Title = "Reset",  Variant = "Destructive",  Callback = function(d)
                        d:Dismiss()
                        Library:Notify({ Title = "Reset", Description = "Settings reset to defaults.", Time = 3 })
                    end },
                },
            })
        end,
    })

    Buttons.D_NoClose = R:AddButton({
        Text = "Dialog (no outside dismiss)",
        Func = function()
            Window:AddDialog("NoCloseDialog", {
                Title = "Required Choice",
                Description = "You must click a button — clicking outside will not dismiss.",
                OutsideClickDismiss = false,
                FooterButtons = {
                    { Title = "Accept", Variant = "Primary",    Callback = function(d)
                        d:Dismiss()
                        Library:Notify({ Title = "Accepted", Description = "Choice made.", Time = 2 })
                    end },
                    { Title = "Reject", Variant = "Destructive", Callback = function(d)
                        d:Dismiss()
                        Library:Notify({ Title = "Rejected", Description = "Dismissed.", Time = 2 })
                    end },
                },
            })
        end,
    })

    Buttons.D_ThreeBtn = R:AddButton({
        Text = "3-Button Dialog",
        Func = function()
            Window:AddDialog("ThreeBtnDialog", {
                Title = "Save Changes?",
                Description = "You have unsaved changes. Would you like to save before leaving?",
                FooterButtons = {
                    { Title = "Don't Save", Variant = "Destructive", Callback = function(d)
                        d:Dismiss()
                        Library:Notify({ Title = "Discarded", Description = "Changes not saved.", Time = 2 })
                    end },
                    { Title = "Cancel", Variant = "Secondary", Callback = function(d) d:Dismiss() end },
                    { Title = "Save",   Variant = "Primary",   Callback = function(d)
                        d:Dismiss()
                        Library:Notify({ Title = "Saved", Description = "Changes saved!", Time = 2 })
                    end },
                },
            })
        end,
    })

    R:AddDivider({ Text = "Icons, Color & Rich Text" })

    Buttons.D_IconColor = R:AddButton({
        Text = "Dialog with Icon + Colored Title",
        Func = function()
            Window:AddDialog("IconColorDialog", {
                Title = "Update Available",
                Icon = "download",
                TitleColor = Color3.fromRGB(90, 200, 255),
                Description = "A new version is ready to install. The window dims behind the dialog (the overlay) while it's open.",
                FooterButtons = {
                    { Title = "Later",   Variant = "Secondary", Callback = function(d) d:Dismiss() end },
                    { Title = "Install", Variant = "Primary",   Callback = function(d)
                        d:Dismiss()
                        Library:Notify({ Title = "Update", Description = "Installing update...", Time = 2 })
                    end },
                },
            })
        end,
    })

    Buttons.D_RichText = R:AddButton({
        Text = "Dialog with Rich Text Body",
        Func = function()
            Window:AddDialog("RichTextDialog", {
                Title = "Formatted Description",
                Description = 'This dialog body supports <b>bold</b>, <i>italic</i>, and <font color="#FF8F5C">colored</font> text, same as every other label in the library.',
                FooterButtons = {
                    { Title = "Got it", Variant = "Primary", Callback = function(d) d:Dismiss() end },
                },
            })
        end,
    })
end

-- ================================================================
-- TAB: CONFIG (SaveManager + ThemeManager)
-- ================================================================
do
    -- SaveManager builds its own config section UI (profile list, save/load/delete
    -- buttons, autoload management) directly into the tab's left column.
    SaveManager:BuildConfigSection(TabConfig)

    -- ThemeManager builds its colour pickers, font selector, built-in theme
    -- dropdown, and custom theme management into the tab's right column.
    ThemeManager:ApplyToTab(TabConfig)
end

--// Restore the autoloaded config (if any) before showing the window.
SaveManager:LoadAutoloadConfig()

--// Show the window
Library:Toggle(true)

--// Initial notification
task.delay(0.5, function()
    Library:Notify({
        Title = "Astral UI Demo",
        Description = "Press RightControl to toggle. Explore every tab to see all elements.",
        Time = 6,
    })
end)

end -- Demo arg check

return Library