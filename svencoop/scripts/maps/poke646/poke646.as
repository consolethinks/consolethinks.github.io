// Poke646 Script
// Main Script
// Author: Zorbos

#include "ammo_nailclip"
#include "ammo_nailround"
#include "weapon_bradnailer"
#include "weapon_cmlwbr"
#include "weapon_heaterpipe"
#include "weapon_nailgun"
#include "weapon_sawedoff"
#include "point_checkpoint"

void MapInit()
{ 
	// Survival checkpoint
	POKECHECKPOINT::RegisterPointCheckPointEntity();

	// Register weapons
	RegisterBradnailer();
	RegisterNailgun();
	RegisterSawedOff();
	RegisterHeaterpipe();
	RegisterCmlwbr();

	// Register ammo entities
	g_CustomEntityFuncs.RegisterCustomEntity( "ammo_nailclip", "ammo_nailclip" );
	g_CustomEntityFuncs.RegisterCustomEntity( "ammo_nailround", "ammo_nailround" );
}