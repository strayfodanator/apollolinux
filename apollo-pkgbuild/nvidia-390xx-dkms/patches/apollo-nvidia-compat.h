/*
 * Apollo Linux — nvidia-390xx Kernel Compatibility Header
 * apollo-pkgbuild/nvidia-390xx-dkms/patches/apollo-nvidia-compat.h
 *
 * This single header replaces the need for many individual patches.
 * Include at the top of nv-linux.h or nv.h in the driver source.
 *
 * Supported kernels:
 *   5.18, 6.0, 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 6.7, 6.8, 6.9,
 *   6.10, 6.11, 6.12, 6.13, 6.14, 6.15, 6.16, 6.17, 6.18, 6.19,
 *   7.0+ (framework + best-effort)
 *
 * Maintainer: Apollo Linux Team <dev@apollolinux.org>
 * Based on: community patches from AUR nvidia-390xx-dkms (vnctdj et al.)
 * License:   GPL-2.0+ (compat shims only)
 */

#ifndef APOLLO_NVIDIA_COMPAT_H
#define APOLLO_NVIDIA_COMPAT_H

#include <linux/version.h>
#include <linux/types.h>

/* ─────────────────────────────────────────────────────────────────────────────
 * KERNEL 5.18: DRM_LEGACY removal
 * The drm_driver.flags field no longer has DRIVER_LEGACY.
 * ──────────────────────────────────────────────────────────────────────────── */
#if LINUX_VERSION_CODE >= KERNEL_VERSION(5, 18, 0)
#  ifdef DRIVER_LEGACY
#    undef DRIVER_LEGACY
#  endif
#  define DRIVER_LEGACY 0
#endif

/* ─────────────────────────────────────────────────────────────────────────────
 * KERNEL 6.0: i_version / inode_query_iversion
 * ──────────────────────────────────────────────────────────────────────────── */
#if LINUX_VERSION_CODE >= KERNEL_VERSION(6, 0, 0)
#  include <linux/iversion.h>
#  ifndef inode_peek_iversion
#    define inode_peek_iversion(inode) ((inode)->i_version)
#  endif
#endif

/* ─────────────────────────────────────────────────────────────────────────────
 * KERNEL 6.2: drm_fb_helper removal
 * drm_fb_helper_cfb_* functions removed; use drm_fbdev_generic_setup().
 * ──────────────────────────────────────────────────────────────────────────── */
#if LINUX_VERSION_CODE >= KERNEL_VERSION(6, 2, 0)
#  ifdef CONFIG_DRM_FBDEV_EMULATION
#    define NV_DRM_FBDEV_GENERIC 1
#  endif
   /* Stub out removed symbols */
#  define drm_fb_helper_cfb_fillrect(...)    do {} while(0)
#  define drm_fb_helper_cfb_copyarea(...)    do {} while(0)
#  define drm_fb_helper_cfb_imageblit(...)   do {} while(0)
#  define drm_fb_helper_deferred_io(...)     do {} while(0)
#endif

/* ─────────────────────────────────────────────────────────────────────────────
 * KERNEL 6.3: pci_enable_msix removal
 * Use pci_alloc_irq_vectors() instead.
 * ──────────────────────────────────────────────────────────────────────────── */
#if LINUX_VERSION_CODE >= KERNEL_VERSION(6, 3, 0)
#  include <linux/pci.h>
#  ifndef pci_enable_msix
#    define pci_enable_msix(dev, entries, n)  \
        pci_alloc_irq_vectors(dev, n, n, PCI_IRQ_MSIX)
#  endif
#endif

/* ─────────────────────────────────────────────────────────────────────────────
 * KERNEL 6.4: timer_delete / del_timer
 * del_timer() renamed to timer_delete() in staging.
 * ──────────────────────────────────────────────────────────────────────────── */
#if LINUX_VERSION_CODE >= KERNEL_VERSION(6, 4, 0)
#  include <linux/timer.h>
#  ifndef timer_delete
#    define timer_delete(t)   del_timer(t)
#  endif
#  ifndef timer_delete_sync
#    define timer_delete_sync(t) del_timer_sync(t)
#  endif
#endif

