#include <sourcemod>
#include <glow>

#define PLUGIN_NEV	"Custom Glows Menu"
#define PLUGIN_LERIAS	"Players can customize their glows"
#define PLUGIN_AUTHOR	"Nexd"
#define PLUGIN_VERSION	"1.0"
#define PLUGIN_URL	"https://github.com/KillStr3aK"
#pragma tabsize 0;
#pragma newdecls required;
#pragma semicolon 1;

#define MAX_GLOW 50

enum struct Glows {
	char Name[32];
	char Flags[20];
	int Color[3];
	int Style;
	float MaxDist;
}

Glows glows[MAX_GLOW];
int g_iGlows;
int g_iEquippedGlow[MAXPLAYERS+1];

char g_szFilePath[PLATFORM_MAX_PATH];

public Plugin myinfo = 
{
	name = PLUGIN_NEV,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_LERIAS,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_glows", Command_Glows);
	BuildPath(Path_SM, g_szFilePath, sizeof(g_szFilePath), "configs/glows.cfg");
	LoadGlows();

	for(int i = 1; i <= MaxClients; i++) OnClientPostAdminCheck(i);
}

public void OnClientPostAdminCheck(int client)
{
	g_iEquippedGlow[client] = -1;
}

public Action Command_Glows(int client, int args)
{
	GlowsMenu(client);
	return Plugin_Handled;
}

public void GlowsMenu(int client)
{
	Menu menu = new Menu(GlowsHandler);
	menu.SetTitle("Glows Menu\n ");
	for(int i = 0; i < g_iGlows; i++) menu.AddItem(IntToStr(i), glows[i].Name, HasPermission(client, glows[i].Flags)?(i==g_iEquippedGlow[client]?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT):ITEMDRAW_DISABLED);
	menu.Display(client, MENU_TIME_FOREVER);
}

public int GlowsHandler(Menu menu, MenuAction action, int client, int selection)
{
	if(action == MenuAction_Select)
	{
		char info[3];
		menu.GetItem(selection, info, sizeof(info));
		g_iEquippedGlow[client] = StringToInt(info);
		EquipGlow(client, glows[g_iEquippedGlow[client]]);
		GlowsMenu(client);
	} else if(action == MenuAction_End) delete menu;
}

public bool EquipGlow(int client, Glows eg)
{
	Glow_SetupEx(client, eg.Color, eg.Style, eg.MaxDist, false);
	PrintToChat(client, "You have equipped the \x04%s \x01Glow!", eg.Name);
}

public void LoadGlows()
{
	g_iGlows = 0;
	KeyValues kv = new KeyValues("Glows");
    kv.ImportFromFile(g_szFilePath);
    
    if (!KvGotoFirstSubKey(kv)) return;

	char szBuffer[12];
	char szTemp[3][4];
    do
	{
        kv.GetString("name", glows[g_iGlows].Name, sizeof(Glows::Name));
		kv.GetString("flags", glows[g_iGlows].Flags, sizeof(Glows::Flags));
		kv.GetString("color", szBuffer, sizeof(szBuffer));
		glows[g_iGlows].Style = kv.GetNum("style");
		glows[g_iGlows].MaxDist = kv.GetFloat("maxdist");

		ExplodeString(szBuffer, " ", szTemp, sizeof(szTemp), sizeof(szTemp[]));
		for(int i = 0; i < 3; i++) { glows[g_iGlows].Color[i] = StringToInt(szTemp[i]); }
        g_iGlows++;
    } while (KvGotoNextKey(kv));
    kv.Close();
}

stock bool HasPermission(int client, const char[] flags)
{
	int iflags = ReadFlagString(flags);
	if(iflags <= 0) return false;
	return CheckCommandAccess(client, "", iflags);
}

stock bool IsValidClient(int client)
{
	if(client <= 0) return false;
	if(client > MaxClients) return false;
	if(!IsClientConnected(client)) return false;
	if(IsFakeClient(client)) return false;
	if(IsClientSourceTV(client)) return false;
	return IsClientInGame(client);
}

stock char IntToStr(int thing)
{
	char itemindex[10];
	IntToString(thing, itemindex, sizeof(itemindex));
	return itemindex;
}