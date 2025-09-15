`timescale 1ns/1ps
import fpnew_pkg::*;

module tb_fpnew_simple_2;

  // Parámetros del testbench
  parameter FP_WIDTH = 16;
  parameter NUM_OPERANDS = 3;

  // Señales de la interfaz de la FPU
  logic clk;
  logic rst_ni;
  logic [NUM_OPERANDS-1:0][FP_WIDTH-1:0] operands_i;
  // Corrección: Usar los tipos enum de fpnew_pkg
  fpnew_pkg::roundmode_e rnd_mode_i;
  fpnew_pkg::operation_e op_i;
  logic op_mod_i;
  fpnew_pkg::fp_format_e src_fmt_i;
  fpnew_pkg::fp_format_e dst_fmt_i;
  fpnew_pkg::int_format_e int_fmt_i;
  logic vectorial_op_i;
  logic [FP_WIDTH-1:0] simd_mask_i;
  logic tag_i;
  logic in_valid_i;
  logic out_ready_i;
  logic flush_i;
  
  logic in_ready_o;
  logic [FP_WIDTH-1:0] result_o;
  fpnew_pkg::status_t status_o; // Corrección: Usar el tipo de status_t
  logic tag_o;
  logic out_valid_o;
  logic busy_o;
  
  // Declara la estructura de características como una constante
  localparam fpu_features_t features_cfg = '{
    Width:         FP_WIDTH,
    EnableVectors: 1'b0,
    EnableNanBox:  1'b1,
    FpFmtMask:     {1'b0, 1'b0, 1'b1, 1'b0, 1'b0}, // Solo habilita el formato FP16
    IntFmtMask:    {fpnew_pkg::INT64, fpnew_pkg::INT32, fpnew_pkg::INT16, fpnew_pkg::INT8}
  };

  // Instancia de la FPU (Device Under Test)
  fpnew_top #(
    .Features (features_cfg),
    .Implementation (fpnew_pkg::DEFAULT_NOREGS),
    .TagType (logic)
  ) i_fpnew_top (
    .clk_i(clk),
    .rst_ni(rst_ni),
    .operands_i(operands_i),
    .rnd_mode_i(rnd_mode_i),
    .op_i(op_i),
    .op_mod_i(op_mod_i),
    .src_fmt_i(src_fmt_i),
    .dst_fmt_i(dst_fmt_i),
    .int_fmt_i(int_fmt_i),
    .vectorial_op_i(vectorial_op_i),
    .simd_mask_i(simd_mask_i),
    .tag_i(tag_i),
    .in_valid_i(in_valid_i),
    .out_ready_i(out_ready_i),
    .flush_i(flush_i),
    .in_ready_o(in_ready_o),
    .result_o(result_o),
    .status_o(status_o),
    .tag_o(tag_o),
    .out_valid_o(out_valid_o),
    .busy_o(busy_o)
  );
  
  // Generación del reloj
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // Secuencia de reset
  initial begin
    rst_ni = 1'b0;
    flush_i = 1'b0;
    #10;
    rst_ni = 1'b1;
    #10;
    flush_i = 1'b1;
    #10;
    flush_i = 1'b0;
  end

  // Tarea para enviar una operación a la FPU
  task send_op(
    input logic [FP_WIDTH-1:0] operand1,
    input logic [FP_WIDTH-1:0] operand2,
    input fpnew_pkg::operation_e operation,
    input logic operation_mod,
    input fpnew_pkg::roundmode_e round_mode,
    input fpnew_pkg::fp_format_e src_format,
    input fpnew_pkg::fp_format_e dst_format,
    input fpnew_pkg::int_format_e int_format
  );
    begin
      operands_i[0] = operand1;
      operands_i[1] = operand2;
      op_i = operation;
      op_mod_i = operation_mod;
      rnd_mode_i = round_mode;
      src_fmt_i = src_format;
      dst_fmt_i = dst_format;
      int_fmt_i = int_format;
      in_valid_i = 1'b1;
      out_ready_i = 1'b1;
      tag_i = 1'b0;
      vectorial_op_i = 1'b0;
      simd_mask_i = '1;
      
      @(posedge clk);
      while (!in_ready_o) begin
        @(posedge clk);
      end
      
      in_valid_i = 1'b0;
      
      @(posedge clk);
      while (!out_valid_o) begin
        @(posedge clk);
      end
      
      $display("Operación: %0d, Operandos: %h, %h, Resultado: %h, Estatus: %b", op_i, operands_i[0], operands_i[1], result_o, status_o);
    end
  endtask
  
  // Secuencia de prueba
  initial begin
    // Declara las variables al inicio del bloque
    fpnew_pkg::fp_format_e FP16_FORMAT;
    fpnew_pkg::roundmode_e RNE_MODE;

    // Ahora asigna los valores
    FP16_FORMAT = fpnew_pkg::FP16;
    RNE_MODE = fpnew_pkg::RNE;
    
    wait(rst_ni == 1'b1);
    
    // Casos de prueba de suma y resta de 16 bits (ejemplos IEEE 754)
    // Suma: 1.0 + 1.0 = 2.0
    // (0x3C00 + 0x3C00 = 0x4000)
    send_op(16'h3C00, 16'h3C00, fpnew_pkg::ADD, 1'b0, RNE_MODE, FP16_FORMAT, FP16_FORMAT, fpnew_pkg::INT8);
    assert(result_o == 16'h4000) else $error("Falla en la suma 1.0 + 1.0");

    // Resta: 3.0 - 2.0 = 1.0
    // (0x4200 - 0x4000 = 0x3C00)
    send_op(16'h4200, 16'h4000, fpnew_pkg::ADD, 1'b1, RNE_MODE, FP16_FORMAT, FP16_FORMAT, fpnew_pkg::INT8);
    assert(result_o == 16'h3C00) else $error("Falla en la resta 3.0 - 2.0");

    $finish;
  end
  
endmodule