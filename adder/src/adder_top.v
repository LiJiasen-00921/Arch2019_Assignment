/* ACM Class System (I) 2018 Fall Assignment 1 */
// top level module for adder

module adder_top
(
    input     clk,      // 100MHz clock signal
    input     btnC,     // reset signal
    input     RsRx,     // RS232 Rx signal
    output    RsTx     // RS232 Tx signal
);

wire rst;
assign rst = btnC;

wire [15:0] adder_opr1, adder_opr2, adder_ans;
wire        adder_carry;

hci adder_hci(
  .clk(clk),
  .rst(rst),
  .rx(RsRx),
  .tx(RsTx),
  .adder_opr1(adder_opr1),
  .adder_opr2(adder_opr2),
  .adder_ans(adder_ans),
  .adder_carry(adder_carry)
);

adder adder(
  adder_opr1,   // first operand
  adder_opr2,   // second operand
  adder_ans,    // result
  adder_carry   // carry bit
);

endmodule