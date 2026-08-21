.. SPDX-License-Identifier: GPL-2.0

=====================================
DaisyForGaming control interface (DFG)
=====================================

The DFG driver exposes a runtime control interface for the
DaisyForGaming kernel at ``/sys/devices/platform/dfg/``.  It is
enabled with ``CONFIG_DFG`` and is available on the Xiaomi Mi A2 Lite
(daisy, msm8953).

Files
=====

``profile`` (rw)
  Selects the active profile.  Valid values: ``performance``,
  ``balanced``, ``battery``.  Applying a profile sets the per-policy
  CPU frequency limits, the cpufreq governor, and the boot-disk I/O
  scheduler, then re-applies the thermal caps.

  Default: controlled by ``CONFIG_DFG_DEFAULT_PERF`` (``performance``
  when enabled, ``balanced`` otherwise).

``cpu_min_freq``, ``cpu_max_freq`` (rw)
  Desired minimum/maximum CPU frequency in kHz, applied to every
  cpufreq policy.  Values are validated against the frequency table at
  apply time.

``governor`` (rw)
  Name of the cpufreq governor to apply to every policy.  Read returns
  the governor currently active on CPU0.

``io_scheduler`` (rw)
  Name of the block I/O scheduler to apply to the boot disk
  (``mmcblk0``).  Read returns the current scheduler and the compiled-in
  alternatives.

``thermal_override`` (rw)
  Boolean.  When ``1``, the soft thermal limit is lifted so the
  performance profile is kept above the soft threshold.  The hard limit
  can never be lifted: once exceeded, the driver forces the safe
  frequency caps and resets this flag.  Writes are refused (``-EPERM``)
  while the hard limit is active or on unsupported platforms.

``boost_ms`` (rw)
  Duration in milliseconds (0-60000) of a one-shot boost that raises
  the CPU min frequency to the policy maximum for the given duration.
  ``0`` cancels.  Boost is refused while the hard thermal limit is
  active.

``deep_idle`` (rw)
  Boolean.  When ``1``, cpuidle is disabled on every online CPU (no
  deep sleep states; removes wake-up jank at the cost of battery).
  Only meaningful with ``CONFIG_CPU_IDLE``.

``thermal_events`` (ro)
  Ring buffer of the last 16 thermal events, newest first.  Each line:
  ``<seconds> <zone> <temp_milliC> <action>``.  Actions:
  ``THROTTLE``, ``OVERRIDE_ACTIVE``, ``HARD_LIMIT``,
  ``OVERRIDE_RESET``, ``OVERRIDE_DENIED``, ``RECOVER``, ``PROFILE``,
  ``BOOT_PERF``, ``VENDOR_FALLBACK``.

``thermal_limits`` (ro)
  Effective soft/hard limits, safe caps, hysteresis, sample period,
  current state (``ok``/``throttled``/``hard-limit``), current maximum
  temperature and override flag.

``vendor_compat`` (ro)
  Result of the platform runtime check.  ``ok: <compatible>`` on
  supported platforms (``qcom,msm8953`` / ``qcom,msm8937`` families);
  ``fallback: <compatible>`` otherwise, in which case the driver locks
  to the balanced profile and refuses ``performance`` and
  ``thermal_override`` writes.

Access control
==============

All write nodes are owned by root (mode ``0644``).  Writes from
unprivileged processes are rejected by the kernel.  The DFG-Controller
app runs under a dedicated SELinux domain ``dfg_controller_app`` (see
``sepolicy/dfg_controller.te``) which is granted write access to the
``sysfs_dfg`` file type.

Example
=======

.. code-block:: sh

   # apply the performance profile
   echo performance > /sys/devices/platform/dfg/profile

   # raise the CPU floor manually
   echo 1612800 > /sys/devices/platform/dfg/cpu_min_freq

   # switch the boot disk to the noop scheduler
   echo noop > /sys/devices/platform/dfg/io_scheduler

   # one-shot 5 second boost
   echo 5000 > /sys/devices/platform/dfg/boost_ms

   # lift the soft thermal cap (hard cap still enforced)
   echo 1 > /sys/devices/platform/dfg/thermal_override

   # inspect the last thermal events
   cat /sys/devices/platform/dfg/thermal_events