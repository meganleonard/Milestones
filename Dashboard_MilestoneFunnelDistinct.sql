/******************************************************




******************************************************/



-- drop table pro.dbo.Dashboard_Funnel_Distinct


-- Student Distinct
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT DISTINCT
	m.STC_PERSON_ID,
	CASE WHEN ce.gender = 'M' THEN 'Male'
		 WHEN ce.gender = 'F' THEN 'Female'
		 ELSE 'Other/Unknown' 
		 END AS Gender,
	pe.Ethnicity,
	pe.URM,
	cz.Zip,
	CASE WHEN cz.PO_NAME IS NULL THEN 'Outside SCC' ELSE cz.PO_NAME END AS City,
	CASE WHEN cz.CountyLoc IS NULL THEN 'Outside SCC' ELSE cz.CountyLoc END AS CountyLoc,
	CASE WHEN eg.StudentID IS NOT NULL THEN 'Yes' ELSE 'No' END AS HasEdGoal,
	eg.VAL_EXTERNAL_REPRESENTATION AS EducationGoal,
	CASE WHEN eg.VAL_EXTERNAL_REPRESENTATION IN ('BA/BS after AA/AS','BA/BS without AA/AS','Trans out-of-state/foreig','Trans to UCSC','Trans to other UC campus','Trans to San Jose State','Trans to CSU Monterey Bay','Trans to other CSU campus','Trans Cal private college') THEN 'Transfer'
		 WHEN eg.VAL_EXTERNAL_REPRESENTATION IN ('AA/AS without transfer') THEN 'Degree without Transfer'
		 WHEN eg.VAL_EXTERNAL_REPRESENTATION IN ('Voc Degree w/o transfer','Voc Cert w/o transfer') THEN 'Vocational Degree or Certificate'
		 WHEN eg.VAL_EXTERNAL_REPRESENTATION IN ('4-yr std meet 4-yr rqmt') THEN '4 Year Student'
		 WHEN eg.VAL_EXTERNAL_REPRESENTATION IN ('Acquire job skills','Update job skills') THEN 'Job Skills'
		 WHEN eg.VAL_EXTERNAL_REPRESENTATION IN ('Basic skills improvement') THEN 'Basic Skills'
		 WHEN eg.VAL_EXTERNAL_REPRESENTATION IN ('Formulate career plans') THEN 'Formulate Career Plans'
		 WHEN eg.VAL_EXTERNAL_REPRESENTATION IN ('Maintain cert or license') THEN 'Maintain Certificate or License'
		 WHEN eg.VAL_EXTERNAL_REPRESENTATION IN ('Intell/cultural developmt') THEN 'Intellectual or Cultural Development'
		 WHEN eg.VAL_EXTERNAL_REPRESENTATION IN ('Credit for HS diploma/GED') THEN 'Credit for GED'
		 WHEN eg.VAL_EXTERNAL_REPRESENTATION IN ('Non-credit to credit') THEN 'Non-Credit to Credit'
		 WHEN eg.VAL_EXTERNAL_REPRESENTATION IN ('Undecided') THEN 'Undecided'
		 ELSE 'Unknown'
		 END AS EducGoal,
	eg.TransferEdGoal AS TransferEdGoal,
	CASE WHEN eops.STUDENT_ID IS NOT NULL THEN 'EOPS' 
		 WHEN eops.STUDENT_ID IS NULL THEN 'Not EOPS' 
		 ELSE 'Unknown' 
		 END AS EOPSEver, 
	CASE WHEN vet.ID IS NOT NULL THEN 'Veteran' 
		 WHEN vet.ID IS NULL THEN 'Not Veteran' 
		 ELSE 'Unknown' 
		 END AS VeteranStatus,
	CASE WHEN dsps.DSPS_ID IS NOT NULL THEN 'ASC' 
		 ELSE 'Not ASC' 
		 END AS DisabilityEver,
	CASE WHEN fy.STUDENTS_ID IS NOT NULL THEN 'Foster Youth' 
		 WHEN fy.STUDENTS_ID IS NULL THEN 'Not Foster Youth' 
		 ELSE 'Unknown' 
		 END AS FosterYouthStatus,
	CASE WHEN fg.FirstGen = 1 THEN 'First Generation' 
		 WHEN fg.FirstGen = 0 THEN 'Not First Generation' 
		 ELSE 'Unknown' 
		 END AS FirstGenerationStatus,
	CASE WHEN pell.SA_STUDENT_ID IS NOT NULL THEN 'Eligible' 
		 WHEN pell.SA_STUDENT_ID IS NULL THEN 'Not-Eligible' 
		 ELSE NULL 
		 END AS PellGrantElg,
	CASE WHEN bog.SA_STUDENT_ID IS NOT NULL THEN 'Eligible' 
		 WHEN bog.SA_STUDENT_ID IS NULL THEN 'Not-Eligible' 
		 ELSE NULL 
		 END AS BOGGrantElg,
	CASE WHEN bog.SA_STUDENT_ID IS NOT NULL OR pell.SA_STUDENT_ID IS NOT NULL THEN 'Disadvantaged'
		 ELSE 'Advantaged'
		 END AS EconomicallyDisadvantaged
