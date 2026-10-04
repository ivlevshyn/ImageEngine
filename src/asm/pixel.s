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
