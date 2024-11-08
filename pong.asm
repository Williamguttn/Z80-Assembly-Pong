INCLUDE "hardware.inc"

; Define constants
DEF PADDLE_HEIGHT EQU 1 ; Amount of tiles that it will stretch out from the center

; Game state
DEF GAME_STATE EQU $C006

; Bit numbers
DEF GAME_PAUSED EQU 0
DEF OPPONENT_MODE EQU 1 ; Opponent bit active = human
DEF SOUND_PLAYING EQU 2

; Position addresses
DEF PADDLEPOS1 EQU $C000
DEF PADDLEPOS2 EQU $C001

DEF BALL_X EQU $C002
DEF BALL_Y EQU $C003
DEF BALLVEL_X EQU $C004
DEF BALLVEL_Y EQU $C005
DEF BOUNCE_COUNTER EQU $C008

DEF OLD_POS_OFFSET EQU $100

; Points
DEF PLR1_POINTS EQU $C010
DEF PLR2_POINTS EQU $C011
DEF TENS_TILE EQU $C012
DEF ONES_TILE EQU $C013

; Tiles
DEF PADDLE_ONE EQU 0
DEF PADDLE_TWO EQU 1
DEF EMPTY_TILE EQU 2
DEF BALL_TILE EQU 3

; Joypad
DEF A_BTN EQU 0
DEF B_BTN EQU 1
DEF D_UP EQU 2
DEF D_DOWN EQU 3
DEF START_BTN EQU 3
DEF SELECT_BTN EQU 2

; Misc
DEF FRAME_COUNTER EQU $C007
DEF BALL_EVERY_FRAME EQU 5
DEF SOUND_TIMER EQU $C009

SECTION "graphics", ROM0
paddle:
opt g.123
    dw `......33
    dw `......33
    dw `......33
    dw `......33
    dw `......33
    dw `......33
    dw `......33
    dw `......33
.end:

paddle2: ; We could just flip paddle to save some ROM space, but no
opt g.123
    dw `33......
    dw `33......
    dw `33......
    dw `33......
    dw `33......
    dw `33......
    dw `33......
    dw `33......
.end:

ball:
opt g.123
    dw `..3333..
    dw `.3....3.
    dw `3......3
    dw `3......3
    dw `3......3
    dw `3......3
    dw `.3....3.
    dw `..3333..
.end:

number_0:
opt g.123
    dw `..3333..
    dw `.3....3.
    dw `.3...33.
    dw `.3..3.3.
    dw `.3.3..3.
    dw `.33...3.
    dw `.3....3.
    dw `..3333..
.end:
number_1:
opt g.123
    dw `...33...
    dw `..333...
    dw `...33...
    dw `...33...
    dw `...33...
    dw `...33...
    dw `...33...
    dw `..3333..
.end:
number_2:
opt g.123
    dw `..3333..
    dw `.3....3.
    dw `......3.
    dw `.....3..
    dw `....3...
    dw `...3....
    dw `..3.....
    dw `.333333.
.end:
number_3:
opt g.123
    dw `..3333..
    dw `.3....3.
    dw `......3.
    dw `....33..
    dw `....33..
    dw `......3.
    dw `.3....3.
    dw `..3333..
.end:
number_4:
opt g.123
    dw `....33..
    dw `...3.3..
    dw `..3..3..
    dw `.3...3..
    dw `.3...3..
    dw `..33333.
    dw `.....3..
    dw `.....3..
.end:
number_5:
opt g.123
    dw `.333333.
    dw `.3......
    dw `.3......
    dw `.33333..
    dw `......3.
    dw `......3.
    dw `......3.
    dw `.33333..
.end:
number_6:
opt g.123
    dw `..3333..
    dw `.3....3.
    dw `.3......
    dw `.3......
    dw `.33333..
    dw `.3....3.
    dw `.3....3.
    dw `..3333..
