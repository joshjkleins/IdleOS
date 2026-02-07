extends Node
var EMPTY_LOG_LINE = {"level":"","service":"","message":"","tags":[]}
var LOG_LINES = [

# ---------------- INFO ----------------
{"level":"INFO","service":"auth.service","message":"Login attempt from 172.16.4.23","tags":[]},
{"level":"INFO","service":"auth.service","message":"Login success user=guest","tags":[]},
{"level":"INFO","service":"api.gateway","message":"Request GET /status 200","tags":[]},
{"level":"INFO","service":"api.gateway","message":"Request POST /login 401","tags":[]},
{"level":"INFO","service":"db.cluster","message":"Query executed in 42ms","tags":[]},
{"level":"INFO","service":"cache.node","message":"Cache miss key=user_profile_221","tags":[]},
{"level":"INFO","service":"lambda.exec","message":"Cold start detected","tags":[]},
{"level":"INFO","service":"s3.bucket","message":"Object read logs/2024-09-21.gz","tags":[]},
{"level":"INFO","service":"net.router","message":"DHCP lease assigned 10.0.0.82","tags":[]},
{"level":"INFO","service":"sys.monitor","message":"CPU usage 38%","tags":[]},
{"level":"INFO","service":"container.docker","message":"Container redis restarted","tags":[]},
{"level":"INFO","service":"tls.handler","message":"TLS handshake completed","tags":[]},
{"level":"INFO","service":"email.service","message":"Outbound mail queued","tags":[]},
{"level":"INFO","service":"firewall","message":"Allowed outbound 443","tags":[]},
{"level":"INFO","service":"cdn.edge","message":"Edge node latency 21ms","tags":[]},
{"level":"INFO","service":"metrics.agent","message":"Heartbeat sent","tags":[]},
{"level":"INFO","service":"backup.agent","message":"Snapshot created","tags":[]},
{"level":"INFO","service":"k8s.node","message":"Node worker-3 ready","tags":[]},
{"level":"INFO","service":"queue.worker","message":"Job 88342 processed","tags":[]},
{"level":"INFO","service":"proxy.edge","message":"Upstream response 304","tags":[]},

# ---------------- WARN ----------------
{"level":"WARN","service":"auth.service","message":"Multiple failed logins user=admin","tags":["suspicious"]},
{"level":"WARN","service":"api.gateway","message":"Rate limit exceeded 192.168.2.14","tags":["suspicious"]},
{"level":"WARN","service":"db.cluster","message":"Slow query detected 812ms","tags":["suspicious"]},
{"level":"WARN","service":"firewall","message":"Port scan suspected from 185.22.91.7","tags":["suspicious","ip"]},
{"level":"WARN","service":"tls.handler","message":"Self-signed certificate detected","tags":["suspicious"]},
{"level":"WARN","service":"container.docker","message":"Container api_server exited unexpectedly","tags":["suspicious"]},
{"level":"WARN","service":"sys.monitor","message":"CPU spike 91%","tags":["suspicious"]},
{"level":"WARN","service":"backup.agent","message":"Snapshot integrity check failed","tags":["suspicious"]},
{"level":"WARN","service":"queue.worker","message":"Job retry limit approaching id=9912","tags":["suspicious"]},

# ---------------- ALERT ----------------
{"level":"ALERT","service":"auth.service","message":"Password hash exposed in debug log","tags":["password","high_value"]},
{"level":"ALERT","service":"auth.service","message":"Privilege escalation attempt user=guest","tags":["username","high_value"]},
{"level":"ALERT","service":"db.cluster","message":"Unauthorized SELECT on users table","tags":["data","high_value"]},
{"level":"ALERT","service":"api.gateway","message":"API key leaked in query string","tags":["key","high_value"]},
{"level":"ALERT","service":"s3.bucket","message":"Public read enabled on bucket backups","tags":["data"]},
{"level":"ALERT","service":"firewall","message":"Inbound SSH allowed from 0.0.0.0","tags":["ip","high_value"]},
{"level":"ALERT","service":"tls.handler","message":"Private key material logged","tags":["key","high_value"]},
{"level":"ALERT","service":"proxy.edge","message":"Session token observed in URL","tags":["token","high_value"]},
{"level":"ALERT","service":"container.docker","message":"Container running as root","tags":["suspicious"]},
{"level":"ALERT","service":"backup.agent","message":"Backup archive contains credentials","tags":["password","data","high_value"]},
{"level":"ALERT","service":"config.loader","message":"Hardcoded API secret detected","tags":["key","high_value"]},
{"level":"ALERT","service":"sys.monitor","message":"Root shell spawned pid=8821","tags":["high_value"]},

# ---------------- ENCRYPTED ----------------
{"level":"INFO","service":"vault.service","message":"Encrypted blob retrieved id=a8F2kL9","tags":["encrypted"]},
{"level":"INFO","service":"kms.handler","message":"Envelope key generated","tags":["encrypted","key"]},
{"level":"INFO","service":"tls.handler","message":"Encrypted session ticket issued","tags":["encrypted","token"]},
{"level":"INFO","service":"backup.agent","message":"Archive encrypted AES256","tags":["encrypted"]},

# ---------------- CORRUPTED ----------------
{"level":"ERR","service":"parser.core","message":"Malformed entry unexpected token","tags":["corrupted"]},
{"level":"ERR","service":"net.capture","message":"Packet decode failed","tags":["corrupted"]},
{"level":"ERR","service":"disk.reader","message":"Sector read error retrying","tags":["corrupted"]},
{"level":"ERR","service":"archive.reader","message":"Gzip footer mismatch","tags":["corrupted"]}

]
