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

concommand.Add("dreams_convertfile", function(ply, cmd, args)
	local f = file.Read(args[1]:Trim(), "GAME")

	local function count(str, it)
		local a = 0
		for k, v in string.gmatch(str, "[" .. it .. "]+") do
			a = a + 1
		end
		return a
	end

	local off = Vector(0, 0, 0)

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

	function remove_up(t, done)
		done = done or {}
		if not istable(t) or done[t] then return end
		t._up = nil
		done[t] = true
		for k, v in pairs(t) do
			remove_up(v, done)
		end
	end

	function tovector(str)
		local t = string.Explode(" ", str)
		return Vector(tonumber(t[1]), tonumber(t[2]), tonumber(t[3])) - off
	end

	function trim(s, char)
		return string.match( s, "^" .. char .. "*(.-)" .. char .. "*$" ) or s
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

	remove_up(solids)
	test_solids = solids

	test_sides = {}
	for k, v in pairs(solids) do
		for a, side in pairs(v.sides) do
			if not side.material or side.material:lower():find("nodraw") then continue end
			side = {
				vertices = side.vertices_plus,
				plane = side.plane
			}
			table.insert(test_sides, side)
		end
	end

	PrintTable(test_sides)
	local name = string.Explode("/", args[1])
	name = name[#name]
	file.CreateDir("dreams/")
	file.Write("dreams/" .. name:Trim():StripExtension() .. ".dat", util.TableToJSON(test_sides))

	SetGlobalString("dreams_phys", name:Trim():StripExtension():Trim())
end, autocomplete)