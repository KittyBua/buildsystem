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
TITAN_DEPS += $(D)/timezone
TITAN_DEPS += $(D)/libcurl
TITAN_DEPS += $(D)/ffmpeg
TITAN_DEPS += $(D)/titan-libipkg 
TITAN_DEPS += $(D)/titan-libdreamdvd 
TITAN_DEPS += $(D)/titan-libeplayer3
ifeq ($(BOXARCH), sh4)
TITAN_DEPS += $(D)/tools-libmme_host
TITAN_DEPS += $(D)/tools-libmme_image
endif

ifeq ($(GRAPHLCD), graphlcd)
TITAN_CONFIG_OPTS += --with-graphlcd
endif

ifeq ($(LCD4LINUX), lcd4linux)
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
TITAN_CPPFLAGS   += -DEPLAYER3
TITAN_CPPFLAGS   += -DEXTEPLAYER3
TITAN_CPPFLAGS   += -I$(SOURCE_DIR)/titan/libeplayer3/include

ifeq ($(GSTREAMER), gstreamer)
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
TITAN_CPPFLAGS   += -DMIPSEL -DOEBUILD
endif

#
#
#
BOARD = $(BOXTYPE)

ifeq ($(BOXARCH), $(filter $(BOXARCH), arm mipsel))
BOARD = vuduo
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
	(cd $(ARCHIVE)/titan.svn; svn up;); \
	[ -d "$(ARCHIVE)/titan.svn" ] || \
	svn checkout --username=public --password=public http://sbnc.dyndns.tv/svn/titan/ $(ARCHIVE)/titan.svn; \
	cp -ra $(ARCHIVE)/titan.svn $(SOURCE_DIR)/titan; \
	set -e; cd $(SOURCE_DIR)/titan; \
		$(call apply_patches, $(TITAN_PATCH))
	@touch $@ 

$(D)/titan.config.status: $(D)/titan.do_prepare
	cd $(SOURCE_DIR)/titan; \
		./autogen.sh $(SILENT_OPT); \
		$(BUILDENV) \
		./configure $(SILENT_CONFIGURE) \
			--build=$(BUILD) \
			--host=$(TARGET) \
			$(TITAN_CONFIG_OPTS) \
			--enable-eplayer3 \
			--datadir=/usr/share \
			--libdir=/usr/lib \
			--bindir=/usr/bin \
			--prefix=/usr \
			--sysconfdir=/etc \
			--with-boxtype=$(BOARD) \
			PKG_CONFIG=$(PKG_CONFIG) \
			CPPFLAGS="$(TITAN_CPPFLAGS)"
	@touch $@

$(D)/titan.do_compile: $(D)/titan.config.status
	cd $(SOURCE_DIR)/titan; \
		$(MAKE) all
	@touch $@

$(D)/titan: $(D)/titan.do_compile
	$(MAKE) -C $(SOURCE_DIR)/titan install DESTDIR=$(TARGET_DIR)
	$(TOUCH)

#
# titan-plugins
#
$(SOURCE_DIR)/titan/plugins/config.status: $(D)/python
#$(D)/titan-plugins: $(D)/titan.do_prepare $(D)/python
	$(START_BUILD)
	cd $(SOURCE_DIR)/titan/plugins; \
		./autogen.sh $(SILENT_OPT); \
		$(BUILDENV) \
		./configure $(SILENT_CONFIGURE) \
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
#		$(MAKE) all
#		$(MAKE) -C $(SOURCE_DIR)/titan/plugins all install DESTDIR=$(TARGET_DIR)
#		$(TOUCH)		

$(D)/titan-plugins.do_compile: $(SOURCE_DIR)/titan/plugins/config.status
	cd $(SOURCE_DIR)/titan/plugins; \
		$(MAKE) all
	@touch $@

$(D)/titan-plugins: $(D)/titan-plugins.do_compile
#	$(START_BUILD)
	cd $(SOURCE_DIR)/titan/plugins
#	$(MAKE) -C $(SOURCE_DIR)/titan/plugins all install DESTDIR=$(TARGET_DIR)
	$(TOUCH)

