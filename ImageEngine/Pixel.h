#ifndef PIXEL_H
#define PIXEL_H

#include <stdint.h>

uint32_t opaque_alpha(void);
uint32_t transparent_alpha(void);
uint32_t invert_channel(uint32_t channel);
uint32_t double_channel_unclamped(uint32_t channel);

    // Each input must be in 0...255.
    // Returns a packed pixel with integer layout 0xAABBGGRR.
uint32_t pack_rgba(uint32_t r, uint32_t g, uint32_t b, uint32_t a);

    // Input uses packed integer layout 0xAABBGGRR.
    // Each function returns its channel in 0...255.
uint32_t red_channel(uint32_t pixel);
uint32_t green_channel(uint32_t pixel);
uint32_t blue_channel(uint32_t pixel);
uint32_t alpha_channel(uint32_t pixel);

uint64_t add_one_u32_then_widen(uint32_t value);
uint64_t widen_then_add_one(uint32_t value);

// Returns width * 4 using 64 bits
// Calculates a byte count only; does not allocate or access memory
uint64_t rgba_row_bytes(uint32_t width);

#endif
