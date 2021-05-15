Vector vecCamColor(240,180,0);
int iCamBrightness = 64;
	
__________________________________________________
//______________________________________________________________
//______________________________________________________________
//_____STORMTROOPERBLASTERSHOOT_________________________________

class CBlasterNpc : ScriptBaseEntity
{
	bool keepRepeatingLight = true;
	float m_yawCenter;
	float m_pitchCenter;
	float ATTN_LOW_HIGH = 0.25f;
	int m_iExplode, m_iSpriteTexture, m_iSpriteTexture2, m_iGlow, m_iSmoke, m_iTrail, m_blasterBolt, m_blasterImpact;
	CBeam@	m_pBeam;
	
	void Spawn()
	{
		Precache();
		self.pev.movetype = MOVETYPE_FLY;
		self.pev.solid = SOLID_BBOX;
		g_EntityFuncs.SetModel( self, E11_MODEL_PROJECTILE );
		self.pev.body = 1;
		m_yawCenter = pev.angles.y;
		m_pitchCenter = pev.angles.x;
		g_EntityFuncs.SetSize( self.pev, g_vecZero, g_vecZero );
		
	}
	
	void Precache()
	{
		m_iExplode = g_Game.PrecacheModel( "sprites/portalhouse/expB1.spr" );
		m_iSpriteTexture = g_Game.PrecacheModel( "sprites/white.spr" );
		m_iSpriteTexture2 = g_Game.PrecacheModel( "sprites/spray.spr" );
		m_iGlow = g_Game.PrecacheModel( "sprites/redflare1.spr" );
		m_iSmoke = g_Game.PrecacheModel( "sprites/steam1.spr" );
		m_iTrail = g_Game.PrecacheModel( "sprites/smoke.spr" );
		m_blasterBolt = g_Game.PrecacheModel( "sprites/portalhouse/plasma.spr" );
		m_blasterImpact = g_Game.PrecacheModel( "sprites/portalhouse/blasterimpact.spr" );
		
	}
	
	void BlasterLight()
	{
		
		g_EntityFuncs.Remove( m_pBeam );
		@m_pBeam = null;
		
		Math.MakeAimVectors( pev.angles );
		@m_pBeam = g_EntityFuncs.CreateBeam( "sprites/portalhouse/plasma.spr", 25 );
		m_pBeam.SetStartPos( self.pev.origin + g_Engine.v_forward * 10 );
		m_pBeam.SetEndPos( self.pev.origin - g_Engine.v_forward * 90 );
		m_pBeam.SetColor( 255, 255, 179 );
		m_pBeam.SetScrollRate( 0 );
		m_pBeam.SetBrightness( 255 );
		m_pBeam.pev.velocity = self.pev.velocity;
		
		if (keepRepeatingLight){
		SetThink( ThinkFunction( this.BlasterLight ) );
		self.pev.nextthink = g_Engine.time + 0.0;
		}
	}

	void ExplodeTouch( CBaseEntity@ pOther )
	{
	
		entvars_t@ pevOwner = self.pev.owner.vars;

		if( g_EngineFuncs.PointContents( self.pev.origin ) == CONTENTS_SKY )
		{
			g_EntityFuncs.Remove( self );
			return;
		}

		TraceResult tr;
		Vector vecSpot = self.pev.origin - self.pev.velocity.Normalize() * 32;
		Vector vecEnd = self.pev.origin + self.pev.velocity.Normalize() * 64;
		g_Utility.TraceLine( vecSpot, vecEnd, ignore_monsters, self.edict(), tr );

		Explode( pOther, tr, DMG_ENERGYBEAM );
		
		ProjectileDynamicLight( self.pev.origin, 8, 255, 0, 0, 1, 150 );
		g_Utility.DecalTrace( tr, DECAL_SMALLSCORCH1 );
		
		if( pOther.pev.takedamage == 1 )
		{
			g_WeaponFuncs.ClearMultiDamage();
			pOther.TraceAttack( pevOwner, self.pev.dmg/8, g_Engine.v_forward , tr, DMG_BULLET ); 
			g_WeaponFuncs.ApplyMultiDamage( self.pev, pevOwner);
		}
		
		
	}

