zb = zb or {}
include("shared.lua")
include("loader.lua")

if not ConVarExists("hg_newspectate") then
    CreateClientConVar("hg_newspectate", "1", true, false, "Enables smooth spectator camera transitions", 0, 1)
end

function CurrentRound()
	return zb.modes[zb.CROUND]
end

zb.ROUND_STATE = 0
--0 = players can join, 1 = round is active, 2 = endround
local vecZero = Vector(0.2, 0.2, 0.2)
local vecFull = Vector(1, 1, 1)
spect,prevspect,viewmode = nil,nil,1
local hullscale = Vector(0,0,0)
net.Receive("ZB_SpectatePlayer", function(len)
	spect = net.ReadEntity()
	prevspect = net.ReadEntity()
	viewmode = net.ReadInt(4)

	timer.Simple(0.1,function()
		-- LocalPlayer():BoneScaleChange()
		LocalPlayer():SetHull(-hullscale,hullscale)
		LocalPlayer():SetHullDuck(-hullscale,hullscale)

		if viewmode == 3 then
			LocalPlayer():SetMoveType(MOVETYPE_NOCLIP)
		end
	end)
end)

zb.ROUND_TIME = zb.ROUND_TIME or 400
zb.ROUND_START = zb.ROUND_START or CurTime()
zb.ROUND_BEGIN = zb.ROUND_BEGIN or CurTime() + 5

net.Receive("updtime",function()
	local time = net.ReadFloat()
	local time2 = net.ReadFloat()
	local time3 = net.ReadFloat()

	zb.ROUND_TIME = time
	zb.ROUND_START = time2
	zb.ROUND_BEGIN = time3
end)

local blur = Material("pp/blurscreen")
local blur2 = Material("effects/shaders/zb_blur" )
local blursettings = {}
local hg_potatopc
hg = hg or {}
function hg.DrawBlur(panel, amount, passes, alpha)
	if is3d2d then return end
	amount = amount or 5
	hg_potatopc = hg_potatopc or hg.ConVars.potatopc

	// old blur
	if(hg_potatopc:GetBool())then
		surface.SetDrawColor(0, 0, 0, alpha or (amount * 20))
		surface.DrawRect(0, 0, panel:GetWide(), panel:GetTall())
	else
		surface.SetMaterial(blur)
		surface.SetDrawColor(0, 0, 0, alpha or 125)
		surface.DrawRect(0, 0, panel:GetWide(), panel:GetTall())
		local x, y = panel:LocalToScreen(0, 0)
		if blursettings and blursettings[1] == amount and blursettings[2] == passes then
			render.UpdateScreenEffectTexture()
			surface.DrawTexturedRect(x * -1, y * -1, ScrW(), ScrH())
			return
		end
		blursettings = {amount, passes}
		for i = -(passes or 0.2), 1, 0.2 do
			blur:SetFloat("$blur", i * amount)
			blur:Recompute()

			render.UpdateScreenEffectTexture()
			surface.DrawTexturedRect(x * -1, y * -1, ScrW(), ScrH())
		end
	end

	--surface.SetMaterial(blur2)
	--surface.SetDrawColor(color_white)
	--local x, y = panel:LocalToScreen(0, 0)
--
	--// those are currently hardcoded cuz it would be too much of a hassle to change this
	--blur2:SetFloat("$c0_x", (amount or 5) * 2500) // density
	--blur2:SetFloat("$c0_y", (passes or 0.2) * 2000) // noise (inverted)
	--blur2:SetFloat("$c0_z", 1) // blending
--
	--render.UpdateScreenEffectTexture()
	--surface.DrawTexturedRect(x * -1, y * -1, ScrW(), ScrH())

	-- surface.SetDrawColor(0, 0, 0, alpha or 125)
	-- surface.DrawRect(0, 0, panel:GetWide(), panel:GetTall())
end

BlurBackground = BlurBackground or hg.DrawBlur

local keydownattack
local keydownattack2
local keydownreload

hook.Add("HUDPaint","FUCKINGSAMENAMEUSEDINHOOKFUCKME",function()
    if LocalPlayer():Alive() then return end
	local spect = LocalPlayer():GetNWEntity("spect")
	if not IsValid(spect) then return end
	if viewmode == 3 then return end
	
	surface.SetFont("HomigradFont")
	surface.SetTextColor(255, 255, 255, 255)
	local txt = "Spectating player: "..spect:Name()
	local w, h = surface.GetTextSize(txt)
	surface.SetTextPos(ScrW() / 2 - w / 2, ScrH() / 8 * 7)
	surface.DrawText(txt)
	local txt = "In-game name: "..spect:GetPlayerName()
	local w, h = surface.GetTextSize(txt)
	surface.SetTextPos(ScrW() / 2 - w / 2, ScrH() / 8 * 7 + h)
	surface.DrawText(txt)
end)

