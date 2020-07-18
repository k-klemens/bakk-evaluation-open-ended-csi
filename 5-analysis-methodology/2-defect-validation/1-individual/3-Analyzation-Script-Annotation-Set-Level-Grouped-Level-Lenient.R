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
df_drvr_kk_s17 <- dbReadTable(con, "DefectReportValidationReport_KK_MA$S17_LenientMapping"); #contains information for TP_C, FP_C
dbDisconnect(con);


##data transformation 

#using the aggregated list to create a dataframe (id, grouped-column, Crowd_Majority_Judgement) for TP_C and FP_C
#include defect_type to be used for coloring each defect_type differntly in graph.
df_eval_c <- df_drvr_kk_s17[,c("id", toString(groupedBy), "Expert_Comparison", "defect_type"), ];
names(df_eval_c)[names(df_eval_c) == "Expert_Comparison"] <- "Crowd_Judgement";
names(df_eval_c)[names(df_eval_c) == toString(groupedBy)] <- "groupedCol";
df_eval_c$Crowd_Judgement[df_eval_c$Crowd_Judgement == "TP"] <- "TPC";
df_eval_c$Crowd_Judgement[df_eval_c$Crowd_Judgement == "FP"] <- "FPC";

#create dataframe (id, grouped-column, Crowd_Judgement) for TP_C
df_eval_tp_c <- df_eval_c[df_eval_c$Crowd_Judgement=="TPC",]

#create dataframe (id, grouped-column, Crowd_Judgement) for FP_C
df_eval_fp_c <- df_eval_c[df_eval_c$Crowd_Judgement=="FPC",]

#create dataframe (id, Expert_Judgement) for TP_E
df_eval_tp_e <- df_drj_kk_s17[df_drj_kk_s17$TruePositive==1 & df_drj_kk_s17$Split_Nr=='_1',][, c("id","TruePositive")]
df_eval_tp_e$TruePositive<- "TPE" #map the TruePositive numeric value to TP
names(df_eval_tp_e)[names(df_eval_tp_e) == "TruePositive"] <- "Expert_Judgement";

#create dataframe (id, Expert_Judgement) for FP_E
df_eval_fp_e <- df_drj_kk_s17[(df_drj_kk_s17$FalsePositive==1 & df_drj_kk_s17$Split_Nr=='_1') | (df_drj_kk_s17$FalsePositive==0 & df_drj_kk_s17$TruePositive==0),][, c("id", "FalsePositive")]
df_eval_fp_e$FalsePositive<- "FPE" #map the FalsePositive numeric value to TP
names(df_eval_fp_e)[names(df_eval_fp_e) == "FalsePositive"] <- "Expert_Judgement";

#create dataframe (id, Expert_judgement) for TP_E and FP_E
df_eval_e <- rbind(df_eval_tp_e, df_eval_fp_e);

#creating dataframe which merges df_eval_e and df_eval_c based on the id
df_eval_c_e <- merge(x = df_eval_c, y = df_eval_e, by = "id");

#applying the evaluation table of task 3 in word
df_eval_tp <- df_eval_c_e[df_eval_c_e$Crowd_Judgement=="TPC"&df_eval_c_e$Expert_Judgement=="TPE",][,c("id", "groupedCol")];
c_eval_tp <- rep(c("TP"), nrow(df_eval_tp));
df_eval_tp["judgement"] <- c_eval_tp;

df_eval_fp <- df_eval_c_e[df_eval_c_e$Crowd_Judgement=="TPC"&df_eval_c_e$Expert_Judgement=="FPE",][,c("id", "groupedCol")];
c_eval_fp <- rep(c("FP"), nrow(df_eval_fp));
df_eval_fp["judgement"] <- c_eval_fp;

df_eval_fn <- df_eval_c_e[df_eval_c_e$Crowd_Judgement=="FPC"&df_eval_c_e$Expert_Judgement=="TPE",][,c("id", "groupedCol")];
c_eval_fn <- rep(c("FN"), nrow(df_eval_fn));
df_eval_fn["judgement"] <- c_eval_fn;

df_eval_tn <- df_eval_c_e[df_eval_c_e$Crowd_Judgement=="FPC"&df_eval_c_e$Expert_Judgement=="FPE",][,c("id", "groupedCol")];
c_eval_tn <- rep(c("TN"), nrow(df_eval_tn));
df_eval_tn["judgement"] <- c_eval_tn;

#create a data.frame which holds all the data evaluated in one frame 
df_eval_compelte <- rbind(df_eval_tp, df_eval_fp, df_eval_fn, df_eval_tn);

#Precision, Recall, Accuarcy per worker 
accuracy_by_groups <- function(x) {
  cnt_tp_w <- length(which(x=="TP"));
  cnt_fp_w <- length(which(x=="FP"));
  cnt_tn_w <- length(which(x=="TN"));
  cnt_fn_w <- length(which(x=="FN"));
  acc <- fun_accuracy(tp=cnt_tp_w, tn=cnt_tn_w, fp=cnt_fp_w, fn=cnt_fn_w);
  return(acc);
}

