# Detailed Implementation Plan — Standalone Nexus Titler

Create a fully standalone, modular, four-script LSL floating text titler with advanced transitions, idle trinkets, language-agnostic font mappings, customizable roles, flexible status bars, and paginated override menus.

---

## 1. Core Technical Specifications

### 1.1 `titler_loader.lsl` (Font & Notecard Loader)
*   **Function:** Loads custom fonts from a notecard named `Fonts.txt`.
*   **Notecard Line Format:** `FontName | SourceCharacters | TargetCharacters`
    *   *Example:* `Bubble | abcdefghijklmnopqrstuvwxyz | ⓐⓑⓒⓓⓔⓕⓖⓗⓘⓙⓚⓛⓜⓝⓞⓟⓠⓡⓢⓣⓤⓥⓦⓧⓨⓩ`
*   **Logic:**
    *   Reads line-by-line via `llGetNotecardLine`.
    *   Parses lines by splitting on `|` with whitespace trimming.
    *   Validates character string lengths (warns wearer in local chat if mapping lengths mismatch).
    *   Writes maps to LSD: `lsd:titler:font:<fontname>:source` and `lsd:titler:font:<fontname>:target`.
    *   Appends `<fontname>` to `lsd:titler:font_list` if not present.
    *   Communicates loading status to UI via Link Message Code 187: `STATUS|fontname|OK` or `ERROR|msg`.

### 1.2 `titler_parser.lsl` (Tag & Translation Resolver)
*   **Override Resolution:** When triggered by `NEXT_MSG` (Code 186):
    *   Reads message parameters from `lsd:titler:msg:<idx>:*`.
    *   If any parameter is blank or missing, falls back to the global default in `lsd:titler:global:*`.
    *   If a parameter equals `"RANDOM"`, executes the **Parameter Randomization Engine** (described below).
    *   Writes all resolved parameters to the active block: `lsd:titler:active:*`.
*   **Dynamic Variable Tag Parsing:**
    *   `%name%` ➔ Wearer's display name (`llGetDisplayName(llGetOwner())`).
    *   `%username%` ➔ Wearer's account username (`llKey2Name(llGetOwner())` or display name fallback).
    *   `%owner%` ➔ User-defined owner name (`lsd:titler:owner_name`).
    *   `%time%` / `%sltime%` ➔ Local SL time (HH:MM:SS format via `llGetWallclock`).
    *   `%sim%` ➔ Current region name (`llGetRegionName()`).
*   **Flexible Status Tag:**
    *   Locates `%<status_tag>%` (value of `lsd:titler:status_tag`, e.g. `%battery%`).
    *   Constructs a status bar using the value from `lsd:titler:status_val` (0.0 to 100.0) and style from `lsd:titler:status_bar_style` (e.g. `BLOCK` ➔ `████░`, `HEART` ➔ `♥♥♥♥♡`, `SPARK` ➔ `✦✦✦✦✧`).
*   **Custom Roles System:**
    *   Replaces tags matching `%role:<key>%` with the custom value from `lsd:titler:role:<key>`.
*   **Language-Agnostic Font Mapping:**
    *   For the selected font, reads `source` and `target` strings from LSD.
    *   Runs letter-by-letter index lookup. Letters not found in `source` map pass through unmodified (Foreign Language/Kanji Immunity).
*   **Smart Line Alignment Padding:**
    *   Enforces max **6 lines** constraint.
    *   If `align` is `LEFT` or `RIGHT`, calculates line lengths, pads lines with spaces.
    *   Checks final byte size. If padded string exceeds **254 bytes**, strips padding and falls back to standard center text to prevent SL engine truncation.
*   **External Open Listeners:**
    *   Listens on chat channel (`lsd:titler:status_channel`) to receive percentage updates (updates `lsd:titler:status_val`).
    *   Listens on Link Message Code 184 for the same updates.
*   **Output:** Sends Code 185 `RENDER_START|<resolved_text>` to the Engine.

### 1.3 `titler_engine.lsl` (Visual FX & Prim Controller)
*   **Startup/Configuration:**
    *   Adjusts local height prim position (`PRIM_POS_LOCAL`) via `lsd:titler:active:height`.
    *   Reads `trans_in`, `trans_out`, `trans_speed`, `color`, `color_end`, `color_trans`, `alpha`, `trinket_style`, `trinket_pos`, `scroll_enabled`, `scroll_width` from the active block.
