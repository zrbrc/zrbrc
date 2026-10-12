# Database Naming Standards, Best Practices, and Styling

## General

- ProperCase/PascalCase for all database objects.
- Object names must be all letters or numbers.
- Underscore in atabase name only.
- Avoid abbreviations unless necessary or commonly known.

## Database Naming

`DIVISION_APPLICATION_ENVIRONMENT`

- Division and environment are all caps.
- Application can be PascalCase or all caps depending on common name of application.

Example: `DSS_WorkerWeb_PROD`, `db_MCI_PROD`, `DCSE_DECSS_TEST`

## Object Naming

- Tables
  - Naming is singular.
  - No prefixes (tbl_) or suffixes (_T) to identify object type.
  
- Columns
  - Naming is singular.
  - No prefixes or suffixes to identify object type.
  - Column name of primary key shall be TableName + Id. For example, if the table name is Address, PK will be AddressId.

- Keys\Contraints
  - Keys will be named with prefix of `PK_<tablename>` for primary keys and `FK_<thistable>_<othertable>` for foreign keys.
  
- Indexes
  - Indexes will be named `IX_<tablename>_<includedcolumns>`
  
- Stored Procedures
  - SPs will be prefixed with `usp` and must contain a verb. Example, `uspGetMaxSalary`.
  
- Functions
  - Functions will be prefixed with `ufn` and must contain a verb. Example, `ufnGetSystemDate`.

## Uniform Suffixes

The following suffixes have universal meanings and may be used to for readibility and comprehension.

- Id: a unique identifier such as a column that is a primary key. e.g. `AddressId`
- Status: flag value or some other status of any type. e.g. `PublicationStatus`.
- Total: the total or sum of a collection of values.
- Num: denotes the field contains any kind of number.
- Name: signifies a name. e.g. `FirstName`
- Seq: contains a contiguous sequence of values or a sequence of a recordset. e.g. `HistorySeq`
- Date: denotes a column that contains the date of something. e.g. `SaleDate`
- Size: the size of something such as a file size or clothing.
- Addr: an address for the record could be physical or intangible such as `IpAddr`.

## SQL Style Option 1

Basetech will not be checking or enforcing formatting of SQL, but below are some examples of a suggested style. The first option is the preferred option of the 2.

### General Rules

- All SQL reserved keywords should be in uppercase. e.g. `SELECT`, `WHERE`, `FROM`
- It is best to use the full keyword instead of abbreviations for readability.
- No trailing whitespace.
- Variable names should be underscore separated:
  - GOOD: `SELECT COUNT(*) AS backers_count`
  - BAD: `SELECT COUNT(*) AS backersCount`
- Comments should go near the top of your query, or at least near the closest SELECT.
- Try to only comment on things that aren't obvious about the query (e.g., why a particular ID is hardcoded, etc.)
- Don't use single letter variable names or alaises be as descriptive as possible given the context:
  - GOOD: `SELECT Backings AS BackingsWithCreators`
  - BAD: `SELECT Backings AS b`
- Use Common Table Expressions (CTEs) early and often, and name them well.
- Commas after the selected columns.

### White Spaces

Spaces should be used to line up the code so that the root keywords all end on the same character boundary. This forms a river down the middle making it easy for the readers eye to scan over the code and separate the keywords from the implementation detail.

```sql
SELECT m.Name,
       p.Name,
       p.ModelNum
  FROM Phone AS p
       JOIN Manufacturer AS m ON p.ManufacturerId = m.ManufacturerId
 WHERE p.ReleaseDate > '2014-09-30'
 ORDER BY m.Name,
          p.Name
```

Notice that `SELECT`, `FROM`, etc. are all right aligned while the actual column names and implementation-specific details are left aligned.

Although not exhaustive always include spaces:

- before and after equals (`=`)
- after commas (`,`) in lists
- surrounding apostrophes (`'`) where not within parentheses or with a trailing comma or semicolon

### Line spacing

Always include newlines/vertical space:

- before `AND` or `OR`
- after semicolons to separate queries for easier reading
- after each keyword definition
- after a comma when separating multiple columns into logical groups
- to separate code into related sections, which helps to ease the readability of
  large chunks of code.

Keeping all the keywords aligned to the righthand side and the values left aligned creates a uniform gap down the middle of the query. It also makes it much easier to to quickly scan over the query definition.

