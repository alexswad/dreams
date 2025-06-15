local Dreams = Dreams
local DREAMS = Dreams.Meta

local Vector = Vector
local Angle = Angle
local ipairs = ipairs

local ang_zero = Angle(0, 0, 0)
local lib = Dreams.Lib

local d_red = Color(255, 0, 0)
local d_green = Color(0, 255, 0)
local d_blue = Color(0, 0, 255)
local d_pink = Color(199, 0, 166)
local d_orange = Color(253, 135, 0)
local d_purple = Color(111, 0, 255)
local d_white = Color(255, 255, 255)

function DREAMS:Draw(ply, rt, debug)
	debug = debug or self.Debug
	local porg = ply:GetDTVector(31)
	if not rt then
		ply:SetPos(porg)
		--ply:SetNetworkOrigin(porg)
	end

	self:RenderRooms(ply, rt or debug ~= 0)
	self:RenderPlayers(ply, rt or debug ~= 0)
	self:RenderDebug(ply, debug)
end

function DREAMS:DrawPropModel(b)
	if not IsValid(b.CMDL) and b.CMDL ~= false then
		b.CMDL = b.model and ClientsideModelSafe(b.model) or false
		b.CMDL:SetNoDraw(true)
		b.CMDL:SetRenderOrigin(b.origin)
		b.CMDL:SetRenderAngles(b.angles)
		if b.scale then b.CMDL:SetModelScale(b.scale) end
	elseif b.CMDL == false then return end
	b.CMDL:DrawModel()
end

function DREAMS:RenderProps(props)
	for a, b in ipairs(props) do
		self:DrawPropModel(b)
	end
end

function DREAMS:RenderRooms(ply, drawall)
	if game.SinglePlayer() and (not ply.DreamRoomCache or ply.DreamRoomCache < CurTime()) then
		local pos = ply:GetDreamPos()
		for a, room in ipairs(self.ListRooms) do
			if room.phys and pos:WithinAABox(room.phys.AA, room.phys.BB) then
				ply.DreamRoom = room
				break
			end
		end
		ply.DreamRoomCache = CurTime() + 0.1
	end

	for k, v in ipairs(self.ListRooms) do
		if not IsValid(v.CMDL) and v.CMDL ~= false then
			v.CMDL = v.mdl and ClientsideModelSafe(v.mdl, RENDERGROUP_BOTH) or false
			if v.CMDL then
				v.CMDL:SetNoDraw(true)
				v.CMDL:SetRenderOrigin(v.mdl_origin and v.offset + v.mdl_origin or v.offset)
				v.CMDL:SetRenderAngles(v.mdl_angles or ang_zero)
				v.CMDL:SetModelScale(v.mdl_scale or 1)
				if v.SetupCMDL then v:SetupCMDL(v.CMDL) end
			end
		end

		if not drawall and ply and ply.DreamRoom and ply.DreamRoom ~= v then continue end

		render.SuppressEngineLighting(true)
		render.SetAmbientLight(0, 0 , 0)
		if v.Lighting then
			render.ResetModelLighting(v.Lighting[1], v.Lighting[2], v.Lighting[3])
		else
			render.ResetModelLighting(1, 1, 1)
		end

		if v.CMDL and not v.nodraw then
			v.CMDL:DrawModel()
		end

		if v.props then
			self:RenderProps(v.props)
		end
		render.SuppressEngineLighting(false)
	end
end

function DREAMS:RenderPlayers(ply, drawall)
	for k, v in ipairs(player.GetAll()) do
		if v:GetDreamID() ~= self.ID or v == ply then continue end
		render.SuppressEngineLighting(true)

		v.Dreams_FDraw = true
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

		if v.DreamRoom ~= ply.DreamRoom and not drawall then continue end
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