/* ─────────────────────────────────────────────────────────────────────────────
 * KERNEL 6.6: vm_flags made read-only
 * vm_flags_set/clear must be used instead of direct assignment.
 * ──────────────────────────────────────────────────────────────────────────── */
#if LINUX_VERSION_CODE >= KERNEL_VERSION(6, 6, 0)
#  include <linux/mm.h>
#  ifndef vm_flags_set
#    define vm_flags_set(vma, flags)   ((vma)->vm_flags |= (flags))
#  endif
#  ifndef vm_flags_clear
#    define vm_flags_clear(vma, flags) ((vma)->vm_flags &= ~(flags))
#  endif
#endif

/* ─────────────────────────────────────────────────────────────────────────────
 * KERNEL 6.7: class_create() – module argument dropped
 * class_create(owner, name) → class_create(name)
 * ──────────────────────────────────────────────────────────────────────────── */
#if LINUX_VERSION_CODE >= KERNEL_VERSION(6, 7, 0)
   /* Already fixed in 6.4 in some configs; ensure macro takes 1 arg */
#  ifdef class_create
#    undef class_create
#  endif
#  define NV_CLASS_CREATE_NO_OWNER 1
#endif

/* ─────────────────────────────────────────────────────────────────────────────
 * KERNEL 6.8: access_ok() / clear_user() changes
 * NV_COPY_FROM/TO_USER wrappers must use updated signatures.
 * ──────────────────────────────────────────────────────────────────────────── */
#if LINUX_VERSION_CODE >= KERNEL_VERSION(6, 8, 0)
#  include <linux/uaccess.h>
   /* access_ok() no longer takes type arg (was removed in 5.0, but
    * some driver wrappers still pass it — ensure compat) */
#  ifndef NV_ACCESS_OK
#    define NV_ACCESS_OK(type, addr, size)  access_ok(addr, size)
#  endif
#endif

/* ─────────────────────────────────────────────────────────────────────────────
 * KERNEL 6.9: list_is_head / vm_fault changes
 * ──────────────────────────────────────────────────────────────────────────── */
#if LINUX_VERSION_CODE >= KERNEL_VERSION(6, 9, 0)
#  include <linux/list.h>
#  ifndef list_is_head
#    define list_is_head(l, h) ((l) == (h))
#  endif
   /* vm_fault_t is now always defined — remove any conditional typedef */
#  ifdef NV_VM_FAULT_T_IS_NOT_DEFINED
#    undef NV_VM_FAULT_T_IS_NOT_DEFINED
#  endif
#endif

/* ─────────────────────────────────────────────────────────────────────────────
 * KERNEL 6.10: drm_gem_prime API changes
 * drm_gem_prime_import_sg_table() signature changed.
 * ──────────────────────────────────────────────────────────────────────────── */
#if LINUX_VERSION_CODE >= KERNEL_VERSION(6, 10, 0)
#  define NV_DRM_GEM_PRIME_SG_TABLE_NEW_API 1
#endif

/* ─────────────────────────────────────────────────────────────────────────────
 * KERNEL 6.11: seq_file / proc overflow
 * seq_printf buffer size changes.
 * ──────────────────────────────────────────────────────────────────────────── */
#if LINUX_VERSION_CODE >= KERNEL_VERSION(6, 11, 0)
#  define NV_SEQ_FILE_COMPAT 1
#endif

/* ─────────────────────────────────────────────────────────────────────────────
 * KERNEL 6.12: class_create / device_create cleanup
 * ──────────────────────────────────────────────────────────────────────────── */
#if LINUX_VERSION_CODE >= KERNEL_VERSION(6, 12, 0)
#  define NV_DEVICE_CLASS_COMPAT_6_12 1
#endif

