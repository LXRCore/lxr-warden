<img src="https://raw.githubusercontent.com/LXRCore/.github/main/profile/lxrcore-logo.png" alt="LXRCore" width="72" align="left" style="margin-right:12px">

# lxr-warden — Server-side sanity, for LXRCore

Nothing here trusts the client. The warden samples what the server itself
can see through OneSync — where a ped is, what it holds, what it spawns,
what explodes — and counts strikes. Strikes warn staff, then kick, then
ban through the core's ban table. Staff tools from lxr-admin (no clip,
godmode) are read from the player's state bag and exempt.

What a server cannot prove — aimbots, wallhacks, menus that never touch
the network — is not claimed here. There is no client script.

## What it does

| Check | What the server sees | Default |
|---|---|---|
| `speed` | distance between samples ÷ time, after a spawn grace, not while dead | > 45 m/s |
| `weapon` | `GetSelectedPedWeapon` not in the core weapon catalog | on |
| `health` | `GetEntityHealth` above the game's ceiling | > 800 |
| `spawns` | `entityCreating` per player per minute; the rest are cancelled | > 20 |
| `explosions` | `explosionEvent` from a player with no explosive item; cancelled | on |

* **Strikes** — weighted, decaying after `decayMinutes`; at `warnStaffAt`
  staff (`staffGroup`) are told, at `kickAt` the player is kicked, at
  `banAt` banned for `banHours` (0 = permanent) through the core.
* **Exempt** — `exemptGroup` and `Player(src).state.staff_noclip / staff_god`.
* **Staff** — `/warden` (everyone with strikes), `/warden <id>`,
  `/warden clear <id>`.
* **Events** — `lxr:warden:strike (src, check, total, detail)`; core log
  line `exploit`.

## Install

```cfg
ensure lxr-core
ensure lxr-warden
```

## API

| Name | Side | Purpose |
|---|---|---|
| `Strikes(src)` | server | live strike total |
| `Strike(src, check, weight, detail)` | server | let another resource add one |
| `Clear(src)` | server | wipe a player's strikes |

## Licence

© 2026 iBoss21 / LXRCore — All Rights Reserved. See `LICENSE`.
