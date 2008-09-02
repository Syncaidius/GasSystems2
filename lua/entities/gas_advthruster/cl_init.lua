
include('shared.lua')

CreateConVar( "cl_drawthrusterseffects", "1" )

local matHeatWave		= Material( "sprites/heatwave" )
local matFire			= Material( "effects/fire_cloud1" )
local matPlasma			= Material( "effects/strider_muzzle" )
local matColor			= Material( "effects/bloodstream" )


--Thrusters only really need to be twopass when they're active.. something to think about..
ENT.RenderGroup 		= RENDERGROUP_BOTH

local OOO = {}
OOO[0] = "Off"
OOO[1] = "On"
OOO[2] = "Overdrive"

function ENT:DoNormalDraw( bDontDrawModel )
	local mode = self:GetNetworkedInt("overlaymode")
	if RD_OverLay_Mode and mode != 0 then -- Don't enable it if disabled by default!
		if RD_OverLay_Mode.GetInt then
			local nr = math.Round(RD_OverLay_Mode:GetInt())
			if nr >= 0 and nr <= 2 then
				mode = nr;
			end
		end
	end
	local rd_overlay_dist = 512
	if RD_OverLay_Distance then
		if RD_OverLay_Distance.GetInt then
			local nr = RD_OverLay_Distance:GetInt()
			if nr >= 256 then
				rd_overlay_dist = nr
			end
		end
	end
	if ( LocalPlayer():GetEyeTrace().Entity == self.Entity and EyePos():Distance( self.Entity:GetPos() ) < rd_overlay_dist and mode != 0) then
		local trace = LocalPlayer():GetEyeTrace()
		if ( !bDontDrawModel ) then self:DrawModel() end
		local nettable = CAF.GetAddon("Resource Distribution").GetEntityTable(self)
		if table.Count(nettable) <= 0 then return end
		local playername = self:GetPlayerName()
		if playername == "" then
			playername = "World"
		end
		-- 0 = no overlay!
		-- 1 = default overlaytext
		-- 2 = new overlaytext
		
		if not mode or mode != 2 then
			local OverlayText = ""
				OverlayText = OverlayText ..self.PrintName.."\n"
			if nettable.network == 0 then
				OverlayText = OverlayText .. "Not connected to a network\n"
			else
				OverlayText = OverlayText .. "Network " .. nettable.network .."\n"
			end
			OverlayText = OverlayText .. "Owner: " .. playername .."\n"
			local runmode = "UnKnown"
			if self:GetOOO() >= 0 and self:GetOOO() <= 2 then
				runmode = OOO[self:GetOOO()]
			end
			local consumption = self:GetNetworkedInt( 1 )
			local entresource = self:GetNetworkedString( 2 )
			local force = self:GetNetworkedInt( 3 )
			local RD = CAF.GetAddon("Resource Distribution")
			OverlayText = OverlayText .. "Mode: " .. runmode .."\n"
			OverlayText = OverlayText ..RD.GetProperResourceName(entresource)..": "..RD.GetResourceAmount(self, entresource).."/"..RD.GetNetworkCapacity(self, entresource).."\n"
			OverlayText = OverlayText .."Consumption Rate: "..string.format("%g",consumption).."\n"
			OverlayText = OverlayText .."Force: " ..string.format("%g",force)
			AddWorldTip( self.Entity:EntIndex(), OverlayText, 0.5, self.Entity:GetPos(), self.Entity  )
		else
			local rot = Vector(0,0,90)
			local TempY = 0
			
			--local pos = self.Entity:GetPos() + (self.Entity:GetForward() ) + (self.Entity:GetUp() * 40 ) + (self.Entity:GetRight())
			local pos = self.Entity:GetPos() + (self.Entity:GetUp() * (self:BoundingRadius( ) + 10))
			local angle =  (LocalPlayer():GetPos() - trace.HitPos):Angle()
			angle.r = angle.r  + 90
			angle.y = angle.y + 90
			angle.p = 0
			
			local textStartPos = -375
			
			cam.Start3D2D(pos,angle,0.03)
			
					surface.SetDrawColor(0,0,0,125)
					surface.DrawRect( textStartPos, 0, 1250, 500 )
					
					surface.SetDrawColor(155,155,155,255)
					surface.DrawRect( textStartPos, 0, -5, 500 )
					surface.DrawRect( textStartPos, 0, 1250, -5 )
					surface.DrawRect( textStartPos, 500, 1250, -5 )
					surface.DrawRect( textStartPos+1250, 0, 5, 500 )
					
					TempY = TempY + 10
					surface.SetFont("ConflictText")
					surface.SetTextColor(255,255,255,255)
					surface.SetTextPos(textStartPos+15,TempY)
					surface.DrawText(self.PrintName)
					TempY = TempY + 70
					
					surface.SetFont("Flavour")
					surface.SetTextColor(155,155,255,255)
					surface.SetTextPos(textStartPos+15,TempY)
					surface.DrawText("Owner: "..playername)
					TempY = TempY + 70
	
					surface.SetFont("Flavour")
					surface.SetTextColor(155,155,255,255)
					surface.SetTextPos(textStartPos+15,TempY)
					if nettable.network == 0 then
						surface.DrawText("Not connected to a network")
					else
						surface.DrawText("Network " .. nettable.network)
					end
					TempY = TempY + 70
					
					if HasOOO then
						local runmode = "UnKnown"
						if self:GetOOO() >= 0 and self:GetOOO() <= 2 then
							runmode = OOO[self:GetOOO()]
						end
						surface.SetFont("Flavour")
						surface.SetTextColor(155,155,255,255)
						surface.SetTextPos(textStartPos+15,TempY)
						surface.DrawText("Mode: "..runmode)
						TempY = TempY + 70
					end
					
					-- Print the used resources
					local stringUsage = ""
					surface.SetFont("Flavour")
					surface.SetTextColor(155,155,255,255)
					surface.SetTextPos(textStartPos+15,TempY)
					stringUsage = stringUsage.."["..CAF.GetAddon("Resource Distribution").GetProperResourceName("energy")..": "..CAF.GetAddon("Resource Distribution").GetResourceAmount(self, "energy").."/"..CAF.GetAddon("Resource Distribution").GetNetworkCapacity(self, "energy").."] "
					surface.DrawText("Resources: "..stringUsage)
					TempY = TempY + 70
					surface.SetFont("Flavour")
					surface.SetTextColor(155,155,255,255)
					surface.SetTextPos(textStartPos+15,TempY)
					surface.DrawText("Name: " .. tostring(self:GetNetworkedString( 8 )))
					surface.SetFont("Flavour")
					surface.SetTextColor(155,155,255,255)
					surface.SetTextPos(textStartPos+15,TempY)
					surface.DrawText("O2 Level: " .. string.format("%g",self:GetNetworkedInt( 1 )).."%")
					TempY = TempY + 70
					surface.SetFont("Flavour")
					surface.SetTextColor(155,155,255,255)
					surface.SetTextPos(textStartPos+15,TempY)
					surface.DrawText("CO2 Level: " .. string.format("%g",self:GetNetworkedInt( 2 )).."%")
					TempY = TempY + 70
					surface.SetFont("Flavour")
					surface.SetTextColor(155,155,255,255)
					surface.SetTextPos(textStartPos+15,TempY)
					surface.DrawText("Nitrogen Level: " .. string.format("%g",self:GetNetworkedInt( 3 )).."%")
					TempY = TempY + 70
					surface.SetFont("Flavour")
					surface.SetTextColor(155,155,255,255)
					surface.SetTextPos(textStartPos+15,TempY)
					surface.DrawText("Hydrogen Level: " .. string.format("%g",self:GetNetworkedInt( 4 )).."%")
					TempY = TempY + 70
					surface.SetFont("Flavour")
					surface.SetTextColor(155,155,255,255)
					surface.SetTextPos(textStartPos+15,TempY)
					surface.DrawText("'Empty' air Level: " .. string.format("%g",self:GetNetworkedInt( 9 )).."%")
					TempY = TempY + 70
					surface.SetFont("Flavour")
					surface.SetTextColor(155,155,255,255)
					surface.SetTextPos(textStartPos+15,TempY)
					surface.DrawText("Pressure: " .. tostring(self:GetNetworkedInt( 5 )))
					TempY = TempY + 70
					surface.SetFont("Flavour")
					surface.SetTextColor(155,155,255,255)
					surface.SetTextPos(textStartPos+15,TempY)
					surface.DrawText("Temperature: " .. tostring(self:GetNetworkedInt( 6 )))
					TempY = TempY + 70
					surface.SetFont("Flavour")
					surface.SetTextColor(155,155,255,255)
					surface.SetTextPos(textStartPos+15,TempY)
					surface.DrawText("Gravity: " .. tostring(self:GetNetworkedInt( 7 )))
					TempY = TempY + 70
			--Stop rendering
			cam.End3D2D()
		end
	else
		if ( !bDontDrawModel ) then self:DrawModel() end
	end
