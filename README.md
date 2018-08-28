# Db2 Jupyter Notebook Extensions
A Jupyter notebook and magic functions to demonstrate Db2 LUW 11 features.

This code is imported as a Jupyter notebook extension in any notebooks you create with Db2 code in it. Place the following line of code in any notebook that you want to use these commands with:
```Python
%run db2.ipynb
```

This code defines a Jupyter/Python magic command called `%sql` which allows you to execute Db2 specific calls to the database. There are other packages available for manipulating databases, but this one has been specifically designed for demonstrating a number of the SQL features available in Db2.

There are two ways of executing the `%sql` command. A single line SQL statement would use the line format of the magic command:
```Python
%sql SELECT * FROM EMPLOYEE
```

If you have a large block of sql then you would place the %%sql command at the beginning of the block and then place the SQL statements into the remainder of the block. Using this form of the `%%sql` statement means that the notebook cell can only contain SQL and no other statements.
```Python
%%sql
SELECT * FROM EMPLOYEE
ORDER BY LASTNAME
```

You can have multiple lines in the SQL block (`%%sql`). The default SQL delimiter is the semi-column (`;`). If you have scripts (triggers, procedures, functions) that use the semi-colon as part of the script, you will need to use the -d option to change the delimiter to an at "@" sign. 
```Python
%%sql -d
SELECT * FROM EMPLOYEE
@
CREATE PROCEDURE ...
@
```

The `%sql` command allows most DB2 commands to execute and has a special version of the CONNECT statement. A CONNECT by itself will attempt to reconnect to the database using previously used settings. If it cannot connect, it will prompt the user for additional information. 

The CONNECT command has the following format:
```Python
%sql CONNECT TO <database> USER <userid> USING <password | ?> HOST <ip address> PORT <port>
```

If you use a "?" for the password field, the system will prompt you for a password. This avoids typing the password as clear text on the screen. If a connection is not successful, the system will print the error message associated with the connect request.

If the connection is successful, the parameters are saved on your system and will be used the next time you run a SQL statement, or when you issue the %sql CONNECT command with no parameters.

In addition to the -d option, there are a number different options that you can specify at the beginning of the SQL:

- -d - Delimiter: Change SQL delimiter to "@" from ";"
- -q - Quiet: Quiet results - no answer set or messages returned from the function
- -r - Return the result set as a data frame for Python usage
- -t - Time: Time the following SQL statement and return the number of times it executes in 1 second
- -j - JSON: Create a pretty JSON representation. Only the first column is formatted
- -a - All: Return all rows in answer set and do not limit display
- -pb - Plot Bar: Plot the results as a bar chart
- -pl - Plot Line: Plot the results as a line chart
- -pp - Plot Pie: Plot the results as a pie chart
- -i - Interactive plotting and viewing of the data
- -sampledata - Create and load the EMPLOYEE and DEPARTMENT tables

One final note. You can pass python variables to the %sql command by using the \{\} braces with the name of the variable inbetween. Note that you will need to place proper punctuation around the variable in the event the SQL command requires it. For instance, the following example will find employee '000010' in the EMPLOYEE table.
```Python
empno = '000010'
%sql SELECT LASTNAME FROM EMPLOYEE WHERE EMPNO='{empno}'
```

The other option is to use a colon in front of a variable name and then no quotes are required.
```Python
%sql SELECT LASTNAME FROM EMPLOYEE WHERE EMPNO=:empno
```

For more documentation and examples, see the Db2 Jupyter Tutorial or sign-up for a free [Db2 Proof of Technology](https://www.ibm.com/cloud/garage/tutorials/ibm-db2-local/modern-application-development-with-db-2) that contains the code from this GitHub repository. Additional details on Db2 features and functions can be found on the [Db2 Advanced Enterprise Edition](https://www.ibm.com/products/db2-database) site.
