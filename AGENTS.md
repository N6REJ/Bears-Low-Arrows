# Project guidance

- Scope: this addon uses only the repository at `E:\wow\Bears-Low-Arrow`. Do not edit or use files from other projects. Other addons under `E:\wow` and `C:\Gaming\World of Warcraft\_forever_\Interface\AddOns` may be read for reference only (for example, to copy an approach that works on Forever), and nothing may be copied from them without asking.
- Bears_Low_Arrow targets World of Warcraft: Forever (1.60.1, interface 16001) only. Use only the APIs available in Forever; do not use retail-only APIs (for example `DropdownButton`, `MenuUtil`, or `SetScrollMode`). Do not add other client variants.
- Always sync changes to `C:\Gaming\World of Warcraft\_forever_\Interface\AddOns\Bears_Low_Arrow` after editing.
- Do not use ElvUI libraries, code, or its `E` namespace, and do not add other UI frameworks. Use Blizzard APIs.
- Keep the addon Lua 5.1 compatible.
- Keep the folder name, TOC filename, addon name, and SavedVariables prefix (`BearsLowArrowDB`) consistent.
- Register runtime files in `Bears_Low_Arrow.toc` in load order.
- Update `README.md` and `CHANGELOG.md` when behavior changes.
