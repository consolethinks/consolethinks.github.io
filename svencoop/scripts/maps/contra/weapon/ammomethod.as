void ShootNormalBullet(CBaseEntity@ pOwner, Vector vecOrigin, Vector vecVelocity)
{
    CProjBullet@ pBullet = cast<CProjBullet@>(CastToScriptClass(g_EntityFuncs.CreateEntity( BULLET_REGISTERNAME, null,  false)));

    g_EntityFuncs.SetOrigin( pBullet.self, vecOrigin );
    @pBullet.pev.owner = @pOwner.edict();

    pBullet.pev.velocity = vecVelocity;
    pBullet.pev.angles = Math.VecToAngles( pBullet.pev.velocity );
    pBullet.szSprPath = BULLET_MDL1;
    
    pBullet.SetTouch( TouchFunction( pBullet.Touch ) );

    g_EntityFuncs.DispatchSpawn( pBullet.self.edict() );
}

void ShootMBullet(CBaseEntity@ pOwner, Vector vecOrigin, Vector vecVelocity)
{
    CProjBullet@ pBullet = cast<CProjBullet@>(CastToScriptClass(g_EntityFuncs.CreateEntity( BULLET_REGISTERNAME, null,  false)));

    g_EntityFuncs.SetOrigin( pBullet.self, vecOrigin );
    @pBullet.pev.owner = @pOwner.edict();

    pBullet.pev.velocity = vecVelocity;
    pBullet.pev.angles = Math.VecToAngles( pBullet.pev.velocity );
    
    pBullet.SetTouch( TouchFunction( pBullet.Touch ) );

    g_EntityFuncs.DispatchSpawn( pBullet.self.edict() );
}

void ShootSBullet(CBaseEntity@ pOwner, Vector vecOrigin, Vector vecVelocity)
{
    for(uint i = 0; i <= 4; i++)
    {
        CProjBullet@ pBullet = cast<CProjBullet@>(CastToScriptClass(g_EntityFuncs.CreateEntity( BULLET_REGISTERNAME, null,  false)));
        g_EntityFuncs.SetOrigin( pBullet.self, vecOrigin );
        @pBullet.pev.owner = @pOwner.edict();

        float x, y;
        g_Utility.GetCircularGaussianSpread( x, y );
        Math.MakeVectors( pOwner.pev.v_angle + pOwner.pev.punchangle );
        Vector vecAngles = g_Engine.v_forward * vecVelocity.Length() + 
                        (x * 1000 * AMMO_SACCURANCY.x * g_Engine.v_right + 
                            y * 1000 * AMMO_SACCURANCY.y * g_Engine.v_up);
        pBullet.pev.velocity = vecAngles;

        pBullet.SetTouch( TouchFunction( pBullet.Touch ) );
        pBullet.SetThink( ThinkFunction( pBullet.DelayTouch ) );
        pBullet.pev.nextthink = g_Engine.time + 1.0f;
        g_EntityFuncs.DispatchSpawn( pBullet.self.edict() );
        pBullet.pev.solid = SOLID_NOT;
    }
}

void ShootLBullet(CBaseEntity@ pOwner, Vector vecOrigin, Vector vecVelocity)
{
    for(uint i = 0; i <= 4; i++)
    {
        g_Scheduler.SetTimeout("ShootMBullet", 0.02 * i, @pOwner, vecOrigin, vecVelocity);
    }
}