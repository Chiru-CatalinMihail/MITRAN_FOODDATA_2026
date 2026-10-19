#!/usr/bin/env bash
# Reproduces the full data-processing pipeline of the paper by executing the
# notebooks in order. Usage: ./run_pipeline.sh [--skip-install]
set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration (override via environment variables)
# ---------------------------------------------------------------------------
PYTHON="${PYTHON:-python3}"                 # Python >= 3.10 (developed on 3.12.3)
VENV_DIR="${VENV_DIR:-.venv}"               # virtual environment location
OUTPUT_DIR="${OUTPUT_DIR:-executed}"        # where executed notebooks are written
TIMEOUT="${TIMEOUT:-1800}"                  # per-cell execution timeout (seconds)
FDC_NAME="FoodData_Central_survey_food_csv_2024-10-31"
FDC_URL="https://fdc.nal.usda.gov/fdc-datasets/${FDC_NAME}.zip"

NOTEBOOKS=(
  0_exploratory_database.ipynb
  1_process_usda_fdc_db_into_multihot_fdc_nutrients.ipynb
  2_obtain_nutrient_values_for_iasi_feta.ipynb
  3_iasi_results.ipynb
)

cd "$(dirname "$0")"

# 1. Python environment
if [[ ! -d "$VENV_DIR" ]]; then
  echo ">> Creating virtual environment in $VENV_DIR"
  "$PYTHON" -m venv "$VENV_DIR"
fi
# shellcheck disable=SC1091
source "$VENV_DIR/bin/activate"
if [[ "${1:-}" != "--skip-install" ]]; then
  echo ">> Installing dependencies"
  pip install --quiet --upgrade pip
  pip install --quiet -r requirements.txt
fi

# 2. USDA FoodData Central (Survey / FNDDS, 2024-10-31 release)
if [[ ! -d "data/$FDC_NAME" ]]; then
  if [[ ! -f "data/$FDC_NAME.zip" ]]; then
    echo ">> Downloading $FDC_NAME.zip"
    curl -fL "$FDC_URL" -o "data/$FDC_NAME.zip"
  fi
  echo ">> Extracting $FDC_NAME.zip"
  "$PYTHON" -m zipfile -e "data/$FDC_NAME.zip" data/
fi

# 3. Required input files
for f in data/FOOD_CODES.csv data/MEAL_ID.csv data/popa2023andreea2013.xlsx \
         data/manually_labelled_fdc_to_feta.xlsx; do
  [[ -f "$f" ]] || { echo "!! Missing required input: $f" >&2; exit 1; }
done

# 4. Execute notebooks in order (each one consumes the previous one's outputs)
mkdir -p "$OUTPUT_DIR"
for nb in "${NOTEBOOKS[@]}"; do
  echo ">> Executing $nb"
  jupyter nbconvert --to notebook --execute "$nb" \
    --output-dir "$OUTPUT_DIR" \
    --ExecutePreprocessor.timeout="$TIMEOUT" \
    --ExecutePreprocessor.kernel_name=python3
done

echo ">> Done. Results in data/PROCESSED_*.csv, executed notebooks in $OUTPUT_DIR/"
