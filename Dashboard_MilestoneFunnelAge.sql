SELECT
m.Cohort,
m.STC_PERSON_ID,
m.TermIDCohort,
m.STC_TERM,
b.BirthYear,
CASE WHEN b.BirthYear IS NOT NULL THEN LEFT(m.Cohort,4) - b.BirthYear ELSE NULL END AS Ageyears,
CASE WHEN LEFT(m.Cohort,4) - b.BirthYear <18 THEN '17 and Under'
		 WHEN LEFT(m.Cohort,4) - b.BirthYear BETWEEN 18 AND 20 THEN '18-20'
		 WHEN LEFT(m.Cohort,4) - b.BirthYear BETWEEN 21 AND 25 THEN '21-25'
		 WHEN LEFT(m.Cohort,4) - b.BirthYear BETWEEN 26 AND 30 THEN '26-30'
		 WHEN LEFT(m.Cohort,4) - b.BirthYear BETWEEN 31 AND 40 THEN '31-40'
		 WHEN LEFT(m.Cohort,4) - b.BirthYear BETWEEN 41 AND 50 THEN '41-50'
		 WHEN LEFT(m.Cohort,4) - b.BirthYear BETWEEN 51 AND 60 THEN '51-60'
		 WHEN LEFT(m.Cohort,4) - b.BirthYear >60 THEN '61 and Over'
		 ELSE 'Unknown'
		 END AS AgeRange
INTO -- drop table 
pro.dbo.Dashboard_Funnel_Age
FROM
pro.dbo.Dashboard_Funnel_Milestones m
LEFT JOIN 
(SELECT DISTINCT
ID,
YEAR(Birth_date) AS BirthYear
FROM 
datatel.dbo.PERSON_ADDRESSES_VIEW
) b ON b.ID = m.STC_PERSON_ID


select * from pro.dbo.Dashboard_Funnel_Age where AgeRange = '18-20'