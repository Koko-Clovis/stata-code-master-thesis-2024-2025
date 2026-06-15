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

log using "$dofile\log_DATA.log", replace

********************************************************************************
***              BASE DE DONNÉES – CAPB
******************************************************************************
import excel using "$sourcedata\CAPB.xlsx", firstrow clear

* conversion de la base en caractère

/*foreach var of varlist _all {
    cap tostring `var', replace force
} */

* Vérifier les noms des colonnes importées
list in 1
duplicates list country
duplicates drop

* Identifier les colonnes à restructurer
* Parcours les années et garde les variables correspondantes
local vars_to_keep
forvalues num = 2006/2018 {
    local vars_to_keep `vars_to_keep' var`num'
}

keep `vars_to_keep' country
destring var2006-var2018, replace ignore("no data")
drop in 95/96

*replace CAPB =. if CAPB == "no data"
reshape long var, i(country) j(year)
ren var CAPB
*replace CAPB ="" if CAPB == "no data"
*destring CAPB, replace

kountry country , from (other) stuck  //create iso code 
ren _ISO3N code_pays 
kountry code_pays, from(iso3n) to(iso3c)                                 
drop code_pays
ren _ISO3C isocode
order country isocode
tab country if isocode =="" // voir les pays dont l'isocode n'a pas pu être créé


replace isocode = "CHN" if country == "China, People's Republic of"
replace isocode = "HKG" if country == "Hong Kong SAR"
replace isocode = "MKD" if country == "North Macedonia "
replace isocode = "TUR" if country == "Türkiye, Republic of"

drop if isocode == ""
*drop if year < 2006 | year >= 2019 

preserve

ren CAPB       capb_r
ren isocode    iso_r

save "$savedata\CAPB_r.dta", replace

restore

ren CAPB       capb_p
ren isocode    iso_p

save "$savedata\CAPB_p.dta", replace

********************************************************************************
*** BASE DE DONNÉES – REGIME DE CHANGE
********************************************************************************
* Importer le fichier Excel
import excel "$sourcedata/238_data.xlsx", firstrow sheet(Fine) clear

ren Country year
* Sauvegarder les noms de pays dans une liste
ds year, not
local countries `r(varlist)'
drop in 78/1668
drop GN GO GP GQ GR GS GT GU GV GW GX GY GZ HA HB HC HD HE HF HG HH HI HJ HK HL HM HN HO HP HQ HR HS HT HU HV HW HX HY HZ IA IB IC ID IE

* Créer un dataset temporaire avec les noms de pays
preserve
clear
set obs `: word count `countries''
gen country = ""
local i = 1
foreach var of local countries {
    replace country = "`var'" in `i'
    local i = `i' + 1
}

gen id = _n
save temp_countries.dta, replace
restore
* Transposer 
xpose, clear
drop in 1/1
* Merger avec les noms de pays
gen id = _n
merge 1:1 id using temp_countries.dta
drop _merge id

* Renommer les colonnes v* avec les années
forvalues i = 1/77 { 
    local year = 1939 + `i'
    capture rename v`i' year`year'
}

* Reshaper au format long
reshape long year, i(country) j(year_num)
rename year regime

* Nettoyer
drop if missing(country) | missing(regime)
*erase temp_countries.dta

keep country year_num regime
drop if year_num < 2006

ren year_num year

save "$savedata\regimes_panel.dta", replace

use "$savedata\regimes_panel.dta", clear

kountry country , from (other) stuck  //create iso code 
ren _ISO3N code_pays 
kountry code_pays, from(iso3n) to(iso3c)                                 
drop code_pays
ren _ISO3C isocode
order country isocode
tab country if isocode =="" // voir les pays dont l'isocode n'a pas pu être créé


* Mapper les noms vers les codes ISO
replace isocode = "ATG" if country == "AntiguaandBarbuda"
replace isocode = "AZE" if country == "AzerbaijanRepof"
replace isocode = "BRN" if country == "BruneiDarussalam"
replace isocode = "BFA" if country == "BurkinaFaso"
replace isocode = "CPV" if country == "CaboVerde"
replace isocode = "CAF" if country == "CentralAfricanRep"
replace isocode = "CHN" if country == "ChinaPR"
replace isocode = "CIV" if country == "CoteDIvoire"
replace isocode = "CUW" if country == "Curacao"
replace isocode = "DOM" if country == "DominicanRepublic"
replace isocode = "SLV" if country == "ElSalvador"
replace isocode = "GNQ" if country == "EquatorialGuinea"
replace isocode = "GIN" if country == "GN"
replace isocode = "BHR" if country == "KingdomofBahrain"
replace isocode = "KGZ" if country == "KyrgyzRep"
replace isocode = "LAO" if country == "LaoDemRep"
replace isocode = "LIE" if country == "Liechtesntein"
replace isocode = "MKD" if country == "MacedoniaFYR"
replace isocode = "MHL" if country == "MarshallIslands"
replace isocode = "ANT" if country == "NetherlandsAntilles"
replace isocode = "NZL" if country == "NewZealand"
replace isocode = "PNG" if country == "PNG"
replace isocode = "COD" if country == "RepOfCongoDem"
replace isocode = "YEM" if country == "RepOfYemen"
replace isocode = "COG" if country == "RepofCongo"
replace isocode = "SMR" if country == "SanMarino"
replace isocode = "STP" if country == "SaoTomePrincipe"
replace isocode = "SAU" if country == "SaudiArabia"
replace isocode = "SRB" if country == "SerbiaRepof"
replace isocode = "SLE" if country == "SierraLeone"
replace isocode = "SVK" if country == "SlovakRepublic"
replace isocode = "SLB" if country == "SolomonIslands"
replace isocode = "ZAF" if country == "SouthAfrica"
replace isocode = "LKA" if country == "SriLanka"
replace isocode = "KNA" if country == "StKittsandNevis"
replace isocode = "LCA" if country == "StLucia"
replace isocode = "VCT" if country == "StVincentGrenadines"
replace isocode = "SYR" if country == "SyrianArabRep"
replace isocode = "TTO" if country == "TrinidadTobago"
replace isocode = "GBR" if country == "UnitedKingdom"
replace isocode = "USA" if country == "UnitedStates"
replace isocode = "PSE" if country == "WestBankandGaza"

