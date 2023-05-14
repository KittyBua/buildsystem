#
# TITAN
#
TITAN_DEPS  = $(D)/bootstrap
TITAN_DEPS += $(D)/libopenthreads
TITAN_DEPS += $(D)/libpng
TITAN_DEPS += $(D)/freetype
TITAN_DEPS += $(D)/libjpeg
TITAN_DEPS += $(D)/zlib
TITAN_DEPS += $(D)/openssl
TITAN_DEPS += $(D)/libcurl
TITAN_DEPS += $(D)/ffmpeg
ifeq ($(BOXARCH), sh4)
TITAN_DEPS += $(D)/tools-libmme_host
TITAN_DEPS += $(D)/tools-libmme_image
endif

ifeq ($(GRAPHLCD), graphlcd)
TITAN_DEPS += $(D)/graphlcd
TITAN_CONFIG_OPTS += --with-graphlcd
endif

ifeq ($(LCD4LINUX), lcd4linux)
TITAN_DEPS += $(D)/lcd4linux
TITAN_CONFIG_OPTS += --with-lcd4linux
endif

ifeq ($(BOXARCH), sh4)
TITAN_CONFIG_OPTS += --enable-multicom324
endif

TITAN_CPPFLAGS   += -DDVDPLAYER
TITAN_CPPFLAGS   += -Wno-unused-but-set-variable

ifeq ($(BOXARCH), sh4)
TITAN_CPPFLAGS   += -I$(KERNEL_DIR)/include
TITAN_CPPFLAGS   += -I$(DRIVER_DIR)/include
TITAN_CPPFLAGS   += -I$(DRIVER_DIR)/bpamem
endif

TITAN_CPPFLAGS   += -I$(TARGET_DIR)/usr/include
TITAN_CPPFLAGS   += -I$(TARGET_DIR)/usr/include/freetype2
TITAN_CPPFLAGS   += -I$(TARGET_DIR)/usr/include/openssl
TITAN_CPPFLAGS   += -I$(TARGET_DIR)/usr/include/libpng16
TITAN_CPPFLAGS   += -I$(TARGET_DIR)/usr/include/dreamdvd
TITAN_CPPFLAGS   += -I$(TOOLS_DIR)/libmme_image
TITAN_CPPFLAGS   += -L$(TARGET_DIR)/usr/lib
TITAN_CPPFLAGS   += -I$(TARGET_DIR)/usr/include/python
TITAN_CPPFLAGS   += -L$(SOURCE_DIR)/titan/libipkg
TITAN_CPPFLAGS   += -DOEBUILD -DOVBUILD
TITAN_CPPFLAGS   += -I$(SOURCE_DIR)

TITAN_LIBEPLAYER3 =
ifeq ($(EXTEPLAYER3), exteplayer3)
TITAN_LIBEPLAYER3 = $(D)/titan-libeplayer3
TITAN_CONFIG_OPTS += --enable-eplayer3
TITAN_CPPFLAGS   += -DEPLAYER3
TITAN_CPPFLAGS   += -DEXTEPLAYER3
TITAN_CPPFLAGS   += -I$(SOURCE_DIR)/titan/libeplayer3/include
endif

ifeq ($(GSTREAMER), gstreamer)
TITAN_DEPS  += $(D)/gstreamer 
TITAN_DEPS  += $(D)/gst_plugins_base 
TITAN_DEPS  += $(D)/gst_plugins_good 
TITAN_DEPS  += $(D)/gst_plugins_bad 
TITAN_DEPS  += $(D)/gst_plugins_ugly 
TITAN_DEPS  += $(D)/gst_plugins_subsink
TITAN_DEPS  += $(D)/gst_plugins_dvbmediasink
TITAN_CONFIG_OPTS += --enable-gstreamer
TITAN_CPPFLAGS   += -DEPLAYER4
TITAN_CPPFLAGS   += -I$(TARGET_DIR)/usr/include/gstreamer-1.0
TITAN_CPPFLAGS   += -I$(TARGET_DIR)/usr/include/glib-2.0
TITAN_CPPFLAGS   += -I$(TARGET_DIR)/usr/include/libxml2
TITAN_CPPFLAGS   += -I$(TARGET_DIR)/usr/lib/gstreamer-1.0/include
TITAN_CPPFLAGS   += $(shell $(PKG_CONFIG) --cflags --libs gstreamer-1.0)
TITAN_CPPFLAGS   += $(shell $(PKG_CONFIG) --cflags --libs gstreamer-audio-1.0)
TITAN_CPPFLAGS   += $(shell $(PKG_CONFIG) --cflags --libs gstreamer-video-1.0)
TITAN_CPPFLAGS   += $(shell $(PKG_CONFIG) --cflags --libs glib-2.0)
endif

