/* 
* Mix Ultimate v1.0 desarrollado por ; Cristian'

* CREDITOS
	- Federico '#8 SickneSS' Fernández
*

* COMANDOS

	- say /.!mix > Abre el menú de mix
	- say /.!rr > (Restart round) Reinicia la ronda sin afectar los resultados, la puntuación, ni el dinero del usuario (Solo en modo mix)
	- say /.!rh > (Reset half) Resetea la mitad que se está jugando
	- say /.!result > Muesta los resultados
	- say /.!chat > Habilita el chat (Administradores) / Pide que habiliten el chat
	- say /.!team > Habilita el cambio de equipos (Administradores) / Pide que habiliten el cambio de equipos
	- say /.!nick > Habilita el cambio de nick (Administradores) / Pide que habiliten el cambio de nick
	- say /.!stats > Muestra en un menú las estadísticas de los mix jugados
	- say /.!select > Muestra en un menú a los usuarios para ser seleccionados por los que cortaron (Modo duelo habilitado)
*
	
* CVARS

	- mix_password "1337" > Establece la contraseña del servidor. Por defecto "1337"
	- mix_prefix "!g[Mix Ultimate]" > Establece el prefijo del mensaje. Por defecto [Mix Ultimate]
	- mix_finish_half "15" > Establece las rondas para que finalicen las mitades. Por defecto 15 rondas
	- mix_show_killer "1" > Muestra, en un hud lateral izquierdo, quién mató a quién. Por defecto 1
	- mix_show_money "1" > Muestra, en un hud lateral izquierdo, el dinero de los usuarios del equipo. Por defecto 1
	- mix_closed_block_say "1" > Establece si se bloqueará el chat en modo cerrado. Por defecto 1
	- mix_closed_block_name "1" > Establece si se bloqueará el cambio de nick en modo cerrado. Por defecto 1
	- mix_result "1" > Muestra los resultados del mix en cada ronda. Por defecto 1
	- mix_result_type "3" > Establece el tipo de mensaje del resultado en cada ronda. Por defecto 3
	
	; mix_result_type "1" > Muestra los resultados del mix en el hud
	; mix_result_type "2" > Muestra los resultados del mix en el chat
	; mix_result_type "3" > Muestra los resultados del mix en el hud y en el chat
	
*
*/

#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <engine>
#include <fun>
#include <fakemeta>
#include <sqlx>

#pragma semicolon 1

#if !defined MIX_TEST_C
	#pragma unused g_mix_cristian
#endif

#define PLUGIN_AUTHOR "; Cristian'"
#define PLUGIN_VERSION "v1.0"

#define SQL_MIX_DATABASE "sql_mix_database"
#define SOUND_MIX_STARTED "mix_ultimate/mix_started.wav"

const PRIVATE_DATA_FRAGS = 445;
const PRIVATE_DATA_DEATHS = 444;
const PRIVATE_DATA_CSMENUCODE = 205;
const PRIVATE_DATA_INTERNAL_MODEL = 126;
const PRIVATE_DATA_MONEY = 115;
const PRIVATE_DATA_TEAM = 114;
const PRIVATE_DATA_LINUX = 5;
const PRIVATE_DATA_SAFE = 2;

const TASK_MIX_ULTIMATE_VALE = 44502;
const TASK_MIX_ULTIMATE_STRUCT = 43502;

/* === ENUMS === */
enum _:ARRAY_MIX_STATS_STRUCT
{
	ARRAY_MIX_ID,
	ARRAY_MIX_MAP[32],
	ARRAY_MIX_SCORE_CT_HF,
	ARRAY_MIX_SCORE_CT_HS,
	ARRAY_MIX_SCORE_CT_TOTAL,
	ARRAY_MIX_SCORE_TT_HF,
	ARRAY_MIX_SCORE_TT_HS,
	ARRAY_MIX_SCORE_TT_TOTAL,
	ARRAY_MIX_SCORE_CT_HF_OVERTIME,
	ARRAY_MIX_SCORE_CT_HS_OVERTIME,
	ARRAY_MIX_SCORE_CT_TOTAL_OVERTIME,
	ARRAY_MIX_SCORE_TT_HF_OVERTIME,
	ARRAY_MIX_SCORE_TT_HS_OVERTIME,
	ARRAY_MIX_SCORE_TT_TOTAL_OVERTIME,
	ARRAY_MIX_ROUNDS,
	ARRAY_MIX_DATE_STARTED[32],
	ARRAY_MIX_DATE_FINISH[32],
	ARRAY_MIX_SYSTIME,
	ARRAY_MIX_USERS_CT[128],
	ARRAY_MIX_USERS_TT[128],
	ARRAY_MIX_FRAGS_CT_HF[48],
	ARRAY_MIX_FRAGS_CT_HS[48],
	ARRAY_MIX_FRAGS_CT_HF_OVERTIME[48],
	ARRAY_MIX_FRAGS_CT_HS_OVERTIME[48],
	ARRAY_MIX_FRAGS_TT_HF[48],
	ARRAY_MIX_FRAGS_TT_HS[48],
	ARRAY_MIX_FRAGS_TT_HF_OVERTIME[48],
	ARRAY_MIX_FRAGS_TT_HS_OVERTIME[48]
};

enum _:ARRAY_USERS_STATS_STRUCT
{
	ARRAY_MIX_ID,
	ARRAY_MIX_ROUND,
	ARRAY_USER_NAME[32],
	ARRAY_USER_IP[16],
	ARRAY_USER_DATE[32],
	ARRAY_USER_MAP[32],
	ARRAY_USER_TEAM[11],
	ARRAY_USER_TKS,
	ARRAY_USER_DISCONNECTED
};

enum CsTeams:MIX_TEAM_STRUCT
{
	MIX_TEAM_UNASSIGNED = CS_TEAM_UNASSIGNED,
	MIX_TEAM_TERRORISTS = CS_TEAM_T,
	MIX_TEAM_CT = CS_TEAM_CT,
	MIX_TEAM_SPECTATORS = CS_TEAM_SPECTATOR
};

enum _:MIX_ULTIMATE_MODES
{
	MIX_MODE_PUBLIC,
	MIX_MODE_PRACTICAL,
	MIX_MODE_CLOSED,
	MIX_MODE_RATES,
	MIX_MODE_VALE,
	MIX_MODE_SPECTATOR,
	MIX_MODE_OPTIONS
};

enum _:MESSAGES_STRUCT
{
	MIX_ULTIMATE_COUNTDOWN,
	MIX_ULTIMATE_NOTICE,
};

enum _:MIX_RESTART
{
	MIX_RESTART_ONE,
	MIX_RESTART_TWO,
	MIX_RESTART_THREE,
	MIX_STARTED,
	MIX_CHOOSER_CUT,
	MIX_HALFS
};

enum _:MIX_HALF_STRUCT
{
	MIX_HALF_FIRST,
	MIX_HALF_SECOND
};

enum _:MIX_CVARS_STRUCT
{
	CVAR_MIX_ENABLE,
	CVAR_MIX_PASSWORD,
	CVAR_MIX_PREFIX,
	CVAR_MIX_FINISH_HALF,
	CVAR_MIX_SHOW_KILLER,
	CVAR_MIX_SHOW_MONEY,
	CVAR_MIX_CLOSED_BLOCK_SAY,
	CVAR_MIX_CLOSED_BLOCK_NAME,
	CVAR_MIX_CLOSED_BLOCK_TEAM,
	CVAR_MIX_RESULT,
	CVAR_MIX_RESULT_TYPE,
	CVAR_MIX_OVERTIME,
	CVAR_MIX_OVERTIME_ROUNDS
};

enum _:MIX_PAGE_STRUCT
{
	MIX_PAGE_CHOOSE_CT,
	MIX_PAGE_CHOOSE_TT,
	MIX_PAGE_CHOOSE_SPEC,
	MIX_PAGE_CHOOSE_CUT,
	MIX_PAGE_RESULTS,
	MIX_PAGE_KICK
};

/* =============== CFG'S =============== */

new const PUBLIC_CFG[][] = 
{
	"amx_on", "mp_autokick 0", "mp_autocrosshair 0", "mp_autoteambalance 1", "mp_buytime .25","mp_consistency 1","mp_c4timer 35","mp_fadetoblack 0",
	"mp_flashlight 1","mp_forcechasecam 0","mp_forcecamera 0","mp_footsteps 1","mp_freezetime 3","mp_friendlyfire 0","mp_hostagepenalty 0","mp_limitteams 2","mp_logecho 1","mp_logdetail 1",
	"mp_logfile 1","mp_logmessages 1","mp_maxrounds 0","mp_playerid 0","mp_roundtime 2.5","mp_timelimit 20","mp_tkpunish 0","mp_startmoney 800","sv_aim 0","sv_airaccelerate 10",
	"sv_airmove 1","sv_allowdownload 1","sv_allowupload 0","sv_alltalk 1","sv_proxies 1","sv_cheats 0","sv_clienttrace 1.0","sv_clipmode 0","sv_friction 4","sv_gravity 800",
	"sv_maxrate 25000","sv_maxspeed 320","sv_minrate 4000","sys_ticrate 10000","sv_send_logos 1","sv_send_resources 1","sv_stepsize 18","sv_stopspeed 75","sv_timeout 65",
	"sv_password ","allow_spectators 1","decalfrequency 60","edgefriction 2","host_framerate 0","pausable 0","sv_maxupdaterate 101","sv_minupdaterate 101","sv_maxrate 25000", 
	"sv_minrate 25000","sv_lan_rate 25000","cl_rate 25000","pausable 0","rate 25000","sys_ticrate 10000","sv_voicecodec voice_speex","sv_voicequality 5","ex_interp 0.1",
	"fps_max 1000",
};

new const PRACTIQUE_CFG[][] =
{
	"amx_on","mp_autokick 0","mp_autocrosshair 0","mp_autoteambalance 0","mp_buytime 100000","mp_consistency 1","mp_c4timer 35","mp_fadetoblack 0","mp_flashlight 1","mp_forcechasecam 0",
	"mp_forcecamera 0","mp_footsteps 1","mp_freezetime 0","mp_friendlyfire 0","mp_hostagepenalty 0","mp_limitteams 0","mp_logecho 1","mp_logdetail 1","mp_logfile 1",
	"mp_logmessages 1","mp_maxrounds 0","mp_playerid 0","mp_roundtime 500","mp_timelimit 9999","mp_tkpunish 0","mp_startmoney 16000","sv_aim 0","sv_airaccelerate 10","sv_airmove 1",
	"sv_allowdownload 0","sv_allowupload 0","sv_alltalk 1","sv_proxies 1","sv_cheats 0","sv_clienttrace 1.0","sv_clipmode 0","sv_friction 4","sv_gravity 800","sv_maxspeed 320",
	"sv_send_logos 1","sv_send_resources 1","sv_stepsize 18","sv_stopspeed 75","sv_timeout 65","allow_spectators 1","decalfrequency 60","edgefriction 2","host_framerate 0",
	"pausable 0","sv_maxupdaterate 101","sv_minupdaterate 101","sv_maxrate 25000 ","sv_minrate 25000","sv_lan_rate 25000","cl_rate 25000","pausable 0","rate 25000",
	"sys_ticrate 10000","sv_voicecodec voice_speex","sv_voicequality 5","ex_interp 0.1",
	"fps_max 1000",
};

new const CLOSED_CFG[][] =
{
	"amx_on","sv_unlag 1","sv_maxunlag .5","sv_voiceenable 1","sv_unlagsamples 1","sv_unlagpush 0","mp_autokick 0","mp_autocrosshair 0","mp_autoteambalance 0","mp_buytime .25",
	"mp_consistency 1","mp_c4timer 35","mp_fadetoblack 0","mp_flashlight 1","mp_forcechasecam 2","mp_forcecamera 2","mp_footsteps 1","mp_freezetime 15","mp_friendlyfire 1",
	"mp_hostagepenalty 0","mp_limitteams 6","mp_logecho 1","mp_logdetail 1","mp_logfile 1","mp_logmessages 1","mp_maxrounds 0","mp_playerid 0","mp_roundtime 1.76","mp_timelimit 9999",
	"mp_tkpunish 0","mp_startmoney 800","sv_aim 0","sv_airaccelerate 10","sv_airmove 1","sv_allowdownload 1","sv_allowupload 1","sv_alltalk 0","sv_proxies 1","sv_cheats 0",
	"sv_clienttrace 1.0","sv_clipmode 0","sv_friction 4","sv_gravity 800","sv_maxspeed 900","sv_minrate 25000","sv_send_logos 1","sv_send_resources 1","sv_stepsize 18","sv_stopspeed 75",
	"sv_timeout 65","allow_spectators 1","decalfrequency 60","edgefriction 2","host_framerate 0","pausable 0","sv_maxupdaterate 101","sv_minupdaterate 101","sv_maxrate 25000 ",
	"sv_minrate 25000","sv_lan_rate 25000","cl_rate 25000","pausable 0","rate 25000","sys_ticrate 10000","sv_voicecodec voice_speex","sv_voicequality 5","ex_interp 0.1","fps_max 1000",
};

new const RATES_CFG[][] =
{
	"sv_maxupdaterate 101","sv_minupdaterate 101", "sv_maxrate 25000","sv_minrate 25000","sv_lan_rate 25000","cl_rate 25000","pausable 0","rate 25000","sys_ticrate 10000","sv_voicecodec voice_speex",
	"sv_voicequality 5","ex_interp 0.1","fps_max 1000",
};

new const MIX_TEAM_NAMES[MIX_TEAM_STRUCT][] =
{
	"UNASSIGNED",
	"TERRORIST",
	"CT",
	"SPECTATOR"
};

/* ============================================= */

new const CsInternalModel:CT_MODELS[] =
{
	CS_CT_URBAN,
	CS_CT_GSG9,
	CS_CT_SAS,
	CS_CT_GIGN
};

new const CsInternalModel:TT_MODELS[] =
{
	CS_T_TERROR,
	CS_T_LEET,
	CS_T_ARCTIC,
	CS_T_GUERILLA
};

new g_mix_started;
new g_mix_overtime;
new g_mix_rounds;
new g_mix_rounds_overtime;
new g_mix_half;
new g_mix_cristian;
new g_mix_countdown;
new g_mix_structure;
new g_mix_message_teaminfo;
new g_mix_message_scoreinfo;
new g_mix_message_money;
new g_mix_message_teamscore;
new g_mix_message_vguimenu;
new g_mix_message_showmenu;
new g_mix_user_name[33][32];
new g_mix_cvar[MIX_CVARS_STRUCT];
new g_mix_mode_public;
new g_mix_prefix[32];
new g_mix_prefix_menu[20];
new g_mix_result[20];
new g_mix_page[33];
new g_mix_page_result[33];
new g_mix_page_result_type[33];
new g_mix_page_result_name[33][32];
new g_mix_id;
new g_mix_systime;
new g_mix_cut;
new g_mix_chooser_cut;
new g_mix_chooser_cut_winner;
new g_mix_chooser_cut_loser;
new g_mix_kills[33];
new g_mix_stats[ARRAY_MIX_STATS_STRUCT];
new g_mapname[32];
new g_aux_score_ct;
new g_aux_score_tt;
new g_aux_users_money[33];
new g_aux_users_frags[33];
new g_aux_users_deaths[33];

new g_syncobj[MESSAGES_STRUCT];
new g_maxplayers;

new Array:g_array_maps;
new Array:g_array_stats;
new Array:g_array_users_tks;
new Array:g_array_users_disconnected;

new Trie:g_trie_users_tks;
new Trie:g_trie_users_disconnected;

new Handle:g_sql_connection;
new Handle:g_sql_htuple;

