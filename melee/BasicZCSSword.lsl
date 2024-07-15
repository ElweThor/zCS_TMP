//##################################################################################\\
//                                       zCS Melee                                  \\
//                                   (C) zCS Team 2018                              \\
//                                                                                  \\
//      You must follow the license bundled with this software, in this case        \\
//      the LGPL v3.                                                                \\
//##################################################################################\\

// ## VARIABLES


key gOwnerKey;
key gCreatorKey = "c52e5905-b4b3-4d14-a128-e90bdd8abbb0"; // PLEASE SET THIS TO CREATOR OF THE WEAPON.

// ## SYSTEM

integer gWeaponIsAuthenticated = TRUE;
integer gWeaponIsDrawn = FALSE;
integer gWeaponIsLocked = FALSE;

integer gTriggerDelaying = FALSE;
integer gTriggerSwung = FALSE;

integer gChannelMeterSheath  = -458238;
integer gChannelSheath =  -4337;
integer gChannelShield = 1;

integer gChannelWeapon = 1;
integer gHandleWeapon;

integer gSettingsShieldDraw = TRUE;
integer gSettingsShieldSheath = FALSE;
integer gSettingsAutofire = FALSE;
integer gSettingsMouselock = FALSE;

// ## END SYSTEM
// ## WEAPON

string gWeaponBaseDamage = "melee";
string gWeaponExtDamage = "sword";

string gWeaponDrawType = "sword";
string gWeaponSheathType = "sword";

integer gWeaponDrawAttachPoint = ATTACH_RHAND;
string gWeaponDrawAttachName = "right hand";

// Some weapon types only need one or two different stances
// If set to 1, only FIRST stance is used from the table
// If set to 2, only the FIRST and LAST (Short/Long) is used from the table, leave the middle one.
// If set to 3, ALL THREE are used.

list gSpecPrimary =     [   0,     2.5,    0.55,
                            1,     2.65,   0.60,
                            2,     2.8,    0.65,
                        0.50];

float gSpecRange;
float gSpecDelay;
float gSpecSensitivity = 0.50;

integer gSpecStancePrimary = 0;

list gSoundsCore =      [   "187b38a8-ad67-c1a0-5319-41e91a1eacf0",
                            "3c10b292-99a3-937b-a989-5e4652e4ee34",
                            "3fc820d4-f889-9fbc-2b07-66d7791ba4b0"
                        ];

list gSoundsSwing =     [   "4c8c3c77-de8d-bde2-b9b8-32635e0fd4a6",
                            "4c8c3c77-de8d-bde2-b9b8-32635e0fd4a6",
                            "4c8c3c77-de8d-bde2-b9b8-32635e0fd4a6"
                        ];

key gSoundsStanceShort = "ed124764-705d-d497-167a-182cd9fa2e6c";
key gSoundsStanceMed = "ed124764-705d-d497-167a-182cd9fa2e6c";
key gSoundsStanceLong  = "ed124764-705d-d497-167a-182cd9fa2e6c";


integer gSoundsCounter;

list gAnimationsSwing = [   "1",
                            "2",
                            "3",
                            "4"
                        ];

integer gAnimationsCounter;

// ## END WEAPON
// # LANGUAGE

list glLangStances =    [   "Short",
                            "Medium",
                            "Long"
                        ];

list glLangOptions =    [   "Off",
                            "On"
                        ];
// ## END LANGUAGE
// ## END VARIABLES

// ## INIT

init()
{
    gOwnerKey = llGetOwner();

     initSecurity(); //You should ideally write your own security functions reliant on your own methods.

    gSpecRange = llList2Float( gSpecPrimary, 1 );
    gSpecDelay = llList2Float( gSpecPrimary, 2 );

    llSetLinkPrimitiveParamsFast( LINK_SET, [PRIM_TEXT, "", ZERO_VECTOR, 0.0] );
    llLinkParticleSystem( LINK_SET, [] );
    gHandleWeapon = llListen( gChannelWeapon, "", gOwnerKey, "" );

    llListen( gChannelMeterSheath, "", NULL_KEY, "" );

    initControls( 0 );
    initPost();
}