end

function ENT:Initialize()
	self.ShouldDraw = 1
	self.NextSmokeEffect = 0

	mx, mn = self.Entity:GetRenderBounds()
	self.Entity:SetRenderBounds( mn + Vector(0,0,128), mx, 0 )
end


function ENT:Draw()
	self.BaseClass.Draw( self )

	self:DrawTranslucent()
end

function ENT:DrawTranslucent()
	if ( self.ShouldDraw == 0 ) then return end

	if ( !self:IsOn() ) then return end
	if ( self:GetEffect() == "none" ) then return end

	local EffectThink = self[ "EffectDraw_"..self:GetEffect() ]
	if ( EffectThink ) then EffectThink( self ) end
end

function ENT:Think()
	self.BaseClass.Think(self)

	self.ShouldDraw = GetConVarNumber( "cl_drawthrusterseffects" )
	
	if ( self.ShouldDraw == 0 ) then return end
	
	if ( !self:IsOn() ) then return end
	if ( self:GetEffect() == "none" ) then return end
	
	local EffectThink = self[ "EffectThink_"..self:GetEffect() ]
	if ( EffectThink ) then EffectThink( self ) end
end

function ENT:EffectThink_fire()
end

function ENT:EffectDraw_fire()

	local vOffset = self.Entity:LocalToWorld( self:GetOffset() )
	local vNormal = (vOffset - self.Entity:GetPos()):GetNormalized()

	local scroll = CurTime() * -10

	render.SetMaterial( matFire )

	render.StartBeam( 3 )
		render.AddBeam( vOffset, 8, scroll, Color( 0, 0, 255, 128) )
		render.AddBeam( vOffset + vNormal * 60, 32, scroll + 1, Color( 255, 255, 255, 128) )
		render.AddBeam( vOffset + vNormal * 148, 32, scroll + 3, Color( 255, 255, 255, 0) )
	render.EndBeam()

	scroll = scroll * 0.5

	render.UpdateRefractTexture()
	render.SetMaterial( matHeatWave )
	render.StartBeam( 3 )
		render.AddBeam( vOffset, 8, scroll, Color( 0, 0, 255, 128) )
		render.AddBeam( vOffset + vNormal * 32, 32, scroll + 2, Color( 255, 255, 255, 255) )
		render.AddBeam( vOffset + vNormal * 128, 48, scroll + 5, Color( 0, 0, 0, 0) )
	render.EndBeam()


	scroll = scroll * 1.3
	render.SetMaterial( matFire )
	render.StartBeam( 3 )
		render.AddBeam( vOffset, 8, scroll, Color( 0, 0, 255, 128) )
		render.AddBeam( vOffset + vNormal * 60, 16, scroll + 1, Color( 255, 255, 255, 128) )
		render.AddBeam( vOffset + vNormal * 148, 16, scroll + 3, Color( 255, 255, 255, 0) )
	render.EndBeam()

end

function ENT:EffectDraw_heatwave()

	local vOffset = self.Entity:LocalToWorld( self:GetOffset() )
	local vNormal = (vOffset - self.Entity:GetPos()):GetNormalized()

	local scroll = CurTime() * -10

	render.SetMaterial( matHeatWave )

	render.StartBeam( 3 )
		render.AddBeam( vOffset, 8, scroll, Color( 0, 0, 255, 128) )
		render.AddBeam( vOffset + vNormal * 60, 32, scroll + 1, Color( 255, 255, 255, 128) )
		render.AddBeam( vOffset + vNormal * 148, 32, scroll + 3, Color( 255, 255, 255, 0) )
	render.EndBeam()

	scroll = scroll * 0.5

	render.UpdateRefractTexture()
	render.SetMaterial( matHeatWave )
	render.StartBeam( 3 )
		render.AddBeam( vOffset, 8, scroll, Color( 0, 0, 255, 128) )
		render.AddBeam( vOffset + vNormal * 32, 32, scroll + 2, Color( 255, 255, 255, 255) )
		render.AddBeam( vOffset + vNormal * 128, 48, scroll + 5, Color( 0, 0, 0, 0) )
	render.EndBeam()


	scroll = scroll * 1.3
	render.SetMaterial( matHeatWave )
	render.StartBeam( 3 )
		render.AddBeam( vOffset, 8, scroll, Color( 0, 0, 255, 128) )
		render.AddBeam( vOffset + vNormal * 60, 16, scroll + 1, Color( 255, 255, 255, 128) )
		render.AddBeam( vOffset + vNormal * 148, 16, scroll + 3, Color( 255, 255, 255, 0) )
	render.EndBeam()

end

function ENT:EffectDraw_color()

	local vOffset = self.Entity:LocalToWorld( self:GetOffset() )
	local vNormal = (vOffset - self.Entity:GetPos()):GetNormalized()

	local scroll = CurTime() * -10

	render.SetMaterial( matColor )

	render.StartBeam( 3 )
		render.AddBeam( vOffset, 8, scroll, Color( 255, 0, 0, 128) )
		render.AddBeam( vOffset + vNormal * 60, 32, scroll + 1, Color( 255, 255, 255, 128) )
		render.AddBeam( vOffset + vNormal * 148, 32, scroll + 3, Color( 255, 255, 255, 0) )
	render.EndBeam()

	scroll = scroll * 0.5

	render.UpdateRefractTexture()
	render.SetMaterial( matColor )
	render.StartBeam( 3 )
		render.AddBeam( vOffset, 8, scroll, Color( 0, 255, 0, 128) )
		render.AddBeam( vOffset + vNormal * 32, 32, scroll + 2, Color( 255, 255, 255, 255) )
		render.AddBeam( vOffset + vNormal * 128, 48, scroll + 5, Color( 0, 0, 0, 0) )
	render.EndBeam()


	scroll = scroll * 1.3
	render.SetMaterial( matColor )
	render.StartBeam( 3 )
		render.AddBeam( vOffset, 8, scroll, Color( 0, 0, 255, 128) )
		render.AddBeam( vOffset + vNormal * 60, 16, scroll + 1, Color( 255, 255, 255, 128) )
		render.AddBeam( vOffset + vNormal * 148, 16, scroll + 3, Color( 255, 255, 255, 0) )
	render.EndBeam()

end

function ENT:EffectDraw_color_random()

	local vOffset = self.Entity:LocalToWorld( self:GetOffset() )
	local vNormal = (vOffset - self.Entity:GetPos()):GetNormalized()

	local scroll = CurTime() * -10

	render.SetMaterial( matColor )

	render.StartBeam( 3 )
		render.AddBeam( vOffset, 8, scroll, Color( 255, 0, 0, 128) )
		render.AddBeam( vOffset + vNormal * 60, 32, scroll + 1, Color( math.random(0,255), math.random(0,255), math.random(0,255), 128) )
		render.AddBeam( vOffset + vNormal * 148, 32, scroll + 3, Color( math.random(0,255), math.random(0,255), math.random(0,255), 0) )
	render.EndBeam()

	scroll = scroll * 0.5

	render.UpdateRefractTexture()
	render.SetMaterial( matColor )
	render.StartBeam( 3 )
		render.AddBeam( vOffset, 8, scroll, Color( 0, 255, 0, 128) )
		render.AddBeam( vOffset + vNormal * 32, 32, scroll + 2, Color( math.random(0,255), math.random(0,255), math.random(0,255), 255) )
		render.AddBeam( vOffset + vNormal * 128, 48, scroll + 5, Color( 0, 0, 0, 0) )
	render.EndBeam()

	scroll = scroll * 1.3
	render.SetMaterial( matColor )
	render.StartBeam( 3 )
		render.AddBeam( vOffset, 8, scroll, Color( 0, 0, 255, 128) )
		render.AddBeam( vOffset + vNormal * 60, 16, scroll + 1, Color( math.random(0,255), math.random(0,255), math.random(0,255), 128) )
		render.AddBeam( vOffset + vNormal * 148, 16, scroll + 3, Color( math.random(0,255), math.random(0,255), math.random(0,255), 0) )
	render.EndBeam()

