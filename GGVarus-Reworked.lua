require("GGPrediction")

local Version = 0.7

local Menu, Utils, Champion

local GG_Target, GG_Orbwalker, GG_Buff, GG_Damage, GG_Spell, GG_Object, GG_Attack, GG_Data, GG_Cursor, SDK_IsRecalling

local HITCHANCE_NORMAL = 2
local HITCHANCE_HIGH = 3
local HITCHANCE_IMMOBILE = 4

local DAMAGE_TYPE_PHYSICAL = 0
local DAMAGE_TYPE_MAGICAL = 1
local DAMAGE_TYPE_TRUE = 2

local ORBWALKER_MODE_NONE = -1
local ORBWALKER_MODE_COMBO = 0
local ORBWALKER_MODE_HARASS = 1
local ORBWALKER_MODE_LANECLEAR = 2
local ORBWALKER_MODE_JUNGLECLEAR = 3
local ORBWALKER_MODE_LASTHIT = 4
local ORBWALKER_MODE_FLEE = 5

local TEAM_JUNGLE = 300
local TEAM_ALLY = myHero.team
local TEAM_ENEMY = 300 - myHero.team

local math_huge = math.huge
local math_pi = math.pi
local math_sqrt = assert(math.sqrt)
local math_abs = assert(math.abs)
local math_ceil = assert(math.ceil)
local math_min = assert(math.min)
local math_max = assert(math.max)
local math_pow = assert(math.pow)
local math_atan = assert(math.atan)
local math_acos = assert(math.acos)
local math_random = assert(math.random)
local table_sort = assert(table.sort)
local table_remove = assert(table.remove)
local table_insert = assert(table.insert)

local myHero = myHero
local os = os
local math = math
local Game = Game
local Vector = Vector
local Control = Control
local Draw = Draw
local table = table
local pairs = pairs
local GetTickCount = GetTickCount

local LastChatOpenTimer = 0

Utils = {}

local UpdatedMenuChamps = { ["Orianna"] = true, ["Viktor"] = true }

Menu = {}
if UpdatedMenuChamps[myHero.charName] then
	Menu = ScriptMenu("GGAIO" .. myHero.charName, "GG AIO - " .. myHero.charName)
	Settings = Menu.Settings

	Menu:Menu("Combo", "Combo")
	Menu.Combo:OnOff("ComboOn", "Combo", true)

	Menu:Menu("Harass", "Harass")
	Menu.Harass:OnOff("HarassOn", "Harass", true)
	Menu.Harass:KeyToggle("HarassOnToggle", "Harass Toggle", false, "H")
	Menu.Harass.HarassOnToggle:PermaShow("Harass Toggle Key")
else
-- stylua: ignore start
	Menu.m = MenuElement({name = "GG Varus Reworked", id = 'GG' .. myHero.charName, type = _G.MENU})
	Menu.q = Menu.m:MenuElement({name = 'Q', id = 'q', type = _G.MENU})
	Menu.w = Menu.m:MenuElement({name = 'W', id = 'w', type = _G.MENU})
	Menu.e = Menu.m:MenuElement({name = 'E', id = 'e', type = _G.MENU})
	Menu.r = Menu.m:MenuElement({name = 'R', id = 'r', type = _G.MENU})
	Menu.d = Menu.m:MenuElement({name = 'Drawings', id = 'd', type = _G.MENU})
	Menu.m:MenuElement({name = '', type = _G.SPACE, id = 'VersionSpaceA'})
	Menu.m:MenuElement({name = 'Version  ' .. Version, type = _G.SPACE, id = 'VersionSpaceB'})
	-- stylua: ignore end
end

function Utils:Cast(spell, target, spellprediction, hitchance, noHit)
	if not self.CanUseSpell and (target or spellprediction) then
		return false
	end
	if spellprediction == nil then
		if target == nil then
			Control.KeyDown(spell)
			Control.KeyUp(spell)
			return true
		end
		Control.CastSpell(spell, target)
		self.CanUseSpell = false
		return true
	end
	if target == nil then
		return false
	end
	spellprediction:GetPrediction(target, myHero)
	if spellprediction:CanHit(hitchance or HITCHANCE_HIGH) or noHit == 1 then
		Control.CastSpell(spell, spellprediction.CastPosition)
		self.CanUseSpell = false
		return true
	end
	return false
