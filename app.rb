require 'sinatra'
require "sinatra/reloader" if development?
require 'twilio-ruby'
require 'json'
require 'httparty'
#require 'giphy'

enable :sessions

configure :development do
	require 'dotenv'
	Dotenv.load
end

bot_greetings = ["Hey","Welcome","Yo","Nice to see you","What's up!","Good to see you!","Hey there!"]
morning_greetings = ["Morning","Good morning"]
afternoon_greetings = ["Afternoon","Good afternoon"]
evening_greetings = ["Evening","Good evening"]
code = "sofronia"

get "/" do
	redirect "/about"
end


get "/about" do
	session["visits"] ||= 0 # Set the session to 0 if it hasn't been set before
	session["visits"] = session["visits"] + 1
	# adds one to the current value (increments)
  time = Time.now
	if time.hour >= 0 && time.hour < 12
	    timed_greeting = morning_greetings.sample
	elsif time.hour >= 12 && time.hour <= 18
		 	timed_greeting = afternoon_greetings.sample
	else
			timed_greeting = evening_greetings.sample
	end
  welcome = "#{timed_greeting} #{bot_greetings.sample}"
	description =  "This is a mathbot!"
	welcomeback = "#{timed_greeting}! #{bot_greetings.sample} #{session["first_name"]}"
	timeFormat = time.strftime("%A %B %d, %Y %H:%M")
	visit = "My app can help you solve math problems! You have visited #{session["visits"]} times as of #{timeFormat}"
	if session["first_name"].nil?
		 welcome + "<br/>" + description +  "<br/>" +  visit
	else
		welcomeback + "<br/>" + description  + "<br/>" + visit
	end
	#ENV["TWILIO_FROM"]
end



get "/signup" do
	if not(session['first_name'].nil? || session['number'].nil?)
		return "Hey #{session['first_name']}, you have signed up. Explore more about the bot!"
	elsif params["code"].nil? || params["code"] != code
		403
	else
		erb :signup
	end
end


post "/signup" do
	if params["code"].nil? || params["code"] != code
		403
	elsif params['first_name'].nil? || params['number'].nil?
		"Sorry.You haven't provided all the required information"
	else
			session['first_name'] = params['first_name']
			session['number'] = params['number']
			return "Thank you for signing up! You will receive a text message in a few minutes from the bot."
	end
end

get "/signup/:first_name/:number" do
	session["first_name"] = params["first_name"]
	session["number"] = params["number"]
	"Your enter your name: " + params["first_name"] + ' and your number: ' + params["number"]
end


get '/check' do
  # if the session variable value contains a value
	# display it in the root endpoint
  "value = " << session[:value].inspect
end

get'/try/:value' do
	session["value"] = params["value"]
end

get "/incoming/sms" do
	403
end


# function that can handle different user inputs
def match (body, keywords)
		keywords.each do |keyword|
		keyword = keyword.downcase.strip
		if body.include?(keyword)
			return true
		end
	end
	return false
end


def determine_response body

	human_greetngs = ["hi","what's up","hello","hi there"]
	feature_keywords = ["what","features","cool functions"]
	who_keywords = ["who"]
	where_keywords = ["where"]
	when_keywords = ["when","what time"]
	why_keywords = ["why"]
	joke_keywords = ["joke","tell me a joke","another one","next"]
	fact_keywords = ["fact","facts"]
	fun_keywords = ["haha","lol","so funny"]
	mood_keywords = ["sad","boring","lonely"]


	# store chatbot responses into variables
	bot_greetings = ["Hey!","Welcome!","Yo!","Nice to see you!","What's up!","Good to see you!","Hey there!"]
	error_message =  "Sorry, I am not sure I understand. I can only respond to commands hi, what, who, where, when, and why."
	feature_response = "This is a bot that can help you learn more about me! 🤖\n Just type in some commands such as where, what, why"
	why_response = "It was made for a class project for Programming for online prototypes. \n I want to use this opportunity to introduce myself more easily."
	who_response = "My name is Shujing Lin. I am a METALS student at CMU."
	where_response = "I am in Pittsburgh now!"
	when_response = "I am available on weekends"
	mood_response = ['I am here for you.','I will always be with you', "I love you 🥰"]

	body = body.downcase.strip
	if match(body, human_greetngs)
		return bot_greetings.sample
	# tell some facts about myself
  elsif match(body, mood_keywords)
		return mood_response.sample
	elsif match(body, who_keywords)
		return who_response
	# tell the functionality of the bot
  elsif match(body, feature_keywords)
		return feature_response
