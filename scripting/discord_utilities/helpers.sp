void AccountsCheck()
{
	Action action = Plugin_Continue;
	Call_StartForward(g_hOnCheckedAccounts);
	Call_PushString(g_sBotToken);
	Call_PushString(g_sGuildID);
	Call_PushString(g_sTableName);
	Call_Finish(action);

	if(action >= Plugin_Handled)
	{
		return;
	}

	char Query[256];
	g_hDB.Format(Query, sizeof(Query), "SELECT userid FROM %s", g_sTableName);
	SQL_TQuery(g_hDB, SQLQuery_AccountCheck, Query);

	Handle hData = json_object();
	json_object_set_new(hData, "limit", json_integer(1000));
	json_object_set_new(hData, "afterID", json_string(""));
	GetMember(hData);
}

void GetMember(Handle hData = INVALID_HANDLE)
{
	if(StrEqual(g_sGuildID, ""))
	{
		LogError("[Discord-Utilities] GuildID is not provided. GetMember won't work!");
		return;
	}
	int limit = JsonObjectGetInt(hData, "limit");
	char afterID[32];
	JsonObjectGetString(hData, "afterID", afterID, sizeof(afterID));

	char url[256];
	if(StrEqual(afterID, ""))
	{
		FormatEx(url, sizeof(url), "https://discord.com/api/guilds/%s/members?limit=%i", g_sGuildID, limit);
	}
	else
	{
		FormatEx(url, sizeof(url), "https://discord.com/api/guilds/%s/members?limit=%i&afterID=%s", g_sGuildID, limit, afterID);
	}

	char route[128];
	FormatEx(route, sizeof(route), "guild/%s/members", g_sGuildID);

	DiscordRequest request = new DiscordRequest(url, k_EHTTPMethodGET);
	if(request == null)
	{
		CreateTimer(2.0, SendGetMembers, hData);
		return;
	}
	request.SetCallbacks(HTTPCompleted, MembersDataReceive);
	request.SetBot(Bot);
	request.SetData(hData, route);
	request.Send(route);
}

public int HTTPCompleted(Handle request, bool failure, bool requestSuccessful, EHTTPStatusCode statuscode, any data, any data2)
{
}

public void MembersDataReceive(Handle request, bool failure, int offset, int statuscode, any dp)
{
	delete request;
}

void GetGuildMember(char[] userid)
{
	Handle hData = json_object();
	json_object_set_new(hData, "userID", json_string(userid[0]));
	GetMember(hData);
}

void SendChatRelay(int client, const char[] sArgs, char[] url, bool bAdmin = true, bool bAllChat = false)
{
	if(strcmp(url, g_sChatRelay_Webhook) == 0)
	{
		for(int i = 0; i < sizeof(g_sChatRelay_BlockList); i++)
		{
			if(strcmp(sArgs, g_sChatRelay_BlockList[i], false) == 0)
			{
				return;
			}
		}
	}
	else if(strcmp(url, g_sAdminChatRelay_Webhook) == 0)
	{
		for(int i = 0; i < sizeof(g_sAdminChatRelay_BlockList); i++)
		{
			if(strcmp(sArgs, g_sAdminChatRelay_BlockList[i], false) == 0)
			{
				return;
			}
		}
	}
	char name[MAX_NAME_LENGTH+1], timestamp[32], sMessage[256];
	GetClientName(client, name, sizeof(name));
	TrimString(name);
	Discord_EscapeString(name, sizeof(name), true);
	
	char auth[32];
	if(!GetClientAuthId(client, AuthId_Steam2, auth, sizeof(auth)))
	{
		return;
	}
	Format(name, sizeof(name), "%s [%s]", name, auth);
	
	FormatEx(sMessage, sizeof(sMessage), sArgs);
	Discord_EscapeString(sMessage, sizeof(sMessage));

	RemoveColors(sMessage, sizeof(sMessage));
	
	if(g_cTimeStamps.BoolValue)
	{
		FormatTime(timestamp, sizeof(timestamp), "[%I:%M:%S %p] ", GetTime());
	}
	
	DiscordWebHook hook = new DiscordWebHook( url );
	hook.SlackMode = true;
	hook.SetUsername( name );
	if(g_sAvatarURL[client][0])
	{
		hook.SetAvatar(g_sAvatarURL[client]);
	}
	char sPrivateToAdmins[32], sAllChat[32];
	Format(sPrivateToAdmins, sizeof(sPrivateToAdmins), "%T", "ChatRelayPrivateToAdmins", LANG_SERVER);
	Format(sAllChat, sizeof(sAllChat), "%T", "ChatRelayAllChat", LANG_SERVER);
	if(strcmp(url, g_sAdminChatRelay_Webhook) == 0)
	{
		Format(sMessage, sizeof(sMessage), "%s`%s` => %s%s", timestamp, g_sServerName, bAdmin ? "" : sPrivateToAdmins, sMessage);
	}
	else
	{
		Format(sMessage, sizeof(sMessage), "%s%s%s", timestamp, bAllChat ? sAllChat : "", sMessage);
	}
	hook.SetContent(sMessage);
	hook.Send();
	
	delete hook;
}