* Vérifier les mappings
tab country if isocode ==""
save "$savedata\regimes_panel.dta", replace

drop country
u "$savedata\regimes_panel.dta", clear

preserve

ren regime       regime_r
ren isocode      iso_r

save "$savedata\regime_r.dta", replace

restore

ren regime       regime_p
ren isocode      iso_p

save "$savedata\regime_p.dta", replace



********************************************************************************
*** BASE DE DONNÉES – CONSOLIDATION BUDGETAIRE
********************************************************************************
import excel using "$sourcedata\Fiscal Consolidation episodes.xlsx", sheet("Fiscal Consolidation Episodes") firstrow clear
drop I
drop in 1288/1289
replace country = "Central Africa Republic" if country =="Central african republic" // Nous corrigeons le nom de la République de la Centrafrique en 2011
replace country = "Macedonia, FYR" if country== "North Macedonia" // pareil pour la Macedonie
replace country = "Guinea-Bissau"  if country== "Guinea Bissau"
//*** On crée le code iso des pays pour pour faciliter la fusion avec les autres bases de données.

ren Largefiscalconsolidation Larg_fisc
ren Fiscalconsolidation      Fisc
ren Taxhikes                 Taxh
ren Spendingcuts             Spend
ren Spendingcutscurrent      Spendcurrent
ren Spendingcutscapital      Spendcapital

*ssc install kountry // installer le package si cela n'est pas encore fait

kountry country , from (other) stuck  
ren _ISO3N country_code 
kountry country_code, from(iso3n) to(iso3c)                                 
drop country_code
ren _ISO3C iso_r
tab country if iso_r =="" // some countries didn't work out  
order country iso_r year

// On crée manuellement pour les pays dont Stata n'a pas pu généré automatiquement 

replace iso_r = "CAF" if country == "Central Africa Republic"
replace iso_r = "CIV" if strpos(country, "Côte") > 0
replace iso_r = "XKX" if country == "Kosovo"
replace iso_r = "COG" if country == "Republic of Congo"

save "$savedata\Fiscal Consolidation episodes.dta", replace

local varlist Larg_fisc Fisc Taxh Spend Spendcurrent Spendcapital
di "`varlist'"
preserve
foreach var of local varlist {
        rename `var' `var'_p
}
ren country country_p
ren iso_r iso_p
save "$savedata\Fiscal_Cons_p.dta", replace

restore

foreach var of local varlist {
        rename `var' `var'_r
}

ren country country_r
save "$savedata\Fiscal_Cons_r.dta", replace

********************************************************************************
*** BASE DE DONNÉES – BANQUE MONDIALE (WDI)
********************************************************************************

* Installation du package si nécessaire
cap ssc install wbopendata, replace

* Importation des indicateurs (1990–2023)
wbopendata, indicator ( ///
    NY.GDP.PCAP.PP.KD; ///  GDP per capita, PPP (constant 2021 international $)
	NY.GDP.MKTP.KD;    ///  GDP (constant 2015 US$)
	NY.GDP.MKTP.CD;    ///  GDP (current US$)
    NE.TRD.GNFS.ZS;    ///  Trade (% of GDP)
    SP.URB.TOTL;       ///  Urban population (total)
    SP.URB.TOTL.IN.ZS; ///  Urban population (% of total population)
    IQ.CPA.ENVR.XQ;    ///  CPIA environmental sustainability rating
    NV.IND.TOTL.ZS;    ///  Industry (% of GDP)
    AG.PRD.LVSK.XD;    ///  Livestock production index
    EG.USE.COMM.FO.ZS; ///  Fossil fuel energy consumption (% of total)
    GE.EST;            ///  Government Effectiveness
    RL.EST;            ///  Rule of Law: Estimate
    RQ.EST;            ///  Regulatory Quality: Estimate
    CC.EST;             ///  Control of Corruption: Estimate
    SP.POP.TOTL;       ///  Population, total
    EN.POP.DNST;       ///  Population density
    EG.FEC.RNEW.ZS;    ///  Renewable energy consumption
    EG.ELC.ACCS.ZS;    ///  Access to electricity
    EG.ELC.ACCS.RU.ZS; ///  Rural access to electricity
    FP.CPI.TOTL.ZG;    ///  Inflation 
    GC.TAX.TOTL.GD.ZS; ///  Tax revenue (% of GDP)
    GC.TAX.YPKG.ZS;    ///  Taxes on income (% of tax revenue)
    GC.TAX.INTT.RV.ZS; ///  Taxes on international trade (% of tax revenue)
	VA.EST;           ///  Voice and Accountability: Estimate
    PV.EST;            ///  Political Stability and Absence of Violence: Estimate
    SE.SEC.ENRR;       ///  Secondary gross enrollment ratio
    SE.SEC.NENR;       ///  Secondary net enrollment ratio
    NY.GDP.TOTL.RT.ZS;  ///  Natural resources rents (% of GDP)
    BX.TRF.PWKR.DT.GD.ZS; /// Remittances (% of GDP)
	NY.GDP.MKTP.KD.ZG; ///        GDP growth (%)
    FM.LBL.BMNY.GD.ZS; ///       Liquidité M2
	FS.AST.PRVT.GD.ZS; ///        Domestic credit (% GDP)
    EG.USE.ELEC.KH.PC; ///        Electric power consumption (kWh per capita)
	PX.REX.REER;    ///     Real effective exchange rate index (2010 = 100)
	PA.NUS.FCRF;     ///   Official exchange rate (LCU per US$, period average)
	SL.UEM.TOTL.ZS;  ///  Unemployment, total (% of total labor force)
	NY.GDP.DEFL.ZS   ///  GDP deflator (base year varies by country)
) clear long full year(1990:2023)


