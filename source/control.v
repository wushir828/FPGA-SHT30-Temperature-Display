
module  control
(
    input   wire             sys_clk_50MHz       ,   
    input   wire             sys_rst_n           ,
    input   wire     [8:0]   init_data           ,
    input   wire             en_write_init       ,
    input   wire             init_done           ,
    input   wire     [8:0]   show_pic_data      ,
    input   wire             en_write_show_pic  ,
	input   wire				  show_pic_done,
    
	output  reg             show_pic_flag      ,
	 
    output  reg      [8:0]   data                ,
    output  reg              en_write      
);

reg     [1:0]   cnt1;

always@(posedge sys_clk_50MHz or negedge sys_rst_n)
    if(!sys_rst_n)
        data <= 'd0;
    else if(init_done == 1'b0)
        data <= init_data;
    else if(init_done == 1'b1)
        data <= show_pic_data;
    else
        data <= data;

always@(posedge sys_clk_50MHz or negedge sys_rst_n)
    if(!sys_rst_n)
        en_write <= 'd0;
    else if(init_done == 1'b0)
        en_write <= en_write_init ;
    else if(init_done == 1'b1)
        en_write <= en_write_show_pic;
    else
        en_write <= en_write;

always@(posedge sys_clk_50MHz or negedge sys_rst_n)
    if(!sys_rst_n)
        cnt1 <= 'd0;
    else if(show_pic_flag)
        cnt1 <= 'd0;
    else if(init_done && cnt1 < 'd3)
        cnt1 <= cnt1 + 1'b1;
    else
        cnt1 <= cnt1;
        
always@(posedge sys_clk_50MHz or negedge sys_rst_n)
    if(!sys_rst_n)
        show_pic_flag <= 1'b0;
    else if(cnt1 == 'd2)
        show_pic_flag <= 1'b1;
    else
        show_pic_flag <= 1'b0;        
endmodule