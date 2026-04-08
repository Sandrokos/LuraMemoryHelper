# Lura Memory Helper

Lightweight World of Warcraft **retail** addon for the **L’ura** encounter (encounter ID **3183**) in **March of Quel’danas**. It shows a small **runes memory** display driven by **raid / raid-leader** chat in most difficulties and **instance chat** in **Raid Finder (LFR)**, pulled out of [Northern Sky Raid Tools](https://github.com/Reloe/NorthernSkyRaidTools) (NSRT), but as a focused standalone helper.

## Install

1. Copy the **`LuraMemoryHelper`** folder into your WoW `_retail_` addons directory:

   `World of Warcraft\_retail_\Interface\AddOns\`

2. **Install the Lura memory icon files (required for the runes to show correctly).** The encounter uses custom icons that are **not** part of the addon ZIP. Download the pack from **[Reloe/LuraMemoryFiles](https://github.com/Reloe/LuraMemoryFiles)** and **replace** the matching files (if any) under:

   `World of Warcraft\_retail_\Interface\ICONS\`

   Without these files, icon-based callouts in raid chat and the on-screen runes may not line up visually with what the encounter expects. The in-game options panel has a button that copies the same repo link and reminds you of this path.

## In-game usage

### Slash command: `/lmh`

| Command | Action |
|--------|--------|
| `/lmh` | Open or toggle the options panel |
| `/lmh options` | Same as `/lmh` |
| `/lmh preview` | Show the runes display (preview) |
| `/lmh hide` | Hide the runes display |
| `/lmh lock` | Lock the display position (default) |
| `/lmh unlock` | Unlock so you can drag the display |

On login the addon prints a short load message and reminds you that **`/lmh`** opens options.

### Runes display

- The display is meant for **L’ura** while you are in that encounter. Visibility follows **encounter phase** rules implemented in Lua (including **mythic** phase 4 handling).
- **Difficulty slot count:** **Normal** and **Raid Finder (LFR)** use **3** rune slots (and the same compact layout as Normal). **Heroic** and **Mythic** use **5** (with mythic-specific ordering from raid vs. raid-leader lines where applicable).
- **LFR** callouts use **instance chat** (`CHAT_MSG_INSTANCE_CHAT`), not the raid channel. The addon listens to **`CHAT_MSG_INSTANCE_CHAT`** for that mode and still listens to **`CHAT_MSG_RAID`** / **`CHAT_MSG_RAID_LEADER`** for Normal / Heroic / Mythic. All use the same icon/file IDs as NSRT for this mechanic.

### Macros (“Create Rune Macros” in options)

The options panel can create **general** (non–secure-button) macros:

- **`LMH_LURA_RUNE_1`** … **`LMH_LURA_RUNE_5`**

While you are in **Raid Finder** (difficulty **17**), **Create Rune Macros** generates lines with **`/i`** (instance). Outside LFR it uses **`/raid`** like NSRT. Open the options panel **from inside the LFR instance** (or mid-encounter) so the game reports the right difficulty; if a macro name already exists it is skipped—delete it first to switch **`/raid`** vs **`/i`**. You must be **out of combat** to create macros.

### Options

- Toggle the **runes display** and **sounds**
- **Preview** the layout and **unlock** dragging to reposition (position is saved in **`LuraDB`**)
- Open a copyable link for the **[LuraMemoryFiles](https://github.com/Reloe/LuraMemoryFiles)** pack—the **same extra `Interface\ICONS` files** called out in **Install** step 2

### Saved variables

Settings live in **`LuraDB`** (`SavedVariables`). The addon applies a small **schema** migration so defaults stay sensible (for example sounds default **off**).

## Requirements

- **WoW retail** with an `Interface` version compatible with the **`## Interface:`** line in `LuraMemoryHelper.toc` (currently **120001**).
- **LuraMemoryFiles** assets installed under **`_retail_\Interface\ICONS\`** (see **Install** step 2). The addon alone is not enough for correct rune visuals.

## Credits

Encounter flow and rune/icon behavior are **derived from NSRT**; see the **Notes** line in `LuraMemoryHelper.toc` for the upstream link.

## License

This project is licensed under the **MIT License**—see [LICENSE](LICENSE).
