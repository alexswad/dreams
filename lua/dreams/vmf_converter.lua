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

local function toangle(str)
	local t = string.Explode(" ", str)
	return Angle(tonumber(t[1]), tonumber(t[2]), tonumber(t[3]))
end

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

local function write_lights(fname, lights)
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

	print("DREAMS: Generated Blender USD Light Data garrysmod/data/dreams/" .. fname .. ".usd.txt")
	file.Write("dreams/" .. fname .. ".usd.txt", str)
end

concommand.Add("dreams_convertfile", function(ply, cmd, args)
	local f = file.Read(args[1]:Trim(), "GAME")

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

	local function remove_up(t, done)
		done = done or {}
		if not istable(t) or done[t] then return end
		t._up = nil
		done[t] = true
		for k, v in pairs(t) do
			remove_up(v, done)
		end
	end

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
		solids[k] = t
	end

	for k, v in pairs(entities) do
		local t = {}
		for a, b in pairs(string.Explode("\n", v)) do
			b = b:Trim()
			if string.StartsWith(b, "\"") then
				local prop = string.Explode("\"", b)
				local propstr, pr = prop[2], prop[4]
				if propstr == "origin" then
					t[propstr] = tovector(pr)
				elseif propstr == "angles" then
					t[propstr] = toangle(pr)
				else
					t[propstr] = pr
				end
			elseif string.StartsWith(b, "editor") then
				break
			end
		end
		entities[k] = t
	end

	local names = {}
	local lights = {}
	for k, v in pairs(entities) do
		if v.classname ~= "light" and v.classname ~= "light_spot" then continue end
		local name = v.targetname or "Light_"
		if names[name] then
			name = name .. names[name]
		end
		names[name] = (names[name] or 1) + 1

		local light = {
			type = v.classname,
			color = {unpack(string.Explode(" ", v._light))},
			name = name,
			pos = v.origin,
			angles = v.angles,
			cone = v._cone
		}

		light.color = {tonumber(light.color[1]) / 255, tonumber(light.color[2]) / 255, tonumber(light.color[3]) / 255}
		table.insert(lights, light)
	end

	remove_up(solids)
	test_solids = solids

	test_sides = {}
	local min, max
	local function minmax(xmin, xmax, vec)
		return Vector(math.min(xmin.x, vec.x), math.min(xmin.y, vec.y), math.min(xmin.z, vec.z)), Vector(math.max(xmax.x, vec.x), math.max(xmax.y, vec.y), math.max(xmax.z, vec.z))
	end
	for k, v in pairs(solids) do
		for a, side in pairs(v.sides) do
			for _, vert in pairs(side.vertices_plus) do
				min, max = minmax(min or vert, max or vert, vert)
			end
			local newverts = {}
			for n, vert in pairs(side.vertices_plus) do
				newverts[n - 1] = vert // dear john Lua... I know where you live...
			end

			if not side.material or side.material:lower():find("nodraw") then continue end
			side = {
				verts = newverts,
				plane = side.plane
			}
			table.insert(test_sides, side)
		end
	end
	test_sides.OBB = {min, max}

	//PrintTable(test_sides)
	local name = string.Explode("/", args[1])
	name = name[#name]
	file.CreateDir("dreams/")
	file.Write("dreams/" .. name:Trim():StripExtension() .. ".dat", util.Compress(util.TableToJSON(test_sides)))
	write_lights(name:Trim():StripExtension(), lights)
	print("DREAMS: Generated DREAMINFO bin garrysmod/data/dreams/" .. name:Trim():StripExtension() .. ".dat")
end, autocomplete)