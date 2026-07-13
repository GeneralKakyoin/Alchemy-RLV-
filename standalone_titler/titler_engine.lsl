// titler_engine.lsl — Visual FX & Prim Controller
// Handles floating text rendering, transition ticks, scrolling, and trinket animations.

// Link Message Codes:
// Code 180 (In): RELOAD -> Reload config parameters
// Code 181 (In): 1 (Enable) or 0 (Disable) -> Enable/disable state
// Code 182 (In): (Resolved preview text) -> Preview temporary message instantly (quiet transitions)
// Code 183 (In): 1 (Quiet) or 0 (Resume) -> Hide/resume floating text
// Code 185 (In): RENDER_START|<text> or RENDER_UPDATE|<text> -> Triggers message transitions or updates
// Code 186 (Out): NEXT_MSG -> Requests the parser to cycle to the next message

// State Constants
integer STATE_TRANS_IN  = 0;
integer STATE_IDLE      = 1;
integer STATE_TRANS_OUT = 2;
integer gState = STATE_IDLE;

// Configuration Defaults
integer titler_enabled   = 0;
integer quiet_mode       = 0;
vector  titler_color     = <1.0, 0.6, 0.8>;
vector  titler_color_end = <1.0, 0.6, 0.8>;
vector  titler_color_tr  = <1.0, 0.6, 0.8>;
float   titler_alpha     = 1.0;
float   titler_height    = 0.5;
string  anim_style       = "GLITCH";
float   trans_speed      = 0.15;
integer scroll_width     = 20;
integer scroll_enabled   = 1;
integer flicker_glitch   = 0;
string  trinket_style    = "HEX";
string  trinket_pos      = "BOTH";
string  trinket_speed    = "MED";

// Runtime variables
string  current_msg_text      = "";
float   current_msg_dur       = 4.0;
float   msg_display_start     = 0.0;

// Transition state
string  trans_src             = "";
string  trans_dst             = "";
integer trans_tick            = -1; // -1 means inactive
integer max_ticks             = 14;

// Scroll state
integer scroll_idx            = 0;
integer scroll_pause_ticks    = 0;
integer scroll_dir            = 1;
string  scroll_padded_text    = "";

// Typing & Blinking Cursor state
string  typing_cursor         = "_";
integer blink_cursor          = 1;
integer blink_tick_counter    = 0;
integer cursor_visible        = 1;

// Trinket state
integer trinket_tick_counter  = 0;
integer trinket_frame_idx     = 0;

// Constants
string CHAOS_GLYPHS = "꩜⌭⚙⟟⌀❖◇◆⬡⬢█▓▒░Ø▰▱⚡☢☣☠▄▌▐■□▲▼○●★☆ｦｧｨｩｪｫｬｭｮｯｰｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄバカエッチにゃんぽんこつあわわきゅんてへもふもふぷにぷに";
string WIPE_CURSOR  = "▓▌";

// Retrieve list of animated frames for each trinket style
list get_trinket_frames(string style)
{
    if (style == "SLEEPY")   return ["(－ω－)z", "(－ω－)~z", "(～﹃～)~z", "(∪｡∪)zzZ", "(=ω=)..zzZ"];
    if (style == "HEART")    return ["♡", "-♡-", "-`♡´-", "♥", "❣", "♡"];
    if (style == "SPARK")    return ["✦", "✦ ✧", "✧ ✦ ✧", "· ✦ ·", "✦"];
    if (style == "KITTY")    return ["=^.^=", "=^ω^=", "(=ↀωↀ=)", "=^ ^=", "=^.^="];
    if (style == "DOTPULSE") return ["·", "· ˙", "· · ˙", "˙ · ·", "˙ ·", "·"];
    if (style == "HEX")      return ["⬡", "⬡ ⬢", "⬢ ⬡ ⬢", "· ⬡ ·", "⬡"];
    if (style == "BEAR")     return ["ʕ·ᴥ·ʔ", "ʕ•ᴥ•ʔ", "ʕ˘ᴥ˘ʔ", "ʕ ᴥ ʔ", "ʕ·ᴥ·ʔ"];
    if (style == "DANCE")    return ["ヽ(・∀・)ﾉ", "(・∀・)ﾉ", "ヽ(・∀・)", "(∀・)ﾉ", "ヽ(・∀・)ﾉ"];
    if (style == "SHY")      return ["(*/ω\\*)", "(*μ_μ)", "( ◡‿◡*)", "(//▽//)", "(*^.^*)"];
    if (style == "ZAP")      return ["⚡", "⚡✺", "✺⚡✺", "⚡ ·", "· ⚡", "⚡"];
    if (style == "MUSIC")    return ["♩", "♩♪", "♪♩♫", "♫♪", "♪", "♩"];
    return [];
}

