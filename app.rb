require 'sinatra'
require "sinatra/reloader" if development?
require 'twilio-ruby'
require 'json'
require 'httparty'
require 'giphy'
require 'open_weather'
require 'better_errors'
require 'did_you_mean'
require 'open-uri'

enable :sessions

configure :development do
	require 'dotenv'
	Dotenv.load
	require "better_errors"
	require 'did_you_mean'
	require 'open-uri'
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


def checkVariable1 body
	body = body.downcase.strip
	return (body.size == 1 and body.count("a-z") > 0)
end


def checkVariable2 (body,variable1)
	body = body.downcase.strip
	return (body.size == 1 and body.count("a-z") > 0 and body!= variable1)
end


def determine_response body, sender

#session variable1
session["last_intent"] ||= nil
session["variable1"] ||= nil
session["variable2"] ||= nil

 # user input
	human_greetngs = ["hi","what's up","hello","hi there","what can you do"]
	human_yes_challenge = ["yes","ready","I'm ready"]
	human_no_challenge = ["no","not ready","maybe next time"]
	human_yes_variable1 = ["yes","correct","no problem"]
	human_yes_variable2 = ["yes","correct","no problem"]
	human_no_variable1 = ["no","another","not correct","incorrect"]
	human_no_variable2 = ["no","another","not correct","incorrect"]


	# store chatbot responses into variables
	bot_greetings = "Welcome! This is Sharia, your math agent! I can give you guidance in solving systems of equations! Are you ready to have some math challenges today?"
	error_message = "Sorry, I am not sure I understand."
  math_problem = "Great! Here is the problem for today: \n In 2018, the median annual income of black women is approximately 60% of that of white men. \n John is a white man and Jasmine is a black woman. \n Both of them happened to have an annual income that equals the median income of their groups in 2018. \n John made $20,000 more than Jasmine. \n Questions: How much did John make in 2018? \n How much did Jasmine make in 2018?"

  # define variables
	variable_prompt = "\n It's a little complicated, right? We can break down the problem a little bit. \n Firstly, it will be helpful if we translate the word problem into equations. \n Let's define variables first. "
	variable1 = "What letter would you like to use as a representation for John?"
	variable2 = "What letter would you like to use as a representation for Jasmine?"
	variable1_confirmation = "OK.Use #{session["variable1"]} to stand for John, is that correct?"
	variable2_confirmation  = "Got it! Use #{session["variable2"]} to represent Jasmine, is that correct?"
	variable1_correction = "Please use a letter from a to z for variables"
	variable2_correction = "Please use a letter from a to z for variables that is diffrent from the one you used for John"


  #write equations
	# first equation
	equation1 = "So let's recall the first part. \n In 2018, the median annual income of black women is approximately 60% of that of white men. \n John is a white man and Jasmine is a black woman. \n What equation with variables can we generate according to this condition?"
  equation1options = "\n 1. #{session["variable2"]} = 0.6 #{session["variable1"]} \n 2.#{session["variable1"]} = 0.6 #{session["variable2"]}"
	no_challenge_response = "Alright. Maybe you can come back later. Let me know when you are ready."
	correct_choice_equation1 = "1"
	wrong_choice_equation1 = "2"
  correct_feedback = ["Great! You got it correct!", "Good job!", "Exactly", "That's correct!"]
	equation1_feedback_wrong = "Are you sure? \n #{session["variable1"]} represents John(white man) and #{session["variable2"]} represents Jasmine(black woman). \n #{session["variable2"]}'s income is 60% of that of #{session["variable_1"]}'s. \n Let's try again. "
  #second equation
  equation2 = "Now let's work on the second equation. \n What can you get from the condition 'John made $20,000 more than Jasmine'?"
  equation2_options = "\n 1. #{session["variable2"]} = #{session["variable1"]} + 20000 \n  2.#{session["variable2"]} = #{session["variable1"]} - 20000"
	correct_choice_equation2 = "2"
	wrong_choice_equation2 = "1"
  equation2_feedback_wrong = "Are you sure? Think about whose money is less. Let's do it again. \n"


	#eliminate variable
  eliminate_variable_1 = "OK. Now we get the first equation #{session["variable2"]} = 0.6 #{session["variable1"]} and the second equation #{session["variable2"]} = #{session["variable1"]} + 20000.  What can we do next? "
	eliminate_variable_2 = "Let's substitute y in the second equation with x to eliminate one variable. What equation can we get combining the two equations? "
  eliminate_variable_options = "\n 1. 0.6 #{session["variable1"]} = #{session["variable1"]} - 20000  \n 2. 0.6 #{session["variable1"]} =  #{session["variable1"]} + 20000"
	eliminate_wrong_feedback = "That's not correct! \n we got  #{session["variable2"]} = 0.6 #{session["variable1"]} and  #{session["variable2"]} =  #{session["variable1"]} - 20000. \n What do you get if we substitute the  #{session["variable2"]} with 0.6  #{session["variable1"]} in equation 2?"
	correct_choice_eliminate = "1"
	wrong_choice_eliminate = "2"

