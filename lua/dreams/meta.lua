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

local tbl_Count = table.Count

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
	local cr1 = v_Cross(b - a, c - a)
	local cr2 = v_Cross(b - a, p - a)
	return v_Dot(cr1, cr2) >= 0
end

local function minmax(xmin, xmax, vec)
	return Vector(math.min(xmin.x, vec.x), math.min(xmin.y, vec.y), math.min(xmin.z, vec.z)), Vector(math.max(xmax.x, vec.x), math.max(xmax.y, vec.y), math.max(xmax.z, vec.z))
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

function DREAMS:Draw(ply, debug)
	ply:SetPos(ply:GetDTVector(31))
	ply:SetNetworkOrigin(ply:GetDTVector(31))
	for k, v in ipairs(self.ListRooms) do
		if not IsValid(v.CMDL) and v.CMDL ~= false then
			v.CMDL = v.mdl and ClientsideModelSafe(v.mdl) or false
			v.CMDL:SetNoDraw(true)
		elseif v.CMDL == false then continue end
		if debug ~= 1 and ply.DreamRoom and ply.DreamRoom ~= v then continue end

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
		if v:GetDreamID() ~= self.ID or v == ply then continue end
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

	if debug == 1 or debug == 2 or debug == 3 then
		for k, v in ipairs(self.Phys) do
			if debug == 1 then
				render.DrawWireframeBox(vector_origin, Angle(), v.OBB[1], v.OBB[2], Color(100, 0, 255), true)
			end
			for _, s in ipairs(v) do
				if not s.bvert then
					local min, max = s.verts[1], s.verts[1]
					for a, b in pairs(s.verts) do
						min, max = minmax(min, max, b)
					end
					s.bvert = {min, max}
				end

				if debug == 1 or debug == 3 then
					render.DrawWireframeBox(vector_origin, Angle(), s.bvert[1], s.bvert[2], Color(0, 150, 255), debug ~= 1)
				end

				if debug == 2 or debug == 3 then
					local plane = s.plane
					local norm = s.normal or normal(plane[1], plane[2], plane[3])
					s.normal = norm
					local middle = s.middle or (s.bvert[2] - s.bvert[1]) / 2 + s.bvert[1]
					s.middle = middle

					local rot, rot_end, rot_three = middle, middle + norm * 25, middle + norm * 50
					render.DrawLine(rot, rot_end, Color(255, 0, 0), false)
					render.DrawLine(rot_end, rot_three, Color(0, 255, 0), false)
				end
			end
		end
	end
end

function DREAMS:SetupFog()
end

function DREAMS:RenderScene(ply)
	local view = {
		origin = origin,
		angles = angles,
		fov = fov,
	}
	if not self:SetupFog(ply) then render.FogMode(MATERIAL_FOG_NONE) end
	self:CalcView(ply, view)
	cam.Start3D(view.origin, view.angles, view.fov, 0, 0, ScrW(), ScrH())
	self:Draw(ply)
	cam.End3D()

	cam.Start2D()
	self:DrawHUD(ply, ScrW(), ScrH())
	cam.End2D()
	return true
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

	if ply:IsBot() or cmd_KeyDown(cmd, IN_FORWARD) then
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

	if vel.z < 0 then v_SetUnpacked(vel, vel.x, vel.y, math_max(math_min(vel.z, -1) * 1.111, -1400)) end
	v_Add(vel, Vector(0, 0, -self.Gravity * FrameTime()))
	mv_SetVelocity(mv, vel)
	return true
end

// For Debug
function DREAMS:StartMoveFly(ply, mv, cmd)
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

	if  cmd_KeyDown(cmd, IN_FORWARD) then
		v_Add(pos, Angle(0, ang.y, 0):Forward())
	end

	if cmd_KeyDown(cmd, IN_BACK) then
		v_Add(pos, -Angle(0, ang.y, 0):Forward())
	end

	if cmd_KeyDown(cmd, IN_JUMP) then
		v_Add(pos, Vector(0, 0, 1))
	end

	if cmd_KeyDown(cmd, IN_DUCK) then
		v_Add(pos, Vector(0, 0, -1))
	end

	v_Normalize(pos)
	local vel = ply_GetAbsVelocity(ply) * 0.9 + pos * speed
	if v_IsEqualTol(vel, vector_origin, 3) then
		vel:Zero()
	end

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
			local norm = s.normal or normal(plane[1], plane[2], plane[3])
			s.normal = norm
			local hit = intersectrayplane(worg + norm, -norm, plane[1], norm)
			local fhit = v_IsEqualTol(norm, up, 0.3) and intersectrayplane(org + up * vel_len * 2, -up, plane[1], norm)
			local wd, fd = hit and v_Dot(worg - hit + norm, norm) or 0, fhit and v_Dot(org - fhit + norm, norm) or 0

			if not fhit and hit and (v_DistToSqr(hit, worg) < 17 ^ 2 or wd < 1 and wd > -2) or fhit and (v_DistToSqr(fhit, org) < 1 or fd < 0 and fd > -3 * math_abs(vel.z / 10)) then
				local verts = s.verts
				local n_verts = tbl_Count(verts)
				local e = fhit or hit

				local dobreak
				for i = 0, n_verts - 1 do
					if not check(verts[i], verts[(i + 1) % n_verts], verts[(i + 2) % n_verts], e) then
						dobreak = true
						break
					end
				end
				if dobreak then continue end

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

pmeta.O_GetActiveWeapon = pmeta.O_GetActiveWeapon or pmeta.GetActiveWeapon

function pmeta:GetActiveWeapon()
	local res = self:O_GetActiveWeapon()
	if res == NULL then return game.GetWorld() end
	return res
end