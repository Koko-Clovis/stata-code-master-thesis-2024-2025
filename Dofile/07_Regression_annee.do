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
***          DEFINITION DES GLOBAUX
********************************************************************************

local project_dir "C:\Users\HP\Desktop\Memoire"

* Chemins d'accès
global  sourcedata   "`project_dir'\Data\Brutes"
global  savedata     "`project_dir'\Data\Traitees"
global  dofile       "`project_dir'\Dofile"
global  graphs       "`project_dir'\Resultats\graphes"
global  tables       "`project_dir'\Resultats\tables"




log using "$dofile\yearly_regressions.log", replace text

********************************************************************************
***          PREPARATION DES DONNEES
********************************************************************************

use "$savedata\Final_DATA.dta", clear 

* Encodage des variables catégorielles
encode iso_r, gen(iso_r_num)
encode iso_p, gen(iso_p_num)

drop iso_r iso_p
ren iso_r_num iso_r
ren iso_p_num iso_p

egen ID = group(iso_r iso_p)
xtset ID year

* Variables de contrôle
global control_jt fin_dev_r inflation_r access_elec_r res_rents_r gross_debt_r gdp_growth_r remit_gdp_r log_GDP_r Inst_qlt CIT_r
global control_jt_MR fin_dev_r inflation_r access_elec_r res_rents_r gross_debt_r gdp_growth_r remit_gdp_r log_GDP_r Inst_qlt CIT_r MR
global control_ij log_distcap contig comlang_off col45
global control_ijt BIT RTA InstDist

********************************************************************************
***          REGRESSIONS ANNEE PAR ANNEE ET GRAPHIQUES EVENT-STUDY 
********************************************************************************


********************************************************************************
* PREPARATION DES DONNEES POUR LES REGRESSIONS ANNUELLES
********************************************************************************

* Identifier les années disponibles dans les données
quietly levelsof year, local(years)
display "Années disponibles: `years'"

* Initialiser le style graphique
grstyle init
grstyle color background white



********************************************************************************
* BOUCLE SUR LES ANNEES ET STOCKAGE DES ESTIMATIONS - VARIABLE DEPENDANTE: in_Flow_per_r
********************************************************************************

display ""
display "*** REGRESSION ANNEE PAR ANNEE POUR in_Flow_per_r ***"
display ""

foreach yr of local years {
    display "=== Traitement de l'année `yr' ==="
    
    * Compter les observations pour cette année
    quietly count if year == `yr' & !missing(in_Flow_per_r, Fisc_r, Larg_fisc_r)
    local obs_count = r(N)
    
    if `obs_count' < 50 {
        display "Année `yr': Trop peu d'observations (`obs_count'), ignorée"
        continue
    }
    
    * Régression avec Fisc_r pour l'année yr
    capture {
        quietly ppmlhdfe in_Flow_per_r Fisc_r $control_jt $control_ijt if year == `yr', ///
            vce(cl iso_p) nolog d keepsingletons
        
        if _rc == 0 {
            estimates store inflow_per_fisc_`yr'
            display "Année `yr': Fisc_r estimé et stocké (in_Flow_per_r)"
        }
        else {
            display "Année `yr': Erreur dans l'estimation de Fisc_r (in_Flow_per_r)"
        }
    }
    
    * Régression avec Larg_fisc_r pour l'année yr  
    capture {
        quietly ppmlhdfe in_Flow_per_r Larg_fisc_r $control_jt $control_ijt if year == `yr', ///
            vce(cl iso_p) nolog d keepsingletons
        
        if _rc == 0 {
            estimates store inflow_per_larg_`yr'
            display "Année `yr': Larg_fisc_r estimé et stocké (in_Flow_per_r)"
        }
        else {
            display "Année `yr': Erreur dans l'estimation de Larg_fisc_r (in_Flow_per_r)"
        }
    }
}

* Créer la liste des estimations pour in_Flow_per_r
local fisc_estimates_per ""
local larg_estimates_per ""

