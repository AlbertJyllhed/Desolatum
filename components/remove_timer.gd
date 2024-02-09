extends Timer

func _on_timeout():
	owner.queue_free()