# tell my location
	elsif match(body, where_keywords)
		return where_response
	elsif match(body, when_keywords)
		return  when_response
	elsif match(body, why_keywords)
		return why_response
# return a random joke
	elsif match(body, joke_keywords)
			array_of_lines = IO.readlines("jokes.txt")
			return array_of_lines.sample.strip()
	# return a random fact about me
	elsif match(body, fact_keywords)
			array_of_lines_fact = IO.readlines("facts.txt")
			return array_of_lines_fact.sample.strip()
	# react to the user after they see the joke
  elsif match(body, fun_keywords)
			return "funny right?"
	else
	# Sending unexpected answer to the Slack Channel
      return send_to_slack body
	end
end

get "/test/conversation" do
	if params[:Body].nil? || params[:From].nil? #check if parameters are blank
		return "Sorry, I am not sure I understand.\n Try type in some messages and your phone number."
	else
		determine_response params[:Body]
	end
end

error 403 do
	"Access Forbidden"
end


get "/sms/incoming" do
	session[:counter] ||= 0

	sender = params[:From] || ""
	body = params[:Body] || ""
  media = nil
	message = determine_response body

	twiml = Twilio::TwiML::MessagingResponse.new do |r|
		r.message do |m|
			m.body(message)
      unless media.nil?
		   	m.media(media)
	   end
   end
 end
   session[:counter] += 1
	 content_type 'text/xml'
	 twiml.to_s
end

get "/test/sms" do
  # code to check parameters
	#...
  client = Twilio::REST::Client.new ENV["TWILIO_ACCOUNT_SID"], ENV["TWILIO_AUTH_TOKEN"]

  # Include a message here
  message = "Hi, welcome to SoMath!\n I can respond to who, what, where, when and why. If you're stuck, type help."

  # this will send a message from any end point
  client.api.account.messages.create(
    from: ENV["TWILIO_FROM"],
    to:  ENV["TEST_NUMBER"],
    body: message
  )
	# response if eveything is OK
	"You're signed up. You'll receive a text message in a few minutes from the bot. "
end

get "/test/deckofcards/randomcard" do
	 response = HTTParty.get("https://deckofcardsapi.com/api/deck/new/shuffle/?deck_count=1")
	 puts response.body

	 deck_id = response["deck_id"]
	 puts "Deck id is #{deck_id}"
   random_card_url = "https://deckofcardsapi.com/api/deck/#{deck_id}/draw/?count=2"
	 response = HTTParty.get(random_card_url)
	 puts response.body

	 #response["cards"].to_json

	 response_str = "You have drawn"
	 response["cards"].each do |card|
		 suit = card["suit"]
		 value = card["value"]
		 response_str += " the #{value} of #{suit}, "
	 end
	 response_str
end

# get “/test/giphy-sms/” do
# 	Giphy::Configuration.configure do |config|
# 		config.api_key = ENV["GIPHY_API_KEY"]
# 	end
# 	result = Giphy.search("lol", {limit: 3 })
# 	unless result.empty?
# 		gif = result.first
# 		gif_url  = gif.orginal_image.gif_url
#     #{}"<img src ='#{gif_url}' />"
# 		client = Twilio::REST::Client.new ENV["TWILIO_ACCOUNT_SID"], ENV["TWILIO_AUTH_TOKEN"]
#
# 	  # Include a message here
# 	  message = "Hi, welcome to SoMath!\n I can respond to who, what, where, when and why. If you're stuck, type help."
#
# 	  # this will send a message from any end point
# 	  client.api.account.messages.create(
# 	    from: ENV["TWILIO_FROM"],
# 	    to:  ENV["TEST_NUMBER"],
# 	    body: message
# 			media_url: gif_url)
# 		"Sent message with image <img src ='#{gif_url}' />"
# 	else
# 		"I couldn't find a gif for that"
# 	end
# end

def send_to_slack message
	 slack_webhook = ENV['SLACK_WEBHOOK']
	 formatted_message = "*Recently Received:*\n"
	 formatted_message += "#{message} "
	 HTTParty.post slack_webhook, body: {text: formatted_message.to_s, username: "MyBot" }.to_json, headers: {'content-type' => 'application/json'}
end
