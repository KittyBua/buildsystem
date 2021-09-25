#
# busybox
#
ifeq ($(BUSYBOX_SNAPSHOT), 1)
BUSYBOX_VER = snapshot
BUSYBOX_SOURCE =
BUSYBOX_DEPS =
else
BUSYBOX_VER = 1.32.0
BUSYBOX_SOURCE = busybox-$(BUSYBOX_VER).tar.bz2
BUSYBOX_DEPS = $(ARCHIVE)/$(BUSYBOX_SOURCE)

$(ARCHIVE)/$(BUSYBOX_SOURCE):
	$(DOWNLOAD) https://busybox.net/downloads/$(BUSYBOX_SOURCE)

endif

BUSYBOX = busybox-$(BUSYBOX_VER)

BUSYBOX_PATCH  = busybox-$(BUSYBOX_VER)-nandwrite.patch
BUSYBOX_PATCH += busybox-$(BUSYBOX_VER)-unicode.patch
BUSYBOX_PATCH += busybox-$(BUSYBOX_VER)-extra.patch
BUSYBOX_PATCH += busybox-$(BUSYBOX_VER)-extra2.patch
BUSYBOX_PATCH += busybox-$(BUSYBOX_VER)-flashcp-small-output.patch
BUSYBOX_PATCH += busybox-$(BUSYBOX_VER)-block-telnet-internet.patch

ifeq ($(BUSYBOX_SNAPSHOT), 1)
#BUSYBOX_PATCH += busybox-$(BUSYBOX_VER)-tar-fix.patch
BUSYBOX_PATCH += busybox-$(BUSYBOX_VER)-changed_FreeBSD_fix.patch
BUSYBOX_PATCH += busybox-$(BUSYBOX_VER)-recursive_action-fix.patch
endif

ifeq ($(BOXARCH), $(filter $(BOXARCH), arm mips))
BUSYBOX_CONFIG = busybox-$(BUSYBOX_VER).config_arm
else
BUSYBOX_CONFIG = busybox-$(BUSYBOX_VER).config
endif

$(D)/busybox: $(D)/bootstrap $(BUSYBOX_DEPS) $(PATCHES)/$(BUSYBOX_CONFIG)
	$(START_BUILD)
	$(REMOVE)/$(BUSYBOX)
ifeq ($(BUSYBOX_SNAPSHOT), 1)
	set -e; if [ -d $(ARCHIVE)/busybox.git ]; \
		then cd $(ARCHIVE)/busybox.git; git pull; \
		else cd $(ARCHIVE); git clone git://git.busybox.net/busybox.git busybox.git; \
		fi
	cp -ra $(ARCHIVE)/busybox.git $(BUILD_TMP)/$(BUSYBOX)
else
	$(UNTAR)/$(BUSYBOX_SOURCE)
endif
	$(CHDIR)/$(BUSYBOX); \
		$(call apply_patches, $(BUSYBOX_PATCH)); \
		install -m 0644 $(lastword $^) .config; \
		sed -i -e 's#^CONFIG_PREFIX.*#CONFIG_PREFIX="$(TARGET_DIR)"#' .config; \
		$(BUILDENV) \
		$(MAKE) ARCH=$(BOXARCH) CROSS_COMPILE=$(TARGET)- CFLAGS_EXTRA="$(TARGET_CFLAGS)" busybox; \
		$(MAKE) ARCH=$(BOXARCH) CROSS_COMPILE=$(TARGET)- CFLAGS_EXTRA="$(TARGET_CFLAGS)" CONFIG_PREFIX=$(TARGET_DIR) install-noclobber 
	$(REMOVE)/$(BUSYBOX)
	$(TOUCH)

#
# bash
#
BASH_VER = 5.0
BASH_SOURCE = bash-$(BASH_VER).tar.gz
BASH_PATCH  = $(PATCHES)/bash

$(ARCHIVE)/$(BASH_SOURCE):
	$(DOWNLOAD) http://ftp.gnu.org/gnu/bash/$(BASH_SOURCE)

$(D)/bash: $(D)/bootstrap $(ARCHIVE)/$(BASH_SOURCE)
	$(START_BUILD)
	$(REMOVE)/bash-$(BASH_VER)
	$(UNTAR)/$(BASH_SOURCE)
	$(CHDIR)/bash-$(BASH_VER); \
		$(call apply_patches, $(BASH_PATCH), 0); \
		$(CONFIGURE) \
			--libdir=$(TARGET_LIB_DIR) \
			--includedir=$(TARGET_INCLUDE_DIR) \
			--docdir=$(TARGET_DIR)/.remove \
			--infodir=$(TARGET_DIR)/.remove \
			--mandir=$(TARGET_DIR)/.remove \
			--localedir=$(TARGET_DIR)/.remove/locale \
			--datarootdir=$(TARGET_DIR)/.remove \
		; \
		$(MAKE); \
		$(MAKE) install prefix=$(TARGET_DIR)
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/bash.pc
	$(REMOVE)/bash-$(BASH_VER)
	$(TOUCH)

#
# mtd_utils
#
MTD_UTILS_VER = 1.5.2
MTD_UTILS_SOURCE = mtd-utils-$(MTD_UTILS_VER).tar.bz2

$(ARCHIVE)/$(MTD_UTILS_SOURCE):
	$(DOWNLOAD) ftp://ftp.infradead.org/pub/mtd-utils/$(MTD_UTILS_SOURCE)

$(D)/mtd_utils: $(D)/bootstrap $(D)/zlib $(D)/lzo $(D)/e2fsprogs $(ARCHIVE)/$(MTD_UTILS_SOURCE)
	$(START_BUILD)
	$(REMOVE)/mtd-utils-$(MTD_UTILS_VER)
	$(UNTAR)/$(MTD_UTILS_SOURCE)
	$(CHDIR)/mtd-utils-$(MTD_UTILS_VER); \
		$(BUILDENV) \
		$(MAKE) PREFIX= CC=$(TARGET)-gcc LD=$(TARGET)-ld STRIP=$(TARGET)-strip WITHOUT_XATTR=1 DESTDIR=$(TARGET_DIR); \
		cp -a $(BUILD_TMP)/mtd-utils-$(MTD_UTILS_VER)/mkfs.jffs2 $(TARGET_DIR)/usr/sbin
		cp -a $(BUILD_TMP)/mtd-utils-$(MTD_UTILS_VER)/sumtool $(TARGET_DIR)/usr/sbin
#		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REMOVE)/mtd-utils-$(MTD_UTILS_VER)
	$(TOUCH)

#
# module_init_tools
#
MODULE_INIT_TOOLS_VER = 3.16
MODULE_INIT_TOOLS_SOURCE = module-init-tools-$(MODULE_INIT_TOOLS_VER).tar.bz2
MODULE_INIT_TOOLS_PATCH = module-init-tools-$(MODULE_INIT_TOOLS_VER).patch

$(ARCHIVE)/$(MODULE_INIT_TOOLS_SOURCE):
	$(DOWNLOAD) ftp.be.debian.org/pub/linux/utils/kernel/module-init-tools/$(MODULE_INIT_TOOLS_SOURCE)

$(D)/module_init_tools: $(D)/bootstrap $(D)/lsb $(ARCHIVE)/$(MODULE_INIT_TOOLS_SOURCE)
	$(START_BUILD)
	$(REMOVE)/module-init-tools-$(MODULE_INIT_TOOLS_VER)
	$(UNTAR)/$(MODULE_INIT_TOOLS_SOURCE)
	$(CHDIR)/module-init-tools-$(MODULE_INIT_TOOLS_VER); \
		$(call apply_patches, $(MODULE_INIT_TOOLS_PATCH)); \
		autoreconf -fi $(SILENT_OPT); \
		$(CONFIGURE) \
			--target=$(TARGET) \
			--prefix= \
			--program-suffix="" \
			--mandir=/.remove \
			--docdir=/.remove \
			--disable-builddir \
		; \
		$(MAKE); \
		$(MAKE) install sbin_PROGRAMS="depmod modinfo" bin_PROGRAMS= DESTDIR=$(TARGET_DIR)
	$(call adapted-etc-files, $(MODULE_INIT_TOOLS_ADAPTED_ETC_FILES))
	$(REMOVE)/module-init-tools-$(MODULE_INIT_TOOLS_VER)
	$(TOUCH)

#
# sysvinit
#
SYSVINIT_VER = 2.99
SYSVINIT_SOURCE = sysvinit-$(SYSVINIT_VER).tar.xz
SYSVINIT_PATCH  = sysvinit-$(SYSVINIT_VER)-crypt-lib.patch
SYSVINIT_PATCH += sysvinit-$(SYSVINIT_VER)-change-INIT_FIFO.patch

$(ARCHIVE)/$(SYSVINIT_SOURCE):
	$(DOWNLOAD) https://download.savannah.gnu.org/releases/sysvinit/$(SYSVINIT_SOURCE)

$(D)/sysvinit: $(D)/bootstrap $(ARCHIVE)/$(SYSVINIT_SOURCE)
	$(START_BUILD)
	$(REMOVE)/sysvinit-$(SYSVINIT_VER)
	$(UNTAR)/$(SYSVINIT_SOURCE)
	$(CHDIR)/sysvinit-$(SYSVINIT_VER); \
		$(call apply_patches, $(SYSVINIT_PATCH)); \
		sed -i -e 's/\ sulogin[^ ]*//' -e 's/pidof\.8//' -e '/ln .*pidof/d' \
		-e '/bootlogd/d' -e '/utmpdump/d' -e '/mountpoint/d' -e '/mesg/d' src/Makefile; \
		$(BUILDENV) \
		$(MAKE) SULOGINLIBS=-lcrypt; \
		$(MAKE) install ROOT=$(TARGET_DIR) MANDIR=/.remove
	rm -f $(addprefix $(TARGET_DIR)/sbin/,fstab-decode runlevel telinit)
	rm -f $(addprefix $(TARGET_DIR)/usr/bin/,lastb)
	install -m 644 $(SKEL_ROOT)/etc/inittab $(TARGET_DIR)/etc/inittab
	[ ! -z "$(CUSTOM_INITTAB)" ] && install -m 0755 $(CUSTOM_INITTAB) $(TARGET_DIR)/etc/inittab || true
	$(REMOVE)/sysvinit-$(SYSVINIT_VER)
	$(TOUCH)

#
# opkg
#
$(D)/opkg: $(D)/bootstrap $(D)/host_opkg $(D)/libarchive $(ARCHIVE)/$(OPKG_SOURCE)
	$(START_BUILD)
	$(REMOVE)/opkg-$(OPKG_VER)
	$(UNTAR)/$(OPKG_SOURCE)
	$(CHDIR)/opkg-$(OPKG_VER); \
		$(call apply_patches, $(OPKG_PATCH)); \
		LIBARCHIVE_LIBS="-L$(TARGET_LIB_DIR) -larchive" \
		LIBARCHIVE_CFLAGS="-I$(TARGET_INCLUDE_DIR)" \
		$(CONFIGURE) \
			--prefix=/usr \
			--disable-curl \
			--disable-gpg \
			--mandir=/.remove \
		; \
		$(MAKE) all ; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	install -d -m 0755 $(TARGET_LIB_DIR)/opkg
	install -d -m 0755 $(TARGET_DIR)/etc/opkg
	ln -sf opkg $(TARGET_DIR)/usr/bin/opkg-cl
	$(REWRITE_LIBTOOL)/libopkg.la
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libopkg.pc
	$(REMOVE)/opkg-$(OPKG_VER)
	$(TOUCH)

#
# lsb
#
LSB_MAJOR = 3.2
LSB_MINOR = 20
LSB_VER = $(LSB_MAJOR)-$(LSB_MINOR)
LSB_SOURCE = lsb_$(LSB_VER).tar.gz

$(ARCHIVE)/$(LSB_SOURCE):
	$(DOWNLOAD) https://debian.sdinet.de/etch/sdinet/lsb/$(LSB_SOURCE)

$(D)/lsb: $(D)/bootstrap $(ARCHIVE)/$(LSB_SOURCE)
	$(START_BUILD)
	$(REMOVE)/lsb-$(LSB_MAJOR)
	$(UNTAR)/$(LSB_SOURCE)
	$(CHDIR)/lsb-$(LSB_MAJOR); \
		install -m 0644 init-functions $(TARGET_DIR)/lib/lsb
	$(REMOVE)/lsb-$(LSB_MAJOR)
	$(TOUCH)

#
# portmap
#
PORTMAP_VER = 6.0.0
PORTMAP_SOURCE = portmap_$(PORTMAP_VER).orig.tar.gz
PORTMAP_PATCH = portmap-$(PORTMAP_VER).patch

$(ARCHIVE)/$(PORTMAP_SOURCE):
	$(DOWNLOAD) https://merges.ubuntu.com/p/portmap/$(PORTMAP_SOURCE)

$(ARCHIVE)/portmap_$(PORTMAP_VER)-3.diff.gz:
	$(DOWNLOAD) https://merges.ubuntu.com/p/portmap/portmap_$(PORTMAP_VER)-3.diff.gz

