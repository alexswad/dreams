if CLIENT then
	hook.Add("RenderScene", "!!Dreams_RenderDreams", function(origin, angles, fov)
		local ply = LocalPlayer()
		if not ply:IsDreaming() then return end
		local dream = ply:GetDream()
		local view = {
			origin = origin,
			angles = angles,
			fov = fov,
		}
		if not dream:SetupFog(ply) then render.FogMode(MATERIAL_FOG_NONE) end
		dream:CalcView(ply, view)
		cam.Start3D(view.origin, view.angles, view.fov, 0, 0, ScrW(), ScrH())
			dream:Draw(ply)
		cam.End3D()

		cam.Start2D()
			dream:DrawHUD(ply, ScrW(), ScrH())
		cam.End2D()
		return true
	end)

	hook.Add("HUDShouldDraw", "!!Dreams_ShouldDrawHud", function(str)
		local ply = LocalPlayer()
		if not ply.IsDreaming or not ply:IsDreaming() then return end
		local dream = ply:GetDream()
		return dream:HUDShouldDraw(ply, str)
	end)
end

if SERVER then
	local ran = {}
	hook.Add("Think", "!!Dreams_Think", function()
		for k, v in ipairs(player.GetAll()) do
			if not v:IsDreaming() or not v:Alive() then continue end
			local dream = v:GetDream()
			if not ran[dream.ID] then
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

	hook.Add("PlayerDeath", "!!Dreams_Death", ondeath)
	hook.Add("PlayerSilentDeath", "!!Dreams_Death", ondeath)
else
	local last_dream = 0
	hook.Add("Think", "Dreams_Think", function()
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
				end
			end
			last_dream = dream and dream.ID or 0
		end

		if dream then
			dream:Think(ply)
		end
	end)
end

hook.Add("SetupMove", "Dreams_setupmove", function(ply, cmd, mv)
	if not ply:IsDreaming() then return end
	local dream = ply:GetDream()
	return dream:StartMove(ply, cmd, mv)
end)

hook.Add("Move", "Dreams_domove", function(ply, mv)
	if not ply:IsDreaming() then return end
	local dream = ply:GetDream()
	return dream:DoMove(ply, mv)
end)

hook.Add("FinishMove", "Dreams_finishmove", function(ply, mv)
	if not ply:IsDreaming() then return end
	local dream = ply:GetDream()
	return dream:FinishMove(ply, mv)
end)

hook.Add("PlayerSwitchWeapon", "Dreams_SwitchWeapon", function(ply, old, new)
	if not ply:IsDreaming() then return end
	local dream = ply:GetDream()
	return dream:SwitchWeapon(ply, old, new)
end)

hook.Add("PrePlayerDraw", "Dreams_DrawPlayer", function(ply, flags)
	if not ply:IsDreaming() then return end
	local dream = ply:GetDream()
	return dream:PrePlayerDraw(ply, flags)
end)