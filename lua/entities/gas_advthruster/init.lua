
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

if not (WireMod == nil) then
	ENT.WireDebugName = "Energy Thruster"
end

local Thruster_Sound 	= Sound( "PhysicsCannister.ThrusterLoop" )

function ENT:Initialize()
	self.BaseClass.Initialize(self)
	
	self.Entity:DrawShadow( false )
	
	local phys = self.Entity:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
	end
	
	--Entity Settings
	self.Effect = "fire"
	self.active = 0
	self.massed = true
	self.force = 0
	self.toggle = 0
	self.togon = false
	self.energy = 0
	self.oxygem = 0
	self.nitrogen = 0
	self.hydrogen = 0
	self.steam = 0
	self.ngas = 0
	self.methane = 0
	self.propane = 0
	self.deuterium = 0
	self.tritium = 0
	
	local max = self.Entity:OBBMaxs()
	local min = self.Entity:OBBMins()
	
	self.ThrustOffset 	= Vector( 0, 0, max.z )
	self.ThrustOffsetR 	= Vector( 0, 0, min.z )
	self.ForceAngle		= self.ThrustOffset:GetNormalized() * -1

	self:SetOffset( self.ThrustOffset )
	self.Entity:StartMotionController()
	self.outputon = 0
	
	self:Switch( false, 0 )

	self.Inputs = Wire_CreateInputs(self.Entity, { "On" })
	self.Outputs = Wire_CreateOutputs(self.Entity, { "On",})
end

function ENT:OnRemove()
	self.BaseClass.OnRemove(self)
	
    if (self.EnableSound) then
		self.Entity:StopSound(Thruster_Sound)
	end
end

function ENT:SetForce( force, mul )
	if (force) then
		self:NetSetForce( force )
	end
	mul = mul or 1
	
	local phys = self.Entity:GetPhysicsObject()
	if (!phys:IsValid()) then
		Msg("Warning: [gas_advthruster] Physics object isn't valid!\n")
		return
	end

	--Get the data in worldspace
	local ThrusterWorldPos = phys:LocalToWorld( self.ThrustOffset )
	local ThrusterWorldForce = phys:LocalToWorldVector( self.ThrustOffset * -1 )

	-- Calculate the velocity
	ThrusterWorldForce = ThrusterWorldForce * force * mul
	self.ForceLinear, self.ForceAngle = phys:CalculateVelocityOffset( ThrusterWorldForce, ThrusterWorldPos );
	self.ForceLinear = phys:WorldToLocalVector( self.ForceLinear )
	
	if ( mul > 0 ) then
		self:SetOffset( self.ThrustOffset )
	else
		self:SetOffset( self.ThrustOffsetR )
	end
end

