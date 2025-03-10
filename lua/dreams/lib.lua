-- Useful math and mesh functions

Dreams.Lib = {}
local lib = Dreams.Lib

local vmeta = FindMetaTable("Vector")
local v_Normalize = vmeta.Normalize
local v_Cross = vmeta.Cross
local Vector = Vector

-- For creating a list of quads to use for rendering meshes
function lib.RectToMesh(l, w, h, off, ignore, um, vm)
	local frt = Vector(l, w, h) + off
	local flt = Vector(l, 0, h) + off
	local frb = Vector(l, w, 0) + off
	local flb = Vector(l, 0, 0) + off
	local brt = Vector(0, w, h) + off
	local blt = Vector(0, 0, h) + off
	local brb = Vector(0, w, 0) + off
	local blb = Vector(0, 0, 0) + off

	local nverts = {}
	ignore = ignore or {}
	local sw = w * (vm or 0.01)
	local sl = l * (um or 0.01)
	if not ignore[1] then
		table.Add(nverts, {
			-- front
			{pos = flt, u = 0, v = 0},
			{pos = frt, u = 1 * sw, v = 0},
			{pos = frb, u = 1 * sw, v = 1},
			{pos = flb, u = 0, v = 1},
		})
	end
	if not ignore[2] then
		table.Add(nverts, {
			-- right
			{pos = frt, u = 0, v = 0},
			{pos = brt, u = 1 * sl, v = 0},
			{pos = brb, u = 1 * sl, v = 1},
			{pos = frb, u = 0, v = 1},
		})
	end
	if not ignore[3] then
		table.Add(nverts, {
			-- back
			{pos = brt, u = 0, v = 0},
			{pos = blt, u = 1 * sw, v = 0},
			{pos = blb, u = 1 * sw, v = 1},
			{pos = brb, u = 0, v = 1},
		})
	end
	if not ignore[4] then
		table.Add(nverts, {
			-- left
			{pos = blt, u = 0, v = 0},
			{pos = flt, u = 1 * sl, v = 0},
			{pos = flb, u = 1 * sl, v = 1},
			{pos = blb, u = 0, v = 1},
		})
	end
	return nverts
end

-- For creating a list of faces for Dreams Phys
function lib.RectToFaces(l, w, h, off, ignore)
	local frt = Vector(l, w, h) + off
	local flt = Vector(l, 0, h) + off
	local frb = Vector(l, w, 0) + off
	local flb = Vector(l, 0, 0) + off
	local brt = Vector(0, w, h) + off
	local blt = Vector(0, 0, h) + off
	local brb = Vector(0, w, 0) + off
	local blb = Vector(0, 0, 0) + off

	local nverts = {}
	ignore = ignore or {}
	if not ignore[1] then
		table.insert(nverts, {
			normal = Vector(1, 0, 0),
			plane = {flt},
			-- front
			verts = {
				[0] = flt,
				[1] = frt,
				[2] = frb,
				[3] = flb,
			},
		})
	end
	if not ignore[2] then
		table.insert(nverts, {
			-- right
			normal = Vector(0, 1, 0),
			plane = {frt},
			verts = {
				[0] = frt,
				[1] = brt,
				[2] = brb,
				[3] = frb,
			},
		})
	end
	if not ignore[3] then
		table.insert(nverts, {
			-- back
			normal = Vector(-1, 0, 0),
			plane = {brt},
			verts = {
				[0] = brt,
				[1] = blt,
				[2] = blb,
				[3] = brb,
			}
		})
	end
	if not ignore[4] then
		table.insert(nverts, {
			-- left
			normal = Vector(0, -1, 0),
			plane = {blt},
			verts = {
				[0] = blt,
				[1] = flt,
				[2] = flb,
				[3] = blb,
			}
		})
	end
	return nverts
end

function lib.PlaneToNormal(c, b, a)
	local cr = v_Cross(b - a, c - a)
	v_Normalize(cr)
	return cr
end

function lib.MinMaxVecs(xmin, xmax, vec)
	return Vector(math.min(xmin.x, vec.x), math.min(xmin.y, vec.y), math.min(xmin.z, vec.z)), Vector(math.max(xmax.x, vec.x), math.max(xmax.y, vec.y), math.max(xmax.z, vec.z))
end