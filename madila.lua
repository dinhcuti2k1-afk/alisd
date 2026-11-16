-- ============================================================================
-- SCRIPT MADILA.LUA - SỰ KIỆN NÚI LỬA & NHẬT THỰC (CLIENT-SIDE) + ESP + FLY
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
				
				-- Tạo hạt lửa rơi xung quanh đầu nhân vật
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
					
					-- Tự hủy sau 3 giây để chống lag
					Debris:AddItem = nil
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
local originalAtmosphere = Lighting:FindFirstChildOfClass("Atmosphere")

local function toggleEclipse(active)
	eclipseActive = active
	if eclipseActive then
		print("[MrDon] Sự kiện Nhật Thực bắt đầu!")
		Lighting.ClockTime = 0 -- Đặt giờ thành nửa đêm
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

-- 6. Giao diện điều khiển (UI)
if player.PlayerGui:FindFirstChild("MadilaAdminGui") then
	player.PlayerGui.MadilaAdminGui:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MadilaAdminGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 240, 0, 260)
frame.Position = UDim2.new(0, 20, 0.5, -130)
frame.BackgroundColor3 = Color3.fromRGB(30, 32, 36)
frame.BorderSizePixel = 0
frame.Parent = screenGui

Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

local titleLabel = Instance.new("TextLabel")
titlePanel = titleLabel
titleLabel.Size = UDim2.new(1, 0, 0, 25)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "--- MRDON ADMIN PANEL ---"
titleLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextSize = 13
titleLabel.Parent = frame

-- Nút Sự Kiện Núi Lửa
local volcanoBtn = Instance.new("TextButton")
volcanoBtn.Size = UDim2.new(1, -20, 0, 28)
volcanoBtn.Position = UDim2.new(0, 10, 0, 30)
volcanoBtn.Text = "Bật/Tắt Sự Kiện Núi Lửa"
volcanoBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
volcanoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
volcanoBtn.Font = Enum.Font.SourceSansBold
volcanoBtn.TextSize = 14
volcanoBtn.Parent = frame
Instance.new("UICorner", volcanoBtn).CornerRadius = UDim.new(0, 6)

volcanoBtn.MouseButton1Click:Connect(function()
	toggleVolcano(not volcanoActive)
	volcanoBtn.BackgroundColor3 = volcanoActive and Color3.fromRGB(60, 180, 90) or Color3.fromRGB(180, 60, 60)
end)

-- Nút Sự Kiện Nhật Thực
local eclipseBtn = Instance.new("TextButton")
eclipseBtn.Size = UDim2.new(1, -20, 0, 28)
eclipseBtn.Position = UDim2.new(0, 10, 0, 66)
eclipseBtn.Text = "Bật/Tắt Sự Kiện Nhật Thực"
eclipseBtn.BackgroundColor3 = Color3.fromRGB(80, 60, 140)
eclipseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
eclipseBtn.Font = Enum.Font.SourceSansBold
eclipseBtn.TextSize = 14
eclipseBtn.Parent = frame
Instance.new("UICorner", eclipseBtn).CornerRadius = UDim.new(0, 6)

eclipseBtn.MouseButton1Click:Connect(function()
	toggleEclipse(not eclipseActive)
	eclipseBtn.BackgroundColor3 = eclipseActive and Color3.fromRGB(60, 180, 90) or Color3.fromRGB(80, 60, 140)
end)

-- Nút Định Vị (ESP)
local espBtn = Instance.new("TextButton")
espBtn.Size = UDim2.new(1, -20, 0, 28)
espBtn.Position = UDim2.new(0, 10, 0, 102)
espBtn.Text = "Bật/Tắt Định Vị (ESP Bot/Player)"
espBtn.BackgroundColor3 = Color3.fromRGB(60, 140, 180)
espBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
espBtn.Font = Enum.Font.SourceSansBold
espBtn.TextSize = 14
espBtn.Parent = frame
Instance.new("UICorner", espBtn).CornerRadius = UDim.new(0, 6)

espBtn.MouseButton1Click:Connect(function()
	toggleESP(not espEnabled)
	espBtn.BackgroundColor3 = espEnabled and Color3.fromRGB(60, 180, 90) or Color3.fromRGB(60, 140, 180)
end)

-- Nút Bay
local flyBtn = Instance.new("TextButton")
flyBtn.Size = UDim2.new(1, -20, 0, 28)
flyBtn.Position = UDim2.new(0, 10, 0, 138)
flyBtn.Text = "Bật/Tắt Bay (Fly)"
flyBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 180)
flyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
flyBtn.Font = Enum.Font.SourceSansBold
flyBtn.TextSize = 14
flyBtn.Parent = frame
Instance.new("UICorner", flyBtn).CornerRadius = UDim.new(0, 6)

flyBtn.MouseButton1Click:Connect(function()
	toggleFlight(not flying)
	flyBtn.BackgroundColor3 = flying and Color3.fromRGB(60, 180, 90) or Color3.fromRGB(60, 120, 180)
end)

-- Nút Xuyên Tường
local noclipBtn = Instance.new("TextButton")
noclipBtn.Size = UDim2.new(1, -20, 0, 28)
noclipBtn.Position = UDim2.new(0, 10, 0, 174)
noclipBtn.Text = "Bật/Tắt Xuyên Tường"
noclipBtn.BackgroundColor3 = Color3.fromRGB(120, 60, 180)
noclipBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
noclipBtn.Font = Enum.Font.SourceSansBold
noclipBtn.TextSize = 14
noclipBtn.Parent = frame
Instance.new("UICorner", noclipBtn).CornerRadius = UDim.new(0, 6)

noclipBtn.MouseButton1Click:Connect(function()
	noclip = not noclip
	noclipBtn.BackgroundColor3 = noclip and Color3.fromRGB(60, 180, 90) or Color3.fromRGB(120, 60, 180)
end)

-- Nút Giảm Lag
local lagBtn = Instance.new("TextButton")
lagBtn.Size = UDim2.new(1, -20, 0, 28)
lagBtn.Position = UDim2.new(0, 10, 0, 210)
lagBtn.Text = "Giảm Lag (Lag Fix)"
lagBtn.BackgroundColor3 = Color3.fromRGB(180, 140, 60)
lagBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
lagBtn.Font = Enum.Font.SourceSansBold
lagBtn.TextSize = 14
lagBtn.Parent = frame
Instance.new("UICorner", lagBtn).CornerRadius = UDim.new(0, 6)

lagBtn.MouseButton1Click:Connect(function()
	for _, desc in ipairs(Workspace:GetDescendants()) do
		if desc:IsA("BasePart") then desc.CastShadow = false end
	end
	print("[MrDon] Đã giảm lag thành công.")
end)

print("[MrDon] Script Sự kiện Núi Lửa & Nhật Thực đã khởi chạy hoàn tất trên Volcano!")
