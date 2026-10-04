# Module 01 — Your first assembly code

Read [the guide](../course-guide.md) first. Work at the repository root. This module supplies complete small functions because the instruction vocabulary is new. Copying is expected; tracing and modifying the code is how you make it yours. Each lesson is delivered as one complete message. All checks and questions are at its end.

## M01-L01 — A Swift program calls your first assembly function

**Prerequisites:** none beyond general programming. **Outcome:** the executable prints an opaque alpha value returned by assembly. **Time:** 60–120 minutes, excluding installation.

### Explanation and worked code

Source text is not executed directly. The assembler translates instructions into an object file containing machine code. The linker combines that object with Swift's compiled code and runtime references into an executable. We expose a normal C-compatible function so Swift and assembly agree where a result lives.

Create `src/asm/pixel.s`:

```asm
.text
.p2align 2
.globl _opaque_alpha
_opaque_alpha:
    mov w0, #255
    ret
```

`.text` selects executable code. `.p2align 2` aligns the following address to a multiple of four bytes, because 2 to the power 2 is 4. `.globl` makes a symbol visible to the linker. `_opaque_alpha:` names this function's first instruction; the leading underscore is the Mach-O external-symbol spelling. The C and Swift names omit it. Directives and labels guide tools; they are not executed instructions.

`w0` is a 32-bit view of a CPU register. `#255` is an immediate constant encoded through the assembler. `mov` places 255 into the register used here for the return value. `ret` returns to the caller using the link register. You do not print from assembly: Swift receives the number and prints it.

Create `src/bridge/Pixel.h`:

```c
#ifndef PIXEL_H
#define PIXEL_H
#include <stdint.h>
uint32_t opaque_alpha(void);
#endif
```

This declares a function returning an unsigned 32-bit integer with no arguments. It does not implement it. The guard prevents repeated inclusion. `stdint.h` defines exact-width integer names; `uint32_t` imports as Swift `UInt32`. A header is the agreed interface between languages.

Create `src/swift/main.swift`:

```swift
let alpha: UInt32 = opaque_alpha()
print("opaque alpha = \(alpha)")
```

`let` binds a value you will not reassign. `: UInt32` states its type. `\(alpha)` inserts the value into a string. Swift knows the function because we pass the header to its compiler.

Run these commands from the repository root:

```bash
mkdir -p .build
xcrun clang -arch arm64 -g -c src/asm/pixel.s -o .build/pixel.o
xcrun swiftc -g -Onone -import-objc-header src/bridge/Pixel.h src/swift/main.swift .build/pixel.o -o .build/pixel
.build/pixel
```

`-c` stops after producing the object. `-g` includes debugging information. `-Onone` keeps Swift easy to debug. The final command executes the program; no Rosetta or simulator is involved. Record the toolchain commands listed in the guide in a small note for later reviews.

### Your implementation

Create the three files yourself and reproduce the build. Add `.build/` to your own `.gitignore`. Then add a second function, `transparent_alpha`, returning zero, with a header declaration and a Swift call. Use the existing function as the model; explain the three places where the function's name appears. Keep the original opaque function.

### After completing the whole lesson

**Checks:** both values print as 255 and 0; a clean rebuild after deleting only `.build/` works; `uname -m` reports native arm64. If it does not, investigate the execution environment before assuming these commands are native. Record compiler/SDK versions and the exact build output.

**Questions:** What is the difference between declaring and implementing a function? Which line actually puts the result into a register? Why is the underscore in assembly but absent in Swift? What job does the linker do?

**Completion rubric:** two callable functions, correct header declarations, reproducible build, no generated binaries committed, and explanations that distinguish assembler directives from instructions. Suggested commit: `M01-L01: call assembly alpha functions from Swift`.

## M01-L02 — Transform one color channel

**Prerequisite:** M01-L01. **Outcome:** calculate `255 - channel` in assembly. **New concepts:** arguments, register scratch space, subtraction, and a function contract.

### Explanation and worked code

Our input is logically a byte, but we deliberately expose it as `uint32_t` to keep the initial boundary simple. The caller promises it is between 0 and 255. Under this interface, the first integer argument arrives in `w0`; the return value also uses `w0`. A register is a storage location, not a permanently named variable. Replacing the input with the result is normal.

Append to `pixel.s`:

```asm
.p2align 2
.globl _invert_channel
_invert_channel:
    mov w1, #255
    sub w0, w1, w0
    ret
```

Add `uint32_t invert_channel(uint32_t channel);` inside the header guard. In `main.swift`, call `invert_channel(40)` and print the result. The `sub destination, left, right` order matters: this computes 255 minus input. With input 40, the state is: entry `w0=40`; after `mov`, `w1=255`; after `sub`, `w0=215`. `w1` is scratch space that this function is permitted to change. No memory buffer exists yet.

