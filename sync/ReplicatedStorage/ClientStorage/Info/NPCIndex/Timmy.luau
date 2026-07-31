-- StrangeBoy.lua
local RPS = game:GetService("ReplicatedStorage")
local PLRS = game:GetService("Players")

local plr = PLRS.LocalPlayer
local Storage = RPS:WaitForChild("ClientStorage")
local QuestIndex = require(Storage:WaitForChild("Info"):WaitForChild("QuestIndex"))

return {
	Dialogues = {
		["First"] = {
			[1] = { Text = "..." },
			[2] = { Text = "..." },
			[3] = { Text = "You're not from around here, are you?" },
			[4] = { Text = "Nobody ever is." },
			[5] = { Text = "I'm not supposed to talk to strangers. But you don't look so bad." },
			[6] = { Text = "There's somewhere I need to go. I don't like going alone." },
			[7] = {
				Text = "Would you walk with me? It's not far. I promise.",
				Specialty = "Y/N Quest",	
				Action = {
					Name = "StartFollowing",
					Parameters = {"StrangeBoyMeetPoint", 3.5}
				}
				--Actions = {
				--	Yes = "Travel Ship Back",
				--	No = nil
				--} --> later idea to implement later
			},
			[8] = {
				Text = "...Oh. Okay. I understand.",
				AltText = {
					Text = "Really? Okay. Stay close, alright?",
					Condition = {
						Past = 7,
						Answer = 'accepted'
					},
					NextDialogue = "Questing"
				},
			},
		},

		["Questing"] = {
			[1] = { Text = "Still with me?" },
			[2] = { Text = "It's just up ahead. I can feel it." },
		},

		["Quest Return 1"] = {
			[1] = { Text = "...We made it." },
			[2] = { Text = "Thank you for walking with me. I didn't think anyone would." },
			[3] = {
				Text = "I should probably tell you my name sometime. Just... not yet, okay?",
				QuestFinished = true,
			},
			[4] = { Text = "I'll see you around. This isn't the last of it, I promise." },
			NextDialogue = {
				Dialogue = "Done"
			}
		},

		["Done"] = {
			[1] = { Text = "..." },
			[2] = { Text = "Thanks again. For before." },
		},
	},
	DisplayName = {
		Text = "Strange Boy",
		Color = Color3.fromRGB(56, 30, 255)
	},
	QuestSequence = QuestIndex.Quests["Strange Boy's Quest"]
}