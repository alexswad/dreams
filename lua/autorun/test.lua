local normal = function(c, b, a)
	return ((b - a):Cross(c - a)):GetNormalized()
end

if SERVER then
	concommand.Add("start", function(ply)
		local model = ents.Create("dreams_phys")
		model:SetModel("models/scp106/rooms/" .. GetGlobalString("dreams_phys") .. ".mdl")
		//model:PhysicsInit(SOLID_VPHYSICS)
		//model:SetPos(ply:GetPos())
		model:SetRealPos(ply:GetPos())
		model:SetPos(ply:GetPos())
		model:Spawn()
		model:EnableCustomCollisions()
		
		-- local sky = ents.Create("prop_dynamic")
		-- -- sky:SetModel("models/rooms/props/rain_hallway_29.mdl")
		-- -- sky:AddEFlags(EFL_IN_SKYBOX)
		-- -- sky:SetPos(ply:GetPos())
		-- -- //sky:SetAngles(Angle(0, 0, 180))
		-- -- sky:Spawn()
		-- -- sky:SetModelScale(1)

		for k,v in pairs (player.GetAll()) do
			v:AddEFlags(EFL_IN_SKYBOX)
			v:AddEFlags(EFL_FORCE_CHECK_TRANSMIT)
		end
	end)

	timer.Create("test", 0, 0, function()
		for k,v in pairs (player.GetAll()) do
			v:AddEFlags(EFL_IN_SKYBOX)
			v:AddEFlags(EFL_FORCE_CHECK_TRANSMIT)
		end
	end)
end

hook.Add("KeyPress", "test", function(ply, state)
	if SERVER and state == IN_ZOOM then
		if ply:IsDrivingEntity() then
			drive.PlayerStopDriving(ply)
		else
			drive.PlayerStartDriving(ply, ply, "drive_dreams")
		end
	end
end)
