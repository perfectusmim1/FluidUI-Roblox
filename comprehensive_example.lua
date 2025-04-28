-- comprehensive_example.lua
-- FluidUI kapsamlı örnek dosyası
-- Bu dosya, kütüphanenin tam potansiyelini göstermek için tasarlanmıştır 
-- ve tüm mevcut ve potansiyel özellikleri içerir

-- Kütüphaneyi yükleyelim
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- Kütüphane modüllerinin konumu, kendi projenizdeki yerlere göre değiştirin
local FluidUI = require(script.Parent:FindFirstChild("Library") or script:FindFirstChild("Library"))
local SaveManager = require(script.Parent:FindFirstChild("SaveManager") or script:FindFirstChild("SaveManager"))
local InterfaceManager = require(script.Parent:FindFirstChild("InterfaceManager") or script:FindFirstChild("InterfaceManager"))

---------------------------------------------
-- KONFİGÜRASYON VE BAŞLATMA
---------------------------------------------

-- SaveManager'ı başlat
SaveManager:Initialize()

-- InterfaceManager'ı başlat (ve SaveManager'a bağla)
InterfaceManager:Initialize()
InterfaceManager:SetSaveDataCallback(function()
    -- UI ayarlarını kaydetmek için kullanılacak verileri döndür
    return {
        ThemeName = FluidUI.CurrentTheme,
        CornerRadius = FluidUI.CornerRadius.Offset,
        Volume = 0.5,
        Notifications = true,
        Language = "Turkish",
        -- Diğer ayarlar...
    }
end)

-- Kaydedilmiş verileri UI'ye uygula
InterfaceManager:SetLoadDataCallback(function(data)
    if data.ThemeName then
        FluidUI:SetTheme(data.ThemeName)
    end
    if data.CornerRadius then
        FluidUI.CornerRadius = UDim.new(0, data.CornerRadius)
    end
    -- Diğer ayarları uygula...
end)

-- Fluent UI Kütüphanesini Başlat
local ui = FluidUI:Create({
    Theme = "Dark",       -- Başlangıç teması: Dark, Light veya Neon
    Responsive = true,    -- Responsive davranışı etkinleştir
    Parent = nil,         -- Özel bir Parent belirtebilirsiniz (nil = PlayerGui)
    Title = "FluidUI Demo",
    Version = "v1.0.0",
    RoundedCorners = true,
    BlurEffect = true,
    Draggable = true,
    MinimizeButton = true,
    CloseButton = true
})

---------------------------------------------
-- ANA PENCERE YAPISI
---------------------------------------------

-- Ana pencere oluştur
local mainWindow = ui:Window({
    Title = "FluidUI Demo",
    Size = UDim2.new(0, 800, 0, 600),
    Position = UDim2.new(0.5, -400, 0.5, -300),
    Draggable = true,
    Resizable = true,
    MinSize = Vector2.new(400, 300),
    CloseCallback = function()
        ui:Notify("Pencere kapatıldı", "Info")
    end
})

-- Tab sistemi oluştur
local tabs = mainWindow:TabSystem({
    Tabs = {
        {Name = "Ana Sayfa", Icon = "home"},
        {Name = "Temel Bileşenler", Icon = "components"},
        {Name = "Gelişmiş Bileşenler", Icon = "advanced"},
        {Name = "Bildirimler & Diyaloglar", Icon = "notifications"},
        {Name = "Temalar & Stilller", Icon = "palette"},
        {Name = "Ayarlar", Icon = "settings"}
    }
})

---------------------------------------------
-- ANA SAYFA SEKME İÇERİĞİ
---------------------------------------------

local homePage = tabs:GetTabPage("Ana Sayfa")

homePage:Label({
    Text = "FluidUI Modern Roblox UI Kütüphanesi",
    TextSize = 24,
    Bold = true,
    Position = UDim2.new(0.5, 0, 0.1, 0),
    AnchorPoint = Vector2.new(0.5, 0),
    Align = "Center",
    Size = UDim2.new(0, 400, 0, 40)
})

homePage:Label({
    Text = "Fluent UI prensiplerinden ilham alan modern, yumuşak ve akıcı UI kütüphanesi",
    TextSize = 16,
    Position = UDim2.new(0.5, 0, 0.2, 0),
    AnchorPoint = Vector2.new(0.5, 0),
    Align = "Center",
    Size = UDim2.new(0, 500, 0, 30)
})

-- Logo/Image ekle
homePage:Image({
    Image = "rbxassetid://0", -- Kendi asset ID'nizi koyun
    Size = UDim2.new(0, 200, 0, 200),
    Position = UDim2.new(0.5, 0, 0.35, 0),
    AnchorPoint = Vector2.new(0.5, 0)
})

