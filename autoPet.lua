repeat wait() until game:IsLoaded()

local config = _G.config

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local HttpService = game:GetService("HttpService")

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Backpack = LocalPlayer:WaitForChild("Backpack")

local GiftPet = ReplicatedStorage:FindFirstChild("GameEvents"):FindFirstChild("GiftPet")
local AcceptPetGift = ReplicatedStorage:FindFirstChild("GameEvents"):FindFirstChild("AcceptPetGift")

local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

local fileName = LocalPlayer.Name .. ".json"

local listPet = {"Hyacinth Macaw", "T-Rex", "Brontosaurus", "Red Fox", "Dragonfly", "Queen Bee", "Mimic Octopus"}

local function writeData(request, text)
	writefile(fileName, HttpService:JSONEncode({ Request = request, Text = text }))
end

local function skipGame()
	local viewportSize = workspace.CurrentCamera.ViewportSize
	local x = viewportSize.X / 2
	local y = viewportSize.Y / 2
	for i = 1, 2 do
		VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 0)
		task.wait(0.1)
		VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0)
		task.wait(0.5)
	end
end

local function isMain(name)
    for _, v in ipairs(config.mainAccount) do
        if v == name then
            return true
        end
    end
    return false
end

local function isInList(target, list)
	for _, v in ipairs(list) do
		if v == target then return true end
	end
	return false
end

local function getPlayers()
    local data = {}
    local playerList = Players:GetPlayers()

    for _, player in ipairs(playerList) do
        if not isMain(player.Name) then
            table.insert(data, player.Name)
        end
    end

    return data
end

local function getRandomPlayer()
    local playerList = getPlayers()

    if #playerList == 0 then return nil end

    local randomIndex = math.random(1, #playerList)
    return playerList[randomIndex]
end

local function isEquidPet()
	for _, item in ipairs(Character:GetChildren()) do
        if item:IsA("Tool") and item:FindFirstChild("PetToolLocal") then
            return true
        end
	end
	return false
end

local function equidPet()
    if isEquidPet() then return true

    local pets = {}
    for _, p in ipairs(Backpack:GetChildren()) do
        local name = p.Name
        local petName, size = name:match("^(.-) %[(%d+%.?%d*) KG%]")
        if petName then
            if isInList(petName, listPet) then
                p.Parent = Character

                return true
            end
        end
    end

    return false
end

local function countPet()
    local pets = {}
    for _, p in ipairs(Backpack:GetChildren()) do
        local name = p.Name
        local petName, size = name:match("^(.-) %[(%d+%.?%d*) KG%]")
        if petName then
            if isInList(petName, listPet) then
                table.insert(pets, petName)
            end
        end
    end

    return #pets
end

local function TeleportToPlayer(playerName)
    local plr = Players:FindFirstChild(playerName)
    if plr and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
        local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local root = char:WaitForChild("HumanoidRootPart")
        root.CFrame = plr.Character.HumanoidRootPart.CFrame + Vector3.new(1, 0, 0)
    end
end

local function acceptGift()
    GiftPet.OnClientEvent:Connect(function(p, ps, pss)
        AcceptPetGift:FireServer(true, p)
    end)
end

task.spawn(function ()
    task.wait(1)
    skipGame()
    task.wait(1)
end)

if isMain(LocalPlayer.Name) then
    task.spawn(function ()
        while true do
            if countPet() > 59 then
                writeData("Completed", "Full slots")
                break
            end

            writeData("", "Receiving...")

            local targetPlayer = getRandomPlayer()
            
            if targetPlayer then
                TeleportToPlayer(targetPlayer)

                task.wait(30)
            end

            task.wait(5)
        end
    end)
    task.spawn(function ()
        acceptGift()
    end)
else
    task.spawn(function () 
        while true do
            if countPet() < 1 then
                writeData("Completed", "Out Of Pets")
                break
            end

            writeData("", "Total : " .. countPet())

            if isEquidPet() then
                for _, other in ipairs(Players:GetPlayers()) do
                    if other ~= LocalPlayer then
                        local char = other.Character
                        if char and char:FindFirstChild("HumanoidRootPart") then
                            local prompt = char.HumanoidRootPart:FindFirstChildWhichIsA("ProximityPrompt", true)
                            if prompt then
                                task.spawn(function ()
                                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                                    task.wait(5)
                                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
                                end)

                                task.wait(3)
                            end
                        end
                    end
                end
            end
            task.wait(3)
        end
    end)
    task.spawn(function () 
        while true do
            local success, err = pcall(function ()
                equidPet()
            end)
            if not success then
                print("err : ", err)
            end
            task.wait(3)
        end
    end)
end
