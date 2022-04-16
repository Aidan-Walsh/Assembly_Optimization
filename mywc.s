/*--------------------------------------------------------------------*/
/* mywc.s                                                             */
/* Authors: Aidan Walsh, Konstantin Howard                            */
/*--------------------------------------------------------------------*/

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
    /* prolog */
    sub sp, sp, MAIN_STACK_BYTECOUNT
    str x30, [sp]
    /* don't necessarily need to store EOF in register and can make naming better */
    /* iChar = getChar() */
    bl getChar
    adr x1, iChar
    str w0, [x1]
    
/*begin while */
whileLoop:
      /*  if iChar == EOF, goto loopEnd */
    
    cmp w1, EOF
    beq loopEnd
    /*      lCharCount++ */
    adr x0, lCharCount
    ldr x1, [x0]
    add x1, x1, 1
    str x1, [x0]
    /*   if !isspace(iChar), goto notSpace */
    /* put iChar in argument, then call function, and compare */
    adr x1, iChar
    ldr w0, [x1]
    bl isspace
    cmp w0, FALSE
    beq notSpace
    /*       if !iInWord, goto notSpace */
    adr x0, iInWord
    ldr w1, [x0]
    cmp w1, FALSE
    beq notSpace
     /* lWordCount++
        iInWord = FALSE */
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
        adr x0, iInWord
        ldr w1, [x0]
        cmp w1, TRUE
        beq inWord
        /*  iInword = TRUE */
        mov w1, TRUE
        str w1, [x0]
        /* begin InWord */
    inWord:
         /* if iChar != '\n', goto notNewLine */
        adr x0, iChar
        ldr w1, [x0]
        cmp w1, NEWLINE
        bne notNewLine
        /* lLineCount++ */
        adr x0, lLinecount
        ldr x1, [x0]
        add x1, x1, 1
        str x1, [x0]     
    /*  begin notNewLine */
    notNewLine:
        /*  iChar = getChar() */
        bl getChar
        adr x1, iChar
        str w0, [x1]
        /* goto while */
        b whileLoop

    /* begin endOfWhile */
    loopEnd:
        /*if !iInWord, goto end */
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
        adr x0, finalStr
        adr x1, lLinecount
        ldr x1, [x1]
        adr x2, lWordCount
        ldr x2, [x2]
        adr x3, lCharCount
        ldr x3, [x3]
        bl printf

        /* return 0 and epilog */
        mov w0, 0
        ldr x30, [sp]
        add sp, sp, MAIN_STACK_BYTECOUNT
        ret 

        .size main, (. - main)
        
                


