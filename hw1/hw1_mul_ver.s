.data
    # will not overflow
    cmp_data_1: .dword 0x0000000000000000, 0x0000000000000000
    # will not overflow
    cmp_data_2: .dword 0x0000000000000001, 0x0000000000000010
    # will not overflow
    cmp_data_3: .dword 0x0000000000000002, 0x4000000000000000
    # will overflow
    cmp_data_4: .dword 0x0000000000000003, 0x7FFFFFFFFFFFFFFF
    

.text
# assume little endian
main:
    addi sp, sp, -16
    
    # push four pointers of test data onto the stack
    la t0, cmp_data_1
    sw t0, 0(sp)
    la t0, cmp_data_2
    sw t0, 4(sp)
    la t0, cmp_data_3
    sw t0, 8(sp)
    la t0, cmp_data_4
    sw t0, 12(sp)
    
    # for testing
    #li a0, 0
    #li a1, 0x00
    #jal ra clz
    #jal ra print_dec
    #j exit
 
    addi s0, zero, 4    # s0 is the goal iteration count
    addi s1, zero, 0    # s1 is the counter
    addi s2, sp, 0      # s2 now points to cmp_data_1
main_loop:
    lw a0, 0(s2)        # a0 stores the pointer to first data in cmp_data_x
    addi a1, a0, 8      # a1 stores the pointer to second data in cmp_data_x
    jal ra, cimo
    
    li a7, 1            # tell ecall to print decimal
    ecall               # print result of pimo (which is in a0)
    li a0, 32           # 32 is " " in ASCII
    li a7, 11           # tell ecall to print char
    ecall               # print space
    
    addi s2, s2, 4      # s2 points to next cmp_data_x
    addi s1, s1, 1      # counter++
    bne s1, s0, main_loop
    
    addi sp, sp, 16
    j exit
    
    
# check if multiplication overflow:
cimo:
    addi sp, sp, -36
    sw ra, 0(sp)
    sw s0, 4(sp)
    sw s1, 8(sp)
    sw s2, 12(sp)
    sw s3, 16(sp)
    sw s4, 20(sp)
    sw s5, 24(sp)
    sw s6, 28(sp)
    sw s7, 32(sp)
    
    lw s0, 0(a0)
    lw s1, 4(a0)
    li s2, 0
    li s3, 0            # s0 s1 s2 s3 is now the value of x0

    lw s4, 0(a1)
    lw s5, 4(a1)        # s4 s5 is now the value of x1

    add t0, zero, zero
    add t1, zero, zero
    add t2, zero, zero
    add t3, zero, zero  # t0 t1 t2 t3 is now the value of sum

    add s7, zero, zero  # s7 is now the value of cnt
    li s6, 64

cimo_loop:

    bne t2, zero, cimo_ret_t
    bne t3, zero, cimo_ret_t
    beq s7, s6, cimo_ret_f

    andi t4, s4, 1      # t4 is now the LSB of x1
    beq t4, zero, cimo_is_zero  # skip (sum = sum + x0)

cimo_add_sum:
    add t0, t0, s0
    sltu t4, t0, s0     # t4 is now the carry bit
    add t1, t1, s1
    sltu t5, t1, s1     # t5 is now the carry bit
    add t1, t1, t4
    add t2, t2, s2
    sltu t6, t2, s2     # t6 is now the carry bit
    add t2, t2, t5
    add t3, t3, s3
    add t3, t3, t6      # sum = sum + x0

cimo_is_zero:
    srli s4, s4, 1
    slli t4, s5, 31
    or s4, s4, t4
    srli s5, s5, 1      # x1 = x1 >> 1

    slli s3, s3, 1
    srli t4, s2, 31
    or s3, s3, t4
    slli s2, s2, 1
    srli t4, s1, 31
    or s2, s2, t4
    slli s1, s1, 1
    srli t4, s0, 31
    or s1, s1, t4
    slli s0, s0, 1      # x0 = x0 << 1

    addi s7, s7, 1      # cnt++

    j cimo_loop

cimo_ret_t:
    addi a0, zero, 1
    j cimo_end

cimo_ret_f:
    add a0, zero, zero

cimo_end:
    lw ra, 0(sp)
    lw s0, 4(sp)
    lw s1, 8(sp)
    lw s2, 12(sp)
    lw s3, 16(sp)
    lw s4, 20(sp)
    lw s5, 24(sp)
    lw s6, 28(sp)
    lw s7, 32(sp)
    addi sp, sp, 36
    ret


# util func
print_hex:
    addi sp, sp, -4
    sw ra, 0(sp)
    li a7, 34
    ecall       # print value
    li a0, 32   # 32 is " " in ASCII
    li a7, 11
    ecall       # print space
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

print_dec:
    addi sp, sp, -4
    sw ra, 0(sp)
    li a7, 1
    ecall       # print value
    li a0, 32   # 32 is " " in ASCII
    li a7, 11
    ecall       # print space
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

exit:
    nop