AddCSLuaFile("dreams/meta/movement.lua")
AddCSLuaFile("dreams/meta/net.lua")
AddCSLuaFile("dreams/meta/render.lua")

CLIENTSAFE_MODELS = CLIENTSAFE_MODELS or {}
function ClientsideModelSafe(mdl, rndr)
	local ent = ClientsideModel(mdl, rndr)
	table.insert(CLIENTSAFE_MODELS, ent)
	return ent
end
hook.Add("PostCleanupMap", "ClientSideModelSafe_Clear", function()
	for k, v in pairs(CLIENTSAFE_MODELS) do
		v:Remove()
	end
	table.Empty(CLIENTSAFE_MODELS)
end)

local Dreams = Dreams
local emeta = FindMetaTable("Entity")
local pmeta = FindMetaTable("Player")

local DREAMS = {}
DREAMS.__index = DREAMS
Dreams.Meta = DREAMS

include("dreams/meta/movement.lua")
include("dreams/meta/net.lua")
include("dreams/meta/render.lua")

local ply_GetDTVector = emeta.GetDTVector
local ply_SetDTVector = emeta.SetDTVector
local ply_SetDTInt = emeta.SetDTInt
local ply_GetDTInt = emeta.GetDTInt

local Vector = Vector
local Angle = Angle
local ipairs = ipairs

///////////////////////////////////////////

function pmeta:IsDreaming()
	return ply_GetDTInt(self, 31, 0) ~= 0
end

function pmeta:GetDreamID()
	return ply_GetDTInt(self, 31, 0)
end

function pmeta:GetDream()
	local id = ply_GetDTInt(self, 31, 0)
	if id == 0 then return false end
	return Dreams.List[id]
end

function pmeta:GetDreamPos()
	return ply_GetDTVector(self, 31)
end

emeta.O_IsOnGround = emeta.O_IsOnGround or emeta.IsOnGround
local ply_IsOnGround = emeta.O_IsOnGround

function pmeta:IsOnGround()
	if self:IsDreaming() then return true end
	return ply_IsOnGround(self)
end


emeta.O_GetVelocity = emeta.O_GetVelocity or emeta.GetVelocity
local ply_GetVelocity = emeta.O_GetVelocity

function pmeta:GetVelocity()
	if self:IsDreaming() then return self:GetAbsVelocity() end
	return ply_GetVelocity(self)
end

if SERVER then
	function pmeta:SetDream(id)
		self:SetNoTarget(false)
		self:SetDreamPos(vector_origin)
		if isstring(id) then
			id = Dreams.NameToID[id] or 0
		end
		if self:GetDreamID() == id then return end

		local cdream = self:GetDream()
		if cdream then
			cdream:End(self)
		end

		if not Dreams.List[id] then
			ply_SetDTInt(self, 31, 0)
			self:SetCollisionGroup(COLLISION_GROUP_NONE)
			self:SetMoveType(MOVETYPE_WALK)
			return
		end

		ply_SetDTInt(self, 31, id)
		self:GetDream():Start(self)
		self:SetNoTarget(true)
	end

	function pmeta:SetDreamPos(pos)
		self.DreamRoom = nil
		ply_SetDTVector(self, 31, pos)
	end
end


////////////////////////////////////////////

function DREAMS:AddRoom(name, mdl, phy, offset)
	offset = offset or vector_origin
	local phys = util.JSONToTable(util.Decompress(file.Read(phy, "GAME") or ""))
	if phys then
		for k, side in ipairs(phys) do
			for _, vert in pairs(side.verts) do
				side.verts[_] = vert + offset
			end
			for _, vert in pairs(side.plane) do
				side.plane[_] = vert + offset
			end
		end
		phys.OBB[1] = phys.OBB[1] + offset
		phys.OBB[2] = phys.OBB[2] + offset
		table.insert(self.Phys, phys)
	end
	self.Rooms[name] = {name = name, mdl = mdl, phys = phys, phy_string = phy, offset = offset}
	if phys then phys.Room = self.Rooms[name] end

	table.insert(self.ListRooms, self.Rooms[name])
	return self.Rooms[name]
end

////////////////////////////////////////