#
# titan-libipkg
#
TITAN_LIBIPKG_PATCH =
$(D)/titan-libipkg:
	$(START_BUILD)
	cd $(SOURCE_DIR)/titan/libipkg; \
	aclocal $(ACLOCAL_FLAGS); \
	libtoolize --automake -f -c; \
	autoconf; \
	autoheader; \
	automake --add-missing; \
	$(call apply_patches, $(TITAN_LIBIPKG_PATCH)); \
	./configure $(SILENT_CONFIGURE) \
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
$(D)/titan-libdreamdvd: $(D)/libdvdnav
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
$(D)/titan-libeplayer3:
	$(START_BUILD)
	cd $(SOURCE_DIR)/titan/libeplayer3; \
		$(CONFIGURE_TOOLS) \
			--prefix= \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(TOUCH)

#
#
#
titan-clean:
	rm -f $(D)/titan.do_compile
	$(MAKE) -C $(SOURCE_DIR)/titan clean

titan-distclean:
	rm -f $(D)/titan*
	$(MAKE) -C $(SOURCE_DIR)/titan distclean

#
#
#
titan-plugins-clean:
	rm -f $(D)/titan-plugins.do_compile
	cd $(SOURCE_DIR)/titan/plugins; \
		$(MAKE) distclean

titan-plugins-distclean:
	rm -f $(D)/titan-plugins*
	$(MAKE) -C $(SOURCE_DIR)/titan distclean
		
#
# release-titan
#
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
	cp $(SKEL_ROOT)/var/etc/titan/rcconfig $(RELEASE_DIR)/var/etc/titan/rcconfig
	cp $(SKEL_ROOT)/var/etc/titan/satellites $(RELEASE_DIR)/var/etc/titan/satellites
	cp $(SKEL_ROOT)/var/etc/titan/transponder $(RELEASE_DIR)/var/etc/titan/transponder
	cp $(SKEL_ROOT)/var/etc/titan/provider $(RELEASE_DIR)/var/etc/titan/provider
	cp -af $(SKEL_ROOT)/var/usr/share/fonts $(RELEASE_DIR)/var/usr/share
	cp -aR $(SOURCE_DIR)/titan/skins/default $(RELEASE_DIR)/var/usr/local/share/titan/skin
	cp -aR $(SOURCE_DIR)/titan/web $(RELEASE_DIR)/var/usr/local/share/titan
	cp -aR $(SKEL_ROOT)/mnt $(RELEASE_DIR)/	
#
# po
#
	LANGUAGES='de el en es fr it lt nl pl ru vi'
	for lang in $$LANGUAGES; do \
		cd $(SOURCE_DIR)/titan/po/$$lang/LC_MESSAGES && msgfmt -o titan.mo titan.po_auto.po; \
	done
	install -m 0755 $(BASE_DIR)/machine/$(BOXTYPE)/files/rcS_TITAN $(RELEASE_DIR)/etc/init.d/rcS
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
#gstreamer
#
ifeq ($(GSTREAMER), gstreamer)
	cp -aR $(TARGET_DIR)/usr/lib/gstreamer-1.0 $(RELEASE_DIR)/usr/lib
	cp -aR $(TARGET_DIR)/usr/lib/gio $(RELEASE_DIR)/usr/lib
endif
#
# python
#
ifeq ($(PYTHON), python)
	install -d $(RELEASE_DIR)/$(PYTHON_DIR)
	cp -R $(TARGET_DIR)/$(PYTHON_DIR)/* $(RELEASE_DIR)/$(PYTHON_DIR)/
	install -d $(RELEASE_DIR)/$(PYTHON_INCLUDE_DIR)
	cp $(TARGET_DIR)/$(PYTHON_INCLUDE_DIR)/pyconfig.h $(RELEASE_DIR)/$(PYTHON_INCLUDE_DIR)
endif
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
ifeq ($(PYTHON), python)
	find $(RELEASE_DIR)/$(PYTHON_DIR)/ -name '*.a' -exec rm -f {} \;
	find $(RELEASE_DIR)/$(PYTHON_DIR)/ -name '*.c' -exec rm -f {} \;
	find $(RELEASE_DIR)/$(PYTHON_DIR)/ -name '*.pyx' -exec rm -f {} \;
	find $(RELEASE_DIR)/$(PYTHON_DIR)/ -name '*.py' -exec rm -f {} \;
	find $(RELEASE_DIR)/$(PYTHON_DIR)/ -name '*.o' -exec rm -f {} \;
	find $(RELEASE_DIR)/$(PYTHON_DIR)/ -name '*.la' -exec rm -f {} \;
endif
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
ifeq ($(BOXARCH), sh4)
	rm -rf $(RELEASE_DIR)/usr/lib/enigma2
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


