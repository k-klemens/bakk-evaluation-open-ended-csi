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

source(file = "basic-functions.R", echo = TRUE);

#connect to the db
con <- dbConnect(RMariaDB::MariaDB(), 
                 dbname="csi_bakk", 
                 username=rstudioapi::askForPassword("Username"), 
                 password=rstudioapi::askForPassword("Password"));

#read the data from the datbase to R datasframes
df_drj_kk_s17 <- dbReadTable(con, "DefectReportJudgements_KK_S17"); #contains information for TP_E, FP_E
df_drvr_kk_s17 <- dbReadTable(con, "DefectReportValidationReport_KK_MA$S17_StrictMapping"); #contains information for TP_C, FP_C
dbDisconnect(con);

##data transformation 

#using the aggregated list to create a dataframe (id, Crowd_Majority_Judgement) for TP_C and FP_C
df_eval_c <- df_drvr_kk_s17[,c("id", "X_worker_id", "Expert_Comparison")];
names(df_eval_c)[names(df_eval_c) == "Expert_Comparison"] <- "Crowd_Judgement";
names(df_eval_c)[names(df_eval_c) == "X_worker_id"] <- "workerId";
df_eval_c$Crowd_Judgement[df_eval_c$Crowd_Judgement == "TP"] <- "TPC";
df_eval_c$Crowd_Judgement[df_eval_c$Crowd_Judgement == "FP"] <- "FPC";

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
df_eval_tp <- df_eval_c_e[df_eval_c_e$Crowd_Judgement=="TPC"&df_eval_c_e$Expert_Judgement=="TPE",][,c("id", "workerId")];
c_eval_tp <- rep(c("TP"), nrow(df_eval_tp));
df_eval_tp["judgement"] <- c_eval_tp;

df_eval_fp <- df_eval_c_e[df_eval_c_e$Crowd_Judgement=="TPC"&df_eval_c_e$Expert_Judgement=="FPE",][,c("id", "workerId")];
c_eval_fp <- rep(c("FP"), nrow(df_eval_fp));
df_eval_fp["judgement"] <- c_eval_fp;

df_eval_fn <- df_eval_c_e[df_eval_c_e$Crowd_Judgement=="FPC"&df_eval_c_e$Expert_Judgement=="TPE",][,c("id", "workerId")];
c_eval_fn <- rep(c("FN"), nrow(df_eval_fn));
df_eval_fn["judgement"] <- c_eval_fn;

df_eval_tn <- df_eval_c_e[df_eval_c_e$Crowd_Judgement=="FPC"&df_eval_c_e$Expert_Judgement=="FPE",][,c("id", "workerId")];
c_eval_tn <- rep(c("TN"), nrow(df_eval_tn));
df_eval_tn["judgement"] <- c_eval_tn;

#create a data.frame which holds all the data evaluated in one frame 
df_eval_compelte <- rbind(df_eval_tp, df_eval_fp, df_eval_fn, df_eval_tn);

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

df_accuracy_by_worker <- aggregate(x=df_eval_compelte[,c("judgement")], by=list(df_eval_compelte$workerId), FUN = accuracy_by_worker)
names(df_accuracy_by_worker) <- c("workerId", "accuracy");
message(paste0(capture.output(df_accuracy_by_worker), collapse = "\n"));

dev.off();
hist(df_accuracy_by_worker$accuracy,
     main = paste("Accuracy per Worker"),
     xlab = "Accuracy",
     ylim = c(0,30),
     xlim = c(0.1,1),
     axes = FALSE);
axis(side = 1, at=seq(0.1,1,0.1));
axis(side = 2, at=seq(0,30,2));

dirNameForPlots <- file.path(getwd(), "plotting-out", format(Sys.time(), "%Y-%m-%d-%H-%M"));
dir.create(dirNameForPlots, recursive = TRUE, showWarnings = FALSE);
dev.copy(png,file.path(dirNameForPlots, paste0("plot-accuracy-per-worker.png")));
dev.off();


kappa_by_worker <- function(x) {
  cnt_tp_w <- length(which(x=="TP"));
  cnt_fp_w <- length(which(x=="FP"));
  cnt_tn_w <- length(which(x=="TN"));
  cnt_fn_w <- length(which(x=="FN"));
  
  table_kappa_input <- as.table(rbind(
    c(cnt_tp_w, cnt_fp_w),
    c(cnt_fn_w, cnt_tn_w)
  ))
  categories <- c("TP", "FP");
  dimnames(table_kappa_input) <- list("crowd-worker"=categories,"expert"=categories);
  res.k <- Kappa(table_kappa_input);
  return(res.k[1]$Unweighted[1]);
}

df_kappa_by_worker <- aggregate(x=df_eval_compelte[,c("judgement")], by=list(df_eval_compelte$workerId), FUN = kappa_by_worker)
names(df_kappa_by_worker) <- c("workerId", "cohen-kappa");
message(paste0(capture.output(df_kappa_by_worker), collapse = "\n"));

write.csv(df_kappa_by_worker, "kappa_by_worker-strict.csv");
message("wrote kappa results by worker to csv.");


#qqnorm(df_accuracy_by_worker$accuracy);
#qqline(df_accuracy_by_worker$accuracy)
