string CONTRA_WEAPON_VMDL = "models/hl/v_9mmAR.mdl";
string CONTRA_WEAPON_PMDL = "models/hl/p_9mmAR.mdl";
string CONTRA_WEAPON_WMDL = "models/hl/w_9mmAR.mdl";
string CONTRA_WEAPON_ANIM = "mp5";
string CONTRA_WEAPON_SHOOTSND = "hl/weapons/357_cock1.wav";
int CONTRA_WEAPON_FLAG = ITEM_FLAG_SELECTONEMPTY | ITEM_FLAG_NOAUTORELOAD | ITEM_FLAG_NOAUTOSWITCHEMPTY;
float CONTRA_WEAPON_REGEN_TIME = 7.0f;
int CONTRA_WEAPON_SLOT = 3;
int CONTRA_WEAPON_POSITION = 4;
string CONTRA_WEAPON_SHELLMDL = "models/shell.mdl";
int CONTRA_WEAPON_MAXAMMO = 1;
float CONTRA_WEAPON_RECHARGE_GAP = 0.1;

enum CONTRA_WEAPON_ANIMATION
{
	CONTRA_WEAPON_LONGIDLE = 0,
	CONTRA_WEAPON_IDLE1,
	CONTRA_WEAPON_LAUNCH,//HelloTimber added. Wanna fix the problem that no sound when fire.
	CONTRA_WEAPON_RELOAD,
	CONTRA_WEAPON_DEPLOY,
	CONTRA_WEAPON_FIRE1,
	CONTRA_WEAPON_FIRE2,//HelloTimber added. Wanna fix the wrong animation when fire.
	CONTRA_WEAPON_FIRE3,//HelloTimber added. Wanna fix the wrong animation when fire.
};

class CContraWeapon : ScriptBasePlayerWeaponEntity
{
	private CBasePlayer@ m_pPlayer = null;
	private int m_iShell;
	private float m_flRechargeTime;
	private bool bInReload = false;
	CAmmoType@ m_iAmmoType = aryAmmoType[0];

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, CONTRA_WEAPON_WMDL );
		self.m_iDefaultAmmo = CONTRA_WEAPON_MAXAMMO;
		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( CONTRA_WEAPON_VMDL );
		g_Game.PrecacheModel( CONTRA_WEAPON_PMDL );
		g_Game.PrecacheModel( CONTRA_WEAPON_WMDL );
		m_iShell = g_Game.PrecacheModel( CONTRA_WEAPON_SHELLMDL );

		g_SoundSystem.PrecacheSound( "hl/weapons/357_cock1.wav" );
		g_SoundSystem.PrecacheSound( CONTRA_WEAPON_SHOOTSND );

		g_Game.PrecacheGeneric( "sound/" + "hl/weapons/357_cock1.wav" );
		g_Game.PrecacheGeneric( "sound/" + CONTRA_WEAPON_SHOOTSND );
		g_Game.PrecacheGeneric( CONTRA_WEAPON_VMDL );
		g_Game.PrecacheGeneric( CONTRA_WEAPON_PMDL );
		g_Game.PrecacheGeneric( CONTRA_WEAPON_WMDL );
		g_Game.PrecacheGeneric( CONTRA_WEAPON_SHELLMDL );

        g_Game.PrecacheOther(BULLET_REGISTERNAME);
		g_Game.PrecacheOther("NAmmo");
    	g_Game.PrecacheOther("MAmmo");
		g_Game.PrecacheOther("SAmmo");
		g_Game.PrecacheOther("LAmmo");
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= CONTRA_WEAPON_MAXAMMO;
		info.iMaxAmmo2 	= -1;
		info.iMaxClip 	= CONTRA_WEAPON_MAXAMMO;
		info.iSlot 		= CONTRA_WEAPON_SLOT;
		info.iPosition 	= CONTRA_WEAPON_POSITION;
		info.iFlags 	= CONTRA_WEAPON_FLAG;
		info.iWeight 	= 998;

		return true;
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( !BaseClass.AddToPlayer( pPlayer ) )
			return false;
			
		@m_pPlayer = pPlayer;
			
		NetworkMessage message( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			message.WriteLong( self.m_iId );
		message.End();
		return true;
	}

	void Holster( int skiplocal /* = 0 */ )
	{
		bInReload = false;		
		SetThink( null );
	}
	
	bool PlayEmptySound()
	{
		if( self.m_bPlayEmptySound )
		{
			self.m_bPlayEmptySound = false;
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "hl/weapons/357_cock1.wav", 0.8, ATTN_NORM, 0, PITCH_NORM );
		}
		return false;
	}

	bool Deploy()
	{
		return self.DefaultDeploy( self.GetV_Model( CONTRA_WEAPON_VMDL ), self.GetP_Model( CONTRA_WEAPON_PMDL ), CONTRA_WEAPON_DEPLOY, CONTRA_WEAPON_ANIM );
	}
	
	float WeaponTimeBase()
	{
		return g_Engine.time;
	}

	void CancelReload()
	{
		SetThink( null );
		bInReload = false;
	}

	void PrimaryAttack()
	{
		if( self.m_iClip <= 0 || bInReload)
		{
			self.PlayEmptySound();
			return;
		}
		
		m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;//HelloTimber added. Wanna fix the problem that no sound when fire.
		m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;//HelloTimber added. Wanna fix the problem that no sound when fire.

		self.m_iClip--;
		
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "sc_contrahdl/hdl_shot.wav", 1.0, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );//HelloTimber added. Wanna fix the problem that no sound when fire.

		Vector vecSrc = m_pPlayer.GetGunPosition();
		m_iAmmoType.Method( m_pPlayer, vecSrc, g_Engine.v_forward * BULLET_DEFAULT_SPEED );
		self.SendWeaponAnim( CONTRA_WEAPON_FIRE1 );
        self.m_flNextPrimaryAttack = WeaponTimeBase() + m_iAmmoType.FireInter;
		
		self.Reload();//HelloTimber added. Needn't to reload manually.
	}

	void RechargeThink()
	{
		if(self.m_iClip >= self.iMaxClip())
		{
			CancelReload();
			return;
		}
		self.m_iClip++;
		self.pev.nextthink = WeaponTimeBase() + CONTRA_WEAPON_RECHARGE_GAP;
	}

	void Reload()
	{
		if(bInReload)
			return;

		m_flRechargeTime = WeaponTimeBase() + CONTRA_WEAPON_REGEN_TIME;
		bInReload = true;
		SetThink( ThinkFunction( RechargeThink ) );
		self.pev.nextthink = WeaponTimeBase();
		BaseClass.Reload();
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();
		m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );

		if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
			return;

		self.SendWeaponAnim( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed,  0, 1 ) == 0 ? CONTRA_WEAPON_LONGIDLE : CONTRA_WEAPON_IDLE1 );
		self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed,  10, 15 );
	}
}
