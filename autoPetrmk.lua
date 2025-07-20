repeat wait() until game:IsLoaded()

local config = _G.config

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local HttpService = game:GetService("HttpService")

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Backpack = LocalPlayer:WaitForChild("Backpack")

local GameEvents = ReplicatedStorage:WaitForChild("GameEvents")
local GiftPet = GameEvents:WaitForChild("GiftPet")
local AcceptPetGift = GameEvents:WaitForChild("AcceptPetGift")
local PetsService = GameEvents:WaitForChild("PetsService")
local PetGiftingService = GameEvents:WaitForChild("PetGiftingService")

local dataService = require(ReplicatedStorage.Modules:WaitForChild("DataService"))

local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

local fileName = LocalPlayer.Name .. ".json"

local listPet = {"Capybara", "T-Rex", "Brontosaurus", "Red Fox", "Dragonfly", "Queen Bee", "Mimic Octopus"}

local function writeData(request, text)
	writefile(fileName, HttpService:JSONEncode({ Request = request, Text = text }))
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

local function collectPet()
    local data = dataService:GetData()

    for _, p in pairs(data.PetsData.EquippedPets) do
        PetsService:FireServer("UnequipPet", p)
    end
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
    if isEquidPet() then return true end

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
    local data = dataService:GetData()
    
    for _, p in pairs(data.PetsData.PetInventory.Data) do
        local petType = p.PetType
        if isInList(petType, listPet) then
            table.insert(pets, petType)
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

if isMain(LocalPlayer.Name) then
    task.spawn(function () 
        acceptGift()
    end)
    task.spawn(function ()
        while true do
            if countPet() > 59 then
                writeData("Completed", "Full slots")
                break
            end

            writeData("", "Receiving...")
            
            task.wait(3)
        end
    end)
else
    task.spawn(function () 
        while true do
            collectPet()

            if countPet() < 1 then
                writeData("Completed", "Out Of Pets")
                break
            end
				
            writeData("", "Total : " .. countPet())

            if isEquidPet() then
                for _, v in ipairs(config.mainAccount) do
                    PetGiftingService:FireServer("GivePet", Players:WaitForChild(v))
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
                writeData("", err)
            end
            task.wait(3)
        end
    end)
end
