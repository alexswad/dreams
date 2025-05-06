local lib = Dreams.Lib
local vmf = {}
Dreams.VMF = vmf

local ang_zero = Angle()
local function find(folder, list)
	list = list or {}
	local files, folders = file.Find(folder .. "*", "GAME")
	if not files then return list end
	for k, v in pairs(files) do
		if v:EndsWith(".vmf") then
			table.insert(list, folder .. v)
		end
	end

	for k, v in pairs(folders) do
		find(folder .. v .. "/", list)
	end

	return list
end

local function autocomplete(command, str)
	local maps = find("maps/")
	local tab = {}
	for k, v in pairs(maps) do
		if v:lower():find(str:Trim():lower()) or str:Trim() == "" then
			table.insert(tab, command .. " " .. v)
		end
	end
	return tab
end

local function tovector(str)
	local t = string.Explode(" ", str)
	return Vector(tonumber(t[1]), tonumber(t[2]), tonumber(t[3]))
end
vmf.tovector = tovector

local function toangle(str)
	local t = string.Explode(" ", str)
	return Angle(tonumber(t[1]), tonumber(t[2]), tonumber(t[3]))
end
vmf.toangle = toangle

local function trim(s, char)
	return string.match( s, "^" .. char .. "*(.-)" .. char .. "*$" ) or s
end

local function count(str, it)
	local a = 0
	for k, v in string.gmatch(str, "[" .. it .. "]+") do
		a = a + 1
	end
	return a
end

local function remove_up(t, done)
	done = done or {}
	if not istable(t) or done[t] then return end
	t._up = nil
	done[t] = true
	for k, v in pairs(t) do
		remove_up(v, done)
	end
end

