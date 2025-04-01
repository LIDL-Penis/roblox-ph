local GuiLibrary = {}

-- Main functions to create GUI elements
function GuiLibrary:CreateWindow(title)
    local window = {
        Tabs = {},
        ActiveTab = nil
    }
    
    -- Create main frame (dark background with blue accents)
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 600, 0, 400)
    mainFrame.Position = UDim2.new(0.5, -300, 0.5, -200)
    mainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
    mainFrame.BorderSizePixel = 0
    
    -- Create title bar
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 30)
    titleBar.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    
    local titleText = Instance.new("TextLabel")
    titleText.Text = title
    titleText.Size = UDim2.new(1, 0, 1, 0)
    titleText.BackgroundTransparency = 1
    titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleText.TextSize = 16
    titleText.Font = Enum.Font.SourceSansBold
    titleText.Parent = titleBar
    
    -- Create tab container
    local tabContainer = Instance.new("Frame")
    tabContainer.Size = UDim2.new(0.25, 0, 1, -30)
    tabContainer.Position = UDim2.new(0, 0, 0, 30)
    tabContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    tabContainer.BorderSizePixel = 0
    tabContainer.Parent = mainFrame
    
    -- Create content container
    local contentContainer = Instance.new("Frame")
    contentContainer.Size = UDim2.new(0.75, 0, 1, -30)
    contentContainer.Position = UDim2.new(0.25, 0, 0, 30)
    contentContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    contentContainer.BorderSizePixel = 0
    contentContainer.Parent = mainFrame
    
    -- Function to create a new tab
    function window:AddTab(tabName)
        local tab = {
            Sections = {}
        }
        
        local tabButton = Instance.new("TextButton")
        tabButton.Size = UDim2.new(1, 0, 0, 30)
        tabButton.Position = UDim2.new(0, 0, 0, #self.Tabs * 30)
        tabButton.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
        tabButton.BorderSizePixel = 0
        tabButton.Text = tabName
        tabButton.TextColor3 = Color3.fromRGB(150, 150, 150)
        tabButton.Font = Enum.Font.SourceSans
        tabButton.TextSize = 14
        tabButton.Parent = tabContainer
        
        local contentFrame = Instance.new("ScrollingFrame")
        contentFrame.Size = UDim2.new(1, 0, 1, 0)
        contentFrame.BackgroundTransparency = 1
        contentFrame.BorderSizePixel = 0
        contentFrame.ScrollBarThickness = 4
        contentFrame.Visible = false
        contentFrame.Parent = contentContainer
        
        tabButton.MouseButton1Click:Connect(function()
            if self.ActiveTab then
                self.ActiveTab.Button.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
                self.ActiveTab.Button.TextColor3 = Color3.fromRGB(150, 150, 150)
                self.ActiveTab.Content.Visible = false
            end
            
            tabButton.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
            tabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            contentFrame.Visible = true
            
            self.ActiveTab = {Button = tabButton, Content = contentFrame}
        end)
        
        -- Function to add a section to the tab
        function tab:AddSection(sectionName)
            local section = {}
            local sectionIndex = #self.Sections
            
            local sectionFrame = Instance.new("Frame")
            sectionFrame.Size = UDim2.new(0.95, 0, 0, 30)
            sectionFrame.Position = UDim2.new(0.025, 0, 0, 10 + sectionIndex * 160)
            sectionFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
            sectionFrame.BorderSizePixel = 0
            sectionFrame.Parent = contentFrame
            
            local sectionHeader = Instance.new("TextLabel")
            sectionHeader.Size = UDim2.new(1, 0, 0, 30)
            sectionHeader.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
            sectionHeader.BorderSizePixel = 0
            sectionHeader.Text = sectionName
            sectionHeader.TextColor3 = Color3.fromRGB(255, 255, 255)
            sectionHeader.TextSize = 14
            sectionHeader.Font = Enum.Font.SourceSansBold
            sectionHeader.Parent = sectionFrame
            
            local sectionContent = Instance.new("Frame")
            sectionContent.Size = UDim2.new(1, 0, 0, 130)
            sectionContent.Position = UDim2.new(0, 0, 0, 30)
            sectionContent.BackgroundTransparency = 1
            sectionContent.Parent = sectionFrame
            
            local elementCount = 0
            
            -- Function to add a toggle
            function section:AddToggle(name, default, callback)
                local toggle = {}
                
                local toggleFrame = Instance.new("Frame")
                toggleFrame.Size = UDim2.new(1, -10, 0, 25)
                toggleFrame.Position = UDim2.new(0, 5, 0, 5 + elementCount * 30)
                toggleFrame.BackgroundTransparency = 1
                toggleFrame.Parent = sectionContent
                
                local toggleButton = Instance.new("Frame")
                toggleButton.Size = UDim2.new(0, 16, 0, 16)
                toggleButton.Position = UDim2.new(0, 5, 0.5, -8)
                toggleButton.BackgroundColor3 = default and Color3.fromRGB(0, 120, 255) or Color3.fromRGB(50, 50, 55)
                toggleButton.BorderSizePixel = 0
                toggleButton.Parent = toggleFrame
                
                local toggleLabel = Instance.new("TextLabel")
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
                toggleClickArea.Size = UDim2.new(1, 0, 1, 0)
                toggleClickArea.BackgroundTransparency = 1
                toggleClickArea.Text = ""
                toggleClickArea.Parent = toggleFrame
                
                toggleClickArea.MouseButton1Click:Connect(function()
                    enabled = not enabled
                    toggleButton.BackgroundColor3 = enabled and Color3.fromRGB(0, 120, 255) or Color3.fromRGB(50, 50, 55)
                    if callback then callback(enabled) end
                end)
                
                elementCount = elementCount + 1
                return toggle
            end
            
            -- Function to add a slider
            function section:AddSlider(name, min, max, default, callback)
                local slider = {}
                
                local sliderFrame = Instance.new("Frame")
                sliderFrame.Size = UDim2.new(1, -10, 0, 45)
                sliderFrame.Position = UDim2.new(0, 5, 0, 5 + elementCount * 30)
                sliderFrame.BackgroundTransparency = 1
                sliderFrame.Parent = sectionContent
                
                local sliderLabel = Instance.new("TextLabel")
                sliderLabel.Text = name
                sliderLabel.Size = UDim2.new(1, 0, 0, 20)
                sliderLabel.BackgroundTransparency = 1
                sliderLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
                sliderLabel.TextSize = 14
                sliderLabel.Font = Enum.Font.SourceSans
                sliderLabel.TextXAlignment = Enum.TextXAlignment.Left
                sliderLabel.Parent = sliderFrame
                
                local valueDisplay = Instance.new("TextLabel")
                valueDisplay.Text = default .. "%"
                valueDisplay.Size = UDim2.new(0, 40, 0, 20)
                valueDisplay.Position = UDim2.new(1, -40, 0, 0)
                valueDisplay.BackgroundTransparency = 1
                valueDisplay.TextColor3 = Color3.fromRGB(200, 200, 200)
                valueDisplay.TextSize = 14
                valueDisplay.Font = Enum.Font.SourceSans
                valueDisplay.Parent = sliderFrame
                
                local sliderBackground = Instance.new("Frame")
                sliderBackground.Size = UDim2.new(1, 0, 0, 8)
                sliderBackground.Position = UDim2.new(0, 0, 0, 25)
                sliderBackground.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
                sliderBackground.BorderSizePixel = 0
                sliderBackground.Parent = sliderFrame
                
                local sliderFill = Instance.new("Frame")
                local percent = (default - min) / (max - min)
                sliderFill.Size = UDim2.new(percent, 0, 1, 0)
                sliderFill.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
                sliderFill.BorderSizePixel = 0
                sliderFill.Parent = sliderBackground
                
                local sliderButton = Instance.new("TextButton")
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
                
                elementCount = elementCount + 2
                return slider
            end
            
            self.Sections[#self.Sections + 1] = section
            return section
        end
        
        self.Tabs[#self.Tabs + 1] = tab
        
        if #self.Tabs == 1 then
            tabButton.MouseButton1Click:Fire()
        end
        
        return tab
    end
    
    return window
end

return GuiLibrary