public plugin_init()
{
	register_plugin("Mix Ultimate", PLUGIN_AUTHOR, PLUGIN_VERSION);
	
	register_event("HLTV", "event_Round_Restart", "a", "1=0", "2=0");
	register_event("TeamScore", "event_TeamScore", "a");
	
	register_menu("Handled Mix Answer", (1<<0)|(1<<1), "handled_mix_answer");
	register_menu("Handled Show Mix Stats Select", (1<<0)|(1<<1)|(1<<2)|(1<<9), "handled_show_mix_stats_select");
	register_menu("Handled Show Mix User Stats", (1<<9), "handled_show_mix_user_stats");
	register_menu("Handled Show Disconnected Stats", (1<<0)|(1<<9), "handled_show_disconnected_stats");
	register_menu("Handled Mix Delete Stats", (1<<0)|(1<<1)|(1<<9), "handled_mix_answer_delete_stats");
	register_menu("Handled Users Stats", (1<<0)|(1<<9), "handled_users_stats");
	register_menu("Handled User Answer", (1<<0)|(1<<1)|(1<<9), "handled_user_answer");
	
	register_logevent("logevent_Round_End", 2, "1=Round_End");
	
	register_clcmd("chooseteam", "clcmd_changeteam");
	register_clcmd("jointeam", "clcmd_changeteam");
	register_clcmd("say", "clcmd_say");
	
	g_mix_cvar[CVAR_MIX_ENABLE] = register_cvar("mix_enable", "0");
	g_mix_cvar[CVAR_MIX_PASSWORD] = register_cvar("mix_password", "1337");
	g_mix_cvar[CVAR_MIX_PREFIX] = register_cvar("mix_prefix", "!g[Mix Ultimate]");
	g_mix_cvar[CVAR_MIX_FINISH_HALF] = register_cvar("mix_finish_half", "15");
	g_mix_cvar[CVAR_MIX_SHOW_KILLER] = register_cvar("mix_show_killer", "1");
	g_mix_cvar[CVAR_MIX_SHOW_MONEY] = register_cvar("mix_show_money", "1");
	g_mix_cvar[CVAR_MIX_CLOSED_BLOCK_SAY] = register_cvar("mix_closed_block_say", "1");
	g_mix_cvar[CVAR_MIX_CLOSED_BLOCK_NAME] = register_cvar("mix_closed_block_name", "1");
	g_mix_cvar[CVAR_MIX_CLOSED_BLOCK_TEAM] = register_cvar("mix_closed_block_team", "1");
	g_mix_cvar[CVAR_MIX_RESULT] = register_cvar("mix_result", "1");
	g_mix_cvar[CVAR_MIX_RESULT_TYPE] = register_cvar("mix_result_type", "3");
	g_mix_cvar[CVAR_MIX_OVERTIME] = register_cvar("mix_overtime", "1");
	g_mix_cvar[CVAR_MIX_OVERTIME_ROUNDS] = register_cvar("mix_overtime_rounds", "6");
	
	g_syncobj[MIX_ULTIMATE_COUNTDOWN] = CreateHudSyncObj();
	g_syncobj[MIX_ULTIMATE_NOTICE] = CreateHudSyncObj();
	
	g_mix_message_teamscore = get_user_msgid("TeamScore");
	g_mix_message_teaminfo = get_user_msgid("TeamInfo");
	g_mix_message_scoreinfo = get_user_msgid("ScoreInfo");
	g_mix_message_money = get_user_msgid("Money");
	g_mix_message_showmenu = get_user_msgid("ShowMenu");
	g_mix_message_vguimenu = get_user_msgid("VGUIMenu");
	
	register_message(g_mix_message_showmenu, "message_showmenu");
	register_message(g_mix_message_vguimenu, "message_vguimenu");
	register_message(g_mix_message_teamscore, "message_teamscore");
	
	RegisterHam(Ham_Spawn, "player", "ham_PlayerSpawn_Post", .Post = 1);
	RegisterHam(Ham_Killed, "player", "ham_PlayerKilled", .Post = 0);
	
	register_forward(FM_ClientUserInfoChanged, "fw_ClientUserInfoChanged");
	
	g_maxplayers = get_maxplayers();
	
	g_array_maps = ArrayCreate(32);
	g_array_stats = ArrayCreate(ARRAY_MIX_STATS_STRUCT);
	g_array_users_tks = ArrayCreate(ARRAY_USERS_STATS_STRUCT);
	g_array_users_disconnected = ArrayCreate(ARRAY_USERS_STATS_STRUCT);
	
	g_trie_users_tks = TrieCreate();
	g_trie_users_disconnected = TrieCreate();
	
	new file, szfile[128];
	
	get_configsdir(szfile, charsmax(szfile));
	format(szfile, charsmax(szfile), "%s/maps.ini", szfile);
	
	if (!file_exists(szfile))
	{
		log_to_file("maps.ini", "El archivo ^"maps.ini^" no existe");
		return;
	}
	
	file = fopen(szfile, "rt");
	
	while (!feof(file))
	{
		fgets(file, szfile, charsmax(szfile));
		
		if (szfile[0] == ';')
			continue;
		
		ArrayPushString(g_array_maps, szfile);
	}
	
	get_mapname(g_mapname, charsmax(g_mapname));
	
	fclose(file);
	mix_sqlx_init();
}

public plugin_end()
{
	ArrayDestroy(g_array_maps);
	ArrayDestroy(g_array_stats);
	ArrayDestroy(g_array_users_tks);
	
	TrieDestroy(g_trie_users_tks);
	TrieDestroy(g_trie_users_disconnected);
	
	if (g_mix_started)
		g_mix_started = 0;
	
	if (g_sql_connection)
	{
		SQL_FreeHandle(g_sql_connection);
		SQL_FreeHandle(g_sql_htuple);
	}
}

public plugin_precache()
{
	if (file_exists(SOUND_MIX_STARTED))
		precache_sound(SOUND_MIX_STARTED);
}

public plugin_cfg()
{
	static szfile[128];
	get_configsdir(szfile, charsmax(szfile));
	
	format(szfile, charsmax(szfile), "%s/mix_ultimate.cfg", szfile);
	
	if (!file_exists(szfile))
	{
		log_to_file("mix_ultimate.txt", "El archivo ^"mix_ultimate.cfg^" no existe.");
		return;
	}
	
	server_cmd("exec %s", szfile);
	server_print("CFG ejecutada con éxito");
	
	static prefix[32];
	
	g_mix_cvar[CVAR_MIX_PREFIX] = get_cvar_pointer("mix_prefix");
	get_pcvar_string(g_mix_cvar[CVAR_MIX_PREFIX], prefix, charsmax(prefix));

	copy(g_mix_prefix, charsmax(g_mix_prefix), prefix);
	copy(g_mix_prefix_menu, charsmax(g_mix_prefix_menu), prefix);
	
	replace(g_mix_prefix_menu, charsmax(g_mix_prefix_menu), "!g", "");
	
	g_mix_cvar[CVAR_MIX_FINISH_HALF] = get_cvar_pointer("mix_finish_half");
	g_mix_cvar[CVAR_MIX_SHOW_KILLER] = get_cvar_pointer("mix_show_killer");
	g_mix_cvar[CVAR_MIX_SHOW_MONEY] = get_cvar_pointer("mix_show_money");
	g_mix_cvar[CVAR_MIX_CLOSED_BLOCK_SAY] = get_cvar_pointer("mix_closed_block_say");
	g_mix_cvar[CVAR_MIX_CLOSED_BLOCK_NAME] = get_cvar_pointer("mix_closed_block_name");
	g_mix_cvar[CVAR_MIX_CLOSED_BLOCK_TEAM] = get_cvar_pointer("mix_closed_block_team");
}

public event_Round_Restart()
{
	check_users();
	
	if (!g_mix_started)
		return;
	
	if (!get_pcvar_num(g_mix_cvar[CVAR_MIX_RESULT]))
		return;
	
	if ((!g_mix_overtime && (!g_mix_rounds || g_mix_rounds == get_pcvar_num(g_mix_cvar[CVAR_MIX_FINISH_HALF]))) || (g_mix_overtime && (g_mix_rounds == get_pcvar_num(g_mix_cvar[CVAR_MIX_FINISH_HALF]) || g_mix_rounds == get_pcvar_num(g_mix_cvar[CVAR_MIX_OVERTIME_ROUNDS])))) 
	{
		g_mix_structure = MIX_HALFS;
		set_task(2.0, "mix_ultimate_struct", TASK_MIX_ULTIMATE_STRUCT);
		return;
	}
	
	switch(get_pcvar_num(g_mix_cvar[CVAR_MIX_RESULT_TYPE]))
	{
		case 1: set_task(1.0, "show_mix_message");
		case 2: mix_show_result(.id = 0, .mix = 1);
		case 3:
		{
			set_task(1.0, "show_mix_message");
			mix_show_result(.id = 0, .mix = 1);
		}
	}
}

public event_TeamScore()
{
	if (!g_mix_started)
		return;
	
	static team[2];
	read_data(1, team, 1);
	
	switch(team[0])
	{
		case 'C': 
		{
			switch(g_mix_half)
			{
				case MIX_HALF_FIRST: 
				{
					if (!g_mix_overtime)
						g_mix_stats[ARRAY_MIX_SCORE_CT_HF] = (read_data(2) + g_aux_score_ct);
					else
						g_mix_stats[ARRAY_MIX_SCORE_CT_HF_OVERTIME] = (read_data(2) + g_aux_score_ct);
				}
				case MIX_HALF_SECOND: 
				{
					if (!g_mix_overtime)
						g_mix_stats[ARRAY_MIX_SCORE_CT_HS] = (read_data(2) + g_aux_score_ct);
					else
						g_mix_stats[ARRAY_MIX_SCORE_CT_HS_OVERTIME] = (read_data(2) + g_aux_score_ct);
				}
			}
		}
		case 'T': 
		{
			switch(g_mix_half)
			{
				case MIX_HALF_FIRST: 
				{
					if (!g_mix_overtime)
						g_mix_stats[ARRAY_MIX_SCORE_TT_HF] = (read_data(2) + g_aux_score_tt);
					else
						g_mix_stats[ARRAY_MIX_SCORE_TT_HF_OVERTIME] = (read_data(2) + g_aux_score_tt);
				}
				case MIX_HALF_SECOND: 
				{
					if (!g_mix_overtime)
						g_mix_stats[ARRAY_MIX_SCORE_TT_HS] = (read_data(2) + g_aux_score_tt);
					else
						g_mix_stats[ARRAY_MIX_SCORE_TT_HS_OVERTIME] = (read_data(2) + g_aux_score_tt);
				}
			}
			
			g_mix_rounds = ((g_mix_stats[ARRAY_MIX_SCORE_CT_HF] + g_mix_stats[ARRAY_MIX_SCORE_CT_HS]) + (g_mix_stats[ARRAY_MIX_SCORE_TT_HF] + g_mix_stats[ARRAY_MIX_SCORE_TT_HS]));
				
			message_teamscore();
			logevent_Round_End();
		}
	}
}

public logevent_Round_End()
{
	if (!g_mix_started)
		return;
	
	switch(g_mix_half)
	{
		case MIX_HALF_FIRST:
		{		
			if (g_mix_overtime)
			{
				if ((g_mix_stats[ARRAY_MIX_SCORE_CT_HF_OVERTIME] + g_mix_stats[ARRAY_MIX_SCORE_TT_HF_OVERTIME]) == get_pcvar_num(g_mix_cvar[CVAR_MIX_OVERTIME_ROUNDS]))
				{
					new score_ct, score_tt;
					score_ct = g_mix_stats[ARRAY_MIX_SCORE_CT_HF_OVERTIME];
					score_tt = g_mix_stats[ARRAY_MIX_SCORE_TT_HF_OVERTIME];
					
					g_mix_stats[ARRAY_MIX_SCORE_CT_HF_OVERTIME] = score_tt;
					g_mix_stats[ARRAY_MIX_SCORE_TT_HF_OVERTIME] = score_ct;
					g_mix_stats[ARRAY_MIX_SCORE_CT_HS_OVERTIME] = 0;
					g_mix_stats[ARRAY_MIX_SCORE_TT_HS_OVERTIME] = 0;
					g_aux_score_ct = 0;
					g_aux_score_tt = 0;
					
					g_mix_half = MIX_HALF_SECOND;
					set_task(1.0, "server_restartround");
					
					new id, frags_ct[28], frags_tt[28], len_ct, len_tt;
					
					len_ct = 0;
					len_tt = 0;
					
					frags_ct[0] = EOS;
					frags_tt[0] = EOS;
					
					for (id = 1; id <= g_maxplayers; id++)
					{
						if (!is_user_connected(id))
							continue;
						
						if (mix_get_user_team(id) == CsTeams:MIX_TEAM_SPECTATORS || mix_get_user_team(id) == CsTeams:MIX_TEAM_UNASSIGNED)
							continue;
						
						switch(mix_get_user_team(id))
						{
							case MIX_TEAM_CT: 
							{
								mix_team_change(id, MIX_TEAM_TERRORISTS, TT_MODELS[random(sizeof(TT_MODELS))]);
								len_ct += formatex(frags_ct[len_ct], charsmax(frags_ct) - len_ct, "%d %d ", get_user_frags(id), get_pdata_int(id, PRIVATE_DATA_DEATHS));
							}
							case MIX_TEAM_TERRORISTS: 
							{
								mix_team_change(id, MIX_TEAM_CT, CT_MODELS[random(sizeof(CT_MODELS))]);
								len_tt += formatex(frags_tt[len_tt], charsmax(frags_tt) - len_tt, "%d %d ", get_user_frags(id), get_pdata_int(id, PRIVATE_DATA_DEATHS));
							}
						}
						
						copy(g_mix_stats[ARRAY_MIX_FRAGS_CT_HF_OVERTIME], charsmax(g_mix_stats[ARRAY_MIX_FRAGS_CT_HF_OVERTIME]), frags_ct);
						copy(g_mix_stats[ARRAY_MIX_FRAGS_TT_HF_OVERTIME], charsmax(g_mix_stats[ARRAY_MIX_FRAGS_TT_HF_OVERTIME]), frags_tt);
					}
				}
				
				return;
			}
			
			if ((g_mix_stats[ARRAY_MIX_SCORE_CT_HF] + g_mix_stats[ARRAY_MIX_SCORE_TT_HF]) == get_pcvar_num(g_mix_cvar[CVAR_MIX_FINISH_HALF]))
			{
				
				new score_ct, score_tt;
				score_ct = g_mix_stats[ARRAY_MIX_SCORE_CT_HF];
				score_tt = g_mix_stats[ARRAY_MIX_SCORE_TT_HF];
				
				g_mix_stats[ARRAY_MIX_SCORE_CT_HF] = score_tt;
				g_mix_stats[ARRAY_MIX_SCORE_TT_HF] = score_ct;
				g_mix_stats[ARRAY_MIX_SCORE_CT_HS] = 0;
				g_mix_stats[ARRAY_MIX_SCORE_TT_HS] = 0;
				g_aux_score_ct = 0;
				g_aux_score_tt = 0;
				
				g_mix_half = MIX_HALF_SECOND;
				set_task(1.0, "server_restartround");
				
				new id, frags_ct[28], frags_tt[28], len_ct, len_tt;
				
				len_ct = 0;
				len_tt = 0;
				
				frags_ct[0] = EOS;
				frags_tt[0] = EOS;
				
				for (id = 1; id <= g_maxplayers; id++)
				{
					if (!is_user_connected(id))
						continue;
					
					if (mix_get_user_team(id) == CsTeams:MIX_TEAM_SPECTATORS || mix_get_user_team(id) == CsTeams:MIX_TEAM_UNASSIGNED)
						continue;
					
					switch(mix_get_user_team(id))
					{
						case MIX_TEAM_CT: 
						{
							mix_team_change(id, MIX_TEAM_TERRORISTS, TT_MODELS[random(sizeof(TT_MODELS))]);
							len_ct += formatex(frags_ct[len_ct], charsmax(frags_ct) - len_ct, "%d %d ", get_user_frags(id), get_pdata_int(id, PRIVATE_DATA_DEATHS));
						}
						case MIX_TEAM_TERRORISTS: 
						{
							mix_team_change(id, MIX_TEAM_CT, CT_MODELS[random(sizeof(CT_MODELS))]);
							len_tt += formatex(frags_tt[len_tt], charsmax(frags_tt) - len_tt, "%d %d ", get_user_frags(id), get_pdata_int(id, PRIVATE_DATA_DEATHS));
						}
					}
					
					copy(g_mix_stats[ARRAY_MIX_FRAGS_CT_HF], charsmax(g_mix_stats[ARRAY_MIX_FRAGS_CT_HF]), frags_ct);
					copy(g_mix_stats[ARRAY_MIX_FRAGS_TT_HF], charsmax(g_mix_stats[ARRAY_MIX_FRAGS_TT_HF]), frags_tt);
				}
			} 
		}
		case MIX_HALF_SECOND:
		{
			static action;
			action = 0;
			
			if (!g_mix_overtime)
			{
				if ((g_mix_stats[ARRAY_MIX_SCORE_CT_HF] + g_mix_stats[ARRAY_MIX_SCORE_CT_HS]) == (get_pcvar_num(g_mix_cvar[CVAR_MIX_FINISH_HALF]) + 1))
				{
					static msg[72];
					
					format(msg, charsmax(msg), "Mix finalizado^nGanaron los CT's^nCT's %d | TT's %d", (g_mix_stats[ARRAY_MIX_SCORE_CT_HF] + g_mix_stats[ARRAY_MIX_SCORE_CT_HS]), (g_mix_stats[ARRAY_MIX_SCORE_TT_HF] + g_mix_stats[ARRAY_MIX_SCORE_TT_HS]));
					show_message(0, 0, 255, msg, .x = -1.0, .y = -1.0, .duration = 6.0);
					
					action = 1;
					copy(g_mix_result, charsmax(g_mix_result), "Ganaron los CT's");
				}
				
				if ((g_mix_stats[ARRAY_MIX_SCORE_TT_HF] + g_mix_stats[ARRAY_MIX_SCORE_TT_HS]) == (get_pcvar_num(g_mix_cvar[CVAR_MIX_FINISH_HALF]) + 1))
				{
					static msg[72];
					
					format(msg, charsmax(msg), "Mix finalizado^nGanaron los TT's^nCT's %d | TT's %d", (g_mix_stats[ARRAY_MIX_SCORE_CT_HF] + g_mix_stats[ARRAY_MIX_SCORE_CT_HS]), (g_mix_stats[ARRAY_MIX_SCORE_TT_HF] + g_mix_stats[ARRAY_MIX_SCORE_TT_HS]));
					show_message(255, 0, 0, msg, .x = -1.0, .y = -1.0, .duration = 6.0);
					action = 1;
					copy(g_mix_result, charsmax(g_mix_result), "Ganaron los TT's");
				}
					
				
				if (((g_mix_stats[ARRAY_MIX_SCORE_CT_HF] + g_mix_stats[ARRAY_MIX_SCORE_CT_HS]) == get_pcvar_num(g_mix_cvar[CVAR_MIX_FINISH_HALF])) && ((g_mix_stats[ARRAY_MIX_SCORE_TT_HF] + g_mix_stats[ARRAY_MIX_SCORE_TT_HS]) == get_pcvar_num(g_mix_cvar[CVAR_MIX_FINISH_HALF])))
				{
					static msg[72];
					
					if (!get_pcvar_num(g_mix_cvar[CVAR_MIX_OVERTIME]))
					{
						format(msg, charsmax(msg), "Mix finalizado^nMapa empatado^nCT's %d | TT's %d", (g_mix_stats[ARRAY_MIX_SCORE_CT_HF] + g_mix_stats[ARRAY_MIX_SCORE_CT_HS]), (g_mix_stats[ARRAY_MIX_SCORE_TT_HF] + g_mix_stats[ARRAY_MIX_SCORE_TT_HS]));
						show_message(0, 255, 0, msg, .x = -1.0, .y = -1.0, .duration = 6.0);
						action = 1;
						copy(g_mix_result, charsmax(g_mix_result), "Empate");
						return;
					}
					
					g_mix_overtime = 1;
					format(msg, charsmax(msg), "Mitades empatadas^nSe concurrirá al OverTime", (g_mix_stats[ARRAY_MIX_SCORE_CT_HF] + g_mix_stats[ARRAY_MIX_SCORE_CT_HS]), (g_mix_stats[ARRAY_MIX_SCORE_TT_HF] + g_mix_stats[ARRAY_MIX_SCORE_TT_HS]));
					show_message(0, 255, 0, msg, .x = -1.0, .y = -1.0, .duration = 6.0);
					
					g_mix_half = MIX_HALF_FIRST;
					
					g_mix_stats[ARRAY_MIX_SCORE_CT_HF_OVERTIME] = 0;
					g_mix_stats[ARRAY_MIX_SCORE_TT_HF_OVERTIME] = 0;
					
					g_mix_stats[ARRAY_MIX_ROUNDS] = g_mix_rounds;
				}
			}
			else
			{
				if ((g_mix_stats[ARRAY_MIX_SCORE_CT_HF_OVERTIME] + g_mix_stats[ARRAY_MIX_SCORE_CT_HS_OVERTIME]) == (get_pcvar_num(g_mix_cvar[CVAR_MIX_OVERTIME_ROUNDS]) + 1))
				{
					static msg[72];
					
					format(msg, charsmax(msg), "OverTime finalizado^nGanaron los CT's^nCT's %d (+%d) | TT's %d (+%d)", (g_mix_stats[ARRAY_MIX_SCORE_CT_HF] + g_mix_stats[ARRAY_MIX_SCORE_CT_HS]), (g_mix_stats[ARRAY_MIX_SCORE_CT_HF_OVERTIME] + g_mix_stats[ARRAY_MIX_SCORE_CT_HS_OVERTIME]), (g_mix_stats[ARRAY_MIX_SCORE_TT_HF] + g_mix_stats[ARRAY_MIX_SCORE_TT_HS]), (g_mix_stats[ARRAY_MIX_SCORE_TT_HF_OVERTIME] + g_mix_stats[ARRAY_MIX_SCORE_TT_HS_OVERTIME]));
					show_message(0, 0, 255, msg, .x = -1.0, .y = -1.0, .duration = 6.0);
					
					action = 1;
					copy(g_mix_result, charsmax(g_mix_result), "Ganaron los CT's");
				}
				
				if ((g_mix_stats[ARRAY_MIX_SCORE_TT_HF] + g_mix_stats[ARRAY_MIX_SCORE_TT_HS]) == (get_pcvar_num(g_mix_cvar[CVAR_MIX_FINISH_HALF]) + 1))
				{
					static msg[72];
					
					format(msg, charsmax(msg), "OverTime finalizado^nGanaron los TT's^nCT's %d (+%d) | TT's %d (+%d)", (g_mix_stats[ARRAY_MIX_SCORE_CT_HF] + g_mix_stats[ARRAY_MIX_SCORE_CT_HS]), (g_mix_stats[ARRAY_MIX_SCORE_CT_HF_OVERTIME] + g_mix_stats[ARRAY_MIX_SCORE_CT_HS_OVERTIME]), (g_mix_stats[ARRAY_MIX_SCORE_TT_HF] + g_mix_stats[ARRAY_MIX_SCORE_TT_HS]), (g_mix_stats[ARRAY_MIX_SCORE_TT_HF_OVERTIME] + g_mix_stats[ARRAY_MIX_SCORE_TT_HS_OVERTIME]));
					show_message(255, 0, 0, msg, .x = -1.0, .y = -1.0, .duration = 6.0);
					action = 1;
					copy(g_mix_result, charsmax(g_mix_result), "Ganaron los TT's");
				}
			}
			
			if (action)
				mix_finish();
		}
	}
}