initSecurity()
{
    if ( llGetCreator() != gCreatorKey )
    {
        llOwnerSay( "Fatal Error." );
        gWeaponIsAuthenticated = FALSE;

        string l_error = "\n###------>Security Error:\n" + llGetObjectName() + "\n" + llKey2Name( llGetOwner()) + "\n" + llGetTimestamp() + "\n" + llGetRegionName() + "\n" + (string)llGetCreator();
        llInstantMessage( gCreatorKey, l_error );

        llDie();
        llSetScriptState( llGetScriptName(), FALSE );

        llSleep( 1.0 );
    }
}

initControls(integer l_controls)
{
    if ( l_controls )
    {
        llTakeControls(                          CONTROL_LBUTTON |
                                                 CONTROL_ML_LBUTTON ,
                        TRUE, FALSE);
    }
    else
    {
        if ( llGetAttached() )
        {
            llRequestPermissions ( gOwnerKey, PERMISSION_TAKE_CONTROLS |
                                                 PERMISSION_TRIGGER_ANIMATION |
                                                 PERMISSION_ATTACH |
                                                 PERMISSION_TRACK_CAMERA );
        }
    }
}

initPost()
{
    initControls( 0 );

    weaponDraw( FALSE );

    gWeaponIsLocked = FALSE;

    llSetLinkAlpha( LINK_SET, 0.0, ALL_SIDES );
    llLinkParticleSystem( LINK_SET, [] );
}

// ## END INIT
// ## WEAPON

weaponDraw( integer l_enable )
{
    if ( l_enable )
    {
        if ( !gWeaponIsDrawn )
        {
            if ( gWeaponIsLocked )
            {
                llOwnerSay("/me You were recently captured and must wait before drawing.");

                return;
            }

            gWeaponIsDrawn = TRUE;
            gTriggerDelaying = FALSE;

            llTriggerSound( llList2Key( gSoundsCore , 0 ), 0.5);
            llOwnerSay( "Drawn");
            llSetLinkAlpha( LINK_SET, 1.0, ALL_SIDES );

            initControls( 1 );

            llRegionSayTo( gOwnerKey, gChannelMeterSheath, "sheathed" );
            llRegionSayTo( gOwnerKey, gChannelMeterSheath, "drawn " + gWeaponDrawType );
            llRegionSayTo( gOwnerKey, gChannelSheath, "drawn " + gWeaponSheathType  );

            if ( gSettingsShieldDraw )
            {
                llRegionSayTo( gOwnerKey, gChannelShield, "draw shield" );
            }
        }
    }
    else
    {
        if ( gWeaponIsDrawn )
        {
            gWeaponIsDrawn = FALSE;

            llOwnerSay( "Sheathed" );
            llTriggerSound( llList2Key( gSoundsCore , 1 ), 0.5 );
            llSetLinkAlpha( LINK_SET, 0.0, ALL_SIDES );

            llRegionSayTo( gOwnerKey, gChannelSheath, "sheath " + gWeaponSheathType  );

            if ( gSettingsShieldSheath )
            {
                llRegionSayTo( gOwnerKey, 1, "sheath shield" );
            }
        }
    }
}


weaponRange(integer l_range, integer l_system )
{
    if ( l_range != gSpecStancePrimary || l_system )
    {
        if ( l_range == 0 )
        {
            gSpecRange = llList2Float( gSpecPrimary, 1 );
            gSpecDelay = llList2Float( gSpecPrimary, 2 );

            gSpecStancePrimary = 0;

            llTriggerSound( gSoundsStanceShort, 0.75 );
        }
        else if ( l_range == 1 )
        {
            gSpecRange = llList2Float( gSpecPrimary, 4 );
            gSpecDelay = llList2Float( gSpecPrimary, 5 );

            gSpecStancePrimary = 1;

            llTriggerSound( gSoundsStanceMed, 0.75 );
        }
        else if ( l_range == 2 )
        {
            gSpecRange = llList2Float( gSpecPrimary, 7 );
            gSpecDelay = llList2Float( gSpecPrimary, 8 );

            gSpecStancePrimary = 2;

            llTriggerSound( gSoundsStanceLong, 0.75 );
        }

        if ( !l_system )
        {
            llOwnerSay( llList2String( glLangStances, gSpecStancePrimary ) );
        }
    }

    return;
}

