def C3  equ 44
def CS3 equ 156
def D3  equ 262
def DS3 equ 363
def E3  equ 457
def F3  equ 547
def FS3 equ 631
def G3  equ 710
def GS3 equ 786
def A3  equ 854
def AS3 equ 923
def B3  equ 986
def C4  equ 1046
def CS4 equ 1102
def D4  equ 1155
def DS4 equ 1205
def E4  equ 1253
def F4  equ 1297
def FS4 equ 1339
def G4  equ 1379
def GS4 equ 1417
def A4  equ 1452
def AS4 equ 1486
def B4  equ 1517
def C5  equ 1546
def CS5 equ 1575
def D5  equ 1602

def FRAMERATE equ 60
def TEMPO     equ 130
def BPS       equ (TEMPO / 60)
def BEAT      equ (FRAMERATE / BPS)
def WHOLE     equ (BEAT * 4)
def HALF      equ (BEAT * 2)
def QUARTER   equ (BEAT)
def EIGHTH    equ (BEAT / 2)
def SIXTEENTH equ (BEAT / 4)

def CH_CONTROL    equ $00
def CH_AMP        equ $01
def OP_FREQ       equ $02
def OP_AMP        equ $03
def ADSR_ATTACK   equ $04
def ADSR_DECAY    equ $05
def ADSR_SUSTAIN  equ $06
def ADSR_RELEASE  equ $07
def ADSR_BASEL    equ $08
def ADSR_PEAKL    equ $09
def ADSR_SUSTAINL equ $0a

def OP1 equ $01
def OP2 equ $02
def OP3 equ $04
def OP4 equ $08

macro multiply_by_3
    add a, a
    add a, a
endm

macro copy_channel_operator
    ld a, (((\1) - 1) | (((\2) - 1) << 3) | (((\3) - 1) << 5))
    ld hl, $b001
    ld [hl], a
endm

macro copy_channel
    ld a, ((\1) - 1) | (((\2) - 1) << 4)
    ld hl, $b000
    ld [hl], a
endm

macro set_channel_operator
    ld hl, ($a000 | (((\1) - 1) << 8) | (((\2) - 1) << 4))
endm

macro set_register_to_bc
    ld a, l
    and a, $f0
    or a, \1
    ld l, a
    call aec1_load16
endm

macro set_register
    ld a, l
    and a, $f0
    or a, \1
    ld l, a
    ld bc, \2
    call aec1_load16
endm

macro copy_last
    call aec1_load16
endm

macro set_patch
    ld de, \1
    call aec1_init_patch
endm

macro play_channel
    push hl
    ld hl, ($a000 | (((\1) - 1) << 8))
    ld a, ($80 | (\2))
    ld [hl], a
    pop hl
endm

section "vblank", rom0[$0040]

vblank_handler:
    ; Get frame count
    ld a, [$c001]

    ; If 0, then reload count and play sound
    jr nz, .continue

    ; Increment Note Index
    ld a, [$c000]
    inc a
    ld [$c000], a

    ; Load DE with pointer to music data
    ld de, music_data

    ; Load HL with index
    ld hl, $0000
    ld l, a

    ; Multiply HL by 3
    add hl, hl
    add hl, hl

    ; Add in pointer to music data
    add hl, de

    ; Read frequency
    ld a, [hli]
    ld c, a
    ld a, [hli]
    ld b, a

    ; Play sound
    set_channel_operator 1, 3
    set_register_to_bc OP_FREQ
    
    set_channel_operator 1, 4
    set_register_to_bc OP_FREQ

    play_channel 1, OP3 | OP4

    ; Read in frame count
    ld a, [hl]

    ; And store as new frame count
    ld [$c001], a
    reti

.continue:
    ; Else just decrement frame count
    dec a

    ; And store new value
    ld [$c001], a
    reti
    
section "entry", rom0[$0100]

entry:
    nop
    jp start

section "main", rom0[$0150]

start:
    ld a, $ff
    ldh [$ff00+$24], a

    ld sp, $cffe
    call aec1_init

    ; Set up channel 1 patch:
    ; ---------------------------------------------------
    ; Set channel 1's operator 3 patch to bass1_operator3
    set_channel_operator 1, 3
    set_patch bass1_operator3

    ; Copy channel 1's operator data from 3 to 4
    copy_channel_operator 1, 3, 4

    ; Change operator 4 
    set_channel_operator 1, 4
    set_register ADSR_PEAKL, $0001
    copy_last

    ; Set up Music Player state
    ld a, $ff
    ld [$c000], a
    xor a
    ld [$c001], a

    ; Set up Vblank
    ld a, $01
    ld [$ff00+$ff], a
    ei 

.inf jr .inf
.inf2 jr .inf

section "util", rom0[$1000]

; Set all channel's volumes to max
aec1_init:
    ld hl, $a001

.loop
    ld a, $ff
    ld [hl], a
    inc h
    ld a, h
    cp $a1
    jr nz, .loop
    ret

; hl -> channel/operator
; de -> patch
aec1_init_patch:
    ld a, h
    or a, $a0
    ld h, a
    ld a, l
    or a, $04
    ld l, a
    
.loop
    ld a, [de]
    ld [hl], a
    inc de
    ld a, [de]
    ld [hli], a
    inc de
    ld a, l
    and a, $0f
    cp a, $0b
    jr nz, .loop
    ret

aec1_load16:
    ld a, c
    ld [hl], a
    ld a, b
    ld [hli], a
    ret

section "patch", rom0[$2000]

bass1_operator3:
    db $0a, $00 ; ADSR attack          10   ms
    db $00, $00 ; ADSR decay           0    ms
    db $00, $00 ; ADSR sustain         0    ms
    db $b8, $0b ; ADSR release         2000 ms
    db $00, $00 ; ADSR base level      0 units
    db $0f, $00 ; ADSR peak level      15 units
    db $0f, $00 ; ADSR sustain level   15 units

section "music", rom0[$3000]

music_data:
    dw G3
    db WHOLE
    dw G3
    db WHOLE
    dw GS3
    db WHOLE
    dw GS3
    db WHOLE
    dw G3
    db WHOLE
    dw G3
    db WHOLE
    dw GS3
    db WHOLE
    dw GS3
    db WHOLE