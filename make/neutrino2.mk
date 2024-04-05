#
# NEUTRINO2
#
NEUTRINO2_DEPS  = $(D)/bootstrap
NEUTRINO2_DEPS += $(D)/e2fsprogs
NEUTRINO2_DEPS += $(D)/ncurses 
NEUTRINO2_DEPS += $(D)/libcurl
NEUTRINO2_DEPS += $(D)/libpng 
NEUTRINO2_DEPS += $(D)/libjpeg 
NEUTRINO2_DEPS += $(D)/giflib 
NEUTRINO2_DEPS += $(D)/freetype
NEUTRINO2_DEPS += $(D)/ffmpeg
NEUTRINO2_DEPS += $(D)/libfribidi
NEUTRINO2_DEPS += $(D)/libopenthreads
NEUTRINO2_DEPS += $(D)/openssl

#
# CFLAGS / CPPFLAGS
#
NEUTRINO2_CFLAGS       = -Wall -W -Wshadow -pipe -Os
NEUTRINO2_CFLAGS      += -D__KERNEL_STRICT_NAMES
NEUTRINO2_CFLAGS      += -D__STDC_FORMAT_MACROS
NEUTRINO2_CFLAGS      += -D__STDC_CONSTANT_MACROS
NEUTRINO2_CFLAGS      += -fno-strict-aliasing -funsigned-char -ffunction-sections -fdata-sections

NEUTRINO2_CPPFLAGS     = -I$(TARGET_DIR)/usr/include
NEUTRINO2_CPPFLAGS    += -ffunction-sections -fdata-sections
NEUTRINO2_CPPFLAGS    += -I$(CROSS_DIR)/$(TARGET)/sys-root/usr/include

ifeq ($(BOXARCH), sh4)
NEUTRINO2_CPPFLAGS    += -I$(KERNEL_DIR)/include
NEUTRINO2_CPPFLAGS    += -I$(DRIVER_DIR)/include
NEUTRINO2_CPPFLAGS    += -I$(DRIVER_DIR)/bpamem
endif

ifeq ($(BOXTYPE), $(filter $(BOXTYPE), spark spark7162))
NEUTRINO2_CPPFLAGS += -I$(DRIVER_DIR)/frontcontroller/aotom_spark
endif

NEUTRINO2_CONFIG_OPTS =

ifeq ($(BOXARCH), $(filter $(BOXARCH), arm mips))
ifeq ($(GSTREAMER), gstreamer)
NEUTRINO2_CPPFLAGS     += $(shell $(PKG_CONFIG) --cflags --libs gstreamer-1.0)
NEUTRINO2_CPPFLAGS     += $(shell $(PKG_CONFIG) --cflags --libs gstreamer-audio-1.0)
NEUTRINO2_CPPFLAGS     += $(shell $(PKG_CONFIG) --cflags --libs gstreamer-video-1.0)
NEUTRINO2_CPPFLAGS     += $(shell $(PKG_CONFIG) --cflags --libs glib-2.0)
NEUTRINO2_CONFIG_OPTS += --enable-gstreamer --with-gstversion=1.0
endif
endif

ifeq ($(BOXARCH), $(filter $(BOXARCH), arm mips))
ifeq ($(PYTHON), python)
NEUTRINO2_CONFIG_OPTS += --enable-python PYTHON_CPPFLAGS="-I$(TARGET_DIR)/usr/include/python2.7" PYTHON_LIBS="-L$(TARGET_DIR)/usr/lib -lpython2.7" PYTHON_SITE_PKG="$(TARGET_DIR)/usr/lib/python2.7/site-packages"
endif
endif

ifeq ($(LUA), lua)
NEUTRINO2_CONFIG_OPTS += --enable-lua
endif

ifeq ($(CICAM), ci-cam)
NEUTRINO2_CONFIG_OPTS += --enable-ci
endif

