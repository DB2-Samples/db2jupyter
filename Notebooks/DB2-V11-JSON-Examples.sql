--
-- Exploring the use of JSON functions in DB2  
-- Copyright (C) 2016 IBM George Baklarz
--

--
-- To execute this script, use the following syntax:
-- 1. Make sure you have issued DB2CMD or are in a command shell that supports DB2 commands.
-- 2. db2 -w- -tvf table-functions.sql >out.txt
-- 3. Results will be placed into the out.txt file
--

--
-- Make sure you have a copy of the SAMPLE database and can connect to it!
--

CONNECT TO SAMPLE;

-- Internal DB2 JSON Routines 
--
--
-- There are a number of routines are that are built-in to DB2 that are used to manipulate JSON
-- documents. These routines are not externalized in the documentation because they are used by the 
-- internal API's of DB2 for managing the MongoDB interface. For this reason, these routines are
-- not considered "supported" although they can be used at your own risk. Note that the internal
-- use of these routines by DB2 has very specific usage patterns, which means that it is possible
-- that you may generate a set of SQL that may not be handled properly. It is for this reason that
-- you assume any risk associated with using these routines.
--

--
-- DB2 JSON Functions 
--

--
-- There is one built-in DB2 JSON function and a number of other functions that must be registered within
-- DB2 before they can be used. The names of the functions and their purpose are described below.
-- 
-- - JSON_VAL - Extracts data from a JSON document into SQL data types
-- - JSON_TABLE - Returns a table of values for a document that has array types in it
-- - JSON_TYPE - Returns documents that have a field with a specific data type (like array, or date)
-- - JSON_LEN - Returns the count of elements in an array type inside a document
-- - BSON2JSON - Convert BSON formatted document into JSON strings
-- - JSON2BSON - Convert JSON strings into a BSON document format
-- - JSON_GET_POS_ARR_INDEX - Retrieve the index of a value within an array type in a document
-- - JSON_UPDATE - Update a particular field or document using set syntax
-- - BSON_VALIDATE - Checks to make sure that a BSON field in a BLOB object is in a correct format
-- 
--  Aside from the JSON_VAL function, all other functions in this list must be catalogued before first 
--  being used. The next set of SQL will catalog all of these functions for you.
--

--
-- Catalog all DB2 JSON Functions
--
CREATE OR REPLACE FUNCTION SYSTOOLS.JSON_TABLE(
  INJSON BLOB(16M), INELEM VARCHAR(2048), RETTYPE VARCHAR(100)) 
  RETURNS TABLE(TYPE INTEGER, VALUE VARCHAR(2048))
  LANGUAGE C
  PARAMETER STYLE SQL
  PARAMETER CCSID UNICODE
  NO SQL
  NOT FENCED
  DETERMINISTIC
  NO EXTERNAL ACTION
  DISALLOW PARALLEL
  SCRATCHPAD 2048
  EXTERNAL NAME 'db2json!jsonTable';

CREATE OR REPLACE FUNCTION SYSTOOLS.JSON_TYPE(
  INJSON BLOB(16M), INELEM VARCHAR(2048), MAXLENGTH INTEGER) 
  RETURNS INTEGER
  LANGUAGE C
  PARAMETER STYLE SQL
  PARAMETER CCSID UNICODE
  NO SQL
  NOT FENCED
  DETERMINISTIC
  ALLOW PARALLEL
  RETURNS NULL ON NULL INPUT
  NO EXTERNAL ACTION
  EXTERNAL NAME 'db2json!jsonType';

CREATE OR REPLACE FUNCTION SYSTOOLS.JSON_LEN(
  INJSON BLOB(16M), INELEM VARCHAR(2048)) 
  RETURNS INTEGER
  LANGUAGE C
  PARAMETER STYLE SQL
  PARAMETER CCSID UNICODE
  NO SQL
  NOT FENCED
  DETERMINISTIC
  ALLOW PARALLEL
  NO EXTERNAL ACTION
  SCRATCHPAD 2048
  EXTERNAL NAME 'db2json!jsonLen';

CREATE OR REPLACE FUNCTION SYSTOOLS.BSON2JSON(INBSON BLOB(16M)) RETURNS CLOB(16M)
  LANGUAGE C
  PARAMETER STYLE SQL
  PARAMETER CCSID UNICODE
  NO SQL
  NOT FENCED
  DETERMINISTIC
  ALLOW PARALLEL
  NO EXTERNAL ACTION
  SCRATCHPAD 2048
  EXTERNAL NAME 'db2json!jsonBsonToJson';

CREATE OR REPLACE FUNCTION SYSTOOLS.JSON2BSON(INJSON CLOB(16M)) RETURNS BLOB(16M)
  LANGUAGE C
  PARAMETER STYLE SQL
  PARAMETER CCSID UNICODE 
  NO SQL
  NOT FENCED
  DETERMINISTIC
  ALLOW PARALLEL
  NO EXTERNAL ACTION
  SCRATCHPAD 2048
  EXTERNAL NAME 'db2json!jsonToBson';

CREATE OR REPLACE FUNCTION SYSTOOLS.JSON_GET_POS_ARR_INDEX(
  INJSON BLOB(16M), QUERY VARCHAR(32672) FOR BIT DATA) 
  RETURNS INTEGER
  LANGUAGE C
  PARAMETER STYLE SQL
  PARAMETER CCSID UNICODE
  NO SQL
  NOT FENCED
  DETERMINISTIC
  ALLOW PARALLEL
  CALLED ON NULL INPUT
  NO EXTERNAL ACTION
  SCRATCHPAD 2048
  EXTERNAL NAME 'db2json!jsonGetPosArrIndex';

CREATE OR REPLACE FUNCTION SYSTOOLS.JSON_UPDATE(
  INJSON BLOB(16M), INELEM VARCHAR(32672)) 
  RETURNS BLOB(16M)
  LANGUAGE C
  PARAMETER STYLE SQL
  PARAMETER CCSID UNICODE
  NO SQL
  NOT FENCED
  DETERMINISTIC
  ALLOW PARALLEL
  CALLED ON NULL INPUT
  NO EXTERNAL ACTION
  SCRATCHPAD 2048
  EXTERNAL NAME 'db2json!jsonUpdate2';

CREATE OR REPLACE FUNCTION SYSTOOLS.BSON_VALIDATE(
  INJSON BLOB(16M)) 
  RETURNS INT
  LANGUAGE C
  PARAMETER STYLE SQL
  PARAMETER CCSID UNICODE
  NO SQL
  NOT FENCED
  DETERMINISTIC
  ALLOW PARALLEL
  RETURNS NULL ON NULL INPUT
  NO EXTERNAL ACTION
  EXTERNAL NAME 'db2json!jsonValidate'  ;

--
-- Path Statement Requirements 
--

--
-- All of the DB2 JSON functions have been placed into the SYSTOOLS schema. This means that in order to execute
-- any of these commands, you must prefix the command with SYSTOOLS, as in SYSTOOLS.JSON2BSON. In order to 
-- remove this requirement, you must update the CURRENT PATH value to include SYSTOOLS as part of it. The 
-- SQL below will tell you what the current PATH is.
--

VALUES CAST (CURRENT PATH AS VARCHAR(60));

-- 
-- If SYSTOOLS is not part of the path, you can update it with the following SQL.
-- 

SET CURRENT PATH = CURRENT PATH, SYSTOOLS;

--
-- From this point on you won't need to added the SYSTOOLS schema on the front of any of your SQL 
-- statements that refer to these DB2 JSON functions.
--

--
-- Programming with the JSON SQL Functions 
--

--
-- The functions that are listed below give you the ability to retrieve and manipulate JSON documents that
-- you store in a column within a table. What these functions do not do is let you explore the structure of a
-- JSON document. The assumption is that you are storing "known" JSON documents within the column and that
-- you have some knowledge of the underlying structure.
-- 
-- What this means is that none of the functions listed below will let you determine the fields that are
-- found within the document. You must already know what these fields and their structure (i.e. is it an array)
-- are and that you are either trying to extract some of these fields, or need to modify a field within the document. 
-- If you need to determine the structure of the JSON document, you are better off using the JAVA APIs that are available for 
-- manipulating these types of documents.
-- 
-- To store and retrieve an entire document from a column in a table, you would use:
-- 
-- - BSON2JSON - Convert BSON formatted document into JSON strings
-- - JSON2BSON - Convert JSON strings into a BSON document format
-- 
-- You can also verify the contents of a document that is stored in a column by using the BSON_VALIDATE function:
-- 
-- - BSON_VALIDATE - Checks to make sure that a BSON field in a BLOB object is in a correct format
-- 
-- BSON is the binary format use to store JSON documents in MongoDB and is also used by DB2. Documents are always stored
-- in BLOBS (binary objects) which can be as large as 16M. BLOBs can be defined to be INLINE, which will result in 
-- improved performance for any of these JSON functions. If you create a table with a BLOB column, try to use a size that
-- will fit within a DB2 page size. For instance, if you have a 32K page size for your data base, creating BLOB objects less 
-- than 32000 bytes in size will result in better performance:
--
-- CREATE TABLE JSON_EMP (
--   EMP_INFO BLOB(4000) INLINE LENGTH 4000
-- );
--
-- If a large object is not inlined, or greater than 32K in size, the resulting object will be placed into a 
-- large table space. The end result is that BLOB objects will not be kept in bufferpools (which means a direct read is 
-- required from disk for access to any BLOB object) and that two I/Os are required to get any document. One I/O is required
-- to get the base page, while the second is needed to get the BLOB object. By using the INLINE option and keeping the
-- BLOB size below the page size, we can avoid both of these performance overheads.
--    

