**Author:** Nifim<br>
**Version:** 0.7.0.0<br>
**Date:** July. 14, 2018<br>

# Party Time #

* Automaticly accept or decline invites.
* Send party requests which can be automaticly accepted by PT users.
* Provide dialog for accepting and declining invites or requests.

----

**Main Command:** No full name command line. only `/pt`

#### Commands: ####
* 1: (i)nvite [names] - Invite a player or players to join your party.
* 2: (r)equest [name] - Send an invite request to a player.
* 3: (w)hitelist (a)dd|(r)emove [names] - Add or remove player from you auto accept whitelist.
* 4: (b)lacklist (a)dd|(r)emove [names] - Add or remove player from you auto decline blacklist.
* 5: auto_accept on|off - Turn on or off the auto accept invite and request function. `default: on`
* 6: auto_decline on|off - Turn on or off the auto decline invite and request function. `default: off`
* 7: default (a)sk|(w)hitelist|(b)lacklist - Set the default action for unhandled invites. `default: ask`

----

#### To do: ####
* Implement party invite response packet injection.
* Expand to include more `/pcmd` functions.
* Add config gui.
