// titler_parser.lsl — Tag & Translation Resolver
// Resolves variables, custom roles, status progress bars, font mappings, and alignment padding.

// Link Message Codes:
// Code 180 (In): RELOAD -> Reload configuration and listener
// Code 182 (In): PREVIEW (Raw text) -> Parse preview and send resolved text to engine as Code 182
// Code 184 (In): Float percentage string -> Update Status Tag value and re-render if active
// Code 185 (Out): RENDER_START|<resolved_text> or RENDER_UPDATE|<resolved_text> -> Send text to engine
// Code 186 (In): NEXT_MSG -> Select and resolve next message in rotation
// Code 188 (In): SET_ROLE|roleName|val -> Update role name in LSD and re-render if active

integer gListenHandle = 0;
integer gActiveMsgIdx = -1;
string  gCurrentRawText = "";

// Helper: safe string replacement
string replace_string(string src, string target, string replacement)
{
    integer len = llStringLength(target);
    if (len == 0) return src;
    
    integer idx = llSubStringIndex(src, target);
    while (idx != -1)
    {
        src = llDeleteSubString(src, idx, idx + len - 1);
        src = llInsertString(src, idx, replacement);
        idx = llSubStringIndex(src, target);
    }
    return src;
}

// Helper: resolves custom dynamic roles (%role:roleName%)
string resolve_roles(string src)
{
    integer idx = llSubStringIndex(src, "%role:");
    while (idx != -1)
    {
        integer end_idx = llSubStringIndex(llGetSubString(src, idx + 6, -1), "%");
        if (end_idx != -1)
        {
            string role_key = llGetSubString(src, idx + 6, idx + 6 + end_idx - 1);
            string role_val = llLinksetDataRead("lsd:titler:role:" + role_key);
            
            src = llDeleteSubString(src, idx, idx + 6 + end_idx);
            src = llInsertString(src, idx, role_val);
            
            idx = llSubStringIndex(src, "%role:");
        }
        else
        {
            idx = -1;
        }
    }
    return src;
}

// Helper: formats SL Wallclock time as HH:MM:SS
string format_time()
{
    integer wc = (integer)llGetWallclock();
    integer hours = (wc / 3600) % 24;
    integer mins = (wc / 60) % 60;
    integer secs = wc % 60;
    
    string h = (string)hours; if (hours < 10) h = "0" + h;
    string m = (string)mins;  if (mins < 10)  m = "0" + m;
    string s = (string)secs;  if (secs < 10)  s = "0" + s;
    
    return h + ":" + m + ":" + s;
}

// Helper: constructs status bar with configurable length and style
string generate_progress_bar(float val, string style, integer len)
{
    integer filled = llRound((val / 100.0) * len);
    if (filled < 0) filled = 0;
    if (filled > len) filled = len;
    
    string fill_char = "█";
    string empty_char = "░";
    if (style == "HEART")
    {
        fill_char = "♥";
        empty_char = "♡";
    }
    else if (style == "SPARK")
    {
        fill_char = "✦";
        empty_char = "✧";
    }
    
    string bar = "";
    integer i;
    for (i = 0; i < len; ++i)
    {
        if (i < filled) bar += fill_char;
        else            bar += empty_char;
    }
    return bar;
}

// Helper: translates characters using active font map (foreign font immunity)
string translate_font(string src, string font_name)
{
    if (font_name == "" || font_name == "DEFAULT") return src;
    
    string source_chars = llLinksetDataRead("lsd:titler:font:" + font_name + ":source");
    string target_chars = llLinksetDataRead("lsd:titler:font:" + font_name + ":target");
    
    if (source_chars == "" || target_chars == "") return src;
    
    string result = "";
    integer len = llStringLength(src);
    integer i;
    for (i = 0; i < len; ++i)
    {
        string char = llGetSubString(src, i, i);
        integer idx = llSubStringIndex(source_chars, char);
        if (idx != -1)
        {
            char = llGetSubString(target_chars, idx, idx);
        }
        result += char;
    }
    return result;
}

// Helper: counts bytes accurately using Base64
integer get_byte_count(string str)
{
    string b64 = llStringToBase64(str);
    integer b64_len = llStringLength(b64);
    
    while (b64_len > 0 && llGetSubString(b64, -1, -1) == "=")
    {
        b64 = llDeleteSubString(b64, -1, -1);
        b64_len--;
    }
    
    return (b64_len * 3) / 4;
}

// Helper: pads lines for LEFT/RIGHT alignment. Checks byte limits.
string pad_alignment(string text, string align)
{
    if (align != "LEFT" && align != "RIGHT") return text;
    
    list lines = llParseStringKeepNulls(text, ["\n"], []);
    integer num_lines = llGetListLength(lines);
    if (num_lines <= 1) return text;
    
    if (num_lines > 6)
    {
        lines = llList2List(lines, 0, 5);
        num_lines = 6;
    }
    
    // Longest line length
    integer max_len = 0;
    integer i;
    for (i = 0; i < num_lines; ++i)
    {
        integer len = llStringLength(llList2String(lines, i));
        if (len > max_len) max_len = len;
    }
    
    list padded_lines = [];
    for (i = 0; i < num_lines; ++i)
    {
        string line = llList2String(lines, i);
        integer len = llStringLength(line);
        integer diff = max_len - len;
        if (diff > 0)
        {
            string pad = "";
            integer j;
            for (j = 0; j < diff; ++j) pad += " ";
            
            if (align == "LEFT")  line = line + pad;
            if (align == "RIGHT") line = pad + line;
        }
        padded_lines += line;
    }
    
    string padded_text = llDumpList2String(padded_lines, "\n");
    
    if (get_byte_count(padded_text) > 254)
    {
        // Strip padding and fall back to center if byte count exceeds SL limit
        return llDumpList2String(llList2List(lines, 0, 5), "\n");
    }
    
    return padded_text;
}

