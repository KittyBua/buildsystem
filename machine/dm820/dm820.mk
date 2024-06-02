#
# Makefile for dreambox dm820
#
BOXARCH = mips
CICAM = ci-cam
LCD = tftlcd
FKEYS = fkeys

#
#
#
KERNEL_VER             = 3.4-4.0
KERNEL_SRC_VER         = 3.4.113
KERNEL_SRC             = linux-${KERNEL_SRC_VER}.tar.xz
KERNEL_URL             = https://cdn.kernel.org/pub/linux/kernel/v3.x
KERNEL_CONFIG          = defconfig
KERNEL_DIR             = $(BUILD_TMP)/linux-$(KERNEL_SRC_VER)
CUSTOM_KERNEL_VER      = $(KERNEL_SRC_VER)

KERNEL_PATCHES = \
		linux-dreambox-3.4-30070c78a23d461935d9db0b6ce03afc70a10c51.patch \
		kernel-fake-3.4.patch \
		dvb_frontend-Multistream-support-3.4.patch \
		kernel-add-support-for-gcc6.patch \
		kernel-add-support-for-gcc7.patch \
		kernel-add-support-for-gcc8.patch \
		kernel-add-support-for-gcc9.patch \
		kernel-add-support-for-gcc10.patch \
		kernel-add-support-for-gcc11.patch \
		kernel-add-support-for-gcc12.patch \
		kernel-add-support-for-gcc13.patch \
		kernel-add-support-for-gcc14.patch \
		build-with-gcc12-fixes.patch \
		genksyms_fix_typeof_handling.patch \
		0001-log2-give-up-on-gcc-constant-optimizations.patch \
		0002-cp1emu-do-not-use-bools-for-arithmetic.patch \
		0003-makefile-silence-packed-not-aligned-warn.patch \
		0004-fcrypt-fix-bitoperation-for-gcc.patch

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
		$(MAKE) -C $(KERNEL_DIR) ARCH=mips oldconfig
		$(MAKE) -C $(KERNEL_DIR) ARCH=mips CROSS_COMPILE=$(TARGET)- vmlinux.bin modules
		$(MAKE) -C $(KERNEL_DIR) ARCH=mips CROSS_COMPILE=$(TARGET)- DEPMOD=$(DEPMOD) INSTALL_MOD_PATH=$(TARGET_DIR) modules_install
		$(DEPMOD) -ae -b $(TARGET_DIR) -F $(KERNEL_DIR)/System.map -r $(KERNEL_VER)-$(BOXTYPE)
	@touch $@

$(D)/kernel: $(D)/bootstrap $(D)/kernel.do_compile
	install -m 644 $(KERNEL_DIR)/vmlinux.bin $(TARGET_DIR)/boot/
	install -m 644 $(KERNEL_DIR)/System.map $(TARGET_DIR)/boot/System.map-$(BOXARCH)-$(KERNEL_VER)
	rm $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/build || true
	rm $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/source || true
	$(TOUCH)
	
#
# driver
#
DRIVER_VER = 3.4-4.0
DRIVER_DATE = 20181018
DRIVER_SRC = dreambox-dvb-modules_$(DRIVER_VER)-$(BOXTYPE)-$(DRIVER_DATE)_$(BOXTYPE).tar.xz

$(ARCHIVE)/$(DRIVER_SRC):
	$(WGET) https://github.com/oe-mirrors/dreambox/raw/main/$(DRIVER_SRC)

driver: $(D)/driver	
$(D)/driver: $(ARCHIVE)/$(DRIVER_SRC) $(D)/bootstrap $(D)/kernel
	$(START_BUILD)
	install -d $(TARGET_DIR)/lib/modules/$(KERNEL_VER)-$(BOXTYPE)/extra
	tar -xf $(ARCHIVE)/$(DRIVER_SRC) -C $(TARGET_DIR)/lib/modules/$(KERNEL_VER)-$(BOXTYPE)/extra --transform='s/.*\///'
	find $(TARGET_DIR)/lib/modules/$(KERNEL_VER)-$(BOXTYPE)/extra -type d -empty -delete
	$(DEPMOD) -ae -b $(TARGET_DIR) -r $(KERNEL_VER)-$(BOXTYPE)
	$(TOUCH)