INTO 
pro.dbo.Dashboard_Funnel_Distinct 
FROM 
(SELECT DISTINCT stc_person_id FROM
pro.dbo.Dashboard_Funnel_milestones) m
LEFT JOIN 
datatel.dbo.FACTBOOK_CoreEnrollment_View ce ON m.stc_person_id = ce.stc_person_id 
LEFT JOIN 
datatel.dbo.Person_Ethnicities_View pe ON pe.id = ce.stc_person_id
LEFT JOIN 
datatel.dbo.PERSON_ADDRESSES_VIEW pa ON pa.id = ce.STC_PERSON_ID
LEFT JOIN 
pro.dbo.CabrilloZips cz ON LEFT(pa.zip, 5) = cz.ZIP
LEFT JOIN 
(SELECT DISTINCT 
	fy.STUDENTS_ID
	FROM 
		datatel.dbo.FosterYouthStatus AS fy
) fy ON fy.students_id = ce.stc_person_id
LEFT JOIN 
(SELECT DISTINCT 
	[SA_STUDENT_ID]
	FROM 
		[datatel].[dbo].[FinAidAwards_View]
		WHERE 
		[SA_AWARD] = 'PELL' AND [SA_ACTION] = 'A' OR [SA_XMIT_AMT] > 0
) pell ON pell.SA_STUDENT_ID = ce.STC_PERSON_ID
LEFT JOIN 
(SELECT DISTINCT 
	[SA_STUDENT_ID]
	FROM 
   		[datatel].[dbo].[FinAidAwards_View]
		WHERE 
		[SA_AWARD] LIKE ('BOG%') AND [SA_ACTION] = 'A' OR [SA_XMIT_AMT] > 0
) bog ON bog.sa_student_id = ce.stc_person_id
LEFT JOIN 
(SELECT DISTINCT 
	eops.STUDENT_ID
	FROM 
		[datatel].[dbo].C09_DW_STUDENT_EOPS AS eops
) eops ON eops.STUDENT_ID = ce.STC_PERSON_ID
LEFT JOIN 
(SELECT DISTINCT 
	v.ID
	FROM 
		datatel.dbo.VETERAN_ASSOC AS v
		WHERE 
			v.POS = 1 
			AND 
			v.VETERAN_TYPE NOT IN ('S', 'V35', 'VDEP') -- VRAP is iffy, but I left it in
) vet ON vet.ID = ce.STC_PERSON_ID
LEFT JOIN 
(SELECT DISTINCT 
	fg.ID AS StudentID, 
	fg.ParentEdLevel, 
	CASE WHEN fg.ParentEdLevel IN ('11','12','13','14','1X','1Y','21','22','23','24','2X','2Y','31','32','33','34','3X','3Y','41','42','43','44','4X','4Y','X1','X2','X3','X4','Y1','Y2','Y3','Y4') THEN 1 
		 WHEN fg.ParentEdLevel IS NULL OR fg.ParentEdLevel IN ('YY','XX') THEN NULL 
		 ELSE 0 
		 END AS FirstGen
	FROM 
		(SELECT 
			[APPLICANTS_ID] AS ID,
 			([APP_PARENT1_EDUC_LEVEL] + [APP_PARENT2_EDUC_LEVEL]) AS ParentEdLevel,
   			MAX([APPLICANTS_CHGDATE]) AS MaxAppChangeDate
	  		FROM
		 		[datatel].[dbo].[APPLICANTS]
				GROUP BY [APPLICANTS_ID], [APP_PARENT1_EDUC_LEVEL], [APP_PARENT2_EDUC_LEVEL]
		) AS fg
) fg ON fg.StudentID = ce.STC_PERSON_ID
LEFT JOIN 
(SELECT 
	DisPrim.*, 
	DisAll.AllDisabilities
	FROM
		(SELECT DISTINCT 
			d.[PERSON_HEALTH_ID] AS DSPS_ID,
			dd.HC_DESC AS PrimaryDisability
			FROM 
				[datatel].[dbo].[PHL_DISABILITIES] AS d
				INNER JOIN 
				[datatel].[dbo].[DISABILITY] AS dd 
				ON d.[PHL_DISABILITY] = dd.DISABILITY_ID
				WHERE 
					d.PHL_DIS_TYPE = 'PRI'
		) AS DisPrim
		INNER JOIN 
		(SELECT DISTINCT 
			d.[PERSON_HEALTH_ID] AS DSPS_ID,
			datatel.[dbo].[ConcatField](dd.HC_DESC, ', ') AS AllDisabilities
			FROM 
				[datatel].[dbo].[PHL_DISABILITIES] AS d
				INNER JOIN 
				[datatel].[dbo].[DISABILITY] AS dd 
				ON d.[PHL_DISABILITY] = dd.DISABILITY_ID
				GROUP BY [PERSON_HEALTH_ID]
		) AS DisAll
		ON DisPrim.DSPS_ID = DisAll.DSPS_ID
) dsps ON dsps.DSPS_ID = ce.STC_PERSON_ID
LEFT JOIN
		(SELECT DISTINCT 
			eg3.ID AS StudentID, 
			v1.VAL_EXTERNAL_REPRESENTATION, 
			eg3.[PST_EDUC_GOALS] AS EducationGoal,
			CASE WHEN eg3.[PST_EDUC_GOALS] IN ('1','2','1A','1B','1C','1D','1E','1F','1G','2A','2B','2C','2D','2E','2F','2G') THEN 'Transfer' 
				 WHEN eg3.[PST_EDUC_GOALS] = '14'THEN '4yrStudent' ELSE 'Not' END AS TransferEdGoal
			FROM 
				(SELECT 
					eg2.ID, 
					eg2.PST_EDUC_GOALS
					FROM 
						(SELECT
							eg1.ID, 
							eg1.MaxPOS, 
							eg.[PST_EDUC_GOALS]
							FROM 
								(SELECT DISTINCT 
									eg.[PERSON_ST_ID] AS ID, 
									MAX(eg.POS) AS MaxPOS
									FROM 
										[datatel].[dbo].[EDUC_GOALS] AS eg
										GROUP BY eg.[PERSON_ST_ID]
								) AS eg1
								INNER JOIN 
								[datatel].[dbo].[EDUC_GOALS] AS eg
								ON eg1.ID = eg.[PERSON_ST_ID] AND eg1.MaxPOS = eg.[POS]
						) AS eg2
				) AS eg3
				INNER JOIN 
				(SELECT DISTINCT 
					[VALCODE_ID],
					[POS],
					[VAL_MINIMUM_INPUT_STRING],
					[VAL_EXTERNAL_REPRESENTATION]
					FROM 
						[datatel].[dbo].[ST_VALS]
						WHERE 
						valcode_id = 'EDUCATION.GOALS'
				) AS v1
				ON eg3.PST_EDUC_GOALS = v1.[VAL_MINIMUM_INPUT_STRING]
		) eg
		ON eg.StudentID = ce.STC_PERSON_ID
