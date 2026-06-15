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
***                    DÉFINITION DES GLOBAUX
********************************************************************************

local project_dir "C:\Users\HP\Desktop\Memoire"
global sourcedata   "`project_dir'\Data\Brutes"
global savedata     "`project_dir'\Data\Traitees"
global dofile       "`project_dir'\Dofile"
global graphs       "`project_dir'\Resultats\graphes"
global tables       "`project_dir'\Resultats\tables"

log using "$dofile\Stat_des.log", replace

use "$savedata\Final_DATA.dta", clear 

********************************************************************************
***               BASE DE DONNÉES POUR L'ANALYSE EN RÉSEAU
********************************************************************************

preserve
    collapse (sum) in_Flow_per_r, by(iso_r iso_p)
    export delimited using "$savedata\reseau_data.csv", replace
restore

********************************************************************************
***               CRÉATION BASE DE DONNÉES SANS PAYS MP
********************************************************************************

preserve
    * Liste des codes à exclure
    local exclude "AGO DZA NGA GHA CMR COD ZMB GAB ECU COL PER CHL BOL KAZ AZE IDN MNG"
    gen MP = 0
    
    * Supprimer les observations correspondant à ces pays
    foreach code of local exclude {
        replace MP = 1 if iso_r == "`code'"
    }
    
    save "$savedata\Not_MP.dta", replace
restore

********************************************************************************
***                    STATISTIQUES DESCRIPTIVES
********************************************************************************

* Définir les labels des variables
la var in_flow "Flux d'IDE entrants en volume"
la var in_Flow_per_r "Flux d'IDE entrants (\%PIB)"
la var Fisc_r "Consolidation budgétaire"
la var Larg_fisc_r "Consolidation budgétaire>1.5"
la var Taxh_r "Hausse des impôts"
la var Spend_r "Réduction dépenses publiques"
la var fin_dev_r "Développement financier"
la var inflation_r "Taux d'inflation"
la var access_elec_r "Accès à l'électricité"
la var res_rents_r "Rentes des ressources"
la var gross_debt_r "Dette publique brute"
la var gdp_growth_r "Croissance du PIB"
la var remit_gdp_r "Transferts de migrants (\%PIB)"
la var log_GDP_r "Log du PIB"
la var Inst_qlt "Qualité institutionnelle"
la var CIT_r "Impôt sur les sociétés"
la var MR "Résistence multilatérale"
la var log_distcap "Log distance"
la var contig "Contiguïté"
la var comlang_off "Langue officielle commune"
la var col45 "Relation coloniale (post-1945)"
la var BIT "Traité bilatéral d'investissement"
la var RTA "Accord commercial régional"
la var InstDist "Distance institutionnelle"

* Générer le tableau de statistiques descriptives
estpost summarize in_flow in_Flow_per_r Fisc_r Larg_fisc_r Taxh_r Spend_r ///
    fin_dev_r inflation_r access_elec_r res_rents_r gross_debt_r gdp_growth_r ///
    remit_gdp_r log_GDP_r Inst_qlt CIT_r MR log_distcap contig comlang_off ///
    col45 BIT RTA InstDist

* Exporter le tableau en format LaTeX 
esttab using "$tables\statistiques_descriptives.tex", replace ///
    cells("count(fmt(0)) mean(fmt(3)) sd(fmt(3)) min(fmt(3)) max(fmt(3))") ///
    label nonumber ///
    collabels("Obs" "Moyenne" "Écart-type" "Min" "Max") ///
    prehead("\begin{table}[H]" "\centering" "\caption{Statistiques descriptives}" ///
            "\label{tab:tabstat}" "\begin{tabular}{l*{5}{c}}" "\toprule") ///
    prefoot("\bottomrule") ///
    postfoot("\end{tabular}" "\end{table}") ///
    nonotes noobs 

* Afficher le tableau dans la console
esttab, cells("mean(fmt(3)) sd(fmt(3)) min(fmt(3)) max(fmt(3)) count(fmt(0))") ///
    label nonumber title("Statistiques descriptives") ///
    collabels("Moyenne" "Écart-type" "Min" "Max" "Observations") ///
    nonotes noobs

********************************************************************************
***                      MATRICE DE CORRÉLATION
********************************************************************************

* Variables d'intérêt
local vars in_Flow_per_r Larg_fisc_r Fisc_r Taxh_r gross_debt_r ///
           log_GDP_r log_POP_r InstDist res_rents_r remit_gdp_r inflation_r ///
           access_elec_r gdp_growth_r fin_dev_r ///
           RTA log_distcap CIT_r BIT MR

* Matrice de corrélation avec significativité
pwcorr `vars', sig

* Export Excel
putexcel set "$tables\correlation.xlsx", replace
putexcel A1 = matrix(r(C)), names

* Export LaTeX avec rotation à 90 degrés
estpost correlate `vars', matrix listwise
esttab using "$tables\matrice_correlation.tex", replace ///
    unstack label nonumber ///
    title("Matrice de corrélation") ///
    addnote("Note: Corrélations calculées avec suppression listwise des valeurs manquantes") ///
    eqlabels(none) nomtitles booktabs ///
    prehead("\begin{sidewaystable}[htbp]\centering" "\tiny" ///
            "\begin{adjustbox}{width=\textheight,center}") ///
    postfoot("\end{adjustbox}" "\end{sidewaystable}")

********************************************************************************
***                     GRAPHIQUES D'ANALYSE
********************************************************************************

