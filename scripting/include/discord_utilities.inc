#if defined _discord_utilities_included
 #endinput
#endif
#define _discord_utilities_included

typedef FetchedUserIdHandler = function void(const char[] szSteamId, const char[] discordId, bool member, any data);

typedef FetchedRoleIdHandler = function void(int client, bool found, any data);

/**
 * Called after a client's data has been retrieved from database. 
 *
 * @param client        		Client index loaded client.
 * @noreturn
 */
forward void DU_OnClientLoaded(int client);

/**
 * Called after a client has verfied his discord account.
 *
 * @param client        		Client index of the verified client.
 * @param userid        		Discord userid of the client.
 * @param username        		Discord username of the client.
 * @param discriminator         Discord discriminator of the client.
 * @noreturn
 */
forward void DU_OnLinkedAccount(int client, const char[] userid, const char[] username, const char[] discriminator);

/**
 * Called after a client's member status has been revoked.
 *
 * @param client        		Client index.
 * @param userid        		Discord userid of the client.
 * @noreturn
 */
forward void DU_OnAccountRevoked(int client, const char[] userid);

/**
 * Called before checking accounts. return Plugin_Handled to block checking.
 *
 * @param bottoken        		Token of bot which will be checking accounts.
 * @param userid        		Guildid of your discord server.
 * @param tablename        		Table name of database.
 * @noreturn
 */
forward void DU_OnCheckedAccounts(const char[] bottoken, const char[] guildid, const char[] tablename);


/**
 * Called before a blocked command being used by client.
 *
 * @param client        		Player who used command.
 * @param command        		Command used.
 * @return Continue to let him use, Handled to let plugin behave normally, Stop to stop him executing command manually.
 */
forward Action DU_OnBlockedCommandUse(int client, char[] command);

/**
 * Refreshing every client online in server. Can be used for grasping steam avatar of client and re-checking client in database.
 *
 * @noreturn
 */
native void DU_RefreshClients();

/**
 * Discord Database Check
 *
 * @returns true if client was already checked for member status.
 */
native bool DU_IsChecked(int client);

/**
 * Discord Member Check
 *
 * @returns true if client is member of discord server else false.
 */
native bool DU_IsMember(int client);

/**
 * Retrieve client's discord userid.
 * @param client		Client index to get userid from.
 * @param output		String to store userid in.
 * @param maxsize		Max size of string.
 * @Throws native error if Is_Member == false or client userid is not retrieved.
 */
native char DU_GetUserId(int client, char[] output, int maxsize);

/**
 * Retrieve client's discord userid from database.
 * @param szSteamId		Client index to get userid from.
 * @param handler		Function on loaded user id.
 * @Throws native error if szSteamId invalid.
 */
native void DU_GetUserIdBySteamId(const char[] szSteamId, FetchedUserIdHandler handler, any data = 0);

/**
 * Retrieve DNS ip / real ip of server according to sm_du_dns_ip. (If cvar is blank then real ip else DNS ip)
 * @param output		String to store sererip in.
 * @param maxsize		Max size of string.
 * @noreturn
 */
native void DU_GetIP(char[] output, int maxsize);

/**
 * Assigns role to client according to roleid
 * @param client		Client index to give role to.
 * @param roleid		String containing roleid.
 * @param maxsize		Max size of string.
 * @noreturn
 */
native void DU_AddRole(int client, char[] roleid);

/**
 * Deletes role from client according to roleid
 * @param client		Client index to delete role from.
 * @param roleid		String containing roleid.
 * @param maxsize		Max size of string.
 * @noreturn
 */
native void DU_DeleteRole(int client, char[] roleid);

/**
 * Checks role from client according to roleid
 * @param client		Client index to delete role from.
 * @param roleid		String containing roleid.
 * @param maxsize		Max size of string.
 * @noreturn
 */
native void DU_CheckRole(int client, char[] roleid, FetchedRoleIdHandler handler, any data = 0);

public SharedPlugin __pl_discord_utilities =
{
		name = "DiscordUtilities",
		file = "discord_utilities.smx",
	#if defined REQUIRE_PLUGIN
		required = 1,
	#else
		required = 0,
	#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_discord_utilities_SetNTVOptional()
{
	MarkNativeAsOptional("DU_IsChecked");
	MarkNativeAsOptional("DU_IsMember");
	MarkNativeAsOptional("DU_GetUserId");
	MarkNativeAsOptional("DU_RefreshClients");
	MarkNativeAsOptional("DU_GetIP");
	MarkNativeAsOptional("DU_AddRole");
	MarkNativeAsOptional("DU_DeleteRole");
}
#endif 
