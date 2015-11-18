; Ex6.asm  ---- Example program 6 for the DRAGON12-Plus2 Rev. A board
;               (c)2012, EVBplus.com
;     Author: Wayne Chu
;     Date: 4/12/12
;
;     The new Dragon12-Plus2 board added a 3.3V power supply, a Micro SD memory
;     card holder, Bluetooth, Xbee and Nordic nRF24L01+ wireless interfaces.
;     It also provides Arduino Shield Compatible headers and an automatic power
;     switching circuit for selecting power from USB port or external AC
;     adapter.
;
;     Function: This example program is not intended for teaching a user how to
;               write HCS12 code. In fact it was ported from our 68HC11
;               test program, so most instructions were written in 68HC11 code.
;
;               Plays a song via timer5 (PT5)


DB2        equ        4
DB3        equ        8
DB4        equ        $10
DB5        equ        $20
DB6        equ        $40

OL5        equ        DB2
OM5        equ        DB3

TB1MS:     equ        24000        ; 1ms time base of 24000 instruction cycles
;                                ; 24,000 x 1/24MHz = 1ms at 24 MHz bus speed


REGBLK:    equ        $0
#include   reg9s12.h        ; include register equates

F3500HZ:   equ        3429

           org        $1000
spk_tone:        rmb        2
sound_dur:       rmb        1
xsound_save:     rmb        2
sound_repeat:    rmb        1
xsound_beg:      rmb        2
sound_start:     rmb        1
rest_note:       rmb        1
count_5ms:       rmb        1


; for 24 MHz bus speed
; 1200000 / 261.63 Hz = note count

c3        equ        45866                ; 261.63 Hz at 24 MHz
c3s        equ        43293                ; 277.18 Hz at 24 MHz
d3        equ        40864                ; 293.66 Hz at 24 MHz
d3s        equ        38569                ; 311.13 Hz at 24 MHz
e3        equ        36404                ; 329.63 Hz at 24 MHz
f3        equ        34361                ; 349.23 Hz at 24 MHz
f3s        equ        32433                ; 369.99 Hz at 24 MHz
g3        equ        30613                ; 391.99 Hz at 24 MHz
g3s        equ        28894                ; 415.31 Hz at 24 MHz
a3        equ        27273                ; 440.00 Hz at 24 MHz
a3s        equ        25742                ; 466.16 Hz at 24 MHz
b3        equ        24297                ; 493.88 Hz at 24 MHz

c4        equ        22934                ; 523.25 Hz at 24 MHz
c4s        equ        21646                ; 554.37 Hz at 24 MHz
d4        equ        20431                ; 587.33 Hz at 24 MHz
d4s        equ        19285                ; 622.25 Hz at 24 MHz
e4        equ        18202                ; 659.26 Hz at 24 MHz
f4        equ        17181                ; 698.46 Hz at 24 MHz
f4s        equ        16216                ; 739.99 Hz at 24 MHz
g4        equ        15306                ; 783.99 Hz at 24 MHz
g4s        equ        14447                ; 830.61 Hz at 24 MHz
a4        equ        13636                ; 880.00 Hz at 24 MHz
a4s        equ        12871                ; 932.32 Hz at 24 MHz
b4        equ        12149                ; 987.77 Hz at 24 MHz

c5        equ        11467                ; 1046.50 Hz at 24 MHz
c5s        equ        10823                ; 1108.73 Hz at 24 MHz
d5        equ        10216                ; 1174.66 Hz at 24 MHz
d5s        equ        9642                ; 1244.51 Hz at 24 MHz
e5        equ        9101                ; 1318.51 Hz at 24 MHz
f5        equ        8590                ; 1396.91 Hz at 24 MHz
f5s        equ        8108                ; 1479.98 Hz at 24 MHz
g5        equ        7653                ; 1567.98 Hz at 24 MHz
g5s        equ        7225                ; 1661.22 Hz at 24 MHz
a5        equ        6818                ; 1760.00 Hz at 24 MHz
a5s        equ        6435                ; 1864.66 Hz at 24 MHz
b5        equ        6074                ; 1975.53 Hz at 24 MHz

c6        equ        5733                ; 2093.00 Hz at 24 MHz
c6s        equ        5412                ; 2217.46 Hz at 24 MHz
d6        equ        5109                ; 2349.32 Hz at 24 MHz
d6s        equ        4821                ; 2489.02 Hz at 24 MHz
e6        equ        4551                ; 2637.02 Hz at 24 MHz
f6        equ        4295                ; 2793.83 Hz at 24 MHz
f6s        equ        4054                ; 2959.96 Hz at 24 MHz
g6        equ        3827                ; 3135.97 Hz at 24 MHz
g6s        equ        3612                ; 3322.44 Hz at 24 MHz
a6        equ        3409                ; 3520.00 Hz at 24 MHz
a6s        equ        3218                ; 3729.31 Hz at 24 MHz
b6        equ        3037                ; 3951.07 Hz at 24 MHz

c7        equ        2867                ; 4186.01 Hz at 24 MHz
c7s        equ        2706                ; 4434.92 Hz at 24 MHz
d7        equ        2554                ; 4698.64 Hz at 24 MHz
d7s        equ        2411                ; 4978.03 Hz at 24 MHz
e7        equ        2275                ; 5274.04 Hz at 24 MHz
f7        equ        2148                ; 5587.66 Hz at 24 MHz
f7s        equ        2027                ; 5919.92 Hz at 24 MHz
g7        equ        1913                ; 6271.93 Hz at 24 MHz
g7s        equ        1806                ; 6644.88 Hz at 24 MHz
a7        equ        1705                ; 7040.00 Hz at 24 MHz
a7s        equ        1609                ; 7458.63 Hz at 24 MHz
b7        equ        1519                ; 7902.13 Hz at 24 MHz
c8        equ        1                ; for rest note

