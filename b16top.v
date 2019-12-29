module b16top
	(
		////////////////////	Clock Input	 	////////////////////	 
		CLOCK_24,						//	24 MHz
		CLOCK_27,						//	27 MHz
		CLOCK_50,						//	50 MHz
		EXT_CLOCK,						//	External Clock
		////////////////////	Push Button		////////////////////
		KEY,							//	Pushbutton[3:0]
		////////////////////	DPDT Switch		////////////////////
		SW,								//	Toggle Switch[9:0]
		////////////////////	7-SEG Dispaly	////////////////////
		HEX0,							//	Seven Segment Digit 0
		HEX1,							//	Seven Segment Digit 1
		HEX2,							//	Seven Segment Digit 2
		HEX3,							//	Seven Segment Digit 3
		////////////////////////	LED		////////////////////////
		LEDG,							//	LED Green[7:0]
		LEDR,							//	LED Red[9:0]
		////////////////////////	UART	////////////////////////
		UART_TXD,						//	UART Transmitter
		UART_RXD,						//	UART Receiver
		/////////////////////	SDRAM Interface		////////////////
		DRAM_DQ,						//	SDRAM Data bus 16 Bits
		DRAM_ADDR,						//	SDRAM Address bus 12 Bits
		DRAM_LDQM,						//	SDRAM Low-byte Data Mask 
		DRAM_UDQM,						//	SDRAM High-byte Data Mask
		DRAM_WE_N,						//	SDRAM Write Enable
		DRAM_CAS_N,						//	SDRAM Column Address Strobe
		DRAM_RAS_N,						//	SDRAM Row Address Strobe
		DRAM_CS_N,						//	SDRAM Chip Select
		DRAM_BA_0,						//	SDRAM Bank Address 0
		DRAM_BA_1,						//	SDRAM Bank Address 0
		DRAM_CLK,						//	SDRAM Clock
		DRAM_CKE,						//	SDRAM Clock Enable
		////////////////////	Flash Interface		////////////////
		FL_DQ,							//	FLASH Data bus 8 Bits
		FL_ADDR,						//	FLASH Address bus 22 Bits
		FL_WE_N,						//	FLASH Write Enable
		FL_RST_N,						//	FLASH Reset
		FL_OE_N,						//	FLASH Output Enable
		FL_CE_N,						//	FLASH Chip Enable
		////////////////////	SRAM Interface		////////////////
		SRAM_DQ,						//	SRAM Data bus 16 Bits
		SRAM_ADDR,						//	SRAM Address bus 18 Bits
		SRAM_UB_N,						//	SRAM High-byte Data Mask 
		SRAM_LB_N,						//	SRAM Low-byte Data Mask 
		SRAM_WE_N,						//	SRAM Write Enable
		SRAM_CE_N,						//	SRAM Chip Enable
		SRAM_OE_N,						//	SRAM Output Enable
		////////////////////	SD_Card Interface	////////////////
		SD_DAT,							//	SD Card Data
		SD_DAT3,						//	SD Card Data 3
		SD_CMD,							//	SD Card Command Signal
		SD_CLK,							//	SD Card Clock
		////////////////////	USB JTAG link	////////////////////
		TDI,  							// CPLD -> FPGA (data in)
		TCK,  							// CPLD -> FPGA (clk)
		TCS,  							// CPLD -> FPGA (CS)
	    TDO,  							// FPGA -> CPLD (data out)
		////////////////////	I2C		////////////////////////////
		I2C_SDAT,						//	I2C Data
		I2C_SCLK,						//	I2C Clock
		////////////////////	PS2		////////////////////////////
		PS2_DAT,						//	PS2 Data
		PS2_CLK,						//	PS2 Clock
		////////////////////	VGA		////////////////////////////
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_R,   						//	VGA Red[3:0]
		VGA_G,	 						//	VGA Green[3:0]
		VGA_B,  						//	VGA Blue[3:0]
		////////////////	Audio CODEC		////////////////////////
		AUD_ADCLRCK,					//	Audio CODEC ADC LR Clock
		AUD_ADCDAT,						//	Audio CODEC ADC Data
		AUD_DACLRCK,					//	Audio CODEC DAC LR Clock
		AUD_DACDAT,						//	Audio CODEC DAC Data
		AUD_BCLK,						//	Audio CODEC Bit-Stream Clock
		AUD_XCK,						//	Audio CODEC Chip Clock
		////////////////////	GPIO	////////////////////////////
		GPIO_0,							//	GPIO Connection 0
		GPIO_1							//	GPIO Connection 1
	);

