repeat wait() until game:IsLoaded()

local config = _G.config
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Backpack = LocalPlayer:WaitForChild("Backpack")
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local SellPet_RE = ReplicatedStorage.GameEvents.SellPet_RE

local function Teleport(pos)
	local root = Character:FindFirstChild("HumanoidRootPart")
	if root then
		Character:SetPrimaryPartCFrame(pos)
	end
end

local function isInList(target, list)
	for _, v in ipairs(list) do
		if v == target then return true end
	end
	return false
end

local function sellPet()
    Teleport(CFrame.new(86, 4, 1))
    task.wait(5)
    for _, p in ipairs(Backpack:GetChildren()) do
        local name = p.Name
        local petName, size = name:match("^(.-) %[(%d+%.?%d*) KG%]")

        if petName and size then
            if not isInList(petName, config["Pet Dont Delete"]) and tonumber(size) < config["Size Dont Delete"] then
                p.Parent = Character
                SellPet_RE:FireServer(Character:FindFirstChild(name))
                task.wait(0.5)
            end
        end
    end
end

task.spawn(function ()
    while true do
        sellPet()
        task.wait(1800)
    end
end)
