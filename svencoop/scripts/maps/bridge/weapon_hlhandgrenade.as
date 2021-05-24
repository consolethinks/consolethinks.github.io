/*  
* The original Half-Life version of the Hand Grenade
* Converted to SC by Nero
* Edited by Hezus to support 1 handgrenade per pickup
*/

namespace hlw_handgrenade
{

const int HLW_SLOT					= 5;
const int HLW_POSITION				= 10;
const int DAMAGE_HANDGRENADE		= 100;
const int HANDGRENADE_DEFAULT_GIVE	= 1;
const int HANDGRENADE_WEIGHT		= 5;
const int HANDGRENADE_MAX_CARRY		= 10;

enum hlw_e
{
	ANIM_IDLE = 0,
	ANIM_FIDGET,
	ANIM_PINPULL,
	ANIM_THROW1,	// toss
	ANIM_THROW2,	// medium
	ANIM_THROW3,	// hard
	ANIM_HOLSTER,
	ANIM_DRAW
};

int g_sModelIndexFireball;
int g_sModelIndexWExplosion;
int g_sModelIndexSmoke;

class weapon_hlhandgrenade : ScriptBasePlayerWeaponEntity
{
	private CBasePlayer@ m_pPlayer = null;
	float m_flStartThrow;
	float m_flReleaseThrow;
	
	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, self.GetW_Model("models/w_grenade.mdl") );
		self.pev.dmg = DAMAGE_HANDGRENADE;
		self.m_iDefaultAmmo = HANDGRENADE_DEFAULT_GIVE;
		self.FallInit();
	}


	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( "models/w_grenade.mdl" );
		g_Game.PrecacheModel( "models/v_grenade.mdl" );
		g_Game.PrecacheModel( "models/p_grenade.mdl" );

		g_SoundSystem.PrecacheSound( "items/gunpickup2.wav" );

		g_Game.PrecacheOther( "hlgrenade" );
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( !BaseClass.AddToPlayer(pPlayer) )
			return false;

		@m_pPlayer = pPlayer;

		NetworkMessage m( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			m.WriteLong( g_ItemRegistry.GetIdForName("weapon_hlhandgrenade") );
		m.End();

		return true;
	}
	
	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= HANDGRENADE_MAX_CARRY;
		info.iMaxAmmo2 	= -1;
		info.iMaxClip = WEAPON_NOCLIP;
		info.iSlot = HLW_SLOT-1;
		info.iPosition = HLW_POSITION-1;
		info.iWeight = HANDGRENADE_WEIGHT;
		info.iFlags = ITEM_FLAG_LIMITINWORLD | ITEM_FLAG_EXHAUSTIBLE;

		return true;
	}

	void Materialize()
	{
		BaseClass.Materialize();
		SetTouch( TouchFunction(CustomTouch) );
	}

	void CustomTouch( CBaseEntity@ pOther ) 
	{
		if( !pOther.IsPlayer() )
			return;

		CBasePlayer@ pPlayer = cast<CBasePlayer@>( pOther );

		if( pPlayer.HasNamedPlayerItem("weapon_hlhandgrenade") !is null )
		{
	  		if( pPlayer.GiveAmmo(1, "weapon_hlhandgrenade", HANDGRENADE_MAX_CARRY) != -1 )
			{
					self.CheckRespawn();
					g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "items/gunpickup2.wav", 1, ATTN_NORM );

					g_EntityFuncs.Remove( self );
	  		}

	  		return;
		}
		else if( pPlayer.AddPlayerItem( self ) != APIR_NotAdded )
		{
	  		self.AttachToPlayer( pPlayer );
	  		g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "items/gunpickup2.wav", 1, ATTN_NORM );
		}
	}

	bool Deploy()
	{
		m_flReleaseThrow = -1;
		bool bResult;
		{
			bResult = self.DefaultDeploy( self.GetV_Model("models/v_grenade.mdl"), self.GetP_Model("models/p_grenade.mdl"), ANIM_DRAW, "crowbar" );
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.5f;
			return bResult;
		}
	}

	bool CanHolster()
	{
		// can only holster hand grenades when not primed!
		return (m_flStartThrow == 0);
	}

	void Holster( int skiplocal /* = 0 */ )
	{
		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.5f;

		if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) > 0 )
			self.SendWeaponAnim( ANIM_HOLSTER );
		else
		{
			// no more grenades!
			m_pPlayer.pev.weapons &= ~(1<<WEAPON_HANDGRENADE);
			SetThink( ThinkFunction(self.DestroyItem) );
			pev.nextthink = g_Engine.time + 0.1f;
		}

		g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, "common/null.wav", 1.0f, ATTN_NORM );
	}

	void PrimaryAttack()
	{
		if( m_flStartThrow <= 0 and m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) > 0 )
		{
			m_flStartThrow = g_Engine.time;
			m_flReleaseThrow = 0;

			self.SendWeaponAnim( ANIM_PINPULL );
			self.m_flTimeWeaponIdle = g_Engine.time + 0.5f;
		}
	}

	void WeaponIdle()
	{
		if( m_flReleaseThrow == 0 and m_flStartThrow > 0 )
			 m_flReleaseThrow = g_Engine.time;

		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		if( m_flStartThrow > 0 )
		{
			Vector angThrow = m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle;

			if( angThrow.x < 0 )
				angThrow.x = -10 + angThrow.x * ((90 - 10) / 90.0f);
			else
				angThrow.x = -10 + angThrow.x * (( 90 + 10) / 90.0f);

			float flVel = (90 - angThrow.x) * 4;
			if( flVel > 500 )
				flVel = 500;

			Math.MakeVectors( angThrow );

			Vector vecSrc = m_pPlayer.pev.origin + m_pPlayer.pev.view_ofs + g_Engine.v_forward * 16;

			Vector vecThrow = g_Engine.v_forward * flVel + m_pPlayer.pev.velocity;

			// alway explode 3 seconds after the pin was pulled
			float time = m_flStartThrow - g_Engine.time + 3.0f;
			if( time < 0 )
				time = 0;

			ShootTimed( m_pPlayer.pev, vecSrc, vecThrow, time );

			if( flVel < 500 )
				self.SendWeaponAnim( ANIM_THROW1 );
			else if( flVel < 1000 )
				self.SendWeaponAnim( ANIM_THROW2 );
			else
				self.SendWeaponAnim( ANIM_THROW3 );

			// player "shoot" animation
			m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

			m_flReleaseThrow = 0;
			m_flStartThrow = 0;
			self.m_flNextPrimaryAttack = g_Engine.time + 0.5f; //GetNextAttackDelay
			self.m_flTimeWeaponIdle = g_Engine.time + 0.5f; //UTIL_WeaponTimeBase

			m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) - 1 );

			if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 )
			{
				// just threw last grenade
				// set attack times in the future, and weapon idle in the future so we can see the whole throw
				// animation, weapon idle will automatically retire the weapon for us.
				self.m_flTimeWeaponIdle = self.m_flNextSecondaryAttack = self.m_flNextPrimaryAttack = g_Engine.time + 0.5f;// ensure that the animation can finish playing
			}

			return;
		}
		else if( m_flReleaseThrow > 0 )
		{
			// we've finished the throw, restart.
			m_flStartThrow = 0;

			if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) > 0 )
				self.SendWeaponAnim( ANIM_DRAW );
			else
			{
				self.RetireWeapon();
				return;
			}

			self.m_flTimeWeaponIdle = g_Engine.time + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 10, 15 );
			m_flReleaseThrow = -1;
			return;
		}

		if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) > 0 )
		{
			int iAnim;
			float flRand = g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 0, 1 );
			if( flRand <= 0.75 )
			{
				iAnim = ANIM_IDLE;
				self.m_flTimeWeaponIdle = g_Engine.time + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 10, 15 );// how long till we do this again.
			}
			else 
			{
				iAnim = ANIM_FIDGET;
				self.m_flTimeWeaponIdle = g_Engine.time + 75.0f / 30.0f;
			}

			self.SendWeaponAnim( iAnim );
		}
	}	
}

