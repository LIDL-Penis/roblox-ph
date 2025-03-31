--[[
AWP.gg Script Decompiler - Onetap V3 Style
----------------------------------------
This script creates a GUI for dumping and decompiling scripts in Roblox games.
Includes Part Finder details and basic script analysis.
For educational purposes only.
]]

-- Add this near the beginning of the script, after the Logger is defined
-- Global error handler
local originalErrorHandler = error
_G.error = function(message, level)
    if Logger then
        Logger:error(tostring(message))
    else
        warn("Logger not available: " .. tostring(message))
    end
    return originalErrorHandler(message, level or 2)
end

-- Also add this utility function to safely get services
function safeGetService(serviceName)
    local success, service = pcall(function()
        return game:GetService(serviceName)
    end)
    if success then
        return service
    else
        warn("Failed to get service: " .. serviceName)
        return nil
    end
end

-- Then update the service definitions
local Players = safeGetService("Players")
local TextService = safeGetService("TextService")
local TweenService = safeGetService("TweenService")
local UserInputService = safeGetService("UserInputService")
local HttpService = safeGetService("HttpService") -- Added for UrlEncode/JSONDecode
local LocalPlayer = Players and Players.LocalPlayer


-- Logging System
local Logger = {
    Levels = {
        ERROR = 1,
        WARNING = 2,
        INFO = 3,
        DEBUG = 4
    },
    logs = {},
    logUI = nil,
    maxLogsStored = 1000
}

-- Logger configuration
Logger.Config = {
    currentLevel = 3, -- INFO level by default
    showTimestamps = true,
    logToConsole = true,
    logToUI = true,
    logToFile = false,
    maxVisibleLogs = 100,
    logFilePath = "AWPDecompiler_logs.txt"
}

-- Color and name mappings for log levels
Logger.LevelColors = {
    [1] = Color3.fromRGB(231, 76, 60),  -- ERROR
    [2] = Color3.fromRGB(241, 196, 15), -- WARNING
    [3] = Color3.fromRGB(220, 220, 220), -- INFO
    [4] = Color3.fromRGB(170, 170, 170)  -- DEBUG
}

Logger.LevelNames = {
    [1] = "ERROR",
    [2] = "WARNING",
    [3] = "INFO",
    [4] = "DEBUG"
}

-- Format a log message with timestamp
function Logger:formatLogMessage(level, message)
    local timestamp = ""
    if self.Config.showTimestamps then
        timestamp = os.date("[%H:%M:%S] ")
    end

    return timestamp .. "[" .. self.LevelNames[level] .. "] " .. message
end

-- Main logging function
function Logger:log(level, message)
    -- Safety check for message
    if not message or type(message) ~= "string" then
        message = tostring(message or "nil")
    end

    -- Check if this log level should be recorded
    if level > self.Config.currentLevel then
        return
    end

    local formattedMessage = ""
    pcall(function()
        formattedMessage = self:formatLogMessage(level, message)
    end)

    -- Add to log storage
    table.insert(self.logs, {
        level = level,
        message = message,
        formattedMessage = formattedMessage,
        timestamp = os.time()
    })

    -- Limit log storage size
    if #self.logs > self.maxLogsStored then
        table.remove(self.logs, 1)
    end

    -- Log to console if enabled
    if self.Config.logToConsole then
        print(formattedMessage)
    end

    -- Log to UI if enabled and UI exists
    if self.Config.logToUI and self.logUI then
        pcall(function()
            self:updateLogUI()
        end)
    end

    -- Log to file if enabled
    if self.Config.logToFile and writefile then
        pcall(function()
            if not isfile(self.Config.logFilePath) then
                writefile(self.Config.logFilePath, formattedMessage .. "\n")
            else
                appendfile(self.Config.logFilePath, formattedMessage .. "\n")
            end
        end)
    end

    -- Update status bar as well
    pcall(function()
        if level <= 3 and StatusLabel then -- Only show ERROR, WARNING, INFO in status bar
            StatusLabel.Text = message
            StatusLabel.TextColor3 = self.LevelColors[level]
        end
    end)
end

-- Convenience methods for different log levels
function Logger:error(message)
    self:log(self.Levels.ERROR, message)
end

function Logger:warning(message)
    self:log(self.Levels.WARNING, message)
end

function Logger:info(message)
    self:log(self.Levels.INFO, message)
end

function Logger:debug(message)
    self:log(self.Levels.DEBUG, message)
end

-- Add method to explicitly log errors that might occur in pcall
function Logger:logPcallError(success, result, context)
    if not success then
        self:error((context or "Operation failed") .. ": " .. tostring(result))
        return false, result
    end
    return true, result
end

-- Function to add context menu to log entries
local function setupLogContextMenu(logLabel)
    logLabel.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton2 then  -- Right click
            -- Remove any existing context menu first
            local existingMenu = Logger.logUI:FindFirstChild("ContextMenu")
            if existingMenu then existingMenu:Destroy() end

            local contextMenu = Instance.new("Frame")
            contextMenu.Name = "ContextMenu"
            contextMenu.Parent = Logger.logUI -- Parent to the scrolling frame for positioning
            contextMenu.BackgroundColor3 = COLORS.BUTTON_IDLE
            contextMenu.BorderColor3 = COLORS.BORDER
            contextMenu.BorderSizePixel = 1
            -- Calculate position relative to the scrolling frame's canvas
            local relativeY = input.Position.Y - Logger.logUI.AbsolutePosition.Y + Logger.logUI.CanvasPosition.Y
            contextMenu.Position = UDim2.new(0, input.Position.X - Logger.logUI.AbsolutePosition.X, 0, relativeY)
            contextMenu.Size = UDim2.new(0, 100, 0, 25)
            contextMenu.ZIndex = 10

            local copyOption = Instance.new("TextButton")
            copyOption.Name = "CopyOption"
            copyOption.Parent = contextMenu
            copyOption.BackgroundTransparency = 1
            copyOption.Size = UDim2.new(1, 0, 1, 0)
            copyOption.Font = Enum.Font.Gotham
            copyOption.Text = "Copy Log"
            copyOption.TextColor3 = COLORS.TEXT_PRIMARY
            copyOption.TextSize = 12.0
            copyOption.ZIndex = 11

            copyOption.MouseButton1Click:Connect(function()
                setclipboard(logLabel.Text)
                contextMenu:Destroy()
                Logger:info("Log entry copied to clipboard")
            end)

            -- Close context menu when clicking outside
            local closeConnection
            closeConnection = UserInputService.InputBegan:Connect(function(inputObj)
                if inputObj.UserInputType == Enum.UserInputType.MouseButton1 then
                    if contextMenu and contextMenu.Parent then
                         contextMenu:Destroy()
                    end
                    if closeConnection then
                         closeConnection:Disconnect()
                    end
                end
            end)
            -- Also close if mouse leaves the menu area
            contextMenu.MouseLeave:Connect(function()
                 task.wait(0.1) -- Small delay to allow clicking the button
                 if contextMenu and contextMenu.Parent then
                     contextMenu:Destroy()
                 end
                 if closeConnection then
                     closeConnection:Disconnect()
                 end
            end)
        end
    end)
end


-- Original updateLogUI function (will be overridden later)
local originalUpdateLogUI = function(self)
    if not self.logUI then return end

    -- Clear existing logs in UI (excluding context menu)
    for _, child in pairs(self.logUI:GetChildren()) do
        if child:IsA("TextLabel") then
            child:Destroy()
        end
    end

    -- Calculate how many logs to show
    local startIndex = math.max(1, #self.logs - self.Config.maxVisibleLogs + 1)

    -- Add logs to UI
    for i = startIndex, #self.logs do
        local log = self.logs[i]
        local logLabel = Instance.new("TextLabel")
        logLabel.Name = "LogEntry_" .. i
        logLabel.BackgroundTransparency = 1
        logLabel.Size = UDim2.new(1, -8, 0, 18)
        logLabel.Font = Enum.Font.Code
        logLabel.Text = log.formattedMessage
        logLabel.TextColor3 = self.LevelColors[log.level]
        logLabel.TextSize = 12.0
        logLabel.TextXAlignment = Enum.TextXAlignment.Left
        logLabel.TextWrapped = true
        logLabel.LayoutOrder = i
        logLabel.Parent = self.logUI

        -- Safely calculate text size with proper nil checks
        local textSizeY = 18 -- Default height
        if TextService and self.logUI and self.logUI.AbsoluteSize and self.logUI.AbsoluteSize.X > 8 then
            local success, bounds = pcall(function()
                return TextService:GetTextSize(
                    log.formattedMessage,
                    12,
                    Enum.Font.Code,
                    Vector2.new(self.logUI.AbsoluteSize.X - 8, math.huge)
                )
            end)
            if success and bounds then
                textSizeY = bounds.Y
            end
        end

        logLabel.Size = UDim2.new(1, -8, 0, textSizeY + 2)
    end

    -- Update canvas size and scroll to bottom
    task.defer(function()
        if self.logUI and self.logUI:FindFirstChild("UIListLayout") then
            local success, _ = pcall(function()
                self.logUI.CanvasSize = UDim2.new(0, 0, 0, self.logUI.UIListLayout.AbsoluteContentSize.Y)
                -- Only scroll if near the bottom already or just added
                if self.logUI.CanvasPosition.Y >= (self.logUI.CanvasSize.Y.Offset - self.logUI.AbsoluteSize.Y - 50) then
                     self.logUI.CanvasPosition = Vector2.new(0, self.logUI.CanvasSize.Y.Offset)
                end
            end)
            if not success then Logger:warning("Failed to update log UI canvas") end
        end
    end)
end

-- Override Logger's updateLogUI function to add context menu
Logger.updateLogUI = function(self)
    originalUpdateLogUI(self) -- Call the original logic first

    -- Add context menu to all log entries after they are created
    task.defer(function() -- Defer to ensure labels exist
        if not self.logUI then return end
        for _, child in pairs(self.logUI:GetChildren()) do
            if child:IsA("TextLabel") and not child:GetAttribute("ContextMenuAdded") then
                setupLogContextMenu(child)
                child:SetAttribute("ContextMenuAdded", true)
            end
        end
    end)
end

-- Clear all logs
function Logger:clearLogs()
    self.logs = {}
    if self.logUI then
        -- Clear UI elements manually before calling update
        for _, child in pairs(self.logUI:GetChildren()) do
            if child:IsA("TextLabel") or child.Name == "ContextMenu" then
                child:Destroy()
            end
        end
        self:updateLogUI() -- Update to reset canvas size
    end

    if self.Config.logToFile and writefile then
        pcall(function()
            writefile(self.Config.logFilePath, "")
        end)
    end

    self:info("Logs cleared")
end

-- Setup file logging
function Logger:setupFileLogging(enabled)
    if enabled and not writefile then
        self:error("File logging not supported - writefile function unavailable")
        return false
    end

    self.Config.logToFile = enabled

    if enabled and not isfolder("AWPDecompiled") then
        pcall(function()
            makefolder("AWPDecompiled")
        end)
    end

    self:info("File logging " .. (enabled and "enabled" or "disabled"))
    return true
end

-- Set the UI component for logs
function Logger:setLogUI(uiComponent)
    self.logUI = uiComponent

    -- Create UI list layout if it doesn't exist
    if not self.logUI:FindFirstChild("UIListLayout") then
        local listLayout = Instance.new("UIListLayout")
        listLayout.SortOrder = Enum.SortOrder.LayoutOrder
        listLayout.Padding = UDim.new(0, 2) -- Add padding here
        listLayout.Parent = self.logUI
    end

    -- Update UI with existing logs
    if self.Config.logToUI then
        self:updateLogUI()
    end
end

-- Colors (Onetap V3 theme)
local COLORS = {
    BACKGROUND = Color3.fromRGB(17, 17, 17),
    ACCENT = Color3.fromRGB(137, 46, 255),     -- Purple accent
    SECONDARY_ACCENT = Color3.fromRGB(72, 26, 128),
    TEXT_PRIMARY = Color3.fromRGB(220, 220, 220),
    TEXT_SECONDARY = Color3.fromRGB(170, 170, 170),
    BUTTON_IDLE = Color3.fromRGB(38, 38, 38),
    BUTTON_HOVER = Color3.fromRGB(45, 45, 45),
    HEADER = Color3.fromRGB(25, 25, 25),
    SIDEBAR = Color3.fromRGB(22, 22, 22),
    BORDER = Color3.fromRGB(40, 40, 40),
    SUCCESS = Color3.fromRGB(46, 204, 113),
    WARNING = Color3.fromRGB(241, 196, 15),
    ERROR = Color3.fromRGB(231, 76, 60),
    TAB_ACTIVE = Color3.fromRGB(137, 46, 255),
    TAB_INACTIVE = Color3.fromRGB(38, 38, 38),
    TOGGLE_ON = Color3.fromRGB(46, 204, 113),
    TOGGLE_OFF = Color3.fromRGB(231, 76, 60)
}

-- Create GUI elements
local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local Header = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local CloseButton = Instance.new("TextButton")
local MinimizeButton = Instance.new("TextButton")
local MinimizeAllButton = Instance.new("TextButton")
local Sidebar = Instance.new("Frame")
local Logo = Instance.new("TextLabel")
local TabContainer = Instance.new("Frame")
local TabButtonsLayout = Instance.new("UIListLayout")
local ContentFrame = Instance.new("Frame") -- Main content area where pages go

-- Set up the main GUI
ScreenGui.Name = "AWPDecompiler"
ScreenGui.Parent = LocalPlayer and LocalPlayer:WaitForChild("PlayerGui") or game:GetService("CoreGui") -- Fallback to CoreGui
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Main frame properties
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = COLORS.BACKGROUND
MainFrame.BorderColor3 = COLORS.BORDER
MainFrame.BorderSizePixel = 0
MainFrame.Position = UDim2.new(0.5, -300, 0.5, -200)
MainFrame.Size = UDim2.new(0, 600, 0, 450) -- Increased default height slightly
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ClipsDescendants = true

-- Header
Header.Name = "Header"
Header.Parent = MainFrame
Header.BackgroundColor3 = COLORS.HEADER
Header.BorderSizePixel = 0
Header.Size = UDim2.new(1, 0, 0, 30)

-- Title
Title.Name = "Title"
Title.Parent = Header
Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0, 10, 0, 0)
Title.Size = UDim2.new(0, 200, 1, 0)
Title.Font = Enum.Font.Gotham
Title.Text = "AWP.GG"
Title.TextColor3 = COLORS.ACCENT
Title.TextSize = 16.0
Title.TextXAlignment = Enum.TextXAlignment.Left

