//
//  main.swift
//  
//
//  Created by Ivan Levshyn on 04/10/2026.
//

import Foundation

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
