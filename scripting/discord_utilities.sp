#include <sourcemod>
#include <autoexecconfig>
#include <SteamWorks>
#include <discord>
#include <discord_utilities>

#undef REQUIRE_PLUGIN
#include <calladmin>
#include <sourcebanspp>
#include <sourcecomms>
#define USES_CHAT_COLORS
#include <shavit>
#include <multicolors>
#include <bugreport>
#define REQUIRE_PLUGIN

#include "discord_utilities/globals.sp"
#include "discord_utilities/natives.sp"
#include "discord_utilities/discordrequest.sp"
#include "discord_utilities/helpers.sp"
#include "discord_utilities/forwards.sp"
#include "discord_utilities/sql.sp"
#include "discord_utilities/modules.sp"

#pragma dynamic 25000
#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo = 
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESC,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_bLateLoad = late;
	
	RegPluginLibrary("DiscordUtilities");
	
	CreateNative("DU_IsChecked", Native_IsChecked);
	CreateNative("DU_IsMember", Native_IsDiscordMember);
	CreateNative("DU_GetUserId", Native_GetUserId);
	CreateNative("DU_RefreshClients", Native_RefreshClients);
	CreateNative("DU_GetIP", Native_GetIP);
	CreateNative("DU_AddRole", Native_AddRole);
	CreateNative("DU_DeleteRole", Native_DeleteRole);

	g_hOnLinkedAccount = CreateGlobalForward("DU_OnLinkedAccount", ET_Ignore, Param_Cell, Param_String, Param_String, Param_String);
	g_hOnAccountRevoked = CreateGlobalForward("DU_OnAccountRevoked", ET_Ignore, Param_Cell, Param_String);
	g_hOnCheckedAccounts = CreateGlobalForward("DU_OnCheckedAccounts", ET_Event, Param_String, Param_String, Param_String);
	return APLRes_Success;
}

public void OnPluginStart()
{
	hRateLeft = new StringMap();
	hRateReset = new StringMap();
	hRateLimit = new StringMap();

	char sBuffer[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sBuffer, sizeof(sBuffer), "configs/du/");
	if(!DirExists(sBuffer))
	{
		CreateDirectory(sBuffer, 511);
	}
	BuildPath(Path_SM, g_sLastMapPath, sizeof(g_sLastMapPath), "configs/du/discord_lastmap.txt");

	AddCommandListener(Command_AdminChat, "sm_chat");

	CreateCvars();

	LoadTranslations("Discord-Utilities.phrases");
	
	if(g_bLateLoad)
	{
		OnAllPluginsLoaded();
		OnPluginEnd();
		OnConfigsExecuted();
		CreateTimer(3.0, Timer_RefreshClients, _, TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(4.0, VerifyAccounts, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}
