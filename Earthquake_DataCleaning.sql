use dataclean;
select * from dataclean.earthquake;
-- lets Confirm the data types of the variables
SELECT  DATA_TYPE,COLUMN_NAME from INFORMATION_SCHEMA.COLUMNS where
table_schema = 'dataclean' and table_name = 'earthquake' ;

-- This shows that the data are stored in wrong datatype;
-- Dates and time as well as some numerical values are stored with text.
-- This will throw up error during calculation and will also bring out wrong queries 
-- that will skew our analysis later
-- -------------------------------------------------------------------
-- 1 step (inconsistency removal)
-- Lets start by finding the length of the 'date' column
-- Handling data entry inconsistence
SELECT length(date), MAX(length(date)), min(length(date))
from dataclean.earthquake; -- min=10(2022-12-20)-> 10 character, Max=24 means it contains inconsistent data
-- Making sure that there are no other length apart from the two above
SELECT date from dataclean.earthquake 
where length(date) != 10 AND length(date) != 24; -- 0

-- since max(length(date))=24 let's find the count(date)
-- so to know how many inconsistent record we have in database
SELECT count(date) from dataclean.earthquake
where length(date) = 24; -- count=3
-- date with length 24 looks like -> 1975-02-23T02:58:41.000Z
-- now in order to remove this inconsistency we will use "LEFT" function
-- we are shifting 'date' with length of 10 to left so that we can update the records with 
-- length of 24 data 
SELECT LEFT(Date,10) from datacleaning.earthquake;
UPDATE dataclean.earthquake SET Date = LEFT(date,10);-- 3 rows were affected,firstly it throw 1725 ERROR
 -- I have to disable the go to EDIT -> PREFERENCES ->SQL EDITOR
--  and scroll to bottom to uncheck the safe mode (safe mode from query) -> CLICK OK
-- then go to QUERY-> RECONNECT TO SERVER

-- lets recheck if there are records with length 24
select date from dataclean.earthquake where length(date)=24;  -- 0 rows

-- STEP 2 To Standardize the Date column:
-- Now that all the columns have the same length (10).
-- To convert the Date ‘text datatype’ to ‘date datatype’;
 -- A new column Date2 was created
-- and the STR_TO_DATE function will be used to convert the initial values from text to date.

ALTER TABLE dataclean.earthquake
ADD column Date2 date after Date;

UPDATE dataclean.earthquake
SET Date2 = STR_TO_DATE(Date, '%d/%m/%Y');  -- throws error of -> Incorrect datetime value: '02-01-1965' for function str_to_date

-- to know cause of error
Select date, str_to_date(Date, '%d-%m-%Y') from dataclean.earthquake
where str_to_date(Date, '%d-%m-%Y') is null;
-- above query returns 3 rows
-- 1975-02-23	
-- 1985-04-28	
-- 2011-03-13	(yyyy/mm/dd)
-- This query shows that I have 3 irregular date entry format that is different from the 
-- rest that has this format dd/mm/yyyy “01-02-1965". These I changed with the UPDATE and REPLACE function.

update dataclean.earthquake 
SET Date = replace(date,'1975-02-23','23-02-1975' );

update dataclean.earthquake 
SET Date = replace(date,'1985-04-28','28-04-1985' );

update dataclean.earthquake 
SET Date = replace(date,'2011-03-13','13-03-2011' );

-- After all these processes; I have to standardize the Date column again
UPDATE dataclean.earthquake
SET Date2 = STR_TO_DATE(Date, '%d-%m-%Y'); -- 23412 rows returned

select date, date2 from dataclean.earthquake;

-- step 3 Standardize time column 
-- A new column Time2 was created 
-- the CAST function will be used to convert the initial values from text to time.
select cast(time as time) from dataclean.earthquake;

Alter table dataclean.earthquake add Time2 time after time;

Update dataclean.earthquake
set Time2 = cast(time as time); -- Truncated incorrect time value: '1975-02-23T02:58:41.000Z'

-- The Update function for Time threw up error which I traced with the LENGTH function;
-- which shows that Time column have varying string length of 8 and 24, 
-- of which 3 rows out of the whole 23k+ rows are having the length 24.
SELECT time, length(time) from dataclean.earthquake; -- i noticed that length is 8 for most of cols
SELECT time, length(time) from dataclean.earthquake where length(time) >8 ; 
-- so i verified if we have any col with value of length greater than 8
-- turns out we have 3 records with length 24

-- to fix length of 3 records and update column 'Time' using the UPDATE , REPLACE & SUBSTR function
update dataclean.earthquake 
SET time = replace (time,'1975-02-23T02:58:41.000Z',substr(12,8));

update dataclean.earthquake 
SET time = replace (time,'1985-04-28T02:53:41.530Z',substr(12,8));

update dataclean.earthquake 
SET time = replace (time,'2011-03-13T02:23:34.520Z',substr(12,8));

-- now lets verify we dont have any other time records other than the length of 8 and 24 
SELECT time, length(time) from dataclean.earthquake where length(time) !=8 AND length(time)!= 24; 
-- we have some records with the length of 7 which is less than 8 , which is fine cuz they 
-- wont make any inconsistency in the calculation

-- now updating the time2 column having the datatype of 'time' type 
update dataclean.earthquake 
set Time2 = Time ;


-- STEP 4
-- CHECKING AND HANDLING OF BLANK VALUES
select * from dataclean.earthquake where depth=' ';
select count(depth) from dataclean.earthquake  where depth=' '; -- 170 blanks
update dataclean.earthquake 
SET depth = case 
when depth=' ' then 0.0
else depth
END;

-- also updating the deptherror column which contains NULL
update dataclean.earthquake 
SET depth_Error = case 
when depth_Error=' ' then 0.0
else depth_Error
END;