end

function ENT:EffectDraw_color_diy()

	local vOffset = self.Entity:LocalToWorld( self:GetOffset() )
	local vNormal = (vOffset - self.Entity:GetPos()):GetNormalized()
	local r,g,b,a = self.Entity:GetColor();

	local scroll = CurTime() * -10

	render.SetMaterial( matColor )


	render.StartBeam( 3 )
		render.AddBeam( vOffset, 8, scroll, Color( 255, 0, 0, 128) )
		render.AddBeam( vOffset + vNormal * 60, 32, scroll + 1, Color( r, g, g, 128) )
		render.AddBeam( vOffset + vNormal * 148, 32, scroll + 3, Color( r, g, b, 0) )
	render.EndBeam()

	scroll = scroll * 0.5

	render.UpdateRefractTexture()
	render.SetMaterial( matColor )
	render.StartBeam( 3 )
		render.AddBeam( vOffset, 8, scroll, Color( 0, 255, 0, 128) )
		render.AddBeam( vOffset + vNormal * 32, 32, scroll + 2, Color( r, g, g, 255) )
		render.AddBeam( vOffset + vNormal * 128, 48, scroll + 5, Color( 0, 0, 0, 0) )
	render.EndBeam()


	scroll = scroll * 1.3
	render.SetMaterial( matColor )
	render.StartBeam( 3 )
		render.AddBeam( vOffset, 8, scroll, Color( 0, 0, 255, 128) )
		render.AddBeam( vOffset + vNormal * 60, 16, scroll + 1, Color( r, g, g, 128) )
		render.AddBeam( vOffset + vNormal * 148, 16, scroll + 3, Color( 255, 255, 255, 0) )
	render.EndBeam()

end

function ENT:EffectDraw_plasma()

	local vOffset = self.Entity:LocalToWorld( self:GetOffset() )
	local vNormal = (vOffset - self.Entity:GetPos()):GetNormalized()

	local scroll = CurTime() * -20

	render.SetMaterial( matPlasma )

	scroll = scroll * 0.9

	render.StartBeam( 3 )
		render.AddBeam( vOffset, 16, scroll, Color( 0, 255, 255, 255) )
		render.AddBeam( vOffset + vNormal * 8, 16, scroll + 0.01, Color( 255, 255, 255, 255) )
		render.AddBeam( vOffset + vNormal * 64, 16, scroll + 0.02, Color( 0, 255, 255, 0) )
	render.EndBeam()

	scroll = scroll * 0.9

	render.StartBeam( 3 )
		render.AddBeam( vOffset, 16, scroll, Color( 0, 255, 255, 255) )
		render.AddBeam( vOffset + vNormal * 8, 16, scroll + 0.01, Color( 255, 255, 255, 255) )
		render.AddBeam( vOffset + vNormal * 64, 16, scroll + 0.02, Color( 0, 255, 255, 0) )
	render.EndBeam()

	scroll = scroll * 0.9

	render.StartBeam( 3 )
		render.AddBeam( vOffset, 16, scroll, Color( 0, 255, 255, 255) )
		render.AddBeam( vOffset + vNormal * 8, 16, scroll + 0.01, Color( 255, 255, 255, 255) )
		render.AddBeam( vOffset + vNormal * 64, 16, scroll + 0.02, Color( 0, 255, 255, 0) )
	render.EndBeam()

end

function ENT:EffectDraw_fire_smoke()

	local vOffset = self.Entity:LocalToWorld( self:GetOffset() )
	local vNormal = (vOffset - self.Entity:GetPos()):GetNormalized()

	local scroll = CurTime() * -10

	render.SetMaterial( matFire )

	render.StartBeam( 3 )
		render.AddBeam( vOffset, 8, scroll, Color( 0, 0, 255, 128) )
		render.AddBeam( vOffset + vNormal * 60, 32, scroll + 1, Color( 255, 255, 255, 128) )
		render.AddBeam( vOffset + vNormal * 148, 32, scroll + 3, Color( 255, 255, 255, 0) )
	render.EndBeam()

	scroll = scroll * 0.5

	render.UpdateRefractTexture()
	render.SetMaterial( matHeatWave )
	render.StartBeam( 3 )
		render.AddBeam( vOffset, 8, scroll, Color( 0, 0, 255, 128) )
		render.AddBeam( vOffset + vNormal * 32, 32, scroll + 2, Color( 255, 255, 255, 255) )
		render.AddBeam( vOffset + vNormal * 128, 48, scroll + 5, Color( 0, 0, 0, 0) )
	render.EndBeam()


	scroll = scroll * 1.3
	render.SetMaterial( matFire )
	render.StartBeam( 3 )
		render.AddBeam( vOffset, 8, scroll, Color( 0, 0, 255, 128) )
		render.AddBeam( vOffset + vNormal * 60, 16, scroll + 1, Color( 255, 255, 255, 128) )
		render.AddBeam( vOffset + vNormal * 148, 16, scroll + 3, Color( 255, 255, 255, 0) )
	render.EndBeam()

		self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + 0.015

	vOffset = self.Entity:LocalToWorld( self:GetOffset() ) + Vector( math.Rand( -3, 3 ), math.Rand( -3, 3 ), math.Rand( -3, 3 ) )
	vNormal = (vOffset - self.Entity:GetPos()):GetNormalized()

	local emitter = ParticleEmitter( vOffset )

		local particle = emitter:Add( "particles/smokey", vOffset )
			particle:SetVelocity( vNormal * math.Rand( 10, 30 ) )
			particle:SetDieTime( 2.0 )
			particle:SetStartAlpha( math.Rand( 50, 150 ) )
			particle:SetStartSize( math.Rand( 8, 16 ) )
			particle:SetEndSize( math.Rand( 32, 64  ) )
			particle:SetRoll( math.Rand( -0.2, 0.2 ) )
			particle:SetColor( 200, 200, 210 )

	emitter:Finish()

end

function ENT:EffectDraw_fire_smoke_big()

	self.RingTimer = self.RingTimer or 0
	if ( self.RingTimer > CurTime() ) then return end
	self.RingTimer = CurTime() + 0.00005

	local vOffset = self.Entity:LocalToWorld( self:GetOffset() )
	local vNormal = (vOffset - self.Entity:GetPos()):GetNormalized()

	local effectdata = EffectData()
		effectdata:SetOrigin( vOffset )
		effectdata:SetNormal( vNormal )
		effectdata:SetRadius( 10 )
		effectdata:SetScale( 6 )
	util.Effect( "HelicopterMegaBomb", effectdata )

	vOffset = self.Entity:LocalToWorld( self:GetOffset() ) + Vector( math.Rand( -3, 3 ), math.Rand( -3, 3 ), math.Rand( -3, 3 ) )
	vNormal = (vOffset - self.Entity:GetPos()):GetNormalized()

	local emitter = ParticleEmitter( vOffset )

		local particle = emitter:Add( "particles/smokey", vOffset )
			particle:SetVelocity( vNormal * math.Rand( 10, 20 ) )
			particle:SetDieTime( 5.0 )
			particle:SetStartAlpha( math.Rand( 50, 150 ) )
			particle:SetStartSize( math.Rand( 64, 128 ) )
			particle:SetEndSize( math.Rand( 256, 128 ) )
			particle:SetRoll( math.Rand( -0.2, 0.2 ) )
			particle:SetColor( 200, 200, 210 )

	emitter:Finish()

	local effectdata = EffectData()
		effectdata:SetOrigin( vOffset )
		effectdata:SetNormal( vNormal )
	util.Effect( "ThumperDust ", effectdata )

end

function ENT:EffectThink_smoke()

	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + 0.015

	local vOffset = self.Entity:LocalToWorld( self:GetOffset() ) + Vector( math.Rand( -3, 3 ), math.Rand( -3, 3 ), math.Rand( -3, 3 ) )
	local vNormal = (vOffset - self.Entity:GetPos()):GetNormalized()

	local emitter = ParticleEmitter( vOffset )

		local particle = emitter:Add( "particles/smokey", vOffset )
			particle:SetVelocity( vNormal * math.Rand( 10, 30 ) )
			particle:SetDieTime( 2.0 )
			particle:SetStartAlpha( math.Rand( 50, 150 ) )
			particle:SetStartSize( math.Rand( 16, 32 ) )
			particle:SetEndSize( math.Rand( 64, 128 ) )
			particle:SetRoll( math.Rand( -0.2, 0.2 ) )
			particle:SetColor( 200, 200, 210 )

	emitter:Finish()

