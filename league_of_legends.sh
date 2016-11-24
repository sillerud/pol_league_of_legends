#!/usr/bin/env playonlinux-bash
[ "$PLAYONLINUX" = "" ] && exit 0
source "$PLAYONLINUX/lib/sources"

PREFIX="LeagueOfLegends_NEW"
TITLE="League of Legends installer"
WINE_STAGING_VERSION="1.9.23-staging"
WINE_STABLE_VERSION="1.9.23"
LEAGUE_OF_LEGENDS_VERSION="2016_11_10"

POL_SetupWindow_Init

POL_SetupWindow_message "Welcome to this wizard for installing League of Legends with the newer installers and unpatched wine $(pwd)"

POL_SetupWindow_menu "Select your region" "Select region" "NA|EUW|EUNE|OC1|RU|LA1" "|"
REGION="$APP_ANSWER"

LOL_DOWNLOAD_URL="https://riotgamespatcher-a.akamaihd.net/ShellInstaller/$REGION/LeagueofLegends_${REGION}_Installer_$LEAGUE_OF_LEGENDS_VERSION.exe"

POL_SetupWindow_message "Going to download $LOL_DOWNLOAD_URL"

POL_SetupWindow_menu "Select what version of wine you want.\nThe stable version is tested and more stable.\nStaging can be faster and contains\npatches that makes games run faster" "Select wine version" "Stable|Staging" "|"
if [ "$APP_ANSWER" = "Stable" ]
then
	WINE_VERSION="$WINE_STABLE_VERSION"
elif [ "$APP_ANSWER" = "Staging" ]
then
	WINE_VERSION="$WINE_STAGING_VERSION"
fi
POL_Wine_SelectPrefix "$PREFIX"
POL_Wine_PrefixCreate "$WINE_VERSION"

POL_System_TmpCreate "lol_msi"
cd "$POL_System_TmpDir"
EXE="$(basename $LOL_DOWNLOAD_URL)"
INSTALLER="$POL_System_TmpDir/$EXE"
POL_Download "$LOL_DOWNLOAD_URL" "5ef1f0c65fb99296a03023f80a74d104" "$POL_System_TmpDir"

POL_Wine "$INSTALLER" "/extract:$(winepath -w $POL_System_TmpDir/lol_msi)" "/execnoui"
INSTALL_PATH="$(winepath -w '$PREFIX/drive_c/Riot Games')"
POL_SetupWindow_message "$INSTALL_PATH"
POL_Wine "msiexec" "/i" "$(winepath -w $POL_System_TmpDir/LoL.$REGION.msi)" "APPDIR=C:\\Riot Games" "/q"
#POL_Wine "msiexec" "/i" "$(winepath -w $POL_System_TmpDir/LoL.$REGION.msi)" "APPDIR=\"$INSTALL_PATH\"" "/q"

POL_Call POL_Install_vcrun2005
POL_Call POL_Install_d3dx9

Set_OS "winxp"

POL_Shortcut "lol.launcher.admin.exe" "League of Legends"

POL_SetupWindow_Close