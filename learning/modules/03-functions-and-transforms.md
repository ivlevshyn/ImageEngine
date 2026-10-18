# Module 03 — Reliable functions and transformations

Prerequisite: Module 02. Keep the same pixel layout and build script. Start `src/asm/transforms.s` when useful; the script already builds multiple assembly files. Existing kernels remain available. All assessment occurs after each complete lesson.

## M03-L01 — Make function contracts explicit

**Outcome:** public Swift operations establish every precondition needed by assembly. **New concepts:** interface contract, units, aliasing, const input.

### Explanation and worked example

A function signature can identify a pointer without saying how much memory it addresses. Comments must state what the type system cannot. A valid address alone is not a valid image. A stride is measured in bytes; width is measured in pixels; allocation length is another distinct quantity. Confusing these can produce plausible output while corrupting unrelated memory.

Add a header comment in this style:

```c
// data: writable RGBA8; width/height: pixels; stride: bytes.
// If width==0 or height==0: no memory access.
// Otherwise stride >= 4*width and storage covers stride*height bytes.
// Operates in place. RGB inverted; alpha and padding unchanged.
// Synchronous borrowed pointer; does not retain or free it.
void invert_rgba_scalar(uint8_t *data, uint64_t width,
                        uint64_t height, uint64_t stride);
```

In a two-buffer API, `const uint8_t *src` means this interface does not write through the source pointer; it does not guarantee the underlying bytes cannot be changed elsewhere. A separate destination must not overlap the source unless the contract permits it. Rather than comparing arbitrary pointers, a wrapper can allocate a fresh destination and keep both borrows scoped.

### Your implementation

Document every existing assembly declaration with units, range, touched bytes, empty behavior, ownership, and clobber expectations under the ABI. Add a Swift `validatedRowBytes` helper if validation is duplicated. Keep dimensions immutable and restrict direct mutation of `bytes` outside controlled fixtures as the design matures. Explain any remaining trusted internal paths.

For a future crop, write the proposed validation using `originX <= source.width` and `cropWidth <= source.width-originX` after checking nonnegativity. Subtracting from a known valid bound avoids overflowing an unchecked `originX+cropWidth`. Do not implement crop yet.

### After completing the whole lesson

**Checks:** invalid public parameters fail before reaching assembly; empty pointwise images are no-ops; padding tests still pass; no wrapper uses a pointer outside its borrow. Have the reviewer trace one valid and one invalid path.

**Questions:** What cannot a raw pointer tell the callee? Does `const` imply exclusive access? How do identical buffers differ from partially overlapping buffers? Why validate ranges with subtraction?

**Completion rubric:** complete existing API contracts, centralized checked size policy, and a clear division between public validation and trusted kernels. Commit: `M03-L01: document and enforce image contracts`.

## M03-L02 — Call assembly from assembly

**Outcome:** fill a full image by calling the row filler. **New concepts:** leaf/non-leaf functions, link register, stack frame, preserved registers.

### Explanation and worked code

`bl` branches to a function and writes a return address into X30. A function that calls another must preserve its own return address. It must also keep long-lived values somewhere a callee cannot destroy. X19–X28 are preserved by callees under our ABI, so a function using them first saves their incoming values and restores them before returning.

Declare `void fill_image_scalar(uint8_t *dst, uint64_t width, uint64_t height, uint64_t stride, uint32_t rgba);` and use this complete example:

```asm
.text
.p2align 2
.globl _fill_image_scalar
_fill_image_scalar:
    stp x29, x30, [sp, #-64]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    stp x21, x22, [sp, #32]
    str x23, [sp, #48]
    mov x19, x0
    mov x20, x1
    mov x21, x2
    mov x22, x3
    mov w23, w4
    cbz x20, L_fill_image_done
    cbz x21, L_fill_image_done
L_fill_image_row:
    mov x0, x19
    mov x1, x20
    mov w2, w23
    bl _fill_rgba_scalar
    add x19, x19, x22
    subs x21, x21, #1
    b.ne L_fill_image_row
L_fill_image_done:
    ldr x23, [sp, #48]
    ldp x21, x22, [sp, #32]
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #64
    ret
```

