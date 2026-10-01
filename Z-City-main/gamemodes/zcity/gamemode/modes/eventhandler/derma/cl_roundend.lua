-- Improved Round End Menu for Event Handler Mode

local PANEL = {}

-- Color definitions
local COLOR_ALIVE = Color(50, 180, 50, 255)      -- Green - Survived
local COLOR_DEAD = Color(100, 100, 100, 255)     -- Gray - Dead
local COLOR_WOUNDED = Color(80, 140, 80, 255)    -- Dark Green - Wounded
local COLOR_POLICE = Color(0, 100, 255, 255)     -- Blue - Police
local COLOR_KILLER = Color(255, 50, 50, 255)     -- Red - Killer/Murderer
local COLOR_CIVILIAN = Color(255, 100, 200, 255) -- Pink - Civilian
local COLOR_TEXT = Color(255, 255, 255, 255)     -- White text
local COLOR_SHADOW = Color(0, 0, 0, 150)         -- Black shadow

-- Background blur
local blurMat = Material("pp/blurscreen")
BlurBackground = BlurBackground or hg.DrawBlur

function PANEL:Init()
    local sw, sh = ScrW(), ScrH()
    
    -- Window size and position (centered, wider than current)
    local panelWidth = sw * 0.55   -- 55% of screen width
    local panelHeight = sh * 0.75  -- 75% of screen height
    local panelX = (sw - panelWidth) / 2
    local panelY = (sh - panelHeight) / 2
    
    self:SetPos(panelX, panelY)
    self:SetSize(panelWidth, panelHeight)
    self:SetTitle("Round Results")
    self:MakePopup()
    self:SetKeyboardInputEnabled(false)
    self:ShowCloseButton(false)
    
    -- Close button
    local closeBtn = vgui.Create("DButton", self)
    closeBtn:SetPos(panelWidth - 35, 5)
    closeBtn:SetSize(30, 30)
    closeBtn:SetText("✕")
    closeBtn:SetFont("ZB_InterfaceMedium")
    closeBtn.DoClick = function()
        self:Close()
    end
    
    -- Scroll panel for players
    local scroll = vgui.Create("DScrollPanel", self)
    scroll:SetPos(10, 100)
    scroll:SetSize(panelWidth - 20, panelHeight - 110)
    
    -- Customize scrollbar
    local vbar = scroll:GetVBar()
    vbar:SetWide(8)
    vbar.Paint = function(self, w, h)
        surface.SetDrawColor(80, 80, 80, 100)
        surface.DrawRect(0, 0, w, h)
    end
    vbar.btnGrip.Paint = function(self, w, h)
        surface.SetDrawColor(150, 150, 150, 200)
        surface.DrawRect(0, 0, w, h)
    end
    
    -- Store reference to scroll panel
    self.ScrollPanel = scroll
    
    -- Paint function
    function self:Paint(w, h)
        BlurBackground(self)
        
        -- Background
        surface.SetDrawColor(30, 30, 40, 220)
        surface.DrawRect(0, 0, w, h)
        
        -- Border
        surface.SetDrawColor(100, 100, 150, 255)
        surface.DrawOutlinedRect(0, 0, w, h, 2)
        
        -- Title bar
        surface.SetDrawColor(50, 50, 70, 255)
        surface.DrawRect(0, 0, w, 90)
        
        -- Winner text
        if self.WinnerName then
            surface.SetFont("ZB_InterfaceLarge")
            surface.SetTextColor(255, 215, 0, 255)  -- Gold
            local text = self.WinnerName .. " Won!"
            local textW, textH = surface.GetTextSize(text)
            surface.SetTextPos((w - textW) / 2, 15)
            surface.DrawText(text)
        end
        
        -- Mode text
        if self.ModeName then
            surface.SetFont("ZB_InterfaceMedium")
            surface.SetTextColor(200, 200, 200, 255)
            local text = "Mode: " .. self.ModeName
            local textW, textH = surface.GetTextSize(text)
            surface.SetTextPos((w - textW) / 2, 50)
            surface.DrawText(text)
        end
    end
end

function PANEL:SetWinner(winnerName, modeName)
    self.WinnerName = winnerName or "Nobody"
    self.ModeName = modeName or "Unknown Mode"
end

