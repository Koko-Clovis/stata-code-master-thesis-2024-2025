clear all
version 18
set memory 2g
set matsize 11000
set max_memory 16g
set maxvar 11000
set segmentsize 1g

// Pour une autre version antérieure, changez simplement la ligne `version 18`
// selon votre version de Stata avant d'exécuter.

set more off
cap log close

********************************************************************************
***                    DÉFINITION DES GLOBAUX
********************************************************************************

local project_dir "C:\Users\HP\Desktop\Memoire"

* Globaux
global sourcedata   "`project_dir'\Data\Brutes"
global savedata     "`project_dir'\Data\Traitees"
global dofile       "`project_dir'\Dofile"
global graphs       "`project_dir'\Resultats\graphes"
global tables       "`project_dir'\Resultats\tables"

log using "$dofile\regression_prin.log", replace

********************************************************************************
***                         RÉGRESSIONS PRINCIPALES
********************************************************************************

use "$savedata\Final_DATA.dta", clear 

********************************************************************************
***                    PRÉPARATION DES DONNÉES
********************************************************************************

* Encodage des variables iso
encode iso_r, gen(iso_r_num)
encode iso_p, gen(iso_p_num)

drop iso_r iso_p
ren iso_r_num iso_r
ren iso_p_num iso_p

* Création des effets fixes
egen fepr = group(iso_r iso_p)
egen fpt  = group(iso_p year)
egen da   = group(iso_r year)

* Variables dérivées de consolidation
gen      Fisc_r_b = 0
replace  Fisc_r_b = 1 if Fisc_r > 1.5
gen Larg_Conso = Fisc_r_b * Fisc_r

* Configuration du panel
egen ID = group(iso_r iso_p)
xtset ID year

* Définition des groupes de variables de contrôle
global control_jt       fin_dev_r inflation_r access_elec_r res_rents_r ///
                        gross_debt_r gdp_growth_r remit_gdp_r log_GDP_r ///
                        Inst_qlt CIT_r

global control_jt_MR    fin_dev_r inflation_r access_elec_r res_rents_r ///
                        gross_debt_r gdp_growth_r remit_gdp_r log_GDP_r ///
                        Inst_qlt CIT_r MR

global control_ij       log_distcap contig comlang_off col45

global control_ijt      BIT RTA InstDist

********************************************************************************
***          RÉGRESSIONS PRINCIPALES - CONSOLIDATION BUDGÉTAIRE
********************************************************************************

* ============================================================================
* AVEC VARIABLES DYADIQUES
* ============================================================================

* (1) Régression pour consolidation fiscale
ppmlhdfe in_Flow_per_r Fisc_r $control_jt $control_ij $control_ijt, ///
    vce(cl da) absorb(fpt) nolog sep(fe)
eststo ppml_1

* (2) Régression pour large consolidation fiscale
ppmlhdfe in_Flow_per_r Larg_Conso $control_jt $control_ij $control_ijt, ///
    vce(cl da) absorb(fpt) nolog sep(fe)
eststo ppml_2

* ============================================================================
* AVEC EFFETS FIXES PAIRE-PAYS
* ============================================================================

* (3) Régression pour consolidation fiscale
ppmlhdfe in_Flow_per_r Fisc_r $control_jt $control_ijt, ///
    vce(cl da) absorb(fepr fpt) nolog sep(fe)
eststo ppml_3

* (4) Régression pour large consolidation fiscale
ppmlhdfe in_Flow_per_r Larg_Conso $control_jt $control_ijt, ///
    vce(cl da) absorb(fepr fpt) nolog sep(fe)
eststo ppml_4

* ============================================================================
* AVEC RÉSISTANCE MULTILATÉRALE
* ============================================================================

* (5) Régression pour consolidation fiscale
ppmlhdfe in_Flow_per_r Fisc_r $control_jt_MR $control_ijt, ///
    vce(cl da) absorb(fepr fpt) nolog sep(fe)
eststo MR_1

* (6) Régression pour large consolidation fiscale
ppmlhdfe in_Flow_per_r Larg_Conso $control_jt_MR $control_ijt, ///
    vce(cl da) absorb(fepr fpt) nolog sep(fe)
eststo MR_2

* ============================================================================
* AJOUT DES STATISTIQUES LOCALES
* ============================================================================

foreach var in ppml_1 ppml_2 {
    estadd local fepr = "Non", replace: `var'
    estadd local fpt  = "Oui", replace: `var'
}

