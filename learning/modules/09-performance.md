# Module 09 — Performance engineering

Prerequisite: Module 08. Correctness remains required; no speedup is presumed. Native measurements must be made on the learner's Mac. A slower experiment can be a successful lesson if it is measured, explained, and not installed as an unjustified default. Checks and questions follow the whole lesson.

## M09-L01 — Build a trustworthy benchmark

**Outcome:** measure processing separately from decoding, allocation, and output.

### Explanation and supplied timer

Timing one tiny call mostly measures overhead and noise. Run batches long enough to produce stable samples, warm up first, and repeat. A monotonic clock measures elapsed intervals without wall-clock adjustments. Keep allocation, file handling, output, and result verification outside the timed region.

```swift
import Dispatch

func timedBatch(iterations: Int, _ operation: () -> Void) -> UInt64 {
    precondition(iterations > 0)
    let start = DispatchTime.now().uptimeNanoseconds
    for _ in 0..<iterations { operation() }
    let end = DispatchTime.now().uptimeNanoseconds
    return end - start
}
```

The closure parameter lets this helper call an already-prepared operation repeatedly. Borrow input/output storage outside timing where possible so you measure the kernel, and separately measure the public wrapper when interested in real API cost. Consume a checksum of the output after timing and print it; also inspect optimized code later to ensure work was retained. A checksum is evidence of output use, not proof that the compiler preserved every intended operation.

### Your implementation

Create a `--bench` mode and `bench/README.md`. Record hardware as reported locally, OS, toolchain, build flags, image dimensions, stride, operation parameters, warm-up, batch size, sample count, and checksum. Use at least seven samples and report median plus range or interquartile range. Aim for measured batches around 50–200 ms without making this a rigid pass gate; increase iterations based on an initial calibration.

Start with inversion because repeated in-place operations remain controlled. Restore input outside each timed batch if required by another operation. Use release builds. Do not run under LLDB for timing. Avoid assuming fixed CPU frequency, core assignment, or a particular number of performance cores.

### After completing the whole lesson

**Checks:** output correctness checked outside timing; no file I/O/allocation in the intended kernel interval; consistent units; repeated runs produce interpretable distributions; an empty or trivial timed body helps identify overhead. Save raw samples, not just the fastest run.

**Questions:** Why use batches and a monotonic clock? Why distinguish wrapper cost from kernel cost? Why might repeated brightness operations change the workload? What does a checksum fail to prove?

**Completion rubric:** reproducible harness, relevant metadata, raw samples, output validation, and clearly delimited timed work. Commit: `M09-L01: benchmark processing reproducibly`.

## M09-L02 — Compare implementations and inspect compiler output

**Outcome:** explain measured differences among scalar assembly, NEON, and optimized Swift.

### Explanation and worked workflow

A high-level loop can compile to vector instructions. 'Swift baseline' does not mean 'scalar baseline'. Compare equivalent algorithms, input sizes, bounds, rounding, and alpha handling. Label an end-to-end wrapper comparison separately from a pointer-kernel comparison.

```bash
bash build.sh release
xcrun nm .build/pixel
xcrun otool -tvV .build/pixel
```

Use LLDB's function disassembly if that is easier to read; collect timings outside the debugger. For Swift, isolate the baseline in a clearly named function and inspect the linked machine code or compiler assembly output. Compiler-generated symbols may be mangled; use `xcrun swift-demangle` to interpret them. Do not assume a source loop maps to a particular instruction sequence without examining it.

### Your implementation

Provide optimized Swift baselines for inversion and grayscale using the same mathematical contracts. The tutor supplies a straightforward typed-buffer version and explains any pointer syntax. Compare at least a tiny image, a medium image, and a large image. Keep identical data and operation parameters. Report ns/pixel and active-byte throughput with formulas and units, distinguishing active input/output bytes from total memory-system traffic.

Annotate a short relevant disassembly excerpt: loop, loads/stores, arithmetic, and tail if visible. Explain one surprising result, including the possibility that Swift equals or beats handwritten code. Do not call different output semantics a speedup.

### After completing the whole lesson

**Checks:** all baselines pass the same known-answer suite; timing conditions match; the report identifies actual observed vectorization rather than guessing; evidence includes command, binary revision, and metadata.

**Questions:** Why can optimized Swift use SIMD? Why is a tiny-image result not representative of all sizes? How can wrapper overhead hide kernel improvements? Why inspect the executable actually benchmarked?

**Completion rubric:** fair three-way comparison, code inspection, correct units, and no predetermined performance conclusion. Commit: `M09-L02: compare compiler and handwritten kernels`.

## M09-L03 — Unroll with a hypothesis

**Outcome:** test whether processing more independent work per loop improves a specific kernel.

### Explanation and worked idea

A processor can overlap independent instructions, but an instruction needing a previous result must wait for that dependency. Loop unrolling can reduce branch overhead and expose independence. It also increases code size and consumes registers. More unrolling is not always faster.

For a reduction, one accumulator forms a long add chain. Several accumulators can process separate groups, then combine at the end:

```asm
// Fragment after independent block reductions:
// x4...x7 are four partial uint64 totals; x8...x11 hold new sums.
add x4, x4, x8
add x5, x5, x9
add x6, x6, x10
add x7, x7, x11
// Combine only after the main loop, with validated total range.
```

