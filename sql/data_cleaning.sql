-- Inspect raw imported data
SELECT * 
FROM traders_pnl.clients;

-- Create a working copy of the raw table to preserve original data untouched
CREATE TABLE clients_clean AS
SELECT * FROM traders_pnl.clients;

-- Verify the copy was created successfully
SELECT * 
FROM traders_pnl.clients_clean;


-- Fix BOM character issue in column name (imported as "ï»¿ta_id")
ALTER TABLE clients_clean CHANGE `ï»¿ta_id` ta_id VARCHAR(30);

-- Step 0: Add a surrogate primary key
ALTER TABLE clients_clean
ADD COLUMN id INT AUTO_INCREMENT PRIMARY KEY;


-- Find duplicate ta_id values
SELECT ta_id, COUNT(*) AS count
FROM clients_clean
GROUP BY ta_id
HAVING COUNT(*) > 1;

-- Inspect rows with identical values across all columns
SELECT *
FROM clients_clean c1
JOIN (
    SELECT ta_id
    FROM clients_clean
    GROUP BY ta_id, poa, poi, registration_time, ib_id, region,
             initial_deposit, swap_free_status, pnl, nb_of_trades,
             volume, most_traded_symbol
    HAVING COUNT(*) > 1
) dup
ON c1.ta_id = dup.ta_id
ORDER BY c1.ta_id;

-- Delete exact duplicates (keep lowest id)
DELETE c1
FROM clients_clean c1
JOIN clients_clean c2
  ON c1.ta_id = c2.ta_id
 AND c1.poa = c2.poa
 AND c1.poi = c2.poi
 AND c1.registration_time = c2.registration_time
 AND c1.ib_id = c2.ib_id
 AND c1.region = c2.region
 AND c1.initial_deposit = c2.initial_deposit
 AND c1.swap_free_status = c2.swap_free_status
 AND c1.pnl = c2.pnl
 AND c1.nb_of_trades = c2.nb_of_trades
 AND c1.volume = c2.volume
 AND c1.most_traded_symbol = c2.most_traded_symbol
WHERE c1.id > c2.id;

-- Inspect ta_id values that still have multiple rows
SELECT *
FROM clients_clean
WHERE ta_id IN (
    SELECT ta_id
    FROM clients_clean
    GROUP BY ta_id
    HAVING COUNT(*) > 1
)
ORDER BY ta_id;

-- Remove incomplete duplicate identified during manual inspection
DELETE FROM clients_clean
WHERE id = 80;


-- Inspect distinct values in POA
SELECT DISTINCT poa
FROM traders_pnl.clients_clean
ORDER BY poa;

-- Inspect distinct values in POI
SELECT DISTINCT poi
FROM traders_pnl.clients_clean
ORDER BY poi;


-- Replace blanks and N/A with NULL in registration_time
UPDATE traders_pnl.clients_clean
SET registration_time = NULL
WHERE registration_time = ''
   OR registration_time = 'N/A';

-- Convert YYYY.MM.DD HH:MM format
UPDATE traders_pnl.clients_clean
SET registration_time = STR_TO_DATE(registration_time, '%Y.%m.%d %H:%i')
WHERE registration_time LIKE '____.__.__%';

-- Convert MM/DD/YYYY format
UPDATE traders_pnl.clients_clean
SET registration_time = STR_TO_DATE(registration_time, '%m/%d/%Y')
WHERE registration_time LIKE '%/%/%';

-- Convert DD Month, YYYY format
UPDATE traders_pnl.clients_clean
SET registration_time = STR_TO_DATE(registration_time, '%d %M, %Y')
WHERE registration_time LIKE '% %,%';

-- Force full datetime display (shows 00:00:00 for missing times)
SELECT DATE_FORMAT(registration_time, '%Y-%m-%d %H:%i:%s') AS full_time
FROM traders_pnl.clients_clean
WHERE registration_time IS NOT NULL
LIMIT 20;


-- Inspect distinct ib_id values
SELECT DISTINCT ib_id
FROM traders_pnl.clients_clean
ORDER BY ib_id;

-- Find rows with ib_id containing non-numeric text (we noticed from query above that 40404Europe and 40405APAC exist)
SELECT id, ta_id, ib_id, region
FROM traders_pnl.clients_clean
WHERE ib_id LIKE '%Europe%'
   OR ib_id LIKE '%APAC%';
   
-- Correct malformed IB ID and assign region
UPDATE traders_pnl.clients_clean
SET ib_id = '40403',
    region = 'Europe'
WHERE ib_id LIKE '%Europe%';

-- -- Correct malformed IB ID and assign region (using ID)
UPDATE traders_pnl.clients_clean
SET ib_id = '40405',
    region = 'APAC'
