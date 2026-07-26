local plrName = game.Players.LocalPlayer and game.Players.LocalPlayer.DisplayName or "[player]"

return {
	--OpenAnimation = "Slight Suprise",
	Dialogues = {
		["First"] = {
			[1] = {
				Text = "It's <Color=LightCyan><AnimateStyle=Rainbow><AnimateStyleTime=0.45>over<AnimateStyle=/><AnimateStyleTime=/><Color=/>",
			},
			[2] = {
				Text = "<AnimateStyle=Fade><AnimateStyleTime=1>...<AnimateStyle=/><AnimateStyleTime=/>",
			},
			[3] = {
				Text = "<AnimateStyle=Fade><AnimateStyleTime=1>Ahhh... shit<AnimateStyle=/><AnimateStyleTime=/>",
				TextboxType = "Thinking",	
			},
		},
	}
}
