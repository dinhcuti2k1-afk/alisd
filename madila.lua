-- ============================================================================
-- SCRIPT TỔNG HỢP: MADILA.LUA (TÙY CHỈNH TỐC ĐỘ BAY + SỰ KIỆN + ESP + NOCLIP)
-- ============================================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
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

-- Cập nhật lại nhân vật khi hồi sinh
player.CharacterAdded:Connect(function(newChar)
	character = newChar
	humanoidRootPart = newChar:WaitForChild("HumanoidRootPart")
	flying = false
	if bg then bg:Destroy() bg = nil end
	if bv then bv:Destroy() bv = nil end
end)

-- 1. Sự kiện Núi Lửa (Volcano Eruption Effect)
local function toggleVolcano(active)
	volcanoActive = active
	if volcanoActive then
		print("[MrDon] Sự kiện Núi Lửa đã bắt đầu!")
		task.spawn(function()
			while volcanoActive do
				Camera.CFrame = Camera.CFrame * CFrame.new(
					math.random(-35, 35) / 100,
					math.random(-35, 35) / 100,
					math.random(-35, 35) / 100
				)

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
						if part and part.Parent then
							part:Destroy()
						end
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
local originalAmbient = Lighting.Ambient
local originalOutdoor = Lighting.OutdoorAmbient

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
		Lighting.Ambient = originalAmbient
		Lighting.OutdoorAmbient = originalOutdoor
	end
end

-- 3. Tính năng Định vị (ESP) Player và Bot
local function toggleESP(active)
	espEnabled = active
	if not espEnabled then
		for _, billboard in pairs(espObjects) do
			if billboard and billboard.Parent then
				billboard:Destroy()
			end
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

-- 4. Tính năng Bay (Fly) - Hỗ trợ cập nhật tốc độ trực tiếp
local function toggleFlight(active)
	flying = active
	if not character or not humanoidRootPart then return end
	local hum = character:FindFirstChildOfClass("Humanoid")

	if flying then
		if hum then hum.PlatformStand = true end

		bg = Instance.new("BodyGyro")
		bg.MaxTorque = Vector3.new(400000, 400000, 400000)
		bg.P = 20000
		bg.Parent = humanoidRootPart

		bv = Instance.new("BodyVelocity")
		bv.MaxForce = Vector3.new(400000, 400000, 400000)
		bv.Velocity = Vector3.zero
		bv.Parent = humanoidRootPart

		task.spawn(function()
			while flying and character and humanoidRootPart and bv and bg do
				local moveDir = Vector3.zero
				if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Camera.CFrame.LookVector end
				if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - Camera.CFrame.LookVector end
				if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - Camera.CFrame.RightVector end
				if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Camera.CFrame.RightVector end
				if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
				if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - Vector3.new(0, 1, 0) end

				bv.Velocity = moveDir * speed
				bg.CFrame = Camera.CFrame
				RunService.RenderStepped:Wait()
			end
		end)
	else
		if hum then hum.PlatformStand = false end
		if bg then bg:Destroy() bg = nil end
		if bv then bv:Destroy() bv = nil end
	end
end

-- 5. Xuyên tường (Noclip)
RunService.Stepped:Connect(function()
	if noclip and character then
		for _, p in ipairs(character:GetDescendants()) do
			if p:IsA("BasePart") then
				p.CanCollide = false
			end
		end
	end
end)

-- 6. Giao diện điều khiển (UI)
local guiParent = (pcall(function() return CoreGui.Name end) and CoreGui) or player:WaitForChild("PlayerGui")
if guiParent:FindFirstChild("MadilaAdminGui") then
	guiParent.MadilaAdminGui:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MadilaAdminGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = guiParent

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 240, 0, 284)
frame.Position = UDim2.new(0.75, 0, 0.3, 0)
frame.BackgroundColor3 = Color3.fromRGB(30, 32, 36)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = screenGui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 28)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "MADILA PANEL (Kéo thả được)"
titleLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextSize = 14
titleLabel.Parent = frame

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

local volcanoBtn
volcanoBtn = createButton("Bật/Tắt Sự Kiện Núi Lửa", 32, Color3.fromRGB(180, 60, 60), function()
	toggleVolcano(not volcanoActive)
	volcanoBtn.BackgroundColor3 = volcanoActive and Color3.fromRGB(60, 180, 90) or Color3.fromRGB(180, 60, 60)
end)

