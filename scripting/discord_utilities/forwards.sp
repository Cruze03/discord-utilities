public void OnPluginEnd()
{
	KillBot();
}

public void OnLibraryAdded(const char[] szLibrary)
{
	if(StrEqual(szLibrary, "sourcebans++")) g_bSourceBans = true;
	else if(StrEqual(szLibrary, "sourcecomms++")) g_bSourceComms = true;
	else if(StrEqual(szLibrary, "calladmin")) g_bCallAdmin = true;
	else if(StrEqual(szLibrary, "shavit")) g_bShavit = true;
	else if(StrEqual(szLibrary, "bugreport")) g_bBugReport = true;
}

public void OnLibraryRemoved(const char[] szLibrary)
{
	if(StrEqual(szLibrary, "sourcebans++")) g_bSourceBans = false;
	else if(StrEqual(szLibrary, "sourcecomms++")) g_bSourceComms = false;
	else if(StrEqual(szLibrary, "calladmin")) g_bCallAdmin = false;
	else if(StrEqual(szLibrary, "shavit")) g_bShavit = false;
	else if(StrEqual(szLibrary, "bugreport")) g_bBugReport = false;
}

public void OnAllPluginsLoaded()
{
	if(!LibraryExists("discord-api"))
	{
		SetFailState("[Discord-Utilities] This plugin is fully dependant on \"Discord-API\" by Deathknife. (https://github.com/Deathknife/sourcemod-discord)");
	}
	
	g_bSourceBans = LibraryExists("sourcebans++");
	g_bSourceComms = LibraryExists("sourcecomms++");
	g_bCallAdmin = LibraryExists("calladmin");
	g_bShavit = LibraryExists("shavit");
	g_bBugReport = LibraryExists("bugreport");
}

public void OnConfigsExecuted()
{
	LoadCvars();
	if(g_bCallAdmin)
	{
		CallAdmin_GetHostName(g_sServerName, sizeof(g_sServerName));
		g_aCallAdmin_ReportedList = new ArrayList(64);
	}
	else
	{
		FindConVar("hostname").GetString(g_sServerName, sizeof(g_sServerName));
	}
	
	if(Bot == view_as<DiscordBot>(INVALID_HANDLE))
	{
		if(!CommandExists(g_sViewIDCommand))
		{
			RegConsoleCmd(g_sViewIDCommand, Command_ViewId);
		}
		CreateBot();
	}
	
	LoadCommands();
	
	char sDTB[32];
	g_cDatabaseName.GetString(sDTB, sizeof(sDTB));
	g_cTableName.GetString(g_sTableName, sizeof(g_sTableName));
	SQL_TConnect(SQLQuery_Connect, sDTB);
}

public void OnMapEnd()
{
	KillBot();
}