--
-- Creating Tables that support JSON Documents 
--

--
-- To create a table that will store JSON data, you need to define the column so that is of 
-- a binary type. The JSON field must be created as a BLOB (at the time of writing, the use 
-- of the VARBINARY data type has not been verified) column. In order to ensure
-- good performance, you should have BLOB specified as INLINE if possible. 
-- 
-- Of course, if your JSON object is greater than 32K, there is no way it will be able to sit on a 
-- DB2 page, so you will need to use the large object format. However, if the object is significantly smaller than
-- 32K, you will end up getting better performance if it can remain on one DB2 page.
--

DROP TABLE TESTJSON;

CREATE TABLE TESTJSON
  (
  JSON_FIELD BLOB(4000) INLINE LENGTH 4000
  );
  
--  
-- JSON2BSON: Inserting a JSON Document   
--

-- Inserting into a column requires the use of the JSON2BSON function. The JSON2BSON function (and BSON2JSON) are used to transfer
-- data in and out of a traditional DB2 BLOB column. There is no native JSON data type in DB2. Input to the JSON2BSON
-- function must be a properly formatted JSON document. In the event that the document does not follow proper JSON
-- rules, you will get an error code from the function.
--

INSERT INTO TESTJSON VALUES
  ( JSON2BSON('{Name:"George"}'));
  
--
-- This is an example of a poorly formatted JSON document.
--

INSERT INTO TESTJSON VALUES
  ( JSON2BSON('{Name:, Age: 32}'));
  
--  
-- BSON2JSON: Retrieving a JSON Document 
--

--
-- Note that the data that is stored in a JSON column is in a special binary format called BSON. Selecting from the field will 
-- only result in random characters being displayed.
--

SELECT CAST(JSON_FIELD AS VARCHAR(60)) FROM TESTJSON;

--
-- If you want to extract the entire contents of a JSON field, you need to use the BSON2JSON function.
--

SELECT CAST(BSON2JSON(JSON_FIELD) AS VARCHAR(60)) FROM TESTJSON;

--
-- One thing that you should note is that the JSON that is retrieved has been modified slightly so that
-- all of the values have quotes around them to avoid any ambiguity. Note that we didn't necessarily require them
-- when we input the data. For instance, our original JSON document what was inserted looked like this:
--
-- {Name:"George"}
--
-- What gets returned is slightly different, but still considered to be the same JSON document. You must ensure that the
-- naming of any fields is consistent between documents. "Name", "name", and "Name" are all considered different fields. One
-- option is to use lowercase field names, or to use camel-case (first letter is capitalized) in all of your field definitions.
-- The important thing is to keep the naming consistent so you can find the fields in the document.
-- {"Name":"George"}
--

--
-- BSON_VALIDATE: Checking the format of a JSON document 
--

--
-- There is no validation done against the contents of a BLOB column which contains JSON data. 
-- As long as the JSON object is under program control and you are using the JSON functions,
-- you are probably not going to run across problems with the data. You should probably stick to either DB2 JSON
-- functions to access your JSON columns or the db2nosql (MongoDB syntax).
--
-- In the event you believe that a document is corrupted for some reason, you can use the BSON_VALIDATE to make sure it
-- is okay (or not!). The function will return a value of 1 if the record is okay, or a zero otherwise. The one row
-- that we have inserted into the TESTJSON table should be okay.
--

SELECT BSON_VALIDATE(JSON_FIELD) FROM TESTJSON;

--
-- The following SQL will inject a bad value into the beginning of the JSON field to test the results from the 
-- BSON_VALIDATE funtion.
--

UPDATE TESTJSON
  SET JSON_FIELD = BLOB('!') || JSON_FIELD;
  
SELECT BSON_VALIDATE(JSON_FIELD) FROM TESTJSON;

--
-- Manipulating JSON Documents 
--

--
-- The last section described how we can insert and retrieve entire JSON documents from a column in a table. This
-- section will explore a number of functions that allow access to individual fields within the JSON document. These
-- functions are:
-- 
-- - JSON_VAL - Extracts data from a JSON document into SQL data types
-- - JSON_TABLE - Returns a table of values for a document that has array types in it
-- - JSON_TYPE - Returns documents that have a field with a specific data type (like array, or date)
-- - JSON_LEN - Returns the count of elements in an array type inside a document
-- - JSON_GET_POS_ARR_INDEX - Retrieve the index of a value within an array type in a document
-- 
-- Our examples in this section will require a couple of tables to be created.
--

--
-- Sample JSON Table Creation 
--

--
-- The following SQL will load the JSON_EMP table with a number of JSON objects. These records are modelled 
-- around the SAMPLE database JSON_EMP table. 
--

DROP TABLE JSON_EMP;

CREATE TABLE JSON_EMP
  (
  SEQ INT NOT NULL GENERATED ALWAYS AS IDENTITY,
  EMP_DATA BLOB(4000) INLINE LENGTH 4000
  );

INSERT INTO JSON_EMP(EMP_DATA) VALUES JSON2BSON(
    '{
    "empno":"000010",
    "firstnme":"CHRISTINE",
    "midinit":"I",
    "lastname":"HAAS",
    "workdept":"A00",
    "phoneno":[3978],
    "hiredate":"01/01/1995",
    "job":"PRES",
    "edlevel":18,
    "sex":"F",
    "birthdate":"08/24/1963",
    "pay" : {
      "salary":152750.00,
      "bonus":1000.00,
      "comm":4220.00}
    }');
    
INSERT INTO JSON_EMP(EMP_DATA) VALUES JSON2BSON(
    '{
    "empno":"000020","firstnme":"MICHAEL","lastname":"THOMPSON",
    "workdept":"B01","phoneno":[3476,1422],"hiredate":"10/10/2003",
    "job":"MANAGER","edlevel":18,"sex":"M","birthdate":"02/02/1978",
    "pay": {"salary":94250.00,"bonus":800.00,"comm":3300.00}
    }'); 
INSERT INTO JSON_EMP(EMP_DATA) VALUES JSON2BSON(
    '{
    "empno":"000030","firstnme":"SALLY","midinit":"A","lastname":"KWAN",
    "workdept":"C01","phoneno":[4738],"hiredate":"04/05/2005",
    "job":"MANAGER","edlevel":20,"sex":"F","birthdate":"05/11/1971",
    "pay": {"salary":98250.00,"bonus":800.00,"comm":3060.00}
    }');
INSERT INTO JSON_EMP(EMP_DATA) VALUES JSON2BSON(
    '{
    "empno":"000050","firstnme":"JOHN","midinit":"B","lastname":"GEYER",
    "workdept":"E01","phoneno":[6789],"hiredate":"08/17/1979",
    "job":"MANAGER","edlevel":16,"sex":"M","birthdate":"09/15/1955",
    "pay": {"salary":80175.00,"bonus":800.00,"comm":3214.00}
    }'); 
INSERT INTO JSON_EMP(EMP_DATA) VALUES JSON2BSON(
    '{
    "empno":"000060","firstnme":"IRVING","lastname":"STERN",
    "workdept":"D11","phoneno":[6423,2433],"hiredate":"09/14/2003",
    "job":"MANAGER","edlevel":16,"sex":"M","birthdate":"07/07/1975",
    "pay": {"salary":72250.00,"bonus":500.00,"comm":2580.00}
    }');  
INSERT INTO JSON_EMP(EMP_DATA) VALUES JSON2BSON(
    '{
    "empno":"000070","firstnme":"EVA","midinit":"D","lastname":"PULASKI",
    "workdept":"D21","phoneno":[7831,1422,4567],"hiredate":"09/30/2005",
    "job":"MANAGER","edlevel":16,"sex":"F","birthdate":"05/26/2003",
    "pay": {"salary":96170.00,"bonus":700.00,"comm":2893.00}
    }'); 
INSERT INTO JSON_EMP(EMP_DATA) VALUES JSON2BSON(
    '{
    "empno":"000090","firstnme":"EILEEN","midinit":"W","lastname":"HENDERSON",
    "workdept":"E11","phoneno":[5498],"hiredate":"08/15/2000",
    "job":"MANAGER","edlevel":16,"sex":"F","birthdate":"05/15/1971",
    "pay": {"salary":89750.00,"bonus":600.00,"comm":2380.00}
    }');                             
INSERT INTO JSON_EMP(EMP_DATA) VALUES JSON2BSON(
    '{
    "empno":"000100","firstnme":"THEODORE","midinit":"Q","lastname":"SPENSER",
    "workdept":"E21","phoneno":[0972],"hiredate":"06/19/2000",
    "job":"MANAGER","edlevel":14,"sex":"M","birthdate":"12/18/1980",
    "pay": {"salary":86150.00,"bonus":500.00,"comm":2092.00}
    }');                             
INSERT INTO JSON_EMP(EMP_DATA) VALUES JSON2BSON(
    '{
    "empno":"000110","firstnme":"VINCENZO","midinit":"G","lastname":"LUCCHESSI",
    "workdept":"A00","phoneno":[3490,3567],"hiredate":"05/16/1988",
    "job":"SALESREP","edlevel":19,"sex":"M","birthdate":"11/05/1959",
    "pay": {"salary":66500.00,"bonus":900.00,"comm":3720.00}
    }');                          