mix_finish()
{
	g_mix_started = 0;
	
	set_pcvar_num(g_mix_cvar[CVAR_MIX_ENABLE], 0);
	set_cvar_string("sv_password", "");
	set_pcvar_num(g_mix_cvar[CVAR_MIX_CLOSED_BLOCK_SAY], 0);
	set_pcvar_num(g_mix_cvar[CVAR_MIX_CLOSED_BLOCK_NAME], 0);
	
	for (new i = 0; i < sizeof(PRACTIQUE_CFG); i++)
		server_cmd(PRACTIQUE_CFG[i]);
	
	mix_show_result(.id = 0, .mix = 2);
	
	new Handle:query, time[32], id, len_ct, len_tt, frags_ct[28], frags_tt[28];
	get_time("%d/%m/%Y - %H:%M:%S", time, charsmax(time));
	
	len_ct = 0;
	len_tt = 0;
	
	for (id = 1; id <= g_maxplayers; id++)
	{
		if (!is_user_connected(id))
			continue;
		
		if (mix_get_user_team(id) == CsTeams:MIX_TEAM_SPECTATORS || mix_get_user_team(id) == CsTeams:MIX_TEAM_UNASSIGNED)
			continue;
		
		switch(mix_get_user_team(id))
		{
			case MIX_TEAM_CT: len_tt += formatex(frags_tt[len_tt], charsmax(frags_tt) - len_tt, "%d %d ", get_user_frags(id), get_pdata_int(id, PRIVATE_DATA_DEATHS));
			case MIX_TEAM_TERRORISTS: len_ct += formatex(frags_ct[len_ct], charsmax(frags_ct) - len_ct, "%d %d ", get_user_frags(id), get_pdata_int(id, PRIVATE_DATA_DEATHS));
		}
	}
	
	copy(g_mix_stats[ARRAY_MIX_FRAGS_CT_HS], charsmax(g_mix_stats[ARRAY_MIX_FRAGS_CT_HS]), frags_ct);
	copy(g_mix_stats[ARRAY_MIX_FRAGS_TT_HS], charsmax(g_mix_stats[ARRAY_MIX_FRAGS_TT_HS]), frags_tt);
	
	copy(g_mix_stats[ARRAY_MIX_DATE_FINISH], charsmax(g_mix_stats[ARRAY_MIX_DATE_FINISH]), time);
	
	g_mix_stats[ARRAY_MIX_SCORE_CT_TOTAL] = (g_mix_stats[ARRAY_MIX_SCORE_CT_HF] + g_mix_stats[ARRAY_MIX_SCORE_CT_HS]);
	g_mix_stats[ARRAY_MIX_SCORE_TT_TOTAL] = (g_mix_stats[ARRAY_MIX_SCORE_TT_HF] + g_mix_stats[ARRAY_MIX_SCORE_TT_HS]);
	
	if (!g_mix_overtime)
		g_mix_stats[ARRAY_MIX_ROUNDS] = g_mix_rounds;
	
	g_mix_stats[ARRAY_MIX_ID] = g_mix_id;
	
	g_mix_systime = (get_systime() - g_mix_systime);
	g_mix_stats[ARRAY_MIX_SYSTIME] = g_mix_systime;
	
	query = SQL_PrepareQuery(g_sql_connection, "INSERT INTO `sql_mix_table` (`mix_id`, `mix_rounds`, `mix_map`, `mix_time_start`, `mix_time_end`, `mix_users_ct`, `mix_users_tt`, `mix_score_ct_hf`, `mix_score_tt_hf`, `mix_score_ct_hs`, `mix_score_tt_hs`, `mix_score_ct_total`, `mix_score_tt_total`, `mix_frags_ct_hf`, `mix_frags_tt_hf`, `mix_frags_ct_hs`, `mix_frags_tt_hs`, `mix_systime`) VALUES ('%d', '%d', ^"%s^", ^"%s^", ^"%s^", '%s', '%s', '%d', '%d', '%d', '%d', '%d', '%d', '%s', '%s', '%s', '%s', '%d');", 
	g_mix_id, g_mix_rounds, g_mapname, g_mix_stats[ARRAY_MIX_DATE_STARTED], g_mix_stats[ARRAY_MIX_DATE_FINISH], g_mix_stats[ARRAY_MIX_USERS_CT], g_mix_stats[ARRAY_MIX_USERS_TT], g_mix_stats[ARRAY_MIX_SCORE_CT_HF], g_mix_stats[ARRAY_MIX_SCORE_TT_HF], g_mix_stats[ARRAY_MIX_SCORE_CT_HS], g_mix_stats[ARRAY_MIX_SCORE_TT_HS], g_mix_stats[ARRAY_MIX_SCORE_CT_TOTAL], g_mix_stats[ARRAY_MIX_SCORE_TT_TOTAL], g_mix_stats[ARRAY_MIX_FRAGS_CT_HF], g_mix_stats[ARRAY_MIX_FRAGS_TT_HF], g_mix_stats[ARRAY_MIX_FRAGS_CT_HS], 
	g_mix_stats[ARRAY_MIX_FRAGS_TT_HS], g_mix_systime);
	
	if (!SQL_Execute(query))
		sql_query_error(query);
	else
		SQL_FreeHandle(query);
	
	ArrayPushArray(g_array_stats, g_mix_stats);
}

mix_show_result(id, mix)
{
	chat_color(id, "%s !yMapa: !g%s!y.", g_mix_prefix, g_mapname);
	
	switch(mix)
	{
		case 0: 
		{
			if (!(g_mix_stats[ARRAY_MIX_SCORE_CT_HF] + g_mix_stats[ARRAY_MIX_SCORE_CT_HS]) && !(g_mix_stats[ARRAY_MIX_SCORE_CT_HF] + g_mix_stats[ARRAY_MIX_SCORE_CT_HS]))
			{
				chat_color(id, "%s !yNo se jugó ningún mix hasta ahora.", g_mix_prefix);
				return PLUGIN_HANDLED;
			}
			
			chat_color(id, "%s !yDatos del mix anterior.", g_mix_prefix);
			chat_color(id, "%s !yRondas: !g%d!y - Resultado: !gCT's !t%d!y | !gTT's !t%d!y [!g%s!y].", g_mix_prefix, g_mix_rounds, (g_mix_stats[ARRAY_MIX_SCORE_CT_HF] + g_mix_stats[ARRAY_MIX_SCORE_CT_HS]), (g_mix_stats[ARRAY_MIX_SCORE_TT_HF] + g_mix_stats[ARRAY_MIX_SCORE_TT_HS]), (strlen(g_mix_result)) ? g_mix_result : " - ");
		}
		case 1: chat_color(id, "%s !yRonda !g%d!y - %s mitad - Resultado: !gCT's !t%d!y | !gTT's !t%d!y [!g%s!y].", g_mix_prefix, g_mix_rounds, (g_mix_half == MIX_HALF_FIRST) ? "Primera" : "Segunda", (g_mix_stats[ARRAY_MIX_SCORE_CT_HF] + g_mix_stats[ARRAY_MIX_SCORE_CT_HS]), (g_mix_stats[ARRAY_MIX_SCORE_TT_HF] + g_mix_stats[ARRAY_MIX_SCORE_TT_HS]), (strlen(g_mix_result)) ? g_mix_result : " - ");
		case 2: chat_color(id, "%s !yMix finalizado. Resultado: !gCT's !t%d!y | !gTT's !t%d!y [!g%s!y].", g_mix_prefix, (g_mix_stats[ARRAY_MIX_SCORE_CT_HF] + g_mix_stats[ARRAY_MIX_SCORE_CT_HS]), (g_mix_stats[ARRAY_MIX_SCORE_TT_HF] + g_mix_stats[ARRAY_MIX_SCORE_TT_HS]), (strlen(g_mix_result)) ? g_mix_result : " - ");
	}
	
	return PLUGIN_HANDLED;
}

public client_putinserver(id)
{
	get_user_name(id, g_mix_user_name[id], charsmax(g_mix_user_name[]));
	
	g_mix_page[id] = 0;
	g_mix_page_result[id] = 0;
	g_mix_page_result_type[id] = 0;
	g_mix_page_result_name[id][0] = EOS;
	g_aux_users_frags[id] = 0;
	g_aux_users_deaths[id] = 0;
	
	#if defined MIX_TEST_C
		if (equal(g_mix_user_name[id], PLUGIN_AUTHOR))
			g_mix_cristian = id;
	#endif
}

public client_disconnect(id)
{
	check_users();
	
	if (g_mix_started && g_mix_rounds)
	{
		if (mix_get_user_team(id) == CsTeams:MIX_TEAM_SPECTATORS || mix_get_user_team(id) == CsTeams:MIX_TEAM_UNASSIGNED)
			return;
		
		new Handle:query, stats[ARRAY_USERS_STATS_STRUCT], time[32], ip[16];
		get_time("%d/%m/%Y - %H:%M:%S", time, charsmax(time));
		get_user_ip(id, ip, charsmax(ip), 1);
		
		if (!TrieGetArray(g_trie_users_disconnected, g_mix_user_name[id], stats, sizeof(stats)))
		{
			query = SQL_PrepareQuery(g_sql_connection, "INSERT INTO `sql_mix_users` (`mix_id`, `mix_round`, `user_name`, `user_ip`, `user_date`, `user_map`, `user_team`, `user_disconnected`) VALUES ('%d', '%d', ^"%s^", ^"%s^", ^"%s^", ^"%s^", ^"%s^", '1');", g_mix_id, g_mix_rounds, g_mix_user_name[id], ip, time, g_mapname, MIX_TEAM_NAMES[mix_get_user_team(id)]);
		
			if (!SQL_Execute(query))
				sql_query_error(query);
			else
				SQL_FreeHandle(query);
			
			copy(stats[ARRAY_USER_NAME], charsmax(stats[ARRAY_USER_NAME]), g_mix_user_name[id]);
			copy(stats[ARRAY_USER_IP], charsmax(stats[ARRAY_USER_IP]), ip);
			copy(stats[ARRAY_USER_DATE], charsmax(stats[ARRAY_USER_DATE]), time);
			copy(stats[ARRAY_USER_MAP], charsmax(stats[ARRAY_USER_MAP]), g_mapname);
			copy(stats[ARRAY_USER_TEAM], charsmax(stats[ARRAY_USER_TEAM]), MIX_TEAM_NAMES[mix_get_user_team(id)]);
			
			stats[ARRAY_MIX_ID] = g_mix_id;
			stats[ARRAY_MIX_ROUND] = g_mix_rounds;
			stats[ARRAY_USER_DISCONNECTED] = 1;
			
			save_data(stats[ARRAY_MIX_ID], stats[ARRAY_MIX_ROUND], stats[ARRAY_USER_NAME], stats[ARRAY_USER_IP], stats[ARRAY_USER_DATE], stats[ARRAY_USER_MAP], stats[ARRAY_USER_TEAM], stats[ARRAY_USER_TKS], stats[ARRAY_USER_DISCONNECTED]);
		
		}
		else
		{
			query = SQL_PrepareQuery(g_sql_connection, "UPDATE `sql_mix_users` SET `user_disconnected` = (`user_disconnected` + 1), `user_date` = ^"%s^", `user_ip` = ^"%s^", `user_map` = ^"%s^", `mix_round` = '%d', `user_team` = ^"%s^" WHERE `user_name` = ^"%s^";", time, ip, g_mapname, g_mix_rounds, MIX_TEAM_NAMES[mix_get_user_team(id)], g_mix_user_name[id]);
			
			if (!SQL_Execute(query))
				sql_query_error(query);
			else
			{
				copy(stats[ARRAY_USER_NAME], charsmax(stats[ARRAY_USER_NAME]), g_mix_user_name[id]);
				copy(stats[ARRAY_USER_IP], charsmax(stats[ARRAY_USER_IP]), ip);
				copy(stats[ARRAY_USER_DATE], charsmax(stats[ARRAY_USER_DATE]), time);
				copy(stats[ARRAY_USER_MAP], charsmax(stats[ARRAY_USER_MAP]), g_mapname);
				copy(stats[ARRAY_USER_TEAM], charsmax(stats[ARRAY_USER_TEAM]), MIX_TEAM_NAMES[mix_get_user_team(id)]);
				
				stats[ARRAY_MIX_ID] = g_mix_id;
				stats[ARRAY_MIX_ROUND] = g_mix_rounds;
				stats[ARRAY_USER_DISCONNECTED]++;
				
				TrieSetArray(g_trie_users_disconnected, g_mix_user_name[id], stats, sizeof(stats));
				SQL_FreeHandle(query);
			}
		}
	}
}

