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

log using "$dofile\log_TEST_OM.log", replace

********************* IMPORTATION DES DONNÉES

*** IMF programs

clear all
import excel using "$sourcedata\IMF.xls", clear first sheet("IMF_SBA")
rename CountryName country 

replace country ="Cote d'Ivoire" if country =="Côte d'Ivoire"
replace country ="Korea, Dem. People's Rep." if country =="Korea, Dem. Rep."

*/
kountry country , from (other) stuck  											
rename _ISO3N_ code_pays
kountry code_pays , from(iso3n) to(iso3c)
drop code_pays
rename _ISO3C_ code
order country code 
rename code iso_r


drop BA

* Renommer les variables pour correspondre aux années
rename C y1970
rename D y1971
rename E y1972
rename F y1973
rename G y1974
rename H y1975
rename I y1976
rename J y1977
rename K y1978
rename L y1979
rename M y1980
rename N y1981
rename O y1982
rename P y1983
rename Q y1984
rename R y1985
rename S y1986
rename T y1987
rename U y1988
rename V y1989
rename W y1990
rename X y1991
rename Y y1992
rename Z y1993
rename AA y1994
rename AB y1995
rename AC y1996
rename AD y1997
rename AE y1998
rename AF y1999
rename AG y2000
rename AH y2001
rename AI y2002
rename AJ y2003
rename AK y2004
rename AL y2005
rename AM y2006
rename AN y2007
rename AO y2008
rename AP y2009
rename AQ y2010
rename AR y2011
rename AS y2012
rename AT y2013
rename AU y2014
rename AV y2015
rename AW y2016
rename AX y2017
rename AY y2018
rename AZ y2019

* Convertir en numérique si nécessaire
foreach var of varlist y1970-y2019 {
    destring `var', replace
}

* Reshape long
reshape long y, i(country iso_r CountryCode) j(year)
rename y imf_value

* Attribuer les codes ISO manquants
replace iso_r = "HKG" if country == "Hong Kong SAR, China"
replace iso_r = "XKX" if country == "Kosovo" 
replace iso_r = "MAC" if country == "Macao SAR, China"
replace iso_r = "SXM" if country == "Sint Maarten (Dutch part)"
replace iso_r = "YUG" if country == "Yugoslavia, FR (Serbia/Montenegro)"

* Vérifier que tous les codes ont été attribués
list country iso_r if iso_r == ""

* Nettoyer
drop CountryCode
drop if missing(imf_value)
sort country year
drop if year < 2006 | year >= 2019 
*/
save "$savedata\IMF_SBA.dta", replace


***** Economic freedom 
 
clear all
import delimited "$sourcedata\freedom-scores.csv", clear 

rename name  country  
rename indexyear year
drop  isocode  id  shortname

replace overallscore = "." if overallscore=="NULL"
destring overallscore, replace force

*1
replace propertyrights = "." if propertyrights==","
destring propertyrights, replace force
*2
replace judicialeffectiveness = "." if judicialeffectiveness=="NULL"
destring judicialeffectiveness, replace force
*3
replace governmentintegrity = "." if governmentintegrity=="NULL"
destring governmentintegrity, replace force
*4
replace taxburden = "." if taxburden=="NULL"
destring taxburden, replace force
*5
replace governmentspending = "." if governmentspending=="NULL"
destring governmentspending, replace force
*6
replace fiscalhealth = "." if fiscalhealth=="NULL"
destring fiscalhealth, replace force
*7
replace businessfreedom = "." if businessfreedom=="NULL"
destring businessfreedom, replace force
*8
replace laborfreedom = "." if laborfreedom=="NULL"
destring laborfreedom, replace force
*9
replace monetaryfreedom = "." if monetaryfreedom=="NULL"
destring monetaryfreedom, replace force
*10
replace tradefreedom = "." if tradefreedom=="NULL"
destring tradefreedom, replace force
*11
replace investmentfreedom = "." if investmentfreedom=="NULL"
destring investmentfreedom, replace force
*12
replace financialfreedom = "." if financialfreedom=="NULL"
destring financialfreedom, replace force

kountry country , from (other) stuck  											
rename _ISO3N_ code_pays
kountry code_pays , from(iso3n) to(iso3c)
drop code_pays
rename _ISO3C_ code
order country code 
rename code iso_r

egen idcoun = group(country)
egen idyear = group(year)
order country iso_r year idcoun
drop if idcoun ==45

replace iso_r ="CIV" if idcoun==46
replace iso_r ="COG" if idcoun==151
replace iso_r ="STP" if idcoun==182
tab country if iso_r==""
drop if iso_r ==""

duplicates drop idcoun idyear, force
xtset idcoun idyear

drop  idcoun idyear  

tempfile base  
save `base'   

merge m:m iso_r year using `base'
drop _merge

drop if year < 2006 | year >= 2019 

save "$savedata\freedom-scores.dta", replace

************************ MERGE AVEC FINAL DATA

u "$savedata\Final_DATA.dta", clear

merge m:1 iso_r year using "$savedata\IMF_SBA.dta", keep(1 3) nogen

merge m:1 iso_r year using "$savedata\freedom-scores.dta", keep(1 3) nogen

save "$savedata\Final_DATA_test.dta", replace






log close



