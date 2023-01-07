# Makefile script to generate AppImage for LOVE

# Number of processor to use when compiling
NUMBER_OF_PROCESSORS := $(shell nproc)

# CPU architecture, defaults to host
ARCH := $(shell uname -m)

# CMake URL
CMAKE_URL := https://github.com/Kitware/CMake/releases/download/v3.25.1/cmake-3.25.1-linux-$(shell uname -m).sh

# Project branches (for git-based projects)
LOVE_BRANCH := 12.0-development
SDL2_BRANCH := release-2.26.1
LUAJIT_BRANCH := v2.1
OPENAL_BRANCH := 1.22.2
BROTLI_BRANCH := v1.0.9
ZLIB_BRANCH := v1.2.13
HARFBUZZ_BRANCH := 6.0.0

# Project versions (for downloadable tars)
LIBOGG_VERSION := 1.3.5
LIBVORBIS_VERSION := 1.3.7
LIBTHEORA_VERSION := 1.2.0alpha1
FT_VERSION := 2.12.1
BZIP2_VERSION := 1.0.8
LIBMODPLUG_VERSION := 0.8.8.5

# Output AppImage
APPIMAGE_OUTPUT := love-$(LOVE_BRANCH).AppImage

# Output tar
TAR_OUTPUT := love-$(LOVE_BRANCH).tar.gz

# No need to change anything beyond this line
override INSTALLPREFIX := $(CURDIR)/installdir

override CMAKE_PREFIX := $(CURDIR)/cmake
CMAKE := $(CMAKE_PREFIX)/bin/cmake
override CMAKE_OPTS := --install-prefix $(INSTALLPREFIX) -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_INSTALL_RPATH='$$ORIGIN/../lib'
override CONFIGURE := LDFLAGS="-Wl,-rpath,'\$$\$$ORIGIN/../lib' $$LDFLAGS" ../configure --prefix=$(INSTALLPREFIX)

# CMake setup
ifeq ($(SYSTEM_CMAKE),)
cmake_install.sh:
	curl $(CURL_DOH_URL) -Lo cmake_install.sh $(CMAKE_URL)
	chmod u+x cmake_install.sh

$(CMAKE): cmake_install.sh
	mkdir cmake
	bash cmake_install.sh --prefix=$(CMAKE_PREFIX) --skip-license
	touch $(CMAKE)
else
CMAKE := $(CURDIR)/cmakewrapper.sh

$(CMAKE):
	which cmake
	echo $(shell which cmake) '$$@' > $(CMAKE)
	chmod u+x $(CMAKE)
endif

# cURL DoH URL
ifneq ($(DOH_URL),)
override CURL_DOH_URL := --doh-url $(DOH_URL)
endif

cmake: $(CMAKE)

# AppImageTool
appimagetool:
	curl $(CURL_DOH_URL) -Lo appimagetool https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-$(ARCH).AppImage
	chmod u+x appimagetool
ifneq ($(QEMU),)
# Extract the AppImageTool
	$(QEMU) ./appimagetool --appimage-extract
endif

# SDL2
override SDL2_PATH := SDL2-$(SDL2_BRANCH)

$(SDL2_PATH)/configure:
	git clone --depth 1 -b $(SDL2_BRANCH) https://github.com/libsdl-org/SDL $(SDL2_PATH)

$(SDL2_PATH)/build/Makefile: $(SDL2_PATH)/configure
	mkdir -p $(SDL2_PATH)/build
	cd $(SDL2_PATH)/build && $(CONFIGURE) --disable-video-wayland

installdir/lib/libSDL2.so: $(SDL2_PATH)/build/Makefile
	cd $(SDL2_PATH)/build && $(MAKE) install -j$(NUMBER_OF_PROCESSORS)
	strip installdir/lib/libSDL2.so

# libogg
override LIBOGG_FILE := libogg-$(LIBOGG_VERSION)

$(LIBOGG_FILE).tar.gz:
	curl $(CURL_DOH_URL) -Lo $(LIBOGG_FILE).tar.gz http://downloads.xiph.org/releases/ogg/$(LIBOGG_FILE).tar.gz

$(LIBOGG_FILE)/configure: $(LIBOGG_FILE).tar.gz
	tar xzf $(LIBOGG_FILE).tar.gz
	touch $(LIBOGG_FILE)/configure

