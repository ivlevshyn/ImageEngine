# Module 07 — Neighborhood filters

Prerequisite: Module 06. Pointwise operations use one input pixel; filters use neighboring pixels too. This changes borders, aliasing, intermediate storage, and tiling. Required filters initially accept **opaque RGBA8** and produce opaque RGBA8 in disjoint storage. Keep all checks/questions at the end.

## M07-L01 — A scalar 3-by-3 box blur

**Outcome:** average a pixel's neighborhood with an explicit border rule.

### Explanation and algorithm

For each RGB channel, add nine samples centered on `(x,y)`, then compute `(sum+4)/9` with integer floor division. The sum fits in 0…2295. Replicate borders: coordinates below zero select zero; coordinates above the last index select the last index. A corner therefore repeats some source pixels. This is a defined extension of the image, not permission to read outside its allocation.

```text
for each destination (x,y):
    for channel in R,G,B:
        sum = 0
        for dy in -1,0,1:
            sy = clamp(y+dy, 0, height-1)
            for dx in -1,0,1:
                sx = clamp(x+dx, 0, width-1)
                sum += source[sy*srcStride + 4*sx + channel]
        destination[y*dstStride + 4*x + channel] = (sum+4)/9
    destination alpha = 255
```

This is pseudocode to translate, not runnable assembly. The first version may prioritize clear loops over speed. Make the inner calculation a leaf function or carefully preserve state around calls. Use signed coordinates for subtracting one, clamp them, then form addresses. Reject empty filter inputs in the Swift wrapper so `width-1` and `height-1` are valid.

### Your implementation

Add `box3_rgba_scalar(dst,dstStride,src,srcStride,width,height)` with disjoint output. Supply a Swift reference using the same formula and clear loops. The tutor explains its indexing rather than expecting fluency. Validate opaque input. Demonstrate with a synthetic impulse: one white pixel in a black 5-by-5 image.

### After completing the whole lesson

**Checks:** constant images remain constant; a 1-by-1 image stays unchanged; an interior isolated white pixel gives 28 in each of its nine affected RGB outputs; corner/border results match hand calculation; widths/heights 1 and 2 work; source/padding untouched.

**Questions:** Why cannot the first blur safely overwrite its source? Which samples repeat at a corner? Why add 4 before dividing by 9? What is the largest accumulator value?

**Completion rubric:** exact border/rounding semantics, disjoint output, tiny-image handling, and independent reference agreement. Commit: `M07-L01: implement scalar neighborhood blur`.

## M07-L02 — Separate horizontal and vertical sums

**Outcome:** reproduce the same blur with two passes and an intermediate buffer.

### Explanation and algorithm

The nine-term box sum can be grouped into three horizontal sums, then added vertically. The crucial detail is to **delay division**. Rounding each horizontal average and then averaging vertically changes results. Store exact horizontal sums in UInt16, not rounded byte outputs.

Define temporary H as four UInt16 elements per pixel, interleaved RGBA, tightly packed rows of `4*width` elements. For opaque input the alpha sum is 765. Each horizontal value is 0…765. The vertical pass adds three H values, adds 4, and divides by 9; alpha becomes 255. Stride for H is measured in **elements** in Swift indexing and converted explicitly to bytes for assembly.

```text
H[y,x,c] = source[y,max(x-1,0),c]
         + source[y,x,c]
         + source[y,min(x+1,width-1),c]
out[y,x,c] = (H[max(y-1,0),x,c] + H[y,x,c]
             + H[min(y+1,height-1),x,c] + 4) / 9
```

### Your implementation

Add `box3_horizontal_scalar(uint16_t *dst,const uint8_t *src,uint64_t width)` for one row. Add `box3_vertical_scalar(uint8_t *dst,const uint16_t *top,const uint16_t *middle,const uint16_t *bottom,uint64_t width)`. Swift selects replicated row pointers and allocates the checked temporary array. `withUnsafeMutableBufferPointer` on `[UInt16]` gives a typed pointer; advancing it by one moves two bytes. Explain this contrast with raw byte-pointer arithmetic.

The tutor supplies the orchestration in Swift if needed. Keep the direct 3-by-3 implementation as an oracle. Bound temporary size independently: RGBA16 H takes twice the bytes of RGBA8 input, so the original allocation limit alone is not enough.

### After completing the whole lesson

**Checks:** byte-exact comparison with L01 across tiny, random, impulse, and padded images; temporary sums attain 765 for white; one-pixel-wide images repeat the same sample three times; temporary size validation rejects overflow/excessive allocation.

**Questions:** Why is horizontal division deferred? What units does a UInt16 pointer advance use? How much memory does H require relative to the image? Why can two passes be correct despite traversing in a different order?

**Completion rubric:** unnormalized intermediate, exact scalar equivalence, checked temporary ownership, and explicit element/byte units. Commit: `M07-L02: separate blur passes without extra rounding`.

## M07-L03 — Vectorize horizontal filtering

**Outcome:** calculate neighboring byte sums in wider vector lanes without overreading borders.

### Explanation and worked fragment

Process the first and last pixels with scalar border logic. For an interior group beginning at pixel x and covering four pixels, load four pixels from x-1, x, and x+1. The last load reaches pixel x+4, so require `x+4 < width`. The condition is stricter than merely having four output pixels left.

```asm
// Fragment: v0/v1/v2 contain left/center/right 16-byte RGBA groups.
// v3/v4 receive low/high eight sums as UInt16. Clobbers v3/v4.
uaddl v3.8h, v0.8b, v1.8b
uaddw v3.8h, v3.8h, v2.8b
uaddl2 v4.8h, v0.16b, v1.16b
uaddw2 v4.8h, v4.8h, v2.16b
```

