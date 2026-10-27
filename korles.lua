--[[ KORLES UI
     Headless + Korblox + Aksesori dengan menu toggle.
     Efek hanya terlihat di layarmu sendiri (client-side).
     Sembunyikan/tampilkan menu: tombol RightControl atau tombol "KL" kecil. ]]

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local TS = game:GetService("TweenService")
local lp = Players.LocalPlayer

-- hapus instance lama kalau script dijalankan dua kali
pcall(function()
	if getgenv and getgenv().__KORLES_CLOSE then getgenv().__KORLES_CLOSE() end
end)

local DEFAULT_IDS = { 74891470, 10159610478, 10159600649, 141742418 }

-- warna
local ACC = Color3.fromRGB(255, 122, 0)
local BG = Color3.fromRGB(14, 14, 16)
local HD = Color3.fromRGB(22, 22, 26)
local ROW = Color3.fromRGB(30, 30, 36)
local OFF = Color3.fromRGB(58, 58, 66)
local TXT = Color3.fromRGB(235, 235, 240)
local MUT = Color3.fromRGB(150, 150, 160)
local GOOD = Color3.fromRGB(100, 220, 130)
local BAD = Color3.fromRGB(255, 90, 90)
local FB, FM = Enum.Font.GothamBold, Enum.Font.GothamMedium

-- ===== state =====
local S = { headless = false, korblox = false, acc = {}, order = {} }
local alive = true
local conns = {}
local orig = setmetatable({}, { __mode = "k" })
local ui = {}

local function new(cls, props, parent)
	local o = Instance.new(cls)
	for k, v in pairs(props) do o[k] = v end
	o.Parent = parent
	return o
end
local function round(o, r) new("UICorner", { CornerRadius = UDim.new(0, r or 6) }, o) end
local function setStatus(t, bad)
	if ui.status then
		ui.status.Text = t
		ui.status.TextColor3 = bad and BAD or GOOD
	end
end

-- ===== simpan & pulihkan properti =====
local function remember(inst, prop)
	orig[inst] = orig[inst] or {}
	if orig[inst][prop] == nil then orig[inst][prop] = inst[prop] end
end
local function restoreInst(inst)
	local o = orig[inst]
	if o then
		for p, v in pairs(o) do pcall(function() inst[p] = v end) end
		orig[inst] = nil
	end
end

-- ===== headless =====
local function headlessStep()
	local c = lp.Character
	local head = c and c:FindFirstChild("Head")
	if not head then return end
	remember(head, "Transparency")
	head.Transparency = 1
	pcall(function() head.LocalTransparencyModifier = 1 end)
	for _, ch in ipairs(head:GetChildren()) do
		if ch:IsA("Decal") then
			remember(ch, "Transparency")
			ch.Transparency = 1
		elseif ch:IsA("SpecialMesh") then
			remember(ch, "Scale")
			ch.Scale = Vector3.new(0, 0, 0)
		end
	end
end
local function headlessRestore()
	local c = lp.Character
	local head = c and c:FindFirstChild("Head")
	if not head then return end
	restoreInst(head)
	for _, ch in ipairs(head:GetChildren()) do restoreInst(ch) end
	pcall(function() head.LocalTransparencyModifier = 0 end)
end

-- ===== korblox =====
local function korbloxR15(c)
	local upper = c:FindFirstChild("RightUpperLeg")
	local lower = c:FindFirstChild("RightLowerLeg")
	local foot = c:FindFirstChild("RightFoot")
	if not (upper and lower and foot) then return end
	for _, p in ipairs({ upper, lower, foot }) do
		remember(p, "Transparency")
		p.Transparency = 1
		pcall(function() p.LocalTransparencyModifier = 1 end)
		for _, ch in ipairs(p:GetChildren()) do
			if ch:IsA("WrapLayer") then
				remember(ch, "Enabled")
				ch.Enabled = false
			end
		end
	end
	if not upper:FindFirstChild("KL_Korblox") then
		local part = new("Part", {
			Name = "KL_Korblox", CanCollide = false, CanTouch = false,
			CanQuery = false, Massless = true, CFrame = upper.CFrame,
		})
		new("SpecialMesh", {
			MeshType = Enum.MeshType.FileMesh,
			MeshId = "rbxassetid://902942096",
			TextureId = "rbxassetid://902843398",
			Scale = Vector3.new(1, 1, 1),
		}, part)
		new("Weld", { Part0 = upper, Part1 = part, C0 = CFrame.new(), C1 = CFrame.new() }, part)
		part.Parent = upper
	end