foreach yr of local years {
    capture estimates dir inflow_per_fisc_`yr'
    if _rc == 0 {
        local fisc_estimates_per "`fisc_estimates_per' (inflow_per_fisc_`yr', label(`yr'))"
    }
    
    capture estimates dir inflow_per_larg_`yr'
    if _rc == 0 {
        local larg_estimates_per "`larg_estimates_per' (inflow_per_larg_`yr', label(`yr'))"
    }
}

********************************************************************************
* CREATION DES GRAPHIQUES INDIVIDUELS
********************************************************************************


* Graphique pour Fisc_r uniquement (in_Flow_per_r)
if "`fisc_estimates_per'" != "" {
    display "Création graphique Fisc_r pour in_Flow_per_r..."
    
    coefplot `fisc_estimates_per', ///
        yline(0, lcolor(black) lpattern(dash)) ///
        keep(Fisc_r) ///
		level(90) ///
        ylabel(, nogrid format(%9.0f)) ///
        xlabel(, nogrid) ///
        mcolor(navy) ciopts(lcolor(navy)) ///
        msymbol(circle) msize(medium) ///
        vertical ///
        graphregion(color(white)) ///
        bgcolor(white) ///
        title("Consolidation budgétaire (% PIB) - IDE % PIB", size(medium)) ///
        subtitle("Coefficients par année avec IC 90%", size(small)) ///
        xtitle("Année", size(medium)) ///
        ytitle("Coefficient estimé", size(medium)) ///
        legend(off) ///
        scheme(s1color) ///
        name(panel_fisc_inflow_per, replace)
    
    graph export "$graphs\coefplot_fisc_inflow_per.jpg", replace width(800) height(600)
    display "Graphique Fisc_r (% PIB) sauvegardé"
}
else {
    display "Aucune estimation Fisc_r (% PIB) disponible"
}

* Graphique pour Larg_fisc_r uniquement (in_Flow_per_r)
if "`larg_estimates_per'" != "" {
    display "Création graphique Larg_fisc_r pour in_Flow_per_r..."
    
    coefplot `larg_estimates_per', ///
        yline(0, lcolor(black) lpattern(dash)) ///
        keep(Larg_fisc_r) ///
		level(90) ///
        ylabel(, nogrid format(%9.0f)) ///
        xlabel(, nogrid) ///
        mcolor(maroon) ciopts(lcolor(maroon)) ///
        msymbol(diamond) msize(medium) ///
        vertical ///
        graphregion(color(white)) ///
        bgcolor(white) ///
        title("Consolidation budgétaire > 1.5% - IDE % PIB", size(medium)) ///
        subtitle("Coefficients par année avec IC 90%", size(small)) ///
        xtitle("Année", size(medium)) ///
        ytitle("Coefficient estimé", size(medium)) ///
        legend(off) ///
        scheme(s1color) ///
        name(panel_larg_inflow_per, replace)
    
    graph export "$graphs\coefplot_larg_inflow_per.jpg", replace width(800) height(600)
    display "Graphique Larg_fisc_r (% PIB) sauvegardé"
}
else {
    display "Aucune estimation Larg_fisc_r (% PIB) disponible"
}

********************************************************************************
* GRAPHIQUE COMBINE FINAL
********************************************************************************

* Combiner tous les graphiques en une seule figure
capture {
    graph combine panel_fisc_inflow_per panel_larg_inflow_per, ///
        rows(1) cols(2) ///
        graphregion(color(white)) ///
        title("Effets des consolidations budgétaires sur les flux d'IDE", size(large)) ///
        subtitle("Analyse année par année (2006-2018)", size(medium)) ///
        note("Note: Barres verticales = intervalles de confiance 90%. Ligne horizontale = référence zéro.", size(vsmall))
    
    if _rc == 0 {
        graph export "$graphs\panels_combined_yearly_effects.jpg", replace width(1600) height(1200)
        graph export "$graphs\panels_combined_yearly_effects.pdf", replace
        display "Graphique combiné sauvegardé avec succès"
    }
    else {
        display "Erreur lors de la création du graphique combiné"
    }
}

********************************************************************************
* AFFICHAGE DES RESULTATS
********************************************************************************

display ""
display "*** RESUME DES GRAPHIQUES GENERES ***"
display "- Graphiques individuels pour chaque variable dans: $graphs"
display "- Panel combiné final: panels_combined_yearly_effects.jpg/pdf"
display ""
display "*** FIN DES REGRESSIONS ANNEE PAR ANNEE (STYLE COEFPLOT) ***"

log close