require 'rubygems'
require 'twitter'
require 'yaml'

twittercred = YAML.load_file(File.expand_path('twitter.yml'))
 
Twitter.configure do |config|
  config.consumer_key = twittercred['consumer_key']
  config.consumer_secret = twittercred['consumer_secret']
  config.oauth_token = twittercred['oauth_token']
  config.oauth_token_secret = twittercred['oauth_token_secret']
end

puts 'Who\'s followers do you want?:'
$stdout.flush
who = gets

puts 'What is your username? We\'ll compare users you both follow:'
$stdout.flush
me = gets

puts 'Do you want to follow their followers (followers) or the people they follow (friends)?'
$stdout.flush

type = gets.chomp

def myfriends me
	cursor = "-1"
	myfriendsIds = []
	while cursor != 0 do
	 myfriends = Twitter.friend_ids(me,{:cursor=>cursor})
	 cursor = myfriends.next_cursor
	 myfriendsIds+= myfriends.ids
	 sleep(1)
	end
	return myfriendsIds
end

def whotofollow type, myfriendsIds, who
	unless ["followers", "friends"].include?(type)
		puts ">>> Hmm. That's not right, sorry #{me}. >>> You fail"
  		exit
  	end
	cursor = "-1"
	userIds = []
	while cursor != 0 do
		if type == 'followers'
			users = Twitter.follower_ids(who,{:cursor=>cursor})
		else
			users = Twitter.friend_ids(who,{:cursor=>cursor})
		end
		 cursor = users.next_cursor
		 userIds+= users.ids
		 sleep(1)
	end
	uniqueFollowers = userIds - myfriendsIds
	puts ">>> #{who} has #{uniqueFollowers.size} unique #{type} for you to follow"
	return uniqueFollowers
end

myfriendsIds = myfriends(me)

puts ">>> You follow #{myfriendsIds.size}" 

uniqueFollowers = whotofollow(type, myfriendsIds, who)

puts ">>> There are #{uniqueFollowers.size} new people that you don't follow." 

puts ">>> Should we start following them? (Y/N)"
what = gets.chomp

case what
when "Y"
	uniqueFollowers.each do |followerId|
	  	begin
			Twitter.follow(followerId)
		rescue Twitter::Error::TooManyRequests => error
		    puts "Oops, we are rate limited. We will try again at: #{Time.now + error.rate_limit.reset_in + 5}"
		    sleep error.rate_limit.reset_in + 5
		    retry
		rescue Twitter::Error::ServiceUnavailable => error
			sleep(10)
			retry
		else 
			puts ">>> followed followerID #{followerId}"
		end
		sleep(1)
	end
when "N"
	puts "Ok, well that was a waste of time."
else
	puts "Something went wrong here. Start over."
end