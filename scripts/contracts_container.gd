extends Control

@onready var csc = $ContractsSlotsContainer
@onready var ui_slot = preload("res://scenes/contract_ui_slot.tscn")

var contracts_open: bool = false

func _ready():
	Signals.contract_added_signal.connect(contract_added)
	update_contract_ui()

func open_contracts():
	if contracts_open:
		return
	if csc.get_children().size() > 0:
		for c in csc.get_children():
			c.open()
	contracts_open = true

func min_contracts():
	if !contracts_open:
		return
	if csc.get_children().size() > 0:
		for c in csc.get_children():
			c.minimize()
	contracts_open = false

#i believe this is only called on ready
func update_contract_ui():
	for s in csc.get_children():
		s.queue_free()
	
	if ContractsManager.current_contracts.is_empty():
		return
	
	for con in ContractsManager.current_contracts:
		var slot = ui_slot.instantiate()
		slot.connect_contract(con)
		slot.update_info(con)
		slot.visible = true
		csc.add_child(slot)

func contract_added(contract: Contract):
	var slot = ui_slot.instantiate()
	slot.connect_contract(contract)
	slot.update_info(contract)
	#slot.visible = true
	csc.add_child(slot)
	if contracts_open:
		slot.open()
