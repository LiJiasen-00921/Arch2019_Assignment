# Arch2019

Project resources for System(I) 2019 Fall

Stay tuned by pulling this repo to your own.

## Acknowledgment

### Thank wjwwood and Y.F.Lin for the Course Project

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

#### Install RiscV toolchain 
Here is a brief introduction about how to install RiscV toolchain 
for linux or WSL on Windows in 2019.
Before installation, make sure you have at least *8GB free space*. First clone the official repository: 
```
git clone --recursive https://github.com/riscv/riscv-gnu-toolchain.git && cd riscv-gnu-toolchain
```
This might take some time. It is suggested to add proxy for your git or just copy the software from TA (If you don't have one, ask TA for help):  
The following command can activate proxy until you reboost your computer. 
```
export all_proxy="http://127.0.0.1:1080"
export ALL_PROXY="http://127.0.0.1:1080"
```
Now we can start to compile the toolchain
```
./configure --prefix=/opt/riscv --with-arch=rv32ia --with-abi=ilp32 
sudo make all -j12
```
**Remark**: Here `--with-arch=rv32ia` means we only use the ISA with 32-bit address space, 32 registers and atomic instruction (That's what A-extension means). Using `--with-arch=rv32i` will leads to build error. And using `--with-arch=rv32gc` (This is suggested by the official repository, here `g` stands for general which means `i,m,a,f,d` extensions, `c` stands for support  16-bit instructions) will make our `build.sh` crashed.

You may wait for about an hour without `-j12`. `-j12` means that you use 12 threads. After that add the 
toolchain to your PATH, that is adding the following to your `$HOME/.bashrc` or `$HOME/.zshrc` if you are using zsh.
```
export PATH=$PATH:/opt/riscv/bin
```
check if your toolchain works by  
```
riscv32-unknown-elf-gcc -v
riscv32-unknown-linux-gnu-gcc -v 
```
#### Building testcase

In directory 'riscv', run script

    ./build.sh all

Intermediate files:

- testdata/om/testname.om: compiled ELF file
- testdata/data/testname.data: RAM data that can be read by verilog
- testdata/bin/testname.bin: RAM data in binary
- testdata/dump/testname.dump: decompilation of the ELF file

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
