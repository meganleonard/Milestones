DROP TABLE #cohort
DROP TABLE #baseline
DROP TABLE #tmte
DROP TABLE #aagain
DROP TABLE #upd
DROP TABLE #cratt
DROP TABLE #trcratt
DROP TABLE #transf
--DROP TABLE pro.dbo.Dashboard_Funnel_Milestones


/***


Pull cohorts individually

Will eventually rewrite with a loop


***/


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

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
		STC_PERSON_ID = '0367778'
		--AND
		--MntrmMIS4 = 2127 -------------------------------------------------------------- hard coded for Fall 18 only to test query


SELECT * FROM #cohort order by 1

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


DECLARE @termid INT
SET @termid = 2176

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- drop table #baseline

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SELECT DISTINCT
ft.FirstTerm AS Cohort,
ft.STC_PERSON_ID,
--ct.Academic_Year,
--ct.STC_TERM,
ce.TermID_MIS4
--ce.STC_PERSON_ID,
INTO #baseline
FROM 
#cohort ft 
CROSS JOIN 
(select DISTINCT TermID_MIS4 FROM 
datatel.dbo.FACTBOOK_CoreEnrollment_View where TermID_MIS4 > @termid) ce --ON ce.STC_PERSON_ID = ft.STC_PERSON_ID AND ft.MntrmMIS4 <= ce.TermID_MIS4

select * from #baseline order by 2



DECLARE @termid INT
SET @termid = 2176

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SELECT DISTINCT
Academic_Year,
TermID_MIS4,
stc_term
INTO -- drop table
#aagain
FROM
datatel.dbo.FACTBOOK_CoreEnrollment_View
WHERE 
TermID_MIS4 > @termid

select * from #aagain




DECLARE @termid INT
SET @termid = 2176


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
#aagain ct ON  ct.TermID_MIS4 = b.TermID_MIS4
WHERE Academic_Year IS NOT NULL

select * from #upd
order by 2,3


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*

SELECT DISTINCT
b.Cohort,
b.STC_PERSON_ID,
ce.Academic_Year,
ce.STC_TERM,
ce.TermID_MIS4,
CONCAT(ce.stc_term,b.STC_PERSON_ID,b.Cohort) AS TermIDCohort
INTO #baseline
FROM
#terms b
LEFT JOIN 
datatel.dbo.FACTBOOK_CoreEnrollment_View ce ON b.STC_PERSON_ID = ce.STC_PERSON_ID AND b.TermID_MIS4 = ce.TermID_MIS4  



SELECT * FROM #baseline
*/

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @termid INT
SET @termid = 2176

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SELECT DISTINCT
b.* ,
CASE WHEN te.STC_PERSON_ID IS NOT NULL THEN 'Success' ELSE 'Not' END AS TEnglSuccess,
CASE WHEN te.STC_PERSON_ID IS NOT NULL THEN 1 ELSE 0 END AS TEnglSuccessn,
CASE WHEN tm.STC_PERSON_ID IS NOT NULL THEN 'Success' ELSE 'Not' END AS TMathSuccess,
CASE WHEN tm.STC_PERSON_ID IS NOT NULL THEN 1 ELSE 0 END AS TMathSuccessn
INTO -- DROP TABLE
 #tmte
FROM #upd b
LEFT JOIN 
datatel.dbo.factbook_coreenrollment_view ce on b.STC_PERSON_ID = ce.STC_PERSON_ID and b.TermID_MIS4 = ce.TermID_MIS4
LEFT JOIN 
(SELECT
ce.stc_person_id,
ce.TermID_MIS4
FROM 
datatel.dbo.FACTBOOK_CoreEnrollment_View ce
WHERE
ce.STC_COURSE_NAME IN ('ENGL-1A','ENGL-1B','ENGL-1BH','ENGL-1BMC','Engl-2','ENGL-2H','ENGL-2MC','ENGL-2MCH') 
AND
ce.SUCCESS = 1
AND 
TermID_MIS4 > @termid
) te ON te.stc_person_id = b.STC_PERSON_ID AND te.TermID_MIS4 <= b.TermID_MIS4 
LEFT JOIN 
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
TermID_MIS4 > @termid
) tm ON tm.stc_person_id = b.STC_PERSON_ID AND tm.TermID_MIS4 <= b.TermID_MIS4 


SELECT * FROM #tmte




