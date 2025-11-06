# Architecture Diagram

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Azure Subscription                       │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │              Resource Group                              │   │
│  │                                                           │   │
│  │  ┌──────────────────────────────────────────────┐       │   │
│  │  │     Azure Logic App (Consumption Plan)       │       │   │
│  │  │                                               │       │   │
│  │  │  ┌────────────────────────────────────┐     │       │   │
│  │  │  │  Trigger: When item is created     │     │       │   │
│  │  │  │  (SQL Server Polling - 1 minute)   │     │       │   │
│  │  │  └────────────────┬───────────────────┘     │       │   │
│  │  │                   │                          │       │   │
│  │  │                   ▼                          │       │   │
│  │  │  ┌────────────────────────────────────┐     │       │   │
│  │  │  │  Data Transformation               │     │       │   │
│  │  │  │  • CustomerId → ID                 │     │       │   │
│  │  │  │  • Name → FULLNAME                 │     │       │   │
│  │  │  │  • Email → EMAILADDRESS            │     │       │   │
│  │  │  └────────────────┬───────────────────┘     │       │   │
│  │  │                   │                          │       │   │
│  │  │                   ▼                          │       │   │
│  │  │  ┌────────────────────────────────────┐     │       │   │
│  │  │  │  Action: Insert row to Oracle      │     │       │   │
│  │  │  └────────────────────────────────────┘     │       │   │
│  │  └───────────────────────────────────────────┬──┘       │   │
│  │                                              │          │   │
│  │  ┌────────────────────────────────┐         │          │   │
│  │  │  SQL Server API Connection     │◄────────┘          │   │
│  │  │  • Authentication: SQL Auth    │                    │   │
│  │  └────────────┬───────────────────┘                    │   │
│  │               │                                         │   │
│  │  ┌────────────────────────────────┐                    │   │
│  │  │  Oracle DB API Connection      │                    │   │
│  │  │  • Authentication: Basic       │                    │   │
│  │  └────────────┬───────────────────┘                    │   │
│  └───────────────┼──────────────────┼─────────────────────┘   │
└──────────────────┼──────────────────┼──────────────────────────┘
                   │                  │
                   │                  │
        ┌──────────▼─────────┐ ┌────▼──────────────┐
        │   SQL Server       │ │  Oracle Database  │
        │                    │ │                   │
        │  Table: Customer   │ │  Table:           │
        │  • CustomerId      │ │  CUSTOMER_CCS     │
        │  • Name            │ │  • ID             │
        │  • Email           │ │  • FULLNAME       │
        │  • Active          │ │  • EMAILADDRESS   │
        └────────────────────┘ └───────────────────┘
```

## Component Details

### 1. Azure Logic App (Consumption Plan)
- **Type**: Serverless workflow engine
- **Pricing**: Pay-per-execution (~$0.001/run)
- **Features**:
  - Auto-scaling
  - No infrastructure management
  - Built-in monitoring
  - Retry policies
  - Error handling

### 2. SQL Server API Connection
- **Purpose**: Connect to SQL Server or Azure SQL Database
- **Authentication**: SQL Server Authentication (username/password)
- **Capabilities**:
  - Poll for new rows
  - Execute queries
  - Automatic change detection
- **Configuration**:
  - Server: `{sqlServerFqdn}` (e.g., myserver.database.windows.net)
  - Database: `{sqlDatabaseName}`
  - Table: `dbo.Customer`

### 3. Oracle Database API Connection
- **Purpose**: Connect to Oracle Database (cloud or on-premises)
- **Authentication**: Basic authentication (username/password)
- **Capabilities**:
  - Insert rows
  - Update rows
  - Query data
- **Configuration**:
  - Server: `{oracleServer}`
  - Port: `{oraclePort}` (default: 1521)
  - Service/SID: `{oracleServiceName}`
  - Table: `CUSTOMER_CCS`

## Workflow Execution Flow

```
1. Trigger Fires (Every 1 minute)
   │
   ├─► Check SQL Server for new rows in dbo.Customer
   │
   ├─► For each new row:
   │    │
   │    ├─► Initialize variable: id = CustomerId
   │    │
   │    ├─► Initialize variable: fullName = Name
   │    │
   │    ├─► Initialize variable: emailAddress = Email
   │    │
   │    └─► Insert row to Oracle CUSTOMER_CCS table
   │         (ID, FULLNAME, EMAILADDRESS)
   │
   └─► Complete (Success/Failure logged)
```

## Data Flow

```
SQL Server                   Logic App                Oracle Database
─────────────               ──────────               ────────────────

Customer Table              Transformation           CUSTOMER_CCS Table
┌──────────────┐           ┌──────────────┐        ┌──────────────────┐
│ CustomerId: 1│ ────────► │ id = 1       │ ────►  │ ID: 1            │
│ Name: "John" │           │ fullName =   │        │ FULLNAME: "John" │
│ Email: "..." │           │   "John"     │        │ EMAILADDRESS: ..│
│ Active: 1    │           │ emailAddress │        └──────────────────┘
└──────────────┘           │   = "..."    │
                           └──────────────┘
