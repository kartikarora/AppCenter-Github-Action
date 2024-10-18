#!/bin/bash -e

# Required since https://github.blog/2022-04-12-git-security-vulnerability-announced
git config --global --add safe.directory $GITHUB_WORKSPACE

RELEASE_NOTES=""
isFirst=true
releaseId=""
export IFS=";"
params=()
[ "${INPUT_NOTIFYTESTERS}" != true ] && params+=(--silent)
[ "${INPUT_DEBUG}" == true ] && params+=(--debug)
if [ -n "${INPUT_RELEASENOTES}" ]; then
    RELEASE_NOTES=${INPUT_RELEASENOTES}
elif [ $INPUT_GITRELEASENOTES ]; then
    RELEASE_NOTES="$(git log -1 --pretty=short)"
fi

if [ -n "${INPUT_BUILDVERSION}" ]; then
    params+=(--build-version "$INPUT_BUILDVERSION")
fi

if [ -n "${INPUT_BUILDNUMBER}" ]; then
    params+=(--build-number "$INPUT_BUILDNUMBER")
fi

for group in $INPUT_GROUP; do
    if ${isFirst} ; then
        isFirst=false
        appcenter distribute release --token "$INPUT_TOKEN" --app "$INPUT_APPNAME" --group $group --file "$INPUT_FILE" --release-notes "$RELEASE_NOTES" "${params[@]}"
        releaseId=$(appcenter distribute releases list --token "$INPUT_TOKEN" --app "$INPUT_APPNAME" | grep ID | tr -s ' ' | cut -f2 -d ' ' | sort -n -r | head -1)
    else
        appcenter distribute releases add-destination --token "$INPUT_TOKEN" -d $group -t group -r $releaseId --app "$INPUT_APPNAME" "${params[@]}"
    fi
done

releaseInfo=$(appcenter distribute releases show --token "$INPUT_TOKEN" --app "$INPUT_APPNAME" -r $releaseId --output json)
downloadUrl=$(echo $releaseInfo | jq '.downloadUrl')
installUrl=$(echo $releaseInfo | jq '.installUrl')
version_name=$(echo $releaseInfo | jq '.shortCode')
version_code=$(echo $releaseInfo | jq '.version')
echo "download-url=$downloadUrl" >> $GITHUB_OUTPUT
echo "install-url=$installUrl" >> $GITHUB_OUTPUT

if [ -n "${INPUT_MAPPINGFILE}" ]; then
    appcenter crashes upload-mappings --token "$INPUT_TOKEN" --app "$INPUT_APPNAME" --mapping "$INPUT_MAPPINGFILE" --version-name "$version_name" --version-code "$version_code"
fi