-- example.lua
-- FluidUI örnek kullanım dosyası
-- Bu dosya, kütüphanenin temel özelliklerini Roblox Studio'da test etmek için hazırlanmıştır.

local FluidUI = require(script.Parent:FindFirstChild("Library") or script:FindFirstChild("Library"))

local ui = FluidUI:Create({
    Theme = "Dark",
    Responsive = true
})

-- Label
local label = ui:Label({
    Text = "FluidUI - Modern Roblox UI",
    Position = UDim2.new(0.5, -160, 0.1, 0),
    Size = UDim2.new(0, 320, 0, 40)
})

-- Button
local button = ui:Button({
    Text = "Tema: Light",
    Position = UDim2.new(0.5, -80, 0.2, 0),
    Callback = function()
        local newTheme = ui.CurrentTheme == "Light" and "Dark" or "Light"
        ui:SetTheme(newTheme)
        button.Text = "Tema: " .. (newTheme == "Light" and "Dark" or "Light")
        ui:Notify("Tema değiştirildi: " .. newTheme)
    end
})

-- Toggle
local toggle = ui:Toggle({
    Position = UDim2.new(0.5, -30, 0.3, 0),
    State = false,
    Callback = function(state)
        ui:Notify(state and "Açık" or "Kapalı")
    end
})

-- Multi-Select Dropdown
local dropdown = ui:MultiDropdown({
    Position = UDim2.new(0.5, -100, 0.4, 0),
    Options = {"Elma", "Armut", "Muz", "Karpuz", "Çilek"},
    Selected = {"Elma"},
    Placeholder = "Meyve seç...",
    Callback = function(selected)
        ui:Notify("Seçilenler: " .. table.concat(selected, ", "))
    end
})

-- Bildirim örneği
ui:Notify("Hoşgeldiniz!", 3)

-- Dinamik güncelleme örneği
wait(2)
ui:UpdateElement(label, {Text = "Hoşgeldin, Roblox!"})

-- SaveManager ve InterfaceManager örnek entegrasyon
ui.SaveManager:Initialize()
ui.InterfaceManager:Initialize()

return ui
