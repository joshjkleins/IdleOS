# Items.gd (autoload)
extends Node
## ADDING ITEMS ##
# Add to ItemType enum
# Remember ID (commented number)
# create resource in items directory 
# assign id (same as ItemType)
# add preload
# add to ITEM_MAP

## ADDING VALUABLES ##
# Same as above but add to valuables directory and check valuable bool in resource

## ADDING CACHE ##
# Create cache_entry (in appropriate directory) for each item that will be in cache e.g. student_data will be Data and have a min of 1 and max of 10 with a 1.0 (100%) drop chance
# note: drop chance is independent, not weighted. so if its set to 1.0, it will always drop EXCEPT rare drops, then drop chance is ignored in cache_entry
# Once they are all created, create a cache_data resource (again in appropriate directory). and drag cache_entry's to appropriate slots (regular drops & rare drops)
# When creating cache_data resource make sure you follow "ADDING ITEMS" instructions as the ID will matter in ItemType enum
# Once it is created and assigned in this file, go to Stats.gd and assign to appropriate target


#SCHOOL > BANK > HOSPITAL > LAWFIRM > POLICE STATION > GOVERNMENT

## ITEM ROADMAP
# TIER 1 - SCHOOL
# LOGS > IP, USERNAME, ENC PW > PW > CREDENTIAL > SCHOOL PAYLOD > CACHES
#
# TIER 2 - BANK
# M:COOKIES > P:ACCOUNT NUMBERS, ENC PIN, ROUTING NUMBER > C:PIN > M:ACCOUNT ACCESS TOKEN > C:BANK PAYLOAD > H:CACHES
#
# TIER 3 - HOSPITAL
# M:METADATA > P:STAFF IDs, ENCRYPTED BADGE HASH, MAC ADDRESS > C:BADGE HASH > M:ACCESS BADGE > C:HOSPITAL PAYLOAD > H:CACHES
#
# TIER 4 - LAWFIRM
# M:ARCHIVES > P:CASE #, ENC SIGNATURE, EMAIL HEADER > C:DIGITAL SIGNATURE > M:SIGNED CERTIFICATE > C:LAWFIRM PAYLOAD > H:CACHES

# TIER 5 - POLICE STATION
# M:REPOS > P:BADGE #, ENCRYPTED SSH KEY, SUBNET MAP > C:PRIVATE KEYS > M:OFFICER AUTH KEYS > C:POLICE PAYLOAD > H:CACHES

#TIER 6 - GOVERNMENT
# M:DATABSES > P:CLEARANCE ID, ENCRYPTED BIO HASHES, GATEWAY ADDRESS > C:BIOMETRIC TEMPLATE > M: SECURITY CLEARANCE > C:GOVERNMENT PAYLOAD > H:CACHES

#LAWFIRM: ARCHIVES ------- CASE NUMBER, ENCRYPTED SIGNATURE, EMAIL HEADER ---------------- DIGITAL SIGNATURE -------------- SIGNED CERTIFICATE ----------- LAWFIRM PAYLOAD ----------


#mining item tiers 
#1: logs
#2: archives
#3: metadata
#4: cookies
#5: repositories
#6: databases

#parsing item tiers 
# LOCATION ITEM | ENCRYPTED ITEM | IDENTITY ITEM
#1: ip address, enc password, username
#2: case number, encrypted signature, email header
#3: staff id, encrypted badge hash, mac address
#4: account number, enc pin, routing number
#5: badge number, encrypted ssh key, subnet map
#6: clearance id, encrypted bio hashes, gateway address

#cracking item tiers 
#1: password
#2: digital signature
#3: badge hash
#4: PIN
#5: private keys
#6: biometric template

#matching item tiers 
#1: credentials
#2: signed certificate
#3: access badge
#4: account access tokens
#5: officer auth keys
#6: security clearance

#payload item tiers 
#1: school
#2: lawfirm
#3: hospital
#4: bank
#5: police
#6: government

#target 1 : encrypted item, mining item, match item (username), TOKEN, RARE ITEM
#target 2 :  mining item, unencrypted item, match item (username), TOKEN, RARE ITEM
#target 3 : matched (cred) item, compile item (ip address), packet spoof, TOKEN, RARE ITEM
#target 4: compile item (ip address), payload, sql injector, TOKEN, RARE ITEM
#target 5: targets 1-4 caches, rare item

#lawfirm:
#legal assistant: encrypted signature: 25-50 | archives: 25-50 | email header: 25-50 | vm mining token | rare item
#paralegal: archives 25-50 | digital signature 25-50 | email header, vm parsing token | rare item
#associate attorney: signed cert | case number | packet spoof | vm cracking token | rare item
#lawyer: case number | lawfirm payload | sql injector, vm compiling token | rare item
#partner: caches 1-4, rare item

#hospital
#items: metadata | staff id | encrypted badge hash | mac address | badge hash | access badge | hospital payload
#receptionist: metadata | encrytped badge hash | mac address | vm crackign token | rare item
#orderly: metadata, badge hash, mac address | vm compiling token | rare item
#nurse: access badge | staff id | packet spoof | vm mining token | rare item
#doctor: staff id | hospital payload | sql injector | vm phishing token | rare item
#chief of medicine:  targets 1-4 caches, rare item

#bank
#Teller : encrypted pin | cookies | routing number | vm phishing token | rare item
#Loan Officer: cookies | PIN | routing num | vm cracking token | rare item
#Branch Manager: account access token | account number | packet spoof | vm mining token | rare item
#Security Admin: account number | bank payload | sql injector | vm cracking token | rare item
#Chief Financial Officer: targets 1-4 caches, rare item

#police #5
#secretary: enc ssh key | repositories | subnet map | mining token | rare item
#cop: repositories | private keys | subnet map | phishing token | rare item
#detective: officer auth keys | badge number | packet spoof | parsing token | rare item
#sergeant: badge number | police payload | sql injector | vm cracking token | rare item
#captain: targets 1-4 caches, rare item

#items: MINING (databases) -- LOCATION (IP) (clearance id) -- ENCR (pw) (enc bio hashes) -- IDENTITY (username) (gateway address) -- CRACK (biometric template) -- MATCH (secrutiy clearance)
#government
#clerk: enc bio hash | databases | gateway address | vm decoding token | rare item
#analyst: databases | biometric template | gateway address | vm phishing token | rare item
#ambassador: security clearance | clearance ID | packet spoof | vm mining token | rare item
#vice president clearance ID | gov payload | sql injector | vm parsing token | rare item
#president: caches 1-4 | nuclear codes