string get_random_chaos_char()
{
    integer len = llStringLength(CHAOS_GLYPHS);
    integer idx = (integer)llFrand(len);
    return llGetSubString(CHAOS_GLYPHS, idx, idx);
}

// Generate correct frame based on transition style, tick, source, and destination
string get_transition_frame(string style, string src, string dst, integer tick)
{
    integer len_src = llStringLength(src);
    integer len_dst = llStringLength(dst);
    integer max_len = len_src;
    if (len_dst > max_len) max_len = len_dst;
    if (max_len < 1) max_len = 1;
    
    if (style == "GLITCH")
    {
        string display_frame = "";
        string template = dst;
        if (template == "") template = src;
        
        integer i;
        if (tick <= 4)
        {
            float ratio = (float)tick / 4.0;
            for (i = 0; i < max_len; ++i)
            {
                string c = llGetSubString(template, i, i);
                if (c == "\n")
                {
                    display_frame += "\n";
                }
                else if (llFrand(1.0) <= ratio)
                {
                    display_frame += get_random_chaos_char();
                }
                else
                {
                    if (i < len_src) display_frame += llGetSubString(src, i, i);
                    else             display_frame += " ";
                }
            }
        }
        else if (tick <= 10)
        {
            float ratio = (float)(tick - 4) / 6.0;
            if (dst == "") // Transition Out: resolve to space padding
            {
                for (i = 0; i < len_src; ++i)
                {
                    string c = llGetSubString(src, i, i);
                    if (c == "\n") display_frame += "\n";
                    else if (llFrand(1.0) <= ratio) display_frame += " ";
                    else                            display_frame += get_random_chaos_char();
                }
            }
            else // Transition In: resolve to dst text
            {
                for (i = 0; i < len_dst; ++i)
                {
                    string c = llGetSubString(dst, i, i);
                    if (c == "\n") display_frame += "\n";
                    else if (llFrand(1.0) <= ratio) display_frame += c;
                    else                            display_frame += get_random_chaos_char();
                }
            }
        }
        else if (tick < 13)
        {
            if (dst == "") // Transition Out: fade down to sparse chaos
            {
                for (i = 0; i < len_src; ++i)
                {
                    string c = llGetSubString(src, i, i);
                    if (c == "\n") display_frame += "\n";
                    else if (llFrand(4.0) < 1.0) display_frame += get_random_chaos_char();
                    else                         display_frame += " ";
                }
            }
            else // Transition In: close to completion, 1-2 stray flickers
            {
                display_frame = dst;
                integer scramble_pos = (integer)llFrand(len_dst);
                if (len_dst > 0)
                {
                    string c = llGetSubString(display_frame, scramble_pos, scramble_pos);
                    if (c != "\n" && c != " ")
                    {
                        display_frame = llDeleteSubString(display_frame, scramble_pos, scramble_pos);
                        display_frame = llInsertString(display_frame, scramble_pos, get_random_chaos_char());
                    }
                }
            }
        }
        else
        {
            display_frame = dst;
        }
        return display_frame;
    }
    else if (style == "WIPE")
    {
        string display_frame = "";
        string template = dst;
        if (template == "") template = src;
        
        integer cursor_pos = (tick * max_len) / max_ticks;
        integer i;
        for (i = 0; i < max_len; ++i)
        {
            string c = llGetSubString(template, i, i);
            if (c == "\n")
            {
                display_frame += "\n";
            }
            else if (i < cursor_pos)
            {
                if (i < len_dst) display_frame += llGetSubString(dst, i, i);
                else             display_frame += " "; // Pad left side with space to prevent shifting
            }
            else if (i == cursor_pos)
            {
                display_frame += WIPE_CURSOR;
            }
            else
            {
                if (i < len_src) display_frame += llGetSubString(src, i, i);
                else             display_frame += " "; // Pad right side
            }
        }
        return display_frame;
    }
    else if (style == "FADE")
    {
        if (tick <= 4)
        {
            integer chars_to_show = len_src - tick;
            if (chars_to_show < 1) chars_to_show = 1;
            return llGetSubString(src, 0, chars_to_show - 1) + "·";
        }
        else if (tick <= 8)
        {
            return "· · ·";
        }
        else if (tick < 13)
        {
            integer chars_to_show = ((tick - 8) * len_dst) / 5;
            if (chars_to_show < 0) chars_to_show = 0;
            if (chars_to_show > 0) return "·" + llGetSubString(dst, 0, chars_to_show - 1);
            return "·";
        }
        return dst;
    }
    else if (style == "TYPING")
    {
        if (dst == "") // Transition Out
        {
            integer chars_to_show = len_src - ((tick * len_src) / max_ticks);
            if (chars_to_show <= 0) return typing_cursor;
            return llGetSubString(src, 0, chars_to_show - 1) + typing_cursor;
        }
        else // Transition In
        {
            integer chars_to_show = (tick * len_dst) / max_ticks;
            if (chars_to_show <= 0) return typing_cursor;
            if (chars_to_show >= len_dst) return dst;
            return llGetSubString(dst, 0, chars_to_show - 1) + typing_cursor;
        }
    }
    else if (style == "MATRIX_HORIZ")
    {
        string display_frame = "";
        integer i;
        if (dst == "")
        {
            for (i = 0; i < len_src; ++i)
            {
                string char = llGetSubString(src, i, i);
                if (char == " " || char == "\n") display_frame += char;
                else
                {
                    if (llFrand(max_ticks) > tick) display_frame += get_random_chaos_char();
                    else                    display_frame += " ";
                }
            }
        }
        else
        {
            for (i = 0; i < len_dst; ++i)
            {
                string char = llGetSubString(dst, i, i);
                if (char == " " || char == "\n") display_frame += char;
                else
                {
                    if (llFrand(max_ticks) <= tick) display_frame += char;
                    else                     display_frame += get_random_chaos_char();
                }
            }
        }
        return display_frame;
    }
    else if (style == "MATRIX_VERT")
    {
        if (dst == "")
        {
            integer num_newlines = (tick / 2);
            string pad = "";
            integer k;
            for (k = 0; k < num_newlines; ++k) pad += "\n";
            string partial = "";
            if (len_src > 0)
            {
                integer slice_len = len_src - tick;
                if (slice_len > 0) partial = llGetSubString(src, 0, slice_len - 1);
            }
            return pad + partial + " " + get_random_chaos_char();
        }
        else
        {
            if (tick <= 8)
            {
                integer num_newlines = 6 - (tick / 2);
                string pad = "";
                integer k;
                for (k = 0; k < num_newlines; ++k) pad += "\n";
                return pad + get_random_chaos_char() + " " + get_random_chaos_char() + " " + get_random_chaos_char();
            }
            else
            {
                string display_frame = dst;
                integer scramble_pos = (integer)llFrand(len_dst);
                if (len_dst > 0)
                {
                    display_frame = llDeleteSubString(display_frame, scramble_pos, scramble_pos);
                    display_frame = llInsertString(display_frame, scramble_pos, get_random_chaos_char());
                }
                return display_frame;
            }
        }
    }
    else if (style == "SLIDE")
    {
        integer max_spaces = 20;
        if (dst == "")
        {
            integer spaces = (tick * max_spaces) / max_ticks;
            string pad = "";
            integer k;
            for (k = 0; k < spaces; ++k) pad += " ";
            return pad + src;
        }
        else
        {
            integer spaces = max_spaces - ((tick * max_spaces) / max_ticks);
            if (spaces < 0) spaces = 0;
            string pad = "";
            integer k;
            for (k = 0; k < spaces; ++k) pad += " ";
            return pad + dst;
        }
    }
    return dst;
}

