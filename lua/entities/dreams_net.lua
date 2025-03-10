AddCSLuaFile()

ENT.Base = "base_anim"
ENT.Author = "eskil"
ENT.RenderGroup = RENDERGROUP_OTHER

function ENT:UpdateTransmitState()
	return TRANSMIT_ALWAYS
end

if CLIENT then
	function ENT:Initialize()
		self:DrawShadow(false)
	end
end