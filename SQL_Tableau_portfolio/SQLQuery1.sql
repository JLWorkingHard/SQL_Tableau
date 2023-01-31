--do some data cleaning
EXEC sp_help covid

--notice that date data type are varchar,should change to date
Update covid
SET date = CONVERT(Date,date)

--delete dumplicate
WITH cte AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (
            PARTITION BY 
                location,
				date
            ORDER BY 
                location,
				date
        ) row_num
     FROM 
        SQL_portfolio.dbo.covid
)
DELETE FROM cte
WHERE row_num > 1;

--seperate year from date
ALTER TABLE covid
Add year Nvarchar(255);

Update covid
SET year = YEAR(date)

--select some interesting features and create a view
create view c19 as
select location,total_cases,date,year,new_cases,total_deaths,new_deaths,reproduction_rate,total_vaccinations,people_vaccinated,
people_fully_vaccinated,population,median_age,aged_70_older,cardiovasc_death_rate,diabetes_prevalence
from SQL_portfolio..covid

select *
from c19
order by 1,3

--calculate out some usable data from original data and tranfer them into Visulation tool later
--calculate infacted rate
select location,Max(total_cases/population)*100 as infacted_rate
from c19 
where total_cases is not NULL and population is not NULL
group by location
order by 2

--calculate death rate
WITH cte as(
select location,Max(total_cases) as cas,Max(total_deaths) as dea
from c19
where total_cases is not NULL and total_deaths is not NULL
group by location
)
select location, dea/cas*100 as death_rate
from cte
where dea/cas < 1
order by 2

--summerize to global numbers
Select date,SUM(new_cases) as total_cases,SUM(cast(new_deaths as int)) as total_deaths,SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercent
From c19
group by date
Having SUM(new_cases) > 0
order by 1,4

