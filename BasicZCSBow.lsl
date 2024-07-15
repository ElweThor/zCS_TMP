//##################################################################################\\
//                                       zCS Bow                                    \\
//                                   (C) zCS Team 2018                              \\
//                                                                                  \\
//      You must follow the license bundled with this software, in this case        \\
//      the LGPL v3.                                                                \\
//##################################################################################\\

// ## VARIABLES

key gCreatorKey = "a4a682fa-17d6-4d36-9944-2a96d8a0c405";

string gArrowPrefix = "MyArrow<";
string gArrowSuffix = "1.0>";
integer gArrowSalt = 1;
integer gArrowCode;
integer gArrowHash;
string gArrow = "S";

key gOwnerKey;
string gOwnerName;

// ## SYSTEM

integer gWeaponIsAuthenticated = TRUE;
integer gWeaponIsDrawn = FALSE;
integer gWeaponIsLocked = FALSE;
float gWeaponEyeOffset;
float gWeaponCustomOffset;

integer gTriggerDelaying = FALSE;
integer gTriggerSwung = FALSE;

integer gChannelMeterSheath = -458238;
integer gChannelSheath = -4337;

integer gChannelWeapon = 1;
integer gHandleWeapon;

integer gSettingsAutofire = FALSE;

// ## END SYSTEM
// ## WEAPON
string gWeaponDrawType = "bow";

integer gWeaponDrawAttachPoint = ATTACH_LHAND;
string gWeaponDrawAttachName = "left hand";

float gSpecArc = 25;
float gSpecDelay = 0.8;
float gSpecSpeed = 60;

float gSpecSensitivity = 0.50;

integer gSpecStancePrimary = 0;

list gSoundsCore =      [   "187b38a8-ad67-c1a0-5319-41e91a1eacf0",
                            "187b38a8-ad67-c1a0-5319-41e91a1eacf0",
                            "187b38a8-ad67-c1a0-5319-41e91a1eacf0"
                        ];

// ## END WEAPOM
// # LANGUAGE

list glLangStances =    [   "Short",
                            "Long",
                            "Lob"
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
    gOwnerName = llKey2Name ( gOwnerKey );

    initSecurity();

    llSetLinkPrimitiveParamsFast( LINK_SET, [PRIM_TEXT, "", ZERO_VECTOR, 0.0] );
    llLinkParticleSystem( LINK_SET, [] );
    gHandleWeapon = llListen( gChannelWeapon, "", gOwnerKey, "" );
    
    llListen( 1, "", gOwnerKey, "reset " +  gWeaponDrawType );

    llListen( gChannelMeterSheath, "", NULL_KEY, "");

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

    gArrowHash = (integer)("0x" + llGetSubString( llMD5String( llGetRegionName() + (string)gOwnerKey, 0), 2, 5)) + gArrowSalt;

    initRefresh();

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

    initRefresh();
}

initRefresh()
{
    vector l_agentSize = llGetAgentSize( gOwnerKey );
    gWeaponEyeOffset = 1 * ( l_agentSize.z / 2.0 );

    weaponRange( gSpecStancePrimary, TRUE );
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

            llTriggerSound( llList2Key( gSoundsCore , 0 ), 0.3);
            llOwnerSay( "Drawn");
            llSetLinkAlpha( LINK_SET, 1.0, ALL_SIDES );

            initControls( 1 );

            llRegionSayTo( gOwnerKey, gChannelMeterSheath, "sheathed" );
            llRegionSayTo( gOwnerKey, gChannelMeterSheath, "drawn " + gWeaponDrawType );
            llRegionSayTo( gOwnerKey, gChannelSheath, "drawn " + gWeaponDrawType );
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

            llRegionSayTo( gOwnerKey, gChannelSheath, "sheath " + gWeaponDrawType );
        }
    }
}

weaponRange( integer l_range, integer l_system )
{
    if ( l_range != gSpecStancePrimary || l_system )
    {
        if ( !l_system )
        {
            llOwnerSay( llList2String( glLangStances, l_range ) );
        }

        if ( l_range == 0 )
        {
            gSpecStancePrimary = 0;

            gSpecDelay = 0.8;
            gSpecSpeed = 60;

            gArrowCode = (integer)( (string)(f_toolFloatFormat(500 + gSpecArc) + "0" + (string)gArrowHash) );
            gArrow = gArrowPrefix + gArrowSuffix + "S";
        }
        else if ( l_range == 1 )
        {
            gSpecStancePrimary = 1;

            gSpecDelay = 0.9;
            gSpecSpeed = 60;

            gArrowCode = (integer)( (string)("600" + "0" + (string)gArrowHash) );
            gArrow = gArrowPrefix +  gArrowSuffix + "L";
        }
        else if ( l_range == 2 )
        {
            gSpecStancePrimary = 2;

            gSpecDelay = 0.8;
            gSpecSpeed = 35;

            gArrowCode = (integer)( (string)("325" + "0" + (string)gArrowHash) );
            gArrow = gArrowPrefix + gArrowSuffix  + "S";
        }
    }

    if ( gSettingsAutofire )
    {
       gSpecDelay += 0.05;
    }

    return;
}

