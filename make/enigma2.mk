#
# ENIGMA2
#
ENIGMA2_DEPS  = $(D)/bootstrap
ENIGMA2_DEPS += $(D)/opkg
ENIGMA2_DEPS += $(D)/ncurses
ENIGMA2_DEPS += $(D)/libpng
ENIGMA2_DEPS += $(D)/libjpeg
ENIGMA2_DEPS += $(D)/giflib
ENIGMA2_DEPS += $(D)/libfribidi
ENIGMA2_DEPS += $(D)/libglib2
ENIGMA2_DEPS += $(D)/libdvbsi
ENIGMA2_DEPS += $(D)/libxml2
ENIGMA2_DEPS += $(D)/openssl
ENIGMA2_DEPS += $(D)/tuxtxt32bpp
ENIGMA2_DEPS += $(D)/hotplug_e2_helper
ENIGMA2_DEPS += $(D)/avahi
ENIGMA2_DEPS += $(D)/python
ENIGMA2_DEPS  += $(D)/libsigc
ifneq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), size))
ENIGMA2_DEPS += $(D)/ethtool
ENIGMA2_DEPS += $(D)/alsa_utils
ENIGMA2_DEPS += $(D)/libdreamdvd
ENIGMA2_DEPS += $(D)/libmad
ENIGMA2_DEPS += $(D)/libusb
ENIGMA2_DEPS += $(D)/libid3tag
ENIGMA2_DEPS += $(D)/minidlna
ENIGMA2_DEPS += $(D)/sdparm
ENIGMA2_DEPS += $(D)/parted 
endif

ENIGMA2_CONFIG_OPTS =

ifeq ($(GRAPHLCD), graphlcd)
ENIGMA2_CONFIG_OPTS += --with-graphlcd
endif

ifeq ($(LCD4LINUX), lcd4linux)
ENIGMA2_CONFIG_OPTS += --with-lcd4linux
endif

ifeq ($(BOXARCH), sh4)
ENIGMA2_CPPFLAGS   += -I$(KERNEL_DIR)/include
ENIGMA2_CPPFLAGS   += -I$(DRIVER_DIR)/include
endif
ENIGMA2_CPPFLAGS   += -I$(TARGET_DIR)/usr/include

#ifeq ($(GUI), ENIGMA2)
#PYTHON = python
#endif

ENIGMA2_CONFIG_OPTS += PYTHON_CPPFLAGS="-I$(TARGET_DIR)/usr/include/python2.7" PYTHON_LIBS="-L$(TARGET_DIR)/usr/lib -lpython2.7" PYTHON_SITE_PKG="$(TARGET_DIR)/usr/lib/python2.7/site-packages"

ENIGMA2_PATCHES = enigma2.patch

#
# enigma2
#
$(D)/enigma2.do_prepare: $(ENIGMA2_DEPS)
	$(START_BUILD)
	rm -rf $(SOURCE_DIR)/enigma2
	[ -d "$(ARCHIVE)/enigma2.git" ] && \
	(cd $(ARCHIVE)/enigma2.git; git pull;); \
	[ -d "$(ARCHIVE)/enigma2.git" ] || \
	git clone -b 6.4 https://github.com/openatv/enigma2.git $(ARCHIVE)/enigma2.git; \
	cp -ra $(ARCHIVE)/enigma2.git $(SOURCE_DIR)/enigma2; \
	set -e; cd $(SOURCE_DIR)/enigma2; \
		$(call apply_patches,$(ENIGMA2_PATCHES))
	@touch $@

$(D)/enigma2.config.status: $(D)/enigma2.do_prepare
	cd $(SOURCE_DIR)/enigma2; \
		./autogen.sh $(SILENT_OPT); \
		sed -e 's|#!/usr/bin/python|#!$(HOST_DIR)/bin/python|' -i po/xml2po.py; \
		$(BUILDENV) \
		./configure $(SILENT_CONFIGURE) \
			--build=$(BUILD) \
			--host=$(TARGET) \
			$(ENIGMA2_CONFIG_OPTS) \
			--with-libsdl=no \
			--datadir=/usr/share \
			--libdir=/usr/lib \
			--bindir=/usr/bin \
			--prefix=/usr \
			--sysconfdir=/etc \
			--with-boxtype=$(BOXTYPE) \
			-with-gstversion=1.0 \
			PKG_CONFIG=$(PKG_CONFIG) \
			PKG_CONFIG_PATH=$(PKG_CONFIG_PATH) \
			PY_PATH=$(TARGET_DIR)/usr \
			CPPFLAGS="$(ENIGMA2_CPPFLAGS)"
	@touch $@

