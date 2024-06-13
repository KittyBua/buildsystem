#
# libupnp-ipk
#
libupnp-ipk: $(D)/bootstrap $(ARCHIVE)/$(LIBUPNP_SOURCE)
	$(START_BUILD)
	rm -rf $(PKGPREFIX)
	install -d $(PKGPREFIX)
	install -d $(PKGS_DIR)
	install -d $(PKGS_DIR)/$@
	$(REMOVE)/libupnp-$(LIBUPNP_VER)
	$(UNTAR)/$(LIBUPNP_SOURCE)
	$(CHDIR)/libupnp-$(LIBUPNP_VER); \
		$(CONFIGURE) \
			--prefix=/usr \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(PKGPREFIX)
	rm -r $(PKGPREFIX)/usr/include $(PKGPREFIX)/usr/lib/pkgconfig
	$(REMOVE)/libupnp-$(LIBUPNP_VER)
ifneq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), kerneldebug debug normal))
	find $(PKGPREFIX)/ -name '*' -exec $(TARGET)-strip --strip-unneeded {} &>/dev/null \;
endif
	pushd $(PKGPREFIX) && tar --numeric-owner --group=0 --owner=0 -czf $(PKGS_DIR)/$@/data.tar.gz ./* && popd
	touch $(PACKAGES)/libupnp/control/control
	echo Package: libupnp > $(PACKAGES)/libupnp/control/control
	echo Version: $(LIBUPNP_VER) >> $(PACKAGES)/libupnp/control/control
	echo Section: base/libraries >> $(PACKAGES)/libupnp/control/control
ifeq ($(BOXARCH), mips)
	echo Architecture: $(BOXARCH)el >> $(PACKAGES)/libupnp/control/control 
else
	echo Architecture: $(BOXARCH) >> $(PACKAGES)/libupnp/control/control 
endif
	echo Maintainer: $(MAINTAINER)  >> $(PACKAGES)/libupnp/control/control 
	echo Depends:  >> $(PACKAGES)/libupnp/control/control
	pushd $(PACKAGES)/libupnp/control && chmod +x * && tar --numeric-owner --group=0 --owner=0 -czf $(PKGS_DIR)/$@/control.tar.gz ./* && popd
	pushd $(PKGS_DIR)/$@ && echo 2.0 > debian-binary && ar rv $(PKGS_DIR)/libupnp-$(LIBUPNP_VER)_$(BOXARCH)_all.ipk ./data.tar.gz ./control.tar.gz ./debian-binary && popd && rm -rf data.tar.gz control.tar.gz debian-binary
	rm -rf $(PACKAGES)/libupnp/control/control
	rm -rf $(PKGPREFIX)
	rm -rf $(PKGS_DIR)/$@
	$(END_BUILD)

#
# minidlna-ipk
#	
minidlna-ipk: $(D)/bootstrap $(D)/zlib $(D)/sqlite $(D)/libexif $(D)/libjpeg $(D)/libid3tag $(D)/libogg $(D)/libvorbis $(D)/flac $(D)/ffmpeg $(ARCHIVE)/$(MINIDLNA_SOURCE)
	$(START_BUILD)
	rm -rf $(PKGPREFIX)
	install -d $(PKGPREFIX)
	install -d $(PKGS_DIR)
	install -d $(PKGS_DIR)/$@
	$(REMOVE)/minidlna-$(MINIDLNA_VER)
	$(UNTAR)/$(MINIDLNA_SOURCE)
	$(CHDIR)/minidlna-$(MINIDLNA_VER); \
		$(call apply_patches, $(MINIDLNA_PATCH)); \
		autoreconf -fi; \
		$(CONFIGURE) \
			--prefix=/usr \
		; \
		$(MAKE); \
		$(MAKE) install prefix=/usr DESTDIR=$(PKGPREFIX)
	$(REMOVE)/minidlna-$(MINIDLNA_VER)
ifneq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), kerneldebug debug normal))
	find $(PKGPREFIX)/ -name '*' -exec $(TARGET)-strip --strip-unneeded {} &>/dev/null \;
endif
	pushd $(PKGPREFIX) && tar --numeric-owner --group=0 --owner=0 -czf $(PKGS_DIR)/$@/data.tar.gz ./* && popd
	touch $(PACKAGES)/minidlna/control/control
	echo Package: minidlna > $(PACKAGES)/minidlna/control/control
	echo Version: $(MINIDLNA_VER) >> $(PACKAGES)/minidlna/control/control
	echo Section: base/libraries >> $(PACKAGES)/minidlna/control/control
ifeq ($(BOXARCH), mips)
	echo Architecture: $(BOXARCH)el >> $(PACKAGES)/minidlna/control/control 
else
	echo Architecture: $(BOXARCH) >> $(PACKAGES)/minidlna/control/control 
endif
	echo Maintainer: $(MAINTAINER)  >> $(PACKAGES)/minidlna/control/control 
	echo Depends:  >> $(PACKAGES)/minidlna/control/control
	pushd $(PACKAGES)/minidlna/control && chmod +x * && tar --numeric-owner --group=0 --owner=0 -czf $(PKGS_DIR)/$@/control.tar.gz ./* && popd
	pushd $(PKGS_DIR)/$@ && echo 2.0 > debian-binary && ar rv $(PKGS_DIR)/minidlna-$(MINIDLNA_VER)_$(BOXARCH)_all.ipk ./data.tar.gz ./control.tar.gz ./debian-binary && popd && rm -rf data.tar.gz control.tar.gz debian-binary
	rm -rf $(PACKAGES)/minidlna/control/control
	rm -rf $(PKGPREFIX)
	rm -rf $(PKGS_DIR)/$@
	$(END_BUILD)

#
# fbshot-ipk
#
fbshot-ipk: $(D)/bootstrap $(D)/libpng $(ARCHIVE)/$(FBSHOT_SOURCE)
	$(START_BUILD)
	rm -rf $(PKGPREFIX)
	install -d $(PKGPREFIX)
	install -d $(PKGS_DIR)
	install -d $(PKGS_DIR)/$@
	$(REMOVE)/fbshot-$(FBSHOT_VER)
	$(UNTAR)/$(FBSHOT_SOURCE)
	$(CHDIR)/fbshot-$(FBSHOT_VER); \
		$(call apply_patches, $(FBSHOT_PATCH)); \
		sed -i s~'gcc'~"$(TARGET)-gcc $(TARGET_CFLAGS) $(TARGET_LDFLAGS)"~ Makefile; \
		sed -i 's/strip fbshot/$(TARGET)-strip fbshot/' Makefile; \
		$(MAKE) all; \
		install -D -m 755 fbshot $(PKGPREFIX)/bin/fbshot
	$(REMOVE)/fbshot-$(FBSHOT_VER)
ifneq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), kerneldebug debug normal))
	find $(PKGPREFIX)/ -name '*' -exec $(TARGET)-strip --strip-unneeded {} &>/dev/null \;
endif
	pushd $(PKGPREFIX) && tar --numeric-owner --group=0 --owner=0 -czf $(PKGS_DIR)/$@/data.tar.gz ./* && popd
	touch $(PACKAGES)/fbshot/control/control
	echo Package: fbshot > $(PACKAGES)/fbshot/control/control
	echo Version: $(FBSHOT_VER) >> $(PACKAGES)/fbshot/control/control
	echo Section: base/libraries >> $(PACKAGES)/fbshot/control/control
ifeq ($(BOXARCH), mips)
	echo Architecture: $(BOXARCH)el >> $(PACKAGES)/fbshot/control/control 
else
	echo Architecture: $(BOXARCH) >> $(PACKAGES)/fbshot/control/control 
endif
	echo Maintainer: $(MAINTAINER)  >> $(PACKAGES)/fbshot/control/control 
	echo Depends:  >> $(PACKAGES)/fbshot/control/control
	pushd $(PACKAGES)/fbshot/control && chmod +x * && tar --numeric-owner --group=0 --owner=0 -czf $(PKGS_DIR)/$@/control.tar.gz ./* && popd
	pushd $(PKGS_DIR)/$@ && echo 2.0 > debian-binary && ar rv $(PKGS_DIR)/fbshot-$(FBSHOT_VER)_$(BOXARCH)_all.ipk ./data.tar.gz ./control.tar.gz ./debian-binary && popd && rm -rf data.tar.gz control.tar.gz debian-binary
	rm -rf $(PKGPREFIX)
	rm -rf $(PACKAGES)/fbshot/control/control
	rm -rf $(PKGS_DIR)/$@
	$(END_BUILD)

#
# samba-ipk
#	
samba-ipk: $(D)/bootstrap $(ARCHIVE)/$(SAMBA_SOURCE)
	$(START_BUILD)
	rm -rf $(PKGPREFIX)
	install -d $(PKGPREFIX)
	install -d $(PKGPREFIX)/etc/init.d
	install -d $(PKGS_DIR)
	install -d $(PKGS_DIR)/$@
	$(REMOVE)/samba-$(SAMBA_VER)
	$(UNTAR)/$(SAMBA_SOURCE)
	$(CHDIR)/samba-$(SAMBA_VER); \
		$(call apply_patches, $(SAMBA_PATCH)); \
		cd source3; \
		./autogen.sh; \
		$(BUILDENV) \
		ac_cv_lib_attr_getxattr=no \
		ac_cv_search_getxattr=no \
		ac_cv_file__proc_sys_kernel_core_pattern=yes \
		libreplace_cv_HAVE_C99_VSNPRINTF=yes \
		libreplace_cv_HAVE_GETADDRINFO=yes \
		libreplace_cv_HAVE_IFACE_IFCONF=yes \
		LINUX_LFS_SUPPORT=no \
		samba_cv_CC_NEGATIVE_ENUM_VALUES=yes \
		samba_cv_HAVE_GETTIMEOFDAY_TZ=yes \
		samba_cv_HAVE_IFACE_IFCONF=yes \
		samba_cv_HAVE_KERNEL_OPLOCKS_LINUX=yes \
		samba_cv_HAVE_SECURE_MKSTEMP=yes \
		samba_cv_HAVE_WRFILE_KEYTAB=no \
		samba_cv_USE_SETREUID=yes \
		samba_cv_USE_SETRESUID=yes \
		samba_cv_have_setreuid=yes \
		samba_cv_have_setresuid=yes \
		ac_cv_header_zlib_h=no \
		samba_cv_zlib_1_2_3=no \
		ac_cv_path_PYTHON="" \
		ac_cv_path_PYTHON_CONFIG="" \
		libreplace_cv_HAVE_GETADDRINFO=no \
		libreplace_cv_READDIR_NEEDED=no \
		./configure \
			--build=$(BUILD) \
			--host=$(TARGET) \
			--prefix= \
			--includedir=/usr/include \
			--exec-prefix=/usr \
			--disable-pie \
			--disable-avahi \
			--disable-cups \
			--disable-relro \
			--disable-swat \
			--disable-shared-libs \
			--disable-socket-wrapper \
			--disable-nss-wrapper \
			--disable-smbtorture4 \
			--disable-fam \
			--disable-iprint \
			--disable-dnssd \
			--disable-pthreadpool \
			--disable-dmalloc \
			--with-included-iniparser \
			--with-included-popt \
			--with-sendfile-support \
			--without-aio-support \
			--without-cluster-support \
			--without-ads \
			--without-krb5 \
			--without-dnsupdate \
			--without-automount \
			--without-ldap \
			--without-pam \
			--without-pam_smbpass \
			--without-winbind \
			--without-wbclient \
			--without-syslog \
			--without-nisplus-home \
			--without-quotas \
			--without-sys-quotas \
			--without-utmp \
			--without-acl-support \
			--with-configdir=/etc/samba \
			--with-privatedir=/etc/samba \
			--with-mandir=no \
			--with-piddir=/var/run \
			--with-logfilebase=/var/log \
			--with-lockdir=/var/lock \
			--with-swatdir=/usr/share/swat \
			--disable-cups \
			--without-winbind \
			--without-libtdb \
			--without-libtalloc \
			--without-libnetapi \
			--without-libsmbclient \
			--without-libsmbsharemodes \
			--without-libtevent \
			--without-libaddns \
		; \
		$(MAKE) $(MAKE_OPTS); \
		$(MAKE) $(MAKE_OPTS) installservers installbin installscripts installdat installmodules \
			SBIN_PROGS="bin/samba_multicall" DESTDIR=$(PKGPREFIX) prefix=./. ; \
			ln -s samba_multicall $(PKGPREFIX)/usr/sbin/nmbd
			ln -s samba_multicall $(PKGPREFIX)/usr/sbin/smbd
			ln -s samba_multicall $(PKGPREFIX)/usr/sbin/smbpasswd
	install -m 755 $(SKEL_ROOT)/etc/init.d/samba $(PKGPREFIX)/etc/init.d/
	install -m 644 $(SKEL_ROOT)/etc/samba/smb.conf $(PKGPREFIX)/etc/samba/
	$(REMOVE)/samba-$(SAMBA_VER)
ifneq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), kerneldebug debug normal))
	find $(PKGPREFIX)/ -name '*' -exec $(TARGET)-strip --strip-unneeded {} &>/dev/null \;
endif
	pushd $(PKGPREFIX) && tar --numeric-owner --group=0 --owner=0 -czf $(PKGS_DIR)/$@/data.tar.gz ./* && popd
	touch $(PACKAGES)/samba/control/control
	echo Package: samba > $(PACKAGES)/samba/control/control
	echo Version: $(SAMBA_VER) >> $(PACKAGES)/samba/control/control
	echo Section: base/libraries >> $(PACKAGES)/samba/control/control
ifeq ($(BOXARCH), mips)
	echo Architecture: $(BOXARCH)el >> $(PACKAGES)/samba/control/control 
else
	echo Architecture: $(BOXARCH) >> $(PACKAGES)/samba/control/control 
endif
	echo Maintainer: $(MAINTAINER)  >> $(PACKAGES)/samba/control/control 
	echo Depends:  >> $(PACKAGES)/samba/control/control
	pushd $(PACKAGES)/samba/control && chmod +x * && tar --numeric-owner --group=0 --owner=0 -czf $(PKGS_DIR)/$@/control.tar.gz ./* && popd
	pushd $(PKGS_DIR)/$@ && echo 2.0 > debian-binary && ar rv $(PKGS_DIR)/samba-$(SAMBA_VER)_$(BOXARCH)_all.ipk ./data.tar.gz ./control.tar.gz ./debian-binary && popd && rm -rf data.tar.gz control.tar.gz debian-binary
	rm -rf $(PACKAGES)/samba/control/control
	rm -rf $(PKGPREFIX)
	rm -rf $(PKGS_DIR)/$@
	$(END_BUILD)
	
#
# ofgwrite-ipk
#
ofgwrite-ipk: $(D)/bootstrap $(ARCHIVE)/$(OFGWRITE_SOURCE)
	$(START_BUILD)
	rm -rf $(PKGPREFIX)
	install -d $(PKGPREFIX)
	install -d $(PKGPREFIX)/usr/bin
	install -d $(PKGS_DIR)
	install -d $(PKGS_DIR)/$@
	$(REMOVE)/ofgwrite-ddt
	set -e; if [ -d $(ARCHIVE)/ofgwrite-ddt.git ]; \
		then cd $(ARCHIVE)/ofgwrite-ddt.git; git pull; \
		else cd $(ARCHIVE); git clone https://github.com/Duckbox-Developers/ofgwrite-ddt.git ofgwrite-ddt.git; \
		fi
	cp -ra $(ARCHIVE)/ofgwrite-ddt.git $(BUILD_TMP)/ofgwrite-ddt
	$(CHDIR)/ofgwrite-ddt; \
		$(call apply_patches,$(OFGWRITE_PATCH)); \
		$(BUILDENV) \
		$(MAKE); \
	install -m 755 $(BUILD_TMP)/ofgwrite-ddt/ofgwrite_bin $(PKGPREFIX)/usr/bin
	install -m 755 $(BUILD_TMP)/ofgwrite-ddt/ofgwrite_caller $(PKGPREFIX)/usr/bin
	install -m 755 $(BUILD_TMP)/ofgwrite-ddt/ofgwrite $(PKGPREFIX)/usr/bin
	$(REMOVE)/ofgwrite-ddt
ifneq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), kerneldebug debug normal))
	find $(PKGPREFIX)/ -name '*' -exec $(TARGET)-strip --strip-unneeded {} &>/dev/null \;
endif
	pushd $(PKGPREFIX) && tar --numeric-owner --group=0 --owner=0 -czf $(PKGS_DIR)/$@/data.tar.gz ./* && popd
	touch $(PACKAGES)/ofgwrite/control/control
	echo Package: ofgwrite > $(PACKAGES)/ofgwrite/control/control
	echo Version: $(OFGWRITE_VER) >> $(PACKAGES)/ofgwrite/control/control
	echo Section: base/libraries >> $(PACKAGES)/ofgwrite/control/control
ifeq ($(BOXARCH), mips)
	echo Architecture: $(BOXARCH)el >> $(PACKAGES)/ofgwrite/control/control 
else
	echo Architecture: $(BOXARCH) >> $(PACKAGES)/ofgwrite/control/control 
endif
	echo Maintainer: $(MAINTAINER)  >> $(PACKAGES)/ofgwrite/control/control 
	echo Depends:  >> $(PACKAGES)/ofgwrite/control/control
	pushd $(PACKAGES)/ofgwrite/control && chmod +x * && tar --numeric-owner --group=0 --owner=0 -czf $(PKGS_DIR)/$@/control.tar.gz ./* && popd
	pushd $(PKGS_DIR)/$@ && echo 2.0 > debian-binary && ar rv $(PKGS_DIR)/ofgwrite-$(OFGWRITE_VER)_$(BOXARCH)_all.ipk ./data.tar.gz ./control.tar.gz ./debian-binary && popd && rm -rf data.tar.gz control.tar.gz debian-binary
	rm -rf $(PACKAGES)/ofgwrite/control/control
	rm -rf $(PKGPREFIX)
	rm -rf $(PKGS_DIR)/$@
	$(END_BUILD)

#
# xupnpd-ipk
#	
xupnpd-ipk: $(D)/bootstrap $(D)/openssl
	$(START_BUILD)
	rm -rf $(PKGPREFIX)
	install -d $(PKGPREFIX)
	install -d $(PKGPREFIX)/etc/init.d
	install -d $(PKGS_DIR)
	install -d $(PKGS_DIR)/$@
	$(REMOVE)/xupnpd
	set -e; if [ -d $(ARCHIVE)/xupnpd.git ]; \
		then cd $(ARCHIVE)/xupnpd.git; git pull; \
		else cd $(ARCHIVE); git clone https://github.com/clark15b/xupnpd.git xupnpd.git; \
		fi
	cp -ra $(ARCHIVE)/xupnpd.git $(BUILD_TMP)/xupnpd
	($(CHDIR)/xupnpd; git checkout -q $(XUPNPD_BRANCH);)
	$(CHDIR)/xupnpd; \
		$(call apply_patches, $(XUPNPD_PATCH))
	$(CHDIR)/xupnpd/src; \
		$(BUILDENV) \
		$(MAKE) embedded TARGET=$(TARGET) PKG_CONFIG=$(PKG_CONFIG) LUAFLAGS="$(TARGET_LDFLAGS) -I$(TARGET_INCLUDE_DIR)"; \
		$(MAKE) install DESTDIR=$(PKGPREFIX)
	install -m 755 $(SKEL_ROOT)/etc/init.d/xupnpd $(PKGPREFIX)/etc/init.d/
	mkdir -p $(PKGPREFIX)/usr/share/xupnpd/config
	$(REMOVE)/xupnpd
ifneq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), kerneldebug debug normal))
	find $(PKGPREFIX)/ -name '*' -exec $(TARGET)-strip --strip-unneeded {} &>/dev/null \;
endif
	pushd $(PKGPREFIX) && tar --numeric-owner --group=0 --owner=0 -czf $(PKGS_DIR)/$@/data.tar.gz ./* && popd
	touch $(PACKAGES)/xupnpd/control/control
	echo Package: xupnpd > $(PACKAGES)/xupnpd/control/control
	echo Version: $(XUPNPD_VER) >> $(PACKAGES)/xupnpd/control/control
	echo Section: base/application >> $(PACKAGES)/xupnpd/control/control
ifeq ($(BOXARCH), mips)
	echo Architecture: $(BOXARCH)el >> $(PACKAGES)/xupnpd/control/control 
else
	echo Architecture: $(BOXARCH) >> $(PACKAGES)/xupnpd/control/control 
endif
	echo Maintainer: $(MAINTAINER)  >> $(PACKAGES)/xupnpd/control/control 
	echo Depends:  >> $(PACKAGES)/xupnpd/control/control
	pushd $(PACKAGES)/xupnpd/control && chmod +x * && tar --numeric-owner --group=0 --owner=0 -czf $(PKGS_DIR)/$@/control.tar.gz ./* && popd
	pushd $(PKGS_DIR)/$@ && echo 2.0 > debian-binary && ar rv $(PKGS_DIR)/xupnpd-$(XUPNPD_VER)_$(BOXARCH)_all.ipk ./data.tar.gz ./control.tar.gz ./debian-binary && popd && rm -rf data.tar.gz control.tar.gz debian-binary
	rm -rf $(PACKAGES)/xupnpd/control/control
	rm -rf $(PKGPREFIX)
	rm -rf $(PKGS_DIR)/$@
	$(END_BUILD)

#
# graphlcd-ipk
#
graphlcd-ipk: $(D)/bootstrap $(D)/freetype $(D)/libusb $(ARCHIVE)/$(GRAPHLCD_SOURCE)
	$(START_BUILD)
	rm -rf $(PKGPREFIX)
	install -d $(PKGPREFIX)
	install -d $(PKGPREFIX)/etc
	install -d $(PKGS_DIR)
	install -d $(PKGS_DIR)/$@
	$(REMOVE)/graphlcd-git-$(GRAPHLCD_VER)
	$(UNTAR)/$(GRAPHLCD_SOURCE)
	$(CHDIR)/graphlcd-git-$(GRAPHLCD_VER); \
		$(call apply_patches, $(GRAPHLCD_PATCH)); \
		$(MAKE) -C glcdgraphics all TARGET=$(TARGET)- DESTDIR=$(PKGPREFIX); \
		$(MAKE) -C glcddrivers all TARGET=$(TARGET)- DESTDIR=$(PKGPREFIX); \
		$(MAKE) -C glcdgraphics install DESTDIR=$(PKGPREFIX); \
		$(MAKE) -C glcddrivers install DESTDIR=$(PKGPREFIX); \
		cp -a graphlcd.conf $(PKGPREFIX)/etc
		rm -r $(PKGPREFIX)/usr/include
	$(REMOVE)/graphlcd-git-$(GRAPHLCD_VER)
ifneq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), kerneldebug debug normal))
	find $(PKGPREFIX)/ -name '*' -exec $(TARGET)-strip --strip-unneeded {} &>/dev/null \;
endif
	pushd $(PKGPREFIX) && tar --numeric-owner --group=0 --owner=0 -czf $(PKGS_DIR)/$@/data.tar.gz ./* && popd
	touch $(PACKAGES)/graphlcd/control/control
	echo Package: graphlcd > $(PACKAGES)/graphlcd/control/control
	echo Version: $(GRAPHLCD_VER) >> $(PACKAGES)/graphlcd/control/control
	echo Section: base/libraries >> $(PACKAGES)/graphlcd/control/control
ifeq ($(BOXARCH), mips)
	echo Architecture: $(BOXARCH)el >> $(PACKAGES)/graphlcd/control/control 
else
	echo Architecture: $(BOXARCH) >> $(PACKAGES)/graphlcd/control/control 
endif
	echo Maintainer: $(MAINTAINER)  >> $(PACKAGES)/graphlcd/control/control 
	echo Depends:  >> $(PACKAGES)/graphlcd/control/control
	pushd $(PACKAGES)/graphlcd/control && chmod +x * && tar --numeric-owner --group=0 --owner=0 -czf $(PKGS_DIR)/$@/control.tar.gz ./* && popd
	pushd $(PKGS_DIR)/$@ && echo 2.0 > debian-binary && ar rv $(PKGS_DIR)/graphlcd-$(GRAPHLCD_VER)_$(BOXARCH)_all.ipk ./data.tar.gz ./control.tar.gz ./debian-binary && popd && rm -rf data.tar.gz control.tar.gz debian-binary
	rm -rf $(PACKAGES)/graphlcd/control/control
	rm -rf $(PKGPREFIX)
	rm -rf $(PKGS_DIR)/$@
	$(END_BUILD)
	
#
# lcd4linux-ipk
#
lcd4linux-ipk: $(D)/bootstrap $(D)/libusb_compat $(D)/gd $(D)/libusb $(D)/libdpf $(ARCHIVE)/$(LCD4LINUX_SOURCE)
	$(START_BUILD)
	rm -rf $(PKGPREFIX)
	install -d $(PKGPREFIX)
	install -d $(PKGPREFIX)/etc/init.d
	install -d $(PKGS_DIR)
	install -d $(PKGS_DIR)/$@
	$(REMOVE)/lcd4linux-git-$(LCD4LINUX_VER)
	$(UNTAR)/$(LCD4LINUX_SOURCE)
	$(CHDIR)/lcd4linux-git-$(LCD4LINUX_VER); \
		$(call apply_patches, $(LCD4LINUX_PATCH)); \
		$(BUILDENV) ./bootstrap; \
		$(BUILDENV) ./configure $(CONFIGURE_OPTS) \
			--prefix=/usr \
			--with-drivers='DPF,SamsungSPF$(LCD4LINUX_DRV),PNG' \
			--with-plugins='all,!apm,!asterisk,!dbus,!dvb,!gps,!hddtemp,!huawei,!imon,!isdn,!kvv,!mpd,!mpris_dbus,!mysql,!pop3,!ppp,!python,!qnaplog,!raspi,!sample,!seti,!w1retap,!wireless,!xmms' \
			--without-ncurses \
		; \
		$(MAKE) vcs_version all; \
		$(MAKE) install DESTDIR=$(PKGPREFIX)
	install -m 755 $(SKEL_ROOT)/etc/init.d/lcd4linux $(PKGPREFIX)/etc/init.d/
	install -D -m 0600 $(SKEL_ROOT)/etc/lcd4linux.conf $(PKGPREFIX)/etc/lcd4linux.conf
	$(REMOVE)/lcd4linux-git-$(LCD4LINUX_VER)
ifneq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), kerneldebug debug normal))
	find $(PKGPREFIX)/ -name '*' -exec $(TARGET)-strip --strip-unneeded {} &>/dev/null \;
endif
	pushd $(PKGPREFIX) && tar --numeric-owner --group=0 --owner=0 -czf $(PKGS_DIR)/$@/data.tar.gz ./* && popd
	touch $(PACKAGES)/lcd4linux/control/control
	echo Package: lcd4linux > $(PACKAGES)/lcd4linux/control/control
	echo Version: $(LCD4LINUX_VER) >> $(PACKAGES)/lcd4linux/control/control
	echo Section: base/libraries >> $(PACKAGES)/lcd4linux/control/control
ifeq ($(BOXARCH), mips)
	echo Architecture: $(BOXARCH)el >> $(PACKAGES)/lcd4linux/control/control 
else
	echo Architecture: $(BOXARCH) >> $(PACKAGES)/lcd4linux/control/control 
endif
	echo Maintainer: $(MAINTAINER)  >> $(PACKAGES)/lcd4linux/control/control 
	echo Depends:  >> $(PACKAGES)/lcd4linux/control/control
	pushd $(PACKAGES)/lcd4linux/control && chmod +x * && tar --numeric-owner --group=0 --owner=0 -czf $(PKGS_DIR)/$@/control.tar.gz ./* && popd
	pushd $(PKGS_DIR)/$@ && echo 2.0 > debian-binary && ar rv $(PKGS_DIR)/lcd4linux-$(LCD4LINUX_VER)_$(BOXARCH)_$(BOXTYPE).ipk ./data.tar.gz ./control.tar.gz ./debian-binary && popd && rm -rf data.tar.gz control.tar.gz debian-binary
	rm -rf $(PACKAGES)/lcd4linux/control/control
	rm -rf $(PKGPREFIX)
	rm -rf $(PKGS_DIR)/$@
	$(END_BUILD)

#
# gstreamer-ipk
#
gstreamer-ipk: $(D)/bootstrap $(D)/libglib2 $(D)/libxml2 $(D)/glib_networking $(ARCHIVE)/$(GSTREAMER_SOURCE)
	$(START_BUILD)
	rm -rf $(PKGPREFIX)
	install -d $(PKGPREFIX)
	install -d $(PKGS_DIR)
	install -d $(PKGS_DIR)/$@
	$(REMOVE)/gstreamer-$(GSTREAMER_VER)
	$(UNTAR)/$(GSTREAMER_SOURCE)
	$(CHDIR)/gstreamer-$(GSTREAMER_VER); \
		$(call apply_patches, $(GSTREAMER_PATCH)); \
		./autogen.sh --noconfigure; \
		$(CONFIGURE) \
			--prefix=/usr \
			--libexecdir=/usr/lib \
			--datarootdir=/.remove \
			--enable-silent-rules \
			$(GST_PLUGIN_CONFIG_DEBUG) \
			--disable-tests \
			--disable-valgrind \
			--disable-gst-tracer-hooks \
			--disable-dependency-tracking \
			--disable-examples \
			--disable-check \
			$(GST_MAIN_CONFIG_DEBUG) \
			--disable-benchmarks \
			--disable-gtk-doc-html \
			ac_cv_header_valgrind_valgrind_h=no \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(PKGPREFIX)
	rm -r $(PKGPREFIX)/usr/include $(PKGPREFIX)/usr/lib/pkgconfig
	$(REMOVE)/gstreamer-$(GSTREAMER_VER)
ifneq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), kerneldebug debug normal))
	find $(PKGPREFIX)/ -name '*' -exec $(TARGET)-strip --strip-unneeded {} &>/dev/null \;
endif
	pushd $(PKGPREFIX) && tar --numeric-owner --group=0 --owner=0 -czf $(PKGS_DIR)/$@/data.tar.gz ./* && popd
	touch $(PACKAGES)/gstreamer/control/control
	echo Package: gstreamer > $(PACKAGES)/gstreamer/control/control
	echo Version: $(GSTREAMER_VER) >> $(PACKAGES)/gstreamer/control/control
	echo Section: base/libraries >> $(PACKAGES)/gstreamer/control/control
ifeq ($(BOXARCH), mips)
	echo Architecture: $(BOXARCH)el >> $(PACKAGES)/gstreamer/control/control 
else
	echo Architecture: $(BOXARCH) >> $(PACKAGES)/gstreamer/control/control 
endif
	echo Maintainer: $(MAINTAINER)  >> $(PACKAGES)/gstreamer/control/control 
	echo Depends:  >> $(PACKAGES)/gstreamer/control/control
	pushd $(PACKAGES)/gstreamer/control && chmod +x * && tar --numeric-owner --group=0 --owner=0 -czf $(PKGS_DIR)/$@/control.tar.gz ./* && popd
	pushd $(PKGS_DIR)/$@ && echo 2.0 > debian-binary && ar rv $(PKGS_DIR)/gstreamer-$(GSTREAMER_VER)_$(BOXARCH)_all.ipk ./data.tar.gz ./control.tar.gz ./debian-binary && popd && rm -rf data.tar.gz control.tar.gz debian-binary
	rm -rf $(PACKAGES)/gstreamer/control/control
	rm -rf $(PKGPREFIX)
	rm -rf $(PKGS_DIR)/$@
	$(END_BUILD)
	
#
# gst_plugins_base-ipk
#
gst_plugins_base-ipk: $(D)/bootstrap $(D)/zlib $(D)/libglib2 $(D)/orc $(D)/gstreamer $(D)/alsa_lib $(D)/libogg $(D)/libvorbis $(ARCHIVE)/$(GST_PLUGINS_BASE_SOURCE)
	$(START_BUILD)
	rm -rf $(PKGPREFIX)
	install -d $(PKGPREFIX)
	install -d $(PKGS_DIR)
	install -d $(PKGS_DIR)/$@
	$(REMOVE)/gst-plugins-base-$(GST_PLUGINS_BASE_VER)
	$(UNTAR)/$(GST_PLUGINS_BASE_SOURCE)
	$(CHDIR)/gst-plugins-base-$(GST_PLUGINS_BASE_VER); \
		$(call apply_patches, $(GST_PLUGINS_BASE_PATCH)); \
		./autogen.sh --noconfigure; \
		$(CONFIGURE) \
			--prefix=/usr \
			--datarootdir=/.remove \
			--enable-silent-rules \
			--disable-valgrind \
			$(GST_PLUGIN_CONFIG_DEBUG) \
			--disable-examples \
			--disable-gtk-doc-html \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(PKGPREFIX)
	rm -r $(PKGPREFIX)/usr/include $(PKGPREFIX)/usr/lib/pkgconfig
	$(REMOVE)/gst-plugins-base-$(GST_PLUGINS_BASE_VER)
ifneq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), kerneldebug debug normal))
	find $(PKGPREFIX)/ -name '*' -exec $(TARGET)-strip --strip-unneeded {} &>/dev/null \;
endif
	pushd $(PKGPREFIX) && tar --numeric-owner --group=0 --owner=0 -czf $(PKGS_DIR)/$@/data.tar.gz ./* && popd
	touch $(PACKAGES)/gst_plugins_base/control/control
	echo Package: gst_plugins_base > $(PACKAGES)/gst_plugins_base/control/control
	echo Version: $(GST_PLUGINS_BASE_VER) >> $(PACKAGES)/gst_plugins_base/control/control
	echo Section: base/libraries >> $(PACKAGES)/gst_plugins_base/control/control
ifeq ($(BOXARCH), mips)
	echo Architecture: $(BOXARCH)el >> $(PACKAGES)/gst_plugins_base/control/control 
else
	echo Architecture: $(BOXARCH) >> $(PACKAGES)/gst_plugins_base/control/control 
endif
	echo Maintainer: $(MAINTAINER)  >> $(PACKAGES)/gst_plugins_base/control/control 
	echo Depends:  >> $(PACKAGES)/gst_plugins_base/control/control
	pushd $(PACKAGES)/gst_plugins_base/control && chmod +x * && tar --numeric-owner --group=0 --owner=0 -czf $(PKGS_DIR)/$@/control.tar.gz ./* && popd
	pushd $(PKGS_DIR)/$@ && echo 2.0 > debian-binary && ar rv $(PKGS_DIR)/gst_plugins_base-$(GST_PLUGINS_BASE_VER)_$(BOXARCH)_all.ipk ./data.tar.gz ./control.tar.gz ./debian-binary && popd && rm -rf data.tar.gz control.tar.gz debian-binary
	rm -rf $(PACKAGES)/gst_plugins_base/control/control
	rm -rf $(PKGPREFIX)
	rm -rf $(PKGS_DIR)/$@
	$(END_BUILD)

#
# gst_plugins_good-ipk
#
gst_plugins_good-ipk: $(D)/bootstrap $(D)/libpng $(D)/libjpeg $(D)/gstreamer $(D)/gst_plugins_base $(D)/flac $(ARCHIVE)/$(GST_PLUGINS_GOOD_SOURCE)
	$(START_BUILD)
	rm -rf $(PKGPREFIX)
	install -d $(PKGPREFIX)
	install -d $(PKGS_DIR)
	install -d $(PKGS_DIR)/$@
	$(REMOVE)/gst-plugins-good-$(GST_PLUGINS_GOOD_VER)
	$(UNTAR)/$(GST_PLUGINS_GOOD_SOURCE)
	$(CHDIR)/gst-plugins-good-$(GST_PLUGINS_GOOD_VER); \
		$(call apply_patches, $(GST_PLUGINS_GOOD_PATCH)); \
		./autogen.sh --noconfigure; \
		$(CONFIGURE) \
			--build=$(BUILD) \
			--host=$(TARGET) \
			--prefix=/usr \
			--datarootdir=/.remove \
			--enable-silent-rules \
			--disable-valgrind \
			--disable-aalib \
			--disable-aalibtest \
			--disable-cairo \
			--disable-orc \
			--disable-soup \
			$(GST_PLUGIN_CONFIG_DEBUG) \
			--disable-examples \
			--disable-gtk-doc-html \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(PKGPREFIX)
	$(REMOVE)/gst-plugins-good-$(GST_PLUGINS_GOOD_VER)
ifneq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), kerneldebug debug normal))
	find $(PKGPREFIX)/ -name '*' -exec $(TARGET)-strip --strip-unneeded {} &>/dev/null \;
endif
	pushd $(PKGPREFIX) && tar --numeric-owner --group=0 --owner=0 -czf $(PKGS_DIR)/$@/data.tar.gz ./* && popd
	touch $(PACKAGES)/gst_plugins_good/control/control
	echo Package: gst_plugins_good > $(PACKAGES)/gst_plugins_good/control/control
	echo Version: $(GST_PLUGINS_GOOD_VER) >> $(PACKAGES)/gst_plugins_good/control/control
	echo Section: base/libraries >> $(PACKAGES)/gst_plugins_good/control/control
ifeq ($(BOXARCH), mips)
	echo Architecture: $(BOXARCH)el >> $(PACKAGES)/gst_plugins_good/control/control 
else
	echo Architecture: $(BOXARCH) >> $(PACKAGES)/gst_plugins_good/control/control 
endif
	echo Maintainer: $(MAINTAINER)  >> $(PACKAGES)/gst_plugins_good/control/control 
	echo Depends:  >> $(PACKAGES)/gst_plugins_good/control/control
	pushd $(PACKAGES)/gst_plugins_good/control && chmod +x * && tar --numeric-owner --group=0 --owner=0 -czf $(PKGS_DIR)/$@/control.tar.gz ./* && popd
	pushd $(PKGS_DIR)/$@ && echo 2.0 > debian-binary && ar rv $(PKGS_DIR)/gst_plugins_good-$(GST_PLUGINS_GOOD_VER)_$(BOXARCH)_all.ipk ./data.tar.gz ./control.tar.gz ./debian-binary && popd && rm -rf data.tar.gz control.tar.gz debian-binary
	rm -rf $(PACKAGES)/gst_plugins_good/control/control
	rm -rf $(PKGPREFIX)
	rm -rf $(PKGS_DIR)/$@
	$(END_BUILD)
	
#
# gst_plugins_bad-ipk
#
gst_plugins_bad-ipk: $(D)/bootstrap $(D)/libass $(D)/libcurl $(D)/libxml2 $(D)/openssl $(D)/librtmp $(D)/gstreamer $(D)/gst_plugins_base $(ARCHIVE)/$(GST_PLUGINS_BAD_SOURCE)
	$(START_BUILD)
	rm -rf $(PKGPREFIX)
	install -d $(PKGPREFIX)
	install -d $(PKGS_DIR)
	install -d $(PKGS_DIR)/$@
	$(REMOVE)/gst-plugins-bad-$(GST_PLUGINS_BAD_VER)
	$(UNTAR)/$(GST_PLUGINS_BAD_SOURCE)
	$(CHDIR)/gst-plugins-bad-$(GST_PLUGINS_BAD_VER); \
		$(call apply_patches, $(GST_PLUGINS_BAD_PATCH)); \
		./autogen.sh --noconfigure; \
		$(CONFIGURE) \
			--build=$(BUILD) \
			--host=$(TARGET) \
			--prefix=/usr \
			--datarootdir=/.remove \
			--enable-silent-rules \
			--disable-valgrind \
			$(GST_PLUGIN_CONFIG_DEBUG) \
			--disable-examples \
			--disable-gtk-doc-html \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(PKGPREFIX)
	rm -r $(PKGPREFIX)/usr/include $(PKGPREFIX)/usr/lib/pkgconfig
	$(REMOVE)/gst-plugins-bad-$(GST_PLUGINS_BAD_VER)
ifneq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), kerneldebug debug normal))
	find $(PKGPREFIX)/ -name '*' -exec $(TARGET)-strip --strip-unneeded {} &>/dev/null \;
endif
	pushd $(PKGPREFIX) && tar --numeric-owner --group=0 --owner=0 -czf $(PKGS_DIR)/$@/data.tar.gz ./* && popd
	touch $(PACKAGES)/gst_plugins_bad/control/control
	echo Package: gst_plugins_bad > $(PACKAGES)/gst_plugins_bad/control/control
	echo Version: $(GST_PLUGINS_BAD_VER) >> $(PACKAGES)/gst_plugins_bad/control/control
	echo Section: base/libraries >> $(PACKAGES)/gst_plugins_bad/control/control
ifeq ($(BOXARCH), mips)
	echo Architecture: $(BOXARCH)el >> $(PACKAGES)/gst_plugins_bad/control/control 
else
	echo Architecture: $(BOXARCH) >> $(PACKAGES)/gst_plugins_bad/control/control 
endif
	echo Maintainer: $(MAINTAINER)  >> $(PACKAGES)/gst_plugins_bad/control/control 
	echo Depends:  >> $(PACKAGES)/gst_plugins_bad/control/control
	pushd $(PACKAGES)/gst_plugins_bad/control && chmod +x * && tar --numeric-owner --group=0 --owner=0 -czf $(PKGS_DIR)/$@/control.tar.gz ./* && popd
	pushd $(PKGS_DIR)/$@ && echo 2.0 > debian-binary && ar rv $(PKGS_DIR)/gst_plugins_bad-$(GST_PLUGINS_BAD_VER)_$(BOXARCH)_all.ipk ./data.tar.gz ./control.tar.gz ./debian-binary && popd && rm -rf data.tar.gz control.tar.gz debian-binary
	rm -rf $(PACKAGES)/gst_plugins_bad/control/control
	rm -rf $(PKGPREFIX)
	rm -rf $(PKGS_DIR)/$@
	$(END_BUILD)
	
#
# gst_plugins_ugly-ipk
#
gst_plugins_ugly-ipk: $(D)/bootstrap $(D)/gstreamer $(D)/gst_plugins_base $(ARCHIVE)/$(GST_PLUGINS_UGLY_SOURCE)
	$(START_BUILD)
	rm -rf $(PKGPREFIX)
	install -d $(PKGPREFIX)
	install -d $(PKGS_DIR)
	install -d $(PKGS_DIR)/$@
	$(REMOVE)/gst-plugins-ugly-$(GST_PLUGINS_UGLY_VER)
	$(UNTAR)/$(GST_PLUGINS_UGLY_SOURCE)
	$(CHDIR)/gst-plugins-ugly-$(GST_PLUGINS_UGLY_VER); \
		./autogen.sh --noconfigure; \
		$(CONFIGURE) \
			--prefix=/usr \
			--datarootdir=/.remove \
			--enable-silent-rules \
			--disable-valgrind \
			$(GST_PLUGIN_CONFIG_DEBUG) \
			--disable-examples \
			--disable-gtk-doc-html \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(PKGPREFIX)
	$(REMOVE)/gst-plugins-ugly-$(GST_PLUGINS_UGLY_VER)
ifneq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), kerneldebug debug normal))
	find $(PKGPREFIX)/ -name '*' -exec $(TARGET)-strip --strip-unneeded {} &>/dev/null \;
endif
	pushd $(PKGPREFIX) && tar --numeric-owner --group=0 --owner=0 -czf $(PKGS_DIR)/$@/data.tar.gz ./* && popd
	touch $(PACKAGES)/gst_plugins_ugly/control/control
	echo Package: gst_plugins_ugly > $(PACKAGES)/gst_plugins_ugly/control/control
	echo Version: $(GST_PLUGINS_UGLY_VER) >> $(PACKAGES)/gst_plugins_ugly/control/control
	echo Section: base/libraries >> $(PACKAGES)/gst_plugins_ugly/control/control
ifeq ($(BOXARCH), mips)
	echo Architecture: $(BOXARCH)el >> $(PACKAGES)/gst_plugins_ugly/control/control 
else
	echo Architecture: $(BOXARCH) >> $(PACKAGES)/gst_plugins_ugly/control/control 
endif
	echo Maintainer: $(MAINTAINER)  >> $(PACKAGES)/gst_plugins_ugly/control/control 
	echo Depends:  >> $(PACKAGES)/gst_plugins_ugly/control/control
	pushd $(PACKAGES)/gst_plugins_ugly/control && chmod +x * && tar --numeric-owner --group=0 --owner=0 -czf $(PKGS_DIR)/$@/control.tar.gz ./* && popd
	pushd $(PKGS_DIR)/$@ && echo 2.0 > debian-binary && ar rv $(PKGS_DIR)/gst_plugins_ugly-$(GST_PLUGINS_UGLY_VER)_$(BOXARCH)_all.ipk ./data.tar.gz ./control.tar.gz ./debian-binary && popd && rm -rf data.tar.gz control.tar.gz debian-binary
	rm -rf $(PACKAGES)/gst_plugins_ugly/control/control
	rm -rf $(PKGPREFIX)
	rm -rf $(PKGS_DIR)/$@
	$(END_BUILD)
	
#
# gst_plugins_subsink-ipk
#
gst_plugins_subsink-ipk: $(D)/bootstrap $(D)/gstreamer $(D)/gst_plugins_base $(D)/gst_plugins_good $(D)/gst_plugins_bad $(D)/gst_plugins_ugly
	$(START_BUILD)
	rm -rf $(PKGPREFIX)
	install -d $(PKGPREFIX)
	install -d $(PKGS_DIR)
	install -d $(PKGS_DIR)/$@
	$(REMOVE)/gstreamer-$(GST_PLUGINS_SUBSINK_VER)-plugin-subsink
	set -e; if [ -d $(ARCHIVE)/gstreamer$(GST_PLUGINS_SUBSINK_VER)-plugin-subsink.git ]; \
		then cd $(ARCHIVE)/gstreamer$(GST_PLUGINS_SUBSINK_VER)-plugin-subsink.git; git pull; \
		else cd $(ARCHIVE); git clone https://github.com/christophecvr/gstreamer$(GST_PLUGINS_SUBSINK_VER)-plugin-subsink.git gstreamer$(GST_PLUGINS_SUBSINK_VER)-plugin-subsink.git; \
		fi
	cp -ra $(ARCHIVE)/gstreamer$(GST_PLUGINS_SUBSINK_VER)-plugin-subsink.git $(BUILD_TMP)/gstreamer$(GST_PLUGINS_SUBSINK_VER)-plugin-subsink
	$(CHDIR)/gstreamer$(GST_PLUGINS_SUBSINK_VER)-plugin-subsink; \
		aclocal --force -I m4; \
		libtoolize --copy --ltdl --force; \
		autoconf --force; \
		autoheader --force; \
		automake --add-missing --copy --force-missing --foreign; \
		$(CONFIGURE) \
			--prefix=/usr \
			--enable-silent-rules \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(PKGPREFIX)
	$(REMOVE)/gstreamer$(GST_PLUGINS_SUBSINK_VER)-plugin-subsink
ifneq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), kerneldebug debug normal))
	find $(PKGPREFIX)/ -name '*' -exec $(TARGET)-strip --strip-unneeded {} &>/dev/null \;
endif
	pushd $(PKGPREFIX) && tar --numeric-owner --group=0 --owner=0 -czf $(PKGS_DIR)/$@/data.tar.gz ./* && popd
	touch $(PACKAGES)/gst_plugins_subsink/control/control
	echo Package: gst_plugins_subsink > $(PACKAGES)/gst_plugins_subsink/control/control
	echo Version: $(GST_PLUGINS_SUBSINK_VER) >> $(PACKAGES)/gst_plugins_subsink/control/control
	echo Section: base/libraries >> $(PACKAGES)/gst_plugins_subsink/control/control
ifeq ($(BOXARCH), mips)
	echo Architecture: $(BOXARCH)el >> $(PACKAGES)/gst_plugins_subsink/control/control 
else
	echo Architecture: $(BOXARCH) >> $(PACKAGES)/gst_plugins_subsink/control/control 
endif
	echo Maintainer: $(MAINTAINER)  >> $(PACKAGES)/gst_plugins_subsink/control/control 
	echo Depends:  >> $(PACKAGES)/gst_plugins_subsink/control/control
	pushd $(PACKAGES)/gst_plugins_subsink/control && chmod +x * && tar --numeric-owner --group=0 --owner=0 -czf $(PKGS_DIR)/$@/control.tar.gz ./* && popd
	pushd $(PKGS_DIR)/$@ && echo 2.0 > debian-binary && ar rv $(PKGS_DIR)/gst_plugins_subsink-$(GST_PLUGINS_SUBSINK_VER)_$(BOXARCH)_all.ipk ./data.tar.gz ./control.tar.gz ./debian-binary && popd && rm -rf data.tar.gz control.tar.gz debian-binary
	rm -rf $(PACKAGES)/gst_plugins_subsink/control/control
	rm -rf $(PKGPREFIX)
	rm -rf $(PKGS_DIR)/$@
	$(END_BUILD)
	
#
# gst_plugins_dvbmediasink-ipk
#
gst_plugins_dvbmediasink-ipk: $(D)/bootstrap $(D)/gstreamer $(D)/gst_plugins_base $(D)/gst_plugins_good $(D)/gst_plugins_bad $(D)/gst_plugins_ugly $(D)/gst_plugins_subsink $(D)/libdca
	$(START_BUILD)
	rm -rf $(PKGPREFIX)
	install -d $(PKGPREFIX)
	install -d $(PKGS_DIR)
	install -d $(PKGS_DIR)/$@
	$(REMOVE)/gstreamer$(GST_PLUGINS_DVBMEDIASINK_VER)-plugin-dvbmediasink
	set -e; if [ -d $(ARCHIVE)/gstreamer$(GST_PLUGINS_DVBMEDIASINK_VER)-plugin-dvbmediasink.git ]; \
		then cd $(ARCHIVE)/gstreamer$(GST_PLUGINS_DVBMEDIASINK_VER)-plugin-dvbmediasink.git; git pull; \
		else cd $(ARCHIVE); git clone -b gst-1.0 https://github.com/OpenPLi/gst-plugin-dvbmediasink.git gstreamer$(GST_PLUGINS_DVBMEDIASINK_VER)-plugin-dvbmediasink.git; \
		fi
	cp -ra $(ARCHIVE)/gstreamer$(GST_PLUGINS_DVBMEDIASINK_VER)-plugin-dvbmediasink.git $(BUILD_TMP)/gstreamer$(GST_PLUGINS_DVBMEDIASINK_VER)-plugin-dvbmediasink
	$(CHDIR)/gstreamer$(GST_PLUGINS_DVBMEDIASINK_VER)-plugin-dvbmediasink; \
		aclocal --force -I m4; \
		libtoolize --copy --ltdl --force; \
		autoconf --force; \
		autoheader --force; \
		automake --add-missing --copy --force-missing --foreign; \
		$(CONFIGURE) \
			--prefix=/usr \
			--enable-silent-rules \
			--with-wma \
			--with-wmv \
			--with-pcm \
			--with-dts \
			--with-eac3 \
			--with-h265 \
			--with-vb6 \
			--with-vb8 \
			--with-vb9 \
			--with-spark \
			--with-gstversion=1.0 \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(PKGPREFIX)
	$(REMOVE)/gstreamer$(GST_PLUGINS_DVBMEDIASINK_VER)-plugin-dvbmediasink
ifneq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), kerneldebug debug normal))
	find $(PKGPREFIX)/ -name '*' -exec $(TARGET)-strip --strip-unneeded {} &>/dev/null \;
endif
	pushd $(PKGPREFIX) && tar --numeric-owner --group=0 --owner=0 -czf $(PKGS_DIR)/$@/data.tar.gz ./* && popd
	touch $(PACKAGES)/gst_plugins_dvbmediasink/control/control
	echo Package: gst_plugins_dvbmediasink > $(PACKAGES)/gst_plugins_dvbmediasink/control/control
	echo Version: $(GST_PLUGINS_DVBMEDIASINK_VER) >> $(PACKAGES)/gst_plugins_dvbmediasink/control/control
	echo Section: base/libraries >> $(PACKAGES)/gst_plugins_dvbmediasink/control/control
ifeq ($(BOXARCH), mips)
	echo Architecture: $(BOXARCH)el >> $(PACKAGES)/gst_plugins_dvbmediasink/control/control 
else
	echo Architecture: $(BOXARCH) >> $(PACKAGES)/gst_plugins_dvbmediasink/control/control 
endif
	echo Maintainer: $(MAINTAINER)  >> $(PACKAGES)/gst_plugins_dvbmediasink/control/control 
	echo Depends:  >> $(PACKAGES)/gst_plugins_dvbmediasink/control/control
	pushd $(PACKAGES)/gst_plugins_dvbmediasink/control && chmod +x * && tar --numeric-owner --group=0 --owner=0 -czf $(PKGS_DIR)/$@/control.tar.gz ./* && popd
	pushd $(PKGS_DIR)/$@ && echo 2.0 > debian-binary && ar rv $(PKGS_DIR)/gst_plugins_dvbmediasink-$(GST_PLUGINS_DVBMEDIASINK_VER)_$(BOXARCH)_all.ipk ./data.tar.gz ./control.tar.gz ./debian-binary && popd && rm -rf data.tar.gz control.tar.gz debian-binary
	rm -rf $(PACKAGES)/gst_plugins_dvbmediasink/control/control
	rm -rf $(PKGPREFIX)
	rm -rf $(PKGS_DIR)/$@
	$(END_BUILD)
	
#
# ffmpeg
#
ffmpeg-ipk: $(D)/bootstrap $(D)/openssl $(D)/bzip2 $(D)/freetype $(D)/libass $(D)/libxml2 $(D)/libroxml $(D)/librtmp $(ARCHIVE)/$(FFMPEG_SOURCE)
	$(START_BUILD)
	rm -rf $(PKGPREFIX)
	install -d $(PKGPREFIX)
	install -d $(PKGS_DIR)
	install -d $(PKGS_DIR)/$@
	$(REMOVE)/ffmpeg-$(FFMPEG_VER)
	$(UNTAR)/$(FFMPEG_SOURCE)
	$(CHDIR)/ffmpeg-$(FFMPEG_VER); \
		$(call apply_patches, $(FFMPEG_PATCH)); \
		./configure \
			--disable-ffplay \
			--disable-ffprobe \
			\
			--disable-doc \
			--disable-htmlpages \
			--disable-manpages \
			--disable-podpages \
			--disable-txtpages \
			\
			--disable-altivec \
			--disable-amd3dnow \
			--disable-amd3dnowext \
			--disable-mmx \
			--disable-mmxext \
			--disable-sse \
			--disable-sse2 \
			--disable-sse3 \
			--disable-ssse3 \
			--disable-sse4 \
			--disable-sse42 \
			--disable-avx \
			--disable-xop \
			--disable-fma3 \
			--disable-fma4 \
			--disable-avx2 \
			--disable-armv5te \
			--disable-armv6 \
			--disable-armv6t2 \
			--disable-vfp \
			--disable-inline-asm \
			--disable-mips32r2 \
			--disable-mipsdsp \
			--disable-mipsdspr2 \
			--disable-fast-unaligned \
			\
			--disable-dxva2 \
			--disable-vaapi \
			--disable-vdpau \
			\
			--disable-muxers \
			--enable-muxer=apng \
			--enable-muxer=flac \
			--enable-muxer=mp3 \
			--enable-muxer=h261 \
			--enable-muxer=h263 \
			--enable-muxer=h264 \
			--enable-muxer=hevc \
			--enable-muxer=image2 \
			--enable-muxer=image2pipe \
			--enable-muxer=m4v \
			--enable-muxer=matroska \
			--enable-muxer=mjpeg \
			--enable-muxer=mp4 \
			--enable-muxer=mpeg1video \
			--enable-muxer=mpeg2video \
			--enable-muxer=mpegts \
			--enable-muxer=ogg \
			\
			--disable-parsers \
			--enable-parser=aac \
			--enable-parser=aac_latm \
			--enable-parser=ac3 \
			--enable-parser=dca \
			--enable-parser=dvbsub \
			--enable-parser=dvd_nav \
			--enable-parser=dvdsub \
			--enable-parser=flac \
			--enable-parser=h264 \
			--enable-parser=hevc \
			--enable-parser=mjpeg \
			--enable-parser=mpeg4video \
			--enable-parser=mpegvideo \
			--enable-parser=mpegaudio \
			--enable-parser=png \
			--enable-parser=vc1 \
			--enable-parser=vorbis \
			--enable-parser=vp8 \
			--enable-parser=vp9 \
			\
			--disable-encoders \
			--enable-encoder=aac \
			--enable-encoder=h261 \
			--enable-encoder=h263 \
			--enable-encoder=h263p \
			--enable-encoder=jpeg2000 \
			--enable-encoder=jpegls \
			--enable-encoder=ljpeg \
			--enable-encoder=mjpeg \
			--enable-encoder=mpeg1video \
			--enable-encoder=mpeg2video \
			--enable-encoder=mpeg4 \
			--enable-encoder=png \
			--enable-encoder=rawvideo \
			\
			--disable-decoders \
			--enable-decoder=aac \
			--enable-decoder=aac_latm \
			--enable-decoder=adpcm_ct \
			--enable-decoder=adpcm_g722 \
			--enable-decoder=adpcm_g726 \
			--enable-decoder=adpcm_g726le \
			--enable-decoder=adpcm_ima_amv \
			--enable-decoder=adpcm_ima_oki \
			--enable-decoder=adpcm_ima_qt \
			--enable-decoder=adpcm_ima_rad \
			--enable-decoder=adpcm_ima_wav \
			--enable-decoder=adpcm_ms \
			--enable-decoder=adpcm_sbpro_2 \
			--enable-decoder=adpcm_sbpro_3 \
			--enable-decoder=adpcm_sbpro_4 \
			--enable-decoder=adpcm_swf \
			--enable-decoder=adpcm_yamaha \
			--enable-decoder=alac \
			--enable-decoder=ape \
			--enable-decoder=atrac1 \
			--enable-decoder=atrac3 \
			--enable-decoder=atrac3p \
			--enable-decoder=ass \
			--enable-decoder=cook \
			--enable-decoder=dca \
			--enable-decoder=dsd_lsbf \
			--enable-decoder=dsd_lsbf_planar \
			--enable-decoder=dsd_msbf \
			--enable-decoder=dsd_msbf_planar \
			--enable-decoder=dvbsub \
			--enable-decoder=dvdsub \
			--enable-decoder=eac3 \
			--enable-decoder=evrc \
			--enable-decoder=flac \
			--enable-decoder=g723_1 \
			--enable-decoder=g729 \
			--enable-decoder=h261 \
			--enable-decoder=h263 \
			--enable-decoder=h263i \
			--enable-decoder=h264 \
			--enable-decoder=hevc \
			--enable-decoder=iac \
			--enable-decoder=imc \
			--enable-decoder=jpeg2000 \
			--enable-decoder=jpegls \
			--enable-decoder=mace3 \
			--enable-decoder=mace6 \
			--enable-decoder=metasound \
			--enable-decoder=mjpeg \
			--enable-decoder=mlp \
			--enable-decoder=movtext \
			--enable-decoder=mp1 \
			--enable-decoder=mp2 \
			--enable-decoder=mp3 \
			--enable-decoder=mp3adu \
			--enable-decoder=mp3on4 \
			--enable-decoder=mpeg1video \
			--enable-decoder=mpeg2video \
			--enable-decoder=mpeg4 \
			--enable-decoder=nellymoser \
			--enable-decoder=opus \
			--enable-decoder=pcm_alaw \
			--enable-decoder=pcm_bluray \
			--enable-decoder=pcm_dvd \
			--enable-decoder=pcm_f32be \
			--enable-decoder=pcm_f32le \
			--enable-decoder=pcm_f64be \
			--enable-decoder=pcm_f64le \
			--enable-decoder=pcm_lxf \
			--enable-decoder=pcm_mulaw \
			--enable-decoder=pcm_s16be \
			--enable-decoder=pcm_s16be_planar \
			--enable-decoder=pcm_s16le \
			--enable-decoder=pcm_s16le_planar \
			--enable-decoder=pcm_s24be \
			--enable-decoder=pcm_s24daud \
			--enable-decoder=pcm_s24le \
			--enable-decoder=pcm_s24le_planar \
			--enable-decoder=pcm_s32be \
			--enable-decoder=pcm_s32le \
			--enable-decoder=pcm_s32le_planar \
			--enable-decoder=pcm_s8 \
			--enable-decoder=pcm_s8_planar \
			--enable-decoder=pcm_u16be \
			--enable-decoder=pcm_u16le \
			--enable-decoder=pcm_u24be \
			--enable-decoder=pcm_u24le \
			--enable-decoder=pcm_u32be \
			--enable-decoder=pcm_u32le \
			--enable-decoder=pcm_u8 \
			--enable-decoder=pgssub \
			--enable-decoder=png \
			--enable-decoder=qcelp \
			--enable-decoder=qdm2 \
			--enable-decoder=ra_144 \
			--enable-decoder=ra_288 \
			--enable-decoder=ralf \
			--enable-decoder=s302m \
			--enable-decoder=sipr \
			--enable-decoder=shorten \
			--enable-decoder=sonic \
			--enable-decoder=srt \
			--enable-decoder=ssa \
			--enable-decoder=subrip \
			--enable-decoder=subviewer \
			--enable-decoder=subviewer1 \
			--enable-decoder=tak \
			--enable-decoder=text \
			--enable-decoder=truehd \
			--enable-decoder=truespeech \
			--enable-decoder=tta \
			--enable-decoder=vorbis \
			--enable-decoder=wmalossless \
			--enable-decoder=wmapro \
			--enable-decoder=wmav1 \
			--enable-decoder=wmav2 \
			--enable-decoder=wmavoice \
			--enable-decoder=wavpack \
			--enable-decoder=xsub \
			\
			--disable-demuxers \
			--enable-demuxer=aac \
			--enable-demuxer=ac3 \
			--enable-demuxer=apng \
			--enable-demuxer=ass \
			--enable-demuxer=avi \
			--enable-demuxer=dts \
			--enable-demuxer=dash \
			--enable-demuxer=ffmetadata \
			--enable-demuxer=flac \
			--enable-demuxer=flv \
			--enable-demuxer=h264 \
			--enable-demuxer=hls \
			--enable-demuxer=image2 \
			--enable-demuxer=image2pipe \
			--enable-demuxer=image_bmp_pipe \
			--enable-demuxer=image_jpeg_pipe \
			--enable-demuxer=image_jpegls_pipe \
			--enable-demuxer=image_png_pipe \
			--enable-demuxer=m4v \
			--enable-demuxer=matroska \
			--enable-demuxer=mjpeg \
			--enable-demuxer=mov \
			--enable-demuxer=mp3 \
			--enable-demuxer=mpegts \
			--enable-demuxer=mpegtsraw \
			--enable-demuxer=mpegps \
			--enable-demuxer=mpegvideo \
			--enable-demuxer=mpjpeg \
			--enable-demuxer=ogg \
			--enable-demuxer=pcm_s16be \
			--enable-demuxer=pcm_s16le \
			--enable-demuxer=realtext \
			--enable-demuxer=rawvideo \
			--enable-demuxer=rm \
			--enable-demuxer=rtp \
			--enable-demuxer=rtsp \
			--enable-demuxer=srt \
			--enable-demuxer=vc1 \
			--enable-demuxer=wav \
			--enable-demuxer=webm_dash_manifest \
			\
			--disable-filters \
			--enable-filter=scale \
			--enable-filter=drawtext \
			\
			--enable-zlib \
			--enable-bzlib \
			--enable-openssl \
			--enable-libass \
			--enable-bsfs \
			--disable-xlib \
			--disable-libxcb \
			--disable-libxcb-shm \
			--disable-libxcb-xfixes \
			--disable-libxcb-shape \
			\
			$(FFMPEG_CONF_OPTS) \
			\
			--enable-shared \
			--enable-network \
			--enable-nonfree \
			--disable-static \
			--disable-debug \
			--disable-runtime-cpudetect \
			--enable-pic \
			--enable-pthreads \
			--enable-hardcoded-tables \
			--disable-optimizations \
			\
			--pkg-config=pkg-config \
			--enable-cross-compile \
			--cross-prefix=$(TARGET)- \
			--extra-cflags="$(TARGET_CFLAGS) $(FFMPRG_EXTRA_CFLAGS)" \
			--extra-ldflags="$(TARGET_LDFLAGS) -lrt" \
			--arch=$(BOXARCH) \
			--target-os=linux \
			--prefix=/usr \
			--bindir=/sbin \
			--mandir=/.remove \
			--datadir=/.remove \
			--docdir=/.remove \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(PKGPREFIX)
	rm -r $(PKGPREFIX)/usr/include $(PKGPREFIX)/usr/lib/pkgconfig
	$(REMOVE)/ffmpeg-$(FFMPEG_VER)
ifneq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), kerneldebug debug normal))
	find $(PKGPREFIX)/ -name '*' -exec $(TARGET)-strip --strip-unneeded {} &>/dev/null \;
endif
	pushd $(PKGPREFIX) && tar --numeric-owner --group=0 --owner=0 -czf $(PKGS_DIR)/$@/data.tar.gz ./* && popd
	touch $(PACKAGES)/ffmpeg/control/control
	echo Package: ffmpeg > $(PACKAGES)/ffmpeg/control/control
	echo Version: $(FFMPEG_VER) >> $(PACKAGES)/ffmpeg/control/control
	echo Section: base/libraries >> $(PACKAGES)/ffmpeg/control/control
ifeq ($(BOXARCH), mips)
	echo Architecture: $(BOXARCH)el >> $(PACKAGES)/ffmpeg/control/control 
else
	echo Architecture: $(BOXARCH) >> $(PACKAGES)/ffmpeg/control/control 
endif
	echo Maintainer: $(MAINTAINER)  >> $(PACKAGES)/ffmpeg/control/control 
	echo Depends:  >> $(PACKAGES)/ffmpeg/control/control
	pushd $(PACKAGES)/ffmpeg/control && chmod +x * && tar --numeric-owner --group=0 --owner=0 -czf $(PKGS_DIR)/$@/control.tar.gz ./* && popd
	pushd $(PKGS_DIR)/$@ && echo 2.0 > debian-binary && ar rv $(PKGS_DIR)/ffmpeg-$(FFMPEG_VER)_$(BOXARCH)_all.ipk ./data.tar.gz ./control.tar.gz ./debian-binary && popd && rm -rf data.tar.gz control.tar.gz debian-binary
	rm -rf $(PACKAGES)/ffmpeg/control/control
	rm -rf $(PKGPREFIX)
	rm -rf $(PKGS_DIR)/$@
	$(END_BUILD)

#
# lua
#
lua-ipk: $(D)/bootstrap $(D)/ncurses $(ARCHIVE)/$(LUAPOSIX_SOURCE) $(ARCHIVE)/$(LUA_SOURCE)
	$(START_BUILD)
	rm -rf $(PKGPREFIX)
	install -d $(PKGPREFIX)
	install -d $(PKGS_DIR)
	install -d $(PKGS_DIR)/$@
	$(REMOVE)/lua-$(LUA_VER)
	mkdir -p $(PKGPREFIX)/usr/share/lua/$(LUA_VER_SHORT)
	$(UNTAR)/$(LUA_SOURCE)
	$(CHDIR)/lua-$(LUA_VER); \
		$(call apply_patches, $(LUAPOSIX_PATCH)); \
		tar xf $(ARCHIVE)/$(LUAPOSIX_SOURCE); \
		cd luaposix-git-$(LUAPOSIX_VER)/ext; cp posix/posix.c include/lua52compat.h ../../src/; cd ../..; \
		cd luaposix-git-$(LUAPOSIX_VER)/lib; cp *.lua $(TARGET_DIR)/usr/share/lua/$(LUA_VER_SHORT); cd ../..; \
		sed -i 's/<config.h>/"config.h"/' src/posix.c; \
		sed -i '/^#define/d' src/lua52compat.h; \
		sed -i 's|man/man1|/.remove|' Makefile; \
		$(MAKE) linux CC=$(TARGET)-gcc CPPFLAGS="$(TARGET_CPPFLAGS) -fPIC" LDFLAGS="-L$(TARGET_DIR)/usr/lib" BUILDMODE=dynamic PKG_VERSION=$(LUA_VER); \
		$(MAKE) install INSTALL_TOP=$(PKGPREFIX)/usr INSTALL_MAN=$(PKGPREFIX)/.remove
	rm -r $(PKGPREFIX)/usr/include $(PKGPREFIX)/usr/bin/luac
	$(REMOVE)/lua-$(LUA_VER)
ifneq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), kerneldebug debug normal))
	find $(PKGPREFIX)/ -name '*' -exec $(TARGET)-strip --strip-unneeded {} &>/dev/null \;
endif
	pushd $(PKGPREFIX) && tar --numeric-owner --group=0 --owner=0 -czf $(PKGS_DIR)/$@/data.tar.gz ./* && popd
	touch $(PACKAGES)/lua/control/control
	echo Package: lua > $(PACKAGES)/lua/control/control
	echo Version: $(LUA_VER) >> $(PACKAGES)/lua/control/control
	echo Section: base/libraries >> $(PACKAGES)/lua/control/control
ifeq ($(BOXARCH), mips)
	echo Architecture: $(BOXARCH)el >> $(PACKAGES)/lua/control/control 
else
	echo Architecture: $(BOXARCH) >> $(PACKAGES)/lua/control/control 
endif
	echo Maintainer: $(MAINTAINER)  >> $(PACKAGES)/lua/control/control 
	echo Depends:  >> $(PACKAGES)/lua/control/control
	pushd $(PACKAGES)/lua/control && chmod +x * && tar --numeric-owner --group=0 --owner=0 -czf $(PKGS_DIR)/$@/control.tar.gz ./* && popd
	pushd $(PKGS_DIR)/$@ && echo 2.0 > debian-binary && ar rv $(PKGS_DIR)/lua-$(LUA_VER)_$(BOXARCH)_all.ipk ./data.tar.gz ./control.tar.gz ./debian-binary && popd && rm -rf data.tar.gz control.tar.gz debian-binary
	rm -rf $(PACKAGES)/lua/control/control
	rm -rf $(PKGPREFIX)
	rm -rf $(PKGS_DIR)/$@
	$(END_BUILD)
	
#
# luacurl-ipk
#
luacurl-ipk: $(D)/bootstrap $(D)/libcurl $(D)/lua $(ARCHIVE)/$(LUACURL_SOURCE)
	$(START_BUILD)
	rm -rf $(PKGPREFIX)
	install -d $(PKGPREFIX)
	install -d $(PKGS_DIR)
	install -d $(PKGS_DIR)/$@
	$(REMOVE)/luacurl-git-$(LUACURL_VER)
	$(UNTAR)/$(LUACURL_SOURCE)
	$(CHDIR)/luacurl-git-$(LUACURL_VER); \
		$(MAKE) CC=$(TARGET)-gcc LDFLAGS="-L$(TARGET_DIR)/usr/lib" \
			LIBDIR=$(TARGET_DIR)/usr/lib \
			LUA_INC=$(TARGET_DIR)/usr/include; \
		$(MAKE) install DESTDIR=$(PKGPREFIX) LUA_CMOD=/usr/lib/lua/$(LUA_VER_SHORT) LUA_LMOD=/usr/share/lua/$(LUA_VER_SHORT)
	$(REMOVE)/luacurl-git-$(LUACURL_VER)
ifneq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), kerneldebug debug normal))
	find $(PKGPREFIX)/ -name '*' -exec $(TARGET)-strip --strip-unneeded {} &>/dev/null \;
endif
	pushd $(PKGPREFIX) && tar --numeric-owner --group=0 --owner=0 -czf $(PKGS_DIR)/$@/data.tar.gz ./* && popd
	touch $(PACKAGES)/luacurl/control/control
	echo Package: luacurl > $(PACKAGES)/luacurl/control/control
	echo Version: $(LUACURL_VER) >> $(PACKAGES)/luacurl/control/control
	echo Section: base/libraries >> $(PACKAGES)/luacurl/control/control
ifeq ($(BOXARCH), mips)
	echo Architecture: $(BOXARCH)el >> $(PACKAGES)/luacurl/control/control 
else
	echo Architecture: $(BOXARCH) >> $(PACKAGES)/luacurl/control/control 
endif
	echo Maintainer: $(MAINTAINER)  >> $(PACKAGES)/luacurl/control/control 
	echo Depends:  >> $(PACKAGES)/luacurl/control/control
	pushd $(PACKAGES)/luacurl/control && chmod +x * && tar --numeric-owner --group=0 --owner=0 -czf $(PKGS_DIR)/$@/control.tar.gz ./* && popd
	pushd $(PKGS_DIR)/$@ && echo 2.0 > debian-binary && ar rv $(PKGS_DIR)/luacurl-$(LUACURL_VER)_$(BOXARCH)_all.ipk ./data.tar.gz ./control.tar.gz ./debian-binary && popd && rm -rf data.tar.gz control.tar.gz debian-binary
	rm -rf $(PACKAGES)/luacurl/control/control
	rm -rf $(PKGPREFIX)
	rm -rf $(PKGS_DIR)/$@
	$(END_BUILD)
	
#
# luaexpat-ipk
#
luaexpat-ipk: $(D)/bootstrap $(D)/lua $(D)/expat $(ARCHIVE)/$(LUAEXPAT_SOURCE)
	$(START_BUILD)
	rm -rf $(PKGPREFIX)
	install -d $(PKGPREFIX)
	install -d $(PKGS_DIR)
	install -d $(PKGS_DIR)/$@
	$(REMOVE)/luaexpat-$(LUAEXPAT_VER)
	$(UNTAR)/$(LUAEXPAT_SOURCE)
	$(CHDIR)/luaexpat-$(LUAEXPAT_VER); \
		$(call apply_patches, $(LUAEXPAT_PATCH)); \
		$(MAKE) CC=$(TARGET)-gcc LDFLAGS="-L$(TARGET_DIR)/usr/lib" PREFIX=$(TARGET_DIR)/usr; \
		$(MAKE) install DESTDIR=$(PKGPREFIX)/usr
	$(REMOVE)/luaexpat-$(LUAEXPAT_VER)
ifneq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), kerneldebug debug normal))
	find $(PKGPREFIX)/ -name '*' -exec $(TARGET)-strip --strip-unneeded {} &>/dev/null \;
endif
	pushd $(PKGPREFIX) && tar --numeric-owner --group=0 --owner=0 -czf $(PKGS_DIR)/$@/data.tar.gz ./* && popd
	touch $(PACKAGES)/luaexpat/control/control
	echo Package: luaexpat > $(PACKAGES)/luaexpat/control/control
	echo Version: $(LUAEXPAT_VER) >> $(PACKAGES)/luaexpat/control/control
	echo Section: base/libraries >> $(PACKAGES)/luaexpat/control/control
ifeq ($(BOXARCH), mips)
	echo Architecture: $(BOXARCH)el >> $(PACKAGES)/luaexpat/control/control 
else
	echo Architecture: $(BOXARCH) >> $(PACKAGES)/luaexpat/control/control 
endif
	echo Maintainer: $(MAINTAINER)  >> $(PACKAGES)/luaexpat/control/control 
	echo Depends:  >> $(PACKAGES)/luaexpat/control/control
	pushd $(PACKAGES)/luaexpat/control && chmod +x * && tar --numeric-owner --group=0 --owner=0 -czf $(PKGS_DIR)/$@/control.tar.gz ./* && popd
	pushd $(PKGS_DIR)/$@ && echo 2.0 > debian-binary && ar rv $(PKGS_DIR)/luaexpat-$(LUAEXPAT_VER)_$(BOXARCH)_all.ipk ./data.tar.gz ./control.tar.gz ./debian-binary && popd && rm -rf data.tar.gz control.tar.gz debian-binary
	rm -rf $(PACKAGES)/luaexpat/control/control
	rm -rf $(PKGPREFIX)
	rm -rf $(PKGS_DIR)/$@
	$(END_BUILD)

#
# luasocket-ipk
#	
luasocket-ipk: $(D)/bootstrap $(D)/lua $(ARCHIVE)/$(LUASOCKET_SOURCE)
	$(START_BUILD)
	rm -rf $(PKGPREFIX)
	install -d $(PKGPREFIX)
	install -d $(PKGS_DIR)
	install -d $(PKGS_DIR)/$@
	$(REMOVE)/luasocket-git-$(LUASOCKET_VER)
	$(UNTAR)/$(LUASOCKET_SOURCE)
	$(CHDIR)/luasocket-git-$(LUASOCKET_VER); \
		sed -i -e "s@LD_linux=gcc@LD_LINUX=$(TARGET)-gcc@" -e "s@CC_linux=gcc@CC_LINUX=$(TARGET)-gcc -L$(TARGET_DIR)/usr/lib@" -e "s@DESTDIR?=@DESTDIR?=$(PKGPREFIX)/usr@" src/makefile; \
		$(MAKE) CC=$(TARGET)-gcc LD=$(TARGET)-gcc LUAV=$(LUA_VER_SHORT) PLAT=linux COMPAT=COMPAT LUAINC_linux=$(TARGET_DIR)/usr/include LUAPREFIX_linux=; \
		$(MAKE) install LUAPREFIX_linux= LUAV=$(LUA_VER_SHORT)
	$(REMOVE)/luasocket-git-$(LUASOCKET_VER)
ifneq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), kerneldebug debug normal))
	find $(PKGPREFIX)/ -name '*' -exec $(TARGET)-strip --strip-unneeded {} &>/dev/null \;
endif
	pushd $(PKGPREFIX) && tar --numeric-owner --group=0 --owner=0 -czf $(PKGS_DIR)/$@/data.tar.gz ./* && popd
	touch $(PACKAGES)/luasocket/control/control
	echo Package: luasocket > $(PACKAGES)/luasocket/control/control
	echo Version: $(LUASOCKET_VER) >> $(PACKAGES)/luasocket/control/control
	echo Section: base/libraries >> $(PACKAGES)/luasocket/control/control
ifeq ($(BOXARCH), mips)
	echo Architecture: $(BOXARCH)el >> $(PACKAGES)/luasocket/control/control 
else
	echo Architecture: $(BOXARCH) >> $(PACKAGES)/luasocket/control/control 
endif
	echo Maintainer: $(MAINTAINER)  >> $(PACKAGES)/luasocket/control/control 
	echo Depends:  >> $(PACKAGES)/luasocket/control/control
	pushd $(PACKAGES)/luasocket/control && chmod +x * && tar --numeric-owner --group=0 --owner=0 -czf $(PKGS_DIR)/$@/control.tar.gz ./* && popd
	pushd $(PKGS_DIR)/$@ && echo 2.0 > debian-binary && ar rv $(PKGS_DIR)/luasocket-$(LUASOCKET_VER)_$(BOXARCH)_all.ipk ./data.tar.gz ./control.tar.gz ./debian-binary && popd && rm -rf data.tar.gz control.tar.gz debian-binary
	rm -rf $(PACKAGES)/luasocket/control/control
	rm -rf $(PKGPREFIX)
	rm -rf $(PKGS_DIR)/$@
	$(END_BUILD)
	
#
# luafeedparser-ipk
#
luafeedparser-ipk: $(D)/bootstrap $(D)/lua $(ARCHIVE)/$(LUAFEEDPARSER_SOURCE)
	$(START_BUILD)
	rm -rf $(PKGPREFIX)
	install -d $(PKGPREFIX)
	install -d $(PKGS_DIR)
	install -d $(PKGS_DIR)/$@
	install -d $(PKGPREFIX)/usr/share/lua/$(LUA_VER_SHORT)
	$(REMOVE)/luafeedparser-git-$(LUAFEEDPARSER_VER)
	$(UNTAR)/$(LUAFEEDPARSER_SOURCE)
	$(CHDIR)/luafeedparser-git-$(LUAFEEDPARSER_VER); \
		sed -i -e "s/^PREFIX.*//" -e "s/^LUA_DIR.*//" Makefile ; \
		$(BUILDENV) $(MAKE) install  LUA_DIR=$(PKGPREFIX)/usr/share/lua/$(LUA_VER_SHORT)
	$(REMOVE)/luafeedparser-git-$(LUAFEEDPARSER_VER)
