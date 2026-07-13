// titler_loader.lsl — Font & Notecard Loader
// Parses font translation mappings from the Fonts.txt notecard and stores them in LSD.

// Link Message Codes:
// Code 180 (In): RELOAD_FONTS -> Trigger notecard parsing
// Code 187 (Out): STATUS|fontname|OK or ERROR|msg -> Font loading status updates

string NOTECARD_NAME = "Fonts.txt";
key gQueryId;
integer gLineIndex;

// Clears all font keys from LinksetData (Clean Slate rule)
delete_fonts()
{
    list keys = llLinksetDataFindKeys("^lsd:titler:font:", 0, 50);
    while (llGetListLength(keys) > 0)
    {
        integer len = llGetListLength(keys);
        integer i;
        for (i = 0; i < len; ++i)
        {
            llLinksetDataDelete(llList2String(keys, i));
        }
        keys = llLinksetDataFindKeys("^lsd:titler:font:", 0, 50);
    }
    llLinksetDataDelete("lsd:titler:font_list");
    llLinksetDataDelete("lsd:titler:active_font");
}

start_loading()
{
    if (llGetInventoryType(NOTECARD_NAME) != INVENTORY_NOTECARD)
    {
        llMessageLinked(LINK_SET, 187, "ERROR|Fonts.txt notecard is missing in inventory.", NULL_KEY);
        llOwnerSay("/me [Loader Error]: " + NOTECARD_NAME + " notecard is missing in inventory.");
        return;
    }
    
    llOwnerSay("/me [Loader]: Starting font load (Clean Slate)...");
    delete_fonts();
    
    gLineIndex = 0;
    gQueryId = llGetNotecardLine(NOTECARD_NAME, gLineIndex);
}

default
{
    state_entry()
    {
        llSetMemoryLimit(65536);
        start_loading();
    }

    changed(integer change)
    {
        if (change & CHANGED_INVENTORY)
        {
            start_loading();
        }
    }

    link_message(integer sender_num, integer code, string str, key id)
    {
        if (code == 180 && str == "RELOAD_FONTS")
        {
            start_loading();
        }
    }

    dataserver(key query_id, string data)
    {
        if (query_id != gQueryId) return;

        if (data == EOF)
        {
            llMessageLinked(LINK_SET, 187, "STATUS|ALL_LOADED|OK", NULL_KEY);
            llOwnerSay("/me [Loader]: All fonts loaded successfully.");
            
            // Send standard RELOAD to let all scripts know config updated
            llMessageLinked(LINK_SET, 180, "RELOAD", NULL_KEY);
            return;
        }

        string line = llStringTrim(data, STRING_TRIM);
        
        // Skip comments and empty lines
        if (line != "" && llGetSubString(line, 0, 0) != "#" && llGetSubString(line, 0, 1) != "//")
        {
            // Parse line: FontName | SourceCharacters | TargetCharacters
            integer first_pipe = llSubStringIndex(line, "|");
            if (first_pipe != -1)
            {
                string font_name = llStringTrim(llGetSubString(line, 0, first_pipe - 1), STRING_TRIM);
                string remaining = llGetSubString(line, first_pipe + 1, -1);
                
                integer second_pipe = llSubStringIndex(remaining, "|");
                if (second_pipe != -1)
                {
                    string source_chars = llStringTrim(llGetSubString(remaining, 0, second_pipe - 1), STRING_TRIM);
                    string target_chars = llStringTrim(llGetSubString(remaining, second_pipe + 1, -1), STRING_TRIM);
                    
                    integer src_len = llStringLength(source_chars);
                    integer tgt_len = llStringLength(target_chars);
                    
                    if (src_len != tgt_len)
                    {
                        string err = "Length mismatch (" + (string)src_len + " vs " + (string)tgt_len + ") in font '" + font_name + "'. Skip.";
                        llMessageLinked(LINK_SET, 187, "ERROR|" + err, NULL_KEY);
                        llOwnerSay("/me [Loader Warning]: " + err);
                    }
                    else
                    {
                        // Store to LSD
                        llLinksetDataWrite("lsd:titler:font:" + font_name + ":source", source_chars);
                        llLinksetDataWrite("lsd:titler:font:" + font_name + ":target", target_chars);
                        
                        // Update font list
                        string font_list = llLinksetDataRead("lsd:titler:font_list");
                        if (font_list == "")
                        {
                            font_list = font_name;
                        }
                        else
                        {
                            // Ensure no duplicates in font list
                            list existing = llParseString2List(font_list, ["|"], []);
                            if (llListFindList(existing, [font_name]) == -1)
                            {
                                font_list += "|" + font_name;
                            }
                        }
                        llLinksetDataWrite("lsd:titler:font_list", font_list);
                        
                        llMessageLinked(LINK_SET, 187, "STATUS|" + font_name + "|OK", NULL_KEY);
                    }
                }
                else
                {
                    string err = "Invalid line format at line " + (string)(gLineIndex + 1) + ". Expected: FontName | Src | Tgt";
                    llMessageLinked(LINK_SET, 187, "ERROR|" + err, NULL_KEY);
                }
            }
        }

        // Read next line
        gLineIndex++;
        gQueryId = llGetNotecardLine(NOTECARD_NAME, gLineIndex);
    }
}