$(D)/enigma2.do_compile: $(D)/enigma2.config.status
	cd $(SOURCE_DIR)/enigma2; \
		$(MAKE) all
	@touch $@

$(D)/enigma2: $(D)/enigma2.do_compile
	$(MAKE) -C $(SOURCE_DIR)/enigma2 install DESTDIR=$(TARGET_DIR)
	$(TOUCH)

enigma2-clean:
	rm -f $()/enigma2.do_compile
	$(MAKE) -C $(SOURCE_DIR)/enigma2 clean
	rm -f $(TARGET_DIR)/usr/share/fonts/fallback.font
	rm -f $(D)/enigma2

enigma2-distclean:
	rm -f $(D)/enigma2*
	rm -f $(TARGET_DIR)/usr/share/fonts/fallback.font
	$(MAKE) -C $(SOURCE_DIR)/enigma2 distclean
	
#
# hotplug_e2_helper
#
HOTPLUG_E2_PATCH = hotplug-e2-helper.patch

$(D)/hotplug_e2_helper: $(D)/bootstrap
	$(START_BUILD)
	$(REMOVE)/hotplug-e2-helper
	$(SET) -e; 
	[ -d "$(ARCHIVE)/hotplug-e2-helper.git" ] && \
	(cd $(ARCHIVE)/hotplug-e2-helper.git; git pull $(MINUS_Q);); \
	[ -d "$(ARCHIVE)/hotplug-e2-helper.git" ] || \
	git clone $(MINUS_Q) https://github.com/OpenPLi/hotplug-e2-helper.git hotplug-e2-helper.git; \
	$(SILENT)cp -ra $(ARCHIVE)/hotplug-e2-helper.git $(BUILD_TMP)/hotplug-e2-helper
	$(SET) -e; cd $(BUILD_TMP)/hotplug-e2-helper; \
		$(call apply_patches,$(HOTPLUG_E2_PATCH)); \
		$(CONFIGURE) \
			--prefix=/usr \
		; \
		$(MAKE) all; \
		$(MAKE) install prefix=/usr DESTDIR=$(TARGET_DIR)
	$(REMOVE)/hotplug-e2-helper
	$(TOUCH)

#
# libsigc++_e2
#
LIBSIGC_E2_VER_MAJOR = 1
LIBSIGC_E2_VER_MINOR = 2
LIBSIGC_E2_VER_MICRO = 7
LIBSIGC_E2_VER = $(LIBSIGC_E2_VER_MAJOR).$(LIBSIGC_E2_VER_MINOR).$(LIBSIGC_E2_VER_MICRO)
LIBSIGC_E2_SOURCE = libsigc++-$(LIBSIGC_E2_VER).tar.gz

$(ARCHIVE)/$(LIBSIGC_E2_SOURCE):
	$(WGET) https://ftp.gnome.org/pub/GNOME/sources/libsigc++/$(LIBSIGC_E2_VER_MAJOR).$(LIBSIGC_E2_VER_MINOR)/$(LIBSIGC_E2_SOURCE)

$(D)/libsigc_e2: $(D)/bootstrap $(ARCHIVE)/$(LIBSIGC_E2_SOURCE)
	$(START_BUILD)
	$(REMOVE)/libsigc++-$(LIBSIGC_E2_VER)
	$(UNTAR)/$(LIBSIGC_E2_SOURCE)
	set -e; cd $(BUILD_TMP)/libsigc++-$(LIBSIGC_E2_VER); \
		$(CONFIGURE) \
			--prefix=/usr \
			--disable-checks \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/sigc++-1.2.pc
	$(REWRITE_LIBTOOL)/libsigc-1.2.la
	$(REMOVE)/libsigc++-$(LIBSIGC_E2_VER)
	$(TOUCH)

