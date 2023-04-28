#
# NEUTRINO
#
N_OBJDIR = $(BUILD_TMP)/neutrino
LH_OBJDIR = $(BUILD_TMP)/libstb-hal

$(TARGET_DIR)/.version:
	echo "distro=$(FLAVOUR)" > $@
	echo "imagename=`sed -n 's/\#define PACKAGE_NAME "//p' $(N_OBJDIR)/config.h | sed 's/"//'`" >> $@
	echo "imageversion=`sed -n 's/\#define PACKAGE_VERSION "//p' $(N_OBJDIR)/config.h | sed 's/"//'`" >> $@
	echo "homepage=https://github.com/Duckbox-Developers" >> $@
	echo "creator=$(MAINTAINER)" >> $@
	echo "docs=https://github.com/Duckbox-Developers" >> $@
	echo "forum=https://github.com/Duckbox-Developers/neutrino-ddt" >> $@
	echo "version=0200`date +%Y%m%d%H%M`" >> $@
	echo "git=`git log | grep "^commit" | wc -l`" >> $@

NEUTRINO_DEPS  = $(D)/bootstrap
NEUTRINO_DEPS += $(D)/e2fsprogs
NEUTRINO_DEPS += $(D)/ncurses  
NEUTRINO_DEPS += $(D)/libcurl
NEUTRINO_DEPS += $(D)/libpng 
NEUTRINO_DEPS += $(D)/libjpeg 
NEUTRINO_DEPS += $(D)/giflib 
NEUTRINO_DEPS += $(D)/freetype
NEUTRINO_DEPS += $(D)/alsa_utils 
NEUTRINO_DEPS += $(D)/ffmpeg
NEUTRINO_DEPS += $(D)/libfribidi 
NEUTRINO_DEPS += $(D)/libsigc 
NEUTRINO_DEPS += $(D)/libdvbsi 
NEUTRINO_DEPS += $(D)/libusb
NEUTRINO_DEPS += $(D)/pugixml 
NEUTRINO_DEPS += $(D)/libopenthreads
NEUTRINO_DEPS += $(D)/libid3tag
NEUTRINO_DEPS += $(D)/libmad
NEUTRINO_DEPS += $(D)/flac
#ifeq ($(LUA), lua)
NEUTRINO_DEPS += $(D)/lua 
NEUTRINO_DEPS += $(D)/luaexpat 
NEUTRINO_DEPS += $(D)/luacurl 
NEUTRINO_DEPS += $(D)/luasocket 
NEUTRINO_DEPS += $(D)/luafeedparser 
NEUTRINO_DEPS += $(D)/luasoap 
NEUTRINO_DEPS += $(D)/luajson
#endif

NEUTRINO_CFLAGS       = -Wall -W -Wshadow -pipe -Os
NEUTRINO_CFLAGS      += -D__KERNEL_STRICT_NAMES
NEUTRINO_CFLAGS      += -D__STDC_FORMAT_MACROS
NEUTRINO_CFLAGS      += -D__STDC_CONSTANT_MACROS
NEUTRINO_CFLAGS      += -fno-strict-aliasing -funsigned-char -ffunction-sections -fdata-sections

NEUTRINO_CPPFLAGS     = -I$(TARGET_DIR)/usr/include
NEUTRINO_CPPFLAGS    += -I$(CROSS_DIR)/$(TARGET)/sys-root/usr/include

ifeq ($(BOXARCH), sh4)
NEUTRINO_CPPFLAGS    += -I$(KERNEL_DIR)/include
NEUTRINO_CPPFLAGS    += -I$(DRIVER_DIR)/include
NEUTRINO_CPPFLAGS    += -I$(DRIVER_DIR)/bpamem
endif

NEUTRINO_CPPFLAGS    += -ffunction-sections -fdata-sections

ifeq ($(BOXTYPE), $(filter $(BOXTYPE), spark spark7162))
NEUTRINO_CPPFLAGS += -I$(DRIVER_DIR)/frontcontroller/aotom_spark
endif

