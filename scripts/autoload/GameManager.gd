extends Node
signal coins_changed(new_amount:int)
signal inventory_changed()
signal upgrade_purchased(upgrade_id:String)
signal sorted_changed()
signal ingots_changed()
signal notification(msg:String)
signal achievement_unlocked(id:String)
signal prestige_done(tokens:int)
signal ground_changed(skin_id:String)
@warning_ignore("unused_signal") signal proximity_entered(panel_id:String)
@warning_ignore("unused_signal") signal proximity_exited(panel_id:String)
@warning_ignore("unused_signal") signal pile_search_progress(progress:float)  # -1 = ukryj, 0..1 = postęp
@warning_ignore("unused_signal") signal pile_hint_changed(text:String)  # "" = ukryj
@warning_ignore("unused_signal") signal smelt_queue_changed(size:int)
@warning_ignore("unused_signal") signal forge_item_purchased(fid:String)
var coins:int=0
var inventory:Array=[]
var sorted_materials:Array=[]
var ingots:Array=[]
var max_slots:int=8
var click_power:int=1
var luck_bonus:float=0.0
var smelt_speed_bonus:float=0.0
var streak:int=0
var best_streak:int=0
var total_sorted:int=0
var correct_sorted:int=0
var lifetime_coins:int=0
var total_collected:int=0
var total_smelted:int=0
var forge_tokens:int=0
var prestige_count:int=0
var play_time:float=0.0
var has_found_gold:bool=false
var inventory_full:bool=false
var current_ground:String="default"
var near_sell_point:bool=false
var total_crafted:int=0
var scrap_crown_crafted:bool=false
var building_materials:Dictionary={"stone_chunk":0,"steel_beam":0,"concrete_slab":0,"wiring":0}
var building_material_values:Dictionary={"stone_chunk":3,"steel_beam":12,"concrete_slab":8,"wiring":15}
var building_material_names:Dictionary={"stone_chunk":"Kawał Skały","steel_beam":"Stalowa Belka","concrete_slab":"Płyta Betonowa","wiring":"Okablowanie"}
signal building_materials_changed()
var forge_stage:int=0
signal forge_stage_changed(stage:int)
const FORGE_REQUIREMENTS:Array=[
	{},
	{"stone_chunk":15,"concrete_slab":8},
	{"steel_beam":12,"wiring":15},
	{"stone_chunk":25,"steel_beam":20,"concrete_slab":15,"wiring":10},
]
const FORGE_STAGE_NAMES:Array=["Nie zbudowana","Fundament","Komnata Kuźni","Tunel Wyjściowy"]
var best_daily_streak:int=0
var best_leaderboard_rank:int=999
var achievements_unlocked:Array=[]
var achievements_config:Array=[
	{"id":"first_scrap","name":"First Scrap","check":"total_collected >= 1"},
	{"id":"hundred_coins","name":"Pocket Change","check":"lifetime_coins >= 100"},
	{"id":"thousand_coins","name":"Scrap Dealer","check":"lifetime_coins >= 1000"},
	{"id":"ten_k","name":"Junk Mogul","check":"lifetime_coins >= 10000"},
	{"id":"fifty_k","name":"Forge Master","check":"lifetime_coins >= 50000"},
	{"id":"hundred_k","name":"Scrap Baron","check":"lifetime_coins >= 100000"},
	{"id":"first_sort","name":"Sorted!","check":"correct_sorted >= 1"},
	{"id":"sort_streak_5","name":"On a Roll","check":"best_streak >= 5"},
	{"id":"sort_streak_10","name":"Sort Machine","check":"best_streak >= 10"},
	{"id":"sort_100","name":"Sorting Pro","check":"correct_sorted >= 100"},
	{"id":"first_smelt","name":"Smelter","check":"total_smelted >= 1"},
	{"id":"ten_ingots","name":"Ingot Factory","check":"total_smelted >= 10"},
	{"id":"gold_find","name":"Gold Rush","check":"has_found_gold == true"},
	{"id":"first_prestige","name":"Meltdown!","check":"prestige_count >= 1"},
	{"id":"prestige_3","name":"Third Burn","check":"prestige_count >= 3"},
	{"id":"prestige_5","name":"Five Flames","check":"prestige_count >= 5"},
	{"id":"full_inv","name":"Hoarder","check":"inventory_full == true"},
	{"id":"collect_100","name":"Scrap Pile","check":"total_collected >= 100"},
	{"id":"collect_500","name":"Landfill","check":"total_collected >= 500"},
	{"id":"play_30min","name":"Dedicated","check":"play_time >= 1800"},
	{"id":"first_craft","name":"Tinker","check":"total_crafted >= 1"},
	{"id":"craft_5","name":"Workshop","check":"total_crafted >= 5"},
	{"id":"craft_crown","name":"Crown Collector","check":"scrap_crown_crafted == true"},
	{"id":"daily_3","name":"Regular","check":"best_daily_streak >= 3"},
	{"id":"daily_7","name":"Devoted","check":"best_daily_streak >= 7"},
	{"id":"daily_30","name":"Fanatic","check":"best_daily_streak >= 30"},
	{"id":"hire_worker","name":"Employer","check":"workers_hired >= 1"},
	{"id":"full_crew","name":"Full Crew","check":"workers_hired >= 3"},
	{"id":"leaderboard_10","name":"On the Board","check":"best_leaderboard_rank <= 10"},
	{"id":"leaderboard_3","name":"Podium","check":"best_leaderboard_rank <= 3"},
]
var scrap_value_bonus:float=0.0
var combo_cap_bonus:float=0.0
var detect_range_bonus:float=0.0
var ingot_value_bonus:float=0.0
var worker_speed_bonus:float=0.0
var wasteland_luck_bonus:float=0.0
var upgrades:Dictionary={"bigger_bag":0,"click_power":0,"lucky_find":0,"fast_furnace":0,"sort_mastery":0,"auto_sort":0,"second_furnace":0,"night_shift":0,"reinforced_bag":0,"scrap_press":0,"combo_master":0,"deep_scan":0}
var upgrade_config:Dictionary={
	"bigger_bag":{"base":30,"mult":1.7,"max":8,"desc":"+2 slots"},
	"click_power":{"base":60,"mult":2.0,"max":5,"desc":"+1/click"},
	"lucky_find":{"base":100,"mult":2.2,"max":6,"desc":"+3% rare"},
	"fast_furnace":{"base":120,"mult":1.9,"max":8,"desc":"-15% time"},
	"sort_mastery":{"base":80,"mult":2.0,"max":8,"desc":"+10% sort"},
	"auto_sort":{"base":5000,"mult":1.0,"max":1,"desc":"Auto-sort"},
	"second_furnace":{"base":2500,"mult":1.0,"max":1,"desc":"+2 queue"},
	"night_shift":{"base":3000,"mult":1.0,"max":1,"desc":"75% offline"},
	"reinforced_bag":{"base":8000,"mult":2.2,"max":4,"desc":"+4 slots","required_stage":1},
	"scrap_press":{"base":6000,"mult":2.5,"max":5,"desc":"+20% item value","required_stage":1},
	"combo_master":{"base":5000,"mult":2.0,"max":5,"desc":"+1 combo cap","required_stage":1},
	"deep_scan":{"base":7000,"mult":2.3,"max":5,"desc":"+30% detect range","required_stage":1},
}
var forge_shop_config:Dictionary={
	"income_boost":{"cost":1,"max":10,"desc":"+10% income"},
	"rare_boost":{"cost":2,"max":5,"desc":"+5% rare"},
	"start_coins":{"cost":1,"max":5,"desc":"Start 500c"},
	"ground_rust":{"cost":1,"max":1,"desc":"Rust skin — warm ember glow"},
	"ground_ash":{"cost":2,"max":1,"desc":"Ash skin — cold blue tint"},
	"ground_gold":{"cost":3,"max":1,"desc":"Gold skin — metallic sheen"},
	"third_furnace":{"cost":3,"max":1,"desc":"3rd furnace"},
	"auto_collect_2":{"cost":2,"max":1,"desc":"Collect 5s"},
	"hire_worker":{"cost":2,"max":3,"desc":"Hire worker NPC"},
	"wasteland_scout":{"cost":3,"max":5,"desc":"+20% rare w Wasteland","required_stage":2},
	"plasma_forge":{"cost":4,"max":5,"desc":"+15% wartość ingotów","required_stage":2},
	"overclock":{"cost":3,"max":4,"desc":"-25% czas wytopu","required_stage":2},
	"worker_turbo":{"cost":5,"max":3,"desc":"Workerzy +50% prędkości","required_stage":2},
}
var forge_purchases:Dictionary={"income_boost":0,"rare_boost":0,"start_coins":0,"ground_rust":0,"ground_ash":0,"ground_gold":0,"third_furnace":0,"auto_collect_2":0,"hire_worker":0,"wasteland_scout":0,"plasma_forge":0,"overclock":0,"worker_turbo":0}
var sort_bins:Dictionary={"ferrous":["bolt","pipe","steel_beam","alloy_frame","titanium_plate"],"electronics":["battery","motor","chip","nano_chip","reactor_core","scrap_drone"],"non_ferrous":["can","cable","coil","wiring"],"precious":["gold","crystal","plasma_cell"],"mechanical":["gear"],"raw":["stone_chunk","concrete_slab"]}
var smelt_config:Dictionary={
	"can":{"time":5.0,"mult":2.0,"ingot":"Aluminum Ingot"},
	"bolt":{"time":10.0,"mult":2.5,"ingot":"Steel Ingot"},
	"pipe":{"time":10.0,"mult":2.5,"ingot":"Steel Ingot"},
	"cable":{"time":8.0,"mult":3.0,"ingot":"Copper Ingot"},
	"battery":{"time":12.0,"mult":2.0,"ingot":"Lead Ingot"},
	"motor":{"time":15.0,"mult":3.5,"ingot":"Circuit Board"},
	"gold":{"time":20.0,"mult":5.0,"ingot":"Gold Ingot"},
	"chip":{"time":10.0,"mult":2.5,"ingot":"Silicon Wafer"},
	"coil":{"time":7.0,"mult":2.8,"ingot":"Copper Wire"},
	"gear":{"time":14.0,"mult":3.5,"ingot":"Titanium Rod"},
	"crystal":{"time":25.0,"mult":6.0,"ingot":"Forge Shard"},
	"alloy_frame":{"time":18.0,"mult":4.0,"ingot":"Alloy Ingot"},
	"titanium_plate":{"time":22.0,"mult":4.5,"ingot":"Titanium Ingot"},
	"nano_chip":{"time":16.0,"mult":3.8,"ingot":"Neural Core"},
	"reactor_core":{"time":30.0,"mult":6.5,"ingot":"Plasma Cell"},
	"scrap_drone":{"time":35.0,"mult":7.0,"ingot":"Drone Core"},
}
var _auto_sort_timer:float=0.0
func _ready()->void:
	get_viewport().physics_object_picking=true
