class "Tracker"
require "MapPositionGOS"

function Tracker:__init()
    PrintChat("C41T CampTracker V0.7 (BETA) loaded")
    self:LoadMenu()
    Callback.Add(
        "Tick",
        function()
            self:Tick()
        end
    )
    Callback.Add(
        "Draw",
        function()
            self:Draw()
        end
    )
end

function Tracker:LoadMenu()

    --JungleTrackerTimersBlueSide
    self.Blue1Pos = Vector(3734.9819335938, 52.791561126709, 7890.0)
    self.Blue1Timer = -1000
    self.Wolf1Pos = Vector(3780.6279296875, 52.463195800781, 6443.98388671889)
    self.Wolf1Timer = -1000
    self.Gromp1Pos = Vector(2112.0, 51.777313232422, 8450.0)
    self.Gromp1Timer = -1000
    self.Chicken1Pos = Vector(6823.8950195312, 54.782833099365, 5507.755859375)
    self.Chicken1Timer = -1000
    self.Red1Pos = Vector(7772.0, 53.933303833008, 4028.0)
    self.Red1Timer = -1000
    self.Krug1Pos = Vector(8482.470703125, 50.648094177246, 2705.9479980469)
    self.Krug1Timer = -1000

    --JungleTrackerTimersRedSide
    self.Blue2Pos = Vector(11032.0, 51.723670959473, 7002.0)
    self.Blue2Timer = -1000
    self.Wolf2Pos = Vector(11008.0, 62.131362915039, 8386.0)
    self.Wolf2Timer = -1000
    self.Gromp2Pos = Vector(12702.0, 51.691425323486, 6444.0)
    self.Gromp2Timer = -1000
    self.Chicken2Pos = Vector(7986.9970703125, 52.347938537598, 9471.388671875)
    self.Chicken2Timer = -1000
    self.Red2Pos = Vector(7108.0, 56.300552368164, 10892.0)
    self.Red2Timer = -1000
    self.Krug2Pos = Vector(6317.0922851562, 56.47679901123, 12146.458007812)
    self.Krug2Timer = -1000

    --Scuttles
    self.Crab1Pos = Vector(10423, -62, 5181)
    self.Crab1Timer = -1000
    self.Crab2Pos = Vector(4397, -66, 9610)
    self.Crab2Timer = -1000

    --Objectives
    self.BaronPosition = Vector(4951, -71, 10432)
    self.BaronTimer = -1000
    self.HeraldTimer = -1000
    self.DragonPosition = Vector(9789, -71, 4398)
    self.DragonTimer = -1000

    --Other
    self.LastEnemyCamp = nil
    self.LastCampDied = nil
    self.LastCampDiedPos = nil
    self.DieTimer = 10
    self.ParseTick = 10
    self.SoulTimer = 10
end

local GameTimer = Game.Timer
local DrawText = Draw.Text
local DrawColor = Draw.Color
local ObjCount = Game.ObjectCount
local GameObj = Game.Object
local sqrt = math.sqrt
local HeroCount = Game.HeroCount
local Heroes = Game.Hero
local Mteam = 300

local function GetDistance(pos1, pos2)
	if(pos1 == nil or pos2 == nil) then return "Error" end
    local dx = pos1.x - pos2.x
    local dz = pos1.z - pos2.z
	return sqrt(dx*dx + dz*dz)
end

local AllyList = {}
local CheckAlly = false
local function GetAllies()
    for i = 1, HeroCount() do
        local Ally = Heroes(i)
        if Ally.team == myHero.team then
            AllyList[i] = Ally
        end
    end
    return nil
end

local EnemyList = {}
local CheckEnemy = false
local function GetEnemies()
    for i = 1, HeroCount() do
        local Enemy = Heroes(i)
        if Enemy.team ~= myHero.team then
            EnemyList[i] = Enemy
        end
    end
    return nil
end

function Tracker:AlliesInRange(Position, Range)
    local Count = 0
    for i = 1, #AllyList do 
		local Hero = AllyList[i]
        if Hero.dead == false then
            if GetDistance(Hero.pos, Position) < Range then
                Count = Count + 1
            end
        end
    end
    return Count
end

local Monsters = {}
--local min = 16000
--local max = 0
function Tracker:ParseMonsters()
    local count = 0
    if self.ParseTick then
        if(GameTimer() > self.ParseTick) then
            for i = 1, #Monsters do
                Monsters[i] = nil
            end
            for i = 1, 3000 do
                local Object = GameObj(i)
                if Object.team == Mteam and Object.networkID and Object.maxHealth >= 110 and Object.ms >= 150 then
                    --Needs more testing!
                    --[[if i > max then
                        max = i
                    end
                    if i < min then
                        min = i
                    end
                    if GetDistance(Object.pos, Game.mousePos()) < 1500 then
                        print(Object.charName)
                    end]]
                    Monsters[i] = Object
                end
            end
            self.ParseTick = GameTimer() + 0 --Saves every 10 seconds (For better performence needs more testing with different dragons!)
        end
    else
        self.ParseTick = GameTimer()
    end
    --print("Min: ", min)
    --print("Max: ", max)
    --print(Game.mousePos().x, ",", Game.mousePos().y, ",", Game.mousePos().z)
    return nil
end

function Tracker:CampAlive(Position, Range, MonsterName)
    local Count = 0
    local MinionList = Monsters
    for i, Minion in pairs(MinionList) do	
        if Minion.charName:find(MonsterName) and Minion.dead == false then
            if GetDistance(Minion.pos, Position) < Range then
                Count = Count + 1
            end
        end
    end
    return Count
