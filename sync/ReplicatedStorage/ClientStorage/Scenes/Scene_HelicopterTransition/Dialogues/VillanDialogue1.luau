local plrName = game.Players.LocalPlayer and game.Players.LocalPlayer.DisplayName or "[player]"

return {
	--OpenAnimation = "Slight Suprise",
	Dialogues = {
		["First"] = {
			[1] = {
				Text = "<AnimateStyle=Fade><AnimateStyleTime=1>...<AnimateStyle=/><AnimateStyleTime=/>",
			},
			[2] = {
				Text = "<Color=LightCyan><AnimateStyle=Rainbow><AnimateStyleTime=0.45>I can't believe you really tried this, you really thought you could win?<AnimateStyle=/><AnimateStyleTime=/><Color=/>",
				Animation = "Cold Shiver",
				CameraFocus = {},
			},
			[3] = {
				Text = "<AnimateStyle=Fade><AnimateStyleTime=1>...<AnimateStyle=/><AnimateStyleTime=/>",
			},
			[4] = {
				Text = "Ahh...<AnimateYield=0.6> I see,<AnimateYield=0.3> that was your plan <Color=Green><AnimateStyle=Wiggle><AnimateStepFrequency=1><AnimateStyleTime=2>hahaha!<AnimateStyle=/><AnimateStepFrequency=/><AnimateStyleTime=/><Color=/>!<AnimateYield=1.5>",
				Animation = "Nod",
			},
			[5] = {
				Text = "Neverthless, this is where you <Color=Pink>die<Color=/>",
				Animation = "Headshake",	
			},
		},
	}
}
