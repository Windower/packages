**Author:** Nifim<br>
**Version:** 0.8.0.0<br>
**Date:** Nov. 30, 2019<br>

# Party Time #

* Automaticly accept or decline invites.
* Send party requests which can be automaticly accepted by PT users.
* Provide dialog for invites, requests, selecting party leader, etc.

----

**Main Command:** `/pt`

#### Commands: ####
* 1: (i)nvite [names] - Invite a player or players to join your party.
* 2: (r)equest [name] - Send an invite request to a player.
* 3: breakup [party|alliance] - Disband your party | alliance.
* 4: leave - Leave party or alliance.
* 5: leader [name] - Pass party | alliance leader player.
* 6: looter [name] - Send an invite request to a player.
* 7: (k)ick [names] - Kick player from your party.
* 8: whitelist (a)dd|(r)emove [names] - Add or remove player from you auto accept whitelist.
* 9: blacklist (a)dd|(r)emove [names] - Add or remove player from you auto decline blacklist.
* 10: auto_accept_enable (t)rue|(f)alse - Turn on or off the auto accept invite and request function. `default: true`
* 11: auto_decline_enable (t)rue|(f)alse - Turn on or off the auto decline invite and request function. `default: false`
* 12: default (a)sk|(w)hitelist|(b)lacklist - Set the default action for unhandled invites. `default: ask`

----

#### To do: ####
* Implement party invite response packet injection.
* Add config gui.