NEUTRINO_CONFIG_OPTS = --enable-freesatepg
NEUTRINO_CONFIG_OPTS += --enable-lua
NEUTRINO_CONFIG_OPTS += --enable-giflib
NEUTRINO_CONFIG_OPTS += --with-tremor
NEUTRINO_CONFIG_OPTS += --enable-ffmpegdec
#NEUTRINO_CONFIG_OPTS += --enable-pip
NEUTRINO_CONFIG_OPTS += --enable-pugixml

ifeq ($(BOXARCH), arm)
NEUTRINO_CONFIG_OPTS += --enable-reschange
endif

ifeq ($(GSTREAMER), gstreamer)
LH_CONFIG_OPTS += --enable-gstreamer_10
NEUTRINO_CPPFLAGS    += $(shell $(PKG_CONFIG) --cflags --libs gstreamer-1.0)
NEUTRINO_CPPFLAGS    += $(shell $(PKG_CONFIG) --cflags --libs gstreamer-audio-1.0)
NEUTRINO_CPPFLAGS    += $(shell $(PKG_CONFIG) --cflags --libs gstreamer-video-1.0)
NEUTRINO_CPPFLAGS    += $(shell $(PKG_CONFIG) --cflags --libs glib-2.0)
endif

ifeq ($(GRAPHLCD), graphlcd)
NEUTRINO_CONFIG_OPTS += --with-graphlcd
endif

ifeq ($(LCD4LINUX), lcd4linux)
NEUTRINO_CONFIG_OPTS += --with-lcd4linux
endif

MACHINE = $(BOXTYPE)
ifeq ($(BOXARCH), arm)
MACHINE = hd51
endif
ifeq ($(BOXARCH), mipsel)
MACHINE = vuduo
endif

NEUTRINO_CONFIG_OPTS += \
	--with-boxtype=$(MACHINE) \
	--with-libdir=/usr/lib \
	--with-datadir=/usr/share/tuxbox \
	--with-fontdir=/usr/share/fonts \
	--with-configdir=/var/tuxbox/config \
	--with-gamesdir=/var/tuxbox/games \
	--with-iconsdir=/usr/share/tuxbox/neutrino/icons \
	--with-iconsdir_var=/var/tuxbox/icons \
	--with-luaplugindir=/var/tuxbox/plugins \
	--with-localedir=/usr/share/tuxbox/neutrino/locale \
	--with-localedir_var=/var/tuxbox/locale \
	--with-plugindir=/var/tuxbox/plugins \
	--with-plugindir_var=/var/tuxbox/plugins \
	--with-private_httpddir=/usr/share/tuxbox/neutrino/httpd \
	--with-public_httpddir=/var/tuxbox/httpd \
	--with-themesdir=/usr/share/tuxbox/neutrino/themes \
	--with-themesdir_var=/var/tuxbox/themes \
	--with-webtvdir=/share/tuxbox/neutrino/webtv \
	--with-webtvdir_var=/var/tuxbox/plugins/webtv \
	--with-controldir=/var/tuxbox/control \
	PKG_CONFIG=$(PKG_CONFIG) \
	PKG_CONFIG_PATH=$(PKG_CONFIG_PATH) \
	CFLAGS="$(NEUTRINO_CFLAGS)" CXXFLAGS="$(NEUTRINO_CFLAGS)" CPPFLAGS="$(NEUTRINO_CPPFLAGS)"

#
# DDT
#
NEUTRINO = neutrino-ddt
N_BRANCH = master
N_URL = https://github.com/Duckbox-Developers/neutrino-ddt.git
LIBSTB-HAL = libstb-hal-ddt
LH_BRANCH = master
HAL_URL = https://github.com/Duckbox-Developers/libstb-hal-ddt.git

#
# libstb-hal
#
LIBSTB_HAL_PATCHES =

$(D)/libstb-hal.do_prepare:
	$(START_BUILD)
	rm -rf $(SOURCE_DIR)/$(LIBSTB-HAL)
	rm -rf $(LH_OBJDIR)
	[ -d "$(ARCHIVE)/$(LIBSTB-HAL).git" ] && \
	(cd $(ARCHIVE)/$(LIBSTB-HAL).git; git pull; cd "$(BUILD_TMP)";); \
	[ -d "$(ARCHIVE)/$(LIBSTB-HAL).git" ] || \
	git clone $(HAL_URL) $(ARCHIVE)/$(LIBSTB-HAL).git; \
	cp -ra $(ARCHIVE)/$(LIBSTB-HAL).git $(SOURCE_DIR)/$(LIBSTB-HAL);\
	set -e; cd $(SOURCE_DIR)/$(LIBSTB-HAL); \
		$(call apply_patches,$(LIBSTB_HAL_PATCHES))
	@touch $@