#
# tuxtxtlib
#
TUXTXTLIB_PATCH = tuxtxtlib-1.0-fix-dbox-headers.patch tuxtxtlib-fix-found-dvbversion.patch

$(D)/tuxtxtlib: $(D)/bootstrap $(D)/freetype
	$(START_BUILD)
	$(REMOVE)/tuxtxtlib
	[ -d "$(ARCHIVE)/tuxtxt.git" ] && \
	(cd $(ARCHIVE)/tuxtxt.git; git pull $(MINUS_Q);); \
	[ -d "$(ARCHIVE)/tuxtxt.git" ] || \
	git clone $(MINUS_Q) https://github.com/OpenPLi/tuxtxt.git tuxtxt.git; \
	cp -ra $(ARCHIVE)/tuxtxt.git/libtuxtxt $(BUILD_TMP)/tuxtxtlib
	$(SILENT)cd $(BUILD_TMP)/tuxtxtlib; \
		$(call apply_patches,$(TUXTXTLIB_PATCH)); \
		aclocal; \
		autoheader; \
		autoconf; \
		libtoolize --force $(SILENT_OPT); \
		automake --foreign --add-missing; \
		$(BUILDENV) \
		./configure $(SILENT_CONFIGURE) \
			--build=$(BUILD) \
			--host=$(TARGET) \
			--prefix=/usr \
			--with-boxtype=generic \
			--with-configdir=/etc \
			--with-datadir=/usr/share/tuxtxt \
			--with-fontdir=/usr/share/fonts \
		; \
		$(MAKE) all; \
		$(MAKE) install prefix=/usr DESTDIR=$(TARGET_DIR)
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/tuxbox-tuxtxt.pc
	$(REWRITE_LIBTOOL)/libtuxtxt.la
	$(REMOVE)/tuxtxtlib
	$(TOUCH)

#
# tuxtxt32bpp
#
TUXTXT32BPP_PATCH = tuxtxt32bpp-1.0-fix-dbox-headers.patch tuxtxt32bpp-fix-found-dvbversion.patch

$(D)/tuxtxt32bpp: $(D)/bootstrap $(D)/tuxtxtlib
	$(START_BUILD)
	$(REMOVE)/tuxtxt
	$(SILENT)cp -ra $(ARCHIVE)/tuxtxt.git/tuxtxt $(BUILD_TMP)/tuxtxt
	$(SET) -e; cd $(BUILD_TMP)/tuxtxt; \
		$(call apply_patches,$(TUXTXT32BPP_PATCH)); \
		aclocal; \
		autoheader; \
		autoconf; \
		libtoolize --force $(SILENT_OPT); \
		automake --foreign --add-missing; \
		$(BUILDENV) \
		./configure $(SILENT_CONFIGURE) \
			--build=$(BUILD) \
			--host=$(TARGET) \
			--prefix=/usr \
			--with-fbdev=/dev/fb0 \
			--with-boxtype=generic \
			--with-configdir=/etc \
			--with-datadir=/usr/share/tuxtxt \
			--with-fontdir=/usr/share/fonts \
		; \
		$(MAKE) all; \
		$(MAKE) install prefix=/usr DESTDIR=$(TARGET_DIR)
	$(REWRITE_LIBTOOL)/libtuxtxt32bpp.la
	$(REMOVE)/tuxtxt
	$(TOUCH)
	
