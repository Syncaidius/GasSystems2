function AddDir(dir) 	
	local list = file.FindDir("../"..dir.."/*")
	for _, fdir in pairs(list) do  		
		if fdir != ".svn" then 
			AddDir(fdir)
		end
	end
	for k,v in pairs(file.Find("../"..dir.."/*")) do
		resource.AddFile(dir.."/"..v)
	end
end  

AddDir("models/syncaidius")
AddDir("materials/syncaidius")  