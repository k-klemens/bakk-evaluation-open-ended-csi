#install the required database connection libraries
#install.packages("DBI");
#install.packages("odbc");
#install.packages("RMariaDB");
#install.packages("vcd");

#load needed libraries to connect to db
library(DBI);
library(RMariaDB);
library(plyr);
library("vcd");

#load needed functions
source("basic-functions.R");

#connect to the db
con <- dbConnect(RMariaDB::MariaDB(), 
                 dbname="csi_bakk", 
                 username=rstudioapi::askForPassword("Username"), 
                 password=rstudioapi::askForPassword("Password"));

#read the data from the datbase to R datasframes
df_drj_kk_s17 <- dbReadTable(con, "DefectReportJudgements_KK_S17"); #contains information for TP_E, FP_E -> established the frame of reference 
df_drvr_kk_s17 <- dbReadTable(con, "DefectReportValidationReport_KK_MA$S17_StrictMapping"); #contains information for TP_C, FP_C
dbDisconnect(con);

##data transformation 

#using the aggregated list to create a dataframe (id, Crowd_Judgement, TD_ID_C) for TP_C and FP_C
df_eval_c <- df_drvr_kk_s17[,c("id", "Expert_Comparison", "codetd")];
names(df_eval_c)[names(df_eval_c) == "Expert_Comparison"] <- "Crowd_Judgement"; # rename expert comparision to be the mapped result of the crowd 
names(df_eval_c)[names(df_eval_c) == "codetd"] <- "TD_ID_C"; # rename expert comparision to be the mapped result of the crowd 
df_eval_c$Crowd_Judgement[df_eval_c$Crowd_Judgement == "TP"] <- "TPC"
df_eval_c$Crowd_Judgement[df_eval_c$Crowd_Judgement == "FP"] <- "FPC"

#create dataframe (id, Crowd_Judgement) for TP_C
df_eval_tp_c <- df_eval_c[df_eval_c$Crowd_Judgement=="TPC",]

#create dataframe (id, Crowd_Judgement) for FP_C
df_eval_fp_c <- df_eval_c[df_eval_c$Crowd_Judgement=="FPC",]

#create dataframe (id, Expert_Judgement) for TP_E
df_eval_tp_e <- df_drj_kk_s17[df_drj_kk_s17$TruePositive==1 & df_drj_kk_s17$Split_Nr=='_1',][, c("id","TruePositive", "TrueDefectCode")]
df_eval_tp_e$TruePositive<- "TPE" #map the TruePositive numeric value to TPE
names(df_eval_tp_e)[names(df_eval_tp_e) == "TruePositive"] <- "Expert_Judgement";

#create dataframe (id, Expert_Judgement) for FP_E
df_eval_fp_e <- df_drj_kk_s17[(df_drj_kk_s17$FalsePositive==1 & df_drj_kk_s17$Split_Nr=='_1') | (df_drj_kk_s17$FalsePositive==0 & df_drj_kk_s17$TruePositive==0),][, c("id", "FalsePositive", "TrueDefectCode")]
df_eval_fp_e$FalsePositive<- "FPE" #map the FalsePositive numeric value to FPE
names(df_eval_fp_e)[names(df_eval_fp_e) == "FalsePositive"] <- "Expert_Judgement";

#create dataframe (id, Expert_judgement, TD_ID_E) for TP_E and FP_E
df_eval_e <- rbind(df_eval_tp_e, df_eval_fp_e);
names(df_eval_e)[names(df_eval_e) == "TrueDefectCode"] <- "TD_ID_E";

#creating dataframe which merges df_eval_e and df_eval_c based on the id
df_eval_c_e <- merge(x = df_eval_c, y = df_eval_e, by = "id");

#applying the evaluation table of task 3 in word
li_eval_id_tp <- df_eval_c_e[df_eval_c_e$Crowd_Judgement=="TPC"&df_eval_c_e$Expert_Judgement=="TPE"&df_eval_c_e$TD_ID_C==df_eval_c_e$TD_ID_E,][,c("id")]; 
c_eval_tp <- rep(c("TP"), length(li_eval_id_tp));
df_eval_tp <- data.frame("id"=li_eval_id_tp, "judgement"=c_eval_tp);

