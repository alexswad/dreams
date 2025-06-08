local Dreams = Dreams
local DREAMS = Dreams.Meta

DREAMS.NetReceivers = {}
DREAMS.NetSenders = {}

local types = {
	["Vector"] = true,
	["Angle"] = true,
	["Bool"] = true,
	["Entity"] = true,
	["Int"] = true,
	["String"] = true,
	["Float"] = true,
}

function DREAMS:NetSafe()
	return IsValid(self.NetEntity)
end

function DREAMS:NetworkVar(type, slot, name)
	assert(types[type or 0], "Invalid network type")
	assert(slot and name, "Missing arguements")
	if type == "Vector" then
		self["Get" .. name] = function(d, b) if not d:NetSafe() then return b end return d:GetDTVector(slot, b) end
		self["Set" .. name] = function(d, v) if not d:NetSafe() then return end d:SetDTVector(slot, v) end
	elseif type == "Angle" then
		self["Get" .. name] = function(d, b) if not d:NetSafe() then return b end return d:GetDTAngle(slot, b) end
		self["Set" .. name] = function(d, v) if not d:NetSafe() then return end d:SetDTAngle(slot, v) end
	elseif type == "Bool" then
		self["Get" .. name] = function(d, b) if not d:NetSafe() then return b end return d:GetDTBool(slot, b) end
		self["Set" .. name] = function(d, v) if not d:NetSafe() then return end d:SetDTBool(slot, v) end
	elseif type == "Entity" then
		self["Get" .. name] = function(d, b) if not d:NetSafe() then return b end return d:GetDTEntity(slot, b) end
		self["Set" .. name] = function(d, v) if not d:NetSafe() then return end d:SetDTEntity(slot, v) end
	elseif type == "Int" then
		self["Get" .. name] = function(d, b) if not d:NetSafe() then return b end return d:GetDTInt(slot, b) end
		self["Set" .. name] = function(d, v) if not d:NetSafe() then return end d:SetDTInt(slot, v) end
	elseif type == "String" then
		self["Get" .. name] = function(d, b) if not d:NetSafe() then return b end return d:GetDTString(slot, b) end
		self["Set" .. name] = function(d, v) if not d:NetSafe() then return end d:SetDTString(slot, v) end
	elseif type == "Float" then
		self["Get" .. name] = function(d, b) if not d:NetSafe() then return b end return d:GetDTFloat(slot, b) end
		self["Set" .. name] = function(d, v) if not d:NetSafe() then return end d:SetDTFloat(slot, v) end
	end
end

if SERVER then
	function DREAMS:CheckNetwork()
		if not self.SetupDataTables or IsValid(self.NetEntity) or self.NetEntity == false then return end
		self.NetEntity = ents.Create("dreams_net")
		self.NetEntity:SetDTInt(31, self.ID)
		if not IsValid(self.NetEntity) then self.NetEntity = false return end
		for type, tab in pairs(self.DTVars) do
			for k, v in pairs(tab) do
				self:SetDTVar(type, k, v, true)
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
		assert(k ~= 31, "Attempted use of reserved DTInt slot 31")
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

	function DREAMS:SetDTVar(type, k, var, skip)
		self.NetEntity["SetDT" .. type](self.NetEntity, k, var)
		if not skip then self.DTVars[type] = self.DTVars[type] or {}; self.DTVars[type][k] = var end
	end
	--
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
		assert(k ~= 31, "Attempted use of reserved DTInt slot 31")
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
		for k, v in ipairs(ents.FindByClass("dreams_net")) do
			if v:GetDTInt(31) == self.ID then
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
		assert(k ~= 31, "Attempted use of reserved DTInt slot 31")
		self.NetEntity:SetDTInt(k, int)
	end

	function DREAMS:SetDTString(k, str)
		self.NetEntity:SetDTString(k, str)
	end

	function DREAMS:SetDTFloat(k, float)
		self.NetEntity:SetDTFloat(k, float)
	end
	--
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
		assert(k ~= 31, "Attempted use of reserved DTInt slot 31")
		return self.NetEntity:GetDTInt(k, int)
	end

	function DREAMS:GetDTString(k, str)
		return self.NetEntity:GetDTString(k, str)
	end

	function DREAMS:GetDTFloat(k, float)
		return self.NetEntity:GetDTFloat(k, float)
	end
end

---- Commands ----

function DREAMS:AddNetReceiver(string, func)
	self.NetReceivers[string] = func
end

function DREAMS:AddNetSender(string, func)
	self.NetSenders[string] = func or function() end
end

if SERVER then
	util.AddNetworkString("dreams_netcommands")
	function DREAMS:SendCommand(str, ply, data)
		assert(self.NetSenders[str], "Net Command " .. str .. " not defined")
		net.Start("dreams_netcommands")
		net.WriteUInt(self.ID, 32)
		net.WriteString(str)
		self.NetSenders[str](self, data)
		net.Send(ply)
	end

	function DREAMS:SendEndCommand(ply)
		net.Start("dreams_netcommands")
		net.WriteUInt(self.ID, 32)
		net.WriteString("end")
		net.WriteEntity(ply)
		net.Broadcast()
	end

	net.Receive("dreams_netcommands", function(len, ply)
		local dream = ply:GetDream()
		if not dream then return end
		local cmd = net.ReadString()
		if not dream.NetReceivers[cmd or ""] then return end
		dream.NetReceivers[cmd](dream, ply)
	end)
else
	function DREAMS:SendCommand(str, data)
		assert(self.NetSenders[str], "Net Command " .. str .. " not defined")
		net.Start("dreams_netcommands")
		net.WriteString(str)
		self.NetSenders[str](self, data)
		net.SendToServer()
	end

	net.Receive("dreams_netcommands", function(len, ply)
		local id = net.ReadUInt(32)
		local dream = Dreams.List[id]
		local cmd = net.ReadString()
		if cmd == "end" then
			local ent = net.ReadEntity()
			ent:SetDream(0)
			return
		end
		if not dream then return end
		assert(dream.NetReceivers[cmd or ""], "Net Receiver " .. (cmd or "<bad data>") .. " not defined")
		dream.NetReceivers[cmd](dream, LocalPlayer())
	end)
end