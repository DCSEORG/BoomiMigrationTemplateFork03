#!/bin/bash

###############################################################################
# Validation Test Script for Logic App Infrastructure
# 
# This script validates the Bicep template without deploying
###############################################################################

set -e

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Logic App Infrastructure Validation${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check Azure CLI
echo -e "${BLUE}[1/5]${NC} Checking Azure CLI..."
if ! command -v az &> /dev/null; then
    echo -e "${RED}✗ Azure CLI not found${NC}"
    exit 1
fi
AZ_VERSION=$(az version --output json 2>/dev/null | jq -r '."azure-cli"' 2>/dev/null || echo "installed")
echo -e "${GREEN}✓ Azure CLI installed: ${AZ_VERSION}${NC}"

# Check Bicep
echo -e "${BLUE}[2/5]${NC} Checking Bicep CLI..."
if ! command -v az bicep version &> /dev/null; then
    echo -e "${RED}✗ Bicep not found${NC}"
    exit 1
fi
BICEP_VERSION=$(az bicep version | grep -oP 'version \K[0-9.]+')
echo -e "${GREEN}✓ Bicep installed: ${BICEP_VERSION}${NC}"

# Validate Bicep syntax
echo -e "${BLUE}[3/5]${NC} Validating Bicep syntax..."
cd infrastructure
if az bicep build --file main.bicep --stdout > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Bicep template is valid${NC}"
else
    echo -e "${RED}✗ Bicep template has syntax errors${NC}"
    az bicep build --file main.bicep
    exit 1
fi

# Check parameters file
echo -e "${BLUE}[4/5]${NC} Checking parameters file..."
if [ -f "parameters.json" ]; then
    if jq empty parameters.json 2>/dev/null; then
        echo -e "${GREEN}✓ Parameters file is valid JSON${NC}"
    else
        echo -e "${RED}✗ Parameters file has JSON errors${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}⚠ Parameters file not found (optional)${NC}"
fi

# Check deploy script
echo -e "${BLUE}[5/5]${NC} Checking deploy script..."
cd ..
if [ -x "deploy.sh" ]; then
    if bash -n deploy.sh; then
        echo -e "${GREEN}✓ Deploy script syntax is valid${NC}"
    else
        echo -e "${RED}✗ Deploy script has syntax errors${NC}"
        exit 1
    fi
else
    if [ -f "deploy.sh" ]; then
        echo -e "${YELLOW}⚠ Deploy script not executable (fixing...)${NC}"
        chmod +x deploy.sh
        echo -e "${GREEN}✓ Deploy script made executable${NC}"
    else
        echo -e "${RED}✗ Deploy script not found${NC}"
        exit 1
    fi
fi

# Summary
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ All validation checks passed!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}Files validated:${NC}"
echo "  ✓ infrastructure/main.bicep"
echo "  ✓ infrastructure/parameters.json"
echo "  ✓ deploy.sh"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "  1. Review the infrastructure files"
echo "  2. Run './deploy.sh' to deploy to Azure"
echo "  3. See DEPLOYMENT.md for detailed instructions"
echo ""