ifeq ($(BOXARCH), sh4)
TITAN_CPPFLAGS   += -DSH4
else
TITAN_CPPFLAGS   += -DMIPSEL
endif

#
# titan
#
ifeq ($(BOXARCH), sh4)
TITAN_PATCH = titan-sh4.patch
else
TITAN_PATCH = titan.patch
endif

$(D)/titan.do_prepare: $(TITAN_DEPS)
	$(START_BUILD)
	rm -rf $(SOURCE_DIR)/titan
	[ -d "$(ARCHIVE)/titan.svn" ] && \
	(cd $(ARCHIVE)/titan.svn; svn update --username=public --password=public -q;); \
	[ -d "$(ARCHIVE)/titan.svn" ] || \
	svn checkout --username=public --password=public http://sbnc.dyndns.tv/svn/titan/ $(ARCHIVE)/titan.svn -q; \
	cp -ra $(ARCHIVE)/titan.svn $(SOURCE_DIR)/titan; \
	set -e; cd $(SOURCE_DIR)/titan; \
		$(call apply_patches, $(TITAN_PATCH))
	@touch $@ 

$(D)/titan.config.status: $(D)/titan.do_prepare
	cd $(SOURCE_DIR)/titan/titan; \
		./autogen.sh; \
		$(BUILDENV) \
		./configure \
			--build=$(BUILD) \
			--host=$(TARGET) \
			$(TITAN_CONFIG_OPTS) \
			--datadir=/usr/share \
			--libdir=/usr/lib \
			--bindir=/usr/bin \
			--prefix=/usr \
			--sysconfdir=/etc \
			--with-boxtype=$(BOXTYPE) \
			PKG_CONFIG=$(PKG_CONFIG) \
			CPPFLAGS="$(TITAN_CPPFLAGS)"
	@touch $@

$(D)/titan.do_compile: $(D)/titan.config.status $(D)/titan-libipkg $(D)/titan-libdreamdvd $(TITAN_LIBEPLAYER3)
	cd $(SOURCE_DIR)/titan/titan; \
		$(MAKE) all
	@touch $@

$(D)/titan: $(D)/titan.do_compile
	$(MAKE) -C $(SOURCE_DIR)/titan/titan install DESTDIR=$(TARGET_DIR)
	$(TOUCH)

#
# titan-libipkg
#
TITAN_LIBIPKG_PATCH =
$(D)/titan-libipkg: $(D)/titan.do_prepare
	$(START_BUILD)
	cd $(SOURCE_DIR)/titan/libipkg; \
	aclocal $(ACLOCAL_FLAGS); \
	libtoolize --automake -f -c; \
	autoconf; \
	autoheader; \
	automake --add-missing; \
	$(call apply_patches, $(TITAN_LIBIPKG_PATCH)); \
	./configure \
		--build=$(BUILD) \
		--host=$(TARGET) \
		$(TITAN_CONFIG_OPTS) \
		--datadir=/usr/share \
		--libdir=/usr/lib \
		--bindir=/usr/bin \
		--prefix=/usr \
		--sysconfdir=/etc \
		PKG_CONFIG=$(PKG_CONFIG) \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
		cp $(SOURCE_DIR)/titan/libipkg/libipkg.pc $(TARGET_LIB_DIR)/pkgconfig
		$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libipkg.pc
	$(TOUCH)