.end:
number_7:
opt g.123
    dw `.333333.
    dw `......3.
    dw `......3.
    dw `.....3..
    dw `....3...
    dw `...3....
    dw `..3.....
    dw `.3......
.end:
number_8:
opt g.123
    dw `..3333..
    dw `.3....3.
    dw `.3....3.
    dw `..3333..
    dw `.3....3.
    dw `.3....3.
    dw `.3....3.
    dw `..3333..
.end:
number_9:
opt g.123
    dw `..3333..
    dw `.3....3.
    dw `.3....3.
    dw `..33333.
    dw `......3.
    dw `......3.
    dw `.3....3.
    dw `..3333..
.end:

blankTile:
    DS 16, 0

SECTION "entry", ROM0[$100]
    jp Start

SECTION "main", ROM0[$150]
PreStart:
    ; Game state
    ld a, 1 ; Start paused
    ld [GAME_STATE], a
Start:
    ; prepareData will initialize ball and paddle positions
    call prepareData

    call disableLCD ; We have to disable the LCD before loading stuff into VRAM
    call loadTiles
    call loadPalette
    call clearBackground
    call enableLCD

    ; Everything should now be loaded up, so we can begin the game loop
    jp gameLoop

prepareData:
    ld a, PADDLE_HEIGHT
    inc a
    ld [PADDLEPOS1], a ; This address will be paddle 1 Y position
    ld [PADDLEPOS2], a ; This address will be paddle 2 Y position

    call storeOldPad1Pos
    call storeOldPad2Pos

    ld a, 10
    ld [BALL_X], a ; This address will be ball X position
    ld a, 2
    ld [BALL_Y], a ; This address will be ball Y position

    call storeOldBallPos

    ld a, 1
    ld [BALLVEL_X], a ; Ball X velocity
    ld a, 1
    ld [BALLVEL_Y], a ; Ball Y velocity

    xor a
    ld [BOUNCE_COUNTER], a
    ld [PLR1_POINTS], a
    ld [PLR2_POINTS], a

    ld a, 10
    ld [SOUND_TIMER], a

    ret

disableLCD:
.waitForVBlank:
    ld a, [rLY]
    cp 144
    jr c, .waitForVBlank

    xor a
    ld [rLCDC], a

    ret

loadPalette:
    ld a, %11100100
    ld [rBGP], a

    ret

; HL points to source tile data
; BC points to destination in VRAM
; DE is the size counter
loadTileLoop: ; Takes information from registers and loads it into vram
    ld a, [hl+]
    ld [bc], a
    inc bc
    dec de
    ld a, d
    or e
    jp nz, loadTileLoop

    ret

