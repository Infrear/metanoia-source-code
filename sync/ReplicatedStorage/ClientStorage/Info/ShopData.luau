-- ============================================================
-- ShopData (ModuleScript — ReplicatedStorage/ClientStorage/Info)
-- Single source of truth for ALL shop and item data.
-- ShopService and ShopClient both read from here.
--
-- ITEM TAGS (used for filtering, quest tracking, UI grouping):
--   "consumable"  — used from inventory, disappears after use
--   "weapon"      — equippable, modifies ATK stats
--   "armor"       — equippable, modifies DEF stats
--   "accessory"   — equippable, misc stat modifiers
--   "cosmetic"    — no stats, purely visual
--   "aura"        — special class; persistent visual aura on character
--   "card"        — Arcana Cards; single-use or passive battle effects
--   "spelltome"   — teaches a skill on use (consumed)
--   "material"    — crafting/trade-in only, no direct use
--   "food"        — temporary battle buff, consumed on next dungeon enter
--   "record"      — changes battle BGM when equipped
--   "relic"       — fortune/gacha rewards, collectible
--
-- STAT MODIFIER FORMAT:
--   { HP=50, SP=20, ATK=5, DEF=3, SPD=2, MAG=0, RES=0 }
--   All keys optional — omitted = no change
--
-- RARITY:
--   1 = Common, 2 = Uncommon, 3 = Rare, 4 = Epic, 5 = Legendary
-- ============================================================

local ShopData = {}

-- ============================================================
-- ITEM DEFINITIONS
-- ============================================================

