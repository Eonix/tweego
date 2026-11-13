# Building Tweego in Docker

## Requirements

Install Docker Desktop with its WSL 2 backend and use Linux containers. Docker must be running. The first build needs internet access to download the Go image and Go modules. Later builds reuse Docker's module and compiler caches.

No local Go SDK, C compiler, Node.js, or separately installed Go packages are needed. PowerShell is only a convenience wrapper; Docker can also be invoked directly.

The source declares Go 1.13 and five direct modules in `go.mod`: semver/v3, go-charset, watcher, x/net, and x/text. The container uses Go 1.26.9 on Debian Bookworm and disables CGO. Dependency versions remain those of the original source; this build setup does not upgrade them. `go.sum` records dependency checksums and is included in this setup; commit it alongside `go.mod`.

## Build a native Windows executable

From the repository root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build-container.ps1
$env:TWEEGO_PATH = 'C:\dev\projects\xgame\.tools\storyformats'
.\dist\windows-amd64\tweego.exe --version
```

Upstream `--version` prints to stderr and exits with code 1 even on success; use an actual story compilation for a success/failure smoke test.

The build downloads and verifies modules, runs `go test ./...` (including its default vet checks) on the container's native platform, then cross-compiles the requested executable. The original repository has no Go test files, so this checks compilation and vet rather than providing behavioral test coverage. The final Docker stage exports only the executable and the original BSD license to `dist/`; there is no long-running service.

Other targets:

```powershell
.\scripts\build-container.ps1 -TargetOS linux -TargetArch amd64
.\scripts\build-container.ps1 -TargetOS darwin -TargetArch arm64
```

Direct Docker equivalent (also usable from other shells):

```text
docker buildx build --platform windows/amd64 --target artifact --output type=local,dest=dist/windows-amd64 .
```

The builder runs Linux even for Windows/macOS output. Go performs cross-compilation; Windows containers and CPU emulation are unnecessary for these targets. Run target-platform smoke tests on that target OS after exporting.

## Compile a SugarCube game

Building Tweego does not bundle story formats. This upstream version searches for a story-format directory at startup, even for `--version`; set `TWEEGO_PATH` before running it. Point the executable at a SugarCube `format.js` directory when compiling a story. For the adjacent xgame project, after its setup script has run:

```powershell
$env:TWEEGO_PATH = 'C:\dev\projects\xgame\.tools\storyformats'
.\dist\windows-amd64\tweego.exe -f sugarcube-2 -o .\dist\xgame.html C:\dev\projects\xgame\src
```

The executable runs directly on Windows with no Go installation or Docker dependency at runtime. xgame's existing build script continues to use its own downloaded compiler until deliberately switched.

## Maintaining the environment

The Dockerfile pins the Go image version tag. Tags can be rebuilt upstream; for stricter byte-for-byte toolchain pinning, use an approved image digest in `GO_IMAGE`. Update the tag deliberately as Go receives fixes.

If you deliberately change dependencies, regenerate checksums inside the same container toolchain (PowerShell, from the repository root):

```powershell
docker run --rm --mount "type=bind,source=$($PWD.Path),target=/src" --workdir /src golang:1.26.9-bookworm go mod download all
```

Review both `go.mod` and `go.sum` before committing. This command writes checksums to the checkout; ordinary Docker builds copy the source into the builder and leave source files unchanged. Cached downloads live in Docker storage. Existing upstream module names are retained so internal imports continue to work.
