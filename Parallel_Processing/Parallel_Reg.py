# -*- coding: utf-8 -*-
"""
Created on Tue Feb 23 16:38:18 2021

@author: Peilin Yang
"""

import pandas as pd
import statsmodels.api as sm
import numpy as np
import pickle
from linearmodels import PanelOLS
from multiprocessing.pool import ThreadPool

iteration_list=[]

main_data=pd.read_stata(r"C:\Users\Peilin\server_stanford\matchid_final.dta")


#main_data=pd.read_stata(r"C:\Users\Peilin Yang\David Yang Dropbox\Yang Peilin\Peilin\server_stanford\matchid_final.dta")

for Q in ["4","5"]:
  for M1 in ["pop", "emp", "share_no_school", "gdp_pop", "sserv",  "smanuf", "minwage", "s_gov", "school8p", "gini", "share_skill", "avg_inc2000", "lwage_8020", "lwage_9010", "lwage_9050", "lwage_5010", "lwage_7525", "lwage_pct10", "lwage_pct20",  "lwage_pct50", "firm_pop", "hhi_educ", "hhi_ind2", "s_primary", "s_middle", "s_emp1_5", "s_emp5_50", "s_emp50_plus", "sh_wage_top10", "skill_premium"]:
    for M2 in  ["emp", "share_no_school", "gdp_pop", "sserv",  "smanuf", "minwage", "s_gov", "school8p", "gini", "share_skill", "avg_inc2000", "lwage_8020", "lwage_9010", "lwage_9050", "lwage_5010", "lwage_7525", "lwage_pct10", "lwage_pct20",  "lwage_pct50", "firm_pop", "hhi_educ", "hhi_ind2", "s_primary", "s_middle", "s_emp1_5", "s_emp5_50", "s_emp50_plus", "sh_wage_top10", "skill_premium"]:
      for M3 in  ["share_no_school", "gdp_pop", "sserv",  "smanuf", "minwage", "s_gov", "school8p", "gini", "share_skill", "avg_inc2000", "lwage_8020", "lwage_9010", "lwage_9050", "lwage_5010", "lwage_7525", "lwage_pct10", "lwage_pct20",  "lwage_pct50", "firm_pop", "hhi_educ", "hhi_ind2", "s_primary", "s_middle", "s_emp1_5", "s_emp5_50", "s_emp50_plus", "sh_wage_top10", "skill_premium"]:
        for M4 in  ["gdp_pop", "sserv",  "smanuf", "minwage", "s_gov", "school8p", "gini", "share_skill", "avg_inc2000", "lwage_8020", "lwage_9010", "lwage_9050", "lwage_5010", "lwage_7525", "lwage_pct10", "lwage_pct20",  "lwage_pct50", "firm_pop", "hhi_educ", "hhi_ind2", "s_primary", "s_middle", "s_emp1_5", "s_emp5_50", "s_emp50_plus", "sh_wage_top10", "skill_premium"]:
          if M1!=M2 and M2!=M3 and M3!=M4 and M1!=M3 and M1!=M4 and M2!=M4:
              iteration_list.append([Q,M1,M2,M3,M4])



