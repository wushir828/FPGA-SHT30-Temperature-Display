# FPGA-SHT30-Temperature-Display
# 基于 FPGA (MAX 10) 的 SHT30 温湿度 LCD 显示系统

![最终成果展示]<img width="385" height="513" alt="Image" src="https://github.com/user-attachments/assets/bc4c4edc-1255-4d01-8801-4f106d4916c3" />
##  项目简介

本项目是一个基于 STEP-FPGA 小脚丫 MAX 10 开发板 的数字温湿度监测与显示系统。系统通过 I²C 协议与 SHT30 传感器进行通信以采集精确的温湿度数据，经过 FPGA 内部的逻辑运算和 BCD 码转换后，最终通过 SPI 协议驱动 LCD 屏幕，实时显示当前的温度和湿度值。

这个项目完整地覆盖了从传感器数据读取、协议解析、数据处理到最终驱动外设显示的嵌入式系统开发全流程。

## 项目亮点

传感器驱动: 使用 Verilog 实现了 SHT30 温湿度传感器的 I²C 通信协议，完成了传感器初始化、数据请求和读取的完整时序逻辑。
数据处理: 包含了从传感器原始二进制码值到实际温湿度值（浮点数）的转换算法，并通过“移位加三法”实现了二进制到 BCD 码的硬件转换，便于后续在屏幕上显示十进制数字。
外设驱动: 实现了驱动 LCD 屏幕所需的 SPI 协议和控制器的初始化及数据写入逻辑，并设计了字符点阵 ROM 来显示数字和符号。
模块化设计: 整个工程采用了模块化的设计思想，将 I²C 驱动、数据计算、LCD 显示控制等功能解耦，代码结构清晰，便于维护和移植。

##  硬件与软件环境

FPGA 开发板: STEP-BaseBoard V4.0 底板+小脚丫 Altera MAX10 核心板 （10M08SAM153C8G）
传感器: 板载SHT30 温湿度传感器模块
显示屏: 板载 TFTLCD 显示屏
开发工具: Quartus Prime 18.1
硬件描述语言: Verilog HDL

## 项目结构

```
.
├── source/               
│   ├── pll/              # PLL IP核文件
│   ├── lcd_temperature.v # 顶层模块
│   ├── sht30_driver.v    # SHT30 I2C 驱动模块
│   ├── calculate.v       # 温湿度计算模块
│   ├── bin_to_bcd.v      # 二进制转BCD码模块
│   ├── lcd_init.v        # LCD 初始化模块
│   ├── lcd_write.v       # LCD SPI 写驱动模块
│   ├── lcd_show_data.v       # LCD 数据显示逻辑
│   ├── pic_ram.v             # 图片/背景数据存储 
│   └── pixel_rom.v           # 字符点阵数据存储
├── lcd_temperature.qpf     # Quartus 项目文件
├── lcd_temperature.qsf     # Quartus 设置与引脚约束文件
└── lcd_temperature.out.sdc # 时序约束文件
```

##  如何使用

1.  使用 Quartus Prime 18.1 打开 `lcd_temperature.qpf` 工程文件。
2.  执行完整的编译流程 (综合、布局布线)。
3.  通过数据线将小脚丫开发板连接至电脑。
4.  使用 Quartus Programmer 将生成的 `.sof` 配置文件烧录到 MAX 10 FPGA 中。
5.  按下开发板上的复位按键，即可在 LCD 屏幕上看到实时更新的温湿度数据。
