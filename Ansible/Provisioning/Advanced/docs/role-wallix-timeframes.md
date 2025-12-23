# Role: wallix-timeframes

## Description

This role manages **timeframes** (time periods) in WALLIX Bastion. Timeframes define specific time periods (days, hours) during which authorizations can be active.

## Requirements

- `wallix-auth` role must be executed first to establish authentication
- Valid session cookie (`wallix_session_cookie`)
- Accessible WALLIX Bastion API

## Variables

### Variables principales

```yaml
wallix_timeframes:
  - timeframe_name: "business_hours"
    description: "Standard business hours"
    periods:
      - start_date: "2024-01-01"      # Format: YYYY-MM-DD
        end_date: "2025-12-31"        # Format: YYYY-MM-DD
        start_time: "08:00"           # Format: HH:MM
        end_time: "18:00"             # Format: HH:MM
        week_days: [1, 2, 3, 4, 5]    # 1=Monday, 7=Sunday
```

### Period Structure

- **start_date**: Period start date (YYYY-MM-DD)
- **end_date**: Period end date (YYYY-MM-DD)
- **start_time**: Start time (HH:MM)
- **end_time**: End time (HH:MM)
- **week_days**: List of week days (1-7, 1=Monday, 7=Sunday)

## Examples

### Create standard timeframes

```yaml
- hosts: localhost
  roles:
    - wallix-auth
    - wallix-timeframes
  vars:
    wallix_timeframes:
      - timeframe_name: "business_hours"
        description: "Business hours - 8AM-6PM Monday to Friday"
        periods:
          - start_date: "2024-01-01"
            end_date: "2025-12-31"
            start_time: "08:00"
            end_time: "18:00"
            week_days: [1, 2, 3, 4, 5]
      
      - timeframe_name: "maintenance_window"
        description: "Weekend maintenance window"
        periods:
          - start_date: "2024-01-01"
            end_date: "2025-12-31"
            start_time: "02:00"
            end_time: "06:00"
            week_days: [6, 7]
```

### List existing timeframes

```yaml
- hosts: localhost
  roles:
    - wallix-auth
    - wallix-timeframes
  vars:
    wallix_timeframes_list: true
```

## API Endpoints

- **GET** `/api/timeframes` - List all timeframes
- **POST** `/api/timeframes` - Create a new timeframe
- **GET** `/api/timeframes/{id}` - Retrieve a specific timeframe
- **PUT** `/api/timeframes/{id}` - Update a timeframe
- **DELETE** `/api/timeframes/{id}` - Delete a timeframe

## Tasks

- `create_timeframes.yml` - Timeframe creation
- `list_timeframes.yml` - Timeframe listing

## API Return Codes

- **200/201/204**: Timeframe successfully created
- **409**: Timeframe already exists
- **404**: Timeframe not found (during deletion)

## Dependencies

- `wallix-auth` - For authentication
- `wallix-cleanup` - For cleanup (optional)
