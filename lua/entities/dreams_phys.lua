AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "dreams_phys"
ENT.Author = "eskil"
ENT.RenderGroup = RENDERGROUP_BOTH

local normal = function(c, b, a)
	return ((b - a):Cross(c - a)):GetNormalized()
end

function ENT:Initialize()
	self:AddEFlags(EFL_IN_SKYBOX)
	self:AddEFlags(EFL_FORCE_CHECK_TRANSMIT)
	self:UpdatePhys()
end

function ENT:UpdatePhys()
	self.Phys = util.JSONToTable(file.Read("dreams/" .. GetGlobalString("dreams_phys") .. ".dat", "DATA"))
	
end

function ENT:SetupDataTables()
	self:NetworkVar("Float", 0, "RV1")
	self:NetworkVar("Float", 1, "RV2")
	self:NetworkVar("Float", 2, "RV3")
end

function ENT:GetRealPos()
	return Vector(self:GetRV1(), self:GetRV2(), self:GetRV3())
end

function ENT:SetRealPos(vec)
	self:SetRV1(math.Round(vec.x, 3))
	self:SetRV2(math.Round(vec.y, 3))
	self:SetRV3(math.Round(vec.z, 3))
end

function ENT:UpdateTransmitState()
	return TRANSMIT_ALWAYS
end

function ENT:Draw()
	self:SetRenderOrigin(self:GetRealPos())
	self:DrawModel()

	if not self.Phys then return end
	for _, s in pairs(self.Phys) do
		local middle = (s.vertices[1] + s.vertices[3] + s.vertices[2] + s.vertices[4]) / 4
		local norm = normal(s.plane[1], s.plane[2], s.plane[3])

		local rot, rot_end, rot_three = self:RLTW(middle), self:RLTW(middle + norm * 25),  self:RLTW(middle + norm * 50)

		render.DrawLine(rot, rot_end, Color(255, 0, 0), false)
		render.DrawLine(rot_end, rot_three, Color(0, 255, 0), false)
	end
end

hook.Add("PostDrawOpaqueRenderables", "draw_dream", function()
	if not LocalPlayer():IsDrivingEntity() then return end
	for k, v in pairs(ents.FindByClass("prop*")) do
		if v:GetModel():find("29") then render.SuppressEngineLighting(true) v:SetPos(LocalPlayer():GetPos() + Vector(0, 0, 64)) v:DrawModel() render.SuppressEngineLighting(false) v:SetNoDraw(true) continue end
	end
	
	for k, v in pairs(ents.FindByClass("dreams*")) do
		render.DepthRange(0.1, 0)
		render.SetLightingMode(1)

		v:SetRenderOrigin(v:GetRealPos())
		v:DrawModel()

		render.SetLightingMode(0)
		cam.IgnoreZ(false)
	end

	-- for k, v in pairs(ents.FindByClass("prop*")) do
	-- 	render.DepthRange(0.1, 0)
	-- 	render.SetLightingMode(1)

	-- 	v:DrawModel()

	-- 	render.SetLightingMode(0)
	-- 	cam.IgnoreZ(false)
	-- end

	for k, v in pairs(player.GetAll()) do
		render.DepthRange(0.1, 0)
		render.SetLightingMode(1)

		v:DrawModel()

		render.SetLightingMode(0)
		cam.IgnoreZ(false)
	end
end)

local ang_zero = Angle(0, 0, 0)
function ENT:RLTW(pos)
	return LocalToWorld(pos, ang_zero, self:GetRealPos(), self:GetAngles())
end

function ENT:RWTL(pos)
	return WorldToLocal(pos, ang_zero, self:GetRealPos(), self:GetAngles())
end