end

function Tracker:TimersBeforeSpawn()
    if self.BaronTimer < 0 and GameTimer() < 1200 and GameTimer() > 1110 then
        self.BaronTimer = GameTimer() + 90
    end
    if self.HeraldTimer < 0 and GameTimer() < 480 and GameTimer() > 390 then
        self.HeraldTimer = GameTimer() + 90
    end
    if self.DragonTimer < 0 and GameTimer() < 300 and GameTimer() > 210 then
        self.DragonTimer = GameTimer() + 90
    end
    if GameTimer() < 210 and GameTimer() > 120 then
        if self.Crab1Timer < 0 then
            local Time = GameTimer() + 90
            self.Crab1Timer = Time
            self.Crab2Timer = Time
        end
    end
    if GameTimer() < 90 then
        if self.Blue1Timer < 0 then
            local Time = 90 - GameTimer()
            self.Blue1Timer = Time
            self.Blue2Timer = Time
            self.Red1Timer = Time
            self.Red2Timer = Time
            self.Wolf1Timer = Time
            self.Wolf2Timer = Time
            self.Chicken1Timer = Time
            self.Chicken2Timer = Time
            self.Krug1Timer = Time
            self.Krug2Timer = Time
        end
    end
    if GameTimer() < 102 then
        if self.Gromp1Timer < 0 then
            local Time = 102 - GameTimer()
            self.Gromp1Timer = Time
            self.Gromp2Timer = Time
        end
    end
end

local Soul = false
function Tracker:CheckSoul()
    if Soul == false then
        if self.SoulTimer then
            if self.SoulTimer < GameTimer() then
                for i = 1, myHero.buffCount do
                    local buff = myHero:GetBuff(i)
        
                    if buff.count ~= 0 and buff.type == 1 then
                        if buff.name:find("Dragon") and buff.name:find("Soul") and buff.name:find("Preview") == nil then
                            Soul = true
                        end
                    end
                end
                local Enemy = EnemyList[1]
                if Enemy then
                    for i = 1, Enemy.buffCount do
                        local buff = Enemy:GetBuff(i)
            
                        if buff.count ~= 0 and buff.type == 1 then
                            if buff.name:find("Dragon") and buff.name:find("Soul") and buff.name:find("Preview") == nil then
                                Soul = true
                            end
                        end
                    end
                end
                self.SoulTimer = GameTimer() + 15
            end
        else
            self.SoulTimer = GameTimer()
        end
    end
    return nil
end

