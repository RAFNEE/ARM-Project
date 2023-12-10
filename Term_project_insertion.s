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
	BEQ is_init
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

; label to initialize
is_init
	LDR r5, =float_number_series		; load first float number
	LDR r6, =sorted_number_series		; load sorted number series
	
	MOV r7, #0		; initialize count

; label to store sorted array
outer_loop
	CMP r5, r1                   ; compare float data with end of float data
	BEQ result_init
	
    LDR r4, [r5], #4             ; Load data from float number series
	ADD r7, r7, #1		; add count
	
	CMP r2, #1					; count is 1
	BNE sign_data	            ; branch to check sign bit in sort data
	STREQ r4, [r6], #4			; store data in sorted array
	BEQ outer_loop		; recursive
    
    B outer_loop
	
; label to load sorted array
sign_data
	LDR r9, =sorted_number_series		; load first sorted array
	
; label to compare sign bit
sign_loop
	LDR r8, [r9], #4			; load data from sorted array
	
	MOV r10, r4, LSR #31 		; get sign bit
	MOV r11, r8, LSR #31		; get sign bit
	
	CMP r6, r9					; compare to check data count
	SUBLT r9, r9, #4		; subtract address of r9
	BLT inner_loop			; if count same
	
	CMP r10, r11				; check sign bit
	BEQ case_same_sign_bit		; if sign is same with loaded data, branch to compare data
	BLT sign_loop		; if sign bit is smaller than loaded data, branch to compare next data
	SUBGT r9, r9, #4		; subtract address of r9
	BGT inner_loop		; if sign is bigger than loaded data, branch to sort
	
; label of case of same sign bit of positive
case_same_sign_bit
	CMP r10, #1		; if sign bit is 1
	BEQ case_same_sign_bit_neg		; branch negative case
	
	CMP r4, r8		; compare data
	BGE sign_loop		; branch to sort next data
	SUBLT r9, r9, #4		; subtract address of r9
	BLT inner_loop		; branch to sort current data
	
; label of case of same sign bit of negative
case_same_sign_bit_neg
	CMP r4, r8		; compare data
	BLE sign_loop		; branch to sort next data
	SUBGT r9, r9, #4		; subtract address of r9
	BGT inner_loop		; branch to sort current data
	
; label to sort data
inner_loop
	LDR r12, [r9]		; load r9 in r12
	STR r4, [r9], #4		; store r4 in r9
	MOV r4, r12
	
	CMP r9, r6		; compare to check data count
	BLE inner_loop		; repeat while sorted
	ADDGT r6, #4		; add address of r6
	BGT outer_loop		; branch sorted
	
; label to sorted array in final result
result_init
	LDR r1, =sorted_number_series		; sorted array
	LDR r2, =final_result_series		; final array
	MOV r3, #0		; data count
	
; lable to store result
result_loop
	LDR r4, [r1], #4		; load sorted data
    STR r4, [r2], #4		; store sorted data in final result array
    CMP r3, r7		; compare count
    BLT result_loop		; repeat while end
	BEQ exit		; program end
	
; label to exit
exit
	MOV pc, #0	; program end
	END
	
;========== End your code here ===========