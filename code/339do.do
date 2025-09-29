* Set directory 
cd "/Users/cherylz/Desktop/ECO339/339THA"
* Open a log, save as .txt
log using "339log" , text replace
* Load data
use "lfs0119rr.dta", clear

****************************** PART1 ***************************************
* Calculate the median hourly earnings
egen medianwage = median(hrlyearn), by(prov survmnth survyear)
* Define the low pay threshold as two-thirds of the median hourly earnings
gen lowage_threshold = 2/3 * medianwage
* Identify workers earning below this threshold
gen lowage_worker = hrlyearn < lowage_threshold
* Analyze characteristics of low wage workers
tabulate age_12 if lowage_worker, summarize(hrlyearn)
tabulate sex if lowage_worker, summarize(hrlyearn)
tabulate educ90 if lowage_worker, summarize(hrlyearn)
tabulate union if lowage_worker, summarize(hrlyearn)

gen employed = inlist(lfsstat, 1, 2)
* Have an original copy of the data
preserve

* Create the ratio of low-wage workers to total empolyed worker for each characteristic
foreach var in age_12 sex educ90 union {
    * Count the total number of employed workers in each category
    egen total_`var' = total(employed), by(`var')

    * Count the number of low-wage workers in each group
    egen lowage_`var' = total(lowage_worker), by(`var')

    * Create a temporary file to hold ratios
    tempfile tempdata
    save `tempdata'

    collapse (sum) total_`var' lowage_`var', by(`var')

    * Generate the ratio
    gen ratio_`var' = lowage_`var' / total_`var'

    * Display the table with ratios in STATA
    list `var' ratio_`var' in 1/L, clean

    use `tempdata', clear
}


****************************** PART2 ***************************************
* Collapse to see which prov to choose to be treated or controlled and create a minimum wage summary table
restore 
collapse (mean) minwage, by(survyear prov survmnth)
keep if survmnth == 4
drop survmnth
format minwage %9.2f
reshape wide minwage, i(survyear) j(prov)

export excel using "minwage_pivot_table.xlsx", firstrow(variables) replace

restore

* The outcome: employment–population ratio for a given age group
egen employed_rate = mean(employed), by(prov survyear age_12)
egen employed_rate1519 = mean(employed) if age_12 == 1, by(prov survyear)
egen employed_rate2024 = mean(employed) if age_12 == 2, by(prov survyear)

* Emperical Framework: Over the years of our data, some provinces acts as both treatment groups and control groups at some point in time. So we can use a DiD model with multiple treatments.
gen post2011 = (survyear >= 2011)
gen post2009 = (survyear >= 2009)
gen post2015 = (survyear >= 2015)
gen post2012 = (survyear >= 2012)

* Dummy Variables for Year and Region 
foreach p in 10 11 12 13 24 35 46 47 48 59 {
    gen prov_`p' = (prov == "`p'")
}
forvalues y = 2001/2019 {
    gen year_`y' = (survyear == `y')
}

* Quebec as the treatment group
gen treat = (prov == 24)
gen treated24_2011 = treat * post2011 

reg employed_rate1519 post2011 treat treated24_2011 i.prov_* i.year_* [aweight=fweight]
outreg2 using "339t1.xls", ctitle("`x'") se 2aster replace keep(post2011 treat treated24_2011) addtext(FE, YES)
reg employed_rate2024 post2011 treat treated24_2011 i.prov_* i.year_* [aweight=fweight]
outreg2 using "339t1.xls", ctitle("`x'") se 2aster append keep(post2011 treat treated24_2011) addtext(FE, YES)

* Ontario as the treatment group
drop treat 
gen treat = (prov == 35)
gen treated35_2009 = treat * post2009

reg employed_rate1519 post2009 treat treated35_2009 i.prov_* i.year_* [aweight=fweight]
outreg2 using "339t2.xls", ctitle("`x'") se 2aster replace keep(post2009 treat treated35_2009) addtext(FE, YES)
reg employed_rate2024 post2009 treat treated35_2009 i.prov_* i.year_* [aweight=fweight]
outreg2 using "339t2.xls", ctitle("`x'") se 2aster append keep(post2009 treat treated35_2009) addtext(FE, YES)

* Alterta as the treatment group 
drop treat 
gen treat = (prov == 48)
gen treated48_2015 = treat * post2015

reg employed_rate1519 post2015 treat treated48_2015 i.prov_* i.year_* [aweight=fweight]
outreg2 using "339t3.xls", ctitle("`x'") se 2aster replace keep(post2015 treat treated48_2015) addtext(FE, YES)
reg employed_rate2024 post2015 treat treated48_2015 i.prov_* i.year_* [aweight=fweight]
outreg2 using "339t3.xls", ctitle("`x'") se 2aster append keep(post2015 treat treated48_2015) addtext(FE, YES)

* BC as the treatment group
drop treat 
gen treat = (prov == 59)
gen treated59_2012 = treat * post2012

reg employed_rate1519 post2012 treat treated59_2012 i.prov_* i.year_* [aweight=fweight]
outreg2 using "339t4.xls", ctitle("`x'") se 2aster replace keep(post2012 treat treated59_2012) addtext(FE, YES)
reg employed_rate2024 post2012 treat treated59_2012 i.prov_* i.year_* [aweight=fweight]
outreg2 using "339t4.xls", ctitle("`x'") se 2aster append keep(post2012 treat treated59_2012) addtext(FE, YES)

* Cluster the data at the prov level, account for province-level fixed effects and are robust to within-province correlation in the error terms.
* Quebec as the treatment group
drop treat
gen treat = (prov == 24)
drop treated24_2011  
gen treated24_2011 = treat * post2011 

reg employed_rate1519 post2011 treat treated24_2011 i.prov_* i.year_* [aweight=fweight], cluster(prov)
outreg2 using "339t5.xls", ctitle("`x'") se 2aster replace keep(post2011 treat treated24_2011) addtext(FE, YES)
reg employed_rate2024 post2011 treat treated24_2011 i.prov_* i.year_* [aweight=fweight], cluster(prov)
outreg2 using "339t5.xls", ctitle("`x'") se 2aster append keep(post2011 treat treated24_2011) addtext(FE, YES)

* Ontario as the treatment group
drop treat 
gen treat = (prov == 35)
drop treated35_2009 
gen treated35_2009 = treat * post2009

reg employed_rate1519 post2009 treat treated35_2009 i.prov_* i.year_* [aweight=fweight], cluster(prov)
outreg2 using "339t6.xls", ctitle("`x'") se 2aster replace keep(post2009 treat treated35_2009) addtext(FE, YES)
reg employed_rate2024 post2009 treat treated35_2009 i.prov_* i.year_* [aweight=fweight], cluster(prov)
outreg2 using "339t6.xls", ctitle("`x'") se 2aster append keep(post2009 treat treated35_2009) addtext(FE, YES)

* Alterta as the treatment group 
drop treat 
gen treat = (prov == 48)
drop treated48_2015 
gen treated48_2015 = treat * post2015

reg employed_rate1519 post2015 treat treated48_2015 i.prov_* i.year_* [aweight=fweight], cluster(prov)
outreg2 using "339t7.xls", ctitle("`x'") se 2aster replace keep(post2015 treat treated48_2015) addtext(FE, YES)
reg employed_rate2024 post2015 treat treated48_2015 i.prov_* i.year_* [aweight=fweight], cluster(prov)
outreg2 using "339t7.xls", ctitle("`x'") se 2aster append keep(post2015 treat treated48_2015) addtext(FE, YES)

* BC as the treatment group
drop treat 
gen treat = (prov == 59)
drop treated59_2012 
gen treated59_2012 = treat * post2012

reg employed_rate1519 post2012 treat treated59_2012 i.prov_* i.year_* [aweight=fweight], cluster(prov)
outreg2 using "339t8.xls", ctitle("`x'") se 2aster replace keep(post2012 treat treated59_2012) addtext(FE, YES)
reg employed_rate2024 post2012 treat treated59_2012 i.prov_* i.year_* [aweight=fweight], cluster(prov)
outreg2 using "339t8.xls", ctitle("`x'") se 2aster append keep(post2012 treat treated59_2012) addtext(FE, YES)

* DiD Plots for different age groups
collapse (mean) employed, by(prov survyear age_12)
keep if survyear >=2007 & survyear <= 2017
keep if age_12 >= 1 & age_12 <= 2

twoway (line employed survyear if prov == 24&age_12 == 1, lc(blue)) (line employed survyear if prov == 35&age_12 == 1, lc(red)) (line employed survyear if prov == 48&age_12 == 1, lc(green)) (line employed survyear if prov == 59&age_12 == 1, lc(orange)),legend(label(1 "Quebec") label(2 "Ontario") label(3 "Alberta") label(4 "British Columbia") col(4)) ytitle("Empl/Pop for age group 15-19") xlabel(2009 2012 2011 2015, valuelabel) ylabel(, grid) name(g1, replace)
twoway (line employed survyear if prov == 24&age_12 == 2, lc(blue)) (line employed survyear if prov == 35&age_12 == 2, lc(red)) (line employed survyear if prov == 48&age_12 == 2, lc(green)) (line employed survyear if prov == 59&age_12 == 2, lc(orange)),legend(off) ytitle("Empl/Pop for age group 20-24") xlabel(2009 2012 2011 2015, valuelabel) ylabel(, grid) name(g2, replace)
* Install package grc1leg to create combined graphs with one shared legend 
net install grc1leg,from( http://www.stata.com/users/vwiggins/)
grc1leg g1 g2 , legendfrom(g1) title("DiD Plot for Selected Provinces in Canada 2007-2017")


* End of log file 
log close
