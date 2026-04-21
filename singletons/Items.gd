# Items.gd (autoload)
extends Node

enum ItemType {
	DATA,
	LOGS,
	ENCRYPTED_PASSWORDS,
	PASSWORDS,
	USERNAMES,
	CREDENTIALS,
	IP_ADDRESS
}

const DATA = preload("res://items/data.tres")
const LOGS = preload("res://items/logs.tres")
const ENCRYPTED_PASSWORDS = preload("res://items/encrypted_passwords.tres")
const PASSWORDS = preload("res://items/passwords.tres")
const USERNAMES = preload("res://items/usernames.tres")
const CREDENTIALS = preload("res://items/credentials.tres")
const IP_ADDRESS = preload("res://items/ip_address.tres")
 
const ITEM_MAP = {
	ItemType.DATA: DATA,
	ItemType.LOGS: LOGS,
	ItemType.ENCRYPTED_PASSWORDS: ENCRYPTED_PASSWORDS,
	ItemType.PASSWORDS: PASSWORDS,
	ItemType.USERNAMES: USERNAMES,
	ItemType.CREDENTIALS: CREDENTIALS,
	ItemType.IP_ADDRESS: IP_ADDRESS
}
