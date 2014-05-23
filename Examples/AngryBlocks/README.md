# Angry Blocks

This is a example of using `Uno.Physics.Box2D` in Uno and gain access to a powerful physics engine straight from Realtime Studio. 

It is a simple implementation of the popular game Angry Birds and features a level editor in the designer as well as multiple 
rendering methods (and it was created in less then two working days).

![](http://i.imgur.com/nOOOSCw.png?1)

The game leverages both Box2Ds Debug Drawer (which provides verticies to you to render on the screen) and a custom
Uno Drawer for the circles.

Instead of the sling shot the game features a cannon that fires cubes.

## Install instructions

You **need** the `Uno.Physics.Box2D` library.

From `UnoContrib/Packages/` copy the `Uno.Physics.Box2D` folder to your Outracks installation directory\Packages. 
(for example: `C:\Program Files (x86)\Outracks Technologies\Realtime Studio Beta\Packages`.

Then you're ready to play. You fire by clicking with the mouse. The distance between the mouse and the cannon 
(as shown by the yellow line) determines the force of the shot.

## Level Editor
This example adds level editor possibilities to the Realtime Studio designer.

It does not support using the already existing Gizmos (and unfortionally there were no time to find out how to add 
custom Gizmos).

![](http://i.imgur.com/lt3uO1K.png)

Levels are constructed from `PhysicsBlock`, `PhysicsTriangle` and  `PhysicsBall`.

The `MaxImpulse` parameter defines how hard the impulse can be from a collision between two objects before a given object 
will break (disappear).

`BodyType` controls the Box2D BodyType. In the debug drawer you'll see the various types colour coded (Green = Static, 
Red = Dynamic, Purple = Kinetic).

## Notes / Known bugs/issues
* The game will run nice on both Windows and Android. WebGL encounters some performance issues due to a issue in the 
Uno WebGL Backend.

* When you delete nodes from the designer then will not disappear (in the Debug Drawer) until you've clicked 
`Refresh Designer`. (The reason is that the nodes aren't unregistered from Box2D).

* The game does not have a score system and you can fire as many cannon blocks as you'd like. 
This is a simple demo, not a full implementation of Angry Birds :)

* The mouse click doesn't always respond. I do not believe this to be an issue with this application as it only uses Unos
`Uno.Scenes.Input#IsPointerDownTriggered()` function.