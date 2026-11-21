-- ============================================================================
-- SCRIPT TỔNG HỢP: MADILA.LUA - 99 NIGHTS (LỌC KHÚC GỖ NHỎ GỌN + AN TOÀN)
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
local selectedItem = "wood"
local bg, bv
local espObjects = {}

local itemLabels = {
	wood = "Gỗ",
	carrot = "Cà Rốt",
	grape = "Nho",
	rabbit_meat = "Thỏ",
	wolf_meat = "Sói"
}

-- Bỏ "tree" để tránh kéo nhầm cây/khối lớn trên map
local itemKeywords = {
	wood = { "log", "wood", "plank", "twig", "go", "gỗ", "củi" },
	carrot = { "carrot", "ca rot", "cà rốt", "carot" },
	grape = { "grape", "grapes", "berry", "berries", "nho" },
	rabbit_meat = { "rabbit", "bunny", "tho", "thỏ" },
	wolf_meat = { "wolf", "soi", "sói" }
}

player.CharacterAdded:Connect(function(newChar)
	character = newChar
	humanoidRootPart = newChar:WaitForChild("HumanoidRootPart")
	flying = false
	if bg then bg:Destroy() bg = nil end
	if bv then bv:Destroy() bv = nil end
end)

local function matchesKeywords(nameStr, keywords)
	local lowerName = string.lower(nameStr or "")
	for _, kw in ipairs(keywords) do
		if string.find(lowerName, string.lower(kw), 1, true) then
			return true
		end
	end
	return false
end

local function getObjectSize(obj)
	if obj:IsA("BasePart") then
		return obj.Size
	elseif obj:IsA("Model") then
		local _, size = obj:GetBoundingBox()
		return size
	end
	return Vector3.new(1, 1, 1)
end

local function isOversizedForPickup(obj, itemKey)
	local sz = getObjectSize(obj)
	local maxDim = math.max(sz.X, sz.Y, sz.Z)
	if itemKey == "wood" then
		-- Chỉ lấy khúc gỗ/củi cỡ vừa và nhỏ, loại bỏ thân cây/khối khổng lồ
		return maxDim > 12
	end
	return maxDim > 15
end

local function findTargetPart(obj)
	if obj:IsA("BasePart") then
		return obj
	elseif obj:IsA("Model") then
		if obj.PrimaryPart then
			return obj.PrimaryPart
		end
		for _, d in ipairs(obj:GetDescendants()) do
			if d:IsA("BasePart") then
				return d
			end
		end
	elseif obj:IsA("Tool") then
		local handle = obj:FindFirstChild("Handle")
		if handle and handle:IsA("BasePart") then
			return handle
		end
		for _, d in ipairs(obj:GetDescendants()) do
			if d:IsA("BasePart") then
				return d
			end
		end
	end
	return nil
end

local function gentlePickupTrigger(obj)
	for _, d in ipairs(obj:GetDescendants()) do
		if d:IsA("ProximityPrompt") and typeof(fireproximityprompt) == "function" then
			pcall(function()
				fireproximityprompt(d)
			end)
			break
		elseif d:IsA("ClickDetector") and typeof(fireclickdetector) == "function" then
			pcall(function()
				fireclickdetector(d)
			end)
			break
		end
	end
end

