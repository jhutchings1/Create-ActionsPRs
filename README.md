# Create-ActionsPRs
This repository creates pull requests to push a GitHub Actions workflow to a collection of workflows. 

### Prerequisites
* Install [PowerShell](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell?view=powershell-7)
* Install and configure [git](https://git-scm.com/), and configure your account for access to GitHub. [Configuring SSH Keys](https://help.github.com/en/github/authenticating-to-github/connecting-to-github-with-ssh)
* Install [GitHub CLI](https://cli.github.com/)

### Instructions

#### Option 1: Use GitHub API to automatically target everything
1. Clone this repository to your local machine
2. Open powershell and navigate to the directory you cloned this into 
3. Rename the file called `.env-example` to `.env` and add a [GitHub token](https://github.com/settings/tokens) with the `repo` scope. If your organization requires SSO, authorize the token for SSO. 
4. Confirm that the `workflows` directory has all of the workflow files you want in it
5. Run `./Create-ActionsPRs.ps1` to install the script. 
6. Run `CreatePullRequestForRepositories -Repositories (GetReposFromOrganization -Organization orgname) -CommitMessage "message" -PRBody "prbody" -BranchName "branch_name"` 

This will create PRs in every repository that you have push permisisons in. 

#### Option 2: Specify a list to target 
1. Clone this repository to your local machine
2. Open powershell and navigate to the directory you cloned this into 
3. Confirm that you have all the workflow files you want in the `workflows` directory
4. Run `./Create-ActionsPRs.ps1` to install the script. 
5. Create a file with a list of repository URLs, with one repository per line. Save it somewhere you can access. 
6. Confirm that the `workflows` directory has all of the workflow files you want in it
7. Run `CreatePullRequestsFromFile -FileName file.txt -CommitMessage "message" -PRBody "prbody" -BranchName "branch_name"`. Replace file.txt with the path to your file, and update the CommitMessage and PRBody as appropriate. 

#### Option 3: Choose all CodeQL eligible repositories
1. Clone this repository to your local machine
2. Open powershell and navigate to the directory you cloned this into 
3. Rename the file called `.env-example` to `.env` and add a [GitHub token](https://github.com/settings/tokens) with the `repo` scope. If your organization requires SSO, authorize the token for SSO. 
4. Confirm that the `workflows` directory has all of the workflow files you want in it; the CodeQL workflow file is already included in this repo
5. Run `CreatePullRequestsForCodeQLLanguages -Organization orgname` with the organization you want to target instead of orgname. You may optionally override the commit message or PR body by adding `-CommitMessage` or `-PRBody` as appropriate.
