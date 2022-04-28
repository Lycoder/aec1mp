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
def E5  equ 1650
def F5  equ 1673
def FS5 equ 1694
def G5  equ 1714
def GS5 equ 1732
def A5  equ 1750
def AS5 equ 1767
def B5  equ 1783
def C6  equ 1798
def CS6 equ 1812
def D6  equ 1825
def DS6 equ 1837
def E6  equ 1849
def F6  equ 1860
def FS6 equ 1871
def G6  equ 1881
def GS6 equ 1890
def A6  equ 1899
def AS6 equ 1907
def B6  equ 1915
def C7  equ 1923
def CS7 equ 1930
def D7  equ 1936
def DS7 equ 1943
def E7  equ 1949
def F7  equ 1954
def FS7 equ 1959
def G7  equ 1964
def GS7 equ 1969
def A7  equ 1974
def AS7 equ 1978
def B7  equ 1982
def C8  equ 1985
def CS8 equ 1988
def D8  equ 1992
def DS8 equ 1995
def E8  equ 1998
def F8  equ 2001
def FS8 equ 2004
def G8  equ 2006
def GS8 equ 2009
def A8  equ 2011
def AS8 equ 2013
def B8  equ 2015

def FRAMERATE equ 60
def TEMPO     equ 120
def BPS       equ 2
def BEAT      equ 30
def WHOLE     equ 135
def HALF      equ 65
def QUARTER   equ 32
def EIGHTH    equ 16
def SIXTEENTH equ 8

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
def OP_MUL        equ $0b
def OP_DETUNE     equ $0c
def CH_ALG_LFOEN  equ $0d
def CH_LFO_FREQ   equ $0e
def CH_LFO_LEVEL  equ $0f

def OP1 equ $01
def OP2 equ $02
def OP3 equ $04
def OP4 equ $08

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

macro set_channel
    ld hl, ($a000 | (((\1) - 1) << 8))
endm

macro set_register16_to_bc
    ld a, l
    and a, $f0
    or a, \1
    ld l, a
    call aec1_load16
endm

macro set_register16
    ld a, l
    and a, $f0
    or a, \1
    ld l, a
    ld bc, \2
    call aec1_load16
endm

macro set_register8
    ld a, l
    and a, $f0
    or a, \1
    ld l, a
    ld a, \2
    ld [hl], a
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
    jp mp_play_all_channels

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
    set_register16 ADSR_PEAKL, $0001
    copy_last

    ; Set up channel 2-5 patch:
    ; ---------------------------------------------------
    ; Set channel 1's operator 3 patch to bass1_operator3
    set_channel 2
    set_register8 CH_ALG_LFOEN, $80
    set_register8 CH_LFO_LEVEL, $02
    set_register8 CH_LFO_FREQ, $a0

    set_channel_operator 2, 3
    set_patch lead1_operator3

    set_channel_operator 2, 3
    set_register8 OP_MUL, $1

    ; Copy channel 1's operator data from 3 to 4
    copy_channel_operator 2, 3, 4
    ;copy_channel_operator 2, 3, 2

    ;set_channel_operator 2, 3
    ;set_register8 OP_MUL, $1

    ; Change operator 4 
    set_channel_operator 2, 4
    set_register16 ADSR_RELEASE, $07d0
    set_register16 ADSR_PEAKL, $0001
    copy_last

    copy_channel 2, 3
    copy_channel 2, 4
    copy_channel 2, 5

    ; Set up Music Player state
    ld a, $ff
    ld [$c000], a
    ld [$c002], a
    ld [$c004], a
    ld [$c006], a
    ld [$c008], a
    xor a
    ld [$c001], a
    ld [$c003], a
    ld [$c005], a
    ld [$c007], a
    ld [$c009], a

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
    cp $a8
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

mp_play_all_channels:
    call mp_play_note_channel_1
    call mp_play_note_channel_2
    call mp_play_note_channel_3
    call mp_play_note_channel_4
    call mp_play_note_channel_5
    reti

macro load_note_frame_count
    ld a, [($c000 | (((\1) - 1) * 2) + 1)]
endm

macro store_note_frame_count
    ld [($c000 | (((\1) - 1) * 2) + 1)], a
