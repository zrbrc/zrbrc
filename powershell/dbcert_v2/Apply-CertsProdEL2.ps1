# this is just a notes list, not meant to be run as a full script on any server, just 1 line for the server its on
throw 'copy and paste the Install-SqlCertificate.ps1 to the server noted and then run the line for that server'

# Assist SS/PSS  xx.xx.xx.xx  hostname10N1	
# .\Install-SqlCertificate.ps1 -Instances PR2022_1 -FriendlyName ss_pr_sql2022_n1

# Assist SS/PSS  xx.xx.xx.xx  hostname10N2	
# .\Install-SqlCertificate.ps1 -Instances PR2022_2 -FriendlyName ss_pr_sql2022_n2

# Assist  xx.xx.xx.xx  hostname1N1	
# .\Install-SqlCertificate.ps1 -Instances PR2022_3 -FriendlyName assist_pr_sql2022_n1

# Assist  xx.xx.xx.xx  hostname1N3	
# .\Install-SqlCertificate.ps1 -Instances PR2022_4 -FriendlyName assist_pr_sql2022_n3

# Assist  xx.xx.xx.xx  hostname1N5	
# .\Install-SqlCertificate.ps1 -Instances PR2022_5 -FriendlyName assist_pr_sql2022_n5

# Sailpoint/Cerberus  xx.xx.xx.xx  hostname3N1	
# .\Install-SqlCertificate.ps1 -Instances PR2019_30 -FriendlyName cerb_pr_sql2019_n1

# Sailpoint/Cerberus  xx.xx.xx.xx  hostname3N2	
# .\Install-SqlCertificate.ps1 -Instances PR2019_31 -FriendlyName cerb_pr_sql2019_n2

# Biztalk  xx.xx.xx.xx  hostname6N1	
# .\Install-SqlCertificate.ps1 -Instances PR2019_10 -FriendlyName bzt_pr_sql2019_n1

# Biztalk  xx.xx.xx.xx  hostname6N2	
# .\Install-SqlCertificate.ps1 -Instances PR2019_11 -FriendlyName bzt_pr_sql2019_n2

# Assist SSIS  xx.xx.xx.xx  hostEL2AP11	
# .\Install-SqlCertificate.ps1 -Instances IP2022_1 -FriendlyName ssis_pr_sql2022

# DICER/MCI  xx.xx.xx.xx  hostMCIDBC7N1	
# .\Install-SqlCertificate.ps1 -Instances PR2019_18 -FriendlyName dicer_pr_sql2019_n1

# DICER/MCI  xx.xx.xx.xx  hostMCIDBC7N2	
# .\Install-SqlCertificate.ps1 -Instances PR2019_19 -FriendlyName dicer_pr_sql2019_n2

# DICER/MCI  xx.xx.xx.xx  hostMCIDBC7N3	
# .\Install-SqlCertificate.ps1 -Instances PR2019_20 -FriendlyName dicer_pr_sql2019_n3


<# 
hostname8n1domain.com domain.comDC03-CA 02/10/2026 02/10/2028 NO       DUI_PR_SQL2019_N1_20260210     xx.xx.xx.xx
hostname8n2domain.com domain.comDC03-CA 02/10/2026 02/10/2028 NO       DUI_PR_SQL2019_N2_20260210     xx.xx.xx.xx
hostname8n3domain.com domain.comDC03-CA 02/10/2026 02/10/2028 NO       DUI_PR_SQL2019_N3_20260210     xx.xx.xx.xx
hostel2ap11domain.com  domain.comDC03-CA 02/10/2026 02/10/2028 NO       SSIS_PR_SQL2022_20260210       xx.xx.xx.xx
hostname6n1domain.com domain.comDC03-CA 02/10/2026 02/10/2028 NO       BZT_PR_SQL2019_N1_20260210     xx.xx.xx.xx
hostname6n2domain.com domain.comDC03-CA 02/10/2026 02/10/2028 NO       BZT_PR_SQL2019_N2_20260210     xx.xx.xx.xx
hostname10n1domain.com  domain.comDC03-CA 02/10/2026 02/10/2028 NO       SS_PR_SQL2022_N1_20260210      xx.xx.xx.xx
hostname10n2domain.com  domain.comDC03-CA 02/10/2026 02/10/2028 NO       SS_PR_SQL2022_N2_20260210      xx.xx.xx.xx
hostname3n1domain.com domain.comDC03-CA 02/10/2026 02/10/2028 NO       CERB_PR_SQL2019_N1_20260210    xx.xx.xx.xx
hostname3n2domain.com domain.comDC03-CA 02/10/2026 02/10/2028 NO       CERB_PR_SQL2019_N2_20260210    xx.xx.xx.xx
hostname1n1domain.com domain.comDC03-CA 02/10/2026 02/10/2028 NO       ASSIST_PR_SQL2022_N1_20260210  xx.xx.xx.xx
hostname1n3domain.com domain.comDC03-CA 02/10/2026 02/10/2028 NO       ASSIST_PR_SQL2022_N3_20260210  xx.xx.xx.xx
hostname1n5domain.com domain.comDC03-CA 02/10/2026 02/10/2028 NO       ASSIST_PR_SQL2022_N5_20260210  xx.xx.xx.xx
hostmcidbc7n1domain.comdomain.comDC03-CA 02/10/2026 02/10/2028 NO       DICER_PR_SQL2019_N1_20260210   xx.xx.xx.xx
hostmcidbc7n2domain.comdomain.comDC03-CA 02/10/2026 02/10/2028 NO       DICER_PR_SQL2019_N2_20260210   xx.xx.xx.xx
hostmcidbc7n3domain.comdomain.comDC03-CA 02/10/2026 02/10/2028 NO       DICER_PR_SQL2019_N3_20260210   xx.xx.xx.xx
#>