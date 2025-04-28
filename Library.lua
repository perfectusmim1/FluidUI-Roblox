--[[
    Library.lua
    FluidUI: Modern Roblox Luau UI Library
    Inspired by Fluent UI, but more modern, soft, and fluid.
    Features:
    - Ultra-smooth animations (hover, click, dropdown, etc.)
    - Fully rounded, adjustable corners
    - Theme system (Light, Dark, Neon, etc.) with animated transitions
    - Multi-select dropdowns
    - Dynamic element updating
    - Modern notification (toast) system
    - Responsive design
    - Blur, glow, and subtle effects
    - SaveManager and InterfaceManager integration
]]

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local SaveManager = require(script.Parent:FindFirstChild("SaveManager") or script:FindFirstChild("SaveManager"))
local InterfaceManager = require(script.Parent:FindFirstChild("InterfaceManager") or script:FindFirstChild("InterfaceManager"))

local Library = {}
Library.__index = Library

-- Theme definitions
Library.Themes = {
    Light = {
        Primary = Color3.fromRGB(0, 120, 215),
        Background = Color3.fromRGB(245, 245, 245),
        Foreground = Color3.fromRGB(30, 30, 30),
        Accent = Color3.fromRGB(51, 153, 255),
        Border = Color3.fromRGB(220, 220, 220),
        Button = Color3.fromRGB(240, 240, 240),
        ButtonText = Color3.fromRGB(30, 30, 30),
        Glow = Color3.fromRGB(0, 120, 215),
        Toast = Color3.fromRGB(255, 255, 255),
        ToastText = Color3.fromRGB(30, 30, 30),
        Blur = 8,
    },
    Dark = {
        Primary = Color3.fromRGB(0, 120, 215),
        Background = Color3.fromRGB(32, 34, 37),
        Foreground = Color3.fromRGB(220, 220, 220),
        Accent = Color3.fromRGB(51, 153, 255),
        Border = Color3.fromRGB(60, 60, 60),
        Button = Color3.fromRGB(40, 40, 40),
        ButtonText = Color3.fromRGB(220, 220, 220),
        Glow = Color3.fromRGB(0, 120, 215),
        Toast = Color3.fromRGB(40, 40, 40),
        ToastText = Color3.fromRGB(220, 220, 220),
        Blur = 12,
    },
    Neon = {
        Primary = Color3.fromRGB(57, 255, 20),
        Background = Color3.fromRGB(10, 10, 20),
        Foreground = Color3.fromRGB(255, 255, 255),
        Accent = Color3.fromRGB(0, 255, 255),
        Border = Color3.fromRGB(0, 255, 255),
        Button = Color3.fromRGB(20, 20, 40),
        ButtonText = Color3.fromRGB(0, 255, 255),
        Glow = Color3.fromRGB(57, 255, 20),
        Toast = Color3.fromRGB(0, 255, 255),
        ToastText = Color3.fromRGB(10, 10, 20),
        Blur = 16,
    },
}

Library.CurrentTheme = "Dark"
Library.ThemeTransitionTime = 0.5
Library.CornerRadius = UDim.new(0, 12)
Library.Elements = {}
Library.Notifications = {}
Library.ScreenGui = nil

