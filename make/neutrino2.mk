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
NEUTRINO2_DEPS += $(D)/libid3tag
NEUTRINO2_DEPS += $(D)/libmad
NEUTRINO2_DEPS += $(D)/libvorbisidec
NEUTRINO2_DEPS += $(D)/flac
NEUTRINO2_DEPS += $(D)/libopenthreads
NEUTRINO2_DEPS += $(D)/libass
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

ifeq ($(GSTREAMER), gstreamer)
NEUTRINO2_CPPFLAGS     += $(shell $(PKG_CONFIG) --cflags --libs gstreamer-1.0)
NEUTRINO2_CPPFLAGS     += $(shell $(PKG_CONFIG) --cflags --libs gstreamer-audio-1.0)
NEUTRINO2_CPPFLAGS     += $(shell $(PKG_CONFIG) --cflags --libs gstreamer-video-1.0)
NEUTRINO2_CPPFLAGS     += $(shell $(PKG_CONFIG) --cflags --libs glib-2.0)
NEUTRINO2_CONFIG_OPTS += --enable-gstreamer --with-gstversion=1.0
endif

ifeq ($(PYTHON), python)
NEUTRINO2_CONFIG_OPTS += --enable-python PYTHON_CPPFLAGS="-I$(TARGET_DIR)/usr/include/python2.7" PYTHON_LIBS="-L$(TARGET_DIR)/usr/lib -lpython2.7" PYTHON_SITE_PKG="$(TARGET_DIR)/usr/lib/python2.7/site-packages"
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

ifeq ($(GRAPHLCD), graphlcd)
NEUTRINO2_CONFIG_OPTS += --with-graphlcd
endif

ifeq ($(LCD4LINUX), lcd4linux)
NEUTRINO2_CONFIG_OPTS += --with-lcd4linux
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

$(D)/neutrino2-plugins.config.status: neutrino2
	cd $(SOURCE_DIR)/neutrino2/plugins; \
		./autogen.sh; \
		$(BUILDENV) \
		./configure $(SILENT_OPT) \
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
	$(MAKE) top_srcdir=$(SOURCE_DIR)/neutrino2/neutrino2
	@touch $@

$(D)/neutrino2-plugins: $(D)/neutrino2-plugins.do_compile
	$(MAKE) -C $(SOURCE_DIR)/neutrino2/plugins install DESTDIR=$(TARGET_DIR)
	touch $(D)/$(notdir $@)
	$(TUXBOX_CUSTOMIZE)

neutrino2-plugins-clean:
	rm -f $(D)/neutrino2-plugins.do_compile
	$(MAKE) -C $(SOURCE_DIR)/neutrino2/plugins clean

neutrino2-plugins-distclean:
	rm -f $(D)/neutrino2-plugins*
	$(MAKE) -C $(SOURCE_DIR)/neutrino2/plugins distclean
	rm -f $(SOURCE_DIR)/neutrino2/plugins/config.status
	
#
# release-neutrino2
#
release-neutrino2: release-common release-$(BOXTYPE) $(D)/neutrino2 $(D)/neutrino2-plugins
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
	install -m 0755 $(BASE_DIR)/machine/$(BOXTYPE)/files/rcS_NEUTRINO2 $(RELEASE_DIR)/etc/init.d/rcS
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
# lua
#
ifeq ($(LUA), lua)
	cp -R $(TARGET_DIR)/usr/lib/lua $(RELEASE_DIR)/usr/lib/
	if [ -d $(TARGET_DIR)/usr/share/lua ]; then \
		cp -aR $(TARGET_DIR)/usr/share/lua/* $(RELEASE_DIR)/usr/share/lua; \
	fi
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

