public int SQLQuery_Connect(Database db, const char[] error, any userid)
{
	if(db == null)
	{
		LogError("[DU-Connect] Database failure: %s", error);
		SetFailState("[Discord Utilities] Failed to connect to database");
	}
	else
	{
		delete g_hDB;

		g_hDB = db;
		
		char Ident[4096];
		SQL_GetDriverIdent(SQL_ReadDriver(g_hDB), Ident, sizeof(Ident));
		g_bIsMySQl = StrEqual(Ident, "mysql", false) ? true : false;
		
		if(g_bIsMySQl)
		{
			g_hDB.Format(Ident, sizeof(Ident), "CREATE TABLE IF NOT EXISTS `%s` (`ID` bigint(20) NOT NULL AUTO_INCREMENT, `userid` varchar(20) COLLATE utf8_bin NOT NULL, `steamid` varchar(20) COLLATE utf8_bin NOT NULL, `member` int(20) NOT NULL, `last_accountuse` int(64) NOT NULL, PRIMARY KEY (`ID`), UNIQUE KEY `steamid` (`steamid`) ) ENGINE = InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=utf8 COLLATE=utf8_bin;", g_sTableName);
		}
		else
		{
			g_hDB.Format(Ident, sizeof(Ident), "CREATE TABLE IF NOT EXISTS %s (userid varchar(20) NOT NULL, steamid varchar(20) PRIMARY KEY NOT NULL, member int(20) NOT NULL, last_accountuse INTEGER)", g_sTableName);
			SQL_SetCharset(g_hDB, "utf8");
		}
		g_hDB.Query(SQLQuery_ConnectCallback, Ident);
		PruneDatabase();
	}
	
	//For late load
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && !g_bChecked[client])
		{
			OnClientPreAdminCheck(client);
		}
	}
}

public int SQLQuery_ConnectCallback(Database db, DBResultSet results, const char[] error, any userid)
{
	if(db == null)
	{
		LogError("[DU-ConnectCallback] Database failure: %s", error);
	}
}
	
public void PruneDatabase()
{
	if(g_hDB == null)
	{
		LogError("[DU-PruneDatabaseStart] Prune Database cannot connect to database.");
		return;
	}
	if(g_cPruneDays.IntValue <= 0)
	{
		return;
	}

	int maxlastaccuse = GetTime() - (g_cPruneDays.IntValue * 86400);

	char buffer[1024];

	if(g_bIsMySQl)
		g_hDB.Format(buffer, sizeof(buffer), "DELETE FROM `%s` WHERE `last_accountuse`<'%d' AND `last_accountuse`>'0' AND `member` = 0;", g_sTableName, maxlastaccuse);
	else
		g_hDB.Format(buffer, sizeof(buffer), "DELETE FROM %s WHERE last_accountuse<'%d' AND last_accountuse>'0' AND member = 0;", g_sTableName, maxlastaccuse);

	g_hDB.Query(SQLQuery_PruneDatabase, buffer);
}

public int SQLQuery_PruneDatabase(Database db, DBResultSet results, const char[] error, any userid)
{
	if(db == null)
	{
		LogError("[DU-PruneDatabase] Query failure: %s", error);
	}
}

public int SQLQuery_GetUserData(Database db, DBResultSet results, const char[] error, any userid)
{
	int client;
	
	/* Make sure the client didn't disconnect while the thread was running */
	
	if((client = GetClientOfUserId(userid)) == 0)
	{
		return;
	}
	
	if(db == null)
	{
		LogError("[DU-GetUserData] Query failure: %s", error);
		return;
	}
	if(results.RowCount == 0) 
	{
		char szSteamId[32];
		char Query[256];
		GetClientAuthId(client, AuthId_Steam2, szSteamId, sizeof(szSteamId));
		if(g_bIsMySQl)
		{
			g_hDB.Format(Query, sizeof(Query), "INSERT INTO `%s`(ID, userid, steamid, member, last_accountuse) VALUES(NULL, '%s', '%s', '0', '0');", g_sTableName, NULL_STRING, szSteamId);
		}
		else
		{
			g_hDB.Format(Query, sizeof(Query), "INSERT INTO %s(userid, steamid, member, last_accountuse) VALUES('%s', '%s', '0', '0');", g_sTableName, NULL_STRING, szSteamId);
		}
		g_hDB.Query(SQLQuery_InsertNewPlayer, Query);
		OnClientPreAdminCheck(client);
		return;
	}
	while(results.FetchRow())
	{
		results.FetchString(0, g_sUserID[client], sizeof(g_sUserID));
		g_bMember[client] = !!results.FetchInt(1);
	}
	/*
	if(g_bMember[client])
	{
		if(strlen(g_sRoleID) > 5)
		{
			ManagingRole(g_sUserID[client], g_sRoleID, k_EHTTPMethodPUT);
		}
	}
	*/
	char steamid[32];
	GetClientAuthId(client, AuthId_SteamID64, steamid, sizeof(steamid));
	int uniqueNum = GetRandomInt(100000, 999999);
	Format(g_sUniqueCode[client], sizeof(g_sUniqueCode), "%i-%i-%s", g_cServerID.IntValue, uniqueNum, steamid);
	g_bChecked[client] = true;
	Call_StartForward(g_hOnClientLoaded);
	Call_PushCell(client);
	Call_Finish();
}

