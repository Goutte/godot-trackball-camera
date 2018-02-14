
TrackballCamera for Godot
-------------------------

[![MIT](https://img.shields.io/github/license/Goutte/godot-trackball-camera.svg)](https://github.com/Goutte/godot-trackball-camera)
[![Release](https://img.shields.io/github/release/Goutte/godot-trackball-camera.svg)](https://github.com/Goutte/godot-trackball-camera/releases)
[![Donate](https://img.shields.io/badge/%CE%9E-%E2%99%A5-blue.svg)](https://etherscan.io/address/0xB48C3B718a1FF3a280f574Ad36F04068d7EAf498)

A simple [Godot](https://godotengine.org/) `3.x` addon that adds a `TrackballCamera` without gimbal lock.

The `TrackballCamera` responds to input from mouse, keyboard, joystick and touch, in order to rotate around its parent node while facing it.

A version for Godot `2.x` [is available as well](https://github.com/Goutte/godot-trackball-camera/releases/tag/v1.0).


Features
--------

- stays around its parent node, even if it moves
- no gimbal lock (quaternions FTW)
- camera inertia for a smoother experience
- the parent node does not have to be centered in the camera's view
- a bunch of parameters to configure everything as you want it


Install
-------

The installation is as usual, through the Assets Lib.
Then, enable the plugin in `Scene > Project Settings > Plugins`.

You can also simply copy the files of this project into yours, it should work.


Usage
-----

Make the `TrackballCamera` a child of the node to trackball around.
Make sure your camera initially faces said node, and is at a proper distance from it.
The initial position of your camera matters. The node does not need to be in the center.

You can also use this camera to look around you if you place it atop its parent node, spatially.
It's going to rotate around itself, and that amounts to looking around.
You'll probably want to set `mouseInvert` and `keyboardInvert` to true in that case.


Todo
----

- [ ] Test if touch works on android and html5, try `SCREEN_DRAG` otherwise.


Feedback and contributions are welcome!


