
Gateway Positions
=================

All the gateway blocks are at Y=75. For teleporting on top, use Y=78 instead.

Both Minecraft Wikis have a numbered list of coordinates of the gateway blocks,
where the numbers start at the eastern gateway and then count counter-clockwise
seen from above.
The exact positions have had some minor fluctuations between wikis and date
([example][gwpos-mcf-2403], [example][gwpos-mcf-2409],
[example][gwpos-mcw-2403], [example][gwpos-mcw-2409]).
You can use `../../../nrbm.sh gateway_positions.rc t=download`
to download the examples for easy comparison.

The differences in coordinates made me distrust all of them, so I made
[my own list](gateway_positions.tsv) based on my current MC 1.21 main world.
It's very similar to [gwpos-mcw-2403][gwpos-mcw-2403] except most negative
numbers are one lower.
This might be a clue that Mojang may have updated the rounding mechanism
to more accurately position the towers at the exact radius.
This hunch is corroborated by the observation that the average distance in
that wiki table is 95.48778&nbsp;m, while in my list it's 96.02026&nbsp;m.

Later I discovered that my list perfectly matches
[an old version of one of the wiki pages][gwpos-mcw-2403],
which means either Mojang reverted their fix back to the older, less accurate
positions, or that one wiki had the up-to-date, correct information
and then reverted it. ¯&#92;&#95;(ツ)&#95;/¯




Installing a preview into your world
------------------------------------

The main purpose of `gateway_positions.rc` is the `t=preview` mode,
which is also the default. That mode will generate `/setblock` commands
to mark the gateway positions by placing blocks above where the gateways
would be generated, so you can consider them when building other stuff.

You can use the `b=` parameter to define which blocks to use,
separated by one or more space characters, listed from bottom to top,
lower blocks will be placed first. The default is `glowstone iron_bars`.

If you have Xaero's Minimap, you can use `t=xaerowp` to generate waypoints
for the air blocks on top of the gateways as less invasive markers.



Generating platforms
--------------------

If you have WorldEdit, you can use `t=platforms` to build platforms around
each gateway. To avoid accidents,
* backup your central end island, becuase the amount of commands may exceed
  the undo buffer.
* ensure you are in spectator or creative gamemode.
* `//gmask air,cave_air`

The platforms will have water on the floor for easy swimming into the
gateway, and one water on head level for easily initiating swimming mode.
Except for the water, they are made entirely of end stone, because that
and water are two materials that the ender dragon cannot destroy.

An additional end stone block is placed slightly elevated in order to give
a predictable arrival position from which you will drop into the water in
case you arrive with some remaining momentum, e.g. because you swam into
the remote gateway. For extra safety, first swim between the bedrock blocks
so you are next to the portal, stop there, then touch the portal with minimal
movement.



Bridges between platforms
-------------------------

If you then want bridges connecting those platforms, an easy way to do it
is to make a ring with WorldEdit. In WorldEdit terms, a "ring" is a 1-high
hollow cylinder. At time of writing this, WorldEdit apparently
can render those [only with thickness 1][we-cmd-cyl],
its [cylindrical selection mode][we-cmd-sel-cyl] cannot be hollow,
and cannot [subtract from a selection][we-fr-subtract-from-selection],
[the current best solution seems to be][reddit-c-1828f8u]
to generate multiple circles with slightly increasing radii.

However, with the amount of `//hcyl` commands we'd need, it's easier to
work with lots of `//gmask` and temporary blocks.
If you actually use any `structure_void` in proximity of the central end
island, replace that block name with a block you don't use.
Also, do standard precautions with water and lava, as the temporary blocks
of the temporary inner disk could mess with their flow.

If you want to use creative mode instead of spectator, make sure your
teleport position is honored, i.e. your position after teleport has not
been adjusted to avoid solid blocks, and you're not subject to block
interactions.

```text
/gamemode spectator
/teleport @s 0 73 0
//pos1
//pos2
//expand 100 n,s,w,e
//gmask
//replace structure_void air
//gmask air
//cyl structure_void 93 1
//gmask structure_void
//cyl air 85 1
//set end_stone
//gmask
```











  [gwpos-mcf-2403]: https://web.archive.org/web/20240317233056/https://minecraft.fandom.com/wiki/End_gateway
  [gwpos-mcf-2409]: https://web.archive.org/web/20240917101027/https://minecraft.fandom.com/wiki/End_gateway
  [gwpos-mcw-2403]: https://web.archive.org/web/20240303094805/https://minecraft.wiki/w/End_gateway
  [gwpos-mcw-2409]: https://web.archive.org/web/20240912070533/https://minecraft.wiki/w/End_gateway
  [reddit-c-1828f8u]: https://old.reddit.com/r/WorldEdit/comments/1828f8u/
  [we-cmd-cyl]: https://worldedit.enginehub.org/en/latest/usage/generation/#cylinders
  [we-cmd-sel-cyl]: https://worldedit.enginehub.org/en/latest/usage/regions/selections/#selection-modes
  [we-fr-subtract-from-selection]: https://github.com/EngineHub/WorldEdit/issues/1252
