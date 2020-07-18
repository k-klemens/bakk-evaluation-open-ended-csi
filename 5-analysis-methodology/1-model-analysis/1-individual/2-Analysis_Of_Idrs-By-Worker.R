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

#extracting all the rows where the respective judgements columns (TP, FP, TN, FN) are true and merge them into one dataframe with only one judgements column
df_idr_tp <- df_idrs[df_idrs$TruePositive == 1,][,c("id", "Worker")]
c_tp <- rep(c("TP"), nrow(df_idr_tp));
df_idr_tp["judgement"] <- c_tp;

df_idr_fp <- df_idrs[df_idrs$FalsePositive == 1,][,c("id", "Worker")];
c_fp <- rep(c("FP"), nrow(df_idr_fp));
df_idr_fp["judgement"] <- c_fp;


df_idr_tn <- df_idrs[df_idrs$TrueNegative == 1,][,c("id", "Worker")];
c_tn <- rep(c("TN"), nrow(df_idr_tn))
df_idr_tn["judgement"] <- c_tn;


df_idr_fn <- df_idrs[df_idrs$FalseNegative == 1,][,c("id", "Worker")];
c_fn <- rep(c("FN"), nrow(df_idr_fn))
df_idr_fn["judgement"] <- c_fn;

df_eval_compelte <- rbind(df_idr_tp, df_idr_fp, df_idr_tn, df_idr_fn);

#Precision, Recall, Accuarcy per worker 
accuracy_by_worker <- function(x) {
  # x is a list which contains all the judgements as a charackter by one worker
  #creating a dataframe where the specific judgements are colltected and counted
  df_return <- cbind(
    length(which(x=="TP")),
    length(which(x=="FP")),
    length(which(x=="TN")),
    length(which(x=="FN"))
  );
  #setting the names of the variables in the data.frame
  names(df_return) <- c("TP", "FP", "TN", "FN");
  
  cnt_tp_w <- length(which(x=="TP"));
  cnt_fp_w <- length(which(x=="FP"));
  cnt_tn_w <- length(which(x=="TN"));
  cnt_fn_w <- length(which(x=="FN"));
  acc <- fun_accuracy(tp=cnt_tp_w, tn=cnt_tn_w, fp=cnt_fp_w, fn=cnt_fn_w);
  return(acc);
}

#Precision, Recall, Accuarcy per worker 
f1_by_worker <- function(x) {
  cnt_tp_w <- length(which(x=="TP"));
  cnt_fp_w <- length(which(x=="FP"));
  cnt_tn_w <- length(which(x=="TN"));
  cnt_fn_w <- length(which(x=="FN"));
  precision <- fun_precison(tp=cnt_tp_w, fp=cnt_fp_w);
  recall <- fun_recall(tp=cnt_tp_w, fn=cnt_fn_w);
  f1 <- fun_fmeasure(precision = precision, recall = recall);
  return(f1);
}

message("--- ACCURACY BY WORKER EVALUATION (IDRs) ---");

df_accuracy_by_worker <- aggregate(x=df_eval_compelte[,c("judgement")], by=list(df_eval_compelte$Worker), FUN = accuracy_by_worker)
names(df_accuracy_by_worker) <- c("workerId", "accuracy");
df_accuracy_by_worker_ordered <- df_accuracy_by_worker[order(df_accuracy_by_worker$accuracy),]
message(paste0(capture.output(df_accuracy_by_worker_ordered), collapse = "\n"));

dev.new(width=500, height=500);
par(mar=c(5,5,0,1)+0.1,bg="white"); 
hist_aggregated <- hist(df_accuracy_by_worker$accuracy, plot = FALSE);
hist(df_accuracy_by_worker$accuracy,
     #main = paste("Accuracy per Worker"),
     main = NA,
     xlab = "Accuracy",
     ylim = c(0,max(hist_aggregated$counts)+2),
     xlim = c(0.3,1),
     axes = FALSE);
axis(side = 1, at=seq(0.3,1,0.1));
axis(side = 2, at=seq(0,max(hist_aggregated$counts)+1,2));
dev.copy(png, "/Users/kk/Dropbox/Studium/SS20/Bakk-QSE/HComp2020/Data/updated-plots/plot-ma-acc-per-worker.png");
dev.off();
message("See plot window for historgram.")
message("--------------------------------------------");


message("--- F1 BY WORKER EVALUATION (IDRs) ---");
df_f1_by_worker <- aggregate(x=df_eval_compelte[,c("judgement")], by=list(df_eval_compelte$Worker), FUN = f1_by_worker)
names(df_f1_by_worker) <- c("workerId", "f1");
df_f1_by_worker_ordered <- df_f1_by_worker[order(df_f1_by_worker$f1),]
message(paste0(capture.output(df_f1_by_worker_ordered), collapse = "\n"));

dev.new(width=500, height=500);
par(mar=c(5,5,0,1)+0.1,bg="white"); 
hist_aggregated <- hist(df_f1_by_worker$f1, plot = FALSE);
hist(df_f1_by_worker$f1,
     #main = paste("F-Measure per Worker"),
     main = NULL,
     xlab = "F-Measure",
     ylim = c(0,max(hist_aggregated$counts)+2),
     xlim = c(0.2,0.9),
     axes = FALSE);
axis(side = 1, at=seq(0.2,0.9,0.1));
axis(side = 2, at=seq(0,max(hist_aggregated$counts)+1,2));
dev.copy(png, "/Users/kk/Dropbox/Studium/SS20/Bakk-QSE/HComp2020/Data/updated-plots/plot-ma-f1-per-worker.png");
dev.off();
message("See plot window for historgram.")
message("--------------------------------------------");

