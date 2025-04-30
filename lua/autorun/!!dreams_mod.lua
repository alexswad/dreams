Dreams = Dreams or {}

AddCSLuaFile("dreams/hooks.lua")
AddCSLuaFile("dreams/meta.lua")
AddCSLuaFile("dreams/lib/lib.lua")
AddCSLuaFile("dreams/lib/bundle.lua")
AddCSLuaFile("dreams/lib/vmf_convert.lua")

include("dreams/lib/lib.lua")
include("dreams/lib/bundle.lua")
include("dreams/lib/vmf_convert.lua")
include("dreams/hooks.lua")
include("dreams/meta.lua")

local function LoadDreams()
	local files = file.Find("includes/dreams/*.lua", "LUA")
	Dreams.List = {}
	Dreams.NameToID = {}
	for k, v in pairs(files) do
		AddCSLuaFile("includes/dreams/" .. v)

		DREAMS = {}
		DREAMS.Phys = {}
		DREAMS.Name = v:StripExtension()
		DREAMS.Rooms = {}
		DREAMS.ListRooms = {}
		DREAMS.DTVars = {}
		DREAMS.NetReceivers = {}
		DREAMS.NetSenders = {}
		setmetatable(DREAMS, Dreams.Meta)
		include("includes/dreams/" .. v)
		local id = table.insert(Dreams.List, DREAMS)
		DREAMS.ID = id
		Dreams.NameToID[v:StripExtension()] = id
		DREAMS = nil
	end

	if Dreams.HasInit then
		Dreams.Init()
	end
end

local function Init()
	Dreams.HasInit = true
	for k, v in pairs(Dreams.List) do
		for a, room in ipairs(v.ListRooms) do
			if not room.Props then continue end
			for b, prop in ipairs(room.Props) do
				util.PrecacheModel(prop.model)
				print("DREAMS: Precached " .. prop.model)
			end
		end
		if v.SetupDataTables then v:CheckNetwork() v:SetupDataTables() end
		if v.Init then v:Init() end
	end
end

Dreams.Init = Init
Dreams.LoadDreams = LoadDreams
LoadDreams()