extends Control


signal start_game()

func _on_start_game_button_pressed() -> void:
	start_game.emit()
	hide()
	
