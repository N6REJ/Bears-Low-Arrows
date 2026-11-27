# Bears Low Arrow

[![WoW Version](https://img.shields.io/badge/WoW-12.1.5-darkgreen)](https://worldofwarcraft.blizzard.com/) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT) [![GitHub](https://img.shields.io/badge/GitHub-Source-blue?logo=github)](https://github.com/N6REJ/Bears-Low-Arrow)

Shows a large on-screen alert when a hunter is running low on ammo. Works for
all hunter ammo types (arrows, bullets, and bolts).

## How it works

- Only active for hunters, and only while alerts are enabled.
- The ammo count includes only arrows, bullets, and bolts inside your equipped
  quivers and ammo pouches. Loose ammo in other bags is not counted.
- If a quiver or ammo pouch is equipped but empty, the alert reads
  "RELOAD YOUR QUIVER" instead of "LOW AMMO".
- When the total drops below the **Alert below** threshold, a
  large red "LOW AMMO" message appears in the center of the screen.
- The message stays up for **Alert duration** seconds, then waits
  **Delay between alerts** seconds before showing again, as long as you are
  still below the threshold.
- Once you have enough arrows, the alert stops.

## Options

Open the options window with `/arrows` or `/bla`.

| Option | Range | Default |
| --- | --- | --- |
| Alert below | 200-2000 ammo, steps of 200 | 400 |
| Alert duration | 1-30 seconds | 5 |
| Delay between alerts | 5-120 seconds | 30 |
| Alert font size | 24-128 points, steps of 4 | 96 |
| Font | Any font registered with LibSharedMedia-3.0, including fonts added by other addons. Use `<` and `>` to step through the list. | Friz Quadrata TT |
| Play alert sound | Play a sound each time the alert appears. Default on. | on |
| Sound | Click to open a scrollable list (mouse wheel or scrollbar) of built-in sounds (Raid Warning, Level Up, Ready Check, Map Ping, Alarm Clock) plus any sound registered with LibSharedMedia-3.0. Click a sound to select it. | Raid Warning |
| Low ammo text | Color of the "LOW AMMO" text. Click the swatch to open the color wheel. | red |
| Reload quiver text | Color of the "RELOAD YOUR QUIVER" text. Click the swatch to open the color wheel. | gold |
| Enable alerts | on/off | on |
| Unlock alert position | On: the alert shows a preview and can be dragged. Off: the alert is click-through. Closing the options window locks it again. | off |
| Reset position | Moves the alert back to the top center of the screen. | - |

The **Test alert** button shows the alert once using the current duration.
The **Flash text** button pulses the alert for the current duration.
The **Test sound** button plays the selected sound, even when alert sounds are off.

## Minimap button

An arrow icon sits at the top of the minimap by default. Left-click it to open
the options window. Drag it around the minimap edge to move it; its position is
saved.

## Commands

| Command | Description |
| --- | --- |
| `/arrows` or `/bla` | Open or close the options window. |
| `/arrows test` or `/bla test` | Show a test alert. |
| `/arrows flash` or `/bla flash` | Flash the alert text. |
| `/arrows sound` or `/bla sound` | Play the selected alert sound. |

## Requirements

- World of Warcraft: Forever (1.60.1, interface 16001).

## Installation

The repository root is the addon folder, but the folder must be named
`Bears_Low_Arrow` to match `Bears_Low_Arrow.toc`. Junction it into the Forever
AddOns directory:

```powershell
New-Item -ItemType Junction `
    -Path "C:\Gaming\World of Warcraft\_forever_\Interface\AddOns\Bears_Low_Arrow" `
    -Target "E:\wow\Bears-Low-Arrow"
```

Then run `/reload` in game.

## File layout

```text
Bears_Low_Arrow.toc        Addon manifest and load order
core.lua                   Settings, ammo checks, and reminder timing
alert.lua                  Large on-screen alert frame
options.lua                Options window and slash commands (/arrows, /bla)
.github/                   Release, changelog, labels, and stats workflows
.packager/                 BigWigs packager scripts
.pkgmeta                   BigWigs packager configuration
README.md                  This file
CHANGELOG.md               Version history
AGENTS.md                  Project guidance for contributors and agents
```

## Development

- The addon name, TOC filename, folder name, and SavedVariables prefix
  (`BearsLowArrowDB`) must stay consistent.
- Add any new runtime file to `Bears_Low_Arrow.toc` in load order.
- Keep the code Lua 5.1 compatible.

## Release automation

`.github/workflows/release.yml` runs BigWigsMods/packager when a tag is pushed.
It expects the repository secrets `CF_API_KEY`, `WAGO_API_TOKEN`, and the
automatic `GITHUB_TOKEN`. The TOC includes `## X-Curse-Project-ID: 1834026`.

`curseforge-stats.yml` refreshes download stats daily and needs the
`CF_STUDIO_API_KEY` secret.

## License

MIT. See [LICENSE](LICENSE).
