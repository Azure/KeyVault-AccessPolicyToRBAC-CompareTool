# KeyVault-AccessPolicyToRBAC-CompareTool

PowerShell tool to compare Key Vault access policies to assigned RBAC roles to help with Access Policy to RBAC Permission Model migration.
The tool intent is to provide sanity check when migrating existing Key Vault to RBAC permission model to ensure that assigned roles with underlying data actions cover existing Access Policies.

# Usage Instruction

## Prerequisites
- Download project files to your enviroment ('AccessPolicyRBACMapping.csv', 'CompareAccessPolicyToRBAC.ps1')
- Use Windows PowerShell or Cloud Shell

1. Connect to Azure: 'Connect-AzAccount'
2. Execute script '.\CompareAccessPolicyToRBAC.ps1'
3. Provide Key Vault Name for comparison

> [!NOTE]
> Switching from RBAC permission model is reversible action and in case of an issue, you can switch back to Access Policies at any time.

Sample Result:
```
COMPARISON REPORT


Checking Identity : <identity1> <identity display name>
There is no role assigned for identity: <identity1> <identity1 display name>

Checking Identity : <identity2> <identity2 display name>
All ACL permissions are matched for identity <identity2> <identity2 display name>

Checking Identity : <identity3> <identity3 display name>
Missing data action : microsoft.keyvault/vaults/keys/backup/action
Missing data action : microsoft.keyvault/vaults/keys/recover/action
Missing data action : microsoft.keyvault/vaults/keys/create/action
Missing data action : microsoft.keyvault/vaults/keys/restore/action
Missing data action : microsoft.keyvault/vaults/keys/delete
Missing data action : microsoft.keyvault/vaults/keys/update/action
Missing data action : microsoft.keyvault/vaults/keys/import/action
Missing data action : microsoft.keyvault/vaults/keys/purge/action
```

# Suppport
This project is maintained by Microsoft community members. It is not supported by Microsoft Customer Support Services and normal service level agreements do not apply. For questions, issues with using this tool please create an issue in this project.

## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft 
trademarks or logos is subject to and must follow 
[Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks/usage/general).
Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship.
Any use of third-party trademarks or logos are subject to those third-party's policies.