func _process(delta:float)->void:
	play_time+=delta; _check_achievements()
	if upgrades.get("auto_sort",0)>0 and inventory.size()>0:
		_auto_sort_timer+=delta
		if _auto_sort_timer>=3.0:
			_auto_sort_timer=0.0
			var item=inventory[0]; var cb=""
			for bid in sort_bins:
				if item.get("id","") in sort_bins[bid]: cb=bid; break
			if cb!="":
				if randf()<0.93: try_sort(0,cb)
				else: var ks=sort_bins.keys(); try_sort(0,ks[randi()%ks.size()])
var combo_mult:float=1.0
func add_coins(amount:int)->void:
	var b:float=(1.0+forge_tokens*0.1)*(1.0+forge_purchases.get("income_boost",0)*0.1)*combo_mult
	coins+=int(amount*b); lifetime_coins+=int(amount*b); coins_changed.emit(coins)
func spend_coins(amount:int)->bool:
	if coins>=amount: coins-=amount; coins_changed.emit(coins); return true
	return false
func sell_building_material(bid:String)->void:
	if building_materials.get(bid,0)<=0: return
	var val:int=building_material_values.get(bid,1); building_materials[bid]-=1
	add_coins(val); building_materials_changed.emit()
func sell_all_building_materials()->void:
	var total:int=0
	for bid in building_materials:
		total+=building_materials[bid]*building_material_values.get(bid,1)
		building_materials[bid]=0
	if total>0: add_coins(total)
	building_materials_changed.emit()
