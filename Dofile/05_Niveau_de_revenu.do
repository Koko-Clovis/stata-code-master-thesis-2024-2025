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
***          DEFINITION DES GLOBAUX
********************************************************************************

local project_dir "C:\Users\HP\Desktop\Memoire"

* Globaux
global  sourcedata   "`project_dir'\Data\Brutes"
global  savedata     "`project_dir'\Data\Traitees"
global  dofile       "`project_dir'\Dofile"
global  graphs       "`project_dir'\Resultats\graphes"
global  tables       "`project_dir'\Resultats\tables"

log using "$dofile\reg_niv.log", replace



/////////////////////////

use "$savedata\Final_DATA.dta", clear 


encode iso_r, gen(iso_r_num)
encode iso_p, gen(iso_p_num)

drop iso_r iso_p
ren iso_r_num iso_r
ren iso_p_num iso_p

egen fepr = group(iso_r iso_p)
egen fpt  = group(iso_p year)

egen ID=group(iso_r iso_p)
xtset ID year

gl control_jt fin_dev_r inflation_r access_elec_r res_rents_r  gross_debt_r gdp_growth_r remit_gdp_r log_GDP_r Inst_qlt CIT_r

gl control_jt_MR fin_dev_r inflation_r access_elec_r res_rents_r gross_debt_r gdp_growth_r remit_gdp_r log_GDP_r Inst_qlt CIT_r MR

gl control_ij log_distcap contig comlang_off col45

gl control_ijt BIT RTA InstDist





********************************************************************************
***          REGRESSIONS PAR NIVEAU DE REVENU
********************************************************************************

********************************************************************************
***          TABLEAU : VARIABLE DEPENfeprNTE in_Flow_per_r PAR NIVEAU DE REVENU
********************************************************************************
// ==================== RÉGRESSIONS LIC ====================

* Variables dyadiques 
ppmlhdfe in_Flow_per_r Fisc_r $control_jt $control_ij $control_ijt if income_r == "LIC", vce(cl fepr) absorb(fpt) nolog sep(fe)
eststo LIC1

ppmlhdfe in_Flow_per_r Larg_fisc_r $control_jt $control_ij $control_ijt if income_r == "LIC", vce(cl fepr) absorb(fpt) nolog sep(fe)
eststo LIC2

* Effets fixes paires
ppmlhdfe in_Flow_per_r Fisc_r $control_jt $control_ijt if income_r == "LIC", vce(cl fepr) absorb(fepr fpt) nolog sep(fe)
eststo LIC3

ppmlhdfe in_Flow_per_r Larg_fisc_r $control_jt $control_ijt if income_r == "LIC", vce(cl fepr) absorb(fepr fpt) nolog sep(fe)
eststo LIC4

* Avec résistance multilatérale
ppmlhdfe in_Flow_per_r Fisc_r $control_jt_MR $control_ijt if income_r == "LIC", vce(cl fepr) absorb(fepr fpt) nolog sep(fe)
eststo LIC5

ppmlhdfe in_Flow_per_r Larg_fisc_r $control_jt_MR $control_ijt if income_r == "LIC", vce(cl fepr) absorb(fepr fpt) nolog sep(fe)
eststo LIC6

// ==================== RÉGRESSIONS LMC ====================


* Variables dyadiques 
ppmlhdfe in_Flow_per_r Fisc_r $control_jt $control_ij $control_ijt if income_r == "LMC", vce(cl fepr) absorb(fpt) nolog sep(fe)
eststo LMC1

ppmlhdfe in_Flow_per_r Larg_fisc_r $control_jt $control_ij $control_ijt if income_r == "LMC", vce(cl fepr) absorb(fpt) nolog sep(fe)
eststo LMC2

* Effets fixes paires
ppmlhdfe in_Flow_per_r Fisc_r $control_jt $control_ijt if income_r == "LMC", vce(cl fepr) absorb(fepr fpt) nolog sep(fe)
eststo LMC3

ppmlhdfe in_Flow_per_r Larg_fisc_r $control_jt $control_ijt if income_r == "LMC", vce(cl fepr) absorb(fepr fpt) nolog sep(fe)
eststo LMC4

* Avec résistance multilatérale
ppmlhdfe in_Flow_per_r Fisc_r $control_jt_MR $control_ijt if income_r == "LMC", vce(cl fepr) absorb(fepr fpt) nolog sep(fe)
eststo LMC5

ppmlhdfe in_Flow_per_r Larg_fisc_r $control_jt_MR $control_ijt if income_r == "LMC", vce(cl fepr) absorb(fepr fpt) nolog sep(fe)
eststo LMC6

// ==================== RÉGRESSIONS UMC ====================


* Variables bilaterales
ppmlhdfe in_Flow_per_r Fisc_r $control_jt $control_ij $control_ijt if income_r == "UMC", vce(cl fepr) absorb(fpt) nolog sep(fe)
eststo UMC1

ppmlhdfe in_Flow_per_r Larg_fisc_r $control_jt $control_ij $control_ijt if income_r == "UMC", vce(cl fepr) absorb(fpt) nolog sep(fe)
eststo UMC2

* Effets fixes paires
ppmlhdfe in_Flow_per_r Fisc_r $control_jt $control_ijt if income_r == "UMC", vce(cl fepr) absorb(fepr fpt) nolog sep(fe)
eststo UMC3

