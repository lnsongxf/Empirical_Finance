# Peilin Yang 02/21/2021
# Parallel For FE Regression

library(foreign)
library(haven)
library(plm)
library(lmtest)
#library(data.table)
#library(readstata13)
setwd("/home/groups/chenzixu")
#
iteration_list<-list()
#df<-read_dta("matchid_final.dta")
#df2<-read.dta13("matchid_final.dta")
#start<-Sys.time()
data_handle<-load("matchid_final.RData")

#data_handle<-read.table("matchid_final.csv",header=T, sep=",")
#save(data_handle,file="matchid_final.RData")
#End<-Sys.time()
#print(End-start)
#write.csv(data,file = "mydata.csv",row.names = F)


for (Q in c("4","5")){
  
  for( M1 in c("pop", "emp", "share_no_school", "gdp_pop", "sserv",  "smanuf", "minwage", "s_gov", "school8p", "gini", "share_skill", "avg_inc2000", "lwage_8020", "lwage_9010", "lwage_9050", "lwage_5010", "lwage_7525", "lwage_pct10", "lwage_pct20",  "lwage_pct50", "firm_pop", "hhi_educ", "hhi_ind2", "s_primary", "s_middle", "s_emp1_5", "s_emp5_50", "s_emp50_plus", "sh_wage_top10", "skill_premium")) {
    
    for( M2 in  c("emp", "share_no_school", "gdp_pop", "sserv",  "smanuf", "minwage", "s_gov", "school8p", "gini", "share_skill", "avg_inc2000", "lwage_8020", "lwage_9010", "lwage_9050", "lwage_5010", "lwage_7525", "lwage_pct10", "lwage_pct20",  "lwage_pct50", "firm_pop", "hhi_educ", "hhi_ind2", "s_primary", "s_middle", "s_emp1_5", "s_emp5_50", "s_emp50_plus", "sh_wage_top10", "skill_premium")){
      
      for( M3 in  c("share_no_school", "gdp_pop", "sserv",  "smanuf", "minwage", "s_gov", "school8p", "gini", "share_skill", "avg_inc2000", "lwage_8020", "lwage_9010", "lwage_9050", "lwage_5010", "lwage_7525", "lwage_pct10", "lwage_pct20",  "lwage_pct50", "firm_pop", "hhi_educ", "hhi_ind2", "s_primary", "s_middle", "s_emp1_5", "s_emp5_50", "s_emp50_plus", "sh_wage_top10", "skill_premium")) {
        
        for( M4 in  c("gdp_pop", "sserv",  "smanuf", "minwage", "s_gov", "school8p", "gini", "share_skill", "avg_inc2000", "lwage_8020", "lwage_9010", "lwage_9050", "lwage_5010", "lwage_7525", "lwage_pct10", "lwage_pct20",  "lwage_pct50", "firm_pop", "hhi_educ", "hhi_ind2", "s_primary", "s_middle", "s_emp1_5", "s_emp5_50", "s_emp50_plus", "sh_wage_top10", "skill_premium")){
          
          if (M1!=M2&M2!=M3&M3!=M4&M1!=M3&M1!=M4&M2!=M4){
            iteration_list[[start_it]]<-""
            iteration_list[[start_it]][1]<-Q
            iteration_list[[start_it]][2]<-M1
            iteration_list[[start_it]][3]<-M2
            iteration_list[[start_it]][4]<-M3
            iteration_list[[start_it]][5]<-M4
            start_it<-start_it+1
          }
        }
      }
    }
  }
}