#
# titan-libdreamdvd
#
$(D)/titan-libdreamdvd: $(D)/libdvdnav $(D)/titan.do_prepare
	$(START_BUILD)
	export PATH=$(hostprefix)/bin:$(PATH) && \
	cd $(SOURCE_DIR)/titan/libdreamdvd && \
		./autogen.sh; \
		libtoolize --force && \
		aclocal -I $(TARGET_DIR)/usr/share/aclocal && \
		autoconf && \
		automake --foreign --add-missing && \
		$(BUILDENV) \
		./configure \
			--build=$(BUILD) \
			--host=$(TARGET) \
			--prefix=/ \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libdreamdvd.pc
	$(TOUCH)

#
# titan-libeplayer3
#	
TITAN_LIBEPLAYER3_PATCH =
$(D)/titan-libeplayer3: $(D)/titan.do_prepare
	$(START_BUILD)
	cd $(SOURCE_DIR)/titan/libeplayer3; \
		$(CONFIGURE_TOOLS) \
			--prefix=/usr \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(TOUCH)

#
#
#
titan-clean:
	rm -f $(D)/titan.do_compile
	$(MAKE) -C $(SOURCE_DIR)/titan/titan clean

titan-distclean:
	rm -f $(D)/titan*
	$(MAKE) -C $(SOURCE_DIR)/titan/titan distclean
	
#
# titan-plugins
#
$(SOURCE_DIR)/titan/plugins/config.status: $(D)/titan $(D)/python
	$(START_BUILD)
	cd $(SOURCE_DIR)/titan/plugins; \
		./autogen.sh; \
		$(BUILDENV) \
		./configure \
			--build=$(BUILD) \
			--host=$(TARGET) \
			$(TITAN_CONFIG_OPTS) \
			--datadir=/usr/share \
			--libdir=/usr/lib \
			--bindir=/usr/bin \
			--prefix=/usr \
			--sysconfdir=/etc \
			PKG_CONFIG=$(PKG_CONFIG) \
			CPPFLAGS="$(TITAN_CPPFLAGS)"
	@touch $@

$(D)/titan-plugins.do_compile: $(SOURCE_DIR)/titan/plugins/config.status
	cd $(SOURCE_DIR)/titan/plugins; \
		$(MAKE) all
	@touch $@

$(D)/titan-plugins: $(D)/titan-plugins.do_compile
	cd $(SOURCE_DIR)/titan/plugins
	$(MAKE) -C $(SOURCE_DIR)/titan/plugins all install DESTDIR=$(TARGET_DIR)
	$(TOUCH)
	
#
#
#
titan-plugins-clean:
	rm -f $(D)/titan-plugins.do_compile
	$(MAKE) -C $(SOURCE_DIR)/titan/plugins clean

#
#
#
titan-plugins-distclean:
	rm -f $(D)/titan-plugins*
	$(MAKE) -C $(SOURCE_DIR)/titan distclean
		
