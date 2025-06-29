# Event bus to communicate between nodes
extends Node

signal player_hit
signal player_died
signal respawn_player
signal star_touched
signal add_player # Signal to synchronize player data across peers when a new player connects
signal remove_player # Signal to remove player data across peers when a player disconnects

signal bullets_init_and_start # Signal sent to spawn bullets (the server is running the randomization and send to clients)