// Loads rendering parameters from the active blocks in LSD
load_active_params()
{
    titler_enabled = (integer)llLinksetDataRead("lsd:titler:enabled");
    
    string color_str = llLinksetDataRead("lsd:titler:active:color");
    if (color_str != "") titler_color = (vector)color_str;
    else                 titler_color = <1.0, 0.6, 0.8>;
    
    string color_e = llLinksetDataRead("lsd:titler:active:color_end");
    if (color_e != "")   titler_color_end = (vector)color_e;
    else                 titler_color_end = titler_color;
    
    string color_tr = llLinksetDataRead("lsd:titler:active:color_trans");
    if (color_tr != "")  titler_color_tr = (vector)color_tr;
    else                 titler_color_tr = titler_color;
    
    string alpha_str = llLinksetDataRead("lsd:titler:active:alpha");
    if (alpha_str != "") titler_alpha = (float)alpha_str;
    else                 titler_alpha = 1.0;
    
    string height_str = llLinksetDataRead("lsd:titler:active:height");
    if (height_str != "") titler_height = (float)height_str;
    else                  titler_height = 0.5;
    
    string style_str = llLinksetDataRead("lsd:titler:active:trans_in");
    if (style_str != "") anim_style = style_str;
    else                 anim_style = "GLITCH";
    
    string spd_str = llLinksetDataRead("lsd:titler:active:trans_speed");
    if (spd_str != "")   trans_speed = (float)spd_str;
    else                 trans_speed = 0.15;
    if (trans_speed < 0.05) trans_speed = 0.05;
    
    string sw_str = llLinksetDataRead("lsd:titler:active:scroll_width");
    if (sw_str != "")    scroll_width = (integer)sw_str;
    else                 scroll_width = 20;
    
    string se_str = llLinksetDataRead("lsd:titler:active:scroll_enabled");
    if (se_str != "")    scroll_enabled = (integer)se_str;
    else                 scroll_enabled = 1;
    
    string fg_str = llLinksetDataRead("lsd:titler:flicker_glitch");
    if (fg_str != "")    flicker_glitch = (integer)fg_str;
    else                 flicker_glitch = 0;
    
    string tstyle_str = llLinksetDataRead("lsd:titler:active:trinket_style");
    if (tstyle_str != "") trinket_style = tstyle_str;
    else                  trinket_style = "HEX";
    
    string tpos_str = llLinksetDataRead("lsd:titler:active:trinket_pos");
    if (tpos_str != "")  trinket_pos = tpos_str;
    else                 trinket_pos = "BOTH";
    
    string tspd_str = llLinksetDataRead("lsd:titler:trinket_speed");
    if (tspd_str != "")  trinket_speed = tspd_str;
    else                 trinket_speed = "MED";
    
    string dur_str = llLinksetDataRead("lsd:titler:active:dur");
    if (dur_str != "")   current_msg_dur = (float)dur_str;
    else                 current_msg_dur = 4.0;
    
    string cursor_str = llLinksetDataRead("lsd:titler:active:typing_cursor");
    if (cursor_str != "") typing_cursor = cursor_str;
    else                 typing_cursor = "_";
    if (typing_cursor == "none") typing_cursor = "";
    
    string blink_str = llLinksetDataRead("lsd:titler:active:blink_cursor");
    if (blink_str != "") blink_cursor = (integer)blink_str;
    else                 blink_cursor = 1;
    
    // Apply local vertical height offset to the attachment prim only if attached to avatar
    if (llGetAttached() != 0)
    {
        llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_POS_LOCAL, <0.0, 0.0, titler_height>]);
    }
}