INSERT INTO JSON_EMP(EMP_DATA) VALUES JSON2BSON(
    '{
    "empno":"000120","firstnme":"SEAN","midinit":"","lastname":"O''CONNELL",
    "workdept":"A00","phoneno":[2167,1533],"hiredate":"12/05/1993",
    "job":"CLERK","edlevel":14,"sex":"M","birthdate":"10/18/1972",
    "pay": {"salary":49250.00,"bonus":600.00,"comm":2340.00}
    }');                                  
INSERT INTO JSON_EMP(EMP_DATA) VALUES JSON2BSON(
    '{
    "empno":"000130","firstnme":"DELORES","midinit":"M","lastname":"QUINTANA",
    "workdept":"C01","phoneno":[4578],"hiredate":"07/28/2001",
    "job":"ANALYST","edlevel":16,"sex":"F","birthdate":"09/15/1955",
    "pay": {"salary":73800.00,"bonus":500.00,"comm":1904.00}
    }');                             
INSERT INTO JSON_EMP(EMP_DATA) VALUES JSON2BSON(
    '{
    "empno":"000140","firstnme":"HEATHER","midinit":"A","lastname":"NICHOLLS",
    "workdept":"C01","phoneno":[1793],"hiredate":"12/15/2006",
    "job":"ANALYST","edlevel":18,"sex":"F","birthdate":"01/19/1976",
    "pay": {"salary":68420.00,"bonus":600.00,"comm":2274.00}
    }');                             
INSERT INTO JSON_EMP(EMP_DATA) VALUES JSON2BSON(
     '{
     "empno":"000150","firstnme":"BRUCE","midinit":"","lastname":"ADAMSON",
     "workdept":"D11","phoneno":[4510],"hiredate":"02/12/2002",
     "job":"DESIGNER","edlevel":16,"sex":"M","birthdate":"05/17/1977",
     "pay": {"salary":55280.00,"bonus":500.00,"comm":2022.00}
     }');                                
INSERT INTO JSON_EMP(EMP_DATA) VALUES JSON2BSON(
    '{
    "empno":"000160","firstnme":"ELIZABETH","midinit":"R","lastname":"PIANKA", 
    "workdept":"D11","phoneno":[3782,9322],"hiredate":"10/11/2006",
    "job":"DESIGNER","edlevel":17,"sex":"F","birthdate":"04/12/1980",
    "pay": {"salary":62250.00,"bonus":400.00,"comm":1780.00}
    }');                            
INSERT INTO JSON_EMP(EMP_DATA) VALUES JSON2BSON(
    '{
    "empno":"000170","firstnme":"MASATOSHI","midinit":"J","lastname":"YOSHIMURA",
    "workdept":"D11","phoneno":[2890],"hiredate":"09/15/1999",
    "job":"DESIGNER","edlevel":16,"sex":"M","birthdate":"01/05/1981",
    "pay": {"salary":44680.00,"bonus":500.00,"comm":1974.00}
    }');                         
INSERT INTO JSON_EMP(EMP_DATA) VALUES JSON2BSON(
    '{
    "empno":"000180","firstnme":"MARILYN","midinit":"S","lastname":"SCOUTTEN",
    "workdept":"D11","phoneno":[1682,9945],"hiredate":"07/07/2003",
    "job":"DESIGNER","edlevel":17,"sex":"F","birthdate":"02/21/1979",
    "pay": {"salary":51340.00,"bonus":500.00,"comm":1707.00}
    }');                            
INSERT INTO JSON_EMP(EMP_DATA) VALUES JSON2BSON(
    '{
    "empno":"000190","firstnme":"JAMES","midinit":"H","lastname":"WALKER",
    "workdept":"D11","phoneno":[2986,3644],"hiredate":"07/26/2004",
    "job":"DESIGNER","edlevel":16,"sex":"M","birthdate":"06/25/1982",
    "pay": {"salary":50450.00,"bonus":400.00,"comm":1636.00}
    }');                                
INSERT INTO JSON_EMP(EMP_DATA) VALUES JSON2BSON(
    '{
    "empno":"000200","firstnme":"DAVID","midinit":"","lastname":"BROWN",
    "workdept":"D11","phoneno":[4501,2522],"hiredate":"03/03/2002",
    "job":"DESIGNER","edlevel":16,"sex":"M","birthdate":"05/29/1971",
    "pay": {"salary":57740.00,"bonus":600.00,"comm":2217.00}
    }');                                  
INSERT INTO JSON_EMP(EMP_DATA) VALUES JSON2BSON(
    '{
    "empno":"000210","firstnme":"WILLIAM","midinit":"T","lastname":"JONES",
    "workdept":"","phoneno":[0942],"hiredate":"04/11/1998",
    "job":"DESIGNER","edlevel":17,"sex":"M","birthdate":"02/23/2003",
    "pay": {"salary":68270.00,"bonus":400.00,"comm":1462.00}
    }');                               
INSERT INTO JSON_EMP(EMP_DATA) VALUES JSON2BSON(
    '{
    "empno":"000220","firstnme":"JENNIFER","midinit":"K","lastname":"LUTZ",
    "workdept":"D11","phoneno":[0672],"hiredate":"08/29/1998",
    "job":"DESIGNER","edlevel":18,"sex":"F","birthdate":"03/19/1978",
    "pay": {"salary":49840.00,"bonus":600.00,"comm":2387.00}
    }');                               
INSERT INTO JSON_EMP(EMP_DATA) VALUES JSON2BSON(
    '{
    "empno":"000230","firstnme":"JAMES","midinit":"J","lastname":"JEFFERSON",
    "workdept":"D21","phoneno":[2094,8999,3756],"hiredate":"11/21/1996",
    "job":"CLERK","edlevel":14,"sex":"M","birthdate":"05/30/1980",
    "pay": {"salary":42180.00,"bonus":400.00,"comm":1774.00}
    }');                                
INSERT INTO JSON_EMP(EMP_DATA) VALUES JSON2BSON(
    '{
    "empno":"000240","firstnme":"SALVATORE","midinit":"M","lastname":"MARINO",
    "workdept":"D21","phoneno":[3780],"hiredate":"12/05/2004",
    "job":"CLERK","edlevel":17,"sex":"M","birthdate":"03/31/2002",
    "pay": {"salary":48760.00,"bonus":600.00,"comm":2301.00}
    }');                               
INSERT INTO JSON_EMP(EMP_DATA) VALUES JSON2BSON(
    '{
    "empno":"000250","firstnme":"DANIEL","midinit":"S","lastname":"SMITH",
    "workdept":"D21","phoneno":[0961],"hiredate":"10/30/1999",
    "job":"CLERK","edlevel":15,"sex":"M","birthdate":"11/12/1969",
    "pay": {"salary":49180.00,"bonus":400.00,"comm":1534.00}
    }');                                   
INSERT INTO JSON_EMP(EMP_DATA) VALUES JSON2BSON(
    '{
    "empno":"000260","firstnme":"SYBIL","midinit":"P","lastname":"JOHNSON",
    "workdept":"D21","phoneno":[8953,2533],"hiredate":"09/11/2005",
    "job":"CLERK","edlevel":16,"sex":"F","birthdate":"10/05/1976",
    "pay": {"salary":47250.00,"bonus":300.00,"comm":1380.00}
    }');                                  
INSERT INTO JSON_EMP(EMP_DATA) VALUES JSON2BSON(
    '{
    "empno":"000270","firstnme":"MARIA","midinit":"L","lastname":"PEREZ",
    "workdept":"D21","phoneno":[9001],"hiredate":"09/30/2006",
    "job":"CLERK","edlevel":15,"sex":"F","birthdate":"05/26/2003",
    "pay": {"salary":37380.00,"bonus":500.00,"comm":2190.00}
    }');                                    
INSERT INTO JSON_EMP(EMP_DATA) VALUES JSON2BSON(
    '{
    "empno":"000280","firstnme":"ETHEL","midinit":"R","lastname":"SCHNEIDER",
    "workdept":"E11","phoneno":[8997,1422],"hiredate":"03/24/1997",
    "job":"OPERATOR","edlevel":17,"sex":"F","birthdate":"03/28/1976",
    "pay": {"salary":36250.00,"bonus":500.00,"comm":2100.00}
    }');                             
INSERT INTO JSON_EMP(EMP_DATA) VALUES JSON2BSON(
    '{
    "empno":"000290","firstnme":"JOHN","midinit":"R","lastname":"PARKER",
    "workdept":"E11","phoneno":[4502],"hiredate":"05/30/2006",
    "job":"OPERATOR","edlevel":12,"sex":"M","birthdate":"07/09/1985",
    "pay": {"salary":35340.00,"bonus":300.00,"comm":1227.00}
    }');                                 
INSERT INTO JSON_EMP(EMP_DATA) VALUES JSON2BSON(
    '{
    "empno":"000300","firstnme":"PHILIP","midinit":"X","lastname":"SMITH",
    "workdept":"E11","phoneno":[2095],"hiredate":"06/19/2002",
    "job":"OPERATOR","edlevel":14,"sex":"M","birthdate":"10/27/1976",
    "pay": {"salary":37750.00,"bonus":400.00,"comm":1420.00}
    }');                                
INSERT INTO JSON_EMP(EMP_DATA) VALUES JSON2BSON(
    '{
    "empno":"000310","firstnme":"MAUDE","midinit":"F","lastname":"SETRIGHT",
    "workdept":"E11","phoneno":[3332,8005],"hiredate":"09/12/1994",
    "job":"OPERATOR","edlevel":12,"sex":"F","birthdate":"04/21/1961",
    "pay": {"salary":35900.00,"bonus":300.00,"comm":1272.00}
    }');                              
