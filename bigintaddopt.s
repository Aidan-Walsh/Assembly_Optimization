/*--------------------------------------------------------------------*/
/* bigintaddopt.s                                                     */
/* Authors: Aidan Walsh, Konstantin Howard                            */
/*--------------------------------------------------------------------*/

.equ SLONG, 8
.equ MAX_DIGITS, 32768   
.equ FALSE, 0
.equ TRUE, 1

.section .rodata

.section .data

.section .bss

.section .text
    
    /* Return the larger of lLength1 and lLength2. */

    .equ LARGER_STACK_BYTECOUNT, 32

    /* offsets */
    .equ FIRSTSTORE, 8
    .equ SECONDSTORE, 16
    .equ THIRDSTORE, 24
    .equ FOURTHSTORE, 32
    .equ FIFTHSTORE, 40
    .equ SIXTHSTORE, 48
    .equ SEVSTORE, 56
    /* offsets BigInt_larger's local variables and parameters */
    LLARGER .req x19
    LLENGTH2 .req x20
    LLENGTH1 .req x21

    
    .global BigInt_larger


BigInt_larger:

    /* create space on stack, and save previous values in registers
    onto stack */
    sub sp, sp, LARGER_STACK_BYTECOUNT
    str x30, [sp]
    str x19, [sp, FIRSTSTORE]
    str x20, [sp, SECONDSTORE]
    str x21, [sp, THIRDSTORE]
    /* store parameters in registers */
    mov LLENGTH1, x0
    mov LLENGTH2, x1
    /*if (lLength2 >= lLength1) 
    goto lLength2Greater;  */
    cmp LLENGTH2, LLENGTH1
    bge lLength2Greater
    /*lLarger = lLength1; */
    mov LLARGER, LLENGTH1
    /*goto end:*/
    b end
/*begin lLength2Greater: */
lLength2Greater:
    /* lLarger = lLength2; */
    mov LLARGER, LLENGTH2
end:
    /* return lLarger and epilog - restore register values */
    mov x0, LLARGER
    ldr x30, [sp]
    ldr x19, [sp, FIRSTSTORE]
    ldr x20, [sp, SECONDSTORE]
    ldr x21, [sp, THIRDSTORE]
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
    ULCARRY .req x19
    ULSUM .req x20
    LINDEX .req x21
    LSUMLENGTH .req x22
    /* parameters second */
    OSUM .req x23
    OADD_END2 .req x24
    OADD_END1 .req x25
    /* structure offsets */
    .equ LLENGTH, 0
    .equ AULDIGITS, 8
    

    .global BigInt_add


/* BigInt_add function */
BigInt_add:

    /* prolog - allocate stack memory, save previous values
    in registers */
    sub sp, sp, ADD_STACK_BYTECOUNT
    str x30, [sp]
    str x19, [sp, FIRSTSTORE]
    str x20, [sp, SECONDSTORE]
    str x21, [sp, THIRDSTORE]
    str x22, [sp, FOURTHSTORE]
    str x23, [sp, FIFTHSTORE]
    str x24, [sp, SIXTHSTORE]
    str x25, [sp, SEVSTORE]

    /* store parameters in registers */
    mov OADD_END1, x0
    mov OADD_END2, x1
    mov OSUM, x2

    /*lSumLength = BigInt_larger(oAddend1->lLength, oAddend2->lLength); */
    /* dereference registers to get lengths, and load those values */
    ldr x0, [x0, LLENGTH]
    ldr x1, [x1, LLENGTH]
    bl BigInt_larger
    mov LSUMLENGTH, x0
    /*if (oSum->lLength <= lSumLength)
    goto skipMemset */
    /* dereference and load again */
    ldr x2, [x2, LLENGTH]
    cmp x2, x0
    ble skipMemset
    

    /* memset(oSum->aulDigits, 0, MAX_DIGITS * sizeof(unsigned long)) 
     just move values into registers and we want memory location of 
    aulDigits so we just add offset to its memory location that we 
    place in x0 */
    mov x2, SLONG
    mov x3, MAX_DIGITS
    mul x2, x2, x3
    mov x0, OSUM
    add x0, x0, AULDIGITS
    mov x1, 0
    bl memset


