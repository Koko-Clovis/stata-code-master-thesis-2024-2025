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

log using "$dofile\regression_CIT.log", replace

********************************************************************************
***                    ANALYSE D'HÉTÉROGÉNÉITÉ
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

* Configuration du panel
egen ID = group(iso_r iso_p)
xtset ID year

* Définition des groupes de variables de contrôle
global control_jt_MR    fin_dev_r inflation_r access_elec_r res_rents_r ///
                        gross_debt_r gdp_growth_r remit_gdp_r log_GDP_r ///
                        Inst_qlt CIT_r MR

global control_ij       log_distcap contig comlang_off col45

global control_ijt      BIT RTA InstDist

********************************************************************************
***              CRÉATION DES VARIABLES D'INTERACTION
********************************************************************************

* ============================================================================
* INTERACTION AVEC LE TAUX D'IMPOSITION DES SOCIÉTÉS (CIT)
* ============================================================================

gen cor_tax = Fisc_r * CIT_r

* ============================================================================
* INTERACTION AVEC LE NIVEAU DE DETTE
* ============================================================================

gen prod = L1.gross_debt_r

gen deb_bin = 0
replace deb_bin = 1 if prod > 38.1795  // la médiane de la variable gross_debt_r
gen level_deb = deb_bin * Fisc_r

* ============================================================================
* INTERACTION AVEC LES PARADIS FISCAUX
* ============================================================================

gen t_haven = Fisc_r * th_r

* ============================================================================
* INTERACTION AVEC LES RESSOURCES NATURELLES
* ============================================================================

gen res_nat = Fisc_r * Rich

********************************************************************************
***                  RÉGRESSIONS D'HÉTÉROGÉNÉITÉ
********************************************************************************

* ============================================================================
* (1) INTERACTION AVEC LE TAUX D'IMPOSITION DES SOCIÉTÉS
* ============================================================================

ppmlhdfe in_Flow_per_r Fisc_r cor_tax $control_jt_MR $control_ijt, ///
    vce(cl fepr) absorb(fepr fpt) nolog
eststo MR1

* ============================================================================
* (2) INTERACTION AVEC LE NIVEAU DE DETTE
* ============================================================================

ppmlhdfe in_Flow_per_r Fisc_r level_deb $control_jt_MR $control_ijt, ///
    vce(cl fepr) absorb(fepr fpt) nolog sep(fe)
eststo MR2

* ============================================================================
* (3) INTERACTION AVEC LES PARADIS FISCAUX
* ============================================================================

ppmlhdfe in_Flow_per_r Fisc_r t_haven $control_jt_MR $control_ijt, ///
    vce(cl fepr) absorb(fepr fpt) nolog sep(fe)
eststo MR3

* ============================================================================
* (4) INTERACTION AVEC LES RESSOURCES NATURELLES
* ============================================================================

ppmlhdfe in_Flow_per_r Fisc_r res_nat $control_jt_MR $control_ijt, ///
    vce(cl fepr) absorb(fepr fpt) nolog sep(fe)
eststo MR4

********************************************************************************
***              AJOUT DES STATISTIQUES LOCALES
********************************************************************************

foreach var in MR1 MR2 MR3 MR4 {
    estadd local fepr = "Oui", replace: `var'
    estadd local fpt  = "Oui", replace: `var'
    estadd local controls = "Oui", replace: `var'
}

********************************************************************************
***              EXPORT DES RÉSULTATS - TABLE HÉTÉROGÉNÉITÉ
********************************************************************************

esttab MR1 MR2 MR3 MR4 ///
    using "$tables/PPML_HET.tex", replace ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    noobs nomtitles eqlabels(none) ///
    stats(fepr fpt controls N r2_p, ///
        fmt(%9.3g) ///
        labels("EF Pair pays" "EF Origine-année" "Variables de contrôle" ///
               "Observations" "Pseudo R\$^2\$")) ///
    drop(_cons $control_jt $control_jt_MR $control_ijt) ///
    mgroups("CIT" "DEBT" "TAX HAVEN" "NATURAL RES.", ///
        pattern(1 1 1 1 1) ///
        span ///
        prefix(\multicolumn{@span}{c}{) ///
        suffix(}) ///
        erepeat(\cmidrule(lr){@span})) ///
    style(tex) collabels(,none) nodepvars booktabs ///
    refcat(Fisc_r "\addlinespace[0.3em] \textbf{Variables d'intérêt principales} \\ \addlinespace[0.2em]", nolabel) ///
    prehead("\begin{table}[H]" ///
        "\centering" ///
        "\caption{\textbf{Analyse de l'hétérogénéité}}" ///
        "\label{tab:PPMLHET}" ///
        "\scriptsize" ///
        "\resizebox{\textwidth}{!}{" ///
        "\begin{tabular}{l*{4}{c}}" ///
        "\toprule") ///
    postfoot("\bottomrule" ///
        "\end{tabular}}" ///
        "\begin{tablenotes}" ///
        "\footnotesize" ///
        "\item \textit{Notes:} Cette table présente les résultats de nos analyses d'hétérogénéité. La colonne (1) porte sur les taux d'imposition sur les sociétés, la colonne (2) sur le niveau de la dette, la colonne (3) sur les paradis fiscaux, la colonne (4) sur la dotation en ressources naturelles. Les écart-types entre parenthèses sont clusterisés au niveau paire pays et les coefficients significatifs sont signalés par des étoiles comme suit : " ///
        "\textbf{***} p\textless0,01, \textbf{**} p\textless0,05, et \textbf{*} p\textless0,1." ///
        "\end{tablenotes}" ///
        "\end{table}") ///
    varlabel(Fisc_r "Consolidation budgétaire" ///
        cor_tax "Consolidation × CIT" ///
        level_deb "Consolidation × dette" ///
        t_haven "Consolidation × paradis fiscal" ///
        res_nat "Consolidation × ressources naturelles") ///
    order(Fisc_r cor_tax level_deb t_haven res_nat) ///
    legend nonotes noomitted

********************************************************************************
***                           FIN DU SCRIPT
********************************************************************************

log close