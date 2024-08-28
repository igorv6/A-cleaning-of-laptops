-- Before starting our analysis, I create a backup table
CREATE TABLE laptop_backup LIKE laptopdata_uncleaned;
INSERT INTO laptop_backup SELECT * FROM laptopdata_uncleaned;

-- Check the size of the dataset
SELECT COUNT(*) FROM laptopdata_uncleaned;

-- Check the structure of the table and the data type and see if there is something to change
DESCRIBE laptopdata_uncleaned;
-- Checking the datatype of each column, I see that there are some columns that need to be modified:
-- 1) Rename the column "Unnamed: 0"
ALTER TABLE laptopdata_uncleaned CHANGE `Unnamed: 0` `Laptop` INT;

-- 2) Change datatype into columns
ALTER TABLE laptopdata_uncleaned MODIFY Inches DECIMAL (4,2);
-- For Column price:
UPDATE laptopdata_uncleaned
SET Price=ROUND(Price);
-- Other Columns
ALTER TABLE laptopdata_uncleaned MODIFY COLUMN Price INT;
ALTER TABLE laptopdata_uncleaned MODIFY COLUMN Company VARCHAR (25);
ALTER TABLE laptopdata_uncleaned MODIFY COLUMN TypeName VARCHAR (25);
ALTER TABLE laptopdata_uncleaned MODIFY COLUMN Ram VARCHAR (25);
ALTER TABLE laptopdata_uncleaned MODIFY COLUMN OpSys VARCHAR (25);
-- For Column weight. First delete the word "Kg" in each row
UPDATE laptopdata_uncleaned
set Weight = REPLACE(Weight,'kg','');
ALTER TABLE laptopdata_uncleaned CHANGE COLUMN Weight Weight_kg DECIMAL (4,2);
-- Changing the datatype
ALTER TABLE laptopdata_uncleaned MODIFY COLUMN Weight DECIMAL (10,2);
-- I received an Error, there is a "?" inserted as weight.
SELECT * FROM laptopdata_uncleaned WHERE Weight = "?" ;
-- Checking on DELL website I can see that the weight is 1.6 kg, so I update this row
UPDATE laptopdata_uncleaned
SET Weight = 1.6
WHERE weight = '?';
-- Now I can change the datatype in Column "Weight"

-- 3) Check for empty/Null Values
SELECT * FROM laptopdata_uncleaned
WHERE "laptop"= '' 
OR Company= ''
OR TypeName= ''
OR Inches= ''
OR ScreenResolution= ''
OR Cpu= ''
OR Ram=''
OR Memory=''
OR Gpu=''
OR OpSys=''
OR Weight=''
OR Price='';
-- No empy cell in this dataset

-- 4) Check for null values
SELECT * FROM laptopdata_uncleaned
WHERE "laptop" IS NULL
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
-- we have a row with NUll values, I will delet it
DELETE FROM laptopdata_uncleaned
WHERE Company IS NULL; 

-- 5) Check for duplicate
WITH RowNumCte AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY Company, TypeName, Inches, CPu, Ram, Weight, Price ORDER BY pc) AS row_num
    FROM laptopdata_uncleaned
)
SELECT *  FROM laptopdata_uncleaned
WHERE laptop IN (
    SELECT pc FROM RowNumCte WHERE row_num > 1
);

-- Delete duplicates
WITH RowNumCte AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY Company, TypeName, Inches, CPu, Ram, Weight, Price ORDER BY pc) AS row_num
    FROM laptopdata_uncleaned
)
DELETE  FROM laptopdata_uncleaned
WHERE laptop IN (
    SELECT pc FROM RowNumCte WHERE row_num > 1
);

SELECT * FROM laptopdata_uncleaned;
-- 6) Check for outliers
-- Inches colums:
SELECT MIN(Inches),
MAX(Inches)
FROM laptopdata_uncleaned;
-- Price Column:
SELECT MIN(Price), 
MAX(Price)
FROM laptopdata_uncleaned; 
-- Price column contains Minum price 1 and Max Price 324955, of course we will have to check better in Price column
-- Weight Column 
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

-- 7) Check if there are some duplicate values caused by spaces, I will use the TRIM function
SELECT * FROM laptopdata_uncleaned;
SELECT Distinct Company FROM laptopdata_uncleaned;
SELECT Distinct TypeName FROM laptopdata_uncleaned; 
-- I notice that Notebook is repeated two times, I'm goin to fix it with the trim function
UPDATE laptopdata_uncleaned
SET TypeName = TRIM(TypeName);

-- 8) Before finishing our cleaning analysis, i'm goign I add some columns to improve our analysis 
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


