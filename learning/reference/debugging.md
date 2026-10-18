# Debugging guide

Use debug builds to understand execution and release builds to measure performance. Refer to the [LLDB documentation](https://lldb.llvm.org/use/tutorial.html) for command details. Help is available inside LLDB; register display names can vary by toolchain.

## A short working session

```text
xcrun lldb .build/pixel
(lldb) breakpoint set --name invert_rgba_scalar
(lldb) run --self-test
(lldb) disassemble --name invert_rgba_scalar
(lldb) register read x0 x1 x2 x3 pc sp lr
(lldb) memory read --size 1 --format x --count 16 $x0
(lldb) thread step-inst
(lldb) thread step-inst-over
(lldb) thread backtrace
(lldb) continue
```

Type commands after the prompt; do not include `(lldb)`. `$x0` is an LLDB expression naming a register, not a shell variable in these debugger commands. Read only memory you know is valid. `step-inst` follows a call; `step-inst-over` runs through it to the next instruction. A backtrace helps connect the kernel to its Swift caller.

## Symptoms and first observations

| Symptom | First thing to inspect |
| --- | --- |
| Undefined symbol at link | Header name, assembly underscore/global directive, object included in link. |
| Illegal instruction | Wrong target or instruction extension; inspect actual encoding and CPU support. |
| Crash at load/store | Pointer value, access width, count, stride, and allocation lifetime. |
| First row correct, later rows wrong | Row-stride units and resetting the inner counter. |
| RGB correct, transparency wrong | Alpha mask or straight/premultiplied mismatch. |
| Width divisible by block works, others fail | Tail condition, count units, last pointer update. |
| Function never returns | X30 overwritten by a nested call, stack restore error, loop underflow. |
| Wrong only in release | Lifetime/exclusivity bug, missing checks, stale build, undefined assumptions; not proof of a compiler defect. |
| Seams at tile boundaries | Halo read coordinates or treating tile edges as image edges. |
| Blur differs by one | Extra intermediate rounding or a changed division contract. |

## A useful failing case

Reduce the image to the smallest dimensions that still fail. Give pixels distinct channels, keep padding marked, and record the exact parameters. Before stepping, calculate the expected addresses and values for one pixel on paper or in a small table. Compare the first point where actual state diverges. Debugging is easier when you know what a correct state would look like.

For a vector loop, record the remaining count, current pointer offset, lane arrangement, bytes read, and bytes written. Look at the last full block and first tail operation. A correct output checksum cannot show which lane was wrong; byte-level diagnostics can.

## Evidence to save for review

Save the command, implementation commit, input fixture or deterministic seed, relevant register/memory excerpt, expected/actual bytes, and eventual diagnosis. A screenshot can help but searchable text is preferable. Do not paste a whole process memory dump. Rebuild after editing: debugging stale machine code is a common avoidable source of confusion.

## Assembly and sanitizers

Compiler instrumentation generally cannot insert checks around every handwritten assembly access. Sanitizers can still help with surrounding Swift/C code, but a clean run does not prove a raw assembly kernel is in bounds. Sentinel bytes detect unexpected writes; they do not reveal a read whose result is discarded. Combine known-answer tests, loop-bound reasoning, and optional guarded-page fixtures when the course introduces the necessary OS code.