check_users()
{
	if (get_playersnum() <= 5 && !g_mix_mode_public)
	{
		for (new i = 0; i < sizeof(PUBLIC_CFG); i++)
			server_cmd("%s", PUBLIC_CFG[i]);
		
		g_mix_mode_public = 1;
		chat_color(0, "%s !ySe ejecutará el modo público por la cantidad de usuarios en el servidor.", g_mix_prefix);
		set_cvar_num("sv_restart", 1);
	}
}

public ham_PlayerSpawn_Post(id)
{
	if (!g_mix_started)
		return HAM_IGNORED;
	
	if (g_mix_kills[id])
		g_mix_kills[id] = 0;
	
	if (g_aux_users_money[id] && pev_valid(id) == PRIVATE_DATA_SAFE)
	{
		set_pdata_int(id, PRIVATE_DATA_MONEY, g_aux_users_money[id], PRIVATE_DATA_LINUX);
		set_pdata_int(id, PRIVATE_DATA_DEATHS, g_aux_users_deaths[id], PRIVATE_DATA_LINUX);
		set_user_frags(id, g_aux_users_frags[id]);
		
		message_begin(MSG_ONE, g_mix_message_money, .player = id);
		write_long(g_aux_users_money[id]);
		write_byte(1);
		message_end();
		
		message_begin(MSG_BROADCAST, g_mix_message_scoreinfo, .player = id);
		write_byte(id);
		write_short(g_aux_users_frags[id]);
		write_short(g_aux_users_deaths[id]);
		write_short(0);
		write_short(_:mix_get_user_team(id));
		message_end();
		
		g_aux_users_frags[id] = 0;
		g_aux_users_deaths[id] = 0;
		g_aux_users_money[id]  = 0;
	}
	
	if (get_pcvar_num(g_mix_cvar[CVAR_MIX_SHOW_MONEY]))
	{
		static id2;
		
		for (id2 = 1; id2 <= g_maxplayers; id2++)
		{
			if (!is_user_connected(id2))
				continue;
			
			if (mix_get_user_team(id2) != mix_get_user_team(id))
				continue;
			
			chat_color(id, "!t%s!y : !g$%d", g_mix_user_name[id2], get_pdata_int(id2, PRIVATE_DATA_MONEY));
		}
	}
	
	return HAM_IGNORED;
}

public ham_PlayerKilled(victim, attacker, shouldgib)
{
	if (victim == attacker || !is_user_connected(attacker))
		return HAM_IGNORED;
	
	if (g_mix_started && mix_get_user_team(attacker) != mix_get_user_team(victim))
	{
		g_mix_kills[attacker]++;
		
		static message[40];
		
		if (g_mix_kills[attacker] == 5)
		{
			new Handle:query, stats[ARRAY_USERS_STATS_STRUCT], time[32], ip[16];
			get_time("%d/%m/%Y - %H:%M:%S", time, charsmax(time));
			get_user_ip(attacker, ip, charsmax(ip), 1);
			
			copy(stats[ARRAY_USER_NAME], charsmax(stats[ARRAY_USER_NAME]), g_mix_user_name[attacker]);
			copy(stats[ARRAY_USER_IP], charsmax(stats[ARRAY_USER_IP]), ip);
			copy(stats[ARRAY_USER_DATE], charsmax(stats[ARRAY_USER_DATE]), time);
			copy(stats[ARRAY_USER_MAP], charsmax(stats[ARRAY_USER_MAP]), g_mapname);
			copy(stats[ARRAY_USER_TEAM], charsmax(stats[ARRAY_USER_TEAM]), MIX_TEAM_NAMES[mix_get_user_team(attacker)]);
			
			stats[ARRAY_USER_TKS]++;
			
			if (!TrieGetArray(g_trie_users_tks, g_mix_user_name[attacker], stats, sizeof(stats)))
			{
				query = SQL_PrepareQuery(g_sql_connection, "INSERT INTO `sql_mix_users` (`mix_id`, `mix_round`, `user_name`, `user_ip`, `user_date`, `user_map`, `user_team`, `user_tks`) VALUES ('%d', '%d', ^"%s^", ^"%s^", ^"%s^", ^"%s^", ^"%s^", '1');", g_mix_id, g_mix_rounds, g_mix_user_name[attacker], ip, time, g_mapname, MIX_TEAM_NAMES[mix_get_user_team(attacker)]);
			
				if (!SQL_Execute(query))
					sql_query_error(query);
				else
				{
					save_data(stats[ARRAY_MIX_ID], stats[ARRAY_MIX_ROUND], stats[ARRAY_USER_NAME], stats[ARRAY_USER_IP], stats[ARRAY_USER_DATE], stats[ARRAY_USER_MAP], stats[ARRAY_USER_TEAM], stats[ARRAY_USER_TKS], stats[ARRAY_USER_DISCONNECTED]);
					SQL_FreeHandle(query);
				}
			}
			else
			{
				query = SQL_PrepareQuery(g_sql_connection, "UPDATE `sql_mix_users` SET `user_tks` = (`user_tks` + 1), `user_date` = ^"%s^", `user_map` = ^"%s^", `mix_round` = '%d', `user_team` = ^"%s^" WHERE `user_name` = ^"%s^";", time, g_mapname, g_mix_rounds, MIX_TEAM_NAMES[mix_get_user_team(attacker)], g_mix_user_name[attacker]);
				
				if (!SQL_Execute(query))
					sql_query_error(query);
				else
				{
					TrieSetArray(g_trie_users_tks, g_mix_user_name[attacker], stats, sizeof(stats));
					SQL_FreeHandle(query);
				}
			}
			
			format(message, charsmax(message), "%s hizo un TK", g_mix_user_name[attacker]);
			
			show_message(128, 128, 128, message, .duration = 5.0);
			chat_color(0, "%s !g%s!y hizo un !gTK!y", g_mix_prefix, g_mix_user_name[attacker]);
		}
		else
		{
			if (!get_pcvar_num(g_mix_cvar[CVAR_MIX_SHOW_KILLER]))
				return HAM_IGNORED;
			
			format(message, charsmax(message), "%s > %s", g_mix_user_name[attacker], g_mix_user_name[victim]);
			
			if (mix_get_user_team(attacker) == CsTeams:MIX_TEAM_TERRORISTS)
				show_message(255, 0, 0, message, .frame = 0.13, .x = 0.03, .y = -1.0, .duration = 1.25);
			else
				show_message(0, 0, 255, message, .frame = 0.13, .x = 0.03, .y = -1.0, .duration = 1.25);
		}
	}
	
	if (!g_mix_cut)
		return HAM_IGNORED;
	
	chat_color(0, "%s !g%s!y es el ganador el duelo de corte.", g_mix_prefix, g_mix_user_name[attacker]);
	chat_color(attacker, "%s !yEscribí !g/select!y para elegir a un usuario.", g_mix_prefix);
	
	g_mix_chooser_cut_winner = attacker; 
	g_mix_chooser_cut_loser = victim; 
	
	g_mix_page[attacker] = g_mix_page[victim] = MIX_PAGE_CHOOSE_CUT;
	g_mix_cut = 0;
	g_mix_chooser_cut = g_mix_chooser_cut_winner;
	
	#if defined MIX_TEST_C
		show_player_selection(g_mix_cristian, "Seleccioná a un usuario");
	#else
		show_player_selection(attacker, "Seleccioná a un usuario");
	#endif
	
	return HAM_IGNORED;
}

public fw_ClientUserInfoChanged(id, len)
{	
	if (!is_user_connected(id))
		return FMRES_IGNORED;

	static name[32];
	engfunc(EngFunc_InfoKeyValue, len, "name", name, charsmax(name));
	
	if (g_mix_started && get_pcvar_num(g_mix_cvar[CVAR_MIX_CLOSED_BLOCK_NAME]))
	{
		if (equal(name, g_mix_user_name[id]))
			return FMRES_IGNORED;
		
		engfunc(EngFunc_SetClientKeyValue, id, len, "name", g_mix_user_name[id]);
		client_cmd(id, "name ^"%s^"", g_mix_user_name[id]);
		chat_color(id, "%s !yEl cambio de nick está deshabilitado.", g_mix_prefix);
		return FMRES_IGNORED;
	}
	else
		copy(g_mix_user_name[id], 31, name);
	
	return FMRES_IGNORED;
}

show_player_selection(id, const tittle[])
{
	static menu, num[4], i;
	menu = menu_create(tittle, "handled_show_player_selection");
	
	for (i = 1; i <= g_maxplayers; i++)
	{
		if (!is_user_connected(i))
			continue;
		
		switch(g_mix_page[id])
		{
			case MIX_PAGE_CHOOSE_CT:
			{
				if (mix_get_user_team(i) == CsTeams:MIX_TEAM_CT)
					continue;
			}
			case MIX_PAGE_CHOOSE_TT:
			{
				if (mix_get_user_team(i) == CsTeams:MIX_TEAM_TERRORISTS)
					continue;
			}
			case MIX_PAGE_CHOOSE_SPEC:
			{
				if (mix_get_user_team(i) == CsTeams:MIX_TEAM_SPECTATORS || mix_get_user_team(i) == CsTeams:MIX_TEAM_UNASSIGNED)
					continue;
			}
			case MIX_PAGE_CHOOSE_CUT:
			{
				if (mix_get_user_team(i) == CsTeams:MIX_TEAM_CT || mix_get_user_team(i) == CsTeams:MIX_TEAM_TERRORISTS)
					continue;
			}
		}
		
		num_to_str((i + 1), num, charsmax(num));
		menu_additem(menu, g_mix_user_name[i], num);
	}
	
	menu_setprop(menu, MPROP_BACKNAME, "Atrás");
	menu_setprop(menu, MPROP_NEXTNAME, "Siguiente");
	menu_setprop(menu, MPROP_EXITNAME, "Cerrar");
	
	if (pev_valid(id) == PRIVATE_DATA_SAFE)
		set_pdata_int(id, PRIVATE_DATA_CSMENUCODE, 0, PRIVATE_DATA_LINUX);
	
	menu_display(id, menu);
}

public handled_show_player_selection(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu);
		mix_mode_spectator_options(id);
		return PLUGIN_HANDLED;
	}
	
	static num[3];
	static access;
	static itemid;
	
	menu_item_getinfo(menu, item, access, num, charsmax(num), _, _, access);
	itemid = str_to_num(num) - 1;
	
	menu_destroy(menu);
	
	if (is_user_connected(itemid))
	{
		switch(g_mix_page[id])
		{
			case MIX_PAGE_CHOOSE_CT: 
			{
				chat_color(0, "%s !g%s!y seleccionó al usuario !g%s!y para el equipo !gCT!y.", g_mix_prefix, g_mix_user_name[id], g_mix_user_name[itemid]);
				
				mix_team_change(itemid, MIX_TEAM_CT);
				// engclient_cmd(itemid, "jointeam 2");
				// engclient_cmd(itemid, "joinclass 5");
				mix_mode_spectator_options(id);
				
				if (is_user_alive(itemid))
					user_silentkill(itemid);
			}
			case MIX_PAGE_CHOOSE_TT:
			{
				chat_color(0, "%s !g%s!y seleccionó al usuario !g%s!y para el equipo !gTT!y.", g_mix_prefix, g_mix_user_name[id], g_mix_user_name[itemid]);
				mix_team_change(itemid, MIX_TEAM_TERRORISTS);
				// engclient_cmd(itemid, "jointeam 1");
				// engclient_cmd(itemid, "joinclass 5");
				mix_mode_spectator_options(id);
				
				if (is_user_alive(itemid))
					user_silentkill(itemid);
			}
			case MIX_PAGE_CHOOSE_SPEC:
			{
				chat_color(0, "%s !g%s!y seleccionó al usuario !g%s!y para el equipo !gSPEC!y.", g_mix_prefix, g_mix_user_name[id], g_mix_user_name[itemid]);
				entity_set_int(id, EV_INT_deadflag, DEAD_DEAD);
				mix_team_change(itemid, MIX_TEAM_SPECTATORS);
				mix_mode_spectator_options(id);
			}
			case MIX_PAGE_CHOOSE_CUT:
			{
				if ((mix_users_per_team(MIX_TEAM_CT) + mix_users_per_team(MIX_TEAM_TERRORISTS)) == 10)
				{
					chat_color(0, "%s !yTodos los usuarios fueorn seleccionados.", g_mix_prefix);
					return PLUGIN_HANDLED;
				}
				
				mix_team_change(itemid, mix_get_user_team(g_mix_chooser_cut));  
				g_mix_chooser_cut = (g_mix_chooser_cut == g_mix_chooser_cut_winner) ? g_mix_chooser_cut_loser : g_mix_chooser_cut_winner;
				
				ExecuteHamB(Ham_CS_RoundRespawn, itemid);
				
				#if defined MIX_TEST_C
					show_player_selection(g_mix_cristian, "Seleccioná a un usuario");
				#else
					show_player_selection(g_mix_chooser_cut, "Seleccioná a un usuario");
				#endif
			}
			case MIX_PAGE_KICK:
			{
				server_cmd("kick #%d ^"Fuiste expulsado del servidor^"", get_user_userid(itemid));
				chat_color(0, "%s !g%s!y expulsó a !g%s!y.", g_mix_prefix, g_mix_user_name[id], g_mix_user_name[itemid]);
			}
		} 
		
	}
	else
		chat_color(id, "%s !yEl usuario se desconectó del servidor.", g_mix_prefix);
	
	return PLUGIN_HANDLED;
}

public clcmd_changeteam(id)
{
	if (!g_mix_started)
		return PLUGIN_CONTINUE;
	
	if (mix_get_user_team(id) == CsTeams:MIX_TEAM_SPECTATORS || mix_get_user_team(id) == CsTeams:MIX_TEAM_UNASSIGNED || !get_pcvar_num(g_mix_cvar[CVAR_MIX_CLOSED_BLOCK_TEAM]))
	{
		show_menu_team(id);
		return PLUGIN_HANDLED;
	}
		
	chat_color(id, "%s !yEl cambio de equipos está bloqueado.", g_mix_prefix);
	return PLUGIN_HANDLED;
}

show_menu_team(id)
{
	static menu, sztext[128];
	format(sztext, charsmax(sztext), "\d%s \yMenú de equipos^n\dMix número \y#%d - \dRonda \y%d - \dCT's \r%d \d| \r%d \dTT's", g_mix_prefix_menu, g_mix_id, g_mix_rounds, (g_mix_stats[ARRAY_MIX_SCORE_CT_HF] + g_mix_stats[ARRAY_MIX_SCORE_CT_HS]), (g_mix_stats[ARRAY_MIX_SCORE_TT_HF] + g_mix_stats[ARRAY_MIX_SCORE_TT_HS]));
	
	menu = menu_create(sztext, "handled_show_menu_team");
	
	menu_additem(menu, "Terrorista", "1", 0, menu_makecallback("mix_check_team"));
	menu_additem(menu, "Counter-Terrorist^n", "2", 0, menu_makecallback("mix_check_team"));
	
	menu_setprop(menu, MPROP_EXITNAME, "Cerrar");
	menu_display(id, menu);
}

