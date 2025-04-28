--[[
    InterfaceManager.lua
    Part of FluidUI Library for Roblox
    
    Manages UI interactions, animations, and theme control
    Features:
    - Input management
    - Animation handling
    - Theme control
    - UI element state tracking
]]

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local InterfaceManager = {
    InputConnections = {},
    HoveredElements = {},
    FocusedElement = nil,
    ActiveElements = {},
    AnimationTweens = {},
    DraggingElement = nil,
    ClickedElement = nil,
    DoubleClickThreshold = 0.3,
    LastClickTime = 0,
    DragThreshold = 5, -- pixels
    DragData = {
        StartPosition = nil,
        StartOffset = nil,
        IsDragging = false
    },
    ScrollableElements = {},
    MousePosition = Vector2.new(0, 0),
    PreviousMousePosition = Vector2.new(0, 0),
    MouseDelta = Vector2.new(0, 0),
    MouseButtons = {
        Left = false,
        Right = false,
        Middle = false
    },
    KeysDown = {},
    ModifierKeys = {
        Shift = false,
        Ctrl = false,
        Alt = false
    },
    LastInputType = nil,
    InputTypeChangedCallbacks = {},
    ElementCallbacks = {},
    AnimationTweenInfos = {
        Hover = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        Click = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        Movement = TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        FadeIn = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        FadeOut = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        ColorChange = TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        Scale = TweenInfo.new(0.4, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
        Dropdown = TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        Notification = TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        Modal = TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        SpringEffect = TweenInfo.new(0.6, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out, 0, false, 0),
    },
    DefaultAnimationProperties = {
        Hover = {
            BackgroundColor3 = "HoverColor",
            TextColor3 = "HoverTextColor",
            Transparency = 0.9,
            Size = UDim2.new(1.02, 0, 1.02, 0)
        },
        Click = {
            BackgroundColor3 = "PressedColor",
            TextColor3 = "PressedTextColor",
            Transparency = 0.7,
            Size = UDim2.new(0.98, 0, 0.98, 0)
        }
    },
    AnimationQueue = {},
    LastRender = tick(),
    DeltaTime = 0,
    ThemeManager = nil,
    CurrentTheme = nil,
    ElementRegistry = {},
    InputPriority = Enum.ContextActionPriority.High.Value,
    InputMode = "Default",
    ElementDepth = {}
}

local function debugLog(...)
    if InterfaceManager.DebugMode then
        print("[FluidUI InterfaceManager]", ...)
    end
end

-- Initialize the InterfaceManager with connections and setup
function InterfaceManager:Initialize(themeManager)
    self.ThemeManager = themeManager
    
    -- Set up input connections
    self:SetupInputConnections()
    
    -- Set up render loop
    self:SetupRenderLoop()
    
    -- Load last theme if available
    if themeManager then
        self.CurrentTheme = themeManager:GetCurrentTheme()
    end
    
    debugLog("InterfaceManager initialized")
    return self
end

-- Clean up all connections on exit
function InterfaceManager:Cleanup()
    -- Disconnect all input connections
    for _, connection in pairs(self.InputConnections) do
        if typeof(connection) == "RBXScriptConnection" then
            connection:Disconnect()
        end
    end
    
    -- Cancel all running tweens
    for _, tween in pairs(self.AnimationTweens) do
        if tween.Tween and tween.Tween.PlaybackState ~= Enum.PlaybackState.Completed then
            tween.Tween:Cancel()
        end
    end
    
    -- Clear internal data
    self.InputConnections = {}
    self.AnimationTweens = {}
    self.HoveredElements = {}
    self.ActiveElements = {}
    self.ScrollableElements = {}
    
    debugLog("InterfaceManager cleaned up")
end

-- Setup connections for various input types
function InterfaceManager:SetupInputConnections()
    -- Mouse movement tracking
    self.InputConnections.MouseMoved = UserInputService.InputChanged:Connect(function(input, gameProcessed)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            self.PreviousMousePosition = self.MousePosition
            self.MousePosition = input.Position
            self.MouseDelta = self.MousePosition - self.PreviousMousePosition
            
            -- Handle dragging behavior
            self:HandleDragging()
            
            -- Handle hover effects for elements
            self:ProcessMouseHover()
        end
    end)
    
    -- Mouse button and keyboard input
    self.InputConnections.InputBegan = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        self:ProcessInputBegan(input, gameProcessed)
    end)
    
    self.InputConnections.InputEnded = UserInputService.InputEnded:Connect(function(input, gameProcessed)
        self:ProcessInputEnded(input, gameProcessed)
    end)
    
    -- Handle text input
    self.InputConnections.TextInput = UserInputService.TextBoxFocused:Connect(function(textbox)
        self:HandleTextFocus(textbox)
    end)
    
    self.InputConnections.TextFocusLost = UserInputService.TextBoxFocusLost:Connect(function(textbox, enterPressed)
        self:HandleTextFocusLost(textbox, enterPressed)
    end)
    
    -- Handle mousewheel scrolling
    self.InputConnections.MouseWheel = UserInputService.InputChanged:Connect(function(input, gameProcessed)
        if input.UserInputType == Enum.UserInputType.MouseWheel then
            self:HandleScrolling(input.Position.Z)
        end
    end)
    
    -- Track input type changes
    self.InputConnections.LastInputTypeChanged = UserInputService.LastInputTypeChanged:Connect(function(lastInputType)
        self.LastInputType = lastInputType
        self:OnInputTypeChanged(lastInputType)
    end)
    
    -- Initialize the last input type
    self.LastInputType = UserInputService:GetLastInputType()
    
    debugLog("Input connections established")
