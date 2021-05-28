simfphys = istable( simfphys ) and simfphys or {}

simfphys.ManagedVehicles = istable( simfphys.ManagedVehicles ) and simfphys.ManagedVehicles or {}
simfphys.Weapons = istable( simfphys.Weapons ) and simfphys.Weapons or {}
simfphys.weapon = {}

util.AddNetworkString( "avx_ins1_register_tank" )
util.AddNetworkString( "m2_do_effect" )

sound.Add( {
	name = "m2_reload",
	channel = CHAN_STATIC,
	volume = 1.0,
	level = 70,
	pitch = { 90, 110 },
	sound = "pz2/reload_cannon_20mm_1.wav"
} )

sound.Add( {
	name = "m2_fire",
	channel = CHAN_STATIC,
	volume = 1.0,
	level = 140,
	pitch = { 90, 110 },
	sound = "p20mm.wav"
} )