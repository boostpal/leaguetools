class "Tracker"
require "MapPositionGOS"

function Tracker:__init()
    PrintChat("C41T CampTracker V0.6 (BETA) loaded")
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
    self.JTracker 	= {}
    self.JTrackerList = {}

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

    --Objectives
    self.BaronPosition = Vector(4951, -71, 10432)
    self.BaronTimer = -1000
    self.DragonPosition = Vector(9789, -71, 4398)
    self.DragonTimer = -1000

    --Other
    self.LastEnemyCamp = nil
    self.LastCampDied = nil
    self.LastCampDiedPos = nil
    self.DieTimer = 10
    self.ParseTick = 10
end

local Monsters = {}
local GameTimer = Game.Timer
local DrawText = Draw.Text
local DrawColor = Draw.Color
local ObjCount = Game.ObjectCount
local GameObj = Game.Object
local sqrt = math.sqrt
local HeroCount = GameHeroCount
local Heroes = GameHero

local function GetDistance(pos1, pos2)
	if(pos1 == nil or pos2 == nil) then return "Error" end
    local dx = pos1.x - pos2.x
    local dz = pos1.z - pos2.z
	return sqrt(dx*dx + dz*dz)
end

function Tracker:AlliesInRange(Position, Range)
    local Count = 0
    for i = 1, HeroCount() do 
		local Hero = Heroes(i)	
        if Hero.team == myHero.team and Hero.dead == false then
            if GetDistance(Hero.pos, Position) < Range then
                Count = Count + 1
            end
        end
    end
    return Count
end

function Tracker:GetAllJungleMinions()
    local JgMonsters = {}
    if self.ParseTick then
        if(GameTimer() > self.ParseTick) then
            for i = 0, ObjCount() do
                local Object = GameObj(i)
                if Object.team == 300 and Object.networkID and Object.maxHealth > 137 and (Object.totalDamage > 20 or Object.totalDamage == 7) then
                    Monsters[Object.networkID] = Object
                end
            end
            self.ParseTick = GameTimer() + 15 --Saves every 15 seconds (For better performence needs more testing with different dragons!)
        end
    else
        self.ParseTick = GameTimer()
    end
    JgMonsters = Monsters
    return JgMonsters
end

function Tracker:CampAlive(Position, Range, MonsterName)
    local Count = 0
    local MinionList = Tracker:GetAllJungleMinions()
    for i, Minion in pairs(MinionList) do	
        if Minion.team == 300 and Minion.dead == false then
            if GetDistance(Minion.pos, Position) < Range then
                if Minion.charName:find(MonsterName) then
                    Count = Count + 1
                end
            end
        end
    end
    return Count
end

function Tracker:GetJungleTracker()
    local JTracker = {}
    local JungleList = Tracker:GetAllJungleMinions()
    for _, Minion in pairs(JungleList) do
        JTracker[Minion.networkID] = {
            Object		= Minion,
            Position 	= Minion.pos,
            --SpawnTime	= self:GetMonsterSpawnTime(Minion),
            --Timer		= self:GetMonsterTimer(Minion),
        }
    end
    return JTracker
end

function Tracker:TimersBeforeSpawn()
    if self.BaronTimer < 0 and GameTimer() < 1200 and GameTimer() > 1110 then
        self.BaronTimer = GameTimer() + 90
    end
    --print(self.DragonTimer)
    if self.DragonTimer < 0 and GameTimer() < 300 and GameTimer() > 210 then
        self.DragonTimer = GameTimer() + 90
    end
    if GameTimer() < 90 then
        if self.Blue1Timer < 0 then
            self.Blue1Timer = 90 - GameTimer()
        end
        if self.Blue2Timer < 0 then
            self.Blue2Timer = 90 - GameTimer()
        end
        if self.Red1Timer < 0 then
            self.Red1Timer = 90 - GameTimer()
        end
        if self.Red2Timer < 0 then
            self.Red2Timer = 90 - GameTimer()
        end
        if self.Wolf1Timer < 0 then
            self.Wolf1Timer = 90 - GameTimer()
        end
        if self.Wolf2Timer < 0 then
            self.Wolf2Timer = 90 - GameTimer()
        end
        if self.Chicken1Timer < 0 then
            self.Chicken1Timer = 90 - GameTimer()
        end
        if self.Chicken2Timer < 0 then
            self.Chicken2Timer = 90 - GameTimer()
        end
        if self.Krug1Timer < 0 then
            self.Krug1Timer = 90 - GameTimer()
        end
        if self.Krug2Timer < 0 then
            self.Krug2Timer = 90 - GameTimer()
        end
    end
    if GameTimer() < 102 then
        if self.Gromp1Timer < 0 then
            self.Gromp1Timer = 102 - GameTimer()
        end
        if self.Gromp2Timer < 0 then
            self.Gromp2Timer = 102 - GameTimer()
        end
    end
end

function Tracker:GetJTimerList()
    local JTimerList = {}
    for _, Element in pairs(self.JTracker) do
        local Minion 		= Element.Object
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
            if self.DragonTimer < GameTimer() and Minion.charName:find("Dragon") then -- "SRU_Krug" "SRU_Red" "Sru_Crab" "SRU_Blue" "SRU_Murkwolf" "SRU_Razorbeak" "SRU_Gromp"
                --print(Minion.pos.x, Minion.pos.y, Minion.pos.z) --3780.6279296875 52.463195800781 6443.98388671889
                if GetDistance(Minion.pos, self.DragonPosition) < 2000 and self:CampAlive(self.DragonPosition, 2000, "Dragon") == 0 then
                    if Minion.visible then
                        self.DragonTimer = GameTimer() + 300
                    else
                        self.DragonTimer = GameTimer() + 300
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
        if self.DragonTimer > GameTimer() + 1 then
            local Timer = self.DragonTimer - GameTimer()
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
end

function Tracker:Draw()
    self.JTracker 	= self:GetJungleTracker()
    self:TimersBeforeSpawn()
    self:GetJTimerList()
    self:DrawCampTimer()
end

function OnLoad()
    Tracker()
end

--Not In Use
--[[function Tracker:ParseJungleMonsters()
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