#
# release-titan
#
LANGUAGES=de el en es fr it lt nl pl ru vi
release-titan: release-common release-$(BOXTYPE) $(D)/titan
	$(START_BUILD)
	install -d $(RELEASE_DIR)/var/etc/titan
	install -d $(RELEASE_DIR)/var/etc/autostart
	install -d $(RELEASE_DIR)/var/usr/local/share/titan/{skin,po,web,plugins}
	install -d $(RELEASE_DIR)/var/usr/local/share/titan/po/{de,el,en,es,fr,it,lt,nl,pl,ru,vi}
	install -d $(RELEASE_DIR)/var/usr/local/share/titan/po/de/LC_MESSAGES
	install -d $(RELEASE_DIR)/var/usr/local/share/titan/po/el/LC_MESSAGES
	install -d $(RELEASE_DIR)/var/usr/local/share/titan/po/en/LC_MESSAGES
	install -d $(RELEASE_DIR)/var/usr/local/share/titan/po/es/LC_MESSAGES
	install -d $(RELEASE_DIR)/var/usr/local/share/titan/po/fr/LC_MESSAGES
	install -d $(RELEASE_DIR)/var/usr/local/share/titan/po/it/LC_MESSAGES
	install -d $(RELEASE_DIR)/var/usr/local/share/titan/po/lt/LC_MESSAGES
	install -d $(RELEASE_DIR)/var/usr/local/share/titan/po/nl/LC_MESSAGES
	install -d $(RELEASE_DIR)/var/usr/local/share/titan/po/pl/LC_MESSAGES
	install -d $(RELEASE_DIR)/var/usr/local/share/titan/po/ru/LC_MESSAGES
	install -d $(RELEASE_DIR)/var/usr/local/share/titan/po/vi/LC_MESSAGES
	install -d $(RELEASE_DIR)/var/usr/share/fonts
	cp -af $(TARGET_DIR)/usr/bin/titan $(RELEASE_DIR)/usr/bin/
	cp $(SKEL_ROOT)/var/etc/titan/titan.cfg $(RELEASE_DIR)/var/etc/titan/titan.cfg
	cp $(SKEL_ROOT)/var/etc/titan/httpd.cfg $(RELEASE_DIR)/var/etc/titan/httpd.cfg
	cp $(SKEL_ROOT)/var/etc/titan/rcconfig.$(BOXTYPE) $(RELEASE_DIR)/var/etc/titan/rcconfig
	cp $(SKEL_ROOT)/var/etc/titan/satellites $(RELEASE_DIR)/var/etc/titan/satellites
	cp $(SKEL_ROOT)/var/etc/titan/transponder $(RELEASE_DIR)/var/etc/titan/transponder
	cp $(SKEL_ROOT)/var/etc/titan/provider $(RELEASE_DIR)/var/etc/titan/provider
	cp -af $(SKEL_ROOT)/var/usr/share/fonts $(RELEASE_DIR)/var/usr/share
	cp -aR $(SOURCE_DIR)/titan/skins/default $(RELEASE_DIR)/var/usr/local/share/titan/skin
	cp -aR $(SOURCE_DIR)/titan/web $(RELEASE_DIR)/var/usr/local/share/titan
#	cp -aR $(SKEL_ROOT)/mnt $(RELEASE_DIR)/	
#
# po
#
	for lang in $(LANGUAGES); do \
		cd $(SOURCE_DIR)/titan/po/$$lang/LC_MESSAGES && msgfmt -v titan.po_auto.po -o titan.mo; \
		install -m 0666 titan.mo $(RELEASE_DIR)/var/usr/local/share/titan/po/$$lang/LC_MESSAGES/titan.mo; \
	done
	install -m 0755 $(BASE_DIR)/machine/$(BOXTYPE)/files/rcS_TITAN $(RELEASE_DIR)/etc/init.d/rcS
#
# delete unnecessary files
#
	[ -e $(RELEASE_DIR)/usr/bin/neutrino2 ] && rm -rf $(RELEASE_DIR)/usr/bin/neutrino2 || true
	[ -e $(RELEASE_DIR)/usr/bin/enigma2 ] && rm -rf $(RELEASE_DIR)/usr/bin/enigma2 || true
	[ -e $(RELEASE_DIR)/usr/bin/neutrino ] && rm -rf $(RELEASE_DIR)/usr/bin/neutrino || true
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
# image-titan
#
image-titan: release-titan
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
	$(MAKE) flash-image-$(BOXTYPE)-rootfs flash-image-$(BOXTYPE)-disk $(MAKE) flash-image-$(BOXTYPE)-online
endif
ifeq ($(BOXTYPE), hd60)
	$(MAKE) flash-image-$(BOXTYPE)-multi-disk
endif
ifeq ($(BOXTYPE), $(filter $(BOXTYPE), vusolo4k vuultimo4k vuuno4k vuuno4kse vuzero4k))
	$(MAKE) flash-image-$(BOXTYPE)-rootfs flash-image-$(BOXTYPE)-disk $(MAKE) flash-image-$(BOXTYPE)-online
endif
ifeq ($(BOXTYPE), $(filter $(BOXTYPE), vuduo4k))
	$(MAKE) flash-image-$(BOXTYPE)-rootfs flash-image-$(BOXTYPE)-multi-disk $(MAKE) flash-image-$(BOXTYPE)-online
endif
	$(END_BUILD)

