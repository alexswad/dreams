local Dreams = Dreams
local DREAMS = Dreams.Meta

local mvmeta = FindMetaTable("CMoveData")
local cmdmeta = FindMetaTable("CUserCmd")
local vmeta = FindMetaTable("Vector")
local emeta = FindMetaTable("Entity")

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

///////////////////////////////////////////
DREAMS.MoveSpeed = 20
DREAMS.ShiftSpeed = 40
DREAMS.JumpPower = 400
DREAMS.Gravity = 600

local function get_move(cmd, pos, ang)
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
end
Dreams.Meta.TranslateMovement = get_move

function DREAMS:StartMove(ply, mv, cmd)
	mv_SetVelocity(mv, ply_GetAbsVelocity(ply))
	mv_SetOrigin(mv, mv_GetOrigin(mv))

	local ang = mv_GetMoveAngles(mv)
	local pos = Vector(0, 0, 0)
	local speed = self.MoveSpeed
	if cmd_KeyDown(cmd, IN_SPEED) then
		speed = self.ShiftSpeed
	end

	get_move(cmd, pos, ang)

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

	get_move(cmd, pos, ang)

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
local woff2 = Vector(0, 0, 2)
local up = Vector(0, 0, 1)
function DREAMS:DoMove(ply, mv)
	local vel, org = mv_GetVelocity(mv), ply_GetDTVector(ply, 31)
	local vel_len = v_Length(vel)

	local onfloor
	for k, v in ipairs(self.Phys) do
		if v.OBB and not v_WithinAABox(org, v.OBB[1], v.OBB[2]) then continue end
		for _, s in ipairs(v) do
			local plane = s.plane
			local norm = s.normal or normal(plane[1], plane[2], plane[3])
			s.normal = norm
			local worg, worg_off = org + woff, woff
			local hit = intersectrayplane(worg, -norm, plane[1], norm)
			local fhit = v_IsEqualTol(norm, up, 0.3) and intersectrayplane(org + up * vel_len * 2, -up, plane[1], norm)
			local wd, fd = hit and v_Dot(worg - hit, norm) or 0, fhit and v_Dot(org - fhit + norm, norm) or 0

			if not fhit and not hit then
				worg = org + woff2 + norm * 2
				worg_off = woff2
				hit = intersectrayplane(worg, -norm, plane[1], norm)
			end

			if not fhit and hit and (v_DistToSqr(hit, worg) < 17 ^ 2 or wd < 1 and wd > -4) or fhit and (v_DistToSqr(fhit, org) < 1 or fd < 0 and fd > -4 * math_abs(vel.z / 10)) then
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
				else
					vel = vel - norm * v_Dot(vel, norm)
					org = hit - worg_off + norm * 17
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