INSERT INTO JSON_EMP(EMP_DATA) VALUES JSON2BSON(
    '{
    "empno":"000320","firstnme":"RAMLAL","midinit":"V","lastname":"MEHTA",
    "workdept":"E21","phoneno":[9990,1533],"hiredate":"07/07/1995",
    "job":"FIELDREP","edlevel":16,"sex":"M","birthdate":"08/11/1962",
    "pay": {"salary":39950.00,"bonus":400.00,"comm":1596.00}
    }');                                
INSERT INTO JSON_EMP(EMP_DATA) VALUES JSON2BSON(
    '{
    "empno":"000330","firstnme":"WING","midinit":"","lastname":"LEE",
    "workdept":"E21","phoneno":[2103,2453],"hiredate":"02/23/2006",
    "job":"FIELDREP","edlevel":14,"sex":"M","birthdate":"07/18/1971",
    "pay": {"salary":45370.00,"bonus":500.00,"comm":2030.00}
    }');                                     
INSERT INTO JSON_EMP(EMP_DATA) VALUES JSON2BSON(
    '{
    "empno":"000340","firstnme":"JASON","midinit":"R","lastname":"GOUNOT",
    "workdept":"E21","phoneno":[5698,7744],"hiredate":"05/05/1977",
    "job":"FIELDREP","edlevel":16,"sex":"M","birthdate":"05/17/1956",
    "pay": {"salary":43840.00,"bonus":500.00,"comm":1907.00}
    }');                                
INSERT INTO JSON_EMP(EMP_DATA) VALUES JSON2BSON(
    '{
    "empno":"200010","firstnme":"DIAN","midinit":"J","lastname":"HEMMINGER",
    "workdept":"A00","phoneno":[3978,2564],"hiredate":"01/01/1995",
    "job":"SALESREP","edlevel":18,"sex":"F","birthdate":"08/14/1973",
    "pay": {"salary":46500.00,"bonus":1000.00,"comm":4220.00}
    }');                             
INSERT INTO JSON_EMP(EMP_DATA) VALUES JSON2BSON(
    '{
    "empno":"200120","firstnme":"GREG","midinit":"","lastname":"ORLANDO",
    "workdept":"A00","phoneno":[2167,1690],"hiredate":"05/05/2002",
    "job":"CLERK","edlevel":14,"sex":"M","birthdate":"10/18/1972",
    "pay": {"salary":39250.00,"bonus":600.00,"comm":2340.00}
    }');                                    
INSERT INTO JSON_EMP(EMP_DATA) VALUES JSON2BSON(
    '{
    "empno":"200140","firstnme":"KIM","midinit":"N","lastname":"NATZ",
    "workdept":"C01","phoneno":[1793],"hiredate":"12/15/2006",
    "job":"ANALYST","edlevel":18,"sex":"F","birthdate":"01/19/1976",
    "pay": {"salary":68420.00,"bonus":600.00,"comm":2274.00}
    }');                                     
INSERT INTO JSON_EMP(EMP_DATA) VALUES JSON2BSON(
    '{
    "empno":"200170","firstnme":"KIYOSHI","midinit":"","lastname":"YAMAMOTO",
    "workdept":"D11","phoneno":[2890],"hiredate":"09/15/2005",
    "job":"DESIGNER","edlevel":16,"sex":"M","birthdate":"01/05/1981",
    "pay": {"salary":64680.00,"bonus":500.00,"comm":1974.00}
    }');                             
INSERT INTO JSON_EMP(EMP_DATA) VALUES JSON2BSON(
    '{
    "empno":"200220","firstnme":"REBA","midinit":"K","lastname":"JOHN",
    "workdept":"D11","phoneno":[0672],"hiredate":"08/29/2005",
    "job":"DESIGNER","edlevel":18,"sex":"F","birthdate":"03/19/1978",
    "pay": {"salary":69840.00,"bonus":600.00,"comm":2387.00}
    }');                                   
INSERT INTO JSON_EMP(EMP_DATA) VALUES JSON2BSON(
    '{
    "empno":"200240","firstnme":"ROBERT","midinit":"M","lastname":"MONTEVERDE",
    "workdept":"D21","phoneno":[3780,6823],"hiredate":"12/05/2004",
    "job":"CLERK","edlevel":17,"sex":"M","birthdate":"03/31/1984",
    "pay": {"salary":37760.00,"bonus":600.00,"comm":2301.00}
    }');                              
INSERT INTO JSON_EMP(EMP_DATA) VALUES JSON2BSON(
    '{
    "empno":"200280","firstnme":"EILEEN","midinit":"R","lastname":"SCHWARTZ",
    "workdept":"E11","phoneno":[8997,9410],"hiredate":"03/24/1997",
    "job":"OPERATOR","edlevel":17,"sex":"F","birthdate":"03/28/1966",
    "pay": {"salary":46250.00,"bonus":500.00,"comm":2100.00}
    }');                             
INSERT INTO JSON_EMP(EMP_DATA) VALUES JSON2BSON(
    '{
    "empno":"200310","firstnme":"MICHELLE","midinit":"F","lastname":"SPRINGER",
    "workdept":"E11","phoneno":[3332,7889],"hiredate":"09/12/1994",
    "job":"OPERATOR","edlevel":12,"sex":"F","birthdate":"04/21/1961",
    "pay": {"salary":35900.00,"bonus":300.00,"comm":1272.00}
    }');                           
INSERT INTO JSON_EMP(EMP_DATA) VALUES JSON2BSON(
    '{
    "empno":"200330","firstnme":"HELENA","midinit":"","lastname":"WONG",
    "workdept":"E21","phoneno":[2103],"hiredate":"02/23/2006",
    "job":"FIELDREP","edlevel":14,"sex":"F","birthdate":"07/18/1971",
    "pay": {"salary":35370.00,"bonus":500.00,"comm":2030.00}
    }');                                  
INSERT INTO JSON_EMP(EMP_DATA) VALUES JSON2BSON(
    '{
    "empno":"200340","firstnme":"ROY","midinit":"R","lastname":"ALONZO",
    "workdept":"E21","phoneno":[5698,1533],"hiredate":"07/05/1997",
    "job":"FIELDREP","edlevel":16,"sex":"M","birthdate":"05/17/1956",
    "pay": {"salary":31840.00,"bonus":500.00,"comm":1907.00}
    }');
--
-- We can check the count of records to make sure that 42 employees were added to our table.
--

SELECT COUNT(*) FROM JSON_EMP;

--
-- Additional DEPARTMENT Table 
-- 

--
-- In addition to the JSON_EMP table, the following SQL will generate a traditional table called JSON_DEPT
-- that can be used to determine the name of the department an individual works in.
--

DROP TABLE JSON_DEPT;
 
CREATE TABLE JSON_DEPT
  (
  SEQ INT NOT NULL GENERATED ALWAYS AS IDENTITY,
  DEPT_DATA BLOB(4000) INLINE LENGTH 4000 
  );

INSERT INTO JSON_DEPT(DEPT_DATA) VALUES
  JSON2BSON('{"deptno":"A00", "mgrno":"000010", "admrdept":"A00", "deptname":"SPIFFY COMPUTER SERVICE DIV."}'),
  JSON2BSON('{"deptno":"B01", "mgrno":"000020", "admrdept":"A00", "deptname":"PLANNING"                    }'),
  JSON2BSON('{"deptno":"C01", "mgrno":"000030", "admrdept":"A00", "deptname":"INFORMATION CENTER"          }'),
  JSON2BSON('{"deptno":"D01",                   "admrdept":"A00", "deptname":"DEVELOPMENT CENTER"          }'),
  JSON2BSON('{"deptno":"D11", "mgrno":"000060", "admrdept":"D01", "deptname":"MANUFACTURING SYSTEMS"       }'),
  JSON2BSON('{"deptno":"D21", "mgrno":"000070", "admrdept":"D01", "deptname":"ADMINISTRATION SYSTEMS"      }'),
  JSON2BSON('{"deptno":"E01", "mgrno":"000050", "admrdept":"A00", "deptname":"SUPPORT SERVICES"            }'),
  JSON2BSON('{"deptno":"E11", "mgrno":"000090", "admrdept":"E01", "deptname":"OPERATIONS"                  }'),
  JSON2BSON('{"deptno":"E21", "mgrno":"000100", "admrdept":"E01", "deptname":"SOFTWARE SUPPORT"            }'),
  JSON2BSON('{"deptno":"F22",                   "admrdept":"E01", "deptname":"BRANCH OFFICE F2"            }'),
  JSON2BSON('{"deptno":"G22",                   "admrdept":"E01", "deptname":"BRANCH OFFICE G2"            }'),
  JSON2BSON('{"deptno":"H22",                   "admrdept":"E01", "deptname":"BRANCH OFFICE H2"            }'),
  JSON2BSON('{"deptno":"I22",                   "admrdept":"E01", "deptname":"BRANCH OFFICE I2"            }'),
  JSON2BSON('{"deptno":"J22",                   "admrdept":"E01", "deptname":"BRANCH OFFICE J2"            }');
    
--
-- Retrieving Data from a BSON Document
--

--
-- Now that we have inserted some JSON data into a table, this section will explore 
-- the use of the JSON_VAL function to retrieve individual fields from the documents. 
-- This built-in function will return a value from a document in a format that you specify. 
-- The ability to dynamically change the returned data type is extremely important when we 
-- examine index creation in another section.
--
-- The JSON_VAL function has the format:
--
-- JSON_VAL(document, field, type);
--
-- JSON_VAL takes 3 arguments:
-- • document – BSON document
-- • field – The field we are looking for (search path)
-- • type – The return type of data being returned
-- The search path and type must be constants – they cannot be variables so their 
-- use in user-defined functions is limited to using constants.

