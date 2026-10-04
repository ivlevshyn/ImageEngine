# Module 02 — Pixels in memory

Prerequisite: Module 01. This module still supplies complete small kernels. Swift scaffolding is taught explicitly. All checks and questions belong after the entire lesson's implementation.

## M02-L01 — Read and write through a pointer

**Outcome:** invert the RGB bytes of one stored pixel. **New concepts:** address, dereference, byte access, borrowed storage.

### Explanation and worked code

A pointer is a number used as an address, not the pixel itself. `x0` can hold the address of four bytes; loading `[x0]` reads memory at that address. Adding one to the address selects the next byte. Registers do not know how large the allocation is.

Add `void invert_pixel(uint8_t *pixel);` to the header. The caller promises four writable bytes. This function preserves alpha by never touching offset 3:

```asm
.p2align 2
.globl _invert_pixel
_invert_pixel:
    mov w2, #255
    ldrb w1, [x0]
    sub w1, w2, w1
    strb w1, [x0]
    ldrb w1, [x0, #1]
    sub w1, w2, w1
    strb w1, [x0, #1]
    ldrb w1, [x0, #2]
    sub w1, w2, w1
    strb w1, [x0, #2]
    ret
```

`ldrb` loads one byte and zero-extends it into W1. `strb` writes only W1's low byte. Offsets are bytes. `ldr w1,[x0]` would read four bytes, which is a different operation. The pointer in X0 is unchanged.

The Swift call is deliberately scoped:

```swift
var bytes: [UInt8] = [10, 20, 30, 99]
bytes.withUnsafeMutableBufferPointer { buffer in
    guard let pointer = buffer.baseAddress else { return }
    invert_pixel(pointer)
}
print(bytes)
```

`var` permits modification. `[UInt8]` is an array of bytes. The braces are a closure: a block Swift executes while granting temporary access to its storage. `buffer` includes a pointer and count, but assembly receives only the pointer. `baseAddress` is optional because an empty buffer can lack storage. `guard let` unwraps it or leaves the closure. Do not save the pointer for later. Do not read or mutate `bytes` separately inside this mutable borrow.

### Your implementation

Add the function and driver. Add a second function that changes only the alpha byte to 255. State its four-byte precondition. Preserve earlier value-based functions; they teach a different interface. Use the debugger's byte-oriented memory read to inspect the buffer at entry and after return.

### After completing the whole lesson

**Checks:** inversion produces `[245,235,225,99]`; the alpha setter produces `[245,235,225,255]`; a second inversion restores the original RGB. Use a four-byte buffer, not an empty one, for this single-pixel API.

**Questions:** What is in X0: the pixel or its address? Why does `strb` not change the following byte? Why is the pointer valid inside the closure? Why is the single-pixel function not valid for an empty buffer?

**Completion rubric:** correct byte access, alpha policy, scoped borrowing, and a memory trace. Commit: `M02-L01: operate on a pixel buffer`.

## M02-L02 — Fill a row with a loop

**Outcome:** fill zero or more pixels with a packed color. **New concepts:** loop counters, post-index addressing, flags, zero-length behavior.

### Explanation and worked code

Declare `void fill_rgba_scalar(uint8_t *dst, uint64_t pixels, uint32_t rgba);`. X0 is the destination, X1 the pixel count, W2 the packed color. Require `4*pixels` writable bytes. The empty call must return before dereferencing the pointer.

```asm
.p2align 2
.globl _fill_rgba_scalar
_fill_rgba_scalar:
    cbz x1, L_fill_done
L_fill_loop:
    str w2, [x0], #4
    subs x1, x1, #1
    b.ne L_fill_loop
L_fill_done:
    ret
```

`cbz` means compare with zero and branch. `str w2,[x0],#4` stores four bytes at the current pointer, then advances it by four. `subs` subtracts and sets condition flags; `b.ne` repeats when the result was nonzero. Ordinary `sub` does not set those flags. With count 3, stores occur at offsets 0,4,8, then the counter reaches zero. The pointer advances to the end but is not dereferenced there.