`uaddl` widens two narrow operands before adding. `uaddw` adds a widened narrow operand to an already-wide accumulator. These sums can exceed 255, so byte addition would wrap. Store V3 and V4 as 32 bytes of temporary RGBA16 data for the four output pixels.

### Your implementation

Add `box3_horizontal_neon` with the same API as the scalar pass. Handle tiny widths entirely through scalar logic; do not create an unsigned `width-2` before checking width. Use simple overlapping loads first. A later experiment can compare reuse through vector extraction, but correctness precedes reducing loads.

State the input extent and output extent of one block in comments. Preserve the existing temporary layout. Select the new pass in Swift while leaving the scalar vertical pass unchanged so any mismatch is localized.

### After completing the whole lesson

**Checks:** H values match scalar exactly for widths 1…20 and larger random rows; high-half lanes differ in fixtures; white sums reach 765; all source accesses remain inside the active row; outer markers remain intact. End-to-end blur still matches the direct reference.

**Questions:** Why is the load bound `x+4 < width`? Why does four RGBA pixels produce 32 output bytes in H? What does `uaddw` widen? Why test intermediate H rather than only the final image?

**Completion rubric:** exact intermediate sums, safe neighbor accesses, tiny-width fallback, and independent pass verification. Commit: `M07-L03: vectorize horizontal blur sums`.

## M07-L04 — Vectorize vertical filtering and exact division

**Outcome:** complete a NEON blur while preserving the scalar rounding contract.

### Explanation and worked fragment

Corresponding values from three H rows are contiguous. Add them in unsigned 16-bit lanes, then add 4. The numerator n lies in 0…2299. Within this range, floor(n/9) equals `(n*7282)>>16`. The reciprocal is slightly high; its error over this bounded domain is too small to push a nonmultiple across the next quotient boundary. Treat the domain as part of the proof, and exhaustively verify the identity for these 2300 inputs.

```asm
// Fragment: v0.4h contains four numerators n after adding 4.
// v1.4h contains 7282; result v3.4h contains exact quotients.
// Clobbers v2/v3; surrounding code handles the upper half and byte packing.
umull v2.4s, v0.4h, v1.4h
shrn v3.4h, v2.4s, #16
```

Widening the product is essential: 2299*7282 does not fit 16 bits. Narrow the quotients to bytes only after division. Do not use a reciprocal floating-point approximation when the integer contract requires exact equality.

### Your implementation

Add `box3_vertical_neon` with the same API as the scalar vertical pass. Process full vectors of H elements and finish all remaining pixels safely. Use Swift-selected top/middle/bottom pointers, including replicated rows at the global boundary. Validate the identity independently in Swift for every n in the specified range, and explain why that finite exhaustive check complements the mathematical bound.

### After completing the whole lesson

**Checks:** all 2300 quotient cases pass; vertical output matches scalar for random H values in 0…765; end-to-end blur equals the original direct implementation; one-row images and all tails work; output alpha is 255 for opaque input.

**Questions:** Why is the reciprocal valid only with a range argument? Why widen before multiplying? What would normalizing H early change? Which data is reused between neighboring output rows?

**Completion rubric:** exact division with proved/tested domain, correct packing/tails, global borders, and byte-exact complete blur. Commit: `M07-L04: complete exact NEON box blur`.

## M07-L05 — Sobel edge detection and signed intermediates

**Outcome:** detect edges using positive and negative weights. **New concepts:** signed convolution, gradient components, defined approximation.

### Explanation and algorithm

First convert RGB to the existing integer grayscale representation. For the 3-by-3 neighborhood a,b,c / d,e,f / g,h,i, define `Gx=(c+2f+i)-(a+2d+g)` and `Gy=(g+2h+i)-(a+2b+c)`. Each is in -1020…1020. Set the output to `min(255,abs(Gx)+abs(Gy))` in all RGB channels, alpha 255. This L1 gradient magnitude is a deliberate inexpensive approximation; do not describe it as the Euclidean square-root magnitude.

Replicate borders using the same global coordinate rule as blur. Grayscale and Sobel need disjoint stages or independent buffers because neighbors must see original gray values. A constant image produces zero everywhere, including edges under replicated boundaries.

### Your implementation

Implement a clear scalar Sobel kernel and a Swift reference first. Then add one NEON interior path processing multiple adjacent grayscale samples: widen bytes to signed 16-bit-compatible values, form sums/differences without unsigned wrap, use absolute values, add magnitudes, and saturating-narrow to bytes. Values are far from Int16.min, so signed absolute overflow is excluded by the established range. Handle borders and tails scalarly.

The tutor must provide a worked register-level interior example: zero-extend the unsigned bytes into 16-bit lanes, form the positive sums there, then subtract in those wide lanes and interpret the differences as signed. Do not apply `ssubl` directly to raw image bytes: samples above 127 would be interpreted as negative before widening. The full-image orchestration can be supplied in Swift; learning signed vector arithmetic is the core task.

### After completing the whole lesson

**Checks:** constant images yield zero; a vertical black/white step produces strong vertical-edge output; horizontal and diagonal fixtures distinguish Gx/Gy; scalar/NEON byte equality; tiny dimensions and padding; signed intermediates verified against hand calculations at selected pixels.

**Questions:** Why can unsigned subtraction fail here? Why is L1 magnitude an approximation? Why must grayscale remain available while processing neighbors? Why is Int16 sufficient for both gradients and their absolute-value sum?

**Completion rubric:** defined gradients/magnitude, signed-range reasoning, scalar and vector paths, border/tail safety, and interpretable fixtures. Commit: `M07-L05: detect edges with scalar and NEON Sobel`.

## Module references

- [Image mathematics](../reference/image-math.md)
- [NEON widening/narrowing](../reference/neon.md)
- [Test and benchmark evidence](../reference/testing-and-performance.md)
