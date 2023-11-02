

select *
From [Iyanu's project]..['covid deaths']
order by 3,4


--select *
--From [Iyanu's project]..['covid vaccinations']
--order by 3,4

select location, date, total_cases, new_cases, total_deaths, population
From [Iyanu's project]..['covid deaths']
order by 1,2


--TOtal cases vs total deaths
-- The incorrect format
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From [Iyanu's project]..['covid deaths']
order by 1,2
--The correct format: likelihood of dying if contatcting covid in Nigeria.
Select location, date, total_cases,total_deaths, (CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0)) * 100 AS Deathpercentage
from [Iyanu's project]..['covid deaths']
where location like '%NIgeria%'
order by 1,2


--Total cases vs population
Select location, date,population, total_cases, (CONVERT(float, total_cases) / NULLIF(CONVERT(float, population), 0)) * 100 AS Casepercentage
from [Iyanu's project]..['covid deaths']
where location like '%NIgeria%'
order by 1,2


--Countries with highest infecfted rate in compared to population
Select location, population, Max(total_cases) as HighestPopulacePerLocation, Max((CONVERT(float, total_cases)) / NULLIF(CONVERT(float, population), 0)) * 100 AS Casepercentage
from [Iyanu's project]..['covid deaths']
--where location like '%NIgeria%'
group by location, population
order by Casepercentage desc


--HIghest death count per population in each location
Select location, Max(cast(total_deaths as int)) as TotalDeathCount
from [Iyanu's project]..['covid deaths']
--where location like '%NIgeria%'
where continent is not null
group by location
order by TotalDeathCount desc


--Breaking the above out by continent
Select continent, Max(cast(total_deaths as int)) as TotalDeathCount
from [Iyanu's project]..['covid deaths']
--where location like '%NIgeria%'
where continent is not null
group by continent
order by TotalDeathCount desc

--the correct figure by location
Select location, Max(cast(total_deaths as int)) as TotalDeathCount
from [Iyanu's project]..['covid deaths']
--where location like '%NIgeria%'
where continent is null
group by location
order by TotalDeathCount desc


--Breaking it down via global numbers
Select date, sum(cast(total_cases as int)) as TotalCases, sum(cast(total_deaths as int)) as TotalDeaths, 
(sum(cast(total_deaths as int))/sum(cast(total_cases as int)))*100 as DeathPercentage
from [Iyanu's project]..['covid deaths']
--where location like '%NIgeria%'
WHere continent is not null
group by date
order by 1,2



--A total numbers of cases
--Breaking it down via global numbers
--For total global percentage on death
 Select SUM(CONVERT(float, total_cases)) AS TotalCases, 
    SUM(CONVERT(float, total_deaths)) AS TotalDeaths, 
    (SUM(CONVERT(float, total_deaths)) / NULLIF(SUM(CONVERT(float, total_cases)), 0)) * 100 AS DeathPercentage
	from [Iyanu's project]..['covid deaths']
--where location like '%NIgeria%'
WHere continent is not null
--group by date
order by 1,2


select *
From [Iyanu's project]..['covid deaths'] dea
Join [Iyanu's project]..['covid vaccinations'] vac
	On dea.location = vac.location
	and dea.date = dea.date



--Total population vs vaccination
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
From [Iyanu's project]..['covid deaths'] dea
Join [Iyanu's project]..['covid vaccinations'] vac
	On dea.location = vac.location
	and dea.date = dea.date
where dea.continent is null
group by 1,2,3,4


SELECT dea.continent, dea.location, dea.date, dea.population, SUM(vac.new_vaccinations) AS TotalNewVaccinations,
sum(convert(float, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
FROM [Iyanu's project]..['covid deaths'] dea
JOIN [Iyanu's project]..['covid vaccinations'] vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
GROUP BY dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations;

--In order to use a newly created column agaisnt another or an existing table then you need to create  temp or CTE table
-- Let's start with CTE



with PopVsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, SUM(vac.new_vaccinations) AS TotalNewVaccinations,
sum(convert(float, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
FROM [Iyanu's project]..['covid deaths'] dea
JOIN [Iyanu's project]..['covid vaccinations'] vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
GROUP BY dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
)

select *, (RollingPeopleVaccinated/population)*100 as RollingNumberDividesPopulation
From PopVsVac



--Temmp table

Drop table if exists #PercentPopulationVaccinated
Create table #PercentPopulationVaccinated
(
Continent nvarchar(255),
location nvarchar(255),
Date datetime,
Population numeric,
new_vaccinations numeric,
TotalNewVaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, SUM(vac.new_vaccinations) AS TotalNewVaccinations,
sum(convert(float, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
FROM [Iyanu's project]..['covid deaths'] dea
JOIN [Iyanu's project]..['covid vaccinations'] vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
GROUP BY dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations

select *, (RollingPeopleVaccinated/population)*100 as RollingNumberDividesPopulation
From #PercentPopulationVaccinated



--View to store a data for later visuals

Drop table if exists TotalDeathCount
Create view TotalDeathCounts as
Select location, Max(cast(total_deaths as int)) as TotalDeathCount
from [Iyanu's project]..['covid deaths']
--where location like '%NIgeria%'
where continent is null
group by location
--order by TotalDeathCount desc

Select *
from TotalDeathCounts