* Vérification initiale
*br

********************************************************************************
*** RENOMMAGE et ÉTIQUETAGE DE VARIABLES
********************************************************************************

* RENOMMAGE et ÉTIQUETAGE avec vos noms de variables réels

ren ny_gdp_pcap_pp_kd          gdpcap_ppp
la variable gdpcap_ppp         "GDP per capita, PPP (constant 2021 international $)"

rename ny_gdp_mktp_kd          GDP_const2015
la variable GDP_const2015      "GDP (constant 2015 US$)"

rename ny_gdp_mktp_cd          GDP_current
label variable GDP_current     "GDP (Current US$)"

ren ne_trd_gnfs_zs             trade_gdp
la variable trade_gdp          "Trade (% of GDP)"

ren sp_urb_totl                urban_pop
la variable urban_pop          "Urban population (total)"

ren sp_urb_totl_in_zs          urban_pct
la variable urban_pct          "Urban population (% of total population)"

ren iq_cpa_envr_xq             cpiainst_env
la variable cpiainst_env       "CPIA policy and institutions for environmental sustainability rating (1=low to 6=high)"

ren nv_ind_totl_zs             ind_va_gdp
la variable ind_va_gdp         "Industry (including construction), value added (% of GDP)"

ren ag_prd_lvsk_xd            livestock_index
la variable livestock_index   "Livestock production index (2014–2016 = 100)"

ren eg_use_comm_fo_zs         fossil_fuel_cons
la variable fossil_fuel_cons  "Fossil fuel energy consumption (% of total)"

ren ge_est                    gov_eff
la variable gov_eff           "Government Effectiveness: Estimate"

ren rl_est                    rule_law
la variable rule_law          "Rule of Law: Estimate"

ren rq_est                    reg_quality
la variable reg_quality       "Regulatory Quality: Estimate"

ren cc_est                    ctrl_corr
la variable ctrl_corr         "Control of Corruption: Estimate"

ren sp_pop_totl               pop_total
la variable pop_total         "Population, total"

ren en_pop_dnst               pop_density
la variable pop_density       "Population density (people per sq. km of land area)"

ren eg_fec_rnew_zs            renew_energy_cons
la variable renew_energy_cons "Renewable energy consumption (% of total final energy consumption)"

ren eg_elc_accs_zs            access_elec
la variable access_elec       "Access to electricity (% of population)"

ren eg_elc_accs_ru_zs         access_elec_rural
la variable access_elec_rural "Access to electricity, rural (% of rural population)"

ren fp_cpi_totl_zg            inflation
la variable inflation         "Inflation, consumer prices (annual %)"

*ren gc_dod_totl_gd_zs         debt_gdp
*la variable debt_gdp          "Central government debt, total (% of GDP)"

ren gc_tax_totl_gd_zs         tax_rev_gdp
la variable tax_rev_gdp       "Tax revenue (% of GDP)"

ren gc_tax_ypkg_zs            tax_income_prop
la variable tax_income_prop   "Taxes on income, profits and capital gains (% of total tax revenue)"

ren gc_tax_intt_rv_zs         tax_trade
la variable tax_trade         "Taxes on international trade (% of total tax revenue)"

ren va_est                    voice_acc
la variable voice_acc         "Voice and Accountability: Estimate"

ren pv_est                    stab_viol
la variable stab_viol         "Political Stability and Absence of Violence:Estimate"

ren se_sec_enrr               sec_enroll_gross
la variable sec_enroll_gross  "Secondary gross enrollment ratio (% of relevant age group)"

ren se_sec_nenr               sec_enroll_net
la variable sec_enroll_net    "Secondary net enrollment ratio (% of school-age children)"

ren ny_gdp_totl_rt_zs         res_rents
la variable res_rents         "Natural resources rents (% of GDP)"

ren bx_trf_pwkr_dt_gd_zs      remit_gdp
la variable remit_gdp         "Remittances received (% of GDP)"

ren ny_gdp_mktp_kd_zg         gdp_growth
la variable gdp_growth        "GDP growth (annual %)"

ren fs_ast_prvt_gd_zs         fin_dev 
la variable fin_dev           "Domestic credit to private sector (% of GDP)"

ren fm_lbl_bmny_gd_zs         fin_dev_M2
la variable fin_dev_M2        "Liquidité"

ren eg_use_elec_kh_pc         elec_consump
la variable elec_consump      "Electricity consumption (kWh per capita)"

ren px_rex_reer               real_ex_rate
la variable real_ex_rate      "Real effective exchange rate index"

ren pa_nus_fcrf               nominal_ex_rate
la variable nominal_ex_rate   "Nominal effective exchange rate"

ren sl_uem_totl_zs            taux_chom
la variable  taux_chom        "Unemployment, total (% of total labor force)"

ren ny_gdp_defl_zs            deflat
la variable  deflat           "GDP deflator (base year varies by country)"
 

*drop if incomelevelname =="High income"
drop if region=="NA"|region==""
ren countrycode iso_r
order iso_r countryname year
drop if year < 2006 | year >= 2019

*******deflater en prix constant 2015
gen double def2015 = deflat if year == 2015
bysort iso_r: egen def2015_filled = max(def2015)
gen double deflat2015 = (deflat / def2015_filled) * 100
la variable deflat2015 "GDP deflator (2015=100)"

drop def2015 def2015_filled


save "$savedata\variables_de_controles.dta", replace
*/
//***************************** CREATION DES DONNEES D'ORIGINE ET DESTINATION