hook.Add("HG_CalcView", "zzzzzzzUwU", function(ply, pos, angles, fov)
	if not lply:Alive() then
		if lply:KeyDown(IN_ATTACK) then
			if not keydownattack then
				keydownattack = true
				net.Start("ZB_ChooseSpecPly")
				net.WriteInt(IN_ATTACK,32)
				net.SendToServer()
			end
		else
			keydownattack = false
		end

		if lply:KeyDown(IN_ATTACK2) then
			if not keydownattack2 then
				keydownattack2 = true
				net.Start("ZB_ChooseSpecPly")
				net.WriteInt(IN_ATTACK2,32)
				net.SendToServer()
			end
		else
			keydownattack2 = false
		end

		if lply:KeyDown(IN_RELOAD) then
			if not keydownreload then
				keydownreload = true
				net.Start("ZB_ChooseSpecPly")
				net.WriteInt(IN_RELOAD,32)
				net.SendToServer()
			end
		else
			keydownreload = false
		end

		local spect = lply:GetNWEntity("spect",spect)
		if not IsValid(spect) then return end

		local viewmode = lply:GetNWInt("viewmode",viewmode)
		
		if viewmode == 3 then
			if lply:GetMoveType()!=MOVETYPE_NOCLIP then
				lply:SetMoveType(MOVETYPE_NOCLIP)
			end
			lply:SetObserverMode(OBS_MODE_ROAMING)
			return
		else
			lply:SetPos(spect:GetPos())
		end
		
		local ent = hg.GetCurrentCharacter(spect)
		if not IsValid(ent) then return end
		
		local headBone = ent:LookupBone("ValveBiped.Bip01_Head1") or ent:LookupBone("ValveBiped.Bip01_Spine1") or 1
		local bon = ent:GetBoneMatrix(headBone)
		
		if not bon then 
			local eyePos = ent:EyePos()
			if eyePos and eyePos ~= vector_origin then
				pos = eyePos
				ang = ent:EyeAngles()
			else
				pos = ent:GetPos() + Vector(0, 0, 64)
				ang = ent:GetAngles()
			end
		else
			pos, ang = bon:GetTranslation(), bon:GetAngles()
		end

		local eyePos, eyeAng = lply:EyePos(), lply:EyeAngles()
		
		local tr = {}
		tr.start = pos
		tr.endpos = pos + eyeAng:Forward() * -120
		tr.filter = {ent, lply, spect}
		tr.mins = Vector(-4, -4, -4)
		tr.maxs = Vector(4, 4, 4)
		tr = util.TraceHull(tr)

		if viewmode == 2 then
			pos = tr.HitPos + eyeAng:Forward() * 8
			ang = eyeAng
		elseif viewmode == 1 then
			if ent ~= spect and IsValid(ent) then
				local eyeAtt = ent:GetAttachment(ent:LookupAttachment("eyes"))
				if eyeAtt then
					ang = eyeAtt.Ang
				else
					ang = spect:EyeAngles()
				end
			else
				ang = spect:EyeAngles()
			end
			pos = pos + spect:EyeAngles():Forward() * 8
		else
			pos = eyePos
			ang = eyeAng
		end
		
		ang[3] = 0
		
		local view
		local hg_newspectate = GetConVar("hg_newspectate")
		if hg_newspectate and hg_newspectate:GetBool() then
			if not lply.spectLastPos then
				lply.spectLastPos = pos
				lply.spectLastAng = ang
			end
			
			local lerpFactor = FrameTime() * 10
			lply.spectLastPos = LerpVector(lerpFactor, lply.spectLastPos, pos)
			lply.spectLastAng = LerpAngle(lerpFactor, lply.spectLastAng, ang)

			view = {
				origin = lply.spectLastPos,
				angles = lply.spectLastAng,
				fov = fov,
			}
		else
			view = {
				origin = pos,
				angles = ang,
				fov = fov,
			}
		end

		return view
	else
		lply.spectLastPos = nil
		lply.spectLastAng = nil
		lply:SetObserverMode(OBS_MODE_NONE)
	end
end)

zb.fade = zb.fade or 0

hook.Add("RenderScreenspaceEffects", "huyhuyUwU", function()
	if zb.fade > 0 then
		zb.fade = math.Approach(zb.fade, 0, FrameTime() * 1)

		surface.SetDrawColor(0, 0, 0, 255 * math.min(zb.fade, 1))
		surface.DrawRect(-1, -1, ScrW() + 1, ScrH() + 1 )
	end
end)

zb.ROUND_STATE = 0
net.Receive("RoundInfo", function()
	local rnd = net.ReadString()
	
	hook.Run("RoundInfoCalled", rnd)

	if zb.CROUND ~= rnd then
		if hg.DynaMusic then
			hg.DynaMusic:Stop()
		end
	end

	zb.CROUND = rnd

	zb.ROUND_STATE = net.ReadInt(4)
	
	if zb.ROUND_STATE == 0 then
		zb.fade = 7
	end

	if zb.CROUND ~= "" then
		if CurrentRound() then
			if zb.ROUND_STATE == 3 then
				if CurrentRound().EndRound then
					CurrentRound():EndRound()
				end
			elseif zb.ROUND_STATE == 1 then
				if CurrentRound().RoundStart then
					CurrentRound():RoundStart()
				end
			end
		end
	end
end)

if IsValid(scoreBoardMenu) then
	scoreBoardMenu:Remove()
	scoreBoardMenu = nil
end

hook.Add("Player Disconnected","retrymenu",function(data)
	if IsValid(scoreBoardMenu) then
		scoreBoardMenu:Remove()
		scoreBoardMenu = nil
	end
end)

