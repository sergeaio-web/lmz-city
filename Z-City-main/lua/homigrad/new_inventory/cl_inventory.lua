if not CLIENT then return end

local type = type

local inventoryOpen = false
local selectedSlot = 1
local inventoryWeapons = {}
local inventoryAlpha = 0
local inventoryLastUpdate = 0
local inventoryCloseTime = 0

local numberKeys = {
    [KEY_1] = 1,
    [KEY_2] = 2,
    [KEY_3] = 3,
    [KEY_4] = 4,
    [KEY_5] = 5,
    [KEY_6] = 6,
    [KEY_7] = 7,
    [KEY_8] = 8,
    [KEY_9] = 9,
    [KEY_0] = 10
}

local colorBlack = Color(0, 0, 0, 230)
local colorPink = Color(255, 70, 170, 255)
local colorWhite = Color(255, 255, 255, 255)

local colorText = Color(245, 225, 240, 255)
local colorSubText = Color(180, 150, 175, 255)

local colorGrid = Color(255, 80, 180, 35)
local colorPanel = Color(8, 5, 10, 235)

local function IsInventoryEnabled()
    return GetGlobalBool("RadialInventory", false)
end

local function IsPlayerAvailable(ply)
    if not IsValid(ply) then return false end
    if not ply:Alive() then return false end

    local organism = ply.organism

    if organism and organism.otrub then
        return false
    end

    return true
end

local function GetPulseValue(offset, speed)
    local value = math.sin(RealTime() * speed + offset)
    return value * 0.5 + 0.5
end

local function GetPulseColor(offset, speed, alpha)
    local value = GetPulseValue(offset, speed)

    -- Чёрный -> розовый
    if value < 0.5 then
        local fraction = value * 2

        return Color(
            Lerp(fraction, colorBlack.r, colorPink.r),
            Lerp(fraction, colorBlack.g, colorPink.g),
            Lerp(fraction, colorBlack.b, colorPink.b),
            alpha or 255
        )
    end

    -- Розовый -> белый
    local fraction = (value - 0.5) * 2

    return Color(
        Lerp(fraction, colorPink.r, colorWhite.r),
        Lerp(fraction, colorPink.g, colorWhite.g),
        Lerp(fraction, colorPink.b, colorWhite.b),
        alpha or 255
    )
end

local function GetWeaponIcon(wep)
    if not IsValid(wep) then return nil end

    if type(wep.WepSelectIcon) == "IMaterial" then
        return wep.WepSelectIcon
    end

    if type(wep.WepSelectIcon2) == "IMaterial" then
        return wep.WepSelectIcon2
    end

    return nil
end

local function UpdateInventoryWeapons()
    local ply = LocalPlayer()

    if not IsValid(ply) then return end

    inventoryWeapons = {}

    local weapons = ply:GetWeapons()

    for _, wep in ipairs(weapons) do
        if not IsValid(wep) then continue end

        inventoryWeapons[#inventoryWeapons + 1] = {
            weapon = wep,
            name = wep:GetPrintName() or wep:GetClass(),
            class = wep:GetClass(),
            icon = GetWeaponIcon(wep)
        }
    end

    table.sort(inventoryWeapons, function(a, b)
        return a.name < b.name
    end)
end

local function SelectWeapon(slot)
    local item = inventoryWeapons[slot]

    if not item then return end
    if not IsValid(item.weapon) then return end

    net.Start("NI_SelectWeapon")
        net.WriteEntity(item.weapon)
    net.SendToServer()

    if item.weapon ~= LocalPlayer():GetActiveWeapon() then
        surface.PlaySound(
            "arc9_eft_shared/weapon_generic_spin"
            .. math.random(10)
            .. ".ogg"
        )
    end
end

