#include "ph_shot"
#include "p_entity"

const int E11_DEFAULT_GIVE			= 100;
const int E11_MAX_CARRY			= 300;
const int E11_MAX_CLIP				= -1;
const int E11_WEIGHT				= 110;
const int E11_DAMAGE				= 9;

const string E11_SOUND_DRAW		= "portalhouse/selectRifleBlaster.wav";
const string E11_SOUND_FIRE		= "portalhouse/shootRifleBlaster.wav";
const string E11_SOUND_EXPLODE		= "portalhouse/hit_wallRifleBlaster.wav";
const string E11_SOUND_DRYFIRE		= "portalhouse/dryfire.wav";

const string E11_MODEL_NULL		= "models/portalhouse/p_rifleBlaster.mdl";
const string E11_MODEL_VIEW		= "models/portalhouse/v_rifleBlaster.mdl";
const string E11_MODEL_PLAYER		= "models/portalhouse/p_rifleBlasterNull.mdl";
const string E11_MODEL_GROUND		= "models/portalhouse/w_rifleBlaster.mdl";
const string E11_MODEL_CLIP		= "models/w_weaponbox.mdl";
const string E11_MODEL_PROJECTILE	= "models/portalhouse/BlasterShootRed.mdl";

const Vector VECTOR_CONE( 0.15, 0.15, 0.00  );		// 10 degrees by 5 degrees

enum e11_e
{
	E11_LONGIDLE,
	E11_IDLE,
	E11_GRENADE,
	E11_RELOAD,
	E11_DRAW,
	E11_FIRE,
	E11_FIRE_SOLID,
	E11_HOLSTER,
	
};

class weapon_e11blaster : ScriptBasePlayerWeaponEntity
{
	private CBasePlayer@ m_pPlayer = null;
	float ATTN_LOW = 0.5;
	float coolDownNum = 0.0;
	CPEntityController@ pController = null;
	