*************** variable debt de base de données fiscal space
u "$sourcedata\Fiscal_space_data.dta", clear

keep ccode year ggdy
ren ccode iso_r
ren ggdy gross_debt

save "$savedata\Var_debt.dta", replace

///////////////////////////

u "$savedata\variables_de_controles.dta", clear

local varlist2 region regionname adminregion adminregionname incomelevel incomelevelname lendingtype lendingtypename gdpcap_ppp GDP_const2015 GDP_current trade_gdp urban_pop urban_pct cpiainst_env ind_va_gdp livestock_index fossil_fuel_cons gov_eff rule_law reg_quality ctrl_corr pop_total pop_density renew_energy_cons access_elec access_elec_rural inflation tax_rev_gdp tax_income_prop tax_trade voice_acc stab_viol sec_enroll_gross sec_enroll_net res_rents remit_gdp gdp_growth fin_dev elec_consump real_ex_rate nominal_ex_rate gross_debt taux_chom deflat deflat2015
di "`varlist2'"

//////////////////////// Merger avec la variable de la dette en %PIB

merge 1:1 iso_r year using "$savedata\Var_debt.dta", keep(1 3) nogen

preserve
foreach var of local varlist2 {
        rename `var' `var'_p
}
ren country country_p
ren iso_r iso_p
save "$savedata\control_var_p.dta", replace 

restore

foreach var of local varlist2 {
        rename `var' `var'_r
}

ren country country_r
save "$savedata\control_var_r.dta", replace 


//********************************** MERGE DATA
u "$sourcedata\H_Bilateral FDI Database_2022.dta",clear
keep if iso_r=="AFG" | iso_r=="AGO" | iso_r=="ALB" | iso_r=="ARG" | iso_r=="ARM" | iso_r=="AZE" | iso_r=="BDI" | iso_r=="BEN" | iso_r=="BFA" | iso_r=="BGD" | iso_r=="BIH" | iso_r=="BLR" | iso_r=="BLZ" | iso_r=="BOL" | iso_r=="BRA" | iso_r=="BTN" |iso_r=="BWA" | iso_r=="CAF" | iso_r=="CHL" | iso_r=="CHN" | iso_r=="CIV" | iso_r=="CMR" | iso_r=="COD" | iso_r=="COG" |iso_r=="COL" | iso_r=="CPV" | iso_r=="CRI" | iso_r=="DJI" |iso_r=="DOM" | iso_r=="DZA" | iso_r=="ECU" | iso_r=="EGY" |iso_r=="ETH" | iso_r=="GAB" | iso_r=="GEO" | iso_r=="GHA" | iso_r=="GIN" | iso_r=="GMB" | iso_r=="GNB" | iso_r=="GTM" |iso_r=="GUY" | iso_r=="HND" | iso_r=="IDN" | iso_r=="IND" | iso_r=="IRQ" | iso_r=="JOR" | iso_r=="KAZ" | iso_r=="KEN" | iso_r=="KGZ" | iso_r=="KHM" | iso_r=="LBN" | iso_r=="LBR" | iso_r=="LKA" | iso_r=="LSO" | iso_r=="MAR" | iso_r=="MDA" | iso_r=="MDG" | iso_r=="MEX" | iso_r=="MKD" | iso_r=="MLI" |iso_r=="MMR" | iso_r=="MNE" | iso_r=="MNG" | iso_r=="MOZ" | iso_r=="MRT" | iso_r=="MWI" | iso_r=="NAM" | iso_r=="NER" | iso_r=="NGA" | iso_r=="NIC" | iso_r=="NPL" | iso_r=="PAK" |iso_r=="PAN" | iso_r=="PER" | iso_r=="PHL" | iso_r=="PNG" | iso_r=="PRY" | iso_r=="RWA" | iso_r=="SDN" | iso_r=="SEN" |  iso_r=="SLE" | iso_r=="SLV" | iso_r=="SRB" | iso_r=="SWZ" |iso_r=="TCD" | iso_r=="TGO" | iso_r=="THA" | iso_r=="TJK" |iso_r=="TLS" | iso_r=="TUN" | iso_r=="TZA" | iso_r=="UGA" |iso_r=="URY" | iso_r=="VNM" | iso_r=="XKX" | iso_r=="YEM" |iso_r=="ZAF" | iso_r=="ZMB" | iso_r=="ZWE"

keep if iso_p=="AFG" | iso_p=="AGO" | iso_p=="ALB" | iso_p=="ARG" | iso_p=="ARM" | iso_p=="AZE" | iso_p=="BDI" | iso_p=="BEN" | iso_p=="BFA" | iso_p=="BGD" | iso_p=="BIH" | iso_p=="BLR" | iso_p=="BLZ" | iso_p=="BOL" | iso_p=="BRA" | iso_p=="BTN" |iso_p=="BWA" | iso_p=="CAF" | iso_p=="CHL" | iso_p=="CHN" | iso_p=="CIV" | iso_p=="CMR" | iso_p=="COD" | iso_p=="COG" |iso_p=="COL" | iso_p=="CPV" | iso_p=="CRI" | iso_p=="DJI" |iso_p=="DOM" | iso_p=="DZA" | iso_p=="ECU" | iso_p=="EGY" |iso_p=="ETH" | iso_p=="GAB" | iso_p=="GEO" | iso_p=="GHA" | iso_p=="GIN" | iso_p=="GMB" | iso_p=="GNB" | iso_p=="GTM" |iso_p=="GUY" | iso_p=="HND" | iso_p=="IDN" | iso_p=="IND" | iso_p=="IRQ" | iso_p=="JOR" | iso_p=="KAZ" | iso_p=="KEN" | iso_p=="KGZ" | iso_p=="KHM" | iso_p=="LBN" | iso_p=="LBR" | iso_p=="LKA" | iso_p=="LSO" | iso_p=="MAR" | iso_p=="MDA" | iso_p=="MDG" | iso_p=="MEX" | iso_p=="MKD" | iso_p=="MLI" |iso_p=="MMR" | iso_p=="MNE" | iso_p=="MNG" | iso_p=="MOZ" | iso_p=="MRT" | iso_p=="MWI" | iso_p=="NAM" | iso_p=="NER" | iso_p=="NGA" | iso_p=="NIC" | iso_p=="NPL" | iso_p=="PAK" |iso_p=="PAN" | iso_p=="PER" | iso_p=="PHL" | iso_p=="PNG" | iso_p=="PRY" | iso_p=="RWA" | iso_p=="SDN" | iso_p=="SEN" |  iso_p=="SLE" | iso_p=="SLV" | iso_p=="SRB" | iso_p=="SWZ" |iso_p=="TCD" | iso_p=="TGO" | iso_p=="THA" | iso_p=="TJK" |iso_p=="TLS" | iso_p=="TUN" | iso_p=="TZA" | iso_p=="UGA" |iso_p=="URY" | iso_p=="VNM" | iso_p=="XKX" | iso_p=="YEM" |iso_p=="ZAF" | iso_p=="ZMB" | iso_p=="ZWE"

