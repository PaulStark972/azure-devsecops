[CmdletBinding()]
param (
    [string]
    $Location = 'westeurope',

    [string]
    $DeploymentDefinitionPath = "$(Get-Location)\deployments\DeploymentDefinition.json",

    [string]
    $TemplatesRootPath = "$(Get-Location)\arm-templates",

    [switch]
    $WhatIfDeployment
)
Write-Output -InputObject "---------------------"

Write-Output -InputObject "Started in '$( (Get-Location).Path )'`n"

Write-Output -InputObject "---------------------"

$scriptParameters = @{
    Location = $Location
    DeploymentDefinitionsPath = $DeploymentDefinitionPath
    TemplatesRootPath = $TemplatesRootPath
    "WhatIfDeployment.IsPresent" = $WhatIfDeployment.IsPresent
}

Write-Output -InputObject "Script parameters: `n $($scriptParameters | ConvertTo-Json -Depth 100)`n"

Write-Output -InputObject "---------------------"

$context = Get-AzContext

if (-not $context) {
    Write-Error -Exception "Login to Azure first!`n"
}

if (-not (Test-Path -Path $DeploymentDefinitionPath) ) {
    Write-Error -Exception "Provide deployment definitions path`n"
}

if (-not (Test-Path -Path $TemplatesRootPath) ) {
    Write-Error -Exception "Provide templates path`n"
}

$deploymentDefinitions = Get-Content -Path $DeploymentDefinitionPath -Raw | ConvertFrom-Json -AsHashtable

$deploymentObjects =  $deploymentDefinitions | % { New-Object -TypeName PSObject -Property $_ } | Sort-Object -Property Order

foreach ($item in $deploymentObjects) {
    Write-Output -InputObject "Deploying: `n $($item | ConvertTo-Json -Depth 100)`n"

    if ($item.TenantId -and (-not $item.ManagementGroupId) -and ( -not $item.SubscriptionId ) ) {
        $deploymentParameters = @{
            Name         = ('deployment' + '-' + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm'))
            TemplateFile = (Join-Path -Path (Get-Location) -ChildPath $item.TemplateFile )
            Verbose      = $true
            Location     = $location
        }
    
        $parametersFilePath = (Join-Path -Path (Get-Location) -ChildPath ($item.TemplateParameterFile) )
        
        if (Test-Path -Path $parametersFilePath) {
            $deploymentParameters['TemplateParameterFile'] = $parametersFilePath
        }
    
        Set-AzContext -TenantId $item.TenantId | Out-Null
        
        Write-Output -InputObject "Parameters: `n $($deploymentParameters | ConvertTo-Json -Depth 100)`n"

        if ($WhatIfDeployment.IsPresent) {
            Write-Output -InputObject "WhatIf only deployment is not supported at Tenant scope`n"
        } else {
            New-AzTenantDeployment @deploymentParameters -Confirm:$false -ErrorAction Stop
        }

    }
    elseif ($item.ManagementGroupId  ) {
        $deploymentParameters = @{
            ManagementGroupId = $item.ManagementGroupId
            Name              = ('deployment' + '-' + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm'))
            TemplateFile      = (Join-Path -Path (Get-Location) -ChildPath $item.TemplateFile )
            Verbose           = $true
            Location          = $Location
        }
    
        $parametersFilePath = (Join-Path -Path (Get-Location) -ChildPath ($item.TemplateParameterFile) )
        
        if (Test-Path -Path $parametersFilePath) {
            $deploymentParameters['TemplateParameterFile'] = $parametersFilePath
        }
    
        Set-AzContext -TenantId $item.TenantId | Out-Null
        
        if ($WhatIfDeployment.IsPresent) {
            Write-Output -InputObject 'WhatIf only deployment is not supported at Management Group scope'
        } else {
            New-AzManagementGroupDeployment @deploymentParameters -Confirm:$false -ErrorAction Stop
        }
    }
    elseif ($item.SubscriptionId -and (-not $item.RgName) ) {
        $deploymentParameters = @{
            Name         = ('deployment' + '-' + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm'))
            TemplateFile = (Join-Path -Path (Get-Location) -ChildPath ($item.TemplateFile) )
            Verbose      = $true
            Location     = $Location
        }
    
        $parametersFilePath = (Join-Path -Path (Get-Location) -ChildPath ($item.TemplateParameterFile) )
        
        if (Test-Path -Path $parametersFilePath) {
            $deploymentParameters['TemplateParameterFile'] = $parametersFilePath
        }
        
        Set-AzContext -TenantId $item.TenantId -SubscriptionId $item.SubscriptionId -ErrorAction Stop | Out-Null
        
        if ($WhatIfDeployment.IsPresent) {
            Get-AzSubscriptionDeploymentWhatIfResult @deploymentParameters -ErrorAction Stop
        } else {
            New-AzSubscriptionDeployment  @deploymentParameters -Confirm:$false  -ErrorAction Stop
        }

    }
    elseif ($item.RgName) {
        $deploymentParameters = @{
            Name              = ('deployment' + '-' + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm'))
            ResourceGroupName = $item.RgName
            TemplateFile      = (Join-Path -Path (Get-Location) -ChildPath ($item.TemplateFile) )
            Mode              = $item.Mode
        }
            
        $parametersFilePath = (Join-Path -Path (Get-Location) -ChildPath ($item.TemplateParameterFile) )
            
        if (Test-Path -Path $parametersFilePath) {
            $deploymentParameters['TemplateParameterFile'] = $parametersFilePath
        }
            
        Set-AzContext -TenantId $item.TenantId -SubscriptionId $item.SubscriptionId -ErrorAction Stop | Out-Null
        
        if ($WhatIfDeployment.IsPresent) {
            Get-AzResourceGroupDeploymentWhatIfResult  @deploymentParameters -ErrorAction Stop
        } else {
            New-AzResourceGroupDeployment  @deploymentParameters -ErrorAction Stop
        }
    }
}
