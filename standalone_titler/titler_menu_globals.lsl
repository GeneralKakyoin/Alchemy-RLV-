// titler_menu_globals.lsl — Globals & System Configuration Suite (Part 3)
// Manages Globals defaults, Typography/Fonts, Custom Roles, Status Tag Progress Bar, and Attachment Notification Editor.
// Split menu architecture to avoid Stack-Heap Collision.

// Link Message Codes:
// Code 180 (Out): RELOAD -> Tells loader/parser to reload configuration
// Code 184 (Out): Float percentage string -> Update Status Tag value
// Code 188 (Out): SET_ROLE|roleName|val -> Update role name in LSD
// Code 189 (In/Out): HANDOFF|context|msgIdx|pageOffset -> Handoff control between menu scripts
// Code 191 (Out): ATTACH_BAR|<count> -> Trigger attachment bar preview

integer gMenuChannel = 0;
integer gMenuListen = 0;

string  gMenuContext = "globals";
integer gPageOffset = 0;
integer gActiveMsgIdx = -1;

string BTN_FILLER = "~♡~";
string gMenuDivider = "   •   •   •   •   •   •   •   •   •\n";

integer is_globals_context(string context)
{
    if (context == "globals" || context == "global_appearance" || context == "global_animation" ||
        context == "global_trinkets" || context == "status_tag" || context == "roles" ||
        context == "select_cursor" || context == "select_trink_style_global" ||
        context == "select_alphabet" ||
        context == "intermission" ||
        (context == "fonts" && (gActiveMsgIdx == -1 || gActiveMsgIdx == -99)))
    {
        return TRUE;
    }
    return FALSE;
}

string get_btn(list btns, integer idx)
{
    if (idx < llGetListLength(btns))
    {
        string v = llList2String(btns, idx);
        if (v != "" && v != " ") return v;
    }
    return BTN_FILLER;
}

open_dialog(string text, list buttons)
{
    if (gMenuListen != 0)
    {
        llListenRemove(gMenuListen);
        gMenuListen = 0;
    }
    
    gMenuChannel = -1000000000 - (integer)llFrand(1000000000);
    gMenuListen = llListen(gMenuChannel, "", llGetOwner(), "");
    
    list final_btns = [
        get_btn(buttons, 0), get_btn(buttons, 1), get_btn(buttons, 2),
        get_btn(buttons, 3), get_btn(buttons, 4), get_btn(buttons, 5),
        get_btn(buttons, 6), get_btn(buttons, 7), get_btn(buttons, 8),
        get_btn(buttons, 9), get_btn(buttons, 10), get_btn(buttons, 11)
    ];
    
    llDialog(llGetOwner(), text, final_btns, gMenuChannel);
    llSetTimerEvent(60.0);
}

open_textbox(string text)
{
    if (gMenuListen != 0)
    {
        llListenRemove(gMenuListen);
        gMenuListen = 0;
    }
    
    gMenuChannel = -1000000000 - (integer)llFrand(1000000000);
    gMenuListen = llListen(gMenuChannel, "", llGetOwner(), "");
    llTextBox(llGetOwner(), text, gMenuChannel);
    llSetTimerEvent(60.0);
}

string get_toggle_btn(string label, string val)
{
    if (val == "1") return "● " + label;
    if (val == "0") return "○ " + label;
    return "◑ " + label;
}

render_globals_menu()
{
    string text = "⬡ Gʟᴏʙᴀʟ Dᴇꜰᴀᴜʟᴛs & Sᴇᴛᴛɪɴɢs ⬡\n" + gMenuDivider;
    text += "Cᴏɴꜰɪɢᴜʀᴇ ᴅᴇꜰᴀᴜʟᴛ ᴘᴀʀᴀᴍᴇᴛᴇʀs, ᴛʏᴘᴏɢʀᴀᴘʜʏ, ʀᴏʟᴇs, ᴀɴᴅ ᴘʀᴏɢʀᴇss ʙᴀʀs:\n";
    
    list buttons = [
        "Bᴀᴄᴋ", "Intermiss", "Aᴛᴛᴀᴄʜ",
        "Aᴘᴘᴇᴀʀ", "Aɴɪᴍ", "Tʀɪɴᴋᴇᴛs",
        "Fᴏɴᴛs", "Rᴏʟᴇs", "Sᴛᴀᴛ Tᴀɢ"
    ];
    open_dialog(text, buttons);
}

render_global_appearance()
{
    string col = llLinksetDataRead("lsd:titler:color"); if (col == "") col = "<1.0, 0.6, 0.8>";
    string alp = llLinksetDataRead("lsd:titler:alpha"); if (alp == "") alp = "1.0";
    string hgt = llLinksetDataRead("lsd:titler:height"); if (hgt == "") hgt = "0.5";
    
    string text = "⬡ Gʟᴏʙᴀʟ Aᴘᴘᴇᴀʀᴀɴᴄᴇ Dᴇꜰᴀᴜʟᴛs ⬡\n" + gMenuDivider;
    text += "▸ Cᴏʟᴏʀ (RGB): " + col + "\n";
    text += "▸ Aʟᴘʜᴀ (Oᴘᴀᴄɪᴛʏ): " + alp + "\n";
    text += "▸ Hᴇɪɢʜᴛ (Oꜰꜰsᴇᴛ): " + hgt + "m\n" + gMenuDivider;
    
    list buttons = [
        "Bᴀᴄᴋ", " ", " ",
        "Sᴇᴛ Cᴏʟᴏʀ", "Sᴇᴛ Aʟᴘʜᴀ", "Sᴇᴛ Hᴇɪɢʜᴛ"
    ];
    open_dialog(text, buttons);
}

