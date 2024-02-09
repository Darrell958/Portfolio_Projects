--SELECT * 
--FROM covid_portfolio_project.dbo.covid_deaths;

--SELECT * 
--FROM covid_portfolio_project.dbo.covid_vaccinations;
USE covid_project;


SELECT location, date, total_cases, new_cases, total_deaths, population
FROM covid_project.dbo.covid_deaths
ORDER BY 1, 2;

-- Looking at Total Cases vs Total Deaths

SELECT iso_code, continent, location, date, total_cases, population, ROUND(((total_cases / population) * 100),2) AS "cases_per_population"
FROM dbo.covid_deaths
ORDER BY 4, 3;

-- Percent of Covid Cases out of the total population
SELECT iso_code, continent, location, date, total_cases, population, ROUND(((total_cases / population) * 100),2) AS "cases_per_population"
FROM covid_project.dbo.covid_deaths
WHERE location = 'United States'
ORDER BY 4, 3;

-- Change total_cases data type from nvachar to float

SELECT * FROM covid_project.dbo.covid_deaths;

EXEC sp_help '[covid_project].[dbo].[covid_deaths]';

ALTER TABLE [covid_project].[dbo].[covid_deaths]
ALTER COLUMN total_cases float;

-- Percentage of total cases out of total population 
SELECT iso_code, continent, location, date, total_cases, population, ROUND(((total_cases / population) * 100), 2) AS 'population_case_percentage'
FROM dbo.covid_deaths;


-- Percentage of total deaths out of the toal cases 
SELECT iso_code, continent, location, date, total_cases, total_deaths, population, ROUND(((total_deaths / total_cases) * 100), 2) AS 'case_death_percentage'
FROM dbo.covid_deaths;

-- Ordered Percentage of total deaths out of the toal cases 
SELECT location, date, total_cases, total_deaths, population, ROUND(((total_deaths / total_cases) * 100), 2) AS 'case_death_percentage'
FROM dbo.covid_deaths
ORDER BY 1,2;

-- United States Ordered Percentage of total deaths out of the toal cases 
-- Shows likelihood of death if you contract covid-19
SELECT location, date, total_cases, total_deaths, population, ROUND(((total_deaths / total_cases) * 100), 2) AS 'case_death_percentage'
FROM dbo.covid_deaths
WHERE location = 'United States'
ORDER BY 1,2;

-- Looking at Total Cases vs Population
-- Shows what percentage of the population has contracted covid-19
SELECT location, date, population, total_cases, ROUND(((total_cases/population) * 100), 2) AS 'contraction_percentage'
FROM dbo.covid_deaths
WHERE location = 'United States'
ORDER BY 1,2;


-- Look at contries with the highest infection rate compared to population
SELECT location, population, MAX(total_cases) AS 'highest_infection_count', MAX((total_cases/population) * 100) AS 'case_percentage'
FROM dbo.covid_deaths
GROUP BY location, population
ORDER BY case_percentage DESC;

-- Showing the countries with the highest death cout per population
SELECT location, MAX(cast(total_deaths as int)) as 'total_death_count'
FROM dbo.covid_deaths
where continent is not NULL
GROUP BY location
ORDER BY total_death_count DESC;


--LET'S BREAK THINGS DOWN BY CONTINENT

SELECT location, MAX(cast(total_deaths as int)) as 'total_death_count'
FROM dbo.covid_deaths
where continent is NULL
GROUP BY location
ORDER BY total_death_count DESC;

-- Showing continent with the highest death count
SELECT location, MAX(cast(total_deaths as int)) as 'total_death_count'
FROM dbo.covid_deaths
where continent is NULL
GROUP BY location
ORDER BY total_death_count DESC;


-- GLOBAL NUMBERS

-- ran into divide by zero error so this is a way to fix it by using the HAVING clause (I use the Having clause to exclude all 0 value for my divisor so now there will be no 0's to divide by becasue all of the rows where 'SUM(new_cases)' = 0, they were excluded. 
SELECT date, SUM(new_deaths) AS 'total_deaths', SUM(new_cases) AS 'total_cases', (((SUM(new_deaths)) / (SUM(new_cases))) *100) AS death_percentage
FROM dbo.covid_deaths
WHERE continent IS NOT NULL
GROUP BY date
HAVING SUM(new_cases) > 0 
ORDER BY 1,2;
 
 -- ran into divide by zero error so this is a way to fix it by using nullif
SELECT date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths,
SUM(cast(new_deaths as int)) / nullif(SUM(new_cases),0) * 100 as death_percentage
FROM dbo.covid_deaths
where continent is not NULL
GROUP BY date
ORDER BY 1,2

--GT

SELECT SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths,
SUM(cast(new_deaths as int)) / nullif(SUM(new_cases),0) * 100 as death_percentage
FROM dbo.covid_deaths
where continent is not NULL
--GROUP BY date
ORDER BY 1,2

-- Staple covid_deaths and covid_vaccinations on page
SELECT * 
FROM covid_deaths AS dea
JOIN covid_vaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
	AND dea.iso_code = vac.iso_code
	AND dea.continent = vac.continent;


-- Looking at total population vs Vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,
SUM(convert(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
	AS rolling_people_vaccinated
, (roling_people_vaccinated / population)*100
FROM covid_deaths AS dea
JOIN covid_vaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
	AND dea.iso_code = vac.iso_code
	AND dea.continent = vac.continent
WHERE dea.continent IS NOT NULL
ORDER BY 2,3;

-- USE CTE
WITH PopvsVac (continent, location, date, population, new_vaccinations, rolling_people_vaccinated) 

as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,
SUM(convert(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
	AS rolling_people_vaccinated
FROM covid_deaths AS dea
JOIN covid_vaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
	AND dea.iso_code = vac.iso_code
	AND dea.continent = vac.continent
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3;
)

SELECT *, (rolling_people_vaccinated / population) *100
FROM PopvsVac;


-- TEMP TABLE

DROP TABLE IF exists percent_population_vaccinated
CREATE TABLE percent_population_vaccinated (
	continent nvarchar(255),
	location nvarchar(255),
	date DATETIME,
	population NUMERIC,
	new_vaccinations NUMERIC,
	rolling_people_vaccinated NUMERIC
	)


INSERT INTO percent_population_vaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,
SUM(convert(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
	AS rolling_people_vaccinated
FROM covid_deaths AS dea
JOIN covid_vaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
	AND dea.iso_code = vac.iso_code
	AND dea.continent = vac.continent
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

SELECT *, (rolling_people_vaccinated / population) *100
FROM percent_population_vaccinated;

-- Creating View to store data for later visualizations

DROP VIEW IF EXISTS percent_people_vaccinated
CREATE VIEW percent_population_vaccinated AS
	
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	,
	SUM(convert(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
		AS rolling_people_vaccinated
	FROM covid_deaths AS dea
	JOIN covid_vaccinations AS vac
		ON dea.location = vac.location
		AND dea.date = vac.date
		AND dea.iso_code = vac.iso_code
		AND dea.continent = vac.continent
	WHERE dea.continent IS NOT NULL


SELECT * FROM percent_population_vaccinated;