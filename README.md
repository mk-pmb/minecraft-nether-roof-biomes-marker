
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



Using WorldEdit
---------------

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
* You can also give a custom list of biome IDs, e.g. ` b=forest,ocean,desert`
* You can use `b=@path/to/file.txt` to read the list of biomes from a file.
  * If the file path doesn't contain a slash, it's treated as one of the
    built-in lists, which means `.txt` is appended and the path adjusted
    to inside `data/biome_shortnames/`.
* You can use `b=<some/path/list.txt` (your shell may require quoting)
  to read the biomes list from any file.

  [we-biome-mask]: https://worldedit.enginehub.org/en/latest/usage/general/masks/#biome-mask


### A note on WorldEdit's RAM usage

WorldEdit devs seem to consider it _your_ job as the user to divide the
area to be worked on into portions small enough to fit your RAM. &rarr;
[not-a-bug #2343](https://github.com/EngineHub/WorldEdit/issues/2343)

NRBM has some makeshift work-arounds for this, which are described in the
modes that offer them.

However, this still seems to leak memory, so you'd better
__restart Minecraft before and after you use NRBM__ in WE mode.

In a multiplayer scenario, you may have to restart the server.
I haven't tested that. If you do have to, it's probably not a WE bug,
but rather your fault for using stock WE on large areas.

(Because why bloat the main mod if you can solve it yourself?
Feel free to write your own mod that does the dividing and then calls the
WE API for each sub-region. Or you could just install/assign more RAM. 🤷)


### Alternative: Mark chunk corners

Specify `we=cc` to use WorldEdit to mark chunk corners.

* ⚠ For correct operation, ensure you are in creative mode and you are flying!
  * It might work in spectator mode as well if spectators generate terrain or
    all chunks for the entire target area are already generated.
    See also the `tour=` option below.
* RAM usage work-around:
  Chunk corners mode operates on a slice of the area
  (the "air" side, see option `a=` below) and then progressively stacks it,
  and also progressively moves the selection for marker block replacements.

This enables additional options, listed here with their default values:

* `x=0` and `z=0`: The chunk coordinates of the chunk to be marked,
  as given in the "Chunk:" line in the debug screen.
  * To mark multiple consecutive chunks, you can give minimum and maximum
    values separated by two dots, e.g. `x=-10..10 z=30..50`
  * A shorthand notation for origin-centered ranges is available:
    `x=+-5 z=+-8` is equivalent to `x=-5..5 z=-8..8`.
    * The Unicode variant `x=±5 z=±8` should work as well,
      if your bash and terminal play together nicely.
    * If you want to mirror on the 0/-1 block coordinate, with `n` chunks
      on either side, you may use the shorthand `[xz]=:n`, e.g.
      `x=:5 z=:8` which will be equivalent to `x=-5..4 z=-8..7`.
  * Shorthand for setting the `x` and `z` to the same value: `x=z=±20`
* `y=160`: The height at which to place the marker blocks.
  * You can also give a comma-separated triplet of minimum, gap and maximum:
    `y=140,19,180` will create three floors, with 19 blocks gap between them,
    at height levels 140, 160, and 180.
  * ⚠ When you use decorations above or below the marker blocks,
    the effective target area will grow accordingly,
    beyond the marker block range given in `y=`.
* `a=n`: The "air" side of the region to be marked.
  Must be one of the letters `news` to denote north, east, west or south.
  In chunks on that border of the target area, everything in the affected
  height range (including what will become be the gaps) will be cleared
  (set to air).
  * You may also use `a=a` to clear the entire target area.
  * Currently, only `a=n` and `a=a` are implemented.
* `b=n`: Biomes list as described above.
* `t=structure_block`:
  A temporary block to mark the corners for shape only.
  They will then later be replaced by the actual biome marker materials.
  The temporary block should be something that did not originally exist in
  the area to be marked.
  It should also be something robust that doesn't change block state
  (fall, decay, pop, melt, …) on its own.
* `above=.`:
  Dot (`.`) for no effect, or a block name to put above every marker block.
  * ⚠ The effective target area will grow to one block above the `y=` range.
* `below=glowstone`:
  Dot (`.`) for no effect, or a block name to put below every marker block.
  * ⚠ The effective target area will grow to one block below the `y=` range.
* `tour=0,0`:
  When the first number is positive, rather than actually marking stuff,
  just teleport around the target area in steps of (first number) chunks.
  At each position, wait (second number) seconds for the world to generate.
  * `mapkey=`: When set, press this key after each tour teleport,
    and press the Escape key before each subsequent teleport command.
  * `skip=0`: When positive, skip the first `skip` steps.
  * `pat=zx`: Which pattern to walk.
    * `zx`: Start at north-west corner, travel east,
      jump back to west but one step south, and travel east again.
    * `cws`: Clock-wise spiral.
      Not yet implemented.
      Traveling in a spiral will hopefully make it easier to
      skip the inner area when expanding outwards.









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
