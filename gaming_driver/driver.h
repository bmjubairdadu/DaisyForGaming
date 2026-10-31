#ifndef _DAISY_GAMING_DRIVER_H_
#define _DAISY_GAMING_DRIVER_H_

#include <linux/types.h>

#define DRIVER_NAME "daisy_gaming"
#define DEFAULT_DEVICE_PREFIX "daisy_"
#define CLASS_NAME "daisy_cls"

/* IOCTL Command Codes (Fully compatible with RT, QX, Driver.sh & AincradClient) */
#define IOCTL_READ_PROCESS_MEM   0x801
#define IOCTL_WRITE_PROCESS_MEM  0x802
#define IOCTL_GET_MODULE_BASE    0x803

/* Data structure for memory read/write operations (32 bytes) */
struct MemoryOp {
    pid_t pid;          /* Target Process ID */
    uint32_t _pad;      /* 4-byte padding for 64-bit alignment */
    uint64_t addr;      /* Target virtual memory address */
    uint64_t buffer;    /* User-space buffer pointer */
    size_t size;        /* Number of bytes to read or write */
};

/* Data structure for resolving module base address (24 bytes) */
struct ModuleBaseOp {
    pid_t pid;          /* Target Process ID */
    uint32_t _pad;      /* 4-byte padding */
    char *name;         /* User-space pointer to library name (e.g., "libil2cpp.so") */
    uint64_t base;      /* Resolved base virtual address returned to user */
};

#endif /* _DAISY_GAMING_DRIVER_H_ */