// Helper: resolves random option generators
string resolve_param(string local_override, string global_default, string type)
{
    string val = local_override;
    if (val == "") val = global_default;
    
    if (val == "RANDOM")
    {
        if (type == "COLOR")
        {
            return (string)<llFrand(1.0), llFrand(1.0), llFrand(1.0)>;
        }
        else if (type == "FLOAT_ALPHA")
        {
            return (string)(0.2 + llFrand(0.8));
        }
        else if (type == "FLOAT_HEIGHT")
        {
            return (string)(-1.5 + llFrand(3.0));
        }
        else if (type == "ALIGN")
        {
            list aligns = ["LEFT", "RIGHT", "CENTER"];
            return llList2String(aligns, (integer)llFrand(3));
        }
        else if (type == "TRANSITION")
        {
            list trans = ["GLITCH", "WIPE", "FADE", "TYPING", "MATRIX_VERT", "MATRIX_HORIZ", "SLIDE", "INSTANT"];
            return llList2String(trans, (integer)llFrand(8));
        }
        else if (type == "SPEED")
        {
            return (string)(0.05 + llFrand(0.20));
        }
        else if (type == "TRINKET_STYLE")
        {
            list styles = ["HEX", "HEART", "SPARK", "KITTY", "SLEEPY", "DOTPULSE", "BEAR", "DANCE", "SHY", "ZAP", "MUSIC"];
            return llList2String(styles, (integer)llFrand(11));
        }
        else if (type == "DUR")
        {
            return (string)(3.0 + llFrand(7.0));
        }
    }
    return val;
}

