local cloneref = (cloneref or clonereference or function(instance: any)
    return instance
end)
local clonefunction = (clonefunction or copyfunction or function(func)
    return func
end)

local HttpService: HttpService = cloneref(game:GetService("HttpService"))
local Players: Players = cloneref(game:GetService("Players"))
local isfolder, isfile, listfiles = isfolder, isfile, listfiles

if typeof(clonefunction) == "function" then

    local
        isfolder_copy,
        isfile_copy,
        listfiles_copy = clonefunction(isfolder), clonefunction(isfile), clonefunction(listfiles)

    local isfolder_success, isfolder_error = pcall(function()
        return isfolder_copy("test" .. tostring(math.random(1000000, 9999999)))
    end)

    if isfolder_success == false or typeof(isfolder_error) ~= "boolean" then
        isfolder = function(folder)
            local success, data = pcall(isfolder_copy, folder)
            return (if success then data else false)
        end

        isfile = function(file)
            local success, data = pcall(isfile_copy, file)
            return (if success then data else false)
        end

        listfiles = function(folder)
            local success, data = pcall(listfiles_copy, folder)
            return (if success then data else {})
        end
    end
end

local function GetDefaultConfigName()
    local player = Players.LocalPlayer
    local name = player and player.Name or "Player"

    name = name:gsub("[^%w_%-]", "")
    if name == "" then name = "Player" end

    return name .. "_Settings"
end

