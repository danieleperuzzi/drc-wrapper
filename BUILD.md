# Build & Packaging Guide

This document explains how to build Debian (`.deb`) and Arch Linux (`.pkg.tar.zst`) packages for `drcwrapper` both locally and via the automated GitHub Actions CI/CD pipeline.

---

## Directory Structure Overview

```text
.
├── .github/
│   └── workflows/
│       └── build-packages.yml # GitHub Actions workflow
├── Arch/
│   └── AUR/
│       ├── PKGBUILD.template  # Template for local and CI/CD builds
│       └── PKGBUILD.aur       # Template for official AUR releases
├── DEBIAN/
│   ├── control.template       # Control file template
│   ├── postinst.template      # Post-installation hook
│   └── postrm.template        # Post-removal hook
├── build_arch.sh              # Local Arch Linux packaging script
├── build_deb.sh               # Local Debian packaging script
├── drcwrapper                 # Main wrapper executable
├── LICENSE                    # Software license
└── README.md                  # Project documentation
```

---

## Prerequisites

### For Debian/Ubuntu Packaging:
* `dpkg-deb` (part of `dpkg`)
* `bash`
* `sed`

### For Arch Linux Packaging:
* `pacman` and `base-devel` package group (provides `makepkg` and `fakeroot`)
* `bash`
* Non-root shell execution (`makepkg` strictly forbids running as `root`)

---

## Local Building

### 1. Debian Package (`.deb`)

To build a `.deb` package locally, execute `build_deb.sh` and pass the target version as an argument:

```bash
chmod +x build_deb.sh
./build_deb.sh 1.0.0-1
```

**What the script does:**
1. Validates the version parameter input.
2. Constructs a staging directory (`build_staging/`).
3. Replaces `__DEB_VERSION__` in `DEBIAN/control.template` using `sed` to generate `DEBIAN/control`.
4. Copies `drcwrapper` to `usr/local/bin/drcwrapper` inside the staging tree.
5. Enforces standard POSIX executable permissions (`755`).
6. Executes `dpkg-deb --root-owner-group --build` to create `drcwrapper_1.0.0-1_all.deb`.
7. Cleans up the temporary staging directory.

---

### 2. Arch Linux Package (`.pkg.tar.zst`)

To build an Arch package locally, execute `build_arch.sh` and pass the target version:

```bash
chmod +x build_arch.sh
./build_arch.sh 1.0.0
```

**What the script does:**
1. Validates the version parameter input.
2. Constructs a staging directory (`build_arch_staging/`).
3. Injects the version number replacing `__PKGVER__` in `Arch/AUR/PKGBUILD.template`.
4. Runs `makepkg -cd --nodeps` inside the staging folder.
5. Moves the compiled `drc-wrapper-1.0.0-1-any.pkg.tar.zst` artifact to the repository root.
6. Cleans up the staging directory.

---

## CI/CD Pipeline (GitHub Actions)

Automated package compilation is managed by `.github/workflows/build-packages.yml`.

### Triggers & Version Calculation

The workflow triggers on three events:
1. **Push to `main` branch:**
   * Generates dev build artifacts.
   * Versioning assigned: `1.0.0-dev-1` (`.deb`) and `1.0.0.dev` (`.pkg.tar.zst`).
2. **Push of Git Tags (`v*`):**
   * Triggers official release packaging (e.g., tag `v1.0.0` strips the `v` prefix to pass `1.0.0` to the build scripts).
   * Generates production packages and creates an official **GitHub Release** with the artifacts attached.
3. **Manual Trigger (`workflow_dispatch`):**
   * Allows manually specifying a custom version string via the GitHub Actions web interface.

### How the Pipeline Works

* **Debian Job:**
  Runs on `ubuntu-latest`, executes `./build_deb.sh <version>`, and uploads the `.deb` file using `actions/upload-artifact@v4`.
* **Arch Linux Job:**
  Runs in an official `archlinux:latest` Docker container, creates an unprivileged `builder` user to comply with `makepkg` safety requirements, executes `./build_arch.sh <version>`, and uploads the `.pkg.tar.zst` file.
* **Release Job (Tags Only):**
  Downloads both build artifacts and publishes a GitHub Release using `softprops/action-gh-release@v2`.

---

## AUR (Arch User Repository) Publishing

The `Arch/AUR/PKGBUILD.aur` template is dedicated for publishing to the official AUR repository (`https://aur.archlinux.org/drc-wrapper.git`).

Unlike the CI/CD template, `PKGBUILD.aur` uses remote HTTPS git tagging to pull sources directly from GitHub:

```bash
source=("${pkgname}::git+https://github.com/danieleperuzzi/drc-wrapper.git#tag=v${pkgver}")
```

When releasing a new version on AUR:
1. Copy `Arch/AUR/PKGBUILD.aur` to your local clone of the AUR git repo.
2. Update `pkgver` to match the released tag.
3. Update `.SRCINFO` using `mksrcinfo`.
4. Commit and push to `aur.archlinux.org`.