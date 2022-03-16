use database DEMO;
use schema DEMO.TEST;
call sp_test('DEMO', 'TEST','SP_PRO_TEST1');
drop procedure sp_test(string, string, string);
