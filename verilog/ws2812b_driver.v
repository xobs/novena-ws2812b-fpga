`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/11/2014 02:27:19 AM
// Design Name: 
// Module Name: ws2812b_driver
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


module ws2812b_driver #(
    parameter WIDTH = 0
)(
    input clk,
    input enable,
    input [WIDTH-1:0] data_in,
    output wave_out,
    output reg done
    );
        
    reg [11:0] 		      counter;
    reg [WIDTH:0]            data;
    reg load_next;
    
    wire empty;
    wire wave_1;
    wire wave_0;
    
    initial begin
        done <= 1'b1;
        counter <= 1'b0;
        data <= {1'b1,data_in};
        load_next = 1'b0;
    end
    always @(posedge clk) begin
        if (done && enable)
        begin
            counter <= 0;
            done <= 1'b0;
            data <= {1'b1,data_in};
        end else begin
            counter <= ((empty && !done) || counter < 6'b111100) ? (counter + 1) : 0;
            done <= (counter == 12'ha27) ? 1'b1 : done;
            
            if (wave_1) begin
                load_next <= 1'b1;
            end else if (load_next) begin
                data <= data >> 1;
                load_next <= 1'b0;
            end
        end
    end
    //always @(negedge wave_1) begin
    //    data <= next_data;
    //end
    
    
    assign wave_0 = (counter < 6'b010100) ? 1'b1 : 1'b0;
    assign wave_1 = (counter < 6'b101000) ? 1'b1 : 1'b0;
    assign wave_out = !empty ? (data[0] ? wave_1 : wave_0) : 1'b0;
    assign empty = data <= 1'b1 ? 1'b1 : 1'b0;
endmodule
