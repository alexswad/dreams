local Dreams = Dreams
local emeta = FindMetaTable("Entity")
local pmeta = FindMetaTable("Player")

local DREAMS = {}
DREAMS.__index = DREAMS
Dreams.Meta = DREAMS

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

include("dreams/meta/movement.lua")
include("dreams/meta/net.lua")
include("dreams/meta/render.lua")

local ply_GetDTVector = emeta.GetDTVector
local ply_SetDTVector = emeta.SetDTVector
local ply_SetDTInt = emeta.SetDTInt
local ply_GetDTInt = emeta.GetDTInt

local Vector = Vector
local Angle = Angle

Dreams.EMPTY_ROOM = {name = "none", notvalid = true, phys = {}}

------------------------------------------

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

function pmeta:SetDream(id)
	ply_SetDTInt(self, 31, id)
end

if SERVER then
	function pmeta:SetDream(id)
		if isstring(id) then
			id = Dreams.NameToID[id] or 0
		end
		if self:GetDreamID() == id then return end
		self:SetNoTarget(false)
		self:SetDreamPos(vector_origin)

		local cdream = self:GetDream()
		if cdream then
			cdream:End(self)
		else
			self.DREAMS_LastCC = self:GetCustomCollisionCheck()
			self.DREAMS_LastAP = self:GetAvoidPlayers()
		end

		if not Dreams.List[id] then
			ply_SetDTInt(self, 31, 0)
			self:SetCustomCollisionCheck(self.DREAMS_LastCC or false)
			self:SetAvoidPlayers(self.DREAMS_LastAP)
			self:SetMoveType(MOVETYPE_WALK)
			return
		end
		self:SetCustomCollisionCheck(true)
		self:CollisionRulesChanged()
		self:SetAvoidPlayers(false)

		ply_SetDTInt(self, 31, id)
		self:GetDream():Start(self)
		self:SetNoTarget(true)
	end

	function pmeta:SetDreamPos(pos)
		self.DreamRoom = Dreams.EMPTY_ROOM
		ply_SetDTVector(self, 31, pos)
	end
end


--------------------------------------------

local function offset_marks(marks, offset)
	for k, v in pairs(marks) do
		if not v.pos then
			offset_marks(v, offset)
		else
			v.pos = v.pos + offset
		end
	end
end

function DREAMS:AddRoom(name, mdl, phy, offset)
	offset = offset or vector_origin
	local tbl = Dreams.Bundle.Load(phy, "GAME")
	if tbl then
		if tbl.marks then
			offset_marks(tbl.marks, offset)
		end

		if tbl.props then
			for k, v in pairs(tbl.props) do
				v.origin = v.origin + offset
				if v.phys then
					tbl.phys = tbl.phys or {}
					table.insert(tbl.phys, v.phys)
				end
			end
		end

		local room = {
			marks = tbl.marks,
			name = name,
			mdl = mdl or tbl.mdl,
			mdl_origin = tbl.mdl_origin,
			mdl_angles = tbl.mdl_angles,
			mdl_scale = tbl.mdl_scale,
			phys = tbl.phys,
			phy_string = phy,
			offset = offset,
			props = tbl.props,
		}
		self.Rooms[name] = room

		if tbl.phys then
			Dreams.Lib.PhysOffset(tbl.phys, offset)
			tbl.phys.Room = room
			table.insert(self.Phys, tbl.phys)
		end

		if tbl.triggers then
			room.triggers = {}
			for k, v in pairs(tbl.triggers) do
				if not v.name then v.name = #room.triggers + 1 end
				Dreams.Lib.PhysOffset({v.phys}, offset)
				if room.triggers[v.name] then
					local etrig = room.triggers[v.name]
					if etrig.phys.AA then etrig.phys = {etrig.phys} end
					table.insert(etrig.phys, v.phys)
					continue
				end
				room.triggers[v.name] = v
			end
		end

		if tbl.entities then
			room.entities = {}
			for k, v in pairs(tbl.entities) do
				local phys = tostring(v.phys)
				v.phys = nil
				for _, s in pairs(tbl.phys or {}) do
					if tostring(s.id) == phys then
						s.Entity = v
						v.phys = s
						break
					end
				end

				if not v.name then v.name = #room.entities + 1 end
				if room.entities[v.name] then
					local etbl = room.entities[v.name]
					if etbl.phys.AA then etbl.phys = {etbl.phys} end
					table.insert(etbl.phys, v.phys)
					continue
				end
				room.entities[v.name] = v
			end
		end
	else
		self.Rooms[name] = {name = name, mdl = mdl}
	end

	table.insert(self.ListRooms, self.Rooms[name])
	return self.Rooms[name]
