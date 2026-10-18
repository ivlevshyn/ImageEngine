# Memory and Swift: the bridge used by this course

Read alongside Module 02. The goal is enough Swift to safely drive the assembly, with unfamiliar syntax explained by the tutor. Official links are in [resources](resources.md).

## Values, storage, and addresses

A pixel value such as 0xff332211 is a number. An image buffer is a region of stored bytes. A pointer identifies a location in that region. A pointer alone does not contain its length, ownership, element count, or lifetime. Passing a Swift array to assembly through a pointer temporarily crosses the boundary where Swift can enforce ordinary indexed bounds.

An array owns its storage through Swift's runtime. You should not assume its bytes live in a particular stack frame or at a stable address forever. Stack storage generally follows call lifetimes; heap-backed allocations can outlive individual calls when an owner retains them. Assembly borrowed pointers must respect whichever owner keeps the bytes alive.

## Essential Swift syntax

| Syntax | Meaning in the course |
| --- | --- |
| `let count = ...` | Binding you do not reassign. |
| `var image = ...` | Mutable variable. |
| `[UInt8]` | Array of byte values. |
| `UInt32`, `UInt64`, `Int32` | Integers with stated width and signedness. |
| `Int` | Native signed integer; use for Swift collection sizes, validate before converting. |
| `T?` | Optional T, possibly absent. |
| `guard let p = ... else { return }` | Unwrap an optional or leave the current scope. |
| `{ buffer in ... }` | Closure receiving a named argument. |
| `throws`, `try`, `do`/`catch` | Explicit error propagation and handling. |
| `mutating func` | A value-type method allowed to change its value. |
| `0..<n` | Half-open range: zero through n-1. |
| `&+`, `&*` | Explicit wrapping arithmetic; appropriate only when wrapping is intended. |

The tutor should explain these in the lesson where first used, not merely send you here. A conversion such as `UInt64(count)` does not make a negative count valid. Widen operands before arithmetic; assigning an already-overflowed result to a wider type cannot repair it.

## One mutable borrow

```swift
let pixelCount = image.width
guard pixelCount > 0 else { return }
image.bytes.withUnsafeMutableBufferPointer { buffer in
    guard let base = buffer.baseAddress else { return }
    fill_rgba_scalar(base, UInt64(pixelCount), 0xff000000)
}
```

This is a fragment inside a suitable wrapper, not a full image fill: it affects the first row only. Read needed dimensions before borrowing. Do not append, resize, reassign, or independently access `image.bytes` while the closure owns its mutable access. The raw pointer must not escape the closure or be retained by assembly.

## Two disjoint buffers

```swift
// Fragment inside a validated wrapper: source exists; destination was newly
// allocated; width/height are positive; all dimensions and origins are checked.
let sourceStride = source.stride
let destinationStride = destination.stride
source.bytes.withUnsafeBufferPointer { input in
    destination.bytes.withUnsafeMutableBufferPointer { output in
        guard let src = input.baseAddress, let dst = output.baseAddress else { return }
        crop_rgba_scalar(dst, UInt64(destinationStride),
                         src, UInt64(sourceStride),
                         UInt64(cropWidth), UInt64(cropHeight),
                         UInt64(originX), UInt64(originY))
    }
}
```

The destination's allocation establishes disjointness. Capturing scalar dimensions avoids overlapping access to the same Swift value. Immutable borrowing allows reads but does not license concurrent mutation elsewhere. Array copying uses value semantics and may initially share storage; do not use copied array addresses as a long-term aliasing guarantee.

## A minimal executable driver pattern

After M02 introduces `runChecks()` and throwing I/O helpers, the tutor may adapt this supporting code in `main.swift`:

```swift
import Foundation
import Darwin

do {
    let args = CommandLine.arguments
    if args.count == 2 && args[1] == "--self-test" {
        try runChecks()
        print("all checks passed")
    } else if args.count == 4 && args[1] == "invert" {
        var image = try readPPM(URL(fileURLWithPath: args[2]))
        image.invertScalar()
        try writePPM(image, to: URL(fileURLWithPath: args[3]))
    } else {
        print("usage: pixel --self-test | pixel invert input.ppm output.ppm")
        exit(2)
    }
} catch {
    let message = Data("error: \(error)\n".utf8)
    FileHandle.standardError.write(message)
    exit(1)
}
```

Make `runChecks` throwing when it calls throwing helpers; if it remains nonthrowing, omit `try` for that call. Argument zero is the executable name. File URLs identify filesystem paths. A nonzero exit code lets scripts and reviewers distinguish failure from a successful run. Do not let the CLI quietly continue after a failed image operation.

## Typed versus raw pointers

`UnsafePointer<UInt16>.advanced(by: 1)` advances one UInt16 element, two bytes. `UnsafePointer<UInt8>` advances one byte. Assembly address increments always mean bytes. Keep temporary-buffer strides explicitly labeled in elements or bytes, and convert once at the boundary. Do not rebind arbitrary UInt8 array storage to Float/UInt16 without understanding binding/alignment; allocate typed `[Float]` or `[UInt16]` arrays for those stages.

## Concurrency is a separate proof

For M10, all parallel work must finish while buffers are still borrowed. Jobs may share immutable input, write disjoint outputs, and use private scratch. A synchronous join establishes when the caller may reuse/free storage. No worker may start an asynchronous task that outlives that join.

Swift Sendable checks cannot prove the arithmetic partitioning of raw buffers. A narrow `@unchecked Sendable` carrier documents a manual promise, not automatic safety. The wrapper must justify its lifetime, nonoverlap, and lack of escape. Keep unchecked code localized; never disable project-wide checks to silence a real ownership problem.