#Precision, Recall, Accuarcy per worker 
f1_by_groups <- function(x) {
  cnt_tp_w <- length(which(x=="TP"));
  cnt_fp_w <- length(which(x=="FP"));
  cnt_tn_w <- length(which(x=="TN"));
  cnt_fn_w <- length(which(x=="FN"));
  precision <- fun_precison(tp=cnt_tp_w, fp=cnt_fp_w);
  recall <- fun_recall(tp=cnt_tp_w, fn=cnt_fn_w);
  f1 <- fun_fmeasure(precision = precision, recall = recall);
  return(f1);
}

df_defect_types_codetd_mapping <- unique(df_drvr_kk_s17[,c("codetd", "defect_type"),]);
names(df_defect_types_codetd_mapping) <- c("groupedBy", "defect_type");

df_accuracy_by_groups <- aggregate(x=df_eval_compelte[,c("judgement")], by=list(df_eval_compelte$groupedCol), FUN = accuracy_by_groups)
names(df_accuracy_by_groups) <- c("groupedBy", "accuracy");
df_accuracy_by_groups_sorted <- df_accuracy_by_groups[order(df_accuracy_by_groups$accuracy),];
df_accuracy_by_groups_merged <- merge(x=df_accuracy_by_groups_sorted, y=df_defect_types_codetd_mapping, by="groupedBy");
df_accuracy_by_groups_merged_sorted <- df_accuracy_by_groups_merged[with(df_accuracy_by_groups_merged, order(df_accuracy_by_groups_merged$defect_type, df_accuracy_by_groups_merged$accuracy)),]


message(paste0(capture.output(df_accuracy_by_groups_merged_sorted), collapse = "\n"));
dev.new(width=500, height=500);
par(mar=c(5,5,0,1)+0.1,bg="white"); 
plot(x = seq(1,nrow(df_accuracy_by_groups_merged_sorted)), y = df_accuracy_by_groups_merged_sorted$accuracy, axes = FALSE,
     ylim = c(0.3,1), xlim = c(1, nrow(df_accuracy_by_groups_merged_sorted)),
     #main=paste("Accuracy grouped by",groupedBy), 
     ylab = "Accuracy", xlab="", pch=18,
     #,col=as.factor(df_accuracy_by_groups_sorted$groupedBy)
     col=as.factor(df_accuracy_by_groups_merged_sorted$defect_type)
     );
axis.labels = c(df_accuracy_by_groups_merged_sorted$groupedBy);
axis(side=1,at=seq(1, nrow(df_accuracy_by_groups_merged_sorted)), labels = axis.labels, cex.axis=0.9, las=2);
axis(side=2, at=seq(0.3,1,0.1), cex.axis = 0.7);
grid(nx= 0, ny=NULL);

dirNameForPlots <- file.path(getwd(), "plotting-out", paste0(format(Sys.time(), "%Y-%m-%d-%H-%M"),"-grouped-by-", groupedBy));
dir.create(dirNameForPlots, recursive = TRUE, showWarnings = FALSE);
dev.copy(png,file.path(dirNameForPlots, paste0("plot-accuracy-per-grouped-by-",groupedBy,".png")));
dev.off();




df_f1_by_groups <- aggregate(x=df_eval_compelte[,c("judgement")], by=list(df_eval_compelte$groupedCol), FUN = f1_by_groups)
names(df_f1_by_groups) <- c("groupedBy", "f1");
df_f1_by_groups_sorted <- df_f1_by_groups[order(df_f1_by_groups$f1),];
df_f1_by_groups_merged <- merge(x=df_f1_by_groups_sorted, y=df_defect_types_codetd_mapping, by="groupedBy");
df_f1_by_groups_merged_sorted <- df_f1_by_groups_merged[with(df_f1_by_groups_merged, order(df_f1_by_groups_merged$defect_type, df_f1_by_groups_merged$f1)),]

message(paste0(capture.output(df_f1_by_groups_merged_sorted), collapse = "\n"));
dev.new(width=500, height=500);
par(mar=c(5,5,0,1)+0.1,bg="white"); 
plot(x = seq(1,nrow(df_f1_by_groups_merged_sorted)), y = df_f1_by_groups_merged_sorted$f1, axes = FALSE,
     ylim = c(0.3,1), xlim = c(1, nrow(df_f1_by_groups_merged_sorted)),
     #main=paste("Accuracy grouped by",groupedBy), 
     ylab = "F-Measure", xlab="", pch=18
     ,col=as.factor(df_f1_by_groups_merged_sorted$defect_type)
);
axis.labels = c(df_f1_by_groups_merged_sorted$groupedBy);
axis(side=1,at=seq(1, nrow(df_f1_by_groups_merged_sorted)), labels = axis.labels, cex.axis=0.9, las=2);
axis(side=2, at=seq(0.3,1,0.1), cex.axis = 0.7);
grid(nx= 0, ny=NULL);
unique(df_defect_types_codetd_mapping$defect_type);

dirNameForPlots <- file.path(getwd(), "plotting-out", paste0(format(Sys.time(), "%Y-%m-%d-%H-%M"),"-grouped-by-", groupedBy));
dir.create(dirNameForPlots, recursive = TRUE, showWarnings = FALSE);
dev.copy(png,file.path(dirNameForPlots, paste0("plot-f1-per-grouped-by-",groupedBy,".png")));
dev.off();