foreach var in ppml_3 ppml_4 MR_1 MR_2 {
    estadd local fepr = "Oui", replace: `var'
    estadd local fpt  = "Oui", replace: `var'
}

* ============================================================================
* EXPORT DES RÉSULTATS - TABLE 1
* ============================================================================

esttab ppml_1 ppml_2 ppml_3 ppml_4 MR_1 MR_2 ///
    using "$tables\rob1.tex", replace ///
    keep(Fisc_r Larg_Conso) /// 
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    noobs nomtitles eqlabels(none) ///
    stats(fepr fpt N r2_p, ///
        fmt(%9.3g) ///
        labels("EF Pair pays" "EF Origine-année" "Observations" "Pseudo R\$^2\$")) ///
    mgroups("Variables Dyadiques" "EF paires" "MR \& EF paires", ///
        pattern(1 0 1 0 1 0) ///
        span ///
        prefix(\multicolumn{@span}{c}{) ///
        suffix(}) ///
        erepeat(\cmidrule(lr){@span})) ///
    style(tex) collabels(, none) nodepvars booktabs ///
    prehead("\begin{table}[H]" ///
        "\centering" ///
        "\caption{\textbf{Effets des consolidations budgétaires sur les flux d'IDE(\%PIB)}}" ///
        "\label{tab:robust1}" ///
        "\tiny" ///
        "\resizebox{\textwidth}{!}{%" ///
        "\begin{tabular}{l*{6}{c}}" ///
        "\toprule") ///
    postfoot("\bottomrule" ///
        "\end{tabular}}%" ///
        "\begin{tablenotes}" ///
        "\footnotesize" ///
        "\item \textit{Notes:} Cette table présente les résultats des régressions avec la variable dépendante flux d'IDE en pourcentage du PIB. Dans les colonnes (1) et (2) nous utilisons respectivement la variable d'intérêt consolidation budgétaire et la consolidation large(supérieur à 1.5\%PIB) avec les variables bilatérales dans les controles et les effets fixes origine années, les colonnes (3) et (4) utilisent les effets fixes origine années et paires pays sans les variables bilatérales, dans les colonnes (5) et (6) Nous reprenons (3) et (4) en ajoutant un proxy de la résistence multilatérale standard. Les écart-types entre parenthèses sont clusterisés au niveau destination année. Les coefficients significatifs sont signalés par des étoiles comme suit : " ///
        "\textbf{***} p\textless0,01, \textbf{**} p\textless0,05, et \textbf{*} p\textless0,1." ///
        "\end{tablenotes}" ///
        "\end{table}") ///
    varlabel(Fisc_r "Consolidation budgétaire (\% PIB)" ///
        Larg_Conso "Consolidation budgétaire \textgreater 1.5\%") ///
    order(Fisc_r larg_Conso) ///
    legend nonotes noomitted

********************************************************************************
***              RÉGRESSIONS - TAXES VERSUS DÉPENSES
********************************************************************************

* ============================================================================
* CRÉATION DES VARIABLES TAXES ET DÉPENSES
* ============================================================================

gen tax_b = 0
replace tax_b = 1 if Taxh_r > 1.5
gen larg_tax = tax_b * Taxh_r

gen spend_b = 0
replace spend_b = 1 if Spend_r > 1.5
gen larg_spend = spend_b * Spend_r

* ============================================================================
* AVEC VARIABLES DYADIQUES
* ============================================================================

* (1) Régression pour taxes
ppmlhdfe in_Flow_per_r Taxh_r $control_jt $control_ij $control_ijt, ///
    vce(cl da) absorb(fpt) nolog sep(fe)
eststo ppml_1

* (2) Régression pour dépenses
ppmlhdfe in_Flow_per_r Spend_r $control_jt $control_ij $control_ijt, ///
    vce(cl da) absorb(fpt) nolog sep(fe)
eststo ppml_2

* ============================================================================
* AVEC EFFETS FIXES PAIRE-PAYS
* ============================================================================

* (3) Régression pour taxes
ppmlhdfe in_Flow_per_r Taxh_r $control_jt $control_ijt, ///
    vce(cl da) absorb(fepr fpt) nolog sep(fe)
eststo ppml_3

* (4) Régression pour dépenses
ppmlhdfe in_Flow_per_r Spend_r $control_jt $control_ijt, ///
    vce(cl da) absorb(fepr fpt) nolog sep(fe)
eststo ppml_4

* ============================================================================
* AVEC RÉSISTANCE MULTILATÉRALE
* ============================================================================

