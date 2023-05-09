
Trackball Camera for Godot
--------------------------

[![MIT](https://img.shields.io/github/license/Goutte/godot-trackball-camera.svg?style=for-the-badge)](https://github.com/Goutte/godot-trackball-camera)
[![Release](https://img.shields.io/github/release/Goutte/godot-trackball-camera.svg?style=for-the-badge)](https://github.com/Goutte/godot-trackball-camera/releases)
[![FeedStarvingDev](https://img.shields.io/liberapay/patrons/Goutte.svg?style=for-the-badge&logo=liberapay)](https://liberapay.com/Goutte/)

A [Godot](https://godotengine.org/) `4.x` addon that adds a `TrackballCamera` node without gimbal lock.

The `TrackballCamera` responds to input from mouse, keyboard, joystick and touch, in order to rotate around its parent node while facing it.

A version for Godot `3.x` [is available as well](https://github.com/Goutte/godot-trackball-camera/releases/tag/v6.0).
A version for Godot `2.x` [is available as well](https://github.com/Goutte/godot-trackball-camera/releases/tag/v1.0).


Features
--------

- stays around its parent node, even if the latter moves
- no gimbal lock (quaternions 🌟)
- camera inertia for a smoother experience (can be disabled)
- horizon can be stable or free
- the parent node does not have to be centered in the camera's view
- analog camera control with joystick, courtesy of [@marcello505](https://github.com/marcello505) (in [#4](https://github.com/Goutte/godot-trackball-camera/pull/4))
- a bunch of parameters to configure everything as you want it


Install
-------

The installation is as usual, through the [Assets Library](https://godotengine.org/asset-library/asset?user=Goutte).
You can also simply copy the files of this project into yours, it should work.

Then, enable the plugin in `Scene > Project Settings > Plugins`.


Usage
-----

Make the `TrackballCamera` a child of the `Node3D` to trackball around.
Make sure your camera initially faces said node, and is at a proper distance from it.
The initial position of your camera matters. The node does not need to be in the center of the camera's view.

You can also use this camera to look around you if you place it atop its parent node, spatially.
It's going to rotate around itself, and that amounts to looking around.
You'll probably want to set `mouse_invert` and `keyboard_invert` to true in that case.


Todo
----

- [ ] Test if touch works on android and html5, try `SCREEN_DRAG` otherwise. (see [#6](https://github.com/Goutte/godot-trackball-camera/issues/6))
- [ ] Fix drift glitch when inertia is disabled and pitch limits are enabled.


Feedback and contributions are welcome!