end

function ENT:EffectThink_smoke_firecolors()

	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + 0.015

	local vOffset = self.Entity:LocalToWorld( self:GetOffset() ) + Vector( math.Rand( -3, 3 ), math.Rand( -3, 3 ), math.Rand( -3, 3 ) )
	local vNormal = (vOffset - self.Entity:GetPos()):GetNormalized()

	local emitter = ParticleEmitter( vOffset )

		local particle = emitter:Add( "particles/smokey", vOffset )
			particle:SetVelocity( vNormal * math.Rand( 10, 30 ) )
			particle:SetDieTime( 2.0 )
			particle:SetStartAlpha( math.Rand( 50, 150 ) )
			particle:SetStartSize( math.Rand( 16, 32 ) )
			particle:SetEndSize( math.Rand( 64, 128 ) )
			particle:SetRoll( math.Rand( -0.2, 0.2 ) )
			particle:SetColor(math.random(220,255),math.random(110,220),0 )

	emitter:Finish()

end

function ENT:EffectThink_smoke_random()

	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + 0.015

	local vOffset = self.Entity:LocalToWorld( self:GetOffset() ) + Vector( math.Rand( -3, 3 ), math.Rand( -3, 3 ), math.Rand( -3, 3 ) )
	local vNormal = (vOffset - self.Entity:GetPos()):GetNormalized()

	local emitter = ParticleEmitter( vOffset )

		local particle = emitter:Add( "particles/smokey", vOffset )
			particle:SetVelocity( vNormal * math.Rand( 10, 30 ) )
			particle:SetDieTime( 2.0 )
			particle:SetStartAlpha( math.Rand( 50, 150 ) )
			particle:SetStartSize( math.Rand( 16, 32 ) )
			particle:SetEndSize( math.Rand( 64, 128 ) )
			particle:SetRoll( math.Rand( -0.2, 0.2 ) )
			particle:SetColor( math.random(100,255),math.random(100,255),math.random(100,255) )

	emitter:Finish()

end

function ENT:EffectThink_smoke_diy()
local r,g,b,a = self.Entity:GetColor();
	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + 0.015

	local vOffset = self.Entity:LocalToWorld( self:GetOffset() ) + Vector( math.Rand( -3, 3 ), math.Rand( -3, 3 ), math.Rand( -3, 3 ) )
	local vNormal = (vOffset - self.Entity:GetPos()):GetNormalized()

	local emitter = ParticleEmitter( vOffset )

		local particle = emitter:Add( "particles/smokey", vOffset )
			particle:SetVelocity( vNormal * math.Rand( 10, 30 ) )
			particle:SetDieTime( 2.0 )
			particle:SetStartAlpha( math.Rand( 50, 150 ) )
			particle:SetStartSize( math.Rand( 16, 32 ) )
			particle:SetEndSize( math.Rand( 64, 128 ) )
			particle:SetRoll( math.Rand( -0.2, 0.2 ) )
			particle:SetColor( r,g,b)

	emitter:Finish()

end

function ENT:EffectDraw_color_magic()

	local vOffset = self.Entity:LocalToWorld( self:GetOffset() )
	local vNormal = (vOffset - self.Entity:GetPos()):GetNormalized()

	local scroll = CurTime() * -10

	render.SetMaterial( matColor )

	render.StartBeam( 3 )
		render.AddBeam( vOffset, 8, scroll, Color( 255, 0, 0, 128) )
		render.AddBeam( vOffset + vNormal * 60, 32, scroll + 1, Color( 255, 255, 255, 128) )
		render.AddBeam( vOffset + vNormal * 148, 32, scroll + 3, Color( 255, 255, 255, 0) )
	render.EndBeam()

	scroll = scroll * 0.5

	render.UpdateRefractTexture()
	render.SetMaterial( matColor )
	render.StartBeam( 3 )
		render.AddBeam( vOffset, 8, scroll, Color( 0, 255, 0, 128) )
		render.AddBeam( vOffset + vNormal * 32, 32, scroll + 2, Color( 255, 255, 255, 255) )
		render.AddBeam( vOffset + vNormal * 128, 48, scroll + 5, Color( 0, 0, 0, 0) )
	render.EndBeam()


	scroll = scroll * 1.3
	render.SetMaterial( matColor )
	render.StartBeam( 3 )
		render.AddBeam( vOffset, 8, scroll, Color( 0, 0, 255, 128) )
		render.AddBeam( vOffset + vNormal * 60, 16, scroll + 1, Color( 255, 255, 255, 128) )
		render.AddBeam( vOffset + vNormal * 148, 16, scroll + 3, Color( 255, 255, 255, 0) )
	render.EndBeam()

		self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + 0.00005

	vOffset = self.Entity:LocalToWorld( self:GetOffset() )
	vNormal = (vOffset - self.Entity:GetPos()):GetNormalized()

	vOffset = vOffset + VectorRand() * 5

	local emitter = ParticleEmitter( vOffset )

		local particle = emitter:Add( "sprites/gmdm_pickups/light", vOffset )
			particle:SetVelocity( vNormal * math.Rand( 50, 80 ) )
			particle:SetDieTime( 1 )
			particle:SetStartAlpha( 255 )
			particle:SetEndAlpha( 255 )
			particle:SetStartSize( math.Rand( 1, 3 ) )
			particle:SetEndSize( 0 )
			particle:SetRoll( math.Rand( -0.2, 0.2 ) )

	emitter:Finish()

end

function ENT:EffectThink_money()

	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + math.random(0.005,0.00005)

	local vOffset = self.Entity:LocalToWorld( self:GetOffset() )
	local vNormal = (vOffset - self.Entity:GetPos()):GetNormalized()

	vOffset = vOffset + VectorRand() * 20

	local emitter = ParticleEmitter( vOffset )

		local particle = emitter:Add( "thrusteraddon/money"..math.floor(math.random(1,3)).."", vOffset )
			particle:SetVelocity( vNormal * math.Rand( 0, 70 ) )
			particle:SetDieTime( math.Rand(3,5 ) )
			particle:SetStartAlpha( 255 )
			particle:SetEndAlpha( 0 )
			particle:SetStartSize( 5 )
			particle:SetEndSize( 5 )
			particle:SetRoll( math.Rand( -90, 90 ) )

	emitter:Finish()

end

function ENT:EffectThink_debug_10()

	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + 0.05

	local vOffset = self.Entity:LocalToWorld( self:GetOffset() )
	local vNormal = (vOffset - self.Entity:GetPos()):GetNormalized()


	local emitter = ParticleEmitter( vOffset )

		local particle = emitter:Add( "decals/cross", vOffset )
			particle:SetVelocity( vNormal * 0 )
			particle:SetDieTime( 10 )
			particle:SetStartAlpha( 255 )
			particle:SetEndAlpha( 255 )
			particle:SetColor(0,255,0 )
			particle:SetStartSize( 5 )
			particle:SetEndSize( math.Rand(7,10) )
			particle:SetRoll(0)

	emitter:Finish()

end

function ENT:EffectThink_debug_30()

	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + 0.05

	local vOffset = self.Entity:LocalToWorld( self:GetOffset() )
	local vNormal = (vOffset - self.Entity:GetPos()):GetNormalized()


	local emitter = ParticleEmitter( vOffset )

		local particle = emitter:Add( "decals/cross", vOffset )
			particle:SetVelocity( vNormal * 0 )
			particle:SetDieTime( 30 )
			particle:SetStartAlpha( 255 )
			particle:SetEndAlpha( 255 )
			particle:SetColor(0,255,0 )
			particle:SetStartSize( 5 )
			particle:SetEndSize( math.Rand(7,10) )
			particle:SetRoll(0)

	emitter:Finish()

end

function ENT:EffectThink_debug_60()

	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + 0.05

	local vOffset = self.Entity:LocalToWorld( self:GetOffset() )
	local vNormal = (vOffset - self.Entity:GetPos()):GetNormalized()


	local emitter = ParticleEmitter( vOffset )

		local particle = emitter:Add( "decals/cross", vOffset )
			particle:SetVelocity( vNormal * 0 )
			particle:SetDieTime( 60 )
			particle:SetStartAlpha( 255 )
			particle:SetEndAlpha( 255 )
			particle:SetColor(0,255,0 )
			particle:SetStartSize( 5 )
			particle:SetEndSize( math.Rand(7,10) )
			particle:SetRoll(0)

	emitter:Finish()