$(LIBOGG_FILE)/build/Makefile: $(LIBOGG_FILE)/configure
	mkdir -p $(LIBOGG_FILE)/build
	cd $(LIBOGG_FILE)/build && $(CONFIGURE)

installdir/lib/libogg.so: $(LIBOGG_FILE)/build/Makefile
	cd $(LIBOGG_FILE)/build && $(MAKE) install -j$(NUMBER_OF_PROCESSORS)
	strip installdir/lib/libogg.so

# libvorbis
override LIBVORBIS_FILE := libvorbis-$(LIBVORBIS_VERSION)

$(LIBVORBIS_FILE).tar.gz:
	curl $(CURL_DOH_URL) -Lo $(LIBVORBIS_FILE).tar.gz http://downloads.xiph.org/releases/vorbis/$(LIBVORBIS_FILE).tar.gz

$(LIBVORBIS_FILE)/configure: $(LIBVORBIS_FILE).tar.gz
	tar xzf $(LIBVORBIS_FILE).tar.gz
	touch $(LIBVORBIS_FILE)/configure

$(LIBVORBIS_FILE)/build/Makefile: $(LIBVORBIS_FILE)/configure installdir/lib/libogg.so
	mkdir -p $(LIBVORBIS_FILE)/build
	cd $(LIBVORBIS_FILE)/build && $(CONFIGURE)

installdir/lib/libvorbis.so: $(LIBVORBIS_FILE)/build/Makefile
	cd $(LIBVORBIS_FILE)/build && $(MAKE) install -j$(NUMBER_OF_PROCESSORS)
	strip installdir/lib/libvorbis.so
	strip installdir/lib/libvorbisfile.so
	strip installdir/lib/libvorbisenc.so

# libtheora
override LIBTHEORA_FILE := libtheora-$(LIBTHEORA_VERSION)

$(LIBTHEORA_FILE).tar.gz:
	curl $(CURL_DOH_URL) -Lo $(LIBTHEORA_FILE).tar.gz http://downloads.xiph.org/releases/theora/$(LIBTHEORA_FILE).tar.gz

$(LIBTHEORA_FILE)/configure: $(LIBTHEORA_FILE).tar.gz
	tar xzf $(LIBTHEORA_FILE).tar.gz
# Their config.guess and config.sub can't detect ARM64
ifeq ($(ARCH),aarch64)
	curl $(CURL_DOH_URL) -o $(LIBTHEORA_FILE)/config.guess "https://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.guess;hb=HEAD"
	chmod u+x $(LIBTHEORA_FILE)/config.guess
	curl $(CURL_DOH_URL) -o $(LIBTHEORA_FILE)/config.sub "https://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.sub;hb=HEAD"
	chmod u+x $(LIBTHEORA_FILE)/config.sub
endif
	touch $(LIBTHEORA_FILE)/configure

$(LIBTHEORA_FILE)/build/Makefile: $(LIBTHEORA_FILE)/configure installdir/lib/libogg.so
	mkdir -p $(LIBTHEORA_FILE)/build
	cd $(LIBTHEORA_FILE)/build && $(CONFIGURE) --with-ogg=$(INSTALLPREFIX) --with-vorbis=$(INSTALLPREFIX) --disable-examples --disable-encode

installdir/lib/libtheora.so: $(LIBTHEORA_FILE)/build/Makefile
	cd $(LIBTHEORA_FILE)/build && $(MAKE) install -j $(NUMBER_OF_PROCESSORS)
	strip installdir/lib/libtheora.so
	strip installdir/lib/libtheoradec.so
	strip installdir/lib/libtheoraenc.so

# zlib
override ZLIB_PATH := zlib-$(ZLIB_BRANCH)

$(ZLIB_PATH)/configure:
	git clone --depth 1 -b $(ZLIB_BRANCH) https://github.com/madler/zlib $(ZLIB_PATH)

$(ZLIB_PATH)/build/Makefile: $(ZLIB_PATH)/configure
	mkdir -p $(ZLIB_PATH)/build
	cd $(ZLIB_PATH)/build && $(CONFIGURE)

installdir/lib/libz.so: $(ZLIB_PATH)/build/Makefile
	cd $(ZLIB_PATH)/build && $(MAKE) install -j$(NUMBER_OF_PROCESSORS)
	strip installdir/lib/libz.so

