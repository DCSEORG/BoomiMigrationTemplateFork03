#!/bin/bash

###############################################################################
# Deploy Script for Logic App (SQL to Oracle Sync)
# 
# This script deploys the Azure Logic App infrastructure using Bicep
# One-command deployment: ./deploy.sh
###############################################################################

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if Azure CLI is installed
check_azure_cli() {
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI is not installed. Please install it from https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
        exit 1
    fi
    print_success "Azure CLI is installed"
}

# Function to check if user is logged in to Azure
check_azure_login() {
    print_info "Checking Azure login status..."
    if ! az account show &> /dev/null; then
        print_warning "Not logged in to Azure. Initiating login..."
        az login
    else
        print_success "Already logged in to Azure"
    fi
}

# Function to select or create resource group
setup_resource_group() {
    print_info "Setting up resource group..."
    
    read -p "Enter resource group name (default: rg-logic-app-sql-oracle): " RESOURCE_GROUP
    RESOURCE_GROUP=${RESOURCE_GROUP:-rg-logic-app-sql-oracle}
    
    read -p "Enter location (default: eastus): " LOCATION
    LOCATION=${LOCATION:-eastus}
    
    # Check if resource group exists
    if az group exists --name "$RESOURCE_GROUP" --output tsv | grep -q "true"; then
        print_warning "Resource group '$RESOURCE_GROUP' already exists"
        read -p "Do you want to use this existing resource group? (y/n): " use_existing
        if [[ ! $use_existing =~ ^[Yy]$ ]]; then
            print_error "Deployment cancelled by user"
            exit 1
        fi
    else
        print_info "Creating resource group '$RESOURCE_GROUP' in '$LOCATION'..."
        az group create --name "$RESOURCE_GROUP" --location "$LOCATION" --output none
        print_success "Resource group created"
    fi
}

# Function to gather deployment parameters
gather_parameters() {
    print_info "Gathering deployment parameters..."
    echo ""
    print_warning "Please provide the following information:"
    echo ""
    
    # Logic App name
    read -p "Logic App name (default: logic-sql-to-oracle-sync): " LOGIC_APP_NAME
    LOGIC_APP_NAME=${LOGIC_APP_NAME:-logic-sql-to-oracle-sync}
    
    # SQL Server parameters
    echo ""
    print_info "SQL Server Configuration:"
    read -p "SQL Server FQDN (e.g., myserver.database.windows.net): " SQL_SERVER_FQDN
    read -p "SQL Database name: " SQL_DATABASE_NAME
    read -p "SQL Username: " SQL_USERNAME
    read -sp "SQL Password: " SQL_PASSWORD
    echo ""
    read -p "SQL Table name (default: dbo.Customer): " SQL_TABLE_NAME
    SQL_TABLE_NAME=${SQL_TABLE_NAME:-dbo.Customer}
    
    # Oracle Database parameters
    echo ""
    print_info "Oracle Database Configuration:"
    read -p "Oracle Server address: " ORACLE_SERVER
    read -p "Oracle Port (default: 1521): " ORACLE_PORT
    ORACLE_PORT=${ORACLE_PORT:-1521}
    read -p "Oracle Service Name/SID: " ORACLE_SERVICE_NAME
    read -p "Oracle Username: " ORACLE_USERNAME
    read -sp "Oracle Password: " ORACLE_PASSWORD
    echo ""
    read -p "Oracle Target Table name (default: CUSTOMER_CCS): " ORACLE_TABLE_NAME
    ORACLE_TABLE_NAME=${ORACLE_TABLE_NAME:-CUSTOMER_CCS}
    
    echo ""
}

# Function to validate required parameters
validate_parameters() {
    print_info "Validating parameters..."
    
    local has_error=false
    
    if [ -z "$SQL_SERVER_FQDN" ]; then
        print_error "SQL Server FQDN is required"
        has_error=true
    fi
    
    if [ -z "$SQL_DATABASE_NAME" ]; then
        print_error "SQL Database name is required"
        has_error=true
    fi
    
    if [ -z "$SQL_USERNAME" ]; then
        print_error "SQL Username is required"
        has_error=true
    fi
    
    if [ -z "$SQL_PASSWORD" ]; then
        print_error "SQL Password is required"
        has_error=true
    fi
    
    if [ -z "$ORACLE_SERVER" ]; then
        print_error "Oracle Server address is required"
        has_error=true
    fi
    
    if [ -z "$ORACLE_SERVICE_NAME" ]; then
        print_error "Oracle Service Name/SID is required"
        has_error=true
    fi
    
    if [ -z "$ORACLE_USERNAME" ]; then
        print_error "Oracle Username is required"
        has_error=true
    fi
    
    if [ -z "$ORACLE_PASSWORD" ]; then
        print_error "Oracle Password is required"
        has_error=true
    fi
    
    if [ "$has_error" = true ]; then
        print_error "Parameter validation failed. Please provide all required parameters."
        exit 1
    fi
    
    print_success "Parameters validated"
}