end

function ENT:EffectThink_souls()

	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + 0.05

	local vOffset = self.Entity:LocalToWorld( self:GetOffset() )
	local vNormal = (vOffset - self.Entity:GetPos()):GetNormalized()

	vOffset = vOffset + VectorRand() * 20

	local emitter = ParticleEmitter( vOffset )

		local particle = emitter:Add( "sprites/soul", vOffset )
			particle:SetVelocity( vNormal * math.Rand( 0, 50 ) )
			particle:SetDieTime( math.Rand(3,5 ) )
			particle:SetStartAlpha( 255 )
			particle:SetEndAlpha( 0 )
			particle:SetColor(255,255,255 )
			particle:SetStartSize( 0 )
			particle:SetEndSize( math.Rand(7,10) )
			particle:SetRoll( math.Rand( -90, 90 ) )

	emitter:Finish()

end

function ENT:EffectThink_sperm()

	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + math.random(0.005,0.00005)

	local vOffset = self.Entity:LocalToWorld( self:GetOffset() )
	local vNormal = (vOffset - self.Entity:GetPos()):GetNormalized()

	vOffset = vOffset + VectorRand() * 5

	local emitter = ParticleEmitter( vOffset )

		local particle = emitter:Add( "thrusteraddon/sperm", vOffset )
			particle:SetVelocity( vNormal * math.Rand( 0, 70 ) )
			particle:SetDieTime( math.Rand(3,5 ) )
			particle:SetStartAlpha( 255 )
			particle:SetEndAlpha( 200 )
			particle:SetStartSize( 10 )
			particle:SetEndSize( 1 )
			particle:SetRoll( math.random(-180, 180) )

		local particle2 = emitter:Add( "thrusteraddon/goo", vOffset )
			particle2:SetVelocity( vNormal * 0.5  )
			particle2:SetDieTime( math.Rand(3,5 ) )
			particle2:SetStartAlpha( 100 )
			particle2:SetEndAlpha( 5 )
			particle2:SetColor(255,255,255 )
			particle2:SetStartSize( 5 )
			particle2:SetEndSize( 1 )
			particle2:SetRoll( math.random(-180, 180) )

		local particle3 = emitter:Add( "thrusteraddon/goo2", vOffset )
			particle3:SetVelocity( vNormal * 0.5 )
			particle3:SetDieTime( math.Rand(3,5 ) )
			particle3:SetStartAlpha(100 )
			particle3:SetEndAlpha( 5 )
			particle3:SetColor(255,255,255 )
			particle3:SetStartSize( 5 )
			particle3:SetEndSize( 1 )
			particle3:SetRoll( math.random(-180, 180) )

	emitter:Finish()

end


function ENT:EffectThink_feather()

	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + math.random(0.005,0.00005)

	local vOffset = self.Entity:LocalToWorld( self:GetOffset() )
	local vNormal = (vOffset - self.Entity:GetPos()):GetNormalized()

	vOffset = vOffset + VectorRand() * 30

	local emitter = ParticleEmitter( vOffset )

		local particle = emitter:Add( "thrusteraddon/feather"..math.floor(math.random(2,4)).."", vOffset )
			particle:SetVelocity( vNormal * math.Rand( 0, 50 ) )
			particle:SetDieTime( math.Rand(5,7 ) )
			particle:SetStartAlpha( 120 )
			particle:SetEndAlpha( 0 )
			particle:SetStartSize( 5 )
			particle:SetEndSize( 5 )
			particle:SetRoll( math.Rand( -90, 90 ) )

	emitter:Finish()

end

function ENT:EffectThink_goldstar()

	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + math.random(0.005,0.00005)

	local vOffset = self.Entity:LocalToWorld( self:GetOffset() )
	local vNormal = (vOffset - self.Entity:GetPos()):GetNormalized()

	vOffset = vOffset + VectorRand() * 10

	local emitter = ParticleEmitter( vOffset )

		local particle = emitter:Add( "thrusteraddon/Goldstar", vOffset )
			particle:SetVelocity( vNormal * math.Rand( 150, 200 ) )
			particle:SetDieTime( math.Rand(0,1 ) )
			particle:SetStartAlpha( 120 )
			particle:SetEndAlpha( 0 )
			particle:SetStartSize( 5 )
			particle:SetEndSize( 5 )
			particle:SetRoll( math.Rand( -90, 90 ) )

	emitter:Finish()

end

function ENT:EffectThink_candy_cane()

	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + math.random(0.005,0.00005)

	local vOffset = self.Entity:LocalToWorld( self:GetOffset() )
	local vNormal = (vOffset - self.Entity:GetPos()):GetNormalized()

	vOffset = vOffset + VectorRand() * 5

	local emitter = ParticleEmitter( vOffset )

		local particle = emitter:Add( "thrusteraddon/candy", vOffset )
			particle:SetVelocity( vNormal * math.Rand( 0, 20 ) )
			particle:SetDieTime( math.Rand(5,7 ) )
			particle:SetStartAlpha( 120 )
			particle:SetEndAlpha( 0 )
			particle:SetStartSize( 5 )
			particle:SetEndSize( 5 )
			particle:SetRoll( math.Rand( -90, 90 ) )

	emitter:Finish()

end

function ENT:EffectThink_jetflame_advanced()
	self.Smoking = self.Smoking or false
	if self.Entity:GetVelocity():Length() == 0 then
	self.Smoking = false
	end
	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + 0.0000005

	local vOffset = self.Entity:LocalToWorld( self:GetOffset() )
	local vNormal = (vOffset - self.Entity:GetPos()):GetNormalized()

	//vOffset = vOffset + VectorRand() * 5

	local r,g,b
	if self.Entity:GetVelocity():Length() < 1700 then
	r = math.Rand(220,255)
	g = math.Rand(180,220)
	b = 55
	else
	r = 55
	g = 55
	b = math.Rand(200,255)
	end
	local emitter = ParticleEmitter( vOffset )
	local speed = math.Rand(90,252)
	local roll = math.Rand(-90,90)

		local particle = emitter:Add( "particle/fire", vOffset )
			particle:SetVelocity( vNormal * speed )
			particle:SetDieTime( 0.3 )
			particle:SetStartAlpha( 255 )
			particle:SetEndAlpha( 150 )
			particle:SetStartSize( 15.8 )
			particle:SetEndSize( 9 )
			particle:SetColor( r,g,b)
			particle:SetRoll( roll )

		local particle3 = emitter:Add( "sprites/heatwave", vOffset )
			particle3:SetVelocity( vNormal * speed )
			particle3:SetDieTime( 0.7 )
			particle3:SetStartAlpha( 255 )
			particle3:SetEndAlpha( 255 )
			particle3:SetStartSize( 16 )
			particle3:SetEndSize( 18 )
			particle3:SetColor( 255,255,255 )
			particle3:SetRoll( roll )

			vOffset = self.Entity:LocalToWorld( self:GetOffset() )

		local particle2 = emitter:Add( "particle/fire", vOffset )
			particle2:SetVelocity( vNormal * speed )
			particle2:SetDieTime( 0.2 )
			particle2:SetStartAlpha( 200 )
			particle2:SetEndAlpha( 50 )
			particle2:SetStartSize( 8.8 )
			particle2:SetEndSize( 5 )
			particle2:SetColor( 200,200,200 )
			particle2:SetRoll( roll )

	if self.Entity:GetVelocity():Length() < 1000 then
	if not self.Smoking then
	 local particle4 = emitter:Add( "particles/smokey", vOffset )
			particle4:SetVelocity( vNormal * math.Rand( 10, 30 ) )
			particle4:SetDieTime( 20.0 )
			particle4:SetStartAlpha( math.Rand( 50, 150 ) )
			particle4:SetEndAlpha( math.Rand( 0, 10 ) )
			particle4:SetStartSize( math.Rand( 512, 1024 ) )
			particle4:SetEndSize( math.Rand( 16,32  ) )
			particle4:SetRoll( math.Rand( -0.2, 0.2 ) )
			particle4:SetColor( 200, 200, 210 )
	end
	elseif self.Entity:GetVelocity():Length() > 1000 then
	self.Smoking = true
	end

	emitter:Finish()

