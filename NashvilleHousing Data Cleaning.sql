SELECT uniqueid, parcelid, landuse, propertyaddress, saledate, saleprice, legalreference, soldasvacant, ownername, owneraddress, acreage, taxdistrict, landvalue, buildingvalue, totalvalue, yearbuilt, bedrooms, fullbath, halfbath
	FROM public.NashvilleHousing;

SELECT * from public.nashvillehousing -- 56477
-------------------------------------
/*DROP TABLE*/

TRUNCATE TABLE  public.NashvilleHousing



------------------------------------------------------
/* Create Table */

 CREATE TABLE IF NOT EXISTS NashvilleHousing(
 UniqueID Varchar PRIMARY KEY,
 ParcelID Varchar ,
 LandUse varchar,
 PropertyAddress varchar,
 SaleDate varchar,
 SalePrice varchar,
 LegalReference varchar,
 SoldAsVacant varchar,
 OwnerName varchar,
 OwnerAddress varchar,
 Acreage varchar,
 TaxDistrict varchar,
 LandValue varchar,
 BuildingValue varchar,
 TotalValue varchar,
 YearBuilt varchar,
 Bedrooms varchar,
 FullBath varchar,
 HalfBath varchar );
 
 ALTER TABLE public.NashvilleHousing
 ALTER COLUMN SaleDate TYPE varchar;
 

---------------------------------------------------------- 


/* Cleaning data in SQL Queries */

-------------------------------------------------------------------------------------------------------------------------------

-- Standardize Date Format

Select saledate,to_date(saledate,'Month dd, yyyy')
from public.nashvillehousing

Update public.nashvillehousing
SET saledate =to_date(saledate,'Month dd, yyyy')

 --------------------------------------------------------------------------------------------------------------------
 /* Arranging Property address */
 
 Select *
From public.NashvilleHousing
--Where PropertyAddress is null
order by ParcelID

Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress,COALESCE(a.PropertyAddress,b.PropertyAddress) as "CONVERTED COLUMN"
From public.NashvilleHousing a
JOIN public.NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueId
Where a.PropertyAddress is null


UPDATE public.NashvilleHousing as ap
SET PropertyAddress = COALESCE(ap.PropertyAddress,b.PropertyAddress)
From public.NashvilleHousing as b
where ap.ParcelID = b.ParcelID
AND ap.UniqueID <> b.UniqueId
AND ap.PropertyAddress is null

---------------------------------------------------
/* Breaking out Property address and owner addess columsn into Address, City and State columns*/

Select PropertyAddress
From NashvilleHousing
--Where PropertyAddress is null
--order by ParcelID

SELECT
SPLIT_PART(PropertyAddress,',',1) as ADDRESS,
SPLIT_PART(PropertyAddress,',',2) as CITY
From NashvilleHousing

ALTER TABLE NashvilleHousing
Add PropertySplitAddress VARCHAR(255);

Update NashvilleHousing
SET PropertySplitAddress = SPLIT_PART(PropertyAddress,',',1)

ALTER TABLE NashvilleHousing
Add PropertySplitCity VARCHAR(255);

Update NashvilleHousing
SET PropertySplitCity = SPLIT_PART(PropertyAddress,',',2)


Select
OwnerAddress
From NashvilleHousing

Select a.ParcelID, a.OwnerAddress, b.ParcelID, b.OwnerAddress,COALESCE(a.OwnerAddress,b.OwnerAddress) as "CONVERTED COLUMN"
From public.NashvilleHousing a
JOIN public.NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueId
Where a.OwnerAddress is null

Select a.PropertyAddress,b.OwnerAddress 
from public.NashvilleHousing AS a 
LEFT JOIN 
public.NashvilleHousing AS b
ON  a.UniqueID =b.UniqueID
where b.OwnerAddress is NULL 

Update public.NashvilleHousing b
SET OwnerAddress = COALESCE(b.OwnerAddress,a.PropertyAddress)
FROM public.NashvilleHousing a
where a.UniqueID = b.UniqueId
AND b.OwnerAddress is null

SELECT
SPLIT_PART(OwnerAddress,',',1) as ADDRESS,
SPLIT_PART(OwnerAddress,',',2) as CITY,
CASE 
WHEN (SPLIT_PART(OwnerAddress,',',3) is not NULL) then CONCAT('TN')
ELSE (SPLIT_PART(OwnerAddress,',',3))
END
From NashvilleHousing

ALTER TABLE NashvilleHousing
Add OwnersplitAddress VARCHAR(255);

Update NashvilleHousing
SET OwnersplitAddress = SPLIT_PART(OwnerAddress,',',1)

ALTER TABLE NashvilleHousing
Add OwnerCity VARCHAR(255);

Update NashvilleHousing
SET OwnerCity = SPLIT_PART(OwnerAddress,',',2) 

ALTER TABLE NashvilleHousing
Add OwnerState Varchar;

Update NashvilleHousing
SET OwnerState =
CASE 
WHEN (SPLIT_PART(OwnerAddress,',',3) is not NULL) then CONCAT('TN')
ELSE (SPLIT_PART(OwnerAddress,',',3))
END
		  
/*CREATE OR REPLACE FUNCTION PUBLIC.GetOwnerAddress()
		  RETURNS TABLE
		  (
		  OwnerAddress Varchar 
		  )
		  LANGUAGE 'plpgsql'
 AS
  $BODY$
 BEGIN
	RETURN QUERY
		  SELECT 
		  SPLIT_PART(nh.OwnerAddress,',',1) as ADDRESS,
          SPLIT_PART(nh.OwnerAddress,',',2) as CITY,
          SPLIT_PART(nh.OwnerAddress,',',3) as STATE
		  FROM NashvilleHousing as nh;
		  
  END;
  $BODY$;
  
  SELECT * FROM PUBLIC.GetOwnerAddress(); */
	
-----------------------------------------------------------------
/* Sold As vacant */

/* Stored procedure created for updating  Y to Yes and N to No in SoldasVacant column */

CREATE PROCEDURE procupdatesold()
LANGUAGE 'plpgsql'
AS
$$
BEGIN
Update NashvilleHousing
SET SoldAsVacant = CASE When SoldAsVacant = 'Y' THEN 'Yes'
	   When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END;
	   COMMIT;

Select Distinct(SoldAsVacant), Count(SoldAsVacant)
From NashvilleHousing
Group by SoldAsVacant
order by 2
/*
"Y"	52
"N"	399
"Yes"	4623
"No"	51403 */

Select SoldAsVacant
, CASE When SoldAsVacant = 'Y' THEN 'Yes'
	   When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END
From NashvilleHousing

END;
$$;

CALL procupdatesold()

---------------------------------------------------------------------
--- Delete duplicate rows -- 104 rows 

WITH RowNumCTE AS(
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					)row_num

From NashvilleHousing
)

Select *
From RowNumCTE
Where row_num > 1
Order by PropertyAddress