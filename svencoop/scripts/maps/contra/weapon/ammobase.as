Vector AMMO_SACCURANCY = VECTOR_CONE_20DEGREES;

array<CAmmoType@> aryAmmoType = {};
funcdef void FireMethod (CBaseEntity@ pOwner, Vector vecOrigin, Vector vecVelocity);
class CAmmoType
{
    string Name;
    float FireInter;
    string FireSnd;
    Vector Accurency;
    FireMethod@ Method;

    CAmmoType(string _Name, float _FireInter, FireMethod@ _Method)
    {
        Name = _Name;
        FireInter = _FireInter;
        @Method = @_Method;
    }
}

CAmmoType@ GetAmmo(string Name)
{
    for(uint i = 0; i < aryAmmoType.length(); i++)
    {
        if(aryAmmoType[i].Name == Name)
            return aryAmmoType[i];
    }
    return null;
}

void RegisteAmmo (string _Name, float _FireInter, FireMethod@ _Method)
{
    aryAmmoType.insertLast(CAmmoType(_Name, _FireInter, _Method));
}

class NAmmo : CBaseAmmoEntity
{
    NAmmo()
    {
        szMdlPath = "sprites/contra/n.spr";
        @m_iType = GetAmmo("N");
    }
}

class MAmmo : CBaseAmmoEntity
{
    MAmmo()
    {
        szMdlPath = "sprites/contra/m.spr";
        @m_iType = GetAmmo("M");
    }
}

class SAmmo : CBaseAmmoEntity
{
    SAmmo()
    {
        szMdlPath = "sprites/contra/s.spr";
        @m_iType = GetAmmo("S");
    }
}

class LAmmo : CBaseAmmoEntity
{
    LAmmo()
    {
        szMdlPath = "sprites/contra/l.spr";
        @m_iType = GetAmmo("L");
    }
}

class CBaseAmmoEntity : ScriptBaseAnimating
{
    protected string szMdlPath = "sprites/contra/r.spr";
    protected string szPickUpPath = "items/gunpickup2.wav";
    protected float flSize = 6;
	protected CAmmoType@ m_iType;
	void Spawn()
	{ 
		Precache();
		if( !self.SetupModel() )
			g_EntityFuncs.SetModel( self, szMdlPath );
		else
			g_EntityFuncs.SetModel( self, self.pev.model );

        self.pev.movetype 		= MOVETYPE_NONE;
		self.pev.solid 			= SOLID_TRIGGER;

		g_EntityFuncs.SetSize(self.pev, Vector( -flSize, -flSize, -flSize ), Vector( flSize, flSize, flSize ));
        //SetTouch(TouchFunction(this.Touch));

        BaseClass.Spawn();
	}
	
	void Precache()
	{
		BaseClass.Precache();

        string szTemp = string( self.pev.model ).IsEmpty() ? szMdlPath : string(self.pev.model);
        g_Game.PrecacheModel( szTemp );
		g_SoundSystem.PrecacheSound(szPickUpPath);

        g_Game.PrecacheGeneric( szTemp );
        g_Game.PrecacheGeneric( "sound/" + szPickUpPath );
	}

    void SetAnim( int animIndex ) 
	{
		self.pev.sequence = animIndex;
		self.pev.frame = 0;
		self.ResetSequenceInfo();
	}
	
    void Touch(CBaseEntity@ pOther)
    {
        if(pOther.IsAlive() && pOther.IsPlayer() && pOther.IsNetClient())
        {
            CBasePlayer@ pPlayer = cast<CBasePlayer@>(pOther);
            if(pPlayer !is null && pPlayer.IsConnected())
            {
                CContraWeapon@ pWeapon = cast<CContraWeapon@>(CastToScriptClass(pPlayer.HasNamedPlayerItem("weapon_contra")));
                if(pWeapon is null)
                    return;

                @pWeapon.m_iAmmoType = @m_iType;
                g_EntityFuncs.Remove(self);
            }
        }
    }
}