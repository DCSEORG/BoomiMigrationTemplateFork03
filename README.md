# BoomiMigrationTemplate

Fork or clone this repo then add then replace XML files in DAR folder and run the following prompt in the coding Agent:

`Create all the Bicep, Infrastructure as code, json code to create a Logic app consumption plan (not standard plan) in Azure that can move data from SQL server to Oracle Database when new rows are added to the SQL Server database and transform the data in the way that the Boomi files do in this repo (in the Boomi folder). Create a deploy.sh file that can be run on one terminal command that can deploy the solution to azure. The logic app should trigger when a new item is added in the SQL database.

Use this documentation for best practice: https://learn.microsoft.com/en-us/azure/connectors/connectors-create-api-sqlazure?tabs=consumption also this https://learn.microsoft.com/en-us/azure/connectors/connectors-create-api-oracledatabase

Start by making a list of the tasks you will do as checkboxes for the pull request and estimate the time it will take you for each task as a well as a total time estimate at the bottom. Also add a final checkbox for validation & tests and only mark that as checked when you have done all work and are about to terminate the workflow for the GitHub action you are running. Do not use codeql tool or other tools to validate the code as this if for POC not PROD and we need it quickly for our workshop.`