public mix_check_team(id, menu, item)
{
	if (!item)
		return (mix_users_per_team(MIX_TEAM_TERRORISTS) >= 5) ? ITEM_DISABLED : ITEM_ENABLED;
	else
		return (mix_users_per_team(MIX_TEAM_CT) >= 5) ? ITEM_DISABLED : ITEM_ENABLED;
}

public handled_show_menu_team(id, menu, item)
{
	menu_destroy(menu);
	
	switch(item)
	{
		case 0: 
		{
			engclient_cmd(id, "jointeam", "1");
			engclient_cmd(id, "joinclass", "5");
		}
		case 1: 
		{
			engclient_cmd(id, "jointeam", "2");
			engclient_cmd(id, "joinclass", "5");
		}
	}
	
	return PLUGIN_HANDLED;
}

public clcmd_say(id)
{
	static message[190];
	
	read_args(message, charsmax(message));
	remove_quotes(message);
	trim(message);
	
	replace_all(message, charsmax(message), "%", "");
	replace_all(message, charsmax(message), "!y", "");
	replace_all(message, charsmax(message), "!t", "");
	replace_all(message, charsmax(message), "!g", "");
	replace_all(message, charsmax(message), "#", "");
	
	if (message[0] == '.' || message[0] == '/' || message[0] == '!')
	{
		switch(message[1])
		{
			case 'm':
			{
				if (!is_user_admin(id))
					return PLUGIN_HANDLED;
				
				clcmd_mix_ultimate(id);
			}
			case 'r':
			{
				switch(message[2])
				{
					case 'r': 
					{
						chat_color(id, "%s !g%s!y reinició la ronda.", g_mix_prefix, g_mix_user_name[id]);
						set_cvar_num("sv_restart", 1);
						
						if (!g_mix_started)
							return PLUGIN_HANDLED;
						
						if (g_mix_overtime)
						{
							g_aux_score_ct = (g_mix_half == MIX_HALF_FIRST) ? g_mix_stats[ARRAY_MIX_SCORE_CT_HF_OVERTIME] : g_mix_stats[ARRAY_MIX_SCORE_CT_HS_OVERTIME];
							g_aux_score_tt = (g_mix_half == MIX_HALF_FIRST) ? g_mix_stats[ARRAY_MIX_SCORE_TT_HF_OVERTIME] : g_mix_stats[ARRAY_MIX_SCORE_TT_HS_OVERTIME];
						}
						else
						{
							g_aux_score_ct = (g_mix_half == MIX_HALF_FIRST) ? g_mix_stats[ARRAY_MIX_SCORE_CT_HF] : g_mix_stats[ARRAY_MIX_SCORE_CT_HS];
							g_aux_score_tt = (g_mix_half == MIX_HALF_FIRST) ? g_mix_stats[ARRAY_MIX_SCORE_TT_HF] : g_mix_stats[ARRAY_MIX_SCORE_TT_HS];
						}
						
						static i;
							
						for (i = 1; i <= g_maxplayers; i++)
						{
							if (!is_user_connected(i))
								continue;
							
							if (mix_get_user_team(i) == CsTeams:MIX_TEAM_UNASSIGNED || mix_get_user_team(i) == CsTeams:MIX_TEAM_SPECTATORS)
								continue;
							
							g_aux_users_money[i] = get_pdata_int(i, PRIVATE_DATA_MONEY);
							g_aux_users_deaths[i] = get_pdata_int(i, PRIVATE_DATA_DEATHS);
							g_aux_users_frags[i] = get_user_frags(i);
						}
					}
					case 'e': mix_show_result(.id = id, .mix = (g_mix_started) ? 1 : 0);
					case 'h':
					{
						if (!g_mix_started)
						{
							chat_color(id, "%s !ySolo se puede utilizar si se está jugando un mix.", g_mix_prefix);
							return PLUGIN_HANDLED;
						}
						
						switch(g_mix_half)
						{
							case MIX_HALF_FIRST:
							{
								g_mix_stats[(g_mix_overtime) ? ARRAY_MIX_SCORE_CT_HF_OVERTIME : ARRAY_MIX_SCORE_CT_HF] = 0;
								g_mix_stats[(g_mix_overtime) ? ARRAY_MIX_SCORE_TT_HF_OVERTIME : ARRAY_MIX_SCORE_TT_HF] = 0;
								chat_color(id, "%s !g%s!y reseteó la primera mitad del mix.", g_mix_prefix, g_mix_user_name[id]);
							}
							case MIX_HALF_SECOND:
							{
								g_mix_stats[(g_mix_overtime) ? ARRAY_MIX_SCORE_CT_HS_OVERTIME : ARRAY_MIX_SCORE_CT_HS] = 0;
								g_mix_stats[(g_mix_overtime) ? ARRAY_MIX_SCORE_TT_HS_OVERTIME : ARRAY_MIX_SCORE_TT_HS] = 0;
								chat_color(id, "%s !g%s!y reseteó la segunda mitad del mix.", g_mix_prefix, g_mix_user_name[id]);
							}
						}
						
						g_aux_score_ct = 0;
						g_aux_score_tt = 0;
						set_cvar_num("sv_restart", 1);
					}
				}
			}
			case 'c':
			{
				if (!is_user_admin(id))
					chat_color(0, "%s !g%s!y está pidiendo que desbloqueen el chat.", g_mix_prefix, g_mix_user_name[id]);
				else
				{
					set_pcvar_num(g_mix_cvar[CVAR_MIX_CLOSED_BLOCK_SAY], (get_pcvar_num(g_mix_cvar[CVAR_MIX_CLOSED_BLOCK_SAY]) == 1) ? 0 : 1);
					chat_color(0, "%s !g%s!y %s el chat.", g_mix_prefix, g_mix_user_name[id], (get_pcvar_num(g_mix_cvar[CVAR_MIX_CLOSED_BLOCK_SAY])) ? "deshabilitó" : "habilitó");
				}
			}
			case 'n':
			{
				if (!is_user_admin(id))
					return PLUGIN_HANDLED;
				
				set_pcvar_num(g_mix_cvar[CVAR_MIX_CLOSED_BLOCK_NAME], (get_pcvar_num(g_mix_cvar[CVAR_MIX_CLOSED_BLOCK_NAME]) == 1) ? 0 : 1);
				chat_color(0, "%s !g%s!y %s el cambio de nick.", g_mix_prefix, g_mix_user_name[id], (get_pcvar_num(g_mix_cvar[CVAR_MIX_CLOSED_BLOCK_NAME])) ? "deshabilitó" : "habilitó");
			}
			case 't':
			{
				if (message[2] == '1' || message[2] == '2')
				{
					static i;
					
					switch(message[2])
					{
						case '1':
						{
							for (i = 1; i <= g_maxplayers; i++)
							{
								if (!is_user_connected(i))
									continue;
								
								if (mix_get_user_team(i) != CsTeams:MIX_TEAM_TERRORISTS)
									continue;
								
								user_silentkill(i);
							}
						}
						case '2':
						{
							for (i = 1; i <= g_maxplayers; i++)
							{
								if (!is_user_connected(i))
									continue;
								
								if (mix_get_user_team(i) != CsTeams:MIX_TEAM_CT)
									continue;
								
								user_silentkill(i);
							}
						}
					}
					return PLUGIN_HANDLED;
				}
				
				if (!is_user_admin(id))
					chat_color(0, "%s !g%s!y está pidiendo que desbloqueen el cambio de equipos.", g_mix_prefix, g_mix_user_name[id]);
				else
				{
					set_pcvar_num(g_mix_cvar[CVAR_MIX_CLOSED_BLOCK_TEAM], (get_pcvar_num(g_mix_cvar[CVAR_MIX_CLOSED_BLOCK_TEAM]) == 1) ? 0 : 1);
					chat_color(0, "%s !g%s!y %s el cambio de equipos.", g_mix_prefix, g_mix_user_name[id], (get_pcvar_num(g_mix_cvar[CVAR_MIX_CLOSED_BLOCK_TEAM])) ? "deshabilitó" : "habilitó");
				}
			}
			case 's':
			{
				switch(message[2])
				{
					case 'e':
					{
						if (!g_mix_cut || (g_mix_chooser_cut != id && g_mix_page[id] != MIX_PAGE_CHOOSE_CUT))
							return PLUGIN_HANDLED;
					
						show_player_selection(id, "Seleccioná a un usuario");
					}
					case 't': { show_mix_stats(id, .mix_stats = 0); }
				}
			}
		}
		
		return PLUGIN_HANDLED;
	}
	
	if (!g_mix_started)
		return PLUGIN_CONTINUE;
	
	if (!get_pcvar_num(g_mix_cvar[CVAR_MIX_CLOSED_BLOCK_SAY]))
		return PLUGIN_CONTINUE;
	
	if (is_user_admin(id))
		return PLUGIN_CONTINUE;
	
	chat_color(id, "%s !yEl chat está bloqueado. Escribí !g/chat!y para pedir que lo habiliten.", g_mix_prefix);
	return PLUGIN_HANDLED;
}

clcmd_mix_ultimate(id)
{
	if (!is_user_admin(id))
		return;
	
	static menu, sztext[72];
	
	format(sztext, charsmax(sztext), "\d%s \yMix Ultimate \d%s^n\yDesarrollado por \d%s", g_mix_prefix_menu, PLUGIN_VERSION, PLUGIN_AUTHOR);
	menu = menu_create(sztext, "handled_clcmd_mix_ultimate");
	
	menu_additem(menu, "Modo público", "1", 0);
	menu_additem(menu, "Modo práctica", "2", 0);
	menu_additem(menu, "Modo cerrado", "3", 0, menu_makecallback("mix_check_mode_closed"));
	menu_additem(menu, "Modo rates", "4", 0);
	menu_additem(menu, "Modo vale", "5", 0, menu_makecallback("mix_check_mode_closed"));
	menu_additem(menu, "Todos a espectador^n", "6", 0);
	menu_additem(menu, "\yMás opciones", "7", 0);
	
	menu_setprop(menu, MPROP_EXITNAME, "Salir");
	menu_display(id, menu);
}

public mix_check_mode_closed(id, menu, item)
{
	switch(item)
	{
		case 2:
		{
			if (g_mix_started)
				return ITEM_DISABLED;
		}
		case 4:
		{
			if (!get_pcvar_num(g_mix_cvar[CVAR_MIX_ENABLE]) || ((mix_users_per_team(MIX_TEAM_CT) + mix_users_per_team(MIX_TEAM_TERRORISTS)) < 10) || g_mix_started)
				return ITEM_DISABLED;
		}
	}
	
	return ITEM_ENABLED;
}

public handled_clcmd_mix_ultimate(id, menu, item)
{
	menu_destroy(menu);
	
	static i;
	
	switch(item)
	{
		case MENU_EXIT: return PLUGIN_HANDLED;
		case MIX_MODE_PUBLIC:
		{
			for (i = 0; i < sizeof(PUBLIC_CFG); i++)
				server_cmd(PUBLIC_CFG[i]);
			
			chat_color(0, "%s !g%s!y ejecutó el modo público.", g_mix_prefix, g_mix_user_name[id]);
			set_pcvar_num(g_mix_cvar[CVAR_MIX_ENABLE], 0);
			
			if (task_exists(TASK_MIX_ULTIMATE_VALE))
				remove_task(TASK_MIX_ULTIMATE_VALE);
			
			if (task_exists(TASK_MIX_ULTIMATE_STRUCT))
				remove_task(TASK_MIX_ULTIMATE_STRUCT);
			
			show_message(0, 0, 255, "Servidor en modo público");
			set_cvar_string("sv_password", "");
			set_task(1.25, "server_restartround");
			
			if (g_mix_started)
				g_mix_started = 0;			
		}
		case MIX_MODE_PRACTICAL:
		{
			for (i = 0; i < sizeof(PRACTIQUE_CFG); i++)
				server_cmd(PRACTIQUE_CFG[i]);
			chat_color(0, "%s !g%s!y ejecutó el modo práctica.", g_mix_prefix, g_mix_user_name[id]);
			set_pcvar_num(g_mix_cvar[CVAR_MIX_ENABLE], 0);
			
			if (task_exists(TASK_MIX_ULTIMATE_VALE))
				remove_task(TASK_MIX_ULTIMATE_VALE);
			
			if (task_exists(TASK_MIX_ULTIMATE_STRUCT))
				remove_task(TASK_MIX_ULTIMATE_STRUCT);
			
			show_message(255, 0, 255, "Servidor en modo práctica");
			set_task(1.25, "server_restartround");
			
			if (g_mix_started)
				g_mix_started = 0;
		}
		case MIX_MODE_CLOSED:
		{
			if ((mix_users_per_team(MIX_TEAM_CT) + mix_users_per_team(MIX_TEAM_TERRORISTS)) < 10)
			{
				chat_color(id, "%s !yNo hay suficientes jugadores para iniciar el modo cerrado.", g_mix_prefix);
				clcmd_mix_ultimate(id);
				return PLUGIN_HANDLED;
			}
			
			for (i = 0; i < sizeof(CLOSED_CFG); i++)
				server_cmd(CLOSED_CFG[i]);
			
			chat_color(0, "%s !g%s!y ejecutó el modo cerrado.", g_mix_prefix, g_mix_user_name[id]);

			show_message(255, 0, 0, "Servidor en modo cerrado");
			
			g_mix_mode_public = 0;
			set_pcvar_num(g_mix_cvar[CVAR_MIX_ENABLE], 1);
			set_task(1.25, "server_restartround");
		}
		case MIX_MODE_RATES:
		{
			for (i = 0; i < sizeof(RATES_CFG); i++)
				server_cmd("amx_cvar %s", RATES_CFG[i]); 

			chat_color(0, "%s !g%s!y ejecutó los rates.", g_mix_prefix, g_mix_user_name[id]);
			chat_color(id, "%s !yElegí un mapa.", g_mix_prefix);
			
			show_message(0, 255, 0, "Los rates del servidor^nfueron ejecutados");
			
			show_maps(id);
			return PLUGIN_HANDLED;
		}
		case MIX_MODE_VALE:
		{
			remove_task(TASK_MIX_ULTIMATE_VALE);
			set_task(1.0, "mix_ultimate_vale", TASK_MIX_ULTIMATE_VALE, _, _, "a", 5);
			
			server_cmd("amx_off");
			
			g_mix_countdown = 5;
			
			remove_task(TASK_MIX_ULTIMATE_STRUCT);
			set_task((float(g_mix_countdown) + 1.0), "mix_ultimate_struct", TASK_MIX_ULTIMATE_STRUCT);
			
			chat_color(0, "%s !g%s!y ejecutó el vale.", g_mix_prefix, g_mix_user_name[id]);
			g_mix_structure = MIX_RESTART_ONE;
		}
		case MIX_MODE_SPECTATOR:
		{
			mix_mode_spectator_options(id);
			return PLUGIN_HANDLED;
		}
		case MIX_MODE_OPTIONS:
		{
			show_more_options(id);
			return PLUGIN_HANDLED;
		}
	}
	
	clcmd_mix_ultimate(id);
	return PLUGIN_HANDLED;
}

mix_mode_spectator_options(id)
{
	static menu;
	menu = menu_create("Opción de selección", "handled_mix_mode_spectator_options");
	
	menu_additem(menu, "Todos a espectador^n", "1", 0, menu_makecallback("mix_check_all_spectators"));
	menu_additem(menu, "Seleccionar usuario para el equipo CT", "2", 0);
	menu_additem(menu, "Seleccionar usuario para el equipo TT", "3", 0);
	menu_additem(menu, "Seleccionar usuario para el equipo SPEC^n", "4", 0);
	menu_additem(menu, "Seleccionar a dos usuario al azar", "5", 0, menu_makecallback("mix_check_all_spectators"));
	menu_additem(menu, "\yModo duelo", "6", 0);
	
	menu_setprop(menu, MPROP_EXITNAME, "Salir");
	menu_display(id, menu);
}

public mix_check_all_spectators(id, menu, item)
{
	if (g_mix_started)
		return ITEM_DISABLED;

	switch(item)
	{
		case 0:
		{
			if ((!mix_users_per_team(MIX_TEAM_CT) && !mix_users_per_team(MIX_TEAM_TERRORISTS)))
				return ITEM_DISABLED;
		}
		case 4:
		{
			if ((mix_users_per_team(MIX_TEAM_CT) || mix_users_per_team(MIX_TEAM_TERRORISTS)))
				return ITEM_DISABLED;
		}
	}
	
	return ITEM_ENABLED;
}

