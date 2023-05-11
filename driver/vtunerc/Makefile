#
# Makefile for the vtunerc device driver
#
TREE_ROOT?=$(DRIVER_TOPDIR)/
#CONFIG_STGFB_PATH?=$(DRIVER_TOPDIR)/stgfb/stmfb

#CCFLAGSY += -I$(TREE_ROOT)/player2/linux/include/linux/stm/
#CCFLAGSY += -I$(TREE_ROOT)/player2/linux/drivers/media/video/stm/
CCFLAGSY += -I$(KERNEL_LOCATION)/drivers/media/dvb/dvb-core
#CCFLAGSY += -I$(CONFIG_STGFB_PATH)/include
#CCFLAGSY += -I$(TREE_ROOT)/include
#CCFLAGSY += -DDEBUG_DVB

CCFLAGSY += -DVTUNERC_MAX_ADAPTERS=4

ifneq (,$(findstring 2.6.3,$(KERNELVERSION)))
ccflags-y += $(CCFLAGSY)
else
CFLAGS += $(CCFLAGSY)
endif

obj-m += vtunerc.o

vtunerc-objs = vtunerc_main.o vtunerc_ctrldev.o vtunerc_proxyfe.o

