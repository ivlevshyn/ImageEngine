# Testing, review evidence, and performance

Use these reminders after the lesson's implementation. They do not create intermediate lesson gates.

## Correctness evidence ladder

1. Hand-calculated examples establish the intended formula and coordinate mapping.
2. Scalar implementations make the algorithm readable and provide reusable comparisons.
3. Differential scalar/NEON tests explore dimensions, parameters, and lane arrangements.
4. Sentinel, padding, and aliasing checks examine storage effects.
5. Static address-range/ABI reasoning covers obligations tests may miss.
6. Optional specialized tools and guarded-page fixtures strengthen evidence when their setup is taught.

Two matching implementations can share a bug. A correct-looking picture is useful feedback, not a numeric proof. A compiler or assembler accepting a file says nothing about image correctness. Native execution evidence is separate from static review.

## Fixture matrix

| Dimension of variation | Examples |
| --- | --- |
| Size | Empty when permitted; 1x1; 1xN; Nx1; odd/even; just below/at/above SIMD block size. |
| Storage | Tight stride; padded stride; different source/destination strides; base offsets 0…15 for valid raw-row buffers. |
| Channels | All zero; all 255; distinct channels; primary colors; gray ramps; alpha 0,1,128,255 where allowed. |
| Patterns | Checkerboard; impulse; horizontal/vertical ramps; labeled corners; edges crossing tile boundaries. |
| Parameters | Endpoints, near endpoints, identity settings, invalid values rejected by wrappers. |
| Execution | Scalar; NEON; tiled; serial/parallel; debug/release. |

Keep empty behavior operation-specific: pointwise operations can no-op; file I/O and resize reject empty images. For filters, tiny nonempty images still need correct border replication. When an operation is opaque-only, include a rejection test for unsupported alpha instead of treating undefined input as a kernel bug.

## Failure diagnostics

Report operation, implementation variant, seed, width/height/stride, parameter values, pixel/channel or byte offset, expected/actual, and commit. Small exact inputs are better than opaque screenshots. Retain a minimal case when a randomized failure is found.

Sentinels tell you whether bytes were changed. They do not tell you whether a vector read beyond the active region and discarded some lanes. Review the largest load/store extent. The final address plus access width must remain within the permitted region. For neighborhood algorithms include the halo, not only the destination tile.

## Review report template

```text
Lesson:
Implementation commit:
Previous reviewed commit:
Files inspected:
Execution environment:

Requirement | Evidence | Status
...

Required fixes:
- File/function, input exposing the issue, expected behavior, explanation.

Optional improvements:
- Clearly distinguish later-course topics.

Questions:
- Answer assessment or questions still pending.

Executed here:
Learner-provided outputs:
Static-only conclusions:
Unverified items:

Outcome: ready / changes requested / verification pending
Proposed progress entry:
```

Do not mark a lesson ready if its necessary native checks were neither executed nor supplied as credible local evidence. Treat user-provided logs as such; they are not tests the reviewer ran. Changes to shared helpers require focused regression coverage, not an unbounded demand to redo all future lessons.

## Benchmark units

For N iterations on width*height active pixels with total elapsed nanoseconds T:

- `ns/pixel = T / (N * width * height)`.
- `pixels/second = N * width * height * 1e9 / T`.
- Estimated active-byte throughput uses declared algorithmic bytes read/written per pixel; label decimal GB/s versus binary GiB/s explicitly.

Do these calculations in a sufficiently wide or floating type after checking nonzero sizes. Stride padding is not processed pixel content. Cache-line transfers and write allocation can make actual hardware traffic differ from the simple algorithmic count.

## Benchmark discipline

Use release builds, record exact commands and environment, warm up, run multiple samples, and keep raw observations. Separate kernel, wrapper, and end-to-end measurements. Restore or rotate inputs outside the kernel interval when needed. Consume output after timing and inspect optimized code to guard against eliminated or transformed workloads. Do not compare two algorithms with different color-space or rounding semantics as if they were interchangeable.

Thermal state, scheduling, background activity, allocation policy, and reuse of memory can change results. Record concrete conditions rather than inventing guarantees. A 'warm repeated buffer' workload is a useful defined experiment. A 'cold cache' claim needs a justified method. No lesson requires outperforming a professional library or reaching a claimed chip peak.

## Useful experiments after the course

Higher-quality resampling, more general alpha compositing, transparent PNG normalization, a streaming decoder, runtime CPU-feature dispatch for optional extensions, and deeper profiler analysis are natural extensions of this same engine. They are not prerequisites for completing the agreed 50 lessons.
