use csi_bakk;

CREATE VIEW `csi_bakk`.`defectreportjudgements_kk_ma$s17_agreement_coeff_unfiltered` AS
SELECT 
	defectreportvalidationreports_kk_ma$s17.id AS id,
	defectreportvalidationreports_kk_ma$s17.codetd,
	defectreportvalidationreports_kk_ma$s17.Crowd_Judgement AS Crowd_Judgement,
	defectreportvalidationreports_kk_ma$s17.dr_text,
	COUNT(0) AS cntJudgementChoosen,
	(SELECT 
			COUNT(0)
		FROM
			defectreportvalidationreports_kk_ma$s17 T2
		WHERE
			(T2.id = defectreportvalidationreports_kk_ma$s17.id  and T2.codetd = defectreportvalidationreports_kk_ma$s17.codetd)) AS countIdrShownInTotal,
	(COUNT(0) / (SELECT 
			COUNT(0)
		FROM
			defectreportvalidationreports_kk_ma$s17 T2
		WHERE
			(T2.id = defectreportvalidationreports_kk_ma$s17.id and T2.codetd = defectreportvalidationreports_kk_ma$s17.codetd))) AS AGREE_COEFF
FROM
	defectreportvalidationreports_kk_ma$s17
GROUP BY defectreportvalidationreports_kk_ma$s17.id , 
	defectreportvalidationreports_kk_ma$s17.Crowd_Judgement,
    defectreportvalidationreports_kk_ma$s17.codetd,
    defectreportvalidationreports_kk_ma$s17.dr_text;    
    

CREATE VIEW defectreportjudgements_kk_ma$s17_agree_coeff_max_decideable AS
	SELECT  id, codetd, agree_coeff, dr_text, cntJudgementChoosen, countIdrShownInTotal
	FROM
		defectreportjudgements_kk_ma$s17_agreement_coeff_unfiltered AS DV_AC 
	NATURAL JOIN
		(SELECT DISTINCT 
			id, codetd, max(agree_coeff) as agree_coeff
		FROM 
			defectreportjudgements_kk_ma$s17_agreement_coeff_unfiltered
		GROUP BY 
			id, codetd) AS MAX_CNT
	GROUP BY id, codetd, agree_coeff, dr_text, cntJudgementChoosen, countIdrShownInTotal
	HAVING count(*) = 1;

CREATE VIEW defectreportjudgements_kk_ma$s17_agree_coeff_max_undecideable AS
	SELECT  id, codetd, agree_coeff, dr_text, cntJudgementChoosen, countIdrShownInTotal
	FROM
		defectreportjudgements_kk_ma$s17_agreement_coeff_unfiltered AS DV_AC 
	NATURAL JOIN
		(SELECT DISTINCT 
			id, codetd, max(agree_coeff) as agree_coeff
		FROM 
			defectreportjudgements_kk_ma$s17_agreement_coeff_unfiltered
		GROUP BY 
			id, codetd) AS MAX_CNT
		/* the Crowd_Judgement is excluded from the Crowd Judgement therefore duplicates are being "automatically" supressed */
	GROUP BY id, codetd, agree_coeff, dr_text, cntJudgementChoosen, countIdrShownInTotal
	HAVING count(*) >= 2; 
 
CREATE VIEW defectreportjudgements_kk_ma$s17_max_voting AS
SELECT 
	DVR_MAX.* , Crowd_Judgement
FROM
	defectreportjudgements_kk_ma$s17_agree_coeff_max_decideable DVR_MAX
    NATURAL JOIN
    defectreportjudgements_kk_ma$s17_agreement_coeff_unfiltered DVR_ALL    
UNION
SELECT 
	*, "UNDECIDEABLE" as Crowd_Judgement
FROM
	defectreportjudgements_kk_ma$s17_agree_coeff_max_undecideable;
    
CREATE VIEW defectreportjudgements_kk_ma$s17_max_voting_lenient_mapping AS
/* lenient mapping excludes the undcideable */
SELECT 
	*, "TP" as Expert_Comparison
FROM 
	defectreportjudgements_kk_ma$s17_max_voting 
WHERE 
	Crowd_Judgement <> 'UNDECIDEABLE' 
	AND Crowd_Judgement  IN ("TRUE_DEFECT_SAME", "TRUE_DEFECT_DIFFERENT","TRUE_DEFECT_UNCLEAR_IF_SAME")
UNION
SELECT 
	*, "FP" as Expert_Comparison
FROM 
	defectreportjudgements_kk_ma$s17_max_voting 
WHERE 
	Crowd_Judgement <> 'UNDECIDEABLE' 
	AND Crowd_Judgement NOT IN ("TRUE_DEFECT_SAME", "TRUE_DEFECT_DIFFERENT","TRUE_DEFECT_UNCLEAR_IF_SAME");
    
CREATE VIEW defectreportjudgements_kk_ma$s17_max_voting_strict_mapping AS
/* strict mapping excludes the undcideable */
SELECT 
	*, "TP" as Expert_Comparison
FROM 
	defectreportjudgements_kk_ma$s17_max_voting 
WHERE 
	Crowd_Judgement <> 'UNDECIDEABLE' 
	AND Crowd_Judgement  IN ("TRUE_DEFECT_SAME")
UNION
SELECT 
	*, "FP" as Expert_Comparison
FROM 
	defectreportjudgements_kk_ma$s17_max_voting 
WHERE 
	Crowd_Judgement <> 'UNDECIDEABLE' 
	AND Crowd_Judgement NOT IN ("TRUE_DEFECT_SAME");
    