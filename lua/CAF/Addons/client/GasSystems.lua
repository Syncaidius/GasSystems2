local RD = {}

local status = false

--The Class
/**
	The Constructor for this Custom Addon Class
*/
function RD.__Construct()
	status = true
	return true , "Not Implementation yet"
end

/**
	The Destructor for this Custom Addon Class
*/
function RD.__Destruct()
	return false , "Can't disable"
end

/**
	Get the required Addons for this Addon Class
*/
function RD.GetRequiredAddons()
	return {"Resource Distribution"}
end

/**
	Get the Boolean Status from this Addon Class
*/
function RD.GetStatus()
	return status
end

/**
	Get the Version of this Custom Addon Class
*/
function RD.GetVersion()
	return 1.3, "Release"
end

/**
	Get any custom options this Custom Addon Class might have
*/
function RD.GetExtraOptions()
	return {}
end

/**
	Gets a menu from this Custom Addon Class
*/
function RD.GetMenu(menutype, menuname)//Name is nil for main menu, String for others
	local data = {}
	return data
end

/**
	Get the Custom String Status from this Addon Class
*/
function RD.GetCustomStatus()
	return "Implemented"
end

CAF.RegisterAddon("Gas Systems 2", RD, "2")