Append a simple Swift demonstration:

```swift
let samples: [UInt32] = [0, 1, 40, 128, 255]
for value in samples {
    print("\(value) -> \(invert_channel(value))")
}
```

The array's explicit type ensures literals are passed as UInt32. The square brackets create an array. The braces contain the repeated statements. You are using Swift as a visible driver, not learning Swift algorithms here.

### Your implementation

Add the inversion function and keep earlier functions. Add a second function `double_channel_unclamped` using `add w0, w0, w0`. Its return type is UInt32 and its result may exceed 255; do not convert it into UInt8. State the difference between a valid register value and a valid image channel. This temporary experiment will motivate clamping in M04.

Use the same rebuild commands as L01 after every change. An object file is a compiled snapshot; editing source without rebuilding does not alter the executable.

### After completing the whole lesson

**Checks:** inversion results are 255, 254, 215, 127, 0 for the displayed inputs. Doubling 200 produces 400. Inverting twice restores every tested valid channel. Do not claim the inversion contract covers input 400.

**Questions:** Why can `w0` be both input and output? What happens if you swap subtraction's source operands? Why is 400 acceptable in UInt32 but not in an 8-bit channel? What does the input-range promise contribute?

**Completion rubric:** correct functions, declared domains, expected examples, and a register trace for input 40. Suggested commit: `M01-L02: transform scalar channels`.

## M01-L03 — Pack and unpack an RGBA pixel

**Prerequisite:** M01-L02. **Outcome:** create a packed 32-bit pixel. **New concepts:** hexadecimal, bit positions, shifts, AND, OR, and multiple arguments.

### Explanation and worked code

One hexadecimal digit describes four bits; two describe a byte. `0xff` equals 255. Our bytes are R, G, B, A. A packed integer uses R in bits 0–7, G in 8–15, B in 16–23, and A in 24–31. Shifting moves a bit pattern; OR combines nonoverlapping fields. This integer convention will match the little-endian memory layout introduced next module.

```asm
.p2align 2
.globl _pack_rgba
_pack_rgba:
    orr w0, w0, w1, lsl #8
    orr w0, w0, w2, lsl #16
    orr w0, w0, w3, lsl #24
    ret

.p2align 2
.globl _red_channel
_red_channel:
    and w0, w0, #255
    ret
```

These complete functions assume all four packing arguments are in 0…255. Add declarations `uint32_t pack_rgba(uint32_t r, uint32_t g, uint32_t b, uint32_t a);` and `uint32_t red_channel(uint32_t pixel);`. The four arguments arrive in `w0` through `w3`. In the first OR, the `lsl #8` is a shift applied to the source operand; it does not change `w1`.

For R=0x11, G=0x22, B=0x33, A=0x44, the intermediate packed values are 0x00002211, 0x00332211, and 0x44332211. `and` with 255 preserves only the low eight bits. Display hexadecimal in Swift with `String(pixel, radix: 16)`; this is an initializer that formats the value in base 16.

To extract green, first shift right by eight, then mask:

```asm
// Fragment: w0 is the packed input; w0 becomes green.
lsr w0, w0, #8
and w0, w0, #255
```

`lsr` inserts zeros at the top. The fragment belongs inside a named function with `ret`, alignment, and visibility directives as before.

### Your implementation

Add pack, red, green, blue, and alpha extraction functions. Keep the domain explicit rather than silently masking invalid packing arguments. Add Swift output that labels the hexadecimal packed value and each extracted channel. Create one packed pixel from decimal inputs and another from hexadecimal inputs to see that notation does not change the bits.

### After completing the whole lesson

**Checks:** `(0x11,0x22,0x33,0x44)` packs to `0x44332211`; black opaque packs to `0xff000000`; white opaque to `0xffffffff`. Extraction returns the original channels, including zero and 255. Do not reverse byte order merely because hexadecimal is written most significant digit first.

**Questions:** Why is masking needed after extracting green? Why does OR work here without carrying between fields? What would an out-of-contract input of 256 do to packing? Is the leftmost hexadecimal byte our red channel?

**Completion rubric:** five functions with declarations, round-trip examples, and a correct bit-position explanation. Suggested commit: `M01-L03: pack and unpack RGBA values`.

## M01-L04 — Register width and integer interpretation

**Prerequisite:** M01-L03. **Outcome:** distinguish byte, 32-bit, and 64-bit computations before calculating memory offsets.

### Explanation and worked code

`w0` and `x0` are two views of the same register. Writing `w0` also clears the upper 32 bits of `x0`. A CPU register has bits; signedness comes from how operations interpret them. `0xffffffff` represents UInt32.max or signed Int32 -1. The bits alone do not choose the interpretation.

Add this deliberate contrast:

