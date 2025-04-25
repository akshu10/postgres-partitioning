# postgres-partitioning
This was created to try out the the pg_partman extension and perform partitioning in postgresql



### Learning outcomes

**We would have to perform the two steps every time we on-board a new organization in our case.**

1. Create Antarctica partition with YEARLY sub-partitioning
```sql
CREATE TABLE sales_antarctica PARTITION OF sales_hybrid 
FOR VALUES IN ('Antarctica')
PARTITION BY RANGE (sale_date);
```
2. Configure pg_partman for YEARLY subpartitions

```sql 
SELECT partman.create_parent(
    p_parent_table := 'public.sales_antarctica',
    p_control := 'sale_date',
    p_interval := '1 year',
    p_type := 'native'
);
```

## PG_Partman issues:  

### Example Scenario:

If you ran create_parent() in June 2024 with default settings:

```sql
SELECT partman.create_parent(
    'public.sales_antarctica',
    'sale_date',
    '1 year',
    'native'
);

It would create:


sales_antarctica_p2024 (2024-01-01 to 2025-01-01)
sales_antarctica_p2025 (2025-01-01 to 2026-01-01)
sales_antarctica_p2026 (2026-01-01 to 2027-01-01)
sales_antarctica_p2027 (2027-01-01 to 2028-01-01)
```


However we can configure Partman as follows:

### Example 1: 
**Yearly Partitions with 2 Premake**

```sql
SELECT partman.create_parent(
    'public.yearly_data',
    'event_date',
    'yearly',
    'native',
    p_premake := 2  -- Creates 2 future years (2025-2026 if run in 2024)
);
```

### Example 2: 
**Force partitions starting 2023-01-01 with 5 pre-make** 
Partitions beyond 5 are only created if `partman.run_maintenance()` runs regularly as needed(when data insertion requires it)
```sql
SELECT partman.create_parent(
    'public.historical_data',
    'record_date',
    'yearly',
    'native',
    p_premake := 5,
    p_start_partition := '2023-01-01'  -- Creates 2023-2027 partitions AND p_start_partition takes precedence over current date for initial setup.
);
```

### Example 3: 

**Change premake for an already configured table**

```sql
-- Update from default 4 to 10 premake
UPDATE partman.part_config 
SET premake = 10 
WHERE parent_table = 'public.sales_antarctica';
```


### Conclusions: 

1. p_premake - can be left as 1 (default in partman is 4). This ensures that there will be a table one year head. The benefit of this is we dont have too many future tables and if a future year is inserted a table for it will be automatically be created.  


2. Onboarding
    List partition table need to be manually created when a new list value is elected
    The table created above needs to be registered with pg_partman 

3. If we ever decide on adding order data from previous years the yearly partitions will need to be manually created. There is an option to pass a p_start_partition date to pg_partman. (However the date needs to be decided before implementation. )
The start date can be altered of a partition can be altered at a later time. 

