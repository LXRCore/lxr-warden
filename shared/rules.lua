--[[ ═══════════════════════════════════════════════════════════════════════════
     LXR-WARDEN — Shared rules: the arithmetic of suspicion
     © 2026 iBoss21 / LXRCore — All Rights Reserved
     ═══════════════════════════════════════════════════════════════════════════ ]]

LXRWarden = LXRWarden or {}
local W = LXRWarden

---Metres per second between two samples.
function W.Speed(a, b, seconds)
    if seconds <= 0 then return 0 end
    local d = math.sqrt((a.x - b.x) ^ 2 + (a.y - b.y) ^ 2 + (a.z - b.z) ^ 2)
    return d / seconds
end

---Is a weapon hash one the catalog knows (0 = unarmed is always fine)?
function W.KnownWeapon(hash)
    if not hash or hash == 0 or hash == -1569615261 then return true end   -- WEAPON_UNARMED
    return LXRShared.GetWeapon(hash) ~= nil
end

---Sum of live strikes after decay; strikes is { { at, weight, check } }.
function W.Live(strikes, now)
    local cutoff = now - Config.Strikes.decayMinutes * 60
    local total, kept = 0, {}
    for _, s in ipairs(strikes or {}) do if s.at >= cutoff then total = total + s.weight kept[#kept + 1] = s end end
    return total, kept
end

---What a strike total calls for: nil | 'warn' | 'kick' | 'ban'.
function W.Verdict(total)
    local S = Config.Strikes
    if S.banAt > 0 and total >= S.banAt then return 'ban' end
    if S.kickAt > 0 and total >= S.kickAt then return 'kick' end
    if S.warnStaffAt > 0 and total >= S.warnStaffAt then return 'warn' end
    return nil
end

---Does a count function cover any explosive item? count(name) → n
function W.HasExplosive(count)
    for _, n in ipairs(Config.Checks.explosions.items) do if (count(n) or 0) > 0 then return true end end
    return false
end
