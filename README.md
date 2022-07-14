# Assembly Conversion

None of the c code is mine, but instead we converted the c found in bigintadd.c and mywc.c into assembly, in an attempt to beat the compiler in its conversion to assembly (another partnered task with @KonstantinHoward)! Our conversions our found in bigintadd.s, then an optimized version in bigintaddopt.s, and optimized even more in bigintaddoptopt.s, and mywc.s. The bigintadd program is just an addition to the implementation found in bigint.c (it is the adding method) that we wanted to optimize. This is because this method, when adding large numbers, is called many many times, thus it takes most of the run time! If we could optimize the assembly, then we would be significantly speeding up the runtime of many clients using the bigint library. 

The mywc program provides a line count, word count, and character count of stdin and writes it to stdout in that respective order. 

# bigintadd.s
In converting to assembly, we used caller saved registers and so utilized the stack significantly. 

# bigintaddopt.s
The first optimization consisted of switching to callee saved registers, which essentially meant we saved data to the stack and only used registers for everything. 

# bigintaddoptopt.s
This optimization involved a guarded loop, inlining the BigInt_larger function, and the utilization of the adcs instruction which sets flags with a computation so it helped make the assembly more efficient. 

# End product
The final optimized version, using a computer stopwatch, was able to beat the compiler's optimized version! The compiler's version was compiled with "gcc fib.c bigint.c bigintadd.c -D NDEBUG -O -o fib" which let the compiler optimize the code and assembly. When given the stdin of 250000 which told the Fibonacci program to calculate the 250000th value in the Fibonacci sequence, it took 3.01 seconds. When ran with "gcc fib.c bigint.c bigintaddoptopt.s -D NDEBUG -O -o fib" and given the same stdin, it took 2.77 seconds!


# To use mywc.s
1. Download "mywc.s"
2. Sadly, it's difficult compiling the assembly file unless you are running a Linux OS or VM, so the following is for Linux
3. Compile: 
    - "gcc mywc.s -o mywc"
4. To send the program a text file "text.txt" that it will analyze and save the output to "output.txt": 
    - "./mywc < text.txt > output.txt
5. If you run into a permission issue, then run this command and try step 4 again:
    - "chmod +x mywc"
    - Note that if you are running Linux, then you may have to add "sudo" to the beginning of the command to gain super-user privileges.
