BOXARCH = mips
CICAM = ci-cam
LCD = tftlcd
FKEYS = fkeys

#
# kernel
#
KERNEL_VER             = 4.1.20-1.9
KERNEL_DATE            = 20180206
KERNEL_SRC_VER         = 4.1.20
KERNEL_SRC             = gigablue-linux-$(KERNEL_SRC_VER)-$(KERNEL_DATE).tar.gz
KERNEL_URL             = https://source.mynonpublic.com/gigablue
KERNEL_CONFIG          = defconfig
KERNEL_DIR             = $(BUILD_TMP)/linux-$(KERNEL_SRC_VER)
KERNEL_DTB_VER         = bcm7445-bcm97445svmb.dtb
CUSTOM_KERNEL_VER      = $(KERNEL_VER)

KERNEL_PATCHES  = \
		0002-linux_dvb-core.patch \
		0002-bcmgenet-recovery-fix.patch \
		0002-linux_4_1_1_9_dvbs2x.patch \
		0002-linux_dvb_adapter.patch \
		0002-linux_rpmb_not_alloc.patch \
		kernel-add-support-for-gcc6.patch \
		0001-regmap-add-regmap_write_bits.patch \
		0003-Add-support-for-dvb-usb-stick-Hauppauge-WinTV-soloHD.patch \
		0004-af9035-add-USB-ID-07ca-0337-AVerMedia-HD-Volar-A867.patch \
		0005-Add-support-for-EVOLVEO-XtraTV-stick.patch \
		0006-dib8000-Add-support-for-Mygica-Geniatech-S2870.patch \
		0007-dib0700-add-USB-ID-for-another-STK8096-PVR-ref-desig.patch \
		0008-add-Hama-Hybrid-DVB-T-Stick-support.patch \
		0009-Add-Terratec-H7-Revision-4-to-DVBSky-driver.patch \
		0010-media-Added-support-for-the-TerraTec-T1-DVB-T-USB-tu.patch \
		0011-media-tda18250-support-for-new-silicon-tuner.patch \
		0012-media-dib0700-add-support-for-Xbox-One-Digital-TV-Tu.patch \
		0013-mn88472-Fix-possible-leak-in-mn88472_init.patch \
		0014-staging-media-Remove-unneeded-parentheses.patch \
		0015-staging-media-mn88472-simplify-NULL-tests.patch \
		0016-mn88472-fix-typo.patch \
		0017-mn88472-finalize-driver.patch \
		0018-Add-support-for-dvb-usb-stick-Hauppauge-WinTV-dualHD.patch \
		0001-dvb-usb-fix-a867.patch \
		0001-Support-TBS-USB-drivers-for-4.1-kernel.patch \
		0001-TBS-fixes-for-4.1-kernel.patch \
		0001-STV-Add-PLS-support.patch \
		0001-STV-Add-SNR-Signal-report-parameters.patch \
		blindscan2.patch \
		0001-stv090x-optimized-TS-sync-control.patch \
		kernel-add-support-for-gcc7.patch \
		kernel-add-support-for-gcc8.patch \
		kernel-add-support-for-gcc9.patch \
		kernel-add-support-for-gcc10.patch \
		kernel-add-support-for-gcc11.patch \
		kernel-add-support-for-gcc12.patch \
		0002-log2-give-up-on-gcc-constant-optimizations.patch \
		0003-uaccess-dont-mark-register-as-const.patch \
		add-partition-specific-uevent-callbacks-for-partition-info.patch \
		move-default-dialect-to-SMB3.patch \
		fix-multiple-defs-yyloc.patch

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
DRIVER_VER = 4.1.20-1.9
DRIVER_DATE = 20200723

DRIVER_SRC = platform-util-gb7252-${KERNEL_SRC_VER}-$(DRIVER_DATE).r1.zip
DRIVER_URL = http://source.mynonpublic.com/gigablue/drivers

$(ARCHIVE)/$(DRIVER_SRC):
	$(WGET) $(DRIVER_URL)/$(DRIVER_SRC)

driver: $(D)/driver
$(D)/driver: $(ARCHIVE)/$(DRIVER_SRC) $(D)/bootstrap $(D)/kernel
	$(START_BUILD)
	unzip -o $(ARCHIVE)/$(DRIVER_SRC) -d $(BUILD_TMP)/platform-util-$(BOXTYPE)
	install -d $(TARGET_DIR)/usr/share/platform
	install -m 0755 $(BUILD_TMP)/platform-util-$(BOXTYPE)/platform/* $(TARGET_DIR)/usr/share/platform/
	install -d $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/extra/
	install -m 0755 $(TARGET_DIR)/usr/share/platform/*.ko $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/extra/
	install -m 0755 $(TARGET_DIR)/usr/share/platform/*.so $(TARGET_DIR)/usr/lib/
	install -m 0755 $(TARGET_DIR)/usr/share/platform/nxserver $(TARGET_DIR)/usr/bin/nxserver
	install -m 0755 $(TARGET_DIR)/usr/share/platform/dvb_init $(TARGET_DIR)/usr/bin/dvb_init
	$(REMOVE)/platform-util-$(BOXTYPE)
	$(DEPMOD) -ae -b $(TARGET_DIR) -r $(KERNEL_VER)
	$(TOUCH)

#
# release
#
release-gbue4k:
	cp -pa $(TARGET_DIR)/lib/modules/$(KERNEL_VER) $(RELEASE_DIR)/lib/modules
	install -m 0755 $(BASE_DIR)/machine/$(BOXTYPE)/files/halt $(RELEASE_DIR)/etc/init.d/
	cp -f $(BASE_DIR)/machine/$(BOXTYPE)/files/fstab $(RELEASE_DIR)/etc/

#
# flashimage
#
FLASHIMAGE_PREFIX = gigablue/gbue4k

INITRD_SRCDATE = 20181121r1
INITRD_SRC = initrd_$(BOXTYPE)_$(INITRD_SRCDATE).zip

$(ARCHIVE)/$(INITRD_SRC):
	$(DOWNLOAD) https://source.mynonpublic.com/$(BRAND)/initrd/$(INITRD_SRC)

flash-image-gbue4k: $(ARCHIVE)/$(INITRD_SRC)
	rm -rf $(IMAGE_BUILD_DIR) || true
	mkdir -p $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)
	mkdir -p $(IMAGE_DIR)
	#
	unzip -o $(ARCHIVE)/$(INITRD_SRC) -d $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)
	cp $(TARGET_DIR)/boot/zImage $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/kernel.bin
	cd $(RELEASE_DIR); \
	tar -cvf $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs.tar --exclude=kernel.bin . > /dev/null 2>&1; \
	bzip2 $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs.tar
	echo $(BOXTYPE)_$(shell date '+%d%m%Y-%H%M%S') > $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/imageversion
	cd $(IMAGE_BUILD_DIR) && \
	zip -r $(IMAGE_DIR)/$(BOXTYPE)_$(shell date '+%d.%m.%Y-%H.%M')_usb.zip $(FLASHIMAGE_PREFIX)*
	# cleanup
	rm -rf $(IMAGE_BUILD_DIR)

