/*
-- Author: Daniel Quach
-- Name: SQL_NASHVILLE_HOUSING_DATA_PORTFOLIO
-- Create date: 2/28/2023
-- Description: Using the Nashville data excel spreadsheet,
-- the following queries conducts various data cleaning exercises.
-- It includes updating null values using duplicate values, 
-- slicing the owner and address into multiple columns for organization,
-- updating values within the SoldAsVacant column for consistency 
-- and removing duplicate and unused columns. 
*/


-- CONVERT SALEDATE --
/* Remove the time in the saledate column (2014-07-25 00:00:00.000)
by creating a new column and converting the saledate to the date variable)
*/
ALTER TABLE NashvilleHousing
ADD SaleDateConverted Date;

Update NashvilleHousing
SET  SaleDateConverted = CONVERT(Date, SaleDate)


-- POPULATE PROPERTY ADDRESS DATA 
--SELECT *
--FROM dbo.NashvilleHousing
----WHERE PropertyAddress is null
--ORDER BY ParcelID


-- SELF JOIN TO FIND NULL PROPERTY ADDRESS --
SELECT h1.ParcelID, h1.PropertyAddress, h2.ParcelID, 
h2.PropertyAddress, ISNULL(h1.PropertyAddress, h2.PropertyAddress)
FROM dbo.NashvilleHousing h1
JOIN dbo.NashvilleHousing h2
	ON h1.ParcelID = h2.ParcelID
	AND h1.[UniqueID ] <> h2.[UniqueID ]
WHERE h1.PropertyAddress is null


-- UPDATE NULL VALUES TO CORRECT PROPERTY ADDRESS ID --
UPDATE h1
SET PropertyAddress = ISNULL(h1.PropertyAddress, h2.PropertyAddress)
FROM dbo.NashvilleHousing h1
JOIN dbo.NashvilleHousing h2
	ON h1.ParcelID = h2.ParcelID
	AND h1.[UniqueID ] <> h2.[UniqueID ]
WHERE h1.PropertyAddress is null


-- SPLIT ADDRESS INTO SEPERATE COLUMNS ADDRESS, CITY, STATE --
/* Separates the property address to property address and property city 
by creating two new columns and setting the substring to those columns. 
*/

ALTER TABLE NashvilleHousing
ADD PropertySplitAddress Nvarchar(255);

ALTER TABLE NashvilleHousing
ADD PropertySplitCity Nvarchar(255);

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1,  CHARINDEX(',', PropertyAddress) -1) 

UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))


-- SEPARATING OWNER ADDRESS --
/* Separates the owner address (5525  CHERRYWOOD DR, BRENTWOOD, TN)
to OwnerSplitAddress (5525 CHERRYWOOD,DR), OwnerSplitCity (BRENTWOOD), OwnerSplitState (TN)
by adding columns then updating the columns through parsing. 
*/

ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress Nvarchar(255);
ALTER TABLE NashvilleHousing
ADD OwnerSplitCity Nvarchar(255);
ALTER TABLE NashvilleHousing
ADD OwnerSplitState Nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.' ),3)
UPDATE NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.' ),2)
UPDATE NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.' ),1)


-- CHANGE Y AND N  TO YES AND NO IN SOLD AS VACANT FIELD --
/*
The SoldAsVacantt column contains "Yes","Y","No","N" strings. For consistency, the CASE statement 
will convert the "Y" and "N" values into "Yes" and "No" strings respectively. The table will
then be updated to reflect these changes. 
*/
SELECT DISTINCT(SoldAsVacant), Count(SoldAsVacant) AS Counts
FROM dbo.NashvilleHousing
GROUP BY SoldAsVacant

SELECT SoldAsVacant,
	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		 WHEN SoldAsVacant = 'N' THEN 'No'
		 ELSE SoldAsVacant
		 END
FROM dbo.NashvilleHousing

UPDATE NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		 WHEN SoldAsVacant = 'N' THEN 'No'
		 ELSE SoldAsVacant
		 END


-- REMOVE DUPLICATES -- 
/*
For practice, the duplicate values and unused columns will be removed
*/
WITH RowNumCTE AS(
SELECT *, 
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID,
			 	 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY UniqueID)
				 Row_Num
FROM dbo.NashvilleHousing
)

SELECT *
FROM RowNumCTE
WHERE Row_Num > 1


-- DELETE UNUSED COLUMNS  -- 
SELECT *
FROM dbo.NashvilleHousing

ALTER TABLE dbo.NashvilleHousing
DROP COLUMN OwnerAddress, 
			TaxDistrict, 
			PropertyAddress,
			SaleDate