* ============================================================================
* SCATTERPLOTS PAR PAYS
* ============================================================================

preserve
    * Agrégation par pays (iso_r)
    collapse (mean) in_Flow_per_r Fisc_r Larg_fisc_r, by(iso_r)
    
    * Graphique 1: in_Flow_per_r vs Fisc_r (avec restriction aux flux positifs)
    twoway (scatter in_Flow_per_r Fisc_r if in_Flow_per_r >= 0, ///
                   msize(medium) mcolor(navy%70) mlabel(iso_r) ///
                   mlabsize(small) mlabposition(12)) ///
           (lfit in_Flow_per_r Fisc_r if in_Flow_per_r >= 0, lcolor(red)), ///
           name(g1, replace) ///
           xtitle("Consolidation moyenne") ytitle("Flux moyen IDE (\%PIB)") ///
           legend(label(1 "Pays") label(2 "Tendance linéaire"))
    
    * Graphique 2: in_Flow_per_r vs Larg_fisc_r
    twoway (scatter in_Flow_per_r Larg_fisc_r if in_Flow_per_r >= 0, ///
                   msize(medium) mcolor(navy%70) mlabel(iso_r) ///
                   mlabsize(small) mlabposition(12)) ///
           (lfit in_Flow_per_r Larg_fisc_r if in_Flow_per_r >= 0, lcolor(red)), ///
           name(g2, replace) ///
           xtitle("Grande consolidation moyenne") ytitle("Flux moyen IDE (\%PIB)") ///
           legend(label(1 "Pays") label(2 "Tendance linéaire"))
    
    * Combinaison et sauvegarde
    graph combine g1 g2, rows(1) cols(2) 
    graph export "$graphs\scatterplots_consolidation_ide_par_pays.png", replace
restore

* ============================================================================
* GRAPHIQUE PAR NIVEAU DE REVENU
* ============================================================================

preserve
    collapse (mean) mean_ide=in_Flow_per_r, by(income_r)
    
    graph bar mean_ide, over(income_r) ///
          ytitle("Flux IDE moyens (\%PIB)") ///
          b1title("Niveau de revenu des pays") ///
          bar(1, color(navy)) ///
          name(bar_simple, replace)
    
    graph export "$graphs\ide_income.png", replace
restore

* ============================================================================
* ÉVOLUTION TEMPORELLE IDE ET CONSOLIDATION
* ============================================================================

preserve
    * Agrégation par année
    collapse (mean) mean_ide=in_Flow_per_r mean_fisc=Fisc_r mean_larg_fisc=Larg_fisc_r, ///
             by(year)
    
    * Graphique avec deux axes Y (échelles différentes)
    graph twoway (line mean_ide year, yaxis(1) lcolor(navy) ///
                      lwidth(medium) lpattern(solid)) ///
                 (line mean_fisc year, yaxis(2) lcolor(red) ///
                      lwidth(medium) lpattern(dash)), ///
                 ytitle("Flux IDE moyens (\%PIB)", axis(1)) ///
                 ytitle("Consolidation budgétaire moyenne", axis(2)) ///
                 xtitle("Année") ///
                 legend(label(1 "Flux IDE") label(2 "Conso budgétaire")) ///
                 name(evolution_double_axis, replace)
    
    graph export "$graphs\ide_consolidation.png", replace	   
restore

* ============================================================================
* BARRES EMPILÉES PAR ANNÉE
* ============================================================================

preserve
    collapse (sum) total_ide=in_Flow_per_r (mean) mean_fisc=Fisc_r, by(year)
    
    * Création de barres pour IDE et ligne pour consolidation
    graph twoway (bar total_ide year, color(navy%60) barwidth(0.8)) ///
                 (line mean_fisc year, yaxis(2) lcolor(red) lwidth(thick) ///
                      msymbol(circle) mcolor(red)), ///
                 title("IDE totaux et consolidation budgétaire moyenne par année") ///
                 ytitle("IDE totaux (\%PIB)", axis(1)) ///
                 ytitle("Consolidation budgétaire moyenne", axis(2)) ///
                 xtitle("Année") ///
                 legend(label(1 "IDE totaux") label(2 "Consolidation budgétaire")) ///
                 name(evolution_bar_line, replace)
    
    graph export "$graphs\ide_barre.png", replace
restore

* ============================================================================
* IDE MOYENS PAR RÉGION
* ============================================================================

preserve
    * Filtrer les données
    drop if missing(in_Flow_per_r) | missing(adminregion_p)
    keep if inlist(adminregion_r, "EAP", "ECA", "LAC", "MNA", "SAS", "SSA")
    
    * Calculer les IDE moyens par région 
    collapse (mean) ide_moyen=in_Flow_per_r ///
             (count) n_obs=in_Flow_per_r, by(adminregion_p)
    
    * Afficher les statistiques
    list adminregion_p ide_moyen n_obs, separator(0) 
    
    * Créer le graphique en barres
    graph bar ide_moyen, over(adminregion_p, label(angle(45))) ///
        title("IDE moyens émis par région", size(large)) ///
        subtitle("En pourcentage du PIB", size(medium)) ///
        ytitle("IDE moyen (% PIB)") ///
        bar(1, color(navy) lcolor(black)) ///
        note("Source: Fait par l'auteur à partir des données d'étude", size(small)) ///
        scheme(s1mono)
    
    graph export "$graphs\ide_par_dest.png", replace
restore

********************************************************************************
***                           FIN DU SCRIPT
********************************************************************************

log close