render_global_animation()
{
    string style = llLinksetDataRead("lsd:titler:anim_style"); if (style == "") style = "GLITCH";
    string speed = llLinksetDataRead("lsd:titler:trans_speed"); if (speed == "") speed = "0.15";
    string swid  = llLinksetDataRead("lsd:titler:scroll_width"); if (swid == "") swid = "20";
    
    string sc_val = llLinksetDataRead("lsd:titler:scroll_enabled"); if (sc_val == "") sc_val = "0";
    string sc_tog = get_toggle_btn("Sᴄʀᴏʟʟ", sc_val);
    
    string fk_val = llLinksetDataRead("lsd:titler:flicker_glitch"); if (fk_val == "") fk_val = "0";
    string fk_tog = get_toggle_btn("Fʟɪᴄᴋᴇʀ", fk_val);
    
    string cursor = llLinksetDataRead("lsd:titler:typing_cursor"); if (cursor == "") cursor = "_";
    string blink_val = llLinksetDataRead("lsd:titler:blink_cursor"); if (blink_val == "") blink_val = "1";
    string blink_tog = get_toggle_btn("Bʟɪɴᴋ", blink_val);
    
    string blink_status;
    if (blink_val == "1") blink_status = "Eɴᴀʙʟᴇᴅ (Bʟɪɴᴋɪɴɢ)";
    else blink_status = "Dɪsᴀʙʟᴇᴅ (Sᴛᴀᴛɪᴄ)";
    
    string text = "⬡ Gʟᴏʙᴀʟ Aɴɪᴍᴀᴛɪᴏɴ Dᴇꜰᴀᴜʟᴛs ⬡\n" + gMenuDivider;
    text += "▸ Tʀᴀɴsɪᴛɪᴏɴ Sᴛʏʟᴇ: " + style + "\n";
    text += "▸ Tʀᴀɴsɪᴛɪᴏɴ Sᴘᴇᴇᴅ: " + speed + "s\n";
    text += "▸ Sᴄʀᴏʟʟ Wɪᴅᴛʜ: " + swid + " chars\n";
    text += "▸ Tʏᴘɪɴɢ Cᴜʀsᴏʀ: '" + cursor + "'\n";
    text += "▸ Bʟɪɴᴋɪɴɢ Cᴜʀsᴏʀ: " + blink_status + "\n" + gMenuDivider;
    
    list buttons = [
        "Bᴀᴄᴋ", " ", " ",
        "Aʟᴘʜᴀʙᴇᴛ", blink_tog, fk_tog,
        "Sᴄʀ Wɪᴅᴛʜ", sc_tog, "Sᴇᴛ Cᴜʀsᴏʀ",
        "Sᴛʏʟᴇ", "Sᴘᴇᴇᴅ", " "
    ];
    open_dialog(text, buttons);
}

render_alphabet_selection()
{
    string active = llLinksetDataRead("lsd:titler:chaos_alphabet");
    if (active == "") active = "STANDARD";
    
    string text = "⬡ Cʜᴀᴏs Aʟᴘʜᴀʙᴇᴛ Sᴇʟᴇᴄᴛ ⬡\n" + gMenuDivider;
    text += "▸ Aᴄᴛɪᴠᴇ: " + active + "\n";
    text += "Aᴘᴘʟɪᴇs ᴛᴏ GLITCH ᴀɴᴅ CYCLER sᴛʏʟᴇs.\n" + gMenuDivider;
    
    list buttons = [
        "Bᴀᴄᴋ", " ", " ",
        "STANDARD", "MATRIX", "RANDOM"
    ];
    open_dialog(text, buttons);
}

render_global_trinkets()
{
    string style = llLinksetDataRead("lsd:titler:trinket_style"); if (style == "") style = "HEX";
    string pos   = llLinksetDataRead("lsd:titler:trinket_pos"); if (pos == "") pos = "BOTH";
    string speed = llLinksetDataRead("lsd:titler:trinket_speed"); if (speed == "") speed = "MED";
    
    string text = "⬡ Gʟᴏʙᴀʟ Tʀɪɴᴋᴇᴛs Dᴇꜰᴀᴜʟᴛs ⬡\n" + gMenuDivider;
    text += "▸ Sᴛʏʟᴇ: " + style + "\n";
    text += "▸ Pᴏsɪᴛɪᴏɴ: " + pos + "\n";
    text += "▸ Sᴘᴇᴇᴅ: " + speed + "\n" + gMenuDivider;
    
    list buttons = [
        "Bᴀᴄᴋ", " ", " ",
        "Tʀɪɴᴋ Sᴛʏʟᴇ", "Tʀɪɴᴋ Pᴏs", "Tʀɪɴᴋ Sᴘᴇᴇᴅ"
    ];
    open_dialog(text, buttons);
}

string get_trink_style(list styles, integer idx)
{
    if (idx < llGetListLength(styles)) return llList2String(styles, idx);
    return " ";
}