--local hg_coolvetica = ConVarExists("hg_coolvetica") and GetConVar("hg_coolvetica") or CreateClientConVar("hg_coolvetica", "0", true, false, "changes every text to coolvetica because its good", 0, 1)
local hg_font = ConVarExists("hg_font") and GetConVar("hg_font") or CreateClientConVar("hg_font", "Bahnschrift", true, false, "Change UI text font")
local font = function() -- hg_coolvetica:GetBool() and "Coolvetica" or "Bahnschrift"
    local usefont = "Bahnschrift"

    if hg_font:GetString() != "" then
        usefont = hg_font:GetString()
    end

    return usefont
end

surface.CreateFont("ZB_InterfaceSmall", {
    font = font(),
    size = ScreenScale(6),
    weight = 400,
    antialias = true,
	extended = true
})

surface.CreateFont("ZB_InterfaceMedium", {
    font = font(),
    size = ScreenScale(10),
    weight = 400,
    antialias = true,
	extended = true
})

surface.CreateFont("ZB_ScrappersMedium", {
    font = font(),
    size = ScreenScale(10),
    weight = 400,
    antialias = true,
	extended = true
})

surface.CreateFont("ZB_InterfaceMediumLarge", {
    font = font(),
    size = 35,
    weight = 400,
    antialias = true,
	extended = true
})

surface.CreateFont("ZB_InterfaceLarge", {
    font = font(),
    size = ScreenScale(20),
    weight = 400,
    antialias = true,
	extended = true
})

surface.CreateFont("ZB_InterfaceHumongous", {
    font = font(),
    size = 200,
    weight = 400,
    antialias = true,
	extended = true
})

hg.playerInfo = hg.playerInfo or {}

local function addToPlayerInfo(ply, muted, volume)
	hg.playerInfo[ply:SteamID()] = {muted and true or false, volume}

	local json = util.TableToJSON(hg.playerInfo)
	file.Write("zcity_muted.txt", json)

	if file.Exists("zcity_muted.txt", "DATA") then
		local json = file.Read("zcity_muted.txt", "DATA")

		if json then
			hg.playerInfo = util.JSONToTable(json)
		end
	end

	//PrintTable(hg.playerInfo)
end

gameevent.Listen("player_connect")
hook.Add("player_connect", "zcityhuy", function(data)
	local ply = Player(data.userid)
	if IsValid(ply) and ply.SetMuted and hg.playerInfo and hg.playerInfo[data.networkid] then
		ply:SetMuted(hg.playerInfo[data.networkid][1])
		ply:SetVoiceVolumeScale(hg.playerInfo[data.networkid][2])
	end
end)

hook.Add("InitPostEntity", "furryhuy", function()
	if file.Exists("zcity_muted.txt", "DATA") then
		local json = file.Read("zcity_muted.txt", "DATA")

		if json then
			hg.playerInfo = util.JSONToTable(json)
		end

		if hg.playerInfo then
			for i, ply in player.Iterator() do
				if not istable(hg.playerInfo[ply:SteamID()]) then
					local muted = hg.playerInfo[ply:SteamID()]
					hg.playerInfo[ply:SteamID()] = {}
					hg.playerInfo[ply:SteamID()][1] = muted
					hg.playerInfo[ply:SteamID()][2] = 1
				end//compatibility with old json

				if hg.playerInfo[ply:SteamID()] then
					ply:SetMuted(hg.playerInfo[ply:SteamID()][1])
					ply:SetVoiceVolumeScale(hg.playerInfo[ply:SteamID()][2])
				end
			end	
		end
	end
end)

local colGray = Color(122,122,122,255)
local colBlue = Color(130,10,10)
local colBlueUp = Color(160,30,30)
local col = Color(255,255,255,255)

local colSpect1 = Color(75,75,75,255)
local colSpect2 = Color(85,85,85,255)

local colorBG = Color(55,55,55,255)
local colorBGBlacky = Color(40,40,40,255)

hg.muteall = false
hg.mutespect = false

local function OpenPlayerSoundSettings(selfa, ply)
	local Menu = DermaMenu()
	
	if not hg.playerInfo[ply:SteamID()] or not istable(hg.playerInfo[ply:SteamID()]) then addToPlayerInfo(ply, false, 1) end

	local mute = Menu:AddOption( "Mute", function(self)
		if hg.muteall || hg.mutespect then return end
		
		self:SetChecked(not ply:IsMuted())
		ply:SetMuted( not ply:IsMuted() )
		selfa:SetImage(not ply:IsMuted() && "icon16/sound.png" || "icon16/sound_mute.png")
		addToPlayerInfo(ply, ply:IsMuted(), hg.playerInfo[ply:SteamID()][2])
	end ) -- get your stupid one line ass outta here

	mute:SetIsCheckable( true )
	mute:SetChecked( ply:IsMuted() )
	local volumeSlider = vgui.Create("DSlider", Menu)
	volumeSlider:SetLockY( 0.5 )
	volumeSlider:SetTrapInside( true )
	volumeSlider:SetSlideX(hg.playerInfo[ply:SteamID()][2]) 
	volumeSlider.OnValueChanged = function(self, x, y)
		if not IsValid(ply) then return end
		if hg.muteall or (hg.mutespect && !ply:Alive()) then return end
		hg.playerInfo[ply:SteamID()][2] = x
		ply:SetVoiceVolumeScale(hg.playerInfo[ply:SteamID()][2])
		addToPlayerInfo(ply, ply:IsMuted(), hg.playerInfo[ply:SteamID()][2])
	end

	function volumeSlider:Paint(w,h)
		draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0 ) )
		draw.RoundedBox( 0, 0, 0, w*self:GetSlideX(), h, Color( 255, 0, 0 ) )
		draw.DrawText( ( math.Round( 100*self:GetSlideX(), 0 ) ).."%", "DermaDefault", w/2, h/4, color_white, TEXT_ALIGN_CENTER )
	end
	function volumeSlider.Knob.Paint(self) end

	Menu:AddPanel(volumeSlider)
	Menu:Open()
