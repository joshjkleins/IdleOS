extends Node

signal vm_window_focused_signal
signal contract_finished_signal
signal contract_added_signal
signal contracts_removed_signal
signal end_hacking_signal
signal system_temp_updated_signal
signal heat_added_signal
signal hacking_ended_signal
signal defrag_finished_signal
signal update_hacking_header_signal
signal end_hacking_safely_signal
signal item_found_in_cache_signal
signal update_module_header_signal
signal end_log_parsing_safely_signal
signal end_pw_cracking_safely_signal
signal end_cache_decrypting_safely_signal
signal end_data_mining_safely_signal
signal end_cred_matching_safely_signal
signal update_hud_signal
signal update_hud_root_signal
signal end_phishing_safely_signal
signal item_added_signal
signal update_console_signal #used from hacking_game to update main console in hack module

func end_hacking():
	end_hacking_signal.emit()

func system_temp_updated(temp: float):
	system_temp_updated_signal.emit(temp)

func heat_added(heat: float):
	heat_added_signal.emit(heat)

func hacking_ended():
	hacking_ended_signal.emit()

func end_hacking_safely():
	end_hacking_safely_signal.emit()

#hack_container.gd - called when exp, lvl, efficiency, resources etc. are updated
func update_hacking_header():
	update_hacking_header_signal.emit()

func item_found_in_cache(item, amount):
	item_found_in_cache_signal.emit(item, amount)

func update_module_header(process_name: String): #Log Parsing, Cache Decrypting, etc
	update_module_header_signal.emit(process_name)

func end_log_parsing_safely():
	end_log_parsing_safely_signal.emit()

func end_pw_cracking_safely():
	end_pw_cracking_safely_signal.emit()

func end_cache_decrypting_safely():
	end_cache_decrypting_safely_signal.emit()

func end_phishing_safely():
	end_phishing_safely_signal.emit()

func end_data_mining_safely():
	end_data_mining_safely_signal.emit()

func end_cred_matching_safely():
	end_cred_matching_safely_signal.emit()

func update_hud(skill): #SINGLTON AS PARAM
	update_hud_signal.emit(skill)

func update_hud_root():
	update_hud_root_signal.emit()

func item_added(item: ItemData, amount: int):
	item_added_signal.emit(item, amount)

#message: you lost, #type: "Error", "Success"
func update_hack_console(message: String):
	update_console_signal.emit(message)

func contract_added(contract: Contract):
	contract_added_signal.emit(contract)

func defrag_finished():
	defrag_finished_signal.emit()

func vm_window_focused():
	vm_window_focused_signal.emit()
