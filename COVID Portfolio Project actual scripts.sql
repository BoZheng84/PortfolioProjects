SELECT *
FROM ProfolioProject..CovidDeaths
--WHERE continent IS NOT NULL
ORDER BY 3, 4

--SELECT *
--FROM ProfolioProject..CovidVaccinations
--ORDER BY 3, 4

-- Select Data that we are going to using 
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM ProfolioProject..CovidDeaths
ORDER BY 1, 2

-- Looking at Total Cases vs Total Deaths
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases) * 100 as DeathPercentage
FROM ProfolioProject..CovidDeaths
ORDER BY 1, 2
-- Shows likelihood of dying if you contract covid in your country.
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases) * 100 as DeathPercentage
FROM ProfolioProject..CovidDeaths
WHERE location like '%states%' AND location IS NOT NULL
ORDER BY 1, 2

-- Looking at Total Cases vs Population
-- Shows us what percentage of population has gotten covid
SELECT location, date, population, total_cases, (total_cases/population) * 100 as  PercentPolulationInfected
FROM ProfolioProject..CovidDeaths
WHERE location LIKE '%states%' AND location IS NOT NULL
ORDER BY 1, 2

SELECT location, date, population, total_cases, (total_cases/population) * 100 AS PercentPopulatonInfected
FROM ProfolioProject..CovidDeaths
ORDER BY 1, 2

-- Looking at Countries with Highest Infection Rate compared to Population
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population)) * 100 AS PercentPopulatonInfected /*We only look at the highest.*/
FROM ProfolioProject..CovidDeaths
GROUP BY location, population
ORDER BY PercentPopulatonInfected DESC

-- Showing Countries with Highest Death Count per Population
/*It has an issue with the data type for MAX and it just has to do with how the data type is read when you use this aggregate fuction,
we need to convert it or cast it. We need to cast this as an integer so that's read as a numeric.*/
SELECT location, MAX(total_deaths) as TotalDeathCount
FROM ProfolioProject..CovidDeaths
GROUP BY location
ORDER BY TotalDeathCount DESC
-- Using cast to convert this as an integer.
SELECT location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM ProfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

-- LET'S BREAK THINGS DOWN BY CONTINENT
SELECT continent, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM ProfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

SELECT location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM ProfolioProject..CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY TotalDeathCount DESC  

SELECT continent, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM ProfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC  

-- Showing contintents with the highest death count per population
SELECT continent, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM ProfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- GLOBAL NUMBERS
SELECT date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases) * 100 as DeathPercentage
FROM ProfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1, 2

SELECT SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases) * 100 as DeathPercentage
FROM ProfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2

-- Open CovidVaccinations file
SELECT *
FROM ProfolioProject..CovidVaccinations

-- Join this two table together
SELECT *
FROM ProfolioProject..CovidDeaths dea
JOIN ProfolioProject..CovidVaccinations vac
	ON dea.location = vac.location and dea.date = vac.date

-- Looking at Total Population vs Vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM ProfolioProject..CovidDeaths dea
JOIN ProfolioProject..CovidVaccinations vac
	ON dea.location = vac.location and dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(cast(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location)
FROM ProfolioProject..CovidDeaths dea
JOIN ProfolioProject..CovidVaccinations vac
	ON dea.location = vac.location and dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3

/*rolling add*/
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date)
FROM ProfolioProject..CovidDeaths dea
JOIN ProfolioProject..CovidVaccinations vac
	ON dea.location = vac.location and dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3 

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(convert(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
, (RollingPeopleVaccinated/population) * 100
FROM ProfolioProject..CovidDeaths dea
JOIN ProfolioProject..CovidVaccinations vac
	ON dea.location = vac.location and dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3
/*as you can see we're getting an error you can't use column (RollingPeopleVaccinated) that you just created it to this.
What we need to do is to create either a cte or a temp table.*/

-- USE CTE
/*If the number of columns in the cte is different than the number of columns select function here, it will cause an error.*/
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(convert(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM ProfolioProject..CovidDeaths dea
JOIN ProfolioProject..CovidVaccinations vac
	ON dea.location = vac.location and dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *
FROM PopvsVac

WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(convert(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM ProfolioProject..CovidDeaths dea
JOIN ProfolioProject..CovidVaccinations vac
	ON dea.location = vac.location and dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated/Population) * 100
FROM PopvsVac

-- TEMP TABLE
DROP TABLE if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric, 
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)
/*for this convert function we cannot continue to use int because of overflow, so we need to use numeric instead.*/
INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(convert(numeric, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM ProfolioProject..CovidDeaths dea
JOIN ProfolioProject..CovidVaccinations vac
	ON dea.location = vac.location and dea.date = vac.date
--WHERE dea.continent IS NOT NULL

SELECT *, (RollingPeopleVaccinated/Population) * 100
FROM #PercentPopulationVaccinated

-- Creating View to store data for later visualizations
Create View PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(convert(numeric, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM ProfolioProject..CovidDeaths dea
JOIN ProfolioProject..CovidVaccinations vac
	ON dea.location = vac.location and dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *
FROM PercentPopulationVaccinated
