# Official online resources

Curated 2026-10-03. Links below are primary documentation; they complement the course's original explanations. Some Apple/Swift pages use JavaScript and may expose a Markdown alternative for automated readers. If a URL moves, search the official site by the exact page title rather than substituting an unrelated tutorial. References are not mandatory pre-reading unless a lesson says so.

## Apple platform and tools

- [Writing ARM64 code for Apple platforms](https://developer.apple.com/documentation/xcode/writing-arm64-code-for-apple-platforms) — Apple's ABI differences. Consult when checking preserved state, stack rules, or adapting non-Apple examples.
- [Using imported C functions in Swift](https://developer.apple.com/documentation/swift/using-imported-c-functions-in-swift) — the documented header-based boundary used by the course, including pointer imports.
- [Array.withUnsafeMutableBufferPointer](https://developer.apple.com/documentation/swift/array/withunsafemutablebufferpointer(_:)) — the scoped storage access underlying our mutable borrows.
- [LLDB tutorial](https://lldb.llvm.org/use/tutorial.html) — breakpoints, stepping, and debugger operation.
- [LLDB command map](https://lldb.llvm.org/use/map.html) — command lookup when a remembered syntax is wrong.
- [Clang command-line reference](https://clang.llvm.org/docs/ClangCommandLineReference.html) — compilation flags. Apple's installed toolchain is authoritative for flags supported locally.

## Arm architecture and SIMD

- [Learn the architecture: A64 instruction set guide](https://developer.arm.com/documentation/102374/latest/) — instruction families and A64 concepts.
- [Arm Developer documentation](https://developer.arm.com/documentation) — starting point for the current A-profile architecture and instruction references. Look up the exact mnemonic and operand form, not only its name.
- [AAPCS64 on Arm's official GitHub](https://github.com/ARM-software/abi-aa/blob/main/aapcs64/aapcs64.rst) — generic procedure-call standard. Apply Apple's documented differences for this course.
- [Arm NEON intrinsics reference](https://arm-software.github.io/acle/neon_intrinsics/advsimd.html) — useful mapping from data types to AArch64 instruction forms. Check the supported-architecture/feature column; required course code is handwritten assembly.
- [Arm C Language Extensions](https://arm-software.github.io/acle/main/acle.html) — definitions and extension context; mainly an advanced lookup resource here.

## Swift foundations

- [The Swift Programming Language: basics](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/thebasics/) — values, types, optionals, and control flow. The tutor still explains needed syntax in each lesson.
- [Wrapping a C/C++ library in Swift](https://www.swift.org/documentation/articles/wrapping-c-cpp-library-in-swift.html) — module/header organization if you later move beyond the course's direct compiler commands.
- [DispatchQueue.concurrentPerform](https://developer.apple.com/documentation/dispatch/dispatchqueue/concurrentperform(iterations:execute:)) — synchronous parallel iteration used in the final module. Pointer lifetime and partition correctness remain the project's responsibility.

## Images and color

- [Netpbm PPM specification](https://netpbm.sourceforge.net/doc/ppm.html) — full PPM format. Our initial parser deliberately accepts a much smaller canonical 8-bit P6 subset; it is not a general implementation of this document.
- [Image I/O](https://developer.apple.com/documentation/imageio) — decoding and encoding through Apple frameworks in M10.
- [CGBitmapInfo](https://developer.apple.com/documentation/coregraphics/cgbitmapinfo) — bitmap byte-order and alpha-layout options. Validate the chosen layout with known pixels.
- [CSS Color 4: sample color conversion code](https://www.w3.org/TR/css-color-4/#color-conversion-code) — primary specification material for sRGB/linear conversion. The course uses the normalized nonnegative domain, not the full extended-color machinery.

## How to consult a reference

Start with a concrete question: 'Does this instruction widen before adding?', 'How many bytes does this structured load access?', or 'Which registers survive this call?'. Locate the exact operand arrangement and architecture version. Compare that behavior with the course's input bounds. Then return to the code and trace one example.

Do not read entire architecture manuals before beginning. Learn the small subset required by the current image feature, then expand deliberately. Documentation lookup is a skill developed alongside coding, not a prerequisite you must already have.
