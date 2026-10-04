# Module 08 — Floating point, resizing, and light

Prerequisite: Module 07. Introduce floating-point concepts before requiring vector numerical work. Required resize/exposure/linear-filter paths initially use opaque images. All validation and questions occur after the whole lesson.

## M08-L01 — Floating-point exposure

**Outcome:** multiply RGB samples by a finite gain and convert them back with an explicit rounding rule.

### Explanation and worked example

Float represents values with a sign, exponent, and limited-precision significand. Many decimal fractions cannot be represented exactly. Integer-to-float conversion changes representation; moving identical bits between register banks does not. Scalar S0 and vector V0 share storage, so using S0 can affect assumptions about V0.

Declare `uint32_t exposure_channel(uint32_t c, float gain);`. For this mixed C-compatible interface the integer argument uses W0 and the floating argument uses S0. Keep this allocation distinct from 'every argument advances the same register counter'. The caller validates c in 0…255 and finite gain in 0…16.

```asm
.text
.p2align 2
.globl _exposure_channel
_exposure_channel:
    ucvtf s1, w0
    fmul s1, s1, s0
    mov w1, #255
    ucvtf s2, w1
    fmin s1, s1, s2
    fmov s2, #0.5
    fadd s1, s1, s2
    fcvtzu w0, s1
    ret
```

For nonnegative clamped values, adding 0.5 and truncating implements nearest with ties upward. `fcvtzu` converts toward zero to unsigned integer. Gain is nonnegative so no lower clamp is needed under this contract. For c=100,gain=1.25, the result is 125. Gain is a multiplier; an exposure-in-stops UI can compute `2^stops` in Swift later.

### Your implementation

Add a scalar row implementation and then a NEON path using byte-to-32-bit widening, `ucvtf`, vector multiplication/clamping, conversion, and narrowing. Start by tracing the scalar helper. Supply the Swift validation using `gain.isFinite`, range checks, and explicit Float conversion. Preserve alpha and tail rules. Validate the original user value before narrowing a wider type when that conversion could introduce infinity.

### After completing the whole lesson

**Checks:** gains 0,0.5,1,1.25,16; saturation at 255; half-way rounding examples; NaN/infinity/negative gains reject; scalar and vector paths with the same operation schedule agree on the fixtures; alpha/padding unchanged.

**Questions:** Why is `ucvtf` different from a bitwise move? Why does the gain arrive in S0? What rounding does `fcvtzu` perform? Why reject nonfinite values before the kernel?

**Completion rubric:** explicit Float contract, valid mixed argument handling, scalar/vector conversion pipeline, and finite-parameter checks. Commit: `M08-L01: process exposure with floating point`.

## M08-L02 — Nearest-neighbor resizing

**Outcome:** map destination pixel centers to source pixels with no ambiguity.

### Explanation and algorithm

There is more than one plausible resize convention. Define nearest-neighbor mapping as `sx=floor((2*x+1)*sourceWidth/(2*destinationWidth))`, likewise for y, then clamp to the final source index defensively. This maps the center of a destination pixel into source coordinates. Use UInt64 arithmetic under the course's bounded dimensions. Empty source or destination dimensions are rejected.

```asm
// Fragment: x4=destination x, x5=sourceWidth, x6=destinationWidth.
// Output x7=source x; clobbers x8. Inputs satisfy bounded positive sizes.
lsl x7, x4, #1
add x7, x7, #1
mul x7, x7, x5
lsl x8, x6, #1
udiv x7, x7, x8
```

For source width 2 and destination width 4, source indices are 0,0,1,1. For source width 4 and destination width 2, they are 1,3. A different downsampling choice can also be valid, but changing it would change our contract. Nearest neighbor selects samples; it does not average them or provide good general antialiasing when shrinking.

### Your implementation

Create a scalar resize routine with disjoint output. To keep the interface within eight general argument registers, use `resize_nearest_scalar(dst,dstStride,dstWidth,dstHeight,src,srcStride,srcWidth,srcHeight)`. All sizes are uint64. Swift validates allocation limits and opaque input, then supplies the buffers. Copy whole RGBA pixels. Derive source-row addresses once per output row where convenient.

### After completing the whole lesson

