# NEON reference for the image engine

This sheet ties instruction families to the course. Consult [Arm's official material](resources.md) for exact encodings, restrictions, and extension requirements. All required course kernels use baseline Advanced SIMD available to our AArch64 target; do not copy an intrinsic marked for an additional ISA extension without checking it.

## Register arrangements

| Arrangement | Elements in 128 bits | Image example |
| --- | --- | --- |
| `.16b` | 16 × 8-bit | Four RGBA8 pixels or sixteen deinterleaved red samples. |
| `.8h` | 8 × 16-bit | Widened color products or horizontal blur sums. |
| `.4s` | 4 × 32-bit | Four packed pixels, integer products, or four Float channels depending on instruction. |
| `.2d` | 2 × 64-bit | Wide accumulators. |

The same bits can be interpreted differently by different instructions. Changing the arrangement suffix does not perform numeric conversion. Scalar S0 and the low lane of V0 share storage. Track live ranges before mixing scalar FP and SIMD scratch use.

## Families you will use

| Family | Reason it appears |
| --- | --- |
| `dup`, `movi` | Broadcast a scalar or create repeated constants. |
| `ldr/str qN`, `ld1/st1` | Move a contiguous vector-sized block. |
| `ld4/st4` | Deinterleave/reinterleave RGBA channels. A .16b four-register structure transfers 64 bytes. |
| `eor`, `and`, `orr`, `bsl` | Bitwise transforms and selection masks. |
| `uqadd`, `uqsub` | Clamp unsigned lane arithmetic rather than wrap. |
| `ushll`, `uxtl` aliases | Widen values before arithmetic. |
| `umull`, `umlal` | Widening multiply and multiply-accumulate. |
| `uaddl`, `uaddw` | Add narrow values into wider lanes. |
| `shrn`, `rshrn` | Narrow after shifting, optionally with rounding. |
| `xtn`, `uqxtn`, `sqxtun` | Narrow by truncation, unsigned saturation, or signed-to-unsigned saturation as appropriate. |
| `tbl`, `ext`, `zip`, `uzp` | Rearrange bytes/lanes or reuse neighboring data. |
| `uaddlv` | Widening horizontal reduction. |
| `ucvtf`, `fcvtzu` | Numeric conversion between unsigned integers and floating-point values. |
| `fadd`, `fsub`, `fmul`, `fmla` | Floating-point arithmetic; fused forms have their own rounding behavior. |

Names alone are not enough: arrangements and operand forms matter. The `2` suffix on widening operations usually selects an upper source half, while on narrowing operations it places results in an upper destination half. Read the exact form used in a lesson.

## A correct vector loop has three contracts

1. **Arithmetic:** each lane computes the same specified result as the reference, with sufficient intermediate width.
2. **Memory:** every byte read/written belongs to a valid permitted region, including neighbors for filters.
3. **Control:** zero counts, complete blocks, and remainders terminate and cover exactly the intended outputs.

For a four-pixel pointwise block, require at least four remaining pixels. For a four-output horizontal radius-one filter, neighbor loads extend beyond the output block, so derive the bound from all source accesses. Never use alpha masking or ignored lanes to justify an invalid load.

## Numerical traps

- Widen before multiplying or adding if the narrow intermediate would overflow.
- Prove the maximum *intermediate*, including rounding bias.
- Do not apply both a manual rounding bias and a rounding-narrow instruction for the same step.
- Saturating narrowing and truncating narrowing are different contracts.
- Integer division by 255 or 9 is not a shift. An exact reciprocal replacement needs a domain proof.
- Reductions may need wider accumulation than any one lane or block.
- Float arithmetic may differ under fusion. Compare to declared tolerances, preserving exact endpoints where required.

## Intrinsics documentation as a lookup aid

Arm's intrinsics tables show AArch64 instruction mappings and required features. Use them to understand an instruction family and its lane interpretation. The learner still implements the required kernels in assembly; writing a Swift SIMD or C intrinsic call is not a substitute for those assignments. Intrinsics can be optional compiler comparisons later.
