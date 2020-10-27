Function Find-EmptyString {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [AllowNull()]
        [Alias("Variable")]
        $VariableName,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Message
    )
    process {
        if ([string]::IsNullOrWhiteSpace("$VariableName")) {
            $Addition = " Stopping."
            $FinalMessage = $Message + $Addition
            Write-Warning -Message "$FinalMessage"
            Break
        }
    }
}
Function Confirm-AzSession {
    process {
        Write-Verbose "Confirming that you are connected to Azure Context."
        $ConfirmContext = (Get-AzContext -ErrorAction SilentlyContinue)
        $Message = "You are not connected to any Azure subscription."
        Find-EmptyString -VariableName $ConfirmContext -Message $Message
    }
}
Function Get-AzTrafficManagerEndpointHealth {
    [CmdletBinding(DefaultParameterSetName="Set1")]
    [OutputType([PSCustomObject])]
    param (
        # Name of the target resource group where traffic manager is located.
        [Parameter(Mandatory=$true,
        Position=1,
        ParameterSetName="Set1")]
        [Parameter(ParameterSetName="Set2",
        ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$ResourceGroup,
        # Name of the traffic manager.
        [Parameter(Mandatory=$true,
        ParameterSetName="Set1",
        ValueFromPipelineByPropertyName=$true)]
        [Parameter(ParameterSetName="Set2")]
        [ValidateNotNullOrEmpty()]
        [string]$TrafficManager,
        # Name of the endpoint configured in traffic manager.
        [Parameter(Mandatory=$true,
        ParameterSetName="Set2",
        ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [Alias("Endpoint")]
        [string]$EndpointName
    )
    begin {
        Write-Verbose "Checking resource group existence."
        Confirm-AzResourceGroup -ResourceGroup $ResourceGroup
        $TmSplat = @{
            Name = $TrafficManager
            ResourceType = "Microsoft.Network/trafficmanagerprofiles"
            ResourceGroupName = $ResourceGroup
        }
        Write-Verbose "Checking traffic manager existence."
        $CheckTrafficManager = (Get-AzResource @TmSplat -ErrorAction SilentlyContinue)
        Find-EmptyString -VariableName $CheckTrafficManager -Message "Cannot find an traffic manager with the name $TrafficManager."
        if ($PSCmdlet.ParameterSetName -eq "Set2") {
            Write-Verbose "Checking traffic manager endpoint existence."
            $FindEndpoints = (Get-AzTrafficManagerProfile -ResourceGroupName $ResourceGroup -Name $TrafficManager -ErrorAction SilentlyContinue).Endpoints
            Find-EmptyString -VariableName $FindEndpoints -Message "There are not endpoints configured on $TrafficManager."
            $AllEndpointNames = [System.Collections.ArrayList]::new()
            foreach ($Endpoint in $FindEndpoints) {
                [void]$AllEndpointNames.Add($($Endpoint.Name))
            }
            if ($AllEndpointNames -notcontains $EndpointName) {
                Write-Warning "Cannot find an endpoint with the name $EndpointName. Stopping."
                Break
            }
        }
    }
    process {
        if ($PSCmdlet.ParameterSetName -eq "Set1") {
            Write-Verbose "Checking health of all endpoints at - $TrafficManager."
            $FindEndpoints = (Get-AzTrafficManagerProfile -ResourceGroupName $ResourceGroup -Name $TrafficManager -ErrorAction SilentlyContinue).Endpoints
            Find-EmptyString -VariableName $FindEndpoints -Message "There are not endpoints configured on $TrafficManager."
            $AllEndpointNames = [System.Collections.ArrayList]::new()
            $AllEndpointHealth = [System.Collections.ArrayList]::new()
            $HealthStatus = [System.Collections.ArrayList]::new()
            foreach ($Endpoint in $FindEndpoints) {
                [void]$AllEndpointNames.Add($($Endpoint.Name))
            }
            foreach ($Endpoint in $AllEndpointNames) {
                $GetEndpointHealth = (Get-AzTrafficManagerEndpoint -ResourceGroupName $ResourceGroup -Type AzureEndpoints -Name $Endpoint -ProfileName $TrafficManager)
                [void]$AllEndpointHealth.Add($GetEndpointHealth)
            }
            foreach ($Endpoint in $AllEndpointHealth) {
                $TempObject = [PSCustomObject]@{
                    Endpoint = $($Endpoint.Name)
                    Health = $($Endpoint.EndpointMonitorStatus)
                    Location = $($Endpoint.Location)
                    TrafficManager = $($Endpoint.ProfileName)
                }
                [void]$HealthStatus.Add($TempObject)
            }
            $HealthStatus
        }
        if ($PSCmdlet.ParameterSetName -eq "Set2") {
            Write-Verbose "Checking health of $EndpointName."
            $FindEndpoint = (Get-AzTrafficManagerEndpoint -Name $EndpointName -ResourceGroupName $ResourceGroup -Type AzureEndpoints -ProfileName $TrafficManager)
            Find-EmptyString -VariableName $FindEndpoint -Message "Cannot find and endpoint with the name $EndpointName."
            [PSCustomObject]@{
                Endpoint = $($FindEndpoint.Name);
                Health = $($FindEndpoint.EndpointMonitorStatus);
                Location = $($FindEndpoint.Location);
                TrafficManager = $($FindEndpoint.ProfileName);
            }
        }
    }
}