$(D)/portmap: $(D)/bootstrap $(D)/lsb $(ARCHIVE)/$(PORTMAP_SOURCE) $(ARCHIVE)/portmap_$(PORTMAP_VER)-3.diff.gz
	$(START_BUILD)
	$(REMOVE)/portmap-$(PORTMAP_VER)
	$(UNTAR)/$(PORTMAP_SOURCE)
	$(CHDIR)/portmap-$(PORTMAP_VER); \
		gunzip -cd $(lastword $^) | cat > debian.patch; \
		patch -p1 $(SILENT_PATCH) <debian.patch && \
		sed -e 's/### BEGIN INIT INFO/# chkconfig: S 41 10\n### BEGIN INIT INFO/g' -i debian/init.d; \
		$(call apply_patches, $(PORTMAP_PATCH)); \
		$(BUILDENV) $(MAKE) NO_TCP_WRAPPER=1 DAEMON_UID=65534 DAEMON_GID=65535 CC="$(TARGET)-gcc"; \
		install -m 0755 portmap $(TARGET_DIR)/sbin; \
		install -m 0755 pmap_dump $(TARGET_DIR)/sbin; \
		install -m 0755 pmap_set $(TARGET_DIR)/sbin; \
		install -m755 debian/init.d $(TARGET_DIR)/etc/init.d/portmap
	$(REMOVE)/portmap-$(PORTMAP_VER)
	$(TOUCH)

#
# e2fsprogs
#
E2FSPROGS_VER = 1.45.4
E2FSPROGS_SOURCE = e2fsprogs-$(E2FSPROGS_VER).tar.gz
E2FSPROGS_PATCH  = e2fsprogs.patch
E2FSPROGS_PATCH += e2fsprogs-001-exit_0_on_corrected_errors.patch
E2FSPROGS_PATCH += e2fsprogs-002-dont-build-e4defrag.patch
E2FSPROGS_PATCH += e2fsprogs-003-overridable-pc-exec-prefix.patch
E2FSPROGS_PATCH += e2fsprogs-004-Revert-mke2fs-enable-the-metadata_csum-and-64bit-fea.patch
E2FSPROGS_PATCH += e2fsprogs-005-misc-create_inode.c-set-dir-s-mode-correctly.patch
E2FSPROGS_PATCH += e2fsprogs-006-mkdir_p.patch

$(ARCHIVE)/$(E2FSPROGS_SOURCE):
	$(DOWNLOAD) https://sourceforge.net/projects/e2fsprogs/files/e2fsprogs/v$(E2FSPROGS_VER)/$(E2FSPROGS_SOURCE)

$(D)/e2fsprogs: $(D)/bootstrap $(D)/util_linux $(ARCHIVE)/$(E2FSPROGS_SOURCE)
	$(START_BUILD)
	$(REMOVE)/e2fsprogs-$(E2FSPROGS_VER)
	$(UNTAR)/$(E2FSPROGS_SOURCE)
	$(CHDIR)/e2fsprogs-$(E2FSPROGS_VER); \
		$(call apply_patches, $(E2FSPROGS_PATCH)); \
		PATH=$(BUILD_TMP)/e2fsprogs-$(E2FSPROGS_VER):$(PATH) \
		autoreconf -fi $(SILENT_OPT); \
		$(CONFIGURE) LIBS="-luuid -lblkid" \
			--prefix=/usr \
			--libdir=/usr/lib \
			--datarootdir=/.remove \
			--mandir=/.remove \
			--infodir=/.remove \
			--disable-rpath \
			--disable-testio-debug \
			--disable-defrag \
			--disable-nls \
			--disable-jbd-debug \
			--disable-blkid-debug \
			--disable-testio-debug \
			--disable-debugfs \
			--disable-imager \
			--disable-backtrace \
			--disable-mmp \
			--disable-tdb \
			--disable-bmap-stats \
			--disable-fuse2fs \
			--enable-elf-shlibs \
			--enable-fsck \
			--disable-libblkid \
			--disable-libuuid \
			--disable-uuidd \
			--enable-verbose-makecmds \
			--enable-symlink-install \
			--without-libintl-prefix \
			--without-libiconv-prefix \
			--with-root-prefix="" \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/com_err.pc
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/ext2fs.pc
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/e2p.pc
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/ss.pc
	rm -f $(addprefix $(TARGET_DIR)/sbin/,badblocks dumpe2fs e2mmpstatus e2undo logsave)
	rm -f $(addprefix $(TARGET_DIR)/usr/sbin/,filefrag e2freefrag mk_cmds mklost+found uuidd e4crypt)
	rm -f $(addprefix $(TARGET_DIR)/usr/bin/,chattr lsattr uuidgen)
	$(REMOVE)/e2fsprogs-$(E2FSPROGS_VER)
	$(TOUCH)

#
# util_linux
#
UTIL_LINUX_MAJOR = 2.37
UTIL_LINUX_MINOR = 1
UTIL_LINUX_VER = $(UTIL_LINUX_MAJOR).$(UTIL_LINUX_MINOR)
UTIL_LINUX_SOURCE = util-linux-$(UTIL_LINUX_VER).tar.xz

$(ARCHIVE)/$(UTIL_LINUX_SOURCE):
	$(DOWNLOAD) https://www.kernel.org/pub/linux/utils/util-linux/v$(UTIL_LINUX_MAJOR)/$(UTIL_LINUX_SOURCE)

$(D)/util_linux: $(D)/bootstrap $(D)/ncurses $(D)/zlib $(ARCHIVE)/$(UTIL_LINUX_SOURCE)
	$(START_BUILD)
	$(REMOVE)/util-linux-$(UTIL_LINUX_VER)
	$(UNTAR)/$(UTIL_LINUX_SOURCE)
	$(CHDIR)/util-linux-$(UTIL_LINUX_VER); \
		$(CONFIGURE) \
			--prefix=/usr \
			--libdir=/usr/lib \
			--localstatedir=/var/ \
			--datarootdir=/.remove \
			--mandir=/.remove \
			--disable-gtk-doc \
			--enable-line \
			\
			--disable-agetty \
			--disable-bash-completion \
			--disable-bfs \
			--disable-cal \
			--disable-chfn-chsh \
			--disable-chmem \
			--disable-cramfs \
			--disable-eject \
			--disable-fallocate \
			--disable-fdformat \
			--disable-hwclock \
			--disable-kill \
			--disable-last \
			--enable-libblkid \
			--enable-libmount \
			--enable-libsmartcols \
			--enable-libuuid \
			--disable-line \
			--disable-logger \
			--disable-login \
			--disable-login-chown-vcs \
			--disable-login-stat-mail \
			--disable-lslogins \
			--disable-lsmem \
			--disable-makeinstall-chown \
			--disable-makeinstall-setuid \
			--disable-makeinstall-chown \
			--disable-mesg \
			--disable-minix \
			--disable-more \
			--disable-mount \
			--disable-mountpoint \
			--disable-newgrp \
			--disable-nls \
			--disable-nologin \
			--disable-nsenter \
			--disable-partx \
			--disable-pg \
			--disable-pg-bell \
			--disable-pivot_root \
			--disable-pylibmount \
			--disable-raw \
			--disable-rename \
			--disable-rfkill \
			--disable-runuser \
			--disable-rpath \
			--disable-schedutils \
			--disable-setpriv \
			--disable-setterm \
			--disable-su \
			--disable-sulogin \
			--disable-switch_root \
			--disable-tunelp \
			--disable-ul \
			--disable-unshare \
			--disable-use-tty-group \
			--disable-utmpdump \
			--disable-vipw \
			--disable-wall \
			--disable-wdctl \
			--disable-write \
			--disable-zramctl \
			\
			--without-audit \
			--without-python \
			--without-slang \
			--without-systemdsystemunitdir \
			--without-tinfo \
			--without-udev \
			--without-utempter \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REWRITE_LIBTOOL)/libuuid.la
	$(REWRITE_LIBTOOL)/libblkid.la
	$(REWRITE_LIBTOOL)/libmount.la
	$(REWRITE_LIBTOOL)/libsmartcols.la
	$(REWRITE_LIBTOOL)/libfdisk.la
	$(REWRITE_LIBTOOLDEP)/libuuid.la
	$(REWRITE_LIBTOOLDEP)/libblkid.la
	$(REWRITE_LIBTOOLDEP)/libmount.la
	$(REWRITE_LIBTOOLDEP)/libsmartcols.la
	$(REWRITE_LIBTOOLDEP)/libfdisk.la
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/blkid.pc
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/uuid.pc
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/fdisk.pc
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/mount.pc
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/smartcols.pc
	rm -f $(addprefix $(TARGET_DIR)/bin/,findmnt)
	rm -f $(addprefix $(TARGET_DIR)/sbin/,blkdiscard blkzone blockdev cfdisk chcpu ctrlaltdel fdisk findfs fsck fsfreeze fstrim losetup mkfs swaplabel wipefs)
	rm -f $(addprefix $(TARGET_DIR)/usr/bin/,col colcrt colrm column fincore flock getopt ipcmk ipcrm ipcs isosize linux32 linux64 look lscpu lsipc lslocks lsns mcookie namei prlimit renice rev script scriptreplay setarch setsid uname26 uuidgen uuidparse whereis)
	rm -f $(addprefix $(TARGET_DIR)/usr/sbin/,ldattach readprofile rtcwake uuidd)
	$(REMOVE)/util-linux-$(UTIL_LINUX_VER)
	$(TOUCH)

#
# gptfdisk
#
GPTFDISK_VER = 1.0.8
GPTFDISK_SOURCE = gptfdisk-$(GPTFDISK_VER).tar.gz

$(ARCHIVE)/$(GPTFDISK_SOURCE):
	$(DOWNLOAD) https://sourceforge.net/projects/gptfdisk/files/gptfdisk/$(GPTFDISK_VER)/$(GPTFDISK_SOURCE)

$(D)/gptfdisk: $(D)/bootstrap $(D)/e2fsprogs $(D)/ncurses $(D)/libpopt $(ARCHIVE)/$(GPTFDISK_SOURCE)
	$(START_BUILD)
	$(REMOVE)/gptfdisk-$(GPTFDISK_VER)
	$(UNTAR)/$(GPTFDISK_SOURCE)
	$(CHDIR)/gptfdisk-$(GPTFDISK_VER); \
		$(BUILDENV) \
		$(MAKE) sgdisk; \
		install -m755 sgdisk $(TARGET_DIR)/usr/sbin/sgdisk
	$(REMOVE)/gptfdisk-$(GPTFDISK_VER)
	$(TOUCH)

#
# parted
#
PARTED_VER = 3.3
PARTED_SOURCE = parted-$(PARTED_VER).tar.xz
#PARTED_PATCH = parted-$(PARTED_VER)-device-mapper.patch

$(ARCHIVE)/$(PARTED_SOURCE):
	$(DOWNLOAD) https://ftp.gnu.org/gnu/parted/$(PARTED_SOURCE)

$(D)/parted: $(D)/bootstrap $(D)/e2fsprogs $(ARCHIVE)/$(PARTED_SOURCE)
	$(START_BUILD)
	$(REMOVE)/parted-$(PARTED_VER)
	$(UNTAR)/$(PARTED_SOURCE)
	$(CHDIR)/parted-$(PARTED_VER); \
		$(call apply_patches, $(PARTED_PATCH)); \
		autoreconf -fi $(SILENT_OPT); \
		$(CONFIGURE) \
			--target=$(TARGET) \
			--prefix=/usr \
			--mandir=/.remove \
			--infodir=/.remove \
			--without-readline \
			--disable-shared \
			--disable-dynamic-loading \
			--disable-debug \
			--disable-device-mapper \
			--disable-nls \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libparted.pc
	$(REWRITE_LIBTOOL)/libparted.la
	$(REWRITE_LIBTOOL)/libparted-fs-resize.la
	$(REMOVE)/parted-$(PARTED_VER)
	$(TOUCH)

#
# dosfstools
#
DOSFSTOOLS_VER = 4.1
DOSFSTOOLS_SOURCE = dosfstools-$(DOSFSTOOLS_VER).tar.xz

$(ARCHIVE)/$(DOSFSTOOLS_SOURCE):
	$(DOWNLOAD) https://github.com/dosfstools/dosfstools/releases/download/v$(DOSFSTOOLS_VER)/$(DOSFSTOOLS_SOURCE)

DOSFSTOOLS_CFLAGS = $(TARGET_CFLAGS) -D_GNU_SOURCE -fomit-frame-pointer -D_FILE_OFFSET_BITS=64

$(D)/dosfstools: bootstrap $(ARCHIVE)/$(DOSFSTOOLS_SOURCE)
	$(START_BUILD)
	$(REMOVE)/dosfstools-$(DOSFSTOOLS_VER)
	$(UNTAR)/$(DOSFSTOOLS_SOURCE)
	$(CHDIR)/dosfstools-$(DOSFSTOOLS_VER); \
		autoreconf -fi $(SILENT_OPT); \
		$(CONFIGURE) \
			--prefix= \
			--mandir=/.remove \
			--docdir=/.remove \
			--without-udev \
			--enable-compat-symlinks \
			CFLAGS="$(DOSFSTOOLS_CFLAGS)" \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REMOVE)/dosfstools-$(DOSFSTOOLS_VER)
	$(TOUCH)

#
# jfsutils
#
JFSUTILS_VER = 1.1.15
JFSUTILS_SOURCE = jfsutils-$(JFSUTILS_VER).tar.gz
JFSUTILS_PATCH  = jfsutils-$(JFSUTILS_VER).patch
JFSUTILS_PATCH += jfsutils-$(JFSUTILS_VER)-gcc10_fix.patch

$(ARCHIVE)/$(JFSUTILS_SOURCE):
	$(DOWNLOAD) http://jfs.sourceforge.net/project/pub/$(JFSUTILS_SOURCE)

$(D)/jfsutils: $(D)/bootstrap $(D)/e2fsprogs $(ARCHIVE)/$(JFSUTILS_SOURCE)
	$(START_BUILD)
	$(REMOVE)/jfsutils-$(JFSUTILS_VER)
	$(UNTAR)/$(JFSUTILS_SOURCE)
	$(CHDIR)/jfsutils-$(JFSUTILS_VER); \
		$(call apply_patches, $(JFSUTILS_PATCH)); \
		sed "s@<unistd.h>@&\n#include <sys/types.h>@g" -i fscklog/extract.c; \
		sed "s@<unistd.h>@&\n#include <sys/sysmacros.h>@g" -i libfs/devices.c; \
		autoreconf -fi $(SILENT_OPT); \
		$(CONFIGURE) \
			--prefix= \
			--target=$(TARGET) \
			--mandir=/.remove \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	rm -f $(addprefix $(TARGET_DIR)/sbin/,jfs_debugfs jfs_fscklog jfs_logdump)
	$(REMOVE)/jfsutils-$(JFSUTILS_VER)
	$(TOUCH)

