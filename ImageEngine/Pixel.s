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

.p2align 2
.globl _pack_rgba
_pack_rgba:
    orr w0, w0, w1, lsl #8
    orr w0, w0, w2, lsl #16
    orr w0, w0, w3, lsl #24
    ret

.p2align 2
.globl _red_channel
_red_channel:
    and w0, w0, #255
    ret

.p2align 2
.global _green_channel
_green_channel:
    lsr w0, w0, #8
    and w0, w0, #255
    ret

.p2align 2
.globl _blue_channel
_blue_channel:
    lsr w0, w0, #16
    and w0, w0, #255
    ret

.p2align 2
.globl _alpha_channel
_alpha_channel:
    lsr w0, w0, #24
    and w0, w0, #255
    ret
