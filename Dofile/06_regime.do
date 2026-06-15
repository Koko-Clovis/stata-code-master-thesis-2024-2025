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

log using "$dofile\regime.log", replace

use "$savedata\Final_DATA.dta", clear

********************************************************************************
***              FUSION AVEC LES DONNÉES DE RÉGIME DE CHANGE
********************************************************************************

* Fusion avec les données de régime de change
merge m:1 iso_r year using "$savedata\regime_r.dta", keep(1 3) nogen

* Restriction de l'échantillon temporel
drop if year < 2006 | year >= 2017

********************************************************************************
***            CRÉATION DES VARIABLES D'INTERACTION
********************************************************************************

* Variable binaire pour régime de change fixe
gen Fix_b = 0
replace Fix_b = 1 if regime_r < 4

* Variable de consolidation large
gen Larg_tax = Taxh_r if Taxh_r > 1.5

* Variables d'interaction avec le régime de change
gen Fix_change = Fix_b * Taxh_r
gen Fix_change2 = Fix_b * Larg_tax

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
***         RÉGRESSIONS - RÉGIME DE CHANGE ET CONSOLIDATION
********************************************************************************

* ============================================================================
* AVEC VARIABLES BILATÉRALES
* ============================================================================

* (1) Régression pour consolidation fiscale avec interaction
ppmlhdfe in_Flow_per_r Taxh_r Fix_change $control_jt $control_ij $control_ijt, ///
    vce(cl fepr) absorb(fpt) nolog sep(fe)
eststo ppml_1

* (2) Régression pour large consolidation fiscale avec interaction
ppmlhdfe in_Flow_per_r Larg_tax Fix_change2 $control_jt $control_ij $control_ijt, ///
    vce(cl fepr) absorb(fpt) nolog sep(fe)
eststo ppml_2

* ============================================================================
* AVEC EFFETS FIXES PAIRE-PAYS
* ============================================================================

* (3) Régression pour consolidation fiscale avec interaction
ppmlhdfe in_Flow_per_r Taxh_r Fix_change $control_jt $control_ijt, ///
    vce(cl fepr) absorb(fepr fpt) nolog sep(fe)
eststo ppml_3

* (4) Régression pour large consolidation fiscale avec interaction
ppmlhdfe in_Flow_per_r Larg_tax Fix_change2 $control_jt $control_ijt, ///
    vce(cl fepr) absorb(fepr fpt) nolog
eststo ppml_4

* ============================================================================
* AVEC RÉSISTANCE MULTILATÉRALE
* ============================================================================

* (5) Régression pour consolidation fiscale avec interaction
ppmlhdfe in_Flow_per_r Taxh_r Fix_change $control_jt_MR $control_ijt, ///
    vce(cl fepr) absorb(fepr fpt) nolog sep(fe)
eststo MR_1

* (6) Régression pour large consolidation fiscale avec interaction
ppmlhdfe in_Flow_per_r Larg_tax Fix_change2 $control_jt_MR $control_ijt, ///
    vce(cl fepr) absorb(fepr fpt) nolog sep(fe)
eststo MR_2

********************************************************************************
***              AJOUT DES STATISTIQUES LOCALES
********************************************************************************

foreach var in ppml_1 ppml_2 {
    estadd local fepr = "Non", replace: `var'
    estadd local fpt  = "Oui", replace: `var'
    estadd local controls = "Oui", replace: `var'
}

foreach var in ppml_3 ppml_4 MR_1 MR_2 {
    estadd local fepr = "Oui", replace: `var'
    estadd local fpt  = "Oui", replace: `var'
    estadd local controls = "Oui", replace: `var'
}

********************************************************************************
***              EXPORT DES RÉSULTATS - TABLE RÉGIME DE CHANGE
********************************************************************************

esttab ppml_1 ppml_2 ppml_3 ppml_4 MR_1 MR_2 ///
    using "$tables\PPML_regime2.tex", replace ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    noobs nomtitles eqlabels(none) ///
    stats(fepr fpt controls N r2_p, ///
        fmt(%9.3g) ///
        labels("EF Pair pays" "EF Origine-année" "Variables de contrôle" ///
               "Observations" "Pseudo R\$^2\$")) ///
    drop(_cons $control_jt $control_jt_MR $control_ij $control_ijt) ///
    mgroups("Variables bilatérales" "EF paires" "MR \& EF paires", ///
        pattern(1 0 1 0 1 0) ///
        span ///
        prefix(\multicolumn{@span}{c}{) ///
        suffix(}) ///
        erepeat(\cmidrule(lr){@span})) ///
    style(tex) collabels(, none) nodepvars booktabs ///
    refcat(Fisc_r "\addlinespace[0.3em] \textbf{Variables d'intérêt principales} \\ \addlinespace[0.2em]", nolabel) ///
    prehead("\begin{table}[H]" ///
        "\centering" ///
        "\caption{\textbf{Change Fixe}}" ///
        "\label{tab:PPMLregime2}" ///
        "\scriptsize" ///
        "\resizebox{\textwidth}{!}{" ///
        "\begin{tabular}{l*{6}{c}}" ///
        "\toprule") ///
    postfoot("\bottomrule" ///
        "\end{tabular}}" ///
        "\begin{tablenotes}" ///
        "\footnotesize" ///
        "\item \textit{Notes:} Cette table présente les résultats avec introduction de l'interaction de la binaire (égale 1 si le pays recipienfeprire est en change fixe et 0 sinon) avec les variables d'intérêt consolidation budgétaire et consolidation budgétaire large. Les écart-types entre parenthèses sont clustérisés au niveau paire pays et les coefficients significatifs sont signalés par des étoiles comme suit : " ///
        "\textbf{***} p\textless0,01, \textbf{**} p\textless0,05, et \textbf{*} p\textless0,1." ///
        "\end{tablenotes}" ///
        "\end{table}") ///
    varlabel(Taxh_r "Consolidation budgétaire" ///
        Fix_change "Consolidation × Change fixe" ///
        Larg_tax "Consolidation large" ///
        Fix_change2 "Consolidation large × Change fixe") ///
    order(Taxh_r Fix_change Larg_tax Fix_change2) ///
    legend nonotes noomitted

********************************************************************************
***                           FIN DU SCRIPT
********************************************************************************

log close