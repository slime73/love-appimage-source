love-appimage-source
=====

Creates LOVE AppImage by compiling every single dependency from source.

Build
-----

You may want to grab all dependencies required by SDL, but **not** the SDL itself.

Afterwards, run `make`. `love-master.AppImage` (by default) will be generated. See the Makefile script for various tweakable variables.

License
-----

Public domain will do, except AppRun.c which is modified based on AppImage's default AppRun.c
