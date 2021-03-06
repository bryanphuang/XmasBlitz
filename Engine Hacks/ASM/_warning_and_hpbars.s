.thumb
.org 0 @jumpToHack at 276b4

.equ WarningCache, 0x203acc0 @@first byte is state, then list of units
.equ ChargeFramePointers, FramePointers+4

@@ change 15690 from 12 to 20
@@202bd31 is Subtitle Help (bit 0x80), nop at 35718 to force subtitles.

push {r4-r7}

CheckOptions:
ldr r0,OptionByte
ldrb r0,[r0]
mov r1,#0x80
and r0,r1
cmp r0,#0 @0 means ON
bne NotSelected_

DrawBar:
mov r1, #0x10
ldsb r1,[r4,r1] @get x coord
lsl r1,#4
ldr r2,CameraPos
mov r3,#0xc
ldsh r0,[r2,r3] @camera x?
sub r3,r1,r0
mov r0,#0x11 @get y coord
ldsb r0,[r4,r0]
lsl r0,#4
mov r5,#0xe
ldsh r1,[r2,r5] @camera y?
sub r2,r0,r1
mov r1,r3
add r1,#0x10
mov r0,#0x80
lsl r0,#1
lsl r6,r7,#0x18
cmp r1,r0
bhi NotSelected_
mov r0,r2
add r0,#0x10
cmp r0,#0xb0
bhi NotSelected_
ldr r1,Xvalue
add r0,r3,r1
sub r1,#2
and r0,r1
mov r1,r2
add r1,#0xfb
mov r2,#0xff
and r1,r2
ldr r3, FramePointers

FindHP:
@if hp=max, r5 = 0
@if hp=0, r5 = E
@and everything inbetween
push {r0-r3}
mov r0,#0x12
ldrb r0,[r4,r0] @max
mov r1,#0x13
ldrb r1,[r4,r1] @curr
cmp r0,r1
bgt NotFull
mov r5,#0 @or
pop {r0-r3}
b NoBar
@b HPFound
NotFull:
cmp r1,#0
bne NotEmpty
@ mov r5,#0xE @or b NoBar?
@ b HPFound
pop {r0-r3}
b NoBar

NotEmpty:
sub r2,r0,r1 @r2 = damage taken
mov r1,r0
mov r0,#11  @11 images
mul r0,r2
swi #0x6     @damage*11/maxHP
@ mov r5,#1
@ add r5,r0
mov r5, r0
HPFound:
pop {r0-r3}
lsl r2,r5,#2
add r2,r3
ldr r2,[r2]
mov r3,#0
ldr r4, WRAMDisplay
mov lr,r4
.short 0xf800

NoBar:
pop {r4-r7}

@ push {r4-r7}
@ @@now let's try drawing the charge level
@ ChargeDraw:
@ mov r0, #0x47
@ ldrb r0, [r4,r0] @charge level
@ cmp r0, #0x10
@ blt NoCharge

@ mov r1, #0x10
@ ldsb r1,[r4,r1] @get x coord
@ lsl r1,#4
@ ldr r2,CameraPos
@ mov r3,#0xc
@ ldsh r0,[r2,r3] @camera x?
@ sub r3,r1,r0
@ mov r0,#0x11 @get y coord
@ ldsb r0,[r4,r0]
@ lsl r0,#4
@ mov r5,#0xe
@ ldsh r1,[r2,r5] @camera y?
@ sub r2,r0,r1
@ mov r1,r3
@ add r1,#0x10
@ mov r0,#0x80
@ lsl r0,#1
@ lsl r6,r7,#0x18
@ cmp r1,r0
@ bhi NotSelected_
@ mov r0,r2
@ add r0,#0x10
@ cmp r0,#0xb0
@ bhi NotSelected_
@ mov r1, #0xfe @x-offset
@ add r0,r3,r1
@ sub r1,#2
@ and r0,r1
@ mov r1,r2
@ add r1,#0xfb
@ mov r2,#0xff
@ and r1,r2

@ mov r3, #0x47
@ ldrb r3, [r4,r3] @charge level
@ mov r2, #0xf
@ and r2, r3
@ lsl r2, #2
@ ldr r3, ChargeFramePointers
@ add r2, r3
@ ldr r2, [r2]
@ mov r3, #0
@ ldr r4, WRAMDisplay
@ mov lr,r4
@ .short 0xf800

@ NoCharge:
@ pop {r4-r7}
EffectivenessWarning:

@@cache units at some location. if cache empty, check once and write to cache. empty cache when not selected.

