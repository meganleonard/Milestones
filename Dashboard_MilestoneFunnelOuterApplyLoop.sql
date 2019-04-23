/*************************************************************************************************

Updates the Dashboard_Funnel_Milestones table in pro for the Funnel Dashboard

**** This query runs for 15 minutes due to how much data it is pulling ****


ATTEMPTING OUTER APPLY

*************************************************************************************************/

CREATE TABLE #Final 
(
Cohort VARCHAR(20),
STC_PERSON_ID INT,
TermID_MIS4 INT,
Academic_Year VARCHAR(20),
STC_TERM VARCHAR(20),
TermIDCohort VARCHAR(20),
TEnglSuccess VARCHAR(20),
TEnglSuccessn INT,
TMathSuccess VARCHAR(20),
TMathSuccessn INT,
TMathEnglSuccess VARCHAR(20),
TMathEnglSuccessn INT,
FifteenUnitsEarned VARCHAR(20),
FifteenUnitsEarnedn INT,
ThirtyUnitsEarned VARCHAR(20),
ThirtyUnitsEarnedn INT,
SixtyUnitsEarned VARCHAR(20),
SixtyUnitsEarnedn INT,
FifteenUnitsAttempted VARCHAR(20),
FifteenUnitsAttemptedn INT,
ThirtyUnitsAttempted VARCHAR(20),
ThirtyUnitsAttemptedn INT,
SixtyUnitsAttempted VARCHAR(20),
SixtyUnitsAttemptedn INT,
FifteenTrUnitsEarned VARCHAR(20),
FifteenTrUnitsEarnedn INT,
ThirtyTrUnitsEarned VARCHAR(20),
ThirtyTrUnitsEarnedn INT,
SixtyTrUnitsEarned VARCHAR(20),
SixtyTrUnitsEarnedn INT,
FifteenTrUnitsAttempted VARCHAR(20),
FifteenTrUnitsAttemptedn INT,
ThirtyTrUnitsAttempted VARCHAR(20),
ThirtyTrUnitsAttemptedn INT,
SixtyTrUnitsAttempted VARCHAR(20),
SixtyTrUnitsAttemptedn INT,
Degree VARCHAR(20),
Degreen INT,
[Transfer] VARCHAR(20),
[Transfern] INT
)

----------------------------------------------------------------------------------------------------------------------
-- Declaring variables
-- @counter counts up for cohorts
-- @termid counts up for 

DECLARE @counter INT
SET @counter = 12 ---------------------------> Set for earliest year to pull 

DECLARE @termid INT
SET @termid = CONCAT(2,@counter,6)  ------> MIS4 Term ID 


-- While loop will go until counter reaches 19 

WHILE @counter < 19 BEGIN

----------------------------------------------------------------------------------------------------------------------
-- Create #cohort table, pulls first time students

SELECT 
	a.STC_PERSON_ID,
	a.MntrmMIS4, 
	t.SEMESTER,
	t.TERMS_ID as FirstTerm
	INTO -- drop table
	 #cohort
	FROM 
		(SELECT 
			ce.[STC_PERSON_ID],
			MIN(ce.TermID_MIS4) MntrmMIS4
			FROM 
				[datatel].[dbo].[FACTBOOK_CoreEnrollment_View] ce
				INNER JOIN 
				[datatel].[dbo].[Concurrent_HighSchool_Students_View] ch ON ce.STUDENT_ACAD_CRED_ID = ch.STUDENT_ACAD_CRED_ID -- should it just be STUDENT_ACAD_CRED_ID?
				LEFT JOIN 
				pro.dbo.PublicSafetyCourses ps on ce.STC_COURSE_NAME = ps.CourseName
				WHERE 
					ch.Concurrent_HS = 'Not' AND ps.CourseName IS NULL
					GROUP BY ce.[STC_PERSON_ID]
		) a
		LEFT JOIN 
		datatel.dbo.Terms_View t on t.TermID_MIS4 = a.MntrmMIS4
		WHERE 
		RIGHT(t.TERMS_ID, 2) NOT IN ('S1','S2','S3')
		AND
		MntrmMIS4 = CONCAT(2, @counter, 7)



