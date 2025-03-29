local Dreams = Dreams
local DREAMS = Dreams.Meta

local vmeta = FindMetaTable("Vector")
local v_Normalize = vmeta.Normalize
local v_Cross = vmeta.Cross

local Vector = Vector
local Angle = Angle
local ipairs = ipairs

local normal = function(c, b, a)
	local cr = v_Cross(b - a, c - a)
	v_Normalize(cr)
	return cr
end

local function minmax(xmin, xmax, vec)
	return Vector(math.min(xmin.x, vec.x), math.min(xmin.y, vec.y), math.min(xmin.z, vec.z)), Vector(math.max(xmax.x, vec.x), math.max(xmax.y, vec.y), math.max(xmax.z, vec.z))
end

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

	if debug == 1 or debug == 2 or debug == 3 or debug == 4 then
		for k, v in ipairs(self.Phys) do
			if (debug == 1 or debug == 4) and v.OBB then
				local col = HSVToColor(k * 20, 1, 1)
				render.DrawWireframeBox(vector_origin, Angle(), v.OBB[1], v.OBB[2], col, true)
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