public handled_mix_mode_spectator_options(id, menu, item)
{
	menu_destroy(menu);
	
	switch(item)
	{
		case MENU_EXIT:
		{
			clcmd_mix_ultimate(id);
			return PLUGIN_HANDLED;
		}
		case 0:
		{
			static i;
			
			show_message(255, 255, 0, "Todos para el equipo de espectador", .duration = 6.0);
			
			for (i = 1; i <= g_maxplayers; i++)
			{
				if (!is_user_connected(i))
					continue;
				
				entity_set_int(i, EV_INT_deadflag, DEAD_DEAD);
				mix_team_change(i, MIX_TEAM_SPECTATORS);
				
				if (g_mix_page[id])
					g_mix_page[id] = 0;
			}
		}
		case 1: 
		{
			g_mix_page[id] = MIX_PAGE_CHOOSE_CT;
			show_player_selection(id, "Seleccionar usuario para el equipo CT");
			return PLUGIN_HANDLED;
		}
		case 2: 
		{	
			g_mix_page[id] = MIX_PAGE_CHOOSE_TT;
			show_player_selection(id, "Seleccionar usuario para el equipo TT");
			return PLUGIN_HANDLED;
		}
		case 3:
		{
			g_mix_page[id] = MIX_PAGE_CHOOSE_SPEC;
			show_player_selection(id, "Seleccionar usuario para el equipo SPEC");
			return PLUGIN_HANDLED;
		}
		case 4: 
		{
			chat_color(0, "%s !g%s!y seleccionó a dos usuarios al azar.", g_mix_prefix, g_mix_user_name[id]);
			select_random_player();
		}
		case 5:
		{
			if (mix_users_per_team(MIX_TEAM_CT) == 1 && mix_users_per_team(MIX_TEAM_TERRORISTS) == 1)
			{
				chat_color(0, "%s !g%s!y habilitó el !gmodo duelo!y.", g_mix_prefix, g_mix_user_name[id]);
				chat_color(0, "%s !yAhora los usuarios que corten, podrán elegir a sus propios jugadores.", g_mix_prefix);
				g_mix_cut = 1;
			}
			else
				chat_color(id, "%s !yPara habilitar el modo duelo, tiene que haber un solo un jugador en cada equipo.", g_mix_prefix);
		}
	}
	
	mix_mode_spectator_options(id);
	return PLUGIN_HANDLED;
}

select_random_player()
{
	g_mix_structure = MIX_CHOOSER_CUT;
	
	remove_task(TASK_MIX_ULTIMATE_STRUCT);
	set_task(5.0, "mix_ultimate_struct", TASK_MIX_ULTIMATE_STRUCT);
	show_message(255, 255, 0, "En 5 segundos se escogerán a dos jugadores al azar");
}

public server_restartround()
	set_cvar_num("sv_restart", 1);

show_more_options(id)
{
	static menu;
	menu = menu_create("\yMás opciones", "handled_show_more_options");
	
	menu_additem(menu, "Cambiar de mapa", "1", 0);
	menu_additem(menu, "Finalizar mix^n", "2", 0, menu_makecallback("mix_check_started"));
	
	menu_additem(menu, "Estadísticas", "3", 0);
	menu_additem(menu, "Expulsar usuario / equipo", "4", 0);
	
	menu_setprop(menu, MPROP_EXITNAME, "Volver al menú anterior");
	menu_display(id, menu);
}

public mix_check_started(id, menu, item)
{
	if (!g_mix_started)
		return ITEM_DISABLED;
	
	return ITEM_ENABLED;
}

public handled_show_more_options(id, menu, item)
{
	menu_destroy(menu);
	
	switch(item)
	{
		case MENU_EXIT: clcmd_mix_ultimate(id);
		case 0: show_maps(id);
		case 1: mix_answer(id);
		case 2: show_stats(id);
		case 3: show_menu_kick(id);
	}
	
	return PLUGIN_HANDLED;
}

show_maps(id)
{
	static menu, i, num[3], maps[32];
	menu = menu_create("\yCambiar de mapa", "handled_show_maps");
	
	for (i = 0; i < ArraySize(g_array_maps); i++)
	{
		ArrayGetString(g_array_maps, i, maps, charsmax(maps));
		trim(maps);
		
		if (!is_map_valid(maps))
			continue;
		
		num_to_str((i + 1), num, charsmax(num));
		menu_additem(menu, maps, num);
	}
	
	menu_setprop(menu, MPROP_BACKNAME, "Atrás");
	menu_setprop(menu, MPROP_NEXTNAME, "Siguiente");
	menu_setprop(menu, MPROP_EXITNAME, "Volver");
	
	menu_display(id, menu);
}

public handled_show_maps(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu);
		show_more_options(id);
		return PLUGIN_HANDLED;
	}
	
	static num[3];
	static access;
	static map[32];
	
	menu_item_getinfo(menu, item, access, num, charsmax(num), map, charsmax(map), access);
	
	message_begin(MSG_ALL, SVC_INTERMISSION);
	message_end();
	
	chat_color(0, "%s !g%s!y cambió el mapa a !g%s!y.", g_mix_prefix, g_mix_user_name[id], map);
	set_task(2.0, "mix_change_map", _, map, charsmax(map));
	
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

public mix_change_map(const map[])
	server_cmd("changelevel %s", map);

mix_answer(id)
{
	static menu[128];
	format(menu, charsmax(menu), "\y¿Estás seguro de finalizar el mix?^n^n^n\r1. \wSí^n\r2. \wNo");
	
	show_menu(id, (1<<0)|(1<<1), menu, FM_NULLENT, "Handled Mix Answer");
}

public handled_mix_answer(id, key)
{
	if (!key)
		mix_finish();
	
	return PLUGIN_HANDLED;
}

show_stats(id)
{
	static menu; 
	menu = menu_create("\yEstadísticas", "handled_show_stats");
	
	menu_additem(menu, "Estadísticas de los mapas jugados", "1", 0);
	menu_additem(menu, "\yUsuarios que hicieron TK^n", "2", 0);
	
	menu_additem(menu, "\rUsuarios desconectados", "3", 0);
	
	menu_setprop(menu, MPROP_EXITNAME, "Volver");
	menu_display(id, menu);
}

public handled_show_stats(id, menu, item)
{
	menu_destroy(menu);
	
	switch(item)
	{
		case MENU_EXIT: show_more_options(id);
		case 0: show_mix_stats(id, .mix_stats = 0);
		case 1: show_users_stats(id);
		case 2: show_users_disconnected_stats(id);
	}
	
	return PLUGIN_HANDLED;
}

show_mix_stats(id, mix_stats, select = 0)
{
	if (mix_stats)
	{
		static menu[512], stats[ARRAY_MIX_STATS_STRUCT], keys;
		ArrayGetArray(g_array_stats, select, stats);
		
		if ((get_user_flags(id) & ADMIN_RCON))
			keys = (1<<0)|(1<<1)|(1<<2)|(1<<9);
		else
			keys = (1<<0)|(1<<1)|(1<<9);
		
		format(menu, charsmax(menu), "\yEstadísticas del mix \d[%s]^n^n\r1. \wVer equipo CT^n\r2. \wVer equipo TT^n\r3. \%sBorrar estadística^n^n\r* \dMix número: \y#%d^n\r* \dRondas: \y%d^n\r* \dInicio del mix: \y%s^n\r* \dFinal del mix: \y%s^n\r* \dTiempo jugado: \y%s^n^n\r- \wPrimera mitad^n\r* \dCTs \y%d\d | \y%d \dTTs^n^n\r- \wSegunda mitad^n\r* \dTTs \y%d \d(\y+\d%d)\d | \y%d \d(\y+\d%d) \dCTs ^n^n\r- \wResultado final^n\r* \dTTs \r%d\d | \r%d \dCTs^n^n\r0. \wVolver", 
		stats[ARRAY_MIX_MAP], (get_user_flags(id) & ADMIN_RCON) ? "y" : "d", stats[ARRAY_MIX_ID], stats[ARRAY_MIX_ROUNDS], stats[ARRAY_MIX_DATE_STARTED], stats[ARRAY_MIX_DATE_FINISH], mix_systime_calculated(stats[ARRAY_MIX_SYSTIME]), stats[ARRAY_MIX_SCORE_TT_HF], stats[ARRAY_MIX_SCORE_CT_HF], stats[ARRAY_MIX_SCORE_TT_HS], stats[ARRAY_MIX_SCORE_TT_HF], stats[ARRAY_MIX_SCORE_CT_HS], stats[ARRAY_MIX_SCORE_CT_HF], stats[ARRAY_MIX_SCORE_TT_TOTAL], stats[ARRAY_MIX_SCORE_CT_TOTAL]);
		
		show_menu(id, keys, menu, FM_NULLENT, "Handled Show Mix Stats Select");
		return PLUGIN_HANDLED;
	}
	
	static menu, i, num[3], sztext[128], stats[ARRAY_MIX_STATS_STRUCT];
	menu = menu_create("\yEstadísticas de los mapas jugados", "handled_show_mix_stats");
	
	for (i = 0; i < ArraySize(g_array_stats); i++)
	{
		ArrayGetArray(g_array_stats, i, stats);
		num_to_str((i + 1), num, charsmax(num));
		format(sztext, charsmax(sztext), "%s \r[\dCTs \r%d\d | \r%d \dTTs\r]", stats[ARRAY_MIX_MAP], stats[ARRAY_MIX_SCORE_CT_TOTAL], stats[ARRAY_MIX_SCORE_TT_TOTAL]);
		menu_additem(menu, sztext, num);
	}
	
	menu_setprop(menu, MPROP_BACKNAME, "Atrás");
	menu_setprop(menu, MPROP_NEXTNAME, "Siguiente");
	menu_setprop(menu, MPROP_EXITNAME, (is_user_admin(id)) ? "Volver" : "Cerrar");
	menu_display(id, menu);
	
	return PLUGIN_HANDLED;
}

public handled_show_mix_stats(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		if (is_user_admin(id))
			show_stats(id);
		
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	static num[3];
	static access;
	static itemid;
	
	menu_item_getinfo(menu, item, access, num, charsmax(num), _, _, access);
	itemid = str_to_num(num) - 1;
	
	menu_destroy(menu);
	
	g_mix_page_result[id] = itemid;
	show_mix_stats(id, .mix_stats = 1, .select = itemid);	
	return PLUGIN_HANDLED;
}

public handled_show_mix_stats_select(id, key)
{
	switch(key)
	{
		case 0: show_mix_user_stats(id, .team = _:MIX_TEAM_CT);
		case 1: show_mix_user_stats(id, .team = _:MIX_TEAM_TERRORISTS);
		case 2: mix_answer_delete_stats(id);
		case 9: show_mix_stats(id, .mix_stats = 0);
	}
	
	return PLUGIN_HANDLED;
}

show_mix_user_stats(id, team)
{
	static menu[512], i, stats[ARRAY_MIX_STATS_STRUCT], name[5][32], szfrags[2][5][3], szdeaths[2][5][3], add[320], frags[2][5], deaths[2][5], len,
	users, frags_hf, frags_hs;
	
	ArrayGetArray(g_array_stats, g_mix_page_result[id], stats);
	
	switch(team)
	{
		case MIX_TEAM_CT: 
		{
			users = ARRAY_MIX_USERS_CT;
			frags_hf = ARRAY_MIX_FRAGS_CT_HF;
			frags_hs = ARRAY_MIX_FRAGS_CT_HS;			
		}
		case MIX_TEAM_TERRORISTS:
		{
			users = ARRAY_MIX_USERS_TT;
			frags_hf = ARRAY_MIX_FRAGS_TT_HF;
			frags_hs = ARRAY_MIX_FRAGS_TT_HS;
		}
	}
	
	parse(stats[users], name[0], 31, name[1], 31, name[2], 31, name[3], 31, name[4], 31);
	parse(stats[frags_hf], szfrags[0][0], 2, szdeaths[0][0], 2, szfrags[0][1], 2, szdeaths[0][1], 2, szfrags[0][2], 2, szdeaths[0][2], 2, szfrags[0][3], 2, szdeaths[0][3], 2, szfrags[0][4], 2, szdeaths[0][4], 2);
	parse(stats[frags_hs], szfrags[1][0], 2, szdeaths[1][0], 2, szfrags[1][1], 2, szdeaths[1][1], 2, szfrags[1][2], 2, szdeaths[1][2], 2, szfrags[1][3], 2, szdeaths[1][3], 2, szfrags[1][4], 2, szdeaths[1][4], 2);
	
	len = 0;
	add[0] = EOS;
	
	for (i = 0; i < 5; i++)
	{
		frags[0][i] = str_to_num(szfrags[0][i]);
		frags[1][i] = str_to_num(szfrags[1][i]);
		
		deaths[0][i] = str_to_num(szdeaths[0][i]);
		deaths[1][i] = str_to_num(szdeaths[1][i]);
		
		len += formatex(add[len], charsmax(add) - len, "\w%s \r- \y[\d%d \y/ \d%d\y] \y-|- \y[\d%d \y/ \d%d\y]^n", name[i], frags[0][i], deaths[0][i], frags[1][i], deaths[1][i]);
	}
	
	format(menu, charsmax(menu), "\yEstadísticas de los usuarios del equipo \d%s^n^n\r* \dNick \r- \y[\dFrags \y/ \dMuertes\y] \y-|- \dPrimera mitad \y- \dSegunda mitad^n^n%s^n^n^n\r0. \wVolver", (team == _:MIX_TEAM_CT) ? "CT" : "TT", add);
	
	show_menu(id, (1<<9), menu, FM_NULLENT, "Handled Show Mix User Stats");
	return PLUGIN_HANDLED;
}

public handled_show_mix_user_stats(id, key)
{
	if (key == 9)
		show_mix_stats(id, .mix_stats = 1);
	
	return PLUGIN_HANDLED;
}

mix_answer_delete_stats(id)
{
	static menu[128];
	format(menu, charsmax(menu), "\y¿Estás seguro de borrar las estadísticas del mix número \y#%d?^n^n\r1. \wSí^n\r2. \wNo^n^n^n\r0. \wVolver", (g_mix_page_result[id] + 1));

	show_menu(id, (1<<0)|(1<<1)|(1<<9), menu, FM_NULLENT, "Handled Mix Delete Stats");
	return PLUGIN_HANDLED;
}

public handled_mix_answer_delete_stats(id, key)
{
	switch(key)
	{
		case 0: 
		{
			new Handle:query;
			query = SQL_PrepareQuery(g_sql_connection, "DELETE FROM `sql_mix_table` WHERE `mix_id` = '%d';", (g_mix_page_result[id] + 1));
			
			if (!SQL_Execute(query))
				sql_query_error(query);
			else
			{
				g_mix_id--;
				ArrayDeleteItem(g_array_stats, g_mix_page_result[id]);
				show_mix_stats(id, .mix_stats = 0);
				SQL_FreeHandle(query);
				
				query = SQL_PrepareQuery(g_sql_connection, "UPDATE `sql_mix_table` SET `mix_id` = (`mix_id` - 1) WHERE mix_id > '%d';", (g_mix_page_result[id] + 1));
				
				if (!SQL_Execute(query))
					sql_query_error(query);
				else
				{
					chat_color(id, "%s !yLas estadísticas del mix número !g#%d!y fueron borradas.", g_mix_prefix, (g_mix_page_result[id] + 1));
					SQL_FreeHandle(query);
				}
			}
		}
		case 9: show_mix_stats(id, .mix_stats = 1);
	}
	
	return PLUGIN_HANDLED;
}

