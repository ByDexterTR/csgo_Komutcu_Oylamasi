#include <sourcemod>
#include <basecomm>
#include <sdktools>
#include <cstrike>
#include <warden>

int KomSayisi = 0, Sure = -1;
bool Komal[65] = { false, ... }, Kovuldu[65] = { false, ... };
bool Oylama = false;

ConVar ConVar_KomSayiSinir = null, ConVar_KomAlimSure = null, ConVar_KomOylamaSure = null, ConVar_CikanGiremesin = null;

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = 
{
	name = "Komutçu Oylaması", 
	author = "ByDexter", 
	description = "", 
	version = "1.1", 
	url = "https://steamcommunity.com/id/ByDexterTR - ByDexter#5494"
};

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	RegConsoleCmd("sm_komaday", Command_Komaday, "sm_komaday");
	RegConsoleCmd("sm_komkatil", Command_Komaday, "sm_komkatil");
	RegConsoleCmd("sm_komadaysil", Command_Komadaysil, "sm_komadaysil");
	RegConsoleCmd("sm_komayril", Command_Komadaysil, "sm_komayril");
	RegAdminCmd("sm_komal", Command_Komal, ADMFLAG_BAN, "sm_komal");
	RegAdminCmd("sm_komoyla", Command_Komal, ADMFLAG_BAN, "sm_komoyla");
	
	RegAdminCmd("sm_komsil", Command_Komsil, ADMFLAG_BAN, "sm_komsil <Hedef>");
	RegAdminCmd("sm_komiptal", Command_Komoylaiptal, ADMFLAG_BAN, "sm_komiptal");
	RegAdminCmd("sm_komal0", Command_Komoylaiptal, ADMFLAG_BAN, "sm_komal0");
	
	ConVar_KomSayiSinir = CreateConVar("sm_komutcu-oylamasi_katilimci_sayi", "6", "En Fazla kaç kişi katılsın ?", 0, true, 1.0, true, 6.0);
	ConVar_KomAlimSure = CreateConVar("sm_komutcu-oylamasi_alim_sure", "35", "Kaç saniye boyunca oylamaya katılabilsinler ?", 0, true, 15.0, true, 60.0);
	ConVar_KomOylamaSure = CreateConVar("sm_komutcu-oylamasi_oylama_sure", "20", "Kaç saniye olsun oylama", 0, true, 15.0, true, 60.0);
	ConVar_CikanGiremesin = CreateConVar("sm_komutcu-oylamasi_cikan", "0", "Çıkan tekrar katılabilsin mi ? [ 0 = Hayır | 1 = Evet ]", 0, true, 0.0, true, 1.0);
	AutoExecConfig(true, "Komal", "ByDexter");
}

public Action Command_Komsil(int client, int args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "[SM] \x01Kullanım: sm_komsil <Hedef>");
		return Plugin_Handled;
	}
	char arg1[128];
	GetCmdArg(1, arg1, sizeof(arg1));
	int target = FindTarget(client, arg1, true, true);
	if (target == -1)
	{
		return Plugin_Handled;
	}
	if (!Komal[target])
	{
		ReplyToCommand(client, "[SM] \x01Bu hedef Komutçu Oylamasına katılmamış.");
		return Plugin_Handled;
	}
	if (!ConVar_CikanGiremesin.BoolValue)
	{
		Kovuldu[target] = true;
	}
	PrintToChat(target, "[SM] \x01Oylamadan atıldın.");
	Kovuldu[target] = true;
	Komal[target] = false;
	BaseComm_SetClientMute(target, true);
	KomSayisi--;
	return Plugin_Handled;
}

public Action Command_Komaday(int client, int args)
{
	if (!Oylama)
	{
		ReplyToCommand(client, "[SM] \x01Komutçu Oylaması başlatılmamış.");
		return Plugin_Handled;
	}
	if (Komal[client])
	{
		ReplyToCommand(client, "[SM] \x01Zaten Komutçu Oylamasına katılmışsın.");
		return Plugin_Handled;
	}
	if (KomSayisi >= ConVar_KomSayiSinir.IntValue)
	{
		ReplyToCommand(client, "[SM] \x01Komutçu Oylama katılımcı limiti dolmuş.");
		return Plugin_Handled;
	}
	if (Sure == -1)
	{
		ReplyToCommand(client, "[SM] \x01Komutçu Oylaması başlamış.");
		return Plugin_Handled;
	}
	if (Kovuldu[client])
	{
		ReplyToCommand(client, "[SM] \x01Komutçu Oylamasından Kovulduğun/Çıktığın için tekrar katılamazsın.");
		return Plugin_Handled;
	}
	ReplyToCommand(client, "[SM] \x01Komutçu Oylamasına katıldın.");
	Komal[client] = true;
	BaseComm_SetClientMute(client, false);
	KomSayisi++;
	return Plugin_Handled;
}