regression_fun <- function(start_it){
  library(haven)
  library(dplyr)
  # Read Data
  
  
  
  #iteration_list[[start_it]][1]<-Q
  #iteration_list[[start_it]][2]<-M1
  #iteration_list[[start_it]][3]<-M2
  #iteration_list[[start_it]][4]<-M3
  #iteration_list[[start_it]][5]<-M4
  start_it<-1
  # First condition
  name_v1<-paste(iteration_list[[start_it]][2],"PREq",iteration_list[[start_it]][1],sep = "")
  name_v2<-paste(iteration_list[[start_it]][3],"PREq",iteration_list[[start_it]][1],sep = "")
  name_v3<-paste(iteration_list[[start_it]][4],"PREq",iteration_list[[start_it]][1],sep = "")
  name_v4<-paste(iteration_list[[start_it]][5],"PREq",iteration_list[[start_it]][1],sep = "")
  cname_v1<-paste("C",name_v1,sep = "")
  cname_v2<-paste("C",name_v2,sep = "")
  cname_v3<-paste("C",name_v3,sep = "")
  cname_v4<-paste("C",name_v4,sep = "")
  
  df<-data_handle[data_handle[name_v1]==data_handle[cname_v1]|data_handle$treated==1,]
  
  df<-df[df[name_v2]==df[cname_v2]|df$treated==1,]
  df<-df[df[name_v3]==df[cname_v3]|df$treated==1,]
  df<-df[df[name_v4]==df[cname_v4]|df$treated==1,]
  
  data_group<- group_by(df, matchid)
  data_GroupByID<- summarise(data_group,count_each_group = n())
  df<-merge(df,data_GroupByID,by="matchid")
  df<-df[!df["count_each_group"]==15,]
  
  df<-arrange(df, matchid,-treated,Ceucli0300_3,year)
  
  index<-function(x){return(c(1:length(x)))}
  #by matchid: gen NB = _n
  #treated
  #df<-transform(df,NB=unlist(tapply(matchid,matchid,index)))
  df$NB <- with(df, ave(matchid, FUN = seq_along))
  #drop if NB>90
  df<-df[!df["NB"]>90,]
  
  
  #Q`Q'`M1'_`M2'_`M3' .Rdata
  file_path_noweight<-paste("results3_R/Q_",iteration_list[[start_it]][1],"_",
                            iteration_list[[start_it]][2],"_",iteration_list[[start_it]][3],"_",
                            iteration_list[[start_it]][4],"_",iteration_list[[start_it]][5],"_noweight.Rdata",sep="")
  file_path_emp2000weight<-paste("results3_R/Q_",iteration_list[[start_it]][1],"_",
                                 iteration_list[[start_it]][2],"_",iteration_list[[start_it]][3],"_",
                                 iteration_list[[start_it]][4],"_",iteration_list[[start_it]][5],"_emp2000weight.RData",sep="")
  file_path_pop2000weight<-paste("results3_R/Q_",iteration_list[[start_it]][1],"_",
                                 iteration_list[[start_it]][2],"_",iteration_list[[start_it]][3],"_",
                                 iteration_list[[start_it]][4],"_",iteration_list[[start_it]][5],"_pop2000weight.RData",sep="")
  
  # Fixed Effect Regression
  tryCatch(
    {
      fe_noweight <- plm( lemp~shock, data=df, index=c("matchyr","amc"), model="within", effect="twoways")
      fe_noweight["weight_add"]<-"no-weight"
      fe_noweight["Nb Treated"]<-sum(df$Ntreated,na.rm=T)
      save(fe_noweight,file=file_path_noweight)
    }, 
    error=function(e){cat("ERROR :",conditionMessage(e), "\n")})
  tryCatch(
    {
      fe_emp2000weight <- plm( lemp~shock, data=df, index=c("matchyr","amc"),weights=(df$emp2000)^(-1), model="within", effect="twoways")
      fe_emp2000weight["weight_add"]<-"emp-2000"
      fe_emp2000weight["Nb Treated"]<-sum(df$Ntreated,na.rm=T)
      save(fe_emp2000weight,file=file_path_emp2000weight)
    }, 
    error=function(e){cat("ERROR :",conditionMessage(e), "\n")})
  tryCatch(
    {
      fe_pop2000weight <- plm( lemp~shock, data=df, index=c("matchyr","amc"),weights=(df$pop2000)^(-1), model="within", effect="twoways")
      fe_pop2000weight["weight_add"]<-"pop-2000"
      fe_pop2000weight["Nb Treated"]<-sum(df$Ntreated,na.rm=T)
      save(fe_pop2000weight,file=file_path_pop2000weight)
    }, 
    error=function(e){cat("ERROR :",conditionMessage(e), "\n")})
}

#start_time <- Sys.time()

for (er in 1:10){
  regression_fun(er)
}

hhh
#end_time <- Sys.time()
#print("not parallel")
#print(end_time-start_time)


#start_time <- Sys.time()
library(doParallel)
cores<-detectCores()
cl <- makeCluster(cores)
registerDoParallel(cl)
# Parallel
# length(iteration_list)
y <- foreach(x=1:60,.combine='rbind') %dopar% regression_fun(x)
stopCluster(cl)
#end_time <- Sys.time()
#print("parallel")
#print(end_time-start_time)
