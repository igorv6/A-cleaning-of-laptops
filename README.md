# Data Cleaning Using SQL

Data cleaning is an essential part of the data preparation process that focuses on recognizing and rectifying errors, inconsistencies, and inaccuracies within your dataset. This step ensures that the data is accurate, reliable, and appropriate for analysis or modeling. In this Cleaning phase, I will carry out essential data cleaning tasks on a dataset contains all details of various laptops available in the market.
The dataset used for the cleaning can be found on the Kaggle website and can be accessed through the link https://www.kaggle.com/datasets/ehtishamsadiq/uncleaned-laptop-price-dataset.
After downloaded the CSV file from Kaggle, I import the CSV file into MySQL.

## Data Cleaning Process
After creating the table directly using mysql, below are the processes that I used:
### 1. Create a Backup
Before starting the data cleaning it is good practice to create the backup of the original dataset and with the same structure in order to be sure to have a copy to use in case anything goes wrong during the cleaning process.
After creating the backup data, I insert the same value from the original dataset
```sql
CREATE TABLE laptop_backup LIKE laptopdata_uncleaned;

INSERT INTO laptop_backup
SELECT * FROM laptopdata_uncleaned;
```
### 2. Check the size of the dataset and the structure of our table : This dataset contains 1274 rows and 12 columns.
```sql
SELECT COUNT(*) FROM laptopdata_uncleaned;

DESCRIBE laptopdata_uncleaned;
```
![image](https://github.com/user-attachments/assets/d5f30c8d-30eb-48bd-97f0-b142f6e29db2)
### 3. Rename the first column "Unnamed: 0" with the simple name "Index".
```sql
ALTER TABLE laptopdata_uncleaned CHANGE "Unnamed: 0" "Index" INT;
```
### 4. Check and change some datatype into the columns in the dataset
As seen through the DESCRIBE table command, there are some datatypes that need to be changed.
Starting from the most simple
```sql
ALTER TABLE laptopdata_uncleaned MODIFY COLUMN Price INT;
ALTER TABLE laptopdata_uncleaned MODIFY COLUMN Company VARCHAR (25);
ALTER TABLE laptopdata_uncleaned MODIFY COLUMN TypeName VARCHAR (25);
ALTER TABLE laptopdata_uncleaned MODIFY COLUMN Ram VARCHAR (25);
ALTER TABLE laptopdata_uncleaned MODIFY COLUMN OpSys VARCHAR (25);
```
The others needs some other changes as below:
 Column weight. First delete the word "Kg" in each rows and then we can change the datatype
 ```sql
UPDATE laptopdata_uncleaned
set Weight = REPLACE(Weight,'kg','');
ALTER TABLE laptopdata_uncleaned CHANGE COLUMN Weight Weight_kg DECIMAL(4,2);
-- I received an Error, there is a "?" inserted as weight.
SELECT * FROM laptopdata_uncleaned WHERE Weight = "?" ;
-- Checking on DELL website I can see that the weight is 1.6 kg, so I update this row
UPDATE laptopdata_uncleaned
SET Weight = 1.6
WHERE weight = '?';
-- Now I can change the datatype and name
ALTER TABLE laptopdata_uncleaned CHANGE COLUMN Weight Weight_kg DECIMAL(4,2);
```
Before  --->![image](https://github.com/user-attachments/assets/3a1f00a9-b132-444b-bffb-ed07d495951b)                After  --->![image](https://github.com/user-attachments/assets/3ca97a52-b6a1-4810-b286-795cd27118b5)

Column price, before change the data type, I need to use the sql function ROUND
 ```sql
UPDATE laptopdata_uncleaned
SET Price=ROUND(Price);
ALTER TABLE laptopdata_uncleaned MODIFY COLUM PRICE INT;
```
Before -->![image](https://github.com/user-attachments/assets/9ffbdf2b-fbb7-41bf-bfa2-065ac8919cb0)               After -->![image](https://github.com/user-attachments/assets/73e9805e-a016-407d-b92b-f1550508db0d)

Lastly, I modify the datatype
 ```sql
ALTER TABLE laptopdata_uncleaned MODIFY Inches DECIMAL (4,2);
```
### 5. Check for NULL values
```sql
SELECT * FROM laptopdata_uncleaned
WHERE "Index" IS NULL
OR Company IS NULL
OR TypeName IS NULL
OR Inches IS NULL
OR ScreenResolution IS NULL
OR Cpu IS NULL
OR Ram IS NULL
OR Memory IS NULL
OR Gpu IS NULL
OR OpSys IS NULL
OR Weight IS NULL
OR Price IS NULL;
```
I find an entire row with NULL value

![image](https://github.com/user-attachments/assets/b2615b0b-2bce-47f0-b50b-9d13f08ccb6f)

so I can delete it:
```sql
DELETE FROM laptopdata_uncleaned
WHERE Company IS NULL; 
```
### 6. Check for duplicates
Common Table Expressions (CTEs) can be effectively used to identify duplicate records in a SQL table. By using a CTE alongside the ROW_NUMBER() function, we can assign a unique sequential integer to each row within a partition of a dataset. This allows us to identify duplicates based on specified columns.
The CTE computes a row number for each record in the laptopdata_uncleaned table using the ROW_NUMBER() function. This function partitions the data by several columns (Company, TypeName, Inches, CPu, Ram, Weight, and Price) and orders it by the pc field. Each unique combination of these columns will get a distinct row number starting from 1.
The main query then selects all records from laptopdata_uncleaned where the corresponding pc identifier appears in the set of duplicates (i.e., those records where row_num is greater than 1). Thus, it filters out only those entries that have duplicates based on the specified fields.
```sql
WITH RowNumCte AS (
SELECT *,
 ROW_NUMBER() OVER (PARTITION BY Company, TypeName, Inches, CPu, Ram, Weight_kg, Price ORDER BY "Index" AS row_num
FROM laptopdata_uncleaned
)
SELECT *  FROM laptopdata_uncleaned
WHERE "Index" IN (
SELECT "Index" FROM RowNumCte WHERE row_num > 1
);
```
the entire query returns all records from the laptopdata_uncleaned table that are duplicates (i.e., appear more than once) based on the defined criteria (Company, TypeName, Inches, CPu, Ram, Weight_kg, Price).

![image](https://github.com/user-attachments/assets/a60bf351-0c56-4e8a-bc84-934a96f2ed4d)

 And now, I delete them
 
 ```sql
WITH RowNumCte AS (
SELECT *,
 ROW_NUMBER() OVER (PARTITION BY Company, TypeName, Inches, CPu, Ram, Weight_kg, Price ORDER BY "Index" AS row_num
FROM laptopdata_uncleaned
)
DELETE  FROM laptopdata_uncleaned
WHERE "Index" IN (
SELECT "Index" FROM RowNumCte WHERE row_num > 1
);
```
### 7. Check for outliers
I want to see if for numeric values there are some outliers
 ```sql
-- Inches colums:
SELECT MIN(Inches),
MAX(Inches)
FROM laptopdata_uncleaned;

-- Price Column:
SELECT MIN(Price), 
MAX(Price)
FROM laptopdata_uncleaned; 
-- Price column contains Minum price 1 and Max Price 324955, of course we will have to check better in Price column

-- Weight_kg Column 
SELECT MIN(Weight),
MAX(Weight)
FROM laptopdata_uncleaned; 
-- Seems there is some laptop with weight 0.00, just a quickly check..
SELECT * FROM laptopdata_uncleaned
WHERE Weight=0.00;
-- Since is only one row, im going to insert the correct weight checked on Dell website
UPDATE laptopdata_uncleaned
SET Weight = 2.00
WHERE weight = 0.00;
```
### 8. Check if there are some similar values caused by space character
The TRIM() function removes the space character OR other specified characters from the start or end of a string.
 ```sql
SELECT * FROM laptopdata_uncleaned;
SELECT Distinct Company FROM laptopdata_uncleaned;
SELECT Distinct TypeName FROM laptopdata_uncleaned; 
 ```
 I notice that into TypeName column Notebook is repeated two times, I'm goin to fix it with the trim function
   ```sql
UPDATE laptopdata_uncleaned
SET TypeName = TRIM(TypeName);
 ```

Before --> ![image](https://github.com/user-attachments/assets/247de141-e819-4da9-8d7c-596b9faf9354)          After --> ![image](https://github.com/user-attachments/assets/888d3f43-9b87-4713-975e-0ec2e1752740)

### 9. Before finishing our cleaning analysis, i'm going to add some columns to improve our analysis 
 ```sql
ALTER TABLE laptopdata_uncleaned
ADD COLUMN cpu_brand VARCHAR(255) AFTER cpu,
ADD COLUMN cpu_name VARCHAR(255) AFTER cpu_brand,
ADD COLUMN cpu_speed DECIMAL(10,1) AFTER cpu_name;

-- updating the values in new column
UPDATE laptopdata_uncleaned
SET cpu_brand = substring_index(Cpu,' ',1);

update laptopdata_uncleaned
SET cpu_speed = replace(substring_index(Cpu,' ',-1),'GHz','');

update laptopdata_uncleaned
SET cpu_name = replace(replace(Cpu,cpu_brand,' ' ),substring_index(Cpu,' ',-1),' ');
 ```