-- Utility: Create UICorner
local function applyCorner(gui, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = radius or Library.CornerRadius
    c.Parent = gui
    return c
end

-- Utility: Create UIStroke
local function applyStroke(gui, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Thickness = thickness or 1
    s.Parent = gui
    return s
end

-- Utility: Create UIGradient
local function applyGradient(gui, colorseq)
    local g = Instance.new("UIGradient")
    g.Color = colorseq
    g.Parent = gui
    return g
end

-- Utility: Blur effect
local function applyBlur()
    local blur = Instance.new("BlurEffect")
    blur.Size = Library.Themes[Library.CurrentTheme].Blur or 8
    blur.Parent = game:GetService("Lighting")
    return blur
end

-- Theme switching with animation
function Library:SetTheme(themeName)
    if not self.Themes[themeName] then return end
    local oldTheme = self.Themes[self.CurrentTheme]
    local newTheme = self.Themes[themeName]
    self.CurrentTheme = themeName
    -- Animate all registered elements
    for _, el in pairs(self.Elements) do
        if el._themeProps then
            for prop, key in pairs(el._themeProps) do
                local from = el[prop]
                local to = newTheme[key] or from
                if typeof(from) == "Color3" and typeof(to) == "Color3" then
                    local tween = TweenService:Create(el, TweenInfo.new(self.ThemeTransitionTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {[prop] = to})
                    tween:Play()
                else
                    el[prop] = to
                end
            end
        end
    end
    -- Blur effect
    if self._blur then self._blur:Destroy() end
    self._blur = applyBlur()
end

-- Main UI creation
function Library:Init()
    if self.ScreenGui then return end
    self.ScreenGui = Instance.new("ScreenGui")
    self.ScreenGui.Name = "FluidUI"
    self.ScreenGui.IgnoreGuiInset = true
    self.ScreenGui.ResetOnSpawn = false
    self.ScreenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    self._blur = applyBlur()
end

-- Button
function Library:Button(props)
    local btn = Instance.new("TextButton")
    btn.Name = props.Name or "Button"
    btn.Size = props.Size or UDim2.new(0, 160, 0, 40)
    btn.Position = props.Position or UDim2.new(0, 0, 0, 0)
    btn.BackgroundColor3 = self.Themes[self.CurrentTheme].Button
    btn.TextColor3 = self.Themes[self.CurrentTheme].ButtonText
    btn.Text = props.Text or "Button"
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 18
    btn.AutoButtonColor = false
    btn.Parent = props.Parent or self.ScreenGui
    btn.ClipsDescendants = true
    applyCorner(btn, props.CornerRadius)
    applyStroke(btn, self.Themes[self.CurrentTheme].Border, 1)
    btn._themeProps = {BackgroundColor3 = "Button", TextColor3 = "ButtonText"}
    self.Elements[btn] = btn
    -- Glow effect
    if props.Glow then
        local glow = Instance.new("ImageLabel")
        glow.BackgroundTransparency = 1
        glow.Image = "rbxassetid://" -- leave blank for GitHub
        glow.ImageColor3 = self.Themes[self.CurrentTheme].Glow
        glow.Size = UDim2.new(1, 16, 1, 16)
        glow.Position = UDim2.new(0, -8, 0, -8)
        glow.ZIndex = btn.ZIndex - 1
        glow.Parent = btn
        applyGradient(glow, ColorSequence.new{ColorSequenceKeypoint.new(0, self.Themes[self.CurrentTheme].Glow), ColorSequenceKeypoint.new(1, Color3.new(1,1,1))})
    end
    -- Animations
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {BackgroundColor3 = self.Themes[self.CurrentTheme].Accent}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {BackgroundColor3 = self.Themes[self.CurrentTheme].Button}):Play()
    end)
    btn.MouseButton1Down:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15, Enum.EasingStyle.Quint), {BackgroundTransparency = 0.2, Size = btn.Size + UDim2.new(0, 4, 0, 4)}):Play()
    end)
    btn.MouseButton1Up:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15, Enum.EasingStyle.Quint), {BackgroundTransparency = 0, Size = props.Size or UDim2.new(0, 160, 0, 40)}):Play()
    end)
    if props.Callback then
        btn.MouseButton1Click:Connect(props.Callback)
    end
    return btn
end

-- Label
function Library:Label(props)
    local lbl = Instance.new("TextLabel")
    lbl.Name = props.Name or "Label"
    lbl.Size = props.Size or UDim2.new(0, 160, 0, 32)
    lbl.Position = props.Position or UDim2.new(0, 0, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = self.Themes[self.CurrentTheme].Foreground
    lbl.Text = props.Text or "Label"
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 16
    lbl.Parent = props.Parent or self.ScreenGui
    lbl._themeProps = {TextColor3 = "Foreground"}
    self.Elements[lbl] = lbl
    return lbl
end

-- Toggle
function Library:Toggle(props)
    local frame = Instance.new("Frame")
    frame.Name = props.Name or "Toggle"
    frame.Size = props.Size or UDim2.new(0, 60, 0, 32)
    frame.BackgroundColor3 = self.Themes[self.CurrentTheme].Button
    frame.Parent = props.Parent or self.ScreenGui
    applyCorner(frame, props.CornerRadius)
    applyStroke(frame, self.Themes[self.CurrentTheme].Border, 1)
    frame._themeProps = {BackgroundColor3 = "Button"}
    self.Elements[frame] = frame
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 28, 0, 28)
    knob.Position = UDim2.new(0, 2, 0.5, -14)
    knob.BackgroundColor3 = self.Themes[self.CurrentTheme].Accent
    knob.Parent = frame
    applyCorner(knob, UDim.new(1, 0))
    local state = props.State or false
    local function update()
        if state then
            TweenService:Create(knob, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {Position = UDim2.new(1, -30, 0.5, -14), BackgroundColor3 = self.Themes[self.CurrentTheme].Primary}):Play()
        else
            TweenService:Create(knob, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {Position = UDim2.new(0, 2, 0.5, -14), BackgroundColor3 = self.Themes[self.CurrentTheme].Accent}):Play()
        end
    end
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            state = not state
            update()
            if props.Callback then props.Callback(state) end
        end
    end)
    update()
    return frame
end

