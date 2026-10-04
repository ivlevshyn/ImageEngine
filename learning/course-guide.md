# Course guide and shared project contracts

## How the project grows

You build a command-line image engine, provisionally named `pixel`. Swift provides file handling, bounded storage, argument parsing, test fixtures, and eventually work scheduling. Standalone `.s` files implement image operations. A small C header exposes those functions to Swift. C declarations describe a boundary; you are not required to implement a C application.

Start with direct compiler commands so each build stage is visible. A `build.sh` script is introduced as a learner-created project file. Keep this simple build throughout the course; moving to Swift Package Manager later is optional, not a prerequisite. All commands run at the repository root. Names and paths below are conventions the course uses consistently; adapt transparently if your existing project has equivalents.

| Learner-created path | Introduced | Purpose |
| --- | --- | --- |
| `src/asm/pixel.s` | M01 | Small assembly functions; later split into scalar/neon/filter files. |
| `src/bridge/Pixel.h` | M01 | Fixed-width C function declarations imported by Swift. |
| `src/swift/main.swift` | M01 | Entry point and initial checks. |
| `src/swift/Image.swift` | M02 | Image dimensions, stride, owned bytes, checked wrappers. |
| `src/swift/PPM.swift` | M02 | Small P6 reader/writer. |
| `src/swift/Checks.swift` | M02 | Test helpers and fixtures; used by `--self-test`. |
| `build.sh` | M02 | Reproducible debug/release builds. |
| `tests/fixtures/` | M02 | Tiny generated images and exact expected bytes. |
| `tests/results/` | As needed | Small text evidence, not compiled binaries. |
| `bench/` | M09 | Benchmark configuration, results, and method notes. |
| `docs/` | M10 | Your project API and release documentation. |

The delivered ZIP creates none of these implementation files. Lessons contain the code and instructions you use to create them. Put `.build/` and generated large images in your own `.gitignore` when first introduced. Keep source, tests, small fixtures, and meaningful benchmark records in Git.

## Working image representation

The main byte format is **RGBA8, interleaved**, top row first, left to right. One pixel is four consecutive bytes R, G, B, A. A row has `width * 4` active bytes and may have additional padding up to `stride`. Pixel `(x,y)` begins at `base + y*stride + 4*x`. Padding is not image content and must remain untouched unless an operation explicitly owns it.

An integer used to pack those bytes on the little-endian target is `0xAABBGGRR`. For example bytes `[0x11,0x22,0x33,0x44]` correspond to integer `0x44332211`. Hexadecimal formatting of an integer and order of bytes in memory are different views. `UInt8` is a channel, `UInt32` is a packed pixel when declared as such, and counts/strides crossing the C boundary are `uint64_t`/Swift `UInt64`.

Images initially have opaque alpha 255. Straight alpha is the default storage representation when transparency is introduced. Premultiplied data always has a separately named conversion/API or is a documented I/O temporary; never silently mix the two. Early color/filter assignments operate on opaque images or have an explicit alpha policy. RGB code values initially use the course's simplified encoded-value interpretation. M08-L05 adds an explicit sRGB-to-linear path; early blur is not claimed to be physically accurate light mixing. PPM output is a restricted 8-bit P6 teaching subset with untagged RGB; do not claim full color-managed Netpbm support.

## Dimension, bounds, and ownership contract

Swift public wrappers reject negative dimensions, invalid parameters, and overflow before converting to unsigned C arguments. Use `multipliedReportingOverflow` and `addingReportingOverflow` rather than computing a dangerous expression and validating afterward. Require `stride >= width*4`, storage for `stride*height`, and both products to fit Swift `Int` and the array's valid allocation. Some operations use tighter limits stated in their lessons.

Zero-width or zero-height images are valid no-ops for pointwise operations; they must not dereference a pointer. File decoders and resize reject empty images. A nil base address for an empty Swift buffer is therefore never force-unwrapped before an empty check. The project limits decoded dimensions to 16,384 per axis and total RGBA storage to 256 MiB by default; later benchmarks may explicitly allocate larger validated synthetic images. These are project resource policies, not CPU limitations.

