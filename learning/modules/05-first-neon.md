# Module 05 — Your first NEON implementations

Prerequisite: Module 04. NEON is Arm Advanced SIMD. We use baseline AArch64 vector instructions, not optional dot-product/SVE/SME instructions. Each vector implementation retains its scalar counterpart. All checks and questions occur after the whole lesson.

## M05-L01 — One instruction, multiple lanes

**Outcome:** fill exactly four RGBA pixels using one vector store. **New concepts:** vector registers, lane arrangements, vector/scalar register views.

### Explanation and complete example

A 128-bit register can be viewed as sixteen byte lanes (`.16b`), eight halfword lanes (`.8h`), four 32-bit lanes (`.4s`), or two 64-bit lanes (`.2d`). The arrangement describes how an instruction groups bits. It does not transform the stored data automatically. Here `.4s` means four 32-bit packed pixels, not four floating-point numbers.

Declare `void fill4_rgba_neon(uint8_t *dst, uint32_t rgba);`, requiring exactly 16 writable bytes:

```asm
.text
.p2align 2
.globl _fill4_rgba_neon
_fill4_rgba_neon:
    dup v0.4s, w1
    str q0, [x0]
    ret
```

`dup` repeats the 32-bit color in all four lanes. Q0 names the full 128-bit storage of V0 for the store. W1 and V1 are separate register banks; Q0 and V0 are views of the same vector storage. The output is four repeated R,G,B,A groups, exactly as four scalar stores would produce.

For color 0xff332211, V0 has four equal 32-bit lanes. In memory it becomes `11 22 33 ff` repeated four times. Working across lanes is useful because many pixels undergo identical operations. SIMD is not a promise of a particular speedup: memory traffic and surrounding work still matter.

### Your implementation

Create `src/asm/neon.s`, add the declaration, and call it on a 16-byte active region inside a larger marker buffer. Keep this fixed-size teaching API explicitly named `fill4`; do not pretend it handles arbitrary counts yet. Compare the bytes with `fill_rgba_scalar` called for four pixels. Use LLDB to inspect V0/Q0 through the available vector register view on your toolchain.

### After completing the whole lesson

**Checks:** four repeated packed pixels exactly match scalar output; surrounding markers unchanged; colors with different channel values expose byte-order mistakes. This API must not be called on fewer than four pixels.

**Questions:** What does `.4s` mean here? Is Q0 separate storage from V0? How many pixels fit in 16 bytes? Why is a fixed-size function's precondition different from a general image loop?

**Completion rubric:** correct lane explanation, complete fixed-block routine, exact byte comparison, and explicit 16-byte precondition. Commit: `M05-L01: fill four pixels with NEON`.

## M05-L02 — Invert RGB while preserving alpha

**Outcome:** invert four pixels at once without modifying alpha. **New concepts:** vector bitwise operations and repeated masks.

### Explanation and complete example

Inversion already has an exact bitwise form: XOR each packed pixel with 0x00ffffff. Repeat the mask across four 32-bit lanes, then XOR the full vector. A byte arrangement is convenient for the XOR because bitwise operations do not carry between lanes.

```asm
.p2align 2
.globl _invert4_rgba_neon
_invert4_rgba_neon:
    mov w1, #0x00ffffff
    dup v1.4s, w1
    ldr q0, [x0]
    eor v0.16b, v0.16b, v1.16b
    str q0, [x0]
    ret
```

Declare `void invert4_rgba_neon(uint8_t *data);`. A zero mask bit preserves the corresponding input bit; a one flips it. In each alpha byte all mask bits are zero. Avoid using vector NOT on all bytes: that would invert alpha too. The `.16b` spelling does not change the in-memory pixel format.

The general-purpose W1 holds a value copied into a vector register. The load reads sixteen bytes even if only a few resulting lanes would later be used. Discarding unwanted results cannot make an invalid load legal.

### Your implementation

