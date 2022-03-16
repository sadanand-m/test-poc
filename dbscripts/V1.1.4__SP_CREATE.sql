use database DEMO;
use schema DEMO.TEST;
create or replace procedure sp_test(DBASE STRING,SCHEMANAME STRING,TABLENAME STRING)
    returns ARRAY
    language javascript
    execute as caller
    as
    $${
        let response = [];
        function getErrorString(err){
            let result =  "Failed: Code: " + err.code + "\n  State: " + err.state;
            result += "\n  Message: " + err.message;
            result += "\nStack Trace:\n" + err.stackTraceTxt;
            return result;
        }
        function testfn(tableName){
            try {
                snowflake.execute ( {
                    sqlText: `desc table ${tableName}`
                });
                response.push(`Table described ${tableName}.`);
            }
            catch (err)  {
                throw `error: ${tableName}: ${getErrorString(err)}`;
            }
        }
        const tableName = `${DBASE}.${SCHEMANAME}.${TABLENAME}`;
        testfn(tableName);
        return response;
    }$$
;
