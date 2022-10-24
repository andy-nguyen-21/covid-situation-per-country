--Data Source - Give a shout-out to OurWorldInData: https://github.com/owid/covid-19-data/tree/master/public/data

--My focus on this dataset will focus on three main indices: Death Rate/Count, Infected Rate/Count, and (Full) Vaccination Rate/Count (Doses Administered).
--To follow the trend, pattern or changes of Coronavirus pandemic, I will break them down periodically and geographically.
--For example: Global Death Rate per day, continentally Doses Administered per month.

--Let's start this by taking a look on a table
Select Top 10 *
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
Order by 3, 4

Select *
From PortfolioProject..CovidVaccinations
Order by 3, 4

--I am gonna explore the CovidDeaths table first
Select continent, location, date, new_cases, new_deaths, population
, Sum(Convert(int, new_deaths)) Over (Partition by location Order by location, date) Deaths 
--This is actually total_deaths. I just want to practice partition a bit
From PortfolioProject..CovidDeaths
Where continent is not null
--Basically, location is a country only when continent is mentioned
Order by 2, 3

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

--Enough. Now I will create views for later visualization.
