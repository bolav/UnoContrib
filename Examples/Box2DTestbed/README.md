# Box2D Test Bed

This is a example of using `Uno.Physics.Box2D` in Uno and gain access to a powerful physics engine straight from Realtime Studio. 

This implements two demos. One from the official Box2D test bed and one inspired by a official test bed demo.

## Demos
### Falling blocks

![Falling blocks screenshot](http://i.imgur.com/rIgtU4x.png)

This demo features up to two hundred blocks falling down to a center. When they fall out of the center position and onto the
lower ground they disappear into the abyss.

You can click and drag the blocks and as such interact with the environment.

### Pulley Joint

![](http://i.imgur.com/6J6OIyv.png)

This is a simple joint demonstration with two pulleys and a ground. 

**NOTE** Sometimes (as seen on the screenshot) the ropes disappear. The reason is unknown.

## Install instructions

You **need** the `Uno.Physics.Box2D` library.

From `UnoContrib/Packages/` copy the `Uno.Physics.Box2D` folder to your Outracks installation directory\Packages. (for example: `C:\Program Files (x86)\Outracks Technologies\Realtime Studio Beta\Packages`.

Then you're ready to experiment. You can interact in Preview mode with the dynamic (red) objects by clicking and dragging them around.

## Notes / Known bugs/issues
* The demos will run nice on both Windows and Android. WebGL encounters some performance issues due to a issue in the Uno WebGL Backend.