void SendAdminLog(int client, const char[] sArgs)
{
	char name[MAX_NAME_LENGTH+1], timestamp[32], sMessage[256], map[PLATFORM_MAX_PATH], mapdisplay[64];
	GetClientName(client, name, sizeof(name));
	TrimString(name);
	Discord_EscapeString(name, sizeof(name), true);
	
	char auth[32];
	if(!GetClientAuthId(client, AuthId_Steam2, auth, sizeof(auth)))
	{
		return;
	}
	Format(name, sizeof(name), "%s [%s]", name, auth);
	
	GetCurrentMap(map, sizeof(map));
	GetMapDisplayName(map, mapdisplay, sizeof(mapdisplay));

	FormatEx(sMessage, sizeof(sMessage), sArgs);
	Discord_EscapeString(sMessage, sizeof(sMessage));

	
	RemoveColors(name, sizeof(name));
	RemoveColors(sMessage, sizeof(sMessage));
	
	if(g_cTimeStamps.BoolValue)
	{
		FormatTime(timestamp, sizeof(timestamp), "[%I:%M:%S %p] ", GetTime());
	}
	
	DiscordWebHook hook = new DiscordWebHook( g_sAdminLog_Webhook );
	hook.SlackMode = true;
	hook.SetUsername( name );
	if(g_sAvatarURL[client][0])
	{
		hook.SetAvatar(g_sAvatarURL[client]);
	}
	Format(sMessage, sizeof(sMessage), "%T", "AdminLogFormat", LANG_SERVER, timestamp, g_sServerName, mapdisplay, sMessage);
	hook.SetContent(sMessage);
	
	hook.Send();
	
	delete hook;
}

void UpdatePlayer(int client)
{
	char steamid[32], szQuery[512];
	
	GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
	if(g_bIsMySQl)
	{
		g_hDB.Format(szQuery, sizeof(szQuery), "UPDATE `%s` SET last_accountuse = '%d' WHERE `steamid` = '%s';", g_sTableName, GetTime(), steamid);
	}
	else
	{
		g_hDB.Format(szQuery, sizeof(szQuery), "UPDATE %s SET last_accountuse = '%d' WHERE steamid = '%s'", g_sTableName, GetTime(), steamid);
	}
	SQL_TQuery(g_hDB, SQLQuery_UpdatePlayer, szQuery, GetClientUserId(client));
}

void GetLastMap(char[] sMap, int iSize)
{
	if (!FileExists(g_sLastMapPath))
	{
		File fFile = OpenFile(g_sLastMapPath, "w+");
		fFile.Close();
		return;
	}
	File CfgFile = OpenFile(g_sLastMapPath, "r");
	char lines[64];
	while(!IsEndOfFile(CfgFile) && (ReadFileLine(CfgFile, lines, 64)))
	{
		if ((lines[0] == '/' && lines[1] == '/') || (lines[0] == ';' || lines[0] == '\0'))
		{
			continue;
		}
		ReplaceString(lines, 64, "\n", "", false);
		if(strlen(lines) > 1)
		{
			strcopy(sMap, iSize, lines);
		}
	}
	delete CfgFile;
}

void UpdateLastMap()
{
	if(!FileExists(g_sLastMapPath))
	{
		SetFailState("Configuration text file %s not found!", g_sLastMapPath);
	}
	File CfgFile = OpenFile(g_sLastMapPath, "w+");
	if (CfgFile != null)
	{
		FlushFile(CfgFile);
		char map[PLATFORM_MAX_PATH], displayname[64];
		GetCurrentMap(map, sizeof(map));
		GetMapDisplayName(map, displayname, sizeof(displayname));
		WriteFileLine(CfgFile, displayname);
	}
	delete CfgFile;
}

stock int GetRealConnectedPlayers()
{
	int count;
	for(int i = 1; i <= MaxClients; i++)
	{	
		if(IsClientConnected(i) && !IsFakeClient(i) && !IsClientSourceTV(i))
		{
			count++;
		}
	}
	return count;
}

stock void RemoveColors(char[] text, int size)
{
	if(g_bShavit)
	{
		for(int i = 0; i < sizeof(gS_GlobalColorNames); i++)
		{
			ReplaceString(text, size, gS_GlobalColorNames[i], "");
		}
		for(int i = 0; i < sizeof(gS_GlobalColors); i++)
		{
			ReplaceString(text, size, gS_GlobalColors[i], "");
		}
		for(int i = 0; i < sizeof(gS_CSGOColorNames); i++)
		{
			ReplaceString(text, size, gS_CSGOColorNames[i], "");
		}
		for(int i = 0; i < sizeof(gS_CSGOColors); i++)
		{
			ReplaceString(text, size, gS_CSGOColors[i], "");
		}
	}
	else
	{
		for(int i = 0; i < sizeof(C_Tag); i++)
		{
			ReplaceString(text, size, C_Tag[i], "");
		}
		for(int i = 0; i < sizeof(C_TagCode); i++)
		{
			ReplaceString(text, size, C_TagCode[i], "");
		}
	}
}

