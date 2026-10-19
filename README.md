# [Evaluating Carotenoids Intake of Pregnant Women: A FFQ-Based Approach to Dietary Patterns](https://www.mdpi.com/2072-6643/18/12/1999)

Code and data for the paper:

> **Evaluating Carotenoids Intake of Pregnant Women: A FFQ-Based Approach to Dietary Patterns**
> Andreea-Maria Mitran, Alina-Delia Popa, Catalin-Mihail Chiru, Cornelia Mircea, Ionut Iulian Lungu, Ioana-Cezara Caba,
> Andreea Lungu, Cristina Arsene, Dumitru Gafitanu, Florina Crivoi, Monica Hancianu, Cristina Elena Dobre, Oana Cioanca
> — *Nutrients* **2026**, 18(12), 1999.
> [https://doi.org/10.3390/nu18121999](https://doi.org/10.3390/nu18121999)

## Overview

Most food frequency questionnaires (FFQs) report preformed vitamin A and total carotenoids. They do not report individual carotenoids such as lycopene, β-cryptoxanthin or lutein + zeaxanthin.
This repository holds the computational workflow the paper uses to estimate individual carotenoid intake from an existing, validated FFQ.

- **Cohort:** a cross-sectional study of **621 pregnant women** admitted for delivery at the Elena Doamna Regional Obstetrics and Gynecology Hospital in Iași, Romania, in 2023.
- **Dietary assessment:** the **EPIC-Norfolk FFQ** (130 food and beverage items), adapted for Romanian populations and processed with FETA (FFQ EPIC Tool for Analysis) food codes.
- **Food composition:** the **USDA FoodData Central** Survey (FNDDS) database, release 2024-10-31.
- **Carotenoid estimation model:**
  1. A nutrition specialist manually matched each unique FFQ food code to one or more USDA entries (201 USDA entries in total).
  2. The nutrients of interest are extracted from USDA (see [Nutrients extracted](#nutrients-extracted)).
  3. When one FFQ item maps to several USDA entries, the nutrient value is the **arithmetic mean** of those entries. For example, watermelon maps to `2709241` and `2709270`.
  4. USDA values are given per 100 g, so they are **scaled by the portion size** reported in the FFQ:

     ```math
     \text{value}_{\text{scaled}} = \frac{\text{value}_{\text{per 100 g}} \times \text{FOOD\_PORTION (g)}}{100}
     ```

  5. The values are **summed per participant** to get daily intake.

The paper's downstream statistics were run in R and will be added later to this repository. They cover dietary patterns from PCA with varimax rotation, the Diet Quality Index during Pregnancy (DQI-P), Spearman correlations, and energy-adjusted linear regressions with Benjamini–Hochberg FDR correction.

### Nutrients extracted

Retinol, Lycopene (total / cis / trans), β-Carotene (total / cis / trans), α-Carotene, β-Cryptoxanthin, Lutein, Zeaxanthin, Lutein + zeaxanthin, cis-Lutein/Zeaxanthin, Vitamin E (α-tocopherol), Tocopherols and tocotrienols, Choline (total), Vitamin K (phylloquinone), Vitamin D (D2 + D3), Vitamin A (RAE).

## Repository structure

```
.
├── 0_exploratory_database.ipynb
├── 1_process_usda_fdc_db_into_multihot_fdc_nutrients.ipynb
├── 2_obtain_nutrient_values_for_iasi_feta.ipynb
├── 3_iasi_results.ipynb
├── run_pipeline.sh            # one-command reproduction of the whole pipeline
├── requirements.txt
└── data/
    ├── FoodData_Central_survey_food_csv_2024-10-31(.zip)   # USDA FDC Survey (FNDDS) release
    ├── FOOD_CODES.csv                      # FETA food codes → descriptions / portions
    ├── MEAL_ID.csv                         # FFQ meal / line-number lookup
    ├── popa2023andreea2013.xlsx            # FFQ responses of the cohort (ID, MEAL_ID, FOOD_CODE, FOOD_PORTION)
    ├── manually_labelled_fdc_to_feta.xlsx  # expert FETA FOOD_CODE → USDA fdc_id(s) matching
    ├── PROCESSED_*.csv / .txt              # outputs produced by the notebooks
    └── artefacts/                          # intermediate / legacy files kept for traceability
```

## Notebooks

Run the notebooks **in order**. Each one reads the files the previous one wrote to `data/`.

<table>
  <tr>
    <th width="3%">#</th>
    <th width="20%">Notebook</th>
    <th width="47%">What it does</th>
    <th width="15%">Inputs</th>
    <th width="15%">Outputs</th>
  </tr>
  <tr>
    <td>0</td>
    <td><code>0_exploratory_database.ipynb</code></td>
    <td>Looks at each table of the USDA FoodData Central Survey release.</td>
    <td><code>data/FoodData_Central_survey_food_csv_2024-10-31/*.csv</code></td>
    <td><code>PROCESSED_fdc_id_description_pairing.csv</code></td>
  </tr>
  <tr>
    <td>1</td>
    <td><code>1_process_usda_fdc_db_into_multihot_fdc_nutrients.ipynb</code></td>
    <td>Cleans <code>food_nutrient</code>, <code>nutrient</code> and <code>food</code>, then merges them into one table of nutrients per food. It checks that every nutrient of interest is present, filters to those nutrients, and pivots the result to one row per <code>fdc_id</code> with one column per nutrient (unit in the column name). It ends with checks against hand-computed values (watermelon, taramasalata).</td>
    <td>USDA CSVs</td>
    <td><code>PROCESSED_nutrients_per_aliment.csv</code><br><code>PROCESSED_nutrient_name_uniques.txt</code><br><code>PROCESSED_filtered_nutrients_multihot.csv</code></td>
  </tr>
  <tr>
    <td>2</td>
    <td><code>2_obtain_nutrient_values_for_iasi_feta.ipynb</code></td>
    <td>Loads the cohort's FFQ answers and joins them with the FETA food codes. It adds the expert FETA → USDA matching and gives every food line its nutrient values, averaging when one food code maps to several USDA entries. Food codes missing from the original FETA table (<code>12012</code>, <code>17046</code>, <code>11130</code>, <code>17045</code>, <code>a1362</code>, <code>a7021</code>, <code>12008</code>, <code>17038</code>, <code>12042</code>) were added from the <a href="https://www.mrc-epid.cam.ac.uk/wp-content/uploads/2023/03/food_code_lookup.pdf">MRC Epidemiology Food Code Lookup</a>.</td>
    <td><code>FOOD_CODES.csv</code><br><code>MEAL_ID.csv</code><br><code>popa2023andreea2013.xlsx</code><br><code>manually_labelled_fdc_to_feta.xlsx</code><br><code>PROCESSED_filtered_nutrients_multihot.csv</code></td>
    <td><code>PROCESSED_needs_fdc_id.csv</code><br><code>PROCESSED_iasi_with_nutrients_raw.csv</code></td>
  </tr>
  <tr>
    <td>3</td>
    <td><code>3_iasi_results.ipynb</code></td>
    <td>Scales the per-100 g nutrient values by <code>FOOD_PORTION</code> (g) and adds them up per participant (<code>ID</code>).</td>
    <td><code>PROCESSED_iasi_with_nutrients_raw.csv</code></td>
    <td><code>PROCESSED_iasi_with_nutrients_scaled_with_food_portion.csv</code> (per food line)<br><code>PROCESSED_iasi_per_patient_nutrient_totals.csv</code> (per participant)</td>
  </tr>
</table>

The final dataset used for the analyses in the paper is
`data/PROCESSED_iasi_with_nutrients_scaled_with_food_portion.csv`. Its per-participant aggregate is
`data/PROCESSED_iasi_per_patient_nutrient_totals.csv`.

## Requirements

- Python **≥ 3.10**. The notebooks were developed with Python 3.12.3.
- `pandas` (≥ 2.2) and `openpyxl`, which reads the `.xlsx` inputs.
- Jupyter, to run the notebooks interactively, or `nbconvert`, to run them headless.
- About 1 GB of RAM. The USDA `food_nutrient.csv` table is the largest input.

All Python dependencies are listed in `requirements.txt`.

## How to run

### Option A — one command

```bash
./run_pipeline.sh
```

The script:

1. creates a virtual environment in `.venv/` and installs `requirements.txt`;
2. makes sure the USDA FoodData Central Survey release is extracted in `data/` (it extracts the bundled
   `.zip`, or downloads it from USDA if the zip is missing);
3. checks that the required input files exist;
4. runs notebooks `0` → `3` with `jupyter nbconvert`.

Afterwards, the regenerated `data/PROCESSED_*` files are in `data/` and the executed copies of the
notebooks are in `executed/`.

You can override these environment variables:

| Variable | Default | Meaning |
|----------|---------|---------|
| `PYTHON` | `python3` | Python interpreter used to create the venv |
| `VENV_DIR` | `.venv` | Virtual-environment directory |
| `OUTPUT_DIR` | `executed` | Where executed notebooks are saved |
| `TIMEOUT` | `1800` | Per-cell execution timeout (seconds) |

Example: `PYTHON=python3.12 ./run_pipeline.sh`. Add `--skip-install` to reuse an existing
environment without reinstalling packages.

### Option B — interactively

```bash
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
jupyter lab        # then run 0 → 1 → 2 → 3 in order
```

Start Jupyter from the repository root, because the notebooks use relative paths (`./data/...`).

## Citation

If you use this code or data, please cite our work:

```bibtex
@article{mitran2026evaluating,
  title={Evaluating Carotenoids Intake of Pregnant Women: A FFQ-Based Approach to Dietary Patterns},
  author={Mitran, Andreea-Maria and Popa, Alina-Delia and Chiru, Catalin-Mihail and Mircea, Cornelia and Lungu, Ionut Iulian and Caba, Ioana-Cezara and Lungu, Andreea and Arsene, Cristina and Gafitanu, Dumitru and Crivoi, Florina and Hancianu, Monica and Dobre, Cristina Elena and Cioanca, Oana},
  journal={Nutrients},
  volume={18},
  number={12},
  pages={1999},
  year={2026},
  publisher={MDPI}
}
```

## License

The code is released under the [MIT License](LICENSE). The USDA FoodData Central data is in the public domain (U.S. Department of Agriculture, Agricultural Research Service).