#basic functions 
#define basic functions
fun_accuracy <- function(tp,tn,fp,fn){
  classified_correct <- tp+tn;
  n <- tp+tn+fp+fn;
  acc <- classified_correct / n;
  return(acc);
}

fun_recall <- function(tp, fn) {
  rec <- tp / (tp+fn);
  return (rec);
}

fun_precison <- function(tp, fp){
  prec <- tp / (tp+fp);
  return (prec);
}

#F-Measure = (2 * Precision * Recall) / (Precision + Recall)
fun_fmeasure <- function(precision, recall) {
  return((2 * precision * recall) / (precision + recall));
}