ifeq ($(SCART), scart)
NEUTRINO2_CONFIG_OPTS += --enable-scart
endif

ifeq ($(LCD), lcd)
NEUTRINO2_CONFIG_OPTS += --enable-lcd
endif

ifeq ($(LCD), tftlcd)
NEUTRINO2_CONFIG_OPTS += --enable-lcd --enable-tftlcd
endif

ifeq ($(LCD), 4-digits)
NEUTRINO2_CONFIG_OPTS += --enable-4digits
endif

ifeq ($(FKEYS), fkeys)
NEUTRINO2_CONFIG_OPTS += --enable-functionkeys
endif

NEUTRINO2_PATCHES =

$(D)/neutrino2.do_prepare: $(NEUTRINO2_DEPS)
	$(START_BUILD)
	rm -rf $(SOURCE_DIR)/neutrino2
	[ -d "$(ARCHIVE)/neutrino2.git" ] && \
	(cd $(ARCHIVE)/neutrino2.git; git pull;); \
	[ -d "$(ARCHIVE)/neutrino2.git" ] || \
	git clone https://github.com/mohousch/neutrino2.git $(ARCHIVE)/neutrino2.git; \
	cp -ra $(ARCHIVE)/neutrino2.git $(SOURCE_DIR)/neutrino2; \
	set -e; cd $(SOURCE_DIR)/neutrino2/neutrino2; \
		$(call apply_patches,$(NEUTRINO2_PATCHES))
	@touch $@

$(D)/neutrino2.config.status: $(D)/neutrino2.do_prepare
	cd $(SOURCE_DIR)/neutrino2/neutrino2; \
		./autogen.sh; \
		$(BUILDENV) \
		./configure \
			--build=$(BUILD) \
			--host=$(TARGET) \
			--prefix=/usr \
			--enable-silent-rules \
			--enable-maintainer-mode \
			--with-boxtype=$(BOXTYPE) \
			$(NEUTRINO2_CONFIG_OPTS) \
			PKG_CONFIG=$(PKG_CONFIG) \
			PKG_CONFIG_PATH=$(PKG_CONFIG_PATH) \
			CFLAGS="$(NEUTRINO2_CFLAGS)" CXXFLAGS="$(NEUTRINO2_CFLAGS)" CPPFLAGS="$(NEUTRINO2_CPPFLAGS)" LDFLAGS="$(TARGET_LDFLAGS)"
	@touch $@

$(D)/neutrino2.do_compile: $(D)/neutrino2.config.status
	cd $(SOURCE_DIR)/neutrino2/neutrino2; \
		$(MAKE) all
	@touch $@

$(D)/neutrino2: $(D)/neutrino2.do_compile
	$(MAKE) -C $(SOURCE_DIR)/neutrino2/neutrino2 install DESTDIR=$(TARGET_DIR)
	$(TOUCH)

neutrino2-clean:
	rm -f $(D)/neutrino2.do_compile
	$(MAKE) -C $(SOURCE_DIR)/neutrino2/neutrino2 clean

neutrino2-distclean:
	rm -f $(D)/neutrino2*
	$(MAKE) -C $(SOURCE_DIR)/neutrino2/neutrino2 distclean
	
#
# neutrino2 plugins
#
N2_PLUGINS_PATCHES =

$(D)/neutrino2-plugins.do_prepare: $(D)/neutrino2.do_prepare
	$(START_BUILD)
	set -e; cd $(SOURCE_DIR)/neutrino2/plugins; \
		$(call apply_patches, $(N2_PLUGINS_PATCHES))
	@touch $@

