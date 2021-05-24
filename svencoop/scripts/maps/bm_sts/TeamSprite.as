/*
*	Adds a team sprite to the given monster
*/
#include "../../Utils"

const string g_szTeamSpritePointer = "TEAMSPRITE";

const string g_szTeamSprite 	= "sprites/sprite_a_1.spr";

const string g_szBlueSprite 	= "sprites/bm_sts/teamblue.spr";
const string g_szRedSprite 		= "sprites/bm_sts/teamred.spr";
const string g_szGreenSprite 	= "sprites/bm_sts/teamgreen.spr";
const string g_szYellowSprite 	= "sprites/bm_sts/teamyell.spr";

const string& GetSpriteForColor( const Vector& in color )
{
	if( color == Vector( 1, 1, 255 ) )
		return g_szBlueSprite;
	else if( color == Vector( 255, 1, 1 ) )
		return g_szRedSprite;
	else if( color == Vector( 14, 248, 7 ) )
		return g_szGreenSprite;
	else if( color == Vector( 251, 171, 4 ) )
		return g_szYellowSprite;
	else
		return g_szTeamSprite;	//Fallback in case the color didn't match any
}

CBaseEntity@ GetTeamSprite( CBaseEntity@ pMonster )
{
	dictionary@ userdata = pMonster.GetUserData();
	
	CBaseEntity@ pSprite;
	
	if( userdata.get( g_szTeamSpritePointer, @pSprite ) )
		return pSprite;
	else
		return null;
}

void SetTeamSprite( CBaseEntity@ pMonster, CSprite@ pSprite )
{
	dictionary@ userdata = pMonster.GetUserData();
	
	userdata.set( g_szTeamSpritePointer, @pSprite );
}

void AddTeamSprite( CBaseMonster@ pSquadMaker, CBaseEntity@ pEntity )
{
	CBaseMonster@ pMonster = cast<CBaseMonster@>( pEntity );
	
	//Monsters only
	if( pMonster is null )
		return;
	
	CSprite@ pSprite = g_EntityFuncs.CreateSprite( GetSpriteForColor( pMonster.pev.rendercolor ), pMonster.pev.origin, true );
	
	const int iAttachmentCount = pMonster.GetAttachmentCount();
	
	pSprite.SetAttachment( pMonster.edict(), iAttachmentCount );
	
	SetTeamSprite( pMonster, pSprite );
	
	//Set sprite properties here
	pSprite.pev.scale = 0.15;
	pSprite.pev.rendermode = 5;
	pSprite.pev.renderamt = 255;
	pSprite.pev.rendercolor = pMonster.pev.rendercolor;
	
	pSprite.TurnOn();
}

void RemoveTeamSprite( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
{
	if( pActivator is null )
		return;
	
	CBaseEntity@ pSprite = GetTeamSprite( pActivator );
	
	if( pSprite !is null )
		g_EntityFuncs.Remove( pSprite );
}

void PrecacheTeamSprite()
{
	g_Game.PrecacheModel( g_szTeamSprite );
	
	g_Game.PrecacheModel( g_szBlueSprite );
	g_Game.PrecacheModel( g_szRedSprite );
	g_Game.PrecacheModel( g_szGreenSprite );
	g_Game.PrecacheModel( g_szYellowSprite );
}
