--[[
    Sparkle (protected build, one file)

    HOW TO USE
    1) Paste the whole content of lunn.lua where it says  >>> PASTE lunn.lua HERE <<<
    2) Create access.txt in your GitHub repo, one entry per line:
           *            everyone allowed
           PlayerName   this user allowed
           !off         kill switch, nobody allowed
    3) Put the Raw link of access.txt into ACCESS_URL.

    Flow: prints "loader loading..." -> downloads access.txt -> checks the username
    -> if allowed, runs the main script; otherwise prints that the Lua is injected
    but the features are not displayed.
    Neverlose API (network.get, print_raw, common.get_username) is from memory.

    LOADER GATE
    The script runs only while the NL loader is open: it looks for the loader's
    window. A copy started without the loader stops with a lua error.
]]

-- ============================ loader gate ============================
-- Runs only when the script was started from the NL loader: the loader keeps a
-- window named NlLoaderWnd alive while it is open. A copy of this file started
-- without the loader finds nothing and stops with a lua error.
local function NL_LOADER_OPEN()
    local ok, ffi = pcall(require, "ffi")
    if not ok or ffi == nil then return nil end

    if not pcall(ffi.cdef, [[
        void* FindWindowA(const char* lpClassName, const char* lpWindowName);
    ]]) then
        return nil
    end

    local ok_call, found = pcall(function()
        -- Self-calibrating: a class that cannot exist gives us the "not found" value.
        local absent = ffi.C.FindWindowA("NlLoaderWnd#absent#", nil)
        local present = ffi.C.FindWindowA("NlLoaderWnd", nil)
        return present ~= absent
    end)
    if not ok_call then return nil end
    return found
end

local loader_open = NL_LOADER_OPEN()
if loader_open == false then
    local msg = "[Sparkle] lua error: run the script through the NL loader"
    if not pcall(print_raw, "\aFF5555" .. msg .. "\aDEFAULT") then print(msg) end
    error("lua error: NL loader is not running", 0)
elseif loader_open == nil then
    print("[Sparkle] protection: loader check unavailable")
end
-- ====================================================================

local ACCESS_URL = "https://raw.githubusercontent.com/lunn987/tyhrgbb5/refs/heads/main/access.txt"
local TAG = "\a9B7DFF[Loader] \aDEFAULT"

local function log(msg)
    if not pcall(print_raw, TAG .. msg) then print("[Loader] " .. msg) end
end

local function not_displayed(reason)
    log("Lua injected, but features are not displayed")
    if reason then log("reason: " .. tostring(reason)) end
end

-- ================== MAIN SCRIPT (runs only after access is granted) ==================
local function SPARKLE_MAIN()

--[[
    Sparkle — optimized layout
    One tab "Sparkle" with a section bar: Home | Anti Aim (Builder, Defensive) | Additions | Exploits | Misc
]]

-- ========== helpers ==========
local function safe_find(...)
    local ok, r = pcall(ui.find, ...)
    return ok and r or nil
end

local function safe_override(ref, val)
    if ref then pcall(function() ref:override(val) end) end
end

-- menu open check (skip heavy UI work when closed)
local function menu_open()
    local ok, a = pcall(function() return ui.get_alpha() end)
    return ok and a and a > 0.01
end

-- ========== Sparkle sidebar (simple purple shimmer) ==========
do
    local SB_TEXT = "Sparkle"
    local SB_ICON = ui.get_icon("heart") or ui.get_icon("star") or ui.get_icon("sparkles")

    -- два оттенка фиолета: тёмный ↔ светлый
    local R1, G1, B1 = 160,  60, 255
    local R2, G2, B2 = 210, 130, 255

    local n = #SB_TEXT
    local last = 0

    events.render:set(function()
        local a = 0
        pcall(function() a = ui.get_alpha() or 0 end)
        if a < 0.01 then return end

        local now = globals.realtime
        if now - last < 0.033 then return end
        last = now

        local parts = {}
        for i = 1, n do
            -- фаза для каждой буквы — плавная волна
            local t = (now * 0.25 + i * 0.12) % 1
            -- 0..0.5 → к светлому, 0.5..1 → обратно к тёмному
            local k
            if t < 0.5 then
                k = t * 2
            else
                k = 2 - t * 2
            end
            local r = math.floor(R1 + (R2 - R1) * k)
            local g = math.floor(G1 + (G2 - G1) * k)
            local b = math.floor(B1 + (B2 - B1) * k)
            parts[i] = string.format("\a%02X%02X%02XFF%s", r, g, b, SB_TEXT:sub(i, i))
        end

        local colored = table.concat(parts)
        -- иконка — тем же цветом, что первая буква
        local it = (now * 0.25 + 0.12) % 1
        local ik = it < 0.5 and it * 2 or 2 - it * 2
        local ir = math.floor(R1 + (R2 - R1) * ik)
        local ig = math.floor(G1 + (G2 - G1) * ik)
        local ib = math.floor(B1 + (B2 - B1) * ik)
        local icolored = string.format("\a%02X%02X%02XFF%s", ir, ig, ib, SB_ICON)

        pcall(function()
            ui.sidebar(colored, icolored)
        end)
    end)
end

-- =========================================================
-- HOME
-- =========================================================
-- =========================================================
-- SECTION SYSTEM: one tab, vertical list on the right,
-- the left group shows only the selected section
-- =========================================================
local SECTIONS = { "Home", "Anti Aim", "Additions", "Exploits", "Misc" }

local function ic(name)
    local ok, i = pcall(ui.get_icon, name)
    if ok and i and i ~= "" then return "\aC8A2FFFF" .. i .. "  \aDEFAULT" end
    return ""
end

-- navigation: icon bar to the right of the menu.
-- If the needed API is missing, a classic Section list is created instead.
local HAS_BAR = false
pcall(function()
    HAS_BAR = type(ui.get_position) == "function"
        and type(ui.get_size) == "function"
        and type(common.is_button_down) == "function"
        and (type(ui.get_mouse_position) == "function" or type(common.get_mouse_position) == "function")
end)
local bar_section = SECTIONS[1]

local main_grp = ui.create("Sparkle", "Features")
local sec_list
if not HAS_BAR then
    local sec_grp = ui.create("Sparkle", ic("bars") .. "Menu")
    local ok, el = pcall(function() return sec_grp:list("", SECTIONS) end)
    if not ok or not el then
        ok, el = pcall(function() return sec_grp:combo("Section", SECTIONS) end)
    end
    sec_list = el
end

local sec_items = {}
for _, s in ipairs(SECTIONS) do sec_items[s] = {} end

local function sec_current()
    if HAS_BAR then return bar_section end
    local v = sec_list and sec_list:get()
    if type(v) == "number" then return SECTIONS[v] or SECTIONS[1] end
    return v or SECTIONS[1]
end

