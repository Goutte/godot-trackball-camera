
TrackballCamera for Godot
-------------------------

[![MIT](https://img.shields.io/github/license/Goutte/godot-trackball-camera.svg)](https://github.com/Goutte/godot-trackball-camera)
[![Release](https://img.shields.io/github/release/Goutte/godot-trackball-camera.svg)](https://github.com/Goutte/godot-trackball-camera/releases)
[![Donate](https://img.shields.io/badge/%CE%9E-%E2%99%A5-blue.svg)](https://etherscan.io/address/0xB48C3B718a1FF3a280f574Ad36F04068d7EAf498)


A simple [Godot](https://godotengine.org/) `2.1` addon that adds a `TrackballCamera` without gimbal lock.

The `TrackballCamera` responds to input from mouse, keyboard, joystick and touch, in order to rotate around its parent node while facing it.


Features
--------

- stays around its parent node, even if it moves
- no gimbal lock (quaternions FTW)
- camera inertia for a smoother experience
- the parent node does not have to be centered in the camera's view
- a bunch of parameters to configure everything as you want it


Install
-------

The installation is as usual : copy this project as a subdirectory of your `addons/` directory.

```
cd <myproject>/addons
git clone https://github.com/Goutte/godot-trackball-camera trackball_camera
```

Then, enable the plugin in `Scene > Project Settins > Plugins`.


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
- [ ] Update to Godot `3.0` upon release


Feedback and contributions are welcome!