end



hook.Add("Player Getup", "nomorespect", function(ply)
	if not hg.mutespect then return end

	//ply:SetMuted(ply.oldmutedspect)
	ply:SetVoiceVolumeScale(!hg.muteall and (hg.playerInfo[ply:SteamID()] and hg.playerInfo[ply:SteamID()][2] or 1) or 0)
	//ply.oldmutedspect = nil

	//if IsValid(ply.soundButton) then
		//ply.soundButton:SetImage(not ply:IsMuted() && "icon16/sound.png" || "icon16/sound_mute.png")
	//end
end)

hook.Add("Player_Death", "fixSpectatorVoiceMute", function(ply)
	if not hg.mutespect then return end

	//ply.oldmutedspect = ply:IsMuted()
	//ply:SetMuted(hg.mutespect)
	ply:SetVoiceVolumeScale(0)
	//if IsValid(ply.soundButton) then
		//ply.soundButton:SetImage(not ply:IsMuted() && "icon16/sound.png" || "icon16/sound_mute.png")
	//end
end)

hook.Add("Player_Death", "fixSpectatorVoiceEffect", function(ply)
	if eightbit and eightbit.EnableEffect and ply.UserID then
		eightbit.EnableEffect(ply:UserID(), 0)
	end
end)

local SCOREBOARD_PINK = Color(255, 70, 185)
local SCOREBOARD_WHITE = Color(255, 255, 255)
local SCOREBOARD_GRAY = Color(150, 150, 150)
local SCOREBOARD_DARK = Color(15, 15, 15)

local function ScoreboardAnimatedColor(offset, speed)
	speed = speed or 1
	local progress = (math.sin(CurTime() * speed + offset) + 1) * 0.5

	return Color(
		Lerp(progress, SCOREBOARD_GRAY.r, SCOREBOARD_PINK.r),
		Lerp(progress, SCOREBOARD_GRAY.g, SCOREBOARD_PINK.g),
		Lerp(progress, SCOREBOARD_GRAY.b, SCOREBOARD_PINK.b),
		255
	)
end

local function ScoreboardOutlineColor(offset)
	local progress = (math.sin(CurTime() * 1.8 + offset) + 1) * 0.5

	return Color(
		Lerp(progress, 15, SCOREBOARD_PINK.r),
		Lerp(progress, 15, SCOREBOARD_PINK.g),
		Lerp(progress, 15, SCOREBOARD_PINK.b),
		235
	)
end

local function DrawScoreboardOutline(x, y, w, h, thickness)
	thickness = thickness or 2

	surface.SetDrawColor(ScoreboardOutlineColor(x * 0.01 + y * 0.01))

	for i = 0, thickness - 1 do
		surface.DrawOutlinedRect(
			x + i,
			y + i,
			w - i * 2,
			h - i * 2
		)
	end
end

local function DrawScoreboardGradientText(text, fontName, x, y, offset, alignX, alignY)
	text = tostring(text or "")
	surface.SetFont(fontName)

	local fullWidth, fullHeight = surface.GetTextSize(text)
	local drawX = x

	if alignX == TEXT_ALIGN_CENTER then
		drawX = x - fullWidth * 0.5
	elseif alignX == TEXT_ALIGN_RIGHT then
		drawX = x - fullWidth
	end

	local characterCount = utf8.len(text) or 0

	for i = 1, characterCount do
		local character = utf8.sub(text, i, i)

		if character and character ~= "" then
			local characterWidth = surface.GetTextSize(character)

			draw.SimpleText(
				character,
				fontName,
				drawX,
				y,
				ScoreboardAnimatedColor(offset + i * 0.12, 1.7),
				TEXT_ALIGN_LEFT,
				alignY or TEXT_ALIGN_TOP
			)

			drawX = drawX + characterWidth
		end
	end
end

local function GetScoreboardPlayerRole(ply)
	if not IsValid(ply) then
		return ""
	end

	local userGroup = ""

	if ply.GetUserGroup then
		userGroup = string.lower(tostring(ply:GetUserGroup() or ""))
	end

	if userGroup == "superadmin"
	or userGroup == "super_admin"
	or userGroup == "super-admin"
	or ply:IsSuperAdmin() then
		return "SUPERADMIN"
	end

	if userGroup ~= ""
	and userGroup ~= "user"
	and userGroup ~= "guest" then
		return string.upper(userGroup)
	end

	if ply:IsAdmin() then
		return "ADMIN"
	end

	return ""