ShopData.Items = {

	-- //////////////////////////////////////////////////////////
	-- CONSUMABLES — Recovery
	-- //////////////////////////////////////////////////////////

	["heal_minor"] = {
		Name        = "Aura Patch",
		Description = "Restores 100 HP. A small bandage woven with city light.",
		Icon        = "rbxassetid://PATCH_ICON",       -- TODO: replace asset id
		Tags        = { "consumable" },
		Price       = 120,
		SellPrice   = 30,
		StackLimit  = 99,
		Rarity      = 1,
		UseEffect   = { HP = 100 },
	},

	["heal_mid"] = {
		Name        = "Nexus Vial",
		Description = "Restores 350 HP. Glows faintly with latent energy.",
		Icon        = "rbxassetid://VIAL_ICON",
		Tags        = { "consumable" },
		Price       = 380,
		SellPrice   = 95,
		StackLimit  = 99,
		Rarity      = 2,
		UseEffect   = { HP = 350 },
	},

	["heal_full"] = {
		Name        = "Elixir of Selves",
		Description = "Fully restores HP. Tastes like a memory.",
		Icon        = "rbxassetid://ELIXIR_ICON",
		Tags        = { "consumable" },
		Price       = 1200,
		SellPrice   = 300,
		StackLimit  = 20,
		Rarity      = 3,
		UseEffect   = { HP = math.huge },  -- interpreted as full heal
	},

	["sp_minor"] = {
		Name        = "Echo Soda",
		Description = "Restores 50 SP. Carbonated with persona residue.",
		Icon        = "rbxassetid://SODA_ICON",
		Tags        = { "consumable" },
		Price       = 150,
		SellPrice   = 35,
		StackLimit  = 99,
		Rarity      = 1,
		UseEffect   = { SP = 50 },
	},

	["sp_mid"] = {
		Name        = "Mind Brew",
		Description = "Restores 150 SP. Dense with arcane potential.",
		Icon        = "rbxassetid://BREW_ICON",
		Tags        = { "consumable" },
		Price       = 500,
		SellPrice   = 125,
		StackLimit  = 99,
		Rarity      = 2,
		UseEffect   = { SP = 150 },
	},

	["revive_basic"] = {
		Name        = "Second Wind",
		Description = "Revives an ally with 50% HP. A breath from the other side.",
		Icon        = "rbxassetid://REVIVE_ICON",
		Tags        = { "consumable" },
		Price       = 900,
		SellPrice   = 225,
		StackLimit  = 10,
		Rarity      = 3,
		UseEffect   = { Revive = 0.5 },   -- 50% HP revive flag
	},

	-- //////////////////////////////////////////////////////////
	-- CONSUMABLES — Status Cure
	-- //////////////////////////////////////////////////////////

	["cure_burn"] = {
		Name        = "Frost Wrap",
		Description = "Cures Burn status. Cool to the touch, smells like rain.",
		Icon        = "rbxassetid://FROSTWRAP_ICON",
		Tags        = { "consumable" },
		Price       = 80,
		SellPrice   = 20,
		StackLimit  = 99,
		Rarity      = 1,
		UseEffect   = { CureStatus = "Burn" },
	},

	["cure_freeze"] = {
		Name        = "Ember Pill",
		Description = "Cures Freeze status.",
		Icon        = "rbxassetid://EMBERPILL_ICON",
		Tags        = { "consumable" },
		Price       = 80,
		SellPrice   = 20,
		StackLimit  = 99,
		Rarity      = 1,
		UseEffect   = { CureStatus = "Freeze" },
	},

	["cure_all"] = {
		Name        = "Clarity Stone",
		Description = "Cures all status ailments at once.",
		Icon        = "rbxassetid://CLARITY_ICON",
		Tags        = { "consumable" },
		Price       = 340,
		SellPrice   = 85,
		StackLimit  = 30,
		Rarity      = 2,
		UseEffect   = { CureStatus = "All" },
	},

	-- //////////////////////////////////////////////////////////
	-- FOOD — Temporary Battle Buffs (consumed on dungeon entry)
	-- //////////////////////////////////////////////////////////

	["food_curry"] = {
		Name        = "Phantom Curry",
		Description = "A meal that lingers. +20% ATK for next 3 battles.",
		Icon        = "rbxassetid://CURRY_ICON",
		Tags        = { "consumable", "food" },
		Price       = 450,
		SellPrice   = 0,   -- can't sell food
		StackLimit  = 5,
		Rarity      = 2,
		UseEffect   = {
			TempBuff  = { ATK = 0.20 },
			Duration  = 3,            -- battles
		},
	},

	["food_ramen"] = {
		Name        = "Midnight Ramen",
		Description = "Thick broth. +15% DEF and +10% SPD for next 3 battles.",
		Icon        = "rbxassetid://RAMEN_ICON",
		Tags        = { "consumable", "food" },
		Price       = 380,
		SellPrice   = 0,
		StackLimit  = 5,
		Rarity      = 2,
		UseEffect   = {
			TempBuff = { DEF = 0.15, SPD = 0.10 },
			Duration = 3,
		},
	},

	["food_parfait"] = {
		Name        = "Arcana Parfait",
		Description = "Layered and sweet. +25% SP regen for next 5 battles.",
		Icon        = "rbxassetid://PARFAIT_ICON",
		Tags        = { "consumable", "food" },
		Price       = 600,
		SellPrice   = 0,
		StackLimit  = 5,
		Rarity      = 3,
		UseEffect   = {
			TempBuff = { SPRegen = 0.25 },
			Duration = 5,
		},
	},

	-- //////////////////////////////////////////////////////////
	-- WEAPONS
	-- //////////////////////////////////////////////////////////

	["knife_basic"] = {
		Name        = "City Knife",
		Description = "A practical blade. Nothing personal.",
		Icon        = "rbxassetid://KNIFE_ICON",
		Tags        = { "weapon" },
		Price       = 800,
		SellPrice   = 200,
		StackLimit  = 1,
		Rarity      = 1,
		StatModifiers = { ATK = 12, SPD = 2 },
		EquipSlot   = "Weapon",
	},

	["blade_phantom"] = {
		Name        = "Phantom Blade",
		Description = "Forged from crystallized shadow. Has a faint pulse.",
		Icon        = "rbxassetid://PHANTOMBLADE_ICON",
		Tags        = { "weapon" },
		Price       = 3200,
		SellPrice   = 800,
		StackLimit  = 1,
		Rarity      = 3,
		StatModifiers = { ATK = 28, MAG = 5, SPD = 3 },
		EquipSlot   = "Weapon",
		SpecialEffect = "PhantomTrail",  -- VFX tag; handled by CombatVFX module
	},

	["gun_basic"] = {
		Name        = "Urban Pistol",
		Description = "Standard issue. Reliable.",
		Icon        = "rbxassetid://PISTOL_ICON",
		Tags        = { "weapon" },
		Price       = 1200,
		SellPrice   = 300,
		StackLimit  = 1,
		Rarity      = 1,
		StatModifiers = { ATK = 10, RNG = 1 },
		EquipSlot   = "Weapon",
	},

	["staff_arcana"] = {
		Name        = "Arcana Staff",
		Description = "Amplifies magical output. Hums at tarot frequencies.",
		Icon        = "rbxassetid://STAFF_ICON",
		Tags        = { "weapon" },
		Price       = 2800,
		SellPrice   = 700,
		StackLimit  = 1,
		Rarity      = 3,
		StatModifiers = { MAG = 22, SP = 30, ATK = 5 },
		EquipSlot   = "Weapon",
	},

	-- //////////////////////////////////////////////////////////
	-- ARMOR
	-- //////////////////////////////////////////////////////////

	["jacket_basic"] = {
		Name        = "City Jacket",
		Description = "Reinforced lining. Looks good too.",
		Icon        = "rbxassetid://JACKET_ICON",
		Tags        = { "armor" },
		Price       = 950,
		SellPrice   = 240,
		StackLimit  = 1,
		Rarity      = 1,
		StatModifiers = { DEF = 10, RES = 5 },
		EquipSlot   = "Armor",
	},

	["robe_veil"] = {
		Name        = "Veil Robe",
		Description = "Woven from the boundary between worlds. High magic resistance.",
		Icon        = "rbxassetid://ROBE_ICON",
		Tags        = { "armor" },
		Price       = 3600,
		SellPrice   = 900,
		StackLimit  = 1,
		Rarity      = 3,
		StatModifiers = { DEF = 15, RES = 30, MAG = 8 },
		EquipSlot   = "Armor",
	},

	-- //////////////////////////////////////////////////////////
	-- ACCESSORIES
	-- //////////////////////////////////////////////////////////

	["ring_focus"] = {
		Name        = "Focus Ring",
		Description = "Reduces skill miss rate by 15%.",
		Icon        = "rbxassetid://FOCUSRING_ICON",
		Tags        = { "accessory" },
		Price       = 1100,
		SellPrice   = 275,
		StackLimit  = 1,
		Rarity      = 2,
		StatModifiers = { Accuracy = 15 },
		EquipSlot   = "Accessory",
	},

	["charm_luck"] = {
		Name        = "Lucky Charm",
		Description = "Critical hit rate +8%. Smells faintly of clover.",
		Icon        = "rbxassetid://CHARM_ICON",
		Tags        = { "accessory" },
		Price       = 1500,
		SellPrice   = 375,
		StackLimit  = 1,
		Rarity      = 2,
		StatModifiers = { CritRate = 8 },
		EquipSlot   = "Accessory",
	},

	-- //////////////////////////////////////////////////////////
	-- AURAS — Special Class
	-- Auras are persistent visual + minor passive effects that
	-- wrap around the character model. Think colored energy fields,
	-- particle halos, shadow tendrils, etc.
	-- Equipped via the Aura slot (one at a time).
	-- VFX handled by AuraSystem module.
	-- //////////////////////////////////////////////////////////

	["aura_ember"] = {
		Name        = "Ember Aura",
		Description = "A slow burn that never goes out. Fire-type attacks deal +5% damage.",
		Icon        = "rbxassetid://AURA_EMBER_ICON",
		Tags        = { "aura" },
		Price       = 4500,
		SellPrice   = 0,    -- auras can't be sold back; too personal
		StackLimit  = 1,
		Rarity      = 3,
		EquipSlot   = "Aura",
		AuraVFX     = "EmberAura",        -- key into AuraSystem VFX table
		StatModifiers = { ElementBoost = { Element = "Fire", Percent = 5 } },
	},

	["aura_voidstep"] = {
		Name        = "Voidstep Aura",
		Description = "Dark energy orbits the wearer. Evasion +10%, unnerves enemies.",
		Icon        = "rbxassetid://AURA_VOID_ICON",
		Tags        = { "aura" },
		Price       = 5200,
		SellPrice   = 0,
		StackLimit  = 1,
		Rarity      = 4,
		EquipSlot   = "Aura",
		AuraVFX     = "VoidstepAura",
		StatModifiers = { EVA = 10, EnemyMorale = -5 },
	},

	["aura_celestial"] = {
		Name        = "Celestial Aura",
		Description = "Golden light trails every step. +8% to all healing received.",
		Icon        = "rbxassetid://AURA_CELESTIAL_ICON",
		Tags        = { "aura" },
		Price       = 6000,
		SellPrice   = 0,
		StackLimit  = 1,
		Rarity      = 4,
		EquipSlot   = "Aura",
		AuraVFX     = "CelestialAura",
		StatModifiers = { HealingBoost = 8 },
	},

	["aura_phantom"] = {
		Name        = "Phantom Veil",
		Description = "Barely there. Random 10% chance to dodge any attack.",
		Icon        = "rbxassetid://AURA_PHANTOM_ICON",
		Tags        = { "aura" },
		Price       = 8000,
		SellPrice   = 0,
		StackLimit  = 1,
		Rarity      = 5,
		EquipSlot   = "Aura",
		AuraVFX     = "PhantomVeil",
		StatModifiers = { AutoDodgeChance = 10 },
	},

	-- //////////////////////////////////////////////////////////
	-- ARCANA CARDS — Persona-flavored single-use or passive effects
	-- Cards are drawn from the tarot's Major Arcana.
	-- Effect type: "BattleInstant" (used mid-fight), "Passive" (held),
	-- or "WorldEffect" (used on the overworld map).
	-- CardType drives different UI rendering (full tarot card flip).
	-- //////////////////////////////////////////////////////////

	["card_fool"] = {
		Name        = "The Fool",
		Description = "Zero in hand, everything ahead. Resets all cooldowns this battle.",
		Icon        = "rbxassetid://CARD_FOOL_ICON",
		Tags        = { "card", "consumable" },
		Price       = 2200,
		SellPrice   = 550,
		StackLimit  = 5,
		Rarity      = 3,
		CardArcana  = "Fool",
		CardType    = "BattleInstant",
		UseEffect   = { ResetCooldowns = true },
	},

	["card_magician"] = {
		Name        = "The Magician",
		Description = "Will into form. Next skill used costs 0 SP.",
		Icon        = "rbxassetid://CARD_MAGICIAN_ICON",
		Tags        = { "card", "consumable" },
		Price       = 1800,
		SellPrice   = 450,
		StackLimit  = 10,
		Rarity      = 2,
		CardArcana  = "Magician",
		CardType    = "BattleInstant",
		UseEffect   = { NextSkillFree = true },
	},

	["card_tower"] = {
		Name        = "The Tower",
		Description = "Collapse is creation. Deals massive damage to all enemies but halves your HP.",
		Icon        = "rbxassetid://CARD_TOWER_ICON",
		Tags        = { "card", "consumable" },
		Price       = 3500,
		SellPrice   = 875,
		StackLimit  = 3,
		Rarity      = 4,
		CardArcana  = "Tower",
		CardType    = "BattleInstant",
		UseEffect   = { AOEDamage = 999, SelfHPCost = 0.5 },
	},

	["card_star"] = {
		Name        = "The Star",
		Description = "Hope held. Passive: regenerate 5% HP at the start of each battle turn.",
		Icon        = "rbxassetid://CARD_STAR_ICON",
		Tags        = { "card" },
		Price       = 4000,
		SellPrice   = 0,   -- passive cards don't sell
		StackLimit  = 1,
		Rarity      = 4,
		CardArcana  = "Star",
		CardType    = "Passive",
		PassiveEffect = { HPRegenPerTurn = 0.05 },
		EquipSlot   = "Card",  -- goes into a dedicated Card slot
	},

	["card_moon"] = {
		Name        = "The Moon",
		Description = "Illusion reigns. All enemies become Confused for 2 turns.",
		Icon        = "rbxassetid://CARD_MOON_ICON",
		Tags        = { "card", "consumable" },
		Price       = 2800,
		SellPrice   = 700,
		StackLimit  = 5,
		Rarity      = 3,
		CardArcana  = "Moon",
		CardType    = "BattleInstant",
		UseEffect   = { ApplyStatus = { Status = "Confused", Turns = 2, Target = "AllEnemies" } },
	},

	["card_world"] = {
		Name        = "The World",
		Description = "Everything at once. Fully restores the entire party. Extremely rare.",
		Icon        = "rbxassetid://CARD_WORLD_ICON",
		Tags        = { "card", "consumable" },
		Price       = 0,     -- not sold; found or rewarded only
		SellPrice   = 5000,
		StackLimit  = 1,
		Rarity      = 5,
		CardArcana  = "World",
		CardType    = "BattleInstant",
		UseEffect   = { FullPartyRestore = true },
		Unsellable  = false,
		Unbuyable   = true,  -- flag checked by ShopService; won't appear in any shop
	},

	-- //////////////////////////////////////////////////////////
	-- SPELL TOMES — Teach skills on use
	-- //////////////////////////////////////////////////////////

	["tome_fireball"] = {
		Name        = "Tome: Fireball",
		Description = "Consume to permanently learn Fireball. One read, one burn.",
		Icon        = "rbxassetid://TOME_FIRE_ICON",
		Tags        = { "spelltome", "consumable" },
		Price       = 5000,
		SellPrice   = 1250,
		StackLimit  = 1,
		Rarity      = 3,
		UseEffect   = { TeachSkill = "Fireball" },  -- key into SkillLibrary
	},

	["tome_voidslash"] = {
		Name        = "Tome: Void Slash",
		Description = "Consume to permanently learn Void Slash. The blade writes itself into memory.",
		Icon        = "rbxassetid://TOME_VOID_ICON",
		Tags        = { "spelltome", "consumable" },
		Price       = 7500,
		SellPrice   = 1875,
		StackLimit  = 1,
		Rarity      = 4,
		UseEffect   = { TeachSkill = "VoidSlash" },
	},

	-- //////////////////////////////////////////////////////////
	-- MUSIC RECORDS — Equip to change battle BGM
	-- //////////////////////////////////////////////////////////

	["record_lo_fi"] = {
		Name        = "Lo-Fi Phantoms",
		Description = "Beats to fight shadows to.",
		Icon        = "rbxassetid://RECORD_LOFI_ICON",
		Tags        = { "record", "cosmetic" },
		Price       = 1200,
		SellPrice   = 0,
		StackLimit  = 1,
		Rarity      = 2,
		EquipSlot   = "Record",
		BattleBGM   = "rbxassetid://LOFI_BATTLE_ID",
	},

	["record_uprising"] = {
		Name        = "Uprising Vol. I",
		Description = "Peak. This is the one.",
		Icon        = "rbxassetid://RECORD_UPRISING_ICON",
		Tags        = { "record", "cosmetic" },
		Price       = 1800,
		SellPrice   = 0,
		StackLimit  = 1,
		Rarity      = 3,
		EquipSlot   = "Record",
		BattleBGM   = "rbxassetid://UPRISING_BATTLE_ID",
	},

	-- //////////////////////////////////////////////////////////
	-- COSMETICS — Pure style, no stats
	-- //////////////////////////////////////////////////////////

	["hat_beret"] = {
		Name        = "Phantom Beret",
		Description = "Iconic. No stat bonus — you just look better.",
		Icon        = "rbxassetid://BERET_ICON",
		Tags        = { "cosmetic", "armor" },
		Price       = 2000,
		SellPrice   = 500,
		StackLimit  = 1,
		Rarity      = 2,
		EquipSlot   = "Hat",
		CosmeticOnly = true,
	},

	["outfit_phantom"] = {
		Name        = "Phantom Suit",
		Description = "Full stealth aesthetic. Mask not included.",
		Icon        = "rbxassetid://PHANTOM_SUIT_ICON",
		Tags        = { "cosmetic", "armor" },
		Price       = 5500,
		SellPrice   = 0,
		StackLimit  = 1,
		Rarity      = 4,
		EquipSlot   = "Outfit",
		CosmeticOnly = true,
	},

	-- //////////////////////////////////////////////////////////
	-- MATERIALS — Crafting / trade-in only
	-- //////////////////////////////////////////////////////////

	["material_shadow_ore"] = {
		Name        = "Shadow Ore",
		Description = "Dense mineral from the cognitive world. Trade-in value only.",
		Icon        = "rbxassetid://SHADOWORE_ICON",
		Tags        = { "material" },
		Price       = 0,
		SellPrice   = 400,
		StackLimit  = 99,
		Rarity      = 2,
	},

	["material_arcana_dust"] = {
		Name        = "Arcana Dust",
		Description = "Residue of spent cards. Shimmers between states.",
		Icon        = "rbxassetid://ARCANADUST_ICON",
		Tags        = { "material" },
		Price       = 0,
		SellPrice   = 700,
		StackLimit  = 99,
		Rarity      = 3,
	},
}

