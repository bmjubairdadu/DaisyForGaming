import re

# kallsyms.c: remove the "#else { ksu filter }" branch leftovers:
# pristine (pre-KSU): "} else\n\t\tseq_printf(...)"
# current after strip: "} else\n\n\t{\n\t\tif (strstr(...ksu_...)) {\n\t\t\treturn 0;\n\t\t}\n\t\tseq_printf(...)\n\t}"
p = "/mnt/d/DaisyForGaming/kernel/kallsyms.c"
src = open(p, encoding="utf-8", errors="surrogateescape").read()

pat = re.compile(
    r"\t\} else\n\n\t\{\n\t\tif \(strstr\(iter->name, \"ksu_\"\).*?\n\t\t\}\n(\t\tseq_printf\(m, \"%pK %c %s\\n\", \(void \*\)iter->value,\n\t\t\t   iter->type, iter->name\);\n)\t\}",
    re.S)
src, n = pat.subn(lambda m: "\t} else\n" + m.group(1), src)
open(p, "w", encoding="utf-8", errors="surrogateescape", newline="").write(src)
print("kallsyms fixed:", n)
