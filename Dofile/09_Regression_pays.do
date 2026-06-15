clear all
version 18
set memory 2g
set matsize 11000
set max_memory 16g
set maxvar 11000
set segmentsize 1g
set more off
cap log close

********************************************************************************
***                    DEFINITION DES GLOBAUX
********************************************************************************
local project_dir "C:\Users\HP\Desktop\Memoire"
global  sourcedata   "`project_dir'\Data\Brutes"
global  savedata     "`project_dir'\Data\Traitees"
global  dofile       "`project_dir'\Dofile"
global  graphs       "`project_dir'\Resultats\graphes"
global  tables       "`project_dir'\Resultats\tables"

log using "$dofile\pays.log", replace


*******************************************************************************
************************* SUPPRIMER LES PAYS **********************************

* importation des données
u "$savedata\Final_DATA.dta", clear

gen wbcode = iso_r
encode iso_r, gen(iso_r_num)
encode iso_p, gen(iso_p_num)
drop iso_r iso_p
rename iso_r_num iso_r
rename iso_p_num iso_p

* Créer les variables de fixed effects
egen fepr = group(iso_r iso_p)
egen fpt  = group(iso_p year)
egen ID   = group(iso_r iso_p)
xtset ID year

* Définir variables de contrôle
global control_jt_MR fin_dev_r inflation_r access_elec_r res_rents_r gross_debt_r gdp_growth_r remit_gdp_r log_GDP_r Inst_qlt CIT_r MR
global control_ijt BIT RTA InstDist


preserve


levelsof wbcode, local(countries)
local counter = 1
local country_names ""
local estimation_names ""


foreach country of local countries {
    local safename = "noreg" + string(`counter')
    quietly ppmlhdfe in_Flow_per_r Fisc_r $control_jt_MR $control_ijt ///
        if wbcode != "`country'", absorb(fepr fpt) ///
        vce(cl fepr) sep(fe)
    estimates store `safename'
    local country_names "`country_names' `country'"
    local estimation_names "`estimation_names' `safename'"
    local counter = `counter' + 1
}

local total_countries = `counter' - 1
local ideal_cols = 14
local num_sections = ceil(`total_countries' / `ideal_cols')

if `total_countries' > `ideal_cols' {
    local remainder = mod(`total_countries', `ideal_cols')
    if `remainder' > 0 & `remainder' <= 2 {
        local cols_per_section = floor(`total_countries' / `num_sections')
        if `cols_per_section' < 6 {
            local cols_per_section = 6
            local num_sections = ceil(`total_countries' / `cols_per_section')
        }
    }
    else {
        local cols_per_section = `ideal_cols'
    }
}
else {
    local cols_per_section = `total_countries'
    local num_sections = 1
}

capture file close mainfile
file open mainfile using "$tables/robustesse_pays.tex", write replace

file write mainfile "\begin{table}[H]" _n
file write mainfile "\centering" _n
file write mainfile "\caption{Robustesse : exclusion itérative de pays}" _n
file write mainfile "\label{tab:exclusion}" _n
file write mainfile "\resizebox{\textwidth}{!}{%" _n
file write mainfile "\begin{tabular}{l*{14}{c}}" _n
file write mainfile "\toprule" _n

forvalues section_num = 1/`num_sections' {
    local start_idx = (`section_num' - 1) * `cols_per_section' + 1
    local end_idx = min(`section_num' * `cols_per_section', `total_countries')
    local current_estimates ""
    local current_countries ""
    
    forvalues i = `start_idx'/`end_idx' {
        local est_name : word `i' of `estimation_names'
        local country_name : word `i' of `country_names'
        local current_estimates "`current_estimates' `est_name'"
        local current_countries "`current_countries' `country_name'"
    }
    
    local num_cols = `end_idx' - `start_idx' + 1
    
    if `section_num' == 1 {
        file write mainfile "& \multicolumn{`num_cols'}{c}{\textbf{Pays exclu}} \\" _n
        file write mainfile "\cmidrule(lr){2-`=`num_cols'+1'}" _n
    }
    else {
        file write mainfile "& \multicolumn{`num_cols'}{c}{\textbf{Pays exclu (suite)}} \\" _n
        file write mainfile "\cmidrule(lr){2-`=`num_cols'+1'}" _n
    }
    
    esttab `current_estimates' using "$tables/temp_section`section_num'.tex", replace ///
        b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
        noobs eqlabels(none) nodepvars nonumbers ///
        stats(N, fmt(%9.0g) labels("Observations")) ///
        mtitles(`current_countries') ///
        style(tex) collabels(, none) fragment ///
        keep(Fisc_r) ///
        prehead("") posthead("") prefoot("") postfoot("") ///
        substitute("Fisc_r" "Consolidation budgétaire") ///
        varwidth(12)
    
    file open tempfile using "$tables/temp_section`section_num'.tex", read
    file read tempfile line
    while r(eof) == 0 {
        local line = subinstr("`line'", "\toprule", "", .)
        local line = subinstr("`line'", "\midrule", "", .)
        local line = subinstr("`line'", "\bottomrule", "", .)
        local line = subinstr("`line'", "\begin{tabular}", "", .)
        local line = subinstr("`line'", "\end{tabular}", "", .)
        
        if "`line'" != "" {
            file write mainfile "`line'" _n
        }
        file read tempfile line
    }
    file close tempfile
    cap erase "$tables/temp_section`section_num'.tex"
    
    if `section_num' < `num_sections' {
        file write mainfile "\addlinespace[0.5em]" _n
    }
}