// Writes resolved override variables to active block in LSD
resolve_overrides(integer idx)
{
    string prefix = "lsd:titler:msg:" + (string)idx + ":";
    
    string l_dur            = llLinksetDataRead(prefix + "dur");
    string l_color          = llLinksetDataRead(prefix + "color");
    string l_color_end      = llLinksetDataRead(prefix + "color_end");
    string l_color_trans    = llLinksetDataRead(prefix + "color_trans");
    string l_alpha          = llLinksetDataRead(prefix + "alpha");
    string l_height         = llLinksetDataRead(prefix + "height");
    string l_align          = llLinksetDataRead(prefix + "align");
    string l_trans_in       = llLinksetDataRead(prefix + "trans_in");
    string l_trans_out      = llLinksetDataRead(prefix + "trans_out");
    string l_trans_speed    = llLinksetDataRead(prefix + "trans_speed");
    string l_trinket_style  = llLinksetDataRead(prefix + "trinket_style");
    string l_trinket_pos    = llLinksetDataRead(prefix + "trinket_pos");
    string l_scroll_width   = llLinksetDataRead(prefix + "scroll_width");
    string l_scroll_enabled = llLinksetDataRead(prefix + "scroll_enabled");
    
    // Global defaults (ultimate fallbacks)
    string g_color          = llLinksetDataRead("lsd:titler:color");         if (g_color == "") g_color = "<1.0, 0.6, 0.8>";
    string g_alpha          = llLinksetDataRead("lsd:titler:alpha");         if (g_alpha == "") g_alpha = "1.0";
    string g_height         = llLinksetDataRead("lsd:titler:height");        if (g_height == "") g_height = "0.5";
    string g_anim_style     = llLinksetDataRead("lsd:titler:anim_style");    if (g_anim_style == "") g_anim_style = "GLITCH";
    string g_trans_speed    = llLinksetDataRead("lsd:titler:trans_speed");   if (g_trans_speed == "") g_trans_speed = "0.15";
    string g_trinket_style  = llLinksetDataRead("lsd:titler:trinket_style"); if (g_trinket_style == "") g_trinket_style = "HEX";
    string g_trinket_pos    = llLinksetDataRead("lsd:titler:trinket_pos");   if (g_trinket_pos == "") g_trinket_pos = "BOTH";
    string g_scroll_width   = llLinksetDataRead("lsd:titler:scroll_width");  if (g_scroll_width == "") g_scroll_width = "20";
    string g_scroll_enabled = llLinksetDataRead("lsd:titler:scroll_enabled"); if (g_scroll_enabled == "") g_scroll_enabled = "1";
    string g_flicker        = llLinksetDataRead("lsd:titler:flicker_glitch"); if (g_flicker == "") g_flicker = "0";
    string g_font           = llLinksetDataRead("lsd:titler:active_font");    if (g_font == "") g_font = "DEFAULT";
    string g_blink          = llLinksetDataRead("lsd:titler:blink_cursor");   if (g_blink == "") g_blink = "1";
    
    // Cascading active defaults from previous rotating message
    string act_color = llLinksetDataRead("lsd:titler:rotate:active:color"); if (act_color == "") act_color = g_color;
    string act_color_end = llLinksetDataRead("lsd:titler:rotate:active:color_end"); if (act_color_end == "") act_color_end = act_color;
    string act_color_trans = llLinksetDataRead("lsd:titler:rotate:active:color_trans"); if (act_color_trans == "") act_color_trans = act_color;
    string act_alpha = llLinksetDataRead("lsd:titler:rotate:active:alpha"); if (act_alpha == "") act_alpha = g_alpha;
    string act_height = llLinksetDataRead("lsd:titler:rotate:active:height"); if (act_height == "") act_height = g_height;
    string act_align = llLinksetDataRead("lsd:titler:rotate:active:align"); if (act_align == "") act_align = "CENTER";
    string act_trans_in = llLinksetDataRead("lsd:titler:rotate:active:trans_in"); if (act_trans_in == "") act_trans_in = g_anim_style;
    string act_trans_out = llLinksetDataRead("lsd:titler:rotate:active:trans_out"); if (act_trans_out == "") act_trans_out = g_anim_style;
    string act_trans_speed = llLinksetDataRead("lsd:titler:rotate:active:trans_speed"); if (act_trans_speed == "") act_trans_speed = g_trans_speed;
    string act_trinket_style = llLinksetDataRead("lsd:titler:rotate:active:trinket_style"); if (act_trinket_style == "") act_trinket_style = g_trinket_style;
    string act_trinket_pos = llLinksetDataRead("lsd:titler:rotate:active:trinket_pos"); if (act_trinket_pos == "") act_trinket_pos = g_trinket_pos;
    string act_scroll_width = llLinksetDataRead("lsd:titler:rotate:active:scroll_width"); if (act_scroll_width == "") act_scroll_width = g_scroll_width;
    string act_scroll_enabled = llLinksetDataRead("lsd:titler:rotate:active:scroll_enabled"); if (act_scroll_enabled == "") act_scroll_enabled = g_scroll_enabled;
    string act_flicker = llLinksetDataRead("lsd:titler:rotate:active:flicker_glitch"); if (act_flicker == "") act_flicker = g_flicker;
    string act_font = llLinksetDataRead("lsd:titler:rotate:active:font"); if (act_font == "") act_font = g_font;
    string act_blink = llLinksetDataRead("lsd:titler:rotate:active:blink_cursor"); if (act_blink == "") act_blink = g_blink;

    // Resolve overrides
    string res_dur          = resolve_param(l_dur, "4.0", "DUR");
    string res_color        = resolve_param(l_color, act_color, "COLOR");
    string res_color_end    = resolve_param(l_color_end, act_color_end, "COLOR");
    string res_color_trans  = resolve_param(l_color_trans, act_color_trans, "COLOR");
    string res_alpha        = resolve_param(l_alpha, act_alpha, "FLOAT_ALPHA");
    string res_height       = resolve_param(l_height, act_height, "FLOAT_HEIGHT");
    string res_align        = resolve_param(l_align, act_align, "ALIGN");
    string res_trans_in     = resolve_param(l_trans_in, act_trans_in, "TRANSITION");
    string res_trans_out    = resolve_param(l_trans_out, act_trans_out, "TRANSITION");
    string res_trans_speed  = resolve_param(l_trans_speed, act_trans_speed, "SPEED");
    string res_trinket_style = resolve_param(l_trinket_style, act_trinket_style, "TRINKET_STYLE");
    
    string res_trinket_pos   = l_trinket_pos;   if (res_trinket_pos == "") res_trinket_pos = act_trinket_pos;
    string res_scroll_width  = l_scroll_width;  if (res_scroll_width == "") res_scroll_width = act_scroll_width;
    string res_scroll_enabled = l_scroll_enabled; if (res_scroll_enabled == "") res_scroll_enabled = act_scroll_enabled;
    
    string l_flicker = llLinksetDataRead("lsd:titler:msg:" + (string)idx + ":flicker_glitch");
    string res_flicker = l_flicker;
    if (res_flicker == "" || res_flicker == "default") res_flicker = act_flicker;
    
    string l_font = llLinksetDataRead("lsd:titler:msg:" + (string)idx + ":font");
    string res_font = l_font;
    if (res_font == "" || res_font == "default") res_font = act_font;
    
    string l_blink = llLinksetDataRead("lsd:titler:msg:" + (string)idx + ":blink_cursor");
    string res_blink = l_blink;
    if (res_blink == "" || res_blink == "default") res_blink = act_blink;
    
    // Save to active block (for engine)
    llLinksetDataWrite("lsd:titler:active:color", res_color);
    llLinksetDataWrite("lsd:titler:active:color_end", res_color_end);
    llLinksetDataWrite("lsd:titler:active:color_trans", res_color_trans);
    llLinksetDataWrite("lsd:titler:active:alpha", res_alpha);
    llLinksetDataWrite("lsd:titler:active:height", res_height);
    llLinksetDataWrite("lsd:titler:active:align", res_align);
    llLinksetDataWrite("lsd:titler:active:trans_in", res_trans_in);
    llLinksetDataWrite("lsd:titler:active:trans_out", res_trans_out);
    llLinksetDataWrite("lsd:titler:active:trans_speed", res_trans_speed);
    llLinksetDataWrite("lsd:titler:active:trinket_style", res_trinket_style);
    llLinksetDataWrite("lsd:titler:active:trinket_pos", res_trinket_pos);
    llLinksetDataWrite("lsd:titler:active:scroll_width", res_scroll_width);
    llLinksetDataWrite("lsd:titler:active:scroll_enabled", res_scroll_enabled);
    llLinksetDataWrite("lsd:titler:active:flicker_glitch", res_flicker);
    llLinksetDataWrite("lsd:titler:active:font", res_font);
    llLinksetDataWrite("lsd:titler:active:dur", res_dur);
    
    string g_typing_cursor = llLinksetDataRead("lsd:titler:typing_cursor"); if (g_typing_cursor == "") g_typing_cursor = "_";
    llLinksetDataWrite("lsd:titler:active:typing_cursor", g_typing_cursor);
    llLinksetDataWrite("lsd:titler:active:blink_cursor", res_blink);
    
    // Update rotate:active block (for cascading inheritance in next message)
    llLinksetDataWrite("lsd:titler:rotate:active:color", res_color);
    llLinksetDataWrite("lsd:titler:rotate:active:color_end", res_color_end);
    llLinksetDataWrite("lsd:titler:rotate:active:color_trans", res_color_trans);
    llLinksetDataWrite("lsd:titler:rotate:active:alpha", res_alpha);
    llLinksetDataWrite("lsd:titler:rotate:active:height", res_height);
    llLinksetDataWrite("lsd:titler:rotate:active:align", res_align);
    llLinksetDataWrite("lsd:titler:rotate:active:trans_in", res_trans_in);
    llLinksetDataWrite("lsd:titler:rotate:active:trans_out", res_trans_out);
    llLinksetDataWrite("lsd:titler:rotate:active:trans_speed", res_trans_speed);
    llLinksetDataWrite("lsd:titler:rotate:active:trinket_style", res_trinket_style);
    llLinksetDataWrite("lsd:titler:rotate:active:trinket_pos", res_trinket_pos);
    llLinksetDataWrite("lsd:titler:rotate:active:scroll_width", res_scroll_width);
    llLinksetDataWrite("lsd:titler:rotate:active:scroll_enabled", res_scroll_enabled);
    llLinksetDataWrite("lsd:titler:rotate:active:flicker_glitch", res_flicker);
    llLinksetDataWrite("lsd:titler:rotate:active:font", res_font);
    llLinksetDataWrite("lsd:titler:rotate:active:blink_cursor", res_blink);
}

