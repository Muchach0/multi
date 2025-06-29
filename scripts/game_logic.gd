extends Node2D

@onready var game_over_screen: Control = $CanvasLayer/GameOverScreen
@onready var level_label: Control = $CanvasLayer/LevelLabel
@onready var server_label: Control = $CanvasLayer/IsServerLabel

@onready var star: Area2D = $Star

# @onready var player: Area2D = $PlayerShip
# @onready var init_player_position: Vector2 = player.position

@onready var bullets: Node2D = $Bullets
@onready var init_bullet_count: int = 0
const INCREMENT_BULLET_COUNT = 50
var current_level := 1



# Audio part
@onready var audio_explosion: AudioStreamPlayer = $AudioManager/ExplosionAudioStreamPlayer
@onready var audio_win: AudioStreamPlayer = $AudioManager/WinAudioStreamPlayer

var players: Dictionary = {} # This will hold player data for synchronization



func _ready() -> void:
    # Connect signals to the event bus
    EventBus.connect("player_hit", _on_player_hit)
    EventBus.connect("star_touched", send_star_touched_on_all_peers)
    EventBus.connect("add_player", add_player)

    if multiplayer.is_server():
        server_label.visible = true
    # EventBus.connect("player_respawned", self, "_on_player_respawned")



func add_player(player_id, player_info) -> void:
    if !multiplayer.is_server():
        return

    # if player_id != 1:
    player_info["reach_star"] = false
    players[player_id] = player_info
    print("game_logic.gd - add_player() - Players data: %s" % str(players))


@rpc("any_peer", "call_local", "reliable")
func player_was_hit(player_name, number_of_life: int) -> void:
    audio_explosion.play()
    if multiplayer.is_server():
        players[multiplayer.get_remote_sender_id()]["number_of_life"] = number_of_life
        if number_of_life <= 0:
            print("game_logic - Player %s hit and has no lives left, finishing game." % name)
            get_node(NodePath(player_name)).queue_free()
            # When a player is dead, we call finish_game with is_win set to false to all the players
            finish_game.rpc(false)  # Call finish_game with is_win set to false
        else:
            print("game_logic - Player %s hit! Remaining lives: %d" % [name, number_of_life])

# Called by the authoritative player when a player is hit
func _on_player_hit(player_name, number_of_life: int) -> void:
    print("game_logic - Player hit! Remaining lives: %d" % number_of_life)
    # Handle player hit logic here, e.g., update UI or play sound
    player_was_hit.rpc(player_name, number_of_life)



# The button is restart is pressed by the player (local)
func _on_button_restart_pressed() -> void:
    print("game_logic - Restart button pressed")
    restart_game.rpc()
    # EventBus.emit_signal("player_respawned")
    # player.visible = true
    

    # Freeing the bullets and re-instantiate it
    # bullets.queue_free()

    # # Spawning a new player
    # var player = preload("res://prefab/player_ship.tscn").instantiate()  # Create an instance of the food scene
    # # player.position = init_player_position
    # add_child.call_deferred(player)

    # Spawning the bullets
    # bullets = preload("res://prefab/bullets.tscn").instantiate()  # Create an instance of the bullets script
    # bullets.position = Vector2.ZERO
    # bullets.init_bullet_count = init_bullet_count
    # add_child.call_deferred(bullets)

@rpc("any_peer", "call_local", "reliable")
func restart_game() -> void:
    print("Game restarted.")
    # Handle game restart logic here, e.g., reset player positions, scores, etc.
    # Reset players' reach_star status
    for peer_id in players.keys():
        players[peer_id]["reach_star"] = false

    # Reset the star visibility
    star.visible = true

    # Reset the game over screen
    game_over_screen.visible = false

    # Reset the level label
    level_label.text = "Level: " + str(current_level) + " - Bullets: " + str(init_bullet_count)

    if multiplayer.is_server():
        for player_id in players.keys():
            EventBus.emit_signal("respawn_player", player_id, players[player_id])  # Emit a signal to notify to respawn the player

        EventBus.emit_signal("bullets_init_and_start", init_bullet_count)  # Emit a signal to spawn bullets
        


@rpc("any_peer", "call_local", "reliable")
func finish_game(is_win:= true) -> void:
    print("Game finished.")
    # Handle game finish logic here, e.g., show a win screen or play a sound
    if is_win:
        # Play win sound
        audio_win.play()
        star.visible = false
        game_over_screen.get_node("Label").text = "You Win!"
        game_over_screen.get_node("Button").text = "Next Level"
        init_bullet_count += INCREMENT_BULLET_COUNT
        current_level += 1
    else :
        game_over_screen.get_node("Label").text = "Game Over!"
        game_over_screen.get_node("Button").text = "Restart"
    game_over_screen.visible = true

    # Flush all the bullets currently on the screen
    bullets._exit_tree()


func all_players_reached_star() -> bool:
    # Check if all players have reached the star
    for peer_id in players.keys():
        if not players[peer_id].get("reach_star", false):
            return false
    return true


@rpc("any_peer", "call_local", "reliable")
func star_touched(player_name) -> void: # This function is called when a star is touched by any peer
    var peer_id = multiplayer.get_remote_sender_id()
    print(str(multiplayer.get_unique_id()) + " - game_logic.gd - star_touched() - Star touched by peer: %s" % peer_id)
    # Get the player node from the peer ID
    

    # Play the star touched sound when someone touches the star
    audio_win.play()

    
    # print("Player node: ", player)
    if multiplayer.is_server(): # only the server should delete the player
        players[peer_id]["reach_star"] = true # Update the player's reach_star status
        get_node(NodePath(player_name)).queue_free() # maybe not the best to queue_free the player, but it works for now - throw some errors.
        if all_players_reached_star():
            print("All players reached the star, finishing the game.")
            finish_game.rpc(true) # Call finish_game with is_win set to true

func send_star_touched_on_all_peers(player_name) -> void:
    print("game_logic.gd - send_star_touched_on_all_peers() - Player touched the star: %s" % player_name)
    star_touched.rpc(player_name)
    # Handle star touched logic here, e.g., increase score or play a sound




    # Optionally, you can disable player controls or stop the game loop
    # player.queue_free()