// Configures and scales the timer loop dynamically to conserve SIM resources
configure_idle_timer()
{
    integer active_scroll = (scroll_padded_text != "");
    integer active_trinkets = (trinket_style != "NONE" && trinket_style != "");
    
    if (active_scroll || active_trinkets || flicker_glitch == 1)
    {
        // Keep fast interval ticking for real-time animations
        llSetTimerEvent(0.15);
    }
    else if (blink_cursor == 1 && typing_cursor != "")
    {
        // Tick at 0.5s for blinking cursor
        float elapsed = llGetTime() - msg_display_start;
        float remaining = current_msg_dur - elapsed;
        float interval = 0.5;
        if (remaining < interval) interval = remaining;
        if (interval <= 0.05) interval = 0.05;
        llSetTimerEvent(interval);
    }
    else
    {
        // Scale timer to message duration remaining
        float elapsed = llGetTime() - msg_display_start;
        float remaining = current_msg_dur - elapsed;
        if (remaining <= 0.05) remaining = 0.05;
        llSetTimerEvent(remaining);
    }
}

// Initializes scrolling metrics for wide strings
setup_scrolling()
{
    scroll_idx = 0;
    scroll_dir = 1;
    if (scroll_enabled == 1 && llStringLength(current_msg_text) > scroll_width)
    {
        scroll_padded_text = current_msg_text;
        scroll_pause_ticks = 13; // Pause for ~2.0 seconds at start
    }
    else
    {
        scroll_padded_text = "";
        scroll_pause_ticks = 0;
    }
}

