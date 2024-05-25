BOXARCH = arm
CICAM = ci-cam
SCART = scart
LCD = tftlcd
FKEYS =

#
# kernel
#
KERNEL_VER             = 3.14.28-1.8
KERNEL_SRC_VER         = 3.14-1.8
KERNEL_SRC             = stblinux-${KERNEL_SRC_VER}.tar.bz2
KERNEL_URL		= http://code.vuplus.com/download/release/kernel
KERNEL_CONFIG          = defconfig
KERNEL_DIR             = $(BUILD_TMP)/linux
KERNELNAME             = zImage
CUSTOM_KERNEL_VER      = $(KERNEL_SRC_VER)

KERNEL_PATCHES = \
			bcm_genet_disable_warn.patch \
		    	linux_dvb-core.patch \
		    	rt2800usb_fix_warn_tx_status_timeout_to_dbg.patch \
			usb_core_hub_msleep.patch \
		    	rtl8712_fix_build_error.patch \
		    	kernel-add-support-for-gcc6.patch \
		    	kernel-add-support-for-gcc7.patch \
		    	kernel-add-support-for-gcc8.patch \
		    	kernel-add-support-for-gcc9.patch \
		    	kernel-add-support-for-gcc10.patch \
		    	kernel-add-support-for-gcc11.patch \
		    	0001-Support-TBS-USB-drivers.patch \
		    	0001-STV-Add-PLS-support.patch \
		    	0001-STV-Add-SNR-Signal-report-parameters.patch \
		    	0001-stv090x-optimized-TS-sync-control.patch \
		    	blindscan2.patch \
		    	genksyms_fix_typeof_handling.patch \
		    	0001-tuners-tda18273-silicon-tuner-driver.patch \
		    	01-10-si2157-Silicon-Labs-Si2157-silicon-tuner-driver.patch \
		    	02-10-si2168-Silicon-Labs-Si2168-DVB-T-T2-C-demod-driver.patch \
		    	0003-cxusb-Geniatech-T230-support.patch \
		    	CONFIG_DVB_SP2.patch \
		    	dvbsky.patch \
		    	rtl2832u-2.patch \
		    	0004-log2-give-up-on-gcc-constant-optimizations.patch \
		    	0005-uaccess-dont-mark-register-as-const.patch \
		    	0006-makefile-disable-warnings.patch \
		    	move-default-dialect-to-SMB3.patch \
		    	fix-multiple-defs-yyloc.patch

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
	install -m 644 $(KERNEL_DIR)/arch/arm/boot/$(KERNELNAME) $(BOOT_DIR)/vmlinux
	install -m 644 $(KERNEL_DIR)/vmlinux $(TARGET_DIR)/boot/vmlinux-arm-$(KERNEL_VER)
	install -m 644 $(KERNEL_DIR)/System.map $(TARGET_DIR)/boot/System.map-arm-$(KERNEL_VER)
	cp $(KERNEL_DIR)/arch/arm/boot/$(KERNELNAME) $(TARGET_DIR)/boot/
	rm $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/build || true
	rm $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/source || true
	$(TOUCH)

#
# driver
#
DRIVER_VER = 3.14.28
DRIVER_DATE = 20190424
DRIVER_REV = r0
DRIVER_SRC = vuplus-dvb-proxy-$(BOXTYPE)-$(DRIVER_VER)-$(DRIVER_DATE).$(DRIVER_REV).tar.gz
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
UTIL_DATE = 20190424
UTIL_REV = r0
UTIL_SRC = platform-util-$(BOXTYPE)-$(UTIL_VER)-$(UTIL_DATE).$(UTIL_REV).tar.gz
UTIL_URL = http://code.vuplus.com/download/release/platform-util

$(ARCHIVE)/$(UTIL_SRC):
	$(WGET) $(UTIL_URL)/$(UTIL_SRC)

