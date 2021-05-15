namespace ContraGunWagon
{
const int SENTY_TURNRATE = 45;//每0.1秒选择角度
const int SENTY_MAXWAIT = 15;
const float SENTY_FIRERATE = 0.2f;
const float SENTY_CHILDRANGE = 2048;
const string SENTRY_CHILDMODEL = "models/turret.mdl";
const string SENTRY_CHILFFIRESND = "sc_contrahdl/hdl_shot_2.wav";
const string SENTRY_SHELLMODEL = "models/saw_shell.mdl";
const int SENTRY_HEALTH = 150;
const int SENTRY_DMG = 10;
const float SENTRY_BULLETSPEED = 512;
const float SENTRY_FIREANGLE = 0.996; //cos0.1°
const string SENTRY_CLASSNAME = "monster_gunwagon";

enum TURRET_ANIM
{
	SENTY_ANIM_NONE = 0,
	SENTY_ANIM_FIRE,
	SENTY_ANIM_SPIN,
	SENTY_ANIM_DEPLOY,
	SENTY_ANIM_RETIRE,
	SENTY_ANIM_DIE,
};

class CCustomSentry : ScriptBaseMonsterEntity
{
    int iShell;
	int iMinPitch =  -60;

	bool bIsActived;
    bool bIsEnemyVisible;

	float flLastSight;
    float fTurnRate;
    float flShootTime;

    Vector vecLastSight;
	Vector vecCurAngles;
	Vector vecGoalAngles;
	
	void Spawn()
	{
		Precache();
        self.MonsterInit();

		self.pev.movetype = MOVETYPE_FLY;
		self.pev.sequence = 0;
		self.pev.frame = 0;
		self.pev.solid = SOLID_SLIDEBOX;
		self.pev.takedamage = DAMAGE_YES;
        self.m_bloodColor = DONT_BLEED;

		self.pev.scale = 1;

		self.ResetSequenceInfo();
		self.SetBoneController(0, 0);
		self.SetBoneController(1, 0);
		self.m_flFieldOfView = VIEW_FIELD_FULL;
        self.m_flDistLook = SENTY_CHILDRANGE;
		
		g_EntityFuncs.SetModel( self, SENTRY_CHILDMODEL );
		self.pev.health = SENTRY_HEALTH;
		self.pev.max_health = self.pev.health;
		self.m_HackedGunPos = Vector(0,0,48);
		self.pev.view_ofs.z = 48;

        if(self.m_FormattedName == "")
            self.m_FormattedName = "Sentry";
            
		g_EntityFuncs.SetSize( self.pev, Vector(-16, -16, 0), Vector(16, 16, 32) );

        vecGoalAngles.x = 0;

		flLastSight = g_Engine.time + SENTY_MAXWAIT;

		SetThink( ThinkFunction( this.AutoSearchThink ) );
		self.pev.nextthink = g_Engine.time + 1; 
	}

    int	Classify()
	{
		return self.GetClassification( CLASS_ALIEN_MONSTER );
	}

    float TrimAngle(float vecTrim)
    {
        if(vecTrim >= 360)
            vecTrim -= 360;
        if(vecTrim <= 0)
            vecTrim += 360;
        return vecTrim;
    }

	void Precache()
	{  
        g_Game.PrecacheModel( SENTRY_CHILDMODEL );
        g_Game.PrecacheGeneric( SENTRY_CHILDMODEL );

        g_SoundSystem.PrecacheSound( SENTRY_CHILFFIRESND );
        g_Game.PrecacheGeneric( SENTRY_CHILFFIRESND );

        iShell = g_Game.PrecacheModel( SENTRY_SHELLMODEL );
        g_Game.PrecacheGeneric( SENTRY_SHELLMODEL );
	}

    int MoveTurret()
	{
		int state = 0;
		if( vecCurAngles.x != vecGoalAngles.x )
		{
			float flDir = vecGoalAngles.x > vecCurAngles.x ? 1 : -1 ;

			vecCurAngles.x += 0.1 * fTurnRate * flDir;

			if( flDir == 1 )
			{
				if( vecCurAngles.x > vecGoalAngles.x )
					vecCurAngles.x = vecGoalAngles.x;
			} 
			else
			{
				if( vecCurAngles.x < vecGoalAngles.x )
					vecCurAngles.x = vecGoalAngles.x;
			}

				self.SetBoneController( 1, -vecCurAngles.x );
			state = 1;
		}

		if( vecCurAngles.y != vecGoalAngles.y )
		{
			float flDir = vecGoalAngles.y > vecCurAngles.y ? 1 : -1 ;
			float flDist = abs( vecGoalAngles.y - vecCurAngles.y );
			
			if( flDist > 180 )
			{
				flDist = 360 - flDist;
				flDir = -flDir;
			}
			if( flDist > 30 )
			{
				if( fTurnRate < SENTY_TURNRATE * 10 )
				{
					fTurnRate += SENTY_TURNRATE;
				}
			}
			else if( fTurnRate > 45 )
			{
				fTurnRate -= SENTY_TURNRATE;
			}
			else
			{
				fTurnRate += SENTY_TURNRATE;
			}

			vecCurAngles.y += 0.1 * fTurnRate * flDir;

            vecCurAngles.y = TrimAngle(vecCurAngles.y);

			if( flDist < (0.05 * SENTY_TURNRATE) )
				vecCurAngles.y = vecGoalAngles.y;

				self.SetBoneController( 0, vecCurAngles.y - pev.angles.y );
			state = 1;
		}

		if( state == 0 )
			fTurnRate = SENTY_TURNRATE;

		return state;
	}
     
    void SetSearch()
    {
        self.m_hEnemy = null;
		flLastSight = g_Engine.time + SENTY_MAXWAIT;
		SetThink( ThinkFunction( this.SearchThink ) );
    }

    int TakeDamage( entvars_t@ pevInflictor, entvars_t@ pevAttacker, float flDamage, int bitsDamageType)
	{	
		if(pevAttacker is null)
			return 0;

        g_Utility.Ricochet(self.Center(), 1);
		return BaseClass.TakeDamage(pevInflictor, pevAttacker, flDamage, bitsDamageType);
	}

    void Killed(entvars_t@pevAtttacker, int iGibbed)
    {
        self.pev.solid = SOLID_NOT;
		self.pev.takedamage = DAMAGE_NO;

        SetThink( ThinkFunction( KillThink ) );
        self.pev.nextthink = g_Engine.time;
    }

    void KillThink()
	{
        SetThink( ThinkFunction( Explosion ) );
        SetTurretAnim( SENTY_ANIM_DIE );
        self.pev.nextthink = g_Engine.time + 3;
    }

    void Explosion()
    {
        g_EntityFuncs.CreateExplosion(self.Center(), self.pev.angles, self.edict(), 25, true);
        g_EntityFuncs.Remove(self);
    }
    
	void ActiveThink()
	{
		bool fAttack = false;
		Vector vecDirToEnemy;

		self.pev.nextthink = g_Engine.time + 0.1;
		self.StudioFrameAdvance();

		if( !bIsActived || self.m_hEnemy.GetEntity() is null )
		{
			SetSearch();
			return;
		}

		if( !self.m_hEnemy.GetEntity().IsAlive() )
		{
			if( flLastSight <= 0.0 )
				flLastSight = g_Engine.time;
			else
			{
				if( g_Engine.time > flLastSight )
				{ 
					SetSearch();
				    return;
				}
			}
		}

		Vector vecMid = self.pev.origin + self.pev.view_ofs;
		Vector vecMidEnemy = self.m_hEnemy.GetEntity().BodyTarget( vecMid );

		bIsEnemyVisible = self.m_hEnemy.GetEntity().FVisible( self, true );
		vecDirToEnemy = vecMidEnemy - vecMid;
		float flDistToEnemy = vecDirToEnemy.Length();
		Vector vec = Math.VecToAngles( vecMidEnemy - vecMid );

		if( !bIsEnemyVisible || flDistToEnemy > SENTY_CHILDRANGE )
		{
			if( flLastSight <= 0.0 )
				flLastSight = g_Engine.time;
			else
			{
				if( g_Engine.time > flLastSight )
				{
					SetSearch();
					return;
				}
			}
			bIsEnemyVisible = false;
		}
		else
			vecLastSight = vecMidEnemy;

		Math.MakeAimVectors( vecCurAngles );

		Vector vecLOS = vecDirToEnemy;
		vecLOS = vecLOS.Normalize();

		if( DotProduct(vecLOS, g_Engine.v_forward) <= SENTRY_FIREANGLE )
			fAttack = false;
		else
			fAttack = true;

		if( fAttack )
		{
			Vector vecSrc, vecAng;
			self.GetAttachment( 0, vecSrc, vecAng );
			Shoot( vecSrc, g_Engine.v_forward );
		}
		else
			SetTurretAnim( SENTY_ANIM_SPIN );

		if( bIsEnemyVisible )
		{
            vec.y = TrimAngle(vec.y);

			if( vec.x < -180 )
				vec.x += 360;

			if( vec.x > 180 )
				vec.x -= 360;

				if( vec.x > 90 )
					vec.x = 90;
				else if( vec.x < iMinPitch )
					vec.x = iMinPitch;

			vecGoalAngles.y = vec.y;
			vecGoalAngles.x = vec.x;
		}
		MoveTurret();
	}

	void Deploy()
	{
		self.pev.nextthink = g_Engine.time + 0.1;
		self.StudioFrameAdvance();

		if( self.pev.sequence != SENTY_ANIM_DEPLOY )
		{
			bIsActived = true;
			SetTurretAnim( SENTY_ANIM_DEPLOY );
			self.SUB_UseTargets( self, USE_ON, 0 );
        }

		if( self.m_fSequenceFinished )
		{
			vecCurAngles.x = 0;

			SetTurretAnim( SENTY_ANIM_SPIN );
			self.pev.framerate = 0;
			SetThink( ThinkFunction( SearchThink ) );
		}
		flLastSight = g_Engine.time + SENTY_MAXWAIT;
	}

	void SetTurretAnim( int anim )
	{
		if( self.pev.sequence != anim )
		{
			switch( anim )
			{
                case SENTY_ANIM_FIRE:break;
                case SENTY_ANIM_SPIN:
                    if( self.pev.sequence != SENTY_ANIM_FIRE && self.pev.sequence != SENTY_ANIM_SPIN )
                        self.pev.frame = 0;
                    break;
                default:self.pev.frame = 0;break;
			}

			self.pev.sequence = anim;
			self.ResetSequenceInfo();

			switch( anim )
			{
			    case SENTY_ANIM_RETIRE:self.pev.frame = 255;self.pev.framerate = -1.0; break;
                case SENTY_ANIM_DIE:self.pev.framerate = 1.0;break;
			}
		}
	}

    CBaseEntity@ FindClosestEnemy( float fRadius )
	{
		CBaseEntity@ ent = null;
		CBaseEntity@ enemy = null;
        float iNearest = fRadius;
		do
		{
			@ent = g_EntityFuncs.FindEntityInSphere( ent, self.pev.origin, fRadius, "player", "classname" ); 
			if ( ent is null || !ent.IsAlive() )
				continue;
	
			if ( ent.entindex() == self.entindex() )
				continue;
				
			if ( ent.edict() is self.pev.owner )
				continue;
				
			int rel = self.IRelationship(ent);
			if ( rel == R_AL || rel == R_NO )
				continue;

            if(!ent.FVisible(self, true))
                continue;

			float iDist = ( ent.pev.origin - self.pev.origin ).Length();
			if ( iDist < iNearest )
			{
				iNearest = iDist;
				@enemy = ent;
			}
		}
		while ( ent !is null );
		return enemy;
	}

	void Shoot( Vector& in vecSrc, Vector& in vecDirToEnemy )
	{
		if( g_Engine.time >= flShootTime )
		{
			Math.MakeVectors( vecCurAngles );
            CProjBullet@ pBullet = ShootABullet(self, vecSrc, vecDirToEnemy * SENTRY_BULLETSPEED);
            pBullet.self.pev.dmg = SENTRY_DMG;

            g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, SENTRY_CHILFFIRESND, 1, ATTN_NORM, 0, 94 + Math.RandomLong( 0, 0xF ) );

            g_EntityFuncs.EjectBrass( 
			vecSrc, 
			g_Engine.v_right * Math.RandomLong(80,160) + g_Engine.v_forward * Math.RandomLong(-20,80) + self.pev.velocity, 
			vecCurAngles.y, 
			iShell, 
			TE_BOUNCE_SHELL );

			SetTurretAnim(SENTY_ANIM_FIRE);

			flShootTime = g_Engine.time + SENTY_FIRERATE;
		}
	}

    void CheckValidEnemy()
    {
        if( self.m_hEnemy.GetEntity() !is null )
		{
			if( !self.m_hEnemy.GetEntity().IsAlive() )
				self.m_hEnemy = null;
		}

		if( self.m_hEnemy.GetEntity() is null )
		{
			self.Look( SENTY_CHILDRANGE );
			self.m_hEnemy = FindClosestEnemy(SENTY_CHILDRANGE);
		}
    }

	void SearchThink()
	{
		SetTurretAnim( SENTY_ANIM_SPIN );
		self.StudioFrameAdvance();
		
		CheckValidEnemy();

		if( self.m_hEnemy.GetEntity() !is null )
		{
			flLastSight = 0;
			SetThink( ThinkFunction( this.ActiveThink ) );
		}
		else
		{
			vecGoalAngles.y = (vecGoalAngles.y + 0.1 * fTurnRate);
            vecGoalAngles.y = TrimAngle(vecGoalAngles.y);
			MoveTurret();
		}

        self.pev.nextthink = g_Engine.time + 0.1;
	}

	void AutoSearchThink()
	{
		self.StudioFrameAdvance();
		
		CheckValidEnemy();

		if( self.m_hEnemy.GetEntity() !is null )
			SetThink( ThinkFunction( this.Deploy ) );

        self.pev.nextthink = g_Engine.time + 0.3;
	}
}
void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "ContraGunWagon::CCustomSentry", SENTRY_CLASSNAME );
	g_Game.PrecacheOther(SENTRY_CLASSNAME);
}
}