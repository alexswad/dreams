--- Future proofing for compatability
Dreams.Bundle = {}

function Dreams.Bundle.Save(tbl, fname)
	tbl.version = 1.0
	tbl.lights = nil
	local json = util.TableToJSON(tbl)
	if not json then error("Failure creating JSON") end
	file.Write("dreams/" .. fname .. ".dat", util.Compress(json))
	Dreams.Print("[DREAMS] Generated Dream DATFILE @ garrysmod/data/dreams/" .. fname .. ".dat")
end

function Dreams.Bundle.Load(fpath, dir)
	local f = file.Read(fpath, dir or "DATA")
	if not f then ErrorNoHalt("[DREAMS] Unable to read DREAM File " .. fpath .. " " .. (dir or "DATA")) return end
	local json = util.Decompress(f)
	local data = util.JSONToTable(json or "")
	if not data then ErrorNoHalt("[DREAMS] Can't decompress DREAM File " .. fpath .. " " .. (dir or "DATA")) return end
	return data
end