# Bomberman

A clone of the classic mazed based arcade game, Bomberman, originally released in 1983 by Hudson Soft. Written in ARM Assembly. Tested and developed on the NXP LPC2138 with ARM7TDMI-S CPU.
```
	    Bomberman
Time:120       Score:0000
ZZZZZZZZZZZZZZZZZZZZZZZZZ
ZB                     xZ
Z Z Z Z Z Z Z Z Z Z Z Z Z
Z                       Z
Z Z Z Z Z Z Z Z Z Z Z Z Z
Z                       Z
Z Z Z Z Z Z Z Z Z Z Z Z Z
Z                       Z
Z Z Z Z Z Z Z Z Z Z Z Z Z
Z                       Z
Z Z Z Z Z Z Z Z Z Z Z Z Z
Zx                     +Z
ZZZZZZZZZZZZZZZZZZZZZZZZZ
```

The objective of the game is to score as many points as possible without running out of lives within the 120 second time limit of the game. Points are scored by:
<ul>
<li>Killing an enemy (‘x’ or ‘+’) with a bomb (+10 points * current level)</li>
<li>Destroying a brick wall (‘#’) with a bomb (+1 point * current level)</li>
<li>Completing a level by killing all of the enemies (+100 points)</li>
<li>Finishing the game without dying within the 120 second time limit (+25 points for each life remaining)</li>
</ul>

Bomberman initially has 4 lives. Once all the lives are lost, the game ends, so try not to lose them all! Additionally, as each level is completed the next one becomes faster with more brick walls, which makes scoring points and evading enemies much more difficult. 

The game can also be paused and subsequently resumed at any time by pressing the external interrupt button on the LPC2138.

As a placed bomb detonates, game state changes, or a life is lost, the GPIO peripherals attached to the LPC2138 will change in order to provide a retroactive and old school arcade like gameplay experience. This includes the RGB LED blinking for an additional detonation effect, and changing colors when the game state changes (active, non-active, paused, game over, etc.) The LED array also indicates how many lives Bomberman has left.

Happy Bombing!
