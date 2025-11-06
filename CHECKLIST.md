# Pre-Deployment Checklist

Use this checklist to ensure you have everything ready before deploying the Logic App.

## Prerequisites Checklist

### Azure Requirements

- [ ] Azure subscription is active and accessible
- [ ] You have appropriate permissions to create resources
- [ ] Azure CLI is installed on your machine
  ```bash
  az --version
  ```
- [ ] You are logged into Azure CLI
  ```bash
  az login
  az account show
  ```
- [ ] You have selected the correct subscription
  ```bash
  az account set --subscription "YOUR_SUBSCRIPTION_NAME_OR_ID"
  ```

### SQL Server Requirements

- [ ] SQL Server or Azure SQL Database is accessible
- [ ] You have the fully qualified domain name (FQDN)
  - Example: `myserver.database.windows.net`
- [ ] Database exists and is online
- [ ] You have SQL authentication credentials (username/password)
- [ ] SQL Server firewall allows Azure services
  - For Azure SQL: Enable "Allow Azure services and resources to access this server"
- [ ] Source table exists with correct schema:
  ```sql
  -- Verify table exists
  SELECT TOP 1 * FROM dbo.Customer;
  
  -- Expected columns:
  -- CustomerId (int)
  -- Name (nvarchar)
  -- Email (nvarchar)
  -- Active (bit)
  ```
- [ ] SQL user has SELECT permission on the table
  ```sql
  GRANT SELECT ON dbo.Customer TO [your_user];
  ```

### Oracle Database Requirements

- [ ] Oracle Database is accessible from Azure
- [ ] You have the Oracle server address/hostname
- [ ] You know the Oracle port (typically 1521)
- [ ] You have the Oracle service name or SID
- [ ] You have Oracle database credentials (username/password)
- [ ] Oracle listener is running
- [ ] Target table exists with correct schema:
  ```sql
  -- Verify table exists
  SELECT * FROM CUSTOMER_CCS WHERE ROWNUM = 1;
  
  -- Expected columns:
  -- ID (NUMBER)
  -- FULLNAME (VARCHAR2)
  -- EMAILADDRESS (VARCHAR2)
  ```
- [ ] Oracle user has INSERT permission on the table
  ```sql
  GRANT INSERT ON CUSTOMER_CCS TO your_user;
  ```
- [ ] Network connectivity is established (VPN/ExpressRoute/Public endpoint)

### Network & Security

- [ ] SQL Server is reachable from Azure
  - Test from Azure Cloud Shell or Azure VM
- [ ] Oracle Database is reachable from Azure
  - Test connectivity using telnet or similar
- [ ] No corporate proxy blocking Azure Logic Apps
- [ ] SSL/TLS certificates are valid (if using encrypted connections)

### Local Machine Setup

- [ ] Bash shell is available
  - Linux/macOS: Native
  - Windows: WSL, Git Bash, or similar
- [ ] Git is installed (optional, for cloning)
- [ ] Text editor for reviewing files
- [ ] Permission to execute bash scripts
  ```bash
  chmod +x deploy.sh validate.sh
  ```

## Information Gathering Checklist

Before running `./deploy.sh`, gather the following information:

### Azure Information

- [ ] Resource group name (create new or use existing)
  - Example: `rg-logic-app-sql-oracle`
- [ ] Azure region/location
  - Example: `eastus`, `westus2`, `westeurope`

### SQL Server Information

- [ ] SQL Server FQDN
  - Example: `myserver.database.windows.net`
- [ ] SQL Database name
  - Example: `FinanceDB`
- [ ] SQL username
  - Example: `sqladmin`
- [ ] SQL password (keep secure)
  - Ensure it's correct before deployment
- [ ] SQL table name
  - Default: `dbo.Customer`
  - Verify: `SELECT * FROM dbo.Customer`

### Oracle Database Information

- [ ] Oracle server address
  - Example: `oracle.example.com` or IP address
- [ ] Oracle port
  - Default: `1521`
- [ ] Oracle service name or SID
  - Example: `ORCL`, `XEPDB1`
- [ ] Oracle username
  - Example: `oracleuser`
- [ ] Oracle password (keep secure)
  - Ensure it's correct before deployment
- [ ] Oracle table name
  - Default: `CUSTOMER_CCS`
  - Verify: `SELECT * FROM CUSTOMER_CCS`

### Logic App Configuration

- [ ] Decide on Logic App name
  - Default: `logic-sql-to-oracle-sync`
  - Must be unique within resource group
- [ ] Decide on trigger frequency
  - Default: Every 1 minute
  - Can be changed in Bicep file

## Validation Checklist

### Pre-Deployment Validation

- [ ] Clone or download the repository
  ```bash
  git clone <repository-url>
  cd BoomiMigrationTemplateFork03
  ```
- [ ] Review the README.md
- [ ] Review the DEPLOYMENT.md for detailed instructions
- [ ] Run the validation script
  ```bash
  ./validate.sh
  ```
- [ ] Validation script shows all checks passed

### Test Connectivity

#### Test SQL Server Connectivity

From Azure Cloud Shell or a machine with Azure connectivity:

```bash
# Using sqlcmd (if available)
sqlcmd -S myserver.database.windows.net -d FinanceDB -U sqladmin -P 'password' -Q "SELECT TOP 1 * FROM dbo.Customer"

# Or use Azure Portal Query Editor
# Navigate to SQL Database → Query editor
```

- [ ] Can connect to SQL Server
- [ ] Can query the Customer table
- [ ] Table has the expected columns

#### Test Oracle Connectivity

From Azure Cloud Shell or a machine with Azure connectivity:

```bash
# Using sqlplus (if available)
sqlplus oracleuser/password@oracle.example.com:1521/ORCL

# Or test basic connectivity
telnet oracle.example.com 1521
```

- [ ] Can connect to Oracle Database
- [ ] Can query the CUSTOMER_CCS table
- [ ] Table has the expected columns

## Deployment Checklist

### During Deployment

- [ ] Run the deployment script
  ```bash
  ./deploy.sh
  ```
- [ ] Carefully enter all prompted information
- [ ] Verify parameters before confirming deployment
- [ ] Wait for deployment to complete (typically 2-5 minutes)
- [ ] Note any errors or warnings
- [ ] Save the deployment summary output

### Post-Deployment Verification

- [ ] Deployment completed successfully
- [ ] Check Azure Portal for resources
  - [ ] Resource group exists
  - [ ] Logic App exists and is enabled
  - [ ] SQL API connection exists
  - [ ] Oracle API connection exists
- [ ] Verify API connections are authorized
  ```bash
  # Check in Azure Portal
  # Navigate to API Connections
  # Both should show "Connected" status
  ```
- [ ] Logic App is enabled and running
  ```bash
  # Check in Azure Portal
  # Navigate to Logic App → Overview
  # Status should be "Enabled"
  ```

## Testing Checklist

### Test the Logic App

- [ ] Insert a test row in SQL Server
  ```sql
  INSERT INTO dbo.Customer (CustomerId, Name, Email, Active)
  VALUES (9999, 'Test User', 'test@example.com', 1);
  ```
- [ ] Wait 1-2 minutes for Logic App to trigger
- [ ] Check Logic App run history
  - Navigate to Azure Portal → Logic App → Runs history
  - Look for a successful run
- [ ] Verify data in Oracle Database
  ```sql
  SELECT * FROM CUSTOMER_CCS WHERE ID = 9999;
  ```
- [ ] Expected result: Row with FULLNAME='Test User' and EMAILADDRESS='test@example.com'
- [ ] Clean up test data
  ```sql
  -- SQL Server
  DELETE FROM dbo.Customer WHERE CustomerId = 9999;
  
  -- Oracle Database
  DELETE FROM CUSTOMER_CCS WHERE ID = 9999;
  COMMIT;
  ```

### Error Handling Test

- [ ] Insert a row with invalid data (if applicable)
- [ ] Check Logic App run history for error handling
- [ ] Verify error is logged properly
- [ ] Test that subsequent valid rows still process

## Monitoring Setup Checklist

### Optional: Enable Diagnostics

- [ ] Enable diagnostic logs for Logic App
  ```bash
  az monitor diagnostic-settings create \
    --resource <logic-app-resource-id> \
    --name logicapp-diagnostics \
    --logs '[{"category":"WorkflowRuntime","enabled":true}]'
  ```
- [ ] Set up alerts for failures (optional)
- [ ] Configure Application Insights (optional)

## Documentation Checklist

- [ ] Document any customizations made
- [ ] Save connection strings and configurations (securely)
- [ ] Note any issues encountered and resolutions
- [ ] Share deployment summary with team
- [ ] Update team documentation with Azure resource details

## Security Checklist

### Post-Deployment Security

- [ ] Verify credentials are not committed to source control
- [ ] Check .gitignore includes .env files
- [ ] Review Azure RBAC permissions
- [ ] Verify SQL Server firewall rules are restrictive
- [ ] Verify Oracle Database security settings
- [ ] Consider enabling Azure Key Vault for secrets (production)
- [ ] Enable diagnostic logging for auditing
- [ ] Review Logic App managed identity options (future improvement)

## Cleanup Checklist (If Needed)

To remove all resources:

- [ ] Delete the resource group
  ```bash
  az group delete --name rg-logic-app-sql-oracle --yes
  ```
- [ ] Verify resources are deleted in Azure Portal
- [ ] Clean up any test data from databases

## Troubleshooting Checklist

If deployment fails:

- [ ] Check Azure CLI is logged in
- [ ] Verify subscription permissions
- [ ] Check all parameters are correct
- [ ] Review error messages carefully
- [ ] Check Azure resource quotas
- [ ] Verify resource names are unique
- [ ] Consult DEPLOYMENT.md troubleshooting section

If Logic App doesn't trigger:

- [ ] Verify SQL table has new rows
- [ ] Check API connection status in Azure Portal
- [ ] Review Logic App trigger configuration
- [ ] Check SQL Server firewall rules
- [ ] Verify trigger is enabled
- [ ] Review run history for errors

If data doesn't appear in Oracle:

- [ ] Check Logic App run history for errors
- [ ] Verify Oracle connection status
- [ ] Check Oracle table permissions
- [ ] Verify table schema matches expectations
- [ ] Check network connectivity to Oracle

## Success Criteria

Deployment is successful when:

- [ ] All Azure resources are created
- [ ] Logic App is enabled and running
- [ ] API connections are authorized
- [ ] Test insert in SQL Server triggers Logic App
- [ ] Data appears in Oracle Database with correct transformation
- [ ] No errors in Logic App run history

## Next Steps After Successful Deployment

- [ ] Monitor Logic App runs regularly
- [ ] Adjust trigger frequency if needed
- [ ] Implement error notifications (email/Teams)
- [ ] Set up backup and disaster recovery
- [ ] Document operational procedures
- [ ] Train team on Logic App management
- [ ] Plan for production migration (if this is dev/test)

---

**Ready to Deploy?**

If all items in the Prerequisites and Information Gathering sections are checked, you're ready to run:

```bash
./deploy.sh
```

Good luck! 🚀