end
local savedR6 = {}
local function korbloxR6(c)
	local leg = c:FindFirstChild("Right Leg")
	if not leg then return end
	if leg:FindFirstChild("KL_Mesh") then return end
	for _, ch in ipairs(c:GetChildren()) do
		if ch:IsA("CharacterMesh") and ch.BodyPart == Enum.BodyPart.RightLeg and ch.Name ~= "KL_CharMesh" then
			table.insert(savedR6, ch)
			ch.Parent = nil
		end
	end
	pcall(function()
		new("CharacterMesh", { Name = "KL_CharMesh", MeshId = 101851696, BodyPart = Enum.BodyPart.RightLeg }, c)
	end)
	pcall(function()
		new("SpecialMesh", {
			Name = "KL_Mesh",
			MeshType = Enum.MeshType.FileMesh,
			MeshId = "http://www.roblox.com/asset/?id=101851696",
			TextureId = "http://www.roblox.com/asset/?id=101851254",
			Scale = Vector3.new(1, 1, 1),
		}, leg)
	end)
end
local function korbloxStep()
	local c = lp.Character
	local hum = c and c:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	if hum.RigType == Enum.HumanoidRigType.R15 then korbloxR15(c) else korbloxR6(c) end
end
local function korbloxRestore()
	local c = lp.Character
	if not c then return end
	for _, n in ipairs({ "RightUpperLeg", "RightLowerLeg", "RightFoot" }) do
		local p = c:FindFirstChild(n)
		if p then
			restoreInst(p)
			for _, ch in ipairs(p:GetChildren()) do restoreInst(ch) end
			pcall(function() p.LocalTransparencyModifier = 0 end)
		end
	end
	local up = c:FindFirstChild("RightUpperLeg")
	local v = up and up:FindFirstChild("KL_Korblox")
	if v then v:Destroy() end
	local leg = c:FindFirstChild("Right Leg")
	local m = leg and leg:FindFirstChild("KL_Mesh")
	if m then m:Destroy() end
	local cm = c:FindFirstChild("KL_CharMesh")
	if cm then cm:Destroy() end
	for _, ch in ipairs(savedR6) do pcall(function() ch.Parent = c end) end
	savedR6 = {}
end

-- ===== aksesori =====
local function accRemove(id)
	local a = S.acc[id]
	if a and a.obj then
		pcall(function() a.obj:Destroy() end)
		a.obj = nil
	end
end
local function accAttach(id)
	local a = S.acc[id]
	local c = lp.Character
	if not (a and a.on and c) or a.busy then return end
	if a.obj and a.obj.Parent then return end
	a.busy = true
	task.spawn(function()
		local ok, asset = pcall(function() return game:GetObjects("rbxassetid://" .. tostring(id))[1] end)
		a.busy = false
		if not alive then if ok and asset then asset:Destroy() end return end
		if not ok or not asset then
			a.fails = (a.fails or 0) + 1
			if a.fails >= 3 then setStatus("aksesori " .. id .. " gagal dimuat", true) end
			return
		end
		local handle = asset:FindFirstChild("Handle")
		local head = c:FindFirstChild("Head")
		if not a.on or lp.Character ~= c or not handle or not head then
			asset:Destroy()
			if not handle then a.fails = 3; setStatus("ID " .. id .. " bukan aksesori", true) end
			return
		end
		asset.Name = "KL_Acc_" .. tostring(id)
		handle.CanCollide = false
		handle.Massless = true
		asset.Parent = c
		local hum = c:FindFirstChildOfClass("Humanoid")
		if hum then pcall(function() hum:AddAccessory(asset) end) end
		if not (handle:FindFirstChildOfClass("Weld") or handle:FindFirstChildOfClass("WeldConstraint")) then
			local hAtt = handle:FindFirstChildOfClass("Attachment")
			local tPart, tAtt = head, nil
			if hAtt then
				local f = c:FindFirstChild(hAtt.Name, true)
				if f and f:IsA("Attachment") and f.Parent and f.Parent:IsA("BasePart") then
					tPart, tAtt = f.Parent, f
				end
			end
			local w = new("Weld", { Name = "AccessoryWeld", Part0 = tPart, Part1 = handle }, handle)
			if hAtt and tAtt then
				w.C0 = tAtt.CFrame
				w.C1 = hAtt.CFrame
			else
				w.C0 = CFrame.new(0, 0.6, 0)
			end
		end
		a.obj = asset
		a.fails = 0
	end)