note_c        equ        0
note_cs       equ        1
note_d        equ        2
note_ds       equ        3
note_e        equ        4
note_f        equ        5
note_fs       equ        6
note_g        equ        7
note_gs       equ        8
note_a        equ        9
note_as       equ        10
note_b        equ        11

; dur18= 1/8 note,  dur14= 1/4 note,  $fe= rest_note, $ff = end of song
        
dur18         equ        50
dur14         equ        100
        
STACK:        equ        $2000

        org        $2000
        jmp        start

NOTE_TABLE:
        fdb        c3,c3s,d3,d3s,e3,f3,f3s,g3,g3s,a3,a3s,b3
        fdb        0,0,0,0                ; dummy byte
        fdb        c4,c4s,d4,d4s,e4,f4,f4s,g4,g4s,a4,a4s,b4
        fdb        0,0,0,0                ; dummy byte
        fdb        c5,c5s,d5,d5s,e5,f5,f5s,g5,g5s,a5,a5s,b5
        fdb        0,0,0,0                ; dummy byte
        fdb        c6,c6s,d6,d6s,e6,f6,f6s,g6,g6s,a6,a6s,b6
        fdb        0,0,0,0                ; dummy byte
        fdb        c7,c7s,d7,d7s,e7,f7,f7s,g7,g7s,a7,a7s,b7
        fdb        0,0,0,0                ; dummy byte
        fdb        c8


start:
        lds        #STACK
        ldx        #timer6
        stx        $3E62                ; initialize int vetctor
        LDX        #timer5_spk
        stx        $3E64

        ldx        #F3500HZ               ; 3.5kHz
        stx        spk_tone

        ldx        #REGBLK
        ldaa       #$80
        staa       tscr,x                ; enable timer
        ldaa       #DB5+DB6
        staa       tios,x                ; select t6 as an output compare
        staa       tmsk1,x
        clr        count_5ms

        cli
        jsr        spk_on
        jsr        start_sound                ; start sound
stp:    jmp        stp

spk_on:        
        pshx
        ldx        #REGBLK
        bclr       tctl1,x OM5
        bset       tctl1,x OL5                ; toggle speaker
        pulx
        rts
spk_off:
        pshx
        ldx        #REGBLK
        bset       tctl1,x OM5
        bclr       tctl1,x OL5                ; turn off speaker
        pulx
        rts

timer6:
        inc        count_5ms
        ldaa       count_5ms
        cmpa       #5
        bne        tmr3
        clr        count_5ms
;
; processing every 5ms
        ldaa       sound_start
        beq        tmr3
        ldaa       sound_dur                ; duration
        deca
        staa       sound_dur
        bne        tmr3
        ldx        xsound_save
repeat: ldab       0,x
        cmpb       #255
        beq        sound_end
        ldaa       1,x
        cmpa       #255
        beq        sound_end
        staa       sound_dur
        inx
        inx
        stx        xsound_save
        cmpb       #$fe
        bne        not_rest
        ldaa       #1
        staa       rest_note
        jsr        spk_off
        jmp        tmr3
not_rest:
        clr        rest_note
        jsr        spk_on
        ldx        #NOTE_TABLE
        aslb
        abx
        ldx        0,x
        stx        spk_tone
        jmp        tmr3        
sound_end:
        ldaa       sound_repeat
        beq        no_rep
        ldx        xsound_beg
        jmp        repeat

no_rep: ldx        #F3500HZ        ; 3.5kHz
        stx        spk_tone
        jsr        spk_off
        clr        sound_start

tmr3:   ldx        #REGBLK               ; in interrupt service routine
        ldd        #TB1MS                ; 1 ms time base
        addd       tc6,x
        std        tc6,x
        ldaa       #DB6
        staa       tflg1,x               ; clear flag
        rti

timer5_spk:
        ldx        #REGBLK                ; in interrupt service routine
        ldd        spk_tone
        addd       tc5,x
        std        tc5,x
        ldaa       #DB5
        staa       tflg1,x                ; clear flag
        rti

start_sound:
        ldx        #SONG
        stx        xsound_beg
        ldaa       #1
        staa       sound_repeat
        ldab       0,x
        ldaa       1,x
        staa       sound_dur
        inx
        inx
        stx        xsound_save

        ldx        #NOTE_TABLE
        aslb
        abx
        ldx        0,x
        stx        spk_tone
        ldaa       #1
        staa       sound_start
        rts

SONG:   fcb        $20+note_e,dur18
        fcb        $20+note_ds,dur18
        fcb        $20+note_e,dur18
        fcb        $20+note_ds,dur18
        fcb        $20+note_e,dur18
        fcb        $10+note_b,dur18
        fcb        $20+note_d,dur18
        fcb        $20+note_c,dur18
        fcb        $10+note_a,dur14
;        fcb        $fe,dur18
;        fcb        255,255

        fcb        $00+note_e,dur18
        fcb        $00+note_a,dur18
        fcb        $10+note_c,dur18
        fcb        $10+note_e,dur18
        fcb        $10+note_a,dur18
        fcb        $10+note_b,dur14
        fcb        $00+note_gs,dur18
        fcb        $10+note_d,dur18
        fcb        $10+note_e,dur18
        fcb        $10+note_gs,dur18
        fcb        $10+note_b,dur18
        fcb        $20+note_c,dur14

        fcb        $00+note_e,dur18
        fcb        $00+note_a,dur18
        fcb        $10+note_e,dur18
        fcb        $fe,dur14
        fcb        255,255


        org        $3e62
        fdb        timer6
        org        $3e64
        fdb        timer5_spk
        end