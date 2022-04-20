/*--------------------------------------------------------------------*/
/* mywc.s                                                             */
/* Authors: Aidan Walsh, Konstantin Howard                            */
/*--------------------------------------------------------------------*/

/* EOF and newline characters have the following ASCII values */

    .equ EOF, -1
    .equ NEWLINE, 10
    .equ FALSE, 0
    .equ TRUE, 1
    .section .rodata 
finalStr:
        .string "%7ld %7ld %7ld\n"
//---------------------------------------------------------------------
    .section .data
lLinecount:
        .quad 0
lWordCount:
        .quad 0

lCharCount:
        .quad 0

iInWord:
        .word FALSE

//---------------------------------------------------------------------

        .section .bss
iChar:
        .skip 4

//---------------------------------------------------------------------

        .section .text

        /* Write to stdout counts of how many lines, words, and 
        characters are in stdin. A word is a sequence of non-whitespace
        characters. Whitespace is defined by the issspace() function. 
        Return 0. */

        .equ MAIN_STACK_BYTECOUNT, 16

        .global main
main:
    /* prolog - get memory for stack and store return address
    in stack pointer */
    sub sp, sp, MAIN_STACK_BYTECOUNT
    str x30, [sp]
    /* iChar = getChar() */
    /* store the character in x1 which iChar points to */
    bl getChar
    adr x1, iChar
    str w0, [x1]
    
/*begin while */
whileLoop:

        /*  if iChar == EOF, goto loopEnd */
    cmp w1, EOF
    beq loopEnd
    /*      lCharCount++ */
    /* point x0 to lCharCount, then load its value, increment,
    and store in x0 */
    adr x0, lCharCount
    ldr x1, [x0]
    add x1, x1, 1
    str x1, [x0]
    /*   if !isspace(iChar), goto notSpace */
    /* put iChar in argument(x0), then call function, and compare */
    adr x1, iChar
    ldr w0, [x1]
    bl isspace
    cmp w0, FALSE
    beq notSpace
    /* if !iInWord, goto notSpace */
    /* retreive iInWord and compare with false to determine */
    adr x0, iInWord
    ldr w1, [x0]
    cmp w1, FALSE
    beq notSpace
    /* lWordCount++  
    iInWord = FALSE */
    /* retreive address and then load value of lWordCount, 
    then increment and store, and do the same with iInword 
    but use mov to turn to false*/
    adr x0, lWordCount
    ldr x1, [x0]
    add x1, x1, 1
    str x1, [x0]
    adr x0, iInWord
    ldr w1, [x0]
    mov w1, FALSE
    str w1, [x0]
    /*   begin notSpace */
    notSpace:
        /*  if iInWord, goto InWord */
        /* get address, load, and cmp with TRUE */
        adr x0, iInWord
        ldr w1, [x0]
        cmp w1, TRUE
        beq inWord
        /*  iInword = TRUE */
        /* since we already have value in w1, change it to true
        then store */
        mov w1, TRUE
        str w1, [x0]
        /* begin InWord */
    inWord:
         /* if iChar != '\n', goto notNewLine */
         /* get address and load iChar, then compare with value of 
         newline character */
        adr x0, iChar
        ldr w1, [x0]
        cmp w1, NEWLINE
        bne notNewLine
        /* lLineCount++ */
        /* get address, load, then increment, and store */
        adr x0, lLinecount
        ldr x1, [x0]
        add x1, x1, 1
        str x1, [x0]     
    /*  begin notNewLine */
    notNewLine:
        /*  iChar = getChar() */
        /* like we did above, call function, get address of iChar
        then store w0 into what the address of iChar points to */
        bl getChar
        adr x1, iChar
        str w0, [x1]
        /* goto while */
        b whileLoop

    /* begin endOfWhile */
    loopEnd:
        /*if !iInWord, goto end */
        /* get address, load, and then compare with false */
        adr x0, iInWord
        ldr w1, [x0]
        cmp w1, FALSE
        beq end 
         /* lWordCount++ */
        adr x0, lWordCount
        ldr x1, [x0]
        add x1, x1, 1
        str x1, [x0]
    /* begin end */
     end:
        /* printf("%7ld %7ld %7ld\n", lLineCount, lWordCount, lCharCount) */
        /* get address of variables, then load contents into correct registers */
        adr x0, finalStr
        adr x1, lLinecount
        ldr x1, [x1]
        adr x2, lWordCount
        ldr x2, [x2]
        adr x3, lCharCount
        ldr x3, [x3]
        bl printf

        /* return 0 and epilog - load the return address, then
        get rid of stack memory*/
        mov w0, 0
        ldr x30, [sp]
        add sp, sp, MAIN_STACK_BYTECOUNT
        ret 

        .size main, (. - main)
        
                