public int SQLQuery_InsertNewPlayer(Database db, DBResultSet results, const char[] error, any userid)
{
	if(db == null)
	{
		LogError("[DU-InsertNewPlayer] Query failure: %s", error);
	}
}

public int SQLQuery_CheckUserData(Database db, DBResultSet results, const char[] error, DataPack pack)
{
	if(db == null)
	{
		LogError("[DU-CheckUserData] Query failure: %s", error);
		return;
	}
	char szUserIdDB[20];
	while (results.FetchRow())
	{
		results.FetchString(0, szUserIdDB, sizeof(szUserIdDB));
	}
	char szUserId[20], szUserName[32], szDiscriminator[6];
	pack.Reset();
	int client = pack.ReadCell();
	pack.ReadString(szUserId, sizeof(szUserId));
	pack.ReadString(szUserName, sizeof(szUserName));
	pack.ReadString(szDiscriminator, sizeof(szDiscriminator));
	delete pack;

	char szReply[512];
	if(!StrEqual(szUserIdDB, szUserId))
	{
		if(strlen(g_sRoleID) > 5)
		{
			ManagingRole(szUserId, g_sRoleID, k_EHTTPMethodPUT);
		}
		
		CPrintToChat(client, "%s %T", g_sServerPrefix, "DiscordVerified", client, szUserName, szDiscriminator);
		g_bMember[client] = true;

		Format(g_sUserID[client], sizeof(g_sUserID), szUserId);
		Format(szReply, sizeof(szReply), "%T", "DiscordLinked", LANG_SERVER, szUserId);
		Bot.SendMessageToChannelID(g_sVerificationChannelID, szReply);

		char szSteamId[20];
		GetClientAuthId(client, AuthId_Steam2, szSteamId, sizeof(szSteamId));

		char Query[512];
		if(g_bIsMySQl)
		{
			g_hDB.Format(Query, sizeof(Query), "UPDATE `%s` SET `userid` = '%s', member = 1 WHERE `steamid` = '%s';", g_sTableName, szUserId, szSteamId);
		}
		else
		{
			g_hDB.Format(Query, sizeof(Query), "UPDATE %s SET userid = '%s', member = 1 WHERE steamid = '%s'", g_sTableName, szUserId, szSteamId);
		}
		g_hDB.Query(SQLQuery_LinkedAccount, Query);

		Call_StartForward(g_hOnLinkedAccount);
		Call_PushCell(client);
		Call_PushString(szUserId);
		Call_PushString(szUserName);
		Call_PushString(szDiscriminator);
		Call_Finish();
	}
	else
	{
		Format(szReply, sizeof(szReply), "%T", "DiscordAlreadyLinked", LANG_SERVER, szUserId);
		Bot.SendMessageToChannelID(g_sVerificationChannelID, szReply);
	}
}

public int SQLQuery_LinkedAccount(Database db, DBResultSet results, const char[] error, any userid)
{
	if(db == null)
	{
		LogError("[DU-LinkedAccount] Query failure: %s", error);
	}
}

public int SQLQuery_UpdatePlayer(Database db, DBResultSet results, const char[] error, any userid)
{
	if(db == null)
	{
		LogError("[DU-UpdatePlayer] Query failure: %s", error);
	}
}

public int SQLQuery_DeleteAccount(Database db, DBResultSet results, const char[] error, DataPack pack)
{
	if(db == null)
	{
		pack.Reset();
		delete pack;
		LogError("[DU-DeleteAccount] Query failure: %s", error);
		return;
	}
	pack.Reset();
	int userid = pack.ReadCell();
	int userid2 = pack.ReadCell();
	delete pack;
	int client, target;
	if((target = GetClientOfUserId(userid2)) > 0)
	{
		g_bMember[target] = false;
		g_sUserID[target][0] = '\0';
	}
	if((client = GetClientOfUserId(userid)) == 0)
	{
		return;
	}
	CPrintToChat(client, "%s Successfully deleted account from database.", g_sServerPrefix);
}