write_active_override_params(string dur, string color, string alpha, string trans_in, string trans_out, string trans_speed, string trinket_style, string trinket_pos, string align, string height, string scroll_enabled)
{
    string g_color          = llLinksetDataRead("lsd:titler:color");         if (g_color == "") g_color = "<1.0, 0.6, 0.8>";
    string g_alpha          = llLinksetDataRead("lsd:titler:alpha");         if (g_alpha == "") g_alpha = "1.0";
    string g_height         = llLinksetDataRead("lsd:titler:height");        if (g_height == "") g_height = "0.5";
    string g_anim_style     = llLinksetDataRead("lsd:titler:anim_style");    if (g_anim_style == "") g_anim_style = "GLITCH";
    string g_trans_speed    = llLinksetDataRead("lsd:titler:trans_speed");   if (g_trans_speed == "") g_trans_speed = "0.15";
    string g_trinket_style  = llLinksetDataRead("lsd:titler:trinket_style"); if (g_trinket_style == "") g_trinket_style = "HEX";
    string g_trinket_pos    = llLinksetDataRead("lsd:titler:trinket_pos");   if (g_trinket_pos == "") g_trinket_pos = "BOTH";
    string g_scroll_width   = llLinksetDataRead("lsd:titler:scroll_width");  if (g_scroll_width == "") g_scroll_width = "20";
    string g_scroll_enabled = llLinksetDataRead("lsd:titler:scroll_enabled"); if (g_scroll_enabled == "") g_scroll_enabled = "1";
    
    if (dur == "default" || dur == "") dur = "4.0";
    if (color == "default" || color == "") color = g_color;
    if (alpha == "default" || alpha == "") alpha = g_alpha;
    if (trans_in == "default" || trans_in == "") trans_in = g_anim_style;
    if (trans_out == "default" || trans_out == "") trans_out = g_anim_style;
    if (trans_speed == "default" || trans_speed == "") trans_speed = g_trans_speed;
    if (trinket_style == "default" || trinket_style == "") trinket_style = g_trinket_style;
    if (trinket_pos == "default" || trinket_pos == "") trinket_pos = g_trinket_pos;
    if (align == "default" || align == "") align = "CENTER";
    if (height == "default" || height == "") height = g_height;
    if (scroll_enabled == "default" || scroll_enabled == "") scroll_enabled = g_scroll_enabled;
    
    string g_typing_cursor = llLinksetDataRead("lsd:titler:typing_cursor"); if (g_typing_cursor == "") g_typing_cursor = "_";
    string g_blink_cursor = llLinksetDataRead("lsd:titler:blink_cursor"); if (g_blink_cursor == "") g_blink_cursor = "1";
    string g_flicker = llLinksetDataRead("lsd:titler:flicker_glitch"); if (g_flicker == "") g_flicker = "0";
    string g_font = llLinksetDataRead("lsd:titler:active_font"); if (g_font == "") g_font = "DEFAULT";
    
    llLinksetDataWrite("lsd:titler:active:typing_cursor", g_typing_cursor);
    llLinksetDataWrite("lsd:titler:active:blink_cursor", g_blink_cursor);
    llLinksetDataWrite("lsd:titler:active:flicker_glitch", g_flicker);
    llLinksetDataWrite("lsd:titler:active:font", g_font);
    
    llLinksetDataWrite("lsd:titler:active:dur", dur);
    llLinksetDataWrite("lsd:titler:active:color", color);
    llLinksetDataWrite("lsd:titler:active:color_end", color);
    llLinksetDataWrite("lsd:titler:active:color_trans", color);
    llLinksetDataWrite("lsd:titler:active:alpha", alpha);
    llLinksetDataWrite("lsd:titler:active:height", height);
    llLinksetDataWrite("lsd:titler:active:align", align);
    llLinksetDataWrite("lsd:titler:active:trans_in", trans_in);
    llLinksetDataWrite("lsd:titler:active:trans_out", trans_out);
    llLinksetDataWrite("lsd:titler:active:trans_speed", trans_speed);
    llLinksetDataWrite("lsd:titler:active:trinket_style", trinket_style);
    llLinksetDataWrite("lsd:titler:active:trinket_pos", trinket_pos);
    llLinksetDataWrite("lsd:titler:active:scroll_width", g_scroll_width);
    llLinksetDataWrite("lsd:titler:active:scroll_enabled", scroll_enabled);
}