-- ============================================================
-- SHOP DEFINITIONS
-- Each shop has:
--   Type          — drives which GUI layout is loaded
--   DisplayName   — shown in the shop header
--   ArcanaCard    — tarot card image for the header flip animation
--   FixedStock    — always available items { itemId = maxQty (nil = unlimited) }
--   RotatingStock — pool to pick from; refreshes on RotationInterval
--   RotationSlots — how many rotating slots to show at once
--   RotationInterval — "daily" | "hourly" | number (minutes) | "ondungeon"
--   Markup        — price multiplier (1 = normal, 1.2 = 20% markup)
--   SellEnabled   — whether the player can sell items here
--   SellMultiplier — fraction of SellPrice to pay (0.5 = half)
--   RequiredFlag  — story/quest attribute that must be set to access
--   EntryType     — how the player enters the shop (drives ShopClient)
--     "prompt"      = proximity prompt → slide panel (fast)
--     "dialogue"    = NPC dialogue first → shop opens after
--     "door"        = walk through part → fade in UI
--     "examine"     = examine object → popup
--     "cutscene"    = cutscene intro → full UI after
--   NPCDialogueId — if EntryType = "dialogue", which dialogue to run
--   CutsceneId    — if EntryType = "cutscene", which scene to play
-- ============================================================

