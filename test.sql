-- 1. Create schema and install pg_partman (run as superuser)
CREATE SCHEMA IF NOT EXISTS public;  -- pg_partman's default schema
CREATE EXTENSION IF NOT EXISTS pg_partman WITH SCHEMA public;


-- 2. Create parent table with primary key
CREATE TABLE public.sales_hybrid (
    id BIGSERIAL,
    region VARCHAR(50),
    sale_date DATE,
    amount DECIMAL(10,2),
    PRIMARY KEY (id, region)  -- Required for partitioned tables
) PARTITION BY LIST (region);

-- 3. Create default partition
CREATE TABLE public.sales_default PARTITION OF public.sales_hybrid DEFAULT;


-- 4. Create Antarctica partition with YEARLY subpartitioning
CREATE TABLE public.sales_antarctica PARTITION OF public.sales_hybrid 
FOR VALUES IN ('Antarctica')
PARTITION BY RANGE (sale_date);

-- 5. Configure pg_partman for YEARLY subpartitions
SELECT create_parent(
    p_parent_table := 'public.sales_antarctica',  -- Add schema name
    p_control := 'sale_date',
    p_interval := '1 year',
    p_type := 'range',
    p_premake := 3  -- Creates 3 future partitions by default
);


-- 7. Generate subpartitions
SELECT run_maintenance('public.sales_antarctica');

-- 8. Insert test data
INSERT INTO public.sales_hybrid (region, sale_date, amount) VALUES
('Antarctica', '2023-06-15', 100.00),
('Antarctica', '2024-02-20', 200.00),
('Europe', '2024-03-01', 300.00);

-- 9. Migrate Antarctica data from default to dedicated partition
-- Note: Only needed if data was inserted before partition creation
UPDATE public.sales_hybrid 
SET region = 'Antarctica' 
WHERE region = 'Antarctica';

-- 10. Verify data placement
SELECT 
    tableoid::regclass AS partition,
    EXTRACT(YEAR FROM sale_date) AS year,
    id, amount
FROM public.sales_hybrid 
WHERE region = 'Antarctica' 
ORDER BY sale_date;


-- Reset Database 
-- 11. Drop all partitions and parent table
-- Note: This will remove all data in the partitions
DROP TABLE IF EXISTS public.sales_hybrid CASCADE;
DROP TABLE IF EXISTS public.sales_antarctica CASCADE;
DROP TABLE IF EXISTS public.sales_default CASCADE;
DROP SCHEMA IF EXISTS partman CASCADE;
