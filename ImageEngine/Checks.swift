import Foundation

func check(_ condition: Bool, _ message: String) {
    if !condition {
        fatalError("CHECK FAILED: \(message)")
    }
}

func runChecks() {
    let color: UInt32 = pack_rgba(10, 20, 30, 255)
    let marker: UInt8 = 0xA5
    let markers = [UInt8](repeating: marker, count: 4)

    for pixelCount in [0, 1, 3] {
        let activeByteCount = pixelCount * 4

        var storage = [UInt8](
            repeating: marker, count: activeByteCount + 8
        )

        storage.withUnsafeMutableBufferPointer{ buffer in
            guard let base = buffer.baseAddress else {
                fatalError("Expected storage for marker bytes")
            }

            let destination = base.advanced(by: 4)

            fill_rgba_scalar(destination, UInt64(pixelCount), color)
        }

        check(Array(storage.prefix(4)) == markers,
              "count \(pixelCount): leading markers changed"
        )

        check(Array(storage.suffix(4)) == markers,
              "count \(pixelCount): trailing markers changed"
        )

        var expected: [UInt8] = []

        for _ in 0..<pixelCount {
            expected.append(contentsOf: [10, 20, 30, 255])
        }

        let actual = Array(storage[4..<(4 + activeByteCount)])

        check(actual == expected,
              "count \(pixelCount): expected \(expected), got \(actual)")
    }

    fill_rgba_scalar(nil, 0, color)

    print("Fill checks passed")
}
