return {
	["Basic Color"] = {
		["BaseColor"] = Color3.fromRGB(89, 89, 104),
		["Objs"] = {},
		["SolidVersion"] = Color3.fromRGB(89, 89, 104),
	},
	["Rare Color"] = {
		["BaseColor"] = Color3.fromRGB(255, 255, 255),
		["Objs"] = { 
			["UIGradient"] = {
				["Color"] = ColorSequence.new{
					ColorSequenceKeypoint.new(0, Color3.fromRGB(82, 119, 255)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(75, 185, 255))
				}
			},
		},
		["SolidVersion"] = Color3.new(0.333333, 0.666667, 1)
	},
	["Ultra Color"] = {
		["BaseColor"] = Color3.new(1, 1, 1),
		["Objs"] = { 
			["UIGradient"] = {
				["Color"] = ColorSequence.new{
					ColorSequenceKeypoint.new(0, Color3.new(1, 0, 0)),
					ColorSequenceKeypoint.new(1, Color3.new(1, 0.333333, 0))
				}
			},
		},
		["SolidVersion"] = Color3.new(1, 0.2, 0)
	},
	["Crysmatic Color"] = {
		["BaseColor"] = Color3.new(1, 1, 1),
		["Objs"] = { 
			["UIGradient"] = {
				["Color"] = ColorSequence.new{
					ColorSequenceKeypoint.new(0, Color3.new(0, 0, 0)),
					ColorSequenceKeypoint.new(1, Color3.new(0.231373, 0.231373, 0.231373))
				}
			},
		},
		["SolidVersion"] = Color3.new(1, 1, 1)
	},
	["Astral Color"] = {
		["BaseColor"] = Color3.new(1, 1, 1),
		["Objs"] = { 
			["UIGradient"] = {
				["Color"] = ColorSequence.new{
					ColorSequenceKeypoint.new(0, Color3.new(0.666667, 0.333333, 1)),
					ColorSequenceKeypoint.new(1, Color3.new(0.819608, 0.427451, 0.898039))
				}
			},
		},
		["SolidVersion"] = Color3.new(0.666667, 0.333333, 1)
	},
	["Limited Color"] = {
		["BaseColor"] = Color3.new(1, 1),
		["SolidVersion"] = Color3.new(1, 1)
	},
	["Scripting Color"] = {
		["BaseColor"] = Color3.new(0.333333, 1, 1),
		["SolidVersion"] = Color3.new(0.333333, 1, 1)
	},
}