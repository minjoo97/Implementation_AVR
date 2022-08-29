; 16-bit registers
#define XL r26
#define XH r27
#define YL r28
#define YH r29
#define ZL r30
#define ZH r31

; Argument registers for function calls
#define ARG1 r24
#define ARG2 r22
#define ARG3 r20

; Only encrypt and decrypt are callable externally
.global encrypt_opt_opt

.text

/**
 * push_registers macro:
 *
 * Pushes a given range of registers in ascending order
 * To be called like: push_registers 0,15
 */
.macro push_registers from:req, to:req
  push \from
  .if \to-\from
    push_registers "(\from+1)",\to
  .endif
.endm

/**
 * pop_registers macro:
 *
 * Pops a given range of registers in descending order
 * To be called like: pop_registers 0,15
 */

.macro pop_registers from:req, to:req
  pop \to
  .if \to-\from
    pop_registers \from,"(\to-1)"
  .endif
.endm

/**
 * subBytesShiftRows:
 *
 * r0-r15: state matrix
 * r18: temporary register
 * Z: sbox
 */

.macro subBytesShiftRows
  ; Do only byte substitution to index 0,4,8,12
  mov ZL, r0
  lpm r0, Z
  mov ZL, r4
  lpm r4, Z
  mov ZL, r8
  lpm r8, Z
  mov ZL, r12
  lpm r12, Z

  ; Row 2 shifted by 1
  mov r18, r1
  mov ZL, r5
  lpm r1, Z
  mov ZL, r9
  lpm r5, Z
  mov ZL, r13
  lpm r9, Z
  mov ZL, r18
  lpm r13, Z

  ; Row 3 shifted by 2
  mov r18, r10
  mov ZL, r2
  lpm r10, Z
  mov ZL, r18
  lpm r2, Z
  mov r18, r14
  mov ZL, r6
  lpm r14, Z
  mov ZL, r18
  lpm r6, Z

  ; Row 4 shifted by 3
  mov r18, r3
  mov ZL, r15
  lpm r3, Z
  mov ZL, r11
  lpm r15, Z
  mov ZL, r7
  lpm r11, Z
  mov ZL, r18
  lpm r7, Z

.endm 


/**
 * mixColumns:
 *
 * r0-r15: state matrix
 * r16: irreducible polynomial
 * r18-r21, r24: temporary registers
 * Z: sbox
 */