trigger_next_queue_item()
{
    integer q_count = (integer)llLinksetDataRead("lsd:titler:queue_count");
    if (q_count <= 0) return;
    
    string prefix = "lsd:titler:queue:0:";
    string text = llLinksetDataRead(prefix + "text");
    string dur = llLinksetDataRead(prefix + "dur"); if (dur == "default" || dur == "") dur = "4.0";
    string color = llLinksetDataRead(prefix + "color");
    string alpha = llLinksetDataRead(prefix + "alpha");
    string trans_in = llLinksetDataRead(prefix + "trans_in");
    string trans_out = llLinksetDataRead(prefix + "trans_out");
    string trans_speed = llLinksetDataRead(prefix + "trans_speed");
    string trinket_style = llLinksetDataRead(prefix + "trinket_style");
    string trinket_pos = llLinksetDataRead(prefix + "trinket_pos");
    string align = llLinksetDataRead(prefix + "align");
    string height = llLinksetDataRead(prefix + "height");
    string scroll_enabled = llLinksetDataRead(prefix + "scroll_enabled");
    
    integer i;
    for (i = 1; i < q_count; ++i)
    {
        string old_pref = "lsd:titler:queue:" + (string)i + ":";
        string new_pref = "lsd:titler:queue:" + (string)(i - 1) + ":";
        
        llLinksetDataWrite(new_pref + "text", llLinksetDataRead(old_pref + "text"));
        llLinksetDataWrite(new_pref + "dur", llLinksetDataRead(old_pref + "dur"));
        llLinksetDataWrite(new_pref + "color", llLinksetDataRead(old_pref + "color"));
        llLinksetDataWrite(new_pref + "alpha", llLinksetDataRead(old_pref + "alpha"));
        llLinksetDataWrite(new_pref + "trans_in", llLinksetDataRead(old_pref + "trans_in"));
        llLinksetDataWrite(new_pref + "trans_out", llLinksetDataRead(old_pref + "trans_out"));
        llLinksetDataWrite(new_pref + "trans_speed", llLinksetDataRead(old_pref + "trans_speed"));
        llLinksetDataWrite(new_pref + "trinket_style", llLinksetDataRead(old_pref + "trinket_style"));
        llLinksetDataWrite(new_pref + "trinket_pos", llLinksetDataRead(old_pref + "trinket_pos"));
        llLinksetDataWrite(new_pref + "align", llLinksetDataRead(old_pref + "align"));
        llLinksetDataWrite(new_pref + "height", llLinksetDataRead(old_pref + "height"));
        llLinksetDataWrite(new_pref + "scroll_enabled", llLinksetDataRead(old_pref + "scroll_enabled"));
    }
    
    string last_pref = "lsd:titler:queue:" + (string)(q_count - 1) + ":";
    llLinksetDataDelete(last_pref + "text");
    llLinksetDataDelete(last_pref + "dur");
    llLinksetDataDelete(last_pref + "color");
    llLinksetDataDelete(last_pref + "alpha");
    llLinksetDataDelete(last_pref + "trans_in");
    llLinksetDataDelete(last_pref + "trans_out");
    llLinksetDataDelete(last_pref + "trans_speed");
    llLinksetDataDelete(last_pref + "trinket_style");
    llLinksetDataDelete(last_pref + "trinket_pos");
    llLinksetDataDelete(last_pref + "align");
    llLinksetDataDelete(last_pref + "height");
    llLinksetDataDelete(last_pref + "scroll_enabled");
    
    llLinksetDataWrite("lsd:titler:queue_count", (string)(q_count - 1));
    write_active_override_params(dur, color, alpha, trans_in, trans_out, trans_speed, trinket_style, trinket_pos, align, height, scroll_enabled);
    
    gActiveMsgIdx = -2; // Mark queue message active
    gCurrentRawText = text;
    
    string resolved = resolve_message(text, FALSE, -1);
    update_parser_timer(text);
    llMessageLinked(LINK_SET, 185, "RENDER_START|" + resolved, NULL_KEY);
}

queue_message(string type, string text, string dur, string color, string alpha, string trans_in, string trans_out, string trans_speed, string trinket_style, string trinket_pos, string align, string height, string scroll_enabled)
{
    integer q_count = (integer)llLinksetDataRead("lsd:titler:queue_count");
    integer insert_idx = q_count;
    
    if (type == "IMMEDIATE")
    {
        integer i;
        for (i = q_count - 1; i >= 0; --i)
        {
            string old_pref = "lsd:titler:queue:" + (string)i + ":";
            string new_pref = "lsd:titler:queue:" + (string)(i + 1) + ":";
            
            llLinksetDataWrite(new_pref + "text", llLinksetDataRead(old_pref + "text"));
            llLinksetDataWrite(new_pref + "dur", llLinksetDataRead(old_pref + "dur"));
            llLinksetDataWrite(new_pref + "color", llLinksetDataRead(old_pref + "color"));
            llLinksetDataWrite(new_pref + "alpha", llLinksetDataRead(old_pref + "alpha"));
            llLinksetDataWrite(new_pref + "trans_in", llLinksetDataRead(old_pref + "trans_in"));
            llLinksetDataWrite(new_pref + "trans_out", llLinksetDataRead(old_pref + "trans_out"));
            llLinksetDataWrite(new_pref + "trans_speed", llLinksetDataRead(old_pref + "trans_speed"));
            llLinksetDataWrite(new_pref + "trinket_style", llLinksetDataRead(old_pref + "trinket_style"));
            llLinksetDataWrite(new_pref + "trinket_pos", llLinksetDataRead(old_pref + "trinket_pos"));
            llLinksetDataWrite(new_pref + "align", llLinksetDataRead(old_pref + "align"));
            llLinksetDataWrite(new_pref + "height", llLinksetDataRead(old_pref + "height"));
            llLinksetDataWrite(new_pref + "scroll_enabled", llLinksetDataRead(old_pref + "scroll_enabled"));
        }
        insert_idx = 0;
        llLinksetDataWrite("lsd:titler:queue_count", (string)(q_count + 1));
    }
    else
    {
        llLinksetDataWrite("lsd:titler:queue_count", (string)(q_count + 1));
    }
    
    string prefix = "lsd:titler:queue:" + (string)insert_idx + ":";
    llLinksetDataWrite(prefix + "text", text);
    llLinksetDataWrite(prefix + "dur", dur);
    llLinksetDataWrite(prefix + "color", color);
    llLinksetDataWrite(prefix + "alpha", alpha);
    llLinksetDataWrite(prefix + "trans_in", trans_in);
    llLinksetDataWrite(prefix + "trans_out", trans_out);
    llLinksetDataWrite(prefix + "trans_speed", trans_speed);
    llLinksetDataWrite(prefix + "trinket_style", trinket_style);
    llLinksetDataWrite(prefix + "trinket_pos", trinket_pos);
    llLinksetDataWrite(prefix + "align", align);
    llLinksetDataWrite(prefix + "height", height);
    llLinksetDataWrite(prefix + "scroll_enabled", scroll_enabled);
    
    if (type == "IMMEDIATE")
    {
        trigger_next_queue_item();
    }
}

