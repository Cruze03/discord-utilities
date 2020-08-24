public Action Timer_DisplayMapNotification(Handle timer, DataPack pack)
{
	char PrevMap[64], map[64], thumb[256];
	pack.Reset();
	pack.ReadString(map, sizeof(map));
	pack.ReadString(thumb, sizeof(thumb));
	GetLastMap(PrevMap, sizeof(PrevMap));
	if(strcmp(PrevMap, map) == 0)
	{
		return;
	}
	DiscordWebHook hook = new DiscordWebHook( g_sMap_Webhook );
	hook.SlackMode = true;
	if(g_sMap_BotAvatar[0])
	{
		hook.SetAvatar( g_sMap_BotAvatar );
	}
	if(g_sMap_BotName[0])
	{
		hook.SetUsername( g_sMap_BotName );
	}
	
	MessageEmbed embed = new MessageEmbed();
	
	embed.SetThumb(thumb);
	if(StrContains(g_sMap_Color, "#") != -1)
	{
		embed.SetColor(g_sMap_Color);
	}
	else
	{
		LogError("[Discord-Utilities] Map notfication is using default color as you've set invalid map notfication color.");
		embed.SetColor(DEFAULT_COLOR);
	}
	
	char buffer[512], trans[64];
	embed.SetTitle( g_sServerName );
	
	Format(trans, sizeof(trans), "%T", "CurrentMapField", LANG_SERVER);
	embed.AddField( trans, map, true );
	
	Format(trans, sizeof(trans), "%T", "PlayersOnlineField", LANG_SERVER);
	Format(buffer, sizeof(buffer), "%d/%d", GetRealConnectedPlayers(), GetMaxHumanPlayers());
	embed.AddField( trans, buffer, true );
	
	Format(trans, sizeof(trans), "%T", "DirectConnectField", LANG_SERVER);
	Format( buffer, sizeof( buffer ), "steam://connect/%s", g_sServerIP );
	embed.AddField( trans, buffer, false );
	
	hook.Embed( embed );
	hook.Send();
	delete hook;
	UpdateLastMap();
}

public void CallAdmin_OnReportHandled(int client, int id)
{
	if(StrEqual(g_sCallAdmin_Webhook, ""))
	{
		return;
	}
	if(!g_bCallAdmin)
	{
		return;
	}
	if (id != g_iLastReportID)
	{
		return;
	}
	
	char clientName[MAX_NAME_LENGTH], clientAuth[32], clientAuth2[32];
	GetClientName(client, clientName, sizeof(clientName));
	GetClientAuthId(client, AuthId_SteamID64, clientAuth, sizeof(clientAuth));
	GetClientAuthId(client, AuthId_Steam2, clientAuth2, sizeof(clientAuth2));
	Discord_EscapeString(clientName, sizeof(clientName));
	
	DiscordWebHook hook = new DiscordWebHook( g_sCallAdmin_Webhook );
	hook.SlackMode = true;
	if(g_sCallAdmin_BotName[0])
	{
		hook.SetUsername( g_sCallAdmin_BotName );
	}
	if(g_sCallAdmin_BotAvatar[0])
	{
		hook.SetAvatar( g_sCallAdmin_BotAvatar );
	}
	
	MessageEmbed embed = new MessageEmbed();
	
	if(StrContains(g_sCallAdmin_Color, "#") != -1)
	{
		embed.SetColor(g_sCallAdmin_Color);
	}
	else
	{
		LogError("[Discord-Utilities] CallAdmin ReportHandled is using default color as you've set invalid CallAdmin ReportHandled color.");
		embed.SetColor(DEFAULT_COLOR);
	}
	
	char buffer[512], trans[64];
	Format( trans, sizeof( trans ), "%T", "CallAdminReportHandledTitle", LANG_SERVER);
	embed.SetTitle( trans );
	
	Format( trans, sizeof( trans ), "%T", "CallAdminReportHandlerName", LANG_SERVER);
	Format( buffer, sizeof( buffer ), "[%s](http://www.steamcommunity.com/profiles/%s)(%s)", clientName, clientAuth, clientAuth2 );
	embed.AddField( trans, buffer, true );
	
	Format( trans, sizeof( trans ), "%T", "CallAdminReportIDField", LANG_SERVER);
	Format(buffer, sizeof(buffer), "%d", g_iLastReportID);
	embed.AddField( trans, buffer, true );
	
	Format( trans, sizeof( trans ), "%T", "DirectConnectField", LANG_SERVER);
	Format( buffer, sizeof( buffer ), "steam://connect/%s", g_sServerIP );
	embed.AddField( trans, buffer, false );
	
	if(g_sCallAdmin_FooterIcon[0])
	{
		embed.SetFooterIcon( g_sCallAdmin_FooterIcon );
	}
	Format( buffer, sizeof( buffer ), "%T", "ServerField", LANG_SERVER, g_sServerName );
	embed.SetFooter( buffer );
	
	hook.Embed( embed );
	hook.Send();
	delete hook;
}


