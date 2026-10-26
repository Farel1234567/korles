local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

local ACCESSORY_IDS = {
    74891470,
    10159610478,
    10159600649,
    141742418
}

local function lockTransparency(part)
    if not part then return end
    part.Transparency = 1
    pcall(function()
        part:GetPropertyChangedSignal("LocalTransparencyModifier"):Connect(function()
            part.LocalTransparencyModifier = 1
        end)
        part.LocalTransparencyModifier = 1
    end)
end

local function cleanHead(head)
    if not head then return end
    lockTransparency(head)
    for _, child in ipairs(head:GetChildren()) do
        if child:IsA("Decal") then
            child.Transparency = 1
        elseif child:IsA("SpecialMesh") then
            child.Scale = Vector3.new(0, 0, 0)
        elseif child:IsA("SurfaceAppearance") or child:IsA("WrapTarget") then
            child:Destroy()
        elseif child:IsA("WrapLayer") then
            child.Enabled = false
        end
    end
    head.ChildAdded:Connect(function(child)
        if child:IsA("Decal") then
            child.Transparency = 1
        elseif child:IsA("SpecialMesh") then
            child.Scale = Vector3.new(0, 0, 0)
        elseif child:IsA("SurfaceAppearance") or child:IsA("WrapTarget") then
            child:Destroy()
        elseif child:IsA("WrapLayer") then
            child.Enabled = false
        end
    end)
end

local function applyKorbloxR15(char)
    local upper = char:WaitForChild("RightUpperLeg", 8)
    local lower = char:WaitForChild("RightLowerLeg", 8)
    local foot = char:WaitForChild("RightFoot", 8)

    if not (upper and lower and foot) then return end

    lockTransparency(upper)
    lockTransparency(lower)
    lockTransparency(foot)

    for _, part in ipairs({upper, lower, foot}) do
        for _, child in ipairs(part:GetChildren()) do
            if child:IsA("SurfaceAppearance") or child:IsA("WrapTarget") then
                child:Destroy()
            elseif child:IsA("WrapLayer") then
                child.Enabled = false
            end
        end
    end

    local oldVisual = upper:FindFirstChild("KorbloxVisualPart")
    if oldVisual then
        oldVisual:Destroy()
    end

    local korbloxPart = Instance.new("Part")
    korbloxPart.Name = "KorbloxVisualPart"
    korbloxPart.CanCollide = false
    korbloxPart.CanTouch = false
    korbloxPart.CanQuery = false
    korbloxPart.Massless = true
    korbloxPart.CFrame = upper.CFrame

    local mesh = Instance.new("SpecialMesh")
    mesh.MeshType = Enum.MeshType.FileMesh
    mesh.MeshId = "rbxassetid://902942096"
    mesh.TextureId = "rbxassetid://902843398"
    mesh.Scale = Vector3.new(1, 1, 1)
    mesh.Parent = korbloxPart

    local weld = Instance.new("Weld")
    weld.Part0 = upper
    weld.Part1 = korbloxPart
    weld.C0 = CFrame.new(0, 0, 0)
    weld.C1 = CFrame.new(0, 0, 0)
    weld.Parent = korbloxPart

    korbloxPart.Parent = upper
end

local function applyKorbloxR6(char)
    local rightLeg = char:WaitForChild("Right Leg", 8)
    if not rightLeg then return end

    for _, child in ipairs(char:GetChildren()) do
        if child:IsA("CharacterMesh") and child.BodyPart == Enum.BodyPart.RightLeg then
            child:Destroy()
        end
    end

    for _, child in ipairs(rightLeg:GetChildren()) do
        if child:IsA("SpecialMesh") or child:IsA("CharacterMesh") or child:IsA("SurfaceAppearance") or child:IsA("WrapTarget") then
            child:Destroy()
        end
    end

    pcall(function()
        local charMesh = Instance.new("CharacterMesh")
        charMesh.MeshId = 101851696
        charMesh.BodyPart = Enum.BodyPart.RightLeg
        charMesh.Parent = char
    end)

    pcall(function()
        local specialMesh = Instance.new("SpecialMesh")
        specialMesh.MeshType = Enum.MeshType.FileMesh
        specialMesh.MeshId = "http://www.roblox.com/asset/?id=101851696"
        specialMesh.TextureId = "http://www.roblox.com/asset/?id=101851254"
        specialMesh.Scale = Vector3.new(1, 1, 1)
        specialMesh.Parent = rightLeg
    end)
end

local function attachSingleAccessory(char, assetId)
    local tag = "CustomAcc_" .. tostring(assetId)
    local old = char:FindFirstChild(tag)
    if old then
        old:Destroy()
    end

    local success, asset = pcall(function()
        return game:GetObjects("rbxassetid://" .. tostring(assetId))[1]
    end)

    if not success or not asset then return end

    asset.Name = tag
    local handle = asset:FindFirstChild("Handle")
    local head = char:WaitForChild("Head", 8)
    if not handle or not head then return end

    handle.CanCollide = false
    handle.Massless = true
    asset.Parent = char

    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        pcall(function()
            humanoid:AddAccessory(asset)
        end)
    end

    local existingWeld = handle:FindFirstChildOfClass("Weld") or handle:FindFirstChildOfClass("WeldConstraint")
    if not existingWeld then
        local handleAtt = handle:FindFirstChildOfClass("Attachment")
        local targetPart = head
        local targetAtt = nil

        if handleAtt then
            local found = char:FindFirstChild(handleAtt.Name, true)
            if found and found:IsA("Attachment") and found.Parent and found.Parent:IsA("BasePart") then
                targetPart = found.Parent
                targetAtt = found
            end
        end

        local weld = Instance.new("Weld")
        weld.Name = "AccessoryWeld"
        weld.Part0 = targetPart
        weld.Part1 = handle
        if handleAtt and targetAtt then
            weld.C0 = targetAtt.CFrame
            weld.C1 = handleAtt.CFrame
        else
            weld.C0 = CFrame.new(0, 0.6, 0)
        end
        weld.Parent = handle
    end
end

local function applyAccessories(char)
    for _, id in ipairs(ACCESSORY_IDS) do
        task.spawn(attachSingleAccessory, char, id)
    end
end

local function applyCosmetics(char)
    if not char then return end
    local humanoid = char:WaitForChild("Humanoid", 10)
    if not humanoid then return end

    local head = char:WaitForChild("Head", 10)
    if head then
        cleanHead(head)
    end

    task.wait(0.1)

    if humanoid.RigType == Enum.HumanoidRigType.R15 then
        applyKorbloxR15(char)
    else
        applyKorbloxR6(char)
    end

    applyAccessories(char)
end

if localPlayer.Character then
    task.spawn(applyCosmetics, localPlayer.Character)
end

localPlayer.CharacterAdded:Connect(function(char)
    task.spawn(applyCosmetics, char)
end)