For inversion, independent loads/XOR/stores may offer a simpler unrolling experiment. Choose one hypothesis and change one main variable at a time. Avoid using X18 or ABI-preserved registers without saving them. Extra save/restore overhead can dominate small calls.

### Your implementation

Create a separately named 2x or 4x unrolled variant of inversion or sum-red. Preserve the original. Document the dependency you intend to shorten or overhead you intend to reduce. Keep a correct vector remainder loop and scalar tail. Compare several image sizes using the established harness; inspect instruction count/register use and note whether spills or extra preserved-register saves appear.

### After completing the whole lesson

**Checks:** exact correctness suite, all new block-boundary counts, zero/tiny cases, ABI state preservation, repeated benchmark samples. Report regressions as well as gains. Select a new default only if the evidence supports it for the intended workload.

**Questions:** How do independent accumulators differ from repeatedly updating one? What costs can unrolling add? Why test lengths just below the new block size? Why might a large-image gain hurt small images?

**Completion rubric:** explicit hypothesis, isolated variant, correct remainder paths, reproducible result, and a justified adoption decision. Commit: `M09-L03: evaluate loop unrolling`.

## M09-L04 — Memory traffic and cache locality

**Outcome:** distinguish arithmetic limits from data movement and working-set effects.

### Explanation and experiment design

An inversion reads and writes active pixels. A multi-pass filter also writes and rereads temporary buffers. These algorithms can spend more time moving data than performing arithmetic. Caches retain recently accessed data, so repeatedly processing one small image differs from rotating through several large images.

Do not label a workload 'cold cache' merely because it is large. Construct and report concrete policies: repeatedly process one buffer, or rotate through N independent buffers with a stated total size. Never invent cache capacity or bandwidth for the learner's chip. Measured throughput is an observation under a workload, not a guaranteed hardware peak.

### Your implementation

Benchmark at least three dimensions spanning small and large working sets, two legal strides, and both buffer-reuse policies. Measure inversion, two-pass blur, and one memory-copy baseline with equivalent accounting where appropriate. Count algorithmic bytes read/written per active pixel, explicitly noting that actual cache-line traffic may differ.

Try one justified locality change, such as retaining only three horizontal-sum rows in a ring buffer for blur instead of the entire H image. For correctness, row buffers must stay alive until the vertical pass consumes them; global top/bottom replication still applies. This experiment prepares the next module's tile discussion. Preserve a straightforward full-H version as an oracle.

### After completing the whole lesson

**Checks:** all modified algorithms match references; ring reuse does not overwrite a still-needed row; reported storage accounting is correct; raw timing samples include workload policy; stride changes do not alter active pixels.

**Questions:** Why can repeated small images look much faster per pixel? What distinguishes active-byte throughput from memory-bus traffic? How can reducing temporary storage improve performance? What dependency determines when a row buffer can be reused?

**Completion rubric:** controlled memory experiments, honest terminology, correct locality variant, and evidence-based explanation. Commit: `M09-L04: measure and improve memory locality`.

## M09-L05 — Fuse operations without changing semantics

**Outcome:** remove intermediate image traffic while preserving operation order and quantization.

### Explanation and worked example

Two pointwise stages may share one load and store. For example, invert followed by brightness computes `clamp((255-c)+delta,0,255)`. Brightness followed by invert computes `255-clamp(c+delta,0,255)` and can differ: for c=250,delta=20, the results are 25 and 0 respectively. Fusion must preserve order, not simply combine operation names.

```asm
// Fragment for positive delta only: v0=RGBA bytes,
// v1=RGB inversion mask, v2=[delta,delta,delta,0] repeated.
eor v0.16b, v0.16b, v1.16b
uqadd v0.16b, v0.16b, v2.16b
```

Use the negative-delta saturation path when needed. Each vector block now pays one load/store pair instead of two. If a stage has intermediate rounding, retaining wider values across stages could change output; an equivalent fused kernel must preserve the original rounding points unless offered under a separate contract.

### Your implementation

Implement `invert_then_brightness_row_neon` with full parameter validation, alpha preservation, and arbitrary-length tails. Compare it byte-for-byte against the sequential pipeline. Add a minimal dispatch rule that selects this fused implementation only for the exact supported ordered pair. Unsupported sequences continue through ordinary stages.

Benchmark total pipeline time and memory footprint, not just the inner arithmetic fragment. Include small and large images. Retain the simple sequential path for debugging and as a reference.

### After completing the whole lesson

**Checks:** all deltas and endpoint channels; alpha/padding; reordered-operation counterexample; fused/unfused exact equality; benchmark includes the complete supported pair and labels allocation policy.

**Questions:** Why does operation order matter? What prevents arbitrary fusion across filters? Why can deferring rounding change semantics? Why might fusion outperform instruction-level tuning?

**Completion rubric:** semantics-preserving fusion, narrow dispatch rule, retained reference, and measured pipeline benefit or documented lack of it. Commit: `M09-L05: fuse a measured pointwise pipeline`.

## Module references

- [Testing and performance reference](../reference/testing-and-performance.md)
- [Assembly/ABI reference](../reference/assembly-and-abi.md)
- [Official tool documentation](../reference/resources.md)