-- Window control buttons
CloseButton.Name = "CloseButton"
CloseButton.Parent = Header
CloseButton.BackgroundColor3 = COLORS.HEADER
CloseButton.BorderSizePixel = 0
CloseButton.Position = UDim2.new(1, -30, 0, 0)
CloseButton.Size = UDim2.new(0, 30, 0, 30)
CloseButton.Font = Enum.Font.GothamSemibold
CloseButton.Text = "×"
CloseButton.TextColor3 = COLORS.TEXT_PRIMARY
CloseButton.TextSize = 20.0
CloseButton.AutoButtonColor = false

MinimizeButton.Name = "MinimizeButton"
MinimizeButton.Parent = Header
MinimizeButton.BackgroundColor3 = COLORS.HEADER
MinimizeButton.BorderSizePixel = 0
MinimizeButton.Position = UDim2.new(1, -60, 0, 0)
MinimizeButton.Size = UDim2.new(0, 30, 0, 30)
MinimizeButton.Font = Enum.Font.GothamSemibold
MinimizeButton.Text = "−"
MinimizeButton.TextColor3 = COLORS.TEXT_PRIMARY
MinimizeButton.TextSize = 20.0
MinimizeButton.AutoButtonColor = false

MinimizeAllButton.Name = "MinimizeAllButton"
MinimizeAllButton.Parent = Header
MinimizeAllButton.BackgroundColor3 = COLORS.HEADER
MinimizeAllButton.BorderSizePixel = 0
MinimizeAllButton.Position = UDim2.new(1, -90, 0, 0)
MinimizeAllButton.Size = UDim2.new(0, 30, 0, 30)
MinimizeAllButton.Font = Enum.Font.GothamSemibold
MinimizeAllButton.Text = "M"
MinimizeAllButton.TextColor3 = COLORS.ACCENT
MinimizeAllButton.TextSize = 16.0
MinimizeAllButton.AutoButtonColor = false

-- Sidebar
Sidebar.Name = "Sidebar"
Sidebar.Parent = MainFrame
Sidebar.BackgroundColor3 = COLORS.SIDEBAR
Sidebar.BorderSizePixel = 0
Sidebar.Position = UDim2.new(0, 0, 0, 30)
Sidebar.Size = UDim2.new(0, 150, 1, -60) -- Adjusted size to account for status bar

-- Logo
Logo.Name = "Logo"
Logo.Parent = Sidebar
Logo.BackgroundTransparency = 1
Logo.Position = UDim2.new(0, 0, 0, 10)
Logo.Size = UDim2.new(1, 0, 0, 40)
Logo.Font = Enum.Font.GothamBold
Logo.Text = "Script Decompiler"
Logo.TextColor3 = COLORS.TEXT_PRIMARY
Logo.TextSize = 14.0
Logo.TextXAlignment = Enum.TextXAlignment.Center -- Centered logo text

-- Tab Container
TabContainer.Name = "TabContainer"
TabContainer.Parent = Sidebar
TabContainer.BackgroundTransparency = 1
TabContainer.Position = UDim2.new(0, 0, 0, 60)
TabContainer.Size = UDim2.new(1, 0, 1, -70) -- Adjusted size

-- Tab Layout
TabButtonsLayout.Parent = TabContainer
TabButtonsLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabButtonsLayout.Padding = UDim.new(0, 5)
TabButtonsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

-- Content Frame (where tab pages and part details panel go)
ContentFrame.Name = "ContentFrame"
ContentFrame.Parent = MainFrame
ContentFrame.BackgroundColor3 = COLORS.BACKGROUND -- Match background
ContentFrame.BorderSizePixel = 0
ContentFrame.Position = UDim2.new(0, 150, 0, 30)
ContentFrame.Size = UDim2.new(1, -150, 1, -60) -- Adjusted size
ContentFrame.ClipsDescendants = true -- Clip pages

-- Status Bar
local StatusBar = Instance.new("Frame")
StatusBar.Name = "StatusBar"
StatusBar.Parent = MainFrame
StatusBar.BackgroundColor3 = COLORS.HEADER
StatusBar.BorderSizePixel = 0
StatusBar.Position = UDim2.new(0, 0, 1, -30)
StatusBar.Size = UDim2.new(1, 0, 0, 30)

-- Status Label
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Name = "StatusLabel"
StatusLabel.Parent = StatusBar
StatusLabel.BackgroundTransparency = 1
StatusLabel.Position = UDim2.new(0, 10, 0, 0)
StatusLabel.Size = UDim2.new(1, -190, 1, 0) -- Adjusted size for mode indicator
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.Text = "Ready"
StatusLabel.TextColor3 = COLORS.TEXT_SECONDARY
StatusLabel.TextSize = 14.0
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Mode indicator for part finder
local ModeIndicator = Instance.new("TextLabel")
ModeIndicator.Name = "ModeIndicator"
ModeIndicator.Parent = StatusBar
ModeIndicator.BackgroundColor3 = COLORS.TOGGLE_OFF -- Default to off color
ModeIndicator.BorderSizePixel = 0
ModeIndicator.Position = UDim2.new(1, -180, 0.5, -10)
ModeIndicator.Size = UDim2.new(0, 170, 0, 20)
ModeIndicator.Font = Enum.Font.GothamSemibold
ModeIndicator.Text = "Part Script Finder: OFF"
ModeIndicator.TextColor3 = COLORS.TEXT_PRIMARY
ModeIndicator.TextSize = 12.0
ModeIndicator.TextXAlignment = Enum.TextXAlignment.Center
ModeIndicator.Visible = false -- Initially hidden, shown via settings

-- Storage for window states
local windowStates = {
    mainWindow = {
        minimized = false,
        originalSize = UDim2.new(0, 600, 0, 450), -- Match new default size
        minimizedSize = UDim2.new(0, 600, 0, 30)
    },
    codeViewers = {}
}

-- Tab pages container
local tabPages = {}
local activeTab = nil

-- Settings state
local settings = {
    partScriptFinderEnabled = false
}

-- Button hover effects
local function setupButtonHoverEffects(button, idleColor, hoverColor)
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = hoverColor}):Play()
    end)

    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = idleColor}):Play()
    end)
end

-- Toggle button creator
local function createToggleButton(parent, position, initialState, callback)
    local toggleContainer = Instance.new("Frame")
    toggleContainer.Name = "ToggleContainer"
    toggleContainer.Parent = parent
    toggleContainer.BackgroundColor3 = COLORS.BUTTON_IDLE
    toggleContainer.BorderSizePixel = 0
    toggleContainer.Position = position
    toggleContainer.Size = UDim2.new(0, 50, 0, 24)

    local toggleButton = Instance.new("Frame")
    toggleButton.Name = "ToggleButton"
    toggleButton.Parent = toggleContainer
    toggleButton.BackgroundColor3 = initialState and COLORS.TOGGLE_ON or COLORS.TOGGLE_OFF
    toggleButton.BorderSizePixel = 0
    toggleButton.Position = initialState
        and UDim2.new(1, -22, 0, 2) -- Right side when ON
        or UDim2.new(0, 2, 0, 2)   -- Left side when OFF
    toggleButton.Size = UDim2.new(0, 20, 0, 20)

    local isOn = initialState

    local clickDetector = Instance.new("TextButton") -- Use a TextButton for better input handling
    clickDetector.Name = "ClickDetector"
    clickDetector.Parent = toggleContainer
    clickDetector.BackgroundTransparency = 1
    clickDetector.Size = UDim2.new(1,0,1,0)
    clickDetector.Text = ""

    clickDetector.MouseButton1Click:Connect(function()
        isOn = not isOn

        -- Animate the toggle
        local newPosition = isOn
            and UDim2.new(1, -22, 0, 2)
            or UDim2.new(0, 2, 0, 2)
        local newColor = isOn and COLORS.TOGGLE_ON or COLORS.TOGGLE_OFF

        TweenService:Create(toggleButton, TweenInfo.new(0.2), {
            Position = newPosition,
            BackgroundColor3 = newColor
        }):Play()

        -- Call the callback with the new state
        if callback then
            callback(isOn)
        end
    end)

    return toggleContainer, function() return isOn end -- Return function to get state
end

-- Setup hover effects for buttons
setupButtonHoverEffects(CloseButton, COLORS.HEADER, Color3.fromRGB(220, 40, 40))
setupButtonHoverEffects(MinimizeButton, COLORS.HEADER, COLORS.BUTTON_HOVER)
setupButtonHoverEffects(MinimizeAllButton, COLORS.HEADER, COLORS.BUTTON_HOVER)

-- Function to toggle window minimization
local function toggleMinimize(window, windowData)
    if not window or not windowData then return end

    windowData.minimized = not windowData.minimized

    local success, _ = pcall(function()
        if windowData.minimized then
            windowData.originalSize = window.Size
            TweenService:Create(window, TweenInfo.new(0.3), {Size = windowData.minimizedSize}):Play()
        else
            TweenService:Create(window, TweenInfo.new(0.3), {Size = windowData.originalSize}):Play()
        end

        -- Toggle visibility of child elements (excluding header/status)
        for _, child in pairs(window:GetChildren()) do
            if child:IsA("GuiObject") and
               child.Name ~= "Header" and
               child.Name ~= "StatusBar" then
                child.Visible = not windowData.minimized
            end
        end
    end)
    if not success then Logger:warning("Failed to tween window minimization") end

    Logger:debug("Window " .. (window.Name or "Unknown") .. " " .. (windowData.minimized and "minimized" or "restored"))
end

-- Function to set status text (legacy method, now uses Logger)
-- Kept for potential direct use, but Logger is preferred
local function setStatus(text, color)
    if not StatusLabel then return end
    StatusLabel.Text = text
    StatusLabel.TextColor3 = color or COLORS.TEXT_SECONDARY
end

-- Function to create a tab button and its page
local function createTab(name, icon, order)
    -- Create tab button
    local tabButton = Instance.new("TextButton")
    tabButton.Name = name .. "TabButton"
    tabButton.Parent = TabContainer
    tabButton.BackgroundColor3 = COLORS.TAB_INACTIVE
    tabButton.BorderSizePixel = 0
    tabButton.Size = UDim2.new(0, 130, 0, 35)
    tabButton.Font = Enum.Font.Gotham
    tabButton.Text = icon and (icon .. " " .. name) or name
    tabButton.TextColor3 = COLORS.TEXT_PRIMARY
    tabButton.TextSize = 14.0
    tabButton.LayoutOrder = order
    tabButton.AutoButtonColor = false

    -- Left accent indicator for active tab
    local accentIndicator = Instance.new("Frame")
    accentIndicator.Name = "AccentIndicator"
    accentIndicator.Parent = tabButton
    accentIndicator.BackgroundColor3 = COLORS.ACCENT
    accentIndicator.BorderSizePixel = 0
    accentIndicator.Position = UDim2.new(0, 0, 0, 0)
    accentIndicator.Size = UDim2.new(0, 3, 1, 0)
    accentIndicator.Visible = false

    -- Create content page (will be parented under ContentFrame)
    local contentPage = Instance.new("Frame")
    contentPage.Name = name .. "Page"
    contentPage.Parent = ContentFrame -- Parent to the main content area
    contentPage.BackgroundTransparency = 1
    contentPage.BorderSizePixel = 0
    contentPage.Size = UDim2.new(1, 0, 1, 0)
    contentPage.Visible = false
    contentPage.ClipsDescendants = true -- Clip content within the page

    -- Store tab info
    tabPages[name] = {
        button = tabButton,
        page = contentPage,
        accentIndicator = accentIndicator
    }

    -- Tab button click handler
    tabButton.MouseButton1Click:Connect(function()
        if activeTab ~= name then
            switchTab(name)
        end
    end)

    Logger:debug("Created tab: " .. name)
    return contentPage
