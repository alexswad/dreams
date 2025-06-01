local D_VERSION = 1.1
if Dreams and Dreams._VERSION > D_VERSION then print("[DREAMS v" .. D_VERSION .. "] Newer version of Dreams already loaded, skipping") return end

Dreams = Dreams or {}
Dreams._VERSION = D_VERSION

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
		DREAMS.NetReceivers = table.Copy(Dreams.Meta.NetReceivers)
		DREAMS.NetSenders = table.Copy(Dreams.Meta.NetSenders)
		setmetatable(DREAMS, Dreams.Meta)
		include("includes/dreams/" .. v)
		local id = table.insert(Dreams.List, DREAMS)
		DREAMS.ID = id
		Dreams.NameToID[v:StripExtension()] = id
		DREAMS = nil
	end

	if Dreams.HasInit then
		if SERVER then
			for k, v in pairs(ents.FindByClass("dreams_net")) do
				SafeRemoveEntity(v)
			end
		end
		Dreams.Init()
	end
end

local models = {}
local function Init()
	Dreams.HasInit = true
	for k, v in pairs(Dreams.List) do
		for a, room in ipairs(v.ListRooms) do
			if room.mdl and not models[room.mdl] then
				util.PrecacheModel(room.mdl)
				print("DREAMS: Precached " .. room.mdl)
				models[room.mdl] = true
			end

			if not room.props then continue end
			for b, prop in ipairs(room.props) do
				if not prop.model or models[prop.model] then continue end
				util.PrecacheModel(prop.model)
				print("DREAMS: Precached " .. prop.model)
				models[prop.model] = true
			end
		end
		if v.SetupDataTables then v:CheckNetwork() v:SetupDataTables() end
		if v.Init then v:Init() end
	end
	hook.Run("DREAMS_INIT_DONE")
end

Dreams.Init = Init
Dreams.LoadDreams = LoadDreams
LoadDreams()
print("[DREAMS v" .. D_VERSION .. "] Loaded!")
hook.Run("DREAMS_LOADED")