show_users_stats(id, stats = 0)
{
	static array_stats[ARRAY_USERS_STATS_STRUCT];
	
	if (stats)
	{
		static menu[256],  keys;
		ArrayGetArray(g_array_users_tks, g_mix_page_result[id], array_stats);
		TrieGetArray(g_trie_users_tks, array_stats[ARRAY_USER_NAME], array_stats, sizeof(array_stats));
		
		if ((get_user_flags(id) & ADMIN_RCON))
			keys = (1<<0)|(1<<9);
		else
			keys = (1<<9);
		
		g_mix_page_result_type[id] = 1;
		copy(g_mix_page_result_name[id], charsmax(g_mix_page_result_name[]), array_stats[ARRAY_USER_NAME]);
		
		format(menu, charsmax(menu), "\yEstadísticas del TK realizado por \d%s^n^n\y* \dFecha: \y%s^n\y* \dMapa: \y%s^n\y* \dIP: \y%s^n\y* \dEquipo: \y%s^n\r* \dMix número: \y#%d^n\r* \dRonda del mix: \y%d^n^n^n\r1. \%sBorrar estadística^n\r0. \wVolver", array_stats[ARRAY_USER_NAME], array_stats[ARRAY_USER_DATE], array_stats[ARRAY_USER_MAP], array_stats[ARRAY_USER_IP], array_stats[ARRAY_USER_TEAM], array_stats[ARRAY_MIX_ID], array_stats[ARRAY_MIX_ROUND], ((get_user_flags(id) & ADMIN_RCON)) ? "y" : "d");
		show_menu(id, keys, menu, FM_NULLENT, "Handled Users Stats");
		return;
	}
	
	static menu, i, sztext[128], num[3];
	menu = menu_create("\yUsuarios que hicieron TK", "handled_show_users_stats");
	
	ArraySortEx(g_array_users_tks, "ArraySort_Ex");
	
	for (i = 0; i < ArraySize(g_array_users_tks); i++)
	{
		ArrayGetArray(g_array_users_tks, i, array_stats);
		TrieGetArray(g_trie_users_tks, array_stats[ARRAY_USER_NAME], array_stats, sizeof(array_stats));
		
		num_to_str((i + 1), num, charsmax (num));
		format(sztext, charsmax(sztext), "%s \y(\d%d TK's)", array_stats[ARRAY_USER_NAME], array_stats[ARRAY_USER_TKS]);
		menu_additem(menu, sztext, num);
	}
	
	menu_setprop(menu, MPROP_BACKNAME, "Atrás");
	menu_setprop(menu, MPROP_NEXTNAME, "Siguiente");
	menu_setprop(menu, MPROP_EXITNAME, "Volver");
	
	menu_display(id, menu);
}

public handled_show_users_stats(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu);
		show_stats(id);
		return PLUGIN_HANDLED;
	}
	
	static num[3];
	static access;
	static itemid;
	
	menu_item_getinfo(menu, item, access, num, charsmax(num), _, _, access);
	itemid = str_to_num(num) - 1;
	
	menu_destroy(menu);
	
	g_mix_page_result[id] = itemid;
	show_users_stats(id, .stats = 1);
	return PLUGIN_HANDLED;
}

public handled_users_stats(id, key)
{
	switch(key)
	{
		case 0: user_answer(id, "TK realizado", g_mix_page_result_name[id]);
		case 9: show_users_stats(id);
	}
	
	return PLUGIN_HANDLED;
}

user_answer(id, const tittle[], const name[])
{
	static menu[128];
	format(menu, charsmax(menu), "\y¿Estás seguro de borrar esta estadística?^n\d%s: \y%s^n^n\r1. \wSí^n\r2. \wNo^n^n^n\r0. \wVolver", tittle, name);
	
	show_menu(id, (1<<0)|(1<<1)|(1<<9), menu, FM_NULLENT, "Handled User Answer");
}

public handled_user_answer(id ,key)
{
	switch(key)
	{
		case 0:
		{
			new Handle:query;
			query = SQL_PrepareQuery(g_sql_connection, "DELETE FROM `sql_mix_users` WHERE `user_name` = ^"%s^" AND `%s` > '0';", g_mix_page_result_name[id], (g_mix_page_result_type[id] == 1) ? "user_tks" : "user_disconnected");
			
			if (!SQL_Execute(query))
				sql_query_error(query);
			else
			{
				switch(g_mix_page_result_type[id])
				{
					case 1:
					{
						ArrayDeleteItem(g_array_users_tks, g_mix_page_result[id]);
						TrieDeleteKey(g_trie_users_tks, g_mix_page_result_name[id]);
						show_users_stats(id);
					}
					case 2:
					{
						ArrayDeleteItem(g_array_users_disconnected, g_mix_page_result[id]);
						TrieDeleteKey(g_trie_users_disconnected, g_mix_page_result_name[id]);
						show_users_stats(id);
					}
				}
				
				chat_color(id, "%s !yLas estadísticas de !g%s!y !t(%s) !yfueron borradas.", g_mix_prefix, g_mix_page_result_name[id], (g_mix_page_result_type[id] == 1) ? "TK's" : "desconexiones");
				SQL_FreeHandle(query);
			}
		}
		case 9:
		{
			switch(g_mix_page_result_type[id])
			{
				case 1: show_users_stats(id, .stats = 1);
				case 2: show_users_disconnected_stats(id, .stats = 1);
			}
		}
	}
	
	return PLUGIN_HANDLED;
}

show_users_disconnected_stats(id, stats = 0)
{
	static array_stats[ARRAY_USERS_STATS_STRUCT];
	
	if (stats)
	{
		static menu[512], keys;
		
		ArrayGetArray(g_array_users_disconnected, g_mix_page_result[id], array_stats);
		TrieGetArray(g_trie_users_disconnected, array_stats[ARRAY_USER_NAME], array_stats, sizeof(array_stats));
		
		if ((get_user_flags(id) & ADMIN_RCON))
			keys = (1<<0)|(1<<9);
		else
			keys = (1<<9);
		
		g_mix_page_result_type[id] = 2;
		copy(g_mix_page_result_name[id], charsmax(g_mix_page_result_name[]), array_stats[ARRAY_USER_NAME]);
		
		format(menu, charsmax(menu), "\yEstadísticas del usuario desconectado \d%s^n^n\y* \dFecha: \y%s^n\y* \dMapa: \y%s^n\y* \dIP: \y%s^n\y* \dEquipo: \y%s^n\r* \dMix número: \y#%d^n\r* \dRonda del mix: \y%d^n^n^n\r1. \%sBorrar estadística^n\r0. \wVolver", array_stats[ARRAY_USER_NAME], array_stats[ARRAY_USER_DATE], array_stats[ARRAY_USER_MAP], array_stats[ARRAY_USER_IP], array_stats[ARRAY_USER_TEAM], array_stats[ARRAY_MIX_ID], array_stats[ARRAY_MIX_ROUND], ((get_user_flags(id) & ADMIN_RCON)) ? "y" : "d");
		show_menu(id, keys, menu, FM_NULLENT, "Handled Show Disconnected Stats");
		
		return;
	}
	
	static menu, i, num[3], sztext[156];
	menu = menu_create("\yUsuarios desconectados", "handled_show_users_disconnected_stats");
	
	ArraySortEx(g_array_users_disconnected, "ArraySort_Ex");
	
	for (i = 0; i < ArraySize(g_array_users_disconnected); i++)
	{
		ArrayGetArray(g_array_users_disconnected, i, array_stats);
		TrieGetArray(g_trie_users_disconnected, array_stats[ARRAY_USER_NAME], array_stats, sizeof(array_stats));
		
		num_to_str((i + 1), num, charsmax(num));
		format(sztext, charsmax(sztext), "%s \r(\d%d %s)", array_stats[ARRAY_USER_NAME], array_stats[ARRAY_USER_DISCONNECTED], (array_stats[ARRAY_USER_DISCONNECTED] == 1) ? "desconexión" : "desconexiones");
		menu_additem(menu, sztext, num);
	}
	
	menu_setprop(menu, MPROP_BACKNAME, "Atrás");
	menu_setprop(menu, MPROP_NEXTNAME, "Siguiente");
	menu_setprop(menu, MPROP_EXITNAME, "Volver");
	
	menu_display(id, menu);
}

public ArraySort_Ex(Array:myarray, element1[], element2[])
{
	if (element1[ARRAY_USER_DISCONNECTED] > element2[ARRAY_USER_DISCONNECTED])
		return -1;
	else if (element1[ARRAY_USER_DISCONNECTED] < element2[ARRAY_USER_DISCONNECTED])
		return 1;
	
	if (element1[ARRAY_USER_TKS] > element2[ARRAY_USER_TKS])
		return -1;
	else if (element1[ARRAY_USER_TKS] < element2[ARRAY_USER_TKS])
		return 1;
	
	return 0;
}

public handled_show_users_disconnected_stats(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu);
		show_stats(id);
		return PLUGIN_HANDLED;
	}
	
	static num[3];
	static access;
	static itemid;
	
	menu_item_getinfo(menu, item, access, num, charsmax(num), _, _, access);
	itemid = str_to_num(num) - 1;
	
	menu_destroy(menu);
	
	g_mix_page_result[id] = itemid; 
	show_users_disconnected_stats(id, .stats = 1);
	return PLUGIN_HANDLED;
}

public handled_show_disconnected_stats(id, key)
{
	switch(key)
	{
		case 0: user_answer(id, "Usuario desconectado", g_mix_page_result_name[id]);
		case 9: show_users_disconnected_stats(id);
	}
	
	return PLUGIN_HANDLED;
}

show_menu_kick(id)
{
	static menu;
	menu = menu_create("\yExpulsar usuario / equipo", "handled_show_menu_kick");
	
	menu_additem(menu, "Expulsar usuario^n", "1", 0);
	menu_additem(menu, "Expulsar equipo \dTT", "2", 0);
	menu_additem(menu, "Expulsar equipo \dCT", "3", 0);
	menu_additem(menu, "Expulsar equipo \dSPEC", "4", 0);
	
	menu_setprop(menu, MPROP_EXITNAME, "Volver");
	menu_display(id, menu);
}

public handled_show_menu_kick(id, menu, item)
{
	menu_destroy(menu);
	
	switch(item)
	{
		case MENU_EXIT: 
		{
			show_more_options(id);
			return PLUGIN_HANDLED;
		}
		case 0: 
		{
			g_mix_page[id] = MIX_PAGE_KICK;
			show_player_selection(id, "Expulsar usuario");
			return PLUGIN_HANDLED;
		}
		case 1: 
		{
			static i;
			
			for (i = 1; i <= g_maxplayers; i++)
			{
				if (!is_user_connected(i))
					continue;
				
				if (mix_get_user_team(i) != CsTeams:MIX_TEAM_TERRORISTS)
					continue;
				
				server_cmd("kick #%d ^"Fuiste expulsado del servidor^"", get_user_userid(i));
			}
			
			chat_color(0, "%s !g%s!y expulsó al equipo !gTT!y.", g_mix_prefix, g_mix_user_name[id]);
		}
		case 2:
		{
			static i;
			
			for (i = 1; i <= g_maxplayers; i++)
			{
				if (!is_user_connected(i))
					continue;
				
				if (mix_get_user_team(i) != CsTeams:MIX_TEAM_CT)
					continue;
				
				server_cmd("kick #%d ^"Fuiste expulsado del servidor^"", get_user_userid(i));
			}
			
			chat_color(0, "%s !g%s!y expulsó al equipo !gCT!y.", g_mix_prefix, g_mix_user_name[id]);
		}
		case 3:
		{
			static i;
			
			for (i = 1; i <= g_maxplayers; i++)
			{
				if (!is_user_connected(i))
					continue;
				
				if (mix_get_user_team(i) != CsTeams:MIX_TEAM_SPECTATORS && mix_get_user_team(i) != MIX_TEAM_UNASSIGNED)
					continue;
				
				server_cmd("kick #%d ^"Fuiste expulsado del servidor^"", get_user_userid(i));
			}
			
			chat_color(0, "%s !g%s!y expulsó al equipo !gSPEC!y.", g_mix_prefix, g_mix_user_name[id]);
		}
	}
	
	show_menu_kick(id);
	return PLUGIN_HANDLED;
}
	
public mix_ultimate_vale()
{
	static num[6];
	num_to_word(g_mix_countdown, num, 5);
			
	client_cmd(0,"spk ^"fvox/%s^"", num);
	
	set_hudmessage(random_num(0, 255), random_num(0, 255), random_num(0, 255), -1.0, -1.0, 1, 6.0, 1.0);
	ShowSyncHudMsg(0, g_syncobj[MIX_ULTIMATE_COUNTDOWN], "El mix comenzará en %d segundo%s", g_mix_countdown, (g_mix_countdown == 1) ? "" : "s");
	
	g_mix_countdown--;
}

public mix_ultimate_struct()
{
	switch(g_mix_structure)
	{
		case MIX_RESTART_ONE: show_message(255, 255, 0, "Primero reinicio de ronda", .frame = 0.010);
		case MIX_RESTART_TWO: show_message(255, 255, 0, "Segundo reinicio de ronda", .frame = 0.010);
		case MIX_RESTART_THREE: show_message(255, 255, 0, "Tercer reinicio de ronda", .frame = 0.010);
		case MIX_STARTED:
		{
			client_cmd(0, "spk ^"%s^"", SOUND_MIX_STARTED);
			remove_task(TASK_MIX_ULTIMATE_STRUCT);
			
			g_mix_started = 1;
			g_mix_overtime = 0;
			
			g_mix_stats[ARRAY_MIX_SCORE_CT_HF] = 0;
			g_mix_stats[ARRAY_MIX_SCORE_TT_HF] = 0;
			
			g_mix_stats[ARRAY_MIX_SCORE_CT_HS] = 0;
			g_mix_stats[ARRAY_MIX_SCORE_TT_HS] = 0;
			
			g_aux_score_ct = 0;
			g_aux_score_tt = 0;
			
			
			g_mix_rounds = 0;
			
			g_mix_result[0] = EOS;
			
			new id, users_ct[256], users_tt[256], len_ct, len_tt, time[32]; 
			get_time("%d/%m/%Y - %H:%M:%S", time, charsmax(time));
			
			len_ct = 0;
			len_tt = 0;
			
			for (id = 1; id <= g_maxplayers; id++)
			{
				if (!is_user_connected(id))
					continue;
				
				switch(mix_get_user_team(id))
				{
					case MIX_TEAM_CT: len_ct += formatex(users_ct[len_ct], charsmax(users_ct) - len_ct, "^"%s^" ", g_mix_user_name[id]);
					case MIX_TEAM_TERRORISTS: len_tt += formatex(users_tt[len_tt], charsmax(users_tt) - len_tt, "^"%s^" ", g_mix_user_name[id]);
				}
			}
			
			copy(g_mix_stats[ARRAY_MIX_USERS_CT], charsmax(g_mix_stats[ARRAY_MIX_USERS_CT]), users_ct);
			copy(g_mix_stats[ARRAY_MIX_USERS_TT], charsmax(g_mix_stats[ARRAY_MIX_USERS_TT]), users_tt);
			copy(g_mix_stats[ARRAY_MIX_MAP], charsmax(g_mix_stats[ARRAY_MIX_MAP]), g_mapname);
			copy(g_mix_stats[ARRAY_MIX_DATE_STARTED], charsmax(g_mix_stats[ARRAY_MIX_DATE_STARTED]), time);
			
			replace_all(g_mix_stats[ARRAY_MIX_USERS_CT], charsmax(g_mix_stats[ARRAY_MIX_USERS_CT]), "'", "''");
			replace_all(g_mix_stats[ARRAY_MIX_USERS_TT], charsmax(g_mix_stats[ARRAY_MIX_USERS_TT]), "'", "''");
			
			g_mix_systime = get_systime();
			g_mix_id++;
			return PLUGIN_HANDLED;
		}
		case MIX_CHOOSER_CUT:
		{
			static id, users[33], user_selected, user_selection[2], j, num;
			j = 0;
			
			for (id = 1; id <= g_maxplayers; id++)
			{
				if (!is_user_connected(id))
					continue;
				
				users[j] = id;
				j++;
			}
			
			num = 0;
			
			while (num < 2)
			{
				user_selected = users[random_num(1, j)];
				
				#if defined MIX_TEST_C
					if (num == 0)
						user_selected = g_mix_cristian;
				#endif
				
				chat_color(0, "%s !g%s!y fue seleccionado para cortar el mix.", g_mix_prefix, g_mix_user_name[user_selected]);
				
				if (!num)
					mix_team_change(user_selected, MIX_TEAM_TERRORISTS, TT_MODELS[random(sizeof(TT_MODELS))]);
				else
					mix_team_change(user_selected, MIX_TEAM_CT, CT_MODELS[random(sizeof(CT_MODELS))]);
				
				ExecuteHamB(Ham_CS_RoundRespawn, user_selected);
				
				user_selection[num] = user_selected;
				num++;
			}
			
			static msg[78];
			format(msg, charsmax(msg), "%s y %s fueron seleccionados para cortar el mix", g_mix_user_name[user_selection[0]], g_mix_user_name[user_selection[1]]);
			
			show_message(255, 255, 0, msg);
			return PLUGIN_HANDLED;
		}
		case MIX_HALFS:
		{
			static password[32];
			
			get_cvar_string("mix_password", password, charsmax(password));
			set_cvar_string("sv_password", password);
			
			chat_color(0, "%s !gMix Ultimate !g%s!y desarrollado por !g%s!y.", g_mix_prefix, PLUGIN_VERSION, PLUGIN_AUTHOR);
			chat_color(0, "%s !yContraseña: !g%s!y.", g_mix_prefix, password);
			chat_color(0, "%s !yChat %s.", g_mix_prefix, (get_pcvar_num(g_mix_cvar[CVAR_MIX_CLOSED_BLOCK_SAY])) ? "deshabilitado" : "habilitado");
			chat_color(0, "%s !yCambio de nick %s.", g_mix_prefix, (get_pcvar_num(g_mix_cvar[CVAR_MIX_CLOSED_BLOCK_NAME])) ? "deshabilitado" : "habilitado");
			chat_color(0, "%s !yCambio de equipos %s.", g_mix_prefix, (get_pcvar_num(g_mix_cvar[CVAR_MIX_CLOSED_BLOCK_TEAM])) ? "deshabilitado" : "habilitado");
			
			static message[105];
			
			if (!g_mix_overtime)
			{
				format(message, charsmax(message), "Míx número #%d^nComenzó la %s mitad^nCT's %d | TT's %d^nGood Luck & Have Fun", g_mix_id, (g_mix_half == MIX_HALF_FIRST) ? "primera" : "segunda", (g_mix_stats[ARRAY_MIX_SCORE_CT_HF] + g_mix_stats[ARRAY_MIX_SCORE_CT_HS]), (g_mix_stats[ARRAY_MIX_SCORE_TT_HF] + g_mix_stats[ARRAY_MIX_SCORE_TT_HS]));
				show_message(0, 255, 0, message, .duration = 10.0, .effect = 2);
				return PLUGIN_HANDLED;
			}
			
			format(message, charsmax(message), "Míx número #%d^n=== OverTime ===^nComenzó la %s mitad del OverTime^nCT's %d (+%d) | TT's %d (+%d)", g_mix_id, (g_mix_half == MIX_HALF_FIRST) ? "primera" : "segunda", (g_mix_stats[ARRAY_MIX_SCORE_CT_HF] + g_mix_stats[ARRAY_MIX_SCORE_CT_HS]), (g_mix_stats[ARRAY_MIX_SCORE_CT_HF_OVERTIME] + g_mix_stats[ARRAY_MIX_SCORE_CT_HS_OVERTIME]), (g_mix_stats[ARRAY_MIX_SCORE_TT_HF] + g_mix_stats[ARRAY_MIX_SCORE_TT_HS]), (g_mix_stats[ARRAY_MIX_SCORE_TT_HF_OVERTIME] + g_mix_stats[ARRAY_MIX_SCORE_TT_HS_OVERTIME]));
			show_message(0, 255, 0, message, .duration = 10.0, .effect = 2);
			return PLUGIN_HANDLED;
		}
	}
	
	set_cvar_num("sv_restart", (g_mix_structure == MIX_RESTART_THREE) ? 3 : 1);
	g_mix_structure++;
	
	remove_task(TASK_MIX_ULTIMATE_STRUCT);
	set_task(3.0, "mix_ultimate_struct", TASK_MIX_ULTIMATE_STRUCT);
	
	return PLUGIN_HANDLED;
}

