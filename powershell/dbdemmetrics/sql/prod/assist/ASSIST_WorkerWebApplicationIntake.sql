Use DSS_WorkerWeb_PROD;

DECLARE @BeginDate DATE = cast(getdate() -1 as date);
 
SELECT 'Report Running For @BeginDate: ' ,Cast(@BeginDate  AS VARCHAR(30)) ;

 SELECT COUNT(1) AS '[NUMBER OF RFA''s created]'  from RFA_T where 
   cast(FirstInserted_DTTM as date) = @BeginDate;


  select COUNT(1) AS '[NUMBER OF RFA''s initiated / Cases created ]' from Case_T
   where cast(FirstInserted_DTTM as date) = @BeginDate;

    --Cases with new programs added
  select COUNT(1) from  (select  distinct  c.Case_NUMB,a.Program_CODE    from ProgramDetail_T a inner join ApplicationEntity_T b on a.Requester_NUMB =b.ApplicationEntity_IDNO 
  inner join Case_T c on b.Application_IDNO=c.Application_IDNO
  where b.History_CODE='0' and b.DeleteReason_CODE  is null and a.History_CODE='0' and a.DeleteReason_CODE is null and a.Request_INDC =1 
   And cast(a.FirstInserted_DTTM as date) = @BeginDate  ) AS TEST ;




