repeat wait() until game:IsLoaded()

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local GameEvents = ReplicatedStorage:WaitForChild("GameEvents")
local BuyPetEgg = GameEvents:WaitForChild("BuyPetEgg")
local Sell_Inventory = GameEvents:WaitForChild("Sell_Inventory")
local PetEggService = GameEvents:WaitForChild("PetEggService")
local DinoMachineService = GameEvents:WaitForChild("DinoMachineService_RE")

local DataStream = GameEvents:WaitForChild("DataStream")

local EggLocations = workspace:WaitForChild("NPCS"):WaitForChild("Pet Stand"):WaitForChild("EggLocations")

local LocalPlayer = Players.LocalPlayer
local Backpack = LocalPlayer:WaitForChild("Backpack")
local Leaderstats = LocalPlayer:WaitForChild("leaderstats")
local Sheckles = Leaderstats:WaitForChild("Sheckles")
local fileName = LocalPlayer.Name .. ".json"

local dataService = require(ReplicatedStorage.Modules:WaitForChild("DataService"))

local listEggs = {"Dinosaur Egg", "Bug Egg", "Paradise Egg", "Mythical Egg", "Bee Egg"}
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

local function sellInventory()
    local PreviousSheckles = tonumber(Sheckles.Value)
    if PreviousSheckles > 10000 then
        return true
    end
    
	while wait(10) do
		Teleport(CFrame.new(86, 4, 1))
		Sell_Inventory:FireServer()

        if PreviousSheckles < tonumber(Sheckles.Value) then
            return true
        end
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
    local eggLines = {}
	for _, egg in ipairs(EggLocations:GetChildren()) do
		if egg:IsA("Model") then
            table.insert(eggLines, egg.Name)
		end
	end
    return eggLines
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

    -- hatch all pet time hatch = 0
    if #obj > 0 then
        for _, egg in ipairs(obj) do
            if egg:GetAttribute("OBJECT_TYPE") == "PetEgg" and egg:GetAttribute("TimeToHatch") == 0 then
                PetEggService:FireServer("HatchPet", egg)
            end
            task.wait(0.5)
        end
    end

    task.wait(0.5)

    -- plant all egg in list from inventory
	local locations = farm.Important:FindFirstChild("Plant_Locations")
    for _, name in ipairs(listEggs) do
        for _, tool in ipairs(Backpack:GetChildren()) do
            if tool.Name:find(name) then
                tool.Parent = getCharacter()

                task.wait(0.5)

                for _ = 1, 3 do
                    PetEggService:FireServer("CreateEgg", getRandomFarmPoint(locations))
                end
            end
        end
    end
end

local function dinoMachine()
    for _, p in ipairs(Backpack:GetChildren()) do
        local name = p.Name
        local petName, size = name:match("^(.-) %[(%d+%.?%d*) KG%]")

        if petName and size then
            if not isInList(petName, listPet) and tonumber(size) < 10 then
                p.Parent = Character
                
                DinoMachineService:FireServer("MachineInteract")

                task.wait(0.5)

                return true
            end
        end
    end
end

local function claimMachine()
    DataStream.OnClientEvent:Connect(function(action, profile, data)
        if action == "UpdateData" then
            for _, entry in ipairs(data) do
                local path, value = unpack(entry)
                if path == "ROOT/DinoMachine/TimeLeft" then
                    if tonumber(value) == 0 then
                        DinoMachineService:FireServer("ClaimReward")

                        return true
                    end
                end
            end
        end
        task.wait(60)
    end)
end

local function main()
    while wait(15) do
        writeData("", "Wait Stock")

        hatchPets()

        dinoMachine()
        
        local stock = getStock()

        for _, eggName in ipairs(stock) do
            if isInList(eggName, listEggs) then

                writeData("", "Buying : " .. eggName)

                for i = 1, 3 do 
                    BuyPetEgg:FireServer(i)
                end

                return true
            end
        end
    end
end

task.spawn(function ()
    local success, err = pcall(function ()
        main()
        task.wait(0.5)

        writeData("RunAgain", HttpService:JSONEncode(getEggs()))
    end)

    if not success then
        print("Error : " .. err)
        writeData("", err)
    end
end)

task.spawn(function ()
    local success, err = pcall(function ()
        claimMachine()
    end)

    if not success then
        print("Error : " .. err)
        writeData("", err)
    end
end)
