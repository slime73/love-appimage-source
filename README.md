love-appimage-source
=====

Creates LOVE AppImage by compiling every single dependency from source.

Build
-----

You may want to grab [all dependencies required by SDL](https://github.com/libsdl-org/SDL/blob/main/docs/README-linux.md#build-dependencies), but **not** the SDL itself.

Note for Ubuntu ARM64: If APT can't find `libsndio-dev` and `fcitx-libs-dev`, make sure to add `universe` repository!

Afterwards, run `make`. `love-main.AppImage` (by default) will be generated. See the Makefile script for various tweakable variables.

If you're running WSL 1, run `make QEMU=env` instead to bypass FUSE requirement restrictions by extrating `appimagetool` somewhere else first.

License
-----

* AppRun.c is based on default AppImage's AppRun.c thus it's under MIT license.

* The rest is public domain.