WHERE id = 130;

-- Check distinct ib_id values
SELECT DISTINCT ib_id
FROM traders_pnl.clients_clean
ORDER BY ib_id;


-- Check distinct region values
SELECT DISTINCT region
FROM traders_pnl.clients_clean
ORDER BY region;


-- Preview deposits as numbers to sort numerically / catch any hidden formating errors
SELECT ta_id, CAST(initial_deposit AS DECIMAL(12,2)) AS deposit_value
FROM traders_pnl.clients_clean
ORDER BY deposit_value;

-- Smallest 5 deposits
SELECT ta_id, CAST(initial_deposit AS DECIMAL(12,2)) AS deposit_value
FROM traders_pnl.clients_clean
ORDER BY deposit_value ASC
LIMIT 5;

-- Largest 5 deposits
SELECT ta_id, CAST(initial_deposit AS DECIMAL(12,2)) AS deposit_value
FROM traders_pnl.clients_clean
ORDER BY deposit_value DESC
LIMIT 5;

-- Flag suspicious deposits (negative deposits and above 500k)
SELECT ta_id, CAST(initial_deposit AS DECIMAL(12,2)) AS deposit_value
FROM traders_pnl.clients_clean
WHERE CAST(initial_deposit AS DECIMAL(12,2)) < 0
   OR CAST(initial_deposit AS DECIMAL(12,2)) > 500000;  

-- Set negative and extremely high deposits to 0
UPDATE traders_pnl.clients_clean
SET initial_deposit = '0'
WHERE CAST(initial_deposit AS DECIMAL(12,2)) < 0
   OR CAST(initial_deposit AS DECIMAL(12,2)) > 500000;

   
-- See all unique swap_free_status entries
SELECT DISTINCT swap_free_status
FROM traders_pnl.clients_clean;


-- Preview pnl values as numbers
SELECT ta_id, CAST(pnl AS DECIMAL(12,2)) AS pnl_value
FROM traders_pnl.clients_clean
ORDER BY pnl_value;

-- Smallest 5 pnl values
SELECT ta_id, CAST(pnl AS DECIMAL(12,2)) AS pnl_value
FROM traders_pnl.clients_clean
ORDER BY pnl_value ASC
LIMIT 5;

-- Largest 5 pnl values
SELECT ta_id, CAST(pnl AS DECIMAL(12,2)) AS pnl_value
FROM traders_pnl.clients_clean
ORDER BY pnl_value DESC
LIMIT 5;

-- Find trades containing anything other than digits
SELECT id, ta_id, nb_of_trades
FROM traders_pnl.clients_clean
WHERE nb_of_trades REGEXP '[^0-9]';

-- Convert values like 1,232 → 1232
UPDATE traders_pnl.clients_clean
SET nb_of_trades = REPLACE(nb_of_trades, ',', '')
WHERE nb_of_trades LIKE '%,%';

-- Convert values like 1.75k → 1750
UPDATE traders_pnl.clients_clean
SET nb_of_trades = CAST(REPLACE(LOWER(nb_of_trades), 'k', '') AS DECIMAL(12,2)) * 1000
WHERE LOWER(nb_of_trades) LIKE '%k';

-- Flag for volume anything that is NOT a valid decimal number
SELECT id, ta_id, volume
FROM traders_pnl.clients_clean
WHERE volume NOT REGEXP '^[0-9]+(\.[0-9]+)?$';


-- Show distinct values with case sensitivity
SELECT DISTINCT most_traded_symbol COLLATE utf8mb4_bin AS symbol_cs
FROM traders_pnl.clients_clean
ORDER BY symbol_cs;

-- Standardize all symbols to uppercase
UPDATE traders_pnl.clients_clean
SET most_traded_symbol = UPPER(most_traded_symbol)
WHERE most_traded_symbol IS NOT NULL;


-- Inspect clean table
SELECT * 
FROM traders_pnl.clients_clean;


-- Adjust formats for each column
ALTER TABLE traders_pnl.clients_clean
MODIFY ta_id INT,
MODIFY poa ENUM('Yes','No'),
MODIFY poi ENUM('Yes','No'),
MODIFY registration_time DATETIME,
MODIFY ib_id INT,
MODIFY region VARCHAR(20),                
MODIFY initial_deposit DECIMAL(12,2),
MODIFY swap_free_status ENUM('Yes','No'),
MODIFY pnl DECIMAL(12,2),
MODIFY nb_of_trades INT,
MODIFY volume DECIMAL(18,6),
MODIFY most_traded_symbol VARCHAR(20);

-- Check final schema
DESCRIBE traders_pnl.clients_clean;