enum ItemType {
	DATA, #0
	LOGS, #1
	ENCRYPTED_PASSWORDS, #2
	PASSWORDS, #3
	USERNAMES, #4
	CREDENTIALS, #5
	IP_ADDRESS, #6
	PARENTS_CREDIT_CARD, #7
	STUDENT_CACHE, #8
	FALSIFIED_TRANSCRIPT_DATABASE, #9
	ADMIN_CACHE, #10
	STUDENT_DISCIPLINARY_RECORDS, #11
	SCHOOL_BUDGET_EMBEZZLEMENT_LOGS, #12
	DISTRICT_WIDE_MASTER_PASSWORD, #13
	VICE_PRINCIPAL_CACHE, #14
	PRINCIPAL_CACHE, #15
	SUPERINTENDENT_CACHE, #16
	BORROWED_BOOK_HISTORY, #17
	INTERNAL_STAFF_LOGIN_CREDENTIALS, #18
	DIGITIZED_RARE_BOOK_SCAN, #19
	OVERDUE_FINE_WAIVER_DATABASE, #20
	CENSORED_BOOKS_ARCHIVE, #21
	PATRON_CACHE, #22
	VOLUNTEER_CACHE, #23
	ASSISTANT_LIBRARIAN_CACHE, #24
	HEAD_LIBRARIAN_CACHE, #25
	DIRECTOR_CACHE, #26
	EMPLOYEE_PAYROLL_DATA, #27
	SHIFT_SCHEDULE_AND_SECURITY_ROTATION, #28
	SUPPLIER_CONTACT_LIST, #29
	CONFIDENTIAL_HR_COMPLAINT_FILES, #30
	UNRELEASED_PRODUCT_PROTOTYPE, #31
	WORKER_CACHE, #32
	SUPERVISOR_CACHE, #33
	MANAGER_CACHE, #34
	HUMAN_RESOURCES_CACHE, #35
	OWNER_CACHE, #36
	STOLEN_EXAM_ANSWER_KEY, #37
	UNPUBLISHED_RESEARCH_PAPER, #38
	GRANT_FRAUD_DOCUMENTATION, #39
	ADMISSIONS_BRIBERY_RECORDS, #40
	ENDOWMENT_FUND_ACCESS_CODES, #41
	TEACHERS_ASSISTANT_CACHE, #42
	PROFESSOR_CACHE, #43
	DEPARTMENT_CHAIR_CACHE, #44
	DEAN_CACHE, #45
	UNIVERSITY_PRESIDENT_CACHE, #46
	PATIENT_APPOINTMENT_HISTORY, #47
	STAFF_KEYCARD_CLONE_DATA, #48
	PRESCRIPTION_PAD_CREDENTIALS, #49
	PATIENT_INSURANCE_DATA, #50
	FALSIFIED_DRUG_TRIAL_RESULTS, #51
	RECEPTIONIST_CACHE, #52
	ORDERLY_CACHE, #53
	NURSE_CACHE, #54
	DOCTOR_CACHE, #55
	CHIEF_OF_MEDICINE_CACHE, #56
	INTERNAL_AFFAIRS_COMPLAINT_ARCHIVE, #57
	BODY_CAM_FOOTAGE_DELETION_LOGS, #58
	CONFIDENTIAL_INFORMANT_REGISTRY, #59
	EVIDENCE_LOCKER_ACCESS_CODES, #60
	CORRUPTION_PAYOUT_LEDGER, #61
	SECRETARY_CACHE, #62
	COP_CACHE, #63
	DETECTIVE_CACHE, #64
	SERGEANT_CACHE, #65
	CAPTAIN_CACHE, #66
	LEAKED_DEPOSITION_TRANSCRIPTS, #67
	FORGED_COURT_DOCUMENT_TEMPLATES, #68
	SEALED_CASE_FILES, #69
	OFFSHORE_ACCOUNT_RECORDS, #70
	WITNESS_PROTECTION_ADDRESS, #71
	LEGAL_ASSISTANT_CACHE, #72
	PARALEGAL_CACHE, #73
	ASSOCIATE_ATTORNEY_CACHE, #74
	LAWYER_CACHE, #75
	PARTNER_CACHE, #76
	SQL_INJECTOR, #77
	PACKET_SPOOF, #78
	PINS, #79
	ENCRYPTED_PINS, #80
	ACCOUNT_NUMBERS, #81
	ACCOUNT_ACCESS_TOKENS, #82
	UNUSED_83, #83 (was DDoS, removed: slot kept so later item ids stay the same)
	REFRESH_TOKEN, #84
	QUALITY_LOGS, #85
	VM_MINING_TOKEN, #86
	VM_PARSING_TOKEN, #87
	VM_CRACKING_TOKEN, #88
	VM_MATCHING_TOKEN, #89
	VM_PHISHING_TOKEN, #90
	VM_DECODING_TOKEN, #91
	SCHOOL_PAYLOAD, #92
	SMALL_BUSINESS_PAYLOAD, #93
	LIBRARY_PAYLOAD, #94
	VM_COMPILING_TOKEN, #95
	STUDENT_CACHE_FOOTPRINT, #96
	SQL_BOOSTER, #97
	ARCHIVES, #98
	COOKIES, #99
	DATABASES, #100
	METADATA, #101
	REPOSITORIES, #102
	BADGE_HASH, #103
	BIO_TEMPLATE, #104
	DIGITAL_SIGNATURE, #105
	PRIVATE_KEYS, #106
	ACCESS_BADGE, #107
	OFFICER_AUTH_KEYS, #108
	SECURITY_CLEARANCE, #109
	SIGNED_CERTIFICATE, #110
	BADGE_NUMBER, #111
	CASE_NUMBER, #112
	CLEARANCE_ID, #113
	EMAIL_HEADER, #114
	ENCRYPTED_BIO_HASH, #115
	ENCRYPTED_SIGNATURE, #116
	ENCRYPTED_SSH_KEY, #117
	GATEWAY_ADDRESS, #118
	MAC_ADDRESS, #119
	ROUTING_NUMBER, #120
	STAFF_IDS, #121
	SUBNET_MAP, #122
	BANK_PAYLOAD, #123
	GOVERNMENT_PAYLOAD, #124
	HOSPITAL_PAYLOAD, #125
	LAWFIRM_PAYLOAD, #126
	POLICE_PAYLOAD, #127
	ENCRYPTED_BADGE_HASH, #128
	CASH_DRAWER_CODES, #129
	TELLER_CACHE, #130
	SECURITY_CACHE, #131
	LOAN_OFFICER_CACHE, #132
	BRANCH_MANAGER_CACHE, #133
	CFO_CACHE, #134,
	CREDIT_RECORDS, #135
	SAFE_DEPOSIT_BOX_REGISTERY, #136
	SWIFT_MASTER_KEY, #137
	VAULT_OVERRIDE, #138
	CLERK_CACHE, #139
	ANALYST_CACHE, #140
	AMBASSADOR_CACHE, #141
	VICE_PRESIDENT_CACHE, #142
	PRESIDENT_CACHE, #143
	REGISTER_VOTER_DB, #144 clerk
	CIA_BRIEF, #145 ANALYST
	BLACK_BUDGET_LEDGER, #146 ambassador
	DEEP_COVER_IDS, #147 vice pres
	NUKE_CODES, #148 pres
	STUDENT_CACHE_CORRUPTION, #149 <-----------------------HERE
	STUDENT_CACHE_NETWORK, #150
	STUDENT_CACHE_EXTRACTION, #151
	ADMIN_CACHE_FOOTPRINT, #152
	ADMIN_CACHE_CORRUPTION, #153
	ADMIN_CACHE_NETWORK, #154
	ADMIN_CACHE_EXTRACTION, #155
	VICE_PRINCIPAL_CACHE_FOOTPRINT, #156
	VICE_PRINCIPAL_CACHE_CORRUPTION, #157
	VICE_PRINCIPAL_CACHE_NETWORK, #158
	VICE_PRINCIPAL_CACHE_EXTRACTION, #159
	PRINCIPAL_CACHE_FOOTPRINT, #160
	PRINCIPAL_CACHE_CORRUPTION, #161
	PRINCIPAL_CACHE_NETWORK, #162
	PRINCIPAL_CACHE_EXTRACTION, #163
	SUPERINTENDENT_CACHE_FOOTPRINT, #164
	SUPERINTENDENT_CACHE_CORRUPTION, #165
	SUPERINTENDENT_CACHE_NETWORK, #166
	SUPERINTENDENT_CACHE_EXTRACTION, #167
	PATRON_CACHE_FOOTPRINT, #168
	PATRON_CACHE_CORRUPTION, #169
	PATRON_CACHE_NETWORK, #170
	PATRON_CACHE_EXTRACTION, #171
	VOLUNTEER_CACHE_FOOTPRINT, #172
	VOLUNTEER_CACHE_CORRUPTION, #173
	VOLUNTEER_CACHE_NETWORK, #174
	VOLUNTEER_CACHE_EXTRACTION, #175
	ASSISTANT_LIBRARIAN_CACHE_FOOTPRINT, #176
	ASSISTANT_LIBRARIAN_CACHE_CORRUPTION, #177
	ASSISTANT_LIBRARIAN_CACHE_NETWORK, #178
	ASSISTANT_LIBRARIAN_CACHE_EXTRACTION, #179
	HEAD_LIBRARIAN_CACHE_FOOTPRINT, #180
	HEAD_LIBRARIAN_CACHE_CORRUPTION, #181
	HEAD_LIBRARIAN_CACHE_NETWORK, #182
	HEAD_LIBRARIAN_CACHE_EXTRACTION, #183
	DIRECTOR_CACHE_FOOTPRINT, #184
	DIRECTOR_CACHE_CORRUPTION, #185
	DIRECTOR_CACHE_NETWORK, #186
	DIRECTOR_CACHE_EXTRACTION, #187
	WORKER_CACHE_FOOTPRINT, #188
	WORKER_CACHE_CORRUPTION, #189
	WORKER_CACHE_NETWORK, #190
	WORKER_CACHE_EXTRACTION, #191
	SUPERVISOR_CACHE_FOOTPRINT, #192
	SUPERVISOR_CACHE_CORRUPTION, #193
	SUPERVISOR_CACHE_NETWORK, #194
	SUPERVISOR_CACHE_EXTRACTION, #195
	MANAGER_CACHE_FOOTPRINT, #196
	MANAGER_CACHE_CORRUPTION, #197
	MANAGER_CACHE_NETWORK, #198
	MANAGER_CACHE_EXTRACTION, #199
	HUMAN_RESOURCES_CACHE_FOOTPRINT, #200
	HUMAN_RESOURCES_CACHE_CORRUPTION, #201
	HUMAN_RESOURCES_CACHE_NETWORK, #202
	HUMAN_RESOURCES_CACHE_EXTRACTION, #203
	OWNER_CACHE_FOOTPRINT, #204
	OWNER_CACHE_CORRUPTION, #205
	OWNER_CACHE_NETWORK, #206
	OWNER_CACHE_EXTRACTION, #207
	TEACHERS_ASSISTANT_CACHE_FOOTPRINT, #208
	TEACHERS_ASSISTANT_CACHE_CORRUPTION, #209
	TEACHERS_ASSISTANT_CACHE_NETWORK, #210
	TEACHERS_ASSISTANT_CACHE_EXTRACTION, #211
	PROFESSOR_CACHE_FOOTPRINT, #212
	PROFESSOR_CACHE_CORRUPTION, #213
	PROFESSOR_CACHE_NETWORK, #214
	PROFESSOR_CACHE_EXTRACTION, #215
	DEPARTMENT_CHAIR_CACHE_FOOTPRINT, #216
	DEPARTMENT_CHAIR_CACHE_CORRUPTION, #217
	DEPARTMENT_CHAIR_CACHE_NETWORK, #218
	DEPARTMENT_CHAIR_CACHE_EXTRACTION, #219
	DEAN_CACHE_FOOTPRINT, #220
	DEAN_CACHE_CORRUPTION, #221
	DEAN_CACHE_NETWORK, #222
	DEAN_CACHE_EXTRACTION, #223
	UNIVERSITY_PRESIDENT_CACHE_FOOTPRINT, #224
	UNIVERSITY_PRESIDENT_CACHE_CORRUPTION, #225
	UNIVERSITY_PRESIDENT_CACHE_NETWORK, #226
	UNIVERSITY_PRESIDENT_CACHE_EXTRACTION, #227
	RECEPTIONIST_CACHE_FOOTPRINT, #228
	RECEPTIONIST_CACHE_CORRUPTION, #229
	RECEPTIONIST_CACHE_NETWORK, #230
	RECEPTIONIST_CACHE_EXTRACTION, #231
	ORDERLY_CACHE_FOOTPRINT, #232
	ORDERLY_CACHE_CORRUPTION, #233
	ORDERLY_CACHE_NETWORK, #234
	ORDERLY_CACHE_EXTRACTION, #235
	NURSE_CACHE_FOOTPRINT, #236
	NURSE_CACHE_CORRUPTION, #237
	NURSE_CACHE_NETWORK, #238
	NURSE_CACHE_EXTRACTION, #239
	DOCTOR_CACHE_FOOTPRINT, #240
	DOCTOR_CACHE_CORRUPTION, #241
	DOCTOR_CACHE_NETWORK, #242
	DOCTOR_CACHE_EXTRACTION, #243
	CHIEF_OF_MEDICINE_CACHE_FOOTPRINT, #244
	CHIEF_OF_MEDICINE_CACHE_CORRUPTION, #245
	CHIEF_OF_MEDICINE_CACHE_NETWORK, #246
	CHIEF_OF_MEDICINE_CACHE_EXTRACTION, #247
	SECRETARY_CACHE_FOOTPRINT, #248
	SECRETARY_CACHE_CORRUPTION, #249
	SECRETARY_CACHE_NETWORK, #250
	SECRETARY_CACHE_EXTRACTION, #251
	COP_CACHE_FOOTPRINT, #252
	COP_CACHE_CORRUPTION, #253
	COP_CACHE_NETWORK, #254
	COP_CACHE_EXTRACTION, #255
	DETECTIVE_CACHE_FOOTPRINT, #256
	DETECTIVE_CACHE_CORRUPTION, #257
	DETECTIVE_CACHE_NETWORK, #258
	DETECTIVE_CACHE_EXTRACTION, #259
	SERGEANT_CACHE_FOOTPRINT, #260
	SERGEANT_CACHE_CORRUPTION, #261
	SERGEANT_CACHE_NETWORK, #262
	SERGEANT_CACHE_EXTRACTION, #263
	CAPTAIN_CACHE_FOOTPRINT, #264
	CAPTAIN_CACHE_CORRUPTION, #265
	CAPTAIN_CACHE_NETWORK, #266
	CAPTAIN_CACHE_EXTRACTION, #267
	LEGAL_ASSISTANT_CACHE_FOOTPRINT, #268
	LEGAL_ASSISTANT_CACHE_CORRUPTION, #269
	LEGAL_ASSISTANT_CACHE_NETWORK, #270
	LEGAL_ASSISTANT_CACHE_EXTRACTION, #271
	PARALEGAL_CACHE_FOOTPRINT, #272
	PARALEGAL_CACHE_CORRUPTION, #273
	PARALEGAL_CACHE_NETWORK, #274
	PARALEGAL_CACHE_EXTRACTION, #275
	ASSOCIATE_ATTORNEY_CACHE_FOOTPRINT, #276
	ASSOCIATE_ATTORNEY_CACHE_CORRUPTION, #277
	ASSOCIATE_ATTORNEY_CACHE_NETWORK, #278
	ASSOCIATE_ATTORNEY_CACHE_EXTRACTION, #279
	LAWYER_CACHE_FOOTPRINT, #280
	LAWYER_CACHE_CORRUPTION, #281
	LAWYER_CACHE_NETWORK, #282
	LAWYER_CACHE_EXTRACTION, #283
	PARTNER_CACHE_FOOTPRINT, #284
	PARTNER_CACHE_CORRUPTION, #285
	PARTNER_CACHE_NETWORK, #286
	PARTNER_CACHE_EXTRACTION, #287
	TELLER_CACHE_FOOTPRINT, #288
	TELLER_CACHE_CORRUPTION, #289
	TELLER_CACHE_NETWORK, #290
	TELLER_CACHE_EXTRACTION, #291
	SECURITY_CACHE_FOOTPRINT, #292
	SECURITY_CACHE_CORRUPTION, #293
	SECURITY_CACHE_NETWORK, #294
	SECURITY_CACHE_EXTRACTION, #295
	LOAN_OFFICER_CACHE_FOOTPRINT, #296
	LOAN_OFFICER_CACHE_CORRUPTION, #297
	LOAN_OFFICER_CACHE_NETWORK, #298
	LOAN_OFFICER_CACHE_EXTRACTION, #299
	BRANCH_MANAGER_CACHE_FOOTPRINT, #300
	BRANCH_MANAGER_CACHE_CORRUPTION, #301
	BRANCH_MANAGER_CACHE_NETWORK, #302
	BRANCH_MANAGER_CACHE_EXTRACTION, #303
	CFO_CACHE_FOOTPRINT, #304
	CFO_CACHE_CORRUPTION, #305
	CFO_CACHE_NETWORK, #306
	CFO_CACHE_EXTRACTION, #307
	CLERK_CACHE_FOOTPRINT, #308
	CLERK_CACHE_CORRUPTION, #309
	CLERK_CACHE_NETWORK, #310
	CLERK_CACHE_EXTRACTION, #311
	ANALYST_CACHE_FOOTPRINT, #312
	ANALYST_CACHE_CORRUPTION, #313
	ANALYST_CACHE_NETWORK, #314
	ANALYST_CACHE_EXTRACTION, #315
	AMBASSADOR_CACHE_FOOTPRINT, #316
	AMBASSADOR_CACHE_CORRUPTION, #317
	AMBASSADOR_CACHE_NETWORK, #318
	AMBASSADOR_CACHE_EXTRACTION, #319
	VICE_PRESIDENT_CACHE_FOOTPRINT, #320
	VICE_PRESIDENT_CACHE_CORRUPTION, #321
	VICE_PRESIDENT_CACHE_NETWORK, #322
	VICE_PRESIDENT_CACHE_EXTRACTION, #323
	PRESIDENT_CACHE_FOOTPRINT, #324
	PRESIDENT_CACHE_CORRUPTION, #325
	PRESIDENT_CACHE_NETWORK, #326
	PRESIDENT_CACHE_EXTRACTION, #327
	# one-time hacking items (Exploits singleton)
	PROXY_HOP, #328
	LAG_SPIKE, #329
	CEASE_DESIST, #330
	THROTTLE_PATCH, #331
	SLOW_DRIP, #332
	BOOSTER_SHOT, #333
	OVERDRAFT, #334
	MARGIN_CALL, #335
	ZERO_DAY, #336
	GHOST_MODE, #337
	REDACTION, #338
	BLACKOUT, #339
	SHATTER_PROTOCOL, #340
	BURST_BUFFER, #341
	FIRMWARE_BRICK, #342
	PAYLOAD_AMPLIFIER, #343
	VULN_SCANNER, #344
	CRITICAL_OVERFLOW, #345
	PROXY_CHAIN, #346
	GHOST_PACKET, #347
	DECOY_TRAFFIC, #348
	PACKET_SHREDDER, #349
	LATENCY_INJECTOR, #350
	SILENT_ENTRY, #351
	IP_ROTATOR, #352
	ZERO_HOUR, #353
	CASCADE, #354
	MIRROR, #355
	COLD_BOOT, #356
	VM_CACHE, #357
	HANDSHAKE_EXPLOIT, #358
	BACKDOOR, #359
	RESET_LOOP, #360
	HARDENED_SHELL, #361
	FRESH_START, #362
	OPENING_SPOOF, #363
	HOT_STREAK, #364
	DOUBLE_TAP, #365
	BLEED, #366
	BREACH_MOMENTUM, #367
	LEECH, #368
	JITTER, #369
	FAILSAFE, #370
	DATA_HOARDER, #371
	PACKET_FLOOD, #372
	SMOKE_SCREEN, #373
	OVERCHARGE, #374
	PORT_KNOCK, #375
	QUICK_PATCH, #376
	TRACE_SCRAMBLER, #377
	CREDENTIAL_STUFFING, #378
	HEAT_SINK, #379
	ROOTKIT, #380
	MIRROR_IMAGE, #381
	FIREWALL_DRAIN, #382
	SUPPLY_DROP, #383
	CHAIN_REACTION, #384
	FREEZE, #385
	EXFIL_WINDOW, #386
	ROOT_ACCESS, #387
	TOTAL_RECALL, #388
	SYSTEM_PURGE, #389
}