local function GetInventorySize()
    local slotCount = math.min(#inventoryWeapons, 10)

    if slotCount <= 0 then
        return 0, 0
    end

    local slotWidth = ScreenScale(70)
    local slotHeight = ScreenScale(67)
    local gap = ScreenScale(7)
    local padding = ScreenScale(12)

    local width =
        padding * 2
        + slotCount * slotWidth
        + math.max(slotCount - 1, 0) * gap

    local height = slotHeight + padding * 2

    return width, height
end

local function DrawMovingGrid(x, y, w, h, alpha)
    local cellSize = ScreenScale(24)
    local time = RealTime()

    local offsetX = (time * ScreenScale(8)) % cellSize
    local offsetY = (time * ScreenScale(5)) % cellSize

    surface.SetDrawColor(
        colorGrid.r,
        colorGrid.g,
        colorGrid.b,
        alpha
    )

    for gridX = -cellSize, w + cellSize, cellSize do
        surface.DrawRect(
            x + gridX + offsetX,
            y,
            ScreenScale(1),
            h
        )
    end

    for gridY = -cellSize, h + cellSize, cellSize do
        surface.DrawRect(
            x,
            y + gridY + offsetY,
            w,
            ScreenScale(1)
        )
    end
end

local function DrawInventorySlot(item, slot, x, y, w, h, alpha)
    local isSelected = selectedSlot == slot

    local pulse = GetPulseValue(slot * 0.8, 2.2)

    local backgroundColor

    if isSelected then
        backgroundColor = Color(
            Lerp(pulse, 25, 255),
            Lerp(pulse, 5, 90),
            Lerp(pulse, 20, 180),
            alpha
        )
    else
        backgroundColor = Color(
            5,
            3,
            8,
            alpha
        )
    end

    draw.RoundedBox(
        ScreenScale(5),
        x,
        y,
        w,
        h,
        backgroundColor
    )

    local borderColor

    if isSelected then
        borderColor = GetPulseColor(slot * 0.7, 2.5, alpha)
    else
        borderColor = Color(90, 30, 70, alpha)
    end

    surface.SetDrawColor(
        borderColor.r,
        borderColor.g,
        borderColor.b,
        borderColor.a
    )

    surface.DrawOutlinedRect(
        x,
        y,
        w,
        h,
        isSelected and ScreenScale(2) or 1
    )

    local numberColor = isSelected
        and GetPulseColor(slot, 2.8, alpha)
        or colorSubText

    draw.SimpleText(
        slot == 10 and "0" or tostring(slot),
        "ZCity_Tiny",
        x + ScreenScale(7),
        y + ScreenScale(5),
        numberColor,
        TEXT_ALIGN_LEFT,
        TEXT_ALIGN_TOP
    )

    local icon = item.icon

    if icon then
        surface.SetMaterial(icon)
        surface.SetDrawColor(255, 255, 255, alpha)

        surface.DrawTexturedRect(
            x + ScreenScale(13),
            y + ScreenScale(18),
            w - ScreenScale(26),
            h - ScreenScale(34)
        )
    else
        local shortName = string.upper(
            string.sub(item.name or item.class or "ITEM", 1, 3)
        )

        draw.SimpleText(
            shortName,
            "ZCity_Tiny",
            x + w / 2,
            y + h / 2,
            GetPulseColor(slot, 2.2, alpha),
            TEXT_ALIGN_CENTER,
            TEXT_ALIGN_CENTER
        )
    end

    local name = item.name or item.class or "Unknown"

    if #name > 16 then
        name = string.sub(name, 1, 15) .. "..."
    end

    draw.SimpleText(
        name,
        "ZCity_Tiny",
        x + w / 2,
        y + h - ScreenScale(8),
        isSelected and colorText or colorSubText,
        TEXT_ALIGN_CENTER,
        TEXT_ALIGN_BOTTOM
    )

    if isSelected then
        local lineColor = GetPulseColor(slot + 2, 3, alpha)

        surface.SetDrawColor(
            lineColor.r,
            lineColor.g,
            lineColor.b,
            lineColor.a
        )

        surface.DrawRect(
            x + ScreenScale(7),
            y + h - ScreenScale(3),
            w - ScreenScale(14),
            ScreenScale(2)
        )
    end
end

local function DrawInventoryHUD()
    if not inventoryOpen then return end

    local width, height = GetInventorySize()

    if width <= 0 then return end

    local screenWidth = ScrW()
    local x = (screenWidth - width) / 2
    local y = ScreenScale(24)

    local backgroundAlpha = math.Clamp(inventoryAlpha, 0, 255)

    local panelColor = Color(
        colorPanel.r,
        colorPanel.g,
        colorPanel.b,
        backgroundAlpha
    )

    draw.RoundedBox(
        ScreenScale(8),
        x,
        y,
        width,
        height,
        panelColor
    )

    DrawMovingGrid(
        x,
        y,
        width,
        height,
        math.min(backgroundAlpha, 80)
    )

    local borderColor = GetPulseColor(0, 1.4, backgroundAlpha)

    surface.SetDrawColor(
        borderColor.r,
        borderColor.g,
        borderColor.b,
        borderColor.a
    )

    surface.DrawOutlinedRect(
        x,
        y,
        width,
        height,
        ScreenScale(2)
    )

    local slotWidth = ScreenScale(70)
    local slotHeight = ScreenScale(67)
    local gap = ScreenScale(7)
    local padding = ScreenScale(12)

    for slot, item in ipairs(inventoryWeapons) do
        if slot > 10 then break end

        local slotX =
            x
            + padding
            + (slot - 1) * (slotWidth + gap)

        local slotY = y + padding

        DrawInventorySlot(
            item,
            slot,
            slotX,
            slotY,
            slotWidth,
            slotHeight,
            backgroundAlpha
        )
    end
end

hook.Add("Think", "NI_TopInventoryThink", function()
    local ply = LocalPlayer()

    if not IsPlayerAvailable(ply) then
        inventoryOpen = false
        inventoryAlpha = Lerp(FrameTime() * 12, inventoryAlpha, 0)
        return
    end

    if CurTime() - inventoryLastUpdate > 0.15 then
        UpdateInventoryWeapons()
        inventoryLastUpdate = CurTime()
    end

    local targetAlpha = inventoryOpen and 255 or 0

    inventoryAlpha = Lerp(
        FrameTime() * 14,
        inventoryAlpha,
        targetAlpha
    )

    if not inventoryOpen and inventoryAlpha < 1 then
        inventoryAlpha = 0
    end
end)

hook.Add("HUDPaint", "NI_TopInventoryHUD", function()
    DrawInventoryHUD()
end)

hook.Add("HUDShouldDraw", "NI_HideDefaultWeaponSelection", function(name)
    if inventoryOpen and name == "CHudWeaponSelection" then
        return false
    end
end)

hook.Add("PlayerButtonDown", "NI_TopInventoryButtonDown", function(ply, key)
    if ply ~= LocalPlayer() then return end
    if not IsInventoryEnabled() then return end
    if not IsPlayerAvailable(ply) then return end

    local slot = numberKeys[key]

    if not slot then return end

    UpdateInventoryWeapons()

    selectedSlot = math.min(
        slot,
        math.max(#inventoryWeapons, 1)
    )

    inventoryOpen = true
    inventoryCloseTime = CurTime() + 0.15
end)

hook.Add("PlayerButtonUp", "NI_TopInventoryButtonUp", function(ply, key)
    if ply ~= LocalPlayer() then return end
    if not IsInventoryEnabled() then return end

    local slot = numberKeys[key]

    if not slot then return end
    if not inventoryOpen then return end

    if CurTime() >= inventoryCloseTime then
        SelectWeapon(selectedSlot)
    end

    inventoryOpen = false
end)

hook.Add("HG_OnOtrub", "NI_CloseTopInventory", function(ply)
    if ply ~= LocalPlayer() then return end

    inventoryOpen = false
end)

hook.Add("PlayerDeath", "NI_CloseTopInventoryDeath", function(ply)
    if ply ~= LocalPlayer() then return end

    inventoryOpen = false
end)