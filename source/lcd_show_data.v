module lcd_show_data (
    input                   sys_clk             ,
    input                   sys_rst_n           ,
    input                   wr_done             ,
    input                   show_pic_flag       ,

    input   [63:0]          rom_q               ,
    output  reg     [8:0]   rom_addr            ,

    input           [8:0]   addr_start          ,
    input           [15:0]  window_x0           ,
    input           [5:0]   char_length         ,
    input           [7:0]   the_char            ,
    input           [5:0]   x_size              ,
    output  reg             select              ,

    output  wire    [8:0]   show_pic_data       ,
    output  wire            show_pic_done       ,
    output  wire            en_write_show_pic   
);
//color
parameter   WHITE   = 16'hFFFF,
            BLACK   = 16'h0000,	  
            BLUE    = 16'h001F,  
            BRED    = 16'hF81F,
            GRED 	  = 16'hFFE0,
            GBLUE	  = 16'h07FF,
            RED     = 16'hF800,
            MAGENTA = 16'hF81F,
            GREEN   = 16'h07E0,
            CYAN    = 16'h7FFF,
            YELLOW  = 16'hFFE0,
            BROWN   = 16'hBC40, //棕色
            BRRED   = 16'hFC07, //棕红色
            GRAY    = 16'h8430; //灰色

//state machine
parameter   STATE0 = 5'b00_001;
parameter   STATE1 = 5'b00_010;  //generate the window
parameter   STATE2 = 5'b00_100;  //set the window 
parameter   STATE3 = 5'b01_000;
parameter   DONE   = 5'b10_000;

//
parameter   X_SIZE = 16'd31;
parameter   Y_SIZE = 16'd64;

//state machine 
reg     [4:0]   state;

//window x,y,x+size,y+size
// reg     [15:0]  window_x0;//x
wire     [15:0]  window_x1;//x+size
reg     [15:0]  window_y0 = 16'h64;//y
reg     [15:0]  window_y1 = 16'ha4;//y+size

//set show window
reg             the1_wr_done;
reg     [3:0]   cnt_set_windows;

//STATE2 finish flag
wire             state2_finish_flag;

//cnt_rom_prepare
reg     [3:0]   cnt_rom_prepare;

//char length cnt
reg     [5:0]   cnt_length_num;

reg     [239:0]  temp;

reg             length_num_flag;
reg     [9:0]   cnt_wr_color_data;
reg     [8:0]   data;

reg             state1_finish_flag;

//state machine
always@(posedge sys_clk or negedge sys_rst_n)
    if(!sys_rst_n)
        state <= STATE0;
    else
        case(state)
            STATE0 : state <= (show_pic_flag) ? STATE1 : STATE0;
            STATE1 : state <= (state1_finish_flag)?STATE2:STATE1;
            STATE2 : state <= (state2_finish_flag) ? DONE : STATE2;
            DONE   : state <= STATE1;
            default : state <= STATE1;
        endcase

assign     window_x1 = window_x0 + x_size;

//spi send 8 bits data finish
always@(posedge sys_clk or negedge sys_rst_n)
    if(!sys_rst_n) 
        the1_wr_done <= 1'b0;
    else if(wr_done)
        the1_wr_done <= 1'b1;
    else
        the1_wr_done <= 1'b0;

//set lcd show window
always@(posedge sys_clk or negedge sys_rst_n)
begin
    if(!sys_rst_n)	begin
        cnt_set_windows <= 'd0;
    end
    else if(state == STATE1 && the1_wr_done)	begin
        cnt_set_windows <= cnt_set_windows + 1'b1;
    end
    else if(state == DONE)  begin
        cnt_set_windows <= 'd0;
    end
    else 
        cnt_set_windows <= cnt_set_windows;
end