Swift owns allocation initially and for most of the course. Assembly receives borrowed pointers valid only during the synchronous call. It must not save them globally, free them, or use them later. Distinct input/output image operations use disjoint storage unless the lesson explicitly permits identical storage. Partial overlap is forbidden unless an algorithm is specifically designed for it. A Swift wrapper may guarantee this by allocating the destination itself, rather than by attempting arbitrary pointer comparisons.

The C boundary is a trusted internal interface: assembly relies on validated size/allocation relationships, but its loops must still honor the supplied active sizes and handle zero counts correctly. Document caller obligations beside each declaration. Memory safety is shared responsibility, not automatic protection from using Swift.

## Numerical conventions

- RGB inversion: `255 - c`; alpha unchanged.
- Brightness: `clamp(c + delta, 0, 255)`, `delta` integer in `[-255,255]`.
- Grayscale: `(77*R + 150*G + 29*B + 128) >> 8`, repeated in RGB; alpha unchanged.
- Contrast: `clamp(((Int32(c)-128)*factorQ8 + 32768 + 128) >> 8, 0, 255)` with arithmetic signed shift; factorQ8 in `[0,1024]`. This defines tie handling exactly.
- Constant blend: `((256-t)*a + t*b + 128) >> 8`, `t` integer in `[0,256]`; RGB only, opaque input/output for its first version.
- Straight-alpha foreground over opaque background: RGB `(fg*alpha + bg*(255-alpha) + 127)/255`, integer floor division; output alpha 255. General translucent-background compositing is an optional extension.
- Filter border: replicate the nearest edge pixel unless a lesson explicitly declares another policy.
- Integer optimized versions are byte-exact. Floating results require declared tolerances; no global 'approximately equal' waiver.

These are course choices. [Image mathematics](reference/image-math.md) explains the reasons and useful invariants. A performance optimization cannot silently change them.

## Testing and review cadence

Lessons include build/run instructions as part of implementation, but all required checks, comprehension questions, and assessment occur after the full lesson. No hidden intermediate gates. Preserve earlier checks and run relevant regressions when shared functions change. `--self-test` should exit nonzero on failure and print enough context to identify the input, expected result, and actual result.

Tests begin as plain Swift checks, with no testing framework prerequisite. Release-mode verification must not rely solely on `assert`, which may be removed by optimization. Use explicit failures such as `fatalError` in the course's small runner. At SIMD stages, compare scalar and vector results and independently verify selected hand-calculated cases. Random tests use a recorded deterministic seed.

Every lesson has an end section covering checks, questions, and a completion rubric. Save answers in a learner-created `learning/answers/Mxx-Lyy.md` if convenient, or provide them in the review message. This optional directory contains your learning notes, not generated implementation. A review is complete only when requirements, relevant runtime evidence, and understanding questions have been assessed.

## Time and scope

The nominal 1–2 hours refers to one lesson's guided work; tool installation and difficult debugging can exceed it. Advanced lessons are intentionally substantial. Tutors should supply more supporting code or explanation if Swift or mathematics is blocking assembly learning, while preserving all lesson requirements. Optional extensions are never required for progression.

Learn native macOS user-space code first. No direct Darwin syscalls, custom allocator, GPU framework, neural accelerator, SVE/SME, or handwritten thread scheduler is required. Parallelism is scheduled by Swift around synchronous assembly kernels. Additional ISA features are an optional post-course investigation after checking availability.

## Toolchain setup policy

Use Apple's installed development tools via `xcrun`; record `xcode-select -p`, `xcrun swiftc --version`, `xcrun clang --version`, `xcrun --show-sdk-version`, `uname -m`, and `sw_vers`. Baseline commands assume native `arm64` execution. If tools are missing, install/select an appropriate Xcode or Command Line Tools release for your OS using Apple's documented process. Do not guess a version number from the machine model. Tool upgrades are not required unless a concrete incompatibility is observed.

Examples are original teaching code. Official resources are linked in [resources](reference/resources.md). They define platform behavior; this guide defines our project behavior. Consult [validation notes](validation.md) before interpreting package checks as native Mac testing.