////////////////////////	Clock Input	 	////////////////////////
input	[1:0]	CLOCK_24;				//	24 MHz
input	[1:0]	CLOCK_27;				//	27 MHz
input			CLOCK_50;				//	50 MHz
input			EXT_CLOCK;				//	External Clock
////////////////////////	Push Button		////////////////////////
input	[3:0]	KEY;					//	Pushbutton[3:0]
////////////////////////	DPDT Switch		////////////////////////
input	[9:0]	SW;						//	Toggle Switch[9:0]
////////////////////////	7-SEG Dispaly	////////////////////////
output	[6:0]	HEX0;					//	Seven Segment Digit 0
output	[6:0]	HEX1;					//	Seven Segment Digit 1
output	[6:0]	HEX2;					//	Seven Segment Digit 2
output	[6:0]	HEX3;					//	Seven Segment Digit 3
////////////////////////////	LED		////////////////////////////
output	[7:0]	LEDG;					//	LED Green[7:0]
output	[9:0]	LEDR;					//	LED Red[9:0]
////////////////////////////	UART	////////////////////////////
output			UART_TXD;				//	UART Transmitter
input			UART_RXD;				//	UART Receiver
///////////////////////		SDRAM Interface	////////////////////////
inout	[15:0]	DRAM_DQ;				//	SDRAM Data bus 16 Bits
output	[11:0]	DRAM_ADDR;				//	SDRAM Address bus 12 Bits
output			DRAM_LDQM;				//	SDRAM Low-byte Data Mask 
output			DRAM_UDQM;				//	SDRAM High-byte Data Mask
output			DRAM_WE_N;				//	SDRAM Write Enable
output			DRAM_CAS_N;				//	SDRAM Column Address Strobe
output			DRAM_RAS_N;				//	SDRAM Row Address Strobe
output			DRAM_CS_N;				//	SDRAM Chip Select
output			DRAM_BA_0;				//	SDRAM Bank Address 0
output			DRAM_BA_1;				//	SDRAM Bank Address 0
output			DRAM_CLK;				//	SDRAM Clock
output			DRAM_CKE;				//	SDRAM Clock Enable
////////////////////////	Flash Interface	////////////////////////
inout	[7:0]	FL_DQ;					//	FLASH Data bus 8 Bits
output	[21:0]	FL_ADDR;				//	FLASH Address bus 22 Bits
output			FL_WE_N;				//	FLASH Write Enable
output			FL_RST_N;				//	FLASH Reset
output			FL_OE_N;				//	FLASH Output Enable
output			FL_CE_N;				//	FLASH Chip Enable
////////////////////////	SRAM Interface	////////////////////////
inout	[15:0]	SRAM_DQ;				//	SRAM Data bus 16 Bits
output	[17:0]	SRAM_ADDR;				//	SRAM Address bus 18 Bits
output			SRAM_UB_N;				//	SRAM High-byte Data Mask 
output			SRAM_LB_N;				//	SRAM Low-byte Data Mask 
output			SRAM_WE_N;				//	SRAM Write Enable
output			SRAM_CE_N;				//	SRAM Chip Enable
output			SRAM_OE_N;				//	SRAM Output Enable
////////////////////	SD Card Interface	////////////////////////
inout			SD_DAT;					//	SD Card Data
inout			SD_DAT3;				//	SD Card Data 3
inout			SD_CMD;					//	SD Card Command Signal
output			SD_CLK;					//	SD Card Clock
////////////////////////	I2C		////////////////////////////////
inout			I2C_SDAT;				//	I2C Data
output			I2C_SCLK;				//	I2C Clock
////////////////////////	PS2		////////////////////////////////
input		 	PS2_DAT;				//	PS2 Data
input			PS2_CLK;				//	PS2 Clock
////////////////////	USB JTAG link	////////////////////////////
input  			TDI;					// CPLD -> FPGA (data in)
input  			TCK;					// CPLD -> FPGA (clk)
input  			TCS;					// CPLD -> FPGA (CS)
output 			TDO;					// FPGA -> CPLD (data out)
////////////////////////	VGA			////////////////////////////
output			VGA_HS;					//	VGA H_SYNC
output			VGA_VS;					//	VGA V_SYNC
output	[3:0]	VGA_R;   				//	VGA Red[3:0]
output	[3:0]	VGA_G;	 				//	VGA Green[3:0]
output	[3:0]	VGA_B;   				//	VGA Blue[3:0]
////////////////////	Audio CODEC		////////////////////////////
output			AUD_ADCLRCK;			//	Audio CODEC ADC LR Clock
input			AUD_ADCDAT;				//	Audio CODEC ADC Data
output			AUD_DACLRCK;			//	Audio CODEC DAC LR Clock
output			AUD_DACDAT;				//	Audio CODEC DAC Data
inout			AUD_BCLK;				//	Audio CODEC Bit-Stream Clock
output			AUD_XCK;				//	Audio CODEC Chip Clock
////////////////////////	GPIO	////////////////////////////////
inout	[35:0]	GPIO_0;					//	GPIO Connection 0
inout	[35:0]	GPIO_1;					//	GPIO Connection 1
////////////////////////////////////////////////////////////////////