### RESOURCES ###
const DATA = preload("res://items/resources/data.tres")
const LOGS = preload("res://items/resources/Mining/logs.tres")
const ENCRYPTED_PASSWORDS = preload("res://items/resources/Parsing/encrypted_passwords.tres")
const PASSWORDS = preload("res://items/resources/Cracking/passwords.tres")
const USERNAMES = preload("res://items/resources/Parsing/usernames.tres")
const CREDENTIALS = preload("res://items/resources/Matching/credentials.tres")
const IP_ADDRESS = preload("res://items/resources/Parsing/ip_address.tres")
const ENCRYPTED_PINS = preload("res://items/resources/Parsing/encrypted_pins.tres")
const PINS = preload("res://items/resources/Cracking/pins.tres")
const ACCOUNT_NUMBERS = preload("res://items/resources/Parsing/account_numbers.tres")
const ACCOUNT_ACCESS_TOKENS = preload("res://items/resources/Matching/account_access_tokens.tres")
const QUALITY_LOGS = preload("res://items/resources/quality_logs.tres")
const ARCHIVES = preload("res://items/resources/Mining/archives.tres")
const COOKIES = preload("res://items/resources/Mining/cookies.tres")
const DATABASES = preload("res://items/resources/Mining/databases.tres")
const METADATA = preload("res://items/resources/Mining/metadata.tres")
const REPOSITORIES = preload("res://items/resources/Mining/repositories.tres")
const BADGE_HASH = preload("res://items/resources/Cracking/badge_hash.tres")
const BIO_TEMPLATE = preload("res://items/resources/Cracking/bio_template.tres")
const DIGITAL_SIGNATURE = preload("res://items/resources/Cracking/digital_signature.tres")
const PRIVATE_KEYS = preload("res://items/resources/Cracking/private_keys.tres")
const ACCESS_BADGE = preload("res://items/resources/Matching/access_badge.tres")
const OFFICER_AUTH_KEYS = preload("res://items/resources/Matching/officer_auth_keys.tres")
const SECURITY_CLEARANCE = preload("res://items/resources/Matching/security_clearance.tres")
const SIGNED_CERTIFICATE = preload("res://items/resources/Matching/signed_certificate.tres")
const BADGE_NUMBER = preload("res://items/resources/Parsing/badge_number.tres")
const CASE_NUMBER = preload("res://items/resources/Parsing/case_number.tres")
const CLEARANCE_ID = preload("res://items/resources/Parsing/clearance_id.tres")
const EMAIL_HEADER = preload("res://items/resources/Parsing/email_header.tres")
const ENCRYPTED_BIO_HASH = preload("res://items/resources/Parsing/encrypted_bio_hash.tres")
const ENCRYPTED_SIGNATURE = preload("res://items/resources/Parsing/encrypted_signature.tres")
const ENCRYPTED_SSH_KEY = preload("res://items/resources/Parsing/encrypted_ssh_key.tres")
const GATEWAY_ADDRESS = preload("res://items/resources/Parsing/gateway_address.tres")
const MAC_ADDRESS = preload("res://items/resources/Parsing/mac_address.tres")
const ROUTING_NUMBER = preload("res://items/resources/Parsing/routing_number.tres")
const STAFF_IDS = preload("res://items/resources/Parsing/staff_ids.tres")
const SUBNET_MAP = preload("res://items/resources/Parsing/subnet_map.tres")

const ENCRYPTED_BADGE_HASH = preload("res://items/resources/Parsing/encrypted_badge_hash.tres") #128 <-- HERE? NEED TO ADD BELOW
const CASH_DRAWER_CODES = preload("res://items/valuables/bank/cash_drawer_override_code.tres") #129
const TELLER_CACHE = preload("res://items/cache_data/bank/teller_cache.tres") #130
const SECURITY_CACHE = preload("res://items/cache_data/bank/security_cache.tres") #131
const LOAN_OFFICER_CACHE = preload("res://items/cache_data/bank/officer_cache.tres") #132
const BRANCH_MANAGER_CACHE = preload("res://items/cache_data/bank/manager_cache.tres") #133
const CFO_CACHE = preload("res://items/cache_data/bank/cfo_cache.tres") #134
const CREDIT_RECORDS = preload("res://items/valuables/bank/credit_records.tres") #135
const SAFE_DEPOSIT_BOX_REGISTERY = preload("res://items/valuables/bank/safe_deposit_box_registry.tres") #136
const SWIFT_MASTER_KEY = preload("res://items/valuables/bank/swift_master_key.tres") #137
const VAULT_OVERRIDE = preload("res://items/valuables/bank/vault_override.tres") #138
const CLERK_CACHE = preload("res://items/cache_data/government/clerk_cache.tres") #139
const ANALYST_CACHE = preload("res://items/cache_data/government/analyst_cache.tres") #140
const AMBASSADOR_CACHE = preload("res://items/cache_data/government/ambassador_cache.tres") #141
const VICE_PRESIDENT_CACHE = preload("res://items/cache_data/government/vice_president_cache.tres") #142
const PRESIDENT_CACHE = preload("res://items/cache_data/government/president_cache.tres") #143
const REGISTER_VOTER_DB = preload("res://items/valuables/government/register_voter_db.tres") #144 clerk
const CIA_BRIEF = preload("res://items/valuables/government/cia_brief.tres") #145 ANALYST
const BLACK_BUDGET_LEDGER = preload("res://items/valuables/government/black_budget_ledger.tres") #146 ambassador
const DEEP_COVER_IDS = preload("res://items/valuables/government/deep_cover_ids.tres") #147 vice pres
const NUKE_CODES = preload("res://items/valuables/government/nuke_codes.tres") #148 pres


### PAYLOADS ###
const SCHOOL_PAYLOAD = preload("res://items/resources/Payloads/school_payload.tres")
const SMALL_BUSINESS_PAYLOAD = preload("res://items/resources/Payloads/small_business_payload.tres")
const LIBRARY_PAYLOAD = preload("res://items/resources/Payloads/library_payload.tres")
const BANK_PAYLOAD = preload("res://items/resources/Payloads/bank_payload.tres")
const GOVERNMENT_PAYLOAD = preload("res://items/resources/Payloads/government_payload.tres")
const HOSPITAL_PAYLOAD = preload('res://items/resources/Payloads/hospital_payload.tres')
const LAWFIRM_PAYLOAD = preload("res://items/resources/Payloads/lawfirm_payload.tres")
const POLICE_PAYLOAD = preload("res://items/resources/Payloads/police_station_payload.tres")

### COMBAT ###
const SQL_INJECTOR = preload("res://items/combat/sql_injector.tres")
const PACKET_SPOOF = preload("res://items/combat/packet_spoof.tres")

### HACKING MODS ###
const SQL_BOOSTER = preload("res://items/hacking_mods/sql_booster.tres")

### TOKENS ###
#VMs
const VM_MINING_TOKEN = preload("res://items/tokens/mining/vm_mining_token.tres")
const VM_PARSING_TOKEN = preload("res://items/tokens/parsing/vm_parsing_token.tres")
const VM_CRACKING_TOKEN = preload("res://items/tokens/cracking/vm_cracking_token.tres")
const VM_MATCHING_TOKEN = preload("res://items/tokens/matching/vm_matching_token.tres")
const VM_PHISHING_TOKEN = preload("res://items/tokens/phishing/vm_phishing_token.tres")
const VM_DECODING_TOKEN = preload("res://items/tokens/decoding/vm_decoding_token.tres")
const VM_COMPILING_TOKEN = preload("res://items/tokens/compiling/vm_compiling_token.tres")

#REFRESH
const REFRESH_TOKEN = preload("res://items/tokens/refresh/refresh_token.tres")

### VALUABLES ###
#school
const PARENTS_CREDIT_CARD = preload("res://items/valuables/school/parents_credit_card.tres")
const FALSIFIED_TRANSCRIPT_DATABASE = preload("res://items/valuables/school/falsified_transcript_database.tres")
const STUDENT_DISCIPLINARY_RECORDS = preload("res://items/valuables/school/student_disciplinary_records.tres")
const SCHOOL_BUDGET_EMBEZZLEMENT_LOGS = preload("res://items/valuables/school/school_budget_embezzlement_logs.tres")
const DISTRICT_WIDE_MASTER_PASSWORD = preload("res://items/valuables/school/district_wide_master_password.tres")
#library
const BORROWED_BOOK_HISTORY = preload("res://items/valuables/library/borrowed_book_history.tres")
const INTERNAL_STAFF_LOGIN_CREDENTIALS = preload("res://items/valuables/library/internal_staff_login_credentials.tres")
const DIGITIZED_RARE_BOOK_SCAN = preload("res://items/valuables/library/digitized_rare_book_scan.tres")
const OVERDUE_FINE_WAIVER_DATABASE = preload("res://items/valuables/library/overdue_fine_waiver_database.tres")
const CENSORED_BOOKS_ARCHIVE = preload("res://items/valuables/library/censored_books_archive.tres")
#small business
const EMPLOYEE_PAYROLL_DATA = preload("res://items/valuables/small_business/employee_payroll_data.tres")
const SHIFT_SCHEDULE_AND_SECURITY_ROTATION = preload("res://items/valuables/small_business/shift_schedule_and_security_rotation.tres")
const SUPPLIER_CONTACT_LIST = preload("res://items/valuables/small_business/supplier_contact_list.tres")
const CONFIDENTIAL_HR_COMPLAINT_FILES = preload("res://items/valuables/small_business/confidential_hr_complaint_files.tres")
const UNRELEASED_PRODUCT_PROTOTYPE = preload("res://items/valuables/small_business/unreleased_product_prototype.tres")
#university
const STOLEN_EXAM_ANSWER_KEY = preload("res://items/valuables/university/stolen_exam_answer_key.tres")
const UNPUBLISHED_RESEARCH_PAPER = preload("res://items/valuables/university/unpublished_research_paper.tres")
const GRANT_FRAUD_DOCUMENTATION = preload("res://items/valuables/university/grant_fraud_documentation.tres")
const ADMISSIONS_BRIBERY_RECORDS = preload("res://items/valuables/university/admissions_bribery_records.tres")
const ENDOWMENT_FUND_ACCESS_CODES = preload("res://items/valuables/university/endowment_fund_access_codes.tres")
#hospital
const PATIENT_APPOINTMENT_HISTORY = preload("res://items/valuables/hospital/patient_appointment_history.tres")
const STAFF_KEYCARD_CLONE_DATA = preload("res://items/valuables/hospital/staff_keycard_clone_data.tres")
const PRESCRIPTION_PAD_CREDENTIALS = preload("res://items/valuables/hospital/prescription_pad_credentials.tres")
const PATIENT_INSURANCE_DATA = preload("res://items/valuables/hospital/patient_insurance_data.tres")
const FALSIFIED_DRUG_TRIAL_RESULTS = preload("res://items/valuables/hospital/falsified_drug_trial_results.tres")
#police station
const INTERNAL_AFFAIRS_COMPLAINT_ARCHIVE = preload("res://items/valuables/police_station/internal_affairs_complaint_archive.tres")
const BODY_CAM_FOOTAGE_DELETION_LOGS = preload("res://items/valuables/police_station/body_cam_footage_deletion_logs.tres")
const CONFIDENTIAL_INFORMANT_REGISTRY = preload("res://items/valuables/police_station/confidential_informant_registry.tres")
const EVIDENCE_LOCKER_ACCESS_CODES = preload("res://items/valuables/police_station/evidence_locker_access_codes.tres")
const CORRUPTION_PAYOUT_LEDGER = preload("res://items/valuables/police_station/corruption_payout_ledger.tres")
#lawfirm
const LEAKED_DEPOSITION_TRANSCRIPTS = preload("res://items/valuables/lawfirm/leaked_deposition_transcripts.tres")
const FORGED_COURT_DOCUMENT_TEMPLATES = preload("res://items/valuables/lawfirm/forged_court_document_templates.tres")
const SEALED_CASE_FILES = preload("res://items/valuables/lawfirm/sealed_case_files.tres")
const OFFSHORE_ACCOUNT_RECORDS = preload("res://items/valuables/lawfirm/offshore_account_records.tres")
const WITNESS_PROTECTION_ADDRESS = preload("res://items/valuables/lawfirm/witness_protection_address.tres")

### CACHES ###

#school
const STUDENT_CACHE = preload("res://items/cache_data/school/student_cache.tres")
const ADMIN_CACHE = preload("res://items/cache_data/school/admin_cache.tres")
const VICE_PRINCIPAL_CACHE = preload("res://items/cache_data/school/vice_principal_cache.tres")
const PRINCIPAL_CACHE = preload("res://items/cache_data/school/principal_cache.tres")
const SUPERINTENDENT_CACHE = preload("res://items/cache_data/school/superintendent_cache.tres")

const STUDENT_CACHE_FOOTPRINT = preload("res://items/cache_data/school/student_cache_footprint.tres")
const STUDENT_CACHE_CORRUPTION = preload("res://items/cache_data/school/student_cache_corruption.tres") #149
const STUDENT_CACHE_NETWORK = preload("res://items/cache_data/school/student_cache_network.tres") #150
const STUDENT_CACHE_EXTRACTION = preload("res://items/cache_data/school/student_cache_extraction.tres") #151
const ADMIN_CACHE_FOOTPRINT = preload("res://items/cache_data/school/admin_cache_footprint.tres") #152
const ADMIN_CACHE_CORRUPTION = preload("res://items/cache_data/school/admin_cache_corruption.tres") #153
const ADMIN_CACHE_NETWORK = preload("res://items/cache_data/school/admin_cache_network.tres") #154
const ADMIN_CACHE_EXTRACTION = preload("res://items/cache_data/school/admin_cache_extraction.tres") #155
const VICE_PRINCIPAL_CACHE_FOOTPRINT = preload("res://items/cache_data/school/vice_principal_cache_footprint.tres") #156
const VICE_PRINCIPAL_CACHE_CORRUPTION = preload("res://items/cache_data/school/vice_principal_cache_corruption.tres") #157
const VICE_PRINCIPAL_CACHE_NETWORK = preload("res://items/cache_data/school/vice_principal_cache_network.tres") #158
const VICE_PRINCIPAL_CACHE_EXTRACTION = preload("res://items/cache_data/school/vice_principal_cache_extraction.tres") #159
const PRINCIPAL_CACHE_FOOTPRINT = preload("res://items/cache_data/school/principal_cache_footprint.tres") #160
const PRINCIPAL_CACHE_CORRUPTION = preload("res://items/cache_data/school/principal_cache_corruption.tres") #161
const PRINCIPAL_CACHE_NETWORK = preload("res://items/cache_data/school/principal_cache_network.tres") #162
const PRINCIPAL_CACHE_EXTRACTION = preload("res://items/cache_data/school/principal_cache_extraction.tres") #163
const SUPERINTENDENT_CACHE_FOOTPRINT = preload("res://items/cache_data/school/superintendent_cache_footprint.tres") #164
const SUPERINTENDENT_CACHE_CORRUPTION = preload("res://items/cache_data/school/superintendent_cache_corruption.tres") #165
const SUPERINTENDENT_CACHE_NETWORK = preload("res://items/cache_data/school/superintendent_cache_network.tres") #166
const SUPERINTENDENT_CACHE_EXTRACTION = preload("res://items/cache_data/school/superintendent_cache_extraction.tres") #167

