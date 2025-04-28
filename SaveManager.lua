--[[
    SaveManager.lua
    Part of FluidUI Library for Roblox
    
    Handles saving, loading, and management of UI configurations
    Features:
    - Auto-loading configurations
    - Creating new configs
    - Saving current UI state
    - Multiple profile support
]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local SaveManager = {
    Folder = "FluidUI",
    Configs = {},
    CurrentConfig = nil,
    ConfigExtension = ".flui",
    AutoSaveInterval = 60, -- Seconds
    IsAutoSaveEnabled = true,
    AutoSaveConnection = nil,
    DefaultConfig = "default",
    ConfigMetadata = {}
}

local FileSystem = {
    WriteAsync = function(path, content)
        if writefile then
            writefile(path, content)
            return true
        end
        return false
    end,
    
    ReadAsync = function(path)
        if readfile and isfile and isfile(path) then
            return readfile(path)
        end
        return nil
    end,
    
    MakeFolder = function(path)
        if makefolder and not isfolder(path) then
            makefolder(path)
            return true
        elseif isfolder and isfolder(path) then
            return true
        end
        return false
    end,
    
    ListFiles = function(path)
        if listfiles and isfolder and isfolder(path) then
            return listfiles(path)
        end
        return {}
    end,
    
    FileExists = function(path)
        if isfile then
            return isfile(path)
        end
        return false
    end,
    
    DeleteFile = function(path)
        if delfile and isfile and isfile(path) then
            delfile(path)
            return true
        end
        return false
    end,
    
    MoveFile = function(oldPath, newPath)
        if readfile and writefile and isfile and isfile(oldPath) then
            local content = readfile(oldPath)
            writefile(newPath, content)
            delfile(oldPath)
            return true
        end
        return false
    end
}

-- Initialize required folders
function SaveManager:Initialize()
    self.FolderPath = self.Folder
    local success = FileSystem.MakeFolder(self.FolderPath)
    
    -- Create configs folder
    self.ConfigsFolderPath = self.FolderPath .. "/Configs"
    FileSystem.MakeFolder(self.ConfigsFolderPath)
    
    -- Create themes folder
    self.ThemesFolderPath = self.FolderPath .. "/Themes"
    FileSystem.MakeFolder(self.ThemesFolderPath)
    
    self:RefreshConfigList()
    
    -- Try to load the last used config if any
    self:LoadLastUsedConfig()
    
    return success
end

-- Refresh the list of available configurations
function SaveManager:RefreshConfigList()
    self.Configs = {}
    local files = FileSystem.ListFiles(self.ConfigsFolderPath)
    
    for _, file in ipairs(files) do
        -- Extract just the filename without path or extension
        local fileName = string.match(file, "[^/\\]+$")
        if fileName then
            fileName = string.match(fileName, "(.+)%..+$") or fileName
            if string.sub(file, -string.len(self.ConfigExtension)) == self.ConfigExtension then
                table.insert(self.Configs, fileName)
                
                -- Try to read metadata
                self:LoadConfigMetadata(fileName)
            end
        end
    end
    
    return self.Configs
end

-- Create a new configuration
function SaveManager:CreateConfig(name, data, metadata)
    if not name or type(name) ~= "string" or name == "" then
        return false, "Invalid configuration name"
    end
    
    local configPath = self.ConfigsFolderPath .. "/" .. name .. self.ConfigExtension
    
    -- Check if config already exists
    if FileSystem.FileExists(configPath) then
        return false, "Configuration already exists"
    end
    
    local configData = data or {}
    local success = FileSystem.WriteAsync(configPath, HttpService:JSONEncode(configData))
    
    if success then
        table.insert(self.Configs, name)
        self:SetCurrentConfig(name)
        
        -- Save metadata if provided
        if metadata then
            self:SaveConfigMetadata(name, metadata)
        end
    end
    
    return success
end

-- Save the current UI configuration
function SaveManager:SaveCurrentConfig(data, forceName)
    local configName = forceName or self.CurrentConfig or self.DefaultConfig
    
    -- If the config doesn't exist yet
    if not table.find(self.Configs, configName) then
        return self:CreateConfig(configName, data)
    end
    
    local configPath = self.ConfigsFolderPath .. "/" .. configName .. self.ConfigExtension
    local success = FileSystem.WriteAsync(configPath, HttpService:JSONEncode(data))
    
    if success and self.OnConfigSaved then
        self.OnConfigSaved(configName, data)
    end
    
    return success, configName
end

-- Load a configuration by name
function SaveManager:LoadConfig(name)
    if not name or not table.find(self.Configs, name) then
        return nil, "Configuration not found"
    end
    
    local configPath = self.ConfigsFolderPath .. "/" .. name .. self.ConfigExtension
    local content = FileSystem.ReadAsync(configPath)
    
    if not content then
        return nil, "Failed to read configuration file"
    end
    
    local success, data = pcall(function()
        return HttpService:JSONDecode(content)
    end)
    
    if not success then
        return nil, "Failed to parse configuration file"
    end
    
    self:SetCurrentConfig(name)
    
    -- Record this as the last used config
    self:SaveLastUsedConfig(name)
    
    if self.OnConfigLoaded then
        self.OnConfigLoaded(name, data)
    end
    
    return data
end

-- Delete a configuration
function SaveManager:DeleteConfig(name)
    if not name or not table.find(self.Configs, name) then
        return false, "Configuration not found"
    end
    
    local configPath = self.ConfigsFolderPath .. "/" .. name .. self.ConfigExtension
    local success = FileSystem.DeleteFile(configPath)
    
    if success then
        table.remove(self.Configs, table.find(self.Configs, name))
        
        -- If we deleted the current config, reset current config
        if self.CurrentConfig == name then
            self.CurrentConfig = nil
        end
        
        -- Also delete metadata
        local metadataPath = self.ConfigsFolderPath .. "/" .. name .. ".metadata"
        FileSystem.DeleteFile(metadataPath)
        self.ConfigMetadata[name] = nil
        
        if self.OnConfigDeleted then
            self.OnConfigDeleted(name)
        end
    end
    
    return success
end

-- Rename a configuration
function SaveManager:RenameConfig(oldName, newName)
    if not oldName or not table.find(self.Configs, oldName) then
        return false, "Source configuration not found"
    end
    
    if not newName or newName == "" then
        return false, "Invalid new configuration name"
    end
    
    if table.find(self.Configs, newName) then
        return false, "Destination configuration already exists"
    end
    
    local oldPath = self.ConfigsFolderPath .. "/" .. oldName .. self.ConfigExtension
    local newPath = self.ConfigsFolderPath .. "/" .. newName .. self.ConfigExtension
    
    local success = FileSystem.MoveFile(oldPath, newPath)
    
    if success then
        table.remove(self.Configs, table.find(self.Configs, oldName))
        table.insert(self.Configs, newName)
        
        -- If this was the current config, update the reference
        if self.CurrentConfig == oldName then
            self.CurrentConfig = newName
        end
        
        -- Also move the metadata if it exists
        local oldMetadataPath = self.ConfigsFolderPath .. "/" .. oldName .. ".metadata"
        local newMetadataPath = self.ConfigsFolderPath .. "/" .. newName .. ".metadata"
        
        if FileSystem.FileExists(oldMetadataPath) then
            FileSystem.MoveFile(oldMetadataPath, newMetadataPath)
        end
        
        if self.ConfigMetadata[oldName] then
            self.ConfigMetadata[newName] = self.ConfigMetadata[oldName]
            self.ConfigMetadata[oldName] = nil
        end
        
        if self.OnConfigRenamed then
            self.OnConfigRenamed(oldName, newName)
        end
    end
    
    return success
end

-- Set the current active configuration
function SaveManager:SetCurrentConfig(name)
    if not name or not table.find(self.Configs, name) then
        return false
    end
    
    self.CurrentConfig = name
    return true
end

-- Enable auto-saving
function SaveManager:EnableAutoSave(interval)
    if interval and type(interval) == "number" and interval > 0 then
        self.AutoSaveInterval = interval
    end
    
    -- Clear any existing connection
    if self.AutoSaveConnection then
        self.AutoSaveConnection:Disconnect()
        self.AutoSaveConnection = nil
    end
    
    -- Set up auto-save timer
    self.IsAutoSaveEnabled = true
    self.AutoSaveConnection = spawn(function()
        while self.IsAutoSaveEnabled do
            wait(self.AutoSaveInterval)
            
            if self.IsAutoSaveEnabled and self.CurrentConfig and self.GetSaveData then
                local data = self.GetSaveData()
                self:SaveCurrentConfig(data)
            end
        end
    end)
    
    return true
end

-- Disable auto-saving
function SaveManager:DisableAutoSave()
    self.IsAutoSaveEnabled = false
    
    if self.AutoSaveConnection then
        self.AutoSaveConnection:Disconnect()
        self.AutoSaveConnection = nil
    end
    
    return true
end

-- Save configuration metadata
function SaveManager:SaveConfigMetadata(name, metadata)
    if not name or not table.find(self.Configs, name) then
        return false
    end
    
    local metadataPath = self.ConfigsFolderPath .. "/" .. name .. ".metadata"
    local success = FileSystem.WriteAsync(metadataPath, HttpService:JSONEncode(metadata))
    
    if success then
        self.ConfigMetadata[name] = metadata
    end
    
    return success
end

-- Load configuration metadata
function SaveManager:LoadConfigMetadata(name)
    if not name then
        return nil
    end
    
    -- If we already have it cached
    if self.ConfigMetadata[name] then
        return self.ConfigMetadata[name]
    end
    
    local metadataPath = self.ConfigsFolderPath .. "/" .. name .. ".metadata"
    local content = FileSystem.ReadAsync(metadataPath)
    
    if not content then
        return nil
    end
    
    local success, metadata = pcall(function()
        return HttpService:JSONDecode(content)
    end)
    
    if success then
        self.ConfigMetadata[name] = metadata
        return metadata
    end
    
    return nil
end

-- Save the name of the last used config
function SaveManager:SaveLastUsedConfig(name)
    local lastUsedPath = self.FolderPath .. "/lastconfig"
    return FileSystem.WriteAsync(lastUsedPath, name)
end

-- Load the last used config
function SaveManager:LoadLastUsedConfig()
    local lastUsedPath = self.FolderPath .. "/lastconfig"
    local name = FileSystem.ReadAsync(lastUsedPath)
    
    if name and table.find(self.Configs, name) then
        self.CurrentConfig = name
        return name
    end
    
    return nil
end

-- Export a configuration to JSON string
function SaveManager:ExportConfig(name)
    name = name or self.CurrentConfig
    
    if not name or not table.find(self.Configs, name) then
        return nil, "Configuration not found"
    end
    
    local configPath = self.ConfigsFolderPath .. "/" .. name .. self.ConfigExtension
    local content = FileSystem.ReadAsync(configPath)
    
    if not content then
        return nil, "Failed to read configuration"
    end
    
    -- Wrap in export container with metadata
    local exportData = {
        name = name,
        metadata = self:LoadConfigMetadata(name) or {},
        data = HttpService:JSONDecode(content),
        exportTime = os.time(),
        version = "1.0"
    }
    
    return HttpService:JSONEncode(exportData)
end

-- Import a configuration from JSON string
function SaveManager:ImportConfig(jsonString, newName)
    local success, importData = pcall(function()
        return HttpService:JSONDecode(jsonString)
    end)
    
    if not success or not importData.data then
        return false, "Invalid import data format"
    end
    
    local configName = newName or importData.name
    
    -- Make sure the name is unique
    if table.find(self.Configs, configName) then
        local baseName = configName
        local counter = 1
        
        while table.find(self.Configs, configName) do
            configName = baseName .. "_" .. counter
            counter = counter + 1
        end
    end
    
    -- Create the new config
    local success = self:CreateConfig(configName, importData.data, importData.metadata)
    
    if success and self.OnConfigImported then
        self.OnConfigImported(configName, importData)
    end
    
    return success, configName
end

-- Set the function to call to get current UI state for saving
function SaveManager:SetSaveDataCallback(callback)
    if type(callback) == "function" then
        self.GetSaveData = callback
        return true
    end
    return false
end

-- Set the function to call when config is loaded
function SaveManager:SetLoadDataCallback(callback)
    if type(callback) == "function" then
        self.OnConfigLoaded = callback
        return true
    end
    return false
end

-- Set both callbacks at once
function SaveManager:SetCallbacks(saveCallback, loadCallback)
    local success1 = self:SetSaveDataCallback(saveCallback)
    local success2 = self:SetLoadDataCallback(loadCallback)
    return success1 and success2
end

-- Create a backup of all configurations
function SaveManager:BackupAllConfigs()
    local timestamp = os.time()
    local backupFolderPath = self.FolderPath .. "/Backups/" .. timestamp
    FileSystem.MakeFolder(self.FolderPath .. "/Backups")
    FileSystem.MakeFolder(backupFolderPath)
    
    local backupInfo = {
        timestamp = timestamp,
        configs = {}
    }
    
    for _, configName in ipairs(self.Configs) do
        local configPath = self.ConfigsFolderPath .. "/" .. configName .. self.ConfigExtension
        local content = FileSystem.ReadAsync(configPath)
        
        if content then
            local backupPath = backupFolderPath .. "/" .. configName .. self.ConfigExtension
            FileSystem.WriteAsync(backupPath, content)
            
            -- Also backup metadata if exists
            local metadata = self:LoadConfigMetadata(configName)
            if metadata then
                local metadataPath = backupFolderPath .. "/" .. configName .. ".metadata"
                FileSystem.WriteAsync(metadataPath, HttpService:JSONEncode(metadata))
            end
            
            table.insert(backupInfo.configs, configName)
        end
    end
    
    -- Save backup info
    FileSystem.WriteAsync(backupFolderPath .. "/backup_info.json", HttpService:JSONEncode(backupInfo))
    
    return timestamp, backupInfo
end

-- Restore configurations from a backup
function SaveManager:RestoreFromBackup(timestamp)
    local backupFolderPath = self.FolderPath .. "/Backups/" .. timestamp
    
    if not FileSystem.MakeFolder(backupFolderPath) then
        return false, "Backup not found"
    end
    
    local infoPath = backupFolderPath .. "/backup_info.json"
    local infoContent = FileSystem.ReadAsync(infoPath)
    
    if not infoContent then
        return false, "Backup information not found"
    end
    
    local success, backupInfo = pcall(function()
        return HttpService:JSONDecode(infoContent)
    end)
    
    if not success then
        return false, "Failed to parse backup information"
    end
    
    -- Restore each config
    for _, configName in ipairs(backupInfo.configs) do
        local backupPath = backupFolderPath .. "/" .. configName .. self.ConfigExtension
        local content = FileSystem.ReadAsync(backupPath)
        
        if content then
            local configPath = self.ConfigsFolderPath .. "/" .. configName .. self.ConfigExtension
            FileSystem.WriteAsync(configPath, content)
            
            -- Also restore metadata if exists
            local metadataBackupPath = backupFolderPath .. "/" .. configName .. ".metadata"
            local metadataContent = FileSystem.ReadAsync(metadataBackupPath)
            
            if metadataContent then
                local metadataPath = self.ConfigsFolderPath .. "/" .. configName .. ".metadata"
                FileSystem.WriteAsync(metadataPath, metadataContent)
                
                -- Update cached metadata
                self.ConfigMetadata[configName] = HttpService:JSONDecode(metadataContent)
            end
        end
    end
    
    -- Refresh config list
    self:RefreshConfigList()
    
    if self.OnBackupRestored then
        self.OnBackupRestored(timestamp, backupInfo)
    end
    
    return true, backupInfo
end

-- List available backups
function SaveManager:ListBackups()
    local backupsFolder = self.FolderPath .. "/Backups"
    local folders = FileSystem.ListFiles(backupsFolder)
    local backups = {}
    
    for _, folderPath in ipairs(folders) do
        local folderName = string.match(folderPath, "[^/\\]+$")
        local infoPath = folderPath .. "/backup_info.json"
        local infoContent = FileSystem.ReadAsync(infoPath)
        
        if infoContent then
            local success, backupInfo = pcall(function()
                return HttpService:JSONDecode(infoContent)
            end)
            
            if success then
                table.insert(backups, backupInfo)
            end
        end
    end
    
    -- Sort by timestamp (newest first)
    table.sort(backups, function(a, b)
        return a.timestamp > b.timestamp
    end)
    
    return backups
end

return SaveManager