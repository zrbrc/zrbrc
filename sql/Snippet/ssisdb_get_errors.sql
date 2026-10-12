Use SSISDB
go
Select Distinct
    fold.[name] as Folder_name
    ,proj.[name] as Project_Name
    ,pack.[name] as Package_Name
    ,ops.[message_time]
    ,mess.[message_source_name]
    ,ops.[message]
    --,mess.[execution_path]        -- this is pretty long path if you are pasting into an email or Excel
From [internal].[projects] proj
    Join [internal].[packages] pack on proj.project_id = pack.project_id
    Join [internal].[folders] fold on fold.folder_id = proj.folder_id
    Join [internal].[executions] execs on 
        execs.folder_name = fold.[name] and
        execs.project_name = proj.[name] and 
        execs.package_name = pack.[name]
    Join [internal].[operation_messages] ops on execs.execution_id = ops.operation_id
    join [internal].[event_messages] mess on ops.[operation_id] = mess.[operation_id]
        and mess.event_message_id = ops.operation_message_id
        and    mess.package_name = pack.[name]
Where 1=1
    --and ops.message_type = 120          -- errors only
    and ops.message_type in (120,130)  -- errors and warnings
    and ops.message_time > getdate() - 1 -- adjust as necessary