```sql
INSERT INTO Album (Title, ReleaseDate, RecordingDate)
VALUES ('Charcoal Lane', '1990-01-01 01:01:01.00000', '1990-01-01 01:01:01.00000'),
       ('The New Danger', '2008-01-01 01:01:01.00000', '1990-01-01 01:01:01.00000')
```

```sql
UPDATE Album
   SET ReleaseDate = '1990-01-01 01:01:01.00000'
 WHERE Title = 'The New Danger'
```

```sql
SELECT Title,
       ReleaseDate, 
       RecordingDate, 
       RroductionDate
  FROM Album
 WHERE Title IN ('Charcoal Lane', 'The New Danger')
```

### Indentation

To ensure that SQL is readable it is important that standards of indentation are followed.

#### Joins

Joins should be indented to the other side of the river and grouped with a new line where necessary. If there are multiple join conditions, add it on a newline.

```sql
SELECT r.LastName
  FROM Rider AS r
       INNER JOIN Bike AS b ON r.BikeVinNum = b.VinNum
         AND b.EngineTally > 2
       INNER JOIN Crew AS c ON r.CrewChiefLastName = c.LastName
         AND c.Chief = 'Y'
```

#### Subqueries

Subqueries should also be aligned to the right side of the river and then laid out using the same style as any other query. Sometimes it will make sense to have the closing parenthesis on a new line at the same character position as its opening partner—this is especially true where you have nested subqueries.

```sql
SELECT r.LastName,
       (SELECT MAX(YEAR(ChampionshipDate))
          FROM Champion AS c
         WHERE c.LastName = r.LastName
           AND c.Confirmed = 'Y') AS LastChampionshipYear
  FROM Rider AS r
 WHERE r.LastName IN
       (SELECT c.LastName
          FROM Champion AS c
         WHERE YEAR(ChampionshipDate) > '2008'
           AND c.Confirmed = 'Y')
```

### Preferred formalisms

- Make use of `BETWEEN` where possible instead of combining multiple statements with `AND`.
- Similarly use `IN()` instead of multiple `OR` clauses.
- Where a value needs to be interpreted before leaving the database use the `CASE` expression. `CASE` statements can be nested to form more complex logical structures. Case statements are hard to align sometimes, but the below example is a good format.
- Avoid the use of `UNION` clauses and temporary tables where possible. If the schema can be optimised to remove the reliance on these features then it most likely should be.

```sql
SELECT CASE ZipCode
            WHEN '19720' 
                 THEN 'Wilmington'
            WHEN '19711' 
                 THEN 'Newark'
       END AS City
  FROM OfficeLocation
 WHERE StateCode = 'DE'
   AND OpeningTime BETWEEN 8 AND 9
   AND ZipCode IN ('19720','19711')
```

## Create syntax

When declaring schema information it is also important to maintain human-readable code. To facilitate this ensure that the column definitions are ordered and grouped together where it makes sense to do so.

Indent column definitions by four (4) spaces within the `CREATE` definition.

### Choosing data types

- Where possible do not use vendor-specific data types—these are not portable and   may not be available in older versions of the same vendor's software.
- Only use `REAL` or `FLOAT` types where it is strictly necessary for floating point mathematics otherwise prefer `NUMERIC` and `DECIMAL` at all times. Floating point rounding errors are a muisance!
- Only use numeric typed fields if you need to perform math on them. `ZipCode` will never need need math performed on it, so a varchar(5) or (9) would suffice.

### Specifying default values

- The default value must be the same type as the column—if a column is declared a `DECIMAL` do not provide an `INTEGER` default value.
- Default values must follow the data type declaration and come before any `NOT NULL` statement.

### Constraints and keys

Constraints and their subset, keys, are a very important component of any database definition. They can quickly become very difficult to read and reason about though so it is important that a standard set of guidelines are followed.

#### Choosing keys

Deciding the column(s) that will form the keys in the definition should be a
carefully considered activity as it will effect performance and data integrity.

1. The key should be unique to some degree.
2. Consistency in terms of data type for the value across the schema and a lower
   likelihood of this changing in the future.
3. Can the value be validated against a standard format (such as one published by
   ISO)? Encouraging conformity to point 2.
4. Keeping the key as simple as possible whilst not being scared to use compound
   keys where necessary.