function DREAMS:RenderDebug(ply, debug)
	if not ply then return end
	local porg = ply:GetDTVector(31)
	if debug == 1 and ply.DreamRoom then
		local height = 64
		local rad = 16
		local res, norm, middle = false
		local didhit = false
		local phys = ply.DreamRoom.phys
		if not phys then return end

		local thit, _, _, csolid, cside = lib.TraceRayPhys(phys, ply:EyePos(), ply:EyeAngles():Forward(), 100)
		--print(csolid and csolid.id, cside and cside.id)

		render.DrawLine(ply:EyePos() - Vector(0, 10, 10), ply:EyePos() + ply:EyeAngles():Forward() * 100, thit and d_green or d_red, false)
		for k, v in ipairs(phys) do
			if v.PType == DREAMSC_AABB then
				render.DrawWireframeBox(vector_origin, ang_zero, v.AA, v.BB, d_red, false)
			elseif v.PType == DREAMSC_OBB then
				render.DrawWireframeBox(v.Origin or vector_origin, v.OBB_Ang or ang_zero, v.OBB_Min or v.AA, v.OBB_Max or v.BB, d_purple, false)
			elseif v.PType == DREAMSC_PLANE then
				for _, s in ipairs(v) do
					local pres, hit = lib.IntersectABCylinderWithPlane(porg, rad, height, s.origin, s.normal, s.verts, s.size)
					local verts = s.verts
					local n_verts = #verts + 1
					for i = 0, n_verts - 1 do
					render.DrawLine(verts[i], verts[(i + 1) % n_verts], pres and d_green or d_white, not pres)
					end
					if pres then
						render.DrawWireframeSphere(hit, 5, 5, 5, d_green)
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
				render.DrawWireframeSphere(v.Origin, 3, 3, 3, d_red, false)
				middle = middle * norm + porg
				render.DrawWireframeSphere(middle, 3, 3, 3, d_red, false)
				local rot, rot_end, rot_three = middle, middle + norm * 25, middle + norm * 50
				render.DrawLine(rot, rot_end, d_red, false)
				render.DrawLine(rot_end, rot_three, d_green, false)
				didhit = true
			end
		end
		render.DrawWireframeBox(porg, Angle(), Vector(-rad, -rad, 0), Vector(rad, rad, height), didhit and d_green or d_blue)
		return csolid and csolid.id, cside and cside.id
	elseif debug == 2 and ply.DreamRoom then
		local marks = ply.DreamRoom.marks
		if marks then
			for k, v in pairs(marks) do
				if not v.pos then
					for a, b in ipairs(v) do
						render.DrawWireframeSphere(b.pos, 3, 3, 3, b.Color or d_red, false)
					end
				else
					render.DrawWireframeSphere(v.pos, 3, 3, 3, v.Color or d_red, false)
				end
			end
		end

		local triggers = ply.DreamRoom.triggers
		if triggers then
			for k, v in pairs(triggers) do
				v = v.phys
				if not v.AA then
					for a, b in ipairs(v) do
						render.DrawWireframeBox(vector_origin, ang_zero, b.AA, b.BB, d_orange, false)
					end
				else
					render.DrawWireframeBox(vector_origin, ang_zero, v.AA, v.BB, d_orange, false)
				end
			end
		end

		local entities = ply.DreamRoom.entities
		if not entities then return end
		for k, v in pairs(entities) do
			v = v.phys
			render.DrawWireframeBox(vector_origin, ang_zero, v.AA, v.BB, d_pink, false)
		end
	elseif debug == 3 and ply.DreamRoom then
		local phys = ply.DreamRoom.phys
		if not phys then return end
		for k, v in ipairs(phys) do
			if v.AA then
				render.DrawWireframeBox(vector_origin, ang_zero, v.AA, v.BB, d_red, true)
			end
			if v.PAA then
				render.DrawWireframeBox(vector_origin, ang_zero, v.PAA, v.PBB, d_pink, true)
			end
		end

		if not phys.AA then return end
		render.DrawWireframeBox(vector_origin, ang_zero, phys.AA, phys.BB, d_green, false)
	elseif debug == 4 and ply.DreamRoom then
		local phys = ply.DreamRoom.phys
		if not phys then return end
		for k, v in ipairs(phys) do
			for _, s in ipairs(v) do
				render.DrawWireframeSphere(s.origin, 5, 5, 5, d_red)
			end
		end
	end
end

function DREAMS:SetupFog()
end

local height = Vector(0, 0, 64)
function DREAMS:CalcView(ply, view)
	view.angles = ply:EyeAngles()
	view.origin = ply:GetDTVector(31) + height
end

function DREAMS:RenderScene(ply, rt)
	local view = rt or {
		origin = vector_origin,
		angles = ang_zero,
	}

	if not self:SetupFog(ply) then render.FogMode(MATERIAL_FOG_NONE) end
	if not rt then self:CalcView(ply, view) end
	cam.Start3D(view.origin, view.angles, view.fov, 0, 0, view.w or ScrW(), view.h or ScrH())
	self:Draw(ply, rt)
	cam.End3D()

	if rt then return true end
	cam.Start2D()
	self:DrawHUD(ply, ScrW(), ScrH())
	cam.End2D()
	return true
end