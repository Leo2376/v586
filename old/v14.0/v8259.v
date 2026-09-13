/* verilator lint_off UNUSED */
/* verilator lint_off CASEX */
module v8259(
    input               clk,
    input               rst_n,
    
    //master pic
    input               ms_address,
    input               ms_read,
    output reg  [7:0]   ms_readdata,
    input               ms_write,
    input       [7:0]   ms_writedata,
    
    //slave pic
    input               sl_address,
    input               sl_read,
    output reg  [7:0]   sl_readdata,
    input               sl_write,
    input       [7:0]   sl_writedata,
    
    //interrupt input
    input       [15:0]  inter_input,
    
    //interrupt output
    output reg          inter_do,
    output reg  [7:0]   inter_vector,
    input               inter_done
);

reg sla_polled;
reg sla_current_irq;    
reg sla_read_reg_select;
reg sl_read_last;
reg ms_read_last;
reg [15:0] inter_last;
reg sla_in_init;
reg sla_init_requires_4;
reg sla_ltim;
reg [2:0] sla_init_byte_expected;
reg [2:0] sla_lowest_priority;
reg sla_special_mask;
reg [7:0] sla_imr;
reg [7:0] sla_irr;
reg [7:0] sla_isr;
reg [4:0] sla_inter_offset;
reg sla_auto_eoi;
reg sla_rotate_on_aeoi;
reg sla_current_irq_last;
reg mas_polled;
reg mas_read_reg_select;
reg mas_special_mask;
reg [2:0] mas_init_byte_expected;
reg mas_in_init;
reg mas_init_requires_4;
reg mas_ltim;
reg [2:0] mas_lowest_priority;
reg mas_rotate_on_aeoi;
reg mas_auto_eoi;
reg [4:0] mas_inter_offset;
reg [7:0] mas_irr;
reg [7:0] mas_imr;
reg sla_spurious;
reg [7:0] mas_isr;
reg mas_sla_active;
reg mas_current_irq;    
reg mas_spurious;

wire [7:0] mas_inter_vector_bits;
wire sla_acknowledge_not_spurious ;
wire sla_acknowledge              ;
wire [7:0] inter_vector_bits ;
wire [2:0] sla_selected_shifted_isr_first ;
wire [7:0] sla_selected_shifted_isr_first_bits;
wire mas_acknowledge_not_spurious;
wire [7:0] mas_selected_shifted_isr_first_bits;
wire mas_acknowledge;

//------------------------------------------------------------------------------

always @(posedge clk or negedge rst_n) begin if(rst_n == 1'b0) sl_read_last <= 1'b0; else if(sl_read_last) sl_read_last <= 1'b0; else sl_read_last <= sl_read; end 
wire sl_read_valid = sl_read && sl_read_last == 1'b0;

always @(posedge clk or negedge rst_n) begin if(rst_n == 1'b0) ms_read_last <= 1'b0; else if(ms_read_last) ms_read_last <= 1'b0; else ms_read_last <= ms_read; end 
wire ms_read_valid = ms_read && ms_read_last == 1'b0;

//------------------------------------------------------------------------------

always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0)   inter_last <= 16'd0;
    else                inter_last <= inter_input;
end


wire sla_init_icw1 = sl_write && sl_address == 1'b0 && sl_writedata[4] == 1'b1;
wire sla_init_icw2 = sl_write && sl_address == 1'b1 && sla_in_init && sla_init_byte_expected == 3'd2;
wire sla_init_icw3 = sl_write && sl_address == 1'b1 && sla_in_init && sla_init_byte_expected == 3'd3;
wire sla_init_icw4 = sl_write && sl_address == 1'b1 && sla_in_init && sla_init_byte_expected == 3'd4;

wire sla_ocw1 = sla_in_init == 1'b0 && sl_write && sl_address == 1'b1;
wire sla_ocw2 = sl_write && sl_address == 1'b0 && sl_writedata[4:3] == 2'b00;
wire sla_ocw3 = sl_write && sl_address == 1'b0 && sl_writedata[4:3] == 2'b01;

always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0)                       sla_polled <= 1'b0;
    else if(sla_polled && sl_read_valid) sla_polled <= 1'b0;
    else if(sla_ocw3)                       sla_polled <= sl_writedata[2];
