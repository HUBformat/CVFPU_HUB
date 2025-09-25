#!/bin/bash

# Define the log file name
LOG_FILE="compilation.log"

# Step 1: Clean up previous simulation files
echo "Running vdel -all..."
vdel -all

# Step 2: Run the compilation and redirect output to the log file.
# The `exit` command is added to automatically quit the Questasim console.
echo "Running vsim compilation..."
vsim -c -do "compile.do" > "$LOG_FILE"

# Step 3: Check for compilation errors in the log file
echo "Checking for errors in the compilation log..."

# Use grep to find lines with error counts.
# We assign `0` as the default value in case grep finds nothing, preventing the error.
ERROR_COUNT=$(grep "Errors: " "$LOG_FILE" | tail -1 | awk '{print $NF}' | sed 's/,//g')
ERROR_COUNT=${ERROR_COUNT:-0}

# Check if the error count is greater than 0
if [ "$ERROR_COUNT" -gt 0 ]; then
  echo "--------------------------------------------------------"
  echo "❌ COMPILACIÓN FALLIDA"
  echo "Se han encontrado $ERROR_COUNT errores. Por favor, revisa el archivo $LOG_FILE para más detalles."
  echo "--------------------------------------------------------"
  # Optional: Uncomment the next line to also print the log content to the console
  # cat "$LOG_FILE"
  exit 1
else
  echo "--------------------------------------------------------"
  echo "✅ COMPILACIÓN EXITOSA"
  echo "La compilación se completó sin errores."
  echo "--------------------------------------------------------"
  exit 0
fi

# Ejecutar simulación
vsim -voptargs=+acc work.tb_fpnew_simple -do "do wave.do; run"