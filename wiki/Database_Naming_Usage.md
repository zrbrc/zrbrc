# dept/IRM Database Naming Usage rev: 11/18/2014

- [dept/IRM Database Naming Usage rev: 11/18/2014](#deptirm-database-naming-usage-rev-11182014)
  - [Database Names](#database-names)
  - [System Accounts](#system-accounts)
  - [Object Names](#object-names)
  - [Indexes](#indexes)
  - [Temp Tables](#temp-tables)
  - [Interface specific Tables](#interface-specific-tables)
  - [Fields](#fields)
  - [Appendix A](#appendix-a)
  
## Database Names

SQLServer databases will be named using the following standard

- Database: Division_Application_Environment
- IE: a Production database for the Division of Social Services used for
Their client tracking system could be named – DSS_ClientTracker_PROD

## System Accounts

Each database is granted system account or accounts that the application uses to access the database. These accounts are granted access rights to the specified database(s)objects as appropriate for the application. Any application/database security model outside of this configuration will need written approval from the dept Manager of Base Technology.

## Object Names

Database object names are composed of **Pascal case** followed by an underscore, and a character object type identifier (upper case). An example of this would be “JobTransactions_T” which indicates a regular table of JobTransactions.
The character object type identifiers are as follows:

| Object Type                      | Code |
| -------------------------------- | ---- |
| Regular Table                    | T    |
| Persistent Temporary Tables [^1] | P    |
| Views                            | V    |
| Stored Procedures                | SP   |
| Rules                            | R    |
| Defaults                         | D    |
| Triggers                         | TR   |

## Indexes

Preface Primary key indexes with PK followed by an underscore and then the Table name. IE: PK_ClientAddress_T

All other indexes, preface with an IX followed by an underscore, the Table name followed by the index Descriptor. IE: IX_Person_T_NameSearch.

## Temp Tables

Per [http://msdn.microsoft.com/en-us/library/ms174979.aspx](http://msdn.microsoft.com/en-us/library/ms174979.aspx) You can create local and global temporary tables. Local temporary tables are visible only in the current session, and global temporary tables are visible to all sessions. Temporary tables cannot be partitioned.
Prefix local temporary table names with single number sign (#Table_Name_T), and prefix global temporary table names with a double number sign (##Table_Name_T).

## Interface specific Tables

Will use the following naming standard. Agency_FileName_<Direction>_T(P). Direction is to be “Inbound” or “Outbound” only. For example, A DPH system that has an inbound file interface from the Federal Office of Drinking Water could be named FODW_WellResults_Inbound_P. An outbound file interface could be named FODW_WellSamples_Outbound_P. Note that in this example the tables are defined as Persistent Temporary Tables and there use the “_P” postfix.

## Fields

Field names are composed of Pascal case, followed by an underscore, followed by a three to four character SQL Class Word in all uppercase letters (see Appendix A for approved SQL Class Words.) For example: ClientFirst_NAME, ClientMailing_ADDR or Client_IDNO.

## Appendix A

SQL CLASS WORDS AND MODIFIERS

| CLASS WORD            | ABBREVIATION | DEFINITION                                                                                              |
| --------------------- | ------------ | ------------------------------------------------------------------------------------------------------- |
| ADDRESS               | ADDR         | STANDARD MAILING ADDRESS DATA                                                                           |
| AMOUNT                | AMNT         | ANY QUANTITY OF MONEY.                                                                                  |
| BIT                   | BIT          | NUMERIC BINARY (I.E., 1 or 0)                                                                           |
| CODE                  | CODE         | DATA WHICH IDENTIFIES CLASSIFICATIONS OR GROUPS OF ENTITIES.                                            |
| DATE                  | DATE         | ACTUAL CALENDAR DAY OR GROUP OF DAYS (I.E. MONTH AND YEAR).                                             |
| DATE-TIME             | DTTM         | ACTUAL CALENDAR DAY OR GROUP OF DAYS (I.E. MONTH AND YEAR) PLUS ANY UNIT OF TIME NOT CONSIDERED A DATE. |
| EMAIL ADDRESS         | EML          | TEXT REPRESENTATION OF EMAIL ADDR                                                                       |
| IDENTIFICATION NUMBER | IDNO         | NUMERIC OR ALPHANUMERIC DATA. IDENTIFIES A SPECIFIC ENTITY.                                             |
| IMAGE                 | IMG          | IMAGE BINARY DATA (GIF, JPG, ETC)                                                                       |
| INDICATOR             | INDC         | BINARY OR ALPHANUMERIC VALUE  (I.E.Y/N)                                                                 |
| INTEGER               | INT          | ANY INTEGER NUMBER                                                                                      |
| KEY                   | KEY          | GROUP OF DATA USED AS A KEY FIELD                                                                       |
| LOCATION              | LCTN         | GEOGRAPHIC POSITIONING DATA.                                                                            |
| NAME                  | NAME         | ALPHANUMERIC DATA THAT IDENTIFIES A SPECIFIC ENTITY.                                                    |
| NUMBER                | NUMB         | NUMERIC DATA THAT IDENTIFIES A SPECIFIC ENTITY.                                                         |
| PERCENT               | PCT          | RATIO BETWEEN DATA VALUES EXPRESSED AS A PERCENTAGE.                                                    |
| QUANTITY              | QNTY         | AN AMOUNT OF ANYTHING OTHER THAN MONEY.                                                                 |
| TEXT                  | TEXT         | FREE FORM CHARACTER DATA                                                                                |
| TIME                  | TIME         | ANY UNIT OF TIME OTHER THAN DATE                                                                        |
| URL                   | URL          | INTERNET ADDRESS                                                                                        |
| USER DEFINED DATA     | UDD          | ANY PROGRAMMER DEFINED DATA TYPE                                                                        |

[^1]: Persistant Temporary Tables are tables where the structure is created as a regular permanent table but the data contained in those tables is used only in temporary contexts. IE: daily Interface files loaded to temp tables for batch processing where the table gets truncated on every run.