update_status_tag(string tag_data)
{
    list parts = llParseString2List(tag_data, ["|"], []);
    integer count = llGetListLength(parts);
    if (count <= 0) return;
    
    string tag_name = llLinksetDataRead("lsd:titler:status_tag");
    float val = 0.0;
    
    string q_dur = "default";
    string q_col = "default";
    string q_alp = "default";
    string q_tin = "default";
    string q_tout = "default";
    string q_tspd = "default";
    string q_tsty = "default";
    string q_tpos = "default";
    string q_alg = "default";
    string q_hgt = "default";
    string q_scrl = "default";
    
    if (count >= 2)
    {
        tag_name = llStringTrim(llList2String(parts, 0), STRING_TRIM);
        val = (float)llStringTrim(llList2String(parts, 1), STRING_TRIM);
        
        if (count > 2) q_dur = llStringTrim(llList2String(parts, 2), STRING_TRIM);
        if (count > 3) q_col = llStringTrim(llList2String(parts, 3), STRING_TRIM);
        if (count > 4) q_alp = llStringTrim(llList2String(parts, 4), STRING_TRIM);
        if (count > 5) q_tin = llStringTrim(llList2String(parts, 5), STRING_TRIM);
        if (count > 6) q_tout = llStringTrim(llList2String(parts, 6), STRING_TRIM);
        if (count > 7) q_tspd = llStringTrim(llList2String(parts, 7), STRING_TRIM);
        if (count > 8) q_tsty = llStringTrim(llList2String(parts, 8), STRING_TRIM);
        if (count > 9) q_tpos = llStringTrim(llList2String(parts, 9), STRING_TRIM);
        if (count > 10) q_alg = llStringTrim(llList2String(parts, 10), STRING_TRIM);
        if (count > 11) q_hgt = llStringTrim(llList2String(parts, 11), STRING_TRIM);
        if (count > 12) q_scrl = llStringTrim(llList2String(parts, 12), STRING_TRIM);
    }
    else
    {
        val = (float)llStringTrim(tag_data, STRING_TRIM);
    }
    
    if (val < 0.0) val = 0.0;
    if (val > 100.0) val = 100.0;
    
    if (tag_name == "") return;
    
    llLinksetDataWrite("lsd:titler:status_val:" + tag_name, (string)val);
    
    string reg_list = llLinksetDataRead("lsd:titler:status_tags_list");
    list tags = llParseString2List(reg_list, ["|"], []);
    if (llListFindList(tags, [tag_name]) == -1)
    {
        if (reg_list == "") reg_list = tag_name;
        else reg_list += "|" + tag_name;
        llLinksetDataWrite("lsd:titler:status_tags_list", reg_list);
    }
    
    integer queue_updates = (integer)llLinksetDataRead("lsd:titler:queue_status_updates");
    if (queue_updates == 1)
    {
        string bar_style = llLinksetDataRead("lsd:titler:status_bar_style"); if (bar_style == "") bar_style = "BLOCK";
        string bar_len_str = llLinksetDataRead("lsd:titler:status_bar_len");
        integer bar_len = 5;
        if (bar_len_str != "") bar_len = (integer)bar_len_str;
        
        string bar = generate_progress_bar(val, bar_style, bar_len);
        string status_msg = "⬡ " + tag_name + ": " + bar + " (" + (string)((integer)val) + "%) ⬡";
        
        if (q_dur == "default" || q_dur == "") q_dur = "4.0";
        
        queue_message("QUEUE", status_msg, q_dur, q_col, q_alp, q_tin, q_tout, q_tspd, q_tsty, q_tpos, q_alg, q_hgt, q_scrl);
    }
    
    if (llSubStringIndex(gCurrentRawText, "%" + tag_name + "%") != -1)
    {
        string resolved = resolve_message(gCurrentRawText, (gActiveMsgIdx == -1), gActiveMsgIdx);
        llMessageLinked(LINK_SET, 185, "RENDER_UPDATE|" + resolved, NULL_KEY);
    }
}