#
# release-enigma2
#
release-enigma2: release-common release-$(BOXTYPE) $(D)/enigma2
	$(START_BUILD)
	install -d $(RELEASE_DIR)/etc/enigma2
	install -d $(RELEASE_DIR)/etc/tuxbox
	install -d $(RELEASE_DIR)/usr/share/enigma2
	cp -af $(TARGET_DIR)/usr/bin/enigma2 $(RELEASE_DIR)/usr/bin/enigma2
	cp -aR $(TARGET_DIR)/usr/share/enigma2 $(RELEASE_DIR)/usr/share
	cp -aR $(TARGET_DIR)/usr/share/keymaps $(RELEASE_DIR)/usr/share
	cp -aR $(TARGET_DIR)/usr/share/meta $(RELEASE_DIR)/usr/share
	cp -aR $(TARGET_DIR)/usr/share/fonts $(RELEASE_DIR)/usr/share
	cp -aR $(TARGET_DIR)/usr/lib/enigma2 $(RELEASE_DIR)/usr/lib
	cp -Rf $(TARGET_DIR)/usr/share/enigma2/po/en $(RELEASE_DIR)/usr/share/enigma2/po
	cp -Rf $(TARGET_DIR)/usr/share/enigma2/po/de $(RELEASE_DIR)/usr/share/enigma2/po
	cp -aR $(SKEL_ROOT)/usr/share/enigma2/* $(RELEASE_DIR)/usr/share/enigma2
	cp -aR $(SKEL_ROOT)/etc/tuxbox/* $(RELEASE_DIR)/etc/tuxbox/
	install -m 0755 $(BASE_DIR)/machine/$(BOXTYPE)/files/rcS_ENIGMA2 $(RELEASE_DIR)/etc/init.d/rcS
#
# lib usr/lib
#
	cp -R $(TARGET_DIR)/lib/* $(RELEASE_DIR)/lib/
	rm -f $(RELEASE_DIR)/lib/*.{a,o,la}
	chmod 755 $(RELEASE_DIR)/lib/*
	cp -R $(TARGET_DIR)/usr/lib/* $(RELEASE_DIR)/usr/lib/
	rm -rf $(RELEASE_DIR)/usr/lib/{engines,gconv,libxslt-plugins,pkgconfig,sigc++-1.2,sigc++-2.0,lua,python$(PYTHON_VER_MAJOR),enigma2,gstreamer-1.0,gio}
	rm -f $(RELEASE_DIR)/usr/lib/*.{a,o,la}
	chmod 755 $(RELEASE_DIR)/usr/lib/*
#
# enigma2
#
	cp -aR $(TARGET_DIR)/usr/lib/enigma2 $(RELEASE_DIR)/usr/lib
#
#gstreamer
#
ifeq ($(GSTREAMER), gstreamer)
	cp -aR $(TARGET_DIR)/usr/lib/gstreamer-1.0 $(RELEASE_DIR)/usr/lib
	cp -aR $(TARGET_DIR)/usr/lib/gio $(RELEASE_DIR)/usr/lib
endif
#
# python
#
	install -d $(RELEASE_DIR)/$(PYTHON_DIR)
	cp -R $(TARGET_DIR)/$(PYTHON_DIR)/* $(RELEASE_DIR)/$(PYTHON_DIR)/
	install -d $(RELEASE_DIR)/$(PYTHON_INCLUDE_DIR)
	cp $(TARGET_DIR)/$(PYTHON_INCLUDE_DIR)/pyconfig.h $(RELEASE_DIR)/$(PYTHON_INCLUDE_DIR)
#
# mc
#
	if [ -e $(TARGET_DIR)/usr/bin/mc ]; then \
		cp -aR $(TARGET_DIR)/usr/share/mc $(RELEASE_DIR)/usr/share/; \
		cp -af $(TARGET_DIR)/usr/libexec $(RELEASE_DIR)/usr/; \
	fi
#
# shairport
#
	if [ -e $(TARGET_DIR)/usr/bin/shairport ]; then \
		cp -f $(TARGET_DIR)/usr/bin/shairport $(RELEASE_DIR)/usr/bin; \
		cp -f $(TARGET_DIR)/usr/bin/mDNSPublish $(RELEASE_DIR)/usr/bin; \
		cp -f $(TARGET_DIR)/usr/bin/mDNSResponder $(RELEASE_DIR)/usr/bin; \
		cp -f $(SKEL_ROOT)/etc/init.d/shairport $(RELEASE_DIR)/etc/init.d/shairport; \
		chmod 755 $(RELEASE_DIR)/etc/init.d/shairport; \
		cp -f $(TARGET_DIR)/usr/lib/libhowl.so* $(RELEASE_DIR)/usr/lib; \
		cp -f $(TARGET_DIR)/usr/lib/libmDNSResponder.so* $(RELEASE_DIR)/usr/lib; \
	fi	
#
# alsa
#
	if [ -e $(TARGET_DIR)/usr/share/alsa ]; then \
		mkdir -p $(RELEASE_DIR)/usr/share/alsa/; \
		mkdir $(RELEASE_DIR)/usr/share/alsa/cards/; \
		mkdir $(RELEASE_DIR)/usr/share/alsa/pcm/; \
		cp -dp $(TARGET_DIR)/usr/share/alsa/alsa.conf $(RELEASE_DIR)/usr/share/alsa/alsa.conf; \
		cp $(TARGET_DIR)/usr/share/alsa/cards/aliases.conf $(RELEASE_DIR)/usr/share/alsa/cards/; \
		cp $(TARGET_DIR)/usr/share/alsa/pcm/default.conf $(RELEASE_DIR)/usr/share/alsa/pcm/; \
		cp $(TARGET_DIR)/usr/share/alsa/pcm/dmix.conf $(RELEASE_DIR)/usr/share/alsa/pcm/; \
#		cp $(TARGET_DIR)/usr/bin/amixer $(RELEASE_DIR)/usr/bin/; \
	fi
#
# nfs-utils
#
	if [ -e $(TARGET_DIR)/usr/sbin/rpc.nfsd ]; then \
		cp -f $(TARGET_DIR)/usr/sbin/exportfs $(RELEASE_DIR)/usr/sbin/; \
		cp -f $(TARGET_DIR)/usr/sbin/rpc.nfsd $(RELEASE_DIR)/usr/sbin/; \
		cp -f $(TARGET_DIR)/usr/sbin/rpc.mountd $(RELEASE_DIR)/usr/sbin/; \
		cp -f $(TARGET_DIR)/usr/sbin/rpc.statd $(RELEASE_DIR)/usr/sbin/; \
	fi
#
# autofs
#
ifneq ($(BOXTYPE), $(filter $(BOXTYPE), ufs912))
	if [ -d $(RELEASE_DIR)/usr/lib/autofs ]; then \
		cp -f $(TARGET_DIR)/usr/sbin/automount $(RELEASE_DIR)/usr/sbin/; \
#		ln -s /usr/sbin/automount $(RELEASE_DIR)/sbin/automount; \
	fi
endif
#
# graphlcd
#
	if [ -e $(RELEASE_DIR)/usr/lib/libglcddrivers.so ]; then \
		cp -f $(TARGET_DIR)/etc/graphlcd.conf $(RELEASE_DIR)/etc/; \
		rm -f $(RELEASE_DIR)/usr/lib/libglcdskin.so*; \
	fi
#
# lcd4linux
#
	if [ -e $(TARGET_DIR)/usr/bin/lcd4linux ]; then \
		cp -f $(TARGET_DIR)/usr/bin/lcd4linux $(RELEASE_DIR)/usr/bin/; \
		cp -f $(TARGET_DIR)/etc/init.d/lcd4linux $(RELEASE_DIR)/etc/init.d/; \
		cp -a $(TARGET_DIR)/etc/lcd4linux.conf $(RELEASE_DIR)/etc/; \
	fi
#
# minidlna
#
	if [ -e $(TARGET_DIR)/usr/sbin/minidlnad ]; then \
		cp -f $(TARGET_DIR)/usr/sbin/minidlnad $(RELEASE_DIR)/usr/sbin/; \
	fi
#
# openvpn
#
	if [ -e $(TARGET_DIR)/usr/sbin/openvpn ]; then \
		cp -f $(TARGET_DIR)/usr/sbin/openvpn $(RELEASE_DIR)/usr/sbin; \
		install -d $(RELEASE_DIR)/etc/openvpn; \
	fi
#
# udpxy
#
	if [ -e $(TARGET_DIR)/usr/bin/udpxy ]; then \
		cp -f $(TARGET_DIR)/usr/bin/udpxy $(RELEASE_DIR)/usr/bin; \
		cp -a $(TARGET_DIR)/usr/bin/udpxrec $(RELEASE_DIR)/usr/bin; \
	fi
#
# xupnpd
#
	if [ -e $(TARGET_DIR)/usr/bin/xupnpd ]; then \
		cp -f $(TARGET_DIR)/usr/bin/xupnpd $(RELEASE_DIR)/usr/bin; \
		cp -aR $(TARGET_DIR)/usr/share/xupnpd $(RELEASE_DIR)/usr/share; \
		mkdir -p $(RELEASE_DIR)/usr/share/xupnpd/playlists; \
	fi
#
# delete unnecessary files
#
	rm -rf $(RELEASE_DIR)/$(PYTHON_DIR)/{bsddb,compiler,curses,lib-old,lib-tk,plat-linux3,test,sqlite3,pydoc_data,multiprocessing,hotshot,distutils,email,unitest,ensurepip,wsgiref,lib2to3,logging,idlelib}
	rm -rf $(RELEASE_DIR)/$(PYTHON_DIR)/pdb.doc
	rm -rf $(RELEASE_DIR)/$(PYTHON_DIR)/ctypes/test
	rm -rf $(RELEASE_DIR)/$(PYTHON_DIR)/email/test
	rm -rf $(RELEASE_DIR)/$(PYTHON_DIR)/json/tests
	rm -rf $(RELEASE_DIR)/$(PYTHON_DIR)/idlelib/idle_test
	rm -rf $(RELEASE_DIR)/$(PYTHON_DIR)/idlelib/icons
	rm -rf $(RELEASE_DIR)/$(PYTHON_DIR)/lib2to3/tests
	rm -rf $(RELEASE_DIR)/$(PYTHON_DIR)/sqlite3/test
	rm -rf $(RELEASE_DIR)/$(PYTHON_DIR)/unittest/test
	rm -rf $(RELEASE_DIR)/$(PYTHON_DIR)/site-packages/twisted/{test,conch,mail,names,news,words,flow,lore,pair,runner}
	rm -rf $(RELEASE_DIR)/$(PYTHON_DIR)/site-packages/Cheetah/Tests
	rm -rf $(RELEASE_DIR)/$(PYTHON_DIR)/site-packages/livestreamer_cli
	rm -rf $(RELEASE_DIR)/$(PYTHON_DIR)/site-packages/lxml
	rm -f $(RELEASE_DIR)/$(PYTHON_DIR)/site-packages/libxml2mod.so
	rm -f $(RELEASE_DIR)/$(PYTHON_DIR)/site-packages/libxsltmod.so
	rm -rf $(RELEASE_DIR)/$(PYTHON_DIR)/site-packages/OpenSSL/test
	rm -rf $(RELEASE_DIR)/$(PYTHON_DIR)/site-packages/setuptools
	rm -rf $(RELEASE_DIR)/$(PYTHON_DIR)/site-packages/zope/interface/tests
	rm -rf $(RELEASE_DIR)/$(PYTHON_DIR)/site-packages/twisted/application/test
	rm -rf $(RELEASE_DIR)/$(PYTHON_DIR)/site-packages/twisted/conch/test
	rm -rf $(RELEASE_DIR)/$(PYTHON_DIR)/site-packages/twisted/internet/test
	rm -rf $(RELEASE_DIR)/$(PYTHON_DIR)/site-packages/twisted/lore/test
	rm -rf $(RELEASE_DIR)/$(PYTHON_DIR)/site-packages/twisted/mail/test
	rm -rf $(RELEASE_DIR)/$(PYTHON_DIR)/site-packages/twisted/manhole/test
	rm -rf $(RELEASE_DIR)/$(PYTHON_DIR)/site-packages/twisted/names/test
	rm -rf $(RELEASE_DIR)/$(PYTHON_DIR)/site-packages/twisted/news/test
	rm -rf $(RELEASE_DIR)/$(PYTHON_DIR)/site-packages/twisted/pair/test
	rm -rf $(RELEASE_DIR)/$(PYTHON_DIR)/site-packages/twisted/persisted/test
	rm -rf $(RELEASE_DIR)/$(PYTHON_DIR)/site-packages/twisted/protocols/test
	rm -rf $(RELEASE_DIR)/$(PYTHON_DIR)/site-packages/twisted/python/test
	rm -rf $(RELEASE_DIR)/$(PYTHON_DIR)/site-packages/twisted/runner/test
	rm -rf $(RELEASE_DIR)/$(PYTHON_DIR)/site-packages/twisted/scripts/test
	rm -rf $(RELEASE_DIR)/$(PYTHON_DIR)/site-packages/twisted/test
	rm -rf $(RELEASE_DIR)/$(PYTHON_DIR)/site-packages/twisted/trial/test
	rm -rf $(RELEASE_DIR)/$(PYTHON_DIR)/site-packages/twisted/web/test
	rm -rf $(RELEASE_DIR)/$(PYTHON_DIR)/site-packages/twisted/words/test
	rm -rf $(RELEASE_DIR)/$(PYTHON_DIR)/site-packages/*-py$(PYTHON_VER_MAJOR).egg-info
	find $(RELEASE_DIR)/$(PYTHON_DIR)/ -name '*.a' -exec rm -f {} \;
	find $(RELEASE_DIR)/$(PYTHON_DIR)/ -name '*.c' -exec rm -f {} \;
	find $(RELEASE_DIR)/$(PYTHON_DIR)/ -name '*.pyx' -exec rm -f {} \;
	find $(RELEASE_DIR)/$(PYTHON_DIR)/ -name '*.py' -exec rm -f {} \;
	find $(RELEASE_DIR)/$(PYTHON_DIR)/ -name '*.o' -exec rm -f {} \;
	find $(RELEASE_DIR)/$(PYTHON_DIR)/ -name '*.la' -exec rm -f {} \;
	rm -f $(RELEASE_DIR)/usr/bin/avahi-*
	rm -f $(RELEASE_DIR)/usr/bin/easy_install*
	rm -f $(RELEASE_DIR)/usr/bin/glib-*
	rm -f $(addprefix $(RELEASE_DIR)/usr/bin/,dvdnav-config gio-querymodules gobject-query gtester gtester-report)
	rm -f $(addprefix $(RELEASE_DIR)/usr/bin/,livestreamer mailmail manhole opkg-check-config opkg-cl)
	rm -rf $(RELEASE_DIR)/lib/autofs
	rm -rf $(RELEASE_DIR)/usr/lib/m4-nofpu/
	rm -rf $(RELEASE_DIR)/usr/lib/gcc
	rm -f $(RELEASE_DIR)/usr/lib/libc.so
	rm -rf $(RELEASE_DIR)/usr/share/enigma2/po/*
	rm -f $(RELEASE_DIR)/usr/share/meta/*
	rm -f $(RELEASE_DIR)/usr/share/enigma2/black.mvi
	rm -f $(RELEASE_DIR)/usr/share/enigma2/hd-testcard.mvi
	rm -f $(RELEASE_DIR)/usr/share/enigma2/otv_*
	rm -f $(RELEASE_DIR)/usr/share/enigma2/keymap.u80
	rm -f $(RELEASE_DIR)/usr/bin/enigma2.sh
	rm -rf $(RELEASE_DIR)/lib/autofs
	rm -f $(RELEASE_DIR)/lib/libSegFault*
	rm -f $(RELEASE_DIR)/lib/libstdc++.*-gdb.py
	rm -f $(RELEASE_DIR)/lib/libthread_db*
	rm -f $(RELEASE_DIR)/lib/libanl*
	rm -rf $(RELEASE_DIR)/usr/lib/alsa
	rm -rf $(RELEASE_DIR)/usr/lib/glib-2.0
	rm -rf $(RELEASE_DIR)/usr/lib/cmake
	rm -f $(RELEASE_DIR)/usr/lib/*.py
	rm -f $(RELEASE_DIR)/usr/lib/libc.so
	rm -f $(RELEASE_DIR)/usr/lib/xml2Conf.sh
	rm -f $(RELEASE_DIR)/usr/lib/libfontconfig*
	rm -f $(RELEASE_DIR)/usr/lib/libthread_db*
	rm -f $(RELEASE_DIR)/usr/lib/libanl*
	rm -f $(RELEASE_DIR)/usr/lib/libopkg*
	rm -f $(RELEASE_DIR)/sbin/ldconfig
	rm -f $(RELEASE_DIR)/usr/bin/{gdbus-codegen,glib-*,gtester-report}
	rm -f $(RELEASE_DIR)/var/tuxbox/config/zapit/services.xml
	rm -f $(RELEASE_DIR)/var/tuxbox/config/zapit/bouquets.xml
	rm -f $(RELEASE_DIR)/var/tuxbox/config/zapit/ubouquets.xml
	rm -rf $(RELEASE_DIR)/usr/lib/enigma2/python/Plugins/Extensions/DVDBurn
	rm -rf $(RELEASE_DIR)/usr/lib/enigma2/python/Plugins/Extensions/TuxboxPlugins
	rm -rf $(RELEASE_DIR)/usr/lib/enigma2/python/Plugins/Extensions/MediaScanner
	rm -rf $(RELEASE_DIR)/usr/lib/enigma2/python/Plugins/Extensions/MediaPlayer
	rm -rf $(RELEASE_DIR)/usr/lib/enigma2/python/Plugins/Extensions/
	find $(RELEASE_DIR)/usr/lib/enigma2/ -name '*.pyc' -exec rm -f {} \;
	find $(RELEASE_DIR)/usr/lib/enigma2/ -name '*.py' -exec rm -f {} \;
	find $(RELEASE_DIR)/usr/lib/enigma2/ -name '*.a' -exec rm -f {} \;
	find $(RELEASE_DIR)/usr/lib/enigma2/ -name '*.o' -exec rm -f {} \;
	find $(RELEASE_DIR)/usr/lib/enigma2/ -name '*.la' -exec rm -f {} \;
ifeq ($(BOXARCH), sh4)
	rm -rf $(RELEASE_DIR)/usr/lib/lua
	rm -rf $(RELEASE_DIR)/usr/share/lua
	rm -rf $(RELEASE_DIR)/usr/share/tuxbox
	rm -rf $(RELEASE_DIR)/lib/modules/$(KERNEL_VER)
endif
ifeq ($(BOXTYPE), $(filter $(BOXTYPE), ufs910 ufs922))
	rm -f $(RELEASE_DIR)/sbin/jfs_fsck
	rm -f $(RELEASE_DIR)/sbin/fsck.jfs
	rm -f $(RELEASE_DIR)/sbin/jfs_mkfs
	rm -f $(RELEASE_DIR)/sbin/mkfs.jfs
	rm -f $(RELEASE_DIR)/sbin/jfs_tune
	rm -f $(RELEASE_DIR)/sbin/ffmpeg
	rm -f $(RELEASE_DIR)/etc/ssl/certs/ca-certificates.crt
endif
ifeq ($(BOXARCH), $(filter $(BOXARCH), arm mipsel))
	rm -rf $(RELEASE_DIR)/dev.static
	rm -rf $(RELEASE_DIR)/ram
	rm -rf $(RELEASE_DIR)/root
endif
	cp -dpfr $(RELEASE_DIR)/etc $(RELEASE_DIR)/var
	rm -fr $(RELEASE_DIR)/etc
	ln -sf /var/etc $(RELEASE_DIR)
	ln -s /tmp $(RELEASE_DIR)/var/lock
	ln -s /tmp $(RELEASE_DIR)/var/log
	ln -s /tmp $(RELEASE_DIR)/var/run
	ln -s /tmp $(RELEASE_DIR)/var/tmp
	$(TUXBOX_CUSTOMIZE)
#
# strip
#	
ifneq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), kerneldebug debug normal))
	find $(RELEASE_DIR)/ -name '*' -exec $(TARGET)-strip --strip-unneeded {} &>/dev/null \;
endif
	$(END_BUILD)
		
