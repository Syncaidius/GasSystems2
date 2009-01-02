AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

if not (WireAddon == nil) then
  ENT.WireDebugName = "S Processed Gas Tank"
end

function ENT:Initialize()
	self.Entity:SetModel( "models/syncaidius/sprocstore.mdl" )
  self.BaseClass.Initialize(self)

  local phys = self.Entity:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
		phys:SetMass(200)
	end
	
	self.damaged = 0
	self:SetMaxHealth(350)
  self:SetHealth(self:GetMaxHealth())

	CAF.GetAddon("Resource Distribution").AddResource(self,"Methane",5000)
	CAF.GetAddon("Resource Distribution").AddResource(self,"Propane",5000)
	CAF.GetAddon("Resource Distribution").AddResource(self,"Deuterium",5500)
	CAF.GetAddon("Resource Distribution").AddResource(self,"Tritium",5500)
	
	if not (WireAddon == nil) then
		self.Outputs = Wire_CreateOutputs(self.Entity, {"Methane","Propane","Deuterium","Tritium","Max Methane","Max Propane","Max Deuterium","Max Tritium"}) 
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
	self.Entity:SetColor(255,255,255, 255)
	self:SetHealth(self:GetMaxHealth())
	self.damaged = 0
end

function ENT:Destruct()
	local RD = CAF.GetAddon("Resource Distribution")
	
	if server_settings.Bool("GASSYS_TankExplosions") then
		local res1 = RD.GetResourceAmount(self,"Methane")
		local res2 = RD.GetResourceAmount(self,"Propane")
		local res3 = RD.GetResourceAmount(self,"Deuterium")
		local res4 = RD.GetResourceAmount(self,"Tritium")
		
		local resource = (res1+res2+res3+res4)/2 --divide by 2 to stop it being a tiny tank/uber explosion.

		if (resource==0) then 
			resource=1 
		end
		if (resource>10000) then
			resource=10000
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
		
		util.ScreenShake(self.Entity:GetPos(),15,200,2,radius)
		
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
    if not (WireAddon == nil) then
		local RD = CAF.GetAddon("Resource Distribution")
    Wire_TriggerOutput(self.Entity, "Methane", RD.GetResourceAmount( self, "Methane" ))
    Wire_TriggerOutput(self.Entity, "Propane", RD.GetResourceAmount( self, "Propane" ))
		Wire_TriggerOutput(self.Entity, "Deuterium",RD.GetResourceAmount(self,"Deuterium"))
		Wire_TriggerOutput(self.Entity, "Tritium",RD.GetResourceAmount(self,"Tritium"))
		Wire_TriggerOutput(self.Entity, "Max Methane", RD.GetUnitCapacity( self, "Methane" ))
		Wire_TriggerOutput(self.Entity, "Max Propane", RD.GetUnitCapacity( self, "Propane" ))
		Wire_TriggerOutput(self.Entity, "Max Deuterium", RD.GetUnitCapacity( self, "Deuterium" ))
		Wire_TriggerOutput(self.Entity, "Max Tritium", RD.GetUnitCapacity( self, "Tritium" ))
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
		local RD = CAF.GetAddon("Resource Distribution")
		local propane = RD.GetResourceAmount( self, "Propane" )
		local methane = RD.GetResourceAmount(self,"Methane")
		local deut = RD.GetResourceAmount(self,"Deuterium")
		local trit = RD.GetResourceAmount(self,"Tritium")
		caller:ChatPrint("There is "..tostring(propane).." Propane stored in this resource network.")
		caller:ChatPrint("There is "..tostring(methane).." Propane stored in this resource network.")
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
