function Write-Output ([object] $Object, [object] $Param, [string] $Json) {
    if ($Object -and $Param.Log -eq $true) {
        $Rtr = Join-Path $env:SystemRoot 'system32\drivers\CrowdStrike\Rtr'
        if ((Test-Path $Rtr) -eq $false) { New-Item $Rtr -ItemType Directory }
        $Object | ForEach-Object { $_ | ConvertTo-Json -Compress >> "$Rtr\$Json" }
    }
    $Object | ForEach-Object { $_ | ConvertTo-Json -Compress }
}
$Param = if ($args[0]) { $args[0] | ConvertFrom-Json }
$Output = Get-NetRoute -EA 0 | Select-Object DestinationPrefix, InterfaceIndex, InterfaceAlias, AddressFamily,
    NextHop, Publish, State, RouteMetric, InterfaceMetric, Protocol, PolicyStore
Write-Output $Output $Param "get_network_route_$((Get-Date).ToFileTimeUtc()).json"