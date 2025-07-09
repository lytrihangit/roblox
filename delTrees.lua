local HttpService = game:GetService("HttpService")
local plants = workspace.Farm.Farm.Important.Plants_Physical
local LocalPlayer = game:GetService("Players").LocalPlayer
local Backpack = LocalPlayer:WaitForChild("Backpack")
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

local fileName = LocalPlayer.Name .. ".json"

local function writeData(request, text)
	writefile(fileName, HttpService:JSONEncode({ Request = request, Text = text }))
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

local function equidShovel()
    for _, tool in ipairs(Backpack:GetChildren()) do
		local name = tool.Name
		if name:find("Shovel") then
            tool.Parent = Character
            
            return true
		end
	end
    return false
end

local function delTrees()
    if not equidShovel() then
        equidShovel()
    end
    
    local farm = getFarm()
    local objects = farm.Important.Plants_Physical:GetChildren()

    if #objects < 1 then
        writeData("Completed", "Trees : " .. #objects)
        return true
    end

    for _, obj in ipairs(objects) do
        for _, j in ipairs(obj:GetChildren()) do
            local cln = j.ClassName
            if cln == "Part" or cln == "MeshPart" then
                game:GetService("ReplicatedStorage"):WaitForChild("GameEvents"):WaitForChild("Remove_Item"):FireServer(j)
            end
        end
    end

    return true
end

task.spawn(function () 
    local success, err = pcall(function () 
        writeData("", "Deleting...")

        task.wait(0.5)

        delTrees()

        task.wait(0.5)

        writeData("Completed", "Deleted!")
    end)

    if not success then
        writeData("", err)
    end
end)
