	AREA code_area, CODE, READONLY
		ENTRY

float_number_series EQU 0x0450
sorted_number_series EQU 0x00018AEC
final_result_series EQU 0x00031190

;========== Do not change this area ===========

initialization
	LDR r0, =0xDEADBEEF				; seed for random number
	LDR r1, =float_number_series	
	LDR r2, =10000  				; The number of element in stored sereis
	LDR r3, =0x0EACBA90				; constant for random number

save_float_series
	CMP r2, #0
	BEQ ms_init
	BL random_float_number
	STR r0, [r1], #4
	SUB r2, r2, #1
	MOV r5, #0
	B save_float_series

random_float_number
	MOV r5, LR
	EOR r0, r0, r3
	EOR r3, r0, r3, ROR #2
	CMP r0, r1
	BLGE shift_left
	BLLT shift_right
	BX r5

shift_left
	LSL r0, r0, #1
	BX LR

shift_right
	LSR r0, r0, #1
	BX LR
	
;============================================

;========== Start your code here ===========
	
ms_init
	LDR r5, =float_number_series
	
	SUB r7, r1, r5		; length of array address
	MOV r7, r7, LSR #2		; length of array
	SUB r14, r7, #1		; length - 1
	
sort_outer_data
	MOV r8, #1		; current size of array
	
sort_outer_loop
	CMP r8, r7		; compare with array size
	BGE result_copy		; if end of array, branch to result
	
sort_inner_data
	MOV r9, #0		; declare left current size
	
sort_inner_loop
	CMP r9, r14		; compare with array size - 1
	BGE sort_outer_count
	
	; declare mid current size
	ADD r10, r8, r9
	SUB r10, r10, #1
	
	MOV r4, r8, LSL #1		; r4 = r8 * 2
	ADD r4, r4, r9		; add r9 to r4
	
	; declare right end size
	CMP r4, r7		; compare r1 with array size
	MOVLT r11, r4		; if size is smaller, right is left + 2*current
	MOVGE r11, r7		; if size is bigger, right is array length
	
	SUB r11, r11, #1
	B merge_start
	
sort_inner_count
	ADD r9, r9, r8, LSL #1
	B sort_inner_loop
	
sort_outer_count
	MOV r8, r8, LSL #1
	B sort_outer_loop
   
	
merge_start	
	LDR r0, =sorted_number_series
	LDR r5, =float_number_series
	MOV r13, r9		; r13 = left size
	ADD r12, r10, #1		; r12 = mid size + 1
	MOV r6, r9		; r6 = left size
	
merge_cond
	CMP r13, r10		; compare r13 with mid size
	BGT merge_end_mid
	
	CMP r12, r11		; compare r12 with right size
	BGT merge_end_right
	
	B merge_data
	
merge_data
	LDR r1, [r5, r13, LSL #2]		; arr[i]
	LDR r2, [r5, r12, LSL #2]		; arr[j]
	
merge_sign
	MOV r3, r1, LSR #31		; get sign bit
	MOV r4, r2, LSR #31		; get sign bit
	
	CMP r3, r4		; compare sign bit
	BEQ same_sign_bit		; if same sign bit branch to same_sign_bit
	BLT sign_mid		; if r1 sign bit is smaller than r2 sign bit
	BGT sign_left		; if r1 sign bit is bigger than r2 sign bit
	
same_sign_bit
	CMP r3, #1		; check sign bit is negative
	BEQ same_sign_bit_neg		; if sign bit is 1, branch to negative
	
	CMP r1, r2		; compare data
	
	STRLE r1, [r0, r6, LSL #2]		; if arr[i] <= arr[j]
	ADDLE r13, r13, #1		; add r13
	
	STRGT r2, [r0, r6, LSL #2]		; if arr[i] > arr[j]
	ADDGT r12, r12, #1		; add r12
	
	ADD r6, r6, #1		; add r6
	B merge_cond		; repeat merge
	
same_sign_bit_neg
	CMP r1, r2		; compare data
	
	STRLT r2, [r0, r6, LSL #2]		; if arr[i] > arr[j]
	ADDLT r12, r12, #1		; add r12
	
	STRGE r1, [r0, r6, LSL #2]		; if arr[i] <= arr[j]
	ADDGE r13, r13, #1		; add r13
	
	ADD r6, r6, #1		; add r6
	B merge_cond		; repeat merge
	
sign_mid
	STR r2, [r0, r6, LSL #2]		; if arr[i] > arr[j]
	ADD r12, r12, #1		; add r12
	
	ADD r6, r6, #1		; add r6
	B merge_cond		; repeat merge
	
sign_left
	STR r1, [r0, r6, LSL #2]		; if arr[i] <= arr[j]
	ADD r13, r13, #1		; add r13
	
	ADD r6, r6, #1		; add r6
	B merge_cond		; repeat merge
	
merge_end_mid
	CMP r12, r11		; compare r12 with right size
	BGT merge_end_right
	
	LDR r2, [r5, r12, LSL #2]
	STR r2, [r0, r6, LSL #2]
	ADD r12, r12, #1
	ADD r6, r6, #1
	B merge_end_mid
	
merge_end_right
	CMP r13, r10		; compare r13 with mid size
	BGT merge_end_mid2
	
	LDR r1, [r5, r13, LSL #2] ; 
	STR r1, [r0, r6, LSL #2]
	ADD r13, r13, #1
	ADD r6, r6, #1
	B merge_end_right
	
merge_end_mid2
	CMP r12, r11		; compare r12 with right size
	BGT merge_end_data
	
	STR r2, [r0, r6, LSL #2]
	ADD r12, r12, #1
	ADD r6, r6, #1
	B merge_end_mid2
	
;  for (int l = left; l <= right; l++) arr[l] = temp[l]
merge_end_data
	LDR r0, =sorted_number_series
	LDR r1, =float_number_series
	MOV r2, r9
	
merge_end_loop
	CMP r2, r11
	BGT sort_inner_count
	
	LDR r3, [r0, r2, LSL #2]
	STR r3, [r1, r2, LSL #2]
	
	ADD r2, r2, #1
	B merge_end_loop

result_copy
   LDR r4 , =float_number_series
   LDR r8 , =final_result_series
   MOV r11, #0
   
copy_loop_s
   LDR r9, [r4], #4
   STR r9, [r8], #4
   ADD r11, r11, #1
   CMP r11, r7
   BEQ exit
   BNE copy_loop_s
   
exit
	MOV pc, #0		; program end
	END

;========== End your code here ===========