In Swift, prepare 12 bytes and pass `UInt64(3)` plus `pack_rgba(10,20,30,255)` inside a mutable borrow. The count is pixels, not bytes. A type conversion changes representation; it does not validate a negative signed value, so do not blindly convert untrusted input.

### Your implementation

Add fill and a driver for counts 0,1,3. Introduce a small `check` helper in `src/swift/Checks.swift`:

```swift
func check(_ condition: Bool, _ message: String) {
    if !condition { fatalError("CHECK FAILED: \(message)") }
}
```

This takes a Boolean and message. A failed check stops the process with failure. Unlike a debug-only assertion, this remains an explicit check in our release builds. Group checks in `runChecks()` and call it from `main.swift` when `CommandLine.arguments.contains("--self-test")`. Update the compile command to include `src/swift/*.swift`.

### After completing the whole lesson

**Checks:** count 3 gives three copies of `[10,20,30,255]`. Use a larger array with four marker bytes before and after the active region; pass the pointer advanced by four and verify markers unchanged. For count zero, use a valid marker-buffer pointer and verify no changes; the kernel's early return must also make an empty pointer safe.

**Questions:** Why guard zero before the first store? What does post-indexing change? Why is `subs` needed before `b.ne`? What happens if a byte count is passed as pixels?

**Completion rubric:** correct count units, zero handling, bounded writes, and a release-effective check helper. Commit: `M02-L02: fill bounded pixel rows`.

## M02-L03 — Process rows with a stride

**Outcome:** invert a complete image without changing its padding. **New concepts:** nested loops and row address calculations.

### Explanation and worked code

A row may have more allocated bytes than visible pixels. Width tells us what to process; stride tells us where the next row begins. Declare `void invert_rgba_scalar(uint8_t *data, uint64_t width, uint64_t height, uint64_t stride);`.

```asm
.p2align 2
.globl _invert_rgba_scalar
_invert_rgba_scalar:
    cbz x1, L_inv_done
    cbz x2, L_inv_done
L_inv_row:
    mov x4, x0
    mov x5, x1
L_inv_pixel:
    ldr w6, [x4]
    eor w6, w6, #0x00ffffff
    str w6, [x4], #4
    subs x5, x5, #1
    b.ne L_inv_pixel
    add x0, x0, x3
    subs x2, x2, #1
    b.ne L_inv_row
L_inv_done:
    ret
```

On our layout, RGB occupy the low 24 bits and alpha the high 8. XOR with the mask complements RGB bits and leaves alpha unchanged. For an unsigned byte, complementing all eight bits equals `255-c`. X4 walks a row while X0 remains its base until the row ends. Resetting X5 each row is essential. Moving to the next row by width*4 would incorrectly consume padding.

### Your implementation

Add the function and a 2-by-2 fixture with stride 12: eight active bytes and four sentinel bytes per row. Add `build.sh` at the project root using the provided recipe:

```bash
#!/bin/bash
set -euo pipefail
mode="${1:-debug}"
case "$mode" in
  debug) swift_flags=(-g -Onone) ;;
  release) swift_flags=(-O) ;;
  *) echo "usage: bash build.sh [debug|release]" >&2; exit 2 ;;
esac
mkdir -p .build
objects=()
for source in src/asm/*.s; do
  object=".build/$(basename "${source%.s}").o"
  xcrun clang -arch arm64 -g -c "$source" -o "$object"
  objects+=("$object")
done
xcrun swiftc "${swift_flags[@]}" -import-objc-header src/bridge/Pixel.h \
  src/swift/*.swift "${objects[@]}" -o .build/pixel
```

This script stops on errors, compiles each assembly file, and links the resulting objects with all Swift files. Arrays preserve argument boundaries. Run `bash build.sh` and `.build/pixel --self-test`; `bash build.sh release` changes only the Swift optimization mode. Assembly instructions remain the ones you wrote. Keep unique assembly basenames if splitting files later.

### After completing the whole lesson

**Checks:** every active RGB byte is inverted, alpha and row padding unchanged; 0-by-N and N-by-0 return without stores; 1-by-1 and a tightly packed 3-by-2 image work. Build and run checks in both modes.

