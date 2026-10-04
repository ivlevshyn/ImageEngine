# Assembly and Apple ABI reminder

Use this after the relevant lesson introduces a topic. It is a course reminder, not an exhaustive ISA manual. Consult [official resources](resources.md) for authoritative instruction and platform details. Examples target AArch64 Mach-O on macOS.

## Reading an instruction

Most arithmetic examples use destination first: `sub w0,w1,w2` means put W1 minus W2 into W0. `#` introduces an immediate constant. Square brackets denote a memory address expression. A label names a location. A line beginning with a dot is usually an assembler directive, not a CPU instruction.

The assembler may encode a mnemonic as an alias of another instruction. For example a `mov` can become an OR or immediate-building operation. Disassembly showing an alias is not automatically a bug. Not every integer can be encoded in one immediate operand; use an appropriate constant-building sequence or load a constant when necessary.

## Register roles for our simple C boundary

| Register/view | Course use and obligation |
| --- | --- |
| X0–X7 / W0–W7 | Initial integer/pointer argument registers; simple integer result in X0/W0. Caller must assume scratch values can be changed. |
| X8–X15 | Useful scratch in our leaf examples. X8 has a special indirect-result role in some other interfaces; our simple returns do not use it. |
| X16–X17 | Linker/call scratch roles; do not expect values to survive a call. |
| X18 | Reserved on Apple platforms: do not use. |
| X19–X28 | Preserve incoming full 64-bit values if modified. |
| X29 | Frame pointer; keep the platform's frame-chain convention when creating a frame. |
| X30 / LR | Link register. `bl` replaces it with a return address. |
| SP | Stack pointer. Keep 16-byte alignment and restore it on every return. |
| XZR / WZR | Read as zero; writes are discarded. Not interchangeable with SP in arbitrary syntax. |
| V0–V7 | FP/SIMD argument/result and scratch registers for our interfaces. |
| V8–V15 | ABI preservation applies to their low 64 bits; full 128-bit preservation is not generally guaranteed across calls. Avoid them in early leaf examples. |
| V16–V31 | FP/SIMD scratch registers. |

Wn names the low 32 bits of Xn. A write through Wn clears Xn's upper half. Vn, Qn, Dn, Sn, Hn, and Bn describe views of vector/FP storage, not independent registers. Scalar FP arguments use their own allocation rules; do not count all mixed parameters into X0,X1,X2 indiscriminately. For complex structs, variadic calls, many parameters, or vector-by-value interfaces, consult the ABI before writing code. This course uses simple pointer/count interfaces to keep that complexity bounded.

## Conditions and flags

| Operation/condition | Meaning in these lessons |
| --- | --- |
| `add`, `sub` | Arithmetic without updating integer condition flags. |
| `adds`, `subs`, `cmp` | Update flags; `cmp` keeps only flags. |
| `eq`, `ne` | Equality / inequality based on flags. |
| `lt`, `le`, `gt`, `ge` | Signed comparisons. |
| `lo`, `ls`, `hi`, `hs` | Unsigned comparisons. |
| `cbz`, `cbnz` | Test a register for zero/nonzero directly. |
| `csel d,a,b,cond` | Select a if condition holds, otherwise b. |

Know which instruction last set the flags before a conditional branch or selection. A helper call cannot be assumed to preserve them. Counts and addresses normally use unsigned reasoning; signed color deltas need signed reasoning.

## Memory width and addressing

| Example | Access and pointer effect |
| --- | --- |
| `ldrb w1,[x0,#2]` | Read one byte at address X0+2; zero-extend into W1; X0 unchanged. |
| `strb w1,[x0]` | Store low byte only. |
| `ldr w1,[x0]` | Read four bytes. |
| `ldr x1,[x0]` | Read eight bytes. |
| `ldr q0,[x0]` | Read sixteen bytes. |
| `str w1,[x0],#4` | Store at old X0, then advance X0 by four. |
| `stp x29,x30,[sp,#-16]!` | Move SP down sixteen, then store the pair. |

No access width proves the allocation is valid. Ordinary unaligned data access support does not permit overread, and stack alignment is a separate ABI requirement. Pointer arithmetic in assembly is byte-based; typed Swift pointer advancement is element-based.

## Calls and stack frames

A leaf function makes no calls. If it uses only scratch registers and no stack storage, it often needs no frame. A non-leaf function must preserve its own return address and any live caller-clobbered data. Use callee-preserved registers only after saving their incoming values. Restore in the matching order and release exactly the allocated frame size.

M03-L02 gives a complete 64-byte frame. Frame chaining supports debugger backtraces. Unwind metadata such as `.cfi_startproc`, `.cfi_def_cfa`, `.cfi_offset`, and `.cfi_endproc` can describe frames to unwinding tools; add it with a worked explanation and validate it against the actual prologue/epilogue. Do not copy offsets from a different frame. Apple supports platform details such as a red zone, but the course deliberately allocates explicit frames rather than relying on it.

Comments should explain contracts and invariants: `x19 = current row base`, `x5 = remaining pixels`, or `sum <= 65408`. Comments that merely restate 'add adds' are useful only when first introducing syntax. Use distinct local labels per function so separately written kernels cannot collide.

## Mach-O conventions used here

Export `_function_name` in assembly and declare `function_name` in the C header. Code uses `.text`, `.p2align 2`, and `.globl`. Constant data uses an appropriate Mach-O section such as `__TEXT,__const`. Address symbols with supported relocations such as `@PAGE`/`@PAGEOFF`, not a runtime address copied from a debugger. Link through `xcrun swiftc` so the host application receives the required runtime/link settings.

Linux `_start`, ELF section recipes, and Linux syscall numbers are not our macOS program entry strategy. Swift's `main.swift` owns process startup. Keeping this boundary simple leaves the course focused on assembly image algorithms.
