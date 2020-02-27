# Audit Azure Security Center

This script can be used to get Azure Security Center settings. For more information read this article https://azsec.azurewebsites.net/2019/12/15/audit-azure-security-center-in-your-tenant/

| **Information** | **Why** |
| --------------- | ------- |
| Pricing Tier | As of this article there are 8 resource types that are covered by Azure Security Center. You need to see whether you want to take advantage of Standard tier for a specific resource type (e.g. Kubernete) |
| Auto Provisioning | this setting tells you whether Microsoft Monitoring Agent is automatically installed on all virtual machines in your subscription.|
| Data Collection Workspace | this tells you whether data collected from Azure Security Center is stored in default workspace (Microsoft back-end) or a user-defined workspace (the one you create and manage).|
| Contact and Notification | information about email and phone for notification, as well setting of Send email notification for high severity alerts and Also send email notification to subscription owners |

# Reference
Below are some other references related to Azure Security Center that you may need to check out:

- [Connect Azure Security Center to Azure Sentinel programatically](http://azsec.azurewebsites.net/2019/12/14/connect-azure-security-center-to-azure-sentinel-programatically/)
- [Working with Azure Security Center Alert from Azure Sentinel](http://azsec.azurewebsites.net/2019/12/10/working-with-azure-security-center-alert-from-azure-sentinel/)
- [Simulate alerts to be caught by ASC](http://azsec.azurewebsites.net/2019/12/02/simulate-alerts-to-be-caught-by-asc/)
- [Work with Azure Security Center alert in Log Analytics](http://azsec.azurewebsites.net/2019/11/29/work-with-azure-security-center-alert-in-log-analytics/)
- [A bit about ASC Alert in Log Analytics workspace](https://azsec.azurewebsites.net/2019/11/24/a-bit-about-asc-alert-in-log-analytics-workspace/)
- [What is securitydata resource group in Microsoft Azure?](https://azsec.azurewebsites.net/2017/04/14/what-is-securitydata-resource-group-in-microsoft-azure/)
