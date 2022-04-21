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
    
    /* structure offsets */
    .equ LLENGTH, 0
    .equ AULDIGITS, 8

    /* offsets */
    .equ FIRSTSTORE, 8
    .equ SECONDSTORE, 16
    .equ THIRDSTORE, 24
    .equ FOURTHSTORE, 32
    .equ FIFTHSTORE, 40
    .equ SIXTHSTORE, 48

/*-------------------------------------------------------------------*/
/* Assign the sum of oAddend1 and oAddend2 to oSum.  oSum should be
   distinct from oAddend1 and oAddend2.  Return 0 (FALSE) if an
   overflow occurred, and 1 (TRUE) otherwise. */

    .equ ADD_STACK_BYTECOUNT, 48
    /* BigInt_add's offsets local variables and parameters */
    /* local variables first */
    ULSUM .req x20
    LINDEX .req x21
    LSUMLENGTH .req x22
    /* parameters second */
    OSUM .req x23
    OADD_END2 .req x24
    OADD_END1 .req x25
    

    .global BigInt_add


/* BigInt_add function, now 
containing the BigInt_larger function */
BigInt_add:

    /* prolog - save register values to stack*/
    sub sp, sp, ADD_STACK_BYTECOUNT
    str x30, [sp]
    str x20, [sp, FIRSTSTORE]
    str x21, [sp, SECONDSTORE]
    str x22, [sp, THIRDSTORE]
    str x23, [sp, FOURTHSTORE]
    str x24, [sp, FIFTHSTORE]
    str x25, [sp, SIXTHSTORE]

    /* store parameters in registers */
    mov OADD_END1, x0
    mov OADD_END2, x1
    mov OSUM, x2

    /* store parameter lengths in registers */
    ldr x0, [x0, LLENGTH]
    ldr x1, [x1, LLENGTH]

    /* find larger of lengths store it in lSumLength */
    /* if oAddend1->lLength >= oAddend2->lLength */
    cmp x0, x1
    bge oneLonger

    /* lSumLength = oAddend2->lLength */
    mov LSUMLENGTH, x1

    /* skip the part that would be 
    if length of one were longer */
    b twoLonger

    /* begin oneLonger */
oneLonger:
    /* LSUMLENGTH = oAddend1->lLength */
    mov LSUMLENGTH, x0

twoLonger:  
    /*if (oSum->lLength <= lSumLength)
    goto skipMemset */
    ldr x2, [x2, LLENGTH]
    cmp x2, x0
    ble skipMemset
    

/* memset(oSum->aulDigits, 0, MAX_DIGITS * sizeof(unsigned long)) */
/* place values in correct argument registers */
    mov x2, SLONG
    mov x3, MAX_DIGITS
    mul x2, x2, x3
    mov x0, OSUM
    add x0, x0, AULDIGITS
    mov x1, 0
    bl memset


/* begin skipMemset : */
skipMemset:

    /* set carry condition to 0 by doing 
    addition with no overflow */
    mov x0, 0
    adcs x0, x0, x0

    /* lIndex = 0; */
    mov LINDEX, 0
    mov x3, 0
    /* begin guarded for loop with condition */
    /*    if (lIndex >= lSumLength)
        goto endLoop; */
    cmp LINDEX, LSUMLENGTH
    bge endLoop

/*begin forLoop : */
forLoop: 
    /* if register x3 has a 1, then set C to 1 
    via a comparison that we know will do so */
      
noCC:
        cmp x3, 1
        bne isZero
        cmp xzr, xzr
        
isZero:  
     /* ulSum = oAddend1->aulDigits[lIndex] + oAddend2->aulDigits[lIndex]; 
    and adjust carry condition */
    /* add respective digits given by LINDEX
    where we adjust carry condition */

    add x1, OADD_END1, AULDIGITS
    ldr x1, [x1, LINDEX, lsl 3]
   
    add x2, OADD_END2, AULDIGITS
    ldr x2, [x2, LINDEX, lsl 3]    
    
    adcs ULSUM, x2, x1
    
    /* oSum->aulDigits[lIndex] = ulSum; 
    set that digit of oSum to the calculated uSum */
    
    add x0, OSUM, AULDIGITS
    str ULSUM, [x0, LINDEX, lsl 3]

    /* save the carry value C in x3 */
    adcs x3, xzr, xzr    
    
    /* lIndex++;
    make sure LINDEX < LSUMLENGTH to iterate back through loop
    (other part of guarded loop)
    goto forLoop; */
    
    add LINDEX, LINDEX, 1
    cmp LINDEX, LSUMLENGTH
    blt forLoop

   /* begin endLoop: */
endLoop:

    /* test to see if we carried on last addition */
    /* if (x3 != 1)
        goto noCarry; */
    cmp x3, 1
    bne noCarry
    
    /* if (lSumLength != MAX_DIGITS)
        goto notFailure; 
    if we carried on the last available digit,
    there was an overflow failure */
    mov x2, MAX_DIGITS
    cmp LSUMLENGTH, x2
    bne notFailure

    /* return FALSE; */
    mov x0, FALSE
    /* go to epilog */
    b epilog
    
/* begin notFailure: */
notFailure:

    /* oSum->aulDigits[lSumLength] = 1;
    access oSum's array of digits 
    and add carried 1 */
    add x0, OSUM, AULDIGITS
    mov x2, 1
    str x2, [x0, LSUMLENGTH, lsl 3]

    /* lSumLength++; */
    add LSUMLENGTH, LSUMLENGTH, 1

/* begin noCarry: */
noCarry:
    /* oSum->lLength = lSumLength; */
    str LSUMLENGTH, [OSUM, LLENGTH]

    /* return TRUE; */
    mov x0, TRUE

epilog:
    /* epilog - restore previous register values 
    and get rid of stack memory */
    ldr x30, [sp]
    ldr x20, [sp, FIRSTSTORE]
    ldr x21, [sp, SECONDSTORE]
    ldr x22, [sp, THIRDSTORE]
    ldr x23, [sp, FOURTHSTORE]
    ldr x24, [sp, FIFTHSTORE]
    ldr x25, [sp, SIXTHSTORE]
    add sp, sp, ADD_STACK_BYTECOUNT
    ret

    .size BigInt_add, (. - BigInt_add)



