-- ============================================================================
-- SCRIPT TỔNG HỢP: MADILA.LUA (VOLCANO EXECUTOR CLIENT-SIDE READY)
-- ============================================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local Camera = Workspace.CurrentCamera

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- Trạng thái tính năng
local flying = false
local noclip = false
local espEnabled = false
local volcanoActive = false
local eclipseActive = false
local speed = 50
local bg, bv
local espObjects = {}

-- 1. Sự kiện Núi Lửa (Volcano Eruption Effect)
local function toggleVolcano(active)
	volcanoActive = active
	if volcanoActive then
		print("[MrDon] Sự kiện Núi Lửa đã bắt đầu!")
		task.spawn(function()
			while volcanoActive do
				-- Rung lắc camera nhẹ
				Camera.CFrame = Camera.CFrame * CFrame.new(
					math.random(-50, 50)/100, 
					math.random(-50, 50)/100, 
					math.random(-50, 50)/100
				)
				
				-- Tạo thiên thạch/hạt lửa rơi xung quanh nhân vật
				if character and humanoidRootPart then
					local part = Instance.new("Part")
					part.Size = Vector3.new(1.5, 1.5, 1.5)
					part.Shape = Enum.PartType.Ball
					part.BrickColor = BrickColor.new("Bright red")
					part.Material = Enum.Material.Neon
					part.Position = humanoidRootPart.Position + Vector3.new(math.random(-40, 40), 50, math.random(-40, 40))
					part.Velocity = Vector3.new(0, -60, 0)
					part.CanCollide = false
					part.Parent = Workspace
					
					task.delay(3, function()
						if part then part:Destroy() end
					end)
				end
				task.wait(0.15)
			end
		end)
	else
		print("[MrDon] Đã tắt sự kiện Núi Lửa.")
	end
end

-- 2. Sự kiện Nhật Thực (Solar Eclipse Effect)
local originalClockTime = Lighting.ClockTime
local originalBrightness = Lighting.Brightness

local function toggleEclipse(active)
	eclipseActive = active
	if eclipseActive then
		print("[MrDon] Sự kiện Nhật Thực bắt đầu!")
		Lighting.ClockTime = 0
		Lighting.Brightness = 0.1
		Lighting.Ambient = Color3.fromRGB(20, 20, 30)
		Lighting.OutdoorAmbient = Color3.fromRGB(10, 10, 20)
	else
		print("[MrDon] Khôi phục lại ánh sáng ban đầu.")
		Lighting.ClockTime = originalClockTime
		Lighting.Brightness = originalBrightness
		Lighting.Ambient = Color3.fromRGB(128, 128, 128)
		Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
	end
end

-- 3. Tính năng Định vị (ESP) Player và Bot
local function toggleESP(active)
	espEnabled = active
	if not espEnabled then
		for _, billboard in pairs(espObjects) do
			if billboard then billboard:Destroy() end
		end
		espObjects = {}
	end
end

RunService.RenderStepped:Connect(function()
	if not espEnabled then return end
	
	for _, obj in ipairs(Workspace:GetChildren()) do
		if obj:IsA("Model") and obj:FindFirstChild("HumanoidRootPart") and obj:FindFirstChild("Humanoid") then
			if obj ~= player.Character then
				local hrp = obj.HumanoidRootPart
				if not hrp:FindFirstChild("EspTag") then
					local billboard = Instance.new("BillboardGui")
					billboard.Name = "EspTag"
					billboard.Size = UDim2.new(0, 100, 0, 40)
					billboard.StudsOffset = Vector3.new(0, 3, 0)
					billboard.AlwaysOnTop = true
					billboard.Parent = hrp
					
					local textLabel = Instance.new("TextLabel")
					textLabel.Size = UDim2.new(1, 0, 1, 0)
					textLabel.BackgroundTransparency = 1
					textLabel.Text = obj.Name
					textLabel.TextColor3 = Color3.fromRGB(255, 100, 0)
					textLabel.TextScaled = true
					textLabel.Font = Enum.Font.SourceSansBold
					textLabel.Parent = billboard
					
					espObjects[obj] = billboard
				end
			end
		end
	end
end)

