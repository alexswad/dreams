if not DREAMS then
	Dreams.LoadDreams()
	return
end

DREAMS:AddRoom("rainhallway", "models/rooms/rain_hallway.mdl", "models/rooms/rain_hallway_dream.phy", vector_origin)

DREAMS.StartMove = DREAMS.StartMoveFly
DREAMS.MoveSpeed = 20
DREAMS.ShiftSpeed = 40
DREAMS.JumpPower = 400
DREAMS.Gravity = 600

if SERVER then
	function DREAMS:ThinkSelf()
	end

	function DREAMS:EntityTakeDamage(ply, attacker, inflictor, dmg)
		if Dreams.Meta.EntityTakeDamage(self, ply, attacker, inflictor, dmg) then return true end
	end
else
	function DREAMS:Draw(ply)
		Dreams.Meta.Draw(self, ply, 3) // 0 = nothing, 1 = Draw BBoxes, 2 = Draw Face Normals, 3 = Draw Normal + z-BBox
	end

	function DREAMS:DrawHUD(ply, w, h)
		Dreams.Meta.DrawHUD(self, ply, w, h)
	end

	function DREAMS:HUDShouldDraw(ply, string)
	end

	function DREAMS:CalcView(ply, view)
		Dreams.Meta.CalcView(self, ply, view)
	end

	function DREAMS:SetupFog(ply)
	end
end

function DREAMS:Think(ply)
end

function DREAMS:Start(ply)
	Dreams.Meta.Start(self, ply)
end

function DREAMS:End(ply)
	Dreams.Meta.End(self, ply)
end

function DREAMS:SwitchWeapon(ply, old, new)
	return Dreams.Meta.SwitchWeapon(self, ply, old, new)
end