**Checks:** identity resize; 1-by-1 expansion; 2→4 and 4→2 labeled rows; unequal aspect ratios; padded source/output; zero dimensions rejected; no source writes. Confirm index mapping numerically before relying on a displayed image.

**Questions:** Why map pixel centers? Why can nearest neighbor alias when shrinking? Why use wide intermediates despite small channel values? Which calculations are constant across an output row?

**Completion rubric:** documented coordinate convention, exact mapping, checked positive dimensions, and independent strides. Commit: `M08-L02: resize with nearest-neighbor sampling`.

## M08-L03 — Scalar bilinear interpolation

**Outcome:** interpolate four neighboring samples with defined edge and numerical behavior.

### Explanation and worked example

Map each destination center to `u=(x+0.5)*sourceWidth/destinationWidth-0.5`, then clamp u to `[0,sourceWidth-1]`. Set x0=floor(u), x1=min(x0+1,last), and tx=u-x0. Repeat vertically for y0,y1,ty. Clamping before taking the fraction ensures an edge sample is replicated instead of blending with an invalid neighbor.

Use `lerp(a,b,t)=a+(b-a)*t`. Compute a horizontal interpolation on each selected row, then interpolate those results vertically. Keep intermediate values in Float, clamp to 0…255, and round once at final conversion with `floor(value+0.5)`.

```asm
// Complete arithmetic body for float lerp_f32(float a,float b,float t).
// Inputs s0/s1/s2; output s0; clobbers s1. Add normal symbol/directives.
fsub s1, s1, s0
fmul s1, s1, s2
fadd s0, s0, s1
ret
```

For four samples 0,100 / 200,255 and tx=ty=0.5, the result is 138.75 and the stored byte is 139. Fused multiply-add may round differently from the separate operations. Begin with separate instructions and record the schedule. Against an analytical Double reference, allow at most 0.0002 absolute error in the 0…255 interpolated value and at most one code value after quantization; explain every discrepancy near a rounding threshold. An identity resize must still be exact.

### Your implementation

Supply coordinate tables from Swift to simplify the assembly boundary: arrays of UInt32 x0/x1 indices and Float fractions, validated once. Use these exact row interfaces:

```c
void resize_horizontal_scalar(float *dst, const uint8_t *src,
    const uint32_t *left, const uint32_t *right, const float *weights,
    uint64_t destinationWidth);
void resize_vertical_scalar(uint8_t *dst, const float *top,
    const float *bottom, uint64_t pixels, float ty);
```

Each horizontal destination row has `4*destinationWidth` Float elements. Source points to one validated source row; indices are pixels, so multiply by four for source bytes. Float RGBA output uses sixteen bytes per pixel. Swift chooses y0/y1 source rows for each output row, computes the two horizontal rows, and passes them to the vertical kernel. Start by recomputing these two rows when needed; caching is a later optimization. Allocate both temporary rows with checked sizes and scoped typed borrows.

Tutors provide and explain table-generation/ownership scaffolding. Keep alpha at 255 for this opaque-only path. This decomposition prepares the same pipeline for NEON next lesson.

### After completing the whole lesson

**Checks:** worked midpoint=139; constant and identity images; 1-pixel axes; corners under clamping; horizontal/vertical gradients; finite coordinates and weights in [0,1]; tolerance comparison with an independent Double reference.

**Questions:** Why clamp before choosing neighbors and fractions? Why round only at final output? What changes with fused arithmetic? Why is bilinear shrinking not a complete high-quality antialiasing filter?

**Completion rubric:** explicit coordinates/borders, Float intermediate rows, numerical tolerance evidence, exact identity, and honest quality scope. Commit: `M08-L03: add scalar bilinear resizing`.

## M08-L04 — Vectorize the contiguous interpolation pass

**Outcome:** accelerate vertical bilinear interpolation and understand when memory access limits vectorization.

### Explanation and worked fragment

General horizontal resize selects source pixels at irregular offsets; baseline NEON does not supply a general arbitrary-address gather for this task. The vertical pass is easier: two already-resized Float rows are contiguous. For a row's fixed ty, broadcast the weight and interpolate four Float channels at once.