endm

macro load_note_index
    ld a, [($c000 | (((\1) - 1) * 2))]
endm

macro store_note_index
    ld [($c000 | (((\1) - 1) * 2))], a
endm

; ---------------------------------------------------------------
; Play note channel 1
; ---------------------------------------------------------------
mp_play_note_channel_1:
    ; Get channel 1 frame count
    load_note_frame_count 1

    and a, a

    ; If 0, then reload count and play sound
    jr nz, .continue

    ; Increment Note Index
    load_note_index 1
    inc a
    store_note_index 1

    ; Load DE with pointer to music data
    ld de, channel_1_data

    ; Load HL with index
    ld hl, $0000
    ld l, a

    ; Multiply HL by 3
    ld b, h
    ld c, l

    add hl, hl
    add hl, bc

    ; Add in pointer to music data
    add hl, de

    ; Read frequency
    ld a, [hli]
    ld c, a
    ld a, [hli]
    ld b, a

    ; Read in frame count
    ld a, [hl]

    ; And store as new frame count
    store_note_frame_count 1

    ld a, c
    or a, b

    jp z, .silence

    ; Play sound
    set_channel_operator 1, 3
    set_register16_to_bc OP_FREQ
    
    set_channel_operator 1, 4
    set_register16_to_bc OP_FREQ

    play_channel 1, OP1 | OP2 | OP3 | OP4

.silence:
    ret

.continue:
    ; Else just decrement frame count
    dec a

    ; And store new value
    store_note_frame_count 1
    ret

; ---------------------------------------------------------------
; Play note channel 2
; ---------------------------------------------------------------
mp_play_note_channel_2:
    ; Get channel 1 frame count
    load_note_frame_count 2

    and a, a

    ; If 0, then reload count and play sound
    jr nz, .continue

    ; Increment Note Index
    load_note_index 2
    inc a
    store_note_index 2

    ; Load DE with pointer to music data
    ld de, channel_2_data

    ; Load HL with index
    ld hl, $0000
    ld l, a

    ; Multiply HL by 3
    ld b, h
    ld c, l

    add hl, hl
    add hl, bc

    ; Add in pointer to music data
    add hl, de

    ; Read frequency
    ld a, [hli]
    ld c, a
    ld a, [hli]
    ld b, a

    ; Read in frame count
    ld a, [hl]

    ; And store as new frame count
    store_note_frame_count 2

    ld a, c
    or a, b

    jp z, .silence

    ; Play sound
    set_channel_operator 2, 3
    set_register16_to_bc OP_FREQ
    
    set_channel_operator 2, 4
    set_register16_to_bc OP_FREQ

    play_channel 2, OP1 | OP2 | OP3 | OP4

.silence:
    ret

.continue:
    ; Else just decrement frame count
    dec a

    ; And store new value
    store_note_frame_count 2
    ret

; ---------------------------------------------------------------
; Play note channel 3
; ---------------------------------------------------------------
mp_play_note_channel_3:
    ; Get channel 1 frame count
    load_note_frame_count 3

    and a, a

    ; If 0, then reload count and play sound
    jr nz, .continue

    ; Increment Note Index
    load_note_index 3
    inc a
    store_note_index 3

    ; Load DE with pointer to music data
    ld de, channel_3_data

    ; Load HL with index
    ld hl, $0000
    ld l, a

    ; Multiply HL by 3
    ld b, h
    ld c, l

    add hl, hl
    add hl, bc

    ; Add in pointer to music data
    add hl, de

    ; Read frequency
    ld a, [hli]
    ld c, a
    ld a, [hli]
    ld b, a

    ; Read in frame count
    ld a, [hl]

    ; And store as new frame count
    store_note_frame_count 3

    ld a, c
    or a, b

    jp z, .silence

    ; Play sound
    set_channel_operator 3, 3
    set_register16_to_bc OP_FREQ
    
    set_channel_operator 3, 4
    set_register16_to_bc OP_FREQ

    play_channel 3, OP1 | OP2 | OP3 | OP4

.silence:
    ret

.continue:
    ; Else just decrement frame count
    dec a

    ; And store new value
    store_note_frame_count 3
    ret

