methodmap DiscordRequest < Handle
{
	public DiscordRequest(char[] url, EHTTPMethod method)
	{
		Handle request = SteamWorks_CreateHTTPRequest(method, url);
		return view_as<DiscordRequest>(request);
	}
	
	public void SetJsonBody(Handle hJson)
	{
		static char stringJson[16384];
		stringJson[0] = '\0';
		if(hJson != null)
		{
			json_dump(hJson, stringJson, sizeof(stringJson), 0, true);
		}
		SteamWorks_SetHTTPRequestRawPostBody(this, "application/json; charset=UTF-8", stringJson, strlen(stringJson));
		if(hJson != null) delete hJson;
	}
	
	public void SetJsonBodyEx(Handle hJson)
	{
		static char stringJson[16384];
		stringJson[0] = '\0';
		if(hJson != null)
		{
			json_dump(hJson, stringJson, sizeof(stringJson), 0, true);
		}
		SteamWorks_SetHTTPRequestRawPostBody(this, "application/json; charset=UTF-8", stringJson, strlen(stringJson));
	}
	
	property int Timeout
	{
		public set(int timeout)
		{
			SteamWorks_SetHTTPRequestNetworkActivityTimeout(this, timeout);
		}
	}
	
	public void SetCallbacks(SteamWorksHTTPRequestCompleted OnComplete, SteamWorksHTTPDataReceived DataReceived)
	{
		SteamWorks_SetHTTPCallbacks(this, OnComplete, HeadersReceived, DataReceived);
	}
	
	public void SetContentSize()
	{
		SteamWorks_SetHTTPRequestHeaderValue(this, "Content-Length", "0");
	}
	
	public void SetContextValue(any data1, any data2)
	{
		SteamWorks_SetHTTPRequestContextValue(this, data1, data2);
	}
	
	public void SetData(any data1, char[] route)
	{
		SteamWorks_SetHTTPRequestContextValue(this, data1, UrlToDP(route));
	}
	
	public void SetBot(DiscordBot bawt)
	{
		BuildAuthHeader(this, bawt);
	}
	
	public void Send(char[] route)
	{
		DiscordSendRequest(this, route);
	}
}

public int HeadersReceived(Handle request, bool failure, any data, any datapack)
{
	DataPack dp = view_as<DataPack>(datapack);
	if(failure)
	{
		delete dp;
		return;
	}
	
	char xRateLimit[16];
	char xRateLeft[16];
	char xRateReset[32];
	
	bool exists = false;
	
	exists = SteamWorks_GetHTTPResponseHeaderValue(request, "X-RateLimit-Limit", xRateLimit, sizeof(xRateLimit));
	exists = SteamWorks_GetHTTPResponseHeaderValue(request, "X-RateLimit-Remaining", xRateLeft, sizeof(xRateLeft));
	exists = SteamWorks_GetHTTPResponseHeaderValue(request, "X-RateLimit-Reset", xRateReset, sizeof(xRateReset));
	
	//Get url
	char route[128];
	ResetPack(dp);
	ReadPackString(dp, route, sizeof(route));
	delete dp;
	
	int reset = StringToInt(xRateReset);
	if(reset > GetTime() + 3)
	{
		reset = GetTime() + 3;
	}
	
	if(exists)
	{
		SetTrieValue(hRateReset, route, reset);
		SetTrieValue(hRateLeft, route, StringToInt(xRateLeft));
		SetTrieValue(hRateLimit, route, StringToInt(xRateLimit));
	}
	else
	{
		SetTrieValue(hRateReset, route, -1);
		SetTrieValue(hRateLeft, route, -1);
		SetTrieValue(hRateLimit, route, -1);
	}
}

public Handle UrlToDP(char[] url)
{
	DataPack dp = new DataPack();
	WritePackString(dp, url);
	return dp;
}

stock void BuildAuthHeader(Handle request, DiscordBot bawt)
{
	static char buffer[256];
	static char token[196];
	JsonObjectGetString(bawt, "token", token, sizeof(token));
	FormatEx(buffer, sizeof(buffer), "Bot %s", token);
	SteamWorks_SetHTTPRequestHeaderValue(request, "Authorization", buffer);
}

public void DiscordSendRequest(Handle request, const char[] route)
{
	//Check for reset
	int time = GetTime();
	int resetTime;
	
	int defLimit = 0;
	if(!GetTrieValue(hRateLimit, route, defLimit))
	{
		defLimit = 1;
	}
	
	bool exists = GetTrieValue(hRateReset, route, resetTime);
	
	if(!exists)
	{
		SetTrieValue(hRateReset, route, GetTime() + 5);
		SetTrieValue(hRateLeft, route, defLimit - 1);
		SteamWorks_SendHTTPRequest(request);
		return;
	}
	
	if(time == -1)
	{
		//No x-rate-limit send
		SteamWorks_SendHTTPRequest(request);
		return;
	}
	
	if(time > resetTime)
	{
		SetTrieValue(hRateLeft, route, defLimit - 1);
		SteamWorks_SendHTTPRequest(request);
		return;
	}
	else
	{
		int left;
		GetTrieValue(hRateLeft, route, left);
		if(left == 0)
		{
			float remaining = float(resetTime) - float(time) + 1.0;
			Handle dp = new DataPack();
			WritePackCell(dp, request);
			WritePackString(dp, route);
			CreateTimer(remaining, SendRequestAgain, dp);
		}
		else
		{
			left--;
			SetTrieValue(hRateLeft, route, left);
			SteamWorks_SendHTTPRequest(request);
		}
	}
}