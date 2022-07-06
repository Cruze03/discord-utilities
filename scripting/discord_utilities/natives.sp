public int Native_IsChecked(Handle plugin, int numparams)
{
	return g_bChecked[GetNativeCell(1)];
}

public int Native_IsDiscordMember(Handle plugin, int numparams)
{
	if(!g_bChecked[GetNativeCell(1)])
	{
		return ThrowNativeError(25, "[Discord-Utilities] %N hasn't been checked. Call this in OnClientPostAdminCheck.", GetNativeCell(1));
	}
	return g_bMember[GetNativeCell(1)];
}

public int Native_GetUserId(Handle plugin, int numparams)
{
	if(!g_bChecked[GetNativeCell(1)])
	{
		return ThrowNativeError(25, "[Discord-Utilities] %N hasn't been checked. Call this in OnClientPostAdminCheck.", GetNativeCell(1));
	}
	if(!g_bMember[GetNativeCell(1)])
	{
		return ThrowNativeError(25, "[Discord-Utilities] %N isn't verified.", GetNativeCell(1));
	}

	SetNativeString(2, g_sUserID[GetNativeCell(1)], GetNativeCell(3));
	return 0;
}

public int Native_GetUserIdBySteamId(Handle plugin, int numparams)
{
	char szSteamId[32];
	GetNativeString(1, szSteamId, sizeof(szSteamId));

	if(StrEqual(szSteamId, "") || StrContains(szSteamId, "STEAM_1") == -1)
	{
		return ThrowNativeError(25, "[Discord-Utilities] Native_GetUserIdBySteamId Invalid steam id: %s.", szSteamId);
	}

	any data = GetNativeCell(3);

	DataPack dPack = new DataPack();
	dPack.WriteCell(plugin);
	dPack.WriteFunction(GetNativeFunction(2));
	dPack.WriteString(szSteamId);
	dPack.WriteCell(data);

	char Query[512];
	g_hDB.Format(Query, sizeof(Query), "SELECT userid FROM %s WHERE steamid = '%s' and member = 1", g_sTableName, szSteamId);
	g_hDB.Query(SQLQuery_CheckUserDataNative, Query, dPack);
	return 0;
}

public void SQLQuery_CheckUserDataNative(Database db, DBResultSet results, const char[] error, DataPack dPack)
{
	if(db == null)
	{
		LogError("[DU-SQLQuery_CheckUserDataNative] Query failure: %s", error);
		return;
	}

	char szUserIdDB[20], szSteamId[32];
	while (results.FetchRow())
	{
		results.FetchString(0, szUserIdDB, sizeof(szUserIdDB));
	}

	dPack.Reset();
	Handle plugin = dPack.ReadCell();
	Function callback = dPack.ReadFunction();
	dPack.ReadString(szSteamId, sizeof(szSteamId));
	any data = dPack.ReadCell();
	delete dPack;

	Call_StartFunction(plugin, callback);
	Call_PushString(szSteamId);
	Call_PushString(szUserIdDB);
	Call_PushCell(data);
	Call_Finish();
}

public int Native_RefreshClients(Handle plugin, int numparams)
{
	if(!g_bChecked[GetNativeCell(1)])
	{
		return ThrowNativeError(25, "[Discord-Utilities] %N hasn't been checked. Call this in OnClientPostAdminCheck.", GetNativeCell(1));
	}
	RefreshClients();
	return 0;
}

public int Native_GetIP(Handle plugin, int numparams)
{
	SetNativeString(1, g_sServerIP, GetNativeCell(2));
	return 0;
}

public int Native_CheckRole(Handle plugin, int numparams)
{
	if(!g_bChecked[GetNativeCell(1)])
	{
		return ThrowNativeError(25, "[Discord-Utilities] %N hasn't been checked. Call this in OnClientPostAdminCheck.", GetNativeCell(1));
	}
	if(!g_bMember[GetNativeCell(1)])
	{
		return ThrowNativeError(25, "[Discord-Utilities] %N isn't verified.", GetNativeCell(1));
	}
	if(g_sUserID[GetNativeCell(1)][0] == '\0')
	{
		return ThrowNativeError(25, "[Discord-Utilities] %N's userid doesn't exist in database.", GetNativeCell(1));
	}
	int client = GetNativeCell(1);
	char roleid[128];
	GetNativeString(2, roleid, sizeof(roleid));

	any data = GetNativeCell(4);

	DataPack dPack = new DataPack();
	dPack.WriteCell(plugin);
	dPack.WriteFunction(GetNativeFunction(3));
	dPack.WriteCell(GetClientUserId(client));
	dPack.WriteCell(data);

	CheckingRole(g_sUserID[client], roleid, k_EHTTPMethodGET, dPack);
	return 0;
}

public int Native_AddRole(Handle plugin, int numparams)
{
	if(!g_bChecked[GetNativeCell(1)])
	{
		return ThrowNativeError(25, "[Discord-Utilities] %N hasn't been checked. Call this in OnClientPostAdminCheck.", GetNativeCell(1));
	}
	if(!g_bMember[GetNativeCell(1)])
	{
		return ThrowNativeError(25, "[Discord-Utilities] %N isn't verified.", GetNativeCell(1));
	}
	if(g_sUserID[GetNativeCell(1)][0] == '\0')
	{
		return ThrowNativeError(25, "[Discord-Utilities] %N's userid doesn't exist in database.", GetNativeCell(1));
	}
	int client = GetNativeCell(1);
	char roleid[128];
	GetNativeString(2, roleid, sizeof(roleid));
	ManagingRole(g_sUserID[client], roleid, k_EHTTPMethodPUT);
	return 0;
}

public int Native_DeleteRole(Handle plugin, int numparams)
{
	if(!g_bChecked[GetNativeCell(1)])
	{
		return ThrowNativeError(25, "[Discord-Utilities] %N hasn't been checked. Call this in OnClientPostAdminCheck.", GetNativeCell(1));
	}
	if(!g_bMember[GetNativeCell(1)])
	{
		return ThrowNativeError(25, "[Discord-Utilities] %N isn't verified.", GetNativeCell(1));
	}
	if(g_sUserID[GetNativeCell(1)][0] == '\0')
	{
		return ThrowNativeError(25, "[Discord-Utilities] %N's userid doesn't exist in database.", GetNativeCell(1));
	}
	int client = GetNativeCell(1);
	char roleid[128];
	GetNativeString(2, roleid, sizeof(roleid));
	ManagingRole(g_sUserID[client], roleid, k_EHTTPMethodDELETE);
	return 0;
}
