`timescale 1ns/1ps
import fpnew_pkg::*;

module tb_fpnew_simple;

  // Parámetros del testbench
  parameter FP_WIDTH = 32;
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
  logic simd_mask_i;
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
    FpFmtMask:     {1'b1, 1'b0, 1'b0, 1'b0, 1'b0},
    IntFmtMask:    {fpnew_pkg::INT64, fpnew_pkg::INT32, fpnew_pkg::INT16, fpnew_pkg::INT8}
  };

  // Instancia de la FPU (Device Under Test)
  fpnew_top #(
    .Features (fpnew_pkg::RV32F),
    .Implementation (fpnew_pkg::DEFAULT_HUB),
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
    flush_i = 1'b1;
    #5;
    rst_ni = 1'b1; // Liberar el reset asíncrono
    //#10;
    flush_i = 1'b0; // Activar el reset síncrono para limpiar el pipeline
    //#10;
    //flush_i = 1'b0; // Liberar el reset síncrono
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
      // Poner los datos en los puertos de entrada.
      // Los datos deben ser estables antes de activar 'in_valid_i'.
      op_i = operation;
      if (op_i == fpnew_pkg::DIV || op_i == fpnew_pkg::MUL) begin
        operands_i[0] = operand1;
        operands_i[1] = operand2;
        operands_i[2] = 'h0000;
      end else if (op_i == fpnew_pkg::ADD) begin
        operands_i[0] = 'h0000;
        operands_i[1] = operand1;
        operands_i[2] = operand2;
      end else if (op_i == fpnew_pkg::SQRT) begin
        operands_i[0] = operand1;
        operands_i[1] = 'h0000;
        operands_i[2] = 'h0000;
      end
      
      op_mod_i = operation_mod;
      rnd_mode_i = round_mode;
      src_fmt_i = src_format;
      dst_fmt_i = dst_format;
      int_fmt_i = int_format;
      tag_i = 1'b0;
      vectorial_op_i = 1'b0;
      simd_mask_i = '1;

      // Iniciar el handshake de entrada. El testbench está listo para enviar.
      // SUPRIMIDO
      in_valid_i = 1'b1;
      out_ready_i = 1'b1; // El testbench también está listo para recibir el resultado.

      // Esperar a que la FPU esté lista
      @(posedge clk);
      wait(in_ready_o == 1'b1);
      //while (!in_ready_o) begin
      //  @(posedge clk);
      //end
      
      //if (op_i == fpnew_pkg::DIV || op_i == fpnew_pkg::SQRT) begin
      //  wait(in_ready_o == 1'b1);
      //end

      // Esperar a que el resultado esté disponible

      //CAMBIO 1
      @(posedge clk);
      wait(out_valid_o == 1'b1);

      in_valid_i = 1'b0; // Desactivar 'in_valid_i' después de que la FPU acepte los datos.
      out_ready_i = 1'b0; // Desactivar 'out_ready_i' después

      //CAMBIO 2
      if (op_i == fpnew_pkg::DIV || op_i == fpnew_pkg::SQRT) begin
        @(posedge clk);
      end

      //wait(busy_o == 1'b0); // Esperar a que la FPU termine de procesar
      //while (!out_valid_o) begin
      //  @(posedge clk);
      //end
      // La transacción de salida se ha completado.
      //$display("Operación: %0d, Operandos: %h, %h, Resultado: %h, Estatus: %b", op_i, operands_i[0], operands_i[1], result_o, status_o);
    end
  endtask
  
  // Secuencia de prueba
  initial begin
    // Declara las variables al inicio del bloque
    fpnew_pkg::fp_format_e FP32_FORMAT;
    fpnew_pkg::roundmode_e RNE_MODE;

    // Ahora asigna los valores
    FP32_FORMAT = fpnew_pkg::FP32;
    RNE_MODE = fpnew_pkg::RNE;
    
    wait(rst_ni == 1'b1 && flush_i == 1'b0);

    //// NUEVA LINEA
    //in_valid_i = 1'b1;
    //out_ready_i = 1'b1;
    
    // Casos de prueba de suma y resta de 16 bits (ejemplos IEEE 754)
    // Suma: -inf + inf = inf
    // (0x3C00 + 0x3C00 = 0x4000)
    send_op(32'hFFFFFFFF, 32'h7FFFFFFF, fpnew_pkg::ADD, 1'b0, RNE_MODE, FP32_FORMAT, FP32_FORMAT, fpnew_pkg::INT8);
    //assert(result_o == 32'h7FFFFFFF) else $error("Falla en -inf + inf");

    // Resta random
    // (0x4200 - 0x4000 = 0x3C00)
    send_op(32'h40A147AE, 32'h41800000, fpnew_pkg::ADD, 1'b0, RNE_MODE, FP32_FORMAT, FP32_FORMAT, fpnew_pkg::INT8);
    //assert(result_o == 32'h3C000000) else $error("Falla la resta random");

    // Suma: 1.0 + 1.0 = 2.0
    send_op(32'h40000000, 32'hA58F3210, fpnew_pkg::MUL, 1'b0, RNE_MODE, FP32_FORMAT, FP32_FORMAT, fpnew_pkg::INT8);
    //assert(result_o == 32'h3C000000) else $error("Fallo en la multiplicacion 1.0·X");

    // Suma: 1.0 + 1.0 = 2.0
    send_op(32'h41400000, 32'h3F800000, fpnew_pkg::MUL, 1'b0, RNE_MODE, FP32_FORMAT, FP32_FORMAT, fpnew_pkg::INT8);
    //assert(result_o == 32'h3C000000) else $error("Fallo en la multiplicacion 1.0·X");

    // Division: 4.0 / 2.0 = 2.0
    send_op(32'h00012345, 32'h00001234, fpnew_pkg::DIV, 1'b0, RNE_MODE, FP32_FORMAT, FP32_FORMAT, fpnew_pkg::INT8);
    //assert(result_o == 32'h3C000000) else $error("Fallo en la multiplicacion 1.0·X");

    //@(posedge clk);

    // Division: 0 / 0 = inf
    send_op(32'h42C80000, 32'h41A00000, fpnew_pkg::DIV, 1'b0, RNE_MODE, FP32_FORMAT, FP32_FORMAT, fpnew_pkg::INT8);
    //assert(result_o == 32'h3C000000) else $error("Fallo en la multiplicacion 1.0·X");

    //@(posedge clk)

    // Division: 0 / 0 = inf
    send_op(32'h43700000, 32'h42700000, fpnew_pkg::SQRT, 1'b0, RNE_MODE, FP32_FORMAT, FP32_FORMAT, fpnew_pkg::INT8);
    //assert(result_o == 32'h3C000000) else $error("Fallo en la multiplicacion 1.0·X");

    //$finish;
  end
  
endmodule