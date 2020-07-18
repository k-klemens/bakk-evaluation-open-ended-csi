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
df_idrs_mv <- dbReadTable(con, "analysis_individualjudgements_s17_max_voting_notdids"); #contains information for TP_E, FP_E
dbDisconnect(con);

message("--- INDIVIDUAL AGGREGATION EVALUATION (IDRs) ---");
cnt_tp <- length(which(df_idrs_mv=="TP"));
cnt_fp <- length(which(df_idrs_mv=="FP"));
cnt_tn <- length(which(df_idrs_mv=="TN"));
cnt_fn <- length(which(df_idrs_mv=="FN"));

precision <- fun_precison(tp=cnt_tp, fp=cnt_fp);
message("Precision for individual lenient evaluation: ", precision);

recall <- fun_recall(tp=cnt_tp, fn=cnt_fn);
message("Recall for indvidual lenient evaluation: ", recall);

accuracy <- fun_accuracy(tp=cnt_tp, tn=cnt_tn, fp=cnt_fp, fn=cnt_fn);
message("Accuracy for indvidual lenient evaluation: ", accuracy);

fmeasure <- fun_fmeasure(precision = precision, recall = recall);
message("F-Measure/F-Score for indvidual lenient evaluation: ", fmeasure);
message("-------------------------------------");