.macro mixColumns
  ; First row
  mov r18, r0 ; t0 = state[0] ^ state[1];
  eor r18, r1
  mov r19, r1 ; t1 = state[1] ^ state[2];
  eor r19, r2
  mov r20, r2 ; t2 = state[2] ^ state[3];
  eor r20, r3
  mov r21, r3 ; t3 = state[3] ^ state[0];
  eor r21, r0
  mov r24, r0 ; i = state[0];

  mov r0, r18 ; state[0] = mul2[t0] ^ t1 ^ state[3];
  add r0, r0
  brcc .+2
  eor r0, r16
  eor r0, r19
  eor r0, r3

  mov r3, r21 ; state[3] = mul2[t3] ^ t0 ^ state[2];
  add r3, r3
  brcc .+2
  eor r3, r16
  eor r3, r18
  eor r3, r2

  mov r2, r20 ; state[2] = mul2[t2] ^ t3 ^ state[1];
  add r2, r2
  brcc .+2
  eor r2, r16
  eor r2, r21
  eor r2, r1

  mov r1, r19 ; state[1] = mul2[t1] ^ t2 ^ i;
  add r1, r1
  brcc .+2
  eor r1, r16
  eor r1, r20
  eor r1, r24

  ; Second row
  mov r18, r4 ; t0 = state[4] ^ state[5];
  eor r18, r5
  mov r19, r5 ; t1 = state[5] ^ state[6];
  eor r19, r6
  mov r20, r6 ; t2 = state[6] ^ state[7];
  eor r20, r7
  mov r21, r7 ; t3 = state[7] ^ state[4];
  eor r21, r4
  mov r24, r4 ; i = state[4];

  mov r4, r18 ; state[4] = mul2[t0] ^ t1 ^ state[7];
  add r4, r4
  brcc .+2
  eor r4, r16
  eor r4, r19
  eor r4, r7

  mov r7, r21 ; state[7] = mul2[t3] ^ t0 ^ state[6];
  add r7, r7
  brcc .+2
  eor r7, r16
  eor r7, r18
  eor r7, r6

  mov r6, r20 ; state[6] = mul2[t2] ^ t3 ^ state[5];
  add r6, r6
  brcc .+2
  eor r6, r16
  eor r6, r21
  eor r6, r5

  mov r5, r19 ; state[5] = mul2[t1] ^ t2 ^ i;
  add r5, r5
  brcc .+2
  eor r5, r16
  eor r5, r20
  eor r5, r24

  ; Third row
  mov r18, r8 ; t0 = state[8] ^ state[9];
  eor r18, r9
  mov r19, r9 ; t1 = state[9] ^ state[10];
  eor r19, r10
  mov r20, r10 ; t2 = state[10] ^ state[11];
  eor r20, r11
  mov r21, r11 ; t3 = state[11] ^ state[8];
  eor r21, r8
  mov r24, r8 ; i = state[8];

  mov r8, r18 ; state[8] = mul2[t0] ^ t1 ^ state[11];
  add r8, r8
  brcc .+2
  eor r8, r16
  eor r8, r19
  eor r8, r11

  mov r11, r21 ; state[11] = mul2[t3] ^ t0 ^ state[10];
  add r11, r11
  brcc .+2
  eor r11, r16
  eor r11, r18
  eor r11, r10

  mov r10, r20 ; state[10] = mul2[t2] ^ t3 ^ state[9];
  add r10, r10
  brcc .+2
  eor r10, r16
  eor r10, r21
  eor r10, r9

  mov r9, r19 ; state[9] = mul2[t1] ^ t2 ^ i;
  add r9, r9
  brcc .+2
  eor r9, r16
  eor r9, r20
  eor r9, r24

  ; Fourth row
  mov r18, r12 ; t0 = state[12] ^ state[13];
  eor r18, r13
  mov r19, r13 ; t1 = state[13] ^ state[14];
  eor r19, r14
  mov r20, r14 ; t2 = state[14] ^ state[15];
  eor r20, r15
  mov r21, r15 ; t3 = state[15] ^ state[12];
  eor r21, r12
  mov r24, r12 ; i = state[12];

  mov r12, r18 ; state[12] = mul2[t0] ^ t1 ^ state[15];
  add r12, r12
  brcc .+2
  eor r12, r16
  eor r12, r19
  eor r12, r15

  mov r15, r21 ; state[15] = mul2[t3] ^ t0 ^ state[14];
  add r15, r15
  brcc .+2
  eor r15, r16
  eor r15, r18
  eor r15, r14

  mov r14, r20 ; state[14] = mul2[t2] ^ t3 ^ state[13];
  add r14, r14
  brcc .+2
  eor r14, r16
  eor r14, r21
  eor r14, r13

  mov r13, r19 ; state[13] = mul2[t1] ^ t2 ^ i;
  add r13, r13
  brcc .+2
  eor r13, r16
  eor r13, r20
  eor r13, r24

.endm

.macro Addroundkey
		
	LD R18, Y+
	EOR R0, R18

	LD R18, Y+
  	EOR R4, R18
	
	LD R18, Y+
	EOR R8, R18

	LD R18, Y+
	EOR R12, R18

.endm



/**
 * encrypt
 *
 * r0-r15: state matrix
 * r16: irreducible polynomial
 * r18-r20: temporary variables
 * Z: plaintext
 * Y: key / output
 *
 * Note:
 * r18-r27, r30-31 are call-used registers
 * r20 provides ARG3 and can be used regularily after being copied to YL
 * According to the avr-libc FAQ they need not to be pushed/popped
 */

encrypt_opt_opt:
  ; Push r0-r16 for the state matrix
  push_registers 0,16

  ; Push the remaining call-saved registers
  push YL
  push YH

  ; Save the argument pointers to Z (plaintext) and X (key)
//  movw XL, ARG1
//  movw ZL, ARG3

	MOVW R26, R24
	MOVW R28, R20

  ; Load the plaintext given by argument to register 0-15
  .irp param,r0,r1,r2,r3,r4,r5,r6,r7,r8,r9,r10,r11,r12,r13,r14,r15
    ld \param, X+
  .endr

  ; The irreducible polynomial is held consistently in r16, the sbox in Z
  ldi r16, 0x1b
  ldi ZH, hi8(sbox)

  /*ing~*/



  //1
  subBytesShiftRows
  mixColumns
  Addroundkey
  subBytesShiftRows
  mixColumns

  //2
  subBytesShiftRows
  mixColumns
  Addroundkey
  subBytesShiftRows
  mixColumns


  //3
  subBytesShiftRows
  mixColumns
  Addroundkey
  subBytesShiftRows
  mixColumns

  //4
  subBytesShiftRows
  mixColumns
  Addroundkey
  subBytesShiftRows
  mixColumns

  //5
  subBytesShiftRows
  mixColumns
  Addroundkey
  subBytesShiftRows
  mixColumns

  //6
  subBytesShiftRows
  mixColumns
  Addroundkey
  subBytesShiftRows

  ; Save the final state from the registers to Y (ARG2)
  movw YL, ARG2

  .irp param,r0,r1,r2,r3,r4,r5,r6,r7,r8,r9,r10,r11,r12,r13,r14,r15
    st Y+, \param
  .endr

  ; Pop the call-saved registers
  pop YH
  pop YL

  ; Pop the state matrix registers
  pop_registers 0,16

  ret


