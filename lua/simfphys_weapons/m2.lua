local m1a1_susdata = {}
for i = 1,6 do
	m1a1_susdata[i] = {
		attachment = "sus_left_attach_" .. i,
		poseparameter = "suspension_left_" .. i,
	}

	local ir = i + 6

	m1a1_susdata[ir] = {
		attachment = "sus_right_attach_" .. i,
		poseparameter = "suspension_right_" .. i,
	}
end
simfphys.weapon.M2Clipsize = 50
local function cannon_fire(ply,vehicle,shootOrigin,shootDirection)
	vehicle:EmitSound("apc_fire", 140)
  	--sound.Play( Sound( DeflectSounds[ "simulated_vehicles/weapons/apc_fire.wav", Vehicle:GetPos(), 140)


	vehicle:GetPhysicsObject():ApplyForceOffset( -shootDirection * 100000, shootOrigin )

	local projectile = {}
		projectile.filter = vehicle.VehicleData["filter"]
		projectile.shootOrigin = shootOrigin - (shootDirection * 100)
		projectile.shootDirection = shootDirection + (VectorRand() * 0.003)
		projectile.attacker = ply
		projectile.attackingent = vehicle
		projectile.Damage = 250
		projectile.Force = 50
		projectile.Size = 2
		projectile.BlastRadius = 150
		projectile.BlastDamage = 100
		projectile.BlastEffect = "simfphys_tankweapon_explosion_micro"

	simfphys.FirePhysProjectile( projectile )
end

local function atgm_fire(ply,vehicle,shootOrigin,shootDirection)
	vehicle:EmitSound("weapons/stinger_fire1.wav", 125)
	vehicle:EmitSound("tiger_reload")

	--vehicle:GetPhysicsObject():ApplyForceOffset( -shootDirection * 100000, shootOrigin )

	vehicle.missile = ents.Create( "ent_jack_gmod_ezheatmissile" )
	vehicle.missile:SetPos( Vector(shootOrigin.x, shootOrigin.y, vehicle:GetPos().z) + vehicle:GetUp() * 110 )
  	local ang = shootDirection:Angle()
	vehicle.missile:SetAngles(Angle(0, ang.y, ang.r))
	vehicle.missile:SetOwner( ply )
	vehicle.missile:Spawn()
	vehicle.missile:Activate()
  	vehicle.missile:SetState(1)
  	vehicle.missile:Launch()
  	vehicle.missile.AimAt = function()
    	if vehicle == nil || vehicle == NULL then return false end
    	local Attachment = vehicle:GetAttachment(vehicle:LookupAttachment( "muzzle_cannon" ))
        local tr = util.TraceLine( {
            start = Attachment.Pos,
            endpos = Attachment.Pos + -Attachment.Ang:Up() * 100000,
            filter = {vehicle}
        } )
        return tr.HitPos
   	end
end

function simfphys.weapon:ValidClasses()
	return { "m2_bredley" }
end

function simfphys.weapon:Initialize( vehicle )
	net.Start( "avx_ins1_register_tank" )
		net.WriteEntity( vehicle )
		net.WriteString( "bredley" )
	net.Broadcast()

	simfphys.RegisterCrosshair( vehicle:GetDriverSeat(), { Attachment = "muzzle_cannon", Direction = Vector(0, 0, -1), Type = 4 } )
	simfphys.RegisterCamera( vehicle:GetDriverSeat(), Vector(0,-20,75), Vector(0,0,110), true, "muzzle_cannon" )
	
	simfphys.RegisterCamera( vehicle.pSeat[1], Vector(0,60,80), Vector(0,60,80),  true)
	simfphys.RegisterCamera( vehicle.pSeat[2], Vector(0,60,80), Vector(0,60,80),  true)
	simfphys.RegisterCamera( vehicle.pSeat[3], Vector(0,60,80), Vector(0,60,80),  true)
	simfphys.RegisterCamera( vehicle.pSeat[4], Vector(0,60,80), Vector(0,60,80),  true)
	simfphys.RegisterCamera( vehicle.pSeat[5], Vector(0,60,80), Vector(0,60,80),  true)
	simfphys.RegisterCamera( vehicle.pSeat[6], Vector(0,60,80), Vector(0,60,80),  true)
	simfphys.RegisterCamera( vehicle.pSeat[7], Vector(0,60,80), Vector(0,60,80),  true)

	vehicle:SetPoseParameter("cannon_aim_pitch", 75 )
	
	---звук поворота башни
	vehicle.TurretHorizontal = CreateSound(vehicle,"turret1/cannon_turn_loop_1.wav")
	vehicle.TurretHorizontal:SetSoundLevel(100)
	vehicle.TurretHorizontal:Play()
	vehicle:CallOnRemove("stopmgsounds",function(vehicle)
		vehicle.TurretHorizontal:Stop()		
	end)
	---

	timer.Simple( 1, function()
		if not IsValid( vehicle ) then return end
		if not vehicle.VehicleData["filter"] then print("[simfphys Armed Vehicle Pack] ERROR:TRACE FILTER IS INVALID. PLEASE UPDATE SIMFPHYS BASE") return end

		vehicle.WheelOnGround = function( ent )
			ent.FrontWheelPowered = ent:GetPowerDistribution() ~= 1
			ent.RearWheelPowered = ent:GetPowerDistribution() ~= -1

			for i = 1, table.Count( ent.Wheels ) do
				local Wheel = ent.Wheels[i]
				if IsValid( Wheel ) then
					local dmgMul = Wheel:GetDamaged() and 0.5 or 1
					local surfacemul = simfphys.TractionData[Wheel:GetSurfaceMaterial():lower()]

					ent.VehicleData[ "SurfaceMul_" .. i ] = (surfacemul and math.max(surfacemul,0.001) or 1) * dmgMul

					local WheelPos = ent:LogicWheelPos( i )

					local WheelRadius = WheelPos.IsFrontWheel and ent.FrontWheelRadius or ent.RearWheelRadius
					local startpos = Wheel:GetPos()
					local dir = -ent.Up
					local len = WheelRadius + math.Clamp(-ent.Vel.z / 50,2.5,6)
					local HullSize = Vector(WheelRadius,WheelRadius,0)
					local tr = util.TraceHull( {
						start = startpos,
						endpos = startpos + dir * len,
						maxs = HullSize,
						mins = -HullSize,
						filter = ent.VehicleData["filter"]
					} )

					local onground = self:IsOnGround( vehicle ) and 1 or 0
					Wheel:SetOnGround( onground )
					ent.VehicleData[ "onGround_" .. i ] = onground

					if tr.Hit then
						Wheel:SetSpeed( Wheel.FX )
						Wheel:SetSkidSound( Wheel.skid )
						Wheel:SetSurfaceMaterial( util.GetSurfacePropName( tr.SurfaceProps ) )
					end
				end
			end

			local FrontOnGround = math.max(ent.VehicleData[ "onGround_1" ],ent.VehicleData[ "onGround_2" ])
			local RearOnGround = math.max(ent.VehicleData[ "onGround_3" ],ent.VehicleData[ "onGround_4" ])

			ent.DriveWheelsOnGround = math.max(ent.FrontWheelPowered and FrontOnGround or 0,ent.RearWheelPowered and RearOnGround or 0)
		end
	end)
end

function simfphys.weapon:GetForwardSpeed( vehicle )
	return vehicle.ForwardSpeed
end

function simfphys.weapon:IsOnGround( vehicle )
	return vehicle.susOnGround == true
end

function simfphys.weapon:AimCannon( ply, vehicle, pod, Attachment )
	if not IsValid( pod ) then return end

	local Aimang = pod:WorldToLocalAngles( ply:EyeAngles() )
	Aimang:Normalize()

	local AimRate = 50

	local Angles = vehicle:WorldToLocalAngles( Aimang )
	
	---звуки
	local v = math.abs((math.Round(Angles.y,1) - (vehicle.sm_pp_yaw and math.Round(vehicle.sm_pp_yaw,1) or 0)))
	vehicle.VAL_TurretHorizontal = (v <= 0.5 or (v >= 359.7 and v <= 360)) and 0 or 1	
	local ft = FrameTime()
	vehicle.sm_pp_yaw = vehicle.sm_pp_yaw and math.ApproachAngle( vehicle.sm_pp_yaw, Angles.y, AimRate * FrameTime() ) or 180
	vehicle.sm_pp_pitch = vehicle.sm_pp_pitch and math.ApproachAngle( vehicle.sm_pp_pitch, -Angles.p, AimRate * FrameTime() ) or 0

	local TargetAng = Angle(vehicle.sm_pp_pitch,vehicle.sm_pp_yaw,0)
	TargetAng:Normalize()

	vehicle:SetPoseParameter("turret_yaw", TargetAng.y )
	vehicle:SetPoseParameter("cannon_aim_yaw", TargetAng.y )
	vehicle:SetPoseParameter("cannon_aim_pitch", -TargetAng.p + 70 )
end

function simfphys.weapon:ControlTurret( vehicle, deltapos )
	if not istable( vehicle.PassengerSeats ) or not istable( vehicle.pSeat ) then return end
	
	---звуки башни
	vehicle.VAL_TurretHorizontal = vehicle.VAL_TurretHorizontal or 0
	vehicle.TurretHorizontal:ChangePitch(vehicle.VAL_TurretHorizontal*100,0.1)
	vehicle.TurretHorizontal:ChangeVolume(vehicle.VAL_TurretHorizontal,0.1)
	
	vehicle.VAL_TurretHorizontal = 0
	---
	local pod = vehicle:GetDriverSeat()

	if not IsValid( pod ) then return end

	local ply = pod:GetDriver()

	if not IsValid( ply ) then return end

	local ID = vehicle:LookupAttachment( "muzzle_cannon" )
	local Attachment = vehicle:GetAttachment( ID )

	self:AimCannon( ply, vehicle, pod, Attachment )

	local DeltaP = deltapos * engine.TickInterval()

	local fire = ply:KeyDown( IN_ATTACK )
	local fire2 = ply:KeyDown( IN_ATTACK2 )

	if fire then
		self:PrimaryAttack( vehicle, ply, Attachment.Pos + DeltaP, Attachment )
	end

	local ID2 = vehicle:LookupAttachment( "muzzle_missile" )
	local Attachment2 = vehicle:GetAttachment( ID2 )

	if fire2 then
		self:SecondaryAttack( vehicle, ply, Attachment2.Pos + DeltaP, Attachment2 )
	end
end

function simfphys.weapon:CanAttack( vehicle )
	vehicle.NextShoot3 = vehicle.NextShoot3 or 0
	return vehicle.NextShoot3 < CurTime()
end

function simfphys.weapon:SetNextFire( vehicle, time )
	vehicle.NextShoot3 = time
end

function simfphys.weapon:CanAttackNSVT( vehicle )
	vehicle.NextShoot4 = vehicle.NextShoot4 or 0
	return vehicle.NextShoot4 < CurTime()
end

function simfphys.weapon:SetNextNSVTFire( vehicle, time )
	vehicle.NextShoot4 = time
end

function simfphys.weapon:PrimaryAttack( vehicle, ply, shootOrigin, Attachment )
	if not self:CanPrimaryAttack( vehicle ) then return end
	
		self.M2Clip = self.M2Clip or self.M2Clipsize
	
	if not self:CanAttack( vehicle ) then return end
	
	if self.M2Clip <= 0 then
		self.M2Clip = self.M2Clipsize
		vehicle:EmitSound("t90ms_reload", 75, 75)
		self:SetNextFire( vehicle, CurTime() + 6 )
		return
	end

	self.M2Clip = self.M2Clip - 1

	local shootDirection = -Attachment.Ang:Up()

	cannon_fire( ply, vehicle, shootOrigin + shootDirection * 80, shootDirection )

	local effectdata = EffectData()
		effectdata:SetEntity( vehicle )
	util.Effect( "arctic_m2_muzzle", effectdata, true, true )

	self:SetNextPrimaryFire( vehicle, CurTime() + 0.3 )
end

function simfphys.weapon:SecondaryAttack( vehicle, ply, shootOrigin, Attachment )
	if not self:CanSecondaryAttack( vehicle ) then return end

	local shootDirection = -Attachment.Ang:Right()

	atgm_fire( ply, vehicle, shootOrigin + shootDirection * 80, shootDirection )

	self:SetNextSecondaryFire( vehicle, CurTime() + 5 )
end

function simfphys.weapon:CanPrimaryAttack( vehicle )
	vehicle.NextShoot = vehicle.NextShoot or 0
	return vehicle.NextShoot < CurTime()
end

function simfphys.weapon:SetNextPrimaryFire( vehicle, time )
	vehicle.NextShoot = time
end

function simfphys.weapon:CanSecondaryAttack( vehicle )
	vehicle.NextShoot2 = vehicle.NextShoot2 or 0
	return vehicle.NextShoot2 < CurTime()
end

function simfphys.weapon:SetNextSecondaryFire( vehicle, time )
	vehicle.NextShoot2 = time
end

function simfphys.weapon:ModPhysics( vehicle, wheelslocked )
	if wheelslocked and self:IsOnGround( vehicle ) then
		local phys = vehicle:GetPhysicsObject()
		phys:ApplyForceCenter( -vehicle:GetVelocity() * phys:GetMass() * 0.04 )
	end
end

function simfphys.weapon:ControlTrackSounds( vehicle, wheelslocked )
	local speed = math.abs( self:GetForwardSpeed( vehicle ) )
	local fastenuf = speed > 20 and not wheelslocked and self:IsOnGround( vehicle )

	if fastenuf ~= vehicle.fastenuf then
		vehicle.fastenuf = fastenuf

		if fastenuf then
			vehicle.track_snd = CreateSound( vehicle, "simulated_vehicles/sherman/sherman_tracks.wav" )
			vehicle.track_snd:PlayEx(0,0)
			vehicle:CallOnRemove( "stopmesounds", function( veh )
				if veh.track_snd then
					veh.track_snd:Stop()
				end
			end)
		else
			if vehicle.track_snd then
				vehicle.track_snd:Stop()
				vehicle.track_snd = nil
			end
		end
	end

	if vehicle.track_snd then
		vehicle.track_snd:ChangePitch( math.Clamp(60 + speed / 40,0,150) )
		vehicle.track_snd:ChangeVolume( math.min( math.max(speed - 20,0) / 200,1) )
	end
end

function simfphys.weapon:Think( vehicle )
	if not IsValid( vehicle ) or not vehicle:IsInitialized() then return end

	vehicle.wOldPos = vehicle.wOldPos or Vector(0,0,0)
	local deltapos = vehicle:GetPos() - vehicle.wOldPos
	vehicle.wOldPos = vehicle:GetPos()

	local handbrake = vehicle:GetHandBrakeEnabled()

	self:UpdateSuspension( vehicle )
	self:DoWheelSpin( vehicle )
	self:ControlTurret( vehicle, deltapos )
	self:ControlTrackSounds( vehicle, handbrake )
	self:ModPhysics( vehicle, handbrake )

	--[[local ID = vehicle:LookupAttachment( "muzzle_cannon" )
	local Attachment = vehicle:GetAttachment( ID )

	local filter = table.Copy(vehicle.MissileTracking or {})
	table.Add(filter, {vehicle})

	local tr = util.TraceLine( {
		start = Attachment.Pos,
		endpos = Attachment.Pos + -Attachment.Ang:Up() * 100000,
		filter = filter
	} )
	local Aimpos = tr.HitPos

	local remove = {}
	for i, missile in pairs(vehicle.MissileTracking or {}) do
		if IsValid( missile ) then
			local targetdir = Aimpos - missile:GetPos()
			targetdir:Normalize()
			missile.DirVector = missile.DirVector + (targetdir - missile.DirVector) * 0.1

			local vel = -missile:GetVelocity() + missile.DirVector * 2500

			local phys = missile:GetPhysicsObject()

			phys:SetVelocity( vel )
			missile:SetAngles( missile.DirVector:Angle() )
		else
			table.insert(remove, i)
		end
	end

	for k, i in pairs(remove) do
		table.remove(vehicle.MissileTracking, i)
	end]]
local trackss
	local speed = vehicle:GetVelocity():Length()
    local mass = vehicle:GetPhysicsObject():GetMass()
    local TrackTurnRate = 20
    local TrackMultRate = 250
    local AntiFrictionRate = 0.1
	if vehicle:EngineActive() and speed < 200 and vehicle.PressedKeys["A"] and !vehicle.PressedKeys["S"] and vehicle.susOnGround == true then
        if vehicle:GetPhysicsObject():GetAngleVelocity().z <= TrackTurnRate then
            vehicle:GetPhysicsObject():ApplyTorqueCenter( Vector(0,0, mass * TrackMultRate ))
            vehicle:GetPhysicsObject():ApplyForceCenter( Vector( 0,0, mass * AntiFrictionRate ))
        end
    end
    if vehicle:EngineActive() and speed < 200 and vehicle.PressedKeys["D"] and !vehicle.PressedKeys["S"] and vehicle.susOnGround == true then
        if math.abs(vehicle:GetPhysicsObject():GetAngleVelocity().z) <= TrackTurnRate then
            vehicle:GetPhysicsObject():ApplyTorqueCenter( Vector(0,0, -mass * TrackMultRate  ))
            vehicle:GetPhysicsObject():ApplyForceCenter( Vector( 0,0, mass * AntiFrictionRate ))
        end
	end	
	
end

function simfphys.weapon:UpdateSuspension( vehicle )
	if not vehicle.filterEntities then
		vehicle.filterEntities = player.GetAll()
		table.insert(vehicle.filterEntities, vehicle)

		for i, wheel in pairs( ents.FindByClass( "gmod_sent_vehicle_fphysics_wheel" ) ) do
			table.insert(vehicle.filterEntities, wheel)
		end
	end

	vehicle.oldDist = istable( vehicle.oldDist ) and vehicle.oldDist or {}

	vehicle.susOnGround = false
	local Up = vehicle:GetUp()

	for i, v in pairs( m1a1_susdata ) do
		local pos = vehicle:GetAttachment( vehicle:LookupAttachment( m1a1_susdata[i].attachment ) ).Pos + Up * 10

		local trace = util.TraceHull( {
			start = pos,
			endpos = pos + Up * - 100,
			maxs = Vector(10,10,0),
			mins = -Vector(10,10,0),
			filter = vehicle.filterEntities,
		} )
		local Dist = (pos - trace.HitPos):Length() - 50

		if trace.Hit then
			vehicle.susOnGround = true
		end

		vehicle.oldDist[i] = vehicle.oldDist[i] and (vehicle.oldDist[i] + math.Clamp(Dist - vehicle.oldDist[i],-5,1)) or 0

		vehicle:SetPoseParameter(m1a1_susdata[i].poseparameter, vehicle.oldDist[i] )
	end
end

function simfphys.weapon:DoWheelSpin( vehicle )
	local spin_r = (vehicle.VehicleData[ "spin_4" ] + vehicle.VehicleData[ "spin_6" ]) * -1.25
	local spin_l = (vehicle.VehicleData[ "spin_3" ] + vehicle.VehicleData[ "spin_5" ]) * -1.25

	net.Start( "simfphys_update_tracks", true )
		net.WriteEntity( vehicle )
		net.WriteFloat( spin_r )
		net.WriteFloat( spin_l )
	net.Broadcast()

	vehicle:SetPoseParameter("spin_wheels_right", spin_r)
	vehicle:SetPoseParameter("spin_wheels_left", spin_l )
end