end
function ENT:EffectThink_jetflame()

	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + 0.0000005

	local vOffset = self.Entity:LocalToWorld( self:GetOffset() )
	local vNormal = (vOffset - self.Entity:GetPos()):GetNormalized()

	//vOffset = vOffset + VectorRand() * 5

	local emitter = ParticleEmitter( vOffset )
	local speed = math.Rand(90,252)
	local roll = math.Rand(-90,90)

		local particle = emitter:Add( "particle/fire", vOffset )
			particle:SetVelocity( vNormal * speed )
			particle:SetDieTime( 0.3 )
			particle:SetStartAlpha( 255 )
			particle:SetEndAlpha( 150 )
			particle:SetStartSize( 15.8 )
			particle:SetEndSize( 9 )
			particle:SetColor( math.Rand(220,255),math.Rand(180,220),55 )
			particle:SetRoll( roll )

		local particle3 = emitter:Add( "sprites/heatwave", vOffset )
			particle3:SetVelocity( vNormal * speed )
			particle3:SetDieTime( 0.7 )
			particle3:SetStartAlpha( 255 )
			particle3:SetEndAlpha( 255 )
			particle3:SetStartSize( 16 )
			particle3:SetEndSize( 18 )
			particle3:SetColor( 255,255,255 )
			particle3:SetRoll( roll )

			vOffset = self.Entity:LocalToWorld( self:GetOffset() )

		local particle2 = emitter:Add( "particle/fire", vOffset )
			particle2:SetVelocity( vNormal * speed )
			particle2:SetDieTime( 0.2 )
			particle2:SetStartAlpha( 200 )
			particle2:SetEndAlpha( 50 )
			particle2:SetStartSize( 8.8 )
			particle2:SetEndSize( 5 )
			particle2:SetColor( 200,200,200 )
			particle2:SetRoll( roll )




	emitter:Finish()

end

function ENT:EffectThink_jetflame_purple()

	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + 0.0000005

	local vOffset = self.Entity:LocalToWorld( self:GetOffset() )
	local vNormal = (vOffset - self.Entity:GetPos()):GetNormalized()

	//vOffset = vOffset + VectorRand() * 5

	local emitter = ParticleEmitter( vOffset )
	local speed = math.Rand(90,252)
	local roll = math.Rand(-90,90)

		local particle = emitter:Add( "particle/fire", vOffset )
			particle:SetVelocity( vNormal * speed )
			particle:SetDieTime( 0.3 )
			particle:SetStartAlpha( 255 )
			particle:SetEndAlpha( 150 )
			particle:SetStartSize( 15.8 )
			particle:SetEndSize( 9 )
			particle:SetColor(  math.Rand(220,255),55, math.Rand(220,255) )
			particle:SetRoll( roll )

		local particle3 = emitter:Add( "sprites/heatwave", vOffset )
			particle3:SetVelocity( vNormal * speed )
			particle3:SetDieTime( 0.7 )
			particle3:SetStartAlpha( 255 )
			particle3:SetEndAlpha( 255 )
			particle3:SetStartSize( 16 )
			particle3:SetEndSize( 18 )
			particle3:SetColor( 255,255,255 )
			particle3:SetRoll( roll )

			vOffset = self.Entity:LocalToWorld( self:GetOffset() )

		local particle2 = emitter:Add( "particle/fire", vOffset )
			particle2:SetVelocity( vNormal * speed )
			particle2:SetDieTime( 0.2 )
			particle2:SetStartAlpha( 200 )
			particle2:SetEndAlpha( 50 )
			particle2:SetStartSize( 8.8 )
			particle2:SetEndSize( 5 )
			particle2:SetColor( 200,200,200 )
			particle2:SetRoll( roll )




	emitter:Finish()

end

function ENT:EffectThink_jetflame_red()

	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + 0.0000005

	local vOffset = self.Entity:LocalToWorld( self:GetOffset() )
	local vNormal = (vOffset - self.Entity:GetPos()):GetNormalized()

	//vOffset = vOffset + VectorRand() * 5

	local emitter = ParticleEmitter( vOffset )
	local speed = math.Rand(90,252)
	local roll = math.Rand(-90,90)

		local particle = emitter:Add( "particle/fire", vOffset )
			particle:SetVelocity( vNormal * speed )
			particle:SetDieTime( 0.3 )
			particle:SetStartAlpha( 255 )
			particle:SetEndAlpha( 150 )
			particle:SetStartSize( 15.8 )
			particle:SetEndSize( 9 )
			particle:SetColor( math.Rand(220,255),55,55 )
			particle:SetRoll( roll )

		local particle3 = emitter:Add( "sprites/heatwave", vOffset )
			particle3:SetVelocity( vNormal * speed )
			particle3:SetDieTime( 0.7 )
			particle3:SetStartAlpha( 255 )
			particle3:SetEndAlpha( 255 )
			particle3:SetStartSize( 16 )
			particle3:SetEndSize( 18 )
			particle3:SetColor( 255,255,255 )
			particle3:SetRoll( roll )

			vOffset = self.Entity:LocalToWorld( self:GetOffset() )

		local particle2 = emitter:Add( "particle/fire", vOffset )
			particle2:SetVelocity( vNormal * speed )
			particle2:SetDieTime( 0.2 )
			particle2:SetStartAlpha( 200 )
			particle2:SetEndAlpha( 50 )
			particle2:SetStartSize( 8.8 )
			particle2:SetEndSize( 5 )
			particle2:SetColor( 200,200,200 )
			particle2:SetRoll( roll )


	emitter:Finish()

end


function ENT:EffectThink_jetflame_blue()

	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + 0.0000005

	local vOffset = self.Entity:LocalToWorld( self:GetOffset() )
	local vNormal = (vOffset - self.Entity:GetPos()):GetNormalized()

	//vOffset = vOffset + VectorRand() * 5

	local emitter = ParticleEmitter( vOffset )
	local speed = math.Rand(90,252)
	local roll = math.Rand(-90,90)

		local particle = emitter:Add( "particle/fire", vOffset )
			particle:SetVelocity( vNormal * speed )
			particle:SetDieTime( 0.3 )
			particle:SetStartAlpha( 255 )
			particle:SetEndAlpha( 150 )
			particle:SetStartSize( 15.8 )
			particle:SetEndSize( 9 )
			particle:SetColor( 55,55, math.Rand(220,255) )
			particle:SetRoll( roll )

		local particle3 = emitter:Add( "sprites/heatwave", vOffset )
			particle3:SetVelocity( vNormal * speed )
			particle3:SetDieTime( 0.7 )
			particle3:SetStartAlpha( 255 )
			particle3:SetEndAlpha( 255 )
			particle3:SetStartSize( 16 )
			particle3:SetEndSize( 18 )
			particle3:SetColor( 255,255,255 )
			particle3:SetRoll( roll )

			vOffset = self.Entity:LocalToWorld( self:GetOffset() )

		local particle2 = emitter:Add( "particle/fire", vOffset )
			particle2:SetVelocity( vNormal * speed )
			particle2:SetDieTime( 0.2 )
			particle2:SetStartAlpha( 200 )
			particle2:SetEndAlpha( 50 )
			particle2:SetStartSize( 8.8 )
			particle2:SetEndSize( 5 )
			particle2:SetColor( 200,200,200 )
			particle2:SetRoll( roll )



	emitter:Finish()

end


function ENT:EffectThink_balls_firecolors()
	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + 0.025

	local vOffset = self.Entity:LocalToWorld( self:GetOffset() )
	local vNormal = (vOffset - self.Entity:GetPos()):GetNormalized()
	vOffset = vOffset + VectorRand() * 2

	local emitter = ParticleEmitter( vOffset )

		local particle = emitter:Add( "sprites/sent_ball", vOffset )
			particle:SetVelocity( vNormal * 80 )
			particle:SetDieTime( 1 )
			particle:SetStartAlpha( 255 )
			particle:SetEndAlpha( 255 )
			particle:SetColor(math.random(220,255),math.random(100,200),0)
			particle:SetStartSize( 4 )
			particle:SetEndSize( 0 )
			particle:SetRoll( 0 )

	emitter:Finish()

end

function ENT:EffectThink_balls_random()
	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + 0.025

	local vOffset = self.Entity:LocalToWorld( self:GetOffset() )
	local vNormal = (vOffset - self.Entity:GetPos()):GetNormalized()
	vOffset = vOffset + VectorRand() * 2

	local emitter = ParticleEmitter( vOffset )

		local particle = emitter:Add( "sprites/sent_ball", vOffset )
			particle:SetVelocity( vNormal * 80 )
			particle:SetDieTime( 1 )
			particle:SetStartAlpha( 255 )
			particle:SetEndAlpha( 255 )
			particle:SetColor(math.random(0,255),math.random(0,255),math.random(0,255))
			particle:SetStartSize( 4 )
			particle:SetEndSize( 0 )
			particle:SetRoll( 0 )

	emitter:Finish()

