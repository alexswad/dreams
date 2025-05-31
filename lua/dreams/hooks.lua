function Dreams.AddHooks()
	if CLIENT then
		hook.Add("RenderScene", "!!dreams_RenderDreams", function(origin, angles, fov)
			local ply = LocalPlayer()
			if not ply.IsDreaming or not ply:IsDreaming() then return end
			ply.DreamRoom = ply.DreamRoom or Dreams.EMPTY_ROOM
			local dream = ply:GetDream()
			return dream:RenderScene(ply)
		end)

		hook.Add("HUDShouldDraw", "!!dreams_ShouldDrawHud", function(str)
			local ply = LocalPlayer()
			if not ply.IsDreaming or not ply:IsDreaming() then return end
			local dream = ply:GetDream()
			return dream:HUDShouldDraw(ply, str)
		end)

		hook.Add("EntityEmitSound", "!!!!dreams_EmitSound", function(tbl)
			local ply = LocalPlayer()
			if not ply.IsDreaming or not ply:IsDreaming() then return end
			local dream = ply:GetDream()
			return dream:EntityEmitSound(tbl)
		end)
	end

	if SERVER then
		local ran = {}
		hook.Add("Think", "!!!dreams_Think", function()
			for k, v in ipairs(player.GetAll()) do
				if not v:IsDreaming() or not v:Alive() then continue end
				local dream = v:GetDream()
				if not ran[dream.ID] then
					dream:CheckNetwork()
					dream:ThinkSelf()
					ran[dream.ID] = true
				end
				dream:Think(v)
			end
			table.Empty(ran)
		end)

		local ondeath = function(ply)
			if not ply:IsDreaming() then return end
			local rag = ply:GetRagdollEntity()
			if IsValid(rag) then rag:Remove() end
			timer.Simple(0.1, function()
				ply:SetDream(0)
			end)
		end

		hook.Add("PlayerDeath", "!!dreams_Death", ondeath)
		hook.Add("PlayerSilentDeath", "!!dreams_Death", ondeath)
	else
		local last_dream = 0
		hook.Add("Think", "!!!dreams_Think", function()
			local ply = LocalPlayer()
			if not ply.IsDreaming then return end
			local dream = ply:GetDream()
			if last_dream ~= (dream and dream.ID or 0) then
				if Dreams.List[last_dream] then Dreams.List[last_dream]:End(ply) end
				if dream then
					ply.DreamRoom = Dreams.EMPTY_ROOM
					dream:Start(ply)
				else
					for k, v in ipairs(player.GetAll()) do
						v:SetPos(v:GetNetworkOrigin())
					end
				end
				last_dream = dream and dream.ID or 0
			end

			if dream then
				dream:CheckNetwork()
				dream:Think(ply)
			end
		end)
	end

	hook.Add("SetupMove", "!!!dreams_setupmove", function(ply, cmd, mv)
		if not ply:IsDreaming() then return end
		local dream = ply:GetDream()
		return dream:StartMove(ply, cmd, mv)
	end)

	hook.Add("Move", "!!!dreams_domove", function(ply, mv)
		if not ply:IsDreaming() then return end
		local dream = ply:GetDream()
		return dream:DoMove(ply, mv)
	end)

	hook.Add("FinishMove", "!!!dreams_finishmove", function(ply, mv)
		if not ply:IsDreaming() then return end
		local dream = ply:GetDream()
		return dream:FinishMove(ply, mv)
	end)

	hook.Add("PlayerSwitchWeapon", "!!!dreams_SwitchWeapon", function(ply, old, new)
		if not ply:IsDreaming() then return end
		local dream = ply:GetDream()
		return dream:SwitchWeapon(ply, old, new)
	end)

	hook.Add("KeyRelease", "!!!dreams_KeyRelease", function(ply, key)
		if not ply:IsDreaming() then return end
		local dream = ply:GetDream()
		if dream.KeyRelease then dream:KeyRelease(ply, key) end
	end)

	hook.Add("KeyPress", "!!!dreams_KeyPress", function(ply, key)
		if not ply:IsDreaming() then return end
		local dream = ply:GetDream()
		if dream.KeyPress then dream:KeyPress(ply, key) end
	end)

	hook.Add("ShouldCollide", "!!!dreams_collisions", function(ent1, ent2)
		if ent1:IsPlayer() and ent1:IsDreaming() or ent2:IsPlayer() and ent2:IsDreaming() then return false end
	end)

	hook.Add("PlayerFootstep", "!!!dreams_footstep", function(ply)
		if not ply.IsDreaming then return end
		if ply:IsDreaming() or CLIENT and LocalPlayer():IsDreaming() then return true end
	end)

	hook.Add("PrePlayerDraw", "!!!dreams_DrawPlayer", function(ply, flags)
		if ply ~= LocalPlayer() and ply:GetDreamID() ~= LocalPlayer():GetDreamID() and not ply.Dreams_FDraw then
			if not LocalPlayer():IsDreaming() then
				ply:SetNetworkOrigin(ply:GetPos() + Vector(0, 0, -2500)) -- hide real players from people who are not dreaming
				ply:DrawShadow(false)
			end
			return true
		end
		ply.Dreams_FDraw = false
	end)

	hook.Add("EntityTakeDamage", "!!!!dreams_TakeDamage", function(ent, dmg)
		if not IsValid(ent) or not ent:IsPlayer() or not ent:IsDreaming() then return end
		local dream = ent:GetDream()
		return dream:EntityTakeDamage(ent, dmg:GetAttacker(), dmg:GetInflictor(), dmg)
	end)

	hook.Add("InitPostEntity", "!!!dreams_init", function()
		Dreams.Init()
	end)

	if SERVER then
		local spawn = function(ply)
			if ply:IsDreaming() then return false end
		end

		hook.Add("PlayerSpawnEffect", "!!!dreams_SpawnBlock", spawn)
		hook.Add("PlayerSpawnObject", "!!!dreams_SpawnBlock", spawn)
		hook.Add("PlayerSpawnNPC", "!!!dreams_SpawnBlock", spawn)
		hook.Add("PlayerSpawnProp", "!!!dreams_SpawnBlock", spawn)
		hook.Add("PlayerSpawnRagdoll", "!!!dreams_SpawnBlock", spawn)
		hook.Add("PlayerSpawnSENT", "!!!dreams_SpawnBlock", spawn)
		hook.Add("PlayerSpawnVehicle", "!!!dreams_SpawnBlock", spawn)
	end
