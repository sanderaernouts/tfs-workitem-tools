<#
  .SYNOPSIS    
    Sets the work item store to be used by this module. Work item store can be requested with the ByPassRules flag to allow you to bypass rule validation on save.  
  .PARAMETER Collection 
   Collection URL, for example https://tfs.example.com/tfs/myCollection 
  .PARAMETER ByPassRules 
   Allows you to bypass rule validation on save, default is $false 
  .EXAMPLE   
   Set-WorkItemStore -Collection "https://tfs.example.com/tfs/myCollection" 
  .EXAMPLE   
   Set-WorkItemStore -Collection "https://tfs.example.com/tfs/myCollection" -ByPassRules
#>

function Set-WorkItemStore
{
    param([string] $Collection, [Switch] $ByPassRules = $false)

    #load assemblies
	[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.TeamFoundation.Client") 
	[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.TeamFoundation.WorkItemTracking.Client")
    
    $teamProjectCollection = New-Object Microsoft.TeamFoundation.Client.TfsTeamProjectCollection $Collection

	if($ByPassRules)
	{
		$flags = [Microsoft.TeamFoundation.WorkItemTracking.Client.WorkItemStoreFlags]::BypassRules
	}else{
		$flags = [Microsoft.TeamFoundation.WorkItemTracking.Client.WorkItemStoreFlags]::None
	}

    $Script:TFSWorkItemStore = New-Object Microsoft.TeamFoundation.WorkItemTracking.Client.WorkItemStore $teamProjectCollection,$flags
}

<#
  .SYNOPSIS    
    Gets the work item store be used by this module. Note that you will have to run Set-WorkItemStore before running this command.
  .EXAMPLE   
   Get-WorkItemStore
#>
function Get-WorkItemStore
{
	VerifyWorkItemStoreSet
	return $Script:TFSWorkItemStore
}

<#
  .SYNOPSIS    
    Edits the selected work item using by executing the provided script block. The WorkItem object will be passed as the first parameter into the script block  
  .PARAMETER Items 
   One or more WorkItem objects 
  .PARAMETER ScriptBlock 
   The script block to execute for each work item. Note that a WorkItem object will be passed as a first parameter into the script block
  .EXAMPLE   
    Edit-WorkItem -items $items -ScriptBlock {
		param($workitem)
		$workitem.Open()
		
		Write-Host $workitem.Title
	} 
  .EXAMPLE   
#>
function Edit-WorkItem
{
	param(
		[parameter(Mandatory)]
	    $items,
	    [parameter(Mandatory)] 
		$ScriptBlock
	)

	VerifyWorkItemStoreSet

	$count = $items.count
	Write-Verbose "Editing $count items"
	$items | % {
		Invoke-Command $ScriptBlock -ArgumentList $_
	}
}

<#
  .SYNOPSIS    
    Saves one or more work items using the work item store set for this module. If more then 200 work item objects are passed at once the save operation is split into chunks of 200 to reduce save package sizes.

    Note that you will have to run Set-WorkItemStore before running this command.
  .PARAMETER Items 
   One or more WorkItem objects 
  
  .EXAMPLE   
    Save-WorkItem -items $items
  .EXAMPLE   
    Save-WorkItem $items
#>
function Save-WorkItem
{
	Param(
		[parameter(Mandatory)]
		$items
	)

	VerifyWorkItemStoreSet

	if($items.Count -gt 200)
		{
			$count = $items.Count
			Write-Verbose "Saving more then 200 items at once ($count items), splitting the save operation into chunks of 200"
			$chunks = SplitArray -inArray $items -size 200
		
			#recursively call the Save-WorkItem operation with smaller chunks
			$chunks | % {
				Save-WorkItem $_ 
			}

			return
		}

	$store = $Script:TFSWorkItemStore

	$errors = $store.BatchSave($items)
	$errors| % {
		PrintBatchSaveError $_
	}
}

<#
  .SYNOPSIS    
    Sets the value for a field on a single work item object.
  .PARAMETER WorkItem 
   One or more WorkItem objects .
  .PARAMETER Name
   Name or reference name of a field on the work item
  .PARAMETER Value
   The value to assign to the field, note that the value type should match the field type.
  .EXAMPLE   
    Set-Field $workitem -Name 'Severity' -value '2 - Major'
#>
function Set-Field {
	Param(
		$WorkItem,
		[string]$Name,
		$Value
	)

	$Workitem.Fields[$Name].value = $Value
}

<#
  .SYNOPSIS    
    Gets the value for a field on a single work item object.
  .PARAMETER WorkItem 
   One or more WorkItem objects .
  .PARAMETER Name
   Name or reference name of a field on the work item
  .EXAMPLE   
    Set-Field $workitem -Name 'Severity' -value '2 - Major'
#>
function Get-Field {
	Param(
		$WorkItem,
		$Name
	)

	return $WorkItem.Fields[$Name].value
}

<#
  .SYNOPSIS    
    Tests whether a field exists on a single work item object
  .PARAMETER WorkItem 
   One or more WorkItem objects .
  .PARAMETER Name
   Name or reference name of a field on the work item
  .EXAMPLE   
    Test-Field $workitem -Name 'Severity'
#>
function Test-Field {
	Param(
		$WorkItem,
		[string]$Name
	)

	return $WorkItem.Fields.Contains($Name)		
}

#HELPER FUNCTIONS
function SplitArray  
{ 
 
<#   
  .SYNOPSIS    
    Split an array  
  .PARAMETER inArray 
   A one dimensional array you want to split 
  .EXAMPLE   
   Split-array -inArray @(1,2,3,4,5,6,7,8,9,10) -parts 3 
  .EXAMPLE   
   Split-array -inArray @(1,2,3,4,5,6,7,8,9,10) -size 3 
#>  
 
  param($inArray,[int]$parts,[int]$size) 
   
  if ($parts) { 
    $PartSize = [Math]::Ceiling($inArray.count / $parts) 
  }  
  if ($size) { 
    $PartSize = $size 
    $parts = [Math]::Ceiling($inArray.count / $size) 
  } 
 
  $outArray = @() 
  for ($i=1; $i -le $parts; $i++) { 
    $start = (($i-1)*$PartSize) 
    $end = (($i)*$PartSize) - 1 
    if ($end -ge $inArray.count) {$end = $inArray.count} 
    $outArray+=,@($inArray[$start..$end]) 
  } 
  return ,$outArray 
 
}

function PrintBatchSaveError {
	Param (
		$errors
	)

	$errors| % {
		$id = $_.WorkItem.Id
		$exception = $_.Exception
		Write-Error "Error while saving Work Item $id`:`n $exception"
	}
}

function VerifyWorkItemStoreSet {
	if($Script:TFSWorkItemStore -eq $null)
	{
		Write-Error "No Work Item Store was set, run Set-WorkItemStore first." -ErrorAction Stop
	}
}

#Export only functions that have a hypen (-)
Export-Modulemember *-*

