RE: EVALUATION
DATE: 05 / 16 / (REDACTED)
TIME: 06:30

> GG-3883 SUBMITTED FOR ANALYSIS
> SUITABLE CANDIDATES SELECTED FOR EVALUATION
> OBSERVATION OF CANDIDATE #12 AUTHORIZED

PERMISSION TO PROCEED : GRANTED
RETRIEVAL OF CANDIDATE #12's SUBMISSION: COMPLETE


CRITICAL INFORMATION FOR SUCCESSFUL EXECUTION:

> ENSURE HALF-LIFE IS INSTALLED ON STEAM 
> (NOTE THAT THIS IS NOT COMPATIBLE WITH HALF-LIFE SOURCE)
>
> PLACE THE FOLDER "ECHOES" AND THE FILES "CG.DLL" AND "CGGL.DLL"
> INTO THE FOLDER 
> ..\STEAMAPPS\COMMON\HALF-LIFE
> FOR EXAMPLE 
> C:\PROGRAM FILES\STEAM\STEAMAPPS\COMMON\HALF-LIFE
>
> RESTART STEAM
>
> RUN HALF-LIFE ECHOES VIA THE STEAM GAME LIBRARY SHORTCUT
>
> ENSURE SOUNDTRACK VOLUME IS SET HIGH
>
> ENSURE SURROUNDINGS ARE DIMLY LIT
>
> PREPARE FOR UNFORESEEN CONSEQUENCES


TROUBLESHOOTING
This mod is designed for the current Steam version of Half-Life on Windows.
I cannot guarantee it will fully function any other way.

Ensure that you run the game using the "Half-Life: Echoes" game library shortcut in Steam.
This increases the entity limit and avoids the crash "ED_ALLOC: NO FREE EDICTS"
Do not load Half-Life and change to Echoes from within the game.
This will skip the command to allocate extra memory.

You can set this manually if you wish, by adding
-num_edicts 2048
To the Steam launch options for Half-Life: Echoes.
To do this, right click on the game title, and select properties.
Then go to the "General" tab, then "Set launch options".
Or alternatively, add this to the Half-Life launch options:
-game echoes -num_edicts 2048
Remember to remove this if you wish to play Half-Life normally.

If this fails, try to load a saved game from a previous map and try to continue from there.
Report any issues that cannot be fixed by the above to the moddb page.
https://www.moddb.com/mods/half-life-echoes

