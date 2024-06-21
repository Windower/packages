# Pet

Provides information about the player's pet.

## `pet`
This table mostly contains  simple/self explanatory information about the player's currently active pet, if any.
- **index**
- **id**
- **name**
- **owner_index**
- **owner_id**
- **target_id**
- **hp_percent** (current/max values not available, except for the player's automaton in `pet.automaton`)
- **mp_percent** (current/max values not available, except for the player's automaton in `pet.automaton`)
- **tp**
- **active** true if the player has a pet out

## `pet.automaton`
This table holds more complex data describing the player's puppetmaster automaton.
- **name**
- **hp**
- **hp_max**
- **mp**
- **mp_max**
- **active** true if the player's currently active pet appears to be their automaton
- **head**
  - **raw**: unmodified value
  - **item_id**: `raw` + 0x2000
  - **item**: Item information from `client_data.items`
- **frame**
  - **raw**: unmodified value
  - **item_id**: `raw` + 0x2000
  - **item**: Item information from `client_data.items`
- **attachments**: Arrays from 0 to 11 of the following type:
  - **raw**: unmodified value 
  - **item_id**: `raw` + 0x2100
  - **item**: Item information from `client_data``
- **available_heads[i]**: Original index. Offset from `item_id` by 0x2000, starting at `harlequin_head == 1` (no `0`).
- **available_frames[i]**: Original index. Offset from `item_id` by 0x2020, starting at `harlequin_frame == 0`.
- **available_attach[i]**: Original index.  Offset from `item_id` by 0x2100, starting at `strobe == 1` (no `0`).
- **heads_available[item_id]** Modified index to accept `item_id`.
- **frames_available[item_id]** Modified index to accept `item_id`.
- **attach_available[item_id]** Modified index to accept `item_id`.
Automaton's current skill values
- **melee**
- **ranged**
- **magic**
Automaton's skill caps
- **melee_max**
- **magic_max**
- **ranged_max**
Automaton's base stats
- **str**
- **dex**
- **vit**
- **agi**
- **int**
- **mnd**
- **chr**
Automaton's current stat modifiers
- **str_modifier**
- **dex_modifier**
- **vit_modifier**
- **agi_modifier**
- **int_modifier**
- **mnd_modifier**
- **chr_modifier**
