# Release process (short form)

Full documentation: [RELEASE_PROCESS.md](RELEASE_PROCESS.md)

In short:

```bash
./scripts/release_kernel.sh
```

builds the kernel, packages the AnyKernel3 ZIP, computes SHA-256, creates
tag `kernel-v<version>-DaisyForGaming`, publishes the GitHub Release, and
updates + pushes `kernel_update.json`. It refuses to duplicate existing
tags/releases and never force-pushes.
