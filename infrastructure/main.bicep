// Main Bicep template for Logic App Consumption Plan
// This creates a Logic App that syncs data from SQL Server to Oracle Database

@description('Location for all resources')
param location string = resourceGroup().location

@description('Name of the Logic App')
param logicAppName string = 'logic-sql-to-oracle-sync'

@description('SQL Server connection name')
param sqlConnectionName string = 'sql-connection'

@description('SQL Server fully qualified domain name')
param sqlServerFqdn string

@description('SQL Database name')
param sqlDatabaseName string

@description('SQL Server username')
@secure()
param sqlUsername string

@description('SQL Server password')
@secure()
param sqlPassword string

@description('SQL table name to monitor')
param sqlTableName string = 'dbo.Customer'

@description('Oracle Database connection name')
param oracleConnectionName string = 'oracle-connection'

@description('Oracle server address')
param oracleServer string

@description('Oracle port')
param oraclePort string = '1521'

@description('Oracle service name or SID')
param oracleServiceName string

@description('Oracle username')
@secure()
param oracleUsername string

@description('Oracle password')
@secure()
param oraclePassword string

@description('Oracle target table name')
param oracleTableName string = 'CUSTOMER_CCS'

@description('Tags to apply to all resources')
param tags object = {
  Environment: 'Development'
  Application: 'SQL-Oracle-Sync'
  ManagedBy: 'Bicep'
}

// SQL Server API Connection
resource sqlConnection 'Microsoft.Web/connections@2016-06-01' = {
  name: sqlConnectionName
  location: location
  tags: tags
  properties: {
    displayName: 'SQL Server Connection'
    api: {
      id: subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'sql')
    }
    parameterValues: {
      server: sqlServerFqdn
      database: sqlDatabaseName
      username: sqlUsername
      password: sqlPassword
      authType: 'basic'
    }
  }
}

// Oracle Database API Connection
resource oracleConnection 'Microsoft.Web/connections@2016-06-01' = {
  name: oracleConnectionName
  location: location
  tags: tags
  properties: {
    displayName: 'Oracle Database Connection'
    api: {
      id: subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'oracle')
    }
    parameterValues: {
      server: oracleServer
      port: oraclePort
      sid: oracleServiceName
      username: oracleUsername
      password: oraclePassword
    }
  }
}

// Logic App (Consumption Plan)
resource logicApp 'Microsoft.Logic/workflows@2019-05-01' = {
  name: logicAppName
  location: location
  tags: tags
  properties: {
    state: 'Enabled'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {
        '$connections': {
          defaultValue: {}
          type: 'Object'
        }
      }
      triggers: {
        'When_an_item_is_created': {
          type: 'ApiConnection'
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'sql\'][\'connectionId\']'
              }
            }
            method: 'get'
            path: '/v2/datasets/@{encodeURIComponent(encodeURIComponent(\'${sqlServerFqdn}\'))},@{encodeURIComponent(encodeURIComponent(\'${sqlDatabaseName}\'))}/tables/@{encodeURIComponent(encodeURIComponent(\'${sqlTableName}\'))}/onnewitems'
          }
          recurrence: {
            frequency: 'Minute'
            interval: 1
          }
          splitOn: '@triggerBody()?[\'value\']'
        }
      }
      actions: {
        'Initialize_transformed_id': {
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'id'
                type: 'integer'
                value: '@triggerBody()?[\'CustomerId\']'
              }
            ]
          }
          runAfter: {}
        }
        'Initialize_transformed_fullName': {
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'fullName'
                type: 'string'
                value: '@triggerBody()?[\'Name\']'
              }
            ]
          }
          runAfter: {
            'Initialize_transformed_id': [
              'Succeeded'
            ]
          }
        }
        'Initialize_transformed_emailAddress': {
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'emailAddress'
                type: 'string'
                value: '@triggerBody()?[\'Email\']'
              }
            ]
          }
          runAfter: {
            'Initialize_transformed_fullName': [
              'Succeeded'
            ]
          }
        }
        'Insert_row_into_Oracle': {
          type: 'ApiConnection'
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'oracle\'][\'connectionId\']'
              }
            }
            method: 'post'
            path: '/datasets/default/tables/@{encodeURIComponent(encodeURIComponent(\'${oracleTableName}\'))}/items'
            body: {
              ID: '@variables(\'id\')'
              FULLNAME: '@variables(\'fullName\')'
              EMAILADDRESS: '@variables(\'emailAddress\')'
            }
          }
          runAfter: {
            'Initialize_transformed_emailAddress': [
              'Succeeded'
            ]
          }
        }
      }
      outputs: {}
    }
    parameters: {
      '$connections': {
        value: {
          sql: {
            connectionId: sqlConnection.id
            connectionName: sqlConnectionName
            id: subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'sql')
          }
          oracle: {
            connectionId: oracleConnection.id
            connectionName: oracleConnectionName
            id: subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'oracle')
          }
        }
      }
    }
  }
}

// Outputs
output logicAppId string = logicApp.id
output logicAppName string = logicApp.name
output sqlConnectionId string = sqlConnection.id
output oracleConnectionId string = oracleConnection.id
output logicAppTriggerUrl string = listCallbackUrl('${logicApp.id}/triggers/When_an_item_is_created', '2019-05-01').value