# Brotli
override BROTLI_PATH := brotli-$(BROTLI_BRANCH)

$(BROTLI_PATH)/CMakeLists.txt:
	git clone --depth 1 -b $(BROTLI_BRANCH) https://github.com/google/brotli $(BROTLI_PATH)

$(BROTLI_PATH)/build/CMakeCache.txt: $(CMAKE) $(BROTLI_PATH)/CMakeLists.txt
	$(CMAKE) -B$(BROTLI_PATH)/build -S$(BROTLI_PATH) $(CMAKE_OPTS)

installdir/lib/libbrotlidec.so: $(BROTLI_PATH)/build/CMakeCache.txt
	$(CMAKE) --build $(BROTLI_PATH)/build --target install -j $(NUMBER_OF_PROCESSORS)
	strip installdir/lib/libbrotlicommon.so
	strip installdir/lib/libbrotlidec.so
	strip installdir/lib/libbrotlienc.so

# OpenAL-soft
override OPENAL_PATH := openal-soft-$(OPENAL_BRANCH)

$(OPENAL_PATH)/CMakeLists.txt:
	git clone --depth 1 -b $(OPENAL_BRANCH) https://github.com/kcat/openal-soft $(OPENAL_PATH)

$(OPENAL_PATH)/build/CMakeCache.txt: $(CMAKE) $(OPENAL_PATH)/CMakeLists.txt
	$(CMAKE) -B$(OPENAL_PATH)/build -S$(OPENAL_PATH) $(CMAKE_OPTS) -DALSOFT_EXAMPLES=0 -DALSOFT_BACKEND_SNDIO=0

installdir/lib/libopenal.so: $(OPENAL_PATH)/build/CMakeCache.txt
	$(CMAKE) --build $(OPENAL_PATH)/build --target install -j $(NUMBER_OF_PROCESSORS)
	strip installdir/lib/libopenal.so

# BZip2
override BZIP2_FILE := bzip2-$(BZIP2_VERSION)

$(BZIP2_FILE).tar.gz:
	curl $(CURL_DOH_URL) -Lo $(BZIP2_FILE).tar.gz https://sourceware.org/pub/bzip2/$(BZIP2_FILE).tar.gz

$(BZIP2_FILE)/Makefile: $(BZIP2_FILE).tar.gz
	tar xzf $(BZIP2_FILE).tar.gz
	touch $(BZIP2_FILE)/Makefile

installdir/bzip2installed.txt: $(BZIP2_FILE)/Makefile
	cd $(BZIP2_FILE) && $(MAKE) install -j$(NUMBER_OF_PROCESSORS) CFLAGS="-fPIC -Wall -Winline -O2 -g -D_FILE_OFFSET_BITS=64" LDFLAGS="-Wl,-rpath,'\$ORIGIN/../lib'" PREFIX=$(INSTALLPREFIX)
	touch installdir/bzip2installed.txt

# FreeType
override FT_FILE := freetype-$(FT_VERSION)

$(FT_FILE).tar.gz:
	curl $(CURL_DOH_URL) -Lo $(FT_FILE).tar.gz https://download.savannah.gnu.org/releases/freetype/$(FT_FILE).tar.gz

$(FT_FILE)/configure: $(FT_FILE).tar.gz
	tar xzf $(FT_FILE).tar.gz
	touch $(FT_FILE)/configure

$(FT_FILE)/build/Makefile: $(FT_FILE)/configure installdir/bzip2installed.txt installdir/lib/libz.so installdir/lib/libbrotlidec.so
	mkdir -p $(FT_FILE)/build
	cd $(FT_FILE)/build && CFLAGS="-I$(INSTALLPREFIX)/include" LDFLAGS="-Wl,-rpath,'\$$\$$ORIGIN/../lib' -L$(INSTALLPREFIX)/lib -Wl,--no-undefined" PKG_CONFIG_PATH=$(INSTALLPREFIX)/lib/pkgconfig ../configure --prefix=$(INSTALLPREFIX)

installdir/lib/libfreetype.so: $(FT_FILE)/build/Makefile
	cd $(FT_FILE)/build && $(MAKE) install -j$(NUMBER_OF_PROCESSORS)
	strip installdir/lib/libfreetype.so

# harfbuzz
override HB_PATH := harfbuzz-$(HARFBUZZ_BRANCH)

