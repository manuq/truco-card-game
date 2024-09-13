extends Control

@onready var NetworkGateway = get_node("/root/Main").find_child("NetworkGateway")
@onready var MQTTsignalling = NetworkGateway.MQTTsignalling

var brokeraddress = "mosquitto.doesliverpool.xyz"

var possibleusernames = ["Alice", "Beth", "Cath", "Dan", "Earl", "Fred", "George", "Harry", "Ivan", "John", "Kevin", "Larry", "Martin", "Oliver", "Peter", "Quentin", "Robert", "Samuel", "Thomas", "Ulrik", "Victor", "Wayne", "Xavier", "Youngs", "Zephir"]
func _ready():
	randomize()
	$LineEditName.text = possibleusernames[randi_range(0, len(possibleusernames)-1)]
	print(NetworkGateway)	
	NetworkGateway.MQTTsignalling.connect("xclientstatusesupdate", xclientstatusesupdate)
	NetworkGateway.MQTTsignalling.connect("messagereceived", messagereceived)


var playerswaiting = [ ]
func xclientstatusesupdate():
	$PlayersInGame.clear()
	$PlayersWaiting.clear()
	playerswaiting.clear()
	for s in MQTTsignalling.xclientstatuses:
		if MQTTsignalling.xclientstatuses[s] == "closed":
			continue
		var playername = s
		if MQTTsignalling.xclienttreeitems.has(s) and is_instance_valid(MQTTsignalling.xclienttreeitems[s]):
			playername = MQTTsignalling.xclienttreeitems[s].get_text(1)
		if MQTTsignalling.xclientstatuses[s] == "unconnected":
			$PlayersWaiting.add_item(playername)
			playerswaiting.append(s)
		else:
			$PlayersInGame.add_item(playername)

func _on_button_pressed():
	var clientme = MQTTsignalling.get_node("MQTT").client_id
	var notherplayers = 0
	for s in playerswaiting:
		if s != clientme:
			MQTTsignalling.sendmessage_toclient(s, "<joinme>")
			notherplayers += 1
			if notherplayers == 3:
				break
	Multiplayer.host_or_join_game(true)

func messagereceived(msg, fromclientid):
	if msg == "<joinme>":
		Multiplayer.host_or_join_game(false)
		

func _on_go_online_toggled(toggled_on):
	if toggled_on:
		$LineEditRoom.editable = false
		$LineEditName.editable = false
		NetworkGateway.PlayerConnections.LocalPlayer.setplayername($LineEditName.text)
		NetworkGateway.initialstatemqttwebrtc(NetworkGateway.NETWORK_OPTIONS_MQTT_WEBRTC.AS_NECESSARY_MANUALCHANGE, 
				$LineEditRoom.text, brokeraddress)
		$PlayersInGame.visible = true
		$PlayersWaiting.visible = true
		$Label3.visible = true
		$Label4.visible = true
		$GoOnline.text = "online"

	else:
		NetworkGateway.selectandtrigger_networkoption(NetworkGateway.NETWORK_OPTIONS_MQTT_WEBRTC.NETWORK_OFF)
		$LineEditRoom.editable = true
		$LineEditName.editable = true
		$PlayersInGame.visible = false
		$PlayersWaiting.visible = false
		$Label3.visible = false
		$Label4.visible = false
		$GoOnline.text = "go\nonline"