----------------------------------------------------------------------------------------------------------------------
-- Create #baseline table, pulls all terms after student's first term using a cross join

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SELECT DISTINCT
ft.FirstTerm AS Cohort,
ft.STC_PERSON_ID,
ce.TermID_MIS4
INTO #baseline
FROM 
#cohort ft 
CROSS JOIN 
(SELECT DISTINCT TermID_MIS4 FROM 
datatel.dbo.FACTBOOK_CoreEnrollment_View 
WHERE TermID_MIS4 > @termid) ce 



----------------------------------------------------------------------------------------------------------------------
-- Create #aagain table, pulls academic year 

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SELECT DISTINCT
Academic_Year,
TermID_MIS4,
stc_term
INTO -- drop table
#ay
FROM
datatel.dbo.FACTBOOK_CoreEnrollment_View
WHERE 
TermID_MIS4 > @termid



----------------------------------------------------------------------------------------------------------------------
-- Create #upd table, combines the two above tables

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SELECT 
b.Cohort,
b.STC_PERSON_ID,
b.TermID_MIS4,
ct.Academic_Year,
ct.STC_TERM,
CONCAT(ct.stc_term,b.STC_PERSON_ID,b.Cohort) AS TermIDCohort
INTO -- drop table
#upd
FROM #baseline b
LEFT JOIN 
#ay ct ON  ct.TermID_MIS4 = b.TermID_MIS4
WHERE Academic_Year IS NOT NULL



----------------------------------------------------------------------------------------------------------------------
-- Create #tmte table, pulls transfer english and transfer math success

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SELECT 
b.* ,
CASE WHEN te.STC_PERSON_ID IS NOT NULL THEN 'Success' ELSE 'Not' END AS TEnglSuccess,
CASE WHEN te.STC_PERSON_ID IS NOT NULL THEN 1 ELSE 0 END AS TEnglSuccessn,
CASE WHEN tm.STC_PERSON_ID IS NOT NULL THEN 'Success' ELSE 'Not' END AS TMathSuccess,
CASE WHEN tm.STC_PERSON_ID IS NOT NULL THEN 1 ELSE 0 END AS TMathSuccessn
INTO #tmte
FROM #upd b
LEFT JOIN 
datatel.dbo.factbook_coreenrollment_view ce on b.STC_PERSON_ID = ce.STC_PERSON_ID and b.TermID_MIS4 = ce.TermID_MIS4
OUTER APPLY
(SELECT
	ce.stc_person_id
	FROM 
	datatel.dbo.FACTBOOK_CoreEnrollment_View ce
	WHERE
	ce.STC_COURSE_NAME IN ('ENGL-1A','ENGL-1B','ENGL-1BH','ENGL-1BMC','Engl-2','ENGL-2H','ENGL-2MC','ENGL-2MCH') 
	AND
	ce.SUCCESS = 1
	AND 
	TermID_MIS4 > @termid
	AND
	stc_person_id = b.STC_PERSON_ID
	AND 
	TermID_MIS4 <= b.TermID_MIS4 
) te --ON te.stc_person_id = b.STC_PERSON_ID AND te.TermID_MIS4 <= b.TermID_MIS4 
OUTER APPLY
(SELECT
ce.stc_person_id,
ce.TermID_MIS4
FROM 
datatel.dbo.FACTBOOK_CoreEnrollment_View ce
WHERE
ce.STC_COURSE_NAME IN ('Math-4','Math-5A','Math-5B','Math-5C','Math-6','Math-7','Math-12','Math-12H','Math-23') 
AND
ce.SUCCESS = 1
AND 
stc_person_id = b.STC_PERSON_ID
AND
TermID_MIS4 <= b.TermID_MIS4 
AND
TermID_MIS4 > @termid
) tm --ON tm.stc_person_id = b.STC_PERSON_ID AND tm.TermID_MIS4 <= b.TermID_MIS4 






