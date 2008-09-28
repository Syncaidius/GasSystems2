local ENABLE = false

function AddDir(dir) 	
	for k,v in pairs(file.Find("../"..dir.."/*")) do
		resource.AddFile(dir.."/"..v)
	end
end  

if (ENABLE) then
	AddDir("models/syncaidius")
	AddDir("models/pegasus")
	AddDir("materials/syncaidius")
end