local quickStartCard = homePage:Card({
    Title = "Hızlı Başlangıç",
    Size = UDim2.new(0, 250, 0, 120),
    Position = UDim2.new(0.3, -125, 0.65, 0),
    Description = "Hızlı başlamanız için temel örnek kodları ve belgeleri görüntüleyin."
})

quickStartCard:Button({
    Text = "Belgeleri Aç",
    Size = UDim2.new(0.8, 0, 0, 36),
    Position = UDim2.new(0.5, 0, 0.7, 0),
    AnchorPoint = Vector2.new(0.5, 0),
    Callback = function()
        ui:Notify("Belgeler henüz hazır değil!", "Warning", 3)
    end
})

local themeCard = homePage:Card({
    Title = "Temayı Değiştir",
    Size = UDim2.new(0, 250, 0, 120),
    Position = UDim2.new(0.7, -125, 0.65, 0),
    Description = "UI görünümünü özelleştirmek için farklı temaları deneyin."
})

themeCard:Dropdown({
    Options = {"Dark", "Light", "Neon"},
    Default = ui.CurrentTheme,
    Size = UDim2.new(0.8, 0, 0, 36),
    Position = UDim2.new(0.5, 0, 0.7, 0),
    AnchorPoint = Vector2.new(0.5, 0),
    Callback = function(selected)
        ui:SetTheme(selected)
        ui:Notify("Tema değiştirildi: " .. selected, "Success", 3)
    end
})

homePage:Button({
    Text = "Tüm Bildirimleri Göster",
    Size = UDim2.new(0, 200, 0, 40),
    Position = UDim2.new(0.5, 0, 0.85, 0),
    AnchorPoint = Vector2.new(0.5, 0),
    Primary = true,
    Callback = function()
        ui:Notify("Bilgi Bildirimi", "Info", 3)
        wait(0.5)
        ui:Notify("Başarı Bildirimi", "Success", 3)
        wait(0.5)
        ui:Notify("Uyarı Bildirimi", "Warning", 3)
        wait(0.5)
        ui:Notify("Hata Bildirimi", "Error", 3)
    end
})

---------------------------------------------
-- TEMEL BİLEŞENLER SEKME İÇERİĞİ
---------------------------------------------

local basicPage = tabs:GetTabPage("Temel Bileşenler")

-- Grid düzeni oluştur
local grid = basicPage:Grid({
    Columns = 2,
    Padding = UDim2.new(0, 20, 0, 20),
    Position = UDim2.new(0.5, 0, 0.1, 0),
    Size = UDim2.new(0.9, 0, 0.8, 0),
    AnchorPoint = Vector2.new(0.5, 0)
})

-- Butonlar
local buttonSection = grid:Section({
    Title = "Butonlar",
    Size = UDim2.new(1, 0, 0, 200),
})

buttonSection:Button({
    Text = "Standart Buton",
    Size = UDim2.new(0.8, 0, 0, 40),
    Position = UDim2.new(0.5, 0, 0.2, 0),
    AnchorPoint = Vector2.new(0.5, 0),
    Callback = function()
        ui:Notify("Standart buton tıklandı")
    end
})

buttonSection:Button({
    Text = "Birincil Buton",
    Size = UDim2.new(0.8, 0, 0, 40),
    Position = UDim2.new(0.5, 0, 0.4, 0),
    AnchorPoint = Vector2.new(0.5, 0),
    Primary = true,
    Callback = function()
        ui:Notify("Birincil buton tıklandı")
    end
})

buttonSection:Button({
    Text = "Özel Glow Buton",
    Size = UDim2.new(0.8, 0, 0, 40),
    Position = UDim2.new(0.5, 0, 0.6, 0),
    AnchorPoint = Vector2.new(0.5, 0),
    Primary = true,
    Glow = true,
    Callback = function()
        ui:Notify("Özel buton tıklandı")
    end
})

buttonSection:IconButton({
    Icon = "settings",
    Size = UDim2.new(0, 40, 0, 40),
    Position = UDim2.new(0.3, 0, 0.8, 0),
    AnchorPoint = Vector2.new(0.5, 0),
    Tooltip = "Ayarlar",
    Callback = function()
        ui:Notify("Ayarlar butonu tıklandı")
    end
})