#library
const PATRON_CACHE = preload("res://items/cache_data/library/patron_cache.tres")
const VOLUNTEER_CACHE = preload("res://items/cache_data/library/volunteer_cache.tres")
const ASSISTANT_LIBRARIAN_CACHE = preload("res://items/cache_data/library/assistant_librarian_cache.tres")
const HEAD_LIBRARIAN_CACHE = preload("res://items/cache_data/library/head_librarian_cache.tres")
const DIRECTOR_CACHE = preload("res://items/cache_data/library/director_cache.tres")
const PATRON_CACHE_FOOTPRINT = preload("res://items/cache_data/library/patron_cache_footprint.tres") #168
const PATRON_CACHE_CORRUPTION = preload("res://items/cache_data/library/patron_cache_corruption.tres") #169
const PATRON_CACHE_NETWORK = preload("res://items/cache_data/library/patron_cache_network.tres") #170
const PATRON_CACHE_EXTRACTION = preload("res://items/cache_data/library/patron_cache_extraction.tres") #171
const VOLUNTEER_CACHE_FOOTPRINT = preload("res://items/cache_data/library/volunteer_cache_footprint.tres") #172
const VOLUNTEER_CACHE_CORRUPTION = preload("res://items/cache_data/library/volunteer_cache_corruption.tres") #173
const VOLUNTEER_CACHE_NETWORK = preload("res://items/cache_data/library/volunteer_cache_network.tres") #174
const VOLUNTEER_CACHE_EXTRACTION = preload("res://items/cache_data/library/volunteer_cache_extraction.tres") #175
const ASSISTANT_LIBRARIAN_CACHE_FOOTPRINT = preload("res://items/cache_data/library/assistant_librarian_cache_footprint.tres") #176
const ASSISTANT_LIBRARIAN_CACHE_CORRUPTION = preload("res://items/cache_data/library/assistant_librarian_cache_corruption.tres") #177
const ASSISTANT_LIBRARIAN_CACHE_NETWORK = preload("res://items/cache_data/library/assistant_librarian_cache_network.tres") #178
const ASSISTANT_LIBRARIAN_CACHE_EXTRACTION = preload("res://items/cache_data/library/assistant_librarian_cache_extraction.tres") #179
const HEAD_LIBRARIAN_CACHE_FOOTPRINT = preload("res://items/cache_data/library/head_librarian_cache_footprint.tres") #180
const HEAD_LIBRARIAN_CACHE_CORRUPTION = preload("res://items/cache_data/library/head_librarian_cache_corruption.tres") #181
const HEAD_LIBRARIAN_CACHE_NETWORK = preload("res://items/cache_data/library/head_librarian_cache_network.tres") #182
const HEAD_LIBRARIAN_CACHE_EXTRACTION = preload("res://items/cache_data/library/head_librarian_cache_extraction.tres") #183
const DIRECTOR_CACHE_FOOTPRINT = preload("res://items/cache_data/library/director_cache_footprint.tres") #184
const DIRECTOR_CACHE_CORRUPTION = preload("res://items/cache_data/library/director_cache_corruption.tres") #185
const DIRECTOR_CACHE_NETWORK = preload("res://items/cache_data/library/director_cache_network.tres") #186
const DIRECTOR_CACHE_EXTRACTION = preload("res://items/cache_data/library/director_cache_extraction.tres") #187

#small business
const WORKER_CACHE = preload("res://items/cache_data/small_business/worker_cache.tres")
const SUPERVISOR_CACHE = preload("res://items/cache_data/small_business/supervisor_cache.tres")
const MANAGER_CACHE = preload("res://items/cache_data/small_business/manager_cache.tres")
const HUMAN_RESOURCES_CACHE = preload("res://items/cache_data/small_business/human_resources_cache.tres")
const OWNER_CACHE = preload("res://items/cache_data/small_business/owner_cache.tres")
const WORKER_CACHE_FOOTPRINT = preload("res://items/cache_data/small_business/worker_cache_footprint.tres") #188
const WORKER_CACHE_CORRUPTION = preload("res://items/cache_data/small_business/worker_cache_corruption.tres") #189
const WORKER_CACHE_NETWORK = preload("res://items/cache_data/small_business/worker_cache_network.tres") #190
const WORKER_CACHE_EXTRACTION = preload("res://items/cache_data/small_business/worker_cache_extraction.tres") #191
const SUPERVISOR_CACHE_FOOTPRINT = preload("res://items/cache_data/small_business/supervisor_cache_footprint.tres") #192
const SUPERVISOR_CACHE_CORRUPTION = preload("res://items/cache_data/small_business/supervisor_cache_corruption.tres") #193
const SUPERVISOR_CACHE_NETWORK = preload("res://items/cache_data/small_business/supervisor_cache_network.tres") #194
const SUPERVISOR_CACHE_EXTRACTION = preload("res://items/cache_data/small_business/supervisor_cache_extraction.tres") #195
const MANAGER_CACHE_FOOTPRINT = preload("res://items/cache_data/small_business/manager_cache_footprint.tres") #196
const MANAGER_CACHE_CORRUPTION = preload("res://items/cache_data/small_business/manager_cache_corruption.tres") #197
const MANAGER_CACHE_NETWORK = preload("res://items/cache_data/small_business/manager_cache_network.tres") #198
const MANAGER_CACHE_EXTRACTION = preload("res://items/cache_data/small_business/manager_cache_extraction.tres") #199
const HUMAN_RESOURCES_CACHE_FOOTPRINT = preload("res://items/cache_data/small_business/human_resources_cache_footprint.tres") #200
const HUMAN_RESOURCES_CACHE_CORRUPTION = preload("res://items/cache_data/small_business/human_resources_cache_corruption.tres") #201
const HUMAN_RESOURCES_CACHE_NETWORK = preload("res://items/cache_data/small_business/human_resources_cache_network.tres") #202
const HUMAN_RESOURCES_CACHE_EXTRACTION = preload("res://items/cache_data/small_business/human_resources_cache_extraction.tres") #203
const OWNER_CACHE_FOOTPRINT = preload("res://items/cache_data/small_business/owner_cache_footprint.tres") #204
const OWNER_CACHE_CORRUPTION = preload("res://items/cache_data/small_business/owner_cache_corruption.tres") #205
const OWNER_CACHE_NETWORK = preload("res://items/cache_data/small_business/owner_cache_network.tres") #206
const OWNER_CACHE_EXTRACTION = preload("res://items/cache_data/small_business/owner_cache_extraction.tres") #207

#university
const TEACHERS_ASSISTANT_CACHE = preload("res://items/cache_data/university/teachers_assistant_cache.tres")
const PROFESSOR_CACHE = preload("res://items/cache_data/university/professor_cache.tres")
const DEPARTMENT_CHAIR_CACHE = preload("res://items/cache_data/university/department_chair_cache.tres")
const DEAN_CACHE = preload("res://items/cache_data/university/dean_cache.tres")
const UNIVERSITY_PRESIDENT_CACHE = preload("res://items/cache_data/university/university_president_cache.tres")
const TEACHERS_ASSISTANT_CACHE_FOOTPRINT = preload("res://items/cache_data/university/teachers_assistant_cache_footprint.tres") #208
const TEACHERS_ASSISTANT_CACHE_CORRUPTION = preload("res://items/cache_data/university/teachers_assistant_cache_corruption.tres") #209
const TEACHERS_ASSISTANT_CACHE_NETWORK = preload("res://items/cache_data/university/teachers_assistant_cache_network.tres") #210
const TEACHERS_ASSISTANT_CACHE_EXTRACTION = preload("res://items/cache_data/university/teachers_assistant_cache_extraction.tres") #211
const PROFESSOR_CACHE_FOOTPRINT = preload("res://items/cache_data/university/professor_cache_footprint.tres") #212
const PROFESSOR_CACHE_CORRUPTION = preload("res://items/cache_data/university/professor_cache_corruption.tres") #213
const PROFESSOR_CACHE_NETWORK = preload("res://items/cache_data/university/professor_cache_network.tres") #214
const PROFESSOR_CACHE_EXTRACTION = preload("res://items/cache_data/university/professor_cache_extraction.tres") #215
const DEPARTMENT_CHAIR_CACHE_FOOTPRINT = preload("res://items/cache_data/university/department_chair_cache_footprint.tres") #216
const DEPARTMENT_CHAIR_CACHE_CORRUPTION = preload("res://items/cache_data/university/department_chair_cache_corruption.tres") #217
const DEPARTMENT_CHAIR_CACHE_NETWORK = preload("res://items/cache_data/university/department_chair_cache_network.tres") #218
const DEPARTMENT_CHAIR_CACHE_EXTRACTION = preload("res://items/cache_data/university/department_chair_cache_extraction.tres") #219
const DEAN_CACHE_FOOTPRINT = preload("res://items/cache_data/university/dean_cache_footprint.tres") #220
const DEAN_CACHE_CORRUPTION = preload("res://items/cache_data/university/dean_cache_corruption.tres") #221
const DEAN_CACHE_NETWORK = preload("res://items/cache_data/university/dean_cache_network.tres") #222
const DEAN_CACHE_EXTRACTION = preload("res://items/cache_data/university/dean_cache_extraction.tres") #223
const UNIVERSITY_PRESIDENT_CACHE_FOOTPRINT = preload("res://items/cache_data/university/university_president_cache_footprint.tres") #224
const UNIVERSITY_PRESIDENT_CACHE_CORRUPTION = preload("res://items/cache_data/university/university_president_cache_corruption.tres") #225
const UNIVERSITY_PRESIDENT_CACHE_NETWORK = preload("res://items/cache_data/university/university_president_cache_network.tres") #226
const UNIVERSITY_PRESIDENT_CACHE_EXTRACTION = preload("res://items/cache_data/university/university_president_cache_extraction.tres") #227

#hospital
const RECEPTIONIST_CACHE = preload("res://items/cache_data/hospital/receptionist_cache.tres")
const ORDERLY_CACHE = preload("res://items/cache_data/hospital/orderly_cache.tres")
const NURSE_CACHE = preload("res://items/cache_data/hospital/nurse_cache.tres")
const DOCTOR_CACHE = preload("res://items/cache_data/hospital/doctor_cache.tres")
const CHIEF_OF_MEDICINE_CACHE = preload("res://items/cache_data/hospital/chief_of_medicine_cache.tres")
const RECEPTIONIST_CACHE_FOOTPRINT = preload("res://items/cache_data/hospital/receptionist_cache_footprint.tres") #228
const RECEPTIONIST_CACHE_CORRUPTION = preload("res://items/cache_data/hospital/receptionist_cache_corruption.tres") #229
const RECEPTIONIST_CACHE_NETWORK = preload("res://items/cache_data/hospital/receptionist_cache_network.tres") #230
const RECEPTIONIST_CACHE_EXTRACTION = preload("res://items/cache_data/hospital/receptionist_cache_extraction.tres") #231
const ORDERLY_CACHE_FOOTPRINT = preload("res://items/cache_data/hospital/orderly_cache_footprint.tres") #232
const ORDERLY_CACHE_CORRUPTION = preload("res://items/cache_data/hospital/orderly_cache_corruption.tres") #233
const ORDERLY_CACHE_NETWORK = preload("res://items/cache_data/hospital/orderly_cache_network.tres") #234
const ORDERLY_CACHE_EXTRACTION = preload("res://items/cache_data/hospital/orderly_cache_extraction.tres") #235
const NURSE_CACHE_FOOTPRINT = preload("res://items/cache_data/hospital/nurse_cache_footprint.tres") #236
const NURSE_CACHE_CORRUPTION = preload("res://items/cache_data/hospital/nurse_cache_corruption.tres") #237
const NURSE_CACHE_NETWORK = preload("res://items/cache_data/hospital/nurse_cache_network.tres") #238
const NURSE_CACHE_EXTRACTION = preload("res://items/cache_data/hospital/nurse_cache_extraction.tres") #239
const DOCTOR_CACHE_FOOTPRINT = preload("res://items/cache_data/hospital/doctor_cache_footprint.tres") #240
const DOCTOR_CACHE_CORRUPTION = preload("res://items/cache_data/hospital/doctor_cache_corruption.tres") #241
const DOCTOR_CACHE_NETWORK = preload("res://items/cache_data/hospital/doctor_cache_network.tres") #242
const DOCTOR_CACHE_EXTRACTION = preload("res://items/cache_data/hospital/doctor_cache_extraction.tres") #243
const CHIEF_OF_MEDICINE_CACHE_FOOTPRINT = preload("res://items/cache_data/hospital/chief_of_medicine_cache_footprint.tres") #244
const CHIEF_OF_MEDICINE_CACHE_CORRUPTION = preload("res://items/cache_data/hospital/chief_of_medicine_cache_corruption.tres") #245
const CHIEF_OF_MEDICINE_CACHE_NETWORK = preload("res://items/cache_data/hospital/chief_of_medicine_cache_network.tres") #246
const CHIEF_OF_MEDICINE_CACHE_EXTRACTION = preload("res://items/cache_data/hospital/chief_of_medicine_cache_extraction.tres") #247

#police station
const SECRETARY_CACHE = preload("res://items/cache_data/police_station/secretary_cache.tres")
const COP_CACHE = preload("res://items/cache_data/police_station/cop_cache.tres")
const DETECTIVE_CACHE = preload("res://items/cache_data/police_station/detective_cache.tres")
const SERGEANT_CACHE = preload("res://items/cache_data/police_station/sergeant_cache.tres")
const CAPTAIN_CACHE = preload("res://items/cache_data/police_station/captain_cache.tres")
const SECRETARY_CACHE_FOOTPRINT = preload("res://items/cache_data/police_station/secretary_cache_footprint.tres") #248
const SECRETARY_CACHE_CORRUPTION = preload("res://items/cache_data/police_station/secretary_cache_corruption.tres") #249
const SECRETARY_CACHE_NETWORK = preload("res://items/cache_data/police_station/secretary_cache_network.tres") #250
const SECRETARY_CACHE_EXTRACTION = preload("res://items/cache_data/police_station/secretary_cache_extraction.tres") #251
const COP_CACHE_FOOTPRINT = preload("res://items/cache_data/police_station/cop_cache_footprint.tres") #252
const COP_CACHE_CORRUPTION = preload("res://items/cache_data/police_station/cop_cache_corruption.tres") #253
const COP_CACHE_NETWORK = preload("res://items/cache_data/police_station/cop_cache_network.tres") #254
const COP_CACHE_EXTRACTION = preload("res://items/cache_data/police_station/cop_cache_extraction.tres") #255
const DETECTIVE_CACHE_FOOTPRINT = preload("res://items/cache_data/police_station/detective_cache_footprint.tres") #256
const DETECTIVE_CACHE_CORRUPTION = preload("res://items/cache_data/police_station/detective_cache_corruption.tres") #257
const DETECTIVE_CACHE_NETWORK = preload("res://items/cache_data/police_station/detective_cache_network.tres") #258
const DETECTIVE_CACHE_EXTRACTION = preload("res://items/cache_data/police_station/detective_cache_extraction.tres") #259
const SERGEANT_CACHE_FOOTPRINT = preload("res://items/cache_data/police_station/sergeant_cache_footprint.tres") #260
const SERGEANT_CACHE_CORRUPTION = preload("res://items/cache_data/police_station/sergeant_cache_corruption.tres") #261
const SERGEANT_CACHE_NETWORK = preload("res://items/cache_data/police_station/sergeant_cache_network.tres") #262
const SERGEANT_CACHE_EXTRACTION = preload("res://items/cache_data/police_station/sergeant_cache_extraction.tres") #263
const CAPTAIN_CACHE_FOOTPRINT = preload("res://items/cache_data/police_station/captain_cache_footprint.tres") #264
const CAPTAIN_CACHE_CORRUPTION = preload("res://items/cache_data/police_station/captain_cache_corruption.tres") #265
const CAPTAIN_CACHE_NETWORK = preload("res://items/cache_data/police_station/captain_cache_network.tres") #266
const CAPTAIN_CACHE_EXTRACTION = preload("res://items/cache_data/police_station/captain_cache_extraction.tres") #267