class hlgrenade : ScriptBaseMonsterEntity
{
	bool m_bRegisteredSound;

	void Spawn()
	{
		Precache();

		pev.movetype = MOVETYPE_BOUNCE;
		pev.solid = SOLID_BBOX;

		g_EntityFuncs.SetModel( self, "models/w_grenade.mdl" );
		g_EntityFuncs.SetSize( self.pev, g_vecZero, g_vecZero );

		pev.dmg = 100;
		m_bRegisteredSound = false;
	}

	void Precache()
	{
		g_SoundSystem.PrecacheSound( "hlclassic/weapons/debris1.wav" );
		g_SoundSystem.PrecacheSound( "hlclassic/weapons/debris2.wav" );
		g_SoundSystem.PrecacheSound( "hlclassic/weapons/debris3.wav" );

		g_sModelIndexFireball = g_Game.PrecacheModel( "sprites/zerogxplode.spr" );
		g_sModelIndexWExplosion = g_Game.PrecacheModel( "sprites/WXplo1.spr" );
		g_sModelIndexSmoke = g_Game.PrecacheModel( "sprites/steam1.spr" );
	}

	void Explode()
	{
		TraceResult tr;

		g_Utility.TraceLine( pev.origin, pev.origin + Vector(0, 0, -32), ignore_monsters, self.edict(), tr);
		Explode( tr, DMG_BLAST );
	}

