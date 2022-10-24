Select *
From PortfolioProject..CovidDeaths
--Where location = 'North Korea'
Order by 3, 4

--I am gonna work with the following data:

Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
Order by 1, 2

--Cases and deaths
--The likelihood death rate in your country
Select Location, date, total_cases, total_deaths, round((total_deaths/total_cases)*100, 2) DeathPercentage
From PortfolioProject..CovidDeaths
Where location like '%Viet%'
Order by 1, 2

--Cases and Population in a country 

Select Location, date, total_cases, population, (total_cases/population)*100 InfectedPercentage
From PortfolioProject..CovidDeaths
Where location like '%Viet%'
Order by 1, 2

--Hitherto global ranking of the Infection Rate (the word 'hitherto' is severely unpopular but I've just learn it recently so :D)

Select Location, total_cases, population, round((total_cases/population)*100, 2) InfectedPercentage
From PortfolioProject..CovidDeaths
Where Convert(Varchar(25), date, 126) like '%2022-10-19%'
--For the lack of data, you may want to add this:
--AND location Not IN ('International', 'North Korea')
Order by InfectedPercentage DESC

--Similarly, I will rank the global Death Count

--Convert the data type to integer
Select location, Max(Convert(int, total_deaths)) TotalDeaths
From PortfolioProject..CovidDeaths
Where continent is not null
Group by location
Order by TotalDeaths DESC

--Or I can use CAST function
Select location, Max(Cast(total_deaths as int)) TotalDeaths
From PortfolioProject..CovidDeaths
Where continent is not null
Group by location
Order by TotalDeaths DESC

--Let's see the total deaths by continent which is not working exactly as I expect
Select location, Max(Cast(total_deaths as int)) TotalDeaths
From PortfolioProject..CovidDeaths
Where continent is null
Group by location
Order by TotalDeaths DESC

--Because the continent is not actually continent so I have to adjust the query a bit
Select location, Max(Cast(total_deaths as int)) TotalDeaths
From PortfolioProject..CovidDeaths Dea
Where location in
	(Select continent
	From PortfolioProject..CovidDeaths)
Group by location
Order by TotalDeaths DESC

--Global numbers
--Case fatality rate (CFR) per country atm
Select location, Max(total_cases) Cases, Max(Convert(int, total_deaths)) Deaths, Max(Convert(int, total_deaths))/Max(total_cases)*100 CaseFatalityRate
From PortfolioProject..CovidDeaths Dea
Where continent is not null
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
With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, DosesAministered)
As
(
Select dea.continent, dea.location, dea.date, dea.population, convert(int, vac.new_vaccinations) new_vaccinations
, Sum(convert(bigint, vac.new_vaccinations)) Over (Partition by dea.location Order by dea.location, dea.date) DosesAministered
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	And dea.date = vac.date
Where dea.continent is not null
--Order by 2, 3
)
Select *, DosesAministered/Population*100 VaccinationRate
From PopvsVac
--Where DosesAministered/Population*100 > 300
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
DosesAministered numeric
)

Insert into #VaccinationRate
Select dea.continent, dea.location, dea.date, dea.population, convert(int, vac.new_vaccinations) new_vaccinations
, Sum(convert(bigint, vac.new_vaccinations)) Over (Partition by dea.location Order by dea.location, dea.date) DosesAministered
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	And dea.date = vac.date
Where dea.continent is not null

Select *, DosesAministered/Population*100 VaccinationRate
From #VaccinationRate

--Select *
--From PortfolioProject..CovidDeaths Dea

--Select *
--From PortfolioProject..CovidVaccinations Vac