end

local function GetScoreboardPlayerName(ply)
	if not IsValid(ply) then
		return "Unknown"
	end

	local playerName = ply:Name() or "Unknown"
	local role = GetScoreboardPlayerRole(ply)

	if role ~= "" then
		playerName = playerName .. "  [" .. role .. "]"
	end

	return playerName
end

local function PaintScoreboardPlayer(button, ply, isSpectator)
	button.Paint = function(self, w, h)
		if not IsValid(ply) then
			return
		end

		local pulse = (math.sin(CurTime() * 1.4) + 1) * 0.5

		local backgroundColor

		if isSpectator then
			backgroundColor = Color(
				Lerp(pulse, 30, 85),
				Lerp(pulse, 30, 85),
				Lerp(pulse, 30, 85),
				245
			)
		else
			backgroundColor = Color(
				Lerp(pulse, 15, 75),
				Lerp(pulse, 5, 35),
				Lerp(pulse, 25, 100),
				245
			)
		end

		surface.SetDrawColor(backgroundColor)
		surface.DrawRect(0, 0, w, h)

		surface.SetDrawColor(ScoreboardOutlineColor(ply:EntIndex() * 0.25))
		surface.DrawRect(0, h - 2, w, 2)

		DrawScoreboardOutline(0, 0, w, h, 1)

		local textY = h * 0.5
		local playerFont = "ZB_InterfaceMediumLarge"

		DrawScoreboardGradientText(
			GetScoreboardPlayerName(ply),
			playerFont,
			15,
			textY,
			ply:EntIndex(),
			TEXT_ALIGN_LEFT,
			TEXT_ALIGN_CENTER
		)

		DrawScoreboardGradientText(
			tostring(ply:Ping() or 0),
			playerFont,
			w - 15,
			textY,
			ply:EntIndex() + 10,
			TEXT_ALIGN_RIGHT,
			TEXT_ALIGN_CENTER
		)
	end
end

local function AddScoreboardPlayer(parent, ply, isSpectator)
	local button = vgui.Create("DButton", parent)

	button:SetSize(100, ScreenScaleH(22))
	button:Dock(TOP)
	button:DockMargin(8, 6, 8, -1)
	button:SetText("")

	local soundButton = vgui.Create("DImageButton", button)

	soundButton:Dock(RIGHT)
	soundButton:SetSize(30, 0)
	soundButton:DockMargin(5, 10, 45, 10)

	soundButton:SetImage(
		not ply:IsMuted()
		and "icon16/sound.png"
		or "icon16/sound_mute.png"
	)

	soundButton.DoClick = function(self)
		OpenPlayerSoundSettings(self, ply)
	end

	ply.soundButton = soundButton

	PaintScoreboardPlayer(button, ply, isSpectator)

	function button:DoClick()
		if ply:IsBot() then
			chat.AddText(Color(255, 70, 185), "Ботов нельзя открыть в Steam.")
			return
		end

		gui.OpenURL("https://steamcommunity.com/profiles/" .. ply:SteamID64())
	end

	function button:DoRightClick()
		local menu = DermaMenu()

		menu:AddOption("Account", function()
			if zb.Experience and zb.Experience.AccountMenu then
				zb.Experience.AccountMenu(ply)
			end
		end)

		menu:AddOption("Copy SteamID", function()
			SetClipboardText(ply:SteamID())
		end)

		menu:Open()
	end

	parent:AddItem(button)

	return button
end

local function PaintScoreboardScrollPanel(panel)
	panel.Paint = function(self, w, h)
		surface.SetDrawColor(0, 0, 0, 150)
		surface.DrawRect(0, 0, w, h)

		DrawScoreboardOutline(0, 0, w, h, 2)
	end
end

