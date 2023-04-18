$orgName = "Volue"

$repos = gh repo list $orgName --json name,url | ConvertFrom-Json

foreach ($repo in $repos) {
    $staticAnalysisEnabled = $false
    
    $alerts = gh api repos/$orgName/$($repo.name)/code-scanning/alerts
    
    if ($alerts -ne $null) {
        foreach ($alert in $alerts) {
            # Check if any of the code scanning alerts are for static analysis
            if ($alert.analysis_key -eq "cppcheck" -or $alert.analysis_key -eq "codeql") {
                $staticAnalysisEnabled = $true
                break
            }
        }
    }

    if (!$staticAnalysisEnabled) {
        Write-Output $repo.url
    }
}
