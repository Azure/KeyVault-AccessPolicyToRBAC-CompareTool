Write-output "`nKey Vault Access Policy to RBAC permissions comparison report to help with migration to RBAC permission model"
Write-output "It reads Access Policies in Key Vault and check if there is existing RBAC role assignment with same permissions"
Write-output "It will print only missing RBAC data actions for each security principal (user/app)"
Write-output "It does not cover over priviliged role assignments"
Write-output "KNOWN LIMITATIONS:" 
Write-Output "  - Compound Identity (user+app) is not supported`n`n"

$mappingTable = $null
#Read Access Policy RBAC Mapping
$mappingTable = Import-Csv -Path ./AcessPolicyRBACMapping.csv 

If($mappingTable -eq $null)
{
    break
}

$keyVaultName = Read-Host -Prompt 'Input Key Vault name for comparison'
$keyVault = $null
$keyVault = (Get-AzKeyVault -VaultName $keyVaultName)
if($keyVault -eq $null)
{
    Write-Error "Cannot access Key Vault $keyVaultName"
    break
}

# Populate Access Policy Permission to RBAC Data Actions mapping and RBAC Data Actions collection
$APtoRBACMap=@{}
$AllRBACDataActions=@{}
foreach($r in $mappingTable)
{
    $dataActionArray =($r.'RBAC Data Action'.ToLower()).Split(";")
    $dataActionHashTable = @{}
    foreach($dataAction in $dataActionArray)
    {
        $dataActionHashTable.Item($dataAction)=""
        $AllRBACDataActions.Item($dataAction)=""
    }
    $APtoRBACMap.Item($r.'Access Policy Permission'.ToLower())=$dataActionHashTable
}

# Read AKV Access Policies and populate identity to permissions mapping
$APPermissionsByIdentity = @{}
foreach ($ap in $($keyVault.AccessPolicies))
{
   foreach($keysPermission in $ap.PermissionsToKeys)
    {
        if ($null -eq $APPermissionsByIdentity.Item($ap.ObjectId) -or -not $APPermissionsByIdentity.Item($ap.ObjectId).ContainsKey("key " + $keysPermission.ToLower())) {
            $APPermissionsByIdentity.Item($ap.ObjectId) += @{("key " + $keysPermission.ToLower())=""}
        }
    }
    foreach($keysPermission in $ap.PermissionsToCertificates)
    {
        if ($null -eq $APPermissionsByIdentity.Item($ap.ObjectId) -or -not $APPermissionsByIdentity.Item($ap.ObjectId).ContainsKey("certificate " + $keysPermission.ToLower())) {
            $APPermissionsByIdentity.Item($ap.ObjectId) += @{("certificate " + $keysPermission.ToLower())=""}
        }
    }
    foreach($keysPermission in $ap.PermissionsToSecrets)
    {
        if ($null -eq $APPermissionsByIdentity.Item($ap.ObjectId) -or -not $APPermissionsByIdentity.Item($ap.ObjectId).ContainsKey("secret " + $keysPermission.ToLower())) {
            $APPermissionsByIdentity.Item($ap.ObjectId) += @{("secret " + $keysPermission.ToLower())=""}
        }
    }
    foreach($keysPermission in $ap.PermissionsToStorage)
    {
        if ($null -eq $APPermissionsByIdentity.Item($ap.ObjectId) -or -not $APPermissionsByIdentity.Item($ap.ObjectId).ContainsKey("storage " + $keysPermission.ToLower())) {
            $APPermissionsByIdentity.Item($ap.ObjectId) += @{("storage " + $keysPermission.ToLower())=""}
        }
    }
}

Write-Output "Key Vault Access Policies Permissions"
$APPermissionsByIdentity

#Read role assignments key vault data actions
$RBACDataActionsByIdentity = @{}
$roleAssignments = Get-AzRoleAssignment -Scope $keyVault.ResourceId

foreach($ra in $roleAssignments)
{
    $asignedDataActions = (Get-AzRoleDefinition -Id $ra.RoleDefinitionId).DataActions
    foreach($ada in $asignedDataActions)
    {
        $ada = $ada.ToLower()
        #if all add all Key Vault RBAC data actions to per identity map
        if($ada -eq "*" -Or $ada -eq "microsoft.keyVault/*" -Or $ada  -eq "microsoft.keyVault/vaults/*")
        {
            $RBACDataActionsByIdentity.Item($ra.ObjectId) = @{}
            $RBACDataActionsByIdentity.Item($ra.ObjectId) += $AllRBACDataActions
        }
        #otherwise add if it is Key Vault data action 
        elseif($ada.StartsWith("microsoft.keyvault"))
        {
           #if contains wildcard, match it using regex
           if($ada.Contains("*"))
           {
                $pattern = $ada.Replace("*",".*")+"$"
                foreach($da in $AllRBACDataActions.Keys){
                    
                    if($da -match $pattern)
                    {   
                        #check if an item is already added 
                        if($RBACDataActionsByIdentity.Item($ra.ObjectId) -eq $null -Or -Not $RBACDataActionsByIdentity.Item($ra.ObjectId).ContainsKey($da)){
                            $RBACDataActionsByIdentity.Item($ra.ObjectId) += @{$da=""}
                        }
                    }
                }
           }
           else
           {
                #check if an item is already added
                if($RBACDataActionsByIdentity.Item($ra.ObjectId) -eq $null -Or -Not $RBACDataActionsByIdentity.Item($ra.ObjectId).ContainsKey($ada)){
                    $RBACDataActionsByIdentity.Item($ra.ObjectId) += @{$ada=""}
                }
           }  
        }
    }
}

Write-Output "`nKey Vault Role Assignments Data Actions`n"
$RBACDataActionsByIdentity

Write-Output "`nCOMPARISON REPORT`n"

#Compare Access Policies to RBAC
foreach($identity in $APPermissionsByIdentity.Keys)
{
    $identityDisplayName = ($keyVault.AccessPolicies | Where-Object -Property ObjectId -eq "$identity").DisplayName
    Write-Output "`nChecking Identity : $identity $identityDisplayName"
    $missingDACounter = 0
    If(-Not $RBACDataActionsByIdentity.ContainsKey($identity))
    {
        Write-Output "There is no role assigned for identity: $identity $identityDisplayName"
        continue
    }
    foreach($permission in $APPermissionsByIdentity.Item($identity).Keys)
    {
        
        $mappedDataActions = $APtoRBACMap.Item($permission).Keys
        foreach($mappedDA in $mappedDataActions){
            if(-Not $RBACDataActionsByIdentity.Item($identity).ContainsKey($mappedDA))
            {
                Write-Output "Missing data action : $mappedDA"
                $missingDACounter += 1
            }
        }
    }
    If ($missingDACounter -eq 0)
    {
        Write-Output "All ACL permissions are matched for identity $identity $identityDisplayName"
    }
}