function PANEL:AddPlayer(ply, role, isAlive, isWounded)
    if not IsValid(self.ScrollPanel) then return end
    
    local playerPanel = vgui.Create("DPanel", self.ScrollPanel)
    playerPanel:SetSize(self.ScrollPanel:GetWide() - 15, 90)
    playerPanel:Dock(TOP)
    playerPanel:DockMargin(5, 5, 5, 5)
    
    -- Determine role color
    local roleColor = COLOR_CIVILIAN
    if string.lower(role):find("police") or string.lower(role):find("cop") then
        roleColor = COLOR_POLICE
    elseif string.lower(role):find("kill") or string.lower(role):find("murder") then
        roleColor = COLOR_KILLER
    elseif string.lower(role):find("civil") or string.lower(role):find("peace") then
        roleColor = COLOR_CIVILIAN
    end
    
    -- Determine status color
    local statusColor = COLOR_DEAD
    if isAlive then
        statusColor = isWounded and COLOR_WOUNDED or COLOR_ALIVE
    end
    
    -- Paint function
    function playerPanel:Paint(w, h)
        -- Background based on status
        surface.SetDrawColor(statusColor.r, statusColor.g, statusColor.b, 80)
        surface.DrawRect(0, 0, w, h)
        
        -- Border
        surface.SetDrawColor(statusColor.r, statusColor.g, statusColor.b, 200)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        
        -- Status indicator bar on the right
        local barWidth = 25
        surface.SetDrawColor(statusColor.r, statusColor.g, statusColor.b, 200)
        surface.DrawRect(w - barWidth, 0, barWidth, h)
        
        -- Status text
        local statusText = isAlive and (isWounded and "WOUNDED" or "ALIVE") or "DEAD"
        surface.SetFont("ZB_InterfaceSmall")
        surface.SetTextColor(255, 255, 255, 200)
        local textW, textH = surface.GetTextSize(statusText)
        surface.SetTextPos(w - barWidth + (barWidth - textW) / 2, h / 2 - textH / 2)
        surface.DrawText(statusText)
        
        -- Role line indicator at the top
        surface.SetDrawColor(roleColor.r, roleColor.g, roleColor.b, 255)
        surface.DrawRect(0, 0, w - barWidth, 3)
    end
    
    -- Avatar/Steam icon (clickable)
    local avatar = vgui.Create("DButton", playerPanel)
    avatar:SetPos(10, 10)
    avatar:SetSize(50, 50)
    avatar:SetText("")
    avatar.ply = ply
    avatar.DoClick = function()
        if IsValid(ply) and not ply:IsBot() then
            gui.OpenURL("https://steamcommunity.com/profiles/" .. ply:SteamID64())
        end
    end
    avatar.Paint = function(self, w, h)
        -- Avatar background
        surface.SetDrawColor(50, 50, 60, 200)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(100, 100, 120, 255)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        
        -- Player avatar
        if IsValid(ply) then
            surface.SetMaterial(ply:GetAvatarMaterial("medium"))
            surface.SetDrawColor(255, 255, 255, 255)
            surface.DrawTexturedRect(2, 2, w - 4, h - 4)
        end
        
        -- Hover effect
        if self:IsHovered() then
            surface.SetDrawColor(150, 150, 200, 100)
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(150, 150, 200, 255)
            surface.DrawOutlinedRect(0, 0, w, h, 2)
        end
    end
    
    -- Player name
    local nameLabel = vgui.Create("DLabel", playerPanel)
    nameLabel:SetPos(70, 10)
    nameLabel:SetSize(200, 25)
    nameLabel:SetText(ply:GetPlayerName())
    nameLabel:SetFont("ZB_InterfaceMedium")
    nameLabel:SetTextColor(255, 255, 255, 255)
    
    -- Frags display
    local fragsLabel = vgui.Create("DLabel", playerPanel)
    fragsLabel:SetPos(playerPanel:GetWide() - 80, 10)
    fragsLabel:SetSize(70, 25)
    fragsLabel:SetText("Frags: " .. (ply:Frags() or 0))
    fragsLabel:SetFont("ZB_InterfaceSmall")
    fragsLabel:SetTextColor(255, 200, 100, 255)
    fragsLabel:SetContentAlignment(TEXT_ALIGN_RIGHT)
    
    -- Role display with colored indicator
    local roleLabel = vgui.Create("DLabel", playerPanel)
    roleLabel:SetPos(70, 40)
    roleLabel:SetSize(200, 20)
    roleLabel:SetText(role)
    roleLabel:SetFont("ZB_InterfaceSmall")
    roleLabel:SetTextColor(roleColor.r, roleColor.g, roleColor.b, 255)
    
    -- Deaths display
    local deathsLabel = vgui.Create("DLabel", playerPanel)
    deathsLabel:SetPos(playerPanel:GetWide() - 80, 40)
    deathsLabel:SetSize(70, 20)
    deathsLabel:SetText("Deaths: " .. (ply:Deaths() or 0))
    deathsLabel:SetFont("ZB_InterfaceSmall")
    deathsLabel:SetTextColor(200, 100, 100, 255)
    deathsLabel:SetContentAlignment(TEXT_ALIGN_RIGHT)
    
    -- Steam ID display
    local steamLabel = vgui.Create("DLabel", playerPanel)
    steamLabel:SetPos(70, 60)
    steamLabel:SetSize(playerPanel:GetWide() - 90, 20)
    steamLabel:SetText("ID: " .. ply:SteamID())
    steamLabel:SetFont("ZB_InterfaceTiny")
    steamLabel:SetTextColor(150, 150, 150, 200)
end

function PANEL:PopulateFromGame()
    for _, ply in player.Iterator() do
        if ply:Team() == TEAM_SPECTATOR then continue end
        
        local role = "Civilian"
        local isAlive = ply:Alive()
        local isWounded = false
        
        -- Try to detect role (example for common gamemodes)
        if ply:GetNetVar("Role") then
            role = ply:GetNetVar("Role")
        elseif ply:GetTeam() == 1 then
            role = "Police"
        elseif ply:GetTeam() == 2 then
            role = "Killer"
        end
        
        -- Check if wounded
        if ply.organism and ply.organism.incapacitated then
            isWounded = true
        end
        
        self:AddPlayer(ply, role, isAlive, isWounded)
    end
end

function PANEL:Close()
    self:AlphaTo(0, 0.2, 0, function()
        self:Remove()
    end)
end

vgui.Register("ZB_RoundEndPanel", PANEL, "ZFrame")

-- Initialize and show the panel
function OpenRoundEndMenu(winnerName, modeName)
    if IsValid(zb.RoundEndPanel) then
        zb.RoundEndPanel:Remove()
    end
    
    zb.RoundEndPanel = vgui.Create("ZB_RoundEndPanel")
    zb.RoundEndPanel:SetWinner(winnerName or "Nobody", modeName or "Event")
    zb.RoundEndPanel:PopulateFromGame()
    
    return zb.RoundEndPanel
end
