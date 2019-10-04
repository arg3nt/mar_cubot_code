;; TODO
; Read multiple instructions simultaneously and save results to a set of queues
; Movement cancel command
; Biomass Harvesting
; Laser attack!


;; Keyboard Commands

;;;;;
; Movement
;;;;;
; Up Arrow /w       : move up
; Left Arrow / a    : move left
; Down Arrow / s    : move down
; Right Arrow / d   : move right

;;;;;
; Hologram
;;;;;
; b                 : toggle battery level

;;;;;
; Inventory (planned)
;;;;;
; z                 ; digitize and destroy item if any exist

;;;;;
; Laser (planned)
;;;;;
; x                 ; attack with laser


;; Mapping keys to internal codes
; The goal here is to create an abstraction layer between a keypress and the
; command it's tied to. We have a function which maps the key to a command code,
; then we map the command code to a function which translates it into action.

;; Internal Command Codes
; 0                 : Move up
; 1                 : Move right
; 2                 : Move down
; 3                 : Move left
; 4                 : Toggle battery level


;; Reserved Memory
; 0x0A00 - 0x0A03: Battery Toggle State
battery_switch EQU 0x0A00



;; Keyboard keys
kbd_left EQU 37         ; left arrow
kbd_up EQU 38           ; up arrow
kbd_right EQU 39        ; right arrow
kbd_down EQU 40         ; down arrow

kbd_left_alt EQU 65     ; a
kbd_right_alt EQU 68    ; d
kbd_up_alt EQU 87       ; w
kbd_down_alt EQU 83     ; s

kbd_toggle_batt EQU 66  ; b


;; Hardware Device IDs
legs_device EQU 0x0001
kbd_device EQU 0x0004
holo_device EQU 0x0009
battery_device EQU 0x000A



; function getKeyPress: retrieves a keypress from the keyboard
; usage:
; word getKeyPress()
; Modifies: A
getKeyPress:
    PUSH B
    MOV A, 1  ; get the latest keypress
    HWI kbd_device
    MOV A, B
    POP B
    RET

; function mapKeyToMvmt: Maps a keypress to a command
; 0-4: Move up, right, down, left
; 5: 
; word mapKeyToMvmt(word keyCode)
; Input: A: keyboard code
; Modifies: A
mapKeyToCmd:
    CMP A, kbd_left
    JZ move_left
    CMP A, kbd_left_alt
    JZ move_left
    CMP A, kbd_right
    JZ move_right
    CMP A, kbd_right_alt
    JZ move_right
    CMP A, kbd_up
    JZ move_up
    CMP A, kbd_up_alt
    JZ move_up
    CMP A, kbd_down
    JZ move_down
    CMP A, kbd_down_alt
    JZ move_down
    CMP A, kbd_toggle_batt
    JZ toggle_batt
    ; move a null value to A
    MOV A, 0x00A0
    RET

move_left:
    MOV A, 0x0003
    RET
move_right:
    MOV A, 0x0001
    RET
move_up:
    MOV A, 0x0000
    RET
move_down:
    MOV A, 0x0002
    RET
toggle_batt:
    MOV A, 0x0004
    RET

; function moveLegs
; void moveLegs(word direction)
; input: A: direction of mvmt
; modifies: none
moveLegs:
    PUSH B
    MOV B, A
    ; set instruction to LEGS_SET_DIRECTION_AND_WALK
    MOV A, 2
    HWI legs_device
    POP B
    RET

; function getBatteryLevel: retrieves battery level and puts into A
; word getBatteryLevel()
; modifies A
getBatteryLevel:
    PUSH B
    MOV A, 1
    HWI battery_device
    MOV A, B
  
    POP B
    RET

; function printBatteryLevel: prints a decimal on the hologram projector
; void printDecimal(word level)
; input: A: decimal value
printDecimal:
    PUSH A
    PUSH B
  
    MOV B, A
    MOV A, 3  ; HOLO_DISPLAY_DECIMAL
    HWI holo_device

    POP B
    POP A
    RET

; function showBatteryIfActive: displays battery if toggle is on in memory
; void showBatteryIfActive()
showBatteryIfActive:
    CMP [battery_switch], 0
    JZ return
    CALL showBattery
    RET
    

; function showBattery: gets battery level and prints on hologram projector
; void showBattery()
showBattery:
    PUSH A
    CALL getBatteryLevel
    CALL printDecimal
    POP A
    RET


; function toggleBatteryDisplay: toggles battery switch in memory
; void toggleBatteryDisplay()
toggleBatteryDisplay:
    ; if battery is disabled, enable it
    CMP [battery_switch], 0
    JZ enableBatteryDisplay
    ; if battery is enabled, disable it
    MOV [battery_switch], 0
    RET

enableBatteryDisplay:
    MOV [battery_switch], 1
    RET


; quit execution
end:
    brk

; helper to jump straight to return from a conditional
return:
    RET

; Main function
.text
	; Get latest keypress
	CALL getKeyPress
    ; quit if there are no keypresses in the buffer
    CMP A, 0
    JZ noCmds
    
    ; map keypress to a command
    CALL mapKeyToCmd

    ; check whether command was for movement 
    CMP A, 0x0003
    JG legsNotMoving
    CALL moveLegs

legsNotMoving:
    ; check whether command was to toggle battery
    CMP A, 0X0004
    JNZ noToggleBattery
    CALL toggleBatteryDisplay

noCmds:
noToggleBattery:
    CALL showBatteryIfActive
    JMP end
