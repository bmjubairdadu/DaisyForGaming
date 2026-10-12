import re
files=['fs/namei.c','fs/namespace.c','fs/dcache.c','fs/stat.c','fs/readdir.c',
'fs/proc/fd.c','fs/proc/task_mmu.c','fs/overlayfs/inode.c','fs/overlayfs/readdir.c',
'fs/overlayfs/super.c','fs/overlayfs/overlayfs.h','fs/proc_namespace.c',
'fs/statfs.c','fs/notify/fdinfo.c','kernel/kallsyms.c','kernel/sys.c',
'include/linux/mount.h','include/linux/sched.h']
bad=0
for f in files:
    lines=open("/mnt/d/DaisyForGaming/"+f,encoding="utf-8",errors="surrogateescape").read().split("\n")
    depth=0
    for i,l in enumerate(lines,1):
        m=re.match(r"^\s*#\s*(if|ifdef|ifndef|endif)\b",l)
        if m:
            k=m.group(1)
            if k in ("if","ifdef","ifndef"): depth+=1
            elif k=="endif": depth-=1
            if depth<0:
                print(f,"NEGATIVE at",i); bad+=1; depth=0
    if depth!=0:
        print(f,"UNBALANCED depth",depth); bad+=1
print("pp check bad=%d"%bad)
