-- Selecting specific columns from CovidDeaths table and ordering by location and date
SELECT location, date, total_cases, total_deaths, population
FROM [dbo].[CovidDeaths]
ORDER BY 1, 2;

-- Selecting all columns from CovidDeaths table where continent is not null and ordering by location and date
SELECT *
FROM [dbo].[CovidDeaths]
WHERE continent IS NOT NULL
ORDER BY 1, 2;

-- Calculating death percentage for COVID cases in India and ordering by location and date
SELECT location, date, total_cases, total_deaths, (total_deaths / total_cases) * 100 AS deathpercentage
FROM [dbo].[CovidDeaths]
WHERE location LIKE '%india%'
ORDER BY 1, 2;

-- Calculating COVID cases percentage of population in India and ordering by location and date
SELECT location, date, total_cases, population, (total_cases / population) * 100 AS percentage
FROM [dbo].[CovidDeaths]
WHERE location LIKE '%india%'
ORDER BY 1, 2;

-- Finding countries with the highest infection rate vs population and ordering by the maximum infection percentage in descending order
SELECT location, population, MAX(total_cases) AS HighestInfectionCount,
MAX((total_cases / population) * 100) AS maxinfpercentage
FROM [dbo].[CovidDeaths]
-- WHERE location LIKE '%india%'
GROUP BY location, population
ORDER BY maxinfpercentage DESC;

-- Finding countries with the highest death count per population and ordering by the highest death count in descending order
SELECT location, MAX(CAST(total_deaths AS INT)) AS HighestDeathCount
FROM [dbo].[CovidDeaths]
-- WHERE location LIKE '%india%'
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY HighestDeathCount DESC;

-- Finding continents with the highest death count and ordering by the highest death count in descending order
SELECT continent, MAX(CAST(total_deaths AS INT)) AS HighestDeathCount
FROM [dbo].[CovidDeaths]
-- WHERE location LIKE '%india%'
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY HighestDeathCount DESC;

-- Finding the maximum death count in America continent
SELECT MAX(CAST(total_deaths AS INT)) AS sum
FROM [dbo].[CovidDeaths]
WHERE continent LIKE '%America%'
GROUP BY continent;

-- Finding global COVID statistics including total cases, total deaths, and death percentage, and ordering by date
SELECT date, SUM(new_cases) AS totalcases,
SUM(CAST(new_deaths AS INT)) AS totaldeaths,
(SUM(CAST(new_deaths AS INT)) / SUM(new_cases)) * 100 AS deathpercentage
FROM [dbo].[CovidDeaths]
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1, 2;

-- Joining CovidDeaths and CovidVaccinations tables to calculate vaccination statistics
SELECT D.continent, D.location, D.date, D.population, V.new_vaccinations,
SUM(CAST(V.new_vaccinations AS INT)) 
OVER (PARTITION BY D.location ORDER BY D.date, D.location) AS RollingPeopleVaccinated
FROM [dbo].[CovidDeaths] D
JOIN [dbo].[CovidVaccinations] V
ON D.location = V.location
AND D.date = V.date
WHERE D.continent IS NOT NULL
AND D.population IS NOT NULL
ORDER BY 2, 3;

-- Using common table expression (CTE) to calculate vaccination percentages
WITH popvsvac (Continent, Location, Date, Population, New_vaccinations, RollingPeopleVaccinated)
AS (
    SELECT D.continent, D.location, D.date, D.population, V.new_vaccinations,
    SUM(CAST(V.new_vaccinations AS INT)) OVER (PARTITION BY D.location ORDER BY D.date, D.location) AS RollingPeopleVaccinated
    FROM [dbo].[CovidDeaths] D
    JOIN [dbo].[CovidVaccinations] V
    ON D.location = V.location
    AND D.date = V.date
    WHERE D.continent IS NOT NULL
    AND D.population IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated / Population) * 100 AS percentage
FROM popvsvac;

-- Using temporary table to store vaccination data and calculating vaccination percentages
DROP TABLE IF EXISTS #PercentPopulationVaccinated;
CREATE TABLE #PercentPopulationVaccinated
(
    Continent nvarchar(255),
    Location nvarchar(255),
    Date datetime,
    Population numeric,
    New_vaccinations numeric,
    RollingPeopleVaccinated numeric
);
INSERT INTO #PercentPopulationVaccinated
SELECT D.continent, D.location, D.date, D.population, V.new_vaccinations,
SUM(CAST(V.new_vaccinations AS INT)) 
OVER (PARTITION BY D.location ORDER BY D.date, D.location) AS RollingPeopleVaccinated
FROM [dbo].[CovidDeaths] D
JOIN [dbo].[CovidVaccinations] V
ON D.location = V.location
AND D.date = V.date
WHERE D.continent IS NOT NULL
AND D.population IS NOT NULL
ORDER BY 2, 3;
SELECT *, (RollingPeopleVaccinated / Population) * 100 AS percentage
FROM #PercentPopulationVaccinated;

-- Creating a view to encapsulate the population vs vaccination data
CREATE VIEW PercentPopulationVaccinated AS
SELECT D.continent, D.location, D.date, D.population, V.new_vaccinations,
SUM(CAST(V.new_vaccinations AS INT)) 
OVER (PARTITION BY D.location ORDER BY D.date, D.location) AS RollingPeopleVaccinated
FROM [dbo].[CovidDeaths] D
JOIN [dbo].[CovidVaccinations] V
ON D.location = V.location
AND D.date = V.date
WHERE D.continent IS NOT NULL
AND D.population IS NOT NULL;

-- Querying the created view
SELECT *
FROM PercentPopulationVaccinated;