/* begin skipMemset : */
skipMemset:
    /*ulCarry = 0;*/
    mov ULCARRY, 0
    /* lIndex = 0; */
    mov LINDEX, 0
/*begin forLoop : */
forLoop: 

    /*    if (lIndex >= lSumLength)
        goto endLoop; */
    cmp LINDEX, LSUMLENGTH
    bge endLoop

   /* ulSum = ulCarry;
    ulCarry = 0; */
    mov ULSUM, ULCARRY
    mov ULCARRY, 0
    /* ulSum += oAddend1->aulDigits[lIndex]; */
    /*OADD_END1 has memory address so we just add the required offset
    and load with a shift to dereference */
    add x1, OADD_END1, AULDIGITS
    ldr x1, [x1, LINDEX, lsl 3]
    add ULSUM, ULSUM, x1
   /* if (ulSum >= oAddend1->aulDigits[lIndex]) 
        goto noOverflow1; */
    /* x1 already has what we need */
    cmp ULSUM, x1
    bhs noOverflow1
    /* ulCarry = 1; */
    mov ULCARRY, 1
/* begin noOverflow1: */
noOverflow1:
    /* ulSum += oAddend2->aulDigits[lIndex]; */
    /* do what we did before by adding, shifting, and loading */
    add x1, OADD_END2, AULDIGITS
    ldr x1, [x1, LINDEX, lsl 3]
    add ULSUM, ULSUM, x1

    /* if (ulSum >= oAddend2->aulDigits[lIndex])
        goto noOverflow2; */
    /* again, x1 already has what we need, so just compare */
    cmp ULSUM, x1
    bhs noOverflow2
    /* ulCarry = 1; */
    mov ULCARRY, 1

    /* begin noOverflow2: */
noOverflow2:

    /*oSum->aulDigits[lIndex] = ulSum; */
    add x0, OSUM, AULDIGITS
    str ULSUM, [x0, LINDEX, lsl 3]

    /* lIndex++;
    goto forLoop; */
    add LINDEX, LINDEX, 1
    b forLoop

   /* begin endLoop: */
endLoop:

    /* if (ulCarry != 1)
        goto noCarry; */
    cmp ULCARRY, 1
    bne noCarry
    
    /* if (lSumLength != MAX_DIGITS)
        goto notFailure; */
    mov x2, MAX_DIGITS
    cmp LSUMLENGTH, x2
    bne notFailure

    /* return FALSE; */
    mov x0, FALSE
    /* go to epilog */
    b epilog
    
/* begin notFailure: */
notFailure:
    /* oSum->aulDigits[lSumLength] = 1; */
    /* method where we add to get memory location, then 
    shift and load to dereference and assign value */
    add x0, OSUM, AULDIGITS
    mov x2, 1
    str x2, [x0, LSUMLENGTH, lsl 3]

    /* lSumLength++; */
    add LSUMLENGTH, LSUMLENGTH, 1

/* begin noCarry: */
noCarry:
    /* oSum->lLength = lSumLength; */
    /* dereferencing osum + llength mem location will
    let us manipulate value */
    str LSUMLENGTH, [OSUM, LLENGTH]

    /* return TRUE; */
    mov x0, TRUE

epilog:
    /* epilogue - restore register values */
    ldr x30, [sp]
    ldr x19, [sp, FIRSTSTORE]
    ldr x20, [sp, SECONDSTORE]
    ldr x21, [sp, THIRDSTORE]
    ldr x22, [sp, FOURTHSTORE]
    ldr x23, [sp, FIFTHSTORE]
    ldr x24, [sp, SIXTHSTORE]
    ldr x25, [sp, SEVSTORE]
    add sp, sp, ADD_STACK_BYTECOUNT
    ret

    .size BigInt_add, (. - BigInt_add)



