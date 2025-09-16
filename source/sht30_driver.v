module sht30_driver(
		input				clk,		//系统时钟
		input				rst_n,	//系统复位，低有效
		
		output			i2c_scl,	//I2C总线SCL
		inout				i2c_sda,	//I2C总线SDA
		
		output [15:0]	T_code,		//温度码值
		output [15:0]	H_code		//湿度码值
	);
	
	parameter	CNT_NUM	=	15;
	
	localparam	IDLE	=	4'd0;
	localparam	MAIN	=	4'd1;
	localparam	MODE1	=	4'd2;
	localparam	MODE2	=	4'd3;
	localparam	START	=	4'd4;
	localparam	WRITE	=	4'd5;
	localparam	READ	=	4'd6;
	localparam	STOP	=	4'd7;
	localparam	DELAY	=	4'd8;
	
	localparam	ACK		=	1'b0;
	localparam	NACK	=	1'b1;
	
	//使用计数器分频产生400KHz时钟信号clk_400khz
	reg					clk_400khz;
	reg		[9:0]		cnt_400khz;
	always@(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			cnt_400khz <= 10'd0;
			clk_400khz <= 1'b0;
		end else if(cnt_400khz >= CNT_NUM-1) begin
			cnt_400khz <= 10'd0;
			clk_400khz <= ~clk_400khz;
		end else begin
			cnt_400khz <= cnt_400khz + 1'b1;
		end
	end
	
	reg scl,sda,ack,ack_flag;
	reg [3:0] cnt, cnt_main, cnt_mode1, cnt_mode2, cnt_start, cnt_write, cnt_read, cnt_stop;
	reg [7:0] data_wr, dev_addr, reg_data, data_r;
	reg [7:0] tmdata_l,tmdata_h,tmdata_crc,hmdata_l,hmdata_h,hmdata_crc;
	reg [15:0] reg_addr;
	reg [23:0] cnt_delay, num_delay;
	reg [3:0]  state, state_back;
	
	assign T_code = {tmdata_h,tmdata_l};
	assign H_code = {hmdata_h,hmdata_l}; 

	always@(posedge clk_400khz or negedge rst_n) begin
		if(!rst_n) begin	//如果按键复位，将相关数据初始化
			scl <= 1'd1; sda <= 1'd1; ack <= ACK; ack_flag <= 1'b0; cnt <= 1'b0;
			cnt_main <= 1'b0; cnt_mode1 <= 1'b0; cnt_mode2 <= 1'b0;
			cnt_start <= 1'b0; cnt_write <= 1'b0; cnt_read <= 1'b0; cnt_stop <= 1'b0;
			cnt_delay <= 1'b0; num_delay <= 24'd48000;
			state <= IDLE; state_back <= IDLE;
		end else begin
			case(state)
				IDLE:begin	//软件自复位，主要用于程序跑飞后的处理
						scl <= 1'd1; sda <= 1'd1; ack <= ACK; ack_flag <= 1'b0; cnt <= 1'b0;
						cnt_main <= 1'b0; cnt_mode1 <= 1'b0; cnt_mode2 <= 1'b0;
						cnt_start <= 1'b0; cnt_write <= 1'b0; cnt_read <= 1'b0; cnt_stop <= 1'b0;
						cnt_delay <= 1'b0; num_delay <= 24'd48000;
						state <= MAIN; state_back <= IDLE;
					end
				MAIN:begin
						if(cnt_main >= 4'd4) cnt_main <= 4'd2;  	//写完控制指令后循环读数据
						else cnt_main <= cnt_main + 1'b1;	
						case(cnt_main)
							4'd0:	begin dev_addr <= 7'h44; reg_addr <= 16'h30a2; state <= MODE1; end	//软件复位
							4'd1:	begin num_delay <= 24'd600; state <= DELAY; end	//1.5ms延时
							
							4'd2:	begin dev_addr <= 7'h44; reg_addr <= 16'h2c06; state <= MODE1; end	//写入配置
							4'd3:	begin num_delay <= 24'd6000; state <= DELAY; end	//15ms延时
							4'd4:	begin dev_addr <= 7'h44; state <= MODE2; end	//读取配置
	//						4'd5:	begin T_code <= {tmdata_h,tmdata_l};H_code <= {hmdata_h,hmdata_l};  end	//读取数据
							
							
							default: state <= IDLE;	//如果程序失控，进入IDLE自复位状态
						endcase
					end
				MODE1:begin	//16位寄存器写操作
						if(cnt_mode1 >= 4'd5) cnt_mode1 <= 1'b0;	//对START中的子状态执行控制cnt_start
						else cnt_mode1 <= cnt_mode1 + 1'b1;
						state_back <= MODE1;
						case(cnt_mode1)
							4'd0:	begin state <= START; end	//I2C通信时序中的START
							4'd1:	begin data_wr <= dev_addr<<1; state <= WRITE; end	//设备地址
							4'd2:	begin data_wr <= reg_addr[15:8]; state <= WRITE; end	//寄存器地址
							4'd3: begin data_wr <= reg_addr[7:0]; state <= WRITE; end	//寄存器地址
							4'd4:	begin state <= STOP; end	//I2C通信时序中的STOP
							4'd5:	begin state <= MAIN; end	//返回MAIN
							default: state <= IDLE;	//如果程序失控，进入IDLE自复位状态
						endcase
					end
				MODE2:begin	//两次读操作
						if(cnt_mode2 >= 4'd15) cnt_mode2 <= 4'd0;	//对START中的子状态执行控制cnt_start
						else cnt_mode2 <= cnt_mode2 + 1'b1;
						state_back <= MODE2;
						case(cnt_mode2)
							4'd0:	begin state <= START; end	//I2C通信时序中的START
							4'd1:	begin data_wr <= (dev_addr<<1)|8'h01; state <= WRITE; end	//设备地址
							4'd2:	begin ack <= ACK; state <= READ; end	//读寄存器数据
							4'd3:	begin tmdata_h <= data_r; end
							4'd4:	begin ack <= ACK; state <= READ; end	//读寄存器数据
							4'd5:	begin tmdata_l <= data_r; end
							4'd6:	begin ack <= ACK; state <= READ; end	//读寄存器数据
							4'd7:	begin tmdata_crc <= data_r; end
							4'd8:	begin ack <= ACK; state <= READ; end	//读寄存器数据
							4'd9:	begin hmdata_h <= data_r; end
							4'd10:begin ack <= ACK; state <= READ; end	//读寄存器数据
							4'd11:begin hmdata_l <= data_r; end
							4'd12:begin ack <= NACK; state <= READ; end	//读寄存器数据
							4'd13:begin hmdata_crc <= data_r; end
							4'd14:begin state <= STOP; end	//I2C通信时序中的STOP
							4'd15:begin state <= MAIN; end	//返回MAIN
							default: state <= IDLE;	//如果程序失控，进入IDLE自复位状态
						endcase
					end
				START:begin	//I2C通信时序中的起始START
						if(cnt_start >= 3'd5) cnt_start <= 1'b0;	//对START中的子状态执行控制cnt_start
						else cnt_start <= cnt_start + 1'b1;
						case(cnt_start)
							3'd0:	begin sda <= 1'b1; scl <= 1'b1; end	//将SCL和SDA拉高，保持4.7us以上
							3'd1:	begin sda <= 1'b1; scl <= 1'b1; end	//clk_400khz每个周期2.5us，需要两个周期
							3'd2:	begin sda <= 1'b0; end	//SDA拉低到SCL拉低，保持4.0us以上
							3'd3:	begin sda <= 1'b0; end	//clk_400khz每个周期2.5us，需要两个周期
							3'd4:	begin scl <= 1'b0; end	//SCL拉低，保持4.7us以上
							3'd5:	begin scl <= 1'b0; state <= state_back; end	//clk_400khz每个周期2.5us，需要两个周期，返回MAIN
							default: state <= IDLE;	//如果程序失控，进入IDLE自复位状态
						endcase
					end
				WRITE:begin	//I2C通信时序中的写操作WRITE和相应判断操作ACK
						if(cnt <= 3'd6) begin	//共需要发送8bit的数据，这里控制循环的次数
							if(cnt_write >= 3'd3) begin cnt_write <= 1'b0; cnt <= cnt + 1'b1; end
							else begin cnt_write <= cnt_write + 1'b1; cnt <= cnt; end
						end else begin
							if(cnt_write >= 3'd7) begin cnt_write <= 1'b0; cnt <= 1'b0; end	//两个变量都恢复初值
							else begin cnt_write <= cnt_write + 1'b1; cnt <= cnt; end
						end
						case(cnt_write)
							//按照I2C的时序传输数据
							3'd0:	begin scl <= 1'b0; sda <= data_wr[7-cnt]; end	//SCL拉低，并控制SDA输出对应的位
							3'd1:	begin scl <= 1'b1; end	//SCL拉高，保持4.0us以上
							3'd2:	begin scl <= 1'b1; end	//clk_400khz每个周期2.5us，需要两个周期
							3'd3:	begin scl <= 1'b0; end	//SCL拉低，准备发送下1bit的数据
							//获取从设备的响应信号并判断
							3'd4:	begin sda <= 1'bz; end	//释放SDA线，准备接收从设备的响应信号
							3'd5:	begin scl <= 1'b1; end	//SCL拉高，保持4.0us以上
							3'd6:	begin ack_flag <= i2c_sda; end	//获取从设备的响应信号并判断
							3'd7:	begin scl <= 1'b0; if(ack_flag)state <= state; else state <= state_back; end //SCL拉低，如果不应答循环写
							default: state <= IDLE;	//如果程序失控，进入IDLE自复位状态
						endcase
					end
				READ:begin	//I2C通信时序中的读操作READ和返回ACK的操作
						if(cnt <= 3'd6) begin	//共需要接收8bit的数据，这里控制循环的次数
							if(cnt_read >= 3'd3) begin cnt_read <= 1'b0; cnt <= cnt + 1'b1; end
							else begin cnt_read <= cnt_read + 1'b1; cnt <= cnt; end
						end else begin
							if(cnt_read >= 3'd7) begin cnt_read <= 1'b0; cnt <= 1'b0; end	//两个变量都恢复初值
							else begin cnt_read <= cnt_read + 1'b1; cnt <= cnt; end
						end
						case(cnt_read)
							//按照I2C的时序接收数据
							3'd0:	begin scl <= 1'b0; sda <= 1'bz; end	//SCL拉低，释放SDA线，准备接收从设备数据
							3'd1:	begin scl <= 1'b1; end	//SCL拉高，保持4.0us以上
							3'd2:	begin data_r[7-cnt] <= i2c_sda; end	//读取从设备返回的数据
							3'd3:	begin scl <= 1'b0; end	//SCL拉低，准备接收下1bit的数据
							//向从设备发送响应信号
							3'd4:	begin sda <= ack; end	//发送响应信号，将前面接收的数据锁存
							3'd5:	begin scl <= 1'b1; end	//SCL拉高，保持4.0us以上
							3'd6:	begin scl <= 1'b1; end	//SCL拉高，保持4.0us以上
							3'd7:	begin scl <= 1'b0; state <= state_back; end	//SCL拉低，返回MAIN状态
							default: state <= IDLE;	//如果程序失控，进入IDLE自复位状态
						endcase
					end
				STOP:begin	//I2C通信时序中的结束STOP
						if(cnt_stop >= 3'd5) cnt_stop <= 1'b0;	//对STOP中的子状态执行控制cnt_stop
						else cnt_stop <= cnt_stop + 1'b1;
						case(cnt_stop)
							3'd0:	begin sda <= 1'b0; end	//SDA拉低，准备STOP
							3'd1:	begin sda <= 1'b0; end	//SDA拉低，准备STOP
							3'd2:	begin scl <= 1'b1; end	//SCL提前SDA拉高4.0us
							3'd3:	begin scl <= 1'b1; end	//SCL提前SDA拉高4.0us
							3'd4:	begin sda <= 1'b1; end	//SDA拉高
							3'd5:	begin sda <= 1'b1; state <= state_back; end	//完成STOP操作，返回MAIN状态
							default: state <= IDLE;	//如果程序失控，进入IDLE自复位状态
						endcase
					end
				DELAY:begin	//12ms延时
						if(cnt_delay >= num_delay) begin
							cnt_delay <= 1'b0;
							state <= MAIN; 
						end else cnt_delay <= cnt_delay + 1'b1;
					end
				default:;
			endcase
		end
	end
	
	assign	i2c_scl = scl;	//对SCL端口赋值
	assign	i2c_sda = sda;	//对SDA端口赋值

endmodule