	void Explode( CBaseEntity@ pOther, TraceResult pTrace, int bitsDamageType )
	{
		entvars_t@ pevOwner = self.pev.owner.vars;
		
		int damaged = pOther.TakeDamage(self.pev, pevOwner, self.pev.dmg, DMG_ENERGYBEAM );
		g_WeaponFuncs.RadiusDamage( self.pev.origin, self.pev, pevOwner, self.pev.dmg/4, self.pev.dmg/2, CLASS_PLAYER, DMG_ENERGYBEAM);
		
		ProjectileEffect( self.pev.origin );
		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, E11_SOUND_EXPLODE, 0.2, ATTN_LOW_HIGH, 0, PITCH_NORM );

		keepRepeatingLight = false;
		self.pev.velocity = g_vecZero;
		SetTouch( null );
		
		g_EntityFuncs.Remove( m_pBeam );
		g_EntityFuncs.Remove( self );
	}
	
	void Killed( entvars_t@ pevAttacker, int iGib )
	{
		entvars_t@ pevOwner = self.pev.owner.vars;
		if( pevOwner.ClassNameIs("player") )
		{
			g_EngineFuncs.SetView( self.pev.owner, self.pev.owner );
		}
		g_EntityFuncs.Remove( m_pBeam );
		g_EntityFuncs.Remove( self );
	}
	
	void UpdateOnRemove(){
		g_EntityFuncs.Remove( m_pBeam );
	}
	