end

-- Set up a render loop for smooth animations
function InterfaceManager:SetupRenderLoop()
    self.InputConnections.RenderStepped = RunService.RenderStepped:Connect(function(deltaTime)
        self.DeltaTime = deltaTime
        self.LastRender = tick()
        
        -- Process animation queue
        self:ProcessAnimationQueue()
        
        -- Handle custom render updates
        if self.OnRenderStepped then
            self.OnRenderStepped(deltaTime)
        end
    end)
    
    debugLog("Render loop established")
end

-- Process mouse hover effects
function InterfaceManager:ProcessMouseHover()
    -- Find elements under the mouse
    local elementsUnderMouse = self:GetElementsAtPosition(self.MousePosition)
    
    -- Sort elements by depth (z-index)
    table.sort(elementsUnderMouse, function(a, b)
        local depthA = self.ElementDepth[a] or 0
        local depthB = self.ElementDepth[b] or 0
        return depthA > depthB
    end)
    
    -- Check for new hover elements
    for _, element in ipairs(elementsUnderMouse) do
        if not self.HoveredElements[element] then
            self.HoveredElements[element] = true
            self:TriggerElementCallback(element, "MouseEnter")
            self:ApplyHoverEffect(element, true)
        end
    end
    
    -- Check for elements no longer hovered
    for element, _ in pairs(self.HoveredElements) do
        if not table.find(elementsUnderMouse, element) then
            self.HoveredElements[element] = nil
            self:TriggerElementCallback(element, "MouseLeave")
            self:ApplyHoverEffect(element, false)
        end
    end
end

-- Apply hover effects to an element
function InterfaceManager:ApplyHoverEffect(element, isHovering)
    if not element or not element:IsA("GuiObject") then
        return
    end
    
    -- Check if element has hover animations disabled
    if element:GetAttribute("NoHoverAnim") then
        return
    end
    
    -- Get custom hover properties or use defaults
    local hoverProps = element:GetAttribute("HoverProps")
    local properties = {}
    
    if hoverProps and typeof(hoverProps) == "table" then
        properties = hoverProps
    else
        local elementType = element.ClassName
        
        -- Get default hover effects for this element type
        if elementType == "TextButton" or elementType == "ImageButton" then
            properties = table.clone(self.DefaultAnimationProperties.Hover)
        elseif elementType == "Frame" or elementType == "ScrollingFrame" then
            properties = {
                BackgroundTransparency = isHovering and 0.8 or 1,
                BorderSizePixel = isHovering and 1 or 0
            }
        elseif elementType == "TextBox" then
            properties = {
                BackgroundColor3 = isHovering and self:GetThemeColor("InputFieldHoverColor") or self:GetThemeColor("InputFieldColor"),
                TextColor3 = isHovering and self:GetThemeColor("InputFieldHoverTextColor") or self:GetThemeColor("InputFieldTextColor")
            }
        end
    end
    
    -- Process theme color references
    for prop, value in pairs(properties) do
        if type(value) == "string" and self.ThemeManager then
            properties[prop] = self:GetThemeColor(value)
        end
    end
    
    -- Apply the animation
    local tweenInfo = element:GetAttribute("HoverTweenInfo") or self.AnimationTweenInfos.Hover
    
    if isHovering then
        self:AnimateProperties(element, properties, tweenInfo, "hover")
    else
        -- Revert to original properties
        local originalProps = {}
        for prop, _ in pairs(properties) do
            if prop == "BackgroundColor3" then
                originalProps[prop] = element:GetAttribute("OriginalBgColor") or element.BackgroundColor3
            elseif prop == "TextColor3" then
                originalProps[prop] = element:GetAttribute("OriginalTextColor") or element.TextColor3
            elseif prop == "BackgroundTransparency" then
                originalProps[prop] = element:GetAttribute("OriginalBgTransparency") or element.BackgroundTransparency
            elseif prop == "Size" then
                originalProps[prop] = element:GetAttribute("OriginalSize") or element.Size
            else
                originalProps[prop] = element[prop]
            end
        end
        
        self:AnimateProperties(element, originalProps, tweenInfo, "hover")
    end
    
    -- Apply hover cursor if appropriate
    if isHovering and element:GetAttribute("HoverCursor") then
        -- Custom hover cursor implementation
    end
end

