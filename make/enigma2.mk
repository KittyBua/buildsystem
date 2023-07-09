#
# ENIGMA2
#
ENIGMA2_DEPS  = $(D)/bootstrap
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

ENIGMA2_CPPFLAGS =
ENIGMA2_CONFIG_OPTS = 

GSTREAMER ?= gstreamer
ifeq ($(GSTREAMER), gstreamer)
ENIGMA2_DEPS  += $(D)/gstreamer 
ENIGMA2_DEPS  += $(D)/gst_plugins_base 
ENIGMA2_DEPS  += $(D)/gst_plugins_good 
ENIGMA2_DEPS  += $(D)/gst_plugins_bad 
ENIGMA2_DEPS  += $(D)/gst_plugins_ugly 
ENIGMA2_DEPS  += $(D)/gst_plugins_subsink
ENIGMA2_DEPS  += $(D)/gst_plugins_dvbmediasink
ENIGMA2_CPPFLAGS     += $(shell $(PKG_CONFIG) --cflags --libs gstreamer-1.0)
ENIGMA2_CPPFLAGS     += $(shell $(PKG_CONFIG) --cflags --libs gstreamer-audio-1.0)
ENIGMA2_CPPFLAGS     += $(shell $(PKG_CONFIG) --cflags --libs gstreamer-video-1.0)
ENIGMA2_CPPFLAGS     += $(shell $(PKG_CONFIG) --cflags --libs glib-2.0)
ENIGMA2_CONFIG_OPTS += --enable-gstreamer --with-gstversion=1.0
endif

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

ifeq ($(PYTHON), python)
NEUTRINO2_DEPS += $(D)/python
endif

ENIGMA2_CONFIG_OPTS += PYTHON_CPPFLAGS="-I$(TARGET_DIR)/usr/include/python2.7" PYTHON_LIBS="-L$(TARGET_DIR)/usr/lib -lpython2.7" PYTHON_SITE_PKG="$(TARGET_DIR)/usr/lib/python2.7/site-packages"

ENIGMA2 = enigma2-openhdf
ENIGMA2_URL = https://github.com/openhdf/enigma2.git
ENIGMA2_BRANCH = master
ENIGMA2_PATCHES = enigma2-openhdf.patch

#
# enigma2
#
$(D)/enigma2.do_prepare: $(ENIGMA2_DEPS)
	$(START_BUILD)
	rm -rf $(SOURCE_DIR)/enigma2
	[ -d "$(ARCHIVE)/$(ENIGMA2).git" ] && \
	(cd $(ARCHIVE)/$(ENIGMA2).git; git pull;); \
	[ -d "$(ARCHIVE)/$(ENIGMA2).git" ] || \
	git clone -b $(ENIGMA2_BRANCH) $(ENIGMA2_URL) $(ARCHIVE)/$(ENIGMA2).git; \
	cp -ra $(ARCHIVE)/$(ENIGMA2).git $(SOURCE_DIR)/enigma2; \
	set -e; cd $(SOURCE_DIR)/enigma2; \
		$(call apply_patches,$(ENIGMA2_PATCHES))
	@touch $@

$(D)/enigma2.config.status: $(D)/enigma2.do_prepare
	cd $(SOURCE_DIR)/enigma2; \
		chmod 755 autogen.sh; \
		./autogen.sh; \
		sed -e 's|#!/usr/bin/python|#!$(HOST_DIR)/bin/python|' -i po/xml2po.py; \
		$(BUILDENV) \
		./configure \
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
	set -e; 
	[ -d "$(ARCHIVE)/hotplug-e2-helper.git" ] && \
	(cd $(ARCHIVE)/hotplug-e2-helper.git; git pull;); \
	[ -d "$(ARCHIVE)/hotplug-e2-helper.git" ] || \
	git clone https://github.com/OpenPLi/hotplug-e2-helper.git $(ARCHIVE)/hotplug-e2-helper.git; \
	cp -ra $(ARCHIVE)/hotplug-e2-helper.git $(BUILD_TMP)/hotplug-e2-helper
	set -e; cd $(BUILD_TMP)/hotplug-e2-helper; \
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
	(cd $(ARCHIVE)/tuxtxt.git; git pull;); \
	[ -d "$(ARCHIVE)/tuxtxt.git" ] || \
	git clone https://github.com/OpenPLi/tuxtxt.git $(ARCHIVE)/tuxtxt.git; \
	cp -ra $(ARCHIVE)/tuxtxt.git/libtuxtxt $(BUILD_TMP)/tuxtxtlib
	cd $(BUILD_TMP)/tuxtxtlib; \
		$(call apply_patches,$(TUXTXTLIB_PATCH)); \
		aclocal; \
		autoheader; \
		autoconf; \
		libtoolize --force; \
		automake --foreign --add-missing; \
		$(BUILDENV) \
		./configure \
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
	cp -ra $(ARCHIVE)/tuxtxt.git/tuxtxt $(BUILD_TMP)/tuxtxt
	set -e; cd $(BUILD_TMP)/tuxtxt; \
		$(call apply_patches,$(TUXTXT32BPP_PATCH)); \
		aclocal; \
		autoheader; \
		autoconf; \
		libtoolize --force; \
		automake --foreign --add-missing; \
		$(BUILDENV) \
		./configure \
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
# enigma2-ipk
#
enigma2-ipk: $(D)/enigma2.do_compile
	$(START_BUILD)
	rm -rf $(PKGPREFIX)
	install -d $(PKGPREFIX)
	install -d $(PKGS_DIR)
	$(MAKE) -C $(SOURCE_DIR)/enigma2 install DESTDIR=$(PKGPREFIX)
	rm -r $(PKGPREFIX)/usr/include $(PKGPREFIX)/usr/lib/pkgconfig