func get_building_materials_count()->int:
	var total:int=0
	for bid in building_materials: total+=building_materials[bid]
	return total
func can_expand_forge()->bool:
	if forge_stage>=3: return false
	var req:Dictionary=FORGE_REQUIREMENTS[forge_stage+1]
	for mat in req:
		if building_materials.get(mat,0)<req[mat]: return false
	return true
func try_expand_forge()->bool:
	if not can_expand_forge(): return false
	var req:Dictionary=FORGE_REQUIREMENTS[forge_stage+1]
	for mat in req: building_materials[mat]-=req[mat]
	forge_stage+=1
	building_materials_changed.emit()
	forge_stage_changed.emit(forge_stage)
	notification.emit("🔨 %s ukończona!"%FORGE_STAGE_NAMES[forge_stage])
	return true
func add_to_inventory(d:Dictionary)->bool:
	if d.get("category","")=="building":
		var bid:String=d.get("id",""); building_materials[bid]=building_materials.get(bid,0)+1
		total_collected+=1; notification.emit("+1 %s"%d.get("name",bid))
		building_materials_changed.emit(); return true
	if inventory.size()>=max_slots: inventory_full=true; return false
	if scrap_value_bonus > 0.0:
		d = d.duplicate(); d["value"] = int(d.get("value",1) * (1.0 + scrap_value_bonus))
	inventory.append(d); total_collected+=1
	if d.get("id","")=="gold": has_found_gold=true
	if inventory.size()>=max_slots: inventory_full=true
	inventory_changed.emit(); return true