```asm
// Fragment: v0.4s=top, v1.4s=bottom, v2.4s=repeated ty.
// Output v0.4s; clobbers v1. Input samples are finite Float channels.
fsub v1.4s, v1.4s, v0.4s
fmul v1.4s, v1.4s, v2.4s
fadd v0.4s, v0.4s, v1.4s
```

Here `.4s` denotes four 32-bit lanes interpreted by floating-point instructions. One vector spans one RGBA Float pixel, sixteen bytes, unlike RGBA8 where it spans four pixels. After clamp and `+0.5`, convert lanes to UInt32 with `fcvtzu`, then narrow through UInt16 to UInt8. The final store must write only the four produced bytes unless several pixels have been packed into a full vector.

### Your implementation

Implement a NEON vertical row kernel using a C header interface with destination bytes, two Float row pointers, uint64 pixel count, and Float ty. Explain which argument bank carries ty. Process at least one vector per pixel; optionally pack multiple pixels after correctness. Keep the scalar horizontal table-driven stage. Retain a selectable scalar vertical implementation.

Compare a fused `fmla` variant only as an explicit experiment with the same stated error bound. Do not enable broad fast-math behavior merely to chase speed; numerical changes need evidence.

### After completing the whole lesson

**Checks:** scalar schedule agreement; analytical tolerance; full RGBA pixel store bounds; odd widths; alpha stays 255; no temporary row overreads. Include alternating extreme samples and ty values 0,0.5,1.

**Questions:** Why is vertical interpolation more contiguous? How many pixels are in a Float vector here? Why can a 16-byte store after narrowing corrupt output? How does fused arithmetic alter rounding?

**Completion rubric:** useful NEON pass, correct Float/byte layout transition, scoped temporary buffers, and numerical evidence. Commit: `M08-L04: vectorize bilinear vertical interpolation`.

## M08-L05 — An explicit linear-light path

**Outcome:** show why encoded color averaging differs from averaging light, then provide an optional correct-light path.

### Explanation and supplied transfer functions

sRGB code values are nonlinear encodings of light intensity. Averaging black and white code values gives about 128; averaging their linear-light values and encoding the result gives about 188. Neither is a random rounding error: they are different computations. Keep existing encoded-value filters named/documented; add an explicit option instead of changing old outputs.

```swift
import Foundation

func srgbToLinear(_ s: Double) -> Double {
    s <= 0.04045 ? s / 12.92 : pow((s + 0.055) / 1.055, 2.4)
}

func linearToSRGB(_ l: Double) -> Double {
    l <= 0.0031308 ? 12.92 * l : 1.055 * pow(l, 1.0 / 2.4) - 0.055
}
```

Inputs to these teaching helpers are finite in [0,1]. The ternary expression selects one formula. `pow` raises to a real power. Normalize a byte by dividing its Double value by 255. Alpha is not passed through this transfer function. For non-sRGB file profiles, conversion to a defined working color space belongs in the later decoder.

### Your implementation

Create a 256-entry Float decoding table in Swift and a scalar reference encoder using the function above, clamp, and `floor(255*s+0.5)`. Decode opaque RGB into linear Float storage, run a simple two-image 50/50 blend or the existing bilinear interpolation in that space, then encode. Use an assembly scalar/NEON Float arithmetic kernel for the required blend; Swift may handle table lookup and encoding. This keeps the lesson focused rather than requiring handwritten vector powers.

State absolute tolerance 0.000001 for Float blend results in [0,1] against the Double calculation, and at most one encoded code value where Float rounding crosses a threshold. Keep the endpoint and constant-image invariants.

### After completing the whole lesson

**Checks:** transfer endpoints 0/1; all 256 byte values round-trip through the Double helpers; black/white blend approximately 188 versus encoded 128; scalar/NEON Float results within tolerance; alpha unchanged/opaque; options produce documented different outputs.

**Questions:** Why is gamma-space averaging darker? Why is alpha excluded from the color transfer? Why keep old encoded tests? Which work is intentionally handled by Swift rather than assembly?

**Completion rubric:** explicit color-space choice, correct transfer functions, meaningful visual/numerical comparison, and retained contracts. Commit: `M08-L05: add linear-light image processing`.

## Module references

- [Image mathematics](../reference/image-math.md)
- [Floating-point and NEON reminders](../reference/neon.md)
- [Color and platform resources](../reference/resources.md)