*   **Modular Entry/Exit Transitions:**
    *   `INSTANT`: Direct text render.
    *   `GLITCH`: Renders random chaos glyphs (`꩜⚙❖█▓...`), resolving letter-by-letter.
    *   `WIPE`: Sweeps character cursor from left-to-right.
    *   `FADE`: Collapses outgoing string to a single center dot `·`, then expands incoming.
    *   `TYPING`: Letter-by-letter reveal with a flashing trailing underscore `_`.
    *   `MATRIX_HORIZ`: Scrambles characters horizontally through random code glyphs before settling.
    *   `MATRIX_VERT`: Cascades streams of characters vertically using newlines before solidifying.
*   **Highlight Flashing:** Uses `color_trans` highlight color during Transition-In/Out animations, switching to the main color when fully resolved.
*   **Animated Trinkets:** Cycles unicode brackets on independent sub-timers (SLOW, MED, FAST).
*   **Horizontal Scrolling:** Handles wide ticker wrapping for lines exceeding scroll width.
*   **Flicker Glitch:** Randomly corrupts 1-2 letters of static text occasionally if enabled.
*   **Interpolated Colors & Alpha Fades:** Postponed to a later milestone, but structured for quick insertion.

### 1.4 `titler_menu.lsl` (UI & Paginated Dialog Controller)
*   **Paginated dynamic lists:** 12-button pages for messages and roles to bypass LSL limits.
*   **Menu Navigation Structure:**
    *   **Main Menu:** Toggles enabling, global defaults links, Fonts/Roles settings.
    *   **Messages List:** Dynamic paginated list of entries.
    *   **Message Editor:** Edit Text, Edit Dur, Presets Sub-menu, Preview, Delete, and:
        *   `Before FX...` (Transition-In style, speed, color overrides)
        *   `During FX...` (Trinkets, scrolling, smart alignment, flicker overrides)
        *   `After FX...` (Transition-Out style, speed, color overrides)
        *   `Appearance...` (Start color, alpha, height, alignment, randomize overrides)
    *   **Style Presets:** Cyber, Princess, Terminal, Glitch, Reset templates.
    *   **Roles Manager:** Add/edit custom role keywords and names.
    *   **Fonts Manager:** Toggle active font, reload Fonts.txt notecard.

---

## 2. Proposed Changes & File Layout

#### [NEW] [DESIGN.md](file:///C:/Users/Matti/Documents/antigravity/excited-turing/standalone_titler/DESIGN.md) (Already Created)
*   System architectural reference document.

#### [NEW] [titler_loader.lsl](file:///C:/Users/Matti/Documents/antigravity/excited-turing/standalone_titler/titler_loader.lsl)
*   Font loader notecard reader.

#### [NEW] [titler_parser.lsl](file:///C:/Users/Matti/Documents/antigravity/excited-turing/standalone_titler/titler_parser.lsl)
*   Variable, font, and custom status bar parser, smart alignment, and chat listeners.

#### [NEW] [titler_engine.lsl](file:///C:/Users/Matti/Documents/antigravity/excited-turing/standalone_titler/titler_engine.lsl)
*   Floating text renderer, scrolling, trinkets, transition timers, and animation logic.

#### [NEW] [titler_menu.lsl](file:///C:/Users/Matti/Documents/antigravity/excited-turing/standalone_titler/titler_menu.lsl)
*   Main configuration menu, message editor (text, duration, delete), presets, touch/chat entry.

#### [NEW] [titler_menu_overrides.lsl](file:///C:/Users/Matti/Documents/antigravity/excited-turing/standalone_titler/titler_menu_overrides.lsl)
*   Visual effects configuration menus (Before, During, After FX), Appearance overlays, Font list selection, custom roles management, status tag details.

---

## 3. Verification Plan

### Automated Verification
*   We will run `lslint` on all four scripts:
    *   `lslint standalone_titler/titler_loader.lsl`
    *   `lslint standalone_titler/titler_parser.lsl`
    *   `lslint standalone_titler/titler_engine.lsl`
    *   `lslint standalone_titler/titler_menu.lsl`

### Manual Verification
1.  **Loader test:** Put a notecard with font character maps in a test prim and check that fonts populate LSD without warnings.
2.  **Parser/Engine transition test:** Run previews of different messages with different transitions (glitch, wipe, typing, matrix) to verify animations resolve correctly.
3.  **Variable replacement test:** Input text like `%name% has %battery% charge` and verify tags and custom progress bars render.
4.  **Language mapping test:** Test mixed Japanese-English lines to verify foreign language immunity.
5.  **Smart Alignment test:** Configure left/right alignments and long strings to verify character bounds are respected and falling back safely.
6.  **Menu flow test:** Traverse all menus, add/edit/delete messages, and apply style presets.