public void CallAdmin_OnReportPost(int client, int target, const char[] reason)
{
	if(StrEqual(g_sCallAdmin_Webhook, ""))
	{
		return;
	}
	if(!g_bCallAdmin)
	{
		return;
	}
	char sReason[(REASON_MAX_LENGTH + 1) * 2];
	strcopy(sReason, sizeof(sReason), reason);
	Discord_EscapeString(sReason, sizeof(sReason));
	
	char clientAuth[21];
	char clientAuth2[21];
	char clientName[(MAX_NAME_LENGTH + 1) * 2];
	
	if (client == REPORTER_CONSOLE)
	{
		Format(clientName, sizeof(clientName), "%T", "SERVER", LANG_SERVER);
		Format(clientAuth, sizeof(clientAuth), "%T", "CONSOLE", LANG_SERVER);
	}
	else
	{
		GetClientAuthId(client, AuthId_SteamID64, clientAuth, sizeof(clientAuth));
		GetClientAuthId(client, AuthId_Steam2, clientAuth2, sizeof(clientAuth2));
		GetClientName(client, clientName, sizeof(clientName));
		Discord_EscapeString(clientName, sizeof(clientName));
	}
	
	char targetAuth[21];
	char targetAuth2[21];
	char targetName[(MAX_NAME_LENGTH + 1) * 2];
	
	GetClientAuthId(target, AuthId_SteamID64, targetAuth, sizeof(targetAuth));
	GetClientAuthId(target, AuthId_Steam2, targetAuth2, sizeof(targetAuth2));
	GetClientName(target, targetName, sizeof(targetName));
	Discord_EscapeString(targetName, sizeof(targetName));
	
	int index = g_aCallAdmin_ReportedList.FindString(targetAuth);
	
	if(index != -1)
	{
		return;
	}
	
	g_aCallAdmin_ReportedList.PushString(targetAuth);
	
	DiscordWebHook hook = new DiscordWebHook( g_sCallAdmin_Webhook );
	hook.SlackMode = true;
	if(g_sCallAdmin_BotName[0])
	{
		hook.SetUsername( g_sCallAdmin_BotName );
	}
	if(g_sCallAdmin_BotAvatar[0])
	{
		hook.SetAvatar( g_sCallAdmin_BotAvatar );
	}
	
	MessageEmbed embed = new MessageEmbed();
	
	if(StrContains(g_sCallAdmin_Color, "#") != -1)
	{
		embed.SetColor(g_sCallAdmin_Color);
	}
	else
	{
		LogError("[Discord-Utilities] CallAdmin ReportPost is using default color as you've set invalid CallAdmin ReportPost color.");
		embed.SetColor(DEFAULT_COLOR);
	}
	
	g_iLastReportID = CallAdmin_GetReportID();
	
	char buffer[512], trans[64];
	Format( trans, sizeof( trans ), "%T", "CallAdminReportTitle", LANG_SERVER);
	embed.SetTitle( buffer );
	
	if (client != REPORTER_CONSOLE)
	{
		Format( buffer, sizeof( buffer ), "[%s](http://www.steamcommunity.com/profiles/%s) (%s)", clientName, clientAuth, clientAuth2 );
	}
	else
	{
		Format( buffer, sizeof( buffer ), "%s", clientName );
	}
	Format(trans, sizeof(trans), "%T", "ReporterField", LANG_SERVER);
	embed.AddField( trans, buffer, true );
	
	Format(trans, sizeof(trans), "%T", "TargetField", LANG_SERVER);
	Format( buffer, sizeof( buffer ), "[%s](http://www.steamcommunity.com/profiles/%s) (%s)", targetName, targetAuth, targetAuth2 );
	embed.AddField( trans, buffer, true	);
	
	Format(trans, sizeof(trans), "%T", "ReasonField", LANG_SERVER);
	embed.AddField( trans, sReason, true );

	Format(trans, sizeof(trans), "%T", "CallAdminReportIDField", LANG_SERVER);
	Format(buffer, sizeof(buffer), "%d",  g_iLastReportID);
	
	embed.AddField( trans, buffer, false );
	
	Format(trans, sizeof(trans), "%T", "DirectConnectField", LANG_SERVER);
	Format( buffer, sizeof( buffer ), "steam://connect/%s", g_sServerIP );
	embed.AddField( trans, buffer, true );
	
	if(g_sCallAdmin_FooterIcon[0])
	{
		embed.SetFooterIcon( g_sCallAdmin_FooterIcon );
	}
	Format( buffer, sizeof( buffer ), "%T", "ServerField", LANG_SERVER, g_sServerName );
	embed.SetFooter( buffer );
	
	if(g_sCallAdmin_Content[0])
	{
		hook.SetContent( g_sCallAdmin_Content );
	}
	
	hook.Embed( embed );
	hook.Send();
	delete hook;
}