void CreateCvars()
{
	AutoExecConfig_SetFile("Discord-Utilities");
	AutoExecConfig_SetCreateFile(true);

	g_cCallAdmin_Webhook = AutoExecConfig_CreateConVar("sm_du_calladmin_webhook", "", "Webhook for calladmin reports and report handled print. Blank to disable.", FCVAR_PROTECTED);
	g_cCallAdmin_BotName = AutoExecConfig_CreateConVar("sm_du_calladmin_botname", "Discord Utilities", "BotName for calladmin. Blank to use webhook name.");
	g_cCallAdmin_BotAvatar = AutoExecConfig_CreateConVar("sm_du_calladmin_avatar", "", "Avatar link for calladmin bot. Blank to use webhook avatar.");
	g_cCallAdmin_Color = AutoExecConfig_CreateConVar("sm_du_calladmin_color", "#ff9911", "Color for embed message of calladmin.");
	g_cCallAdmin_Content = AutoExecConfig_CreateConVar("sm_du_calladmin_content", "When in-game type !calladmin_handle <ReportID> in chat to handle this report.", "Content for embed message of calladmin. Blank to disable.");
	g_cCallAdmin_FooterIcon = AutoExecConfig_CreateConVar("sm_du_calladmin_footericon", "", "Link to footer icon for calladmin. Blank for no footer icon.");

	g_cBugReport_Webhook = AutoExecConfig_CreateConVar("sm_du_bugreport_webhook", "", "Webhook for bugreport reports. Blank to disable.", FCVAR_PROTECTED);
	g_cBugReport_BotName = AutoExecConfig_CreateConVar("sm_du_bugreport_botname", "Discord Utilities", "BotName for bugreport. Blank to use webhook name.");
	g_cBugReport_BotAvatar = AutoExecConfig_CreateConVar("sm_du_bugreport_avatar", "", "Avatar link for bugreport bot. Blank to use webhook avatar.");
	g_cBugReport_Color = AutoExecConfig_CreateConVar("sm_du_bugreport_color", "#ff9911", "Color for embed message of bugreport.");
	g_cBugReport_Content = AutoExecConfig_CreateConVar("sm_du_bugreport_content", "", "Content for embed message of bugreport. Blank to disable.");
	g_cBugReport_FooterIcon = AutoExecConfig_CreateConVar("sm_du_bugreport_footericon", "", "Link to footer icon for bugreport. Blank for no footer icon.");

	g_cSourceBans_Webhook = AutoExecConfig_CreateConVar("sm_du_sourcebans_webhook", "", "Webhook for sourcebans. Blank to disable.", FCVAR_PROTECTED);
	g_cSourceBans_BotName = AutoExecConfig_CreateConVar("sm_du_sourcebans_botname", "Discord Utilities", "BotName for sourcebans. Blank to use webhook name.");
	g_cSourceBans_BotAvatar = AutoExecConfig_CreateConVar("sm_du_sourcebans_avatar", "", "Avatar link for sourcebans bot. Blank to use webhook avatar.");
	g_cSourceBans_Color = AutoExecConfig_CreateConVar("sm_du_sourcebans_color", "#0E40E6", "Color for embed message of sourcebans.");
	g_cSourceBans_PermaColor = AutoExecConfig_CreateConVar("sm_du_sourcebans_perma_color", "#f00000", "Color for embed message of sourcebans when permanent banned.");
	g_cSourceBans_Content = AutoExecConfig_CreateConVar("sm_du_sourcebans_content", "", "Content for embed message of sourcebans. Blank to disable.");
	g_cSourceBans_FooterIcon = AutoExecConfig_CreateConVar("sm_du_sourcebans_footericon", "", "Link to footer icon for sourcebans. Blank for no footer icon.");

	g_cSourceComms_Webhook = AutoExecConfig_CreateConVar("sm_du_sourcecomms_webhook", "", "Webhook for sourcecomms. Blank to disable.", FCVAR_PROTECTED);
	g_cSourceComms_BotName = AutoExecConfig_CreateConVar("sm_du_sourcecomms_botname", "Discord Utilities", "BotName for sourcecomms. Blank to use webhook name.");
	g_cSourceComms_BotAvatar = AutoExecConfig_CreateConVar("sm_du_sourcecomms_avatar", "", "Avatar link for sourcecomms bot. Blank to use webhook avatar.");
	g_cSourceComms_Color = AutoExecConfig_CreateConVar("sm_du_sourcecomms_color", "#FF69B4", "Color for embed message of sourcecomms.");
	g_cSourceComms_PermaColor = AutoExecConfig_CreateConVar("sm_du_sourcecomms_perma_color", "#f00000", "Color for embed message of sourcecomms when permanent banned.");
	g_cSourceComms_Content = AutoExecConfig_CreateConVar("sm_du_sourcecomms_content", "", "Content for embed message of sourcecomms. Blank to disable.");
	g_cSourceComms_FooterIcon = AutoExecConfig_CreateConVar("sm_du_sourcecomms_footericon", "", "Link to footer icon for sourcecomms. Blank for no footer icon.");

	g_cMap_Webhook = AutoExecConfig_CreateConVar("sm_du_map_webhook", "", "Webhook for map notification. Blank to disable.", FCVAR_PROTECTED);
	g_cMap_BotName = AutoExecConfig_CreateConVar("sm_du_map_botname", "Discord Utilities", "BotName for map notification. Blank to use webhook name.");
	g_cMap_BotAvatar = AutoExecConfig_CreateConVar("sm_du_map_avatar", "", "Avatar link for map notification bot. Blank to use webhook avatar.");
	g_cMap_Color = AutoExecConfig_CreateConVar("sm_du_map_color", "#6a0dad", "Color for embed message of map notification.");
	g_cMap_Content = AutoExecConfig_CreateConVar("sm_du_map_content", "", "Content for embed message of map notification. Blank to disable.");
	g_cMap_Delay = AutoExecConfig_CreateConVar("sm_du_map_delay", "25", "Seconds to wait after mapstart to send the map notification webhook. 0 for no delay.");

	g_cChatRelay_Webhook = AutoExecConfig_CreateConVar("sm_du_chat_webhook", "", "Webhook for game server => discord server chat messages. Blank to disable.", FCVAR_PROTECTED);
	g_cChatRelay_BlockList = AutoExecConfig_CreateConVar("sm_du_chat_blocklist", "rtv, nominate", "Text that shouldn't appear in gameserver => discord server chat messages. Separate it with \", \"");
	g_cAdminChatRelay_Webhook = AutoExecConfig_CreateConVar("sm_du_adminchat_webhook", "", "Webhook for game server => discord server chat messages where chat messages are to admins (say_team with @ / sm_chat). Blank to disable.", FCVAR_PROTECTED);
	g_cAdminChatRelay_BlockList = AutoExecConfig_CreateConVar("sm_du_adminchat_blocklist", "rtv, nominate", "Text that shouldn't appear in gameserver => discord server where chat messages are to admin. Separate it with \", \"");
	g_cAdminLog_Webhook = AutoExecConfig_CreateConVar("sm_du_adminlog_webhook", "", "Webhook for channel where all admin commands are logged. Blank to disable.", FCVAR_PROTECTED);
	g_cAdminLog_BlockList = AutoExecConfig_CreateConVar("sm_du_adminlog_blocklist", "slapped, firebombed", "Log with this string will be ignored. Separate it with \", \"");

	g_cVerificationChannelID = AutoExecConfig_CreateConVar("sm_du_verfication_channelid", "", "Channel ID for verfication. Blank to disable.");
	g_cChatRelayChannelID = AutoExecConfig_CreateConVar("sm_du_chat_channelid", "", "Channel ID for discord server => game server messages. Blank to disable.");
	g_cGuildID = AutoExecConfig_CreateConVar("sm_du_verification_guildid", "", "Guild ID of your discord server. Blank to disable. Needed for verification module.");
	g_cRoleID = AutoExecConfig_CreateConVar("sm_du_verification_roleid", "", "Role ID to give to user when user is verified. Blank to give no role. Verification module needs to be running.");

	g_cAPIKey = AutoExecConfig_CreateConVar("sm_du_apikey", "", "Steam API Key (https://steamcommunity.com/dev/apikey). Needed for gameserver => discord server relay and/or admin chat relay and/or Admin logs. Blank will show default author icon of discord.", FCVAR_PROTECTED);
	g_cBotToken = AutoExecConfig_CreateConVar("sm_du_bottoken", "", "Bot Token. Needed for discord server => gameserver and/or verification module.", FCVAR_PROTECTED);
	g_cDNSServerIP = AutoExecConfig_CreateConVar("sm_du_dns_ip", "", "DNS IP address of your game server. Blank to use real IP.");
	g_cCheckInterval = AutoExecConfig_CreateConVar("sm_du_accounts_check_interval", "300", "Time in seconds between verifying accounts.");
	g_cUseSWGM = AutoExecConfig_CreateConVar("sm_du_use_swgm_file", "0", "Use SWGM config file for restricting commands.");
	g_cTimeStamps = AutoExecConfig_CreateConVar("sm_du_display_timestamps", "0", "Display timestamps? Used in gameserver => discord server relay AND AdminLog");
	g_cServerID = AutoExecConfig_CreateConVar("sm_du_server_id", "1", "Increase this with every server you put this plugin in. Prevents multiple replies from the bot in verfication channel.");
	g_cPrimaryServer = AutoExecConfig_CreateConVar("sm_du_server_primary", "1", "Is this the primary server in the verification channel? Only this server will respond to generic queries.", .min=0.0, .max=1.0, .hasMin=true, .hasMax=true);

	g_cLinkCommand = AutoExecConfig_CreateConVar("sm_du_link_command", "!link", "Command to use in text channel.");
	g_cViewIDCommand = AutoExecConfig_CreateConVar("sm_du_viewid_command", "sm_viewid", "Command to view id.");
	g_cInviteLink = AutoExecConfig_CreateConVar("sm_du_link", "https://discord.gg/83g5xcE", "Invite link of your discord server.");

	g_cDiscordPrefix = AutoExecConfig_CreateConVar("sm_du_discord_prefix", "[{lightgreen}Discord{default}]", "Prefix for discord messages.");
	g_cServerPrefix = AutoExecConfig_CreateConVar("sm_du_server_prefix", "[{lightgreen}Discord-Utilities{default}]", "Prefix for chat messages.");

	g_cDatabaseName = AutoExecConfig_CreateConVar("sm_du_database_name", "du", "Section name in databases.cfg.");
	g_cTableName = AutoExecConfig_CreateConVar("sm_du_table_name", "du_users", "Table Name.");
	g_cPruneDays = AutoExecConfig_CreateConVar("sm_du_prune_days", "60", "Prune database with players whose last connect is X DAYS and he is not member of discord server. 0 to disable.");

	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
	
	HookConVarChange(g_cCallAdmin_Webhook, OnSettingsChanged);
	HookConVarChange(g_cCallAdmin_BotName, OnSettingsChanged);
	HookConVarChange(g_cCallAdmin_BotAvatar, OnSettingsChanged);
	HookConVarChange(g_cCallAdmin_Color, OnSettingsChanged);
	HookConVarChange(g_cCallAdmin_Content, OnSettingsChanged);
	HookConVarChange(g_cCallAdmin_FooterIcon, OnSettingsChanged);

	HookConVarChange(g_cBugReport_Webhook, OnSettingsChanged);
	HookConVarChange(g_cBugReport_BotName, OnSettingsChanged);
	HookConVarChange(g_cBugReport_BotAvatar, OnSettingsChanged);
	HookConVarChange(g_cBugReport_Color, OnSettingsChanged);
	HookConVarChange(g_cBugReport_Content, OnSettingsChanged);
	HookConVarChange(g_cBugReport_FooterIcon, OnSettingsChanged);

	HookConVarChange(g_cSourceBans_Webhook, OnSettingsChanged);
	HookConVarChange(g_cSourceBans_BotName, OnSettingsChanged);
	HookConVarChange(g_cSourceBans_BotAvatar, OnSettingsChanged);
	HookConVarChange(g_cSourceBans_Color, OnSettingsChanged);
	HookConVarChange(g_cSourceBans_PermaColor, OnSettingsChanged);
	HookConVarChange(g_cSourceBans_Content, OnSettingsChanged);
	HookConVarChange(g_cSourceBans_FooterIcon, OnSettingsChanged);

	HookConVarChange(g_cSourceComms_Webhook, OnSettingsChanged);
	HookConVarChange(g_cSourceComms_BotName, OnSettingsChanged);
	HookConVarChange(g_cSourceComms_BotAvatar, OnSettingsChanged);
	HookConVarChange(g_cSourceComms_Color, OnSettingsChanged);
	HookConVarChange(g_cSourceComms_PermaColor, OnSettingsChanged);
	HookConVarChange(g_cSourceComms_Content, OnSettingsChanged);
	HookConVarChange(g_cSourceComms_FooterIcon, OnSettingsChanged);

	HookConVarChange(g_cMap_Webhook, OnSettingsChanged);
	HookConVarChange(g_cMap_BotName, OnSettingsChanged);
	HookConVarChange(g_cMap_BotAvatar, OnSettingsChanged);
	HookConVarChange(g_cMap_Color, OnSettingsChanged);
	HookConVarChange(g_cMap_Content, OnSettingsChanged);

	HookConVarChange(g_cChatRelay_Webhook, OnSettingsChanged);
	HookConVarChange(g_cChatRelay_BlockList, OnSettingsChanged);
	HookConVarChange(g_cAdminChatRelay_Webhook, OnSettingsChanged);
	HookConVarChange(g_cAdminChatRelay_BlockList, OnSettingsChanged);
	HookConVarChange(g_cAdminLog_Webhook, OnSettingsChanged);
	HookConVarChange(g_cAdminLog_BlockList, OnSettingsChanged);

	HookConVarChange(g_cVerificationChannelID, OnSettingsChanged);
	HookConVarChange(g_cChatRelayChannelID, OnSettingsChanged);
	HookConVarChange(g_cGuildID, OnSettingsChanged);
	HookConVarChange(g_cRoleID, OnSettingsChanged);

	HookConVarChange(g_cAPIKey, OnSettingsChanged);
	HookConVarChange(g_cBotToken, OnSettingsChanged);
	HookConVarChange(g_cDNSServerIP, OnSettingsChanged);

	HookConVarChange(g_cLinkCommand, OnSettingsChanged);
	HookConVarChange(g_cViewIDCommand, OnSettingsChanged);
	HookConVarChange(g_cInviteLink, OnSettingsChanged);

	HookConVarChange(g_cDiscordPrefix, OnSettingsChanged);
	HookConVarChange(g_cServerPrefix, OnSettingsChanged);

	HookConVarChange(g_cTableName, OnSettingsChanged);
}

