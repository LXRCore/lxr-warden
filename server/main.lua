--[[ ═══════════════════════════════════════════════════════════════════════════
     LXR-WARDEN — Server: what the server can see, counted
     © 2026 iBoss21 / LXRCore — All Rights Reserved
     ═══════════════════════════════════════════════════════════════════════════ ]]

local LXRCore = exports['lxr-core']:GetCoreObject()
local LXR = exports['lxr-core']:GetLXR()
local W = LXRWarden
local RES = GetCurrentResourceName()
local book = {}       -- src → { strikes = {}, last = { x, y, z, at }, spawns = { n, at }, joined }

local function entry(src)
    book[src] = book[src] or { strikes = {}, spawns = { n = 0, at = os.time() }, joined = GetGameTimer() }
    return book[src]
end
local function exempt(src)
    if LXRCore.Perms.Has(src, Config.Strikes.exemptGroup) then return true end
    local st = Player(src).state
    return st.staff_noclip == true or st.staff_god == true
end
local function staff()
    local out = {}
    for _, id in ipairs(GetPlayers()) do local n = tonumber(id) if LXRCore.Perms.Has(n, Config.Strikes.staffGroup) then out[#out + 1] = n end end
    return out
end

local function strike(src, check, weight, detail)
    if exempt(src) then return end
    local e = entry(src)
    e.strikes[#e.strikes + 1] = { at = os.time(), weight = weight, check = check, detail = detail }
    local total, kept = W.Live(e.strikes, os.time())
    e.strikes = kept
    LXRCore.Log.exploit(src, ('warden %s: %s (total %d)'):format(check, tostring(detail or ''), total))
    LXRCore.Emit('lxr:warden:strike', nil, src, check, total, detail)
    local verdict = W.Verdict(total)
    if verdict == 'warn' then
        for _, s in ipairs(staff()) do LXRCore.Notify(s, Lang:t('staff.warn', { name = GetPlayerName(src) or src, id = src, check = Lang:t('check.' .. check), total = total }), 'warning', 8000) end
    elseif verdict == 'kick' then
        LXRCore.Functions.Kick(src, Lang:t('player.kicked'))
    elseif verdict == 'ban' then
        LXRCore.Functions.ExploitBan(src, 'warden:' .. check, Config.Strikes.banHours > 0 and Config.Strikes.banHours or nil)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🔁 SAMPLING: position, weapon, health
-- ═══════════════════════════════════════════════════════════════════════════════
CreateThread(function()
    local C = Config.Checks
    while true do
        Wait(C.sampleSeconds * 1000)
        local now = os.time()
        for _, id in ipairs(GetPlayers()) do
            local src = tonumber(id)
            local ped = GetPlayerPed(src)
            if ped and ped ~= 0 and LXRCore.Players[src] then
                local e = entry(src)
                local pos = GetEntityCoords(ped)
                if C.speed.on and e.last and GetGameTimer() - e.joined > C.speed.graceAfterSpawnMs and not (C.speed.ignoreDead and Player(src).state.dead) then
                    local mps = W.Speed(e.last, pos, now - e.last.at)
                    if mps > C.speed.maxMps then strike(src, 'speed', C.speed.weight, ('%.0f m/s'):format(mps)) end
                end
                e.last = { x = pos.x, y = pos.y, z = pos.z, at = now }
                if C.weapon.on then
                    local hash = GetSelectedPedWeapon(ped)
                    if not W.KnownWeapon(hash) then strike(src, 'weapon', C.weapon.weight, tostring(hash)) end
                end
                if C.health.on then
                    local hp = GetEntityHealth(ped)
                    if hp > C.health.max then strike(src, 'health', C.health.weight, tostring(hp)) end
                end
            end
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🧨 GAME EVENTS: spawns, explosions
-- ═══════════════════════════════════════════════════════════════════════════════
AddEventHandler('entityCreating', function(handle)
    local C = Config.Checks.spawns
    if not C.on then return end
    local owner = NetworkGetFirstEntityOwner(handle)
    if not owner or owner <= 0 or not LXRCore.Players[owner] then return end
    local e = entry(owner)
    local now = os.time()
    if now - e.spawns.at >= 60 then e.spawns = { n = 0, at = now } end
    e.spawns.n = e.spawns.n + 1
    if e.spawns.n > C.perMinute and not exempt(owner) then
        CancelEvent()
        if e.spawns.n == C.perMinute + 1 then strike(owner, 'spawns', C.weight, ('%d/min'):format(e.spawns.n)) end
    end
end)

AddEventHandler('explosionEvent', function(sender, ev)
    local C = Config.Checks.explosions
    if not C.on then return end
    local src = tonumber(sender)
    if not src or not LXRCore.Players[src] or exempt(src) then return end
    if C.requireItem and not W.HasExplosive(function(n) return LXRCore.Inventory.GetItemCount(src, n) end) then
        CancelEvent()
        strike(src, 'explosion', C.weight, tostring(ev and ev.explosionType))
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🧾 STAFF
-- ═══════════════════════════════════════════════════════════════════════════════
LXR.Commands.Register({
    name = Config.Command.name, help = Lang:t('cmd.help'), permission = Config.Command.permission,
    args = { { name = 'id|clear', help = 'player id, or clear' }, { name = 'id', help = 'player id to clear' } },
    handler = function(src, args)
        if args[1] == 'clear' then
            local T = tonumber(args[2])
            if T and book[T] then book[T].strikes = {} end
            return LXRCore.Notify(src, Lang:t('staff.cleared', { id = tostring(T) }), 'info')
        end
        local T = tonumber(args[1])
        if T then
            local e = book[T]
            local total = e and W.Live(e.strikes, os.time()) or 0
            local lines = {}
            for _, s in ipairs(e and e.strikes or {}) do lines[#lines + 1] = ('%s %s'):format(Lang:t('check.' .. s.check), s.detail or '') end
            return LXRCore.Notify(src, Lang:t('staff.one', { id = T, total = total, list = table.concat(lines, ', ') }), 'info', 10000)
        end
        local n, worst, worstT = 0, 0, nil
        for id, e in pairs(book) do local t = W.Live(e.strikes, os.time()) if t > 0 then n = n + 1 end if t > worst then worst, worstT = t, id end end
        LXRCore.Notify(src, Lang:t('staff.all', { n = n, worst = worst, id = tostring(worstT or '-') }), 'info', 8000)
    end,
})

AddEventHandler('playerDropped', function() book[source] = nil end)
CreateThread(function()
    if Config.Debug.printBanner then
        local on = {}
        for k, c in pairs(Config.Checks) do if type(c) == 'table' and c.on then on[#on + 1] = k end end
        table.sort(on)
        print(('^1[lxr-warden]^7 v%s — checks: %s; kick at %d, ban at %d'):format(GetResourceMetadata(RES, 'version', 0), table.concat(on, ', '), Config.Strikes.kickAt, Config.Strikes.banAt))
    end
end)
exports('Strikes', function(src) local e = book[src] return e and W.Live(e.strikes, os.time()) or 0 end)
exports('Strike', strike)
exports('Clear', function(src) if book[src] then book[src].strikes = {} end end)