$(D)/libstb-hal.config.status: | $(NEUTRINO_DEPS)
	rm -rf $(LH_OBJDIR); \
	test -d $(LH_OBJDIR) || mkdir -p $(LH_OBJDIR); \
	cd $(LH_OBJDIR); \
		$(SOURCE_DIR)/$(LIBSTB-HAL)/autogen.sh; \
		$(BUILDENV) \
		$(SOURCE_DIR)/$(LIBSTB-HAL)/configure --enable-silent-rules \
			--host=$(TARGET) \
			--build=$(BUILD) \
			--prefix=/usr \
			--with-target=cdk \
			--with-targetprefix=/usr \
			$(LH_CONFIG_OPTS) \
			--with-boxtype=$(MACHINE) \
			--enable-silent-rules \
			PKG_CONFIG=$(PKG_CONFIG) \
			PKG_CONFIG_PATH=$(PKG_CONFIG_PATH) \
			CFLAGS="$(NEUTRINO_CFLAGS)" CXXFLAGS="$(NEUTRINO_CFLAGS)" CPPFLAGS="$(NEUTRINO_CPPFLAGS)"
	@touch $@

$(D)/libstb-hal.do_compile: $(D)/libstb-hal.config.status
	cd $(SOURCE_DIR)/$(LIBSTB-HAL); \
		$(MAKE) -C $(LH_OBJDIR) all DESTDIR=$(TARGET_DIR)
	@touch $@

$(D)/libstb-hal: $(D)/libstb-hal.do_prepare $(D)/libstb-hal.do_compile
	$(MAKE) -C $(LH_OBJDIR) install DESTDIR=$(TARGET_DIR)
	$(TOUCH)

libstb-hal-clean:
	rm -f $(D)/libstb-hal
	rm -f $(D)/libstb-hal.config.status
	cd $(LH_OBJDIR); \
		$(MAKE) -C $(LH_OBJDIR) distclean

libstb-hal-distclean:
	rm -rf $(LH_OBJDIR)
	rm -f $(D)/libstb-hal*

#
# neutrino
#
NEUTRINO_PATCHES = neutrino-ddt.patch

$(D)/neutrino.do_prepare: | $(NEUTRINO_DEPS) $(D)/libstb-hal
	$(START_BUILD)
	rm -rf $(SOURCE_DIR)/$(NEUTRINO)
	rm -rf $(N_OBJDIR)
	[ -d "$(ARCHIVE)/$(NEUTRINO).git" ] && \
	(cd $(ARCHIVE)/$(NEUTRINO).git; git pull; cd "$(BUILD_TMP)";); \
	[ -d "$(ARCHIVE)/$(NEUTRINO).git" ] || \
	git clone $(N_URL) $(ARCHIVE)/$(NEUTRINO).git; \
	cp -ra $(ARCHIVE)/$(NEUTRINO).git $(SOURCE_DIR)/$(NEUTRINO); \
	set -e; cd $(SOURCE_DIR)/$(NEUTRINO); \
		$(call apply_patches,$(NEUTRINO_PATCHES))
	@touch $@

$(D)/neutrino.config.status:
	rm -rf $(N_OBJDIR)
	test -d $(N_OBJDIR) || mkdir -p $(N_OBJDIR); \
	cd $(N_OBJDIR); \
		$(SOURCE_DIR)/$(NEUTRINO)/autogen.sh; \
		$(BUILDENV) \
		$(SOURCE_DIR)/$(NEUTRINO)/configure --enable-silent-rules \
			--build=$(BUILD) \
			--host=$(TARGET) \
			--prefix=/usr \
			--with-targetprefix=/usr \
			$(NEUTRINO_CONFIG_OPTS) \
			--with-stb-hal-includes=$(SOURCE_DIR)/$(LIBSTB-HAL)/include \
			--with-stb-hal-build=$(LH_OBJDIR)
	@touch $@