ShopData.Shops = {

	-- ── GENERAL STORE (Convenience — fast grab) ─────────────
	["konbini_main"] = {
		Type         = "GeneralStore",
		DisplayName  = "Neon Konbini",
		ArcanaCard   = "rbxassetid://ARCANA_WHEEL_ICON",   -- Wheel of Fortune motif
		EntryType    = "prompt",
		Markup       = 1.0,
		SellEnabled  = false,
		FixedStock   = {
			heal_minor  = nil,   -- unlimited
			heal_mid    = nil,
			sp_minor    = nil,
			sp_mid      = nil,
			cure_burn   = nil,
			cure_freeze = nil,
			cure_all    = nil,
			revive_basic = 5,   -- limited quantity
		},
		RotatingStock   = { "food_curry", "food_ramen", "food_parfait" },
		RotationSlots   = 2,
		RotationInterval = "daily",
	},

	-- ── WEAPON SHOP ──────────────────────────────────────────
	["armory_district"] = {
		Type         = "Armory",
		DisplayName  = "Iron & Intent",
		ArcanaCard   = "rbxassetid://ARCANA_STRENGTH_ICON",  -- Strength arcana
		EntryType    = "dialogue",
		NPCDialogueId = "shopkeeper_armory_greeting",  -- TODO: wire to DialogueSystem
		Markup       = 1.0,
		SellEnabled  = true,
		SellMultiplier = 0.4,
		FixedStock   = {
			knife_basic  = nil,
			gun_basic    = nil,
			staff_arcana = nil,
		},
		RotatingStock   = { "blade_phantom" },
		RotationSlots   = 1,
		RotationInterval = "daily",
		RequiredFlag  = nil,  -- no gate
	},

	-- ── BOUTIQUE / CLOTHING ──────────────────────────────────
	["boutique_phantom"] = {
		Type         = "Boutique",
		DisplayName  = "Velvet & Shadow",
		ArcanaCard   = "rbxassetid://ARCANA_EMPRESS_ICON",   -- Empress arcana
		EntryType    = "door",      -- player walks through door part
		Markup       = 1.1,
		SellEnabled  = false,
		FixedStock   = {
			jacket_basic   = nil,
			robe_veil      = nil,
			hat_beret      = nil,
			outfit_phantom = nil,
		},
		RotatingStock   = {},
		RotationSlots   = 0,
		RotationInterval = nil,
	},

	-- ── AURA PARLOR ──────────────────────────────────────────
	-- Special layout — aura preview renders on the player character
	["aura_parlor"] = {
		Type         = "AuraParlor",
		DisplayName  = "The Aura Atelier",
		ArcanaCard   = "rbxassetid://ARCANA_STAR_ICON",   -- Star arcana
		EntryType    = "cutscene",
		CutsceneId   = "Scene_AuraAtelier",   -- TODO: wire to SceneDirector
		Markup       = 1.0,
		SellEnabled  = false,
		FixedStock   = {
			aura_ember     = nil,
			aura_voidstep  = nil,
			aura_celestial = nil,
		},
		RotatingStock   = { "aura_phantom" },
		RotationSlots   = 1,
		RotationInterval = "ondungeon",  -- refreshes after each dungeon run
		RequiredFlag  = "UnlockedAuraAtelier",
	},

	-- ── ARCANA CARD SHOP ─────────────────────────────────────
	-- Full tarot card flip UI per item — each card gets a dramatic reveal
	["card_shop"] = {
		Type         = "CardShop",
		DisplayName  = "The Arcana Table",
		ArcanaCard   = "rbxassetid://ARCANA_MAGICIAN_ICON",  -- Magician arcana
		EntryType    = "examine",    -- examine an object (the table itself)
		Markup       = 1.0,
		SellEnabled  = true,
		SellMultiplier = 0.5,
		FixedStock   = {
			card_magician = nil,
			card_moon     = nil,
		},
		RotatingStock   = {
			"card_fool", "card_tower", "card_star",
		},
		RotationSlots   = 2,
		RotationInterval = "daily",
		RequiredFlag  = nil,
	},

	-- ── SPELL TOME LIBRARY ───────────────────────────────────
	["skill_library"] = {
		Type         = "SkillShop",
		DisplayName  = "The Bound Pages",
		ArcanaCard   = "rbxassetid://ARCANA_HIEROPHANT_ICON",  -- Hierophant arcana
		EntryType    = "dialogue",
		NPCDialogueId = "shopkeeper_library_greeting",
		Markup       = 1.0,
		SellEnabled  = false,
		FixedStock   = {
			tome_fireball  = 3,
			tome_voidslash = 1,
		},
		RotatingStock   = {},
		RotationSlots   = 0,
		RotationInterval = nil,
		RequiredFlag  = "ProgressedChapter2",
	},

	-- ── PHARMACY ─────────────────────────────────────────────
	["pharmacy_central"] = {
		Type         = "Pharmacy",
		DisplayName  = "The Still Room",
		ArcanaCard   = "rbxassetid://ARCANA_MOON_ICON",   -- Moon arcana
		EntryType    = "prompt",
		Markup       = 1.0,
		SellEnabled  = false,
		FixedStock   = {
			heal_full    = nil,
			revive_basic = nil,
			cure_all     = nil,
		},
		-- Service: full party restore for a flat fee
		Services     = {
			{
				ServiceId   = "full_restore",
				DisplayName = "Full Recovery",
				Description = "Fully restores the whole party's HP and SP.",
				Price       = 3000,
				Icon        = "rbxassetid://RESTORE_SERVICE_ICON",
			},
		},
		RotatingStock = {},
		RotationSlots = 0,
	},

	-- ── PAWN SHOP / BLACK MARKET ─────────────────────────────
	["pawn_backstreet"] = {
		Type         = "PawnShop",
		DisplayName  = "No Questions Asked",
		ArcanaCard   = "rbxassetid://ARCANA_DEVIL_ICON",   -- Devil arcana
		EntryType    = "door",
		Markup       = 1.35,    -- 35% markup — shady pricing
		SellEnabled  = true,
		SellMultiplier = 0.7,  -- but buys at 70% — best sell rates in town
		FixedStock   = {
			material_shadow_ore  = nil,
			material_arcana_dust = nil,
		},
		RotatingStock   = {
			"blade_phantom", "aura_voidstep", "card_tower",
			"tome_voidslash", "charm_luck",
		},
		RotationSlots   = 3,
		RotationInterval = "daily",
		RequiredFlag  = "UnlockedBackstreet",
	},

	-- ── RESTAURANT ───────────────────────────────────────────
	["restaurant_midori"] = {
		Type         = "Restaurant",
		DisplayName  = "Midori Diner",
		ArcanaCard   = "rbxassetid://ARCANA_TEMPERANCE_ICON",  -- Temperance arcana
		EntryType    = "door",
		Markup       = 1.0,
		SellEnabled  = false,
		FixedStock   = {
			food_curry  = nil,
			food_ramen  = nil,
			food_parfait = nil,
		},
		-- Time-based: breakfast menu vs dinner menu
		TimeMenu     = {
			Day   = { "food_curry", "food_ramen" },
			Night = { "food_parfait" },
		},
		RotatingStock   = {},
		RotationSlots   = 0,
	},

	-- ── MUSIC SHOP ───────────────────────────────────────────
	["music_district"] = {
		Type         = "MusicShop",
		DisplayName  = "Phantom Frequencies",
		ArcanaCard   = "rbxassetid://ARCANA_SUN_ICON",    -- Sun arcana
		EntryType    = "prompt",
		Markup       = 1.0,
		SellEnabled  = false,
		FixedStock   = {
			record_lo_fi    = nil,
			record_uprising = nil,
		},
		RotatingStock   = {},
		RotationSlots   = 0,
	},

	-- ── FORTUNE PARLOR ───────────────────────────────────────
	-- Not a traditional shop — spends currency for meta-progression buffs
	["fortune_parlor"] = {
		Type         = "FortuneParlor",
		DisplayName  = "The Veil",
		ArcanaCard   = "rbxassetid://ARCANA_HERMIT_ICON",  -- Hermit arcana
		EntryType    = "cutscene",
		CutsceneId   = "Scene_FortuneReading",
		Markup       = 1.0,
		SellEnabled  = false,
		FixedStock   = {},
		-- Fortune readings are their own item type resolved by FortuneParlor layout
		Fortunes     = {
			{
				Id          = "fortune_drops",
				DisplayName = "Blessed Haul",
				Description = "Double item drops on next dungeon run.",
				Price       = 1500,
				Icon        = "rbxassetid://FORTUNE_DROPS_ICON",
				Effect      = { DropMultiplier = 2, Duration = "OneDungeon" },
			},
			{
				Id          = "fortune_exp",
				DisplayName = "Enlightened Path",
				Description = "+50% EXP for next 3 battles.",
				Price       = 2000,
				Icon        = "rbxassetid://FORTUNE_EXP_ICON",
				Effect      = { EXPMultiplier = 1.5, Duration = 3 },
			},
			{
				Id          = "fortune_weather",
				DisplayName = "Favored Stars",
				Description = "All weather effects in the next dungeon will be beneficial.",
				Price       = 2500,
				Icon        = "rbxassetid://FORTUNE_WEATHER_ICON",
				Effect      = { WeatherOverride = "Beneficial", Duration = "OneDungeon" },
			},
		},
	},

	-- ── GACHA / CAPSULE MACHINE ──────────────────────────────
	["gacha_street"] = {
		Type         = "Gacha",
		DisplayName  = "The Capsule",
		ArcanaCard   = "rbxassetid://ARCANA_WHEEL_ICON",  -- Wheel of Fortune again — fate
		EntryType    = "examine",
		Markup       = 1.0,
		SellEnabled  = false,
		FixedStock   = {},
		PullCost     = 300,  -- cost per single pull
		PullPool     = {
			-- { itemId, weight }  higher weight = more common
			{ id = "hat_beret",        weight = 40 },
			{ id = "ring_focus",       weight = 30 },
			{ id = "charm_luck",       weight = 20 },
			{ id = "aura_ember",       weight = 8  },
			{ id = "outfit_phantom",   weight = 2  },
		},
		GuaranteedAt = 10,  -- pity system: guaranteed rare+ after 10 pulls without one
		RotatingStock = {},
	},
}