render_trinket_style_select_global()
{
    string trinket_list = llLinksetDataRead("lsd:titler:trinket_list");
    if (trinket_list == "")
    {
        trinket_list = "DOTPULSE|BEAR|DANCE|SPARK|KITTY|SLEEPY|NONE|HEX|HEART|SHY|ZAP|MUSIC";
        llLinksetDataWrite("lsd:titler:trinket_list", trinket_list);
    }
    list all_styles = llParseString2List(trinket_list, ["|"], []);
    
    integer count = llGetListLength(all_styles);
    string text = "⬡ Sᴇʟᴇᴄᴛ Tʀɪɴᴋᴇᴛ Sᴛʏʟᴇ ⬡\n" + gMenuDivider;
    text += "▸ Pᴀɢᴇ Oꜰꜰsᴇᴛ: " + (string)(gPageOffset + 1) + "-" + (string)(gPageOffset + 9) + " (Tᴏᴛᴀʟ: " + (string)count + ")\n" + gMenuDivider;
    
    list buttons = [
        "Bᴀᴄᴋ", "◀ Pʀᴇᴠ", "Nᴇxᴛ ▶",
        get_trink_style(all_styles, gPageOffset + 6), get_trink_style(all_styles, gPageOffset + 7), get_trink_style(all_styles, gPageOffset + 8),
        get_trink_style(all_styles, gPageOffset + 3), get_trink_style(all_styles, gPageOffset + 4), get_trink_style(all_styles, gPageOffset + 5),
        get_trink_style(all_styles, gPageOffset + 0), get_trink_style(all_styles, gPageOffset + 1), get_trink_style(all_styles, gPageOffset + 2)
    ];
    open_dialog(text, buttons);
}

render_cursor_selection()
{
    string text = "⬡ Cᴜsᴏʀ Sᴇʟᴇᴄᴛɪᴏɴ ⬡\n" + gMenuDivider;
    text += "Sᴇʟᴇᴄᴛ ᴛʏᴘɪɴɢ / ʙʟɪɴᴋɪɴɢ ᴄᴜʀsᴏʀ ᶠᴏʀᴍᴀᴛ:\n" + gMenuDivider;
    list cursor_btns = [
        "Bᴀᴄᴋ", " ", " ",
        "▊", "Nᴏɴᴇ", " ",
        "_", "|", "█"
    ];
    open_dialog(text, cursor_btns);
}

string get_font_btn(list fonts, integer idx)
{
    if (idx < llGetListLength(fonts))
    {
        string f_name = llList2String(fonts, idx);
        string styled = llLinksetDataRead("lsd:titler:font:" + f_name + ":styled");
        if (styled == "") styled = f_name;
        if (llStringLength(styled) > 5) styled = llGetSubString(styled, 0, 4);
        return styled;
    }
    return " ";
}

render_fonts_menu()
{
    string active_font = "";
    if (gActiveMsgIdx == -1)
    {
        active_font = llLinksetDataRead("lsd:titler:active_font");
        if (active_font == "") active_font = "DEFAULT";
    }
    else if (gActiveMsgIdx == -99)
    {
        active_font = llLinksetDataRead("lsd:titler:attach:font");
        if (active_font == "") active_font = "Inherited";
    }
    
    string font_list = llLinksetDataRead("lsd:titler:font_list");
    list fonts = llParseString2List(font_list, ["|"], []);
    
    string text = "⬡ Fᴏɴᴛs Cᴏɴꜰɪɢᴜʀᴀᴛɪᴏɴ ⬡\n" + gMenuDivider;
    if (gActiveMsgIdx == -99) text += "▸ Cᴏɴꜰɪɢᴜʀɪɴɢ: Aᴛᴛᴀᴄʜ Mᴇssᴀɢᴇ Fᴏɴᴛ\n";
    else                    text += "▸ Cᴏɴꜰɪɢᴜʀɪɴɢ: Gʟᴏʙᴀʟ Dᴇꜰᴀᴜʟᴛ Fᴏɴᴛ\n";
    text += gMenuDivider;
    text += "▸ Aᴄᴛɪᴠᴇ Fᴏɴᴛ: " + active_font + "\n" + gMenuDivider;
    
    string b0 = "DEFAULT"; if (gActiveMsgIdx != -1) b0 = "default";
    
    list buttons = [
        "Bᴀᴄᴋ", "◀ Pʀᴇᴠ", "Nᴇxᴛ ▶",
        get_font_btn(fonts, gPageOffset + 2), get_font_btn(fonts, gPageOffset + 3), get_font_btn(fonts, gPageOffset + 4),
        b0, get_font_btn(fonts, gPageOffset + 0), get_font_btn(fonts, gPageOffset + 1)
    ];
    open_dialog(text, buttons);
}

string get_role_btn(list roles, integer idx)
{
    if (idx < llGetListLength(roles)) return llList2String(roles, idx);
    return " ";
}

render_roles_menu()
{
    string role_list = llLinksetDataRead("lsd:titler:role_list");
    list roles = llParseString2List(role_list, ["|"], []);
    integer r_count = llGetListLength(roles);
    
    string text = "⬡ Cᴜsᴛᴏᴍ Rᴏʟᴇs Mᴀɴᴀɢᴇʀ ⬡\n" + gMenuDivider;
    text += "▸ Pᴀɢᴇ Oꜰꜰsᴇᴛ: " + (string)(gPageOffset + 1) + "-" + (string)(gPageOffset + 6) + " (Tᴏᴛᴀʟ: " + (string)r_count + ")\n" + gMenuDivider;
    
    if (r_count == 0)
    {
        text += "Nᴏ ᴄᴜsᴛᴏᴍ ʀᴏʟᴇs ᴅᴇꜰɪɴᴇᴅ.\n";
    }
    else
    {
        integer i;
        for (i = gPageOffset; i < gPageOffset + 6 && i < r_count; ++i)
        {
            string r_name = llList2String(roles, i);
            string r_val  = llLinksetDataRead("lsd:titler:role:" + r_name);
            text += "%role:" + r_name + "% ➔ \"" + r_val + "\"\n";
        }
    }
    text += gMenuDivider;
    
    list buttons = [
        "Bᴀᴄᴋ", "◀ Pʀᴇᴠ", "Nᴇxᴛ ▶",
        "Aᴅᴅ Rᴏʟᴇ", "Cʟᴇᴀʀ Rᴏʟᴇs", " ",
        get_role_btn(roles, gPageOffset + 3), get_role_btn(roles, gPageOffset + 4), get_role_btn(roles, gPageOffset + 5),
        get_role_btn(roles, gPageOffset + 0), get_role_btn(roles, gPageOffset + 1), get_role_btn(roles, gPageOffset + 2)
    ];
    open_dialog(text, buttons);
}