#law firm
const LEGAL_ASSISTANT_CACHE = preload("res://items/cache_data/law_firm/legal_assistant_cache.tres")
const PARALEGAL_CACHE = preload("res://items/cache_data/law_firm/paralegal_cache.tres")
const ASSOCIATE_ATTORNEY_CACHE = preload("res://items/cache_data/law_firm/associate_attorney_cache.tres")
const LAWYER_CACHE = preload("res://items/cache_data/law_firm/lawyer_cache.tres")
const PARTNER_CACHE = preload("res://items/cache_data/law_firm/partner_cache.tres")
const LEGAL_ASSISTANT_CACHE_FOOTPRINT = preload("res://items/cache_data/law_firm/legal_assistant_cache_footprint.tres") #268
const LEGAL_ASSISTANT_CACHE_CORRUPTION = preload("res://items/cache_data/law_firm/legal_assistant_cache_corruption.tres") #269
const LEGAL_ASSISTANT_CACHE_NETWORK = preload("res://items/cache_data/law_firm/legal_assistant_cache_network.tres") #270
const LEGAL_ASSISTANT_CACHE_EXTRACTION = preload("res://items/cache_data/law_firm/legal_assistant_cache_extraction.tres") #271
const PARALEGAL_CACHE_FOOTPRINT = preload("res://items/cache_data/law_firm/paralegal_cache_footprint.tres") #272
const PARALEGAL_CACHE_CORRUPTION = preload("res://items/cache_data/law_firm/paralegal_cache_corruption.tres") #273
const PARALEGAL_CACHE_NETWORK = preload("res://items/cache_data/law_firm/paralegal_cache_network.tres") #274
const PARALEGAL_CACHE_EXTRACTION = preload("res://items/cache_data/law_firm/paralegal_cache_extraction.tres") #275
const ASSOCIATE_ATTORNEY_CACHE_FOOTPRINT = preload("res://items/cache_data/law_firm/associate_attorney_cache_footprint.tres") #276
const ASSOCIATE_ATTORNEY_CACHE_CORRUPTION = preload("res://items/cache_data/law_firm/associate_attorney_cache_corruption.tres") #277
const ASSOCIATE_ATTORNEY_CACHE_NETWORK = preload("res://items/cache_data/law_firm/associate_attorney_cache_network.tres") #278
const ASSOCIATE_ATTORNEY_CACHE_EXTRACTION = preload("res://items/cache_data/law_firm/associate_attorney_cache_extraction.tres") #279
const LAWYER_CACHE_FOOTPRINT = preload("res://items/cache_data/law_firm/lawyer_cache_footprint.tres") #280
const LAWYER_CACHE_CORRUPTION = preload("res://items/cache_data/law_firm/lawyer_cache_corruption.tres") #281
const LAWYER_CACHE_NETWORK = preload("res://items/cache_data/law_firm/lawyer_cache_network.tres") #282
const LAWYER_CACHE_EXTRACTION = preload("res://items/cache_data/law_firm/lawyer_cache_extraction.tres") #283
const PARTNER_CACHE_FOOTPRINT = preload("res://items/cache_data/law_firm/partner_cache_footprint.tres") #284
const PARTNER_CACHE_CORRUPTION = preload("res://items/cache_data/law_firm/partner_cache_corruption.tres") #285
const PARTNER_CACHE_NETWORK = preload("res://items/cache_data/law_firm/partner_cache_network.tres") #286
const PARTNER_CACHE_EXTRACTION = preload("res://items/cache_data/law_firm/partner_cache_extraction.tres") #287

#bank
const TELLER_CACHE_FOOTPRINT = preload("res://items/cache_data/bank/teller_cache_footprint.tres") #288
const TELLER_CACHE_CORRUPTION = preload("res://items/cache_data/bank/teller_cache_corruption.tres") #289
const TELLER_CACHE_NETWORK = preload("res://items/cache_data/bank/teller_cache_network.tres") #290
const TELLER_CACHE_EXTRACTION = preload("res://items/cache_data/bank/teller_cache_extraction.tres") #291
const SECURITY_CACHE_FOOTPRINT = preload("res://items/cache_data/bank/security_cache_footprint.tres") #292
const SECURITY_CACHE_CORRUPTION = preload("res://items/cache_data/bank/security_cache_corruption.tres") #293
const SECURITY_CACHE_NETWORK = preload("res://items/cache_data/bank/security_cache_network.tres") #294
const SECURITY_CACHE_EXTRACTION = preload("res://items/cache_data/bank/security_cache_extraction.tres") #295
const LOAN_OFFICER_CACHE_FOOTPRINT = preload("res://items/cache_data/bank/officer_cache_footprint.tres") #296
const LOAN_OFFICER_CACHE_CORRUPTION = preload("res://items/cache_data/bank/officer_cache_corruption.tres") #297
const LOAN_OFFICER_CACHE_NETWORK = preload("res://items/cache_data/bank/officer_cache_network.tres") #298
const LOAN_OFFICER_CACHE_EXTRACTION = preload("res://items/cache_data/bank/officer_cache_extraction.tres") #299
const BRANCH_MANAGER_CACHE_FOOTPRINT = preload("res://items/cache_data/bank/manager_cache_footprint.tres") #300
const BRANCH_MANAGER_CACHE_CORRUPTION = preload("res://items/cache_data/bank/manager_cache_corruption.tres") #301
const BRANCH_MANAGER_CACHE_NETWORK = preload("res://items/cache_data/bank/manager_cache_network.tres") #302
const BRANCH_MANAGER_CACHE_EXTRACTION = preload("res://items/cache_data/bank/manager_cache_extraction.tres") #303
const CFO_CACHE_FOOTPRINT = preload("res://items/cache_data/bank/cfo_cache_footprint.tres") #304
const CFO_CACHE_CORRUPTION = preload("res://items/cache_data/bank/cfo_cache_corruption.tres") #305
const CFO_CACHE_NETWORK = preload("res://items/cache_data/bank/cfo_cache_network.tres") #306
const CFO_CACHE_EXTRACTION = preload("res://items/cache_data/bank/cfo_cache_extraction.tres") #307
#government
const CLERK_CACHE_FOOTPRINT = preload("res://items/cache_data/government/clerk_cache_footprint.tres") #308
const CLERK_CACHE_CORRUPTION = preload("res://items/cache_data/government/clerk_cache_corruption.tres") #309
const CLERK_CACHE_NETWORK = preload("res://items/cache_data/government/clerk_cache_network.tres") #310
const CLERK_CACHE_EXTRACTION = preload("res://items/cache_data/government/clerk_cache_extraction.tres") #311
const ANALYST_CACHE_FOOTPRINT = preload("res://items/cache_data/government/analyst_cache_footprint.tres") #312
const ANALYST_CACHE_CORRUPTION = preload("res://items/cache_data/government/analyst_cache_corruption.tres") #313
const ANALYST_CACHE_NETWORK = preload("res://items/cache_data/government/analyst_cache_network.tres") #314
const ANALYST_CACHE_EXTRACTION = preload("res://items/cache_data/government/analyst_cache_extraction.tres") #315
const AMBASSADOR_CACHE_FOOTPRINT = preload("res://items/cache_data/government/ambassador_cache_footprint.tres") #316
const AMBASSADOR_CACHE_CORRUPTION = preload("res://items/cache_data/government/ambassador_cache_corruption.tres") #317
const AMBASSADOR_CACHE_NETWORK = preload("res://items/cache_data/government/ambassador_cache_network.tres") #318
const AMBASSADOR_CACHE_EXTRACTION = preload("res://items/cache_data/government/ambassador_cache_extraction.tres") #319
const VICE_PRESIDENT_CACHE_FOOTPRINT = preload("res://items/cache_data/government/vice_president_cache_footprint.tres") #320
const VICE_PRESIDENT_CACHE_CORRUPTION = preload("res://items/cache_data/government/vice_president_cache_corruption.tres") #321
const VICE_PRESIDENT_CACHE_NETWORK = preload("res://items/cache_data/government/vice_president_cache_network.tres") #322
const VICE_PRESIDENT_CACHE_EXTRACTION = preload("res://items/cache_data/government/vice_president_cache_extraction.tres") #323
const PRESIDENT_CACHE_FOOTPRINT = preload("res://items/cache_data/government/president_cache_footprint.tres") #324
const PRESIDENT_CACHE_CORRUPTION = preload("res://items/cache_data/government/president_cache_corruption.tres") #325
const PRESIDENT_CACHE_NETWORK = preload("res://items/cache_data/government/president_cache_network.tres") #326
const PRESIDENT_CACHE_EXTRACTION = preload("res://items/cache_data/government/president_cache_extraction.tres") #327
const PROXY_HOP = preload("res://items/exploits/proxy_hop.tres") #328
const LAG_SPIKE = preload("res://items/exploits/lag_spike.tres") #329
const CEASE_DESIST = preload("res://items/exploits/cease_desist.tres") #330
const THROTTLE_PATCH = preload("res://items/exploits/throttle_patch.tres") #331
const SLOW_DRIP = preload("res://items/exploits/slow_drip.tres") #332
const BOOSTER_SHOT = preload("res://items/exploits/booster_shot.tres") #333
const OVERDRAFT = preload("res://items/exploits/overdraft.tres") #334
const MARGIN_CALL = preload("res://items/exploits/margin_call.tres") #335
const ZERO_DAY = preload("res://items/exploits/zero_day.tres") #336
const GHOST_MODE = preload("res://items/exploits/ghost_mode.tres") #337
const REDACTION = preload("res://items/exploits/redaction.tres") #338
const BLACKOUT = preload("res://items/exploits/blackout.tres") #339
const SHATTER_PROTOCOL = preload("res://items/hacking_mods/shatter_protocol.tres") #340
const BURST_BUFFER = preload("res://items/hacking_mods/burst_buffer.tres") #341
const FIRMWARE_BRICK = preload("res://items/hacking_mods/firmware_brick.tres") #342
const PAYLOAD_AMPLIFIER = preload("res://items/hacking_mods/payload_amplifier.tres") #343
const VULN_SCANNER = preload("res://items/hacking_mods/vuln_scanner.tres") #344
const CRITICAL_OVERFLOW = preload("res://items/hacking_mods/critical_overflow.tres") #345
const PROXY_CHAIN = preload("res://items/hacking_mods/proxy_chain.tres") #346
const GHOST_PACKET = preload("res://items/hacking_mods/ghost_packet.tres") #347
const DECOY_TRAFFIC = preload("res://items/hacking_mods/decoy_traffic.tres") #348
const PACKET_SHREDDER = preload("res://items/hacking_mods/packet_shredder.tres") #349
const LATENCY_INJECTOR = preload("res://items/hacking_mods/latency_injector.tres") #350
const SILENT_ENTRY = preload("res://items/hacking_mods/silent_entry.tres") #351
const IP_ROTATOR = preload("res://items/hacking_mods/ip_rotator.tres") #352
const ZERO_HOUR = preload("res://items/hacking_mods/zero_hour.tres") #353
const CASCADE = preload("res://items/hacking_mods/cascade.tres") #354
const MIRROR = preload("res://items/hacking_mods/mirror.tres") #355
const COLD_BOOT = preload("res://items/hacking_mods/cold_boot.tres") #356
const VM_CACHE = preload("res://items/cache_data/vm_cache.tres") #357
const HANDSHAKE_EXPLOIT = preload("res://items/hacking_mods/handshake_exploit.tres") #358
const BACKDOOR = preload("res://items/hacking_mods/backdoor.tres") #359
const RESET_LOOP = preload("res://items/hacking_mods/reset_loop.tres") #360
const HARDENED_SHELL = preload("res://items/hacking_mods/hardened_shell.tres") #361
const FRESH_START = preload("res://items/hacking_mods/fresh_start.tres") #362
const OPENING_SPOOF = preload("res://items/hacking_mods/opening_spoof.tres") #363
const HOT_STREAK = preload("res://items/hacking_mods/hot_streak.tres") #364
const DOUBLE_TAP = preload("res://items/hacking_mods/double_tap.tres") #365
const BLEED = preload("res://items/hacking_mods/bleed.tres") #366
const BREACH_MOMENTUM = preload("res://items/hacking_mods/breach_momentum.tres") #367
const LEECH = preload("res://items/hacking_mods/leech.tres") #368
const JITTER = preload("res://items/hacking_mods/jitter.tres") #369
const FAILSAFE = preload("res://items/hacking_mods/failsafe.tres") #370
const DATA_HOARDER = preload("res://items/hacking_mods/data_hoarder.tres") #371
const PACKET_FLOOD = preload("res://items/exploits/packet_flood.tres") #372
const SMOKE_SCREEN = preload("res://items/exploits/smoke_screen.tres") #373
const OVERCHARGE = preload("res://items/exploits/overcharge.tres") #374
const PORT_KNOCK = preload("res://items/exploits/port_knock.tres") #375
const QUICK_PATCH = preload("res://items/exploits/quick_patch.tres") #376
const TRACE_SCRAMBLER = preload("res://items/exploits/trace_scrambler.tres") #377
const CREDENTIAL_STUFFING = preload("res://items/exploits/credential_stuffing.tres") #378
const HEAT_SINK = preload("res://items/exploits/heat_sink.tres") #379
const ROOTKIT = preload("res://items/exploits/rootkit.tres") #380
const MIRROR_IMAGE = preload("res://items/exploits/mirror_image.tres") #381
const FIREWALL_DRAIN = preload("res://items/exploits/firewall_drain.tres") #382
const SUPPLY_DROP = preload("res://items/exploits/supply_drop.tres") #383
const CHAIN_REACTION = preload("res://items/exploits/chain_reaction.tres") #384
const FREEZE = preload("res://items/exploits/freeze.tres") #385
const EXFIL_WINDOW = preload("res://items/exploits/exfil_window.tres") #386
const ROOT_ACCESS = preload("res://items/exploits/root_access.tres") #387
const TOTAL_RECALL = preload("res://items/exploits/total_recall.tres") #388
const SYSTEM_PURGE = preload("res://items/exploits/system_purge.tres") #389

