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

log using "$dofile\sens_annee.log", replace


******************************** REGRESSION ************************************
********************************************************************************
u "$savedata\Final_DATA.dta", clear 

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


* Analyse de sensibilité : exclusion progressive des années
* Basé sur notre modèle principal
* Régression de référence (toute la période)
display "=== REGRESSION DE REFERENCE (toute la période) ==="
ppmlhdfe in_flow Fisc_r $control_jt $control_ijt , vce(cl fepr) absorb(fepr fpt) nolog d keepsingletons sep(fe)

* Stocker les résultats de référence
matrix coef_ref = e(b)
matrix se_ref = vecdiag(cholesky(diag(vecdiag(e(V)))))
scalar coef_fisc_ref = coef_ref[1,1]
scalar se_fisc_ref = se_ref[1,1]

* Identifier la période d'étude
qui sum year
local debut = r(min)
local fin = r(max)

* Initialiser les matrices pour stocker les résultats
local n_years = `fin' - `debut' + 1
matrix coef_results = J(`n_years'+1, 4, .)
matrix colnames coef_results = year coef lower_ci upper_ci

* Stocker les résultats de référence
matrix coef_results[1,1] = 0  // 0 pour indiquer "toute la période"
matrix coef_results[1,2] = coef_fisc_ref
matrix coef_results[1,3] = coef_fisc_ref - 1.96*se_fisc_ref
matrix coef_results[1,4] = coef_fisc_ref + 1.96*se_fisc_ref

* Exclure chaque année une par une
local row = 2
forvalues annee = `debut'/`fin' {
    display "=== Exclusion année `annee' ==="
    
    quietly {
        ppmlhdfe in_Flow_per_r Fisc_r $control_jt $control_ijt if year != `annee', vce(cl fepr) absorb(fepr fpt) nolog sep(fe)
        
        * Stocker les résultats
        matrix temp_coef = e(b)
        matrix temp_se = vecdiag(cholesky(diag(vecdiag(e(V)))))
        
        matrix coef_results[`row',1] = `annee'
        matrix coef_results[`row',2] = temp_coef[1,1]
        matrix coef_results[`row',3] = temp_coef[1,1] - 1.96*temp_se[1,1]
        matrix coef_results[`row',4] = temp_coef[1,1] + 1.96*temp_se[1,1]
    }
    
    local row = `row' + 1
}

* Convertir la matrice en dataset temporaire pour le graphique
preserve
clear
svmat coef_results, names(col)

* Créer une variable pour l'axe x
gen x_pos = _n
label define x_labels 1 "Référence", modify
forvalues i = 2/`=_N' {
    local annee_label = year[`i']
    label define x_labels `i' "Sans `annee_label'", modify
}
label values x_pos x_labels

* Créer le graphique avec barres d'erreur
twoway (rcap lower_ci upper_ci x_pos, lcolor(navy) lwidth(medium)) ///
       (scatter coef x_pos, mcolor(red) msize(medium) msymbol(circle)), ///
       xlabel(1/`=_N', valuelabel angle(45) labsize(small)) ///
       ylabel(, format(%9.3f) labsize(small)) ///
       ytitle("Coefficient de consolidation", size(medium)) ///
       xtitle("Spécifications", size(medium)) ///
       title("Analyse de sensibilité : Coefficient de la variable consolidation", size(medium)) ///
       subtitle("avec intervalles de confiance à 95%", size(small)) ///
       legend(order(2 "Coefficient" 1 "IC 95%") position(6) rows(1)) ///
       scheme(s2color) ///
       graphregion(color(white)) ///
       plotregion(margin(medium))

* Sauvegarder le graphique
graph export "$graphs\sens_annee.png", replace width(1200) height(800)
graph export "robustesse_coefficients.eps", replace





log close