end

-- Function to switch between tabs
function switchTab(tabName)
    if not tabPages[tabName] then
        Logger:warning("Attempted to switch to non-existent tab: " .. tabName)
        return
    end

    -- Deactivate current tab if any
    if activeTab and tabPages[activeTab] then
        tabPages[activeTab].page.Visible = false
        tabPages[activeTab].button.BackgroundColor3 = COLORS.TAB_INACTIVE
        tabPages[activeTab].accentIndicator.Visible = false
    end

    -- Activate new tab
    tabPages[tabName].page.Visible = true
    tabPages[tabName].button.BackgroundColor3 = COLORS.BUTTON_HOVER -- Use hover color for active tab background
    tabPages[tabName].accentIndicator.Visible = true
    activeTab = tabName

    -- Special handling for Scripts tab when Part Details are visible
    if tabName == "Scripts" and partDetailsPanel and partDetailsPanel.Visible then
         -- Ensure layout is correct if switching back to Scripts tab
         local detailsHeight = partDetailsPanel.AbsoluteSize.Y
         scriptsOutputBox.Position = UDim2.new(0, 10, 0, partDetailsPanel.Position.Y.Offset + detailsHeight + 10)
         scriptsOutputBox.Size = UDim2.new(1, -20, 1, -(partDetailsPanel.Position.Y.Offset + detailsHeight + 20))
    elseif tabName ~= "Scripts" and partDetailsPanel and partDetailsPanel.Visible then
         -- Optionally hide part details when switching away? Or keep it visible?
         -- For now, keep it visible but ensure it's parented correctly
         partDetailsPanel.Parent = ContentFrame -- Ensure it stays in the main content area
         partDetailsPanel.Visible = true -- Keep visible even on other tabs if desired
    end


    Logger:debug("Switched to tab: " .. tabName)
end

-- Cache for script decompilation results
local decompileCache = {}

-- Function to decompile script bytecode with caching
local function decompileScript(script_instance)
    -- Check cache first
    if decompileCache[script_instance] then
        Logger:debug("Using cached decompilation for: " .. script_instance.Name)
        return decompileCache[script_instance], nil
    end

    Logger:info("Decompiling script: " .. script_instance:GetFullName())

    local successBytecode, bytecodeOrError = pcall(function()
        return getscriptbytecode(script_instance)
    end)

    if not successBytecode then
        local errorMsg = "Failed to get bytecode: " .. tostring(bytecodeOrError)
        Logger:error(errorMsg)
        return nil, errorMsg
    end

    -- Encode bytecode to base64
    local encoded = ""
    local successEncode = pcall(function()
        encoded = crypt.base64.encode(bytecodeOrError)
        -- Add padding if necessary (standard base64 requires it)
        while #encoded % 4 ~= 0 do
            encoded = encoded .. "="
        end
    end)
    if not successEncode then
         Logger:error("Failed to base64 encode bytecode.")
         return nil, "Base64 encoding failed"
    end


    Logger:debug("Sending decompilation request for: " .. script_instance.Name)
    local scriptName = script_instance:GetFullName()
    local body = "bytecode=" .. HttpService:UrlEncode(encoded) .. "&name=" .. HttpService:UrlEncode(scriptName)

    -- Send request to the decompiler server
    local successReq, response = pcall(function()
        return request({
            Url = "http://localhost:8080/decompile",
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/x-www-form-urlencoded"
            },
            Body = body
        })
    end)

    if not successReq then
        local errorMsg = "Request failed: " .. tostring(response) -- 'response' here is the error message
        Logger:error(errorMsg)
        return nil, errorMsg
    end

    -- Check response structure and status code
    if type(response) ~= "table" or not response.StatusCode then
         local errorMsg = "Invalid response from server: " .. tostring(response)
         Logger:error(errorMsg)
         return nil, errorMsg
    end

    if response.StatusCode ~= 200 then
        local errorMsg = "Server error (" .. response.StatusCode .. "): " .. (response.Body or "Unknown error")
        Logger:error(errorMsg)
        return nil, errorMsg
    end

    Logger:info("Successfully decompiled: " .. script_instance.Name)
    local decompiledSource = response.Body

    -- Cache the result
    decompileCache[script_instance] = decompiledSource

    return decompiledSource, nil
end

-- Function to create a safe filename
local function createSafeFilename(name)
    -- Replace most non-alphanumeric characters with underscores
    local safeName = name:gsub("[^%w_%.%-]", "_")
    -- Replace multiple underscores with a single one
    safeName = safeName:gsub("_+", "_")
    -- Remove leading/trailing underscores
    safeName = safeName:gsub("^_+", ""):gsub("_+$", "")

    if #safeName == 0 then safeName = "unnamed_script" end -- Handle empty names

    local basePath = "AWPDecompiled/"
    local filePath = basePath .. safeName .. ".lua"
    local counter = 1

    -- Prevent overwriting files with the same name
    while isfile and isfile(filePath) do
        filePath = basePath .. safeName .. "_" .. counter .. ".lua"
        counter = counter + 1
    end

    Logger:debug("Created safe filename: " .. filePath)
    return filePath
end

-- Function to save decompiled code
local function saveDecompiledScript(scriptName, source)
    if not writefile then
        Logger:warning("Cannot save script: writefile function not available")
        return nil
    end

    if isfolder and not isfolder("AWPDecompiled") then
        Logger:debug("Creating AWPDecompiled folder")
        local success = pcall(makefolder, "AWPDecompiled")
        if not success then
             Logger:error("Failed to create AWPDecompiled folder")
             return nil
        end
    end

    local filePath = createSafeFilename(scriptName)

    Logger:info("Saving script to file: " .. filePath)
    local success, err = pcall(writefile, filePath, source)
    if success then
        return filePath
    else
        Logger:error("Failed to write file " .. filePath .. ": " .. tostring(err))
        return nil
    end
end

-- Storage for all found scripts
local allScripts = {}
local currentScriptEntries = {} -- UI elements for the currently displayed scripts

-- Function to perform basic analysis on decompiled source code
local function analyzeScriptSource(source)
    local findings = {}
    local checksFound = {} -- Separate table for checks

    -- Keywords/Patterns to look for (General Features)
    -- Using %f[%w_]keyword%f[%W_] to match whole words better (Lua pattern frontier)
    local feature_patterns = {
        { pattern = "%f[%w_]require%f[%W_]", label = "Loads Modules (require)" },
        { pattern = "%f[%w_]getfenv%f[%W_]", label = "Environment Access (getfenv)" },
        { pattern = "%f[%w_]setfenv%f[%W_]", label = "Environment Modification (setfenv)" },
        { pattern = "%f[%w_]loadstring%f[%W_]", label = "Executes Strings (loadstring - High Risk)" },
        { pattern = "string%.reverse", label = "String Reversal (Potential Obfuscation)" },
        { pattern = "HttpService", label = "Network Requests (HttpService)" },
        { pattern = "%f[%w_]request%f[%W_]", label = "Network Requests (request - Executor?)" },
        { pattern = "TeleportService", label = "Teleportation (TeleportService)" },
        { pattern = "MarketplaceService", label = "Monetization (MarketplaceService)" },
        { pattern = "DataStoreService", label = "Data Persistence (DataStoreService)" },
        { pattern = "%f[%w_]FireServer%f[%W_]", label = "Client->Server Event (FireServer)" },
        { pattern = "%f[%w_]InvokeServer%f[%W_]", label = "Client->Server Function (InvokeServer)" },
        { pattern = "%f[%w_]OnClientEvent%f[%W_]", label = "Server->Client Event (OnClientEvent)" },
        { pattern = "%f[%w_]OnServerEvent%f[%W_]", label = "Client->Server Event (OnServerEvent)" },
        { pattern = "%f[%w_]getscriptbytecode%f[%W_]", label = "Bytecode Access (getscriptbytecode - Executor?)" },
        { pattern = "%f[%w_]hookfunction%f[%W_]", label = "Function Hooking (hookfunction - Executor?)" },
        { pattern = "%f[%w_]setclipboard%f[%W_]", label = "Clipboard Access (setclipboard)" },
        { pattern = "%f[%w_]writefile%f[%W_]", label = "File System Write (writefile - Executor?)" },
    }

    -- Patterns for common CHECKS
    local check_patterns = {
        -- Player Identity Checks
        { pattern = "player%.UserId%s*==", label = "Checks Player UserId" },
        { pattern = "player%.Name%s*==", label = "Checks Player Name" },
        { pattern = "player%.AccountAge", label = "Checks Player AccountAge" },
        { pattern = "player%.MembershipType", label = "Checks Player MembershipType" },
        -- Admin/Privilege Checks
        { pattern = "table%.find%(.-,.*player%.(Name|UserId)", label = "Checks if Player in List (table.find)" },
        { pattern = "player%:IsInGroup%s*%(%d+%)", label = "Checks Group Membership (IsInGroup)" },
        { pattern = "player%:GetRankInGroup%s*%(%d+%)", label = "Checks Group Rank (GetRankInGroup)" },
        -- Anti-Cheat / Executor Checks
        { pattern = "_G%..-%s*==", label = "Checks Global Variable (_G)" },
        { pattern = "shared%..-%s*==", label = "Checks Shared Variable (shared)" },
        { pattern = "%f[%w_](syn|getgenv|getrenv|getreg|isexecutor)%f[%W_]", label = "Checks for Executor Artifacts" },
        { pattern = "game%.PlaceId%s*==", label = "Checks Game PlaceId" },
        { pattern = "game%.JobId", label = "Checks Game JobId" },
        -- Add more specific checks if needed
    }

    -- Convert source to lowercase once for case-insensitive search
    -- Note: This might miss checks that rely on specific casing, but simplifies patterns
    local lowerSource = string.lower(source)

    local function performCheck(patternList, resultsTable, categoryName)
        for _, check in ipairs(patternList) do
            local success, found = pcall(function()
                -- Use plain find for patterns that might contain special Lua chars like '.'
                -- Also use plain find for patterns that might be complex regex-like
                if string.find(check.pattern, "[%.%[%]%(%)%%%+%-%*%?%^%$%(%)]", 1) then
                     return string.find(lowerSource, string.lower(check.pattern), 1, true)
                else
                     return string.find(lowerSource, string.lower(check.pattern), 1)
                end
            end)
            if success and found then
                table.insert(resultsTable, "• " .. check.label)
            elseif not success then
                 Logger:warning("Analysis pattern error for " .. categoryName .. ": " .. check.pattern)
            end
        end
    end

    -- Process Feature Patterns
    performCheck(feature_patterns, findings, "feature")

    -- Process Check Patterns
    performCheck(check_patterns, checksFound, "check")

    -- Combine results
    local combinedResults = {}
    if #findings > 0 then
        table.insert(combinedResults, "-- Features --")
        for _, finding in ipairs(findings) do
            table.insert(combinedResults, finding)
        end
    end
    if #checksFound > 0 then
        if #combinedResults > 0 then table.insert(combinedResults, "") end -- Add spacer
        table.insert(combinedResults, "-- Checks --")
        for _, check in ipairs(checksFound) do
            table.insert(combinedResults, check)
        end
    end

    return combinedResults
end