; The following tables reside in flash memory
; as they are belonging to the .text section
.balign 256

sbox:
.byte 0x63, 0x7C, 0x77, 0x7B, 0xF2, 0x6B, 0x6F, 0xC5, 0x30, 0x01, 0x67, 0x2B, 0xFE, 0xD7, 0xAB, 0x76
.byte 0xCA, 0x82, 0xC9, 0x7D, 0xFA, 0x59, 0x47, 0xF0, 0xAD, 0xD4, 0xA2, 0xAF, 0x9C, 0xA4, 0x72, 0xC0
.byte 0xB7, 0xFD, 0x93, 0x26, 0x36, 0x3F, 0xF7, 0xCC, 0x34, 0xA5, 0xE5, 0xF1, 0x71, 0xD8, 0x31, 0x15
.byte 0x04, 0xC7, 0x23, 0xC3, 0x18, 0x96, 0x05, 0x9A, 0x07, 0x12, 0x80, 0xE2, 0xEB, 0x27, 0xB2, 0x75
.byte 0x09, 0x83, 0x2C, 0x1A, 0x1B, 0x6E, 0x5A, 0xA0, 0x52, 0x3B, 0xD6, 0xB3, 0x29, 0xE3, 0x2F, 0x84
.byte 0x53, 0xD1, 0x00, 0xED, 0x20, 0xFC, 0xB1, 0x5B, 0x6A, 0xCB, 0xBE, 0x39, 0x4A, 0x4C, 0x58, 0xCF
.byte 0xD0, 0xEF, 0xAA, 0xFB, 0x43, 0x4D, 0x33, 0x85, 0x45, 0xF9, 0x02, 0x7F, 0x50, 0x3C, 0x9F, 0xA8
.byte 0x51, 0xA3, 0x40, 0x8F, 0x92, 0x9D, 0x38, 0xF5, 0xBC, 0xB6, 0xDA, 0x21, 0x10, 0xFF, 0xF3, 0xD2
.byte 0xCD, 0x0C, 0x13, 0xEC, 0x5F, 0x97, 0x44, 0x17, 0xC4, 0xA7, 0x7E, 0x3D, 0x64, 0x5D, 0x19, 0x73
.byte 0x60, 0x81, 0x4F, 0xDC, 0x22, 0x2A, 0x90, 0x88, 0x46, 0xEE, 0xB8, 0x14, 0xDE, 0x5E, 0x0B, 0xDB
.byte 0xE0, 0x32, 0x3A, 0x0A, 0x49, 0x06, 0x24, 0x5C, 0xC2, 0xD3, 0xAC, 0x62, 0x91, 0x95, 0xE4, 0x79
.byte 0xE7, 0xC8, 0x37, 0x6D, 0x8D, 0xD5, 0x4E, 0xA9, 0x6C, 0x56, 0xF4, 0xEA, 0x65, 0x7A, 0xAE, 0x08
.byte 0xBA, 0x78, 0x25, 0x2E, 0x1C, 0xA6, 0xB4, 0xC6, 0xE8, 0xDD, 0x74, 0x1F, 0x4B, 0xBD, 0x8B, 0x8A
.byte 0x70, 0x3E, 0xB5, 0x66, 0x48, 0x03, 0xF6, 0x0E, 0x61, 0x35, 0x57, 0xB9, 0x86, 0xC1, 0x1D, 0x9E
.byte 0xE1, 0xF8, 0x98, 0x11, 0x69, 0xD9, 0x8E, 0x94, 0x9B, 0x1E, 0x87, 0xE9, 0xCE, 0x55, 0x28, 0xDF
.byte 0x8C, 0xA1, 0x89, 0x0D, 0xBF, 0xE6, 0x42, 0x68, 0x41, 0x99, 0x2D, 0x0F, 0xB0, 0x54, 0xBB, 0x16


; 16 bytes are allocated uninitialized for the key
.section .bss

key:
.fill 16, 1, 0


/*      
	 0   3    2      5       4      7
0    00  03   02    05     04     07
4    01  04   03    06     05     08
8    02  05   04    07     06     09
12   03  06   05    08     07     0A
*/