replace name_r = "Macedonia, FYR" if name_r == "North Macedonia"
drop if year < 2006 | year >= 2019

* Créer un identifiant de groupe
egen dup_id = group(year iso_r iso_p)

* Marquer comme doublon si le groupe apparaît plus d'une fois
bysort dup_id: gen dup = cond(_N > 1, 1, 0)

drop if update==0 & dup ==1

save "$sourcedata\H_Bilateral FDI Database_2022_r.dta", replace


*use "$sourcedata\H_Bilateral FDI Database_2022.dta",clear

foreach var in in_flow out_flow in_stock out_stock {
replace `var'=0 if `var'<0	
}


*** Cylindrer la base de données

fillin iso_p iso_r year
drop _fillin
drop if iso_p == iso_r
drop th_r th_p


foreach var in in_flow out_flow in_stock out_stock {
replace `var'=0 if `var'==.	
}
save "$sourcedata\H_Bilateral FDI Database_2022_fill.dta", replace
preserve
u "$sourcedata\H_Bilateral FDI Database_2022.dta",clear
keep iso_r year th_r
duplicates drop iso_r year,force
save "$sourcedata\H_Bilateral FDI Database_2022_thr.dta", replace
restore

u "$sourcedata\H_Bilateral FDI Database_2022_fill.dta",clear
merge m:1 iso_r year using "$sourcedata\H_Bilateral FDI Database_2022_thr.dta", keep(1 3) nogen

preserve
u "$sourcedata\H_Bilateral FDI Database_2022.dta",clear
keep iso_p year th_p
duplicates drop iso_p year,force
save "$sourcedata\H_Bilateral FDI Database_2022_thp.dta", replace
restore

merge m:1 iso_p year using "$sourcedata\H_Bilateral FDI Database_2022_thp.dta", keep(1 3) nogen

// 88,210/126,126  = 69.94% les zeros générés pour inflow represente 69.94% de la taille de l'echantillon
// 88,220/126,126  = 69.95% les zeros générés pour outflow represente 69.95% de la taille de l'echantillon
// 80,437/126,126 = 63.78% les zeros générés pour instock represente 63.78% de la taille de l'echantillon
// 80,457/126,126  = 63,79% les zeros générés pour outstock represente 63,79% de la taille de l'echantillon

save "$savedata\Final_FDI.dta", replace

*/****** Ajout du binaire pour les paradis fiscaux
u "$sourcedata\H_Bilateral FDI Database_2022_r.dta", clear

keep iso_r iso_p year th_r th_p

preserve
collapse (mean) th_r, by(iso_r)
save "$savedata\th_r.dta",replace

restore
collapse (mean) th_p, by(iso_p)

ren iso_p iso_r
merge 1:1 iso_r using "$savedata\th_r.dta"

drop if _merge == 1
drop _merge
ren iso_r iso_p

save "$savedata\th_p.dta", replace


///////////////// Avec Final_FDI

u "$savedata\Final_FDI.dta",clear

merge m:1 iso_r using "$savedata\th_r.dta"

drop if _merge == 1
drop _merge

merge m:1 iso_p using "$savedata\th_p.dta"
drop _merge

save "$savedata\Final_FDI.dta", replace
*/
***************************************************************************** 
****        MERGE FDI AVEC FISCAL CONSOLIDATION
******************************************************************************
u "$savedata\Final_FDI.dta", clear

merge m:1 iso_r year using "$savedata\Fiscal_Cons_r.dta", keep(1 3) nogen

merge m:1 year iso_p using "$savedata\Fiscal_Cons_p.dta", keep(1 3) nogen


*************************** WITH CONTROL VARIABLES

merge m:1 year iso_r using "$savedata\control_var_r", keep(1 3) nogen

merge m:1 year iso_p using "$savedata\control_var_p", keep(1 3) nogen

drop name_p name_r income_r income_p source_out_flow source_in_stock source_out_stock source_economy_in_flow source_economy_out_flow source_economy_in_stock source_economy_out_stock income_r region_r region_p update

ren country_p name_p
ren country_r name_r
ren incomelevel_r income_r
ren incomelevel_p income_p

*Suprimer les pays qui ont assez de données manquées pour les PIB dû aux conflits
/*
drop if name_r == "Yemen" 
drop if name_r == "Djibouti"
*drop if name_r == "Algeria"
drop if name_p == "Yemen"  
drop if name_p == "Djibouti"
*drop if name_p == "Algeria"
*/
//****************

*drop if iso_r == "LSO"
*drop if iso_p == "LSO"