$(HB_PATH)/CMakeLists.txt:
	git clone --depth 1 -b $(HARFBUZZ_BRANCH) https://github.com/harfbuzz/harfbuzz $(HB_PATH)

$(HB_PATH)/build/CMakeCache.txt: $(HB_PATH)/CMakeLists.txt installdir/lib/libfreetype.so
	$(CMAKE) -B$(HB_PATH)/build -S$(HB_PATH) $(CMAKE_OPTS) -DHB_HAVE_FREETYPE=1 -DHB_BUILD_SUBSET=0 -DBUILD_SHARED_LIBS=0 -DCMAKE_POSITION_INDEPENDENT_CODE=1

installdir/lib/libharfbuzz.a: $(HB_PATH)/build/CMakeCache.txt
	$(CMAKE) --build $(HB_PATH)/build --target install -j $(NUMBER_OF_PROCESSORS)

# libmodplug
override LIBMODPLUG_FILE := libmodplug-$(LIBMODPLUG_VERSION)

$(LIBMODPLUG_FILE).tar.gz:
	curl $(CURL_DOH_URL) -Lo $(LIBMODPLUG_FILE).tar.gz http://sourceforge.net/projects/modplug-xmms/files/libmodplug/$(LIBMODPLUG_VERSION)/$(LIBMODPLUG_FILE).tar.gz/download

$(LIBMODPLUG_FILE)/configure: $(LIBMODPLUG_FILE).tar.gz
	tar xzf $(LIBMODPLUG_FILE).tar.gz
	touch $(LIBMODPLUG_FILE)/configure

$(LIBMODPLUG_FILE)/build/Makefile: $(LIBMODPLUG_FILE)/configure
	mkdir -p $(LIBMODPLUG_FILE)/build
	cd $(LIBMODPLUG_FILE)/build && $(CONFIGURE)

installdir/lib/libmodplug.so: $(LIBMODPLUG_FILE)/build/Makefile
	cd $(LIBMODPLUG_FILE)/build && $(MAKE) install -j$(NUMBER_OF_PROCESSORS)

# LuaJIT
override LUAJIT_PATH := LuaJIT-$(LUAJIT_BRANCH)

$(LUAJIT_PATH)/Makefile:
	git clone --depth 1 -b $(LUAJIT_BRANCH) https://github.com/LuaJIT/LuaJIT $(LUAJIT_PATH)

installdir/lib/libluajit-5.1.so: $(LUAJIT_PATH)/Makefile
	cd $(LUAJIT_PATH) && LDFLAGS="-Wl,-rpath,'\$$\$$ORIGIN/../lib'" $(MAKE) amalg -j$(NUMBER_OF_PROCESSORS) PREFIX=/usr
	cd $(LUAJIT_PATH) && make install PREFIX=$(INSTALLPREFIX)
	cd $(LUAJIT_PATH) && make clean
	strip installdir/lib/libluajit-5.1.so
	strip installdir/bin/luaji*

# LOVE
override LOVE_PATH := love2d-$(LOVE_BRANCH)

$(LOVE_PATH)/CMakeLists.txt:
	git clone --depth 1 -b $(LOVE_BRANCH) https://github.com/love2d/love $(LOVE_PATH)

$(LOVE_PATH)/configure: $(LOVE_PATH)/CMakeLists.txt installdir/lib/libluajit-5.1.so installdir/lib/libmodplug.so installdir/lib/libfreetype.so installdir/lib/libopenal.so installdir/lib/libz.so installdir/lib/libtheora.so installdir/lib/libvorbis.so installdir/lib/libogg.so installdir/lib/libSDL2.so installdir/lib/libharfbuzz.a
	cd $(LOVE_PATH) && bash platform/unix/genmodules
	cp $(LOVE_PATH)/platform/unix/configure.ac $(LOVE_PATH) && cp $(LOVE_PATH)/platform/unix/Makefile.am $(LOVE_PATH)
	cd $(LOVE_PATH) && autoheader
	cd $(LOVE_PATH) && libtoolize --force
	cd $(LOVE_PATH) && aclocal -I $(INSTALLPREFIX)/share/aclocal
	cd $(LOVE_PATH) && autoconf -I$(INSTALLPREFIX)
	cd $(LOVE_PATH) && automake -a