$(D)/platform_util: $(D)/bootstrap $(ARCHIVE)/$(UTIL_SRC)
	$(START_BUILD)
	$(UNTAR)/$(UTIL_SRC)
	install -m 0755 $(BUILD_TMP)/platform-util-$(BOXTYPE)/* $(TARGET_DIR)/usr/bin
	$(REMOVE)/platform-util-$(BOXTYPE)
	$(TOUCH)

#
# libgles
#
GLES_VER = 17.1
GLES_DATE = 20190424
GLES_REV = r0
GLES_SRC = libgles-$(BOXTYPE)-$(GLES_VER)-$(GLES_DATE).$(GLES_REV).tar.gz
GLES_URL = http://code.vuplus.com/download/release/libgles

$(ARCHIVE)/$(GLES_SRC):
	$(WGET) $(GLES_URL)/$(GLES_SRC)

$(D)/libgles: $(D)/bootstrap $(ARCHIVE)/$(GLES_SRC)
	$(START_BUILD)
	$(UNTAR)/$(GLES_SRC)
	install -m 0755 $(BUILD_TMP)/libgles-$(BOXTYPE)/lib/* $(TARGET_DIR)/usr/lib
	ln -sf libv3ddriver.so $(TARGET_DIR)/usr/lib/libEGL.so
	ln -sf libv3ddriver.so $(TARGET_DIR)/usr/lib/libGLESv2.so
	cp -a $(BUILD_TMP)/libgles-$(BOXTYPE)/include/* $(TARGET_DIR)/usr/include
	$(REMOVE)/libgles-$(BOXTYPE)
	$(TOUCH)

#
# vmlinuz initrd
#
INITRD_DATE = 20170209
INITRD_SRC = vmlinuz-initrd_$(BOXTYPE)_$(INITRD_DATE).tar.gz
INITRD_URL = http://code.vuplus.com/download/release/kernel

$(ARCHIVE)/$(INITRD_SRC):
	$(WGET) $(INITRD_URL)/$(INITRD_SRC)

$(D)/vmlinuz_initrd: $(D)/bootstrap $(ARCHIVE)/$(INITRD_SRC)
	$(START_BUILD)
	tar -xf $(ARCHIVE)/$(INITRD_SRC) -C $(TARGET_DIR)/boot

#
# release
#
release-vusolo4k:
	cp -pa $(TARGET_DIR)/lib/modules/$(KERNEL_VER) $(RELEASE_DIR)/lib/modules
	install -m 0755 $(BASE_DIR)/machine/$(BOXTYPE)/files/halt $(RELEASE_DIR)/etc/init.d/

#
# flashimage
#
FLASHIMAGE_PREFIX = vuplus/solo4k
	
#
# multi-rootfs
#
flash-image-vusolo4k-multi-rootfs:
	# Create final USB-image
	rm -rf $(IMAGE_BUILD_DIR) || true
	mkdir -p $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)
	mkdir -p $(IMAGE_DIR)
	#
	cp $(TARGET_DIR)/boot/vmlinuz-initrd-7366c0 $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/initrd_auto.bin
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
	echo This file forces a reboot after the update. > $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/reboot.update
	echo This file forces creating partitions. > $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/mkpart.update
	echo Dummy for update. > $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/kernel_auto.bin
	echo Dummy for update. > $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs.tar.bz2
	#
	echo $(BOXTYPE)_$(shell date '+%d%m%Y-%H%M%S') > $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/imageversion
	#
	cd $(IMAGE_BUILD_DIR) && \
	zip -r $(IMAGE_DIR)/$(BOXTYPE)_$(shell date '+%d.%m.%Y-%H.%M')_multi_usb.zip $(FLASHIMAGE_PREFIX)/rootfs*.tar.bz2 $(FLASHIMAGE_PREFIX)/initrd_auto.bin $(FLASHIMAGE_PREFIX)/kernel*_auto.bin $(FLASHIMAGE_PREFIX)/*.update $(FLASHIMAGE_PREFIX)/imageversion
	# cleanup
	rm -rf $(IMAGE_BUILD_DIR)

#
# rootfs
#
flash-image-vusolo4k-rootfs:
	# Create final USB-image
	rm -rf $(IMAGE_BUILD_DIR) || true
	mkdir -p $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)
	mkdir -p $(IMAGE_DIR)
	#
	cp $(TARGET_DIR)/boot/vmlinuz-initrd-7366c0 $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/initrd_auto.bin
	cp $(TARGET_DIR)/boot/$(KERNELNAME) $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/kernel_auto.bin
	#
	cd $(RELEASE_DIR); \
	tar -cvf $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs.tar --exclude=$(KERNELNAME)* --exclude=vmlinuz-initrd* . > /dev/null 2>&1; \
	bzip2 $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs.tar
	#
	echo This file forces a reboot after the update. > $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/reboot.update
	echo $(BOXTYPE)_$(shell date '+%d%m%Y-%H%M%S') > $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/imageversion
	#
	cd $(IMAGE_BUILD_DIR) && \
	zip -r $(IMAGE_DIR)/$(BOXTYPE)_$(shell date '+%d.%m.%Y-%H.%M')_usb.zip $(FLASHIMAGE_PREFIX)/rootfs.tar.bz2 $(FLASHIMAGE_PREFIX)/initrd_auto.bin $(FLASHIMAGE_PREFIX)/kernel_auto.bin $(FLASHIMAGE_PREFIX)/reboot.update $(FLASHIMAGE_PREFIX)/imageversion
	# cleanup
	rm -rf $(IMAGE_BUILD_DIR)

#
# online
#
flash-image-vusolo4k-online:
	# Create final USB-image
	rm -rf $(IMAGE_BUILD_DIR) || true
	mkdir -p $(IMAGE_BUILD_DIR)/$(BOXTYPE)
	mkdir -p $(IMAGE_DIR)
	#
	cp $(TARGET_DIR)/boot/vmlinuz-initrd-7366c0 $(IMAGE_BUILD_DIR)/$(BOXTYPE)/initrd_auto.bin
	cp $(TARGET_DIR)/boot/$(KERNELNAME) $(IMAGE_BUILD_DIR)/$(BOXTYPE)/kernel_auto.bin
	#
	cd $(RELEASE_DIR); \
	tar -cvf $(IMAGE_BUILD_DIR)/$(BOXTYPE)/rootfs.tar --exclude=$(KERNELNAME)* --exclude=vmlinuz-initrd* . > /dev/null 2>&1; \
	bzip2 $(IMAGE_BUILD_DIR)/$(BOXTYPE)/rootfs.tar
	#
	echo This file forces a reboot after the update. > $(IMAGE_BUILD_DIR)/$(BOXTYPE)/reboot.update
	echo $(BOXTYPE)_$(shell date '+%d%m%Y-%H%M%S') > $(IMAGE_BUILD_DIR)/$(BOXTYPE)/imageversion
	#
	cd $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX) && \
	tar -cvzf $(IMAGE_DIR)/$(BOXTYPE)_$(shell date '+%d.%m.%Y-%H.%M')_online.tgz rootfs.tar.bz2 initrd_auto.bin kernel_auto.bin reboot.update imageversion
	# cleanup
	rm -rf $(IMAGE_BUILD_DIR)

