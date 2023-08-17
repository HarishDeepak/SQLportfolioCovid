---
SELECT location,date,total_cases,total_deaths,population
FROM [dbo].[CovidDeaths]
order by 1,2

SELECT *
FROM [dbo].[CovidDeaths]
where continent is not null
order by 1,2

--total deaths vs cases
--the prob of dying if we get covid
SELECT location,date,total_cases,total_deaths, (total_deaths/total_cases)*100 as deathpercentage
FROM [dbo].[CovidDeaths]
Where location like '%india%'
order by 1,2

--total cases vs population
--shows the percentage of population which got covid
SELECT location,date,total_cases,population, (total_cases/population)*100 as percentage
FROM [dbo].[CovidDeaths]
Where location like '%india%'
order by 1,2

--countries with highest infection RATE VS POPULATION
SELECT location,population,MAX(total_cases) as HighestInfectionCount,
MAX((total_cases/population)*100) as maxinfpercentage
FROM [dbo].[CovidDeaths]
--Where location like '%india%'
Group by location,population
order by maxinfpercentage desc

--Countries with highsest death per population
SELECT location,MAX(cast(total_deaths as int)) as HighestDeathCount
--MAX((total_deaths/total_cases)*100) as maxdeathpercentage
FROM [dbo].[CovidDeaths]
--Where location like '%india%'
where continent is not null
Group by location
order by HighestDeathCount desc

--in continents
SELECT continent,MAX(cast(total_deaths as int)) as HighestDeathCount
--MAX((total_deaths/total_cases)*100) as maxdeathpercentage
FROM [dbo].[CovidDeaths]
--Where location like '%india%'
where continent is not null
Group by continent
order by HighestDeathCount desc

Select MAx(Cast(total_deaths as int)) as sum
FROM [dbo].[CovidDeaths]
where continent like '%America%'
group by continent

--Global numbers
SELECT date,Sum(new_cases) as totalcases,
sum(cast(new_deaths as int)) as totaldeaths,
(sum(cast(new_deaths as int))/Sum(new_cases))*100 as deathpercentage
FROM [dbo].[CovidDeaths]
Where continent is not null
Group by date
order by 1,2


--Vaccinations
--total population vs vaccination
Select D.continent,D.location,D.date,D.population,V.new_vaccinations,
SUM(Cast(V.new_vaccinations as int)) 
over (partition by D.location order by D.date,D.location) as RollingPeopleVaccinated
From [dbo].[CovidDeaths] D
 Join [dbo].[CovidVaccinations] V
on D.location=V.location
and D.date=V.date
WHERE 
    D.continent IS NOT NULL
    AND D.population IS NOT NULL
order by 2,3

--Using cte
WITH popvsvac (Continent, Location, Date, Population, New_vaccinations, RollingPeopleVaccinated)
AS (
    SELECT
        D.continent,
        D.location,
        D.date,
        D.population,
        V.new_vaccinations,
        SUM(CAST(V.new_vaccinations AS INT)) OVER (PARTITION BY D.location ORDER BY D.date, D.location) AS RollingPeopleVaccinated
    FROM
        [dbo].[CovidDeaths] D
    JOIN
        [dbo].[CovidVaccinations] V
    ON
        D.location = V.location
        AND D.date = V.date
    WHERE
        D.continent IS NOT NULL
        AND D.population IS NOT NULL
)
SELECT
    *,
    (RollingPeopleVaccinated / Population) * 100 AS percentage
FROM
    popvsvac;


--using temp table
Drop table if exists #PercentPopulationVacinated
Create table #PercentPopulationVacinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)
Insert into #PercentPopulationVacinated
Select D.continent,D.location,D.date,D.population,V.new_vaccinations,
SUM(Cast(V.new_vaccinations as int)) 
over (partition by D.location order by D.date,D.location) as RollingPeopleVaccinated
From [dbo].[CovidDeaths] D
 Join [dbo].[CovidVaccinations] V
on D.location=V.location
and D.date=V.date
WHERE 
    D.continent IS NOT NULL
    AND D.population IS NOT NULL
order by 2,3
SELECT
    *,
    (RollingPeopleVaccinated / Population) * 100 AS percentage
FROM
#PercentPopulationVacinated


--creating view for tableau

Create View PercentPopulationVaccinated as
Select D.continent,D.location,D.date,D.population,V.new_vaccinations,
SUM(Cast(V.new_vaccinations as int)) 
over (partition by D.location order by D.date,D.location) as RollingPeopleVaccinated
From [dbo].[CovidDeaths] D
 Join [dbo].[CovidVaccinations] V
on D.location=V.location
and D.date=V.date
WHERE 
    D.continent IS NOT NULL
    AND D.population IS NOT NULL
--order by 2,3

Select *From
PercentPopulationVaccinated