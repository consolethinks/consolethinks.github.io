// Poke646: Vendetta Script
// Main Script
// Author: Zorbos

#include "ammo_par21_clip"
#include "ammo_par21_grenades"
#include "weapon_cmlwbr"
#include "weapon_leadpipe"
#include "weapon_par21"
#include "weapon_sawedoff"
#include "../poke646/point_checkpoint"

void MapInit()
{
	// Survival checkpoint
	POKECHECKPOINT::RegisterPointCheckPointEntity();

	// Register weapons
	RegisterPAR21();
	RegisterSawedOff();
	RegisterLeadpipe();
	RegisterCmlwbr();
	
	// Register ammo entities
	g_CustomEntityFuncs.RegisterCustomEntity( "ammo_par21_clip", "ammo_par21_clip" );
	g_CustomEntityFuncs.RegisterCustomEntity( "ammo_par21_grenades", "ammo_par21_grenades" );
}