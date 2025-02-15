if CLIENT then
	hook.Add("RenderScene", "Dreams_RenderDreams", function(origin, angles, fov)
		local ply = LocalPlayer()
		if not ply:IsDreaming() then return end
		local dream = ply:GetDream()
		local view = {
			origin = origin,
			angles = angles,
			fov = fov,
		}
		if not dream:SetupFog(s, ply) then render.FogMode(MATERIAL_FOG_NONE) end
		dream:CalcView(ply, view)
		cam.Start3D(view.origin, view.angles, view.fov, 0, 0, ScrW(), ScrH())
			dream:Draw(ply)
		cam.End3D()

		cam.Start2D()
			dream:DrawHUD(ScrW(), ScrH())
		cam.End2D()
		return true
	end)

	hook.Add("HUDShouldDraw", "Dreams_ShouldDrawHud", function(str)
		local ply = LocalPlayer()
		if not ply.IsDreaming or not ply:IsDreaming() then return end
		local dream = ply:GetDream()
		return dream:HUDShouldDraw(ply, str)
	end)
end

if SERVER then
	local ran = {}
	hook.Add("Think", "Dreams_Think", function()
		for k, v in ipairs(player.GetAll()) do
			if not v:IsDreaming() then continue end
			local dream = v:GetDream()
			if not ran[dream.ID] then
				dream:ThinkSelf()
				ran[dream.ID] = true
			end
			dream:Think(v)
		end
		table.Empty(ran)
	end)
else
	local last_dream = 0
	hook.Add("Think", "Dreams_Think", function()
		local ply = LocalPlayer()
		if not ply.IsDreaming then return end
		if not ply:IsDreaming() then
			if last_dream ~= 0 and Dreams.List[last_dream] then
				pcall(Dreams.List[last_dream].End, Dreams.List[last_dream], ply)
				last_dream = 0
			end
			return
		else
			local dream = ply:GetDream()
			if last_dream ~= dream.ID then
				if last_dream ~= 0 then
					pcall(Dreams.List[last_dream].End, Dreams.List[last_dream], ply)
				end
				last_dream = dream.ID
				dream:Start(ply)
			end
			dream:Think(ply)
		end
	end)
end

hook.Add("SetupMove", "Dreams_setupmove", function(ply, cmd, mv)
	if not ply:IsDreaming() then return end
	local dream = ply:GetDream()
	dream:StartMove(ply, cmd, mv)
	return true
end)

hook.Add("Move", "Dreams_domove", function(ply, mv)
	if not ply:IsDreaming() then return end
	local dream = ply:GetDream()
	dream:DoMove(ply, mv)
	return true
end)

hook.Add("FinishMove", "Dreams_finishmove", function(ply, mv)
	if not ply:IsDreaming() then return end
	local dream = ply:GetDream()
	dream:FinishMove(ply, mv)
	return true
end)