local secondHerald = false
function Tracker:GetJTimerList()
    local JTimerList = {}
    for _, Minion in pairs(Monsters) do
        --local Minion 		= Element.Object
        --local Timer 		= Element.Timer
        if Minion.dead then
            if self.BaronTimer < GameTimer() and Minion.charName:find("Baron") then -- "SRU_Krug" "SRU_Red" "Sru_Crab" "SRU_Blue" "SRU_Murkwolf" "SRU_Razorbeak" "SRU_Gromp"
                --print(Minion.pos.x, Minion.pos.y, Minion.pos.z) --3780.6279296875 52.463195800781 6443.98388671889
                if GetDistance(Minion.pos, self.BaronPosition) < 2000 and self:CampAlive(self.BaronPosition, 2000, "Baron") == 0 then
                    if Minion.visible then
                        self.BaronTimer = GameTimer() + 360
                    else
                        self.BaronTimer = GameTimer() + 360
                    end
                end
            end
            if self.HeraldTimer < GameTimer() and Minion.charName:find("Herald") and secondHerald == false then -- "SRU_Krug" "SRU_Red" "Sru_Crab" "SRU_Blue" "SRU_Murkwolf" "SRU_Razorbeak" "SRU_Gromp"
                --print(Minion.pos.x, Minion.pos.y, Minion.pos.z) --3780.6279296875 52.463195800781 6443.98388671889
                if GetDistance(Minion.pos, self.BaronPosition) < 2000 then
                    if Minion.visible then
                        secondHerald = true
                        self.HeraldTimer = GameTimer() + 360
                    else
                        secondHerald = true
                        self.HeraldTimer = GameTimer() + 360
                    end
                end
            end
            if self.DragonTimer < GameTimer() and Minion.charName:find("Dragon") then -- "SRU_Krug" "SRU_Red" "Sru_Crab" "SRU_Blue" "SRU_Murkwolf" "SRU_Razorbeak" "SRU_Gromp"
                --print(Minion.pos.x, Minion.pos.y, Minion.pos.z) --3780.6279296875 52.463195800781 6443.98388671889
                if GetDistance(Minion.pos, self.DragonPosition) < 2000 and self:CampAlive(self.DragonPosition, 2000, "Dragon") == 0 then
                    self.DragonTimer = GameTimer() + 300
                end
            end
            if self.Crab1Timer < GameTimer() and Minion.charName == "Sru_Crab" then
                --print(Minion.pos.x, Minion.pos.y, Minion.pos.z) --3734.9819335938 52.791561126709 52.791561126709
                if GetDistance(Minion.pos, self.Crab1Pos) < 2500 then
                    if Minion.visible then
                        self.Crab1Timer = GameTimer() + 150
                    else
                        self.Crab1Timer = GameTimer() + 150
                        if self:AlliesInRange(self.Crab1Pos, 2000) == 0 then
                            self.LastEnemyCamp = "Crab1"
                        end
                    end
                end
            end
            if self.Crab2Timer < GameTimer() and Minion.charName == "Sru_Crab" then
                --print(Minion.pos.x, Minion.pos.y, Minion.pos.z) --3734.9819335938 52.791561126709 52.791561126709
                if GetDistance(Minion.pos, self.Crab2Pos) < 2500 then
                    if Minion.visible then
                        self.Crab2Timer = GameTimer() + 150
                    else
                        self.Crab2Timer = GameTimer() + 150
                        if self:AlliesInRange(self.Crab2Pos, 2000) == 0 then
                            self.LastEnemyCamp = "Crab2"
                        end
                    end
                end
            end
            if self.Blue1Timer < GameTimer() and Minion.charName == "SRU_Blue" then
                --print(Minion.pos.x, Minion.pos.y, Minion.pos.z) --3734.9819335938 52.791561126709 52.791561126709
                if GetDistance(Minion.pos, self.Blue1Pos) < 2000 then
                    if Minion.visible then
                        self.Blue1Timer = GameTimer() + 300
                    else
                        self.Blue1Timer = GameTimer() + 300
                        if self:AlliesInRange(self.Blue1Pos, 2000) == 0 then
                            self.LastEnemyCamp = "Blue1"
                        end
                    end
                end
            end
            if self.Blue2Timer < GameTimer() and Minion.charName == "SRU_Blue" then
                --print(Minion.pos.x, Minion.pos.y, Minion.pos.z) --11032.0 51.723670959473 7002.0
                if GetDistance(Minion.pos, self.Blue2Pos) < 2000 then
                    if Minion.visible then
                        self.Blue2Timer = GameTimer() + 300
                    else
                        self.Blue2Timer = GameTimer() + 300
                        if self:AlliesInRange(self.Blue2Pos, 2000) == 0 then
                            self.LastEnemyCamp = "Blue2"
                        end
                    end
                end
            end
            if self.Wolf1Timer < GameTimer() and Minion.charName:find("wolf") then -- "SRU_Krug" "SRU_Red" "Sru_Crab" "SRU_Blue" "SRU_Murkwolf" "SRU_Razorbeak" "SRU_Gromp"
                --print(Minion.pos.x, Minion.pos.y, Minion.pos.z) --3780.6279296875 52.463195800781 6443.98388671889
                local MonstersAlive = self:CampAlive(self.Wolf1Pos, 2000, "wolf")
                if GetDistance(Minion.pos, self.Wolf1Pos) < 2000 and MonstersAlive == 0 then
                    if self.LastCampDied == "Wolf1" then
                        self.LastCampDied = nil
                        self.LastCampDiedPos = nil
                    end
                    if Minion.visible then
                        self.Wolf1Timer = GameTimer() + 135
                    else
                        self.Wolf1Timer = GameTimer() + 135
                        if self:AlliesInRange(self.Wolf1Pos, 2000) == 0 then
                            self.LastEnemyCamp = "Wolf1"
                        end
                    end
                else
                    if Minion.visible == false and GetDistance(Minion.pos, self.Wolf1Pos) < 2000 and self:AlliesInRange(self.Wolf1Pos, 2000) == 0 and MonstersAlive < 3 and MonstersAlive > 0 then
                        self.LastCampDied = "Wolf1"
                        self.LastCampDiedPos = self.Wolf1Pos
                    end
                end
            end
            if self.Wolf2Timer < GameTimer() and Minion.charName:find("wolf") then -- "SRU_Krug" "SRU_Red" "Sru_Crab" "SRU_Blue" "SRU_Murkwolf" "SRU_Razorbeak" "SRU_Gromp"
                --print(Minion.pos.x, Minion.pos.y, Minion.pos.z) --11008.0 62.131362915039 8386.0
                local MonstersAlive = self:CampAlive(self.Wolf2Pos , 2000, "wolf")
                if GetDistance(Minion.pos, self.Wolf2Pos ) < 2000 and MonstersAlive == 0 then
                    if self.LastCampDied == "Wolf2" then
                        self.LastCampDied = nil
                        self.LastCampDiedPos = nil
                    end
                    if Minion.visible then
                        self.Wolf2Timer = GameTimer() + 135
                    else
                        self.Wolf2Timer = GameTimer() + 135
                        if self:AlliesInRange(self.Wolf2Pos , 2000) == 0 then
                            self.LastEnemyCamp = "Wolf2"
                        end
                    end
                else
                    if Minion.visible == false and GetDistance(Minion.pos, self.Wolf2Pos ) < 2000 and self:AlliesInRange(self.Wolf2Pos , 2000) == 0 and MonstersAlive < 3 and MonstersAlive > 0 then
                        self.LastCampDied = "Wolf2"
                        self.LastCampDiedPos = self.Wolf2Pos 
                    end
                end
            end
            if self.Gromp1Timer < GameTimer() and Minion.charName == "SRU_Gromp" then -- "SRU_Krug" "SRU_Red" "Sru_Crab" "SRU_Blue" "SRU_Murkwolf" "SRU_Razorbeak" "SRU_Gromp"
                --print(Minion.pos.x,",",Minion.pos.y,",",Minion.pos.z) --2102.0  51.777328491211 8454.0
                if GetDistance(Minion.pos, self.Gromp1Pos) < 2000 then
                    if Minion.visible then
                        self.Gromp1Timer = GameTimer() + 135
                    else
                        self.Gromp1Timer = GameTimer() + 135
                        if self:AlliesInRange(self.Gromp1Pos, 2000) == 0 then
                            self.LastEnemyCamp = "Gromp1"
                        end
                    end
                end
            end
            if self.Gromp2Timer < GameTimer() and Minion.charName == "SRU_Gromp" then -- "SRU_Krug" "SRU_Red" "Sru_Crab" "SRU_Blue" "SRU_Murkwolf" "SRU_Razorbeak" "SRU_Gromp"
                --print(Minion.pos.x,",",Minion.pos.y,",",Minion.pos.z) --2102.0  51.777328491211 8454.0
                if GetDistance(Minion.pos, self.Gromp2Pos) < 2000 then
                    if Minion.visible then
                        self.Gromp2Timer = GameTimer() + 135
                    else
                        self.Gromp2Timer = GameTimer() + 135
                        if self:AlliesInRange(self.Gromp2Pos, 2000) == 0 then
                            self.LastEnemyCamp = "Gromp2"
                        end
                    end
                end
            end
            if self.Krug1Timer < GameTimer() and Minion.charName:find("Krug") then -- "SRU_Krug" "SRU_Red" "Sru_Crab" "SRU_Blue" "SRU_Murkwolf" "SRU_Razorbeak" "SRU_Gromp"
                --print(Minion.pos.x,",",Minion.pos.y,",",Minion.pos.z) --2102.0  51.777328491211 8454.0
                local MonstersAlive = self:CampAlive(self.Krug1Pos, 2000, "Krug")
                if GetDistance(Minion.pos, self.Krug1Pos) < 2000 and MonstersAlive == 0 then
                    if self.LastCampDied == "Krug1" then
                        self.LastCampDied = nil
                        self.LastCampDiedPos = nil
                    end
                    if Minion.visible then
                        self.Krug1Timer = GameTimer() + 135
                    else
                        self.Krug1Timer = GameTimer() + 135
                        if self:AlliesInRange(self.Krug1Pos, 2000) == 0 then
                            self.LastEnemyCamp = "Krug1"
                        end
                    end
                else
                    if Minion.visible == false and GetDistance(Minion.pos, self.Krug1Pos) < 2000 and self:AlliesInRange(self.Krug1Pos, 2000) == 0 and MonstersAlive < 2 and MonstersAlive > 0 then
                        self.LastCampDied = "Krug1"
                        self.LastCampDiedPos = self.Krug1Pos
                    end
                end
            end
            if self.Krug2Timer < GameTimer() and Minion.charName:find("Krug") then -- "SRU_Krug" "SRU_Red" "Sru_Crab" "SRU_Blue" "SRU_Murkwolf" "SRU_Razorbeak" "SRU_Gromp"
                --print(Minion.pos.x,",",Minion.pos.y,",",Minion.pos.z) --2102.0  51.777328491211 8454.0
                local MonstersAlive = self:CampAlive(self.Krug2Pos, 2000, "Krug")
                if GetDistance(Minion.pos, self.Krug2Pos) < 2000 and MonstersAlive == 0 then
                    if self.LastCampDied == "Krug2" then
                        self.LastCampDied = nil
                        self.LastCampDiedPos = nil
                    end
                    if Minion.visible then
                        self.Krug2Timer = GameTimer() + 135
                    else
                        self.Krug2Timer = GameTimer() + 135
                        if self:AlliesInRange(self.Krug2Pos, 2000) == 0 then
                            self.LastEnemyCamp = "Krug2"
                        end
                    end
                else
                    if Minion.visible == false and GetDistance(Minion.pos, self.Krug2Pos) < 2000 and self:AlliesInRange(self.Krug2Pos, 2000) == 0 and MonstersAlive < 2 and MonstersAlive > 0 then
                        self.LastCampDied = "Krug2"
                        self.LastCampDiedPos = self.Krug2Pos
                    end
                end
            end
            if self.Red1Timer < GameTimer() and Minion.charName == "SRU_Red" then -- "SRU_Krug" "SRU_Red" "Sru_Crab" "SRU_Blue" "SRU_Murkwolf" "SRU_Razorbeak" "SRU_Gromp"
                --print(Minion.pos.x,",",Minion.pos.y,",",Minion.pos.z) --2102.0  51.777328491211 8454.0
                if GetDistance(Minion.pos, self.Red1Pos) < 2000 then
                    if Minion.visible then
                        self.Red1Timer = GameTimer() + 300
                    else
                        self.Red1Timer = GameTimer() + 300
                        if self:AlliesInRange(self.Red1Pos, 2000) == 0 then
                            self.LastEnemyCamp = "Red1"
                        end
                    end
                end
            end
            if self.Red2Timer < GameTimer() and Minion.charName == "SRU_Red" then -- "SRU_Krug" "SRU_Red" "Sru_Crab" "SRU_Blue" "SRU_Murkwolf" "SRU_Razorbeak" "SRU_Gromp"
                --print(Minion.pos.x,",",Minion.pos.y,",",Minion.pos.z) --2102.0  51.777328491211 8454.0
                if GetDistance(Minion.pos, self.Red2Pos) < 2000 then
                    if Minion.visible then
                        self.Red2Timer = GameTimer() + 300
                    else
                        self.Red2Timer = GameTimer() + 300
                        if self:AlliesInRange(self.Red2Pos, 2000) == 0 then
                            self.LastEnemyCamp = "Red2"
                        end
                    end
                end
            end
            if self.Chicken1Timer < GameTimer() and Minion.charName:find("Razor") then -- "SRU_Krug" "SRU_Red" "Sru_Crab" "SRU_Blue" "SRU_Murkwolf" "SRU_Razorbeak" "SRU_Gromp"
                --print(Minion.pos.x,",",Minion.pos.y,",",Minion.pos.z) --2102.0  51.777328491211 8454.0
                local MonstersAlive = self:CampAlive(self.Chicken1Pos, 2000, "Razor")
                if GetDistance(Minion.pos, self.Chicken1Pos) < 2000 and MonstersAlive == 0 then
                    if self.LastCampDied == "Chicken1" then
                        self.LastCampDied = nil
                        self.LastCampDiedPos = nil
                    end
                    if Minion.visible then
                        self.Chicken1Timer = GameTimer() + 135
                    else
                        self.Chicken1Timer = GameTimer() + 135
                        if self:AlliesInRange(self.Chicken1Pos, 2000) == 0 then
                            self.LastEnemyCamp = "Chicken1"
                        end
                    end
                else
                    if Minion.visible == false and GetDistance(Minion.pos, self.Chicken1Pos) < 2000 and self:AlliesInRange(self.Chicken1Pos, 2000) == 0 and MonstersAlive < 6 and MonstersAlive > 0 then
                        self.LastCampDied = "Chicken1"
                        self.LastCampDiedPos = self.Chicken1Pos
                    end
                end
            end
            if self.Chicken2Timer < GameTimer() and Minion.charName:find("Razor") then -- "SRU_Krug" "SRU_Red" "Sru_Crab" "SRU_Blue" "SRU_Murkwolf" "SRU_Razorbeak" "SRU_Gromp"
                --print(Minion.pos.x,",",Minion.pos.y,",",Minion.pos.z) --2102.0  51.777328491211 8454.0
                local MonstersAlive = self:CampAlive(self.Chicken2Pos, 2000, "Razor")
                if GetDistance(Minion.pos, self.Chicken2Pos) < 2000 and MonstersAlive == 0 then
                    if self.LastCampDied == "Chicken2" then
                        self.LastCampDied = nil
                        self.LastCampDiedPos = nil
                    end
                    if Minion.visible then
                        self.Chicken2Timer = GameTimer() + 135
                    else
                        self.Chicken2Timer = GameTimer() + 135
                        if self:AlliesInRange(self.Chicken2Pos, 2000) == 0 then
                            self.LastEnemyCamp = "Chicken2"
                        end
                    end
                else
                    if Minion.visible == false and GetDistance(Minion.pos, self.Chicken2Pos) < 2000 and self:AlliesInRange(self.Chicken2Pos, 2000) == 0 and MonstersAlive < 6 and MonstersAlive > 0 then
                        self.LastCampDied = "Chicken2"
                        self.LastCampDiedPos = self.Chicken2Pos
                    end
                end
            end
        end
    end
    return JTimerList