-- Process mouse button and keyboard input began
function InterfaceManager:ProcessInputBegan(input, gameProcessed)
    if gameProcessed then return end
    
    local inputType = input.UserInputType
    local keyCode = input.KeyCode
    
    -- Update mouse button states
    if inputType == Enum.UserInputType.MouseButton1 then
        self.MouseButtons.Left = true
        self:HandleMouseClick(1)
    elseif inputType == Enum.UserInputType.MouseButton2 then
        self.MouseButtons.Right = true
        self:HandleMouseClick(2)
    elseif inputType == Enum.UserInputType.MouseButton3 then
        self.MouseButtons.Middle = true
        self:HandleMouseClick(3)
    elseif inputType == Enum.UserInputType.Keyboard then
        -- Track keys being pressed
        self.KeysDown[keyCode] = true
        
        -- Update modifier keys state
        if keyCode == Enum.KeyCode.LeftShift or keyCode == Enum.KeyCode.RightShift then
            self.ModifierKeys.Shift = true
        elseif keyCode == Enum.KeyCode.LeftControl or keyCode == Enum.KeyCode.RightControl then
            self.ModifierKeys.Ctrl = true
        elseif keyCode == Enum.KeyCode.LeftAlt or keyCode == Enum.KeyCode.RightAlt then
            self.ModifierKeys.Alt = true
        end
        
        self:HandleKeyDown(keyCode)
    end
end

-- Process mouse button and keyboard input ended
function InterfaceManager:ProcessInputEnded(input, gameProcessed)
    local inputType = input.UserInputType
    local keyCode = input.KeyCode
    
    -- Update mouse button states
    if inputType == Enum.UserInputType.MouseButton1 then
        self.MouseButtons.Left = false
        self:HandleMouseRelease(1)
    elseif inputType == Enum.UserInputType.MouseButton2 then
        self.MouseButtons.Right = false
        self:HandleMouseRelease(2)
    elseif inputType == Enum.UserInputType.MouseButton3 then
        self.MouseButtons.Middle = false
        self:HandleMouseRelease(3)
    elseif inputType == Enum.UserInputType.Keyboard then
        -- Track keys being released
        self.KeysDown[keyCode] = nil
        
        -- Update modifier keys state
        if keyCode == Enum.KeyCode.LeftShift or keyCode == Enum.KeyCode.RightShift then
            self.ModifierKeys.Shift = false
        elseif keyCode == Enum.KeyCode.LeftControl or keyCode == Enum.KeyCode.RightControl then
            self.ModifierKeys.Ctrl = false
        elseif keyCode == Enum.KeyCode.LeftAlt or keyCode == Enum.KeyCode.RightAlt then
            self.ModifierKeys.Alt = false
        end
        
        self:HandleKeyUp(keyCode)
    end
end

-- Handle mouse button click events
function InterfaceManager:HandleMouseClick(buttonId)
    -- Find top element under click
    local elementsUnderMouse = self:GetElementsAtPosition(self.MousePosition)
    
    -- Sort elements by depth (z-index)
    table.sort(elementsUnderMouse, function(a, b)
        local depthA = self.ElementDepth[a] or 0
        local depthB = self.ElementDepth[b] or 0
        return depthA > depthB
    end)
    
    local clickedElement = elementsUnderMouse[1]
    
    -- Handle focus changes
    if buttonId == 1 then
        if clickedElement then
            if self.FocusedElement and self.FocusedElement ~= clickedElement then
                self:HandleElementBlur(self.FocusedElement)
            end
            
            self:HandleElementFocus(clickedElement)
            self.FocusedElement = clickedElement
            
            -- Record for drag operation
            self.DragData.StartPosition = self.MousePosition
            self.DragData.IsDragging = false
            
            -- Check if element is draggable
            if clickedElement:GetAttribute("Draggable") then
                self.DragData.DraggableElement = clickedElement
                self.DragData.StartOffset = clickedElement.Position
            end
            
            -- Handle double-click detection
            local currentTime = tick()
            if self.ClickedElement == clickedElement and 
               (currentTime - self.LastClickTime) < self.DoubleClickThreshold then
                self:TriggerElementCallback(clickedElement, "DoubleClick", buttonId)
            else
                self.ClickedElement = clickedElement
                self.LastClickTime = currentTime
                
                -- Apply click animation
                self:ApplyClickEffect(clickedElement, true)
                
                -- Call normal click callback
                self:TriggerElementCallback(clickedElement, "Click", buttonId)
            end
        else
            -- Clicked on nothing, remove focus
            if self.FocusedElement then
                self:HandleElementBlur(self.FocusedElement)
                self.FocusedElement = nil
            end
        end
    elseif buttonId == 2 and clickedElement then
        -- Right-click behavior
        self:TriggerElementCallback(clickedElement, "RightClick")
    elseif buttonId == 3 and clickedElement then
        -- Middle-click behavior
        self:TriggerElementCallback(clickedElement, "MiddleClick")
    end
end

-- Handle mouse button release events
function InterfaceManager:HandleMouseRelease(buttonId)
    -- End any drag operation when mouse released
    if buttonId == 1 then
        if self.DragData.IsDragging and self.DragData.DraggableElement then
            self:TriggerElementCallback(self.DragData.DraggableElement, "DragEnd", self.MousePosition)
        end
        
        self.DragData.IsDragging = false
        self.DragData.DraggableElement = nil
        
        -- Restore button from click effect
        if self.ClickedElement then
            self:ApplyClickEffect(self.ClickedElement, false)
            self:TriggerElementCallback(self.ClickedElement, "Release")
            self.ClickedElement = nil
        end
    end
end