void LoadCvars()
{
	g_cCallAdmin_Webhook.GetString(g_sCallAdmin_Webhook, sizeof(g_sCallAdmin_Webhook));
	g_cCallAdmin_BotName.GetString(g_sCallAdmin_BotName, sizeof(g_sCallAdmin_BotName));
	g_cCallAdmin_BotAvatar.GetString(g_sCallAdmin_BotAvatar, sizeof(g_sCallAdmin_BotAvatar));
	g_cCallAdmin_Color.GetString(g_sCallAdmin_Color, sizeof(g_sCallAdmin_Color));
	g_cCallAdmin_Content.GetString(g_sCallAdmin_Content, sizeof(g_sCallAdmin_Content));
	g_cCallAdmin_FooterIcon.GetString(g_sCallAdmin_FooterIcon, sizeof(g_sCallAdmin_FooterIcon));
	
	g_cBugReport_Webhook.GetString(g_sBugReport_Webhook, sizeof(g_sBugReport_Webhook));
	g_cBugReport_BotName.GetString(g_sBugReport_BotName, sizeof(g_sBugReport_BotName));
	g_cBugReport_BotAvatar.GetString(g_sBugReport_BotAvatar, sizeof(g_sBugReport_BotAvatar));
	g_cBugReport_Color.GetString(g_sBugReport_Color, sizeof(g_sBugReport_Color));
	g_cBugReport_Content.GetString(g_sBugReport_Content, sizeof(g_sBugReport_Content));
	g_cBugReport_FooterIcon.GetString(g_sBugReport_FooterIcon, sizeof(g_sBugReport_FooterIcon));
	
	g_cSourceBans_Webhook.GetString(g_sSourceBans_Webhook, sizeof(g_sSourceBans_Webhook));
	g_cSourceBans_BotName.GetString(g_sSourceBans_BotName, sizeof(g_sSourceBans_BotName));
	g_cSourceBans_BotAvatar.GetString(g_sSourceBans_BotAvatar, sizeof(g_sSourceBans_BotAvatar));
	g_cSourceBans_Color.GetString(g_sSourceBans_Color, sizeof(g_sSourceBans_Color));
	g_cSourceBans_PermaColor.GetString(g_sSourceBans_PermaColor, sizeof(g_sSourceBans_PermaColor));
	g_cSourceBans_Content.GetString(g_sSourceBans_Content, sizeof(g_sSourceBans_Content));
	g_cSourceBans_FooterIcon.GetString(g_sSourceBans_FooterIcon, sizeof(g_sSourceBans_FooterIcon));
	
	g_cSourceComms_Webhook.GetString(g_sSourceComms_Webhook, sizeof(g_sSourceComms_Webhook));
	g_cSourceComms_BotName.GetString(g_sSourceComms_BotName, sizeof(g_sSourceComms_BotName));
	g_cSourceComms_BotAvatar.GetString(g_sSourceComms_BotAvatar, sizeof(g_sSourceComms_BotAvatar));
	g_cSourceComms_Color.GetString(g_sSourceComms_Color, sizeof(g_sSourceComms_Color));
	g_cSourceComms_PermaColor.GetString(g_sSourceComms_PermaColor, sizeof(g_sSourceComms_PermaColor));
	g_cSourceComms_Content.GetString(g_sSourceComms_Content, sizeof(g_sSourceComms_Content));
	g_cSourceComms_FooterIcon.GetString(g_sSourceComms_FooterIcon, sizeof(g_sSourceComms_FooterIcon));
	
	g_cMap_Webhook.GetString(g_sMap_Webhook, sizeof(g_sMap_Webhook));
	g_cMap_BotName.GetString(g_sMap_BotName, sizeof(g_sMap_BotName));
	g_cMap_BotAvatar.GetString(g_sMap_BotAvatar, sizeof(g_sMap_BotAvatar));
	g_cMap_Color.GetString(g_sMap_Color, sizeof(g_sMap_Color));
	g_cMap_Content.GetString(g_sMap_Content, sizeof(g_sMap_Content));
	
	char sBlockList[PLATFORM_MAX_PATH];
	g_cChatRelay_Webhook.GetString(g_sChatRelay_Webhook, sizeof(g_sChatRelay_Webhook));
	g_cChatRelay_BlockList.GetString(sBlockList, sizeof(sBlockList));
	ExplodeString(sBlockList, ", ", g_sChatRelay_BlockList, MAX_BLOCKLIST_LIMIT, 64);
	g_cAdminChatRelay_Webhook.GetString(g_sAdminChatRelay_Webhook, sizeof(g_sAdminChatRelay_Webhook));
	g_cAdminChatRelay_BlockList.GetString(sBlockList, sizeof(sBlockList));
	ExplodeString(sBlockList, ", ", g_sAdminChatRelay_BlockList, MAX_BLOCKLIST_LIMIT, 64);
	g_cAdminLog_Webhook.GetString(g_sAdminLog_Webhook, sizeof(g_sAdminLog_Webhook));
	g_cAdminLog_BlockList.GetString(sBlockList, sizeof(sBlockList));
	ExplodeString(sBlockList, ", ", g_sAdminLog_BlockList, MAX_BLOCKLIST_LIMIT, 64);
	
	g_cVerificationChannelID.GetString(g_sVerificationChannelID, sizeof(g_sVerificationChannelID));
	g_cChatRelayChannelID.GetString(g_sChatRelayChannelID, sizeof(g_sChatRelayChannelID));
	g_cGuildID.GetString(g_sGuildID, sizeof(g_sGuildID));
	g_cRoleID.GetString(g_sRoleID, sizeof(g_sRoleID));
	
	g_cAPIKey.GetString(g_sAPIKey, sizeof(g_sAPIKey));
	g_cBotToken.GetString(g_sBotToken, sizeof(g_sBotToken));
	g_cDNSServerIP.GetString(g_sServerIP, sizeof(g_sServerIP));
	ServerIP(g_sServerIP, sizeof(g_sServerIP));
	
	g_cLinkCommand.GetString(g_sLinkCommand, sizeof(g_sLinkCommand));
	g_cViewIDCommand.GetString(g_sViewIDCommand, sizeof(g_sViewIDCommand));
	g_cInviteLink.GetString(g_sInviteLink, sizeof(g_sInviteLink));
	
	g_cDiscordPrefix.GetString(g_sDiscordPrefix, sizeof(g_sDiscordPrefix));
	g_cServerPrefix.GetString(g_sServerPrefix, sizeof(g_sServerPrefix));
}

