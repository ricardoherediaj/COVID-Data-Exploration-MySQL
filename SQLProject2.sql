SELECT * 
FROM covid_vaccinations.coviddeaths
ORDER BY 3,4;

SELECT * 
FROM covid_vaccinations.covidvaccinations2
ORDER BY 3,4;

-- Select the data we are going to use 
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM covid_vaccinations.coviddeaths
ORDER BY 1,2;

-- Look at Total Cases vs Total Deaths 
-- Shows likelihood of dying if you contract Covid in your country 

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage 
FROM covid_vaccinations.coviddeaths
WHERE location like '%spain%'
ORDER BY 1,2; 

-- Look at Total Cases vs Total Deaths 
-- Shows what percentage of population has gotten Covid 

SELECT location, date, total_cases, Population, (total_cases/population)*100 AS PercentPopulationInfected
FROM covid_vaccinations.coviddeaths
-- WHERE location LIKE '%spain%'
ORDER BY 1,2; 

-- Look at countries with highest infection rate compared to population 

SELECT location, Population, MAX(total_cases) as HighestInfectionCount,  MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM covid_vaccinations.coviddeaths
GROUP BY location, population 
ORDER BY PercentPopulationInfected desc; 

-- Showing Countries with the Highest Death Count per Population
SELECT location, MAX(cast(total_deaths AS SIGNED int)) as TotalDeathCount
FROM covid_vaccinations.coviddeaths
WHERE continent is not NULL
GROUP BY location
ORDER BY TotalDeathCount desc; 

-- LET'S BREAK THINGS DOWN BY CONTINENT

-- Showing Continents with the Highest Death Count per Population

SELECT continent, MAX(cast(total_deaths AS SIGNED int)) as TotalDeathCount
FROM covid_vaccinations.coviddeaths
WHERE continent is not NULL
GROUP BY continent
ORDER BY TotalDeathCount desc;

-- GLOBAL NUMBERS

SELECT date, SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS SIGNED INT)), SUM(cast(new_deaths AS SIGNED INT))/SUM(new_cases)*100 AS DeathPercentage 
FROM covid_vaccinations.coviddeaths
--  WHERE location like '%spain%'
WHERE continent is not NULL
group by date 
ORDER BY 1,2;

CREATE VIEW DeathPercentage AS 
SELECT date, SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS SIGNED INT)), SUM(cast(new_deaths AS SIGNED INT))/SUM(new_cases)*100 AS DeathPercentage 
FROM covid_vaccinations.coviddeaths
WHERE continent IS NOT NULL;

-- Then we want to see the total global numbers without the date

SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS SIGNED INT)) AS total_deaths, SUM(cast(new_deaths AS SIGNED INT))/SUM(new_cases)*100 AS DeathPercentage 
FROM covid_vaccinations.coviddeaths
--  WHERE location like '%spain%'
WHERE continent is not NULL
-- group by date 
ORDER BY 1,2;

-- JOIN tables to gain insight

SELECT *
FROM covid_vaccinations.coviddeaths AS dea 
JOIN covid_vaccinations.covidvaccinations2 AS vac 
ON dea.location = vac.location
and dea.date = vac.date 

-- Looking at Total Population vs Vaccinations (to see the total amount of the people in the world that has been vaccinated)

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM covid_vaccinations.coviddeaths AS dea 
JOIN covid_vaccinations.covidvaccinations2 AS vac 
ON dea.location = vac.location
and dea.date = vac.date
Where dea.continent is not null 
order by 2,3;  

-- We'll include a partition clause and do it by location why? Because everytime we have a new location we want the count to start over we don't wan't the aggregate function (we'll also include) running over and over, just to run a country and then the next one and so on. 

-- USE CTE 

With PopvsVac(Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(cast(vac.new_vaccinations AS SIGNED INT)) OVER (Partition by dea.location order by dea.location, dea.date)AS RollingPeopleVaccinated
FROM covid_vaccinations.coviddeaths AS dea 
JOIN covid_vaccinations.covidvaccinations2 AS vac 
ON dea.location = vac.location
and dea.date = vac.date
Where dea.continent is not null 
-- order by 2,3;  
)
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PopvsVac

-- TEMP TABLE

DROP TABLE IF EXISTS PercentPopulationVaccinated;
CREATE TEMPORARY TABLE PercentPopulationVaccinated (
continent varchar(255), location varchar(255), date datetime , population double , 
new_vaccinations double , RollingVaccinationCount double
);
INSERT INTO PercentPopulationVaccinated 
SELECT dea.continent,dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS SIGNED INT)) 
OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM covid_vaccinations.coviddeaths AS dea
JOIN covid_vaccinations.covidvaccinations2 AS vac 
ON dea.location = vac.location 
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL; 

SELECT *, (RollingPeopleVaccinated/population)*100 FROM PercentPopulationVaccinated;

-- Create view to store data for data visualization later 

CREATE VIEW PercentPopulationVaccinated AS 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS SIGNED INT)) 
OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM covid_vaccinations.coviddeaths AS dea
JOIN covid_vaccinations.covidvaccinations2 AS vac 
WHERE dea.continent IS NOT NULL;

SELECT * FROM PercentPopulationVaccinated;











