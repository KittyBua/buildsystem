BOXARCH = arm
CICAM = ci-cam
SCART = scart
LCD = 4-digits
FKEYS =

#
# kernel
#
KERNEL_VER             = 4.4.35
KERNEL_DATE            = 20181224
KERNEL_SRC             = octagon-linux-$(KERNEL_VER)-$(KERNEL_DATE).tar.gz
KERNEL_URL             = http://source.mynonpublic.com/octagon
KERNEL_CONFIG          = defconfig
KERNEL_DIR             = $(BUILD_TMP)/linux-$(KERNEL_VER)
KERNEL_DTB_VER         = hi3798mv200.dtb
KERNELNAME             = uImage
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
		fix-dvbcore.patch \
		0005-xbox-one-tuner-4.4.patch \
		0006-dvb-media-tda18250-support-for-new-silicon-tuner.patch \
		0007-dvb-mn88472-staging.patch \
		mn88472_reset_stream_ID_reg_if_no_PLP_given.patch \
		af9035.patch \
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
	cp $(BASE_DIR)/machine/$(BOXTYPE)/patches//initramfs-subdirboot.cpio.gz $(KERNEL_DIR)
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
		$(MAKE) -C $(KERNEL_DIR) ARCH=arm CROSS_COMPILE=$(TARGET)- $(KERNEL_DTB_VER) $(KERNELNAME) modules
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
DRIVER_DATE    = 20220105
DRIVER_SRC = $(BOXTYPE)-hiko-$(DRIVER_DATE).zip

HICHIPSET = 3798mv200
SOC_FAMILY = hisi3798mv200

HILIB_DATE     = 20190917
LIBGLES_DATE   = 20180301
LIBREADER_DATE = 20200612
HIHALT_DATE    = 20200601
TNTFS_DATE     = 20200528

HILIB_SRC = $(BOXTYPE)-hilib-$(HILIB_DATE).tar.gz
LIBGLES_SRC = $(SOC_FAMILY)-opengl-$(LIBGLES_DATE).tar.gz
LIBREADER_SRC = $(BOXTYPE)-libreader-$(LIBREADER_DATE).tar.gz
HIHALT_SRC = $(BOXTYPE)-hihalt-$(HIHALT_DATE).tar.gz
TNTFS_SRC = $(HICHIPSET)-tntfs-$(TNTFS_DATE).zip
LIBJPEG_SRC = libjpeg.so.62.2.0

WIFI_DIR = RTL8192EU-master
WIFI_SRC = master.zip
WIFI = RTL8192EU.zip

WIFI2_DIR = RTL8822C-main
WIFI2_SRC = main.zip
WIFI2 = RTL8822C.zip

$(ARCHIVE)/$(DRIVER_SRC):
	$(WGET) http://source.mynonpublic.com/octagon/$(DRIVER_SRC)
	
$(ARCHIVE)/$(HILIB_SRC):
	$(WGET) http://source.mynonpublic.com/octagon/$(HILIB_SRC)

$(ARCHIVE)/$(LIBGLES_SRC):
	$(WGET) http://source.mynonpublic.com/octagon/$(LIBGLES_SRC)

$(ARCHIVE)/$(LIBREADER_SRC):
	$(WGET) http://source.mynonpublic.com/octagon/$(LIBREADER_SRC)

$(ARCHIVE)/$(HIHALT_SRC):
	$(WGET) http://source.mynonpublic.com/octagon/$(HIHALT_SRC)

$(ARCHIVE)/$(TNTFS_SRC):
	$(WGET) http://source.mynonpublic.com/tntfs/$(TNTFS_SRC)

$(ARCHIVE)/$(LIBJPEG_SRC):	
	$(WGET) https://github.com/oe-alliance/oe-alliance-core/raw/5.3/meta-brands/meta-octagon/recipes-graphics/files/$(LIBJPEG_SRC)

$(ARCHIVE)/$(WIFI_SRC):
	$(WGET) https://github.com/zukon/RTL8192EU/archive/refs/heads/$(WIFI_SRC) -O $(ARCHIVE)/$(WIFI)

