# Bears Low Arrows

## Unreleased

- fix: "Test alert" and "Flash text" now stay up for the selected alert duration. The periodic check was hiding them within a few seconds when ammo was above the threshold.
- fix: "Test sound" now falls back to the default raid warning sound if the selected sound file can't be played, and reports the failure in chat if no fallback is available.
- fix: fixed a load error ("attempt to index upvalue 'soundList'") when the options window was initialized
- chore: renamed everything from "Bears Low Arrow" to "Bears Low Arrows". The SavedVariables table is now `BearsLowArrowsDB` (was `BearsLowArrowDB`), so settings saved under the old name are not carried over. Frame names, the minimap button, the options window, the slash command globals, the TOC title, and the release project name use the new name. Slash commands `/arrows` and `/bla` are unchanged.
- chore: project source repository moved to https://github.com/N6REJ/Bears-Low-Arrows (README link updated)
- chore: packaged addon folder is now `Bears_Low_Arrows` (`package-as` in `.pkgmeta`), matching the TOC filename
- docs: README rewritten. Installation no longer uses machine-specific paths and uses a generic AddOns location. Adds a git clone option. File layout, development notes, and badge (Forever 1.60.1) updated.
- feat: large on-screen "LOW AMMO" alert for hunters whose ammo count is below the set threshold. Covers all hunter ammo types (arrows, bullets, and bolts).
- feat: options window (`/lowarrow`) with sliders for the threshold (200-2000 in steps of 200), alert duration, and delay between alerts
- feat: alert font size slider (24-128 points)
- feat: alert font selection from the LibSharedMedia-3.0 font list, including fonts added by other addons. Stepped with `<` and `>` in the options window.
- feat: "Unlock alert position" option. When unlocked, the alert shows a preview and can be dragged. The position is saved, and "Reset position" moves it back to the top center.
- feat: minimap button with an arrow icon, placed at the top of the minimap by default. Left-click opens options, and it can be dragged around the minimap edge.
- feat: alert text colors. "LOW AMMO" and "RELOAD YOUR QUIVER" each have a color swatch in the options window that opens the Blizzard color wheel (`ColorPickerFrame`).
- feat: "RELOAD YOUR QUIVER" alert when an equipped quiver or ammo pouch is empty. Uses the same duration, delay, sound, and font as the low ammo alert.
- fix: ammo count now includes arrows, bullets, and bolts held in equipped quivers and ammo pouches (read with `C_Container`). Loose ammo in other bags and the ammo slot are no longer counted.
- chore: Forever only. TOC interface is 16001. The options window uses the same custom frames as the Bears-Mailbox Forever addon (backdrop panels, custom checkboxes, sliders, and buttons) instead of classic UI templates. The sound picker is a scrollable list in the same style.
- feat: "Test sound" button and `/arrows sound` / `/bla sound` play the selected sound on its own.
- feat: alert sound option. Plays with each alert and with the Test alert button. Sounds are chosen from a dropdown list of built-in options and LibSharedMedia-3.0 sounds.
- feat: "Flash text" button pulses the alert for the set duration
- feat: slash commands are now `/arrows` and `/bla` (replaces `/lowarrow`)
- feat: enable/disable checkbox and a "Test alert" button
- chore: initial project skeleton (TOC, packager and workflow files)