	void Spawn()
	{
		self.Precache();
		g_EntityFuncs.SetModel( self, E11_MODEL_GROUND );
		self.m_iDefaultAmmo = E11_DEFAULT_GIVE;
		self.pev.sequence = 1;
		self.FallInit();
		
	}

	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( E11_MODEL_NULL );
		g_Game.PrecacheModel( E11_MODEL_VIEW );
		g_Game.PrecacheModel( E11_MODEL_PLAYER );
		g_Game.PrecacheModel( E11_MODEL_GROUND );
		g_Game.PrecacheModel( E11_MODEL_PROJECTILE );
		g_Game.PrecacheModel( "sprites/spray.spr" );
		g_Game.PrecacheModel( "sprites/portalhouse/expB1.spr" );
		g_Game.PrecacheModel( "sprites/redflare1.spr" );
		g_Game.PrecacheModel( "sprites/white.spr" );
		g_Game.PrecacheModel( "sprites/portalhouse/blasterboltred.spr" );
		g_Game.PrecacheModel( "sprites/portalhouse/blasterimpact.spr" );
		
		
		g_Game.PrecacheGeneric( "sound/" + E11_SOUND_DRAW );
		g_Game.PrecacheGeneric( "sound/" + E11_SOUND_FIRE );
		g_Game.PrecacheGeneric( "sound/" + E11_SOUND_EXPLODE );
		g_Game.PrecacheGeneric( "sound/" + E11_SOUND_DRYFIRE );
		g_SoundSystem.PrecacheSound( E11_SOUND_DRAW );
		g_SoundSystem.PrecacheSound( E11_SOUND_FIRE );
		g_SoundSystem.PrecacheSound( E11_SOUND_EXPLODE );
		g_SoundSystem.PrecacheSound( E11_SOUND_DRYFIRE );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= E11_MAX_CARRY;
		info.iMaxAmmo2 	= -1;
		info.iMaxClip 	= E11_MAX_CLIP;
		info.iSlot 		= 2;
		info.iPosition 	= 9;
		info.iFlags 	= ITEM_FLAG_NOAUTORELOAD;
		info.iWeight 	= E11_WEIGHT;

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
		@pController = SpawnWeaponControllerInPlayer( m_pPlayer, E11_MODEL_PLAYER );
		}
		return self.DefaultDeploy( self.GetV_Model( E11_MODEL_VIEW ), self.GetP_Model( E11_MODEL_NULL ), E11_DRAW, "mp5" );
	}


	void Holster( int skipLocal = 0 )
	{
		m_pPlayer.m_flNextAttack = WeaponTimeBase() + 0.7;
		self.SendWeaponAnim( E11_RELOAD );
		
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
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, E11_SOUND_DRYFIRE, 1.0, ATTN_LOW, 0, PITCH_NORM );
			return;
		}
		
		if (@pController != null){
		pController.SetAnimAttack();
		}
		
		m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		self.SendWeaponAnim( E11_FIRE );
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, E11_SOUND_FIRE, 1.0, ATTN_LOW, 0, 94 + Math.RandomLong( 0,0xF ) );
		
		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle);
		
		ShootBlaster( m_pPlayer.pev, m_pPlayer.GetGunPosition() + g_Engine.v_forward * 32 + g_Engine.v_up * -4 + g_Engine.v_right * 3, g_Engine.v_forward * 4000);
		
		Vector vecTemp;
		vecTemp = m_pPlayer.pev.v_angle;

		vecTemp.x -= 0.65f;
		vecTemp.y += 0.2f;
		m_pPlayer.pev.angles = vecTemp;
		m_pPlayer.pev.fixangle = FAM_FORCEVIEWANGLES;
		
		m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) - 1 );
		self.m_flNextPrimaryAttack = g_Engine.time + 0.4;
		self.m_flNextSecondaryAttack = g_Engine.time + 0.12;
		self.m_flTimeWeaponIdle = g_Engine.time + 1.0;
		m_pPlayer.pev.punchangle.x -= 0.25;
	}

	void SecondaryAttack()
	{

		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD || m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 1 )
		{
			self.PlayEmptySound();
			self.m_flNextSecondaryAttack = g_Engine.time + 0.5;
			self.m_flNextSecondaryAttack = g_Engine.time + 0.5;
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, E11_SOUND_DRYFIRE, 1.0, ATTN_LOW, 0, PITCH_NORM );
			return;
		}
		
		if (@pController != null){
		pController.SetAnimAttack();
		}
		
		m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		self.SendWeaponAnim( E11_FIRE );
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, E11_SOUND_FIRE, 1.0, ATTN_LOW, 0, 94 + Math.RandomLong( 0,0xF ) );
		
		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle);
		
		float numRandom1 = Math.RandomFloat(-VECTOR_CONE.y,VECTOR_CONE.y) * coolDownNum;
		float numRandom2 = Math.RandomFloat(-VECTOR_CONE.x,VECTOR_CONE.x) * coolDownNum;
		
		ShootBlasterAlt( m_pPlayer.pev, m_pPlayer.GetGunPosition() + g_Engine.v_forward * 32 + g_Engine.v_up * -4 + g_Engine.v_right * 3, g_Engine.v_forward * 4000 + g_Engine.v_up * numRandom1 * 500 + g_Engine.v_right * numRandom2 * 500);
		
		Vector vecTemp;
		vecTemp = m_pPlayer.pev.v_angle;

		vecTemp.x -= 0.65f;
		vecTemp.y += 0.2f;
		m_pPlayer.pev.angles = vecTemp;
		m_pPlayer.pev.fixangle = FAM_FORCEVIEWANGLES;

		m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) - 2 );
		self.m_flNextPrimaryAttack = g_Engine.time + 0.4;
		self.m_flNextSecondaryAttack = g_Engine.time + 0.12;
		self.m_flTimeWeaponIdle = g_Engine.time + 1.0;
		m_pPlayer.pev.punchangle.x -= 0.25;
		
		if (coolDownNum < 1.4){
		coolDownNum += 0.1;
		}
		
		SetThink( ThinkFunction( this.CoolDownFire ) );
		self.pev.nextthink = g_Engine.time + 0.2;
	}

	void CoolDownFire(){
		
		if (coolDownNum > 0.0){
		coolDownNum -= 0.7;
		}
		
		if (coolDownNum < 0.0){
		coolDownNum = 0.0;
		}
		
		SetThink( ThinkFunction( this.CoolDownFire ) );
		self.pev.nextthink = g_Engine.time + 0.2;
	}

	void WeaponIdle()
	{
		

		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		self.SendWeaponAnim( E11_LONGIDLE );
		self.m_flTimeWeaponIdle = g_Engine.time + 10.0;
	}

	void Reload()
	{
		
		if( self.m_iClip != 0 )
			return;
		
		self.DefaultReload( 1, E11_RELOAD, 3.6 );
	}
}

class BlasterAmmoBox : ScriptBasePlayerAmmoEntity
{	
	void Spawn()
	{ 
		Precache();
		g_EntityFuncs.SetModel( self, E11_MODEL_CLIP );
		self.pev.body = 15;
		BaseClass.Spawn();
	}
	
	void Precache()
	{
		g_Game.PrecacheModel( E11_MODEL_CLIP );
		g_SoundSystem.PrecacheSound( "items/9mmclip1.wav" );
	}
	
	bool AddAmmo( CBaseEntity@ pOther )
	{ 
		int iGive;

		iGive = E11_DEFAULT_GIVE;

		if( pOther.GiveAmmo( iGive, "blaster", E11_MAX_CARRY ) != -1)
		{
			g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "items/9mmclip1.wav", 1, ATTN_NORM );
			return true;
		}
		return false;
	}
}

void RegisterE11Blaster()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_e11blaster", "weapon_e11blaster" );
	g_ItemRegistry.RegisterWeapon( "weapon_e11blaster", "portalhouse", "blaster" );
}

void RegisterBlasterAmmoBox()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "BlasterAmmoBox", "ammo_blaster" );
}
