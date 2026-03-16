script_name('Helper Lovli for ARZ')
script_author('idea - bossov, realization - slardar')
script_version('2.1.0')
script_properties('work-in-pause')
local imgui = require 'mimgui'
local samp_check, samp = pcall(require, 'samp.events')
local effil_check, effil = pcall(require, 'effil')
local monet_check, monet = pcall(require, 'MoonMonet')
local ffi = require('ffi')
local encoding = require('encoding')
local inicfg = require 'inicfg'
local render = require('lib.render')
local vkeys = require('vkeys')

encoding.default = 'CP1251'
u8 = encoding.UTF8

if not imgui or not samp_check or not effil_check or not monet_check then
    function main()
        if not isSampfuncsLoaded() or not isSampLoaded() then return end
        while not isSampAvailable() do wait(100) end
        local libs = {
            ['Mimgui'] = imgui ~= nil,
            ['SAMP.Lua'] = samp_check,
            ['Effil'] = effil_check,
            ['MoonMonet'] = monet_check
        }
        local libs_no_found = {}
        for k, v in pairs(libs) do
            if not v then
                sampAddChatMessage('« Helper Lovli » {FFFFFF}У Вас отсутствует библиотека {7172ee}' .. k .. '{FFFFFF}. Без неё скрипт {7172ee}не будет {FFFFFF}работать!', 0x7172ee)
                table.insert(libs_no_found, k)
            end
        end
        sampShowDialog(18364, '{7172ee}Helper Lovli', string.format('{FFFFFF}В Вашей сборке {7172ee}нету необходимых библиотек{FFFFFF} для работы скрипта.\nБез них он {7172ee}не будет{FFFFFF} работать!\n\nБиблиотеки, которые Вам нужны:\n{FFFFFF}- {7172ee}%s\n\n{FFFFFF}Все библиотеки можно скачать в теме на BlastHack: {7172ee}https://www.blast.hk/threads/190033\n{FFFFFF}В этой же теме Вы {7172ee}найдете инструкцию {FFFFFF}для их установки.', table.concat(libs_no_found, '\n{FFFFFF}- {7172ee}')), 'Принять', '', 0)
        thisScript():unload()
    end
    return
end

local function file_exists(path)
    local f = io.open(path, 'r')
    if f then
        f:close()
        return true
    end
    return false
end

local CONFIG_PATH = getWorkingDirectory() .. '/config/helper.ini'

local CMD_LIST = {
    "/piss",
    "/domkrat",
    "/adrenaline",
    "/enterc",
    "/fogdist",
    "/buybiz",
    "/fweather 1",
    "/ftime 12",
    "/style"
}

local CMD_NAMES = {
    u8"Пис",
    u8"Домкрат",
    u8"Адреналин",
    u8"Вход в машину",
    u8"Туман",
    u8"Купить бизнес",
    u8"Погода 1",
    u8"Время 12",
    u8"Стиль"
}

local KEY_LIST = {
    "1","2","3","4","5","6","7","8","9",
    "F1","F2","F3","F4","F5","F6","F7","F8","F9","F10","F11","F12",
    "Q","W","E","R","T","Y","U","I","O","P",
    "A","S","D","F","G","H","J","K","L",
    "Z","X","C","V","B","N","M"
}

local VK_MAP = {
    ["1"] = 0x31, ["2"] = 0x32, ["3"] = 0x33, ["4"] = 0x34, ["5"] = 0x35,
    ["6"] = 0x36, ["7"] = 0x37, ["8"] = 0x38, ["9"] = 0x39,
    ["F1"] = 0x70, ["F2"] = 0x71, ["F3"] = 0x72, ["F4"] = 0x73,
    ["F5"] = 0x74, ["F6"] = 0x75, ["F7"] = 0x76, ["F8"] = 0x77,
    ["F9"] = 0x78, ["F10"] = 0x79, ["F11"] = 0x7A, ["F12"] = 0x7B,
    ["Q"] = 0x51, ["W"] = 0x57, ["E"] = 0x45, ["R"] = 0x52,
    ["T"] = 0x54, ["Y"] = 0x59, ["U"] = 0x55, ["I"] = 0x49,
    ["O"] = 0x4F, ["P"] = 0x50, ["A"] = 0x41, ["S"] = 0x53,
    ["D"] = 0x44, ["F"] = 0x46, ["G"] = 0x47, ["H"] = 0x48,
    ["J"] = 0x4A, ["K"] = 0x4B, ["L"] = 0x4C, ["Z"] = 0x5A,
    ["X"] = 0x58, ["C"] = 0x43, ["V"] = 0x56, ["B"] = 0x42,
    ["N"] = 0x4E, ["M"] = 0x4D
}

local VK_TO_KEY = {}
for key, code in pairs(VK_MAP) do
    VK_TO_KEY[code] = key
end

local DEFAULT_CONFIG = {
    script = {
        scriptColor = "f57c00",
        activationCommand = "helper"
    },
    cef = {
        timeout = 5,
        houseEnabled = true,
        businessEnabled = true
    },
    binders = {},
    trening = {
        enabled = false,
        key = "N",
        command = 1
    },
    marker = {
        defaultMode = 1,
        enabled = false
    },
    timer = {
        enabled = false
    }
}

-- Загружаем конфиг с защитой
local function loadConfig()
    -- Если файл не существует, возвращаем дефолтный
    if not file_exists(CONFIG_PATH) then
        print("Helper Lovli: Файл конфига не найден, используется дефолтный")
        return DEFAULT_CONFIG
    end
    
    -- Пытаемся загрузить конфиг
    local success, loaded = pcall(inicfg.load, DEFAULT_CONFIG, CONFIG_PATH)
    if success and loaded then
        -- Проверяем, не пустой ли конфиг
        if next(loaded) == nil then
            print("Helper Lovli: Конфиг пуст, используется дефолтный")
            return DEFAULT_CONFIG
        end
        print("Helper Lovli: Конфиг успешно загружен")
        return loaded
    else
        print("Helper Lovli: Ошибка загрузки конфига, используется дефолтный")
        return DEFAULT_CONFIG
    end
end

local ini = loadConfig()

-- Парсим биндеры из INI
local function parseBinders()
    local binders = {}
    if ini and ini.binders then
        for _, line in pairs(ini.binders) do
            local idx, cmd, enabled = line:match("(%d+)|([^|]*)|([^|]*)")
            if idx then
                table.insert(binders, {
                    key = KEY_LIST[tonumber(idx) + 1] or "1",
                    cmd = cmd or "/piss",
                    enabled = enabled == "true"
                })
            end
        end
    end
    return binders
end

-- Настройки runtime с защитой от nil
local settings = {
    scriptColor = tonumber('0x' .. (ini.script and ini.script.scriptColor or "f57c00")) or 0xf57c00,
    activationCommand = (ini.script and ini.script.activationCommand) or "helper",
    cef = {
        timeout = ((ini.cef and ini.cef.timeout) or 5) * 1000,
        houseEnabled = (ini.cef and ini.cef.houseEnabled ~= nil) and ini.cef.houseEnabled or true,
        businessEnabled = (ini.cef and ini.cef.businessEnabled ~= nil) and ini.cef.businessEnabled or true
    },
    binders = parseBinders(),
    trening = {
        enabled = (ini.trening and ini.trening.enabled ~= nil) and ini.trening.enabled or false,
        key = (ini.trening and ini.trening.key) or "N",
        command = (ini.trening and ini.trening.command) or 1
    },
    marker = {
        defaultMode = (ini.marker and ini.marker.defaultMode) or 1,
        enabled = (ini.marker and ini.marker.enabled ~= nil) and ini.marker.enabled or false
    },
    timer = {
        enabled = (ini.timer and ini.timer.enabled ~= nil) and ini.timer.enabled or false
    }
}

