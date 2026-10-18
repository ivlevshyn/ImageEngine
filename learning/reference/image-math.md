# Image mathematics and numerical contracts

These are project definitions, not claims that every image library uses identical conventions. Keep them stable while comparing scalar and SIMD code. The course guide is the canonical overview; each lesson supplies the implementation detail.

## Pointwise operations

Let c be a byte-valued channel and `clamp(v)=min(255,max(0,v))`.

| Operation | Required calculation | Important bound or invariant |
| --- | --- | --- |
| Invert | `255-c` | Applying twice is identity. |
| Brightness | `clamp(c+delta)` | delta -255…255; intermediate -255…510. |
| Grayscale | `(77R+150G+29B+128)>>8` | Pre-shift max 65408; neutral grays unchanged. |
| Contrast | `clamp(((c-128)*q+32896) arithmetic-shift-right 8)` | q 0…1024; q=256 identity, q=0 midpoint. |
| Blend | `((256-t)*a+t*b+128)>>8` | t 0…256; exact endpoints; opaque inputs initially. |
| Straight foreground over opaque background | `(f*a+b*(255-a)+127)/255`, floor | a=0 selects background; a=255 foreground; output alpha 255. |

Alpha is preserved for single-image RGB color operations. Fill/copy/geometry work on the full pixel. A function's explicit contract takes precedence over assuming that every kernel treats alpha identically.

## Fixed point and rounding

Q8 stores a real scale approximately as an integer divided by 256. It is a chosen representation, not a special register type. For nonnegative n, `(n+128)>>8` rounds n/256 to nearest with ties upward. Signed arithmetic shift and signed division have different behavior for negative values; use the expression defined by the lesson rather than casually substituting one for the other.

The order of rounding matters. `round(round(a/3)+round(b/3)+round(c/3))` is not generally the same as rounding the combined quantity once. Preserve unnormalized horizontal sums in the separable blur. Similarly, fusion must retain any intermediate quantization that is part of the unfused contract.

## Blur and Sobel

Box blur uses replicated global borders and `(nineSampleSum+4)/9`. Each horizontal three-sample sum fits 0…765 in UInt16. The vertical sum fits 0…2295; after the rounding bias the numerator is at most 2299. For this domain only, the course validates exact division with `(n*7282)>>16`. The widening product fits UInt32. Do not reuse the identity for unrestricted integers without a new proof.

Sobel computes Gx and Gy in -1020…1020 using signed wide intermediates. `abs(Gx)+abs(Gy)` fits 0…2040; saturate to 255 only when producing the byte. This L1 magnitude deliberately differs from `sqrt(Gx*Gx+Gy*Gy)`. Opaque grayscale input and replicated borders are the required initial policy.

## Resize coordinates

For nearest neighbor, use pixel-center mapping `floor((2*x+1)*sourceWidth/(2*destinationWidth))`. For bilinear, map to `u=(x+0.5)*sourceWidth/destinationWidth-0.5`, clamp u to the source interval, then choose floor(u), the next clamped neighbor, and the fraction. Source/destination dimensions must be positive. A one-pixel source axis selects the same sample for both neighbors.

For bilinear interpolation use `a+(b-a)*t` twice horizontally and once vertically, then quantize once. A separable implementation with Float intermediate rows follows this model. Nearest and bilinear interpolation are useful learning algorithms; bilinear alone does not provide ideal antialiasing for large downscales. A wider reconstruction filter is a possible post-course extension.

## Floating-point comparison policy

| Path | Reference and bound |
| --- | --- |
| Exposure | Same Float operation schedule should agree across scalar/vector fixtures; independently verify clamping and nearest-up conversion. |
| Bilinear intermediate | Absolute error <=0.0002 in channel units 0…255 versus a Double analytical reference. |
| Bilinear quantized output | At most one code-value difference versus the reference near rounding thresholds; identity/constant cases still must meet their invariants. |
| Linear-light 50/50 Float blend | Absolute error <=0.000001 in normalized units versus Double. |
| Linear-light encoded byte | At most one code-value difference attributable to Float rounding; endpoints exact. |

These bounds are course acceptance criteria, not blanket exemptions. A wrong coordinate mapping cannot be dismissed as floating-point noise. Log the actual maximum error and failing sample; reject NaN/infinity at validated public boundaries where parameters require finite values. An optimized variant that changes operation order or uses fused multiply-add needs a fresh comparison against the same bound.

## Color space and alpha

The early integer engine treats RGB as encoded code values. The optional linear-light path explicitly decodes sRGB, performs light-domain arithmetic, and re-encodes. A black/white midpoint is about 188 when encoded after linear averaging, compared with 128 from averaging encoded bytes. See [official color resources](resources.md) for transfer-function definitions.

Straight alpha stores independent RGB and opacity. Premultiplication multiplies RGB by alpha. Conversion back cannot reconstruct hidden RGB when alpha is zero and can lose precision for small alpha. The required PNG adapter initially rejects nonopaque pixels to keep that boundary explicit; the internal scalar compositor still teaches transparent foreground handling over opaque backgrounds.

Never gamma-correct alpha. Do not compare a color-managed decoder's samples to an unmanaged path as if they necessarily represented the same numbers. Record working color space and alpha convention with the buffer type or API.
