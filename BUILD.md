# Build and Packaging Guide

This guide explains how to build Debian (`.deb`) and Arch Linux (`.pkg.tar.zst`) packages locally and through GitHub Actions.

## Current Structure

```text
.
├── .github/workflows/
│   ├── test.yml
│   └── build-packages.yml
├── Arch/AUR/
│   ├── PKGBUILD.template
│   └── PKGBUILD.aur
├── DEBIAN/
│   ├── control.template
│   ├── postinst
│   └── postrm
├── build_deb.sh
├── build_arch.sh
├── drcwrapper
├── README.md
└── BUILD.md
```

## Local Build Requirements

### Debian package
- `dpkg-deb`
- `bash`
- `sed`

### Arch package
- `makepkg` (from `base-devel`)
- `bash`
- `sed`
- Build must run as non-root user.

## Local Build Commands

### Build Debian package

```bash
chmod +x build_deb.sh
./build_deb.sh 1.0.0-1
```

Output example:

```text
drc-wrapper_1.0.0-1_all.deb
```

What `build_deb.sh` does:
1. Validates the version argument.
2. Creates `build_staging/` with Debian package layout.
3. Renders `DEBIAN/control` from `DEBIAN/control.template`.
4. Optionally includes `DEBIAN/postinst` and `DEBIAN/postrm` if present.
5. Installs `drcwrapper` in `/usr/bin` inside the package.
6. Installs docs (`README.md`, `BUILD.md`) and license.
7. Builds package with `dpkg-deb --root-owner-group --build`.
8. Cleans temporary staging directory.

### Build Arch package

```bash
chmod +x build_arch.sh
./build_arch.sh 1.0.0
```

Output example:

```text
drc-wrapper-1.0.0-1-any.pkg.tar.zst
```

What `build_arch.sh` does:
1. Validates the version argument.
2. Creates `build_arch_staging/`.
3. Renders `PKGBUILD` from `Arch/AUR/PKGBUILD.template`.
4. Runs `makepkg -cd --nodeps` in staging directory.
5. Moves generated `.pkg.tar.zst` back to repository root.
6. Cleans staging directory.

## GitHub Actions Workflows

### `.github/workflows/test.yml`
Single test workflow used both as:
1. regular CI entrypoint on push/pull_request/manual
2. reusable workflow via `workflow_call` from package build workflow

It performs:
1. `bash -n drcwrapper`
2. `shellcheck drcwrapper`
3. `./drcwrapper -h` and `./drcwrapper --help`
4. Real end-to-end run with files in `test/`
5. Output verification in generated `drc_out_*` directory.

### `.github/workflows/build-packages.yml`
Build and release workflow.

Triggers:
1. push on `main`
2. push on tags `v*`
3. manual dispatch with optional version input

Jobs:
1. `test`: runs tests from `test.yml`
2. `build-deb`: builds `.deb` via `build_deb.sh` and uploads artifact
3. `build-arch`: builds `.pkg.tar.zst` via `build_arch.sh` and uploads artifact
4. `release`: on tags only, downloads artifacts and publishes GitHub Release assets

Version strategy in CI:
1. Manual dispatch: uses input version.
2. Tag `vX.Y.Z`: uses `X.Y.Z`.
3. Push on main: uses development versions (`1.0.0-dev` for Debian path, `1.0.0.dev` for Arch path).

## AUR Publishing

`Arch/AUR/PKGBUILD.aur` is intended for AUR submissions and uses tagged GitHub source:

```bash
source=("${pkgname}::git+https://github.com/danieleperuzzi/drc-wrapper.git#tag=v${pkgver}")
```

Typical AUR release flow:
1. Update `pkgver` in `PKGBUILD.aur`.
2. Regenerate `.SRCINFO` with `makepkg --printsrcinfo > .SRCINFO`.
3. Commit and push to AUR repository.