local GuiLibrary = {}

function GuiLibrary:CreateWindow(title)
    -- First, ensure we create a proper ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "PandoraInspired"
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.ResetOnSpawn = false
    
    -- Try to place in CoreGui first (for exploits), then fallback to PlayerGui
    local success = pcall(function()
        screenGui.Parent = game:GetService("CoreGui")
    end)
    
    if not success then
        screenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    end
    
    local window = {
        Tabs = {},
        ActiveTab = nil,
        ScreenGui = screenGui
    }
    
    -- Create main frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 600, 0, 400)
    mainFrame.Position = UDim2.new(0.5, -300, 0.5, -200)
    mainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = screenGui
    
    -- Add corner radius to main frame
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0, 6)
    uiCorner.Parent = mainFrame
    
    -- Create title bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 30)
    titleBar.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    
    -- Add rounded corners to title bar
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 6)
    titleCorner.Parent = titleBar
    
    -- Title text
    local titleText = Instance.new("TextLabel")
    titleText.Name = "Title"
    titleText.Text = title
    titleText.Size = UDim2.new(1, -10, 1, 0)
    titleText.Position = UDim2.new(0, 10, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleText.TextSize = 16
    titleText.Font = Enum.Font.SourceSansBold
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Parent = titleBar
    
    -- Create tab container
    local tabContainer = Instance.new("Frame")
    tabContainer.Name = "TabContainer"
    tabContainer.Size = UDim2.new(0.25, 0, 1, -30)
    tabContainer.Position = UDim2.new(0, 0, 0, 30)
    tabContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    tabContainer.BorderSizePixel = 0
    tabContainer.Parent = mainFrame
    
    -- Add stroke to tab container
    local tabContainerStroke = Instance.new("UIStroke")
    tabContainerStroke.Color = Color3.fromRGB(30, 30, 35)
    tabContainerStroke.Thickness = 1
    tabContainerStroke.Parent = tabContainer
    
    -- Create content container
    local contentContainer = Instance.new("Frame")
    contentContainer.Name = "ContentContainer"
    contentContainer.Size = UDim2.new(0.75, 0, 1, -30)
    contentContainer.Position = UDim2.new(0.25, 0, 0, 30)
    contentContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    contentContainer.BorderSizePixel = 0
    contentContainer.Parent = mainFrame
    
    -- Tab selection function
    function window:SelectTab(tabIndex)
        local targetTab = self.Tabs[tabIndex]
        if not targetTab then return end
        
        -- Deselect current tab if one is active
        if self.ActiveTab then
            self.ActiveTab.Button.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
            self.ActiveTab.Button.TextColor3 = Color3.fromRGB(150, 150, 150)
            self.ActiveTab.Content.Visible = false
        end
        
        -- Select new tab
        local tabButton = targetTab.Button
        local contentFrame = targetTab.Content
        
        tabButton.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
        tabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        contentFrame.Visible = true
        
        self.ActiveTab = {Button = tabButton, Content = contentFrame}
    end
    
    -- Function to create a new tab
    function window:AddTab(tabName)
        local tab = {
            Sections = {},
            Button = nil,
            Content = nil
        }
        
        local tabIndex = #self.Tabs + 1
        
        -- Create tab button
        local tabButton = Instance.new("TextButton")
        tabButton.Name = "Tab_" .. tabName
        tabButton.Size = UDim2.new(1, 0, 0, 30)
        tabButton.Position = UDim2.new(0, 0, 0, (tabIndex - 1) * 30)
        tabButton.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
        tabButton.BorderSizePixel = 0
        tabButton.Text = tabName
        tabButton.TextColor3 = Color3.fromRGB(150, 150, 150)
        tabButton.TextSize = 14
        tabButton.Font = Enum.Font.SourceSans
        tabButton.Parent = tabContainer
        
        -- Create content frame for this tab
        local contentFrame = Instance.new("ScrollingFrame")
        contentFrame.Name = "Content_" .. tabName
        contentFrame.Size = UDim2.new(1, 0, 1, 0)
        contentFrame.BackgroundTransparency = 1
        contentFrame.BorderSizePixel = 0
        contentFrame.ScrollBarThickness = 4
        contentFrame.Visible = false
        contentFrame.ScrollingDirection = Enum.ScrollingDirection.Y
        contentFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
        contentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        contentFrame.Parent = contentContainer
        
        tab.Button = tabButton
        tab.Content = contentFrame
        
        -- Store the tab
        self.Tabs[tabIndex] = tab
        
        -- Connect tab button click
        tabButton.MouseButton1Click:Connect(function()
            self:SelectTab(tabIndex)
        end)
        
        -- Section creation function
        function tab:AddSection(sectionName)
            local section = {}
            local sectionIndex = #self.Sections
            
            -- Create section frame
            local sectionFrame = Instance.new("Frame")
            sectionFrame.Name = "Section_" .. sectionName
            sectionFrame.Size = UDim2.new(0.95, 0, 0, 30) -- Initial height
            sectionFrame.Position = UDim2.new(0.025, 0, 0, 10 + sectionIndex * 160)
            sectionFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
            sectionFrame.BorderSizePixel = 0
            sectionFrame.Parent = contentFrame
            
            -- Add UI corner
            local sectionCorner = Instance.new("UICorner")
            sectionCorner.CornerRadius = UDim.new(0, 4)
            sectionCorner.Parent = sectionFrame
            
            -- Create section header
            local sectionHeader = Instance.new("TextLabel")
            sectionHeader.Name = "Header"
            sectionHeader.Size = UDim2.new(1, 0, 0, 30)
            sectionHeader.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
            sectionHeader.BorderSizePixel = 0
            sectionHeader.Text = sectionName
            sectionHeader.TextColor3 = Color3.fromRGB(255, 255, 255)
            sectionHeader.TextSize = 14
            sectionHeader.Font = Enum.Font.SourceSansBold
            sectionHeader.Parent = sectionFrame
            
            -- Add header corner
            local headerCorner = Instance.new("UICorner")
            headerCorner.CornerRadius = UDim.new(0, 4)
            headerCorner.Parent = sectionHeader
            
            -- Create section content
            local sectionContent = Instance.new("Frame")
            sectionContent.Name = "Content"
            sectionContent.Size = UDim2.new(1, 0, 0, 130)
            sectionContent.Position = UDim2.new(0, 0, 0, 30)
            sectionContent.BackgroundTransparency = 1
            sectionContent.Parent = sectionFrame
            
            local elementCount = 0
            
            -- Add toggle element
            function section:AddToggle(name, default, callback)
                local toggle = {}
                
                local toggleFrame = Instance.new("Frame")
                toggleFrame.Name = "Toggle_" .. name
                toggleFrame.Size = UDim2.new(1, -10, 0, 25)
                toggleFrame.Position = UDim2.new(0, 5, 0, 5 + elementCount * 30)
                toggleFrame.BackgroundTransparency = 1
                toggleFrame.Parent = sectionContent
                
                local toggleButton = Instance.new("Frame")
                toggleButton.Name = "Button"
                toggleButton.Size = UDim2.new(0, 16, 0, 16)
                toggleButton.Position = UDim2.new(0, 5, 0.5, -8)
                toggleButton.BackgroundColor3 = default and Color3.fromRGB(0, 120, 255) or Color3.fromRGB(50, 50, 55)
                toggleButton.BorderSizePixel = 0
                toggleButton.Parent = toggleFrame
                
                -- Add corner to toggle button
                local toggleCorner = Instance.new("UICorner")
                toggleCorner.CornerRadius = UDim.new(0, 3)
                toggleCorner.Parent = toggleButton
                
                local toggleLabel = Instance.new("TextLabel")
                toggleLabel.Name = "Label"
                toggleLabel.Text = name
                toggleLabel.Size = UDim2.new(1, -30, 1, 0)
                toggleLabel.Position = UDim2.new(0, 30, 0, 0)
                toggleLabel.BackgroundTransparency = 1
                toggleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
                toggleLabel.TextSize = 14
                toggleLabel.Font = Enum.Font.SourceSans
                toggleLabel.TextXAlignment = Enum.TextXAlignment.Left
                toggleLabel.Parent = toggleFrame
                
                local enabled = default or false
                
                local toggleClickArea = Instance.new("TextButton")
                toggleClickArea.Name = "ClickArea"
                toggleClickArea.Size = UDim2.new(1, 0, 1, 0)
                toggleClickArea.BackgroundTransparency = 1
                toggleClickArea.Text = ""
                toggleClickArea.Parent = toggleFrame
                
                toggleClickArea.MouseButton1Click:Connect(function()
                    enabled = not enabled
                    toggleButton.BackgroundColor3 = enabled and Color3.fromRGB(0, 120, 255) or Color3.fromRGB(50, 50, 55)
                    if callback then callback(enabled) end
                end)
                
                function toggle:SetState(state)
                    enabled = state
                    toggleButton.BackgroundColor3 = enabled and Color3.fromRGB(0, 120, 255) or Color3.fromRGB(50, 50, 55)
                    if callback then callback(enabled) end
                end
                
                function toggle:GetState()
                    return enabled
                end
                
                elementCount = elementCount + 1
                return toggle
            end
            
            -- Add slider element
            function section:AddSlider(name, min, max, default, callback)
                local slider = {}
                
                local sliderFrame = Instance.new("Frame")
                sliderFrame.Name = "Slider_" .. name
                sliderFrame.Size = UDim2.new(1, -10, 0, 45)
                sliderFrame.Position = UDim2.new(0, 5, 0, 5 + elementCount * 30)
                sliderFrame.BackgroundTransparency = 1
                sliderFrame.Parent = sectionContent
                
                local sliderLabel = Instance.new("TextLabel")
                sliderLabel.Name = "Label"
                sliderLabel.Text = name
                sliderLabel.Size = UDim2.new(1, -50, 0, 20)
                sliderLabel.BackgroundTransparency = 1
                sliderLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
                sliderLabel.TextSize = 14
                sliderLabel.Font = Enum.Font.SourceSans
                sliderLabel.TextXAlignment = Enum.TextXAlignment.Left
                sliderLabel.Parent = sliderFrame
                
                local valueDisplay = Instance.new("TextLabel")
                valueDisplay.Name = "Value"
                valueDisplay.Text = default .. "%"
                valueDisplay.Size = UDim2.new(0, 40, 0, 20)
                valueDisplay.Position = UDim2.new(1, -40, 0, 0)
                valueDisplay.BackgroundTransparency = 1
                valueDisplay.TextColor3 = Color3.fromRGB(200, 200, 200)
                valueDisplay.TextSize = 14
                valueDisplay.Font = Enum.Font.SourceSans
                valueDisplay.Parent = sliderFrame
                
                local sliderBackground = Instance.new("Frame")
                sliderBackground.Name = "Background"
                sliderBackground.Size = UDim2.new(1, 0, 0, 8)
                sliderBackground.Position = UDim2.new(0, 0, 0, 25)
                sliderBackground.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
                sliderBackground.BorderSizePixel = 0
                sliderBackground.Parent = sliderFrame
                
                -- Add corner to slider background
                local bgCorner = Instance.new("UICorner")
                bgCorner.CornerRadius = UDim.new(0, 4)
                bgCorner.Parent = sliderBackground
                
                local sliderFill = Instance.new("Frame")
                sliderFill.Name = "Fill"
                local percent = (default - min) / (max - min)
                sliderFill.Size = UDim2.new(percent, 0, 1, 0)
                sliderFill.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
                sliderFill.BorderSizePixel = 0
                sliderFill.Parent = sliderBackground
                
                -- Add corner to slider fill
                local fillCorner = Instance.new("UICorner")
                fillCorner.CornerRadius = UDim.new(0, 4)
                fillCorner.Parent = sliderFill
                
                local sliderButton = Instance.new("TextButton")
                sliderButton.Name = "Button"
                sliderButton.Size = UDim2.new(1, 0, 1, 0)
                sliderButton.BackgroundTransparency = 1
                sliderButton.Text = ""
                sliderButton.Parent = sliderBackground
                
                local value = default
                
                local function updateSlider(input)
                    local pos = input.Position.X - sliderBackground.AbsolutePosition.X
                    local size = sliderBackground.AbsoluteSize.X
                    local percent = math.clamp(pos / size, 0, 1)
                    
                    sliderFill.Size = UDim2.new(percent, 0, 1, 0)
                    value = math.floor(min + (max - min) * percent)
                    valueDisplay.Text = value .. "%"
                    
                    if callback then callback(value) end
                end
                
                sliderButton.MouseButton1Down:Connect(function(input)
                    updateSlider({Position = {X = input.Position.X}})
                    
                    local connection
                    connection = game:GetService("UserInputService").InputChanged:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseMovement then
                            updateSlider({Position = {X = input.Position.X}})
                        end
                    end)
                    
                    game:GetService("UserInputService").InputEnded:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 then
                            if connection then connection:Disconnect() end
                        end
                    end)
                end)
                
                function slider:SetValue(newValue)
                    value = math.clamp(newValue, min, max)
                    local percent = (value - min) / (max - min)
                    sliderFill.Size = UDim2.new(percent, 0, 1, 0)
                    valueDisplay.Text = value .. "%"
                    if callback then callback(value) end
                end
                
                function slider:GetValue()
                    return value
                end
                
                elementCount = elementCount + 2
                return slider
            end
            
            -- Add dropdown element
            function section:AddDropdown(name, options, default, callback)
                local dropdown = {}
                
                local dropdownFrame = Instance.new("Frame")
                dropdownFrame.Name = "Dropdown_" .. name
                dropdownFrame.Size = UDim2.new(1, -10, 0, 45)
                dropdownFrame.Position = UDim2.new(0, 5, 0, 5 + elementCount * 30)
                dropdownFrame.BackgroundTransparency = 1
                dropdownFrame.Parent = sectionContent
                
                local dropdownLabel = Instance.new("TextLabel")
                dropdownLabel.Name = "Label"
                dropdownLabel.Text = name
                dropdownLabel.Size = UDim2.new(1, 0, 0, 20)
                dropdownLabel.BackgroundTransparency = 1
                dropdownLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
                dropdownLabel.TextSize = 14
                dropdownLabel.Font = Enum.Font.SourceSans
                dropdownLabel.TextXAlignment = Enum.TextXAlignment.Left
                dropdownLabel.Parent = dropdownFrame
                
                local dropdownButton = Instance.new("TextButton")
                dropdownButton.Name = "Button"
                dropdownButton.Text = default or options[1] or "Select"
                dropdownButton.Size = UDim2.new(1, 0, 0, 25)
                dropdownButton.Position = UDim2.new(0, 0, 0, 20)
                dropdownButton.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
                dropdownButton.BorderSizePixel = 0
                dropdownButton.TextColor3 = Color3.fromRGB(200, 200, 200)
                dropdownButton.TextSize = 14
                dropdownButton.Font = Enum.Font.SourceSans
                dropdownButton.Parent = dropdownFrame
                
                -- Add corner to dropdown button
                local buttonCorner = Instance.new("UICorner")
                buttonCorner.CornerRadius = UDim.new(0, 4)
                buttonCorner.Parent = dropdownButton
                
                local dropdownMenu = Instance.new("Frame")
                dropdownMenu.Name = "Menu"
                dropdownMenu.Size = UDim2.new(1, 0, 0, #options * 25)
                dropdownMenu.Position = UDim2.new(0, 0, 1, 0)
                dropdownMenu.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
                dropdownMenu.BorderSizePixel = 0
                dropdownMenu.Visible = false
                dropdownMenu.ZIndex = 10
                dropdownMenu.Parent = dropdownButton
                
                -- Add corner to dropdown menu
                local menuCorner = Instance.new("UICorner")
                menuCorner.CornerRadius = UDim.new(0, 4)
                menuCorner.Parent = dropdownMenu
                
                local isOpen = false
                local selected = default or options[1] or "Select"
                
                dropdownButton.MouseButton1Click:Connect(function()
                    isOpen = not isOpen
                    dropdownMenu.Visible = isOpen
                end)
                
                for i, option in ipairs(options) do
                    local optionButton = Instance.new("TextButton")
                    optionButton.Name = "Option_" .. option
                    optionButton.Text = option
                    optionButton.Size = UDim2.new(1, 0, 0, 25)
                    optionButton.Position = UDim2.new(0, 0, 0, (i-1) * 25)
                    optionButton.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
                    optionButton.BorderSizePixel = 0
                    optionButton.TextColor3 = Color3.fromRGB(200, 200, 200)
                    optionButton.TextSize = 14
                    optionButton.Font = Enum.Font.SourceSans
                    optionButton.ZIndex = 11
                    optionButton.Parent = dropdownMenu
                    
                    optionButton.MouseButton1Click:Connect(function()
                        selected = option
                        dropdownButton.Text = option
                        isOpen = false
                        dropdownMenu.Visible = false
                        if callback then callback(option) end
                    end)
                end
                
                function dropdown:Select(option)
                    for i, opt in ipairs(options) do
                        if opt == option then
                            selected = option
                            dropdownButton.Text = option
                            if callback then callback(option) end
                            return
                        end
                    end
                end
                
                function dropdown:GetSelected()
                    return selected
                end
                
                elementCount = elementCount + 2
                return dropdown
            end
            
            -- Update section size based on elements
            local function updateSectionSize()
                sectionContent.Size = UDim2.new(1, 0, 0, 10 + elementCount * 30)
                sectionFrame.Size = UDim2.new(0.95, 0, 0, 40 + elementCount * 30)
            end
            
            section.Frame = sectionFrame
            section.UpdateSize = updateSectionSize
            
            -- Store the section
            self.Sections[#self.Sections + 1] = section
            
            return section
        end
        
        return tab
    end
    
    -- Make the GUI draggable
    local dragging = false
    local dragInput
    local dragStart
    local startPos
    
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
        end
    end)
    
    game:GetService("UserInputService").InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(
                startPos.X.Scale, 
                startPos.X.Offset + delta.X, 
                startPos.Y.Scale, 
                startPos.Y.Offset + delta.Y
            )
        end
    end)
    
    -- Select first tab when it's added
    window.SelectFirstTab = function()
        if #window.Tabs > 0 then
            window:SelectTab(1)
        end
    end
    
    return window
end

return GuiLibrary