#
# f2fs-tools
#

F2FS-TOOLS_VER = 1.14.0
F2FS-TOOLS_SOURCE = f2fs-tools-$(F2FS-TOOLS_VER).tar.gz

$(ARCHIVE)/$(F2FS-TOOLS_SOURCE):
	$(DOWNLOAD) https://git.kernel.org/pub/scm/linux/kernel/git/jaegeuk/f2fs-tools.git/snapshot/$(F2FS-TOOLS_SOURCE)

$(D)/f2fs-tools: $(D)/bootstrap $(D)/util_linux $(ARCHIVE)/$(F2FS-TOOLS_SOURCE)
	$(REMOVE)/f2fs-tools-$(F2FS-TOOLS_VER)
	$(UNTAR)/$(F2FS-TOOLS_SOURCE)
	$(CHDIR)/f2fs-tools-$(F2FS-TOOLS_VER); \
		autoreconf -fi $(SILENT_OPT); \
		ac_cv_file__git=no \
		$(CONFIGURE) \
			--prefix= \
			--mandir=/.remove \
			--without-selinux \
			--without-blkid \
			; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REMOVE)/f2fs-tools-$(F2FS-TOOLS_VER)
	$(TOUCH)

#
# ntfs-3g
#
NTFS_3G_VER = 2017.3.23
NTFS_3G_SOURCE = ntfs-3g_ntfsprogs-$(NTFS_3G_VER).tgz
NTFS_3G_PATCH = ntfs-3g-fuseint-fix-path-mounted-on-musl.patch
NTFS_3G_PATCH += ntfs-3g-sysmacros.patch

$(ARCHIVE)/$(NTFS_3G_SOURCE):
	$(DOWNLOAD) https://tuxera.com/opensource/$(NTFS_3G_SOURCE)

$(D)/ntfs_3g: $(D)/bootstrap $(ARCHIVE)/$(NTFS_3G_SOURCE)
	$(START_BUILD)
	$(REMOVE)/ntfs-3g_ntfsprogs-$(NTFS_3G_VER)
	$(UNTAR)/$(NTFS_3G_SOURCE)
	$(CHDIR)/ntfs-3g_ntfsprogs-$(NTFS_3G_VER); \
		$(call apply_patches, $(NTFS_3G_PATCH)); \
		$(CONFIGURE) \
			--prefix=/usr \
			--exec-prefix=/usr \
			--bindir=/usr/bin \
			--mandir=/.remove \
			--docdir=/.remove \
			--disable-ldconfig \
			--disable-static \
			--disable-ntfsprogs \
			--enable-silent-rules \
			--with-fuse=internal \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libntfs-3g.pc
	$(REWRITE_LIBTOOL)/libntfs-3g.la
	rm -f $(addprefix $(TARGET_DIR)/usr/bin/,lowntfs-3g ntfs-3g.probe)
	rm -f $(addprefix $(TARGET_DIR)/sbin/,mount.lowntfs-3g)
	$(REMOVE)/ntfs-3g_ntfsprogs-$(NTFS_3G_VER)
	$(TOUCH)

#
# mc
#
MC_VER = 4.8.26
MC_SOURCE = mc-$(MC_VER).tar.xz
MC_PATCH = mc-$(MC_VER).patch

$(ARCHIVE)/$(MC_SOURCE):
	$(DOWNLOAD) ftp.midnight-commander.org/$(MC_SOURCE)

$(D)/mc: $(D)/bootstrap $(D)/libglib2 $(D)/ncurses $(ARCHIVE)/$(MC_SOURCE)
	$(START_BUILD)
	$(REMOVE)/mc-$(MC_VER)
	$(UNTAR)/$(MC_SOURCE)
	$(CHDIR)/mc-$(MC_VER); \
		$(call apply_patches, $(MC_PATCH)); \
		autoreconf -fi $(SILENT_OPT); \
		$(CONFIGURE) \
			--prefix=/usr \
			--mandir=/.remove \
			--sysconfdir=/etc \
			--with-homedir=/var/tuxbox/config/mc \
			--without-gpm-mouse \
			--disable-doxygen-doc \
			--disable-doxygen-dot \
			--disable-doxygen-html \
			--enable-charset \
			--disable-nls \
			--with-screen=ncurses \
			--without-x \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	rm -rf $(TARGET_SHARE_DIR)/mc/examples
	find $(TARGET_SHARE_DIR)/mc/skins -type f ! -name default.ini | xargs --no-run-if-empty rm
	$(REMOVE)/mc-$(MC_VER)
	$(TOUCH)

#
# socat
#
SOCAT_VER = 1.7.4.1
SOCAT_SOURCE = socat-$(SOCAT_VER).tar.gz
SOCAT_PATCH = socat-$(SOCAT_VER).patch

$(ARCHIVE)/$(SOCAT_SOURCE):
	$(DOWNLOAD) http://www.dest-unreach.org/socat/download/$(SOCAT_SOURCE)

$(D)/socat: $(D)/bootstrap $(ARCHIVE)/$(SOCAT_SOURCE)
	$(START_BUILD)
	$(REMOVE)/socat-$(SOCAT_VER)
	$(UNTAR)/$(SOCAT_SOURCE)
	$(CHDIR)/socat-$(SOCAT_VER); \
		$(call apply_patches, $(SOCAT_PATCH)); \
		$(CONFIGURE) \
			--target=$(TARGET) \
			--prefix=/usr \
			--disable-ip6 \
			--disable-openssl \
			--disable-tun \
			--disable-libwrap \
			--disable-filan \
			--disable-sycls \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REMOVE)/socat-$(SOCAT_VER)
	$(TOUCH)

#
# nano
#
NANO_VER = 2.2.6
NANO_SOURCE = nano-$(NANO_VER).tar.gz

$(ARCHIVE)/$(NANO_SOURCE):
	$(DOWNLOAD) https://www.nano-editor.org/dist/v2.2/$(NANO_SOURCE)

$(D)/nano: $(D)/bootstrap $(ARCHIVE)/$(NANO_SOURCE)
	$(START_BUILD)
	$(REMOVE)/nano-$(NANO_VER)
	$(UNTAR)/$(NANO_SOURCE)
	$(CHDIR)/nano-$(NANO_VER); \
		$(CONFIGURE) \
			--target=$(TARGET) \
			--prefix=/usr \
			--disable-nls \
			--enable-tiny \
			--enable-color \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REMOVE)/nano-$(NANO_VER)
	$(TOUCH)

#
# rsync
#
RSYNC_VER = 3.1.3
RSYNC_SOURCE = rsync-$(RSYNC_VER).tar.gz

$(ARCHIVE)/$(RSYNC_SOURCE):
	$(DOWNLOAD) https://download.samba.org/pub/rsync/src/$(RSYNC_SOURCE)

$(D)/rsync: $(D)/bootstrap $(ARCHIVE)/$(RSYNC_SOURCE)
	$(START_BUILD)
	$(REMOVE)/rsync-$(RSYNC_VER)
	$(UNTAR)/$(RSYNC_SOURCE)
	$(CHDIR)/rsync-$(RSYNC_VER); \
		$(CONFIGURE) \
			--prefix=/usr \
			--mandir=/.remove \
			--sysconfdir=/etc \
			--disable-debug \
			--disable-locale \
		; \
		$(MAKE) all; \
		$(MAKE) install-all DESTDIR=$(TARGET_DIR)
	$(REMOVE)/rsync-$(RSYNC_VER)
	$(TOUCH)

#
# fuse
#
FUSE_VER = 2.9.9
FUSE_SOURCE = fuse-$(FUSE_VER).tar.gz

$(ARCHIVE)/$(FUSE_SOURCE):
	$(DOWNLOAD) https://github.com/libfuse/libfuse/releases/download/fuse-$(FUSE_VER)/$(FUSE_SOURCE)

$(D)/fuse: $(D)/bootstrap $(ARCHIVE)/$(FUSE_SOURCE)
	$(START_BUILD)
	$(REMOVE)/fuse-$(FUSE_VER)
	$(UNTAR)/$(FUSE_SOURCE)
	$(CHDIR)/fuse-$(FUSE_VER); \
		$(CONFIGURE) \
			CFLAGS="$(TARGET_CFLAGS) -I$(KERNEL_DIR)/arch/sh" \
			--prefix=/usr \
			--exec-prefix=/usr \
			--disable-static \
			--mandir=/.remove \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
		-rm $(TARGET_DIR)/etc/udev/rules.d/99-fuse.rules
		-rmdir $(TARGET_DIR)/etc/udev/rules.d
		-rmdir $(TARGET_DIR)/etc/udev
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/fuse.pc
	$(REWRITE_LIBTOOL)/libfuse.la
	$(REWRITE_LIBTOOL)/libulockmgr.la
	$(REMOVE)/fuse-$(FUSE_VER)
	$(TOUCH)

#
# curlftpfs
#
CURLFTPFS_VER = 0.9.2
CURLFTPFS_SOURCE = curlftpfs-$(CURLFTPFS_VER).tar.gz
CURLFTPFS_PATCH = curlftpfs-$(CURLFTPFS_VER).patch

$(ARCHIVE)/$(CURLFTPFS_SOURCE):
	$(DOWNLOAD) https://sourceforge.net/projects/curlftpfs/files/latest/download/$(CURLFTPFS_SOURCE)

$(D)/curlftpfs: $(D)/bootstrap $(D)/libcurl $(D)/fuse $(D)/libglib2 $(ARCHIVE)/$(CURLFTPFS_SOURCE)
	$(START_BUILD)
	$(REMOVE)/curlftpfs-$(CURLFTPFS_VER)
	$(UNTAR)/$(CURLFTPFS_SOURCE)
	$(CHDIR)/curlftpfs-$(CURLFTPFS_VER); \
		$(call apply_patches, $(CURLFTPFS_PATCH)); \
		export ac_cv_func_malloc_0_nonnull=yes; \
		export ac_cv_func_realloc_0_nonnull=yes; \
		$(CONFIGURE) \
			CFLAGS="$(TARGET_CFLAGS) -I$(KERNEL_DIR)/arch/sh" \
			--target=$(TARGET) \
			--prefix=/usr \
			--mandir=/.remove \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REMOVE)/curlftpfs-$(CURLFTPFS_VER)
	$(TOUCH)

#
# sdparm
#
SDPARM_VER = 1.11
SDPARM_SOURCE = sdparm-$(SDPARM_VER).tgz

$(ARCHIVE)/$(SDPARM_SOURCE):
	$(DOWNLOAD) http://sg.danny.cz/sg/p/$(SDPARM_SOURCE)

$(D)/sdparm: $(D)/bootstrap $(ARCHIVE)/$(SDPARM_SOURCE)
	$(START_BUILD)
	$(REMOVE)/sdparm-$(SDPARM_VER)
	$(UNTAR)/$(SDPARM_SOURCE)
	$(CHDIR)/sdparm-$(SDPARM_VER); \
		$(CONFIGURE) \
			--prefix= \
			--bindir=/sbin \
			--mandir=/.remove \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	rm -f $(addprefix $(TARGET_DIR)/sbin/,sas_disk_blink scsi_ch_swp)
	$(REMOVE)/sdparm-$(SDPARM_VER)
	$(TOUCH)

#
# hddtemp
#
HDDTEMP_VER = 0.3-beta15
HDDTEMP_SOURCE = hddtemp-$(HDDTEMP_VER).tar.bz2

$(ARCHIVE)/$(HDDTEMP_SOURCE):
	$(DOWNLOAD) http://savannah.c3sl.ufpr.br/hddtemp/$(HDDTEMP_SOURCE)

$(D)/hddtemp: $(D)/bootstrap $(ARCHIVE)/$(HDDTEMP_SOURCE)
	$(START_BUILD)
	$(REMOVE)/hddtemp-$(HDDTEMP_VER)
	$(UNTAR)/$(HDDTEMP_SOURCE)
	$(CHDIR)/hddtemp-$(HDDTEMP_VER); \
		$(CONFIGURE) \
			--prefix= \
			--mandir=/.remove \
			--datadir=/.remove \
			--with-db_path=/var/hddtemp.db \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
		install -d $(TARGET_DIR)/var/tuxbox/config
		install -m 644 $(SKEL_ROOT)/release/hddtemp.db $(TARGET_DIR)/var
	$(REMOVE)/hddtemp-$(HDDTEMP_VER)
	$(TOUCH)

#
# hdparm
#
HDPARM_VER = 9.58
HDPARM_SOURCE = hdparm-$(HDPARM_VER).tar.gz

$(ARCHIVE)/$(HDPARM_SOURCE):
	$(DOWNLOAD) https://sourceforge.net/projects/hdparm/files/hdparm/$(HDPARM_SOURCE)

$(D)/hdparm: $(D)/bootstrap $(ARCHIVE)/$(HDPARM_SOURCE)
	$(START_BUILD)
	$(REMOVE)/hdparm-$(HDPARM_VER)
	$(UNTAR)/$(HDPARM_SOURCE)
	$(CHDIR)/hdparm-$(HDPARM_VER); \
		$(BUILDENV) \
		$(MAKE) CROSS=$(TARGET)- all; \
		$(MAKE) install DESTDIR=$(TARGET_DIR) mandir=/.remove
	$(REMOVE)/hdparm-$(HDPARM_VER)
	$(TOUCH)