function ENT:Setup(effect, bidir, sound, massless, toggle, energy, oxygen, nitrogen, hydrogen, steam, ngas, methane, propane, deuterium, tritium)
	self.toggle = toggle
	CAF.GetAddon("Resource Distribution").AddResource(self,"energy",0)
	CAF.GetAddon("Resource Distribution").AddResource(self,"oxygen",0)
	CAF.GetAddon("Resource Distribution").AddResource(self,"nitrogen",0)
	CAF.GetAddon("Resource Distribution").AddResource(self,"hydrogen",0)
	CAF.GetAddon("Resource Distribution").AddResource(self,"steam",0)
	CAF.GetAddon("Resource Distribution").AddResource(self,"Natural Gas",0)
	CAF.GetAddon("Resource Distribution").AddResource(self,"Methane",0)
	CAF.GetAddon("Resource Distribution").AddResource(self,"Propane",0)
	CAF.GetAddon("Resource Distribution").AddResource(self,"Deuterium",0)
	CAF.GetAddon("Resource Distribution").AddResource(self,"Tritium",0)
	
	self.Effect = effect
	self.BiDir = bidir
	self.EnableSound = sound
	
	self:SetEffect( self.Effect ) 
	self.energy = math.abs(energy)
	self.oxygen = math.abs(oxygen)
	self.nitrogen = math.abs(nitrogen)
	self.hydrogen = math.abs(hydrogen)
	self.steam = math.abs(steam)
	self.ngas = math.abs(ngas)
	self.methane = math.abs(methane)
	self.propane = math.abs(propane)
	self.deuterium = math.abs(deuterium)
	self.tritium = math.abs(tritium)
	
	local energyfc = (self.energy*100)*2.3
	local o2fc = (self.oxygen*100)*2.0
	local nitfc = (self.nitrogen*100)*1.6
	local hydrofc = (self.hydrogen*100)*2.7
	local steamfc = (self.steam*100)*1.125
	local ngasfc = (self.ngas*100)*1.35
	local methfc = (self.methane*100)*2.475
	local propfc = (self.propane*100)*2.5
	local deutfc = (self.deuterium*100)*3.375
	local tritfc = (self.tritium*100)*3.15
	
	self.force = energyfc + o2fc + nitfc + hydrofc + steamfc + ngasfc + methfc + propfc + deutfc + tritfc
	self:SetForce(force)
	
	if (not sound) then
		self.Entity:StopSound(Thruster_Sound)
	end
	if (massless) then
		local phys = self:GetPhysicsObject()
		if phys:IsValid() then
			phys:EnableGravity(false)
			phys:EnableDrag(false)
			phys:Wake()
			self.massed = false
		end
	else
		local phys = self:GetPhysicsObject()
		if phys:IsValid() then
			phys:EnableGravity(true)
			phys:EnableDrag(true)
			phys:Wake()
			self.massed = true
		end
	end
end

function ENT:TriggerInput(iname, value)
	if (iname == "On") then
		if (value != 0) then
			self:Switch(true, value)
		else
			self:Switch(false, 0)
		end
	end
end

function ENT:PhysicsSimulate( phys, deltatime )
	if (!self:IsOn()) then return SIM_NOTHING end

	self:SetEffect(self.Effect)
	
	local ForceAngle, ForceLinear = self.ForceAngle, self.ForceLinear
	
	return ForceAngle, ForceLinear, SIM_LOCAL_ACCELERATION
end

function ENT:Switch( on, mul )
	if (!self.Entity:IsValid()) then return false end
	
	local changed = (self:IsOn() ~= on)
	if (on) then
		if (self:CanRun()) then
			self:SetOn( true )
			self:SetOOO(1)
		   if (changed) and (self.EnableSound) then
				self.Entity:StopSound( Thruster_Sound )
				self.Entity:EmitSound( Thruster_Sound )
			end
			
			self:NetSetMul( mul )
			
			self:SetForce( self.force, mul )
		else
			self:SetOn( false )
		end
	else
		self:SetOn(false)
		self:SetOOO(0)
	  if (self.EnableSound) then
			self.Entity:StopSound( Thruster_Sound )
		end
	end
	
	local phys = self.Entity:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
	end
	
	return true
end

function ENT:CanRun()
	local RD = CAF.GetAddon("Resource Distribution")
	local energy = RD.GetResourceAmount(self, "energy")
	local o2 = RD.GetResourceAmount(self, "oxygen")
	local nitrogen = RD.GetResourceAmount(self, "nitrogen")
	local hydrogen = RD.GetResourceAmount(self, "hydrogen")
	local steam = RD.GetResourceAmount(self, "steam")
	local ngas = RD.GetResourceAmount(self, "Natural Gas")
	local methane = RD.GetResourceAmount(self, "Methane")
	local propane = RD.GetResourceAmount(self, "Propane")
	local deuterium = RD.GetResourceAmount(self, "Deuterium")
	local tritium = RD.GetResourceAmount(self, "Tritium")
	
	if (energy >= self.energy and o2 >= self.oxygen and nitrogen >= self.nitrogen and hydrogen >= self.hydrogen and steam >= self.steam) then
		if (ngas >= self.ngas and methane >= self.methane and propane >= self.propane and deuterium >= self.deuterium and tritium >= self.tritium) then
			return true
		else
			return false
		end
	else
		return false
	end