```asm
.p2align 2
.globl _add_one_u32_then_widen
_add_one_u32_then_widen:
    add w0, w0, #1
    ret

.p2align 2
.globl _widen_then_add_one
_widen_then_add_one:
    mov w0, w0
    add x0, x0, #1
    ret
```

Add these declarations inside the header guard:

```c
uint64_t add_one_u32_then_widen(uint32_t value);
uint64_t widen_then_add_one(uint32_t value);
```

The first performs a 32-bit addition, so overflow wraps at 2^32. The second explicitly zeroes the upper half with a W-register write before doing 64-bit arithmetic. The self-move has a purpose: it establishes the width conversion without assuming unspecified upper argument bits. The result for UInt32.max is respectively zero and 4,294,967,296.

Add `uint64_t rgba_row_bytes(uint32_t width);` and implement it as `mov w0,w0`, `lsl x0,x0,#2`, `ret`. Shifting by two multiplies by four. A byte count should not accidentally be truncated to 32 bits. This function is an arithmetic demonstration, not permission to allocate enormous images.

Swift normally checks overflow in ordinary integer arithmetic. Raw assembly additions do not automatically reproduce that behavior. The engine will validate allocation arithmetic in Swift and use assembly only after its bounds are established.

### Your implementation

Add the three functions and compare them from Swift using UInt32 values and UInt64 results. Document why row-byte calculation uses the X view. Write a short table for widths 0, 1, 3, and UInt32.max; no image allocation is needed. Explain that preserving a wide arithmetic result does not prove sufficient memory exists.

### After completing the whole lesson

**Checks:** the two add functions agree on 0 and 254 but differ on UInt32.max; row-byte results are 0, 4, 12, and 17,179,869,180. Earlier packing and channel checks still work.

**Questions:** Does writing `w0` preserve the old high half of `x0`? Why is `mov w0,w0` useful here? Why would a W-register shift give a wrong large row size? What extra facts are needed before accessing that many bytes?

**Completion rubric:** correct wide results, explicit type declarations, no giant allocation, and a distinction between arithmetic validity and memory validity. Suggested commit: `M01-L04: understand register width and size arithmetic`.

## M01-L05 — Follow the machine in LLDB

**Prerequisite:** M01-L04. **Outcome:** explain an observed execution trace rather than guessing from source.

### Explanation and worked commands

A debugger pauses the process and exposes registers and memory. A source-line step may cross several instructions; an instruction step advances one machine instruction. The program counter, `pc`, identifies the instruction about to execute. Breakpoints let you stop at a function without manually stepping through Swift's startup.

Build with the debug commands, then:

```text
xcrun lldb .build/pixel
(lldb) breakpoint set --name invert_channel
(lldb) run
(lldb) disassemble --name invert_channel
(lldb) register read x0 x1 pc lr
(lldb) thread step-inst
(lldb) register read x0 x1 pc
(lldb) thread step-inst
(lldb) register read x0 x1 pc
(lldb) thread step-out
(lldb) continue
(lldb) quit
```

The `(lldb)` prefix is the debugger prompt; do not type it. `lr` is a name for x30. Register output often uses hexadecimal: 0x28 is 40, 0xd7 is 215. The debugger may display an instruction alias different from the mnemonic you wrote; aliases can name the same encoding. Debug symbols and Mach-O symbol presentation also mean breakpoints commonly use the source function name without the underscore.

If the breakpoint does not resolve, use `image lookup -n invert_channel`, confirm the function was linked and called, and inspect LLDB's help. Do not keep changing arithmetic code to solve a missing-symbol build problem. Distinguish build failures, link failures, and runtime mistakes.

### Your implementation

Make the driver call inversion with 40 first so the trace is predictable. Capture a short text trace showing the entry value, the 255 scratch value, and the 215 result. Trace `widen_then_add_one` separately using UInt32.max. Add a learner note explaining the observed machine code and any aliases. Save only relevant output, not a huge debugger transcript.

You may temporarily introduce a subtraction-order error to observe its effect, then fix it before committing. The goal is to connect symptoms to state, not to memorize debugger commands.

### After completing the whole lesson

**Checks:** all existing examples still produce their expected values; the trace identifies state before and after each relevant instruction; source and executable match the same build. Confirm the result register before `ret` rather than relying only on printed output.

**Questions:** What is the difference between `step-inst` and stepping over a function? Why can a breakpoint fail even when the source contains the function? What does `ret` use to know where to return? How did the width experiment appear in the debugger?

**Completion rubric:** usable debug build, concise trace, fixed deliberate errors, and explanations connected to observed registers. Suggested commit: `M01-L05: document assembly execution in LLDB`.

## Module references

- [Assembly and ABI reminder](../reference/assembly-and-abi.md)
- [Debugging reference](../reference/debugging.md)
- [Official documentation index](../reference/resources.md)