public void BugReport_OnReportPost(int client, const char[] map, const char[] reason, ArrayList array)
{
	if(StrEqual(g_sBugReport_Webhook, ""))
	{
		return;
	}
	
	if(!g_bBugReport)
	{
		return;
	}
	
	char sReason[(REASON_MAX_LENGTH + 1) * 2];
	strcopy(sReason, sizeof(sReason), reason);
	int index = array.FindString(sReason);

	if(index != -1)
	{
		LogError("Duplicate Reason. Skipping.");
		return;
	}

	Discord_EscapeString(sReason, sizeof(sReason));
	
	char clientAuth[21];
	char clientAuth2[21];
	char clientName[(MAX_NAME_LENGTH + 1) * 2];
	
	if (client == REPORTER_CONSOLE)
	{
		Format(clientName, sizeof(clientName), "%T", "SERVER", LANG_SERVER);
		Format(clientAuth, sizeof(clientAuth), "%T", "CONSOLE", LANG_SERVER);
	}
	else
	{
		GetClientAuthId(client, AuthId_SteamID64, clientAuth, sizeof(clientAuth));
		GetClientAuthId(client, AuthId_Steam2, clientAuth2, sizeof(clientAuth2));
		GetClientName(client, clientName, sizeof(clientName));
		Discord_EscapeString(clientName, sizeof(clientName));
	}
	
	DiscordWebHook hook = new DiscordWebHook( g_sBugReport_Webhook );
	hook.SlackMode = true;
	if(g_sBugReport_BotName[0])
	{
		hook.SetUsername( g_sBugReport_BotName );
	}
	
	if(g_sBugReport_BotAvatar[0])
	{
		hook.SetAvatar( g_sBugReport_BotAvatar );
	}
	
	MessageEmbed embed = new MessageEmbed();
	
	if(StrContains(g_sBugReport_Color, "#") != -1)
	{
		embed.SetColor(g_sBugReport_Color);
	}
	else
	{
		LogError("[Discord-Utilities] BugReport is using default color as you've set invalid BugReport color.");
		embed.SetColor(DEFAULT_COLOR);
	}
	
	char buffer[512], trans[64];
	Format( trans, sizeof( trans ), "%T", "BugReportTitle", LANG_SERVER);
	embed.SetTitle( buffer );
	
	if (client != REPORTER_CONSOLE)
	{
		Format( buffer, sizeof( buffer ), "[%s](http://www.steamcommunity.com/profiles/%s) (%s)", clientName, clientAuth, clientAuth2 );
	}
	else
	{
		Format( buffer, sizeof( buffer ), "%s", clientName );
	}
	Format( trans, sizeof( trans ), "%T", "ReporterField", LANG_SERVER);
	embed.AddField( trans, buffer, true );
	
	Format( trans, sizeof( trans ), "%T", "MapField", LANG_SERVER);
	embed.AddField( trans, map, true );
	
	Format( trans, sizeof( trans ), "%T", "ReasonField", LANG_SERVER);
	embed.AddField( trans, sReason, false );
	
	Format( trans, sizeof( trans ), "%T", "DirectConnectField", LANG_SERVER);
	Format( buffer, sizeof( buffer ), "steam://connect/%s", g_sServerIP );
	embed.AddField( trans, buffer, false );
	
	if(g_sBugReport_FooterIcon[0])
	{
		embed.SetFooterIcon( g_sBugReport_FooterIcon );
	}
	Format( buffer, sizeof( buffer ), "%T", "ServerField", LANG_SERVER, g_sServerName);
	embed.SetFooter( buffer );
	
	if(g_sBugReport_Content[0])
	{
		hook.SetContent(g_sBugReport_Content);
	}
	
	hook.Embed( embed );
	hook.Send();
	delete hook;
}

