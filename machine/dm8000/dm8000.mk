BOXARCH = mips
CICAM = ci-cam
SCART = scart
LCD = tftlcd
FKEYS = fkeys

#
#
#
KERNEL_VER             = 3.2-dm8000
KERNEL_SRC_VER         = 3.2.68
KERNEL_SRC             = linux-${KERNEL_SRC_VER}.tar.xz
KERNEL_URL             = https://cdn.kernel.org/pub/linux/kernel/v3.x
KERNEL_CONFIG          = defconfig
KERNEL_DIR             = $(BUILD_TMP)/linux-$(KERNEL_SRC_VER)
KERNELNAME             = vmlinux
CUSTOM_KERNEL_VER      = $(KERNEL_SRC_VER)

KERNEL_PATCHES_MIPS = \
		kernel-fake-3.2.patch \
		linux-dreambox-3.2-3c7230bc0819495db75407c365f4d1db70008044.patch \
		unionfs-2.6_for_3.2.62.patch \
		0001-correctly-initiate-nand-flash-ecc-config-when-old-2n.patch \
		0001-Revert-MIPS-Fix-potencial-corruption.patch \
		fadvise_dontneed_change.patch \
		fix-proc-cputype.patch \
		rtl8712-backport-b.patch \
		rtl8712-backport-c.patch \
		rtl8712-backport-d.patch \
		0007-CHROMIUM-make-3.82-hack-to-fix-differing-behaviour-b.patch \
		0008-MIPS-Fix-build-with-binutils-2.24.51.patch \
		0009-MIPS-Refactor-clear_page-and-copy_page-functions.patch \
		0010-BRCMSTB-Fix-build-with-binutils-2.24.51.patch \
		0011-staging-rtl8712-rtl8712-avoid-lots-of-build-warnings.patch \
		0001-brmcnand_base-disable-flash-BBT-on-64MB-nand.patch \
		0002-ubifs-add-config-option-to-use-zlib-as-default-compr.patch \
		em28xx_fix_terratec_entries.patch \
		em28xx_add_terratec_h5_rev3.patch \
		dvb-usb-siano-always-load-smsdvb.patch \
		dvb-usb-af9035.patch \
		dvb-usb-a867.patch \
		dvb-usb-rtl2832.patch \
		dvb_usb_disable_rc_polling.patch \
		dvb-usb-smsdvb_fix_frontend.patch \
		0001-it913x-backport-changes-to-3.2-kernel.patch \
		kernel-add-support-for-gcc6.patch \
		kernel-add-support-for-gcc7.patch \
		kernel-add-support-for-gcc8.patch \
		kernel-add-support-for-gcc9.patch \
		kernel-add-support-for-gcc10.patch \
		kernel-add-support-for-gcc11.patch \
		kernel-add-support-for-gcc12.patch \
		misc_latin1_to_utf8_conversions.patch \
		0001-dvb_frontend-backport-multistream-support.patch \
		genksyms_fix_typeof_handling.patch \
		0012-log2-give-up-on-gcc-constant-optimizations.patch \
		0013-cp1emu-do-not-use-bools-for-arithmetic.patch \
		0014-makefile-silence-packed-not-aligned-warn.patch \
		0015-fcrypt-fix-bitoperation-for-gcc.patch \
		fix-multiple-defs-yyloc.patch
		
KERNEL_PATCHES = $(KERNEL_PATCHES_MIPS)

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
		$(MAKE) -C $(KERNEL_DIR) ARCH=mips CROSS_COMPILE=$(TARGET)- $(KERNELNAME) modules
		$(MAKE) -C $(KERNEL_DIR) ARCH=mips CROSS_COMPILE=$(TARGET)- DEPMOD=$(DEPMOD) INSTALL_MOD_PATH=$(TARGET_DIR) modules_install
		$(DEPMOD) -ae -b $(TARGET_DIR) -F $(KERNEL_DIR)/System.map -r $(KERNEL_VER)
	@touch $@

$(D)/kernel: $(D)/bootstrap $(D)/kernel.do_compile
	install -m 644 $(KERNEL_DIR)/$(KERNELNAME) $(TARGET_DIR)/boot/
	install -m 644 $(KERNEL_DIR)/System.map $(TARGET_DIR)/boot/System.map-$(BOXARCH)-$(KERNEL_VER)
#	rm $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/build || true
#	rm $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/source || true
#
#	gzip -9c < "$(KERNEL_DIR)/vmlinux" > "$(KERNEL_DIR)/vmlinux-3.2-dm8000.gz"
#	install -m 644 $(KERNEL_DIR)/vmlinux-3.2-dm8000.gz $(TARGET_DIR)/boot/	ln -sf vmlinux-3.2-dm8000.gz $(TARGET_DIR)/boot/vmlinux
#	install -m 644 $(KERNEL_DIR)/System.map $(TARGET_DIR)/boot/System.map-$(BOXARCH)-$(KERNEL_VER)
	rm $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/build || true
	rm $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/source || true
#
	$(TOUCH)
	
#
# driver
#
DRIVER_VER = 3.2
DRIVER_DATE = 20140604a
DRIVER_SRC = dreambox-dvb-modules-$(BOXTYPE)-$(DRIVER_VER)-$(BOXTYPE)-$(DRIVER_DATE).tar.bz2

$(ARCHIVE)/$(DRIVER_SRC):
	$(WGET) https://sources.dreamboxupdate.com/download/opendreambox/2.0.0/dreambox-dvb-modules/$(DRIVER_SRC)
	
$(D)/driver: $(ARCHIVE)/$(DRIVER_SRC) $(D)/bootstrap $(D)/kernel
	$(START_BUILD)
	install -d $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/extra
	tar -xf $(ARCHIVE)/$(DRIVER_SRC) -C $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/extra
#	tar -xf $(ARCHIVE)/grautec.tar.gz -C $(TARGET_DIR)/
	$(DEPMOD) -ae -b $(TARGET_DIR) -r $(KERNEL_VER)
	$(TOUCH)
	
#
# release-dm8000
#
release-dm8000:
	cp -pa $(TARGET_DIR)/lib/modules/$(KERNEL_VER) $(RELEASE_DIR)/lib/modules
	install -m 0755 $(BASE_DIR)/machine/$(BOXTYPE)/files/halt $(RELEASE_DIR)/etc/init.d/
	cp -f $(BASE_DIR)/machine/$(BOXTYPE)/files/fstab $(RELEASE_DIR)/etc/
	
#
# flashimage
#
flash-image-dm8000:

