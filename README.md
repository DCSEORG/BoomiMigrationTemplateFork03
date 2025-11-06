# BoomiMigrationTemplate

## Overview

This repository provides a complete solution to migrate Boomi integration workflows to Azure Logic Apps. It includes Infrastructure as Code (Bicep), deployment scripts, and comprehensive documentation.

## 🚀 Quick Start

Deploy the Logic App in one command:

```bash
./deploy.sh
```

For detailed instructions, see [QUICKSTART.md](QUICKSTART.md).

## 📁 Repository Structure

```
.
├── deploy.sh                 # One-command deployment script
├── validate.sh              # Validation script (test without deploying)
├── QUICKSTART.md            # Quick start guide
├── DEPLOYMENT.md            # Comprehensive deployment guide
├── infrastructure/          # Bicep templates and documentation
│   ├── main.bicep          # Main infrastructure template
│   ├── parameters.json     # Parameter template
│   └── README.md           # Infrastructure documentation
├── Boomi(.DAR)/            # Original Boomi workflow files
│   ├── Process/            # Boomi process definitions
│   └── Components/         # Boomi components (connections, maps)
└── .env.example            # Environment variables template
```

## ✨ What This Solution Does

The Azure Logic App (Consumption Plan) replicates the Boomi workflow:

1. **Monitors SQL Server** for new rows in the Customer table
2. **Transforms data** according to Boomi mapping:
   - `CustomerId` → `ID`
   - `Name` → `FULLNAME`
   - `Email` → `EMAILADDRESS`
3. **Inserts** transformed data into Oracle Database

## 📋 Prerequisites

- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) installed
- Azure subscription with permissions to create resources
- SQL Server database (Azure SQL or on-premises)
- Oracle Database (cloud or on-premises)

## 🎯 Deployment Options

### Option 1: Interactive Deployment (Recommended)

```bash
./deploy.sh
```

The script will prompt you for all required configuration.

### Option 2: Automated Deployment

```bash
# Copy and edit environment file
cp .env.example .env
nano .env

# Source environment and deploy
source .env
./deploy.sh
```

### Option 3: Manual Deployment

```bash
az deployment group create \
  --resource-group my-rg \
  --template-file ./infrastructure/main.bicep \
  --parameters sqlServerFqdn="..." \
               sqlDatabaseName="..." \
               # ... other parameters
```

## 📖 Documentation

- **[QUICKSTART.md](QUICKSTART.md)** - Get started in 3 steps
- **[CHECKLIST.md](CHECKLIST.md)** - Pre-deployment checklist
- **[DEPLOYMENT.md](DEPLOYMENT.md)** - Comprehensive deployment guide
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - Architecture diagrams and details
- **[SOLUTION_SUMMARY.md](SOLUTION_SUMMARY.md)** - Complete solution overview
- **[infrastructure/README.md](infrastructure/README.md)** - Infrastructure documentation

## 🔒 Security Notes

- Never commit `.env` files with real credentials
- Use Azure Key Vault for production secrets
- Review firewall rules before deployment
- Enable diagnostic logging for monitoring

## 🧪 Testing & Validation

Validate without deploying:

```bash
./validate.sh
```

Test the deployed Logic App:

```sql
INSERT INTO dbo.Customer (CustomerId, Name, Email, Active)
VALUES (100, 'Test User', 'test@example.com', 1);
```

## 💰 Cost Estimation

Logic App Consumption Plan:
- ~$0.001 per execution
- No fixed costs
- Pay only for actual usage

## 🛠️ Customization

### Change Trigger Frequency

Edit `infrastructure/main.bicep`:

```bicep
recurrence: {
  frequency: 'Minute'
  interval: 5  // Every 5 minutes
}
```

### Add More Field Mappings

Add variables in the Logic App workflow definition in `main.bicep`.

## 🐛 Troubleshooting

Common issues and solutions:

1. **Deployment fails**: Check Azure CLI is logged in (`az login`)
2. **SQL connection fails**: Verify firewall allows Azure services
3. **Oracle connection fails**: Check network connectivity
4. **Logic App doesn't trigger**: Verify table schema and trigger configuration

See [DEPLOYMENT.md](DEPLOYMENT.md) for detailed troubleshooting.

## 📚 References

- [Azure Logic Apps Documentation](https://docs.microsoft.com/en-us/azure/logic-apps/)
- [SQL Server Connector](https://learn.microsoft.com/en-us/azure/connectors/connectors-create-api-sqlazure?tabs=consumption)
- [Oracle Database Connector](https://learn.microsoft.com/en-us/azure/connectors/connectors-create-api-oracledatabase)
- [Bicep Documentation](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/)

## 🤝 Contributing

This is a template repository. Fork it and customize for your needs.

## 📄 License

This solution is provided as-is for workshop and proof-of-concept purposes.

---

## Original Template Usage

Fork or clone this repo, then replace XML files in the `Boomi(.DAR)` folder with your own Boomi workflow files if you have them, and run the deployment.

