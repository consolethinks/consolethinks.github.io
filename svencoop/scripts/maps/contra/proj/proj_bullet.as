string BULLET_REGISTERNAME = "contra_bullet";
float BULLET_DEFAULT_SPEED = 800;
string BULLET_MDL1 = "sprites/contra/contra_bullet1.spr";
string BULLET_MDL2 = "sprites/contra/contra_bullet2.spr";
float BULLET_DEFAULTDMG = 30;

class CProjBullet : ScriptBaseAnimating
{
    string szSprPath = BULLET_MDL2;
    string szHitSound = "common/null.wav";
    float flSpeed = BULLET_DEFAULT_SPEED;
    float flScale = 0.5f;
    int iDamageType = DMG_BULLET;

    Vector vecHullMin = Vector(-4, -4, -4);
    Vector vecHullMax = Vector(4, 4, 4);

    Vector vecVelocity = Vector(0, 0, 0);
    Vector vecColor = Vector(255, 255, 255);

    void Spawn()
	{	
        if(self.pev.owner is null)
            return;

        Precache();

		pev.movetype = MOVETYPE_FLYMISSILE;
		pev.solid = SOLID_SLIDEBOX;

        self.pev.framerate = 1.0f;
        //self.pev.rendermode = kRenderNormal;
        //self.pev.renderamt = 255;
        //self.pev.rendercolor = vecColor;
		
		self.pev.model = szSprPath;
        self.pev.scale = flScale;
        self.pev.speed = flSpeed;
        self.pev.dmg = BULLET_DEFAULTDMG;

        g_EngineFuncs.MakeVectors(self.pev.angles);
		//self.pev.velocity = g_Engine.v_forward * self.pev.speed;
        vecVelocity = self.pev.velocity;

		g_EntityFuncs.SetModel( self, self.pev.model );
		g_EntityFuncs.SetSize(self.pev, vecHullMin, vecHullMax);
        g_EntityFuncs.SetOrigin( self, self.pev.origin );

        self.pev.nextthink = g_Engine.time + 0.1f;
	}
    
    void Think()
    {
        self.pev.velocity = vecVelocity;
        self.pev.nextthink = g_Engine.time + 0.1f;
    }

    void SetAnim( int animIndex ) 
	{
		self.pev.sequence = animIndex;
		self.pev.frame = 0;
		self.ResetSequenceInfo();
	}

    void DelayTouch()
    {
        self.pev.solid = SOLID_SLIDEBOX;
        SetThink( ThinkFunction( this.Think ) );
        self.pev.nextthink = g_Engine.time + 0.1f;
    }

    void Precache()
    {
        BaseClass.Precache();
		
        string szTemp = string( self.pev.model ).IsEmpty() ? szSprPath : string(self.pev.model);
		g_Game.PrecacheModel( szTemp );
        g_Game.PrecacheGeneric( szTemp );

        g_Game.PrecacheModel( BULLET_MDL1 );
        g_Game.PrecacheGeneric( BULLET_MDL1 );
        g_Game.PrecacheModel( BULLET_MDL2 );
        g_Game.PrecacheGeneric( BULLET_MDL2 );

        g_SoundSystem.PrecacheSound( szHitSound );
        g_Game.PrecacheGeneric( "sound/" + szHitSound );
    }

    void Touch( CBaseEntity@ pOther )
	{
		if( self.GetClassname() == pOther.GetClassname() || pOther.edict() is self.pev.owner)
        {
            self.pev.velocity = g_Engine.v_forward * self.pev.speed;
            return;
        }
        
        if(pOther.IsAlive())
            pOther.TakeDamage( self.pev, self.pev.owner.vars, self.pev.dmg, iDamageType);

        g_SoundSystem.EmitSound( self.edict(), CHAN_AUTO, szHitSound, 1.0f, ATTN_NONE );
        g_EntityFuncs.Remove(self);
	}
}

CProjBullet@ ShootABullet(CBaseEntity@ pOwner, Vector vecOrigin, Vector vecVelocity)
{
    CProjBullet@ pBullet = cast<CProjBullet@>(CastToScriptClass(g_EntityFuncs.CreateEntity( BULLET_REGISTERNAME, null,  false)));

    g_EntityFuncs.SetOrigin( pBullet.self, vecOrigin );
    @pBullet.pev.owner = @pOwner.edict();

    pBullet.pev.velocity = vecVelocity;
    pBullet.pev.angles = Math.VecToAngles( pBullet.pev.velocity );
    
    pBullet.SetTouch( TouchFunction( pBullet.Touch ) );

    g_EntityFuncs.DispatchSpawn( pBullet.self.edict() );

    return pBullet;
}