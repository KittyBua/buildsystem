#
# Makefile for gigablue ultra
#
BOXARCH = mips
CICAM = ci-cam
SCART = scart
LCD = lcd
FKEYS = fkeys

#
# kernel
#
KERNEL_VER             = 4.8.3
KERNEL_DATE            = 20170302
KERNEL_SRC             = gigablue-linux-$(KERNEL_VER)-mips-$(KERNEL_DATE).tgz
KERNEL_URL             = http://source.mynonpublic.com/gigablue/linux
KERNEL_CONFIG          = defconfig
KERNEL_DIR             = $(BUILD_TMP)/linux-$(KERNEL_VER)
CUSTOM_KERNEL_VER      = $(KERNEL_VER)

KERNEL_PATCHES  = \
		    	0001-genet1-1000mbit.patch \
			0001-stv090x-optimized-TS-sync-control.patch \
			0001-STV-Add-PLS-support.patch \
			0001-STV-Add-SNR-Signal-report-parameters.patch \
			0001-Support-TBS-USB-drivers-for-4.6-kernel.patch \
			0001-TBS-fixes-for-4.6-kernel.patch \
			0002-log2-give-up-on-gcc-constant-optimizations.patch \
			bcmgenet_phyaddr.patch \
			blindscan2.patch \
			fix-build-with-binutils-2.41.patch \
			fix-never-be-null_outside-array-bounds-gcc-12.patch \
			move-default-dialect-to-SMB2.patch \
#			move-default-dialect-to-SMB3.patch \
			nfs-max-rwsize-8k.patch \
			noforce_correct_pointer_usage.patch \
			kernel-add-support-for-gcc-5.patch \
   			kernel-add-support-for-gcc6.patch \
			kernel-add-support-for-gcc7.patch \
			kernel-add-support-for-gcc8.patch \
			kernel-add-support-for-gcc9.patch \
			kernel-add-support-for-gcc10.patch \
			kernel-add-support-for-gcc11.patch \
			kernel-add-support-for-gcc12.patch \
			genksyms_fix_typeof_handling.patch \

$(ARCHIVE)/$(KERNEL_SRC):
	$(WGET) $(KERNEL_URL)/$(KERNEL_SRC)

$(D)/kernel.do_prepare: $(ARCHIVE)/$(KERNEL_SRC) $(BASE_DIR)/machine/$(BOXTYPE)/files/$(KERNEL_CONFIG)
	$(START_BUILD)
	rm -rf $(KERNEL_DIR)
	$(UNTARGZ)/$(KERNEL_SRC)
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
		$(MAKE) -C $(KERNEL_DIR) ARCH=mips oldconfig
		$(MAKE) -C $(KERNEL_DIR) ARCH=mips CROSS_COMPILE=$(TARGET)- vmlinux modules
		$(MAKE) -C $(KERNEL_DIR) ARCH=mips CROSS_COMPILE=$(TARGET)- DEPMOD=$(DEPMOD) INSTALL_MOD_PATH=$(TARGET_DIR) modules_install
		$(DEPMOD) -ae -b $(TARGET_DIR) -F $(KERNEL_DIR)/System.map -r $(KERNEL_VER)
	@touch $@

$(D)/kernel: $(D)/bootstrap $(D)/kernel.do_compile
	install -m 644 $(KERNEL_DIR)/vmlinux $(TARGET_DIR)/boot/
	install -m 644 $(KERNEL_DIR)/System.map $(TARGET_DIR)/boot/System.map-$(BOXARCH)-$(KERNEL_VER)
	rm $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/build || true
	rm $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/source || true
	$(TOUCH)

#
# driver
#
DRIVER_VER = 4.8.3
DRIVER_DATE = 20180403
DRIVER_SRC = gigablue-drivers-$(DRIVER_VER)-BCM7362-$(DRIVER_DATE).zip
DRIVER_URL = http://source.mynonpublic.com/gigablue/drivers

$(ARCHIVE)/$(DRIVER_SRC):
	$(WGET) $(DRIVER_URL)/$(DRIVER_SRC)

driver: $(D)/driver
$(D)/driver: $(ARCHIVE)/$(DRIVER_SRC) $(D)/bootstrap $(D)/kernel
	$(START_BUILD)
	install -d $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/extra
	unzip -o $(ARCHIVE)/$(DRIVER_SRC) -d $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/extra
	$(DEPMOD) -ae -b $(TARGET_DIR) -r $(KERNEL_VER)
	$(TOUCH)

#
# release
#
release-$(BOXTYPE):
	cp -pa $(TARGET_DIR)/lib/modules/$(KERNEL_VER) $(RELEASE_DIR)/lib/modules
	install -m 0755 $(BASE_DIR)/machine/$(BOXTYPE)/files/halt $(RELEASE_DIR)/etc/init.d/
	cp -f $(BASE_DIR)/machine/$(BOXTYPE)/files/fstab $(RELEASE_DIR)/etc/

#
# flashimage
#
FLASHIMAGE_PREFIX = gigablue/ultraue

flash-image-gb800se:
	# Create final USB-image
	rm -rf $(IMAGE_BUILD_DIR) || true
	mkdir -p $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)
	mkdir -p $(IMAGE_DIR)
	# splash
	cp $(SKEL_ROOT)/boot/splash.bin $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)
	cp $(SKEL_ROOT)/boot/warning.bin $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)
	cp $(SKEL_ROOT)/boot/lcdsplash.bin $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)
	cp $(SKEL_ROOT)/boot/lcdwarning220.bin $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/lcdwarning.bin
	cp $(SKEL_ROOT)/boot/lcdwaitkey220.bin $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/lcdwaitkey.bin
	echo "rename this file to 'force' to force an update without confirmation" > $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/noforce;
	# kernel
	gzip -f -c < "$(TARGET_DIR)/boot/vmlinux" > "$(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/kernel.bin"
	# rootfs
	mkfs.ubifs -r $(RELEASE_DIR) -o $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs.ubi -m 2048 -e 126976 -c 4096
	echo '[ubifs]' > $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/ubinize.cfg
	echo 'mode=ubi' >> $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/ubinize.cfg
	echo 'image=$(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs.ubi' >> $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/ubinize.cfg
	echo 'vol_id=0' >> $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/ubinize.cfg
	echo 'vol_type=dynamic' >> $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/ubinize.cfg
	echo 'vol_name=rootfs' >> $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/ubinize.cfg
	echo 'vol_size=100MiB' >> $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/ubinize.cfg
	echo 'vol_flags=autoresize' >> $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/ubinize.cfg
	ubinize -o $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs.bin -m 2048 -p 128KiB $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/ubinize.cfg
	rm -f $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs.ubi
	rm -f $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/ubinize.cfg
	#
	echo $(BOXTYPE)_$(shell date '+%d%m%Y-%H%M%S') > $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/imageversion
	#
	cd $(IMAGE_BUILD_DIR) && \
	zip -r $(IMAGE_DIR)/$(BOXTYPE)_$(shell date '+%d.%m.%Y-%H.%M')_usb.zip $(FLASHIMAGE_PREFIX)*
	# cleanup
	rm -rf $(IMAGE_BUILD_DIR)