local window = imgui.new.bool(false)
imgui.Process = false
local menu = imgui.new.int(1)
local fonts = {}

local scriptColor = imgui.new.float[3](
    bit.rshift(settings.scriptColor, 16) / 255,
    bit.band(bit.rshift(settings.scriptColor, 8), 0xFF) / 255,
    bit.band(settings.scriptColor, 0xFF) / 255
)

local activation_command = imgui.new.char[128](settings.activationCommand)

local cef_timeout = imgui.new.int(settings.cef.timeout / 1000)
local cef_houseEnabled = imgui.new.bool(settings.cef.houseEnabled)
local cef_businessEnabled = imgui.new.bool(settings.cef.businessEnabled)

local binders = settings.binders
local editing_binder_index = -1
local new_key_idx = imgui.new.int(0)
local new_cmd_idx = imgui.new.int(0)

local waiting_for_key = false
local waiting_for_key_type = nil
local waiting_for_key_index = nil

local show_cmd_popup = imgui.new.bool(false)
local selecting_cmd_type = nil
local selecting_cmd_index = nil
local temp_cmd_selection = 1

local trening_enabled = imgui.new.bool(settings.trening.enabled)
local trening_key = imgui.new.char[128](settings.trening.key)
local trening_command = imgui.new.int(settings.trening.command)

local t = 0
local captcha = ''
local captime = nil
local captchaTable = {}
local trening_active = false
local captcha_dialog_open = false

local MODE_TRACER = 1
local MODE_MARKER = 2
local currentMode = nil
local marker_defaultMode = imgui.new.int(settings.marker.defaultMode)
local marker_enabled = imgui.new.bool(settings.marker.enabled)

local tracer = {
    isSet = false,
    targetX = 0,
    targetY = 0,
    targetZ = 0
}

local marker = {
    isSet = false,
    x = 0,
    y = 0,
    z = 0,
    interior = 0
}

local render_font = nil
local drawDist = 50.0

local timer_enabled = imgui.new.bool(settings.timer.enabled)
local fogToggle = false
local ttime = nil

local palette = monet.buildColors(settings.scriptColor, 1.5, true)

function convertDecimalToRGBA(u32, alpha)
    local a = bit.band(bit.rshift(u32, 24), 0xFF) / 0xFF
    local r = bit.band(bit.rshift(u32, 16), 0xFF) / 0xFF
    local g = bit.band(bit.rshift(u32, 8), 0xFF) / 0xFF
    local b = bit.band(u32, 0xFF) / 0xFF
    return imgui.ImVec4(r, g, b, a * (alpha or 1.0))
end

function theme(color, chroma_multiplier, accurate_shades)
    imgui.SwitchContext()
    palette = monet.buildColors(color, chroma_multiplier, accurate_shades)
    local style = imgui.GetStyle()
    local colors = style.Colors
    local flags = imgui.Col

    style.WindowPadding = imgui.ImVec2(15, 15)
    style.FramePadding = imgui.ImVec2(8, 6)
    style.ItemSpacing = imgui.ImVec2(10, 8)
    style.ItemInnerSpacing = imgui.ImVec2(6, 6)
    style.TouchExtraPadding = imgui.ImVec2(0, 0)

    style.IndentSpacing = 20
    style.ScrollbarSize = 12.5
    style.GrabMinSize = 10

    style.WindowBorderSize = 0
    style.ChildBorderSize = 1
    style.PopupBorderSize = 1
    style.FrameBorderSize = 0
    style.TabBorderSize = 0

    style.WindowRounding = 3
    style.ChildRounding = 3
    style.PopupRounding = 3
    style.FrameRounding = 3
    style.ScrollbarRounding = 1.5
    style.GrabRounding = 3
    style.TabRounding = 3

    style.WindowTitleAlign = imgui.ImVec2(0.50, 0.50)

    colors[flags.Text] = convertDecimalToRGBA(palette.neutral1.color_50)
    colors[flags.TextDisabled] = convertDecimalToRGBA(palette.neutral1.color_400)
    colors[flags.WindowBg] = convertDecimalToRGBA(palette.accent2.color_900)
    colors[flags.ChildBg] = convertDecimalToRGBA(palette.accent2.color_900)
    colors[flags.PopupBg] = convertDecimalToRGBA(palette.accent2.color_900)
    colors[flags.Border] = convertDecimalToRGBA(palette.accent2.color_300)
    colors[flags.BorderShadow] = imgui.ImVec4(0, 0, 0, 0)
    colors[flags.FrameBg] = convertDecimalToRGBA(palette.accent1.color_600)
    colors[flags.FrameBgHovered] = convertDecimalToRGBA(palette.accent1.color_500)
    colors[flags.FrameBgActive] = convertDecimalToRGBA(palette.accent1.color_400)
    colors[flags.TitleBgActive] = convertDecimalToRGBA(palette.accent1.color_600)
    colors[flags.ScrollbarBg] = convertDecimalToRGBA(palette.accent2.color_800)
    colors[flags.ScrollbarGrab] = convertDecimalToRGBA(palette.accent1.color_600)
    colors[flags.ScrollbarGrabHovered] = convertDecimalToRGBA(palette.accent1.color_500)
    colors[flags.ScrollbarGrabActive] = convertDecimalToRGBA(palette.accent1.color_400)
    colors[flags.CheckMark] = convertDecimalToRGBA(palette.neutral1.color_50)
    colors[flags.SliderGrab] = convertDecimalToRGBA(palette.accent2.color_400)
    colors[flags.SliderGrabActive] = convertDecimalToRGBA(palette.accent2.color_300)
    colors[flags.Button] = convertDecimalToRGBA(palette.accent2.color_700)
    colors[flags.ButtonHovered] = convertDecimalToRGBA(palette.accent1.color_600)
    colors[flags.ButtonActive] = convertDecimalToRGBA(palette.accent1.color_500)
    colors[flags.Header] = convertDecimalToRGBA(palette.accent1.color_800)
    colors[flags.HeaderHovered] = convertDecimalToRGBA(palette.accent1.color_700)
    colors[flags.HeaderActive] = convertDecimalToRGBA(palette.accent1.color_600)
    colors[flags.Separator] = convertDecimalToRGBA(palette.accent2.color_200)
    colors[flags.SeparatorHovered] = convertDecimalToRGBA(palette.accent2.color_100)
    colors[flags.SeparatorActive] = convertDecimalToRGBA(palette.accent2.color_50)
    colors[flags.ResizeGrip] = convertDecimalToRGBA(palette.accent2.color_900)
    colors[flags.ResizeGripHovered] = convertDecimalToRGBA(palette.accent2.color_800)
    colors[flags.ResizeGripActive] = convertDecimalToRGBA(palette.accent2.color_700)
    colors[flags.Tab] = convertDecimalToRGBA(palette.accent1.color_700)
    colors[flags.TabHovered] = convertDecimalToRGBA(palette.accent1.color_600)
    colors[flags.TabActive] = convertDecimalToRGBA(palette.accent1.color_500)
    colors[flags.PlotLines] = convertDecimalToRGBA(palette.accent3.color_300)
    colors[flags.PlotLinesHovered] = convertDecimalToRGBA(palette.accent3.color_50)
    colors[flags.PlotHistogram] = convertDecimalToRGBA(palette.accent3.color_300)
    colors[flags.PlotHistogramHovered] = convertDecimalToRGBA(palette.accent3.color_50)
    colors[flags.DragDropTarget] = convertDecimalToRGBA(palette.accent1.color_100)
    colors[flags.ModalWindowDimBg] = imgui.ImVec4(0.00, 0.00, 0.00, 0.95)
