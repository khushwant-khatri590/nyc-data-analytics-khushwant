-- Quick test to verify source connection works
SELECT 
    unique_key,
    created_date,
    complaint_type,
    borough
FROM {{ source('raw', 'source_dot_service_requests_history') }}
LIMIT 10
```

### Step 3 - Save the file
Click **Save**

### Step 4 - Commit
Commit with message: `Added test_311_sample model`

### Step 5 - Run the model
In the terminal at the bottom type:
```
dbt run --select test_311_sample