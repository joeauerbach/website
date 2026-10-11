# Wordpress Blue/Green deployment

This is a pretty easy way to deploy and manage a blue/green deployment for wordpress. The goal is to
make it as simple as possible to update, backup, and restore so that your site is as hard to break as 
possible.

## Architecture Diagram

```text
[ Internet ]
      │
┌─────▼──────────────────────────────┐
│ Load Balancer                      |
|  (holds the blue/green live value) │
│        |                           │
│  ┌──────────────────────────────┐  │
│  │ wp-blue OR wp-green          │--│--[ Your home ip ]   
│  │ ──► whichever is live        │  │
│  └──────────────────────────────┘  │
└────────────────────────────────────┘
```

## Requirements

| Name | Version | Notes |
| :--- | :--- | :--- |
| **terraform** | >= 1.16.0 | (You can change this, I'm not your dad.) |

## Providers

| Name | Version | Notes |
| :--- | :--- | :--- |
| **gcp** | N/A | (AWS version pending, but you can probably figure it out) |

## Usage Example

```hcl
A normal terraform apply will delpoy the blue site but a crossover is more complex. (see below)
```

## Inputs

| Name | Description | Type | Default | Required |
| :--- | :--- | :--- | :--- | :---: |
| **active_stack** | The version of the site that is active. | `string` | `"blue"` | no |

## Outputs

| Name | Description |
| :--- | :--- |
| **public_ip** | The load balancer ip. |
| **green_ip** | The ip of wp-green. |
| **blue_ip** | The ip of wp-blue. |
| **active_stack** | The current active site instance. |

## Deployment Instructions

1. **Initialize the workspace:**
   ```bash
   terraform init
   ```
2. **Review the execution plan:**
   ```bash
   terraform plan
   ```
3. **Apply the configuration:**
   ```bash
   terraform apply
   ```

## Performing a Blue-Green Cutover

1. **Deploy Green:** 
    Run Terraform with active_stack = "blue" (default) while updating your Green template with the new WordPress/plugin version. (blue is the default)
    '''bash
    terraform apply
    '''
2. **Verify Green:** 
    Access the Green instance (the instance can be accessed directly from your home ip) and test changes.
3. **Switch Traffic:** 
    Update your terraform variable to point to green:
    '''bash
    terraform apply -var="active_env=green"
    '''
4. **Rollback:** 
    The Load Balancer updates its backend target to Green with zero downtime. Roll back instantly by switching back to active_stack = "blue" if any issues occur.
    '''bash
    terraform apply -var="active_env=blue"
    '''
