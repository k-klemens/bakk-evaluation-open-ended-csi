USE csi_bakk;

DROP TABLE IF EXISTS DefectReportJudgements_KK_S17;

/** SCHEMA DESCRIPTION 
		This schmea is used to import data from  manually judged IDRs in excel for the experiment of Spring2017.
        
	FIELD DESCRIPTION
		id: id to identify the DefectReport after data transformation. The id is in the format U<CFTask.CFTask_ID>W<CFTaskInstanceWorker_ID>. Traceability to all other tables is given by splitting this id.
        CFTask_ID: field is part of the schema for convenience, so that joining CFTask and further tables does not need to be done by splitting the id column.
        Worker: field is part of the schema for convenience, so that joining CFTaskInstance and further tables does not need to be done by splitting the id column.
        Split_Nr: some IDR have been duplicated while manual judgement because several TD's were assigned. To preserve traceability to crowdsourcing judgements and exsisting table, the id has not been change. Further this field has been introduced and if a IDR has been splitted, this is indicated by setting this column to _2, _3 and so forth.
        Automatic_Processing: boolean value to indicate whether automatic processing for analysis is possible or not. For example if a IDR has been split and assigned to more than one TD while manual judgement, automatic processing cannot be performed.
        TruePositive: boolean value to indicate whether the given defect report correlates to a TD in the TrueDefectCatalog.
        FaluePositive: boolean value to indicate whether the given defect report does not correclate to a TD in the TrueDefectCatalog and is not a potential defect which might have been forgotten in the TrueDefectCatalog.
        TrueDefectCode: if the IDR is a TD the TrueDefectCode is given.
        Same_Eme: booelan to indicate if the IDR's eme_id was reported on the EME_ID of the assigned TD. 
        In_Neighbours: boolean to indicate if the IDR' eme_id was reported on one of the EME_IDs in the Neighborhood of the assigned TD.
        Notes: field to contain notes which were taken while manual judgement. 
**/

/*Creating the table for the manually transformed data which has been exported from excel to csv */
/*NOTE: the Foreign Keys are not implemented for now since this would cause changes in the original DB schema. */
CREATE TABLE DefectReportJudgements_KK_S17(
	id varchar(256),
  /*  CONSTRAINT FK_DefectReportJudmgents_KK_S17_DefectReport FOREIGN KEY (id) REFERENCES DefectReport(id), */
    
    CFTask_ID VARCHAR(256),
    /*CONSTRAINT FK_DefectReportJudmgents_KK_S17_CFTask FOREIGN KEY (CFTask_ID) REFERENCES CFTask(CFTask_id), */
    
    Worker VARCHAR(256) ,
   /* CONSTRAINT FK_DefectReportJudmgents_KK_S17_CFTaskInstance FOREIGN KEY (CFTask_ID, Worker) REFERENCES CFTaskInstance(CFTask_id, Worker), */
    
    Split_Nr VARCHAR(3),
    Automatic_Processing BOOLEAN,
    TruePositive BOOLEAN,
    FalsePositive BOOLEAN,
    
    TrueDefectCode VARCHAR(256),
    CONSTRAINT FK_DefectReportJudmgents_KK_S17_TrueDefectCatalog FOREIGN KEY (TrueDefectCode) REFERENCES TrueDefectCatalog(Defect_Id),
    
    Same_EME BOOLEAN,
    In_Neighbours BOOLEAN,
    
    Notes VARCHAR(2048),  
    
    CONSTRAINT PK_DefectReportJudmgents_KK_S17 PRIMARY KEY(ID, Split_NR)
);

/** Importing data from excel/cvs should be done by using the import-csv-to-sql.py script */

SELECT * FROM DefectReportJudgements_KK_S17;
