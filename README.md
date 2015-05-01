# tfs-workitem-tools
A PowerShell module to quickly edit work items in bulk, for instance when doing process template or field migrations. This module allows you to bypass the work item rules to make it easier to migrate for instance states or field values. By default items are saved in a single batch operation with a maximum of 200 items per batch to reduce the save packet sizes. The commandlets work with VSO as well, but you cannot use the ByPassRules flag here because you will not have permission to do this on VSO.

##Available commandlets
- Edit-WorkItem
- Get-FieldValue
- Get-WorkItem
- Get-WorkItemStore
- Save-WorkItem
- Set-FieldValue
- Set-WorkItemStore
- Test-Field

##Installation
###Dependencies
* Visual Studio Team Explorer 2013

###Steps
Go to https://github.com/sanderaernouts/tfs-workitem-tools/releases and download latest release of the TfsWorkItemTools.zip archive. Unzip the archive and run the install.ps1 script. This will place necesary files in your "%USERPROFILE%\Documents\WindowsPowerShell\Modules" folder.

##Uninstalation
Remove the TfsWorkItemTools folder from the following location "%USERPROFILE%\Documents\WindowsPowerShell\Modules"



##Usage
Importing the module into your script:
```powershell
Import-Module -Name TfsWorkItemTools
```

View available cmdlets:
```powershell
Get-Command -Module TfsWorkItemTools
```

View help information per cmdlet:
```powershell
Get-Help Set-WorkItemStore
```

*note: you can use the -Detailed or -Full switch of the Get-Help cmdlet to more help information including examples*

View the full help documentation for all cmdlets in the module:
```powershell
Get-Command -Module TfsWorkItemTools | Get-Help -Full
```

This module uses a Azure PowerShell like approach for setting the work item store (similar behaviour as [Set-AzureSubscription](https://msdn.microsoft.com/en-us/library/dn495189.aspx)). Before you can use any of the commands in this module you will have to set the work item store. It is stored as a private module variable and used by the other cmdlets to prevent the need to pass the work item store into each and every cmdlet.

##Example
```powershell
#First set the work item store to be used by this module by passing in the collection URL and request to use the ByPassRules flag
Set-WorkItemStore "https://your.tfs.server/tfs/yourcollection" -ByPassRules

#Retrieve all WorkItem objects which are bugs or product backlog items and are placed under the area path "MyProject\".
$workitems = Get-WorkItem "SELECT [State], [Title] From WorkItems Where [Work Item Type] IN ('Bug', 'Product Backlog Item)' AND [Area Path] UNDER 'MyProject\'"

Edit-WorkItem $workitems {
  param($workitem)

  #To avoid exceptions test whether the field actually exists on the work item
  if(Test-Field $workitem "My.Custom.Field")
  {
    #assign a default value. Note that you can use any PowerShell based logic here such as copying values from one field to another, using a switch statement to map values, etc.
    Set-FieldValue $workitem "My.Custom.Field" 123
  }
}

#Save the work items in batch save operations of maximum 200 items. -Verbose will show you if and how your work items are split into chunks
Save-WorkItem $workitems -Verbose
```
