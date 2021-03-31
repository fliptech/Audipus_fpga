module PCM_to_I2S_Converter(
    input           clk,
    input           reset_n,
    input          l_data_valid,
    input          r_data_valid,
    output reg      l_data_en,
    output reg      r_data_en,
    input [23:0]    l_data,
    input [23:0]    r_data,
    output          sclk,
    output reg      bclk,
    output reg      lrclk,
    output reg [23:0] s_data
);    

reg         bclk_en, l_shift_en, r_shift_en;
//reg [2:0]   bclk_shift, lrclk_shift;
reg [23:0]  l_data_reg, r_data_reg;
//reg [15:0]  i2s_seq_cnt;
//reg [15:0]  lr_cnt;
reg [3:0]   i2s_seq_cnt;
reg [5:0]   lr_cnt;

// timing signals @ sample freq = 96KHz
// bclk, bclk_en generation ** bclk = 49.152MHz/16
always @ (posedge clk) begin    // clk freq = 49.152MHz
    if (reset_n) begin
        i2s_seq_cnt <= 0;    
        bclk <= 1'b0;
        bclk_en <= 1'b0;
    end
    else begin  // 1 bclk = 8 clk  
        case (i2s_seq_cnt)
            3  : begin
                bclk <= 1'b0;
                bclk_en <= 1'b1;
                bclk_en <= 1'b1;            // on falling edge of bclk
                i2s_seq_cnt <= i2s_seq_cnt + 1;
            end
            7  : begin
                bclk <= 1'b1;
                bclk_en <= 1'b0;
                i2s_seq_cnt <= 0;
            end
            default:    begin
                bclk <= bclk;
                bclk_en <= 1'b0;
                i2s_seq_cnt <= i2s_seq_cnt + 1;
            end
        endcase               
    end
end

// lrclk, l_data_en, r_data_en generation ** lrclk = bclk/64
always @ (posedge clk) begin    // clk freq = 49.152MHz
    if (reset_n) begin
        lr_cnt <= 0;    
     end
    else if (bclk_en) begin         // 1 lrclk = 64 bclk                
        case (lr_cnt)
            15  : begin
                lrclk <= 1'b1;
                l_data_en <= 1'b1;
                r_data_en <= 1'b0;
                lr_cnt <= lr_cnt + 1;
           end
            31  : begin
                lrclk <= 1'b0;
                r_data_en <= 1'b1;
                l_data_en <= 1'b0;
                lr_cnt = 0;
            end
            default: begin
                lrclk <= lrclk;
                l_data_en <= 1'b0;
                r_data_en <= 1'b0;
                lr_cnt <= lr_cnt + 1;
            end
        endcase
    end
    else begin
        lr_cnt <= lr_cnt;
        lrclk <= lrclk;
    end
end



// I2S shift out using Std Data Format
always @ (posedge clk) begin
    if (bclk_en) begin
        if (l_data_en)
            l_data_reg <= l_data;
        else if (r_data_en)
            r_data_reg <= r_data;
        else if (!lrclk) begin
            s_data <= l_data_reg[23];
            l_data_reg[0] <= 1'b0;
            l_data_reg[23:1] <= l_data_reg[22:0];
        end
        else /* if (lrclk) */ begin
            s_data <= r_data_reg[23];
            r_data_reg[0] <= 1'b0;
            r_data_reg[23:1] <= r_data_reg[22:0];   
        end
    end
    else begin
        s_data <= s_data;
        l_data_reg <= l_data_reg;            
        r_data_reg <= r_data_reg;
    end

end

endmodule
