extends Node2D



var current_hadith_number = 1


var timer_seconds_passed: float = 0
var seconds_per_day: float = 86400
onready var bot = $DiscordBot
var Hadith_Book_Name = "Sahih Al-Bukhari"

func _ready():
	bot.TOKEN = "bot-token"

	bot.connect("bot_ready", self, "_on_DiscordBot_bot_ready")
	bot.connect("message_create", self, "_on_DiscordBot_message_create")
	bot.connect("interaction_create", self, "_on_bot_interaction_create")
	# Connect with Discord
	bot.login()
	
	
	
func _on_DiscordBot_bot_ready(bot: DiscordBot):
	print("Logged in as " + bot.user.username + "#" + bot.user.discriminator)
	print("Ready on " + str(bot.guilds.size()) + " guilds and " + str(bot.channels.size()) + " channels")

	# Set the presence of the bot
	bot.set_presence({
		"activity": {
			"type": "Game",
			"name": "with the intention of seeking knowledge and spreading peace"
		}
	})
	
	
	
	
func _process(delta: float) -> void:
	timer_seconds_passed += delta
	print(timer_seconds_passed)
	if timer_seconds_passed >= seconds_per_day:
		timer_seconds_passed = 0
		run_every_24_hours()

func run_every_24_hours() -> void:
	var hadith_number = current_hadith_number
	print("hadith sent out")
	$HadithAPIRequest.request("https://www.hadithapi.com/public/api/hadiths?apiKey=api-key&hadithNumber=" + str(hadith_number) + "&book=sahih-bukhari")
	


func redo_too_long():
	var hadith_number = current_hadith_number
	print("hadith sent out")
	$HadithAPIRequest.request("https://www.hadithapi.com/public/api/hadiths?apiKey=api-key&hadithNumber=" + str(hadith_number) + "&book=sahih-bukhari")
	
	
func _on_HadithAPI_request_completed(result, response_code, headers, body):
	var json = JSON.parse(body.get_string_from_utf8())
	#print(json.result)
	#print(json.result["hadiths"]["data"][0]["englishNarrator"])
	
	var max_character_limit = 2000  # Discord's character limit for messages
	if len(str(json.result["hadiths"]["data"][0]["hadithEnglish"])) > max_character_limit:
		print("Hadith skipped due to length.")
		bot.send("log_channel_id_or_something", "Had to skip Hadith Number #" + str(current_hadith_number) + " as the hadith length surpasses 2000 characters! Redoing with the next Hadith.")
		current_hadith_number += 1
		redo_too_long()
		return
		
	else:
		
		var hadith_embed = Embed.new()
		var current_datetime = Time.get_time_string_from_system()
		hadith_embed.set_title(str(json.result["hadiths"]["data"][0]["englishNarrator"]))
		hadith_embed.set_description(str(json.result["hadiths"]["data"][0]["hadithEnglish"]))
		hadith_embed.set_footer("Hadith Number #" + str(current_hadith_number) + ", from " + str(Hadith_Book_Name) +". Sent at: " + str(current_datetime))
		current_hadith_number += 1
		bot.send("id of the hadith channel", {"embeds": [hadith_embed]})
	