public show_mix_message()
{
	if (g_mix_rounds == get_pcvar_num(g_mix_cvar[CVAR_MIX_FINISH_HALF]) || (g_mix_rounds == get_pcvar_num(g_mix_cvar[CVAR_MIX_OVERTIME_ROUNDS]) && g_mix_overtime))
		return;
	
	static msg[100];
			
	if (g_mix_overtime)
		format(msg, charsmax(msg), "OVERTIME^nMíx número #%d^n%s mitad^nRonda %d^nCT's %d (+%d) | TT's %d (+%d)", g_mix_id, (g_mix_half == MIX_HALF_FIRST) ? "Primera" : "Segunda", g_mix_rounds_overtime, (g_mix_stats[ARRAY_MIX_SCORE_CT_HF] + g_mix_stats[ARRAY_MIX_SCORE_CT_HS]), (g_mix_stats[ARRAY_MIX_SCORE_CT_HF_OVERTIME] + g_mix_stats[ARRAY_MIX_SCORE_CT_HS_OVERTIME]), (g_mix_stats[ARRAY_MIX_SCORE_TT_HF] + g_mix_stats[ARRAY_MIX_SCORE_TT_HS]), (g_mix_stats[ARRAY_MIX_SCORE_TT_HF_OVERTIME] + g_mix_stats[ARRAY_MIX_SCORE_TT_HS_OVERTIME]));
	else
		format(msg, charsmax(msg), "Míx número #%d^n%s mitad^nRonda %d^nCT's %d | TT's %d", g_mix_id, (g_mix_half == MIX_HALF_FIRST) ? "Primera" : "Segunda", g_mix_rounds, (g_mix_stats[ARRAY_MIX_SCORE_CT_HF] + g_mix_stats[ARRAY_MIX_SCORE_CT_HS]), (g_mix_stats[ARRAY_MIX_SCORE_TT_HF] + g_mix_stats[ARRAY_MIX_SCORE_TT_HS]));
	
	show_message(0, 255, 0, msg);
}

show_message(red,  green, blue, const message[], Float:frame = 0.025, Float:x = -1.0, Float:y = 0.29, Float:duration = 3.5, effect = 2, syncobj = MIX_ULTIMATE_NOTICE)
{
	set_hudmessage(red, green, blue, x, y, effect, 0.1, frame, 0.025, duration, 1);
	ShowSyncHudMsg(0, g_syncobj[syncobj], message);
}

chat_color(id, const input[], any:...)
{
	static message[191];
	vformat(message, 190, input, 3);
	
	replace_all(message, 190, "!g", "^4");
	replace_all(message, 190, "!t", "^3");
	replace_all(message, 190, "!y", "^1");
	
	message_begin((id) ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, get_user_msgid("SayText"), .player = id);
	write_byte((id) ? id : 33);
	write_string(message);
	message_end();
}

mix_users_per_team(CsTeams:team)
{
	static id, users[_:MIX_TEAM_STRUCT];
	users[_:team] = 0;
	
	for (id = 1; id <= g_maxplayers; id++)
	{
		if (!is_user_connected(id))
			continue;
		
		if (mix_get_user_team(id) != team)
			continue;
		
		users[_:team]++;
	}
	
	return users[_:team];
}

mix_team_change(id, { CsTeams,_ }:team, { CsInternalModel,_ }:model = CS_DONTCHANGE)
{
	set_pdata_int(id, PRIVATE_DATA_TEAM, _:team);
	
	if (model)
		set_pdata_int(id, PRIVATE_DATA_INTERNAL_MODEL, _:model);
	
	dllfunc(DLLFunc_ClientUserInfoChanged, id);
	
	emessage_begin(MSG_ALL, g_mix_message_teaminfo);
	ewrite_byte(id);
	ewrite_string(MIX_TEAM_NAMES[team]);
	emessage_end();
	
	return PLUGIN_HANDLED;
}

CsTeams:mix_get_user_team(id, &{ CsInternalModel,_ }:model = CS_DONTCHANGE)
{
	model = CsInternalModel:get_pdata_int(id, PRIVATE_DATA_INTERNAL_MODEL);
	
	return CsTeams:get_pdata_int(id, PRIVATE_DATA_TEAM);
}

public message_showmenu(msgid, dest, id)
{
	if (!g_mix_started)
		return PLUGIN_CONTINUE;
	
	static message[32];
	get_msg_arg_string(4, message, charsmax(message));
	
	if (containi(message, "Team_Select") != -1)
	{
		show_menu_team(id);
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

public message_vguimenu(msgid, dest, id)
{
	if (!g_mix_started)
		return PLUGIN_CONTINUE;
	
	if (get_msg_arg_int(1) != 2)
	{
		show_menu_team(id);
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
		
}

public message_teamscore()
{
	message_begin(MSG_ALL, g_mix_message_teamscore);
	write_string("CT");
	write_short((g_mix_stats[ARRAY_MIX_SCORE_CT_HF] + g_mix_stats[ARRAY_MIX_SCORE_CT_HS]) + (g_mix_stats[ARRAY_MIX_SCORE_CT_HF_OVERTIME] + g_mix_stats[ARRAY_MIX_SCORE_CT_HS_OVERTIME]));
	message_end();
	
	message_begin(MSG_ALL, g_mix_message_teamscore);
	write_string("TERRORIST");
	write_short((g_mix_stats[ARRAY_MIX_SCORE_TT_HF] + g_mix_stats[ARRAY_MIX_SCORE_TT_HS]) + (g_mix_stats[ARRAY_MIX_SCORE_TT_HF_OVERTIME] + g_mix_stats[ARRAY_MIX_SCORE_TT_HS_OVERTIME]));
	message_end();
}

sql_query_error(Handle:query)
{
	static error[56];
	SQL_QueryError(query, error, 55);
        
	chat_color(0, "%s !yError: !g%s!y.", g_mix_prefix, error);
	server_print("Error de consola: %s", error);
	SQL_FreeHandle(query);
}

mix_systime_calculated(systime)
{
	static hours, minutes, seconds, time_calculated[40];
	
	hours = ((systime / 3600) % 24);
	minutes = ((systime / 60) % 60);
	seconds = (systime % 60);
	
	format(time_calculated, charsmax(time_calculated), "%d hora%s, %d minuto%s, %d segundo%s", hours, (hours == 1) ? "" : "s", minutes, (minutes == 1) ? "" : "s", seconds, (seconds == 1) ? "" : "s");
	return time_calculated;
}

mix_sqlx_init()
{
	if (!module_exists("sqlite"))
	{
		chat_color(0, "%s !yEl módulo !gsqlite!y no está cargado.", g_mix_prefix);
		return PLUGIN_HANDLED;
	}
	
	g_sql_htuple = SQL_MakeDbTuple("", "", "", SQL_MIX_DATABASE);
	
	static error, szerror[256];
	
	if (g_sql_htuple == Empty_Handle)
	{
		chat_color(0, "%s !yError de tupla: !g%s!y.", g_mix_prefix, szerror);
		return PLUGIN_HANDLED;
	}
	
	g_sql_connection = SQL_Connect(g_sql_htuple, error, szerror, charsmax(szerror));
	
	if (g_sql_connection == Empty_Handle)
	{
		chat_color(0, "%s !yError en la conexión !gSQLite!y.", g_mix_prefix);
		return PLUGIN_HANDLED;
	}
	
	new Handle:query;
	query = SQL_PrepareQuery(g_sql_connection, "SELECT * FROM `sql_mix_table`");
	
	if (!SQL_Execute(query))
		sql_query_error(query);
	else if (SQL_NumResults(query))
	{
		new stats[ARRAY_MIX_STATS_STRUCT];
		
		while (SQL_MoreResults(query))
		{
			stats[ARRAY_MIX_ID] = SQL_ReadResult(query, 0);
			
			SQL_ReadResult(query, 1, stats[ARRAY_MIX_MAP], charsmax(stats[ARRAY_MIX_MAP]));
			
			stats[ARRAY_MIX_SCORE_CT_HF] = SQL_ReadResult(query, 2);
			stats[ARRAY_MIX_SCORE_CT_HS] = SQL_ReadResult(query, 3);
			stats[ARRAY_MIX_SCORE_CT_TOTAL] = SQL_ReadResult(query, 4);
			stats[ARRAY_MIX_SCORE_TT_HF] = SQL_ReadResult(query, 5);
			stats[ARRAY_MIX_SCORE_TT_HS] = SQL_ReadResult(query, 6);
			stats[ARRAY_MIX_SCORE_TT_TOTAL] = SQL_ReadResult(query, 7);
			stats[ARRAY_MIX_ROUNDS] = SQL_ReadResult(query, 8);
			
			SQL_ReadResult(query, 9, stats[ARRAY_MIX_DATE_STARTED], charsmax(stats[ARRAY_MIX_DATE_STARTED]));
			SQL_ReadResult(query, 10, stats[ARRAY_MIX_DATE_FINISH], charsmax(stats[ARRAY_MIX_DATE_FINISH]));
			
			stats[ARRAY_MIX_SYSTIME] = SQL_ReadResult(query, 11);
			
			SQL_ReadResult(query, 12, stats[ARRAY_MIX_USERS_CT], charsmax(stats[ARRAY_MIX_USERS_CT]));
			SQL_ReadResult(query, 13, stats[ARRAY_MIX_USERS_TT], charsmax(stats[ARRAY_MIX_USERS_TT]));
			SQL_ReadResult(query, 14, stats[ARRAY_MIX_FRAGS_CT_HF], charsmax(stats[ARRAY_MIX_FRAGS_CT_HF]));
			SQL_ReadResult(query, 15, stats[ARRAY_MIX_FRAGS_CT_HS], charsmax(stats[ARRAY_MIX_FRAGS_CT_HS]));
			SQL_ReadResult(query, 16, stats[ARRAY_MIX_FRAGS_TT_HF], charsmax(stats[ARRAY_MIX_FRAGS_TT_HF]));
			SQL_ReadResult(query, 17, stats[ARRAY_MIX_FRAGS_TT_HS], charsmax(stats[ARRAY_MIX_FRAGS_TT_HS]));
			
			g_mix_id++;
			ArrayPushArray(g_array_stats, stats);
			SQL_NextRow(query);
		}
		
		SQL_FreeHandle(query);
	}
	else
		SQL_FreeHandle(query);
	
	query = SQL_PrepareQuery(g_sql_connection, "SELECT * FROM `sql_mix_users`;");
	
	if (!SQL_Execute(query))
		sql_query_error(query);
	else if (SQL_NumResults(query))
	{
		new stats[ARRAY_USERS_STATS_STRUCT];
		
		while (SQL_MoreResults(query))
		{
			stats[ARRAY_MIX_ID] = SQL_ReadResult(query, 0);
			stats[ARRAY_MIX_ROUND] = SQL_ReadResult(query, 1);
			
			SQL_ReadResult(query, 2, stats[ARRAY_USER_NAME], charsmax(stats[ARRAY_USER_NAME]));
			SQL_ReadResult(query, 3, stats[ARRAY_USER_IP], charsmax(stats[ARRAY_USER_IP]));
			SQL_ReadResult(query, 4, stats[ARRAY_USER_DATE], charsmax(stats[ARRAY_USER_DATE]));
			
			SQL_ReadResult(query, 5, stats[ARRAY_USER_MAP], charsmax(stats[ARRAY_USER_MAP]));
			SQL_ReadResult(query, 6, stats[ARRAY_USER_TEAM], charsmax(stats[ARRAY_USER_TEAM]));
			
			stats[ARRAY_USER_TKS] = SQL_ReadResult(query, 7);
			stats[ARRAY_USER_DISCONNECTED] = SQL_ReadResult(query, 8);
			
			save_data(stats[ARRAY_MIX_ID], stats[ARRAY_MIX_ROUND], stats[ARRAY_USER_NAME], stats[ARRAY_USER_IP], stats[ARRAY_USER_DATE], stats[ARRAY_USER_MAP], stats[ARRAY_USER_TEAM], stats[ARRAY_USER_TKS], stats[ARRAY_USER_DISCONNECTED]);
			SQL_NextRow(query);
		}
		
		SQL_FreeHandle(query);
	}
	else
		SQL_FreeHandle(query);
	
	return PLUGIN_HANDLED;
}

save_data(mix_id, mix_round, const name[], const ip[], const date[], const map[], const team[], tks, disconnected)
{
	new stats[ARRAY_USERS_STATS_STRUCT];
	
	copy(stats[ARRAY_USER_NAME], charsmax(stats[ARRAY_USER_NAME]), name);
	copy(stats[ARRAY_USER_IP], charsmax(stats[ARRAY_USER_IP]), ip);
	copy(stats[ARRAY_USER_DATE], charsmax(stats[ARRAY_USER_MAP]), date);
	copy(stats[ARRAY_USER_MAP], charsmax(stats[ARRAY_USER_MAP]), map);
	copy(stats[ARRAY_USER_TEAM], charsmax(stats[ARRAY_USER_TEAM]), team);
				
	stats[ARRAY_MIX_ID] = mix_id;
	stats[ARRAY_MIX_ROUND] = mix_round;
	
	stats[ARRAY_USER_TKS] = tks;
	stats[ARRAY_USER_DISCONNECTED] = disconnected;
	
	if (stats[ARRAY_USER_TKS])
	{
		TrieSetArray(g_trie_users_tks, stats[ARRAY_USER_NAME], stats, sizeof(stats));
		ArrayPushArray(g_array_users_tks, stats);
	}
	
	if (stats[ARRAY_USER_DISCONNECTED])
	{
		TrieSetArray(g_trie_users_disconnected, stats[ARRAY_USER_NAME], stats, sizeof(stats));
		ArrayPushArray(g_array_users_disconnected, stats);
	}
}