#strict evaluation: all the remaning TPC = TPE which are not already processed are counted as FP
li_eval_id_fp_1 <- df_eval_c_e[df_eval_c_e$Crowd_Judgement=="TPC"&df_eval_c_e$Expert_Judgement=="TPE"&df_eval_c_e$TD_ID_C!=df_eval_c_e$TD_ID_E,][,c("id")]; 
c_eval_fp_1 <- rep(c("FP"), length(li_eval_id_fp_1));
df_eval_fp_1 <- data.frame("id"=li_eval_id_fp_1, "judgement"=c_eval_fp_1);

li_eval_id_fp_2 <- df_eval_c_e[df_eval_c_e$Crowd_Judgement=="TPC"&df_eval_c_e$Expert_Judgement=="FPE",][,c("id")];
c_eval_fp_2 <- rep(c("FP"), length(li_eval_id_fp_2));
df_eval_fp_2 <- data.frame("id"=li_eval_id_fp_2, "judgement"=c_eval_fp_2);

li_eval_id_fn <- df_eval_c_e[df_eval_c_e$Crowd_Judgement=="FPC"&df_eval_c_e$Expert_Judgement=="TPE",][,c("id")];
c_eval_fn <- rep(c("FN"), length(li_eval_id_fn));
df_eval_fn <- data.frame("id"=li_eval_id_fn, "judgement"=c_eval_fn);

li_eval_id_tn <- df_eval_c_e[df_eval_c_e$Crowd_Judgement=="FPC"&df_eval_c_e$Expert_Judgement=="FPE",][,c("id")];
c_eval_tn <- rep(c("TN"), length(li_eval_id_tn));
df_eval_tn <- data.frame("id"=li_eval_id_tn, "judgement"=c_eval_tn);

#create a data.frame which holds all the data evaluated in one frame 
df_eval_compelte <- rbind(df_eval_tp, df_eval_fp_1, df_eval_fp_2, df_eval_fn, df_eval_tn);

#Precision, Recall, Accuarcy
cnt_tp <- nrow(df_eval_compelte[df_eval_compelte$judgement=="TP",]);
cnt_fp <- nrow(df_eval_compelte[df_eval_compelte$judgement=="FP",]);
cnt_fn <- nrow(df_eval_compelte[df_eval_compelte$judgement=="FN",]);
cnt_tn <- nrow(df_eval_compelte[df_eval_compelte$judgement=="TN",]);

#calucalte a sum to validate if all the IDRs have been collected
sum(cnt_tp, cnt_fp, cnt_fn, cnt_tn);

message("--- STRICT EVALUATION ---\n");
precision <- fun_precison(tp=cnt_tp, fp=cnt_fp);
message("Precision for strict evaluation: ", precision);

recall <- fun_recall(tp=cnt_tp, fn=cnt_fn);
message("Recall for strict evaluation: ", recall);

f1 <- fun_fmeasure(precision = precision, recall = recall);
message("F-Measure for lenient evaluation: ", f1);

accuracy <- fun_accuracy(tp=cnt_tp, tn=cnt_tn, fp=cnt_fp, fn=cnt_fn);
message("Accuracy for strict evaluation: ", accuracy);

#Cohen's Kappa two rater agreement (https://www.datanovia.com/en/lessons/cohens-kappa-in-r-for-two-categorical-variables/)
table_kappa_input <- as.table(rbind(
  c(cnt_tp, cnt_fp),
  c(cnt_fn, cnt_tn)
))
categories <- c("TP", "FP");
dimnames(table_kappa_input) <- list("crowd"=categories,"expert"=categories);
message("\nConfusion Matrix:");
message(paste0(capture.output(table_kappa_input), collapse = "\n"));

res.k <- Kappa(table_kappa_input);
res.k;
message("\nCohen's Kappa Coefficient:");
message(paste0(capture.output(res.k), collapse = "\n"));
message("Kappa Confidence Intervals:");
message(paste0(capture.output(confint(res.k)), collapse = "\n"));

message("---------------------------\n");


#Pearson Correlation
#cor.test(x = c(nrow(df_eval_fp_e),nrow(df_eval_tp_e)), y = c(nrow(df_eval_fp_c),nrow(df_eval_tp_c)), method = "pearson");
