show databases

create table sandbox.before_backup (
    id int
);

Insert into sandbox.before_backup values (1),(2),(3);
select * from  sandbox.before_backup

show binary logs
flush binary logs

create table sandbox.after_backup (
    id int
);

Insert into sandbox.after_backup values (4),(5),(6);
select * from sandbox.after_backup

show global variables like '%dir%';

-- mysqlbackup --datadir="C:\ProgramData\MySQL\MySQL Server 8.0\Data" --backup-dir="E:\mysql_backup\2023-02-22_13-30-12" --uncompress copy-back