buttonSection:IconButton({
    Icon = "refresh",
    Size = UDim2.new(0, 40, 0, 40),
    Position = UDim2.new(0.5, 0, 0.8, 0),
    AnchorPoint = Vector2.new(0.5, 0),
    Tooltip = "Yenile",
    Callback = function()
        ui:Notify("Yenile butonu tıklandı")
    end
})

buttonSection:IconButton({
    Icon = "close",
    Size = UDim2.new(0, 40, 0, 40),
    Position = UDim2.new(0.7, 0, 0.8, 0),
    AnchorPoint = Vector2.new(0.5, 0),
    Tooltip = "Kapat",
    Callback = function()
        ui:Notify("Kapat butonu tıklandı")
    end
})

-- Giriş bileşenleri
local inputSection = grid:Section({
    Title = "Giriş Bileşenleri",
    Size = UDim2.new(1, 0, 0, 200),
})

inputSection:Toggle({
    Text = "Bildirimleri Etkinleştir",
    Position = UDim2.new(0.3, 0, 0.2, 0),
    AnchorPoint = Vector2.new(0.5, 0),
    State = true,
    Callback = function(state)
        ui:Notify("Toggle durumu: " .. (state and "Açık" or "Kapalı"))
    end
})

inputSection:Checkbox({
    Text = "Ses Efektleri",
    Position = UDim2.new(0.7, 0, 0.2, 0),
    AnchorPoint = Vector2.new(0.5, 0),
    Checked = true,
    Callback = function(checked)
        ui:Notify("Checkbox durumu: " .. (checked and "Seçili" or "Seçili değil"))
    end
})

inputSection:RadioGroup({
    Options = {"Seçenek 1", "Seçenek 2", "Seçenek 3"},
    Selected = "Seçenek 1",
    Position = UDim2.new(0.3, 0, 0.5, 0),
    AnchorPoint = Vector2.new(0.5, 0),
    Callback = function(selected)
        ui:Notify("Radio seçim: " .. selected)
    end
})

inputSection:Slider({
    Text = "Ses Seviyesi",
    Min = 0,
    Max = 100,
    Default = 50,
    Position = UDim2.new(0.7, 0, 0.5, 0),
    AnchorPoint = Vector2.new(0.5, 0),
    Size = UDim2.new(0.4, 0, 0, 40),
    Callback = function(value)
        -- Her değişiklikte çok fazla bildirim istemediğimiz için,
        -- Slider'ı bıraktığında bildirim gönderelim
    end,
    ReleasedCallback = function(value)
        ui:Notify("Ses seviyesi: %" .. value)
    end
})

inputSection:TextBox({
    PlaceholderText = "Adınızı girin...",
    Text = "",
    Position = UDim2.new(0.5, 0, 0.8, 0),
    AnchorPoint = Vector2.new(0.5, 0),
    Size = UDim2.new(0.8, 0, 0, 40),
    ClearButtonEnabled = true,
    Callback = function(text)
        ui:Notify("Giriş: " .. text)
    end
})

-- Dropdown ve seçim bileşenleri
local selectSection = grid:Section({
    Title = "Dropdown ve Seçim Bileşenleri",
    Size = UDim2.new(1, 0, 0, 200),
})

selectSection:Dropdown({
    Text = "Tek Seçimli Dropdown",
    Options = {"Seçenek 1", "Seçenek 2", "Seçenek 3", "Seçenek 4"},
    Selected = "Seçenek 1",
    Position = UDim2.new(0.5, 0, 0.25, 0),
    AnchorPoint = Vector2.new(0.5, 0),
    Size = UDim2.new(0.8, 0, 0, 40),
    Callback = function(selected)
        ui:Notify("Seçim: " .. selected)
    end
})

selectSection:MultiDropdown({
    Text = "Çoklu Seçimli Dropdown",
    Options = {"Elma", "Armut", "Muz", "Portakal", "Kiraz"},
    Selected = {"Elma"},
    Position = UDim2.new(0.5, 0, 0.5, 0),
    AnchorPoint = Vector2.new(0.5, 0),
    Size = UDim2.new(0.8, 0, 0, 40),
    Callback = function(selected)
        ui:Notify("Seçilenler: " .. table.concat(selected, ", "))
    end
})

selectSection:ComboBox({
    Text = "ComboBox (Yazılabilir Dropdown)",
    Options = {"İstanbul", "Ankara", "İzmir", "Bursa", "Antalya"},
    Position = UDim2.new(0.5, 0, 0.75, 0),
    AnchorPoint = Vector2.new(0.5, 0),
    Size = UDim2.new(0.8, 0, 0, 40),
    AllowCustomInput = true,
    Callback = function(selected)
        ui:Notify("Seçilen/Girilen: " .. selected)
    end
})