local function spawnItemAtPlayer(itemKey, amount)
	if not character or not humanoidRootPart then
		warn("[MrDon] Chưa tìm thấy nhân vật!")
		return
	end

	local qty = tonumber(amount)
	if not qty or qty < 1 then
		qty = 1
	end
	qty = math.clamp(math.floor(qty), 1, 30)

	local keywords = itemKeywords[itemKey]
	if not keywords then return end

	local isCreature = (itemKey == "rabbit_meat" or itemKey == "wolf_meat")
	local candidates = {}
	local seenRoots = {}

	for _, obj in ipairs(Workspace:GetDescendants()) do
		if obj ~= character and not obj:IsDescendantOf(character) then
			if matchesKeywords(obj.Name, keywords) then
				local rootObj = obj
				if obj:IsA("BasePart") and obj.Parent and obj.Parent:IsA("Model") and matchesKeywords(obj.Parent.Name, keywords) then
					rootObj = obj.Parent
				end

				if not seenRoots[rootObj] and not isOversizedForPickup(rootObj, itemKey) then
					local part = findTargetPart(rootObj)
					if part then
						local dist = (part.Position - humanoidRootPart.Position).Magnitude
						table.insert(candidates, {
							obj = rootObj,
							part = part,
							dist = dist,
							anchored = part.Anchored
						})
						seenRoots[rootObj] = true
					end
				end
			end
		end
	end

	table.sort(candidates, function(a, b)
		if not isCreature and a.anchored ~= b.anchored then
			return not a.anchored
		end
		return a.dist < b.dist
	end)

	local movedCount = 0
	local centerPos = humanoidRootPart.Position + (humanoidRootPart.CFrame.LookVector * 3.5)

	for i = 1, math.min(qty, #candidates) do
		local entry = candidates[i]
		local obj = entry.obj
		local part = entry.part

		if obj and obj.Parent and part and part.Parent then
			local angle = (i / math.max(1, math.min(qty, #candidates))) * math.pi * 2
			local radius = isCreature and (2.5 + (i * 0.25)) or (1.8 + (i * 0.2))
			local targetCFrame = CFrame.new(
				centerPos.X + math.cos(angle) * radius,
				humanoidRootPart.Position.Y + 0.8 + ((i % 3) * 0.4),
				centerPos.Z + math.sin(angle) * radius
			)

			local movedOK = pcall(function()
				if obj:IsA("Model") then
					obj:PivotTo(targetCFrame)
				elseif part:IsA("BasePart") then
					if not part.Anchored then
						part.AssemblyLinearVelocity = Vector3.zero
						part.AssemblyAngularVelocity = Vector3.zero
					end
					part.CFrame = targetCFrame
				end
			end)

			if movedOK then
				movedCount += 1
				if itemKey == "carrot" or itemKey == "grape" then
					gentlePickupTrigger(obj)
				end
			end
		end
	end

	print(string.format("[MrDon] %s | Nhập: %d | Đưa tới: %d/%d", itemLabels[itemKey] or itemKey, qty, movedCount, #candidates))
end

-- 1. Sự kiện Núi Lửa
local function toggleVolcano(active)
	volcanoActive = active
	if volcanoActive then
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
	end
end

-- 2. Sự kiện Nhật Thực
local originalClockTime = Lighting.ClockTime
local originalBrightness = Lighting.Brightness
local originalAmbient = Lighting.Ambient
local originalOutdoor = Lighting.OutdoorAmbient

local function toggleEclipse(active)
	eclipseActive = active
	if eclipseActive then
		Lighting.ClockTime = 0
		Lighting.Brightness = 0.1
		Lighting.Ambient = Color3.fromRGB(20, 20, 30)
		Lighting.OutdoorAmbient = Color3.fromRGB(10, 10, 20)
	else
		Lighting.ClockTime = originalClockTime
		Lighting.Brightness = originalBrightness
		Lighting.Ambient = originalAmbient
		Lighting.OutdoorAmbient = originalOutdoor
	end
end

-- 3. Định vị ESP
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

-- 4. Bay (Fly) + Chỉnh tốc độ
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

-- 6. Giao diện UI
local guiParent = (pcall(function() return CoreGui.Name end) and CoreGui) or player:WaitForChild("PlayerGui")
if guiParent:FindFirstChild("MadilaAdminGui") then
	guiParent.MadilaAdminGui:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MadilaAdminGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = guiParent

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 260, 0, 444)
frame.Position = UDim2.new(0.73, 0, 0.12, 0)
frame.BackgroundColor3 = Color3.fromRGB(30, 32, 36)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = screenGui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 28)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "MADILA - 99 NIGHTS"
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

local minusBtn = Instance.new("TextButton")
minusBtn.Size = UDim2.new(0, 34, 0, 28)
minusBtn.Position = UDim2.new(0, 10, 0, 176)
minusBtn.Text = "-10"
minusBtn.BackgroundColor3 = Color3.fromRGB(70, 75, 85)
minusBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minusBtn.Font = Enum.Font.SourceSansBold
minusBtn.TextSize = 13
minusBtn.Parent = frame
Instance.new("UICorner", minusBtn).CornerRadius = UDim.new(0, 6)

local speedBox = Instance.new("TextBox")
speedBox.Size = UDim2.new(1, -100, 0, 28)
speedBox.Position = UDim2.new(0, 50, 0, 176)
speedBox.Text = tostring(speed)
speedBox.PlaceholderText = "Tốc độ..."
speedBox.BackgroundColor3 = Color3.fromRGB(45, 48, 54)
speedBox.TextColor3 = Color3.fromRGB(255, 255, 255)
speedBox.Font = Enum.Font.SourceSansBold
speedBox.TextSize = 14
speedBox.Parent = frame
Instance.new("UICorner", speedBox).CornerRadius = UDim.new(0, 6)

local plusBtn = Instance.new("TextButton")
plusBtn.Size = UDim2.new(0, 34, 0, 28)
plusBtn.Position = UDim2.new(1, -44, 0, 176)
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

local resourceButtons = {}

local function selectResource(itemKey)
	selectedItem = itemKey
	for key, btn in pairs(resourceButtons) do
		btn.BorderSizePixel = (key == itemKey) and 2 or 0
		btn.BorderColor3 = Color3.fromRGB(255, 235, 100)
	end
end

local function createSelectBtn(label, xPos, yPos, width, color, itemKey)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, width, 0, 26)
	btn.Position = UDim2.new(0, xPos, 0, yPos)
	btn.Text = label
	btn.BackgroundColor3 = color
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Font = Enum.Font.SourceSansBold
	btn.TextSize = 12
	btn.Parent = frame
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
	resourceButtons[itemKey] = btn
	btn.MouseButton1Click:Connect(function()
		selectResource(itemKey)
	end)
	return btn
end

createSelectBtn("Gỗ", 10, 246, 76, Color3.fromRGB(140, 95, 45), "wood")
createSelectBtn("Cà Rốt", 92, 246, 76, Color3.fromRGB(220, 115, 35), "carrot")
createSelectBtn("Nho", 174, 246, 76, Color3.fromRGB(115, 55, 165), "grape")
createSelectBtn("Thỏ", 10, 278, 116, Color3.fromRGB(165, 115, 95), "rabbit_meat")
createSelectBtn("Sói", 134, 278, 116, Color3.fromRGB(110, 115, 130), "wolf_meat")

selectResource("wood")

local qtyBox = Instance.new("TextBox")
qtyBox.Size = UDim2.new(0, 154, 0, 28)
qtyBox.Position = UDim2.new(0, 10, 0, 312)
qtyBox.Text = "1"
qtyBox.PlaceholderText = "Nhập số lượng..."
qtyBox.BackgroundColor3 = Color3.fromRGB(45, 48, 54)
qtyBox.TextColor3 = Color3.fromRGB(255, 230, 120)
qtyBox.Font = Enum.Font.SourceSansBold
qtyBox.TextSize = 14
qtyBox.Parent = frame
Instance.new("UICorner", qtyBox).CornerRadius = UDim.new(0, 6)

qtyBox.FocusLost:Connect(function()
	local n = tonumber(qtyBox.Text)
	if n and n >= 1 then
		qtyBox.Text = tostring(math.floor(n))
	else
		qtyBox.Text = "1"
	end
end)

local okBtn = Instance.new("TextButton")
okBtn.Size = UDim2.new(0, 80, 0, 28)
okBtn.Position = UDim2.new(0, 170, 0, 312)
okBtn.Text = "OK"
okBtn.BackgroundColor3 = Color3.fromRGB(50, 175, 95)
okBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
okBtn.Font = Enum.Font.SourceSansBold
okBtn.TextSize = 14
okBtn.Parent = frame
Instance.new("UICorner", okBtn).CornerRadius = UDim.new(0, 6)

okBtn.MouseButton1Click:Connect(function()
	spawnItemAtPlayer(selectedItem, qtyBox.Text)
end)

createButton("Giảm Lag (Lag Fix)", 348, Color3.fromRGB(180, 140, 60), function()
	for _, desc in ipairs(Workspace:GetDescendants()) do
		if desc:IsA("BasePart") then
			desc.CastShadow = false
		end
	end
	print("[MrDon] Đã giảm lag thành công.")
end)

print("[MrDon] Madila.lua đã lọc kích thước khối gỗ/vật thể để tránh kéo nhầm vật lớn!")
