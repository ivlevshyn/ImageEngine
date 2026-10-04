;
//  pixel.s
//  
//
//  Created by Ivan Levshyn on 04/10/2026.
//

.text
.p2align 2
.globl _opaque_alpha
_opaque_alpha:
    mov w0, #255
    ret

.p2align 2
.globl _transparent_alpha
_transparent_alpha:
    mov w0, #0
    ret

.p2align 2
.globl _invert_channel
_invert_channel:
    mov w1, #255
    sub w0, w1, w0
    ret

.p2align 2
.globl _double_channel_unclamped
_double_channel_unclamped:
    add w0, w0, w0
    ret