-- Apply click effects to an element
function InterfaceManager:ApplyClickEffect(element, isClicking)
    if not element or not element:IsA("GuiObject") then
        return
    end
    
    -- Check if element has click animations disabled
    if element:GetAttribute("NoClickAnim") then
        return
    end
    
    -- Get custom click properties or use defaults
    local clickProps = element:GetAttribute("ClickProps")
    local properties = {}
    
    if clickProps and typeof(clickProps) == "table" then
        properties = clickProps
    else
        local elementType = element.ClassName
        
        -- Get default click effects for this element type
        if elementType == "TextButton" or elementType == "ImageButton" then
            properties = table.clone(self.DefaultAnimationProperties.Click)
        elseif elementType == "Frame" or elementType == "ScrollingFrame" then
            properties = {
                BackgroundTransparency = isClicking and 0.7 or 0.9,
                Position = isClicking and UDim2.new(element.Position.X.Scale, element.Position.X.Offset + 1, 
                                                    element.Position.Y.Scale, element.Position.Y.Offset + 1) or
                                           element:GetAttribute("OriginalPosition") or element.Position
            }
        end
    end
    
    -- Process theme color references
    for prop, value in pairs(properties) do
        if type(value) == "string" and self.ThemeManager then
            properties[prop] = self:GetThemeColor(value)
        end
    end
    
    -- Apply the animation
    local tweenInfo = element:GetAttribute("ClickTweenInfo") or self.AnimationTweenInfos.Click
    
    if isClicking then
        -- Save original position if needed for position animation
        if properties.Position and not element:GetAttribute("OriginalPosition") then
            element:SetAttribute("OriginalPosition", element.Position)
        end
        
        -- Spring effect for buttons
        if element:IsA("TextButton") or element:IsA("ImageButton") then
            tweenInfo = self.AnimationTweenInfos.SpringEffect
        end
        
        self:AnimateProperties(element, properties, tweenInfo, "click")
    else
        -- Revert to original properties
        local originalProps = {}
        for prop, _ in pairs(properties) do
            if prop == "BackgroundColor3" then
                originalProps[prop] = element:GetAttribute("OriginalBgColor") or element.BackgroundColor3
            elseif prop == "TextColor3" then
                originalProps[prop] = element:GetAttribute("OriginalTextColor") or element.TextColor3
            elseif prop == "BackgroundTransparency" then
                originalProps[prop] = element:GetAttribute("OriginalBgTransparency") or element.BackgroundTransparency
            elseif prop == "Size" then
                originalProps[prop] = element:GetAttribute("OriginalSize") or element.Size
            elseif prop == "Position" then
                originalProps[prop] = element:GetAttribute("OriginalPosition") or element.Position
            else
                originalProps[prop] = element[prop]
            end
        end
        
        self:AnimateProperties(element, originalProps, tweenInfo, "click")
    end
    
    -- Apply haptic feedback if available
    if isClicking and self.EnableHapticFeedback then
        if UserInputService.VibrationMotor then
            UserInputService:SetMotorVibration(Enum.VibrationMotor.Small, 0.2, 0.1)
        end
    end
end

-- Handle element focus events
function InterfaceManager:HandleElementFocus(element)
    if not element then return end
    
    -- Record that this element is focused
    self.ActiveElements[element] = true
    
    -- Call the focus callback
    self:TriggerElementCallback(element, "Focus")
    
    -- Apply focus visual effects
    if element:IsA("GuiObject") and not element:GetAttribute("NoFocusAnim") then
        local focusProps = element:GetAttribute("FocusProps") or {
            BorderColor3 = self:GetThemeColor("FocusBorderColor"),
            BorderSizePixel = 2
        }
        
        -- Process theme color references
        for prop, value in pairs(focusProps) do
            if type(value) == "string" and self.ThemeManager then
                focusProps[prop] = self:GetThemeColor(value)
            end
        end
        
        -- Store original values
        if not element:GetAttribute("OriginalBorderColor") then
            element:SetAttribute("OriginalBorderColor", element.BorderColor3)
        end
        
        if not element:GetAttribute("OriginalBorderSize") then
            element:SetAttribute("OriginalBorderSize", element.BorderSizePixel)
        end
        
        local tweenInfo = element:GetAttribute("FocusTweenInfo") or self.AnimationTweenInfos.FadeIn
        self:AnimateProperties(element, focusProps, tweenInfo, "focus")
    end
end

-- Handle element blur (lose focus) events
function InterfaceManager:HandleElementBlur(element)
    if not element then return end
    
    -- Record that this element is no longer focused
    self.ActiveElements[element] = nil
    
    -- Call the blur callback
    self:TriggerElementCallback(element, "Blur")
    
    -- Revert focus visual effects
    if element:IsA("GuiObject") and not element:GetAttribute("NoFocusAnim") then
        local originalProps = {
            BorderColor3 = element:GetAttribute("OriginalBorderColor") or element.BorderColor3,
            BorderSizePixel = element:GetAttribute("OriginalBorderSize") or element.BorderSizePixel
        }
        
        local tweenInfo = element:GetAttribute("FocusTweenInfo") or self.AnimationTweenInfos.FadeOut
        self:AnimateProperties(element, originalProps, tweenInfo, "focus")
    end
end