end

function Tracker:DrawCampTimer()
    local ExtraDist2Camp = 1.15
    if --[[self.CampMarker.Value == 1 and]] self.LastCampDied ~= nil and self.LastCampDiedPos ~= nil then
        if os.clock() - self.DieTimer > 5  then
            self.DieTimer = os.clock()
        else
            if os.clock() > self.DieTimer + 4 then
                self.LastCampDied = nil
                self.LastCampDiedPos = nil
            end
        end
        local R, G, B = 235, 168, 52
        local MinionPos 	= self.LastCampDiedPos
        if MinionPos then
            local MapPos		= MinionPos:ToMM()
            local R, G, B = 131, 235, 52
            DrawText("X", 20, MapPos.x-10, MapPos.y-12, DrawColor(255,R,G,B))
        end
    end
    if --[[self.DrawJungleTimers.Value == 1]] 1 == 1 then
        if self.HeraldTimer > GameTimer() + 1 and GameTimer() < 1170 and self.BaronTimer < 0 then
            local Timer = self.HeraldTimer - GameTimer()
            local MinionPos 	= self.BaronPosition
            local MapPos		= MinionPos:ToMM()
            local R, G, B = 255, 255, 255
            if 15 > Timer - (GetDistance(MinionPos, myHero.pos)* ExtraDist2Camp) / myHero.ms then
                R, G, B = 235, 168, 52
            end
            if 3 > Timer - (GetDistance(MinionPos, myHero.pos)* ExtraDist2Camp) / myHero.ms then
                R, G, B = 131, 235, 52
            end
            DrawText(string.format("%.0f", Timer), 20, MapPos.x-10, MapPos.y-12, DrawColor(255,R,G,B))
        else
            if self.BaronTimer > GameTimer() + 1 then
                local Timer = self.BaronTimer - GameTimer()
                local MinionPos 	= self.BaronPosition
                local MapPos		= MinionPos:ToMM()
                local R, G, B = 255, 255, 255
                if 15 > Timer - (GetDistance(MinionPos, myHero.pos)* ExtraDist2Camp) / myHero.ms then
                    R, G, B = 235, 168, 52
                end
                if 3 > Timer - (GetDistance(MinionPos, myHero.pos)* ExtraDist2Camp) / myHero.ms then
                    R, G, B = 131, 235, 52
                end
                DrawText(string.format("%.0f", Timer), 20, MapPos.x-10, MapPos.y-12, DrawColor(255,R,G,B))
            end
        end
        if self.DragonTimer > GameTimer() + 1 or (Soul == true and self.DragonTimer + 60 > GameTimer() + 1) then
            local Timer = self.DragonTimer - GameTimer()
            if Soul == true then
                Timer = Timer + 60
            end
            local MinionPos 	= self.DragonPosition
            local MapPos		= MinionPos:ToMM()
            local R, G, B = 255, 255, 255
            if 15 > Timer - (GetDistance(MinionPos, myHero.pos)* ExtraDist2Camp) / myHero.ms then
                R, G, B = 235, 168, 52
            end
            if 3 > Timer - (GetDistance(MinionPos, myHero.pos)* ExtraDist2Camp) / myHero.ms then
                R, G, B = 131, 235, 52
            end
            DrawText(string.format("%.0f", Timer), 20, MapPos.x-10, MapPos.y-12, DrawColor(255,R,G,B))
        end
        if GameTimer() > 270 then
            if self.Crab1Timer > GameTimer() + 1 or self.Crab2Timer > GameTimer() + 1 then
                local Timer = self.Crab1Timer - GameTimer()
                if self.Crab2Timer > self.Crab1Timer then
                    Timer = self.Crab2Timer - GameTimer()
                end
                local MinionPos 	= self.Crab1Pos
                local MapPos		= MinionPos:ToMM()
                local MinionPos2 	= self.Crab2Pos
                local MapPos2		= MinionPos2:ToMM()
                local R, G, B = 255, 255, 255
                local R2, G2, B2 = 255, 255, 255
                if self.LastEnemyCamp == "Crab1" then
                    R, G, B = 235, 64, 52
                end
                if self.LastEnemyCamp == "Crab2" then
                    R2, G2, B2 = 235, 64, 52
                end
                if 15 > Timer - (GetDistance(MinionPos, myHero.pos)* ExtraDist2Camp) / myHero.ms then
                    R, G, B = 235, 168, 52
                end
                if 3 > Timer - (GetDistance(MinionPos, myHero.pos)* ExtraDist2Camp) / myHero.ms then
                    R, G, B = 131, 235, 52
                end
                if 15 > Timer - (GetDistance(MinionPos2, myHero.pos)* ExtraDist2Camp) / myHero.ms then
                    R2, G2, B2 = 235, 168, 52
                end
                if 3 > Timer - (GetDistance(MinionPos2, myHero.pos)* ExtraDist2Camp) / myHero.ms then
                    R2, G2, B2 = 131, 235, 52
                end
                DrawText(string.format("%.0f", Timer), 20, MapPos.x-10, MapPos.y-24, DrawColor(255,R,G,B))
                DrawText(string.format("%.0f", Timer), 20, MapPos2.x-10, MapPos2.y, DrawColor(255,R2,G2,B2))
            end
        else
            if self.Crab1Timer > GameTimer() + 1 then
                local Timer = self.Crab1Timer - GameTimer()
                local MinionPos 	= self.Crab1Pos
                local MapPos		= MinionPos:ToMM()
                local R, G, B = 255, 255, 255
                if self.LastEnemyCamp == "Crab1" then
                    R, G, B = 235, 64, 52
                end
                if 15 > Timer - (GetDistance(MinionPos, myHero.pos)* ExtraDist2Camp) / myHero.ms then
                    R, G, B = 235, 168, 52
                end
                if 3 > Timer - (GetDistance(MinionPos, myHero.pos)* ExtraDist2Camp) / myHero.ms then
                    R, G, B = 131, 235, 52
                end
                DrawText(string.format("%.0f", Timer), 20, MapPos.x-10, MapPos.y-12, DrawColor(255,R,G,B))
            end
            if self.Crab2Timer > GameTimer() + 1 then
                local Timer = self.Crab2Timer - GameTimer()
                local MinionPos 	= self.Crab2Pos
                local MapPos		= MinionPos:ToMM()
                local R, G, B = 255, 255, 255
                if self.LastEnemyCamp == "Crab2" then
                    R, G, B = 235, 64, 52
                end
                if 15 > Timer - (GetDistance(MinionPos, myHero.pos)* ExtraDist2Camp) / myHero.ms then
                    R, G, B = 235, 168, 52
                end
                if 3 > Timer - (GetDistance(MinionPos, myHero.pos)* ExtraDist2Camp) / myHero.ms then
                    R, G, B = 131, 235, 52
                end
                DrawText(string.format("%.0f", Timer), 20, MapPos.x-10, MapPos.y-12, DrawColor(255,R,G,B))
            end
        end
        if self.Blue1Timer > GameTimer() + 1 then
            local Timer = self.Blue1Timer - GameTimer()
            local MinionPos 	= self.Blue1Pos
            local MapPos		= MinionPos:ToMM()
            local R, G, B = 255, 255, 255
            if self.LastEnemyCamp == "Blue1" then
                R, G, B = 235, 64, 52
            end
            if 15 > Timer - (GetDistance(MinionPos, myHero.pos)* ExtraDist2Camp) / myHero.ms then
                R, G, B = 235, 168, 52
            end
            if 3 > Timer - (GetDistance(MinionPos, myHero.pos)* ExtraDist2Camp) / myHero.ms then
                R, G, B = 131, 235, 52
            end
            DrawText(string.format("%.0f", Timer), 20, MapPos.x-10, MapPos.y-12, DrawColor(255,R,G,B))
        end
        if self.Blue2Timer > GameTimer() + 1 then
            local Timer = self.Blue2Timer - GameTimer()
            local MinionPos 	= self.Blue2Pos
            local MapPos		= MinionPos:ToMM()
            local R, G, B = 255, 255, 255
            if self.LastEnemyCamp == "Blue2" then
                R, G, B = 235, 64, 52
            end
            if 15 > Timer - (GetDistance(MinionPos, myHero.pos)* ExtraDist2Camp) / myHero.ms then
                R, G, B = 235, 168, 52
            end
            if 3 > Timer - (GetDistance(MinionPos, myHero.pos)* ExtraDist2Camp) / myHero.ms then
                R, G, B = 131, 235, 52
            end
            DrawText(string.format("%.0f", Timer), 20, MapPos.x-10, MapPos.y-12, DrawColor(255,R,G,B))
        end
        if self.Wolf1Timer > GameTimer() + 1 then
            local Timer = self.Wolf1Timer - GameTimer()
            local MinionPos 	= self.Wolf1Pos
            local MapPos		= MinionPos:ToMM()
            local R, G, B = 255, 255, 255
            if self.LastEnemyCamp == "Wolf1" then
                R, G, B = 235, 64, 52
            end
            if 15 > Timer - (GetDistance(MinionPos, myHero.pos)* ExtraDist2Camp) / myHero.ms then
                R, G, B = 235, 168, 52
            end
            if 3 > Timer - (GetDistance(MinionPos, myHero.pos)* ExtraDist2Camp) / myHero.ms then
                R, G, B = 131, 235, 52
            end
            DrawText(string.format("%.0f", Timer), 17, MapPos.x-10, MapPos.y-12, DrawColor(255,R,G,B))
        end
        if self.Wolf2Timer > GameTimer() + 1 then
            local Timer = self.Wolf2Timer - GameTimer()
            local MinionPos 	= self.Wolf2Pos
            local MapPos		= MinionPos:ToMM()
            local R, G, B = 255, 255, 255
            if self.LastEnemyCamp == "Wolf2" then
                R, G, B = 235, 64, 52
            end
            if 15 > Timer - (GetDistance(MinionPos, myHero.pos)* ExtraDist2Camp) / myHero.ms then
                R, G, B = 235, 168, 52
            end
            if 3 > Timer - (GetDistance(MinionPos, myHero.pos)* ExtraDist2Camp) / myHero.ms then
                R, G, B = 131, 235, 52
            end
            DrawText(string.format("%.0f", Timer), 17, MapPos.x-10, MapPos.y-12, DrawColor(255,R,G,B))
        end
        if self.Krug1Timer > GameTimer() + 1 then
            local Timer = self.Krug1Timer - GameTimer()
            local MinionPos 	= self.Krug1Pos
            local MapPos		= MinionPos:ToMM()
            local R, G, B = 255, 255, 255
            if self.LastEnemyCamp == "Krug1" then
                R, G, B = 235, 64, 52
            end
            if 15 > Timer - (GetDistance(MinionPos, myHero.pos)* ExtraDist2Camp) / myHero.ms then
                R, G, B = 235, 168, 52
            end
            if 3 > Timer - (GetDistance(MinionPos, myHero.pos)* ExtraDist2Camp) / myHero.ms then
                R, G, B = 131, 235, 52
            end
            DrawText(string.format("%.0f", Timer), 17, MapPos.x-10, MapPos.y-12, DrawColor(255,R,G,B))
        end
        if self.Krug2Timer > GameTimer() + 1 then
            local Timer = self.Krug2Timer - GameTimer()
            local MinionPos 	= self.Krug2Pos
            local MapPos		= MinionPos:ToMM()
            local R, G, B = 255, 255, 255
            if self.LastEnemyCamp == "Krug2" then
                R, G, B = 235, 64, 52
            end
            if 15 > Timer - (GetDistance(MinionPos, myHero.pos)* ExtraDist2Camp) / myHero.ms then
                R, G, B = 235, 168, 52
            end
            if 3 > Timer - (GetDistance(MinionPos, myHero.pos)* ExtraDist2Camp) / myHero.ms then
                R, G, B = 131, 235, 52
            end
            DrawText(string.format("%.0f", Timer), 17, MapPos.x-10, MapPos.y-12, DrawColor(255,R,G,B))
        end
        if self.Red1Timer > GameTimer() + 1 then
            local Timer = self.Red1Timer - GameTimer()
            local MinionPos 	= self.Red1Pos
            local MapPos		= MinionPos:ToMM()
            local R, G, B = 255, 255, 255
            if self.LastEnemyCamp == "Red1" then
                R, G, B = 235, 64, 52
            end
            if 15 > Timer - (GetDistance(MinionPos, myHero.pos)* ExtraDist2Camp) / myHero.ms then
                R, G, B = 235, 168, 52
            end
            if 3 > Timer - (GetDistance(MinionPos, myHero.pos)* ExtraDist2Camp) / myHero.ms then
                R, G, B = 131, 235, 52
            end
            DrawText(string.format("%.0f", Timer), 20, MapPos.x-10, MapPos.y-12, DrawColor(255,R,G,B))
        end
        if self.Red2Timer > GameTimer() + 1 then
            local Timer = self.Red2Timer - GameTimer()
            local MinionPos 	= self.Red2Pos
            local MapPos		= MinionPos:ToMM()
            local R, G, B = 255, 255, 255
            if self.LastEnemyCamp == "Red2" then
                R, G, B = 235, 64, 52
            end
            if 15 > Timer - (GetDistance(MinionPos, myHero.pos)* ExtraDist2Camp) / myHero.ms then
                R, G, B = 235, 168, 52
            end
            if 3 > Timer - (GetDistance(MinionPos, myHero.pos)* ExtraDist2Camp) / myHero.ms then
                R, G, B = 131, 235, 52
            end
            DrawText(string.format("%.0f", Timer), 20, MapPos.x-10, MapPos.y-12, DrawColor(255,R,G,B))
        end
        if self.Chicken1Timer > GameTimer() + 1 then
            local Timer = self.Chicken1Timer - GameTimer()
            local MinionPos 	= self.Chicken1Pos
            local MapPos		= MinionPos:ToMM()
            local R, G, B = 255, 255, 255
            if self.LastEnemyCamp == "Chicken1" then
                R, G, B = 235, 64, 52
            end
            if 15 > Timer - (GetDistance(MinionPos, myHero.pos)* ExtraDist2Camp) / myHero.ms then
                R, G, B = 235, 168, 52
            end
            if 3 > Timer - (GetDistance(MinionPos, myHero.pos)* ExtraDist2Camp) / myHero.ms then
                R, G, B = 131, 235, 52
            end
            DrawText(string.format("%.0f", Timer), 17, MapPos.x-10, MapPos.y-12, DrawColor(255,R,G,B))
        end
        if self.Chicken2Timer > GameTimer() + 1 then
            local Timer = self.Chicken2Timer - GameTimer()
            local MinionPos 	= self.Chicken2Pos
            local MapPos		= MinionPos:ToMM()
            local R, G, B = 255, 255, 255
            if self.LastEnemyCamp == "Chicken2" then
                R, G, B = 235, 64, 52
            end
            if 15 > Timer - (GetDistance(MinionPos, myHero.pos)* ExtraDist2Camp) / myHero.ms then
                R, G, B = 235, 168, 52
            end
            if 3 > Timer - (GetDistance(MinionPos, myHero.pos)* ExtraDist2Camp) / myHero.ms then
                R, G, B = 131, 235, 52
            end
            DrawText(string.format("%.0f", Timer), 17, MapPos.x-10, MapPos.y-12, DrawColor(255,R,G,B))
        end
        if self.Gromp1Timer > GameTimer() + 1 then
            local Timer = self.Gromp1Timer - GameTimer()
            local MinionPos 	= self.Gromp1Pos
            local MapPos		= MinionPos:ToMM()
            local R, G, B = 255, 255, 255
            if self.LastEnemyCamp == "Gromp1" then
                R, G, B = 235, 64, 52
            end
            if 15 > Timer - (GetDistance(MinionPos, myHero.pos)* ExtraDist2Camp) / myHero.ms then
                R, G, B = 235, 168, 52
            end
            if 3 > Timer - (GetDistance(MinionPos, myHero.pos)* ExtraDist2Camp) / myHero.ms then
                R, G, B = 131, 235, 52
            end
            DrawText(string.format("%.0f", Timer), 17, MapPos.x-10, MapPos.y-12, DrawColor(255,R,G,B))
        end
        if self.Gromp2Timer > GameTimer() + 1 then
            local Timer = self.Gromp2Timer - GameTimer()
            local MinionPos 	= self.Gromp2Pos
            local MapPos		= MinionPos:ToMM()
            local R, G, B = 255, 255, 255
            if self.LastEnemyCamp == "Gromp2" then
                R, G, B = 235, 64, 52
            end
            if 15 > Timer - (GetDistance(MinionPos, myHero.pos)* ExtraDist2Camp) / myHero.ms then
                R, G, B = 235, 168, 52
            end
            if 3 > Timer - (GetDistance(MinionPos, myHero.pos)* ExtraDist2Camp) / myHero.ms then
                R, G, B = 131, 235, 52
            end
            DrawText(string.format("%.0f", Timer), 17, MapPos.x-10, MapPos.y-12, DrawColor(255,R,G,B))
        end
    end
