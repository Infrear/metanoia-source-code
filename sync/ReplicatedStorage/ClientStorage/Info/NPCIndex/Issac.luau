local plrName = game.Players.LocalPlayer and game.Players.LocalPlayer.DisplayName or "[player]"

return {
	OpenAnimation = "Slight Suprise",
	Dialogues = {
		["First"] = {
			[1] = {
				Text = "<AnimateStyle=Fade><AnimateStyleTime=1>...<AnimateStyle=/><AnimateStyleTime=/>",
			},
			[2] = {
				Text = "<Color=LightCyan><AnimateStyle=Rainbow><AnimateStyleTime=0.45>Brrrrrr!<AnimateStyle=/><AnimateStyleTime=/><Color=/>",
				Animation = "Cold Shiver",
			},
			[3] = {
				Text = "It's so cold nowadays. I thought <Color=Red>Climate<Color=/> change was supposed to make the world warmer!?",
				Animation = "Unhappy (Kick Floor)",
			},
			[4] = {
				Text = "I bet it's because of all these <Color=Pink>winter storms<Color=/> and the <Color=LightYellow>polar vortex outbreaks from the East Coast<Color=/>.",
				Animation = "Headshake",	
			},
			[5] = {
				Text = "Or maybe...<AnimateYield=0.6> it was the <Color=Blue>electromagnetic burst<Color=/> from that <Color=Purple>deep-space anomaly<Color=/> last year...<AnimateYield=0.6>",
				Animation = "Nod",
			},
			[6] = {
				Text = "They say it <Color=LightGreen>messed with the atmosphere<Color=/> and <Color=Orange>disrupted the ocean currents<Color=/>, throwing everything out of balance!",
				Animation = "Hand Up Nod"
			},
			[7] = {
				Text = "If this keeps up...<AnimateYield=0.6> who knows how much colder it'll get?",
				Animation = "Headshake"
			}
		},
	}
}
