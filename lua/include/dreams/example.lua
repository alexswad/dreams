if not DREAMS then
	Dreams.LoadDreams()
	return
end

DREAMS:AddRoom("test", "models/rooms/rain_hallway.mdl", "data/dreams/rain_hallway.dat", vector_origin)


function DREAMS:Draw()
	Dreams.Meta.Draw(self, 2)
end  