def regression_fun(start_it):
    
    #print(start_it,"\n")
    
    name_v1=iteration_list[start_it][2-1]+"PREq"+iteration_list[start_it][1-1]
    name_v2=iteration_list[start_it][3-1]+"PREq"+iteration_list[start_it][1-1]
    name_v3=iteration_list[start_it][4-1]+"PREq"+iteration_list[start_it][1-1]
    name_v4=iteration_list[start_it][5-1]+"PREq"+iteration_list[start_it][1-1]
    cname_v1="C"+name_v1
    cname_v2="C"+name_v2
    cname_v3="C"+name_v3
    cname_v4="C"+name_v4
    df=main_data[(main_data[name_v1]==main_data[cname_v1]) | (main_data["treated"]==1)]
    df=df[(df[name_v2]==df[cname_v2]) | (df["treated"]==1)]
    df=df[(df[name_v3]==df[cname_v3]) | (df["treated"]==1)]
    df=df[(df[name_v4]==df[cname_v4]) | (df["treated"]==1)]
    
    groupnum = pd.DataFrame(df.groupby(['matchid']).size(),columns=["nummatchid"])
    
    df=pd.merge(df,groupnum,how="inner",on='matchid')
    
    df=df[df["nummatchid"]!=15]
    
    df=df.sort_values(by=["matchid","treated","Ceucli0300_3","year"],ascending=[True,False,True,True])
    
    df["NB"]=df["treated"].groupby(df["matchid"]).rank()
    df=df[df["NB"]<=90]
    
    file_path_noweight="results3/Q_"+iteration_list[start_it][1-1]+"_"+iteration_list[start_it][2-1]+"_"+iteration_list[start_it][3-1]+"_"+iteration_list[start_it][4-1]+"_"+iteration_list[start_it][5-1]+"_noweight.pkl"
    file_path_emp2000weight="results3/Q_"+iteration_list[start_it][1-1]+"_"+iteration_list[start_it][2-1]+"_"+iteration_list[start_it][3-1]+"_"+iteration_list[start_it][4-1]+"_"+iteration_list[start_it][5-1]+"_emp2000weight.pkl"
    file_path_pop2000weight="results3/Q_"+iteration_list[start_it][1-1]+"_"+iteration_list[start_it][2-1]+"_"+iteration_list[start_it][3-1]+"_"+iteration_list[start_it][4-1]+"_"+iteration_list[start_it][5-1]+"_pop2000weight.pkl"

    

    #matchyr=pd.Categorical(df.matchyr)
    df=df.set_index(["matchyr","amc"])
    #df['matchyr']=matchyr

    exog_vars=['shock']
    exog=sm.add_constant(df[exog_vars])
    
    try:
        #mod_no_w=[]
        res=[]
        mod_no_w=PanelOLS(df.lemp,exog,entity_effects=True)
        res=mod_no_w.fit()
        mod_no_w_coeff=pd.DataFrame([iteration_list[start_it][1]+"-"+iteration_list[start_it][2]+"-"+iteration_list[start_it][3]+"-"+iteration_list[start_it][4],res._params[1],res.std_errors._values[1],len(res.resids.T),df['Ntreated'].sum(),"no-weight"])
        mod_no_w_coeff.to_pickle(file_path_noweight)
        #del mod_no_w._w
        #del mod_no_w._x
        #del mod_no_w._y
        #mod_no_w.weight_add="no-weight"
        #mod_no_w.Nb_Treated=df['Ntreated'].sum()
        
        # 1:Name: 
        # 2:Coefficient:  res._params[1]
        # 3:Standarad_Error: res.std_errors._values[1]
        # 4:Obs: len(res.resids.T)
        # 5:Nb Treated: df['Ntreated'].sum()
        # 6:Weight
        
        
    except Exception as e:
        #print(e)
        pass
    try:
        res=[]
        mod_emp2000=PanelOLS(df.lemp,exog,weights=abs(df.emp2000)+1e-6,entity_effects=True)
        res=mod_emp2000.fit()
        mod_emp2000_coeff=pd.DataFrame([iteration_list[start_it][1]+"-"+iteration_list[start_it][2]+"-"+iteration_list[start_it][3]+"-"+iteration_list[start_it][4],res._params[1],res.std_errors._values[1],len(res.resids.T),df['Ntreated'].sum(),"no-weight"])
        mod_emp2000_coeff.to_pickle(file_path_emp2000weight)
        #del mod_emp2000._w
        #del mod_emp2000._x
        #del mod_emp2000._y
        #mod_emp2000.weight_add="emp-2000"
        #mod_emp2000.Nb_Treated=df['Ntreated'].sum()
    except Exception as e:
        #print(e)
        pass
    try:
        res=[]
        mod_pop2000=PanelOLS(df.lemp,exog,weights=abs(df.emp2000)+1e-6,entity_effects=True)
        res=mod_pop2000.fit()
        mod_pop2000_coeff=pd.DataFrame([iteration_list[start_it][1]+"-"+iteration_list[start_it][2]+"-"+iteration_list[start_it][3]+"-"+iteration_list[start_it][4],res._params[1],res.std_errors._values[1],len(res.resids.T),df['Ntreated'].sum(),"no-weight"])
        mod_pop2000_coeff.to_pickle(file_path_pop2000weight)
        #mod_pop2000=PanelOLS(df.lemp,exog,weights=abs(df.pop2000)+1e-6,entity_effects=True)
        #del mod_pop2000._w
        #del mod_pop2000._x
        #del mod_pop2000._y
        #mod_pop2000.weight_add="pop-2000"
        #mod_pop2000.Nb_Treated=df['Ntreated'].sum()
    except Exception as e:
        #print(e)
        pass

    
    
    
    #del mod.exog
    #del mod.weights
    #del mod._not_null
    #del mod._original_index
    #del mod.dependent
    
    
   
    #res=mod_no_w.fit(cov_type='clustered',cluster_entity=True)
    #print(res)
    
    
    #with open(file_path_noweight, 'wb') as f:
    #    pickle.dump(mod_no_w, f)
    
    #with open(file_path_emp2000weight, 'wb') as f:
    #    pickle.dump(mod_emp2000, f)
        
    #with open(file_path_pop2000weight, 'wb') as f:
    #    pickle.dump(mod_pop2000, f)
    #np.save(file_path_noweight,mod_no_w)
    #np.save(file_path_emp2000weight,mod_emp2000)
    #np.save(file_path_pop2000weight,mod_pop2000)


import warnings
import time



warnings.filterwarnings("ignore")
#10000-20000
#iter_nums=list(range(12610,20000))
time_start=time.time()
#iter_nums=list(range(50000,60000))
#iter_nums=list(range(80000,90000))
iter_nums=list(range(120000,130000))
pool_size = 8
pool = ThreadPool(pool_size)  # create a new pool
results = pool.map(regression_fun, iter_nums)  # add thread 
pool.close()  # no accept new thread
pool.join()  # wait to finish
time_end=time.time()
print('totally cost',time_end-time_start)



#import pickle


#with open(filepath, 'rb') as f:
#    file_path_emp2000weight = pickle.load(f)


#res=file_path_emp2000weight.fit(cov_type='clustered',cluster_entity=True)
 