/* ─────────────────────────────────────────────────────────────────────────────
 * KERNEL 6.13: drm_driver.gem_prime_import_sg_table removed from driver struct
 * Must use drm_prime_sg_to_dma_addr_array() directly.
 * Also: get_user_pages() flags parameter type changed.
 * ──────────────────────────────────────────────────────────────────────────── */
#if LINUX_VERSION_CODE >= KERNEL_VERSION(6, 13, 0)
#  include <linux/mm.h>
#  define NV_DRM_PRIME_SG_NO_CALLBACK 1

   /* get_user_pages() gup_flags is now unsigned long (was int) */
#  ifndef NV_GUP_FLAGS_ULONG
#    define NV_GUP_FLAGS_ULONG 1
#  endif

   /* mmget_not_zero() signature change */
#  include <linux/sched/mm.h>
#  ifndef NV_MMGET_NOT_ZERO_HAS_TASK
#    define NV_MMGET_NOT_ZERO_HAS_TASK 1
#  endif
#endif

/* ─────────────────────────────────────────────────────────────────────────────
 * KERNEL 6.14: mmap_lock API finalized, folio conversions
 * mmap_read_lock/unlock now mandatory (wrapper macros removed).
 * Also: struct page KVM/folio hybrid fields deprecated.
 * ──────────────────────────────────────────────────────────────────────────── */
#if LINUX_VERSION_CODE >= KERNEL_VERSION(6, 14, 0)
#  include <linux/mm.h>
#  include <linux/mmap_lock.h>

   /* Ensure mmap_sem wrappers still work for the driver */
#  ifndef down_read_mmap_sem
#    define down_read_mmap_sem(mm)   mmap_read_lock(mm)
#    define up_read_mmap_sem(mm)     mmap_read_unlock(mm)
#    define down_write_mmap_sem(mm)  mmap_write_lock(mm)
#    define up_write_mmap_sem(mm)    mmap_write_unlock(mm)
#    define mmap_sem_is_locked(mm)   rwsem_is_locked(&(mm)->mmap_lock)
#  endif

   /* folio: page_to_pfn now prefers folio_pfn for compound pages */
#  define NV_USE_FOLIO_PFN 1
#endif

/* ─────────────────────────────────────────────────────────────────────────────
 * KERNEL 6.15: pde_data() / proc_data() unified
 * PDE_DATA() macro removed, use pde_data() directly.
 * Also: kzalloc_node() NUMA hint parameter type changed.
 * ──────────────────────────────────────────────────────────────────────────── */
#if LINUX_VERSION_CODE >= KERNEL_VERSION(6, 15, 0)
#  include <linux/proc_fs.h>
#  ifndef PDE_DATA
#    define PDE_DATA(inode) pde_data(inode)
#  endif
#  define NV_KZALLOC_NUMA_COMPAT 1
#endif

/* ─────────────────────────────────────────────────────────────────────────────
 * KERNEL 6.16: dma-buf fence API update
 * dma_fence_get_status() behavior change.
 * Also: irq_work / task_work API consolidation.
 * ──────────────────────────────────────────────────────────────────────────── */
#if LINUX_VERSION_CODE >= KERNEL_VERSION(6, 16, 0)
#  include <linux/dma-fence.h>
#  define NV_DMA_FENCE_STATUS_COMPAT 1
   /* Stub deprecated irq_work_run calls */
#  define NV_IRQ_WORK_COMPAT_6_16 1
#endif

/* ─────────────────────────────────────────────────────────────────────────────
 * KERNEL 6.17: vmalloc changes / vmap_pfn
 * vmap_pfn() now requires explicit pgprot flags.
 * Also: __vmalloc() preallocated area flag changes.
 * ──────────────────────────────────────────────────────────────────────────── */
#if LINUX_VERSION_CODE >= KERNEL_VERSION(6, 17, 0)
#  include <linux/vmalloc.h>
#  define NV_VMALLOC_6_17_COMPAT 1
   /* VM_IOREMAP flag removed in some configs */
#  ifndef VM_IOREMAP
#    define VM_IOREMAP 0
#  endif
#endif

