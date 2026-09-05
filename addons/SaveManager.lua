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
    SaveManager.Folder = "AstralSettings"
    SaveManager.SubFolder = ""
    SaveManager.Ignore = {}
    SaveManager.Library = nil

    SaveManager.CurrentConfig = nil
    SaveManager._Loading = false

    SaveManager.Parser = {
        Toggle = {
            Save = function(object)
                return object.Value
            end,
            Load = function(object, value)
                if object.Value ~= value then
                    object:SetValue(value)
                end
            end,
        },
        Slider = {
            Save = function(object)
                return tostring(object.Value)
            end,
            Load = function(object, value)
                if object.Value ~= value then
                    object:SetValue(value)
                end
            end,
        },
        ProgressBar = {
            Save = function(object)
                return tostring(object.Value)
            end,
            Load = function(object, value)
                if object.Value ~= value then
                    object:SetValue(value)
                end
            end,
        },
        Dropdown = {
            Save = function(object)
                return object.Value
            end,
            Load = function(object, value)
                if object.Value ~= value then
                    object:SetValue(value)
                end
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

                -- A stale/old config can contain key = "None". Do not let that
                -- value destroy a script-declared default when the config is being
                -- recreated/reset. Explicitly saved None is still respected when
                -- loading an existing user config; fresh defaults are handled by
                -- SaveManager:ResetToDefaults below.
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

        -- SaveManager now owns revealing the window: it has to load the
        -- config first and only THEN show/hide based on AutoShow. Tell the
        -- library to stand down its own auto-reveal (CreateWindow's
        -- task.defer and Loading:Destroy) so it can't show the UI early
        -- with default/unloaded values while SaveManager is still working.
        --
        -- ORDERING REQUIREMENT: this MUST be called BEFORE
        -- Library:CreateWindow(...), not after. CreateWindow checks
        -- Library.DeferAutoShowTo synchronously, before it returns to your
        -- script, in order to decide whether to auto-reveal the window. If
        -- SetLibrary runs after CreateWindow, that check has already
        -- happened and already seen DeferAutoShowTo as nil -- the window
        -- (and bubble, if enabled) will have already flashed default/
        -- unloaded values before SaveManager gets a chance to load the
        -- real config. Library.Toggled being true here is a reliable sign
        -- that's exactly what just happened, so warn loudly instead of
        -- failing silently.
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

    function SaveManager:Save(name)
        if not name or name:gsub(" ", "") == "" then
            return false, "no config file is selected"
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

        for idx, value in pairs(decoded) do
            if self.Ignore[idx] then continue end

            local object = self.Library.Toggles[idx] or self.Library.Options[idx]
            if object and object.Type and self.Parser[object.Type] then
                pcall(self.Parser[object.Type].Load, object, value)
            end
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
                        table.insert(out, file:sub(pos + 1, start - 1))
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
                -- KeyPicker.Default used to be copied from the live Value, which
                -- means a previous load of "None" could turn the supposed default
                -- into "None" permanently. Use the immutable script-declared
                -- DefaultKey/DefaultMode/DefaultModifiers instead.
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
            -- A brand-new config must be created from the library/example
            -- defaults, never from whatever values happen to be in memory.
            self:ResetToDefaults()
            self.CurrentConfig = name
            self:Save(name)
        end

        return name
    end

    function SaveManager:BuildConfigSection(tab)
        assert(self.Library, "Must set SaveManager.Library")

        self:EnsureStartupConfig()

        local section = tab:AddRightSection("Configuration", "folder-cog")

        section:AddDivider({ Text = "Active Config" })

        section:AddDropdown("SaveManager_ConfigList", {
            Text = "Config list",
            Values = self:RefreshConfigList(),
            Default = self.CurrentConfig,
            AllowNull = true,
            Callback = function(Value)
                if not Value or Value == "" then return end
                if Value == self.CurrentConfig then return end

                local success, err = self:Load(Value)
                if not success then
                    self.Library:Notify({ Title = "SaveManager", Description = "Failed to load config: " .. err, Time = 4 })
                    return
                end

                self.Library:Notify({ Title = "SaveManager", Description = string.format("Loaded config %q.", Value), Time = 3 })
            end,
        })

        if self.CurrentConfig then
            self.Library.Options.SaveManager_ConfigList:SetSelectedValue(self.CurrentConfig)
        end

        section:AddDivider({ Text = "Create New" })

        section:AddInput("SaveManager_ConfigName", { Text = "New config name", Placeholder = "Enter name..." })

        section:AddButton({ Text = "Create config", Func = function()
            local name = self.Library.Options.SaveManager_ConfigName.Value

            if not name or name:gsub(" ", "") == "" then
                self.Library:Notify({ Title = "SaveManager", Description = "Invalid config name (empty).", Time = 3 })
                return
            end

            local list = self:RefreshConfigList()
            if table.find(list, name) then
                self.Library:Notify({ Title = "SaveManager", Description = "A config with that name already exists.", Time = 3 })
                return
            end

            self:ResetToDefaults()

            self.CurrentConfig = name

            local success, err = self:Save(name)
            if not success then
                self.Library:Notify({ Title = "SaveManager", Description = "Failed to create config: " .. err, Time = 4 })
                return
            end

            self.Library.Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
            self.Library.Options.SaveManager_ConfigList.Value = name
            self.Library.Options.SaveManager_ConfigList:Display()

            self.Library:Notify({ Title = "SaveManager", Description = string.format("Created and switched to %q.", name), Time = 3 })
        end })

        section:AddDivider({ Text = "Manage" })

        section:AddButton({ Text = "Delete current config", Risky = true, Func = function()
            local name = self.CurrentConfig

            if not name then
                self.Library:Notify({ Title = "SaveManager", Description = "No config is currently active.", Time = 3 })
                return
            end

            local success, err = self:Delete(name)
            if not success then
                self.Library:Notify({ Title = "SaveManager", Description = "Failed to delete config: " .. err, Time = 4 })
                return
            end

            self.CurrentConfig = nil

            self:ResetToDefaults()

            local defaultName = GetDefaultConfigName()
            self.CurrentConfig = defaultName

            local saveSuccess, saveErr = self:Save(defaultName)
            if not saveSuccess then
                self.Library:Notify({ Title = "SaveManager", Description = "Failed to recreate default config: " .. saveErr, Time = 4 })
            end

            self.Library:Notify({ Title = "SaveManager", Description = string.format("Deleted %q. Reset to defaults as %q.", name, defaultName), Time = 3 })

            self.Library.Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
            self.Library.Options.SaveManager_ConfigList.Value = self.CurrentConfig
            self.Library.Options.SaveManager_ConfigList:Display()
        end })

        self:SetIgnoreIndexes({ "SaveManager_ConfigList", "SaveManager_ConfigName" })

        self:StartAutoSaveWatcher()

        task.defer(function()
            if self.CurrentConfig then
                self:Load(self.CurrentConfig)
            end

            self:RevealAfterLoad()
        end)
    end

    -- Single source of truth for "config is done loading, now show/hide the
    -- window per AutoShow". Waits out any active loading screen (icon
    -- loading, Library:CreateLoading, etc.) so the reveal never races it,
    -- then releases the DeferAutoShowTo flag so the window's own AutoShow
    -- logic behaves normally again afterward (e.g. the ToggleKeybind).
    function SaveManager:RevealAfterLoad()
        local Lib = self.Library
        local Window = Lib

        local AutoShow = true
        if Window and typeof(Window) == "table" and Window.AutoShow ~= nil then
            AutoShow = Window.AutoShow
        elseif Lib and Lib.AutoShow ~= nil then
            AutoShow = Lib.AutoShow
        end

        -- If a loading screen (e.g. icon preloading) is still up, wait for
        -- it to finish before revealing -- otherwise the window would pop
        -- in underneath/before the splash is gone.
        local LibraryTable = (Lib and typeof(Lib) == "table" and Lib) or (Window and typeof(Window) == "table" and Window.Library)
        if LibraryTable then
            while LibraryTable.ActiveLoading do
                task.wait()
            end
        end

        -- IMPORTANT: always route through Toggle (never skip it) even when
        -- AutoShow is false. Library:Toggle() is also what piggybacks the
        -- bubble's first-time creation (see Library.BubbleWantedOnStart /
        -- Library.ToggleBubble in Astral.lua) -- that hook only fires
        -- inside Toggle itself. If we skip calling Toggle entirely while
        -- AutoShow is off, the bubble never gets created, leaving the user
        -- with neither the window nor the bubble visible. So we always call
        -- Toggle with the correct target value (true for AutoShow, false
        -- otherwise) instead of conditionally avoiding the call.
        if Window and Window.Toggle then
            Window:Toggle(AutoShow)
        elseif Window and typeof(Window) == "table" and Window.Library and Window.Library.Toggle then
            Window.Library:Toggle(AutoShow)
        end

        -- Release the "SaveManager owns the reveal" flag now that the
        -- reveal has actually happened, so normal manual toggling
        -- (keybind/bubble) isn't affected going forward.
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