$(SOURCE_DIR)/$(NEUTRINO)/src/gui/version.h:
	@rm -f $@; \
	echo '#define BUILT_DATE "'`date`'"' > $@
	@if test -d $(SOURCE_DIR)/$(LIBSTB-HAL) ; then \
		pushd $(SOURCE_DIR)/$(LIBSTB-HAL) ; \
		HAL_REV=$$(git log | grep "^commit" | wc -l) ; \
		popd ; \
		pushd $(SOURCE_DIR)/$(NEUTRINO) ; \
		NMP_REV=$$(git log | grep "^commit" | wc -l) ; \
		popd ; \
		pushd $(BASE_DIR) ; \
		DDT_REV=$$(git log | grep "^commit" | wc -l) ; \
		popd ; \
		echo '#define VCS "DDT-rev'$$DDT_REV'_HAL-rev'$$HAL_REV'_NMP-rev'$$NMP_REV'"' >> $@ ; \
	fi

$(D)/neutrino.do_compile: $(D)/neutrino.config.status $(SOURCE_DIR)/$(NEUTRINO)/src/gui/version.h
	cd $(SOURCE_DIR)/$(NEUTRINO); \
		$(MAKE) -C $(N_OBJDIR) all
	@touch $@

$(D)/neutrino: $(D)/neutrino.do_prepare $(D)/neutrino.do_compile
	$(MAKE) -C $(N_OBJDIR) install DESTDIR=$(TARGET_DIR); \
	rm -f $(TARGET_DIR)/.version
	make $(TARGET_DIR)/.version
	$(TOUCH)

neutrino-clean:
	rm -f $(D)/neutrino.do_compile
	$(MAKE) -C $(N_OBJDIR) clean
	rm -f $(D)/neutrino
	rm -f $(SOURCE_DIR)/$(NEUTRINO)/src/gui/version.h

neutrino-distclean: libstb-hal-distclean
	rm -f $(D)/neutrino*
	$(MAKE) -C $(N_OBJDIR) distclean
	rm -rf $(N_OBJDIR)

#
# neutrino-plugins
#
NEUTRINO_PLUGINS  = $(D)/neutrino-plugins
NEUTRINO_PLUGINS += $(D)/neutrino-plugins-scripts-lua
NEUTRINO_PLUGINS += $(D)/neutrino-plugins-mediathek
#NEUTRINO_PLUGINS += $(D)/neutrino-plugins-xupnpd

NEUTRINO_PLUGINS_PATCHES =

NP_OBJDIR = $(BUILD_TMP)/neutrino-plugins

ifeq ($(BOXARCH), sh4)
EXTRA_CPPFLAGS_MP_PLUGINS = -DMARTII
endif

$(D)/neutrino-plugins.do_prepare:
	$(START_BUILD)
	rm -rf $(SOURCE_DIR)/neutrino-plugins
	set -e; 
	[ -d "$(ARCHIVE)/neutrino-plugins.git" ] && \
	(cd $(ARCHIVE)/neutrino-plugins.git; git pull;); \
	[ -d "$(ARCHIVE)/neutrino-plugins.git" ] || \
	git clone https://github.com/Duckbox-Developers/neutrino-ddt-plugins.git; \
	cp -ra $(ARCHIVE)/neutrino-plugins.git $(SOURCE_DIR)/neutrino-plugins
ifeq ($(BOXARCH), $(filter $(BOXARCH), arm mipsel))
	sed -i -e 's#shellexec fx2#shellexec#g' $(SOURCE_DIR)/neutrino-plugins/Makefile.am
endif
	set -e; cd $(SOURCE_DIR)/neutrino-plugins; \
		$(call apply_patches, $(NEUTRINO_PLUGINS_PATCHES))
	@touch $@