render_status_tag_menu()
{
    string tag = llLinksetDataRead("lsd:titler:status_tag");
    string chan = llLinksetDataRead("lsd:titler:status_channel");
    string sty = llLinksetDataRead("lsd:titler:status_bar_style"); if (sty == "") sty = "BLOCK";
    string len = llLinksetDataRead("lsd:titler:status_bar_len"); if (len == "") len = "5";
    string val = llLinksetDataRead("lsd:titler:status_val"); if (val == "") val = "100.0";
    
    integer queue_updates = (integer)llLinksetDataRead("lsd:titler:queue_status_updates");
    string queue_status;
    string queue_btn;
    if (queue_updates == 1)
    {
        queue_status = "Eɴᴀʙʟᴇᴅ (Qᴜᴇᴜᴇ)";
        queue_btn = "● Qᴜᴇᴜᴇ";
    }
    else
    {
        queue_status = "Dɪsᴀʙʟᴇᴅ (Sɪʟᴇɴᴛ)";
        queue_btn = "○ Qᴜᴇᴜᴇ";
    }
    
    string text = "⬡ Sᴛᴀᴛᴜs Pʀᴏɢʀᴇss Bᴀʀ Mᴇɴᴜ ⬡\n" + gMenuDivider;
    text += "▸ Tᴀɢ Kᴇʏᴡᴏʀᴅ: %" + tag + "%\n";
    text += "▸ Lɪsᴛᴇɴᴇʀ Cʜᴀɴɴᴇʟ: " + chan + "\n";
    text += "▸ Bᴀʀ Sᴛʏʟᴇ: " + sty + "\n";
    text += "▸ Bᴀʀ Lᴇɴɢᴛʜ: " + len + " chars\n";
    text += "▸ Cᴜʀʀᴇɴᴛ Vᴀʟᴜᴇ: " + val + "%\n";
    text += "▸ Qᴜᴇᴜᴇᴅ Uᴘᴅᴀᴛᴇs: " + queue_status + "\n" + gMenuDivider;
    
    list buttons = [
        "Bᴀᴄᴋ", " ", " ",
        "Tᴀɢ Nᴀᴍᴇ", "Sᴇᴛ Cʜᴀɴɴᴇʟ", queue_btn,
        "Sᴇᴛ Sᴛʏʟᴇ", "Sᴇᴛ Lᴇɴɢᴛʜ", "Sᴇᴛ Vᴀʟᴜᴇ"
    ];
    open_dialog(text, buttons);
}

string get_msg_btn(integer count, integer idx)
{
    if (idx < count) return "Msg " + (string)(idx + 1);
    return " ";
}

render_intermission_menu()
{
    string int_idx = llLinksetDataRead("lsd:titler:intermission_idx");
    string active_lbl = "None (Disabled)";
    if (int_idx != "") active_lbl = "Msg " + (string)((integer)int_idx + 1);
    
    integer count = (integer)llLinksetDataRead("lsd:titler:msg_count");
    string text = "⬡ Iɴᴛᴇʀᴍɪssɪᴏɴ Mᴇssᴀɢᴇ ⬡\n" + gMenuDivider;
    text += "Sᴇʟᴇᴄᴛ ᴀ ᴍᴇssᴀɢᴇ ᴛᴏ ɪɴᴊᴇᴄᴛ ʙᴇᴛᴡᴇᴇɴ\n";
    text += "ᴇᴠᴇʀʏ ɴᴏʀᴍᴀʟ ᴍᴇssᴀɢᴇ ɪɴ ᴛʜᴇ ʀᴏᴛᴀᴛɪᴏɴ:\n" + gMenuDivider;
    text += "▸ Aᴄᴛɪᴠᴇ: " + active_lbl + "\n";
    text += "▸ Pᴀɢᴇ: " + (string)(gPageOffset + 1) + "-" + (string)(gPageOffset + 5) + " / " + (string)count + "\n" + gMenuDivider;
    
    list buttons = [
        "Bᴀᴄᴋ", "◀ Pʀᴇᴠ", "Nᴇxᴛ ▶",
        get_msg_btn(count, gPageOffset + 3), get_msg_btn(count, gPageOffset + 4), "None",
        get_msg_btn(count, gPageOffset + 0), get_msg_btn(count, gPageOffset + 1), get_msg_btn(count, gPageOffset + 2)
    ];
    open_dialog(text, buttons);
}

refresh_menu()
{
    if (gMenuContext == "globals") render_globals_menu();
    else if (gMenuContext == "global_appearance") render_global_appearance();
    else if (gMenuContext == "global_animation") render_global_animation();
    else if (gMenuContext == "global_trinkets") render_global_trinkets();
    else if (gMenuContext == "status_tag") render_status_tag_menu();
    else if (gMenuContext == "roles") render_roles_menu();
    else if (gMenuContext == "fonts") render_fonts_menu();
    else if (gMenuContext == "select_trink_style_global") render_trinket_style_select_global();
    else if (gMenuContext == "select_cursor") render_cursor_selection();
    else if (gMenuContext == "select_alphabet") render_alphabet_selection();
    else if (gMenuContext == "intermission") render_intermission_menu();
}

