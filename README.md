# Arch2019

Project resources for System(I) 2019 Fall

Stay tuned by pulling this repo to your own.

## Project Structure & Instruction

#### Simulation

Using Vivado

1. Create a RTL project in Vivado
2. Put 'adder.v' into 'Sources'
3. Put 'test_adder.v' into 'Simulation Sources'
4. Run Behavioral Simulation
5. Make sure to run at least 100 steps during the simulation (usually 100ns)
6. You can see the results in 'Tcl console'

Or using iverilog:

    iverilog test_adder.v
    vvp a.out

#### FPGA testing

In top directory, clone the serial library and build

    git submodule update --init
    cd serial
    make
    make install

Dependencies see [wjwwood/serial](https://github.com/wjwwood/serial)

In 'ctrl' folder, build the controller

    ./build.sh

Run the controller (may require superuser privilege)

    ./run.sh uart-port

the UART port should look like:

on Linux: /dev/ttyUSB1

on WSL: /dev/ttyS4

on Windows: COM3 (not tested)

Especially suggest WSL


### RISC-V ISA Assignment (100 points of the course work)

You should hand in at least a valid project.
For the basic score, we only test the correctness.
Speed and special arch can be bonuses. 

#### Prerequisite

- serial library (see above)
- Vivado / iverilog + gtkwave
- RISC-V GNU Compiler Toolchain (see wiki for details)

#### Overview

- src:  template & support modules for riscv
- sim:  source files for simulation (including a demo cpu)
- ctrl: controller used for loading RAM data into FPGA BRAM and debugging
- sys:  basic system and I/O functions
- testcase: test programs written in c

#### Testcase

- testcase/testname.c:   source file
- testcase/testname.in:  input
- testcase/testname.ans: answer

#### Building testcase

In directory 'riscv', run script

    ./build_test.sh testname

This will compile 'testcase/testname.c' and output all intermediate files to directory 'test/'

Intermediate files:

- test/test.c: copy of the testcase source file
- test/test.om: compiled ELF file
- test/test.data: RAM data that can be read by verilog
- test/test.bin: RAM data in binary
- test/test.dump: decompilation of the ELF file

#### Simulation

modify and run script

    ./run_test.sh testname

This will first build the testcase and then run custom commands for simulation.

You can also use custom Makefile to run testcases.

Testcases with input are currently unsupported in simulation, use testcases with no input instead.

#### FPGA testing

Build the testcase

In directory 'ctrl', build the controller

    ./build.sh

Run the controller (may require superuser privilege)

    ./run.sh path-to-ram path-to-input uart-port

RAM data can be found as 'test/test.bin' after building the testcase.

The controller will upload the data to FPGA BRAM (128KiB max), and can then be used to manage I/O and support debugging.

Alternatively, modify and run script

    ./run_test_fpga.sh testname

#### Debug packet definition

Echo

    0x00: opcode: 0x00
    0x01: BYTE_COUNT [7:0]
    0x02: BYTE_COUNT [15:8]
    rest: data to be echoed

    return: data echoed

CPU Memory Read

    0x00: opcode: 0x01
    0x01: MEM_ADDR [7:0]
    0x02: MEM_ADDR [15:8]
    0x03: MEM_ADDR [16]
    0x04: BYTE_COUNT [7:0]
    0x05: BYTE_COUNT [15:8]

    return: BYTES

CPU Memory Write

    0x00: opcode: 0x02
    0x01: MEM_ADDR [7:0]
    0x02: MEM_ADDR [15:8]
    0x03: MEM_ADDR [16]
    0x04: BYTE_COUNT [7:0]
    0x05: BYTE_COUNT [15:8]
    rest: data to write

Break

    0x00: opcode: 0x03

Run

    0x00: opcode: 0x04

CPU Register Read (demo)

    0x00: opcode: 0x05

Query Break

    0x00: opcode: 0x07

Query Error Code

    0x00: opcode: 0x08

#### Benchmark

(to be decided)

## Notes

- In 'sys/rom.s', the sp is now initialized to 0x00020000 (can be enlarged if running in simulation).
- When running program on FPGA, do not allocate too much(10000+ int) space as the RAM is only 128KB.
- run ```./configure --prefix=/opt/riscv --with-arch=rv32i --with-abi=ilp32``` before making the RISC-V toolchain.
