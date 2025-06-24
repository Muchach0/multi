extends State
class_name PlayerWandering


var player : CharacterBody2D


func Enter():
    print("Entering PlayerWandering state")
    player = get_parent().get_parent() # Getting the grand-parent of the script, i.e. the KinematicBody2D node to move it
    if player.get_node("Animation_Flames"):
        player.get_node("Animation_Flames").play("wandering")
        player.get_node("Animation_Flames").visible = true

        
func Exit():
    print("Exiting PlayerWandering state")
    if player.get_node("Animation_Flames"):
        player.get_node("Animation_Flames").visible = false
        player.get_node("Animation_Flames").stop()
