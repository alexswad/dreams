if CLIENT then
	hook.Add("RenderScene", "!!dreams_RenderDreams", function(origin, angles, fov)
		local ply = LocalPlayer()
		if not ply:IsDreaming() then return end
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
		if not ply:IsDreaming() then return end
		local dream = ply:GetDream()
		return dream:EntityEmitSound(tbl)
	end)
end

if SERVER then
	local ran = {}
	hook.Add("Think", "!!dreams_Think", function()
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
		timer.Simple(0.1, function()
			ply:SetDream(0)
		end)
	end

	hook.Add("PlayerDeath", "!!dreams_Death", ondeath)
	hook.Add("PlayerSilentDeath", "!!Dreams_Death", ondeath)
else
	local last_dream = 0
	hook.Add("Think", "!!!dreams_Think", function()
		local ply = LocalPlayer()
		if not ply.IsDreaming then return end
		local dream = ply:GetDream()
		if last_dream ~= (dream and dream.ID or 0) then
			if Dreams.List[last_dream] then Dreams.List[last_dream]:End(ply) end
			if dream then
				dream:Start(ply)
			else
				for k, v in pairs(player.GetAll()) do
					v:SetRenderOrigin(nil)
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

hook.Add("PrePlayerDraw", "!!!dreams_DrawPlayer", function(ply, flags)
	if not ply:IsDreaming() then return end
	local dream = ply:GetDream()
	return dream:PrePlayerDraw(ply, flags)
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