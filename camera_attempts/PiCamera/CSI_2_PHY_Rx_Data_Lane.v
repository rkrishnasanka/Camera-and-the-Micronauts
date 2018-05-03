`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: BU
// Engineer: Josh Wildey
// 
// Create Date:    13:16:09 03/18/2018
// Module Name:    CSI_2_PHY_Rx_Data_Lane 
// Project Name:   PiCamera
// Target Devices: Nexys3 Spartan 6
// Revision 0.01 - File Created
// Description: 
//
// This module implements a data lane on the Physical layer of the
// CSI-2 Interface.
//
//////////////////////////////////////////////////////////////////////////////////
module CSI_2_PHY_Rx_Data_Lane(
	// This is the Positive Input Line for the input data line
   input Dp,
	
	// This is the Negative Input Line for the input data line
   input Dn,
	
	// High-Speed Receive DDR Clock used to sample the data in all data lanes.
	// This signal is supplied by the CSI-2 clock lane receiver
   input RxDDRClkHS,
	
	// Shutdown Lane Module.  This active high signal forces the lan module
	// into "shutdown", disabling all activity.  All line driver, including
	// terminators are turned off when Shutdown is asserted.  When Shutdown
	// is high, all PPI outputs are driven to the default inactive state.
	// Shutdown is a level sensitive signal and does not depend on any clock
   input Shutdown,
	
	// High-Speed Receive Byte Clock.  This signal is used to synchronize signals
	// in the high-speed receive clock domain.  The RxByteClkHS is generated by
	// dividing the received RxDDRClkHS.
   output RxByteClkHS,
	
	// High-Speed Receive Data.  Eight bit high-speed data received by the lane
	// module.  The signal connected to RxDataHS[0] was received first.  Data is
	// transferred on rising edges of RxByteClkHS.
   output [7:0] RxDataHS,
	
	// Receiver Synchronization Observed.  This active high signal indicates that
	// the lane module has seen an appropriate synchronization event.  In a typical
	// high-speed transmission, RxSyncHS is high for one cycle of RxByteClkHS at the
	// beginning of a high-speed transmission when RxActiveHS is first asserted.  The
	// signal missing is signaled using ErrSotSyncHS.
   output RxSyncHS,
	
	// High-Speed Receive Data Valid.  This active high signal indicated that the lane
	// module is driving valid ata to the protocol on the RxDataHS output.  There is no
	// "RxReadyHS" signal, and the protocol is expected to caputre RxDataHS on every
	// rising edge of RxByteClkHS where RxValidHS is asserted.  There is no provision for
	// the protocol to slow down ("throttle") the receive data.
   output RxValidHS,
	
	// High-Speed Reception Active.  This active high signal indicates that the lane
	// module is actively receiving a high-speed transmission from the lane interconnect.
   output RxActiveHS,
	
	// Escape Ultra Low Power (Rx) mode.  This active high signal is asserted to
	// indicate that the lane module has entered ultra low power mode.  The lane
	// module remains in the mode with RxUlpmEsc asserted until a Stop state is
	// detected on the lane interconnect.
   output RxUlpmEsc,
	
	// Lane is in Stop state.  This active high signal indicated that the lane
	// module is currently in Stop state.  This signal is asynchronous.
   output Stopstate,
	
	// Start-of-Transmission (SoT) Error.  If the high-speed SoT leader sequence is
	// corrupted, but in such a way that proper synchronization can still be acheived,
	// this error signal is asserted for one cycle of RxByteClkHS.  This is considered
	// to be a "soft error" in the leader sequence and confidence in the payload is reduced.
   output ErrSotHS,
	
	// Start-of-Transmission Synchronization Error.  If the high-speed SoT leader
	// sequence is corrupted in a way that proper synchronization cannot be
	// expected, this error is asserted for one cycle of RxByteClkHS.
   output ErrSotSyncHS,
	
	// Escape Entry Error.  If an unrecognized escape entry command is received,
	// this signal is asserted and remains high until the next change in the line
	// state.  The only escape entry command supported by the receiver is the ULPS.
   output ErrEsc,
	
	// Control Error.  This signal is asserted when an incorrect line state
	// sequence is detected.
   output ErrControl
   );

	// Intermediate connection for RxDataHS (Output of Differential Signal Buffer)
	wire RxDataHSBuf;

	IBUFDS #(
		.CAPACITANCE("NORMAL"),   // "LOW", "NORMAL", "DONT_CARE" (Virtex-4 only)
		.DIFF_TERM("TRUE"),       // Differential Termination (Virtex-4/5, Spartan-3E/3A)
		.IBUF_DELAY_VALUE("0"),   // Specify the amount of added input delay for
										  // the buffer: "0"-"12" (Spartan-3E)
										  // "0"-"16" (Spartan-3A)
		.IFD_DELAY_VALUE("AUTO"), // Specify the amount of added delay for input
										  // register: "AUTO", "0"-"6" (Spartan-3E)
										  // "AUTO", "0"-"8" (Spartan-3A)
		.IOSTANDARD("DEFAULT")    // Specify the input I/O standard
	) IBUFDS_inst (
		.O(RxDataHSBuf),  // Buffer output
		.I(Dp),             // Diff_p buffer input (connect directly to top-level port)
		.IB(Dn)             // Diff_n buffer input (connect directly to top-level port)
	);
	
	// Byte Clock Generation
	reg [1:0] RxByteClkHSCounter = 0;
	reg       ByteClk = 0;
	
	// Byte Buffer to deserialize
	reg [7:0] DataByte = 8'd0;
	
	assign RxByteClkHS = Shutdown ? 1'b0 : ByteClk;
	assign RxDataHS = Shutdown ? 8'd0 : ( {DataByte[0],
	                                       DataByte[1],
										   DataByte[2],
										   DataByte[3],
										   DataByte[4],
										   DataByte[5],
										   DataByte[6],
										   DataByte[7]} );
	
	always @ (posedge RxDDRClkHS) begin
		if (RxByteClkHSCounter == 0) ByteClk <= ~ByteClk;
		RxByteClkHSCounter <= RxByteClkHSCounter + 1'b1;
		DataByte = (DataByte << 1'b1) | RxDataHSBuf;
	end

endmodule