-- Etiketler ve Metinler
local textSection = grid:Section({
    Title = "Etiketler ve Metinler",
    Size = UDim2.new(1, 0, 0, 200),
})

textSection:Label({
    Text = "Standart Etiket",
    Position = UDim2.new(0.5, 0, 0.2, 0),
    AnchorPoint = Vector2.new(0.5, 0),
    Size = UDim2.new(0.8, 0, 0, 30),
    Align = "Center"
})

textSection:Header({
    Text = "Başlık Metni",
    Position = UDim2.new(0.5, 0, 0.35, 0),
    AnchorPoint = Vector2.new(0.5, 0),
    Size = UDim2.new(0.8, 0, 0, 40),
})

textSection:Paragraph({
    Text = "Bu bir paragraf metnidir. Daha uzun metinler için uygundur. İçerik otomatik olarak satırlara bölünecektir. Örnek detaylı açıklama metnini burada gösterebilirsiniz.",
    Position = UDim2.new(0.5, 0, 0.6, 0),
    AnchorPoint = Vector2.new(0.5, 0),
    Size = UDim2.new(0.8, 0, 0, 80),
    TextWrapped = true
})

---------------------------------------------
-- GELİŞMİŞ BİLEŞENLER SEKME İÇERİĞİ
---------------------------------------------

local advancedPage = tabs:GetTabPage("Gelişmiş Bileşenler")

local advancedGrid = advancedPage:Grid({
    Columns = 2,
    Padding = UDim2.new(0, 20, 0, 20),
    Position = UDim2.new(0.5, 0, 0.1, 0),
    Size = UDim2.new(0.9, 0, 0.8, 0),
    AnchorPoint = Vector2.new(0.5, 0)
})

-- Renk Seçici
local colorSection = advancedGrid:Section({
    Title = "Renk Seçici",
    Size = UDim2.new(1, 0, 0, 200),
})

colorSection:ColorPicker({
    Title = "Özel Renk Seçin",
    Default = Color3.fromRGB(0, 120, 215),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    AnchorPoint = Vector2.new(0.5, 0),
    Size = UDim2.new(0.8, 0, 0, 150),
    Callback = function(color)
        ui:Notify("Seçilen renk: RGB(" .. math.floor(color.R*255) .. "," .. math.floor(color.G*255) .. "," .. math.floor(color.B*255) .. ")")
    end
})

-- İlerleme Göstergeleri
local progressSection = advancedGrid:Section({
    Title = "İlerleme Göstergeleri",
    Size = UDim2.new(1, 0, 0, 200),
})

local progressBar = progressSection:ProgressBar({
    Text = "Yükleniyor...",
    Value = 30,
    Position = UDim2.new(0.5, 0, 0.2, 0),
    AnchorPoint = Vector2.new(0.5, 0),
    Size = UDim2.new(0.8, 0, 0, 30),
})

progressSection:Button({
    Text = "%10 Arttır",
    Position = UDim2.new(0.3, 0, 0.4, 0),
    AnchorPoint = Vector2.new(0.5, 0),
    Size = UDim2.new(0.35, 0, 0, 30),
    Callback = function()
        local newValue = math.min(100, progressBar:GetValue() + 10)
        progressBar:SetValue(newValue)
    end
})

progressSection:Button({
    Text = "%10 Azalt",
    Position = UDim2.new(0.7, 0, 0.4, 0),
    AnchorPoint = Vector2.new(0.5, 0),
    Size = UDim2.new(0.35, 0, 0, 30),
    Callback = function()
        local newValue = math.max(0, progressBar:GetValue() - 10)
        progressBar:SetValue(newValue)
    end
})

local loadingSpinner = progressSection:LoadingSpinner({
    Position = UDim2.new(0.3, 0, 0.7, 0),
    AnchorPoint = Vector2.new(0.5, 0),
    Size = UDim2.new(0, 50, 0, 50),
    Speed = 1.5
})

progressSection:Button({
    Text = "Durdur/Başlat",
    Position = UDim2.new(0.7, 0, 0.7, 0),
    AnchorPoint = Vector2.new(0.5, 0),
    Size = UDim2.new(0.35, 0, 0, 30),
    Callback = function()
        if loadingSpinner:IsSpinning() then
            loadingSpinner:Stop()
        else
            loadingSpinner:Start()
        end
    end
})

-- Akordiyonlar ve Genişleyen Paneller
local expandableSection = advancedGrid:Section({
    Title = "Akordiyonlar ve Genişleyen Paneller",
    Size = UDim2.new(1, 0, 0, 200),
})