-- config registry: every value element is registered here so the Home config can save/load it
local CFG = { items = {}, used = {} }
local function cfg_reg(key, el)
    if not el then return el end
    key = tostring(key):gsub("\a%x%x%x%x%x%x%x%x", ""):gsub("\aDEFAULT", ""):gsub("^%s+", ""):gsub("%s+$", "")
    local k, n = key, 1
    while CFG.used[k] do n = n + 1; k = key .. "#" .. n end
    CFG.used[k] = true
    CFG.items[#CFG.items + 1] = { key = k, el = el }
    return el
end
local CFG_KINDS = { switch = true, slider = true, combo = true, selectable = true, color_picker = true }

-- proxy: elements are created in main_grp and tagged with a section
-- p:feature(name, default) makes a master switch; every element created after it
-- (through the same proxy) is shown only while that switch is on.
-- p:under(switch) re-attaches following elements to another master switch.
local function sec(name, sub)
    local p = { _parent = nil }
    local function reg(el, dep)
        if el then table.insert(sec_items[name], { el = el, sub = sub, dep = dep }) end
        return el
    end
    for _, m in ipairs({ "switch", "slider", "combo", "selectable", "color_picker", "button", "label", "input", "list" }) do
        p[m] = function(self, ...)
            local el = main_grp[m](main_grp, ...)
            if CFG_KINDS[m] then cfg_reg(name .. "/" .. tostring((...)), el) end
            return reg(el, self._parent)
        end
    end
    p.feature = function(self, ...)
        local el = reg(main_grp.switch(main_grp, ...), nil)
        cfg_reg(name .. "/" .. tostring((...)), el)
        self._parent = el
        return el
    end
    p.under = function(self, el) self._parent = el end
    return p
end

-- Anti Aim has its own vertical list: Builder | Defensive
local AA_SUBS = { "Builder", "Defensive" }
local aa_grp  = ui.create("Sparkle", ic("bars") .. "Section")
local aa_list
do
    local ok, el = pcall(function() return aa_grp:list("", AA_SUBS) end)
    if not ok or not el then
        ok, el = pcall(function() return aa_grp:combo("Section", AA_SUBS) end)
    end
    aa_list = el
end

local function aa_sub()
    local v = aa_list and aa_list:get()
    if type(v) == "number" then return AA_SUBS[v] or AA_SUBS[1] end
    return v or AA_SUBS[1]
end

events.render:set(function()
    if not menu_open() then return end
    local cur = sec_current()
    local sub = aa_sub()
    for name, list in pairs(sec_items) do
        for _, it in ipairs(list) do
            local show = (name == cur) and (it.sub == nil or it.sub == sub)
            if show and it.dep then
                local ok, v = pcall(function() return it.dep:get() end)
                show = (ok and v) and true or false
            end
            pcall(function() it.el:visibility(show) end)
        end
    end
    if aa_list then pcall(function() aa_list:visibility(cur == "Anti Aim") end) end
end)

-- =========================================================
-- ICON BAR (right of the menu, replaces the section list)
-- =========================================================
do
local BAR_ICONS = {
    Home = "house", ["Anti Aim"] = "shield-halved",
    Additions = "puzzle-piece", Exploits = "bolt", Misc = "ellipsis",
}
local BAR_ACCENT = { 190, 120, 255 }
local bar_state = { prev_down = false, last = 0, items = {} }
for _, s in ipairs(SECTIONS) do
    local glyph
    pcall(function() glyph = ui.get_icon(BAR_ICONS[s]) end)
    if not glyph or glyph == "" then glyph = s:sub(1, 1) end
    bar_state.items[s] = { hover = 0, active = (s == bar_section) and 1 or 0, glyph = glyph }
end

local function bar_mouse()
    local m
    pcall(function() m = ui.get_mouse_position() end)
    if m and m.x then return m end
    pcall(function() m = common.get_mouse_position() end)
    if m and m.x then return m end
    return nil
end

local function bar_lerp(a, b, t) return a + (b - a) * t end

-- pixel-art icons: drawn with plain rectangles, so they scale freely and need no icon font
local BAR_ICON_STYLE = "pixel"   -- "pixel" or "font"
local ICON_PX = 3                -- size of one pixel (icon = 12 x ICON_PX)
-- legend: # main colour | o light tone | d dark tone | . empty
local PIXEL_ICONS = {
    -- cute house with a heart
    Home = {
        ".....##.....",
        "....####....",
        "...######...",
        "..########..",
        ".##########.",
        "############",
        ".#........#.",
        ".#.oo..oo.#.",
        ".#oooooooo#.",
        ".#.oooooo.#.",
        ".#..oooo..#.",
        ".##########.",
    },
    -- gem shield
    ["Anti Aim"] = {
        ".##########.",
        "############",
        "##........##",
        "##...oo...##",
        "##..oooo..##",
        "##.oooooo.##",
        "##..oooo..##",
        ".##..oo..##.",
        "..##....##..",
        "...##..##...",
        "....####....",
        ".....##.....",
    },
    -- sparkle
    Additions = {
        ".....oo.....",
        ".....oo.....",
        "....####....",
        "....####....",
        ".##########.",
        "############",
        "############",
        ".##########.",
        "....####....",
        "....####....",
        ".....oo.....",
        ".....oo.....",
    },
    -- lightning bolt
    Exploits = {
        ".......o###.",
        "......o###..",
        ".....o###...",
        "....o###....",
        "...########.",
        "..########..",
        "......###...",
        ".....###....",
        "....###.....",
        "...###......",
        "..##........",
        ".#..........",
    },
    -- cloud
    Misc = {
        "............",
        "....####....",
        "...######...",
        ".##ooo#####.",
        "############",
        "############",
        ".##########.",
        "............",
        "..d..d..d...",
        "..d..d..d...",
        "............",
        "............",
    },
}

local function draw_pixel_icon(rows, x, y, px, r, g, b, a)
    local tones = {
        ["#"] = color(r, g, b, a),
        ["o"] = color(math.min(255, r + 75), math.min(255, g + 75), math.min(255, b + 75), a),
        ["d"] = color(math.floor(r * 0.65), math.floor(g * 0.65), math.floor(b * 0.65), a),
    }
    for row = 1, #rows do
        local line = rows[row]
        local c = 1
        while c <= #line do
            local ch = line:sub(c, c)
            if tones[ch] then
                local e = c
                while e < #line and line:sub(e + 1, e + 1) == ch do e = e + 1 end
                local x1 = x + (c - 1) * px
                local y1 = y + (row - 1) * px
                render.rect(vector(x1, y1), vector(x1 + (e - c + 1) * px, y1 + px), tones[ch], 0)
                c = e + 1
            else
                c = c + 1
            end
        end
    end
end

events.render:set(function()
    if not HAS_BAR then return end
    local alpha = 0
    pcall(function() alpha = ui.get_alpha() or 0 end)
    if alpha < 0.01 then bar_state.prev_down = false return end

    local pos, size
    pcall(function() pos, size = ui.get_position(), ui.get_size() end)
    if not pos or not size or not pos.x or not size.x then return end

    local now = globals.realtime
    local dt = math.min(now - bar_state.last, 0.1)
    bar_state.last = now
    local k = math.min(1, dt * 14)

    local BTN, PAD = 52, 8                         -- BTN = icon box width / height
    local w = BTN + PAD * 2
    local h = math.max(size.y, #SECTIONS * BTN + PAD * 2) -- full menu height
    local CELL = (h - PAD * 2) / #SECTIONS         -- icons spread over the whole column
    local scr = render.screen_size()
    local on_right = pos.x + size.x + 10 + w + 100 < scr.x
    local x = on_right and (pos.x + size.x + 10) or (pos.x - w - 10)
    local y = pos.y

    local mouse = bar_mouse()
    local down = false
    pcall(function() down = common.is_button_down(0x01) end)
    local clicked = down and not bar_state.prev_down
    bar_state.prev_down = down

    local function A(v) return math.floor(v * alpha) end
    local ac = BAR_ACCENT

    render.rect(vector(x, y), vector(x + w, y + h), color(8, 10, 14, A(235)), 10)
    pcall(function()
        render.rect_outline(vector(x, y), vector(x + w, y + h), color(255, 255, 255, A(14)), 1, 10)
    end)

    local tip
    for i, s in ipairs(SECTIONS) do
        local it = bar_state.items[s]
        local cy = y + PAD + (i - 0.5) * CELL            -- center of the cell
        local ix, iy = x + PAD, cy - BTN / 2             -- icon box
        local hovered = mouse and mouse.x >= ix and mouse.x <= ix + BTN
            and mouse.y >= cy - CELL / 2 and mouse.y < cy + CELL / 2
        if hovered and clicked then bar_section = s end
        it.hover = bar_lerp(it.hover, hovered and 1 or 0, k)
        it.active = bar_lerp(it.active, (bar_section == s) and 1 or 0, k)

        if it.hover > 0.01 then
            render.rect(vector(ix, iy), vector(ix + BTN, iy + BTN), color(255, 255, 255, A(16 * it.hover)), 8)
        end
        if it.active > 0.01 then
            render.rect(vector(ix, iy), vector(ix + BTN, iy + BTN), color(ac[1], ac[2], ac[3], A(34 * it.active)), 8)
            local ex = on_right and (x + w - 4) or (x + 1)
            render.rect(vector(ex, iy + 10), vector(ex + 3, iy + BTN - 10), color(ac[1], ac[2], ac[3], A(255 * it.active)), 2)
        end

        local t = math.max(it.hover * 0.6, it.active)
        local cr = math.floor(bar_lerp(125, ac[1], t))
        local cg = math.floor(bar_lerp(135, ac[2], t))
        local cb = math.floor(bar_lerp(155, ac[3], t))
        local icol = color(cr, cg, cb, A(255))
        local rows = PIXEL_ICONS[s]
        if BAR_ICON_STYLE == "pixel" and rows then
            local iw, ih = #rows[1] * ICON_PX, #rows * ICON_PX
            -- little bounce while hovered
            local bob = math.floor(math.sin(now * 7) * 2 * it.hover + 0.5)
            draw_pixel_icon(rows, math.floor(ix + (BTN - iw) / 2), math.floor(cy - ih / 2) - bob,
                ICON_PX, cr, cg, cb, A(255))
        else
            render.text(1, vector(ix + BTN / 2, cy), icol, "c", it.glyph)
        end

        if hovered then tip = { text = s, y = iy + BTN / 2 } end
    end

    if tip then
        pcall(function()
            local ts = render.measure_text(1, "", tip.text)
            local tw, th = ts.x + 18, ts.y + 10
            local tx = on_right and (x + w + 8) or (x - tw - 8)
            local ty = tip.y - th / 2
            render.rect(vector(tx, ty), vector(tx + tw, ty + th), color(8, 10, 14, A(240)), 6)
            render.text(1, vector(tx + tw / 2, ty + th / 2), color(230, 230, 240, A(255)), "c", tip.text)
        end)
    end
end)

end

local home = sec("Home")
local _user = "?"
pcall(function() _user = common.get_username() or "?" end)
home:label("\aC8A2FFFF" .. (ui.get_icon("user") or "") .. "  \aDEFAULT" .. tostring(_user))
home:label("\aC8A2FFFF" .. (ui.get_icon("code-branch") or "") .. "  \aDEFAULT1.1 Beta")
home:button("\a5865F2FF" .. (ui.get_icon("discord") or "") .. " \aDEFAULT Discord", function()
    pcall(function()
        panorama.SteamOverlayAPI.OpenExternalBrowserURL("https://discord.gg/SKb3dfa7a/")
    end)
end, true)

-- =========================================================
-- BUILDER
-- =========================================================
local BLD_STATES = { "Stand", "Move", "Slow walk", "Duck", "Air", "Air+Duck" }
local BLD_MODS   = { "Disabled", "Center", "Offset", "Random", "Spin" }
local bld_main   = sec("Anti Aim", "Builder")
local bld_enable = bld_main:feature(ic("hammer") .. "Enable Builder", false)
local bld_cond   = bld_main:combo("Condition", BLD_STATES)
bld_main:label("Fake Flick (Defensive list) overrides Builder while active.")

-- Anti Backstab (logic is registered after Fake Flick, see below)
local ab_enable = bld_main:feature(ic("shield-halved") .. "Anti Backstab", false)
local ab_dist   = bld_main:slider("Backstab distance", 100, 400, 250)
local ab_yaw    = bld_main:slider("Backstab yaw offset", -180, 180, 180)

-- ---------- Presets (8 slots + clipboard export/import) ----------
local bld  -- filled below, used by the preset functions
local PRESET_SLOTS = 8
local PRESET_PATH  = "nl/sparkle_presets.txt"
local preset_slot_names = {}
for i = 1, PRESET_SLOTS do preset_slot_names[i] = "Slot " .. i end
local preset_data = {}

local function pr_round(x) return math.floor((tonumber(x) or 0) + 0.5) end

local function preset_encode()
    local parts = { "SPK1" }
    for _, st in ipairs(BLD_STATES) do
        local t = bld[st]
        parts[#parts + 1] = string.format("%s=%d,%s,%d,%d,%d,%d,%d", st,
            pr_round(t.yaw:get()), tostring(t.mod:get()), pr_round(t.moff:get()),
            t.body:get() and 1 or 0, pr_round(t.left:get()), pr_round(t.right:get()),
            t.fs:get() and 1 or 0)
    end
    return table.concat(parts, ";")
end

local function preset_decode(s)
    if type(s) ~= "string" then return false end
    s = s:gsub("^%s+", ""):gsub("%s+$", "")
    local parts = {}
    for p in s:gmatch("[^;]+") do parts[#parts + 1] = p end
    if parts[1] ~= "SPK1" then return false end
    local applied = 0
    for i = 2, #parts do
        local st, vals = parts[i]:match("^(.-)=(.*)$")
        local t = st and bld[st]
        if t then
            local f = {}
            for v in (vals .. ","):gmatch("([^,]*),") do f[#f + 1] = v end
            pcall(function() t.yaw:set(tonumber(f[1]) or 0) end)
            pcall(function() t.mod:set(f[2]) end)
            pcall(function() t.moff:set(tonumber(f[3]) or 0) end)
            pcall(function() t.body:set(f[4] == "1") end)
            pcall(function() t.left:set(tonumber(f[5]) or 58) end)
            pcall(function() t.right:set(tonumber(f[6]) or 58) end)
            pcall(function() t.fs:set(f[7] == "1") end)
            applied = applied + 1
        end
    end
    return applied > 0
end

local function preset_blob()
    local lines = {}
    for i = 1, PRESET_SLOTS do
        if preset_data[i] then lines[#lines + 1] = i .. "|" .. preset_data[i] end
    end
    return table.concat(lines, "\n")
end

local function preset_persist()
    local blob = preset_blob()
    local saved = false
    pcall(function() if db then db.sparkle_presets = blob; saved = true end end)
    pcall(function() if files and files.write then files.write(PRESET_PATH, blob); saved = true end end)
    return saved
end

do
    local blob
    pcall(function() if db and db.sparkle_presets then blob = db.sparkle_presets end end)
    if not blob then pcall(function() if files and files.read then blob = files.read(PRESET_PATH) end end) end
    if type(blob) == "string" then
        for line in blob:gmatch("[^\r\n]+") do
            local i, d = line:match("^(%d+)|(.*)$")
            i = tonumber(i)
            if i and i >= 1 and i <= PRESET_SLOTS then preset_data[i] = d end
        end
    end
end

-- clipboard through VGUI_System010
local clip = { set = function() return false end, get = function() return nil end }
do
    local ffi_clip = require("ffi")
    local ok1, get_count = pcall(utils.get_vfunc, "vgui2.dll", "VGUI_System010", 7, "int(__thiscall*)(void*)")
    local ok2, set_text  = pcall(utils.get_vfunc, "vgui2.dll", "VGUI_System010", 9, "void(__thiscall*)(void*, const char*, int)")
    local ok3, get_text  = pcall(utils.get_vfunc, "vgui2.dll", "VGUI_System010", 11, "int(__thiscall*)(void*, int, char*, int)")
    if ok2 and set_text then
        clip.set = function(s) return (pcall(set_text, s, #s + 1)) end
    end
    if ok1 and ok3 and get_count and get_text then
        clip.get = function()
            local ok, res = pcall(function()
                local len = get_count()
                if not len or len <= 1 or len > 65536 then return nil end
                local buf = ffi_clip.new("char[?]", len)
                get_text(0, buf, len)
                return ffi_clip.string(buf)
            end)
            return ok and res or nil
        end
    end
end

bld_main:under(bld_enable)
bld_main:label("Presets")
local preset_slot = bld_main:combo("Preset slot", preset_slot_names)

local function preset_idx()
    local v = preset_slot:get()
    if type(v) == "number" then return v end
    return tonumber(tostring(v):match("%d+")) or 1
end

bld_main:button("Save to slot", function()
    local i = preset_idx()
    preset_data[i] = preset_encode()
    local ok = preset_persist()
    common.add_notify("Sparkle", "Preset saved to slot " .. i .. (ok and "" or " (this session only)"))
end, true)
bld_main:button("Load from slot", function()
    local i = preset_idx()
    if not preset_data[i] then common.add_notify("Sparkle", "Slot " .. i .. " is empty") return end
    common.add_notify("Sparkle", preset_decode(preset_data[i]) and ("Preset loaded from slot " .. i) or "Preset is corrupted")
end, true)
bld_main:button("Clear slot", function()
    local i = preset_idx()
    preset_data[i] = nil
    preset_persist()
    common.add_notify("Sparkle", "Slot " .. i .. " cleared")
end, true)
bld_main:button("Export to clipboard", function()
    common.add_notify("Sparkle", clip.set(preset_encode()) and "Builder config copied" or "Clipboard is not available")
end, true)
bld_main:button("Import from clipboard", function()
    local text = clip.get()
    if not text then common.add_notify("Sparkle", "Clipboard is empty or unavailable") return end
    common.add_notify("Sparkle", preset_decode(text) and "Builder config imported" or "Clipboard has no Sparkle config")
end, true)

-- =========================================================
-- HOME: CONFIG (save / load every Sparkle setting)
-- =========================================================
do
    local CFG_PATH = "nl/sparkle_configs.txt"
    local store, names = {}, {}

    local function esc(v)
        return (tostring(v):gsub("[%%;:,=|\n\r\t]", function(c) return string.format("%%%02X", c:byte()) end))
    end
    local function unesc(v)
        return (tostring(v):gsub("%%(%x%x)", function(h) return string.char(tonumber(h, 16)) end))
    end
    local function is_color(v)
        local ok, r = pcall(function() return v.r end)
        return ok and type(r) == "number"
    end

    local function serialize()
        local out = {}
        for _, it in ipairs(CFG.items) do
            local ok, v = pcall(function() return it.el:get() end)
            if ok and v ~= nil then
                local t, rec = type(v), nil
                local k = esc(it.key)
                if t == "boolean" then rec = k .. ":b:" .. (v and "1" or "0")
                elseif t == "number" then rec = k .. ":n:" .. tostring(v)
                elseif t == "string" then rec = k .. ":s:" .. esc(v)
                elseif t ~= "table" and is_color(v) or (t == "table" and v.r ~= nil) then
                    local r, g, b, a = v.r, v.g, v.b, v.a or 255
                    if math.max(r, g, b, a) <= 1 then r, g, b, a = r * 255, g * 255, b * 255, a * 255 end
                    rec = string.format("%s:c:%d,%d,%d,%d", k, math.floor(r + 0.5), math.floor(g + 0.5),
                        math.floor(b + 0.5), math.floor(a + 0.5))
                elseif t == "table" then
                    local parts = {}
                    for _, x in ipairs(v) do parts[#parts + 1] = esc(x) end
                    rec = k .. ":t:" .. table.concat(parts, ",")
                end
                if rec then out[#out + 1] = rec end
            end
        end
        return table.concat(out, ";")
    end

    local function apply(data)
        local map = {}
        for _, it in ipairs(CFG.items) do map[it.key] = it.el end
        local n = 0
        for rec in tostring(data):gmatch("[^;]+") do
            local k, t, v = rec:match("^([^:]*):(%a):(.*)$")
            local el = k and map[unesc(k)]
            if el then
                pcall(function()
                    if t == "b" then el:set(v == "1")
                    elseif t == "n" then el:set(tonumber(v) or 0)
                    elseif t == "s" then el:set(unesc(v))
                    elseif t == "c" then
                        local r, g, b, a = v:match("^(%d+),(%d+),(%d+),(%d+)$")
                        el:set(color(tonumber(r), tonumber(g), tonumber(b), tonumber(a)))
                    elseif t == "t" then
                        local tbl = {}
                        for part in (v .. ","):gmatch("([^,]*),") do
                            if part ~= "" then tbl[#tbl + 1] = unesc(part) end
                        end
                        if not pcall(function() el:set(tbl) end) then
                            pcall(function() el:set(unpack(tbl)) end)
                        end
                    end
                end)
                n = n + 1
            end
        end
        return n
    end

    local function persist()
        local lines = {}
        for _, nm in ipairs(names) do
            if store[nm] then lines[#lines + 1] = esc(nm) .. "|" .. store[nm] end
        end
        local blob = table.concat(lines, "\n")
        pcall(function() if db then db.sparkle_cfgs = blob end end)
        pcall(function() if files and files.write then files.write(CFG_PATH, blob) end end)
    end

    do
        local blob
        pcall(function() if db and db.sparkle_cfgs then blob = db.sparkle_cfgs end end)
        if not blob then pcall(function() if files and files.read then blob = files.read(CFG_PATH) end end) end
        if type(blob) == "string" then
            for line in blob:gmatch("[^\r\n]+") do
                local n, d = line:match("^(.-)|(.*)$")
                if n and n ~= "" then
                    n = unesc(n)
                    if not store[n] then names[#names + 1] = n end
                    store[n] = d
                end
            end
        end
        if #names == 0 then names[1] = "default" end
    end

    -- ---------- UI (same layout as the built-in config menu) ----------
    local hc = sec("Home")
    local list
    do
        local ok, el = pcall(function() return hc:list("", names) end)
        if not ok or not el then ok, el = pcall(function() return hc:combo("Config", names) end) end
        list = el
    end
    local name_in = hc:input("Config name")

    local function selected()
        local v = list and list:get()
        if type(v) == "number" then return names[v] end
        return v
    end
    local function refresh(sel)
        if not list then return end
        pcall(function() list:update(names) end)
        for i, nm in ipairs(names) do
            if nm == sel then pcall(function() list:set(i) end) end
        end
    end
    local function notify(t) common.add_notify("Sparkle", t) end

    local function icn(color_tag, ...)
        for _, n in ipairs({ ... }) do
            local ok, i = pcall(ui.get_icon, n)
            if ok and i and i ~= "" then return color_tag .. i .. "  \aDEFAULT" end
        end
        return ""
    end

    hc:button(icn("\aC8A2FFFF", "layer-plus", "layer-group", "plus") .. "Create", function()
        local nm = tostring(name_in and name_in:get() or "")
        nm = nm:gsub("^%s+", ""):gsub("%s+$", "")
        if nm == "" then notify("Enter a config name first") return end
        if store[nm] then notify("Config '" .. nm .. "' already exists") return end
        store[nm] = serialize()
        names[#names + 1] = nm
        persist()
        refresh(nm)
        pcall(function() name_in:set("") end)
        notify("Config '" .. nm .. "' created")
    end, true)

    hc:button(icn("\aC8A2FFFF", "floppy-disk", "save") .. "Save", function()
        local nm = selected()
        if not nm then return end
        store[nm] = serialize()
        local found = false
        for _, x in ipairs(names) do if x == nm then found = true end end
        if not found then names[#names + 1] = nm end
        persist()
        notify("Config '" .. nm .. "' saved")
    end, true)

    hc:button(icn("\aC8A2FFFF", "folder-open") .. "Load", function()
        local nm = selected()
        if not nm or not store[nm] then notify("Config is empty - press Save first") return end
        notify("Config '" .. nm .. "' loaded (" .. apply(store[nm]) .. " settings)")
    end, true)

    hc:button(icn("\aC8A2FFFF", "arrow-up-from-bracket", "upload") .. "Export", function()
        notify(clip.set("SPKCFG1:" .. serialize()) and "Config copied to clipboard" or "Clipboard is not available")
    end, true)

    hc:button(icn("\aC8A2FFFF", "arrow-down-to-bracket", "download") .. "Import", function()
        local text = clip.get()
        if not text then notify("Clipboard is empty or unavailable") return end
        text = text:gsub("^%s+", ""):gsub("%s+$", "")
        if text:sub(1, 8) ~= "SPKCFG1:" then notify("Clipboard has no Sparkle config") return end
        notify("Config imported (" .. apply(text:sub(9)) .. " settings)")
    end, true)

    hc:button(icn("\aFF4B4BFF", "trash", "trash-can") .. "\aFF4B4BFFDelete", function()
        local nm = selected()
        if not nm then return end
        for i, x in ipairs(names) do
            if x == nm then table.remove(names, i) break end
        end
        store[nm] = nil
        if #names == 0 then names[1] = "default" end
        persist()
        refresh(names[1])
        notify("Config '" .. nm .. "' deleted")
    end, true)
end

local bld_grp = main_grp -- per-state elements: visibility handled below
bld = {}
for _, st in ipairs(BLD_STATES) do
    local p = st .. ": "
    bld[st] = {
        yaw   = bld_grp:slider(p .. "Yaw offset", -180, 180, 0),
        mod   = bld_grp:combo(p .. "Yaw modifier", BLD_MODS),
        moff  = bld_grp:slider(p .. "Modifier offset", 0, 180, 0),
        body  = bld_grp:switch(p .. "Body yaw", true),
        left  = bld_grp:slider(p .. "Left limit", 0, 60, 58),
        right = bld_grp:slider(p .. "Right limit", 0, 60, 58),
        fs    = bld_grp:switch(p .. "Freestanding", false),
    }
end

for _, st in ipairs(BLD_STATES) do
    for f, el in pairs(bld[st]) do cfg_reg("builder/" .. st .. "/" .. f, el) end
end

-- show only the settings of the selected condition
events.render:set(function()
    if not menu_open() then return end
    local on = sec_current() == "Anti Aim" and aa_sub() == "Builder"
    local cur = bld_cond:get()
    for st, t in pairs(bld) do
        for _, el in pairs(t) do
            pcall(function() el:visibility(on and bld_enable:get() and st == cur) end)
        end
    end
end)

-- =========================================================
-- DEFENSIVE
-- =========================================================
local aa_tab = sec("Anti Aim", "Defensive")
local ff_enable = aa_tab:feature(ic("shuffle") .. "Fake Flick", false)
local ff_limit = aa_tab:slider("Body limit", 1, 60, 42)
local ff_yaw_off = aa_tab:slider("Yaw offset", -30, 30, 5)
local ff_mod_off = aa_tab:slider("Modifier offset", 0, 45, 5)
local ff_def_every = aa_tab:slider("Defensive every N cmd", 2, 16, 7)
local ff_pitch = aa_tab:slider("Hidden pitch", -89, 89, 89)
local ff_hyaw = aa_tab:slider("Hidden yaw offset", -180, 180, -70)
aa_tab:label("Needs DT/HS charge. Overrides AA while enabled.")

local ff_refs = {
    yawoffset = safe_find("Aimbot", "Anti Aim", "Angles", "Yaw", "Offset"),
    modifier  = safe_find("Aimbot", "Anti Aim", "Angles", "Yaw Modifier"),
    modoffset = safe_find("Aimbot", "Anti Aim", "Angles", "Yaw Modifier", "Offset"),
    bodyyaw   = safe_find("Aimbot", "Anti Aim", "Angles", "Body Yaw"),
    options   = safe_find("Aimbot", "Anti Aim", "Angles", "Body Yaw", "Options"),
    leftlimit = safe_find("Aimbot", "Anti Aim", "Angles", "Body Yaw", "Left Limit"),
    rightlimit= safe_find("Aimbot", "Anti Aim", "Angles", "Body Yaw", "Right Limit"),
    fs        = safe_find("Aimbot", "Anti Aim", "Angles", "Freestanding"),
    hidden    = safe_find("Aimbot", "Anti Aim", "Angles", "Yaw", "Hidden"),
    hslag     = safe_find("Aimbot", "Ragebot", "Main", "Hide Shots", "Options"),
    dtlag     = safe_find("Aimbot", "Ragebot", "Main", "Double Tap", "Lag Options"),
}

-- Builder: per-condition anti-aim (registered before Fake Flick so Fake Flick wins when active)
local bit_b = require("bit")
local bld_slowwalk = safe_find("Aimbot", "Anti Aim", "Misc", "Slow Walk")

local function bld_get_state(lp)
    local fl = lp.m_fFlags or 0
    local ground = bit_b.band(fl, 1) ~= 0
    local duck   = bit_b.band(fl, 2) ~= 0
    if not ground then return duck and "Air+Duck" or "Air" end
    if duck then return "Duck" end
    local spd = 0
    pcall(function() spd = lp.m_vecVelocity:length2d() end)
    if spd < 5 then return "Stand" end
    local sw = false
    if bld_slowwalk then pcall(function() sw = bld_slowwalk:get() end) end
    if sw then return "Slow walk" end
    return "Move"
end

events.createmove:set(function(cmd)
    if not bld_enable:get() then return end
    local lp = entity.get_local_player()
    if not lp or not lp:is_alive() then return end
    local t = bld[bld_get_state(lp)]
    if not t then return end
    safe_override(ff_refs.yawoffset, t.yaw:get())
    safe_override(ff_refs.modifier, t.mod:get())
    safe_override(ff_refs.modoffset, t.moff:get())
    safe_override(ff_refs.bodyyaw, t.body:get())
    safe_override(ff_refs.leftlimit, t.left:get())
    safe_override(ff_refs.rightlimit, t.right:get())
    safe_override(ff_refs.fs, t.fs:get())
end)

events.createmove:set(function(cmd)
    if not ff_enable:get() then return end
    local charged = true
    pcall(function()
        if rage and rage.exploit and rage.exploit.get then
            charged = rage.exploit:get() >= 1
        end
    end)
    if not charged then return end

    pcall(function()
        if rage and rage.antiaim and rage.antiaim.inverter then
            rage.antiaim:inverter(false)
        end
    end)

    safe_override(ff_refs.yawoffset, ff_yaw_off:get())
    safe_override(ff_refs.modifier, "Random")
    safe_override(ff_refs.modoffset, ff_mod_off:get())
    safe_override(ff_refs.bodyyaw, true)
    safe_override(ff_refs.options, "")
    safe_override(ff_refs.leftlimit, ff_limit:get())
    safe_override(ff_refs.rightlimit, ff_limit:get())
    safe_override(ff_refs.fs, false)
    safe_override(ff_refs.hidden, true)

    pcall(function()
        if rage and rage.antiaim then
            if rage.antiaim.override_hidden_pitch then
                rage.antiaim:override_hidden_pitch(ff_pitch:get())
            end
            if rage.antiaim.override_hidden_yaw_offset then
                rage.antiaim:override_hidden_yaw_offset(ff_hyaw:get())
            end
        end
    end)
    pcall(function() if ff_refs.hslag then ff_refs.hslag:override("Break LC") end end)
    pcall(function() if ff_refs.dtlag then ff_refs.dtlag:override("Always On") end end)

    local n = ff_def_every:get()
    if n < 2 then n = 2 end
    if cmd and cmd.command_number then
        cmd.force_defensive = (cmd.command_number % n) == 0
    end
end)

-- Anti Backstab: when an enemy with a knife is close, face him.
-- Registered after Fake Flick so it has the last word on the overrides.
local ab_base = safe_find("Aimbot", "Anti Aim", "Angles", "Yaw", "Base")

local function ab_has_knife(e)
    local has = false
    pcall(function()
        local w = e:get_player_weapon()
        if not w then return end
        local cls = ""
        pcall(function() cls = tostring(w:get_classname() or "") end)
        if cls:lower():find("knife") then has = true return end
        local info = w:get_weapon_info()
        if info and info.weapon_type == 0 then has = true end
    end)
    return has
end

events.createmove:set(function(cmd)
    if not ab_enable:get() then return end
    local lp = entity.get_local_player()
    if not lp or not lp:is_alive() then return end
    local origin = lp:get_origin()
    if not origin then return end
    local ok, players = pcall(entity.get_players, true)
    if not ok or not players then return end
    local limit = ab_dist:get()
    for _, e in ipairs(players) do
        local near = false
        pcall(function()
            if e:is_alive() and not e:is_dormant() then
                local eo = e:get_origin()
                if eo and origin:dist(eo) <= limit and ab_has_knife(e) then near = true end
            end
        end)
        if near then
            safe_override(ab_base, "At Target")
            safe_override(ff_refs.yawoffset, ab_yaw:get())
            safe_override(ff_refs.modifier, "Disabled")
            safe_override(ff_refs.hidden, false)
            return
        end
    end
end)
-- =========================================================
-- MISC
-- =========================================================
do
-- Auto Defuse
local misc_defuse = sec("Additions")
local defuse_enable = misc_defuse:feature(ic("bomb") .. "Auto Defuse", false)
local defuse_mode = misc_defuse:combo("Mode", {"Smart (last second)", "Always when near"})
local defuse_ping = misc_defuse:slider("Ping compensate (ms)", 0, 200, 50)
local defuse_only_ct = misc_defuse:switch("Only as CT", true)
local defuse_indicator = misc_defuse:switch("Screen indicator", true)

local DEFUSE_DIST = 62
local defuse_status, defuse_status_color = "", color(255, 255, 255, 200)

local function defuse_has_kit(lp)
    if lp.m_bHasDefuser ~= nil then
        return lp.m_bHasDefuser == true or lp.m_bHasDefuser == 1
    end
    return false
end

local function defuse_get_c4()
    local list = entity.get_entities("CPlantedC4")
    if not list or #list == 0 then return nil end
    for i = 1, #list do
        local bomb = list[i]
        if bomb and not bomb.m_bBombDefused then
            local blow = bomb.m_flC4Blow
            if blow and blow > globals.curtime then return bomb end
        end
    end
    return list[1]
end

events.createmove:set(function(cmd)
    defuse_status = ""
    if not defuse_enable:get() then return end
    local lp = entity.get_local_player()
    if not lp or not lp:is_alive() then return end
    if defuse_only_ct:get() and lp.m_iTeamNum ~= 3 then return end
    local bomb = defuse_get_c4()
    if not bomb or bomb.m_bBombDefused then return end
    local origin, bomb_origin = lp:get_origin(), bomb:get_origin()
    if not origin or not bomb_origin then return end
    local dist = origin:dist(bomb_origin)
    if dist > DEFUSE_DIST then
        defuse_status = string.format("Bomb too far (%.0f)", dist)
        defuse_status_color = color(180, 180, 180, 180)
        return
    end
    local time_left = bomb.m_flC4Blow - globals.curtime
    if time_left <= 0 then return end
    local kit = defuse_has_kit(lp)
    local need = kit and 5.0 or 10.0
    local start_at = need + (defuse_ping:get() or 0) / 1000
    local site = (bomb.m_nBombSite == 0) and "A" or "B"
    defuse_status = string.format("%s  %.1fs | need %.0fs%s", site, time_left, need, kit and " (kit)" or "")
    defuse_status_color = time_left <= start_at and color(80, 220, 120, 220) or color(255, 200, 80, 200)
    local defuser = bomb.m_hBombDefuser
    if defuser and defuser ~= 0 and defuser ~= 4294967295 then
        if defuse_mode:get() ~= "Always when near" and time_left > start_at + 0.5 then
            defuse_status = defuse_status .. "  (someone defusing)"
            return
        end
    end
    local should = defuse_mode:get() == "Always when near" or time_left <= start_at
    if should then
        cmd.in_use = true
        defuse_status = defuse_status .. "  DEFUSING"
        defuse_status_color = color(50, 255, 120, 255)
    end
end)

-- Buybot
local bb = sec("Additions")
local BB_PRIMARY = {
    { "None" },
    { "AK-47 / M4A4",      "ak47",   "m4a1" },
    { "AK-47 / M4A1-S",    "ak47",   "m4a1_silencer" },
    { "AWP",               "awp",    "awp" },
    { "SSG 08",            "ssg08",  "ssg08" },
    { "G3SG1 / SCAR-20",   "g3sg1",  "scar20" },
    { "Galil AR / FAMAS",  "galilar","famas" },
    { "SG 553 / AUG",      "sg556",  "aug" },
    { "MAC-10 / MP9",      "mac10",  "mp9" },
    { "MP7",               "mp7",    "mp7" },
    { "UMP-45",            "ump45",  "ump45" },
    { "P90",               "p90",    "p90" },
    { "Nova",              "nova",   "nova" },
    { "XM1014",            "xm1014", "xm1014" },
    { "Sawed-Off / MAG-7", "sawedoff","mag7" },
}
local BB_SECONDARY = {
    { "None" },
    { "Desert Eagle",      "deagle",   "deagle" },
    { "R8 Revolver",       "revolver", "revolver" },
    { "P250",              "p250",     "p250" },
    { "Tec-9 / Five-SeveN","tec9",     "fiveseven" },
    { "CZ75-Auto",         "cz75a",    "cz75a" },
    { "Dual Berettas",     "elite",    "elite" },
}
local function bb_names(list)
    local t = {}
    for i, v in ipairs(list) do t[i] = v[1] end
    return t
end
local function bb_lookup(list, name)
    for _, v in ipairs(list) do if v[1] == name then return v end end
    return nil
end
local function bb_selected(sel, name)
    if type(sel) ~= "table" then return false end
    for _, v in ipairs(sel) do if v == name then return true end end
    return false
end

local bb_enable    = bb:feature(ic("cart-shopping") .. "Buybot", false)
local bb_primary   = bb:combo("Primary weapon", bb_names(BB_PRIMARY))
local bb_secondary = bb:combo("Secondary weapon", bb_names(BB_SECONDARY))
local bb_gear      = bb:selectable("Equipment", "Kevlar + Helmet", "Defuse Kit", "HE Grenade", "Flashbang", "Smoke", "Molotov / Incendiary", "Zeus x27")

local function bb_buy()
    if not bb_enable:get() then return end
    local lp = entity.get_local_player()
    if not lp then return end
    local team = lp.m_iTeamNum
    local col
    if team == 2 then col = 2 elseif team == 3 then col = 3 else return end -- 2 = T, 3 = CT

    local cmds = {}
    local p = bb_lookup(BB_PRIMARY, bb_primary:get())
    if p and p[col] then cmds[#cmds + 1] = "buy " .. p[col] end
    local s = bb_lookup(BB_SECONDARY, bb_secondary:get())
    if s and s[col] then cmds[#cmds + 1] = "buy " .. s[col] end

    local gear = bb_gear:get()
    if bb_selected(gear, "Kevlar + Helmet") then cmds[#cmds + 1] = "buy vesthelm" end
    if col == 3 and bb_selected(gear, "Defuse Kit") then cmds[#cmds + 1] = "buy defuser" end
    if bb_selected(gear, "HE Grenade") then cmds[#cmds + 1] = "buy hegrenade" end
    if bb_selected(gear, "Flashbang") then cmds[#cmds + 1] = "buy flashbang" end
    if bb_selected(gear, "Smoke") then cmds[#cmds + 1] = "buy smokegrenade" end
    if bb_selected(gear, "Molotov / Incendiary") then cmds[#cmds + 1] = (col == 3) and "buy incgrenade" or "buy molotov" end
    if bb_selected(gear, "Zeus x27") then cmds[#cmds + 1] = "buy taser" end

    for _, c in ipairs(cmds) do utils.console_exec(c) end
end

pcall(function()
    events.round_start:set(function()
        if not bb_enable:get() then return end
        utils.execute_after(0.3, bb_buy)
    end)
end)

-- Aspect Ratio
local ar_enable = bb:feature(ic("expand") .. "Aspect Ratio", false)
local ar_value  = bb:slider("Ratio x100 (133=4:3, 160=16:10, 178=16:9)", 50, 250, 133)
local ar_last = nil
events.render:set(function()
    local want = ar_enable:get() and (ar_value:get() / 100) or 0
    if want ~= ar_last then
        ar_last = want
        pcall(function() cvar.r_aspectratio:float(want) end)
    end
end)
events.level_init:set(function() ar_last = nil end)
events.shutdown:set(function()
    pcall(function() cvar.r_aspectratio:float(0) end)
end)

-- Fast Ladder
local fl_enable = bb:feature(ic("up-down") .. "Fast Ladder", false)
events.createmove:set(function(cmd)
    if not fl_enable:get() then return end
    local lp = entity.get_local_player()
    if not lp or not lp:is_alive() then return end
    local mt = 0
    pcall(function() mt = lp.m_MoveType end)
    if mt ~= 9 then return end -- 9 = MOVETYPE_LADDER

    local va = cmd.view_angles
    if not va then return end
    if cmd.forwardmove > 0 then
        if va.x < 45 then
            va.x = 89
            cmd.in_moveright, cmd.in_moveleft = true, false
            cmd.in_forward, cmd.in_back = false, true
            if cmd.sidemove == 0 then va.y = va.y + 90 end
            if cmd.sidemove < 0 then va.y = va.y + 150 end
            if cmd.sidemove > 0 then va.y = va.y + 30 end
        end
    elseif cmd.forwardmove < 0 then
        va.x = 89
        cmd.in_moveleft, cmd.in_moveright = true, false
        cmd.in_forward, cmd.in_back = true, false
        if cmd.sidemove == 0 then va.y = va.y + 90 end
        if cmd.sidemove > 0 then va.y = va.y + 150 end
        if cmd.sidemove < 0 then va.y = va.y + 30 end
    end
    if va.y > 180 then va.y = va.y - 360 elseif va.y < -180 then va.y = va.y + 360 end
    pcall(function() cmd.view_angles = va end)
end)

-- Clantag
local misc_clantag = sec("Additions")
local clantag_enabled = misc_clantag:feature(ic("tag") .. "Clantag", false)
local clantag_frames = {
    "", "s", "sp", "spa", "spar", "spark", "sparkl", "sparkle",
    "sparkle", "sparkle", "sparkl", "spark", "spar", "spa", "sp", "s", "", "", ""
}
local clantag_last = nil
events.net_update_end:set(function()
    if not clantag_enabled:get() then
        if clantag_last and clantag_last ~= "" then
            common.set_clan_tag("")
            clantag_last = ""
        end
        return
    end
    local idx = math.floor(globals.tickcount / 12) % #clantag_frames + 1
    local tag = clantag_frames[idx]
    if tag ~= clantag_last then
        common.set_clan_tag(tag)
        clantag_last = tag
    end
end)

-- defuse indicator (moved here from the old combined render)
events.render:set(function()
    if defuse_enable:get() and defuse_indicator:get() and defuse_status ~= "" then
        local sc = render.screen_size()
        render.text(1, vector(sc.x / 2, sc.y * 0.72), defuse_status_color, "c", defuse_status)
    end
end)

events.shutdown:set(function()
    if clantag_last and clantag_last ~= "" then
        common.set_clan_tag("")
        clantag_last = ""
    end
end)
end

-- =========================================================
-- HIT LOGS (redesign)
-- =========================================================
do
local misc_hits = sec("Additions")
local hitlogs_enabled    = misc_hits:feature(ic("crosshairs") .. "Hit Logs", false)
local hitlogs_output     = misc_hits:selectable("Output", "Console", "Screen")
local hitlogs_color      = misc_hits:color_picker("Hit color", color(170, 120, 255))
local hitlogs_miss_color = misc_hits:color_picker("Miss color", color(255, 90, 110))
local hitlogs_time       = misc_hits:slider("Duration (s)", 2, 10, 5)
local hitlogs_max        = misc_hits:slider("Max logs", 3, 10, 6)
local hitlogs_ypos       = misc_hits:slider("Y position %", 10, 90, 65)

local hitgroup_names = {
    [0] = "generic", "head", "chest", "stomach", "left arm", "right arm",
    "left leg", "right leg", "neck", "generic", "gear"
}

local hl_entries = {}
local hl_font = render.load_font("Verdana", 13, "a") or 1
local hl_last = 0
local HL_H, HL_GAP, HL_PAD = 26, 6, 12

local function hl_has(name)
    local sel = hitlogs_output:get()
    if type(sel) ~= "table" then return false end
    for _, v in ipairs(sel) do if v == name then return true end end
    return false
end

-- works with both 0..255 and 0..1 color components
local function hl_rgb(c)
    local r, g, b = c.r or 255, c.g or 255, c.b or 255
    if math.max(r, g, b) <= 1 then r, g, b = r * 255, g * 255, b * 255 end
    return math.floor(r + 0.5), math.floor(g + 0.5), math.floor(b + 0.5)
end

local function hl_clamp(v, a, b) return math.max(a, math.min(b, v)) end
local function hl_lerp(a, b, t) return a + (b - a) * t end

local HL_WHITE = { 235, 235, 245 }
local HL_GRAY  = { 140, 145, 165 }

events.aim_ack:set(function(shot)
    if not hitlogs_enabled:get() then return end

    local hit = shot.state == nil
    local name = "unknown"
    if shot.target then
        local ok, n = pcall(function() return shot.target:get_name() end)
        if ok and n then name = n end
    end
    if #name > 16 then name = name:sub(1, 15) .. "..." end

    local hitgroup = hit and shot.hitgroup or shot.wanted_hitgroup or 0
    local hg  = hitgroup_names[hitgroup] or "unknown"
    local dmg = shot.damage or 0
    local hc  = shot.hitchance and math.floor(shot.hitchance + 0.5) or 0
    local bt  = shot.backtrack or 0

    local cr, cg, cb = hl_rgb(hit and hitlogs_color:get() or hitlogs_miss_color:get())
    local acc = { cr, cg, cb }

    local segs
    if hit then
        segs = {
            { "Hit ", acc }, { name, HL_WHITE }, { " in the ", HL_GRAY }, { hg, acc },
            { " for ", HL_GRAY }, { tostring(dmg), HL_WHITE },
            { string.format("   hc %d%% | bt %d", hc, bt), HL_GRAY },
        }
    else
        segs = {
            { "Missed ", acc }, { name, HL_WHITE }, { " in the ", HL_GRAY }, { hg, acc },
            { " due to ", HL_GRAY }, { tostring(shot.state), acc },
            { string.format("   hc %d%% | bt %d", hc, bt), HL_GRAY },
        }
    end

    if hl_has("Console") then
        local hex = string.format("\a%02x%02x%02x", cr, cg, cb)
        local plain = {}
        for i = 1, #segs do plain[i] = segs[i][1] end
        print_raw(hex .. "[Sparkle] \aDEFAULT" .. table.concat(plain))
    end

    if hl_has("Screen") then
        hl_entries[#hl_entries + 1] = { segs = segs, acc = acc, time = globals.realtime }
        while #hl_entries > hitlogs_max:get() do table.remove(hl_entries, 1) end
    end
end)

events.render:set(function()
    if not hitlogs_enabled:get() or not hl_has("Screen") then
        if #hl_entries > 0 then hl_entries = {} end
        return
    end
    if #hl_entries == 0 then return end

    local now = globals.realtime
    local dt = hl_clamp(now - hl_last, 0, 0.1)
    hl_last = now
    local duration = hitlogs_time:get()

    for i = #hl_entries, 1, -1 do
        if now - hl_entries[i].time > duration then table.remove(hl_entries, i) end
    end

    local sc = render.screen_size()
    local cx = sc.x * 0.5
    local base_y = sc.y * (hitlogs_ypos:get() / 100)

    for i, e in ipairs(hl_entries) do
        -- width is measured once
        if not e.w then
            local tw = 0
            for _, s in ipairs(e.segs) do
                local m = render.measure_text(hl_font, "", s[1])
                s.w = m.x
                s.h = m.y
                tw = tw + m.x
            end
            e.tw = tw
            e.th = e.segs[1].h or 14
            e.w = tw + HL_PAD * 2 + 4
        end

        local age = now - e.time
        local t_in = hl_clamp(age / 0.3, 0, 1)
        local appear = 1 - (1 - t_in) ^ 3                    -- ease-out
        local fade = hl_clamp((duration - age) / 0.4, 0, 1)
        local a = appear * fade
        local function A(v) return math.floor(v * a) end

        local target_y = base_y + (i - 1) * (HL_H + HL_GAP)
        if not e.y then e.y = target_y end
        e.y = hl_lerp(e.y, target_y, hl_clamp(dt * 14, 0, 1))

        local x = math.floor(cx - e.w / 2)
        local y = math.floor(e.y + (1 - appear) * 12)
        local w = e.w
        local ac = e.acc

        -- glow
        pcall(function()
            render.shadow(vector(x, y), vector(x + w, y + HL_H), color(ac[1], ac[2], ac[3], A(70)), 22, 0, 6)
        end)
        -- background
        render.rect(vector(x, y), vector(x + w, y + HL_H), color(12, 13, 20, A(225)), 6)
        pcall(function()
            render.rect_outline(vector(x, y), vector(x + w, y + HL_H), color(255, 255, 255, A(14)), 1, 6)
        end)
        -- accent bar on the left
        render.rect(vector(x + 4, y + 5), vector(x + 7, y + HL_H - 5), color(ac[1], ac[2], ac[3], A(255)), 2)
        -- remaining-time line
        local left = hl_clamp(1 - age / duration, 0, 1)
        if left > 0.01 then
            render.rect(vector(x + 10, y + HL_H - 3), vector(x + 10 + (w - 20) * left, y + HL_H - 2),
                color(ac[1], ac[2], ac[3], A(170)), 1)
        end

        -- text by segments
        local tx = x + HL_PAD + 2
        local ty = y + (HL_H - 3 - e.th) / 2 + 1
        for _, s in ipairs(e.segs) do
            local c = s[2]
            render.text(hl_font, vector(tx, ty), color(c[1], c[2], c[3], A(255)), "", s[1])
            tx = tx + s.w
        end
    end
end)

end

local exploits_tab = sec("Exploits")
exploits_tab:label("Exploit options go here.")

-- DISCORD RPC (Sparkle Lua) — fixed (no os)
-- Application ID: 1561097343023976448
-- =========================================================
do
local ffi_rpc = require("ffi")
local bit_rpc = require("bit")

-- application IDs per profile (swap the IDs here if you want them the other way round)
local RPC_PROFILES = {
    Sparkle     = "1560345200037986328",
    Persistence = "1561097343023976448",
}
-- "tence" in purple (same accent as menu)
local RPC_NAMES = {
    "Sparkle",
    "Persis\aC8A2FFFFtence",
}

local rpc_group   = sec("Misc")
local rpc_enable  = rpc_group:feature(ic("discord") .. "Discord RPC", true)
-- profile choice lives in the gear popup (falls back to the normal list if create() is missing)
local rpc_cfg = nil
pcall(function() rpc_cfg = rpc_enable:create() end)
local rpc_host = rpc_cfg or rpc_group
local rpc_profile = rpc_host:combo("Profile", RPC_NAMES)
if rpc_cfg then cfg_reg("misc/rpc profile", rpc_profile) end

local function rpc_client_id()
    local v = rpc_profile:get()
    if type(v) == "number" then v = RPC_NAMES[v] end
    v = tostring(v or "")
    -- strip NL colour codes from combo label
    v = v:gsub("\a%x%x%x%x%x%x%x%x", ""):gsub("\aDEFAULT", "")
    v = v:gsub("%s+", "")
    if v:lower():find("persis") then return RPC_PROFILES.Persistence end
    if v:lower():find("sparkle") then return RPC_PROFILES.Sparkle end
    return RPC_PROFILES[v] or RPC_PROFILES.Sparkle
end
local rpc_debug   = { get = function() return false end }
-- Dynamic activity: menu -> in_menu | match -> map + K/D
local function rpc_json_esc(s)
    s = tostring(s or "")
    s = s:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', ' '):gsub('\r', '')
    return s
end

local function rpc_get_map()
    -- 1) common.get_map_data
    local ok, md = pcall(function() return common.get_map_data() end)
    if ok and md then
        if type(md) == "table" then
            local n = md.name or md.shortname or md.map_name or md.level_name
            if n and tostring(n) ~= "" then return tostring(n) end
        elseif type(md) == "string" and md ~= "" then
            return md
        end
    end
    -- 2) globals
    pcall(function()
        if globals.mapname and globals.mapname ~= "" then
            md = globals.mapname
        end
    end)
    if type(md) == "string" and md ~= "" then return md end
    -- 3) panorama
    local ok2, name = pcall(function()
        return panorama.loadstring([[
            try {
                if (GameStateAPI && GameStateAPI.IsConnectedToServer && GameStateAPI.IsConnectedToServer()) {
                    var m = GameStateAPI.GetMapName && GameStateAPI.GetMapName();
                    if (m) return m;
                }
            } catch (e) {}
            return "";
        ]])()
    end)
    if ok2 and name and name ~= "" then return tostring(name) end
    return nil
end

local function rpc_is_connected()
    local ok, v = pcall(function()
        return panorama.loadstring([[
            try { return !!(GameStateAPI && GameStateAPI.IsConnectedToServer && GameStateAPI.IsConnectedToServer()); }
            catch (e) { return false; }
        ]])()
    end)
    if ok and v then return true end
    -- fallback: local player exists and not in pure menu
    local lp = entity.get_local_player()
    return lp ~= nil
end

-- Track K/D ourselves (player_resource often returns 0 in NL)
local rpc_kills, rpc_deaths = 0, 0
local rpc_kd_map = nil

local function rpc_kd_reset()
    rpc_kills, rpc_deaths = 0, 0
end

events.player_death:set(function(e)
    local me = entity.get_local_player()
    if not me then return end
    local atk = entity.get(e.attacker, true)
    local vic = entity.get(e.userid, true)
    if atk and atk == me and vic ~= me then
        rpc_kills = rpc_kills + 1
    end
    if vic and vic == me then
        rpc_deaths = rpc_deaths + 1
    end
end)

-- reset when map changes / new game
events.level_init:set(function()
    rpc_kd_reset()
    rpc_kd_map = nil
end)
pcall(function()
    events.round_prestart:set(function() end) -- keep match totals
end)

local function rpc_get_kd()
    -- also try resource once in case events missed
    local k, d = rpc_kills, rpc_deaths
    pcall(function()
        local lp = entity.get_local_player()
        if not lp then return end
        local idx = lp:get_index()
        local pr = entity.get_player_resource()
        if not pr or not idx then return end
        local rk, rd = 0, 0
        pcall(function()
            if pr.m_iKills then rk = tonumber(pr.m_iKills[idx]) or tonumber(pr.m_iKills[idx - 1]) or 0 end
            if pr.m_iDeaths then rd = tonumber(pr.m_iDeaths[idx]) or tonumber(pr.m_iDeaths[idx - 1]) or 0 end
        end)
        pcall(function()
            if (rk == 0 and rd == 0) and entity.get_prop then
                rk = tonumber(entity.get_prop(pr, "m_iKills", idx)) or 0
                rd = tonumber(entity.get_prop(pr, "m_iDeaths", idx)) or 0
            end
        end)
        -- prefer higher values (resource is authority if non-zero)
        if rk > k then k = rk end
        if rd > d then d = rd end
        rpc_kills, rpc_deaths = k, d
    end)
    return k, d
end

local function rpc_details_get()
    if not rpc_is_connected() then
        return "in_menu"
    end
    local map = rpc_get_map()
    if map and map ~= "" then
        local lower = map:lower()
        if lower:find("menu") or lower:find("background") then
            return "in_menu"
        end
        -- strip path: maps/de_mirage.bsp -> de_mirage
        map = tostring(map)
        map = map:gsub("\\", "/")
        map = map:gsub("^maps/", ""):gsub("^/maps/", "")
        map = map:gsub("%.bsp$", "")
        -- last path segment only
        map = map:match("([^/]+)$") or map
        return map
    end
    return "in_game"
end

local function rpc_state_get()
    if not rpc_is_connected() then
        return ""  -- omit in SET_ACTIVITY
    end
    local map = rpc_get_map()
    if map then
        local lower = map:lower()
        if lower:find("menu") or lower:find("background") then
            return ""
        end
    end
    local k, d = rpc_get_kd()
    return string.format("K/D: %d/%d", k, d)
end

local rpc_details = { get = rpc_details_get }
local rpc_state   = { get = rpc_state_get }

local function unix_time()
    local ok, t = pcall(function()
        return math.floor(panorama.loadstring("return Date.now()/1000")() + 0.5)
    end)
    if ok and type(t) == "number" then return t end
    return math.floor(globals.realtime + 1700000000)
end

ffi_rpc.cdef[[
    typedef void* HANDLE;
    typedef unsigned long DWORD;
    typedef int BOOL;

    HANDLE CreateFileA(
        const char* lpFileName,
        DWORD dwDesiredAccess,
        DWORD dwShareMode,
        void* lpSecurityAttributes,
        DWORD dwCreationDisposition,
        DWORD dwFlagsAndAttributes,
        HANDLE hTemplateFile
    );

    BOOL WriteFile(
        HANDLE hFile,
        const char* lpBuffer,
        DWORD nNumberOfBytesToWrite,
        DWORD* lpNumberOfBytesWritten,
        void* lpOverlapped
    );

    BOOL ReadFile(
        HANDLE hFile,
        char* lpBuffer,
        DWORD nNumberOfBytesToRead,
        DWORD* lpNumberOfBytesRead,
        void* lpOverlapped
    );

    BOOL PeekNamedPipe(
        HANDLE hNamedPipe,
        void* lpBuffer,
        DWORD nBufferSize,
        DWORD* lpBytesRead,
        DWORD* lpTotalBytesAvail,
        DWORD* lpBytesLeftThisMessage
    );

    BOOL CloseHandle(HANDLE hObject);
    DWORD GetLastError();
]]

local GENERIC_READ  = 0x80000000
local GENERIC_WRITE = 0x40000000
local OPEN_EXISTING = 3
local INVALID_HANDLE = ffi_rpc.cast("HANDLE", -1)

local OPCODE_HANDSHAKE = 0
local OPCODE_FRAME     = 1
local OPCODE_CLOSE     = 2
local OPCODE_PING      = 3
local OPCODE_PONG      = 4

local function log(msg)
    if rpc_debug:get() then
        print("[Sparkle RPC] " .. tostring(msg))
    end
end

local function pack_u32(n)
    n = n % 4294967296
    return string.char(
        n % 256,
        math.floor(n / 256) % 256,
        math.floor(n / 65536) % 256,
        math.floor(n / 16777216) % 256
    )
end

local function unpack_u32(s)
    if not s or #s < 4 then return 0 end
    local b1, b2, b3, b4 = s:byte(1, 4)
    return b1 + b2 * 256 + b3 * 65536 + b4 * 16777216
end

local rpc = {
    handle = nil,
    ready = false,
    connected = false,
    last_update = 0,
    last_try = 0,
    client = nil,
    start_time = unix_time()
}

local function rpc_write(opcode, str)
    if not rpc.handle then return false end
    local packet = pack_u32(opcode) .. pack_u32(#str) .. str
    local buf = ffi_rpc.new("char[?]", #packet)
    ffi_rpc.copy(buf, packet)
    local written = ffi_rpc.new("DWORD[1]")
    local ok = ffi_rpc.C.WriteFile(rpc.handle, buf, #packet, written, nil)
    if ok == 0 then
        log("WriteFile failed, err=" .. tostring(ffi_rpc.C.GetLastError()))
        return false
    end
    return true
end

local function rpc_try_read()
    if not rpc.handle then return end
    local avail = ffi_rpc.new("DWORD[1]")
    local ok = ffi_rpc.C.PeekNamedPipe(rpc.handle, nil, 0, nil, avail, nil)
    if ok == 0 or avail[0] < 8 then return end

    local header_buf = ffi_rpc.new("char[8]")
    local read = ffi_rpc.new("DWORD[1]")
    if ffi_rpc.C.ReadFile(rpc.handle, header_buf, 8, read, nil) == 0 then return end

    local header = ffi_rpc.string(header_buf, 8)
    local opcode = unpack_u32(header:sub(1, 4))
    local len = unpack_u32(header:sub(5, 8))
    if len <= 0 or len > 65536 then return end

    local body_buf = ffi_rpc.new("char[?]", len)
    local total = 0
    local body_read = ffi_rpc.new("DWORD[1]")
    while total < len do
        if ffi_rpc.C.ReadFile(rpc.handle, body_buf + total, len - total, body_read, nil) == 0 then
            break
        end
        total = total + body_read[0]
        if body_read[0] == 0 then break end
    end

    local body = ffi_rpc.string(body_buf, total)
    log("recv op=" .. opcode .. " len=" .. total .. " body=" .. body:sub(1, 120))

    if opcode == OPCODE_FRAME then
        if body:find('"evt":"READY"') or body:find('"evt": "READY"') then
            rpc.ready = true
            log("READY received")
        end
    elseif opcode == OPCODE_PING then
        rpc_write(OPCODE_PONG, "")
    elseif opcode == OPCODE_CLOSE then
        log("Discord closed pipe")
        rpc.handle = nil
        rpc.ready = false
        rpc.connected = false
    end
end

local function rpc_open()
    if rpc.handle then return true end
    local cid = rpc_client_id()
    for i = 0, 9 do
        local path = "\\\\.\\pipe\\discord-ipc-" .. i
        local h = ffi_rpc.C.CreateFileA(
            path,
            bit_rpc.bor(GENERIC_READ, GENERIC_WRITE),
            0, nil,
            OPEN_EXISTING,
            0, nil
        )
        if h ~= INVALID_HANDLE then
            rpc.handle = h
            rpc.connected = true
            rpc.ready = false
            rpc.client = cid
            local payload = string.format('{"v":1,"client_id":"%s"}', cid)
            if rpc_write(OPCODE_HANDSHAKE, payload) then
                log("handshake sent on pipe " .. i)
                return true
            else
                ffi_rpc.C.CloseHandle(h)
                rpc.handle = nil
                rpc.connected = false
            end
        end
    end
    log("no discord pipe found (is Discord running?)")
    return false
end

local function rpc_set_activity(details, state)
    if not rpc.handle then return end
    details = rpc_json_esc(details or "in_menu")
    state = state and tostring(state) or ""
    state = rpc_json_esc(state)

    local activity
    if state == "" then
        activity = string.format(
            '{"details":"%s","timestamps":{"start":%d},"instance":true}',
            details, rpc.start_time
        )
    else
        activity = string.format(
            '{"details":"%s","state":"%s","timestamps":{"start":%d},"instance":true}',
            details, state, rpc.start_time
        )
    end

    local encoded = string.format(
        '{"cmd":"SET_ACTIVITY","args":{"pid":%d,"activity":%s},"nonce":"%s"}',
        4,
        activity,
        tostring(math.random(100000, 999999))
    )
    local ok = rpc_write(OPCODE_FRAME, encoded)
    if ok then
        log("SET_ACTIVITY ok: " .. details .. " | " .. (state ~= "" and state or "-"))
    else
        log("SET_ACTIVITY write failed")
    end
    return ok
end

local function rpc_close()
    if rpc.handle then
        pcall(function()
            local payload = string.format('{"v":1,"client_id":"%s"}', rpc.client or rpc_client_id())
            rpc_write(OPCODE_CLOSE, payload)
            ffi_rpc.C.CloseHandle(rpc.handle)
        end)
        rpc.handle = nil
        rpc.ready = false
        rpc.connected = false
        rpc.client = nil
        log("closed")
    end
end

events.render:set(function()
    if not rpc_enable:get() then
        if rpc.connected then rpc_close() end
        return
    end
    -- profile changed -> reconnect with the other application id
    if rpc.connected and rpc.client ~= rpc_client_id() then
        rpc_close()
        rpc.last_try = 0
        rpc.last_update = 0
    end
    local now = globals.realtime
    if not rpc.connected then
        if now - rpc.last_try < 5 then return end
        rpc.last_try = now
        pcall(rpc_open)
        return
    end
    pcall(rpc_try_read)
    -- if pipe died, reconnect
    if not rpc.handle then
        rpc.connected = false
        rpc.ready = false
        return
    end
    if rpc.ready and (now - rpc.last_update > 4 or rpc.last_update == 0) then
        rpc.last_update = now
        local d = rpc_details:get()
        local s = rpc_state:get()
        pcall(rpc_set_activity, d, s)
    end
end)

events.shutdown:set(function()
    rpc_close()
end)

print("[Sparkle] Discord RPC loaded")
end
-- =========================================================
-- TRASH TALK
-- =========================================================
do
local tt_group = sec("Additions")
local tt_master = tt_group:feature(ic("comment") .. "Trash Talk", true)
-- only the on/off switch is in the menu; everything else is fixed
local tt_kill  = { get = function() return true end }
local tt_rev   = { get = function() return true end }
local tt_death = { get = function() return true end }
local tt_team  = { get = function() return true end }
local tt_dcnt  = { get = function() return 3 end }
local tt_tdel  = { get = function() return 15 end }
local tt_dgap  = { get = function() return 35 end }

local kill_phrases = {
    "адин свинья",
    "ю систер денсинг naked на мне",
    "кусай хуй",
    "у тебя батя пидор грифин",
    "твою мамку костылем доводили до оргазма",
    "тебя бабка пинает пока ты сосешь с рупастой",
    "понял тебя хуесос терпи мой член",
    "1 big pig",
    "ддоснул тя членом",
    "1 тераризавал твою пизду",
    "ракал твою мамку на днях",
    "111 полил мачой твой комп ночью, он нахуй сгорел",
    "поздравляю хуйло, у тебя семья вымрет.",
    "1 пропиши ff",
    "1 не пытайся играть, вскрой брюхо родне",
    "мой килл равен - твоему фф",
}

local death_phrases = {
    "лагало нахуй я не должен был умереть",
    "128 тик бы не умер 64 тик мусор для нищих",
    "рандом хитбокс баг движка",
    "сервер скипнул тик когда я уклонялся",
    "visually killed я жив технически",
    "это desync мой клиент показывал другую позицию",
    "интерполяция убила меня а не %s",
    "пинг скакнул до 300 именно сейчас совпадение нет",
    "subtick мусор valve деграданты",
    "%s точно читер такого не бывает без вальхака",
    "у %s вальхак 100 процентов репорт уже летит",
    "%s аимбот очевидный смотрите на угол поворота",
    "%s это случайность а не скилл не радуйся",
    "%s позор себе и семье за читы",
    "эта игра кусок дерьма valve нахуй",
    "баг клиента у меня показывало что я за углом",
    "я тебя пожалел иначе бы 1 тап был",
    "%s твоя мать сосала чтобы тебе повезло",
    "%s отец продал душу дьяволу чтобы ты выстрелил",
    "%s сестра легла под разработчика чтобы у тебя был вальхак",
    "у %s вся семья в морге от моих пуль",
    "%s надеюсь тебе прострелят глазное яблоко",
    "я дал тебе фраг %s чтобы твоя мать порадовалась",
    "%s если бы я хотел ты бы уже сдох от позора",
    "это не скилл %s, это наследственная дегенерация",
    "%s у тебя в генах крысиный трупный яд",
    "у %s в черепе вместо мозга гниль",
    "%s надеюсь у тебя отсохнут руки и глаза вытекут",
    "я бы убил тебя %s, но мне жаль потратить пулю",
    "%s твоё существование — ошибка природы",
    "%s тебя должны были смыть в унитаз при рождении",
    "у %s в роду все кончали в психушке",
    "%s твоя семья сдохнет в муках когда я вернусь",
    "это последний фраг в твоей жалкой жизни %s",
    "я позволил %s чтобы у него была хоть одна радость",
    "%s твой скам аккаунт скоро в бан, как и твоя семья",
}

local kq, kp = {}, {0}
local dq, dp = {}, {0}

local function tt_shuffle(t)
    for i = #t, 2, -1 do
        local j = utils.random_int(1, i)
        t[i], t[j] = t[j], t[i]
    end
end

local function tt_reset()
    kq = {}
    for _, v in ipairs(kill_phrases) do table.insert(kq, v) end
    tt_shuffle(kq)
    kp[1] = 0
    dq = {}
    for _, v in ipairs(death_phrases) do table.insert(dq, v) end
    tt_shuffle(dq)
    dp[1] = 0
end

local function tt_next(q, pos)
    pos[1] = pos[1] + 1
    if pos[1] > #q then
        tt_shuffle(q)
        pos[1] = 1
    end
    return q[pos[1]]
end

local function tt_fmt(tmpl, name)
    name = (tostring(name or ""):gsub('[;"\\]', ""))
    if string.find(tmpl, "%%s") then
        return tmpl:format(name)
    end
    return tmpl
end

local function tt_sayboth(msg)
    msg = (tostring(msg or ""):gsub('[;"]', ""))
    utils.console_exec("say " .. msg)
    if tt_team:get() then
        utils.execute_after(tt_tdel:get() * 0.1, function()
            utils.console_exec("say_team " .. msg)
        end)
    end
end

local tt_killer = nil
local tt_lkill = 0
local tt_ldeath = 0
local TT_KCD = 3
local TT_DCD = 6

events.player_hurt:set(function(e)
    if not tt_master:get() then return end
    local me = entity.get_local_player()
    if not me then return end
    local atk = entity.get(e.attacker, true)
    local vic = entity.get(e.userid, true)

    if me == atk then
        if not vic then return end
        if e.health <= 0 then
            if tt_rev:get() and tt_killer and vic == tt_killer then
                if globals.realtime - tt_lkill >= TT_KCD then
                    tt_lkill = globals.realtime
                    tt_killer = nil
                    tt_sayboth(tt_next(kq, kp))
                end
            elseif tt_kill:get() and globals.realtime - tt_lkill >= TT_KCD then
                tt_lkill = globals.realtime
                tt_sayboth(tt_next(kq, kp))
            end
        end
    end

    if me == vic and e.health <= 0 then
        tt_killer = atk
        if tt_death:get() and globals.realtime - tt_ldeath >= TT_DCD then
            tt_ldeath = globals.realtime
            local aname = atk and (atk:get_name() or "noname") or "noname"
            local cnt = tt_dcnt:get()
            for i = 1, cnt do
                local delay = (i - 1) * (tt_dgap:get() * 0.1)
                local msg = tt_fmt(tt_next(dq, dp), aname)
                if delay == 0 then
                    tt_sayboth(msg)
                else
                    utils.execute_after(delay, function()
                        tt_sayboth(msg)
                    end)
                end
            end
        end
    end
end)

events.shutdown:set(function() end)

tt_reset()
end

-- =========================================================


-- =========================================================
-- WATERMARK + KEYBINDS (own do-block: no extra top-level locals)
-- =========================================================
do
    local function clamp(v, a, b) return math.max(a, math.min(b, v)) end
    local function lerp(a, b, t) return a + (b - a) * t end
    local function rgb(c)
        local r, g, b = c.r or 255, c.g or 255, c.b or 255
        if math.max(r, g, b) <= 1 then r, g, b = r * 255, g * 255, b * 255 end
        return { math.floor(r + 0.5), math.floor(g + 0.5), math.floor(b + 0.5) }
    end
    local function lighter(c, d)
        return { math.min(255, c[1] + d), math.min(255, c[2] + d), math.min(255, c[3] + d) }
    end

    local font = render.load_font("Verdana", 13, "a") or 1
    local function tsize(s)
        local m = render.measure_text(font, "", s)
        return m.x, m.y
    end

    local function glow(x1, y1, x2, y2, c, a, size, round)
        pcall(function()
            render.shadow(vector(x1, y1), vector(x2, y2), color(c[1], c[2], c[3], a), size, 0, round)
        end)
    end

    -- thin accent line (gradient if available, otherwise solid)
    local function accent_line(x1, y, x2, c, a)
        local l = lighter(c, 55)
        local ok = pcall(function()
            render.gradient(vector(x1, y), vector(x2, y + 2),
                color(c[1], c[2], c[3], a), color(l[1], l[2], l[3], a))
        end)
        if not ok then
            render.rect(vector(x1, y), vector(x2, y + 2), color(c[1], c[2], c[3], a), 0)
        end
    end

    local function mouse_pos()
        local m
        pcall(function() m = ui.get_mouse_position() end)
        if m and m.x then return m end
        pcall(function() m = common.get_mouse_position() end)
        if m and m.x then return m end
        return nil
    end

    local WHITE = { 235, 235, 245 }
    local GRAY  = { 140, 145, 165 }

    -- ================== WATERMARK ==================
    local wm_grp    = sec("Additions")
    local wm_enable = wm_grp:feature(ic("signature") .. "Watermark", true)
    -- settings live in the gear popup of the switch (falls back to the normal list if create() is missing)
    local wm_cfg = nil
    pcall(function() wm_cfg = wm_enable:create() end)
    local wm_host   = wm_cfg or wm_grp
    local function WR(k, el) if wm_cfg then cfg_reg("watermark/" .. k, el) end return el end
    local wm_color  = WR("color", wm_host:color_picker("Watermark color", color(170, 120, 255)))
    local wm_pos    = WR("position", wm_host:combo("Position", { "Top right", "Top left", "Bottom right", "Bottom left" }))
    local wm_user   = WR("user", wm_host:switch("Show username", true))
    local wm_fps    = WR("fps", wm_host:switch("Show FPS", true))
    local wm_ping   = WR("ping", wm_host:switch("Show ping", true))
    local wm_time   = WR("time", wm_host:switch("Show time", true))

    -- small pixel-art gear drawn before the brand (only exists while Watermark is on)
    local GEAR_PX = 2
    local GEAR = {
        "....#....",
        ".##.#.##.",
        ".#######.",
        "..##.##..",
        "###...###",
        "..##.##..",
        ".#######.",
        ".##.#.##.",
        "....#....",
    }
    local GEAR_W = #GEAR[1] * GEAR_PX
    local function draw_gear(x, y, col)
        for r = 1, #GEAR do
            local line = GEAR[r]
            local c = 1
            while c <= #line do
                if line:sub(c, c) == "#" then
                    local e = c
                    while e < #line and line:sub(e + 1, e + 1) == "#" do e = e + 1 end
                    render.rect(vector(x + (c - 1) * GEAR_PX, y + (r - 1) * GEAR_PX),
                        vector(x + e * GEAR_PX, y + r * GEAR_PX), col, 0)
                    c = e + 1
                else
                    c = c + 1
                end
            end
        end
    end

    local wm_name = "user"
    pcall(function() wm_name = tostring(common.get_username() or "user") end)
    local fps_s = 60

    local function get_ping()
        local p
        pcall(function()
            local nc = utils.net_channel()
            if nc then
                local v
                pcall(function() v = nc:get_latency(0) end)
                if not v then pcall(function() v = nc.latency[0] end) end
                if not v then pcall(function() v = nc.latency end) end
                if type(v) == "number" then p = (v < 5) and (v * 1000) or v end
            end
        end)
        if not p then
            pcall(function()
                local lp = entity.get_local_player()
                local pr = entity.get_player_resource()
                if lp and pr then p = tonumber(pr.m_iPing[lp:get_index()]) end
            end)
        end
        return p and math.floor(p + 0.5) or nil
    end

    local function get_clock()
        local ok, t = pcall(function() return common.get_system_time() end)
        if ok and type(t) == "table" and t.hours then
            return string.format("%02d:%02d", t.hours, t.minutes or 0)
        end
        return nil
    end

    local wm_w = 0
    events.render:set(function()
        if not wm_enable:get() then return end
        local now = globals.realtime
        local ft = globals.frametime or 0.01
        if ft > 0 then fps_s = lerp(fps_s, 1 / ft, 0.05) end

        local ac = rgb(wm_color:get())

        -- {text to draw, text used for width}
        local parts = {}
        if wm_user:get() then parts[#parts + 1] = { wm_name, wm_name } end
        if wm_fps:get() then
            parts[#parts + 1] = { string.format("%d fps", math.floor(fps_s + 0.5)), "000 fps" }
        end
        if wm_ping:get() then
            local p = get_ping()
            if p then parts[#parts + 1] = { string.format("%d ms", p), "000 ms" } end
        end
        if wm_time:get() then
            local c = get_clock()
            if c then parts[#parts + 1] = { c, "00:00" } end
        end

        local BRAND = "Sparkle"
        local bw = tsize(BRAND)
        local _, th = tsize("Ag")
        local PAD, H = 11, 26
        local total = PAD * 2 + GEAR_W + 7 + bw
        for _, p in ipairs(parts) do
            p.w = tsize(p[2])
            total = total + 17 + p.w
        end
        wm_w = (wm_w == 0) and total or lerp(wm_w, total, clamp((globals.frametime or 0.01) * 12, 0, 1))
        local w = math.floor(wm_w + 0.5)

        local sc = render.screen_size()
        local M = 15
        local pos = wm_pos:get()
        local x = (pos == "Top left" or pos == "Bottom left") and M or (sc.x - w - M)
        local y = (pos == "Bottom left" or pos == "Bottom right") and (sc.y - H - M) or M

        glow(x, y, x + w, y + H, ac, 55, 20, 7)
        render.rect(vector(x, y), vector(x + w, y + H), color(12, 13, 20, 225), 7)
        pcall(function()
            render.rect_outline(vector(x, y), vector(x + w, y + H), color(255, 255, 255, 14), 1, 7)
        end)
        accent_line(x + 6, y + 1, x + w - 6, ac, 255)

        local ty = y + (H - th) / 2 + 1

        -- gear icon
        draw_gear(x + PAD, y + (H - #GEAR * GEAR_PX) / 2, color(ac[1], ac[2], ac[3], 255))

        -- brand with purple shimmer
        local cx = x + PAD + GEAR_W + 7
        for i = 1, #BRAND do
            local ch = BRAND:sub(i, i)
            local t = (now * 0.25 + i * 0.12) % 1
            local k = t < 0.5 and t * 2 or 2 - t * 2
            local l = lighter(ac, 60)
            local r = math.floor(lerp(ac[1], l[1], k))
            local g = math.floor(lerp(ac[2], l[2], k))
            local b = math.floor(lerp(ac[3], l[3], k))
            render.text(font, vector(cx, ty), color(r, g, b, 255), "", ch)
            cx = cx + tsize(ch)
        end

        for _, p in ipairs(parts) do
            cx = cx + 8
            render.rect(vector(cx, y + 8), vector(cx + 1, y + H - 8), color(255, 255, 255, 40), 0)
            cx = cx + 9
            render.text(font, vector(cx, ty), color(WHITE[1], WHITE[2], WHITE[3], 255), "", p[1])
            cx = cx + p.w
        end
    end)

    -- ================== KEYBINDS ==================
    local kb_grp    = sec("Additions")
    local kb_enable = kb_grp:feature(ic("keyboard") .. "Keybinds", true)
    local kb_color  = kb_grp:color_picker("Keybinds color", color(170, 120, 255))
    kb_grp:label("Drag the window while the menu is open.")

    local kb = {
        x = 20, y = nil, w = 130, wa = 0, last = 0,
        drag = false, ox = 0, oy = 0, prev = false,
        anim = {}, order = {},
    }
    pcall(function()
        local s = db and db.sparkle_kbpos
        if type(s) == "string" then
            local a, b = s:match("(-?%d+),(-?%d+)")
            if a then kb.x, kb.y = tonumber(a), tonumber(b) end
        end
    end)

    local HDR, ROW, KPAD = 26, 19, 11

    events.render:set(function()
        if not kb_enable:get() then return end
        local now = globals.realtime
        local dt = clamp(now - kb.last, 0, 0.1)
        kb.last = now
        local sc = render.screen_size()
        if not kb.y then kb.y = math.floor(sc.y * 0.4) end
        local menu = menu_open()
        local ac = rgb(kb_color:get())

        -- collect active binds
        local active = {}
        local ok, binds = pcall(function() return ui.get_binds() end)
        if ok and type(binds) == "table" then
            for _, b in ipairs(binds) do
                if b.name and (b.active == nil or b.active) then
                    local val
                    if type(b.value) == "string" and b.value ~= "" then val = b.value
                    elseif type(b.mode) == "string" and b.mode ~= "" then val = b.mode
                    else val = "on" end
                    if val == "true" then val = "on" end
                    active[tostring(b.name)] = tostring(val)
                end
            end
        end

        -- animation bookkeeping
        for name, val in pairs(active) do
            local e = kb.anim[name]
            if not e then
                e = { a = 0 }
                kb.anim[name] = e
                kb.order[#kb.order + 1] = name
            end
            e.val = val
            e.target = 1
        end
        for name, e in pairs(kb.anim) do
            if not active[name] then e.target = 0 end
            e.a = lerp(e.a, e.target, clamp(dt * 12, 0, 1))
        end
        for i = #kb.order, 1, -1 do
            local e = kb.anim[kb.order[i]]
            if e and e.target == 0 and e.a < 0.02 then
                kb.anim[kb.order[i]] = nil
                table.remove(kb.order, i)
            end
        end

        -- window visibility
        local want = (#kb.order > 0 or menu) and 1 or 0
        kb.wa = lerp(kb.wa, want, clamp(dt * 10, 0, 1))
        if kb.wa < 0.02 then return end
        local function A(v) return math.floor(v * kb.wa) end

        -- width / height
        local hw = tsize("Keybinds")
        local want_w = hw + KPAD * 2 + 20
        for _, name in ipairs(kb.order) do
            local e = kb.anim[name]
            local nw = tsize(name)
            local vw = tsize("[" .. e.val .. "]")
            want_w = math.max(want_w, nw + vw + KPAD * 2 + 22)
        end
        kb.w = lerp(kb.w, want_w, clamp(dt * 12, 0, 1))
        local w = math.floor(kb.w + 0.5)
        local rows_h = 0
        for _, name in ipairs(kb.order) do rows_h = rows_h + ROW * kb.anim[name].a end
        local h = HDR + rows_h + (rows_h > 0.5 and 5 or 0)

        -- dragging (menu open only)
        local m = mouse_pos()
        local down = false
        pcall(function() down = common.is_button_down(0x01) end)
        if menu and m then
            if down and not kb.prev and m.x >= kb.x and m.x <= kb.x + w
                and m.y >= kb.y and m.y <= kb.y + HDR then
                kb.drag = true
                kb.ox, kb.oy = m.x - kb.x, m.y - kb.y
            end
            if kb.drag and down then
                kb.x = clamp(m.x - kb.ox, 0, sc.x - w)
                kb.y = clamp(m.y - kb.oy, 0, sc.y - HDR)
            end
        end
        if kb.drag and (not down or not menu) then
            kb.drag = false
            pcall(function()
                if db then db.sparkle_kbpos = string.format("%d,%d", kb.x, kb.y) end
            end)
        end
        kb.prev = down

        local x, y = math.floor(kb.x), math.floor(kb.y)

        glow(x, y, x + w, y + h, ac, A(55), 20, 7)
        render.rect(vector(x, y), vector(x + w, y + h), color(12, 13, 20, A(225)), 7)
        pcall(function()
            render.rect_outline(vector(x, y), vector(x + w, y + h), color(255, 255, 255, A(14)), 1, 7)
        end)
        accent_line(x + 6, y + 1, x + w - 6, ac, A(255))

        -- header
        local _, th = tsize("Ag")
        render.text(font, vector(x + KPAD, y + (HDR - th) / 2 + 1), color(ac[1], ac[2], ac[3], A(255)), "", "Keybinds")
        local cnt = tostring(#kb.order)
        local cw = tsize(cnt)
        render.text(font, vector(x + w - KPAD - cw, y + (HDR - th) / 2 + 1),
            color(GRAY[1], GRAY[2], GRAY[3], A(255)), "", cnt)
        if rows_h > 0.5 then
            render.rect(vector(x + KPAD, y + HDR - 1), vector(x + w - KPAD, y + HDR),
                color(255, 255, 255, A(18)), 0)
        end

        -- rows
        local cy = y + HDR + 2
        for _, name in ipairs(kb.order) do
            local e = kb.anim[name]
            local ra = kb.wa * e.a
            if ra > 0.02 then
                local ty = cy + (ROW * e.a - th) / 2
                render.text(font, vector(x + KPAD, ty),
                    color(WHITE[1], WHITE[2], WHITE[3], math.floor(255 * ra)), "", name)
                local vt = "[" .. e.val .. "]"
                local vw = tsize(vt)
                render.text(font, vector(x + w - KPAD - vw, ty),
                    color(ac[1], ac[2], ac[3], math.floor(255 * ra)), "", vt)
            end
            cy = cy + ROW * e.a
        end
    end)
end

common.add_notify("Sparkle", "Home / Anti Aim / Additions / Exploits / Misc")
print("[Sparkle] optimized layout loaded")


-- MODEL CHANGER (merged)
-- =========================================================
do
local agents = {
    -- CT
    { team = "CT", name = "ST6",              path = "models/player/custom_player/legacy/ctm_st6.mdl" },
    { team = "CT", name = "ST6 (A)",          path = "models/player/custom_player/legacy/ctm_st6_variantA.mdl" },
    { team = "CT", name = "ST6 (B)",          path = "models/player/custom_player/legacy/ctm_st6_variantB.mdl" },
    { team = "CT", name = "ST6 (C)",          path = "models/player/custom_player/legacy/ctm_st6_variantC.mdl" },
    { team = "CT", name = "ST6 (D)",          path = "models/player/custom_player/legacy/ctm_st6_variantD.mdl" },
    { team = "CT", name = "SEAL Soldier",     path = "models/player/custom_player/legacy/ctm_st6_variantE.mdl" },
    { team = "CT", name = "Buckshot SEAL",    path = "models/player/custom_player/legacy/ctm_st6_variantG.mdl" },
    { team = "CT", name = "Ricksaw SEAL",     path = "models/player/custom_player/legacy/ctm_st6_variantI.mdl" },
    { team = "CT", name = "FBI",              path = "models/player/custom_player/legacy/ctm_fbi.mdl" },
    { team = "CT", name = "FBI (A)",          path = "models/player/custom_player/legacy/ctm_fbi_variantA.mdl" },
    { team = "CT", name = "FBI (C)",          path = "models/player/custom_player/legacy/ctm_fbi_variantC.mdl" },
    { team = "CT", name = "FBI (D)",          path = "models/player/custom_player/legacy/ctm_fbi_variantD.mdl" },
    { team = "CT", name = "FBI (E)",          path = "models/player/custom_player/legacy/ctm_fbi_variantE.mdl" },
    { team = "CT", name = "Operator FBI",     path = "models/player/custom_player/legacy/ctm_fbi_variantF.mdl" },
    { team = "CT", name = "Delrow FBI",       path = "models/player/custom_player/legacy/ctm_fbi_variantG.mdl" },
    { team = "CT", name = "Syfers FBI",       path = "models/player/custom_player/legacy/ctm_fbi_variantH.mdl" },
    { team = "CT", name = "GIGN",             path = "models/player/custom_player/legacy/ctm_gign.mdl" },
    { team = "CT", name = "GIGN (A)",         path = "models/player/custom_player/legacy/ctm_gign_variantA.mdl" },
    { team = "CT", name = "GIGN (B)",         path = "models/player/custom_player/legacy/ctm_gign_variantB.mdl" },
    { team = "CT", name = "GIGN (C)",         path = "models/player/custom_player/legacy/ctm_gign_variantC.mdl" },
    { team = "CT", name = "GIGN (D)",         path = "models/player/custom_player/legacy/ctm_gign_variantD.mdl" },
    { team = "CT", name = "GSG9",             path = "models/player/custom_player/legacy/ctm_gsg9.mdl" },
    { team = "CT", name = "GSG9 (A)",         path = "models/player/custom_player/legacy/ctm_gsg9_variantA.mdl" },
    { team = "CT", name = "GSG9 (B)",         path = "models/player/custom_player/legacy/ctm_gsg9_variantB.mdl" },
    { team = "CT", name = "GSG9 (C)",         path = "models/player/custom_player/legacy/ctm_gsg9_variantC.mdl" },
    { team = "CT", name = "GSG9 (D)",         path = "models/player/custom_player/legacy/ctm_gsg9_variantD.mdl" },
    { team = "CT", name = "IDF",              path = "models/player/custom_player/legacy/ctm_idf.mdl" },
    { team = "CT", name = "IDF (B)",          path = "models/player/custom_player/legacy/ctm_idf_variantB.mdl" },
    { team = "CT", name = "IDF (C)",          path = "models/player/custom_player/legacy/ctm_idf_variantC.mdl" },
    { team = "CT", name = "IDF (D)",          path = "models/player/custom_player/legacy/ctm_idf_variantD.mdl" },
    { team = "CT", name = "IDF (E)",          path = "models/player/custom_player/legacy/ctm_idf_variantE.mdl" },
    { team = "CT", name = "IDF (F)",          path = "models/player/custom_player/legacy/ctm_idf_variantF.mdl" },
    { team = "CT", name = "SAS",              path = "models/player/custom_player/legacy/ctm_sas.mdl" },
    { team = "CT", name = "B Squadron SAS",   path = "models/player/custom_player/legacy/ctm_sas_variantF.mdl" },
    { team = "CT", name = "D Squadron NZSAS", path = "models/player/custom_player/legacy/ctm_sas_variantG.mdl" },
    { team = "CT", name = "SWAT",             path = "models/player/custom_player/legacy/ctm_swat.mdl" },
    { team = "CT", name = "SWAT (A)",         path = "models/player/custom_player/legacy/ctm_swat_variantA.mdl" },
    { team = "CT", name = "SWAT (B)",         path = "models/player/custom_player/legacy/ctm_swat_variantB.mdl" },
    { team = "CT", name = "SWAT (C)",         path = "models/player/custom_player/legacy/ctm_swat_variantC.mdl" },
    { team = "CT", name = "SWAT (D)",         path = "models/player/custom_player/legacy/ctm_swat_variantD.mdl" },
    { team = "CT", name = "Heavy CT",         path = "models/player/custom_player/legacy/ctm_heavy.mdl" },
    -- T
    { team = "T",  name = "Phoenix",          path = "models/player/custom_player/legacy/tm_phoenix.mdl" },
    { team = "T",  name = "Phoenix (A)",      path = "models/player/custom_player/legacy/tm_phoenix_variantA.mdl" },
    { team = "T",  name = "Phoenix (B)",      path = "models/player/custom_player/legacy/tm_phoenix_variantB.mdl" },
    { team = "T",  name = "Phoenix (C)",      path = "models/player/custom_player/legacy/tm_phoenix_variantC.mdl" },
    { team = "T",  name = "Phoenix (D)",      path = "models/player/custom_player/legacy/tm_phoenix_variantD.mdl" },
    { team = "T",  name = "Heavy Phoenix",    path = "models/player/custom_player/legacy/tm_phoenix_heavy.mdl" },
    { team = "T",  name = "Elite Crew (A)",   path = "models/player/custom_player/legacy/tm_leet_variantA.mdl" },
    { team = "T",  name = "Elite Crew (B)",   path = "models/player/custom_player/legacy/tm_leet_variantB.mdl" },
    { team = "T",  name = "Elite Crew (C)",   path = "models/player/custom_player/legacy/tm_leet_variantC.mdl" },
    { team = "T",  name = "Elite Crew (D)",   path = "models/player/custom_player/legacy/tm_leet_variantD.mdl" },
    { team = "T",  name = "Elite Crew (E)",   path = "models/player/custom_player/legacy/tm_leet_variantE.mdl" },
    { team = "T",  name = "Elite Crew (K)",   path = "models/player/custom_player/legacy/tm_leet_variantK.mdl" },
    { team = "T",  name = "Anarchist",        path = "models/player/custom_player/legacy/tm_anarchist.mdl" },
    { team = "T",  name = "Anarchist (A)",    path = "models/player/custom_player/legacy/tm_anarchist_variantA.mdl" },
    { team = "T",  name = "Anarchist (B)",    path = "models/player/custom_player/legacy/tm_anarchist_variantB.mdl" },
    { team = "T",  name = "Anarchist (C)",    path = "models/player/custom_player/legacy/tm_anarchist_variantC.mdl" },
    { team = "T",  name = "Anarchist (D)",    path = "models/player/custom_player/legacy/tm_anarchist_variantD.mdl" },
    { team = "T",  name = "Balkan (A)",       path = "models/player/custom_player/legacy/tm_balkan_variantA.mdl" },
    { team = "T",  name = "Balkan (B)",       path = "models/player/custom_player/legacy/tm_balkan_variantB.mdl" },
    { team = "T",  name = "Balkan (C)",       path = "models/player/custom_player/legacy/tm_balkan_variantC.mdl" },
    { team = "T",  name = "Balkan (D)",       path = "models/player/custom_player/legacy/tm_balkan_variantD.mdl" },
    { team = "T",  name = "Balkan (E)",       path = "models/player/custom_player/legacy/tm_balkan_variantE.mdl" },
    { team = "T",  name = "Pirate",           path = "models/player/custom_player/legacy/tm_pirate.mdl" },
    { team = "T",  name = "Pirate (A)",       path = "models/player/custom_player/legacy/tm_pirate_variantA.mdl" },
    { team = "T",  name = "Pirate (B)",       path = "models/player/custom_player/legacy/tm_pirate_variantB.mdl" },
    { team = "T",  name = "Pirate (C)",       path = "models/player/custom_player/legacy/tm_pirate_variantC.mdl" },
    { team = "T",  name = "Pirate (D)",       path = "models/player/custom_player/legacy/tm_pirate_variantD.mdl" },
    { team = "T",  name = "Professional",     path = "models/player/custom_player/legacy/tm_professional.mdl" },
    { team = "T",  name = "Professional (1)", path = "models/player/custom_player/legacy/tm_professional_var1.mdl" },
    { team = "T",  name = "Professional (2)", path = "models/player/custom_player/legacy/tm_professional_var2.mdl" },
    { team = "T",  name = "Professional (3)", path = "models/player/custom_player/legacy/tm_professional_var3.mdl" },
    { team = "T",  name = "Professional (4)", path = "models/player/custom_player/legacy/tm_professional_var4.mdl" },
    { team = "T",  name = "Separatist",       path = "models/player/custom_player/legacy/tm_separatist.mdl" },
    { team = "T",  name = "Separatist (A)",   path = "models/player/custom_player/legacy/tm_separatist_variantA.mdl" },
    { team = "T",  name = "Separatist (B)",   path = "models/player/custom_player/legacy/tm_separatist_variantB.mdl" },
    { team = "T",  name = "Separatist (C)",   path = "models/player/custom_player/legacy/tm_separatist_variantC.mdl" },
    { team = "T",  name = "Separatist (D)",   path = "models/player/custom_player/legacy/tm_separatist_variantD.mdl" },
    { team = "T",  name = "Jumpsuit (A)",     path = "models/player/custom_player/legacy/tm_jumpsuit_variantA.mdl" },
    { team = "T",  name = "Jumpsuit (B)",     path = "models/player/custom_player/legacy/tm_jumpsuit_variantB.mdl" },
    { team = "T",  name = "Jumpsuit (C)",     path = "models/player/custom_player/legacy/tm_jumpsuit_variantC.mdl" },
}

local function names_for(team)
    local t = { "— Default —" }
    for _, a in ipairs(agents) do
        if a.team == team then
            t[#t + 1] = a.name
        end
    end
    return t
end

local function path_for(team, name)
    if not name or name == "— Default —" then
        return nil
    end
    for _, a in ipairs(agents) do
        if a.team == team and a.name == name then
            return a.path
        end
    end
    return nil
end

-- modelinfo helpers (pcall everything — old patterns may fail)
local find_or_load, get_model_index
do
    local ok_st, get_st = pcall(utils.get_vfunc, "engine.dll", "VEngineClientStringTable001", 3, "void*(__thiscall*)(void*, const char*)")
    local ok_mi, find_mdl = pcall(utils.get_vfunc, "engine.dll", "VModelInfoClient004", 39, "void*(__thiscall*)(void*, const char*)")
    local ok_idx, get_idx = pcall(utils.get_vfunc, "engine.dll", "VModelInfoClient004", 2, "int(__thiscall*)(void*, const char*)")
    local ok_add, add_str = pcall(function()
        return utils.get_vfunc(8, "int*(__thiscall*)(void*, bool, const char*, int, const void*)")
    end)

    find_or_load = function(path)
        if not path then return false end
        pcall(function()
            if ok_mi and find_mdl then find_mdl(path) end
            if ok_st and get_st and ok_add and add_str then
                local tbl = get_st("modelprecache")
                if tbl then
                    local p = ffi.cast("void***", tbl)
                    add_str(p, false, path, -1, nil)
                end
            end
        end)
        return true
    end

    get_model_index = function(path)
        if not ok_idx or not get_idx then return -1 end
        local ok, idx = pcall(get_idx, path)
        if ok and idx then return idx end
        return -1
    end
end

local function apply_model(path)
    if not path then return end
    local lp = entity.get_local_player()
    if not lp or not lp:is_alive() then return end
    find_or_load(path)
    local idx = get_model_index(path)
    if idx and idx ~= -1 then
        pcall(function()
            if lp.m_nModelIndex ~= idx then
                lp.m_nModelIndex = idx
            end
        end)
    end
end

-- ===== UI under Sparkle =====
local tab = sec("Misc")
local enable = tab:feature(ic("person") .. "Enable Model Changer", true)
local ct_list = tab:combo("CT Agent", names_for("CT"))
local t_list = tab:combo("T Agent", names_for("T"))
local apply_btn = tab:button("Apply + full update", function()
    pcall(function() common.force_full_update() end)
    common.add_notify("Sparkle", "Models refreshed")
end, true)
tab:label("Only local model (client-side). Built-in agents only.")

events.net_update_end:set(function()
    if not enable:get() then return end
    local lp = entity.get_local_player()
    if not lp or not lp:is_alive() then return end

    local team = lp.m_iTeamNum
    local path
    if team == 3 then
        path = path_for("CT", ct_list:get())
    elseif team == 2 then
        path = path_for("T", t_list:get())
    end
    if path then
        apply_model(path)
    end
end)

print("[Sparkle] Model Changer — presets T/CT")
end

end
-- =====================================================================================
print("[Sparkle] Loader accepted. Loading script...")
SPARKLE_MAIN()

строки 1-2651