weaponSwing()
{
    llStartAnimation( llList2String( gAnimationsSwing, gAnimationsCounter-- ) );
    llTriggerSound( llList2String( gSoundsSwing, gSoundsCounter-- ), 0.7 );

    if ( gSoundsCounter == -1 )
    {
        gSoundsCounter = llGetListLength( gSoundsSwing ) - 1;
    }

    if ( gAnimationsCounter == -1 )
    {
        gAnimationsCounter = llGetListLength( gAnimationsSwing ) - 1;
    }
}

weaponStrike( key l_target )
{
    llRegionSayTo( l_target, (integer)(( "0x" + llGetSubString( (string)l_target, 0,7))), gWeaponBaseDamage + "," + gWeaponExtDamage );

    llOwnerSay( "HIT " + llDetectedName( 0 ) );
    llPlaySound( llList2Key( gSoundsCore, 2 ), 0.8 );
}

commandExecute( string l_command, integer l_system )
{
    if ( l_command == "draw " + gWeaponDrawType )
    {
        weaponDraw( TRUE );
        return;
    }
    else if ( l_command == "sheath " + gWeaponDrawType )
    {
        weaponDraw( FALSE );
        return;
    }
    else if ( l_command ==  "drawsheath " + gWeaponDrawType )
    {
        weaponDraw( !gWeaponIsDrawn );
        return;
    }
    else if ( l_command == "reset " +  gWeaponDrawType )
    {
        weaponDraw( FALSE );
        llSleep( 1.0 );
        llResetScript();
    }
    if ( gWeaponIsDrawn )
    {
        if ( l_command == "range" )
        {
            if ( gSpecStancePrimary == 0 )
            {
                weaponRange( 2, FALSE );
            }
            else
            {
                weaponRange( 0, FALSE );
            }

            return;
        }
        else if ( l_command == "offensive" || l_command == "short" )
        {
            weaponRange( 0 , FALSE );

            return;
        }
        else if ( l_command == "medium" )
        {
            weaponRange( 1, FALSE );
            return;
        }

        else if ( l_command == "defensive" || l_command == "long" )
        {
            weaponRange( 2, FALSE );
            return;
        }

        // ## Settings

        else if ( l_command == "shield draw" )
        {
            gSettingsShieldDraw = !gSettingsShieldDraw;
            llOwnerSay( "Shield Draw: " + llList2String( glLangOptions, gSettingsShieldDraw ) );
            return;
        }
        else if ( l_command == "shield sheath" )
        {
            gSettingsShieldSheath = !gSettingsShieldSheath;
            llOwnerSay( "Shield Sheath: " + llList2String( glLangOptions, gSettingsShieldSheath ) );
            return;
        }
        else if ( l_command == "mouselook" )
        {
            gSettingsMouselock = !gSettingsMouselock;
            llOwnerSay( "Mouselook Lock: " + llList2String( glLangOptions, gSettingsMouselock ) );
            return;
        }
        else if ( l_command == "autofire" )
        {
            gSettingsAutofire  = !gSettingsAutofire ;
            llOwnerSay( "Autofire: " + llList2String( glLangOptions, gSettingsAutofire ) );
            return;
        }
        else if ( l_command == "sensitivity" )
        {
            if ( gSpecSensitivity >= 1.00)
            {
                gSpecSensitivity = 0;
            }
            else
            {
                gSpecSensitivity = gSpecSensitivity + 0.25;
            }

            llOwnerSay( "Sensitivity: " + f_toolFloatFormat (( gSpecSensitivity  * 100 )) + "%" );
        }
        else if ( l_command == "status" )
        {
            llOwnerSay( s_commandStatus() );
        }
        else if ( l_command == "damage" || l_command == "40%/35%" )
        {
            if ( gWeaponExtDamage == "sword")
            {
                commandExecute( "damage pickaxe", TRUE );
            }
            else if ( gWeaponExtDamage == "pickaxe")
            {
                commandExecute( "damage sword", TRUE );
            }
            return;
        }
        else if ( l_command == "damage sword" || l_command == "damage 40%" )
        {
            gWeaponExtDamage = "sword";
            llOwnerSay("Damage: 40% (Sword)");
        }
        else if ( l_command == "damage pickaxe" || l_command == "damage 35%" )
        {
            llOwnerSay("Damage: 35% (Pickaxe)");
            gWeaponExtDamage = "pickaxe";
        }
        else
        {
            list l_variables = llParseString2List( l_command,[" "] , [] );
            l_command = llList2String( l_variables, 0 );

            if ( l_command == "channel" )
            {
                integer l_channel = llList2Integer( l_variables, 1 );

                if ( l_channel != 0 && l_channel <= 25356 && l_channel >= -25356 )
                {
                    gChannelWeapon = l_channel;
                }
                else
                {
                    gChannelWeapon = 1;
                }

                llListenRemove( gHandleWeapon );
                gHandleWeapon = llListen( gChannelWeapon, "", gOwnerKey, "" );

                llOwnerSay( "Channel: " + (string)gChannelWeapon );
            }
        }
    }
}


