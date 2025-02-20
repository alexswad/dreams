if not DREAMS then
	Dreams.LoadDreams()
	return
end

DREAMS:AddRoom("rainhallway", "models/rooms/rain_hallway.mdl", "models/rooms/rain_hallway_dream.phy", vector_origin)


function DREAMS:Draw()
	Dreams.Meta.Draw(self, 3) // 0 = nothing, 1 = Draw BBoxes, 2 = Draw Face Normals, 3 = Draw Normal + z-BBox
end
DREAMS.StartMove = DREAMS.StartMoveFly