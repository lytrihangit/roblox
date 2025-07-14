local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local dataService = require(ReplicatedStorage.Modules:WaitForChild("DataService"))

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Backpack = LocalPlayer:WaitForChild("Backpack")

local GameEvents = ReplicatedStorage:WaitForChild("GameEvents")
local BuyGearStock = GameEvents:WaitForChild("BuyGearStock")

local fileName = LocalPlayer.Name .. ".json"

local listGear = {"Levelup Lollipop", "Master Sprinkler", "Godly Sprinkler"}

local function writeData(request, text)
	writefile(fileName, HttpService:JSONEncode({ Request = request, Text = text }))
end

local function isInList(target, list)
	for _, v in ipairs(list) do
		if v == target then return true end
	end
	return false
end

local function getStockGear()
    local stockGear = {}
    local data = dataService:GetData()
    for n, _ in pairs(data.GearStock.Stocks) do
        table.insert(stockGear, n)
    end
    return stockGear
end

local function getInventory()
	local gears = {}
	for _, tool in ipairs(Backpack:GetChildren()) do
        if tool:IsA("Tool") then
            local name = tool.Name
            if not name:find("Shovel") then
                local toolName, qty = name:match("^(.-) x(%d+)$")
                gears[toolName or name] = tonumber(qty) or 1
            end
        end
	end
	return gears
end

task.spawn(function () 
    while true do
        local success = false
        local stock = getStockGear()

        writeData("", HttpService:JSONEncode(stock))

        for _, s in ipairs(listGear) do
            if isInList(s, stock) then
                for _ = 1, 3 do
                    BuyGearStock:FireServer(s)
                end
                success = true
            end
        end

        if success then
            writeData("RunAgain", HttpService:JSONEncode(getInventory()))
            break
        end

        task.wait(15)
    end
end)
