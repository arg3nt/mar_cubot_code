kbd_left EQU 37
kbd_up EQU 38
kbd_right EQU 39
kbd_down EQU 40

kbd_left_alt EQU 65
kbd_right_alt EQU 68
kbd_up_alt EQU 87
kbd_down_alt EQU 83

kbd_device EQU 0x0004
legs_device EQU 0x0001

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

; function mapKeyToMvmt: Maps a keypress to a direction of movement
; word mapKeyToMvmt(word keyCode)
; Input: A: keyboard code
; Modifies: A
mapKeyToMvmt:
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
  ; move a null value to A
  MOV A, 0x0004
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

  

end:
  brk

.text
	; Get latest keypress
	CALL getKeyPress
    ; quit if there are no keypresses in the buffer
    CMP A, 0
    JZ end
    
    ; map keypress to a movement
    CALL mapKeyToMvmt

    ; make sure a valid key was pressed
    CMP A, 0x0003
    JG end
    
    ; trigger leg movement in direction
    CALL moveLegs
    
	CALL end