public void OnMapStart()
{
	if(StrEqual(g_sMap_Webhook, ""))
	{
		return;
	}
	char PrevMap[64], map[PLATFORM_MAX_PATH], displayname[64], buffer[256];
	GetLastMap(PrevMap, sizeof(PrevMap));
	GetCurrentMap(map, sizeof(map));
	GetMapDisplayName(map, displayname, sizeof(displayname));
	Format(buffer, sizeof(buffer), "https://image.gametracker.com/images/maps/160x120/csgo/%s.jpg", displayname);
	
	if(strcmp(PrevMap, displayname) != 0)
	{
		DataPack data = new DataPack();
		CreateDataTimer(g_cMap_Delay.FloatValue, Timer_DisplayMapNotification, data, TIMER_FLAG_NO_MAPCHANGE);
		data.WriteString(displayname);
		data.WriteString(buffer);
	}
	CreateTimer(g_cCheckInterval.FloatValue, VerifyAccounts, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action Command_AdminChat(int client, const char[] command, int argc)
{
	if(StrEqual(g_sAdminChatRelay_Webhook, ""))
	{
		return Plugin_Continue;
	}
	if(1 <= client <= MaxClients)
	{
		char sMessage[256];
		GetCmdArgString(sMessage, sizeof(sMessage));
		SendChatRelay(client, sMessage, g_sAdminChatRelay_Webhook);
	}
	return Plugin_Continue;
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	if(StrEqual(g_sChatRelay_Webhook, "") && StrEqual(g_sAdminChatRelay_Webhook, ""))
	{
		return Plugin_Continue;
	}
	if(1 <= client <= MaxClients)
	{
		if(strcmp(command, "say") != 0 && strcmp(command, "say_team") != 0)
		{
			return Plugin_Continue;
		}
		if(IsChatTrigger() || sArgs[0] == '!')
		{
			return Plugin_Continue;
		}
		if(strcmp(command, "say_team") == 0 && sArgs[0] == '@')
		{
			bool bAdmin = CheckCommandAccess(client, "", ADMFLAG_GENERIC);
			SendChatRelay(client, sArgs[1], g_sAdminChatRelay_Webhook, bAdmin);
			return Plugin_Continue;
		}
		if(strcmp(command, "say") == 0 && sArgs[0] == '@')
		{
			SendChatRelay(client, sArgs[1], g_sChatRelay_Webhook, true, true);
			return Plugin_Continue;
		}
		SendChatRelay(client, sArgs, g_sChatRelay_Webhook);
	}
	return Plugin_Continue;
}

public Action OnLogAction(Handle hSource, Identity ident, int client, int target, const char[] sMsg)
{
	if(client <= 0)
	{
		return Plugin_Continue;
	}

	if(StrContains(sMsg, "sm_chat", false) != -1)
	{
		return Plugin_Continue;// dont log sm_chat because it's already being showed in admin chat relay channel.
	}
	
	SendAdminLog(client, sMsg);
	
	return Plugin_Continue;
}

public void OnClientDisconnect(int client)
{
	if(g_hDB == null)
	{
		return;
	}
	UpdatePlayer(client);
}

public void OnClientPutInServer(int client)
{
	g_bChecked[client] = false;
	g_sAvatarURL[client][0] = '\0';
	g_bMember[client] = false;
	g_sUniqueCode[client][0] = '\0';
	g_sUserID[client][0] = '\0';
}

public Action OnClientPreAdminCheck(int client)
{
	if(IsFakeClient(client) || g_hDB == null)
	{
		return;
	}
	
	char szQuery[512], szSteamId[32];
	GetClientAuthId(client, AuthId_Steam2, szSteamId, sizeof(szSteamId));
	if(g_bIsMySQl)
	{
		g_hDB.Format(szQuery, sizeof(szQuery), "SELECT userid, member FROM %s WHERE steamid = '%s';", g_sTableName, szSteamId);
	}
	else
	{
		g_hDB.Format(szQuery, sizeof(szQuery), "SELECT userid, member FROM %s WHERE steamid = '%s'", g_sTableName, szSteamId);
	}
	SQL_TQuery(g_hDB, SQLQuery_GetUserData, szQuery, GetClientUserId(client));

	
	if(StrEqual(g_sAPIKey, ""))
	{
		return;
	}
	
	char szSteamID64[32];
	if(!GetClientAuthId(client, AuthId_SteamID64, szSteamID64, sizeof(szSteamID64)))
	{
		return;
	}

	static char sRequest[256];
	FormatEx(sRequest, sizeof(sRequest), "https://api.steampowered.com/ISteamUser/GetPlayerSummaries/v0002/?key=%s&steamids=%s&format=vdf", g_sAPIKey, szSteamID64);
	Handle hRequest = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, sRequest);
	if(!hRequest || !SteamWorks_SetHTTPRequestContextValue(hRequest, client) || !SteamWorks_SetHTTPCallbacks(hRequest, OnTransferCompleted) || !SteamWorks_SendHTTPRequest(hRequest))
	{
		delete hRequest;
	}
}

public int OnSettingsChanged(ConVar convar, const char[] oldVal, const char[] newVal)
{
	if(StrEqual(oldVal, newVal, true))
	{
        return;
	}
	if(convar == g_cCallAdmin_Webhook)
	{
		strcopy(g_sCallAdmin_Webhook, sizeof(g_sCallAdmin_Webhook), newVal);
	}
	else if(convar == g_cCallAdmin_BotName)
	{
		strcopy(g_sCallAdmin_BotName, sizeof(g_sCallAdmin_BotName), newVal);
	}
	else if(convar == g_cCallAdmin_BotAvatar)
	{
		strcopy(g_sCallAdmin_BotAvatar, sizeof(g_sCallAdmin_BotAvatar), newVal);
	}
	else if(convar == g_cCallAdmin_Color)
	{
		strcopy(g_sCallAdmin_Color, sizeof(g_sCallAdmin_Color), newVal);
	}
	else if(convar == g_cCallAdmin_Content)
	{
		strcopy(g_sCallAdmin_Content, sizeof(g_sCallAdmin_Content), newVal);
	}
	else if(convar == g_cCallAdmin_FooterIcon)
	{
		strcopy(g_sCallAdmin_FooterIcon, sizeof(g_sCallAdmin_FooterIcon), newVal);
	}
	else if(convar == g_cBugReport_Webhook)
	{
		strcopy(g_sBugReport_Webhook, sizeof(g_sBugReport_Webhook), newVal);
	}
	else if(convar == g_cBugReport_BotName)
	{
		strcopy(g_sBugReport_BotName, sizeof(g_sBugReport_BotName), newVal);
	}
	else if(convar == g_cBugReport_BotAvatar)
	{
		strcopy(g_sBugReport_BotAvatar, sizeof(g_sBugReport_BotAvatar), newVal);
	}
	else if(convar == g_cBugReport_Color)
	{
		strcopy(g_sBugReport_Color, sizeof(g_sBugReport_Color), newVal);
	}
	else if(convar == g_cBugReport_Content)
	{
		strcopy(g_sBugReport_Content, sizeof(g_sBugReport_Content), newVal);
	}
	else if(convar == g_cBugReport_FooterIcon)
	{
		strcopy(g_sBugReport_FooterIcon, sizeof(g_sBugReport_FooterIcon), newVal);
	}
	else if(convar == g_cSourceBans_Webhook)
	{
		strcopy(g_sSourceBans_Webhook, sizeof(g_sSourceBans_Webhook), newVal);
	}
	else if(convar == g_cSourceBans_BotName)
	{
		strcopy(g_sSourceBans_BotName, sizeof(g_sSourceBans_BotName), newVal);
	}
	else if(convar == g_cSourceBans_BotAvatar)
	{
		strcopy(g_sSourceBans_BotAvatar, sizeof(g_sSourceBans_BotAvatar), newVal);
	}
	else if(convar == g_cSourceBans_Color)
	{
		strcopy(g_sSourceBans_Color, sizeof(g_sSourceBans_Color), newVal);
	}
	else if(convar == g_cSourceBans_PermaColor)
	{
		strcopy(g_sSourceBans_PermaColor, sizeof(g_sSourceBans_PermaColor), newVal);
	}
	else if(convar == g_cSourceBans_Content)
	{
		strcopy(g_sSourceBans_Content, sizeof(g_sSourceBans_Content), newVal);
	}
	else if(convar == g_cSourceBans_FooterIcon)
	{
		strcopy(g_sSourceBans_FooterIcon, sizeof(g_sSourceBans_FooterIcon), newVal);
	}
	else if(convar == g_cSourceBans_Webhook)
	{
		strcopy(g_sSourceBans_Webhook, sizeof(g_sSourceBans_Webhook), newVal);
	}
	else if(convar == g_cSourceComms_BotName)
	{
		strcopy(g_sSourceComms_BotName, sizeof(g_sSourceComms_BotName), newVal);
	}
	else if(convar == g_cSourceComms_BotAvatar)
	{
		strcopy(g_sSourceComms_BotAvatar, sizeof(g_sSourceComms_BotAvatar), newVal);
	}
	else if(convar == g_cSourceComms_Color)
	{
		strcopy(g_sSourceComms_Color, sizeof(g_sSourceComms_Color), newVal);
	}
	else if(convar == g_cSourceComms_PermaColor)
	{
		strcopy(g_sSourceComms_PermaColor, sizeof(g_sSourceComms_PermaColor), newVal);
	}
	else if(convar == g_cSourceComms_Content)
	{
		strcopy(g_sSourceComms_Content, sizeof(g_sSourceComms_Content), newVal);
	}
	else if(convar == g_cSourceComms_FooterIcon)
	{
		strcopy(g_sSourceComms_FooterIcon, sizeof(g_sSourceComms_FooterIcon), newVal);
	}
	else if(convar == g_cMap_Webhook)
	{
		strcopy(g_sMap_Webhook, sizeof(g_sMap_Webhook), newVal);
	}
	else if(convar == g_cMap_BotName)
	{
		strcopy(g_sMap_BotName, sizeof(g_sMap_BotName), newVal);
	}
	else if(convar == g_cMap_BotAvatar)
	{
		strcopy(g_sMap_BotAvatar, sizeof(g_sMap_BotAvatar), newVal);
	}
	else if(convar == g_cMap_Color)
	{
		strcopy(g_sMap_Color, sizeof(g_sMap_Color), newVal);
	}
	else if(convar == g_cMap_Content)
	{
		strcopy(g_sMap_Content, sizeof(g_sMap_Content), newVal);
	}
	else if(convar == g_cChatRelay_Webhook)
	{
		strcopy(g_sChatRelay_Webhook, sizeof(g_sChatRelay_Webhook), newVal);
	}
	else if(convar == g_cChatRelay_BlockList)
	{
		ExplodeString(newVal, ", ", g_sChatRelay_BlockList, MAX_BLOCKLIST_LIMIT, 64);
	}
	else if(convar == g_cAdminChatRelay_Webhook)
	{
		strcopy(g_sAdminChatRelay_Webhook, sizeof(g_sAdminChatRelay_Webhook), newVal);
	}
	else if(convar == g_cAdminChatRelay_BlockList)
	{
		ExplodeString(newVal, ", ", g_sAdminChatRelay_BlockList, MAX_BLOCKLIST_LIMIT, 64);
	}
	else if(convar == g_cAdminLog_Webhook)
	{
		strcopy(g_sAdminLog_Webhook, sizeof(g_sAdminLog_Webhook), newVal);
	}
	else if(convar == g_cAdminLog_BlockList)
	{
		ExplodeString(newVal, ", ", g_sAdminLog_BlockList, MAX_BLOCKLIST_LIMIT, 64);
	}
	else if(convar == g_cVerificationChannelID)
	{
		strcopy(g_sVerificationChannelID, sizeof(g_sVerificationChannelID), newVal);
	}
	else if(convar == g_cChatRelayChannelID)
	{
		strcopy(g_sChatRelayChannelID, sizeof(g_sChatRelayChannelID), newVal);
	}
	else if(convar == g_cGuildID)
	{
		strcopy(g_sGuildID, sizeof(g_sGuildID), newVal);
	}
	else if(convar == g_cRoleID)
	{
		strcopy(g_sRoleID, sizeof(g_sRoleID), newVal);
	}
	else if(convar == g_cAPIKey)
	{
		strcopy(g_sAPIKey, sizeof(g_sAPIKey), newVal);
	}
	else if(convar == g_cBotToken)
	{
		strcopy(g_sBotToken, sizeof(g_sBotToken), newVal);
	}
	else if(convar == g_cDNSServerIP)
	{
		strcopy(g_sServerIP, sizeof(g_sServerIP), newVal);
		ServerIP(g_sServerIP, sizeof(g_sServerIP));
	}
	else if(convar == g_cLinkCommand)
	{
		strcopy(g_sLinkCommand, sizeof(g_sLinkCommand), newVal);
	}
	else if(convar == g_cViewIDCommand)
	{
		strcopy(g_sViewIDCommand, sizeof(g_sViewIDCommand), newVal);
	}
	else if(convar == g_cInviteLink)
	{
		strcopy(g_sInviteLink, sizeof(g_sInviteLink), newVal);
	}
	else if(convar == g_cDiscordPrefix)
	{
		strcopy(g_sDiscordPrefix, sizeof(g_sDiscordPrefix), newVal);
	}
	else if(convar == g_cServerPrefix)
	{
		strcopy(g_sServerPrefix, sizeof(g_sServerPrefix), newVal);
	}
	else if(convar == g_cTableName)
	{
		strcopy(g_sTableName, sizeof(g_sTableName), newVal);
		char dtbname[32];
		g_cDatabaseName.GetString(dtbname, sizeof(dtbname));
		SQL_TConnect(SQLQuery_Connect, dtbname);
		RefreshClients();
	}
}

public void GuildList(DiscordBot bawt, char[] id, char[] name, char[] icon, bool owner, int permissions, const bool listen)
{
	Bot.GetGuildChannels(id, ChannelList, INVALID_FUNCTION, listen);
}

public void ChannelList(DiscordBot bawt, const char[] guild, DiscordChannel Channel, const bool listen)
{
	if(StrEqual(g_sBotToken, "") || StrEqual(g_sChatRelayChannelID, "") && StrEqual(g_sVerificationChannelID, ""))
	{
		return;
	}
	if(Bot.IsListeningToChannel(Channel))
	{
		//Bot.StopListeningToChannel(Channel);
		return;
	}
	char id[20], name[32];
	Channel.GetID(id, sizeof(id));
	Channel.GetName(name, sizeof(name));
	if(strlen(g_sChatRelayChannelID) > 10) //ChannelID size is around 18-20 char
	{
		if(StrEqual(id, g_sChatRelayChannelID))
		{
			Bot.StartListeningToChannel(Channel, ChatRelayReceived);
		}
	}
	if(strlen(g_sVerificationChannelID) > 10)
	{
		if(StrEqual(id, g_sVerificationChannelID))
		{
			g_sVerificationChannelName = name;
			if(listen)
			{
				Bot.StartListeningToChannel(Channel, OnMessageReceived);
			}
		}
	}
}

public void CallAdmin_OnServerDataChanged(ConVar convar, ServerData type, const char[] oldVal, const char[] newVal)
{
	if (type == ServerData_HostName)
		CallAdmin_GetHostName(g_sServerName, sizeof(g_sServerName));
}

public Action Command_ViewId(int client, int args)
{
	if(!client || StrEqual(g_sVerificationChannelID, ""))
	{
		return Plugin_Handled;
	}
	
	CPrintToChat(client, "%s %T", g_sServerPrefix, "LinkYourID", client, g_sUniqueCode[client]);
	
	CPrintToChat(client, "%s %T", g_sServerPrefix, "LinkConnect", client);
	CPrintToChat(client, "%s {blue}%s", g_sServerPrefix, g_sInviteLink);
	
	CPrintToChat(client, "%s %T", g_sServerPrefix, "LinkUsage", client, g_sLinkCommand, g_sUniqueCode[client]);
	CPrintToChat(client, "%s %T", g_sServerPrefix, "LinkUsage2", client, g_sVerificationChannelName);
	
	return Plugin_Handled;
}

public Action Check(int client, const char[] command, int args)
{
	if(!client || client > MaxClients)
	{
		return Plugin_Continue;
	}
	if(!g_bMember[client])
	{
		CPrintToChat(client, "%s %T", g_sServerPrefix, "MustVerify", client, ChangePartsInString(g_sViewIDCommand, "sm_", "!"));
		return Plugin_Stop;
	}
	return Plugin_Continue;
}
