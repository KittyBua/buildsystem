BOXARCH = arm
CICAM = ci-cam
SCART = scart
LCD = 4-digits
FKEYS =

#
# kernel
#
KERNEL_VER             = 4.4.35
KERNEL_DATE            = 20200219
KERNEL_SRC             = linux-$(KERNEL_VER)-$(KERNEL_DATE)-arm.tar.gz
KERNEL_URL             = http://source.mynonpublic.com/maxytec
KERNEL_CONFIG          = defconfig
KERNEL_DIR             = $(BUILD_TMP)/linux-$(KERNEL_VER)
KERNEL_DTB_VER         = hi3798mv200.dtb
CUSTOM_KERNEL_VER      = $(KERNEL_VER)-$(KERNEL_DATE)-arm

KERNEL_PATCHES = \
		0002-log2-give-up-on-gcc-constant-optimizations.patch \
		0003-dont-mark-register-as-const.patch \
		0001-remote.patch \
		HauppaugeWinTV-dualHD.patch \
		dib7000-linux_4.4.179.patch \
		dvb-usb-linux_4.4.179.patch \
		wifi-linux_4.4.183.patch \
		move-default-dialect-to-SMB3.patch \
		0004-linux-fix-buffer-size-warning-error.patch \
		modules_mark__inittest__exittest_as__maybe_unused.patch \
		includelinuxmodule_h_copy__init__exit_attrs_to_initcleanup_module.patch \
		Backport_minimal_compiler_attributes_h_to_support_GCC_9.patch \
		0005-xbox-one-tuner-4.4.patch \
		0006-dvb-media-tda18250-support-for-new-silicon-tuner.patch \
		0007-dvb-mn88472-staging.patch \
		mn88472_reset_stream_ID_reg_if_no_PLP_given.patch \
		4.4.35_fix-multiple-defs-yyloc.patch

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
		$(MAKE) -C $(KERNEL_DIR) ARCH=arm CROSS_COMPILE=$(TARGET)- $(KERNEL_DTB_VER) uImage modules
		$(MAKE) -C $(KERNEL_DIR) ARCH=arm CROSS_COMPILE=$(TARGET)- DEPMOD=$(DEPMOD) INSTALL_MOD_PATH=$(TARGET_DIR) modules_install
	@touch $@

$(D)/kernel: $(D)/bootstrap $(D)/kernel.do_compile
	install -m 644 $(KERNEL_DIR)/vmlinux $(TARGET_DIR)/boot/vmlinux-arm-$(KERNEL_VER)
	install -m 644 $(KERNEL_DIR)/System.map $(TARGET_DIR)/boot/System.map-$(BOXARCH)-$(KERNEL_VER)
	cp $(KERNEL_DIR)/arch/arm/boot/zImage $(TARGET_DIR)/boot/
	cat $(KERNEL_DIR)/arch/arm/boot/zImage $(KERNEL_DIR)/arch/arm/boot/dts/$(KERNEL_DTB_VER) > $(TARGET_DIR)/boot/zImage.dtb
	rm $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/build || true
	rm $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/source || true
	$(TOUCH)

#
# driver
#
DRIVER_VER = 4.4.35
DRIVER_DATE    = 20211129
PLAYERLIB_DATE = 20200622
LIBGLES_DATE   = 20190104

DRIVER_SRC = multiboxse-drivers-$(DRIVER_VER)-$(DRIVER_DATE).zip
PLAYERLIB_SRC = maxytec-libs-3798mv200-$(PLAYERLIB_DATE).zip
LIBGLES_SRC = multiboxse-mali-$(LIBGLES_DATE).zip
LIBGLES_HEADERS = libgles-mali-utgard-headers.zip
MALI_MODULE_VER = DX910-SW-99002-r7p0-00rel0
MALI_MODULE_SRC = $(MALI_MODULE_VER).tgz
MALI_MODULE_PATCH = 0001-hi3798mv200-support.patch

$(ARCHIVE)/$(DRIVER_SRC):
	$(WGET) http://source.mynonpublic.com/maxytec/$(DRIVER_SRC)

$(ARCHIVE)/$(PLAYERLIB_SRC):
	$(WGET) http://source.mynonpublic.com/maxytec/$(PLAYERLIB_SRC)

$(ARCHIVE)/$(LIBGLES_SRC):
	$(WGET) http://downloads.mutant-digital.net/$(KERNEL_TYPE)/$(LIBGLES_SRC)

