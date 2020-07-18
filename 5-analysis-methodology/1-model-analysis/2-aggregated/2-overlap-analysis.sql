SELECT Judgement, count(*)
FROM csi_bakk.analysis_individualjudgements_s17_max_voting
WHERE Judgement LIKE "D%"
GROUP BY Judgement
ORDER BY Judgement;