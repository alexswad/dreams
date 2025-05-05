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

local cmd_KeyDown = cmdmeta.KeyDown
local ply_GetAbsVelocity = emeta.GetAbsVelocity
local ply_GetDTVector = emeta.GetDTVector
local ply_SetDTVector = emeta.SetDTVector
local ply_GetTable = emeta.GetTable

local v_Add = vmeta.Add
local v_Normalize = vmeta.Normalize
local v_WithinAABox = vmeta.WithinAABox
local v_Dot = vmeta.Dot
local v_IsEqualTol = vmeta.IsEqualTol
local v_SetUnpacked = vmeta.SetUnpacked

local math_min = math.min
local math_max = math.max
local FrameTime = FrameTime
local Vector = Vector
local Angle = Angle
local ipairs = ipairs

local IN_SPEED = IN_SPEED
local IN_MOVERIGHT = IN_MOVERIGHT
local IN_MOVELEFT = IN_MOVELEFT
local IN_FORWARD = IN_FORWARD
local IN_BACK = IN_BACK

-------------------------------------------------
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
	if ply:IsBot() then cmd:AddKey(IN_FORWARD) end
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

	if ply.DREAMS_onfloor then v_SetUnpacked(vel, vel.x, vel.y, math.Clamp(vel.z, -3, 3))
	elseif vel.z < 0 then v_SetUnpacked(vel, vel.x, vel.y, math_max(math_min(vel.z, -1) * 1.111, -1400)) end
	v_Add(vel, Vector(0, 0, -self.Gravity * FrameTime()))
	mv_SetVelocity(mv, vel)
	return true
end

-- For Debug mostly
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

local InterCylAABB = Dreams.Lib.IntersectABCylinderWithAABB
local InterCylOBB = Dreams.Lib.IntersectABCylinderWithOBB
local InterCylPlane = Dreams.Lib.IntersectABCylinderWithPlane

local vector_up = Vector(0, 0, 1)

local xnorm = Vector(1, 0, 0)
local neg_xnorm = -xnorm
local ynorm = Vector(0, 1, 0)
local neg_ynorm = -ynorm
local znorm = Vector(0, 0, 1)
local neg_znorm = -znorm

local function clear_axes(vel, norm)
	if norm.z < 0 then
		local anorm = norm.z > 0 and znorm or neg_znorm
		vel = vel + anorm * math_max(0, v_Dot(vel, -anorm))
	elseif norm.z >= 0 then
		return vel
	end
	if norm.x ~= 0 then
		local anorm = norm.x > 0 and xnorm or neg_xnorm
		vel = vel + anorm * math_max(0, v_Dot(vel, -anorm))
	end
	if norm.y ~= 0 then
		local anorm = norm.y > 0 and ynorm or neg_ynorm
		vel = vel + anorm * math_max(0, v_Dot(vel, -anorm))
	end
	return vel
end

function DREAMS:DoMove(ply, mv)
	local vel, morg = mv_GetVelocity(mv), ply_GetDTVector(ply, 31)
	local org = morg + vel * FrameTime()
	local ptbl = ply_GetTable(ply)
	local onfloor
	for k, v in ipairs(self.Phys) do
		if not v_WithinAABox(org, v.AA, v.BB) then continue end
		for a, s in ipairs(v) do
			local t = s.PType
			local res, norm, hit
			if t == DREAMSC_AABB then
				res, norm, hit = InterCylAABB(org, 16, 64, s.AA, s.BB)
			elseif t == DREAMSC_OBB then
				local axes = s.OBB_Axes
				res, norm, hit =  InterCylOBB(org, 16, 64, s.Origin, s.OBB_Ang, s.OBB_Min, s.OBB_Max, axes[1], axes[2], axes[3])
			elseif t == DREAMSC_PLANE then
				if not v_WithinAABox(org, s.PAA, s.PBB) then continue end
				for b, side in ipairs(s) do
					local pnorm = side.normal
					local pres, phit = InterCylPlane(org, 16, 64, side.origin, pnorm, side.verts)
					if pres  then
						local hnorm = pnorm
						if v_IsEqualTol(pnorm, vector_up, 0.3) then
							onfloor = true
							hnorm = vector_up
						end
						morg = morg + pnorm * math.abs(math_min(5, v_Dot(phit - org, -pnorm))) * FrameTime()
						org = morg + vel * FrameTime()
						vel = vel + hnorm * math_max(0, v_Dot(vel, -hnorm))
						vel = vel + pnorm * math_max(0, v_Dot(vel, -pnorm))
					end
				end
			end

			if res then
				if v_IsEqualTol(norm, vector_up, 0.5) then
					onfloor = true
				else
					ptbl.DREAMS_onfloor = false
				end
				if hit then vel = vel + hit * 32 end
				vel = vel + norm * math_max(0, v_Dot(vel, -norm))
				vel = clear_axes(vel, norm)
			end
		end
		ptbl.DreamRoom = v.Room
	end

	if onfloor and mv:KeyDown(IN_JUMP) then
		v_SetUnpacked(vel, vel.x, vel.y, self.JumpPower)
		ptbl.DREAMS_onfloor = false
		onfloor = false
	end

	if not onfloor and ptbl.DREAMS_onfloor then
		vel = vel - Vector(0, 0, 40)
		morg = morg - Vector(0, 0, 0.1)
	end
	ptbl.DREAMS_onfloor = onfloor

	ply_SetDTVector(ply, 31, morg + vel * FrameTime())
	mv_SetVelocity(mv, vel)
	return true
end

function DREAMS:FinishMove(ply, mv)
	ply:SetAbsVelocity(mv_GetVelocity(mv))
	if SERVER then ply:DropToFloor() end
	return true
end

-- if onfloor and mv:KeyPressed(IN_JUMP) then
-- 	v_SetUnpacked(vel, vel.x, vel.y, self.JumpPower)
-- end