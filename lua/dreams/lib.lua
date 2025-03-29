-- Useful math and mesh functions

Dreams.Lib = {}
local lib = Dreams.Lib

local vmeta = FindMetaTable("Vector")
local v_Normalize = vmeta.Normalize
local v_Cross = vmeta.Cross
local v_Dot = vmeta.Dot
local v_DistToSqr = vmeta.DistToSqr
local Vector = Vector
local tbl_Count = table.Count
local ipairs = ipairs

local reverse_tbl = function(tbl)
	local ntbl = {}
	local i = 0
	for k, v in SortedPairs(tbl, true) do
		ntbl[i] = v
		i = i + 1
	end
	return ntbl
end

-- For creating a list of quads to use for rendering meshes
function lib.RectToMesh(l, w, h, off, ignore, reverse, um, vm)
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

	if not ignore[5] then
		table.Add(nverts, {
			-- up
			{pos = blt, u = 0, v = 0},
			{pos = brt, u = 1 * sl, v = 0},
			{pos = frt, u = 1 * sl, v = 1},
			{pos = flt, u = 0, v = 1},
		})
	end

	if not ignore[6] then
		table.Add(nverts, {
			-- down
			{pos = blb, u = 0, v = 0},
			{pos = flb, u = 1 * sl, v = 0},
			{pos = frb, u = 1 * sl, v = 1},
			{pos = brb, u = 0, v = 1},
		})
	end
	if reverse then nverts = table.Reverse(nverts) end
	return nverts
end

-- For creating a list of faces for Dreams Phys
function lib.RectToFaces(l, w, h, off, ignore, reverse)
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
		local verts = {
			[0] = flt,
			[1] = frt,
			[2] = frb,
			[3] = flb,
		}
		if reverse then
			verts = reverse_tbl(verts)
		end
		table.insert(nverts, {
			normal = Vector(1, 0, 0),
			plane = {flt},
			-- front
			verts = verts,
		})
	end
	if not ignore[2] then
		local verts = {
			[0] = frt,
			[1] = brt,
			[2] = brb,
			[3] = frb,
		}
		if reverse then
			verts = reverse_tbl(verts)
		end
		table.insert(nverts, {
			-- right
			normal = Vector(0, 1, 0),
			plane = {frt},
			verts = verts
		})
	end
	if not ignore[3] then
		local verts = {
			[0] = brt,
			[1] = blt,
			[2] = blb,
			[3] = brb,
		}
		if reverse then
			verts = reverse_tbl(verts)
		end
		table.insert(nverts, {
			-- back
			normal = Vector(-1, 0, 0),
			plane = {brt},
			verts = verts,
		})
	end
	if not ignore[4] then
		local verts = {
			[0] = blt,
			[1] = flt,
			[2] = flb,
			[3] = blb,
		}
		if reverse then
			verts = reverse_tbl(verts)
		end
		table.insert(nverts, {
			-- left
			normal = Vector(0, -1, 0),
			plane = {blt},
			verts = verts,
		})
	end

	if not ignore[5] then
		local verts = {
			[0] = blt,
			[1] = brt,
			[2] = frt,
			[3] = flt,
		}
		if reverse then
			verts = reverse_tbl(verts)
		end
		table.insert(nverts, {
			-- up
			normal = Vector(0, 0, 1),
			plane = {blt},
			verts = verts,
		})
	end

	if not ignore[6] then
		local verts = {
			[0] = blb,
			[1] = flb,
			[2] = frb,
			[3] = brb,
		}
		if reverse then
			verts = reverse_tbl(verts)
		end
		table.insert(nverts, {
			-- down
			normal = Vector(0, 0, -1),
			plane = {blb},
			verts = verts
		})
	end
	return nverts
end

function lib.MinMaxVecs(xmin, xmax, vec)
	return Vector(math.min(xmin.x, vec.x), math.min(xmin.y, vec.y), math.min(xmin.z, vec.z)), Vector(math.max(xmax.x, vec.x), math.max(xmax.y, vec.y), math.max(xmax.z, vec.z))
end

local intersectrayplane = util.IntersectRayWithPlane
local normal = function(c, b, a)
	local cr = v_Cross(b - a, c - a)
	v_Normalize(cr)
	return cr
end
lib.PlaneToNormal = normal

local function check(a, b, c, p)
	local cr1 = v_Cross(b - a, c - a)
	local cr2 = v_Cross(b - a, p - a)
	return v_Dot(cr1, cr2) >= 0
end
lib.InsideOutTest = check

function lib.TracePhys(phys, start, dir, dist_sqr)
	local chit, cwd, cs
	for _, s in ipairs(phys) do
		local plane = s.plane
		local norm = s.normal or normal(plane[1], plane[2], plane[3])
		s.normal = norm
		local hit = intersectrayplane(start, dir, plane[1], norm)
		local wd = hit and v_Dot(start - hit, norm) or 0
		if hit and wd > 0 then
			local hdist = v_DistToSqr(hit, start)
			if dist_sqr and hdist > dist_sqr then continue end
			if chit and v_DistToSqr(chit, start) < hdist then continue end
			local verts = s.verts
			local n_verts = tbl_Count(verts)

			local dobreak
			for i = 0, n_verts - 1 do
				if not check(verts[i], verts[(i + 1) % n_verts], verts[(i + 2) % n_verts], hit) then
					dobreak = true
					break
				end
			end
			if dobreak then continue end
			chit = hit
			cwd = wd
			cs = s
		end
	end
	return chit, cwd, cs
end