----------------------------------------------------------------------------------------------------------------------
-- Create #cratt table, pulls credits attempted

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SELECT
t.*,
CASE WHEN t.TEnglSuccess = 'Success' AND t.TMathSuccess = 'Success' THEN 'Success' ELSE 'Not' END AS TMathEnglSuccess,
CASE WHEN t.TEnglSuccess = 'Success' AND t.TMathSuccess = 'Success' THEN 1 ELSE 0 END AS TMathEnglSuccessn,
CASE WHEN SUM(cr.CreditsEarned) >= 15 THEN 'Success' ELSE 'Not' END AS FifteenUnitsEarned,
CASE WHEN SUM(cr.CreditsEarned) >= 15 THEN 1 ELSE 0 END AS FifteenUnitsEarnedn,
CASE WHEN SUM(cr.CreditsEarned) >= 30 THEN 'Success' ELSE 'Not' END AS ThirtyUnitsEarned,
CASE WHEN SUM(cr.CreditsEarned) >= 30 THEN 1 ELSE 0 END AS ThirtyUnitsEarnedn,
CASE WHEN SUM(cr.CreditsEarned) >= 60 THEN 'Success' ELSE 'Not' END AS SixtyUnitsEarned,
CASE WHEN SUM(cr.CreditsEarned) >= 60 THEN 1 ELSE 0 END AS SixtyUnitsEarnedn,
CASE WHEN SUM(cr.CreditsAttempted) >= 15 THEN 'Success' ELSE 'Not' END AS FifteenUnitsAttempted,
CASE WHEN SUM(cr.CreditsAttempted) >= 15 THEN 1 ELSE 0 END AS FifteenUnitsAttemptedn,
CASE WHEN SUM(cr.CreditsAttempted) >= 30 THEN 'Success' ELSE 'Not' END AS ThirtyUnitsAttempted,
CASE WHEN SUM(cr.CreditsAttempted) >= 30 THEN 1 ELSE 0 END AS ThirtyUnitsAttemptedn,
CASE WHEN SUM(cr.CreditsAttempted) >= 60 THEN 'Success' ELSE 'Not' END AS SixtyUnitsAttempted,
CASE WHEN SUM(cr.CreditsAttempted) >= 60 THEN 1 ELSE 0 END AS SixtyUnitsAttemptedn
INTO -- drop table
#cratt
FROM
#tmte t
OUTER APPLY
(SELECT
	ce.STC_PERSON_ID,
	ce.termid_mis4,
	SUM(ce.STC_CMPL_CRED) AS CreditsEarned,
	SUM(ce.stc_cred) AS CreditsAttempted
	FROM 
		datatel.dbo.FACTBOOK_CoreEnrollment_View ce
		WHERE
		ce.TermID_MIS4 > @termid
		AND 
		STC_PERSON_ID = t.STC_PERSON_ID
		AND 
		TermID_MIS4 <=t.TermID_MIS4
		--and 
		--ce.STC_PERSON_ID = '0366761'
		GROUP BY ce.STC_PERSON_ID, ce.TermID_MIS4  --order by 1,2
) cr --ON cr.STC_PERSON_ID = t.STC_PERSON_ID AND cr.TermID_MIS4 <=t.TermID_MIS4
GROUP BY 
t.Academic_Year, t.Cohort, t.STC_PERSON_ID, t.STC_TERM, t.TEnglSuccess, T.TEnglSuccessn, t.TermID_MIS4, t.TermIDCohort, t.TMathSuccess, t.TMathSuccessn






----------------------------------------------------------------------------------------------------------------------
-- Create #trcratt table, pulls transfer credits attempted 


SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT 
t.* ,
CASE WHEN SUM(tcr.CreditsEarned) >= 15 THEN 'Success' ELSE 'Not' END AS FifteenTrUnitsEarned,
CASE WHEN SUM(tcr.CreditsEarned) >= 15 THEN 1 ELSE 0 END AS FifteenTrUnitsEarnedn,
CASE WHEN SUM(tcr.CreditsEarned) >= 30 THEN 'Success' ELSE 'Not' END AS ThirtyTrUnitsEarned,
CASE WHEN SUM(tcr.CreditsEarned) >= 30 THEN 1 ELSE 0 END AS ThirtyTrUnitsEarnedn,
CASE WHEN SUM(tcr.CreditsEarned) >= 60 THEN 'Success' ELSE 'Not' END AS SixtyTrUnitsEarned,
CASE WHEN SUM(tcr.CreditsEarned) >= 60 THEN 1 ELSE 0 END AS SixtyTrUnitsEarnedn,
CASE WHEN SUM(tcr.CreditsAttempted) >= 15 THEN 'Success' ELSE 'Not' END AS FifteenTrUnitsAttempted,
CASE WHEN SUM(tcr.CreditsAttempted) >= 15 THEN 1 ELSE 0 END AS FifteenTrUnitsAttemptedn,
CASE WHEN SUM(tcr.CreditsAttempted) >= 30 THEN 'Success' ELSE 'Not' END AS ThirtyTrUnitsAttempted,
CASE WHEN SUM(tcr.CreditsAttempted) >= 30 THEN 1 ELSE 0 END AS ThirtyTrUnitsAttemptedn,
CASE WHEN SUM(tcr.CreditsAttempted) >= 60 THEN 'Success' ELSE 'Not' END AS SixtyTrUnitsAttempted,
CASE WHEN SUM(tcr.CreditsAttempted) >= 60 THEN 1 ELSE 0 END AS SixtyTrUnitsAttemptedn
INTO  -- drop table
#trcratt
FROM
#cratt t
OUTER APPLY 
(SELECT
	ce.STC_PERSON_ID,
	ce.termid_mis4,
	SUM(ce.STC_CMPL_CRED) AS CreditsEarned, 
	SUM(ce.stc_cred) AS CreditsAttempted
	FROM
		datatel.dbo.FACTBOOK_CoreEnrollment_View ce
		WHERE
		STC_CRED_TYPE IN ('IC', 'IU', 'TC', 'TD', 'TR', 'TU')
		AND 
		ce.TermID_MIS4 > @termid
		AND
		STC_PERSON_ID = t.STC_PERSON_ID
		AND
		TermID_MIS4 <=t.TermID_MIS4
		GROUP BY ce.STC_PERSON_ID, ce.TermID_MIS4
) tcr --ON tcr.STC_PERSON_ID = t.STC_PERSON_ID AND tcr.TermID_MIS4 <=t.TermID_MIS4
WHERE Academic_Year IS NOT NULL 
GROUP BY 
t.Academic_Year, t.Cohort, t.STC_PERSON_ID, t.STC_TERM, t.TEnglSuccess, t.TEnglSuccessn, t.TermID_MIS4, t.TermIDCohort, t.TMathSuccess, t.TMathSuccessn, t.TMathEnglSuccess, t.TMathEnglSuccessn,
t.fifteenunitsearned, t.thirtyunitsearned, t.sixtyunitsearned, t.fifteenunitsattempted, t.thirtyunitsattempted, t.sixtyunitsattempted, 
t.fifteenunitsearnedn, t.thirtyunitsearnedn, t.sixtyunitsearnedn, t.fifteenunitsattemptedn, t.thirtyunitsattemptedn, t.sixtyunitsattemptedn



----------------------------------------------------------------------------------------------------------------------
-- Create #transf table, pulls transfers from NSC tables 


SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT DISTINCT
StudentID,
TransferTerm,
TermID_MIS4 AS TransferTermID
INTO #transf
FROM 
(SELECT DISTINCT
	[Transfer AY],
	StudentID,
	CONCAT(LEFT([Transfer AY],4),'FA') AS TransferTerm
	FROM 
		pro.dbo.NSC_Fall2018_First4YrEnrollment nsc -------------------------------------------------------> needs to be updated whenever NSC is updated
		LEFT JOIN 
		datatel.dbo.FACTBOOK_CoreEnrollment_View ce ON ce.STC_PERSON_ID = nsc.StudentID 
		WHERE
		nsc.[Transfer AY] IN ('2012-13','2013-14','2014-15','2015-16','2016-17','2017-18','2018-19') ---------------> this too
		AND ce.TermID_MIS4 > @termid
) a
LEFT JOIN 
datatel.dbo.FACTBOOK_CoreEnrollment_View ce ON ce.STC_TERM = a.TransferTerm