// RUBAT PLEAAASEEEE
// PLEASASEEEEE DONT PATCH THIS
// IM ONLY A LEVEL 1 CODER AND I NEED THIS FOR RENDERSCENE
// IF YOU PATCH THIS I WILL HAVE TO MAKE A SHITTY CHATBOX AND HUD TO REPLACE WHATS MISSING
// AND THEN MAKE A SHITTY CHATBOX DETECTOR FOR COMPATABILITY
// FOR ALL THAT IS HOLY. PLEASE. DO NOT PATCH THIS.

if CLIENT then
	local open_chat = chat.Open
	local close_chat = chat.Close
	local chatbox
	local cviewport
	hook.Add("StartChat", "!!!!Dreams_gethuds", function()
		if IsValid(chatbox) or (chatbox == false and chatbox ~= nil) then return end
		timer.Simple(0.1, function()
			chatbox = IsValid(vgui.GetKeyboardFocus()) and vgui.GetKeyboardFocus():GetParent():GetParent()
			if not IsValid(chatbox) or chatbox:GetClassName() ~= "CHudChat" then chatbox = false return end
			cviewport = chatbox:GetParent()
		end)
	end)

	local opened
	function DREAMS:DrawHUD(ply, w, h)
		if not opened and chatbox == nil then
			opened = true
			open_chat(1)
			timer.Simple(0.2, close_chat)
		end
		if chatbox and chatbox:GetClassName() == "CHudChat" then
			chatbox:SetPaintedManually(true)
			chatbox:PaintManual()
			chatbox:SetPaintedManually(false)

			cviewport:SetPaintedManually(true)
			cviewport:PaintManual()
			cviewport:SetPaintedManually(false)
		end

		GetHUDPanel():SetPaintedManually(true)
		GetHUDPanel():PaintManual()
		GetHUDPanel():SetPaintedManually(false)
	end

	function DREAMS:HUDShouldDraw(ply, string)
	end
end


if SERVER then
	function DREAMS:Start(ply)
		local starts = ents.FindByClass("info_player_start")
		local start = starts[math.random(#starts)] or starts[1]
		ply:SetPos((IsValid(start) and start:GetPos() + Vector(0, 0, 1) or vector_origin) + Angle(0, math.Rand(1, 360), 45):Forward() * math.random(72, 120))
		ply:DropToFloor()
		ply:SetCollisionGroup(COLLISION_GROUP_PASSABLE_DOOR)
		ply:SetNoTarget(true)
		ply:SetActiveWeapon(NULL)
		ply:SetMoveType(MOVETYPE_NONE)
	end

	function DREAMS:ThinkSelf()
	end

	function DREAMS:EntityTakeDamage(ply, attacker, inflictor, dmg)
		if not IsValid(attacker) and dmg:GetDamageType() ~= DMG_GENERIC then return true end
		if IsValid(attacker) and (not attacker:IsPlayer() or attacker:GetDreamID() ~= ply:GetDreamID()) then return true end
	end
else
	function DREAMS:Start(ply)
	end

	function DREAMS:PrePlayerDraw(ply)
		if ply:GetDreamID() ~= LocalPlayer():GetDreamID() then
			if not LocalPlayer():IsDreaming() then
				ply:SetPos(ply:GetPos() + Vector(0, 0, -2500))
			else
				ply:SetRenderOrigin(nil)
			end
			return true
		end
	end
end

function DREAMS:SwitchWeapon(ply, old, new)
	return true
end

function DREAMS:Think(ply)
end

function DREAMS:End(ply)
end

//////////////////////////////////
pmeta.O_GetActiveWeapon = pmeta.O_GetActiveWeapon or pmeta.GetActiveWeapon

function pmeta:GetActiveWeapon()
	local res = self:O_GetActiveWeapon()
	if res == NULL then return game.GetWorld() end
	return res
end

if SERVER then
	emeta.O_EmitSound = emeta.O_EmitSound or emeta.EmitSound

	function emeta:EmitSound(name, lvl, pitch, vlm, chnl,flg, dsp, filter)
		if not filter then
			filter = RecipientFilter()
			filter:AddAllPlayers()
		end
		for k, v in pairs(player.GetAll()) do
			if v:IsDreaming() then
				filter:RemovePlayer(v)
			end
		end

		self:O_EmitSound(name, lvl, pitch, vlm, chnl,flg, dsp, filter)
	end
else
	function DREAMS:EntityEmitSound(tbl)
		if IsValid(tbl.Entity) and tbl.Entity ~= LocalPlayer() then return false end
	end
end
