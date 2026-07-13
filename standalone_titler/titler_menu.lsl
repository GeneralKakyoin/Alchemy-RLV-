// titler_menu.lsl — Standalone Configuration Menu (Part 1 - Main & Messages)
// Manages dialog pagination, user touch inputs, chat commands, presets, and text box configuration.
// Split menu architecture to avoid Stack-Heap Collision.

// Link Message Codes:
// Code 180 (Out): RELOAD -> Tells loader/parser to reload configuration
// Code 181 (Out): 1 (Enable) or 0 (Disable) -> Enable/disable state toggle
// Code 182 (Out): (Raw text) -> Sends preview string to parser/engine
// Code 189 (In/Out): HANDOFF|context|msgIdx|pageOffset (User key) -> Handoff control between menus

integer gMenuChannel = 0;
integer gMenuListen = 0;
integer gMenuUserChannel = 5;
integer gUserListen = 0;

string  gMenuContext = "main"; // main, messages, msg_edit, presets
integer gPageOffset = 0;
integer gActiveMsgIdx = -1; // message index being edited

// Check if context belongs to the overrides menu script
integer is_override_context(string context)
{
    if (context == "before_fx" || context == "during_fx" || context == "after_fx" ||
        context == "appearance" || context == "global_appearance" || context == "global_animation" ||
        context == "global_trinkets" || context == "fonts" || context == "roles" || context == "status_tag" ||
        llSubStringIndex(context, "select_style:") == 0 || context == "select_trink_style")
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
    llDialog(llGetOwner(), text, buttons, gMenuChannel);
    llSetTimerEvent(60.0); // 60s timeout
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

update_user_listener()
{
    if (gUserListen != 0)
    {
        llListenRemove(gUserListen);
        gUserListen = 0;
    }
    
    string chan_str = llLinksetDataRead("lsd:titler:menu_channel");
    if (chan_str == "")
    {
        gMenuUserChannel = 5;
        llLinksetDataWrite("lsd:titler:menu_channel", "5");
    }
    else
    {
        gMenuUserChannel = (integer)chan_str;
    }
    
    if (gMenuUserChannel != 0)
    {
        gUserListen = llListen(gMenuUserChannel, "", llGetOwner(), "");
    }
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

render_main_menu()
{
    integer enabled = (integer)llLinksetDataRead("lsd:titler:enabled");
    string  style   = llLinksetDataRead("lsd:titler:anim_style"); if (style == "") style = "GLITCH";
    string  active_font = llLinksetDataRead("lsd:titler:active_font"); if (active_font == "") active_font = "DEFAULT";
    
    string status = "🔴 Disabled";
    if (enabled == 1) status = "🟢 Enabled";
    
    string text = "⬡ Nexus Titler Main Menu ⬡\n";
    text += "--------------------------------------\n";
    text += "Status: " + status + "\n";
    text += "Global Style: " + style + "\n";
    text += "Active Font: " + active_font + "\n";
    text += "--------------------------------------\n";
    text += "Select a configuration panel:";
    
    string toggle_btn = "Enable";
    if (enabled == 1) toggle_btn = "Disable";
    
    list buttons = [
        "Fonts", "Roles", "Status Tag",
        "Appearance", "Animation", "Trinkets",
        "Messages", toggle_btn, " ",
        "Close", " ", " "
    ];
    open_dialog(text, buttons);
}

render_messages_menu()
{
    integer count = (integer)llLinksetDataRead("lsd:titler:msg_count");
    string text = "⬡ Messages Manager ⬡\n";
    text += "Page Offset: " + (string)(gPageOffset + 1) + "-" + (string)(gPageOffset + 6) + " (Total: " + (string)count + ")\n";
    text += "--------------------------------------\n";
    
    if (count == 0)
    {
        text += "No messages saved. Falls back to default.\n";
    }
    else
    {
        integer i;
        for (i = gPageOffset; i < gPageOffset + 6 && i < count; ++i)
        {
            string m_text = llLinksetDataRead("lsd:titler:msg:" + (string)i + ":text");
            string m_dur  = llLinksetDataRead("lsd:titler:msg:" + (string)i + ":dur");
            text += (string)(i + 1) + ": \"" + m_text + "\" (" + m_dur + "s)\n";
        }
    }
    text += "--------------------------------------\n";
    
    list msg_btns = [];
    integer i;
    for (i = gPageOffset; i < gPageOffset + 6 && i < count; ++i)
    {
        msg_btns += "Msg " + (string)(i + 1);
    }
    while (llGetListLength(msg_btns) < 6) msg_btns += " ";
    
    list buttons = [
        llList2String(msg_btns, 3), llList2String(msg_btns, 4), llList2String(msg_btns, 5),
        llList2String(msg_btns, 0), llList2String(msg_btns, 1), llList2String(msg_btns, 2),
        "Add Msg", "Clear All", " ",
        "◀ Prev", "Next ▶", "Back"
    ];
    open_dialog(text, buttons);
}

render_msg_editor()
{
    string prefix = "lsd:titler:msg:" + (string)gActiveMsgIdx + ":";
    string m_text = llLinksetDataRead(prefix + "text");
    string m_dur  = llLinksetDataRead(prefix + "dur"); if (m_dur == "") m_dur = "4.0";
    string m_font = llLinksetDataRead(prefix + "font"); if (m_font == "") m_font = "Inherited";
    
    string text = "⬡ Message Editor: Msg " + (string)(gActiveMsgIdx + 1) + " ⬡\n";
    text += "--------------------------------------\n";
    text += "Raw Text: \"" + m_text + "\"\n";
    text += "Duration: " + m_dur + "s\n";
    text += "Font: " + m_font + "\n";
    text += "--------------------------------------\n";
    text += "Edit parameters or select style:";
    
    list buttons = [
        "Presets...", "Preview", "Delete",
        "Before FX...", "During FX...", "After FX...",
        "Change Text", "Duration", "Appearance...",
        "Back", "Set Font", " "
    ];
    open_dialog(text, buttons);
}

render_presets_menu()
{
    string text = "⬡ Style Presets ⬡\n";
    text += "Apply quick style overrides to Msg " + (string)(gActiveMsgIdx + 1) + ":\n";
    text += "• Cyber: Neon green, matrix vert, hex trinkets\n";
    text += "• Princess: Pink, fade, heart trinkets\n";
    text += "• Terminal: White, typing, no trinkets\n";
    text += "• Glitch: Random colors, glitch, flicker enabled\n";
    text += "• Reset: Clears local overrides\n";
    
    list buttons = [
        "Preset: Cyber", "Preset: Princess", "Preset: Terminal",
        "Preset: Glitch", "Preset: Reset", " ",
        " ", " ", " ",
        "Back", " ", " "
    ];
    open_dialog(text, buttons);
}

refresh_menu()
{
    if (gMenuContext == "main") render_main_menu();
    else if (gMenuContext == "messages") render_messages_menu();
    else if (gMenuContext == "msg_edit") render_msg_editor();
    else if (gMenuContext == "presets") render_presets_menu();
}

default
{
    state_entry()
    {
        update_user_listener();
    }

    changed(integer change)
    {
        if (change & CHANGED_OWNER)
        {
            update_user_listener();
        }
    }

    touch_start(integer total_number)
    {
        if (llDetectedKey(0) == llGetOwner())
        {
            gMenuContext = "main";
            refresh_menu();
        }
    }

    link_message(integer sender_num, integer code, string str, key id)
    {
        // Code 189: Handoff from overrides menu script
        if (code == 189)
        {
            list parts = llParseString2List(str, ["|"], []);
            string action = llList2String(parts, 0);
            
            if (action == "HANDOFF")
            {
                string target_context = llList2String(parts, 1);
                
                // Only process if it is in our context domain
                if (!is_override_context(target_context))
                {
                    gMenuContext = target_context;
                    gActiveMsgIdx = (integer)llList2String(parts, 2);
                    gPageOffset = (integer)llList2String(parts, 3);
                    
                    refresh_menu();
                }
            }
        }
    }

    listen(integer channel, string name, key id, string message)
    {
        if (id != llGetOwner()) return;

        if (channel == gMenuUserChannel)
        {
            string msg = llToLower(llStringTrim(message, STRING_TRIM));
            if (msg == "menu" || msg == "titler")
            {
                gMenuContext = "main";
                refresh_menu();
            }
            return;
        }

        if (channel == gMenuChannel)
        {
            llSetTimerEvent(0.0);
            string cmd = llStringTrim(message, STRING_TRIM);
            
            // --- Text Box Processing ---
            if (llSubStringIndex(gMenuContext, "textbox:") == 0)
            {
                string action = llGetSubString(gMenuContext, 8, -1);
                
                if (action == "add_msg_text")
                {
                    llLinksetDataWrite("lsd:titler:temp_add_text", cmd);
                    gMenuContext = "textbox:add_msg_dur";
                    open_textbox("Enter display duration in seconds (e.g. 5.0):");
                    return;
                }
                
                if (action == "add_msg_dur")
                {
                    float dur = (float)cmd;
                    if (dur <= 0.0) dur = 4.0;
                    
                    string text = llLinksetDataRead("lsd:titler:temp_add_text");
                    llLinksetDataDelete("lsd:titler:temp_add_text");
                    
                    integer count = (integer)llLinksetDataRead("lsd:titler:msg_count");
                    string prefix = "lsd:titler:msg:" + (string)count + ":";
                    
                    llLinksetDataWrite(prefix + "text", text);
                    llLinksetDataWrite(prefix + "dur", (string)dur);
                    llLinksetDataWrite("lsd:titler:msg_count", (string)(count + 1));
                    
                    llMessageLinked(LINK_SET, 180, "RELOAD", NULL_KEY);
                    gMenuContext = "messages";
                    refresh_menu();
                    return;
                }
                
                string prefix = "lsd:titler:msg:" + (string)gActiveMsgIdx + ":";
                
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
            }

            // --- Dialog Processing ---
            if (cmd == "Close") return;
            if (cmd == "Back")
            {
                if (gMenuContext == "messages") gMenuContext = "main";
                else if (gMenuContext == "msg_edit") gMenuContext = "messages";
                else if (gMenuContext == "presets") gMenuContext = "msg_edit";
                refresh_menu();
                return;
            }

            if (gMenuContext == "main")
            {
                if (cmd == "Enable")
                {
                    llMessageLinked(LINK_SET, 181, "1", NULL_KEY);
                    render_main_menu();
                }
                else if (cmd == "Disable")
                {
                    llMessageLinked(LINK_SET, 181, "0", NULL_KEY);
                    render_main_menu();
                }
                else if (cmd == "Messages")
                {
                    gPageOffset = 0;
                    gMenuContext = "messages";
                    render_messages_menu();
                }
                else if (is_override_context(cmd) || cmd == "Appearance" || cmd == "Animation" || cmd == "Trinkets" || cmd == "Fonts" || cmd == "Roles" || cmd == "Status Tag")
                {
                    // Map generic labels to override contexts
                    string handoff_context = cmd;
                    if (cmd == "Appearance") handoff_context = "global_appearance";
                    else if (cmd == "Animation") handoff_context = "global_animation";
                    else if (cmd == "Trinkets") handoff_context = "global_trinkets";
                    else if (cmd == "Fonts") handoff_context = "fonts";
                    else if (cmd == "Roles") handoff_context = "roles";
                    else if (cmd == "Status Tag") handoff_context = "status_tag";
                    
                    // Hand off to overrides menu script
                    llMessageLinked(LINK_SET, 189, "HANDOFF|" + handoff_context + "|" + (string)gActiveMsgIdx + "|" + (string)gPageOffset, id);
                }
                return;
            }

            if (gMenuContext == "messages")
            {
                if (cmd == "Add Msg")
                {
                    integer count = (integer)llLinksetDataRead("lsd:titler:msg_count");
                    if (count >= 16)
                    {
                        llOwnerSay("Maximum limit of 16 rotation messages reached.");
                        render_messages_menu();
                        return;
                    }
                    gMenuContext = "textbox:add_msg_text";
                    open_textbox("Enter raw text string for new message (supports variables like %name%, %time%):");
                    return;
                }
                if (cmd == "Clear All")
                {
                    integer count = (integer)llLinksetDataRead("lsd:titler:msg_count");
                    integer i;
                    for (i = 0; i < count; ++i)
                    {
                        clear_message_overrides(i);
                        llLinksetDataDelete("lsd:titler:msg:" + (string)i + ":text");
                        llLinksetDataDelete("lsd:titler:msg:" + (string)i + ":dur");
                    }
                    llLinksetDataWrite("lsd:titler:msg_count", "0");
                    llMessageLinked(LINK_SET, 180, "RELOAD", NULL_KEY);
                    render_messages_menu();
                    return;
                }
                if (cmd == "◀ Prev")
                {
                    if (gPageOffset >= 6) gPageOffset -= 6;
                    render_messages_menu();
                    return;
                }
                if (cmd == "Next ▶")
                {
                    integer count = (integer)llLinksetDataRead("lsd:titler:msg_count");
                    if (gPageOffset + 6 < count) gPageOffset += 6;
                    render_messages_menu();
                    return;
                }
                if (llSubStringIndex(cmd, "Msg ") == 0)
                {
                    gActiveMsgIdx = (integer)llGetSubString(cmd, 4, -1) - 1;
                    gMenuContext = "msg_edit";
                    render_msg_editor();
                    return;
                }
            }

            if (gMenuContext == "msg_edit")
            {
                if (cmd == "Change Text")
                {
                    gMenuContext = "textbox:msg_text";
                    open_textbox("Enter new message text:");
                    return;
                }
                if (cmd == "Duration")
                {
                    gMenuContext = "textbox:msg_dur";
                    open_textbox("Enter display duration (or RANDOM):");
                    return;
                }
                if (cmd == "Presets...")
                {
                    gMenuContext = "presets";
                    render_presets_menu();
                    return;
                }
                if (cmd == "Preview")
                {
                    string text = llLinksetDataRead("lsd:titler:msg:" + (string)gActiveMsgIdx + ":text");
                    llMessageLinked(LINK_SET, 182, text, NULL_KEY);
                    render_msg_editor();
                    return;
                }
                if (cmd == "Delete")
                {
                    integer count = (integer)llLinksetDataRead("lsd:titler:msg_count");
                    clear_message_overrides(gActiveMsgIdx);
                    
                    integer i;
                    for (i = gActiveMsgIdx; i < count - 1; ++i)
                    {
                        string next_pref = "lsd:titler:msg:" + (string)(i + 1) + ":";
                        string curr_pref = "lsd:titler:msg:" + (string)i + ":";
                        llLinksetDataWrite(curr_pref + "text", llLinksetDataRead(next_pref + "text"));
                        llLinksetDataWrite(curr_pref + "dur", llLinksetDataRead(next_pref + "dur"));
                        
                        llLinksetDataWrite(curr_pref + "color", llLinksetDataRead(next_pref + "color"));
                        llLinksetDataWrite(curr_pref + "color_end", llLinksetDataRead(next_pref + "color_end"));
                        llLinksetDataWrite(curr_pref + "color_trans", llLinksetDataRead(next_pref + "color_trans"));
                        llLinksetDataWrite(curr_pref + "alpha", llLinksetDataRead(next_pref + "alpha"));
                        llLinksetDataWrite(curr_pref + "height", llLinksetDataRead(next_pref + "height"));
                        llLinksetDataWrite(curr_pref + "align", llLinksetDataRead(next_pref + "align"));
                        llLinksetDataWrite(curr_pref + "trans_in", llLinksetDataRead(next_pref + "trans_in"));
                        llLinksetDataWrite(curr_pref + "trans_out", llLinksetDataRead(next_pref + "trans_out"));
                        llLinksetDataWrite(curr_pref + "trans_speed", llLinksetDataRead(next_pref + "trans_speed"));
                        llLinksetDataWrite(curr_pref + "trinket_style", llLinksetDataRead(next_pref + "trinket_style"));
                        llLinksetDataWrite(curr_pref + "trinket_pos", llLinksetDataRead(next_pref + "trinket_pos"));
                        llLinksetDataWrite(curr_pref + "scroll_width", llLinksetDataRead(next_pref + "scroll_width"));
                        llLinksetDataWrite(curr_pref + "scroll_enabled", llLinksetDataRead(next_pref + "scroll_enabled"));
                        llLinksetDataWrite(curr_pref + "font", llLinksetDataRead(next_pref + "font"));
                        llLinksetDataWrite(curr_pref + "flicker_glitch", llLinksetDataRead(next_pref + "flicker_glitch"));
                        llLinksetDataWrite(curr_pref + "blink_cursor", llLinksetDataRead(next_pref + "blink_cursor"));
                    }
                    string last_pref = "lsd:titler:msg:" + (string)(count - 1) + ":";
                    llLinksetDataDelete(last_pref + "text");
                    llLinksetDataDelete(last_pref + "dur");
                    clear_message_overrides(count - 1);
                    llLinksetDataWrite("lsd:titler:msg_count", (string)(count - 1));
                    llMessageLinked(LINK_SET, 180, "RELOAD", NULL_KEY);
                    
                    gMenuContext = "messages";
                    render_messages_menu();
                    return;
                }
                
                // All other commands hand off to overrides menu script
                string handoff_context = cmd;
                if (cmd == "Before FX...") handoff_context = "before_fx";
                else if (cmd == "During FX...") handoff_context = "during_fx";
                else if (cmd == "After FX...") handoff_context = "after_fx";
                else if (cmd == "Appearance...") handoff_context = "appearance";
                else if (cmd == "Set Font") handoff_context = "fonts";
                
                llMessageLinked(LINK_SET, 189, "HANDOFF|" + handoff_context + "|" + (string)gActiveMsgIdx + "|" + (string)gPageOffset, id);
                return;
            }

            if (gMenuContext == "presets")
            {
                string prefix = "lsd:titler:msg:" + (string)gActiveMsgIdx + ":";
                if (cmd == "Preset: Cyber")
                {
                    clear_message_overrides(gActiveMsgIdx);
                    llLinksetDataWrite(prefix + "color", "<0.0, 1.0, 0.2>");
                    llLinksetDataWrite(prefix + "trans_in", "MATRIX_VERT");
                    llLinksetDataWrite(prefix + "trans_out", "MATRIX_VERT");
                    llLinksetDataWrite(prefix + "trinket_style", "HEX");
                    llMessageLinked(LINK_SET, 180, "RELOAD", NULL_KEY);
                    render_msg_editor();
                }
                else if (cmd == "Preset: Princess")
                {
                    clear_message_overrides(gActiveMsgIdx);
                    llLinksetDataWrite(prefix + "color", "<1.0, 0.4, 0.7>");
                    llLinksetDataWrite(prefix + "trans_in", "FADE");
                    llLinksetDataWrite(prefix + "trans_out", "FADE");
                    llLinksetDataWrite(prefix + "trinket_style", "HEART");
                    llMessageLinked(LINK_SET, 180, "RELOAD", NULL_KEY);
                    render_msg_editor();
                }
                else if (cmd == "Preset: Terminal")
                {
                    clear_message_overrides(gActiveMsgIdx);
                    llLinksetDataWrite(prefix + "color", "<1.0, 1.0, 1.0>");
                    llLinksetDataWrite(prefix + "trans_in", "TYPING");
                    llLinksetDataWrite(prefix + "trans_out", "TYPING");
                    llLinksetDataWrite(prefix + "trinket_style", "NONE");
                    llMessageLinked(LINK_SET, 180, "RELOAD", NULL_KEY);
                    render_msg_editor();
                }
                else if (cmd == "Preset: Glitch")
                {
                    clear_message_overrides(gActiveMsgIdx);
                    llLinksetDataWrite(prefix + "color", "RANDOM");
                    llLinksetDataWrite(prefix + "color_end", "RANDOM");
                    llLinksetDataWrite(prefix + "color_trans", "RANDOM");
                    llLinksetDataWrite(prefix + "trans_in", "GLITCH");
                    llLinksetDataWrite(prefix + "trans_out", "GLITCH");
                    llLinksetDataWrite("lsd:titler:flicker_glitch", "1");
                    llMessageLinked(LINK_SET, 180, "RELOAD", NULL_KEY);
                    render_msg_editor();
                }
                else if (cmd == "Preset: Reset")
                {
                    clear_message_overrides(gActiveMsgIdx);
                    llMessageLinked(LINK_SET, 180, "RELOAD", NULL_KEY);
                    render_msg_editor();
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
