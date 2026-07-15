local mp = require 'mp'

local function get_clipboard()
    if mp.get_property('clipboard-backends') ~= nil or mp.get_property_bool('clipboard-enable') then
        return mp.get_property('clipboard/text', '')
    end
    local res = mp.command_native({
        name = 'subprocess',
        playback_only = false,
        capture_stdout = true,
        args = { 'powershell', '-NoProfile', '-Command', 'Get-Clipboard -Raw' }
    })
    return res.error and '' or res.stdout
end

local function decode(value)
    value = value:gsub('+', ' ')
    return (value:gsub('%%(%x%x)', function(hex)
        return string.char(tonumber(hex, 16))
    end))
end

local function parse(uri)
    local query = {}
    for pair in (uri:match('%?(.*)') or ''):gmatch('[^&]+') do
        local key, value = pair:match('^([^=]+)=(.*)$')
        if key then query[decode(key)] = decode(value) end
    end
    return query
end

local function is_allowed_media(url)
    local host, path = url:match('^https://([^/:?#]+)([^?#]*)')
    if not host or not path:lower():match('%.m3u8$') then return false end
    host = host:lower()
    return host == '115.com' or host:match('%.115%.com$') or
        host == '115cdn.net' or host:match('%.115cdn%.net$')
end

mp.add_forced_key_binding('Ctrl+v', 'mpv115-paste', function()
    local value = get_clipboard():match('^%s*(.-)%s*$')
    if not value:find('^mpv115://play%?') then
        mp.commandv('script-message-to', 'open_dialog', 'import_clipboard')
        return
    end

    local query = parse(value)
    if not is_allowed_media(query.url or '') then
        mp.osd_message('无效的 MPV 115 链接')
        return
    end

    mp.set_property('referrer', 'https://115.com/')
    mp.set_property('user-agent', query.ua or '')
    mp.set_property('force-media-title', query.title or '115')
    mp.commandv('loadfile', query.url, 'replace')
end)