string get_cursor_space(string cursor)
{
    if (cursor == "_") return " "; // Figure space (U+2007)
    if (cursor == "|") return " "; // Thin space (U+2009)
    if (cursor == "█") return " "; // Em space (U+2003)
    if (cursor == "▊") return " "; // Figure space (U+2007)
    return " ";
}

// Appends active trinket frames and random flicker noise to render output
render_text(string message)
{
    if (quiet_mode == 1 || titler_enabled == 0)
    {
        llSetText("", ZERO_VECTOR, 0.0);
        return;
    }
    
    string final_text = message;
    
    // Append Blinking Cursor if active, in STATE_IDLE, and visible/hidden with matching space
    if (trans_tick == -1 && scroll_padded_text == "" && blink_cursor == 1 && typing_cursor != "")
    {
        if (cursor_visible == 1)
        {
            final_text += typing_cursor;
        }
        else
        {
            final_text += get_cursor_space(typing_cursor);
        }
    }
    
    // Process occasional flicker glitch
    if (flicker_glitch == 1 && trans_tick == -1)
    {
        float roll = llFrand(1.0);
        
        // 1. Deep Static Surge (3% chance): Turn entire text to code rain
        if (roll < 0.03)
        {
            integer len = llStringLength(final_text);
            string static_text = "";
            integer j;
            for (j = 0; j < len; ++j)
            {
                string c = llGetSubString(final_text, j, j);
                if (c == "\n") static_text += "\n";
                else           static_text += get_random_chaos_char();
            }
            final_text = static_text;
        }
        // 2. Micro-corrupt (17% chance): Corrupt 1 to 3 random characters
        else if (roll < 0.20)
        {
            integer len = llStringLength(final_text);
            if (len > 0)
            {
                integer glitch_count = 1 + (integer)llFrand(3.0);
                integer gc;
                for (gc = 0; gc < glitch_count; ++gc)
                {
                    integer pos1 = (integer)llFrand(len);
                    string char1 = llGetSubString(final_text, pos1, pos1);
                    if (char1 != " " && char1 != "\n" && char1 != typing_cursor)
                    {
                        final_text = llDeleteSubString(final_text, pos1, pos1);
                        final_text = llInsertString(final_text, pos1, get_random_chaos_char());
                    }
                }
            }
        }
    }
    
    list frames = get_trinket_frames(trinket_style);
    integer frame_count = llGetListLength(frames);
    
    if (frame_count > 0 && trinket_style != "NONE")
    {
        if (trinket_frame_idx >= frame_count) trinket_frame_idx = 0;
        string trinket = llList2String(frames, trinket_frame_idx);
        
        if (trinket_pos == "PREFIX")
            final_text = trinket + " " + final_text;
        else if (trinket_pos == "SUFFIX")
            final_text = final_text + " " + trinket;
        else if (trinket_pos == "BOTH")
            final_text = trinket + " " + final_text + " " + trinket;
    }
    
    // Choose highlight trans color during active transition or default color
    vector col = titler_color;
    if (trans_tick != -1) col = titler_color_tr;
    
    llSetText(final_text, col, titler_alpha);
}

// Updates trinket frames index on separate sub-timers
update_trinkets()
{
    if (trinket_style == "NONE" || trinket_style == "") return;
    
    trinket_tick_counter++;
    integer threshold = 4; // MED
    if (trinket_speed == "SLOW") threshold = 8;
    if (trinket_speed == "FAST") threshold = 2;
    
    if (trinket_tick_counter >= threshold)
    {
        trinket_tick_counter = 0;
        list frames = get_trinket_frames(trinket_style);
        integer frame_count = llGetListLength(frames);
        if (frame_count > 0)
        {
            trinket_frame_idx = (trinket_frame_idx + 1) % frame_count;
            if (trans_tick == -1 && scroll_padded_text == "")
            {
                render_text(current_msg_text);
            }
        }
    }
}