-- 4. Tính năng Bay (Fly)
local function toggleFlight(active)
	flying = active
	local hum = character:FindFirstChildOfClass("Humanoid")
	if flying then
		if hum then hum.PlatformStand = true end
		bg = Instance.new("BodyGyro", humanoidRootPart)
		bg.MaxTorque = Vector3.new(400000, 400000, 400000)
		bg.P = 20000
		
		bv = Instance.new("BodyVelocity", humanoidRootPart)
		bv.MaxForce = Vector3.new(400000, 400000, 400000)
		bv.Velocity = Vector3.new(0, 0, 0)
		
		task.spawn(function()
			while flying and character and humanoidRootPart do
				local moveDir = Vector3.new()
				if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Camera.CFrame.LookVector end
				if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - Camera.CFrame.LookVector end
				if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - Camera.CFrame.RightVector end
				if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Camera.CFrame.RightVector end
				bv.Velocity = moveDir * speed
				bg.CFrame = Camera.CFrame
				RunService.RenderStepped:Wait()
			end
		end)
	else
		if hum then hum.PlatformStand = false end
		if bg then bg:Destroy() end
		if bv then bv:Destroy() end
	end
end

-- 5. Xuyên tường (Noclip)
RunService.Stepped:Connect(function()
	if noclip and character then
		for _, p in ipairs(character:GetDescendants()) do
			if p:IsA("BasePart") then p.CanCollide = false end
		end
	end
end)

-- 6. Giao diện điều khiển (UI) - Đặt góc trái gọn gàng
if player.PlayerGui:FindFirstChild("MadilaAdminGui") then
	player.PlayerGui.MadilaAdminGui:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MadilaAdminGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 240, 0, 260)
frame.Position = UDim2.new(0, 20, 0.4, 0) -- Đẩy xuống giữa màn hình tránh bị che nút game
frame.BackgroundColor3 = Color3.fromRGB(30, 32, 36)
frame.BorderSizePixel = 0
frame.Parent = screenGui

Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 25)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "--- MRDON ADMIN PANEL ---"
titleLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextSize = 13
titleLabel.Parent = frame

-- Tạo nút bấm hàng loạt
local function createButton(name, posY, color, callback)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -20, 0, 28)
	btn.Position = UDim2.new(0, 10, 0, posY)
	btn.Text = name
	btn.BackgroundColor3 = color
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Font = Enum.Font.SourceSansBold
	btn.TextSize = 14
	btn.Parent = frame
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
	
	btn.MouseButton1Click:Connect(callback)
	return btn
end

-- Khởi tạo các nút trên UI
local volcanoBtn = createButton("Bật/Tắt Sự Kiện Núi Lửa", 30, Color3.fromRGB(180, 60, 60), function()
	toggleVolcano(not volcanoActive)
	volcanoBtn.BackgroundColor3 = volcanoActive and Color3.fromRGB(60, 180, 90) or Color3.fromRGB(180, 60, 60)
end)

local eclipseBtn = createButton("Bật/Tắt Sự Kiện Nhật Thực", 66, Color3.fromRGB(80, 60, 140), function()
	toggleEclipse(not eclipseActive)
	eclipseBtn.BackgroundColor3 = eclipseActive and Color3.fromRGB(60, 180, 90) or Color3.fromRGB(80, 60, 140)
end)

local espBtn = createButton("Bật/Tắt Định Vị (ESP Bot/Player)", 102, Color3.fromRGB(60, 140, 180), function()
	toggleESP(not espEnabled)
	espBtn.BackgroundColor3 = espEnabled and Color3.fromRGB(60, 180, 90) or Color3.fromRGB(60, 140, 180)
end)

local flyBtn = createButton("Bật/Tắt Bay (Fly)", 138, Color3.fromRGB(60, 120, 180), function()
	toggleFlight(not flying)
	flyBtn.BackgroundColor3 = flying and Color3.fromRGB(60, 180, 90) or Color3.fromRGB(60, 120, 180)
end)

local noclipBtn = createButton("Bật/Tắt Xuyên Tường", 174, Color3.fromRGB(120, 60, 180), function()
	noclip = not noclip
	noclipBtn.BackgroundColor3 = noclip and Color3.fromRGB(60, 180, 90) or Color3.fromRGB(120, 60, 180)
end)

createButton("Giảm Lag (Lag Fix)", 210, Color3.fromRGB(180, 140, 60), function()
	for _, desc in ipairs(Workspace:GetDescendants()) do
		if desc:IsA("BasePart") then desc.CastShadow = false end
	end
	print("[MrDon] Đã giảm lag thành công.")
end)

print("[MrDon] Code tổng hợp Madila.lua đã khởi chạy hoàn tất trên Volcano!")