public Action Command_Komadaysil(int client, int args)
{
	if (!Oylama)
	{
		ReplyToCommand(client, "[SM] \x01Komutçu Oylaması başlatılmamış.");
		return Plugin_Handled;
	}
	if (!Komal[client])
	{
		ReplyToCommand(client, "[SM] \x01Zaten Oylamaya katılmamışsın.");
		return Plugin_Handled;
	}
	if (!ConVar_CikanGiremesin.BoolValue)
	{
		Kovuldu[client] = true;
	}
	ReplyToCommand(client, "[SM] \x01Komutçu Oylamasından ayrıldın.");
	Komal[client] = false;
	BaseComm_SetClientMute(client, true);
	KomSayisi--;
	return Plugin_Handled;
}

public Action Command_Komal(int client, int args)
{
	if (Oylama)
	{
		ReplyToCommand(client, "[SM] \x01Komutçu Oylaması zaten başlatılmış.");
		return Plugin_Handled;
	}
	for (int i = 1; i <= MaxClients; i++)if (IsValidClient(i))
	{
		Kovuldu[i] = false;
		Komal[i] = false;
	}
	Oylama = true;
	KomSayisi = 0;
	Sure = ConVar_KomAlimSure.IntValue;
	CreateTimer(1.0, MenuKontrolEt, _, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
	return Plugin_Handled;
}

public Action Command_Komoylaiptal(int client, int args)
{
	for (int i = 1; i <= MaxClients; i++)if (IsValidClient(i))
	{
		if (Komal[i])
			BaseComm_SetClientMute(i, true);
		
		Kovuldu[i] = false;
		Komal[i] = false;
	}
	Oylama = false;
	Sure = -1;
	KomSayisi = 0;
	ReplyToCommand(client, "[SM] \x01Komutçu Oylamasını iptal ettin.");
	PrintToChatAll("[SM] \x01\x10%N \x01tarafından Komutçu Oylaması iptal edildi.", client);
	return Plugin_Handled;
}

public Action MenuKontrolEt(Handle timer, any data)
{
	if (Oylama)
	{
		if (Sure > 0)
		{
			Sure--;
			Panel panel = new Panel();
			char format[192];
			Format(format, 192, "★ Komutçu Oylaması <%d/%d> (%d Saniye kaldı başlamasına) ★", KomSayisi, ConVar_KomSayiSinir.IntValue, Sure);
			panel.SetTitle(format);
			panel.DrawText("➜ Aday olmak için: !komaday");
			panel.DrawText("➜ Adaylıktan çıkmak için: !komadaysil");
			panel.DrawText("➜ Adaylıktan kovmak için: !komsil <Hedef>");
			panel.DrawText("➜ Oylamayı iptal etmek için: !komiptal");
			panel.DrawText(" ");
			panel.DrawText("➜ Adaylar:");
			if (KomSayisi == 0)
			{
				panel.DrawItem("Kimse Katılmadı!", ITEMDRAW_DISABLED);
			}
			else
			{
				for (int i = 1; i <= MaxClients; i++)if (IsValidClient(i) && Komal[i])
				{
					GetClientName(i, format, 192);
					FixText(format, 192);
					Format(format, 192, "%s - (#%d)", format, GetClientUserId(i));
					panel.DrawItem(format, ITEMDRAW_DISABLED);
				}
			}
			for (int i = 1; i <= MaxClients; i++)if (IsValidClient(i))
			{
				panel.Send(i, Panel_CallBack, 1);
				delete panel;
			}
		}
		else
		{
			for (int i = 1; i <= MaxClients; i++)if (IsValidClient(i) && Kovuldu[i])
			{
				Kovuldu[i] = false;
			}
			Sure = -1;
			if (KomSayisi <= 0)
			{
				Oylama = false;
				KomSayisi = 0;
				PrintToChatAll("[SM] \x01Komutçu oylamasına kimse katılmadı.");
			}
			else if (KomSayisi == 1)
			{
				Oylama = false;
				KomSayisi = 0;
				if (warden_exist())
				{
					for (int i = 1; i <= MaxClients; i++)if (IsValidClient(i) && warden_iswarden(i))
					{
						FakeClientCommand(i, "sm_uw");
						ChangeClientTeam(i, CS_TEAM_T);
						CS_RespawnPlayer(i);
					}
				}
				for (int i = 1; i <= MaxClients; i++)if (IsValidClient(i) && Komal[i])
				{
					if (IsPlayerAlive(i))
					{
						int wepIdx;
						for (int xz; xz < 12; xz++)
						{
							while ((wepIdx = GetPlayerWeaponSlot(i, xz)) != -1)
							{
								RemovePlayerItem(i, wepIdx);
								RemoveEntity(wepIdx);
							}
						}
						ForcePlayerSuicide(i);
					}
					Komal[i] = false;
					ChangeClientTeam(i, CS_TEAM_CT);
					CS_RespawnPlayer(i);
					SetEntProp(i, Prop_Data, "m_takedamage", 0, 1);
					FakeClientCommand(i, "sm_w");
					PrintToChatAll("[SM] \x01Komutçu Oylamasını \x10%N \x01Kazandı.", i);
					PrintToChatAll("[SM] %N: God verildi", i);
				}
			}
			else
			{
				if (IsVoteInProgress())
				{
					CancelVote();
				}
				Menu menu2 = new Menu(VoteMenu_CallBack);
				menu2.SetTitle("★ Kim Komutçu Olsun ? ★\n ");
				int userid;
				char ClientName[128], ClientUserId[16];
				for (int i = 1; i <= MaxClients; i++)if (IsValidClient(i) && Komal[i])
				{
					userid = GetClientUserId(i);
					FormatEx(ClientUserId, sizeof(ClientUserId), "%d", userid);
					GetClientName(i, ClientName, sizeof(ClientName));
					Format(ClientName, sizeof(ClientName), "➜ %s", ClientName);
					menu2.AddItem(ClientUserId, ClientName);
				}
				menu2.ExitBackButton = false;
				menu2.ExitButton = false;
				menu2.DisplayVoteToAll(ConVar_KomOylamaSure.IntValue);
			}
			return Plugin_Stop;
		}
	}
	else
	{
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public int Panel_CallBack(Menu panel, MenuAction action, int client, int position)
{
}

public int VoteMenu_CallBack(Menu menu2, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		delete menu2;
	}
	else if (action == MenuAction_VoteEnd)
	{
		for (int i = 1; i <= MaxClients; i++)if (IsValidClient(i))
		{
			Komal[i] = false;
		}
		Sure = -1;
		Oylama = false;
		KomSayisi = 0;
		char Buneamk[128];
		menu2.GetItem(param1, Buneamk, sizeof(Buneamk));
		int client = GetClientOfUserId(StringToInt(Buneamk));
		if (warden_exist())
		{
			for (int i = 1; i <= MaxClients; i++)if (IsValidClient(i) && warden_iswarden(i))
			{
				FakeClientCommand(i, "sm_uw");
				ChangeClientTeam(i, CS_TEAM_T);
				CS_RespawnPlayer(i);
			}
		}
		if (IsPlayerAlive(client))
		{
			int wepIdx;
			for (int i; i < 12; i++)
			{
				while ((wepIdx = GetPlayerWeaponSlot(client, i)) != -1)
				{
					RemovePlayerItem(client, wepIdx);
					RemoveEntity(wepIdx);
				}
			}
			ForcePlayerSuicide(client);
		}
		ChangeClientTeam(client, CS_TEAM_CT);
		CS_RespawnPlayer(client);
		SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
		FakeClientCommand(client, "sm_w");
		char Names[128];
		GetClientName(client, Names, sizeof(Names));
		PrintToChatAll("[SM] \x01Komutçu Oylamasını \x10%s \x01Kazandı.", Names);
		PrintToChatAll("[SM] %s: God verildi", Names);
	}
}

bool IsValidClient(int client, bool nobots = true)
{
	if (client <= 0 || client > MaxClients || !IsClientConnected(client) || (nobots && IsFakeClient(client)))
	{
		return false;
	}
	return IsClientInGame(client);
}

bool FixText(char[] Fix, int size)
{
	if (size <= 0)
	{
		return false;
	}
	ReplaceString(Fix, size, "/", "", false);
	ReplaceString(Fix, size, "`", "", false);
	ReplaceString(Fix, size, "*", "", false);
	ReplaceString(Fix, size, "[", "", false);
	ReplaceString(Fix, size, "]", "", false);
	ReplaceString(Fix, size, "(", "", false);
	ReplaceString(Fix, size, ")", "", false);
	ReplaceString(Fix, size, "|", "", false);
	ReplaceString(Fix, size, "_", "", false);
	ReplaceString(Fix, size, "\"", "'", false);
	ReplaceString(Fix, size, "\\", "", false);
	ReplaceString(Fix, size, "~", "", false);
	return true;
}