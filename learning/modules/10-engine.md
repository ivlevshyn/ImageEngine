# Module 10 — An integrated image-processing engine

Prerequisite: Module 09. This module combines existing algorithms with supplied/explained Swift systems scaffolding. It does not require designing a GUI or a threading runtime. Whole-lesson checks and questions remain at the end.

## M10-L01 — Plan and execute an image pipeline

**Outcome:** execute a requested sequence with validated parameters and reusable storage.

### Explanation and design

A pipeline is an ordered list of operations. Some work in place, some require distinct output, some change dimensions, and some require a different numerical representation. Treat these properties as explicit metadata rather than assumptions scattered through dispatch code. Planning validates the sequence and calculates working sizes before execution.

```swift
enum Operation {
    case invert
    case brightness(Int32)
    case grayscale
    case boxBlur3
    case resizeBilinear(width: Int, height: Int)
}
```

Associated values carry parameters for the relevant case. A `switch` handles every operation. The tutor supplies a small Swift executor skeleton and explains its control flow. Keep encoded RGBA8 and linear Float processing as explicitly separate modes; do not quietly insert or remove color conversions to satisfy a stage.

### Your implementation

Create a plan describing dimensions, representation, input/output aliasing, scratch size, and selected scalar/NEON/fused implementation for each stage. Reuse two image buffers in a ping-pong arrangement for disjoint-output stages, reallocating only when size/capacity requires it. Reuse scratch storage with checked capacity. In-place stages can keep the current buffer when contracts permit.

Support a small explicit CLI pipeline syntax documented by you, such as separate operation arguments parsed in Swift. Parsing is supplied scaffolding if needed. Keep a `--implementation scalar|neon` comparison mode; unsupported NEON stages may use a clearly reported scalar fallback. Reject incompatible parameters/representations before processing.

### After completing the whole lesson

**Checks:** empty pipeline is identity; a mixed sequence matches direct stage-by-stage execution; dimension changes update later strides/capacities; unsupported alpha/representation combinations reject; repeated executions do not retain stale data or pointers.

**Questions:** Why describe aliasing in the plan? When can scratch storage be reused? Why does operation order remain part of the contract? How should a missing optimized implementation be reported?

**Completion rubric:** explicit plan, correct execution, bounded reusable storage, truthful fallback selection, and reproducible CLI examples. Commit: `M10-L01: integrate image pipelines`.

## M10-L02 — Tiles and neighborhood halos

**Outcome:** process pieces of an image with results identical to whole-image execution.

### Explanation and worked example

A tile owns a rectangle of output. A pointwise stage reads that same rectangle. A radius-one blur additionally needs one source pixel around it, called a halo. At an internal tile boundary, the neighbor comes from the adjacent part of the original image; it is **not** an image edge. Replicating each tile's own edge creates seams.

For an output tile covering x=16…31 and y=8…15 in a larger image, blur needs source x=15…32 and y=7…16, clipped/replicated only at the global image boundary. Output writes remain restricted to the owned rectangle. For multiple neighborhood stages, required source regions can expand further; start by tiling one stage at a time.

### Your implementation

Introduce a tile descriptor with integer origin and size, all validated against global dimensions. Implement tiled inversion first, then tiled box blur. Pass global source dimensions/coordinates or prepare a correctly expanded local source view; document the choice. Use disjoint output for blur. Each tile gets its own temporary horizontal sums or an explicitly synchronized/reused workspace in serial execution.

Test tile sizes 1,3,8,31 and dimensions not divisible by them. Keep global strides when pointing into the original allocation. A tile's base pointer does not make its rows tightly packed. Use the untiled scalar and NEON versions as oracles.

### After completing the whole lesson

**Checks:** exact tiled/untiled equality; corner/edge tiles; a bright line crossing tile boundaries; partial last tiles; no duplicate or missing output pixels; sentinel/padding preservation. Show one halo calculation by hand.

**Questions:** Why are tile boundaries not image boundaries? Why does a view retain the parent stride? How do halos differ from owned output? How would two blur stages change required source coverage?