end

function Tracker:Tick()
    if CheckAlly == false then
        GetAllies()
        CheckAlly = true
    end
    if CheckEnemy == false then
        GetEnemies()
        CheckEnemy = true
    end
    if Soul == false then
        self:CheckSoul()
    end
end

function Tracker:Draw()
    self:ParseMonsters()
    self:TimersBeforeSpawn()
    self:GetJTimerList()
    self:DrawCampTimer()
end

function OnLoad()
    Tracker()
end

--Not In Use
--[[

function Tracker:GetJungleTracker()
    local JTracker = {}
    for _, Minion in pairs(Monsters) do
        JTracker[Minion.networkID] = {
            Object		= Minion,
            --Position 	= Minion.pos,
            --SpawnTime	= self:GetMonsterSpawnTime(Minion),
            --Timer		= self:GetMonsterTimer(Minion),
        }
    end
    return JTracker
end
    
function Tracker:ParseJungleMonsters()
    if self.ParseTick then
        if (GameTimer() > self.ParseTick) then
            self.JungleMonsters = Tracker:GetAllJungleMinions()
            self.ParseTick = GameTimer() --+0.1
        end
    else
        self.ParseTick = GameTimer()
    end
end

function Tracker:GetMonsterSpawnTime(Minion)
    if self.JTracker[Minion.networkID] then
        --print(self.JTracker[Minion.networkID].Object.charName)
        local Timer = 135
        if Minion.charName == "Sru_Crab" then
            Timer = 150
        end
        if Minion.charName == "SRU_Blue" or Minion.charName == "SRU_Red" then
            Timer = 300
        end
        if Minion.visible == false then
            Timer = Timer - 1
        end
        --if self.JTracker[Minion.networkID].Timer == nil or self.JTracker[Minion.networkID].Timer <= 0 then
            --print(GameTimer() + Timer)
            if Minion.dead then
                return GameTimer() + Timer
            end
        --end
        return self.JTracker[Minion.networkID].SpawnTime
    end
    return 0.0			
end

function Tracker:GetMonsterTimer(Minion)
    if self.JTracker[Minion.networkID] then
        local Spawn = self.JTracker[Minion.networkID].SpawnTime
        --print(self.JTracker[Minion.networkID].Object.charName)
        if Spawn ~= nil then
            return Spawn - GameTimer()
        else
            return 0
        end
    end
    return nil
end]]