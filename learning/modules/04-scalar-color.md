# Module 04 — Scalar color processing

Prerequisite: Module 03. These functions establish numerical references for SIMD. Keep integer formulas exact and document alpha behavior. All final verification and questions occur after implementation.

## M04-L01 — Brightness, signed values, and clamping

**Outcome:** add a signed brightness adjustment without wrapping a bright pixel to black.

### Explanation and worked code

For a channel c and delta in -255…255, calculate `clamp(c+delta,0,255)`. The intermediate range is -255…510, so it needs more than an unsigned byte. A byte store alone truncates; it does not clamp. Saturation is a deliberate numerical choice.

Declare `uint32_t brighten_channel(uint32_t c, int32_t delta);`. This complete helper illustrates signed comparisons:

```asm
.text
.p2align 2
.globl _brighten_channel
_brighten_channel:
    add w0, w0, w1
    cmp w0, #0
    csel w0, wzr, w0, lt
    mov w2, #255
    cmp w0, w2
    csel w0, w2, w0, gt
    ret
```

`cmp` updates flags as if subtracting without keeping the arithmetic result. `lt` and `gt` are signed comparisons. `wzr` supplies zero. `csel destination,a,b,condition` chooses a when the condition is true and b otherwise. With c=10 and delta=-30, the sum is -20, the first selection makes it 0, and the second leaves it 0. Using an unsigned comparison for this negative intermediate would misinterpret it as a huge positive number.

### Your implementation

Create `brightness_rgba_scalar(data,width,height,stride,delta)`, with uint64 dimensions and int32 delta. The Swift wrapper rejects delta outside the stated interval. Modify only RGB. First use the helper for individual demonstrations; in the image kernel either inline its logic or preserve loop state correctly across calls. Do not introduce per-channel calls without accounting for caller-clobbered registers. Keep the existing inversion implementation unchanged.

### After completing the whole lesson

**Checks:** `(10,-30)->0`, `(250,20)->255`, `(100,20)->120`; delta 0 is identity; -255 makes all RGB black and +255 makes them white; alpha/padding unchanged. Invalid delta fails before assembly.

**Questions:** Why is a byte store insufficient? Why do signed comparison conditions matter? What range must the intermediate represent? Which registers would be unsafe to keep across a helper call?

**Completion rubric:** exact clamp semantics, signed delta, preserved alpha/padding, range validation, and edge cases. Commit: `M04-L01: add scalar brightness`.

## M04-L02 — Weighted grayscale and rounding

**Outcome:** compute one grayscale value and repeat it in RGB. **New concepts:** fixed integer weights, multiply-accumulate, bounded intermediates.

### Explanation and worked fragment

Use `Y=(77R+150G+29B+128)>>8`. The weights total 256, making black stay black and white stay white. They approximate a luma-like encoded RGB mix; this is not the later linear-light luminance path. Adding 128 before shifting rounds the nonnegative weighted sum to nearest with ties upward.

```asm
// Fragment: w0=R, w1=G, w2=B, each 0...255.
// Output w3=Y; clobbers w4/w5/w6. No memory access.
mov w4, #77
mov w5, #150
mov w6, #29
mul w3, w0, w4
madd w3, w1, w5, w3
madd w3, w2, w6, w3
add w3, w3, #128
lsr w3, w3, #8
```

`madd d,a,b,c` computes a*b+c. The largest pre-shift value is 65,408, so it fits unsigned 16 bits, though we use W registers now. This proof will justify narrower vector lanes later. Overflow analysis follows the largest intermediate, not only the final 0…255 result.

### Your implementation

Add `grayscale_rgba_scalar(data,width,height,stride)`. Load three channels, apply the formula, write Y into R/G/B, preserve A and padding. Add an independent Swift formula using Int or UInt32 intermediates for hand-sized fixtures. Explain the Swift conversions before arithmetic; multiplying UInt8 values directly can overflow before assignment to a wider variable.

### After completing the whole lesson

**Checks:** pure red maps to 77, green to 149, blue to 29, black to 0, white to 255; gray input `(c,c,c)` stays c for every c in 0…255. Check nonopaque alpha is preserved. Confirm the green result by calculation, not by assuming it equals the weight.

**Questions:** Why add 128? Why do weights sum to 256? Why widen before multiplication? Why is encoded grayscale different from linear-light luminance?

**Completion rubric:** exact formula, independent expected values, full intermediate-range proof, and unchanged alpha/padding. Commit: `M04-L02: add weighted scalar grayscale`.

## M04-L03 — Contrast in fixed-point arithmetic

**Outcome:** scale channel distance from a midpoint without requiring floating point yet.

### Explanation and worked fragment

A Q8 factor stores the real scale multiplied by 256: 256 means 1.0, 128 means 0.5, and 512 means 2.0. The course defines:

`out = clamp(((c-128)*factorQ8 + 32768 + 128) arithmetic-shift-right 8,0,255)`.

The 32768 term restores the midpoint in Q8 units. The additional 128 performs the chosen rounding. Negative values use an arithmetic right shift, which repeats the sign bit. Do not replace it with logical shift or signed division without checking rounding for negative inputs.

```asm
// Fragment: w0=channel, w1=factorQ8 in 0...1024.
// Output w0=unclamped signed result; clobbers w2.
sub w0, w0, #128
mul w0, w0, w1
mov w2, #32896
add w0, w0, w2
asr w0, w0, #8
```

