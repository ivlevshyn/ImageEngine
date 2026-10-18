import Foundation

func checkPixel(
    r: UInt32,
    g: UInt32,
    b: UInt32,
    a: UInt32,
    expected: UInt32
) {
    let packed = pack_rgba(r, g, b, a)

    guard packed == expected else {
        fatalError("Packing failed: expected 0x\(String(expected, radix: 16))" + "got 0x\(String(packed, radix: 16))")
    }

    let extracted: [UInt32] = [
        red_channel(packed),
        green_channel(packed),
        blue_channel(packed),
        alpha_channel(packed)
    ]

    let original: [UInt32] = [r, g, b, a]

    guard extracted == original else {
        fatalError("Extraction failed: expected \(original), got \(extracted)")
    }
}

let alpha: UInt32 = opaque_alpha()
let transparent: UInt32 = transparent_alpha()
print("opaque alpha = \(alpha)")
print("transparent alpha = \(transparent)")

let inverted: UInt32 = invert_channel(40)
print("Inverted 40 = \(inverted)")

let samples: [UInt32] = [0, 1, 40, 128, 255]

for value in samples {
    print("\(value) -> \(invert_channel(value))")
}

let doubled: UInt32 = double_channel_unclamped(200)
print("Doubled 200 = \(doubled)")

for value in samples {
    let restored = invert_channel(invert_channel(value))

    if restored != value {
        fatalError("Double inversion failed for \(value): got \(restored)")
    }
}

print("double inversion checks passed")

let packedExample: UInt32 = pack_rgba(0x11, 0x22, 0x33, 0x44)
print("packed RGBA = 0x\(String(packedExample, radix: 16))")

print("red = \(red_channel(packedExample))")
print("green = \(green_channel(packedExample))")
print("blue = \(blue_channel(packedExample))")
print("alpha = \(alpha_channel(packedExample))")

let packedDecimal: UInt32 = pack_rgba(17, 34, 51, 68)
print("packed from decimal = 0x\(String(packedDecimal, radix: 16))")

checkPixel(r: 0x11, g: 0x22, b: 0x33, a: 0x44, expected: 0x44332211)

checkPixel(r: 17, g: 34, b: 51, a: 68, expected: 0x44332211)

checkPixel(r: 0, g: 0, b: 0, a: 255, expected: 0xFF000000)

checkPixel(r: 255, g: 255, b: 255, a: 255, expected: 0xFFFFFFFF)

checkPixel(r: 255, g: 0, b: 255, a: 0, expected: 0x00FF00FF)

print("RGBA packing/unpacking tests passed")