end

function getTheme()
    local r = math.floor(scriptColor[0] * 255 + 0.5)
    local g = math.floor(scriptColor[1] * 255 + 0.5)
    local b = math.floor(scriptColor[2] * 255 + 0.5)
    local color = tonumber(string.format("0x%02x%02x%02x", r, g, b))
    theme(color, 1.5, true)
end

function imgui.ColorsButton(text, size, colors)
    imgui.PushStyleColor(imgui.Col.Button, imgui.ColorConvertHexToFloat4(colors[1]))
    imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ColorConvertHexToFloat4(colors[2]))
    imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ColorConvertHexToFloat4(colors[3]))
    local result = imgui.Button(text, size)
    imgui.PopStyleColor(3)
    return result
end

function imgui.ColorConvertHexToFloat4(hex)
    local s = hex:sub(5, 6) .. hex:sub(3, 4) .. hex:sub(1, 2)
    return imgui.ColorConvertU32ToFloat4(tonumber('0xFF' .. s))
end

function imgui.BeginColorChild(...)
    imgui.PushStyleColor(imgui.Col.ChildBg, convertDecimalToRGBA(palette.accent2.color_800))
    imgui.BeginChild(...)
end

function imgui.EndColorChild()
    imgui.EndChild()
    imgui.PopStyleColor(1)
end

