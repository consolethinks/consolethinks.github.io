#include "ph_shot"
#include "p_entity"

const int BOWCASTER_DEFAULT_GIVE			= 50;
const int BOWCASTER_MAX_CARRY			= 100;
const int BOWCASTER_MAX_CLIP				= -1;
const int BOWCASTER_WEIGHT				= 110;
const int BOWCASTER_DAMAGE				= 39;

const string BOWCASTER_SOUND_DRAW		= "portalhouse/selectBowcaster.wav";
const string BOWCASTER_SOUND_FIRE1		= "portalhouse/fireBowcaster.wav";
const string BOWCASTER_SOUND_FIRE2		= "portalhouse/alt_fireBowcaster.wav";
const string BOWCASTER_SOUND_EXPLODE		= "portalhouse/hit_wallBowcaster.wav";
const string BOWCASTER_SOUND_DRYFIRE		= "portalhouse/dryfire.wav";

const string BOWCASTER_MODEL_NULL		= "models/not_precached2.mdl";
const string BOWCASTER_MODEL_VIEW		= "models/portalhouse/v_bowcaster.mdl";
const string BOWCASTER_MODEL_PLAYER		= "models/portalhouse/p_bowcaster.mdl";
const string BOWCASTER_MODEL_GROUND		= "models/portalhouse/w_bowcaster.mdl";
const string BOWCASTER_MODEL_CLIP		= "models/w_weaponbox.mdl";
const string BOWCASTER_MODEL_PROJECTILE	= "models/portalhouse/HighPowerBlasterShootRed.mdl";

const Vector VECTOR_CONE_BOWCASTER( 0.15, 0.15, 0.00  );

enum bowcaster_e
{
	BOWCASTER_IDLE1,
	BOWCASTER_FIRE,
	BOWCASTER_DRAW,
	BOWCASTER_HOLSTER,
	BOWCASTER_IDLE2,
	
};

class weapon_bowcasterblaster : ScriptBasePlayerWeaponEntity
{
	private CBasePlayer@ m_pPlayer = null;
	float ATTN_LOW = 0.5;
	int g_iCurrentMode = 0;
	CPEntityController@ pController = null;
	
	void Spawn()
	{
		self.Precache();
		g_EntityFuncs.SetModel( self, BOWCASTER_MODEL_GROUND );
		self.m_iDefaultAmmo = BOWCASTER_DEFAULT_GIVE;
		self.pev.sequence = 1;
		g_iCurrentMode = 0;
		self.FallInit();

	}

	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( BOWCASTER_MODEL_NULL );
		g_Game.PrecacheModel( BOWCASTER_MODEL_VIEW );
		g_Game.PrecacheModel( BOWCASTER_MODEL_PLAYER );
		g_Game.PrecacheModel( BOWCASTER_MODEL_GROUND );
		g_Game.PrecacheModel( BOWCASTER_MODEL_PROJECTILE );
		g_Game.PrecacheModel( "sprites/spray.spr" );
		g_Game.PrecacheModel( "sprites/portalhouse/expB1.spr" );
		g_Game.PrecacheModel( "sprites/redflare1.spr" );
		
		g_Game.PrecacheGeneric( "sound/" + BOWCASTER_SOUND_DRAW );
		g_Game.PrecacheGeneric( "sound/" + BOWCASTER_SOUND_FIRE1 );
		g_Game.PrecacheGeneric( "sound/" + BOWCASTER_SOUND_FIRE2 );
		g_Game.PrecacheGeneric( "sound/" + BOWCASTER_SOUND_EXPLODE );
		g_Game.PrecacheGeneric( "sound/" + BOWCASTER_SOUND_DRYFIRE );
		
		g_SoundSystem.PrecacheSound( BOWCASTER_SOUND_DRAW );
		g_SoundSystem.PrecacheSound( BOWCASTER_SOUND_FIRE1 );
		g_SoundSystem.PrecacheSound( BOWCASTER_SOUND_FIRE2 );
		g_SoundSystem.PrecacheSound( BOWCASTER_SOUND_EXPLODE );
		g_SoundSystem.PrecacheSound( BOWCASTER_SOUND_DRYFIRE );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= BOWCASTER_MAX_CARRY;
		info.iMaxAmmo2 	= -1;
		info.iMaxClip 	= BOWCASTER_MAX_CLIP;
		info.iSlot 		= 3;
		info.iPosition 	= 8;
		info.iFlags 	= ITEM_FLAG_NOAUTORELOAD;
		info.iWeight 	= BOWCASTER_WEIGHT;

		return true;
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( BaseClass.AddToPlayer( pPlayer ) )
		{
			@m_pPlayer = pPlayer;
			NetworkMessage message( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			message.WriteLong( self.m_iId );
			message.End();
			return true;
		}
		
		return false;
	}
	
	bool Deploy()
	{
		if (@pController == null){
		@pController = SpawnWeaponControllerInPlayer( m_pPlayer, BOWCASTER_MODEL_PLAYER );
		}
		return self.DefaultDeploy( self.GetV_Model( BOWCASTER_MODEL_VIEW ), self.GetP_Model( BOWCASTER_MODEL_NULL ), BOWCASTER_DRAW, "gauss" );
		
	}