function GM:ScoreboardShow()
	if IsValid(scoreBoardMenu) then
		scoreBoardMenu:Remove()
		scoreBoardMenu = nil
	end

	Dynamic = 0

	scoreBoardMenu = vgui.Create("ZFrame")

	local sizeX, sizeY = ScrW() / 1.3, ScrH() / 1.2
	local posX, posY = ScrW() / 2 - sizeX / 2, ScrH() / 2 - sizeY / 2

	scoreBoardMenu:SetPos(posX, posY)
	scoreBoardMenu:SetSize(sizeX, sizeY)
	scoreBoardMenu:MakePopup()
	scoreBoardMenu:SetKeyboardInputEnabled(false)
	scoreBoardMenu:ShowCloseButton(false)

	-- Mute all
	local muteAllButton = vgui.Create("DButton", scoreBoardMenu)
	local buttonW, buttonH = ScreenScale(30), ScreenScale(6)

	muteAllButton:SetPos(
		scoreBoardMenu:GetWide() - buttonW * 2.3,
		scoreBoardMenu:GetTall() - buttonH * 1.5
	)

	muteAllButton:SetSize(buttonW, buttonH)
	muteAllButton:SetText("")

	muteAllButton.Paint = function(self, w, h)
		surface.SetDrawColor(0, 0, 0, 150)
		surface.DrawRect(0, 0, w, h)

		DrawScoreboardOutline(0, 0, w, h, 2)

		DrawScoreboardGradientText(
			hg.muteall and "UNMUTE ALL" or "MUTE ALL",
			"ZB_InterfaceSmall",
			w / 2,
			h / 2,
			1,
			TEXT_ALIGN_CENTER,
			TEXT_ALIGN_CENTER
		)
	end

	muteAllButton.DoClick = function()
		hg.muteall = not hg.muteall

		for _, ply in player.Iterator() do
			if hg.muteall then
				ply:SetVoiceVolumeScale(0)
			else
				ply:SetVoiceVolumeScale(
					(
						not hg.mutespect
						or ply:Alive()
					)
					and (
						hg.playerInfo[ply:SteamID()]
						and hg.playerInfo[ply:SteamID()][2]
						or 1
					)
					or 0
				)
			end
		end
	end

	-- Mute spectators
	local muteSpectatorsButton = vgui.Create("DButton", scoreBoardMenu)

	muteSpectatorsButton:SetPos(
		scoreBoardMenu:GetWide() - buttonW * 1.2,
		scoreBoardMenu:GetTall() - buttonH * 1.5
	)

	muteSpectatorsButton:SetSize(buttonW, buttonH)
	muteSpectatorsButton:SetText("")

	muteSpectatorsButton.Paint = function(self, w, h)
		surface.SetDrawColor(0, 0, 0, 150)
		surface.DrawRect(0, 0, w, h)

		DrawScoreboardOutline(0, 0, w, h, 2)

		DrawScoreboardGradientText(
			hg.mutespect and "UNMUTE SPECTATORS" or "MUTE SPECTATORS",
			"ZB_InterfaceSmall",
			w / 2,
			h / 2,
			2,
			TEXT_ALIGN_CENTER,
			TEXT_ALIGN_CENTER
		)
	end

	muteSpectatorsButton.DoClick = function()
		hg.mutespect = not hg.mutespect

		for _, ply in player.Iterator() do
			if ply:Alive() then
				-- continue not available in Lua 5.1
			else
				if hg.mutespect then
					ply:SetVoiceVolumeScale(0)
				else
					ply:SetVoiceVolumeScale(
						not hg.muteall
						and (
							hg.playerInfo[ply:SteamID()]
							and hg.playerInfo[ply:SteamID()][2]
							or 1
						)
						or 0
					)
				end
			end
		end
	end

	local serverName = GetHostName() or "ZCity | Developer Server | #01"

	scoreBoardMenu.PaintOver = function(self, w, h)
		DrawScoreboardOutline(0, 0, w, h, 3)

		DrawScoreboardGradientText(
			serverName,
			"ZB_InterfaceLarge",
			w / 2,
			10,
			3,
			TEXT_ALIGN_CENTER,
			TEXT_ALIGN_TOP
		)

		DrawScoreboardGradientText(
			"Players:",
			"ZB_InterfaceMediumLarge",
			w / 4,
			ScreenScale(25),
			4,
			TEXT_ALIGN_CENTER,
			TEXT_ALIGN_TOP
		)

		DrawScoreboardGradientText(
			"SV Tick: " .. math.Round(1 / engine.ServerFrameTime()),
			"ZB_InterfaceMediumLarge",
			w / 2,
			ScreenScale(25),
			5,
			TEXT_ALIGN_CENTER,
			TEXT_ALIGN_TOP
		)

		DrawScoreboardGradientText(
			"Spectators:",
			"ZB_InterfaceMediumLarge",
			w * 0.75,
			ScreenScale(25),
			6,
			TEXT_ALIGN_CENTER,
			TEXT_ALIGN_TOP
		)

		DrawScoreboardGradientText(
			"ZC Version: " .. tostring(hg.Version or "unknown"),
			"ZB_InterfaceSmall",
			w * 0.01,
			h - ScreenScale(5),
			7,
			TEXT_ALIGN_LEFT,
			TEXT_ALIGN_BOTTOM
		)
	end

	-- Переход в наблюдение
	if LocalPlayer():Team() ~= TEAM_SPECTATOR then
		local spectateButton = vgui.Create("DButton", scoreBoardMenu)

		spectateButton:SetPos(sizeX * 0.925, sizeY * 0.095)
		spectateButton:SetSize(ScrW() / 20, ScrH() / 30)
		spectateButton:SetText("")

		spectateButton.DoClick = function()
			net.Start("ZB_SpecMode")
				net.WriteBool(true)
			net.SendToServer()

			scoreBoardMenu:Remove()
			scoreBoardMenu = nil
		end

		spectateButton.Paint = function(self, w, h)
			surface.SetDrawColor(0, 0, 0, 150)
			surface.DrawRect(0, 0, w, h)

			DrawScoreboardOutline(0, 0, w, h, 2)

			DrawScoreboardGradientText(
				"Join",
				"ZB_InterfaceMedium",
				w / 2,
				h / 2,
				8,
				TEXT_ALIGN_CENTER,
				TEXT_ALIGN_CENTER
			)
		end
	end

	-- Возврат из наблюдения
	if LocalPlayer():Team() == TEAM_SPECTATOR then
		local playingButton = vgui.Create("DButton", scoreBoardMenu)

		playingButton:SetPos(sizeX * 0.010, sizeY * 0.095)
		playingButton:SetSize(ScrW() / 20, ScrH() / 30)
		playingButton:SetText("")

		playingButton.DoClick = function()
			net.Start("ZB_SpecMode")
				net.WriteBool(false)
			net.SendToServer()

			scoreBoardMenu:Remove()
			scoreBoardMenu = nil
		end

		playingButton.Paint = function(self, w, h)
			surface.SetDrawColor(0, 0, 0, 150)
			surface.DrawRect(0, 0, w, h)

			DrawScoreboardOutline(0, 0, w, h, 2)

			DrawScoreboardGradientText(
				"Join",
				"ZB_InterfaceMedium",
				w / 2,
				h / 2,
				9,
				TEXT_ALIGN_CENTER,
				TEXT_ALIGN_CENTER
			)
		end
	end

	-- Панель игроков
	local playersPanel = vgui.Create("DScrollPanel", scoreBoardMenu)
	playersPanel:SetPos(10, ScreenScaleH(58))
	playersPanel:SetSize(sizeX / 2 - 10, sizeY - ScreenScaleH(72))
	PaintScoreboardScrollPanel(playersPanel)

	local disappearance = lply:GetNetVar("disappearance", nil)

	for _, ply in player.Iterator() do
		if ply:Team() == TEAM_SPECTATOR then
			-- continue not available; skip
		else
			if CurrentRound() and CurrentRound().name == "fear" and not ply:Alive() then
				-- skip
			elseif disappearance and ply ~= lply then
				-- skip
			else
				AddScoreboardPlayer(playersPanel, ply, false)
			end
		end
	end

	-- Панель наблюдателей
	local spectatorsPanel = vgui.Create("DScrollPanel", scoreBoardMenu)
	spectatorsPanel:SetPos(sizeX / 2 + 5, ScreenScaleH(58))
	spectatorsPanel:SetSize(sizeX / 2 - 15, sizeY - ScreenScaleH(72))
	PaintScoreboardScrollPanel(spectatorsPanel)

	for _, ply in player.Iterator() do
		if ply:Team() ~= TEAM_SPECTATOR then
			-- skip
		else
			if CurrentRound() and CurrentRound().name == "fear" and not ply:Alive() then
				-- skip
			elseif disappearance and ply ~= lply then
				-- skip
			else
				AddScoreboardPlayer(spectatorsPanel, ply, true)
			end
		end
	end

	return true