$(ARCHIVE)/$(MALI_MODULE_SRC):
	$(WGET) https://developer.arm.com/-/media/Files/downloads/mali-drivers/kernel/mali-utgard-gpu/$(MALI_MODULE_SRC);name=driver

driver: $(D)/driver
$(D)/driver: $(ARCHIVE)/$(DRIVER_SRC) $(D)/bootstrap $(D)/kernel
	$(START_BUILD)
	install -d $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/extra
	unzip -o $(ARCHIVE)/$(DRIVER_SRC) -d $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/extra
	install -d $(TARGET_DIR)/bin
	mv $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/extra/turnoff_power $(TARGET_DIR)/bin
	ls $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/extra | sed s/.ko//g > $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/modules.default
	#$(MAKE) install-v3ddriver
	#$(MAKE) install-v3ddriver-header
	#$(MAKE) install-hisiplayer-preq
	#$(MAKE) install-hisiplayer-libs
	#$(MAKE) mali-gpu-modul
	$(TOUCH)

$(D)/install-v3ddriver: $(ARCHIVE)/$(LIBGLES_SRC)
	install -d $(TARGET_LIB_DIR)
	unzip -o $(ARCHIVE)/$(LIBGLES_SRC) -d $(TARGET_LIB_DIR)
	ln -sf libMali.so $(TARGET_LIB_DIR)/libmali.so
	ln -sf libMali.so $(TARGET_LIB_DIR)/libEGL.so.1.4
	ln -sf libEGL.so.1.4 $(TARGET_LIB_DIR)/libEGL.so.1
	ln -sf libEGL.so.1 $(TARGET_LIB_DIR)/libEGL.so
	ln -sf libMali.so $(TARGET_LIB_DIR)/libGLESv1_CM.so.1.1
	ln -sf libGLESv1_CM.so.1.1 $(TARGET_LIB_DIR)/libGLESv1_CM.so.1
	ln -sf libGLESv1_CM.so.1 $(TARGET_LIB_DIR)/libGLESv1_CM.so
	ln -sf libMali.so $(TARGET_LIB_DIR)/libGLESv2.so.2.0
	ln -sf libGLESv2.so.2.0 $(TARGET_LIB_DIR)/libGLESv2.so.2
	ln -sf libGLESv2.so.2 $(TARGET_LIB_DIR)/libGLESv2.so
	ln -sf libMali.so $(TARGET_LIB_DIR)/libgbm.so

$(D)/install-v3ddriver-header: $(ARCHIVE)/$(LIBGLES_HEADERS)
	install -d $(TARGET_INCLUDE_DIR)
	unzip -o $(PATCHES)/$(LIBGLES_HEADERS) -d $(TARGET_INCLUDE_DIR)
	install -d $(TARGET_LIB_DIR)/pkgconfig
	cp $(PATCHES)/glesv2.pc $(TARGET_LIB_DIR)/pkgconfig
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/glesv2.pc
	cp $(PATCHES)/glesv1_cm.pc $(TARGET_LIB_DIR)/pkgconfig
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/glesv1_cm.pc
	cp $(PATCHES)/egl.pc $(TARGET_LIB_DIR)/pkgconfig
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/egl.pc

