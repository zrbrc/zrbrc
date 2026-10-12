-- simple bulk insert POC, reads input and format file
-- https://docs.microsoft.com/en-us/sql/relational-databases/import-export/xml-format-files-sql-server?view=sql-server-ver16#ImportFixedFields

CREATE TABLE [dbo].[Person_T](
SSN             VARCHAR(9),
DOB             VARCHAR(10),
LAST_NAME       VARCHAR(20),
FIRST_NAME      VARCHAR(22),
ADDRESS_1       VARCHAR(32),
ADDRESS_2       VARCHAR(32),
CITY            VARCHAR(25),
STATE           VARCHAR(2),
ZIP             VARCHAR(9),
AGENCY_SOURCE   VARCHAR(3),
AGENCY2_SOURCE  VARCHAR(3),
AGENCY2_LNAME   VARCHAR(40),
AGENCY2_FNAME   VARCHAR(22),
AGENCY2_ADDR1   VARCHAR(20),
AGENCY2_ADDR2   VARCHAR(20),
AGENCY2_CITY    VARCHAR(15),
AGENCY2_STATE   VARCHAR(2),
AGENCY2_ZIP     VARCHAR(9),
AGENCY2_ID      VARCHAR(7)
) ON [PRIMARY]
GO

USE DOF_Reference

TRUNCATE TABLE dbo.Person_T

BULK INSERT dbo.Person_T
FROM 'M:\Management\DOF\DOR_to_db_062922.LST'
WITH ( FORMATFILE = 'M:\Management\DOF\format.xml' )