/*

Cleaning data in SQL Queries

*/

Select *
From PortfolioProject..NashvilleHousing

------------------------------------------------------------------------------------------------------------------------------

-- Standadize Date Format

Alter Table NashvilleHousing
Add SaleDate2 Date;

Update NashvilleHousing
Set SaleDate2 = Convert(date, SaleDate)

Select SaleDate, SaleDate2
From PortfolioProject..NashvilleHousing

------------------------------------------------------------------------------------------------------------------------------

-- Populate Property Address data

Select *
From PortfolioProject..NashvilleHousing
Where PropertyAddress is null

Select *
From PortfolioProject..NashvilleHousing

Select count(*) value_not_nulls, count(*) - count(PropertyAddress) value_nulls
From PortfolioProject..NashvilleHousing

SELECT a.[UniqueID ], b.[UniqueID ], a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
FROM PortfolioProject..NashvilleHousing a
JOIN PortfolioProject..NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL


BEGIN TRANSACTION
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject..NashvilleHousing a
JOIN PortfolioProject..NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL
COMMIT

------------------------------------------------------------------------------------------------------------------------------

-- Split Address into seperated fields (Add, City, State)

-- PropertyAddress

Select PropertyAddress
From PortfolioProject..NashvilleHousing

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 ) PropertySplitAddress
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) PropertySplitCity
FROM PortfolioProject..NashvilleHousing

ALTER TABLE PortfolioProject..NashvilleHousing
ADD PropertySplitAddress NVARCHAR(255);

UPDATE PortfolioProject..NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 )

ALTER TABLE PortfolioProject..NashvilleHousing
ADD PropertySplitCity NVARCHAR(255);

UPDATE PortfolioProject..NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))

-- Owner Address

SELECT
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)
, PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)
, PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM PortfolioProject..NashvilleHousing

ALTER TABLE PortfolioProject..NashvilleHousing
ADD OwnerSplitAddress NVARCHAR(255);

UPDATE PortfolioProject..NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

ALTER TABLE PortfolioProject..NashvilleHousing
ADD OwnerSplitCity NVARCHAR(255);

UPDATE PortfolioProject..NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

ALTER TABLE PortfolioProject..NashvilleHousing
ADD OwnerSplitState NVARCHAR(255);

UPDATE PortfolioProject..NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

------------------------------------------------------------------------------------------------------------------------------

-- Change Y and N to Yes and No in 'Sold as Vacant' field

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM PortfolioProject..NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2

SELECT SoldAsVacant 
, CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
		END
FROM PortfolioProject..NashvilleHousing

UPDATE PortfolioProject..NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
						WHEN SoldAsVacant = 'N' THEN 'No'
						ELSE SoldAsVacant
						END

------------------------------------------------------------------------------------------------------------------------------

-- Delete Unused Columns

SELECT *
FROM PortfolioProject..NashvilleHousing

ALTER TABLE PortfolioProject..NashvilleHousing
DROP COLUMN PropertyAddress, SaleDate, OwnerAddress

------------------------------------------------------------------------------------------------------------------------------

-- Remove Duplicates

WITH RowNumCte AS (
	SELECT *,
	ROW_NUMBER() OVER (
		PARTITION BY 
			[ParcelID]
		  ,[LandUse]
		  ,[SalePrice]
		  ,[LegalReference]
		  ,[SoldAsVacant]
		  ,[OwnerName]
		  ,[Acreage]
		  ,[TaxDistrict]
		  ,[LandValue]
		  ,[BuildingValue]
		  ,[TotalValue]
		  ,[YearBuilt]
		  ,[Bedrooms]
		  ,[FullBath]
		  ,[HalfBath]
		  ,[SaleDate2]
		  ,[PropertySplitCity]
		  ,[PropertySplitAddress]
		  ,[OwnerSplitAddress]
		  ,[OwnerSplitCity]
		  ,[OwnerSplitState]
		ORDER BY
			UniqueID
			) row_num
	FROM PortfolioProject..NashvilleHousing
)
--SELECT *
DELETE
FROM RowNumCte
WHERE row_num > 1
------------------------------------------------------------------------------------------------------------------------------

