#if defined _bugreport_included
	#endinput
#endif
#define _bugreport_included


#define REASON_MAX_LENGTH 128

#define COOLDOWN 300  //in seconds (default: 300[5 minutes])

/**
 * Called after a client (or module) has reported a bug for a map.
 * Be sure to check that client != 0 if you expect a valid client index.
 *
 * @param client        Client index of the caller.
 * @param map        	DisplayName of map when client reported the bug.
 * @param reason        Reason selected by the client for the report.
 * @param array         Array with reasons that have already been reported in the current map.
 * @noreturn
 */
forward void BugReport_OnReportPost(int client, const char[] map, const char[] reason, ArrayList array);


public SharedPlugin __pl_bugreport = 
{
	name = "bugreport",
	file = "bugreport.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};




#if !defined REQUIRE_PLUGIN
public __pl_bugreport_SetNTVOptional()
{
}
#endif
