--Data Source - Give a shout-out to OurWorldInData: https://github.com/owid/covid-19-data/tree/master/public/data

--My focus on this dataset will focus on three main indices: Case Fatality Rate/Count, Infected Rate/Count, and (Full) Vaccination Rate/Count (Doses Administered).
--To follow the trend, pattern or changes of Coronavirus pandemic, I will break them down periodically and geographically.
--For example: Global Death Rate per day, continentally Doses Administered per month.

--Let's start this by taking a look on a table
Select *
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
Order by 3, 4

--I am gonna explore the CovidDeaths table first
Select continent, location, date, new_cases, new_deaths, population
, Sum(Convert(int, new_deaths)) Over (Partition by location Order by location, date) Deaths 
--This is actually total_deaths. I just want to practice partition a bit
From PortfolioProject..CovidDeaths
Where continent is not null
--Basically, location is a country only when continent is mentioned
Order by 2, 3

--Checking the location list when continent is not null
Select continent, location
From PortfolioProject..CovidDeaths
Where continent is not null
Group by continent, location
Order by 1, 2

--Cases and deaths

--The likelihood death rate in a specific country per day
Select Location, date, total_cases, total_deaths, total_deaths/total_cases*100 DeathRate
From PortfolioProject..CovidDeaths
Where location = 'Vietnam'
Order by 1, 2

--Cases and Population in a specific country 
Select Location, date, total_cases, population, (total_cases/population)*100 InfectedRate
From PortfolioProject..CovidDeaths
Where location = 'Vietnam'
Order by 1, 2

--Hitherto ranking of the global Infected Rate (the word 'hitherto' is severely unpopular but I've just learn it recently so :D)
Select continent, location, total_cases, population, total_cases/population*100 InfectedPercentage
From PortfolioProject..CovidDeaths
Where Convert(Varchar(25), date, 126) like '%2022-10-19%' 
	and continent is not null
Order by InfectedPercentage DESC

--Similarly, I will rank the global Death Count

--Convert the data type to integer
Select location, Max(Cast(total_deaths as int)) TotalDeaths
From PortfolioProject..CovidDeaths
Where continent is not null
Group by location
Order by TotalDeaths DESC

--Let's see the total deaths by continent 
Select location, Max(Cast(total_deaths as int)) TotalDeaths
From PortfolioProject..CovidDeaths
Where continent is null
Group by location
Order by TotalDeaths DESC
--This is not working exactly as I expected

--Because the continent is not actually continent so I have to adjust the query a bit
Select location, Max(Cast(total_deaths as int)) TotalDeaths
From PortfolioProject..CovidDeaths Dea
Where location in
	(Select continent
	From PortfolioProject..CovidDeaths)
Group by location
Order by TotalDeaths DESC
--Now it looks right

--Global numbers

--Case fatality rate (CFR) per country atm
Select location, Max(total_cases) Cases, Max(Convert(int, total_deaths)) Deaths, Max(Convert(int, total_deaths))/Max(total_cases)*100 CaseFatalityRate
From PortfolioProject..CovidDeaths Dea
Where continent is not null
	and location <> 'North Korea'
	--North Korea is a pain in the table so I just have to remove it
Group by location
Order by 4 DESC

--Case fatality rate (CFR) per day

--Note that population is fixed during the whole time
Select date, Sum(new_cases) NewCases, Sum(Convert(int, new_deaths)) Deaths, Sum(Convert(int, new_deaths))/Sum(new_cases)*100 CaseFatalityRate
From PortfolioProject..CovidDeaths Dea
Where continent is not null
Group by date
Order by date

--World Case fatality rate (CFR)
Select Sum(new_cases) Cases, Sum(Convert(int, new_deaths)) Deaths, Sum(Convert(int, new_deaths))/Sum(new_cases)*100 CaseFatalityRate
From PortfolioProject..CovidDeaths Dea
Where continent is not null

--Come to the Vaccination table. Let's find out the vaccination rate.

--Lets use CTE
With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, DosesAdministered)
As
(
Select dea.continent, dea.location, dea.date, dea.population, convert(int, vac.new_vaccinations) new_vaccinations
, Sum(convert(bigint, vac.new_vaccinations)) Over (Partition by dea.location Order by dea.location, dea.date) DosesAdministered
--This might look like total_vaccinations. However, the column will be null when there is no new vaccinations that day so DosesAdministered column is needed.
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	And dea.date = vac.date
Where dea.continent is not null
)
Select *, DosesAdministered/Population*100 VaccinationRate
From PopvsVac
Order by 2, 3

--Or TEMP table
Drop Table if exists #VaccinationRate
Create Table #VaccinationRate
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
DosesAdministered numeric
)

Insert into #VaccinationRate
Select dea.continent, dea.location, dea.date, dea.population, convert(int, vac.new_vaccinations) new_vaccinations
, Sum(convert(bigint, vac.new_vaccinations)) Over (Partition by dea.location Order by dea.location, dea.date) DosesAdministered
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	And dea.date = vac.date
Where dea.continent is not null

