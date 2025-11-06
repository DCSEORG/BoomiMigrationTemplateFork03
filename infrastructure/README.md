# Azure Logic App Infrastructure

This directory contains the Infrastructure as Code (IaC) for deploying an Azure Logic App (Consumption Plan) that synchronizes data from SQL Server to Oracle Database.

## Overview

The solution migrates the Boomi integration workflow to Azure Logic Apps, providing:

- **Automatic triggering** when new rows are added to SQL Server
- **Data transformation** from SQL Server schema to Oracle Database schema
- **Field mapping** (CustomerId → id, Name → fullName, Email → emailAddress)
- **Serverless execution** using Logic App Consumption Plan

## Architecture

```
SQL Server (Azure SQL/SQL Server)
    ↓ (Trigger: When an item is created)
Logic App (Consumption Plan)
    ↓ (Transform: Map fields)
Oracle Database
    ↓ (Action: Insert row)
```

## Files

- `main.bicep` - Main Bicep template defining all Azure resources
- `parameters.json` - Parameter file template (not used by deploy.sh, but available for CI/CD)
- `README.md` - This file

## Resources Deployed

1. **API Connection (SQL Server)** - Connects to Azure SQL or SQL Server
2. **API Connection (Oracle Database)** - Connects to Oracle Database
3. **Logic App (Consumption)** - The workflow orchestrating the data sync

## Prerequisites

- Azure CLI installed ([Install Guide](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli))
- Azure subscription with permissions to create resources
- SQL Server database with the source table
- Oracle Database with the target table
- Network connectivity between Azure and your databases

## Quick Deployment

From the root of the repository, run:

```bash
./deploy.sh
```

The script will:
1. Check Azure CLI installation
2. Verify Azure login (prompt if needed)
3. Prompt for resource group name and location
4. Collect SQL Server connection details
5. Collect Oracle Database connection details
6. Deploy all resources using Bicep
7. Display deployment summary with next steps

## Manual Deployment (Alternative)

If you prefer to deploy manually or use a CI/CD pipeline:

```bash
# Login to Azure
az login

# Create resource group
az group create --name rg-logic-app --location eastus

# Deploy Bicep template
az deployment group create \
  --name logic-app-deployment \
  --resource-group rg-logic-app \
  --template-file ./infrastructure/main.bicep \
  --parameters sqlServerFqdn="myserver.database.windows.net" \
  --parameters sqlDatabaseName="FinanceDB" \
  --parameters sqlUsername="sqladmin" \
  --parameters sqlPassword="YourPassword123!" \
  --parameters oracleServer="oracle.example.com" \
  --parameters oracleServiceName="ORCL" \
  --parameters oracleUsername="oracleuser" \
  --parameters oraclePassword="OraclePass123!"
```

## Configuration Parameters

### SQL Server Configuration

- `sqlServerFqdn` - Fully qualified domain name (e.g., `myserver.database.windows.net`)
- `sqlDatabaseName` - Database name
- `sqlUsername` - Authentication username
- `sqlPassword` - Authentication password (secure parameter)
- `sqlTableName` - Table to monitor (default: `dbo.Customer`)

### Oracle Database Configuration

- `oracleServer` - Oracle server address
- `oraclePort` - Oracle port (default: `1521`)
- `oracleServiceName` - Oracle service name or SID
- `oracleUsername` - Authentication username
- `oraclePassword` - Authentication password (secure parameter)
- `oracleTableName` - Target table name (default: `CUSTOMER_CCS`)

### Other Parameters

- `location` - Azure region (default: `eastus`)
- `logicAppName` - Logic App resource name
- `tags` - Resource tags for organization

## Data Transformation

The Logic App performs the following field mappings from SQL Server to Oracle Database:

| SQL Server Field | Oracle Database Field |
|-----------------|----------------------|
| CustomerId      | ID                   |
| Name            | FULLNAME             |
| Email           | EMAILADDRESS         |

This matches the transformation logic defined in the Boomi workflow (`Map_CustomerToCCS.xml`).

## Monitoring and Management

After deployment:

1. **View Logic App**: Navigate to the Azure Portal → Logic Apps → Select your Logic App
2. **Monitor Runs**: Check the "Runs history" to see triggered executions
3. **View Connections**: Check API Connections to verify authentication status
4. **Edit Workflow**: Use the Logic App Designer to modify the workflow

## Trigger Behavior

The Logic App uses the SQL Server connector's "When an item is created" trigger:

- **Polling Interval**: Every 1 minute (configurable)
- **Split On**: Enabled (processes each new row individually)
- **Detection Method**: Uses SQL Server change tracking or timestamp column

## Troubleshooting

### Connection Issues

- **SQL Server**: Ensure Azure services can access the SQL Server (firewall rules)
- **Oracle Database**: Verify network connectivity and firewall rules
- **Authentication**: Verify credentials are correct in the API connections

### Logic App Not Triggering

- Check the SQL table has the proper schema
- Verify the trigger is enabled in the Logic App
- Check the Logic App run history for errors
- Ensure the SQL Server connector is authorized

### Data Not Appearing in Oracle

- Verify the Oracle table schema matches the expected fields
- Check Oracle Database permissions for the user
- Review Logic App run details for specific error messages

## Security Best Practices

1. **Use Managed Identities** where possible (requires SQL Database with Azure AD)
2. **Store secrets in Key Vault** for production deployments
3. **Enable diagnostic logs** for monitoring and auditing
4. **Restrict network access** using Private Endpoints or Service Endpoints
5. **Use least privilege** for database user permissions

## Cost Considerations

This solution uses:
- **Logic App (Consumption)**: Pay-per-execution model
- **API Connections**: No additional cost
- Estimated cost: ~$0.001 per workflow execution

## References

- [Azure Logic Apps Documentation](https://docs.microsoft.com/en-us/azure/logic-apps/)
- [SQL Server Connector](https://learn.microsoft.com/en-us/azure/connectors/connectors-create-api-sqlazure?tabs=consumption)
- [Oracle Database Connector](https://learn.microsoft.com/en-us/azure/connectors/connectors-create-api-oracledatabase)
- [Bicep Documentation](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/)

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review Azure Logic App run history
3. Consult Microsoft documentation links
4. Open an issue in this repository
