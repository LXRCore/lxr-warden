--[[ ═══════════════════════════════════════════════════════════════════════════
     LXR-WARDEN — Offline tests: speed, known weapons, decay, verdicts, locale parity
     Usage (from the lxr-warden folder):  lua tests/run.lua
     © 2026 iBoss21 / LXRCore — All Rights Reserved
     ═══════════════════════════════════════════════════════════════════════════ ]]

local CORE = os.getenv('LXR_CORE_PATH') or '../lxr-core'
package.path = CORE .. '/?.lua;' .. package.path
local ok = pcall(function() require('tests.lib.fxshim') end)
if not ok then print('lxr-core shim not found at ' .. CORE) os.exit(2) end
local Shim = require('tests.lib.fxshim')
for _, f in ipairs({ 'shared/main.lua', 'shared/locale.lua', 'locales/en.lua', 'config.lua', 'shared/catalog.lua', 'shared/items.lua', 'shared/prices.lua', 'shared/weapons.lua' }) do Shim.load(CORE .. '/' .. f) end
Config = nil Locale = nil
Shim.load('shared/locale.lua') Shim.load('locales/en.lua') Shim.load('locales/ka.lua') Shim.load('config.lua') Shim.load('shared/rules.lua')
local W = LXRWarden

local passed, failed = 0, 0
local function test(name, fn) local okT, err = xpcall(fn, debug.traceback) if okT then passed = passed + 1 print('  ^ ok   ' .. name) else failed = failed + 1 print('  x FAIL ' .. name .. '\n' .. err) end end
local function eq(a, b, msg) if a ~= b then error((msg or 'eq') .. ': expected ' .. tostring(b) .. ' got ' .. tostring(a), 2) end end

print('lxr-warden offline tests')
test('speed in metres per second; zero time is zero', function()
    eq(W.Speed({ x = 0, y = 0, z = 0 }, { x = 30, y = 40, z = 0 }, 5), 10)
    eq(W.Speed({ x = 0, y = 0, z = 0 }, { x = 1, y = 0, z = 0 }, 0), 0)
    assert(Config.Checks.speed.maxMps > 20, 'a train must not strike')
end)
test('known weapons: unarmed and every catalog weapon; garbage is not', function()
    assert(W.KnownWeapon(0)) assert(W.KnownWeapon(nil)) assert(W.KnownWeapon(-1569615261))
    local n = 0
    for hash in pairs(LXRShared.Weapons) do assert(W.KnownWeapon(hash), tostring(hash)) n = n + 1 end
    assert(n > 20)
    assert(not W.KnownWeapon(123456789))
end)
test('strikes decay; verdicts climb', function()
    local now = 100000
    local strikes = { { at = now - 10, weight = 2, check = 'speed' }, { at = now - Config.Strikes.decayMinutes * 60 - 1, weight = 9, check = 'weapon' } }
    local total, kept = W.Live(strikes, now)
    eq(total, 2) eq(#kept, 1)
    eq(W.Verdict(0), nil) eq(W.Verdict(Config.Strikes.warnStaffAt), 'warn') eq(W.Verdict(Config.Strikes.kickAt), 'kick') eq(W.Verdict(Config.Strikes.banAt), 'ban')
    assert(Config.Strikes.warnStaffAt < Config.Strikes.kickAt and Config.Strikes.kickAt < Config.Strikes.banAt)
end)
test('explosive items exist in the catalog; the satchel check reads them', function()
    for _, n in ipairs(Config.Checks.explosions.items) do assert(LXRShared.Items[n], n) end
    assert(W.HasExplosive(function(n) return n == 'weapon_thrown_dynamite' and 1 or 0 end))
    assert(not W.HasExplosive(function() return 0 end))
    for k in pairs(Config.Checks) do if type(Config.Checks[k]) == 'table' then assert(Locale.Bundles.en['check.' .. (k == 'explosions' and 'explosion' or k)], 'label ' .. k) end end
end)
test('locale parity', function()
    local en, ka = Locale.Bundles.en, Locale.Bundles.ka
    local missing = {}
    for k in pairs(en) do if ka[k] == nil then missing[#missing + 1] = k end end
    eq(#missing, 0, 'ka missing: ' .. table.concat(missing, ', '))
end)
print(('%d passed, %d failed'):format(passed, failed))
os.exit(failed == 0 and 0 or 1)
