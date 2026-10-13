import re

# ============ Patch A: MainViewModel.kt ============
f = r"D:\DFG-Controller\app\src\main\java\com\dfgcontroller\ui\MainViewModel.kt"
raw = open(f, "rb").read().decode("utf-8")
nl = "\r\n" if "\r\n" in raw else "\n"

# A1: replace single cleanerBusy with 5 individual busy flows
old_decl = (
    "    private val _cleanerBusy = MutableStateFlow(false)\n"
    "    val cleanerBusy: StateFlow<Boolean> = _cleanerBusy.asStateFlow()\n"
).replace("\n", nl)
new_decl = (
    "    // Per-cleaner busy states: each RUN button tracks only its own job,\n"
    "    // so pressing one never lights up the others.\n"
    "    private val _ramCleanBusy = MutableStateFlow(false)\n"
    "    val ramCleanBusy: StateFlow<Boolean> = _ramCleanBusy.asStateFlow()\n"
    "    private val _appCacheCleanBusy = MutableStateFlow(false)\n"
    "    val appCacheCleanBusy: StateFlow<Boolean> = _appCacheCleanBusy.asStateFlow()\n"
    "    private val _junkFilesCleanBusy = MutableStateFlow(false)\n"
    "    val junkFilesCleanBusy: StateFlow<Boolean> = _junkFilesCleanBusy.asStateFlow()\n"
    "    private val _deepRamCleanBusy = MutableStateFlow(false)\n"
    "    val deepRamCleanBusy: StateFlow<Boolean> = _deepRamCleanBusy.asStateFlow()\n"
    "    private val _deepJunkCleanBusy = MutableStateFlow(false)\n"
    "    val deepJunkCleanBusy: StateFlow<Boolean> = _deepJunkCleanBusy.asStateFlow()\n"
).replace("\n", nl)
assert old_decl in raw, "cleanerBusy decl not found"
raw = raw.replace(old_decl, new_decl)

# A2: map each function's _cleanerBusy writes to its own flow
func_map = {
    "fun cleanRam(": "_ramCleanBusy",
    "fun cleanAppCaches(": "_appCacheCleanBusy",
    "fun deepCleanRam(": "_deepRamCleanBusy",
    "fun deepCleanJunk(": "_deepJunkCleanBusy",
    "fun cleanJunkFiles(": "_junkFilesCleanBusy",
}
lines = raw.split(nl)
current_flow = None
replaced = 0
for i, ln in enumerate(lines):
    for sig, flow in func_map.items():
        if sig in ln:
            current_flow = flow
    if "_cleanerBusy.value" in ln and current_flow:
        indent = ln[: len(ln) - len(ln.lstrip())]
        val = "true" if ".value = true" in ln else "false"
        lines[i] = f"{indent}{current_flow}.value = {val}"
        replaced += 1
raw = nl.join(lines)
assert "_cleanerBusy" not in raw, "leftover _cleanerBusy references"
open(f, "wb").write(raw.encode("utf-8"))
print("MainViewModel: cleaner flows split, replaced =", replaced)

# A3: gate the "Applying saved profile..." popup to first-run only
f2 = f  # same file
raw = open(f2, "rb").read().decode("utf-8")
old_init = (
    "    fun initializeKernelInterface() {\n"
    "        viewModelScope.launch {\n"
    "            _isApplyingProfile.value = true\n"
    "            showStatus(\"Initializing Interface...\")\n"
    "            delay(1000)\n"
).replace("\n", nl)
new_init = (
    "    fun initializeKernelInterface() {\n"
    "        viewModelScope.launch {\n"
    "            val firstRunNow = repository.firstRun.first()\n"
    "            _isFirstRun.value = firstRunNow\n"
    "            // The \"Applying saved profile...\" card is a FIRST-TIME-SETUP\n"
    "            // indicator only. Later app opens initialize silently.\n"
    "            if (firstRunNow) _isApplyingProfile.value = true\n"
    "            showStatus(\"Initializing Interface...\")\n"
    "            delay(1000)\n"
).replace("\n", nl)
assert old_init in raw, "initializeKernelInterface head not found"
raw = raw.replace(old_init, new_init)

# the tail of initializeKernelInterface: gate the second set too.
# It's the block ending with: _isApplyingProfile.value = false\n showStatus("System Ready ...
old_tail = (
    "            loadInitialData()\n"
    "            startMemoryPolling()\n"
    "            startLogPolling()\n"
    "\n"
    "            _isApplyingProfile.value = false\n"
    "            showStatus(\"System Ready (${_kernelModeLabel.value}).\")\n"
).replace("\n", nl)
new_tail = (
    "            loadInitialData()\n"
    "            startMemoryPolling()\n"
    "            startLogPolling()\n"
    "\n"
    "            if (firstRunNow) _isApplyingProfile.value = false\n"
    "            showStatus(\"System Ready (${_kernelModeLabel.value}).\")\n"
).replace("\n", nl)
assert old_tail in raw, "initializeKernelInterface tail not found"
raw = raw.replace(old_tail, new_tail)

# remove the now-duplicate firstRun read inside the body (it moved to the top)
old_dup = (
    "            val firstRun = repository.firstRun.first()\n"
    "            _isFirstRun.value = firstRun\n"
    "\n"
    "            loadInitialData()\n"
).replace("\n", nl)
new_dup = (
    "            loadInitialData()\n"
).replace("\n", nl)
assert old_dup in raw, "duplicate firstRun read not found"
raw = raw.replace(old_dup, new_dup)

open(f2, "wb").write(raw.encode("utf-8"))
print("MainViewModel: popup gated to first run")
