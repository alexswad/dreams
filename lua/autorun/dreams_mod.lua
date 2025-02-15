Dreams = Dreams or {}

AddCSLuaFile("dreams/hooks.lua")
AddCSLuaFile("dreams/meta.lua")
AddCSLuaFile("dreams/vmf_converter.lua")
include("dreams/hooks.lua")
include("dreams/meta.lua")
if CLIENT then include("dreams/vmf_converter.lua") end

function Dreams.LoadDreams()
	local files = file.Find("include/dreams/*.lua", "LUA")
	Dreams.List = {}
	Dreams.NameToID = {}
	for k, v in pairs(files) do
		AddCSLuaFile("include/dreams/" .. v)

		DREAMS = {}
		DREAMS.Phys = {}
		DREAMS.Name = "dreams_" .. v:StripExtension()
		DREAMS.Rooms = {}
		DREAMS.ListRooms = {}
		setmetatable(DREAMS, Dreams.Meta)
		include("include/dreams/" .. v)
		local id = table.insert(Dreams.List, DREAMS)
		DREAMS.ID = id
		Dreams.NameToID["dreams_" .. v:StripExtension()] = id
		DREAMS = nil
	end
end
Dreams.LoadDreams() 