public void SBPP_OnBanPlayer(int admin, int target, int time, const char[] reason)
{
	if(StrEqual(g_sSourceBans_Webhook, ""))
	{
		return;
	}
	if(!g_bSourceBans)
	{
		return;
	}
	char clientName[MAX_NAME_LENGTH], clientAuth[32], clientAuth2[32];
	char targetName[MAX_NAME_LENGTH], targetAuth[32], targetAuth2[32];
	GetClientName(target, targetName, sizeof(targetName));
	GetClientAuthId(target, AuthId_SteamID64, targetAuth, sizeof(targetAuth));
	GetClientAuthId(target, AuthId_Steam2, targetAuth2, sizeof(targetAuth2));
	Discord_EscapeString(targetName, sizeof(targetName));
	
	if(!admin)
	{
		Format(clientName, sizeof(clientName), "%T", "SERVER", LANG_SERVER);
		Format(clientAuth, sizeof(clientAuth), "%T", "CONSOLE", LANG_SERVER);
	}
	else
	{
		GetClientAuthId(admin, AuthId_SteamID64, clientAuth, sizeof(clientAuth));
		GetClientAuthId(admin, AuthId_Steam2, clientAuth2, sizeof(clientAuth2));
		GetClientName(admin, clientName, sizeof(clientName));
		Discord_EscapeString(clientName, sizeof(clientName));
	}
	
	char sReason[64];
	
	strcopy(sReason, sizeof(sReason), reason);

	if(strlen(sReason) < 2)
	{
		Format(sReason, sizeof(sReason), "%T", "NoReasonSpecified", LANG_SERVER);
	}
	Discord_EscapeString(sReason, sizeof(sReason));
	
	DiscordWebHook hook = new DiscordWebHook( g_sSourceBans_Webhook );
	hook.SlackMode = true;
	if(g_sSourceBans_BotName[0])
	{
		hook.SetUsername( g_sSourceBans_BotName );
	}
	
	if(g_sSourceBans_BotAvatar[0])
	{
		hook.SetAvatar( g_sSourceBans_BotAvatar );
	}
	
	MessageEmbed embed = new MessageEmbed();
	
	char buffer[512], trans[64];
	Format( trans, sizeof( trans ), "%T", "SourceBansTitle", LANG_SERVER);
	embed.SetTitle( trans );
	
	if(admin)
	{
		Format( buffer, sizeof( buffer ), "[%s](http://www.steamcommunity.com/profiles/%s) (%s)", clientName, clientAuth, clientAuth2 );
	}
	else
	{
		Format( buffer, sizeof( buffer ), "%s", clientName );
		
	}
	Format( trans, sizeof( trans ), "%T", "AdminField", LANG_SERVER);
	embed.AddField( trans, buffer, true );
	
	Format( trans, sizeof( trans ), "%T", "PlayerField", LANG_SERVER);
	Format( buffer, sizeof( buffer ), "[%s](http://www.steamcommunity.com/profiles/%s) (%s)", targetName, targetAuth, targetAuth2 );
	embed.AddField( trans, buffer, true	);
	
	char sTime[32];
	IntToString(time, sTime, sizeof(sTime));
	if(time < 0)
	{
		Format(buffer, sizeof( buffer ), "%T", "TEMPORARY", LANG_SERVER);
		if(g_sSourceBans_Color[0])
		{
			embed.SetColor(g_sSourceBans_Color);
		}
		else
		{
			LogError("[Discord-Utilities] Sourcebans is using default color as you've set Sourcebans color to blank.");
			embed.SetColor(DEFAULT_COLOR);
		}
	}
	else if(time > 0)
	{
		char sMinute[16], sMinutes[16];
		Format(sMinute, sizeof(sMinute), "%T", "MINUTE", LANG_SERVER);
		Format(sMinutes, sizeof(sMinutes), "%T", "MINUTES", LANG_SERVER);
		Format( buffer, sizeof( buffer ), "%d %s", time, time == 1 ? sMinute:sMinutes);
		if(g_sSourceBans_Color[0])
		{
			embed.SetColor(g_sSourceBans_Color);
		}
		else
		{
			LogError("[Discord-Utilities] Sourcebans is using default color as you've set Sourcebans color to blank.");
			embed.SetColor(DEFAULT_COLOR);
		}
	}
	else
	{
		Format(buffer, sizeof( buffer ), "%T", "PERMANENT", LANG_SERVER);
		if(g_sSourceBans_PermaColor[0])
		{
			embed.SetColor(g_sSourceBans_PermaColor);
		}
		else
		{
			LogError("[Discord-Utilities] Sourcebans permaban is using default color as you've set Sourcebans perma color to blank.");
			embed.SetColor(DEFAULT_COLOR);
		}
	}
	Format( trans, sizeof( trans ), "%T", "LengthField", LANG_SERVER);
	embed.AddField( trans, buffer, true );
	
	Format( trans, sizeof( trans ), "%T", "ReasonField", LANG_SERVER);
	embed.AddField( trans, sReason, true );
	
	Format( trans, sizeof( trans ), "%T", "DirectConnectField", LANG_SERVER);
	Format( buffer, sizeof( buffer ), "steam://connect/%s", g_sServerIP );
	embed.AddField( trans, buffer, true );
	
	if(g_sSourceBans_FooterIcon[0])
	{
		embed.SetFooterIcon( g_sSourceBans_FooterIcon );
	}
	
	Format( buffer, sizeof( buffer ), "%T", "ServerField", LANG_SERVER, g_sServerName );
	embed.SetFooter( buffer );
	
	if(g_sSourceBans_Content[0])
	{
		hook.SetContent(g_sSourceBans_Content);
	}
	
	hook.Embed( embed );
	hook.Send();
	delete hook;
}