ppmlhdfe in_Flow_per_r Larg_fisc_r $control_jt $control_ijt if income_r == "UMC", vce(cl fepr) absorb(fepr fpt) nolog sep(fe)
eststo UMC4

* Avec résistance multilatérale
ppmlhdfe in_Flow_per_r Fisc_r $control_jt_MR $control_ijt if income_r == "UMC", vce(cl fepr) absorb(fepr fpt) nolog sep(fe)
eststo UMC5

ppmlhdfe in_Flow_per_r Larg_fisc_r $control_jt_MR $control_ijt if income_r == "UMC", vce(cl fepr) absorb(fepr fpt) nolog sep(fe)
eststo UMC6

// Ajouter les statistiques sur les effets fixes
foreach var in LIC1 LIC2 LMC1 LMC2 UMC1 UMC2 {
    estadd local fepr = "Non", replace: `var'
    estadd local fpt = "Oui", replace: `var'
	estadd local controls = "Oui", replace: `var'
}

foreach var in LIC3 LIC4 LIC5 LIC6 LMC3 LMC4 LMC5 LMC6 UMC3 UMC4 UMC5 UMC6 {
    estadd local fepr = "Oui", replace: `var'
    estadd local fpt = "Oui", replace: `var'
	estadd local controls = "Oui", replace: `var'
}

// ==================== EXPORT TABLEAU PANNEAU SUPERPOSÉ in_flow ====================
// PANEL A: LIC - Premier tableau avec en-tête complet
esttab LIC1 LIC2 LIC3 LIC4 LIC5 LIC6 ///
    using "$tables\revenu2.tex", replace ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
	cells(b(fmt(3)) se(par fmt(3))) ///
    noobs nomtitles eqlabels(none) ///
    keep(Fisc_r Larg_fisc_r) ///
    stats(N r2_p, fmt(%9.3g) ///
        labels("Observations" "Pseudo R\$^2\$")) ///
    style(tex) collabels(none) nodepvars booktabs plain ///
    varlabel(Fisc_r "Consolidation budgétaire (\% PIB)" ///
        Larg_fisc_r "Consolidation budgétaire > 1.5\%") ///
    nonotes noomitted ///
    prehead("\begin{table}[H] \centering" ///
            "\caption{Effets de la consolidation budgétaire sur les IDE(\%) par niveau de revenu}" ///
            "\label{tab:revenu2}" ///
            "\resizebox{ \textwidth}{!}{\begin{tabular}{l*{6}{c}} \toprule" ///
            "\multicolumn{7}{l}{\textbf{Panel A: Pays à faible revenu (LIC)}} \\") ///
    posthead("\midrule") ///
    prefoot("\midrule") ///
    postfoot("\midrule")



// PANEL B: LMC - Ajouter au fichier existant
esttab LMC1 LMC2 LMC3 LMC4 LMC5 LMC6 ///
    using "$tables\revenu2.tex", append ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    noobs nomtitles eqlabels(none) ///
    keep(Fisc_r Larg_fisc_r) ///
    stats(N r2_p, fmt(%9.3g) ///trai 
        labels("Observations" "Pseudo R\$^2\$")) ///
    nonotes noomitted ///
    varlabel(Fisc_r "Consolifeprtion budgétaire (\% PIB)" ///
        Larg_fisc_r "Consolifeprtion budgétaire > 1.5\%") ///
    prehead("\multicolumn{7}{l}{\textbf{Panel B: Pays à revenu intermédiaire inférieur (LMC)}} \\") ///
    posthead("\midrule") ///
    postfoot("\midrule")

// PANEL C: UMC - Finaliser le tableau
esttab UMC1 UMC2 UMC3 UMC4 UMC5 UMC6 ///
    using "$tables\revenu2.tex", append ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    noobs nomtitles eqlabels(none) ///
    keep(Fisc_r Larg_fisc_r) ///
    stats(fepr fpt controls N r2_p, fmt(%9.3g) ///
        labels("EF Paire pays" "EF Origine-année" "Variables de contrôle" "Observations" "Pseudo R\$^2\$")) ///
    nonotes noomitted ///
    varlabel(Fisc_r "Consolidation budgétaire (\% PIB)" ///
        Larg_fisc_r "Consolidation budgétaire > 1.5\%") ///
    prehead("\multicolumn{7}{l}{\textbf{Panel C: Pays à revenu intermédiaire supérieur (UMC)}} \\") ///
    posthead("\midrule") ///
    postfoot("\bottomrule \end{tabular}} \parbox{\dimexpr \textwidth-4\tabcolsep} {\footnotesize \textit{Notes:} Cette table présente les resultats des analyses par niveau de revenu. Les variables de contrôle incluses feprns toutes les spécifications : Log PIB courant, Rentes de ressources naturelles, Transferts des migrants (\% PIB), Accès à l'électricité, Croissance du PIB, Développement financier, Inflation (\%), Dette publique brute (\% PIB), Qualité des institutions (Moy_6), Taux d'IS, Distance log(capitales), Frontière commune, Langue officielle commune, relation coloniale après 1945, Traité bilatéral d'investissement (BIT), Accord commercial régional, Distance institutionnelle. Les colonnes (5) et (6) incluent la variable Résistance M. Ecart-type clustérisés au niveau paire pays entre parenthèses. * p\$<\$0{,}10, ** p\$<\$0{,}05, *** p\$<\$0{,}01.} \end{table}")
			 

			 
			 
log close