end

-- ===== setter =====
local renderAcc
local function setHeadless(v)
	S.headless = v
	if not v then headlessRestore() end
	setStatus("Headless " .. (v and "ON" or "OFF"))
end
local function setKorblox(v)
	S.korblox = v
	if not v then korbloxRestore() end
	setStatus("Korblox " .. (v and "ON" or "OFF"))
end
local function setAcc(id, v)
	local a = S.acc[id]
	if not a then return end
	a.on = v
	a.fails = 0
	if v then accAttach(id) else accRemove(id) end
end
local function addAcc(id, on)
	if S.acc[id] then setStatus("ID " .. id .. " sudah ada", true) return end
	S.acc[id] = { on = false, fails = 0 }
	table.insert(S.order, id)
	if on then setAcc(id, true) end
	renderAcc()
end
local function removeAccId(id)
	accRemove(id)
	S.acc[id] = nil
	for i, v in ipairs(S.order) do if v == id then table.remove(S.order, i) break end end
	renderAcc()
end

-- ===== loop & respawn =====
table.insert(conns, RS.Heartbeat:Connect(function()
	if S.headless then pcall(headlessStep) end
	if S.korblox then pcall(korbloxStep) end
end))
table.insert(conns, lp.CharacterAdded:Connect(function(c)
	c:WaitForChild("Humanoid", 10)
	task.wait(0.3)
	for _, id in ipairs(S.order) do
		local a = S.acc[id]
		if a then a.obj = nil; a.busy = false; a.fails = 0 end
	end
end))
task.spawn(function()
	while alive do
		task.wait(1)
		for _, id in ipairs(S.order) do
			local a = S.acc[id]
			if a and a.on and not a.busy and (a.fails or 0) < 3 and not (a.obj and a.obj.Parent) then
				pcall(accAttach, id)
			end
		end
	end
end)

-- ===== UI =====
local gui = Instance.new("ScreenGui")
gui.Name = "KorlesUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 999
do
	local ok = pcall(function()
		gui.Parent = (gethui and gethui()) or game:GetService("CoreGui")
	end)
	if not ok or not gui.Parent then gui.Parent = lp:WaitForChild("PlayerGui") end
end

local cam = workspace.CurrentCamera
local vp = cam and cam.ViewportSize or Vector2.new(640, 360)
local W = math.clamp(vp.X - 20, 260, 320)
local H = math.clamp(vp.Y - 40, 240, 400)

local frame = new("Frame", {
	Size = UDim2.fromOffset(W, H), Position = UDim2.new(0.5, -W / 2, 0.5, -H / 2),
	BackgroundColor3 = BG, BorderSizePixel = 0, ClipsDescendants = true,
}, gui)
round(frame, 8)
new("UIStroke", { Color = ACC, Thickness = 1.5 }, frame)

local head = new("Frame", { Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = HD, BorderSizePixel = 0 }, frame)
new("TextLabel", {
	Size = UDim2.new(1, -70, 1, 0), Position = UDim2.fromOffset(10, 0), BackgroundTransparency = 1,
	Text = "KORLES", TextColor3 = ACC, Font = FB, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
}, head)
local bMin = new("TextButton", {
	Size = UDim2.fromOffset(24, 24), Position = UDim2.new(1, -56, 0, 5), BackgroundColor3 = OFF,
	Text = "-", TextColor3 = TXT, Font = FB, TextSize = 14, AutoButtonColor = false,
}, head)
round(bMin, 5)
local bX = new("TextButton", {
	Size = UDim2.fromOffset(24, 24), Position = UDim2.new(1, -28, 0, 5), BackgroundColor3 = OFF,
	Text = "X", TextColor3 = ACC, Font = FB, TextSize = 13, AutoButtonColor = false,
}, head)
round(bX, 5)

