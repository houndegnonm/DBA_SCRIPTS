set session transaction isolation level read committed ; 
set @env := 'schema_source_name' ; 
set @target_db:= 'schema_backup_name' ;
set @time_suffix := date_format(now(),'%Y%m%d_%H%i') ; 
select concat('create table `',@target_db,'`.',table_name,'_', @time_suffix ,' like `',@env,'`.',table_name,
        ' ; insert into `',@target_db,'`.',table_name,'_', @time_suffix , ' select * from `',@env,'`.',table_name,' ;')
from information_schema.tables 
where table_schema = @env and 
table_name in (
'table1',
'table2');