#
# release-dm820
#
release-dm820:
	cp -pa $(TARGET_DIR)/lib/modules/$(KERNEL_VER)-$(BOXTYPE) $(RELEASE_DIR)/lib/modules
	install -m 0755 $(BASE_DIR)/machine/$(BOXTYPE)/files/halt $(RELEASE_DIR)/etc/init.d/
	cp -f $(BASE_DIR)/machine/$(BOXTYPE)/files/fstab $(RELEASE_DIR)/etc/
	
#
# flashimage
#
flash-image-dm820:
#	rm -rf $(IMAGE_BUILD_DIR) || true
#	mkdir -p $(IMAGE_BUILD_DIR)/$(BOXTYPE)
	mkdir -p $(IMAGE_DIR)
	#
	gzip -9c < "$(TARGET_DIR)/boot/vmlinux.bin" > "$(IMAGE_BUILD_DIR)/$(BOXTYPE)/vmlinux.gz-3.4-4.0-dm820"
#	mkfs.jffs2 --root=$(RELEASE_DIR)/boot/ --disable-compressor=lzo --compression-mode=size --eraseblock=131072 --output=$(IMAGE_BUILD_DIR)/$(BOXTYPE)/boot.jffs2
	#
#	mkfs.ubifs -r $(RELEASE_DIR) -o $(IMAGE_BUILD_DIR)/$(BOXTYPE)/rootfs.ubifs -m 2048 -e 126KiB -c 1961 -x favor_lzo -F
#	echo '[ubifs]' > $(IMAGE_BUILD_DIR)/$(BOXTYPE)/ubinize.cfg
#	echo 'mode=ubi' >> $(IMAGE_BUILD_DIR)/$(BOXTYPE)/ubinize.cfg
#	echo 'image=$(IMAGE_BUILD_DIR)/$(BOXTYPE)/rootfs.ubifs' >> $(IMAGE_BUILD_DIR)/$(BOXTYPE)/ubinize.cfg
#	echo 'vol_id=0' >> $(IMAGE_BUILD_DIR)/$(BOXTYPE)/ubinize.cfg
#	echo 'vol_type=dynamic' >> $(IMAGE_BUILD_DIR)/$(BOXTYPE)/ubinize.cfg
#	echo 'vol_name=rootfs' >> $(IMAGE_BUILD_DIR)/$(BOXTYPE)/ubinize.cfg
#	echo 'vol_flags=autoresize' >> $(IMAGE_BUILD_DIR)/$(BOXTYPE)/ubinize.cfg
#	ubinize -o $(IMAGE_BUILD_DIR)/$(BOXTYPE)/rootfs.ubi -m 2048 -p 128KiB -s 512 $(IMAGE_BUILD_DIR)/$(BOXTYPE)/ubinize.cfg
#	rm -f $(IMAGE_BUILD_DIR)/$(BOXTYPE)/rootfs.ubifs
#	rm -f $(IMAGE_BUILD_DIR)/$(BOXTYPE)/ubinize.cfg
#	echo $(BOXTYPE)_$(shell date '+%d%m%Y-%H%M%S') > $(IMAGE_BUILD_DIR)/$(BOXTYPE)/imageversion
#	cd $(IMAGE_BUILD_DIR)/$(BOXTYPE) && \
#	buildimage -a dm8000 -e 0x20000 -f 0x4000000 -s 2048 -b 0x100000:secondstage-dm8000-84.bin -d 0x700000:boot.jffs2 -d 0xF800000:rootfs.ubi > $(BOXTYPE).nfi
	#
#	cd $(IMAGE_BUILD_DIR) && \
#	zip -r $(IMAGE_DIR)/$(BOXTYPE)_$(shell date '+%d.%m.%Y-%H.%M')_usb.zip $(BOXTYPE)/$(BOXTYPE).nfi $(BOXTYPE)/imageversion
	cd $(RELEASE_DIR) && \
	tar cvJf $(IMAGE_DIR)/$(BOXTYPE)_$(shell date '+%d.%m.%Y-%H.%M')_usb.tar.xz --exclude=vmlinux.gz* . > /dev/null 2>&1
	# cleanup
#	rm -rf $(IMAGE_BUILD_DIR)