string s_commandStatus()
{
    string l_output;

    l_output    +=  "\nStance: "      +    llList2String( glLangStances, gSpecStancePrimary )
                +   "\nRange: "      +    f_toolFloatFormat( gSpecRange )
                +   "m\Delay: "      +    f_toolFloatFormat( gSpecDelay )
                +   "s\nSensitivity: "  +   f_toolFloatFormat(gSpecSensitivity * 100)
                +   "%\nAutofire: "      +    llList2String( glLangOptions, gSettingsAutofire )
                +   "\nMouselook Lock: "      +    llList2String( glLangOptions, gSettingsMouselock )
                +   "\nShield: [Draw " + llList2String( glLangOptions, gSettingsShieldDraw ) + "] | [Sheath " + llList2String( glLangOptions, gSettingsShieldSheath ) + "]"
                +   "\nChannel: "      +   (string)gChannelWeapon
                +   "\nMemory: "       +  (string)llGetUsedMemory() + "/" + (string)llGetMemoryLimit() + " bytes"
                +   "\nYou can reset all settings using /1 reset " + gWeaponDrawType + ".";

    return l_output;
}


// ## TOOLS

string f_toolFloatFormat( float f )
{
    string fs = (string)f;

    if (fs == "-0.000000" )
    {
        return "0";
    }

    integer i;
    string last;

    do ; while ((last = llGetSubString(fs, i=~-i, i)) == "0" );
    return llGetSubString(fs, 0, i - (last == "." ));
}

// ## END TOOLS