-- i see my columns in the DB has spaces in between so I'm renaming them using back ticks ``
Alter table dataclean.earthquake rename column `Azimuthal Gap` to  AzimuthalGap;
Alter table dataclean.earthquake rename column `Root Mean Square` to  Root_Mean_Square;
Alter table dataclean.earthquake rename column `Magnitude Seismic Stations` to  Magnitude_Seismic_Stations;
Alter table dataclean.earthquake rename column `Horizontal Distance` to  Horizontal_Distance;
Alter table dataclean.earthquake rename column `Magnitude Error` to  Magnitude_Error;
Alter table dataclean.earthquake rename column `Horizontal Error` to  Horizontal_Error;
Alter table dataclean.earthquake rename column `Depth Error` to  Depth_Error;
Alter table dataclean.earthquake rename column `Depth Seismic Stations` to  Depth_Seismic_Stations;

-- rechecking the blanks 
select count(depth_error) from dataclean.earthquake  where depth_error=' '; -- 0

-- STEP 5
-- CONVERTING THE NUMERICAL DATA THAT WAS STORED AS TEXT TO DOUBLE
-- IMPORTANT --
-- i tried using alter/modify command to change the datatype but can't 
-- due to error Code: 1265. Data truncated for column 'AzimuthalGap' at row 1	
Alter table dataclean.earthquake Modify column Magnitude_Seismic_Stations double;



-- so i used cast , alter/add column , then updated value making a new column with double datatype
select cast(AzimuthalGap as double) from dataclean.earthquake;
Alter table dataclean.earthquake add Azimuthal_Gap double after AzimuthalGap ;
Update dataclean.earthquake
set AzimuthalGap = cast(Azimuthal_Gap as double); 

select cast(Depth_Seismic_Stations as double) from dataclean.earthquake;
Alter table dataclean.earthquake add DepthSeismicStations double after Depth_Seismic_Stations ;
Update dataclean.earthquake
set Depth_Seismic_Stations = cast(DepthSeismicStations as double); 

select cast(Root_Mean_Square as double) from dataclean.earthquake;
Alter table dataclean.earthquake add RootMeanSquare double after Root_Mean_Square ;
Update dataclean.earthquake
set Root_Mean_Square = cast(RootMeanSquare as double); 

select cast(Horizontal_Error as double) from dataclean.earthquake;
Alter table dataclean.earthquake add HorizontalError double after Horizontal_Error ;
Update dataclean.earthquake
set Horizontal_Error = cast(HorizontalError as double); 

select cast(Horizontal_Distance as double) from dataclean.earthquake;
Alter table dataclean.earthquake add HorizontalDistance double after Horizontal_Distance ;
Update dataclean.earthquake
set Horizontal_Distance = cast(HorizontalDistance as double); 

select cast(Magnitude_Seismic_Stations as double) from dataclean.earthquake;
Alter table dataclean.earthquake add MagnitudeSeismicStations double after Magnitude_Seismic_Stations ;
Update dataclean.earthquake
set Magnitude_Seismic_Stations = cast(MagnitudeSeismicStations as double); 

-- now that we have so many columns which we dont need lets delete them using ALTER/DROP
select * from dataclean.earthquake;
alter table dataclean.earthquake
Drop column date;
alter table dataclean.earthquake
Drop column time;
alter table dataclean.earthquake Drop column Depth_Error;
alter table dataclean.earthquake Drop column Depth_Seismic_Stations;
alter table dataclean.earthquake Drop column Horizontal_Distance;
alter table dataclean.earthquake Drop column Horizontal_Error;
alter table dataclean.earthquake Drop column AzimuthalGap;
alter table dataclean.earthquake Drop column Magnitude_Seismic_Stations;
alter table dataclean.earthquake Drop column Root_Mean_Square;
alter table dataclean.earthquake Drop column Horizontal_Error;

-- Checking for Duplicates using CTE and ROW NUM:

 with t1 
 as 
 (Select *, row_number() over(partition by Date2,time2,Latitude,Longitude order by ID) rownum
from dataclean.earthquake ) 
select count(*) from t1 where rownum>1; -- 0 count means no duplicate rows exists

-- STEP 6
-- CREATING NEW COLUMNS (YEAR, MONTH, DAY, WEEK, DAY OF WEEK) FROM THE DATE2 COLUMN
-- using extract function to get the value from date2 column

-- Year
     -- select EXTRACT (year from date2) from dataclean.earthquake; -- extract throws error 
      -- lets find an alternative
      -- SELECT DATEPART(year, date2) from dataclean.earthquake; --throws error 
      
-- YEAR EXTRACTED using Alter , UPDATE/EXTRACT
    alter table dataclean.earthquake add column Year int after time2;
	update dataclean.earthquake set Year =
    extract(Year from Date2);      -- extract worked with update command 23412 rows affected
 
 -- ADDING MONTH
	alter table dataclean.earthquake add column Month int after Year;
    update dataclean.earthquake set Month =
    extract(Month from Date2);   
    
-- ADDING WEEK ,DAY NAME
alter table dataclean.earthquake add column week int after month;
update dataclean.earthquake set Week =
week(Date2, 0);

-- DAY OF WEEK
alter table dataclean.earthquake add column day char(17) after week;
update dataclean.earthquake set day=
dayname(date2);
select max(Magnitude) from dataclean.earthquake ;

-- CHECKING FOR OUTLIERS 
-- KEEPING IN KNOWLEDGE that my range is 1965 - 2016 and magnitude should be greater than 5.5

select year from dataclean.earthquake 
where YEAR < 1965 or Year >2016;  -- 0

select magnitude from dataclean.earthquake 
where Magnitude < 5.5; -- 0



