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
df_idrs <- dbReadTable(con, "analysis_individualjudgements_s17_simple"); #contains information for TP_E, FP_E
dbDisconnect(con);

message("--- INDIVIDUAL LENIENT EVALUATION (IDRs) ---");
cnt_tp <- nrow(df_idrs[df_idrs$TruePositive == 1,]);
cnt_fp <- nrow(df_idrs[df_idrs$FalsePositive == 1,]);
cnt_tn <- nrow(df_idrs[df_idrs$TrueNegative == 1,]);
cnt_fn <- nrow(df_idrs[df_idrs$FalseNegative == 1,]);

precision <- fun_precison(tp=cnt_tp, fp=cnt_fp);
message("Precision for individual lenient evaluation: ", precision);

recall <- fun_recall(tp=cnt_tp, fn=cnt_fn);
message("Recall for indvidual lenient evaluation: ", recall);

accuracy <- fun_accuracy(tp=cnt_tp, tn=cnt_tn, fp=cnt_fp, fn=cnt_fn);
message("Accuracy for indvidual lenient evaluation: ", accuracy);

fmeasure <- fun_fmeasure(precision = precision, recall = recall);
message("F-Measure/F-Score for indvidual lenient evaluation: ", fmeasure);
message("-------------------------------------");
