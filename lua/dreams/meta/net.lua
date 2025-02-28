local Dreams = Dreams
local DREAMS = Dreams.Meta

if SERVER then
	function DREAMS:CheckNetwork()
		if not self.SetupDataTables or IsValid(self.NetEntity) or self.NetEntity == false then return end
		self.NetEntity = ents.Create("dreams_net")
		self.NetEntity:SetDTInt(0, self.ID)
		if not IsValid(self.NetEntity) then self.NetEntity = false return end
		for type, tab in pairs(self.DTVars) do
			for k, v in pairs(tab) do
				self:SetDTVar(type, k, v)
			end
		end
	end

	function DREAMS:SetDTVector(k, vec)
		self.DTVars["Vector"] = self.DTVars["Vector"] or {}
		self.DTVars["Vector"][k] = vec
		self.NetEntity:SetDTVector(k, vec)
	end

	function DREAMS:SetDTAngle(k, ang)
		self.DTVars["Angle"] = self.DTVars["Angle"] or {}
		self.DTVars["Angle"][k] = ang
		self.NetEntity:SetDTAngle(k, ang)
	end

	function DREAMS:SetDTBool(k, bool)
		self.DTVars["Bool"] = self.DTVars["Bool"] or {}
		self.DTVars["Bool"][k] = bool
		self.NetEntity:SetDTBool(k, bool)
	end

	function DREAMS:SetDTEntity(k, ent)
		self.DTVars["Entity"] = self.DTVars["Entity"] or {}
		self.DTVars["Entity"][k] = ent
		self.NetEntity:SetDTEntity(k, ent)
	end

	function DREAMS:SetDTInt(k, int)
		assert(k ~= 0, "Attempted use of reserved DTInt slot 0")
		self.DTVars["Int"] = self.DTVars["Int"] or {}
		self.DTVars["Int"][k] = int
		self.NetEntity:SetDTInt(k, int)
	end

	function DREAMS:SetDTString(k, str)
		self.DTVars["String"] = self.DTVars["String"] or {}
		self.DTVars["String"][k] = str
		self.NetEntity:SetDTString(k, str)
	end

	function DREAMS:SetDTFloat(k, float)
		self.DTVars["Float"] = self.DTVars["Float"] or {}
		self.DTVars["Float"][k] = float
		self.NetEntity:SetDTFloat(k, float)
	end

	function DREAMS:SetDTVar(type, k, var)
		self.NetEntity["SetDT" .. type](self.NetEntity, k, var)
	end
	//
	function DREAMS:GetDTVector(k, vec)
		self.DTVars["Vector"] = self.DTVars["Vector"] or {}
		return self.DTVars["Vector"][k] or vec
	end

	function DREAMS:GetDTAngle(k, ang)
		self.DTVars["Angle"] = self.DTVars["Angle"] or {}
		return self.DTVars["Angle"][k] or ang
	end

	function DREAMS:GetDTBool(k, bool)
		self.DTVars["Bool"] = self.DTVars["Bool"] or {}
		return self.DTVars["Bool"][k] or bool
	end

	function DREAMS:GetDTEntity(k, ent)
		self.DTVars["Entity"] = self.DTVars["Entity"] or {}
		return self.DTVars["Entity"][k] or ent or NULL
	end

	function DREAMS:GetDTInt(k, int)
		assert(k ~= 0, "Attempted use of reserved DTInt slot 0")
		self.DTVars["Int"] = self.DTVars["Int"] or {}
		return self.DTVars["Int"][k] or int or 0
	end

	function DREAMS:GetDTString(k, str)
		self.DTVars["String"] = self.DTVars["String"] or {}
		return self.DTVars["String"][k] or str or ""
	end

	function DREAMS:GetDTFloat(k, float)
		self.DTVars["Float"] = self.DTVars["Float"] or {}
		return self.DTVars["Float"][k] or float or 0
	end
else
	function DREAMS:CheckNetwork()
		if not self.SetupDataTables or IsValid(self.NetEntity) then return end
		for k, v in pairs(ents.FindByClass("dreams_net")) do
			if v:GetDTInt(0) == self.ID then
				self.NetEntity = v
				break
			end
		end
	end

	function DREAMS:SetDTVector(k, vec)
		self.NetEntity:SetDTVector(k, vec)
	end

	function DREAMS:SetDTAngle(k, ang)
		self.NetEntity:SetDTAngle(k, ang)
	end

	function DREAMS:SetDTBool(k, bool)
		self.NetEntity:SetDTBool(k, bool)
	end

	function DREAMS:SetDTEntity(k, ent)
		self.NetEntity:SetDTEntity(k, ent)
	end

	function DREAMS:SetDTInt(k, int)
		assert(k ~= 0, "Attempted use of reserved DTInt slot 0")
		self.NetEntity:SetDTInt(k, int)
	end

	function DREAMS:SetDTString(k, str)
		self.NetEntity:SetDTString(k, str)
	end

	function DREAMS:SetDTFloat(k, float)
		self.NetEntity:SetDTFloat(k, float)
	end
	//
	function DREAMS:GetDTVector(k, vec)
		return self.NetEntity:GetDTVector(k, vec)
	end

	function DREAMS:GetDTAngle(k, ang)
		return self.NetEntity:GetDTAngle(k, ang)
	end

	function DREAMS:GetDTBool(k, bool)
		return self.NetEntity:GetDTBool(k, bool)
	end

	function DREAMS:GetDTEntity(k, ent)
		return self.NetEntity:GetDTEntity(k, ent)
	end

	function DREAMS:GetDTInt(k, int)
		assert(k ~= 0, "Attempted use of reserved DTInt slot 0")
		return self.NetEntity:GetDTInt(k, int)
	end

	function DREAMS:GetDTString(k, str)
		return self.NetEntity:GetDTString(k, str)
	end

	function DREAMS:GetDTFloat(k, float)
		return self.NetEntity:GetDTFloat(k, float)
	end
end