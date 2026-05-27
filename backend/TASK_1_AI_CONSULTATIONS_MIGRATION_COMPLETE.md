# Task 1: AI Consultations Database Migration - COMPLETE

## Overview
Successfully created and tested the database migration for the `ai_consultations` table as part of the AI Visual Assistant feature.

## Migration Details

### File Created
- **Location**: `database/migrations/2026_05_26_190714_create_ai_consultations_table.php`
- **Migration Name**: `create_ai_consultations_table`

### Table Schema

#### Columns
| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `id` | UUID (CHAR 36) | NO | Primary key |
| `customer_id` | UUID (CHAR 36) | NO | Foreign key to users table |
| `image_path` | VARCHAR(500) | NO | Path to stored consultation image |
| `image_size_kb` | INT UNSIGNED | NO | Image file size in kilobytes |
| `markers` | JSON | NO | Array of marker objects with x, y, description |
| `ai_diagnosis` | TEXT | NO | AI-generated diagnosis text |
| `recommended_service_type` | VARCHAR(100) | NO | Service category recommendation |
| `cost_min` | DECIMAL(10,2) | NO | Minimum cost estimate in NPR |
| `cost_max` | DECIMAL(10,2) | NO | Maximum cost estimate in NPR |
| `recommended_providers` | JSON | YES | Array of recommended provider IDs |
| `ai_response_raw` | JSON | NO | Complete AI response for reference |
| `processing_time_ms` | INT UNSIGNED | NO | AI processing time in milliseconds |
| `created_at` | TIMESTAMP | YES | Record creation timestamp |
| `updated_at` | TIMESTAMP | YES | Record update timestamp |
| `deleted_at` | TIMESTAMP | YES | Soft delete timestamp |

#### Foreign Keys
- **Constraint**: `ai_consultations_customer_id_foreign`
  - Column: `customer_id`
  - References: `users.id`
  - On Delete: CASCADE

#### Indexes
1. **PRIMARY**: `id` (primary key)
2. **idx_customer_created**: Composite index on `(customer_id, created_at)`
   - Optimizes queries filtering by customer and sorting by date
   - Used for consultation history retrieval
3. **idx_service_type**: Index on `recommended_service_type`
   - Optimizes filtering consultations by service type
   - Supports analytics queries

### JSON Field Structures

#### markers JSON
```json
[
  {
    "x": 0.45,
    "y": 0.32,
    "description": "Water leaking from pipe joint"
  },
  {
    "x": 0.67,
    "y": 0.58,
    "description": "Rust visible on metal surface"
  }
]
```

#### recommended_providers JSON
```json
["provider-uuid-1", "provider-uuid-2", "provider-uuid-3"]
```

#### ai_response_raw JSON
```json
{
  "diagnosis": "Plumbing leak with corrosion damage",
  "service_type": "Plumbing Repair",
  "cost_estimate": {
    "min": 2000,
    "max": 5000,
    "currency": "NPR"
  },
  "confidence": 0.87,
  "model": "qwen3-vl:2b",
  "processing_time_ms": 27000
}
```

## Testing Results

### Migration Tests
✅ **Migration Up**: Successfully created table with all columns, indexes, and constraints
✅ **Migration Down**: Successfully rolled back and dropped table cleanly
✅ **Re-migration**: Successfully re-ran migration after rollback

### Verification Tests
All tests passed successfully:

1. ✅ **Table Existence**: Verified table `ai_consultations` exists
2. ✅ **Column Structure**: All 15 required columns present with correct types
3. ✅ **Indexes**: All 3 indexes created (PRIMARY, idx_customer_created, idx_service_type)
4. ✅ **Foreign Key**: Constraint correctly references `users.id` with CASCADE delete
5. ✅ **Data Insertion**: Successfully inserted test consultation record
6. ✅ **Data Retrieval**: Successfully retrieved and validated JSON fields
7. ✅ **Index Usage**: Confirmed composite index is used in queries

### Test Script
Created comprehensive test script: `test_ai_consultations_migration.php`
- Tests all aspects of the migration
- Validates data insertion and retrieval
- Verifies JSON field handling
- Confirms index usage with EXPLAIN queries

## Acceptance Criteria Status

✅ **Migration creates table with all required columns**
- All 15 columns created with correct data types
- UUID primary key configured
- JSON fields for markers, providers, and raw response
- Timestamps and soft deletes included

✅ **Foreign key constraint on customer_id references users table**
- Constraint `ai_consultations_customer_id_foreign` created
- References `users.id`
- CASCADE delete configured

✅ **Indexes created for performance optimization**
- Composite index on (customer_id, created_at) for history queries
- Index on recommended_service_type for filtering
- Verified index usage with EXPLAIN queries

✅ **Migration can be rolled back cleanly**
- Successfully tested rollback
- Table dropped without errors
- Re-migration works correctly

## Database Commands

### Run Migration
```bash
docker exec gharsewa_app php artisan migrate --path=database/migrations/2026_05_26_190714_create_ai_consultations_table.php
```

### Rollback Migration
```bash
docker exec gharsewa_app php artisan migrate:rollback --step=1
```

### Verify Table Structure
```bash
docker exec gharsewa_db mysql -u gharsewa_user -pgharsewa_password gharsewa -e "DESCRIBE ai_consultations;"
```

### Check Indexes
```bash
docker exec gharsewa_db mysql -u gharsewa_user -pgharsewa_password gharsewa -e "SHOW INDEX FROM ai_consultations;"
```

### Run Test Script
```bash
docker exec gharsewa_app php test_ai_consultations_migration.php
```

## Requirements Satisfied

This migration satisfies **REQ-9 (Data Persistence)** from the AI Visual Assistant specification:

- ✅ Consultation records stored in MySQL database
- ✅ All required fields included (customer_id, image_path, markers, AI response fields)
- ✅ Unique filenames supported via UUID
- ✅ Customer association via foreign key
- ✅ Query optimization via indexes
- ✅ Soft deletes for data retention

## Next Steps

The database schema is now ready for:
1. **Task 2**: Create AIConsultation Eloquent model
2. **Task 3**: Implement VisionAIService class
3. **Task 5**: Build API endpoints for consultation creation

## Notes

- Migration follows Laravel 11 conventions
- Uses UUID for primary keys (consistent with existing schema)
- Soft deletes enabled for data retention requirements (12 months)
- Composite index optimized for common query patterns
- JSON fields allow flexible data storage for markers and AI responses
- Foreign key CASCADE ensures data integrity when users are deleted