**Completion rubric:** correct coordinate model, halo semantics, complete nonoverlapping writes, and seam-free exact output. Commit: `M10-L02: tile pointwise and neighborhood operations`.

## M10-L03 — Schedule independent tiles safely

**Outcome:** run independent tile work concurrently while maintaining pointer lifetimes and disjoint writes.

### Explanation and supplied scheduling pattern

SIMD operates across lanes within a core; parallel scheduling assigns separate work to threads. These are independent levels. Parallel work is safe here when all workers read immutable source data, each writes a disjoint output rectangle, and each owns its scratch storage. Array value semantics alone do not establish this for raw pointers.

Use a synchronous parallel loop so all jobs finish before the buffer borrows end. The tutor must supply a concrete scheduling wrapper for the installed Swift compiler, explain Sendable checking, and never solve diagnostics by broadly disabling concurrency checks. This small pattern illustrates the boundary:

```swift
import Dispatch

// A narrowly scoped pointer carrier. The proof is in the surrounding wrapper:
// immutable source, disjoint destination tiles, no escape, synchronous join.
final class BorrowedTilePointers: @unchecked Sendable {
    let source: UnsafePointer<UInt8>
    let destination: UnsafeMutablePointer<UInt8>
    init(source: UnsafePointer<UInt8>, destination: UnsafeMutablePointer<UInt8>) {
        self.source = source
        self.destination = destination
    }
}
```

This class does not create safety. The unchecked annotation makes your proof obligation explicit. Construct it only inside nested source/destination buffer borrows. Use `DispatchQueue.concurrentPerform(iterations:)` inside those borrows, and let it return before leaving them. Capture immutable validated tile metadata, not the Swift arrays being borrowed. Do not let jobs enqueue asynchronous work that outlives the loop. If the learner prefers avoiding this unsafe carrier, the tutor can supply an owning buffer abstraction with the same documented guarantees.

### Your implementation

Parallelize tiled inversion, then blur with private per-job scratch. Use a bounded number of worker jobs that each process several tiles, rather than creating an unbounded worker abstraction. Keep a serial fallback for small workloads. Allocation of job scratch occurs before timing or is included explicitly as wrapper cost. Do not request core pinning or assume core types.

### After completing the whole lesson

**Checks:** exact serial/parallel results across job counts 1,2,3,4 and tile sizes; repeated runs; write-region proof; no retained pointers; all jobs complete before borrowed storage is released; compiler concurrency diagnostics addressed narrowly. Measure crossover and regressions.

**Questions:** Why must the parallel loop be synchronous here? What does `@unchecked Sendable` assert rather than prove? Why does shared scratch create a race? Why can correct disjoint writes still suffer false sharing or bandwidth limits?

**Completion rubric:** explicit ownership/lifetime proof, private scratch, exact output, bounded scheduling, and measured serial fallback rationale. Commit: `M10-L03: schedule independent image tiles`.

## M10-L04 — PNG input/output with a normalized boundary

**Outcome:** support ordinary PNG files without making assembly understand file encodings or framework-specific bitmap layouts.

### Explanation and supplied API route

Use Image I/O for decoding/encoding and Core Graphics for an explicit working bitmap. A decoder's native storage is not automatically our RGBA byte format. Byte order, component order, row stride, color space, orientation, and alpha representation must be normalized before kernels see it. PNG's file samples and a Core Graphics drawing buffer can use different alpha conventions.

The tutor supplies and explains a `PNG.swift` implementation using `CGImageSourceCreateWithURL`, `CGImageSourceCreateImageAtIndex`, an explicitly configured `CGContext`, and `CGImageDestinationCreateWithURL`/`CGImageDestinationFinalize`. Verify signatures against the installed SDK's official documentation. This framework adapter is supporting code; the learner is not expected to discover these APIs independently.

