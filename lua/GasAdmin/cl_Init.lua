--Gas Systems Admin
--By Syncaidius

GasAdmin.AdminCPanel = nil

function GasAdmin.AdminPanel(Panel)
	Panel:ClearControls()
	
	if(!LocalPlayer():IsAdmin()) then
		Panel:AddControl("Label", {Text = "You are not an admin"})
		return
	end
	
	if(!GasAdmin.AdminCPanel) then
		GasAdmin.AdminCPanel = Panel
	end
	
	Panel:AddControl("Label", {Text = "Admin Panel - Gas Admin Panel by Syncaidius"})
	
	Panel:AddControl("Slider", {Label = "Max Gas Generators", Command = "sbox_maxgas_generator", Type = "Integer", Min = "0", Max = "999"})
	Panel:AddControl("Slider", {Label = "Max Gas Storages", Command = "sbox_maxgas_storage", Type = "Integer", Min = "0", Max = "999"})
	Panel:AddControl("Slider", {Label = "Max Powered Thrusters", Command = "sbox_maxgas_thrusters", Type = "Integer", Min = "0", Max = "999"})
	Panel:AddControl("CheckBox", {Label = "Gas Tank Explosions", Command = "GASSYS_TankExplosions"})
	
	Panel:AddControl("Button", {Text = "Apply Settings", Command = "GASSYS_applysettings"})
end

function GasAdmin.PopulateToolMenu()
	spawnmenu.AddToolMenuOption("Utilities", "Gas Systems Admin", "Admin", "Admin", "", "", GasAdmin.AdminPanel)
end
hook.Add("PopulateToolMenu", "GasAdmin.PopulateToolMenu", GasAdmin.PopulateToolMenu)
