key gOwner;

string gSheathType = "sword"; // Must match gWeaponSheathType.
integer gSheathChannel = -4337;
integer gSheathPart = LINK_SET;

integer gIsSheath = TRUE;
integer gIsShown = FALSE;

init()
{
    gOwner = llGetOwner();

    llListen( gSheathChannel, "", NULL_KEY, "drawn " + gSheathType );
    llListen( gSheathChannel, "", NULL_KEY, "sheath " + gSheathType );

    sheathToggle( FALSE );
}

sheathToggle(integer l_hide)
{
    if ( !gIsSheath )
    {
        l_hide = !l_hide;
    }

    if ( l_hide )
    {
        gIsShown = FALSE;
        llSetLinkAlpha( gSheathPart, 0.0, ALL_SIDES );
    }
    else
    {
        gIsShown = TRUE;
        llSetLinkAlpha( gSheathPart, 1.0, ALL_SIDES );
    }
}

default
{
    state_entry()
    {
        init();
    }

    listen(integer l_channel, string l_name, key l_key, string l_body)
    {
        if ( l_channel == gSheathChannel )
        {
            if ( llGetOwnerKey( l_key ) == gOwner )
            {
                if ( l_body == "drawn " + gSheathType )
                {
                    sheathToggle( TRUE );
                }
                else if ( l_body == "sheath " + gSheathType )
                {
                    sheathToggle( FALSE );
                }
            }
        }
    }

    on_rez(integer l_int)
    {
        llResetScript();
    }
}