$(LOVE_PATH)/build/Makefile: $(LOVE_PATH)/configure
	mkdir -p $(LOVE_PATH)/build
	cd $(LOVE_PATH)/build && CFLAGS="-I$(INSTALLPREFIX)/include" PKG_CONFIG_PATH=$(INSTALLPREFIX)/lib/pkgconfig LDFLAGS="-Wl,-rpath,'\$$\$$ORIGIN/../lib' -L$(INSTALLPREFIX)/lib" ../configure --prefix=$(INSTALLPREFIX)

installdir/bin/love: $(LOVE_PATH)/build/Makefile
	cd $(LOVE_PATH)/build && $(MAKE) install -j$(NUMBER_OF_PROCESSORS)
	strip installdir/bin/love
	-strip installdir/lib/liblove*

installdir/love.sh: love.sh
	mkdir -p installdir
	cp love.sh installdir/love.sh
	touch installdir/love.sh

installdir/AppRun: love.sh installdir/bin/love
	mkdir -p installdir
	cp love.sh installdir/AppRun
	chmod +x installdir/AppRun

installdir/love.desktop: $(LOVE_PATH)/platform/unix/love.desktop.in
	cat $(LOVE_PATH)/platform/unix/love.desktop.in | sed 's/@bindir@\///' > installdir/love.desktop

installdir/love.svg: $(LOVE_PATH)/platform/unix/love.svg
	cp $(LOVE_PATH)/platform/unix/love.svg installdir/love.svg

installdir/license.txt: $(LOVE_PATH)/license.txt
	cp $(LOVE_PATH)/license.txt installdir/license.txt

appimage-prepare: installdir/AppRun installdir/love.desktop installdir/love.svg installdir/license.txt appimagetool
	mkdir -p installdir2/lib installdir2/bin
	cp installdir/AppRun installdir2/AppRun
	cp installdir/license.txt installdir2/license.txt
	cp installdir/love.desktop installdir2/love.desktop
	cp installdir/love.svg installdir2/love.svg
	cp -L installdir/bin/love installdir2/bin/love
	strip installdir2/bin/love
	patchelf --set-rpath '$$ORIGIN/../lib' installdir2/bin/love
	ldd installdir/bin/love | while read line; do \
		dll=`echo $$line | sed 's/\s.*//'`; \
		if [ -f installdir/lib/$$dll ]; then \
			cp -L installdir/lib/$$dll installdir2/lib/$$dll; \
			strip installdir2/lib/$$dll; \
			patchelf --set-rpath '$$ORIGIN/../lib' installdir2/lib/$$dll; \
			echo $$dll; \
		fi \
	done
	cp -r installdir/share installdir2/
	-rm -rf installdir2/share/aclocal
	-rm -rf installdir2/share/man
	-rm -rf installdir2/share/doc
	-rm -rf installdir2/share/openal

$(TAR_OUTPUT): installdir/AppRun installdir/love.desktop installdir/love.svg installdir/license.txt appimagetool appimage-prepare
	cd installdir2; tar -cvzf ../$(TAR_OUTPUT) *

$(APPIMAGE_OUTPUT): installdir/AppRun installdir/love.desktop installdir/love.svg installdir/license.txt appimagetool appimage-prepare
ifeq ($(QEMU),)
	./appimagetool installdir2 $(APPIMAGE_OUTPUT)
else
	cd squashfs-root/usr/lib && ../../AppRun ../../../installdir2 ../../../$(APPIMAGE_OUTPUT)
endif

getdeps: $(CMAKE) appimagetool $(SDL2_PATH)/configure $(LIBOGG_FILE).tar.gz $(LIBVORBIS_FILE).tar.gz $(LIBTHEORA_FILE).tar.gz $(ZLIB_PATH)/configure $(BROTLI_PATH)/CMakeLists.txt $(BZIP2_FILE).tar.gz $(FT_FILE).tar.gz $(LIBMODPLUG_FILE).tar.gz $(LUAJIT_PATH)/Makefile $(LOVE_PATH)/CMakeLists.txt $(HB_PATH)/CMakeLists.txt

AppImage: $(APPIMAGE_OUTPUT)

tar: $(TAR_OUTPUT)

default: $(APPIMAGE_OUTPUT) $(TAR_OUTPUT)

.DEFAULT_GOAL := default
.PHONY := default getdeps cmake appimage-prepare AppImage tar