Select *, DosesAdministered/Population*100 VaccinationRate
From #VaccinationRate

--Alright. Now I will create some views for later visualizations.
--I have a imagination of the upcoming visualization that using Line graphs.
--The y-axis is for rate/count and the x-axis is for time (day/month/quater).
--The lines will depict the historical trend of Coronavirus by country/continent/world level.

--Infected Rate (country/per day)
Drop View If Exists InfectedRateCountryPerDay
Create View InfectedRateCountryPerDay 
As
	Select location, date, total_cases, population, total_cases/population*100 InfectedRate
	From PortfolioProject..CovidDeaths dea
	Where continent is not null

--Infected Rate (continent/per day)
Drop View If Exists InfectedRateContinentPerDay
Create View InfectedRateContinentPerDay 
As
	Select location, date, total_cases, population, total_cases/population*100 InfectedRate
	From PortfolioProject..CovidDeaths dea
	Where location in
		(Select continent
		From PortfolioProject..CovidDeaths)

--Infected Rate (world/per day)
Drop View If Exists InfectedRateWorldPerDay
Create View InfectedRateWorldPerDay 
As
	Select location, date, total_cases, population, total_cases/population*100 InfectedRate
	From PortfolioProject..CovidDeaths dea
	Where location = 'World'

--Case Fatality Rate (country/per day)
Drop View If Exists CFRCountryPerDay
Create View CFRCountryPerDay 
As
	Select location, date, convert(int, total_deaths) total_deaths, total_cases, convert(int, total_deaths)/total_cases*100 CaseFatalityRate
	From PortfolioProject..CovidDeaths dea
	Where continent is not null

--Case Fatality Rate (continent/per day)
Drop View If Exists CFRContinentPerDay
Create View CFRContinentPerDay 
As
	Select location, date, convert(int, total_deaths) total_deaths, total_cases, convert(int, total_deaths)/total_cases*100 CaseFatalityRate
	From PortfolioProject..CovidDeaths dea
	Where location in
		(Select continent
		From PortfolioProject..CovidDeaths)

--Case Fatality Rate (world/per day)
Drop View If Exists CFRWorldPerDay
Create View CFRWorldPerDay 
As
	Select location, date, convert(int, total_deaths) total_deaths, total_cases, convert(int, total_deaths)/total_cases*100 CaseFatalityRate
	From PortfolioProject..CovidDeaths dea
	Where location = 'World'

--Doses Administered Rate (country/per day)
Drop Table If Exists #DosesAdministeredCountryPerDay
Create Table #DosesAdministeredCountryPerDay
(
Location nvarchar(255),
Date date,
Population numeric,
NewDoses numeric,
DosesAdministered numeric
)

	Insert Into #DosesAdministeredCountryPerDay
	Select d.location, d.date, d.population, v.new_vaccinations
	, Sum(Convert(numeric, v.new_vaccinations)) Over (Partition by d.location Order by d.location, d.date) DosesAdministered
	From PortfolioProject..CovidDeaths d
	Join PortfolioProject..CovidVaccinations v
		On d.location = v.location
		and d.date = v.date
	Where d.continent is not null
		
		Select *, DosesAdministered/Population*100 DosesRate
		From #DosesAdministeredCountryPerDay
--Look like View function is not allowed with Temp tables.
--I can use CTE instead.
Drop View If Exists DosesAdministeredCountryPerDay
Create View DosesAdministeredCountryPerDay
As
	With DosesAdministeredCountryPerDay (Location, Date, Population, NewDoses, DosesAdministered)
	As
	(
	Select d.location, d.date, d.population, v.new_vaccinations
	, Sum(Convert(numeric, v.new_vaccinations)) Over (Partition by d.location Order by d.location, d.date) DosesAdministered
	From PortfolioProject..CovidDeaths d
	Join PortfolioProject..CovidVaccinations v
		On d.location = v.location
		and d.date = v.date
	Where d.continent is not null
	)
	Select *, DosesAdministered/Population*100 DosesRate
	From DosesAdministeredCountryPerDay

--Doses Administered Rate (continent/per day)
Drop View If Exists DosesAdministeredContinentPerDay
Create View DosesAdministeredContinentPerDay
As
With DosesAdministeredContinentPerDay (Location, Date, Population, NewDoses, DosesAdministered)
As
(
Select d.location, d.date, d.population, v.new_vaccinations
, Sum(Convert(numeric, v.new_vaccinations)) Over (Partition by d.location Order by d.location, d.date) DosesAdministered
From PortfolioProject..CovidDeaths d
Join PortfolioProject..CovidVaccinations v
	On d.location = v.location
	and d.date = v.date
Where d.location in
	(Select continent
	From PortfolioProject..CovidDeaths)
)
	Select *, DosesAdministered/Population*100 DosesRate
	From DosesAdministeredContinentPerDay

