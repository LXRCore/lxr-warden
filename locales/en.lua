--[[ ═══════════════════════════════════════════════════════════════════════════
     LXR-WARDEN — Locale: English (canonical)
     Developer   : iBoss21 | Brand : LXRCore | https://www.lxrcore.com
     © 2026 iBoss21 / LXRCore — All Rights Reserved
     ═══════════════════════════════════════════════════════════════════════════ ]]

Locale.Register('en', {
    cmd = { help = 'Warden: strikes for everyone, one player, or clear <id>' },
    check = { speed = 'moving too fast', weapon = 'unknown weapon in hand', health = 'health above the limit', spawns = 'spawning too much', explosion = 'explosion without explosives' },
    staff = { warn = 'Warden: %{name} (#%{id}) — %{check}, %{total} strikes.', one = '#%{id}: %{total} strikes. %{list}', all = '%{n} players with strikes; worst %{worst} (#%{id}).', cleared = 'Strikes cleared for #%{id}.' },
    player = { kicked = 'The server saw something it could not explain. Try again, honestly.' },
})
