local Dreams = Dreams
local DREAMS = Dreams.Meta

local Vector = Vector
local Angle = Angle
local ipairs = ipairs

local ang_zero = Angle(0, 0, 0)
local lib = Dreams.Lib
function DREAMS:Draw(ply, debug)
	local porg = ply:GetDTVector(31)
	ply:SetPos(porg)
	ply:SetNetworkOrigin(porg)
	for k, v in ipairs(self.ListRooms) do
		if not IsValid(v.CMDL) and v.CMDL ~= false then
			v.CMDL = v.mdl and ClientsideModelSafe(v.mdl) or false
			v.CMDL:SetNoDraw(true)
			v.CMDL:SetRenderOrigin(v.offset)
		elseif v.CMDL == false then continue end
		if debug ~= 1 and ply.DreamRoom and ply.DreamRoom ~= v then continue end

		render.SuppressEngineLighting(true)
		render.SetAmbientLight(0, 0 , 0)
		if v.Lighting then
			render.ResetModelLighting(v.Lighting[1], v.Lighting[2], v.Lighting[3])
		else
			render.ResetModelLighting(1, 1, 1)
		end

		v.CMDL:DrawModel()

		if v.Props then
			for a, b in ipairs(v.Props) do
				if not IsValid(b.CMDL) and b.CMDL ~= false then
					b.CMDL = b.model and ClientsideModelSafe(b.model) or false
					b.CMDL:SetNoDraw(true)
					b.CMDL:SetRenderOrigin(b.pos)
					b.CMDL:SetRenderAngles(b.angles)
				elseif b.CMDL == false then continue end
				b.CMDL:DrawModel()
			end
		end
		render.SuppressEngineLighting(false)
	end

	for k, v in ipairs(player.GetAll()) do
		if v:GetDreamID() ~= self.ID or v == ply then continue end
		render.SuppressEngineLighting(true)

		v:SetNetworkOrigin(v:GetDTVector(31))

		if not v.DreamRoomCache or v.DreamRoomCache < CurTime() then
			local pos = v:GetDreamPos()
			for a, room in ipairs(self.ListRooms) do
				if room.phys and pos:WithinAABox(room.phys.AA, room.phys.BB) then
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

	debug = debug or self.Debug
	if debug == 1 and ply.DreamRoom then
		local height = 64
		local rad = 16
		local res, norm, middle = false
		local didhit = false

		local thit = lib.TraceRayPhys(ply.DreamRoom.phys, ply:EyePos(), ply:EyeAngles():Forward(), 500)

		render.DrawLine(ply:EyePos() - Vector(0, 10, 10), ply:EyePos() + ply:EyeAngles():Forward() * 500, thit and Color(0, 255, 0) or Color(255, 0 , 0), false)

		for k, v in ipairs(ply.DreamRoom.phys) do

			if v.PType == DREAMSC_AABB then
				render.DrawWireframeBox(vector_origin, ang_zero, v.AA, v.BB, Color(255, 0, 0), true)
			elseif v.PType == DREAMSC_OBB then
				render.DrawWireframeBox(v.Origin or vector_origin, v.OBB_Ang or ang_zero, v.OBB_Min or v.AA, v.OBB_Max or v.BB, Color(122, 40, 230), true)
			elseif v.PType == DREAMSC_PLANE then
				for _, s in ipairs(v) do
					local pres, hit = lib.IntersectABCylinderWithPlane(porg, rad, height, s.origin, s.normal, s.verts)
					local verts = s.verts
					local n_verts = table.Count(verts)
					for i = 0, n_verts - 1 do
					render.DrawLine(verts[i], verts[(i + 1) % n_verts], pres and Color(0, 255, 0) or Color(255, 255, 255), pres)
					end
					if pres then
						render.DrawWireframeSphere(hit, 5, 5, 5, Color(0, 255, 0))
					end
				end
			end
			if v.PType == DREAMSC_OBB then
				local axes = v.OBB_Axes
				res, norm, middle = lib.IntersectABCylinderWithOBB(porg, rad, height, v.Origin, v.OBB_Ang, v.OBB_Min, v.OBB_Max, axes[1], axes[2], axes[3])
			elseif v.PType == DREAMSC_AABB then
				res, norm, middle = lib.IntersectABCylinderWithAABB(porg, rad, height, v.AA, v.BB)
			end
			if res and norm and v.PType ~= DREAMSC_PLANE then
				render.DrawWireframeSphere(v.Origin, 3, 3, 3, Color(255, 0, 0), true)
				middle = middle * norm + porg
				render.DrawWireframeSphere(middle, 3, 3, 3, Color(255, 0, 0), true)
				local rot, rot_end, rot_three = middle, middle + norm * 25, middle + norm * 50
				render.DrawLine(rot, rot_end, Color(255, 0, 0), false)
				render.DrawLine(rot_end, rot_three, Color(0, 255, 0), false)
				didhit = true
			end
		end
		render.DrawWireframeBox(porg, Angle(), Vector(-rad, -rad, 0), Vector(rad, rad, height), didhit and Color(0, 255, 0) or Color(0, 0, 255))
	end
end

function DREAMS:SetupFog()
end

local height = Vector(0, 0, 64)
function DREAMS:CalcView(ply, view)
	view.angles = ply:EyeAngles()
	view.origin = ply:GetDTVector(31) + height
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