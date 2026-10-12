SELECT
	A.Division_CODE AS AppDivion,
	A.ApplicationName_TEXT AS AppName,
	A.Type_Code AS AppType,
	A.Active_INDC AS AppActive,
	WF.Environment_CODE AS Environment,
	WF.MigrationType_CODE As MigrationType,
	WF.Description_TEXT AS WorkflowGroup,
	WF.Sequence_NUMB AS WorkflowSequence,
	UD.ADLogin_TEXT AS Username,
	UD.Active_INDC AS UserEnabled,
	UD.UserDetail_IDNO,
	WFA.WorkflowApprover_IDNO,
	WF.Workflow_IDNO,
	A.Application_IDNO
FROM
	UserDetails_T1 AS UD
	JOIN WorkflowApprovers_T1 AS WFA ON WFA.UserDetail_IDNO =  UD.UserDetail_IDNO
	JOIN Workflows_T1 AS WF ON WF.Workflow_IDNO = WFA.Workflow_IDNO
	JOIN Applications_T1 AS A ON A.Application_IDNO = WF.Application_IDNO
ORDER BY
	A.ApplicationName_TEXT,
	WF.Environment_CODE,
	WF.MigrationType_CODE,
	WF.Description_TEXT,
	UD.ADLogin_TEXT