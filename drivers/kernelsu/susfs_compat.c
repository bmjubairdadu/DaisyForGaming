/*
 * SusFS <-> KernelSU glue (DaisyForGaming).
 *
 * The SusFS kernel patch expects three helpers from a SusFS-integrated
 * KernelSU fork (see fs/susfs.c externs and the fs/namespace.c hooks):
 *
 *   susfs_is_current_ksu_domain()   - is the caller running in KSU's su
 *                                     SELinux domain (u:r:su:s0)? Used to
 *                                     hand sus mount-ids to mounts created
 *                                     by root processes.
 *   susfs_is_current_zygote_domain() - is the caller zygote (u:r:zygote:s0)?
 *   ksu_try_umount()                 - umount by struct path, via the
 *                                     v5.9 path_umount() backport in
 *                                     fs/namespace.c.
 *
 * The domain SIDs are looked up once and cached: the namespace.c hooks call
 * the domain checks on every alloc_vfsmount()/copy_mnt_ns().
 */

#include <linux/fs.h>
#include <linux/namei.h>
#include <linux/path.h>
#include <linux/printk.h>
#include <linux/sched.h>
#include <linux/security.h>
#include <linux/mount.h>
#include <linux/module.h>
#include <linux/cred.h>

#include "objsec.h"
#include "klog.h"

#define KSU_SU_DOMAIN "u:r:su:s0"
#define ZYGOTE_DOMAIN "u:r:zygote:s0"

static u32 ksu_domain_sid;
static int ksu_domain_state; /* 0 = lookup pending, 1 = ok, -1 = failed */
static u32 zygote_domain_sid;
static int zygote_domain_state;

/*
 * Read the current task's SELinux SID directly from its cred security blob.
 * On 4.9, task_sid()/current_sid() are static inlines local to
 * security/selinux/hooks.c, so we use current_security() here instead
 * (same pattern as sucompat.c's cred checks).
 */
static u32 dfg_current_sid(void)
{
	const struct task_security_struct *tsec = current_security();

	return tsec->sid;
}

static u32 domain_sid_cached(const char *domain, u32 *sid, int *state)
{
	u32 found = 0;

	if (*state == 1)
		return *sid;
	if (*state == -1)
		return 0;

	if (security_secctx_to_secid(domain, strlen(domain), &found) || !found) {
		*state = -1;
		return 0;
	}

	*sid = found;
	*state = 1;
	return found;
}

bool susfs_is_current_ksu_domain(void)
{
	u32 sid = domain_sid_cached(KSU_SU_DOMAIN, &ksu_domain_sid,
				    &ksu_domain_state);

	if (!sid)
		return false;

	return dfg_current_sid() == sid;
}

bool susfs_is_current_zygote_domain(void)
{
	u32 sid = domain_sid_cached(ZYGOTE_DOMAIN, &zygote_domain_sid,
				    &zygote_domain_state);

	if (!sid)
		return false;

	return dfg_current_sid() == sid;
}

extern int path_umount(struct path *path, int flags);

void ksu_try_umount(const char *mnt, bool check_mnt, int flags,
		    uid_t __maybe_unused uid)
{
	struct path path;
	int err;

	if (!mnt)
		return;

	err = kern_path(mnt, LOOKUP_FOLLOW, &path);
	if (err) {
		pr_debug("ksu_try_umount: kern_path('%s') failed: %d\n", mnt,
			 err);
		return;
	}

	if (check_mnt && path.dentry != path.mnt->mnt_root) {
		/* not a mountpoint - nothing to unmount here */
		path_put(&path);
		return;
	}

	/* path_umount() consumes the dentry/mnt references itself */
	err = path_umount(&path, flags);
	if (err)
		pr_debug("ksu_try_umount: '%s' failed: %d\n", mnt, err);
	else
		pr_info("ksu_try_umount: '%s' unmounted\n", mnt);
}