local accordion = expandableSection:Accordion({
    Position = UDim2.new(0.5, 0, 0.5, 0),
    AnchorPoint = Vector2.new(0.5, 0),
    Size = UDim2.new(0.9, 0, 0, 120),
    Items = {
        {
            Title = "Bölüm 1",
            Content = "Bu bölümün içeriği burada görünür. İstediğiniz kadar metin ekleyebilirsiniz."
        },
        {
            Title = "Bölüm 2",
            Content = "Bu ikinci bölümün içeriğidir. Bölümler tıklandığında açılıp kapanır."
        },
        {
            Title = "Bölüm 3",
            Content = "Üçüncü bölüm içeriği burada."
        }
    }
})

-- Ağaç Görünümü
local treeSection = advancedGrid:Section({
    Title = "Ağaç Görünümü",
    Size = UDim2.new(1, 0, 0, 200),
})

treeSection:TreeView({
    Position = UDim2.new(0.5, 0, 0.5, 0),
    AnchorPoint = Vector2.new(0.5, 0),
    Size = UDim2.new(0.9, 0, 0, 150),
    Items = {
        {
            Text = "Ana Klasör",
            Children = {
                {
                    Text = "Alt Klasör 1",
                    Children = {
                        { Text = "Dosya 1.1" },
                        { Text = "Dosya 1.2" }
                    }
                },
                {
                    Text = "Alt Klasör 2",
                    Children = {
                        { Text = "Dosya 2.1" }
                    }
                },
                { Text = "Dosya 3" }
            }
        },
        {
            Text = "İkinci Ana Klasör",
            Children = {
                { Text = "Başka Dosya" }
            }
        }
    },
    Callback = function(item)
        ui:Notify("Seçilen öğe: " .. item.Text)
    end
})

---------------------------------------------
-- BİLDİRİMLER & DİYALOGLAR SEKME İÇERİĞİ
---------------------------------------------

local notificationsPage = tabs:GetTabPage("Bildirimler & Diyaloglar")

local notifySection = notificationsPage:Section({
    Title = "Bildirim Örnekleri",
    Size = UDim2.new(0.9, 0, 0, 200),
    Position = UDim2.new(0.5, 0, 0.1, 0),
    AnchorPoint = Vector2.new(0.5, 0)
})

local notifyTypes = {
    {Text = "Bilgi Bildirimi", Type = "Info"},
    {Text = "Başarı Bildirimi", Type = "Success"},
    {Text = "Uyarı Bildirimi", Type = "Warning"},
    {Text = "Hata Bildirimi", Type = "Error"},
}

for i, notifyInfo in ipairs(notifyTypes) do
    notifySection:Button({
        Text = notifyInfo.Text,
        Position = UDim2.new(0.5, 0, 0.2 + (i-1)*0.2, 0),
        AnchorPoint = Vector2.new(0.5, 0),
        Size = UDim2.new(0.8, 0, 0, 40),
        Callback = function()
            ui:Notify(notifyInfo.Text, notifyInfo.Type, 3)
        end
    })
end

local dialogSection = notificationsPage:Section({
    Title = "Diyaloglar",
    Size = UDim2.new(0.9, 0, 0, 240),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    AnchorPoint = Vector2.new(0.5, 0)
})

dialogSection:Button({
    Text = "Bilgi Diyaloğu",
    Position = UDim2.new(0.5, 0, 0.15, 0),
    AnchorPoint = Vector2.new(0.5, 0),
    Size = UDim2.new(0.8, 0, 0, 40),
    Callback = function()
        ui:ShowMessageBox({
            Title = "Bilgi",
            Text = "Bu bir bilgilendirme mesajıdır.",
            Type = "Info",
            Buttons = {"Tamam"}
        })
    end
})

dialogSection:Button({
    Text = "Onay Diyaloğu",
    Position = UDim2.new(0.5, 0, 0.35, 0),
    AnchorPoint = Vector2.new(0.5, 0),
    Size = UDim2.new(0.8, 0, 0, 40),
    Callback = function()
        ui:ShowMessageBox({
            Title = "Onay",
            Text = "Bu işlemi gerçekleştirmek istediğinizden emin misiniz?",
            Type = "Warning",
            Buttons = {"Evet", "Hayır"},
            Callback = function(button)
                ui:Notify("Seçilen: " .. button)
            end
        })
    end
})

