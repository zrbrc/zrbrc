USE [DMS_FORCES_PROD];
GO
-- Account Receivables by Payment/Program and Total dollar value of collections by program per month
-----------------------------------------------------------------------------------------------
       
		DECLARE @AsofDate DATE = CAST(GETDATE() -1 AS DATE);
		
		SELECT 'Report Running For BeginDate: ' ,Cast(@AsofDate  AS VARCHAR(30)) ;
	
		DECLARE @currentMonthStart DATE = 
				CASE
				WHEN @AsofDate > '2015-11-30' 
				THEN CONVERT(VARCHAR(25),DATEADD(dd,-(DAY(@AsofDate)-1),@AsofDate),101)
				ELSE '2015-11-12'
				END

		DECLARE @currentMonthEnd DATE = CONVERT(VARCHAR(25),DATEADD(dd,-(DAY(DATEADD(mm,1,@AsofDate))),DATEADD(mm,1,@AsofDate)),101), 
				@lastSavedTimestamp DATETIME  = getdate(), 
				@workloadID UNIQUEIDENTIFIER = null


       -- Some standard variables
       DECLARE
                @currentYear INT = DATEPART(year, @currentMonthStart), 
				@currentMonth INT = DATEPART(month, @currentMonthStart), 
				@legacyProgramID VARCHAR(128) = 'BAT_AR-ManageYTDClaimsAndPayments'

       SELECT 
              SUM (T.Payment_AMNT ),
              T.PaymentType_CODE,
              T.ReportCategory_CODE
              FROM 
              (
                    SELECT DISTINCT                   
						SUM(cp.Payment_AMNT) AS Payment_AMNT,
						CASE 
							WHEN cp.PaymentType_CODE = 'RC' AND cp.ReportCategory_CODE = '01' THEN 'RA' --TANF
                            WHEN cp.PaymentType_CODE = 'RC' AND cp.ReportCategory_CODE = '02' THEN 'RF' --Food Benefits
                            WHEN cp.PaymentType_CODE = 'RC' AND cp.ReportCategory_CODE = '06' THEN 'RG' --General Assistance
                            WHEN cp.PaymentType_CODE = 'RC' AND cp.ReportCategory_CODE = '09' THEN 'RX' --Refugee Cash Assistance    
                            ELSE cp.PaymentType_CODE         
						END AS PaymentType_CODE, 
						cp.ReportCategory_CODE
					FROM
						dbo.ClaimPayment_T cp
                    INNER JOIN
                        dbo.Transaction_T t 
					ON 
						cp.Transaction_IDNO = t.Transaction_IDNO
                    WHERE
                     (
                           t.Certification_NUMB IS NOT NULL
                           AND COALESCE(cp.PaymentReversal_INDC, '') IN ('N', '')
                           AND cp.PaymentDay_DATE >= @currentMonthStart
                           AND cp.PaymentDay_DATE <= @currentMonthEnd
                     )
                     OR
                     (
                           t.PaymentStatus_CODE <> 'RV'
                           AND COALESCE(cp.PaymentReversal_INDC, '') IN ('N', '')
                           AND cp.PaymentDay_DATE >= @currentMonthStart
                           AND cp.PaymentDay_DATE <= @currentMonthEnd
                           AND cp.history_code = '0' 
                           AND cp.history_code = '0' 
                     )
                     OR
                     (
                           t.PaymentStatus_CODE <> 'RV'
                           AND COALESCE(cp.PaymentReversal_INDC, '') IN ('N', '')
                           AND cp.PaymentDay_DATE >= @currentMonthStart
                           AND cp.PaymentDay_DATE <= @currentMonthEnd
                           AND cp.history_code = '9'
                           AND t.Certification_NUMB is not null
                           AND t.history_code  = '9'
                     )
                     OR
                     (
                           t.PaymentStatus_CODE = 'RV'
                           AND cp.LastSaved_DTTM >= @currentMonthStart
                           AND cp.LastSaved_DTTM <= @currentMonthEnd
                     )
              GROUP BY                   
                       cp.PaymentType_CODE, 
					   cp.ReportCategory_CODE
              
              UNION ALL

              SELECT DISTINCT                   
                     SUM(cp.Payment_AMNT) AS Payment_AMNT, 
					 CASE 
							WHEN cp.PaymentType_CODE = 'RC' AND cp.ReportCategory_CODE = '01' THEN 'RA' --TANF
                            WHEN cp.PaymentType_CODE = 'RC' AND cp.ReportCategory_CODE = '02' THEN 'RF' --Food Benefits
                            WHEN cp.PaymentType_CODE = 'RC' AND cp.ReportCategory_CODE = '06' THEN 'RG' --General Assistance
                            WHEN cp.PaymentType_CODE = 'RC' AND cp.ReportCategory_CODE = '09' THEN 'RX' --Refugee Cash Assistance    
                            ELSE cp.PaymentType_CODE         
                     END AS PaymentType_CODE, 
					 cp.ReportCategory_CODE
              FROM
                     dbo.ClaimPayment_T cp
              WHERE
                    (
                     cp.PaymentReversal_INDC =  'Y'
                     AND cp.LastSaved_DTTM >= @currentMonthStart
                     AND cp.LastSaved_DTTM <= @currentMonthEnd
                     )
                     AND CP.History_CODE = '0'
              GROUP BY                   
                       cp.PaymentType_CODE, 
					   cp.ReportCategory_CODE
              
              UNION ALL

              SELECT DISTINCT                   
                     SUM(cp.Payment_AMNT) AS Payment_AMNT, 
					 CASE 
							WHEN cp.PaymentType_CODE = 'RC' AND cp.ReportCategory_CODE = '01' THEN 'RA' --TANF
							WHEN cp.PaymentType_CODE = 'RC' AND cp.ReportCategory_CODE = '02' THEN 'RF' --Food Benefits
                            WHEN cp.PaymentType_CODE = 'RC' AND cp.ReportCategory_CODE = '06' THEN 'RG' --General Assistance
                            WHEN cp.PaymentType_CODE = 'RC' AND cp.ReportCategory_CODE = '09' THEN 'RX' --Refugee Cash Assistance    
                            ELSE cp.PaymentType_CODE         
                      END AS PaymentType_CODE, 
					  cp.ReportCategory_CODE
              FROM
                     dbo.ClaimPayment_T cp
              INNER JOIN
                     dbo.Transaction_T t 
			  ON 
					 cp.Transaction_IDNO = t.Transaction_IDNO
              WHERE
                     CP.PaymentReversal_INDC = 'Y'
                     AND cp.LastSaved_DTTM >= @currentMonthStart
                     AND cp.LastSaved_DTTM <= @currentMonthEnd
                     AND CP.History_CODE = '9'
                     AND t.Certification_NUMB IS NOT NULL
              GROUP BY                   
                     cp.PaymentType_CODE, 
					 cp.ReportCategory_CODE 
			)  AS T
              GROUP BY 
				     PaymentType_CODE, 
					 ReportCategory_CODE

 