public void SBPP_OnReportPlayer(int reporter, int target, const char[] reason)
{
	if(StrEqual(g_sCallAdmin_Webhook, ""))
	{
		return;
	}
	if(!g_bSourceBans)
	{
		return;
	}
	char clientName[MAX_NAME_LENGTH], clientAuth[32], clientAuth2[32];
	char targetName[MAX_NAME_LENGTH], targetAuth[32], targetAuth2[32];
	GetClientName(target, targetName, sizeof(targetName));
	GetClientAuthId(target, AuthId_SteamID64, targetAuth, sizeof(targetAuth));
	GetClientAuthId(target, AuthId_Steam2, targetAuth2, sizeof(targetAuth2));
	Discord_EscapeString(targetName, sizeof(targetName));
	
	if(!reporter)
	{
		Format(clientName, sizeof(clientName), "%T", "SERVER", LANG_SERVER);
		Format(clientAuth, sizeof(clientAuth), "%T", "CONSOLE", LANG_SERVER);
	}
	else
	{
		GetClientAuthId(reporter, AuthId_SteamID64, clientAuth, sizeof(clientAuth));
		GetClientAuthId(reporter, AuthId_Steam2, clientAuth2, sizeof(clientAuth2));
		GetClientName(reporter, clientName, sizeof(clientName));
		Discord_EscapeString(clientName, sizeof(clientName));
	}
	
	char sReason[64];
	
	strcopy(sReason, sizeof(sReason), reason);

	Discord_EscapeString(sReason, sizeof(sReason));
	
	DiscordWebHook hook = new DiscordWebHook( g_sCallAdmin_Webhook );
	hook.SlackMode = true;
	if(g_sCallAdmin_BotName[0])
	{
		hook.SetUsername( g_sCallAdmin_BotName );
	}
	
	if(g_sCallAdmin_BotAvatar[0])
	{
		hook.SetAvatar( g_sCallAdmin_BotAvatar );
	}
	
	MessageEmbed embed = new MessageEmbed();
	
	if(StrContains(g_sCallAdmin_Color, "#") != -1)
	{
		embed.SetColor(g_sCallAdmin_Color);
	}
	else
	{
		LogError("[Discord-Utilities] SourceBans ReportPlayer is using default color as you've set invalid SourceBans ReportPlayer color.");
		embed.SetColor(DEFAULT_COLOR);
	}
	
	char buffer[512], trans[64];
	Format( trans, sizeof( trans ), "%T", "SourceBansReportTitle", LANG_SERVER);
	embed.SetTitle( trans );
	
	if(!StrEqual(clientAuth, "Server"))
	{
		Format( buffer, sizeof( buffer ), "[%s](http://www.steamcommunity.com/profiles/%s) (%s)", clientName, clientAuth, clientAuth2 );
	}
	else
	{
		Format( buffer, sizeof( buffer ), "%s", clientName );
		
	}
	Format( trans, sizeof( trans ), "%T", "ReporterField", LANG_SERVER);
	embed.AddField( trans, buffer, true );
	
	Format( buffer, sizeof( buffer ), "[%s](http://www.steamcommunity.com/profiles/%s) (%s)", targetName, targetAuth, targetAuth2 );
	Format( trans, sizeof( trans ), "%T", "TargetField", LANG_SERVER);
	embed.AddField( trans, buffer, true	);
	
	Format( trans, sizeof( trans ), "%T", "ReasonField", LANG_SERVER);
	embed.AddField( trans, sReason, true );
	
	Format( trans, sizeof( trans ), "%T", "DirectConnectField", LANG_SERVER);
	Format( buffer, sizeof( buffer ), "steam://connect/%s", g_sServerIP );
	embed.AddField( trans, buffer, true );
	
	if(g_sCallAdmin_FooterIcon[0])
	{
		embed.SetFooterIcon( g_sCallAdmin_FooterIcon );
	}
	
	Format( buffer, sizeof( buffer ), "%T", "ServerField", LANG_SERVER, g_sServerName );
	embed.SetFooter( buffer );
	
	if(g_sCallAdmin_Content[0])
	{
		hook.SetContent(g_sCallAdmin_Content);
	}
	
	hook.Embed( embed );
	hook.Send();
	delete hook;
}