# transpose equation
   transpose = "Now let's try to get  #{session["variable1"]} to one side of the equation. \n What do we get if we move  #{session["variable1"]} to one side?"
	 transpose_options = "1.  #{session["variable1"]} + 0.6  #{session["variable1"]} = 20000 \n  2. 0.6  #{session["variable1"]} -  #{session["variable1"]} = -20000"
	 correct_choice_transpose = "2"
 	 wrong_choice_transpose = "1"
	 transpose_wrong_feedback = "That's not correct! \n  That's not correct! We should change sign if we move an element to the other side of the equation. \n Let's try again."


# get the equation
  get_transposed_equation = "What is the equation that we can get after transposing? "
	get_transposed_equation_options = "\n 1. 0.4  #{session["variable1"]} = 20000 \n 2. -0.4  #{session["variable1"]}  = 20000"
	correct_choice_transposed_equation = "1"
	wrong_choice_transposed_equation = "2"
	transposed_equation_wrong_feedback = "That's not correct! \n Let's think about it in this way: \n (0.6-1)  #{session["variable1"]} = -20000, then we divide (-1) in both sides."


# get the value of x
  value_of_x  = "So what is the value of  #{session["variable1"]} that we can get by solving the equation? "
	x_value = "50000"
  x_value_wrong_feedback = "That's not correct! \n We should try to get the coefficient of  #{session["variable1"]} by dividing both sides by 0.4, then we get  #{session["variable1"]} = 2000/0.4. \n You can calculate it on your own or use a calculator.\n Let's try again"


# get the value of  y
 value_of_y = "So, what is the value of  #{session["variable2"]} ?"
 y_value_wrong_feedback = "That's not correct! \n Now that we have the equation  #{session["variable2"]} = 0.6  #{session["variable1"]} and value of  #{session["variable1"]}, we can substitute the  #{session["variable1"]} with the value and get the value of  #{session["variable2"]}! \n Let's try again."



# process of solving systems of equations

proncess = "Congratulations! You have finished the challenge! \n So let's recall the process of solving systems of equations word problems:
\n 1. define variables.
\n 2. get the two equations.
\n 3. eliminate one variable by combining the two equations.
\n 4. solve the equation to get the value of one variable.
\n 5. put the value back to the equation to get the value of the other variable."



body = body.downcase.strip
# happy path
  # first step. introduction
	if session["last_intent"] == nil
		session["last_intent"] = "greeting"
		return bot_greetings

	#confirmation for challenges
elsif session["last_intent"] == "geeting"
	 if match(body, human_yes_challenge)
		session["last_intent"] = "math_challenge"
 		# send_sms_to sender, math_problem
	  # 	sleep(3)
		# send_sms_to sender, variable_prompt
		#   sleep(3)
	  return math_problem + variable_prompt + variable1
	else
		session["last_intent"] = nil
		return no_challenge_response
	end

	# check if the user input of variable1 is valid
elsif session["last_intent"] == "math_challenge"
	 if checkVariable1 body
		  session["last_intent"] = "variable_1"
	  	return variable1_confirmation
   else
		 session["last_intent"] = "math_challenge"
		 return variable1_correction + variable1
	end

	# confirm variable
elsif session["last_intent"] == "variable_1"
		if match(body, human_yes_variable1)
			session["last_intent"] = "variable1_confirm"
			session["variabl1"] = body
		  return variable2
   else
		session["last_intent"] = "math_challenge"
		return "Got it." + variable1
	end

	# check if the user input of variable2 is valid
elsif	session["last_intent"] == "variable1_confirm"
   if checkVariable2(body,variable1)
		session["last_intent"] == "variable_2"
		return variable2_confirmation
	else
		session["last_intent"] = "variable_1_confirm"
		return variable2_correction + variable2
	end

	elsif session["last_intent"] == "variable_2"
		if match(body, human_yes_variable2)
		session["variabl2"] = body
		session["last_intent"] == "variable2_confirmation"
		return equation1 + equation1options
	else
		session["last_intent"] = "variable_1_confirm"
		return "Got it. " + variable2
end

 	# check if the user's choice of equation1 is correct
elsif session["last_intent"] == "variable2_confirmation"
    if body == correct_choice_equation1
		 session["last_intent"] = "equation1"
		 return correct_feedback.sample + equation2 + equation2_options
	 else
		 session["last_intent"] = "variable2_confirmation"
	 	return equation2_feedback_wrong + equation1 + equation1options
end
		# check if the user's choice of equation2 is correct
elsif session["last_intent"] == "equation1"
	if body == correct_choice_equation2
		 session["last_intent"] = "equation2"
		 return correct_feedback.sample + eliminate_variable_1 + eliminate_variable_2
	else
		session["last_intent"] = "equation1"
		return equation2_feedback_wrong + equation2 + equation2_options
end

#elinimate variable
elsif session["last_intent"] == "equation2"
	if body == correct_choice_eliminate
	 session["last_intent"] = "eliminate_variable"
	 return correct_feedback.sample + transpose + transpose_options
 else
	 session["last_intent"] = "equation2"
	 return eliminate_wrong_feedack + eliminate_variable_1 + eliminate_variable_2 + eliminate_variable_options
 end
# transpose the equation

elsif session["last_intent"] == "eliminate_variable"
	if body == correct_choice_transpose
	session["last_intent"] = "transpose"
	return correct_feedback.sample + get_transposed_equation + get_transposed_equation_options
else
	session["last_intent"] = "eliminate_variable"
	return transpose_wrong_feedback + transpose + transpose_options
end

	# get transposed equation
elsif session["last_intent"] == "transpose"
	 if body == correct_choice_transposed_equation
		 session["last_intent"] = "transposed_equation"
		 return correct_feedback.sample + value_of_x
  else
		 session["last_intent"] = "transpose"
		return transposed_equation_wrong_feedback + get_transposed_equation + get_transposed_equation_options
end

# get the value of x
elsif session["last_intent"] == "transposed_equation"
	if body == x_value
  	session["last_intent"] = "get_x_value"
	  return correct_feedback.sample + value_of_y
  else
	 session["last_intent"] = "transposed_equation"
	 return x_value_wrong_feedback + value_of_x
 end

	 # get the value of y
 elsif session["last_intent"] == "get_x_value"
	  if body == y_value
		 session["last_intent"] = "get_y_value"
	 	 return correct_feedback.sample + process
	 else
		  session["last_intent"] = "get_x_value"
	 	 return y_value_wrong_feedback  + value_of_y
	 end

end



get "/sms/incoming" do
	session[:counter] ||= 0

	sender = params[:From] || ""
	body = params[:Body] || ""
  media = determine_media_response body
	message = determine_response body, sender

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



 def send_sms_to send_to, message
 client = Twilio::REST::Client.new ENV["TWILIO_ACCOUNT_SID"], ENV["TWILIO_AUTH_TOKEN"]
 client.api.account.messages.create(
   from: ENV["TWILIO_FROM"],
   to: send_to,
   body: message
 )
​
end




def determine_media_response body
	q = body.to_s.downcase.strip

Giphy::Configuration.configure do |config|
	config.api_key = ENV["GIPHY_API_KEY"]
end

if q == "image"
	giphy_search = "hello"
else
	giphy_search = nil
end

unless giphy_search.nil?
	results = Giphy.search( giphy_search, { limit: 25 } )
	unless results.empty?
		gif = results.sample.fixed_width_downsampled_image.url.to_s
		return gif
	end
end
nil
end
