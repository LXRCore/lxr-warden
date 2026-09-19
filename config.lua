--[[
    ██╗     ██╗  ██╗██████╗       ██╗    ██╗ █████╗ ██████╗ ██████╗ ███████╗███╗   ██╗
    ██║     ╚██╗██╔╝██╔══██╗      ██║    ██║██╔══██╗██╔══██╗██╔══██╗██╔════╝████╗  ██║
    ██║      ╚███╔╝ ██████╔╝█████╗██║ █╗ ██║███████║██████╔╝██║  ██║█████╗  ██╔██╗ ██║
    ██║      ██╔██╗ ██╔══██╗╚════╝██║███╗██║██╔══██║██╔══██╗██║  ██║██╔══╝  ██║╚██╗██║
    ███████╗██╔╝ ██╗██║  ██║      ╚███╔███╔╝██║  ██║██║  ██║██████╔╝███████╗██║ ╚████║
    ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝       ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚═╝  ╚═══╝

    LXR Core - Warden

    Server-side sanity. Nothing here trusts the client: the warden samples
    what the server itself can see through OneSync — where a ped is, what it
    holds, what it spawns, what explodes — and counts strikes. Strikes warn
    staff, then kick, then ban through the core. Staff tools from lxr-admin
    (no clip, godmode) are read from the player's state bag and exempt.
    What a server cannot prove (aimbots, wallhacks, menus that never touch
    the network) is not claimed here.

    Brand:       LXRCore — Lux Empire eXperience RedM Core
    Product:     wolves.land / The Land of Wolves
    Developer:   iBoss21 / LXRCore
    Website:     https://www.lxrcore.com
    Discord:     https://discord.gg/GAhk8cgXe9
    GitHub:      https://github.com/LXRCore

    Version: 3.0.0
    Performance Target: one sampling pass every `sampleSeconds` across online players; no client loop

    © 2026 iBoss21 / LXRCore | lxrcore.com | All Rights Reserved
]]

Config = Config or {}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ LANGUAGE ██████████████████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████
Config.Lang = 'en'

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ CHECKS ════════════════════════════════════════════════
-- ████████████████████████████████████████████████████████████████████████████████
Config.Checks = {
    sampleSeconds = 5,
    -- distance covered between samples, in metres per second; a galloping horse is ~14, a train ~20
    speed    = { on = true, maxMps = 45.0, graceAfterSpawnMs = 20000, ignoreDead = true, weight = 1 },
    -- weapon in hand that the core catalog does not know (spawned, not from an item)
    weapon   = { on = true, weight = 2 },
    -- health above what the game allows
    health   = { on = true, max = 800, weight = 2 },
    -- entities created by a player per minute (OneSync entityCreating)
    spawns   = { on = true, perMinute = 20, weight = 1 },
    -- explosions from a player without an explosive item in the satchel
    explosions = { on = true, requireItem = true, weight = 3, items = { 'weapon_thrown_dynamite', 'weapon_thrown_dynamite_volatile', 'weapon_thrown_molotov', 'ammo_revolver_explosive', 'ammo_pistol_explosive', 'ammo_repeater_explosive', 'ammo_rifle_explosive', 'ammo_shotgun_explosive', 'ammo_arrow_dynamite', 'blasting_cap' } },
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ STRIKES ═══════════════════════════════════════════════
-- ████████████████████████████████████████████████████████████████████████████████
Config.Strikes = {
    warnStaffAt = 2,             -- staff at `staffGroup` are told
    kickAt = 5,
    banAt = 9, banHours = 72,    -- 0 = permanent
    decayMinutes = 30,           -- strikes older than this fall off
    staffGroup = 'mod',
    exemptGroup = 'admin',       -- never struck (in addition to lxr-admin's state bags)
}

Config.Command = { name = 'warden', permission = 'mod' }   -- /warden [id] — strikes; /warden clear <id>
Config.Debug = { printBanner = true, log = true }
