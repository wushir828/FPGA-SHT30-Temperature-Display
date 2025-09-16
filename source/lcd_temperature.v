module  lcd_temperature
(
    input           	clk			,
    input           	rst_n		   ,
    
    inout           i2c_sda         ,
    output          i2c_scl         ,

    output          	lcd_rst     ,
	output				lcd_blk		,
    output          	lcd_dc      ,
    output          	lcd_sclk    ,
    output          	lcd_mosi    ,
    output          	lcd_cs      
);

wire    [8:0]   data;   
wire            en_write;
wire            wr_done; 

wire    [8:0]   init_data;
wire            en_write_init;
wire            init_done;

wire            show_pic_flag     ;

wire    [8:0]   show_pic_data     ;
wire            en_write_show_pic  ;

wire     [8:0]  rom_addr;
wire    [63:0]   rom_q;
wire				 clk_50MHz;


assign			lcd_blk = 1'b1;


pll pll_u1(
 
		.inclk0		(clk			), 
		.c0			(clk_50MHz	)
	);

lcd_write  lcd_write_inst
(
    .sys_clk_50MHz(clk_50MHz	  ),
    .sys_rst_n    (rst_n  		  ),
    .data         (data         ),
    .en_write     (en_write     ),
                                
    .wr_done      (wr_done      ),
    .cs           (lcd_cs       ),
    .dc           (lcd_dc       ),
    .sclk         (lcd_sclk     ),
    .mosi         (lcd_mosi     )
);

control  control_inst
(
    .sys_clk_50MHz          (clk_50MHz 	       ), 
    .sys_rst_n              (rst_n		          ),
    .init_data              (init_data           ),
    .en_write_init          (en_write_init       ),
    .init_done              (init_done           ),
    .show_pic_data         (show_pic_data      ),
    .en_write_show_pic     (en_write_show_pic  ),

	 .show_pic_flag	      (show_pic_flag     ),
    .data                   (data                ),
    .en_write               (en_write            )
);

lcd_init  lcd_init_inst
(
    .sys_clk_50MHz(clk_50MHz		),
    .sys_rst_n    (rst_n	     ),
    .wr_done      (wr_done      ),

    .lcd_rst      (lcd_rst      ),
    .init_data    (init_data    ),
    .en_write     (en_write_init),
    .init_done    (init_done    )
);

wire  [8:0]     addr_start;
wire  [15:0]    window_x0;
wire  [7:0]     the_char;
wire [5:0] char_length;
wire            show_pic_done;

wire    [5:0]   x_size_w;
wire    [15:0]  T_data_w;
wire    [15:0]  H_data_w;
wire            select_w;

char_select u_char_select(
    .clk                (clk                ),
    .rst_n              (rst_n              ),
    .next_char_flag     (show_pic_done      ),
    .T_data             (T_data_w           ),
    .H_data             (H_data_w           ),
    .select             (select_w           ),
    .addr_start         (addr_start         ),
    .window_x0          (window_x0          ),
    .char_length        (char_length        ),
    .x_size             (x_size_w           ),
    .the_char           (the_char           )
);

lcd_show_data u_lcd_show_data(
    .sys_clk             (clk_50MHz         ),
    .sys_rst_n           (rst_n             ),
    .wr_done             (wr_done           ),
    .show_pic_flag       (show_pic_flag     ),
    .rom_q               (rom_q             ),
    .rom_addr            (rom_addr          ),

    .show_pic_data       (show_pic_data     ),
    .show_pic_done       (show_pic_done     ),
    .en_write_show_pic   (en_write_show_pic ),

    .addr_start         (addr_start ),
    .window_x0          (window_x0  ),
    .x_size             (x_size_w   ),
    .select             (select_w   ),
    .char_length        (char_length)
);

pixel_rom   u_pixel_rom(
.address            (rom_addr           ),
.q                  (rom_q              )
);

    wire    [15:0]  T_code_w;
    
    wire    [15:0]  H_code_w;
    wire    [7:0]   dat_en_w;
    wire    [7:0]   dot_en_w;


sht30_driver u_sht30_driver(
.clk            (clk        ),
.rst_n          (rst_n      ),
.i2c_scl        (i2c_scl    ),
.i2c_sda        (i2c_sda    ),
.T_code         (T_code_w   ),
.H_code         (H_code_w   )
);

calculate   u_calculate(
.rst_n           (rst_n      ),
.T_code          (T_code_w   ),
.H_code          (H_code_w   ),
.T_data          (T_data_w   ),
.H_data          (H_data_w   ),
.dat_en          (dat_en_w   ),
.dot_en          (dot_en_w   )
);

endmodule
