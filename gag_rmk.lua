repeat wait() until game:IsLoaded()

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local VirtualUser = game:GetService('VirtualUser')

local GameEvents = ReplicatedStorage:WaitForChild("GameEvents")
local BuyPetEgg = GameEvents:WaitForChild("BuyPetEgg")
local Sell_Inventory = GameEvents:WaitForChild("Sell_Inventory")
local PetEggService = GameEvents:WaitForChild("PetEggService")

local DataStream = GameEvents:WaitForChild("DataStream")

local LocalPlayer = Players.LocalPlayer
local Backpack = LocalPlayer:WaitForChild("Backpack")
local Leaderstats = LocalPlayer:WaitForChild("leaderstats")
local Sheckles = Leaderstats:WaitForChild("Sheckles")
local fileName = LocalPlayer.Name .. ".json"

local dataService = require(ReplicatedStorage.Modules:WaitForChild("DataService"))

local listEggs = {"Bug Egg", "Paradise Egg", "Mythical Egg"}
local listPet = {"T-Rex", "Brontosaurus", "Red Fox", "Dragonfly", "Queen Bee", "Mimic Octopus"}

local function writeData(request, text)
	writefile(fileName, HttpService:JSONEncode({ Request = request, Text = text }))
end

local function getCharacter()
	return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

local function Teleport(pos)
	local root = getCharacter():FindFirstChild("HumanoidRootPart")
	if root then
		getCharacter():SetPrimaryPartCFrame(pos)
	end
end

local function getEggs()
	local eggs = {}

	for _, tool in ipairs(Backpack:GetChildren()) do
		local name = tool.Name
		if name:find("Egg") then
			local eggName, qty = name:match("^(.-) x(%d+)$")
			eggs[eggName or name] = tonumber(qty) or 1
		end
	end

	return eggs
end

local function getFarm()
	local Farms = workspace:WaitForChild("Farm"):GetChildren()

	for _, Farm in ipairs(Farms) do
		local Important = Farm:FindFirstChild("Important")
		local Data = Important:FindFirstChild("Data")
		local Owner = Data:FindFirstChild("Owner").Value

		if Owner == LocalPlayer.Name then
			return Farm
		end
	end
end

local function getRandomFarmPoint(locations)
	local plots = locations:GetChildren()
	if #plots == 0 then return Vector3.new(0, 4, 0) end

	local plot = plots[math.random(#plots)]
	local pivot, size = plot:GetPivot(), plot.Size
	local x = math.random(math.ceil(pivot.X - size.X / 2), math.floor(pivot.X + size.X / 2))
	local z = math.random(math.ceil(pivot.Z - size.Z / 2), math.floor(pivot.Z + size.Z / 2))

	return Vector3.new(x, 4, z)
end

local function getStock()
    local eggStock = {}
    local data = dataService:GetData()

    for _, v in pairs(data.PetEggStock.Stocks) do
        table.insert(eggStock, v.EggName)
    end

    return eggStock
end

local function isInList(target, list)
	for _, v in ipairs(list) do
		if v == target then return true end
	end
	return false
end

local function getEggFarms()
    local farm = getFarm()
    local objects = farm.Important.Objects_Physical:GetChildren()

    return farm, objects
end

local function hatchPets()
    local farm, obj = getEggFarms()

    if #obj > 0 then
        for _, egg in ipairs(obj) do
            if egg:GetAttribute("OBJECT_TYPE") == "PetEgg" and egg:GetAttribute("TimeToHatch") == 0 then
                PetEggService:FireServer("HatchPet", egg)
            end
            task.wait(0.5)
        end
    end

    task.wait(0.5)

	local locations = farm.Important:FindFirstChild("Plant_Locations")
    for _, name in ipairs(listEggs) do
        for _, tool in ipairs(Backpack:GetChildren()) do
            if tool.Name:find(name) then
                tool.Parent = getCharacter()

                task.wait(0.5)

                for _ = 1, 8 do
                    PetEggService:FireServer("CreateEgg", getRandomFarmPoint(locations))
                end
            end
        end
    end
end

local function main()
    while true do
        local success = false

        writeData("", "Wait Stock")

        hatchPets()
        
        local stock = getStock()

        for _, eggName in ipairs(stock) do
            if isInList(eggName, listEggs) then
                BuyPetEgg:FireServer(eggName)

                success = true
            end
        end

        hatchPets()
    
        if success then
            writeData("RunAgain", HttpService:JSONEncode(getEggs()))
            break
        end
		
        task.wait(10)
    end
end
task.spawn(function () 
    LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end)

task.spawn(function ()
    local success, err = pcall(function ()
        main()
    end)

    if not success then
        print("Error : " .. err)
        writeData("", err)
    end
end)