#
# hdidle
#
HDIDLE_VER = 1.05
HDIDLE_SOURCE = hd-idle-$(HDIDLE_VER).tgz
HDIDLE_PATCH = hd-idle-$(HDIDLE_VER).patch

$(ARCHIVE)/$(HDIDLE_SOURCE):
	$(DOWNLOAD) https://sourceforge.net/projects/hd-idle/files/$(HDIDLE_SOURCE)

$(D)/hdidle: $(D)/bootstrap $(ARCHIVE)/$(HDIDLE_SOURCE)
	$(START_BUILD)
	$(REMOVE)/hd-idle
	$(UNTAR)/$(HDIDLE_SOURCE)
	$(CHDIR)/hd-idle; \
		$(call apply_patches, $(HDIDLE_PATCH)); \
		$(BUILDENV) \
		$(MAKE) CC=$(TARGET)-gcc; \
		$(MAKE) install TARGET_DIR=$(TARGET_DIR) install
	$(REMOVE)/hd-idle
	$(TOUCH)

#
# fbshot
#
FBSHOT_VER = 0.3
FBSHOT_SOURCE = fbshot-$(FBSHOT_VER).tar.gz
FBSHOT_PATCH = fbshot-$(FBSHOT_VER)-$(BOXARCH).patch

$(ARCHIVE)/$(FBSHOT_SOURCE):
	$(DOWNLOAD) http://distro.ibiblio.org/amigolinux/download/Utils/fbshot/$(FBSHOT_SOURCE)

$(D)/fbshot: $(D)/bootstrap $(D)/libpng $(ARCHIVE)/$(FBSHOT_SOURCE)
	$(START_BUILD)
	$(REMOVE)/fbshot-$(FBSHOT_VER)
	$(UNTAR)/$(FBSHOT_SOURCE)
	$(CHDIR)/fbshot-$(FBSHOT_VER); \
		$(call apply_patches, $(FBSHOT_PATCH)); \
		sed -i s~'gcc'~"$(TARGET)-gcc $(TARGET_CFLAGS) $(TARGET_LDFLAGS)"~ Makefile; \
		sed -i 's/strip fbshot/$(TARGET)-strip fbshot/' Makefile; \
		$(MAKE) all; \
		install -D -m 755 fbshot $(TARGET_DIR)/bin/fbshot
	$(REMOVE)/fbshot-$(FBSHOT_VER)
	$(TOUCH)

#
# sysstat
#
SYSSTAT_VER = 12.5.4
SYSSTAT_SOURCE = sysstat-$(SYSSTAT_VER).tar.bz2

$(ARCHIVE)/$(SYSSTAT_SOURCE):
	$(DOWNLOAD) http://pagesperso-orange.fr/sebastien.godard/$(SYSSTAT_SOURCE)

$(D)/sysstat: $(D)/bootstrap $(ARCHIVE)/$(SYSSTAT_SOURCE)
	$(START_BUILD)
	$(REMOVE)/sysstat-$(SYSSTAT_VER)
	$(UNTAR)/$(SYSSTAT_SOURCE)
	$(CHDIR)/sysstat-$(SYSSTAT_VER); \
		$(CONFIGURE) \
			--prefix=/usr \
			--mandir=/.remove \
			--docdir=/.remove \
			--disable-documentation \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(TARGET_DIR) NLS_DIR=/.remove/locale
	$(REMOVE)/sysstat-$(SYSSTAT_VER)
	$(TOUCH)

#
# autofs
#
AUTOFS_VER = 5.1.6
AUTOFS_SOURCE = autofs-$(AUTOFS_VER).tar.gz
#AUTOFS_PATCH = autofs-$(AUTOFS_VER).patch

$(ARCHIVE)/$(AUTOFS_SOURCE):
	$(DOWNLOAD) https://www.kernel.org/pub/linux/daemons/autofs/v5/$(AUTOFS_SOURCE)

$(D)/autofs: $(D)/bootstrap $(D)/e2fsprogs $(D)/libnsl $(ARCHIVE)/$(AUTOFS_SOURCE)
	$(START_BUILD)
	$(REMOVE)/autofs-$(AUTOFS_VER)
	$(UNTAR)/$(AUTOFS_SOURCE)
	$(CHDIR)/autofs-$(AUTOFS_VER); \
		$(call apply_patches, $(AUTOFS_PATCH)); \
		autoconf; \
		$(BUILDENV) \
		$(CONFIGURE) \
			--prefix=/usr \
		; \
		$(MAKE) all; \
		$(MAKE) install INSTALLROOT=$(TARGET_DIR) SUBDIRS="lib daemon modules"
	install -m 755 $(SKEL_ROOT)/etc/init.d/autofs $(TARGET_DIR)/etc/init.d/
	install -m 644 $(SKEL_ROOT)/etc/auto.hotplug $(TARGET_DIR)/etc/
	install -m 644 $(SKEL_ROOT)/etc/auto.master $(TARGET_DIR)/etc/
	install -m 644 $(SKEL_ROOT)/etc/auto.misc $(TARGET_DIR)/etc/
	install -m 644 $(SKEL_ROOT)/etc/auto.network $(TARGET_DIR)/etc/
	ln -sf ../usr/sbin/automount $(TARGET_DIR)/sbin/automount
	$(REMOVE)/autofs-$(AUTOFS_VER)
	$(TOUCH)

#
# shairport
#
$(D)/shairport: $(D)/bootstrap $(D)/openssl $(D)/howl $(D)/alsa_lib
	$(START_BUILD)
	$(REMOVE)/shairport
	set -e; if [ -d $(ARCHIVE)/shairport.git ]; \
		then cd $(ARCHIVE)/shairport.git; git pull; \
		else cd $(ARCHIVE); git clone -b 1.0-dev git://github.com/abrasive/shairport.git shairport.git; \
		fi
	cp -ra $(ARCHIVE)/shairport.git $(BUILD_TMP)/shairport
	$(CHDIR)/shairport; \
		sed -i 's|pkg-config|$$PKG_CONFIG|g' configure; \
		PKG_CONFIG=$(PKG_CONFIG) \
		$(BUILDENV) \
		$(MAKE); \
		$(MAKE) install PREFIX=$(TARGET_DIR)/usr
	$(REMOVE)/shairport
	$(TOUCH)

#
# shairport-sync
#
$(D)/shairport-sync: $(D)/bootstrap $(D)/libdaemon $(D)/libpopt $(D)/libconfig $(D)/openssl $(D)/alsa_lib
	$(START_BUILD)
	$(REMOVE)/shairport-sync
	set -e; if [ -d $(ARCHIVE)/shairport-sync.git ]; \
		then cd $(ARCHIVE)/shairport-sync.git; git pull; \
		else cd $(ARCHIVE); git clone https://github.com/mikebrady/shairport-sync.git shairport-sync.git; \
		fi
	cp -ra $(ARCHIVE)/shairport-sync.git $(BUILD_TMP)/shairport-sync
	$(CHDIR)/shairport-sync; \
		autoreconf -fi $(SILENT_OPT); \
		PKG_CONFIG=$(PKG_CONFIG) \
		$(BUILDENV) \
		$(CONFIGURE) \
			--prefix=/usr \
			--with-alsa \
			--with-ssl=openssl \
			--with-metadata \
			--with-tinysvcmdns \
			--with-pipe \
			--with-stdout \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REMOVE)/shairport-sync
	$(TOUCH)

#
# shairplay
#
SHAIRPLAY_VER = 193138f39adc47108e4091753ea6db8d15ae289a
SHAIRPLAY_SOURCE = shairplay-git-$(SHAIRPLAY_VER).tar.bz2
SHAIRPLAY_URL = https://github.com/juhovh/shairplay.git
SHAIRPLAY_PATCH = shairplay-howl.diff

$(ARCHIVE)/$(SHAIRPLAY_SOURCE):
	$(HELPERS_DIR)/get-git-archive.sh $(SHAIRPLAY_URL) $(SHAIRPLAY_VER) $(notdir $@) $(ARCHIVE)

$(D)/shairplay: libao $(D)/howl $(ARCHIVE)/$(SHAIRPLAY_SOURCE)
	$(START_BUILD)
	$(REMOVE)/shairplay-$(SHAIRPLAY_VER)
	$(UNTAR)/$(SHAIRPLAY_SOURCE)
	$(CHDIR)/shairplay-git-$(SHAIRPLAY_VER); \
		$(call apply_patches, $(SHAIRPLAY_PATCH)); \
		for A in src/test/example.c src/test/main.c src/shairplay.c ; do sed -i "s#airport.key#/usr/share/shairplay/airport.key#" $$A ; done && \
		autoreconf -fi $(SILENT_OPT); \
		PKG_CONFIG=$(PKG_CONFIG) \
		$(BUILDENV) \
		$(CONFIGURE) \
			--enable-shared \
			--disable-static \
			--prefix=/usr \
		; \
		$(MAKE) install DESTDIR=$(TARGET_DIR); \
		install -d $(TARGET_SHARE_DIR)/shairplay ; \
		install -m 644 airport.key $(TARGET_SHARE_DIR)/shairplay && \
	$(REWRITE_LIBTOOL)/libshairplay.la
	$(REMOVE)/shairplay-git-$(SHAIRPLAY_VER)
	$(TOUCH)

#
# dbus
#
DBUS_VER = 1.12.6
DBUS_SOURCE = dbus-$(DBUS_VER).tar.gz

$(ARCHIVE)/$(DBUS_SOURCE):
	$(DOWNLOAD) https://dbus.freedesktop.org/releases/dbus/$(DBUS_SOURCE)

$(D)/dbus: $(D)/bootstrap $(D)/expat $(ARCHIVE)/$(DBUS_SOURCE)
	$(START_BUILD)
	$(REMOVE)/dbus-$(DBUS_VER)
	$(UNTAR)/$(DBUS_SOURCE)
	$(CHDIR)/dbus-$(DBUS_VER); \
		$(CONFIGURE) \
		CFLAGS="$(TARGET_CFLAGS) -Wno-cast-align" \
			--without-x \
			--prefix=/usr \
			--docdir=/.remove \
			--sysconfdir=/etc \
			--localstatedir=/var \
			--with-console-auth-dir=/run/console/ \
			--without-systemdsystemunitdir \
			--disable-systemd \
			--disable-static \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/dbus-1.pc
	$(REWRITE_LIBTOOL)/libdbus-1.la
	rm -f $(addprefix $(TARGET_DIR)/usr/bin/,dbus-cleanup-sockets dbus-daemon dbus-launch dbus-monitor)
	$(REMOVE)/dbus-$(DBUS_VER)
	$(TOUCH)

#
# avahi
#
AVAHI_VER = 0.7
AVAHI_SOURCE = avahi-$(AVAHI_VER).tar.gz

$(ARCHIVE)/$(AVAHI_SOURCE):
	$(DOWNLOAD) https://github.com/lathiat/avahi/releases/download/v$(AVAHI_VER)/$(AVAHI_SOURCE)

$(D)/avahi: $(D)/bootstrap $(D)/expat $(D)/libdaemon $(D)/dbus $(ARCHIVE)/$(AVAHI_SOURCE)
	$(START_BUILD)
	$(REMOVE)/avahi-$(AVAHI_VER)
	$(UNTAR)/$(AVAHI_SOURCE)
	$(CHDIR)/avahi-$(AVAHI_VER); \
		$(CONFIGURE) \
			--prefix=/usr \
			--target=$(TARGET) \
			--sysconfdir=/etc \
			--localstatedir=/var \
			--with-distro=none \
			--with-avahi-user=nobody \
			--with-avahi-group=nogroup \
			--with-autoipd-user=nobody \
			--with-autoipd-group=nogroup \
			--with-xml=expat \
			--enable-libdaemon \
			--disable-nls \
			--disable-glib \
			--disable-gobject \
			--disable-qt3 \
			--disable-qt4 \
			--disable-gtk \
			--disable-gtk3 \
			--disable-dbm \
			--disable-gdbm \
			--disable-python \
			--disable-pygtk \
			--disable-python-dbus \
			--disable-mono \
			--disable-monodoc \
			--disable-autoipd \
			--disable-doxygen-doc \
			--disable-doxygen-dot \
			--disable-doxygen-man \
			--disable-doxygen-rtf \
			--disable-doxygen-xml \
			--disable-doxygen-chm \
			--disable-doxygen-chi \
			--disable-doxygen-html \
			--disable-doxygen-ps \
			--disable-doxygen-pdf \
			--disable-core-docs \
			--disable-manpages \
			--disable-xmltoman \
			--disable-tests \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/avahi-core.pc
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/avahi-client.pc
	$(REWRITE_LIBTOOL)/libavahi-common.la
	$(REWRITE_LIBTOOL)/libavahi-core.la
	$(REWRITE_LIBTOOL)/libavahi-client.la
	$(REMOVE)/avahi-$(AVAHI_VER)
	$(TOUCH)

#
# wget
#
WGET_VER = 1.21.1
WGET_SOURCE = wget-$(WGET_VER).tar.gz
WGET_PATCH = wget-$(WGET_VER).patch

$(ARCHIVE)/$(WGET_SOURCE):
	$(DOWNLOAD) https://ftp.gnu.org/gnu/wget/$(WGET_SOURCE)

$(D)/wget: $(D)/bootstrap $(D)/openssl $(ARCHIVE)/$(WGET_SOURCE)
	$(START_BUILD)
	$(REMOVE)/wget-$(WGET_VER)
	$(UNTAR)/$(WGET_SOURCE)
	$(CHDIR)/wget-$(WGET_VER); \
		$(call apply_patches, $(WGET_PATCH)); \
		$(CONFIGURE) \
			--prefix=/usr \
			--mandir=/.remove \
			--infodir=/.remove \
			--with-openssl \
			--with-ssl=openssl \
			--with-libssl-prefix=$(TARGET_DIR) \
			--disable-ipv6 \
			--disable-debug \
			--disable-nls \
			--disable-opie \
			--disable-digest \
			--disable-rpath \
			--disable-iri \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REMOVE)/wget-$(WGET_VER)
	$(TOUCH)

