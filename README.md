
<!--#echo json="package.json" key="name" underline="=" -->
minecraft-nether-roof-biomes-marker
===================================
<!--/#echo -->

<!--#echo json="package.json" key="description" -->
In Minecraft, on the nether roof, use creative mode commands to mark biomes
with blocks of your choice. .
<!--/#echo -->



How it works
------------

The script will `/teleport` you to pre-defined places in a grid,
guess biome from sky color, and `/setblock` a marker block accordingly.

If you have WorldEdit installed, it can even mark huge areas much more
efficiently than the `/teleport` + `/setblock` approach.
See "Using WorldEdit" below.



### This is a crutch.

There were some mods that had way better ways of showing biome borders,
especially because they change with elevation.
If you know how to port them to modern Minecraft, please do so.

Good candidates I found so far:

* [Bounding Box Outline Reloaded
  ](https://github.com/irtimaled/BoundingBoxOutlineReloaded/issues/)

Less promising candidates but maybe worth observing:

* A biome map feature was also
  [requested for Xaero's World Map][xaero-issue-cf135].
  * Xaero's World Map Settings have an option "Biomes in Vanilla Mode"
    but I have no idea what it does or how to enable Vanilla Mode.
* [Biome Border Viewer
  ](https://www.curseforge.com/minecraft/mc-mods/biome-border-viewer)
  looks ancient, dead, and isn't free software; so even if we could
  update it, we wouldn't have permission to do so.


  [xaero-issue-cf135]: https://legacy.curseforge.com/minecraft/mc-mods/xaeros-world-map/issues/135



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
1.  Ensure you're in spectator mode.
1.  Via your remote control mechanism, run `./nrbm.sh tmp.rc`
    * If you want to slow down the setblock part in order to observe how
      this script works, you can just append ` slow_setblock.rc`
      to the command line.


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
`radius`, `ccx`, `ccz` and maybe `extra_floors`.
In that case, you might consider passing them as command line
options rather than using a custom config file.


### Why spectator mode?

Flying in creative has most of the features we'd need:

* Resist gravity
* Resist suffocation
* Resist most other damage
  * Void damage won't be relevant since we're usually in building range.

However, creative mode interferes with our teleportations
if the destination happens to have a solid block, because
your feet will automatically evade it if they can,
thereby messing up the location of our sampling.



Reverting failed attempts
-------------------------

You can automaticaly generate WorldEdit commands to fix it:

`./nrbm.sh task=revert_preview radius=300`

It uses multiple replace commands because of chat message length limits.

If you like the commands, you can have them sent to chat by
omitting the `_preview` part:

`./nrbm.sh task=revert radius=300`

Or you can write the preview to a file, adjust it, and then have that
sent to chat:

`./nrbm.sh task=stdin2chat <revert.txt`



### Using WorldEdit

I was blinded by all the forum threads where people discussed potential mods,
but found none. I accepted the apparent lack of solutions too easily.
Indeed it's a bit hidden in the docs, but WorldEdit can do it,
using the [Biome Mask][we-biome-mask].

1.  Hover with your feet at the center of the area where you want the marker
    blocks to be placed.
1.  To mark all biomes within X/Z ± 300 blocks around your feet:
    `./nrbm.sh slabs.rc we=300`

* The "we" (WorldEdit) mode will generate the `setblock_cmd` template
  for each nether biome, find the first unconditional command that
  starts with `/setblock %x %y %z `, and use the remainder of the line
  as the material with which to replace all `air` and `cave_air`.
* The example loads the `slabs.rc` config because in the carpets from
  the default config would be rather fragile when placing in midair.
* (Not available yet) For the overworld, add option `b=ow`.
* (Not available yet) For the end, add option `b=end`.
* You can also give a custom list of biome IDs, e.g. ` b=forest,ocean,desert`

  [we-biome-mask]: https://worldedit.enginehub.org/en/latest/usage/general/masks/#biome-mask





<!--#toc stop="scan" -->



Known issues
------------

* It's a crutch. (See above.)
* Needs more/better tests and docs.




&nbsp;


License
-------
<!--#echo json="package.json" key=".license" -->
ISC
<!--/#echo -->
