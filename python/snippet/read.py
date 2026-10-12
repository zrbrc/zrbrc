import pandas as pd
import sqlalchemy as sa
import pyodbc
import csv
import os

abspath = os.path.abspath(__file__)
dname = os.path.dirname(abspath)
os.chdir(dname)

conn = sa.create_engine('mssql+pyodbc://sa:HappyG0Lucky@192.168.1.5,1433/dates_db?driver=ODBC+Driver+17+for+SQL+Server')

csv_file = pd.read_csv('E:\Workspace\dev\python\snippet\scripts.csv',header=0)

for index, row in csv_file.iterrows():

    sql = (open(row['input'])).read()

    if pd.isna(row['output']) :
        pd.read_sql(sql,conn)
    else:
        pd.read_sql(sql,conn).to_csv(row['output'], index=False, quoting=csv.QUOTE_ALL)