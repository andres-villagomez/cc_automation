$ring = Read-Host -Prompt 'Type Ring'
$namespace = Read-Host -Prompt 'Type Namespace'
Write-Host "You input server '$Servers' and '$User' on '$Date'" 
function Get-PodStatus($namespace = $null, $excludeSystemPod = $true) 
{
    if ($namespace)
    {
        $pods = cc get pods -n $namespace -o json | ConvertFrom-Json
    }
    else
    {
        $pods = cc get pods -A -o json | ConvertFrom-Json
    }
    $results = @()
    foreach($pod in $pods.items)
    {
        if ($excludeSystemPod -and $pod.metadata.namespace -like 'kube-*' -or $pod.metadata.name -like 'secret-cache-service-*')
        { continue }
        $totalContainerCount = $pod.status.containerstatuses.count
        $readyContainerCount = ($pod.status.containerstatuses | ? { $_.ready -eq 'True' }).count
        if (!$readyContainerCount)
        { $readyContainerCount = 0}
        $containerOverallReadiness = "$($readyContainerCount)/$($totalContainerCount)"
        $podConditions = ""
        foreach($condition in $pod.status.conditions)
        {
            $podConditions += ",$($condition.type):$($condition.status)"
        }
        if ($podConditions)
        {
            $podConditions = $podConditions.Trim(',')
        }
        $podPrefix = ""
        if($pod.metadata.name -match "(.+)(-.+)(-.+)$")
        {
            $podPrefix = $Matches[1]
        }
        $result = New-Object -TypeName PSObject
        $ht = ([ordered]@{
            "namespace"=$pod.metadata.namespace;
            "pod"=$pod.metadata.name;
                                             "status"=$pod.status.phase;
            "node"=$pod.spec.nodename;
                                             "podIP"=$pod.status.podIP;
            "podConditions"=$podConditions
            "apps"=$pod.spec.containers.name;
        })
        # $ht  | Format-Table -AutoSize
        $ht.GetEnumerator() | % {
            $result | Add-Member -MemberType NoteProperty -Name $_.Key -Value $_.Value
        }
        $results += $result
    }
    $results | Format-Table -AutoSize
}
