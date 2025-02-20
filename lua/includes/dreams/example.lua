if not DREAMS then
	Dreams.LoadDreams()
	return
end

DREAMS:AddRoom("rainhallway", "models/rooms/rain_hallway.mdl", "models/rooms/rain_hallway_dream.phy", vector_origin)


function DREAMS:Draw()
	Dreams.Meta.Draw(self, 3)
end  