dialogSection:Button({
    Text = "Özel Giriş Diyaloğu",
    Position = UDim2.new(0.5, 0, 0.55, 0),
    AnchorPoint = Vector2.new(0.5, 0),
    Size = UDim2.new(0.8, 0, 0, 40),
    Callback = function()
        ui:ShowInputDialog({
            Title = "Kullanıcı Adı",
            Placeholder = "Kullanıcı adınızı girin",
            Buttons = {"Onayla", "İptal"},
            Callback = function(text, button)
                if button == "Onayla" and text ~= "" then
                    ui:Notify("Hoşgeldin, " .. text)
                end
            end
        })
    end
})

dialogSection:Button({
    Text = "Modal Diyalog (Özelleştirilebilir)",
    Position = UDim2.new(0.5, 0, 0.75, 0),
    AnchorPoint = Vector2.new(0.5, 0),
    Size = UDim2.new(0.8, 0, 0, 40),
    Callback = function()
        -- Özelleştirilebilir modal diyalog
        local modal = ui:CreateModal({
            Title = "Özel Modal",
            Size = UDim2.new(0, 400, 0, 300),
            CloseButton = true
        })
        
        modal:Label({
            Text = "Bu tamamen özelleştirilebilir bir modal diyalogdur.",
            Position = UDim2.new(0.5, 0, 0.2, 0),
            AnchorPoint = Vector2.new(0.5, 0),
            Size = UDim2.new(0.8, 0, 0, 30),
            Align = "Center"
        })
        
        modal:Image({
            Image = "rbxassetid://0", -- Kendi asset ID'nizi koyun
            Size = UDim2.new(0, 100, 0, 100),
            Position = UDim2.new(0.5, 0, 0.45, 0),
            AnchorPoint = Vector2.new(0.5, 0)
        })
        
        modal:Button({
            Text = "Kapat",
            Position = UDim2.new(0.5, 0, 0.85, 0),
            AnchorPoint = Vector2.new(0.5, 0),
            Size = UDim2.new(0.4, 0, 0, 36),
            Callback = function()
                modal:Close()
            end
        })
        
        modal:Show()
    end
})

---------------------------------------------
-- TEMALAR & STİLLER SEKME İÇERİĞİ
---------------------------------------------

local themesPage = tabs:GetTabPage("Temalar & Stilller")

local themesSection = themesPage:Section({
    Title = "Tema Seçimi",
    Size = UDim2.new(0.9, 0, 0, 200),
    Position = UDim2.new(0.5, 0, 0.1, 0),
    AnchorPoint = Vector2.new(0.5, 0)
})

local themes = {"Dark", "Light", "Neon"}
local themeButtons = {}

for i, themeName in ipairs(themes) do
    themeButtons[themeName] = themesSection:Button({
        Text = themeName,
        Position = UDim2.new((i-1)*0.33 + 0.17, 0, 0.3, 0),
        AnchorPoint = Vector2.new(0.5, 0),
        Size = UDim2.new(0.25, 0, 0, 40),
        Callback = function()
            ui:SetTheme(themeName)
            for _, btn in pairs(themeButtons) do
                btn:SetPrimary(false)
            end
            themeButtons[themeName]:SetPrimary(true)
        end
    })
    
    if themeName == ui.CurrentTheme then
        themeButtons[themeName]:SetPrimary(true)
    end
end

local customizeSection = themesPage:Section({
    Title = "Özelleştirme",
    Size = UDim2.new(0.9, 0, 0, 250),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    AnchorPoint = Vector2.new(0.5, 0)
})

customizeSection:Label({
    Text = "Köşe Yuvarlaklığı",
    Position = UDim2.new(0.3, 0, 0.2, 0),
    AnchorPoint = Vector2.new(0.5, 0),
    Size = UDim2.new(0.4, 0, 0, 30),
})

customizeSection:Slider({
    Min = 0,
    Max = 24,
    Default = ui.CornerRadius.Offset,
    Position = UDim2.new(0.7, 0, 0.2, 0),
    AnchorPoint = Vector2.new(0.5, 0),
    Size = UDim2.new(0.4, 0, 0, 30),
    Callback = function(value)
        ui.CornerRadius = UDim.new(0, value)
        SaveManager:SaveCurrentConfig({CornerRadius = value})
    end
})

customizeSection:Label({
    Text = "Buton Glow Efekti",
    Position = UDim2.new(0.3, 0, 0.4, 0),
    AnchorPoint = Vector2.new(0.5, 0),
    Size = UDim2.new(0.4, 0, 0, 30),
})

customizeSection:Toggle({
    Position = UDim2.new(0.7, 0, 0.4, 0),
    AnchorPoint = Vector2.new(0.5, 0),
    State = true,
    Callback = function(state)
        ui.UseGlowEffect = state
        SaveManager:SaveCurrentConfig({UseGlowEffect = state})
    end
})