------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @termid INT
SET @termid = 2126

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SELECT DISTINCT
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
LEFT JOIN 
(SELECT
ce.STC_PERSON_ID,
ce.termid_mis4,
SUM(ce.STC_CMPL_CRED) AS CreditsEarned,
SUM(ce.stc_cred) AS CreditsAttempted
FROM 
datatel.dbo.FACTBOOK_CoreEnrollment_View ce
WHERE
ce.TermID_MIS4 > @termid
GROUP BY ce.STC_PERSON_ID, ce.TermID_MIS4
) cr ON cr.STC_PERSON_ID = t.STC_PERSON_ID AND cr.TermID_MIS4 <=t.TermID_MIS4
GROUP BY 
t.Academic_Year, t.Cohort, t.STC_PERSON_ID, t.STC_TERM, t.TEnglSuccess, T.TEnglSuccessn, t.TermID_MIS4, t.TermIDCohort, t.TMathSuccess, t.TMathSuccessn





SELECT * FROM #cratt order by 5,4

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


DECLARE @termid INT
SET @termid = 2126


SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT DISTINCT
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
LEFT JOIN 
(SELECT
ce.STC_PERSON_ID,
ce.termid_mis4,
SUM(ce.STC_CMPL_CRED) AS CreditsEarned,  -------------------------------------------- Transferrable credits
SUM(ce.stc_cred) AS CreditsAttempted
FROM
datatel.dbo.FACTBOOK_CoreEnrollment_View ce
WHERE
STC_CRED_TYPE IN ('IC', 'IU', 'TC', 'TD', 'TR', 'TU')
AND 
ce.TermID_MIS4 > @termid
GROUP BY ce.STC_PERSON_ID, ce.TermID_MIS4
) tcr ON tcr.STC_PERSON_ID = t.STC_PERSON_ID AND tcr.TermID_MIS4 <=t.TermID_MIS4
WHERE Academic_Year IS NOT NULL 
GROUP BY 
t.Academic_Year, t.Cohort, t.STC_PERSON_ID, t.STC_TERM, t.TEnglSuccess, t.TEnglSuccessn, t.TermID_MIS4, t.TermIDCohort, t.TMathSuccess, t.TMathSuccessn, t.TMathEnglSuccess, t.TMathEnglSuccessn,
t.fifteenunitsearned, t.thirtyunitsearned, t.sixtyunitsearned, t.fifteenunitsattempted, t.thirtyunitsattempted, t.sixtyunitsattempted, 
t.fifteenunitsearnedn, t.thirtyunitsearnedn, t.sixtyunitsearnedn, t.fifteenunitsattemptedn, t.thirtyunitsattemptedn, t.sixtyunitsattemptedn



SELECT * FROM #trcratt order by 2,5

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

DECLARE @termid INT
SET @termid = 2126


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
		pro.dbo.NSC_Fall2018_First4YrEnrollment nsc
		LEFT JOIN 
		datatel.dbo.FACTBOOK_CoreEnrollment_View ce ON ce.STC_PERSON_ID = nsc.StudentID 
		WHERE
		nsc.[Transfer AY] IN ('2012-13','2013-14','2014-15','2015-16','2016-17','2017-18','2018-19')
		AND ce.TermID_MIS4 > @termid
) a
LEFT JOIN 
datatel.dbo.FACTBOOK_CoreEnrollment_View ce ON ce.STC_TERM = a.TransferTerm
order by 1


SELECT * FROM #transf 

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @termid INT
SET @termid = 2126

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT DISTINCT
t.* ,
CASE WHEN g.[Student ID] IS NOT NULL THEN 'Success' ELSE 'Not' END AS Degree,
CASE WHEN g.[Student ID] IS NOT NULL THEN 1 ELSE 0 END AS Degreen,
CASE WHEN tr.studentid IS NOT NULL THEN 'Success' ELSE 'Not' END AS [Transfer],
CASE WHEN tr.studentid IS NOT NULL THEN 1 ELSE 0 END AS [Transfern]
INTO #finalF12
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

select * from #finalF12



SELECT 
* 
INTO #final
FROM 
#finalF18 
UNION ALL 
SELECT 
* 
FROM 
#finalF17
UNION ALL
SELECT 
* 
FROM  
#finalF16
UNION ALL
SELECT 
* 
FROM  
#finalF15
UNION ALL 
SELECT 
* 
FROM  
#finalF14
UNION ALL 
SELECT 
* 
FROM  
#finalF13
UNION ALL
SELECT 
* 
FROM  
#finalF12


SELECT * FROM #final order by 2, 3 


SELECT 
* INTO pro.dbo.Dashboard_Funnel_Milestones FROM #final 



SELECT * from pro.dbo.Dashboard_Funnel_Milestones order by stc_term