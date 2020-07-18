USE CSI_BAKK;

DROP TABLE IF EXISTS NoDefectReportJudgements_KK_S17;

/** SCHEMA DESCRIPTION 
		This schmea contains all IDR's which were assigned no_defect for the experiment of Spring2017.
        Furthermore this schema containts the result of automated judgements whether these IDRs are TrueNegaitves or FalseNegative.
        A IDR is considered a FalseNegative if the EME_ID of a IDR can be cound in the TrueDefectCatalog.
        
	FIELD DESCRIPTION
		id: id to identify the DefectReport after data transformation. The id is in the format U<CFTask.CFTask_ID>W<CFTaskInstanceWorker_ID>. Traceability to all other tables is given by splitting this id.
        CFTask_ID: field is part of the schema for convenience, so that joining CFTask and further tables does not need to be done by splitting the id column.
		Worker: field is part of the schema for convenience, so that joining CFTaskInstance and further tables does not need to be done by splitting the id column.
        TrueNegative: indicate if the judgement with no_defect was correct. True if the EME_ID of the IDR  is not contained in the TrueDefectCatalog.
        FalseNegative: indicate if the judgment with no_defect was wrong. True if the EME_ID of the IDR id containted in the TrueDefectCatalog.
		TrueDefectCode: if the IDR is a TD the TrueDefectCode is given.
        EME_id: the EME_id of the IDR. (not necessarily needed...)
**/
CREATE TABLE NoDefectReportJudgements_KK_S17(
	id VARCHAR(256) PRIMARY KEY, /*the id like in the defect report U<CFTaskID>W<Worker>*/
    CFTask_ID VARCHAR(2048),
    Worker VARCHAR(2048),
    TrueNegative BOOLEAN,
    FalseNegative BOOLEAN, 
	TrueDefectCode VARCHAR(256),
    EME_id VARCHAR(256)
);

TRUNCATE TABLE NoDefectReportJudgements_KK_S17;
   
/* Insert all the No_Defects of the CTIMA Table to the NoDefectReportJudgements_KK_S17 Report with the concatinated ID,
which have not been alreay added to the DefectReportJudgements_KK_S17*/
INSERT INTO NoDefectReportJudgements_KK_S17(id, CFTask_ID, Worker, TrueNegative, FalseNegative, TrueDefectCode, EME_id)
SELECT concat('U', CT.CFTask_ID, 'W', worker), CT.CFTask_ID, worker, 
	/* if statement which do the judgining by using set operations */
    /* this should work because the EME_ID can have at max 1 defect report */
	IF(CTIMA.EME_ID NOT IN (SELECT EME_ID FROM TrueDefectCatalog WHERE EME_ID <> 'NA' AND EME_ID IS NOT NULL), true, false),  /* if EME_ID not found in the true defect catalog (excluding NA and eme_id empty) then set TrueNegative=True */
    IF(CTIMA.EME_ID IN (SELECT EME_ID FROM TrueDefectCatalog WHERE EME_ID <> 'NA' AND EME_ID IS NOT NULL), true, false), /*if EME_ID is found in the true defect catalog then set FalseNegative=True */
    IF(CTIMA.EME_ID IN (SELECT EME_ID FROM TrueDefectCatalog), (SELECT Defect_ID FROM TrueDefectCatalog WHERE TrueDefectCatalog.EME_ID = CTIMA.EME_ID), NULL), /* add the TD if FP=true */
    CTIMA.eme_id /*also add the EME_id to allow refence */
FROM CFTaskInstanceMA CTIMA, CFTaskInstance CTI, CFTask CT, CFJob CJ
WHERE  CTIMA.id = CTI.id
AND CTI.CFTask_id = CT.CFTask_id
AND CT.CFjobId = CJ.CFjobId
AND Experiment = 'ViennaSpring2017'
AND ModelDefects = 'no_defect'
/* exclude all the concatinated IDs which are already in the DefectReportTable because there might be some ModelDefects='no_defect' which containt a defect report, hence they are already being analyzed */
/* also taking care of the splitting which has been done while transforming the data */
AND concat('U', CT.CFTask_ID, 'W', worker) NOT IN (SELECT DISTINCT substring_index(DR.id, '_', 1) 
FROM DefectReport DR , CFTaskInstance CTI, CFTask CT, CFJob CJ
WHERE DR.taskInstanceID = CTI.id AND CTI.CFTask_id = CT.CFTask_ID AND CT.CFJobID = CJ.CFJobID
AND CJ.Experiment = "ViennaSpring2017");

/*validate that there has been no misproessing */
/*expected count(*) to be 0 */
SELECT count(*) FROM NoDefectReportJudgements_KK_S17 
WHERE (TrueNegative=TRUE AND FalseNegative=TRUE) OR (TrueNegative=FALSE AND FalseNegative=FALSE);

/*validate that there has been no misproessing */
/*expected count(*) to be 0 */
SELECT count(*) FROM NoDefectReportJudgements_KK_S17 
WHERE FalseNegative = TRUE;


/* find the ones which are defects which have not been spotted with additional information from CTIMA and TrueDefectCatalog Table */
SELECT NDRJ.*, TDC.ME_Type, TDC.eme_text, TDC.Model_Location, TDC.Model_Element_Code, TDC.Defect_Type, TDC.Description, TDC.Neighborhood, CTIMA.ModelDefects, CTIMA.DefectReport, CTIMA.Feedback
FROM NoDefectReportJudgements_KK_S17 NDRJ, TrueDefectCatalog TDC, CFTaskInstance CTI, CFTaskInstanceMA CTIMA
WHERE FalseNegative=TRUE
AND TDC.Defect_ID = NDRJ.TrueDefectCode 
AND NDRJ.CFTask_ID = CTI.CFTask_id
AND NDRJ.worker = CTI.worker
AND CTI.id = CTIMA.id;

/*FURHTER INVESTIGATE HOW THE SUPERFLOUS DEFECT ARE AUTOMATICALLY EVALUATED BY THESE GIVEN INSERT INTO STATEMENTA
BECAUSE THESE DEFECTS HAVE EME_ID = NA !!! */
/* MIGHT SHOULD CHECK IF THE PROCESSING ENTITIY SHOULD BE THE MODEL ELEMENT CODE -> BUT THIS ONE NEEDS TO HAVE THE SAME UNIQUENESS AS THE EME_ID */
/* EME = EXPECTED MODEL ELEMENT SO THESE ARE ONLY THE EMEs WHICH SHOULD BE (!!!) IN THE MODEL */

SELECT * FROM NoDefectReportJudgements_KK_S17;

