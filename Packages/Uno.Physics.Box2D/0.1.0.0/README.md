# Box2D Sample implementation

This repository contains a port of [Box2D.XNA](https://box2dxna.codeplex.com/) For Uno.

This implementation is only for **demonstration purposes and is not of production quality**. 
It is based on Box2D XNA and as such runs version r112 of Box2D. (To the current date that is over 200 
revisions old, and as such many tweaks and improvements made to the original Box2D project is missing).

## Example of use
See `Examples/Angry Blocks/` in the `UnoContrib` Git repository.

See [Tutorial: Using Box2D @ Outracks Beta Zone](https://beta.outracks.com/tutorials/using_box2d)

## Author
Original port made by Liam S. Crouch.

Arne-Christian Blystad made some improvements to make it run in WebGL

## Known limitations

This version is very old (r112). We lack many improvements and additions that were made to Box2D since r112.

The WebGL performance is horrible. The reason for this is due to the use of `$CreateRef` which the Google V8 
JavaScript compiler cannot optimize to native code. A detailed report on these findings can be found on the 
[Outracks Beta Zone forums](https://beta.outracks.com/forum/bugreports/703).