-- Handle dragging operations
function InterfaceManager:HandleDragging()
    -- Check if we're in a drag operation
    if self.DragData.DraggableElement and self.MouseButtons.Left then
        local element = self.DragData.DraggableElement
        local distance = (self.MousePosition - self.DragData.StartPosition).Magnitude
        
        -- Check if we've moved enough to consider it a drag
        if distance >= self.DragThreshold and not self.DragData.IsDragging then
            self.DragData.IsDragging = true
            self:TriggerElementCallback(element, "DragStart", self.MousePosition)
        end
        
        -- If we're dragging, update position
        if self.DragData.IsDragging then
            local offset = self.MousePosition - self.DragData.StartPosition
            local newPosition
            
            -- Get constraints
            local dragBounds = element:GetAttribute("DragBounds")
            local dragAxis = element:GetAttribute("DragAxis") or "XY"
            
            if dragAxis == "X" then
                offset = Vector2.new(offset.X, 0)
            elseif dragAxis == "Y" then
                offset = Vector2.new(0, offset.Y)
            end
            
            -- Calculate new position
            newPosition = UDim2.new(
                self.DragData.StartOffset.X.Scale, 
                self.DragData.StartOffset.X.Offset + offset.X,
                self.DragData.StartOffset.Y.Scale, 
                self.DragData.StartOffset.Y.Offset + offset.Y
            )
            
            -- Apply bounds constraints if specified
            if dragBounds then
                -- Implement bounds constraints
            end
            
            -- Apply new position with smoothing
            local tweenInfo = element:GetAttribute("DragTweenInfo") or TweenInfo.new(0.05, Enum.EasingStyle.Linear)
            self:AnimateProperties(element, {Position = newPosition}, tweenInfo, "drag")
            
            -- Call the drag callback
            self:TriggerElementCallback(element, "Drag", self.MousePosition, offset)
        end
    end
end

-- Handle text input focus
function InterfaceManager:HandleTextFocus(textbox)
    if not textbox or not textbox:IsA("TextBox") then return end
    
    -- Handle the focus effect
    self:HandleElementFocus(textbox)
    
    -- Call specific text focus callback
    self:TriggerElementCallback(textbox, "TextFocus")
    
    -- Apply text focus animation
    if not textbox:GetAttribute("NoTextFocusAnim") then
        local props = {
            BackgroundColor3 = self:GetThemeColor("InputFieldFocusColor"),
            TextColor3 = self:GetThemeColor("InputFieldFocusTextColor"),
            BorderColor3 = self:GetThemeColor("FocusBorderColor"),
            BorderSizePixel = 2
        }
        
        local tweenInfo = textbox:GetAttribute("TextFocusTweenInfo") or self.AnimationTweenInfos.FadeIn
        self:AnimateProperties(textbox, props, tweenInfo, "textFocus")
    end
end

-- Handle text input focus lost
function InterfaceManager:HandleTextFocusLost(textbox, enterPressed)
    if not textbox or not textbox:IsA("TextBox") then return end
    
    -- Handle the blur effect
    self:HandleElementBlur(textbox)
    
    -- Call specific text focus lost callback
    self:TriggerElementCallback(textbox, "TextFocusLost", {enterPressed = enterPressed})
    
    -- Revert text focus animation
    if not textbox:GetAttribute("NoTextFocusAnim") then
        local originalProps = {
            BackgroundColor3 = textbox:GetAttribute("OriginalBgColor") or textbox.BackgroundColor3,
            TextColor3 = textbox:GetAttribute("OriginalTextColor") or textbox.TextColor3,
            BorderColor3 = textbox:GetAttribute("OriginalBorderColor") or textbox.BorderColor3,
            BorderSizePixel = textbox:GetAttribute("OriginalBorderSize") or textbox.BorderSizePixel
        }
        
        local tweenInfo = textbox:GetAttribute("TextFocusTweenInfo") or self.AnimationTweenInfos.FadeOut
        self:AnimateProperties(textbox, originalProps, tweenInfo, "textFocus")
    end
    
    -- Special handling for 'enter' key pressed
    if enterPressed then
        self:TriggerElementCallback(textbox, "TextSubmitted", textbox.Text)
    end
end

-- Handle key down events
function InterfaceManager:HandleKeyDown(keyCode)
    -- Call global keydown callback
    if self.OnKeyDown then
        self.OnKeyDown(keyCode, self.ModifierKeys)
    end
    
    -- If an element is focused, send the key event to it
    if self.FocusedElement then
        self:TriggerElementCallback(self.FocusedElement, "KeyDown", keyCode, self.ModifierKeys)
    end
    
    -- Handle specific key combinations or shortcuts
    if self.ModifierKeys.Ctrl then
        if keyCode == Enum.KeyCode.S then
            -- Ctrl+S Save shortcut
            if self.OnSaveShortcut then
                self.OnSaveShortcut()
            end
        elseif keyCode == Enum.KeyCode.Z then
            -- Ctrl+Z Undo shortcut
            if self.OnUndoShortcut then
                self.OnUndoShortcut()
            end
        elseif keyCode == Enum.KeyCode.Y then
            -- Ctrl+Y Redo shortcut
            if self.OnRedoShortcut then
                self.OnRedoShortcut()
            end
        end
    end
end

-- Handle key up events
function InterfaceManager:HandleKeyUp(keyCode)
    -- Call global keyup callback
    if self.OnKeyUp then
        self.OnKeyUp(keyCode, self.ModifierKeys)
    end
    
    -- If an element is focused, send the key event to it
    if self.FocusedElement then
        self:TriggerElementCallback(self.FocusedElement, "KeyUp", keyCode, self.ModifierKeys)
    end
