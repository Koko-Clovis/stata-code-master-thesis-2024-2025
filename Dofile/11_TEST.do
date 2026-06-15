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

log using "$dofile\regression_prin.log", replace

************ INSTALLATION PPMLHDFE, 

cap ssc install ftools, replace
cap ssc install ppmlhdfe, replace

******************************** REGRESSION ************************************
********************************************************************************
u "$savedata\Final_DATA_test.dta", clear 

egen iso_r_num = group(iso_r)
egen iso_p_num = group(iso_p)

drop iso_r iso_p
ren iso_r_num iso_r
ren iso_p_num iso_p

egen fepr = group(iso_r iso_p)
egen fpt  = group(iso_p year)
egen da   = group(iso_r year)

gen      Fisc_r_b= 0
replace  Fisc_r_b=1 if Fisc_r>1.5
gen Larg_Conso = Fisc_r_b*Fisc_r

egen ID=group(iso_r iso_p)
xtset ID year


gl control_jt fin_dev_r inflation_r access_elec_r res_rents_r  gross_debt_r gdp_growth_r remit_gdp_r log_GDP_r Inst_qlt CIT_r

gl control_jt_MR fin_dev_r inflation_r access_elec_r res_rents_r gross_debt_r gdp_growth_r remit_gdp_r log_GDP_r Inst_qlt CIT_r MR

gl control_ij log_distcap contig comlang_off col45

gl control_ijt BIT RTA InstDist


/////////////////////////////regression
           
// Régressions avec stockage des résultats
eststo o_score: ppmlhdfe in_Flow_per_r Fisc_r overallscore $control_jt_MR $control_ijt, vce(cl fepr) absorb(fepr fpt) nolog sep(fe)  

eststo imf_value: ppmlhdfe in_Flow_per_r Fisc_r imf_value $control_jt_MR $control_ijt, vce(cl fepr) absorb(fepr fpt) nolog sep(fe)

eststo over_imf: ppmlhdfe in_Flow_per_r Fisc_r overallscore imf_value $control_jt_MR $control_ijt, vce(cl fepr) absorb(fepr fpt) nolog sep(fe)

eststo pro_rights: ppmlhdfe in_Flow_per_r Fisc_r propertyrights $control_jt_MR $control_ijt, vce(cl fepr) absorb(fepr fpt) nolog sep(fe)
   
eststo jud_effectiveness: ppmlhdfe in_Flow_per_r Fisc_r judicialeffectiveness $control_jt_MR $control_ijt, vce(cl fepr) absorb(fepr fpt) nolog sep(fe)
    
eststo gov_integrity: ppmlhdfe in_Flow_per_r Fisc_r governmentintegrity $control_jt_MR $control_ijt, vce(cl fepr) absorb(fepr fpt) nolog sep(fe)
    
eststo tax_burden: ppmlhdfe in_Flow_per_r Fisc_r taxburden $control_jt_MR $control_ijt, vce(cl fepr) absorb(fepr fpt) nolog sep(fe)
        
eststo gov_spending: ppmlhdfe in_Flow_per_r Fisc_r governmentspending $control_jt_MR $control_ijt, vce(cl fepr) absorb(fepr fpt) nolog sep(fe)
    
eststo fis_health: ppmlhdfe in_Flow_per_r Fisc_r fiscalhealth $control_jt_MR $control_ijt, vce(cl fepr) absorb(fepr fpt) nolog sep(fe)

eststo bus_freedom: ppmlhdfe in_Flow_per_r Fisc_r businessfreedom $control_jt_MR $control_ijt, vce(cl fepr) absorb(fepr fpt) nolog sep(fe)

eststo lab_freedom: ppmlhdfe in_Flow_per_r Fisc_r laborfreedom $control_jt_MR $control_ijt, vce(cl fepr) absorb(fepr fpt) nolog sep(fe)

eststo mon_freedom: ppmlhdfe in_Flow_per_r Fisc_r monetaryfreedom $control_jt_MR $control_ijt, vce(cl fepr) absorb(fepr fpt) nolog sep(fe)

eststo tra_freedom: ppmlhdfe in_Flow_per_r Fisc_r tradefreedom $control_jt_MR $control_ijt, vce(cl fepr) absorb(fepr fpt) nolog sep(fe)

eststo inv_freedom: ppmlhdfe in_Flow_per_r Fisc_r investmentfreedom $control_jt_MR $control_ijt, vce(cl fepr) absorb(fepr fpt) nolog sep(fe)

eststo fin_freedom: ppmlhdfe in_Flow_per_r Fisc_r financialfreedom $control_jt_MR $control_ijt, vce(cl fepr) absorb(fepr fpt) nolog sep(fe)

// Ajout des statistiques locales pour chaque modèle
foreach var in o_score imf_value over_imf pro_rights jud_effectiveness gov_integrity tax_burden gov_spending fis_health bus_freedom lab_freedom mon_freedom tra_freedom inv_freedom fin_freedom {
	estadd local fepr = "Oui", replace: `var'
	estadd local fpt  = "Oui", replace: `var'
}

// Export du tableau
esttab o_score imf_value over_imf pro_rights jud_effectiveness gov_integrity tax_burden gov_spending fis_health bus_freedom lab_freedom mon_freedom tra_freedom inv_freedom fin_freedom ///
    using "$tables\PPML_test.tex", replace ///
    cells(b(star fmt(3)) se(par fmt(3))) star(* 0.10 ** 0.05 *** 0.01) booktabs ///
    collabels(none) nomtitles nonumber label ///
    stats(N r2_p fepr fpt, ///
          fmt(%9.0g %9.3f %s %s) ///
          labels("Observations" "Pseudo R\$^2\$" "EF Pair pays" "EF Origine-année")) ///
    title("Test de variables omises\label{tab:ppmltest}") ///
    prehead("\begin{table}[htbp]" "\centering" "\caption{@title}" ///
            "\resizebox{\textwidth}{!}{%" ///
            "\begin{tabular}{l*{15}{c}}" ///
            "\toprule" ///
            "& \multicolumn{15}{c}{Variable dépendante : Flux d'IDE entrants (\% PIB)} \\" ///
            "\cmidrule(lr){2-16}" ///
            "& (1) & (2) & (3) & (4) & (5) & (6) & (7) & (8) & (9) & (10) & (11) & (12) & (13) & (14) & (15) \\" ///
            "\midrule") ///
    postfoot("\bottomrule" ///
             "\end{tabular}" ///
             "}" ///
             "\begin{flushleft}" ///
             "\footnotesize" ///
             "\textbf{Notes :} Test de variables omises avec effets fixes pays-pays et destination année ; écarts-types robustes entre parenthèses, clusterisés au niveau paires pays ; ***, ** et * indiquent respectivement une significativité aux niveaux de 1\%, 5\% et 10\%." ///
             "\end{flushleft}" ///
             "\end{table}") ///
    keep(Fisc_r overallscore imf_value propertyrights judicialeffectiveness governmentintegrity taxburden governmentspending fiscalhealth businessfreedom laborfreedom monetaryfreedom tradefreedom investmentfreedom financialfreedom) ///
    order(Fisc_r overallscore imf_value propertyrights judicialeffectiveness governmentintegrity taxburden governmentspending fiscalhealth businessfreedom laborfreedom monetaryfreedom tradefreedom investmentfreedom financialfreedom)
	
	
	
	
log close	