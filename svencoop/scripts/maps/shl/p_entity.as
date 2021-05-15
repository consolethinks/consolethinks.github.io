class CPEntityController : ScriptBaseMonsterEntity
{

	void Spawn()
	{
		Precache();
		self.pev.movetype = MOVETYPE_NONE;
		self.pev.solid = SOLID_NOT;
		self.pev.body = 15;
		
		self.pev.sequence = 0;
		self.pev.frame = 0;
		self.ResetSequenceInfo();

	}

	void Precache()
	{
		
	}

	void FollowPlayer(CBasePlayer@ playerToFollow){

	g_EntityFuncs.SetOrigin( self, playerToFollow.GetOrigin() + g_Engine.v_forward * -15 + g_Engine.v_up * -15);
	
	Vector newAngle = Vector (-playerToFollow.pev.v_angle.x * 0.25,playerToFollow.pev.v_angle.y,playerToFollow.pev.v_angle.z);

	self.pev.angles = newAngle;
	
	}
	


//ANIMACIONES.

void SetAnimIdleLoop(){

	self.pev.sequence = 0;
	self.pev.frame = 0;
	self.ResetSequenceInfo();

}

void SetAnimAttack(){

	self.pev.sequence = 1;
	self.pev.frame = 0;
	self.ResetSequenceInfo();
	
	SetThink( ThinkFunction( this.SetAnimIdleLoop ) );
	self.pev.nextthink = g_Engine.time + 0.02;

}

void SetAnimAttackAlt(){

	self.pev.sequence = 2;
	self.pev.frame = 0;
	self.ResetSequenceInfo();
	
	SetThink( ThinkFunction( this.SetAnimIdleLoop ) );
	self.pev.nextthink = g_Engine.time + 0.02;

}


//FIN ANIMACIONES.


void DeletePEntity()
{

	g_EntityFuncs.Remove( self );

}




}

CPEntityController@ SpawnWeaponControllerInPlayer( CBasePlayer@ player, string weaponPlayer )
{
		
	CBaseEntity@ cbePEntity = g_EntityFuncs.CreateEntity( "PEntity", null,  false);
	CPEntityController@ PEntity = cast<CPEntityController@>(CastToScriptClass(cbePEntity));
	
	g_EntityFuncs.DispatchSpawn( PEntity.self.edict() );
	
	g_EntityFuncs.SetOrigin( PEntity.self, player.GetOrigin() + g_Engine.v_forward * -15 + g_Engine.v_up * -12.5);
	Vector newAngle = Vector (-player.pev.v_angle.x * 0.25,player.pev.v_angle.y,player.pev.v_angle.z);
	PEntity.pev.angles = newAngle;
	
	@PEntity.pev.owner = player.pev.pContainingEntity;
	@PEntity.pev.aiment = player.pev.pContainingEntity;
	PEntity.pev.movetype = MOVETYPE_FOLLOW;
	g_EntityFuncs.SetModel( PEntity.self, weaponPlayer );

	return PEntity;

}




void RegisterPEntity()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "CPEntityController", "PEntity" );
}