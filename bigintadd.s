/*--------------------------------------------------------------------*/
/* mywc.s                                                             */
/* Authors: Aidan Walsh, Konstantin Howard                            */
/*--------------------------------------------------------------------*/

.equ MAX_DIGITS, 32768   
.equ FALSE, 0
.equ TRUE, 1

.section .rodata

.section .data

.section .bss

.section .text
    
    /* Return the larger of lLength1 and lLength2. */

    .equ LARGER_STACK_BYTECOUNT, 32
    /* offsets BigInt_larger's local variables and parameters */
    .equ LLARGER, 8
    .equ LLENGTH2, 16
    .equ LLENGTH1, 24

    
    .global BigInt_larger


BigInt_larger:

    /* create space on stack, store return addresses
        and function parameters lLength1, lLength2 */
    sub sp, sp, LARGER_STACK_BYTECOUNT
    str x30, [sp]
    str x0, [sp, LLENGTH1]
    str x1, [sp, LLENGTH2]
    /*if (lLength2 >= lLength1) 
    goto lLength2Greater;  */
    cmp x1, x0
    bge lLength2Greater
    /*lLarger = lLength1; */
    str x0, [sp, LLARGER]
    /*goto end:*/
    b end
/*begin lLength2Greater: */
lLength2Greater:
    /* lLarger = lLength2; */
    str x1, [sp, LLARGER]
end:
    /* return lLarger and epilog */
    ldr x0, [sp, LLARGER]
    ldr x30, [sp]
    add sp, sp, LARGER_STACK_BYTECOUNT
    ret

    .size BigInt_larger, (. - BigInt_larger)

/*-------------------------------------------------------------------*/
/* Assign the sum of oAddend1 and oAddend2 to oSum.  oSum should be
   distinct from oAddend1 and oAddend2.  Return 0 (FALSE) if an
   overflow occurred, and 1 (TRUE) otherwise. */

    .equ ADD_STACK_BYTECOUNT, 64
    /* BigInt_add's offsets local variables and parameters */
    /* local variables first */
    .equ ULCARRY, 8
    .equ ULSUM, 16
    .equ LINDEX, 24
    .equ LSUMLENGTH, 32
    /* parameters second */
    .equ OSUM, 40
    .equ OADD_END2, 48
    .equ OADD_END1, 56
    

    .global BigInt_add


/* BigInt_add function */
BigInt_add:

/* prolog */
    sub sp, sp, ADD_STACK_BYTECOUNT
    str x30, [sp]
    str x0, [sp, OADD_END1]
    str x1, [sp, OADD_END2]
    str x2, [sp, OSUM]


/*lSumLength = BigInt_larger(oAddend1->lLength, oAddend2->lLength); */
    ldr x0, [x0]
    ldr x1, [x1]
    bl BigInt_larger
    str x0, [sp, LSUMLENGTH]
 /*if (oSum->lLength <= lSumLength)
    goto skipMemset */
    ldr x2, [x2]
    cmp x2, x0
    ble skipMemset
    

/* memset(oSum->aulDigits, 0, MAX_DIGITS * sizeof(unsigned long)) */
    mov x2, 8
    mov x3, MAX_DIGITS
    mul x2, x2, x3
    ldr x0, [sp, OSUM]
    add x0, x0, 8
    mov x1, 0
    bl memset


/* begin skipMemset : */
skipMemset:
    /*ulCarry = 0;*/
    mov x0, 0
    str x0, [sp, ULCARRY]
    /* lIndex = 0; */
    mov x0, 0
    str x0, [sp, LINDEX]
/*begin forLoop : */
forLoop: 

    /*    if (lIndex >= lSumLength)
        goto endLoop; */
    ldr x0, [sp, LINDEX]
    ldr x1, [sp, LSUMLENGTH]
    cmp x0, x1
    bge endLoop

   /* ulSum = ulCarry;
    ulCarry = 0; */
    ldr x0, [sp, ULCARRY]
    str x0, [sp, ULSUM]
    mov x0, 0
    str x0, [sp, ULCARRY]
    /* ulSum += oAddend1->aulDigits[lIndex]; */
    ldr x0, [sp, ULSUM]
    ldr x1, [sp, OADD_END1]
    add x1, x1, 8
    ldr x2, [sp, LINDEX]
    ldr x1, [x1, x2, lsl 3]
    add x0, x0, x1
    str x0, [sp, ULSUM]
   /* if (ulSum >= oAddend1->aulDigits[lIndex]) 
        goto noOverflow1; */
    cmp x0, x1
    bhs noOverflow1
    /* ulCarry = 1; */
    mov x3, 1
    str x3, [sp, ULCARRY]
    /* begin noOverflow1: */
noOverflow1:
    /* ulSum += oAddend2->aulDigits[lIndex]; */
    ldr x1, [sp, OADD_END2]
    add x1, x1, 8
    ldr x1, [x1, x2, lsl 3]
    add x0, x0, x1
    str x0, [sp, ULSUM]

    /* if (ulSum >= oAddend2->aulDigits[lIndex])
        goto noOverflow2; */
    cmp x0, x1
    bhs noOverflow2
    /* ulCarry = 1; */
    mov x3, 1
    str x3, [sp, ULCARRY]

    /* begin noOverflow2: */
noOverflow2:

    /*oSum->aulDigits[lIndex] = ulSum; */
    ldr x0, [sp, OSUM]
    add x0, x0, 8
    ldr x1, [sp, LINDEX]
    ldr x2, [sp, ULSUM]
    str x2, [x0, x1, lsl 3]

    /* lIndex++;
    goto forLoop; */
    add x1, x1, 1
    str x1, [sp, LINDEX]
    b forLoop

   /* begin endLoop: */
endLoop:

    /* if (ulCarry != 1)
        goto noCarry; */
    ldr x0, [sp, ULCARRY]
    cmp x0, 1
    bne noCarry
    
    /* if (lSumLength != MAX_DIGITS)
        goto notFailure; */
    ldr x1, [sp, LSUMLENGTH]
    mov x2, MAX_DIGITS
    cmp x1, x2
    bne notFailure

    /* return FALSE; */
    mov x0, FALSE

    /* epilogue */
    ldr x30, [sp]
    add sp, sp, ADD_STACK_BYTECOUNT
    ret

    .size BigInt_add, (. - BigInt_add)
    
    /* begin notFailure:
    oSum->aulDigits[lSumLength] = 1; */
notFailure:
    ldr x0, [sp, OSUM]
    add x0, x0, 8
    ldr x1, [sp, LSUMLENGTH]
    mov x2, 1
    str x2, [x0, x1, lsl 3]

    /* lSumLength++; */
    add x1, x1, 1
    str x1, [sp, LSUMLENGTH]

    /* begin noCarry:
    oSum->lLength = lSumLength; */
noCarry:
    ldr x0, [sp, OSUM]
    ldr x1, [sp, LSUMLENGTH]
    str x1, [x0]

    /* return TRUE; */
    mov x0, TRUE
    /* epilogue */
    ldr x30, [sp]
    add sp, sp, ADD_STACK_BYTECOUNT
    ret

    .size BigInt_add, (. - BigInt_add)