customizeSection:Label({
    Text = "Animasyon Hızı",
    Position = UDim2.new(0.3, 0, 0.6, 0),
    AnchorPoint = Vector2.new(0.5, 0),
    Size = UDim2.new(0.4, 0, 0, 30),
})

customizeSection:Slider({
    Min = 0.1,
    Max = 2,
    Default = 1,
    Increment = 0.1,
    Position = UDim2.new(0.7, 0, 0.6, 0),
    AnchorPoint = Vector2.new(0.5, 0),
    Size = UDim2.new(0.4, 0, 0, 30),
    Callback = function(value)
        ui.AnimationSpeed = value
        SaveManager:SaveCurrentConfig({AnimationSpeed = value})
    end
})

customizeSection:Button({
    Text = "Özel Temayı Kaydet",
    Position = UDim2.new(0.5, 0, 0.8, 0),
    AnchorPoint = Vector2.new(0.5, 0),
    Size = UDim2.new(0.6, 0, 0, 40),
    Primary = true,
    Callback = function()
        ui:ShowInputDialog({
            Title = "Tema Adı",
            Placeholder = "Özel tema adını girin",
            Buttons = {"Kaydet", "İptal"},
            Callback = function(text, button)
                if button == "Kaydet" and text ~= "" then
                    -- Tema kaydetme işlemi
                    ui:Notify("Tema kaydedildi: " .. text, "Success")
                end
            end
        })
    end
})

---------------------------------------------
-- AYARLAR SEKME İÇERİĞİ
---------------------------------------------

local settingsPage = tabs:GetTabPage("Ayarlar")

local configSection = settingsPage:Section({
    Title = "Konfigürasyon Yönetimi",
    Size = UDim2.new(0.9, 0, 0, 280),
    Position = UDim2.new(0.5, 0, 0.1, 0),
    AnchorPoint = Vector2.new(0.5, 0)
})

local configNameInput = configSection:TextBox({
    PlaceholderText = "Konfigürasyon adı...",
    Position = UDim2.new(0.5, 0, 0.15, 0),
    AnchorPoint = Vector2.new(0.5, 0),
    Size = UDim2.new(0.8, 0, 0, 40),
    ClearButtonEnabled = true
})

configSection:Button({
    Text = "Yeni Konfigürasyon Oluştur",
    Position = UDim2.new(0.5, 0, 0.3, 0),
    AnchorPoint = Vector2.new(0.5, 0),
    Size = UDim2.new(0.8, 0, 0, 40),
    Callback = function()
        local configName = configNameInput:GetText()
        if configName and configName ~= "" then
            SaveManager:CreateConfig(configName, {
                ThemeName = ui.CurrentTheme,
                CornerRadius = ui.CornerRadius.Offset,
                UseGlowEffect = ui.UseGlowEffect,
                AnimationSpeed = ui.AnimationSpeed,
                -- Diğer ayarlar...
            })
            configNameInput:SetText("")
            ui:Notify("Konfigürasyon oluşturuldu: " .. configName, "Success")
        else
            ui:Notify("Lütfen geçerli bir konfigürasyon adı girin", "Warning")
        end
    end
})

-- Mevcut konfigürasyonları listele
local configDropdown = configSection:Dropdown({
    Text = "Konfigürasyonlar",
    Options = SaveManager:RefreshConfigList(),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    AnchorPoint = Vector2.new(0.5, 0),
    Size = UDim2.new(0.8, 0, 0, 40),
    Callback = function(selected)
        configSection.SelectedConfig = selected
    end
})

-- Refresh configs button
configSection:Button({
    Text = "Listeyi Yenile",
    Position = UDim2.new(0.3, 0, 0.65, 0),
    AnchorPoint = Vector2.new(0.5, 0),
    Size = UDim2.new(0.35, 0, 0, 40),
    Callback = function()
        local configs = SaveManager:RefreshConfigList()
        configDropdown:UpdateOptions(configs)
        ui:Notify("Konfigürasyon listesi yenilendi")
    end
})