For the first required PNG path, accept **opaque images** and normalize to 8-bit sRGB, RGBA bytes, top-row-first. Use a context with explicit `byteOrder32Big` and `premultipliedLast` bitmap information when selecting the RGBA memory convention, then verify it with channel fixtures. Opaque alpha makes premultiplied and straight RGB numerically identical. Reject decoded nonopaque pixels instead of passing premultiplied data into straight-alpha kernels. Supporting transparent PNG via explicit unpremultiplication/premultiplication is a documented optional extension with lossy-rounding and alpha-zero policies.

### Your implementation

Integrate the supplied adapter with your existing CLI and pipeline. Read dimensions before allocating the working image, apply the same size policy, and reject unsupported multi-image/orientation behavior explicitly or normalize it deliberately. Use a four-corner test to establish row orientation; do not assume a drawing coordinate convention maps to your byte-row convention without evidence. On output, construct a CGImage describing the exact owned buffer and keep it alive for the encoder's use. Check destination finalization success.

### After completing the whole lesson

**Checks:** red/green/blue/white pixels keep channel order; asymmetric corners preserve orientation; opaque sRGB PNG round-trip preserves selected pixel samples; transparent input rejects clearly; profile conversion is reported as conversion rather than asserted byte identity; invalid dimensions/files fail. Run a complete PNG→pipeline→PNG example.

**Questions:** Why is '32-bit pixels' insufficient to specify a layout? When do straight and premultiplied RGB coincide? Why can profile conversion change samples? What keeps output storage alive during encoding?

**Completion rubric:** supplied/explained adapter integrated correctly, verified RGBA/orientation/sRGB boundary, honest opaque scope, error handling, and end-to-end evidence. Commit: `M10-L04: add normalized PNG input and output`.

## M10-L05 — Release and explain the engine

**Outcome:** a reproducible image engine and a technical account of what you learned.

### Explanation and deliverables

A working release includes behavior, evidence, and limits. 'Written in assembly' is an implementation fact, not a quality guarantee. Explain which kernels are scalar, which use NEON, which stages are orchestrated in Swift, and what measurements justify selected optimizations.

Create a project README outside `learning/` describing setup, exact build/test/benchmark commands, CLI examples, supported formats, dimension limits, alpha/color-space policies, and error behavior. Document the assembly interface and ownership rules. Preserve simple implementations as selectable references or test oracles. Keep benchmark claims tied to a commit, toolchain, workload, and machine.

### Your implementation

Prepare one demonstration pipeline using at least a pointwise operation, a neighborhood filter, and resize. Provide the source fixture or a reproducible fixture generator and record output checksums. Run the cumulative correctness suite in debug and release modes. Review every assembly function for frame/register obligations and every raw-pointer crossing for bounds/lifetime assumptions. Run representative scalar/NEON/tiled/parallel equivalence checks.

Write a short optimization report with a table of changes, hypotheses, measurements, numerical equivalence, and adoption decisions. Include at least one experiment that failed to improve performance or had a workload-specific tradeoff. Explain the result honestly. Add known limitations such as opaque-only filters/PNG boundary, simplified PPM subset, bilinear downsampling quality, and absence of native automated evidence where applicable.

The lesson does not require making a repository public, publishing a release, or pushing a tag automatically. You decide whether to tag the reviewed commit. A local/repository release candidate is sufficient.

### After completing the whole lesson

**Checks:** a clean checkout builds from documented commands; all required checks pass; no hidden generated dependency is needed; examples produce specified outputs; reported performance is reproducible within normal variation; all earlier required review fixes are resolved.

**Questions:** How does data move from a file to vector registers and back? Which safety obligations remain despite Swift ownership? Where did SIMD help most, and where did memory or scheduling dominate? How would you investigate a new incorrect image without guessing?

**Completion rubric:** complete reproducible engine, documented contracts/limits, traceable correctness and performance evidence, and an explanation connecting memory, ABI, SIMD, and architecture. Commit: `M10-L05: document and validate the image engine release`.

## Module references

- [Memory and concurrency boundary](../reference/memory-and-swift.md)
- [Testing and performance](../reference/testing-and-performance.md)
- [Apple Image I/O and Core Graphics sources](../reference/resources.md)