func remove_from_inventory(i:int)->void:
	if i>=0 and i<inventory.size(): inventory.remove_at(i); inventory_changed.emit()
func sell_item(i:int)->void:
	if i>=0 and i<inventory.size(): add_coins(inventory[i].get("value",1)); remove_from_inventory(i)
func sell_all()->void:
	var t:int=0
	for i in inventory: t+=i.get("value",1)
	inventory.clear()
	if t>0: add_coins(t)
	inventory_changed.emit()
func try_sort(idx:int,bid:String)->bool:
	if idx<0 or idx>=inventory.size(): return false
	var item=inventory[idx]; var correct=item.get("id","") in sort_bins.get(bid,[])
	total_sorted+=1
	if correct:
		correct_sorted+=1; streak+=1
		if streak>best_streak: best_streak=streak
		var sv:int=int(item.get("value",1)*1.8*(1.0+upgrades.get("sort_mastery",0)*0.1)*(1.0+minf(streak*0.05,0.5+combo_cap_bonus)))
		var si=item.duplicate(); si["sorted_value"]=sv; sorted_materials.append(si)
		remove_from_inventory(idx); sorted_changed.emit(); return true
	else: streak=0; remove_from_inventory(idx); notification.emit("Wrong bin!"); return false
func add_ingot(d:Dictionary)->void:
	if ingot_value_bonus > 0.0:
		d = d.duplicate(); d["value"] = int(d.get("value",1) * (1.0 + ingot_value_bonus))
	ingots.append(d); total_smelted+=1; ingots_changed.emit()
func sell_ingot(i:int)->void:
	if i>=0 and i<ingots.size(): add_coins(ingots[i].get("value",1)); ingots.remove_at(i); ingots_changed.emit()
func sell_all_ingots()->void:
	var t:int=0
	for ig in ingots: t+=ig.get("value",1)
	ingots.clear()
	if t>0: add_coins(t)
	ingots_changed.emit()
func get_upgrade_cost(uid:String)->int:
	var c=upgrade_config.get(uid,{}); return int(c.get("base",100)*pow(c.get("mult",2.0),upgrades.get(uid,0)))