order iso_p name_p iso_r name_r year th_r th_p  in_flow out_flow in_stock out_stock

replace income_r = "UMC" if iso_r == "ARG"
replace income_p = "UMC" if iso_p == "ARG"

replace income_r = "UMC" if iso_r == "CHL"
replace income_p = "UMC" if iso_p == "CHL"

replace income_r = "UMC" if iso_r == "URY"
replace income_p = "UMC" if iso_p == "URY"

replace income_r = "UMC" if iso_r == "PAN"
replace income_p = "UMC" if iso_p == "PAN"
 

order iso_r name_r iso_p name_p year
sort iso_r year


generate inflow_def = in_flow * 100 / deflat2015_r     // IDE réel
gen in_Flow_per_r = (inflow_def*1000000)*100/GDP_const2015_r	


*gen in_Flow_per_r = (in_flow*1000000)*100/GDP_const2015_r

*gen in_Flow_per_r = (in_flow*100000000)/GDP_current_r

gen log_GDP_r   = log(GDP_const2015_r)
gen log_GDP_p   = log(GDP_const2015_p)
 
gen log_POP_r   = log(pop_total_r) // Pas de zeros Min = 4.54e+08 
gen log_POP_p   = log(pop_total_p)

egen Inst_qlt = rowmean(gov_eff_r rule_law_r reg_quality_r ctrl_corr_r voice_acc_r stab_viol_r)

****/////////////////////////////CALCUL DE LA DISTANCE INSTITUTIONNELLE

egen meam_gov_r = rowmean(voice_acc_r stab_viol_r gov_eff_r rule_law_r reg_quality_r ctrl_corr_r)

egen meam_gov_p = rowmean(voice_acc_p stab_viol_p gov_eff_p rule_law_p reg_quality_p ctrl_corr_p)

****Calcul de la distance institutionnelle
gen InstDist = abs(meam_gov_r - meam_gov_p)
drop meam_gov_r meam_gov_p


*-------------------------------------------------------*
* Changer le format d'affichage de TOUTES les variables numeriques
* en %9.0g (notation compacte, max 9 caractères, pas de décimales)
*-------------------------------------------------------*

// Boucle sur toutes les variables de la base
/*/ Sélectionner uniquement les variables numériques
ds, has(type numeric)
local numvars `r(varlist)'

// Appliquer le format %9.0g à chacune
foreach v of local numvars {
    format `v' %9.0g
}

*/

save "$savedata\Final_DATA.dta", replace


/////////////////////////// DONNEES ORIGINE DESTINATION

use "$sourcedata\Gravity_V202211.dta", clear


keep year country_id_o country_id_d distw_harmonic distw_arithmetic dist distcap contig diplo_disagreement comlang_off comlang_ethno comcol col45 legal_old_o legal_old_d legal_new_o legal_new_d comleg_pretrans comleg_posttrans transition_legalchange comrelig fta_wto fta_wto_raw

drop if year < 2006 | year >= 2019 

ren country_id_d iso_r
ren country_id_o iso_p
ren fta_wto       RTA

duplicates drop iso_p iso_r year, force
drop if iso_p == iso_r
ren distw_harmonic distw

save "$savedata\CEPII_data.dta", replace

//////////////// merge avec Final_DATA

u "$savedata\Final_DATA.dta", clear

merge 1:1 iso_r iso_p year using "$savedata\CEPII_data.dta", keep(1 3) nogen

order name_r iso_r name_p  iso_p year 
save "$savedata\Final_DATA.dta", replace


//////////// VARIABLE CORPORATE INCOME TAXE and BIT

u "$sourcedata\corporatetax_taxfoundation.dta", clear

keep ccode_dest year tax_rate
drop if year < 2006 | year >= 2019 
ren ccode_dest isocode
ren tax_rate CIT

preserve

ren CIT       CIT_r
ren isocode    iso_r

save "$savedata\CIT_r.dta", replace

restore

ren CIT       CIT_p
ren isocode    iso_p

save "$savedata\CIT_p.dta", replace

/////////////// VARIABLE BIT

u "$sourcedata\BIT2020new_full.dta", clear

ren ccode_dest iso_r
ren ccode_scr  iso_p

save "$savedata\BIT.dta", replace

****************** Developement financier

u "$sourcedata\FD_Database.dta", clear

keep code year FD

preserve

ren FD       FD_r
ren code     iso_r

save "$savedata\FD_Database_r.dta", replace

restore

ren FD       FD_p
ren code     iso_p

save "$savedata\FD_Database_p.dta", replace



///////////// MERGER AVEC Final DATA

u "$savedata\Final_DATA.dta", clear

merge m:1 year iso_r using "$savedata\CIT_r.dta", keep(1 3) nogen

merge m:1 year iso_p using "$savedata\CIT_p.dta", keep(1 3) nogen

merge m:1 iso_r iso_p using "$savedata\BIT.dta", keep(1 3) nogen

merge m:1 iso_r year using "$savedata\FD_Database_r.dta", keep(1 3) nogen

merge m:1 iso_p year using "$savedata\FD_Database_p.dta", keep(1 3) nogen

*********** CREATION DE LA BINAIRE BIT

gen bitforce=0 if iso_r==iso_p
replace bitforce=0 if yrforce==.

replace bitforce=1 if yrforce==year
replace bitforce=1 if yrforce<year & yrforce!=.
replace bitforce=0 if yrforce>year & yrforce!=.
replace bitforce=0 if yrterm==year
replace bitforce=0 if yrterm<year & yrterm!=.
replace bitforce=1 if yrforce2==year & bitforce==0
replace bitforce=1 if yrforce2<year & yrforce2!=. & bitforce==0
replace bitforce=0 if yrterm2==year
replace bitforce=0 if yrterm2<year & yrterm2!=.
replace bitforce=0 if iso_r==iso_p