-- Function to create a script entry in the output box (Onetap V3 style)
local function addScriptEntry(scriptInstance, index, outputBox)
    local entry = Instance.new("Frame")
    entry.Name = "ScriptEntry_" .. index
    entry.BackgroundColor3 = COLORS.BUTTON_IDLE
    entry.BorderSizePixel = 0
    entry.Size = UDim2.new(1, -4, 0, 40)
    entry.Parent = outputBox
    entry.LayoutOrder = index

    -- Left accent bar (Onetap V3 style)
    local accentBar = Instance.new("Frame")
    accentBar.Name = "AccentBar"
    accentBar.Parent = entry
    accentBar.BackgroundColor3 = COLORS.ACCENT
    accentBar.BorderSizePixel = 0
    accentBar.Position = UDim2.new(0, 0, 0, 0)
    accentBar.Size = UDim2.new(0, 2, 1, 0)

    local scriptNameLabel = Instance.new("TextLabel")
    scriptNameLabel.Name = "ScriptName"
    scriptNameLabel.BackgroundTransparency = 1
    scriptNameLabel.Position = UDim2.new(0, 10, 0, 0)
    scriptNameLabel.Size = UDim2.new(1, -100, 1, 0)
    scriptNameLabel.Font = Enum.Font.Gotham
    scriptNameLabel.Text = scriptInstance:GetFullName()
    scriptNameLabel.TextColor3 = COLORS.TEXT_PRIMARY
    scriptNameLabel.TextSize = 13.0
    scriptNameLabel.TextXAlignment = Enum.TextXAlignment.Left
    scriptNameLabel.TextYAlignment = Enum.TextYAlignment.Center
    scriptNameLabel.TextWrapped = true
    scriptNameLabel.Parent = entry

    local typeLabel = Instance.new("TextLabel")
    typeLabel.Name = "TypeLabel"
    typeLabel.BackgroundColor3 = COLORS.SECONDARY_ACCENT
    typeLabel.BorderSizePixel = 0
    typeLabel.Position = UDim2.new(0, 10, 0.5, -8) -- Centered vertically
    typeLabel.Size = UDim2.new(0, 55, 0, 16)
    typeLabel.Font = Enum.Font.GothamSemibold
    typeLabel.Text = scriptInstance:IsA("LocalScript") and "LOCAL" or "MODULE"
    typeLabel.TextColor3 = COLORS.TEXT_PRIMARY
    typeLabel.TextSize = 9.0
    typeLabel.TextXAlignment = Enum.TextXAlignment.Center
    typeLabel.ZIndex = 2
    typeLabel.Parent = entry

    -- Update script name position to accommodate type label
    scriptNameLabel.Position = UDim2.new(0, 75, 0, 0)
    scriptNameLabel.Size = UDim2.new(1, -165, 1, 0)

    local decompileButton = Instance.new("TextButton")
    decompileButton.Name = "DecompileButton"
    decompileButton.BackgroundColor3 = COLORS.SECONDARY_ACCENT
    decompileButton.BorderSizePixel = 0
    decompileButton.Position = UDim2.new(1, -90, 0.5, -12)
    decompileButton.Size = UDim2.new(0, 80, 0, 24)
    decompileButton.Font = Enum.Font.Gotham
    decompileButton.Text = "Decompile"
    decompileButton.TextColor3 = COLORS.TEXT_PRIMARY
    decompileButton.TextSize = 12.0
    decompileButton.Parent = entry
    decompileButton.AutoButtonColor = false

    -- Button hover effect
    setupButtonHoverEffects(decompileButton, COLORS.SECONDARY_ACCENT, COLORS.ACCENT)

    -- Handle decompile button click
    decompileButton.MouseButton1Click:Connect(function()
        Logger:info("Starting decompilation for: " .. scriptInstance.Name)
        decompileButton.Text = "Wait..."
        decompileButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
        decompileButton.Interactable = false -- Disable button during processing

        -- Decompile in a separate thread to avoid freezing the UI
        task.spawn(function()
            local source, errorMsg = decompileScript(scriptInstance) -- Use errorMsg variable

            -- Re-enable button regardless of outcome
            task.defer(function()
                 decompileButton.Text = "Decompile"
                 decompileButton.BackgroundColor3 = COLORS.SECONDARY_ACCENT
                 decompileButton.Interactable = true
            end)

            if source then
                -- Save the decompiled script
                local filePath = saveDecompiledScript(scriptInstance.Name, source)

                -- Create viewer window for the decompiled code (Onetap V3 style)
                local viewerGui = Instance.new("Frame")
                viewerGui.Name = "CodeViewer_" .. scriptInstance.Name:gsub("[^%w_]", "_") -- Safer name
                viewerGui.BackgroundColor3 = COLORS.BACKGROUND
                viewerGui.BorderColor3 = COLORS.BORDER
                viewerGui.BorderSizePixel = 0
                viewerGui.Position = UDim2.new(0.5, -275, 0.5, -225) -- Slightly adjusted position
                viewerGui.Size = UDim2.new(0, 550, 0, 500) -- Increased size for analysis/link
                viewerGui.Parent = ScreenGui
                viewerGui.Active = true
                viewerGui.Draggable = true
                viewerGui.ClipsDescendants = true
                viewerGui.ZIndex = 2 -- Ensure it's above main frame

                Logger:debug("Created code viewer for: " .. scriptInstance.Name)

                -- Create window state for this viewer
                local viewerId = "viewer_" .. tostring(scriptInstance)
                windowStates.codeViewers[viewerId] = {
                    minimized = false,
                    originalSize = viewerGui.Size, -- Use the actual size
                    minimizedSize = UDim2.new(viewerGui.Size.X.Offset, 0, 0, 30)
                }

                -- Viewer header
                local viewerHeader = Instance.new("Frame")
                viewerHeader.Name = "Header"
                viewerHeader.Parent = viewerGui
                viewerHeader.BackgroundColor3 = COLORS.HEADER
                viewerHeader.BorderSizePixel = 0
                viewerHeader.Size = UDim2.new(1, 0, 0, 30)

                local headerAccent = Instance.new("Frame")
                headerAccent.Name = "HeaderAccent"
                headerAccent.Parent = viewerHeader
                headerAccent.BackgroundColor3 = COLORS.ACCENT
                headerAccent.BorderSizePixel = 0
                headerAccent.Position = UDim2.new(0, 0, 1, -2)
                headerAccent.Size = UDim2.new(1, 0, 0, 2)

                local viewerTitle = Instance.new("TextLabel")
                viewerTitle.Name = "Title"
                viewerTitle.Parent = viewerHeader
                viewerTitle.BackgroundTransparency = 1
                viewerTitle.Position = UDim2.new(0, 10, 0, 0)
                viewerTitle.Size = UDim2.new(1, -100, 1, 0) -- Adjusted size slightly
                viewerTitle.Font = Enum.Font.Gotham
                viewerTitle.Text = scriptInstance.Name
                viewerTitle.TextColor3 = COLORS.TEXT_PRIMARY
                viewerTitle.TextSize = 14.0
                viewerTitle.TextXAlignment = Enum.TextXAlignment.Left

                local closeViewerButton = Instance.new("TextButton")
                closeViewerButton.Name = "CloseButton"
                closeViewerButton.Parent = viewerHeader
                closeViewerButton.BackgroundColor3 = COLORS.HEADER
                closeViewerButton.BorderSizePixel = 0
                closeViewerButton.Position = UDim2.new(1, -30, 0, 0)
                closeViewerButton.Size = UDim2.new(0, 30, 0, 30)
                closeViewerButton.Font = Enum.Font.GothamSemibold
                closeViewerButton.Text = "×"
                closeViewerButton.TextColor3 = COLORS.TEXT_PRIMARY
                closeViewerButton.TextSize = 20.0
                closeViewerButton.AutoButtonColor = false

                local minimizeViewerButton = Instance.new("TextButton")
                minimizeViewerButton.Name = "MinimizeButton"
                minimizeViewerButton.Parent = viewerHeader
                minimizeViewerButton.BackgroundColor3 = COLORS.HEADER
                minimizeViewerButton.BorderSizePixel = 0
                minimizeViewerButton.Position = UDim2.new(1, -60, 0, 0)
                minimizeViewerButton.Size = UDim2.new(0, 30, 0, 30)
                minimizeViewerButton.Font = Enum.Font.GothamSemibold
                minimizeViewerButton.Text = "−"
                minimizeViewerButton.TextColor3 = COLORS.TEXT_PRIMARY
                minimizeViewerButton.TextSize = 20.0
                minimizeViewerButton.AutoButtonColor = false

                local copyCodeButton = Instance.new("TextButton")
                copyCodeButton.Name = "CopyCodeButton"
                copyCodeButton.Parent = viewerHeader
                copyCodeButton.BackgroundColor3 = COLORS.HEADER
                copyCodeButton.BorderSizePixel = 0
                copyCodeButton.Position = UDim2.new(1, -100, 0, 5)
                copyCodeButton.Size = UDim2.new(0, 35, 0, 20)
                copyCodeButton.Font = Enum.Font.Gotham
                copyCodeButton.Text = "Copy"
                copyCodeButton.TextColor3 = COLORS.TEXT_PRIMARY
                copyCodeButton.TextSize = 12.0
                copyCodeButton.AutoButtonColor = false

                setupButtonHoverEffects(closeViewerButton, COLORS.HEADER, Color3.fromRGB(220, 40, 40))
                setupButtonHoverEffects(minimizeViewerButton, COLORS.HEADER, COLORS.BUTTON_HOVER)
                setupButtonHoverEffects(copyCodeButton, COLORS.HEADER, COLORS.SECONDARY_ACCENT)

                local pathLabel = Instance.new("TextLabel")
                pathLabel.Name = "PathLabel"
                pathLabel.BackgroundColor3 = COLORS.BUTTON_IDLE
                pathLabel.BorderSizePixel = 0
                pathLabel.Position = UDim2.new(0, 10, 0, 40)
                pathLabel.Size = UDim2.new(1, -20, 0, 24)
                pathLabel.Font = Enum.Font.Gotham
                pathLabel.Text = "  " .. (filePath and filePath or "Not saved (writefile unavailable)")
                pathLabel.TextColor3 = COLORS.TEXT_SECONDARY
                pathLabel.TextSize = 12.0
                pathLabel.TextXAlignment = Enum.TextXAlignment.Left
                pathLabel.Parent = viewerGui

                -- << Analysis Results Frame >>
                local analysisFrame = Instance.new("Frame")
                analysisFrame.Name = "AnalysisFrame"
                analysisFrame.Parent = viewerGui
                analysisFrame.BackgroundColor3 = COLORS.BUTTON_IDLE
                analysisFrame.BorderSizePixel = 0
                analysisFrame.Position = UDim2.new(0, 10, 0, 70) -- Position below pathLabel
                analysisFrame.Size = UDim2.new(1, -20, 0, 80) -- Increased height
                analysisFrame.Visible = false -- Initially hidden
                analysisFrame.ClipsDescendants = true

                local analysisTitle = Instance.new("TextLabel")
                analysisTitle.Name = "AnalysisTitle"
                analysisTitle.Parent = analysisFrame
                analysisTitle.BackgroundTransparency = 1
                analysisTitle.Position = UDim2.new(0, 5, 0, 2)
                analysisTitle.Size = UDim2.new(1, -10, 0, 18)
                analysisTitle.Font = Enum.Font.GothamBold
                analysisTitle.Text = "Analysis Results:"
                analysisTitle.TextColor3 = COLORS.ACCENT
                analysisTitle.TextSize = 12.0
                analysisTitle.TextXAlignment = Enum.TextXAlignment.Left

                local analysisResultsLabel = Instance.new("TextLabel")
                analysisResultsLabel.Name = "AnalysisResultsLabel"
                analysisResultsLabel.Parent = analysisFrame
                analysisResultsLabel.BackgroundTransparency = 1
                analysisResultsLabel.Position = UDim2.new(0, 5, 0, 20)
                analysisResultsLabel.Size = UDim2.new(1, -10, 1, -22)
                analysisResultsLabel.Font = Enum.Font.Code
                analysisResultsLabel.Text = ""
                analysisResultsLabel.TextColor3 = COLORS.TEXT_PRIMARY
                analysisResultsLabel.TextSize = 11.0
                analysisResultsLabel.TextWrapped = true
                analysisResultsLabel.TextXAlignment = Enum.TextXAlignment.Left
                analysisResultsLabel.TextYAlignment = Enum.TextYAlignment.Top
                -- << END Analysis Frame >>

                -- << Web View Link Label >>
                local webViewLabel = Instance.new("TextLabel")
                webViewLabel.Name = "WebViewLabel"
                webViewLabel.Parent = viewerGui
                webViewLabel.BackgroundTransparency = 1
                webViewLabel.Font = Enum.Font.Gotham
                webViewLabel.TextSize = 11.0
                webViewLabel.TextColor3 = COLORS.TEXT_SECONDARY
                webViewLabel.TextXAlignment = Enum.TextXAlignment.Left
                webViewLabel.Position = UDim2.new(0, 10, 0, 156) -- Position below analysis frame (70 + 80 + 6 padding)
                webViewLabel.Size = UDim2.new(1, -20, 0, 18)
                webViewLabel.Text = "View in Browser: (Feature requires server update)" -- Placeholder
                -- << END Web View Link >>

                -- Create a scrollable frame for the code preview
                local codeScrollFrame = Instance.new("ScrollingFrame")
                codeScrollFrame.Name = "CodeScrollFrame"
                codeScrollFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
                codeScrollFrame.BorderSizePixel = 0
                codeScrollFrame.Position = UDim2.new(0, 10, 0, 180) -- Position below web view label (156 + 18 + 6 padding)
                codeScrollFrame.Size = UDim2.new(1, -20, 1, -190) -- Adjusted size
                codeScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0) -- Will be updated dynamically
                codeScrollFrame.ScrollBarThickness = 4
                codeScrollFrame.ScrollBarImageColor3 = COLORS.ACCENT
                codeScrollFrame.ScrollingDirection = Enum.ScrollingDirection.Y
                codeScrollFrame.Parent = viewerGui

                -- Add a TextLabel inside the ScrollingFrame to display the code
                local codeLabel = Instance.new("TextLabel")
                codeLabel.Name = "CodeLabel"
                codeLabel.BackgroundTransparency = 1
                codeLabel.Size = UDim2.new(1, -10, 0, 0) -- Height will be adjusted dynamically
                codeLabel.Position = UDim2.new(0, 5, 0, 0)
                codeLabel.Font = Enum.Font.Code
                codeLabel.Text = source
                codeLabel.TextColor3 = COLORS.TEXT_PRIMARY
                codeLabel.TextSize = 14.0
                codeLabel.TextWrapped = false -- Keep wrapping off for code
                codeLabel.TextXAlignment = Enum.TextXAlignment.Left
                codeLabel.TextYAlignment = Enum.TextYAlignment.Top
                codeLabel.Parent = codeScrollFrame

                -- Perform and Display Analysis
                local findings = analyzeScriptSource(source)
                if #findings > 0 then
                    analysisResultsLabel.Text = table.concat(findings, "\n")
                    analysisFrame.Visible = true
                    Logger:info("Analysis found " .. #findings .. " patterns in " .. scriptInstance.Name)
                else
                    analysisResultsLabel.Text = "No significant patterns found."
                    analysisFrame.Visible = true -- Show the frame even if nothing found
                    Logger:info("Analysis found no significant patterns in " .. scriptInstance.Name)
                end

                -- Update Web View Link (if server provides ID/URL in response)
                -- Example: Assuming response.Body is JSON like {"source": "...", "view_id": "..."}
                -- local successDecode, responseData = pcall(HttpService.JSONDecode, HttpService, response.Body)
                -- if successDecode and responseData.view_id then
                --     webViewLabel.Text = "View in Browser: http://localhost:8080/view/" .. responseData.view_id
                -- end

                -- Copy code button functionality
                copyCodeButton.MouseButton1Click:Connect(function()
                    setclipboard(source)
                    Logger:info("Code copied to clipboard: " .. scriptInstance.Name)
                    local originalText = copyCodeButton.Text
                    copyCodeButton.Text = "Copied!"
                    copyCodeButton.BackgroundColor3 = COLORS.SUCCESS
                    task.delay(2, function()
                        if copyCodeButton and copyCodeButton.Parent then -- Check if still exists
                             copyCodeButton.Text = originalText
                             copyCodeButton.BackgroundColor3 = COLORS.HEADER
                        end
                    end)
                end)

                -- Calculate text size and update canvas
                task.defer(function() -- Defer calculation as AbsoluteSize might not be ready
                    if codeScrollFrame and codeScrollFrame.Parent and TextService then
                         local successBounds, textBounds = pcall(TextService.GetTextSize, TextService,
                             source,
                             codeLabel.TextSize,
                             codeLabel.Font,
                             Vector2.new(codeScrollFrame.AbsoluteSize.X - 20, math.huge)
                         )
                         if successBounds and textBounds then
                             codeLabel.Size = UDim2.new(1, -10, 0, textBounds.Y + 10) -- Add padding
                             codeScrollFrame.CanvasSize = UDim2.new(0, textBounds.X + 20, 0, textBounds.Y + 20) -- Add padding
                         else
                              Logger:warning("Failed to calculate text bounds for code viewer.")
                              -- Fallback size calculation
                              local lineCount = select(2, string.gsub(source, "\n", "\n")) + 1
                              local estimatedHeight = lineCount * (codeLabel.TextSize * 1.2)
                              codeLabel.Size = UDim2.new(1, -10, 0, estimatedHeight)
                              codeScrollFrame.CanvasSize = UDim2.new(0, 0, 0, estimatedHeight + 20)
                         end
                    end
                end)

                -- Close viewer button event
                closeViewerButton.MouseButton1Click:Connect(function()
                    windowStates.codeViewers[viewerId] = nil
                    viewerGui:Destroy()
                    Logger:debug("Closed code viewer for: " .. scriptInstance.Name)
                end)

                -- Minimize viewer button event
                minimizeViewerButton.MouseButton1Click:Connect(function()
                    toggleMinimize(viewerGui, windowStates.codeViewers[viewerId])
                end)

                Logger:info("Successfully displayed decompiled code for: " .. scriptInstance.Name)
            else
                Logger:error("Decompilation failed for " .. scriptInstance.Name .. ": " .. (errorMsg or "Unknown error"))
            end
        end)
    end)

    table.insert(currentScriptEntries, entry)
    return entry