; ---------------------------------------------------------------
; Play note channel 4
; ---------------------------------------------------------------
mp_play_note_channel_4:
    ; Get channel 1 frame count
    load_note_frame_count 4

    and a, a

    ; If 0, then reload count and play sound
    jr nz, .continue

    ; Increment Note Index
    load_note_index 4
    inc a
    store_note_index 4

    ; Load DE with pointer to music data
    ld de, channel_4_data

    ; Load HL with index
    ld hl, $0000
    ld l, a

    ; Multiply HL by 3
    ld b, h
    ld c, l

    add hl, hl
    add hl, bc

    ; Add in pointer to music data
    add hl, de

    ; Read frequency
    ld a, [hli]
    ld c, a
    ld a, [hli]
    ld b, a

    ; Read in frame count
    ld a, [hl]

    ; And store as new frame count
    store_note_frame_count 4

    ld a, c
    or a, b

    jp z, .silence

    ; Play sound
    set_channel_operator 4, 3
    set_register16_to_bc OP_FREQ
    
    set_channel_operator 4, 4
    set_register16_to_bc OP_FREQ

    play_channel 4, OP1 | OP2 | OP3 | OP4

.silence:
    ret

.continue:
    ; Else just decrement frame count
    dec a

    ; And store new value
    store_note_frame_count 4
    ret

; ---------------------------------------------------------------
; Play note channel 5
; ---------------------------------------------------------------
mp_play_note_channel_5:
    ; Get channel 1 frame count
    load_note_frame_count 5

    and a, a

    ; If 0, then reload count and play sound
    jr nz, .continue

    ; Increment Note Index
    load_note_index 5
    inc a
    store_note_index 5

    ; Load DE with pointer to music data
    ld de, channel_5_data

    ; Load HL with index
    ld hl, $0000
    ld l, a

    ; Multiply HL by 3
    ld b, h
    ld c, l

    add hl, hl
    add hl, bc

    ; Add in pointer to music data
    add hl, de

    ; Read frequency
    ld a, [hli]
    ld c, a
    ld a, [hli]
    ld b, a

    ; Read in frame count
    ld a, [hl]

    ; And store as new frame count
    store_note_frame_count 5

    ld a, c
    or a, b

    jp z, .silence

    ; Play sound
    set_channel_operator 5, 3
    set_register16_to_bc OP_FREQ
    
    set_channel_operator 5, 4
    set_register16_to_bc OP_FREQ

    play_channel 5, OP1 | OP2 | OP3 | OP4

.silence:
    ret

.continue:
    ; Else just decrement frame count
    dec a

    ; And store new value
    store_note_frame_count 5
    ret

; ---------------------------------------------------------------
; Play note channel 6
; ---------------------------------------------------------------
mp_play_note_channel_6:
    ; Get channel 1 frame count
    load_note_frame_count 6

    and a, a

    ; If 0, then reload count and play sound
    jr nz, .continue

    ; Increment Note Index
    load_note_index 6
    inc a
    store_note_index 6

    ; Load DE with pointer to music data
    ld de, channel_6_data

    ; Load HL with index
    ld hl, $0000
    ld l, a

    ; Multiply HL by 3
    ld b, h
    ld c, l

    add hl, hl
    add hl, bc

    ; Add in pointer to music data
    add hl, de

    ; Read frequency
    ld a, [hli]
    ld c, a
    ld a, [hli]
    ld b, a

    ; Read in frame count
    ld a, [hl]

    ; And store as new frame count
    store_note_frame_count 6

    ld a, c
    or a, b

    jp z, .silence

    ; Play sound
    set_channel_operator 6, 3
    set_register16_to_bc OP_FREQ
    
    set_channel_operator 6, 4
    set_register16_to_bc OP_FREQ

    play_channel 6, OP1 | OP2 | OP3 | OP4

.silence:
    ret

.continue:
    ; Else just decrement frame count
    dec a

    ; And store new value
    store_note_frame_count 6
    ret

