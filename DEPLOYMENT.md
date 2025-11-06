# Azure Logic App Deployment Guide

## Overview

This solution provides a complete Infrastructure as Code (IaC) implementation to migrate a Boomi integration workflow to Azure Logic Apps. The Logic App synchronizes customer data from SQL Server to Oracle Database with automatic triggering on new row insertion.

## What's Included

```
.
├── deploy.sh                 # One-command deployment script
├── infrastructure/
│   ├── main.bicep           # Bicep template for Azure resources
│   ├── parameters.json      # Parameter template
│   └── README.md            # Infrastructure documentation
├── .env.example             # Environment variables template
├── .gitignore               # Git ignore rules
└── DEPLOYMENT.md            # This file
```

## Architecture

The solution deploys:

1. **SQL Server API Connection** - Connects to Azure SQL Database or SQL Server
2. **Oracle Database API Connection** - Connects to Oracle Database  
3. **Logic App (Consumption Plan)** - Serverless workflow that:
   - Triggers when new rows are added to SQL Server
   - Transforms data (CustomerId→id, Name→fullName, Email→emailAddress)
   - Inserts transformed data into Oracle Database

## Boomi Workflow Mapping

This Logic App replicates the Boomi workflow defined in `Boomi(.DAR)/Process/SyncCustomerData.xml`:

| Boomi Component | Logic App Equivalent |
|----------------|---------------------|
| GetFromSQL (Database Connector) | SQL Server Trigger (When an item is created) |
| MapToJSON (Map Component) | Initialize Variable actions for field transformation |
| PostToCCS (HTTP Connector to Oracle) | Oracle Database Insert action |

### Field Mapping (from `Map_CustomerToCCS.xml`)

- `CustomerId` (SQL) → `ID` (Oracle)
- `Name` (SQL) → `FULLNAME` (Oracle)
- `Email` (SQL) → `EMAILADDRESS` (Oracle)

## Prerequisites

### Required Software
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) (version 2.30 or later)
- Bash shell (Linux, macOS, WSL, or Git Bash on Windows)

### Azure Requirements
- Active Azure subscription
- Permissions to create resources in the subscription
- Resource provider registered: `Microsoft.Logic`, `Microsoft.Web`

### Database Requirements

#### SQL Server
- Azure SQL Database OR SQL Server accessible from Azure
- Source table with schema:
  ```sql
  CREATE TABLE dbo.Customer (
      CustomerId INT PRIMARY KEY,
      Name NVARCHAR(100),
      Email NVARCHAR(100),
      Active BIT
  )
  ```
- Firewall rule allowing Azure services (if using Azure SQL)
- SQL Authentication enabled

#### Oracle Database
- Oracle Database accessible from Azure (on-premises or cloud)
- Target table with schema:
  ```sql
  CREATE TABLE CUSTOMER_CCS (
      ID NUMBER PRIMARY KEY,
      FULLNAME VARCHAR2(100),
      EMAILADDRESS VARCHAR2(100)
  )
  ```
- Network connectivity from Azure (VPN, ExpressRoute, or public endpoint)
- User with INSERT permissions on the target table

## Deployment Steps

### Option 1: Interactive Deployment (Recommended)

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd BoomiMigrationTemplateFork03
   ```

2. **Run the deployment script**
   ```bash
   ./deploy.sh
   ```

3. **Follow the prompts** to provide:
   - Resource group name
   - Azure region
   - SQL Server connection details
   - Oracle Database connection details

4. **Wait for deployment** (typically 2-5 minutes)

5. **Review the summary** output showing deployed resources

### Option 2: Environment Variables Deployment

1. **Create environment file**
   ```bash
   cp .env.example .env
   ```

2. **Edit .env with your values**
   ```bash
   nano .env  # or use your preferred editor
   ```

3. **Run deployment with environment variables**
   ```bash
   source .env
   ./deploy.sh
   ```

### Option 3: CI/CD Pipeline Deployment

For automated deployments, use Azure CLI in your pipeline:

```yaml
# Example GitHub Actions workflow
- name: Deploy Logic App
  run: |
    az deployment group create \
      --name logic-app-deployment \
      --resource-group ${{ secrets.RESOURCE_GROUP }} \
      --template-file ./infrastructure/main.bicep \
      --parameters sqlServerFqdn=${{ secrets.SQL_SERVER }} \
                   sqlDatabaseName=${{ secrets.SQL_DATABASE }} \
                   sqlUsername=${{ secrets.SQL_USERNAME }} \
                   sqlPassword=${{ secrets.SQL_PASSWORD }} \
                   oracleServer=${{ secrets.ORACLE_SERVER }} \
                   oracleServiceName=${{ secrets.ORACLE_SERVICE }} \
                   oracleUsername=${{ secrets.ORACLE_USERNAME }} \
                   oraclePassword=${{ secrets.ORACLE_PASSWORD }}
```

## Post-Deployment Configuration

### 1. Verify API Connections

```bash
# Check SQL connection status
az resource show \
  --resource-group rg-logic-app-sql-oracle \
  --resource-type Microsoft.Web/connections \
  --name sql-connection

# Check Oracle connection status
az resource show \
  --resource-group rg-logic-app-sql-oracle \
  --resource-type Microsoft.Web/connections \
  --name oracle-connection
