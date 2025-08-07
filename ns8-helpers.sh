# Helper functions for NS8 module scripts

validate_repo_argument() {
    local owner_and_repo="$1"

    if [ -z "$owner_and_repo" ]; then
        echo "Usage: $0 <owner/repo>"
        echo
        echo "Example: $0 NethServer/ns8-kickstart"
        return 2
    fi
}

# Check if the GitHub CLI is installed
check_gh_installed() {
    if ! command -v gh &> /dev/null; then
        echo "gh (GitHub CLI) is not installed. Please install it first."
        return 1
    fi
}

# Check if the user is logged in to GitHub
check_gh_logged_in() {
    if ! gh auth status &> /dev/null; then
        echo "You are not logged in to GitHub. Please log in using 'gh auth login'."
        return 1
    fi
}

# Check if the Yarn version is compatible
check_yarn_version() {
    if ! yarn --version | grep -qE '^1\.22\..+$'; then
        echo "Yarn not installed or version not compatible, 1.22.x is required"
        return 1
    fi
}

# Clone the repository or pull changes it if it already exists
clone_or_update_repo() {
    local owner_and_repo="$1"
    local git_workspace="$2"
    local repo="${owner_and_repo##*/}"
    cd "$git_workspace"

    if [ ! -d "$repo" ]; then
        echo "Cloning repository $repo..."
        git clone git@github.com:"$owner_and_repo"
        cd "$repo"
    else
        echo "Repository $repo already exists, skipping clone."
        cd "$repo"
        echo "Pulling latest changes..."
        git checkout main
        git pull origin main
    fi
}

# Create or switch to a branch
create_or_switch_branch() {
    local branch="$1"

    if git show-ref --verify --quiet refs/heads/"$branch"; then
        echo "Switching to existing branch: $branch"
        git checkout "$branch"
    else
        echo "Creating new branch: $branch"
        git checkout -b "$branch"
    fi
}

# Confirm and commit changes, optionally creating a pull request
confirm_and_commit() {
    local owner_and_repo="$1"
    local package="$2"
    local cve="$3"
    local use_branch="$4"
    local branch="$5"
    local reviewer="$6"

    if $use_branch; then
        confirm_message="Do you want to commit and create a pull request on repo $owner_and_repo for $package $cve?"
    else
        confirm_message="Do you want to commit changes ON THE MAIN BRANCH of $owner_and_repo for $package $cve?"
    fi

    read -p "$confirm_message (y/N): " confirm
    if [[ "$confirm" != "y" ]]; then
        echo "Skipping commit."
        return 0
    fi

    git add .
    git commit -m "fix: $package $cve"
    git push --set-upstream origin "$branch"
    
    if $use_branch; then
        gh pr create --title "fix: $package $cve" --body "Fix $cve" --reviewer $reviewer
        echo "Pull request created."
    else
        git push origin main
        echo "Changes pushed to main branch."
    fi
}