```

## Boomi to Azure Mapping

```
Boomi Process               Azure Logic App
─────────────               ───────────────

Start Shape      ────────► (Implicit - workflow starts)
     │
     ▼
GetFromSQL       ────────► SQL Trigger (When item created)
(Connector)                • Table: dbo.Customer
     │                     • Polling interval: 1 minute
     ▼
MapToJSON        ────────► Initialize Variables
(Map Component)            • id ← CustomerId
     │                     • fullName ← Name
     ▼                     • emailAddress ← Email
PostToCCS        ────────► Oracle Insert Action
(HTTP Connector)           • Table: CUSTOMER_CCS
                          • Fields: ID, FULLNAME, EMAILADDRESS
```

## Network Architecture

### Option 1: Public Endpoints (Simplest)
```
Logic App (Azure) ──► SQL Server (Public endpoint + Firewall rules)
      │
      └──────────────► Oracle DB (Public endpoint + Firewall rules)
```

### Option 2: Hybrid Connection (More Secure)
```
Logic App (Azure) ──► Hybrid Connection ──► On-premises SQL Server
      │
      └──────────────► Hybrid Connection ──► On-premises Oracle DB
```

### Option 3: Private Endpoints (Most Secure)
```
Logic App (VNET) ──► Private Endpoint ──► Azure SQL Database
      │
      └──────────────► Private Endpoint ──► Oracle DB (via VPN/ExpressRoute)
```

## Deployment Architecture

```
Developer/DevOps              Azure
────────────────             ──────

./deploy.sh      ──────►    Azure CLI
     │                          │
     │                          ▼
     │                   Azure Resource Manager
     │                          │
     │                          ▼
     ├──────► Bicep Template ──┴──► Creates Resources:
     │        (main.bicep)            • Resource Group
     │                                • Logic App
     │                                • API Connections
     │
     └──────► Parameters
              • SQL credentials
              • Oracle credentials
              • Configuration
```

## Monitoring & Observability

```
Logic App
    │
    ├─► Run History (Built-in)
    │   • Trigger history
    │   • Action results
    │   • Duration
    │   • Status codes
    │
    ├─► Diagnostic Logs (Optional)
    │   • Workflow runtime
    │   • Action execution
    │   • Error details
    │
    └─► Azure Monitor (Optional)
        • Metrics
        • Alerts
        • Application Insights integration
```

## Scaling Behavior

```
Load Level          Logic App Behavior
──────────         ──────────────────

Low                1 instance
(1-10 items/min)   Single execution

Medium             2-5 instances
(10-50 items/min)  Parallel execution (limited by concurrency)

High               Up to 25 instances (default max)
(50+ items/min)    Throttling may occur if exceeds limit

Customization:     Modify concurrency settings in Bicep
                   runtimeConfiguration.concurrency.runs
```

## Security Architecture

```
┌────────────────────────────────────────────────┐
│  Security Layers                               │
│                                                 │
│  1. Authentication                             │
│     • Azure AD for Logic App access           │
│     • SQL Auth for SQL Server                 │
│     • Basic Auth for Oracle DB                │
│                                                 │
│  2. Authorization                              │
│     • Azure RBAC for resource management      │
│     • Database user permissions               │
│                                                 │
│  3. Network Security                           │
│     • Firewall rules (SQL Server)             │
│     • Network ACLs (Oracle DB)                │
│     • Optional: Private Endpoints             │
│                                                 │
│  4. Data Protection                            │
│     • TLS for data in transit                 │
│     • Encrypted connections                   │
│     • Secure parameter handling               │
│                                                 │
│  5. Secrets Management                         │
│     • Secure parameters in deployment         │
│     • Optional: Azure Key Vault integration   │
└────────────────────────────────────────────────┘
```

## Cost Breakdown

```
Component               Cost Structure
─────────              ──────────────

Logic App              $0.001 per execution
                      • Trigger execution: $0.001
                      • Action execution: Included in execution cost
                      • No fixed cost

API Connections        No additional cost
                      • SQL connector: Included
                      • Oracle connector: Included

Data Transfer          Standard Azure rates
                      • Ingress: Free
                      • Egress: Varies by region

Example Monthly Cost:
• 1,000 executions/day × 30 days = 30,000 executions
• 30,000 × $0.001 = $30/month
```

## Comparison: Boomi vs Azure Logic Apps

```
Feature                Boomi                Logic Apps
───────               ──────               ──────────

Hosting               Self-managed/Cloud   Fully managed (Azure)
Pricing               License-based        Pay-per-execution
Scaling               Manual               Automatic
Monitoring            Boomi dashboard      Azure Monitor + Portal
Development           Boomi Studio         Azure Portal + VS Code
Source Control        Limited              Full (Bicep/ARM)
CI/CD                 Custom               Native (Azure DevOps/GitHub)
```

## References

- **Logic Apps Architecture**: https://docs.microsoft.com/en-us/azure/logic-apps/logic-apps-overview
- **SQL Connector Reference**: https://learn.microsoft.com/en-us/azure/connectors/connectors-create-api-sqlazure
- **Oracle Connector Reference**: https://learn.microsoft.com/en-us/azure/connectors/connectors-create-api-oracledatabase
