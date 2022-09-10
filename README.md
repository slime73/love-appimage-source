love-appimage-source
=====

Creates LOVE AppImage by compiling every single dependency from source.

Build
-----

You may want to grab `patchelf` and [all dependencies required by SDL](https://github.com/libsdl-org/SDL/blob/main/docs/README-linux.md#build-dependencies), but **not** the SDL itself.

Note for Ubuntu ARM64: If APT can't find `libsndio-dev` and `fcitx-libs-dev`, make sure to add `universe` repository!

Afterwards, run `make`. `love-main.AppImage` and `love-main.tar.gz` (by default) will be generated. See the Makefile script for various tweakable variables.

If you're running WSL 1, run with `make QEMU=env` to bypass FUSE requirement restrictions by extrating `appimagetool` first.

License
-----

Public Domain