loadTiles:
    ; Load paddle 1 (Tile #0)
    ld hl, paddle
    ld bc, _VRAM
    ld de, 16 ; Counter
    call loadTileLoop

    ; Load flipped paddle (Tile #1)
    ld hl, paddle2
    ld de, 16
    call loadTileLoop

    ; Load blank tiles (Tile #2)
    ld hl, blankTile
    ld de, 16
    call loadTileLoop

    ; Load ball (Tile #3)
    ld hl, ball
    ld de, 16
    call loadTileLoop

    ld hl, number_0
    ld de, 16
    call loadTileLoop

    ld hl, number_1
    ld de, 16
    call loadTileLoop

    ld hl, number_2
    ld de, 16
    call loadTileLoop

    ld hl, number_3
    ld de, 16
    call loadTileLoop

    ld hl, number_4
    ld de, 16
    call loadTileLoop

    ld hl, number_5
    ld de, 16
    call loadTileLoop

    ld hl, number_6
    ld de, 16
    call loadTileLoop

    ld hl, number_7
    ld de, 16
    call loadTileLoop

    ld hl, number_8
    ld de, 16
    call loadTileLoop

    ld hl, number_9
    ld de, 16
    call loadTileLoop

    ret

clearBackground:
    ld hl, _SCRN0 ; Start of background tile map
    ld bc, 32*32
.clearLoop:
    ld a, 2 ; Empty tile
    ld [hl+], a
    dec bc
    ld a, b
    or c
    jr nz, .clearLoop

    ret

enableLCD:
    ld a, LCDCF_BGON | LCDCF_BG8000 | LCDCF_ON
    ldh [rLCDC], a

    ret

; Main game loop
gameLoop:
; Wait for VBlank to end
.waitVBlankEnd:
    ld a, [rLY]
    cp 144
    jr nc, .waitVBlankEnd

    ; Now, wait for it to start
.waitVBlank:
    ld a, [rLY]
    cp 144
    jr c, .waitVBlank

    call checkInput

    ; Game paused logic
    ld a, [GAME_STATE]
    bit GAME_PAUSED, a
    jr nz, gameLoop ; Skip drawing if paused


    call ballPhysics

    ; Move AI only if ai mode is on
    ld a, [GAME_STATE]
    bit OPPONENT_MODE, a
    call z, moveAI

    call updateSoundTimer
    call updateScreen

    jr gameLoop

moveAI:
    ld a, [GAME_STATE]
    bit 1, a
    jr z, .pass ; AI player

    ret
.pass:
    call storeOldPad2Pos ; Important. Store before updating

    ; AI is in control
    ld a, [BALL_Y]
    ld [PADDLEPOS2], a

    ret

addPointsPlr1:
    ld a, [PLR1_POINTS]
    cp 100
    jr z, .reset

    inc a
    ld [PLR1_POINTS], a
    jr .ret
.reset
    xor a
    ld [PLR1_POINTS], a
.ret
    ret

addPointsPlr2:
    ld a, [PLR2_POINTS]
    cp 100
    jr z, .reset

    inc a
    ld [PLR2_POINTS], a
    jr .ret
.reset:
    xor a
    ld[PLR2_POINTS], a
.ret:
    ret

handleBounceCounter: ; This mostly creates an illusion of variety
    ld a, [BOUNCE_COUNTER]
    cp 3
    call z, .flipYVel

    inc a
    ld [BOUNCE_COUNTER], a

    ret
.flipYVel:
    ld a, [BALLVEL_Y]
    cpl
    inc a
    ld [BALLVEL_Y], a

    xor a
    ld [BOUNCE_COUNTER], a

    ret

ballPhysics:
    call storeOldBallPos

    ld a, [BALLVEL_X]
    ld b, a
    ld a, [BALL_X]

    add a, b
    ld [BALL_X], a

    ; Move Y
    ld a, [BALLVEL_Y]
    ld b, a
    ld a, [BALL_Y]

    add a, b
    ld [BALL_Y], a

checkBallCollisions:
.checkPaddle1:
    ; Check X
    ld a, [BALL_X]
    or a
    jr nz, .checkPaddle2

    ; Check Y
    ld a, [PADDLEPOS1]
    sub PADDLE_HEIGHT
    ld b, a
    
    ld a, [BALL_Y]
    cp b ; If Y less or greater
    jr c, .checkPaddle2

    ; gt
    ld a, [PADDLEPOS1]
    add a, PADDLE_HEIGHT
    add a, PADDLE_HEIGHT
    add a, PADDLE_HEIGHT ; dont know why this is required
    ld b, a

    ld a, [BALL_Y]
    cp b
    jr nc, .checkPaddle2

    ld a, [BALL_X + OLD_POS_OFFSET]
    ld [BALL_X], a
    ld a, [BALL_Y + OLD_POS_OFFSET]
    ld [BALL_Y], a

    call handleBounceCounter

    ld a, [BALLVEL_X]
    cpl
    inc a
    ld [BALLVEL_X], a

    ret

.checkPaddle2:
    ; Check X
    ld a, [BALL_X]
    cp 19
    jr nz, .screenCollision

    ; Check Y
    ld a, [PADDLEPOS2]
    sub PADDLE_HEIGHT
    ld b, a
    
    ld a, [BALL_Y]
    cp b ; If Y less or greater
    jr c, .screenCollision

    ; gt
    ld a, [PADDLEPOS2]
    add a, PADDLE_HEIGHT
    add a, PADDLE_HEIGHT
    add a, PADDLE_HEIGHT ; dont know why this is required
    ld b, a

    ld a, [BALL_Y]
    cp b
    jr nc, .screenCollision

    ld a, [BALL_X + OLD_POS_OFFSET]
    ld [BALL_X], a
    ld a, [BALL_Y + OLD_POS_OFFSET]
    ld [BALL_Y], a

    call handleBounceCounter

    ld a, [BALLVEL_X]
    cpl
    inc a
    ld [BALLVEL_X], a

    ret

.screenCollision:
    ; Check if we're hitting the edge of the screen
    ; Left side
    ld a, [BALL_X]

    cp 255
    jr nz, .skip
    call playClickSound
    ld a, [BALL_X + OLD_POS_OFFSET]
    ld [BALL_X], a

    ld a, [BALLVEL_X]
    cpl
    inc a
    ld [BALLVEL_X], a

    call addPointsPlr2
.skip:

    cp 19
    jr c, checkBallCollisionsY
    jr z, checkBallCollisionsY

    call playClickSound

    ; Greater than
    ld a, [BALL_X + OLD_POS_OFFSET]
    ld [BALL_X], a

    ; Flip velocity
    ld a, [BALLVEL_X]
    cpl
    inc a
    ld [BALLVEL_X], a

    call addPointsPlr1

checkBallCollisionsY:

    ; Bottom
    ld a, [BALL_Y]
    cp 17
    jr c, .ng
    jr z, .ng

    ; Greater than
    ld a, [BALL_Y + OLD_POS_OFFSET]
    ld [BALL_Y], a

    ; Flip velocity
    ld a, [BALLVEL_Y]
    cpl
    inc a
    ld [BALLVEL_Y], a
.ng:
    ret

playClickSound:
    ld a, [GAME_STATE]
    bit SOUND_PLAYING, a
    jr z, .play
    ret
.play:
    set SOUND_PLAYING, a
    ld [GAME_STATE], a

    ; Enable sound system
    ld a, %10000000
    ldh [rAUDENA], a

    ld a, %00000000 ; NR10 (no sweep)
    ldh [rAUD1SWEEP], a

    ld a, %10000001 ; NR11 (50% duty cycle, length=1)
    ldh [rAUD1LEN], a

    ld a, %11110001 ; NR12 (Initial volume 15, sweep down, sweep step 1)
    ldh [rAUD1ENV], a

    ld a, %11000000 ; NR13 (frequency low bits)
    ldh [rAUD1LOW], a

    ld a, %11000111 ; NR14 (trigger, use length, frequency high bits)
    ldh [rAUD1HIGH], a

    ld a, 4
    ld [SOUND_TIMER], a

    ret

updateSoundTimer:
    ld a, [SOUND_TIMER]
    or a
    jr z, .noTimer

    dec a
    ld [SOUND_TIMER], a
    jr nz, .noTimer

    ld a, [GAME_STATE]
    res SOUND_PLAYING, a
    ld [GAME_STATE], a ; Allow sound to play again

.noTimer:
    ret

; Clamp paddles to ensure that they don't travel too far
clampPaddle1:
    ; Clamp first paddle
    ld a, [PADDLEPOS1]

    ; Top of the screen
    cp 255
    jr z, .padPrev

    ; Bottom of the screen
    add a, PADDLE_HEIGHT

    cp 16
    jr c, .ng
    jr z, .ng

    jr .padPrev

    ret
.padPrev:
    ld a, [PADDLEPOS1 + OLD_POS_OFFSET]
    ld [PADDLEPOS1], a
.ng:
    ret

clampPaddle2:
    ; Clamp first paddle
    ld a, [PADDLEPOS2]

    ; Top of the screen
    cp 255
    jr z, .padPrev

    ; Bottom of the screen
    add a, PADDLE_HEIGHT

    cp 16
    jr c, .ng
    jr z, .ng

    jr .padPrev

    ret
.padPrev:
    ld a, [PADDLEPOS2 + OLD_POS_OFFSET]
    ld [PADDLEPOS2], a
.ng:
    ret

storeOldPad1Pos: ; For clearing the paddles
    ld a, [PADDLEPOS1]
    ld [PADDLEPOS1 + OLD_POS_OFFSET], a

    ret

storeOldPad2Pos:
    ld a, [PADDLEPOS2]
    ld [PADDLEPOS2 + OLD_POS_OFFSET], a

    ret

storeOldBallPos:
    ld a, [BALL_X]
    ld [BALL_X + OLD_POS_OFFSET], a

    ld a, [BALL_Y]
    ld [BALL_Y + OLD_POS_OFFSET], a

    ret

; Pressing start button starts the game
startBtn:
    ld a, [GAME_STATE]
    res GAME_PAUSED, a
    ld [GAME_STATE], a

    ret

selectBtn:
    ld a, [GAME_STATE]
    xor %00000010 ; Toggle opponent bit
    set GAME_PAUSED, a
    ld [GAME_STATE], a

    jp Start

    ret

dPadUp:
    call storeOldPad1Pos

    ld a, [PADDLEPOS1]
    dec a
    ld [PADDLEPOS1], a

    call clampPaddle1 ; Limit movement

    ret

dPadDown:
    call storeOldPad1Pos

    ld a, [PADDLEPOS1] ; Paddle 1 y pos
    inc a
    ld [PADDLEPOS1], a

    call clampPaddle1 ; Limit movement

    ret

aBtn:
    ld a, [GAME_STATE]
    bit OPPONENT_MODE, a
    jr z, .skip
    ; Human mode is enabled
    call storeOldPad2Pos

    ld a, [PADDLEPOS2]
    dec a
    ld [PADDLEPOS2], a

    call clampPaddle2
.skip:
    ret

bBtn:
    ld a, [GAME_STATE]
    bit OPPONENT_MODE, a
    jr z, .skip
    ; Human mode is enabled
    call storeOldPad2Pos

    ld a, [PADDLEPOS2]
    inc a
    ld [PADDLEPOS2], a

    call clampPaddle2
.skip:
    ret

; All user input
checkInput:
    ; Read D-pad
    ld a, $20
    ldh [$FF00], a ; Switch to D-pad mode
    ldh a, [$FF00] ; Read D-pad state

    or $F0
    ld b, a ; Store D-pad state in b

    ; Read buttons
    ld a, $10
    ldh [$FF00], a
    ldh a, [$FF00]

    or $F0
    ld c, a ; Store button state

    ; D-pad
    bit D_UP, b
    call z, dPadUp

    bit D_DOWN, b
    call z, dPadDown

    ; Buttons
    bit A_BTN, c
    call z, aBtn

    bit B_BTN, c
    call z, bBtn

    bit START_BTN, c
    call z, startBtn

    bit START_BTN, c
    jr nz, .skip

    bit SELECT_BTN, c
    call z, selectBtn
.skip
    ret

; Result of convertScore:
; Reg A holds the tens digit
; Reg B holds the ones digit
convertScore:
    ; A register will hold the score
    ld b, 10

    ld c, 0
.convertLoop:
    sub b
    jr c, .finishedConvert
    inc c
    jr .convertLoop
.finishedConvert:
    add b
    ld b, a
    ld a, c

    add a, 4; Offset by 4 to match tile indices
    ld [TENS_TILE], a

    ld a, b
    add a, 4
    ld [ONES_TILE], a

    ret

multiply32: ; multiply de by 32
    sla e
    rl d
    sla e
    rl d
    sla e
    rl d
    sla e
    rl d
    sla e
    rl d

    ret

clearPaddles:
    ; Loop counter
    ld b, PADDLE_HEIGHT
    sla b
    inc b ; Double and increase by one
.clearPaddleLoop:
    ld hl, _SCRN0
    
    ; Calculate position
    ld a, [PADDLEPOS1 + OLD_POS_OFFSET]
    sub PADDLE_HEIGHT
    add a, b ; (y - height + counter)

    ld c, a
    ld d, 0
    ld e, c

    call multiply32 ; Mulitply de by 32

    add hl, de

    ; Clear first paddle
    ld a, EMPTY_TILE
    ld [hl], a

    ; Second paddle
    ld hl, _SCRN0
    ld a, [PADDLEPOS2 + OLD_POS_OFFSET]
    sub PADDLE_HEIGHT
    add a, b ; (y - height + counter)

    ld c, a
    ld d, 0
    ld e, c

    call multiply32

    add hl, de

    ; Add x position too
    ld d, 0
    ld e, 19

    add hl, de

    ; Clear second paddle
    ld a, EMPTY_TILE
    ld [hl], a

    dec b
    jr nz, .clearPaddleLoop

    ret

drawPaddles:
    ; Loop counter
    ld b, PADDLE_HEIGHT
    sla b
    inc b ; Double and increase by one
.paddleLoop:
    ld hl, _SCRN0
    
    ; Calculate position
    ld a, [PADDLEPOS1]
    sub PADDLE_HEIGHT
    add a, b ; (y - height + counter)

    ld c, a
    ld d, 0
    ld e, c

    call multiply32

    add hl, de

    ; Draw first paddle
    xor a
    ld [hl], a

    ; Second paddle
    ld hl, _SCRN0
    ld a, [PADDLEPOS2]
    sub PADDLE_HEIGHT
    add a, b ; (y - height + counter)

    ld c, a
    ld d, 0
    ld e, c

    call multiply32

    add hl, de

    ; Add x position too
    ld d, 0
    ld e, 19

    add hl, de

    ld a, PADDLE_TWO
    ld [hl], a

    dec b
    jr nz, .paddleLoop

    ret

clearBall:
    ld hl, _SCRN0

    ld a, [BALL_Y + OLD_POS_OFFSET] ; Y pos
    ld c, a
    ld d, 0
    ld e, c

    call multiply32

    add hl, de

    ld a, [BALL_X + OLD_POS_OFFSET]
    ld d, 0
    ld e, a

    add hl, de ; Add X pos

    ld a, EMPTY_TILE
    ld [hl], a

    ret

drawBall:
    ld hl, _SCRN0

    ld a, [BALL_Y] ; Y pos
    ld c, a
    ld d, 0
    ld e, c

    call multiply32

    add hl, de

    ld a, [BALL_X]
    ld d, 0
    ld e, a

    add hl, de ; Add X pos

    ld a, BALL_TILE
    ld [hl], a

    ret

drawPlr1Points:
    ld a, [PLR1_POINTS]
    call convertScore
   
    ld hl, _SCRN0 + 2
    ld a, [TENS_TILE]
    ld [hl], a

    inc hl
    ld a, [ONES_TILE]
    ld [hl], a

    ret

drawPlr2Points:
    ld a, [PLR2_POINTS]
    call convertScore

    ld hl, _SCRN0 + 16
    ld a, [TENS_TILE]
    ld [hl], a
    
    inc hl
    ld a, [ONES_TILE]
    ld [hl], a

    ret

updateScreen:

    call clearPaddles
    call clearBall

    call drawPaddles
    call drawBall
    call drawPlr1Points
    call drawPlr2Points

    ret