--
-- A typical JSON record will contain a variety of data types and structures as 
-- illustrated by the following record from the JSON_EMP table.
--
--   {
--     "empno":"200170",
--     "firstnme":"KIYOSHI",
--     "midinit":"",
--     "lastname":"YAMAMOTO",
--     "workdept":"D11",
--     "phoneno":[2890],
--     "hiredate":"09/15/2005",
--     "job":"DESIGNER",
--     "edlevel":16,
--     "sex":"M",
--     "birthdate":"01/05/1981",
--     "pay": {
--       "salary":64680.00,
--       "bonus":500.00,
--       "comm":1974.00
--     }
--   }         
--
-- There are number of fields with different formats, including strings (firstnme), 
-- integers (edlevel), decimal (salary), date (hiredate), a number array (phoneno), 
-- and a structure (pay). JSON data can consist of nested objects, arrays and very 
-- complex structures. The format of a JSON object is checked when using the JSON2BSON 
-- function and an error message will be issued if it does not conform to the 
-- JSON specification.
--
-- The JSON_VAL function needs to know how to return the data type back from the JSON 
-- record, so you need to specify what the format should be. The possible formats are:
--  
-- Code	Format
-- n 	DECFLOAT
-- i 	INTEGER
-- I 	BIGINT (notice this is a lowercase L)
-- f 	DOUBLE
-- d 	DATE
-- ts 	TIMESTAMP (6)
-- t 	TIME
-- s:n 	A VARCHAR with a size of n being the maximum
-- b:n 	A BINARY value with n being the maximum
-- u 	An integer with a value of 0 or 1.
--

--
-- Retrieving Atomic Values
--

--
-- This first example will retrieve the name and salary of the employee whose employee 
-- number is "200170"
--

SELECT JSON_VAL(EMP_DATA,'lastname','s:20'), 
       JSON_VAL(EMP_DATA,'pay.salary','f')
  FROM JSON_EMP
WHERE
  JSON_VAL(EMP_DATA,'empno','s:6') = '200170';

--
-- If the size of the field being returned is larger that the field specification, 
-- you will get a NULL value returned, not a truncated value. 
--

SELECT JSON_VAL(EMP_DATA,'lastname','s:7')
  FROM JSON_EMP
WHERE
  JSON_VAL(EMP_DATA,'empno','s:6') = '200170';

--
-- In the case of character fields, you may need to specify a larger return 
-- size and then truncate it to get a subset of the data.
--

SELECT LEFT(JSON_VAL(EMP_DATA,'lastname','s:20'),7)
  FROM JSON_EMP
WHERE
  JSON_VAL(EMP_DATA,'empno','s:6') = '200170';

--
-- Retrieving Array Values
--

--
-- Selecting data from an array type will always give you the first value (element zero). 
-- The employees all have extension numbers but some of them have more than one. 
-- Some of the extensions start with a zero so since the column is being treated as an 
-- integer you will get only 3 digits. It's probably better to define it as a character 
-- string rather than a number!
--

SELECT JSON_VAL(EMP_DATA, 'phoneno', 'i') FROM JSON_EMP;
 
--
-- If you specify ":na" after the type specifier, you will get an error if the field 
-- is an array type. Hopefully you already know the format of your JSON data and can 
-- avoid having to check to see if arrays exist. What this statement will tell you is 
-- that one of the records you were attempting to retrieve was an array type. In fact, 
-- all the phone extensions are being treated as array types even though they have only 
-- one value in many cases.
--

SELECT JSON_VAL(EMP_DATA, 'phoneno', 'i:na') FROM JSON_EMP;

--
-- If you need to access a specific array element in a field, you can use the "dot" 
-- notation after the field name. The first element starts at zero. If we select 
-- the 2nd element (.1) all the employees that have a second extension will have a 
-- value retrieved while the ones who don't will have a null value.
--

--
-- Retrieving Structured Fields
--

--
-- Structured fields are retrieved using the same dot notation as arrays. 
-- The field is specified by using the "field.subfield" format and these fields can be 
-- an arbitrary number of levels deep. 
--
-- The pay field in the employee record is made up of three additional fields.
--
-- 
-- "pay": {
--    "salary":64680.00,
--    "bonus":500.00,
--    "comm":1974.00
-- }
--
-- To retrieve these three fields, you need to explictly name them since 
-- retrieving pay alone will not work.
--

SELECT JSON_VAL(EMP_DATA,'pay.salary','i'),
       JSON_VAL(EMP_DATA,'pay.bonus','i'),
       JSON_VAL(EMP_DATA,'pay.comm','i')
  FROM JSON_EMP
WHERE
  JSON_VAL(EMP_DATA,'empno','s:6') = '200170';

--
-- If you attempt to retrieve the pay field, you will end up with a NULL value, not 
-- an error code. The reason for this is that the JSON_VAL function cannot format the 
-- field into an atomic value so it returns the NULL value instead.
--
--
-- Determining NULL Values in a Field
--

--
-- To determine whether a field exists, or has a null value, you need use the "u" flag.  
-- If you use the "u" flag, the value returned will be either:
-- • 1 – The field exists, and it has a value (not null or empty string)
-- • 0 – The field exists, but the value is null or empty
-- • null – The field does not exist
--
-- In the JSON_EMP table, there are a few employees who do not have middle names. 
-- The following query will return a value or 1, 0, or NULL depending on whether the 
-- middle name exists for a record.

SELECT JSON_VAL(EMP_DATA,'lastname','s:30'),
       JSON_VAL(EMP_DATA,'midinit','u')
FROM JSON_EMP;

--
-- The results contain 40 employees who have a middle initial, and two that do not. 
-- The results can be misleading because an employee can have the midinit field defined, 
-- but no value assigned to it:
--
-- {
--  "empno":"000120",
--  "firstnme":"SEAN",
--  "midinit":"",
--  "lastname":"O''CONNELL",...
-- }        
-- 
-- In this case, the employee does not have a middle name, but the field is present. 
-- To determine whether an employee does not have a middle name, you will need to check 
-- for a NULL value (the field does not exist, or the field is empty) when 
-- retrieving the middle initial (9 rows):
--

SELECT COUNT(*) FROM JSON_EMP
  WHERE JSON_VAL(EMP_DATA,'midinit','s:40') IS NULL;

--
-- If you only want to know how many employee have the middle initial field (midinit) 
-- that is empty, you need to exclude the records that do not contain the field (7 rows):

SELECT COUNT(*) FROM JSON_EMP
  WHERE JSON_VAL(EMP_DATA,'midinit','s:40') IS NULL AND
        JSON_VAL(EMP_DATA,'midinit','u') IS NOT NULL;

--
-- Joining JSON Tables
--

--
-- You can join tables with JSON columns by using the JSON_VAL function 
-- to compare two values:
--

SELECT JSON_VAL(EMP_DATA,'empno','s:6') AS EMPNO, 
       JSON_VAL(EMP_DATA,'lastname','s:20') AS LASTNAME,
       JSON_VAL(DEPT_DATA,'deptname','s:30') AS DEPTNAME
  FROM JSON_EMP, JSON_DEPT
WHERE
  JSON_VAL(DEPT_DATA,'deptno','s:3') = 
  JSON_VAL(EMP_DATA,'workdept','s:3')
FETCH FIRST 5 ROWS ONLY;  

--
-- You need to ensure that the data types from both JSON functions are compatible for 
-- the join to work properly. In this case, the department number and the work department 
-- are both returned as 3-byte character strings. If you decided to use integers 
-- instead or a smaller string size, the join will not work as expected because 
-- the conversion will result in truncated or NULL values.
--
-- If you plan on doing joins between JSON objects, you may want to consider creating 
-- indexes on the documents to speed up the join process. More information on the use 
-- of indexes is found at the end of this chapter.
--

--
-- JSON Data Types
--

--
-- If you are unsure of what data type a field contains, you can use the the JSON_TYPE 
-- function to determine the type before retrieving the field.
--
-- The JSON_TYPE function has the format:
--
-- ID = JSON_TYPE(document, field, 2048);
-- 
-- JSON_TYPE takes 3 arguments:
-- • document – BSON document
-- • field – The field we are looking for (search path)
-- • search path size – 2048 is the required value
--
-- The 2048 specifies the maximum length of the field parameter and should be 
-- left at this value.
--
-- When querying the data types within a JSON document, the following values are returned.
-- 
-- ID  	TYPE                 	ID  	TYPE
--  1  	Double               	10  	Null      
--  2  	String               	11  	Regular Expression
--  3  	Object               	12  	Future use
--  4  	Array                	13  	JavaScript
--  5  	Binary data          	14  	Symbol
--  6  	Undefined            	15  	Javascript (with scope)
--  7  	Object id            	16  	32-bit integer
--  8  	Boolean              	17  	Timestamp 
--  9  	Date                 	18  	64-bit integer
-- 
-- The next SQL statement will create a table with standard types within it.
-- 

DROP TABLE TYPES;

CREATE TABLE TYPES
  (DATA BLOB(4000) INLINE LENGTH 4000);

INSERT INTO TYPES VALUES
  JSON2BSON(
  '{
  "string"    : "string",
  "integer"   : 1,
  "number"    : 1.1,
  "date"      : {"$date": "2016-06-20T13:00:00"},
  "boolean"   : true,
  "array"     : [1,2,3],
  "object"    : {type: "main", phone: [1,2,3]}
  }');

