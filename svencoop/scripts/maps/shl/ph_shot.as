Vector vecCamColor(240,180,0);
int iCamBrightness = 64;
	
class CBlaster : ScriptBaseEntity
{
	bool keepRepeatingLight = true;
	float m_yawCenter;
	float m_pitchCenter;
	float ATTN_LOW_HIGH = 0.25f;
	int m_iExplode, m_iSpriteTexture, m_iSpriteTexture2, m_iGlow, m_iSmoke, m_iTrail, m_blasterBolt, m_blasterImpact;
	CBeam@	m_pBeam;
	private CSprite@ glowShoot;
	
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
		
		@glowShoot = g_EntityFuncs.CreateSprite( "sprites/redflare1.spr", self.pev.origin, false ); 
		glowShoot.SetTransparency( kRenderTransAdd, 0, 0, 0, 50, 14 );
		glowShoot.SetScale( 0.25 );
		glowShoot.SetAttachment( self.edict(), 0 );
		
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
	
	void Ignite()
	{

		int r=175, g=175, b=175, br=175;
		int r2=255, g2=255, b2=255, br2=175;
		
		// rocket trail
		NetworkMessage ntrail1( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
			ntrail1.WriteByte( TE_BEAMFOLLOW );
			ntrail1.WriteShort( self.entindex() );
			ntrail1.WriteShort( m_iTrail );
			ntrail1.WriteByte( Math.RandomLong(5,30) );//Life
			ntrail1.WriteByte( Math.RandomLong(4,5) );//Width
			ntrail1.WriteByte( int(r) );
			ntrail1.WriteByte( int(g) );
			ntrail1.WriteByte( int(b) );
			ntrail1.WriteByte( int(br) );
		ntrail1.End();
		NetworkMessage ntrail2( MSG_PVS, NetworkMessages::SVC_TEMPENTITY );
			ntrail2.WriteByte( TE_BEAMFOLLOW );
			ntrail2.WriteShort( self.entindex() );
			ntrail2.WriteShort( m_iSpriteTexture2 );
			ntrail2.WriteByte( Math.RandomLong(5,30) );//Life
			ntrail2.WriteByte( Math.RandomLong(4,5) );//Width
			ntrail2.WriteByte( int(r2) );
			ntrail2.WriteByte( int(g2) );
			ntrail2.WriteByte( int(b2) );
			ntrail2.WriteByte( int(br2) );
		ntrail2.End();
	}
	
	void BlasterLight()
	{
		
		g_EntityFuncs.Remove( m_pBeam );
		@m_pBeam = null;
		
		Math.MakeAimVectors( pev.angles );
		@m_pBeam = g_EntityFuncs.CreateBeam( "sprites/portalhouse/plasma.spr", 15 );
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
		
		g_EntityFuncs.Remove( glowShoot );
		g_EntityFuncs.Remove( m_pBeam );
		g_EntityFuncs.Remove( self );
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

	void Killed( entvars_t@ pevAttacker, int iGib )
	{
		entvars_t@ pevOwner = self.pev.owner.vars;
		
		g_EntityFuncs.Remove( glowShoot );
		g_EntityFuncs.Remove( m_pBeam );
		g_EntityFuncs.Remove( self );
	}
	
	void UpdateOnRemove(){
		g_EntityFuncs.Remove( glowShoot );
		g_EntityFuncs.Remove( m_pBeam );
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
		int discBrightness = 175;
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




// HIGH POWER BLASTER _______________________________________________________________________________________________________
// HIGH POWER BLASTER _______________________________________________________________________________________________________
// HIGH POWER BLASTER _______________________________________________________________________________________________________
// HIGH POWER BLASTER _______________________________________________________________________________________________________
// HIGH POWER BLASTER _______________________________________________________________________________________________________




class CHPBlaster : ScriptBaseEntity
{
	bool keepRepeatingLight = true;
	float m_yawCenter;
	float m_pitchCenter;
	float ATTN_LOW_HIGH = 0.25f;
	int m_iExplode, m_iSpriteTexture, m_iSpriteTexture2, m_iGlow, m_iSmoke, m_iTrail, m_blasterBolt, m_blasterImpact;
	CBeam@	m_pBeam;
	private CSprite@ glowShoot;
	
	void Spawn()
	{
		Precache();
		self.pev.movetype = MOVETYPE_FLY;
		self.pev.solid = SOLID_BBOX;
		g_EntityFuncs.SetModel( self, BOWCASTER_MODEL_PROJECTILE );
		self.pev.body = 1;
		m_yawCenter = pev.angles.y;
		m_pitchCenter = pev.angles.x;
		g_EntityFuncs.SetSize( self.pev, g_vecZero, g_vecZero );
		
		@glowShoot = g_EntityFuncs.CreateSprite( "sprites/redflare1.spr", self.pev.origin, false ); 
		glowShoot.SetTransparency( kRenderTransAdd, 0, 0, 0, 50, 14 );
		glowShoot.SetScale( 0.25 );
		glowShoot.SetAttachment( self.edict(), 0 );
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
	
	void Ignite()
	{
		int r=175, g=175, b=175, br=175;
		int r2=255, g2=255, b2=255, br2=175;
		
		// rocket trail
		NetworkMessage ntrail1( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
			ntrail1.WriteByte( TE_BEAMFOLLOW );
			ntrail1.WriteShort( self.entindex() );
			ntrail1.WriteShort( m_iTrail );
			ntrail1.WriteByte( Math.RandomLong(5,30) );//Life
			ntrail1.WriteByte( Math.RandomLong(4,5) );//Width
			ntrail1.WriteByte( int(r) );
			ntrail1.WriteByte( int(g) );
			ntrail1.WriteByte( int(b) );
			ntrail1.WriteByte( int(br) );
		ntrail1.End();
		NetworkMessage ntrail2( MSG_PVS, NetworkMessages::SVC_TEMPENTITY );
			ntrail2.WriteByte( TE_BEAMFOLLOW );
			ntrail2.WriteShort( self.entindex() );
			ntrail2.WriteShort( m_iSpriteTexture2 );
			ntrail2.WriteByte( Math.RandomLong(5,30) );//Life
			ntrail2.WriteByte( Math.RandomLong(4,5) );//Width
			ntrail2.WriteByte( int(r2) );
			ntrail2.WriteByte( int(g2) );
			ntrail2.WriteByte( int(b2) );
			ntrail2.WriteByte( int(br2) );
		ntrail2.End();
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

		//_______PUSHING__________
		
		if (pOther.pev.classname != "monster_sentry" && pOther.pev.classname != "flechette" && pOther.IsBSPModel() == false)
		{
		Math.MakeVectors(pevOwner.v_angle);
		pOther.pev.velocity = pOther.pev.velocity + g_Engine.v_forward * 4 * self.pev.dmg;
		}
		
		//________________________

		Explode( pOther, tr, DMG_ENERGYBEAM );
		ProjectileDynamicLight( self.pev.origin, 8, 255, 0, 0, 1, 150 );
		g_Utility.DecalTrace( tr, DECAL_OFSCORCH1 );
		
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
		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, BOWCASTER_SOUND_EXPLODE, 0.4, ATTN_LOW_HIGH, 0, PITCH_NORM );

		keepRepeatingLight = false;
		self.pev.velocity = g_vecZero;
		SetTouch( null );
		
		g_EntityFuncs.Remove( glowShoot );
		g_EntityFuncs.Remove( m_pBeam );
		g_EntityFuncs.Remove( self );
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

	void Killed( entvars_t@ pevAttacker, int iGib )
	{
		entvars_t@ pevOwner = self.pev.owner.vars;
		if( pevOwner.ClassNameIs("player") )
		{
			g_EngineFuncs.SetView( self.pev.owner, self.pev.owner );
		}
		g_EntityFuncs.Remove( glowShoot );
		g_EntityFuncs.Remove( m_pBeam );
		g_EntityFuncs.Remove( self );
	}
	
	void UpdateOnRemove(){
		g_EntityFuncs.Remove( glowShoot );
		g_EntityFuncs.Remove( m_pBeam );
	}
	

	void ProjectileEffect( Vector origin )
	{
		int fireballScale = 3;
		int fireballBrightness = 255;
		int smokeScale = 12;
		int discLife = 12;
		int discWidth = 64;
		int discR = 255;
		int discG = 255;
		int discB = 255;
		int glowR = 255;
		int glowG = 255;
		int glowB = 255;
		int discBrightness = 175;
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


//________________________________________________________________________________
//________________________________________________________________________________
//________________________________________________________________________________
//________________________________________________________________________________
//____FLECHETTEAMMOCSHOOT____


class CCShoot : ScriptBaseEntity
{
	bool keepRepeatingLight = true;
	float m_yawCenter;
	float m_pitchCenter;
	float ATTN_LOW_HIGH = 0.25f;
	int m_iExplode, m_iSpriteTexture, m_iSpriteTexture2, m_iGlow, m_iSmoke, m_iTrail, m_iSpriteTextureShoot;
	private CSprite@ cShoot;
	
	void Spawn()
	{
		Precache();
		self.pev.movetype = MOVETYPE_TOSS;
		self.pev.solid = SOLID_BBOX;
		g_EntityFuncs.SetModel( self, HREPEATER_MODEL_NULL );
		self.pev.body = 1;
		m_yawCenter = pev.angles.y;
		m_pitchCenter = pev.angles.x;
		g_EntityFuncs.SetSize( self.pev, g_vecZero, g_vecZero );
		
		@cShoot = g_EntityFuncs.CreateSprite( "sprites/portalhouse/cshoot.spr", self.pev.origin, false ); 
		cShoot.SetTransparency( kRenderTransAdd, 0, 0, 0, 255, 14 );
		cShoot.SetScale( 0.50 );
		cShoot.SetAttachment( self.edict(), 0 );
		
	}
	
	void Precache()
	{
		m_iExplode = g_Game.PrecacheModel( "sprites/portalhouse/expB1.spr" );
		m_iSpriteTexture = g_Game.PrecacheModel( "sprites/white.spr" );
		m_iSpriteTexture2 = g_Game.PrecacheModel( "sprites/spray.spr" );
		m_iGlow = g_Game.PrecacheModel( "sprites/redflare1.spr" );
		m_iSmoke = g_Game.PrecacheModel( "sprites/steam1.spr" );
		m_iTrail = g_Game.PrecacheModel( "sprites/smoke.spr" );
		m_iSpriteTextureShoot = g_Game.PrecacheModel( "sprites/portalhouse/cshoot.spr" );
	}
	
	void CShootLight()
	{
		if (keepRepeatingLight){
		ProjectileDynamicLight( self.pev.origin, 16, 0, 0, 25, 0, 150 );	
		SetThink( ThinkFunction( this.CShootLight ) );
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
		
		//_______PUSHING__________
		
		if (pOther.pev.classname != "monster_sentry" && pOther.pev.classname != "flechette" && pOther.IsBSPModel() == false)
		{
		Math.MakeVectors(pevOwner.v_angle);
		pOther.pev.velocity = pOther.pev.velocity - (self.pev.origin - pOther.pev.origin).Normalize() * (self.pev.dmg * 10);
		}

		//________________________

		Explode( pOther, tr, DMG_BULLET );
		ProjectileDynamicLight( self.pev.origin, 16, 0, 0, 25, 1, 150 );	
		g_Utility.DecalTrace( tr, DECAL_OFSCORCH3 );

		
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
		
		g_WeaponFuncs.RadiusDamage( self.pev.origin, self.pev, pevOwner, self.pev.dmg * 2 , self.pev.dmg * 2.2, CLASS_NONE, DMG_ENERGYBEAM);
		
		while( (@pOther = g_EntityFuncs.FindEntityInSphere(pOther, self.pev.origin, self.pev.dmg * 2.2, "*", "classname")) !is null )
		{
		
		if (pOther.pev.classname != "monster_sentry" && pOther.pev.classname != "flechette" && pOther.IsBSPModel() == false)
		{
		Math.MakeVectors(pevOwner.v_angle);
		pOther.pev.velocity = pOther.pev.velocity - (self.pev.origin - pOther.pev.origin).Normalize() * (self.pev.dmg * 10);
		}
		
		}
		
		ProjectileEffect( self.pev.origin );
		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, HREPEATER_SOUND_EXPLODEALT, 0.4, ATTN_LOW_HIGH, 0, PITCH_NORM );

		keepRepeatingLight = false;
		self.pev.velocity = g_vecZero;
		SetTouch( null );
		g_EntityFuncs.Remove (cShoot);
		g_EntityFuncs.Remove( self );
	}

	void Killed( entvars_t@ pevAttacker, int iGib )
	{
		entvars_t@ pevOwner = self.pev.owner.vars;
		if( pevOwner.ClassNameIs("player") )
		{
			g_EngineFuncs.SetView( self.pev.owner, self.pev.owner );
		}
		g_EntityFuncs.Remove (cShoot);;
		g_EntityFuncs.Remove( self );
	}
	
	void UpdateOnRemove(){
		g_EntityFuncs.Remove (cShoot);
	}
	

	void ProjectileEffect( Vector origin )
	{
		int fireballScale = 3;
		int fireballBrightness = 255;
		int smokeScale = 14;
		int discLife = 2;
		int discWidth = 24;
		int discR = 255;
		int discG = 255;
		int discB = 0;
		int glowR = 255;
		int glowG = 255;
		int glowB = 0;
		int discBrightness = 255;
		int glowLife = 1;
		int glowScale = 15;
		int glowBrightness = 100;
		
		NetworkMessage projectilexp2( MSG_PVS, NetworkMessages::SVC_TEMPENTITY );
			projectilexp2.WriteByte( TE_SMOKE );
			projectilexp2.WriteCoord( origin.x );
			projectilexp2.WriteCoord( origin.y );
			projectilexp2.WriteCoord( origin.z );
			projectilexp2.WriteShort( m_iSmoke );
			projectilexp2.WriteByte( int(smokeScale) );
			projectilexp2.WriteByte( 24 ); //framrate
		projectilexp2.End();
		
		NetworkMessage projectilexp3( MSG_PVS, NetworkMessages::SVC_TEMPENTITY );
			projectilexp3.WriteByte( TE_BEAMCYLINDER );
			projectilexp3.WriteCoord( origin.x );
			projectilexp3.WriteCoord( origin.y );
			projectilexp3.WriteCoord( origin.z );
			projectilexp3.WriteCoord( origin.x );
			projectilexp3.WriteCoord( origin.y );
			projectilexp3.WriteCoord( origin.z + 600 );
			projectilexp3.WriteShort( m_iSpriteTexture );
			projectilexp3.WriteByte( 0 );
			projectilexp3.WriteByte( 0 );
			projectilexp3.WriteByte( discLife );
			projectilexp3.WriteByte( discWidth );
			projectilexp3.WriteByte( 0 );
			projectilexp3.WriteByte( int(discR) );
			projectilexp3.WriteByte( int(discG) );
			projectilexp3.WriteByte( int(discB) );
			projectilexp3.WriteByte( int(discBrightness) );
			projectilexp3.WriteByte( 0 );
		projectilexp3.End();
		
		NetworkMessage projectilexp5( MSG_PVS, NetworkMessages::SVC_TEMPENTITY );
			projectilexp5.WriteByte( TE_BEAMCYLINDER );
			projectilexp5.WriteCoord( origin.x );
			projectilexp5.WriteCoord( origin.y );
			projectilexp5.WriteCoord( origin.z );
			projectilexp5.WriteCoord( origin.x );
			projectilexp5.WriteCoord( origin.y );
			projectilexp5.WriteCoord( origin.z + 240 );
			projectilexp5.WriteShort( m_iSpriteTexture );
			projectilexp5.WriteByte( 0 );
			projectilexp5.WriteByte( 0 );
			projectilexp5.WriteByte( discLife );
			projectilexp5.WriteByte( discWidth );
			projectilexp5.WriteByte( 0 );
			projectilexp5.WriteByte( int(discR) );
			projectilexp5.WriteByte( int(discG) );
			projectilexp5.WriteByte( int(discB) );
			projectilexp5.WriteByte( int(discBrightness) );
			projectilexp5.WriteByte( 0 );
		projectilexp5.End();
		
	}
	

	
}

//______________________________________________________________
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

void RegisterBlaster()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "CBlaster", "blaster" );
}

void RegisterHPBlaster()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "CHPBlaster", "HPblaster" );
}

void RegisterCShoot()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "CCShoot", "flechetteCShoot" );
}

void RegisterBlasterNpc()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "CBlasterNpc", "blasterNpc" );
}
