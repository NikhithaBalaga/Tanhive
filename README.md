# Tanhive
PROJECT -> Two Stage Convolution Neural Network Using FSM 

This is a project for generating a bitstream file from Verilog RTL code using Vivado and programming it onto the Pynq-Z1 board.

TABLE OF CONTENTS:

Installation

Usage

Building the Project

Implementation

I/O Modules

SRAM Organization


INSTALLATION:

To use this project, you'll need to have Vivado installed on your computer. You can download Vivado from the Xilinx website. You'll also need to have the Pynq-Z1 board and a connection to your computer.

USAGE:

To generate a bitstream file from the Verilog RTL code and program it onto the Pynq-Z1 board, follow these steps:

•	Open Vivado and create a new project.

•	Add the Verilog RTL code files(conv_fsm.v) to the project.

•	Create a new testbench and add the Verilog testbench files(dut.v) to the project.

•	Run the simulation to verify the design.

•	Generate the netlist file by following the Vivado synthesis flow (syntheis files)

•	Generate the bitstream file by following the Vivado implementation flow (.bit, .tcl, .hwh)

•	Connect the Pynq-Z1 board to your computer using a USB cable.

•	Create a new project for the Pynq-Z1 board in Vivado.

•	Program the bitstream file onto the Pynq-Z1 board using Vivado.

•	For more detailed instructions on using Vivado and programming the Pynq-Z1 board, refer to the Vivado User Guide and the Pynq-Z1 Board User Manual.

BUILDING THE PROJECT:

•	Inputs are a NxN 8-bit per entry input array and are stored in the input SRAM. The inputs are signed but will only take on positive values. N will be provided in the memory for each problem. N will be a power of 2 and no larger than 64. 

•	The kernel matrix is 3x3 8-bit kernel array and is stored in the weight SRAM. The weights are signed and can be positive or negative.  

•	The output will be sized as ((N-2)/2)*((N-2)/2) array and your design will load it into the output SRAM. The outputs will be 8-bits wide but will only take on positive values. 

•	We implemented 2 stages, a single stage of a convolution with a ReLu function, a single stage of max pooling.

IMPLEMENTATION:

We implemented a single stage of a convolutional neural network with a ReLu activation 
function. We implemented a multiplier and accumulator to implement the CNN function. The multiplier will have two 8-bit inputs and a 16-bit output. The accumulator will be 20 bits wide. This will ensure that there is no overflow. The result of the ReLu function will be saturated to 8 bits, i.e. Any value greater than 127 will be 127. 

The resulting matrix from this stage will have size (N-2)*(N-2) and have 8-bit entries. 
We implemented a MaxPooling function based on the max in each 2*2 subarray. The input to the MaxPooling layer will be the output of the convolutional layer. No ReLu is needed. The output from this stage will be an ((N-2)/2)*((N-2)/2) array. 

The accumulator will be 20 bits wide. This (together with control over the weights in training) will ensure that there is no overflow. The result of the ReLu function will be 
saturated to 8 bits, i.e. Any value greater than 127 will be 127.

I/O MODULES:

The IO are as follows: 
•	Interfaces to three SRAMs as described above. Behavior is described below. 

•	Interface to a fourth SRAM.

•	clk; Clock from the test fixture. Name of the clock in the synthesis script. 

•	reset_b; Reset from the test fixture. This will go active low at the start of the simulation run. 

•	dut_run; This will be set high by the test fixture when it is ready for a new run to start. 

•	dut_busy; This is an output of our design and will be high when the hardware is busy. 

It is to be set low by the reset. It will go high one cycle after dut_run goes high and stay high until one cycle after the last output is sent to the output memory. 
In this project, the weights are fixed for each run. However, multiple input sets will be provided. We kept running the inputs until the size entry in the memory takes on the value FFFF. The first entry will be a valid array size, not FFFF. When dut_run goes high, the needed operations are performed for one or more examples stored in the SRAMs and the outputs are written to the results SRAM. 
We gave four sets of sample inputs and expected outputs. 

Note: These are stored in the subdirectories input_0 and input_1 respectively. Two more will be given just before the project demo. These are held back so as to prevent us from hard-wiring our code for the provided inputs. The organization of the SRAMs will be so as to contain packed values (two per 16-bit word) in row-major order. 

SRAM ORGANIZATION:

The weights of SRAM will be organized as follows. The convolutional kernel is stored first. 

Addr Contents 

0000 k00 k01 // i.e. k00 is in the high order bits

0001 k02 k10 

0002 k11 k12 

0003 k20 k21 

0004 k22 00 
…

last pair of weights – depends on N 

The input SRAM will be organized as follows. An example is given where the first input matrix is 

16x16.3x3 

7x7 

15x15 

Addr Contents 

0000 00 N1 // note 0s stored first 

0001 x00 x01 
… 
0008 x0,14 x0,15 

0009 x10 x11 
… 
0040 x15,14 x15,15 

0041 00 N2 // if this is FF FF stop processing 

0042 x00 x01 
The output SRAM are organized in a way where zeros are appended at the end of every set of output corresponding to each set of N *N inputs.