--Doses Administered Rate (world/per day)
Drop View If Exists DosesAdministeredWorldPerDay
Create View DosesAdministeredWorldPerDay
As
With DosesAdministeredWorldPerDay (Location, Date, Population, NewDoses, DosesAdministered)
As
(
	Select d.location, d.date, d.population, v.new_vaccinations
	, Sum(Convert(numeric, v.new_vaccinations)) Over (Partition by d.location Order by d.location, d.date) DosesAdministered
	From PortfolioProject..CovidDeaths d
	Join PortfolioProject..CovidVaccinations v
		On d.location = v.location
		and d.date = v.date
	Where d.location = 'World'
)
		Select *, DosesAdministered/Population*100 DosesRate
		From DosesAdministeredWorldPerDay

--Some summarized numbers (updated on 2022-10-19)
--by country
Select d.location, Max(d.population) Population, Max(d.total_cases) Total_Cases
, Max(Convert(int, d.total_deaths)) Total_Deaths
, Max(Convert(bigint, v.total_vaccinations)) Total_Vaccinations
, Max(Convert(int, d.total_deaths))/Max(d.total_cases)*100 CaseFatalityRate
, Max(d.total_cases)/Max(d.population)*100 InfectedRate
, Max(Convert(bigint, v.total_vaccinations))/Max(d.population)*100 DosesAdministered
From PortfolioProject..CovidDeaths d
Join PortfolioProject..CovidVaccinations v
	On d.location = v.location
	And d.date = d.date
Where d.continent is not null
Group by d.location
Order by 1
--This query took 90 seconds to execute. I will try CTE to shorten the query time.
Drop View If Exists SummarisedByCountry
Create View SummarisedByCountry
As
With SummarisedByCountry (Location, Popuplation, Total_Cases, Total_Deaths, Total_Vaccinations)
As
(
Select d.location, d.population, d.total_cases, Convert(int, d.total_deaths), Convert(bigint, v.total_vaccinations)
From PortfolioProject..CovidDeaths d
Inner Join (
	Select location, Max(date) as MaxDate, Max(total_vaccinations) total_vaccinations
	From PortfolioProject..CovidVaccinations
	Group by location
	) v
On d.location = v.location
	And d.date = v.MaxDate
Where d.continent is not null
)
Select *, Total_Deaths/Total_Cases*100 CaseFatalityRate, Total_Cases/Popuplation*100 InfectedRate, Total_Vaccinations/Popuplation*100 DosesAdministeredRate
From SummarisedByCountry
--Well I am not sure this is the optimal way but the long executed time is complete gone.

--by continent
Drop View If Exists SummarisedByContinent
Create View SummarisedByContinent
As
With SummarisedByContinent (Location, Popuplation, Total_Cases, Total_Deaths, Total_Vaccinations)
As
(
Select d.location, d.population, d.total_cases, Convert(int, d.total_deaths), Convert(bigint, v.total_vaccinations)
From PortfolioProject..CovidDeaths d
Inner Join (
	Select location, Max(date) as MaxDate, Max(total_vaccinations) total_vaccinations
	From PortfolioProject..CovidVaccinations
	Group by location
	) v
On d.location = v.location
	And d.date = v.MaxDate
Where d.location in 
	(Select continent
	From PortfolioProject..CovidDeaths)
)
Select *, Total_Deaths/Total_Cases*100 CaseFatalityRate, Total_Cases/Popuplation*100 InfectedRate, Total_Vaccinations/Popuplation*100 DosesAdministered
From SummarisedByContinent

--worldwide
Drop View If Exists SummarisedByWorldwide
Create View SummarisedByWorldwide
As
With SummarisedByWorldwide (Location, Popuplation, Total_Cases, Total_Deaths, Total_Vaccinations)
As
(
Select d.location, d.population, d.total_cases, Convert(int, d.total_deaths), Convert(bigint, v.total_vaccinations)
From PortfolioProject..CovidDeaths d
Inner Join (
	Select location, Max(date) as MaxDate, Max(total_vaccinations) total_vaccinations
	From PortfolioProject..CovidVaccinations
	Group by location
	) v
On d.location = v.location
	And d.date = v.MaxDate
Where d.location = 'World'
)
Select *, Total_Deaths/Total_Cases*100 CaseFatalityRate, Total_Cases/Popuplation*100 InfectedRate, Total_Vaccinations/Popuplation*100 DosesAdministered
From SummarisedByWorldwide

--So I need three main indices in a querry since Tableau Public prevents me from merging tables.
--Here goes all total of death, infection and new doses, per day, by country.
Select d.location, d.date, d.population
, v.new_vaccinations
, Sum(Convert(numeric, v.new_vaccinations)) Over (Partition by d.location Order by d.location, d.date) DosesAdministered
, d.new_cases
, Sum(d.new_cases) Over (Partition by d.location Order by d.location, d.date) TotalCases
, d.new_deaths
, Sum(Convert(numeric, d.new_deaths)) Over (Partition by d.location Order by d.location, d.date) TotalDeaths
From PortfolioProject..CovidDeaths d
Join PortfolioProject..CovidVaccinations v
	On d.location = v.location
	and d.date = v.date
Where d.continent is not null

