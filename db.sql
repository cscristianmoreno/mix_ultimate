DROP TABLE `sql_mix_table`;
DROP TABLE `sql_mix_users`;

CREATE TABLE IF NOT EXISTS `sql_mix_table`
(
	mix_id INTEGER NOT NULL,
	mix_map VARCHAR(32) NOT NULL,
	mix_score_ct_hf INTEGER NOT NULL DEFAULT '0',
	mix_score_ct_hs INTEGER NOT NULL DEFAULT '0',
	mix_score_ct_total INTEGER NOT NULL DEFAULT '0',
	mix_score_tt_hf INTEGER NOT NULL DEFAULT '0',
	mix_score_tt_hs INTEGER NOT NULL DEFAULT '0',
	mix_score_tt_total INTEGER NOT NULL DEFAULT '0',
	mix_score_ct_hf_overtime INTEGER NOT NULL DEFAULT '0',
	mix_score_ct_hs_overtime INTEGER NOT NULL DEFAULT '0',
	mix_score_ct_total_overtime INTEGER NOT NULL DEFAULT '0',
	mix_score_tt_hf_overtime INTEGER NOT NULL DEFAULT '0',
	mix_score_tt_hs_overtime INTEGER NOT NULL DEFAULT '0',
	mix_score_tt_total_overtime INTEGER NOT NULL DEFAULT '0',
	mix_rounds INTEGER NOT NULL DEFAULT '0',
	mix_time_start VARCHAR(32) NOT NULL DEFAULT '',
	mix_time_end VARCHAR(32) NOT NULL DEFAULT '',
	mix_systime INTEGER NOT NULL DEFAULT '0',
	mix_users_ct VARCHAR(128) NOT NULL DEFAULT '',
	mix_users_tt VARCHAR(128) NOT NULL DEFAULT '',
	mix_frags_ct_hf VARCHAR(48) NOT NULL DEFAULT '',
	mix_frags_ct_hs VARCHAR(48) NOT NULL DEFAULT '',
	mix_frags_tt_hf VARCHAR(48) NOT NULL DEFAULT '',
	mix_frags_tt_hs VARCHAR(48) NOT NULL DEFAULT ''
);

CREATE TABLE IF NOT EXISTS `sql_mix_users`
(
	mix_id INTEGER NOT NULL,
	mix_round INTEGER NOT NULL,
	user_name VARCHAR(32) NOT NULL,
	user_ip VARCHAR(16) NOT NULL,
	user_date VARCHAR(32) NOT NULL,
	user_map VARCHAR(32) NOT NULL,
	user_team VARCHAR(11) NOT NULL,
	user_tks INTEGER NOT NULL DEFAULT '0',
	user_disconnected INTEGER NOT NULL DEFAULT '0'
);
*/