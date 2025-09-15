# Crear la biblioteca de trabajo
vlib work
vmap work work

# Definir las rutas de los directorios de inclusión
set COMMON_CELLS_INC "./src/common_cells/include"
set FPU_DIV_SQRT_INC "./src/fpu_div_sqrt_mvp/hdl"
set VENDOR_INC "./vendor/opene906/E906_RTL_FACTORY/gen_rtl/fdsu/rtl"

# Compilar los paquetes de common_cells primero
vlog -sv -work work +incdir+$COMMON_CELLS_INC \
  ./src/common_cells/src/cf_math_pkg.sv \
  ./src/common_cells/src/cb_filter_pkg.sv \
  ./src/common_cells/src/cdc_reset_ctrlr_pkg.sv \
  ./src/common_cells/src/ecc_pkg.sv

# Compilar el resto de los módulos de common_cells
vlog -sv -work work +incdir+$COMMON_CELLS_INC \
  ./src/common_cells/src/*.sv

# Compilar el paquete de la FPU
vlog -sv -work work +incdir+$COMMON_CELLS_INC +incdir+$FPU_DIV_SQRT_INC ./src/fpnew_pkg.sv

# Compilar el paquete de la unidad de división y raíz cuadrada primero
vlog -sv -work work +incdir+$FPU_DIV_SQRT_INC ./src/fpu_div_sqrt_mvp/hdl/defs_div_sqrt_mvp.sv

# Ahora compilar el resto de los módulos de la unidad de división
vlog -sv -work work +incdir+$FPU_DIV_SQRT_INC ./src/fpu_div_sqrt_mvp/hdl/*.sv

# Compilar el contenido de la carpeta vendor
vlog -sv -work work +incdir+$COMMON_CELLS_INC +incdir+$FPU_DIV_SQRT_INC +incdir+$VENDOR_INC \
  ./vendor/opene906/E906_RTL_FACTORY/gen_rtl/fdsu/rtl/*.sv

# Compilar los módulos de la FPU que dependen de los paquetes
vlog -sv -work work +incdir+$COMMON_CELLS_INC +incdir+$FPU_DIV_SQRT_INC +incdir+$VENDOR_INC \
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
  ./src/tb_fpnew_simple.sv