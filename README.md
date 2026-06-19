# COVID-19 Vaccination & Mortality Analysis — SQL Portfolio

Exploratory data analysis of global COVID-19 death and vaccination statistics using advanced T-SQL techniques: window functions, CTEs, temp tables, JOINs, and views. Built on the Our World in Data COVID-19 dataset (loaded into SQL Server).

[![SQL Server](https://img.shields.io/badge/SQL_Server-CC2927?style=for-the-badge&logo=microsoft-sql-server&logoColor=white)](https://www.microsoft.com/en-us/sql-server)
[![LinkedIn](https://img.shields.io/badge/linkedin-0A66C2?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/harishdeepak/)
[![GitHub](https://img.shields.io/badge/github-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/HarishDeepak)

---

## Dataset

Two tables sourced from the Our World in Data COVID-19 dataset:

| Table | Key Columns |
|---|---|
| `CovidDeaths` | location, continent, date, total_cases, new_cases, total_deaths, new_deaths, population |
| `CovidVaccinations` | location, date, new_vaccinations, total_vaccinations, people_vaccinated |

Files: `CovidDeaths.xlsx`, `CovidVaccinations.xlsx`, `Covid.xlsx` (combined view)

---

## Analyses Implemented

### 1. Death Rate Analysis
```sql
SELECT location, date, total_cases, total_deaths,
       (total_deaths / total_cases) * 100 AS deathpercentage
FROM [dbo].[CovidDeaths]
WHERE location LIKE '%india%'
ORDER BY 1, 2;
```
- Death percentage by country and date
- India-specific drill-down throughout all analyses

### 2. Infection Rate vs. Population
```sql
SELECT location, population,
       MAX(total_cases) AS HighestInfectionCount,
       MAX((total_cases / population) * 100) AS maxinfpercentage
FROM [dbo].[CovidDeaths]
GROUP BY location, population
ORDER BY maxinfpercentage DESC;
```
- Countries ranked by peak infection rate relative to population

### 3. Mortality by Country and Continent
```sql
SELECT location, MAX(CAST(total_deaths AS INT)) AS HighestDeathCount
FROM [dbo].[CovidDeaths]
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY HighestDeathCount DESC;
```
- Country-level and continent-level total death counts

### 4. Global Aggregation by Date
```sql
SELECT date,
       SUM(new_cases) AS totalcases,
       SUM(CAST(new_deaths AS INT)) AS totaldeaths,
       (SUM(CAST(new_deaths AS INT)) / SUM(new_cases)) * 100 AS deathpercentage
FROM [dbo].[CovidDeaths]
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1, 2;
```
- Daily global new cases, new deaths, and case fatality rate

### 5. Rolling Vaccination Count (Window Function)
```sql
SELECT D.location, D.date, D.population, V.new_vaccinations,
       SUM(CAST(V.new_vaccinations AS INT))
           OVER (PARTITION BY D.location ORDER BY D.date) AS RollingPeopleVaccinated
FROM [dbo].[CovidDeaths] D
JOIN [dbo].[CovidVaccinations] V
    ON D.location = V.location AND D.date = V.date
WHERE D.continent IS NOT NULL;
```
- Running total of people vaccinated, reset per country

### 6. Vaccination Coverage — CTE Approach
```sql
WITH popvsvac (Continent, Location, Date, Population, New_vaccinations, RollingPeopleVaccinated)
AS (
    SELECT ..., SUM(...) OVER (PARTITION BY D.location ORDER BY D.date) AS RollingPeopleVaccinated
    FROM CovidDeaths D JOIN CovidVaccinations V ON ...
)
SELECT *, (RollingPeopleVaccinated / Population) * 100 AS percentage
FROM popvsvac;
```
- Percentage of population vaccinated over time using a CTE

### 7. Vaccination Coverage — Temp Table Approach
```sql
DROP TABLE IF EXISTS #PercentPopulationVaccinated;
CREATE TABLE #PercentPopulationVaccinated (
    Continent nvarchar(255), Location nvarchar(255), Date datetime,
    Population numeric, New_vaccinations numeric, RollingPeopleVaccinated numeric
);
INSERT INTO #PercentPopulationVaccinated
SELECT ... SUM(...) OVER (PARTITION BY D.location ORDER BY D.date) ...
FROM CovidDeaths D JOIN CovidVaccinations V ON ...
SELECT *, (RollingPeopleVaccinated / Population) * 100 AS percentage
FROM #PercentPopulationVaccinated;
```
- Same computation via a temp table (demonstrates alternative approach)

### 8. Reusable View
```sql
CREATE VIEW PercentPopulationVaccinated AS
SELECT ..., SUM(...) OVER (PARTITION BY D.location ORDER BY D.date) AS RollingPeopleVaccinated
FROM CovidDeaths D JOIN CovidVaccinations V ON ...
WHERE D.continent IS NOT NULL;
```
- Encapsulates the vaccination coverage query for reuse in dashboards / BI tools

---

## SQL Techniques Demonstrated

| Technique | Usage |
|---|---|
| `JOIN` (INNER) | CovidDeaths × CovidVaccinations on location + date |
| `SUM() OVER (PARTITION BY ... ORDER BY ...)` | Rolling vaccination totals per country |
| `MAX()` aggregation | Peak infection count and death count per location |
| `CAST()` | Converting string death counts to INT for arithmetic |
| `CTE (WITH ... AS)` | Derived vaccination percentage table |
| `Temp Table (CREATE TABLE #...)` | Alternative to CTE for multi-step computation |
| `CREATE VIEW` | Reusable vaccination coverage query |
| `WHERE continent IS NOT NULL` | Filtering out continent-level aggregate rows |
| India-specific `LIKE '%india%'` | Country-level drill-down |

---

## File Structure

| File | Contents |
|---|---|
| `Coviddatasetproject.sql` | All T-SQL queries (analysis, CTE, temp table, view) |
| `CovidDeaths.xlsx` | Deaths dataset (load to SQL Server as `dbo.CovidDeaths`) |
| `CovidVaccinations.xlsx` | Vaccination dataset (load as `dbo.CovidVaccinations`) |
| `Covid.xlsx` | Combined reference spreadsheet |

---

## Setup

**Requirements:** SQL Server (any edition) or SQL Server Express; SSMS or Azure Data Studio

1. Import `CovidDeaths.xlsx` into table `[dbo].[CovidDeaths]`
2. Import `CovidVaccinations.xlsx` into table `[dbo].[CovidVaccinations]`
3. Run `Coviddatasetproject.sql` in order

---

## References

- Our World in Data COVID-19 Dataset: https://ourworldindata.org/covid-deaths
