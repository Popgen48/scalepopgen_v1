import os
import sys
import re
import pandas as pd
import numpy as np

window_size = sys.argv[1]
sel_threshold    = sys.argv[2]
method = sys.argv[3]
pop = sys.argv[4]
chrom_map_file = sys.argv[5]
outprefix = sys.argv[6]
files = sys.argv[7:]

df = pd.DataFrame()

chrom_id_map_dict = {}

if chrom_map_file != "none":
    with open(chrom_map_file) as source:
        for line in source:
            line = line.rstrip().split()
            chrom_id_map_dict[line[0]] = int(line[1])

for file in files:
    if method != "ihs":
        df1 = pd.read_csv(file,delim_whitespace=True,index_col=False)
        if method == "sweepfinder2":
            chrom = re.search('.+?(?=_'+re.escape(pop)+'.)',file)[0]
            new_column = [chrom]*len(df1.index)
            df1.insert(0,"CHROM",new_column,True)
            df1.rename(columns={'location': 'BIN_START'}, inplace=True)
            df1["BIN_START"] = df1["BIN_START"].round(0).astype(int)
    else:
        df1 = pd.read_csv(file,delim_whitespace=True,index_col=False, names=["locusID","BIN_START","1_freq","ihh1","ihh0","row_ihs","std_ihs","quantile"])
        chrom = re.search('.+?(?=_'+re.escape(pop)+'.)',file)[0]
        new_column = [chrom]*len(df1.index)
        df1.insert(0,"CHROM",new_column,True)
        df1["std_ihs"] = df1["std_ihs"].abs()

    df = pd.concat([df, df1], ignore_index=True)

if chrom_map_file != "none":
    for chrom in chrom_id_map_dict.keys():
        df.replace(chrom, chrom_id_map_dict[chrom], inplace=True)

df["CHROM"] = df["CHROM"].astype(int)
df["BIN_START"] = df["BIN_START"].astype(int)

df.sort_values(['CHROM', 'BIN_START'], ascending=[True, True], inplace=True)

if method == "tajimas_d":
    df["BIN_END"] = df["BIN_START"]+int(window_size)
    df["BIN_START"] = df["BIN_START"]+1
    col_name = "TajimaD"

if method == "fst_all":
    col_name = "MEAN_FST"

if method == "pi_val":
    col_name = "PI"

if method == "sweepfinder2":
    df["BIN_END"] = df["BIN_START"]+1
    col_name = "LR"

if method == "ihs":
    df["BIN_END"] = df["BIN_START"]+1
    col_name = "std_ihs"

f_df = df[["CHROM","BIN_START","BIN_END",col_name]]

f_df.replace(np.nan, 0, inplace=True)

if method == "fst":
    f_df[col_name] = f_df[col_name].apply(lambda x : x if x > 0 else 0)

merge_df = f_df.to_csv(outprefix+".out",sep=" ",header=True,index=False)


with open(outprefix+".cutoff","w") as dest:
    cutoff = 1-float(sel_threshold) if (method == "fst_all" or method == "sweepfinder2" or method == "ihs") else float(sel_threshold)
    dest.write("id"+","+"cutoff"+"\n")
    dest.write(pop+","+str(f_df[col_name].quantile(cutoff))+"\n")