// Master parsing function to resolve all variables, roles, fonts and layout bounds
string resolve_message(string raw_text, integer is_preview, integer msg_idx)
{
    if (!is_preview && msg_idx != -1)
    {
        resolve_overrides(msg_idx);
    }
    
    string resolved = raw_text;
    
    resolved = replace_string(resolved, "%name%", llGetDisplayName(llGetOwner()));
    
    string uname = llKey2Name(llGetOwner());
    if (uname == "") uname = llGetDisplayName(llGetOwner());
    resolved = replace_string(resolved, "%username%", uname);
    
    string owner_name = llLinksetDataRead("lsd:titler:owner_name");
    if (owner_name == "") owner_name = llGetDisplayName(llGetOwner());
    resolved = replace_string(resolved, "%owner%", owner_name);
    
    string t_str = format_time();
    resolved = replace_string(resolved, "%time%", t_str);
    resolved = replace_string(resolved, "%sltime%", t_str);
    
    resolved = replace_string(resolved, "%sim%", llGetRegionName());
    
    // Status Bar tags resolution
    string reg_list = llLinksetDataRead("lsd:titler:status_tags_list");
    string primary_tag = llLinksetDataRead("lsd:titler:status_tag");
    if (primary_tag != "" && llSubStringIndex(reg_list, primary_tag) == -1)
    {
        if (reg_list == "") reg_list = primary_tag;
        else reg_list += "|" + primary_tag;
    }
    
    list tags = llParseString2List(reg_list, ["|"], []);
    integer tag_count = llGetListLength(tags);
    integer t_idx;
    for (t_idx = 0; t_idx < tag_count; ++t_idx)
    {
        string t_name = llList2String(tags, t_idx);
        string tag_to_find = "%" + t_name + "%";
        if (llSubStringIndex(resolved, tag_to_find) != -1)
        {
            string specific_val = llLinksetDataRead("lsd:titler:status_val:" + t_name);
            if (specific_val == "") specific_val = llLinksetDataRead("lsd:titler:status_val");
            float status_val = (float)specific_val;
            
            string bar_style = llLinksetDataRead("lsd:titler:status_bar_style"); if (bar_style == "") bar_style = "BLOCK";
            string bar_len_str = llLinksetDataRead("lsd:titler:status_bar_len");
            integer bar_len = 5;
            if (bar_len_str != "")
            {
                bar_len = (integer)bar_len_str;
                if (bar_len < 5) bar_len = 5;
                if (bar_len > 15) bar_len = 15;
            }
            
            string bar = generate_progress_bar(status_val, bar_style, bar_len);
            resolved = replace_string(resolved, tag_to_find, bar);
        }
    }
    
    resolved = resolve_roles(resolved);
    
    string active_font = llLinksetDataRead("lsd:titler:active:font");
    if (active_font == "") active_font = llLinksetDataRead("lsd:titler:active_font");
    if (active_font != "" && active_font != "DEFAULT")
    {
        resolved = translate_font(resolved, active_font);
    }
    
    string active_align = "CENTER";
    if (!is_preview)
    {
        active_align = llLinksetDataRead("lsd:titler:active:align");
    }
    resolved = pad_alignment(resolved, active_align);
    
    return resolved;
}

update_listener()
{
    if (gListenHandle != 0)
    {
        llListenRemove(gListenHandle);
        gListenHandle = 0;
    }
    
    string chan_str = llLinksetDataRead("lsd:titler:status_channel");
    if (chan_str != "")
    {
        integer chan = (integer)chan_str;
        if (chan != 0)
        {
            gListenHandle = llListen(chan, "", NULL_KEY, "");
        }
    }
}

// Timer checks if real-time dynamic tags (%time%) exist to manage update rate
update_parser_timer(string raw_text)
{
    if (llSubStringIndex(raw_text, "%time%") != -1 || llSubStringIndex(raw_text, "%sltime%") != -1)
    {
        llSetTimerEvent(1.0);
    }
    else
    {
        llSetTimerEvent(0.0);
    }
}