default
{
    state_entry()
    {
        llSetMemoryLimit(65536);
    }

    link_message(integer sender_num, integer code, string str, key id)
    {
        // Code 189: Handoff from other menu scripts
        if (code == 189)
        {
            list parts = llParseString2List(str, ["|"], []);
            string action = llList2String(parts, 0);
            
            if (action == "HANDOFF")
            {
                string target_context = llList2String(parts, 1);
                gActiveMsgIdx = (integer)llList2String(parts, 2);
                gPageOffset = (integer)llList2String(parts, 3);
                
                if (is_globals_context(target_context))
                {
                    gMenuContext = target_context;
                    refresh_menu();
                }
            }
        }
    }

    listen(integer channel, string name, key id, string message)
    {
        if (id != llGetOwner()) return;

        if (channel == gMenuChannel)
        {
            llSetTimerEvent(0.0);
            string cmd = llStringTrim(message, STRING_TRIM);
            
            if (cmd == BTN_FILLER) return;
            
            // --- Text Box Processing ---
            if (llSubStringIndex(gMenuContext, "textbox:") == 0)
            {
                string action = llGetSubString(gMenuContext, 8, -1);
                
                if (action == "g_color")
                {
                    llLinksetDataWrite("lsd:titler:color", cmd);
                    llMessageLinked(LINK_SET, 180, "RELOAD", NULL_KEY);
                    gMenuContext = "global_appearance";
                    refresh_menu();
                    return;
                }
                if (action == "g_alpha")
                {
                    llLinksetDataWrite("lsd:titler:alpha", cmd);
                    llMessageLinked(LINK_SET, 180, "RELOAD", NULL_KEY);
                    gMenuContext = "global_appearance";
                    refresh_menu();
                    return;
                }
                if (action == "g_height")
                {
                    llLinksetDataWrite("lsd:titler:height", cmd);
                    llMessageLinked(LINK_SET, 180, "RELOAD", NULL_KEY);
                    gMenuContext = "global_appearance";
                    refresh_menu();
                    return;
                }
                if (action == "g_speed")
                {
                    llLinksetDataWrite("lsd:titler:trans_speed", cmd);
                    llMessageLinked(LINK_SET, 180, "RELOAD", NULL_KEY);
                    gMenuContext = "global_animation";
                    refresh_menu();
                    return;
                }
                if (action == "g_scroll_width")
                {
                    llLinksetDataWrite("lsd:titler:scroll_width", cmd);
                    llMessageLinked(LINK_SET, 180, "RELOAD", NULL_KEY);
                    gMenuContext = "global_animation";
                    refresh_menu();
                    return;
                }
                if (action == "tag_name")
                {
                    llLinksetDataWrite("lsd:titler:status_tag", cmd);
                    llMessageLinked(LINK_SET, 180, "RELOAD", NULL_KEY);
                    gMenuContext = "status_tag";
                    refresh_menu();
                    return;
                }
                if (action == "tag_chan")
                {
                    llLinksetDataWrite("lsd:titler:status_channel", cmd);
                    llMessageLinked(LINK_SET, 180, "RELOAD", NULL_KEY);
                    gMenuContext = "status_tag";
                    refresh_menu();
                    return;
                }
                if (action == "tag_len")
                {
                    integer len = (integer)cmd;
                    if (len < 5) len = 5;
                    if (len > 15) len = 15;
                    llLinksetDataWrite("lsd:titler:status_bar_len", (string)len);
                    llMessageLinked(LINK_SET, 180, "RELOAD", NULL_KEY);
                    gMenuContext = "status_tag";
                    refresh_menu();
                    return;
                }
                if (action == "tag_val")
                {
                    llLinksetDataWrite("lsd:titler:status_val", cmd);
                    llMessageLinked(LINK_SET, 184, cmd, NULL_KEY);
                    gMenuContext = "status_tag";
                    refresh_menu();
                    return;
                }
                if (action == "add_role_name")
                {
                    llLinksetDataWrite("lsd:titler:temp_role_name", cmd);
                    gMenuContext = "textbox:add_role_val";
                    open_textbox("Enter role resolved value string:");
                    return;
                }
                if (action == "add_role_val")
                {
                    string r_name = llLinksetDataRead("lsd:titler:temp_role_name");
                    llLinksetDataDelete("lsd:titler:temp_role_name");
                    llMessageLinked(LINK_SET, 188, r_name + "|" + cmd, NULL_KEY);
                    gMenuContext = "roles";
                    refresh_menu();
                    return;
                }
                if (llSubStringIndex(action, "edit_role:") == 0)
                {
                    string r_name = llGetSubString(action, 10, -1);
                    llMessageLinked(LINK_SET, 188, r_name + "|" + cmd, NULL_KEY);
                    gMenuContext = "roles";
                    refresh_menu();
                    return;
                }
            }

            // --- Dialog Processing ---
            if (cmd == "Back" || cmd == "Bᴀᴄᴋ")
            {
                if (gMenuContext == "globals")
                {
                    gMenuContext = "";
                    if (gMenuListen != 0) { llListenRemove(gMenuListen); gMenuListen = 0; }
                    llMessageLinked(LINK_SET, 189, "HANDOFF|main|-1|0", id);
                    return;
                }
                
                if (gMenuContext == "global_appearance" || gMenuContext == "global_animation" || gMenuContext == "global_trinkets" || gMenuContext == "roles" || gMenuContext == "status_tag" || gMenuContext == "intermission")
                {
                    gMenuContext = "globals";
                    refresh_menu();
                    return;
                }
                
                if (gMenuContext == "select_trink_style_global")
                {
                    gMenuContext = "global_trinkets";
                    refresh_menu();
                    return;
                }
                
                if (gMenuContext == "select_cursor")
                {
                    gMenuContext = "global_animation";
                    refresh_menu();
                    return;
                }
                
                if (gMenuContext == "fonts")
                {
                    gMenuContext = "globals";
                    refresh_menu();
                    return;
                }
            }

            if (gMenuContext == "globals")
            {
                if (cmd == "Appearance" || cmd == "Aᴘᴘᴇᴀʀ" || cmd == "Aᴘᴘᴇᴀʀᴀɴᴄᴇ")
                {
                    gMenuContext = "global_appearance";
                    render_global_appearance();
                }
                else if (cmd == "Animation" || cmd == "Aɴɪᴍ" || cmd == "Aɴɪᴍᴀᴛɪᴏɴ")
                {
                    gMenuContext = "global_animation";
                    render_global_animation();
                }
                else if (cmd == "Trinkets" || cmd == "Tʀɪɴᴋᴇᴛs")
                {
                    gMenuContext = "global_trinkets";
                    render_global_trinkets();
                }
                else if (cmd == "Fonts" || cmd == "Fᴏɴᴛs")
                {
                    gActiveMsgIdx = -1;
                    gPageOffset = 0;
                    gMenuContext = "fonts";
                    render_fonts_menu();
                }
                else if (cmd == "Roles" || cmd == "Rᴏʟᴇs")
                {
                    gPageOffset = 0;
                    gMenuContext = "roles";
                    render_roles_menu();
                }
                else if (cmd == "Sᴛᴀᴛ Tᴀɢ" || cmd == "Stat Tag")
                {
                    gMenuContext = "status_tag";
                    refresh_menu();
                    return;
                }
                if (cmd == "Intermiss")
                {
                    gMenuContext = "intermission";
                    gPageOffset = 0;
                    refresh_menu();
                    return;
                }
                else if (cmd == "Attach" || cmd == "Aᴛᴛᴀᴄʜ")
                {
                    gMenuContext = "";
                    if (gMenuListen != 0) { llListenRemove(gMenuListen); gMenuListen = 0; }
                    llMessageLinked(LINK_SET, 189, "HANDOFF|attach_bar|-99|0", id);
                }
                return;
            }

            if (gMenuContext == "global_appearance")
            {
                if (cmd == "Set Color" || cmd == "Sᴇᴛ Cᴏʟᴏʀ")
                {
                    gMenuContext = "textbox:g_color";
                    open_textbox("Enter global text color vector (e.g. 1 0.5 0.8 or RANDOM):");
                }
                else if (cmd == "Set Alpha" || cmd == "Sᴇᴛ Aʟᴘʜᴀ")
                {
                    gMenuContext = "textbox:g_alpha";
                    open_textbox("Enter global alpha float 0.0 - 1.0:");
                }
                else if (cmd == "Set Height" || cmd == "Sᴇᴛ Hᴇɪɢʜᴛ")
                {
                    gMenuContext = "textbox:g_height";
                    open_textbox("Enter global vertical offset height float:");
                }
                return;
            }

            if (gMenuContext == "global_trinkets")
            {
                if (cmd == "Trink Style" || cmd == "Tʀɪɴᴋ Sᴛʏʟᴇ")
                {
                    gPageOffset = 0;
                    gMenuContext = "select_trink_style_global";
                    render_trinket_style_select_global();
                }
                else if (cmd == "Trink Pos" || cmd == "Tʀɪɴᴋ Pᴏs")
                {
                    string pos = llLinksetDataRead("lsd:titler:trinket_pos");
                    if (pos == "" || pos == "BOTH") pos = "PREFIX";
                    else if (pos == "PREFIX")       pos = "SUFFIX";
                    else                            pos = "BOTH";
                    llLinksetDataWrite("lsd:titler:trinket_pos", pos);
                    llMessageLinked(LINK_SET, 180, "RELOAD", NULL_KEY);
                    render_global_trinkets();
                }
                else if (cmd == "Trink Speed" || cmd == "Tʀɪɴᴋ Sᴘᴇᴇᴅ")
                {
                    string spd = llLinksetDataRead("lsd:titler:trinket_speed");
                    if (spd == "" || spd == "MED") spd = "FAST";
                    else if (spd == "FAST")        spd = "SLOW";
                    else                           spd = "MED";
                    llLinksetDataWrite("lsd:titler:trinket_speed", spd);
                    llMessageLinked(LINK_SET, 180, "RELOAD", NULL_KEY);
                    render_global_trinkets();
                }
                return;
            }

            if (gMenuContext == "select_trink_style_global")
            {
                if (cmd == "◀ Prev" || cmd == "◀ Pʀᴇᴠ")
                {
                    if (gPageOffset >= 9) gPageOffset -= 9;
                    render_trinket_style_select_global();
                    return;
                }
                if (cmd == "Next ▶" || cmd == "Nᴇxᴛ ▶")
                {
                    string trinket_list = llLinksetDataRead("lsd:titler:trinket_list");
                    list all_styles = llParseString2List(trinket_list, ["|"], []);
                    if (gPageOffset + 9 < llGetListLength(all_styles)) gPageOffset += 9;
                    render_trinket_style_select_global();
                    return;
                }
                if (cmd != " " && cmd != "")
                {
                    llLinksetDataWrite("lsd:titler:trinket_style", cmd);
                    llMessageLinked(LINK_SET, 180, "RELOAD", NULL_KEY);
                    gMenuContext = "global_trinkets";
                    render_global_trinkets();
                }
                return;
            }

            if (gMenuContext == "global_animation")
            {
                if (cmd == "Style" || cmd == "Sᴛʏʟᴇ")
                {
                    gMenuContext = "";
                    if (gMenuListen != 0) { llListenRemove(gMenuListen); gMenuListen = 0; }
                    llMessageLinked(LINK_SET, 189, "HANDOFF|select_style:global_animation|-1|" + (string)gPageOffset, id);
                }
                else if (cmd == "Speed" || cmd == "Sᴘᴇᴇᴅ")
                {
                    gMenuContext = "textbox:g_speed";
                    open_textbox("Enter global transition tick speed in seconds:");
                }
                else if (cmd == "Scroll Width" || cmd == "Sᴄʀᴏʟʟ Wɪᴅᴛʜ" || cmd == "Sᴄʀ Wɪᴅᴛʜ")
                {
                    gMenuContext = "textbox:g_scroll_width";
                    open_textbox("Enter global scroll boundary width (e.g. 20):");
                }
                else if (cmd == "Set Cursor" || cmd == "Sᴇᴛ Cᴜʀsᴏʀ")
                {
                    gMenuContext = "select_cursor";
                    render_cursor_selection();
                }
                else if (cmd == "Alphabet" || cmd == "Aʟᴘʜᴀʙᴇᴛ")
                {
                    gMenuContext = "select_alphabet";
                    render_alphabet_selection();
                }
                else if (cmd == "Scroll Toggle" || llSubStringIndex(cmd, "Sᴄʀᴏʟʟ") != -1)
                {
                    string sc = llLinksetDataRead("lsd:titler:scroll_enabled");
                    if (sc == "" || sc == "1") sc = "0";
                    else                      sc = "1";
                    llLinksetDataWrite("lsd:titler:scroll_enabled", sc);
                    llMessageLinked(LINK_SET, 180, "RELOAD", NULL_KEY);
                    render_global_animation();
                }
                else if (cmd == "Flicker Toggle" || llSubStringIndex(cmd, "Fʟɪᴄᴋᴇʀ") != -1)
                {
                    string fk = llLinksetDataRead("lsd:titler:flicker_glitch");
                    if (fk == "" || fk == "1") fk = "0";
                    else                      fk = "1";
                    llLinksetDataWrite("lsd:flicker_glitch", fk);
                    llMessageLinked(LINK_SET, 180, "RELOAD", NULL_KEY);
                    render_global_animation();
                }
                else if (cmd == "Blink Toggle" || llSubStringIndex(cmd, "Bʟɪɴᴋ") != -1)
                {
                    string bl = llLinksetDataRead("lsd:titler:blink_cursor");
                    if (bl == "" || bl == "1") bl = "0";
                    else                      bl = "1";
                    llLinksetDataWrite("lsd:titler:blink_cursor", bl);
                    llMessageLinked(LINK_SET, 180, "RELOAD", NULL_KEY);
                    render_global_animation();
                }
                return;
            }

            if (gMenuContext == "select_cursor")
            {
                if (cmd != " " && cmd != "")
                {
                    string to_save = cmd;
                    if (to_save == "None") to_save = "";
                    llLinksetDataWrite("lsd:titler:typing_cursor", to_save);
                    llMessageLinked(LINK_SET, 180, "RELOAD", NULL_KEY);
                    gMenuContext = "global_animation";
                    render_global_animation();
                }
                return;
            }
            
            if (gMenuContext == "select_alphabet")
            {
                if (cmd != " " && cmd != "")
                {
                    llLinksetDataWrite("lsd:titler:chaos_alphabet", cmd);
                    llMessageLinked(LINK_SET, 180, "RELOAD", NULL_KEY);
                    gMenuContext = "global_animation";
                    render_global_animation();
                }
                return;
            }

            if (gMenuContext == "status_tag")
            {
                if (cmd == "Set Tag Name" || cmd == "Sᴇᴛ Tᴀɢ Nᴀᴍᴇ" || cmd == "Tᴀɢ Nᴀᴍᴇ")
                {
                    gMenuContext = "textbox:tag_name";
                    open_textbox("Enter Status Tag keyword:");
                }
                else if (cmd == "Set Channel" || cmd == "Sᴇᴛ Cʜᴀɴɴᴇʟ")
                {
                    gMenuContext = "textbox:tag_chan";
                    open_textbox("Enter Status Listener Channel number:");
                }
                else if (cmd == "Set Style" || cmd == "Sᴇᴛ Sᴛʏʟᴇ")
                {
                    string sty = llLinksetDataRead("lsd:titler:status_bar_style");
                    if (sty == "" || sty == "BLOCK") sty = "PIPER";
                    else if (sty == "PIPER")         sty = "DIODE";
                    else                             sty = "BLOCK";
                    llLinksetDataWrite("lsd:titler:status_bar_style", sty);
                    llMessageLinked(LINK_SET, 180, "RELOAD", NULL_KEY);
                    render_status_tag_menu();
                }
                else if (cmd == "Set Length" || cmd == "Sᴇᴛ Lᴇɴɢᴛʜ")
                {
                    gMenuContext = "textbox:tag_len";
                    open_textbox("Enter progress bar character length (5 to 15):");
                }
                else if (cmd == "Set Value" || cmd == "Sᴇᴛ Vᴀʟᴜᴇ")
                {
                    gMenuContext = "textbox:tag_val";
                    open_textbox("Enter percentage progress value (0 to 100):");
                }
                else if (cmd == "Queue Updates" || llSubStringIndex(cmd, "Qᴜᴇᴜᴇ") != -1)
                {
                    integer q = (integer)llLinksetDataRead("lsd:titler:queue_status_updates");
                    if (q == 1) q = 0;
                    else        q = 1;
                    llLinksetDataWrite("lsd:titler:queue_status_updates", (string)q);
                    render_status_tag_menu();
                }
                return;
            }

            if (gMenuContext == "roles")
            {
                if (cmd == "Add Role" || cmd == "Aᴅᴅ Rᴏʟᴇ")
                {
                    gMenuContext = "textbox:add_role_name";
                    open_textbox("Enter custom role keyword (e.g. master, pet):");
                    return;
                }
                if (cmd == "Clear Roles" || cmd == "Cʟᴇᴀʀ Rᴏʟᴇs")
                {
                    string role_list = llLinksetDataRead("lsd:titler:role_list");
                    list roles = llParseString2List(role_list, ["|"], []);
                    integer i;
                    for (i = 0; i < llGetListLength(roles); ++i)
                    {
                        llLinksetDataDelete("lsd:titler:role:" + llList2String(roles, i));
                    }
                    llLinksetDataDelete("lsd:titler:role_list");
                    llMessageLinked(LINK_SET, 180, "RELOAD", NULL_KEY);
                    render_roles_menu();
                    return;
                }
                if (cmd == "◀ Prev" || cmd == "◀ Pʀᴇᴠ")
                {
                    if (gPageOffset >= 6) gPageOffset -= 6;
                    render_roles_menu();
                    return;
                }
                if (cmd == "Next ▶" || cmd == "Nᴇxᴛ ▶")
                {
                    string role_list = llLinksetDataRead("lsd:titler:role_list");
                    list roles = llParseString2List(role_list, ["|"], []);
                    if (gPageOffset + 6 < llGetListLength(roles)) gPageOffset += 6;
                    render_roles_menu();
                    return;
                }
                if (cmd != " " && cmd != "")
                {
                    gMenuContext = "textbox:edit_role:" + cmd;
                    open_textbox("Enter new value for role %role:" + cmd + "%:");
                }
                return;
            }

            if (gMenuContext == "fonts")
            {
                if (cmd == "Reload Notecard" || cmd == "Rᴇʟᴏᴀᴅ Nᴏᴛᴇᴄᴀʀᴅ" || cmd == "Rᴇʟᴏᴀᴅ")
                {
                    llMessageLinked(LINK_SET, 180, "RELOAD_FONTS", NULL_KEY);
                    render_fonts_menu();
                    return;
                }
                if (cmd == "◀ Prev" || cmd == "◀ Pʀᴇᴠ")
                {
                    if (gPageOffset >= 5) gPageOffset -= 5;
                    render_fonts_menu();
                    return;
                }
                if (cmd == "Next ▶" || cmd == "Nᴇxᴛ ▶")
                {
                    string font_list = llLinksetDataRead("lsd:titler:font_list");
                    list fonts = llParseString2List(font_list, ["|"], []);
                    if (gPageOffset + 5 < llGetListLength(fonts)) gPageOffset += 5;
                    render_fonts_menu();
                    return;
                }
                if (cmd != " " && cmd != "")
                {
                    string selected_font = cmd;
                    string font_list = llLinksetDataRead("lsd:titler:font_list");
                    list fonts = llParseString2List(font_list, ["|"], []);
                    integer font_idx;
                    for (font_idx = gPageOffset; font_idx < gPageOffset + 5 && font_idx < llGetListLength(fonts); ++font_idx)
                    {
                        string original_font = llList2String(fonts, font_idx);
                        string styled_font = llLinksetDataRead("lsd:titler:font:" + original_font + ":styled");
                        if (styled_font == "") styled_font = original_font;
                        if (llStringLength(styled_font) > 5) styled_font = llGetSubString(styled_font, 0, 4);
                        if (cmd == styled_font) selected_font = original_font;
                    }
                    
                    if (gActiveMsgIdx == -99)
                    {
                        string to_save = selected_font;
                        if (to_save == "default") to_save = "";
                        llLinksetDataWrite("lsd:titler:attach:font", to_save);
                    }
                    else
                    {
                        llLinksetDataWrite("lsd:titler:active_font", selected_font);
                    }
                    llMessageLinked(LINK_SET, 180, "RELOAD", NULL_KEY);
                    render_fonts_menu();
                    return;
                }
            }
            if (gMenuContext == "intermission")
            {
                if (cmd == "◀ Prev" || cmd == "◀ Pʀᴇᴠ")
                {
                    if (gPageOffset >= 5) gPageOffset -= 5;
                    render_intermission_menu();
                    return;
                }
                if (cmd == "Next ▶" || cmd == "Nᴇxᴛ ▶")
                {
                    integer count = (integer)llLinksetDataRead("lsd:titler:msg_count");
                    if (gPageOffset + 5 < count) gPageOffset += 5;
                    render_intermission_menu();
                    return;
                }
                if (cmd == "None")
                {
                    llLinksetDataDelete("lsd:titler:intermission_idx");
                    render_intermission_menu();
                    return;
                }
                if (llSubStringIndex(cmd, "Msg ") == 0)
                {
                    integer idx = (integer)llGetSubString(cmd, 4, -1) - 1;
                    llLinksetDataWrite("lsd:titler:intermission_idx", (string)idx);
                    render_intermission_menu();
                    return;
                }
            }
        }
    }

    timer()
    {
        llSetTimerEvent(0.0);
        if (gMenuListen != 0)
        {
            llListenRemove(gMenuListen);
            gMenuListen = 0;
        }
    }
}