$(D)/neutrino-plugins.config.status: $(D)/bootstrap
	rm -rf $(NP_OBJDIR); \
	test -d $(NP_OBJDIR) || mkdir -p $(NP_OBJDIR); \
	cd $(NP_OBJDIR); \
		$(SOURCE_DIR)/neutrino-plugins/autogen.sh $(SILENT_OPT) && automake --add-missing $(SILENT_OPT); \
		$(BUILDENV) \
		$(SOURCE_DIR)/neutrino-plugins/configure $(SILENT_OPT) \
			--host=$(TARGET) \
			--build=$(BUILD) \
			--prefix= \
			--enable-silent-rules \
			--with-target=cdk \
			--include=/usr/include \
			--enable-maintainer-mode \
			--with-boxtype=$(MACHINE) \
			--with-plugindir=/var/tuxbox/plugins \
			--with-libdir=/usr/lib \
			--with-datadir=/usr/share/tuxbox \
			--with-fontdir=/usr/share/fonts \
			PKG_CONFIG=$(PKG_CONFIG) \
			PKG_CONFIG_PATH=$(PKG_CONFIG_PATH) \
			CPPFLAGS="$(NEUTRINO_CPPFLAGS) $(EXTRA_CPPFLAGS_MP_PLUGINS) -DNEW_LIBCURL" \
			LDFLAGS="$(TARGET_LDFLAGS) -L$(NP_OBJDIR)/fx2/lib/.libs"
	@touch $@

$(D)/neutrino-plugins.do_compile: $(D)/neutrino-plugins.config.status
	$(MAKE) -C $(NP_OBJDIR) DESTDIR=$(TARGET_DIR)
	@touch $@

$(D)/neutrino-plugins: $(D)/neutrino-plugins.do_prepare $(D)/neutrino-plugins.do_compile
	$(MAKE) -C $(NP_OBJDIR) install DESTDIR=$(TARGET_DIR)
	$(TOUCH)

neutrino-plugins-clean:
	rm -f $(D)/neutrino-plugins
	rm -f $(D)/neutrino-plugin
	rm -f $(D)/neutrino-plugin.config.status
	cd $(NP_OBJDIR); \
		$(MAKE) -C $(NP_OBJDIR) clean

neutrino-plugins-distclean:
	rm -rf $(NP_OBJDIR)
	rm -f $(D)/neutrino-plugin*

#
# neutrino-plugins-xupnpd
#
$(D)/neutrino-plugins-xupnpd: $(D)/xupnpd $(D)/lua $(D)/neutrino-plugins-scripts-lua
	install -m 644 $(ARCHIVE)/neutrino-plugin-scripts-lua.git/xupnpd/xupnpd_18plus.lua ${TARGET_DIR}/usr/share/xupnpd/plugins/
	install -m 644 $(ARCHIVE)/neutrino-plugin-scripts-lua.git/xupnpd/xupnpd_cczwei.lua ${TARGET_DIR}/usr/share/xupnpd/plugins/
	: install -m 644 $(ARCHIVE)/neutrino-plugin-scripts-lua.git/xupnpd/xupnpd_coolstream.lua ${TARGET_DIR}/usr/share/xupnpd/plugins/
	install -m 644 $(ARCHIVE)/neutrino-plugin-scripts-lua.git/xupnpd/xupnpd_youtube.lua ${TARGET_DIR}/usr/share/xupnpd/plugins/
	$(TOUCH)

#
# neutrino-plugins-scripts-lua
#
$(D)/neutrino-plugins-scripts-lua: $(D)/bootstrap
	$(START_BUILD)
	$(REMOVE)/neutrino-plugin-scripts-lua
	set -e; 
	[ -d "$(ARCHIVE)/neutrino-plugin-scripts-lua.git" ] && \
	(cd $(ARCHIVE)/neutrino-plugin-scripts-lua.git; git pull;); \
	[ -d "$(ARCHIVE)/neutrino-plugin-scripts-lua.git" ] || \
	git clone https://github.com/Duckbox-Developers/neutrino-plugin-scripts-lua.git; \
	cp -ra $(ARCHIVE)/neutrino-plugin-scripts-lua.git/plugins $(BUILD_TMP)/neutrino-plugin-scripts-lua
	$(CHDIR)/neutrino-plugin-scripts-lua; \
		install -d $(TARGET_DIR)/var/tuxbox/plugins
