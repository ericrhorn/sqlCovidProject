SELECT * FROM coviddeaths
ORDER BY 3,4;

SELECT * FROM covidvaccinations
ORDER BY 3,4;


-- looking at Location date and case total 
SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM coviddeaths
WHERE continent != ''
ORDER BY 1,2;

SELECT Location, SUM(total_cases) as totalCases, population, population/SUM(total_cases)*100 as percentOfPop
FROM coviddeaths
WHERE continent != ''
group by location, population;


-- total cases vs total deaths (know percent of death of infected people) in the US
SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)* 100 as DeathPercent 
FROM coviddeaths
WHERE location like '%States%'
and continent != ''
ORDER BY 1,2;


-- total cases vs population 
SELECT Location, date, total_cases, population, (total_cases/population)* 100 as ContractionRate 
FROM coviddeaths
WHERE location like '%States%'
ORDER BY 1,2;
 
 
-- countries with highest Contraction rate
SELECT Location, population, MAX(total_cases) as TotalInfected, MAX((total_cases/population))* 100 as PercentPopInfected 
FROM coviddeaths
-- WHERE location like '%States%'
WHERE continent != ''
GROUP BY location, population
ORDER BY PercentPopInfected desc;

SELECT Location, population, date, MAX(total_cases) as TotalInfected, MAX((total_cases/population))* 100 as PercentPopInfected 
FROM coviddeaths
-- WHERE location like '%States%'
WHERE continent != ''
GROUP BY location, population, date
ORDER BY location, date;


SELECT continent, MAX(total_cases) as TotalInfected, MAX((total_cases/population))* 100 as PercentPopInfected 
FROM coviddeaths
-- WHERE location like '%States%'
WHERE continent != ''
GROUP BY continent
ORDER BY PercentPopInfected desc;


-- countries with highest death rate per pop
SELECT Location, MAX(CAST(total_deaths AS UNSIGNED)) as TotalDeaths
FROM coviddeaths
-- WHERE location like '%States%'
WHERE continent != ''
GROUP BY location
ORDER BY TotalDeaths desc;


-- order by location/continent 
SELECT location, MAX(CAST(total_deaths AS UNSIGNED)) as TotalDeaths, SUM(population) as totalPopulation
FROM coviddeaths
-- WHERE location like '%States%'
WHERE continent = ''
and location not in ('World', 'European Union', 'High income', 'Upper middle income', 'Lower middle income', 'Low income')
-- and location not like '%High%'
-- and location not like '%Upper%'
-- and location not like '%Lower%'
-- and location not like '%Low%'
GROUP BY location
ORDER BY TotalDeaths desc;





-- order by continent
SELECT continent, MAX(CAST(total_deaths AS UNSIGNED)) as TotalDeaths
FROM coviddeaths
-- WHERE location like '%States%'
WHERE continent != ''
-- and location not like '%World%'
-- and location not like '%High%'
-- and location not like '%Upper%'
-- and location not like '%Lower%'
-- and location not like '%Low%'
GROUP BY continent 
ORDER BY TotalDeaths desc;

-- SELECT location, SUM(CAST(new_deaths AS UNSIGNED)) as totalDeaths
-- FROM coviddeaths
-- WHERE continent != ''
-- GROUP BY location
-- ORDER BY totalDeaths DESC;



-- global data by date
SELECT date, SUM(new_cases) as total_cases, SUM(CAST(new_deaths AS UNSIGNED)) as total_deaths, SUM(CAST(new_deaths AS UNSIGNED))/SUM(new_cases)*100 as DeathPercent
FROM coviddeaths
WHERE continent != ''
GROUP BY date
ORDER BY 1,2;


-- global data
SELECT SUM(new_cases) as total_cases, SUM(CAST(new_deaths AS UNSIGNED)) as total_deaths, SUM(CAST(new_deaths AS UNSIGNED))/SUM(new_cases)*100 as DeathPercent
FROM coviddeaths
WHERE continent != ''
-- GROUP BY date
ORDER BY 1,2;



SELECT * FROM covidvaccinations;


-- join death and vacination tables 

SELECT * FROM coviddeaths dea
JOIN covidvaccinations vac
on dea.location = vac.location
and dea.date = vac.date;


-- total pop vs vacination 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations 
FROM coviddeaths dea
JOIN covidvaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent != ''
-- GROUP BY dea.continent
ORDER BY 2,3;


SELECT dea.continent, dea.location, dea.population, vac.total_vaccinations 
FROM coviddeaths dea
JOIN covidvaccinations vac
	on dea.location = vac.location
WHERE dea.continent != ''
-- GROUP BY dea.continent
ORDER BY 2,3;



SELECT dea.continent, dea.population, vac.new_vaccinations 
FROM coviddeaths dea
JOIN covidvaccinations vac
	on dea.continent = vac.continent