-- 
-- The following SQL will generate a list of data types and field names found within this document.
-- 

SELECT 'STRING',JSON_TYPE(DATA, 'string', 2048) FROM TYPES
UNION ALL
SELECT 'INTEGER',JSON_TYPE(DATA, 'integer', 2048) FROM TYPES
UNION ALL
SELECT 'NUMBER',JSON_TYPE(DATA, 'number', 2048) FROM TYPES
UNION ALL
SELECT 'DATE',JSON_TYPE(DATA, 'date', 2048) FROM TYPES
UNION ALL
SELECT 'BOOLEAN', JSON_TYPE(DATA, 'boolean', 2048) FROM TYPES
UNION ALL
SELECT 'ARRAY', JSON_TYPE(DATA, 'array', 2048) FROM TYPES
UNION ALL
SELECT 'OBJECT', JSON_TYPE(DATA, 'object', 2048) FROM TYPES;

--
-- Extracting Fields Using Different Data Types
--

--
-- The following sections will show how we can get atomic (non-array) types out of 
-- a JSON document. We are not going to be specific which documents we want, other 
-- than what field we want to retrieve.
--
-- A temporary table called SANDBOX is used throughout these examples:
--

DROP TABLE SANDBOX;

CREATE TABLE SANDBOX (DATA BLOB(4000) INLINE LENGTH 4000);

--
-- JSON INTEGERS and BIGINT
--

--
-- Integers within JSON documents are easily identified as numbers that don't have a 
-- decimal places in them. There are two different types of integers supported 
-- within DB2 and are identified by the size (number of digits) in the number itself.
-- 
-- • Integer – a set of digits that do not include a decimal place. The number cannot 
--             exceed −2,147,483,648 to 2,147,483,647
-- • Bigint  – a set of digits that do not include a decimal place but exceed that of 
--             an integer. The number cannot exceed –9,223,372,036,854,775,808 to 
--             9,223,372,036,854,775,807
--
-- You don't explicitly state the type of integer that you are using. 
-- The system will detect the type based on its size.
-- 
-- The JSON_TYPE function will return a value of 16 for integers and 18 for a 
-- large integer (BIGINT). To retrieve a value from an integer field you need to 
-- use the "i" flag and "l" (lowercase L) for big integers.
-- 
-- This first SQL statement will create a regular integer field.
-- 

INSERT INTO SANDBOX VALUES
  JSON2BSON('{"count":9782333}');

-- 
-- The JSON_TYPE function will verify that this is an integer field (Type=16).
-- 

SELECT JSON_TYPE(DATA,'count',2048) AS TYPE 
  FROM SANDBOX;

--
-- You can retrieve an integer value with either the 'i' flag or the 'l' flag. 
-- This first SQL statement retrieves the value as an integer.
--

SELECT JSON_VAL(DATA,'count','i') FROM SANDBOX;

--
-- We can ask that the value be interpreted as a BIGINT by using the 'l' flag, 
-- so JSON_VAL will expand the size of the return value.
--

SELECT JSON_VAL(DATA,'count','l') FROM SANDBOX;

--
-- The next SQL statement will create a field with a BIGINT size. Note that we don't 
-- need to specify anything other than have a very big number!
--

DELETE FROM SANDBOX;

INSERT INTO SANDBOX VALUES
  JSON2BSON('{"count":94123512223422}');

--
-- The JSON_TYPE function will verify that this is a big integer field (Type=18).
--

SELECT JSON_TYPE(DATA,'count',2048) AS TYPE 
  FROM SANDBOX;

--
-- We can check to see that the data is stored in the document as a BIGINT by 
-- using the JSON_TYPE function.
--

SELECT JSON_TYPE(DATA,'count',2048) FROM SANDBOX;

--
-- Returning the data as an integer type 'i' will fail since the number is too big 
-- to fit into an integer format. Note that you do not get an error message - 
-- a NULL value gets returned.
--

SELECT JSON_VAL(DATA,'count','i') FROM SANDBOX;
 
--
-- Specifying the 'I' flag will make the data be returned properly.
--

SELECT JSON_VAL(DATA,'count','l') FROM SANDBOX;

--
-- Since we have an integer in the JSON field, we also have the option of returning 
-- the value as a floating-point number (f) or as a decimal number (n). Either of 
-- these options will work with integer values.
--

SELECT JSON_VAL(DATA,'count','n') AS DECIMAL, 
       JSON_VAL(DATA,'count','f') AS FLOAT
FROM SANDBOX;
 
--
-- JSON NUMBERS and FLOATING POINT
--

--
-- JSON numbers are recognized by DB2 when there is a decimal point in the value. 
-- Floating point values are recognized using the Exx specifier after the number 
-- which represents the power of 10 that needs to be applied to the base value. 
-- For instance, 1.0E01 is the value 10.
-- 
-- The JSON type for numbers is 1, whether it is in floating point format or decimal format.
-- 
-- The SQL statement below inserts a salary into the table (using the 
-- standard decimal place notation).
--

DELETE FROM SANDBOX;
 
INSERT INTO SANDBOX VALUES
  JSON2BSON('{"salary":92342.20}');

-- 
-- The JSON_TYPE function will verify that this is a numeric field (Type=1).
--

SELECT JSON_TYPE(DATA,'salary',2048) AS TYPE 
  FROM SANDBOX;

--
-- Numeric data can be retrieved in either number (n) formant, integer (i - note that
-- you will get truncation), or floating point (f).
--

SELECT JSON_VAL(DATA,'salary','n') AS DECIMAL, 
       JSON_VAL(DATA,'salary','i') AS INTEGER,
       JSON_VAL(DATA,'salary','f') AS FLOAT
FROM SANDBOX;
 
--
-- You may wonder why number format (n) results in an answer that has a fractional 
-- component that isn't exactly 92342.20. The reason is that DB2 is converting the 
-- value to DECFLOAT(34) which supports a higher precision number, but can result in 
-- fractions that can't be accurately represented within the binary format. Casting 
-- the value to DEC(9,2) will properly format the number.
--

SELECT DEC(JSON_VAL(DATA,'salary','n'),9,2) AS DECIMAL
FROM SANDBOX;

--
-- A floating-point number is recognized by the Exx specifier in the number. The 
-- BSON function will tag this value as a number even though you specified it in floating 
-- point format. The following SQL inserts the floating value into the table.
--

DELETE FROM SANDBOX;
 
INSERT INTO SANDBOX VALUES
  JSON2BSON('{"salary":9.2523E01}');

--
-- The JSON_TYPE function will verify that this is a floating point field (Type=1).
--

SELECT JSON_TYPE(DATA,'salary',2048) AS TYPE 
  FROM SANDBOX;
 
--
-- The floating-point value can be retrieved as a number, integer, or floating point value.
--

SELECT JSON_VAL(DATA,'salary','n') AS DECIMAL, 
       JSON_VAL(DATA,'salary','i') AS INTEGER,
       JSON_VAL(DATA,'salary','f') AS FLOAT
FROM SANDBOX;

--
-- JSON BOOLEAN VALUES
--

--
-- JSON has a data type which can be true or false (boolean). DB2 doesn't have an 
-- equivalent data type for boolean, so we need to retrieve it as an integer or 
-- character string (true/false).
-- 
-- The JSON type for boolean values is 8.
--  
-- The SQL statement below inserts a true and false value into the table.
--

DELETE FROM SANDBOX;
 
INSERT INTO SANDBOX VALUES
  JSON2BSON('{"valid":true, "invalid":false}');

--
-- We will double-check what type the field is in the JSON record.
--

SELECT JSON_TYPE(DATA,'valid',2048) AS TYPE 
  FROM SANDBOX;  
 
--
-- To retrieve the value, we can ask that it be formatted as an integer or number.
--

SELECT JSON_VAL(DATA,'valid','n') AS TRUE_DECIMAL, 
       JSON_VAL(DATA,'valid','i') AS TRUE_INTEGER,
       JSON_VAL(DATA,'invalid','n') AS FALSE_DECIMAL,
       JSON_VAL(DATA,'invalid','i') AS FALSE_INTEGER
FROM SANDBOX;

--
-- You can also retrieve a boolean field as a character or
-- binary field, but the results are not what you would expect
-- with binary.
--

SELECT JSON_VAL(DATA,'valid','s:5') AS TRUE_STRING, 
       JSON_VAL(DATA,'valid','b:2') AS TRUE_BINARY,
       JSON_VAL(DATA,'invalid','s:5') AS FALSE_STRING,
       JSON_VAL(DATA,'invalid','b:2') AS FALSE_BINARY
FROM SANDBOX;

--
-- JSON DATE, TIME, and TIMESTAMPS
--

-- 
-- This first SQL statement will insert a JSON field that uses the $date modifier.
--

DELETE FROM SANDBOX;
 
INSERT INTO SANDBOX VALUES
  JSON2BSON('{"today":{"$date":"2016-07-01T12:00:00"}}');

--
-- Querying the data type of this field using JSON_VAL will return a value of 9 (date type).
--
 
SELECT JSON_TYPE(DATA,'today',2048) FROM SANDBOX;

--
-- If you decide to use a character string to represent a date, you can use either 
-- the "s:x" specification to return the date as a string,
-- or use "d" to have it displayed as a date. This first SQL
-- statement returns the date as a string.
--

DELETE FROM SANDBOX;
 