#		cp -R $(BUILD_TMP)/neutrino-plugin-scripts-lua/favorites2bin/* $(TARGET_DIR)/var/tuxbox/plugins/
		cp -R $(BUILD_TMP)/neutrino-plugin-scripts-lua/ard_mediathek/* $(TARGET_DIR)/var/tuxbox/plugins/
		cp -R $(BUILD_TMP)/neutrino-plugin-scripts-lua/mtv/* $(TARGET_DIR)/var/tuxbox/plugins/
		cp -R $(BUILD_TMP)/neutrino-plugin-scripts-lua/netzkino/* $(TARGET_DIR)/var/tuxbox/plugins/
	$(REMOVE)/neutrino-plugin-scripts-lua
	$(TOUCH)
#
# neutrino-mediathek
#
$(D)/neutrino-plugins-mediathek:
	$(START_BUILD)
	$(REMOVE)/neutrino-plugins-mediathek
	set -e; 
	[ -d "$(ARCHIVE)/neutrino-plugins-mediathek.git" ] && \
	(cd $(ARCHIVE)/neutrino-plugins-mediathek.git; git pull;); \
	[ -d "$(ARCHIVE)/neutrino-plugins-mediathek.git" ] || \
	git clone https://github.com/Duckbox-Developers/neutrino-plugins-mediathek.git; \
	cp -ra $(ARCHIVE)/neutrino-plugins-mediathek.git $(BUILD_TMP)/neutrino-plugins-mediathek
	install -d $(TARGET_DIR)/var/tuxbox/plugins
	$(CHDIR)/neutrino-plugins-mediathek; \
		cp -a plugins/* $(TARGET_DIR)/var/tuxbox/plugins/; \
#		cp -a share $(TARGET_DIR)/usr/
		rm -f $(TARGET_DIR)/var/tuxbox/plugins/neutrino-mediathek/livestream.lua
	$(REMOVE)/neutrino-plugins-mediathek
	$(TOUCH)
	
#
# release-neutrino
#
release-neutrino: release-common release-$(BOXTYPE) $(D)/neutrino $(NEUTRINO_PLUGINS)
	$(START_BUILD)
	install -d $(RELEASE_DIR)/var/tuxbox
	install -d $(RELEASE_DIR)/usr/share/iso-codes
	install -d $(RELEASE_DIR)/usr/share/tuxbox
	install -d $(RELEASE_DIR)/var/tuxbox
	install -d $(RELEASE_DIR)/var/tuxbox/config/{webtv,zapit}
	install -d $(RELEASE_DIR)/var/tuxbox/plugins
	install -d $(RELEASE_DIR)/var/httpd
	cp -af $(TARGET_DIR)/usr/bin/neutrino $(RELEASE_DIR)/usr/bin/
	cp -af $(TARGET_DIR)/usr/bin/backup.sh $(RELEASE_DIR)/usr/bin/
	cp -af $(TARGET_DIR)/usr/bin/install.sh $(RELEASE_DIR)/usr/bin/
	cp -af $(TARGET_DIR)/usr/bin/luaclient $(RELEASE_DIR)/usr/bin/
	cp -af $(TARGET_DIR)/usr/bin/pzapit $(RELEASE_DIR)/usr/bin/
	cp -af $(TARGET_DIR)/usr/bin/rcsim $(RELEASE_DIR)/usr/bin/
	cp -af $(TARGET_DIR)/usr/bin/restore.sh $(RELEASE_DIR)/usr/bin/
	cp -af $(TARGET_DIR)/usr/bin/sectionsdcontrol $(RELEASE_DIR)/usr/bin/
	cp -dp $(TARGET_DIR)/.version $(RELEASE_DIR)/
	cp -aR $(TARGET_DIR)/usr/share/tuxbox/neutrino $(RELEASE_DIR)/usr/share/tuxbox
#	cp -aR $(TARGET_DIR)/usr/share/tuxbox/sokoban $(RELEASE_DIR)/usr/share/tuxbox
	cp -aR $(TARGET_DIR)/usr/share/fonts $(RELEASE_DIR)/usr/share/
	cp -aR $(TARGET_DIR)/var/tuxbox/* $(RELEASE_DIR)/var/tuxbox
	cp -dp $(TARGET_DIR)/.version $(RELEASE_DIR)/
	install -m 0755 $(BASE_DIR)/machine/$(BOXTYPE)/files/rcS_NEUTRINO $(RELEASE_DIR)/etc/init.d/rcS
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
	