file write mainfile "\midrule" _n
file write mainfile "\bottomrule" _n
file write mainfile "\end{tabular}" _n
file write mainfile "}%" _n
file write mainfile "\begin{flushleft}" _n
file write mainfile "\footnotesize" _n
file write mainfile "\textbf{Notes :} Ce tableau teste la robustesse de nos résultats principaux en excluant successivement chaque pays de l'échantillon. " _n
file write mainfile "Chaque colonne présente le coefficient de la consolidation obtenu en estimant la régression incluant les resistances multilatérales  " _n
file write mainfile "sur l'échantillon excluant le pays indiqué en en-tête de colonne. " _n
file write mainfile "Écarts-types robustes entre parenthèses, clusterisés au niveau paires pays ; ***, ** et * indiquent respectivement une significativité aux niveaux de 1\%, 5 \% et 10\%." _n
file write mainfile "\end{flushleft}" _n
file write mainfile "\end{table}" _n

file close mainfile
restore





* Créer un graphique montrant la distribution des coefficients
preserve

clear
set obs `total_countries'
gen country_num = _n
gen coeff = .
gen lower_ci = .
gen upper_ci = .

local counter = 1
foreach est of local estimation_names {
    estimates restore `est'
    local coeff = _b[Fisc_r]
    local se = _se[Fisc_r]
    replace coeff = `coeff' in `counter'
    replace lower_ci = `coeff' - 1.96*`se' in `counter'
    replace upper_ci = `coeff' + 1.96*`se' in `counter'
    local counter = `counter' + 1
}

* Graphique avec intervalles de confiance
twoway (rcap lower_ci upper_ci country_num, lcolor(blue)) ///
       (scatter coeff country_num, mcolor(red) msize(small)), ///
       xlabel(, angle(45) labsize(tiny)) ///
       ylabel(, labsize(small)) ///
       ytitle("Coefficient de consolidation budgétaire") ///
       xtitle("Pays exclu (numéroté)") ///
       title("Sensibilité : exclusion itérative des pays") ///
       legend(order(2 "Coefficient" 1 "IC 90%")) ///
       scheme(s1color)

graph export "$graphs/robustesse_pays.png", replace width(1200) height(800)



log close