The exclamation mark on the first store is pre-index writeback: reserve 64 bytes, then store the pair. The final load restores the old frame pointer and return address, then releases those bytes. All frame sizes keep SP aligned to 16 bytes. X29 links the frame chain; do not repurpose it as a general counter. The unused eight bytes are intentional padding. Saving X23 before writing W23 preserves the caller's full X23 value.

### Your implementation

Use this function in `Image.fillScalar` instead of a Swift row loop. Add comments that explain the stack layout and register roles. In LLDB, step over one row call and observe that scratch registers may change while the saved loop state survives. Add assembly unwind/CFI annotations only as an explained extension after the basic frame is understood; the reference discusses their role.

### After completing the whole lesson

**Checks:** empty, padded, and multirow fills match the previous Swift-driven behavior. Inspect that every return path restores SP and all touched preserved registers. Observe the return address before and after a nested call.

**Questions:** Why does `bl` make saving X30 necessary? Why not keep the row count in X1 across the call? Why reserve 64 bytes when saved values use 56? Why must a W23 write still restore the original X23?

**Completion rubric:** correct stack layout, restored preserved state, correct rows/padding, and a nested-call trace. Commit: `M03-L02: compose assembly functions safely`.

## M03-L03 — Crop into a new image

**Outcome:** extract a rectangular region with independent source/destination strides. **New concepts:** origin offsets, unsigned loop counts, disjoint buffers.

### Explanation and worked kernel

Use eight arguments so the integer/pointer interface fits the initial argument registers:

```c
void crop_rgba_scalar(uint8_t *dst, uint64_t dstStride,
                      const uint8_t *src, uint64_t srcStride,
                      uint64_t width, uint64_t height,
                      uint64_t originX, uint64_t originY);
```

The source start is `src + originY*srcStride + originX*4`. The multiply-add instruction can combine the first calculation. After Swift validates source bounds and creates the destination, this fragment establishes row bases:

```asm
// Entry arguments x0...x7 follow the declaration above.
// Fragment clobbers x2 and x8...x11; surrounding function needs zero guards/ret.
madd x2, x7, x3, x2
add x2, x2, x6, lsl #2
// At each row start:
mov x8, x2
mov x9, x0
mov x10, x4
// Inner body, repeated width times:
ldr w11, [x8], #4
str w11, [x9], #4
```

Copying packed pixels preserves all four channels. Update source and destination row bases by their own strides. Incrementing both by the same stride works only accidentally for equally laid-out images. The fragment is not a complete callable function: you supply labels, guards, counter updates, row transitions, and `ret`.

### Your implementation

Add `Image.cropped(x:y:width:height:) throws -> Image`. Check nonnegative coordinates/sizes and bounds before forming offsets. Allocate a fresh destination; borrow the source immutably and destination mutably. Snapshot dimensions before entering closures. Return an empty image for a valid zero-sized crop. Do not force unwrap empty base addresses. The tutor supplies the nested Swift borrowing pattern from the memory reference.

### After completing the whole lesson

**Checks:** crop a labeled 4-by-3 image at origin (1,1) to 2-by-2; result pixels must be exactly source coordinates (1,1),(2,1),(1,2),(2,2). Test full-image crop, last single pixel, padded source/destination, empty legal crop, and out-of-range origins. Input bytes never change.

**Questions:** Which stride locates the next source row? Why does the new image simplify overlap rules? What prevents multiplication overflow here? What makes an empty crop valid even at an image edge?

**Completion rubric:** exact coordinate mapping, two correct strides, independent destination, validated bounds, and no source writes. Commit: `M03-L03: crop image regions`.

## M03-L04 — Flip horizontally in place

