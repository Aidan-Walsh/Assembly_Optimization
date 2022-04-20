/*--------------------------------------------------------------------*/
/* bigintaddoptopt.s                                                  */
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
    
    /* offsets */
    .equ FIRSTSTORE, 8
    .equ SECONDSTORE, 16
    .equ THIRDSTORE, 24
    .equ FOURTHSTORE, 32
    .equ FIFTHSTORE, 40
    .equ SIXTHSTORE, 48
    .equ SEVSTORE, 56

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
    

    .global BigInt_add


/* BigInt_add function */
BigInt_add:

    /* prolog */
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
    ldr x0, [x0]
    ldr x1, [x1]

    /* find larger of lengths and store it in lSumLength */
    /* if oAddend1->lLength >= oAddend2->lLength */
    cmp x0, x1
    bge oneLonger

    /* lSumLength = oAddend2->lLength */
    mov LSUMLENGTH, x1

    /* skip the next part that would be the else */
    b twoLonger
    
    /* begin oneLonger */
oneLonger:
    /* LSUMLENGTH = oAddend1->lLength */
    mov LSUMLENGTH, x0

twoLonger:  
    /*if (oSum->lLength <= lSumLength)
    goto skipMemset */
    ldr x2, [x2]
    cmp x2, x0
    ble skipMemset
    

/* memset(oSum->aulDigits, 0, MAX_DIGITS * sizeof(unsigned long)) */
    mov x2, SLONG
    mov x3, MAX_DIGITS
    mul x2, x2, x3
    mov x0, OSUM
    add x0, x0, 8
    mov x1, 0
    bl memset


/* begin skipMemset : */
skipMemset:
    /*ulCarry = 0;*/
    mov ULCARRY, 0
    /* lIndex = 0; */
    mov LINDEX, 0

     /*    if (lIndex >= lSumLength)
        goto endLoop; */
    cmp LINDEX, LSUMLENGTH
    bge endLoop

/*begin forLoop : */
forLoop: 

   

   /* ulSum = ulCarry;
    ulCarry = 0; */
    mov ULSUM, ULCARRY
    mov ULCARRY, 0
    /* ulSum += oAddend1->aulDigits[lIndex]; */
    add x1, OADD_END1, 8
    ldr x1, [x1, LINDEX, lsl 3]
    add ULSUM, ULSUM, x1
   /* if (ulSum >= oAddend1->aulDigits[lIndex]) 
        goto noOverflow1; */
    cmp ULSUM, x1
    bhs noOverflow1
    /* ulCarry = 1; */
    mov ULCARRY, 1
    /* begin noOverflow1: */
noOverflow1:
    /* ulSum += oAddend2->aulDigits[lIndex]; */
    add x1, OADD_END2, 8
    ldr x1, [x1, LINDEX, lsl 3]
    add ULSUM, ULSUM, x1

    /* if (ulSum >= oAddend2->aulDigits[lIndex])
        goto noOverflow2; */
    cmp ULSUM, x1
    bhs noOverflow2
    /* ulCarry = 1; */
    mov ULCARRY, 1

    /* begin noOverflow2: */
noOverflow2:

    /*oSum->aulDigits[lIndex] = ulSum; */
    add x0, OSUM, 8
    str ULSUM, [x0, LINDEX, lsl 3]

    /* lIndex++;
    goto forLoop; */
    add LINDEX, LINDEX, 1

    cmp LINDEX, LSUMLENGTH
    blt forLoop

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
    
    /* begin notFailure:
    oSum->aulDigits[lSumLength] = 1; */
notFailure:
    add x0, OSUM, 8
    mov x2, 1
    str x2, [x0, LSUMLENGTH, lsl 3]

    /* lSumLength++; */
    add LSUMLENGTH, LSUMLENGTH, 1

    /* begin noCarry:
    oSum->lLength = lSumLength; */
noCarry:
    str LSUMLENGTH, [OSUM]

    /* return TRUE; */
    mov x0, TRUE

epilog:
    /* epilogue */
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