**Questions:** Why use two pointers for rows and pixels? Why can the XOR mask preserve alpha? What would happen if the inner counter were not reset? Does a stride prove the allocation contains that many rows?

**Completion rubric:** correct nested loop, padding preservation, empty behavior, and reproducible script. Commit: `M02-L03: process strided RGBA images`.

## M02-L04 — Own storage in Swift and borrow it safely

**Outcome:** a small image type validates allocation arithmetic and contains unsafe access. **New concepts:** ownership, overflow checks, exclusivity, wrapper versus kernel contracts.

### Explanation and worked code

The assembly routine sees an address and integers. Swift's wrapper must establish that those integers describe real storage. Checking after overflowing is too late. Supply this initial `Image.swift` and explain every new construct:

```swift
enum ImageError: Error {
    case invalidDimensions, invalidStride, excessiveSize, invalidFormat
}

struct Image {
    let width: Int
    let height: Int
    let stride: Int
    var bytes: [UInt8]

    init(width: Int, height: Int, stride requestedStride: Int? = nil) throws {
        guard width >= 0, height >= 0, width <= 16384, height <= 16384 else {
            throw ImageError.invalidDimensions
        }
        let (rowBytes, rowOverflow) = width.multipliedReportingOverflow(by: 4)
        guard !rowOverflow else { throw ImageError.excessiveSize }
        let stride = requestedStride ?? rowBytes
        guard stride >= rowBytes else { throw ImageError.invalidStride }
        let (count, sizeOverflow) = stride.multipliedReportingOverflow(by: height)
        guard !sizeOverflow, count <= 256 * 1024 * 1024 else {
            throw ImageError.excessiveSize
        }
        self.width = width
        self.height = height
        self.stride = stride
        self.bytes = [UInt8](repeating: 0, count: count)
    }

    mutating func invertScalar() {
        let w = width, h = height, s = stride
        guard w > 0, h > 0 else { return }
        bytes.withUnsafeMutableBufferPointer { buffer in
            guard let base = buffer.baseAddress else { return }
            invert_rgba_scalar(base, UInt64(w), UInt64(h), UInt64(s))
        }
    }
}
```

`struct` defines a value with fields. `let` dimensions are fixed after initialization. `throws` makes failure explicit; callers use `try`. An enum case identifies a category of error. `Int?` is optional; `??` selects a default when absent. The tuple from `multipliedReportingOverflow` contains a result and an overflow flag. `self.width` distinguishes a stored property from the parameter. `mutating` permits a value-type method to change its storage.

Local copies of dimensions avoid reaching back into the same value during a mutable borrow. Arrays have value semantics and may share backing storage until mutation; never assume two copied arrays retain equal pointers or that an address remains valid across resizing. Scope unsafe access narrowly.

### Your implementation

Use this image type in the existing checks. Add a `fillScalar(rgba:)` method using one row at a time and the earlier row kernel. Read the active byte count from validated dimensions; never pass the whole padded byte count as pixels. Keep errors surfaced through `do`/`catch` in the driver, with a clear message and a failing process outcome. The tutor should show a minimal example if this syntax is new.

### After completing the whole lesson

**Checks:** reject negative dimensions, stride smaller than active bytes, overflowing `Int.max` stride times height, and storage above the policy limit without allocating it. Accept a valid padded image and an empty image. Filling/inverting leave padding unchanged.

**Questions:** Who owns and frees the array storage? Why must the pointer not escape? What does the overflow flag prevent? Why copy dimensions before borrowing the mutable buffer?

**Completion rubric:** checked allocation, scoped pointers, explicit errors, correct empty behavior, and wrapper/kernel responsibilities. Commit: `M02-L04: validate and own image buffers in Swift`.

## M02-L05 — Read and write your first image files

**Outcome:** load a tiny P6 image, invert it, and write another. **New concepts:** binary versus text, exact payload boundaries, RGB-to-RGBA conversion.

### Explanation and supplied scaffolding