-- ============================================================
-- AURA CLASS DEFINITIONS
-- Separate from items — describes what each AuraVFX key does.
-- Consumed by AuraSystem module (TODO: build AuraSystem).
-- ============================================================

ShopData.AuraVFX = {
	["EmberAura"] = {
		ParticleFolder  = "Effects.Auras.Ember",  -- path under ClientStorage.Effects
		Color           = Color3.fromRGB(255, 120, 30),
		ParticleRate    = 15,
		Radius          = 3.5,
		IdleAnimation   = "AuraFlicker",  -- looping AnimationController anim on VFX rig
		ActiveAnimation = "AuraBurst",    -- plays on skill use
	},
	["VoidstepAura"] = {
		ParticleFolder  = "Effects.Auras.Void",
		Color           = Color3.fromRGB(80, 0, 140),
		ParticleRate    = 20,
		Radius          = 4,
		IdleAnimation   = "AuraOrbit",
		ActiveAnimation = "AuraNova",
	},
	["CelestialAura"] = {
		ParticleFolder  = "Effects.Auras.Celestial",
		Color           = Color3.fromRGB(255, 215, 80),
		ParticleRate    = 10,
		Radius          = 5,
		IdleAnimation   = "AuraHalo",
		ActiveAnimation = "AuraRadiate",
	},
	["PhantomVeil"] = {
		ParticleFolder  = "Effects.Auras.Phantom",
		Color           = Color3.fromRGB(200, 200, 255),
		ParticleRate    = 8,
		Radius          = 4.5,
		IdleAnimation   = "AuraDrift",
		ActiveAnimation = "AuraVanish",
	},
}

-- ============================================================
-- ARCANA CARD VISUAL DEFINITIONS
-- Each card arcana has a face image and a back image for the
-- flip animation in CardShop layout.
-- ============================================================

ShopData.ArcanaVisuals = {
	Fool       = { Face = "rbxassetid://CARD_FOOL_FACE",     Back = "rbxassetid://CARD_BACK" },
	Magician   = { Face = "rbxassetid://CARD_MAGICIAN_FACE", Back = "rbxassetid://CARD_BACK" },
	Tower      = { Face = "rbxassetid://CARD_TOWER_FACE",    Back = "rbxassetid://CARD_BACK" },
	Star       = { Face = "rbxassetid://CARD_STAR_FACE",     Back = "rbxassetid://CARD_BACK" },
	Moon       = { Face = "rbxassetid://CARD_MOON_FACE",     Back = "rbxassetid://CARD_BACK" },
	World      = { Face = "rbxassetid://CARD_WORLD_FACE",    Back = "rbxassetid://CARD_BACK" },
}

return ShopData