end

function GM:ScoreboardHide()
	if IsValid(scoreBoardMenu) then
		scoreBoardMenu:Close()
		scoreBoardMenu = nil
	end
end

-- свет от молнии а саму молнию я не сделал skill issue
if CLIENT then
	net.Receive("PunishLightningEffect", function()
		local target = net.ReadEntity()
		if not IsValid(target) then return end
		local dlight = DynamicLight(target:EntIndex())
		if dlight then
			dlight.pos = target:GetPos()
			dlight.r = 126
			dlight.g = 139
			dlight.b = 212
			dlight.brightness = 1
			dlight.Decay = 1000
			dlight.Size = 500
			dlight.DieTime = CurTime() + 1
		end
	end)
end

/*  -- а кстати зачем здесь нэт, это же можно было на клиенте полностью сделать...
	if CLIENT then
		net.Receive("PluvCommand", function()
			local specialSteamID = "STEAM_0:1:81850653" 
			local playerSteamID = LocalPlayer():SteamID() 

			local imageURLs = {"https://sadsalat.github.io/salatis/music/boof.gif", "https://i.ibb.co/drt1Lks/KtvCLSs.webp", "https://media.tenor.com/kG4PmVvJuRIAAAAC/rain-world-rain-world-saint.gif"} 
			local soundURLs = {"https://sadsalat.github.io/salatis/music/sus-rock.mp3", "https://sadsalat.github.io/salatis/music/tiktok-raaaah-scream.mp3", "https://sadsalat.github.io/salatis/music/sus-rock.mp3"} 

			local chosenImage = imageURLs[math.random(#imageURLs)]
			local chosenSound = soundURLs[math.random(#soundURLs)]

			sound.PlayURL(chosenSound, "", function(station)
				if IsValid(station) then
					station:Play()
				else
					print("Unable to play the sound.")
				end
			end)

			local html = vgui.Create("HTML")
			html:OpenURL(chosenImage)
			html:SetSize(ScrW(), ScrH())
			html:Center()
			html:MakePopup()

			timer.Simple(3, function()
				if IsValid(html) then
					html:Remove()
				end
			end)
		end)
	end
*/

local lightningMaterial = Material("sprites/lgtning")