#
# coreutils
#
COREUTILS_VER = 8.23
COREUTILS_SOURCE = coreutils-$(COREUTILS_VER).tar.xz
COREUTILS_PATCH = coreutils-$(COREUTILS_VER).patch

$(ARCHIVE)/$(COREUTILS_SOURCE):
	$(DOWNLOAD) https://ftp.gnu.org/gnu/coreutils/$(COREUTILS_SOURCE)

$(D)/coreutils: $(D)/bootstrap $(D)/openssl $(ARCHIVE)/$(COREUTILS_SOURCE)
	$(START_BUILD)
	$(REMOVE)/coreutils-$(COREUTILS_VER)
	$(UNTAR)/$(COREUTILS_SOURCE)
	$(CHDIR)/coreutils-$(COREUTILS_VER); \
		$(call apply_patches, $(COREUTILS_PATCH)); \
		export fu_cv_sys_stat_statfs2_bsize=yes; \
		$(CONFIGURE) \
			--prefix=/usr \
			--bindir=/bin \
			--mandir=/.remove \
			--infodir=/.remove \
			--localedir=/.remove/locale \
			--enable-largefile \
			--enable-silent-rules \
			--disable-xattr \
			--disable-libcap \
			--disable-acl \
			--without-gmp \
			--without-selinux \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REMOVE)/coreutils-$(COREUTILS_VER)
	$(TOUCH)

#
# smartmontools
#
SMARTMONTOOLS_VER = 7.2
SMARTMONTOOLS_SOURCE = smartmontools-$(SMARTMONTOOLS_VER).tar.gz

$(ARCHIVE)/$(SMARTMONTOOLS_SOURCE):
	$(DOWNLOAD) https://sourceforge.net/projects/smartmontools/files/smartmontools/$(SMARTMONTOOLS_VER)/$(SMARTMONTOOLS_SOURCE)

$(D)/smartmontools: $(D)/bootstrap $(ARCHIVE)/$(SMARTMONTOOLS_SOURCE)
	$(START_BUILD)
	$(REMOVE)/smartmontools-$(SMARTMONTOOLS_VER)
	$(UNTAR)/$(SMARTMONTOOLS_SOURCE)
	$(CHDIR)/smartmontools-$(SMARTMONTOOLS_VER); \
		$(CONFIGURE) \
			--prefix=/usr \
		; \
		$(MAKE); \
		$(MAKE) install prefix=$(TARGET_DIR)/usr mandir=./remove
	$(REMOVE)/smartmontools-$(SMARTMONTOOLS_VER)
	$(TOUCH)

#
# nfs_utils
#
NFS_UTILS_VER = 2.5.3
NFS_UTILS_SOURCE = nfs-utils-$(NFS_UTILS_VER).tar.bz2
NFS_UTILS_PATCH = nfs-utils-$(NFS_UTILS_VER).patch

$(ARCHIVE)/$(NFS_UTILS_SOURCE):
	$(DOWNLOAD) https://sourceforge.net/projects/nfs/files/nfs-utils/$(NFS_UTILS_VER)/$(NFS_UTILS_SOURCE)

$(D)/nfs_utils: $(D)/bootstrap $(D)/e2fsprogs $(ARCHIVE)/$(NFS_UTILS_SOURCE)
	$(START_BUILD)
	$(REMOVE)/nfs-utils-$(NFS_UTILS_VER)
	$(UNTAR)/$(NFS_UTILS_SOURCE)
	$(CHDIR)/nfs-utils-$(NFS_UTILS_VER); \
		$(call apply_patches, $(NFS_UTILS_PATCH)); \
		$(CONFIGURE) \
			CC_FOR_BUILD=$(TARGET)-gcc \
			--prefix=/usr \
			--exec-prefix=/usr \
			--mandir=/.remove \
			--disable-gss \
			--enable-ipv6=no \
			--disable-tirpc \
			--disable-nfsv4 \
			--without-tcp-wrappers \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	install -m 755 $(SKEL_ROOT)/etc/init.d/nfs-common $(TARGET_DIR)/etc/init.d/
	install -m 755 $(SKEL_ROOT)/etc/init.d/nfs-kernel-server $(TARGET_DIR)/etc/init.d/
	install -m 644 $(SKEL_ROOT)/etc/exports $(TARGET_DIR)/etc/
	rm -f $(addprefix $(TARGET_DIR)/sbin/,mount.nfs mount.nfs4 umount.nfs umount.nfs4 osd_login)
	rm -f $(addprefix $(TARGET_DIR)/usr/sbin/,mountstats nfsiostat sm-notify start-statd)
	$(REMOVE)/nfs-utils-$(NFS_UTILS_VER)
	$(TOUCH)

#
# libevent
#
LIBEVENT_VER = 2.0.21-stable
LIBEVENT_SOURCE = libevent-$(LIBEVENT_VER).tar.gz

$(ARCHIVE)/$(LIBEVENT_SOURCE):
	$(DOWNLOAD) https://github.com/downloads/libevent/libevent/$(LIBEVENT_SOURCE)

$(D)/libevent: $(D)/bootstrap $(ARCHIVE)/$(LIBEVENT_SOURCE)
	$(START_BUILD)
	$(REMOVE)/libevent-$(LIBEVENT_VER)
	$(UNTAR)/$(LIBEVENT_SOURCE)
	$(CHDIR)/libevent-$(LIBEVENT_VER);\
		$(CONFIGURE) \
			--prefix=/usr \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libevent.pc
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libevent_openssl.pc
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libevent_pthreads.pc
	$(REWRITE_LIBTOOL)/libevent_core.la
	$(REWRITE_LIBTOOL)/libevent_extra.la
	$(REWRITE_LIBTOOL)/libevent.la
	$(REWRITE_LIBTOOL)/libevent_openssl.la
	$(REWRITE_LIBTOOL)/libevent_pthreads.la
	$(REMOVE)/libevent-$(LIBEVENT_VER)
	$(TOUCH)

#
# libnfsidmap
#
LIBNFSIDMAP_VER = 0.25
LIBNFSIDMAP_SOURCE = libnfsidmap-$(LIBNFSIDMAP_VER).tar.gz

$(ARCHIVE)/$(LIBNFSIDMAP_SOURCE):
	$(DOWNLOAD) http://www.citi.umich.edu/projects/nfsv4/linux/libnfsidmap/$(LIBNFSIDMAP_SOURCE)

$(D)/libnfsidmap: $(D)/bootstrap $(ARCHIVE)/$(LIBNFSIDMAP_SOURCE)
	$(START_BUILD)
	$(REMOVE)/libnfsidmap-$(LIBNFSIDMAP_VER)
	$(UNTAR)/$(LIBNFSIDMAP_SOURCE)
	$(CHDIR)/libnfsidmap-$(LIBNFSIDMAP_VER);\
		$(CONFIGURE) \
		ac_cv_func_malloc_0_nonnull=yes \
			--prefix=/usr \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libnfsidmap.pc
	$(REWRITE_LIBTOOL)/libnfsidmap.la
	$(REMOVE)/libnfsidmap-$(LIBNFSIDMAP_VER)
	$(TOUCH)

#
# vsftpd
#
VSFTPD_VER = 3.0.3
VSFTPD_SOURCE = vsftpd-$(VSFTPD_VER).tar.gz
VSFTPD_PATCH = vsftpd-$(VSFTPD_VER).patch
VSFTPD_PATCH += vsftpd-$(VSFTPD_VER)-find_libs.patch

$(ARCHIVE)/$(VSFTPD_SOURCE):
	$(DOWNLOAD) https://security.appspot.com/downloads/$(VSFTPD_SOURCE)

$(D)/vsftpd: $(D)/bootstrap $(D)/openssl $(ARCHIVE)/$(VSFTPD_SOURCE)
	$(START_BUILD)
	$(REMOVE)/vsftpd-$(VSFTPD_VER)
	$(UNTAR)/$(VSFTPD_SOURCE)
	$(CHDIR)/vsftpd-$(VSFTPD_VER); \
		$(call apply_patches, $(VSFTPD_PATCH)); \
		$(MAKE) clean; \
		$(MAKE) $(BUILDENV); \
		$(MAKE) install PREFIX=$(TARGET_DIR)
	install -m 755 $(SKEL_ROOT)/etc/init.d/vsftpd $(TARGET_DIR)/etc/init.d/
	install -m 644 $(SKEL_ROOT)/etc/vsftpd.conf $(TARGET_DIR)/etc/
	$(REMOVE)/vsftpd-$(VSFTPD_VER)
	$(TOUCH)

#
# procps_ng
#
PROCPS_NG_VER = 3.3.16
PROCPS_NG_SOURCE = procps-ng-$(PROCPS_NG_VER).tar.xz

$(ARCHIVE)/$(PROCPS_NG_SOURCE):
	$(DOWNLOAD) http://sourceforge.net/projects/procps-ng/files/Production/$(PROCPS_NG_SOURCE)

$(D)/procps_ng: $(D)/bootstrap $(D)/ncurses $(ARCHIVE)/$(PROCPS_NG_SOURCE)
	$(START_BUILD)
	$(REMOVE)/procps-ng-$(PROCPS_NG_VER)
	$(UNTAR)/$(PROCPS_NG_SOURCE)
	cd $(BUILD_TMP)/procps-ng-$(PROCPS_NG_VER); \
		export ac_cv_func_malloc_0_nonnull=yes; \
		export ac_cv_func_realloc_0_nonnull=yes; \
		$(CONFIGURE) \
			--target=$(TARGET) \
			--prefix= \
		; \
		$(MAKE); \
		install -D -m 755 top/.libs/top $(TARGET_DIR)/bin/top; \
		install -D -m 755 ps/.libs/pscommand $(TARGET_DIR)/bin/ps; \
		cp -a proc/.libs/libprocps.so* $(TARGET_LIB_DIR)
	$(REMOVE)/procps-ng-$(PROCPS_NG_VER)
	$(TOUCH)

#
# htop
#
HTOP_VER = 2.2.0
HTOP_SOURCE = htop-$(HTOP_VER).tar.gz
HTOP_PATCH = htop-$(HTOP_VER).patch

$(ARCHIVE)/$(HTOP_SOURCE):
	$(DOWNLOAD) http://hisham.hm/htop/releases/$(HTOP_VER)/$(HTOP_SOURCE)

$(D)/htop: $(D)/bootstrap $(D)/ncurses $(ARCHIVE)/$(HTOP_SOURCE)
	$(START_BUILD)
	$(REMOVE)/htop-$(HTOP_VER)
	$(UNTAR)/$(HTOP_SOURCE)
	$(CHDIR)/htop-$(HTOP_VER); \
		$(call apply_patches, $(HTOP_PATCH)); \
		autoreconf -fi $(SILENT_OPT); \
		$(CONFIGURE) \
			--prefix=/usr \
			--mandir=/.remove \
			--sysconfdir=/etc \
			--disable-unicode \
			ac_cv_func_malloc_0_nonnull=yes \
			ac_cv_func_realloc_0_nonnull=yes \
			ac_cv_file__proc_stat=yes \
			ac_cv_file__proc_meminfo=yes \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	rm -rf $(addprefix $(TARGET_SHARE_DIR)/,pixmaps applications)
	$(REMOVE)/htop-$(HTOP_VER)
	$(TOUCH)

#
# ethtool
#
ETHTOOL_VER = 5.13
ETHTOOL_SOURCE = ethtool-$(ETHTOOL_VER).tar.xz
ETHTOOL_PATCH = ethtool-$(ETHTOOL_VER).patch

$(ARCHIVE)/$(ETHTOOL_SOURCE):
	$(DOWNLOAD) https://www.kernel.org/pub/software/network/ethtool/$(ETHTOOL_SOURCE)

$(D)/ethtool: $(D)/bootstrap $(ARCHIVE)/$(ETHTOOL_SOURCE)
	$(START_BUILD)
	$(REMOVE)/ethtool-$(ETHTOOL_VER)
	$(UNTAR)/$(ETHTOOL_SOURCE)
	$(CHDIR)/ethtool-$(ETHTOOL_VER); \
		$(call apply_patches, $(ETHTOOL_PATCH)); \
		$(CONFIGURE) \
			--prefix=/usr \
			--mandir=/.remove \
			--disable-pretty-dump \
			--disable-netlink \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REMOVE)/ethtool-$(ETHTOOL_VER)
	$(TOUCH)

#
# samba
#
SAMBA_VER = 3.6.25
SAMBA_SOURCE = samba-$(SAMBA_VER).tar.gz
SAMBA_PATCH = $(PATCHES)/samba

ifeq ($(SAMBA_SMALL_INSTALL), 1)
SAMBA_INSTALL = \
		$(MAKE) $(MAKE_OPTS) \
			installservers installbin installdat installmodules \
			SBIN_PROGS="bin/samba_multicall" \
			BIN_PROGS="bin/testparm" \
			DESTDIR=$(TARGET_DIR) prefix=./. ;
else
SAMBA_INSTALL = \
		$(MAKE) $(MAKE_OPTS) \
			installservers installbin installscripts installdat installmodules \
			SBIN_PROGS="bin/samba_multicall" \
			DESTDIR=$(TARGET_DIR) prefix=./. ;
endif

$(ARCHIVE)/$(SAMBA_SOURCE):
	$(DOWNLOAD) https://ftp.samba.org/pub/samba/stable/$(SAMBA_SOURCE)

