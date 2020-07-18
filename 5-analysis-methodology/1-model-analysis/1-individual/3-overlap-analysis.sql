use csi_bakk;

SELECT TrueDefectCode, count(*) FROM
DefectReportJudgements_KK_S17
GROUP BY TrueDefectCode
ORDER BY TrueDefectCode;