ifneq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), kerneldebug debug normal))
	find $(PKGPREFIX)/ -name '*' -exec $(TARGET)-strip --strip-unneeded {} &>/dev/null \;
endif
	pushd $(PKGPREFIX) && tar --numeric-owner --group=0 --owner=0 -czf $(PKGS_DIR)/$@/data.tar.gz ./* && popd
	touch $(PACKAGES)/luafeedparser/control/control
	echo Package: luafeedparser > $(PACKAGES)/luafeedparser/control/control
	echo Version: $(LUAFEEDPARSER_VER) >> $(PACKAGES)/luafeedparser/control/control
	echo Section: base/libraries >> $(PACKAGES)/luafeedparser/control/control
ifeq ($(BOXARCH), mips)
	echo Architecture: $(BOXARCH)el >> $(PACKAGES)/luafeedparser/control/control 
else
	echo Architecture: $(BOXARCH) >> $(PACKAGES)/luafeedparser/control/control 
endif
	echo Maintainer: $(MAINTAINER)  >> $(PACKAGES)/luafeedparser/control/control 
	echo Depends:  >> $(PACKAGES)/luafeedparser/control/control
	pushd $(PACKAGES)/luafeedparser/control && chmod +x * && tar --numeric-owner --group=0 --owner=0 -czf $(PKGS_DIR)/$@/control.tar.gz ./* && popd
	pushd $(PKGS_DIR)/$@ && echo 2.0 > debian-binary && ar rv $(PKGS_DIR)/luafeedparser-$(LUAFEEDPARSER_VER)_$(BOXARCH)_all.ipk ./data.tar.gz ./control.tar.gz ./debian-binary && popd && rm -rf data.tar.gz control.tar.gz debian-binary
	rm -rf $(PACKAGES)/luafeedparser/control/control
	rm -rf $(PKGPREFIX)
	rm -rf $(PKGS_DIR)/$@
	$(END_BUILD)
	
#
# luasoap-ipk
#
luasoap-ipk: $(D)/bootstrap $(D)/lua $(ARCHIVE)/$(LUASOAP_SOURCE)
	$(START_BUILD)
	rm -rf $(PKGPREFIX)
	install -d $(PKGPREFIX)
	install -d $(PKGS_DIR)
	install -d $(PKGS_DIR)/$@
	install -d $(PKGPREFIX)/usr/share/lua/$(LUA_VER_SHORT)
	$(REMOVE)/luasoap-$(LUASOAP_VER)
	$(UNTAR)/$(LUASOAP_SOURCE)
	$(CHDIR)/luasoap-$(LUASOAP_VER); \
		$(call apply_patches, $(LUASOAP_PATCH)); \
		$(MAKE) install LUA_DIR=$(PKGPREFIX)/usr/share/lua/$(LUA_VER_SHORT)
	$(REMOVE)/luasoap-$(LUASOAP_VER)
ifneq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), kerneldebug debug normal))
	find $(PKGPREFIX)/ -name '*' -exec $(TARGET)-strip --strip-unneeded {} &>/dev/null \;
endif
	pushd $(PKGPREFIX) && tar --numeric-owner --group=0 --owner=0 -czf $(PKGS_DIR)/$@/data.tar.gz ./* && popd
	touch $(PACKAGES)/luasoap/control/control
	echo Package: luasoap > $(PACKAGES)/luasoap/control/control
	echo Version: $(LUA_VER_SHORT) >> $(PACKAGES)/luasoap/control/control
	echo Section: base/libraries >> $(PACKAGES)/luasoap/control/control
ifeq ($(BOXARCH), mips)
	echo Architecture: $(BOXARCH)el >> $(PACKAGES)/luasoap/control/control 
else
	echo Architecture: $(BOXARCH) >> $(PACKAGES)/luasoap/control/control 
endif
	echo Maintainer: $(MAINTAINER)  >> $(PACKAGES)/luasoap/control/control 
	echo Depends:  >> $(PACKAGES)/luasoap/control/control
	pushd $(PACKAGES)/luasoap/control && chmod +x * && tar --numeric-owner --group=0 --owner=0 -czf $(PKGS_DIR)/$@/control.tar.gz ./* && popd
	pushd $(PKGS_DIR)/$@ && echo 2.0 > debian-binary && ar rv $(PKGS_DIR)/luasoap-$(LUA_VER_SHORT)_$(BOXARCH)_all.ipk ./data.tar.gz ./control.tar.gz ./debian-binary && popd && rm -rf data.tar.gz control.tar.gz debian-binary
	rm -rf $(PACKAGES)/luasoap/control/control
	rm -rf $(PKGPREFIX)
	rm -rf $(PKGS_DIR)/$@
	$(END_BUILD)
	
#
# luajson-ipk
#
luajson-ipk: $(D)/bootstrap $(D)/lua $(ARCHIVE)/json.lua
	$(START_BUILD)
	rm -rf $(PKGPREFIX)
	install -d $(PKGPREFIX)
	install -d $(PKGS_DIR)
	install -d $(PKGS_DIR)/$@
	install -d $(PKGPREFIX)/usr/share/lua/$(LUA_VER_SHORT)
	cp $(ARCHIVE)/json.lua $(PKGPREFIX)/usr/share/lua/$(LUA_VER_SHORT)/json.lua
ifneq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), kerneldebug debug normal))
	find $(PKGPREFIX)/ -name '*' -exec $(TARGET)-strip --strip-unneeded {} &>/dev/null \;
endif
	pushd $(PKGPREFIX) && tar --numeric-owner --group=0 --owner=0 -czf $(PKGS_DIR)/$@/data.tar.gz ./* && popd
	touch $(PACKAGES)/luajson/control/control
	echo Package: luajson > $(PACKAGES)/luajson/control/control
	echo Version: $(LUA_VER_SHORT) >> $(PACKAGES)/luajson/control/control
	echo Section: base/libraries >> $(PACKAGES)/luajson/control/control
ifeq ($(BOXARCH), mips)
	echo Architecture: $(BOXARCH)el >> $(PACKAGES)/luajson/control/control 
else
	echo Architecture: $(BOXARCH) >> $(PACKAGES)/luajson/control/control 
endif
	echo Maintainer: $(MAINTAINER)  >> $(PACKAGES)/luajson/control/control 
	echo Depends:  >> $(PACKAGES)/luajson/control/control
	pushd $(PACKAGES)/luajson/control && chmod +x * && tar --numeric-owner --group=0 --owner=0 -czf $(PKGS_DIR)/$@/control.tar.gz ./* && popd
	pushd $(PKGS_DIR)/$@ && echo 2.0 > debian-binary && ar rv $(PKGS_DIR)/luajson-$(LUA_VER_SHORT)_$(BOXARCH)_all.ipk ./data.tar.gz ./control.tar.gz ./debian-binary && popd && rm -rf data.tar.gz control.tar.gz debian-binary
	rm -rf $(PACKAGES)/luajson/control/control
	rm -rf $(PKGPREFIX)
	rm -rf $(PKGS_DIR)/$@
	$(END_BUILD)
	
#
# python
#
python-ipk: $(D)/bootstrap $(D)/host_python $(D)/ncurses $(D)/zlib $(D)/openssl $(D)/libffi $(D)/bzip2 $(D)/readline $(D)/sqlite $(ARCHIVE)/$(PYTHON_SOURCE)
	$(START_BUILD)
	rm -rf $(PKGPREFIX)
	install -d $(PKGPREFIX)
	install -d $(PKGS_DIR)
	install -d $(PKGS_DIR)/$@
	$(REMOVE)/Python-$(PYTHON_VER)
	$(UNTAR)/$(PYTHON_SOURCE)
	$(CHDIR)/Python-$(PYTHON_VER); \
		$(call apply_patches, $(PYTHON_PATCH)); \
		CONFIG_SITE= \
		$(BUILDENV) \
		autoreconf -fiv Modules/_ctypes/libffi; \
		autoconf; \
		./configure \
			--build=$(BUILD) \
			--host=$(TARGET) \
			--target=$(TARGET) \
			--prefix=/usr \
			--mandir=/.remove \
			--sysconfdir=/etc \
			--enable-shared \
			--with-lto \
			--enable-ipv6 \
			--with-threads \
			--with-pymalloc \
			--with-signal-module \
			--with-wctype-functions \
			ac_sys_system=Linux \
			ac_sys_release=2 \
			ac_cv_file__dev_ptmx=no \
			ac_cv_file__dev_ptc=no \
			ac_cv_have_long_long_format=yes \
			ac_cv_no_strict_aliasing_ok=yes \
			ac_cv_pthread=yes \
			ac_cv_cxx_thread=yes \
			ac_cv_sizeof_off_t=8 \
			ac_cv_have_chflags=no \
			ac_cv_have_lchflags=no \
			ac_cv_py_format_size_t=yes \
			ac_cv_broken_sem_getvalue=no \
			HOSTPYTHON=$(HOST_DIR)/bin/python$(PYTHON_VER_MAJOR) \
		; \
		$(MAKE) $(MAKE_OPTS) \
			PYTHON_MODULES_INCLUDE="$(PKGPREFIX)/usr/include" \
			PYTHON_MODULES_LIB="$(PKGPREFIX)/usr/lib" \
			PYTHON_XCOMPILE_DEPENDENCIES_PREFIX="$(PKGPREFIX)" \
			CROSS_COMPILE_TARGET=yes \
			CROSS_COMPILE=$(TARGET) \
			MACHDEP=linux2 \
			HOSTARCH=$(TARGET) \
			CFLAGS="$(TARGET_CFLAGS)" \
			LDFLAGS="$(TARGET_LDFLAGS)" \
			LD="$(TARGET)-gcc" \
			HOSTPYTHON=$(HOST_DIR)/bin/python$(PYTHON_VER_MAJOR) \
			HOSTPGEN=$(HOST_DIR)/bin/pgen \
			all DESTDIR=$(PKGPREFIX) \
		; \
		$(MAKE) install DESTDIR=$(PKGPREFIX)
	ln -sf ../../libpython$(PYTHON_VER_MAJOR).so.1.0 $(PKGPREFIX)/$(PYTHON_DIR)/config/libpython$(PYTHON_VER_MAJOR).so; \
	ln -sf $(PKGPREFIX)/$(PYTHON_INCLUDE_DIR) $(TARGET_DIR)/usr/include/python
	rm -r $(PKGPREFIX)/usr/include $(PKGPREFIX)/usr/lib/pkgconfig
	$(REMOVE)/Python-$(PYTHON_VER)
ifneq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), kerneldebug debug normal))
	find $(PKGPREFIX)/ -name '*' -exec $(TARGET)-strip --strip-unneeded {} &>/dev/null \;
endif
	pushd $(PKGPREFIX) && tar --numeric-owner --group=0 --owner=0 -czf $(PKGS_DIR)/$@/data.tar.gz ./* && popd
	touch $(PACKAGES)/python/control/control
	echo Package: python > $(PACKAGES)/python/control/control
	echo Version: $(PYTHON_VER) >> $(PACKAGES)/python/control/control
	echo Section: base/libraries >> $(PACKAGES)/python/control/control
ifeq ($(BOXARCH), mips)
	echo Architecture: $(BOXARCH)el >> $(PACKAGES)/python/control/control 
else
	echo Architecture: $(BOXARCH) >> $(PACKAGES)/python/control/control 
endif
	echo Maintainer: $(MAINTAINER)  >> $(PACKAGES)/python/control/control 
	echo Depends:  >> $(PACKAGES)/python/control/control
	pushd $(PACKAGES)/python/control && chmod +x * && tar --numeric-owner --group=0 --owner=0 -czf $(PKGS_DIR)/$@/control.tar.gz ./* && popd
	pushd $(PKGS_DIR)/$@ && echo 2.0 > debian-binary && ar rv $(PKGS_DIR)/python-$(PYTHON_VER)_$(BOXARCH)_all.ipk ./data.tar.gz ./control.tar.gz ./debian-binary && popd && rm -rf data.tar.gz control.tar.gz debian-binary
	rm -rf $(PACKAGES)/python/control/control
	rm -rf $(PKGPREFIX)
	rm -rf $(PKGS_DIR)/$@
	$(END_BUILD)

#
# aio-grab-ipk
#
aio-grab-ipk: $(D)/bootstrap $(D)/libpng $(D)/libjpeg
	$(START_BUILD)
	rm -rf $(PKGPREFIX)
	install -d $(PKGPREFIX)
	install -d $(PKGS_DIR)
	install -d $(PKGS_DIR)/$@
	set -e; cd $(TOOLS_DIR)/aio-grab-$(BOXARCH); \
		$(CONFIGURE_TOOLS) CPPFLAGS="$(CPPFLAGS) -I$(DRIVER_DIR)/bpamem" \
			--prefix= \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(PKGPREFIX)
ifneq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), kerneldebug debug normal))
	find $(PKGPREFIX)/ -name '*' -exec $(TARGET)-strip --strip-unneeded {} &>/dev/null \;
endif
	pushd $(PKGPREFIX) && tar --numeric-owner --group=0 --owner=0 -czf $(PKGS_DIR)/$@/data.tar.gz ./* && popd
	touch $(PACKAGES)/aio-grab/control/control
	echo Package: aio-grab > $(PACKAGES)/aio-grab/control/control
	echo Section: applications >> $(PACKAGES)/aio-grab/control/control
ifeq ($(BOXARCH), mips)
	echo Architecture: $(BOXARCH)el >> $(PACKAGES)/aio-grab/control/control 
else
	echo Architecture: $(BOXARCH) >> $(PACKAGES)/aio-grab/control/control 
endif
	echo Maintainer: $(MAINTAINER)  >> $(PACKAGES)/aio-grab/control/control 
	echo Depends:  >> $(PACKAGES)/aio-grab/control/control
	pushd $(PACKAGES)/aio-grab/control && chmod +x * && tar --numeric-owner --group=0 --owner=0 -czf $(PKGS_DIR)/$@/control.tar.gz ./* && popd
	pushd $(PKGS_DIR)/$@ && echo 2.0 > debian-binary && ar rv $(PKGS_DIR)/aio-grab_$(BOXARCH)_all.ipk ./data.tar.gz ./control.tar.gz ./debian-binary && popd && rm -rf data.tar.gz control.tar.gz debian-binary
	rm -rf $(PACKAGES)/aio-grab/control/control
	rm -rf $(PKGPREFIX)
	rm -rf $(PKGS_DIR)/$@
	$(END_BUILD)
	
#
# showiframe-ipk
#
showiframe-ipk: $(D)/bootstrap
	$(START_BUILD)
	rm -rf $(PKGPREFIX)
	install -d $(PKGPREFIX)
	install -d $(PKGS_DIR)
	install -d $(PKGS_DIR)/$@
	set -e; cd $(TOOLS_DIR)/showiframe-$(BOXARCH); \
		$(CONFIGURE_TOOLS) \
			--prefix= \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(PKGPREFIX)
ifneq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), kerneldebug debug normal))
	find $(PKGPREFIX)/ -name '*' -exec $(TARGET)-strip --strip-unneeded {} &>/dev/null \;
endif
	pushd $(PKGPREFIX) && tar --numeric-owner --group=0 --owner=0 -czf $(PKGS_DIR)/$@/data.tar.gz ./* && popd
	touch $(PACKAGES)/showiframe/control/control
	echo Package: showiframe > $(PACKAGES)/showiframe/control/control
#	echo Version: $(SHOWIFRAME_VER) >> $(PACKAGES)/showiframe/control/control
	echo Section: applications >> $(PACKAGES)/showiframe/control/control
ifeq ($(BOXARCH), mips)
	echo Architecture: $(BOXARCH)el >> $(PACKAGES)/showiframe/control/control 
else
	echo Architecture: $(BOXARCH) >> $(PACKAGES)/showiframe/control/control 
endif
	echo Maintainer: $(MAINTAINER)  >> $(PACKAGES)/showiframe/control/control 
	echo Depends:  >> $(PACKAGES)/showiframe/control/control
	pushd $(PACKAGES)/showiframe/control && chmod +x * && tar --numeric-owner --group=0 --owner=0 -czf $(PKGS_DIR)/$@/control.tar.gz ./* && popd
	pushd $(PKGS_DIR)/$@ && echo 2.0 > debian-binary && ar rv $(PKGS_DIR)/showiframe_$(BOXARCH)_all.ipk ./data.tar.gz ./control.tar.gz ./debian-binary && popd && rm -rf data.tar.gz control.tar.gz debian-binary
	rm -rf $(PACKAGES)/showiframe/control/control
	rm -rf $(PKGPREFIX)
	rm -rf $(PKGS_DIR)/$@
	$(END_BUILD)
	
#
# all packagrs
#
packages: \
	libupnp-ipk \
	minidlna-ipk \
	fbshot-ipk \
	ofgwrite-ipk \
	xupnpd-ipk \
	graphlcd-ipk \
	lcd4linux-ipk \
	gstreamer-ipk \
	gst_plugins_good-ipk \
	gst_plugins_bad-ipk \
	gst_plugins_ugly-ipk \
	gst_plugins_subsink-ipk \
	gst_plugins_dvbmediasink-ipk \
	ffmpeg-ipk lua-ipk \
	luacurl-ipk \
	luaexpat-ipk \
	luasocket-ipk \
	luafeedparser-ipk \
	luajson-ipk \
	python-ipk \
	aio-grab-ipk \
	showiframe-ipk
		
#
# pkg-clean
#
packages-clean:
	cd $(PKGS_DIR) && rm -rf *
		
