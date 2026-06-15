/**************************************************************************************************
Replication Master Do-file

ProjET: Consolidations budgétaires et investissements directs étrangers
 dans les pays en développement : une analyse à partir de
 données narratives et bilatérales.
 
Author:DIBLONI KOKO CLOVIS
Date: 21/08/25
**************************************************************************************************/
*/
.
clear all
set more off

gl path "C:\Users\HP\Desktop\Memoire"

*----------------------------------------------*
* 0. traitement de données
*----------------------------------------------*
do "$path\dofile\00_WDI_DATA.do"
* 1. Stat_des
*----------------------------------------------*
do "$path\dofile\01_Stat_des.do"
*----------------------------------------------*
* 2. Régressions principales
*----------------------------------------------*
do "$path\dofile\02_Regression_prin.do"
*----------------------------------------------*
* 3. Robustesses
*----------------------------------------------*
do "$path\dofile\03_Robustesse.do"
*----------------------------------------------*
* 4. Hétérogénéité
*----------------------------------------------*
do "$path\dofile\04_Hetergeneite.do"
*----------------------------------------------*
* 5. En fonction du niveau de revenu
*----------------------------------------------*
do "$path\dofile\05_Niveau_de_revenu.do"
* 6. Regime de change
*----------------------------------------------*
do "$path\dofile\06_regime.do"

* 7. Regression par année
*----------------------------------------------*
do "$path\dofile\07_Regression_annee.do"

* 8.  Sensibilité par rapport à l'année
*----------------------------------------------*
do "$path\dofile\08_sensibilité_annee.do"

* 9. Sensibilité par rapport au pays
*----------------------------------------------*
do "$path\dofile\09_Regression_pays.do"

* 10. Traitement de données pour le test de variables omises
*----------------------------------------------*
do "$path\dofile\10_TEST_VAR_OM.do"

* 11. Test de variables omises
*----------------------------------------------*
do "$path\dofile\11_TEST.do"



log close