	void Explode( TraceResult pTrace, int bitsDamageType )
	{
		pev.model = string_t();//invisible
		pev.solid = SOLID_NOT;// intangible

		pev.takedamage = DAMAGE_NO;

		// Pull out of the wall a bit
		if( pTrace.flFraction != 1.0f )
			pev.origin = pTrace.vecEndPos + (pTrace.vecPlaneNormal * (pev.dmg - 24) * 0.6f);

		int iContents = g_EngineFuncs.PointContents( pev.origin );

		NetworkMessage expl( MSG_PAS, NetworkMessages::SVC_TEMPENTITY, pev.origin );
			expl.WriteByte( TE_EXPLOSION );		// This makes a dynamic light and the explosion sprites/sound
			expl.WriteCoord( pev.origin.x );	// Send to PAS because of the sound
			expl.WriteCoord( pev.origin.y );
			expl.WriteCoord( pev.origin.z );
			if( iContents != CONTENTS_WATER )
				expl.WriteShort( g_sModelIndexFireball );
			else
				expl.WriteShort( g_sModelIndexWExplosion );
			expl.WriteByte( int((pev.dmg - 50) * 0.60f)  ); // scale * 10
			expl.WriteByte( 15 ); // framerate
			expl.WriteByte( TE_EXPLFLAG_NONE );
		expl.End();

		GetSoundEntInstance().InsertSound( bits_SOUND_COMBAT, pev.origin, NORMAL_EXPLOSION_VOLUME, 3.0f, self ); 

		entvars_t@ pevOwner;
		if( pev.owner !is null )
			@pevOwner = pev.owner.vars;
		else
			@pevOwner = null;

		@pev.owner = null; // can't traceline attack owner if this is set

		g_WeaponFuncs.RadiusDamage( pev.origin, self.pev, pevOwner, pev.dmg, pev.dmg * 2.5f, CLASS_NONE, bitsDamageType );

		if( Math.RandomFloat(0, 1) < 0.5f )
			g_Utility.DecalTrace( pTrace, DECAL_SCORCH1 );
		else
			g_Utility.DecalTrace( pTrace, DECAL_SCORCH2 );

		switch( Math.RandomLong(0, 2) )
		{
			case 0:	g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, "hlclassic/weapons/debris1.wav", 0.55f, ATTN_NORM ); break;
			case 1:	g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, "hlclassic/weapons/debris2.wav", 0.55f, ATTN_NORM ); break;
			case 2:	g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, "hlclassic/weapons/debris3.wav", 0.55f, ATTN_NORM ); break;
		}

		pev.effects |= EF_NODRAW;
		SetThink( ThinkFunction(this.Smoke) );
		pev.velocity = g_vecZero;
		pev.nextthink = g_Engine.time + 0.3f;

		if( iContents != CONTENTS_WATER )
		{
			int sparkCount = Math.RandomLong(0, 3);
			for( int i = 0; i < sparkCount; i++ )
				g_EntityFuncs.Create( "spark_shower", pev.origin, pTrace.vecPlaneNormal, false );
		}
	}

	void Smoke()
	{
		if( g_EngineFuncs.PointContents(pev.origin) == CONTENTS_WATER )
			g_Utility.Bubbles( pev.origin - Vector(64, 64, 64), pev.origin + Vector(64, 64, 64), 100 );
		else
		{
			NetworkMessage smoke( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, pev.origin );
				smoke.WriteByte( TE_SMOKE );
				smoke.WriteCoord( pev.origin.x );
				smoke.WriteCoord( pev.origin.y );
				smoke.WriteCoord( pev.origin.z );
				smoke.WriteShort( g_sModelIndexSmoke );
				smoke.WriteByte( int((pev.dmg - 50) * 0.80f) ); // scale * 10
				smoke.WriteByte( 12 ); // framerate
			smoke.End();
		}

		g_EntityFuncs.Remove( self );
	}

	void Killed( entvars_t@ pevAttacker, int iGib )
	{
		Detonate();
	}

	// Timed grenade, this think is called when time runs out.
	void DetonateUse( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float value )
	{
		SetThink( ThinkFunction(this.Detonate) );
		pev.nextthink = g_Engine.time;
	}

	void Detonate()
	{
		TraceResult tr;
		Vector		vecSpot;

		vecSpot = pev.origin + Vector (0 , 0 , 8);
		g_Utility.TraceLine( vecSpot, vecSpot + Vector (0, 0, -40), ignore_monsters, self.edict(), tr);

		Explode( tr, DMG_BLAST );
	}

	void BounceTouch( CBaseEntity@ pOther )
	{
		// don't hit the guy that launched this grenade
		if( pOther.edict() is pev.owner )
			return;

		// only do damage if we're moving fairly fast
		if( self.m_flNextAttack < g_Engine.time and self.pev.velocity.Length() > 100 )
		{
			entvars_t@ pevOwner = self.pev.owner.vars;
			if( pevOwner !is null )
			{
				TraceResult tr = g_Utility.GetGlobalTrace();
				g_WeaponFuncs.ClearMultiDamage();
				pOther.TraceAttack( pevOwner, 1, g_Engine.v_forward, tr, DMG_CLUB );
				g_WeaponFuncs.ApplyMultiDamage( self.pev, pevOwner);
			}

			self.m_flNextAttack = g_Engine.time + 1.0f; // debounce
		}

		Vector vecTestVelocity;
		// pev.avelocity = Vector (300, 300, 300);

		// this is my heuristic for modulating the grenade velocity because grenades dropped purely vertical
		// or thrown very far tend to slow down too quickly for me to always catch just by testing velocity. 
		// trimming the Z velocity a bit seems to help quite a bit.
		vecTestVelocity = pev.velocity; 
		vecTestVelocity.z *= 0.45f;

		if( !m_bRegisteredSound and vecTestVelocity.Length() <= 60 )
		{
			//g_Game.AlertMessage( at_console, "Grenade Registered!: %1\n", vecTestVelocity.Length() );

			// grenade is moving really slow. It's probably very close to where it will ultimately stop moving. 
			// go ahead and emit the danger sound.
			
			// register a radius louder than the explosion, so we make sure everyone gets out of the way
			GetSoundEntInstance().InsertSound( bits_SOUND_DANGER, pev.origin, int(pev.dmg / 0.4f), 0.3f, self ); 
			m_bRegisteredSound = true;
		}

		if( (pev.flags & FL_ONGROUND) != 0 )
		{
			// add a bit of static friction
			pev.velocity = pev.velocity * 0.8f;

			pev.sequence = Math.RandomLong(1, 1);
		}
		else
		{
			// play bounce sound
			BounceSound();
		}

		pev.framerate = pev.velocity.Length() / 200.0f;
		if( pev.framerate > 1.0f )
			pev.framerate = 1;
		else if( pev.framerate < 0.5f )
			pev.framerate = 0;

	}

	void BounceSound()
	{
		switch( Math.RandomLong( 0, 2 ) )
		{
			case 0:	g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, "weapons/grenade_hit1.wav", 0.25f, ATTN_NONE );	break;
			case 1:	g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, "weapons/grenade_hit2.wav", 0.25f, ATTN_NONE );	break;
			case 2:	g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, "weapons/grenade_hit3.wav", 0.25f, ATTN_NONE );	break;
		}
	}

	void TumbleThink()
	{
		if( !self.IsInWorld() )
		{
			g_EntityFuncs.Remove( self );
			return;
		}

		self.StudioFrameAdvance();
		pev.nextthink = g_Engine.time + 0.1f;

		if( pev.dmgtime - 1 < g_Engine.time )
			GetSoundEntInstance().InsertSound( bits_SOUND_DANGER, pev.origin + pev.velocity * (pev.dmgtime - g_Engine.time), 400, 0.1f, self ); 

		if( pev.dmgtime <= g_Engine.time )
			SetThink( ThinkFunction(this.Detonate) );
			
		if( pev.waterlevel != WATERLEVEL_DRY )
		{
			pev.velocity = pev.velocity * 0.5f;
			pev.framerate = 0.2f;
		}
	}
}