default
{
    state_entry()
    {
        llSetMemoryLimit(65536);
        update_listener();
    }

    link_message(integer sender_num, integer code, string str, key id)
    {
        // Code 180: RELOAD configuration and update listener
        if (code == 180)
        {
            update_listener();
            
            // Re-render current message if it's active
            if (gCurrentRawText != "" && gActiveMsgIdx != -2)
            {
                string resolved = resolve_message(gCurrentRawText, (gActiveMsgIdx == -1), gActiveMsgIdx);
                llMessageLinked(LINK_SET, 185, "RENDER_UPDATE|" + resolved, NULL_KEY);
            }
            return;
        }

        // Code 182: PREVIEW raw text (parse preview and send to engine as Code 182)
        if (code == 182)
        {
            gActiveMsgIdx = -1;
            gCurrentRawText = str;
            update_parser_timer(gCurrentRawText);
            
            string resolved = resolve_message(gCurrentRawText, TRUE, -1);
            llMessageLinked(LINK_SET, 182, resolved, id);
            return;
        }

        // Code 184: Status percentage update
        if (code == 184)
        {
            update_status_tag(str);
            return;
        }

        // Code 186: NEXT_MSG selection and override resolution
        if (code == 186)
        {
            integer q_count = (integer)llLinksetDataRead("lsd:titler:queue_count");
            if (q_count > 0)
            {
                trigger_next_queue_item();
                return;
            }
            
            integer msg_count = (integer)llLinksetDataRead("lsd:titler:msg_count");
            if (msg_count <= 0)
            {
                gActiveMsgIdx = 0;
                gCurrentRawText = "Nᴇxᴜs Tɪᴛʟᴇʀ";
                
                // Fall back to defaults in LSD active block
                llLinksetDataWrite("lsd:titler:active:color", "<1.0, 0.6, 0.8>");
                llLinksetDataWrite("lsd:titler:active:color_end", "<1.0, 0.6, 0.8>");
                llLinksetDataWrite("lsd:titler:active:color_trans", "<1.0, 0.6, 0.8>");
                llLinksetDataWrite("lsd:titler:active:alpha", "1.0");
                llLinksetDataWrite("lsd:titler:active:height", "0.5");
                llLinksetDataWrite("lsd:titler:active:align", "CENTER");
                llLinksetDataWrite("lsd:titler:active:trans_in", "GLITCH");
                llLinksetDataWrite("lsd:titler:active:trans_out", "GLITCH");
                llLinksetDataWrite("lsd:titler:active:trans_speed", "0.15");
                llLinksetDataWrite("lsd:titler:active:trinket_style", "HEX");
                llLinksetDataWrite("lsd:titler:active:trinket_pos", "BOTH");
                llLinksetDataWrite("lsd:titler:active:scroll_width", "20");
                llLinksetDataWrite("lsd:titler:active:scroll_enabled", "1");
                llLinksetDataWrite("lsd:titler:active:dur", "5.0");
                
                string resolved = resolve_message(gCurrentRawText, FALSE, -1);
                update_parser_timer(gCurrentRawText);
                llMessageLinked(LINK_SET, 185, "RENDER_START|" + resolved, NULL_KEY);
                return;
            }
            
            string cycle_order = llLinksetDataRead("lsd:titler:cycle_order"); if (cycle_order == "") cycle_order = "SEQ";
            integer next_idx = gActiveMsgIdx + 1;
            
            if (cycle_order == "SHUFFLE" && msg_count > 1)
            {
                next_idx = (integer)llFrand(msg_count);
                if (next_idx == gActiveMsgIdx) next_idx = (next_idx + 1) % msg_count;
            }
            else
            {
                if (next_idx >= msg_count || next_idx < 0) next_idx = 0;
            }
            
            gActiveMsgIdx = next_idx;
            llLinksetDataWrite("lsd:titler:active_msg_idx", (string)gActiveMsgIdx);
            
            gCurrentRawText = llLinksetDataRead("lsd:titler:msg:" + (string)gActiveMsgIdx + ":text");
            if (gCurrentRawText == "") gCurrentRawText = "Nᴇxᴜs Mᴏᴅᴜʟᴇ";
            
            string resolved = resolve_message(gCurrentRawText, FALSE, gActiveMsgIdx);
            update_parser_timer(gCurrentRawText);
            
            llMessageLinked(LINK_SET, 185, "RENDER_START|" + resolved, NULL_KEY);
            return;
        }

        // Code 190: External queue insertion
        if (code == 190)
        {
            list parts = llParseString2List(str, ["|"], []);
            string q_type = llStringTrim(llList2String(parts, 0), STRING_TRIM);
            string q_text = llList2String(parts, 1);
            string q_dur  = llList2String(parts, 2); if (q_dur == "") q_dur = "default";
            string q_col  = llList2String(parts, 3); if (q_col == "") q_col = "default";
            string q_alp  = llList2String(parts, 4); if (q_alp == "") q_alp = "default";
            string q_tin  = llList2String(parts, 5); if (q_tin == "") q_tin = "default";
            string q_tout = llList2String(parts, 6); if (q_tout == "") q_tout = "default";
            string q_tspd = llList2String(parts, 7); if (q_tspd == "") q_tspd = "default";
            string q_tsty = llList2String(parts, 8); if (q_tsty == "") q_tsty = "default";
            string q_tpos = llList2String(parts, 9); if (q_tpos == "") q_tpos = "default";
            string q_alg  = llList2String(parts, 10); if (q_alg == "") q_alg = "default";
            string q_hgt  = llList2String(parts, 11); if (q_hgt == "") q_hgt = "default";
            string q_scrl = llList2String(parts, 12); if (q_scrl == "") q_scrl = "default";
            
            queue_message(q_type, q_text, q_dur, q_col, q_alp, q_tin, q_tout, q_tspd, q_tsty, q_tpos, q_alg, q_hgt, q_scrl);
            return;
        }

        // Code 188: External role updates
        if (code == 188)
        {
            list parts = llParseString2List(str, ["|"], []);
            string role_name = llList2String(parts, 0);
            string role_val = llList2String(parts, 1);
            
            llLinksetDataWrite("lsd:titler:role:" + role_name, role_val);
            
            string role_list = llLinksetDataRead("lsd:titler:role_list");
            list roles = llParseString2List(role_list, ["|"], []);
            if (llListFindList(roles, [role_name]) == -1)
            {
                if (role_list == "") role_list = role_name;
                else role_list += "|" + role_name;
                llLinksetDataWrite("lsd:titler:role_list", role_list);
            }
            
            // Re-render active message if it uses this role tag
            if (llSubStringIndex(gCurrentRawText, "%role:" + role_name + "%") != -1)
            {
                string resolved = resolve_message(gCurrentRawText, (gActiveMsgIdx == -1), gActiveMsgIdx);
                llMessageLinked(LINK_SET, 185, "RENDER_UPDATE|" + resolved, NULL_KEY);
            }
            return;
        }
    }

    listen(integer channel, string name, key id, string message)
    {
        // Public listener percentage updates
        string msg = llStringTrim(message, STRING_TRIM);
        if (msg != "")
        {
            if (llGetSubString(msg, -1, -1) == "%")
            {
                msg = llGetSubString(msg, 0, -2);
            }
            update_status_tag(msg);
        }
    }

    timer()
    {
        // Real-time timer update for clock variables (%time%)
        string resolved = resolve_message(gCurrentRawText, (gActiveMsgIdx == -1), gActiveMsgIdx);
        llMessageLinked(LINK_SET, 185, "RENDER_UPDATE|" + resolved, NULL_KEY);
    }
}
