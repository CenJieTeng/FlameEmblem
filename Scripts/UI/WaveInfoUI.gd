extends Control

@onready var target = $Panel/target
@onready var wave = $Panel/wave
var max_wave := 0

func init(p_max_wave, target_str):
	target.text  = "目的：" + target_str
	max_wave = p_max_wave

func set_wave(p_wave):
	wave.text = str(p_wave) + "/" + str(max_wave)
