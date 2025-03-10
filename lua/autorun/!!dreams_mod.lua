Dreams = Dreams or {}

AddCSLuaFile("dreams/hooks.lua")
AddCSLuaFile("dreams/meta.lua")
AddCSLuaFile("dreams/lib.lua")
AddCSLuaFile("dreams/vmf_converter.lua")
include("dreams/lib.lua")
include("dreams/hooks.lua")
include("dreams/meta.lua")
if CLIENT then include("dreams/vmf_converter.lua") end


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
		if v.SetupDataTables then v:CheckNetwork() v:SetupDataTables() end
		if v.Init then v:Init() end
	end
end

Dreams.Init = Init
Dreams.LoadDreams = LoadDreams
LoadDreams()