function imgui.FText(text, font)
    assert(text)
    local render_text = function(stext)
        local text, colors, m = {}, {}, 1
        while stext:find('{%u%l-%u-%l-}') do
            local n, k = stext:find('{.-}')
            local color = imgui.GetStyle().Colors[imgui.Col[stext:sub(n + 1, k - 1)]]
            if color then
                text[#text], text[#text + 1] = stext:sub(m, n - 1), stext:sub(k + 1, #stext)
                colors[#colors + 1] = color
                m = n
            end
            stext = stext:sub(1, n - 1) .. stext:sub(k + 1, #stext)
        end
        if text[0] then
            for i = 0, #text do
                imgui.TextColored(colors[i] or colors[1], text[i])
                imgui.SameLine(nil, 0)
            end
            imgui.NewLine()
        else imgui.Text(stext) end
    end
    imgui.PushFont(fonts[font])
    render_text(text)
    imgui.PopFont()
end

function imgui.CenterText(text, font)
    imgui.PushFont(fonts[font or 20])
    local windowWidth = imgui.GetWindowWidth()
    local textWidth = imgui.CalcTextSize(text).x
    imgui.SetCursorPosX((windowWidth - textWidth) / 2)
    imgui.Text(text)
    imgui.PopFont()
end

function imgui.ActiveButton(name, ...)
    imgui.PushStyleColor(imgui.Col.Button, convertDecimalToRGBA(palette.accent1.color_500))
    imgui.PushStyleColor(imgui.Col.ButtonHovered, convertDecimalToRGBA(palette.accent1.color_400))
    imgui.PushStyleColor(imgui.Col.ButtonActive, convertDecimalToRGBA(palette.accent1.color_300))
    local result = imgui.Button(name, ...)
    imgui.PopStyleColor(3)
    return result
end

function sms(text)
    if text == nil then return end
    if type(text) ~= 'string' then text = tostring(text) end
    local color_chat = string.format("%06X", settings.scriptColor % 0x1000000)
    text = text:gsub('{mc}', '{' .. color_chat .. '}'):gsub('{%-1}', '{FFFFFF}')
    sampAddChatMessage('« Helper Lovli » {FFFFFF}' .. text, tonumber('0x' .. color_chat))
end

function saveConfig()
    -- Убеждаемся, что ini существует
    if not ini then
        ini = DEFAULT_CONFIG
    end
    
    local r = math.floor(scriptColor[0] * 255 + 0.5)
    local g = math.floor(scriptColor[1] * 255 + 0.5)
    local b = math.floor(scriptColor[2] * 255 + 0.5)
    
    -- Убеждаемся, что все секции существуют
    ini.script = ini.script or {}
    ini.cef = ini.cef or {}
    ini.trening = ini.trening or {}
    ini.marker = ini.marker or {}
    ini.timer = ini.timer or {}
    ini.binders = ini.binders or {}
    
    ini.script.scriptColor = string.format("%02x%02x%02x", r, g, b)
    ini.script.activationCommand = ffi.string(activation_command)
    settings.scriptColor = tonumber(string.format("0x%02x%02x%02x", r, g, b))
    settings.activationCommand = ffi.string(activation_command)

    ini.cef.timeout = cef_timeout[0]
    ini.cef.houseEnabled = cef_houseEnabled[0]
    ini.cef.businessEnabled = cef_businessEnabled[0]
    settings.cef.timeout = cef_timeout[0] * 1000
    settings.cef.houseEnabled = cef_houseEnabled[0]
    settings.cef.businessEnabled = cef_businessEnabled[0]

    ini.trening.enabled = trening_enabled[0]
    ini.trening.key = ffi.string(trening_key)
    ini.trening.command = trening_command[0]
    settings.trening.enabled = trening_enabled[0]
    settings.trening.key = ffi.string(trening_key)
    settings.trening.command = trening_command[0]

    ini.marker.defaultMode = marker_defaultMode[0]
    ini.marker.enabled = marker_enabled[0]
    settings.marker.defaultMode = marker_defaultMode[0]
    settings.marker.enabled = marker_enabled[0]

    ini.timer.enabled = timer_enabled[0]
    settings.timer.enabled = timer_enabled[0]

    ini.binders = {}
    for i, binder in ipairs(binders) do
        local key_idx = 0
        for idx, key in ipairs(KEY_LIST) do
            if key == binder.key then
                key_idx = idx - 1
                break
            end
        end
        ini.binders[tostring(i)] = key_idx .. "|" .. binder.cmd .. "|" .. tostring(binder.enabled)
    end

    local success, err = pcall(inicfg.save, ini, CONFIG_PATH)
    if not success then
        print("Helper Lovli: Ошибка сохранения конфига - " .. tostring(err))
    else
        print("Helper Lovli: Конфиг сохранен")
    end
end

function getVKey(key)
    if not key then return nil end
    return VK_MAP[key:upper()]
end

function executeBinderCommand(cmd)
    if cmd == '/fogdist' then
        fogToggle = not fogToggle
        sampProcessChatInput(fogToggle and '/fogdist 35' or '/fogdist 500')
    else
        sampProcessChatInput(cmd)
    end
end

function checkBinders()
    for _, binder in ipairs(binders) do
        if binder.enabled and binder.key and binder.key ~= '' and binder.cmd then
            local vkey = getVKey(binder.key)
            if vkey and wasKeyPressed(vkey) and not sampIsChatInputActive() and not sampIsDialogActive() and not sampIsCursorActive() then
                executeBinderCommand(binder.cmd)
            end
        end
    end

    if trening_enabled[0] then
        local key = ffi.string(trening_key)
        if key and key ~= '' then
            local vkey = getVKey(key)
            if vkey and wasKeyPressed(vkey) and not sampIsChatInputActive() and not sampIsDialogActive() and not sampIsCursorActive() and not trening_active and not captcha_dialog_open then
                showCaptcha()
            end
        end
    end
end

function removeTextdraws()
    if t > 0 then
        trening_active = false
        captcha_dialog_open = false
        for i = 1, t do
            if sampTextdrawIsExists(i) then
                sampTextdrawDelete(i)
            end
        end
        t = 0
        captcha = ''
        captime = nil
        captchaTable = {}
    end
end

function GenerateTextDraw(id, PosX, PosY)
    if id == 0 then
        t = t + 1
        sampTextdrawCreate(t, "LD_SPAC:white", PosX - 5, PosY + 7)
        sampTextdrawSetLetterSizeAndColor(t, 0, 3, 0x80808080)
        sampTextdrawSetBoxColorAndSize(t, 1, 0xFF759DA3, PosX+5, 0.000000)
    elseif id == 1 then
        for i = 0, 1 do
            t = t + 1
            if i == 0 then
                offsetX = 3
                offsetBX = 15
            else
                offsetX = -3
                offsetBX = -15
            end
            sampTextdrawCreate(t, "LD_SPAC:white", PosX - offsetX, PosY)
            sampTextdrawSetLetterSizeAndColor(t, 0, 4.5, 0x80808080)
            sampTextdrawSetBoxColorAndSize(t, 1, 0xFF759DA3, PosX-offsetBX, 0.000000)
        end
    elseif id == 2 then
        for i = 0, 1 do
            t = t + 1
            if i == 0 then
                offsetX = -8
                offsetY = 7
                offsetBX = 15
            else
                offsetX = 6
                offsetY = 25
                offsetBX = -15
            end
            sampTextdrawCreate(t, "LD_SPAC:white", PosX - offsetX, PosY + offsetY)
            sampTextdrawSetLetterSizeAndColor(t, 0, 0.8, 0x80808080)
            sampTextdrawSetBoxColorAndSize(t, 1, 0xFF759DA3, PosX-offsetBX, 0.000000)
        end
    elseif id == 3 then
        for i = 0, 1 do
            t = t + 1
            if i == 0 then
                size = 0.8
                offsetY = 7
            else
                size = 1
                offsetY = 25
            end
            sampTextdrawCreate(t, "LD_SPAC:white", PosX+10, PosY+offsetY)
            sampTextdrawSetLetterSizeAndColor(t, 0, 1, 0x80808080)
            sampTextdrawSetBoxColorAndSize(t, 1, 0xFF759DA3, PosX-15, 0.000000)
        end
    elseif id == 4 then
        for i = 0, 1 do
            t = t + 1
            if i == 0 then
                size = 1.8
                offsetX = -10
                offsetY = 0
                offsetBX = 10
            else
                size = 2
                offsetX = -10
                offsetY = 25
                offsetBX = 15
            end
            sampTextdrawCreate(t, "LD_SPAC:white", PosX - offsetX, PosY + offsetY)
            sampTextdrawSetLetterSizeAndColor(t, 0, size, 0x80808080)
            sampTextdrawSetBoxColorAndSize(t, 1, 0xFF759DA3, PosX-offsetBX, 0.000000)
        end
    elseif id == 5 then
        for i = 0, 1 do
            t = t + 1
            if i == 0 then
                size = 0.8
                offsetX = 8
                offsetY = 7
                offsetBX = -15
            else
                size = 1
                offsetX = -10
                offsetY = 25
                offsetBX = 15
            end
            sampTextdrawCreate(t, "LD_SPAC:white", PosX - offsetX, PosY + offsetY)
            sampTextdrawSetLetterSizeAndColor(t, 0, size, 0x80808080)
            sampTextdrawSetBoxColorAndSize(t, 1, 0xFF759DA3, PosX-offsetBX, 0.000000)
        end
    elseif id == 6 then
        for i = 0, 1 do
            t = t + 1
            if i == 0 then
                size = 0.8
                offsetX = 7.5
                offsetY = 7
                offsetBX = -15
            else
                size = 1
                offsetX = -10
                offsetY = 25
                offsetBX = 10
            end
            sampTextdrawCreate(t, "LD_SPAC:white", PosX - offsetX, PosY + offsetY)
            sampTextdrawSetLetterSizeAndColor(t, 0, size, 0x80808080)
            sampTextdrawSetBoxColorAndSize(t, 1, 0xFF759DA3, PosX-offsetBX, 0.000000)
        end
    elseif id == 7 then
        t = t + 1
        sampTextdrawCreate(t, "LD_SPAC:white", PosX - 13, PosY + 7)
        sampTextdrawSetLetterSizeAndColor(t, 0, 3.75, 0x80808080)
        sampTextdrawSetBoxColorAndSize(t, 1, 0xFF759DA3, PosX+5, 0.000000)
    elseif id == 8 then
        for i = 0, 1 do
            t = t + 1
            if i == 0 then
                size = 0.8
                offsetY = 7
            else
                size = 1
                offsetY = 25
            end
            sampTextdrawCreate(t, "LD_SPAC:white", PosX+10, PosY+offsetY)
            sampTextdrawSetLetterSizeAndColor(t, 0, 1, 0x80808080)
            sampTextdrawSetBoxColorAndSize(t, 1, 0xFF759DA3, PosX-10, 0.000000)
        end
    elseif id == 9 then
        for i = 0, 1 do
            t = t + 1
            if i == 0 then
                size = 0.8
                offsetY = 6
                offsetBX = 10
            else
                size = 1
                offsetY = 25
                offsetBX = 15
            end
            sampTextdrawCreate(t, "LD_SPAC:white", PosX+10, PosY+offsetY)
            sampTextdrawSetLetterSizeAndColor(t, 0, 1, 0x80808080)
            sampTextdrawSetBoxColorAndSize(t, 1, 0xFF759DA3, PosX-offsetBX, 0.000000)
        end
    end
end

function showCaptcha()
    removeTextdraws()
    t = t + 1
    sampTextdrawCreate(t, "LD_SPAC:white", 220, 120)
    sampTextdrawSetLetterSizeAndColor(t, 0, 6.5, 0x80808080)
    sampTextdrawSetBoxColorAndSize(t, 1, 0xFF1A2432, 380, 0.000000)

    t = t + 1
    sampTextdrawCreate(t, "LD_SPAC:white", 225, 125)
    sampTextdrawSetLetterSizeAndColor(t, 0, 5.5, 0x80808080)
    sampTextdrawSetBoxColorAndSize(t, 1, 0xFF759DA3, 375, 0.000000)

    local nextPos = -30.0
    math.randomseed(os.time())
    captcha = ''
    captchaTable = {}
    for i = 1, 4 do
        local a = math.random(0, 9)
        table.insert(captchaTable, a)
        captcha = captcha..a
    end
    for i = 0, 4 do
        nextPos = nextPos + 30
        t = t + 1
        sampTextdrawCreate(t, "usebox", 240 + nextPos, 130)
        sampTextdrawSetLetterSizeAndColor(t, 0, 4.5, 0x80808080)
        sampTextdrawSetBoxColorAndSize(t, 1, 0xFF1A2432, 30, 25.000000)
        sampTextdrawSetAlign(t, 2)
        if i < 4 then
            GenerateTextDraw(captchaTable[i + 1], 240 + nextPos, 130)
        else
            GenerateTextDraw(0, 240 + nextPos, 130)
        end
    end
    sampShowDialog(8813, '{F89168}Тренировка капчи', '{FFFFFF}Введите {C6FB4A}5{FFFFFF} символов, которые\nвидно на {C6FB4A}вашем{FFFFFF} экране.', 'Принять', 'Отмена', 1)
    captime = os.clock()
    trening_active = true
    captcha_dialog_open = true
end

function removeFire(text)
    return text and text:gsub(" :FIRE:%d+", ""):gsub(":FIRE:%d+", "") or ""
end

function show_arz_notify(type, title, text, time)
    local function escape_js(s)
        return s:gsub("\\", "\\\\"):gsub('"', '\\"')
    end
    local clean_text = removeFire(text or "")
    local str = ('window.executeEvent("event.notify.initialize", "[\\"%s\\", \\"%s\\", \\"%s\\", \\"%s\\"]");'):format(
        escape_js(type or "info"), escape_js(title or ""), escape_js(clean_text), tostring(time or settings.cef.timeout))
    visualCEF(str, true)
end

function visualCEF(str, is_encoded)
    local bs = raknetNewBitStream()
    raknetBitStreamWriteInt8(bs, 17)
    raknetBitStreamWriteInt32(bs, 0)
    raknetBitStreamWriteInt16(bs, #str)
    raknetBitStreamWriteInt8(bs, is_encoded and 1 or 0)
    if is_encoded then 
        raknetBitStreamEncodeString(bs, str) 
    else 
        raknetBitStreamWriteString(bs, str) 
    end
    raknetEmulPacketReceiveBitStream(220, bs)
    raknetDeleteBitStream(bs)
end

function getHouseName(id)
    if id >= 200 and id <= 246 then return "Вайн-Вуд"
    elseif id >= 0 and id <= 140 then return "Гетто"
    elseif id >= 142 and id <= 155 then return "Под Вайн-Вудом Дома"
    elseif id >= 1023 and id <= 1037 then return "Поломино Хиллс Дома"
    elseif id == 541 then return "Крутая Особа"
    elseif id == 495 or id == 124 or id == 491 or id == 307 or id == 413 or id == 624 or id == 255 then return "Грин-Таун"
    elseif id >= 850 and id <= 1300 then return "Сан-Фиеро"
    end
    return nil
end

function getBusinessName(id)
    if id >= 360 and id <= 397 then return "Парко Завод"
    elseif id >= 398 and id <= 408 then return "Парко Аэро Лс"
    elseif id >= 409 and id <= 410 then return "Парко Дб ЛС"
    elseif id >= 443 and id <= 450 then return "Водные парковки"
    end
    return nil
end

-- ============= ТЕСТОВАЯ ФУНКЦИЯ ДЛЯ ПРОВЕРКИ CEF =============

function testCEF()
    show_arz_notify('info', 'Тест CEF', 'Если вы это видите - CEF работает!', 5000)
    sms('Отправлен тестовый CEF нотифай')
end

-- Регистрируем тестовую команду
sampRegisterChatCommand('testcef', testCEF)

function cmd_marker()
    if not marker_enabled[0] then return end
    local x, y, z = getCharCoordinates(PLAYER_PED)
    if marker_defaultMode[0] == MODE_TRACER then
        if isCharInAnyCar(PLAYER_PED) then
            sms('Нельзя установить трейсер в машине')
            return
        end
        tracer.targetX, tracer.targetY, tracer.targetZ = x, y, z
        tracer.isSet = true
        currentMode = MODE_TRACER
        sms('Трейсер установлен')
    elseif marker_defaultMode[0] == MODE_MARKER then
        marker.x, marker.y, marker.z = x, y, z
        marker.interior = getActiveInterior()
        marker.isSet = true
        currentMode = MODE_MARKER
        sms('Маркер установлен')
    end
end

function cmd_delmarker()
    tracer.isSet = false
    marker.isSet = false
    currentMode = nil
    sms('Маркер удален')
end

function updateTracerMode()
    if not tracer.isSet then 
        currentMode = nil 
        return 
    end
    
    local status, err = pcall(function()
        local myX, myY, myZ = getCharCoordinates(PLAYER_PED)
        local wPosX, wPosY = convert3DCoordsToScreen(tracer.targetX, tracer.targetY, tracer.targetZ)
        local mPosX, mPosY = convert3DCoordsToScreen(myX, myY, myZ)
        
        if wPosX and wPosY and mPosX and mPosY then
            local color = palette.accent1.color_500
            color = bit.bor(bit.band(color, 0x00FFFFFF), 0xFF000000)
            renderDrawLine(mPosX, mPosY, wPosX, wPosY, 4.0, color)
        end
        
        if getDistanceBetweenCoords3d(myX, myY, myZ, tracer.targetX, tracer.targetY, tracer.targetZ) < 5.0 then
            cmd_delmarker()
            sms('Вы достигли цели!')
        end
    end)
end

function updateMarkerMode()
    if not marker.isSet then 
        currentMode = nil 
        return 
    end
    
    if getActiveInterior() ~= marker.interior then 
        return 
    end
    
    local status, err = pcall(function()
        local px, py, pz = getCharCoordinates(PLAYER_PED)
        local dist = getDistanceBetweenCoords3d(px, py, pz, marker.x, marker.y, marker.z)
        
        if dist <= drawDist then
            drawMarker(px, py, pz, dist)
        end
    end)
end

function isPointOnScreen(x, y, z)
    local screenX, screenY = convert3DCoordsToScreen(x, y, z)
    if not screenX or not screenY then return false end
    local screenW, screenH = getScreenResolution()
    if screenX < -50 or screenX > screenW + 50 or screenY < -50 or screenY > screenH + 50 then 
        return false 
    end
    return true, screenX, screenY
end

function drawMarker(px, py, pz, dist)
    local isVisible, centerX, centerY = isPointOnScreen(marker.x, marker.y, marker.z)
    if not isVisible then return end
    
    local screenW, screenH = getScreenResolution()
    local numSegments = 24
    local radius = 1.2
    local angleStep = (math.pi * 2) / numSegments
    
    local lineColor = palette.accent1.color_500
    lineColor = bit.bor(bit.band(lineColor, 0x00FFFFFF), 0xFF000000)
    
    for i = 0, numSegments - 1 do
        local angle1 = i * angleStep
        local angle2 = (i + 1) % numSegments * angleStep
        
        local x1 = marker.x + math.cos(angle1) * radius
        local y1 = marker.y + math.sin(angle1) * radius
        local z1 = marker.z - 0.1
        
        local x2 = marker.x + math.cos(angle2) * radius
        local y2 = marker.y + math.sin(angle2) * radius
        local z2 = marker.z - 0.1
        
        local vis1, sx1, sy1 = isPointOnScreen(x1, y1, z1)
        local vis2, sx2, sy2 = isPointOnScreen(x2, y2, z2)
        
        if vis1 and vis2 and sx1 and sx2 and sy1 and sy2 then
            renderDrawLine(sx1, sy1, sx2, sy2, 3.0, lineColor)
        end
    end
    
    local tx, ty = convert3DCoordsToScreen(marker.x, marker.y, marker.z + 1.5)
    if tx and ty and tx >= -50 and tx <= screenW + 50 and ty >= -50 and ty <= screenH + 50 then
        renderFontDrawText(render_font, string.format("%.1f м", dist), tx - 25, ty - 20, 0xFFFFFFFF)
    end
    
    local isPlayerVisible, psx, psy = isPointOnScreen(px, py, pz + 0.5)
    if isPlayerVisible and psx and psy and centerX and centerY then
        renderDrawLine(psx, psy, centerX, centerY, 4.0, lineColor)
    end
end

function updateActivationCommand()
    local cmd = ffi.string(activation_command)
    if cmd and cmd ~= "" then
        pcall(sampUnregisterChatCommand, settings.activationCommand)
        sampRegisterChatCommand(cmd, function()
            window[0] = not window[0]
            imgui.Process = window[0]
        end)
        settings.activationCommand = cmd
        sms('Команда активации изменена на {mc}/' .. cmd)
    end
end

function onWindowMessage(msg, wparam, lparam)
    if msg == 0x100 and wparam == vkeys.VK_ESCAPE and window[0] then
        window[0] = false
        imgui.Process = false
        return true
    end
    if msg == 0x100 and waiting_for_key then
        local key = VK_TO_KEY[wparam]
        if key then
            if waiting_for_key_type == "new" then
                table.insert(binders, {key = key, cmd = CMD_LIST[new_cmd_idx[0] + 1], enabled = true})
                saveConfig()
                sms('Биндер добавлен: ' .. key .. ' | ' .. tostring(CMD_NAMES[new_cmd_idx[0] + 1]))
            elseif waiting_for_key_type == "edit" and waiting_for_key_index then
                local binder = binders[waiting_for_key_index]
                if binder then
                    binder.key = key
                    saveConfig()
                    sms('Клавиша изменена на ' .. key)
                end
            end
            waiting_for_key = false
            waiting_for_key_type = nil
            waiting_for_key_index = nil
        end
        return true
    end
end

function onShowDialog(dlgId, style, title, button1, button2, text)
    if not title or not text then return end
    
    local nocolor = text:gsub("{......}", "")
    
    -- Проверяем диалог покупки имущества
    if title and (title:find('Разрешение на покупку имущества') or title:find('Разрешение на покупку')) then
        local houseId = nocolor:match('дом %((%d+)%)')
        local bizId = nocolor:match('бизнес %((%d+)%)')
        
        if houseId then
            local name = getHouseName(tonumber(houseId)) or ""
            if settings.cef.houseEnabled then
                show_arz_notify('info', 'Дом', 'ID: ' .. houseId .. ' ' .. name, settings.cef.timeout)
                sms('{info}Дом: {white}ID: ' .. houseId .. ' ' .. name)
            end
        end
        
        if bizId then
            local name = getBusinessName(tonumber(bizId)) or ""
            if settings.cef.businessEnabled then
                show_arz_notify('info', 'Бизнес', 'ID: ' .. bizId .. ' ' .. name, settings.cef.timeout)
                sms('{info}Бизнес: {white}ID: ' .. bizId .. ' ' .. name)
            end
        end
    end
end

-- Регистрируем обработчик диалогов через samp.events
if samp_check then
    function samp.onShowDialog(dlgId, style, title, button1, button2, text)
        onShowDialog(dlgId, style, title, button1, button2, text)
    end
end
function main()
    if not isSampfuncsLoaded() or not isSampLoaded() then return end
    while not isSampAvailable() do wait(100) end

    imgui.OnInitialize(function()
        imgui.GetIO().IniFilename = nil
        fonts = {}
        
        local glyph_ranges = imgui.GetIO().Fonts:GetGlyphRangesCyrillic()
        local font_path = getWorkingDirectory() .. '/HelperLovli/EagleSans-Regular.ttf'
        
        if file_exists(font_path) then
            fonts[20] = imgui.GetIO().Fonts:AddFontFromFileTTF(font_path, 20, nil, glyph_ranges)
            fonts[15] = imgui.GetIO().Fonts:AddFontFromFileTTF(font_path, 15, nil, glyph_ranges)
            fonts[18] = imgui.GetIO().Fonts:AddFontFromFileTTF(font_path, 18, nil, glyph_ranges)
            fonts[25] = imgui.GetIO().Fonts:AddFontFromFileTTF(font_path, 25, nil, glyph_ranges)
            fonts[30] = imgui.GetIO().Fonts:AddFontFromFileTTF(font_path, 30, nil, glyph_ranges)
        else
            fonts[20] = imgui.GetIO().Fonts:AddFontDefault()
            fonts[15] = fonts[20]
            fonts[18] = fonts[20]
            fonts[25] = fonts[20]
            fonts[30] = fonts[20]
        end
        
        getTheme()
    end)

    render_font = renderCreateFont("Arial", 14, 7)

    sampRegisterChatCommand(settings.activationCommand, function()
        window[0] = not window[0]
        imgui.Process = window[0]
    end)
    
    sampRegisterChatCommand('marker', function() cmd_marker() end)
    sampRegisterChatCommand('delmarker', function() cmd_delmarker() end)
    sampRegisterChatCommand('adr', function() sampProcessChatInput('/adrenaline') end)
    sampRegisterChatCommand('ontr', function() trening_enabled[0] = not trening_enabled[0]; saveConfig(); sms('Тренинг ' .. (trening_enabled[0] and '{mc}включен' or 'выключен')) end)
    sampRegisterChatCommand('captcha', function() trening_enabled[0] = not trening_enabled[0]; saveConfig(); sms('Тренинг ' .. (trening_enabled[0] and '{mc}включен' or 'выключен')) end)

    sms('{mc}Helper Lovli{ffffff} загружен! Авторы: {mc}bossov{ffffff} & {mc}slardar')
    sms('Активация меню: {mc}/' .. settings.activationCommand)
    sms('Загружено биндеров: {mc}' .. #binders)

    imgui.OnFrame(
        function() return window[0] and not isPauseMenuActive() and not sampIsScoreboardOpen() end,
        function()
            if window[0] then
                imgui.SetNextWindowSize(imgui.ImVec2(850, 470), imgui.Cond.Always)                
                imgui.SetNextWindowPos(
                    imgui.ImVec2(select(1, getScreenResolution())/2, select(2, getScreenResolution())/2),
                    imgui.Cond.FirstUseEver,
                    imgui.ImVec2(0.5,0.5)
                )
                imgui.Begin("Helper Lovli", window,
                    bit.bor(
                        imgui.WindowFlags.NoResize,
                        imgui.WindowFlags.NoCollapse,
                        imgui.WindowFlags.NoTitleBar,
                        imgui.WindowFlags.NoScrollbar,
                        imgui.WindowFlags.NoScrollWithMouse
                ))

                imgui.PushFont(fonts[25])
                imgui.Text("Helper Lovli")
                imgui.PopFont()

                imgui.SameLine(imgui.GetWindowWidth() - 40)
                if imgui.Button(u8"X", imgui.ImVec2(30, 25)) then
                    window[0] = false
                    imgui.Process = false
                end

                imgui.Separator()
                
                imgui.BeginGroup()
                imgui.PushFont(fonts[18])
                local menu_items = {
                    u8"Основное",
                    u8"Биндеры",
                    u8"Тренинг",
                    u8"Маркер",
                    u8"Таймер",
                    u8"CEF уведомления",
                    u8"Инфо"
                }
                for i, item in ipairs(menu_items) do
                    if imgui.ActiveButton(item, imgui.ImVec2(200, 45)) then
                        menu[0] = i
                    end
                end
                imgui.PopFont()
                imgui.EndGroup()

                imgui.SameLine()

                imgui.BeginColorChild('right_panel', imgui.ImVec2(610, 350), true,
                    bit.bor(
                        imgui.WindowFlags.NoScrollbar,
                        imgui.WindowFlags.NoScrollWithMouse
                    )
                )
                
                local title = menu_items[menu[0]]
                imgui.PushFont(fonts[25])
                local cursorY = imgui.GetCursorPosY()
                imgui.SetCursorPosY(cursorY - 5)
                imgui.CenterText(title, 25)
                imgui.SetCursorPosY(cursorY + 20)
                imgui.PopFont()
                imgui.Separator()

                if menu[0] == 1 then
                    imgui.PushFont(fonts[18])
                    imgui.FText(u8"Цвет скрипта:", 18)
                    imgui.SameLine()
                    imgui.PushItemWidth(200)
                    if imgui.ColorEdit3('##script_color', scriptColor) then
                        saveConfig()
                        getTheme()
                    end
                    imgui.PopItemWidth()
                    
                    imgui.Dummy(imgui.ImVec2(0, 10))
                    
                    imgui.FText(u8"Команда активации:", 18)
                    imgui.SameLine()
                    imgui.PushItemWidth(150)
                    imgui.Text("/")
                    imgui.SameLine()
                    if imgui.InputText('##activation_cmd', activation_command, ffi.sizeof(activation_command)) then end
                    imgui.PopItemWidth()
                    imgui.SameLine()
                    if imgui.ActiveButton(u8" Применить", imgui.ImVec2(100, 25)) then
                        updateActivationCommand()
                        saveConfig()
                    end
                    
                    imgui.Dummy(imgui.ImVec2(0, 10))
                    imgui.SetCursorPosX(100)
                    if imgui.ActiveButton(u8" Сохранить все настройки", imgui.ImVec2(250, 30)) then
                        saveConfig()
                        sms('Настройки сохранены')
                    end
                    imgui.PopFont()

                elseif menu[0] == 2 then
                    imgui.PushFont(fonts[18])
                    
                    imgui.BeginColorChild('binders_list', imgui.ImVec2(580, 180), true)
                    
                    for i, binder in ipairs(binders) do
                        imgui.Text(binder.key .. " | " .. binder.cmd)
                        imgui.SameLine(150)
                        
                        local bool = imgui.new.bool(binder.enabled)
                        if imgui.Checkbox(u8"Вкл##"..i, bool) then
                            binder.enabled = bool[0]
                            saveConfig()
                        end

                        imgui.SameLine(220)
                        if imgui.Button(u8"KEY##"..i) then
                            waiting_for_key = true
                            waiting_for_key_type = "edit"
                            waiting_for_key_index = i
                        end

                        imgui.SameLine(300)
                        if imgui.Button(u8"DEL##"..i) then
                            table.remove(binders, i)
                            saveConfig()
                        end
                        
                        imgui.SameLine(380)
                        local current_cmd_index = 1
                        for idx, cmd in ipairs(CMD_LIST) do
                            if cmd == binder.cmd then
                                current_cmd_index = idx
                                break
                            end
                        end
                        if imgui.Button(tostring(CMD_NAMES[current_cmd_index]) .. "##edit" .. i, imgui.ImVec2(180, 25)) then
                            show_cmd_popup[0] = true
                            selecting_cmd_type = "edit"
                            selecting_cmd_index = i
                            temp_cmd_selection = current_cmd_index
                        end

                        imgui.Dummy(imgui.ImVec2(0, 5))
                    end
                    
                    imgui.EndColorChild()
                    
                    imgui.Separator()
                    imgui.Text(u8"Новый биндер:")
                    
                    local window_width = imgui.GetWindowWidth()
                    local text_width = imgui.CalcTextSize(u8"[НАЖМИТЕ КЛАВИШУ]").x
                    imgui.SetCursorPosX((window_width - text_width) / 2)
                    
                    if waiting_for_key and waiting_for_key_type == "new" then
                        imgui.TextColored(convertDecimalToRGBA(palette.accent3.color_500), u8"[НАЖМИТЕ КЛАВИШУ]")
                    else
                        imgui.TextDisabled(u8"[ОЖИДАНИЕ КЛАВИШИ]")
                    end

                    imgui.Dummy(imgui.ImVec2(0, 5))
                    
                    local button_width = 200
                    imgui.SetCursorPosX((window_width - button_width) / 2 - 100)
                    
                    imgui.PushStyleColor(imgui.Col.Button, convertDecimalToRGBA(palette.accent2.color_700))
                    imgui.PushStyleColor(imgui.Col.ButtonHovered, convertDecimalToRGBA(palette.accent1.color_600))

                    if imgui.ActiveButton(tostring(CMD_NAMES[new_cmd_idx[0] + 1]) .. " (" .. CMD_LIST[new_cmd_idx[0] + 1] .. ")", imgui.ImVec2(200, 25)) then
                        show_cmd_popup[0] = true
                        selecting_cmd_type = "new"
                        temp_cmd_selection = new_cmd_idx[0] + 1
                    end

                    imgui.SameLine()
                    
                    if imgui.ActiveButton(u8" Добавить", imgui.ImVec2(140, 25)) then
                        waiting_for_key = true
                        waiting_for_key_type = "new"
                        sms('Нажмите клавишу для нового биндера...')
                    end

                    imgui.PopStyleColor(2)
                    imgui.PopFont()

                elseif menu[0] == 3 then
                    imgui.PushFont(fonts[18])
                    imgui.SetCursorPosX(100)
                    imgui.FText(u8"Включить тренинг:", 18)
                    imgui.SameLine(300)
                    if imgui.Checkbox('##trening_enabled', trening_enabled) then saveConfig() end
                    imgui.Dummy(imgui.ImVec2(0, 10))
                    imgui.SetCursorPosX(100)
                    imgui.FText(u8"Клавиша активации:", 18)
                    imgui.SameLine(300)
                    imgui.PushItemWidth(100)
                    if imgui.InputText('##trening_key', trening_key, ffi.sizeof(trening_key)) then saveConfig() end
                    imgui.PopItemWidth()
                    imgui.Dummy(imgui.ImVec2(0, 10))
                    imgui.SetCursorPosX(100)
                    if imgui.ActiveButton(u8" Открыть капчу сейчас", imgui.ImVec2(250, 30)) then
                        showCaptcha()
                    end
                    imgui.SameLine()
                    if imgui.ActiveButton(u8" Очистить", imgui.ImVec2(150, 30)) then
                        removeTextdraws()
                    end
                    imgui.PopFont()

                elseif menu[0] == 4 then
                    imgui.PushFont(fonts[18])
                    imgui.SetCursorPosX(100)
                    imgui.FText(u8"Включить маркер:", 18)
                    imgui.SameLine(300)
                    if imgui.Checkbox('##marker_enabled', marker_enabled) then saveConfig() end
                    imgui.Dummy(imgui.ImVec2(0, 10))
                    imgui.SetCursorPosX(100)
                    imgui.FText(u8"Режим по умолчанию:", 18)
                    imgui.SameLine(300)
                    local mode_names = { u8"Трейсер", u8"Маркер" }
                    if imgui.ActiveButton(mode_names[marker_defaultMode[0]], imgui.ImVec2(150, 25)) then
                        marker_defaultMode[0] = (marker_defaultMode[0] % 2) + 1
                        saveConfig()
                    end
                    imgui.Dummy(imgui.ImVec2(0, 20))
                    imgui.SetCursorPosX(100)
                    imgui.FText(u8"{TextDisabled}Команды:", 18)
                    imgui.SetCursorPosX(120)
                    imgui.FText(u8"{ButtonActive}/marker{Text} - поставить маркер", 18)
                    imgui.SetCursorPosX(120)
                    imgui.FText(u8"{ButtonActive}/delmarker{Text} - удалить маркер", 18)
                    imgui.PopFont()

                elseif menu[0] == 5 then
                    imgui.PushFont(fonts[18])
                    imgui.SetCursorPosX(100)
                    imgui.FText(u8"Включить таймер:", 18)
                    imgui.SameLine(300)
                    if imgui.Checkbox('##timer_enabled', timer_enabled) then saveConfig() end
                    imgui.Dummy(imgui.ImVec2(0, 20))
                    imgui.SetCursorPosX(100)
                    imgui.FText(u8"Таймер показывает время,", 18)
                    imgui.SetCursorPosX(100)
                    imgui.FText(u8"за которое вы ввели капчу", 18)
                    imgui.PopFont()

                elseif menu[0] == 6 then
                    imgui.PushFont(fonts[18])
                    imgui.SetCursorPosX(100)
                    imgui.FText(u8"Время показа уведомлений:", 18)
                    imgui.SameLine(300)
                    imgui.PushItemWidth(100)
                    if imgui.SliderInt('##cef_timeout', cef_timeout, 1, 20, u8'%d сек') then
                        saveConfig()
                    end
                    imgui.PopItemWidth()
                    
                    imgui.Dummy(imgui.ImVec2(0, 10))
                    imgui.SetCursorPosX(100)
                    imgui.FText(u8"Уведомления о домах:", 18)
                    imgui.SameLine(300)
                    if imgui.Checkbox('##house_enabled', cef_houseEnabled) then saveConfig() end
                    
                    imgui.Dummy(imgui.ImVec2(0, 10))
                    imgui.SetCursorPosX(100)
                    imgui.FText(u8"Уведомления о бизнесах:", 18)
                    imgui.SameLine(300)
                    if imgui.Checkbox('##business_enabled', cef_businessEnabled) then saveConfig() end
                    
                    imgui.Dummy(imgui.ImVec2(0, 20))
                    imgui.SetCursorPosX(100)
                    imgui.FText(u8"Статус:", 18)
                    imgui.SetCursorPosX(120)
                    imgui.FText(u8"Дома: " .. (cef_houseEnabled[0] and "{1DFF00}ВКЛ" or "{FF0000}ВЫКЛ"), 18)
                    imgui.SetCursorPosX(120)
                    imgui.FText(u8"Бизнесы: " .. (cef_businessEnabled[0] and "{1DFF00}ВКЛ" or "{FF0000}ВЫКЛ"), 18)
                    imgui.PopFont()

                elseif menu[0] == 7 then
                    imgui.PushFont(fonts[18])
                    imgui.Dummy(imgui.ImVec2(0, 20))
                    imgui.SetCursorPosX(150)
                    imgui.FText(u8"Helper Lovli for ARZ", 18)
                    imgui.SetCursorPosX(150)
                    imgui.FText(u8"Версия: 2.1.0", 18)
                    imgui.SetCursorPosX(150)
                    imgui.FText(u8"Авторы: idea - bossov, realization - slardar", 18)
                    imgui.Dummy(imgui.ImVec2(0, 20))
                    imgui.SetCursorPosX(150)
                    imgui.FText(u8"Команды:", 18)
                    imgui.SetCursorPosX(170)
                    imgui.FText(u8"{ButtonActive}/" .. settings.activationCommand .. u8"{Text} - открыть меню", 18)
                    imgui.SetCursorPosX(170)
                    imgui.FText(u8"{ButtonActive}/adr{Text} - /adrenaline", 18)
                    imgui.SetCursorPosX(170)
                    imgui.FText(u8"{ButtonActive}/marker{Text} - поставить маркер", 18)
                    imgui.SetCursorPosX(170)
                    imgui.FText(u8"{ButtonActive}/delmarker{Text} - удалить маркер", 18)
                    imgui.SetCursorPosX(170)
                    imgui.FText(u8"{ButtonActive}/ontr /captcha{Text} - тренинг", 18)
                    imgui.PopFont()
                end

                imgui.EndColorChild()

                imgui.Separator()
                imgui.BeginGroup()
                if imgui.ActiveButton(u8" Сохранить", imgui.ImVec2(130, 28)) then
                    saveConfig()
                    sms('Настройки сохранены')
                end
                imgui.SameLine()
                if imgui.Button(u8" Закрыть", imgui.ImVec2(130, 28)) then
                    window[0] = false
                    imgui.Process = false
                end
                imgui.EndGroup()

                imgui.End()
            end

            if show_cmd_popup[0] then
                imgui.OpenPopup(u8"Выбор команды")
                imgui.SetNextWindowSize(imgui.ImVec2(300, 350), imgui.Cond.Always)
                if imgui.BeginPopupModal(u8"Выбор команды", show_cmd_popup, imgui.WindowFlags.AlwaysAutoResize + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse) then
                    imgui.FText(u8"Выберите команду:", 18)
                    imgui.Separator()
                    
                    imgui.BeginColorChild('cmd_list', imgui.ImVec2(280, 250), true)
                    
                    for i = 1, #CMD_LIST do
                        local is_selected = (i == temp_cmd_selection)
                        local status = is_selected and "? " or " "
                        local btn_name = status .. tostring(CMD_NAMES[i]) .. " (" .. CMD_LIST[i] .. ")"
                        if imgui.ActiveButton(btn_name, imgui.ImVec2(250, 30)) then
                            if selecting_cmd_type == "edit" and selecting_cmd_index then
                                local binder = binders[selecting_cmd_index]
                                if binder then
                                    binder.cmd = CMD_LIST[i]
                                    saveConfig()
                                end
                            elseif selecting_cmd_type == "new" then
                                new_cmd_idx[0] = i - 1
                            end
                            show_cmd_popup[0] = false
                            selecting_cmd_type = nil
                            selecting_cmd_index = nil
                        end
                    end
                    
                    imgui.EndColorChild()
                    
                    imgui.Separator()
                    if imgui.Button(u8" Отмена", imgui.ImVec2(250, 30)) then
                        show_cmd_popup[0] = false
                        selecting_cmd_type = nil
                        selecting_cmd_index = nil
                    end
                    imgui.EndPopup()
                end
            end
        end
    )

    while true do
        wait(0)
        checkBinders()

        if trening_enabled[0] then
            local result, button, list, input = sampHasDialogRespond(8813)
            if result then
                if button == 1 then
                    if input == captcha..'0' then
                        sms('{1DFF00}Верно! [' .. string.format("%.3f", os.clock() - captime) .. ' сек]')
                    else
                        sms('{FF0000}Неверно! [' .. string.format("%.3f", os.clock() - captime) .. ' сек]')
                    end
                end
                removeTextdraws()
                trening_active = false
                captcha_dialog_open = false
            end
        end

        if timer_enabled[0] then
            if sampIsDialogActive() and sampGetDialogCaption():find('Проверка на робота') then
                ttime = os.clock()
                while sampIsDialogActive() do wait(0) end
                sms('Капча введена за ' .. string.sub(tostring(os.clock() - ttime), 1, 5) .. ' сек')
            end
        end

        if marker_enabled[0] then
            if currentMode == MODE_TRACER then
                updateTracerMode()
            elseif currentMode == MODE_MARKER then
                updateMarkerMode()
            end
        elseif currentMode then
            cmd_delmarker()
        end
    end
end

function onScriptTerminate(script, quitGame)
    if script == thisScript() then
        saveConfig()
    end
end

function onQuitGame()
    saveConfig()
end

EXPORTS = {}

function EXPORTS.isHelperOpen()
    return window[0]
end

function EXPORTS.openHelper()
    window[0] = true
    imgui.Process = true
end

function EXPORTS.closeHelper()
    window[0] = false
    imgui.Process = false
end
