#!/bin/sh
# makeIPA.sh

# TODO: Usage

# Color
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
WHITE='\033[1;37m'
LIGHT_BLUE='\033[1;36m'
NC='\033[0m'

# Line Break
LINE_BREAK_LEFT="\n\033[32;1m"
LINE_BREAK_RIGHT="\033[0m\n"

# Default 
default() {
    CODE_SIGN_DISTRIBUTION="iPhone Distribution: XXXX"
    SCHEMA_NAME="PPPP"
    CONFIGURATION="Release"
    PROJECT_TYPE="project"
}

# Customize
customize() {
    # 証明書
    CODE_SIGN_DISTRIBUTION="iPhone Distribution: XXXX"
    echo "${LINE_BREAK_LEFT}CODE_SIGN_DISTRIBUTION: ${CODE_SIGN_DISTRIBUTION}"

    # 証明書の確認
    echo "${LINE_BREAK_LEFT}${LIGHT_BLUE}上記の証明書を使いますか？ ${NC}"
    echo "${WHITE}1. Yes ${NC}"
    echo "${WHITE}2. No ${NC}"

    read parameter

    if [[ "${parameter}" == "1" ]]; then
    CODE_SIGN_DISTRIBUTION="iPhone Distribution: XXXX"
    elif [[ "${parameter}" == "2" ]]; then
    echo "${LINE_BREAK_LEFT}${LIGHT_BLUE}証明書を入力してください(ExportOptionsを再作成してください。)： ${NC}"
    read parameter
    CODE_SIGN_DISTRIBUTION="${parameter}"
    else
    echo "${LINE_BREAK_LEFT}[Error] 無効なパラメーターですが...${LINE_BREAK_RIGHT}"
    exit 1
    fi

    # TODO: xcodebuild -list => ?
    # Scheme
    echo "${LINE_BREAK_LEFT}${LIGHT_BLUE}Scheme を選んでください： ${NC}"
    echo "${WHITE}1. YYYY ${NC}"

    read parameter

    if [[ "${parameter}" == "1" ]]; then
    SCHEMA_NAME="YYYY"
    else
    echo "${LINE_BREAK_LEFT}[Error] 無効なパラメーターですが...${LINE_BREAK_RIGHT}"
    exit 1
    fi

    # Configuration
    echo "${LINE_BREAK_LEFT}${LIGHT_BLUE}Configuration を選んでください： ${NC}"
    echo "${WHITE}1. Debug ${NC}"
    echo "${WHITE}2. Alpha ${NC}"
    echo "${WHITE}3. Beta ${NC}"
    echo "${WHITE}4. Release ${NC}"

    read parameter

    if [[ "${parameter}" == "1" ]]; then
    CONFIGURATION="Debug"
    elif [[ "${parameter}" == "2" ]]; then
    CONFIGURATION="Alpha"
    elif [[ "${parameter}" == "3" ]]; then
    CONFIGURATION="Beta"
    elif [[ "${parameter}" == "4" ]]; then
    CONFIGURATION="Release"
    else
    echo "${LINE_BREAK_LEFT}[Error] 無効なパラメーターですが...${LINE_BREAK_RIGHT}"
    exit 1
    fi

    # Project or Workspace
    echo "${LINE_BREAK_LEFT}${LIGHT_BLUE}プロジェクトタイプを選んでください： ${NC}"
    echo "${WHITE}1. Project(.xcodeproj) ${NC}"
    echo "${WHITE}2. Workspace(.xcworkspace) ${NC}"

    read parameter

    if [[ "${parameter}" == "1" ]]; then
    PROJECT_TYPE="project"
    PROJECT_TYPE_EXT="xcodeproj"
    elif [[ "${parameter}" == "2" ]]; then
    PROJECT_TYPE="workspace"
    PROJECT_TYPE_EXT="xcworkspace"
    else
    echo "${LINE_BREAK_LEFT}[Error] 無効なパラメーターですが...${LINE_BREAK_RIGHT}"
    exit 1
    fi
}

## 初期化1
# ========================================================
# プロジェクト名
PROJECT_NAME=`find . -name *.xcodeproj | awk -F "[/.]" '{print $(NF-1)}'`

# Plistファイルのパス
ExportOptions_Path=$(pwd)/ExportOptions.plist
# ========================================================

# ExportOptions.plistの確認
if [ ! -e "$ExportOptions_Path" ]; then
    echo "${RED}[Error] ExportOptions.plist is not exist!${NC}"
    exit 1
fi

# Default or Customize
echo "${LINE_BREAK_LEFT}${LIGHT_BLUE}ディフォルト設定でビルドとアーカイブを行いますか？ ${NC}"
echo "${WHITE}1. Yes ${NC}"
echo "${WHITE}2. No ${NC}"

read parameter
if [[ "${parameter}" == "1" ]]; then
echo "Default"
default
else
echo "Customize"
customize
fi

## 初期化2
# ========================================================
# info.plistパス
INFOPLIST_PATH="./${PROJECT_NAME}/Info.plist"

# CFBundleShortVersionString
BUNDLE_SHORT_VERSION=$(/usr/libexec/PlistBuddy -c "print CFBundleShortVersionString" "${INFOPLIST_PATH}")

# CFBundleVersion
BUNDLE_VERSION=$(/usr/libexec/PlistBuddy -c "print CFBundleVersion" "${INFOPLIST_PATH}")

DATE="$(date +%Y%m%d)"
# 格納用フォルダー名
IPA_FOLDER_NAME="${CONFIGURATION}_v${BUNDLE_SHORT_VERSION}_${DATE}"

# IPAファイルのパス
EXPORT_FILE_PATH="archive/${IPA_FOLDER_NAME}"
# ========================================================

echo "${YELLOW}[Process] Start${NC}"

echo "${YELLOW}[Process] Cleaning${NC}"
xcodebuild \
clean \
-$PROJECT_TYPE $PROJECT_NAME.$PROJECT_TYPE_EXT \
-scheme $SCHEME_NAME \
-configuration $CONFIGURATION
echo "${GREEN}[Success] Finished cleaning${NC}"

echo "${YELLOW}[Process] Building and Archiving${NC}"
xcodebuild \
archive \
-$PROJECT_TYPE $PROJECT_NAME.$PROJECT_TYPE_EXT \
-scheme $SCHEMA_NAME \
-configuration $CONFIGURATION \
-archivePath $EXPORT_FILE_PATH/$PROJECT_NAME.xcarchive \
clean archive \
-quiet || exit

if [ -e $EXPORT_FILE_PATH/$PROJECT_NAME.xcarchive ]; then
    echo "${GREEN}[Success] Finished building and archiving${NC}"
else
    echo "${RED}[Error] Failure to build and archive${NC}"
    exit 1
fi

echo "${YELLOW}[Process] Archiving${NC}"
xcodebuild \
-exportArchive \
-archivePath $EXPORT_FILE_PATH/$PROJECT_NAME.xcarchive \
-exportPath $EXPORT_FILE_PATH \
-exportOptionsPlist $ExportOptions_Path \
-allowProvisioningUpdates \
-quiet || exit

if [ -e $EXPORT_FILE_PATH/$PROJECT_NAME.ipa ]; then
    echo "${GREEN}[Success] Finished Archiving${NC}"
    open $EXPORT_FILE_PATH
else
    echo "${RED}[Error] Failure to export archive${NC}"
fi