Add the fixed-block function and compare against scalar inversion on four pixels whose alpha values are 0,1,128,255. Write a short lane diagram as a Markdown table: lane byte index, input meaning, mask value, output rule. Keep the scalar function unchanged. Add no arbitrary-length wrapper until the next lesson's bounds are implemented.

### After completing the whole lesson

**Checks:** all RGB channels invert and alpha stays exact; two calls restore the block; sentinel bytes remain unchanged; scalar and SIMD outputs match. Include a deliberately nonuniform pixel block so copying a single pixel four times fails visibly.

**Questions:** Why use a mask instead of NOT? Does `.16b` mean the image now has sixteen channels? What does the load access before any masking? Why is the scalar reference still valuable for a simple operation?

**Completion rubric:** correct mask, full block access contract, alpha preservation, lane explanation, and exact comparison. Commit: `M05-L02: invert four pixels with a NEON mask`.

## M05-L03 — Full vectors and scalar tails

**Outcome:** process any legal row length safely. **New concepts:** vector loop bounds, tails, per-row boundaries, alignment versus validity.

### Explanation and complete example

With four pixels per vector, a row has `count/4` full blocks and `count%4` remaining pixels. Do not round count upward and load beyond the row. Ordinary NEON loads on normal allocated memory need not begin at a 16-byte boundary, but every accessed byte must still be valid. Alignment and bounds are different concerns.

```asm
.p2align 2
.globl _fill_rgba_neon
_fill_rgba_neon:
    dup v0.4s, w2
    cmp x1, #4
    b.lo L_nfill_tail
L_nfill_vector:
    str q0, [x0], #16
    sub x1, x1, #4
    cmp x1, #4
    b.hs L_nfill_vector
L_nfill_tail:
    cbz x1, L_nfill_done
L_nfill_scalar:
    str w2, [x0], #4
    subs x1, x1, #1
    b.ne L_nfill_scalar
L_nfill_done:
    ret
```

Declare `void fill_rgba_neon(uint8_t *dst, uint64_t pixels, uint32_t rgba);`, matching the scalar row filler's types. `lo`/`hs` are unsigned lower/higher-or-same comparisons, suitable for pixel counts. The loop subtracts only when at least four pixels remain, preventing count underflow. No pointer is dereferenced on count zero.

### Your implementation

Add the complete fill and write `invert_row_neon(data,pixels)` using the same control structure, the earlier vector mask, and a scalar packed-pixel XOR tail. Write a Swift image wrapper that calls the row kernel for each active row using stride. Keep processing within each row so padding cannot become a tail's accidental input.

### After completing the whole lesson

**Checks:** counts 0…17; widths 3,4,5 and 15,16,17; base offsets 0…15 inside an adequately sized allocation; padded multirow images. Compare exact active bytes and all surrounding markers with scalar results. Inspect load bounds separately: unchanged markers detect writes, not invalid reads.

**Questions:** Why does unsigned comparison fit this loop? Why does masking after an out-of-bounds load not fix it? Why restart the tail logic each row? Can an unaligned address still be valid?

**Completion rubric:** correct zero/full/tail paths, no rounded-up accesses, per-row stride handling, and offset tests. Commit: `M05-L03: handle NEON tails safely`.

## M05-L04 — Saturating vector brightness

**Outcome:** apply positive and negative brightness to multiple pixels without corrupting alpha. **New concepts:** unsigned saturating addition/subtraction, parameter-dependent paths.

### Explanation and worked fragments

NEON `uqadd` clamps unsigned addition at the lane maximum; `uqsub` clamps unsigned subtraction at zero. A signed delta is not a byte to add blindly: a negative Int32 reinterpreted as UInt8 becomes a large positive number. Choose addition or subtraction once based on delta's sign, and use its magnitude in 0…255.

Build a repeated byte pattern `[m,m,m,0]` so alpha receives no change:

```asm
// Fragment: w3=nonnegative magnitude 0...255; clobbers w4,v1.
orr w4, w3, w3, lsl #8
orr w4, w4, w3, lsl #16
dup v1.4s, w4
// For a loaded vector v0, positive-delta path:
uqadd v0.16b, v0.16b, v1.16b
// ALTERNATIVE negative-delta path (do not execute both):
uqsub v0.16b, v0.16b, v1.16b
```

Saturation happens independently per byte. The zero alpha lane preserves any alpha value under either operation. The vector arithmetic exactly matches the scalar clamp because the magnitude is bounded and the path reflects delta's sign. We do not need 16-bit intermediates for this particular operation; grayscale and blending will.

### Your implementation

Add `brightness_row_neon(data,pixels,delta)` with the same validated delta interval as M04. Select a loop before processing pixels rather than branching separately for every channel. Provide correct scalar tails and a Swift image wrapper. Keep the scalar image version selectable for comparison. Document scratch registers and which instructions change flags so tail control does not accidentally use stale conditions.

### After completing the whole lesson

**Checks:** deltas -255,-1,0,1,255; channels 0,1,127,254,255; multiple alpha values; all remainder lengths; padding/offset cases. Compare exact bytes with scalar output. Reject out-of-contract delta before negating or narrowing it.

**Questions:** Why not use wrapping `add`? Why choose sign outside the pixel loop? How does a zero adjustment preserve alpha? When would wider intermediate lanes be necessary instead?

**Completion rubric:** exact signed-delta semantics, safe tails, alpha preservation, and no byte reinterpretation of negative deltas. Commit: `M05-L04: add saturating NEON brightness`.

## M05-L05 — Establish a differential test matrix

**Outcome:** reusable evidence that vector and scalar operations agree across awkward inputs. **New concepts:** deterministic randomized tests, independent oracles, read-bound limits of canaries.

### Explanation and supplied generator

Differential testing runs the same input through two implementations and compares results. It catches many vector mistakes but cannot detect a shared incorrect specification. Keep hand-calculated cases as well. Randomness should be reproducible, so use a fixed seed and print it with failing dimensions and parameters.

```swift
struct FixtureRNG {
    var state: UInt64
    mutating func nextByte() -> UInt8 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return UInt8(truncatingIfNeeded: state >> 56)
    }
}
```

Swift's `&*` and `&+` intentionally wrap, unlike ordinary checked arithmetic. Wrapping is appropriate for this deterministic generator, not for allocation sizes. `truncatingIfNeeded` selects the low bits of the supplied value; here the shift already gives one byte. This is a test generator, not cryptographic randomness.

### Your implementation

Generate cases across widths 0…33, heights 0,1,2,7, and several legal strides. Fill active pixels with deterministic bytes and padding with known sentinels. For each implemented vector operation, start both paths from identical independent inputs. Compare active output, alpha policy, padding, and outer sentinels. Report the first mismatch with operation, seed, x/y/channel, expected/actual, and parameters.

Keep a separate small suite of exact known values. Include base-offset tests on raw row kernels. Do not claim AddressSanitizer automatically instruments handwritten assembly accesses. Optional guarded-page fixtures can make overreads observable, but require additional explained OS scaffolding; static loop-bound reasoning remains required now.

### After completing the whole lesson

**Checks:** both debug and release builds pass; a deliberately wrong alpha mask or missing tail produces an informative failure, then is fixed; the same seed reproduces the same input. Preserve the bug-revealing case as a regression.

**Questions:** Why can two implementations agree and both be wrong? What errors do sentinels detect, and what do they miss? Why allow wrapping in this generator but not size validation? Why are odd widths valuable?

**Completion rubric:** deterministic suite, independent known answers, clear diagnostics, alpha/padding coverage, and honest evidence limits. Commit: `M05-L05: validate scalar and NEON equivalence`.

## Module references

- [NEON reference](../reference/neon.md)
- [Testing and performance](../reference/testing-and-performance.md)
- [Official Arm resources](../reference/resources.md)