hlgrenade ShootTimed( entvars_t@ pevOwner, Vector vecStart, Vector vecVelocity, float time )
{
	CBaseEntity@ cbeGrenade = g_EntityFuncs.CreateEntity( "hlgrenade", null,  false );
	hlgrenade@ pGrenade = cast<hlgrenade@>(CastToScriptClass(cbeGrenade));
	g_EntityFuncs.DispatchSpawn( pGrenade.self.edict() );

	g_EntityFuncs.SetOrigin( pGrenade.self, vecStart );

	pGrenade.pev.velocity = vecVelocity;
	pGrenade.pev.angles = Math.VecToAngles(pGrenade.pev.velocity);
	@pGrenade.pev.owner = pevOwner.get_pContainingEntity();

	pGrenade.SetTouch( TouchFunction(pGrenade.BounceTouch) );	// Bounce if touched

	// Take one second off of the desired detonation time and set the think to PreDetonate. PreDetonate
	// will insert a DANGER sound into the world sound list and delay detonation for one second so that 
	// the grenade explodes after the exact amount of time specified in the call to ShootTimed(). 

	pGrenade.pev.dmgtime = g_Engine.time + time;
	pGrenade.SetThink( ThinkFunction(pGrenade.TumbleThink) );
	pGrenade.pev.nextthink = g_Engine.time + 0.1f;
	if( time < 0.1f )
	{
		pGrenade.pev.nextthink = g_Engine.time;
		pGrenade.pev.velocity = g_vecZero;
	}

	pGrenade.pev.sequence = Math.RandomLong(3, 6);
	pGrenade.pev.framerate = 1.0f;

	// Tumble through the air
	// pGrenade.pev.avelocity.x = -400;

	pGrenade.pev.gravity = 0.5f;
	pGrenade.pev.friction = 0.8f;

	g_EntityFuncs.SetModel( pGrenade.self, "models/w_grenade.mdl" );
	pGrenade.pev.dmg = 100;

	return pGrenade;
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "hlw_handgrenade::hlgrenade", "hlgrenade" );
	g_CustomEntityFuncs.RegisterCustomEntity( "hlw_handgrenade::weapon_hlhandgrenade", "weapon_hlhandgrenade" );
	g_ItemRegistry.RegisterWeapon( "weapon_hlhandgrenade", "hl_weapons", "weapon_hlhandgrenade", "", "weapon_hlhandgrenade" );
}

} //namespace hlw_handgrenade END