-- Multi-Select Dropdown
function Library:MultiDropdown(props)
    local frame = Instance.new("Frame")
    frame.Name = props.Name or "MultiDropdown"
    frame.Size = props.Size or UDim2.new(0, 200, 0, 40)
    frame.BackgroundColor3 = self.Themes[self.CurrentTheme].Button
    frame.Parent = props.Parent or self.ScreenGui
    applyCorner(frame, props.CornerRadius)
    applyStroke(frame, self.Themes[self.CurrentTheme].Border, 1)
    frame._themeProps = {BackgroundColor3 = "Button"}
    self.Elements[frame] = frame
    local selected = props.Selected or {}
    local options = props.Options or {}
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -32, 1, 0)
    label.Position = UDim2.new(0, 8, 0, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = self.Themes[self.CurrentTheme].Foreground
    label.Text = table.concat(selected, ", ")
    label.Font = Enum.Font.Gotham
    label.TextSize = 16
    label.Parent = frame
    local arrow = Instance.new("ImageLabel")
    arrow.Size = UDim2.new(0, 24, 0, 24)
    arrow.Position = UDim2.new(1, -28, 0.5, -12)
    arrow.BackgroundTransparency = 1
    arrow.Image = "rbxassetid://" -- leave blank for GitHub
    arrow.ImageColor3 = self.Themes[self.CurrentTheme].Accent
    arrow.Parent = frame
    local dropdown = Instance.new("Frame")
    dropdown.Size = UDim2.new(1, 0, 0, 0)
    dropdown.Position = UDim2.new(0, 0, 1, 0)
    dropdown.BackgroundColor3 = self.Themes[self.CurrentTheme].Button
    dropdown.ClipsDescendants = true
    dropdown.Visible = false
    dropdown.Parent = frame
    applyCorner(dropdown, props.CornerRadius)
    applyStroke(dropdown, self.Themes[self.CurrentTheme].Border, 1)
    local function updateLabel()
        label.Text = #selected > 0 and table.concat(selected, ", ") or (props.Placeholder or "Seçiniz...")
    end
    local function openDropdown()
        dropdown.Visible = true
        TweenService:Create(dropdown, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {Size = UDim2.new(1, 0, 0, #options * 32)}):Play()
    end
    local function closeDropdown()
        TweenService:Create(dropdown, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {Size = UDim2.new(1, 0, 0, 0)}):Play()
        delay(0.3, function() dropdown.Visible = false end)
    end
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if dropdown.Visible then closeDropdown() else openDropdown() end
        end
    end)
    for i, opt in ipairs(options) do
        local optBtn = Instance.new("TextButton")
        optBtn.Size = UDim2.new(1, 0, 0, 32)
        optBtn.Position = UDim2.new(0, 0, 0, (i-1)*32)
        optBtn.BackgroundColor3 = self.Themes[self.CurrentTheme].Button
        optBtn.TextColor3 = self.Themes[self.CurrentTheme].Foreground
        optBtn.Text = opt
        optBtn.Font = Enum.Font.Gotham
        optBtn.TextSize = 16
        optBtn.AutoButtonColor = false
        optBtn.Parent = dropdown
        applyCorner(optBtn, UDim.new(1, 0))
        optBtn.MouseButton1Click:Connect(function()
            local idx = table.find(selected, opt)
            if idx then table.remove(selected, idx) else table.insert(selected, opt) end
            updateLabel()
            if props.Callback then props.Callback(selected) end
        end)
        optBtn.MouseEnter:Connect(function()
            TweenService:Create(optBtn, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {BackgroundColor3 = self.Themes[self.CurrentTheme].Accent}):Play()
        end)
        optBtn.MouseLeave:Connect(function()
            TweenService:Create(optBtn, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {BackgroundColor3 = self.Themes[self.CurrentTheme].Button}):Play()
        end)
    end
    updateLabel()
    return frame
end

-- Notification (Toast)
function Library:Notify(text, duration)
    duration = duration or 2
    local toast = Instance.new("Frame")
    toast.Size = UDim2.new(0, 320, 0, 48)
    toast.Position = UDim2.new(1, -340, 1, -60 - (#self.Notifications*56))
    toast.BackgroundColor3 = self.Themes[self.CurrentTheme].Toast
    toast.BackgroundTransparency = 0.1
    toast.AnchorPoint = Vector2.new(0, 1)
    toast.Parent = self.ScreenGui
    applyCorner(toast, UDim.new(0, 16))
    applyStroke(toast, self.Themes[self.CurrentTheme].Border, 1)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -24, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = self.Themes[self.CurrentTheme].ToastText
    lbl.Text = text
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 18
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = toast
    table.insert(self.Notifications, toast)
    TweenService:Create(toast, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {BackgroundTransparency = 0}):Play()
    delay(duration, function()
        TweenService:Create(toast, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {BackgroundTransparency = 1}):Play()
        wait(0.4)
        toast:Destroy()
        table.remove(self.Notifications, table.find(self.Notifications, toast))
    end)
    return toast
end

-- Dynamic element update
function Library:UpdateElement(element, props)
    if not element or not props then return end
    for k, v in pairs(props) do
        if element[k] ~= nil then
            element[k] = v
        end
    end
end

-- Responsive design: auto scale
function Library:EnableResponsive()
    if not self.ScreenGui then return end
    local scale = Instance.new("UIScale")
    scale.Parent = self.ScreenGui
    local function updateScale()
        local res = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
        scale.Scale = math.clamp(res.Y/1080, 0.7, 1.2)
    end
    updateScale()
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
end

-- Public API
function Library:Create(props)
    self:Init()
    if props and props.Theme then self:SetTheme(props.Theme) end
    if props and props.Responsive then self:EnableResponsive() end
    return self
end

-- SaveManager/InterfaceManager integration
Library.SaveManager = SaveManager
Library.InterfaceManager = InterfaceManager

return setmetatable(Library, Library)