It is a reasoned and considered balancing act to be performed at the definition of a database. Should requirements evolve in the future it is possible to make changes to the definitions to keep them up to date.

#### Defining constraints

Once the keys are decided it is possible to define them in the system using
constraints along with field value validation.

- Tables must have at least one key to be complete and useful.
- Constraints should be given a custom name excepting `UNIQUE`, `PRIMARY KEY` and `FOREIGN KEY` where the database vendor will generally supply sufficiently intelligible names automatically.

##### Layout and order

- Specify the primary key first right after the `CREATE TABLE` statement.
- Constraints should be defined directly beneath the column they correspond to. Indent the constraint so that it aligns to the right of the column name.
- If it is a multi-column constraint then consider putting it as close to both column definitions as possible and where this is difficult as a last resort include them at the end of the `CREATE TABLE` definition.
- If it is a table-level constraint that applies to the entire table then it should also appear at the end.
- Use alphabetical order where `ON DELETE` comes before `ON UPDATE`.
- If it make senses to do so align each aspect of the query on the same character position. For example all `NOT NULL` definitions could start at the same character position. This is not hard and fast, but it certainly makes the code much easier to scan and read.

##### Validation

- Use `LIKE` and `SIMILAR TO` constraints to ensure the integrity of strings where the format is known.
- Where the ultimate range of a numerical value is known it must be written as a range `CHECK()` to prevent incorrect values entering the database or the silent truncation of data too large to fit the column definition. In the least it should check that the value is greater than zero in most cases.
- `CHECK()` constraints should be kept in separate clauses to ease debugging.

##### Example

```sql
CREATE TABLE Staff (
    PRIMARY KEY (StaffNum),
    StaffNum     INT(5)       NOT NULL,
    FirstName    VARCHAR(100) NOT NULL,
    PensInDrawer INT(2)       NOT NULL,
                 CONSTRAINT PensInDrawerRange
                 CHECK(PensInDrawer BETWEEN 1 AND 99)
)
```

### Designs to avoid

- Object-oriented design principles do not effectively translate to relational  database designs—avoid this pitfall.
- Placing the value in one column and the units in another column. The column should make the units self-evident to prevent the requirement to combine columns again later in the application. Use `CHECK()` to ensure valid data is inserted into the column.
- Entity–Attribute–Value(EAV) tables—use a specialist product intended for handling such schema-less data instead.
- Splitting up data that should be in one table across many tables because of arbitrary concerns such as time-based archiving or location in a multinational organisation. Later queries must then work across multiple tables with `UNION` rather than just simply querying one table.

## Sql Style Option 2

While the above is the preferred option, the option below is another acceptable style. A lot of the rules/suggestions above still hold for the below style.

- No tabs, 2 spaces.
- Align all columns to the first column on their own line
- Only one table should be in the FROM. Never use FROM-joins
- Explicitly use INNER JOIN not just JOIN, making multiple lines of INNER JOINs easier to scan
- Multiple WHERE clauses should go on different lines and begin with the SQL operator
- CASE statements aren't always easy to format but try to indent 2 spaces or align WHEN, THEN, and ELSE together inside CASE and END
- The body of a CTE must be one indent further than the WITH keyword. Open them at the end of a line and close them on a new line

### Examples

```sql
SELECT 
  CASE ZipCode
    WHEN '19720' 
      THEN 'Wilmington'
    WHEN '19711' 
      THEN 'Newark'
  END AS City
FROM OfficeLocation AS OL
INNER JOIN Staff AS ST ON OL.StaffId = ST.StaffID
WHERE
  StateCode = 'DE'
  AND OpeningTime BETWEEN 8 AND 9
  AND ZipCode IN ('19720','19711')
```

```sql
WITH backings_per_category AS (
  SELECT
    ...
), backers AS (
  SELECT
    ...
), backers_and_creators AS (
  ...
)
SELECT * FROM backers;
```

## References

https://about.gitlab.com/handbook/business-technology/data-team/platform/sql-style-guide/

https://www.sqlstyle.guide/

https://www.databasestar.com/sql-best-practices/

https://www.vertabelo.com/blog/an-unemotional-logical-look-at-sql-server-naming-conventions/

https://learn.microsoft.com/en-us/previous-versions/sql/sql-server-2008/ms124438(v=sql.100)?redirectedfrom=MSDN

END