//	All inout port turn to tri-state
assign	DRAM_DQ		=	16'hzzzz;
assign	FL_DQ		=	8'hzz;
assign	SRAM_DQ		=	16'hzzzz;
assign	SD_DAT		=	1'bz;
assign	I2C_SDAT	=	1'bz;
// all unconnected outputs to harmless values
assign { DRAM_ADDR, DRAM_LDQM, DRAM_UDQM, DRAM_WE_N, DRAM_CAS_N, DRAM_RAS_N, DRAM_CS_N } = 'hF;
assign { DRAM_BA_0, DRAM_BA_1, DRAM_CLK, DRAM_CKE } = 0;
assign { FL_ADDR, FL_WE_N, FL_RST_N, FL_OE_N, FL_CE_N } = 'hF;
assign { SD_DAT3, SD_CMD, SD_CLK } = 0;
assign { VGA_HS, VGA_VS, VGA_R, VGA_G, VGA_B } = 0;
assign { AUD_ADCLRCK, AUD_DACLRCK, AUD_DACDAT, AUD_BCLK, AUD_XCK } = 0;
assign { TDO, I2C_SCLK } = 1;

   wire 	clk = CLOCK_50;
`ifdef SLOW_CLOCK
   reg [27:0] 	counter;

   always@(posedge clk or negedge nreset)
     if(!nreset)
       counter <= 0;
     else
       counter <= counter + 1;
`endif

   wire 	nreset = KEY[0];
   wire 	rc;
   wire [1:0] 	wc;
   wire [15:0] 	addrc, dwritec;
   reg [15:0] 	data;
   reg [3:0] 	sel;
   reg 	  READY;

   wire [7:0] od;
   wire [7:0] id;
   wire [15:0] rate;
   wire       dox;
   wire       dix, wip;

   wire   dr, dw, drun, irqrun, csu, ru;
   wire [1:0] wru;
   wire [2:0] dstate;
   wire [15:0] LED7;
   wire [15:0] addru, datau, data_dbg, ramdata, bp;
   wire        run = irqrun & ~csu & drun & (/* SW[3] ? &counter[22:0] : */ &READY);

   uart rs232(clk, nreset, UART_RXD, UART_TXD, id, od, dix, dox, wip, rate, LEDR);

   dbg_uart dbgmem(clk, nreset, dix, dox, id, od,
		   csu, addru, ru, wru, dr ? data_dbg : data, datau, { 5'b00100, irqrun, &READY, drun }, dstate);

   wire [15:0] addr = csu ? addru : addrc;
   wire [15:0] dwrite = csu ? datau : dwritec;
   wire [1:0] w = csu ? wru : wc;
   wire r = csu ? ru : rc;
   
   debugger dbg(.clk(clk), .nreset(nreset), .run(~csu & &READY),
                .addr(addru[15:1]), .data(datau), .r(ru), .w(wru),
                .cpu_addr(addr), .cpu_r(r),
                .drun(drun), .dr(dr), .dw(dw), .bp(bp));
   cpu b16(.clk(clk), .latclk(clk), .run(run), .nreset(nreset),
	   .addr(addrc), .rd(rc), .wr(wc), .data(data), .dataout(dwritec), .gwrite(1'b0),
	   .dr(dr), .dw(dw), .daddr(addru[3:1]), .din(datau), .dout(data_dbg), .bp(bp));
   SEG7_LUT_4 u0 ( HEX0,HEX1,HEX2,HEX3,
   `ifdef SWITCHES
                   SW[2] ? SW[0] ? { 8'h0, dix, ru, wru, 1'b0, dstate } : rate : SW[1] ? (SW[0] ? addr : data) :
   `endif
                   LED7);

   bootram bootmem(.clk(~clk), .nreset(nreset), .sel(sel[1]), .r(r), .w(w),
		   .addr(addr[12:1]), .din(dwrite), .dout(ramdata));
   
   always @(negedge clk or negedge nreset)
     if(!nreset) begin
       READY <= -1;
     end else begin
       if(sel[0]) READY <= READY + 1;
       else READY <= -1;
     end

   wire [15:0] sfr_data, pwm_data;
   wire [2:0]  pwm;
   
   sfr sfr_block(clk, nreset, drun, sel[2], addr[7:0], r, w, dwrite, sfr_data,
		 LED7, GPIO_0, GPIO_1, irqrun, { KEY[3:1], SW },
		 { 24'b0, 3'b0, pwm[2], 3'b0, pwm[1], 3'b0, pwm[0] });
   pwm pwm_block(clk, nreset, drun, sel[3], addr[5:0], r, w, dwrite, pwm_data,
		 pwm);
   
   always @*
     case({ r, sel })
       5'b11000: data <= pwm_data;
       5'b10100: data <= sfr_data;
       5'b10010: data <= ramdata;
       5'b10001: data <= SRAM_DQ;
       default: data <= 0;
     endcase // case(sel)
   
   always @(addr)
     if(addr[15:8] == 8'hff) sel <= 4'b0100;
     else if(addr[15:8] == 8'hfe) sel <= 4'b1000;
     else if(addr[15:13] == 3'h1) sel <= 4'b0010;
     else sel <= 4'b0001;

   assign SRAM_WE_N = ~sel[0] | (|w ? &READY : 1'b1);
   assign SRAM_CE_N = ~sel[0] | (|w ? &READY : ~r);
   assign SRAM_OE_N = ~(sel[0] & r);
   assign SRAM_DQ = (SRAM_OE_N & sel[0]) ? dwrite : 16'hzzzz;
   assign SRAM_ADDR = ~sel[0] ? 16'hzzzz : addr[15:1];
   assign SRAM_UB_N = ~r & (SRAM_WE_N | ~w[1]);
   assign SRAM_LB_N = ~r & (SRAM_WE_N | ~w[0]);
   
   assign LEDG = { SRAM_WE_N, SRAM_CE_N, SRAM_OE_N, SRAM_UB_N, SRAM_LB_N, sel };
   
endmodule