$(D)/neutrino2-plugins.config.status: $(D)/neutrino2-plugins.do_prepare
	cd $(SOURCE_DIR)/neutrino2/plugins; \
		./autogen.sh; \
		$(BUILDENV) \
		./configure \
			--host=$(TARGET) \
			--build=$(BUILD) \
			--enable-silent-rules \
			--with-boxtype=$(BOXTYPE) \
			$(NEUTRINO2_CONFIG_OPTS) \
			PKG_CONFIG=$(PKG_CONFIG) \
			PKG_CONFIG_PATH=$(PKG_CONFIG_PATH) \
			CFLAGS="$(NEUTRINO2_CFLAGS)" CXXFLAGS="$(NEUTRINO2_CFLAGS)" CPPFLAGS="$(NEUTRINO2_CPPFLAGS)" \
			LDFLAGS="$(TARGET_LDFLAGS)"
	@touch $@

$(D)/neutrino2-plugins.do_compile: $(D)/neutrino2-plugins.config.status
	cd $(SOURCE_DIR)/neutrino2/plugins; \
	$(MAKE)
	@touch $@

$(D)/neutrino2-plugins: $(D)/neutrino2-plugins.do_compile
	$(MAKE) -C $(SOURCE_DIR)/neutrino2/plugins install DESTDIR=$(TARGET_DIR)
	touch $(D)/$(notdir $@)

neutrino2-plugins-clean:
	rm -f $(D)/neutrino2-plugins.do_compile
	$(MAKE) -C $(SOURCE_DIR)/neutrino2/plugins clean

neutrino2-plugins-distclean:
	rm -f $(D)/neutrino2-plugins*
	$(MAKE) -C $(SOURCE_DIR)/neutrino2/plugins distclean
	rm -f $(SOURCE_DIR)/neutrino2/plugins/config.status
	
#
# neutrino2-ipk
#
neutrino2-ipk: $(D)/neutrino2.do_compile
	$(START_BUILD)
	rm -rf $(PKGPREFIX)
	install -d $(PKGPREFIX)
	install -d $(PKGS_DIR)
	$(MAKE) -C $(SOURCE_DIR)/neutrino2/neutrino2 install DESTDIR=$(PKGPREFIX)
ifneq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), kerneldebug debug normal))
	find $(PKGPREFIX)/ -name '*' -exec $(TARGET)-strip --strip-unneeded {} &>/dev/null \;
endif
	cd $(PKGPREFIX) && tar -cvzf $(PKGS_DIR)/data.tar.gz *
	cd $(PACKAGES)/neutrino2 && tar -cvzf $(PKGS_DIR)/control.tar.gz *
	cd $(PKGS_DIR) && echo 2.0 > debian-binary && tar -cvzf $(PKGS_DIR)/neutrino2_$(BOXARCH)_$(BOXTYPE)_$(shell date '+%d.%m.%Y-%H.%M').tar.gz data.tar.gz control.tar.gz debian-binary && rm -rf data.tar.gz control.tar.gz debian-binary
	rm -rf $(PKGPREFIX)
	$(END_BUILD)
	
#
# neutrino2-plugins-ipk
#
neutrino2-plugins-ipk: $(D)/neutrino2-plugins.do_compile
	$(START_BUILD)
	rm -rf $(PKGPREFIX)
	install -d $(PKGPREFIX)
	install -d $(PKGS_DIR)
	$(MAKE) -C $(SOURCE_DIR)/neutrino2/plugins install DESTDIR=$(PKGPREFIX)
ifneq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), kerneldebug debug normal))
	find $(PKGPREFIX)/ -name '*' -exec $(TARGET)-strip --strip-unneeded {} &>/dev/null \;
endif
	cd $(PKGPREFIX) && tar -cvzf $(PKGS_DIR)/data.tar.gz *
	cd $(PACKAGES)/neutrino2 && tar -cvzf $(PKGS_DIR)/control.tar.gz *
	cd $(PKGS_DIR) && echo 2.0 > debian-binary && tar -cvzf $(PKGS_DIR)/neutrino2_plugins_$(BOXARCH)_$(BOXTYPE)_$(shell date '+%d.%m.%Y-%H.%M').tar.gz data.tar.gz control.tar.gz debian-binary && rm -rf data.tar.gz control.tar.gz debian-binary
	rm -rf $(PKGPREFIX)
	$(END_BUILD)
	
