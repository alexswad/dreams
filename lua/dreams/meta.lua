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

local mvmeta = FindMetaTable("CMoveData")
local cmdmeta = FindMetaTable("CUserCmd")
local vmeta = FindMetaTable("Vector")
local emeta = FindMetaTable("Entity")
local pmeta = FindMetaTable("Player")

local DREAMS = {}
DREAMS.__index = DREAMS
Dreams.Meta = DREAMS

local mv_SetVelocity = mvmeta.SetVelocity
local mv_SetOrigin = mvmeta.SetOrigin
local mv_GetMoveAngles = mvmeta.GetMoveAngles
local mv_GetOrigin = mvmeta.GetOrigin
local mv_GetVelocity = mvmeta.GetVelocity

local cmd_KeyDown = cmdmeta.KeyDown
local ply_GetAbsVelocity = emeta.GetAbsVelocity
local ply_GetDTVector = emeta.GetDTVector
local ply_SetDTVector = emeta.SetDTVector
local ply_SetDTInt = emeta.SetDTInt
local ply_GetDTInt = emeta.GetDTInt
local ply_GetTable = emeta.GetTable

local v_Add = vmeta.Add
local v_Normalize = vmeta.Normalize
local v_WithinAABox = vmeta.WithinAABox
local v_Cross = vmeta.Cross
local v_Dot = vmeta.Dot
local v_IsEqualTol = vmeta.IsEqualTol
local v_DistToSqr = vmeta.DistToSqr
local v_SetUnpacked = vmeta.SetUnpacked
local v_Length = vmeta.Length

local math_min = math.min
local math_max = math.max
local math_abs = math.abs
local FrameTime = FrameTime
local Vector = Vector
local Angle = Angle
local ipairs = ipairs

local IN_SPEED = IN_SPEED
local IN_MOVERIGHT = IN_MOVERIGHT
local IN_MOVELEFT = IN_MOVELEFT
local IN_FORWARD = IN_FORWARD
local IN_BACK = IN_BACK

local intersectrayplane = util.IntersectRayWithPlane
local normal = function(c, b, a)
	local cr = v_Cross(b - a, c - a)
	v_Normalize(cr)
	return cr
end

local function check(a, b, c, p)
	if not a or not b then return true end
	local cr1 = v_Cross(b - a, c - a)
	local cr2 = v_Cross(b - a, p - a)
	return v_Dot(cr1, cr2) >= 0
end

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
			self:SetNoTarget(false)
			self:SetCollisionGroup(COLLISION_GROUP_NONE)
			self:SetMoveType(MOVETYPE_WALK)
			self:SetAvoidPlayers(self.Dreams_OLDAVP)
			return
		end

		ply_SetDTInt(self, 31, id)
		self:GetDream():Start(self)
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


///////////////////////////////////////////////