$(D)/install-hisiplayer-libs: $(ARCHIVE)/$(PLAYERLIB_SRC)
	install -d $(BUILD_TMP)/hiplay
	unzip -o $(ARCHIVE)/$(PLAYERLIB_SRC) -d $(BUILD_TMP)/hiplay
	install -d $(TARGET_LIB_DIR)/hisilicon
	install -m 0755 $(BUILD_TMP)/hiplay/hisilicon/* $(TARGET_LIB_DIR)/hisilicon
	install -m 0755 $(BUILD_TMP)/hiplay/ffmpeg/* $(TARGET_LIB_DIR)/hisilicon
	#install -m 0755 $(BUILD_TMP)/hiplay/glibc/* $(TARGET_LIB_DIR)/hisilicon
	ln -sf /lib/ld-linux-armhf.so.3 $(TARGET_LIB_DIR)/hisilicon/ld-linux.so
	$(REMOVE)/hiplay

$(D)/install-hisiplayer-preq: $(D)/zlib $(D)/libpng $(D)/freetype $(D)/libcurl $(D)/libxml2 $(D)/libjpeg_turbo2 $(D)/harfbuzz

$(D)/mali-gpu-modul: $(ARCHIVE)/$(MALI_MODULE_SRC) $(D)/bootstrap $(D)/kernel
	$(START_BUILD)
	$(REMOVE)/$(MALI_MODULE_VER)
	$(UNTAR)/$(MALI_MODULE_SRC)
	$(CHDIR)/$(MALI_MODULE_VER); \
		$(call apply_patches, $(MALI_MODULE_PATCH)); \
		$(MAKE) -C $(KERNEL_DIR) ARCH=arm CROSS_COMPILE=$(TARGET)- \
		M=$(BUILD_TMP)/$(MALI_MODULE_VER)/driver/src/devicedrv/mali \
		EXTRA_CFLAGS="-DCONFIG_MALI_SHARED_INTERRUPTS=y \
		-DCONFIG_MALI400=m \
		-DCONFIG_MALI450=y \
		-DCONFIG_MALI_DVFS=y \
		-DCONFIG_GPU_AVS_ENABLE=y" \
		CONFIG_MALI_SHARED_INTERRUPTS=y \
		CONFIG_MALI400=m \
		CONFIG_MALI450=y \
		CONFIG_MALI_DVFS=y \
		CONFIG_GPU_AVS_ENABLE=y ; \
		$(MAKE) -C $(KERNEL_DIR) ARCH=arm CROSS_COMPILE=$(TARGET)- \
		M=$(BUILD_TMP)/$(MALI_MODULE_VER)/driver/src/devicedrv/mali \
		EXTRA_CFLAGS="-DCONFIG_MALI_SHARED_INTERRUPTS=y \
		-DCONFIG_MALI400=m \
		-DCONFIG_MALI450=y \
		-DCONFIG_MALI_DVFS=y \
		-DCONFIG_GPU_AVS_ENABLE=y" \
		CONFIG_MALI_SHARED_INTERRUPTS=y \
		CONFIG_MALI400=m \
		CONFIG_MALI450=y \
		CONFIG_MALI_DVFS=y \
		CONFIG_GPU_AVS_ENABLE=y \
		DEPMOD=$(DEPMOD) INSTALL_MOD_PATH=$(TARGET_DIR) modules_install
	ls $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/extra | sed s/.ko//g > $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/modules.default
	$(REMOVE)/$(MALI_MODULE_VER)
	$(TOUCH)

#
# release
#
release-multiboxse:
	cp -pa $(TARGET_DIR)/lib/modules/$(KERNEL_VER) $(RELEASE_DIR)/lib/modules
	install -m 0755 $(SKEL_ROOT)/etc/init.d/mmcblk-by-name $(RELEASE_DIR)/etc/init.d/mmcblk-by-name
	install -m 0755 $(BASE_DIR)/machine/$(BOXTYPE)/files/halt $(RELEASE_DIR)/etc/init.d/
	cp -f $(BASE_DIR)/machine/$(BOXTYPE)/files/fstab $(RELEASE_DIR)/etc/

#
# flashimage
#
FLASH_IMAGE_NAME = disk
FLASH_BOOT_IMAGE = bootoptions.img
FLASH_IMAGE_LINK = $(FLASH_IMAGE_NAME).ext4

FLASH_BOOTOPTIONS_PARTITION_SIZE = 4096
FLASH_IMAGE_ROOTFS_SIZE = 1048576
 
FLASH_BOOTARGS_DATE  = 20201110
FLASH_PARTITONS_DATE = 20201130 #20200319
FLASH_RECOVERY_DATE  = 20201110

FLASH_BOOTARGS_SRC = $(BOXTYPE)-bootargs-$(FLASH_BOOTARGS_DATE).zip
#FLASH_PARTITONS_SRC = $(BOXTYPE)-partitions-$(FLASH_PARTITONS_DATE).zip
FLASH_RECOVERY_SRC = $(BOXTYPE)-recovery-$(FLASH_RECOVERY_DATE).zip

BLOCK_SIZE = 512
BLOCK_SECTOR = 2

$(ARCHIVE)/$(FLASH_BOOTARGS_SRC):
	$(WGET) http://source.mynonpublic.com/maxytec/$(FLASH_BOOTARGS_SRC)

$(ARCHIVE)/$(FLASH_PARTITONS_SRC):
	$(WGET) http://source.mynonpublic.com/maxytec/$(FLASH_PARTITONS_SRC)
	
$(ARCHIVE)/$(FLASH_RECOVERY_SRC):
	$(WGET) http://source.mynonpublic.com/maxytec/$(FLASH_RECOVERY_SRC)

#
# disk
#
flash-image-$(BOXTYPE)-disk: $(ARCHIVE)/$(FLASH_BOOTARGS_SRC)
	# Create image
	rm -rf $(IMAGE_BUILD_DIR) || true
	mkdir -p $(IMAGE_BUILD_DIR)/$(BOXTYPE)
	mkdir -p $(IMAGE_DIR)
	#
	unzip -o $(ARCHIVE)/$(FLASH_BOOTARGS_SRC) -d $(IMAGE_BUILD_DIR)
#	unzip -o $(ARCHIVE)/$(FLASH_PARTITONS_SRC) -d $(IMAGE_BUILD_DIR)
	#
	echo $(BOXTYPE)_$(shell date '+%d%m%Y-%H%M%S') > $(IMAGE_BUILD_DIR)/$(BOXTYPE)/imageversion
	#
	dd if=/dev/zero of=$(IMAGE_BUILD_DIR)/$(FLASH_IMAGE_LINK) seek=$(shell expr $(FLASH_IMAGE_ROOTFS_SIZE) \* $(BLOCK_SECTOR)) count=0 bs=$(BLOCK_SIZE)
	$(HOST_DIR)/bin/mkfs.ext4 -F $(IMAGE_BUILD_DIR)/$(FLASH_IMAGE_LINK) -d $(RELEASE_DIR)
	# Error codes 0-3 indicate successfull operation of fsck (no errors or errors corrected)
	$(HOST_DIR)/bin/fsck.ext4 -pvfD $(IMAGE_BUILD_DIR)/$(FLASH_IMAGE_LINK) || [ $? -le 3 ]
	dd if=/dev/zero of=$(IMAGE_BUILD_DIR)/$(FLASH_BOOT_IMAGE) bs=1024 count=$(FLASH_BOOTOPTIONS_PARTITION_SIZE)
	mkfs.msdos -S 512 $(IMAGE_BUILD_DIR)/$(FLASH_BOOT_IMAGE)
	echo "bootcmd=mmc read 0 0x1000000 0x53D000 0x8000; bootm 0x1000000 bootargs=console=ttyAMA0,115200 root=/dev/mmcblk0p21 rootfstype=ext4" > $(IMAGE_BUILD_DIR)/STARTUP
	echo "bootcmd=mmc read 0 0x3F000000 0x70000 0x4000; bootm 0x3F000000; mmc read 0 0x1FFBFC0 0x52000 0xC800; bootargs=androidboot.selinux=enforcing androidboot.serialno=0123456789 console=ttyAMA0,115200" > $(IMAGE_BUILD_DIR)/STARTUP_RED
	echo "bootcmd=mmc read 0 0x1000000 0x53D000 0x8000; bootm 0x1000000 bootargs=console=ttyAMA0,115200 root=/dev/mmcblk0p21 rootfstype=ext4" > $(IMAGE_BUILD_DIR)/STARTUP_GREEN
	echo "bootcmd=mmc read 0 0x1000000 0x53D000 0x8000; bootm 0x1000000 bootargs=console=ttyAMA0,115200 root=/dev/mmcblk0p21 rootfstype=ext4" > $(IMAGE_BUILD_DIR)/STARTUP_YELLOW
	echo "bootcmd=mmc read 0 0x1000000 0x53D000 0x8000; bootm 0x1000000 bootargs=console=ttyAMA0,115200 root=/dev/mmcblk0p21 rootfstype=ext4" > $(IMAGE_BUILD_DIR)/STARTUP_BLUE
	mcopy -i $(IMAGE_BUILD_DIR)/$(FLASH_BOOT_IMAGE) -v $(IMAGE_BUILD_DIR)/STARTUP ::
	mcopy -i $(IMAGE_BUILD_DIR)/$(FLASH_BOOT_IMAGE) -v $(IMAGE_BUILD_DIR)/STARTUP_RED ::
	mcopy -i $(IMAGE_BUILD_DIR)/$(FLASH_BOOT_IMAGE) -v $(IMAGE_BUILD_DIR)/STARTUP_GREEN ::
	mcopy -i $(IMAGE_BUILD_DIR)/$(FLASH_BOOT_IMAGE) -v $(IMAGE_BUILD_DIR)/STARTUP_YELLOW ::
	mcopy -i $(IMAGE_BUILD_DIR)/$(FLASH_BOOT_IMAGE) -v $(IMAGE_BUILD_DIR)/STARTUP_BLUE ::
	cp $(IMAGE_BUILD_DIR)/$(FLASH_BOOT_IMAGE) $(IMAGE_BUILD_DIR)/$(BOXTYPE)/$(FLASH_BOOT_IMAGE)
	ext2simg -zv $(IMAGE_BUILD_DIR)/$(FLASH_IMAGE_LINK) $(IMAGE_BUILD_DIR)/$(BOXTYPE)/rootfs.fastboot.gz
	mv $(IMAGE_BUILD_DIR)/bootargs-8gb.bin $(IMAGE_BUILD_DIR)/bootargs.bin
	mv $(IMAGE_BUILD_DIR)/$(BOXTYPE)/bootargs-8gb.bin $(IMAGE_BUILD_DIR)/$(BOXTYPE)/bootargs.bin
	cp $(TARGET_DIR)/boot/uImage $(IMAGE_BUILD_DIR)/$(BOXTYPE)/uImage
	#
	cd $(IMAGE_BUILD_DIR) && \
	zip -r $(IMAGE_DIR)/$(BOXTYPE)_$(shell date '+%d.%m.%Y-%H.%M')_recovery_emmc.zip *
	# cleanup
	rm -rf $(IMAGE_BUILD_DIR)
	
flash-image-$(BOXTYPE)-rootfs:
	rm -rf $(IMAGE_BUILD_DIR) || true
	mkdir -p $(IMAGE_BUILD_DIR)/$(BOXTYPE)
	mkdir -p $(IMAGE_DIR)
	#
	cp $(TARGET_DIR)/boot/uImage $(IMAGE_BUILD_DIR)/$(BOXTYPE)/uImage
	#
	cd $(RELEASE_DIR); \
	tar -cvf $(IMAGE_BUILD_DIR)/$(BOXTYPE)/rootfs.tar --exclude=uImage* . > /dev/null 2>&1; \
	bzip2 $(IMAGE_BUILD_DIR)/$(BOXTYPE)/rootfs.tar
	#
	echo "$(BOXTYPE)_$(shell date '+%d.%m.%Y-%H.%M')" > $(IMAGE_BUILD_DIR)/$(BOXTYPE)/imageversion
	echo "$(BOXTYPE)_$(shell date '+%d.%m.%Y-%H.%M')_emmc.zip" > $(IMAGE_BUILD_DIR)/unforce_$(BOXTYPE).txt; \
	echo "Rename the unforce_$(BOXTYPE).txt to force_$(BOXTYPE).txt and move it to the root of your usb-stick" > $(IMAGE_BUILD_DIR)/force_$(BOXTYPE)_READ.ME; \
	echo "When you enter the recovery menu then it will force to install the image $$(cat $(IMAGE_BUILD_DIR)/$(BOXTYPE)/imageversion).zip in the image-slot1" >> $(IMAGE_BUILD_DIR)/force_$(BOXTYPE)_READ.ME; \
	#
	cd $(IMAGE_BUILD_DIR) && \
	zip -r $(IMAGE_DIR)/$(BOXTYPE)_$(shell date '+%d.%m.%Y-%H.%M')_usb.zip $(BOXTYPE)/unforce_$(BOXTYPE).txt $(BOXTYPE)/force_$(BOXTYPE)_READ.ME $(BOXTYPE)/rootfs.tar.bz2 $(BOXTYPE)/uImage $(BOXTYPE)/imageversion
	# cleanup
	rm -rf $(IMAGE_BUILD_DIR)

flash-image-$(BOXTYPE)-online:
	rm -rf $(IMAGE_BUILD_DIR) || true
	mkdir -p $(IMAGE_BUILD_DIR)/$(BOXTYPE)
	mkdir -p $(IMAGE_DIR)
	#
	cp $(TARGET_DIR)/boot/uImage $(IMAGE_BUILD_DIR)/$(BOXTYPE)/uImage
	#
	cd $(RELEASE_DIR); \
	tar -cvf $(IMAGE_BUILD_DIR)/$(BOXTYPE)/rootfs.tar --exclude=uImage* . > /dev/null 2>&1; \
	bzip2 $(IMAGE_BUILD_DIR)/$(BOXTYPE)/rootfs.tar
	#
	echo $(BOXTYPE)_$(shell date '+%d%m%Y-%H%M%S') > $(IMAGE_BUILD_DIR)/$(BOXTYPE)/imageversion
	#
	cd $(IMAGE_BUILD_DIR) && \
	tar -cvzf $(IMAGE_DIR)/$(BOXTYPE)_$(shell date '+%d.%m.%Y-%H.%M')_online.tgz $(BOXTYPE)/rootfs.tar.bz2 $(BOXTYPE)/uImage $(BOXTYPE)/imageversion
	# cleanup
	rm -rf $(IMAGE_BUILD_DIR)

