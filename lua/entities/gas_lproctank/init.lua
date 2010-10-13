AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

function ENT:Initialize()
	self.Entity:SetModel( "models/syncaidius/lprocstore.mdl" )
	self.BaseClass.Initialize(self)

	local phys = self.Entity:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
		phys:SetMass(320)
	end
	
	self.damaged = 0
	self:SetMaxHealth(980)
	self:SetHealth(self:GetMaxHealth())
	
	local RD = CAF.GetAddon("Resource Distribution")
	RD.AddResource(self,"Methane",24000)
	RD.AddResource(self,"Propane",24000)
	RD.AddResource(self,"Deuterium",25000)
	RD.AddResource(self,"Tritium",25000)
	
	if WireLib then
		self.WireDebugName = self.PrintName
		self.Outputs = WireLib.CreateOutputs(self, {"Methane","Propane","Deuterium","Tritium","Max Methane","Max Propane","Max Deuterium","Max Tritium"}) 
	end
end

function ENT:OnRemove()
    self.BaseClass.OnRemove(self)
end

function ENT:Damage()
	if (self.damaged == 0) then
		self.damaged = 1
	end
end

function ENT:Repair()
	self:SetHealth(self:GetMaxHealth())
	self.damaged = 0
end

function ENT:Destruct()
	if server_settings.Bool("GASSYS_TankExplosions") then
		local RD = CAF.GetAddon("Resource Distribution")
		local res1 = RD.GetResourceAmount(self,"Methane")
		local res2 = RD.GetResourceAmount(self,"Propane")
		local res3 = RD.GetResourceAmount(self,"Deuterium")
		local res4 = RD.GetResourceAmount(self,"Tritium")
		
		local resource = (res1+res2+res3+res4)/2 --divide by 2 to stop it being a tiny tank/uber explosion.

		if (resource==0) then 
			resource=1 
		end
		if (resource>49000) then
			resource=49000
		end
		
		local magnit=math.floor(resource/50)
		local radius=math.floor(resource/60)
		local expl=ents.Create("env_explosion")
		
		expl:SetPos(self.Entity:GetPos())
		expl:SetName("Gas Tank")
		expl:SetParent(self.Entity)
		expl:SetOwner(self.Entity:GetOwner())
		expl:SetKeyValue("iMagnitude", magnit)
		expl:SetKeyValue("iRadiusOverride", radius)
		expl:SetKeyValue("spawnflags", 64)
		expl:Spawn()
		expl:Activate()
		expl:Fire("explode", "", 0)
		expl:Fire("kill","",0)
		self.Exploded = true
		
		local effectdata = EffectData()
			effectdata:SetOrigin( self.Entity:GetPos() )
			effectdata:SetMagnitude(3)
			effectdata:SetScale(0.6)
		util.Effect( "tank_explode", effectdata )	 -- self made effect
		
		util.PrecacheSound("ambient/explosions/explode_8.wav")
		self.Entity:EmitSound("ambient/explosions/explode_8.wav", 100, 100)
		
		local Ambient = ents.Create("ambient_generic")
		Ambient:SetPos(self.Entity:GetPos())
		Ambient:SetKeyValue("message", "ambient/explosions/explode_8.wav")
		Ambient:SetKeyValue("health", 10)
		Ambient:SetKeyValue("preset", 0)
		Ambient:SetKeyValue("radius", radius*10)
		Ambient:Spawn()
		Ambient:Activate()
		Ambient:Fire("PlaySound", "", 0)
		Ambient:Fire("kill", "", 4)
		
		self.shakeeffect = ents.Create("env_shake") -- Shake from the explosion
		self.shakeeffect:SetKeyValue("amplitude", 16)
		self.shakeeffect:SetKeyValue("spawnflags", 4 + 8 + 16)
		self.shakeeffect:SetKeyValue("frequency", 200.0)
		self.shakeeffect:SetKeyValue("duration", 2)
		self.shakeeffect:SetKeyValue("radius", 2000)
		self.shakeeffect:SetPos(self.Entity:GetPos())
		self.shakeeffect:Fire("StartShake","",0)
		self.shakeeffect:Fire("Kill","",4)
		
		self.splasheffect = ents.Create("env_splash")
		self.splasheffect:SetKeyValue("scale", 500)
		self.splasheffect:SetKeyValue("spawnflags", 2)
		
		self.light = ents.Create("light")
		self.light:SetKeyValue("_light", 255 + 255 + 255)
		self.light:SetKeyValue("style", 0)
		
		local physExplo = ents.Create( "env_physexplosion" )
		physExplo:SetOwner( self.Owner )
		physExplo:SetPos( self.Entity:GetPos() )
		physExplo:SetKeyValue( "Magnitude", magnit )	-- Power of the Physicsexplosion
		physExplo:SetKeyValue( "radius", radius )	-- Radius of the explosion
		physExplo:SetKeyValue( "spawnflags", 2 + 16 )
		physExplo:Spawn()
		physExplo:Fire( "Explode", "", 0 )
		physExplo:Fire( "Kill", "", 0 )
		
		self.Entity:Remove()
	else
		CAF.GetAddon("Life Support").Destruct( self.Entity )
	end
end

function ENT:Output()
	return 1
end

function ENT:UpdateWireOutputs()
    if WireLib then
		WireLib.TriggerOutput(self.Entity, "Methane", self:GetResourceAmount( "Methane" ))
		WireLib.TriggerOutput(self.Entity, "Propane", self:GetResourceAmount( "Propane" ))
		WireLib.TriggerOutput(self.Entity, "Deuterium", self:GetResourceAmount( "Deuterium"))
		WireLib.TriggerOutput(self.Entity, "Tritium", self:GetResourceAmount( "Tritium"))
		WireLib.TriggerOutput(self.Entity, "Max Methane", self:GetNetworkCapacity( "Methane" ))
		WireLib.TriggerOutput(self.Entity, "Max Propane", self:GetNetworkCapacity( "Propane" ))
		WireLib.TriggerOutput(self.Entity, "Max Deuterium", self:GetNetworkCapacity( "Deuterium" ))
		WireLib.TriggerOutput(self.Entity, "Max Tritium", self:GetNetworkCapacity( "Tritium" ))
	end
end

function ENT:Think()
  self.BaseClass.Think(self)
    
  self:UpdateWireOutputs()
    
	self.Entity:NextThink( CurTime() + 1 )
	return true
end

function ENT:AcceptInput(name,activator,caller)
	if name == "Use" and caller:IsPlayer() and caller:KeyDownLast(IN_USE) == false then
		local propane = self:GetResourceAmount("Propane" )
		local methane = self:GetResourceAmount("Methane")
		local deut = self:GetResourceAmount("Deuterium")
		local trit = self:GetResourceAmount("Tritium")
		caller:ChatPrint("There is "..tostring(propane).." Propane stored in this resource network.")
		caller:ChatPrint("There is "..tostring(methane).." Methane stored in this resource network.")
		caller:ChatPrint("There is "..tostring(deut).." Deuterium stored in this resource network.")
		caller:ChatPrint("There is "..tostring(trit).." Tritium stored in this resource network.")
	end
end

function ENT:PreEntityCopy()
  self.BaseClass.PreEntityCopy(self)
end

function ENT:PostEntityPaste( Player, Ent, CreatedEntities )
  self.BaseClass.PostEntityPaste(self, Player, Ent, CreatedEntities )
end