INSERT INTO SANDBOX VALUES
  JSON2BSON('{"today":"2016-07-01"}');

SELECT JSON_VAL(DATA,'today','s:10') FROM SANDBOX;

--
-- Using the 'd' specification will return the value as a date.
--

SELECT JSON_VAL(DATA,'today','d') FROM SANDBOX;
 
--
-- What about timestamps? If you decide to store a timestamp into a field, you can 
-- retrieve it in a variety of ways. This first set of SQL statements will retrieve 
-- it as a string.
--

DELETE FROM SANDBOX;
 
INSERT INTO SANDBOX VALUES
   JSON2BSON('{"today":"' || VARCHAR(NOW()) || '"}');

SELECT JSON_VAL(DATA,'today','s:30') FROM SANDBOX;

--
-- Retrieving it as a Date will also work, but the time portion will be removed.
--

SELECT JSON_VAL(DATA,'today','d') FROM SANDBOX;
 
--
-- You can also ask for the timestamp value by using the 'ts'
-- specification. Note that you can't get just the time portion
-- unless you use a SQL function to cast it.
--

SELECT JSON_VAL(DATA,'today','ts') FROM SANDBOX;

-- 
-- To force the value to return just the time portion, either
-- store the data as a time value (HH:MM:SS) string or store a
-- timestamp and use the TIME function to extract just that
-- portion of the timestamp.
--
 
SELECT TIME(JSON_VAL(DATA,'today','ts')) FROM SANDBOX;

--
-- JSON Strings
--

--
-- For character strings, you must specify what the maximum
-- length is. This example will return the size of the lastname
-- field as 10 characters long.
--

SELECT JSON_VAL(EMP_DATA, 'lastname', 's:10') FROM JSON_EMP;

--
-- You must specify a length for the 's' parameter otherwise
-- you will get an error from the function. If the size of the
-- character string is too large to return, then the function
-- will return a null value for that field.
--

SELECT JSON_VAL(EMP_DATA, 'lastname', 's:8') FROM JSON_EMP;
 
--
-- JSON_TABLE Function
--

--
-- The following query works because we do not treat the field phoneno as an array:
--

SELECT JSON_VAL(EMP_DATA, 'phoneno', 'i') FROM JSON_EMP;

--
-- By default, only the first number of an array is returned
-- when you use JSON_VAL. However, there will be situations
-- where you do want to return all the values in an array. This
-- is where the JSON_TABLE function must be used.
--
-- The format of the JSON_TABLE function is:
--  
--    JSON_TABLE(document, field, type)
-- 
-- The arguments are:
-- 
-- • document – BSON document
-- • field – The field we are looking for
-- • type – The return type of data being returned 
--  
-- JSON_TABLE returns two columns: Type and Value. The type
-- is one of a possible 18 values found in the table below. The
-- Value is the actual contents of the field.
--  
-- ID  	TYPE                 	ID  	TYPE
--  1  	Double               	10  	Null      
--  2  	String               	11  	Regular Expression
--  3  	Object               	12  	Future use
--  4  	Array                	13  	JavaScript
--  5  	Binary data          	14  	Symbol
--  6  	Undefined            	15  	Javascript (with scope)
--  7  	Object id            	16  	32-bit integer
--  8  	Boolean              	17  	Timestamp 
--  9  	Date                 	18  	64-bit integer
-- 
-- The TYPE field is probably something you wouldn't require
-- as part of your queries since you are already specifying the
-- return type in the function.
-- 
-- The format of the JSON_TABLE function is like JSON_VAL
-- except that it returns a table of values. You must use this
-- function as part of FROM clause and a table function
-- specification. For example, to return the contents of the
-- phone extension array for just one employee (000230) we can
-- use the following JSON_TABLE function.
--

SELECT PHONES.TYPE, CAST(PHONES.VALUE AS VARCHAR(10)) AS VALUE FROM JSON_EMP E, 
       TABLE( JSON_TABLE(E.EMP_DATA,'phoneno','i') ) AS PHONES 
WHERE JSON_VAL(E.EMP_DATA,'empno','s:6') = '000230'; 

--
-- The TABLE( ... ) specification in the FROM clause is used
-- for table functions. The results that are returned from the
-- TABLE function are treated the same as a traditional table.
-- 
-- To create a query that gives the name of every employee and their extensions would require the following query.

SELECT JSON_VAL(E.EMP_DATA, 'lastname', 's:10') AS LASTNAME, 
       CAST(PHONES.VALUE AS VARCHAR(10)) AS PHONE
  FROM JSON_EMP E, 
       TABLE( JSON_TABLE(E.EMP_DATA,'phoneno','i') ) AS PHONES;
 
-- 
-- Only a subset of the results is shown above, but you will
-- see that there are multiple lines for employees who have
-- more than one extension.
-- 
-- The results of a TABLE function must be named (AS ...) if
-- you need to refer to the results of the TABLE function in
-- the SELECT list or in other parts of the SQL.
-- 
-- You can use other SQL operators to sort or organize the
-- results. For instance, we can use the ORDER BY operator to
-- find out which employees have the same extension. Note how
-- the TABLE function is named PHONES and the VALUES column is
-- renamed to PHONE.
--

SELECT JSON_VAL(E.EMP_DATA, 'lastname', 's:10') AS LASTNAME,
       CAST (PHONES.VALUE AS VARCHAR(10)) AS PHONE
  FROM JSON_EMP E, 
       TABLE( JSON_TABLE(E.EMP_DATA,'phoneno','i') ) AS PHONES
ORDER BY PHONE; 

--
-- You can even find out how many people are sharing
-- extensions! The HAVING clause tells DB2 to only return
-- groupings where there are more than one employee with the
-- same extension.
--

SELECT CAST(PHONES.VALUE AS VARCHAR(10)) AS PHONE, COUNT(*) AS COUNT 
  FROM JSON_EMP E, 
       TABLE( JSON_TABLE(E.EMP_DATA,'phoneno','i') ) AS PHONES
GROUP BY PHONES.VALUE HAVING COUNT(*) > 1
ORDER BY PHONES.VALUE;

--
-- JSON_LEN Function
-- 

--
-- The previous example showed how we could retrieve the
-- values from within an array of a document. Sometimes an
-- application needs to determine how many values are in the
-- array itself. The JSON_LEN function is used to figure out
-- what the array count is. 
-- 
-- The format of the JSON_LEN function is:
--  
--    count = JSON_LEN(document,field)
-- 
-- The arguments are:
-- • document – BSON document
-- • field – The field we are looking for
-- • count – Number of array entries or NULL if the field is not an array
-- If the field is not an array, this function will return a
-- null value, otherwise it will give you the number of values
-- in the array. In our previous example, we could determine
-- the number of extensions per person by taking advantage of
-- the JSON_LEN function.
--

SELECT JSON_VAL(E.EMP_DATA, 'lastname', 's:10') AS LASTNAME, 
       JSON_LEN(E.EMP_DATA, 'phoneno') AS PHONE_COUNT
  FROM JSON_EMP E;

--
-- JSON_GET_POS_ARR_INDEX Function
--

--
-- The JSON_TABLE and JSON_LEN functions can be used to
-- retrieve all the values from an array, but searching for a
-- specific array value is difficult to do. One way to seach
-- array values is to extract everything using the JSON_TABLE
-- function.
--

SELECT JSON_VAL(E.EMP_DATA, 'lastname', 's:10') AS LASTNAME,
       CAST(PHONES.VALUE AS VARCHAR(10)) AS PHONE
  FROM JSON_EMP E, 
       TABLE( JSON_TABLE(E.EMP_DATA,'phoneno','i') ) AS PHONES
WHERE PHONES.VALUE = 1422;

-- An easier way is to use the JSON_GET_POS_ARR_INDEX function.
-- This function will search array values without having to
-- extract the array values with the JSON_TABLE function.
-- 
-- The format of the JSON_GET_POS_ARR_INDEX function is:
-- 
--    element = JSON_GET_POS_ARR_INDEX(document, field)
-- 
-- The arguments are: 
-- • document – BSON document
-- • field – The field we are looking for and its value
-- • element – The first occurrence of the value in the array
--
-- The format of the field argument is "{field:value}" and it needs to be in
-- BSON format. This means you needs to add the JSON2BSON
-- function around the field specification.
--     JSON2BSON( '{"field":"value"}' ) 
-- This function only tests for equivalence and the data type should match what is
-- already in the field. The return value is the position
-- within the array that the value was found, where the first
-- element starts at zero.
-- 
-- In our JSON_EMP table, each employee has one or more phone
-- numbers. The following SQL will retrieve all employees who
-- have the extension 1422:
--

SELECT JSON_VAL(EMP_DATA, 'lastname', 's:10') AS LASTNAME
  FROM JSON_EMP
WHERE JSON_GET_POS_ARR_INDEX(EMP_DATA,
  JSON2BSON('{"phoneno":1422}')) >= 0;

--
-- If we used quotes around the phone number, the function will not match any of 
-- the values in the table.
--

--
-- Updating JSON Documents
--