local lheader = [[
#usda 1.0
(
    defaultPrim = "root"
    doc = "Blender v4.3.2"
    metersPerUnit = 1
    upAxis = "Z"
)

def Xform "root" (
    customData = {
        dictionary Blender = {
            bool generated = 1
        }
    }
)
{
]]

local light_str = [[
	def Xform "%i"
    {
        custom string userProperties:blender:object_name = "%t"
        float3 xformOp:rotateXYZ = (0, 0, 0)
        float3 xformOp:scale = (1, 1, 1)
        double3 xformOp:translate = (%p)
        uniform token[] xformOpOrder = ["xformOp:translate", "xformOp:rotateXYZ", "xformOp:scale"]

        def SphereLight "%i"
        {
            float3[] extent = [(-0, -0, -0), (0, 0, 0)]
            color3f inputs:color = (%c)
            float inputs:diffuse = 1
            float inputs:exposure = 0
            float inputs:intensity = 318309.88
            bool inputs:normalize = 1
            float inputs:radius = 0
            float inputs:specular = 0
            bool treatAsPoint = 1
            custom string userProperties:blender:data_name = "%t"
        }
    }
]]

local light_pstr = [[
	def Xform "%i"
    {
        custom string userProperties:blender:object_name = "%t"
        float3 xformOp:rotateXYZ = (%a)
        float3 xformOp:scale = (1, 1, 1)
        double3 xformOp:translate = (%p)
        uniform token[] xformOpOrder = ["xformOp:translate", "xformOp:rotateXYZ", "xformOp:scale"]

        def SphereLight "%i" (
            prepend apiSchemas = ["ShapingAPI"]
        )
        {
            float3[] extent = [(-0, -0, -0), (0, 0, 0)]
            color3f inputs:color = (%c)
            float inputs:diffuse = 1
            float inputs:exposure = 0
            float inputs:intensity = 318309.88
            bool inputs:normalize = 1
            float inputs:radius = 1
            float inputs:shaping:cone:angle = %k
            float inputs:shaping:cone:softness = 0.5
            float inputs:specular = 0
            custom string userProperties:blender:data_name = "%t"
        }
    }
]]

function vmf.SaveLights(fname, lights)
	if table.Count(lights) == 0 then return end
	local str = lheader
	for k, v in pairs(lights) do
		if v.type == "light" then
			local s = light_str
			s = s:Replace("%t", v.name)
			s = s:Replace("%i", "Light_" .. k)
			s = s:Replace("%p", v.pos.x .. ", " .. v.pos.y .. ", " .. v.pos.z)
			s = s:Replace("%c", v.color[1] .. ", " .. v.color[2] .. ", " .. v.color[3])
			str = str .. s
		elseif v.type == "light_spot" then
			local s = light_pstr
			s = s:Replace("%t", v.name)
			s = s:Replace("%i", "Light_" .. k)
			s = s:Replace("%p", v.pos.x .. ", " .. v.pos.y .. ", " .. v.pos.z)
			s = s:Replace("%c", v.color[1] .. ", " .. v.color[2] .. ", " .. v.color[3])
			s = s:Replace("%a", v.angles.p .. ", " .. v.angles.y .. ", " .. v.angles.r)
			s = s:Replace("%k", v.cone or "60")
			str = str .. s
		end
	end
	str = str .. "}"

	Dreams.Print("Generated Blender USD Light Data @ garrysmod/data/dreams/" .. fname .. ".usd.txt")
	file.Write("dreams/" .. fname .. ".usd.txt", str)
end

function vmf.ConvertLightEntity(v, name)
	local bname = name or v.targetname or "Light"

	local light = {
		type = v.classname,
		color = {unpack(string.Explode(" ", v._light))},
		name = bname,
		pos = v.origin,
		angles = v.angles,
		cone = v._cone
	}

	light.color = {tonumber(light.color[1]) / 255, tonumber(light.color[2]) / 255, tonumber(light.color[3]) / 255}
	return light
end

function vmf.ExtractSolids(f)
	local solids = {}
	for k, v in pairs(string.Explode("solid", f)) do
		if k == 1 then continue end
		local str = ""
		for a, b in pairs(string.Explode("}", v)) do
			str = str .. b .. "}"
			if count(str, "{") == count(str, "}") then
				break
			end
		end
		table.insert(solids, str)
	end

	local nsolids = {}
	for k, v in pairs(solids) do
		local t = {sides = {}}
		local wt = t
		for a, b in pairs(string.Explode("\n", v)) do
			b = b:Trim()
			if string.StartsWith(b, "\"") then
				local prop = string.Explode("\"", b)
				local propstr, pr = prop[2], prop[4]
				if propstr == "v" then
					table.insert(wt, tovector(pr))
				elseif propstr == "plane" then
					wt[propstr] = {}
					local verts = string.Explode(") (", pr)
					for c, d in pairs(verts) do
						wt[propstr][c] = tovector(trim(d, "[()]"))
					end
				else
					wt[propstr] = pr
				end
			elseif b == "side" then
				wt = {}
				table.insert(t.sides, wt)
			elseif b ~= "{" and b ~= "}" and b ~= "" then
				wt[b] = {_up = wt}
				wt = wt[b]
			elseif b == "}" then
				wt = wt._up or t
			end
		end

		t.editor = nil
		if table.Count(t.sides) > 0 then
			table.insert(nsolids, t)
		end
	end

	remove_up(nsolids)
	return nsolids
end

function vmf.ExtractEnts(f)
	local entities = {}
	for k, v in pairs(string.Explode("entity", f)) do
		if k == 1 then continue end
		local str = ""
		for a, b in pairs(string.Explode("}", v)) do
			str = str .. b .. "}"
			if count(str, "{") == count(str, "}") then
				break
			end
		end
		table.insert(entities, str)
	end

	for k, v in pairs(entities) do
		local t = {}
		local sid
		for a, b in pairs(string.Explode("\n", v)) do
			b = b:Trim()
			if string.StartsWith(b, "\"") then
				local prop = string.Explode("\"", b)
				local propstr, pr = prop[2], prop[4]
				if sid == true and propstr == "id" then
					t.sid = pr
					break
				end

				if propstr == "origin" then
					t[propstr] = tovector(pr)
				elseif propstr == "angles" then
					t[propstr] = toangle(pr)
				else
					t[propstr] = pr
				end
			elseif string.StartsWith(b, "solid") then
				sid = true
			elseif string.StartsWith(b, "editor") or string.StartsWith(b, "side") then
				break
			end
		end
		entities[k] = t
	end
	return entities
end

DREAMSC_AABB = 1
DREAMSC_OBB = 2
DREAMSC_PLANE = 3

local is_square = lib.IsSquare

local function check_normals(t, n)
	for k, v in pairs(t) do
		if v:IsEqualTol(n, 0.05) or v:IsEqualTol(-n, 0.05) then return false end
	end
	return true
end

function vmf.SolidToPhys(solid, optimize)
	local ptype = DREAMSC_AABB
	local min, max
	local nsides = {DTYPE = "DreamSolid"}
	local mnormals = {}
	local smaterial
	for _, v in pairs(solid.sides) do
		local verts = v.vertices_plus or v.verts
		if not verts then Dreams.Print("VMF is missing important information, re-open with Hammer++ and save before converting") error("Missing index vertices_plus") end
		if not is_square(verts) then ptype = DREAMSC_PLANE end

		local nverts = {}
		local pmin, pmax
		for n, vert in pairs(verts) do
			min, max = lib.MinMaxVecs(min or vert, max or vert, vert)
			pmin, pmax = lib.MinMaxVecs(pmin or vert, pmax or vert, vert)
			nverts[n - 1] = vert
		end
		local middle = (pmax - pmin) / 2 + pmin

		local normal = v.normal or lib.PlaneToNormal(unpack(v.plane))
		local cnorm = lib.MagnitudeToNormal(normal:Unpack())
		if ptype == DREAMSC_AABB and not normal:IsEqualTol(cnorm, 0.1) then ptype = DREAMSC_OBB end
		if check_normals(mnormals, normal) then
			table.insert(mnormals, normal)
		end

		if v.material and v.material:lower():find("nodraw") then continue end
		smaterial = smaterial or v.material
		side = {
			verts = nverts,
			plane = v.plane,
			normal = normal,
			material = v.material,
			id = v.id,
			origin = middle
		}
		table.insert(nsides, side)
	end

	nsides.AA = min
	nsides.BB = max
	nsides.Origin = (max - min) / 2 + min
	if ptype == DREAMSC_OBB then
		local vm = lib.RotationMatrixFromNormals(unpack(mnormals))
		local axes = {vm:GetForward(), vm:GetRight(), vm:GetUp()}
		local ang = vm:GetAngles()
		local omin, omax
		nsides.OBB_Ang = ang
		nsides.OBB_Axes = axes
		for k, v in pairs(solid.sides) do
			for n, vert in pairs(v.vertices_plus) do
				vert = WorldToLocal(vert, ang_zero, nsides.Origin, ang)
				omin, omax = lib.MinMaxVecs(omin or vert, omax or vert, vert)
			end
		end
		nsides.HalfExtents = lib.HalfExtentsFromBox(omin, omax)
		nsides.OBB_Min = omin
		nsides.OBB_Max = omax
	elseif ptype == DREAMSC_AABB then
		nsides.HalfExtents = lib.HalfExtentsFromBox(min, max)
	elseif ptype == DREAMSC_PLANE then
		nsides.PAA = min - Vector(128, 128, 128)
		nsides.PBB = max + Vector(128, 128, 128)
	end

	if optimize and (ptype == DREAMSC_AABB or ptype == DREAMSC_OBB) then
		for _, s in ipairs(nsides) do
			s.plane = nil
			s.verts = nil
		end
	end

	nsides.PType = ptype
	nsides.material = smaterial
	nsides.id = solid.id
	return nsides
end

function vmf.ConvertPropEntity(v)
	local prop = {
		model = v.model,
		skin = v.skin,
		origin = v.origin,
		angles = v.angles,
		solid = tonumber(v.solid) or 2,
	}
	util.PrecacheModel(prop.model)

	local ent = ents.Create("prop_dynamic")
	if not IsValid(ent) then
		ErrorNoHalt("[DREAMS] Failed to create entity reference for prop " .. v.model .. " (Indicies full?)\n")
		return prop
	end

	ent:SetModel(v.model)
	ent:Spawn()
	local obmin, obmax = ent:OBBMins(), ent:OBBMaxs()
	local phys = ent:GetPhysicsObject()
	local mesh = IsValid(phys) and phys:GetMesh() or util.GetModelMeshes(prop.model) and util.GetModelMeshes(prop.model)[1]
	if not IsValid(phys) then Dreams.Debug("Prop " .. v.model .. " has no physics, treating as displacement") end
	SafeRemoveEntity(ent)

	if prop.solid == 2 and obmin then
		prop.phys = lib.GeneratePhysOBB(v.origin, obmin, obmax, v.angles)
	elseif mesh and prop.solid == 6 then
		prop.displace = mesh.triangles and true
		local sides = {}
		local cside = {}
		local cplane = {}
		for i, b in ipairs(mesh.triangles or mesh) do
			cside[(i - 1) % 3 + 1] = b.pos
			cplane[(i - 1) % 3 + 1] = b.pos
			if (i - 1) % 3 + 1 == 3 then
				table.insert(sides, {
					vertices_plus = cside,
					plane = cplane,
				})
				cside = {}
				cplane = {}
			end
		end

		prop.phys = vmf.SolidToPhys({sides = sides})
		Dreams.Lib.PhysOffset({prop.phys}, prop.origin, prop.angles, prop.displace)
	end
	return prop
end

function vmf.ConvertFile(f, optimize)
	local nsolids = {}
	local vents = vmf.ExtractEnts(f)
	local marks = {}
	local lights = {}
	local props = {}
	local triggers = {}

	local min, max
	local solids = vmf.ExtractSolids(f)
	for k, v in pairs(solids) do
		local tbl = vmf.SolidToPhys(v, true)
		nsolids[k] = tbl
		min, max = lib.MinMaxVecs(min or tbl.AA, max or tbl.AA, tbl.AA)
		min, max = lib.MinMaxVecs(min, max, tbl.BB)
	end

	for k, v in pairs(vents) do
		local cname = v.classname
		if cname == "info_teleport_destination" or cname == "info_target" then
			local name = v.targetname or cname
			local mark = {
				pos = v.origin,
				angles = v.angles,
			}
			if marks[name] then
				if marks[name].pos then
					marks[name] = {marks[name]}
				end
				table.insert(marks[name], mark)
			else
				marks[name] = mark
			end
		end
		if cname == "light" or cname == "light_spot" then
			table.insert(lights, vmf.ConvertLightEntity(v))
		end
		if cname == "prop_static" or cname == "prop_dynamic" then
			table.insert(props, vmf.ConvertPropEntity(v))
		end
		if cname:StartsWith("trigger_") and v.sid then
			local solid
			for ks, s in pairs(nsolids) do
				if s.id == v.sid then
					solid = s
					table.remove(nsolids, ks)
					break
				end
			end
			if solid then
				local trigger = {
					name = v.targetname,
					phys = solid,
				}
				table.insert(triggers, trigger)
			end
		end
	end

	for k, v in pairs(props) do
		tbl = v.phys
		if not tbl then continue end
		min, max = lib.MinMaxVecs(min or tbl.AA + v.origin, max or tbl.AA + v.origin, tbl.AA + v.origin)
		min, max = lib.MinMaxVecs(min, max, tbl.BB + v.origin)
	end
	nsolids.AA = min - Vector(128, 128, 128)
	nsolids.BB = max + Vector(128, 128, 128)
	return {
		DTYPE = "DreamRoom",
		phys = nsolids,
		marks = marks,
		props = props,
		lights = lights,
		triggers = triggers,
	}
end

if SERVER then
	concommand.Add("dreams_convertvmf", function(ply, cmd, args)
		if ply and not ply:IsListenServerHost() then print("You must be the server console!") return end

		file.CreateDir("dreams/")
		local name = string.Explode("/", args[1])
		name = name[#name]:StripExtension()
		local f = file.Read(args[1]:Trim(), "GAME")
		local data = vmf.ConvertFile(f, true)
		vmf.SaveLights(name, data.lights)
		Dreams.Bundle.Save(data, name)
	end, autocomplete)
end