function DREAMS:Draw()
	local ply = LocalPlayer()
	ply:SetPos(ply:GetDTVector(31))
	ply:SetNetworkOrigin(ply:GetDTVector(31))
	for k, v in ipairs(self.ListRooms) do
		if not IsValid(v.CMDL) and v.CMDL ~= false then
			v.CMDL = v.mdl and ClientsideModelSafe(v.mdl) or false
			v.CMDL:SetNoDraw(true)
		elseif v.CMDL == false then continue end
		if ply.DreamRoom and ply.DreamRoom ~= v then continue end

		render.SuppressEngineLighting(true)
		render.SetAmbientLight(0, 0 , 0)
		if v.Lighting then
			render.ResetModelLighting(v.Lighting[1], v.Lighting[2], v.Lighting[3])
		else
			render.ResetModelLighting(1, 1, 1)
		end

		v.CMDL:SetRenderOrigin(v.offset)
		v.CMDL:DrawModel()

		render.SuppressEngineLighting(false)
	end

	for k, v in ipairs(player.GetAll()) do
		if not v:GetDreamID() == self.ID or v == ply then continue end
		render.SuppressEngineLighting(true)

		v:SetNetworkOrigin(v:GetDTVector(31))
		v:SetPos(v:GetDTVector(31))

		if not v.DreamRoomCache or v.DreamRoomCache < CurTime() then
			local pos = v:GetDreamPos()
			for a, room in ipairs(self.ListRooms) do
				if room.phys and pos:WithinAABox(room.phys.OBB[1], room.phys.OBB[2]) then
					v.DreamRoom = room
					break
				end
			end
			v.DreamRoomCache = CurTime() + 0.1
		end

		if v.DreamRoom and v.DreamRoom.MdlLighting then
			render.ResetModelLighting(v.DreamRoom.MdlLighting[1], v.DreamRoom.MdlLighting[2], v.DreamRoom.MdlLighting[3])
		else
			render.ResetModelLighting(1, 1, 1)
		end

		if not pk_pills or pk_pills and not pk_pills.getMappedEnt(v) then
			v:DrawModel()
		else
			local ent = pk_pills.getMappedEnt(v)
			if ent.GetPuppet and IsValid(ent:GetPuppet()) then
				ent:GetPuppet():SetRenderOrigin(v:GetDreamPos())
				ent:GetPuppet():DrawModel()
				ent:GetPuppet():SetPos(v:GetDreamPos())
			end
		end

		render.SuppressEngineLighting(false)
	end
end

function DREAMS:SetupFog()
end


///////////////////////////////////////////
DREAMS.MoveSpeed = 20
DREAMS.ShiftSpeed = 40
DREAMS.JumpPower = 400
DREAMS.Gravity = 600
function DREAMS:StartMove(ply, mv, cmd)
	mv_SetVelocity(mv, ply_GetAbsVelocity(ply))
	mv_SetOrigin(mv, mv_GetOrigin(mv))

	local ang = mv_GetMoveAngles(mv)
	local pos = Vector(0, 0, 0)
	local speed = self.MoveSpeed
	if cmd_KeyDown(cmd, IN_SPEED) then
		speed = self.ShiftSpeed
	end

	if cmd_KeyDown(cmd, IN_MOVERIGHT) then
		v_Add(pos, ang:Right())
	end

	if cmd_KeyDown(cmd, IN_MOVELEFT) then
		v_Add(pos, -ang:Right())
	end

	if cmd_KeyDown(cmd, IN_FORWARD) then
		v_Add(pos, Angle(0, ang.y, 0):Forward())
	end

	if cmd_KeyDown(cmd, IN_BACK) then
		v_Add(pos, -Angle(0, ang.y, 0):Forward())
	end

	v_Normalize(pos)
	local vel = ply_GetAbsVelocity(ply) * 0.9 + pos * speed
	if v_IsEqualTol(vel, vector_origin, 3) then
		vel:Zero()
	end

	if vel.z < 0 then v_SetUnpacked(vel, vel.x, vel.y, math_max(math_min(vel.z, -1) * 1.111, -800)) end
	v_Add(vel, Vector(0, 0, -self.Gravity * FrameTime()))
	mv_SetVelocity(mv, vel)
	return true
end