// Triggers exit transition before requesting parser for next rotation index
start_exit_transition()
{
    string out_style = llLinksetDataRead("lsd:titler:active:trans_out");
    if (out_style == "") out_style = anim_style;
    anim_style = out_style;
    
    if (out_style == "INSTANT")
    {
        gState = STATE_IDLE;
        trans_tick = -1;
        llMessageLinked(LINK_SET, 186, "NEXT_MSG", NULL_KEY);
    }
    else
    {
        gState = STATE_TRANS_OUT;
        trans_src = current_msg_text;
        trans_dst = "";
        trans_tick = 0;
        
        max_ticks = 14;
        if (out_style == "TYPING" || out_style == "WIPE")
        {
            max_ticks = llStringLength(trans_src);
            if (max_ticks < 5) max_ticks = 5;
        }
        
        float speed = trans_speed;
        if (max_ticks > 14)
        {
            speed = (14.0 * trans_speed) / (float)max_ticks;
            if (speed < 0.05) speed = 0.05;
        }
        llSetTimerEvent(speed);
    }
}

// Decides whether to exit transition to blank or transition directly during rotation
trigger_next_rotation_step()
{
    string msg_idx_str = llLinksetDataRead("lsd:titler:active_msg_idx");
    string out_override = "";
    if (msg_idx_str != "")
    {
        out_override = llLinksetDataRead("lsd:titler:msg:" + msg_idx_str + ":trans_out");
    }
    
    if (out_override != "" && out_override != "INSTANT")
    {
        start_exit_transition();
    }
    else
    {
        // Bypass transition out: request next message directly for seamless rotation!
        llMessageLinked(LINK_SET, 186, "NEXT_MSG", NULL_KEY);
    }
}


