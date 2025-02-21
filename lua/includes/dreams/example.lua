if not DREAMS then
	Dreams.LoadDreams()
	return
end

DREAMS:AddRoom("rainhallway", "models/rooms/rain_hallway.mdl", "models/rooms/rain_hallway_dream.phy", vector_origin)

DREAMS.StartMove = DREAMS.StartMoveFly // Helper function
// There are the move hooks you can replace
// DREAMS:StartMove(ply, mv, cmd)
// DREAMS:DoMove(ply, mv)
// DREAMS:FinishMove(ply, mv)
DREAMS.MoveSpeed = 20
DREAMS.ShiftSpeed = 40
DREAMS.JumpPower = 400
DREAMS.Gravity = 600

if SERVER then
	function DREAMS:ThinkSelf() // Called before any player think, allows for updating ent positions & dream variables
	end

	function DREAMS:EntityTakeDamage(ply, attacker, inflictor, dmg)
		if Dreams.Meta.EntityTakeDamage(self, ply, attacker, inflictor, dmg) then return true end
	end
else
	function DREAMS:Draw(ply)
		Dreams.Meta.Draw(self, ply, 3) // 0 = nothing, 1 = Draw BBoxes, 2 = Draw Face Normals, 3 = Draw Normal + z-BBox
	end

	function DREAMS:DrawHUD(ply, w, h)
		Dreams.Meta.DrawHUD(self, ply, w, h) // you MUST call this or nothing including the escape menu will be able to render, use the hook below to disable default panels
	end

	function DREAMS:HUDShouldDraw(ply, string) // see https://wiki.facepunch.com/gmod/GM:HUDShouldDraw
	end

	function DREAMS:CalcView(ply, view) // view is an editable table, see https://wiki.facepunch.com/gmod/Structures/CamData
		Dreams.Meta.CalcView(self, ply, view) // Will automatically setup camera to player's 64 height
	end

	function DREAMS:SetupFog(ply) // return true to setup fog
	end
end

function DREAMS:Think(ply) // Called for every player serverside and localplayer clientside
end

function DREAMS:Start(ply) // Setups the player's positioning in the world. Player is actually in a world position so that they're properly networked, then positioned clientside
	Dreams.Meta.Start(self, ply) // You would normally want to call this unless you know what your doing
end

function DREAMS:End(ply)
	Dreams.Meta.End(self, ply) // ATM does nothing and not required
end

function DREAMS:SwitchWeapon(ply, old, new) // return true to prevent, default will only allow player to switch to nothing
	return Dreams.Meta.SwitchWeapon(self, ply, old, new)
end