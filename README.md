
<!--#echo json="package.json" key="name" underline="=" -->
minecraft-nether-roof-biomes-marker
===================================
<!--/#echo -->

<!--#echo json="package.json" key="description" -->
In Minecraft, on the nether roof, use creative mode commands to mark biomes
with blocks of your choice. .
<!--/#echo -->



This is a crutch.
-----------------

There were some mods that had way better ways of showing biome borders,
especially because they change with elevation.
If you know how to port them to modern Minecraft, please do so.

Good candidates I found so far:

* [Bounding Box Outline Reloaded
  ](https://github.com/irtimaled/BoundingBoxOutlineReloaded/issues/)




How it works
------------

The script will `/teleport` you to pre-defined places in a grid,
guess biome from sky color, and `/setblock` a marker block accordingly.



Usage
-----

1.  Use Ubuntu focal or later and Minecraft Java 1.19.4.
1.  Copy `defaults.rc` to `tmp.rc`.
1.  Edit `tmp.rc` to set job options.
1.  Prepare a way to interact with the command line while Minecraft has
    the input focus. SSH is a good way to achieve this.
1.  Start Minecraft, open your world.
1.  Ensure you do have the `/teleport` and `/setblock` commands available.
    * One way to do this is to type `/telep` and `/setbl` into ingame chat
      and see whether it suggests the full command name.
      Chat should only do so if the commands are enabled.
    * If your world usually doesn't allow commands, you can temporarily
      override this by selecting "Open to LAN" and checking the
      "Allow cheats" checkbox.
      Depending on your LAN you may want to set joining player's game mode
      to spectator, adventure, and/or double-check your firewall rules.
1.  Ensure you're invulnerable and not affected by gravity.
    (Spectator mode or flying in creative mode.)
1.  Aim straight up, i.e. as high into the sky as you can.
1.  Via your remote control mechanism, run `./nrbm.sh tmp.rc`


### `nrbm.sh` command line arguments

… may be `key=value` pairs for config options,
or a config filename to run as bash code.

Config filenames may be preceeded by `=`, which will be ignored.
Always prepend `=` in cases where the config filename might contain a `=`
character, because otherwise it might be interpreted as a config option.


### About editing the config file

You may omit options for which you like the default,
because `defaults.rc` will always be read first.

It might turn out that the only options you need are
`radius` and maybe `extra_floors`.
In that case, you might consider passing them as command line
options rather than using a custom config file.





<!--#toc stop="scan" -->



Known issues
------------

* Needs more/better tests and docs.




&nbsp;


License
-------
<!--#echo json="package.json" key=".license" -->
ISC
<!--/#echo -->