--
-- There are a couple of approaches available to updating JSON
-- documents. One approach is to extract the document from the
-- table in a text form using BSON2JSON and then using string
-- functions or regular expressions to modify the data.
-- 
-- The other option is to use the JSON_UPDATE statement. The
-- syntax of the JSON_UPDATE function is:
-- 
--    JSON_UPDATE(document, '{$set: {field:value}}')
-- 
-- The arguments are: 
-- • document – BSON document 
-- • field – The field we are looking for 
-- • value – The value we want to set the field to
-- 
-- There are three possible outcomes from using the JSON_UPDATE statement:
-- • If the field is found, the existing value is replaced with the new one
-- • If the field is not found, the field:value pair is added to the document
-- • If the value is set to the null keyword, the field is removed from the document
--
-- The field can specify a portion of a structure, or an element of an
-- array using the dot notation. The following SQL will
-- illustrate how values can be added and removed from a document.
-- 
-- A single record that contains 3 phone number extensions are
-- added to a table:
--

DELETE FROM SANDBOX;

INSERT INTO SANDBOX VALUES
   JSON2BSON('{"phone":"[1111,2222,3333]"}');

--
-- To add a new field to the record, the JSON_UPDATE function needs to specify the 
-- field and value pair.
--

UPDATE SANDBOX
  SET DATA = 
    JSON_UPDATE(DATA,'{ $set: {"lastname":"HAAS"}}');

--
-- Retrieving the document shows that the lastname field has now been added to the record.
--

SELECT CAST(BSON2JSON(DATA) AS VARCHAR(60)) FROM SANDBOX;

--
-- If you specify a field that is an array type and do not
-- specify an element, you will end up replacing the entire
-- field with the value.
--

UPDATE SANDBOX
  SET DATA = 
    JSON_UPDATE(DATA,'{ $set: {"phone":"9999"}}');

SELECT CAST(BSON2JSON(DATA) AS VARCHAR(60)) FROM SANDBOX;

--
-- Running the SQL against the original phone data will work properly.
--

UPDATE SANDBOX
  SET DATA = 
    JSON_UPDATE(DATA,'{ $set: {"phone.0":9999}}');

SELECT CAST(BSON2JSON(DATA) AS VARCHAR(60)) FROM SANDBOX;

--
-- Indexing JSON Documents
--

--
-- DB2 supports computed indexes, which allows for the use
-- of functions like JSON_VAL to be used as part of the index
-- definition. For instance, searching for an employee number
-- will result in a scan against the table if no indexes are
-- defined:
--

SELECT JSON_VAL(EMP_DATA, 'lastname', 's:20') AS LASTNAME
  FROM JSON_EMP
WHERE  JSON_VAL(EMP_DATA, 'empno', 's:6') = '000010';

--
-- The following is the explain output
-- 
-- Cost = 13.628412
-- 
--     Rows   
--   Operator 
--     (ID)   
--     Cost   
--    1.68   
--   RETURN  
--    ( 1)   
--   13.6284 
--     |     
--    1.68   
--   TBSCAN  
--    ( 2)   
--   13.6283 
--     |     
--     42    
--  Table:   
--  BAKLARZ  
--  JSON_EMP
-- 
-- To create an index on the empno field, we use the JSON_VAL function to extract the 
-- empno from the JSON field.
--

CREATE INDEX IX_JSON ON JSON_EMP
  (JSON_VAL(EMP_DATA,'lastname','s:20'));

--
-- Rerunning the SQL results in the following explain plan:
--
-- 
-- Cost = 6.811412
-- 
--           Rows   
--         Operator 
--           (ID)   
--           Cost   
--          1.68   
--         RETURN  
--          ( 1)   
--         6.81141 
--           |    
--          1.68  
--         FETCH  
--          ( 2)  
--         6.8113 
--        /      \
--     1.68        42    
--    IXSCAN    Table:   
--     ( 3)     BAKLARZ  
--  0.00484089  JSON_EMP 
--     |     
--     42    
--   Index:  
--   BAKLARZ 
--   IX_JSON
--
-- DB2 can now use the index to retrieve the record. 
--

--
-- Simplifying JSON SQL Inserts and Retrieval
--

--
-- From a development perspective, you always need to convert
-- documents to and from JSON using the BSON2JSON and JSON2BSON
-- functions. There are ways to hide these functions from an
-- application and simplify some of the programming.
-- 
-- One approach to simplifying the conversion of documents
-- between formats is to use INSTEAD OF triggers. These
-- triggers can intercept transactions before they are applied
-- to the base tables. This approach requires that we create a
-- view on top of an existing table.
-- 
-- The first step is to create the base table with two copies
-- of the JSON column. One will contain the original JSON
-- character string while the second will contain the converted
-- BSON. For this example, the JSON column will be called INFO,
-- and the BSON column will be called BSONINFO. The use of two
-- columns containing JSON would appear strange at first. The
-- reason for the two columns is that DB2 expects the BLOB
-- column to contain binary data. You cannot insert a character
-- string (JSON) into the BSON column without converting it
-- first. DB2 will raise an error so the JSON column is there
-- to avoid an error while the conversion takes place.
-- 
-- From a debugging perspective, we can keep both the CLOB and
-- BLOB values in this table if we want. The trigger will set
-- the JSON column to null after the BSON column has been
-- populated.
--

DROP TABLE BASE_EMP_TXS;
CREATE TABLE BASE_EMP_TXS (
  SEQNO    INT NOT NULL GENERATED ALWAYS AS IDENTITY,
  INFO     VARCHAR(4000),
  BSONINFO BLOB(4000) INLINE LENGTH 4000
  );

--  
-- To use INSTEAD OF triggers, a view needs to be created on
-- top of the base table. Note that we explicitly use the
-- SYSTOOLS schema to make sure we are getting the correct
-- function used here.
--

CREATE OR REPLACE VIEW EMP_TXS AS
  (SELECT SEQNO, BSON2JSON(BSONINFO) AS INFO FROM BASE_EMP_TXS);

--
-- At this point we can create three INSTEAD OF triggers to handle insert, 
-- updates and deletes on the view. 
--
-- On INSERT the DEFAULT keyword is used to generate the ID number, the JSON field is 
-- set to NULL and the BSON column contains the converted value of the JSON string. 
--

--#SET TERMINATOR /

CREATE OR REPLACE TRIGGER I_EMP_TXS
  INSTEAD OF INSERT ON EMP_TXS
  REFERENCING NEW AS NEW_TXS
  FOR EACH ROW MODE DB2SQL
BEGIN ATOMIC
  INSERT INTO BASE_EMP_TXS VALUES (
     DEFAULT,
     NULL,
     SYSTOOLS.JSON2BSON(NEW_TXS.INFO)
     );
END
/

--
-- On UPDATES, the sequence number remains the same, and the BSON field is updated 
-- with the contents of the JSON field.
--

CREATE OR REPLACE TRIGGER U_EMP_TXS
  INSTEAD OF UPDATE ON EMP_TXS
  REFERENCING NEW AS NEW_TXS OLD AS OLD_TXS
  FOR EACH ROW MODE DB2SQL
BEGIN ATOMIC
  UPDATE BASE_EMP_TXS 
     SET (INFO, BSONINFO) = (NULL,
         SYSTOOLS.JSON2BSON(NEW_TXS.INFO)) 
     WHERE 
       BASE_EMP_TXS.SEQNO = OLD_TXS.SEQNO;
END
/

--
-- Finally, the DELETE trigger will just remove the row.
--

CREATE OR REPLACE TRIGGER D_EMP_TXS
  INSTEAD OF DELETE ON EMP_TXS
  REFERENCING OLD AS OLD_TXS
  FOR EACH ROW MODE DB2SQL
BEGIN ATOMIC
  DELETE FROM BASE_EMP_TXS 
     WHERE 
       BASE_EMP_TXS.SEQNO = OLD_TXS.SEQNO;
END
/

--#SET TERMINATOR ;

-- Applications will only deal with the EMP_TXS view. Any
-- inserts will use the text version of the JSON and not have
-- to worry about using the JSON2BSON function since the
-- underlying INSTEAD OF trigger will take care of the
-- conversion.
-- 
-- The following insert statement only includes the JSON string
-- since the sequence number will be generated automatically as
-- part of the insert.
--

INSERT INTO EMP_TXS(INFO) VALUES (
    '{
    "empno":"000010",
    "firstnme":"CHRISTINE",
    "midinit":"I",
    "lastname":"HAAS",
    "workdept":"A00",
    "phoneno":[3978],
    "hiredate":"01/01/1995",
    "job":"PRES",
    "edlevel":18,
    "sex":"F",
    "birthdate":"08/24/1963",
    "pay" : {
      "salary":152750.00,
      "bonus":1000.00,
      "comm":4220.00}
    }');

--
-- Selecting from the EMP_TXS view will return the JSON in a readable format:
--

SELECT SEQNO, CAST(LEFT(INFO,60) AS VARCHAR(60)) FROM EMP_TXS;  

--
-- The base table only contains the BSON but the view translates the value back into a readable format.
--
-- An update statement that replaces the entire string works as expected.
--

UPDATE EMP_TXS SET INFO = '{"empno":"000010"}' WHERE SEQNO = 1;
SELECT SEQNO, CAST(LEFT(INFO,60) AS VARCHAR(60)) FROM EMP_TXS;  

--
-- If you want to manipulate the BSON directly (say change the employee number), 
-- you need to refer to the BASE table instead.
--

UPDATE BASE_EMP_TXS
  SET BSONINFO = JSON_UPDATE(BSONINFO,
    '{$set: {"empno":"111111"}}')
  WHERE SEQNO = 1;

--
-- And we can check it using our original view.
--

SELECT SEQNO, CAST(LEFT(INFO,60) AS VARCHAR(60)) FROM EMP_TXS;  

--
-- Note: Remember that these functions are not officially
-- supported. Use of these functions is entirely at your own
-- risk and may not operate in the same way in the future.
--  

QUIT;
  
  
  