end

-- Handle scrolling for scrollable elements
function InterfaceManager:HandleScrolling(scrollDirection)
    -- Find scrollable elements under mouse
    local elementsUnderMouse = self:GetElementsAtPosition(self.MousePosition)
    local scrollableElement = nil
    
    -- Find the top-most scrollable element
    for _, element in ipairs(elementsUnderMouse) do
        if element:IsA("ScrollingFrame") or element:GetAttribute("Scrollable") then
            scrollableElement = element
            break
        end
    end
    
    -- If we found a scrollable element, handle scrolling
    if scrollableElement then
        local scrollIncrement = scrollableElement:GetAttribute("ScrollIncrement") or 40
        local smoothScroll = scrollableElement:GetAttribute("SmoothScroll") ~= false
        
        if scrollableElement:IsA("ScrollingFrame") then
            local currentPos = scrollableElement.CanvasPosition
            local newPos
            
            if scrollableElement:GetAttribute("ScrollDirection") == "Horizontal" then
                newPos = Vector2.new(currentPos.X - (scrollDirection * scrollIncrement), currentPos.Y)
            else
                newPos = Vector2.new(currentPos.X, currentPos.Y - (scrollDirection * scrollIncrement))
            end
            
            if smoothScroll then
                -- Smooth scrolling with animation
                self:AnimateProperties(scrollableElement, {CanvasPosition = newPos}, 
                    self.AnimationTweenInfos.Movement, "scroll")
            else
                -- Immediate scrolling
                scrollableElement.CanvasPosition = newPos
            end
            
            self:TriggerElementCallback(scrollableElement, "Scroll", scrollDirection)
        else
            -- Custom scrollable element handling
            self:TriggerElementCallback(scrollableElement, "CustomScroll", scrollDirection, scrollIncrement)
        end
        
        return true
    end
    
    return false
end

-- Get all interactive GUI elements at a screen position
function InterfaceManager:GetElementsAtPosition(position)
    local elements = {}
    
    -- Iterate through all registered elements
    for element, _ in pairs(self.ElementRegistry) do
        if element:IsA("GuiObject") and element.Visible then
            -- Check if point is within the element
            local absPos = element.AbsolutePosition
            local absSize = element.AbsoluteSize
            
            if position.X >= absPos.X and 
               position.X <= absPos.X + absSize.X and
               position.Y >= absPos.Y and
               position.Y <= absPos.Y + absSize.Y then
                table.insert(elements, element)
            end
        end
    end
    
    return elements
end

-- Animate properties of a GUI element with a tween
function InterfaceManager:AnimateProperties(element, properties, tweenInfo, tweenId)
    if not element or not element:IsA("GuiObject") then return end
    
    -- Generate a unique ID for this tween
    local id = tweenId .. "_" .. element:GetFullName()
    
    -- Cancel any existing tween with the same ID
    if self.AnimationTweens[id] and 
       self.AnimationTweens[id].Tween and 
       self.AnimationTweens[id].Tween.PlaybackState ~= Enum.PlaybackState.Completed then
        self.AnimationTweens[id].Tween:Cancel()
    end
    
    -- Create and start the tween
    local tween = TweenService:Create(element, tweenInfo, properties)
    tween:Play()
    
    -- Store the tween for later reference
    self.AnimationTweens[id] = {
        Tween = tween,
        Element = element,
        StartTime = tick(),
        Properties = properties
    }
    
    -- Set up completion callback
    tween.Completed:Connect(function()
        if self.AnimationTweens[id] then
            self.AnimationTweens[id].Completed = true
        end
    end)
    
    return tween
end

-- Queue an animation to be processed on the next frame
function InterfaceManager:QueueAnimation(element, properties, tweenInfo, tweenId, delay)
    if not element or not element:IsA("GuiObject") then return end
    
    table.insert(self.AnimationQueue, {
        Element = element,
        Properties = properties,
        TweenInfo = tweenInfo,
        TweenId = tweenId,
        Delay = delay or 0,
        QueueTime = tick()
    })
end

-- Process the animation queue on each frame
function InterfaceManager:ProcessAnimationQueue()
    local currentTime = tick()
    local i = 1
    
    while i <= #self.AnimationQueue do
        local anim = self.AnimationQueue[i]
        
        -- Check if it's time to start this animation
        if (currentTime - anim.QueueTime) >= anim.Delay then
            -- Start the animation
            self:AnimateProperties(anim.Element, anim.Properties, anim.TweenInfo, anim.TweenId)
            
            -- Remove from queue
            table.remove(self.AnimationQueue, i)
        else
            -- Move to next animation
            i = i + 1
        end
    end
end

-- Register a UI element for interaction handling
function InterfaceManager:RegisterElement(element, callbacks, depth)
    if not element then return end
    
    self.ElementRegistry[element] = true
    
    -- Store callbacks if provided
    if callbacks then
        self.ElementCallbacks[element] = callbacks
    end
    
    -- Store depth for z-ordering
    if depth then
        self.ElementDepth[element] = depth
    end
    
    -- Store original properties for animation reversion
    if element:IsA("GuiObject") then
        element:SetAttribute("OriginalBgColor", element.BackgroundColor3)
        element:SetAttribute("OriginalTextColor", element.TextColor3)
        element:SetAttribute("OriginalBgTransparency", element.BackgroundTransparency)
        element:SetAttribute("OriginalSize", element.Size)
        element:SetAttribute("OriginalPosition", element.Position)
    end
    
    -- Set up any special behaviors based on element type
    if element:IsA("ScrollingFrame") then
        self.ScrollableElements[element] = true
    end
    
    return element
