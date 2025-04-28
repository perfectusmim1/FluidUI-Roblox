-- Example.lua
-- FluidUI kütüphanesi örnek kullanım dosyası
-- Roblox Studio veya exploit ortamında çalıştırılabilir

local FluidUI = require(script.Parent.FluidUI)

-- Tema yöneticisi örneği (basit, gerçek projede genişletilebilir)
local ThemeManager = {
    CurrentTheme = "Dark",
    Themes = {
        Dark = {
            PrimaryColor = Color3.fromRGB(0, 120, 215),
            BackgroundColor = Color3.fromRGB(40, 40, 40),
            TextColor = Color3.fromRGB(255, 255, 255)
        },
        Light = {
            PrimaryColor = Color3.fromRGB(0, 120, 215),
            BackgroundColor = Color3.fromRGB(240, 240, 240),
            TextColor = Color3.fromRGB(20, 20, 20)
        }
    },
    GetColor = function(self, colorName, theme)
        theme = theme or self.CurrentTheme
        return self.Themes[theme][colorName] or Color3.fromRGB(255,255,255)
    end,
    GetTheme = function(self, theme)
        return self.Themes[theme or self.CurrentTheme]
    end,
    GetCurrentTheme = function(self)
        return self.CurrentTheme
    end
}

-- FluidUI başlat
FluidUI:Initialize(ThemeManager)

-- Basit bir pencere ve buton oluştur
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FluidUIExample"
ScreenGui.Parent = game:GetService("Players").LocalPlayer.PlayerGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 400, 0, 300)
MainFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
MainFrame.BackgroundColor3 = ThemeManager:GetColor("BackgroundColor")
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.Name = "MainWindow"
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 18)
UICorner.Parent = MainFrame

local Button = Instance.new("TextButton")
Button.Size = UDim2.new(0, 120, 0, 40)
Button.Position = UDim2.new(0.5, -60, 0.5, -20)
Button.BackgroundColor3 = ThemeManager:GetColor("PrimaryColor")
Button.TextColor3 = ThemeManager:GetColor("TextColor")
Button.Text = "Tıkla!"
Button.Font = Enum.Font.GothamBold
Button.TextSize = 18
Button.Parent = MainFrame

local ButtonCorner = Instance.new("UICorner")
ButtonCorner.CornerRadius = UDim.new(0, 12)
ButtonCorner.Parent = Button

-- Butonu FluidUI'ya kaydet, animasyon ve ripple efektini etkinleştir
FluidUI.InterfaceManager:RegisterElement(Button)
FluidUI.InterfaceManager:EnableRippleEffect(Button)

FluidUI.InterfaceManager:SetElementCallback(Button, "Click", function()
    Button.Text = "Tıklandı!"
end)

-- Temayı anlık olarak değiştirmek için örnek
-- ThemeManager.CurrentTheme = "Light"
-- FluidUI.InterfaceManager:ApplyTheme("Light")