drop yrsig yrforce yrterm yrsig2 yrforce2 yrterm2 SHORTTITLE STATUS PARTIES DATEOFSIGNATURE DATEOFENTRYINTOFORCE TERMINATIONDATE
label var bitforce "BIT dummy"
ren bitforce   BIT

///////// CONSTRUCTION DE LA VARIABLE DE RESISTENCE MULTILATÉRALE


*** Création du MR GDP
preserve
drop if iso_p==iso_r
collapse distw [aw=GDP_current_p], by(iso_r year)
gen rmt_imp_distgdp=ln(distw)
label var rmt_imp_distgdp "Destination MR dist, w. GDP ne"
ren rmt_imp_distgdp MR
save "$savedata\rmt_imp_distgdp_ne.dta", replace
restore

*** Création du MTR Tax  
preserve
drop if iso_p==iso_r
collapse distw [aw=CIT_p], by(iso_r year)
gen rmt_imp_tax_dist=ln(distw)
label var rmt_imp_tax_dist "Destination MRT dist, w. tax ne"
ren rmt_imp_tax_dist MTR
save "$savedata\rmt_imp_tax_dist.dta", replace
restore


merge m:1 iso_r year using "$savedata\rmt_imp_distgdp_ne.dta",keep(1 3) nogen
merge m:1 iso_r year using "$savedata\rmt_imp_tax_dist.dta",keep(1 3) nogen

gen log_dist    = log(distw)
gen log_distcap = log(distcap)



drop source_in_flow lendingtype_p lendingtypename_p legal_old_o legal_old_d legal_new_o legal_new_d lendingtype_r lendingtypename_r

* CREATION D'UNE BINAIRE POUR LES PAYS RICHES EN RESSOURCE CLASSIFICATION DU FMI

gen Rich = 0
label variable Rich "1 if Resources-rich, IMF classification"
replace Rich = 1 if iso_r =="COD"
replace Rich = 1 if iso_r =="LBR"
replace Rich = 1 if iso_r =="NER"
replace Rich = 1 if iso_r =="GIN"
replace Rich = 1 if iso_r =="MLI"
replace Rich = 1 if iso_r =="TCD"
replace Rich = 1 if iso_r =="MRT"
replace Rich = 1 if iso_r =="LAO"
replace Rich = 1 if iso_r =="ZMB"
replace Rich = 1 if iso_r =="VNM"
replace Rich = 1 if iso_r =="YEM"
replace Rich = 1 if iso_r =="NGA"
replace Rich = 1 if iso_r =="CMR"
replace Rich = 1 if iso_r =="PNG"
replace Rich = 1 if iso_r =="SDN"
replace Rich = 1 if iso_r =="UZB"
replace Rich = 1 if iso_r =="CIV"
replace Rich = 1 if iso_r =="BOL"
replace Rich = 1 if iso_r =="MNG"
replace Rich = 1 if iso_r =="COG"
replace Rich = 1 if iso_r =="IRQ"
replace Rich = 1 if iso_r =="IDN"
replace Rich = 1 if iso_r =="TLS"
replace Rich = 1 if iso_r =="SYR"
replace Rich = 1 if iso_r =="GUY"
replace Rich = 1 if iso_r =="TKM"
replace Rich = 1 if iso_r =="AGO"
replace Rich = 1 if iso_r =="GAB"
replace Rich = 1 if iso_r =="GNQ"
replace Rich = 1 if iso_r =="SLE"
replace Rich = 1 if iso_r =="AFG"
replace Rich = 1 if iso_r =="MDG"
replace Rich = 1 if iso_r =="MOZ"
replace Rich = 1 if iso_r =="CAF"
replace Rich = 1 if iso_r =="UGA"
replace Rich = 1 if iso_r =="TZA"
replace Rich = 1 if iso_r =="TGO"
replace Rich = 1 if iso_r =="KGZ"
replace Rich = 1 if iso_r =="STP"
replace Rich = 1 if iso_r =="GHA"
replace Rich = 1 if iso_r =="GTM"
replace Rich = 1 if iso_r =="ECU"
replace Rich = 1 if iso_r =="ALB"
replace Rich = 1 if iso_r =="DZA"
replace Rich = 1 if iso_r =="IRN"
replace Rich = 1 if iso_r =="PER"
replace Rich = 1 if iso_r =="AZE"
replace Rich = 1 if iso_r =="BWA"
replace Rich = 1 if iso_r =="KAZ"
replace Rich = 1 if iso_r =="SUR"
replace Rich = 1 if iso_r =="MEX"
replace Rich = 1 if iso_r =="RUS"
replace Rich = 1 if iso_r =="CHL"
replace Rich = 1 if iso_r =="VEN"
replace Rich = 1 if iso_r =="LBY"
replace Rich = 1 if iso_r =="BHR"
replace Rich = 1 if iso_r =="BRN"
replace Rich = 1 if iso_r =="TTO"
replace Rich = 1 if iso_r =="SAU"
replace Rich = 1 if iso_r =="OMN"
replace Rich = 1 if iso_r =="UAE"
replace Rich = 1 if iso_r =="QAT"
replace Rich = 1 if iso_r =="NOR"

gen Not_rich = 0
replace Not_rich = 1 if Rich == 0  

