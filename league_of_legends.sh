#!/usr/bin/env playonlinux-bash
[ "$PLAYONLINUX" = "" ] && exit 0
source "$PLAYONLINUX/lib/sources"

PREFIX="LeagueOfLegends_NEW"
TITLE="League of Legends installer"
WINE_STAGING_VERSION="1.9.23-staging"
WINE_STABLE_VERSION="1.9.24"
LEAGUE_OF_LEGENDS_VERSION="2016_11_10"

declare -A HASHES=( ["Russia"]="7803b38f78badc03585fb0ef588d130b" ["EU Nordic & East"]="ca65a9d529310603b2777d703e490dbc" ["North America"]="aad5fb3163e32a77a48f65fda820275c" ["Latin America South"]="8750db743cc19c50eee4454d21f1ce60" ["Latin America North"]="e2126127aa73b497a2d12b2ff17316a5" ["Brazil"]="782c92b0f8f4920385a9d6782d0c7292" ["EU West"]="5ef1f0c65fb99296a03023f80a74d104" ["Oceania"]="761af34a3054db7661edfe3bf55c48ee" )
declare -A URLS=( ["EU West"]="https://riotgamespatcher-a.akamaihd.net/ShellInstaller/EUW/LeagueofLegends_EUW_Installer_2016_11_10.exe" ["North America"]="https://riotgamespatcher-a.akamaihd.net/ShellInstaller/NA/LeagueofLegends_NA_Installer_2016_05_13.exe" ["EU Nordic & East"]="https://riotgamespatcher-a.akamaihd.net/ShellInstaller/EUNE/LeagueofLegends_EUNE_Installer_2016_11_10.exe" ["Oceania"]="https://riotgamespatcher-a.akamaihd.net/ShellInstaller/OC1/LeagueofLegends_OC1_Installer_2016_05_13.exe" ["Russia"]="https://riotgamespatcher-a.akamaihd.net/ShellInstaller/RU/LeagueofLegends_RU_Installer_2016_05_13.exe" ["Latin America North"]="https://riotgamespatcher-a.akamaihd.net/ShellInstaller/LA1/LeagueofLegends_LA1_Installer_2016_05_26.exe" ["Latin America South"]="https://riotgamespatcher-a.akamaihd.net/ShellInstaller/LA2/LeagueofLegends_LA2_Installer_2016_05_27.exe" ["Brazil"]="https://riotgamespatcher-a.akamaihd.net/ShellInstaller/BR/LeagueofLegends_BR_Installer_2016_05_13.exe" )
declare -A REGIONS=( ["EU West"]="EUW" ["North America"]="NA" ["EU Nordic & East"]="EUNE" ["Oceania"]="OC1" ["Russia"]="RU" ["Latin America North"]="LA1" ["Latin America South"]="LA2" ["Brazil"]="BR" )
REGION_DESC="EU West|North America|EU Nordic & East|Oceania|Russia|Latin America North|Latin America South|Brazil"

POL_SetupWindow_Init

POL_SetupWindow_message "Welcome to this wizard for installing League of Legends with the newer installers and unpatched wine"

POL_SetupWindow_menu "Select your region" "Select region" "$REGION_DESC" "|"
REGION="${REGIONS[$APP_ANSWER]}"
LOL_DOWNLOAD_HASH="${HASHES[$APP_ANSWER]}"
LOL_DOWNLOAD_URL="${URLS[$APP_ANSWER]}"

# For some reason the initial patching doesn't work with staging, so temporarily disable the choice
#POL_SetupWindow_menu "Select what version of wine you want.\nThe stable version is tested and more stable.\nStaging can be faster and contains\npatches that makes games run faster" "Select wine version" "Stable|Staging" "|"
#if [ "$APP_ANSWER" = "Stable" ]
#then
#	WINE_VERSION="$WINE_STABLE_VERSION"
#elif [ "$APP_ANSWER" = "Staging" ]
#then
#	WINE_VERSION="$WINE_STAGING_VERSION"
#fi
POL_Wine_SelectPrefix "$PREFIX"
POL_Wine_PrefixCreate "$WINE_STABLE_VERSION" #"$WINE_VERSION"

POL_System_TmpCreate "lol_msi"
cd "$POL_System_TmpDir"
EXE="$(basename $LOL_DOWNLOAD_URL)"
INSTALLER="$POL_System_TmpDir/$EXE"
POL_Download "$LOL_DOWNLOAD_URL" "$LOL_DOWNLOAD_HASH" "$POL_System_TmpDir"

POL_Wine "$INSTALLER" "/extract:$(winepath -w $POL_System_TmpDir/lol_msi)" "/execnoui"
POL_Wine "msiexec" "/i" "$POL_System_TmpDir/LoL.$REGION.msi" "APPDIR=C:\\Riot Games" "/q"

#POL_Call POL_Install_vcrun2005
POL_Call POL_Install_d3dx9

#Set_OS "winxp"
POL_Call POL_Function_OverrideDLL builtin,native wininet

#POL_Wine_reboot

POL_Shortcut "lol.launcher.admin.exe" "League of Legends (new)"

POL_SetupWindow_Close
