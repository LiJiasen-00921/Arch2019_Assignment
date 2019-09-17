/* ACM Class System (I) 2018 Fall Assignment 1 */
// host communication interface

// for adder assignment

module hci
(
    input           clk,
    input           rst,
    input           rx,
    output          tx,
    
    input  [15:0]   adder_ans,
    input           adder_carry,
    output [15:0]   adder_opr1,
    output [15:0]   adder_opr2

);

// Debug packet opcodes.
localparam [7:0] OP_ECHO                 = 8'h00,
                 OP_OPRAND               = 8'h01;

// Error code bit positions.
localparam DBG_UART_PARITY_ERR = 0,
           DBG_UNKNOWN_OPCODE  = 1;

// Symbolic state representations.
localparam [4:0] S_DISABLED              = 5'h00,
                 S_DECODE                = 5'h01,
                 S_ECHO_STG_0            = 5'h02,
                 S_ECHO_STG_1            = 5'h03,
                 S_OPRAND                = 5'h04,
                 S_ANSWER                = 5'h05;
                 
reg [ 4:0] q_state,            d_state;
reg [ 1:0] q_decode_cnt,       d_decode_cnt;
reg [16:0] q_execute_cnt,      d_execute_cnt;
reg [ 1:0] d_err_code,         q_err_code;

// UART output buffer FFs.
reg  [7:0] q_tx_data, d_tx_data;
reg        q_wr_en,   d_wr_en;

// UART input signals.
reg        rd_en;
wire [7:0] rd_data;
wire       rx_empty;
wire       tx_full;
wire       parity_err;

// Adder input/output
reg  [15:0] q_adder_opr1,     d_adder_opr1;
reg  [15:0] q_adder_opr2,     d_adder_opr2;

always @(posedge clk)
  begin
    if (rst)
      begin
        q_state            <= S_DECODE;
        q_decode_cnt       <= 2'b00;
        q_execute_cnt      <= 17'b00;
        q_tx_data          <= 8'h00;
        q_wr_en            <= 1'b0;
        q_err_code         <= 0;
        q_adder_opr1       <= 15'b0;
        q_adder_opr2       <= 15'b0;
      end
    else
      begin
        q_state            <= d_state;
        q_decode_cnt       <= d_decode_cnt;
        q_execute_cnt      <= d_execute_cnt;
        q_tx_data          <= d_tx_data;
        q_wr_en            <= d_wr_en;
        q_err_code         <= d_err_code;
        q_adder_opr1       <= d_adder_opr1;
        q_adder_opr2       <= d_adder_opr2;
      end
  end

uart #(.SYS_CLK_FREQ(100000000),
       .BAUD_RATE(38400),
       .DATA_BITS(8),
       .STOP_BITS(1),
       .PARITY_MODE(1)) uart_blk
(
  .clk(clk),
  .reset(rst),
  .rx(rx),
  .tx_data(q_tx_data),
  .rd_en(rd_en),
  .wr_en(q_wr_en),
  .tx(tx),
  .rx_data(rd_data),
  .rx_empty(rx_empty),
  .tx_full(tx_full),
  .parity_err(parity_err)
);

always @*
  begin
    d_state        = q_state;
    d_decode_cnt   = q_decode_cnt;
    d_execute_cnt  = q_execute_cnt;
    d_adder_opr1   = q_adder_opr1;
    d_adder_opr2   = q_adder_opr2;
    d_err_code     = q_err_code;

    rd_en         = 1'b0;
    d_tx_data     = 8'h00;
    d_wr_en       = 1'b0;

    if (parity_err)
      d_err_code[DBG_UART_PARITY_ERR] = 1'b1;

    case (q_state)
      S_DISABLED:
        begin
          if (!rx_empty)
            begin
              d_state = S_DECODE;
            end
        end
      S_DECODE:
        begin
          if (!rx_empty)
            begin
              rd_en = 1'b1;
              d_decode_cnt = 0;
              case (rd_data)
                OP_ECHO:                 d_state = S_ECHO_STG_0;
                OP_OPRAND:               d_state = S_OPRAND;
                default: begin
                  d_err_code[DBG_UNKNOWN_OPCODE] = 1'b1;
                  d_state = S_DECODE;
                end
              endcase
            end
        end
      S_ECHO_STG_0:
        begin
          if (!rx_empty)
            begin
              rd_en = 1'b1;
              d_decode_cnt = q_decode_cnt + 3'h1;
              if (q_decode_cnt == 0)
                begin
                  d_execute_cnt = rd_data;
                end
              else
                begin
                  d_execute_cnt = { rd_data, q_execute_cnt[7:0] };
                  d_state = (d_execute_cnt) ? S_ECHO_STG_1 : S_DECODE;
                end
            end
        end
      S_ECHO_STG_1:
        begin
          if (!rx_empty)
            begin
              rd_en = 1'b1;
              d_execute_cnt = q_execute_cnt - 17'h00001;
              d_tx_data = rd_data;
              d_wr_en = 1'b1;
              if (d_execute_cnt == 0)
                d_state = S_DECODE;
            end
        end
      S_OPRAND:
        begin
          if (!rx_empty)
            begin
              rd_en = 1'b1;
              d_decode_cnt = q_decode_cnt + 3'h001;
              case (q_decode_cnt)
                2'b00: d_adder_opr1 = rd_data;
                2'b01: d_adder_opr1 = {rd_data, q_adder_opr1[7:0]};
                2'b10: d_adder_opr2 = rd_data;
                2'b11: begin
                  d_adder_opr2 = {rd_data, q_adder_opr2[7:0]};
                  d_execute_cnt = 3'b100;
                  d_state = S_ANSWER;
                end
              endcase
            end
        end
      S_ANSWER:
        begin
          if (q_execute_cnt[2])
            begin
              // Dummy cycle.  Allow adder 1 cycle to return result, and allow uart tx fifo
              // 1 cycle to update tx_full setting.
              d_execute_cnt = q_execute_cnt - 17'h00001;
            end
          else if (!tx_full)
            begin
              d_execute_cnt = q_execute_cnt - 17'h00001;
              case (q_execute_cnt)
                2'b01: d_tx_data = {7'b0, adder_carry};
                2'b10: d_tx_data = adder_ans[15:8];
                2'b11: d_tx_data = adder_ans[7:0];
              endcase
              d_wr_en = 1'b1;
              if (d_execute_cnt==0) d_state = S_DECODE;
            end
        end
    endcase
end

assign adder_opr1 = q_adder_opr1;
assign adder_opr2 = q_adder_opr2;

endmodule