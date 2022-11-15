set @partition_year:=2022;
 set @partition_month:=11;
set @env:=104;
set @table_name:='event';
set @tenantid:=802;
SET session group_concat_max_len=15000;
SET @row_number := 0;
select GROUP_CONCAT(body ORDER BY src ASC SEPARATOR ' ') from (
select "1" as src , CONCAT('copy into@PUBLIC.STAGE_AWS_S3_',@env,'_',@tenantid,'_ACTIONS/RECOVERY/',
        @table_name,'/',@table_name,'_unloaded.parquet from ( select \n') as body 
union all   
     SELECT 
    "2" as src , 
     GROUP_CONCAT(ib ORDER BY row_num asc SEPARATOR ',') as body 
     from 
     (
     select 
     CAST( (@row_number:=@row_number + 1) as SIGNED ) AS row_num, 
       CONCAT(CASE 
       	when lower(c.name) in ('birthdate') then '(DATE_PART( EPOCH_MICROSECOND,birthdate))' 
       	when lower(c.name) in ('datecreated') then '(DATE_PART( EPOCH_MICROSECOND,datecreated))' 
       	when lower(c.name) in ('datemodified') then '(DATE_PART( EPOCH_MICROSECOND,datemodified))' 
       	-- when lower(@table_name) <> 'zipdemographics' and lower(c.name) in ('rowcreated') then '(DATE_PART( EPOCH_MICROSECOND,rowcreated))' 
        when lower(c.name) in ('rowcreated') then '(DATE_PART( EPOCH_MICROSECOND,rowcreated))' 
       	when lower(c.name) in ('rowmodified') then '(DATE_PART( EPOCH_MICROSECOND,rowmodified))' 
       	when lower(c.name) in ('rowprocessed') then '(DATE_PART( EPOCH_MICROSECOND,rowprocessed))'	
		when lower(c.name) in ('emailoptindate') then '(DATE_PART( EPOCH_MICROSECOND,emailoptindate)) ' 	
		when lower(c.name) in ('emailoptoutdate') then '(DATE_PART( EPOCH_MICROSECOND,emailoptoutdate))'  
		when lower(c.name) in ('eventtimestamp') then '(DATE_PART( EPOCH_MICROSECOND,eventtimestamp))' 
       	when lower(c.name) in ('a1campaignexecutiontimestamp') then '(DATE_PART( EPOCH_MICROSECOND,a1campaignexecutiontimestamp))'
       	when lower(c.name) in ('transactiontimestamp') then '(DATE_PART( EPOCH_MICROSECOND,transactiontimestamp))'
       	when lower(c.name) in ('shipdate') then '(DATE_PART( EPOCH_MICROSECOND,shipdate))'
       	when lower(c.name) in ('invoicedate') then '(DATE_PART( EPOCH_MICROSECOND,invoicedate))'
       	when lower(c.name) in ('attributionstartdate') then '(DATE_PART( EPOCH_MICROSECOND,attributionstartdate))'
       	when lower(c.name) in ('startdatebigint') then '(DATE_PART( EPOCH_MICROSECOND,startdatebigint))'
       	when lower(c.name) in ('enddatebigint') then '(DATE_PART( EPOCH_MICROSECOND,enddatebigint))'
       	when lower(c.name) in ('starttimestamp') then '(DATE_PART( EPOCH_MICROSECOND,starttimestamp))'
       	when lower(c.name) in ('endtimestamp') then '(DATE_PART( EPOCH_MICROSECOND,endtimestamp))'
       	when lower(c.name) in ('expirytimestamp') then '(DATE_PART( EPOCH_MICROSECOND,expirytimestamp))'
       	when lower(c.name) in ('firstdispatchtimestamp') then '(DATE_PART( EPOCH_MICROSECOND,firstdispatchtimestamp))'
       	when lower(c.name) in ('lastdispatchtimestamp') then '(DATE_PART( EPOCH_MICROSECOND,lastdispatchtimestamp))'
       	else lower(c.name) 
       END ,
      ' :: ',
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
	JOIN (SELECT @row_number:=0) AS t
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
') FILE_FORMAT = (TYPE = PARQUET COMPRESSION = None) 
HEADER = true
OVERWRITE = true
SINGLE = TRUE ;' as body
 ) q  ;