public void SourceComms_OnBlockAdded(int admin, int target, int time, int commtype, char[] reason)
{
	if(StrEqual(g_sSourceComms_Webhook, ""))
	{
		return;
	}
	if(!g_bSourceComms)
	{
		return;
	}
	if(commtype != TYPE_MUTE && commtype != TYPE_GAG && commtype != TYPE_SILENCE)
	{
		return;
	}
	char clientName[MAX_NAME_LENGTH], clientAuth[32], clientAuth2[32];
	char targetName[MAX_NAME_LENGTH], targetAuth[32], targetAuth2[32];
	GetClientName(target, targetName, sizeof(targetName));
	GetClientAuthId(target, AuthId_SteamID64, targetAuth, sizeof(targetAuth));
	GetClientAuthId(target, AuthId_Steam2, targetAuth2, sizeof(targetAuth2));
	Discord_EscapeString(targetName, sizeof(targetName));
	
	if(!admin)
	{
		Format(clientName, sizeof(clientName), "%T", "SERVER", LANG_SERVER);
		Format(clientAuth, sizeof(clientAuth), "%T", "CONSOLE", LANG_SERVER);
	}
	else
	{
		GetClientAuthId(admin, AuthId_SteamID64, clientAuth, sizeof(clientAuth));
		GetClientAuthId(admin, AuthId_Steam2, clientAuth2, sizeof(clientAuth2));
		GetClientName(admin, clientName, sizeof(clientName));
		Discord_EscapeString(clientName, sizeof(clientName));
	}
	
	char sReason[64];
	
	strcopy(sReason, sizeof(sReason), reason);

	if(strlen(sReason) < 2)
	{
		Format(sReason, sizeof(sReason), "%T", "NoReasonSpecified", LANG_SERVER);
	}
	Discord_EscapeString(sReason, sizeof(sReason));
	
	DiscordWebHook hook = new DiscordWebHook( g_sSourceComms_Webhook );
	hook.SlackMode = true;
	if(g_sSourceComms_BotName[0])
	{
		hook.SetUsername( g_sSourceComms_BotName );
	}
	
	if(g_sSourceComms_BotAvatar[0])
	{
		hook.SetAvatar( g_sSourceComms_BotAvatar );
	}
	
	MessageEmbed embed = new MessageEmbed();
	
	char buffer[512], trans[64];
	Format( trans, sizeof( trans ), "%T", "SourceCommsTitle", LANG_SERVER);
	embed.SetTitle( trans );
	
	if(!admin)
	{
		Format( buffer, sizeof( buffer ), "[%s](http://www.steamcommunity.com/profiles/%s) (%s)", clientName, clientAuth, clientAuth2 );
	}
	else
	{
		Format( buffer, sizeof( buffer ), "%s", clientName );
		
	}
	Format( trans, sizeof( trans ), "%T", "AdminField", LANG_SERVER);
	embed.AddField( trans, buffer, true );
	
	Format( trans, sizeof( trans ), "%T", "PlayerField", LANG_SERVER);
	Format( buffer, sizeof( buffer ), "[%s](http://www.steamcommunity.com/profiles/%s) (%s)", targetName, targetAuth, targetAuth2 );
	embed.AddField( trans, buffer, true	);
	
	if(time < 0)
	{
		Format(buffer, sizeof( buffer ), "%T", "TEMPORARY", LANG_SERVER);
		if(StrContains(g_sSourceComms_Color[0], "#") != -1)
		{
			embed.SetColor(g_sSourceComms_Color);
		}
		else
		{
			LogError("[Discord-Utilities] Sourcecomms is using default color as you've set invalid Sourcecomms color.");
			embed.SetColor(DEFAULT_COLOR);
		}
	}
	else if(time > 0)
	{
		char sMinute[16], sMinutes[16];
		Format(sMinute, sizeof(sMinute), "%T", "MINUTE", LANG_SERVER);
		Format(sMinutes, sizeof(sMinutes), "%T", "MINUTES", LANG_SERVER);
		Format( buffer, sizeof( buffer ), "%d %s", time, time == 1 ? sMinute:sMinutes);
		if(StrContains(g_sSourceComms_Color[0], "#") != -1)
		{
			embed.SetColor(g_sSourceComms_Color);
		}
		else
		{
			LogError("[Discord-Utilities] Sourcecomms is using default color as you've set invalid Sourcecomms color.");
			embed.SetColor(DEFAULT_COLOR);
		}
	}
	else
	{
		Format(buffer, sizeof( buffer ), "%T", "PERMANENT", LANG_SERVER);
		if(StrContains(g_sSourceComms_PermaColor[0], "#") != -1)
		{
			embed.SetColor(g_sSourceComms_PermaColor);
		}
		else
		{
			LogError("[Discord-Utilities] Sourcecomms permaban is using default color as you've set invalid Sourcecomms perma color.");
			embed.SetColor(DEFAULT_COLOR);
		}
	}
	
	Format( trans, sizeof( trans ), "%T", "LengthField", LANG_SERVER);
	embed.AddField( trans, buffer, true );
	
	switch(commtype)
	{
		case TYPE_MUTE:
		{
			Format(buffer, sizeof( buffer ), "%T", "MUTE", LANG_SERVER);
		}
		case TYPE_GAG:
		{
			Format(buffer, sizeof( buffer ), "%T", "GAG", LANG_SERVER);
		}
		case TYPE_SILENCE:
		{
			Format(buffer, sizeof( buffer ), "%T", "SILENCE", LANG_SERVER);
		}
		/*
		case TYPE_UNMUTE:
		{
			Format(buffer, sizeof( buffer ), "%T", "UN-MUTE", LANG_SERVER);
		}
		case TYPE_UNGAG:
		{
			Format(buffer, sizeof( buffer ), "%T", "UN-GAG", LANG_SERVER);
		}
		case TYPE_UNSILENCE:
		{
			Format(buffer, sizeof( buffer ), "%T", "UN-SILENCE", LANG_SERVER);
		}
		*/
	}
	Format( trans, sizeof( trans ), "%T", "TypeField", LANG_SERVER);
	embed.AddField( trans, buffer, true );
	
	Format( trans, sizeof( trans ), "%T", "ReasonField", LANG_SERVER);
	embed.AddField( trans, sReason, true );
	
	Format( trans, sizeof( trans ), "%T", "DirectConnectField", LANG_SERVER);
	Format( buffer, sizeof( buffer ), "steam://connect/%s", g_sServerIP );
	embed.AddField( trans, buffer, true );
	
	if(g_sSourceComms_FooterIcon[0])
	{
		embed.SetFooterIcon( g_sSourceComms_FooterIcon );
	}
	
	Format( buffer, sizeof( buffer ), "%T", "ServerField", LANG_SERVER, g_sServerName );
	embed.SetFooter( buffer );
	
	if(g_sSourceComms_Content[0])
	{
		hook.SetContent(g_sSourceComms_Content);
	}
	
	hook.Embed( embed );
	hook.Send();
	delete hook;
}

