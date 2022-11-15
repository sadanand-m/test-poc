
-- set @partition_year:=2022;
-- set @partition_month:=11;
set @env:=104;
set @table_name:='event';
set @tenantid:=802;
SET session group_concat_max_len=15000;
SET @row_number := 0;
select GROUP_CONCAT(body ORDER BY src ASC SEPARATOR '') from (
select "1" as src , CONCAT('copy into@PUBLIC.STAGE_AWS_S3_',@env,'_',@tenantid,'_ACTIONS/RECOVERY/',
        @table_name,'/',@table_name,'_unloaded.parquet from ( select \n') as body 
union all   
     SELECT 
    "2" as src , 
     GROUP_CONCAT(ib ORDER BY row_num asc SEPARATOR ',') as body 
     from 
     (
     select 
     (@row_number:=@row_number + 1) AS row_num , 
       CONCAT(CASE 
       	when lower(c.name) in ('birthdate') then '(DATE_PART( EPOCH_MICROSECOND,birthdate))' 
       	when lower(c.name) in ('datecreated') then '(DATE_PART( EPOCH_MICROSECOND,datecreated))' 
       	when lower(c.name) in ('datemodified') then '(DATE_PART( EPOCH_MICROSECOND,datemodified))' 
       	when lower(c.name) in ('rowcreated') then '(DATE_PART( EPOCH_MICROSECOND,rowcreated))' 
       	when lower(c.name) in ('rowmodified') then '(DATE_PART( EPOCH_MICROSECOND,rowmodified))' 
       	when lower(c.name) in ('rowprocessed') then '(DATE_PART( EPOCH_MICROSECOND,rowprocessed))'	
		when lower(c.name) in ('emailoptindate') then '(DATE_PART( EPOCH_MICROSECOND,emailoptindate)) ' 	
		when lower(c.name) in ('emailoptoutdate') then '(DATE_PART( EPOCH_MICROSECOND,emailoptoutdate))'  
       	else lower(c.name) 
       END ,
      '::',
        case 
        	 when c.type = 0 then 'INT'
        	 when c.type = 1 then 'BIGINT'
        	 when c.type = 2 then 'STRING'
        	 when c.type = 3 then 'DOUBLE'
        	 when c.type = 4 then 'BOOLEAN'
        	 when c.type = 5 then 'DECIMAL(18,4)'
        	   end , ' as ', lower(c.name)
        ) as ib 
FROM
	schema_column c
	join 
	schema_table m on 
	c.tableId = m.table_id
where 
	c.tenant_id IN (0, @tenantid)
	AND m.tenant_id IN (0, @tenantid)
    AND m.name = @table_name
    AND m.active  = 1
    ORDER BY	c.column_id ASC, c.tenant_id 
   )x   
union all 
select "3" as src,(case when @partition_year IS NOT NULL AND @partition_month IS NOT NULL then CONCAT(' FROM A1SF_DB_',@env,'_',@tenantid,'.public.',@table_name,
                    ' WHERE COALESCE(DELETEFLAG,FALSE ) <> TRUE  ',
                   'AND ROWCREATED LIKE ''',@partition_year,'%',@partition_month,'%\'')
         else CONCAT(' FROM A1SF_DB_',@env,'_',@tenantid,'.public.',@table_name, ' WHERE COALESCE(DELETEFLAG,FALSE ) <> TRUE ')
         end) as body
union all
select "4" as src,
' ) FILE_FORMAT = (TYPE = PARQUET COMPRESSION = None) 
HEADER = true
OVERWRITE = true
SINGLE = TRUE ;' as body
 ) q  ;
