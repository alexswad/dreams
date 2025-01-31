AddCSLuaFile()
AddCSLuaFile("dreams/init.lua")
AddCSLuaFile("dreams/cl_init.lua")

if SERVER then
	include("dreams/init.lua")
else
	include("dreams/cl_init.lua")
end