$(ARCHIVE)/$(WIFI2_SRC):
	$(WGET) https://github.com/zukon/RTL8822C/archive/refs/heads/$(WIFI2_SRC) -O $(ARCHIVE)/$(WIFI2)

driver: $(D)/driver
$(D)/driver: $(ARCHIVE)/$(DRIVER_SRC) $(D)/bootstrap $(D)/kernel
	$(START_BUILD)
	install -d $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/extra
	unzip -o $(ARCHIVE)/$(DRIVER_SRC) -d $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/extra
	install -d $(TARGET_DIR)/bin
	mv $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/extra/hiko/* $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/extra
	rmdir $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/extra/hiko
	$(MAKE) install-tntfs
	$(MAKE) install-wifi
	$(MAKE) install-wifi2
	ls $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/extra | sed s/.ko//g > $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/modules.default
	$(MAKE) install-hisiplayer-libs
	$(MAKE) install-hilib
	$(MAKE) install-libjpeg
	$(MAKE) install-hihalt
	$(MAKE) install-libreader
	$(TOUCH)

$(D)/install-hilib: $(ARCHIVE)/$(HILIB_SRC)
	install -d $(BUILD_TMP)/hilib
	tar xzf $(ARCHIVE)/$(HILIB_SRC) -C $(BUILD_TMP)/hilib
	cp -R $(BUILD_TMP)/hilib/hilib/* $(TARGET_LIB_DIR)
	$(REMOVE)/hilib

$(D)/install-hisiplayer-libs: $(ARCHIVE)/$(LIBGLES_SRC)
	install -d $(BUILD_TMP)/hiplay
	tar xzf $(ARCHIVE)/$(LIBGLES_SRC) -C $(BUILD_TMP)/hiplay
	cp -d $(BUILD_TMP)/hiplay/usr/lib/* $(TARGET_LIB_DIR)
	$(REMOVE)/hiplay

$(D)/install-libreader: $(ARCHIVE)/$(LIBREADER_SRC)
	install -d $(BUILD_TMP)/libreader
	tar xzf $(ARCHIVE)/$(LIBREADER_SRC) -C $(BUILD_TMP)/libreader
	install -m 0755 $(BUILD_TMP)/libreader/libreader $(TARGET_DIR)/usr/bin/libreader
	$(REMOVE)/libreader

$(D)/install-tntfs: $(ARCHIVE)/$(TNTFS_SRC)
	install -d $(BUILD_TMP)/tntfs
	unzip -o $(ARCHIVE)/$(TNTFS_SRC) -d $(BUILD_TMP)/tntfs
	install -m 0755 $(BUILD_TMP)/tntfs/tntfs.ko $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/extra
	$(REMOVE)/tntfs

$(D)/install-hihalt: $(ARCHIVE)/$(HIHALT_SRC)
	install -d $(BUILD_TMP)/hihalt
	tar xzf $(ARCHIVE)/$(HIHALT_SRC) -C $(BUILD_TMP)/hihalt
	install -m 0755 $(BUILD_TMP)/hihalt/hihalt $(TARGET_DIR)/usr/bin/hihalt
	$(REMOVE)/hihalt

$(D)/install-libjpeg: $(ARCHIVE)/$(LIBJPEG_SRC)
	cp $(ARCHIVE)/$(LIBJPEG_SRC) $(TARGET_LIB_DIR)

$(D)/install-wifi: $(D)/bootstrap $(D)/kernel $(ARCHIVE)/$(WIFI_SRC)
	$(START_BUILD)
	$(REMOVE)/$(WIFI_DIR)
	unzip -o $(ARCHIVE)/$(WIFI) -d $(BUILD_TMP)
	echo $(KERNEL_DIR)
	$(CHDIR)/$(WIFI_DIR); \
		$(MAKE) ARCH=arm CROSS_COMPILE=$(TARGET)- KVER=$(DRIVER_VER) KSRC=$(KERNEL_DIR); \
		install -m 644 8192eu.ko $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/extra
	$(REMOVE)/$(WIFI_DIR)
	$(TOUCH)

$(D)/install-wifi2: $(D)/bootstrap $(D)/kernel $(ARCHIVE)/$(WIFI2_SRC)
	$(START_BUILD)
	$(REMOVE)/$(WIFI2_DIR)
	unzip -o $(ARCHIVE)/$(WIFI2) -d $(BUILD_TMP)
	echo $(KERNEL_DIR)
	$(CHDIR)/$(WIFI2_DIR); \
		$(MAKE) ARCH=arm CROSS_COMPILE=$(TARGET)- KVER=$(DRIVER_VER) KSRC=$(KERNEL_DIR); \
		install -m 644 88x2cu.ko $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/extra
	$(REMOVE)/$(WIFI2_DIR)
	$(TOUCH)

#
# release
#
release-$(BOXTYPE):
	cp -pa $(TARGET_DIR)/lib/modules/$(KERNEL_VER) $(RELEASE_DIR)/lib/modules
	install -m 0755 $(SKEL_ROOT)/etc/init.d/mmcblk-by-name $(RELEASE_DIR)/etc/init.d/mmcblk-by-name
	install -m 0755 $(BASE_DIR)/machine/$(BOXTYPE)/files/halt $(RELEASE_DIR)/etc/init.d/
	cp -f $(BASE_DIR)/machine/$(BOXTYPE)/files/fstab $(RELEASE_DIR)/etc/
	install -m 0755 $(BASE_DIR)/machine/$(BOXTYPE)/showiframe $(RELEASE_DIR)/bin
	install -m 0755 $(BASE_DIR)/machine/$(BOXTYPE)/libreader.sh  $(RELEASE_DIR)/usr/bin/libreader.sh
	install -d $(RELEASE_DIR)/var/spool/cron/crontabs
	install -m 0755 $(BASE_DIR)/machine/$(BOXTYPE)/root  $(RELEASE_DIR)/var/spool/cron/crontabs/root
	touch $(RELEASE_DIR)/var/tuxbox/config/.crond
	install -m 0755 $(BASE_DIR)/machine/$(BOXTYPE)/suspend  $(RELEASE_DIR)/etc/init.d/suspend
	cp $(TARGET_DIR)/boot/uImage $(RELEASE_DIR)/tmp/
	install -m 0755 $(BASE_DIR)/machine/$(BOXTYPE)/libreader $(RELEASE_DIR)/etc/init.d/
	cd $(RELEASE_DIR)/etc/rc.d/rc0.d; ln -sf ../../init.d/libreader ./S05libreader
	cd $(RELEASE_DIR)/etc/rc.d/rc6.d; ln -sf ../../init.d/libreader ./S05libreader

#
# flashimage
#
FLASH_IMAGE_NAME = disk
FLASH_BOOT_IMAGE = bootoptions.img
FLASH_IMAGE_LINK = $(FLASH_IMAGE_NAME).ext4

FLASH_BOOTOPTIONS_PARTITION_SIZE = 4096
FLASH_IMAGE_ROOTFS_SIZE = 1048576
 
FLASH_BOOTARGS_DATE  = 20201110
FLASH_PARTITONS_DATE = 20200319
FLASH_RECOVERY_DATE  = 20201110

FLASH_BOOTARGS_SRC = $(BOXTYPE)-bootargs-$(FLASH_BOOTARGS_DATE).zip
FLASH_PARTITONS_SRC = $(BOXTYPE)-partitions-$(FLASH_PARTITONS_DATE).zip
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
flash-image-$(BOXTYPE)-disk: $(ARCHIVE)/$(FLASH_BOOTARGS_SRC) $(ARCHIVE)/$(FLASH_PARTITONS_SRC)
	# Create image
	rm -rf $(IMAGE_BUILD_DIR) || true
	mkdir -p $(IMAGE_BUILD_DIR)/$(BOXTYPE)
	mkdir -p $(IMAGE_DIR)
	#
	unzip -o $(ARCHIVE)/$(FLASH_BOOTARGS_SRC) -d $(IMAGE_BUILD_DIR)
	unzip -o $(ARCHIVE)/$(FLASH_PARTITONS_SRC) -d $(IMAGE_BUILD_DIR)
	#
	echo $(BOXTYPE)_usb_$(shell date '+%d%m%Y-%H%M%S') > $(IMAGE_BUILD_DIR)/$(BOXTYPE)/imageversion
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
	cp $(TARGET_DIR)/boot/$(KERNELNAME) $(IMAGE_BUILD_DIR)/$(BOXTYPE)/$(KERNELNAME)
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
	cp $(TARGET_DIR)/boot/$(KERNELNAME) $(IMAGE_BUILD_DIR)/$(BOXTYPE)/$(KERNELNAME)
	#
	cd $(RELEASE_DIR); \
	tar -cvf $(IMAGE_BUILD_DIR)/$(BOXTYPE)/rootfs.tar --exclude=$(KERNELNAME)* . > /dev/null 2>&1; \
	bzip2 $(IMAGE_BUILD_DIR)/$(BOXTYPE)/rootfs.tar
	#
	echo "$(BOXTYPE)_usb_$(shell date '+%d.%m.%Y-%H.%M')" > $(IMAGE_BUILD_DIR)/$(BOXTYPE)/imageversion
	echo "$(BOXTYPE)_usb_$(shell date '+%d.%m.%Y-%H.%M')_emmc.zip" > $(IMAGE_BUILD_DIR)/unforce_$(BOXTYPE).txt; \
	echo "Rename the unforce_$(BOXTYPE).txt to force_$(BOXTYPE).txt and move it to the root of your usb-stick" > $(IMAGE_BUILD_DIR)/force_$(BOXTYPE)_READ.ME; \
	echo "When you enter the recovery menu then it will force to install the image $$(cat $(IMAGE_BUILD_DIR)/$(BOXTYPE)/imageversion).zip in the image-slot1" >> $(IMAGE_BUILD_DIR)/force_$(BOXTYPE)_READ.ME; \
	#
	cd $(IMAGE_BUILD_DIR) && \
	zip -r $(IMAGE_DIR)/$(BOXTYPE)_$(shell date '+%d.%m.%Y-%H.%M')_usb.zip $(BOXTYPE)/unforce_$(BOXTYPE).txt $(BOXTYPE)/force_$(BOXTYPE)_READ.ME $(BOXTYPE)/rootfs.tar.bz2 $(BOXTYPE)/$(KERNELNAME) $(BOXTYPE)/imageversion
	# cleanup
	rm -rf $(IMAGE_BUILD_DIR)

flash-image-$(BOXTYPE)-online:
	rm -rf $(IMAGE_BUILD_DIR) || true
	mkdir -p $(IMAGE_BUILD_DIR)/$(BOXTYPE)
	mkdir -p $(IMAGE_DIR)
	#
	cp $(TARGET_DIR)/boot/$(KERNELNAME) $(IMAGE_BUILD_DIR)/$(BOXTYPE)/$(KERNELNAME)
	#
	cd $(RELEASE_DIR); \
	tar -cvf $(IMAGE_BUILD_DIR)/$(BOXTYPE)/rootfs.tar --exclude=$(KERNELNAME)* . > /dev/null 2>&1; \
	bzip2 $(IMAGE_BUILD_DIR)/$(BOXTYPE)/rootfs.tar
	#
	echo $(BOXTYPE)_$(shell date '+%d%m%Y-%H%M%S') > $(IMAGE_BUILD_DIR)/$(BOXTYPE)/imageversion
	#
	cd $(IMAGE_BUILD_DIR) && \
	tar -cvzf $(IMAGE_DIR)/$(BOXTYPE)_$(shell date '+%d.%m.%Y-%H.%M')_online.tgz $(BOXTYPE)/rootfs.tar.bz2 $(BOXTYPE)/$(KERNELNAME) $(BOXTYPE)/imageversion
	# cleanup
	rm -rf $(IMAGE_BUILD_DIR)

