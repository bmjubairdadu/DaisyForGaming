import re

# sched.h: remove susfs fields block
p = "/mnt/d/DaisyForGaming/include/linux/sched.h"
src = open(p, encoding="utf-8", errors="surrogateescape").read()
pat = re.compile(r"#ifdef CONFIG_KSU_SUSFS\n\tu64 susfs_task_state;\n\tu64 susfs_last_fake_mnt_id;\n#endif\n")
src, n = pat.subn("", src)
open(p, "w", encoding="utf-8", errors="surrogateescape", newline="").write(src)
print("sched.h fixed:", n)

# Delete sus_su.h
import os
p = "/mnt/d/DaisyForGaming/include/linux/sus_su.h"
if os.path.exists(p):
    os.remove(p)
    print("sus_su.h deleted")
