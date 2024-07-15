//##################################################################################\\
//                                       zCS Melee                                  \\
//                                   (C) zCS Team 2018                              \\
//                                                                                  \\
//      You must follow the license bundled with this software, in this case        \\
//      the LGPL v3.                                                                \\
//##################################################################################\\

key gOwnerKey;
#define gMemoryLimit 18538

string gSoundShieldDraw = "5d7c6435-c21e-776f-1fb4-30e6ead007cd";
string gSoundShieldSheath = "26ccfe39-dbbc-fea8-2214-3780ee834779";
string gSoundShieldBlock = "6b3d6897-8dd6-0d7b-d408-6ca541898452";

string gAnimShieldDraw = "";
string gAnimShieldSheath = "";
string gAnimShieldBlock = "";

string gConfigurationNotecard = "Shield Params";
integer gConfigurationLine;
key gKey;

integer gConfigurationDrawn = FALSE;

#define gWeaponSheathPart LINK_SET
#define gWeaponChannel 1
#define gShieldChannel -452239
#define gWeaponSheathPart LINK_SET
integer gWeaponIsShown = FALSE;

init()
{
    llSetMemoryLimit( gMemoryLimit );
    
    gOwnerKey = llGetOwner();
    
    llListen( gWeaponChannel, "", NULL_KEY, "draw shield" );
    llListen( gWeaponChannel, "", NULL_KEY, "sheath shield" );

    #if gWeaponIsSheath != 1
        llListen( gShieldChannel, "", NULL_KEY, "" );
        llWhisper( gWeaponChannel, "sheath shield" ); 
    #endif
    
    if ( llGetInventoryType( gConfigurationNotecard ) == INVENTORY_NOTECARD )
    {
        gConfigurationLine = 0;
        gKey = llGetNotecardLine( gConfigurationNotecard, gConfigurationLine );
    }
    
    if ( llGetAttached() )
    {
        llRequestPermissions( gOwnerKey, PERMISSION_TAKE_CONTROLS | PERMISSION_TRIGGER_ANIMATION ); 
    } 
}

shieldDraw( integer l_enable )
{
    #if gWeaponIsSheath == 1
        l_enable = !l_enable;
    #endif
    
    if ( l_enable && !gWeaponIsShown )
    {
        gWeaponIsShown = TRUE;
        llSetLinkAlpha( gWeaponSheathPart, 1.0, ALL_SIDES );        
        
        if ( gSoundShieldDraw != "" )
        {
            llTriggerSound( gSoundShieldDraw, 1.0 );
        }
        
        if ( gAnimShieldDraw != "" )
        {
            llStartAnimation( gAnimShieldDraw );
        }    
        
    }
    else if ( gWeaponIsShown )
    {
        gWeaponIsShown = FALSE;
        llSetLinkAlpha( gWeaponSheathPart, 0.0, ALL_SIDES );     
        
        if ( gSoundShieldSheath != "" )
        {
            llTriggerSound( gSoundShieldSheath, 1.0 );
        }           
        
        if ( gAnimShieldSheath != "" )
        {
            llStartAnimation( gAnimShieldSheath );
        }     
    }
}

default
{
    state_entry()
    {
        init();
    }

    listen( integer l_channel, string l_name, key l_key, string l_body )
    {
        if ( gOwnerKey == llGetOwnerKey( l_key ) || gOwnerKey == l_key )
        {
            if ( l_channel == gWeaponChannel )
            {
                if ( l_body == "draw shield" )
                {
                    shieldDraw( TRUE );                    
                }
                else if ( l_body == "sheath shield" )    
                {
                    shieldDraw( FALSE );
                }
            }
            else if ( l_channel == gShieldChannel )
            {
                if ( l_body == "block" )
                {
                    if ( gSoundShieldBlock != "" )
                    {
                        llTriggerSound( gSoundShieldBlock, 1.0 );
                    }                    
                }
            }
        }
    }
    
    #if gWeaponIsSheath != 1
    attach( key l_key )
    {
        llReleaseControls();
        
        if ( llGetOwner() == gOwnerKey )
        {
            llRequestPermissions( gOwnerKey, PERMISSION_TAKE_CONTROLS | PERMISSION_TRIGGER_ANIMATION ); 
        }
        
        shieldDraw( FALSE );
    }
    #endif
    
    changed( integer l_change )
    {
        if ( l_change & CHANGED_OWNER )
        {
            llResetScript();
        }
        if ( l_change & CHANGED_INVENTORY )
        {
            llResetScript();
        }
    }

    #if gWeaponIsSheath != 1    
    dataserver( key l_key, string l_data )
    {
        if ( l_key == gKey )
        {
            if ( l_data == EOF )   
            {
                llOwnerSay("Loaded.");
                
                return;
            }         
            
            l_data = llStringTrim( l_data, STRING_TRIM );
            
            if ( l_data != "" )
            {
                if ( llSubStringIndex( l_data, "#" ) != 0 )
                {
                    integer i = llSubStringIndex( l_data, "=" );
                    
                    if ( i != -1 && i + 1 != (llStringLength( l_data )) )
                    {
                        string l_name = llStringTrim( llGetSubString( l_data, 0, i - 1 ), STRING_TRIM );
                        string l_value = llStringTrim( llGetSubString( l_data, i + 1, -1 ), STRING_TRIM );
                        
                        if ( l_name == "Dodge Animation1" )
                        {
                            gAnimShieldBlock = l_value;
                        }
                        else if ( l_name == "Dodge Sound1" )
                        {
                            gSoundShieldBlock = l_value;
                        }
                        else if ( l_name == "Draw Sound" )
                        {
                            gSoundShieldDraw = l_value;
                        }
                        else if ( l_name == "Sheath Sound" )
                        {
                            gSoundShieldSheath = l_value;
                        }
                        else if ( l_name == "Draw Animation" )
                        {
                            gAnimShieldDraw = l_value;
                        }
                        else if ( l_name == "Sheath Animation" )
                        {
                            gAnimShieldSheath = l_value;
                        }
                    }
                }
            }
            
            gKey = llGetNotecardLine( gConfigurationNotecard, ++gConfigurationLine );
            
        }
    }
    #endif
    
    #if gWeaponIsSheath != 1
    run_time_permissions( integer l_perm )
    {
        if ( l_perm & PERMISSION_TAKE_CONTROLS )
        {
            llTakeControls( CONTROL_DOWN, 
                            TRUE, TRUE      );                    
        } 
    }
    
    control( key l_key, integer l_held, integer l_change ) 
    {
        if ( CONTROL_DOWN && l_change )
        {
            if ( gAnimShieldBlock != "")
            {
                if ( l_held ) 
                {
                    if ( gWeaponIsShown )
                    {
                        llStartAnimation( gAnimShieldBlock );
                    }
                }
                else
                {
                    llStopAnimation( gAnimShieldBlock );          
                }
            }
        }
    }
    #endif
}
