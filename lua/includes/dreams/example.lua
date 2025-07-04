if not DREAMS then
	Dreams.LoadDreams()
	return
end


-- These are the move hooks you can replace and/or call
-- DREAMS:StartMove(ply, mv, cmd)
-- DREAMS:DoMove(ply, mv)
-- DREAMS:FinishMove(ply, mv)
DREAMS.MoveSpeed = 40
DREAMS.ShiftSpeed = 60
DREAMS.JumpPower = 400
DREAMS.Gravity = 600
DREAMS.Debug = 1

DREAMS:AddRoom("rainhallway", nil, "data_static/dreams/test/rain_hallway.dat", Vector(10, 10, -100))

if SERVER then
	function DREAMS:ThinkSelf() -- Called before any player think, allows for updating ent positions & dream variables
	end

	function DREAMS:EntityTakeDamage(ply, attacker, inflictor, dmg)
		if Dreams.Meta.EntityTakeDamage(self, ply, attacker, inflictor, dmg) then return true end -- Will prevent anything but players in dreams from hurting dreaming players
	end
else
	function DREAMS:Draw(ply, rt)
		-- Will draw room models and players for you, draw other clientside models or entities after
		Dreams.Meta.Draw(self, ply, rt, 1)
	end

	function DREAMS:DrawHUD(ply, w, h)
		Dreams.Meta.DrawHUD(self, ply, w, h, true) -- you MUST call this or nothing including the escape menu will be able to render, use the hook below to disable default panels
	end

	function DREAMS:HUDShouldDraw(ply, string) -- see https:--wiki.facepunch.com/gmod/GM:HUDShouldDraw
	end

	function DREAMS:CalcView(ply, view) -- view is an editable table, see https:--wiki.facepunch.com/gmod/Structures/CamData
		Dreams.Meta.CalcView(self, ply, view) -- Will automatically setup camera to player's 64 height
	end

	function DREAMS:SetupFog(ply) -- return true to setup fog
	end

	function DREAMS:EntityEmitSound(tbl)
		return Dreams.Meta.EntityEmitSound(self, tbl) -- blocks all sounds from other entities, isnt perfect but thats sauce engine
	end
end

function DREAMS:Think(ply) -- Called for every player serverside and localplayer clientside
end

function DREAMS:Start(ply) -- Player is actually in a world position so that they're properly networked, then positioned clientside
	Dreams.Meta.Start(self, ply) -- Setups the player's positioning in the world. You would normally want to call this unless you know what your doing
	--if SERVER then ply:SetDreamPos(self.Rooms["rainhallway"].marks["test"].pos) end -- Spawn the player at our info_teleport_destination
end

function DREAMS:End(ply)
	Dreams.Meta.End(self, ply) -- Resets the player positioning to Spawn since they're probably in the skybox
end

function DREAMS:SwitchWeapon(ply, old, new) -- return true to prevent, default will only allow player to switch to nothing
	return Dreams.Meta.SwitchWeapon(self, ply, old, new)
end

function DREAMS:KeyPress(ply, key)
	if CLIENT and IsFirstTimePredicted() and key == IN_USE then self.Debug = ((self.Debug or 0) + 1) % 5 end
end

-- If defined, will automatically create a DREAMS.NetEntity for easy networking
--[[
function DREAMS:SetupDataTables()
	self:NetworkVar("Int", 1, "MyVar")
	self:SetMyVar(200)
end
--]]
