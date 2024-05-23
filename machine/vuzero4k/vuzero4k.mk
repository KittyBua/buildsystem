BOXARCH = arm
CICAM = ci-cam
SCART = scart
LCD = 
FKEYS =

#
# kernel
#
KERNEL_VER             = 4.1.20-1.9
KERNEL_SRC_VER         = 4.1-1.9
KERNEL_SRC             = stblinux-${KERNEL_SRC_VER}.tar.bz2
KERNEL_URL		= http://code.vuplus.com/download/release/kernel
KERNEL_CONFIG          = defconfig
KERNEL_DIR             = $(BUILD_TMP)/linux
KERNELNAME             = zImage
CUSTOM_KERNEL_VER      = $(KERNEL_SRC_VER)

KERNEL_PATCHES_VUZERO4K = \
		4_1_linux_dvb_adapter.patch \
		4_1_linux_dvb-core.patch \
		4_1_linux_4_1_45_dvbs2x.patch \
		4_1_dmx_source_dvr.patch \
		4_1_bcmsysport_4_1_45.patch \
		4_1_linux_usb_hub.patch \
		4_1_0001-regmap-add-regmap_write_bits.patch \
		4_1_0002-af9035-fix-device-order-in-ID-list.patch \
		4_1_0003-Add-support-for-dvb-usb-stick-Hauppauge-WinTV-soloHD.patch \
		4_1_0004-af9035-add-USB-ID-07ca-0337-AVerMedia-HD-Volar-A867.patch \
		4_1_0005-Add-support-for-EVOLVEO-XtraTV-stick.patch \
		4_1_0006-dib8000-Add-support-for-Mygica-Geniatech-S2870.patch \
		4_1_0007-dib0700-add-USB-ID-for-another-STK8096-PVR-ref-desig.patch \
		4_1_0008-add-Hama-Hybrid-DVB-T-Stick-support.patch \
		4_1_0009-Add-Terratec-H7-Revision-4-to-DVBSky-driver.patch \
		4_1_0010-media-Added-support-for-the-TerraTec-T1-DVB-T-USB-tu.patch \
		4_1_0011-media-tda18250-support-for-new-silicon-tuner.patch \
		4_1_0012-media-dib0700-add-support-for-Xbox-One-Digital-TV-Tu.patch \
		4_1_0013-mn88472-Fix-possible-leak-in-mn88472_init.patch \
		4_1_0014-staging-media-Remove-unneeded-parentheses.patch \
		4_1_0015-staging-media-mn88472-simplify-NULL-tests.patch \
		4_1_0016-mn88472-fix-typo.patch \
		4_1_0017-mn88472-finalize-driver.patch \
		4_1_0001-dvb-usb-fix-a867.patch \
		4_1_kernel-add-support-for-gcc6.patch \
		4_1_kernel-add-support-for-gcc7.patch \
		4_1_kernel-add-support-for-gcc8.patch \
		4_1_kernel-add-support-for-gcc9.patch \
		4_1_kernel-add-support-for-gcc10.patch \
		4_1_0001-Support-TBS-USB-drivers-for-4.1-kernel.patch \
		4_1_0001-TBS-fixes-for-4.1-kernel.patch \
		4_1_0001-STV-Add-PLS-support.patch \
		4_1_0001-STV-Add-SNR-Signal-report-parameters.patch \
		4_1_blindscan2.patch \
		4_1_0001-stv090x-optimized-TS-sync-control.patch \
		4_1_0002-log2-give-up-on-gcc-constant-optimizations.patch \
		4_1_0003-uaccess-dont-mark-register-as-const.patch \
		bcmgenet-recovery-fix.patch \
		linux_rpmb_not_alloc.patch \
		fix-multiple-defs-yyloc.patch

KERNEL_PATCHES = $(KERNEL_PATCHES_VUZERO4K)

$(ARCHIVE)/$(KERNEL_SRC):
	$(WGET) $(KERNEL_URL)/$(KERNEL_SRC)