end

function ENT:EffectThink_balls()
local r,g,b,a = self.Entity:GetColor();
	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + 0.025

	local vOffset = self.Entity:LocalToWorld( self:GetOffset() )
	local vNormal = (vOffset - self.Entity:GetPos()):GetNormalized()
	vOffset = vOffset + VectorRand() * 2

	local emitter = ParticleEmitter( vOffset )

		local particle = emitter:Add( "sprites/sent_ball", vOffset )
			particle:SetVelocity( vNormal * 80 )
			particle:SetDieTime( 1 )
			particle:SetStartAlpha( 255 )
			particle:SetEndAlpha( 255 )
			particle:SetColor(r,g,b)
			particle:SetStartSize( 4 )
			particle:SetEndSize( 0 )
			particle:SetRoll( 0 )

	emitter:Finish()

end

function ENT:EffectThink_plasma_rings()

	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + 0.00005

	local vOffset = self.Entity:LocalToWorld( self:GetOffset() )
	local vNormal = (vOffset - self.Entity:GetPos()):GetNormalized()

	vOffset = vOffset + VectorRand() * 5

	local emitter = ParticleEmitter( vOffset )

		local particle = emitter:Add( "sprites/magic", vOffset )
			particle:SetVelocity( vNormal * math.Rand( 50, 80 ) )
			particle:SetDieTime( 1 )
			particle:SetStartAlpha( 255 )
			particle:SetEndAlpha( 255 )
			particle:SetStartSize( math.Rand( 3,5 ) )
			particle:SetEndSize( 0 )
			particle:SetRoll( math.Rand( -0.2, 0.2 ) )

	emitter:Finish()

end

function ENT:EffectThink_magic_firecolors()

	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + 0.00005

	local vOffset = self.Entity:LocalToWorld( self:GetOffset() )
	local vNormal = (vOffset - self.Entity:GetPos()):GetNormalized()

	vOffset = vOffset + VectorRand() * 5

	local emitter = ParticleEmitter( vOffset )

		local particle = emitter:Add( "sprites/gmdm_pickups/light", vOffset )
			particle:SetVelocity( vNormal * math.Rand( 50, 80 ) )
			particle:SetDieTime( 1 )
			particle:SetStartAlpha( 255 )
			particle:SetEndAlpha( 255 )
			particle:SetColor(math.random(220,255),math.random(100,200),0)
			particle:SetStartSize( math.Rand( 1, 3 ) )
			particle:SetEndSize( 0 )
			particle:SetRoll( math.Rand( -0.2, 0.2 ) )

	emitter:Finish()

end

function ENT:EffectThink_magic()

	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + 0.00005

	local vOffset = self.Entity:LocalToWorld( self:GetOffset() )
	local vNormal = (vOffset - self.Entity:GetPos()):GetNormalized()

	vOffset = vOffset + VectorRand() * 5

	local emitter = ParticleEmitter( vOffset )

		local particle = emitter:Add( "sprites/gmdm_pickups/light", vOffset )
			particle:SetVelocity( vNormal * math.Rand( 50, 80 ) )
			particle:SetDieTime( 1 )
			particle:SetStartAlpha( 255 )
			particle:SetEndAlpha( 255 )
			particle:SetStartSize( math.Rand( 1, 3 ) )
			particle:SetEndSize( 0 )
			particle:SetRoll( math.Rand( -0.2, 0.2 ) )

	emitter:Finish()

end

function ENT:EffectThink_magic_diy()
local r,g,b,a = self.Entity:GetColor();
	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + 0.00005

	local vOffset = self.Entity:LocalToWorld( self:GetOffset() )
	local vNormal = (vOffset - self.Entity:GetPos()):GetNormalized()

	vOffset = vOffset + VectorRand() * 5

	local emitter = ParticleEmitter( vOffset )

		local particle = emitter:Add( "sprites/gmdm_pickups/light", vOffset )
			particle:SetVelocity( vNormal * math.Rand( 50, 80 ) )
			particle:SetDieTime( 1 )
			particle:SetStartAlpha( 255 )
			particle:SetEndAlpha( 255 )
			particle:SetColor(r,g,b)
			particle:SetStartSize( math.Rand( 1, 3 ) )
			particle:SetEndSize( 0 )
			particle:SetRoll( math.Rand( -0.2, 0.2 ) )

	emitter:Finish()

end

function ENT:EffectThink_magic_color()

	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + 0.00005

	local vOffset = self.Entity:LocalToWorld( self:GetOffset() )
	local vNormal = (vOffset - self.Entity:GetPos()):GetNormalized()

	vOffset = vOffset + VectorRand() * 5

	local emitter = ParticleEmitter( vOffset )

		local particle = emitter:Add( "sprites/gmdm_pickups/light", vOffset )
			particle:SetVelocity( vNormal * math.Rand( 50, 80) )
			particle:SetDieTime( 1 )
			particle:SetStartAlpha( 255 )
			particle:SetEndAlpha( 255 )
			particle:SetColor( math.random(0,255),math.random(0,255),math.random(0,255))
			particle:SetStartSize( math.Rand( 1, 3 ) )
			particle:SetEndSize( 0 )
			particle:SetRoll( math.Rand( -0.2, 0.2 ) )

	emitter:Finish()

end


function ENT:EffectDraw_rings()

	self.RingTimer = self.RingTimer or 0
	if ( self.RingTimer > CurTime() ) then return end
	self.RingTimer = CurTime() + 0.00005

	local vOffset = self.Entity:LocalToWorld( self:GetOffset() )
	local vNormal = (vOffset - self.Entity:GetPos()):GetNormalized()

	local effectdata = EffectData()
		effectdata:SetOrigin( vOffset )
		effectdata:SetNormal( vNormal )
	util.Effect( "thruster_ring", effectdata )

end

function ENT:EffectDraw_tesla()

	self.RingTimer = self.RingTimer or 0
	if ( self.RingTimer > CurTime() ) then return end
	self.RingTimer = CurTime() + 0.00005

	local vOffset = self.Entity:LocalToWorld( self:GetOffset() )
	local vNormal = (vOffset - self.Entity:GetPos()):GetNormalized()

	local effectdata = EffectData()
		effectdata:SetOrigin( vOffset )
		effectdata:SetNormal( vNormal )
		effectdata:SetRadius( 1 )
		effectdata:SetScale( 1 )
	util.Effect( "TeslaZap ", effectdata )

end

function ENT:EffectDraw_blood()

	self.RingTimer = self.RingTimer or 0
	if ( self.RingTimer > CurTime() ) then return end
	self.RingTimer = CurTime() + 0.00005

	local vOffset = self.Entity:LocalToWorld( self:GetOffset() )
	local vNormal = (vOffset - self.Entity:GetPos()):GetNormalized()

	local effectdata = EffectData()
		effectdata:SetOrigin( vOffset )
		effectdata:SetNormal( vNormal )
		effectdata:SetRadius( 1 )
		effectdata:SetScale( 1 )
	util.Effect( "BloodImpact", effectdata )

end

function ENT:EffectDraw_some_sparks()

	self.RingTimer = self.RingTimer or 0
	if ( self.RingTimer > CurTime() ) then return end
	self.RingTimer = CurTime() + 0.00005

	local vOffset = self.Entity:LocalToWorld( self:GetOffset() )
	local vNormal = (vOffset - self.Entity:GetPos()):GetNormalized()

	local effectdata = EffectData()
		effectdata:SetOrigin( vOffset )
		effectdata:SetNormal( vNormal )
		effectdata:SetRadius( 1 )
		effectdata:SetScale( 1 )
	util.Effect( "StunstickImpact", effectdata )

end

function ENT:EffectDraw_spark_fountain()

	self.RingTimer = self.RingTimer or 0
	if ( self.RingTimer > CurTime() ) then return end
	self.RingTimer = CurTime() + 0.00005

	local vOffset = self.Entity:LocalToWorld( self:GetOffset() )
	local vNormal = (vOffset - self.Entity:GetPos()):GetNormalized()

	local effectdata = EffectData()
		effectdata:SetOrigin( vOffset )
		effectdata:SetNormal( vNormal )
		effectdata:SetRadius( 1 )
		effectdata:SetScale( 1 )
	util.Effect( "ManhackSparks", effectdata )

end

