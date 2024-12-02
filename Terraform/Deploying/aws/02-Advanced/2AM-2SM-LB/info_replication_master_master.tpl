[node1]
ip = ${ip1}
password_wabadmin = ${wabadmin_password}
password_wabsuper = ${wabsuper_password}
password_change = False

[node2]
ip = ${ip2}
password_wabadmin = ${wabadmin_password}
password_wabsuper = ${wabsuper_password}
password_change = True

[global]
mode = Master/Master
timeout_cmd = 120
replicate_ignore_tables = newly_terminated_session;session_log;auth_log;xref_authlog_group;trace_log
passphrase = ${cryptokey_password}
password_admin = ${webui_password}
database = wallix

# WARNING : all secrets will be removed from this file after the SQL replication is set up