WHERE dea.continent != ''
-- GROUP BY dea.continent
ORDER BY 2,3;


-- SELECT dea.location, MAX(CAST(total_deaths AS UNSIGNED)) as TotalDeaths, SUM(population) as totalPopulation, SUM(vac.people_fully_vaccinated) AS totalVaccinations
-- FROM coviddeaths dea
-- JOIN covidvaccinations vac
-- 	on dea.location = vac.location
-- WHERE dea.continent = ''
-- and dea.location not in ('World', 'European Union', 'High income', 'Upper middle income', 'Lower middle income', 'Low income')

-- GROUP BY dea.location
-- ORDER BY totalVaccinations desc;






-- rolling count of vaccinations by country 

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER by dea.location, dea.date) as VacineCount
-- (VaccineCount/population)*100 - this will error since you cant use a collumn you just created and then use it in the next one must use a cte or temp table
FROM coviddeaths dea
JOIN covidvaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent != ''
-- GROUP BY dea.continent
ORDER BY 2,3;


-- use CTE (common table expression)
with PopVsVac (continent, location, date, population, new_vaccinations, VaccineCount)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER by dea.location, dea.date) as VaccineCount
FROM coviddeaths dea
JOIN covidvaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent != ''
-- and dea.location like '%States%'
-- GROUP BY dea.continent
-- ORDER BY 2,3
)
SELECT *, (VaccineCount/population)*100 as PercentofPopVaccinated FROM PopVsVac;


-- cte -- percent vaccinated as a country total 

with PopVsVac (continent, location, population, date, new_vaccinations, VaccineCount)
as
(
SELECT dea.continent, dea.location, dea.population, dea.date, vac.new_vaccinations, 
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER by dea.location, dea.date) as VaccineCount
FROM coviddeaths dea
JOIN covidvaccinations vac
	on dea.location = vac.location
    and dea.date = vac.date
WHERE dea.continent != ''
)
SELECT *, (VaccineCount/population)*100 as PercentofPopVaccinated FROM PopVsVac;



-- create a temp table 

DROP Table if exists PercentPopVaccinated2;
CREATE TEMPORARY TABLE PercentPopVaccinated2 as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER by dea.location, dea.date) as VaccineCount
-- (VaccineCount/population)*100
FROM coviddeaths dea
JOIN covidvaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent != '';
SELECT *, (VaccineCount/population)*100 as PercentPopVaccinated FROM PercentPopVaccinated2;


-- create view for tableau visualization


-- percent of population with vacinations 
Create View PercentPopVacinated as
with PopVsVac (continent, location, date, population, new_vaccinations, VaccineCount)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER by dea.location, dea.date) as VaccineCount
FROM coviddeaths dea
JOIN covidvaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent != ''
-- and dea.location like '%States%'
-- GROUP BY dea.continent
-- ORDER BY 2,3
)
SELECT *, (VaccineCount/population)*100 as PercentofPopVaccinated FROM PopVsVac;

-- calling data from created view
SELECT * FROM percentpopvacinated;


-- total deaths worldwide and percent of deaths per case
CREATE VIEW totalDeaths as
SELECT SUM(new_cases) as totalCases, SUM(new_deaths) as totalDeaths, SUM(new_deaths)/SUM(new_cases)*100 as deathPercent
FROM coviddeaths
WHERE continent != ''
ORDER BY 1,2;

SELECT * FROM totalDeaths;


-- total deaths by continent
CREATE VIEW totalDeathsByContinent as
SELECT location, MAX(CAST(total_deaths AS UNSIGNED)) as TotalDeaths
FROM coviddeaths
-- WHERE location like '%States%'
WHERE continent = ''
and location not in ('World', 'European Union', 'High income', 'Upper middle income', 'Lower middle income', 'Low income')
GROUP BY location
ORDER BY TotalDeaths desc;

SELECT * FROM totalDeathsByContinent;


-- percent of population infected by country
CREATE VIEW percentInfectedByCountry as 
SELECT Location, population, MAX(total_cases) as TotalInfected, MAX((total_cases/population))* 100 as PercentPopInfected 
FROM coviddeaths
-- WHERE location like '%States%'
WHERE continent != ''
GROUP BY location, population
ORDER BY PercentPopInfected desc;

SELECT * FROM percentInfectedByCountry;


-- infected population by date and locaiton
CREATE VIEW timeLineOfPercentInfected as 
SELECT Location, population, date, MAX(total_cases) as TotalInfected, MAX((total_cases/population))* 100 as PercentPopInfected 
FROM coviddeaths
-- WHERE location like '%States%'
WHERE continent != ''
GROUP BY location, population, date
ORDER BY location, date;

SELECT * FROM timeLineOfPercentInfected