$(D)/samba: $(D)/bootstrap $(ARCHIVE)/$(SAMBA_SOURCE)
	$(START_BUILD)
	$(REMOVE)/samba-$(SAMBA_VER)
	$(UNTAR)/$(SAMBA_SOURCE)
	$(CHDIR)/samba-$(SAMBA_VER); \
		$(call apply_patches, $(SAMBA_PATCH)); \
		cd source3; \
		./autogen.sh $(SILENT_OPT); \
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
		libreplace_cv_HAVE_SECURE_MKSTEMP=yes \
		samba_cv_HAVE_WRFILE_KEYTAB=no \
		samba_cv_USE_SETREUID=yes \
		samba_cv_USE_SETRESUID=yes \
		samba_cv_have_setreuid=yes \
		samba_cv_have_setresuid=yes \
		samba_cv_optimize_out_funcation_calls=no \
		ac_cv_header_zlib_h=no \
		samba_cv_zlib_1_2_3=no \
		ac_cv_path_PYTHON="" \
		ac_cv_path_PYTHON_CONFIG="" \
		libreplace_cv_HAVE_GETADDRINFO=no \
		libreplace_cv_READDIR_NEEDED=no \
		./configure $(SILENT_OPT) \
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
		$(SAMBA_INSTALL)
			ln -sf samba_multicall $(TARGET_DIR)/usr/sbin/nmbd
			ln -sf samba_multicall $(TARGET_DIR)/usr/sbin/smbd
			ln -sf samba_multicall $(TARGET_DIR)/usr/sbin/smbpasswd
	install -m 755 $(SKEL_ROOT)/etc/init.d/samba $(TARGET_DIR)/etc/init.d/
	install -m 644 $(SKEL_ROOT)/etc/samba/smb.conf $(TARGET_DIR)/etc/samba/
	rm -rf $(TARGET_LIB_DIR)/pdb
	rm -rf $(TARGET_LIB_DIR)/perfcount
	rm -rf $(TARGET_LIB_DIR)/nss_info
	rm -rf $(TARGET_LIB_DIR)/gpext
	$(REMOVE)/samba-$(SAMBA_VER)
	$(TOUCH)

#
# ntp
#
NTP_VER = 4.2.8p15
NTP_SOURCE = ntp-$(NTP_VER).tar.gz
NTP_PATCH = ntp-$(NTP_VER).patch

$(ARCHIVE)/$(NTP_SOURCE):
	$(DOWNLOAD) https://www.eecis.udel.edu/~ntp/ntp_spool/ntp4/ntp-4.2/$(NTP_SOURCE)

$(D)/ntp: $(D)/bootstrap $(ARCHIVE)/$(NTP_SOURCE)
	$(START_BUILD)
	$(REMOVE)/ntp-$(NTP_VER)
	$(UNTAR)/$(NTP_SOURCE)
	$(CHDIR)/ntp-$(NTP_VER); \
		$(call apply_patches, $(NTP_PATCH)); \
		$(CONFIGURE) \
			--target=$(TARGET) \
			--prefix=/usr \
			--mandir=/.remove \
			--infodir=/.remove \
			--docdir=/.remove \
			--localedir=/.remove \
			--htmldir=/.remove \
			--disable-tick \
			--disable-tickadj \
			--with-yielding-select=yes \
			--without-ntpsnmpd \
			--disable-debugging \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REMOVE)/ntp-$(NTP_VER)
	$(TOUCH)

#
# wireless_tools
#
WIRELESS_TOOLS_VER = 29
WIRELESS_TOOLS_SOURCE = wireless_tools.$(WIRELESS_TOOLS_VER).tar.gz
WIRELESS_TOOLS_PATCH = wireless-tools.$(WIRELESS_TOOLS_VER).patch

$(ARCHIVE)/$(WIRELESS_TOOLS_SOURCE):
	$(DOWNLOAD) http://www.hpl.hp.com/personal/Jean_Tourrilhes/Linux/$(WIRELESS_TOOLS_SOURCE)

$(D)/wireless_tools: $(D)/bootstrap $(ARCHIVE)/$(WIRELESS_TOOLS_SOURCE)
	$(START_BUILD)
	$(REMOVE)/wireless_tools.$(WIRELESS_TOOLS_VER)
	$(UNTAR)/$(WIRELESS_TOOLS_SOURCE)
	$(CHDIR)/wireless_tools.$(WIRELESS_TOOLS_VER); \
		$(call apply_patches, $(WIRELESS_TOOLS_PATCH)); \
		$(MAKE) CC="$(TARGET)-gcc" CFLAGS="$(TARGET_CFLAGS) -I."; \
		$(MAKE) install PREFIX=$(TARGET_DIR)/usr INSTALL_MAN=$(TARGET_DIR)/.remove
	$(REMOVE)/wireless_tools.$(WIRELESS_TOOLS_VER)
	$(TOUCH)

#
# libnl
#
LIBNL_VER = 3.2.25
LIBNL_SOURCE = libnl-$(LIBNL_VER).tar.gz

$(ARCHIVE)/$(LIBNL_SOURCE):
	$(DOWNLOAD) https://www.infradead.org/~tgr/libnl/files/$(LIBNL_SOURCE)

$(D)/libnl: $(D)/bootstrap $(D)/openssl $(ARCHIVE)/$(LIBNL_SOURCE)
	$(START_BUILD)
	$(REMOVE)/libnl-$(LIBNL_VER)
	$(UNTAR)/$(LIBNL_SOURCE)
	$(CHDIR)/libnl-$(LIBNL_VER); \
		$(CONFIGURE) \
			--target=$(TARGET) \
			--prefix=/usr \
			--bindir=/.remove \
			--mandir=/.remove \
			--infodir=/.remove \
		make $(SILENT_OPT); \
		make install $(SILENT_OPT) DESTDIR=$(TARGET_DIR)
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libnl-3.0.pc
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libnl-cli-3.0.pc
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libnl-genl-3.0.pc
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libnl-nf-3.0.pc
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libnl-route-3.0.pc
	$(REWRITE_LIBTOOL)/libnl-3.la
	$(REWRITE_LIBTOOL)/libnl-cli-3.la
	$(REWRITE_LIBTOOL)/libnl-genl-3.la
	$(REWRITE_LIBTOOL)/libnl-idiag-3.la
	$(REWRITE_LIBTOOL)/libnl-nf-3.la
	$(REWRITE_LIBTOOL)/libnl-route-3.la
	$(REMOVE)/libnl-$(LIBNL_VER)
	$(TOUCH)

#
# wpa_supplicant
#
WPA_SUPPLICANT_VER = 0.7.3
WPA_SUPPLICANT_SOURCE = wpa_supplicant-$(WPA_SUPPLICANT_VER).tar.gz

$(ARCHIVE)/$(WPA_SUPPLICANT_SOURCE):
	$(DOWNLOAD) https://w1.fi/releases/$(WPA_SUPPLICANT_SOURCE)

$(D)/wpa_supplicant: $(D)/bootstrap $(D)/openssl $(D)/wireless_tools $(ARCHIVE)/$(WPA_SUPPLICANT_SOURCE)
	$(START_BUILD)
	$(REMOVE)/wpa_supplicant-$(WPA_SUPPLICANT_VER)
	$(UNTAR)/$(WPA_SUPPLICANT_SOURCE)
	$(CHDIR)/wpa_supplicant-$(WPA_SUPPLICANT_VER)/wpa_supplicant; \
		cp -f defconfig .config; \
		sed -i 's/#CONFIG_DRIVER_RALINK=y/CONFIG_DRIVER_RALINK=y/' .config; \
		sed -i 's/#CONFIG_IEEE80211W=y/CONFIG_IEEE80211W=y/' .config; \
		sed -i 's/#CONFIG_OS=unix/CONFIG_OS=unix/' .config; \
		sed -i 's/#CONFIG_TLS=openssl/CONFIG_TLS=openssl/' .config; \
		sed -i 's/#CONFIG_IEEE80211N=y/CONFIG_IEEE80211N=y/' .config; \
		sed -i 's/#CONFIG_INTERWORKING=y/CONFIG_INTERWORKING=y/' .config; \
		export CFLAGS="-pipe -Os -Wall -g0 -I$(TARGET_INCLUDE_DIR)"; \
		export CPPFLAGS="-I$(TARGET_INCLUDE_DIR)"; \
		export LIBS="-L$(TARGET_LIB_DIR) -Wl,-rpath-link,$(TARGET_LIB_DIR)"; \
		export LDFLAGS="-L$(TARGET_LIB_DIR)"; \
		export DESTDIR=$(TARGET_DIR); \
		$(MAKE) CC=$(TARGET)-gcc; \
		$(MAKE) install BINDIR=/usr/sbin DESTDIR=$(TARGET_DIR)
	$(REMOVE)/wpa_supplicant-$(WPA_SUPPLICANT_VER)
	$(TOUCH)

#
# dvbsnoop
#
DVBSNOOP_VER = d3f134b
DVBSNOOP_SOURCE = dvbsnoop-git-$(DVBSNOOP_VER).tar.bz2
DVBSNOOP_URL = https://github.com/Duckbox-Developers/dvbsnoop.git

$(ARCHIVE)/$(DVBSNOOP_SOURCE):
	$(HELPERS_DIR)/get-git-archive.sh $(DVBSNOOP_URL) $(DVBSNOOP_VER) $(notdir $@) $(ARCHIVE)

$(D)/dvbsnoop: $(D)/bootstrap $(D)/kernel $(ARCHIVE)/$(DVBSNOOP_SOURCE)
	$(START_BUILD)
	$(REMOVE)/dvbsnoop-git-$(DVBSNOOP_VER)
	$(UNTAR)/$(DVBSNOOP_SOURCE)
	$(CHDIR)/dvbsnoop-git-$(DVBSNOOP_VER); \
		$(CONFIGURE) \
			--enable-silent-rules \
			--prefix=/usr \
			--mandir=/.remove \
			$(DVBSNOOP_CONF_OPTS) \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REMOVE)/dvbsnoop-git-$(DVBSNOOP_VER)
	$(TOUCH)

#
# udpxy
#
UDPXY_VER = 612d227
UDPXY_SOURCE = udpxy-git-$(UDPXY_VER).tar.bz2
UDPXY_URL = https://github.com/pcherenkov/udpxy.git
UDPXY_PATCH = udpxy-git-$(UDPXY_VER).patch

$(ARCHIVE)/$(UDPXY_SOURCE):
	$(HELPERS_DIR)/get-git-archive.sh $(UDPXY_URL) $(UDPXY_VER) $(notdir $@) $(ARCHIVE)

$(D)/udpxy: $(D)/bootstrap $(ARCHIVE)/$(UDPXY_SOURCE)
	$(START_BUILD)
	$(REMOVE)/udpxy-git-$(UDPXY_VER)
	$(UNTAR)/$(UDPXY_SOURCE)
	$(CHDIR)/udpxy-git-$(UDPXY_VER)/chipmunk; \
		$(call apply_patches, $(UDPXY_PATCH)); \
		$(BUILDENV) \
		$(MAKE) CC=$(TARGET)-gcc CCKIND=gcc; \
		$(MAKE) install INSTALLROOT=$(TARGET_DIR)/usr MANPAGE_DIR=$(TARGET_DIR)/.remove
	$(REMOVE)/udpxy-git-$(UDPXY_VER)
	$(TOUCH)

#
# openvpn
#
OPENVPN_VER = 2.5.3
OPENVPN_SOURCE = openvpn-$(OPENVPN_VER).tar.xz

$(ARCHIVE)/$(OPENVPN_SOURCE):
	$(DOWNLOAD) http://swupdate.openvpn.org/community/releases/$(OPENVPN_SOURCE) || \
	$(DOWNLOAD) http://build.openvpn.net/downloads/releases/$(OPENVPN_SOURCE)

$(D)/openvpn: $(D)/bootstrap $(D)/openssl $(D)/lzo $(ARCHIVE)/$(OPENVPN_SOURCE)
	$(START_BUILD)
	$(REMOVE)/openvpn-$(OPENVPN_VER)
	$(UNTAR)/$(OPENVPN_SOURCE)
	$(CHDIR)/openvpn-$(OPENVPN_VER); \
		$(CONFIGURE) \
			--target=$(TARGET) \
			--prefix=/usr \
			--mandir=/.remove \
			--docdir=/.remove \
			--disable-lz4 \
			--disable-selinux \
			--disable-systemd \
			--disable-plugins \
			--disable-debug \
			--disable-pkcs11 \
			--enable-small \
			NETSTAT="/bin/netstat" \
			IFCONFIG="/sbin/ifconfig" \
			IPROUTE="/sbin/ip" \
			ROUTE="/sbin/route" \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	install -m 755 $(SKEL_ROOT)/etc/init.d/openvpn $(TARGET_DIR)/etc/init.d/
	install -d $(TARGET_DIR)/etc/openvpn
	$(REMOVE)/openvpn-$(OPENVPN_VER)
	$(TOUCH)

#
# vpnc
#
VPNC_VER = 0.5.3r550-2jnpr1
VPNC_DIR = vpnc-$(VPNC_VER)
VPNC_SOURCE = vpnc-$(VPNC_VER).tar.gz
VPNC_URL = https://github.com/ndpgroup/vpnc/archive

VPNC_PATCH = \
	vpnc-fix-build.patch \
	vpnc-nomanual.patch \
	vpnc-susv3-legacy.patch \
	vpnc-conf.patch

VPNC_CPPFLAGS = -DVERSION=\\\"$(VPNC_VER)\\\"

$(ARCHIVE)/$(VPNC_SOURCE):
	$(DOWNLOAD) $(VPNC_URL)/$(VPNC_VER).tar.gz -O $(@)