end

always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0)                                                       sla_read_reg_select <= 1'b0;
    else if(sla_init_icw1)                                                  sla_read_reg_select <= 1'b0;
    else if(sla_ocw3 && sl_writedata[2] == 1'b0 && sl_writedata[1])   sla_read_reg_select <= sl_writedata[0];
end

always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0)                                                       sla_special_mask <= 1'd0;
    else if(sla_init_icw1)                                                  sla_special_mask <= 1'd0;
    else if(sla_ocw3 && sl_writedata[2] == 1'b0 && sl_writedata[6])   sla_special_mask <= sl_writedata[5];
end

always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0)                                   sla_in_init <= 1'b0;
    else if(sla_init_icw1)                              sla_in_init <= 1'b1;
    else if(sla_init_icw3 && ~(sla_init_requires_4))    sla_in_init <= 1'b0;
    else if(sla_init_icw4)                              sla_in_init <= 1'b0;
end

always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0)       sla_init_requires_4 <= 1'b0;
    else if(sla_init_icw1)  sla_init_requires_4 <= sl_writedata[0];
end

always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0)       sla_ltim <= 1'b0;
    else if(sla_init_icw1)  sla_ltim <= sl_writedata[3];
end

always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0)                               sla_init_byte_expected <= 3'd0;
    else if(sla_init_icw1)                          sla_init_byte_expected <= 3'd2;
    else if(sla_init_icw2)                          sla_init_byte_expected <= 3'd3;
    else if(sla_init_icw3 && sla_init_requires_4)   sla_init_byte_expected <= 3'd4;
end

