return {
	Settings = {
		AllowSkip = true,
		DisableControls = true,
		FadeInOnStart = true,
	},

	Timeline = {
		{
			Action = "Setup",
			NPCs = {
				{Name = "Nova", StartingPos = "Nova_Entry_Node"},
				{Name = "Joker", StartingPos = "Player_Spawn_Node"}
			},
			Props = {"SchoolTable", "Notebook"}
		},
		{
			Action = "Camera",
			Target = "Cam_EstablishingShot",
			Style = "Tween",
			Duration = 3
		},
		{
			Action = "Animation",
			Target = "Nova",
			AnimName = "Nova_Wave_HyperSpecific", -- Found in the Scene's Anim folder
			Generic = false 
		},
		{
			Action = "Dialogue",
			Speaker = "Nova",
			Text = "Hey! You actually showed up. I thought you'd be too busy with the Metaverse stuff.",
			Condition = function(playerData) 
				return playerData.SocialStats.Knowledge.Level >= 2 
			end,
			AltText = "Oh... you're that quiet kid, right?" -- If condition fails
		},
		{
			Action = "Effect",
			Name = "SpeedLines",
			Duration = 1
		},
		{
			Action = "Cleanup" -- Despawns props and returns control
		}
	}
}