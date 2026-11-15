# Testing and performance

Use these reminders while implementing code and repository tests. They do not create end-of-lesson checks/reviews or require evidence submissions.

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

## Repository code checks

Inspect the relevant committed implementation, declarations, callers, and tests at an exact GitHub revision. Report concrete defects and required fixes briefly, keeping optional improvements separate. Record the checked revision and lesson status when updating progress.

Do not require a formal end-of-lesson review, question answers, command output, screenshots, debugger traces, or other learner evidence. Use repository code as the basis for completion. Run focused checks when useful and supported by the available environment, and distinguish executed tests from static conclusions. Missing native execution alone is not a completion blocker; do not claim execution or performance that was not measured.

Changes to shared helpers call for focused regression coverage in the implementation, rather than an unbounded demand to redo future lessons. Benchmark data is useful project material when that is the implementation task; it is not a separate evidence submission or review gate.

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
