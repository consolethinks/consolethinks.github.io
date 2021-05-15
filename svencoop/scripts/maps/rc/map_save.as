class map_save : ScriptBaseEntity
{
	int szMarkedOnly = 1;
	string saveDir = "scripts/maps/store/";
	string delimiter = " ";
	string fileContent = "";
	string szNextMap = "";
	
	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if(szKey == "nextmap") // name of the save file. map on which this data will get loaded
		{
			szNextMap = szValue;
			return true;
		}
		else if(szKey == "markedonly") // only affect entities marked with the "transitional" keyvalue set to "1"
		{
			szMarkedOnly = atoi( szValue );
			return true;
		}
		else
			return BaseClass.KeyValue( szKey, szValue );
	}
	
	void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
	{
		SaveBreakables();
		SavePushables();
		SaveDoors();
		Save();
	}
	
	void Save()
	{
		string saveFile = saveDir + szNextMap + ".dat";
		File@ file = g_FileSystem.OpenFile(saveFile, OpenFile::WRITE);
		
		if( file.IsOpen() )
		{			
			file.Write(fileContent);
			file.Close();	
			g_Game.AlertMessage( at_console, "saved. " + fileContent + "\n" );
			

		}
	}
	
	void SaveBreakables()
	{
		CBaseEntity@ pEntity = null;
		int entsFound = 0;

		while( (@pEntity = g_EntityFuncs.FindEntityByClassname(pEntity, "func_breakable")) !is null )
		{
			g_Game.AlertMessage( at_console, "found a breakable \n" );
			
			if( pEntity.pev.targetname != "" )
			{
				g_Game.AlertMessage( at_console, "brekable has a name: " + pEntity.pev.targetname + "\n" );
			
				CustomKeyvalues@ cks = pEntity.GetCustomKeyvalues();
				int iTransitional = cks.GetKeyvalue("$i_transitional").GetInteger();
				
				g_Game.AlertMessage( at_console, "brekable is transitional: " +  iTransitional + "\n" );

				if( iTransitional == 1 || szMarkedOnly == 0 )
				{
					entsFound++;
					fileContent = "" + fileContent + " " + pEntity.pev.targetname;
				}
			}
		}
		
		g_Game.AlertMessage( at_console, "" + entsFound + " breakables saved.\n" );
	}
	
	void SavePushables()
	{
		CBaseEntity@ pEntity = null;
		int entsFound = 0;

		while( (@pEntity = g_EntityFuncs.FindEntityByClassname(pEntity, "func_pushable")) !is null )
		{
			if( pEntity.pev.targetname != "" )
			{
				CustomKeyvalues@ cks = pEntity.GetCustomKeyvalues();
				int iTransitional = cks.GetKeyvalue("$i_transitional").GetInteger();

				if( iTransitional == 1 || szMarkedOnly == 0 )
				{
					entsFound++;
					fileContent = "" + fileContent + " " + pEntity.pev.targetname;
					fileContent = "" + fileContent + " " + pEntity.pev.origin.x;
					fileContent = "" + fileContent + " " + pEntity.pev.origin.y;
					fileContent = "" + fileContent + " " + pEntity.pev.origin.z;
				}
			}
			
		}
		
		g_Game.AlertMessage( at_console, "" + entsFound + " pushables saved.\n" );
	}
	
	void SaveDoors()
	{
		CBaseEntity@ pEntity = null;
		int entsFound = 0;

		while( (@pEntity = g_EntityFuncs.FindEntityByClassname(pEntity, "func_door")) !is null )
		{
			if( pEntity.pev.targetname != "" )
			{
				CustomKeyvalues@ cks = pEntity.GetCustomKeyvalues();
				int iTransitional = cks.GetKeyvalue("$i_transitional").GetInteger();

				if( iTransitional == 1 || szMarkedOnly == 0 )
				{
					entsFound++;
					CBaseDoor@ dDoor = cast<CBaseDoor@>( pEntity );
					fileContent = "" + fileContent + " " + pEntity.pev.targetname;
					fileContent = "" + fileContent + " " + dDoor.GetToggleState();
				}
			}			
		}
		
		g_Game.AlertMessage( at_console, "" + entsFound + " doors saved.\n" );
		
	}
}




