**Author:** Nifim<br>
**Version:** 0.7.0.0<br>
**Date:** July. 14, 2018<br>

# Party Time #

* Automaticly accept or decline invites.
* Send party requests which can be automaticly accepted by PT users
* Provide dialog for accepting and declining invites or requests

----

**Main Command:** No full name command line. only /pt

#### Commands: ####
* 1: (j)oin [name] - Send invite request to a player.
* 2: (i)nvite [names] - invite player or players to join your party
* 3: (w)hitelist invite|request (a)dd|(r)emove [names] - add ore remove player from you auto accept whitelist.
* 4: (b)lacklist invite|request (a)dd|(r)emove [names] - add ore remove player from you auto decline blacklist.

* 5: ui_enable on|off - Turn on or off the invite and request pop-up dialogs. `defualt: on`
* 6: auto_accept on|off - Turn on or off the auto accept invite and request function. `defualt: on`
* 7: auto_decline on|off - Turn on or off the auto decline invite and request function. `defualt: off`

----

#### To do: ####
* Implement party invite response packet injection
* Add config gui.