$(D)/kernel.do_prepare: $(ARCHIVE)/$(KERNEL_SRC) $(BASE_DIR)/machine/$(BOXTYPE)/files/$(KERNEL_CONFIG)
	$(START_BUILD)
	rm -rf $(KERNEL_DIR)
	$(UNTAR)/$(KERNEL_SRC)
	set -e; cd $(KERNEL_DIR); \
		for i in $(KERNEL_PATCHES); do \
			echo -e "==> $(TERM_RED)Applying Patch:$(TERM_NORMAL) $$i"; \
			$(APATCH) $(BASE_DIR)/machine/$(BOXTYPE)/patches/$$i; \
		done
	install -m 644 $(BASE_DIR)/machine/$(BOXTYPE)/files/$(KERNEL_CONFIG) $(KERNEL_DIR)/.config
ifeq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), kerneldebug debug))
	@echo "Using kernel debug"
	@grep -v "CONFIG_PRINTK" "$(KERNEL_DIR)/.config" > $(KERNEL_DIR)/.config.tmp
	cp $(KERNEL_DIR)/.config.tmp $(KERNEL_DIR)/.config
	@echo "CONFIG_PRINTK=y" >> $(KERNEL_DIR)/.config
	@echo "CONFIG_PRINTK_TIME=y" >> $(KERNEL_DIR)/.config
endif
	@touch $@

$(D)/kernel.do_compile: $(D)/kernel.do_prepare
	set -e; cd $(KERNEL_DIR); \
		$(MAKE) -C $(KERNEL_DIR) ARCH=arm oldconfig
		$(MAKE) -C $(KERNEL_DIR) ARCH=arm CROSS_COMPILE=$(TARGET)- $(KERNELNAME) modules
		$(MAKE) -C $(KERNEL_DIR) ARCH=arm CROSS_COMPILE=$(TARGET)- DEPMOD=$(DEPMOD) INSTALL_MOD_PATH=$(TARGET_DIR) modules_install
	@touch $@

$(D)/kernel: $(D)/bootstrap $(D)/kernel.do_compile
	install -m 644 $(KERNEL_DIR)/arch/arm/boot/$(KERNELNAME) $(TARGET_DIR)/boot/vmlinux
	install -m 644 $(KERNEL_DIR)/vmlinux $(TARGET_DIR)/boot/vmlinux-arm-$(KERNEL_VER)
	install -m 644 $(KERNEL_DIR)/System.map $(TARGET_DIR)/boot/System.map-arm-$(KERNEL_VER)
	cp $(KERNEL_DIR)/arch/arm/boot/$(KERNELNAME) $(TARGET_DIR)/boot/
	rm $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/build || true
	rm $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/source || true
	$(TOUCH)

#
# driver
#
DRIVER_VER = 4.1.20
DRIVER_DATE = 20190424
DRIVER_REV = r0
DRIVER_SRC = vuplus-dvb-proxy-vuzero4k-$(DRIVER_VER)-$(DRIVER_DATE).$(DRIVER_REV).tar.gz
DRIVER_URL = http://code.vuplus.com/download/release/vuplus-dvb-proxy

$(ARCHIVE)/$(DRIVER_SRC):
	$(WGET) $(DRIVER_URL)/$(DRIVER_SRC)

driver: $(D)/driver
$(D)/driver: $(ARCHIVE)/$(DRIVER_SRC) $(D)/bootstrap $(D)/kernel
	$(START_BUILD)
	install -d $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/extra
	tar -xf $(ARCHIVE)/$(DRIVER_SRC) -C $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/extra
	$(MAKE) platform_util
	$(MAKE) libgles
	$(MAKE) vmlinuz_initrd
	$(DEPMOD) -ae -b $(TARGET_DIR) -r $(KERNEL_VER)
	$(TOUCH)

#
# platform util
#
UTIL_VER = 17.1
UTIL_DATE = $(DRIVER_DATE)
UTIL_REV = r0
UTIL_SRC = platform-util-vuzero4k-$(UTIL_VER)-$(UTIL_DATE).$(UTIL_REV).tar.gz
UTIL_URL = http://code.vuplus.com/download/release/platform-util

$(ARCHIVE)/$(UTIL_SRC):
	$(WGET) $(UTIL_URL)/$(UTIL_SRC)

