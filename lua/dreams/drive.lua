
local intersectrayplane = util.IntersectRayWithPlane
local abs = math.abs

local normal = function(c, b, a)
	return ((b - a):Cross(c - a)):GetNormalized()
end

local function check(a, b, c, p)
	local cr1 = (b - a):Cross(c - a)
	local cr2 = (b - a):Cross(p - a)
	return cr1:Dot(cr2) >= 0
end

local woff = Vector(0, 0, 32)
drive.Register("drive_dreams", {
	CalcView = function(self, view)
		view.angles = self.Player:EyeAngles()
		view.origin = self.Player:GetPos() + Vector(0, 0, 64)
	end,

	StartMove = function(self, mv, cmd)
		local ply = self.Player
		ply:SetMoveType(MOVETYPE_NOCLIP)

		mv:SetVelocity(ply:GetAbsVelocity())
		mv:SetOrigin(ply:GetNetworkOrigin())
	
		local ang = mv:GetMoveAngles()
		local pos = Vector(0, 0, 0)
		local speed = 20
		if cmd:KeyDown(IN_SPEED) then
			speed = 40
		end
	
		if cmd:KeyDown(IN_MOVERIGHT) then
			pos:Add(ang:Right())
		end
	
		if cmd:KeyDown(IN_MOVELEFT) then
			pos:Add(-ang:Right())
		end
	
		if cmd:KeyDown(IN_FORWARD) then
			pos:Add(Angle(0, ang.y, 0):Forward())
		end
	
		if cmd:KeyDown(IN_BACK) then
			pos:Add(-Angle(0, ang.y, 0):Forward())
		end
	
		pos:Normalize()
		local vel = mv:GetVelocity() * 0.9 + pos * speed

		if vel:IsEqualTol(Vector(0, 0, 0), 3) then
			vel = Vector(0, 0, 0)
		end

		if vel.z < 0 then vel:Set(Vector(vel.x, vel.y, math.min(vel.z, -1) / 0.9)) end
		vel:Add(Vector(0, 0, -600 * FrameTime()))
		mv:SetVelocity(vel)

	end,

	Move = function(self, mv)
		local prop = ents.FindByClass("dreams_*")[1]
		if not prop then
			drive.PlayerStopDriving(self.Player)
			return
		end
		local vel, org = mv:GetVelocity(), mv:GetOrigin()
	
		local rnorm, rorg = prop:WorldToLocalAngles(vel:Angle()):Forward(), prop:RWTL(org)
		local rvel = rnorm * vel:Length()

		local onfloor
		for _, s in ipairs(prop.Phys or {}) do
			local norm = normal(s.plane[1], s.plane[2], s.plane[3])
			local worg = rorg + woff
			local rvel_len = rvel:Length()
			local hit = intersectrayplane(worg + norm * rvel_len, -norm, s.plane[1], norm)
			local fhit = norm:IsEqualTol(Vector(0, 0, 1), 0.3)
			 and intersectrayplane(rorg + Vector(0, 0, 1) * rvel_len * 2, Vector(0, 0, -1), s.plane[1], norm)
			local wd, fd = hit and (worg - hit + norm):Dot(norm) or 0, fhit and (rorg - fhit + norm):Dot(norm) or 0
			if not fhit and hit and (hit:DistToSqr(worg) < 16 ^ 2 or wd < 0 and wd > -2) or fhit and (fhit:DistToSqr(rorg) < 1 or fd < 0 and fd > -4 * abs(rvel.z / 10)) then
				local a, b, c, d = unpack(s.vertices)
				local e = fhit or hit
				if check(a, b, c, e) and check(b, c, a, e) and check(c, d, a, e) and check(d, a, b, e) then
					if fhit then
						onfloor = true
						rorg = Vector(rorg.x, rorg.y, fhit.z)
						rvel = Vector(rvel.x, rvel.y, 0)
					else
						rorg = hit - Vector(0, 0, 32) + norm * 16
					end
				end
			end
		end


		org = prop:RLTW(rorg)
		vel = prop:LocalToWorldAngles(rvel:Angle()):Forward() * rvel:Length()

		if onfloor and mv:KeyPressed(IN_JUMP) then
			vel = Vector(vel.x, vel.y, 400)
			mv:SetVelocity(vel)
		end

		mv:SetOrigin(org + vel * FrameTime())
		mv:SetVelocity(vel)
	end,

	FinishMove =  function( self, mv )
		self.Entity:SetNetworkOrigin( mv:GetOrigin() )
		self.Entity:SetAbsVelocity( mv:GetVelocity() )
		//self.Entity:SetAngles( mv:GetMoveAngles() )

		if SERVER and IsValid(self.Entity:GetPhysicsObject()) then
			local phys = self.Entity:GetPhysicsObject()
			phys:EnableMotion(true)
			phys:SetPos(mv:GetOrigin())
			phys:Wake()
			phys:EnableMotion(false)
		end
	end,
},"drive_base")