stock void MakeStringSafe(const char[] sOrigin, char[] sOut, int iOutSize)
{
	int iDataLen = strlen(sOrigin);
	int iCurIndex;

	for (int i = 0; i < iDataLen && iCurIndex < iOutSize; i++)
	{
		if (sOrigin[i] < 0x20 && sOrigin[i] != 0x0) continue;

		switch (sOrigin[i])
		{
			case '@':
			{
				strcopy(sOut[iCurIndex], iOutSize, "@​");
				iCurIndex += 4;

				continue;
			}
			case '`':
			{
				strcopy(sOut[iCurIndex], iOutSize, "\\`");
				iCurIndex += 2;

				continue;
			}
			case '_':
			{
				strcopy(sOut[iCurIndex], iOutSize, "\\_");
				iCurIndex += 2;

				continue;
			}
			case '~':
			{
				strcopy(sOut[iCurIndex], iOutSize, "\\~");
				iCurIndex += 2;

				continue;
			}
			default:
			{
				sOut[iCurIndex] = sOrigin[i];
				iCurIndex++;
			}
		}
	}
}

public int OnTransferCompleted(Handle hRequest, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode, int client)
{
	if (bFailure || !bRequestSuccessful || eStatusCode != k_EHTTPStatusCode200OK)
	{
		LogError("SteamAPI HTTP Response failed: %d", eStatusCode);
		delete hRequest;
		return;
	}

	int iBodyLength;
	SteamWorks_GetHTTPResponseBodySize(hRequest, iBodyLength);

	char[] sData = new char[iBodyLength];
	SteamWorks_GetHTTPResponseBodyData(hRequest, sData, iBodyLength);

	delete hRequest;
	
	APIWebResponse(sData, client);
}