weaponFire( rotation l_rot, vector l_pos )
{
    l_pos = l_pos + llRot2Fwd(l_rot);
    l_pos.z += gWeaponEyeOffset;
    l_pos.z += gWeaponCustomOffset;

    l_pos = l_pos + <0.20,0,0>*l_rot;

    if ( gWeaponIsDrawn )
    {
        llRezAtRoot( gArrow, l_pos, gSpecSpeed*llRot2Fwd(l_rot), l_rot, gArrowCode );
        llTriggerSound( llList2Key( gSoundsCore, 2 ), 0.9 );
    }
}
// ## END WEAPON
// ## COMMAND

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
    else if ( l_command == "drawsheath " + gWeaponDrawType )
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
                weaponRange( 1, FALSE );
            }
            else
            {
                weaponRange( 0, FALSE );
            }

            return;
        }
        else if ( l_command == "short" )
        {
            weaponRange( 0 , FALSE );

            return;
        }
        else if ( l_command == "long" )
        {
            weaponRange( 1 , FALSE );

            return;
        }
        else if ( l_command == "lob" )
        {
            weaponRange( 2, FALSE );

            return;
        }
        else if ( l_command == "autofire" )
        {
            gSettingsAutofire  = !gSettingsAutofire ;
            llOwnerSay( "Autofire: " + llList2String( glLangOptions, gSettingsAutofire ) );

            initRefresh();

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

                return;
            }
            else if ( l_command == "arc" )
            {
                if ( llList2String(l_variables, 1) == "")
                {
                    if ( (integer)gSpecArc % 25 == 0)
                    {
                        if ( gSpecArc == 50)
                        {
                            gSpecArc = -100;
                        }
                        else
                        {
                            gSpecArc = gSpecArc + 25;
                        }
                    }
                    else
                    {
                        gSpecArc = 0;
                    }
                }
                else if ( llList2Integer(l_variables, 1) <= 50 && llList2Integer(l_variables, 1) >= -100)
                {
                    gSpecArc = llList2Float(l_variables, 1);
                }

                llOwnerSay( "Arc: " + f_toolFloatFormat(gSpecArc) );

                initRefresh();
            }
            else if ( l_command == "height" )
            {
                if ( llList2String(l_variables, 1) == "")
                {
                    if ( (integer)(gWeaponCustomOffset * 100) % 5 == 0)
                    {
                        if ( gWeaponCustomOffset == 0.3)
                        {
                            gWeaponCustomOffset = 0.3;
                        }

                        else
                        {
                            gWeaponCustomOffset = gWeaponCustomOffset + 0.05;
                        }
                    }

                    else
                    {
                        gWeaponCustomOffset = 0;
                    }
                }

                else if ( llList2Float(l_variables, 1) <= 0.3 && llList2Float(l_variables, 1) >= -0.3)
                {
                    gWeaponCustomOffset = llList2Float(l_variables, 1);
                }

                llOwnerSay("Height Offset: " + f_toolFloatFormat(gWeaponCustomOffset));

                initRefresh();
                return;
            }
        }
    }
}

string s_commandStatus()
{
    string l_output;

    l_output    +=  "\nRange: "      +    llList2String( glLangStances, gSpecStancePrimary )
                +   "\nDelay: "      +    f_toolFloatFormat( gSpecDelay )
                +   "s\nArc: "      +    f_toolFloatFormat( gSpecArc )
                +   "\nSpeed: "      +    f_toolFloatFormat( gSpecSpeed )
                +   "m/s\nOffset: "      +    f_toolFloatFormat( gWeaponCustomOffset )
                +   "m\nSensitivity: "  +   f_toolFloatFormat(gSpecSensitivity * 100)
                +   "%\nAutofire: "      +    llList2String( glLangOptions, gSettingsAutofire )
                +   "\nChannel: "      +   (string)gChannelWeapon
                +   "\nArrow: "        +   gArrow
                +   "\nMemory: "       +  (string)llGetUsedMemory() + "/" + (string)llGetMemoryLimit() + " bytes"
                +   "\nYou can reset all settings using /1 reset " + gWeaponDrawType + ".";

    return l_output;
}

// ## END COMMAND
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

        if (( CONTROL_LBUTTON & l_pressed ) || ( CONTROL_LBUTTON & l_down ) || ( CONTROL_LBUTTON & l_released ))
        {
            return;
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
            if ( gSpecSensitivity == 0 )
            {
                return;
            }

            float l_sens = gSpecDelay - fl_time;

            if ( l_sens / gSpecDelay <= gSpecSensitivity )
            {
                gTriggerDelaying = TRUE;

                // No point using a timer event for a short delay.
                if ( l_sens > 0.10 || l_down )
                {
                    llSetTimerEvent( l_sens - 0.10 );
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

            gTriggerSwung = TRUE;
            gTriggerDelaying = FALSE;

            weaponFire( llGetCameraRot(), llGetPos() );
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

            weaponFire( llGetCameraRot(), llGetPos() );
        }

        llSetTimerEvent( 0 );
    }

    listen( integer l_channel, string l_name, key l_key, string l_body )
    {
        if ( !gWeaponIsAuthenticated )
        {
            initSecurity();

            return;
        }

        if ( l_channel == gChannelWeapon || l_channel == 1 )
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

                // Splash.
            }
        }
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
            if ( llGetOwner() != gCreatorKey )
            {
                llOwnerSay( "Please attach me to your " + gWeaponDrawAttachName + "." );

                llDetachFromAvatar();
                llSleep(1.0);
                llReleaseControls();
                llDie();
            }
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
    
    object_rez(key l_key)
    {
        llStartAnimation("shoot_l_bow");
    }
}