local woff = Vector(0, 0, 32)
local up = Vector(0, 0, 1)
function DREAMS:DoMove(ply, mv)
	local vel, org = mv_GetVelocity(mv), ply_GetDTVector(ply, 31)
	local vel_len = v_Length(vel)
	local worg = org + woff

	local onfloor
	for k, v in ipairs(self.Phys) do
		if not v_WithinAABox(org, v.OBB[1], v.OBB[2]) then continue end
		for _, s in ipairs(v) do
			local plane = s.plane
			local norm = normal(plane[1], plane[2], plane[3])
			local hit = intersectrayplane(worg + norm, -norm, plane[1], norm)
			local fhit = v_IsEqualTol(norm, up, 0.3) and intersectrayplane(org + up * vel_len * 2, -up, plane[1], norm)
			local wd, fd = hit and v_Dot(worg - hit + norm, norm) or 0, fhit and v_Dot(org - fhit + norm, norm) or 0

			if not fhit and hit and (v_DistToSqr(hit, worg) < 17 ^ 2 or wd < 1 and wd > -2) or fhit and (v_DistToSqr(fhit, org) < 1 or fd < 0 and fd > -3 * math_abs(vel.z / 10)) then
				local verts = s.verts
				local a, b, c, d, f = verts[1], verts[2], verts[3], verts[4], verts[5]
				local e = fhit or hit
				if check(a, b, c, e) and check(b, c, a, e) and check(c, d, a, e) and check(d, a, b, e) and check(d, f, c) and check(f, a, d) then
					if fhit then
						onfloor = true
						v_SetUnpacked(org, org.x, org.y, fhit.z)
						v_SetUnpacked(vel, vel.x, vel.y, 0.1)
						worg = org + woff
					else
						vel = vel - norm * v_Dot(vel, norm)
						org = hit - woff + norm * 17
						worg = org + woff
					end
				end
			end
		end
		ply_GetTable(ply).DreamRoom = v.Room
	end

	if onfloor and mv:KeyPressed(IN_JUMP) then
		v_SetUnpacked(vel, vel.x, vel.y, self.JumpPower)
	end

	ply_SetDTVector(ply, 31, org + vel * FrameTime())
	mv_SetVelocity(mv, vel)
	return true
end

function DREAMS:FinishMove(ply, mv)
	ply:SetAbsVelocity(mv_GetVelocity(mv))
	if SERVER then ply:DropToFloor() end
	return true
end

local height = Vector(0, 0, 64)
function DREAMS:CalcView(ply, view)
	view.angles = ply:EyeAngles()
	view.origin = ply:GetDTVector(31) + height
end

////////////////////////////////////////

// RUBAT PLEAAASEEEE
// PLEASASEEEEE DONT PATCH THIS
// IM ONLY A LEVEL 1 CODER AND I NEED THIS FOR RENDERSCENE
// IF YOU PATCH THIS I WILL HAVE TO MAKE A SHITTY CHATBOX AND HUD TO REPLACE WHATS MISSING
// AND THEN MAKE A SHITTY CHATBOX DETECTOR FOR COMPATABILITY
// FOR ALL THAT IS HOLY. PLEASE. DO NOT PATCH THIS.

if CLIENT then
	local chatbox
	local cviewport
	hook.Add("StartChat", "Dreams_gethuds", function()
		if IsValid(chatbox) or (chatbox == false and chatbox ~= nil) then return end
		timer.Simple(0.1, function()
			chatbox = vgui.GetKeyboardFocus():GetParent():GetParent()
			if not IsValid(chatbox) or chatbox:GetClassName() ~= "CHudChat" then chatbox = false return end
			cviewport = chatbox:GetParent()
		end)
	end)

	function DREAMS:DrawHUD()
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
		local start = ents.FindByClass("info_player_start")[1]
		ply:SetPos(IsValid(start) and start:GetPos() + Vector(0, 0, 1) or vector_origin)
		ply:SetCollisionGroup(COLLISION_GROUP_PASSABLE_DOOR)
		ply:SetNoTarget(true)
		ply:SetMoveType(MOVETYPE_NONE)
		ply.Dreams_OLDAVP = ply:GetAvoidPlayers()
		ply:SetAvoidPlayers(false)
		ply:SetActiveWeapon(NULL)
	end

	function DREAMS:ThinkSelf()
	end
else
	function DREAMS:Start()
	end

	function DREAMS:PrePlayerDraw(ply)
		if ply:GetDreamID() ~= LocalPlayer():GetDreamID() then
			ply:SetPos(ply:GetPos() + Vector(0, 0, -96))
			return true
		end
	end
end

function DREAMS:SwitchWeapon()
	return true
end

function DREAMS:Think(ply)
end

function DREAMS:End(ply)
end

pmeta.O_GetActiveWeapon = pmeta.O_GetActiveWeapon or pmeta.GetActiveWeapon

function pmeta:GetActiveWeapon()
	local res = self:O_GetActiveWeapon()
	if res == NULL then return game.GetWorld() end
	return res
end