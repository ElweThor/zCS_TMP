// ## WARNING: THIS SCRIPT WILL ONLY COMPILE IN FIRESTORM WITH LSL PRE-PROCESSOR ENABLED!!  ##

// DO NOT USE MONO!!!

//##################################################################################\\
//                                       zCS Arrow                                  \\
//                                   (C) zCS Team 2018                              \\
//                                                                                  \\
//      You must follow the license bundled with this software, in this case        \\
//      the LGPL v3.                                                                \\
//##################################################################################\\

// ## VARIABLES

#define gPrimarySecurityAlt "c52e5905-b4b3-4d14-a128-e90bdd8abbb0" // Set to creator avatar..

#define gArrowTimeout 0.65
#define gArrowSalt 1
#define gArrowSound "ed124764-705d-d497-167a-182cd9fa2e6c"
#define gArrowWeight 1.00
integer gArrowHash;

#define gWeaponBaseDamage  "sword"
#define gWeaponExtDamage "arrow~direct"
#define gWeaponExtDamageSplash "arrow"

integer gArrowHasHit = FALSE;
integer gArrowSplash = 0;
integer gArrowHasBeenRezzed = FALSE;


arrowStrike(key l_target, integer l_direct)
{
    if ( !gArrowHasHit )
    {
        integer l_targetChannel = (integer)( "0x" + llGetSubString( (string)l_target, 0,7) );
        string l_targetName = llKey2Name( l_target );

        if ( l_direct )
        {
            llRegionSayTo( l_target, l_targetChannel, gWeaponBaseDamage + "," + llKey2Name( llGetOwner() ) + "," + l_targetName + "," + gWeaponExtDamage );
            llOwnerSay( l_targetName );
            llTriggerSound( gArrowSound, 0.7 );
        }
        else
        {
            llRegionSayTo( l_target, l_targetChannel, gWeaponBaseDamage + "," + llKey2Name( llGetOwner() ) + "," + l_targetName + "," + gWeaponExtDamageSplash );
        }
    }

    gArrowHasHit = TRUE;
    llSetTimerEvent( gArrowTimeout );
}

default
{
    state_entry()
    {
        llSetBuoyancy( gArrowWeight );
        llCollisionSound("", 0.0);
        llCollisionSprite("");

        llSetLinkPrimitiveParamsFast( LINK_THIS, [PRIM_PHYSICS, TRUE, PRIM_PHANTOM, FALSE] );
        llSetStatus(STATUS_BLOCK_GRAB_OBJECT | STATUS_DIE_AT_EDGE, TRUE);
        llSetStatus(STATUS_ROTATE_X | STATUS_ROTATE_Y | STATUS_ROTATE_Z, FALSE);
    }

    timer()
    {
        llDie();
    }

    collision_start( integer l_detected )
    {
        llSetLinkPrimitiveParamsFast( LINK_THIS, [PRIM_PHYSICS, FALSE, PRIM_PHANTOM, TRUE] );

        if ( gArrowHasBeenRezzed )
        {
            if ( llDetectedType(0) & AGENT && llDetectedKey(0) != llGetOwner() || llDetectedName(0) == "Bow Tester~0.02" )
            {
                arrowStrike( llDetectedKey(0), TRUE );
            }
            else
            {
                llSensor("", NULL_KEY, AGENT, 3.5, PI);
            }
        }
    }

    land_collision_start( vector l_pos )
    {
        llSetLinkPrimitiveParamsFast( LINK_THIS, [PRIM_PHYSICS, FALSE, PRIM_PHANTOM, TRUE] );

        if ( gArrowHasBeenRezzed )
        {
            llSensor("", NULL_KEY, AGENT, 3.5, PI);
        }
    }

    on_rez( integer l_rez )
    {
        string l_rez = (string)l_rez;

        llSetBuoyancy( ( ((float)llGetSubString( l_rez, 0, 2 )) - 500) / 100);

        gArrowHash = (integer)("0x" + llGetSubString( llMD5String( (string)llGetOwner(), 0), 2, 5)) + gArrowSalt;


        if (  (integer)llGetSubString( l_rez, 4, -1 ) == gArrowHash && llGetCreator() == gPrimarySecurityAlt )
        {
            gArrowHasBeenRezzed = TRUE;
        }
        else
        {
            gArrowHasBeenRezzed = FALSE;
            llSetLinkPrimitiveParamsFast( LINK_THIS, [PRIM_PHYSICS, FALSE, PRIM_PHANTOM, TRUE] );

            llSetTimerEvent( gArrowTimeout );
            return;
        }

    }

    sensor(integer l_detected)
    {
        if ( llDetectedKey(0) != llGetOwner() )
        {
            arrowStrike( llDetectedKey(0) , FALSE);
        }
        else
        {
            if ( llDetectedKey(1) )
            {
                arrowStrike(llDetectedKey(1), FALSE );
            }
        }

        llSetTimerEvent( gArrowTimeout );
    }

    no_sensor()
    {
        llSetTimerEvent( gArrowTimeout );
    }

    attach( key l_key )
    {
        if ( l_key )
        {
            if ( llGetOwner() != gPrimarySecurityAlt )
            {
                llSetScriptState( llGetScriptName(), FALSE );
            }
            else
            {
                llResetScript();
            }
        }
    }
}
