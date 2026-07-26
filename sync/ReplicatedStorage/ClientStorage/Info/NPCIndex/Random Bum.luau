-- Services
local RPS = game:GetService("ReplicatedStorage")
local PLRS = game:GetService("Players")

-- Dependancies
local plr = PLRS.LocalPlayer

local Storage = RPS:WaitForChild("ClientStorage")
local QuestIndex = require(Storage:WaitForChild("Info"):WaitForChild("QuestIndex"))
--local NPCActionIndex = require(Storage:WaitForChild("Info"):WaitForChild("NPCActionIndex"))

local plrName = plr and plr.DisplayName or "[player]"

return {	
	OpenAnimation = "Slight Suprise (Looking Down)",
	Dialogues = {
		["First"] = {
			[1] = {
				Text = "..."
			},
			[2] = {
				Text = "Can I help you?"
			},
			[3] = {
				Text = "..."
			},
			[4] = {
				Text = "Oh, you're here from my friend aren't you?",
				Animation = "Double Nod (Looking Down)",
			},
			[5] = {
				Text = "Well, my name is Joker and im one of the researchers here. Im glad your here becuase I need your help on a couple of things",
				NameChange = {
					Text = "Joker",
					Color = Color3.fromRGB(255, 0, 0)
				},
				Animation = "Hand Up Nod (Looking Down)",
			},
			[6] = {
				Text = "I need you to go to mars on that ship up there and get some <AnimateStyle=Appear><Color=Silver>titanium.<Color=/>!<AnimateYield=1><AnimateStyle=/>",
			},
			--[7] = {
			--	Text = "I know it sounds crazy but I need it for my project",
			--	Specialty = "Y/N Quest",	
			--},
			--[8] = {
			--	Text = "Oh well, let me know when your ready",
			--	AltText = {
			--		Text = "Thank you so much. Good luck!",
			--		Condition = {
			--			Past = 7, -- not needed
			--			Answer = 'accepted'
			--		},	
			--		NextDialogue = "Questing"
			--	},
			--}
		--	[1] = {
		--		Text = "..."
		--	},
		--	[2] = {
		--		Text = "Can I help you?"
		--	},
		--	[3] = {
		--		Text = "..."
		--	},
		--	[4] = { Text = "Oh, you're  wondering what this lab is all about, i gotchu" },
		--	[5] = { Text = "Allow me to introduce you to the world of probabilities." },
		--	[6] = { 
		--		Text = "Specifically, we’re looking at something called a <Color=Yellow>geometric distribution<Color=/>, where we measure how many tries it takes to get your first success." 
		--	},
		--	[7] = { 
		--		Text = "Imagine flipping a coin until you get heads. That’s geometric. You're counting how many flips it takes — not just if you get it." 
		--	},
		--	[8] = { 
		--		Text = "It's used in science, quality testing, even video games – anywhere you’re waiting for something to happen." 
		--	},
		--	[9] = { 
		--		Text = "Stick around. The others here will help explain the math, the results, and even show you some simulations." 
		--	},
		--},
		
		--["Questing"] = {
		--	[1] = {
		--		Text = "Hey, its you again"
		--	},
		--	[2] = {
		--		Text = "Did you get the <AnimateStyle=Appear><Color=Silver>titanium?<Color=/>!<AnimateYield=1><AnimateStyle=/>",
		--	},
		--	[3] = {
		--		Text = "Oh, well, just get back to me when you have it",
		--	},
		--},
		
		--["Quest Return 1"] = {
		--	[1] = {
		--		Text = "Hey, its you again"
		--	},
		--	[2] = {
		--		Text = "Oh, I see you got the <AnimateStyle=Appear><Color=Silver>titanium!<Color=/>!<AnimateYield=1><AnimateStyle=/>",
		--	},
		--	[3] = {
		--		Text = "Here is some <AnimateStyle=Rainbow><Color=NeonGreen>Uranium<Color=/>!<AnimateYield=1><AnimateStyle=/> I collected from the mine... don't tell anyone about it",
		--		QuestFinished = true,
		--	},
		--	[4] = {
		--		Text = "I just need you to collect a couple more things for me.",
		--	},
		--	[5] = {
		--		Text = "You'll need to find some materials such as <Color=Grey>Aluminum<Color=/>, <Color=MatteBeige>Cardboard<Color=/>, and <Color=LightCyan>Plastic<Color=/>.",
		--		Specialty = "Y/N Quest",
		--	},
		--	[6] = {
		--		Text = "Oh alright then, let me know if you change your mind",
		--		AltText = {
		--			Text = "Thank you so much. Good luck!",
		--			Condition = {
		--				Past = 5,
		--				Answer = 'accepted'
		--			},	
		--			NextDialogue = "Questing 2"
		--		},
		--	},
		--},
		
		--["Questing 2"] = {
		--	[1] = {
		--		Text = "What's up!"
		--	},
		--	[2] = {
		--		Text = "Come back when you have the resources, thanks!"
		--	}
		--},
		
		--["Quest Return 2"] = {
		--	[1] = {
		--		Text = "Great, your back!"
		--	},
		--	[2] = {
		--		Text = "Haha, I bet you're wondering what I am going to be doing with all this.",
		--		QuestFinished = true,
		--	},
		--	[3] = {
		--		Text = "I'll be able to tell you soon enough",
		--	},
		--	[4] = {
		--		Text = "Now, i'll need you to go around and chop down some trees for wood. While your at it, would you mind making a <Color=White>Biofuel Synthesizer<Color=/> for me?",
		--		Specialty = "Y/N Quest",	
		--	},
		--	[5] = {
		--		Text = "Oh well, let me know when your ready",
		--		AltText = {
		--			Text = "Thank you so much. Good luck! Don't forget, you'll need a workbench first to craft a chemical synthesizer",
		--			Condition = {
		--				Past = 4,
		--				Answer = 'accepted'
		--			},
		--			NextDialogue = "Questing 3"
		--		},
		--	},
		--},
		--["Questing 3"] = {
		--	[1] = {
		--		Text = "Hey there! Still working on those trees and that synthesizer?"
		--	},
		--	[2] = {
		--		Text = "Let me know when you’ve got it all ready."
		--	}
		--},
		--["Quest Return 3"] = {
		--	[1] = {
		--		Text = "Nice, you have the Synthesizer done!",
		--		QuestFinished = true,
		--	},
		--	[2] = {
		--		Text = "Now that we have the Synthesizer, go clean off the <Color=Grey>aluminum can<Color=/>, empty the <Color=LightCyan>water bottle<Color=/>, and put the <Color=MatteBeige>cardboard box<Color=/> into the <Color=Red>Chemical<Color=/> Synthesizer with some wood.",
		--	},
		--	[3] = {
		--		Text = "We need to do this to ready the materials for recycling and synthesis. Are you up for the chores?",
		--		Specialty = "Y/N Quest",	
		--	},
		--	[4] = {
		--		Text = "Oh alright then, let me know if you change your mind",
		--		AltText = {
		--			Text = "Thank you so much. Good luck!",
		--			Condition = {
		--				Past = 3,
		--				Answer = 'accepted'
		--			},
		--			NextDialogue = "Questing 4"
		--		},
		--	},
		--},
		--["Questing 4"] = {
		--	[1] = {
		--		Text = "Hellooo, still working on that cleaning?"
		--	},
		--	[2] = {
		--		Text = "Let me know when you’re all done."
		--	}
		--},
		--["Quest Return 4"] = {
		--	[1] = {
		--		Text = "Nice, you have everything cleaned up and ready",
		--	},
		--	[2] = {
		--		Text = "Now that we have the finished materials, we will need to synthesize them in the high-tech, state-of-the-art, <Color=White>Biofuel Synthesizer<Color=/>!",
		--	},
		--	[3] = {
		--		Text = "You'll also need some ammoniacal copper sulfate and ammonia. I'll give you the ammoniacal copper sulfate, and you'll have to get the ammonia off the countertop over there.",
		--		QuestFinished = true,
		--	},
		--	[4] = {
		--		Text = "We'll use it to make cellulose and make fuel.",
		--	},
		--	[5] = {
		--		Text = "this fuel will be highly biodegradable so we won't have to worry about pollution!",
		--		Specialty = "Y/N Quest",	
		--	},
		--	[6] = {
		--		Text = "Oh alright then, let me know if you change your mind",
		--		AltText = {
		--			Text = "Thank you so much. Good luck!",
		--			Condition = {
		--				Past = 5,
		--				Answer = 'accepted'
		--			},
		--			NextDialogue = "Questing 5"
		--		},
		--	},
		--},
		--["Questing 5"] = {
		--	[1] = {
		--		Text = "Hi again!"
		--	},
		--	[2] = {
		--		Text = "Let me know when you have the materials synthesized"
		--	}
		--},
		--["Quest Return 5"] = {
		--	[1] = {
		--		Text = "Welcome back!"
		--	},
		--	[2] = {
		--		Text = "With everything almost done, I need you to head over to those bushes across the street and gather some <Color=DarkGreen>Moss<Color=/>.",
		--		QuestFinished = true
		--	},
		--	[3] = {
		--		Text = "The moss will reproduce and be able to filtrate any unpure water we have",
		--		Specialty = "Y/N Quest",
		--	},
		--	[4] = {
		--		Text = "Oh alright then, let me know if you change your mind",
		--		AltText = {
		--			Text = "Thank you so much. Good luck!",
		--			Condition = {
		--				Past = 3,
		--				Answer = 'accepted'
		--			},
		--			NextDialogue = "Questing 6"
		--		},
		--	},
		--},
		--["Questing 6"] = {
		--	[1] = {
		--		Text = "Hey, any luck finding that moss?"
		--	},
		--	[2] = {
		--		Text = "It’s important for the water filtration process! Keep at it."
		--	}
		--},
		--["Quest Return 6"] = {
		--	[1] = {
		--		Text = "You got the <Color=DarkGreen>Moss<Color=/>!",
		--		QuestFinished = true,
		--	},
		--	[2] = {
		--		Text = "Now go plant those in the science garden.",
		--	},
		--	[3] = {
		--		Text = "with that we won't have to worry about unclean water.",
		--	},
		--	[4] = {
		--		Text = "Make sure you don't step on any of Angela's plants!",
		--		Specialty = "Y/N Quest",
		--	},

		--	[5] = {
		--		Text = "Oh alright then, let me know if you change your mind",
		--		AltText = {
		--			Text = "Thank you so much. Good luck!",
		--			Condition = {
		--				Past = 4,
		--				Answer = 'accepted'
		--			},	
		--		NextDialogue = "Questing 7"
		--		},
		--	},
		--},
		--["Questing 7"] = {
		--	[1] = {
		--		Text = "You’re almost there! Just plant that moss in the garden."
		--	},
		--	[2] = {
		--		Text = "Let me know when it's done!"
		--	}
		--},

		--["Quest Return 7"] = {
		--	[1] = {
		--		Text = "Great, you planted the <Color=DarkGreen>Moss<Color=/>!",
		--	},
		--	[2] = {
		--		Text = "Now everything is complete and I can send this research off to NASA.",
		--	},
		--	[3] = {
		--		Text = "Thank you for all your help, it would've taken me forever to do this by myself.",
		--	},
		--	[4] = {
		--		Text = "I hope this will do as a reward for your hard work.",
		--	},
		--	[5] = {
		--		Text = "It's a diamond i found in the mine, it's not much of any use to me so I hope you do something good with it.",
		--		QuestFinished = true,
		--	},
		--	NextDialogue = {
		--		Dialogue = "Done"
		--	}
		--},

		--["Done"] = {
		--	[1] = {
		--		Text = "Thanks again for your help the other day!",
		--	},
		--},
		},
	},
	QuestSequence = QuestIndex.Quests["Xander's Quest"]
}