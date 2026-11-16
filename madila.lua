-- ============================================================================
-- SCRIPT CHẠY QUA LOADSTRING (Đã tối ưu hóa cho Client Executor)
-- ============================================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- Đảm bảo có RemoteEvent trên ReplicatedStorage để tương thích
local cageEvent = ReplicatedStorage:FindFirstChild("CagePlayerEvent")
if not cageEvent then
	cageEvent = Instance.new("RemoteEvent")
	cageEvent.Name = "CagePlayerEvent"
	cageEvent.Parent = ReplicatedStorage
end

-- States
local flying = false
local noclip = false
local speed = 50
local bg, bv

-- 1. Lag Reduction (Giảm lag)
local function applyLagReduction()
	for _, descendant in ipairs(Workspace:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.CastShadow = false
			descendant.Material = Enum.Material.SmoothPlastic
		elseif descendant:IsA("ParticleEmitter") or descendant:IsA("Trail") or descendant:IsA("Fire") or descendant:IsA("Smoke") then
			descendant.Enabled = false
		end
	end
	pcall(function()
		UserSettings():GetService("UserGameSettings").SavedQualityLevel = Enum.SavedQualitySetting.Level1
	end)
	print("[MrDon] Đã giảm lag thành công.")
end

-- 2. Flight Toggle (Bay)
local function toggleFlight(active)
	flying = active
	local hum = character:FindFirstChildOfClass("Humanoid")
	if flying then
		if hum then hum.PlatformStand = true end
		
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
		if hum then hum.PlatformStand = false end
		if bg then bg:Destroy() end
		if bv then bv:Destroy() end
	end
end

-- 3. Noclip Loop (Xuyên tường)
RunService.Stepped:Connect(function()
	if noclip and character then
		for _, part in ipairs(character:GetDescendants()) do
			if part:IsA("BasePart") then part.CanCollide = false end
		end
	end
end)

-- 4. GUI Setup (Tạo giao diện hiển thị trên màn hình)
-- Xóa GUI cũ nếu lỡ chạy nhiều lần
if player.PlayerGui:FindFirstChild("UnifiedAdminGui") then
	player.PlayerGui.UnifiedAdminGui:Destroy()
end

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

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = frame

local textBox = Instance.new("TextBox")
textBox.Size = UDim2.new(1, -20, 0, 30)
textBox.Position = UDim2.new(0, 10, 0, 10)
textBox.PlaceholderText = "Tên người chơi..."
textBox.Text = ""
textBox.BackgroundColor3 = Color3.fromRGB(45, 48, 54)
textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
textBox.Font = Enum.Font.SourceSans
textBox.TextSize = 16
textBox.Parent = frame

local tBoxCorner = Instance.new("UICorner")
tBoxCorner.CornerRadius = UDim.new(0, 6)
tBoxCorner.Parent = textBox

local actionBtn = Instance.new("TextButton")
actionBtn.Size = UDim2.new(1, -20, 0, 28)
actionBtn.Position = UDim2.new(0, 10, 0, 48)
actionBtn.Text = "Nhốt Lồng Sắt"
actionBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
actionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
actionBtn.Font = Enum.Font.SourceSansBold
actionBtn.TextSize = 15
actionBtn.Parent = frame

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 6)
btnCorner.Parent = actionBtn

actionBtn.MouseButton1Click:Connect(function()
	if textBox.Text ~= "" then
		cageEvent:FireServer(textBox.Text)
	end
end)

local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(1, -20, 0, 24)
infoLabel.Position = UDim2.new(0, 10, 0, 82)
infoLabel.Text = "[F] Bay | [N] Xuyên Tường | [L] Giảm Lag"
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
		print("[MrDon] Noclip:", noclip)
	elseif input.KeyCode == Enum.KeyCode.L then
        applyLagReduction()
	end
end)

print("[MrDon] Giao diện Admin Utility đã được khởi tạo thành công!")
