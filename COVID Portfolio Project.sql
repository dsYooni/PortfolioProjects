/*
COVID 19 Data Exploration

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Funcations, Creating Views, Converting Data Types

*/

Select *
FROM [Portfolio Project]..CovidDeaths$
where Continent is NOT NULL
ORDER BY 3,4

Select *
FROM [Portfolio Project]..CovidVaccinations$
ORDER BY 3,4

-- Select Data that we are going to be starting with

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM [Portfolio Project]..CovidDeaths$
WHERE continent is NOT NULL
ORDER BY 1,2

-- Total Cases v Total Deaths
-- Shows likeihood of dying once you contract COVID in your country

SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM [Portfolio Project]..CovidDeaths$
WHERE location LIKE '%states%'
AND continent is NOT NULL
ORDER BY 1,2

-- Total Cases v Population
-- Shows what percentage of population infected with COVID

SELECT Location, date, Population, total_cases, (total_cases/Population)*100 AS DeathPercentage
FROM [Portfolio Project]..CovidDeaths$
--WHERE location LIKE '%states%'
ORDER BY 1,2

-- Countries with Highest Infection Rate compared to Population

SELECT Location, Population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/Population))*100 AS PercentPopulationInfected
FROM [Portfolio Project]..CovidDeaths$
--WHERE location LIKE '%states%'
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC

-- Countries with Highest Death Count per Population

SELECT Location, MAX(cast(total_deaths AS INT)) AS TotalDeathCount
FROM [Portfolio Project]..CovidDeaths$
--WHERE location LIKE "$states$'
WHERE continent IS NOT NULL
GROUP BY Location
ORDER BY TotalDeathCount DESC


-- BREAKING THINGS DOWN BY CONTINENT

-- Showing continents with the highest death count per population

SELECT continent, MAX(cast(total_deaths AS INT)) AS TotalDeathCount
FROM [Portfolio Project]..CovidDeaths$
--WHERE location LIKE "%states%'
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC


--GLOBAL NUMBERS

SELECT date, SUM(total_cases) AS GlobalTotalCases, SUM(cast(total_deaths as INT)) AS GlobalTotalDeaths, SUM(cast(total_deaths as INT))/SUM(total_cases)*100 AS GlobalDeathPercentage
FROM [Portfolio Project]..CovidDeaths$
--WHERE location LIKE "%states%'
WHERE continent IS NOT NULL
GROUP BY date
--ORDER BY 1, 2


-- Total Population v Vaccinations
-- Shows Percentage of Population that has recieved at least one COVID vaccine

SELECT dea.continent, dea.location, dea.date, dea.population, cast(vac.new_vaccinations AS bigINT) AS NewVaccinations
, SUM(cast(vac.new_vaccinations AS bigINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM [Portfolio Project]..CovidDeaths$ dea
JOIN [Portfolio Project]..CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is NOT NULL
--ORDER BY continent ASC, location ASC, date ASC
ORDER BY 2,3

--Use CTE to perform Calculation on Partition By in previous query

With CTE_PopvsVac (continent, location, date, population, New_Vaccinations, RollingPeopleVaccinated) 
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, cast(vac.new_vaccinations AS bigINT) AS NewVaccinations
, SUM(cast(vac.new_vaccinations AS bigINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100 AS VaccinatedPercentage
FROM [Portfolio Project]..CovidDeaths$ dea
JOIN [Portfolio Project]..CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is NOT NULL
--ORDER BY 2,3
)
SELECT *, (RollingPeopleVaccinated/population)*100
FROM CTE_PopvsVac


--Using Temp Table to perform Calculation on Partition By i previous query

DROP TABLE if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent NVARCHAR(255), 
location NVARCHAR(255),
date datetime,
population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, cast(vac.new_vaccinations AS bigINT) AS NewVaccinations
, SUM(cast(vac.new_vaccinations AS bigINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100 AS VaccinatedPercentage
FROM [Portfolio Project]..CovidDeaths$ dea
JOIN [Portfolio Project]..CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
--WHERE dea.continent is NOT NULL
--ORDER BY 2,3

SELECT *, (RollingPeopleVaccinated/population)*100
FROM #PercentPopulationVaccinated


--Creating View to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, cast(vac.new_vaccinations AS bigINT) AS NewVaccinations
, SUM(cast(vac.new_vaccinations AS bigINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100 AS VaccinatedPercentage
FROM [Portfolio Project]..CovidDeaths$ dea
JOIN [Portfolio Project]..CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is NOT NULL
