#install the required database connection libraries
#install.packages("DBI");
#install.packages("odbc");
#install.packages("RMariaDB");
#install.packages("vcd");
#install.packages("rlist");


#load needed libraries to connect to db
library(DBI);
library(RMariaDB);
library(plyr);
library("vcd");
library(rlist);

source("basic-functions.R", echo=FALSE);

#connect to the db
con <- dbConnect(RMariaDB::MariaDB(), 
                 dbname="csi_bakk", 
                 username=rstudioapi::askForPassword("Username"), 
                 password=rstudioapi::askForPassword("Password"));

#read the data from the datbase to R datasframes

## CAUTION: THE SECOND QUERY TAKES IT TIME (!!!!) UP TO 2 MINUTES (!!!) WAIT FOR IT TO BE FINSHED

df_drj_kk_s17 <- dbReadTable(con, "DefectReportJudgements_KK_S17"); #contains information for TP_E, FP_E
df_drvr_aggregated_kk_s17 <- dbReadTable(con, "defectreportjudgements_kk_ma$s17_max_voting_lenient_mapping"); #contains information for TP_C, FP_C
dbDisconnect(con);

##data transformation 

#using the aggregated list to create a dataframe (id, Crowd_Majority_Judgement) for TP_C and FP_C
df_eval_c <- df_drvr_aggregated_kk_s17[,c("id", "Expert_Comparison")];
names(df_eval_c)[names(df_eval_c) == "defect_report_code"] <- "id"
names(df_eval_c)[names(df_eval_c) == "Expert_Comparison"] <- "Crowd_Judgement";
df_eval_c$Crowd_Judgement[df_eval_c$Crowd_Judgement == "TP"] <- "TPC"
df_eval_c$Crowd_Judgement[df_eval_c$Crowd_Judgement == "FP"] <- "FPC"

#create dataframe (id, Crowd_Majority_Judgement) for TP_C
df_eval_tp_c <- df_eval_c[df_eval_c$Crowd_Judgement=="TPC",]

#create dataframe (id, Crowd_Majority_Judgement) for FP_C
df_eval_fp_c <- df_eval_c[df_eval_c$Crowd_Judgement=="FPC",]

#create dataframe (id, Expert_Judgement) for TP_E
df_eval_tp_e <- df_drj_kk_s17[df_drj_kk_s17$TruePositive==1 & df_drj_kk_s17$Split_Nr=='_1',][, c("id","TruePositive")]
df_eval_tp_e$TruePositive<- "TPE" #map the TruePositive numeric value to TP
names(df_eval_tp_e)[names(df_eval_tp_e) == "TruePositive"] <- "Expert_Judgement";

#create dataframe (id, Expert_Judgement) for FP_E
df_eval_fp_e <- df_drj_kk_s17[(df_drj_kk_s17$FalsePositive==1 & df_drj_kk_s17$Split_Nr=='_1') | (df_drj_kk_s17$FalsePositive==0 & df_drj_kk_s17$TruePositive==0),][, c("id", "FalsePositive")]
df_eval_fp_e$FalsePositive<- "FPE" #map the FalsePositive numeric value to TP
names(df_eval_fp_e)[names(df_eval_fp_e) == "FalsePositive"] <- "Expert_Judgement";

#create dataframe (id, Expert:judgement) for TP_E and FP_E
df_eval_e <- rbind(df_eval_tp_e, df_eval_fp_e);


#creating dataframe which merges df_eval_e and df_eval_c based on the id
df_eval_c_e <- merge(x = df_eval_c, y = df_eval_e, by = "id");

#applying the evaluation table of task 3 in word
df_eval_tp <- data.frame(df_eval_c_e[df_eval_c_e$Crowd_Judgement=="TPC"&df_eval_c_e$Expert_Judgement=="TPE",][,c("id")]);
c_eval_tp <- rep(c("TP"), nrow(df_eval_tp));
df_eval_tp["judgement"] <- c_eval_tp;
names(df_eval_tp) <- c("id","judgement");

df_eval_fp <- data.frame(df_eval_c_e[df_eval_c_e$Crowd_Judgement=="TPC"&df_eval_c_e$Expert_Judgement=="FPE",][,c("id")]);
c_eval_fp <- rep(c("FP"), nrow(df_eval_fp));
df_eval_fp["judgement"] <- c_eval_fp;
names(df_eval_fp) <- c("id","judgement");

df_eval_fn <- data.frame(df_eval_c_e[df_eval_c_e$Crowd_Judgement=="FPC"&df_eval_c_e$Expert_Judgement=="TPE",][,c("id")]);
c_eval_fn <- rep(c("FN"), nrow(df_eval_fn));
df_eval_fn["judgement"] <- c_eval_fn;
names(df_eval_fn) <- c("id","judgement");

df_eval_tn <- data.frame(df_eval_c_e[df_eval_c_e$Crowd_Judgement=="FPC"&df_eval_c_e$Expert_Judgement=="FPE",][,c("id")]);
c_eval_tn <- rep(c("TN"), length(df_eval_tn));
df_eval_tn["judgement"] <- c_eval_tn;
names(df_eval_tn) <- c("id","judgement");

#create a data.frame which holds all the data evaluated in one frame 

df_eval_compelte <- rbind(df_eval_tp, df_eval_fp, df_eval_fn, df_eval_tn);

message("--- AGGREGATED LENIENT EVALUATION ---");
message("Using judgements infered by majority voting.\n")
cnt_tp <- nrow(df_eval_compelte[df_eval_compelte$judgement=="TP",]);
cnt_fp <- nrow(df_eval_compelte[df_eval_compelte$judgement=="FP",]);
cnt_fn <- nrow(df_eval_compelte[df_eval_compelte$judgement=="FN",]);
cnt_tn <- nrow(df_eval_compelte[df_eval_compelte$judgement=="TN",]);

precision <- fun_precison(tp=cnt_tp, fp=cnt_fp);
message("Precision for aggregated lenient evaluation: ", precision);

recall <- fun_recall(tp=cnt_tp, fn=cnt_fn);
message("Recall for aggregated lenient evaluation: ", recall);

accuracy <- fun_accuracy(tp=cnt_tp, tn=cnt_tn, fp=cnt_fp, fn=cnt_fn);
message("Accuracy for aggregated lenient evaluation: ", accuracy);

fmeasure <- fun_fmeasure(precision = precision, recall = recall);
message("F-Measure/F-Score for aggregated lenient evaluation: ", fmeasure);
message("-------------------------------------");
