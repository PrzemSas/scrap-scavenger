extends PanelContainer
@onready var desc_l:Label=$VBox/Desc
@onready var bar:ProgressBar=$VBox/Bar
@onready var rew_l:Label=$VBox/Reward
func _ready()->void:
	ChallengeManager.challenge_updated.connect(_upd); visible=false
func _upd(ch:Dictionary)->void:
	visible=true
	if ch.get("done",false):
		desc_l.text="✓ "+ch.get("desc",""); bar.value=100; rew_l.text="DONE!"
	else:
		desc_l.text=ch.get("desc","")
		var p=ChallengeManager.get_progress(); var t=ChallengeManager.get_target()
		bar.value=float(p)/float(t)*100.0
		rew_l.text="%d/%d · %dc"%[p,t,ch.get("reward",0)]