end

-- Unregister a UI element
function InterfaceManager:UnregisterElement(element)
    if not element then return end
    
    self.ElementRegistry[element] = nil
    self.ElementCallbacks[element] = nil
    self.ElementDepth[element] = nil
    self.HoveredElements[element] = nil
    self.ActiveElements[element] = nil
    self.ScrollableElements[element] = nil
    
    -- Cancel any running animations
    for id, tween in pairs(self.AnimationTweens) do
        if tween.Element == element and tween.Tween.PlaybackState ~= Enum.PlaybackState.Completed then
            tween.Tween:Cancel()
            self.AnimationTweens[id] = nil
        end
    end
    
    return true
end

-- Trigger an element callback if it exists
function InterfaceManager:TriggerElementCallback(element, callbackName, ...)
    if not element or not callbackName then return end
    
    -- Check for element-specific callback
    if self.ElementCallbacks[element] and 
       self.ElementCallbacks[element][callbackName] and
       type(self.ElementCallbacks[element][callbackName]) == "function" then
        
        self.ElementCallbacks[element][callbackName](element, ...)
        return true
    end
    
    -- Check for custom attribute callback
    local attributeCallback = element:GetAttribute("On" .. callbackName)
    if attributeCallback and type(attributeCallback) == "function" then
        attributeCallback(element, ...)
        return true
    end
    
    -- Check for global element type callback
    local globalCallback = self["OnElement" .. callbackName]
    if globalCallback and type(globalCallback) == "function" then
        globalCallback(element, ...)
        return true
    end
    
    return false
end

-- Set a callback function for an element
function InterfaceManager:SetElementCallback(element, callbackName, callbackFn)
    if not element or not callbackName or type(callbackFn) ~= "function" then
        return false
    end
    
    if not self.ElementCallbacks[element] then
        self.ElementCallbacks[element] = {}
    end
    
    self.ElementCallbacks[element][callbackName] = callbackFn
    return true
end

-- Apply a ripple effect animation to an element
function InterfaceManager:ApplyRippleEffect(element, position)
    if not element or not element:IsA("GuiObject") then return end
    
    -- Create ripple circle
    local ripple = Instance.new("Frame")
    ripple.Name = "Ripple"
    ripple.BackgroundColor3 = self:GetThemeColor("RippleColor") or Color3.fromRGB(255, 255, 255)
    ripple.BackgroundTransparency = 0.7
    ripple.BorderSizePixel = 0
    ripple.AnchorPoint = Vector2.new(0.5, 0.5)
    
    -- Calculate local position within element
    local localPos
    if position then
        localPos = position - element.AbsolutePosition
    else
        localPos = Vector2.new(element.AbsoluteSize.X/2, element.AbsoluteSize.Y/2)
    end
    
    -- Start with small size at click position
    ripple.Position = UDim2.new(0, localPos.X, 0, localPos.Y)
    ripple.Size = UDim2.new(0, 0, 0, 0)
    
    -- Calculate max size based on furthest corner
    local topLeft = (Vector2.new(0, 0) - localPos).Magnitude
    local topRight = (Vector2.new(element.AbsoluteSize.X, 0) - localPos).Magnitude
    local bottomLeft = (Vector2.new(0, element.AbsoluteSize.Y) - localPos).Magnitude
    local bottomRight = (Vector2.new(element.AbsoluteSize.X, element.AbsoluteSize.Y) - localPos).Magnitude
    local maxSize = math.max(topLeft, topRight, bottomLeft, bottomRight) * 2
    
    -- Add the ripple to the element
    ripple.Parent = element
    
    -- Apply corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0) -- Make it fully circular
    corner.Parent = ripple
    
    -- Animate the ripple
    local growTween = TweenService:Create(
        ripple,
        TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Size = UDim2.new(0, maxSize, 0, maxSize), BackgroundTransparency = 1}
    )
    
    growTween:Play()
    
    -- Clean up after animation
    growTween.Completed:Connect(function()
        ripple:Destroy()
    end)
    
    return ripple
end

-- Handle input type changed (keyboard, gamepad, touch, etc.)
function InterfaceManager:OnInputTypeChanged(inputType)
    -- Notify all registered callbacks
    for _, callback in pairs(self.InputTypeChangedCallbacks) do
        if type(callback) == "function" then
            callback(inputType)
        end
    end
    
    -- Update input mode based on new input type
    if inputType == Enum.UserInputType.Touch then
        self.InputMode = "Touch"
    elseif inputType == Enum.UserInputType.Gamepad1 then
        self.InputMode = "Gamepad"
    else
        self.InputMode = "Default"
    end
    
    -- Adjust UI for this input mode
    self:AdjustUIForInputMode(self.InputMode)
end