void te_sprite(Vector pos, string sprite="sprites/portalhouse/blasterimpact.spr", 
	uint8 scale=1, uint8 alpha=50, 
	NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
{
	NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
	m.WriteByte(TE_SPRITE);
	m.WriteCoord(pos.x);
	m.WriteCoord(pos.y);
	m.WriteCoord(pos.z);
	m.WriteShort(g_EngineFuncs.ModelIndex(sprite));
	m.WriteByte(scale);
	m.WriteByte(alpha);
	m.End();
}
	
void te_sparks(Vector pos, 
    NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
{
    NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
    m.WriteByte(TE_SPARKS);
    m.WriteCoord(pos.x);
    m.WriteCoord(pos.y);
    m.WriteCoord(pos.z);
    m.End();
}

void te_ricochet(Vector pos, uint8 scale=10, 
    NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
{
    NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
    m.WriteByte(TE_ARMOR_RICOCHET);
    m.WriteCoord(pos.x);
    m.WriteCoord(pos.y);
    m.WriteCoord(pos.z);
    m.WriteByte(scale);
    m.End();
}

	void ProjectileEffect( Vector origin )
	{
		int fireballScale = 3;
		int fireballBrightness = 255;
		int smokeScale = 7;
		int discLife = 12;
		int discWidth = 64;
		int discR = 255;
		int discG = 255;
		int discB = 255;
		int glowR = 255;
		int glowG = 255;
		int glowB = 255;
		int discBrightness = 128;
		int glowLife = 1;
		int glowScale = 15;
		int glowBrightness = 100;
		
		te_sparks(origin);
		te_sprite(origin);

		// Big Plume of Smoke
		NetworkMessage projectilexp2( MSG_PVS, NetworkMessages::SVC_TEMPENTITY );
			projectilexp2.WriteByte( TE_SMOKE );
			projectilexp2.WriteCoord( origin.x );
			projectilexp2.WriteCoord( origin.y );
			projectilexp2.WriteCoord( origin.z );
			projectilexp2.WriteShort( m_iSmoke );
			projectilexp2.WriteByte( int(smokeScale) );
			projectilexp2.WriteByte( 24 ); //framrate
		projectilexp2.End();
		
	}
	
}


//__________________
//__________________
//__________________

CBlaster@ ShootBlaster( entvars_t@ pevOwner, Vector vecStart, Vector vecVelocity )
{
	CBaseEntity@ cbeProjectile = g_EntityFuncs.CreateEntity( "blaster", null,  false);
	CBlaster@ pProjectile = cast<CBlaster@>(CastToScriptClass(cbeProjectile));
	g_EntityFuncs.DispatchSpawn( pProjectile.self.edict() );
	g_EntityFuncs.SetOrigin( pProjectile.self, vecStart );
	
	pProjectile.pev.velocity = vecVelocity;
	pProjectile.pev.angles = Math.VecToAngles( pProjectile.pev.velocity );
	@pProjectile.pev.owner = pevOwner.pContainingEntity;
	pProjectile.SetTouch( TouchFunction( pProjectile.ExplodeTouch ) );
	pProjectile.pev.dmg = E11_DAMAGE;
	ProjectileDynamicLight( pProjectile.pev.origin, 6, 255, 0, 0, 5, 50 );
	
	//Effecto aditivo.
	pProjectile.pev.rendermode 	= kRenderTransAdd;
	pProjectile.pev.renderfx 		= kRenderFxNone;
	pProjectile.pev.renderamt 	= 0;
	pProjectile.pev.rendercolor 	= Vector( 0, 0, 0 );
	
	pProjectile.SetThink( ThinkFunction( pProjectile.BlasterLight ) );
	pProjectile.pev.nextthink = g_Engine.time + 0.02;
		
	return pProjectile;
}

CBlaster@ ShootBlasterPistol( entvars_t@ pevOwner, Vector vecStart, Vector vecVelocity )
{
	CBaseEntity@ cbeProjectile = g_EntityFuncs.CreateEntity( "blaster", null,  false);
	CBlaster@ pProjectile = cast<CBlaster@>(CastToScriptClass(cbeProjectile));
	g_EntityFuncs.DispatchSpawn( pProjectile.self.edict() );
	g_EntityFuncs.SetOrigin( pProjectile.self, vecStart );
	
	pProjectile.pev.velocity = vecVelocity;
	pProjectile.pev.angles = Math.VecToAngles( pProjectile.pev.velocity );
	@pProjectile.pev.owner = pevOwner.pContainingEntity;
	pProjectile.SetTouch( TouchFunction( pProjectile.ExplodeTouch ) );
	pProjectile.pev.dmg = DL44_DAMAGE;
	ProjectileDynamicLight( pProjectile.pev.origin, 6, 255, 0, 0, 5, 50 );
	
	//Effecto aditivo.
	pProjectile.pev.rendermode 	= kRenderTransAdd;
	pProjectile.pev.renderfx 		= kRenderFxNone;
	pProjectile.pev.renderamt 	= 0;
	pProjectile.pev.rendercolor 	= Vector( 0, 0, 0 );
	
	pProjectile.SetThink( ThinkFunction( pProjectile.BlasterLight ) );
	pProjectile.pev.nextthink = g_Engine.time + 0.02;
	
	
	
	return pProjectile;
}

CBlaster@ ShootBlasterAlt( entvars_t@ pevOwner, Vector vecStart, Vector vecVelocity )
{
	CBaseEntity@ cbeProjectile = g_EntityFuncs.CreateEntity( "blaster", null,  false);
	CBlaster@ pProjectile = cast<CBlaster@>(CastToScriptClass(cbeProjectile));
	g_EntityFuncs.DispatchSpawn( pProjectile.self.edict() );
	g_EntityFuncs.SetOrigin( pProjectile.self, vecStart );
	
	pProjectile.pev.velocity = vecVelocity;
	pProjectile.pev.angles = Math.VecToAngles( pProjectile.pev.velocity );
	@pProjectile.pev.owner = pevOwner.pContainingEntity;
	pProjectile.SetTouch( TouchFunction( pProjectile.ExplodeTouch ) );
	pProjectile.pev.dmg = E11_DAMAGE;
	ProjectileDynamicLight( pProjectile.pev.origin, 6, 255, 0, 0, 5, 50 );
	
	//Effecto aditivo.
	pProjectile.pev.rendermode 	= kRenderTransAdd;
	pProjectile.pev.renderfx 		= kRenderFxNone;
	pProjectile.pev.renderamt 	= 0;
	pProjectile.pev.rendercolor 	= Vector( 0, 0, 0 );

	pProjectile.SetThink( ThinkFunction( pProjectile.BlasterLight ) );
	pProjectile.pev.nextthink = g_Engine.time + 0.02;
	
	
	return pProjectile;
}

CHPBlaster@ ShootBlasterCrossbow1( entvars_t@ pevOwner, Vector vecStart, Vector vecVelocity )
{
	CBaseEntity@ cbeProjectile = g_EntityFuncs.CreateEntity( "HPblaster", null,  false);
	CHPBlaster@ pProjectile = cast<CHPBlaster@>(CastToScriptClass(cbeProjectile));
	g_EntityFuncs.DispatchSpawn( pProjectile.self.edict() );
	g_EntityFuncs.SetOrigin( pProjectile.self, vecStart );
	
	pProjectile.pev.velocity = vecVelocity;
	pProjectile.pev.angles = Math.VecToAngles( pProjectile.pev.velocity );
	@pProjectile.pev.owner = pevOwner.pContainingEntity;
	pProjectile.SetTouch( TouchFunction( pProjectile.ExplodeTouch ) );
	pProjectile.pev.dmg = HREPEATER_DAMAGE;
	ProjectileDynamicLight( pProjectile.pev.origin, 6, 255, 0, 0, 5, 50 );
	
	//Effecto aditivo.
	pProjectile.pev.rendermode 	= kRenderTransAdd;
	pProjectile.pev.renderfx 		= kRenderFxNone;
	pProjectile.pev.renderamt 	= 0;
	pProjectile.pev.rendercolor 	= Vector( 0, 0, 0 );
	
	pProjectile.SetThink( ThinkFunction( pProjectile.BlasterLight ) );
	pProjectile.pev.nextthink = g_Engine.time + 0.02;
	
	return pProjectile;
}

CBlaster@ ShootBlasterCrossbow2( entvars_t@ pevOwner, Vector vecStart, Vector vecVelocity )
{
	CBaseEntity@ cbeProjectile = g_EntityFuncs.CreateEntity( "blaster", null,  false);
	CBlaster@ pProjectile = cast<CBlaster@>(CastToScriptClass(cbeProjectile));
	g_EntityFuncs.DispatchSpawn( pProjectile.self.edict() );
	g_EntityFuncs.SetOrigin( pProjectile.self, vecStart );
	
	pProjectile.pev.velocity = vecVelocity;
	pProjectile.pev.angles = Math.VecToAngles( pProjectile.pev.velocity );
	@pProjectile.pev.owner = pevOwner.pContainingEntity;
	pProjectile.SetTouch( TouchFunction( pProjectile.ExplodeTouch ) );
	pProjectile.pev.dmg = BOWCASTER_DAMAGE * 0.3;
	ProjectileDynamicLight( pProjectile.pev.origin, 6, 255, 0, 0, 5, 50 );
	
	//Effecto aditivo.
	pProjectile.pev.rendermode 	= kRenderTransAdd;
	pProjectile.pev.renderfx 		= kRenderFxNone;
	pProjectile.pev.renderamt 	= 0;
	pProjectile.pev.rendercolor 	= Vector( 0, 0, 0 );
	
	pProjectile.SetThink( ThinkFunction( pProjectile.BlasterLight ) );
	pProjectile.pev.nextthink = g_Engine.time + 0.02;
	
	return pProjectile;
}

CCShoot@ ShootCShoot( entvars_t@ pevOwner, Vector vecStart, Vector vecVelocity )
{
	CBaseEntity@ cbeProjectile = g_EntityFuncs.CreateEntity( "flechetteCShoot", null,  false);
	CCShoot@ pProjectile = cast<CCShoot@>(CastToScriptClass(cbeProjectile));
	g_EntityFuncs.DispatchSpawn( pProjectile.self.edict() );
	g_EntityFuncs.SetOrigin( pProjectile.self, vecStart );
	
	pProjectile.pev.velocity = vecVelocity;
	pProjectile.pev.angles = Math.VecToAngles( pProjectile.pev.velocity );
	@pProjectile.pev.owner = pevOwner.pContainingEntity;
	pProjectile.SetTouch( TouchFunction( pProjectile.ExplodeTouch ) );
	pProjectile.pev.dmg = HREPEATER_DAMAGE * 10;
	ProjectileDynamicLight( pProjectile.pev.origin, 16, 100, 100, 255, 5, 50 );

	
	//Effecto aditivo.
	pProjectile.pev.rendermode 	= kRenderTransAdd;
	pProjectile.pev.renderfx 		= kRenderFxNone;
	pProjectile.pev.renderamt 	= 0;
	pProjectile.pev.rendercolor 	= Vector( 0, 0, 0 );
	
	pProjectile.SetThink( ThinkFunction( pProjectile.CShootLight ) );
	pProjectile.pev.nextthink = g_Engine.time + 0.0;
	
	return pProjectile;
}

CHPBlaster@ ShootBlasterT21( entvars_t@ pevOwner, Vector vecStart, Vector vecVelocity )
{
	CBaseEntity@ cbeProjectile = g_EntityFuncs.CreateEntity( "HPblaster", null,  false);
	CHPBlaster@ pProjectile = cast<CHPBlaster@>(CastToScriptClass(cbeProjectile));
	g_EntityFuncs.DispatchSpawn( pProjectile.self.edict() );
	g_EntityFuncs.SetOrigin( pProjectile.self, vecStart );
	
	pProjectile.pev.velocity = vecVelocity;
	pProjectile.pev.angles = Math.VecToAngles( pProjectile.pev.velocity );
	@pProjectile.pev.owner = pevOwner.pContainingEntity;
	pProjectile.SetTouch( TouchFunction( pProjectile.ExplodeTouch ) );
	pProjectile.pev.dmg = T21_DAMAGE;
	ProjectileDynamicLight( pProjectile.pev.origin, 6, 255, 0, 0, 5, 50 );
	
	//Effecto aditivo.
	pProjectile.pev.rendermode 	= kRenderTransAdd;
	pProjectile.pev.renderfx 		= kRenderFxNone;
	pProjectile.pev.renderamt 	= 0;
	pProjectile.pev.rendercolor 	= Vector( 0, 0, 0 );
	
	pProjectile.SetThink( ThinkFunction( pProjectile.BlasterLight ) );
	pProjectile.pev.nextthink = g_Engine.time + 0.02;
	
	return pProjectile;
}

CBlasterNpc@ ShootBlasterNpc( int damageBlaster, entvars_t@ pevOwner, Vector vecStart, Vector vecVelocity )
{
	CBaseEntity@ cbeProjectile = g_EntityFuncs.CreateEntity( "blasterNpc", null,  false);
	CBlasterNpc@ pProjectile = cast<CBlasterNpc@>(CastToScriptClass(cbeProjectile));
	g_EntityFuncs.DispatchSpawn( pProjectile.self.edict() );
	g_EntityFuncs.SetOrigin( pProjectile.self, vecStart );
	
	pProjectile.pev.velocity = vecVelocity;
	pProjectile.pev.angles = Math.VecToAngles( pProjectile.pev.velocity );
	@pProjectile.pev.owner = pevOwner.pContainingEntity;
	pProjectile.SetTouch( TouchFunction( pProjectile.ExplodeTouch ) );
	pProjectile.pev.dmg = damageBlaster;
	ProjectileDynamicLight( pProjectile.pev.origin, 10, 255, 0, 0, 5, 40 );	
	
	//Effecto aditivo.
	pProjectile.pev.rendermode 	= kRenderTransAdd;
	pProjectile.pev.renderfx 		= kRenderFxNone;
	pProjectile.pev.renderamt 	= 0;
	pProjectile.pev.rendercolor 	= Vector( 0, 0, 0 );
	
	pProjectile.SetThink( ThinkFunction( pProjectile.BlasterLight ) );
	pProjectile.pev.nextthink = g_Engine.time + 0.03;
	
	
	
	return pProjectile;
}

void ProjectileDynamicLight( Vector vecPos, int radius, int r, int g, int b, int8 life, int decay )
{
	NetworkMessage ndl( MSG_PVS, NetworkMessages::SVC_TEMPENTITY );
		ndl.WriteByte( TE_DLIGHT );
		ndl.WriteCoord( vecPos.x );
		ndl.WriteCoord( vecPos.y );
		ndl.WriteCoord( vecPos.z );
		ndl.WriteByte( radius );
		ndl.WriteByte( int(r) );
		ndl.WriteByte( int(g) );
		ndl.WriteByte( int(b) );
		ndl.WriteByte( life );
		ndl.WriteByte( decay );
	ndl.End();

}

void RegisterBlasterNpc()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "CBlasterNpc", "blasterNpc" );
}