* (5) Régression pour taxes
ppmlhdfe in_Flow_per_r Taxh_r $control_jt_MR $control_ijt, ///
    vce(cl da) absorb(fepr fpt) nolog sep(fe)
eststo MR_1

* (6) Régression pour taxes avec large
ppmlhdfe in_Flow_per_r Taxh_r larg_tax $control_jt_MR $control_ijt, ///
    vce(cl da) absorb(fepr fpt) nolog sep(fe)
eststo MR_2

* (7) Régression pour dépenses
ppmlhdfe in_Flow_per_r Spend_r $control_jt_MR $control_ijt, ///
    vce(cl da) absorb(fepr fpt) nolog sep(fe)
eststo MR_3

* (8) Régression pour dépenses avec large
ppmlhdfe in_Flow_per_r Spend_r larg_spend $control_jt_MR $control_ijt, ///
    vce(cl da) absorb(fepr fpt) nolog sep(fe)
eststo MR_4

* ============================================================================
* AJOUT DES STATISTIQUES LOCALES
* ============================================================================

foreach var in ppml_1 ppml_2 {
    estadd local fepr = "Non", replace: `var'
    estadd local fpt  = "Oui", replace: `var'
    estadd local controls = "Oui", replace: `var'
}

foreach var in ppml_3 ppml_4 MR_1 MR_2 MR_3 MR_4 {
    estadd local fepr = "Oui", replace: `var'
    estadd local fpt  = "Oui", replace: `var'
    estadd local controls = "Oui", replace: `var'
}

* ============================================================================
* EXPORT DES RÉSULTATS - TABLE 2
* ============================================================================

esttab ppml_1 ppml_2 ppml_3 ppml_4 MR_1 MR_2 MR_3 MR_4 ///
    using "$tables\rob2.tex", replace ///
    keep(Taxh_r larg_tax Spend_r larg_spend) ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    noobs nomtitles eqlabels(none) ///
    stats(controls fepr fpt N r2_p, ///
        fmt(%9.3g) ///
        labels("Variables de contrôle" "EF Pair pays" "EF Origine-année" ///
               "Observations" "Pseudo R\$^2\$")) ///
    mgroups("Variables Dyadiques" "EF paires" "MR \& EF paires", ///
        pattern(1 0 1 0 1 0) ///
        span ///
        prefix(\multicolumn{@span}{c}{) ///
        suffix(}) ///
        erepeat(\cmidrule(lr){@span})) ///
    style(tex) collabels(, none) nodepvars booktabs ///
    prehead("\begin{table}[H]" ///
        "\centering" ///
        "\caption{\textbf{Taxes versus Dépenses}}" ///
        "\label{tab:robust2}" ///
        "\scriptsize" ///
        "\resizebox{\textwidth}{!}{" ///
        "\begin{tabular}{l*{8}{c}}" ///
        "\toprule") ///
    postfoot("\bottomrule" ///
        "\end{tabular}}" ///
        "\begin{tablenotes}" ///
        "\footnotesize" ///
        "\item \textit{Notes:} Cette table présente les résultats des régressions avec la variable dépendante flux d'IDE(\%PIB). Dans les colonnes (1) et (2) nous utilisons respectivement la variable d'intérêt consolidation budgétaire par la hausse des impôts et la consolidation la réduction des dépenses avec les variables bilatérales dans les controles et les effets fixes origine années, les colonnes (3) et (4) utilisent les effets fixes origine années et paires pays sans les variables bilatérales, dans les colonnes (5) à (7), nous reprenons (3) et (4) en ajoutant un proxy de la résistence multilatérale standard et dans (6) et (8) on inclut respectivement taxe et depense large au specifications des colonnes (5) et (7). Les écart-types entre parenthèses sont clusterisés au niveau destination années. Les coefficients significatifs sont signalés par des étoiles comme suit : " ///
        "\textbf{***} p\textless0,01, \textbf{**} p\textless0,05, et \textbf{*} p\textless0,1." ///
        "\end{tablenotes}" ///
        "\end{table}") ///
    varlabel(Taxh_r "Hausse taxes" ///
        larg_tax "Taxes larges" ///
        Spend_r "Réduction dépenses" ///
        larg_spend "Dépenses larges") ///
    order(Taxh_r larg_tax Spend_r larg_spend) ///
    legend nonotes noomitted

********************************************************************************
***                           FIN DU SCRIPT
********************************************************************************

log close