$(D)/vpnc: $(D)/bootstrap $(D)/openssl $(D)/lzo $(D)/libgcrypt $(ARCHIVE)/$(VPNC_SOURCE)
	$(START_BUILD)
	$(REMOVE)/vpnc-$(VPNC_VER)
	$(UNTAR)/$(VPNC_SOURCE)
	$(CHDIR)/vpnc-$(VPNC_VER); \
		$(call apply_patches, $(VPNC_PATCH)); \
		$(BUILDENV) \
		$(MAKE) \
			CPPFLAGS="$(CPPFLAGS) $(VPNC_CPPFLAGS)"; \
		$(MAKE) \
			CPPFLAGS="$(CPPFLAGS) $(VPNC_CPPFLAGS)" \
			install-strip DESTDIR=$(TARGET_DIR) \
			PREFIX=/usr \
			MANDIR=$(TARGET_DIR)/.remove \
			DOCDIR=$(TARGET_DIR)/.remove
	$(REMOVE)/vpnc-$(VPNC_VER)
	$(TOUCH)

#
# openssh
#
OPENSSH_VER = 8.6p1
OPENSSH_SOURCE = openssh-$(OPENSSH_VER).tar.gz

$(ARCHIVE)/$(OPENSSH_SOURCE):
	$(DOWNLOAD) https://artfiles.org/openbsd/OpenSSH/portable/$(OPENSSH_SOURCE)

$(D)/openssh: $(D)/bootstrap $(D)/zlib $(D)/openssl $(ARCHIVE)/$(OPENSSH_SOURCE)
	$(START_BUILD)
	$(REMOVE)/openssh-$(OPENSSH_VER)
	$(UNTAR)/$(OPENSSH_SOURCE)
	$(CHDIR)/openssh-$(OPENSSH_VER); \
		CC=$(TARGET)-gcc; \
		./configure $(SILENT_OPT) \
			$(CONFIGURE_OPTS) \
			--prefix=/usr \
			--mandir=/.remove \
			--sysconfdir=/etc/ssh \
			--libexecdir=/sbin \
			--with-privsep-path=/var/empty \
			--with-cppflags="-pipe -Os -I$(TARGET_INCLUDE_DIR)" \
			--with-ldflags=-"L$(TARGET_LIB_DIR)" \
		; \
		$(MAKE); \
		$(MAKE) install-nokeys DESTDIR=$(TARGET_DIR)
	install -m 755 $(BUILD_TMP)/openssh-$(OPENSSH_VER)/opensshd.init $(TARGET_DIR)/etc/init.d/openssh
	sed -i 's/^#PermitRootLogin prohibit-password/PermitRootLogin yes/' $(TARGET_DIR)/etc/ssh/sshd_config
	$(REMOVE)/openssh-$(OPENSSH_VER)
	$(TOUCH)

#
# dropbear
#
DROPBEAR_VER = 2018.76
DROPBEAR_SOURCE = dropbear-$(DROPBEAR_VER).tar.bz2

$(ARCHIVE)/$(DROPBEAR_SOURCE):
	$(DOWNLOAD) http://matt.ucc.asn.au/dropbear/releases/$(DROPBEAR_SOURCE)

$(D)/dropbear: $(D)/bootstrap $(D)/zlib $(ARCHIVE)/$(DROPBEAR_SOURCE)
	$(START_BUILD)
	$(REMOVE)/dropbear-$(DROPBEAR_VER)
	$(UNTAR)/$(DROPBEAR_SOURCE)
	$(CHDIR)/dropbear-$(DROPBEAR_VER); \
		$(CONFIGURE) \
			--prefix=/usr \
			--mandir=/.remove \
			--disable-pututxline \
			--disable-wtmp \
			--disable-wtmpx \
			--disable-loginfunc \
			--disable-pam \
		; \
		sed -i 's|^\(#define DROPBEAR_SMALL_CODE\).*|\1 0|' default_options.h; \
		$(MAKE) PROGRAMS="dropbear dbclient dropbearkey scp" SCPPROGRESS=1; \
		$(MAKE) PROGRAMS="dropbear dbclient dropbearkey scp" install DESTDIR=$(TARGET_DIR)
	install -m 755 $(SKEL_ROOT)/etc/init.d/dropbear $(TARGET_DIR)/etc/init.d/
	install -d -m 0755 $(TARGET_DIR)/etc/dropbear
	$(REMOVE)/dropbear-$(DROPBEAR_VER)
	$(TOUCH)

#
# dropbearmulti
#
DROPBEARMULTI_VER = 846d38f
#DROPBEARMULTI_VER = a8d6dac
DROPBEARMULTI_SOURCE = dropbearmulti-git-$(DROPBEARMULTI_VER).tar.bz2
DROPBEARMULTI_URL = https://github.com/mkj/dropbear.git

$(ARCHIVE)/$(DROPBEARMULTI_SOURCE):
	$(HELPERS_DIR)/get-git-archive.sh $(DROPBEARMULTI_URL) $(DROPBEARMULTI_VER) $(notdir $@) $(ARCHIVE)

$(D)/dropbearmulti: $(D)/bootstrap $(ARCHIVE)/$(DROPBEARMULTI_SOURCE)
	$(START_BUILD)
	$(REMOVE)/dropbearmulti-git-$(DROPBEARMULTI_VER)
	$(UNTAR)/$(DROPBEARMULTI_SOURCE)
	$(CHDIR)/dropbearmulti-git-$(DROPBEARMULTI_VER); \
		$(BUILDENV) \
		autoreconf -fi $(SILENT_OPT); \
		$(CONFIGURE) \
			--prefix=/usr \
			--disable-syslog \
			--disable-lastlog \
			--infodir=/.remove \
			--localedir=/.remove/locale \
			--mandir=/.remove \
			--docdir=/.remove \
			--htmldir=/.remove \
			--dvidir=/.remove \
			--pdfdir=/.remove \
			--psdir=/.remove \
			--disable-shadow \
			--disable-zlib \
			--disable-utmp \
			--disable-utmpx \
			--disable-wtmp \
			--disable-wtmpx \
			--disable-loginfunc \
			--disable-pututline \
			--disable-pututxline \
		; \
		$(MAKE) PROGRAMS="dropbear scp dropbearkey" MULTI=1; \
		$(MAKE) PROGRAMS="dropbear scp dropbearkey" MULTI=1 install DESTDIR=$(TARGET_DIR)
	cd $(TARGET_DIR)/usr/bin && ln -sf /usr/bin/dropbearmulti dropbear
	install -m 755 $(SKEL_ROOT)/etc/init.d/dropbear $(TARGET_DIR)/etc/init.d/
	install -d -m 0755 $(TARGET_DIR)/etc/dropbear
	$(REMOVE)/dropbearmulti-git-$(DROPBEARMULTI_VER)
	$(TOUCH)

#
# usb_modeswitch_data
#
USB_MODESWITCH_DATA_VER = 20160112
USB_MODESWITCH_DATA_SOURCE = usb-modeswitch-data-$(USB_MODESWITCH_DATA_VER).tar.bz2
USB_MODESWITCH_DATA_PATCH = usb-modeswitch-data-$(USB_MODESWITCH_DATA_VER).patch

$(ARCHIVE)/$(USB_MODESWITCH_DATA_SOURCE):
	$(DOWNLOAD) http://www.draisberghof.de/usb_modeswitch/$(USB_MODESWITCH_DATA_SOURCE)

$(D)/usb_modeswitch_data: $(D)/bootstrap $(ARCHIVE)/$(USB_MODESWITCH_DATA_SOURCE)
	$(START_BUILD)
	$(REMOVE)/usb-modeswitch-data-$(USB_MODESWITCH_DATA_VER)
	$(UNTAR)/$(USB_MODESWITCH_DATA_SOURCE)
	$(CHDIR)/usb-modeswitch-data-$(USB_MODESWITCH_DATA_VER); \
		$(call apply_patches, $(USB_MODESWITCH_DATA_PATCH)); \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REMOVE)/usb-modeswitch-data-$(USB_MODESWITCH_DATA_VER)
	$(TOUCH)

#
# usb_modeswitch
#
USB_MODESWITCH_VER = 2.3.0
USB_MODESWITCH_SOURCE = usb-modeswitch-$(USB_MODESWITCH_VER).tar.bz2
USB_MODESWITCH_PATCH = usb-modeswitch-$(USB_MODESWITCH_VER).patch

$(ARCHIVE)/$(USB_MODESWITCH_SOURCE):
	$(DOWNLOAD) http://www.draisberghof.de/usb_modeswitch/$(USB_MODESWITCH_SOURCE)

$(D)/usb_modeswitch: $(D)/bootstrap $(D)/libusb $(D)/usb_modeswitch_data $(ARCHIVE)/$(USB_MODESWITCH_SOURCE)
	$(START_BUILD)
	$(REMOVE)/usb-modeswitch-$(USB_MODESWITCH_VER)
	$(UNTAR)/$(USB_MODESWITCH_SOURCE)
	$(CHDIR)/usb-modeswitch-$(USB_MODESWITCH_VER); \
		$(call apply_patches, $(USB_MODESWITCH_PATCH)); \
		sed -i -e "s/= gcc/= $(TARGET)-gcc/" -e "s/-l usb/-lusb -lusb-1.0 -lpthread -lrt/" -e "s/install -D -s/install -D --strip-program=$(TARGET)-strip -s/" Makefile; \
		sed -i -e "s/@CC@/$(TARGET)-gcc/g" jim/Makefile.in; \
		$(BUILDENV) $(MAKE) DESTDIR=$(TARGET_DIR); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REMOVE)/usb-modeswitch-$(USB_MODESWITCH_VER)
	$(TOUCH)

#
# dvb-apps
#
DVB_APPS_PATCH = dvb-apps.patch

$(D)/dvb-apps: $(D)/bootstrap $(ARCHIVE)/$(DVB_APPS_SOURCE)
	$(START_BUILD)
	$(REMOVE)/dvb-apps
	set -e; if [ -d $(ARCHIVE)/dvb-apps.git ]; \
		then cd $(ARCHIVE)/dvb-apps.git; git pull; \
		else cd $(ARCHIVE); git clone https://github.com/openpli-arm/dvb-apps.git dvb-apps.git; \
		fi
	cp -ra $(ARCHIVE)/dvb-apps.git $(BUILD_TMP)/dvb-apps
	$(CHDIR)/dvb-apps; \
		$(call apply_patches,$(DVB_APPS_PATCH)); \
		$(BUILDENV) \
		$(BUILDENV) $(MAKE) DESTDIR=$(TARGET_DIR); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REMOVE)/dvb-apps
	$(TOUCH)

#
# minisatip
#
MINISATIP_PATCH = minisatip.patch

$(D)/minisatip: $(D)/bootstrap $(D)/openssl $(D)/libdvbcsa $(D)/dvb-apps $(ARCHIVE)/$(MINISATIP_SOURCE)
	$(START_BUILD)
	$(REMOVE)/minisatip
	set -e; if [ -d $(ARCHIVE)/minisatip.git ]; \
		then cd $(ARCHIVE)/minisatip.git; git pull; \
		else cd $(ARCHIVE); git clone https://github.com/catalinii/minisatip.git minisatip.git; \
		fi
	cp -ra $(ARCHIVE)/minisatip.git $(BUILD_TMP)/minisatip
	$(CHDIR)/minisatip; \
		$(call apply_patches,$(MINISATIP_PATCH)); \
		$(BUILDENV) \
		export CFLAGS="-pipe -Os -Wall -g0 -I$(TARGET_DIR)/usr/include"; \
		export CPPFLAGS="-I$(TARGET_DIR)/usr/include"; \
		export LDFLAGS="-L$(TARGET_DIR)/usr/lib"; \
		./configure \
			--host=$(TARGET) \
			--build=$(BUILD) \
			--enable-enigma \
			--enable-static \
		; \
		$(MAKE); \
	install -m 755 $(BUILD_TMP)/minisatip/minisatip $(TARGET_DIR)/usr/bin
	install -d $(TARGET_DIR)/usr/share/minisatip
	cp -a $(BUILD_TMP)/minisatip/html $(TARGET_DIR)/usr/share/minisatip
	$(REMOVE)/minisatip
	$(TOUCH)

#
# ofgwrite
#
OFGWRITE_PATCH = ofgwrite.patch

$(D)/ofgwrite: $(D)/bootstrap $(ARCHIVE)/$(OFGWRITE_SOURCE)
	$(START_BUILD)
	$(REMOVE)/ofgwrite-max
	set -e; if [ -d $(ARCHIVE)/ofgwrite-max.git ]; \
		then cd $(ARCHIVE)/ofgwrite-max.git; git pull; \
		else cd $(ARCHIVE); git clone https://github.com/MaxWiesel/ofgwrite-max.git ofgwrite-max.git; \
		fi
	cp -ra $(ARCHIVE)/ofgwrite-max.git $(BUILD_TMP)/ofgwrite-max
	$(CHDIR)/ofgwrite-max; \
		$(call apply_patches,$(OFGWRITE_PATCH)); \
		$(BUILDENV) \
		$(MAKE); \
	install -m 755 $(BUILD_TMP)/ofgwrite-max/ofgwrite_bin $(TARGET_DIR)/usr/bin
	install -m 755 $(BUILD_TMP)/ofgwrite-max/ofgwrite_caller $(TARGET_DIR)/usr/bin
	install -m 755 $(BUILD_TMP)/ofgwrite-max/ofgwrite $(TARGET_DIR)/usr/bin
	$(REMOVE)/ofgwrite-max
	$(TOUCH)

