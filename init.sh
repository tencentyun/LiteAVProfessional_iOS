#!/usr/bin/env bash
# Download TXLiteAVSDK_Professional.framework

cd $(dirname $0)
if [ ! -e "SDK/TXLiteAVSDK_Professional.framework" ]; then
    URL="$(cat SDK/README.md | grep -o 'http.*zip')"
    echo "Downloading SDK from $URL"
    curl "$URL" --output SDK/TXLiteAVSDK_Professional_iOS.zip
    cd SDK
    echo "Unzipping SDK..."
    unzip -q TXLiteAVSDK_Professional_iOS.zip
    rm -rf __MACOSX
    mv TXLiteAVSDK_Professional_*/SDK/*.framework .
    rm -rf TXLiteAVSDK_Professional_*
fi

# Download ImSDK.framework
cd $(dirname $0)
if [ ! -e "SDK/ImSDK.framework" ]; then
URL="https://pod-1252463788.cos.ap-guangzhou.myqcloud.com/mlvbspec/ImSDK/ImSDK.framework.zip"
echo "Downloading IM SDK from $URL"
curl "$URL" --output SDK/ImSDK.zip
cd SDK
unzip -q ImSDK.zip
rm -rf ImSDK.zip
rm -rf __MACOSX
fi