ifneq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), kerneldebug debug normal))
	find $(PKGPREFIX)/ -name '*' -exec $(TARGET)-strip --strip-unneeded {} &>/dev/null \;
endif
	cd $(PKGPREFIX) && tar -cvzf $(PKGS_DIR)/data.tar.gz *
	cd $(PACKAGES)/enigma2 && tar -cvzf $(PKGS_DIR)/control.tar.gz *
	cd $(PKGS_DIR) && echo 2.0 > debian-binary && tar -cvzf $(PKGS_DIR)/enigma2_$(BOXARCH)_$(BOXTYPE).tar.gz data.tar.gz control.tar.gz debian-binary && rm -rf data.tar.gz control.tar.gz debian-binary
	rm -rf $(PKGPREFIX)
	$(END_BUILD)
	
#
# release-enigma2
#
release-enigma2: $(RELEASE_DEPS) $(D)/enigma2 release-common release-$(BOXTYPE)
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
	cp -aR $(SKEL_ROOT)/etc/enigma2/* $(RELEASE_DIR)/etc/enigma2/
	cp -aR $(TARGET_DIR)/usr/lib/enigma2 $(RELEASE_DIR)/usr/lib
	install -m 0755 $(BASE_DIR)/machine/$(BOXTYPE)/files/rcS_ENIGMA2 $(RELEASE_DIR)/etc/init.d/rcS
#
# delete unnecessary files
#
	[ -e $(RELEASE_DIR)/usr/bin/neutrino2 ] && rm -rf $(RELEASE_DIR)/usr/bin/neutrino2 || true
	[ -e $(RELEASE_DIR)/usr/bin/titan ] && rm -rf $(RELEASE_DIR)/usr/bin/titan || true
	[ -e $(RELEASE_DIR)/usr/bin/neutrino ] && rm -rf $(RELEASE_DIR)/usr/bin/neutrino || true
#
#
#
	find $(RELEASE_DIR)/usr/lib/enigma2/ -name '*.pyc' -exec rm -f {} \;
	find $(RELEASE_DIR)/usr/lib/enigma2/ -name '*.pyo' -exec rm -f {} \;
	find $(RELEASE_DIR)/usr/lib/enigma2/ -name '*.a' -exec rm -f {} \;
	find $(RELEASE_DIR)/usr/lib/enigma2/ -name '*.o' -exec rm -f {} \;
	find $(RELEASE_DIR)/usr/lib/enigma2/ -name '*.la' -exec rm -f {} \;
#
#
#
	cp -dpfr $(RELEASE_DIR)/etc $(RELEASE_DIR)/var
	rm -fr $(RELEASE_DIR)/etc
	ln -sf /var/etc $(RELEASE_DIR)
	$(TUXBOX_CUSTOMIZE)
#
# strip
#	
ifneq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), kerneldebug debug normal))
	find $(RELEASE_DIR)/ -name '*' -exec $(TARGET)-strip --strip-unneeded {} &>/dev/null \;
endif
	$(END_BUILD)

#
# image-enigma2
#
image-enigma2: release-enigma2
	$(START_BUILD)
ifeq ($(BOXTYPE), $(filter $(BOXTYPE), fortis_hdbox octagon1008 ipbox55 ipbox9900 cuberevo cuberevo_mini cuberevo_mini2 cuberevo_250hd cuberevo_2000hd spark spark7162 atevio7500 tf7700 ufs910 ufs912 ufs913 ufs922))
	$(MAKE) flash-image-$(BOXTYPE)
endif
ifeq ($(BOXTYPE), hl101)
	$(MAKE) usb-image-$(BOXTYPE)
endif
ifeq ($(BOXTYPE), $(filter $(BOXTYPE), vuduo vuduo2 gb800se bre2zet2c osnino osninoplus osninopro))
	$(MAKE) flash-image-$(BOXTYPE)
endif
ifeq ($(BOXTYPE), $(filter $(BOXTYPE), bre2ze4k h7 hd51 hd61 osmini4k osmio4k osmio4kplus e4hdultra))
	$(MAKE) flash-image-$(BOXTYPE)-rootfs flash-image-$(BOXTYPE)-disk flash-image-$(BOXTYPE)-online
endif
ifeq ($(BOXTYPE), hd60)
	$(MAKE) flash-image-$(BOXTYPE)-multi-disk
endif
ifeq ($(BOXTYPE), $(filter $(BOXTYPE), vusolo4k vuultimo4k vuuno4k vuuno4kse vuzero4k))
	$(MAKE) flash-image-$(BOXTYPE)-rootfs flash-image-$(BOXTYPE)-disk flash-image-$(BOXTYPE)-online
endif
ifeq ($(BOXTYPE), $(filter $(BOXTYPE), vuduo4k))
	$(MAKE) flash-image-$(BOXTYPE)-rootfs flash-image-$(BOXTYPE)-multi-disk flash-image-$(BOXTYPE)-online
endif
	$(END_BUILD)
		