class map_load : ScriptBaseEntity
{
	int szMarkedOnly = 1;
	string saveDir = "scripts/maps/store/";
	string delimiter = " ";
	array<string> splitContent = { "", "", "", "", "" };

	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if(szKey == "markedonly") // only affect entities marked with the "transitional" keyvalue set to "1"
		{
			szMarkedOnly = atoi( szValue );
			return true;
		}
		else
			return BaseClass.KeyValue( szKey, szValue );
	}

	void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
	{
		Load();
	}
	
	void Load()
	{
		string saveFile = saveDir + g_Engine.mapname + ".dat";
		File@ file = g_FileSystem.OpenFile(saveFile, OpenFile::READ);
		
		if( file !is null && file.IsOpen() )
		{
			string fileContent;
			file.ReadLine(fileContent);
			string emptyfileContent = "";
			file.Write(emptyfileContent);
			file.Close();
			
			splitContent = fileContent.Split(delimiter);
			
			LoadBreakables();
			LoadPushables();
			LoadDoors();
		}
	}
	
	void LoadBreakables()
	{
		CBaseEntity@ pEntity = null;
		int entsFound = 0;
	
		while( (@pEntity = g_EntityFuncs.FindEntityByClassname(pEntity, "func_breakable")) !is null )
		{
			bool entFound = false;

			CustomKeyvalues@ cks = pEntity.GetCustomKeyvalues();
			int iTransitional = cks.GetKeyvalue("$i_transitional").GetInteger();

			if( iTransitional == 1 || szMarkedOnly == 0 )
			{
				for(uint i = 0; i < splitContent.length(); i++)
				{
					if(splitContent[i] == pEntity.pev.targetname)
					{
						entFound = true;
						break;
					}
					else if( pEntity.pev.targetname == "" )
					{
						entFound = true;
						break;
					}
				}
				
				if(!entFound)
				{
					g_EntityFuncs.Remove( pEntity );
					entsFound++;
				}
			}
		}
		
		g_Game.AlertMessage( at_console, "" + entsFound + " breakables removed. \n" );
	}
	
	void LoadPushables()
	{
		CBaseEntity@ pEntity = null;
		int entsFound = 0;
	
		while( (@pEntity = g_EntityFuncs.FindEntityByClassname(pEntity, "func_pushable")) !is null )
		{
			bool entFound = false;
			
			CustomKeyvalues@ cks = pEntity.GetCustomKeyvalues();
			int iTransitional = cks.GetKeyvalue("$i_transitional").GetInteger();

			if( iTransitional == 1 || szMarkedOnly == 0 )
			{			
				for(uint i = 0; i < splitContent.length(); i++)
				{
					if(splitContent[i] == pEntity.pev.targetname)
					{
						entFound = true;
						pEntity.pev.origin = Vector( atof(splitContent[i+1]), atof(splitContent[i+2]), atof(splitContent[i+3]) );
						break;
					}
					else if( pEntity.pev.targetname == "" )
					{
						entFound = true;
						break;
					}
				}
			}
			
			if(!entFound)
			{
				g_EntityFuncs.Remove( pEntity );
				entsFound++;
			}
		}
		
		g_Game.AlertMessage( at_console, "" + entsFound + " pushables removed. \n" );
	}
	
	void LoadDoors()
	{
		CBaseEntity@ pEntity = null;
		int entsFound = 0;
	
		while( (@pEntity = g_EntityFuncs.FindEntityByClassname(pEntity, "func_door")) !is null )
		{
			bool entFound = false;
			
			CustomKeyvalues@ cks = pEntity.GetCustomKeyvalues();
			int iTransitional = cks.GetKeyvalue("$i_transitional").GetInteger();

			if( iTransitional == 1 || szMarkedOnly == 0 )
			{			
				for(uint i = 0; i < splitContent.length(); i++)
				{
					if(splitContent[i] == pEntity.pev.targetname)
					{
						entFound = true;
						CBaseDoor@ dDoor = cast<CBaseDoor@>( pEntity );
						dDoor.SetToggleState( atoi(splitContent[i+1]) );
						break;
					}	
				}
			}
			
			if(!entFound)
			{
				entsFound++;
			}
		}
		
		g_Game.AlertMessage( at_console, "" + entsFound + " doors set. \n" );
	}
	
}