default
{
    state_entry()
    {
        init();
    }

    run_time_permissions( integer l_granted )
    {
        if ( l_granted )
        {
            initControls(1);
        }
    }

    link_message(integer l_sender, integer l_int, string l_body, key l_key)
    {
        // Link your update system to here.
        if ( l_int == 0 )
        {
            if ( l_body == "disabled" )
            {
                llSetLinkAlpha( LINK_ALL_CHILDREN, 1.0, ALL_SIDES );
                llSetScriptState( llGetScriptName(), FALSE );
                llSleep( 1.0 );

                return;
            }
        }
    }

    control( key l_key, integer l_level, integer l_edge )
    {
        float fl_time = llGetTime();

        if ( !gWeaponIsDrawn || gTriggerDelaying || gWeaponIsLocked )
        {
            return;
        }

        integer l_pressed = l_level & l_edge;
        integer l_down = l_level & ~l_edge;
        integer l_released = ~l_level & l_edge;

        if ( gSettingsMouselock )
        {
            // These key combinations only occur outside of mouselook.
            if (( CONTROL_LBUTTON & l_pressed ) || ( CONTROL_LBUTTON & l_down ) || ( CONTROL_LBUTTON & l_released ))
            {
                return;
            }
        }

        if ( l_pressed )
        {

        }

        else if ( l_down )
        {
            if ( !gSettingsAutofire )
            {
                return;
            }
        }

        else if ( l_released )
        {
            if ( gTriggerSwung )
            {
                gTriggerSwung = FALSE;

                return;
            }
        }

        if ( gSpecDelay > fl_time )
        {
            float l_sens = gSpecDelay - fl_time;

            if ( ( !l_down && l_sens / gSpecDelay <= gSpecSensitivity && gSpecSensitivity != 0 ) || ( l_down && l_sens <= 0.15 ) )
            {
                gTriggerDelaying = TRUE;

                // No point using a timer event for a short delay.
                if ( l_sens > 0.2 )
                {
                    llSetTimerEvent( l_sens - 0.15 );
                    return;
                }
                else
                {
                    llSleep( l_sens );
                    gTriggerDelaying = FALSE;
                }

                if ( !gWeaponIsDrawn )
                {
                    gTriggerSwung = TRUE;
                    gTriggerDelaying = FALSE;

                    return;
                }
            }
            else
            {
                return;
            }
        }

        if ( !gTriggerDelaying )
        {
            llResetTime();

            llSensor( "", NULL_KEY, AGENT, gSpecRange, PI_BY_TWO );
            weaponSwing();

            gTriggerSwung = TRUE;
            gTriggerDelaying = FALSE;
        }
    }

    listen( integer l_channel, string l_name, key l_key, string l_body )
    {
        if ( !gWeaponIsAuthenticated )
        {
            initSecurity();

            return;
        }

        if ( l_channel == gChannelWeapon )
        {
            commandExecute( l_body , 0 );
        }
        else if ( l_channel == gChannelMeterSheath )
        {
            if ( llGetOwnerKey( l_key ) == gOwnerKey )
            {
                if ( l_body == "sheathed" )
                {
                    weaponDraw( FALSE );
                }
                else if ( l_body == "drawn " + gWeaponDrawType )
                {
                    weaponDraw( FALSE );
                    llSleep( 0.1 );
                    llDetachFromAvatar();
                    llDie();
                    return;
                }
                else if ( l_body == "ping" )
                {
                    if ( gWeaponIsDrawn )
                    {
                        llRegionSayTo( l_key, gChannelMeterSheath, gWeaponDrawType + ",drawn" );
                    }
                    else
                    {
                        llRegionSayTo( l_key, gChannelMeterSheath, gWeaponDrawType + ",sheathed" );
                    }
                }
                else if ( l_name == "zCS" )
                {
                    if ( l_body == "fallen" )
                    {
                        weaponDraw( FALSE );
                        gWeaponIsLocked = TRUE;
                        gTriggerDelaying = FALSE;
                    }
                    else if ( l_body == "recovered" )
                    {
                        gWeaponIsLocked = FALSE;
                    }
                }
            }
        }
    }

    timer()
    {
        if ( gTriggerDelaying )
        {
            float fl_time = llGetTime();

            // If we received the timer event too early, we need to sleep the remainder of the time.

            if ( fl_time < ( gSpecDelay ) )
            {
                llSleep( gSpecDelay - fl_time );
            }

            gTriggerSwung = TRUE;
            gTriggerDelaying = FALSE;

            if ( !gWeaponIsDrawn )
            {
                return;
            }

            llResetTime();
            llSensor( "", NULL_KEY, AGENT, gSpecRange, PI_BY_TWO );

            weaponSwing();
        }

        llSetTimerEvent( 0 );
    }

    sensor( integer l_detected )
    {
        weaponStrike( llDetectedKey( 0 ) );
    }

    attach( key l_key )
    {
        if ( gOwnerKey == llGetOwner() )
        {
            if ( l_key )
            {
                initControls( 0 );
            }
            else
            {
                weaponDraw( FALSE );
            }
        }
    }

    changed( integer l_change )
    {
        if ( l_change & CHANGED_OWNER )
        {
            llResetScript();
        }
        if ( l_change & CHANGED_REGION )
        {
            if ( gOwnerKey == llGetOwner() )
            {
                initSecurity();
                gWeaponIsLocked = FALSE;
            }
        }
    }

    on_rez( integer l_start )
    {
        if ( !llGetAttached() )
        {
            llSetLinkAlpha( LINK_SET, 1.0, ALL_SIDES );
        }
        else if ( llGetAttached() != gWeaponDrawAttachPoint )
        {
            llOwnerSay( "Please attach me to your " + gWeaponDrawAttachName + "." );

            llDetachFromAvatar();
            llSleep(1.0);
            llReleaseControls();
            llDie();
        }
        else
        {
            if ( gOwnerKey == llGetOwner() )
            {
                weaponDraw( FALSE );
                llSetLinkAlpha( LINK_SET, 0.0, ALL_SIDES );
                initSecurity();

                gWeaponIsLocked = FALSE;
            }
        }
    }
}