end

-- function DREAMS:KeyPress(ply, key)
-- 	if CLIENT and key == IN_USE then self.Debug = (self.Debug or 0) % 1 + 1 end
-- end
----------------------------------------

-- please dont patch this rubat :(
if CLIENT then
	local open_chat = chat.Open
	local close_chat = chat.Close
	local chatbox
	local cviewport
	hook.Add("StartChat", "!!!!Dreams_gethuds", function()
		if IsValid(chatbox) then return end
		timer.Simple(0.2, function()
			chatbox = IsValid(vgui.GetKeyboardFocus()) and vgui.GetKeyboardFocus():GetParent():GetParent()
			if not IsValid(chatbox) or chatbox:GetClassName() ~= "CHudChat" then return end
			cviewport = chatbox:GetParent()
		end)
	end)

	local opened
	function DREAMS:DrawHUD(ply, w, h, skip_glua)
		if not opened and chatbox == nil then
			opened = true
			open_chat(1)
			timer.Simple(0.25, close_chat)
		end
		if chatbox and chatbox:GetClassName() == "CHudChat" then
			chatbox:SetPaintedManually(true)
			chatbox:PaintManual()
			chatbox:SetPaintedManually(false)

			cviewport:SetPaintedManually(true)
			cviewport:PaintManual()
			cviewport:SetPaintedManually(false)
		end

		if not skip_glua then
			GetHUDPanel():SetPaintedManually(true)
			GetHUDPanel():PaintManual()
			GetHUDPanel():SetPaintedManually(false)
		end
	end

	function DREAMS:HUDShouldDraw(ply, str)
		if str == "CHudWeaponSelection" then return false end
	end
end


if SERVER then
	function DREAMS:Start(ply)
		local starts = ents.FindByClass("info_player_*")
		local start = starts[math.random(#starts)] or starts[1]
		ply:SetPos((IsValid(start) and start:GetPos() + Vector(0, 0, 64) or vector_origin) + Angle(0, math.Rand(-360, 360), 30):Forward() * 10)
		ply:DropToFloor()
		ply:SetNoTarget(true)
		ply:SetActiveWeapon(NULL)
		ply:SetMoveType(MOVETYPE_NONE)
		ply.DreamRoom = Dreams.EMPTY_ROOM
	end

	function DREAMS:ThinkSelf()
	end

	function DREAMS:EntityTakeDamage(ply, attacker, inflictor, dmg)
		if not IsValid(attacker) and dmg:GetDamageType() ~= DMG_GENERIC then return true end
		if IsValid(attacker) and (not attacker:IsPlayer() or attacker:GetDreamID() ~= ply:GetDreamID()) then return true end
	end

	function DREAMS:End(ply)
		local starts = ents.FindByClass("info_player_*")
		local start = starts[math.random(#starts)] or starts[1]
		ply:SetPos(IsValid(start) and start:GetPos() + Vector(0, 0, 1) or ply:GetPos())
		ply:SetAbsVelocity(vector_origin)
		self:SendEndCommand(ply)
	end

	DREAMS:AddNetSender("falldamage", function(dream, int) net.WriteInt(int, 32) end)
	function DREAMS:TakeFallDamage(ply, speed)
		local dmg = self:GetFallDamage(ply, speed)
		if not isnumber(dmg) or dmg < 1 then return end
		local dinfo = DamageInfo()
		dinfo:SetDamageType(DMG_FALL)
		dinfo:SetDamage(dmg)
		dinfo:SetAttacker(ply)
		ply:TakeDamageInfo(dinfo)
		self:SendCommand("falldamage", ply, speed)
	end

	function DREAMS:GetFallDamage(ply, speed)
		return hook.Run("GetFallDamage", ply, speed)
	end
else
	DREAMS:AddNetReceiver("falldamage", function(dream, ply)
		dream:TakeFallDamage(ply, net.ReadInt(32))
	end)

	function DREAMS:TakeFallDamage(ply, speed)
		ply:EmitSound("player/pl_fallpain3.wav")
	end

	function DREAMS:Start(ply)
	end

	function DREAMS:End(ply)
	end
end

function DREAMS:SwitchWeapon(ply, old, new)
	return true
end

function DREAMS:Think(ply)
end

----------------------------------
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
		for k, v in ipairs(player.GetAll()) do
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