The product lies between -131,072 and 130,048; a signed 32-bit intermediate easily holds it. Finish with the signed clamp from L01. With factor 256, every channel is unchanged. With factor 0, every RGB channel becomes 128. Fixed point trades a specified finite factor resolution for integer arithmetic with reproducible rounding.

### Your implementation

Add `contrast_rgba_scalar(data,width,height,stride,factorQ8)` with uint32 factor, validated by Swift. Preserve alpha. Add a CLI argument that accepts integer Q8 values initially; user-friendly decimal conversion can remain a Swift-side extension. Keep integer numerical semantics visible in tests.

### After completing the whole lesson

**Checks:** factor 0 gives 128; 256 is identity; 512 maps 0→0, 64→0, 128→128, 192→255, 255→255. Test factors 128 and 1024 and channels around 127/128. Reject 1025.

**Questions:** Why is the midpoint added in scaled units? What distinguishes `asr` from `lsr`? How does factor quantization differ from rounding the result? Why can a scalar/vector comparison miss a shared formula error?

**Completion rubric:** declared Q8 interpretation, exact signed rounding, bounded factor, independent examples. Commit: `M04-L03: add fixed-point contrast`.

## M04-L04 — Blend two opaque images

**Outcome:** combine corresponding pixels with an exact integer blend parameter.

### Explanation and worked fragment

For each RGB channel, compute `((256-t)*a+t*b+128)>>8`, with t in 0…256. The endpoints must return a and b exactly. Restrict this first API to opaque images; output alpha is 255. Give both inputs identical dimensions, but allow distinct row strides. Allocate a disjoint destination.

```asm
// Fragment: w0=a, w1=b, w2=t; output w0; clobbers w3/w4.
mov w3, #256
sub w3, w3, w2
mul w4, w0, w3
madd w4, w1, w2, w4
add w4, w4, #128
lsr w0, w4, #8
```

Because the weights sum to 256, the largest sum including rounding is 65,408. This fits unsigned 16-bit lanes, an important SIMD opportunity. Averaging each product separately before adding would round twice and change results.

### Your implementation

Use a row kernel to keep the ABI small: `blend_row_scalar(dst,a,b,pixels,t)` with pointers, uint64 count, uint32 t. A Swift wrapper validates matching dimensions and opaque active alpha, borrows input arrays immutably, and loops over rows into a new image. It passes each row's independently computed address. The tutor supplies and explains nested borrow closures if needed. Keep the loop in Swift for now; the assembly row kernel is the learning target.

### After completing the whole lesson

**Checks:** t=0 and 256 return the respective input; t=128 blends 0 and 255 to 128; equal input images are unchanged; input buffers remain intact; distinct strides work; dimensions/alpha/t errors are rejected. Test 1-pixel and empty cases according to the wrapper contract.

**Questions:** Why is t allowed to equal 256? Why not store t in UInt8? Why round only after accumulating? Why are input strides independent even when dimensions match?

**Completion rubric:** exact endpoints/rounding, row API, disjoint output, validated opaque policy, and independent inputs. Commit: `M04-L04: blend two scalar images`.

## M04-L05 — Alpha compositing with an explicit representation

**Outcome:** place a straight-alpha foreground over an opaque background.

### Explanation and worked example

Straight alpha stores RGB independently of alpha. Premultiplied alpha stores RGB already multiplied by opacity. Using a premultiplied pixel as if it were straight multiplies twice and creates dark edges. Our main storage stays straight; this first compositor requires opaque background and produces opaque output.

For foreground channel f, background b, and foreground alpha a:

`result = floor((f*a + b*(255-a) + 127)/255)`.

For f=200,b=20,a=128, the numerator is 28,267, giving 110. For alpha 0 the result is background; for 255 it is foreground. Output alpha is always 255 under the opaque-background restriction. Alpha itself is a coverage/opacity factor, not a color channel to gamma-correct.

```asm
// Fragment: w0=foreground, w1=background, w2=alpha.
// Output w0=channel; clobbers w3/w4/w5.
mov w3, #255
sub w4, w3, w2
mul w5, w0, w2
madd w5, w1, w4, w5
add w5, w5, #127
udiv w0, w5, w3
```

`udiv` performs unsigned integer division, discarding the remainder. Division by 255 is not a right shift by eight. Do not optimize it to /256 and accidentally lose exact endpoints. We use a mathematically defined scalar reference before considering an exact vector division replacement.

### Your implementation

Add `composite_over_opaque_row_scalar(dst,foreground,background,pixels)` with disjoint destination and equal-length rows. Have Swift reject a nonopaque background. Preserve the original foreground, including hidden RGB under zero alpha. Add a checkerboard background fixture to see transparency, while calculating exact expected values for selected pixels.

Document that general straight-over-straight composition requires computing output alpha and handling division by it; that extension is not required here. Do not silently accept unsupported background transparency.

### After completing the whole lesson

**Checks:** transparent foreground leaves background; opaque foreground replaces it; the worked 200/20/128 case gives 110; output alpha is 255; nonopaque backgrounds reject; padding/input storage unchanged.

**Questions:** Why does premultiplied RGB require a different formula? Why is /255 not /256? Why may a transparent pixel contain nonzero RGB? Why does the current contract avoid dividing by output alpha?

**Completion rubric:** exact formula and representation, validated background, endpoint/midpoint evidence, and honest scope. Commit: `M04-L05: composite straight alpha over opaque images`.

## Module references

- [Image mathematics](../reference/image-math.md)
- [Assembly and signed conditions](../reference/assembly-and-abi.md)
- [Testing reference](../reference/testing-and-performance.md)