-- Load selected config
configSection:Button({
    Text = "Yükle",
    Position = UDim2.new(0.7, 0, 0.65, 0),
    AnchorPoint = Vector2.new(0.5, 0),
    Size = UDim2.new(0.35, 0, 0, 40),
    Callback = function()
        if configSection.SelectedConfig then
            local config = SaveManager:LoadConfig(configSection.SelectedConfig)
            if config then
                if config.ThemeName then ui:SetTheme(config.ThemeName) end
                if config.CornerRadius then ui.CornerRadius = UDim.new(0, config.CornerRadius) end
                if config.UseGlowEffect ~= nil then ui.UseGlowEffect = config.UseGlowEffect end
                if config.AnimationSpeed then ui.AnimationSpeed = config.AnimationSpeed end
                ui:Notify("Konfigürasyon yüklendi: " .. configSection.SelectedConfig, "Success")
            end
        else
            ui:Notify("Lütfen önce bir konfigürasyon seçin", "Warning")
        end
    end
})

-- Delete selected config
configSection:Button({
    Text = "Sil",
    Position = UDim2.new(0.3, 0, 0.8, 0),
    AnchorPoint = Vector2.new(0.5, 0),
    Size = UDim2.new(0.35, 0, 0, 40),
    Danger = true,
    Callback = function()
        if configSection.SelectedConfig then
            ui:ShowMessageBox({
                Title = "Konfigürasyon Silme",
                Text = configSection.SelectedConfig .. " konfigürasyonunu silmek istediğinizden emin misiniz?",
                Type = "Warning",
                Buttons = {"Evet", "Hayır"},
                Callback = function(button)
                    if button == "Evet" then
                        SaveManager:DeleteConfig(configSection.SelectedConfig)
                        local configs = SaveManager:RefreshConfigList()
                        configDropdown:UpdateOptions(configs)
                        configSection.SelectedConfig = nil
                        ui:Notify("Konfigürasyon silindi", "Success")
                    end
                end
            })
        else
            ui:Notify("Lütfen önce bir konfigürasyon seçin", "Warning")
        end
    end
})

-- Save current settings to selected config
configSection:Button({
    Text = "Mevcut Ayarları Kaydet",
    Position = UDim2.new(0.7, 0, 0.8, 0),
    AnchorPoint = Vector2.new(0.5, 0),
    Size = UDim2.new(0.35, 0, 0, 40),
    Callback = function()
        if configSection.SelectedConfig then
            SaveManager:SaveCurrentConfig({
                ThemeName = ui.CurrentTheme,
                CornerRadius = ui.CornerRadius.Offset,
                UseGlowEffect = ui.UseGlowEffect,
                AnimationSpeed = ui.AnimationSpeed,
                -- Diğer ayarlar...
            }, configSection.SelectedConfig)
            ui:Notify("Ayarlar kaydedildi: " .. configSection.SelectedConfig, "Success")
        else
            ui:Notify("Lütfen önce bir konfigürasyon seçin", "Warning")
        end
    end
})

-- Genel Ayarlar
local generalSection = settingsPage:Section({
    Title = "Genel Ayarlar",
    Size = UDim2.new(0.9, 0, 0, 200),
    Position = UDim2.new(0.5, 0, 0.6, 0),
    AnchorPoint = Vector2.new(0.5, 0)
})

generalSection:Label({
    Text = "Otomatik Kaydetme",
    Position = UDim2.new(0.3, 0, 0.2, 0),
    AnchorPoint = Vector2.new(0.5, 0),
    Size = UDim2.new(0.4, 0, 0, 30),
})

generalSection:Toggle({
    Position = UDim2.new(0.7, 0, 0.2, 0),
    AnchorPoint = Vector2.new(0.5, 0),
    State = true,
    Callback = function(state)
        if state then
            SaveManager:EnableAutoSave(60) -- 60 saniyede bir otomatik kaydet
            ui:Notify("Otomatik kaydetme etkinleştirildi")
        else
            SaveManager:DisableAutoSave()
            ui:Notify("Otomatik kaydetme devre dışı bırakıldı")
        end
    end
})

generalSection:Label({
    Text = "Kütüphane Sürümü",
    Position = UDim2.new(0.3, 0, 0.5, 0),
    AnchorPoint = Vector2.new(0.5, 0),
    Size = UDim2.new(0.4, 0, 0, 30),
})

generalSection:Label({
    Text = "v1.0.0",
    Position = UDim2.new(0.7, 0, 0.5, 0),
    AnchorPoint = Vector2.new(0.5, 0),
    Size = UDim2.new(0.4, 0, 0, 30),
    TextColor3 = Color3.fromRGB(150, 150, 150)
})

generalSection:Button({
    Text = "GitHub'da İncele",
    Position = UDim2.new(0.5, 0, 0.8, 0),
    AnchorPoint = Vector2.new(0.5, 0),
    Size = UDim2.new(0.6, 0, 0, 40),
    Callback = function()
        ui:Notify("GitHub URL: [Sizin URL'niz]")
    end
})

return ui