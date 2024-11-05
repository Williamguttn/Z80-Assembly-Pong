; TODO:
; Draw the ball
; Make it so that the game starts paused. The menu button (or something else) starts all movements
; Select button will:
; 1. Freeze the game (Player has to restart again). Also means reset ball pos and paddle pos
; 2. Switch between AI and human opponent

; TODO:
; Add sounds when pressing Start
; Finish ball y collision

INCLUDE "hardware.inc"

; Define constants
DEF PADDLE_HEIGHT EQU 1 ; Amount of tiles that it will stretch out, from the center

; Game state
DEF GAME_STATE EQU $C006

DEF GAME_PAUSED EQU 0
DEF OPPONENT_MODE EQU 1 ; Opponent bit active = human

; Position addresses
DEF PADDLEPOS1 EQU $C000
DEF PADDLEPOS2 EQU $C001

DEF BALL_X EQU $C002
DEF BALL_Y EQU $C003
DEF BALLVEL_X EQU $C004
DEF BALLVEL_Y EQU $C005

DEF OLD_POS_OFFSET EQU $100

; Tiles
DEF PADDLE_ONE EQU 0
DEF PADDLE_TWO EQU 1
DEF EMPTY_TILE EQU 2
DEF BALL_TILE EQU 3

; Joypad
DEF D_UP EQU 2
DEF D_DOWN EQU 3
DEF START_BTN EQU 3

; Misc
DEF FRAME_COUNTER EQU $C007
DEF BALL_EVERY_FRAME EQU 5

SECTION "graphics", ROM0
paddle:
opt g.123
    dw `.......3
    dw `.......3
    dw `.......3
    dw `.......3
    dw `.......3
    dw `.......3
    dw `.......3
    dw `.......3
.end:

paddle2: ; We could just flip paddle to save some ROM space, but no
opt g.123
    dw `3.......
    dw `3.......
    dw `3.......
    dw `3.......
    dw `3.......
    dw `3.......
    dw `3.......
    dw `3.......
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

blankTile:
    DS 16, 0

SECTION "entry", ROM0[$100]
    jp Start

SECTION "main", ROM0[$150]
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

    ; Game state
    ld a, 1 ; Start paused
    ld [GAME_STATE], a

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
; DE is the size coutner
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
    ;ld bc, _VRAM + 16
    ld de, 16
    call loadTileLoop

    ; Load blank tiles (Tile #2)
    ld hl, blankTile ; TODO: Do we need to place _VRAM + 32 in bc?
    ;ld bc, _VRAM + 32
    ld de, 16
    call loadTileLoop

    ; Load ball (Tile #3)
    ld hl, ball
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
    call updateScreen

    jr gameLoop

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
    cp 0
    jr nz, .checkPaddle2

    ; Check Y
    ld a, [PADDLEPOS1]
    ;sub PADDLE_HEIGHT
    ld b, a
    
    ld a, [BALL_Y]
    cp b ; If Y less or greater
    jr c, .checkPaddle2

    ; gt
    ld a, [PADDLEPOS1]
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

    ld a, [BALLVEL_Y]
    cpl
    inc a
    ld [BALLVEL_Y], a

    ld a, [BALLVEL_X]
    cpl
    inc a
    ld [BALLVEL_X], a

    ret

.checkPaddle2:

.screenCollision:

    ; Check if we're hitting the edge of the screen
    ; Left side
    ld a, [BALL_X]

    cp 255
    jr nz, .skip

    ld a, [BALL_X + OLD_POS_OFFSET]
    ld [BALL_X], a

    ld a, [BALLVEL_X]
    cpl
    inc a
    ld [BALLVEL_X], a

.skip:
; CHECK: Do we need this here?; CHECK: Do we need this here?; CHECK: Do we need this here?
; CHECK: Do we need this here?; CHECK: Do we need this here?; CHECK: Do we need this here?
    ;ld a, [BALL_X] 

    cp 19
    jr c, checkBallCollisionsY
    jr z, checkBallCollisionsY

    ld a, 1
    ld [$C010], a

    ; Greater than
    ld a, [BALL_X + OLD_POS_OFFSET]
    ld [BALL_X], a

    ; Flip velocity
    ld a, [BALLVEL_X]
    cpl
    inc a
    ld [BALLVEL_X], a

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
    bit START_BTN, c
    call z, startBtn

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

    ld a, 1
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

updateScreen:

    call clearPaddles ; Clear paddles
    call clearBall

    call drawPaddles
    call drawBall

    ret