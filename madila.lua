-- ============================================================================
-- SCRIPT MADILA.LUA - ĐÓNG BĂNG TOÀN DIỆN (FORCE POSITION LOCK + ESP)
-- ============================================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- Trạng thái
local flying = false
local noclip = false
local espEnabled = false
local speed = 50
local bg, bv
local espObjects = {}
local frozenTargets = {} -- Lưu trữ danh sách mục tiêu đang bị khóa tọa độ

-- 1. Tìm kiếm Player hoặc NPC/Bot theo tên
local function findTargetByName(query)
	if not query or query == "" then return nil end
	local lowerQ = string.lower(query)
	
	for _, p in ipairs(Players:GetPlayers()) do
		if string.find(string.lower(p.Name), lowerQ) or string.find(string.lower(p.DisplayName), lowerQ) then
			return p.Character
		end
	end
	
	for _, obj in ipairs(Workspace:GetChildren()) do
		if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") then
			if string.find(string.lower(obj.Name), lowerQ) then
				return obj
			end
		end
	end
	return nil
end

-- 2. Vòng lặp cưỡng chế vị trí (Force Lock Loop) - Ngăn mục tiêu dịch chuyển
RunService.Heartbeat:Connect(function()
	for targetChar, lockedCFrame in pairs(frozenTargets) do
		if targetChar and targetChar.Parent and targetChar:FindFirstChild("HumanoidRootPart") then
			local hrp = targetChar.HumanoidRootPart
			local hum = targetChar:FindFirstChildOfClass("Humanoid")
			
			-- Liên tục ép vị trí và hướng về chỗ bị khóa, vô hiệu hóa mọi lệnh chạy
			hrp.CFrame = lockedCFrame
			hrp.AssemblyLinearVelocity = Vector3.zero
			hrp.AssemblyAngularVelocity = Vector3.zero
			
			if hum then
				hum.WalkSpeed = 0
				hum.JumpPower = 0
				hum.PlatformStand = true
			end
		else
			-- Xóa khỏi danh sách nếu mục tiêu thoát hoặc biến mất
			frozenTargets[targetChar] = nil
		end
	end
end)

local function toggleFreezeTarget(targetChar)
	if not targetChar or not targetChar:FindFirstChild("HumanoidRootPart") then
		warn("[MrDon] Không tìm thấy mục tiêu để đóng băng!")
		return false
	end

	local hrp = targetChar.HumanoidRootPart
	if not frozenTargets[targetChar] then
		-- Bật đóng băng và lưu lại tọa độ cố định tại thời điểm bấm
		frozenTargets[targetChar] = hrp.CFrame
		print("[MrDon] Đã khóa cứng toàn diện mục tiêu:", targetChar.Name)
		return true
	else
		-- Tắt đóng băng, trả lại trạng thái cho nhân vật
		local hum = targetChar:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.WalkSpeed = 16
			hum.JumpPower = 50
			hum.PlatformStand = false
		end
		frozenTargets[targetChar] = nil
		print("[MrDon] Đã mở khóa cho:", targetChar.Name)
		return false
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
					textLabel.TextColor3 = Color3.fromRGB(0, 255, 255)
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
frame.Size = UDim2.new(0, 240, 0, 230)
frame.Position = UDim2.new(0, 20, 0.5, -115)
frame.BackgroundColor3 = Color3.fromRGB(30, 32, 36)
frame.BorderSizePixel = 0
frame.Parent = screenGui

Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

local textBox = Instance.new("TextBox")
textBox.Size = UDim2.new(1, -20, 0, 30)
textBox.Position = UDim2.new(0, 10, 0, 10)
textBox.PlaceholderText = "Nhập tên Player hoặc Bot..."
textBox.Text = ""
textBox.BackgroundColor3 = Color3.fromRGB(45, 48, 54)
textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
textBox.Font = Enum.Font.SourceSans
textBox.TextSize = 14
textBox.Parent = frame
Instance.new("UICorner", textBox).CornerRadius = UDim.new(0, 6)

-- Nút Đóng Băng Cưỡng Chế
local freezeBtn = Instance.new("TextButton")
freezeBtn.Size = UDim2.new(1, -20, 0, 28)
freezeBtn.Position = UDim2.new(0, 10, 0, 48)
freezeBtn.Text = "Đóng Băng Cưỡng Chế"
freezeBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
freezeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
freezeBtn.Font = Enum.Font.SourceSansBold
freezeBtn.TextSize = 14
freezeBtn.Parent = frame
Instance.new("UICorner", freezeBtn).CornerRadius = UDim.new(0, 6)

freezeBtn.MouseButton1Click:Connect(function()
	local targetChar = findTargetByName(textBox.Text)
	if targetChar then
		local isFrozen = toggleFreezeTarget(targetChar)
		freezeBtn.BackgroundColor3 = isFrozen and Color3.fromRGB(60, 180, 90) or Color3.fromRGB(180, 60, 60)
	else
		warn("[MrDon] Không tìm thấy tên mục tiêu này!")
	end
end)

-- Nút Định Vị (ESP)
local espBtn = Instance.new("TextButton")
espBtn.Size = UDim2.new(1, -20, 0, 28)
espBtn.Position = UDim2.new(0, 10, 0, 84)
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
flyBtn.Position = UDim2.new(0, 10, 0, 120)
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
noclipBtn.Position = UDim2.new(0, 10, 0, 156)
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
lagBtn.Position = UDim2.new(0, 10, 0, 192)
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

print("[MrDon] Script Madila (Force Lock + ESP) đã sẵn sàng!")