net.Receive("AnotherLightningEffect", function()
    local target = net.ReadEntity()
	if not IsValid(target) then return end
    local points = {}
    for i = 1, 27 do
        points[i] = target:GetPos() + Vector(0, 0, i * 50) + Vector(math.Rand(-20,20),math.Rand(-20,20),math.Rand(-20,20))
    end
    hook.Add( "PreDrawTranslucentRenderables", "LightningExample", function(isDrawingDepth, isDrawingSkybox)
        if isDrawingDepth or isDrawingSkybox then return end
        local uv = math.Rand(0, 1)
        render.OverrideBlend( true, BLEND_SRC_COLOR, BLEND_SRC_ALPHA, BLENDFUNC_ADD, BLEND_ONE, BLEND_ZERO, BLENDFUNC_ADD )
        render.SetMaterial(lightningMaterial)
        render.StartBeam(27)
        for i = 1, 27 do
            render.AddBeam(points[i], 20, uv * i, Color(255,255,255,255))
        end
        render.EndBeam()
        render.OverrideBlend( false )
    end )
    timer.Simple(0.1, function()
        hook.Remove("PreDrawTranslucentRenderables", "LightningExample")
    end)
end)

function GM:AddHint( name, delay )
	return false
end

local snakeGameOpen = false

concommand.Add("zb_snake", function() -- вот как здесь!
    if snakeGameOpen then
        print("[Snake Game] Игра уже запущена!")
        return
    end

    local frame = vgui.Create("ZFrame")
    frame:SetTitle("Snake Game")
    frame:SetSize(400, 400)
    frame:Center()
    frame:MakePopup()
    frame:SetDeleteOnClose(true)  
    snakeGameOpen = true  

    local gridSize = 20
    local gridWidth = 19  
    local gridHeight = 19  
    local snakePanel = vgui.Create("DPanel", frame)
    snakePanel:SetSize(380, 380)
    snakePanel:SetPos(10, 10)

    
    frame:SetDraggable(true)
    frame:ShowCloseButton(true)

    local snake = {
        {x = 10, y = 10},
    }
	
    local snakeDirection = "RIGHT"
    local food = nil
    local score = 0
    local gameRunning = true

  
    local function spawnFood()
        local validPosition = false
        while not validPosition do
            local newFood = {
                x = math.random(0, gridWidth - 1), 
                y = math.random(0, gridHeight - 1)
            }
            validPosition = true

        
            for _, segment in ipairs(snake) do
                if segment.x == newFood.x and segment.y == newFood.y then
                    validPosition = false  
                    break
                end
            end

            
            if validPosition then
                food = newFood
            end
        end
    end

    
    local function drawSnake()
        surface.SetDrawColor(0, 255, 0, 255)
        for _, segment in ipairs(snake) do
            surface.DrawRect(segment.x * gridSize, segment.y * gridSize, gridSize - 1, gridSize - 1)
        end
    end

  
    local function drawFood()
        if food then
            surface.SetDrawColor(255, 0, 0, 255)
            surface.DrawRect(food.x * gridSize, food.y * gridSize, gridSize - 1, gridSize - 1)
        end
    end

   
    local function moveSnake()
        if not gameRunning then return end

        local head = table.Copy(snake[1])

        if snakeDirection == "UP" then
            head.y = head.y - 1
        elseif snakeDirection == "DOWN" then
            head.y = head.y + 1
        elseif snakeDirection == "LEFT" then
            head.x = head.x - 1
        elseif snakeDirection == "RIGHT" then
            head.x = head.x + 1
        end

        
        if head.x < 0 or head.x >= gridWidth or head.y < 0 or head.y >= gridHeight then
            gameRunning = false
        end

       
        for _, segment in ipairs(snake) do
            if segment.x == head.x and segment.y == head.y then
                gameRunning = false
            end
        end

       
        table.insert(snake, 1, head)

        if food and head.x == food.x and head.y == food.y then
            score = score + 1
            spawnFood()  
        else
            table.remove(snake)
        end
    end


    local function resetGame()
        snake = {{x = 10, y = 10}}
        snakeDirection = "RIGHT"
        score = 0
        gameRunning = true
        spawnFood()  
    end


    function snakePanel:Paint(w, h)
        surface.SetDrawColor(50, 50, 50, 255)
        surface.DrawRect(0, 0, w, h)

        if gameRunning then
            drawSnake()
            drawFood()
        else
            draw.SimpleText("Game Over! Press R to restart", "DermaDefault", w / 2, h / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        draw.SimpleText("Score: " .. score, "DermaDefault", 10, 10, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end


    function frame:OnKeyCodePressed(key) -- ФУРИ МУВ теперь понятно почему лагает змейка
        if key == KEY_W and snakeDirection ~= "DOWN" then
            snakeDirection = "UP"
        elseif key == KEY_S and snakeDirection ~= "UP" then
            snakeDirection = "DOWN"
        elseif key == KEY_A and snakeDirection ~= "RIGHT" then
            snakeDirection = "LEFT"
        elseif key == KEY_D and snakeDirection ~= "LEFT" then
            snakeDirection = "RIGHT"
        elseif key == KEY_R then
            resetGame()
        end
    end


    timer.Create("SnakeGameTimer", 0.2, 0, function()
        if gameRunning then
            moveSnake()
        end
        snakePanel:InvalidateLayout(true)
    end)


    frame.OnClose = function()
        timer.Remove("SnakeGameTimer")
        snakeGameOpen = false  
        print("[Snake Game] Игра закрыта.") -- НЕ РАБОТАЕТ
    end


    resetGame()
end)

hook.Add("Player Spawn", "GuiltKnown",function(ply)
	if ply == LocalPlayer() then
		system.FlashWindow()
	end
end)