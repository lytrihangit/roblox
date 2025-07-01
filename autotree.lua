repeat wait() until game:IsLoaded()

local config = _G.config

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Backpack = LocalPlayer:WaitForChild("Backpack")
local Leaderstats = LocalPlayer:WaitForChild("leaderstats")
local Sheckles = Leaderstats:WaitForChild("Sheckles")

local GameEvents = ReplicatedStorage:WaitForChild("GameEvents")
local Sell_Inventory = GameEvents:WaitForChild("Sell_Inventory")

local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")

local fileName = LocalPlayer.Name .. ".json"

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

local function Teleport(pos)
	local root = Character:FindFirstChild("HumanoidRootPart")
	if root then
		Character:SetPrimaryPartCFrame(pos)
	end
end

local function sellInventory()
    local PreviousSheckles = tonumber(Sheckles.Value)

	while wait(5) do
		Teleport(CFrame.new(86, 4, 1))
		Sell_Inventory:FireServer()

        Sheckles = Leaderstats:WaitForChild("Sheckles")
        if PreviousSheckles < tonumber(Sheckles.Value) then
            writeData('Completed', HttpService:JSONEncode({
                Sheckles = tonumber(Sheckles.Value)
            }))
            break
        end
	end
end

local function getGuiByPath(root, path)
	for part in string.gmatch(path, "[^%.]+") do
		if root then
			root = root:FindFirstChild(part)
		else
			return nil
		end
	end
	return root
end

local function isEquidTree()
	for _, item in ipairs(Character:GetChildren()) do
		if item:IsA("Tool") and item:FindFirstChild("Item_Seed") then
			return true
		end
	end
	return false
end

local function equidTree()
    -- if isEquidTree() then return true end

    for _, tool in ipairs(Backpack:GetChildren()) do
        if tool:IsA("Tool") and tool:FindFirstChild("Item_Seed") then
            Humanoid:EquipTool(tool)
            
            return true
        end
    end
    return false
end

local function countTree()
    local Trees = {}
    for _, tool in ipairs(Backpack:GetChildren()) do
        if tool:IsA("Tool") and tool:FindFirstChild("Item_Seed") then
            table.insert(Trees, tool.Name)
        end
    end
    return #Trees
end

local function autoClickButtonByPath(pathString)
	local gui = LocalPlayer:WaitForChild("PlayerGui")
	while task.wait(2) do
        if countTree() > 0 then
            break
        end

		local button = getGuiByPath(gui, pathString)
		if button and button:IsA("GuiButton") and button.Visible then
			local pos = button.AbsolutePosition
			local size = button.AbsoluteSize
			local inset = GuiService:GetGuiInset()
			local x = pos.X + size.X / 2
			local y = pos.Y + size.Y / 2 + inset.Y
			VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 0)
			task.wait(0.5)
			VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0)
		end
	end
end

task.spawn(function ()
    task.wait(1)
    skipGame()
    task.wait(1)
end)

if LocalPlayer.Name == config.mainAccount then
    task.spawn(function ()
        while task.wait(1) do
            local success, err = pcall(function ()
                equidTree()
            end)
            if not success then
                print("err : ", err)
                break
            end
        end
    end)

    task.spawn(function ()
        while task.wait(3) do
            if countTree() < 1 then
                writeData('Completed', 'Out Of Trees')
                break
            end

            writeData('', 'Sending...')

            if isEquidTree() then
                for _, other in ipairs(Players:GetPlayers()) do
					if other ~= LocalPlayer then
						local char = other.Character
						if char and char:FindFirstChild("HumanoidRootPart") then
							local prompt = char.HumanoidRootPart:FindFirstChildWhichIsA("ProximityPrompt", true)
							if prompt then
                                task.spawn(function ()
                                    prompt:InputHoldBegin()
                                    task.wait(6)
                                    prompt:InputHoldEnd()
                                end)

                                task.wait(3)
							end
						end
					end
				end
            end
        end
    end)
else
    task.spawn(function ()
        while task.wait(3) do
            writeData('', 'Waiting Tree')

			local mainPlr = Players:FindFirstChild(config.mainAccount)
			if mainPlr and mainPlr.Character and mainPlr.Character:FindFirstChild("HumanoidRootPart") then
				local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
				local root = char:WaitForChild("HumanoidRootPart")
				root.CFrame = mainPlr.Character.HumanoidRootPart.CFrame + Vector3.new(1, 0, 0)

                autoClickButtonByPath("Gift_Notification.Frame.Gift_Notification.Holder.Frame.Accept")

                task.wait(3)

                sellInventory()
                
                break
			end
		end
    end)
end