$(D)/platform_util: $(D)/bootstrap $(ARCHIVE)/$(UTIL_SRC)
	$(START_BUILD)
	$(UNTAR)/$(UTIL_SRC)
	install -m 0755 $(BUILD_TMP)/platform-util-vuzero4k/* $(TARGET_DIR)/usr/bin
	$(REMOVE)/platform-util-vuzero4k
	$(TOUCH)

#
# libgles
#
GLES_VER = 17.1
GLES_DATE = $(DRIVER_DATE)
GLES_REV = r0
GLES_SRC = libgles-vuzero4k-$(GLES_VER)-$(GLES_DATE).$(GLES_REV).tar.gz
GLES_URL = http://code.vuplus.com/download/release/libgles

$(ARCHIVE)/$(GLES_SRC):
	$(WGET) $(GLES_URL)/$(GLES_SRC)

$(D)/libgles: $(D)/bootstrap $(ARCHIVE)/$(GLES_SRC)
	$(START_BUILD)
	$(UNTAR)/$(GLES_SRC)
	install -m 0755 $(BUILD_TMP)/libgles-vuzero4k/lib/* $(TARGET_LIB_DIR)
	ln -sf libv3ddriver.so $(TARGET_LIB_DIR)/libEGL.so
	ln -sf libv3ddriver.so $(TARGET_LIB_DIR)/libGLESv2.so
	cp -a $(BUILD_TMP)/libgles-vuzero4k/include/* $(TARGET_INCLUDE_DIR)
	$(REMOVE)/libgles-vuzero4k
	$(TOUCH)

#
# vmlinuz initrd
#
INITRD_DATE = 20170522
INITRD_SRC = vmlinuz-initrd_vuzero4k_$(INITRD_DATE).tar.gz
INITRD_URL = http://code.vuplus.com/download/release/kernel

$(ARCHIVE)/$(INITRD_SRC):
	$(WGET) $(INITRD_URL)/$(INITRD_SRC)

$(D)/vmlinuz_initrd: $(D)/bootstrap $(ARCHIVE)/$(INITRD_SRC)
	$(START_BUILD)
	tar -xf $(ARCHIVE)/$(INITRD_SRC) -C $(TARGET_DIR)/boot
	$(TOUCH)

#
# release
#
release-vuzero4k:
	cp -pa $(TARGET_DIR)/lib/modules/$(KERNEL_VER) $(RELEASE_DIR)/lib/modules
	rm -f $(RELEASE_DIR)/lib/modules/$(KERNEL_VER)/extra/fpga_directc.ko
	install -m 0755 $(BASE_DIR)/machine/$(BOXTYPE)/files/halt $(RELEASE_DIR)/etc/init.d/
	cp -f $(BASE_DIR)/machine/$(BOXTYPE)/files/fstab $(RELEASE_DIR)/etc/

#
# flashimage
#
FLASHIMAGE_PREFIX = vuplus/zero4k
	
#
# multi-rootfs
#
flash-image-vuzero4k-multi-rootfs:
	# Create final USB-image
	rm -rf $(IMAGE_BUILD_DIR) || true
	mkdir -p $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)
	mkdir -p $(IMAGE_DIR)
	#
	cp $(TARGET_DIR)/boot/vmlinuz-initrd-7260a0 $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/initrd_auto.bin
	cp $(TARGET_DIR)/boot/$(KERNELNAME) $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/kernel1_auto.bin
	cp $(TARGET_DIR)/boot/$(KERNELNAME) $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/kernel2_auto.bin
	cp $(TARGET_DIR)/boot/$(KERNELNAME) $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/kernel3_auto.bin
	cp $(TARGET_DIR)/boot/$(KERNELNAME) $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/kernel4_auto.bin
	#
	cd $(RELEASE_DIR); \
	tar -cvf $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs.tar --exclude=$(KERNELNAME)* --exclude=vmlinuz-initrd* . > /dev/null 2>&1; \
	bzip2 $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs.tar
	mv $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs.tar.bz2 $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs1.tar.bz2
	cp $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs1.tar.bz2 $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs2.tar.bz2
	cp $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs1.tar.bz2 $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs3.tar.bz2
	cp $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs1.tar.bz2 $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs4.tar.bz2
	#
	echo This file forces the update. > $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/force.update
	echo Dummy for update. > $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/kernel_auto.bin
	echo Dummy for update. > $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs.tar.bz2
	echo $(BOXTYPE)_$(shell date '+%d%m%Y-%H%M%S') > $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/imageversion
	#
	cd $(IMAGE_BUILD_DIR) && \
	zip -r $(IMAGE_DIR)/$(BOXTYPE)_$(shell date '+%d.%m.%Y-%H.%M')_multi_usb.zip $(FLASHIMAGE_PREFIX)/rootfs*.tar.bz2 $(FLASHIMAGE_PREFIX)/initrd_auto.bin $(FLASHIMAGE_PREFIX)/kernel*_auto.bin $(FLASHIMAGE_PREFIX)/*.update $(FLASHIMAGE_PREFIX)/imageversion
	# cleanup
	rm -rf $(IMAGE_BUILD_DIR)
	
#
# rootfs
#
flash-image-vuzero4k-rootfs:
	# Create final USB-image
	rm -rf $(IMAGE_BUILD_DIR) || true
	mkdir -p $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)
	mkdir -p $(IMAGE_DIR)
	#
	cp $(TARGET_DIR)/boot/vmlinuz-initrd-7260a0 $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/initrd_auto.bin
	cp $(TARGET_DIR)/boot/$(KERNELNAME) $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/kernel_auto.bin
	#
	cd $(RELEASE_DIR); \
	tar -cvf $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs.tar --exclude=$(KERNELNAME)* --exclude=vmlinuz-initrd* . > /dev/null 2>&1; \
	bzip2 $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs.tar
	#
	echo This file forces the update. > $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/force.update
	echo This file forces creating partitions. > $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/mkpart.update
	echo $(BOXTYPE)_$(shell date '+%d%m%Y-%H%M%S') > $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/imageversion
	#
	cd $(IMAGE_BUILD_DIR) && \
	zip -r $(IMAGE_DIR)/$(BOXTYPE)_$(shell date '+%d.%m.%Y-%H.%M')_usb.zip $(FLASHIMAGE_PREFIX)/rootfs.tar.bz2 $(FLASHIMAGE_PREFIX)/initrd_auto.bin $(FLASHIMAGE_PREFIX)/kernel_auto.bin $(FLASHIMAGE_PREFIX)/*.update $(FLASHIMAGE_PREFIX)/imageversion
	# cleanup
	rm -rf $(IMAGE_BUILD_DIR)

#
# online
#
flash-image-vuzero4k-online:
	# Create final USB-image
	rm -rf $(IMAGE_BUILD_DIR) || true
	mkdir -p $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)
	mkdir -p $(IMAGE_DIR)
	#
	cp $(TARGET_DIR)/boot/vmlinuz-initrd-7260a0 $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/initrd_auto.bin
	cp $(TARGET_DIR)/boot/$(KERNELNAME) $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/kernel_auto.bin
	#
	cd $(RELEASE_DIR); \
	tar -cvf $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs.tar --exclude=$(KERNELNAME)* --exclude=vmlinuz-initrd* . > /dev/null 2>&1; \
	bzip2 $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs.tar
	#
	echo This file forces the update. > $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/force.update
	echo This file forces creating partitions. > $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/mkpart.update
	echo $(BOXTYPE)_$(shell date '+%d%m%Y-%H%M%S') > $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/imageversion
	#
	cd $(IMAGE_BUILD_DIR) && \
	tar -cvzf $(IMAGE_DIR)/$(BOXTYPE)_$(shell date '+%d.%m.%Y-%H.%M')_online.tgz $(FLASHIMAGE_PREFIX)/rootfs.tar.bz2 $(FLASHIMAGE_PREFIX)/initrd_auto.bin $(FLASHIMAGE_PREFIX)/kernel_auto.bin $(FLASHIMAGE_PREFIX)/*.update $(FLASHIMAGE_PREFIX)/imageversion
	# cleanup
	rm -rf $(IMAGE_BUILD_DIR)

