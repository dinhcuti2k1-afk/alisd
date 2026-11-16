--[[
	Script Name: UnifiedAdminUtility.lua
	Location: 
		- Place the server logic part inside a Script in ServerScriptService.
		- Place the client UI & controller logic inside a LocalScript in StarterPlayer -> StarterPlayerScripts.
]]

-- ============================================================================
-- PART 1: SERVER SCRIPT (Put in ServerScriptService)
-- ============================================================================
if game:GetService("RunService"):IsServer() then
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Workspace = game:GetService("Workspace")

	local cageEvent = ReplicatedStorage:FindFirstChild("CagePlayerEvent")
	if not cageEvent then
		cageEvent = Instance.new("RemoteEvent")
		cageEvent.Name = "CagePlayerEvent"
		cageEvent.Parent = ReplicatedStorage
	end

	local AUTHORIZED_ADMINS = {
		[-1] = true, -- Studio local test
	}

	local activeCages = {}

	local function findPlayerByName(partialName)
		if type(partialName) ~= "string" or #partialName == 0 then return nil end
		local lowerQuery = string.lower(partialName)
		for _, plr in ipairs(Players:GetPlayers()) do
			if string.sub(string.lower(plr.Name), 1, #lowerQuery) == lowerQuery or
			   string.sub(string.lower(plr.DisplayName), 1, #lowerQuery) == lowerQuery then
				return plr
			end
		end
		return nil
	end

	local function buildIronCage(centerCFrame, ownerName)
		local cageModel = Instance.new("Model")
		cageModel.Name = ownerName .. "_IronCage"

		local size = 8
		local barThickness = 0.4
		local height = 9
		local barSpacing = 1.6

		local function createPart(partSize, offsetCFrame)
			local p = Instance.new("Part")
			p.Size = partSize
			p.CFrame = centerCFrame * offsetCFrame
			p.Anchored = true
			p.CanCollide = true
			p.Material = Enum.Material.CorrodedMetal
			p.Color = Color3.fromRGB(70, 75, 80)
			p.TopSurface = Enum.SurfaceType.Smooth
			p.BottomSurface = Enum.SurfaceType.Smooth
			p.Parent = cageModel
			return p
		end

		createPart(Vector3.new(size, barThickness, size), CFrame.new(0, -height / 2, 0))
		createPart(Vector3.new(size, barThickness, size), CFrame.new(0, height / 2, 0))

		local halfSize = (size / 2) - (barThickness / 2)
		for offset = -halfSize, halfSize, barSpacing do
			createPart(Vector3.new(barThickness, height, barThickness), CFrame.new(offset, 0, halfSize))
			createPart(Vector3.new(barThickness, height, barThickness), CFrame.new(offset, 0, -halfSize))
			createPart(Vector3.new(barThickness, height, barThickness), CFrame.new(halfSize, 0, offset))
			createPart(Vector3.new(barThickness, height, barThickness), CFrame.new(-halfSize, 0, offset))
		end

		cageModel.Parent = Workspace
		return cageModel
	end

	cageEvent.OnServerEvent:Connect(function(requestingPlayer, targetName)
		if not AUTHORIZED_ADMINS[requestingPlayer.UserId] then
			warn("[MrDon Security] Unauthorized cage attempt by:", requestingPlayer.Name)
			return
		end

		local targetPlayer = findPlayerByName(targetName)
		if not targetPlayer then return end

		if activeCages[targetPlayer.UserId] then
			activeCages[targetPlayer.UserId]:Destroy()
			activeCages[targetPlayer.UserId] = nil
			return
		end

		local character = targetPlayer.Character
		local hrp = character and character:FindFirstChild("HumanoidRootPart")
		if hrp then
			local spawnCFrame = hrp.CFrame
			local cage = buildIronCage(spawnCFrame, targetPlayer.Name)
			activeCages[targetPlayer.UserId] = cage
			hrp.CFrame = spawnCFrame
		end
	end)

	Players.PlayerRemoving:Connect(function(plr)
		if activeCages[plr.UserId] then
			activeCages[plr.UserId]:Destroy()
			activeCages[plr.UserId] = nil
		end
	end)

-- ============================================================================
-- PART 2: CLIENT CONTROLLER (Put in StarterPlayerScripts as a LocalScript)
-- ============================================================================
else
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local UserInputService = game:GetService("UserInputService")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Workspace = game:GetService("Workspace")

	local player = Players.LocalPlayer
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
	local cageEvent = ReplicatedStorage:WaitForChild("CagePlayerEvent")

	-- States
	local flying = false
	local noclip = false
	local speed = 50
	local bg, bv

	-- Lag Reduction
	local function applyLagReduction()
		for _, descendant in ipairs(Workspace:GetDescendants()) do
			if descendant:IsA("BasePart") then
				descendant.CastShadow = false
				descendant.Material = Enum.Material.SmoothPlastic
			elseif descendant:IsA("ParticleEmitter") or descendant:IsA("Trail") or descendant:IsA("Fire") or descendant:IsA("Smoke") then
				descendant.Enabled = false
			end
		end
		UserSettings():GetService("UserGameSettings").SavedQualityLevel = Enum.SavedQualitySetting.Level1
	end

	-- Flight Toggle
	local function toggleFlight(active)
		flying = active
		if flying then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid then humanoid.PlatformStand = true end
			
			bg = Instance.new("BodyGyro")
			bg.MaxTorque = Vector3.new(400000, 400000, 400000)
			bg.P = 20000
			bg.Parent = humanoidRootPart
			
			bv = Instance.new("BodyVelocity")
			bv.MaxForce = Vector3.new(400000, 400000, 400000)
			bv.Velocity = Vector3.new(0, 0, 0)
			bv.Parent = humanoidRootPart
			
			task.spawn(function()
				while flying and character and humanoidRootPart do
					local camera = Workspace.CurrentCamera
					local moveDirection = Vector3.new()
					
					if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDirection = moveDirection + camera.CFrame.LookVector end
					if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDirection = moveDirection - camera.CFrame.LookVector end
					if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDirection = moveDirection - camera.CFrame.RightVector end
					if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDirection = moveDirection + camera.CFrame.RightVector end
					
					bv.Velocity = moveDirection * speed
					bg.CFrame = camera.CFrame
					RunService.RenderStepped:Wait()
				end
			end)
		else
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid then humanoid.PlatformStand = false end
			if bg then bg:Destroy() end
			if bv then bv:Destroy() end
		end
	end

	-- Noclip Loop
	RunService.Stepped:Connect(function()
		if noclip and character then
			for _, part in ipairs(character:GetDescendants()) do
				if part:IsA("BasePart") then part.CanCollide = false end
			end
		end
	end)

	-- GUI Setup
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "UnifiedAdminGui"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = player:WaitForChild("PlayerGui")

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 220, 0, 115)
	frame.Position = UDim2.new(0, 20, 0.5, -60)
	frame.BackgroundColor3 = Color3.fromRGB(30, 32, 36)
	frame.BorderSizePixel = 0
	frame.Parent = screenGui

	local textBox = Instance.new("TextBox")
	textBox.Size = UDim2.new(1, -20, 0, 30)
	textBox.Position = UDim2.new(0, 10, 0, 10)
	textBox.PlaceholderText = "Target Player Name..."
	textBox.Text = ""
	textBox.BackgroundColor3 = Color3.fromRGB(45, 48, 54)
	textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	textBox.Font = Enum.Font.SourceSans
	textBox.TextSize = 16
	textBox.Parent = frame

	local actionBtn = Instance.new("TextButton")
	actionBtn.Size = UDim2.new(1, -20, 0, 28)
	actionBtn.Position = UDim2.new(0, 10, 0, 48)
	actionBtn.Text = "Toggle Iron Cage"
	actionBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
	actionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	actionBtn.Font = Enum.Font.SourceSansBold
	actionBtn.TextSize = 15
	actionBtn.Parent = frame

	actionBtn.MouseButton1Click:Connect(function()
		if textBox.Text ~= "" then
			cageEvent:FireServer(textBox.Text)
		end
	end)

	local infoLabel = Instance.new("TextLabel")
	infoLabel.Size = UDim2.new(1, -20, 0, 24)
	infoLabel.Position = UDim2.new(0, 10, 0, 82)
	infoLabel.Text = "[F] Fly | [N] Noclip | [L] Lag Fix"
	infoLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	infoLabel.BackgroundTransparency = 1
	infoLabel.Font = Enum.Font.SourceSans
	infoLabel.TextSize = 13
	infoLabel.Parent = frame

	-- Keybindings
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.KeyCode == Enum.KeyCode.F then
			toggleFlight(not flying)
		elseif input.KeyCode == Enum.KeyCode.N then
			noclip = not noclip
		elseif input.KeyCode == Enum.KeyCode.L then
			applyLagReduction()
		end
	end)
end