	void Holster( int skipLocal = 0 )
	{
		m_pPlayer.m_flNextAttack = WeaponTimeBase() + 0.7;
		self.SendWeaponAnim( BOWCASTER_HOLSTER );
		ToggleZoom( 0 );
		g_iCurrentMode = 0;
		m_pPlayer.pev.maxspeed = 0;
		
		pController.DeletePEntity();
		@pController = null;

	}
	
	float WeaponTimeBase()
	{
		return g_Engine.time;
	}
	
	void PrimaryAttack()
	{

		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD || m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = g_Engine.time + 0.5;
			self.m_flNextSecondaryAttack = g_Engine.time + 0.5;
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, BOWCASTER_SOUND_DRYFIRE, 1.0, ATTN_LOW, 0, PITCH_NORM );
			return;
		}
		
		if (@pController != null){
		pController.SetAnimAttack();
		}
		
		m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		self.SendWeaponAnim( BOWCASTER_FIRE );
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, BOWCASTER_SOUND_FIRE2, 1.0, ATTN_LOW, 0, 94 + Math.RandomLong( 0,0xF ) );
		
		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle);
		
		ShootBlasterCrossbow1( m_pPlayer.pev, m_pPlayer.GetGunPosition() + g_Engine.v_forward * 32 + g_Engine.v_up * -4 + g_Engine.v_right * 4, g_Engine.v_forward * 4000);
		
		Vector vecTemp;
		vecTemp = m_pPlayer.pev.v_angle;

		vecTemp.x -= 0.8f;
		vecTemp.y += -0.3f;
		m_pPlayer.pev.angles = vecTemp;
		m_pPlayer.pev.fixangle = FAM_FORCEVIEWANGLES;
		
		m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) - 2 );
		self.m_flNextPrimaryAttack = g_Engine.time + 0.6;
		self.m_flNextSecondaryAttack = g_Engine.time + 0.6;
		self.m_flNextTertiaryAttack = g_Engine.time + 0.6;
		self.m_flTimeWeaponIdle = g_Engine.time + 1.0;
		m_pPlayer.pev.punchangle.x -= 2;
		

	}
	
	void SecondaryAttack()
	{

		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD || m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 4 )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = g_Engine.time + 0.5;
			self.m_flNextSecondaryAttack = g_Engine.time + 0.5;
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, BOWCASTER_SOUND_DRYFIRE, 1.0, ATTN_LOW, 0, PITCH_NORM );
			return;
		}
		
		if (@pController != null){
		pController.SetAnimAttack();
		}
		
		m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		self.SendWeaponAnim( BOWCASTER_FIRE );
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, BOWCASTER_SOUND_FIRE1, 1.0, ATTN_LOW, 0, 94 + Math.RandomLong( 0,0xF ) );
		
		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle);
		
		float numRandom1 = Math.RandomFloat(-VECTOR_CONE_BOWCASTER.y,VECTOR_CONE_BOWCASTER.y);
		float numRandom2 = Math.RandomFloat(-VECTOR_CONE_BOWCASTER.x,VECTOR_CONE_BOWCASTER.x);
		
		float numRandom3 = Math.RandomFloat(-VECTOR_CONE_BOWCASTER.y,VECTOR_CONE_BOWCASTER.y) + 0.15;
		float numRandom4 = Math.RandomFloat(-VECTOR_CONE_BOWCASTER.x,VECTOR_CONE_BOWCASTER.x) + 0.15;
		
		float numRandom5 = Math.RandomFloat(-VECTOR_CONE_BOWCASTER.y,VECTOR_CONE_BOWCASTER.y) + 0.15;
		float numRandom6 = Math.RandomFloat(-VECTOR_CONE_BOWCASTER.x,VECTOR_CONE_BOWCASTER.x) - 0.15;
		
		float numRandom7 = Math.RandomFloat(-VECTOR_CONE_BOWCASTER.y,VECTOR_CONE_BOWCASTER.y) - 0.15;
		float numRandom8 = Math.RandomFloat(-VECTOR_CONE_BOWCASTER.x,VECTOR_CONE_BOWCASTER.x) - 0.15;
		
		float numRandom9 = Math.RandomFloat(-VECTOR_CONE_BOWCASTER.y,VECTOR_CONE_BOWCASTER.y) - 0.15;
		float numRandom10 = Math.RandomFloat(-VECTOR_CONE_BOWCASTER.x,VECTOR_CONE_BOWCASTER.x) + 0.15;

		ShootBlasterCrossbow2( m_pPlayer.pev, m_pPlayer.GetGunPosition() + g_Engine.v_forward * 36 + g_Engine.v_up * -8 + g_Engine.v_right * 8, g_Engine.v_forward * 4000 + g_Engine.v_up * numRandom1 * 300 + g_Engine.v_right * numRandom2 * 500);
		ShootBlasterCrossbow2( m_pPlayer.pev, m_pPlayer.GetGunPosition() + g_Engine.v_forward * 34 + g_Engine.v_up * -6 + g_Engine.v_right * 10, g_Engine.v_forward * 4000 + g_Engine.v_up * numRandom3 * 300 + g_Engine.v_right * numRandom4 * 500);
		ShootBlasterCrossbow2( m_pPlayer.pev, m_pPlayer.GetGunPosition() + g_Engine.v_forward * 32 + g_Engine.v_up * -6 + g_Engine.v_right * 6, g_Engine.v_forward * 4000 + g_Engine.v_up * numRandom5 * 300 + g_Engine.v_right * numRandom6 * 500);
		ShootBlasterCrossbow2( m_pPlayer.pev, m_pPlayer.GetGunPosition() + g_Engine.v_forward * 30 + g_Engine.v_up * -10 + g_Engine.v_right * 6, g_Engine.v_forward * 4000 + g_Engine.v_up * numRandom7 * 300 + g_Engine.v_right * numRandom8 * 500);
		ShootBlasterCrossbow2( m_pPlayer.pev, m_pPlayer.GetGunPosition() + g_Engine.v_forward * 28 + g_Engine.v_up * -10 + g_Engine.v_right * 10, g_Engine.v_forward * 4000 + g_Engine.v_up * numRandom9 * 300 + g_Engine.v_right * numRandom10 * 500);
		
		Vector vecTemp;
		vecTemp = m_pPlayer.pev.v_angle;

		vecTemp.x -= 0.8f;
		vecTemp.y += -0.3f;
		m_pPlayer.pev.angles = vecTemp;
		m_pPlayer.pev.fixangle = FAM_FORCEVIEWANGLES;
		
		m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) - 5 );
		self.m_flNextPrimaryAttack = g_Engine.time + 0.6;
		self.m_flNextSecondaryAttack = g_Engine.time + 0.6;
		self.m_flNextTertiaryAttack = g_Engine.time + 0.6;
		self.m_flTimeWeaponIdle = g_Engine.time + 1.0;
		m_pPlayer.pev.punchangle.x -= 2;
		

	}
	


	void TertiaryAttack()
	{
		self.m_flNextSecondaryAttack = self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.3f;
		self.m_flNextTertiaryAttack = g_Engine.time + 0.6;
		
		switch ( g_iCurrentMode )
		{
			case 0:
			{
				g_iCurrentMode = 1;
				m_pPlayer.pev.maxspeed = 150;
				ToggleZoom( 30 );
				break;
			}
			
			case 1:
			{
				g_iCurrentMode = 0;
				m_pPlayer.pev.maxspeed = 0;
				ToggleZoom( 0 );
				break;
			}
		}
		
	}
	
	
	void ToggleZoom( int zoomedFOV )
	{
		if ( self.m_fInZoom == true )
		{
			SetFOV( 0 ); // 0 means reset to default fov
		}
		else if ( self.m_fInZoom == false )
		{
			SetFOV( zoomedFOV );
		}
	}
	
	void SetFOV( int fov )
	{
		m_pPlayer.pev.fov = m_pPlayer.m_iFOV = fov;
	}

	void WeaponIdle()
	{
		
		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;


		int iAnim;
		switch( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed,  0, 1 ) )
		{
			case 0:	iAnim = BOWCASTER_IDLE1;
			self.m_flTimeWeaponIdle = g_Engine.time + 2.4;
			break;
			
			case 1: iAnim = BOWCASTER_IDLE2;
			self.m_flTimeWeaponIdle = g_Engine.time + 5;
			break;
		}
		
		self.SendWeaponAnim( iAnim );

			
	}

	void Reload()
	{
		
		if( self.m_iClip != 0 )
			return;
		
		self.DefaultReload( 1, BOWCASTER_HOLSTER, 3.6 );
	}
}