public void APIWebResponse(const char[] sData, int client)
{
	KeyValues kvResponse = new KeyValues("SteamAPIResponse");

	if (!kvResponse.ImportFromString(sData, "SteamAPIResponse"))
	{
		LogError("kvResponse.ImportFromString(\"SteamAPIResponse\") in APIWebResponse failed.");

		delete kvResponse;
		return;
	}

	if (!kvResponse.JumpToKey("players"))
	{
		LogError("kvResponse.JumpToKey(\"players\") in APIWebResponse failed.");

		delete kvResponse;
		return;
	}

	if (!kvResponse.GotoFirstSubKey())
	{
		LogError("kvResponse.GotoFirstSubKey() in APIWebResponse failed.");

		delete kvResponse;
		return;
	}

	kvResponse.GetString("avatarfull", g_sAvatarURL[client], sizeof(g_sAvatarURL[]));
	delete kvResponse;
}

void ManagingRole(char[] userid, char[] roleid, EHTTPMethod method)
{
	Handle hData = json_object();
	json_object_set_new(hData, "userid", json_string(userid));
	json_object_set_new(hData, "roleid", json_string(roleid));
	json_object_set_new(hData, "method", json_integer(view_as<int>(method)));
	ManageRole(hData);
}

void ManageRole(Handle hData)
{
	if(StrEqual(g_sGuildID, ""))
	{
		LogError("[Discord-Utilities] GuildID is not provided. Role cannot be provided!");
		return;
	}
	char userid[128];
	if (!JsonObjectGetString(hData, "userid", userid, sizeof(userid)))
	{
		LogError("JsonObjectGetString \"userid\" failed");
		return;
	}
	char roleid[128];
	if (!JsonObjectGetString(hData, "roleid", roleid, sizeof(roleid)))
	{
		LogError("JsonObjectGetString \"roleid\" failed");
		return;
	}
	EHTTPMethod method = view_as<EHTTPMethod>(JsonObjectGetInt(hData, "method"));
	char url[1024];
	FormatEx(url, sizeof(url), "https://discord.com/api/guilds/%s/members/%s/roles/%s", g_sGuildID, userid, roleid);
	char route[512];
	FormatEx(route, sizeof(route), "guild/%s/members", g_sGuildID);
	DiscordRequest request = new DiscordRequest(url, method);
	if (request == null)
	{
		CreateTimer(2.0, SendManageRole, hData, TIMER_FLAG_NO_MAPCHANGE);
		return;
	}
	request.SetCallbacks(HTTPCompleted, MembersDataReceive);
	request.SetContentSize();
	request.SetBot(Bot);
	request.SetData(hData, route);
	request.Send(route);
	//delete hData;
	//delete request;
}

