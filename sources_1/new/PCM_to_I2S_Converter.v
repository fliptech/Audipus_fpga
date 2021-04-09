module PCM_to_I2S_Converter(
    input           clk,
    input           audio_en,
    input           audio_test,
    input           l_data_en,
    input           r_data_en,
    input [23:0]    l_data,
    input [23:0]    r_data,
//    output          sclk,  // use i2s_sclk from ClockGeneration
    output reg      bclk,
    output reg      lrclk,
    output reg      i2s_valid,
    output          s_data
);    

reg         bclk_en, l_shift_en, r_shift_en, lrclk_dly;
//reg [2:0]   bclk_shift, lrclk_shift;
reg [23:0]  shift_data_reg;
//reg [23:0]  l_data_reg, r_data_reg;
reg [3:0]   bclk_count;
reg [5:0]   bit_count;

reg      l_fifo_rd_en, r_fifo_rd_en;


wire [23:0] l_fifo_dout, r_fifo_dout;
wire        l_fifo_full, l_fifo_empty;
wire        r_fifo_full, r_fifo_empty;
wire        l_half_full, r_half_full;

assign s_data = shift_data_reg[23];

// timing signals @ sample freq = 96KHz
// bclk, bclk_en generation ** bclk = 49.152MHz/16
always @ (posedge clk) begin    // clk freq = 49.152MHz
    if (!audio_en) begin
        bclk_count <= 0;    
        bclk <= 1'b0;
        bclk_en <= 1'b0;
    end
    else begin  // 1 bclk = 8 clk  
        case (bclk_count)
            3  : begin
                bclk <= 1'b0;
                bclk_en <= 1'b1;            // on falling edge of bclk
                bclk_count <= bclk_count + 1;
            end
            7  : begin
                bclk <= 1'b1;
                bclk_en <= 1'b0;
                bclk_count <= 0;
            end
            default:    begin
                bclk <= bclk;
                bclk_en <= 1'b0;
                bclk_count <= bclk_count + 1;
            end
        endcase               
    end
end
//assign dac_sclk = fir_bypass ? i2s_sclk : clkGen_i2s_clk;

// lrclk, l_data_load, r_data_load generation ** lrclk = bclk/64
always @ (posedge clk) begin    // clk freq = 49.152MHz
    if (!i2s_valid) begin
        bit_count <= 0;    
        lrclk <= 1'b0;
        l_fifo_rd_en <= 1'b0;
        r_fifo_rd_en <= 1'b0;
    end
    else if (bclk_en) begin         // 1 lrclk = 64 bclk                
        case (bit_count)
            31  : begin
                lrclk <= 1'b1;
                l_fifo_rd_en <= 1'b1;
                r_fifo_rd_en <= 1'b0;
                bit_count <= bit_count + 1;
           end
            63  : begin
                lrclk <= 1'b0;
                r_fifo_rd_en <= 1'b1;
                l_fifo_rd_en <= 1'b0;
                bit_count = 0;
            end
            default: begin
                lrclk <= lrclk;
                l_fifo_rd_en <= 1'b0;
                r_fifo_rd_en <= 1'b0;
                bit_count <= bit_count + 1;
            end
        endcase
    end
    else begin
        bit_count <= bit_count;
        lrclk <= lrclk;
        l_fifo_rd_en <= 1'b0;
        r_fifo_rd_en <= 1'b0;
    end
end

always @ (posedge clk) begin    // clk freq = 49.152MHz
    if (r_fifo_empty) 
        i2s_valid <= 1'b0;
    else if (r_half_full) 
        i2s_valid <= 1'b1;
    else
        i2s_valid <= i2s_valid;
end


i2s_fifo l_pcm_to_i2s_fifo (
    .clk          (clk),            // input wire clk
    .rst          (!audio_en),      // input wire rst
    .din          (l_data),         // input wire [23 : 0] din
    .wr_en        (l_data_en),      // input wire wr_en
    .rd_en        (l_fifo_rd_en),   // input wire rd_en
    .dout         (l_fifo_dout),    // output wire [23 : 0] dout
    .full         (l_fifo_full),    // output wire full
    .empty        (l_fifo_empty),   // output wire empty
    .prog_full    (l_half_full)     // output 200 entries    
);


i2s_fifo r_pcm_to_i2s_fifo (
    .clk          (clk),            // input wire clk
    .rst          (!audio_en),      // input wire rst
    .din          (r_data),         // input wire [23 : 0] din
    .wr_en        (r_data_en),      // input wire wr_en
    .rd_en        (r_fifo_rd_en),   // input wire rd_en
    .dout         (r_fifo_dout),    // output wire [23 : 0] dout
    .full         (r_fifo_full),    // output wire full
    .empty        (r_fifo_empty),   // output wire empty
    .prog_full    (r_half_full)     // output 200 entries
);

    

// I2S shift out using I2S Format
always @ (posedge clk) begin
    if (bclk_en) begin
        lrclk_dly <= lrclk;
        if (!lrclk && lrclk_dly) begin           
//          if (l_fifo_empty)
//              shift_data_reg <= 0;
            if (audio_test)
                shift_data_reg <= 24'h666aaa;
            else
                shift_data_reg <= l_fifo_dout;
        end
        else if (lrclk && !lrclk_dly) begin
//          if (r_fifo_empty)
//              shift_data_reg <= 0;
            if (audio_test)
                shift_data_reg <= 24'h555999;
            else
                shift_data_reg <= r_fifo_dout;
        end
        else begin // shift right, lsb first
            shift_data_reg[0] <= 1'b0;
            shift_data_reg[23:1] <= shift_data_reg[22:0];
        end
    end
    else begin
        shift_data_reg <= shift_data_reg; 
        lrclk_dly <= lrclk_dly;           
    end

end

endmodule