default
{
    state_entry()
    {
        llSetMemoryLimit(65536);
        load_active_params();
        
        if (titler_enabled == 1 && quiet_mode == 0)
        {
            llMessageLinked(LINK_SET, 186, "NEXT_MSG", NULL_KEY);
        }
        else
        {
            llSetText("", ZERO_VECTOR, 0.0);
            llSetTimerEvent(0.0);
        }
    }

    link_message(integer sender_num, integer code, string str, key id)
    {
        // Code 180: RELOAD preferences
        if (code == 180)
        {
            load_active_params();
            if (titler_enabled == 1 && quiet_mode == 0)
            {
                if (trans_tick == -1)
                {
                    setup_scrolling();
                    configure_idle_timer();
                    render_text(current_msg_text);
                }
            }
            else
            {
                llSetText("", ZERO_VECTOR, 0.0);
                llSetTimerEvent(0.0);
            }
            return;
        }

        // Code 181: Enable/Disable Quick Toggle
        if (code == 181)
        {
            integer enabled_state = (integer)str;
            llLinksetDataWrite("lsd:titler:enabled", (string)enabled_state);
            load_active_params();
            
            if (enabled_state == 1 && quiet_mode == 0)
            {
                llMessageLinked(LINK_SET, 186, "NEXT_MSG", NULL_KEY);
            }
            else
            {
                llSetText("", ZERO_VECTOR, 0.0);
                llSetTimerEvent(0.0);
            }
            return;
        }

        // Code 182: Preview resolved text (instantly override, clear transitions)
        if (code == 182)
        {
            trans_tick = -1;
            scroll_padded_text = "";
            gState = STATE_IDLE;
            current_msg_text = str;
            msg_display_start = llGetTime();
            current_msg_dur = 6.0; // Show preview for 6.0s
            
            load_active_params();
            render_text(str);
            configure_idle_timer();
            return;
        }

        // Code 183: Quiet mode toggle
        if (code == 183)
        {
            quiet_mode = (integer)str;
            if (quiet_mode == 1)
            {
                llSetText("", ZERO_VECTOR, 0.0);
                llSetTimerEvent(0.0);
            }
            else
            {
                load_active_params();
                if (titler_enabled == 1)
                {
                    llMessageLinked(LINK_SET, 186, "NEXT_MSG", NULL_KEY);
                }
            }
            return;
        }

        // Code 185: RENDER_START (new transition) or RENDER_UPDATE (in-place update)
        if (code == 185)
        {
            integer pipe = llSubStringIndex(str, "|");
            if (pipe != -1)
            {
                string cmd = llGetSubString(str, 0, pipe - 1);
                string payload = llGetSubString(str, pipe + 1, -1);
                
                if (cmd == "RENDER_START")
                {
                    load_active_params();
                    trans_src = current_msg_text;
                    trans_dst = payload;
                    
                    string in_style = llLinksetDataRead("lsd:titler:active:trans_in");
                    if (in_style == "") in_style = anim_style;
                    
                    if (in_style == "INSTANT")
                    {
                        gState = STATE_IDLE;
                        trans_tick = -1;
                        current_msg_text = trans_dst;
                        msg_display_start = llGetTime();
                        setup_scrolling();
                        render_text(current_msg_text);
                        configure_idle_timer();
                    }
                    else
                    {
                        gState = STATE_TRANS_IN;
                        trans_tick = 0;
                        
                        max_ticks = 14;
                        if (in_style == "TYPING" || in_style == "WIPE")
                        {
                            max_ticks = llStringLength(trans_dst);
                            if (max_ticks < 5) max_ticks = 5;
                        }
                        
                        float speed = trans_speed;
                        if (max_ticks > 14)
                        {
                            speed = (14.0 * trans_speed) / (float)max_ticks;
                            if (speed < 0.05) speed = 0.05;
                        }
                        llSetTimerEvent(speed);
                    }
                }
                else if (cmd == "RENDER_UPDATE")
                {
                    current_msg_text = payload;
                    if (gState == STATE_IDLE && trans_tick == -1)
                    {
                        setup_scrolling();
                        render_text(current_msg_text);
                        configure_idle_timer();
                    }
                }
            }
            return;
        }
    }

    timer()
    {
        // 1. Process active transition loop
        if (trans_tick != -1)
        {
            trans_tick++;
            
            if (gState == STATE_TRANS_IN)
            {
                string frame = get_transition_frame(anim_style, trans_src, trans_dst, trans_tick);
                render_text(frame);
                
                if (trans_tick >= max_ticks)
                {
                    gState = STATE_IDLE;
                    trans_tick = -1;
                    current_msg_text = trans_dst;
                    msg_display_start = llGetTime();
                    cursor_visible = 1;
                    blink_tick_counter = 0;
                    setup_scrolling();
                    render_text(current_msg_text);
                    configure_idle_timer();
                }
            }
            else if (gState == STATE_TRANS_OUT)
            {
                string frame = get_transition_frame(anim_style, trans_src, trans_dst, trans_tick);
                render_text(frame);
                
                if (trans_tick >= max_ticks)
                {
                    gState = STATE_IDLE;
                    trans_tick = -1;
                    current_msg_text = "";
                    llMessageLinked(LINK_SET, 186, "NEXT_MSG", NULL_KEY);
                }
            }
        }
        // 2. Process scrolling ticks
        else if (scroll_padded_text != "")
        {
            if (scroll_pause_ticks > 0)
            {
                scroll_pause_ticks--;
            }
            else
            {
                scroll_idx += scroll_dir;
                integer max_idx = llStringLength(scroll_padded_text) - scroll_width;
                
                if (scroll_dir == 1)
                {
                    if (scroll_idx >= max_idx)
                    {
                        scroll_idx = max_idx;
                        scroll_dir = -1;
                        scroll_pause_ticks = 13; // Pause for ~2.0 seconds at end
                    }
                }
                else
                {
                    if (scroll_idx <= 0)
                    {
                        scroll_idx = 0;
                        scroll_dir = 1;
                        scroll_pause_ticks = 13; // Pause for ~2.0 seconds at start
                    }
                }
            }
            
            string display = llGetSubString(scroll_padded_text, scroll_idx, scroll_idx + scroll_width - 1);
            render_text(display);
            
            if (llGetTime() - msg_display_start >= current_msg_dur)
            {
                trigger_next_rotation_step();
            }
        }
        // 3. Static/flicker display ticks
        else
        {
            if (llGetTime() - msg_display_start >= current_msg_dur)
            {
                trigger_next_rotation_step();
            }
            else
            {
                integer needs_render = 0;
                
                if (blink_cursor == 1 && typing_cursor != "")
                {
                    integer is_fast_timer = (flicker_glitch == 1 || (trinket_style != "NONE" && trinket_style != ""));
                    if (is_fast_timer)
                    {
                        blink_tick_counter++;
                        if (blink_tick_counter >= 4)
                        {
                            blink_tick_counter = 0;
                            cursor_visible = 1 - cursor_visible;
                            needs_render = 1;
                        }
                    }
                    else
                    {
                        cursor_visible = 1 - cursor_visible;
                        needs_render = 1;
                    }
                }
                
                if (needs_render || flicker_glitch == 1)
                {
                    render_text(current_msg_text);
                }
            }
        }
        
        // 4. Always update trinket frame sub-timer
        update_trinkets();
    }
}
