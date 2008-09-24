--Gas Systems Admin
--By By Syncaidius

function GasAdmin.SetupTable()
	if(!sql.TableExists("gassysadmin")) then
		sql.Query("CREATE TABLE IF NOT EXISTS gassysadmin(maxgens INTEGER NOT NULL, maxstors INTEGER NOT NULL, maxthrust INTEGER NOT NULL, gasexp INTEGER NOT NULL);")
		sql.Query("INSERT INTO gassysadmin(maxgens, maxstors, maxthrust, gasexp) VALUES(24,24,20,1)")
		Msg("GASSYSTEMS: SETTINGS TABLE CREATED!\n")
	else
		Msg("GASSYSTEMS: SETTINGS TABLE LOADED!\n")
	end
	return sql.QueryRow("SELECT * FROM gassysadmin LIMIT 999")
end
GasAdmin.Config = GasAdmin.SetupTable()

function GasAdmin.ApplySettings(ply, cmd, args)
	if(!ply:IsAdmin()) then
		return
	end
	
	local maxgens = ply:GetInfo("sbox_maxgas_generator")
	local maxstors = ply:GetInfo("sbox_maxgas_storage")
	local maxthrust = ply:GetInfo("sbox_maxgas_thrusters")
	local gasexp = (ply:GetInfo("GASSYS_TankExplosions") or "1")
	
	sql.Query("UPDATE gassysadmin SET maxgens = "..maxgens..", maxstors = "..maxstors..", maxthrust = "..maxthrust..", gasexp = "..gasexp)
	
	GasAdmin.Config = sql.QueryRow("SELECT * FROM spropprotection LIMIT 999")
	
	game.ConsoleCommand( "sbox_maxgas_generator "..maxgens )
	game.ConsoleCommand( "sbox_maxgas_storage "..maxstors )
	game.ConsoleCommand( "sbox_maxgas_maxthrusters "..maxthrust )
	game.ConsoleCommand( "GASSYS_TankExplosions "..gasexp )
	
	for k,v in pairs(player.GetAll()) do
		v:ChatPrint("GASSYSTEMS: "..ply:GetName().." has changed one or more settings.\n")
	end
	Msg("GASSYSTEMS: "..ply:GetName().." has changed one or more settings.\n")
	Msg("GASSYSTEMS: SETTINGS SAVED SUCCESSFULLY!\n")
end
concommand.Add("GASSYS_applysettings", GasAdmin.ApplySettings)