void LoadCommands()
{
	char sBuffer[256];
	if(g_cUseSWGM.IntValue == 1)
	{
		KeyValues kv = new KeyValues("Command_Listener");
		BuildPath(Path_SM, sBuffer, sizeof(sBuffer), "configs/swgm/command_listener.ini");
		if(!FileToKeyValues(kv, sBuffer))
		{
			SetFailState("[Discord-Utilities] Missing config file %s. If you don't use SWGM, then change 'sm_du_use_swgm_file' value to 0.", sBuffer);
		}
		if(kv.GotoFirstSubKey())
		{
			do
			{
				if(kv.GetSectionName(sBuffer, sizeof(sBuffer)))
				{
					AddCommandListener(Check, sBuffer);
				}
			}
			while (kv.GotoNextKey());
		}
		delete kv;
		return;
	}
	BuildPath(Path_SM, sBuffer, sizeof(sBuffer), "configs/du/command_listener.ini");
	
	File fFile = OpenFile(sBuffer, "r");
	
	if(!FileExists(sBuffer))
	{
		fFile.Close();
		fFile = OpenFile(sBuffer, "w+");
		fFile.WriteLine("// Separate each commands with separate lines. DON'T USE SPACE INFRONT OF COMMANDS. Example:");
		fFile.WriteLine("//sm_shop");
		fFile.WriteLine("//sm_store");
		fFile.WriteLine("//Use it without \"//\"");
		fFile.Close();
		LogError("[Discord-Utilities] %s file is empty. Add commands to restrict them!", sBuffer);
		return;
	}
	char sReadBuffer[PLATFORM_MAX_PATH];

	int len;
	while(!fFile.EndOfFile() && fFile.ReadLine(sReadBuffer, sizeof(sReadBuffer)))
	{
		if (sReadBuffer[0] == '/' && sReadBuffer[1] == '/' || IsCharSpace(sReadBuffer[0]))
		{
			continue;
		}

		ReplaceString(sReadBuffer, sizeof(sReadBuffer), "\n", "");
		ReplaceString(sReadBuffer, sizeof(sReadBuffer), "\r", "");
		ReplaceString(sReadBuffer, sizeof(sReadBuffer), "\t", "");

		len = strlen(sReadBuffer);

		if (len < 3)
		{
			continue;
		}

		AddCommandListener(Check, sReadBuffer);
	}

	fFile.Close();
}

