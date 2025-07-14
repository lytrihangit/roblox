local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local dataService = require(ReplicatedStorage.Modules:WaitForChild("DataService"))

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Backpack = LocalPlayer:WaitForChild("Backpack")

local GameEvents = ReplicatedStorage:WaitForChild("GameEvents")
local BuyGearStock = GameEvents:WaitForChild("BuyGearStock")

local fileName = LocalPlayer.Name .. ".json"

local listGear = {"Levelup Lollipop"}

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

    for n, v in pairs(data.GearStock.Stocks) do
        stockGear[n] = v.Stock
    end

    return stockGear
end

local function getInventory()
	local gears = {}

	for _, tool in ipairs(Backpack:GetChildren()) do
		local name = tool.Name
        local toolName, qty = name:match("^(.-) x(%d+)$")
        gears[toolName or name] = tonumber(qty) or 1
	end

	return gears
end

task.spawn(function () 
    while true do
        writeData("", HttpService:JSONEncode(getInventory()))

        local success = false
        local stock = getStockGear()

        for gName, gCount in pairs(stock) do
            local gCount = tonumber(gCount)

            if isInList(gName, listGear) and gCount > 0 then
                if gCount > 1 then
                    for _ = 1, gCount do
                        BuyGearStock:FireServer(gName)
                    end
                end
                success = true
            end
        end

        if success then
            writeData("RunAgain", HttpService:JSONEncode(getInventory()))
            break
        end

        task.wait(5)
    end
end)
