extends Node

func _ready():
    # Jeśli upgrade_purchased istnieje — OK
    # Jeśli nie — ignorujemy
    if GameManager.has_variable("upgrade_purchased"):
        if GameManager.upgrade_purchased:
            print("Upgrade purchased — sound enabled")
    else:
        print("upgrade_purchased not found — skipping")