stock void RefreshClients()
{
	for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i))
	{
		OnClientPreAdminCheck(i);
	}
}

stock void CreateBot(bool guilds = true, bool listen = true)
{
	if(StrEqual(g_sBotToken, "") || StrEqual(g_sChatRelayChannelID, "") && StrEqual(g_sVerificationChannelID, ""))
	{
		return;
	}
	Bot = new DiscordBot(g_sBotToken);
	if(guilds)
	{
		Bot.GetGuilds(GuildList, _, listen);
	}
}

stock void KillBot()
{
	if(Bot)
	{
		Bot.StopListeningToChannels();
		Bot.StopListening();
	}
	delete Bot;
}

stock int GetClientFromUniqueCode(const char[] unique)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i)) continue;
		if (StrEqual(g_sUniqueCode[i], unique)) return i;
	}
	return -1;
}

stock char ChangePartsInString(char[] input, const char[] from, const char[] to)
{
	char output[64];
	ReplaceString(input, sizeof(output), from, to);
	strcopy(output, sizeof(output), input);
	return output;
}

void ServerIP(char[] sIP, int size)
{
	if(sIP[0])
	{
		return;
	}
	int ip[4];
	int iServerPort = FindConVar("hostport").IntValue;
	SteamWorks_GetPublicIP(ip);
	if(SteamWorks_GetPublicIP(ip))
	{
		Format(sIP, size, "%d.%d.%d.%d:%d", ip[0], ip[1], ip[2], ip[3], iServerPort);
	}
	else
	{
		int iServerIP = FindConVar("hostip").IntValue;
		Format(sIP, size, "%d.%d.%d.%d:%d", iServerIP >> 24 & 0x000000FF, iServerIP >> 16 & 0x000000FF, iServerIP >> 8 & 0x000000FF, iServerIP & 0x000000FF, iServerPort);
	}
}

/*
stock void GetGuilds(bool listen = true)
{	
	Bot.GetGuilds(GuildList, _, listen);
}
*/

stock void Discord_EscapeString(char[] string, int maxlen, bool name = false)
{
	if(name)
	{
		ReplaceString(string, maxlen, "everyone", "everyonｅ");
		ReplaceString(string, maxlen, "here", "herｅ");
		ReplaceString(string, maxlen, "discordtag", "dｉscordtag");
	}
	ReplaceString(string, maxlen, "#", "＃");
	ReplaceString(string, maxlen, "@", "＠");
	ReplaceString(string, maxlen, ":", "");
	ReplaceString(string, maxlen, "_", "ˍ");
	ReplaceString(string, maxlen, "'", "＇");
	ReplaceString(string, maxlen, "`", "＇");
	ReplaceString(string, maxlen, "~", "∽");
	ReplaceString(string, maxlen, "\"", "＂");
}

/* TIMERS */

public Action VerifyAccounts(Handle timer)
{
	AccountsCheck();
}

public Action SendGetMembers(Handle timer, any data)
{
	GetMember(view_as<Handle>(data));
}

public Action SendManageRole(Handle timer, Handle hData)
{
	ManageRole(hData);
}

public Action SendRequestAgain(Handle timer, DataPack dp)
{
	ResetPack(dp, false);
	Handle request = ReadPackCell(dp);
	char route[512];
	ReadPackString(dp, route, sizeof(route));
	delete dp;
	DiscordSendRequest(request, route);
}

public Action Timer_RefreshClients(Handle timer)
{
	RefreshClients();
}

stock void DU_DeleteMessageID(DiscordMessage discordmessage)
{
	char channelid[64], msgid[64];
	
	discordmessage.GetChannelID(channelid, sizeof(channelid));
	discordmessage.GetID(msgid, sizeof(msgid));
	
	Bot.DeleteMessageID(channelid, msgid);
}