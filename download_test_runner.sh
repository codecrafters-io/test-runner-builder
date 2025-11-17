set -e
set -x

destinationDir="/var/opt/test-runner" # Destination directory

repoOwner="codecrafters-io"                  # GitHub repository owner
repoName="test-runner"                       # GitHub repository name
releaseTag="v0.3.71"                         # Release tag to download
assetName="${releaseTag}_linux_amd64.tar.gz" # Asset name
downloadedTarPath="$(mktemp)"                # Path to downloaded tar file

# Get the asset ID
assetId=$(curl -fsSL --header "Authorization: Bearer ${GITHUB_TOKEN}" "https://api.github.com/repos/$repoOwner/$repoName/releases/tags/$releaseTag" | jq -r --arg assetName "$assetName" '.assets[] | select(.name==$assetName) | .id')
echo "Asset ID: $assetId"

downloadUrl="https://api.github.com/repos/$repoOwner/$repoName/releases/assets/$assetId"
echo "Download URL: $downloadUrl"

wget --header="Authorization: Bearer ${GITHUB_TOKEN}" --header="Accept: application/octet-stream" -O $downloadedTarPath $downloadUrl
mkdir -p $destinationDir
tar xz -C $destinationDir -f $downloadedTarPath

rm -rf $downloadedTarPath