local eclipseBtn
eclipseBtn = createButton("Bật/Tắt Sự Kiện Nhật Thực", 68, Color3.fromRGB(80, 60, 140), function()
	toggleEclipse(not eclipseActive)
	eclipseBtn.BackgroundColor3 = eclipseActive and Color3.fromRGB(60, 180, 90) or Color3.fromRGB(80, 60, 140)
end)

local espBtn
espBtn = createButton("Bật/Tắt Định Vị (ESP)", 104, Color3.fromRGB(60, 140, 180), function()
	toggleESP(not espEnabled)
	espBtn.BackgroundColor3 = espEnabled and Color3.fromRGB(60, 180, 90) or Color3.fromRGB(60, 140, 180)
end)

local flyBtn
flyBtn = createButton("Bật/Tắt Bay (Fly)", 140, Color3.fromRGB(60, 120, 180), function()
	toggleFlight(not flying)
	flyBtn.BackgroundColor3 = flying and Color3.fromRGB(60, 180, 90) or Color3.fromRGB(60, 120, 180)
end)

-- Thanh chỉnh tốc độ bay (Nút -10 / Ô nhập số / Nút +10)
local minusBtn = Instance.new("TextButton")
minusBtn.Size = UDim2.new(0, 32, 0, 28)
minusBtn.Position = UDim2.new(0, 10, 0, 176)
minusBtn.Text = "-10"
minusBtn.BackgroundColor3 = Color3.fromRGB(70, 75, 85)
minusBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minusBtn.Font = Enum.Font.SourceSansBold
minusBtn.TextSize = 13
minusBtn.Parent = frame
Instance.new("UICorner", minusBtn).CornerRadius = UDim.new(0, 6)

local speedBox = Instance.new("TextBox")
speedBox.Size = UDim2.new(1, -96, 0, 28)
speedBox.Position = UDim2.new(0, 48, 0, 176)
speedBox.Text = tostring(speed)
speedBox.PlaceholderText = "Tốc độ..."
speedBox.BackgroundColor3 = Color3.fromRGB(45, 48, 54)
speedBox.TextColor3 = Color3.fromRGB(255, 255, 255)
speedBox.Font = Enum.Font.SourceSansBold
speedBox.TextSize = 14
speedBox.Parent = frame
Instance.new("UICorner", speedBox).CornerRadius = UDim.new(0, 6)

local plusBtn = Instance.new("TextButton")
plusBtn.Size = UDim2.new(0, 32, 0, 28)
plusBtn.Position = UDim2.new(1, -42, 0, 176)
plusBtn.Text = "+10"
plusBtn.BackgroundColor3 = Color3.fromRGB(70, 75, 85)
plusBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
plusBtn.Font = Enum.Font.SourceSansBold
plusBtn.TextSize = 13
plusBtn.Parent = frame
Instance.new("UICorner", plusBtn).CornerRadius = UDim.new(0, 6)

speedBox.FocusLost:Connect(function()
	local num = tonumber(speedBox.Text)
	if num and num > 0 then
		speed = num
	else
		speedBox.Text = tostring(speed)
	end
end)

minusBtn.MouseButton1Click:Connect(function()
	speed = math.max(10, speed - 10)
	speedBox.Text = tostring(speed)
end)

plusBtn.MouseButton1Click:Connect(function()
	speed = speed + 10
	speedBox.Text = tostring(speed)
end)

local noclipBtn
noclipBtn = createButton("Bật/Tắt Xuyên Tường", 212, Color3.fromRGB(120, 60, 180), function()
	noclip = not noclip
	noclipBtn.BackgroundColor3 = noclip and Color3.fromRGB(60, 180, 90) or Color3.fromRGB(120, 60, 180)
end)

createButton("Giảm Lag (Lag Fix)", 248, Color3.fromRGB(180, 140, 60), function()
	for _, desc in ipairs(Workspace:GetDescendants()) do
		if desc:IsA("BasePart") then
			desc.CastShadow = false
		end
	end
	print("[MrDon] Đã giảm lag thành công.")
end)

print("[MrDon] Code tổng hợp Madila.lua đã sẵn sàng!")