-- Adjust UI elements for different input modes
function InterfaceManager:AdjustUIForInputMode(mode)
    -- This would contain adaptations for different input methods
    -- For example, making touch targets larger, gamepad navigation, etc.
    
    if self.OnInputModeChanged then
        self.OnInputModeChanged(mode)
    end
end

-- Register a callback for input type changes
function InterfaceManager:RegisterInputTypeChangedCallback(callback)
    if type(callback) ~= "function" then
        return false
    end
    
    table.insert(self.InputTypeChangedCallbacks, callback)
    return true
end

-- Get a theme color, with fallback to default
function InterfaceManager:GetThemeColor(colorName)
    if self.ThemeManager and self.CurrentTheme then
        local color = self.ThemeManager:GetColor(colorName, self.CurrentTheme)
        if color then
            return color
        end
    end
    
    -- Default colors as fallback
    local defaultColors = {
        PrimaryColor = Color3.fromRGB(0, 120, 215),
        SecondaryColor = Color3.fromRGB(51, 153, 255),
        BackgroundColor = Color3.fromRGB(40, 40, 40),
        TextColor = Color3.fromRGB(255, 255, 255),
        DisabledColor = Color3.fromRGB(150, 150, 150),
        HoverColor = Color3.fromRGB(20, 150, 255),
        PressedColor = Color3.fromRGB(0, 80, 160),
        ErrorColor = Color3.fromRGB(232, 17, 35),
        SuccessColor = Color3.fromRGB(16, 124, 16),
        WarningColor = Color3.fromRGB(255, 185, 0),
        BorderColor = Color3.fromRGB(60, 60, 60),
        FocusBorderColor = Color3.fromRGB(0, 120, 215),
        InputFieldColor = Color3.fromRGB(60, 60, 60),
        InputFieldHoverColor = Color3.fromRGB(80, 80, 80),
        InputFieldFocusColor = Color3.fromRGB(70, 70, 70),
        InputFieldTextColor = Color3.fromRGB(255, 255, 255),
        RippleColor = Color3.fromRGB(255, 255, 255)
    }
    
    return defaultColors[colorName] or Color3.fromRGB(255, 255, 255)
end

-- Apply theme to all registered UI elements
function InterfaceManager:ApplyTheme(themeName)
    if not self.ThemeManager then
        return false
    end
    
    -- Update current theme
    local themeData = self.ThemeManager:GetTheme(themeName)
    if not themeData then
        return false
    end
    
    self.CurrentTheme = themeName
    
    -- Apply theme to all registered elements
    for element, _ in pairs(self.ElementRegistry) do
        if element:IsA("GuiObject") then
            self:ApplyThemeToElement(element, themeData)
        end
    end
    
    return true
end

-- Apply theme to a specific element
function InterfaceManager:ApplyThemeToElement(element, themeData)
    if not element or not themeData then return end
    
    local elementType = element.ClassName
    local themeProps = element:GetAttribute("ThemeProperties")
    
    -- Default theme mapping based on element type
    if not themeProps then
        if elementType == "Frame" then
            themeProps = {BackgroundColor3 = "BackgroundColor"}
        elseif elementType == "TextLabel" or elementType == "TextButton" then
            themeProps = {
                BackgroundColor3 = "BackgroundColor",
                TextColor3 = "TextColor"
            }
        elseif elementType == "TextBox" then
            themeProps = {
                BackgroundColor3 = "InputFieldColor",
                TextColor3 = "InputFieldTextColor",
                PlaceholderColor3 = "DisabledColor"
            }
        elseif elementType == "ImageLabel" or elementType == "ImageButton" then
            themeProps = {BackgroundColor3 = "BackgroundColor"}
        elseif elementType == "ScrollingFrame" then
            themeProps = {
                BackgroundColor3 = "BackgroundColor",
                ScrollBarImageColor3 = "SecondaryColor"
            }
        end
    end
    
    -- Apply theme properties if we have a mapping
    if themeProps then
        local newProperties = {}
        
        for prop, colorName in pairs(themeProps) do
            local color = self.ThemeManager:GetColor(colorName, self.CurrentTheme)
            if color then
                newProperties[prop] = color
                
                -- Store original values for animation reversion
                if prop == "BackgroundColor3" then
                    element:SetAttribute("OriginalBgColor", color)
                elseif prop == "TextColor3" then
                    element:SetAttribute("OriginalTextColor", color)
                end
            end
        end
        
        -- Animate the changes
        local tweenInfo = element:GetAttribute("ThemeTweenInfo") or self.AnimationTweenInfos.ColorChange
        self:AnimateProperties(element, newProperties, tweenInfo, "theme")
    end
end

-- Show a ripple animation on a button when clicked
function InterfaceManager:EnableRippleEffect(button, color)
    if not button then return end
    
    -- Register the element if not already registered
    if not self.ElementRegistry[button] then
        self:RegisterElement(button)
    end
    
    -- Set up the click callback to spawn ripples
    self:SetElementCallback(button, "Click", function(element, buttonId, position)
        if buttonId == 1 then  -- Left click
            self:ApplyRippleEffect(element, position)
        end
    end)
    
    -- Store the ripple color if provided
    if color then
        button:SetAttribute("RippleColor", color)
    end
    
    -- Make sure the button has ClipsDescendants enabled
    button.ClipsDescendants = true
end

return InterfaceManager