; ---------------------------------------------------------------
; Play note channel 7
; ---------------------------------------------------------------
mp_play_note_channel_7:
    ; Get channel 1 frame count
    load_note_frame_count 7

    and a, a

    ; If 0, then reload count and play sound
    jr nz, .continue

    ; Increment Note Index
    load_note_index 7
    inc a
    store_note_index 7

    ; Load DE with pointer to music data
    ld de, channel_7_data

    ; Load HL with index
    ld hl, $0000
    ld l, a

    ; Multiply HL by 3
    ld b, h
    ld c, l

    add hl, hl
    add hl, bc

    ; Add in pointer to music data
    add hl, de

    ; Read frequency
    ld a, [hli]
    ld c, a
    ld a, [hli]
    ld b, a

    ; Read in frame count
    ld a, [hl]

    ; And store as new frame count
    store_note_frame_count 7

    ld a, c
    or a, b

    jp z, .silence

    ; Play sound
    set_channel_operator 7, 3
    set_register16_to_bc OP_FREQ
    
    set_channel_operator 7, 4
    set_register16_to_bc OP_FREQ

    play_channel 7, OP1 | OP2 | OP3 | OP4

.silence:
    ret

.continue:
    ; Else just decrement frame count
    dec a

    ; And store new value
    store_note_frame_count 7
    ret

; ---------------------------------------------------------------
; Play note channel 8
; ---------------------------------------------------------------
mp_play_note_channel_8:
    ; Get channel 1 frame count
    load_note_frame_count 8

    and a, a

    ; If 0, then reload count and play sound
    jr nz, .continue

    ; Increment Note Index
    load_note_index 8
    inc a
    store_note_index 8

    ; Load DE with pointer to music data
    ld de, channel_8_data

    ; Load HL with index
    ld hl, $0000
    ld l, a

    ; Multiply HL by 3
    ld b, h
    ld c, l

    add hl, hl
    add hl, bc

    ; Add in pointer to music data
    add hl, de

    ; Read frequency
    ld a, [hli]
    ld c, a
    ld a, [hli]
    ld b, a

    ; Read in frame count
    ld a, [hl]

    ; And store as new frame count
    store_note_frame_count 8

    ld a, c
    or a, b

    jp z, .silence

    ; Play sound
    set_channel_operator 8, 3
    set_register16_to_bc OP_FREQ
    
    set_channel_operator 8, 4
    set_register16_to_bc OP_FREQ

    play_channel 8, OP1 | OP2 | OP3 | OP4

.silence:
    ret

.continue:
    ; Else just decrement frame count
    dec a

    ; And store new value
    store_note_frame_count 8
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

lead1_operator3:
    db $0a, $00 ; ADSR attack          10   ms
    db $00, $00 ; ADSR decay           0    ms
    db $00, $00 ; ADSR sustain         0    ms
    db $00, $02 ; ADSR release         250 ms
    db $00, $00 ; ADSR base level      0 units
    db $05, $00 ; ADSR peak level      15 units
    db $05, $00 ; ADSR sustain level   15 units

section "music", rom0[$3000]

channel_1_data:
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

    channel_2_data:
    dw C7
    db EIGHTH
    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH
    
    dw C7
    db EIGHTH
    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH
    
    dw C7
    db EIGHTH
    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH
    
    dw C7
    db EIGHTH
    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH
    
    dw C7
    db EIGHTH
    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH
    
    dw C7
    db EIGHTH
    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH
    
    dw C7
    db EIGHTH
    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH
    
    dw C7
    db EIGHTH
    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH

    dw C7
    db EIGHTH
    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH
    
    dw C7
    db EIGHTH
    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH
    
    dw C7
    db EIGHTH
    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH
    
    dw C7
    db EIGHTH
    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH
    
    dw C7
    db EIGHTH
    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH
    
    dw C7
    db EIGHTH
    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH
    
    dw C7
    db EIGHTH
    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH
    
    dw C7
    db EIGHTH
    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH

    ; -------------------------
    ; End
    ; -------------------------
    dw $0000
    db WHOLE
    dw $0000
    db WHOLE
    dw $0000
    db WHOLE
    dw $0000
    db WHOLE

