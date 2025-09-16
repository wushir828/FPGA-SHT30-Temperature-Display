module char_select (
    input               clk             ,
    input               rst_n           ,
    input               next_char_flag  ,
    input       [15:0]  T_data          ,
    input       [15:0]  H_data          ,
    input               select          ,

    output reg [8:0]    addr_start      ,
    output reg [15:0]   window_x0       ,
    output reg [5:0]    char_length     ,
    output reg [5:0]    x_size          ,
    output reg [6:0]    the_char
);
    
//the_char
parameter   FIRST   = 7'b0000_001;
parameter   COLON   = 7'b0000_010;
parameter   BAI     = 7'b0000_100;
parameter   SHI     = 7'b0001_000;
parameter   GE      = 7'b0010_000;
parameter   DOT     = 7'b0100_000;
parameter   XIAOSHU = 7'b1000_000;

reg     [15:0]      T_data_r;
reg     [15:0]      H_data_r;
reg                 fuhao;

always@(posedge clk)begin
    if(next_char_flag) begin
        if(T_data[15:12] == 4'ha)
            fuhao <= 1'b1;
        else 
            fuhao <= 1'b0;
    end
    else 
        fuhao <= fuhao;
end

always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)	begin
        T_data_r <= 16'd0;
        H_data_r <= 16'd0;
    end
    else if(next_char_flag && (the_char == XIAOSHU))	begin
        T_data_r <= T_data;
        H_data_r <= H_data;
    end
    else begin
        T_data_r <= T_data_r;
        H_data_r <= H_data_r;
    end
end

//the_char decide which char to display
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)	begin
        the_char <= FIRST;
    end
    else if(next_char_flag)	begin
        case (the_char)
            FIRST    :begin
                the_char <= COLON;
            end 
            COLON   :begin
                the_char <= BAI;
            end 
            BAI     :begin
                the_char <= SHI;
            end 
            SHI     :begin
                the_char <= GE;
            end 
            GE      :begin
                the_char <= DOT;
            end 
            DOT     :begin
                the_char <= XIAOSHU;
            end 
            XIAOSHU :begin
                the_char <= (fuhao)?BAI:SHI;
            end
            default: the_char <= FIRST;
        endcase
    end
    else 
        the_char <= the_char;
end

// rom address begin
always@(*)
begin
    case (the_char)
        FIRST   : addr_start <= (select)?9'd352:9'd320;
        COLON   : addr_start <= 'd430;

        DOT     : addr_start <= 'd418;
        BAI     : addr_start <= (select)?((!fuhao)?9'd480:9'd448):9'd441;

        SHI     : addr_start <= (select)?({T_data_r[11:8],5'b00000}):({H_data_r[11:8],5'b00000});
        GE      : addr_start <= (select)?({T_data_r[7:4],5'b00000}):({H_data_r[7:4],5'b00000});
        XIAOSHU : addr_start <= (select)?({T_data_r[3:0],5'b00000}):({H_data_r[3:0],5'b00000});
        default: addr_start <= 'd0;
    endcase
end

//generate the window depend on the_char
always@(*)
begin
    case (the_char)
        FIRST   :begin
            window_x0 <= 16'd20;
        end
        COLON   :begin
            window_x0 <= 16'd60;
        end
        BAI     :begin
            window_x0 <= 16'd90;
        end
        SHI     :begin
            window_x0 <= (fuhao)?16'd130:16'd90;
        end
        GE      :begin
            window_x0 <= (fuhao)?16'd170:16'd130;
        end
        DOT     :begin
            window_x0 <= (fuhao)?16'd210:16'd170;
        end
        XIAOSHU :begin
            window_x0 <= (fuhao)?16'd230:16'd190;
        end
        default: begin
            window_x0 <= 16'd0;
        end
    endcase
end

always@(*)
begin
    case (the_char)
        FIRST   : char_length <= 6'd32;
        COLON   : char_length <= 6'd32;
        BAI     : char_length <= 6'd32;
        SHI     : char_length <= 6'd32;
        GE      : char_length <= 6'd32;
        DOT     : char_length <= 6'd32;
        XIAOSHU : char_length <= 6'd32;
        default: char_length <= 6'd32;
    endcase
end

always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)	begin
        x_size <= 6'd31;
    end
    else if(the_char == COLON || the_char == DOT)	begin
        x_size <= 6'd12;
    end
    else begin
        x_size <= 6'd31;
    end
end

endmodule