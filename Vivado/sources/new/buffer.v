`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/16/2026 04:16:52 AM
// Design Name: 
// Module Name: buffer
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module buffer(
        inout sda,
        inout scl,
        input I_0,
        input I_1,
        input T_0,
        input T_1,
        output O_0,
        output O_1
    );
    
    IOBUF U0 (.O(O_0), .I(I_0), .T(T_0), .IO(sda));
    IOBUF U1 (.O(O_1), .I(I_1), .T(T_1), .IO(scl));
    
endmodule