always@(posedge sys_clk or negedge sys_rst_n)
begin
    if(!sys_rst_n)	begin
        state1_finish_flag <= 1'b0;
    end
    else if(cnt_set_windows == 'd10 && the1_wr_done)	begin
        state1_finish_flag <= 1'b1;
    end
    else 
        state1_finish_flag <= 1'b0;
end

//wait read data from rom
always@(posedge sys_clk or negedge sys_rst_n)
begin
    if(!sys_rst_n)	begin
        cnt_rom_prepare <= 'd0;
    end
    else if(length_num_flag)	begin
        cnt_rom_prepare <= 'd0;
    end
    else if (state == STATE2 && cnt_rom_prepare <'d8) begin
        cnt_rom_prepare <= cnt_rom_prepare + 1'b1;
    end
    else 
        cnt_rom_prepare <= cnt_rom_prepare;
end

//generate rom addr 
always@(posedge sys_clk or negedge sys_rst_n)
begin
    if(!sys_rst_n)	begin
        rom_addr <= 'd0;
    end
    else if(cnt_rom_prepare == 'd1 && cnt_length_num < x_size)	begin
        rom_addr <= cnt_length_num + addr_start;
    end
    else if(cnt_rom_prepare == 'd5 && cnt_length_num < x_size)begin
        rom_addr <= cnt_length_num + addr_start;
    end
    else 
        rom_addr <= rom_addr;
end

//cnt length
always@(posedge sys_clk or negedge sys_rst_n)
begin
    if(!sys_rst_n)	begin
       cnt_length_num <= 'd0; 
    end
    else if (state == STATE1) begin
        cnt_length_num <= 'd0;
    end
    else if(length_num_flag && state == STATE2)	begin
        cnt_length_num <= cnt_length_num + 1'b1;
    end
    else begin
        cnt_length_num <= cnt_length_num;
    end
end

//select T or H
always@(posedge sys_clk or negedge sys_rst_n)
begin
    if(!sys_rst_n)	begin
        select <= 1'b1;
    end
    else if (cnt_rom_prepare == 'd0) begin
        select <= 1'b1;
    end
    else if (cnt_rom_prepare == 'd4) begin
        select <= 1'b0;
    end
    else 
        select <= select;
end

//temp
always@(posedge sys_clk or negedge sys_rst_n)
    if(!sys_rst_n)
        temp <= 'd0;
    else if(cnt_rom_prepare == 'd3)
        temp <= {rom_q,20'b0};
    else if(cnt_rom_prepare == 'd7)
        temp <= {rom_q,20'd0,temp[99:0]};
    else if(state == STATE2 && the1_wr_done)     
			begin
				if(cnt_wr_color_data[0] == 1)
					temp <= temp >>1;
				else
					temp <= temp;
			end

//finish the 64 bits data;
always@(posedge sys_clk or negedge sys_rst_n)
    if(!sys_rst_n)
        length_num_flag <= 1'b0;
   else if(
            state == STATE2 && 
            cnt_wr_color_data == 'd479 &&
            the1_wr_done
           )
       length_num_flag <= 1'b1;
    else
       length_num_flag <= 1'b0;

//color generate cnt
always@(posedge sys_clk or negedge sys_rst_n)
    if(!sys_rst_n)
        cnt_wr_color_data <= 'd0;
    else if(cnt_rom_prepare == 'd7 || state == DONE)
        cnt_wr_color_data <= 'd0;
    else if(state == STATE2 && the1_wr_done)
        cnt_wr_color_data <= cnt_wr_color_data + 1'b1;

//the main 
//send commmend and data
always@(posedge sys_clk or negedge sys_rst_n)
    if(!sys_rst_n)
        data <= 9'h000;
    else if(state == STATE1)
        case(cnt_set_windows)
            0 : data <= 9'h02A;
            1 : data <= {1'b1,8'h00};//start coordinates
            2 : data <= {1'b1,8'h00};
            3 : data <= {1'b1,8'h00};//end coordinates
            4 : data <= {1'b1,8'hef};
            5 : data <= 9'h02B;
            6 : data <= {1'b1,window_x0[15:8]};
            7 : data <= {1'b1,window_x0[7:0]};
            8 : data <= {1'b1,window_x1[15:8]};
            9 : data <= {1'b1,window_x1[7:0]};
            10: data <= 9'h02C;
            default: data <= 9'h000;
        endcase
    else if(state == STATE2 && ((temp & 8'h01) == 'd0))
        if(cnt_wr_color_data[0] == 1'b0 )
            data <= {1'b1,WHITE[15:8]};
        else
            data <= {1'b1,WHITE[7:0]};
    else if(state == STATE2 && ((temp & 8'h01) == 'd1))
        if(cnt_wr_color_data[0] == 1'b0 )
            data <= {1'b1,BROWN[15:8]};
        else
            data <= {1'b1,BROWN[7:0]};
    else
        data <= data;   

assign state2_finish_flag = ((cnt_length_num == x_size) && length_num_flag)?1'b1 : 1'b0;

assign en_write_show_pic = (state == STATE1 || cnt_rom_prepare == 'd8) ? 1'b1 : 1'b0;
assign show_pic_done = (state == DONE) ? 1'b1 : 1'b0;

assign show_pic_data = data;  


endmodule