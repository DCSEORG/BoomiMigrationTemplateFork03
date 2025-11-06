# Quick Start Guide

## Deploying the Logic App in 3 Steps

### Step 1: Prerequisites ✅

Ensure you have:
- Azure CLI installed: `az --version`
- Active Azure subscription
- SQL Server and Oracle Database accessible

### Step 2: Run Deployment 🚀

```bash
./deploy.sh
```

Follow the prompts to enter:
- Resource group name and location
- SQL Server connection details
- Oracle Database connection details

### Step 3: Verify Deployment ✓

Test the Logic App:
```sql
-- In your SQL Server database
INSERT INTO dbo.Customer (CustomerId, Name, Email, Active)
VALUES (100, 'Test User', 'test@example.com', 1);
```

Check in Azure Portal:
1. Navigate to your Resource Group
2. Open the Logic App
3. View "Runs history" to see the execution
4. Verify data in Oracle Database

## Troubleshooting

**Script won't run?**
```bash
chmod +x deploy.sh
```

**Need detailed instructions?**
See [DEPLOYMENT.md](DEPLOYMENT.md) for comprehensive guide.

**Need to understand the infrastructure?**
See [infrastructure/README.md](infrastructure/README.md) for technical details.

## What Gets Deployed

- **Logic App (Consumption)** - Serverless workflow
- **SQL Server API Connection** - Connects to your SQL Server
- **Oracle Database API Connection** - Connects to Oracle
- **Automatic Trigger** - Monitors SQL table for new rows
- **Data Transformation** - Maps fields per Boomi workflow

## Costs

Consumption plan pricing:
- ~$0.001 per execution
- No fixed costs
- Pay only for what you use

## Next Steps

1. ✅ Monitor Logic App runs
2. ✅ Customize trigger frequency if needed
3. ✅ Add error handling and retry logic
4. ✅ Set up alerts and notifications

## Support

- 📖 [Full Deployment Guide](DEPLOYMENT.md)
- 🏗️ [Infrastructure Documentation](infrastructure/README.md)
- 🐛 Issues? Check Azure Logic App run history
