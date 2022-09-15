#
# KERNEL
#
KERNEL_VER             = 4.4.35
KERNEL_DATE            = 20200508
KERNEL_TYPE            = h9combo
KERNEL_SRC_VER         = $(KERNEL_VER)-$(KERNEL_DATE)
KERNEL_SRC             = linux-$(KERNEL_VER)-$(KERNEL_DATE)-arm.tar.gz
KERNEL_URL             = http://source.mynonpublic.com/zgemma
KERNEL_CONFIG          = $(KERNEL_TYPE)/defconfig
KERNEL_DIR             = $(BUILD_TMP)/linux-$(KERNEL_VER)
KERNEL_DTB_VER         = hi3798mv200.dtb

KERNEL_PATCHES = \
		armbox/$(KERNEL_TYPE)/0001-remote.patch \
		armbox/$(KERNEL_TYPE)/HauppaugeWinTV-dualHD.patch \
		armbox/$(KERNEL_TYPE)/dib7000-linux_4.4.179.patch \
		armbox/$(KERNEL_TYPE)/dvb-usb-linux_4.4.179.patch \
		armbox/$(KERNEL_TYPE)/0002-log2-give-up-on-gcc-constant-optimizations.patch \
		armbox/$(KERNEL_TYPE)/0003-dont-mark-register-as-const.patch \
		armbox/$(KERNEL_TYPE)/wifi-linux_4.4.183.patch \
		armbox/$(KERNEL_TYPE)/0004-linux-fix-buffer-size-warning-error.patch \
		armbox/$(KERNEL_TYPE)/modules_mark__inittest__exittest_as__maybe_unused.patch \
		armbox/$(KERNEL_TYPE)/includelinuxmodule_h_copy__init__exit_attrs_to_initcleanup_module.patch \
		armbox/$(KERNEL_TYPE)/Backport_minimal_compiler_attributes_h_to_support_GCC_9.patch \
		armbox/$(KERNEL_TYPE)/0005-xbox-one-tuner-4.4.patch \
		armbox/$(KERNEL_TYPE)/0006-dvb-media-tda18250-support-for-new-silicon-tuner.patch \
		armbox/$(KERNEL_TYPE)/0007-dvb-mn88472-staging.patch \
		armbox/$(KERNEL_TYPE)/mn88472_reset_stream_ID_reg_if_no_PLP_given.patch \
		armbox/$(KERNEL_TYPE)/4.4.35_fix-multiple-defs-yyloc.patch \
		armbox/$(KERNEL_TYPE)/af9035.patch

# others
#CAIRO_OPTS = \
#		--enable-egl \
#		--enable-glesv2

LINKS_PATCH_BOXTYPE = links-$(LINKS_VER)-event2-input.patch

CUSTOM_RCS     = $(SKEL_ROOT)/release/rcS_neutrino_$(KERNEL_TYPE)
CUSTOM_INITTAB = $(SKEL_ROOT)/etc/inittab_ttyS0

# release target
neutrino-release-h9combo:
	install -m 0755 $(SKEL_ROOT)/release/halt_h9combo $(RELEASE_DIR)/etc/init.d/halt
	install -m 0755 $(SKEL_ROOT)/etc/init.d/mmcblk-by-name $(RELEASE_DIR)/etc/init.d/mmcblk-by-name
	cp -f $(SKEL_ROOT)/release/fstab_h9combo $(RELEASE_DIR)/etc/fstab
ifeq ($(LAYOUT), multi)
	sed -i -e 's#/dev/mmcblk0p10#/dev/mmcblk0p7#g' $(RELEASE_DIR)/etc/fstab
	sed -i -e 's#/dev/mmcblk0p11#/dev/mmcblk0p9#g' $(RELEASE_DIR)/etc/fstab
endif
	cp $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/extra/*.ko $(RELEASE_DIR)/lib/modules/
	cp $(TARGET_DIR)/boot/uImage $(RELEASE_DIR)/boot/

