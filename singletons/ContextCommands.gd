extends Node

enum TerminalContext {
	ROOT,
	PROCESS,
	DARKWEB
}

var current_context: TerminalContext = TerminalContext.ROOT

var help_text := {
	TerminalContext.ROOT: """
ROOT COMMANDS:
ls -r               Lists all resources
ls -p               List available processes
lp [process name]   Load a process
dw -auth            Connects to the dark web shop
clear               Clears console
help                Shows this help message
quit                Quit game
""",

	TerminalContext.PROCESS: """
PROCESS COMMANDS:
status           Show process status
pause            Pause current process
resume           Resume current process
stop             Stop process
help             Show this help message
exit             Return to main terminal
""",

	TerminalContext.DARKWEB: """
DARK WEB COMMANDS:
ls                            List items to purchase
buy id=[itemID] a=[amount]    Purchase x amount of items (default amount = 1)
balance                       Show available data
exit                          Disconnect from market
help                          Show this help message
"""
}
