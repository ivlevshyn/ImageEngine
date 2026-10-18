# Module 06 — Rearranging and combining vector data

Prerequisite: Module 05. Focus on data layout, intermediate widths, and reductions. Preserve scalar references and arbitrary-length tails. All questions and required checks are at the end of each lesson.

## M06-L01 — Separate interleaved channels

**Outcome:** understand and use structured loads/stores on RGBA data.

### Explanation and worked fragment

Our storage alternates R,G,B,A. Many algorithms want a vector containing only red samples. A structured `ld4` distributes groups of four bytes into four registers. For sixteen pixels, it reads **64 bytes**, not sixteen. The fourth register holds sixteen alpha values.

```asm
// Fragment: x0 points to at least 16 active RGBA pixels.
// x1 points to a disjoint 64-byte destination.
// Clobbers v0...v3 and advances x0/x1 by 64 bytes.
ld4 {v0.16b, v1.16b, v2.16b, v3.16b}, [x0], #64
st4 {v0.16b, v1.16b, v2.16b, v3.16b}, [x1], #64
```

After loading, V0 holds R0…R15, V1 G0…G15, V2 B0…B15, and V3 A0…A15. `st4` interleaves them again. The source format never changes; the registers temporarily use a planar view. This can simplify arithmetic but is not automatically faster than other loading strategies.

### Your implementation

Create a teaching row-copy kernel using structured loads/stores for full sixteen-pixel blocks and packed scalar copies for the remainder. Give it disjoint-buffer semantics. Then add a red/blue exchange in the vector registers before storing, matched by a scalar tail. Keep it named as a channel permutation, not a change of the engine's canonical format. Preserve G and A.

Write a table showing the first four pixels before loading and the first four lanes in each register after loading. Use distinct channel values. Avoid using ABI-preserved V8–V15 as unaccounted scratch registers; V0–V7 and V16–V31 are sufficient here.

### After completing the whole lesson

**Checks:** widths 0,1,15,16,17,31,32,33; copied output exact; red/blue swapped exactly; alpha unchanged; source/destination padding untouched; no 64-byte access for fewer than sixteen active pixels.

**Questions:** How many bytes does this `ld4` read? How does a planar register view differ from planar file storage? Why must the block-count threshold change from four to sixteen pixels? What would forgetting the scalar tail do?

**Completion rubric:** correct deinterleaving model, safe block size, exact permutation, and disjoint destination. Commit: `M06-L01: use structured RGBA loads and stores`.

## M06-L02 — Widen, accumulate, round, and narrow grayscale

**Outcome:** vectorize the exact grayscale formula for sixteen pixels at a time.

### Explanation and worked fragment

Eight-bit multiplication would lose the high bits of weighted products. Widening multiply takes byte inputs and produces 16-bit products. Low and high halves of the input vector are handled separately. The maximum weighted sum is 65,280; adding a rounding half-unit still fits unsigned 16 bits.

```asm
// Fragment after ld4: v0=R,v1=G,v2=B,v3=A, each .16b.
// Constants v16/v17/v18 contain 77/150/29 in every byte.
// Output v19 contains 16 Y bytes. Clobbers v4/v5/v19.
umull v4.8h, v0.8b, v16.8b
umlal v4.8h, v1.8b, v17.8b
umlal v4.8h, v2.8b, v18.8b
rshrn v19.8b, v4.8h, #8
umull2 v5.8h, v0.16b, v16.16b
umlal2 v5.8h, v1.16b, v17.16b
umlal2 v5.8h, v2.16b, v18.16b
rshrn2 v19.16b, v5.8h, #8
```

`rshrn` performs the rounding right shift and narrows the result; do not also add 128 manually. The `2` multiplication forms consume the upper eight source bytes; the `2` narrowing form writes the upper half of the destination. Copy Y to the RGB registers and preserve V3 before `st4`. Initialize constants once outside the loop with `movi`.

### Your implementation

Add `grayscale_row_neon(data,pixels)` and its image wrapper. Match M04's formula exactly. Use the scalar formula for the final 0…15 pixels. Annotate each register's lane type at each stage, especially where byte samples become halfword sums.

### After completing the whole lesson

**Checks:** compare all 256 neutral grays, primary-color examples, random colors, high-half-distinct inputs, and all tail lengths. Verify alpha/padding. A test where only pixels 8…15 differ catches forgotten high-half operations.

**Questions:** Why does widening occur before accumulation? What does the suffix `2` select? Why must rounding happen exactly once? What bound makes 16-bit sums sufficient?

**Completion rubric:** bit-exact scalar match, correct low/high halves, documented ranges, and safe tails. Commit: `M06-L02: vectorize weighted grayscale`.

## M06-L03 — Exact vector blending

**Outcome:** vectorize two-input blending without changing endpoint or rounding behavior.

### Explanation and worked fragment

The blend parameter can equal 256, so byte lanes cannot represent its full domain. Widen the samples to unsigned 16-bit values before multiplying by halfword weights. Each combined weighted sum is at most 65,280, leaving room for rounding. No saturating approximation is necessary.

```asm
// Fragment for eight channels after widening:
// v0.8h=A, v1.8h=B, v2.8h=(256-t), v3.8h=t.
// v4 accumulates; v5.8b receives rounded output.
mul v4.8h, v0.8h, v2.8h
mla v4.8h, v1.8h, v3.8h
rshrn v5.8b, v4.8h, #8
```

`ushll v0.8h,v6.8b,#0` is one way to widen eight bytes before this fragment. Organize register lifetimes so loading a second input does not overwrite the first. You may blend all channels for opaque inputs because blending 255 with 255 returns 255; the wrapper must still enforce opacity. Document that this shortcut is specific to the current contract.

