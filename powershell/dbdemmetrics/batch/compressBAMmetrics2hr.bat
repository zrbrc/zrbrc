@echo off
"C:\Program Files\7-Zip\7Z" D D:\Batch\SSIS_Executables\DSS\BAM_Metrics2hr_Prod.zip D:\Batch\SSIS_Executables\DSS\*.csv
"C:\Program Files\7-Zip\7Z" A D:\Batch\SSIS_Executables\DSS\BAM_Metrics2hr_Prod.zip D:\Batch\SSIS_Executables\DSS\*BAM*2hr*.csv
del d:\batch\ssis_executables\dss\*BAM*2hr*.csv