#
# Astra (Advanced Streamer) SlonikMod
#
$(D)/astra-sm: $(D)/bootstrap $(D)/openssl
	$(START_BUILD)
	$(REMOVE)/astra-sm
	set -e; if [ -d $(ARCHIVE)/astra-sm.git ]; \
		then cd $(ARCHIVE)/astra-sm.git; git pull; \
		else cd $(ARCHIVE); git clone https://gitlab.com/crazycat69/astra-sm.git $(ARCHIVE)/astra-sm.git; \
		fi
	cp -ra $(ARCHIVE)/astra-sm.git $(BUILD_TMP)/astra-sm
	$(CHDIR)/astra-sm; \
		$(BUILDENV) \
		autoreconf -fi $(SILENT_OPT); \
		sed -i 's:(CFLAGS):(CFLAGS_FOR_BUILD):' tools/Makefile.am; \
		$(CONFIGURE) \
			--build=$(BUILD) \
			--host=$(TARGET) \
			--prefix=/usr \
		; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REMOVE)/astra-sm
	$(TOUCH)

#
# 
#
IOZONE_VER = 482
IOZONE_SOURCE = iozone3_$(IOZONE_VER).tar
IOZONE_PATCH =

$(ARCHIVE)/$(IOZONE_SOURCE):
	$(DOWNLOAD) http://www.iozone.org/src/current/$(IOZONE_SOURCE)

$(D)/iozone3: $(D)/bootstrap $(ARCHIVE)/$(IOZONE_SOURCE)
	$(START_BUILD)
	$(REMOVE)/iozone3_$(IOZONE_VER)
	$(UNTAR)/$(IOZONE_SOURCE)
	$(CHDIR)/iozone3_$(IOZONE_VER); \
		$(call apply_patches, $(IOZONE_PATCH)); \
		sed -i -e "s/= gcc/= $(TARGET)-gcc/" src/current/makefile; \
		sed -i -e "s/= cc/= $(TARGET)-cc/" src/current/makefile; \
		cd src/current; \
		$(BUILDENV); \
		$(MAKE) linux-arm
		install -m 755 $(BUILD_TMP)/iozone3_$(IOZONE_VER)/src/current/iozone $(TARGET_DIR)/usr/bin
	$(REMOVE)/iozone3_$(IOZONE_VER)
	$(TOUCH)

#
# Mupen64Plus
#
MUPEN64CORE_VER = ef15526
MUPEN64CORE_SOURCE = mupen64core-git-$(MUPEN64CORE_VER).tar.bz2
MUPEN64CORE_URL = https://github.com/mupen64plus/mupen64plus-core.git

$(ARCHIVE)/$(MUPEN64CORE_SOURCE):
	$(HELPERS_DIR)/get-git-archive.sh $(MUPEN64CORE_URL) $(MUPEN64CORE_VER) $(notdir $@) $(ARCHIVE)

$(D)/mupen64core: $(D)/bootstrap $(ARCHIVE)/$(MUPEN64CORE_SOURCE) $(D)/libsdl2 $(D)/libpng $(D)/freetype $(D)/zlib
	$(START_BUILD)
	$(REMOVE)/mupen64core-git-$(MUPEN64CORE_VER)
	$(UNTAR)/$(MUPEN64CORE_SOURCE)
	$(CHDIR)/mupen64core-git-$(MUPEN64CORE_VER); \
		$(BUILDENV) \
		cd projects/unix/ && $(MAKE) \
			CPU=ARM \
			CROSS_COMPILE=$(TARGET)- \
			PKG_CONFIG=$(PKG_CONFIG) \
			NO_ASM=1 \
			SDL_CONFIG=$(TARGET_DIR)/usr/bin/sdl2-config \
			USE_GLES=1 \
			PREFIX=/usr \
			DESTDIR=$(TARGET_DIR) \
			all install; \
	$(REMOVE)/mupen64core-git-$(MUPEN64CORE_VER)
	$(TOUCH)

MUPEN64CMD_VER = 5926250
MUPEN64CMD_SOURCE = mupen64cmd-git-$(MUPEN64CMD_VER).tar.bz2
MUPEN64CMD_URL = https://github.com/mupen64plus/mupen64plus-ui-console.git

$(ARCHIVE)/$(MUPEN64CMD_SOURCE):
	$(HELPERS_DIR)/get-git-archive.sh $(MUPEN64CMD_URL) $(MUPEN64CMD_VER) $(notdir $@) $(ARCHIVE)

$(D)/mupen64cmd: $(D)/bootstrap $(ARCHIVE)/$(MUPEN64CMD_SOURCE) $(D)/mupen64core
	$(START_BUILD)
	$(REMOVE)/mupen64cmd-git-$(MUPEN64CMD_VER)
	$(UNTAR)/$(MUPEN64CMD_SOURCE)
	$(CHDIR)/mupen64cmd-git-$(MUPEN64CMD_VER); \
		$(BUILDENV) \
		cd projects/unix/ && $(MAKE) \
			CPU=ARM \
			CROSS_COMPILE=$(TARGET)- \
			PKG_CONFIG=$(PKG_CONFIG) \
			NO_ASM=1 \
			SDL_CONFIG=$(TARGET_DIR)/usr/bin/sdl2-config \
			USE_GLES=1 \
			PREFIX=/usr \
			DESTDIR=$(TARGET_DIR) \
			APIDIR=$(TARGET_INCLUDE_DIR)/mupen64plus \
			MANDIR=/.remove \
			APPSDIR=/.remove \
			ICONSDIR=/.remove \
			all install; \
	$(REMOVE)/mupen64cmd-git-$(MUPEN64CMD_VER)
	$(TOUCH)

MUPEN64VID_VER = 7f10448
MUPEN64VID_SOURCE = mupen64vid-git-$(MUPEN64VID_VER).tar.bz2
MUPEN64VID_URL = https://github.com/mupen64plus/mupen64plus-video-rice.git

$(ARCHIVE)/$(MUPEN64VID_SOURCE):
	$(HELPERS_DIR)/get-git-archive.sh $(MUPEN64VID_URL) $(MUPEN64VID_VER) $(notdir $@) $(ARCHIVE)

$(D)/mupen64vid: $(D)/bootstrap $(ARCHIVE)/$(MUPEN64VID_SOURCE) $(D)/mupen64core
	$(START_BUILD)
	$(REMOVE)/mupen64vid-git-$(MUPEN64VID_VER)
	$(UNTAR)/$(MUPEN64VID_SOURCE)
	$(CHDIR)/mupen64vid-git-$(MUPEN64VID_VER); \
		$(BUILDENV) \
		cd projects/unix/ && $(MAKE) \
			CPU=ARM \
			CROSS_COMPILE=$(TARGET)- \
			PKG_CONFIG=$(PKG_CONFIG) \
			NO_ASM=1 \
			SDL_CONFIG=$(TARGET_DIR)/usr/bin/sdl2-config \
			USE_GLES=1 \
			PREFIX=/usr \
			DESTDIR=$(TARGET_DIR) \
			APIDIR=$(TARGET_INCLUDE_DIR)/mupen64plus \
			MANDIR=/.remove \
			APPSDIR=/.remove \
			ICONSDIR=/.remove \
			all install; \
	$(REMOVE)/mupen64vid-git-$(MUPEN64VID_VER)
	$(TOUCH)

MUPEN64AUD_VER = 732722c
MUPEN64AUD_SOURCE = mupen64aud-git-$(MUPEN64AUD_VER).tar.bz2
MUPEN64AUD_URL = https://github.com/mupen64plus/mupen64plus-audio-sdl.git

$(ARCHIVE)/$(MUPEN64AUD_SOURCE):
	$(HELPERS_DIR)/get-git-archive.sh $(MUPEN64AUD_URL) $(MUPEN64AUD_VER) $(notdir $@) $(ARCHIVE)

$(D)/mupen64aud: $(D)/bootstrap $(ARCHIVE)/$(MUPEN64AUD_SOURCE) $(D)/mupen64core
	$(START_BUILD)
	$(REMOVE)/mupen64aud-git-$(MUPEN64AUD_VER)
	$(UNTAR)/$(MUPEN64AUD_SOURCE)
	$(CHDIR)/mupen64aud-git-$(MUPEN64AUD_VER); \
		$(BUILDENV) \
		cd projects/unix/ && $(MAKE) \
			CPU=ARM \
			CROSS_COMPILE=$(TARGET)- \
			PKG_CONFIG=$(PKG_CONFIG) \
			SDL_CONFIG=$(TARGET_DIR)/usr/bin/sdl2-config \
			NO_SPEEX=1 \
			NO_OSS=1 \
			NO_SRC=1 \
			PREFIX=/usr \
			DESTDIR=$(TARGET_DIR) \
			APIDIR=$(TARGET_INCLUDE_DIR)/mupen64plus \
			MANDIR=/.remove \
			APPSDIR=/.remove \
			ICONSDIR=/.remove \
			all install; \
	$(REMOVE)/mupen64aud-git-$(MUPEN64AUD_VER)
	$(TOUCH)

MUPEN64INP_VER = f5c3995
MUPEN64INP_SOURCE = mupen64inp-git-$(MUPEN64INP_VER).tar.bz2
MUPEN64INP_URL = https://github.com/mupen64plus/mupen64plus-input-sdl.git

$(ARCHIVE)/$(MUPEN64INP_SOURCE):
	$(HELPERS_DIR)/get-git-archive.sh $(MUPEN64INP_URL) $(MUPEN64INP_VER) $(notdir $@) $(ARCHIVE)

$(D)/mupen64inp: $(D)/bootstrap $(ARCHIVE)/$(MUPEN64INP_SOURCE) $(D)/mupen64core
	$(START_BUILD)
	$(REMOVE)/mupen64inp-git-$(MUPEN64INP_VER)
	$(UNTAR)/$(MUPEN64INP_SOURCE)
	$(CHDIR)/mupen64inp-git-$(MUPEN64INP_VER); \
		$(BUILDENV) \
		cd projects/unix/ && $(MAKE) \
			CPU=ARM \
			CROSS_COMPILE=$(TARGET)- \
			PKG_CONFIG=$(PKG_CONFIG) \
			NO_ASM=1 \
			SDL_CONFIG=$(TARGET_DIR)/usr/bin/sdl2-config \
			USE_GLES=1 \
			PREFIX=/usr \
			DESTDIR=$(TARGET_DIR) \
			APIDIR=$(TARGET_INCLUDE_DIR)/mupen64plus \
			MANDIR=/.remove \
			APPSDIR=/.remove \
			ICONSDIR=/.remove \
			all install; \
	$(REMOVE)/mupen64inp-git-$(MUPEN64INP_VER)
	$(TOUCH)

$(D)/mupen64: $(D)/mupen64core $(D)/mupen64vid $(D)/mupen64aud $(D)/mupen64inp $(D)/mupen64cmd
	$(TOUCH)

#
# libzen
#
LIBZEN_VER = 0.4.38
LIBZEN_SOURCE = libzen_$(LIBZEN_VER).tar.bz2

$(ARCHIVE)/$(LIBZEN_SOURCE):
	$(DOWNLOAD) https://mediaarea.net/download/source/libzen/$(LIBZEN_VER)/$(LIBZEN_SOURCE)

$(D)/libzen: bootstrap $(D)/zlib $(ARCHIVE)/$(LIBZEN_SOURCE)
	$(START_BUILD)
	$(REMOVE)/ZenLib
	$(UNTAR)/$(LIBZEN_SOURCE)
	$(CHDIR)/ZenLib/Project/GNU/Library; \
		autoreconf -fi $(SILENT_OPT); \
		$(CONFIGURE) \
			--prefix=/usr \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libzen.pc
	$(REWRITE_LIBTOOL)/libzen.la
	$(REWRITE_LIBTOOLDEP)/libzen.la
	$(REMOVE)/ZenLib
	$(TOUCH)

#
# libmediainfo
#
LIBMEDIAINFO_VER = 20.08
LIBMEDIAINFO_SOURCE = libmediainfo_$(LIBMEDIAINFO_VER).tar.bz2

$(ARCHIVE)/$(LIBMEDIAINFO_SOURCE):
	$(DOWNLOAD) https://mediaarea.net/download/source/libmediainfo/$(LIBMEDIAINFO_VER)/$(LIBMEDIAINFO_SOURCE)

$(D)/libmediainfo: bootstrap $(D)/zlib $(D)/libzen $(ARCHIVE)/$(LIBMEDIAINFO_SOURCE)
	$(START_BUILD)
	$(REMOVE)/MediaInfoLib
	$(UNTAR)/$(LIBMEDIAINFO_SOURCE)
	$(CHDIR)/MediaInfoLib/Project/GNU/Library; \
		autoreconf -fi $(SILENT_OPT); \
		$(CONFIGURE) \
			--prefix=/usr \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libmediainfo.pc
	$(REWRITE_LIBTOOL)/libmediainfo.la
	$(REWRITE_LIBTOOLDEP)/libmediainfo.la
	$(REMOVE)/MediaInfoLib
	$(TOUCH)

#
# mediainfo
#
MEDIAINFO_VER = 20.08
MEDIAINFO_SOURCE = mediainfo_$(MEDIAINFO_VER).tar.bz2

$(ARCHIVE)/$(MEDIAINFO_SOURCE):
	$(DOWNLOAD) https://mediaarea.net/download/source/mediainfo/$(MEDIAINFO_VER)/$(MEDIAINFO_SOURCE)

$(D)/mediainfo: bootstrap $(D)/zlib $(D)/libzen $(D)/libmediainfo $(ARCHIVE)/$(MEDIAINFO_SOURCE)
	$(START_BUILD)
	$(REMOVE)/MediaInfo
	$(UNTAR)/$(MEDIAINFO_SOURCE)
	$(CHDIR)/MediaInfo/Project/GNU/CLI; \
		autoreconf -fi $(SILENT_OPT); \
		$(CONFIGURE) \
			--prefix=/usr \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REMOVE)/MediaInfo
	$(TOUCH)
