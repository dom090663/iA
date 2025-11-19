--// Services
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local workspace = game:GetService("Workspace")

--// Player
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")

--// GUI
local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Rayfield/main/source"))()

local Window = Rayfield:CreateWindow({
    Name = "AutoFarm Item Hub",
    LoadingTitle = "กำลังโหลด AutoFarm...",
    LoadingSubtitle = "กรุณารอสักครู่",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "AutoFarmItemHub",
        FileName = "Config"
    },
    Discord = {
        Enabled = false
    },
    KeySystem = false
})

--// ตัวแปรปรับ
local escapeEnable = false
local tweenSpeed = 5 -- ค่าเริ่มต้นกลาง
local tweenSpeeds = {ใกล้ = 3, กลาง = 5, ไกล = 7}

--// ฟังก์ชันทวีน
local function tweenTo(position, speed)
    local tweenInfo = TweenInfo.new(speed, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(hrp, tweenInfo, {CFrame = CFrame.new(position)})
    tween:Play()
    tween.Completed:Wait()
end

--// ฟังก์ชันเก็บไอเท็ม
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

--// GUI Slider ปรับความเร็วทวีน
Window:CreateSlider({
    Name = "ปรับความเร็วทวีน (กลาง)",
    Range = {1, 10},
    Increment = 1,
    Suffix = " ความเร็ว",
    CurrentValue = tweenSpeed,
    Flag = "TweenSpeed",
    Callback = function(value)
        tweenSpeed = value
        -- ปรับสัดส่วนตามใกล้ กลาง ไกล
        tweenSpeeds.กลาง = value
        tweenSpeeds.ใกล้ = math.max(value - 2,1)
        tweenSpeeds.ไกล = value + 2
    end
})

--// GUI Toggle Escape
Window:CreateToggle({
    Name = "เปิด/ปิด Escape",
    CurrentValue = false,
    Flag = "EscapeToggle",
    Callback = function(Value)
        escapeEnable = Value
        if escapeEnable then
            task.spawn(function()
                while escapeEnable do
                    -- ยิง Remote 20 ครั้งต่อรอบ
                    for i = 1, 20 do
                        local args = {"Escape"}
                        pcall(function()
                            ReplicatedStorage:WaitForChild("PlayerTurnInput"):InvokeServer(unpack(args))
                        end)
                        task.wait(0.01)
                    end
                    task.wait(0.05)
                end
            end)
        end
    end
})

--// ฟังก์ชันตรวจสอบ Combat
local function inCombat()
    local args = {}
    local status = pcall(function()
        return ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Data"):WaitForChild("GetPotionCDs"):InvokeServer(unpack(args))
    end)
    if status then
        return false -- ไม่อยู่ combat
    else
        return true -- อยู่ combat
    end
end

--// AutoFarm Loop
task.spawn(function()
    while true do
        local items = workspace.SpawnedItems:GetChildren()
        -- จัดเรียงตามระยะทางใกล้ตัว
        table.sort(items, function(a,b)
            if a:FindFirstChild("Handle") and b:FindFirstChild("Handle") then
                return (hrp.Position - a.Handle.Position).Magnitude < (hrp.Position - b.Handle.Position).Magnitude
            else
                return false
            end
        end)

        for _, item in ipairs(items) do
            if item:FindFirstChild("Handle") and not inCombat() then
                local distance = (hrp.Position - item.Handle.Position).Magnitude
                local speed
                if distance < 50 then
                    speed = tweenSpeeds.ใกล้
                elseif distance < 300 then
                    speed = tweenSpeeds.กลาง
                else
                    speed = tweenSpeeds.ไกล
                end
                tweenTo(item.Handle.Position + Vector3.new(0,3,0), speed)
                collectItem(item)
                if #workspace.SpawnedItems:GetChildren() == 0 then
                    -- Hop server ถ้าไม่มีไอเท็ม
                    game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
                end
            end
        end
        task.wait(0.5)
    end
end)