public void ChatRelayReceived(DiscordBot bawt, DiscordChannel channel, DiscordMessage discordmessage)
{
	if(discordmessage.GetAuthor().IsBot()) return;

	char message[512];
	char userName[32], discriminator[6];
	discordmessage.GetContent(message, sizeof(message));
	discordmessage.GetAuthor().GetUsername(userName, sizeof(userName));
	discordmessage.GetAuthor().GetDiscriminator(discriminator, sizeof(discriminator));

	CPrintToChatAll("%s %T", g_sDiscordPrefix, "ChatRelayFormat", LANG_SERVER, userName, discriminator, message);
}

public void OnMessageReceived(DiscordBot bawt, DiscordChannel channel, DiscordMessage discordmessage)
{
	if(discordmessage.GetAuthor().IsBot()) return;

	char szValues[2][99];
	char szReply[512];
	char message[512];
	char userID[20], userName[32], discriminator[6];

	discordmessage.GetContent(message, sizeof(message));
	discordmessage.GetAuthor().GetUsername(userName, sizeof(userName));
	discordmessage.GetAuthor().GetDiscriminator(discriminator, sizeof(discriminator));
	discordmessage.GetAuthor().GetID(userID, sizeof(userID));

	int retrieved1 = ExplodeString(message, " ", szValues, sizeof(szValues), sizeof(szValues[]));	
	TrimString(szValues[1]);
	
	char _szValues[3][75];
	int retrieved2 = ExplodeString(szValues[1], "-", _szValues, sizeof(_szValues), sizeof(_szValues[]));

	bool bIsPrimary = g_cPrimaryServer.BoolValue;

	if(StrEqual(szValues[0], g_sLinkCommand))
	{
		if (retrieved1 < 2)
		{
			//Prevent multiple replies, only allow the primary server to respond
			if (bIsPrimary)
			{
				Format(szReply, sizeof(szReply), "%T", "DiscordMissingParameters", LANG_SERVER, userID);
				Bot.SendMessage(channel, szReply);
				DU_DeleteMessageID(discordmessage);
			}
			return;
		}
		else if (retrieved2 != 3)
		{
			if (bIsPrimary)
			{
				Format(szReply, sizeof(szReply), "%T", "DiscordInvalidID", LANG_SERVER, userID, g_sViewIDCommand);
				Bot.SendMessage(channel, szReply);
				DU_DeleteMessageID(discordmessage);
			}
			return;
		}
		
		if(StringToInt(_szValues[0]) != g_cServerID.IntValue)
		{
			return; //Prevent multiple replies from the bot (for e.g. the plugin is installed on more than 1 server and they're using the same bot & channel)
		}

		int client = GetClientFromUniqueCode(szValues[1]);
		if(client <= 0)
		{
			Format(szReply, sizeof(szReply), "%T", "DiscordInvalid", LANG_SERVER, userID);
			Bot.SendMessage(channel, szReply);
		}
		else if (!g_bMember[client])
		{
			DataPack datapack = new DataPack();
			datapack.WriteCell(client);
			datapack.WriteString(userID);
			datapack.WriteString(userName);
			datapack.WriteString(discriminator);
			//datapack.WriteString(messageID);

			char szSteamId[32];
			GetClientAuthId(client, AuthId_Steam2, szSteamId, sizeof(szSteamId));

			char Query[512];
			g_hDB.Format(Query, sizeof(Query), "SELECT userid FROM %s WHERE steamid = '%s'", g_sTableName, szSteamId);
			SQL_TQuery(g_hDB, SQLQuery_CheckUserData, Query, datapack);
			
			//Security addition - renew unique code in case another user copies it before query returns (?)
			GetClientAuthId(client, AuthId_SteamID64, szSteamId, sizeof(szSteamId));
			int uniqueNum = GetRandomInt(100000, 999999);
			Format(g_sUniqueCode[client], sizeof(g_sUniqueCode), "%i-%i-%s", g_cServerID.IntValue, uniqueNum, szSteamId);
		} else
		{
			//Don't bother querying the DB if user is already a member
			Format(szReply, sizeof(szReply), "%T", "DiscordAlreadyLinked", LANG_SERVER, userID);
			Bot.SendMessage(channel, szReply);
		}
	}
	else
	{
		if (bIsPrimary)
		{
			Format(szReply, sizeof(szReply), "%T", "DiscordInfo", LANG_SERVER, userID, g_sLinkCommand);
			Bot.SendMessage(channel, szReply);
		}
	}
	DU_DeleteMessageID(discordmessage);
}