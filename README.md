love-appimage-source
=====

A Makefile script that builds LÖVE AppImage by compiling every single dependency from source.

Build
-----

First, install these dependencies (adapt accordingly for non-Debian distro):

```sh
sudo apt-get install autotools-dev automake autoconf libtool patchelf
```

Then followed by [all dependencies required by SDL](https://github.com/libsdl-org/SDL/blob/main/docs/README-linux.md#build-dependencies), but **not** the SDL itself.

Afterwards, run `make`. `love-main.AppImage` and `love-main.tar.gz` (by default) will be generated. See the Makefile script for various tweakable variables.

Notes:
* If you're getting FUSE error in Ubuntu 22.04 or later, install `libfuse2`. Ubuntu 22 start switching to FUSE 3 which is NOT SUPPORTED by AppImage!
* For Ubuntu ARM64, ff APT can't find `libsndio-dev` and `fcitx-libs-dev`, make sure to add `universe` repository!
* If you're running WSL 1, run with `make QEMU=env` to bypass FUSE requirement restrictions by extrating `appimagetool` first.

License
-----

Public Domain
