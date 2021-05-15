namespace ContraBoyz
{
// 怪物Event
const int BOYZ_RANGEATTACK_EVENT = 3;
//怪物属性
const string BOYZ_CLASSNAME = "monster_contra_boyz";
const string BOYZ_DISPLAY_NAME = "Orc Boyz";
const string BOYZ_MODEL = "models/barney.mdl";
const string BOYZ_ATTACKSOUND = "sc_contrahdl/hdl_shot_2.wav";//HelloTimber changed, give him a sound when fire.
const string BOYZ_DEATHSOUND = "common/null.wav";//HelloTimber changed, no sound when dead.
const string BOYZ_ALERTSOUND = "AoMDC/monsters/ghost/slv_die.wav";//HelloTimber changed, no sound when see player.
const float BOYZ_BULLETVELOCITY = 512;
const float BOYZ_EYESIGHT_RANGE = 2048;
const float BOYZ_ATTACK_FREQUENCE = 0.3;
const float BOYZ_MOD_HEALTH = 30.0;
const float BOYZ_MOD_MOVESPEED = 325.0;
const int BOYZ_MOD_DMG_INIT = 10;
const float BOYZ_MOD_HEALTH_SURVIVAL = 30.0;
const float BOYZ_MOD_MOVESPEED_SURVIVAL = 400.0;
const int BOYZ_MOD_DMG_INIT_SURVIVAL = 10;

class CMonsterBoyz : ScriptBaseMonsterEntity
{
	private float m_flNextAttack = 0;
	private bool bSurvivalEnabled = g_EngineFuncs.CVarGetFloat("mp_survival_starton") == 1 && g_EngineFuncs.CVarGetFloat("mp_survival_supported") == 1;
	
	void Precache()
	{
		BaseClass.Precache();

		g_Game.PrecacheModel(BOYZ_MODEL);

		g_SoundSystem.PrecacheSound(BOYZ_ATTACKSOUND);
		g_SoundSystem.PrecacheSound(BOYZ_DEATHSOUND);
		g_SoundSystem.PrecacheSound(BOYZ_ALERTSOUND);
	}
	
	void Spawn()
	{
		Precache();

		if( !self.SetupModel() )
			g_EntityFuncs.SetModel( self, BOYZ_MODEL );
			
		g_EntityFuncs.SetSize( self.pev, VEC_HUMAN_HULL_MIN, VEC_HUMAN_HULL_MAX );
	
		self.pev.health = bSurvivalEnabled ? BOYZ_MOD_HEALTH_SURVIVAL : BOYZ_MOD_HEALTH;
		self.pev.solid = SOLID_SLIDEBOX;
		self.pev.movetype = MOVETYPE_STEP;
		self.m_bloodColor = BLOOD_COLOR_RED;
		//宽
		self.pev.view_ofs = Vector( 0, 0, 80 );
		self.m_flFieldOfView = 0.8;
		self.m_MonsterState = MONSTERSTATE_NONE;
		self.m_afCapability = bits_CAP_DOORS_GROUP;
		self.m_FormattedName = BOYZ_DISPLAY_NAME;

		self.MonsterInit();
	}

	int	Classify()
	{
		return self.GetClassification( CLASS_ALIEN_MONSTER );
	}
	
	void SetYawSpeed()
	{
		self.pev.yaw_speed = bSurvivalEnabled ? BOYZ_MOD_MOVESPEED_SURVIVAL : BOYZ_MOD_MOVESPEED;
	}
	
	void DeathSound()
	{
		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, BOYZ_DEATHSOUND, 1, ATTN_NORM, 0, PITCH_NORM );
	}
	
	void Killed(entvars_t@ pevAttacker, int iGib)
	{
		BaseClass.Killed(pevAttacker, iGib);
	}
	
	void AlertSound()
	{	
		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, BOYZ_ALERTSOUND, 1, ATTN_NORM, 0, PITCH_NORM );
	
	}
	
	int TakeDamage( entvars_t@ pevInflictor, entvars_t@ pevAttacker, float flDamage, int bitsDamageType)
	{	
		if(pevAttacker is null)
			return 0;

		CBaseEntity@ pAttacker = g_EntityFuncs.Instance( pevAttacker );
		if(self.CheckAttacker( pAttacker ))
			return 0;

		return BaseClass.TakeDamage(pevInflictor, pevAttacker, flDamage, bitsDamageType);
	}
	
	CBaseEntity@ GetEnemy()
	{
		if(self.m_hEnemy.IsValid())
			return self.m_hEnemy.GetEntity().MyMonsterPointer();
		return null;
	}	
	
	bool CheckMeleeAttack1( float flDot, float flDist )
	{
		return false;
	}
	bool CheckMeleeAttack2( float flDot, float flDist )
	{
		return false;
	}
	
	bool CheckRangeAttack1(float flDot, float flDist)
	{
		if ( flDist <= BOYZ_EYESIGHT_RANGE && flDot >= 0.5 && self.NoFriendlyFire())
		{
			if(!self.m_hEnemy.IsValid())
				return false;
			CBaseMonster@ pEnemy = self.m_hEnemy.GetEntity().MyMonsterPointer();
			if (pEnemy is null)
				return false;
			Vector vecSrc = self.pev.origin;
			vecSrc.z += pev.size.z * 0.5;;
			Vector vecEnd = (pEnemy.BodyTarget( vecSrc ) - pEnemy.Center()) + self.m_vecEnemyLKP;
			TraceResult tr;
			g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, self.edict(), tr );
			if ( tr.flFraction == 1.0 || tr.pHit is pEnemy.edict() )
				return true;
		}
		return false;
	}

	//Waaaaaaaagh!
	void ShootPlayer(CBasePlayer@ pPlayer)
	{
		Math.MakeVectors( self.pev.angles );
		Vector vecSrc = self.pev.origin;
		vecSrc.z += pev.size.z * 0.5;;
		Vector vecAim = self.ShootAtEnemy( vecSrc );
		Vector angDir = Math.VecToAngles( vecAim );
		self.SetBlending( 0, angDir.x );

		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, BOYZ_ATTACKSOUND, 1, ATTN_NORM, 0, PITCH_NORM );
		CProjBullet@ pBullet = ShootABullet(self, vecSrc, vecAim * BOYZ_BULLETVELOCITY);
		pBullet.self.pev.dmg = bSurvivalEnabled ? BOYZ_MOD_DMG_INIT_SURVIVAL : BOYZ_MOD_DMG_INIT;
	}

	void HandleAnimEvent(MonsterEvent@ pEvent)
	{
		if(g_Engine.time < m_flNextAttack)
			return;
		switch(pEvent.event)
		{
			case BOYZ_RANGEATTACK_EVENT:
			{
				//我的剑，只砍玩家
				CBasePlayer@ pPlayer = cast<CBasePlayer@>(GetEnemy());
				if (pPlayer !is null)
				{
					ShootPlayer(pPlayer);
					m_flNextAttack = g_Engine.time + BOYZ_ATTACK_FREQUENCE;
				}
				break;
			}
			default: BaseClass.HandleAnimEvent(pEvent);break;
		}
	}
}
void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "ContraBoyz::CMonsterBoyz", BOYZ_CLASSNAME );
	g_Game.PrecacheOther(BOYZ_CLASSNAME);
}
}