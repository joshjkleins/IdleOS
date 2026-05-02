# Items.gd (autoload)
extends Node
## ADDING ITEMS ##
# Add to ItemType enum
# Remember ID (commented number)
# create resource in items directory 
# assign id (same as ItemType)
# add preload
# add to ITEM_MAP (order not important here(ithink))

## ADDING VALUABLES ##
# Same as above but add to valuables directory and check valuable bool in resource

## ADDING CACHE ##
# Create cache_entry (in appropriate directory) for each item that will be in cache e.g. student_data will be Data and have a min of 1 and max of 10 with a 1.0 (100%) drop chance
# note: drop chance is independent, not weighted. so if its set to 1.0, it will always drop EXCEPT rare drops, then drop chance is ignored in cache_entry
# Once they are all created, create a cache_data resource (again in appropriate directory). and drag cache_entry's to appropriate slots (regular drops & rare drops)
# When creating cache_data resource make sure you follow "ADDING ITEMS" instructions as the ID will matter in ItemType enum
# Once it is created and assigned in this file, go to Stats.gd and assign to appropriate target


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
}

#items
const DATA = preload("res://items/data.tres")
const LOGS = preload("res://items/logs.tres")
const ENCRYPTED_PASSWORDS = preload("res://items/encrypted_passwords.tres")
const PASSWORDS = preload("res://items/passwords.tres")
const USERNAMES = preload("res://items/usernames.tres")
const CREDENTIALS = preload("res://items/credentials.tres")
const IP_ADDRESS = preload("res://items/ip_address.tres")

#valuables
const PARENTS_CREDIT_CARD = preload("res://items/valuables/parents_credit_card.tres")
const FALSIFIED_TRANSCRIPT_DATABASE = preload("res://items/valuables/falsified_transcript_database.tres")
 
#caches
const STUDENT_CACHE = preload("res://items/cache_data/school/student/student_cache.tres")
const ADMIN_CACHE = preload("res://items/cache_data/school/admin/admin_cache.tres")

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
}