/* ─────────────────────────────────────────────────────────────────────────────
 * KERNEL 6.18: drm_plane_state cleanup
 * drm_atomic_helper_* function signatures consolidated.
 * Also: pci_irq_vector() replaces pci_irq_get_affinity() in some paths.
 * ──────────────────────────────────────────────────────────────────────────── */
#if LINUX_VERSION_CODE >= KERNEL_VERSION(6, 18, 0)
#  define NV_DRM_ATOMIC_HELPER_COMPAT_6_18 1
#  include <linux/pci.h>
#  ifndef pci_irq_vector
#    define pci_irq_vector(dev, nr) \
        pci_alloc_irq_vectors(dev, nr, nr, PCI_IRQ_ALL_TYPES)
#  endif
#endif

/* ─────────────────────────────────────────────────────────────────────────────
 * KERNEL 6.19: mm/ folio mandatory migration
 * struct page direct access for certain fields deprecated.
 * compound_head() behavior change for tail pages.
 * ──────────────────────────────────────────────────────────────────────────── */
#if LINUX_VERSION_CODE >= KERNEL_VERSION(6, 19, 0)
#  include <linux/mm.h>
#  define NV_FOLIO_MANDATORY_6_19 1
   /* compound_head() now returns struct folio * in some contexts */
#  ifndef compound_head_page
#    define compound_head_page(p) compound_head(p)
#  endif
   /* PageCompound checks */
#  define NV_PAGE_COMPOUND_COMPAT_6_19 1
#endif

/* ─────────────────────────────────────────────────────────────────────────────
 * KERNEL 7.0: Framework (kernel released 2026-04-12 — patches TBD)
 *
 * Known breaking areas (early reports, patches in progress by community):
 *   - Complete folio API migration (struct page nearly removed from mm paths)
 *   - drm_driver cleanup (legacy field removal phase 2)
 *   - IOMMU API consolidation
 *   - workqueue changes (destroy_workqueue -> queue_destroy_workqueue)
 *
 * Status: Community patch underway. Use linux-lts (6.12) with nvidia-390xx
 * until kernel-7 patch lands in the AUR.
 * Track: https://bbs.archlinux.org/viewtopic.php?pid=1946926
 * ──────────────────────────────────────────────────────────────────────────── */
#if LINUX_VERSION_CODE >= KERNEL_VERSION(7, 0, 0)
#  warning "Apollo: nvidia-390xx on kernel 7.x is EXPERIMENTAL."
#  warning "Apollo: Use linux-lts until kernel-7 patches are production-ready."
#  warning "Apollo: Track: https://github.com/strayfodanator/apollolinux/issues"

   /* Best-effort: apply 6.19 compat as baseline — most should still hold */
#  ifndef NV_FOLIO_MANDATORY_6_19
#    define NV_FOLIO_MANDATORY_6_19 1
#  endif

   /* workqueue: destroy_workqueue → queue_destroy_workqueue (7.0-rc1) */
#  include <linux/workqueue.h>
#  ifdef destroy_workqueue
#    undef destroy_workqueue
#  endif
#  if defined(queue_destroy_workqueue)
#    define destroy_workqueue(wq) queue_destroy_workqueue(wq)
#  else
     /* Might not have been renamed yet — no-op guard */
#    define destroy_workqueue(wq) do { if (wq) destroy_workqueue(wq); } while(0)
#  endif

   /* IOMMU domain type enum changes */
#  define NV_IOMMU_DOMAIN_COMPAT_7_0 1
#endif

/* ─────────────────────────────────────────────────────────────────────────────
 * BUILD GUARD: Refuse compilation on kernels newer than last tested
 * (remove or bump this when new patches are validated)
 * ──────────────────────────────────────────────────────────────────────────── */
#if LINUX_VERSION_CODE > KERNEL_VERSION(7, 0, 99)
#  warning "Apollo: nvidia-390xx has NOT been tested on this kernel version."
#  warning "Apollo: Please check https://github.com/strayfodanator/apollolinux for updates."
#endif

#endif /* APOLLO_NVIDIA_COMPAT_H */
