
function CreatePullRequestsFromFile {
  param (
      [string] $FileName,
      [string] $CommitMessage,
      [string] $PRBody,
      [string] $BranchName
  )
  $repos = Get-Content $FileName
  $languages = '"C"', '"C++"', '"Go"', '"C#"', '"Python"', '"Java"', '"JavaScript"', '"TypeScript"'
  $filteredRepos = @()
  foreach ($repo in $repos)
  {
    $chunks = $repo.split("/")
    $repo_nwo = $chunks[3] + "/" + $chunks[4]
    $url = "https://api.github.com/repos/" + $repo_nwo + "/languages"
    $headers = getHeaders
    $langs = Invoke-WebRequest -Uri $url -Method Get -Headers $headers
    $value = $langs.Content

    if ($value -ne "{}") {
      if (ContainsAny -string $value -values $languages) {
        $filteredRepos += $repo
      }
    }
  }

  # Clone repos
  foreach ($repo in $filteredRepos)
  {
    Set-Location $PSScriptRoot
    $chunks = $repo.split("/")
    $repo_nwo = $chunks[3] + "/" + $chunks[4]
    gh repo clone $repo_nwo $repo_nwo
    Set-Location $repo_nwo
    git checkout -b $BranchName
    if ((Get-ChildItem .github -ErrorAction SilentlyContinue).Count -eq 0) {
      mkdir .github
    }
    if ((Get-ChildItem .github/workflows -ErrorAction SilentlyContinue).Count  -eq 0) {
      mkdir .github/workflows
    }
    copy-item "$PSScriptRoot/workflows" -destination ".github/" -Recurse
    git add -A
    git commit -a -m $CommitMessage
    gh pr create -b $PRBody -t $CommitMessage
    Set-Location ../..
    rm -rf $repo_nwo
  }
  Set-Location $PSScriptRoot
}

function CreatePullRequestForRepositories {
  param (
      # An Array of Repository objects as returned by the GitHub API
      [array] $Repositories,
      [string] $CommitMessage,
      [string] $PRBody,
      [string] $BranchName
  )
  foreach ($repo in $repos) 
  {
    Set-Location $PSScriptRoot

    gh repo clone $repo.full_name $repo.full_name

    Set-Location $repo.full_name
    git checkout -b $BranchName

    copy-item "$PSScriptRoot/workflows" -Destination ".github/" -Recurse
    git add -A
    git commit -a -m $CommitMessage
    gh pr create -b $PRBody -t $CommitMessage
  }
}

function getAuthenticationToken {
  $token = Get-ChildItem Env:\GITHUB_TOKEN -ErrorAction SilentlyContinue
  if ($null -eq $token) {
    $envFile = Get-Content .env
    foreach ($line in $envFile) {
      if ($line.startsWith("GITHUB_TOKEN=")) {
        $token = $line.Substring($line.IndexOf("=") + 1)
      }
    }
  }
  
  return $token
}

function getHeaders {
  $token = getAuthenticationToken
  $authheader = "Bearer " + $token
  $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
  $headers.Add("Authorization",$authheader)
  return $headers
}
  
function GetReposFromOrganization {
  param (
      [string] $Organization
  )
  $url = "https://api.github.com/orgs/$Organization/repos"
  $headers = getHeaders

  $repos = Invoke-RestMethod -Uri $url -Method Get -Headers $headers -ResponseHeadersVariable 'response'

  if ($null -ne $response) {
    if ($null -ne $response.Link) {
      # Parse the Link header to paginate
      $response.Link[0] -match '.*?page=([0-9]*)>; rel="last"'
      $pages = [int]($Matches[1])

      # Paginate
      for ($page = 2; $page -lt $pages; $page++) {
        $pageUrl = $url + "?page=" + $page
        $repos += Invoke-RestMethod -Uri $pageUrl -Method Get -Headers $headers
      }
    } 
  }

  return $repos
}

function FilterForSupportedLanguages($repos) {
  $languages = '"C"', '"C++"', '"Go"', '"C#"', '"Python"', '"Java"', '"JavaScript"', '"TypeScript"'
  $filteredRepos = @()

  foreach ($repo in $repos) {
    if ($repo.GetType().Name -eq "PSCustomObject") {
      $url = $repo.url + "/languages"
      $headers = getHeaders

      $langs = Invoke-WebRequest -Uri $url -Method Get -Headers $headers 
      $value = $langs.Content

      if ($value -ne "{}") {
        if (ContainsAny -string $value -values $languages) {
          $filteredRepos += $repo
        }
      }
    }
  }
  return $filteredRepos
}

function ContainsAny {
  param([string]$string, [array]$values)
  foreach ($value in $values) {
    if ($string.Contains($value)) {
      return $true;
    }
  }
  return $false;
}

function CreatePullRequestsForCodeQLLanguages {
  param (
      [string] $Organization,
      [string] $CommitMessage = "Add CodeQL Analysis workflow",
      [string] $PRBody = "Adds an Actions workflow which enables CodeQL analysis and will perform static analysis security testing on your code. You'll see results show up in pull requests and/or the Security tab. "
  )
  $repos = FilterForSupportedLanguages(GetReposFromOrganization -Organization $Organization);

  CreatePullRequestForRepositories -Repositories $repos -CommitMessage $CommitMessage -PRBody $PRBody -BranchName codeql

}

