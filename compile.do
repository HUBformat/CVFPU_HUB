# Crear la biblioteca de trabajo
vlib work
vmap work work

# Definir las rutas de los directorios de inclusión
set COMMON_CELLS_INC "./src/common_cells/include"
set FPU_DIV_SQRT_INC "./src/fpu_div_sqrt_mvp/hdl"
set VENDOR_INC "./vendor/opene906/E906_RTL_FACTORY/gen_rtl/fdsu/rtl"
set VENDOR_INC2 "./vendor/openc910/C910_RTL_FACTORY/gen_rtl/vfdsu/rtl"

# Compilar los paquetes de common_cells primero, eliminando el archivo que no existe.
vlog -sv -work work +incdir+$COMMON_CELLS_INC \
  ./src/common_cells/src/cf_math_pkg.sv \
  ./src/common_cells/src/cb_filter_pkg.sv \
  ./src/common_cells/src/ecc_pkg.sv

# Compilar el paquete defs_div_sqrt_mvp ANTES que los otros módulos de esa carpeta.
vlog -sv -work work +incdir+$COMMON_CELLS_INC +incdir+$FPU_DIV_SQRT_INC \
  ./src/fpu_div_sqrt_mvp/hdl/defs_div_sqrt_mvp.sv

# Compilar el paquete principal de la FPU fpnew_pkg
vlog -sv -work work +incdir+$COMMON_CELLS_INC +incdir+$FPU_DIV_SQRT_INC ./src/fpnew_pkg.sv

# Compilar el resto de los módulos de common_cells
vlog -sv -work work +incdir+$COMMON_CELLS_INC \
  ./src/common_cells/src/*.sv

# Compilar las dependencias restantes de la unidad de división y raíz cuadrada
# Ahora se pueden compilar con el comodín porque el paquete ya está disponible
vlog -sv -work work +incdir+$COMMON_CELLS_INC +incdir+$FPU_DIV_SQRT_INC ./src/fpu_div_sqrt_mvp/hdl/*.sv

# Compilar el contenido de la carpeta vendor
vlog -sv -work work +incdir+$COMMON_CELLS_INC \
  +incdir+$FPU_DIV_SQRT_INC +incdir+$VENDOR_INC \
  ./vendor/opene906/E906_RTL_FACTORY/gen_rtl/fdsu/rtl/*.v
  
# Compilar los archivos de la unidad de reloj de Openc910.
vlog -work work ./vendor/openc910/C910_RTL_FACTORY/gen_rtl/clk/rtl/*.v
vlog -work work +incdir+$COMMON_CELLS_INC +incdir+$VENDOR_INC2 \
  ./vendor/openc910/C910_RTL_FACTORY/gen_rtl/vfdsu/rtl/*.v

# Compilar módulos del sumador
vlog -sv -work work \
  ./src/hub_modules/adder/special_cases_detector.sv \
  ./src/hub_modules/adder/special_result_for_adder.sv \
  ./src/hub_modules/adder/Exponent_difference.sv \
  ./src/hub_modules/adder/shifter.sv \
  ./src/hub_modules/adder/LZD.sv \
  ./src/hub_modules/adder/FPHUB_adder.sv \
  ./src/hub_modules/adder/fpnew_hub_adder_wrapper.sv

# Compilar módulos del multiplicador
vlog -sv -work work \
  ./src/hub_modules/multiplier/special_result_for_multiplier.sv \
  ./src/hub_modules/multiplier/FPHUB_mult.sv \
  ./src/hub_modules/multiplier/fpnew_hub_multiplier_wrapper.sv \

# Compilar los módulos de la FPU que dependen de los paquetes
vlog -sv -work work +incdir+$COMMON_CELLS_INC +incdir+$FPU_DIV_SQRT_INC +incdir+$VENDOR_INC +incdir+$VENDOR_INC2 \
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
  ./src/fpnew_top.sv


# Compilar el testbench 1
vlog -sv -work work +incdir+$COMMON_CELLS_INC +incdir+$FPU_DIV_SQRT_INC +incdir+$VENDOR_INC +incdir+$VENDOR_INC2 ./src/tb_fpnew_simple.sv

# Compilar el testbench 2
vlog -sv -work work +incdir+$COMMON_CELLS_INC +incdir+$FPU_DIV_SQRT_INC +incdir+$VENDOR_INC +incdir+$VENDOR_INC2 ./src/tb_fpnew_simple_2.sv