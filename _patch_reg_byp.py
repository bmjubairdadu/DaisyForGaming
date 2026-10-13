f = r"D:\DFG-Controller\app\src\main\java\com\dfgcontroller\core\KernelTunable.kt"
raw = open(f, "rb").read().decode("utf-8")
nl = "\r\n" if "\r\n" in raw else "\n"
lines = raw.split(nl)

# remove the bypass_on_gaming tunable block: from 'id = "bypass_on_gaming"'
# backwards to the 'KernelTunable(' line, forwards through the closing '),'
start = end = -1
for i, l in enumerate(lines):
    if 'id = "bypass_on_gaming"' in l:
        # walk back to the KernelTunable( opener
        j = i
        while j >= 0 and "KernelTunable(" not in lines[j]:
            j -= 1
        start = j
        # walk forward to the closing '),'
        k = i
        while k < len(lines) and lines[k].strip() != "),":
            k += 1
        end = k
        break

if start >= 0 and end > start:
    # also drop a following blank line if present
    stop = end + 1
    if stop < len(lines) and lines[stop].strip() == "":
        stop += 1
    del lines[start:stop]
    open(f, "wb").write(nl.join(lines).encode("utf-8"))
    print("removed bypass_on_gaming tunable block")
else:
    print("bypass_on_gaming not found")