local foot = new("Frame", { Size = UDim2.new(1, 0, 0, 22), Position = UDim2.new(1, 0, 1, 0), AnchorPoint = Vector2.new(1, 1), BackgroundColor3 = HD, BorderSizePixel = 0 }, frame)
ui.status = new("TextLabel", {
	Size = UDim2.new(1, -16, 1, 0), Position = UDim2.fromOffset(8, 0), BackgroundTransparency = 1,
	Text = "siap", TextColor3 = GOOD, Font = FM, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left,
	TextTruncate = Enum.TextTruncate.AtEnd,
}, foot)

local body = new("ScrollingFrame", {
	Size = UDim2.new(1, 0, 1, -56), Position = UDim2.fromOffset(0, 34), BackgroundTransparency = 1,
	BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = ACC,
	CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, frame)
new("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, body)
new("UIListLayout", { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder }, body)

local order = 0
local function nx() order = order + 1 return order end
local function section(t)
	new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, Text = string.upper(t), TextColor3 = ACC,
		Font = FB, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = nx(),
	}, body)
end
local refreshers = {}
local function makeSwitch(parent, pos, get, click)
	local tr = new("TextButton", {
		Size = UDim2.fromOffset(36, 18), Position = pos, Text = "", AutoButtonColor = false,
		BackgroundColor3 = OFF, BorderSizePixel = 0,
	}, parent)
	round(tr, 9)
	local kn = new("Frame", {
		Size = UDim2.fromOffset(14, 14), Position = UDim2.new(0, 2, 0.5, -7),
		BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
	}, tr)
	round(kn, 7)
	local function refresh()
		local on = get()
		TS:Create(tr, TweenInfo.new(0.12), { BackgroundColor3 = on and ACC or OFF }):Play()
		TS:Create(kn, TweenInfo.new(0.12), { Position = on and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7) }):Play()
	end
	tr.MouseButton1Click:Connect(function() click() refresh() end)
	refresh()
	return refresh
end
local function toggleRow(text, get, set)
	local r = new("Frame", { Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = ROW, BorderSizePixel = 0, LayoutOrder = nx() }, body)
	round(r)
	new("TextLabel", {
		Size = UDim2.new(1, -60, 1, 0), Position = UDim2.fromOffset(10, 0), BackgroundTransparency = 1,
		Text = text, TextColor3 = TXT, Font = FM, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
	}, r)
	table.insert(refreshers, makeSwitch(r, UDim2.new(1, -46, 0.5, -9), get, function() set(not get()) end))
end
local function button(text, solid, fn)
	local b = new("TextButton", {
		Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = solid and ACC or ROW, Text = text,
		TextColor3 = solid and Color3.new(0, 0, 0) or ACC, Font = FB, TextSize = 11,
		AutoButtonColor = false, LayoutOrder = nx(),
	}, body)
	round(b)
	b.MouseButton1Click:Connect(function() task.spawn(function() local ok, e = pcall(fn) if not ok then setStatus("error: " .. tostring(e):sub(1, 60), true) end end) end)
	return b
end

section("Karakter")
toggleRow("Headless (kepala hilang)", function() return S.headless end, setHeadless)
toggleRow("Korblox kaki kanan", function() return S.korblox end, setKorblox)

section("Aksesori")
local accHolder = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = nx() }, body)
new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, accHolder)