var ITEM_NAME_MAP = {}

func _ready():
	for item in ITEM_MAP.values():
		ITEM_NAME_MAP[item.name.to_lower()] = item

const ITEM_MAP = {
	ItemType.DATA: DATA,
	ItemType.LOGS: LOGS,
	ItemType.ENCRYPTED_PASSWORDS: ENCRYPTED_PASSWORDS,
	ItemType.PASSWORDS: PASSWORDS,
	ItemType.USERNAMES: USERNAMES,
	ItemType.CREDENTIALS: CREDENTIALS,
	ItemType.IP_ADDRESS: IP_ADDRESS,
	ItemType.PARENTS_CREDIT_CARD: PARENTS_CREDIT_CARD,
	ItemType.STUDENT_CACHE: STUDENT_CACHE,
	ItemType.FALSIFIED_TRANSCRIPT_DATABASE: FALSIFIED_TRANSCRIPT_DATABASE,
	ItemType.ADMIN_CACHE: ADMIN_CACHE,
	ItemType.STUDENT_DISCIPLINARY_RECORDS: STUDENT_DISCIPLINARY_RECORDS,
	ItemType.SCHOOL_BUDGET_EMBEZZLEMENT_LOGS: SCHOOL_BUDGET_EMBEZZLEMENT_LOGS,
	ItemType.DISTRICT_WIDE_MASTER_PASSWORD: DISTRICT_WIDE_MASTER_PASSWORD,
	ItemType.VICE_PRINCIPAL_CACHE: VICE_PRINCIPAL_CACHE,
	ItemType.PRINCIPAL_CACHE: PRINCIPAL_CACHE,
	ItemType.SUPERINTENDENT_CACHE: SUPERINTENDENT_CACHE,
	ItemType.BORROWED_BOOK_HISTORY: BORROWED_BOOK_HISTORY,
	ItemType.INTERNAL_STAFF_LOGIN_CREDENTIALS: INTERNAL_STAFF_LOGIN_CREDENTIALS,
	ItemType.DIGITIZED_RARE_BOOK_SCAN: DIGITIZED_RARE_BOOK_SCAN,
	ItemType.OVERDUE_FINE_WAIVER_DATABASE: OVERDUE_FINE_WAIVER_DATABASE,
	ItemType.CENSORED_BOOKS_ARCHIVE: CENSORED_BOOKS_ARCHIVE,
	ItemType.PATRON_CACHE: PATRON_CACHE,
	ItemType.VOLUNTEER_CACHE: VOLUNTEER_CACHE,
	ItemType.ASSISTANT_LIBRARIAN_CACHE: ASSISTANT_LIBRARIAN_CACHE,
	ItemType.HEAD_LIBRARIAN_CACHE: HEAD_LIBRARIAN_CACHE,
	ItemType.DIRECTOR_CACHE: DIRECTOR_CACHE,
	ItemType.EMPLOYEE_PAYROLL_DATA: EMPLOYEE_PAYROLL_DATA,
	ItemType.SHIFT_SCHEDULE_AND_SECURITY_ROTATION: SHIFT_SCHEDULE_AND_SECURITY_ROTATION,
	ItemType.SUPPLIER_CONTACT_LIST: SUPPLIER_CONTACT_LIST,
	ItemType.CONFIDENTIAL_HR_COMPLAINT_FILES: CONFIDENTIAL_HR_COMPLAINT_FILES,
	ItemType.UNRELEASED_PRODUCT_PROTOTYPE: UNRELEASED_PRODUCT_PROTOTYPE,
	ItemType.WORKER_CACHE: WORKER_CACHE,
	ItemType.SUPERVISOR_CACHE: SUPERVISOR_CACHE,
	ItemType.MANAGER_CACHE: MANAGER_CACHE,
	ItemType.HUMAN_RESOURCES_CACHE: HUMAN_RESOURCES_CACHE,
	ItemType.OWNER_CACHE: OWNER_CACHE,
	ItemType.STOLEN_EXAM_ANSWER_KEY: STOLEN_EXAM_ANSWER_KEY,
	ItemType.UNPUBLISHED_RESEARCH_PAPER: UNPUBLISHED_RESEARCH_PAPER,
	ItemType.GRANT_FRAUD_DOCUMENTATION: GRANT_FRAUD_DOCUMENTATION,
	ItemType.ADMISSIONS_BRIBERY_RECORDS: ADMISSIONS_BRIBERY_RECORDS,
	ItemType.ENDOWMENT_FUND_ACCESS_CODES: ENDOWMENT_FUND_ACCESS_CODES,
	ItemType.TEACHERS_ASSISTANT_CACHE: TEACHERS_ASSISTANT_CACHE,
	ItemType.PROFESSOR_CACHE: PROFESSOR_CACHE,
	ItemType.DEPARTMENT_CHAIR_CACHE: DEPARTMENT_CHAIR_CACHE,
	ItemType.DEAN_CACHE: DEAN_CACHE,
	ItemType.UNIVERSITY_PRESIDENT_CACHE: UNIVERSITY_PRESIDENT_CACHE,
	ItemType.PATIENT_APPOINTMENT_HISTORY: PATIENT_APPOINTMENT_HISTORY,
	ItemType.STAFF_KEYCARD_CLONE_DATA: STAFF_KEYCARD_CLONE_DATA,
	ItemType.PRESCRIPTION_PAD_CREDENTIALS: PRESCRIPTION_PAD_CREDENTIALS,
	ItemType.PATIENT_INSURANCE_DATA: PATIENT_INSURANCE_DATA,
	ItemType.FALSIFIED_DRUG_TRIAL_RESULTS: FALSIFIED_DRUG_TRIAL_RESULTS,
	ItemType.RECEPTIONIST_CACHE: RECEPTIONIST_CACHE,
	ItemType.ORDERLY_CACHE: ORDERLY_CACHE,
	ItemType.NURSE_CACHE: NURSE_CACHE,
	ItemType.DOCTOR_CACHE: DOCTOR_CACHE,
	ItemType.CHIEF_OF_MEDICINE_CACHE: CHIEF_OF_MEDICINE_CACHE,
	ItemType.INTERNAL_AFFAIRS_COMPLAINT_ARCHIVE: INTERNAL_AFFAIRS_COMPLAINT_ARCHIVE,
	ItemType.BODY_CAM_FOOTAGE_DELETION_LOGS: BODY_CAM_FOOTAGE_DELETION_LOGS,
	ItemType.CONFIDENTIAL_INFORMANT_REGISTRY: CONFIDENTIAL_INFORMANT_REGISTRY,
	ItemType.EVIDENCE_LOCKER_ACCESS_CODES: EVIDENCE_LOCKER_ACCESS_CODES,
	ItemType.CORRUPTION_PAYOUT_LEDGER: CORRUPTION_PAYOUT_LEDGER,
	ItemType.SECRETARY_CACHE: SECRETARY_CACHE,
	ItemType.COP_CACHE: COP_CACHE,
	ItemType.DETECTIVE_CACHE: DETECTIVE_CACHE,
	ItemType.SERGEANT_CACHE: SERGEANT_CACHE,
	ItemType.CAPTAIN_CACHE: CAPTAIN_CACHE,
	ItemType.LEAKED_DEPOSITION_TRANSCRIPTS: LEAKED_DEPOSITION_TRANSCRIPTS,
	ItemType.FORGED_COURT_DOCUMENT_TEMPLATES: FORGED_COURT_DOCUMENT_TEMPLATES,
	ItemType.SEALED_CASE_FILES: SEALED_CASE_FILES,
	ItemType.OFFSHORE_ACCOUNT_RECORDS: OFFSHORE_ACCOUNT_RECORDS,
	ItemType.WITNESS_PROTECTION_ADDRESS: WITNESS_PROTECTION_ADDRESS,
	ItemType.LEGAL_ASSISTANT_CACHE: LEGAL_ASSISTANT_CACHE,
	ItemType.PARALEGAL_CACHE: PARALEGAL_CACHE,
	ItemType.ASSOCIATE_ATTORNEY_CACHE: ASSOCIATE_ATTORNEY_CACHE,
	ItemType.LAWYER_CACHE: LAWYER_CACHE,
	ItemType.PARTNER_CACHE: PARTNER_CACHE,
	ItemType.SQL_INJECTOR: SQL_INJECTOR,
	ItemType.PACKET_SPOOF: PACKET_SPOOF,
	ItemType.PINS: PINS,
	ItemType.ENCRYPTED_PINS: ENCRYPTED_PINS,
	ItemType.ACCOUNT_NUMBERS: ACCOUNT_NUMBERS,
	ItemType.ACCOUNT_ACCESS_TOKENS: ACCOUNT_ACCESS_TOKENS,
	ItemType.REFRESH_TOKEN: REFRESH_TOKEN,
	ItemType.QUALITY_LOGS: QUALITY_LOGS,
	ItemType.VM_MINING_TOKEN: VM_MINING_TOKEN,
	ItemType.VM_PARSING_TOKEN: VM_PARSING_TOKEN,
	ItemType.VM_CRACKING_TOKEN: VM_CRACKING_TOKEN,
	ItemType.VM_MATCHING_TOKEN: VM_MATCHING_TOKEN,
	ItemType.VM_PHISHING_TOKEN: VM_PHISHING_TOKEN,
	ItemType.VM_DECODING_TOKEN: VM_DECODING_TOKEN,
	ItemType.SCHOOL_PAYLOAD: SCHOOL_PAYLOAD,
	ItemType.SMALL_BUSINESS_PAYLOAD: SMALL_BUSINESS_PAYLOAD,
	ItemType.LIBRARY_PAYLOAD: LIBRARY_PAYLOAD,
	ItemType.VM_COMPILING_TOKEN: VM_COMPILING_TOKEN,
	ItemType.STUDENT_CACHE_FOOTPRINT: STUDENT_CACHE_FOOTPRINT,
	ItemType.SQL_BOOSTER: SQL_BOOSTER,
	ItemType.ARCHIVES: ARCHIVES,
	ItemType.COOKIES: COOKIES,
	ItemType.DATABASES: DATABASES,
	ItemType.METADATA: METADATA,
	ItemType.REPOSITORIES: REPOSITORIES,
	ItemType.BADGE_HASH: BADGE_HASH,
	ItemType.BIO_TEMPLATE: BIO_TEMPLATE,
	ItemType.DIGITAL_SIGNATURE: DIGITAL_SIGNATURE,
	ItemType.PRIVATE_KEYS: PRIVATE_KEYS,
	ItemType.ACCESS_BADGE: ACCESS_BADGE,
	ItemType.OFFICER_AUTH_KEYS: OFFICER_AUTH_KEYS,
	ItemType.SECURITY_CLEARANCE: SECURITY_CLEARANCE,
	ItemType.SIGNED_CERTIFICATE: SIGNED_CERTIFICATE,
	ItemType.BADGE_NUMBER: BADGE_NUMBER,
	ItemType.CASE_NUMBER: CASE_NUMBER,
	ItemType.CLEARANCE_ID: CLEARANCE_ID,
	ItemType.EMAIL_HEADER: EMAIL_HEADER,
	ItemType.ENCRYPTED_BIO_HASH: ENCRYPTED_BIO_HASH,
	ItemType.ENCRYPTED_SIGNATURE: ENCRYPTED_SIGNATURE,
	ItemType.ENCRYPTED_SSH_KEY: ENCRYPTED_SSH_KEY,
	ItemType.GATEWAY_ADDRESS: GATEWAY_ADDRESS,
	ItemType.MAC_ADDRESS: MAC_ADDRESS,
	ItemType.ROUTING_NUMBER: ROUTING_NUMBER,
	ItemType.STAFF_IDS: STAFF_IDS,
	ItemType.SUBNET_MAP: SUBNET_MAP,
	ItemType.BANK_PAYLOAD: BANK_PAYLOAD,
	ItemType.GOVERNMENT_PAYLOAD: GOVERNMENT_PAYLOAD,
	ItemType.HOSPITAL_PAYLOAD: HOSPITAL_PAYLOAD,
	ItemType.LAWFIRM_PAYLOAD: LAWFIRM_PAYLOAD,
	ItemType.POLICE_PAYLOAD: POLICE_PAYLOAD,
	ItemType.ENCRYPTED_BADGE_HASH: ENCRYPTED_BADGE_HASH, #128
	ItemType.CASH_DRAWER_CODES: CASH_DRAWER_CODES, #129
	ItemType.TELLER_CACHE: TELLER_CACHE, #130
	ItemType.SECURITY_CACHE: SECURITY_CACHE, #131
	ItemType.LOAN_OFFICER_CACHE: LOAN_OFFICER_CACHE, #132
	ItemType.BRANCH_MANAGER_CACHE: BRANCH_MANAGER_CACHE, #133
	ItemType.CFO_CACHE: CFO_CACHE, #134,
	ItemType.CREDIT_RECORDS: CREDIT_RECORDS, #135
	ItemType.SAFE_DEPOSIT_BOX_REGISTERY: SAFE_DEPOSIT_BOX_REGISTERY, #136
	ItemType.SWIFT_MASTER_KEY: SWIFT_MASTER_KEY, #137
	ItemType.VAULT_OVERRIDE: VAULT_OVERRIDE, #138
	ItemType.CLERK_CACHE: CLERK_CACHE, #139
	ItemType.ANALYST_CACHE: ANALYST_CACHE, #140
	ItemType.AMBASSADOR_CACHE: AMBASSADOR_CACHE, #141
	ItemType.VICE_PRESIDENT_CACHE: VICE_PRESIDENT_CACHE, #142
	ItemType.PRESIDENT_CACHE: PRESIDENT_CACHE, #143
	ItemType.REGISTER_VOTER_DB: REGISTER_VOTER_DB, #144 clerk
	ItemType.CIA_BRIEF: CIA_BRIEF, #145 ANALYST
	ItemType.BLACK_BUDGET_LEDGER: BLACK_BUDGET_LEDGER, #146 ambassador
	ItemType.DEEP_COVER_IDS: DEEP_COVER_IDS, #147 vice pres
	ItemType.NUKE_CODES: NUKE_CODES, #148 pres
	ItemType.STUDENT_CACHE_CORRUPTION: STUDENT_CACHE_CORRUPTION, #149
	ItemType.STUDENT_CACHE_NETWORK: STUDENT_CACHE_NETWORK, #150
	ItemType.STUDENT_CACHE_EXTRACTION: STUDENT_CACHE_EXTRACTION, #151
	ItemType.ADMIN_CACHE_FOOTPRINT: ADMIN_CACHE_FOOTPRINT, #152
	ItemType.ADMIN_CACHE_CORRUPTION: ADMIN_CACHE_CORRUPTION, #153
	ItemType.ADMIN_CACHE_NETWORK: ADMIN_CACHE_NETWORK, #154
	ItemType.ADMIN_CACHE_EXTRACTION: ADMIN_CACHE_EXTRACTION, #155
	ItemType.VICE_PRINCIPAL_CACHE_FOOTPRINT: VICE_PRINCIPAL_CACHE_FOOTPRINT, #156
	ItemType.VICE_PRINCIPAL_CACHE_CORRUPTION: VICE_PRINCIPAL_CACHE_CORRUPTION, #157
	ItemType.VICE_PRINCIPAL_CACHE_NETWORK: VICE_PRINCIPAL_CACHE_NETWORK, #158
	ItemType.VICE_PRINCIPAL_CACHE_EXTRACTION: VICE_PRINCIPAL_CACHE_EXTRACTION, #159
	ItemType.PRINCIPAL_CACHE_FOOTPRINT: PRINCIPAL_CACHE_FOOTPRINT, #160
	ItemType.PRINCIPAL_CACHE_CORRUPTION: PRINCIPAL_CACHE_CORRUPTION, #161
	ItemType.PRINCIPAL_CACHE_NETWORK: PRINCIPAL_CACHE_NETWORK, #162
	ItemType.PRINCIPAL_CACHE_EXTRACTION: PRINCIPAL_CACHE_EXTRACTION, #163
	ItemType.SUPERINTENDENT_CACHE_FOOTPRINT: SUPERINTENDENT_CACHE_FOOTPRINT, #164
	ItemType.SUPERINTENDENT_CACHE_CORRUPTION: SUPERINTENDENT_CACHE_CORRUPTION, #165
	ItemType.SUPERINTENDENT_CACHE_NETWORK: SUPERINTENDENT_CACHE_NETWORK, #166
	ItemType.SUPERINTENDENT_CACHE_EXTRACTION: SUPERINTENDENT_CACHE_EXTRACTION, #167
	ItemType.PATRON_CACHE_FOOTPRINT: PATRON_CACHE_FOOTPRINT, #168
	ItemType.PATRON_CACHE_CORRUPTION: PATRON_CACHE_CORRUPTION, #169
	ItemType.PATRON_CACHE_NETWORK: PATRON_CACHE_NETWORK, #170
	ItemType.PATRON_CACHE_EXTRACTION: PATRON_CACHE_EXTRACTION, #171
	ItemType.VOLUNTEER_CACHE_FOOTPRINT: VOLUNTEER_CACHE_FOOTPRINT, #172
	ItemType.VOLUNTEER_CACHE_CORRUPTION: VOLUNTEER_CACHE_CORRUPTION, #173
	ItemType.VOLUNTEER_CACHE_NETWORK: VOLUNTEER_CACHE_NETWORK, #174
	ItemType.VOLUNTEER_CACHE_EXTRACTION: VOLUNTEER_CACHE_EXTRACTION, #175
	ItemType.ASSISTANT_LIBRARIAN_CACHE_FOOTPRINT: ASSISTANT_LIBRARIAN_CACHE_FOOTPRINT, #176
	ItemType.ASSISTANT_LIBRARIAN_CACHE_CORRUPTION: ASSISTANT_LIBRARIAN_CACHE_CORRUPTION, #177
	ItemType.ASSISTANT_LIBRARIAN_CACHE_NETWORK: ASSISTANT_LIBRARIAN_CACHE_NETWORK, #178
	ItemType.ASSISTANT_LIBRARIAN_CACHE_EXTRACTION: ASSISTANT_LIBRARIAN_CACHE_EXTRACTION, #179
	ItemType.HEAD_LIBRARIAN_CACHE_FOOTPRINT: HEAD_LIBRARIAN_CACHE_FOOTPRINT, #180
	ItemType.HEAD_LIBRARIAN_CACHE_CORRUPTION: HEAD_LIBRARIAN_CACHE_CORRUPTION, #181
	ItemType.HEAD_LIBRARIAN_CACHE_NETWORK: HEAD_LIBRARIAN_CACHE_NETWORK, #182
	ItemType.HEAD_LIBRARIAN_CACHE_EXTRACTION: HEAD_LIBRARIAN_CACHE_EXTRACTION, #183
	ItemType.DIRECTOR_CACHE_FOOTPRINT: DIRECTOR_CACHE_FOOTPRINT, #184
	ItemType.DIRECTOR_CACHE_CORRUPTION: DIRECTOR_CACHE_CORRUPTION, #185
	ItemType.DIRECTOR_CACHE_NETWORK: DIRECTOR_CACHE_NETWORK, #186
	ItemType.DIRECTOR_CACHE_EXTRACTION: DIRECTOR_CACHE_EXTRACTION, #187
	ItemType.WORKER_CACHE_FOOTPRINT: WORKER_CACHE_FOOTPRINT, #188
	ItemType.WORKER_CACHE_CORRUPTION: WORKER_CACHE_CORRUPTION, #189
	ItemType.WORKER_CACHE_NETWORK: WORKER_CACHE_NETWORK, #190
	ItemType.WORKER_CACHE_EXTRACTION: WORKER_CACHE_EXTRACTION, #191
	ItemType.SUPERVISOR_CACHE_FOOTPRINT: SUPERVISOR_CACHE_FOOTPRINT, #192
	ItemType.SUPERVISOR_CACHE_CORRUPTION: SUPERVISOR_CACHE_CORRUPTION, #193
	ItemType.SUPERVISOR_CACHE_NETWORK: SUPERVISOR_CACHE_NETWORK, #194
	ItemType.SUPERVISOR_CACHE_EXTRACTION: SUPERVISOR_CACHE_EXTRACTION, #195
	ItemType.MANAGER_CACHE_FOOTPRINT: MANAGER_CACHE_FOOTPRINT, #196
	ItemType.MANAGER_CACHE_CORRUPTION: MANAGER_CACHE_CORRUPTION, #197
	ItemType.MANAGER_CACHE_NETWORK: MANAGER_CACHE_NETWORK, #198
	ItemType.MANAGER_CACHE_EXTRACTION: MANAGER_CACHE_EXTRACTION, #199
	ItemType.HUMAN_RESOURCES_CACHE_FOOTPRINT: HUMAN_RESOURCES_CACHE_FOOTPRINT, #200
	ItemType.HUMAN_RESOURCES_CACHE_CORRUPTION: HUMAN_RESOURCES_CACHE_CORRUPTION, #201
	ItemType.HUMAN_RESOURCES_CACHE_NETWORK: HUMAN_RESOURCES_CACHE_NETWORK, #202
	ItemType.HUMAN_RESOURCES_CACHE_EXTRACTION: HUMAN_RESOURCES_CACHE_EXTRACTION, #203
	ItemType.OWNER_CACHE_FOOTPRINT: OWNER_CACHE_FOOTPRINT, #204
	ItemType.OWNER_CACHE_CORRUPTION: OWNER_CACHE_CORRUPTION, #205
	ItemType.OWNER_CACHE_NETWORK: OWNER_CACHE_NETWORK, #206
	ItemType.OWNER_CACHE_EXTRACTION: OWNER_CACHE_EXTRACTION, #207
	ItemType.TEACHERS_ASSISTANT_CACHE_FOOTPRINT: TEACHERS_ASSISTANT_CACHE_FOOTPRINT, #208
	ItemType.TEACHERS_ASSISTANT_CACHE_CORRUPTION: TEACHERS_ASSISTANT_CACHE_CORRUPTION, #209
	ItemType.TEACHERS_ASSISTANT_CACHE_NETWORK: TEACHERS_ASSISTANT_CACHE_NETWORK, #210
	ItemType.TEACHERS_ASSISTANT_CACHE_EXTRACTION: TEACHERS_ASSISTANT_CACHE_EXTRACTION, #211
	ItemType.PROFESSOR_CACHE_FOOTPRINT: PROFESSOR_CACHE_FOOTPRINT, #212
	ItemType.PROFESSOR_CACHE_CORRUPTION: PROFESSOR_CACHE_CORRUPTION, #213
	ItemType.PROFESSOR_CACHE_NETWORK: PROFESSOR_CACHE_NETWORK, #214
	ItemType.PROFESSOR_CACHE_EXTRACTION: PROFESSOR_CACHE_EXTRACTION, #215
	ItemType.DEPARTMENT_CHAIR_CACHE_FOOTPRINT: DEPARTMENT_CHAIR_CACHE_FOOTPRINT, #216
	ItemType.DEPARTMENT_CHAIR_CACHE_CORRUPTION: DEPARTMENT_CHAIR_CACHE_CORRUPTION, #217
	ItemType.DEPARTMENT_CHAIR_CACHE_NETWORK: DEPARTMENT_CHAIR_CACHE_NETWORK, #218
	ItemType.DEPARTMENT_CHAIR_CACHE_EXTRACTION: DEPARTMENT_CHAIR_CACHE_EXTRACTION, #219
	ItemType.DEAN_CACHE_FOOTPRINT: DEAN_CACHE_FOOTPRINT, #220
	ItemType.DEAN_CACHE_CORRUPTION: DEAN_CACHE_CORRUPTION, #221
	ItemType.DEAN_CACHE_NETWORK: DEAN_CACHE_NETWORK, #222
	ItemType.DEAN_CACHE_EXTRACTION: DEAN_CACHE_EXTRACTION, #223
	ItemType.UNIVERSITY_PRESIDENT_CACHE_FOOTPRINT: UNIVERSITY_PRESIDENT_CACHE_FOOTPRINT, #224
	ItemType.UNIVERSITY_PRESIDENT_CACHE_CORRUPTION: UNIVERSITY_PRESIDENT_CACHE_CORRUPTION, #225
	ItemType.UNIVERSITY_PRESIDENT_CACHE_NETWORK: UNIVERSITY_PRESIDENT_CACHE_NETWORK, #226
	ItemType.UNIVERSITY_PRESIDENT_CACHE_EXTRACTION: UNIVERSITY_PRESIDENT_CACHE_EXTRACTION, #227
	ItemType.RECEPTIONIST_CACHE_FOOTPRINT: RECEPTIONIST_CACHE_FOOTPRINT, #228
	ItemType.RECEPTIONIST_CACHE_CORRUPTION: RECEPTIONIST_CACHE_CORRUPTION, #229
	ItemType.RECEPTIONIST_CACHE_NETWORK: RECEPTIONIST_CACHE_NETWORK, #230
	ItemType.RECEPTIONIST_CACHE_EXTRACTION: RECEPTIONIST_CACHE_EXTRACTION, #231
	ItemType.ORDERLY_CACHE_FOOTPRINT: ORDERLY_CACHE_FOOTPRINT, #232
	ItemType.ORDERLY_CACHE_CORRUPTION: ORDERLY_CACHE_CORRUPTION, #233
	ItemType.ORDERLY_CACHE_NETWORK: ORDERLY_CACHE_NETWORK, #234
	ItemType.ORDERLY_CACHE_EXTRACTION: ORDERLY_CACHE_EXTRACTION, #235
	ItemType.NURSE_CACHE_FOOTPRINT: NURSE_CACHE_FOOTPRINT, #236
	ItemType.NURSE_CACHE_CORRUPTION: NURSE_CACHE_CORRUPTION, #237
	ItemType.NURSE_CACHE_NETWORK: NURSE_CACHE_NETWORK, #238
	ItemType.NURSE_CACHE_EXTRACTION: NURSE_CACHE_EXTRACTION, #239
	ItemType.DOCTOR_CACHE_FOOTPRINT: DOCTOR_CACHE_FOOTPRINT, #240
	ItemType.DOCTOR_CACHE_CORRUPTION: DOCTOR_CACHE_CORRUPTION, #241
	ItemType.DOCTOR_CACHE_NETWORK: DOCTOR_CACHE_NETWORK, #242
	ItemType.DOCTOR_CACHE_EXTRACTION: DOCTOR_CACHE_EXTRACTION, #243
	ItemType.CHIEF_OF_MEDICINE_CACHE_FOOTPRINT: CHIEF_OF_MEDICINE_CACHE_FOOTPRINT, #244
	ItemType.CHIEF_OF_MEDICINE_CACHE_CORRUPTION: CHIEF_OF_MEDICINE_CACHE_CORRUPTION, #245
	ItemType.CHIEF_OF_MEDICINE_CACHE_NETWORK: CHIEF_OF_MEDICINE_CACHE_NETWORK, #246
	ItemType.CHIEF_OF_MEDICINE_CACHE_EXTRACTION: CHIEF_OF_MEDICINE_CACHE_EXTRACTION, #247
	ItemType.SECRETARY_CACHE_FOOTPRINT: SECRETARY_CACHE_FOOTPRINT, #248
	ItemType.SECRETARY_CACHE_CORRUPTION: SECRETARY_CACHE_CORRUPTION, #249
	ItemType.SECRETARY_CACHE_NETWORK: SECRETARY_CACHE_NETWORK, #250
	ItemType.SECRETARY_CACHE_EXTRACTION: SECRETARY_CACHE_EXTRACTION, #251
	ItemType.COP_CACHE_FOOTPRINT: COP_CACHE_FOOTPRINT, #252
	ItemType.COP_CACHE_CORRUPTION: COP_CACHE_CORRUPTION, #253
	ItemType.COP_CACHE_NETWORK: COP_CACHE_NETWORK, #254
	ItemType.COP_CACHE_EXTRACTION: COP_CACHE_EXTRACTION, #255
	ItemType.DETECTIVE_CACHE_FOOTPRINT: DETECTIVE_CACHE_FOOTPRINT, #256
	ItemType.DETECTIVE_CACHE_CORRUPTION: DETECTIVE_CACHE_CORRUPTION, #257
	ItemType.DETECTIVE_CACHE_NETWORK: DETECTIVE_CACHE_NETWORK, #258
	ItemType.DETECTIVE_CACHE_EXTRACTION: DETECTIVE_CACHE_EXTRACTION, #259
	ItemType.SERGEANT_CACHE_FOOTPRINT: SERGEANT_CACHE_FOOTPRINT, #260
	ItemType.SERGEANT_CACHE_CORRUPTION: SERGEANT_CACHE_CORRUPTION, #261
	ItemType.SERGEANT_CACHE_NETWORK: SERGEANT_CACHE_NETWORK, #262
	ItemType.SERGEANT_CACHE_EXTRACTION: SERGEANT_CACHE_EXTRACTION, #263
	ItemType.CAPTAIN_CACHE_FOOTPRINT: CAPTAIN_CACHE_FOOTPRINT, #264
	ItemType.CAPTAIN_CACHE_CORRUPTION: CAPTAIN_CACHE_CORRUPTION, #265
	ItemType.CAPTAIN_CACHE_NETWORK: CAPTAIN_CACHE_NETWORK, #266
	ItemType.CAPTAIN_CACHE_EXTRACTION: CAPTAIN_CACHE_EXTRACTION, #267
	ItemType.LEGAL_ASSISTANT_CACHE_FOOTPRINT: LEGAL_ASSISTANT_CACHE_FOOTPRINT, #268
	ItemType.LEGAL_ASSISTANT_CACHE_CORRUPTION: LEGAL_ASSISTANT_CACHE_CORRUPTION, #269
	ItemType.LEGAL_ASSISTANT_CACHE_NETWORK: LEGAL_ASSISTANT_CACHE_NETWORK, #270
	ItemType.LEGAL_ASSISTANT_CACHE_EXTRACTION: LEGAL_ASSISTANT_CACHE_EXTRACTION, #271
	ItemType.PARALEGAL_CACHE_FOOTPRINT: PARALEGAL_CACHE_FOOTPRINT, #272
	ItemType.PARALEGAL_CACHE_CORRUPTION: PARALEGAL_CACHE_CORRUPTION, #273
	ItemType.PARALEGAL_CACHE_NETWORK: PARALEGAL_CACHE_NETWORK, #274
	ItemType.PARALEGAL_CACHE_EXTRACTION: PARALEGAL_CACHE_EXTRACTION, #275
	ItemType.ASSOCIATE_ATTORNEY_CACHE_FOOTPRINT: ASSOCIATE_ATTORNEY_CACHE_FOOTPRINT, #276
	ItemType.ASSOCIATE_ATTORNEY_CACHE_CORRUPTION: ASSOCIATE_ATTORNEY_CACHE_CORRUPTION, #277
	ItemType.ASSOCIATE_ATTORNEY_CACHE_NETWORK: ASSOCIATE_ATTORNEY_CACHE_NETWORK, #278
	ItemType.ASSOCIATE_ATTORNEY_CACHE_EXTRACTION: ASSOCIATE_ATTORNEY_CACHE_EXTRACTION, #279
	ItemType.LAWYER_CACHE_FOOTPRINT: LAWYER_CACHE_FOOTPRINT, #280
	ItemType.LAWYER_CACHE_CORRUPTION: LAWYER_CACHE_CORRUPTION, #281
	ItemType.LAWYER_CACHE_NETWORK: LAWYER_CACHE_NETWORK, #282
	ItemType.LAWYER_CACHE_EXTRACTION: LAWYER_CACHE_EXTRACTION, #283
	ItemType.PARTNER_CACHE_FOOTPRINT: PARTNER_CACHE_FOOTPRINT, #284
	ItemType.PARTNER_CACHE_CORRUPTION: PARTNER_CACHE_CORRUPTION, #285
	ItemType.PARTNER_CACHE_NETWORK: PARTNER_CACHE_NETWORK, #286
	ItemType.PARTNER_CACHE_EXTRACTION: PARTNER_CACHE_EXTRACTION, #287
	ItemType.TELLER_CACHE_FOOTPRINT: TELLER_CACHE_FOOTPRINT, #288
	ItemType.TELLER_CACHE_CORRUPTION: TELLER_CACHE_CORRUPTION, #289
	ItemType.TELLER_CACHE_NETWORK: TELLER_CACHE_NETWORK, #290
	ItemType.TELLER_CACHE_EXTRACTION: TELLER_CACHE_EXTRACTION, #291
	ItemType.SECURITY_CACHE_FOOTPRINT: SECURITY_CACHE_FOOTPRINT, #292
	ItemType.SECURITY_CACHE_CORRUPTION: SECURITY_CACHE_CORRUPTION, #293
	ItemType.SECURITY_CACHE_NETWORK: SECURITY_CACHE_NETWORK, #294
	ItemType.SECURITY_CACHE_EXTRACTION: SECURITY_CACHE_EXTRACTION, #295
	ItemType.LOAN_OFFICER_CACHE_FOOTPRINT: LOAN_OFFICER_CACHE_FOOTPRINT, #296
	ItemType.LOAN_OFFICER_CACHE_CORRUPTION: LOAN_OFFICER_CACHE_CORRUPTION, #297
	ItemType.LOAN_OFFICER_CACHE_NETWORK: LOAN_OFFICER_CACHE_NETWORK, #298
	ItemType.LOAN_OFFICER_CACHE_EXTRACTION: LOAN_OFFICER_CACHE_EXTRACTION, #299
	ItemType.BRANCH_MANAGER_CACHE_FOOTPRINT: BRANCH_MANAGER_CACHE_FOOTPRINT, #300
	ItemType.BRANCH_MANAGER_CACHE_CORRUPTION: BRANCH_MANAGER_CACHE_CORRUPTION, #301
	ItemType.BRANCH_MANAGER_CACHE_NETWORK: BRANCH_MANAGER_CACHE_NETWORK, #302
	ItemType.BRANCH_MANAGER_CACHE_EXTRACTION: BRANCH_MANAGER_CACHE_EXTRACTION, #303
	ItemType.CFO_CACHE_FOOTPRINT: CFO_CACHE_FOOTPRINT, #304
	ItemType.CFO_CACHE_CORRUPTION: CFO_CACHE_CORRUPTION, #305
	ItemType.CFO_CACHE_NETWORK: CFO_CACHE_NETWORK, #306
	ItemType.CFO_CACHE_EXTRACTION: CFO_CACHE_EXTRACTION, #307
	ItemType.CLERK_CACHE_FOOTPRINT: CLERK_CACHE_FOOTPRINT, #308
	ItemType.CLERK_CACHE_CORRUPTION: CLERK_CACHE_CORRUPTION, #309
	ItemType.CLERK_CACHE_NETWORK: CLERK_CACHE_NETWORK, #310
	ItemType.CLERK_CACHE_EXTRACTION: CLERK_CACHE_EXTRACTION, #311
	ItemType.ANALYST_CACHE_FOOTPRINT: ANALYST_CACHE_FOOTPRINT, #312
	ItemType.ANALYST_CACHE_CORRUPTION: ANALYST_CACHE_CORRUPTION, #313
	ItemType.ANALYST_CACHE_NETWORK: ANALYST_CACHE_NETWORK, #314
	ItemType.ANALYST_CACHE_EXTRACTION: ANALYST_CACHE_EXTRACTION, #315
	ItemType.AMBASSADOR_CACHE_FOOTPRINT: AMBASSADOR_CACHE_FOOTPRINT, #316
	ItemType.AMBASSADOR_CACHE_CORRUPTION: AMBASSADOR_CACHE_CORRUPTION, #317
	ItemType.AMBASSADOR_CACHE_NETWORK: AMBASSADOR_CACHE_NETWORK, #318
	ItemType.AMBASSADOR_CACHE_EXTRACTION: AMBASSADOR_CACHE_EXTRACTION, #319
	ItemType.VICE_PRESIDENT_CACHE_FOOTPRINT: VICE_PRESIDENT_CACHE_FOOTPRINT, #320
	ItemType.VICE_PRESIDENT_CACHE_CORRUPTION: VICE_PRESIDENT_CACHE_CORRUPTION, #321
	ItemType.VICE_PRESIDENT_CACHE_NETWORK: VICE_PRESIDENT_CACHE_NETWORK, #322
	ItemType.VICE_PRESIDENT_CACHE_EXTRACTION: VICE_PRESIDENT_CACHE_EXTRACTION, #323
	ItemType.PRESIDENT_CACHE_FOOTPRINT: PRESIDENT_CACHE_FOOTPRINT, #324
	ItemType.PRESIDENT_CACHE_CORRUPTION: PRESIDENT_CACHE_CORRUPTION, #325
	ItemType.PRESIDENT_CACHE_NETWORK: PRESIDENT_CACHE_NETWORK, #326
	ItemType.PRESIDENT_CACHE_EXTRACTION: PRESIDENT_CACHE_EXTRACTION, #327
	ItemType.PROXY_HOP: PROXY_HOP, #328
	ItemType.LAG_SPIKE: LAG_SPIKE, #329
	ItemType.CEASE_DESIST: CEASE_DESIST, #330
	ItemType.THROTTLE_PATCH: THROTTLE_PATCH, #331
	ItemType.SLOW_DRIP: SLOW_DRIP, #332
	ItemType.BOOSTER_SHOT: BOOSTER_SHOT, #333
	ItemType.OVERDRAFT: OVERDRAFT, #334
	ItemType.MARGIN_CALL: MARGIN_CALL, #335
	ItemType.ZERO_DAY: ZERO_DAY, #336
	ItemType.GHOST_MODE: GHOST_MODE, #337
	ItemType.REDACTION: REDACTION, #338
	ItemType.BLACKOUT: BLACKOUT, #339
	ItemType.SHATTER_PROTOCOL: SHATTER_PROTOCOL, #340
	ItemType.BURST_BUFFER: BURST_BUFFER, #341
	ItemType.FIRMWARE_BRICK: FIRMWARE_BRICK, #342
	ItemType.PAYLOAD_AMPLIFIER: PAYLOAD_AMPLIFIER, #343
	ItemType.VULN_SCANNER: VULN_SCANNER, #344
	ItemType.CRITICAL_OVERFLOW: CRITICAL_OVERFLOW, #345
	ItemType.PROXY_CHAIN: PROXY_CHAIN, #346
	ItemType.GHOST_PACKET: GHOST_PACKET, #347
	ItemType.DECOY_TRAFFIC: DECOY_TRAFFIC, #348
	ItemType.PACKET_SHREDDER: PACKET_SHREDDER, #349
	ItemType.LATENCY_INJECTOR: LATENCY_INJECTOR, #350
	ItemType.SILENT_ENTRY: SILENT_ENTRY, #351
	ItemType.IP_ROTATOR: IP_ROTATOR, #352
	ItemType.ZERO_HOUR: ZERO_HOUR, #353
	ItemType.CASCADE: CASCADE, #354
	ItemType.MIRROR: MIRROR, #355
	ItemType.COLD_BOOT: COLD_BOOT, #356
	ItemType.VM_CACHE: VM_CACHE, #357
	ItemType.HANDSHAKE_EXPLOIT: HANDSHAKE_EXPLOIT, #358
	ItemType.BACKDOOR: BACKDOOR, #359
	ItemType.RESET_LOOP: RESET_LOOP, #360
	ItemType.HARDENED_SHELL: HARDENED_SHELL, #361
	ItemType.FRESH_START: FRESH_START, #362
	ItemType.OPENING_SPOOF: OPENING_SPOOF, #363
	ItemType.HOT_STREAK: HOT_STREAK, #364
	ItemType.DOUBLE_TAP: DOUBLE_TAP, #365
	ItemType.BLEED: BLEED, #366
	ItemType.BREACH_MOMENTUM: BREACH_MOMENTUM, #367
	ItemType.LEECH: LEECH, #368
	ItemType.JITTER: JITTER, #369
	ItemType.FAILSAFE: FAILSAFE, #370
	ItemType.DATA_HOARDER: DATA_HOARDER, #371
	ItemType.PACKET_FLOOD: PACKET_FLOOD, #372
	ItemType.SMOKE_SCREEN: SMOKE_SCREEN, #373
	ItemType.OVERCHARGE: OVERCHARGE, #374
	ItemType.PORT_KNOCK: PORT_KNOCK, #375
	ItemType.QUICK_PATCH: QUICK_PATCH, #376
	ItemType.TRACE_SCRAMBLER: TRACE_SCRAMBLER, #377
	ItemType.CREDENTIAL_STUFFING: CREDENTIAL_STUFFING, #378
	ItemType.HEAT_SINK: HEAT_SINK, #379
	ItemType.ROOTKIT: ROOTKIT, #380
	ItemType.MIRROR_IMAGE: MIRROR_IMAGE, #381
	ItemType.FIREWALL_DRAIN: FIREWALL_DRAIN, #382
	ItemType.SUPPLY_DROP: SUPPLY_DROP, #383
	ItemType.CHAIN_REACTION: CHAIN_REACTION, #384
	ItemType.FREEZE: FREEZE, #385
	ItemType.EXFIL_WINDOW: EXFIL_WINDOW, #386
	ItemType.ROOT_ACCESS: ROOT_ACCESS, #387
	ItemType.TOTAL_RECALL: TOTAL_RECALL, #388
	ItemType.SYSTEM_PURGE: SYSTEM_PURGE, #389
}
