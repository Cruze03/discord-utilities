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