always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0)                                                           sla_lowest_priority <= 3'd7;
    else if(sla_init_icw1)                                                      sla_lowest_priority <= 3'd7;
    else if(sla_ocw2 && sl_writedata == 8'hA0)                               sla_lowest_priority <= sla_lowest_priority + 3'd1;  //rotate on non-specific EOI
    else if(sla_ocw2 && { sl_writedata[7:3], 3'b000 } == 8'hC0)              sla_lowest_priority <= sl_writedata[2:0];        //set priority
    else if(sla_ocw2 && { sl_writedata[7:3], 3'b000 } == 8'hE0)              sla_lowest_priority <= sl_writedata[2:0];        //rotate on specific EOI
    else if(sla_acknowledge_not_spurious && sla_auto_eoi && sla_rotate_on_aeoi) sla_lowest_priority <= sla_lowest_priority + 3'd1;  //rotate on AEOI
end

always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0)           sla_imr <= 8'hFF;
    else if(sla_init_icw1)      sla_imr <= 8'h00;
    else if(sla_ocw1)           sla_imr <= sl_writedata;
end

wire [7:0] sla_edge_detect = {
    inter_input[15] == 1'b1 && inter_last[15] == 1'b0,
    inter_input[14] == 1'b1 && inter_last[14] == 1'b0,
    inter_input[13] == 1'b1 && inter_last[13] == 1'b0,
    inter_input[12] == 1'b1 && inter_last[12] == 1'b0,
    inter_input[11] == 1'b1 && inter_last[11] == 1'b0,
    inter_input[10] == 1'b1 && inter_last[10] == 1'b0,
    inter_input[9]  == 1'b1 && inter_last[9] == 1'b0,
    inter_input[8]  == 1'b1 && inter_last[8] == 1'b0
};

always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0)                       sla_irr <= 8'h00;
    else if(sla_init_icw1)                  sla_irr <= 8'h00;
    else if(sla_acknowledge_not_spurious)   sla_irr <= (sla_irr & inter_input[15:8] & ~(inter_vector_bits)) | ((~(sla_ltim))? sla_edge_detect : inter_input[15:8]);
    else                                    sla_irr <= (sla_irr & inter_input[15:8])                            | ((~(sla_ltim))? sla_edge_detect : inter_input[15:8]);
end

wire [7:0] sla_writedata_mask =
    (sl_writedata[2:0] == 3'd0)?     8'b00000001 :
    (sl_writedata[2:0] == 3'd1)?     8'b00000010 :
    (sl_writedata[2:0] == 3'd2)?     8'b00000100 :
    (sl_writedata[2:0] == 3'd3)?     8'b00001000 :
    (sl_writedata[2:0] == 3'd4)?     8'b00010000 :
    (sl_writedata[2:0] == 3'd5)?     8'b00100000 :
    (sl_writedata[2:0] == 3'd6)?     8'b01000000 :
                                        8'b10000000;

wire sla_isr_clear = 
    (sla_polled && sl_read_valid) || //polling
    (sla_ocw2 && (sl_writedata == 8'h20 || sl_writedata == 8'hA0)); //non-specific EOI or rotate on non-specific EOF
                                        
always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0)                                               sla_isr <= 8'h00;
    else if(sla_init_icw1)                                          sla_isr <= 8'h00;
    else if(sla_ocw2 && { sl_writedata[7:3], 3'b000 } == 8'h60)  sla_isr <= sla_isr & ~(sla_writedata_mask);                     //clear on specific EOI
    else if(sla_ocw2 && { sl_writedata[7:3], 3'b000 } == 8'hE0)  sla_isr <= sla_isr & ~(sla_writedata_mask);                     //clear on rotate on specific EOI
    else if(sla_isr_clear)                                          sla_isr <= sla_isr & ~(sla_selected_shifted_isr_first_bits);    //clear on polling or non-specific EOI (with or without rotate)
    else if(sla_acknowledge_not_spurious && ~(sla_auto_eoi))        sla_isr <= sla_isr | inter_vector_bits;                     //set
end

always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0)       sla_inter_offset <= 5'h0E;
    else if(sla_init_icw2)  sla_inter_offset <= sl_writedata[7:3];
end

always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0)       sla_auto_eoi <= 1'b0;
    else if(sla_init_icw1)  sla_auto_eoi <= 1'b0;
    else if(sla_init_icw4)  sla_auto_eoi <= sl_writedata[1];
end

always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0)                                   sla_rotate_on_aeoi <= 1'b0;
    else if(sla_init_icw1)                              sla_rotate_on_aeoi <= 1'b0;
    else if(sla_ocw2 && sl_writedata[6:0] == 7'd0)   sla_rotate_on_aeoi <= sl_writedata[7];
end

wire [7:0] sla_selected_prepare = sla_irr & ~(sla_imr) & ~(sla_isr);

wire [7:0] sla_selected_shifted =
    (sla_lowest_priority == 3'd7)?      sla_selected_prepare :
    (sla_lowest_priority == 3'd0)?      { sla_selected_prepare[0],   sla_selected_prepare[7:1] } :
    (sla_lowest_priority == 3'd1)?      { sla_selected_prepare[1:0], sla_selected_prepare[7:2] } :
    (sla_lowest_priority == 3'd2)?      { sla_selected_prepare[2:0], sla_selected_prepare[7:3] } :
    (sla_lowest_priority == 3'd3)?      { sla_selected_prepare[3:0], sla_selected_prepare[7:4] } :
    (sla_lowest_priority == 3'd4)?      { sla_selected_prepare[4:0], sla_selected_prepare[7:5] } :
    (sla_lowest_priority == 3'd5)?      { sla_selected_prepare[5:0], sla_selected_prepare[7:6] } :
                                        { sla_selected_prepare[6:0], sla_selected_prepare[7] };
    
wire [7:0] sla_selected_shifted_isr =
    (sla_lowest_priority == 3'd7)?      sla_isr :
    (sla_lowest_priority == 3'd0)?      { sla_isr[0],   sla_isr[7:1] } :
    (sla_lowest_priority == 3'd1)?      { sla_isr[1:0], sla_isr[7:2] } :
    (sla_lowest_priority == 3'd2)?      { sla_isr[2:0], sla_isr[7:3] } :
    (sla_lowest_priority == 3'd3)?      { sla_isr[3:0], sla_isr[7:4] } :
    (sla_lowest_priority == 3'd4)?      { sla_isr[4:0], sla_isr[7:5] } :
    (sla_lowest_priority == 3'd5)?      { sla_isr[5:0], sla_isr[7:6] } :
                                        { sla_isr[6:0], sla_isr[7] };

assign sla_selected_shifted_isr_first =
    (sla_selected_shifted_isr[0])?  3'd0 :
    (sla_selected_shifted_isr[1])?  3'd1 :
    (sla_selected_shifted_isr[2])?  3'd2 :
    (sla_selected_shifted_isr[3])?  3'd3 :
    (sla_selected_shifted_isr[4])?  3'd4 :
    (sla_selected_shifted_isr[5])?  3'd5 :
    (sla_selected_shifted_isr[6])?  3'd6 :
                                    3'd7;
    
wire [2:0] sla_selected_shifted_isr_first_norm = sla_lowest_priority + sla_selected_shifted_isr_first + 3'd1;

assign sla_selected_shifted_isr_first_bits =
    (sla_selected_shifted_isr_first_norm == 3'd0)?  8'b00000001 :
    (sla_selected_shifted_isr_first_norm == 3'd1)?  8'b00000010 :
    (sla_selected_shifted_isr_first_norm == 3'd2)?  8'b00000100 :
    (sla_selected_shifted_isr_first_norm == 3'd3)?  8'b00001000 :
    (sla_selected_shifted_isr_first_norm == 3'd4)?  8'b00010000 :
    (sla_selected_shifted_isr_first_norm == 3'd5)?  8'b00100000 :
    (sla_selected_shifted_isr_first_norm == 3'd6)?  8'b01000000 :
                                                    8'b10000000;
                                    
wire [2:0] sla_selected_index =
    (sla_selected_shifted[0])?      3'd0 :
    (sla_selected_shifted[1])?      3'd1 :
    (sla_selected_shifted[2])?      3'd2 :
    (sla_selected_shifted[3])?      3'd3 :
    (sla_selected_shifted[4])?      3'd4 :
    (sla_selected_shifted[5])?      3'd5 :
    (sla_selected_shifted[6])?      3'd6 :
                                    3'd7;

wire sla_irq = sla_selected_prepare != 8'd0 && (sla_special_mask || sla_selected_index < sla_selected_shifted_isr_first);

wire [2:0] sla_irq_value = (sla_irq)? sla_lowest_priority + sla_selected_index + 3'd1 : 3'd7;

always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0)           sla_current_irq <= 1'b0;
    else if(sla_init_icw1)      sla_current_irq <= 1'b0;
    else if(sla_acknowledge)    sla_current_irq <= 1'b0;
    else if(sla_irq)            sla_current_irq <= 1'b1;
end

always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0)   sla_current_irq_last <= 1'b0;
    else                sla_current_irq_last <= sla_current_irq;
end

assign sla_acknowledge_not_spurious = (sla_polled && sl_read_valid) || (mas_sla_active && inter_done && ~(sla_spurious));
assign sla_acknowledge 	     = (sla_polled && sl_read_valid) || (mas_sla_active && inter_done);

wire sla_spurious_start = sla_current_irq && ~(inter_done) && ~(sla_irq);

always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0)                       sla_spurious <= 1'd0;
    else if(sla_init_icw1)                  sla_spurious <= 1'b0;
    else if(sla_spurious_start)             sla_spurious <= 1'b1;
    else if(sla_acknowledge || sla_irq)     sla_spurious <= 1'b0;
end

//------------------------------------------------------------------------------

wire mas_init_icw1 = ms_write && ms_address == 1'b0 && ms_writedata[4] == 1'b1;
wire mas_init_icw2 = ms_write && ms_address == 1'b1 && mas_in_init && mas_init_byte_expected == 3'd2;
wire mas_init_icw3 = ms_write && ms_address == 1'b1 && mas_in_init && mas_init_byte_expected == 3'd3;
wire mas_init_icw4 = ms_write && ms_address == 1'b1 && mas_in_init && mas_init_byte_expected == 3'd4;

wire mas_ocw1 = mas_in_init == 1'b0 && ms_write && ms_address == 1'b1;
wire mas_ocw2 = ms_write && ms_address == 1'b0 && ms_writedata[4:3] == 2'b00;
wire mas_ocw3 = ms_write && ms_address == 1'b0 && ms_writedata[4:3] == 2'b01;

always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0)                           mas_polled <= 1'b0;
    else if(mas_polled && ms_read_valid)    mas_polled <= 1'b0;
    else if(mas_ocw3)                           mas_polled <= ms_writedata[2];
end

always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0)                                                       mas_read_reg_select <= 1'b0;
    else if(mas_init_icw1)                                                  mas_read_reg_select <= 1'b0;
    else if(mas_ocw3 && ms_writedata[2] == 1'b0 && ms_writedata[1]) mas_read_reg_select <= ms_writedata[0];
end

always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0)                                                       mas_special_mask <= 1'd0;
    else if(mas_init_icw1)                                                  mas_special_mask <= 1'd0;
    else if(mas_ocw3 && ms_writedata[2] == 1'b0 && ms_writedata[6]) mas_special_mask <= ms_writedata[5];
end

always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0)                                   mas_in_init <= 1'b0;
    else if(mas_init_icw1)                              mas_in_init <= 1'b1;
    else if(mas_init_icw3 && ~(mas_init_requires_4))    mas_in_init <= 1'b0;
    else if(mas_init_icw4)                              mas_in_init <= 1'b0;
end

always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0)       mas_init_requires_4 <= 1'b0;
    else if(mas_init_icw1) mas_init_requires_4 <= ms_writedata[0];
end

always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0)      	mas_ltim <= 1'b0;
    else if(mas_init_icw1) 	mas_ltim <= ms_writedata[3];
end

always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0)                               mas_init_byte_expected <= 3'd0;
    else if(mas_init_icw1)                          mas_init_byte_expected <= 3'd2;
    else if(mas_init_icw2)                          mas_init_byte_expected <= 3'd3;
    else if(mas_init_icw3 && mas_init_requires_4)   mas_init_byte_expected <= 3'd4;
end

always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0)                                                               mas_lowest_priority <= 3'd7;
    else if(mas_init_icw1)                                                          mas_lowest_priority <= 3'd7;
    else if(mas_ocw2 && ms_writedata == 8'hA0)                                  mas_lowest_priority <= mas_lowest_priority + 3'd1;  //rotate on non-specific EOI
    else if(mas_ocw2 && { ms_writedata[7:3], 3'b000 } == 8'hC0)                 mas_lowest_priority <= ms_writedata[2:0];       //set priority
    else if(mas_ocw2 && { ms_writedata[7:3], 3'b000 } == 8'hE0)                 mas_lowest_priority <= ms_writedata[2:0];       //rotate on specific EOI
    else if(mas_acknowledge_not_spurious && mas_auto_eoi && mas_rotate_on_aeoi)     mas_lowest_priority <= mas_lowest_priority + 3'd1;  //rotate on AEOI
end

always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0)           mas_imr <= 8'hFF;
    else if(mas_init_icw1)      mas_imr <= 8'h00;
    else if(mas_ocw1)           mas_imr <= ms_writedata;
end

wire [7:0] mas_inter_input = { inter_input[7:3], sla_current_irq, inter_input[1:0] };

wire [7:0] mas_edge_detect = {
    inter_input[7] == 1'b1    && inter_last[7] == 1'b0,
    inter_input[6] == 1'b1    && inter_last[6] == 1'b0,
    inter_input[5] == 1'b1    && inter_last[5] == 1'b0,
    inter_input[4] == 1'b1    && inter_last[4] == 1'b0,
    inter_input[3] == 1'b1    && inter_last[3] == 1'b0,
    sla_current_irq == 1'b1       && sla_current_irq_last == 1'b0,
    inter_input[1] == 1'b1    && inter_last[1] == 1'b0,
    inter_input[0] == 1'b1    && inter_last[0] == 1'b0
};

always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0)                       mas_irr <= 8'h00;
    else if(mas_init_icw1)                  mas_irr <= 8'h00;
    else if(mas_acknowledge_not_spurious)   mas_irr <= (mas_irr & mas_inter_input & ~(mas_inter_vector_bits)) | ((~(mas_ltim))? mas_edge_detect : mas_inter_input);
    else                                    mas_irr <= (mas_irr & mas_inter_input)                                | ((~(mas_ltim))? mas_edge_detect : mas_inter_input);
end

wire [7:0] mas_writedata_mask =
    (ms_writedata[2:0] == 3'd0)?    8'b00000001 :
    (ms_writedata[2:0] == 3'd1)?    8'b00000010 :
    (ms_writedata[2:0] == 3'd2)?    8'b00000100 :
    (ms_writedata[2:0] == 3'd3)?    8'b00001000 :
    (ms_writedata[2:0] == 3'd4)?    8'b00010000 :
    (ms_writedata[2:0] == 3'd5)?    8'b00100000 :
    (ms_writedata[2:0] == 3'd6)?    8'b01000000 :
                                        8'b10000000;

wire mas_isr_clear = 
    (mas_polled && ms_read_valid) || //polling
    (mas_ocw2 && (ms_writedata == 8'h20 || ms_writedata == 8'hA0)); //non-specific EOI or rotate on non-specific EOF
                                        
always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0)                                                   mas_isr <= 8'h00;
    else if(mas_init_icw1)                                              mas_isr <= 8'h00;
    else if(mas_ocw2 && { ms_writedata[7:3], 3'b000 } == 8'h60)     mas_isr <= mas_isr & ~(mas_writedata_mask);                     //clear on specific EOI
    else if(mas_ocw2 && { ms_writedata[7:3], 3'b000 } == 8'hE0)     mas_isr <= mas_isr & ~(mas_writedata_mask);                     //clear on rotate on specific EOI
    else if(mas_isr_clear)                                              mas_isr <= mas_isr & ~(mas_selected_shifted_isr_first_bits);    //clear on polling or non-specific EOI (with or without rotate)
    else if(mas_acknowledge_not_spurious && ~(mas_auto_eoi))            mas_isr <= mas_isr | mas_inter_vector_bits;                 //set
end

always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0)       mas_inter_offset <= 5'd1;
    else if(mas_init_icw2)  mas_inter_offset <= ms_writedata[7:3];
end

always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0)       mas_auto_eoi <= 1'b0;
    else if(mas_init_icw1)  mas_auto_eoi <= 1'b0;
    else if(mas_init_icw4)  mas_auto_eoi <= ms_writedata[1];
end

always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0)                                   mas_rotate_on_aeoi <= 1'b0;
    else if(mas_init_icw1)                              mas_rotate_on_aeoi <= 1'b0;
    else if(mas_ocw2 && ms_writedata[6:0] == 7'd0)  mas_rotate_on_aeoi <= ms_writedata[7];
end

wire [7:0] mas_selected_prepare = mas_irr & ~(mas_imr) & ~(mas_isr);

wire [7:0] mas_selected_shifted =
    (mas_lowest_priority == 3'd7)?      mas_selected_prepare :
    (mas_lowest_priority == 3'd0)?      { mas_selected_prepare[0],   mas_selected_prepare[7:1] } :
    (mas_lowest_priority == 3'd1)?      { mas_selected_prepare[1:0], mas_selected_prepare[7:2] } :
    (mas_lowest_priority == 3'd2)?      { mas_selected_prepare[2:0], mas_selected_prepare[7:3] } :
    (mas_lowest_priority == 3'd3)?      { mas_selected_prepare[3:0], mas_selected_prepare[7:4] } :
    (mas_lowest_priority == 3'd4)?      { mas_selected_prepare[4:0], mas_selected_prepare[7:5] } :
    (mas_lowest_priority == 3'd5)?      { mas_selected_prepare[5:0], mas_selected_prepare[7:6] } :
                                        { mas_selected_prepare[6:0], mas_selected_prepare[7] };
    
wire [7:0] mas_selected_shifted_isr =
    (mas_lowest_priority == 3'd7)?      mas_isr :
    (mas_lowest_priority == 3'd0)?      { mas_isr[0],   mas_isr[7:1] } :
    (mas_lowest_priority == 3'd1)?      { mas_isr[1:0], mas_isr[7:2] } :
    (mas_lowest_priority == 3'd2)?      { mas_isr[2:0], mas_isr[7:3] } :
    (mas_lowest_priority == 3'd3)?      { mas_isr[3:0], mas_isr[7:4] } :
    (mas_lowest_priority == 3'd4)?      { mas_isr[4:0], mas_isr[7:5] } :
    (mas_lowest_priority == 3'd5)?      { mas_isr[5:0], mas_isr[7:6] } :
                                        { mas_isr[6:0], mas_isr[7] };

wire [2:0] mas_selected_shifted_isr_first =
    (mas_selected_shifted_isr[0])?  3'd0 :
    (mas_selected_shifted_isr[1])?  3'd1 :
    (mas_selected_shifted_isr[2])?  3'd2 :
    (mas_selected_shifted_isr[3])?  3'd3 :
    (mas_selected_shifted_isr[4])?  3'd4 :
    (mas_selected_shifted_isr[5])?  3'd5 :
    (mas_selected_shifted_isr[6])?  3'd6 :
                                    3'd7;
    
wire [2:0] mas_selected_shifted_isr_first_norm = mas_lowest_priority + mas_selected_shifted_isr_first + 3'd1;

assign mas_selected_shifted_isr_first_bits =
    (mas_selected_shifted_isr_first_norm == 3'd0)?  8'b00000001 :
    (mas_selected_shifted_isr_first_norm == 3'd1)?  8'b00000010 :
    (mas_selected_shifted_isr_first_norm == 3'd2)?  8'b00000100 :
    (mas_selected_shifted_isr_first_norm == 3'd3)?  8'b00001000 :
    (mas_selected_shifted_isr_first_norm == 3'd4)?  8'b00010000 :
    (mas_selected_shifted_isr_first_norm == 3'd5)?  8'b00100000 :
    (mas_selected_shifted_isr_first_norm == 3'd6)?  8'b01000000 :
                                                    8'b10000000;

wire [2:0] mas_selected_index =
    (mas_selected_shifted[0])?      3'd0 :
    (mas_selected_shifted[1])?      3'd1 :
    (mas_selected_shifted[2])?      3'd2 :
    (mas_selected_shifted[3])?      3'd3 :
    (mas_selected_shifted[4])?      3'd4 :
    (mas_selected_shifted[5])?      3'd5 :
    (mas_selected_shifted[6])?      3'd6 :
                                    3'd7;

wire mas_irq = mas_selected_prepare != 8'd0 && (mas_special_mask || mas_selected_index < mas_selected_shifted_isr_first);

wire [2:0] mas_irq_value = (mas_irq|inter_done)? mas_lowest_priority + mas_selected_index + 3'd1 : 3'd7;

always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0)           mas_current_irq <= 1'b0;
    else if(mas_init_icw1)      mas_current_irq <= 1'b0;
    else if(mas_acknowledge)    mas_current_irq <= 1'b0;
    else if(mas_irq)            mas_current_irq <= 1'b1;
end

assign mas_acknowledge_not_spurious = (mas_polled && ms_read_valid) || (inter_done && ~(mas_spurious));
assign mas_acknowledge              = (mas_polled && ms_read_valid) || inter_done;

wire mas_spurious_start = mas_current_irq && ~(inter_done) && ~(mas_irq);

always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0)                       mas_spurious <= 1'd0;
    else if(mas_init_icw1)                  mas_spurious <= 1'b0;
    else if(mas_spurious_start)             mas_spurious <= 1'b1;
    else if(mas_acknowledge || mas_irq)     mas_spurious <= 1'b0;
end

always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0)                                               mas_sla_active <= 1'b0;
    else if(mas_init_icw1)                                          mas_sla_active <= 1'b0;
    else if(mas_acknowledge)                                        mas_sla_active <= 1'b0;
    else if((mas_irq || mas_current_irq) && mas_irq_value != 3'd2)  mas_sla_active <= 1'b0;
    else if((mas_irq || mas_current_irq) && mas_irq_value == 3'd2)  mas_sla_active <= 1'b1;
end

//------------------------------------------------------------------------------

assign mas_inter_vector_bits = (mas_sla_active)? 8'b00000100 : inter_vector_bits;

assign     inter_vector_bits =
    (inter_vector[2:0] == 3'd0)?    8'b00000001 :
    (inter_vector[2:0] == 3'd1)?    8'b00000010 :
    (inter_vector[2:0] == 3'd2)?    8'b00000100 :
    (inter_vector[2:0] == 3'd3)?    8'b00001000 :
    (inter_vector[2:0] == 3'd4)?    8'b00010000 :
    (inter_vector[2:0] == 3'd5)?    8'b00100000 :
    (inter_vector[2:0] == 3'd6)?    8'b01000000 :
                                        8'b10000000;

//------------------------------------------------------------------------------
    
// synthesis translate_off
wire _unused_ok = &{ 1'b0, inter_last[15:1], sla_selected_shifted[7],
                           sla_selected_shifted_isr[7], mas_inter_input[0],
                           mas_selected_shifted[7], mas_selected_shifted_isr[7], 1'b0 };
// synthesis translate_on

//------------------------------------------------------------------------------

always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0)           inter_do <= 1'b0;
    else if(mas_init_icw1)      inter_do <= 1'b0;
    else if(mas_acknowledge)    inter_do <= 1'b0;
    else if(mas_irq)            inter_do <= 1'b1;
end

always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0)                                               inter_vector <= 8'd0;
    else if(mas_init_icw1)                                          inter_vector <= 8'd0;
    else if((mas_irq || mas_current_irq) && mas_irq_value != 3'd2)  inter_vector <= { mas_inter_offset, mas_irq_value };
    else if((mas_irq || mas_current_irq) && mas_irq_value == 3'd2)  inter_vector <= { sla_inter_offset, sla_irq_value };
end

//------------------------------------------------------------------------------

wire [7:0] sla_readdata_prepared =
    (sla_polled)?                                               { sla_current_irq, 4'd0, sla_irq_value } :
    (sl_address == 1'b0 && sla_read_reg_select == 1'b0)?     sla_irr :
    (sl_address == 1'b0 && sla_read_reg_select == 1'b1)?     sla_isr :
                                                                sla_imr;

always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0)   sl_readdata <= 8'd0;
    else                sl_readdata <= sla_readdata_prepared;
end

wire [7:0] mas_readdata_prepared =
    (mas_polled)?                                               { mas_current_irq, 4'd0, mas_irq_value } :
    (ms_address == 1'b0 && mas_read_reg_select == 1'b0)?    mas_irr :
    (ms_address == 1'b0 && mas_read_reg_select == 1'b1)?    mas_isr :
                                                                mas_imr;

always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0)   ms_readdata <= 8'd0;
    else                ms_readdata <= mas_readdata_prepared;
end

//------------------------------------------------------------------------------

endmodule