P6 uses an ASCII header followed by binary RGB samples. Our supported subset is exactly `P6\n<width> <height>\n255\n` followed by width*height*3 bytes, with positive dimensions. General PPM comments, arbitrary header whitespace, 16-bit samples, and multiple images are deliberately unsupported. Reject them clearly. This restriction makes the parser small and avoids treating binary whitespace-valued pixels as header whitespace.

Create `PPM.swift` with the following complete scaffolding. The tutor explains Foundation, `Data`, ranges, throwing, and array slices before expecting independent modifications.

```swift
import Foundation

func readPPM(_ url: URL) throws -> Image {
    let raw = [UInt8](try Data(contentsOf: url))
    var cursor = 0
    func line() throws -> String {
        guard cursor < raw.count,
              let end = raw[cursor...].firstIndex(of: 10),
              end - cursor <= 128,
              let text = String(bytes: raw[cursor..<end], encoding: .ascii) else {
            throw ImageError.invalidFormat
        }
        cursor = end + 1
        return text
    }
    guard try line() == "P6" else { throw ImageError.invalidFormat }
    let fields = try line().split(separator: " ", omittingEmptySubsequences: false)
    guard fields.count == 2,
          fields.allSatisfy({ !$0.isEmpty && $0.utf8.allSatisfy({ $0 >= 48 && $0 <= 57 }) }),
          let w = Int(fields[0]), let h = Int(fields[1]), w > 0, h > 0 else {
        throw ImageError.invalidFormat
    }
    guard try line() == "255" else { throw ImageError.invalidFormat }
    var image = try Image(width: w, height: h)
    let payload = w * h * 3 // Safe after Image's stricter RGBA allocation validation.
    guard raw.count - cursor == payload else { throw ImageError.invalidFormat }
    for y in 0..<h {
        for x in 0..<w {
            let source = cursor + (y * w + x) * 3
            let target = y * image.stride + x * 4
            image.bytes[target] = raw[source]
            image.bytes[target + 1] = raw[source + 1]
            image.bytes[target + 2] = raw[source + 2]
            image.bytes[target + 3] = 255
        }
    }
    return image
}

func writePPM(_ image: Image, to url: URL) throws {
    guard image.width > 0, image.height > 0 else { throw ImageError.invalidDimensions }
    var output = Data("P6\n\(image.width) \(image.height)\n255\n".utf8)
    for y in 0..<image.height {
        for x in 0..<image.width {
            let i = y * image.stride + x * 4
            guard image.bytes[i + 3] == 255 else { throw ImageError.invalidFormat }
            output.append(contentsOf: image.bytes[i..<(i + 3)])
        }
    }
    try output.write(to: url)
}
```

`0..<h` excludes h. The writer emits only active RGB bytes; padding and alpha do not belong in PPM. Rejecting nonopaque alpha avoids silently losing transparency. This teaching reader loads the file before validating its dimensions; a production streaming parser with an input-byte limit is a later optional hardening task. Use small trusted fixtures here.

### Your implementation

Add a CLI path `pixel invert input.ppm output.ppm` alongside `--self-test`. The tutor supplies the small `CommandLine.arguments` dispatch and `do`/`catch` plumbing if needed. Generate a 2-by-2 fixture with distinct corners through your own writer. Load it, call `invertScalar()`, save it, and retain the original. Record the deliberately limited format support in the project README.

### After completing the whole lesson

**Checks:** opaque RGB write/read is exact; inversion changes only intended RGB; first raster bytes of 10,13,32,35 are preserved as data; truncated/extra payloads and unsupported headers fail; a padded input image writes the correct active pixels. Inspect output visually if a viewer supports the subset, but use byte checks as the authority.

**Questions:** Why must the parser stop at an exact binary boundary? Why are alpha and padding absent from the file? Why does the payload multiplication follow dimension validation? What format inputs does this reader intentionally reject?

**Completion rubric:** end-to-end file transform, truthful format limits, exact binary parsing, and retained scalar tests. Commit: `M02-L05: transform PPM images end to end`.

## Module references

- [Memory and Swift](../reference/memory-and-swift.md)
- [Debugging](../reference/debugging.md)
- [Official PPM specification and Swift sources](../reference/resources.md)
