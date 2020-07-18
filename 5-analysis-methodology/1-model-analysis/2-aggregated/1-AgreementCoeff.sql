CREATE VIEW csi_bakk.analysis_individualjudgements_s17_agree_coeff_max_decideable AS 
SELECT
	MA_AC.FocusEme, countJudgmenetChoosen, totalShown, AggreementCoef
FROM
	analysis_individualjudgements_s17_agreement_coeff MA_AC
    JOIN 
	(SELECT 
		FocusEme, max(AggreementCoef) as agreeCoeff
	FROM 
		csi_bakk.analysis_individualjudgements_s17_agreement_coeff
	GROUP BY 
		FocusEme) as MaxTable
	ON (MA_AC.FocusEme = MaxTable.FocusEme AND MA_AC.AggreementCoef = MaxTable.agreeCoeff)
    GROUP BY MA_AC.FocusEme, countJudgmenetChoosen, totalShown, AggreementCoef
HAVING COUNT(*) = 1;

CREATE VIEW csi_bakk.analysis_individualjudgements_s17_agree_coeff_max_undecideable AS     
SELECT
	MA_AC.FocusEme, countJudgmenetChoosen, totalShown, AggreementCoef
FROM
	analysis_individualjudgements_s17_agreement_coeff MA_AC
    JOIN 
	(SELECT 
		FocusEme, max(AggreementCoef) as agreeCoeff
	FROM 
		csi_bakk.analysis_individualjudgements_s17_agreement_coeff
	GROUP BY 
		FocusEme) as MaxTable
	ON (MA_AC.FocusEme = MaxTable.FocusEme AND MA_AC.AggreementCoef = MaxTable.agreeCoeff)
    GROUP BY MA_AC.FocusEme, countJudgmenetChoosen, totalShown, AggreementCoef
HAVING COUNT(*) >= 2;

CREATE VIEW csi_bakk.analysis_individualjudgements_s17_max_voting AS     
SELECT 
	*
FROM
	analysis_individualjudgements_s17_agree_coeff_max_decideable IDR_MAX NATURAL JOIN analysis_individualjudgements_s17_agreement_coeff
UNION
SELECT
	analysis_individualjudgements_s17_agree_coeff_max_undecideable.*,  
    'UNDECIDEABLE' AS Judgement
FROM 
	analysis_individualjudgements_s17_agree_coeff_max_undecideable;

CREATE VIEW csi_bakk.analysis_individualjudgements_s17_max_voting_notdids AS
    SELECT 
        FocusEme,
        'TP' AS `Judgement`
    FROM
        analysis_individualjudgements_s17_max_voting
    WHERE
        (`Judgement` LIKE 'D%') 
    UNION SELECT 
        FocusEME,
        Judgement
    FROM
        analysis_individualjudgements_s17_max_voting
    WHERE
        (NOT ((Judgement LIKE 'D%')));