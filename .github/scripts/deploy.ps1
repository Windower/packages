$repo = ($env:GITHUB_REPOSITORY -Split '/')[1] ?? $env:GITHUB_REPOSITORY
&ssh "${env:SSH_USER}@${env:SSH_HOST}" (@(
    "rm -rf ~/staging/${repo}",
    "mkdir -p ~/staging/${repo}"
) -Join '&&')
&scp -r './.staging/*' "${env:SSH_USER}@${env:SSH_HOST}:~/staging/${repo}"
&ssh "${env:SSH_USER}@${env:SSH_HOST}" (@(
    "rm -rf ~/backup/"
    "mkdir ~/backup/"
    "mv ${env:FILES_PATH}/* ~/backup/",
    "mv ~/staging/${repo}/* ${env:FILES_PATH}/",
    "rm -r ~/backup/"
    "rm -r ~/staging/${repo}"
) -Join '&&')