end

function Utils:GetEnemyHeroes(range, bbox)
	local result = {}
	if not self.CanUseSpell then
		return result
	end
	for i, unit in ipairs(Champion.EnemyHeroes) do
		--[[if self.CachedDistance[i] == nil then
			self.CachedDistance[i] = unit.distance
		end]]
		local extrarange = bbox and unit.boundingRadius or 0
		if --[[self.CachedDistance[i]]
			unit.distance < range + extrarange
		then
			table_insert(result, unit)
		end
	end
	return result
end

if Champion == nil and myHero.charName == "Varus" then
	-- menu values
	local MENU_Q_COMBO = true
	local MENU_Q_HARASS = false
	local MENU_Q_WSTACKS = true
	local MENU_Q_SKIP_WSTACKS = false
	local MENU_Q_TIME = 0.5
	local MENU_Q_RANGE = 300
	local MENU_Q_HITCHANCE = 2
	local MENU_W_COMBO = true
	local MENU_W_HARASS = false
	local MENU_W_HP = 50
	local MENU_E_COMBO = true
	local MENU_E_HARASS = false
	local MENU_E_WSTACKS = true
	local MENU_E_SKIP_WSTACKS = false
	local MENU_E_HITCHANCE = 2
	local MENU_R_COMBO = true
	local MENU_R_HARASS = false
	local MENU_R_XHeroHP = 200
	local MENU_R_XEnemyHP = 600
	local MENU_R_XRANGE = 500
	local MENU_R_HITCHANCE = 2
	local WAIT_STACKS = -1000
	local W_DELAY = WAIT_STACKS < Game.Timer()

-- stylua: ignore start
    -- menu
    Menu.q:MenuElement({id = "combo", name = "Combo", value = MENU_Q_COMBO, callback = function(x) MENU_Q_COMBO = x end})
    Menu.q:MenuElement({id = "harass", name = "Harass", value = MENU_Q_HARASS, callback = function(x) MENU_Q_HARASS = x end})
    Menu.q:MenuElement({id = "wstacks", name = "when enemy has W buff x3", value = MENU_Q_WSTACKS, callback = function(x) MENU_Q_WSTACKS = x end})
    Menu.q:MenuElement({id = "wstacksskip", name = "skip W buff check if no attack target", value = MENU_Q_SKIP_WSTACKS, callback = function(x) MENU_Q_SKIP_WSTACKS = x end})
    Menu.q:MenuElement({id = "xtime", name = "minimum charging time", value = MENU_Q_TIME, min = 0.1, max = 1.4, step = 0.1, callback = function(x) MENU_Q_TIME = x end})
    Menu.q:MenuElement({id = "xrange", name = "charging time only if no enemies in aarange + x", value = MENU_Q_RANGE, min = 100, max = 600, step = 10, callback = function(x) MENU_Q_RANGE = x end})
    Menu.q:MenuElement({id = "hitchance", name = "Hitchance", value = MENU_Q_HITCHANCE, drop = {"normal", "high", "immobile"}, callback = function(x) MENU_Q_HITCHANCE = x end})
    Menu.w:MenuElement({id = "combo", name = "Combo", value = MENU_W_COMBO, callback = function(x) MENU_W_COMBO = x end})
    Menu.w:MenuElement({id = "harass", name = "Harass", value = MENU_W_HARASS, callback = function(x) MENU_W_HARASS = x end})
    Menu.w:MenuElement({id = "hp", name = "enemy %hp less than", value = MENU_W_HP, min = 1, max = 100, step = 1, callback = function(x) MENU_W_HP = x end})
    Menu.e:MenuElement({id = "combo", name = "Combo", value = MENU_E_COMBO, callback = function(x) MENU_E_COMBO = x end})
    Menu.e:MenuElement({id = "harass", name = "Harass", value = MENU_E_HARASS, callback = function(x) MENU_E_HARASS = x end})
    Menu.e:MenuElement({id = "wstacks", name = "when enemy has W buff x3", value = MENU_E_WSTACKS, callback = function(x) MENU_E_WSTACKS = x end})
    Menu.e:MenuElement({id = "wstacksskip", name = "skip W buff check if no attack target", value = MENU_E_SKIP_WSTACKS, callback = function(x) MENU_E_SKIP_WSTACKS = x end})
    Menu.e:MenuElement({id = "hitchance", name = "Hitchance", value = MENU_E_HITCHANCE, drop = {"normal", "high", "immobile"}, callback = function(x) MENU_E_HITCHANCE = x end})
    Menu.r:MenuElement({id = "combo", name = "Use R Combo", value = MENU_R_COMBO, callback = function(x) MENU_R_COMBO = x end})
    Menu.r:MenuElement({id = "harass", name = "Use R Harass", value = MENU_R_HARASS, callback = function(x) MENU_R_HARASS = x end})
    Menu.r:MenuElement({id = "xherohp", name = "hero near to death hp", value = MENU_R_XHeroHP, min = 100, max = 1000, step = 50, callback = function(x) MENU_R_XHeroHP = x end})
    Menu.r:MenuElement({id = "xenemyhp", name = "enemy health above", value = MENU_R_XEnemyHP, min = 100, max = 1000, step = 50, callback = function(x) MENU_R_XEnemyHP = x end})
    Menu.r:MenuElement({id = "xrange", name = "enemy in range", value = MENU_R_XRANGE, min = 250, max = 1000, step = 50, callback = function(x) MENU_R_XRANGE = x end})
    Menu.r:MenuElement({id = "hitchance", name = "Hitchance", value = MENU_R_HITCHANCE, drop = {"normal", "high", "immobile"}, callback = function(x) MENU_R_HITCHANCE = x end})
    Menu.r:MenuElement({name = "Semi Manual", id = "semi", type = _G.MENU})
    Menu.r_semi_key = Menu.r.semi:MenuElement({name = "Semi-Manual Key", id = "key", key = string.byte("T")})
    Menu.r_semi_hitchance = Menu.r.semi:MenuElement({id = "hitchance", name = "Hitchance", value = 2, drop = {"normal", "high", "immobile"}})
	-- stylua: ignore end

	-- locals
	local QPrediction = GGPrediction:SpellPrediction({
		Delay = 0.1,
		Radius = 70,
		Range = 1650,
		Speed = 1900,
		Collision = false,
		Type = GGPrediction.SPELLTYPE_LINE,
	})
	local EPrediction = GGPrediction:SpellPrediction({
		Delay = 0.7419,
		Radius = 235,
		Range = 925,
		Speed = math.huge,
		Collision = false,
		Type = GGPrediction.SPELLTYPE_CIRCLE,
	})
	local RPrediction = GGPrediction:SpellPrediction({
		Delay = 0.2419,
		Radius = 120,
		Range = 1250,
		Speed = 1500,
		Collision = false,
		Type = GGPrediction.SPELLTYPE_LINE,
	})

	-- champion
	Champion = {
		CanAttackCb = function()
			return not Champion:HasQBuff() and GG_Spell:CanTakeAction({ q = 0.33, w = 0, e = 0.33, r = 0.33 })
		end,
		CanMoveCb = function()
			return GG_Spell:CanTakeAction({ q = 0.2, w = 0, e = 0.2, r = 0.2 })
		end,
	}
	-- has q buff
	function Champion:HasQBuff()
		return GG_Buff:HasBuff(myHero, "varusq") or self.Timer < GG_Spell.QTimer + 0.5
	end
	-- on tick
	function Champion:OnTick()
		--print(myHero.attackSpeed * 0.658)
        --print(Champion:WStackDMG())
		Champion:QKillSteal()
		if self:HasQBuff() then
			if not self.IsCombo and not self.IsHarass then
				return
			end
			self:QBuffLogic()
			return
		end
		if
			Control.IsKeyDown(HK_Q)
			and (self.IsCombo or self.IsHarass)
			and not GG_Buff:HasBuff(myHero, "varusq")
			and self.Timer > GG_Spell.QTimer + 0.5
			and self.Timer > GG_Spell.QkTimer + 0.5
			and Game.CanUseSpell(_Q) == 0
		then
			Control.KeyUp(HK_Q)
		end
		if self.IsAttacking or self.CanAttackTarget then
			return
		end
		self.WSpellData = myHero:GetSpellData(_W)
		self:RLogic()
		self:ELogic()
		self:QLogic()
	end
	-- q can up
	local QKSTarget = nil
	local WToggle = false
	function Champion:QKillSteal()
		if not GG_Spell:IsReady(_Q, { q = 0.33, w = 0, e = 0.6, r = 0.33 }) then
			return
		end
		local enemies = Utils:GetEnemyHeroes(1500)
		local canusew = Game.CanUseSpell(_W) == 0
		for i = 1, #enemies do
			local enemy = enemies[i]
			local WDMG = 0
			local WStackDMG = Champion:WStackDMG(enemy)
			local AR = (100 / (100 + enemy.armor))
			local QRawDmg = myHero:GetSpellData(_Q).level * 55 - 40 + myHero.totalDamage * (myHero:GetSpellData(_Q).level * 0.05 + 1.2)
			local QDmg = QRawDmg * AR
			local EnemyHP = 100 * (enemy.health - QDmg + (10 * enemy.hpRegen)) / enemy.maxHealth
			local MR = (100 / (100 + enemy.magicResist))
			if canusew then
				WDMG = Champion:WLevelDMG()
			end
			if EnemyHP < ((WDMG + WStackDMG)) * MR then
				QKSTarget = enemy
				Control.KeyDown(HK_Q)
				break
			end
		end
		local qtimer = self.Timer - GG_Spell.QTimer
		if qtimer > 6 then
			return
		end
		if QKSTarget then
			QPrediction.Range = 925 + (qtimer * 0.5 * 700)
			if canusew then
				WToggle = true
				Control.KeyDown(HK_W)
				Control.KeyUp(HK_W)
			end
			local InRange = GGPrediction:GetDistance(QKSTarget.pos, self.Pos) < 1500
			local WDMG = Champion:WLevelDMG()
			local WStackDMG = Champion:WStackDMG(QKSTarget)
			local AR = (100 / (100 + QKSTarget.armor))
			local QRawDmg = myHero:GetSpellData(_Q).level * 55 - 40 + myHero.totalDamage * (myHero:GetSpellData(_Q).level * 0.05 + 1.2)
			local QarmD = QRawDmg * AR
			local QDmg = math.min(QarmD, QarmD * 0.60) * (1 + qtimer / 2.5)
			local EnemyHP = 100 * (QKSTarget.health - QDmg + (4 * QKSTarget.hpRegen)) / QKSTarget.maxHealth
			local MR = (100 / (100 + QKSTarget.magicResist))
			local Killable = EnemyHP < (WStackDMG + (WDMG * 0.60) * (1 + qtimer / 4)) * MR
			if InRange and (WToggle == true and qtimer < 2 and Killable == false) then return end
			if GGPrediction:GetDistance(QKSTarget.pos, self.Pos) < QPrediction.Range - 50 then
				WToggle = false
				Utils:Cast(HK_Q, QKSTarget, QPrediction, MENU_Q_HITCHANCE + 1, 1)
				--print("CastedQKS")
				QKSTarget = nil
				WAIT_STACKS = Game.Timer() + 1
				return
			end
			if qtimer > 4.2 then
				QKSTarget = nil
			end
		end
	end

	function Champion:QCanUp(target)
		if target == nil or QKSTarget ~= nil then
			return false
		end
		QPrediction:GetPrediction(target, myHero)
		if QPrediction:CanHit(MENU_Q_HITCHANCE + 1) and GG_Buff:GetBuffCount(target, "varuswdebuff") >= 2 then
			--local pos = myHero.pos
			--if GGPrediction:GetDistance(pos, QPrediction.UnitPosition) > GGPrediction:GetDistance(pos, target.pos) + 75 then
			return true
			--end
		end
		return false
	end
	--WDMG
	function Champion:WLevelDMG()
		local D = 9
		local Qlevel = myHero:GetSpellData(_Q).level
		local Wlevel = myHero:GetSpellData(_W).level
		local Elevel = myHero:GetSpellData(_E).level
		local Rlevel = myHero:GetSpellData(_R).level
		local totalLvl = Qlevel + Wlevel + Elevel + Rlevel
		if totalLvl then
			if totalLvl > 3 then
				D = D + 3
			end
			if totalLvl > 6 then
				D = D + 3
			end
			if totalLvl > 9 then
				D = D + 3
			end
			if totalLvl > 12 then
				D = D + 3
			end
		end
		return D
	end
	function Champion:WStackDMG(enemy)
		local D = 11.25
		local Stakcs = 3
		if enemy then
			Stakcs = GG_Buff:GetBuffCount(enemy, "varuswdebuff")
		end
		if myHero:GetSpellData(_W).level > 0 then
			D= (11.25 + 2.25 * myHero:GetSpellData(_W).level + ((myHero.ap / 100) * 6.75)) / 3 * Stakcs
		end
		--print(D)
		return D
	end
	-- q buff logic
	function Champion:QBuffLogic()
		if not Control.IsKeyDown(HK_Q) then
			return
		end
		local qtimer = self.Timer - GG_Spell.QTimer
		if qtimer > 6 then
			return
		end
		local WDMG = Champion:WLevelDMG()
		local QRawDmg = myHero:GetSpellData(_Q).level * 55 - 40 + myHero.totalDamage * (myHero:GetSpellData(_Q).level * 0.05 + 1.2)
		local aaenemies = Utils:GetEnemyHeroes(myHero.range + MENU_Q_RANGE)
		--print(qtimer)
		QPrediction.Range = 925 + (qtimer * 0.5 * 700)
		local canusew = Game.CanUseSpell(_W) == 0
			and ((self.IsCombo and MENU_W_COMBO) or (self.IsHarass and MENU_W_HARASS))
		local enemies = Utils:GetEnemyHeroes(QPrediction.Range)
		if self:QCanUp(self.AttackTarget)
			and GGPrediction:GetDistance(self.AttackTarget.pos, self.Pos) < 1545 then
            local WStackDMG = Champion:WStackDMG(self.AttackTarget)
			local AR = (100 / (100 + self.AttackTarget.armor))
			local QarmD = QRawDmg * AR
			local QDmg = math.min(QarmD, QarmD * 0.60) * (1 + qtimer / 2.5)
			local EnemyHP = 100 * (self.AttackTarget.health - QarmD + (10 * self.AttackTarget.hpRegen)) / self.AttackTarget.maxHealth
			local EnemyHP2 = 100 * (self.AttackTarget.health - QDmg + (4 * self.AttackTarget.hpRegen)) / self.AttackTarget.maxHealth
			local MR = (100 / (100 + self.AttackTarget.magicResist))
			if canusew and EnemyHP < ((WDMG + WStackDMG + 10) * 1.16) * MR then
				WToggle = true
				Control.KeyDown(HK_W)
				Control.KeyUp(HK_W)
			end
			local InRange = GGPrediction:GetDistance(self.AttackTarget.pos, self.Pos) < 1400
			local Killable = EnemyHP2 < (WStackDMG + (WDMG * 0.60) * (1 + qtimer / 4)) * MR
			if (#aaenemies == 0 and qtimer < MENU_Q_TIME) then return end
			if InRange and (WToggle == true and qtimer < 2 and Killable == false) then return end
			if GGPrediction:GetDistance(self.AttackTarget.pos, self.Pos) < QPrediction.Range - 50 then
				WToggle = false
				Utils:Cast(HK_Q, self.AttackTarget, QPrediction, MENU_Q_HITCHANCE + 1, 1)
				WAIT_STACKS = Game.Timer() + 1
				return
			end
		end
		for i = 1, #enemies do
			local enemy = enemies[i]
			if self:QCanUp(enemy) and GGPrediction:GetDistance(enemy.pos, self.Pos) < 1545 then
                local WStackDMG = Champion:WStackDMG(enemy)
				local AR = (100 / (100 + enemy.armor))
				local QarmD = QRawDmg * AR
				local QDmg = math.min(QarmD, QarmD * 0.60) * (1 + qtimer / 2.5)
				local EnemyHP = 100 * (enemy.health - QarmD + (10 * enemy.hpRegen)) / enemy.maxHealth
				local EnemyHP2 = 100 * (enemy.health - QDmg + (4 * enemy.hpRegen)) / enemy.maxHealth
				local MR = (100 / (100 + enemy.magicResist))
				if canusew and EnemyHP < ((WDMG + WStackDMG + 10) * 1.16) * MR then
					WToggle = true
					Control.KeyDown(HK_W)
					Control.KeyUp(HK_W)
				end
				local Killable = EnemyHP2 < (WStackDMG + (WDMG * 0.60) * (1 + qtimer / 4)) * MR
				if (#aaenemies == 0 and qtimer < MENU_Q_TIME) then return end
				local InRange = GGPrediction:GetDistance(enemy.pos, self.Pos) < 1400
				if InRange and (WToggle == true and qtimer < 2 and Killable == false) then return end
				if GGPrediction:GetDistance(enemy.pos, self.Pos) < QPrediction.Range - 50 then
					WToggle = false
					Utils:Cast(HK_Q, enemy, QPrediction, MENU_Q_HITCHANCE + 1, 1)
					WAIT_STACKS = Game.Timer() + 1
					return
				end
			end
		end
	end
	-- q logic
	function Champion:QLogic()
		if not GG_Spell:IsReady(_Q, { q = 0.33, w = 0, e = 0.6, r = 0.33 }) then
			return
		end
		self:QCombo()
	end
	-- q combo
	local AAtimer = {}
	function Champion:ExtraStack(Enemy)
		if Enemy then
			if(myHero.activeSpell.isAutoAttack) then
				--print(myHero.activeSpell.target, ": ", Enemy.handle)
				if myHero.activeSpell.target == Enemy.handle then
					if AAtimer[Enemy.networkID] then
						if AAtimer[Enemy.networkID] > Game.Timer() then
							AAtimer[Enemy.networkID] = nil
							print("END")
							return nil
						end
						return true
					else
						AAtimer[Enemy.networkID] = Game.Timer() + 0.8
					end
				end
			end
		end
		return true
	end

	function Champion:QCombo()
		if not ((self.IsCombo and MENU_Q_COMBO) or (self.IsHarass and MENU_Q_HARASS)) then
			return
		end
		local enemies = Utils:GetEnemyHeroes(1500)
		for i = 1, #enemies do
			local enemy = enemies[i]
			if WAIT_STACKS < Game.Timer() then
				if
					not MENU_Q_WSTACKS
					or self.WSpellData.level == 0
					or GG_Buff:GetBuffCount(enemy, "varuswdebuff") == 3
					or GG_Buff:GetBuffCount(enemy, "varuswdebuff") == 2 and Champion:ExtraStack(enemy) and AAtimer[enemy.networkID] and AAtimer[enemy.networkID] > Game.Timer()
					or (self.IsCombo and MENU_Q_SKIP_WSTACKS and self.AttackTarget == nil and GG_Buff:GetBuffCount(enemy, "varuswdebuff") == 1 and Champion:ExtraStack(enemy) and AAtimer[enemy.networkID] and AAtimer[enemy.networkID] > Game.Timer())
					or (self.IsCombo and MENU_Q_SKIP_WSTACKS and self.AttackTarget == nil and GG_Buff:GetBuffCount(enemy, "varuswdebuff") == 2)
				then
					Control.KeyDown(HK_Q)
					break
				end
			end
		end
	end
	-- e logic
	function Champion:ELogic()
		if not GG_Spell:IsReady(_E, { q = 0.33, w = 0, e = 0.63, r = 0.33 }) then
			return
		end
		self:ECombo()
	end
	-- e combo

	function Champion:ECombo()
		if not ((self.IsCombo and MENU_E_COMBO) or (self.IsHarass and MENU_E_HARASS)) then
			return
		end
		local ASE = (myHero.attackSpeed * 0.658) > 1.75
		if
			self.AttackTarget
			and (
				not MENU_E_WSTACKS
				or self.WSpellData.level == 0
				or GG_Buff:GetBuffCount(self.AttackTarget, "varuswdebuff") == 3
				or ASE and GG_Buff:GetBuffCount(self.AttackTarget, "varuswdebuff") == 2
				or GG_Buff:GetBuffCount(self.AttackTarget, "varuswdebuff") == 2 and Champion:ExtraStack(self.AttackTarget) and AAtimer[self.AttackTarget.networkID] and AAtimer[self.AttackTarget.networkID] > Game.Timer()
				or ASE and GG_Buff:GetBuffCount(self.AttackTarget, "varuswdebuff") == 1 and Champion:ExtraStack(self.AttackTarget) and AAtimer[self.AttackTarget.networkID] and AAtimer[self.AttackTarget.networkID] > Game.Timer()
			)
		then
			if WAIT_STACKS < Game.Timer() and Utils:Cast(HK_E, self.AttackTarget, EPrediction, MENU_E_HITCHANCE + 1, 0) then
				WAIT_STACKS = Game.Timer() + 1
				return
			end
		end
		local enemies = Utils:GetEnemyHeroes(EPrediction.Range)
		for i = 1, #enemies do
			local enemy = enemies[i]
			if
				not MENU_E_WSTACKS
				or self.WSpellData.level == 0
				or GG_Buff:GetBuffCount(enemy, "varuswdebuff") == 3
				or ASE and GG_Buff:GetBuffCount(enemy, "varuswdebuff") == 2
				or GG_Buff:GetBuffCount(enemy, "varuswdebuff") == 2 and Champion:ExtraStack(enemy) and AAtimer[enemy.networkID] and AAtimer[enemy.networkID] > Game.Timer()
				or ASE and GG_Buff:GetBuffCount(enemy, "varuswdebuff") == 2 and Champion:ExtraStack(enemy) and AAtimer[enemy.networkID] and AAtimer[enemy.networkID] > Game.Timer()
				or (MENU_E_SKIP_WSTACKS and self.AttackTarget == nil and GG_Buff:GetBuffCount(enemy, "varuswdebuff") == 2)
				or (MENU_E_SKIP_WSTACKS and self.AttackTarget == nil and GG_Buff:GetBuffCount(enemy, "varuswdebuff") == 1 and Champion:ExtraStack(enemy) and AAtimer[enemy.networkID] and AAtimer[enemy.networkID] > Game.Timer())
			then
				if WAIT_STACKS < Game.Timer() and Utils:Cast(HK_E, enemy, EPrediction, MENU_E_HITCHANCE + 1, 0) then
					WAIT_STACKS = Game.Timer() + 1
					break
				end
			end
		end
	end
	-- r logic
	function Champion:RLogic()
		if not GG_Spell:IsReady(_R, { q = 0.33, w = 0, e = 0.63, r = 0.5 }) then
			return
		end
		self:RCombo()
	end
	-- r combo
	function Champion:RCombo()
		local canuseW = Game.CanUseSpell(_W) == 0
		local canuseQ = Game.CanUseSpell(_W) == 0
		local SpellsUP = canuseW and canuseQ
		if not ((self.IsCombo and MENU_R_COMBO) or (self.IsHarass and MENU_R_HARASS)) then
			return
		end
		local nearToDeath = myHero.health <= MENU_R_XHeroHP
		if
			self.AttackTarget
			and GGPrediction:GetDistance(self.AttackTarget.pos, self.Pos) < 900
			and (nearToDeath or self.AttackTarget.health >= MENU_R_XEnemyHP)
		then
			if Utils:Cast(HK_R, self.AttackTarget, RPrediction, MENU_R_HITCHANCE + 1, 0) then
				return
			end
		end
		local enemies = Utils:GetEnemyHeroes(RPrediction.Range)
		for i = 1, #enemies do
			local enemy = enemies[i]
			if GGPrediction:GetDistance(enemy.pos, self.Pos) < 900 then
				if nearToDeath or (SpellsUP and enemy.health >= MENU_R_XEnemyHP and 100 * enemy.health / enemy.maxHealth < (Champion:WLevelDMG() + Champion:WStackDMG() + 10) * 1.16) then
					if Utils:Cast(HK_R, enemy, RPrediction, MENU_R_HITCHANCE + 1, 0) then
						break
					end
				end
			end
		end
	end
	-- r semi manual
	function Champion:RSemiManual()
		if not Menu.r_semi_key:Value() then
			return
		end
		local enemies = Utils:GetEnemyHeroes(RPrediction.Range)
		for i = 1, #enemies do
			local enemy = enemies[i]
			if Utils:Cast(HK_R, enemy, RPrediction, Menu.r_semi_hitchance:Value() + 1, 0) then
				break
			end
		end
	end
end

if Champion ~= nil then
	function Champion:PreTick()
		self.IsCombo = GG_Orbwalker.Modes[ORBWALKER_MODE_COMBO]
		self.IsHarass = GG_Orbwalker.Modes[ORBWALKER_MODE_HARASS]
		self.IsLaneClear = GG_Orbwalker.Modes[ORBWALKER_MODE_LANECLEAR]
		self.IsLastHit = GG_Orbwalker.Modes[ORBWALKER_MODE_LASTHIT]
		self.IsFlee = GG_Orbwalker.Modes[ORBWALKER_MODE_FLEE]
		self.AttackTarget = nil
		self.CanAttackTarget = false
		self.IsAttacking = GG_Orbwalker:IsAutoAttacking()
		if not self.IsAttacking and (self.IsCombo or self.IsHarass) then
			self.AttackTarget = GG_Target:GetComboTarget()
			self.CanAttack = GG_Orbwalker:CanAttack()
			if self.AttackTarget and self.CanAttack then
				self.CanAttackTarget = true
			else
				self.CanAttackTarget = false
			end
		end
		self.Timer = Game.Timer()
		self.Pos = myHero.pos
		self.BoundingRadius = myHero.boundingRadius
		self.Range = myHero.range + self.BoundingRadius
		self.ManaPercent = 100 * myHero.mana / myHero.maxMana
		self.AllyHeroes = GG_Object:GetAllyHeroes(2000)
		self.EnemyHeroes = GG_Object:GetEnemyHeroes(false, false, true)
		--Utils.CachedDistance = {}
	end
	Callback.Add("Load", function()
		GG_Target = _G.SDK.TargetSelector
		GG_Orbwalker = _G.SDK.Orbwalker
		GG_Buff = _G.SDK.BuffManager
		GG_Damage = _G.SDK.Damage
		GG_Spell = _G.SDK.Spell
		GG_Object = _G.SDK.ObjectManager
		GG_Attack = _G.SDK.Attack
		GG_Data = _G.SDK.Data
		GG_Cursor = _G.SDK.Cursor
		SDK_IsRecalling = _G.SDK.IsRecalling
		GG_Orbwalker:CanAttackEvent(Champion.CanAttackCb)
		GG_Orbwalker:CanMoveEvent(Champion.CanMoveCb)
		if Champion.OnLoad then
			Champion:OnLoad()
		end
		if Champion.OnPreAttack then
			GG_Orbwalker:OnPreAttack(Champion.OnPreAttack)
		end
		if Champion.OnAttack then
			GG_Orbwalker:OnAttack(Champion.OnAttack)
		end
		if Champion.OnPostAttack then
			GG_Orbwalker:OnPostAttack(Champion.OnPostAttack)
		end
		if Champion.OnPostAttackTick then
			GG_Orbwalker:OnPostAttackTick(Champion.OnPostAttackTick)
		end
		if Champion.OnTick then
			table.insert(_G.SDK.OnTick, function()
				--DH:drawSpellData(myHero, _W, 0, 0, 22)
				--DH:drawActiveSpell(myHero, 500, 0, 22)
				--DH:drawHeroesDistance(22)
				Champion:PreTick()
				if not SDK_IsRecalling(myHero) then
					Champion:OnTick()
				end
				Utils.CanUseSpell = true
			end)
		end
		if Champion.OnDraw then
			table.insert(_G.SDK.OnDraw, function()
				Champion:OnDraw()
			end)
		end
		if Champion.OnWndMsg then
			table.insert(_G.SDK.OnWndMsg, function(msg, wParam)
				Champion:OnWndMsg(msg, wParam)
			end)
		end
	end)
	return
end