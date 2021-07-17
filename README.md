love-appimage-source
=====

Creates LOVE AppImage by compiling every single dependency from source.

Build
-----

You may want to grab [all dependencies required by SDL](https://github.com/libsdl-org/SDL/blob/main/docs/README-linux.md#build-dependencies), but **not** the SDL itself.

Note for Ubuntu ARM64: If APT can't find `libsndio-dev` and `fcitx-libs-dev`, make sure to add `universe` repository!

Afterwards, run `make`. `love-master.AppImage` (by default) will be generated. See the Makefile script for various tweakable variables.

License
-----

Public domain will do, except AppRun.c which is modified based on AppImage's default AppRun.c