----------------------------------------------------------------------------------------------------------------------
-- Create #end table, pulls everything all together

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT
t.* ,
CASE WHEN g.[Student ID] IS NOT NULL THEN 'Success' ELSE 'Not' END AS Degree,
CASE WHEN g.[Student ID] IS NOT NULL THEN 1 ELSE 0 END AS Degreen,
CASE WHEN tr.studentid IS NOT NULL THEN 'Success' ELSE 'Not' END AS [Transfer],
CASE WHEN tr.studentid IS NOT NULL THEN 1 ELSE 0 END AS [Transfern]
INTO #end
FROM -- select * from 
#trcratt t
LEFT JOIN 
(SELECT * 
FROM
	(SELECT
		g2.[Student ID],
		g2.TermID_MIS4,
		g2.Term,
		ROW_NUMBER() OVER(PARTITION BY [student id] ORDER BY termid_mis4 ASC) AS POS
		FROM
		(SELECT
			ce.TermID_MIS4,
			g.[Student ID],
			g.Term,
			g.DiplomaMajorType
			FROM
				datatel.dbo.GraduatesByTerm_View g
				LEFT JOIN 
				datatel.dbo.FACTBOOK_CoreEnrollment_View ce ON ce.STC_PERSON_ID = g.[Student ID] AND ce.STC_TERM = g.Term
				WHERE
				ce.TermID_MIS4 > @termid
		) g2
	) g3
	WHERE g3.POS = 1
) g ON g.[Student ID] = t.STC_PERSON_ID AND t.TermID_MIS4 >= g.TermID_MIS4
LEFT JOIN 
#transf tr ON tr.StudentID = t.STC_PERSON_ID AND t.TermID_MIS4 >= tr.TransferTermID
GROUP BY 
t.Academic_Year, t.Cohort, t.STC_PERSON_ID, t.STC_TERM, t.TEnglSuccess, t.TermID_MIS4, t.TermIDCohort, t.TMathSuccess, t.TEnglSuccessn, t.TMathSuccessn,
t.fifteenunitsearned, t.thirtyunitsearned, t.sixtyunitsearned, t.fifteenunitsattempted, t.thirtyunitsattempted, t.sixtyunitsattempted,
t.fifteentrunitsearned, t.thirtytrunitsearned, t.sixtytrunitsearned, t.fifteentrunitsattempted, t.thirtytrunitsattempted, t.sixtytrunitsattempted, 
t.fifteenunitsearnedn, t.thirtyunitsearnedn, t.sixtyunitsearnedn, t.fifteenunitsattemptedn, t.thirtyunitsattemptedn, t.sixtyunitsattemptedn,
t.fifteentrunitsearnedn, t.thirtytrunitsearnedn, t.sixtytrunitsearnedn, t.fifteentrunitsattemptedn, t.thirtytrunitsattemptedn, t.sixtytrunitsattemptedn, 
g.[Student ID], tr.StudentID, t.TMathEnglSuccess, t.TMathEnglSuccessn




----------------------------------------------------------------------------------------------------------------------

-- insert your temp table into your final table
INSERT INTO #Final
SELECT * FROM #end


----------------------------------------------------------------------------------------------------------------------

-- drop any temp tables you used (except your final table)
DROP TABLE #cohort
DROP TABLE #baseline
DROP TABLE #tmte
DROP TABLE #ay
DROP TABLE #upd
DROP TABLE #cratt
DROP TABLE #trcratt
DROP TABLE #transf
DROP TABLE #end

----------------------------------------------------------------------------------------------------------------------

-- reset counter to the following year
SET @counter = @counter + 1
END 
GO


----------------------------------------------------------------------------------------------------------------------

-- Loop is over, selecting all from the final temp table

SELECT * FROM #Final

-- DROP TABLE pro.dbo.Dashboard_Funnel_Milestones
-- SELECT * INTO pro.dbo.Dashboard_Funnel_Milestones FROM #Final

--DROP TABLE #Final

--select stc_term, STC_COURSE_NAME, stc_Cred, STC_CMPL_CRED 
--from datatel.dbo.FACTBOOK_CoreEnrollment_View where STC_PERSON_ID = '0000590' order by TermID_MIS4