class HighPowerBlasterAmmoBox : ScriptBasePlayerAmmoEntity
{	
	void Spawn()
	{ 
		Precache();
		g_EntityFuncs.SetModel( self, BOWCASTER_MODEL_CLIP );
		self.pev.body = 15;
		BaseClass.Spawn();
	}
	
	void Precache()
	{
		g_Game.PrecacheModel( BOWCASTER_MODEL_CLIP );
		g_SoundSystem.PrecacheSound( "items/9mmclip1.wav" );
	}
	
	bool AddAmmo( CBaseEntity@ pOther )
	{ 
		int iGive;

		iGive = BOWCASTER_DEFAULT_GIVE;

		if( pOther.GiveAmmo( iGive, "highpowerblaster", BOWCASTER_MAX_CARRY ) != -1)
		{
			g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "items/9mmclip1.wav", 1, ATTN_NORM );
			return true;
		}
		return false;
	}
}

void RegisterBowcasterBlaster()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_bowcasterblaster", "weapon_bowcasterblaster" );
	g_ItemRegistry.RegisterWeapon( "weapon_bowcasterblaster", "portalhouse", "highpowerblaster" );
}

void RegisterHighPowerBlasterAmmoBox()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "HighPowerBlasterAmmoBox", "ammo_highpowerblaster" );
}
