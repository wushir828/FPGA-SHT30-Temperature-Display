module calculate(
		input				rst_n,		//复位信号
		input	[15:0]	T_code,		//温度码值
		input	[15:0]	H_code,		//湿度码值
		
		output	[15:0]	T_data,		//温度BCD码
		output	[15:0]	H_data,		//湿度BCD码
		output	[7:0]		dat_en,		//数字显示使能
		output	[7:0]		dot_en		//小数点显示使能
	);

/////////////////////////////////////温度运算/////////////////////////////////////////

// 温度 T = -45 + 175 * T_code / (2^16-1) = (-45 + 175 * T_code / 2^16) 
wire [31:0] a = T_code * 16'd17500;
wire [31:0] b = a >> 16; //除以2^16取商
wire [31:0] c = (b>=32'd4500)? (b - 32'd4500):(32'd4500 - b); //温度有正负，取绝对值
wire [15:0] T_data_bin = c[15:0];

//进行BCD转码处理
//小数点在BCD码基础上左移2位，完成除以100的操作
//T_data_bcd[19:16]百位,[15:12]十位,[11:8]个位,[7:0]两个小数位
wire [19:0] T_data_bcd;
bin_to_bcd u1
(
.rst_n				(rst_n		),	//系统复位，低有效
.bin_code			(T_data_bin	),	//需要进行BCD转码的二进制数据
.bcd_code			(T_data_bcd	)	//转码后的BCD码型数据输出
);

//要显示的数据,保留1位小数
//若温度为负，将T_data_bcd[19:16]百位数据用数字A替换，同时把数码管A的字库显示负号
assign T_data = (b>=32'd4500)? T_data_bcd[19:4]:{4'ha,T_data_bcd[15:4]};

//数据显示使能，高位消零
assign dat_en[7] = |T_data[15:12]; //自或
assign dat_en[6] = (b>=32'd4500)?(|T_data[15:8]):(|T_data[11:8]);
assign dat_en[5:4] = 2'b11;

//小数点显示使能
assign dot_en[7:4] = 4'b0010;

/////////////////////////////////////湿度运算/////////////////////////////////////////

// 湿度 TH = 100 * H_code / 2^16 = (100 * H_code / 2^16) 
wire [31:0] d = H_code * 16'd1000;
wire [31:0] e = d >> 16; //除以2^16取商
wire [15:0] H_data_bin = e[15:0];

//进行BCD转码处理
//小数点在BCD码基础上左移1位，完成除以10的操作
//H_data_bcd[19:16]千位,[15:12]百位,[11:8]十位,[7:4]个位,[3:0]小数位
wire [19:0] H_data_bcd;
bin_to_bcd u2
(
.rst_n				(rst_n		),	//系统复位，低有效
.bin_code			(H_data_bin	),	//需要进行BCD转码的二进制数据
.bcd_code			(H_data_bcd	)	//转码后的BCD码型数据输出
);

//要显示的数据,保留1位小数
assign H_data = H_data_bcd[15:0];

//数据显示使能
assign dat_en[3] = |H_data[15:12]; //自或
assign dat_en[2] = |H_data[15:8];
assign dat_en[1:0] = 2'b11;

//小数点显示使能
assign dot_en[3:0] = 4'b0010;

endmodule