end

function ENT:Think()
	local RD = CAF.GetAddon("Resource Distribution")
	self.BaseClass.Think(self)

	if (self:IsOn() && self:CanRun()) then
		RD.ConsumeResource(self, "energy", self.energy)
		RD.ConsumeResource(self, "oxygen", self.oxygen)
		RD.ConsumeResource(self, "nitrogen", self.nitrogen)
		RD.ConsumeResource(self, "hydrogen", self.hydrogen)
		RD.ConsumeResource(self, "steam", self.steam)
		RD.ConsumeResource(self, "Natural Gas", self.ngas)
		RD.ConsumeResource(self, "Methane", self.methane)
		RD.ConsumeResource(self, "Propane", self.propane)
		RD.ConsumeResource(self, "Deuterium", self.deuterium)
		RD.ConsumeResource(self, "Tritium", self.tritium)
		self.outputon = 1
	else
		self:Switch( false )
		self.outputon = 0
	end
	
	if not (WireAddon == nil) then
		Wire_TriggerOutput(self, "On", self.outputon )
	end
	
	self:ShowOutput()

	self.Entity:NextThink(CurTime() + 1)
	return true
end

function ENT:ShowOutput()
	self.Entity:SetNetworkedInt( 1, self.force or 0 )
	
	self.Entity:SetNetworkedInt( 10,self.energy or 0) -- energy consumption
	self.Entity:SetNetworkedInt( 11,self.oxygen or 0) --o2 consumption
	self.Entity:SetNetworkedInt( 12,self.nitrogen or 0) --N consumption
	self.Entity:SetNetworkedInt( 13,self.hydrogen or 0) --H consumption
	self.Entity:SetNetworkedInt( 14,self.steam or 0) --Steam consumption
	self.Entity:SetNetworkedInt( 15,self.ngas or 0) --Ngas consumption
	self.Entity:SetNetworkedInt( 16,self.methane or 0) --methane consumption
	self.Entity:SetNetworkedInt( 17,self.propane or 0) --propane consumption
	self.Entity:SetNetworkedInt( 18,self.deuterium or 0) --deuterium consumption
	self.Entity:SetNetworkedInt( 19,self.tritium or 0) --tritium consumption
end

function ENT:OnRestore()
	local phys = self.Entity:GetPhysicsObject()
	
	if (phys:IsValid()) then
		phys:Wake()
	end
	
	local max = self.Entity:OBBMaxs()
	local min = self.Entity:OBBMins()
	
	self.ThrustOffset 	= Vector( 0, 0, max.z )
	self.ThrustOffsetR 	= Vector( 0, 0, min.z )
	self.ForceAngle		= self.ThrustOffset:GetNormalized() * -1
	
	self:SetOffset( self.ThrustOffset )
	self.Entity:StartMotionController()
	
	if (self.PrevOutput) then
		self:Switch(true, self.PrevOutput)
	else
		self:Switch(false)
	end
	
  self.BaseClass.OnRestore(self)
end

--Duplicator stuff 
function ENT:PreEntityCopy()
    self.BaseClass.PreEntityCopy(self)
end

function ENT:PostEntityPaste( Player, Ent, CreatedEntities )
  self.BaseClass.PostEntityPaste(self, Player, Ent, CreatedEntities )
end

numpad.Register("gas_advthruster_on", function(pl, ent, mul)
	if not ent:IsValid() then return false end
	ent:Switch(true, mul)
	return true
end)

numpad.Register("gas_advthruster_off", function(pl, ent, mul)
	if not ent:IsValid() then return false end
		ent:Switch(false, mul)
	return true
end)