```

### 2. Authorize Connections (if needed)

If connections show as "Unauthenticated":

1. Navigate to Azure Portal
2. Go to Resource Group → API Connections
3. Click on each connection
4. Click "Edit API connection"
5. Re-enter credentials and save

### 3. Test the Logic App

```sql
-- Insert a test row in SQL Server
INSERT INTO dbo.Customer (CustomerId, Name, Email, Active)
VALUES (1, 'John Doe', 'john.doe@example.com', 1);
```

Wait 1-2 minutes, then check:
- Logic App run history in Azure Portal
- Oracle Database for the new row

### 4. Monitor Logic App

```bash
# View recent runs
az logic workflow show \
  --resource-group rg-logic-app-sql-oracle \
  --name logic-sql-to-oracle-sync

# Enable diagnostics (recommended)
az monitor diagnostic-settings create \
  --resource-group rg-logic-app-sql-oracle \
  --resource logic-sql-to-oracle-sync \
  --name logicapp-diagnostics \
  --workspace <log-analytics-workspace-id> \
  --logs '[{"category":"WorkflowRuntime","enabled":true}]'
```

## Customization

### Change Trigger Frequency

Edit `main.bicep` and modify the trigger recurrence:

```bicep
recurrence: {
  frequency: 'Minute'  // Options: Second, Minute, Hour, Day, Week, Month
  interval: 5          // Run every 5 minutes instead of 1
}
```

### Add More Field Mappings

Edit `main.bicep` actions section to add more field transformations:

```bicep
'Initialize_transformed_newField': {
  type: 'InitializeVariable'
  inputs: {
    variables: [
      {
        name: 'newField'
        type: 'string'
        value: '@triggerBody()?[\'SourceField\']'
      }
    ]
  }
  runAfter: { /* ... */ }
}
```

### Filter Trigger Conditions

Add a condition in the Logic App workflow to filter which rows to process:

```bicep
'Condition_Check_Active': {
  type: 'If'
  expression: {
    and: [
      {
        equals: [
          '@triggerBody()?[\'Active\']'
          true
        ]
      }
    ]
  }
  actions: {
    // Insert to Oracle only if Active = true
  }
}
```

## Troubleshooting

### Issue: "The template deployment failed"

**Solution**: Check the error message for details. Common causes:
- Invalid resource names (must be unique)
- Insufficient permissions
- Quota limits reached

### Issue: SQL Server connection fails

**Solution**:
1. Verify SQL Server firewall allows Azure services
2. Check credentials are correct
3. Ensure database exists and is accessible
4. Test connection from Azure Portal

### Issue: Oracle Database connection fails

**Solution**:
1. Verify Oracle Database is reachable from Azure
2. Check Oracle listener is running
3. Verify service name/SID is correct
4. Test with Oracle SQL Developer or similar tool

### Issue: Logic App triggers but doesn't insert to Oracle

**Solution**:
1. Check Logic App run history for error details
2. Verify Oracle table exists with correct schema
3. Check Oracle user has INSERT permissions
4. Verify field names match (case-sensitive)

### Issue: "The deployment script doesn't run"

**Solution**:
```bash
# Make script executable
chmod +x deploy.sh

# If still fails, run with bash explicitly
bash deploy.sh
```

## Cleanup

To remove all deployed resources:

```bash
# Delete the entire resource group
az group delete --name rg-logic-app-sql-oracle --yes --no-wait
```

## Security Best Practices

### For Production Deployments

1. **Use Azure Key Vault for secrets**
   ```bicep
   param sqlPassword string = reference(keyVaultSecret.id).value
   ```

2. **Enable Managed Identity for SQL Database**
   ```bicep
   authentication: {
     type: 'ManagedServiceIdentity'
   }
   ```

3. **Use Private Endpoints**
   - Deploy Logic App in a VNET
   - Use Private Endpoints for SQL and Oracle

4. **Enable diagnostic logging**
   - Send logs to Log Analytics
   - Set up alerts for failures

5. **Implement least privilege**
   - SQL user with minimal permissions (SELECT only)
   - Oracle user with INSERT only on target table

## Performance Considerations

### Trigger Frequency
- Default: Every 1 minute
- For high-volume: Use Azure Service Bus or Event Grid
- For low-volume: Increase to 5-15 minutes

### Batch Processing
- Current: Processes one row at a time
- For bulk: Modify to process in batches

### Concurrency
```bicep
properties: {
  runtimeConfiguration: {
    concurrency: {
      runs: 25  // Maximum concurrent runs
    }
  }
}
```

## Cost Estimation

Based on Logic App Consumption Plan pricing:

| Component | Cost |
|-----------|------|
| Logic App execution | ~$0.001 per run |
| SQL connector action | Included |
| Oracle connector action | Included |
| API Connection | No additional cost |

**Example**: 1,000 new customers/day = ~$1/day = ~$30/month

For detailed pricing: [Azure Logic Apps Pricing](https://azure.microsoft.com/en-us/pricing/details/logic-apps/)

## Support and Resources

### Documentation
- [Azure Logic Apps](https://docs.microsoft.com/en-us/azure/logic-apps/)
- [SQL Server Connector](https://learn.microsoft.com/en-us/azure/connectors/connectors-create-api-sqlazure?tabs=consumption)
- [Oracle Database Connector](https://learn.microsoft.com/en-us/azure/connectors/connectors-create-api-oracledatabase)
- [Bicep Documentation](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/)

### Getting Help
1. Review Azure Logic App run history
2. Check Azure Resource Health
3. Enable diagnostics and review logs
4. Contact Azure Support if needed

## Next Steps

After successful deployment:

1. ✅ Test with sample data
2. ✅ Set up monitoring and alerts
3. ✅ Configure proper error handling
4. ✅ Implement security best practices
5. ✅ Document any customizations
6. ✅ Train team on Logic App management

## License

This solution is provided as-is for workshop and proof-of-concept purposes.
