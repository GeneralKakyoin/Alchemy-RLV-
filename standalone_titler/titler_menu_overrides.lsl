// titler_menu_overrides.lsl — Overrides Configuration Menu (Part 2 - Style & Settings)
// Manages Before/During/After FX, Appearance overrides, Fonts, Roles, and Status Tags configuration.
// Split menu architecture to avoid Stack-Heap Collision.

// Link Message Codes:
// Code 180 (Out): RELOAD -> Tells loader/parser to reload configuration
// Code 184 (Out): Float percentage string -> Update Status Tag value
// Code 188 (Out): SET_ROLE|roleName|val -> Update role name in LSD
// Code 189 (In/Out): HANDOFF|context|msgIdx|pageOffset (User key) -> Handoff control between menus

integer gMenuChannel = 0;
integer gMenuListen = 0;

string  gMenuContext = "main";
integer gPageOffset = 0;
integer gParentPageOffset = 0;
integer gActiveMsgIdx = -1;

string BTN_FILLER = " ";

/// Check if context belongs to this overrides script (not the main menu script)
string get_msg_prefix(integer idx)
{
    return "lsd:titler:msg:" + (string)idx + ":";
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

integer is_override_context(string context)
{
    if (context == "before_fx" || context == "during_fx" || context == "after_fx" ||
        context == "appearance" || context == "msg_edit" || context == "msg_move" || context == "presets" ||
        (context == "fonts" && gActiveMsgIdx >= 0) ||
        (llSubStringIndex(context, "select_style:") == 0) ||
        (context == "select_trink_style"))
    {
        return TRUE;
    }
    return FALSE;
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
    
    // Flat layout — llDialog displays index 0 at bottom, index 9-11 at top.
    // Buttons are passed in visual bottom-to-top order: row0, row1, row2, row3.
    list final_btns = [
        get_btn(buttons,  0), get_btn(buttons,  1), get_btn(buttons,  2),
        get_btn(buttons,  3), get_btn(buttons,  4), get_btn(buttons,  5),
        get_btn(buttons,  6), get_btn(buttons,  7), get_btn(buttons,  8),
        get_btn(buttons,  9), get_btn(buttons, 10), get_btn(buttons, 11)
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

render_before_fx()
{
    string prefix = get_msg_prefix(gActiveMsgIdx);
    string t_style = llLinksetDataRead(prefix + "trans_in"); if (t_style == "") t_style = "Inherited";
    string t_speed = llLinksetDataRead(prefix + "trans_speed"); if (t_speed == "") t_speed = "Inherited";
    string t_color = llLinksetDataRead(prefix + "color_trans"); if (t_color == "") t_color = "Inherited";
    
    string text = "⬡ Before FX: Transition In ⬡\n";
    text += "--------------------------------------\n";
    text += "Style: " + t_style + "\n";
    text += "Speed: " + t_speed + "\n";
    text += "Flash Color: " + t_color + "\n";
    text += "--------------------------------------\n";
    
    list buttons = [
        "In Style", "In Speed", "In Color",
        " ", " ", " ",
        " ", " ", " ",
        "Back", " ", " "
    ];
    open_dialog(text, buttons);
}

render_during_fx()
{
    string prefix = get_msg_prefix(gActiveMsgIdx);
    string trink = llLinksetDataRead(prefix + "trinket_style"); if (trink == "") trink = "Inherited";
    string tpos  = llLinksetDataRead(prefix + "trinket_pos"); if (tpos == "") tpos = "Inherited";
    string swid  = llLinksetDataRead(prefix + "scroll_width"); if (swid == "") swid = "Inherited";
    string scrl  = llLinksetDataRead(prefix + "scroll_enabled"); if (scrl == "") scrl = "Inherited";
    
    string flick = llLinksetDataRead(prefix + "flicker_glitch");
    string flick_status = "Inherited";
    if (flick == "1") flick_status = "ON";
    else if (flick == "0") flick_status = "OFF";
    
    string blink = llLinksetDataRead(prefix + "blink_cursor");
    string blink_status = "Inherited";
    if (blink == "1") blink_status = "ON";
    else if (blink == "0") blink_status = "OFF";
    
    string text = "⬡ During FX: Idle Animations ⬡\n";
    text += "--------------------------------------\n";
    text += "Trinket Style: " + trink + "\n";
    text += "Trinket Position: " + tpos + "\n";
    text += "Scroll Width: " + swid + "\n";
    text += "Scroll Toggle: " + scrl + "\n";
    text += "Flicker Toggle: " + flick_status + "\n";
    text += "Blink Toggle: " + blink_status + "\n";
    text += "--------------------------------------\n";
    
    list buttons = [
        "Trink Style", "Trink Pos", "Scroll Width",
        "Scroll Toggle", "Flicker Toggle", "Blink Toggle",
        " ", " ", " ",
        "Back", " ", " "
    ];
    open_dialog(text, buttons);
}

render_after_fx()
{
    string prefix = get_msg_prefix(gActiveMsgIdx);
    string t_style = llLinksetDataRead(prefix + "trans_out"); if (t_style == "") t_style = "Inherited";
    string t_speed = llLinksetDataRead(prefix + "trans_speed"); if (t_speed == "") t_speed = "Inherited";
    string t_color = llLinksetDataRead(prefix + "color_trans"); if (t_color == "") t_color = "Inherited";
    
    string text = "⬡ After FX: Transition Out ⬡\n";
    text += "--------------------------------------\n";
    text += "Style: " + t_style + "\n";
    text += "Speed: " + t_speed + "\n";
    text += "Flash Color: " + t_color + "\n";
    text += "--------------------------------------\n";
    
    list buttons = [
        "Out Style", "Out Speed", "Out Color",
        " ", " ", " ",
        " ", " ", " ",
        "Back", " ", " "
    ];
    open_dialog(text, buttons);
}

render_appearance_overrides()
{
    string prefix = get_msg_prefix(gActiveMsgIdx);
    string col = llLinksetDataRead(prefix + "color"); if (col == "") col = "Inherited";
    string alp = llLinksetDataRead(prefix + "alpha"); if (alp == "") alp = "Inherited";
    string hgt = llLinksetDataRead(prefix + "height"); if (hgt == "") hgt = "Inherited";
    string alg = llLinksetDataRead(prefix + "align"); if (alg == "") alg = "Inherited";
    
    string text = "⬡ Appearance Overrides ⬡\n";
    text += "--------------------------------------\n";
    text += "Start Color: " + col + "\n";
    text += "Alpha Override: " + alp + "\n";
    text += "Height Override: " + hgt + "\n";
    text += "Smart Align: " + alg + "\n";
    text += "--------------------------------------\n";
    
    list buttons = [
        "Start Color", "Alpha Override", "Height Override",
        "Smart Align", "Randomize All", " ",
        " ", " ", " ",
        "Back", " ", " "
    ];
    open_dialog(text, buttons);
}

render_fonts_menu()
{
    string active_font = "";
    if (gActiveMsgIdx == -1)
    {
        active_font = llLinksetDataRead("lsd:titler:active_font");
        if (active_font == "") active_font = "DEFAULT";
    }
    else
    {
        string prefix = get_msg_prefix(gActiveMsgIdx);
        active_font = llLinksetDataRead(prefix + "font");
        if (active_font == "") active_font = "Inherited";
    }
    
    string font_list = llLinksetDataRead("lsd:titler:font_list");
    list fonts = llParseString2List(font_list, ["|"], []);
    
    string text = "⬡ Fonts Configuration ⬡\n";
    if (gActiveMsgIdx == -1)
    {
        text += "Configuring: Global Default Font\n";
    }
    else
    {
        text += "Configuring: Msg " + (string)(gActiveMsgIdx + 1) + " Font\n";
    }
    text += "--------------------------------------\n";
    text += "Active Font: " + active_font + "\n";
    text += "--------------------------------------\n";
    
    list font_btns = [];
    if (gActiveMsgIdx == -1) font_btns += "DEFAULT";
    else                    font_btns += "default";
    
    integer i;
    for (i = gPageOffset; i < gPageOffset + 5 && i < llGetListLength(fonts); ++i)
    {
        font_btns += llList2String(fonts, i);
    }
    while (llGetListLength(font_btns) < 6) font_btns += " ";
    
    list buttons = [
        llList2String(font_btns, 3), llList2String(font_btns, 4), llList2String(font_btns, 5),
        llList2String(font_btns, 0), llList2String(font_btns, 1), llList2String(font_btns, 2),
        "Reload Notecard", " ", " ",
        "◀ Prev", "Next ▶", "Back"
    ];
    open_dialog(text, buttons);
}

render_roles_menu()
{
    string role_list = llLinksetDataRead("lsd:titler:role_list");
    list roles = llParseString2List(role_list, ["|"], []);
    integer r_count = llGetListLength(roles);
    
    string text = "⬡ Custom Roles Manager ⬡\n";
    text += "Page Offset: " + (string)(gPageOffset + 1) + "-" + (string)(gPageOffset + 6) + " (Total: " + (string)r_count + ")\n";
    text += "--------------------------------------\n";
    
    if (r_count == 0)
    {
        text += "No custom roles defined.\n";
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
    text += "--------------------------------------\n";
    
    list role_btns = [];
    integer i;
    for (i = gPageOffset; i < gPageOffset + 6 && i < r_count; ++i)
    {
        role_btns += llList2String(roles, i);
    }
    while (llGetListLength(role_btns) < 6) role_btns += " ";
    
    list buttons = [
        llList2String(role_btns, 3), llList2String(role_btns, 4), llList2String(role_btns, 5),
        llList2String(role_btns, 0), llList2String(role_btns, 1), llList2String(role_btns, 2),
        "Add Role", "Clear Roles", " ",
        "◀ Prev", "Next ▶", "Back"
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
    string queue_status = "Disabled (Silent)";
    string queue_btn = "[X] Queue";
    if (queue_updates == 1)
    {
        queue_status = "Enabled (Enqueue)";
        queue_btn = "[✔] Queue";
    }
    
    string text = "⬡ Status Progress Bar Menu ⬡\n";
    text += "--------------------------------------\n";
    text += "Tag Keyword: %" + tag + "%\n";
    text += "Open Channel: " + chan + "\n";
    text += "Bar Style: " + sty + "\n";
    text += "Bar Length: " + len + " chars\n";
    text += "Current Value: " + val + "%\n";
    text += "Queued Updates: " + queue_status + "\n";
    text += "--------------------------------------\n";
    
    list buttons = [
        "Set Style", "Set Length", "Set Value",
        "Set Tag Name", "Set Channel", queue_btn,
        " ", " ", " ",
        "Back", " ", " "
    ];
    open_dialog(text, buttons);
}

render_global_appearance()
{
    string col = llLinksetDataRead("lsd:titler:color"); if (col == "") col = "<1.0, 0.6, 0.8>";
    string alp = llLinksetDataRead("lsd:titler:alpha"); if (alp == "") alp = "1.0";
    string hgt = llLinksetDataRead("lsd:titler:height"); if (hgt == "") hgt = "0.5";
    string own = llLinksetDataRead("lsd:titler:owner_name"); if (own == "") own = "Inherit DisplayName";
    
    string text = "⬡ Global Appearance Defaults ⬡\n";
    text += "--------------------------------------\n";
    text += "Color (RGB): " + col + "\n";
    text += "Alpha (Opacity): " + alp + "\n";
    text += "Height (Offset): " + hgt + "m\n";
    text += "Owner Variable: " + own + "\n";
    text += "--------------------------------------\n";
    
    list buttons = [
        "Set Color", "Set Alpha", "Set Height",
        "Set Owner", " ", " ",
        " ", " ", " ",
        "Back", " ", " "
    ];
    open_dialog(text, buttons);
}

render_global_animation()
{
    string style = llLinksetDataRead("lsd:titler:anim_style"); if (style == "") style = "GLITCH";
    string speed = llLinksetDataRead("lsd:titler:trans_speed"); if (speed == "") speed = "0.15";
    string swid  = llLinksetDataRead("lsd:titler:scroll_width"); if (swid == "") swid = "20";
    
    integer sc = (integer)llLinksetDataRead("lsd:titler:scroll_enabled");
    string sc_tog = "Scroll ON"; if (sc == 1) sc_tog = "Scroll OFF";
    
    integer fk = (integer)llLinksetDataRead("lsd:titler:flicker_glitch");
    string fk_tog = "Flicker ON"; if (fk == 1) fk_tog = "Flicker OFF";
    
    string cursor = llLinksetDataRead("lsd:titler:typing_cursor"); if (cursor == "") cursor = "_";
    integer blink = (integer)llLinksetDataRead("lsd:titler:blink_cursor");
    string blink_status = "Enabled (Blinking)";
    string blink_tog = "[✔] Blink";
    if (blink == 0 && llLinksetDataRead("lsd:titler:blink_cursor") != "")
    {
        blink_status = "Disabled (Static)";
        blink_tog = "[X] Blink";
    }
    
    string text = "⬡ Global Animation Defaults ⬡\n";
    text += "--------------------------------------\n";
    text += "Transition Style: " + style + "\n";
    text += "Transition Speed: " + speed + "s\n";
    text += "Scroll Width: " + swid + " chars\n";
    text += "Typing Cursor: '" + cursor + "'\n";
    text += "Blinking Cursor: " + blink_status + "\n";
    text += "--------------------------------------\n";
    
    list buttons = [
        "Global Style", "Global Speed", "Set Cursor",
        "Scroll Width", sc_tog, fk_tog,
        blink_tog, " ", " ",
        "Back", " ", " "
    ];
    open_dialog(text, buttons);
}

render_style_selection(string context_to_set)
{
    string text = "⬡ Select Animation Style ⬡\n";
    text += "Configuring: " + context_to_set + "\n";
    text += "Choose one of the 8 rendering transition styles:";
    
    list buttons = [
        "MATRIX_VERT", "MATRIX_HORIZ", "SLIDE",
        "WIPE", "FADE", "TYPING",
        "GLITCH", "INSTANT", "default",
        "Back", " ", " "
    ];
    open_dialog(text, buttons);
}

render_global_trinkets()
{
    string style = llLinksetDataRead("lsd:titler:trinket_style"); if (style == "") style = "HEX";
    string pos   = llLinksetDataRead("lsd:titler:trinket_pos"); if (pos == "") pos = "BOTH";
    string speed = llLinksetDataRead("lsd:titler:trinket_speed"); if (speed == "") speed = "MED";
    
    string text = "⬡ Global Trinkets Defaults ⬡\n";
    text += "--------------------------------------\n";
    text += "Style: " + style + "\n";
    text += "Position: " + pos + "\n";
    text += "Speed: " + speed + "\n";
    text += "--------------------------------------\n";
    
    list buttons = [
        "Trink Style", "Trink Pos", "Trink Speed",
        " ", " ", " ",
        " ", " ", " ",
        "Back", " ", " "
    ];
    open_dialog(text, buttons);
}

render_trinket_style_select()
{
    string text = "⬡ Select Trinket Style ⬡\n";
    
    list buttons = [
        "DOTPULSE", "BEAR", "DANCE",
        "SPARK", "KITTY", "SLEEPY",
        "NONE", "HEX", "HEART",
        "SHY", "ZAP", "MUSIC"
    ];
    open_dialog(text, buttons);
}

render_cursor_selection()
{
    list cursor_btns = [
        "Bᴀᴄᴋ", " ", " ",
        "▊", "Nᴏɴᴇ", " ",
        "_", "|", "█"
    ];
    open_dialog("⬡ Cᴜʀsᴏʀ Sᴇʟᴇᴄᴛɪᴏɴ ⬡\nSᴇʟᴇᴄᴛ ᴛʏᴘɪɴɢ / ʙʟɪɴᴋɪɴɢ ᴄᴜʀsᴏʀ ꜰᴏʀᴍᴀᴛ:\n", cursor_btns);
}

clear_message_overrides(integer idx)
{
    string prefix = "lsd:titler:msg:" + (string)idx + ":";
    llLinksetDataDelete(prefix + "color");
    llLinksetDataDelete(prefix + "color_end");
    llLinksetDataDelete(prefix + "color_trans");
    llLinksetDataDelete(prefix + "alpha");
    llLinksetDataDelete(prefix + "height");
    llLinksetDataDelete(prefix + "align");
    llLinksetDataDelete(prefix + "trans_in");
    llLinksetDataDelete(prefix + "trans_out");
    llLinksetDataDelete(prefix + "trans_speed");
    llLinksetDataDelete(prefix + "trinket_style");
    llLinksetDataDelete(prefix + "trinket_pos");
    llLinksetDataDelete(prefix + "scroll_width");
    llLinksetDataDelete(prefix + "scroll_enabled");
    llLinksetDataDelete(prefix + "font");
    llLinksetDataDelete(prefix + "flicker_glitch");
    llLinksetDataDelete(prefix + "blink_cursor");
}

copy_msg(string from_pref, string to_pref)
{
    llLinksetDataWrite(to_pref + "text",           llLinksetDataRead(from_pref + "text"));
    llLinksetDataWrite(to_pref + "dur",            llLinksetDataRead(from_pref + "dur"));
    llLinksetDataWrite(to_pref + "color",          llLinksetDataRead(from_pref + "color"));
    llLinksetDataWrite(to_pref + "color_end",      llLinksetDataRead(from_pref + "color_end"));
    llLinksetDataWrite(to_pref + "color_trans",    llLinksetDataRead(from_pref + "color_trans"));
    llLinksetDataWrite(to_pref + "alpha",          llLinksetDataRead(from_pref + "alpha"));
    llLinksetDataWrite(to_pref + "height",         llLinksetDataRead(from_pref + "height"));
    llLinksetDataWrite(to_pref + "align",          llLinksetDataRead(from_pref + "align"));
    llLinksetDataWrite(to_pref + "trans_in",       llLinksetDataRead(from_pref + "trans_in"));
    llLinksetDataWrite(to_pref + "trans_out",      llLinksetDataRead(from_pref + "trans_out"));
    llLinksetDataWrite(to_pref + "trans_speed",    llLinksetDataRead(from_pref + "trans_speed"));
    llLinksetDataWrite(to_pref + "trinket_style",  llLinksetDataRead(from_pref + "trinket_style"));
    llLinksetDataWrite(to_pref + "trinket_pos",    llLinksetDataRead(from_pref + "trinket_pos"));
    llLinksetDataWrite(to_pref + "scroll_width",   llLinksetDataRead(from_pref + "scroll_width"));
    llLinksetDataWrite(to_pref + "scroll_enabled", llLinksetDataRead(from_pref + "scroll_enabled"));
    llLinksetDataWrite(to_pref + "font",           llLinksetDataRead(from_pref + "font"));
    llLinksetDataWrite(to_pref + "flicker_glitch", llLinksetDataRead(from_pref + "flicker_glitch"));
    llLinksetDataWrite(to_pref + "blink_cursor",   llLinksetDataRead(from_pref + "blink_cursor"));
}

clear_temp_msg()
{
    string prefix = "lsd:titler:temp_msg:";
    llLinksetDataDelete(prefix + "text"); llLinksetDataDelete(prefix + "dur");
    llLinksetDataDelete(prefix + "color"); llLinksetDataDelete(prefix + "color_end");
    llLinksetDataDelete(prefix + "color_trans"); llLinksetDataDelete(prefix + "alpha");
    llLinksetDataDelete(prefix + "height"); llLinksetDataDelete(prefix + "align");
    llLinksetDataDelete(prefix + "trans_in"); llLinksetDataDelete(prefix + "trans_out");
    llLinksetDataDelete(prefix + "trans_speed"); llLinksetDataDelete(prefix + "trinket_style");
    llLinksetDataDelete(prefix + "trinket_pos"); llLinksetDataDelete(prefix + "scroll_width");
    llLinksetDataDelete(prefix + "scroll_enabled"); llLinksetDataDelete(prefix + "font");
    llLinksetDataDelete(prefix + "flicker_glitch"); llLinksetDataDelete(prefix + "blink_cursor");
}

move_message(integer from_idx, integer to_idx)
{
    if (from_idx == to_idx) return;
    integer count = (integer)llLinksetDataRead("lsd:titler:msg_count");
    if (to_idx < 0 || to_idx >= count) return;
    
    string from_pref = "lsd:titler:msg:" + (string)from_idx + ":";
    string temp_pref = "lsd:titler:temp_msg:";
    copy_msg(from_pref, temp_pref);
    
    if (from_idx < to_idx)
    {
        integer i;
        for (i = from_idx; i < to_idx; ++i)
            copy_msg("lsd:titler:msg:" + (string)(i + 1) + ":", "lsd:titler:msg:" + (string)i + ":");
    }
    else
    {
        integer i;
        for (i = from_idx; i > to_idx; --i)
            copy_msg("lsd:titler:msg:" + (string)(i - 1) + ":", "lsd:titler:msg:" + (string)i + ":");
    }
    copy_msg(temp_pref, "lsd:titler:msg:" + (string)to_idx + ":");
    clear_temp_msg();
    
    integer active_play_idx = (integer)llLinksetDataRead("lsd:titler:active_msg_idx");
    if (active_play_idx == from_idx)
        llLinksetDataWrite("lsd:titler:active_msg_idx", (string)to_idx);
    else if (from_idx < to_idx)
    {
        if (active_play_idx > from_idx && active_play_idx <= to_idx)
            llLinksetDataWrite("lsd:titler:active_msg_idx", (string)(active_play_idx - 1));
    }
    else
    {
        if (active_play_idx >= to_idx && active_play_idx < from_idx)
            llLinksetDataWrite("lsd:titler:active_msg_idx", (string)(active_play_idx + 1));
    }
}

render_msg_editor()
{
    string prefix = get_msg_prefix(gActiveMsgIdx);
    string m_text = llLinksetDataRead(prefix + "text");
    if (llStringLength(m_text) > 30) m_text = llGetSubString(m_text, 0, 29) + "...";
    string m_dur  = llLinksetDataRead(prefix + "dur"); if (m_dur == "") m_dur = "4.0";
    integer dur_val = (integer)((float)m_dur);
    if (dur_val <= 0) dur_val = 4;
    string m_font = llLinksetDataRead(prefix + "font"); if (m_font == "") m_font = "Inherited";
    
    string text = "⬡ Mᴇssᴀɢᴇ Eᴅɪᴛᴏʀ: Msɢ " + (string)(gActiveMsgIdx + 1) + " ⬡\n" + gMenuDivider;
    
    string prev_text = llLinksetDataRead(prefix + "text");
    if (llStringLength(prev_text) > 80) prev_text = llGetSubString(prev_text, 0, 79) + "...";
    text += "« " + prev_text + " »\n" + gMenuDivider;
    
    text += "▸ Rᴀᴡ Tᴇxᴛ: \"" + m_text + "\"\n";
    text += "▸ Dᴜʀᴀᴛɪᴏɴ: " + (string)dur_val + "s\n";
    text += "▸ Fᴏɴᴛ: " + m_font + "\n" + gMenuDivider;
    text += "Eᴅɪᴛ ᴘᴀʀᴀᴍᴇᴛᴇʀs ᴏʀ sᴇʟᴇᴄᴛ sᴛʏʟᴇ:";
    
    list buttons = [
        "Bᴀᴄᴋ", "Sᴇᴛ Fᴏɴᴛ", "Mᴏᴠᴇ...",
        "Pʀᴇsᴇᴛs...", "Pʀᴇᴠɪᴇᴡ", "Dᴇʟᴇᴛᴇ",
        "Tʀᴀɴs Iɴ...", "Iᴅʟᴇ FX...", "Tʀᴀɴs Oᴜᴛ...",
        "Cʜᴀɴɢᴇ Tᴇxᴛ", "Dᴜʀᴀᴛɪᴏɴ", "Aᴘᴘᴇᴀʀ..."
    ];
    open_dialog(text, buttons);
}

render_presets_menu()
{
    string text = "⬡ Sᴛʏʟᴇ Pʀᴇsᴇᴛs ⬡\n" + gMenuDivider;
    text += "Apply quick style overrides to Msg " + (string)(gActiveMsgIdx + 1) + ":\n";
    text += "- Cyber: Neon green, matrix, hex trinkets\n";
    text += "- Princess: Pink, fade, heart trinkets\n";
    text += "- Terminal: White, typing, no trinkets\n";
    text += "- Glitch: Random color, glitch, flicker\n";
    text += "- Reset: Clear all local overrides";
    
    list buttons = [
        "Bᴀᴄᴋ", " ", " ",
        "Gʟɪᴛᴄʜ", "Rᴇsᴇᴛ", " ",
        "Cʏʙᴇʀ", "Pʀɪɴᴄᴇss", "Tᴇʀᴍɪɴᴀʟ"
    ];
    open_dialog(text, buttons);
}

render_msg_move_menu()
{
    integer count = (integer)llLinksetDataRead("lsd:titler:msg_count");
    string m_text = llLinksetDataRead(get_msg_prefix(gActiveMsgIdx) + "text");
    if (llStringLength(m_text) > 30) m_text = llGetSubString(m_text, 0, 29) + "...";
    
    string text = "⬡ Mᴏᴠᴇ Mᴇssᴀɢᴇ ⬡\n" + gMenuDivider;
    text += "▸ Cᴜʀʀᴇɴᴛ Pᴏsɪᴛɪᴏɴ: Msg " + (string)(gActiveMsgIdx + 1) + " ᴏꜰ " + (string)count + "\n";
    text += "▸ Rᴀᴡ Tᴇxᴛ: \"" + m_text + "\"\n" + gMenuDivider;
    text += "Sᴇʟᴇᴄᴛ ᴅɪʀᴇᴄᴛɪᴏɴ ᴏʀ ᴇɴᴛᴇʀ ᴛᴀʀɢᴇᴛ ɪɴᴅᴇx:";
    
    list buttons = [
        "Bᴀᴄᴋ", "▲ Mᴏᴠᴇ Uᴘ", "Mᴏᴠᴇ Dᴏᴡɴ ▼",
        "Mᴏᴠᴇ Tᴏ...", " ", " ",
        " ", " ", " ",
        " ", " ", " "
    ];
    open_dialog(text, buttons);
}

refresh_menu()
{
    if (gMenuContext == "msg_edit") render_msg_editor();
    else if (gMenuContext == "presets") render_presets_menu();
    else if (gMenuContext == "msg_move") render_msg_move_menu();
    else if (gMenuContext == "before_fx") render_before_fx();
    else if (gMenuContext == "during_fx") render_during_fx();
    else if (gMenuContext == "after_fx") render_after_fx();
    else if (gMenuContext == "appearance") render_appearance_overrides();
    else if (gMenuContext == "fonts") render_fonts_menu();
    else if (gMenuContext == "roles") render_roles_menu();
    else if (gMenuContext == "status_tag") render_status_tag_menu();
    else if (gMenuContext == "global_appearance") render_global_appearance();
    else if (gMenuContext == "global_animation") render_global_animation();
    else if (gMenuContext == "global_trinkets") render_global_trinkets();
    else if (llSubStringIndex(gMenuContext, "select_style:") == 0) render_style_selection(gMenuContext);
    else if (gMenuContext == "select_trink_style") render_trinket_style_select();
    else if (gMenuContext == "select_cursor") render_cursor_selection();
}

default
{
    state_entry()
    {
        llSetMemoryLimit(65536);
    }

    link_message(integer sender_num, integer code, string str, key id)
    {
        // Code 189: Handoff from main menu script
        if (code == 189)
        {
            list parts = llParseString2List(str, ["|"], []);
            string action = llList2String(parts, 0);
            
            if (action == "HANDOFF")
            {
                string target_context = llList2String(parts, 1);
                
                if (is_override_context(target_context))
                {
                    gMenuContext = target_context;
                    gActiveMsgIdx = (integer)llList2String(parts, 2);
                    gParentPageOffset = (integer)llList2String(parts, 3);
                    gPageOffset = gParentPageOffset;
                    
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
            
            // --- Text Box Processing ---
            if (llSubStringIndex(gMenuContext, "textbox:") == 0)
            {
                string action = llGetSubString(gMenuContext, 8, -1);
                string prefix = get_msg_prefix(gActiveMsgIdx);
                
                if (action == "msg_text")
                {
                    llLinksetDataWrite(prefix + "text", cmd);
                    llMessageLinked(LINK_SET, 180, "RELOAD", NULL_KEY);
                    gMenuContext = "msg_edit";
                    refresh_menu();
                    return;
                }
                if (action == "msg_dur")
                {
                    llLinksetDataWrite(prefix + "dur", cmd);
                    llMessageLinked(LINK_SET, 180, "RELOAD", NULL_KEY);
                    gMenuContext = "msg_edit";
                    refresh_menu();
                    return;
                }
                if (action == "msg_move_to")
                {
                    integer target_pos = (integer)cmd;
                    integer m_count = (integer)llLinksetDataRead("lsd:titler:msg_count");
                    if (target_pos < 1 || target_pos > m_count)
                        llOwnerSay("Invalid position. Must be between 1 and " + (string)m_count + ".");
                    else
                    {
                        integer target_idx = target_pos - 1;
                        move_message(gActiveMsgIdx, target_idx);
                        gActiveMsgIdx = target_idx;
                        llMessageLinked(LINK_SET, 180, "RELOAD", NULL_KEY);
                    }
                    gMenuContext = "msg_move";
                    refresh_menu();
                    return;
                }
                if (action == "msg_in_speed")
                {
                    llLinksetDataWrite(prefix + "trans_speed", cmd);
                    llMessageLinked(LINK_SET, 180, "RELOAD", NULL_KEY);
                    gMenuContext = "before_fx";
                    refresh_menu();
                    return;
                }
                if (action == "msg_in_color")
                {
                    llLinksetDataWrite(prefix + "color_trans", cmd);
                    llMessageLinked(LINK_SET, 180, "RELOAD", NULL_KEY);
                    gMenuContext = "before_fx";
                    refresh_menu();
                    return;
                }
                if (action == "msg_out_speed")
                {
                    llLinksetDataWrite(prefix + "trans_speed", cmd);
                    llMessageLinked(LINK_SET, 180, "RELOAD", NULL_KEY);
                    gMenuContext = "after_fx";
                    refresh_menu();
                    return;
                }
                if (action == "msg_out_color")
                {
                    llLinksetDataWrite(prefix + "color_trans", cmd);
                    llMessageLinked(LINK_SET, 180, "RELOAD", NULL_KEY);
                    gMenuContext = "after_fx";
                    refresh_menu();
                    return;
                }
                if (action == "msg_scroll_width")
                {
                    llLinksetDataWrite(prefix + "scroll_width", cmd);
                    llMessageLinked(LINK_SET, 180, "RELOAD", NULL_KEY);
                    gMenuContext = "during_fx";
                    refresh_menu();
                    return;
                }
                if (action == "msg_start_color")
                {
                    llLinksetDataWrite(prefix + "color", cmd);
                    llMessageLinked(LINK_SET, 180, "RELOAD", NULL_KEY);
                    gMenuContext = "appearance";
                    refresh_menu();
                    return;
                }
                if (action == "msg_alpha")
                {
                    llLinksetDataWrite(prefix + "alpha", cmd);
                    llMessageLinked(LINK_SET, 180, "RELOAD", NULL_KEY);
                    gMenuContext = "appearance";
                    refresh_menu();
                    return;
                }
                if (action == "msg_height")
                {
                    llLinksetDataWrite(prefix + "height", cmd);
                    llMessageLinked(LINK_SET, 180, "RELOAD", NULL_KEY);
                    gMenuContext = "appearance";
                    refresh_menu();
                    return;
                }
                
                // Global updates
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
                if (action == "g_owner")
                {
                    llLinksetDataWrite("lsd:titler:owner_name", cmd);
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
            if (cmd == BTN_FILLER) return;
            
            if (cmd == "Back" || cmd == "Bᴀᴄᴋ")
            {
                string handin_context = "main";
                
                if (gMenuContext == "before_fx") handin_context = "msg_edit";
                else if (gMenuContext == "during_fx") handin_context = "msg_edit";
                else if (gMenuContext == "after_fx") handin_context = "msg_edit";
                else if (gMenuContext == "appearance") handin_context = "msg_edit";
                else if (gMenuContext == "fonts" && gActiveMsgIdx >= 0) handin_context = "msg_edit";
                else if (gMenuContext == "msg_edit") handin_context = "messages";
                else if (gMenuContext == "presets" || gMenuContext == "msg_move")
                {
                    gMenuContext = "msg_edit";
                    refresh_menu();
                    return;
                }
                else if (llSubStringIndex(gMenuContext, "select_style:") == 0)
                {
                    list parts = llParseString2List(gMenuContext, [":"], []);
                    gMenuContext = llList2String(parts, 1);
                    refresh_menu();
                    return;
                }
                else if (gMenuContext == "select_trink_style")
                {
                    if (gActiveMsgIdx == -1) gMenuContext = "global_trinkets";
                    else                    gMenuContext = "during_fx";
                    refresh_menu();
                    return;
                }
                else if (gMenuContext == "select_cursor")
                {
                    gMenuContext = "global_animation";
                    refresh_menu();
                    return;
                }
                
                gMenuContext = "";
                if (gMenuListen != 0) { llListenRemove(gMenuListen); gMenuListen = 0; }
                llMessageLinked(LINK_SET, 189, "HANDOFF|" + handin_context + "|" + (string)gActiveMsgIdx + "|" + (string)gParentPageOffset, id);
                return;
            }

            if (gMenuContext == "before_fx")
            {
                if (cmd == "In Style")
                {
                    gMenuContext = "select_style:before_fx";
                    render_style_selection(gMenuContext);
                }
                else if (cmd == "In Speed")
                {
                    gMenuContext = "textbox:msg_in_speed";
                    open_textbox("Enter Transition In tick speed in seconds (or RANDOM/default):");
                }
                else if (cmd == "In Color")
                {
                    gMenuContext = "textbox:msg_in_color";
                    open_textbox("Enter Transition In entry flash color vector (e.g. 1 1 1 or RANDOM/default):");
                }
                return;
            }

            if (gMenuContext == "during_fx")
            {
                if (cmd == "Trink Style")
                {
                    gMenuContext = "select_trink_style";
                    render_trinket_style_select();
                }
                else if (cmd == "Trink Pos")
                {
                    string prefix = "lsd:titler:msg:" + (string)gActiveMsgIdx + ":";
                    string tpos = llLinksetDataRead(prefix + "trinket_pos");
                    if (tpos == "" || tpos == "BOTH")      tpos = "PREFIX";
                    else if (tpos == "PREFIX") tpos = "SUFFIX";
                    else                       tpos = "BOTH";
                    llLinksetDataWrite(prefix + "trinket_pos", tpos);
                    llMessageLinked(LINK_SET, 180, "RELOAD", NULL_KEY);
                    render_during_fx();
                }
                else if (cmd == "Scroll Width")
                {
                    gMenuContext = "textbox:msg_scroll_width";
                    open_textbox("Enter scroll width boundary (e.g. 20 or default):");
                }
                else if (cmd == "Scroll Toggle")
                {
                    string prefix = "lsd:titler:msg:" + (string)gActiveMsgIdx + ":";
                    string sc = llLinksetDataRead(prefix + "scroll_enabled");
                    if (sc == "" || sc == "1") sc = "0";
                    else                      sc = "1";
                    llLinksetDataWrite(prefix + "scroll_enabled", sc);
                    llMessageLinked(LINK_SET, 180, "RELOAD", NULL_KEY);
                    render_during_fx();
                }
                else if (cmd == "Flicker Toggle")
                {
                    string prefix = "lsd:titler:msg:" + (string)gActiveMsgIdx + ":";
                    string flick = llLinksetDataRead(prefix + "flicker_glitch");
                    if (flick == "") flick = "1";
                    else if (flick == "1") flick = "0";
                    else flick = "";
                    
                    llLinksetDataWrite(prefix + "flicker_glitch", flick);
                    llMessageLinked(LINK_SET, 180, "RELOAD", NULL_KEY);
                    render_during_fx();
                }
                else if (cmd == "Blink Toggle")
                {
                    string prefix = "lsd:titler:msg:" + (string)gActiveMsgIdx + ":";
                    string blink = llLinksetDataRead(prefix + "blink_cursor");
                    if (blink == "") blink = "1";
                    else if (blink == "1") blink = "0";
                    else blink = "";
                    
                    llLinksetDataWrite(prefix + "blink_cursor", blink);
                    llMessageLinked(LINK_SET, 180, "RELOAD", NULL_KEY);
                    render_during_fx();
                }
                return;
            }

            if (gMenuContext == "after_fx")
            {
                if (cmd == "Out Style")
                {
                    gMenuContext = "select_style:after_fx";
                    render_style_selection(gMenuContext);
                }
                else if (cmd == "Out Speed")
                {
                    gMenuContext = "textbox:msg_out_speed";
                    open_textbox("Enter Transition Out tick speed in seconds (or RANDOM/default):");
                }
                else if (cmd == "Out Color")
                {
                    gMenuContext = "textbox:msg_out_color";
                    open_textbox("Enter Transition Out exit flash color vector (e.g. 0 0 0 or RANDOM/default):");
                }
                return;
            }

            if (gMenuContext == "appearance")
            {
                if (cmd == "Start Color")
                {
                    gMenuContext = "textbox:msg_start_color";
                    open_textbox("Enter text start color vector (e.g. 1 0.5 0.5 or RANDOM/default):");
                }
                else if (cmd == "Alpha Override")
                {
                    gMenuContext = "textbox:msg_alpha";
                    open_textbox("Enter alpha float 0.0 - 1.0 (or RANDOM/default):");
                }
                else if (cmd == "Height Override")
                {
                    gMenuContext = "textbox:msg_height";
                    open_textbox("Enter vertical offset height float (or RANDOM/default):");
                }
                else if (cmd == "Smart Align")
                {
                    string prefix = "lsd:titler:msg:" + (string)gActiveMsgIdx + ":";
                    string alg = llLinksetDataRead(prefix + "align");
                    if (alg == "" || alg == "CENTER") alg = "LEFT";
                    else if (alg == "LEFT")          alg = "RIGHT";
                    else if (alg == "RIGHT")         alg = "CENTER";
                    
                    llLinksetDataWrite(prefix + "align", alg);
                    llMessageLinked(LINK_SET, 180, "RELOAD", NULL_KEY);
                    render_appearance_overrides();
                }
                else if (cmd == "Randomize All")
                {
                    string prefix = "lsd:titler:msg:" + (string)gActiveMsgIdx + ":";
                    llLinksetDataWrite(prefix + "color", "RANDOM");
                    llLinksetDataWrite(prefix + "alpha", "RANDOM");
                    llLinksetDataWrite(prefix + "height", "RANDOM");
                    llLinksetDataWrite(prefix + "align", "RANDOM");
                    llLinksetDataWrite(prefix + "trans_in", "RANDOM");
                    llLinksetDataWrite(prefix + "trans_out", "RANDOM");
                    llLinksetDataWrite(prefix + "dur", "RANDOM");
                    llMessageLinked(LINK_SET, 180, "RELOAD", NULL_KEY);
                    render_appearance_overrides();
                }
                return;
            }

            if (llSubStringIndex(gMenuContext, "select_style:") == 0)
            {
                list parts = llParseString2List(gMenuContext, [":"], []);
                string dest = llList2String(parts, 1);
                string prefix = "lsd:titler:msg:" + (string)gActiveMsgIdx + ":";
                
                string key_to_write = prefix + "trans_in";
                if (dest == "after_fx") key_to_write = prefix + "trans_out";
                if (dest == "global_animation") key_to_write = "lsd:titler:anim_style";
                
                string val = cmd;
                if (val == "default") val = "";
                
                llLinksetDataWrite(key_to_write, val);
                llMessageLinked(LINK_SET, 180, "RELOAD", NULL_KEY);
                
                gMenuContext = dest;
                refresh_menu();
                return;
            }

            if (gMenuContext == "select_trink_style")
            {
                string val = cmd;
                if (gActiveMsgIdx == -1)
                {
                    llLinksetDataWrite("lsd:titler:trinket_style", val);
                    gMenuContext = "global_trinkets";
                }
                else
                {
                    llLinksetDataWrite("lsd:titler:msg:" + (string)gActiveMsgIdx + ":trinket_style", val);
                    gMenuContext = "during_fx";
                }
                llMessageLinked(LINK_SET, 180, "RELOAD", NULL_KEY);
                refresh_menu();
                return;
            }

            if (gMenuContext == "global_appearance")
            {
                if (cmd == "Set Color")
                {
                    gMenuContext = "textbox:g_color";
                    open_textbox("Enter default color vector (e.g. 1.0 0.6 0.8):");
                }
                else if (cmd == "Set Alpha")
                {
                    gMenuContext = "textbox:g_alpha";
                    open_textbox("Enter default alpha opacity float (0.0 - 1.0):");
                }
                else if (cmd == "Set Height")
                {
                    gMenuContext = "textbox:g_height";
                    open_textbox("Enter default floating height offset (e.g. 0.5):");
                }
                else if (cmd == "Set Owner")
                {
                    gMenuContext = "textbox:g_owner";
                    open_textbox("Enter custom Owner Name string (resolves %owner%):");
                }
                return;
            }

            if (gMenuContext == "global_animation")
            {
                if (cmd == "Global Style")
                {
                    gMenuContext = "select_style:global_animation";
                    render_style_selection(gMenuContext);
                }
                else if (cmd == "Global Speed")
                {
                    gMenuContext = "textbox:g_speed";
                    open_textbox("Enter default Transition speed in seconds:");
                }
                else if (cmd == "Scroll Width")
                {
                    gMenuContext = "textbox:g_scroll_width";
                    open_textbox("Enter default scroll character width boundary:");
                }
                else if (cmd == "Scroll ON" || cmd == "Scroll OFF")
                {
                    integer sc = (integer)llLinksetDataRead("lsd:titler:scroll_enabled");
                    if (sc == 1) llLinksetDataWrite("lsd:titler:scroll_enabled", "0");
                    else         llLinksetDataWrite("lsd:titler:scroll_enabled", "1");
                    llMessageLinked(LINK_SET, 180, "RELOAD", NULL_KEY);
                    render_global_animation();
                }
                else if (cmd == "Flicker ON" || cmd == "Flicker OFF")
                {
                    integer fk = (integer)llLinksetDataRead("lsd:titler:flicker_glitch");
                    if (fk == 1) llLinksetDataWrite("lsd:titler:flicker_glitch", "0");
                    else         llLinksetDataWrite("lsd:titler:flicker_glitch", "1");
                    llMessageLinked(LINK_SET, 180, "RELOAD", NULL_KEY);
                    render_global_animation();
                }
                else if (cmd == "Set Cursor")
                {
                    gMenuContext = "select_cursor";
                    render_cursor_selection();
                }
                else if (cmd == "[✔] Blink" || cmd == "[X] Blink")
                {
                    integer blink = (integer)llLinksetDataRead("lsd:titler:blink_cursor");
                    if (llLinksetDataRead("lsd:titler:blink_cursor") == "") blink = 1;
                    llLinksetDataWrite("lsd:titler:blink_cursor", (string)(1 - blink));
                    llMessageLinked(LINK_SET, 180, "RELOAD", NULL_KEY);
                    render_global_animation();
                }
                return;
            }
            
            if (gMenuContext == "select_cursor")
            {
                if (cmd != "Back")
                {
                    string to_save = cmd;
                    if (to_save == "None") to_save = "none";
                    llLinksetDataWrite("lsd:titler:typing_cursor", to_save);
                    llMessageLinked(LINK_SET, 180, "RELOAD", NULL_KEY);
                }
                gMenuContext = "global_animation";
                render_global_animation();
                return;
            }

            if (gMenuContext == "global_trinkets")
            {
                if (cmd == "Trink Style")
                {
                    gActiveMsgIdx = -1;
                    gMenuContext = "select_trink_style";
                    render_trinket_style_select();
                }
                else if (cmd == "Trink Pos")
                {
                    string pos = llLinksetDataRead("lsd:titler:trinket_pos");
                    if (pos == "" || pos == "BOTH")      pos = "PREFIX";
                    else if (pos == "PREFIX") pos = "SUFFIX";
                    else                       pos = "BOTH";
                    llLinksetDataWrite("lsd:titler:trinket_pos", pos);
                    llMessageLinked(LINK_SET, 180, "RELOAD", NULL_KEY);
                    render_global_trinkets();
                }
                else if (cmd == "Trink Speed")
                {
                    string spd = llLinksetDataRead("lsd:titler:trinket_speed");
                    if (spd == "" || spd == "MED") spd = "FAST";
                    else if (spd == "FAST")       spd = "SLOW";
                    else                          spd = "MED";
                    llLinksetDataWrite("lsd:titler:trinket_speed", spd);
                    llMessageLinked(LINK_SET, 180, "RELOAD", NULL_KEY);
                    render_global_trinkets();
                }
                return;
            }

            if (gMenuContext == "msg_edit")
            {
                if (cmd == "Mᴏᴠᴇ..." || cmd == "Move...")
                {
                    gMenuContext = "msg_move";
                    render_msg_move_menu();
                    return;
                }
                if (cmd == "Cʜᴀɴɢᴇ Tᴇxᴛ" || cmd == "Change Text")
                {
                    gMenuContext = "textbox:msg_text";
                    open_textbox("Enter new message text:");
                    return;
                }
                if (cmd == "Dᴜʀᴀᴛɪᴏɴ" || cmd == "Duration")
                {
                    gMenuContext = "textbox:msg_dur";
                    open_textbox("Enter display duration (or RANDOM):");
                    return;
                }
                if (cmd == "Pʀᴇsᴇᴛs..." || cmd == "Presets...")
                {
                    gMenuContext = "presets";
                    render_presets_menu();
                    return;
                }
                if (cmd == "Pʀᴇᴠɪᴇᴡ" || cmd == "Preview")
                {
                    string preview_txt = llLinksetDataRead(get_msg_prefix(gActiveMsgIdx) + "text");
                    llMessageLinked(LINK_SET, 182, preview_txt, NULL_KEY);
                    render_msg_editor();
                    return;
                }
                if (cmd == "Dᴇʟᴇᴛᴇ" || cmd == "Delete")
                {
                    integer count = (integer)llLinksetDataRead("lsd:titler:msg_count");
                    clear_message_overrides(gActiveMsgIdx);
                    integer i;
                    for (i = gActiveMsgIdx; i < count - 1; ++i)
                    {
                        string next_pref = "lsd:titler:msg:" + (string)(i + 1) + ":";
                        string curr_pref = "lsd:titler:msg:" + (string)i + ":";
                        copy_msg(next_pref, curr_pref);
                    }
                    string last_pref = "lsd:titler:msg:" + (string)(count - 1) + ":";
                    llLinksetDataDelete(last_pref + "text");
                    llLinksetDataDelete(last_pref + "dur");
                    clear_message_overrides(count - 1);
                    llLinksetDataWrite("lsd:titler:msg_count", (string)(count - 1));
                    llMessageLinked(LINK_SET, 180, "RELOAD", NULL_KEY);
                    gMenuContext = "";
                    if (gMenuListen != 0) { llListenRemove(gMenuListen); gMenuListen = 0; }
                    llMessageLinked(LINK_SET, 189, "HANDOFF|messages|-1|" + (string)gParentPageOffset, id);
                    return;
                }
                if (cmd == "Sᴇᴛ Fᴏɴᴛ" || cmd == "Set Font")
                {
                    gMenuContext = "fonts";
                    render_fonts_menu();
                    return;
                }
                if (cmd == "Tʀᴀɴs Iɴ..." || cmd == "Trans In...")
                {
                    gMenuContext = "before_fx";
                    refresh_menu();
                    return;
                }
                if (cmd == "Iᴅʟᴇ FX..." || cmd == "Idle FX...")
                {
                    gMenuContext = "during_fx";
                    refresh_menu();
                    return;
                }
                if (cmd == "Tʀᴀɴs Oᴜᴛ..." || cmd == "Trans Out...")
                {
                    gMenuContext = "after_fx";
                    refresh_menu();
                    return;
                }
                if (cmd == "Aᴘᴘᴇᴀʀ..." || cmd == "Appear...")
                {
                    gMenuContext = "appearance";
                    refresh_menu();
                    return;
                }
                return;
            }

            if (gMenuContext == "msg_move")
            {
                if (cmd == "▲ Mᴏᴠᴇ Uᴘ" || cmd == "Move Up")
                {
                    if (gActiveMsgIdx > 0)
                    {
                        move_message(gActiveMsgIdx, gActiveMsgIdx - 1);
                        gActiveMsgIdx = gActiveMsgIdx - 1;
                        llMessageLinked(LINK_SET, 180, "RELOAD", NULL_KEY);
                    }
                    else llOwnerSay("Message is already at the beginning.");
                    render_msg_move_menu();
                    return;
                }
                if (cmd == "Mᴏᴠᴇ Dᴏᴡɴ ▼" || cmd == "Move Down")
                {
                    integer count = (integer)llLinksetDataRead("lsd:titler:msg_count");
                    if (gActiveMsgIdx < count - 1)
                    {
                        move_message(gActiveMsgIdx, gActiveMsgIdx + 1);
                        gActiveMsgIdx = gActiveMsgIdx + 1;
                        llMessageLinked(LINK_SET, 180, "RELOAD", NULL_KEY);
                    }
                    else llOwnerSay("Message is already at the end.");
                    render_msg_move_menu();
                    return;
                }
                if (cmd == "Mᴏᴠᴇ Tᴏ..." || cmd == "Move To...")
                {
                    gMenuContext = "textbox:msg_move_to";
                    open_textbox("Enter target position (1 to " + llLinksetDataRead("lsd:titler:msg_count") + "):");
                    return;
                }
                return;
            }

            if (gMenuContext == "presets")
            {
                string prefix = get_msg_prefix(gActiveMsgIdx);
                if (cmd == "Cʏʙᴇʀ" || cmd == "Cyber")
                {
                    clear_message_overrides(gActiveMsgIdx);
                    llLinksetDataWrite(prefix + "color", "<0.0, 1.0, 0.2>");
                    llLinksetDataWrite(prefix + "trans_in", "MATRIX_VERT");
                    llLinksetDataWrite(prefix + "trans_out", "MATRIX_VERT");
                    llLinksetDataWrite(prefix + "trinket_style", "HEX");
                    llMessageLinked(LINK_SET, 180, "RELOAD", NULL_KEY);
                    gMenuContext = "msg_edit"; render_msg_editor();
                }
                else if (cmd == "Pʀɪɴᴄᴇss" || cmd == "Princess")
                {
                    clear_message_overrides(gActiveMsgIdx);
                    llLinksetDataWrite(prefix + "color", "<1.0, 0.4, 0.7>");
                    llLinksetDataWrite(prefix + "trans_in", "FADE");
                    llLinksetDataWrite(prefix + "trans_out", "FADE");
                    llLinksetDataWrite(prefix + "trinket_style", "HEART");
                    llMessageLinked(LINK_SET, 180, "RELOAD", NULL_KEY);
                    gMenuContext = "msg_edit"; render_msg_editor();
                }
                else if (cmd == "Tᴇʀᴍɪɴᴀʟ" || cmd == "Terminal")
                {
                    clear_message_overrides(gActiveMsgIdx);
                    llLinksetDataWrite(prefix + "color", "<1.0, 1.0, 1.0>");
                    llLinksetDataWrite(prefix + "trans_in", "TYPING");
                    llLinksetDataWrite(prefix + "trans_out", "TYPING");
                    llLinksetDataWrite(prefix + "trinket_style", "NONE");
                    llMessageLinked(LINK_SET, 180, "RELOAD", NULL_KEY);
                    gMenuContext = "msg_edit"; render_msg_editor();
                }
                else if (cmd == "Gʟɪᴛᴄʜ" || cmd == "Glitch")
                {
                    clear_message_overrides(gActiveMsgIdx);
                    llLinksetDataWrite(prefix + "color", "RANDOM");
                    llLinksetDataWrite(prefix + "color_end", "RANDOM");
                    llLinksetDataWrite(prefix + "color_trans", "RANDOM");
                    llLinksetDataWrite(prefix + "trans_in", "GLITCH");
                    llLinksetDataWrite(prefix + "trans_out", "GLITCH");
                    llLinksetDataWrite(prefix + "flicker_glitch", "1");
                    llMessageLinked(LINK_SET, 180, "RELOAD", NULL_KEY);
                    gMenuContext = "msg_edit"; render_msg_editor();
                }
                else if (cmd == "Rᴇsᴇᴛ" || cmd == "Reset")
                {
                    clear_message_overrides(gActiveMsgIdx);
                    llMessageLinked(LINK_SET, 180, "RELOAD", NULL_KEY);
                    gMenuContext = "msg_edit"; render_msg_editor();
                }
                return;
            }

            if (gMenuContext == "fonts")
            {
                if (cmd == "Reload Notecard")
                {
                    llMessageLinked(LINK_SET, 180, "RELOAD_FONTS", NULL_KEY);
                    render_fonts_menu();
                    return;
                }
                if (cmd == "◀ Prev")
                {
                    if (gPageOffset >= 5) gPageOffset -= 5;
                    render_fonts_menu();
                    return;
                }
                if (cmd == "Next ▶")
                {
                    string font_list = llLinksetDataRead("lsd:titler:font_list");
                    list fonts = llParseString2List(font_list, ["|"], []);
                    if (gPageOffset + 5 < llGetListLength(fonts)) gPageOffset += 5;
                    render_fonts_menu();
                    return;
                }
                
                // Select font
                if (cmd != " " && cmd != "")
                {
                    if (gActiveMsgIdx == -1)
                    {
                        llLinksetDataWrite("lsd:titler:active_font", cmd);
                    }
                    else
                    {
                        string prefix = "lsd:titler:msg:" + (string)gActiveMsgIdx + ":";
                        string to_save = cmd;
                        if (to_save == "default") to_save = "";
                        llLinksetDataWrite(prefix + "font", to_save);
                    }
                    llMessageLinked(LINK_SET, 180, "RELOAD", NULL_KEY);
                    render_fonts_menu();
                }
                return;
            }

            if (gMenuContext == "roles")
            {
                if (cmd == "Add Role")
                {
                    gMenuContext = "textbox:add_role_name";
                    open_textbox("Enter custom role keyword (e.g. master, pet):");
                    return;
                }
                if (cmd == "Clear Roles")
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
                if (cmd == "◀ Prev")
                {
                    if (gPageOffset >= 6) gPageOffset -= 6;
                    render_roles_menu();
                    return;
                }
                if (cmd == "Next ▶")
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
                    string curr_val = llLinksetDataRead("lsd:titler:role:" + cmd);
                    open_textbox("Edit value for %role:" + cmd + "% (currently: \"" + curr_val + "\"):");
                }
                return;
            }

            if (gMenuContext == "status_tag")
            {
                if (cmd == "Set Tag Name")
                {
                    gMenuContext = "textbox:tag_name";
                    open_textbox("Enter percentage status bar tag keyword (e.g. battery, sanity):");
                }
                else if (cmd == "Set Channel")
                {
                    gMenuContext = "textbox:tag_chan";
                    open_textbox("Enter chat channel to listen for percentage updates (0 for public chat or any integer):");
                }
                else if (cmd == "Set Length")
                {
                    gMenuContext = "textbox:tag_len";
                    open_textbox("Enter status bar character length (range 5 - 15):");
                }
                else if (cmd == "Set Value")
                {
                    gMenuContext = "textbox:tag_val";
                    open_textbox("Enter custom percentage value (0.0 to 100.0):");
                }
                else if (cmd == "Set Style")
                {
                    list style_btns = ["BLOCK", "HEART", "SPARK", "Back"];
                    open_dialog("Select status bar styling format:", style_btns);
                }
                
                else if (cmd == "BLOCK" || cmd == "HEART" || cmd == "SPARK")
                {
                    llLinksetDataWrite("lsd:titler:status_bar_style", cmd);
                    llMessageLinked(LINK_SET, 180, "RELOAD", NULL_KEY);
                    render_status_tag_menu();
                }
                else if (cmd == "[✔] Queue" || cmd == "[X] Queue")
                {
                    integer queue_updates = (integer)llLinksetDataRead("lsd:titler:queue_status_updates");
                    llLinksetDataWrite("lsd:titler:queue_status_updates", (string)(1 - queue_updates));
                    render_status_tag_menu();
                }
                return;
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