# Function to deploy the infrastructure
deploy_infrastructure() {
    print_info "Starting deployment of Logic App infrastructure..."
    
    DEPLOYMENT_NAME="logic-app-deployment-$(date +%Y%m%d-%H%M%S)"
    
    print_info "Deployment name: $DEPLOYMENT_NAME"
    print_info "This may take a few minutes..."
    
    # Deploy using Bicep
    az deployment group create \
        --name "$DEPLOYMENT_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --template-file ./infrastructure/main.bicep \
        --parameters location="$LOCATION" \
        --parameters logicAppName="$LOGIC_APP_NAME" \
        --parameters sqlServerFqdn="$SQL_SERVER_FQDN" \
        --parameters sqlDatabaseName="$SQL_DATABASE_NAME" \
        --parameters sqlUsername="$SQL_USERNAME" \
        --parameters sqlPassword="$SQL_PASSWORD" \
        --parameters sqlTableName="$SQL_TABLE_NAME" \
        --parameters oracleServer="$ORACLE_SERVER" \
        --parameters oraclePort="$ORACLE_PORT" \
        --parameters oracleServiceName="$ORACLE_SERVICE_NAME" \
        --parameters oracleUsername="$ORACLE_USERNAME" \
        --parameters oraclePassword="$ORACLE_PASSWORD" \
        --parameters oracleTableName="$ORACLE_TABLE_NAME" \
        --output table
    
    if [ $? -eq 0 ]; then
        print_success "Deployment completed successfully!"
    else
        print_error "Deployment failed. Check the error messages above."
        exit 1
    fi
}

# Function to display deployment summary
display_summary() {
    print_info "Deployment Summary:"
    echo ""
    echo "Resource Group: $RESOURCE_GROUP"
    echo "Location: $LOCATION"
    echo "Logic App Name: $LOGIC_APP_NAME"
    echo ""
    
    print_info "Retrieving deployment outputs..."
    
    # Get Logic App details
    LOGIC_APP_URL=$(az logic workflow show \
        --resource-group "$RESOURCE_GROUP" \
        --name "$LOGIC_APP_NAME" \
        --query "id" \
        --output tsv 2>/dev/null || echo "N/A")
    
    echo ""
    print_success "Logic App deployed successfully!"
    echo "Logic App Resource ID: $LOGIC_APP_URL"
    echo ""
    print_info "You can view and manage your Logic App in the Azure Portal:"
    echo "https://portal.azure.com/#resource$LOGIC_APP_URL"
    echo ""
    print_warning "Next Steps:"
    echo "1. Verify the SQL Server firewall allows Azure services"
    echo "2. Ensure the Oracle Database is accessible from Azure"
    echo "3. Test the Logic App trigger by adding a new row to the SQL Server table"
    echo "4. Monitor the Logic App runs in the Azure Portal"
    echo ""
}

# Main execution
main() {
    echo ""
    print_info "================================================="
    print_info "  Azure Logic App Deployment Script"
    print_info "  SQL Server to Oracle Database Sync"
    print_info "================================================="
    echo ""
    
    # Check prerequisites
    check_azure_cli
    check_azure_login
    
    # Setup resource group
    setup_resource_group
    
    # Gather parameters
    gather_parameters
    
    # Validate parameters
    validate_parameters
    
    # Confirm deployment
    echo ""
    print_warning "Ready to deploy with the following configuration:"
    echo "  Resource Group: $RESOURCE_GROUP"
    echo "  Location: $LOCATION"
    echo "  Logic App: $LOGIC_APP_NAME"
    echo "  SQL Server: $SQL_SERVER_FQDN"
    echo "  Oracle Server: $ORACLE_SERVER"
    echo ""
    read -p "Proceed with deployment? (y/n): " confirm
    
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        print_warning "Deployment cancelled by user"
        exit 0
    fi
    
    # Deploy infrastructure
    deploy_infrastructure
    
    # Display summary
    display_summary
    
    print_success "Deployment complete!"
}

# Run main function
main
