#define PLUGIN_VERSION "2.9.4-BETA"

#define PLUGIN_NAME "Discord Utilities"
#define PLUGIN_AUTHOR "Cruze"
#define PLUGIN_DESC "Utilities that can be used to integrate gameserver to discord server I guess?"
#define PLUGIN_URL "https://github.com/Cruze03/discord-utilities | http://www.steamcommunity.com/profiles/76561198132924835"

#define DEFAULT_COLOR "#00FF00"

#define MAX_BLOCKLIST_LIMIT 20
#define MAX_ARGUMENTS 15

#define USE_AutoExecConfig

ConVar g_cCallAdmin_Webhook, g_cCallAdmin_BotName, g_cCallAdmin_BotAvatar, g_cCallAdmin_Color, g_cCallAdmin_Content, g_cCallAdmin_FooterIcon;
ConVar g_cBugReport_Webhook, g_cBugReport_BotName, g_cBugReport_BotAvatar, g_cBugReport_Color, g_cBugReport_Content, g_cBugReport_FooterIcon;
ConVar g_cSourceBans_Webhook, g_cSourceBans_BotName, g_cSourceBans_BotAvatar, g_cSourceBans_Color, g_cSourceBans_PermaColor, g_cSourceBans_Content, g_cSourceBans_FooterIcon;
ConVar g_cSourceComms_Webhook, g_cSourceComms_BotName, g_cSourceComms_BotAvatar, g_cSourceComms_Color, g_cSourceComms_PermaColor, g_cSourceComms_Content, g_cSourceComms_FooterIcon;
ConVar g_cMap_Webhook, g_cMap_BotName, g_cMap_Color, g_cMap_BotAvatar, g_cMap_Content, g_cMap_Delay, g_cMap_Thumbnail;
ConVar g_cChatRelay_Webhook, g_cChatRelay_BlockList, g_cAdminChatRelay_Mode, g_cAdminChatRelay_Webhook, g_cAdminChatRelay_BlockList, g_cAdminLog_Webhook, g_cAdminLog_BlockList;
ConVar g_cVerificationChannelID, g_cChatRelayChannelID, g_cAdminChatRelayChannelID, g_cAdminCommandChannelID, g_cGuildID, g_cRoleID;
ConVar g_cAPIKey, g_cBotToken, g_cDNSServerIP, g_cCheckInterval, g_cUseSWGM, g_cTimeStamps, g_cServerID;
ConVar g_cLinkCommand, g_cViewIDCommand, g_cInviteLink;
ConVar g_cDiscordPrefix, g_cServerPrefix;
ConVar g_cDatabaseName, g_cTableName, g_cPruneDays;
ConVar g_cPrimaryServer;

char g_sCallAdmin_Webhook[128], g_sCallAdmin_BotName[32], g_sCallAdmin_BotAvatar[128], g_sCallAdmin_Color[8], g_sCallAdmin_Content[256], g_sCallAdmin_FooterIcon[128];
char g_sBugReport_Webhook[128], g_sBugReport_BotName[32], g_sBugReport_BotAvatar[128], g_sBugReport_Color[8], g_sBugReport_Content[256], g_sBugReport_FooterIcon[128];
char g_sSourceBans_Webhook[128], g_sSourceBans_BotName[32], g_sSourceBans_BotAvatar[128], g_sSourceBans_Color[8], g_sSourceBans_PermaColor[8], g_sSourceBans_Content[256], g_sSourceBans_FooterIcon[128];
char g_sSourceComms_Webhook[128], g_sSourceComms_BotName[32], g_sSourceComms_BotAvatar[128], g_sSourceComms_Color[8], g_sSourceComms_PermaColor[8], g_sSourceComms_Content[256], g_sSourceComms_FooterIcon[128];
char g_sMap_Webhook[128], g_sMap_BotName[32], g_sMap_BotAvatar[128], g_sMap_Color[8], g_sMap_Content[256];
char g_sChatRelay_Webhook[128], g_sChatRelay_BlockList[MAX_BLOCKLIST_LIMIT][64], g_sAdminChatRelay_Mode[16], g_sAdminChatRelay_Webhook[128], g_sAdminChatRelay_BlockList[MAX_BLOCKLIST_LIMIT][64], g_sAdminLog_Webhook[128], g_sAdminLog_BlockList[MAX_BLOCKLIST_LIMIT][64];
char g_sVerificationChannelID[20], g_sChatRelayChannelID[20], g_sAdminChatRelayChannelID[20], g_sAdminCommandChannelID[20], g_sGuildID[64], g_sRoleID[20];
char g_sAPIKey[128], g_sBotToken[128], g_sServerIP[128];
char g_sLinkCommand[20], g_sViewIDCommand[20], g_sInviteLink[64];
char g_sDiscordPrefix[128], g_sServerPrefix[128];
char g_sTableName[32];

char g_sVerificationChannelName[32];

int g_iLastReportID;

char g_sServerName[128];

ArrayList g_aCallAdmin_ReportedList;

bool g_bCallAdmin, g_bSourceBans, g_bSourceComms, g_bShavit, g_bBugReport, g_bBaseComm, g_bMaterialAdmin;

char g_sLastMapPath[PLATFORM_MAX_PATH];

char g_sAvatarURL[MAXPLAYERS+1][128];
bool g_bChecked[MAXPLAYERS+1];
bool g_bMember[MAXPLAYERS+1];
bool g_bRoleGiven[MAXPLAYERS+1];
char g_sUserID[MAXPLAYERS+1][20];
char g_sUniqueCode[MAXPLAYERS+1][36];

Handle g_hOnCheckedAccounts, g_hOnLinkedAccount, g_hOnAccountRevoked, g_hOnClientLoaded, g_hOnBlockedCommandUse;

DiscordBot Bot;

Database g_hDB;

bool g_bIsMySQl;

bool g_bLateLoad = false;

Handle hRateLimit = null;
Handle hRateReset = null;
Handle hRateLeft = null;

Handle hFinalMemberList;