**Outcome:** reverse pixel order in each row without reversing channel order. **New concepts:** two-ended traversal and swap invariants.

### Explanation and worked fragment

Within a row, pixel x maps to `width-1-x`. Swapping pairs performs the operation in place. Only `width/2` swaps are needed; the center pixel of an odd-width row remains where it is. Guard width zero before subtracting one, or an unsigned width can underflow.

```asm
// Fragment: x4=left pixel address, x5=right pixel address.
// Both address complete active pixels; clobbers w6/w7.
ldr w6, [x4]
ldr w7, [x5]
str w7, [x4], #4
str w6, [x5]
sub x5, x5, #4
```

Both loads precede both stores so neither original value is lost. Packed-word access moves whole pixels, including alpha. Reversing bytes instead would scramble channels. The outer loop follows stride and never includes padding in the reversal.

### Your implementation

Declare `flip_horizontal_scalar(data,width,height,stride)` with the same types as inversion. Write complete loops around the fragment. Use `lsr` by one to obtain the unsigned pair count. Add a Swift wrapper and CLI operation. Document why an in-place swap is allowed here while crop uses disjoint storage.

### After completing the whole lesson

**Checks:** rows `[A,B,C,D]` become `[D,C,B,A]`; `[A,B,C]` becomes `[C,B,A]`; widths 0,1,2,3,5 and padded images work. Two flips recover all original bytes, including unchanged padding. Give each pixel distinct RGBA values so channel-order mistakes cannot hide.

**Questions:** Why stop after width/2 swaps? Why load both pixels before either store? What underflows if width zero is not guarded? Why is reversing the whole allocation incorrect?

**Completion rubric:** correct odd/even behavior, preserved pixel channels/padding, safe empty case, and involution test. Commit: `M03-L04: flip rows in place`.

## M03-L05 — Flip vertically and consolidate the API

**Outcome:** swap active contents of opposing rows and expose a coherent transformation interface. **New concepts:** physical storage versus logical image rows.

### Explanation and algorithm

Vertical flip maps row y to height-1-y. Swap only the active `width*4` bytes between row pairs. Padding stays attached to its original physical row and is not image content. With distinct padding markers, swapping whole strides would violate the contract even though the displayed image looked correct.

Use X-register arithmetic for row addresses and a half-height counter. Reuse the horizontal lesson's two-load/two-store idea for corresponding pixels in the upper and lower rows. You do not need a temporary whole row: one packed pixel in a register is enough for each exchange. The middle row of an odd-height image is untouched.

### Your implementation

Add `flip_vertical_scalar(data,width,height,stride)` and its Swift wrapper. Organize the public Swift interface so fill, invert, crop, and both flips have predictable naming. Move assembly functions into sensible files only if helpful; keep exported names stable so tests remain valid. The shell build uses unique source basenames.

Create a small transformation demonstration from a labeled 3-by-3 image: original, crop, horizontal flip, vertical flip, and both flips. For geometric inspection, use visibly different corners. For correctness, compare exact pixels. Keep command parsing small and explained; the CLI is supporting scaffolding.

### After completing the whole lesson

**Checks:** vertical twice restores the image; a single-row image stays unchanged; 0-by-N and N-by-0 do not dereference; row padding remains at its original offsets. Horizontal followed by vertical equals vertical followed by horizontal for the same image. All earlier tests still pass after any file moves.

**Questions:** Why not swap padding too? Does a 180-degree turn reverse channels? Which geometric operations require new storage in our current API? What evidence would distinguish a pointer-arithmetic bug from a pixel-format bug?

**Completion rubric:** complete vertical transform, compositional check, stable header/Swift interfaces, and documented overlap rules. Commit: `M03-L05: complete scalar geometry operations`.

## Module references

- [Apple ABI reminders](../reference/assembly-and-abi.md)
- [Swift borrowing patterns](../reference/memory-and-swift.md)
- [Test evidence](../reference/testing-and-performance.md)