function renderAcc()
	for _, ch in ipairs(accHolder:GetChildren()) do if ch:IsA("Frame") then ch:Destroy() end end
	for i, id in ipairs(S.order) do
		local row = new("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = ROW, BorderSizePixel = 0, LayoutOrder = i }, accHolder)
		round(row)
		new("TextLabel", {
			Size = UDim2.new(1, -90, 1, 0), Position = UDim2.fromOffset(10, 0), BackgroundTransparency = 1,
			Text = "ID " .. id, TextColor3 = TXT, Font = FM, TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
		}, row)
		makeSwitch(row, UDim2.new(1, -78, 0.5, -9), function() return S.acc[id] and S.acc[id].on end, function() setAcc(id, not S.acc[id].on) end)
		local del = new("TextButton", {
			Size = UDim2.fromOffset(22, 22), Position = UDim2.new(1, -30, 0.5, -11), BackgroundColor3 = OFF,
			Text = "x", TextColor3 = BAD, Font = FB, TextSize = 12, AutoButtonColor = false,
		}, row)
		round(del, 5)
		del.MouseButton1Click:Connect(function() removeAccId(id) end)
	end
end

local inRow = new("Frame", { Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = ROW, BorderSizePixel = 0, LayoutOrder = nx() }, body)
round(inRow)
local box = new("TextBox", {
	Size = UDim2.new(1, -86, 1, -8), Position = UDim2.fromOffset(8, 4), BackgroundTransparency = 1, Text = "",
	PlaceholderText = "ID aksesori...", PlaceholderColor3 = MUT, TextColor3 = ACC, Font = FM, TextSize = 12,
	TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false,
}, inRow)
local addBtn = new("TextButton", {
	Size = UDim2.fromOffset(70, 24), Position = UDim2.new(1, -76, 0.5, -12), BackgroundColor3 = ACC,
	Text = "TAMBAH", TextColor3 = Color3.new(0, 0, 0), Font = FB, TextSize = 10, AutoButtonColor = false,
}, inRow)
round(addBtn, 5)
addBtn.MouseButton1Click:Connect(function()
	local id = tonumber((box.Text:gsub("%s+", "")))
	if id and id > 0 then
		box.Text = ""
		addAcc(math.floor(id), true)
		setStatus("menambah ID " .. math.floor(id))
	else
		setStatus("ID harus angka", true)
	end
end)

section("Semua")
button("NYALAKAN SEMUA", true, function()
	setHeadless(true); setKorblox(true)
	for _, id in ipairs(S.order) do setAcc(id, true) end
	renderAcc()
	for _, r in ipairs(refreshers) do r() end
end)
button("MATIKAN SEMUA", false, function()
	setHeadless(false); setKorblox(false)
	for _, id in ipairs(S.order) do setAcc(id, false) end
	renderAcc()
	for _, r in ipairs(refreshers) do r() end
	setStatus("semua dimatikan")
end)

for _, id in ipairs(DEFAULT_IDS) do addAcc(id, false) end

-- ===== drag, minimize, tutup =====
local function draggable(handle, target, onTap)
	local dragging, moved, startPos, startFrame = false, false, nil, nil
	handle.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging, moved, startPos, startFrame = true, false, i.Position, target.Position
		end
	end)
	table.insert(conns, UIS.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			local d = i.Position - startPos
			if math.abs(d.X) + math.abs(d.Y) > 6 then moved = true end
			target.Position = UDim2.new(startFrame.X.Scale, startFrame.X.Offset + d.X, startFrame.Y.Scale, startFrame.Y.Offset + d.Y)
		end
	end))
	table.insert(conns, UIS.InputEnded:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) then
			dragging = false
			if not moved and onTap then onTap() end
		end
	end))
end

local mini = new("TextButton", {
	Size = UDim2.fromOffset(42, 42), Position = UDim2.fromOffset(10, 60), BackgroundColor3 = BG, Text = "KL",
	TextColor3 = ACC, Font = FB, TextSize = 13, AutoButtonColor = false, Visible = false,
}, gui)
round(mini, 10)
new("UIStroke", { Color = ACC, Thickness = 1.5 }, mini)

draggable(head, frame, nil)
draggable(mini, mini, function()
	frame.Position = mini.Position
	frame.Visible = true
	mini.Visible = false
end)
bMin.MouseButton1Click:Connect(function()
	mini.Position = frame.Position
	frame.Visible = false
	mini.Visible = true
end)

local function closeAll()
	if not alive then return end
	alive = false
	for _, id in ipairs(S.order) do pcall(accRemove, id) end
	S.headless, S.korblox = false, false
	pcall(headlessRestore)
	pcall(korbloxRestore)
	for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
	if gui then gui:Destroy() end
end
bX.MouseButton1Click:Connect(closeAll)
pcall(function() if getgenv then getgenv().__KORLES_CLOSE = closeAll end end)

table.insert(conns, UIS.InputBegan:Connect(function(i, gp)
	if not gp and i.KeyCode == Enum.KeyCode.RightControl then
		if frame.Visible then
			mini.Position = frame.Position
			frame.Visible = false
			mini.Visible = true
		else
			frame.Position = mini.Position
			frame.Visible = true
			mini.Visible = false
		end
	end
end))

setStatus("siap. nyalakan fitur lewat toggle")