#
# release-neutrino2
#
release-neutrino2: $(RELEASE_DEPS) $(D)/neutrino2 $(D)/neutrino2-plugins release-common release-$(BOXTYPE)
	$(START_BUILD)
	install -d $(RELEASE_DIR)/var/tuxbox
	install -d $(RELEASE_DIR)/usr/share/iso-codes
	install -d $(RELEASE_DIR)/usr/share/tuxbox
	install -d $(RELEASE_DIR)/var/tuxbox
	install -d $(RELEASE_DIR)/var/tuxbox/config/{webtv,zapit}
	install -d $(RELEASE_DIR)/var/tuxbox/plugins
	install -d $(RELEASE_DIR)/var/httpd
	cp -af $(TARGET_DIR)/usr/bin/neutrino2 $(RELEASE_DIR)/usr/bin/
	cp -af $(TARGET_DIR)/usr/bin/backup.sh $(RELEASE_DIR)/usr/bin/
	cp -af $(TARGET_DIR)/usr/bin/init_hdd.sh $(RELEASE_DIR)/usr/bin/
	cp -af $(TARGET_DIR)/usr/bin/install.sh $(RELEASE_DIR)/usr/bin/
	cp -af $(TARGET_DIR)/usr/bin/restore.sh $(RELEASE_DIR)/usr/bin/
	cp -aR $(TARGET_DIR)/usr/share/tuxbox/neutrino2 $(RELEASE_DIR)/usr/share/tuxbox
	cp -aR $(TARGET_DIR)/var/tuxbox/* $(RELEASE_DIR)/var/tuxbox
	[ -e $(RELEASE_DIR)/var/tuxbox/control/audioplayer.end ] && rm -rf $(RELEASE_DIR)/var/tuxbox/control || true
	install -m 0755 $(BASE_DIR)/machine/$(BOXTYPE)/files/rcS_NEUTRINO2 $(RELEASE_DIR)/etc/init.d/rcS
#
# delete unnecessary files
#
ifeq ($(BOXARCH), sh4)
	[ -e $(RELEASE_DIR)/usr/bin/titan ] && rm -rf $(RELEASE_DIR)/usr/bin/titan || true
	[ -e $(RELEASE_DIR)/usr/bin/enigma2 ] && rm -rf $(RELEASE_DIR)/usr/bin/enigma2 || true
	[ -e $(RELEASE_DIR)/usr/bin/neutrino ] && rm -rf $(RELEASE_DIR)/usr/bin/neutrino || true
	[ -e $(RELEASE_DIR)/sbin/sfdisk ] && rm -rf $(RELEASE_DIR)/sbin/sfdisk || true
	[ -e $(RELEASE_DIR)/usr/bin/ipkg-cl ] && rm -rf $(RELEASE_DIR)/usr/bin/ipkg-cl || true
	[ -e $(RELEASE_DIR)/usr/bin/eplayer3 ] && rm -rf $(RELEASE_DIR)/usr/bin/eplayer3 || true
	[ -e $(RELEASE_DIR)/usr/bin/exteplayer3 ] && rm -rf $(RELEASE_DIR)/usr/bin/exteplayer3 || true
	[ -e $(RELEASE_DIR)/usr/bin/lircd ] && rm -rf $(RELEASE_DIR)/usr/bin/lircd || true
	rm -rf $(RELEASE_DIR)/usr/share/zoneinfo
	rm -rf $(RELEASE_DIR)/usr/share/fonts
	rm -rf $(RELEASE_DIR)/usr/share/iso-codes
	rm -rf $(RELEASE_DIR)/usr/lib/libavahi*
	rm -rf $(RELEASE_DIR)/usr/lib/libgst*
	rm -rf $(RELEASE_DIR)/usr/bin/hotplug_e2_helper
	[ -e $(RELEASE_DIR)/usr/bin/ipkg-cl ] && rm -rf $(RELEASE_DIR)/usr/bin/ipkg-cl || true
	[ -e $(RELEASE_DIR)/usr/lib/libipkg.so ] && rm -rf $(RELEASE_DIR)/usr/lib/libipkg* || true
	[ -e $(RELEASE_DIR)/usr/lib/libarchive.so ] && rm -rf $(RELEASE_DIR)/usr/lib/libarchive* || true
	[ -e $(RELEASE_DIR)/usr/lib/libdbus-1.so ] && rm -rf $(RELEASE_DIR)/usr/lib/libdbus-1* || true
	[ -e $(RELEASE_DIR)/usr/lib/libeplayer3.so ] && rm -rf $(RELEASE_DIR)/usr/lib/libeplayer3* || true
	[ -e $(RELEASE_DIR)/usr/lib/libexteplayer3.so ] && rm -rf $(RELEASE_DIR)/usr/lib/libexteplayer3* || true
	[ -e $(RELEASE_DIR)/usr/lib/libglib-2.0.so ] && rm -rf $(RELEASE_DIR)/usr/lib/libglib-2.0* || true
	[ -e $(RELEASE_DIR)/usr/lib/libgmodule-2.0.so ] && rm -rf $(RELEASE_DIR)/usr/lib/libgmodule-2.0* || true
	[ -e $(RELEASE_DIR)/usr/lib/libgobject-2.0.so ] && rm -rf $(RELEASE_DIR)/usr/lib/libgobject-2.0* || true
	[ -e $(RELEASE_DIR)/usr/lib/libgthread-2.0.so ] && rm -rf $(RELEASE_DIR)/usr/lib/libgthread-2.0* || true
	[ -e $(RELEASE_DIR)/usr/lib/libpython2.7.so ] && rm -rf $(RELEASE_DIR)/usr/lib/libpython* || true
endif
#
# imigrate /etc to /var/etc
#
	cp -dpfr $(RELEASE_DIR)/etc $(RELEASE_DIR)/var
	rm -fr $(RELEASE_DIR)/etc
	ln -sf /var/etc $(RELEASE_DIR)
#
# strip
#	
ifneq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), kerneldebug debug normal))
	find $(RELEASE_DIR)/ -name '*' -exec $(TARGET)-strip --strip-unneeded {} &>/dev/null \;
endif
	$(END_BUILD)

#
# image-neutrino2
#
image-neutrino2: release-neutrino2
	$(START_BUILD)
ifeq ($(BOXTYPE), $(filter $(BOXTYPE), fortis_hdbox octagon1008 cuberevo cuberevo_mini cuberevo_mini2 cuberevo_2000hd spark spark7162 atevio7500 ufs910 ufs912))
	$(MAKE) flash-image-$(BOXTYPE)
endif
ifeq ($(BOXTYPE), hl101)
	$(MAKE) usb-image-$(BOXTYPE)
endif
ifeq ($(BOXTYPE), $(filter $(BOXTYPE), vuduo vuduo2 gb800se bre2zet2c osnino osninoplus osninopro dm8000))
	$(MAKE) flash-image-$(BOXTYPE)
endif
ifeq ($(BOXTYPE), $(filter $(BOXTYPE), bre2ze4k h7 hd51 hd60 osmini4k osmio4k osmio4kplus e4hdultra))
	$(MAKE) flash-image-$(BOXTYPE)-disk flash-image-$(BOXTYPE)-rootfs
endif
ifeq ($(BOXTYPE), $(filter $(BOXTYPE), vuduo4k vusolo4k vuultimo4k vuuno4k vuuno4kse vuzero4k))
	$(MAKE) flash-image-$(BOXTYPE)-rootfs
endif
	$(END_BUILD)

