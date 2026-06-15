# Replication guide

## Master 2 thesis — Applied Economics of Development

**Title:** Fiscal consolidations and foreign direct investment in developing
countries: an analysis based on narrative and bilateral data.

**Author:** DIBLONI KOKO CLOVIS
**Date:** 21 August 2025
**Institution:** Université Clermont Auvergne — School of Economics

This document describes how the study can be replicated.

---

## Table of contents

1. [Software used](#software-used)
2. [Project structure](#project-structure)
3. [Data preparation and cleaning](#data-preparation-and-cleaning)
4. [Structure of the replication code](#structure-of-the-replication-code)
5. [Replication instructions](#replication-instructions)
6. [Generated results](#generated-results)
7. [Contact](#contact)

---

## Software used

This project relies on different versions of statistical software. The current
results and tables are all produced with **Stata 18 and RStudio**. All
econometric analyses were performed in Stata 18. The thesis itself was written
in LaTeX.

## Project structure

The main project folder is named `Memoire`. It contains several sub-folders,
each one corresponding to a step in the data processing workflow as well as the
resulting outputs, described below.

## Data preparation and cleaning

### Data

The macroeconomic data used in this study comes from several sources. Raw data
files can be found in the `Brutes/` sub-folder of the `Data/` folder, or you
can refer to the appendix of the thesis where the data source links are
provided.

> **Note on this GitHub repository:** the `Data/` folder is **not** published
> here. Only the code (`Dofile/` and `Code R/`) is. To run the replication,
> obtain the raw data from the sources listed in the thesis appendix and place
> them in a local `Data/Brutes/` folder.

## Structure of the replication code

The main replication file (`Replication.do`) sequentially runs every script
needed to reproduce the results of the thesis. The detailed structure is as
follows:

### Initial setup

The global path must be defined at the beginning of the master script:

```stata
gl path "C:\Users\HP\Desktop\Memoire"
```

### Replication steps

#### 0. Data processing (`00_WDI_DATA.do`)
- Import and clean the data
- Build derived variables
- Merge the different databases

#### 1. Descriptive statistics (`01_Stat_des.do`)
- Generate descriptive statistics
- Build descriptive-statistics tables
- Exploratory data analysis

#### 2. Main regressions (`02_Regression_prin.do`)
- Estimate the main econometric models
- Produce the main results tables

#### 3. Robustness tests (`03_Robustesse.do`)
- Robustness tests with alternative specifications
- Change of clustering level

#### 4. Heterogeneity analysis (`04_Hetergeneite.do`)
- Analysis of heterogeneous effects along different dimensions
- Interaction tests

#### 5. Analysis by income level (`05_Niveau_de_revenu.do`)
- Distinction between low-income, lower-middle-income and upper-middle-income
  countries

#### 6. Analysis by exchange-rate regime (`06_regime.do`)
- Distinction between fixed and flexible exchange-rate regimes

#### 7. Year-by-year regressions (`07_Regression_annee.do`)
- Time analysis of the effects
- Evolution of the coefficients over time

#### 8. Sensitivity to the year (`08_sensibilité_annee.do`)
- Temporal stability tests
- Identifying influential years

#### 9. Sensitivity to countries (`09_Regression_pays.do`)
- Identifying influential countries
- Iterative analysis

#### 10. Preparation for the omitted-variables test (`10_TEST_VAR_OM.do`)
- Data preparation for the omitted-variables tests

#### 11. Omitted-variables test (`11_TEST.do`)
- Formal omitted-variables tests
- Adding additional variables

## Replication instructions

### Requirements
- Stata 18 (or a later version — adjust the `version` line in the do-files if
  needed)
- Access to the databases mentioned above
- Enough disk space for data and results

### Replication steps
1. Download the project files into a local folder
2. Update the global path in the master file (`gl path "your_path"`)
3. Make sure the raw data files are placed in the appropriate sub-folder
4. Run the master file `Replication.do`

### Recommended folder structure

```
Memoire/
├── Dofile/
│   ├── 00_WDI_DATA.do
│   ├── 01_Stat_des.do
│   ├── 02_Regression_prin.do
│   ├── ... (other .do files)
│   ├── Replication.do
├── Data/
│   ├── Brutes/
│   └── Traitees/
├── Resultats/
│   ├── tables/
│   ├── graphes/
├── redaction/
│   └── MEMOIRE_DIBLONI_KOKO_CLOVIS.pdf
└── Code R/
    └── Analyse de données.Rmd
```

The R Markdown file should be executed chunk by chunk.

## Generated results

The replication code produces:
- Descriptive-statistics tables
- Regression-results tables
- Robustness tests
- Figures

## A note on language

Inline comments inside the `.do` files and the `.Rmd` file are still partly in
French (the language in which the thesis was written). Variable names,
commands and outputs are standard.

## Contact

For any question about replicating these results, please contact:

**DIBLONI KOKO CLOVIS** — diblonikokoclovis@gmail.com

---
