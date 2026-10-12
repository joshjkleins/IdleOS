extends Node

var process_commands = []

func _ready():
	#LOOP THROUGH ALL SKILLS AND GET COMMANDS
	var skills = [Mining, Parsing, Cracking, Matching, Phishing, Compiling, Hacking, Decoding, Defragging]
	for skill in skills:
		for minor in skill.minor_processes:
			process_commands.append(minor.command)

var cd_commands = [
	"cd mining",
	"cd parsing",
	"cd cracking",
	"cd matching",
	"cd phishing",
	"cd hacking",
	"cd decoding",
	"cd defragging",
	"cd compiling",
	
	"cd ../mining",
	"cd ../parsing",
	"cd ../cracking",
	"cd ../matching",
	"cd ../phishing",
	"cd ../hacking",
	"cd ../decoding",
	"cd ../defragging",
	"cd ../compiling"
]

func get_cd_completions(command: String):
	var potential_commands = []
	
	for cmd in cd_commands:
		if cmd.begins_with(command):
			potential_commands.append(cmd)
	
	return potential_commands


func get_process_completions(command: String, current_context):
	#Left off here - was going to add current_context to this function to only return related process commands
	var potential_commands = []
	for cmd in process_commands:
		if cmd.begins_with(command):
			potential_commands.append(cmd)
			
	return potential_commands

func get_completions(command: String, player_tabbed: int, current_context: String):
	var potential_commands = []
	
	if command.begins_with("cd"):
		potential_commands.append_array(get_cd_completions(command))
	
	
	potential_commands.append_array(get_process_completions(command, current_context))
	
	if potential_commands.is_empty():
		return command
	
	var looped_index = player_tabbed % potential_commands.size()
	
	return potential_commands[looped_index]
