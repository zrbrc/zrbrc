
$csv = @"
Node,Hostname,Label
EL2_PROD_APP_01,hostel2ap01domain.com,xx.xx.xx.xx
EL2_PROD_APP_02,hostel2ap02domain.com,xx.xx.xx.xx
EL2_PROD_APP_03,hostel2ap03domain.com,xx.xx.xx.xx
EL2_PROD_BIZ_17,hostel2ap17domain.com,xx.xx.xx.xx
EL2_PROD_DB_CLS1N1,hostname1n1domain.com,xx.xx.xx.xx
EL2_PROD_DB_CLS1N3,hostname1n3domain.com,xx.xx.xx.xx
EL2_PROD_DEPLOY_01,hostel2ss01domain.com,xx.xx.xx.xx
EL2_PROD_SFTP_01,deptsftp01domain.com,xx.xx.xx.xx
EL2_PROD_WEB_01,hostel2wb01domain.com,xx.xx.xx.xx
EL2_PROD_WEB_02,hostel2wb02domain.com,xx.xx.xx.xx
EL2_PROD_WEB_03,hostel2wb03domain.com,xx.xx.xx.xx
IDMZ1_PROD_DECSS_WEB_01,hostdecsswb01,xx.xx.xx.xx
IDMZ1_PROD_DECSS_WEB_02,hostdecsswb02,xx.xx.xx.xx
IDMZ1_PROD_DEPT_WEB_01,hostfarmwb01,xx.xx.xx.xx
IDMZ2_PROD_DECSS_APP_03,hostdecssap03domain.com,xx.xx.xx.xx
IDMZ2_PROD_DECSS_APP_04,hostdecssap04domain.com,xx.xx.xx.xx
IDMZ2_PROD_DECSS_BAT_CLS1,hostdecssbat1domain.com,xx.xx.xx.xx
IDMZ2_PROD_DEPT_APP_02,hostfarmapp02domain.com,xx.xx.xx.xx
IDMZ2_PROD_FP_02,hostfp02domain.com,xx.xx.xx.xx
IDMZ2_PROD_SSIS_C1LS1,hostssisc1ag1domain.com,xx.xx.xx.xx
IDMZ3_PROD_DECSS_DB_CLS1LS1,hostdcssag1domain.com,xx.xx.xx.xx
MDMZ_PROD_UVMS_01,deptuvms01.domain.com,xx.xx.xx.xx
"@ | ConvertFrom-Csv

$csv | Write-SqlTableData -ServerInstance 'xx.xx.xx.xx,15150' -DatabaseName 'db_DollarUniverse_SBX' -SchemaName 'dbo' -TableName 'Nodes'