end
Dreams.AddHooks()

function Dreams.RemoveHooks()
	hook.Remove("RenderScene", "!!dreams_RenderDreams")
	hook.Remove("HUDShouldDraw", "!!dreams_ShouldDrawHud")
	hook.Remove("EntityEmitSound", "!!!!dreams_EmitSound")
	hook.Remove("InitPostEntity", "!!!dreams_init")
	hook.Remove("EntityTakeDamage", "!!!!dreams_TakeDamage")
	hook.Remove("PrePlayerDraw", "!!!dreams_DrawPlayer")
	hook.Remove("PlayerFootstep", "!!!dreams_footstep")
	hook.Remove("ShouldCollide", "!!!dreams_collisions")
	hook.Remove("KeyPress", "!!!dreams_KeyPress")
	hook.Remove("KeyRelease", "!!!dreams_KeyRelease")
	hook.Remove("PlayerSwitchWeapon", "!!!dreams_SwitchWeapon")
	hook.Remove("FinishMove", "!!!dreams_finishmove")
	hook.Remove("Move", "!!!dreams_domove")
	hook.Remove("SetupMove", "!!!dreams_setupmove")
	hook.Remove("Think", "!!!dreams_Think")

	hook.Remove("PlayerSpawnEffect", "!!!dreams_SpawnBlock")
	hook.Remove("PlayerSpawnObject", "!!!dreams_SpawnBlock")
	hook.Remove("PlayerSpawnNPC", "!!!dreams_SpawnBlock")
	hook.Remove("PlayerSpawnProp", "!!!dreams_SpawnBlock")
	hook.Remove("PlayerSpawnRagdoll", "!!!dreams_SpawnBlock")
	hook.Remove("PlayerSpawnSENT", "!!!dreams_SpawnBlock")
	hook.Remove("PlayerSpawnVehicle", "!!!dreams_SpawnBlock")

	hook.Remove("PlayerDeath", "!!dreams_Death")
	hook.Remove("PlayerSilentDeath", "!!dreams_Death")

	hook.Run("DREAMS_CLEANUP")
end