end

-- Function to extract important data from a part
local function getPartDetails(part)
    if not part then return "No part selected" end

    local properties = {
        Name = part.Name,
        ClassName = part.ClassName,
        Path = part:GetFullName(),
        Parent = part.Parent and part.Parent.Name or "None",
        Position = tostring(part.Position),
        Size = tostring(part.Size),
        Orientation = tostring(part.Orientation),
        Anchored = tostring(part.Anchored),
        CanCollide = tostring(part.CanCollide),
        Transparency = string.format("%.2f", part.Transparency), -- Format transparency
        Material = tostring(part.Material)
    }

    -- Get additional properties based on class
    if part:IsA("BasePart") then
        properties.BrickColor = tostring(part.BrickColor)
        properties.Reflectance = string.format("%.2f", part.Reflectance)
        properties.Mass = string.format("%.2f", part:GetMass()) -- Add mass
    end

    if part:IsA("MeshPart") then
        properties.MeshId = part.MeshId or "None"
        properties.TextureID = part.TextureID or "None"
    end

    -- Add specific properties for other common types if needed
    -- if part:IsA("Seat") then ... end

    return properties
end

-- Function to find scripts related to a specific part
local function findScriptsRelatedToPart(part)
    if not part then
        Logger:warning("No part specified for script finding")
        return {}
    end

    local relatedScripts = {}
    local partName = part.Name
    local partPath = part:GetFullName()

    Logger:info("Searching for scripts related to " .. partPath)

    -- Find scripts by hierarchy (siblings and children)
    local function checkChildrenForScripts(parent)
        if not parent then return end
        for _, child in ipairs(parent:GetChildren()) do
            if child:IsA("LocalScript") or child:IsA("ModuleScript") then
                if not table.find(relatedScripts, child) then -- Avoid duplicates
                    table.insert(relatedScripts, child)
                    Logger:debug("Found script by hierarchy: " .. child:GetFullName())
                end
            end
        end
    end

    -- Check for scripts in the part itself
    checkChildrenForScripts(part)

    -- Check for scripts in the parent
    checkChildrenForScripts(part.Parent)

    -- Find scripts that might reference this part by name or path in cached scripts
    if #allScripts > 0 then
        for _, script in ipairs(allScripts) do
            -- If we haven't already found this script in the hierarchy
            if not table.find(relatedScripts, script) then
                local decompiled = decompileCache[script]
                if decompiled then
                    -- Check for part name (case-insensitive) or full path
                    local lowerDecompiled = string.lower(decompiled)
                    if string.find(lowerDecompiled, string.lower(partName), 1, true) or
                       string.find(lowerDecompiled, string.lower(partPath), 1, true) then
                        table.insert(relatedScripts, script)
                        Logger:debug("Found script by name/path reference: " .. script:GetFullName())
                    end
                end
            end
        end
    end

    Logger:info("Found " .. #relatedScripts .. " scripts related to " .. partName)
    return relatedScripts
end

-- Create part details panel (will be parented under ContentFrame)
local partDetailsPanel = Instance.new("Frame")
partDetailsPanel.Name = "PartDetailsPanel"
partDetailsPanel.Parent = ContentFrame -- Parent to main content area
partDetailsPanel.BackgroundColor3 = COLORS.BUTTON_IDLE
partDetailsPanel.BorderSizePixel = 1
partDetailsPanel.BorderColor3 = COLORS.BORDER -- Add border
partDetailsPanel.Position = UDim2.new(0, 10, 0, 10) -- Default position near top
partDetailsPanel.Size = UDim2.new(1, -20, 0, 150) -- Default size
partDetailsPanel.Visible = false
partDetailsPanel.ZIndex = 2 -- Above script list but below code viewers
partDetailsPanel.ClipsDescendants = true

-- Part details title
local partDetailsTitle = Instance.new("Frame") -- Use frame for background
partDetailsTitle.Name = "PartDetailsTitleFrame"
partDetailsTitle.Parent = partDetailsPanel
partDetailsTitle.BackgroundColor3 = COLORS.SECONDARY_ACCENT
partDetailsTitle.BorderSizePixel = 0
partDetailsTitle.Size = UDim2.new(1, 0, 0, 24)

local partDetailsTitleLabel = Instance.new("TextLabel")
partDetailsTitleLabel.Name = "PartDetailsTitleLabel"
partDetailsTitleLabel.Parent = partDetailsTitle
partDetailsTitleLabel.BackgroundTransparency = 1
partDetailsTitleLabel.Size = UDim2.new(1, -120, 1, 0) -- Make space for buttons
partDetailsTitleLabel.Position = UDim2.new(0, 5, 0, 0)
partDetailsTitleLabel.Font = Enum.Font.GothamBold
partDetailsTitleLabel.Text = "Part Details"
partDetailsTitleLabel.TextColor3 = COLORS.TEXT_PRIMARY
partDetailsTitleLabel.TextSize = 14.0
partDetailsTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
partDetailsTitleLabel.ZIndex = 3

-- Close button for part details
local closeDetailsButton = Instance.new("TextButton")
closeDetailsButton.Name = "CloseDetailsButton"
closeDetailsButton.Parent = partDetailsTitle -- Parent to title frame
closeDetailsButton.BackgroundTransparency = 1
closeDetailsButton.Position = UDim2.new(1, -24, 0, 0)
closeDetailsButton.Size = UDim2.new(0, 24, 1, 0)
closeDetailsButton.Font = Enum.Font.GothamBold
closeDetailsButton.Text = "×"
closeDetailsButton.TextColor3 = COLORS.TEXT_PRIMARY
closeDetailsButton.TextSize = 16.0
closeDetailsButton.ZIndex = 4
closeDetailsButton.AutoButtonColor = false
setupButtonHoverEffects(closeDetailsButton, COLORS.SECONDARY_ACCENT, COLORS.ERROR)

-- Copy Position button
local copyPositionButton = Instance.new("TextButton")
copyPositionButton.Name = "CopyPositionButton"
copyPositionButton.Parent = partDetailsTitle -- Parent to title frame
copyPositionButton.BackgroundColor3 = COLORS.BUTTON_IDLE
copyPositionButton.BorderSizePixel = 0
copyPositionButton.Position = UDim2.new(1, -120, 0.5, -10) -- Position left of close button
copyPositionButton.Size = UDim2.new(0, 90, 0, 20)
copyPositionButton.Font = Enum.Font.Gotham
copyPositionButton.Text = "Copy Position"
copyPositionButton.TextColor3 = COLORS.TEXT_PRIMARY
copyPositionButton.TextSize = 11.0
copyPositionButton.ZIndex = 4
copyPositionButton.AutoButtonColor = false
setupButtonHoverEffects(copyPositionButton, COLORS.BUTTON_IDLE, COLORS.ACCENT)

-- Part info content scrolling frame
local partInfoContent = Instance.new("ScrollingFrame")
partInfoContent.Name = "PartInfoContent"
partInfoContent.Parent = partDetailsPanel
partInfoContent.BackgroundTransparency = 1
partInfoContent.Position = UDim2.new(0, 0, 0, 24) -- Below title
partInfoContent.Size = UDim2.new(1, 0, 1, -24)
partInfoContent.CanvasSize = UDim2.new(0, 0, 0, 0)
partInfoContent.ScrollBarThickness = 4
partInfoContent.ScrollBarImageColor3 = COLORS.ACCENT
partInfoContent.ZIndex = 3
partInfoContent.AutomaticCanvasSize = Enum.AutomaticSize.Y -- Auto size vertically

-- List layout for properties
local infoListLayout = Instance.new("UIListLayout")
infoListLayout.Parent = partInfoContent
infoListLayout.SortOrder = Enum.SortOrder.LayoutOrder -- Use layout order
infoListLayout.Padding = UDim.new(0, 2)

-- Function to update part details display
local function updatePartDetails(part)
    -- Clear existing details
    for _, child in pairs(partInfoContent:GetChildren()) do
        if child:IsA("Frame") or child:IsA("UIListLayout") then -- Clear frames, keep layout
             if child:IsA("Frame") then child:Destroy() end
        end
    end

    if not part then
        partDetailsTitleLabel.Text = "Part Details (None Selected)"
        return
    end

    partDetailsTitleLabel.Text = "Part Details: " .. part.Name

    local properties = getPartDetails(part)
    local index = 0

    -- Define order for common properties
    local propertyOrder = {"Name", "ClassName", "Path", "Parent", "Position", "Size", "Orientation", "Anchored", "CanCollide", "Transparency", "BrickColor", "Material", "Reflectance", "Mass", "MeshId", "TextureID"}
    local displayedProperties = {}

    -- Display ordered properties first
    for _, key in ipairs(propertyOrder) do
        local value = properties[key]
        if value ~= nil then
            local propertyRow = Instance.new("Frame")
            propertyRow.Name = "Property_" .. key
            propertyRow.Parent = partInfoContent
            propertyRow.BackgroundColor3 = index % 2 == 0 and
                Color3.fromRGB(25, 25, 25) or
                Color3.fromRGB(30, 30, 30)
            propertyRow.BorderSizePixel = 0
            propertyRow.Size = UDim2.new(1, 0, 0, 20)
            propertyRow.LayoutOrder = index
            propertyRow.ZIndex = 3

            local propertyName = Instance.new("TextLabel")
            propertyName.Name = "PropertyName"
            propertyName.Parent = propertyRow
            propertyName.BackgroundTransparency = 1
            propertyName.Position = UDim2.new(0, 5, 0, 0)
            propertyName.Size = UDim2.new(0.35, -10, 1, 0) -- Adjusted size split
            propertyName.Font = Enum.Font.Gotham
            propertyName.Text = key
            propertyName.TextColor3 = COLORS.ACCENT
            propertyName.TextSize = 12.0
            propertyName.TextXAlignment = Enum.TextXAlignment.Left
            propertyName.ZIndex = 3

            local propertyValue = Instance.new("TextLabel")
            propertyValue.Name = "PropertyValue"
            propertyValue.Parent = propertyRow
            propertyValue.BackgroundTransparency = 1
            propertyValue.Position = UDim2.new(0.35, 0, 0, 0)
            propertyValue.Size = UDim2.new(0.65, -5, 1, 0)
            propertyValue.Font = Enum.Font.Code
            propertyValue.Text = tostring(value) -- Ensure it's a string
            propertyValue.TextColor3 = COLORS.TEXT_PRIMARY
            propertyValue.TextSize = 12.0
            propertyValue.TextXAlignment = Enum.TextXAlignment.Left
            propertyValue.TextWrapped = false -- Keep on one line if possible
            propertyValue.ClipsDescendants = true
            propertyValue.ZIndex = 3

            index = index + 1
            displayedProperties[key] = true
        end
    end

    -- Display any remaining properties (alphabetically)
    local remainingKeys = {}
    for key, _ in pairs(properties) do
        if not displayedProperties[key] then
            table.insert(remainingKeys, key)
        end
    end
    table.sort(remainingKeys)

    for _, key in ipairs(remainingKeys) do
         local value = properties[key]
         -- (Create propertyRow, propertyName, propertyValue similar to above)
         local propertyRow = Instance.new("Frame")
         propertyRow.Name = "Property_" .. key
         propertyRow.Parent = partInfoContent
         propertyRow.BackgroundColor3 = index % 2 == 0 and
             Color3.fromRGB(25, 25, 25) or
             Color3.fromRGB(30, 30, 30)
         propertyRow.BorderSizePixel = 0
         propertyRow.Size = UDim2.new(1, 0, 0, 20)
         propertyRow.LayoutOrder = index
         propertyRow.ZIndex = 3

         local propertyName = Instance.new("TextLabel")
         propertyName.Name = "PropertyName"
         propertyName.Parent = propertyRow
         propertyName.BackgroundTransparency = 1
         propertyName.Position = UDim2.new(0, 5, 0, 0)
         propertyName.Size = UDim2.new(0.35, -10, 1, 0)
         propertyName.Font = Enum.Font.Gotham
         propertyName.Text = key
         propertyName.TextColor3 = COLORS.ACCENT
         propertyName.TextSize = 12.0
         propertyName.TextXAlignment = Enum.TextXAlignment.Left
         propertyName.ZIndex = 3

         local propertyValue = Instance.new("TextLabel")
         propertyValue.Name = "PropertyValue"
         propertyValue.Parent = propertyRow
         propertyValue.BackgroundTransparency = 1
         propertyValue.Position = UDim2.new(0.35, 0, 0, 0)
         propertyValue.Size = UDim2.new(0.65, -5, 1, 0)
         propertyValue.Font = Enum.Font.Code
         propertyValue.Text = tostring(value)
         propertyValue.TextColor3 = COLORS.TEXT_PRIMARY
         propertyValue.TextSize = 12.0
         propertyValue.TextXAlignment = Enum.TextXAlignment.Left
         propertyValue.TextWrapped = false
         propertyValue.ClipsDescendants = true
         propertyValue.ZIndex = 3

         index = index + 1
    end

    -- Disconnect old connection if exists
    if copyPositionButton:FindFirstChild("ClickConnection") then
        copyPositionButton.ClickConnection:Disconnect()
    end
    -- Connect copy position button
    copyPositionButton.ClickConnection = copyPositionButton.MouseButton1Click:Connect(function()
        local posText = "Vector3.new" .. properties.Position
        setclipboard(posText)
        Logger:info("Position copied to clipboard: " .. posText)
        -- Visual feedback
        local originalText = copyPositionButton.Text
        copyPositionButton.Text = "Copied!"
        copyPositionButton.BackgroundColor3 = COLORS.SUCCESS
        task.delay(1.5, function()
            if copyPositionButton and copyPositionButton.Parent then
                 copyPositionButton.Text = originalText
                 copyPositionButton.BackgroundColor3 = COLORS.BUTTON_IDLE
            end
        end)
    end)

    -- Adjust panel height dynamically (optional, but nice)
    local desiredHeight = math.min(300, 24 + index * 22) -- Max height 300
    partDetailsPanel.Size = UDim2.new(1, -20, 0, desiredHeight)
    -- Canvas size is handled by AutomaticCanvasSize = Y
end

-- Update the close button functionality
closeDetailsButton.MouseButton1Click:Connect(function()
    partDetailsPanel.Visible = false

    -- Restore original size/position of output box if it exists
    if scriptsOutputBox then
        scriptsOutputBox.Position = UDim2.new(0, 10, 0, 50) -- Original position
        scriptsOutputBox.Size = UDim2.new(1, -20, 1, -60) -- Original size
    end
    Logger:debug("Closed part details panel")
end)

-- Optimized function to dump all scripts
local function dumpScripts(outputBox)
    -- Clear the output box and reset script entries
    for _, entry in ipairs(currentScriptEntries) do
        entry:Destroy()
    end
    currentScriptEntries = {}

    -- Reset canvas position
    if outputBox then outputBox.CanvasPosition = Vector2.new(0, 0) end

    -- Use cached results if available and no search query active
    local searchQuery = tabPages["Scripts"] and tabPages["Scripts"].searchBar.Text or ""
    if #allScripts > 0 and searchQuery == "" then
        Logger:info("Using cached script list with " .. #allScripts .. " scripts")
        filterAndDisplayScripts(outputBox)
        return
    end

    -- Get all scripts
    allScripts = {}
    Logger:info("Starting script search...")
    local collectedCount = 0
    local servicesToScan = { game } -- Start with game, could add CoreGui etc. if needed

    local function collectScriptsRecursive(parent)
        local success, children = pcall(parent.GetChildren, parent)
        if not success then
            Logger:warning("Failed to get children of: " .. parent:GetFullName())
            return
        end

        for _, child in ipairs(children) do
            local isScript = false
            local successType = pcall(function()
                if child:IsA("LocalScript") or child:IsA("ModuleScript") then
                    isScript = true
                end
            end)

            if successType and isScript then
                table.insert(allScripts, child)
                collectedCount = collectedCount + 1
                if collectedCount % 100 == 0 then -- Update status periodically
                    setStatus("Searching... Found " .. collectedCount .. " scripts")
                    task.wait() -- Yield briefly
                end
            end

            -- Recurse only if it's likely to contain scripts (e.g., not a BasePart with many children)
            -- This is a heuristic and might miss scripts in unusual places
            local shouldRecurse = true
            if child:IsA("Configuration") or child:IsA("Folder") or child:IsA("Actor") or
               child:IsA("ScreenGui") or child:IsA("PlayerGui") or child:IsA("StarterGui") or
               child:IsA("StarterPlayerScripts") or child:IsA("StarterCharacterScripts") or
               child:IsA("ReplicatedStorage") or child:IsA("ServerScriptService") or
               child:IsA("Workspace") or child:IsA("ServerStorage") or
               child:IsA("Player") or child:IsA("Players") or
               child:IsA("Model") and #children < 500 -- Avoid huge models
               then
                 -- Continue recursion
            elseif #children > 0 and not child:IsA("BasePart") and not child:IsA("GuiObject") then
                 -- Recurse for other container types
            else
                 shouldRecurse = false
            end

            if shouldRecurse then
                 collectScriptsRecursive(child)
            end
        end
    end

    -- Start collection
    for _, service in ipairs(servicesToScan) do
        collectScriptsRecursive(service)
    end

    Logger:info("Script search completed, found " .. #allScripts .. " scripts")
    setStatus("Found " .. #allScripts .. " scripts. Displaying...")

    -- Display the scripts
    filterAndDisplayScripts(outputBox)
    setStatus("Ready") -- Reset status after display starts
end

-- Function to filter and display scripts based on search query
function filterAndDisplayScripts(outputBox, searchQuery, scriptsList)
    if not outputBox then
        Logger:error("OutputBox not provided for filtering scripts.")
        return
    end

    -- Clear current entries
    for _, entry in ipairs(currentScriptEntries) do
        entry:Destroy()
    end
    currentScriptEntries = {}
    outputBox.CanvasPosition = Vector2.new(0,0) -- Reset scroll

    -- Get search query if provided
    searchQuery = searchQuery or (tabPages["Scripts"] and string.lower(tabPages["Scripts"].searchBar.Text) or "")

    -- Use provided scripts list or all scripts
    local scriptsToFilter = scriptsList or allScripts
    local filteredScripts = {}

    -- Filter scripts based on search query (case-insensitive)
    local lowerQuery = string.lower(searchQuery)
    for _, script in ipairs(scriptsToFilter) do
        if script and script.Parent then -- Ensure script is valid
            if lowerQuery == "" or string.find(string.lower(script:GetFullName()), lowerQuery, 1, true) then
                table.insert(filteredScripts, script)
            end
        end
    end

    -- Display status and log
    local statusMsg = ""
    if scriptsList then
        statusMsg = "Displaying " .. #filteredScripts .. " related scripts"
    elseif searchQuery == "" then
        statusMsg = "Displaying all " .. #filteredScripts .. " scripts"
    else
        statusMsg = "Found " .. #filteredScripts .. " scripts matching query: '" .. searchQuery .. "'"
    end
    Logger:info(statusMsg)
    setStatus(statusMsg)

    -- Display scripts in batches for better performance
    local batchSize = 30 -- Increased batch size slightly
    local currentBatchIndex = 1

    -- Function to add a batch of scripts
    local function addBatch()
        local endIndex = math.min(currentBatchIndex + batchSize - 1, #filteredScripts)
        local addedInBatch = 0

        for i = currentBatchIndex, endIndex do
            if filteredScripts[i] and filteredScripts[i].Parent then -- Double check validity
                 addScriptEntry(filteredScripts[i], i, outputBox)
                 addedInBatch = addedInBatch + 1
            end
        end

        currentBatchIndex = endIndex + 1

        -- If more batches remain, schedule the next batch with a small delay
        if currentBatchIndex <= #filteredScripts then
            task.wait() -- Yield before scheduling next batch
            task.defer(addBatch) -- Use defer for subsequent batches
        else
            setStatus("Ready") -- Reset status when done displaying
            Logger:debug("Finished displaying filtered scripts.")
        end
    end

    -- Start with the first batch
    if #filteredScripts > 0 then
        addBatch()
    else
        setStatus("Ready") -- Reset status if nothing to display
    end
end

-- Function to enable/disable part script finder mode
local function togglePartScriptFinder(enabled)
    settings.partScriptFinderEnabled = enabled
    ModeIndicator.Text = "Part Script Finder: " .. (enabled and "ON" or "OFF")
    ModeIndicator.BackgroundColor3 = enabled and COLORS.TOGGLE_ON or COLORS.TOGGLE_OFF
    ModeIndicator.Visible = true -- Make sure it's visible when toggled

    Logger:info("Part Script Finder " .. (enabled and "enabled" or "disabled"))

    if enabled then
        Logger:info("Click on any part to find related scripts")
    else
        -- Hide part details panel if finder is turned off
        if partDetailsPanel then partDetailsPanel.Visible = false end
        -- Restore script output box size
        if scriptsOutputBox then
             scriptsOutputBox.Position = UDim2.new(0, 10, 0, 50)
             scriptsOutputBox.Size = UDim2.new(1, -20, 1, -60)
        end
    end
end

-- Function to minimize all windows
local function minimizeAllWindows()
    Logger:debug("Minimizing all windows")
    -- Minimize main window if not already minimized
    if not windowStates.mainWindow.minimized then
        toggleMinimize(MainFrame, windowStates.mainWindow)
    end

    -- Minimize all open code viewers
    for id, state in pairs(windowStates.codeViewers) do
        -- Find the viewer by ID in ScreenGui
        local viewerGui = ScreenGui:FindFirstChild("CodeViewer_" .. id:sub(9), true) -- Find recursively
        if viewerGui and not state.minimized then
             toggleMinimize(viewerGui, state)
        end
    end
end

-- Create tabs
local scriptsPage = createTab("Scripts", "📜", 1)
local logsPage = createTab("Logs", "📋", 2)
local settingsPage = createTab("Settings", "⚙️", 3)
local aboutPage = createTab("About", "ℹ️", 4)

-- ########################
-- ### Scripts Tab Content ###
-- ########################
local scriptsHeader = Instance.new("Frame")
scriptsHeader.Name = "ScriptsHeader"
scriptsHeader.Parent = scriptsPage
scriptsHeader.BackgroundTransparency = 1
scriptsHeader.Position = UDim2.new(0, 10, 0, 10)
scriptsHeader.Size = UDim2.new(1, -20, 0, 30)

local scriptsSearchContainer = Instance.new("Frame")
scriptsSearchContainer.Name = "SearchContainer"
scriptsSearchContainer.Parent = scriptsHeader
scriptsSearchContainer.BackgroundColor3 = COLORS.BUTTON_IDLE
scriptsSearchContainer.BorderSizePixel = 0
scriptsSearchContainer.Position = UDim2.new(0, 0, 0, 0)
scriptsSearchContainer.Size = UDim2.new(1, -100, 1, 0) -- Make space for dump button

-- Search Icon
local searchIcon = Instance.new("TextLabel")
searchIcon.Name = "SearchIcon"
searchIcon.Parent = scriptsSearchContainer
searchIcon.BackgroundTransparency = 1
searchIcon.Position = UDim2.new(0, 5, 0, 0)
searchIcon.Size = UDim2.new(0, 25, 1, 0)
searchIcon.Font = Enum.Font.GothamBold
searchIcon.Text = "🔍"
searchIcon.TextColor3 = COLORS.TEXT_SECONDARY
searchIcon.TextSize = 14.0
searchIcon.TextXAlignment = Enum.TextXAlignment.Center

-- Search Bar
local searchBar = Instance.new("TextBox")
searchBar.Name = "SearchBar"
searchBar.Parent = scriptsSearchContainer
searchBar.BackgroundTransparency = 1
searchBar.Position = UDim2.new(0, 30, 0, 0)
searchBar.Size = UDim2.new(1, -65, 1, 0)
searchBar.Font = Enum.Font.Gotham
searchBar.PlaceholderText = "Search scripts..."
searchBar.PlaceholderColor3 = COLORS.TEXT_SECONDARY
searchBar.Text = ""
searchBar.TextColor3 = COLORS.TEXT_PRIMARY
searchBar.TextSize = 14.0
searchBar.ClearTextOnFocus = false
searchBar.TextXAlignment = Enum.TextXAlignment.Left

-- Clear Search Button
local clearSearchButton = Instance.new("TextButton")
clearSearchButton.Name = "ClearSearchButton"
clearSearchButton.Parent = scriptsSearchContainer
clearSearchButton.BackgroundTransparency = 1
clearSearchButton.Position = UDim2.new(1, -35, 0, 0)
clearSearchButton.Size = UDim2.new(0, 35, 1, 0)
clearSearchButton.Font = Enum.Font.Gotham
clearSearchButton.Text = "×"
clearSearchButton.TextColor3 = COLORS.TEXT_SECONDARY
clearSearchButton.TextSize = 16.0
clearSearchButton.AutoButtonColor = false
clearSearchButton.Visible = false -- Show only when text exists
setupButtonHoverEffects(clearSearchButton, COLORS.BUTTON_IDLE, COLORS.BUTTON_HOVER) -- Subtle hover

-- Dump Scripts Button
local dumpScriptsButton = Instance.new("TextButton")
dumpScriptsButton.Name = "DumpScriptsButton"
dumpScriptsButton.Parent = scriptsHeader -- Parent to header frame
dumpScriptsButton.BackgroundColor3 = COLORS.SECONDARY_ACCENT
dumpScriptsButton.BorderSizePixel = 0
dumpScriptsButton.Position = UDim2.new(1, -90, 0, 0) -- Position right
dumpScriptsButton.Size = UDim2.new(0, 90, 1, 0)
dumpScriptsButton.Font = Enum.Font.Gotham
dumpScriptsButton.Text = "Dump Scripts"
dumpScriptsButton.TextColor3 = COLORS.TEXT_PRIMARY
dumpScriptsButton.TextSize = 12.0
dumpScriptsButton.AutoButtonColor = false
setupButtonHoverEffects(dumpScriptsButton, COLORS.SECONDARY_ACCENT, COLORS.ACCENT)

-- Output Box for Scripts tab (Positioned below header, potentially adjusted by part details)
local scriptsOutputBox = Instance.new("ScrollingFrame")
scriptsOutputBox.Name = "OutputBox"
scriptsOutputBox.Parent = scriptsPage
scriptsOutputBox.BackgroundColor3 = COLORS.BACKGROUND
scriptsOutputBox.BorderColor3 = COLORS.BORDER -- Add border
scriptsOutputBox.BorderSizePixel = 1
scriptsOutputBox.Position = UDim2.new(0, 10, 0, 50) -- Default position below header
scriptsOutputBox.Size = UDim2.new(1, -20, 1, -60) -- Default size
scriptsOutputBox.CanvasSize = UDim2.new(0, 0, 0, 0)
scriptsOutputBox.ScrollBarThickness = 4
scriptsOutputBox.ScrollBarImageColor3 = COLORS.ACCENT
scriptsOutputBox.ScrollingDirection = Enum.ScrollingDirection.Y
scriptsOutputBox.AutomaticCanvasSize = Enum.AutomaticSize.Y -- Auto size canvas

-- List layout for organizing script entries
local scriptsListLayout = Instance.new("UIListLayout")
scriptsListLayout.Parent = scriptsOutputBox
scriptsListLayout.SortOrder = Enum.SortOrder.LayoutOrder
scriptsListLayout.Padding = UDim.new(0, 4)

-- Store references in the tab data
tabPages["Scripts"].outputBox = scriptsOutputBox
tabPages["Scripts"].searchBar = searchBar
tabPages["Scripts"].clearSearchButton = clearSearchButton

-- #####################
-- ### Logs Tab Content ###
-- #####################
local logsFrame = Instance.new("Frame")
logsFrame.Name = "LogsFrame"
logsFrame.Parent = logsPage
logsFrame.BackgroundTransparency = 1
logsFrame.Position = UDim2.new(0, 10, 0, 10)
logsFrame.Size = UDim2.new(1, -20, 1, -20) -- Use full page space

-- Logs header
local logsHeader = Instance.new("Frame")
logsHeader.Name = "LogsHeader"
logsHeader.Parent = logsFrame
logsHeader.BackgroundColor3 = COLORS.BUTTON_IDLE
logsHeader.BorderSizePixel = 0
logsHeader.Size = UDim2.new(1, 0, 0, 30)

-- Log level filter
local logLevelLabel = Instance.new("TextLabel")
logLevelLabel.Name = "LogLevelLabel"
logLevelLabel.Parent = logsHeader
logLevelLabel.BackgroundTransparency = 1
logLevelLabel.Position = UDim2.new(0, 10, 0, 0)
logLevelLabel.Size = UDim2.new(0, 70, 1, 0)
logLevelLabel.Font = Enum.Font.Gotham
logLevelLabel.Text = "Log Level:"
logLevelLabel.TextColor3 = COLORS.TEXT_PRIMARY
logLevelLabel.TextSize = 12.0
logLevelLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Log level dropdown (simplified button cycle)
local logLevelDropdown = Instance.new("TextButton")
logLevelDropdown.Name = "LogLevelDropdown"
logLevelDropdown.Parent = logsHeader
logLevelDropdown.BackgroundColor3 = COLORS.SECONDARY_ACCENT
logLevelDropdown.BorderSizePixel = 0
logLevelDropdown.Position = UDim2.new(0, 80, 0, 5)
logLevelDropdown.Size = UDim2.new(0, 80, 0, 20)
logLevelDropdown.Font = Enum.Font.Gotham
logLevelDropdown.Text = Logger.LevelNames[Logger.Config.currentLevel] -- Set initial text
logLevelDropdown.TextColor3 = COLORS.TEXT_PRIMARY
logLevelDropdown.TextSize = 12.0
logLevelDropdown.AutoButtonColor = false
setupButtonHoverEffects(logLevelDropdown, COLORS.SECONDARY_ACCENT, COLORS.ACCENT)

-- Export logs button
local exportLogsButton = Instance.new("TextButton")
exportLogsButton.Name = "ExportLogsButton"
exportLogsButton.Parent = logsHeader
exportLogsButton.BackgroundColor3 = COLORS.SECONDARY_ACCENT
exportLogsButton.BorderSizePixel = 0
exportLogsButton.Position = UDim2.new(1, -180, 0, 5)
exportLogsButton.Size = UDim2.new(0, 80, 0, 20)
exportLogsButton.Font = Enum.Font.Gotham
exportLogsButton.Text = "Export Logs"
exportLogsButton.TextColor3 = COLORS.TEXT_PRIMARY
exportLogsButton.TextSize = 

-- ##########################
-- ### Settings Tab Content ###
-- ##########################
local settingsContainer = Instance.new("Frame")
settingsContainer.Name = "SettingsContainer"
settingsContainer.Parent = settingsPage
settingsContainer.BackgroundTransparency = 1
settingsContainer.Position = UDim2.new(0, 10, 0, 10)
settingsContainer.Size = UDim2.new(1, -20, 1, -20)

local settingsTitle = Instance.new("TextLabel")
settingsTitle.Name = "SettingsTitle"
settingsTitle.Parent = settingsContainer
settingsTitle.BackgroundTransparency = 1
settingsTitle.Position = UDim2.new(0, 0, 0, 0)
settingsTitle.Size = UDim2.new(1, 0, 0, 30)
settingsTitle.Font = Enum.Font.GothamBold
settingsTitle.Text = "Settings"
settingsTitle.TextColor3 = COLORS.TEXT_PRIMARY
settingsTitle.TextSize = 18.0
settingsTitle.TextXAlignment = Enum.TextXAlignment.Left

-- Helper function to create a setting row
local function createSettingRow(parent, yPos, labelText, descriptionText, initialValue, callback)
    local settingFrame = Instance.new("Frame")
    settingFrame.Name = labelText:gsub("%s", "") .. "Setting"
    settingFrame.Parent = parent
    settingFrame.BackgroundTransparency = 1
    settingFrame.Position = UDim2.new(0, 0, 0, yPos)
    settingFrame.Size = UDim2.new(1, 0, 0, 60) -- Increased height for description

    local settingLabel = Instance.new("TextLabel")
    settingLabel.Name = "Label"
    settingLabel.Parent = settingFrame
    settingLabel.BackgroundTransparency = 1
    settingLabel.Position = UDim2.new(0, 0, 0, 0)
    settingLabel.Size = UDim2.new(1, -70, 0, 24) -- Make space for toggle
    settingLabel.Font = Enum.Font.Gotham
    settingLabel.Text = labelText
    settingLabel.TextColor3 = COLORS.TEXT_PRIMARY
    settingLabel.TextSize = 14.0
    settingLabel.TextXAlignment = Enum.TextXAlignment.Left

    local settingDescription = Instance.new("TextLabel")
    settingDescription.Name = "Description"
    settingDescription.Parent = settingFrame
    settingDescription.BackgroundTransparency = 1
    settingDescription.Position = UDim2.new(0, 0, 0, 24)
    settingDescription.Size = UDim2.new(1, -70, 0, 36)
    settingDescription.Font = Enum.Font.Gotham
    settingDescription.Text = descriptionText
    settingDescription.TextColor3 = COLORS.TEXT_SECONDARY
    settingDescription.TextSize = 12.0
    settingDescription.TextWrapped = true
    settingDescription.TextXAlignment = Enum.TextXAlignment.Left
    settingDescription.TextYAlignment = Enum.TextYAlignment.Top

    local toggle, getToggleState = createToggleButton(
        settingFrame,
        UDim2.new(1, -60, 0, 0), -- Position toggle top-right
        initialValue,
        callback
    )
    toggle.Name = "Toggle"

    return settingFrame, getToggleState
end

-- Part script finder setting
local finderFrame, getFinderState = createSettingRow(
    settingsContainer,
    40, -- Y Position
    "Part Script Finder",
    "When enabled, click on any part in the game to find scripts related to it in the 'Scripts' tab.",
    settings.partScriptFinderEnabled,
    function(isEnabled)
        togglePartScriptFinder(isEnabled)
    end
)

-- Log to file setting
local fileLogFrame, getFileLogState = createSettingRow(
    settingsContainer,
    110, -- Y Position (40 + 60 + 10 padding)
    "Log to File",
    "Save logs to a file in AWPDecompiled folder. Requires 'writefile' support.",
    Logger.Config.logToFile,
    function(isEnabled)
        Logger:setupFileLogging(isEnabled)
    end
)

-- #######################
-- ### About Tab Content ###
-- #######################
local aboutContainer = Instance.new("Frame")
aboutContainer.Name = "AboutContainer"
aboutContainer.Parent = aboutPage
aboutContainer.BackgroundTransparency = 1
aboutContainer.Position = UDim2.new(0, 10, 0, 10)
aboutContainer.Size = UDim2.new(1, -20, 1, -20)

local aboutTitle = Instance.new("TextLabel")
aboutTitle.Name = "AboutTitle"
aboutTitle.Parent = aboutContainer
aboutTitle.BackgroundTransparency = 1
aboutTitle.Position = UDim2.new(0, 0, 0, 0)
aboutTitle.Size = UDim2.new(1, 0, 0, 30)
aboutTitle.Font = Enum.Font.GothamBold
aboutTitle.Text = "About AWP.GG Decompiler"
aboutTitle.TextColor3 = COLORS.TEXT_PRIMARY
aboutTitle.TextSize = 18.0
aboutTitle.TextXAlignment = Enum.TextXAlignment.Left

local aboutDescription = Instance.new("TextLabel")
aboutDescription.Name = "AboutDescription"
aboutDescription.Parent = aboutContainer
aboutDescription.BackgroundTransparency = 1
aboutDescription.Position = UDim2.new(0, 0, 0, 40)
aboutDescription.Size = UDim2.new(1, 0, 1, -50) -- Use available space
aboutDescription.Font = Enum.Font.Gotham
aboutDescription.Text = [[
AWP.GG Script Decompiler is a tool for analyzing scripts in Roblox games for educational purposes.

Features:
• Script dumping & searching
• Decompilation via local server
• Part Script Finder (Click parts to find related scripts)
• Part details display
• Basic script analysis (keywords, checks)
• Tab-based interface w/ Onetap V3 theme
• Code viewer with copy functionality
• Comprehensive logging system (UI, console, file)
• Window management (minimize, minimize all)

Disclaimer: Use responsibly and ethically. Decompiling scripts may violate the Terms of Service of Roblox or specific games. This tool is intended for learning and security research.
]]
aboutDescription.TextColor3 = COLORS.TEXT_PRIMARY
aboutDescription.TextSize = 14.0
aboutDescription.TextWrapped = true
aboutDescription.TextXAlignment = Enum.TextXAlignment.Left
aboutDescription.TextYAlignment = Enum.TextYAlignment.Top

-- ########################
-- ### Event Connections ###
-- ########################

-- Connect part click detection for Part Script Finder
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if settings.partScriptFinderEnabled and input.UserInputType == Enum.UserInputType.MouseButton1 and not gameProcessed then
        -- Raycast to find the clicked part
        local mouse = LocalPlayer:GetMouse()
        local target = mouse.Target

        if target then
            Logger:info("Part clicked: " .. target:GetFullName())
            -- Switch to Scripts tab to show results
            switchTab("Scripts")

            -- Show part details panel and update its content
            updatePartDetails(target)
            partDetailsPanel.Visible = true

            -- Adjust script output box to make room for part details
            local detailsHeight = partDetailsPanel.AbsoluteSize.Y
            local detailsYPos = partDetailsPanel.Position.Y.Offset
            scriptsOutputBox.Position = UDim2.new(0, 10, 0, detailsYPos + detailsHeight + 10) -- Position below details + padding
            scriptsOutputBox.Size = UDim2.new(1, -20, 1, -(detailsYPos + detailsHeight + 20)) -- Adjust size

            -- Find related scripts and display them
            local relatedScripts = findScriptsRelatedToPart(target)

            if #relatedScripts > 0 then
                Logger:info("Found " .. #relatedScripts .. " scripts related to " .. target:GetFullName())
                filterAndDisplayScripts(scriptsOutputBox, "", relatedScripts) -- Pass empty query, specific list
            else
                Logger:warning("No scripts found related to " .. target:GetFullName())
                -- Clear the output box
                for _, entry in ipairs(currentScriptEntries) do
                    entry:Destroy()
                end
                currentScriptEntries = {}
                scriptsOutputBox.CanvasSize = UDim2.new(0,0,0,0) -- Reset canvas
            end
        end
    end
end)

-- Connect search functionality
local debounceTimer = nil
searchBar.Changed:Connect(function(property)
    if property == "Text" then
        local query = searchBar.Text
        clearSearchButton.Visible = #query > 0 -- Show clear button if text exists

        -- Debounce search to avoid lag when typing quickly
        if debounceTimer then
            task.cancel(debounceTimer)
        end

        debounceTimer = task.delay(0.3, function()
            Logger:debug("Search query changed: " .. query)
            filterAndDisplayScripts(scriptsOutputBox) -- Filter using current text
            debounceTimer = nil
        end)
    end
end)

-- Clear search button
clearSearchButton.MouseButton1Click:Connect(function()
    searchBar.Text = ""
    clearSearchButton.Visible = false
    Logger:debug("Search cleared")
    filterAndDisplayScripts(scriptsOutputBox) -- Re-filter with empty query
end)

-- Connect minimize functionality
MinimizeButton.MouseButton1Click:Connect(function()
    toggleMinimize(MainFrame, windowStates.mainWindow)
end)

-- Connect minimize all functionality
MinimizeAllButton.MouseButton1Click:Connect(function()
    minimizeAllWindows()
end)

-- Connect Dump Scripts button
dumpScriptsButton.MouseButton1Click:Connect(function()
    Logger:info("Starting script dump")
    dumpScripts(scriptsOutputBox)
end)

-- Connect Close button
CloseButton.MouseButton1Click:Connect(function()
    Logger:info("Closing AWP.GG Script Decompiler")
    task.wait(0.1) -- Give time for log to be displayed/saved
    ScreenGui:Destroy()
end)

-- ############################
-- ### Initialization Logic ###
-- ############################

-- Activate default tab
switchTab("Scripts")

-- Initialize Performance Monitoring (part of logging system)
local performanceStats = {
    scriptsFetched = 0,
    scriptsDecompiled = 0,
    startTime = os.time()
}

-- Function to update performance stats
function updatePerformanceStats(statName, value)
    if performanceStats[statName] ~= nil then
        if type(value) == "number" then
            performanceStats[statName] = performanceStats[statName] + value
        else
            performanceStats[statName] = value -- Allow setting directly
        end
        -- Logger:debug("Updated performance stat: " .. statName .. " = " .. tostring(performanceStats[statName]))
    else
        Logger:warning("Attempted to update unknown performance stat: " .. statName)
    end
end

-- Function to get runtime in a formatted string
function getRuntime()
    local runtime = os.time() - performanceStats.startTime
    local hours = math.floor(runtime / 3600)
    local minutes = math.floor((runtime % 3600) / 60)
    local seconds = runtime % 60
    return string.format("%02d:%02d:%02d", hours, minutes, seconds)
end

-- Add performance stats logging task
task.spawn(function()
    while task.wait(60) do -- Log stats every minute
        if not ScreenGui or not ScreenGui.Parent then break end -- Stop if GUI is closed

        Logger:debug(string.format("Perf Stats - Runtime: %s, Fetched: %d, Decompiled: %d",
                    getRuntime(),
                    performanceStats.scriptsFetched,
                    performanceStats.scriptsDecompiled))
    end
end)

-- Add hooks to log script decompilation/dumping events
local originalDecompileScript = decompileScript
decompileScript = function(script_instance)
    local source, errorMsg = originalDecompileScript(script_instance)
    if source then
        updatePerformanceStats("scriptsDecompiled", 1)
    end
    return source, errorMsg
end

local originalDumpScripts = dumpScripts
dumpScripts = function(outputBox)
    originalDumpScripts(outputBox)
    -- Update stats after the dump is complete (allScripts is populated)
    updatePerformanceStats("scriptsFetched", #allScripts)
end

-- Function to check server status and display warning if needed
function checkServerStatus()
    Logger:info("Checking decompiler server status...")

    local success, response = pcall(function()
        return request({
            Url = "http://localhost:8080/status", -- Standard status endpoint
            Method = "GET",
            Timeout = 5 -- Add a timeout
        })
    end)

    if success and type(response) == "table" and response.StatusCode == 200 then
        Logger:info("Decompiler server is running and responsive.")
        return true
    else
        local errorReason = "Unknown error"
        if not success then errorReason = tostring(response) -- pcall error message
        elseif type(response) == "table" then errorReason = "Status Code: " .. (response.StatusCode or "N/A")
        else errorReason = "Invalid response type: " .. type(response)
        end

        Logger:error("Decompiler server is not responding (" .. errorReason .. "). Make sure it's running at http://localhost:8080")

        -- Create a warning overlay if server is not available
        local existingOverlay = MainFrame:FindFirstChild("WarningOverlay")
        if existingOverlay then existingOverlay:Destroy() end -- Remove old overlay

        local warningOverlay = Instance.new("Frame")
        warningOverlay.Name = "WarningOverlay"
        warningOverlay.Parent = MainFrame
        warningOverlay.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        warningOverlay.BackgroundTransparency = 0.3
        warningOverlay.BorderSizePixel = 0
        warningOverlay.Position = UDim2.new(0, 150, 0, 30) -- Cover content area
        warningOverlay.Size = UDim2.new(1, -150, 1, -60)
        warningOverlay.ZIndex = 10

        local warningLabel = Instance.new("TextLabel")
        warningLabel.Name = "WarningLabel"
        warningLabel.Parent = warningOverlay
        warningLabel.BackgroundColor3 = COLORS.ERROR
        warningLabel.BorderSizePixel = 1
        warningLabel.BorderColor3 = COLORS.BORDER
        warningLabel.Position = UDim2.new(0.5, -175, 0.5, -50)
        warningLabel.Size = UDim2.new(0, 350, 0, 100)
        warningLabel.Font = Enum.Font.GothamBold
        warningLabel.Text = "DECOMPILER SERVER NOT FOUND\n\nEnsure the Python server is running at:\nhttp://localhost:8080\n\n(" .. errorReason .. ")"
        warningLabel.TextColor3 = COLORS.TEXT_PRIMARY
        warningLabel.TextSize = 14.0
        warningLabel.TextWrapped = true
        warningLabel.ZIndex = 11

        local dismissButton = Instance.new("TextButton")
        dismissButton.Name = "DismissButton"
        dismissButton.Parent = warningLabel
        dismissButton.BackgroundColor3 = COLORS.SECONDARY_ACCENT
        dismissButton.BorderSizePixel = 0
        dismissButton.Position = UDim2.new(0.5, -50, 1, -30)
        dismissButton.Size = UDim2.new(0, 100, 0, 25)
        dismissButton.Font = Enum.Font.Gotham
        dismissButton.Text = "Dismiss"
        dismissButton.TextColor3 = COLORS.TEXT_PRIMARY
        dismissButton.TextSize = 14.0
        dismissButton.ZIndex = 12
        setupButtonHoverEffects(dismissButton, COLORS.SECONDARY_ACCENT, COLORS.ACCENT)

        dismissButton.MouseButton1Click:Connect(function()
            warningOverlay:Destroy()
        end)

        return false
    end
end

-- Run server status check shortly after startup
task.delay(1, checkServerStatus)

-- Final initialization message
Logger:info("AWP.GG Script Decompiler initialized")
Logger:info("Server should be running at http://localhost:8080")
Logger:debug("Debug logging is enabled.")

-- Return the GUI and Logger (for debugging and extension purposes)
return {
    ScreenGui = ScreenGui,
    Logger = Logger
}