function ENT:EffectDraw_more_sparks()

	self.RingTimer = self.RingTimer or 0
	if ( self.RingTimer > CurTime() ) then return end
	self.RingTimer = CurTime() + 0.00005

	local vOffset = self.Entity:LocalToWorld( self:GetOffset() )
	local vNormal = (vOffset - self.Entity:GetPos()):GetNormalized()

	local effectdata = EffectData()
		effectdata:SetOrigin( vOffset )
		effectdata:SetNormal( vNormal )
		effectdata:SetRadius( 1 )
		effectdata:SetScale( 1 )
	util.Effect( "cball_explode", effectdata )

end

function ENT:EffectDraw_water_small()

	self.RingTimer = self.RingTimer or 0
	if ( self.RingTimer > CurTime() ) then return end
	self.RingTimer = CurTime() + 0.00005

	local vOffset = self.Entity:LocalToWorld( self:GetOffset() )
	local vNormal = (vOffset - self.Entity:GetPos()):GetNormalized()

	local effectdata = EffectData()
		effectdata:SetOrigin( vOffset )
		effectdata:SetNormal( vNormal )
		effectdata:SetRadius( 1 )
		effectdata:SetScale( 1 )
	util.Effect( "watersplash", effectdata )

end

function ENT:EffectDraw_water_medium()

	self.RingTimer = self.RingTimer or 0
	if ( self.RingTimer > CurTime() ) then return end
	self.RingTimer = CurTime() + 0.00005

	local vOffset = self.Entity:LocalToWorld( self:GetOffset() )
	local vNormal = (vOffset - self.Entity:GetPos()):GetNormalized()

	local effectdata = EffectData()
		effectdata:SetOrigin( vOffset )
		effectdata:SetNormal( vNormal )
		effectdata:SetRadius( 5 )
		effectdata:SetScale( 3 )

	util.Effect( "watersplash", effectdata )

end

function ENT:EffectDraw_water_big()

	self.RingTimer = self.RingTimer or 0
	if ( self.RingTimer > CurTime() ) then return end
	self.RingTimer = CurTime() + 0.00005

	local vOffset = self.Entity:LocalToWorld( self:GetOffset() )
	local vNormal = (vOffset - self.Entity:GetPos()):GetNormalized()

	local effectdata = EffectData()
		effectdata:SetOrigin( vOffset )
		effectdata:SetNormal( vNormal )
		effectdata:SetRadius( 10 )
		effectdata:SetScale( 6 )
	util.Effect( "watersplash", effectdata )

end

function ENT:EffectDraw_water_huge()

	self.RingTimer = self.RingTimer or 0
	if ( self.RingTimer > CurTime() ) then return end
	self.RingTimer = CurTime() + 0.00005

	local vOffset = self.Entity:LocalToWorld( self:GetOffset() )
	local vNormal = (vOffset - self.Entity:GetPos()):GetNormalized()

	local effectdata = EffectData()
		effectdata:SetOrigin( vOffset )
		effectdata:SetNormal( vNormal )
		effectdata:SetRadius( 50 )
		effectdata:SetScale( 50 )
	util.Effect( "watersplash", effectdata )

end


function ENT:EffectDraw_striderblood_small()

	self.RingTimer = self.RingTimer or 0
	if ( self.RingTimer > CurTime() ) then return end
	self.RingTimer = CurTime() + 0.00005

	local vOffset = self.Entity:LocalToWorld( self:GetOffset() )
	local vNormal = (vOffset - self.Entity:GetPos()):GetNormalized()

	local effectdata = EffectData()
		effectdata:SetOrigin( vOffset )
		effectdata:SetNormal( vNormal )
		effectdata:SetRadius( 1 )
		effectdata:SetScale( 1 )
	util.Effect( "StriderBlood", effectdata )

end

function ENT:EffectDraw_striderblood_medium()

	self.RingTimer = self.RingTimer or 0
	if ( self.RingTimer > CurTime() ) then return end
	self.RingTimer = CurTime() + 0.00005

	local vOffset = self.Entity:LocalToWorld( self:GetOffset() )
	local vNormal = (vOffset - self.Entity:GetPos()):GetNormalized()

	local effectdata = EffectData()
		effectdata:SetOrigin( vOffset )
		effectdata:SetNormal( vNormal )
		effectdata:SetRadius( 2 )
		effectdata:SetScale( 2 )

	util.Effect( "StriderBlood", effectdata )

end

function ENT:EffectDraw_striderblood_big()

	self.RingTimer = self.RingTimer or 0
	if ( self.RingTimer > CurTime() ) then return end
	self.RingTimer = CurTime() + 0.00005

	local vOffset = self.Entity:LocalToWorld( self:GetOffset() )
	local vNormal = (vOffset - self.Entity:GetPos()):GetNormalized()

	local effectdata = EffectData()
		effectdata:SetOrigin( vOffset )
		effectdata:SetNormal( vNormal )
		effectdata:SetRadius( 3 )
		effectdata:SetScale( 3 )
	util.Effect( "StriderBlood", effectdata )

end

function ENT:EffectDraw_striderblood_huge()

	self.RingTimer = self.RingTimer or 0
	if ( self.RingTimer > CurTime() ) then return end
	self.RingTimer = CurTime() + 0.00005

	local vOffset = self.Entity:LocalToWorld( self:GetOffset() )
	local vNormal = (vOffset - self.Entity:GetPos()):GetNormalized()

	local effectdata = EffectData()
		effectdata:SetOrigin( vOffset )
		effectdata:SetNormal( vNormal )
		effectdata:SetRadius( 4)
		effectdata:SetScale( 4 )
	util.Effect( "StriderBlood", effectdata )

end

function ENT:EffectDraw_rings_grow()

	self.RingTimer = self.RingTimer or 0
	if ( self.RingTimer > CurTime() ) then return end
	self.RingTimer = CurTime() + 0.00005

	local vOffset = self.Entity:LocalToWorld( self:GetOffset() )
	local vNormal = (vOffset - self.Entity:GetPos()):GetNormalized()

	local effectdata = EffectData()
		effectdata:SetOrigin( vOffset )
		effectdata:SetNormal( vNormal )
	util.Effect( "thruster_ring_grow", effectdata )

end

function ENT:EffectDraw_rings_grow_rings()

	self.RingTimer = self.RingTimer or 0
	if ( self.RingTimer > CurTime() ) then return end
	self.RingTimer = CurTime() + 0.00005

	local vOffset = self.Entity:LocalToWorld( self:GetOffset() )
	local vNormal = (vOffset - self.Entity:GetPos()):GetNormalized()

	local effectdata = EffectData()
		effectdata:SetOrigin( vOffset )
		effectdata:SetNormal( vNormal )
	util.Effect( "thruster_ring", effectdata )
	util.Effect( "thruster_ring_grow", effectdata )
	util.Effect( "thruster_ring_grow1", effectdata )
	util.Effect( "thruster_ring_grow2", effectdata )
	util.Effect( "thruster_ring_grow3", effectdata )

end


function ENT:EffectDraw_rings_shrink()

	self.RingTimer = self.RingTimer or 0
	if ( self.RingTimer > CurTime() ) then return end
	self.RingTimer = CurTime() + 0.00005

	local vOffset = self.Entity:LocalToWorld( self:GetOffset() )
	local vNormal = (vOffset - self.Entity:GetPos()):GetNormalized()

	local effectdata = EffectData()
		effectdata:SetOrigin( vOffset )
		effectdata:SetNormal( vNormal )
	util.Effect( "thruster_ring_shrink", effectdata )

end


function ENT:EffectThink_bubble()
	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end

	self.SmokeTimer = CurTime() + 0.005

	local vOffset = self.Entity:LocalToWorld( self:GetOffset() )
	local vNormal = (vOffset - self.Entity:GetPos()):GetNormalized()
	vOffset = vOffset + VectorRand() * 5


	local emitter = ParticleEmitter( vOffset )

	local particle = emitter:Add( "effects/bubble", vOffset )
	vNormal.x = vNormal.x * 0.7
	vNormal.y = vNormal.y * 0.7
	vNormal.z = (vNormal.z+1) * 20
	particle:SetVelocity( vNormal)
	particle:SetDieTime( 2 )
	particle:SetStartAlpha( 125 )
	particle:SetEndAlpha( 125 )
	particle:SetColor(255,255,255)
	particle:SetStartSize( 7 )
	particle:SetEndSize( 0 )
	particle:SetRoll( 0 )

	emitter:Finish()
end