************************** Date de ciblage Inflation
*** Hard IT 
gen hard_it =0
replace hard_it = 1 if iso_r == "BRA" & year >=1999
replace hard_it = 1 if iso_r ==  "CHL" & year >=2001 
replace hard_it = 1 if iso_r == "COL" & year >=1999
replace hard_it = 1 if iso_r == "HUN" & year >=2001
replace hard_it = 1 if iso_r == "MEX" & year >=2001
replace hard_it = 1 if iso_r == "PER" & year >=2002 
replace hard_it = 1 if iso_r == "PHL" & year >=2002 
replace hard_it = 1 if iso_r ==  "POL" & year >=1998
replace hard_it = 1 if iso_r ==  "ZAF" & year >=2000
replace hard_it = 1 if iso_r == "THA" & year >=2000
replace hard_it = 1 if iso_r ==  "IDN" & year >=2005
replace hard_it = 1 if iso_r ==  "ROU" & year >=2005
replace hard_it = 1 if iso_r ==  "TUR" & year >=2006 
replace hard_it = 1 if iso_r == "GHA" & year >=2007
replace hard_it = 1 if iso_r == "GTM" & year >=2006
replace hard_it = 1 if iso_r == "URY" & year >=2007
replace hard_it = 1 if iso_r == "UGA" & year >=2011
replace hard_it = 1 if iso_r == "SRB" & year >=2009
replace hard_it = 1 if iso_r == "PRY" & year >=2011
replace hard_it = 1 if iso_r == "RUS" & year >=2015
replace hard_it = 1 if iso_r == "DOM" & year >=2012
replace hard_it = 1 if iso_r == "KAZ" & year >=2015
replace hard_it = 1 if iso_r == "UKR" & year >=2017
replace hard_it = 1 if iso_r == "MDA" & year >=2013

*/*** Advanced
replace hard_it = 1  if iso_r == "AUS" & year >=1994
replace hard_it = 1  if iso_r == "CAN" & year >=1994
replace hard_it = 1  if iso_r == "FIN" & year >=1994 & year <=1999
replace hard_it = 1  if iso_r == "ISL" & year >= 2001
replace hard_it = 1  if iso_r == "NZL" & year >=1990
replace hard_it = 1  if iso_r == "NOR" & year >=2001
replace hard_it = 1  if iso_r == "ESP" & year >=1995 & year <=1998
replace hard_it = 1  if iso_r == "CHE" & year >=2000 // Pays non considéré comme cibleur strict, mais avec une stratégie similaire...
replace hard_it = 1  if iso_r == "SWE" & year >=1995 
replace hard_it = 1  if iso_r == "GBR" & year >=1993
replace hard_it = 1  if iso_r == "CZE" & year >=1998
replace hard_it = 1  if iso_r == "ISR" & year >=1997
replace hard_it = 1  if iso_r == "SVK" & year >=2005 & year <=2009
replace hard_it = 1  if iso_r == "KOR" & year >=1998
*/
***** Soft targets 
gen soft_it =0
replace soft_it = 1 if iso_r == "BRA" & year >=1999
replace soft_it = 1 if iso_r ==  "CHL" & year >=1991
replace soft_it = 1 if iso_r == "COL" & year >=1999
replace soft_it = 1 if iso_r == "HUN" & year >=2001
replace soft_it = 1 if iso_r == "MEX" & year >=1999
replace soft_it = 1 if iso_r == "PER" & year >=2002
replace soft_it = 1 if iso_r == "PHL" & year >=2002
replace soft_it = 1 if iso_r ==  "POL" & year >=1998
replace soft_it = 1 if iso_r ==  "ZAF" & year >=2000
replace soft_it = 1 if iso_r == "THA" & year >=2000
replace soft_it = 1 if iso_r ==  "IDN" & year >=2005
replace soft_it = 1 if iso_r ==  "ROU" & year >=2005
replace soft_it = 1 if iso_r ==  "TUR" & year >=2002
replace soft_it = 1 if iso_r == "GHA" & year >=2007
replace soft_it = 1 if iso_r == "GTM" & year >=2005
replace soft_it = 1 if iso_r == "URY" & year >=2005
replace soft_it = 1 if iso_r == "UGA" & year >=2011
replace soft_it = 1 if iso_r ==  "SRB" & year >=2006
replace soft_it = 1 if iso_r ==   "PRY" & year >=2011
replace soft_it = 1 if iso_r == "RUS" & year >=2015
replace soft_it = 1 if iso_r == "DOM" & year >=2012
replace soft_it = 1 if iso_r == "KAZ" & year >=2015
replace soft_it = 1 if iso_r == "UKR" & year >=2017
replace soft_it = 1 if iso_r == "MDA" & year >=2010

*/*** Advanced
replace soft_it = 1 if iso_r == "AUS" & year >=1993
replace soft_it = 1 if iso_r == "CAN" & year >=1991
replace soft_it = 1 if iso_r == "FIN" & year >=1993 & year <=1999
replace soft_it = 1 if iso_r == "ISL" & year >= 2001
replace soft_it = 1 if iso_r == "NZL" & year >=1990
replace soft_it = 1 if iso_r == "NOR" & year >=2001
replace soft_it = 1 if iso_r == "ESP" & year >=1995 & year <=1999
replace soft_it = 1 if iso_r == "CHE" & year >=2000
replace soft_it = 1 if iso_r == "SWE" & year >=1993 
replace soft_it = 1 if iso_r == "GBR" & year >=1992
replace soft_it = 1 if iso_r == "CZE" & year >=1998
replace soft_it = 1 if iso_r == "ISR" & year >=1992
replace soft_it = 1 if iso_r == "SVK" & year >=2005 & year <=2009
replace soft_it = 1 if iso_r == "KOR" & year >=1998
*/


save "$savedata\Final_DATA.dta", replace



////////// CREATION DE LA BASE DE DONNÉES DE ROBUSTESSE AVEC CAPB

u "$savedata\Final_DATA.dta", clear

merge m:1 iso_r year using "$savedata\CAPB_r.dta",keep(3) nogen

merge m:1 iso_p year using "$savedata\CAPB_p.dta",keep(1 3) nogen


order name_r iso_r name_p  iso_p year 
drop country

save "$savedata\CAPB.dta", replace


log close
di as result "Analyse terminée avec succès."







* Fin du do-file