local SaveManager = {}
do
    SaveManager.Folder = "Astral"
    SaveManager.SubFolder = ""
    SaveManager.Ignore = {}
    SaveManager.Library = nil

    SaveManager.LoadingOrder = {}
    SaveManager.UseLoadingOrder = false

    SaveManager.AutoloadConfig = nil

    SaveManager.CurrentConfig = nil
    SaveManager._Loading = false

    local function EncodeUDim2(Value: UDim2)
        return {
            X = { Scale = Value.X.Scale, Offset = Value.X.Offset },
            Y = { Scale = Value.Y.Scale, Offset = Value.Y.Offset },
        }
    end

    local function DecodeUDim2(Data: any)
        local DataType = typeof(Data)
        if DataType == "table" then
            return UDim2.new(Data.X.Scale, Data.X.Offset, Data.Y.Scale, Data.Y.Offset)
        elseif DataType == "UDim2" then
            return Data
        end

        return nil
    end

    SaveManager.Parser = {
        Toggle = {
            Save = function(object)
                return object.Value
            end,
            Load = function(object, value)
                if object.Value == value then
                    object:RunChanged()
                    return
                end

                object:SetValue(value)
            end,
        },
        Slider = {
            Save = function(object)
                return tostring(object.Value)
            end,
            Load = function(object, value)
                if object.Value == value then
                    object:RunChanged()
                    return
                end

                object:SetValue(value)
            end,
        },
        ProgressBar = {
            Save = function(object)
                return tostring(object.Value)
            end,
            Load = function(object, value)
                if object.Value == value then
                    return
                end

                object:SetValue(value)
            end,
        },
        Dropdown = {
            Save = function(object)
                return object.Value
            end,
            Load = function(object, value)
                if object.Value == value then
                    object:RunChanged()
                    return
                end

                object:SetValue(value)
            end,
        },
        ColorPicker = {
            Save = function(object)
                return { value = object.Value:ToHex(), transparency = object.Transparency }
            end,
            Load = function(object, value)
                object:SetValueRGB(Color3.fromHex(value.value), value.transparency)
            end,
        },
        KeyPicker = {
            Save = function(object)
                return {
                    mode = object.Mode,
                    key = object.Value,
                    modifiers = object.Modifiers,
                }
            end,
            Load = function(object, value)
                if type(value) ~= "table" then return end

                local key = value.key
                local mode = value.mode or object.Mode or object.DefaultMode
                local modifiers = value.modifiers

                object:SetValue({ Key = key, Mode = mode, Modifiers = modifiers })
            end,
        },
        Input = {
            Save = function(object)
                return object.Value
            end,
            Load = function(object, value)
                if object.Value ~= value and type(value) == "string" then
                    object:SetValue(value)
                end
            end,
        },
    }

    function SaveManager:SetLibrary(Library)
        self.Library = Library

        if Library and typeof(Library) == "table" then
            if Library.Toggled then
                warn("[SaveManager] SetLibrary() was called AFTER Library:CreateWindow(). " ..
                    "The window may have already auto-shown with default/unloaded values. " ..
                    "Call SaveManager:SetLibrary(Library) BEFORE Library:CreateWindow(...) instead.")
            end

            Library.DeferAutoShowTo = self
        end
    end

    function SaveManager:IgnoreThemeSettings()
        self:SetIgnoreIndexes({
            "BackgroundColor", "MainColor", "AccentColor", "OutlineColor", "FontColor", "FontFace",
            "ThemeManager_ThemeList", "ThemeManager_CustomThemeList", "ThemeManager_CustomThemeName",
        })
    end

    function SaveManager:CheckSubFolder(CreateFolder)
        if typeof(self.SubFolder) ~= "string" or self.SubFolder == "" then return false end

        if CreateFolder == true then
            if not isfolder(self.Folder .. "/settings/" .. self.SubFolder) then
                makefolder(self.Folder .. "/settings/" .. self.SubFolder)
            end
        end

        return true
    end

    function SaveManager:GetPaths()
        local paths = {}

        local parts = self.Folder:split("/")
        for idx = 1, #parts do
            local path = table.concat(parts, "/", 1, idx)
            if not table.find(paths, path) then paths[#paths + 1] = path end
        end

        paths[#paths + 1] = self.Folder .. "/settings"

        if self:CheckSubFolder(false) then
            local subFolder = self.Folder .. "/settings/" .. self.SubFolder
            parts = subFolder:split("/")

            for idx = 1, #parts do
                local path = table.concat(parts, "/", 1, idx)
                if not table.find(paths, path) then paths[#paths + 1] = path end
            end
        end

        return paths
    end

    function SaveManager:BuildFolderTree()
        local paths = self:GetPaths()

        for i = 1, #paths do
            local str = paths[i]
            if isfolder(str) then continue end

            makefolder(str)
        end
    end

    function SaveManager:CheckFolderTree()
        if isfolder(self.Folder) then return end
        SaveManager:BuildFolderTree()

        task.wait(0.1)
    end

    function SaveManager:SetIgnoreIndexes(list)
        for _, key in pairs(list) do
            self.Ignore[key] = true
        end
    end

    function SaveManager:SetFolder(folder)
        self.Folder = folder
        self:BuildFolderTree()
    end

    function SaveManager:SetSubFolder(folder)
        self.SubFolder = folder
        self:BuildFolderTree()
    end

    function SaveManager:GetFilePath(name)
        local file = self.Folder .. "/settings/" .. name .. ".json"
        if self:CheckSubFolder(true) then
            file = self.Folder .. "/settings/" .. self.SubFolder .. "/" .. name .. ".json"
        end
        return file
    end

    function SaveManager:SetLoadingOrder(Enabled: boolean, Order: { string }?)
        SaveManager.UseLoadingOrder = Enabled == true
        SaveManager.LoadingOrder = typeof(Order) == "table" and Order or SaveManager.LoadingOrder
    end

    function SaveManager:Save(name)
        if not name or name:gsub(" ", "") == "" then
            return false, "no config file is selected"
        end
        if string.lower(name) == "autoload" then
            return false, "Invalid config name provided"
        end
        self:CheckFolderTree()

        local fullPath = self:GetFilePath(name)

        local data = {}

        for idx, toggle in pairs(self.Library.Toggles) do
            if not toggle.Type then continue end
            if not self.Parser[toggle.Type] then continue end
            if self.Ignore[idx] then continue end

            data[idx] = self.Parser[toggle.Type].Save(toggle)
        end

        for idx, option in pairs(self.Library.Options) do
            if not option.Type then continue end
            if not self.Parser[option.Type] then continue end
            if self.Ignore[idx] then continue end

            data[idx] = self.Parser[option.Type].Save(option)
        end

        --// Keybind menu state
        if self.Library.KeybindFrame then
            local Hidden = {}
            for Index, Option in self.Library.Options do
                if Option.Type == "KeyPicker" and Option.NoUI ~= true and Option.MenuVisible == false then
                    Hidden[Index] = true
                end
            end

            local KeybindMenu = self.Library.KeybindMenu
            local Collapsed = false
            if KeybindMenu and KeybindMenu.IsCollapsed then
                Collapsed = KeybindMenu:IsCollapsed() == true
            elseif self.Library.KeybindContainer then
                Collapsed = not self.Library.KeybindContainer.Visible
            end

            data.__keybindMenu = {
                visible = self.Library.KeybindFrame.Visible,
                position = EncodeUDim2(self.Library.KeybindFrame.Position),
                collapsed = Collapsed,
                hidden = Hidden,
            }
        end

        --// Section folded states
        if self.Library.Tabs then
            local FoldedSections = {}
            for TabIndex, Tab in self.Library.Tabs do
                if typeof(Tab) ~= "table" or Tab.IsKeyTab or not Tab.Sections then continue end

                for SectionIndex, Section in Tab.Sections do
                    if typeof(Section) ~= "table" or Section.Folded ~= true then continue end
                    if typeof(Section.SetFolded) ~= "function" then continue end

                    table.insert(FoldedSections, {
                        tabIdx = typeof(TabIndex) == "string" and TabIndex or Tab.Name,
                        idx = typeof(SectionIndex) == "string" and SectionIndex or Section.Name,
                    })
                end
            end

            if next(FoldedSections) then
                data.__foldedSections = FoldedSections
            end
        end

        local success, encoded = pcall(HttpService.JSONEncode, HttpService, data)
        if not success then
            return false, "failed to encode data"
        end

        writefile(fullPath, encoded)
        return true
    end

    function SaveManager:Load(name)
        if not name or name:gsub(" ", "") == "" then
            return false, "no config file is selected"
        end
        self:CheckFolderTree()

        local file = self:GetFilePath(name)
        if not isfile(file) then return false, "invalid file" end

        local success, decoded = pcall(HttpService.JSONDecode, HttpService, readfile(file))
        if not success then return false, "decode error" end

        self._Loading = true

        --// Keybind menu state
        if typeof(decoded.__keybindMenu) == "table" and self.Library.KeybindFrame then
            local MenuData = decoded.__keybindMenu

            self.Library.KeybindFrame.Visible = MenuData.visible == true

            local Position = DecodeUDim2(MenuData.position)
            if Position then
                self.Library.KeybindFrame.Position = Position
            end

            if self.Library.KeybindContainer then
                self.Library.KeybindContainer.Visible = MenuData.collapsed ~= true
            end

            local KeybindMenu = self.Library.KeybindMenu
            if KeybindMenu and KeybindMenu.SetCollapsed then
                KeybindMenu:SetCollapsed(MenuData.collapsed == true)
            end

            if typeof(MenuData.hidden) == "table" then
                for Index, Option in self.Library.Options do
                    if Option.Type ~= "KeyPicker" or Option.NoUI == true or not Option.SetMenuVisibility then
                        continue
                    end

                    Option:SetMenuVisibility(MenuData.hidden[Index] ~= true)
                end
            end
        end

        --// Section folded states
        if typeof(decoded.__foldedSections) == "table" and self.Library.Tabs then
            for _, Entry in decoded.__foldedSections do
                if typeof(Entry) ~= "table" then continue end

                local Tab = self.Library.Tabs[Entry.tabIdx]
                if typeof(Tab) ~= "table" or not Tab.Sections then continue end

                local Section = Tab.Sections[Entry.idx]
                if typeof(Section) ~= "table" or typeof(Section.SetFolded) ~= "function" then
                    --// Fall back to matching by section name
                    for _, Candidate in Tab.Sections do
                        if typeof(Candidate) == "table" and Candidate.Name == Entry.idx and typeof(Candidate.SetFolded) == "function" then
                            Section = Candidate
                            break
                        end
                    end
                end

                if typeof(Section) == "table" and typeof(Section.SetFolded) == "function" then
                    Section:SetFolded(true)
                end
            end
        end

        --// Elements (optionally in a caller-defined type order)
        local Queue = {}
        for idx, value in pairs(decoded) do
            if self.Ignore[idx] then continue end
            if idx == "__keybindMenu" or idx == "__foldedSections" then continue end

            local object = self.Library.Toggles[idx] or self.Library.Options[idx]
            if object and object.Type and self.Parser[object.Type] then
                table.insert(Queue, { object = object, value = value })
            end
        end

        if SaveManager.UseLoadingOrder == true and typeof(SaveManager.LoadingOrder) == "table" then
            table.sort(Queue, function(a, b)
                local aIndex = table.find(SaveManager.LoadingOrder, a.object.Type) or math.huge
                local bIndex = table.find(SaveManager.LoadingOrder, b.object.Type) or math.huge
                return aIndex < bIndex
            end)
        end

        for _, Entry in Queue do
            pcall(self.Parser[Entry.object.Type].Load, Entry.object, Entry.value)
        end

        task.defer(function()
            self._Loading = false
        end)

        self.CurrentConfig = name
        return true
    end

    function SaveManager:Delete(name)
        if not name or name:gsub(" ", "") == "" then
            return false, "no config file is selected"
        end

        local file = self:GetFilePath(name)
        if not isfile(file) then return false, "invalid file" end

        local success = pcall(delfile, file)
        if not success then return false, "delete file error" end

        if name == SaveManager.AutoloadConfig then
            SaveManager:DeleteAutoloadConfig()
        end

        return true
    end

    function SaveManager:RefreshConfigList()
        local success, data = pcall(function()
            self:CheckFolderTree()

            local list = {}
            local out = {}

            if self:CheckSubFolder(true) then
                list = listfiles(self.Folder .. "/settings/" .. self.SubFolder)
            else
                list = listfiles(self.Folder .. "/settings")
            end
            if typeof(list) ~= "table" then list = {} end

            for i = 1, #list do
                local file = list[i]
                if file:sub(-5) == ".json" then
                    local pos = file:find(".json", 1, true)
                    local start = pos

                    local char = file:sub(pos, pos)
                    while char ~= "/" and char ~= "\\" and char ~= "" do
                        pos = pos - 1
                        char = file:sub(pos, pos)
                    end

                    if char == "/" or char == "\\" then
                        local name = file:sub(pos + 1, start - 1)
                        if name ~= "autoload" then
                            table.insert(out, name)
                        end
                    end
                end
            end

            table.sort(out, function(a, b) return a:lower() < b:lower() end)

            return out
        end)

        if not success then
            if self.Library then
                self.Library:Notify({ Title = "SaveManager", Description = "Failed to load config list: " .. tostring(data), Time = 4 })
            else
                warn("Failed to load config list: " .. tostring(data))
            end

            return {}
        end

        return data
    end

    function SaveManager:RefreshDropdown()
        local dropdown = self.Library.Options.SaveManager_ConfigList
        if not dropdown then return end

        local list = self:RefreshConfigList()
        dropdown:SetValues(list)

        if self.CurrentConfig and table.find(list, self.CurrentConfig) then
            dropdown.Value = self.CurrentConfig
            dropdown:Display()
        end
    end

    function SaveManager:GetAutoloadConfig()
        self:CheckFolderTree()

        local folder = self.Folder .. "/settings"
        if self:CheckSubFolder(false) then
            folder = self.Folder .. "/settings/" .. self.SubFolder
        end

        local autoloadPath = folder .. "/autoload.txt"
        if not isfile(autoloadPath) then
            return "none", false, "Autoload config is not set"
        end

        local success, name = pcall(readfile, autoloadPath)
        if not (success and typeof(name) == "string") then
            return "none", false, name
        end

        local file = self:GetFilePath(name)
        if not isfile(file) then
            return "none", false, "Config file not found"
        end

        SaveManager.AutoloadConfig = name
        return name, true
    end

    function SaveManager:SaveAutoloadConfig(name)
        if not name or name:gsub(" ", "") == "" then
            return false, "No config is selected"
        end
        self:CheckFolderTree()

        local folder = self.Folder .. "/settings"
        if self:CheckSubFolder(false) then
            folder = self.Folder .. "/settings/" .. self.SubFolder
        end

        if not isfile(self:GetFilePath(name)) then
            return false, "Config does not exist"
        end

        local success, err = pcall(writefile, folder .. "/autoload.txt", name)
        if not success then
            return false, err
        end

        SaveManager.AutoloadConfig = name
        return true
    end

    function SaveManager:LoadAutoloadConfig()
        local name, success, err = self:GetAutoloadConfig()
        if not success then
            if err ~= "Autoload config is not set" then
                self.Library:Notify({ Title = "SaveManager", Description = "Failed to load autoload config: " .. tostring(err), Time = 4 })
            end

            return
        end

        local loadSuccess, loadErr = self:Load(name)
        if not loadSuccess then
            self.Library:Notify({ Title = "SaveManager", Description = "Failed to load autoload config: " .. tostring(loadErr), Time = 4 })
            return
        end

        self.Library:Notify({ Title = "SaveManager", Description = string.format("Successfully loaded autoload config %q.", name), Time = 3 })
    end

    function SaveManager:DeleteAutoloadConfig()
        self:CheckFolderTree()

        local folder = self.Folder .. "/settings"
        if self:CheckSubFolder(false) then
            folder = self.Folder .. "/settings/" .. self.SubFolder
        end

        local autoloadPath = folder .. "/autoload.txt"
        if not isfile(autoloadPath) then
            return false, "Autoload config is not set"
        end

        local success, err = pcall(delfile, autoloadPath)
        if not success then
            return false, err
        end

        SaveManager.AutoloadConfig = nil
        return true
    end

    function SaveManager:SaveJSON()
        local data = {}

        for idx, toggle in pairs(self.Library.Toggles) do
            if not toggle.Type then continue end
            if not self.Parser[toggle.Type] then continue end
            if self.Ignore[idx] then continue end

            data[idx] = self.Parser[toggle.Type].Save(toggle)
        end

        for idx, option in pairs(self.Library.Options) do
            if not option.Type then continue end
            if not self.Parser[option.Type] then continue end
            if self.Ignore[idx] then continue end

            data[idx] = self.Parser[option.Type].Save(option)
        end

        local success, encoded = pcall(HttpService.JSONEncode, HttpService, data)
        if not success then
            return nil, false, "Failed to encode data"
        end

        return encoded, true
    end

    function SaveManager:LoadJSON(content)
        if not content or content:gsub(" ", "") == "" then
            return false, "No JSON provided"
        end

        local success, decoded = pcall(HttpService.JSONDecode, HttpService, content)
        if not success or typeof(decoded) ~= "table" then
            return false, "Failed to decode config data"
        end

        self._Loading = true

        local Queue = {}
        for idx, value in pairs(decoded) do
            if self.Ignore[idx] then continue end
            if idx == "__keybindMenu" or idx == "__foldedSections" then continue end

            local object = self.Library.Toggles[idx] or self.Library.Options[idx]
            if object and object.Type and self.Parser[object.Type] then
                table.insert(Queue, { object = object, value = value })
            end
        end

        if SaveManager.UseLoadingOrder == true and typeof(SaveManager.LoadingOrder) == "table" then
            table.sort(Queue, function(a, b)
                local aIndex = table.find(SaveManager.LoadingOrder, a.object.Type) or math.huge
                local bIndex = table.find(SaveManager.LoadingOrder, b.object.Type) or math.huge
                return aIndex < bIndex
            end)
        end

        for _, Entry in Queue do
            pcall(self.Parser[Entry.object.Type].Load, Entry.object, Entry.value)
        end

        task.defer(function()
            self._Loading = false
        end)

        return true
    end

    function SaveManager:ResetToDefaults()
        self._Loading = true

        for idx, toggle in pairs(self.Library.Toggles) do
            if self.Ignore[idx] then continue end
            if toggle.Default ~= nil and toggle.SetValue then
                pcall(toggle.SetValue, toggle, toggle.Default)
            end
        end

        for idx, option in pairs(self.Library.Options) do
            if self.Ignore[idx] then continue end

            if option.Type == "KeyPicker" and option.SetValue then
                local key = option.DefaultKey or option.Default or "None"
                local mode = option.DefaultMode or option.Mode
                local modifiers = table.clone(option.DefaultModifiers or {})

                pcall(option.SetValue, option, {
                    Key = key,
                    Mode = mode,
                    Modifiers = modifiers,
                })
            elseif option.Default ~= nil and option.SetValue then
                pcall(option.SetValue, option, option.Default)
            end
        end

        task.defer(function()
            self._Loading = false
        end)
    end

    function SaveManager:AutoSave()
        if self._Loading then return end
        if not self.CurrentConfig then return end

        self:Save(self.CurrentConfig)
    end

    local function Fingerprint(objectType, object)
        local ok, saved = pcall(SaveManager.Parser[objectType].Save, object)
        if not ok then return nil end

        local ok2, encoded = pcall(HttpService.JSONEncode, HttpService, saved)
        if not ok2 then return nil end

        return encoded
    end

    function SaveManager:StartAutoSaveWatcher()
        assert(self.Library, "Must set SaveManager.Library")

        if self._Watching then return end
        self._Watching = true

        task.spawn(function()
            local lastState = {}

            local function Snapshot()
                local state = {}

                for idx, toggle in pairs(self.Library.Toggles) do
                    if self.Ignore[idx] then continue end
                    if not toggle.Type or not self.Parser[toggle.Type] then continue end

                    state[idx] = Fingerprint(toggle.Type, toggle)
                end

                for idx, option in pairs(self.Library.Options) do
                    if self.Ignore[idx] then continue end
                    if not option.Type or not self.Parser[option.Type] then continue end

                    state[idx] = Fingerprint(option.Type, option)
                end

                return state
            end

            lastState = Snapshot()

            while self._Watching do
                task.wait(0.5)

                pcall(function() self:RefreshDropdown() end)

                local newState = Snapshot()
                local changed = false

                if not self._Loading then
                    for idx, value in pairs(newState) do
                        if lastState[idx] ~= value then
                            changed = true
                            break
                        end
                    end

                    if not changed then
                        for idx in pairs(lastState) do
                            if newState[idx] == nil then
                                changed = true
                                break
                            end
                        end
                    end
                end

                lastState = newState

                if changed then
                    self:AutoSave()
                end
            end
        end)
    end

    function SaveManager:EnsureStartupConfig()
        local name = GetDefaultConfigName()
        local list = self:RefreshConfigList()

        if table.find(list, name) then
            self:Load(name)
        else
            self:ResetToDefaults()
            self.CurrentConfig = name
            self:Save(name)
        end

        return name
    end

    local function ShowDialog(Condition, Index, Title, Description, DestructiveText, DestructiveAction)
        if Condition() == false then
            return DestructiveAction()
        end

        local Window = SaveManager.Library.Window
        if not Window or not Window.AddDialog then
            return DestructiveAction()
        end

        return Window:AddDialog(Index, {
            Title = Title,
            Description = Description,
            AutoDismiss = false,
            FooterButtons = {
                Cancel = {
                    Title = "Cancel",
                    Variant = "Ghost",
                    Order = 1,
                    Callback = function(Dialog)
                        Dialog:Dismiss()
                    end,
                },
                DestructiveAction = {
                    Title = DestructiveText,
                    Variant = "Destructive",
                    Order = 2,
                    Callback = function(Dialog)
                        Dialog:Dismiss()
                        DestructiveAction()
                    end,
                },
            },
        })
    end

    function SaveManager:BuildConfigSection(tab)
        assert(self.Library, "Must set SaveManager.Library")

        self:EnsureStartupConfig()

        local section = tab:AddRightSection("Configuration", "folder-cog")

        local ConfigList, AutoloadConfigLabel
        local function RefreshList()
            if not ConfigList then return end
            ConfigList:SetValues(self:RefreshConfigList())
            ConfigList:SetValue(nil)
        end

        local function RefreshAutoloadConfigLabel()
            local name = self:GetAutoloadConfig()

            if AutoloadConfigLabel then
                AutoloadConfigLabel:SetText(string.format("Current autoload config: %s", name))
            end
            RefreshList()
        end

        local function WithAutoloadSuffix(Value)
            if Value == SaveManager.AutoloadConfig then
                return string.format("%s (autoload)", Value)
            end

            return Value
        end

        section:AddDivider({ Text = "Active Config" })

        section:AddDropdown("SaveManager_ConfigList", {
            Text = "Config list",
            Values = self:RefreshConfigList(),
            Default = self.CurrentConfig,
            AllowNull = true,
            FormatDisplayValue = WithAutoloadSuffix,
            FormatListValue = WithAutoloadSuffix,
        })

        ConfigList = self.Library.Options.SaveManager_ConfigList

        if self.CurrentConfig then
            ConfigList:SetSelectedValue(self.CurrentConfig)
        end

        section:AddButton({ Text = "Load config", Func = function()
            local name = ConfigList.Value
            if not name or name == "" then
                self.Library:Notify({ Title = "SaveManager", Description = "Please select a config first.", Time = 3 })
                return
            end

            ShowDialog(
                function() return true end,
                "SaveManager_LoadConfig",
                "Load config",
                string.format("Are you sure you want to load %q? Your current settings will be overwritten.", name),
                "Load",
                function()
                    local success, err = self:Load(name)
                    if not success then
                        self.Library:Notify({ Title = "SaveManager", Description = "Failed to load config: " .. tostring(err), Time = 4 })
                        return
                    end

                    self.Library:Notify({ Title = "SaveManager", Description = string.format("Loaded config %q.", name), Time = 3 })
                end
            )
        end })

        section:AddButton({ Text = "Overwrite config", Func = function()
            local name = ConfigList.Value
            if not name or name == "" then
                self.Library:Notify({ Title = "SaveManager", Description = "Please select a config first.", Time = 3 })
                return
            end

            ShowDialog(
                function() return true end,
                "SaveManager_OverwriteConfig",
                "Overwrite config",
                string.format("Are you sure you want to overwrite %q with your current settings? This cannot be undone.", name),
                "Overwrite",
                function()
                    local success, err = self:Save(name)
                    if not success then
                        self.Library:Notify({ Title = "SaveManager", Description = "Failed to overwrite config: " .. tostring(err), Time = 4 })
                        return
                    end

                    self.Library:Notify({ Title = "SaveManager", Description = string.format("Overwrote config %q.", name), Time = 3 })
                end
            )
        end })

        section:AddButton({ Text = "Delete config", Risky = true, Func = function()
            local name = ConfigList.Value
            if not name or name == "" then
                self.Library:Notify({ Title = "SaveManager", Description = "Please select a config first.", Time = 3 })
                return
            end

            ShowDialog(
                function() return true end,
                "SaveManager_DeleteConfig",
                "Delete config",
                string.format("Are you sure you want to delete %q? This cannot be undone.", name),
                "Delete",
                function()
                    local success, err = self:Delete(name)
                    if not success then
                        self.Library:Notify({ Title = "SaveManager", Description = "Failed to delete config: " .. tostring(err), Time = 4 })
                        return
                    end

                    if self.CurrentConfig == name then
                        self.CurrentConfig = nil
                        self:ResetToDefaults()

                        local defaultName = GetDefaultConfigName()
                        self.CurrentConfig = defaultName
                        self:Save(defaultName)
                    end

                    self.Library:Notify({ Title = "SaveManager", Description = string.format("Deleted config %q.", name), Time = 3 })
                    RefreshAutoloadConfigLabel()
                end
            )
        end })

        section:AddButton({ Text = "Refresh list", Func = function()
            RefreshList()
        end })

        section:AddDivider({ Text = "Create New" })

        section:AddInput("SaveManager_ConfigName", { Text = "New config name", Placeholder = "Enter name..." })

        section:AddButton({ Text = "Create config", Func = function()
            local name = self.Library.Options.SaveManager_ConfigName.Value

            if not name or name:gsub(" ", "") == "" then
                self.Library:Notify({ Title = "SaveManager", Description = "Invalid config name (empty).", Time = 3 })
                return
            end

            if string.lower(name) == "autoload" then
                self.Library:Notify({ Title = "SaveManager", Description = "Invalid config name provided.", Time = 3 })
                return
            end

            ShowDialog(
                function()
                    local list = self:RefreshConfigList()
                    return table.find(list, name) ~= nil
                end,
                "SaveManager_CreateConfig",
                "Config already exists",
                string.format("A config named %q already exists. Overwriting will replace it with your current settings.", name),
                "Overwrite",
                function()
                    self:ResetToDefaults()

                    self.CurrentConfig = name

                    local success, err = self:Save(name)
                    if not success then
                        self.Library:Notify({ Title = "SaveManager", Description = "Failed to create config: " .. tostring(err), Time = 4 })
                        return
                    end

                    ConfigList:SetValues(self:RefreshConfigList())
                    ConfigList.Value = name
                    ConfigList:Display()

                    self.Library:Notify({ Title = "SaveManager", Description = string.format("Created and switched to %q.", name), Time = 3 })
                end
            )
        end })

        section:AddDivider({ Text = "Autoload" })

        section:AddButton({ Text = "Set as autoload", Func = function()
            local name = ConfigList.Value
            if not name or name == "" then
                self.Library:Notify({ Title = "SaveManager", Description = "Please select a config first.", Time = 3 })
                return
            end

            local success, err = self:SaveAutoloadConfig(name)
            if not success then
                self.Library:Notify({ Title = "SaveManager", Description = "Failed to set autoload config: " .. tostring(err), Time = 4 })
                return
            end

            self.Library:Notify({ Title = "SaveManager", Description = string.format("Set autoload config to %q.", name), Time = 3 })
            RefreshAutoloadConfigLabel()
        end })

        section:AddButton({ Text = "Reset autoload", Func = function()
            ShowDialog(
                function() return true end,
                "SaveManager_ResetAutoload",
                "Reset autoload config",
                "Are you sure you want to clear the autoload config? No config will be loaded automatically on next launch.",
                "Reset",
                function()
                    local success, err = self:DeleteAutoloadConfig()
                    if not success then
                        self.Library:Notify({ Title = "SaveManager", Description = "Failed to reset autoload config: " .. tostring(err), Time = 4 })
                        return
                    end

                    self.Library:Notify({ Title = "SaveManager", Description = "Reset autoload config.", Time = 3 })
                    RefreshAutoloadConfigLabel()
                end
            )
        end })

        AutoloadConfigLabel = section:AddLabel("Current autoload config: ...")

        section:AddDivider({ Text = "Import & Export" })

        section:AddInput("SaveManager_JSON", { Text = "Config JSON", Placeholder = "Paste config JSON..." })

        section:AddButton({ Text = "Import config", Func = function()
            local content = self.Library.Options.SaveManager_JSON.Value
            if not content or content:gsub(" ", "") == "" then
                self.Library:Notify({ Title = "SaveManager", Description = "Configuration JSON cannot be empty.", Time = 3 })
                return
            end

            ShowDialog(
                function() return true end,
                "SaveManager_ImportConfig",
                "Import config",
                "Are you sure you want to import this configuration? Your current settings will be overwritten.",
                "Import",
                function()
                    local success, err = self:LoadJSON(content)
                    if not success then
                        self.Library:Notify({ Title = "SaveManager", Description = "Failed to import config: " .. tostring(err), Time = 4 })
                        return
                    end

                    self.Library:Notify({ Title = "SaveManager", Description = "Imported config.", Time = 3 })
                end
            )
        end })

        section:AddButton({ Text = "Export current config", Func = function()
            local encoded, success, err = self:SaveJSON()
            if not success then
                self.Library:Notify({ Title = "SaveManager", Description = tostring(err), Time = 4 })
                return
            end

            self.Library.Options.SaveManager_JSON:SetValue(encoded)
            if setclipboard then
                setclipboard(encoded)
                self.Library:Notify({ Title = "SaveManager", Description = "Copied config to your clipboard.", Time = 3 })
            end
        end })

        self:SetIgnoreIndexes({ "SaveManager_ConfigList", "SaveManager_ConfigName", "SaveManager_JSON" })

        self:StartAutoSaveWatcher()

        RefreshAutoloadConfigLabel()

        task.defer(function()
            if self.CurrentConfig then
                self:Load(self.CurrentConfig)
            else
                self:LoadAutoloadConfig()
            end

            self:RevealAfterLoad()
        end)
    end

    function SaveManager:RevealAfterLoad()
        local Lib = self.Library
        local Window = Lib

        local AutoShow = true
        if Window and typeof(Window) == "table" and Window.AutoShow ~= nil then
            AutoShow = Window.AutoShow
        elseif Lib and Lib.AutoShow ~= nil then
            AutoShow = Lib.AutoShow
        end

        local LibraryTable = (Lib and typeof(Lib) == "table" and Lib) or (Window and typeof(Window) == "table" and Window.Library)
        if LibraryTable then
            while LibraryTable.ActiveLoading do
                task.wait()
            end
        end

        if Window and Window.Toggle then
            Window:Toggle(AutoShow)
        elseif Window and typeof(Window) == "table" and Window.Library and Window.Library.Toggle then
            Window.Library:Toggle(AutoShow)
        end

        if LibraryTable and LibraryTable.DeferAutoShowTo == self then
            LibraryTable.DeferAutoShowTo = nil
        end
    end

    function SaveManager:Init(Window)
        assert(self.Library, "Must set SaveManager.Library")
        Window = Window or self.Library

        if self.CurrentConfig then
            self:Load(self.CurrentConfig)
        else
            self:EnsureStartupConfig()
        end

        self:RevealAfterLoad()
    end

    SaveManager:BuildFolderTree()
end

return SaveManager