### Your implementation

Add `blend_row_neon(dst,a,b,pixels,t)` with disjoint destination. Choose a block size, state its byte extent, and build its full/tail paths. Reuse existing Swift row scheduling. Preserve exact parameter validation and use one rounding step. Compare with the scalar kernel and independent endpoint formulas.

For a practical arithmetic proof, create an end-of-lesson parameter test over all t=0…256 and a representative set of channel pairs, including both extremes. Optional exhaustive testing of all channel pairs is useful but not a required runtime cost.

### After completing the whole lesson

**Checks:** t=0,1,127,128,255,256; equal images; alternating high/low channels; all tails; different input strides. Verify no output writes escape the destination and both sources remain unchanged.

**Questions:** Why are halfword weights necessary? Why does `mla` here not need widening? What protects the sum from overflow? Under what condition is blending alpha with the same formula valid?

**Completion rubric:** correct sample widening, 256 endpoint, exact rounding, bounded accesses, and retained opaque contract. Commit: `M06-L03: vectorize exact image blending`.

## M06-L04 — Table lookups and channel permutations

**Outcome:** implement a four-pixel channel reorder using a byte lookup table and compare it with structured loading.

### Explanation and worked fragment

`tbl` selects bytes from vector register tables. It is not a gather from arbitrary memory addresses. For four RGBA pixels, swapping R/B uses byte indices `[2,1,0,3,6,5,4,7,10,9,8,11,14,13,12,15]`. Each output byte names its source byte.

```asm
// Fragment: v0 is one 16-byte RGBA block; v1 is the index vector.
// v2 receives reordered bytes; input registers remain available.
tbl v2.16b, {v0.16b}, v1.16b
```

For this single-register table, indices outside 0…15 yield zero. The mapping must therefore be checked, not assumed. Constant bytes can live in a Mach-O constant section and be addressed with a page-relative pair:

```asm
// Fragment, use inside the function before its loop; clobbers x9,v1.
adrp x9, L_swap_rb@PAGE
add x9, x9, L_swap_rb@PAGEOFF
ldr q1, [x9]
// At file scope, outside functions:
.section __TEXT,__const
.p2align 4
L_swap_rb:
    .byte 2,1,0,3,6,5,4,7,10,9,8,11,14,13,12,15
.text
```

The symbol's final address is resolved by the toolchain. Do not embed an absolute address observed in one debug run. A constant table is data, not executable instructions.

### Your implementation

Implement `swap_rb_row_neon` with four-pixel blocks and a scalar tail. Compare its output with M06-L01's structured-load version. Keep both until performance lessons measure them. Explain every index in one pixel group and how the next group's indices shift by four.

### After completing the whole lesson

**Checks:** `[R,G,B,A]` becomes `[B,G,R,A]` for every pixel; two permutations restore the original; all tails and alpha values work. A diagnostic block containing byte values 0…15 must produce the exact index sequence.

**Questions:** Why is TBL not arbitrary-memory gather? What does an out-of-range index do? Why use relocatable constant addressing? Why can equivalent algorithms perform differently?

**Completion rubric:** correct table, position-independent addressing, exact tail mapping, and comparison with the prior permutation. Commit: `M06-L04: reorder channels with NEON table lookup`.

## M06-L05 — Reduce pixels into statistics

**Outcome:** calculate the sum of red samples and derive their mean in Swift. **New concepts:** horizontal reduction, accumulator width, overflow budgets.

### Explanation and worked fragment

Most earlier instructions operate lane by lane. A reduction combines lanes into one value. After deinterleaving sixteen red bytes, their sum is at most 4,080. A byte-lane reduction would overflow. A widening reduction produces a halfword result, which can then be added to a 64-bit total.

```asm
// Fragment: v0.16b contains sixteen red samples; x4 is uint64 total.
// Clobbers v4 and w5; x4 receives the updated total.
uaddlv h4, v0.16b
umov w5, v4.h[0]
add x4, x4, x5
```

Declare `uint64_t sum_red_row_neon(const uint8_t *src,uint64_t pixels);` and a scalar counterpart. Bound the total by `255*pixels` in the wrapper. Under the course image limits it fits comfortably, but the raw function's documented domain must still make the assumption explicit. Mean is sum divided by the number of pixels; an empty image has no defined mean, so return an optional result in Swift rather than dividing by zero.

### Your implementation

Add scalar and NEON row sums and a Swift image-statistics wrapper. The vector loop may use `ld4` and discard unused G/B/A lanes, with a scalar tail. Accumulate row sums in UInt64 using checked arithmetic at the public boundary. Convert to Double only when calculating the displayed mean, after the exact integer sum is known. Optional minimum and maximum statistics can use appropriate reductions after this required sum works.

### After completing the whole lesson

**Checks:** all-black sum 0; all-red-255 sum 255*N; sixteen 255 samples sum 4080; known ramp sum; empty mean is absent; padding never contributes. Compare scalar/NEON totals on large synthetic inputs and tails.

**Questions:** Why is `addv b...` inadequate for sixteen bytes? Why use a 64-bit total after a small block reduction? Why defer conversion to floating point? How would multiple independent accumulators affect later optimization?

**Completion rubric:** overflow-aware reduction, exact totals, empty policy, padding exclusion, and independent arithmetic examples. Commit: `M06-L05: reduce image channels into statistics`.

## Module references

- [NEON data and narrowing reference](../reference/neon.md)
- [Image mathematics](../reference/image-math.md)
- [Official instruction resources](../reference/resources.md)