push {r4-r7}
ldr r0, ActiveUnit
ldr r6,[r0] @r6 contains active units data
ldrb r0,[r6,#0xC] @status byte
mov r1,#1
tst r0,r1 @AND r0,r1
bne UnitSelected @the active unit isn't selected

@@if not selected, clear cache
@@then
ldr r0, =WarningCache
mov r1, #0
str r1, [r0]

NotSelected_:
b NotSelected

.ltorg

UnitSelected:
@make sure active unit is ally:
ldrb r0,[r6,#0xB]
mov r1, #0x80
tst r0,r1
bne NoEffectiveness_

ldrb r0,[r4,#0xB] @deployment #
mov r1,#0x80
tst r0,r1
beq NoEffectiveness_ @if zero flag is set, not an enemy unit so skip

@@now check if the unit is in the cache
ldr r1, =WarningCache
ldrb r2, [r1]
cmp r2, #1 @@if flag is 1, set to 2 on second frame around.
bne FlagNot1
  cmp r0, #0x81 @@if flag is 1 on the first unit, this is the second frame
  bne CheckAndCache
    add r2, #1
    strb r2, [r1]

FlagNot1:
cmp r2, #0
bne CheckCached
  add r2, #1 @@if flag is 0 set flag to 1
  strb r2, [r1]
  b CheckAndCache

CheckCached:
@@if in cache
@r0 is deployment no
bl CheckInCache
cmp r0, #0
beq NoEffectiveness

@ @@now to check they're on screen (no need tbh)
@ mov r1, #0x10
@ ldsb r1,[r4,r1] @get x coord
@ lsl r1,#4
@ ldr r2,CameraPos
@ mov r3,#0xc
@ ldsh r0,[r2,r3] @camera x?
@ sub r3,r1,r0
@ mov r0,#0x11 @get y coord
@ ldsb r0,[r4,r0]
@ lsl r0,#4
@ mov r5,#0xe
@ ldsh r1,[r2,r5] @camera y?
@ sub r2,r0,r1
@ mov r1,r3
@ add r1,#0x10
@ mov r0,#0x80
@ lsl r0,#1
@ cmp r1,r0
@ bhi NoEffectiveness
@  now we check again
mov r5, r4
add r5, #0x1e                             @start of inventory
mov r7, #0                                @loop counter
_LoopThroughItems:
ldrh r0,[r5]                              @item #
cmp r0,#0                                 @no more items?
beq NoEffectiveness

  _CheckEquippable:
  mov r0,r4 @current unit data
  ldrh r1,[r5] @current unit's weapon
  ldr r2, CanEquip
  mov lr,r2
  .short 0xf800
  cmp r0,#1
  bne _KeepLooping                         @if can't equip, skip to next item
    ldrh r0,[r5]
    mov r1, r6                            @r0 is item, r1 is target
    ldr r2, CheckEffectiveness
    mov lr,r2
    .short 0xf800
    cmp r0,#1
    beq _IsEffective
      mov r0,r4 @current unit = attacker  @if not effective, check for Slayer
      mov r1,r6 @active unit = defender
      ldr r2, SlayerCheck
      mov lr, r2
      .short 0xf800
      cmp r0,#1
      beq _IsEffective
        ldrb r0,[r5]                      @if neither, check crit rate
        ldr r1, GetItemData
        mov lr,r1
        .short 0xf800
        ldrb r0,[r0,#0x18]
        cmp r0, #24
        ble _KeepLooping                   @0-24 no warning
        cmp r0, #0xFF
        beq _KeepLooping                   @0xFF means cannot crit
      _IsDangerous:
        mov r0,#8
        bl DrawWarningSign
        b NoEffectiveness
      _IsEffective:                        @Draw Red warning
        mov r0,#0
        bl DrawWarningSign
        NoEffectiveness_:
        b NoEffectiveness
_KeepLooping:
cmp r7, #5 @last item?
bge NoEffectiveness
add r7,#1
b _LoopThroughItems

.ltorg

CheckAndCache:
mov r5, r4
add r5, #0x1e                             @start of inventory
mov r7, #0                                @loop counter
LoopThroughItems:
ldrh r0,[r5]                              @item #
cmp r0,#0                                 @no more items?
beq NoEffectiveness

  CheckEquippable:
  mov r0,r4 @current unit data
  ldrh r1,[r5] @current unit's weapon
  ldr r2, CanEquip
  mov lr,r2
  .short 0xf800
  cmp r0,#1
  bne KeepLooping                         @if can't equip, skip to next item
    ldrh r0,[r5]
    mov r1, r6                            @r0 is item, r1 is target
    ldr r2, CheckEffectiveness
    mov lr,r2
    .short 0xf800
    cmp r0,#1
    beq IsEffective
      mov r0,r4 @current unit = attacker  @if not effective, check for Slayer
      mov r1,r6 @active unit = defender
      ldr r2, SlayerCheck
      mov lr, r2
      .short 0xf800
      cmp r0,#1
      beq IsEffective
        ldrb r0,[r5]                      @if neither, check crit rate
        ldr r1, GetItemData
        mov lr,r1
        .short 0xf800
        ldrb r0,[r0,#0x18]
        cmp r0, #24
        ble KeepLooping                   @0-24 no warning
        cmp r0, #0xFF
        beq KeepLooping                   @0xFF means cannot crit
      IsDangerous:
        @ mov r0,#8
        @ bl DrawWarningSign
        ldrb r0, [r4, #0xb]
        bl AddToCache
        b NoEffectiveness
      IsEffective:                        @Draw Red warning
        @ mov r0,#0
        @ bl DrawWarningSign
        ldrb r0, [r4, #0xb]
        bl AddToCache
        b NoEffectiveness
KeepLooping:
cmp r7, #5 @last item?
bge NoEffectiveness
add r7,#1
b LoopThroughItems

NoEffectiveness:
@now we check for Talk icon
@we need r0 to be active unit and r1 to be current unit
@ ldr r0, ActiveUnit
@ ldr r6,[r0] @r6 contains active units data
@ ldr r0,[r6] @character data
@ ldrb r0,[r0,#4] @char num
@ ldr r1,[r4] @current character
@ ldrb r1,[r1,#4]
@ ldr r3, TalkCheck
@ mov lr,r3
@ .short 0xf800
@ cmp r0,#0
@ beq NotSelected
@ mov r0, #0x10
@ bl DrawWarningSign

NotSelected:
pop {r4-r7}

@original routine
mov r0,r4
add r0,#0x30
ldrb r0,[r0]
lsl r0,#0x1c
lsr r0,#0x1c
ldr r1,Return_to
bx r1

AddToCache:
@r0 is number
ldr r1, =WarningCache
NextCacheLoop:
add r1, #1
ldrb r2, [r1] @first unit
cmp r2, #0
bne NextCacheLoop
  strb r0, [r1]
  mov r0, #0
  strb r0, [r1, #1]
  b ATC_End
b NextCacheLoop
ATC_End:
bx r14
.ltorg

CheckInCache:
@r0 is number to check
ldr r1, =WarningCache
NextCacheCheck:
add r1, #1
ldrb r2, [r1] @first unit
cmp r2, #0
beq CIC_False @reached end, return false
cmp r2, r0
bne NextCacheCheck
  b CIC_True @found match, return true
b NextCacheCheck
CIC_True:
mov r0, #1
b CIC_End
CIC_False:
mov r0, #0
CIC_End:
bx r14

DrawWarningSign:
push {r4-r7,r14}
mov r5,r0       @r5 is either 0 or 8 depending on effective/killer (or 0x10 for talk)
mov r1, #0x10
ldsb r1,[r4,r1] @get x coord
lsl r1,#4
ldr r2,CameraPos
mov r3,#0xc
ldsh r0,[r2,r3] @camera x?
sub r3,r1,r0
mov r0,#0x11 @get y coord
ldsb r0,[r4,r0]
lsl r0,#4
mov r1,#0xe
ldsh r1,[r2,r1] @camera y?
sub r2,r0,r1
mov r1,r3
add r1,#0x10
mov r0,#0x80
lsl r0,#1
lsl r6,r7,#0x18
cmp r1,r0
bhi NoSign
mov r0,r2
add r0,#0x10
cmp r0,#0xb0
bhi NoSign
ldr r1,Xvalue
add r0,r3,r1
add r0,#0xB @tweak for X coord
sub r1,#2
and r0,r1
mov r1,r2
add r1,#0xee  @y coord
mov r2,#0xff
and r1,r2
mov r2, #(WS_FrameData - LoadFrameData - 4)
LoadFrameData:
add r2, pc
add r2, r5    @loads up either effective or killer depending on r5
mov r3,#0
ldr r4, WRAMDisplay
mov lr,r4
.short 0xf800

NoSign:
pop {r4-r7}
pop {r0}
bx r0
.ltorg
.align
OptionByte:
.long 0x202bd31
CameraPos:
.long 0x202bcb0
Xvalue:
.long 0x201
WRAMDisplay:
.long 0x8002bb8
Return_to:
.long 0x80276be+1
ActiveUnit:
.long 0x3004e50
SlayerCheck:
.long 0x8016c88
CheckEffectiveness:
.long 0x8016bec
CanEquip:
.long 0x8016574
GetItemData:
.long 0x80177B0
TalkCheck:
.long 0x8083f68
WS_FrameData: @should be the OAM data
.long 0x000f0001 @8x8 sprite
.long 0x087601ff @the tile is 0x76
Killer_FrameData:
.long 0x000f0001
.long 0x087701ff @tile #0x77
Talk_FrameData:
.long 0x400f0001 @16x8 sprite
.long 0x087001ee @tile #0x70
FramePointers:
@.long 0x8e903a0 @need to replace
@POIN ChargeFramePointers