func get_upgrade_max(uid:String)->int: return upgrade_config.get(uid,{}).get("max",1)
func buy_upgrade(uid:String)->bool:
	if upgrades.get(uid,0)>=get_upgrade_max(uid): return false
	if not spend_coins(get_upgrade_cost(uid)): return false
	upgrades[uid]=upgrades.get(uid,0)+1
	match uid:
		"bigger_bag": max_slots+=2; inventory_changed.emit()
		"click_power": click_power+=1
		"lucky_find": luck_bonus+=0.03
		"fast_furnace": smelt_speed_bonus+=0.15
		"reinforced_bag": max_slots+=4; inventory_changed.emit()
		"scrap_press": scrap_value_bonus+=0.20
		"combo_master": combo_cap_bonus+=1.0
		"deep_scan": detect_range_bonus+=0.30
	upgrade_purchased.emit(uid); return true
func buy_forge_item(fid:String)->bool:
	var c=forge_shop_config.get(fid,{}); var cur=forge_purchases.get(fid,0)
	if cur>=c.get("max",1) or forge_tokens<c.get("cost",1): return false
	forge_tokens-=c.cost; forge_purchases[fid]=cur+1
	match fid:
		"rare_boost": luck_bonus+=0.05
		"ground_rust": current_ground="rust"; ground_changed.emit("rust")
		"ground_ash": current_ground="ash"; ground_changed.emit("ash")
		"ground_gold": current_ground="gold"; ground_changed.emit("gold")
		"third_furnace": smelt_queue_changed.emit(get_smelt_queue_max())
		"wasteland_scout": wasteland_luck_bonus+=0.20
		"plasma_forge": ingot_value_bonus+=0.15
		"overclock": smelt_speed_bonus+=0.25
		"worker_turbo": worker_speed_bonus+=0.50
	notification.emit("Forge: %s"%c.get("desc","")); forge_item_purchased.emit(fid); return true
func can_prestige()->bool: return lifetime_coins>=50000
func get_prestige_tokens()->int:
	if lifetime_coins<10000: return 0
	return int(log(lifetime_coins)/log(10)-3)
func do_prestige()->void:
	if not can_prestige(): return
	var tokens=get_prestige_tokens(); forge_tokens+=tokens; prestige_count+=1
	coins=forge_purchases.get("start_coins",0)*500; inventory.clear(); sorted_materials.clear(); ingots.clear()
	max_slots=8; click_power=1; smelt_speed_bonus=0.0; streak=0
	for key in upgrades: upgrades[key]=0
	luck_bonus=forge_purchases.get("rare_boost",0)*0.05
	coins_changed.emit(coins); inventory_changed.emit(); sorted_changed.emit(); ingots_changed.emit()
	prestige_done.emit(tokens); notification.emit("MELTDOWN! +%d tokens"%[tokens])
func _check_achievements()->void:
	var _names=["total_collected","lifetime_coins","correct_sorted","best_streak","total_smelted","has_found_gold","prestige_count","inventory_full","play_time","total_crafted","scrap_crown_crafted","best_daily_streak","workers_hired","best_leaderboard_rank"]
	var _vals=[total_collected,lifetime_coins,correct_sorted,best_streak,total_smelted,has_found_gold,prestige_count,inventory_full,play_time,total_crafted,scrap_crown_crafted,best_daily_streak,forge_purchases.get("hire_worker",0),best_leaderboard_rank]
	for ach in achievements_config:
		if ach.id in achievements_unlocked: continue
		var expr=Expression.new()
		if expr.parse(ach.check,_names)!=OK: continue
		if expr.execute(_vals)==true:
			achievements_unlocked.append(ach.id); achievement_unlocked.emit(ach.id); notification.emit("🏆 %s"%ach.name)
func get_smelt_queue_max()->int:
	return 3+upgrades.get("second_furnace",0)*2+forge_purchases.get("third_furnace",0)*2
func get_accuracy()->int:
	if total_sorted==0: return 0
	return int(float(correct_sorted)/float(total_sorted)*100.0)
func get_idle_rate()->float:
	var r:float=0.0
	if upgrades.get("click_power",0)>=2: r+=0.1
	if upgrades.get("auto_sort",0)>0: r+=0.2
	return r*(1.0+forge_tokens*0.1)*(1.0+forge_purchases.get("income_boost",0)*0.1)