channel_3_data:
    dw $0000
    db EIGHTH
    dw AS6
    db EIGHTH
    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH

    dw $0000
    db EIGHTH
    dw AS6
    db EIGHTH
    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH

    dw $0000
    db EIGHTH
    dw AS6
    db EIGHTH
    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH

    dw $0000
    db EIGHTH
    dw AS6
    db EIGHTH
    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH

    dw $0000
    db EIGHTH
    dw AS6
    db EIGHTH
    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH

    dw $0000
    db EIGHTH
    dw AS6
    db EIGHTH
    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH

    dw $0000
    db EIGHTH
    dw AS6
    db EIGHTH
    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH

    dw $0000
    db EIGHTH
    dw AS6
    db EIGHTH
    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH

    dw $0000
    db EIGHTH
    dw AS6
    db EIGHTH
    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH

    dw $0000
    db EIGHTH
    dw AS6
    db EIGHTH
    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH

    dw $0000
    db EIGHTH
    dw AS6
    db EIGHTH
    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH

    dw $0000
    db EIGHTH
    dw AS6
    db EIGHTH
    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH

    dw $0000
    db EIGHTH
    dw AS6
    db EIGHTH
    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH

    dw $0000
    db EIGHTH
    dw AS6
    db EIGHTH
    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH

    dw $0000
    db EIGHTH
    dw AS6
    db EIGHTH
    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH

    dw $0000
    db EIGHTH
    dw AS6
    db EIGHTH
    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH

    ; -------------------------
    ; End
    ; -------------------------
    dw $0000
    db WHOLE
    dw $0000
    db WHOLE
    dw $0000
    db WHOLE
    dw $0000
    db WHOLE

channel_4_data:
    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH
    dw F6
    db EIGHTH
    dw $0000
    db EIGHTH

    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH
    dw F6
    db EIGHTH
    dw $0000
    db EIGHTH

    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH
    dw F6
    db EIGHTH
    dw $0000
    db EIGHTH

    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH
    dw F6
    db EIGHTH
    dw $0000
    db EIGHTH

    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH
    dw F6
    db EIGHTH
    dw $0000
    db EIGHTH

    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH
    dw F6
    db EIGHTH
    dw $0000
    db EIGHTH

    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH
    dw F6
    db EIGHTH
    dw $0000
    db EIGHTH

    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH
    dw F6
    db EIGHTH
    dw $0000
    db EIGHTH

    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH
    dw F6
    db EIGHTH
    dw $0000
    db EIGHTH

    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH
    dw F6
    db EIGHTH
    dw $0000
    db EIGHTH

    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH
    dw F6
    db EIGHTH
    dw $0000
    db EIGHTH

    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH
    dw F6
    db EIGHTH
    dw $0000
    db EIGHTH

    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH
    dw F6
    db EIGHTH
    dw $0000
    db EIGHTH

    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH
    dw F6
    db EIGHTH
    dw $0000
    db EIGHTH

    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH
    dw F6
    db EIGHTH
    dw $0000
    db EIGHTH

    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH
    dw F6
    db EIGHTH
    dw $0000
    db EIGHTH
; -------------------------
; End
; -------------------------
    dw $0000
    db WHOLE
    dw $0000
    db WHOLE
    dw $0000
    db WHOLE
    dw $0000
    db WHOLE

channel_5_data:
    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH
    dw D6
    db EIGHTH

    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH
    dw D6
    db EIGHTH

    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH
    dw D6
    db EIGHTH

    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH
    dw D6
    db EIGHTH

    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH
    dw C6
    db EIGHTH

    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH
    dw C6
    db EIGHTH

    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH
    dw C6
    db EIGHTH

    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH
    dw C6
    db EIGHTH

    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH
    dw D6
    db EIGHTH

    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH
    dw D6
    db EIGHTH

    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH
    dw D6
    db EIGHTH

    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH
    dw D6
    db EIGHTH

    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH
    dw C6
    db EIGHTH

    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH
    dw C6
    db EIGHTH

    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH
    dw C6
    db EIGHTH

    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH
    dw $0000
    db EIGHTH
    dw C6
    db EIGHTH


; -------------------------
; End
; -------------------------
    dw $0000
    db WHOLE
    dw $0000
    db WHOLE
    dw $0000
    db WHOLE
    dw $0000
    db WHOLE


channel_6_data:
channel_7_data:
channel_8_data: