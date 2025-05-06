local lib = Dreams.Lib or {}
Dreams.Lib = lib
local vmeta = FindMetaTable("Vector")
local Vector = Vector
local Angle = Angle
local v_DistToSqr = vmeta.DistToSqr
-- local v_Sub = vmeta.Sub
-- local v_Add = vmeta.Add
local v_Unpack = vmeta.Unpack
local v_Dot = vmeta.Dot
local v_SetUnpacked = vmeta.SetUnpacked
local LocalToWorld = LocalToWorld
local WorldToLocal = WorldToLocal
local v_Normalize = vmeta.Normalize
local v_Cross = vmeta.Cross
local math = math
local math_min = math.min
local math_max = math.max
local math_abs = math.abs
local function math_Clamp(_in, low, high)
	return math_min(math_max(_in, low), high)
end
local table = table
local table_Count = table.Count
local vector_up = Vector(0, 0, 1)
---------------------------------------------------------
local function check(a, b, c, p)
	local cr1 = v_Cross(b - a, c - a)
	local cr2 = v_Cross(b - a, p - a)
	return v_Dot(cr1, cr2) >= 0
end
lib.InsideOutTest = check

local ang_zero = Angle(0, 0, 0)
local xnorm = Vector(1, 0, 0)
local neg_xnorm = -xnorm
local ynorm = Vector(0, 1, 0)
local neg_ynorm = -ynorm
local znorm = Vector(0, 0, 1)
local neg_znorm = -znorm

local function highest_mag_norm(xdelta, ydelta, zdelta, xsize, ysize, zsize)
	local axd = math_abs(xdelta)
	local ayd = math_abs(ydelta)
	local azd = math_abs(zdelta)
	local res = math_max(axd, ayd, azd)
	if res == axd then
		return xdelta > 0 and xnorm or neg_xnorm
	elseif res == ayd then
		return ydelta > 0 and ynorm or neg_ynorm
	elseif res == azd then
		return zdelta > 0 and znorm or neg_znorm
	end
end
lib.MagnitudeToNormal = highest_mag_norm

local function norm_compare(xdelta, ydelta, zdelta, xsize, ysize, zsize)
	local axd = math_abs(xdelta) - xsize
	local ayd = math_abs(ydelta) - ysize
	local azd = math_abs(zdelta) - zsize
	local res = math_max(axd, ayd, azd)
	if res == axd then
		return xdelta > 0 and xnorm or neg_xnorm
	elseif res == ayd then
		return ydelta > 0 and ynorm or neg_ynorm
	elseif res == azd then
		return zdelta > 0 and znorm or neg_znorm
	end
end

local function highest_mag(xdelta, ydelta, zdelta)
	local axd = math_abs(xdelta)
	local ayd = math_abs(ydelta)
	local azd = math_abs(zdelta)
	local mags = {{d = "x", axd}, {d = "y", ayd}, {d = "z", azd}}
	table.sort(mags, function(a, b) return a[1] > b[1] end)
	return mags[1].d, mags[2].d, mags[3].d
end
lib.OrderedHighestMag = highest_mag

local mvec = Vector()
local function IntersectABCylinderWithAABB(cylOrg, cylRad, cylHeight, boxmin, boxmax)
	local xmin, ymin, zmin = v_Unpack(boxmin)
	local xmax, ymax, zmax = v_Unpack(boxmax)
	local cx, cy, cz = v_Unpack(cylOrg)
	local mcx, mcy = math_Clamp(cx, xmin, xmax), math_Clamp(cy, ymin, ymax)

	v_SetUnpacked(mvec, mcx, mcy, cz)
	if v_DistToSqr(mvec, cylOrg) > cylRad ^ 2 then return false end

	cylHeight = cylHeight / 2
	local zsize = (zmax - zmin) / 2
	local zdelta = cz + cylHeight - (zmin + zsize)
	if zsize + cylHeight < math_abs(zdelta) then return false end

	local xsize, ysize = (xmax - xmin) / 2, (ymax - ymin) / 2
	local xdelta, ydelta = cx - (xmin + xsize), cy - (ymin + ysize)
	ydist = ysize - math_abs(ydelta) + cylRad
	xdist = xsize - math_abs(xdelta) + cylRad
	zdist = zsize - math_abs(zdelta) + cylHeight

	local norm = norm_compare(xdelta, ydelta, zdelta, xsize, ysize, zsize)

	return true, norm, Vector(math_max(0, xdist * norm.x), math_max(0, ydist * norm.y), math_max(0, zdist * norm.z))
end
lib.IntersectABCylinderWithAABB = IntersectABCylinderWithAABB

function lib.IntersectABCylinderWithOBB(cylOrg, cylRad, cylHeight, org, angle, boxmin, boxmax, ax, ay, az)
	cylOrg = WorldToLocal(cylOrg, ang_zero, org, angle)
	local xmin, ymin, zmin = v_Unpack(boxmin)
	local xmax, ymax, zmax = v_Unpack(boxmax)
	local cx, cy, cz = v_Unpack(cylOrg)
	local mcx, mcy = math_Clamp(cx, xmin, xmax), math_Clamp(cy, ymin, ymax)
	local xdot, ydot = v_Dot(ax, vector_up) * cylHeight, v_Dot(ay, vector_up) * cylHeight
	v_SetUnpacked(mvec, mcx, mcy, cz)
	if v_DistToSqr(mvec, cylOrg) > cylRad ^ 2 + math.abs(xdot) ^ 2 + math.abs(ydot) ^ 2 then return false end

	local zsize = (zmax - zmin) / 2
	local zdelta = cz + v_Dot(az, vector_up) * cylHeight / 2 - (zmin + zsize)
	if zsize + cylHeight / 2 < math_abs(zdelta) then return false end

	local xsize, ysize = (xmax - xmin) / 2, (ymax - ymin) / 2
	local xdelta, ydelta = cx - (xmin + xsize), cy - (ymin + ysize)
	local norm = norm_compare(xdelta, ydelta, zdelta, xsize, ysize, zsize)

	ydist = ysize - math_abs(ydelta) + cylRad
	xdist = xsize - math_abs(xdelta) + cylRad
	zdist = zsize - math_abs(zdelta) + cylHeight / 2
	local tnorm = LocalToWorld(norm, ang_zero, vector_origin, angle)
	local dist = Vector(math_max(0, xdist * norm.x), math_max(0, ydist * norm.y), math_max(0, zdist * norm.z))

	return true, tnorm, LocalToWorld(dist, ang_zero, vector_origin, angle)
end

local function IntersectSphereWithAABB(org, rad, boxmin, boxmax)
	local xmin, ymin, zmin = v_Unpack(boxmin)
	local xmax, ymax, zmax = v_Unpack(boxmax)
	local cx, cy, cz = v_Unpack(org)
	local mcx, mcy, mcz = math_Clamp(cx, xmin, xmax), math_Clamp(cy, ymin, ymax), math_Clamp(cz, zmin, zmax)

	v_SetUnpacked(mvec, mcx, mcy, mcz)
	if v_DistToSqr(mvec, org) > rad ^ 2 then return false end

	local xsize, ysize, zsize = (xmax - xmin) / 2, (ymax - ymin) / 2, (zmax - zmin) / 2
	local xdelta, ydelta, zdelta = cx - (xmin + xsize), cy - (ymin + ysize), cz - (zmin + zsize)
	ydist = ysize - math_abs(ydelta) + rad
	xdist = xsize - math_abs(xdelta) + rad
	zdist = zsize - math_abs(zdelta) + rad

	return true, norm_compare(xdelta, ydelta, zdelta, xsize, ysize, zsize), Vector(xdist, ydist, zdist)
end
lib.IntersectSphereWithAABB = IntersectSphereWithAABB

function lib.IntersectSphereWithOBB(sorg, rad, org, angle, boxmin, boxmax)
	local torg = WorldToLocal(sorg, ang_zero, org, angle)
	local res, mag, vec = IntersectSphereWithAABB(torg, rad * 2, boxmin, boxmax)
	if not res then return false end
	local tmag, tvec = LocalToWorld(mag, ang_zero, vector_origin, angle), LocalToWorld(vec, ang_zero, org, angle)
	return true, tmag, tvec
end

function lib.IntersectABCylinderWithPlane(cylOrg, rad, height, org, pnormal, verts)
	local ox, oy, oz = v_Unpack(org)
	local cx, cy, cz = v_Unpack(cylOrg)

	v_SetUnpacked(mvec, cx - ox, cy - oy, cz - oz + height / 2)
	local d = v_Dot(pnormal, mvec)
	if math_abs(d) > rad + math_abs(v_Dot(pnormal, vector_up) * height / 4) then return false end

	local hit = Vector(cx, cy, cz + height / 2) - pnormal * d
	local pcheck = hit + (org - hit):GetNormalized() * math_abs(d) / 2

	if verts then
		local n_verts = #verts + 1
		for i = 0, n_verts - 1 do
			if not check(verts[i], verts[(i + 1) % n_verts], verts[(i + 2) % n_verts], pcheck) then
				return false
			end
		end
	end
	return true, hit
end

local ir_obb = util.IntersectRayWithOBB
local ir_plane = util.IntersectRayWithPlane

function lib.IntersectRayWithPPoly(start, dir, dist, origin, norm, verts)
	local hit = ir_plane(start, dir, origin, norm)
	local wd = hit and v_Dot(start - hit, norm) or 0
	if hit and wd > 0 then
		local n_verts = table_Count(verts)
		if dist ^ 2 < v_DistToSqr(hit, start) then return end
		for i = 0, n_verts - 1 do
			if not check(verts[i], verts[(i + 1) % n_verts], verts[(i + 2) % n_verts], hit) then
				return
			end
		end
		return hit
	end
end
local ir_poly = lib.IntersectRayWithPPoly

function lib.TraceRayPhys(phys, start, dir, dist)
	local chit, cfrac, cnormal, csolid, cside
	local delta = dir * dist
	local endpos = start + delta
	for a, s in ipairs(phys) do
		local t = s.PType
		if t == DREAMSC_AABB then
			local hit, normal, frac = ir_obb(start, delta, vector_origin, ang_zero, s.AA, s.BB)
			if hit and (not chit or v_DistToSqr(hit, start) < v_DistToSqr(chit, start)) then
				chit = hit
				cfrac = frac
				cnormal = normal
				csolid = s
			end
		elseif t == DREAMSC_OBB then
			local hit, normal, frac = ir_obb(start, delta, s.Origin, s.OBB_Ang, s.OBB_Min, s.OBB_Max)
			if hit and (not chit or v_DistToSqr(hit, start) < v_DistToSqr(chit, start)) then
				chit = hit
				cfrac = frac
				cnormal = normal
				csolid = s
			end
		elseif t == DREAMSC_PLANE then
			for b, side in ipairs(s) do
				local norm = side.normal
				local hit = ir_poly(start, dir, dist, side.origin, norm, side.verts)
				if hit and (not chit or v_DistToSqr(hit, start) < v_DistToSqr(chit, start)) then
					chit = hit
					cfrac = hit:Distance(start) / start:Distance(endpos)
					cnormal = norm
					csolid = s
					cside = side
				end
			end
		end
	end

	return chit, cfrac, cnormal, csolid, cside
end

local InterCylAABB = lib.IntersectABCylinderWithAABB
local InterCylOBB = lib.IntersectABCylinderWithOBB
local InterCylPlane = lib.IntersectABCylinderWithPlane
local v_WithinAABox = vmeta.WithinAABox

function lib.IntersectCylPhys(phys, origin, rad, height)
	for a, s in ipairs(phys) do
		local t = s.PType
		if t == DREAMSC_AABB then
			local hit, norm, dist = InterCylAABB(origin, rad, height, s.AA, s.BB)
			if hit then return norm, dist end
		elseif t == DREAMSC_OBB then
			local axes = s.OBB_Axes
			local hit, norm, dist = InterCylOBB(origin, rad, height, s.Origin, s.OBB_Ang, s.OBB_Min, s.OBB_Max, axes[1], axes[2], axes[3])
			if hit then return norm, dist end
		elseif t == DREAMSC_PLANE then
			for b, side in ipairs(s) do
				if not v_WithinAABox(origin, s.PAA, s.PBB) then continue end
				local pnorm = side.normal
				local hit, phit = InterCylPlane(origin, rad, height, side.origin, pnorm, side.verts)
				if hit then return pnorm, phit end
			end
		end
	end
end
---------------------------
function lib.RectToMeshEx(l, w, h, off, ignore, reverse, um, vm)
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
---------------------
local normal = function(c, b, a)
	local cr = v_Cross(b - a, c - a)
	v_Normalize(cr)
	return cr
end
lib.PlaneToNormal = normal

function lib.MinMaxVecs(xmin, xmax, vec)
	return Vector(math.min(xmin.x, vec.x), math.min(xmin.y, vec.y), math.min(xmin.z, vec.z)), Vector(math.max(xmax.x, vec.x), math.max(xmax.y, vec.y), math.max(xmax.z, vec.z))
end

local function is_90_deg(v1, v2, v3)
	local l1 = (v1 - v2):GetNormalized()
	local l2 = (v3 - v2):GetNormalized()
	local dot = l1:Dot(l2)
	if dot > -0.05 and dot < 0.05 then return true end
end
lib.CornerIs90Deg = is_90_deg

local function is_square(verts)
	if table.Count(verts) ~= 4 then return false end
	local v1 = verts[1]
	local v2 = verts[2]
	local v3 = verts[3]
	local v4 = verts[4]
	if not is_90_deg(v1, v2, v3) or not is_90_deg(v2, v3, v4) or not is_90_deg(v3, v4, v1) or not is_90_deg(v4, v1, v2) then return false end
	return true
end

lib.IsSquare = is_square

local function calc_norm(norms, norm)
	local m1, m2, m3 = highest_mag(norm:Unpack())
	if not norms[m1] then norms[m1] = norm return end
	if not norms[m2] then norms[m2] = norm return end
	if not norms[m3] then norms[m3] = norm return end
end

local function determinant(m)
	return
		m[1][1] * (m[2][2] * m[3][3] - m[2][3] * m[3][2]) -
		m[1][2] * (m[2][1] * m[3][3] - m[2][3] * m[3][1]) +
		m[1][3] * (m[2][1] * m[3][2] - m[2][2] * m[3][1])
end

function lib.RotationMatrixFromNormals(n1, n2, n3)
	local n = {}
	calc_norm(n, n1)
	calc_norm(n, n2)
	calc_norm(n, n3)

	local rotmat = {
		{ n.x.x, n.y.x, n.z.x, 0 },
		{ n.x.y, n.y.y, n.z.y, 0 },
		{ n.x.z, n.y.z, n.z.z, 0 },
		{ 0, 0, 0, 1 }
	}

	if determinant(rotmat) < 0 then
		for i = 1, 4 do
			rotmat[i][1] = -rotmat[i][1]
		end
	end
	return Matrix(rotmat)
end

function lib.HalfExtentsFromBox(min, max)
	local size = (max - min) / 2
	return {math_abs(size.x), math_abs(size.y), math_abs(size.z)}
end
------------------------

function lib.PhysOffset(phys_data, offset, angle, displace)
	if phys_data.AA then
		phys_data.AA = phys_data.AA + offset
		phys_data.BB = phys_data.BB + offset
	end
	for k, solid in ipairs(phys_data) do
		solid.Origin = solid.Origin + offset
		solid.AA = solid.AA + offset
		solid.BB = solid.BB + offset
		if solid.PAA and not angle then
			solid.PAA = solid.PAA + offset
			solid.PBB = solid.PBB + offset
		end

		for _, side in ipairs(solid) do
			if angle then
				side.origin = side.origin and LocalToWorld(side.origin, ang_zero, vector_origin, angle)
				side.normal = LocalToWorld(side.normal, ang_zero, vector_origin, angle)
			end

			for a, vert in pairs(side.verts or {}) do
				if angle then
					vert = LocalToWorld(vert, ang_zero, vector_origin, angle)
				end

				if displace and side.normal.z > 0.2 and side.normal.z < 0.7 then
					vert = vert + (vert - side.origin):GetNormalized() * 15
				end
				side.verts[a] = vert + offset
			end

			for a, plane in pairs(side.plane or {}) do
				if angle then
					plane = LocalToWorld(plane, ang_zero, vector_origin, angle)
				end
				side.plane[a] = plane + offset
			end
			side.origin = side.origin and side.origin + offset
		end

		if angle then
			lib.SolidFixBounds(solid)
		end
	end
end

function lib.SolidFixBounds(solid)
	local min, max
	for k, tbl in ipairs(solid) do
		min, max = lib.MinMaxVecs(min or solid.AA + tbl.origin, max or solid.AA + tbl.origin, solid.AA + tbl.origin)
		min, max = lib.MinMaxVecs(min, max, solid.BB + tbl.origin)

		for a, vert in pairs(tbl.verts or {}) do
			min, max = lib.MinMaxVecs(min, max, vert)
		end
	end
	solid.AA = min
	solid.BB = max
	if solid.PAA then
		solid.PAA = min - Vector(128, 128, 128)
		solid.PBB = max + Vector(128, 128, 128)
	end
end

local function find_neighbors(solid, tvert, index)
	local tab = {}
	for _, side in ipairs(solid) do
		for a, vert in pairs(side.verts or {}) do
			if vert:IsEqualTol(tvert, 0.05) then
				tab[_] = index
			end
		end
	end
	return tab
end

function lib.PlaneNeighbors(solid)
	for _, side in ipairs(solid) do
		local neighbors = {}
		for a, vert in pairs(side.verts or {}) do
			local n = find_neighbors(solid, vert, a)
			if n then table.Merge(neighbors, n) end
		end
		side.neighbors = neighbors
	end
end

function lib.GeneratePhysOBB(origin, omin, omax, ang)
	local nsides = {}
	local vm = Matrix()
	vm:SetAngles(ang)
	local axes = {vm:GetForward(), vm:GetRight(), vm:GetUp()}
	nsides.AA = omin
	nsides.BB = omax
	nsides.OBB_Ang = ang
	nsides.OBB_Axes = axes
	nsides.HalfExtents = lib.HalfExtentsFromBox(omin, omax)
	nsides.OBB_Min = omin
	nsides.OBB_Max = omax
	nsides.PType = 2
	nsides.Origin = origin
	return nsides
end

function Dreams.Print(str)
	print("[DREAMS] " .. str)
end

function Dreams.Debug(str)
	print("[:DREAMS:] " .. str)
end