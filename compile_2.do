# Crear la biblioteca de trabajo
vlib work
vmap work work

# Definir las rutas de los directorios de inclusión
set COMMON_CELLS_INC "./src/common_cells/include"
set FPU_DIV_SQRT_INC "./src/fpu_div_sqrt_mvp/hdl"

# Compilar las dependencias comunes primero
vlog -sv -work work +incdir+$COMMON_CELLS_INC ./src/common_cells/src/*.sv

# Compilar el paquete de la FPU primero
vlog -sv -work work +incdir+$COMMON_CELLS_INC +incdir+$FPU_DIV_SQRT_INC ./src/fpnew_pkg.sv

# Compilar las dependencias de la unidad de división y raíz cuadrada
vlog -sv -work work +incdir+$COMMON_CELLS_INC +incdir+$FPU_DIV_SQRT_INC ./src/fpu_div_sqrt_mvp/hdl/*.sv

# Compilar los módulos de la FPU que dependen de los paquetes
# Se listan explícitamente para garantizar el orden de compilación
vlog -sv -work work +incdir+$COMMON_CELLS_INC +incdir+$FPU_DIV_SQRT_INC \
  ./src/fpnew_cast_multi.sv \
  ./src/fpnew_classifier.sv \
  ./src/fpnew_divsqrt_multi.sv \
  ./src/fpnew_divsqrt_th_32.sv \
  ./src/fpnew_divsqrt_th_64_multi.sv \
  ./src/fpnew_fma.sv \
  ./src/fpnew_fma_multi.sv \
  ./src/fpnew_noncomp.sv \
  ./src/fpnew_opgroup_block.sv \
  ./src/fpnew_opgroup_fmt_slice.sv \
  ./src/fpnew_opgroup_multifmt_slice.sv \
  ./src/fpnew_rounding.sv \
  ./src/fpnew_top.sv \
  ./tb_fpnew_simple.sv