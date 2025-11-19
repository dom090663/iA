-- โหลด Rayfield
local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/dom090663/Rayfield/main/source.lua"))()

local Window = Rayfield:CreateWindow({
    Name = "iA Hub (ภาษาไทย)",
    LoadingTitle = "กำลังโหลด iA Hub...",
    LoadingSubtitle = "ขอให้สนุก :)",
    ConfigurationSaving = { Enabled = true, FolderName = nil, FileName = "iAHubConfig" },
    Discord = { Enabled = false }
})

-- Services
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")

-- Player
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")

-- Variables
local speedSetting = 5
local tweenMinDelay = 0.5
local tweenMaxDelay = 10
local noclipEnabled = false

-- Noclip
RunService.Stepped:Connect(function()
    if noclipEnabled and character then
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

-- Tween function
local function tweenTo(position, delay)
    local tweenInfo = TweenInfo.new(delay or tweenMinDelay, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(hrp, tweenInfo, {CFrame = CFrame.new(position)})
    tween:Play()
    tween.Completed:Wait()
end

-- เก็บของ
local function collectItem(item)
    local handle = item:FindFirstChild("Handle")
    if handle then
        local clickPart = handle:FindFirstChild("ClickPart")
        if clickPart then
            local detector = clickPart:FindFirstChildWhichIsA("ClickDetector")
            if detector then
                task.spawn(function()
                    fireclickdetector(detector)
                end)
            end
        end
    end
end

-- Hop server ถ้าไม่มีไอเท็ม
local function checkAndHop()
    local spawnedItems = workspace:WaitForChild("SpawnedItems"):GetChildren()
    if #spawnedItems == 0 then
        TeleportService:Teleport(game.PlaceId, player)
    end
end

-- Slider ปรับความเร็วทวีน
Rayfield:CreateSlider({
    Name = "ความเร็วทวีน (1-10)",
    Range = {1,10},
    Increment = 1,
    Suffix = "",
    CurrentValue = speedSetting,
    Flag = "SpeedSlider",
    Callback = function(value)
        speedSetting = value
        tweenMinDelay = math.max(0.1, speedSetting - 2)
        tweenMaxDelay = speedSetting + 5
    end
})

-- Toggle Noclip
Rayfield:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Flag = "NoclipToggle",
    Callback = function(value)
        noclipEnabled = value
    end
})

-- ปุ่มเริ่มเก็บของ
Rayfield:CreateButton({
    Name = "เริ่มเก็บของ",
    Callback = function()
        task.spawn(function()
            while true do
                checkAndHop()
                local items = workspace.SpawnedItems:GetChildren()
                if #items == 0 then
                    task.wait(1)
                    continue
                end
                -- Sort ใกล้ตัวก่อน
                table.sort(items, function(a,b)
                    return (a.Handle.Position - hrp.Position).Magnitude < (b.Handle.Position - hrp.Position).Magnitude
                end)
                for _, item in ipairs(items) do
                    if item:FindFirstChild("Handle") then
                        local distance = (item.Handle.Position - hrp.Position).Magnitude
                        local delay = math.clamp(distance/100, tweenMinDelay, tweenMaxDelay)
                        tweenTo(item.Handle.Position + Vector3.new(0,3,0), delay)
                        collectItem(item)
                    end
                end
                task.wait(1)
            end
        end)
    end
})

-- ปุ่ม Escape (รันซ้ำ 20 ครั้ง)
Rayfield:CreateButton({
    Name = "Escape (หลบหนี)",
    Callback = function()
        task.spawn(function()
            for i = 1,20 do
                local args = {"Escape"}
                local success, err = pcall(function()
                    ReplicatedStorage:WaitForChild("PlayerTurnInput"):InvokeServer(unpack(args))
                end)
                if not success then warn("Escape ล้มเหลว: "..tostring(err)) end
                task.wait(0.05) -- หน่วงเวลาเล็กน้อยระหว่างการยิง Remote
            end
        end)
    end
})

-- ปุ่ม Dodge (ถ้าต้องการ)
Rayfield:CreateButton({
    Name = "Dodge (ถ้าเล่นมินิเกม)",
    Callback = function()
        task.spawn(function()
            local args = {true,true}
            local success, err = pcall(function()
                ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Information"):WaitForChild("RemoteFunction"):FireServer(unpack(args))
            end)
            if not success then warn("Dodge ล้มเหลว: "..tostring(err)) end
        end)
    end
})
