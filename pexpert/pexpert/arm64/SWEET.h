/*
 * Copyright (c) 2023 Apple Inc. All rights reserved.
 */
#ifndef _PEXPERT_ARM64_SWEET_H_
#define _PEXPERT_ARM64_SWEET_H_

#define SWEET                     1

/* Six homogeneous A55s; cpus=N is clamped here until A76/AMP is audited. */
#define ARM_ARCH_TIMER
#define __ARM_ARCH__              8
#define __ARM_VMSA__              8
#define __ARM_VFP__               4
#define __ARM_COHERENT_CACHE__    1
#ifndef ASSEMBLER
#define SWEET_UART
#endif

/* Board-specific constants */
#define SWEET_MEM_BASE            0x80000000ULL
#define SWEET_MEM_SIZE            0x4D000000ULL
#define SWEET_FB_BASE             0x9C000000ULL
#define SWEET_FB_WIDTH            1080
#define SWEET_FB_HEIGHT           2400
#define SWEET_FB_BPP              32
#define SWEET_VTIMER_INTID        27
#define SWEET_IPI_SGI             1
#define SWEET_UART_BASE           0x010C0000
#define SWEET_UART_IRQ            118
#define SWEET_SERIAL_BAUD         115200

#define SWEET_SMP_MAX_CPUS 8

/* No monitor for this board - disables WFI power gating checks */
#define NO_MONITOR                1

#endif /* _PEXPERT_ARM64_SWEET_H_ */
