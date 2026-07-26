-- Services
local TS = game:GetService("TweenService")
local RPS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local PLRS = game:GetService("Players")

-- Dependencies
local plr = PLRS.LocalPlayer
repeat wait() until plr.Character
local char = game.Players.LocalPlayer.Character
local hum = char:WaitForChild("Humanoid")
local playerGUI = plr:WaitForChild("PlayerGui")
local hrp = char:WaitForChild("HumanoidRootPart")

local mouse = plr:GetMouse()
local cam = workspace:WaitForChild("Camera")

local Storage = RPS:WaitForChild("ClientStorage")
local NPCWalkStreets = workspace:WaitForChild("NPCWALKERS")
local walkerOrchestrator = require(script:WaitForChild("WalkerOrchestrator"))

local KeySettings = require(Storage.Info.KeybindsMaster)
local SkillLibrary = require(Storage.Info.SkillLibrary)

-- Local Variables

-- Constants

-- Local Functions

-- Connections

-- Loose Threads
walkerOrchestrator.init()
walkerOrchestrator.loadStreet(NPCWalkStreets.NPCWalker1)
