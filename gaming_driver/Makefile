obj-m := daisy_gaming.o
daisy_gaming-objs := entry.o

KDIR ?= /mnt/d/DaisyForGaming/out
ARCH ?= arm64
CROSS_COMPILE ?= aarch64-linux-gnu-

default:
	$(MAKE) -C /mnt/d/DaisyForGaming O=$(KDIR) M=$(PWD) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) modules
	cp daisy_gaming.ko 4.9.337-DaisyForGaming.ko
	cp daisy_gaming.ko "/mnt/d/Driver Maker/4.9.337-DaisyForGaming.ko"

clean:
	$(MAKE) -C /mnt/d/DaisyForGaming O=$(KDIR) M=$(PWD) clean
	rm -f 4.9.337-DaisyForGaming.ko
