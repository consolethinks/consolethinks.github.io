#include "../../custom_weapons/weapon_P904"
#include "../../custom_weapons/weapon_vulcan"
#include "../../custom_weapons/weapon_plasma"
//#include "monster_race"

/*array<ItemMapping@> g_ItemMappings =
{
	ItemMapping( "weapon_m16", "weapon_P904" ),
		
	// No las reemplaza, debe hacerse manual desde ripent, agregar HL despues del func_
	// Ejemplo: func_hlhealthcharger. -Giegue
	
	//ItemMapping( "func_healthcharger", GetHLHPChargerName() ),
	//ItemMapping( "func_recharge", GetHLAPChargerName() )
	
}*/

void MapInit()
{
	Registervulcan();
	RegisterP904();
	RegisterA768mmBox();
	Registerplasma();
	RegisterPlasmaProjectile();
	RegisterPlasmaProjectile2();
	RegisterPlasmaCell();
	//RegisterMonsterRace();
	
	g_ClassicMode.EnableMapSupport();
	g_ClassicMode.SetEnabled( true );
}

void MapActivate()
{
	CBaseEntity@ ent = null;
	while( ( @ent = g_EntityFuncs.FindEntityByClassname( ent, "weapon_m16" ) ) !is null )
	{
		g_EntityFuncs.Remove( ent );
	}
	
}
